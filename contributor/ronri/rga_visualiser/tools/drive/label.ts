// Checks for name each selected object wears; not Nim because crossing forfeits check compiler
//   makes over its `page.evaluate` bodies, which name bridge's derived exports and page's own
//   `selectOnly`. Overlay's `<text>` is reachable through glue; losing that check is not.
//   Label is placed by `marker.nim` and drawn in object's ink, haloed in backdrop's colour.
//   Selected through page's own entry throughout: bare `nimSelect*` moves Nim's selection
//   and never tells page, so overlay would carry no label at all to read.

import type { Page } from '@playwright/test';
import {
  eyeAround, outToward, placeCamera, readPlaced, settleCamera, type Placed,
} from './camera';
import { waitFrames } from './frame';
import { clearTheGlass } from './gestures';
import { report } from './report';


/** How many steps each orbit is walked in, and how many of those two together make. */
const STEPS_ORBIT = 200, FRAMES_WANTED = 400;

/** Label's own place this step, and window it must stay inside. */
interface Standing {
  x: number;
  y: number;
  width: number;
  height: number;
}

/** Read first overlay label's place, or nothing where overlay carries none. */
async function labelStanding(page: Page): Promise<Standing | null> {
  return page.evaluate(() => {
    const text = document.querySelector('#overlay text');
    const rect = (document.getElementById('gl') as HTMLElement).getBoundingClientRect();
    if (text === null) return null;
    return {
      x: Number(text.getAttribute('x')), y: Number(text.getAttribute('y')),
      width: rect.width, height: rect.height,
    };
  });
}

/** What walking two orbits did to one label. */
interface Walked {
  frames: number;
  hops: number;
  out_of_view: number;
  step_most: number;
}

/** Stand camera 19 units off origin, facing it, along this bearing and rise. */
function placedAround(bearing: number, rise: number): Placed {
  const pivot = [0, 0, 0];
  return { eye: eyeAround(pivot, 19, outToward(bearing, rise)), pivot };
}

/** Walk camera round one orbit at this rise, watching label step by step. */
async function walkOrbit(page: Page, rise: number, walked: Walked): Promise<void> {
  let before: Standing | null = null, step_before = 0;
  for (let i = 0; i <= STEPS_ORBIT; i += 1) {
    await placeCamera(page, placedAround((i / STEPS_ORBIT) * 2 * Math.PI, rise));
    await waitFrames(page, 2);

    const at = await labelStanding(page);
    if (at === null) {
      walked.out_of_view += 1;
      before = null;
      continue;
    }
    walked.frames += 1;
    if (at.x < 0 || at.x > at.width || at.y < 0 || at.y > at.height) walked.out_of_view += 1;
    if (before !== null) {
      const step = Math.hypot(at.x - before.x, at.y - before.y);
      // Hop is long step that is also far longer than one before it, which is mock-up
      //   page's own criterion: steady glide is long steps in row, not one lurch.
      if (step > 12 && step > 2 * step_before + 1) walked.hops += 1;
      walked.step_most = Math.max(walked.step_most, step);
      step_before = step;
    }
    before = at;
  }
}

/** Drive full orbit at two heights, and assert line's label glides through both.
 *
 *  Second height carries line through vertical on screen, which is where label's own
 *  placement would jump from one end of it to other.
 */
export async function driveLabelGlide(page: Page): Promise<void> {
  await clearTheGlass(page);
  await page.keyboard.press('Home');
  await settleCamera(page);
  await page.evaluate(() => clearSelection());

  const line = await page.evaluate(
    () => nimSceneHandles().find((one) => nimObjectKindWord(one) === 'line') ?? -1,
  );
  if (line < 0) {
    report("the scene holds a line to select", false, 'none');
    return;
  }
  await page.evaluate((one) => selectOnly(one, null), line);
  await settleCamera(page);

  const walked: Walked = { frames: 0, hops: 0, out_of_view: 0, step_most: 0 };
  for (const rise of [0.42, 3.0]) await walkOrbit(page, rise, walked);
  report(
    "a line's label glides through a full orbit and a vertical crossing, staying in view",
    walked.frames >= FRAMES_WANTED && walked.hops === 0 && walked.out_of_view === 0,
    `${walked.frames} frames, ${walked.hops} hops, ${walked.out_of_view} out of view, ` +
      `largest step ${walked.step_most.toFixed(1)} px`,
  );
  await page.evaluate(() => clearSelection());
}

/** Where first overlay label's box stands, and window it must stay inside. */
interface Box {
  left: number;
  top: number;
  right: number;
  bottom: number;
  width: number;
  height: number;
}

/** Read first overlay label's box, or nothing where overlay carries none. */
async function labelBox(page: Page): Promise<Box | null> {
  return page.evaluate(() => {
    const text = document.querySelector('#overlay text') as SVGTextElement | null;
    const rect = (document.getElementById('gl') as HTMLElement).getBoundingClientRect();
    if (text === null) return null;
    const box = text.getBBox();
    return {
      left: box.x, top: box.y, right: box.x + box.width, bottom: box.y + box.height,
      width: rect.width, height: rect.height,
    };
  });
}

