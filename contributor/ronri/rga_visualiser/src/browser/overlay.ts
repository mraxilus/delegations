// Hover ring and drag rubber-band, as SVG over canvas; not Nim because these reach browser APIs
//   Nim's JS backend does not express.
//   Presentation alone: every join, meet, pick, drag and camera move is computed by
//   bridge, compiled from same modules desktop draws through (Article II.9).
//   Concatenated into page in order `tools/build.nim` names; see its `SCRIPTS`.

/* ---------------------------------------------------------------------- */
/* Overlay: hover ring + drag rubber-band, as plain 2D SVG drawn on top of */
/* WebGL canvas -- mirrors `visualiser.drawInteractionOverlay` exactly     */
/* (same radius, same tint per operation), just drawn through SVG rather   */
/* than through Dear ImGui's own immediate-mode draw list.                */
/* ---------------------------------------------------------------------- */

const svg_overlay = elementById<SVGSVGElement>('overlay');
// Read from marker.nim's own constants via nimOverlayMetrics.
//   Never hand-copied literal that could drift out of sync with them.
const METRICS_OVERLAY = nimOverlayMetrics();
const WIDTH_OVERLAY_LINE = flatAt(METRICS_OVERLAY, 0);
const ALPHA_MARKER_SELECTED = flatAt(METRICS_OVERLAY, 1);
const ALPHA_MARKER_HOVER = flatAt(METRICS_OVERLAY, 2);
const HEIGHT_LABEL_MARKER = flatAt(METRICS_OVERLAY, 3);
const WIDTH_LABEL_HALO = flatAt(METRICS_OVERLAY, 4);
const ALPHA_LABEL_HALO = flatAt(METRICS_OVERLAY, 5);
// Every ink's colour as CSS string, read once: name label wears its object's ink, and.
//   `nimInkColor` builds sequence per call, which per selected object per frame was
//   allocation per frame. Indexed by ink ordinal, `nimItemInk`'s answer.
const COLOUR_INK_CSS: string[] = [];
for (let ink = 0; ink < nimInkCount(); ink += 1) {
  const rgb = nimInkColor(ink);
  const red = Math.round(flatAt(rgb, 0) * 255);
  const green = Math.round(flatAt(rgb, 1) * 255);
  const blue = Math.round(flatAt(rgb, 2) * 255);
  COLOUR_INK_CSS.push('rgb(' + red + ',' + green + ',' + blue + ')');
}
// Label's face sized to box marker.nim placed it in, so one number decides both.
svg_overlay.style.fontSize = HEIGHT_LABEL_MARKER + 'px';
// Halo in scene's own backdrop colour, at halo width and alpha marker.nim states.
//   Halo that blends with ground knocks surroundings out of letters; marker's white
//   dominated them. See `marker.WIDTH_MARKER_LABEL_HALO`.
const COLOUR_LABEL_HALO = (() => {
  const rgb = nimInkColor(nimInkBackdrop());
  return 'rgba(' + Math.round((rgb[0] ?? 0) * 255) + ',' + Math.round((rgb[1] ?? 0) * 255) + ',' +
    Math.round((rgb[2] ?? 0) * 255) + ',' + ALPHA_LABEL_HALO + ')';
})();
// Mirrors marker.MarkerKind's own ordinals; nimSelectionMarker leads with one of these.
const MARKER_RING = 0, MARKER_RAILS = 1, MARKER_LOOP = 2, MARKER_BANDS = 3,
  MARKER_FRAME = 4;
// Read from interaction.nim's own constants via nimMenuMetrics, for same reason marker's sizes are:
//   hand-copied literal here would drift from desktop's menu.
const METRICS_MENU = nimMenuMetrics();
const HEIGHT_MENU_WEDGE = flatAt(METRICS_MENU, 0);
const PADDING_MENU_WEDGE = flatAt(METRICS_MENU, 1);
const ROUNDING_MENU_WEDGE = flatAt(METRICS_MENU, 2);
const WIDTH_MENU_WEDGE_BORDER = flatAt(METRICS_MENU, 3);
const RADIUS_MENU_CENTRE = flatAt(METRICS_MENU, 4);
const ALPHA_MENU_WEDGE = flatAt(METRICS_MENU, 5);
const ALPHA_MENU_UNOFFERED = flatAt(METRICS_MENU, 6);
// Floats per wedge in nimDragMenuLayout:
//   x, y, offered.
//   Wedge's own colours come from `.menu-wedge`, which is `.selection-menu button` -- see
//   shell.html.
const FLOATS_MENU_WEDGE = 3;

