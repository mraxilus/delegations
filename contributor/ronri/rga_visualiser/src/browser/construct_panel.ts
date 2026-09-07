// Add-point and apply-operation controls; not Nim because these reach browser APIs Nim's JS backend
//   does not express.
//   Presentation alone: every join, meet, pick, drag and camera move is computed by
//   bridge, compiled from same modules desktop draws through (Article II.9).
//   Concatenated into page in order `tools/build.nim` names; see its `SCRIPTS`.

/* ---------------------------------------------------------------------- */
/* Construct panel: add point, apply operation -- mirrors                 */
/* panel.layoutPointNew / panel.layoutOperation exactly.                  */
/* ---------------------------------------------------------------------- */

const picker_arity = elementById('op-arity');
const picker_operation = elementById<HTMLSelectElement>('op-select');
const picker_operand_first = elementById<HTMLSelectElement>('op-first');
const picker_operand_second = elementById<HTMLSelectElement>('op-second');
const field_operand_second = elementById('op-second-field');

let arity_current = 0; // 0 = unary, 1 = binary -- matches nimOperationArity's own convention.

function populateOperations() {
  const value_previous = picker_operation.value;
  picker_operation.innerHTML = '';
  const count = nimOperationCount();
  for (let i = 0; i < count; i++) {
    if (nimOperationArity(i) !== arity_current) continue;
    const option = document.createElement('option');
    option.value = String(i);
    option.textContent = nimOperationNotation(i);
    picker_operation.appendChild(option);
  }
  // Fall back to new list's first option where previous selection's index is absent.
  //   Switching arity can leave it absent from new, filtered option list, and
  //   opSelect.value must not point at now-nonexistent <option>.
  if (picker_operation.querySelector('option[value="' + value_previous + '"]')) {
    picker_operation.value = value_previous;
  } else {
    // Fresh list opens on what was last applied at this arity, not on its own head.
    picker_operation.value = String(nimOperationRemembered(arity_current));
  }
  updateOperandEnablement();
  ghostDrawerOperation();
}

picker_arity.querySelectorAll('button[data-arity]').forEach((button) => {
  button.addEventListener('click', () => {
    arity_current = parseInt((button as HTMLElement).dataset.arity ?? '0', 10);
    picker_arity.querySelectorAll('button[data-arity]').forEach(
      (each) => each.classList.toggle('on', each === button),
    );
    populateOperations();
  });
});

function ghostDrawerOperation() {
  // Preview what `apply` would build, live while this section is open.
  //   Follows operation and both operands, since preview that ignored half its own
  //   inputs would be showing something button beside it would not build.
  //   Nim decides what preview is worth showing; this only says which three readings to
  //   try.
  //   Drawer names its own operands, so it reads them rather than selection.
  if (!isDrawerApplyOpen()) { nimClearPreview(); return; }
  const handles = nimSceneHandles();
  const first = handles[parseInt(picker_operand_first.value, 10)];
  const second = arity_current === 0
    ? first
    : handles[parseInt(picker_operand_second.value, 10)];
  if (first === undefined || second === undefined) { nimClearPreview(); return; }
  if (!Number.isInteger(first) || !Number.isInteger(second)) { nimClearPreview(); return; }
  nimGhostOperation(parseInt(picker_operation.value, 10), first, second);
}

// How long one slice of row building may take before it yields frame. Under third of.
//   60 fps frame: long enough that few dozen rows land per slice, short enough that
//   frame it is spending is still frame that draws.
const MILLISECONDS_ROWS_SLICE = 5;
// Wider slice while row is waited for: reader pressed `edit` and is looking at nothing.
//   until that row stands, so frames give way to rows -- five thousand at largest demo,
//   which at five milliseconds is over one second of list filling before row can be
//   scrolled to. See `openPanelTo`.
const MILLISECONDS_ROWS_SLICE_REVEAL = 24;
// Row `openPanelTo` is waiting to scroll to, by key, or null.
//   Consumed by `revealPendingRow` once row stands, whether that is at once or slices later.
let key_reveal_pending: string | null = null;
// What is left of reconcile that has not finished building its rows, or null. Drained by.
//   frame loop rather than by `requestAnimationFrame` of its own, for one reason:
//   `recordPhaseTime` *overwrites* phase's reading for frame rather than adding to it,
//   so work done in callback beside loop is either unmeasured or clobbers what
//   loop measured. Cost inside frame belongs to phase of that frame -- same rule
//   `ui refresh` row was fixed under once already.
interface RowsPending {
  keys: string[];
  standing: Map<string, HTMLElement>;
  signatures: Map<string, string>;
  at: number;
}
let rows_pending: RowsPending | null = null;