/** Drive orbit at phone width with horizon line selected, and assert its label stays whole,
 *  at its left, and never swaps sides.
 *
 *  Horizon line's label stood above its band's topmost point wherever that fell: on narrow
 *  page it fell at right edge, name cut, and on level horizon it hopped between two side
 *  edges frame to frame. It now rides band's crossing of left edge. Two heights, since
 *  band's crossing wanders down whole height as camera rises. Runs over demo, whose
 *  ecliptic gives horizon line; whole camera is put back after, as far-sky check does,
 *  since zoom check following reads its opening distance off wherever camera stands.
 */
export async function driveLabelHeldInView(page: Page): Promise<void> {
  await clearTheGlass(page);
  await page.evaluate(() => clearSelection());
  const before = await readPlaced(page);
  const line = await page.evaluate(
    () => nimSceneHandles().find((one) => nimObjectKindWord(one) === 'horizon line') ?? -1,
  );
  if (line < 0) {
    report('the scene holds a horizon line to select', false, 'none');
    return;
  }
  await page.setViewportSize({ width: 393, height: 560 });
  await page.evaluate((one) => selectOnly(one, null), line);
  await settleCamera(page);
  let frames = 0, cut = 0, worst = 0, swaps = 0, right = 0;
  for (const rise of [0.2, 1.26]) {
    let centre_before: number | null = null;
    for (let i = 0; i < 48; i += 1) {
      await placeCamera(page, placedAround((i / 48) * 2 * Math.PI, rise));
      await waitFrames(page, 2);
      const box = await labelBox(page);
      if (box === null) {
        centre_before = null;
        continue;
      }
      frames += 1;
      const over = Math.max(
        -box.left, box.right - box.width, -box.top, box.bottom - box.height,
      );
      if (over > 0) cut += 1;
      worst = Math.max(worst, over);
      // Side swap is centre crossing quarter of width in one frame; glide never does.
      const centre = 0.5*(box.left + box.right);
      if (centre > 0.5*box.width) right += 1;
      if (centre_before !== null && Math.abs(centre - centre_before) > 0.25*box.width) {
        swaps += 1;
      }
      centre_before = centre;
    }
  }
  report(
    "a horizon line's label stays whole inside a phone-width page, on its left, through" +
      " two orbits without swapping sides",
    frames >= 48 && cut === 0 && swaps === 0 && right === 0,
    `${frames} frames with a label, ${cut} with its box past an edge, worst ` +
      `${worst.toFixed(1)} px over, ${swaps} side swaps, ${right} on the right`,
  );
  await page.evaluate(() => clearSelection());
  await page.setViewportSize({ width: 1200, height: 900 });
  await placeCamera(page, before);
  await settleCamera(page);
}

/** Drive label's first frame at phone width, and assert its box is whole inside view.
 *
 *  Label appears on frame after one without any. Its `<text>` is then staged off document,
 *  and text measured off document has no length, so hold kept centre alone inside view
 *  and half of name hung past edge for that frame. Horizon line's label rides left edge,
 *  so its hold always has work to do there. Read in same frame that draws it: page's own
 *  loop asks for its frame before this check asks for one, so it draws first.
 */
export async function driveLabelFirstFrame(page: Page): Promise<void> {
  await clearTheGlass(page);
  const before = await readPlaced(page);
  const line = await page.evaluate(
    () => nimSceneHandles().find((one) => nimObjectKindWord(one) === 'horizon line') ?? -1,
  );
  if (line < 0) {
    report('the scene holds a horizon line whose label to read', false, 'none');
    return;
  }
  await page.setViewportSize({ width: 393, height: 560 });
  let read = 0, cut = 0, worst = 0;
  for (const bearing of [0.0, 1.5, 3.0, 4.5]) {
    await page.evaluate(() => clearSelection());
    await placeCamera(page, placedAround(bearing, 0.2));
    await waitFrames(page, 2);
    const box = await page.evaluate((one) => {
      selectOnly(one, null);
      return new Promise<{ over: number } | null>((done) => requestAnimationFrame(() => {
        const text = document.querySelector('#overlay text') as SVGTextElement | null;
        const rect = (document.getElementById('gl') as HTMLElement).getBoundingClientRect();
        if (text === null) { done(null); return; }
        const drawn = text.getBBox();
        done({
          over: Math.max(
            -drawn.x, drawn.x + drawn.width - rect.width,
            -drawn.y, drawn.y + drawn.height - rect.height,
          ),
        });
      }));
    }, line);
    if (box === null) continue;
    read += 1;
    if (box.over > 0) cut += 1;
    worst = Math.max(worst, box.over);
  }
  report(
    "a label's first frame holds its whole box inside a phone-width page",
    read === 4 && cut === 0,
    `${read} of 4 first frames read, ${cut} with the box past an edge, worst ` +
      `${worst.toFixed(1)} px over`,
  );
  await page.evaluate(() => clearSelection());
  await page.setViewportSize({ width: 1200, height: 900 });
  await placeCamera(page, before);
  await settleCamera(page);
}