// **Overlay reuses its own elements rather than rebuilding DOM each frame.**
// `refreshOverlay` used to clear layer with innerHTML and create every marker,
// pulse and wedge afresh -- element construction plus garbage per frame, roughly half
// overlay row's cost while anything was selected. Now each frame *stages* what it
// wants drawn: `stageEl` takes recycled element of right tag (stripping whatever
// attributes last use left on it), and one `replaceChildren` at end swaps
// layer's children in staged order -- so z-order still reads straight down staging
// calls, and element unused this frame simply comes off DOM into pool.
// Elements taken off layer this frame, by tag, ready for next frame's staging.
const pool_overlay = new Map<string, SVGElement[]>();
let staged_overlay: SVGElement[] = [];
function stageEl(tag: string, attrs: Record<string, string | number>): SVGElement {
  const bin = pool_overlay.get(tag);
  const element = bin !== undefined && bin.length > 0
    ? bin.pop() as SVGElement
    : document.createElementNS('http://www.w3.org/2000/svg', tag);
  for (let i = element.attributes.length - 1; i >= 0; i -= 1) {
    const name = element.attributes[i]?.name;
    if (name === undefined) continue;
    if (!(name in attrs)) element.removeAttribute(name);
  }
  for (const k in attrs) element.setAttribute(k, String(attrs[k]));
  staged_overlay.push(element);
  return element;
}
function recycleOverlay() {
  for (const element of Array.from(svg_overlay.children) as SVGElement[]) {
    let bin = pool_overlay.get(element.tagName);
    if (bin === undefined) { bin = []; pool_overlay.set(element.tagName, bin); }
    bin.push(element);
  }
  staged_overlay = [];
}

// Stroke one object's marker into overlay.
//   Every geometric decision -- which outline, how far off object it sits, where its points land on
//   screen -- was made by marker.nim; this only turns flat array it reports into SVG elements.
//
// **Interaction layer works in CSS pixels; render layer works in framebuffer
// pixels.** Two layers, two units, and each is told which it is in: cursor, hover,
// markers and menus are all asked and answered in CSS pixels, while `nimBuildFrame` and
// WebGL uniforms below take framebuffer size and scale their own constants by
// device pixel ratio. This used to be half-done -- positions were converted from
// framebuffer to CSS but every *length* was not, so marker's radius and menu wedge's
// height were drawn at ratio times their intended size, and `make the marker bigger` had
// no stable meaning. Converting nothing is simpler than converting some of it.
// Rails arrive as consecutive pairs, one per drawn piece, so pairwise loop below
// covers line clipped into any number of them without knowing how many to expect.
// Orientation pulse travelling along selected object's marker: which way it goes is
// object's own orientation, and shape of every run comes across bridge already
// in screen space. Filled rather than stroked, because each run tapers from swollen head
// back to outline's own width and stroke carries one width for its whole length --
// marker.ribbonAlong shapes that outline, this only fills what it is handed. Only caller
// passing time gets one -- hover and focus wear same marker standing still.
function appendMarkerPulse(
  handle: number, alpha: number, progress: number, is_touch: boolean,
) {
  const flat = nimSelectionPulse(handle, canvas.clientWidth, canvas.clientHeight, progress,
    is_touch === true);
  if (flat.length === 0) return;
  const fill = 'rgba(255,255,255,' + alpha + ')';
  let at = 1;
  for (let run = 0; run < flatAt(flat, 0); run++) {
    const count = flatAt(flat, at++);
    const points: string[] = [];
    for (let i = 0; i < count; i++) {
      points.push(flatAt(flat, at + 2 * i) + ',' + flatAt(flat, at + 2 * i + 1));
    }
    at += 2 * count;
    stageEl('polygon', {
      points: points.join(' '), fill: fill, stroke: 'none',
    });
  }
}