function sliceObjectRows() {
  // One slice of pending reconcile, bounded by time rather than by row count: row.
  //   that is already standing and unchanged costs almost nothing, and one that has to be
  //   built costs far more, so fixed count would be different budget on every pass.
  if (rows_pending === null) return;
  const { keys, standing } = rows_pending;
  const budget = key_reveal_pending === null
    ? MILLISECONDS_ROWS_SLICE : MILLISECONDS_ROWS_SLICE_REVEAL;
  const until = performance.now() + budget;
  while (rows_pending.at < keys.length) {
    const at = rows_pending.at;
    const key = keys[at] ?? '';
    const signature = signatureOfObjectRow(key);
    let node = standing.get(key);
    const is_building = node === undefined || signatures_row.get(key) !== signature;
    if (is_building) {
      if (node !== undefined) node.remove();
      node = buildRowFor(key);
      node.dataset.key = key;
    }
    // **Signature committed per row, not at end of pass.** Refresh arriving mid-build.
    //   restarts pass from top, and with signatures held back until pass finished every
    //   row already built read as stale and was built again -- list that never finished
    //   while selection kept refreshing it, and edit form that never scrolled into view.
    signatures_row.set(key, signature);
    // Already in right place is common case; otherwise this moves it there.
    if (node !== undefined && list_objects.children[at] !== node) {
      list_objects.insertBefore(node, list_objects.children[at] ?? null);
    }
    rows_pending.at = at + 1;
    // Checked only where row was actually built, so pass that changes nothing runs to.
    //   end without ever reading clock -- tap on `hide` stays immediate.
    if (is_building && performance.now() >= until) {
      revealPendingRow();
      return;
    }
  }
  // Whatever is left past wanted rows is gone from scene, signatures with it.
  while (list_objects.children.length > keys.length) {
    list_objects.lastElementChild?.remove();
  }
  const wanted = new Set(keys);
  for (const key of Array.from(signatures_row.keys())) {
    if (!wanted.has(key)) signatures_row.delete(key);
  }
  rows_pending = null;
  revealPendingRow();
}

function revealPendingRow() {
  // Scroll to row `openPanelTo` asked for, once it stands; see `key_reveal_pending`.
  //   Row far down list stands only after every row above it, so this is asked after
  //   each slice as well as at once.
  if (key_reveal_pending === null) return;
  const row = list_objects.querySelector('.object-row[data-key="' + key_reveal_pending + '"]');
  if (row === null) return;
  key_reveal_pending = null;
  scrollRowIntoView(row as HTMLElement);
}

function isDrawerObjectsOpen() {
  // Collapsed section shows no rows, so there are none to keep current.
  //   Drawer is asked as well as section:
  //   section marked open inside closed drawer is still not on screen, and load happens either way.
  const section = document.querySelector('.section[data-section="objects"]');
  return section !== null && section.classList.contains('open') &&
    drawer.classList.contains('open');
}

function isDrawerApplyOpen() {
  // Collapsed section previews nothing:
  //   ghost belongs to control on screen, and one left standing after its section closed names
  //   nothing reader can see.
  const section = document.querySelector('.section[data-section="apply"]');
  return section !== null && section.classList.contains('open');
}

picker_operation.addEventListener('change', () => {
  updateOperandEnablement();
  ghostDrawerOperation();
});
for (const operand of [picker_operand_first, picker_operand_second]) {
  operand.addEventListener('change', ghostDrawerOperation);
}
function updateOperandEnablement() {
  const arity = nimOperationArity(parseInt(picker_operation.value, 10) || 0);
  field_operand_second.style.display = arity === 0 ? 'none' : '';
}

populateOperations();

// Coefficient grid, shared by add-multivector section and each row's own edit box:
//   stacked one row per grade (0 to n), rather than wrapping basis order at fixed
//   column count regardless of grade boundaries -- grade comes from `nimBasisGrade`
//   (backed by `pga/algebra.grade`, library's own basis-to-grade lookup), needing
//   no hardcoded basis list or JS-side reimplementation to stay correct if this build's
//   own dimension ever changes.
function buildGradedCoefficientGrid(
  container: HTMLElement, valueAt: (basis: number) => string,
): HTMLInputElement[] {
  const count_basis = nimBasisCount();
  const inputs = new Array(count_basis);
  const by_grade: number[][] = [];
  for (let b = 0; b < count_basis; b++) {
    const grade = nimBasisGrade(b);
    (by_grade[grade] || (by_grade[grade] = [])).push(b);
  }
  for (const group of by_grade) {
    if (!group) continue;
    const row = document.createElement('div');
    row.className = 'coefficient-grade-row';
    for (const b of group) {
      const f = document.createElement('div');
      f.className = 'field';
      const label_text = document.createElement('label');
      label_text.textContent = nimBasisName(b);
      const input = document.createElement('input');
      input.type = 'number';
      input.step = '0.1';
      input.value = valueAt(b);
      f.appendChild(label_text);
      f.appendChild(input);
      row.appendChild(f);
      inputs[b] = input;
    }
    container.appendChild(row);
  }
  return inputs;
}

