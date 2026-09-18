// Object list and its edit session; not Nim because these reach browser APIs Nim's JS backend does
//   not express.
//   Presentation alone: every join, meet, pick, drag and camera move is computed by
//   bridge, compiled from same modules desktop draws through (Article II.9).
//   Concatenated into page in order `tools/build.nim` names; see its `SCRIPTS`.

/* ---------------------------------------------------------------------- */
/* Objects panel: list, show/hide, remove, rename, recolour, edit         */
/* coefficients -- mirrors panel.layoutObjects / layoutObject exactly.      */
/* ---------------------------------------------------------------------- */

const list_objects = elementById('objects-list');
const count_objects = elementById('objects-count');
/* ---------------------------------------------------------------------- */
/* Edit session: one at time, in one of two modes -- composing brand-      */
/* new object (`handle` null, nothing backing it in scene yet) or            */
/* editing existing one. Both stage same four things and preview           */
/* through same preview; only `save` reaches scene. State lives here         */
/* rather than in row's own closures because `refreshObjectsUI`            */
/* rebuilds every row from scratch, which would otherwise discard it.      */
/* ---------------------------------------------------------------------- */

// Object being composed or edited, or `null` where no session is open.
//   `handle` is null while composing, since object does not exist yet.
interface EditSession {
  handle: number | null;
  coefficients: number[];
  label: string;
  ink: number;
  radius: number;
}
let session_edit: EditSession | null = null;

function beginEditSession(handle: number | null) {
  // Null handle composes; real handle edits that object. Seeding composing session from.
  //   Nim's own defaults keeps auto-label and cycled ink every other construction
  //   path assigns, while leaving both editable before object exists.
  session_edit = handle === null
    ? {
        handle: null,
        coefficients: new Array(nimBasisCount()).fill(0),
        label: nimDefaultLabel(),
        ink: nimDefaultInk(),
        radius: nimDefaultRadius(),
      }
    : {
        handle,
        coefficients: Array.from(nimObjectCoefficients(handle)),
        label: nimObjectLabel(handle),
        ink: nimObjectInk(handle),
        radius: nimObjectRadius(handle),
      };
  nimSetPreviewStaged(openSession().coefficients, openSession().radius);
}

// Read session caller has already established is open.
//   `is_open`, `is_pending` and `isComposing` are what guarantee it; this is where that
//   guarantee is stated to type-checker rather than repeated as null test per field.
//   Throwing names contradiction, where reading field off nothing would report failure
//   somewhere else entirely (Article IV.4).
function openSession(): EditSession {
  if (session_edit === null) throw new Error('No edit session open.');
  return session_edit;
}


function endEditSession() {
  session_edit = null;
  nimClearPreviewStaged();
}

// Two rows that are not object: note shown to empty list, and row.
//   composing session heads it with. Keys rather than positions, so reconcile below can
//   talk about every row same way.
const KEY_ROW_EMPTY = 'empty';
const KEY_ROW_PENDING = 'pending';
// What each standing row was picture of when it was built. Compared, never ordered; row that
//   leaves window takes its entry with it, so map is exactly rows standing.
let signatures_row = new Map<string, string>();

// Geometry line row shows, held per handle against scene's own revision.
//   **Costly half of signature, and function of geometry alone.** Measured at
//   1,024 objects, `nimFormatMultivector` is 11.8 ms of walk and `nimObjectKindWord` 2.9,
//   against 0.8 ms for every other field row draws put together. Geometry changes only
//   when `scene.revision` does -- every writer bumps it, which is what frame hold and
//   placement cache already rest on -- so text is re-derived when revision moves
//   and reused otherwise. Selection change, which is what most refreshes are, moves no
//   revision and re-derives nothing.
//   Cleared whole rather than per handle: revision is scene's, not handle's, so
//   edit re-derives every row. That is same over-approximation `PLACEMENTS` makes, and it
//   costs one deliberate action walk it would have paid anyway.
let text_geometry_row = new Map();
let revision_geometry_row = -1;