// Write selected object's name above its marker.
//   Filled in object's own ink and haloed in backdrop's colour, so letters read against
//   whatever they stand over. Where it sits is `marker.Marker.label_at`'s decision,
//   centred here on both axes; face is `svg#overlay text`'s in shell.html.
//   Text set on element rather than through attributes: `stageEl` strips and sets
//   attributes only, and recycled <text> keeps last content unless overwritten.
//   Line's label comes as anchor on line plus direction to push it: text is measured
//   here, where its face is, and pushed by `nimLabelClearance` so its own box clears
//   line at any angle; see `marker.Marker.is_label_beside`.
function appendLabel(handle: number) {
  const at = nimSelectionLabelAt(handle, canvas.clientWidth, canvas.clientHeight);
  if (flatAt(at, 2) < 0.5) return;
  const element = stageEl('text', {
    x: flatAt(at, 0), y: flatAt(at, 1), 'text-anchor': 'middle', 'dominant-baseline': 'central',
    fill: COLOUR_INK_CSS[nimItemInk(handle)] ?? '',
    stroke: COLOUR_LABEL_HALO, 'stroke-width': WIDTH_LABEL_HALO,
    'stroke-linejoin': 'round', 'paint-order': 'stroke',
  });
  element.textContent = nimItemLabel(handle);
  if (flatAt(at, 3) > 0.5) {
    const half = (element as SVGTextElement).getComputedTextLength() / 2;
    const clearance = nimLabelClearance(flatAt(at, 4), flatAt(at, 5), half);
    element.setAttribute('x', String(flatAt(at, 0) + clearance * flatAt(at, 4)));
    element.setAttribute('y', String(flatAt(at, 1) + clearance * flatAt(at, 5)));
  }
}

function appendMarker(
  handle: number, alpha: number, w: number, h: number, progress: number,
  is_touch?: boolean, swell?: number,
) {
  const marker =
    nimSelectionMarker(handle, canvas.clientWidth, canvas.clientHeight, progress,
      is_touch === true, swell || 0);
  if (marker.length === 0) return;
  const kind = flatAt(marker, 0), is_closed = flatAt(marker, 1) > 0.5;
  const radius = flatAt(marker, 2), fraction = flatAt(marker, 3);
  const stroke = 'rgba(255,255,255,' + alpha + ')';
  const points: Array<[number, number]> = [];
  for (let i = 4; i + 1 < marker.length; i += 2) {
    points.push([flatAt(marker, i), flatAt(marker, i + 1)]);
  }

  if (kind === MARKER_RING) {
    // Keep whole ring as <circle>; only partial one becomes arc path.
    //   Marker that is not filling draws exactly as plain ring.
    if (fraction >= 1) {
      stageEl('circle', {
        cx: pointAt(points, 0)[0], cy: pointAt(points, 0)[1], r: radius,
        fill: 'none', stroke: stroke, 'stroke-width': WIDTH_OVERLAY_LINE,
      });
    } else if (fraction > 0) {
      // Sweep clockwise from twelve o'clock, measuring angle from top.
      //   Sweep then reads way every other progress dial does; with y downward, SVG's
      //   positive sweep direction (flag 1) is that same clockwise sense.
      const [cx, cy] = pointAt(points, 0);
      const turn = fraction * 2 * Math.PI;
      const ex = cx + radius * Math.sin(turn), ey = cy - radius * Math.cos(turn);
      stageEl('path', {
        d: 'M ' + cx + ',' + (cy - radius) +
           ' A ' + radius + ',' + radius + ' 0 ' + (fraction > 0.5 ? 1 : 0) + ',1 ' +
           ex + ',' + ey,
        fill: 'none', stroke: stroke, 'stroke-width': WIDTH_OVERLAY_LINE,
      });
    }
  } else if (kind === MARKER_RAILS) {
    for (let i = 0; i < points.length; i += 2) {
      stageEl('line', {
        x1: pointAt(points, i)[0], y1: pointAt(points, i)[1],
        x2: pointAt(points, i + 1)[0], y2: pointAt(points, i + 1)[1],
        stroke: stroke, 'stroke-width': WIDTH_OVERLAY_LINE,
      });
    }
  } else if (kind === MARKER_LOOP || kind === MARKER_FRAME) {
    // Stroke frame through very same element plane's loop does, as closed polyline.
    //   Circle while it expands, screen's own rectangle once it arrives.
    //   One path for every closed outline rather than <rect> of its own, and nothing to
    //   keep in step when one of them changes.
    stageEl(is_closed ? 'polygon' : 'polyline', {
      points: points.map((p) => p[0] + ',' + p[1]).join(' '),
      fill: 'none', stroke: stroke, 'stroke-width': WIDTH_OVERLAY_LINE,
    });
  } else if (kind === MARKER_BANDS) {
    // Two runs in one array:
    //   header says how many points first band holds and whether each band closed, since either can
    //   be cut into arc by eye on its own.
    const count_first = Math.round(flatAt(marker, 2)), is_closed_second = flatAt(marker, 3) > 0.5;
    const bands = [
      { run: points.slice(0, count_first), closed: is_closed },
      { run: points.slice(count_first), closed: is_closed_second },
    ];
    for (const band of bands) {
      if (band.run.length === 0) continue;
      stageEl(band.closed ? 'polygon' : 'polyline', {
        points: band.run.map((p) => p[0] + ',' + p[1]).join(' '),
        fill: 'none', stroke: stroke, 'stroke-width': WIDTH_OVERLAY_LINE,
      });
    }
  }
}