elementById('button-apply').addEventListener('click', () => {
  if (nimSceneCount() === 0) { toast('Scene is empty; add a point first.'); return; }
  const handles = nimSceneHandles();
  const last = handles.length - 1;
  const first = handles[Math.min(parseInt(picker_operand_first.value, 10) || 0, last)];
  const second = handles[Math.min(parseInt(picker_operand_second.value, 10) || 0, last)];
  if (nimSceneCount() >= nimSceneCapacity()) { toast('Scene is full.'); return; }
  if (first === undefined || second === undefined) { toast('Pick two objects.'); return; }
  const result = nimApplyOperation(
    parseInt(picker_operation.value, 10), first, second, now());
  toast(result.message);
  adoptConstructionSelection();
});

let key_selection_synced_last = ''; // Mirrors panel.nim's index_operand_synced_highlight,
  // generalized to pair:
  //   re-defaults operand m/n to current selection only moment selection itself changes (not on
  //   every refreshOperandOptions call, which happens far more often than selection changes), so
  //   manual pick of different operand sticks until selection moves again.
let key_operand_options_last = ''; // Handle list + labels last used to rebuild operand m/n's
  // own <option> elements -- rebuilding <select>'s options while its native picker
  // is open (mobile especially) makes browser re-show/reset that picker, so
  // full rebuild below only actually runs when scene composition or label changed,
  // never on every periodic tick.

function refreshOperandOptions() {
  const handles = nimSceneHandles();
  // **Keyed on scene's own revision, not on roll-call of every label.** Key used.
  //   to be `handle:label` joined over whole scene, which is one FFI call per object and
  //   string length of list -- 5,038 calls to decide whether two pickers needed
  //   rebuilding, on path every scene change runs through. `scene.revision` moves on
  //   exactly edits that can change label, and count catches nothing else moving.
  const key = nimSceneRevision() + ':' + handles.length;
  // Collapsed section has no pickers to fill: rebuilding them is one `<option>` per.
  //   object per picker, ten thousand elements at largest size, for control that is
  //   not on screen. Section header and drawer button both refresh on opening.
  if (key !== key_operand_options_last && isDrawerApplyOpen()) {
    key_operand_options_last = key;
    for (const selection_target of [picker_operand_first, picker_operand_second]) {
      const prev = selection_target.value;
      selection_target.innerHTML = '';
      handles.forEach((handle, i) => {
        const option = document.createElement('option');
        option.value = String(i);
        option.textContent = nimObjectLabel(handle);
        selection_target.appendChild(option);
      });
      if (prev !== '' && parseInt(prev, 10) < handles.length) selection_target.value = prev;
    }
  }
  syncOperandsToSelection(handles);
}

function syncOperandsToSelection(handles?: number[]) {
  // Everything selection already says is filled in here rather than asked for second time:
  //   how many objects are picked names arity (`nimSelectionArity`, same rule floating menu reads),
  //   and order they were picked names m and n.
  //   Only right when selection itself changes -- cheap enough (no DOM rebuild) to call on every
  //   frame-loop tick, unlike option-list rebuild above, and leaving later manual pick of either
  //   alone until selection next moves.
  //   Mirrors panel.layoutApply exactly.
  const key = handles_selection.join(',');
  if (key === key_selection_synced_last) return;
  key_selection_synced_last = key;
  if (handles_selection.length === 0) return; // Nothing picked names nothing; leave it be.
  const handles_scene = handles || nimSceneHandles();

  const arity = nimSelectionArity();
  if (arity !== arity_current) {
    // Rebuild filtered operation list, indexed per arity.
    //   Option carried across from other list names unrelated operation;
    //   populateOperations rebuilds it and falls back to new list's first entry, exactly
    //   as arity buttons do.
    arity_current = arity;
    picker_arity.querySelectorAll('button[data-arity]').forEach((each) => {
      each.classList.toggle(
        'on', parseInt((each as HTMLElement).dataset.arity ?? '0', 10) === arity);
    });
    populateOperations();
  }

  const position_first = handles_scene.indexOf(handles_selection[0] ?? -1);
  if (position_first >= 0) picker_operand_first.value = String(position_first);
  if (handles_selection.length >= 2) {
    // Three or more picked still names binary operation, on first two:
    //   this picker can say which two, unlike floating menu, which hides `apply` rather than guess.
    const position_second = handles_scene.indexOf(handles_selection[1] ?? -1);
    if (position_second >= 0) picker_operand_second.value = String(position_second);
  }
}