function geometryTextFor(handle: number) {
  const revision = nimSceneRevision();
  if (revision_geometry_row !== revision) {
    revision_geometry_row = revision;
    text_geometry_row = new Map();
  }
  let held = text_geometry_row.get(handle);
  if (held === undefined) {
    held = nimObjectKindWord(handle) + ': ' + nimFormatMultivector(handle);
    text_geometry_row.set(handle, held);
  }
  return held;
}

function signatureOfObjectRow(key: string) {
  // **Everything row draws, and nothing else.** Two equal signatures mean same.
  //   picture, so element standing there is already right and is left alone.
  if (key === KEY_ROW_EMPTY || key === KEY_ROW_PENDING) return key;
  const handle = parseInt(key, 10);
  // Open row is keyed by being open rather than described. Its fields preview.
  //   `session_edit` and its own handlers keep them current as reader types; rebuilding
  //   it on some unrelated refresh would take caret out of whatever field they were in.
  if (isEditing(handle)) return 'open:' + handle;
  return [
    nimObjectLabel(handle), nimObjectInk(handle), nimObjectVisible(handle) ? 1 : 0,
    handles_selection.includes(handle) ? 1 : 0, geometryTextFor(handle),
  ].join('\u0001');
}

function buildRowFor(key: string) {
  if (key === KEY_ROW_EMPTY) {
    const p = document.createElement('div');
    p.className = 'help-text';
    p.style.margin = '8px 0 0';
    p.textContent = nimWording(Wording.NoteListEmpty);
    return p;
  }
  return buildObjectRow(key === KEY_ROW_PENDING ? null : parseInt(key, 10));
}

// **Only rows near viewport exist.** List is window over its keys: two spacers stand in.
//   for rows above and below it at heights they measured, or `PIXELS_ROW_ESTIMATE` until
//   they have, and window covers scroller's height plus `SCREENS_SLACK_WINDOW` each side.
//   Building every row, even in time-bounded slices, was 2,862 ms of list filling across 33
//   frames of 80 ms at 5,038 objects, and 45,813 elements standing after -- freeze on first
//   opening, and every write in drawer after it paid for tree that size.
//   Scroll marks window stale and frame loop settles it (`settleObjectWindow`), so cost lands
//   in `ui` phase beside rest; refresh renders at once, so caller that changed scene finds its
//   row standing before call returns.
// Keys of every row list stands for, in order, as of last refresh.
let keys_list: string[] = [];
// Height each row stands at, by key, kept across refreshes; row never yet stood has none.
const heights_row = new Map<string, number>();
// Same heights by index into `keys_list`, so walk on scroll is over numbers, not map.
let heights_list: number[] = [];
// Collapsed row's modal height: 930 of demo's 1,024 measure 61 px, and 93 wrap coefficients to
//   76. Row above viewport measured taller than this once scrolled to is held in place by
//   browser's own scroll anchoring; see `.object-spacer` in `shell.html`.
const PIXELS_ROW_ESTIMATE = 61;
// Screens of rows built beyond viewport, each side. Fling at 2,000 px/s moves 160 px in 80 ms
//   frame, and one screen is several times that.
const SCREENS_SLACK_WINDOW = 1;
// Where each standing row's key sits in `keys_list`, so measurement can patch by index.
const index_of_row = new WeakMap<Element, number>();
// Scene and session keys were last built against; unchanged means keys need no rebuilding.
let stamp_keys_list = '';
const spacer_top = document.createElement('div');
const spacer_bottom = document.createElement('div');
spacer_top.className = 'object-spacer';
spacer_bottom.className = 'object-spacer';
list_objects.append(spacer_top, spacer_bottom);
// Drawer's one scroller, which window below is measured against.
const scroller = document.querySelector('.drawer-scroll');
// Set by scroll and resize, cleared by render, read by frame loop.
let is_window_stale = false;
if (scroller !== null) {
  scroller.addEventListener('scroll', () => { is_window_stale = true; }, { passive: true });
}
window.addEventListener('resize', () => { is_window_stale = true; });