function refreshOverlay(cursor: PointLocal | null) {
  recycleOverlay();
  const w = canvas.clientWidth, h = canvas.clientHeight;
  // One clock reading for whole overlay, before any pulse is shaped:
  //   every selected object's comet advances by that same step.
  //   Pulse carries its phase between frames rather than computing it from time -- see
  //   selection.PulseClock for why reading it off clock made every comet lurch moment camera moved.
  nimTickPulse(now());

  // Draw one marker per selected object, shaped to that object by marker.nim.
  //   Ring about point, rails flanking line, loop lying on plane.
  //   Hover draws very same marker at lower opacity, so both read as one family and
  //   hovering line previews exactly what selecting it will draw.
  for (const handle of handles_selection) {
    if (handle === nimHoldHandle()) continue; // Its own swollen marker is drawn below.
    appendMarker(handle, ALPHA_MARKER_SELECTED, w, h, 1);
    appendMarkerPulse(handle, ALPHA_MARKER_SELECTED, 1, false);
    appendLabel(handle);
  }

  // Fill pressed item's own marker as press matures into selection.
  //   Wait then reads as filling rather than as nothing happening.
  //   Drawn at selected weight it is about to become, and skipped for item already
  //   selected, whose finished marker is on screen already.
  // Swell filled marker clear of finger doing filling.
  //   `nimBeginHold` is called from touch branch of `pointerdown` and from nowhere
  //   else, so hold in progress on this build is finger's by construction.
  //   Flag is passed rather than inferred inside marker.nim, which cannot see what kind
  //   of pointer is on glass.
  // Draw even once handle is selected, unlike every other overlay rule here.
  //   Matured hold keeps its swollen marker until finger lifts and it settles, and
  //   plain selected marker underneath it is very size this is animating away from.
  const handle_hold = nimHoldHandle();
  if (handle_hold >= 0) {
    appendMarker(handle_hold, ALPHA_MARKER_SELECTED, w, h, nimHoldProgress(now()), true,
      nimSwellHold(now()));
    // Name rides up with swollen marker, once hold has selected it.
    if (handles_selection.includes(handle_hold)) appendLabel(handle_hold);
  }

  // Hover and keyboard focus wear same marker at same weight:
  //   reader driving by key sees exactly what reader driving by pointer sees, and focus indicator
  //   WCAG 2.4.7 asks for is machinery already built rather than second one invented beside it.
  for (const handle of [nimHoverHandle(), nimFocusHandle()]) {
    if (handle >= 0 && handle !== handle_hold && !handles_selection.includes(handle)) {
      appendMarker(handle, ALPHA_MARKER_HOVER, w, h, 1);
    }
  }

  if (nimDragActive()) {
    const src = nimAnchorScreen(nimDragSourceHandle(), canvas.clientWidth, canvas.clientHeight);
    if (flatAt(src, 2) > 0.5 && cursor) {
      const sx = flatAt(src, 0), sy = flatAt(src, 1);
      // Tinted by what releasing would do, not by which button started drag:
      //   operation's own colour over pair that makes something, reserved magenta over one that
      //   makes nothing, neutral while crossing empty space.
      const tint = nimDragTint();
      const stroke = 'rgba(' + Math.round(flatAt(tint, 0) * 255) + ',' +
        Math.round(flatAt(tint, 1) * 255) + ',' + Math.round(flatAt(tint, 2) * 255) + ',0.85)';
      stageEl('line', {
        x1: sx, y1: sy, x2: cursor.x, y2: cursor.y,
        stroke: stroke, 'stroke-width': WIDTH_OVERLAY_LINE,
      });
      // Which way round pair is being taken:
      //   band swelling into its own last stretch, same shape orientation pulse wears.
      //   Shaped by `marker.cometFor` across bridge rather than worked out here -- band's direction
      //   is gesture's own business, and this layer fills what it is handed.
      //   Empty while cursor rests on its own source, which points nowhere.
      const comet = nimDragComet(w, h);
      if (comet.length) {
        const points = [];
        for (let i = 0; i + 1 < comet.length; i += 2) points.push(comet[i] + ',' + comet[i + 1]);
        stageEl('polygon', {
          points: points.join(' '), fill: stroke, stroke: 'none',
        });
      }
    }
    appendChoiceMenu(w, h);
  }

  // One swap for whole layer, in staged order. Also what detaches whatever last.
  //   frame drew and this one did not: those elements sit in pool, off DOM.
  svg_overlay.replaceChildren(...staged_overlay);
}

