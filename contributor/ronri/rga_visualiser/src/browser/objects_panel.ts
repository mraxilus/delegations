// Object list and its edit session; not Nim because these reach browser APIs Nim's JS backend does
//   not express.
//   Presentation alone: every join, meet, pick, drag and camera move is computed by
//   bridge, compiled from same modules desktop draws through (Article II.9).
//   Concatenated into page in order `tools/build.nim` names; see its `SCRIPTS`.

/* ---------------------------------------------------------------------- */
/* Objects panel: list, show/hide, remove, rename, recolour, edit         */
/* coefficients -- mirrors panel.layoutObjects / layoutItem exactly.      */
/* ---------------------------------------------------------------------- */

const list_objects = elementById('objects-list');
const count_objects = elementById('objects-count');
/* ---------------------------------------------------------------------- */
/* Edit session: one at time, in one of two modes -- composing brand-      */
/* new object (`handle` null, nothing backing it in scene yet) or            */
/* editing existing one. Both stage same four things and preview           */
/* through same ghost; only `save` reaches scene. State lives here         */
/* rather than in row's own closures because `refreshObjectsUI`            */
/* rebuilds every row from scratch, which would otherwise discard it.      */
/* ---------------------------------------------------------------------- */

// Item being composed or edited, or `null` where no session is open.
//   `handle` is null while composing, since object does not exist yet.
interface EditSession {
  handle: number | null;
  coefficients: number[];
  label: string;
  ink: number;
  radius: number;
  shines: boolean;
}
let session_edit: EditSession | null = null;

function beginEditSession(handle: number | null) {
  // Null handle composes; real handle edits that item. Seeding composing session from.
  //   Nim's own defaults keeps auto-label and cycled ink every other construction
  //   path assigns, while leaving both editable before object exists.
  session_edit = handle === null
    ? {
        handle: null,
        coefficients: new Array(nimBasisCount()).fill(0),
        label: nimDefaultLabel(),
        ink: nimDefaultInk(),
        radius: nimDefaultRadius(),
        shines: false,
      }
    : {
        handle,
        coefficients: Array.from(nimItemCoefficients(handle)),
        label: nimItemLabel(handle),
        ink: nimItemInk(handle),
        radius: nimItemRadius(handle),
        shines: nimItemShines(handle),
      };
  nimSetGhost(openSession().coefficients, openSession().radius);
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
  nimClearGhost();
}

// Two rows that are not object: note shown to empty list, and row.
//   composing session heads it with. Keys rather than positions, so reconcile below can
//   talk about every row same way.
const KEY_ROW_EMPTY = 'empty';
const KEY_ROW_PENDING = 'pending';
// What each key's row was picture of when it was last built. Compared, never ordered.
let signatures_row = new Map();

// Geometry line row shows, held per handle against scene's own revision.
//   **Costly half of signature, and function of geometry alone.** Measured at
//   1,024 objects, `nimFormatMultivector` is 11.8 ms of walk and `nimItemShapeWord` 2.9,
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
    held = nimItemShapeWord(handle) + ': ' + nimFormatMultivector(handle);
    text_geometry_row.set(handle, held);
  }
  return held;
}

function signatureOfItemRow(key: string) {
  // **Everything row draws, and nothing else.** Two equal signatures mean same.
  //   picture, so element standing there is already right and is left alone.
  if (key === KEY_ROW_EMPTY || key === KEY_ROW_PENDING) return key;
  const handle = parseInt(key, 10);
  // Open row is keyed by being open rather than described. Its fields preview.
  //   `session_edit` and its own handlers keep them current as reader types; rebuilding
  //   it on some unrelated refresh would take caret out of whatever field they were in.
  if (isEditing(handle)) return 'open:' + handle;
  return [
    nimItemLabel(handle), nimItemInk(handle), nimItemVisible(handle) ? 1 : 0,
    handles_selection.includes(handle) ? 1 : 0, geometryTextFor(handle),
  ].join('\u0001');
}