// Heights read after layout, never inside scroll path: reading box inside scroll handler lays
//   document out inside that event, bargain `sizes.ts` states at length. Row that changes size
//   without rebuilding -- coefficient line wrapping as reader types, drawer narrowing -- reports
//   here too, which no measurement at build time would see.
const measurer_rows = typeof ResizeObserver === 'function'
  ? new ResizeObserver((entries) => {
      for (const entry of entries) {
        const node = entry.target as HTMLElement;
        const height = entry.borderBoxSize[0]?.blockSize ?? node.offsetHeight;
        if (height <= 0) continue; // Section shut reports every row at nothing.
        const key = node.dataset.key ?? '';
        heights_row.set(key, height);
        const at = index_of_row.get(node);
        if (at !== undefined && keys_list[at] === key) heights_list[at] = height;
      }
    })
  : null;

function heightOf(key: string): number { return heights_row.get(key) ?? PIXELS_ROW_ESTIMATE; }

function refreshObjectsUI() {
  // **Closed section builds nothing, and catches up when it opens.** Count in header is.
  //   written either way -- it is one string, it is visible while section is shut, and it is
  //   only part of this reader can see from there. Same shape as pool grid's `is_pool_stale`
  //   and diagnostics tick's own `open` check; section handler is what redeems flag.
  count_objects.textContent =
    '(' + nimSceneCount() + ' of ' + nimSceneCapacity() + ')';
  // These two belong to *apply* section and to button above list, not to.
  //   rows -- they are refreshed here only because every caller that changes scene
  //   already calls this. So they run whether or not rows do: gating them behind
  //   objects section left operand pickers empty for reader who had collapsed it.
  refreshOperandOptions();
  refreshAddButton();
  if (!isDrawerObjectsOpen()) return;

  // **Keys rebuilt only when scene or session moved.** Revision moves on every edit, count on.
  //   every add and remove, and composing row is only other row there is; refresh on selection
  //   alone, which is most of them, keeps five thousand keys and their heights as they stand.
  // **Ordered by bridge, not by comparator that calls it.** `nimSceneHandlesCreated` walks by.
  //   creation ordinal, and replayed load stamps `born` in creation order, so reversing it is
  //   "most recently added first" for one pass and no comparator at all -- sorting by
  //   `nimObjectBorn` was two calls across FFI per comparison, 124,000 over 5,038 handles.
  const stamp = nimSceneRevision() + ':' + nimSceneCount() + ':' + (isComposing() ? 'p' : '');
  if (stamp !== stamp_keys_list) {
    stamp_keys_list = stamp;
    const handles = Array.from(nimSceneHandlesCreated()).reverse();
    keys_list = [];
    if (handles.length === 0 && !isComposing()) keys_list.push(KEY_ROW_EMPTY);
    // Composing session heads list: it is newest thing here, and it has no.
    //   `born` reading to sort by since nothing backs it in scene yet.
    if (isComposing()) keys_list.push(KEY_ROW_PENDING);
    for (const handle of handles) keys_list.push(String(handle));
    heights_list = keys_list.map(heightOf);
    // What list stands for, for harness that cannot count rows it does not build.
    list_objects.dataset.count = String(handles.length);
  }
  renderObjectWindow();
}