// Draw four wedges of open choice menu.
//   Every position, colour, label and whether wedge is offered comes from interaction.nim through
//   nimDragMenuLayout/Labels, and which one cursor stands in from nimDragMenuHighlighted -- same
//   call release resolves through, so highlight is never second opinion about where cursor is.
//   Wedge label's laid-out width, measured once per label and remembered.
//   Still measured from what browser actually laid it out as -- never estimated from character
//   count, which drifts moment face loaded is not one estimate was tuned against -- but label's
//   metrics cannot change between frames, and `getBBox` forces layout, so paying it once per label
//   is whole point.
//   Cache empties when document's fonts finish loading, in case early measure ran against fallback
//   face.
const widths_menu_label = new Map<string, number>();
document.fonts.ready.then(() => widths_menu_label.clear());
function widthMenuLabel(label: string) {
  const held = widths_menu_label.get(label);
  if (held !== undefined) return held;
  const text = document.createElementNS('http://www.w3.org/2000/svg', 'text');
  text.setAttribute('class', 'menu-wedge-label');
  text.textContent = label;
  svg_overlay.appendChild(text);
  const width = text.getBBox().width;
  text.remove();
  widths_menu_label.set(label, width);
  return width;
}

// Cache wedge labels: fixed for build, so bridge is asked once rather than per frame.
let labels_menu: string[] | null = null;

function appendChoiceMenu(w: number, h: number) {
  const layout = nimDragMenuLayout();
  if (layout.length === 0) return;
  if (labels_menu === null) labels_menu = nimDragMenuLabels();
  const labels = labels_menu;
  const highlighted = nimDragMenuHighlighted();
  const centre = nimDragMenuCentre();
  for (let i = 0; i * FLOATS_MENU_WEDGE < layout.length; i += 1) {
    const at = i * FLOATS_MENU_WEDGE;
    const x = flatAt(layout, at), y = flatAt(layout, at + 1);
    const is_offered = flatAt(layout, at + 2) > 0.5;
    const width = widthMenuLabel(labels[i] ?? '') + PADDING_MENU_WEDGE;
    stageEl('rect', {
      x: x - width / 2, y: y - HEIGHT_MENU_WEDGE / 2,
      width: width, height: HEIGHT_MENU_WEDGE, rx: ROUNDING_MENU_WEDGE,
      'fill-opacity': is_offered ? ALPHA_MENU_WEDGE : ALPHA_MENU_UNOFFERED,
      'stroke-width': WIDTH_MENU_WEDGE_BORDER,
      class: i === highlighted ? 'menu-wedge on' : 'menu-wedge',
    });
    const text = stageEl('text', {
      x: x, y: y, 'text-anchor': 'middle', 'dominant-baseline': 'central',
      // Unoffered wedge is dimmed rather than dropped:
      //   gap where wedge should be is unreadable, and point of fixed compass is that choice never
      //   moves.
      'fill-opacity': is_offered ? 1 : 0.6,
      class: i === highlighted ? 'menu-wedge-label on' : 'menu-wedge-label',
    });
    text.textContent = labels[i] ?? '';
  }
  // Middle is where nothing is chosen, and way out of menu that opened unasked.
  stageEl('circle', {
    cx: flatAt(centre, 0), cy: flatAt(centre, 1),
    r: RADIUS_MENU_CENTRE,
    fill: 'none', class: 'menu-centre', 'stroke-width': WIDTH_OVERLAY_LINE,
  });
}