/** How far in from view's left and bottom edges frame's label box may stand, in pixels. */
const PIXELS_CORNER_LABEL = 56;

/** Drive horizon plane's selection, and assert its label stands inside frame's bottom-left corner.
 *
 *  Frame is whole view, so label has no top to sit above; it stood centred inside top
 *  edge, under chip row's controls. Anchor is on frame's left edge, pushed rightward by
 *  page's own measured text, `MARGIN_LABEL_FOOT` up, clear of scale bar in that corner.
 */
export async function driveFrameLabelCorner(page: Page): Promise<void> {
  await clearTheGlass(page);
  await page.evaluate(() => clearSelection());
  const plane = await page.evaluate(
    () => nimSceneHandles().find((one) => nimObjectKindWord(one) === 'horizon plane') ?? -1,
  );
  if (plane < 0) {
    report('the scene holds a horizon plane to select', false, 'none');
    return;
  }
  await page.evaluate((one) => selectOnly(one, null), plane);
  await settleCamera(page);
  await waitFrames(page, 2);
  const box = await labelBox(page);
  const ruler = await page.evaluate(() => {
    const bar = document.querySelector('.ruler');
    return bar === null ? null : bar.getBoundingClientRect().top;
  });
  report(
    "a horizon plane's label stands inside the frame's bottom-left corner, above the scale bar",
    box !== null && box.left > 0 && box.left < PIXELS_CORNER_LABEL
      && box.bottom < box.height && box.bottom > box.height - PIXELS_CORNER_LABEL
      && (ruler === null || box.bottom <= ruler),
    box === null ? 'no label' : `box ${box.left.toFixed(0)}..${box.right.toFixed(0)} across,`
      + ` ${box.top.toFixed(0)}..${box.bottom.toFixed(0)} down, in ${box.width} by`
      + ` ${box.height}; scale bar's top at ${ruler === null ? 'none' : ruler.toFixed(0)}`,
  );
  await page.evaluate(() => clearSelection());
}

/** Drive two picks, and assert each wears its own name above its marker. */
export async function driveLabelWorn(page: Page): Promise<void> {
  const points = await page.evaluate(
    () => nimSceneHandles().filter((one) => nimObjectKindWord(one) === 'point'),
  );
  await page.evaluate((given) => {
    selectOnly(given[0] ?? 0, null);
    toggleSelection(given[1] ?? 0, null);
  }, points);
  await waitFrames(page, 2); // Overlay is staged by frame loop, not by selection.

  const worn = await page.evaluate((given) => {
    const texts = (): Element[] => Array.from(document.querySelectorAll('#overlay text'));
    const two = texts().map((text) => ({
      text: text.textContent, fill: text.getAttribute('fill'),
      stroke: text.getAttribute('stroke'),
      y: Number(text.getAttribute('y')),
    }));
    const one = given[0] ?? 0;
    const rgb = nimInkColor(nimObjectInk(one));
    const paint = (colour: number[]): string =>
      Math.round((colour[0] ?? 0) * 255) + ',' + Math.round((colour[1] ?? 0) * 255) + ',' +
        Math.round((colour[2] ?? 0) * 255);
    const anchor = Array.from(nimAnchorScreen(one, window.innerWidth, window.innerHeight));
    // Halo wears backdrop's colour at marker.nim's alpha; see `overlay.COLOUR_LABEL_HALO`.
    const halo = 'rgba(' + paint(nimInkColor(nimInkBackdrop())) + ',' +
      (nimOverlayMetrics()[5] ?? 0) + ')';
    const face = texts().length > 0 ? getComputedStyle(texts()[0] as Element) : null;
    return {
      count: two.length, first: two.find((text) => text.text === nimObjectLabel(one)),
      ink: 'rgb(' + paint(rgb) + ')', halo, anchor_y: anchor[1] ?? 0,
      labels: [nimObjectLabel(one), nimObjectLabel(given[1] ?? 0)],
      weight: face?.fontWeight ?? '', size: face?.fontSize ?? '',
    };
  }, points);

  report(
    'a selected object wears its name above its marker, in its ink, haloed',
    worn.count === 2 && worn.first !== undefined && worn.first.fill === worn.ink &&
      worn.first.stroke === worn.halo && worn.first.y < worn.anchor_y &&
      worn.weight === '600' && worn.size === '16px',
    `${worn.count} labels for two selected (${worn.labels.join(', ')}); ` +
      (worn.first === undefined ? 'first label missing'
        : `fill ${worn.first.fill} (ink ${worn.ink}), y ${worn.first.y.toFixed(0)} above ` +
          `anchor ${worn.anchor_y.toFixed(0)}, ${worn.weight} at ${worn.size}`),
  );

  await clearTheGlass(page);
  await page.evaluate(() => clearSelection());
  await waitFrames(page, 2);
  const count_cleared = await page.evaluate(
    () => document.querySelectorAll('#overlay text').length,
  );
  report(
    'and nothing selected wears no label',
    count_cleared === 0, `${count_cleared} labels with nothing selected`,
  );
}