function renderObjectWindow() {
  // Rows around viewport, reconciled against rows already standing; see `keys_list`.
  is_window_stale = false;
  if (scroller === null) return;
  // Harness or reset that emptied list took spacers with it.
  if (spacer_top.parentNode !== list_objects) list_objects.prepend(spacer_top);
  if (spacer_bottom.parentNode !== list_objects) list_objects.append(spacer_bottom);

  const height_view = scroller.clientHeight;
  const top_list = list_objects.getBoundingClientRect().top
    - scroller.getBoundingClientRect().top + scroller.scrollTop;
  const from = scroller.scrollTop - top_list - height_view * SCREENS_SLACK_WINDOW;
  const until = from + height_view * (1 + 2 * SCREENS_SLACK_WINDOW);

  // Walk to window's edges. Numbers, not map: five thousand adds is microseconds.
  const count = keys_list.length;
  let lo = 0;
  let y_lo = 0;
  while (lo < count && y_lo + (heights_list[lo] ?? PIXELS_ROW_ESTIMATE) <= from) {
    y_lo += heights_list[lo] ?? PIXELS_ROW_ESTIMATE;
    lo += 1;
  }
  let hi = lo;
  let y_hi = y_lo;
  while (hi < count && y_hi < until) {
    y_hi += heights_list[hi] ?? PIXELS_ROW_ESTIMATE;
    hi += 1;
  }
  let y_end = y_hi;
  for (let at = hi; at < count; at += 1) y_end += heights_list[at] ?? PIXELS_ROW_ESTIMATE;

  // Rows outside window, or for keys scene no longer has, go; signatures with them.
  //   Snapshotted, not walked live: loop below inserts into this very collection.
  const wanted = new Set<string>();
  for (let at = lo; at < hi; at += 1) wanted.add(keys_list[at] ?? '');
  const standing = new Map<string, HTMLElement>();
  for (const node of Array.from(list_objects.children) as HTMLElement[]) {
    if (node === spacer_top || node === spacer_bottom) continue;
    const key = node.dataset.key ?? '';
    if (wanted.has(key)) standing.set(key, node);
    else dropRow(node, key);
  }

  // **Reconciled against rows already standing, not rebuilt.** Two equal signatures mean.
  //   same picture, so element standing there is already right and is left alone: refresh
  //   that changes nothing writes nothing, and tap on `hide` stays immediate. Built as diff
  //   rather than by making tap-driven callers call something narrower: list of `the cheap
  //   callers` is contract thirteenth caller breaks silently.
  for (let at = lo; at < hi; at += 1) {
    const key = keys_list[at] ?? '';
    const signature = signatureOfObjectRow(key);
    let node = standing.get(key);
    if (node === undefined || signatures_row.get(key) !== signature) {
      if (node !== undefined) dropRow(node, key);
      node = buildRowFor(key);
      node.dataset.key = key;
      signatures_row.set(key, signature);
      measurer_rows?.observe(node);
    }
    index_of_row.set(node, at);
    node.classList.toggle('first', at === 0);
    // Already in right place is common case; otherwise this moves it there.
    const place = 1 + (at - lo);
    if (list_objects.children[place] !== node) {
      list_objects.insertBefore(node, list_objects.children[place] ?? null);
    }
  }
  const above = y_lo + 'px';
  const below = (y_end - y_hi) + 'px';
  if (spacer_top.style.height !== above) spacer_top.style.height = above;
  if (spacer_bottom.style.height !== below) spacer_bottom.style.height = below;
}

function dropRow(node: HTMLElement, key: string) {
  measurer_rows?.unobserve(node);
  node.remove();
  signatures_row.delete(key);
}

/** Settle window frame loop found stale, and say whether it did. */
function settleObjectWindow(): boolean {
  if (!is_window_stale) return false;
  is_window_stale = false;
  if (!isDrawerObjectsOpen()) return false;
  renderObjectWindow();
  return true;
}

function revealObjectRow(key: string) {
  // Scroll list to this key's row and render window there, in one call. Offset is sum of.
  //   heights above it, estimate where row has never stood, so row lands inside window and
  //   one reading of where it actually stands corrects rest. Placed under pinned heading rather
  //   than at scroller's own edge, which heading covers; see `.section-header`.
  if (scroller === null) return;
  const at = keys_list.indexOf(key);
  if (at < 0) return;
  let offset = 0;
  for (let i = 0; i < at; i += 1) offset += heights_list[i] ?? PIXELS_ROW_ESTIMATE;
  const heading = document.querySelector('.section[data-section="objects"] .section-header');
  const clearance = heading === null ? 0 : heading.getBoundingClientRect().height;
  const box_scroller = scroller.getBoundingClientRect();
  const top_list = list_objects.getBoundingClientRect().top - box_scroller.top
    + scroller.scrollTop;
  scroller.scrollTop = top_list + offset - clearance;
  renderObjectWindow();
  const row = list_objects.querySelector('[data-key="' + key + '"]');
  if (row === null) return;
  scroller.scrollTop += row.getBoundingClientRect().top - box_scroller.top - clearance;
}