function buildRowFor(key: string) {
  if (key === KEY_ROW_EMPTY) {
    const p = document.createElement('div');
    p.className = 'help-text';
    p.style.margin = '8px 0 0';
    p.textContent = 'Nothing here yet -- press `add` above, or drag between two objects.';
    return p;
  }
  return buildItemRow(key === KEY_ROW_PENDING ? null : parseInt(key, 10));
}

function refreshObjectsUI() {
  // **Closed section builds nothing, and catches up when it opens.** Loading largest.
  //   size with this section collapsed built 5,038 rows for list nobody could see: 790 ms
  //   of 1,496 ms load, half of it, spent on picture that was not on screen. Count
  //   in header is written either way -- it is one string, it is visible while
  //   section is shut, and it is only part of this reader can see from there.
  //   Same shape as pool grid's `is_pool_stale` and diagnostics tick's own
  //   `open` check; section handler above is what redeems flag.
  count_objects.textContent =
    '(' + nimSceneCount() + ' of ' + nimSceneCapacity() + ')';
  // These two belong to *apply* section and to button above list, not to.
  //   rows -- they are refreshed here only because every caller that changes scene
  //   already calls this. So they run whether or not rows do: gating them behind
  //   objects section left operand pickers empty for reader who had collapsed it.
  refreshOperandOptions();
  refreshAddButton();
  if (!isDrawerObjectsOpen()) return;

  // **Reconciled against rows already standing, not rebuilt.** This used to empty.
  //   list and build every row again, which on 1,024-object demo was 570 ms of
  //   JavaScript and 164 ms of layout -- and there are dozen callers, so tap on `hide`
  //   paid all of it to change one checkbox.
  //   Built as diff rather than by making tap-driven callers call something narrower:
  //   list of `the cheap callers` is contract thirteenth caller breaks silently, and
  //   this way every caller is cheap, including ones not yet written. Refresh that
  //   changes nothing writes nothing. Same shape as `timings.RECORDS_FRAME`'s
  //   this-frame/last-frame pair and swap arena, one side of wire over.
  // **Ordered by bridge, not by comparator that calls it.** This used to sort by.
  //   `nimItemBorn`, which is two calls across FFI per comparison -- about 124,000 of
  //   them over 5,038 handles, and 165 ms of load, to reach order Nim can hand over.
  //   `nimSceneHandlesCreated` is that order already: `scene.handlesCreated` walks by
  //   creation ordinal, and replayed load stamps `born` in creation order, so reversing
  //   it is same "most recently added first" for one pass and no comparator at all.
  const handles = Array.from(nimSceneHandlesCreated()).reverse();
  const keys: string[] = [];
  if (handles.length === 0 && !isComposing()) keys.push(KEY_ROW_EMPTY);
  // Composing session heads list: it is newest thing here, and it has no.
  //   `born` reading to sort by since nothing backs it in scene yet.
  if (isComposing()) keys.push(KEY_ROW_PENDING);
  for (const handle of handles) keys.push(String(handle));

  // Snapshotted, not walked live: loop below inserts into this very collection.
  const standing = new Map<string, HTMLElement>();
  for (const node of Array.from(list_objects.children) as HTMLElement[]) {
    standing.set(node.dataset.key ?? '', node);
  }

  // **Built in slices, so long list cannot freeze page.** Five thousand rows is 820 ms.
  //   of element construction in one block -- whole of load, once bridge stopped
  //   deep-copying timeline -- and there is no version of that reader does not feel.
  //   Diff itself stays whole and synchronous: it is *building* that costs, and
  //   half-applied diff is only ever list that has not finished filling, never wrong one.
  //   Rows appear top-down as scene's own objects animate in, which is order
  //   they arrive in anyway.
  //   Refresh that finds everything already standing does no building and so never yields
  //   -- common case, tap on `hide`, stays exactly as immediate as it was.
  rows_pending = { keys, standing, signatures: new Map<string, string>(), at: 0 };
  sliceObjectRows();
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

function buildItemRow(handle: number | null) {
  // `handle === null` builds composing row: same layout, but nothing backs it in.
  //   scene, so everything it displays comes from `session_edit` and buttons that act
  //   on real object (hide, remove) are left out entirely.
  const is_pending = handle === null;
  const is_open = is_pending || isEditing(handle);

  const row = document.createElement('div');
  if (!is_pending) row.dataset.handle = String(handle); // Lets caller find one row again by handle.
  // Open row says so on itself: it is one row whose real height panel has to.
  //   know -- `scrollRowIntoView` scrolls to bring its edit form into view, and form
  //   standing behind 42px placeholder scrolls to placeholder. `shell.html` reads
  //   this class to keep open row out of containment other thousand are in.
  row.className = 'item-row'
    + (is_open ? ' editing-item' : '')
    + (is_pending ? ' pending-item' : '')
    + (!is_pending && handles_selection.includes(handle) ? ' selected' : '')
    + (!is_pending && !nimItemVisible(handle) ? ' hidden-item' : '');

  const top = document.createElement('div');
  top.className = 'item-top';

  // While session is open its staged values drive row, so swatch, label and.
  //   coefficient line preview edit without scene having changed.
  const inkOf = () => (is_open ? openSession().ink : nimItemInk(handle));
  const labelOf = () => (is_open ? openSession().label : nimItemLabel(handle));

  // Selection checkbox:
  //   mirrors/toggles membership in `handles_selection`, exactly same helper
  //   long-press/click-to-select already drives -- not visibility any more.
  const check_select = document.createElement('input');
  check_select.type = 'checkbox';
  check_select.checked = !is_pending && handles_selection.includes(handle);
  check_select.disabled = is_pending; // Nothing to select until it exists.
  check_select.title = 'Select or deselect this object.';
  if (!is_pending) check_select.addEventListener('change', () => toggleSelection(handle, null));
  top.appendChild(check_select);

  const swatch = document.createElement('span');
  swatch.className = 'swatch';
  swatch.style.background = rgbToCss(nimInkColor(inkOf()));
  top.appendChild(swatch);

  const label = document.createElement('span');
  label.className = 'item-label';
  label.textContent = labelOf();
  label.style.color = rgbToCss(nimInkColor(inkOf()));
  top.appendChild(label);

  const toggle_edit = document.createElement('button');
  toggle_edit.className = 'button item-edit-toggle';
  toggle_edit.type = 'button';
  toggle_edit.textContent = is_open ? 'save' : 'edit';
  toggle_edit.title = is_open
    ? 'Commit these values to the scene.'
    : 'Rename, recolour or reshape this object; nothing changes until you save.';
  toggle_edit.addEventListener('click', () => {
    if (!is_open) { beginEditSession(handle); refreshObjectsUI(); return; }
    if (is_pending && nimSceneCount() >= nimSceneCapacity()) { toast('Scene is full.'); return; }
    if (is_pending) {
      nimAddItem(
        openSession().coefficients, openSession().label, openSession().ink, openSession().radius,
        openSession().shines, now(),
      );
      endEditSession();
      adoptConstructionSelection();
      toast('Added `' + label.textContent + '`.');
    } else {
      nimCommitItem(
        handle, openSession().coefficients, openSession().label, openSession().ink,
        openSession().radius, openSession().shines,
      );
      endEditSession();
      toast('Saved `' + label.textContent + '`.');
    }
    refreshObjectsUI();
    refreshUndoRedoButtons();
  });
  top.appendChild(toggle_edit);

  if (is_open) {
    // Abandon: composing row vanishes with nothing added, editing row reverts. In.
    //   both cases scene was never touched, so this only has to drop session.
    const cancel = document.createElement('button');
    cancel.className = 'button item-edit-cancel';
    cancel.type = 'button';
    cancel.textContent = '✕';
    cancel.title = is_pending ? 'Discard this new object.' : 'Discard these changes.';
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
    visibility.className = 'button item-visibility';
    visibility.type = 'button';
    visibility.textContent = nimItemVisible(handle) ? 'hide' : 'show';
    visibility.title = 'Show or hide this object without removing it.';
    visibility.addEventListener('click', () => {
      const was_visible = nimItemVisible(handle);
      nimSetVisible(handle, !was_visible);
      visibility.textContent = was_visible ? 'show' : 'hide'; // Local flip, no full rebuild.
      row.classList.toggle('hidden-item', was_visible);
    });
    top.appendChild(visibility);

    const remove = document.createElement('button');
    remove.className = 'button item-remove';
    remove.type = 'button';
    remove.textContent = 'remove';
    remove.title = "Delete this object; its handle is reused by the next one you add.";
    remove.addEventListener('click', () => {
      nimRemoveItem(handle); // Drops handle from selection itself, so stale pick
        // cannot linger and read as "selected" once future add reuses freed handle.
      if (isEditing(handle)) endEditSession(); // Its session has nothing left to commit to.
      toast('Removed `' + label.textContent + '`.');
      onSelectionChanged(null);
    });
    top.appendChild(remove);
  }

  row.appendChild(top);

  const line_coefficient = document.createElement('div');
  line_coefficient.className = 'item-coefficient';
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
  //   `nimItemCoefficients` call across FFI for every row of every rebuild, to fill
  //   inputs nobody could see.
  //   Nothing was reachable in there anyway: every field writes into `session_edit`, which
  //   is null unless session is open, so hidden form could only have thrown.
  if (is_open) {
    const box_edit = document.createElement('div');
    box_edit.className = 'item-edit' + (is_open ? ' open' : '');

    const field_label = document.createElement('div');
    field_label.className = 'field';
    field_label.innerHTML = '<label>label</label>';
    // Write every field below into session, never scene.
    //   Row's own swatch, label and coefficient line preview change, ghost previews
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
    field_ink.innerHTML = '<label>colour</label>';
    const picker_ink = document.createElement('select');
    // Only categorical slots are offerable; `nimInkChoosableSlots` decides which those.
    //   are, so no palette rule lives out here. Its entries stay whole-palette ordinals,
    //   same ones `nimItemInk` reports and `nimInkName`/`nimInkColor` accept.
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
    field_radius.innerHTML = '<label>size</label>';
    const input_radius = document.createElement('input');
    input_radius.type = 'number';
    input_radius.min = String(nimLeastRadius());
    input_radius.step = 'any';
    input_radius.value = nimFormatNumber(openSession().radius);
    input_radius.title = 'Radius the point is drawn at, in world units; it shrinks with distance.';
    input_radius.addEventListener('input', () => {
      const typed = parseFloat(input_radius.value);
      openSession().radius = Number.isFinite(typed) && typed >= nimLeastRadius()
        ? typed : nimDefaultRadius();
      nimSetGhost(openSession().coefficients, openSession().radius); // Ghost shows size too.
    });
    field_radius.appendChild(input_radius);
    box_edit.appendChild(field_radius);

    // Sun: point every other point is shaded from, drawn flat itself; see `lighting`.
    const field_shines = document.createElement('label');
    field_shines.className = 'field field-check';
    const input_shines = document.createElement('input');
    input_shines.type = 'checkbox';
    input_shines.checked = openSession().shines;
    input_shines.addEventListener('change', () => { openSession().shines = input_shines.checked; });
    field_shines.appendChild(input_shines);
    field_shines.appendChild(document.createTextNode(' shines'));
    field_shines.title = 'A sun: lights every other point from where it stands.';
    box_edit.appendChild(field_shines);

    const note_coefficient = document.createElement('div');
    note_coefficient.className = 'help-text';
    note_coefficient.style.margin = '6px 0';
    note_coefficient.textContent = is_pending
      ? 'The 16 numbers of the new multivector, in the library’s basis order. ' +
        'A live preview draws as soon as any goes non-zero.'
      : 'The 16 numbers of this object’s own multivector, in the library’s basis ' +
        'order. The object itself only moves when you save.';
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
          : nimItemCoefficients(handle)[b] ?? 0),
    );
    inputs_coefficient.forEach((input, b) => {
      // `input`, not `change`: ghost tracks keystroke rather than waiting for.
      //   field to blur, which is what makes preview feel live.
      input.addEventListener('input', () => {
        openSession().coefficients[b] = parseFloat(input.value) || 0;
        nimSetGhost(openSession().coefficients, openSession().radius);
        line_coefficient.textContent = describeStaged();
      });
    });
    box_edit.appendChild(grid);

    row.appendChild(box_edit);
  }
  return row;
}

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