function isComposing() { return session_edit !== null && session_edit.handle === null; }

function isEditing(handle: number) {
  return session_edit !== null && session_edit.handle === handle;
}

function refreshAddButton() {
  // Disabled while any session is open, so starting second one cannot silently.
  //   discard first -- same treatment undo/redo get when their side is empty.
  writeDisabled(button_add, session_edit !== null || nimSceneCount() >= nimSceneCapacity());
}

function buildObjectRow(handle: number | null) {
  // `handle === null` builds composing row: same layout, but nothing backs it in.
  //   scene, so everything it displays comes from `session_edit` and buttons that act
  //   on real object (hide, remove) are left out entirely.
  const is_pending = handle === null;
  const is_open = is_pending || isEditing(handle);

  const row = document.createElement('div');
  if (!is_pending) row.dataset.handle = String(handle); // Lets caller find one row again by handle.
  row.className = 'object-row'
    + (is_pending ? ' pending-object' : '')
    + (!is_pending && handles_selection.includes(handle) ? ' selected' : '')
    + (!is_pending && !nimObjectVisible(handle) ? ' hidden-object' : '');

  const top = document.createElement('div');
  top.className = 'object-top';

  // While session is open its staged values drive row, so swatch, label and.
  //   coefficient line preview edit without scene having changed.
  const inkOf = () => (is_open ? openSession().ink : nimObjectInk(handle));
  const labelOf = () => (is_open ? openSession().label : nimObjectLabel(handle));

  // Selection checkbox:
  //   mirrors/toggles membership in `handles_selection`, exactly same helper
  //   long-press/click-to-select already drives -- not visibility any more.
  const check_select = document.createElement('input');
  check_select.type = 'checkbox';
  check_select.checked = !is_pending && handles_selection.includes(handle);
  check_select.disabled = is_pending; // Nothing to select until it exists.
  check_select.title = nimWording(Wording.TipRowSelect);
  if (!is_pending) check_select.addEventListener('change', () => toggleSelection(handle, null));
  top.appendChild(check_select);

  const swatch = document.createElement('span');
  swatch.className = 'swatch';
  swatch.style.background = rgbToCss(nimInkColor(inkOf()));
  top.appendChild(swatch);

  const label = document.createElement('span');
  label.className = 'object-label';
  label.textContent = labelOf();
  label.style.color = rgbToCss(nimInkColor(inkOf()));
  top.appendChild(label);

  const toggle_edit = document.createElement('button');
  toggle_edit.className = 'button object-edit-toggle';
  toggle_edit.type = 'button';
  toggle_edit.textContent =
    nimWording(is_open ? Wording.NameRowCommit : Wording.NameRowEdit);
  toggle_edit.title = nimWording(is_open ? Wording.TipRowCommit : Wording.TipRowEdit);
  toggle_edit.addEventListener('click', () => {
    if (!is_open) { beginEditSession(handle); refreshObjectsUI(); return; }
    if (is_pending && nimSceneCount() >= nimSceneCapacity()) { toast(nimFullMessage()); return; }
    if (is_pending) {
      nimAddObject(
        openSession().coefficients, openSession().label, openSession().ink, openSession().radius,
        now(),
      );
      endEditSession();
      adoptConstructionSelection();
      toast(nimAddedMessage(label.textContent ?? ''));
    } else {
      nimCommitObject(
        handle, openSession().coefficients, openSession().label, openSession().ink,
        openSession().radius,
      );
      endEditSession();
      toast(nimSavedMessage(label.textContent ?? ''));
    }
    refreshObjectsUI();
    refreshUndoRedoButtons();
  });
  top.appendChild(toggle_edit);

  if (is_open) {
    // Abandon: composing row vanishes with nothing added, editing row reverts. In.
    //   both cases scene was never touched, so this only has to drop session.
    const cancel = document.createElement('button');
    cancel.className = 'button object-edit-cancel';
    cancel.type = 'button';
    cancel.textContent = nimWording(Wording.NameRowDiscard);
    cancel.title = nimWording(is_pending ? Wording.TipRowDiscardNew : Wording.TipRowDiscardEdit);
    cancel.addEventListener('click', () => {
      endEditSession();
      refreshObjectsUI();
    });
    top.appendChild(cancel);
  }

  if (!is_open) {
    // Hide/show and remove act on object as scene holds it, which is exactly what.
    //   open session is staging replacement for -- offering them mid-edit invites
    //   acting on one version while looking at another. Composing row has no object at
    //   all yet, so both are left out rather than shown disabled either way.
    const visibility = document.createElement('button');
    visibility.className = 'button object-visibility';
    visibility.type = 'button';
    visibility.textContent = visibilityLabel(
      nimObjectVisible(handle), Wording.NameRowHide, Wording.NameRowShow,
    );
    visibility.title = nimWording(Wording.TipRowVisible);
    visibility.addEventListener('click', () => {
      const was_visible = nimObjectVisible(handle);
      nimSetVisible(handle, !was_visible);
      // Local flip, no full rebuild.
      visibility.textContent = visibilityLabel(
        !was_visible, Wording.NameRowHide, Wording.NameRowShow,
      );
      row.classList.toggle('hidden-object', was_visible);
    });
    top.appendChild(visibility);

    const remove = document.createElement('button');
    remove.className = 'button object-remove';
    remove.type = 'button';
    remove.textContent = nimWording(Wording.NameRowRemove);
    remove.title = nimWording(Wording.TipRowRemove);
    remove.addEventListener('click', () => {
      nimRemoveObject(handle); // Drops handle from selection itself, so stale pick
        // cannot linger and read as "selected" once future add reuses freed handle.
      if (isEditing(handle)) endEditSession(); // Its session has nothing left to commit to.
      toast(nimRemovedMessage(label.textContent ?? ''));
      onSelectionChanged(null);
    });
    top.appendChild(remove);
  }

  row.appendChild(top);

  const line_coefficient = document.createElement('div');
  line_coefficient.className = 'object-coefficient';
  const describeStaged = () =>
    is_open ? nimDescribeCoefficients(openSession().coefficients)
           : geometryTextFor(handle);
  line_coefficient.textContent = describeStaged();
  row.appendChild(line_coefficient);

  // **Built only for row that is open, which is at most one of them.** Everything.
  //   below is edit form, and closed row used to build whole of it -- label
  //   field, ink picker with option per choosable handle, and grid with input per
  //   basis element -- and then let CSS hide it. Measured on 1,024-object demo that was
  //   **76 elements per collapsed row and 80,325 on page**, against 843 on opening
  //   scene; one rebuild of list cost 570 ms of JavaScript and 164 ms of layout, so
  //   tap on `hide` froze page for three quarters of second. It also meant
  //   `nimObjectCoefficients` call across FFI for every row of every rebuild, to fill
  //   inputs nobody could see.
  //   Nothing was reachable in there anyway: every field writes into `session_edit`, which
  //   is null unless session is open, so hidden form could only have thrown.
  if (is_open) {
    const box_edit = document.createElement('div');
    box_edit.className = 'object-edit' + (is_open ? ' open' : '');

    const field_label = document.createElement('div');
    field_label.className = 'field';
    field_label.appendChild(labelElement(Wording.NameRowLabel));
    // Write every field below into session, never scene.
    //   Row's own swatch, label and coefficient line preview change, preview previews
    //   geometry, and only `save` above reaches `SCENE`.
    const input_label = document.createElement('input');
    input_label.type = 'text';
    input_label.value = labelOf();
    input_label.maxLength = 39;
    input_label.addEventListener('input', () => {
      openSession().label = input_label.value;
      label.textContent = input_label.value;
    });
    field_label.appendChild(input_label);
    box_edit.appendChild(field_label);

    const field_ink = document.createElement('div');
    field_ink.className = 'field';
    field_ink.appendChild(labelElement(Wording.NameRowInk));
    const picker_ink = document.createElement('select');
    // Only categorical slots are offerable; `nimInkChoosableSlots` decides which those.
    //   are, so no palette rule lives out here. Its entries stay whole-palette ordinals,
    //   same ones `nimObjectInk` reports and `nimInkName`/`nimInkColor` accept.
    for (const ink of nimInkChoosableSlots()) {
      const option = document.createElement('option');
      option.value = String(ink);
      option.textContent = nimInkName(ink);
      picker_ink.appendChild(option);
    }
    picker_ink.value = String(inkOf());
    picker_ink.addEventListener('change', () => {
      openSession().ink = parseInt(picker_ink.value, 10);
      const rgb = nimInkColor(openSession().ink);
      swatch.style.background = rgbToCss(rgb);
      label.style.color = rgbToCss(rgb);
    });
    field_ink.appendChild(picker_ink);
    box_edit.appendChild(field_ink);

    // Size reads for point alone; line and plane take theirs from camera and horizon.
    //   World units, so what is typed shrinks with distance like everything else drawn
    //   at position. Bounded below at what editor accepts, since model refuses zero
    //   outright and would take page down with it.
    const field_radius = document.createElement('div');
    field_radius.className = 'field';
    field_radius.appendChild(labelElement(Wording.NameRowSize));
    const input_radius = document.createElement('input');
    input_radius.type = 'number';
    input_radius.min = String(nimLeastRadius());
    input_radius.step = 'any';
    input_radius.value = nimFormatNumber(openSession().radius);
    input_radius.title = nimWording(Wording.TipRowRadius);
    input_radius.addEventListener('input', () => {
      const typed = parseFloat(input_radius.value);
      openSession().radius = Number.isFinite(typed) && typed >= nimLeastRadius()
        ? typed : nimDefaultRadius();
      // Preview shows staged size too, not just staged place.
      nimSetPreviewStaged(openSession().coefficients, openSession().radius);
    });
    field_radius.appendChild(input_radius);
    box_edit.appendChild(field_radius);

    const note_coefficient = document.createElement('div');
    note_coefficient.className = 'help-text';
    note_coefficient.style.margin = '6px 0';
    note_coefficient.textContent = nimWording(
      is_pending ? Wording.NoteCoefficientsNew : Wording.NoteCoefficientsEdit,
    );
    box_edit.appendChild(note_coefficient);

    const grid = document.createElement('div');
    grid.className = 'coefficient-grid';
    // `nimFormatNumber`, not `toFixed` here: how many digits coefficient is worth.
    //   is decision about this project's numbers, and desktop's own cells make it
    //   same way.
    const inputs_coefficient = buildGradedCoefficientGrid(
      grid,
      (b) =>
        nimFormatNumber(is_open
          ? openSession().coefficients[b] ?? 0
          : nimObjectCoefficients(handle)[b] ?? 0),
    );
    inputs_coefficient.forEach((input, b) => {
      // `input`, not `change`: preview tracks keystroke rather than waiting for.
      //   field to blur, which is what makes preview feel live.
      input.addEventListener('input', () => {
        openSession().coefficients[b] = parseFloat(input.value) || 0;
        nimSetPreviewStaged(openSession().coefficients, openSession().radius);
        line_coefficient.textContent = describeStaged();
      });
    });
    box_edit.appendChild(grid);

    row.appendChild(box_edit);
  }
  return row;
}

// Set here rather than in markup: shown text has one home, and attribute in
//   `shell.html` could only hold second copy of it.
elementById('button-save-scene').title = nimWording(Wording.TipMenuSaveScene);
elementById('button-load-scene').title = nimWording(Wording.TipMenuLoadScene);
elementById('button-save-scene').addEventListener('click', saveScene);
elementById('button-load-scene').addEventListener('click', () => {
  elementById('file-load-scene').click();
});
elementById<HTMLInputElement>('file-load-scene').addEventListener('change', (e) => {
  const input = e.currentTarget as HTMLInputElement;
  const file = input.files?.[0];
  if (file) loadSceneFile(file);
  input.value = '';
});
