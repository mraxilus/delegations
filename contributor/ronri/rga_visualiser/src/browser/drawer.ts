// Drawer, its collapsible sections, help and undo controls; not Nim because these reach browser
//   APIs Nim's JS backend does not express.
//   Presentation alone: every join, meet, pick, drag and camera move is computed by
//   bridge, compiled from same modules desktop draws through (Article II.9).
//   Concatenated into page in order `tools/build.nim` names; see its `SCRIPTS`.

/* ---------------------------------------------------------------------- */
/* Drawer + collapsible sections                                          */
/* ---------------------------------------------------------------------- */

// Every transition in stylesheet runs to these, so browser eases over same.
//   duration and curve appear animation does -- `nimAnimationMilliseconds` is
//   `mesh.ANIMATION_MILLISECONDS`, and bezier is easeOutCubic written for CSS.
document.documentElement.style.setProperty('--anim', nimAnimationMilliseconds() + 'ms');
document.documentElement.style.setProperty('--ease', 'cubic-bezier(0.215, 0.61, 0.355, 1)');

const drawer = elementById('drawer');
const row_chip_found = document.querySelector('.chip-row');
if (row_chip_found === null) throw new Error('Missing chip row.');
const row_chip: Element = row_chip_found;
const button_drawer = elementById('button-drawer');
button_drawer.addEventListener('click', () => {
  const open = drawer.classList.toggle('open');
  button_drawer.classList.toggle('on', open);
  // Everything inside it that skips its work while out of sight catches up now:
  //   rows, operand pickers.
  //   Both are no-ops when their own section is still collapsed.
  refreshObjectsUI();
});

// Top menu: one popover holding every top-bar action (undo/redo, axes/grid, save/load.
//   scene, save PNG/load demo) that used to be spread across four separate chip-row
//   pill-groups -- each button inside keeps its own pre-existing #id-based wiring
//   unchanged below; this only owns popover's own open/close.
const menu_top = elementById('top-menu');
const button_menu = elementById('button-menu');
button_menu.addEventListener('click', () => {
  const open = menu_top.classList.toggle('show');
  button_menu.classList.toggle('on', open);
});

document.querySelectorAll('.section-header').forEach((header) => {
  header.addEventListener('click', () => {
    const section = header.parentElement;
    if (section === null) throw new Error('Section header outside section.');
    section.classList.toggle('open');
    // Start or end apply section's own preview with section itself.
    //   Preview lives exactly as long as section is on screen, so opening one starts it
    //   and collapsing one ends it.
    //   Asked of every section rather than only that one: check reads section's own
    //   class either way, and handler that knew which section it was would be second
    //   place to keep in step.
    previewDrawerOperation();
    // Let objects list catch up on whatever it skipped while it was closed.
    //   See `refreshObjectsUI`; same shape, same reason, and asked of every section for
    //   same reason as above, since call is no-op unless it is objects section that
    //   opened.
    refreshObjectsUI();
  });
});
elementById('toggle-axes').addEventListener('click', (e) => {
  is_axes_shown = !is_axes_shown;
  (e.currentTarget as HTMLElement).classList.toggle('on', is_axes_shown);
});
elementById('toggle-grid').addEventListener('click', (e) => {
  is_grid_shown = !is_grid_shown;
  (e.currentTarget as HTMLElement).classList.toggle('on', is_grid_shown);
});
/* ---------------------------------------------------------------------- */
/* Help: ? button says it whenever asked.                                 */
/* ---------------------------------------------------------------------- */

// Pill naming few gestures used to greet every load and leave on reader's first.
//   action. Panel below outgrew it -- it lists every path and every operation, on
//   demand and for as long as reader wants -- and page that explains itself when
//   asked does not need to explain itself unasked. Five gestures that dismissed
//   pill now dismiss nothing, which is why no call replaced them.

// Built from `help.lut_help_entries` across bridge, so this panel and desktop's.
//   own say same thing by construction. Four strings per entry; see nimHelpEntries.
//   One tab per path, because reader opens this in middle of one way of working and
//   only that way's rows are any use to them right then. Tab row belongs to is
//   core's answer -- first of its four strings -- so this builds strip out of
//   paths it actually sees rather than naming them here and drifting from table.
const button_help = elementById('button-help');
const panel_help = elementById('help-panel');
const strip_help = elementById('help-tabs');
const rows_help = elementById('help-rows');
const note_help = elementById('help-description');
const descriptions_help = new Map();
function buildHelp() {
  // What each tab is about, in one sentence, keyed by very title rows are grouped.
  //   by -- so two exports join on string rather than on matching order.
  const described = nimHelpDescriptions();
  for (let i = 0; i + 1 < described.length; i += 2) {
    descriptions_help.set(described[i] ?? '', described[i + 1] ?? '');
  }
  const flat = nimHelpEntries();
  const paths: string[] = [];
  for (let i = 0; i + 3 < flat.length; i += 4) {
    const path = flat[i] ?? '';
    const action = flat[i + 1] ?? '';
    const outcome = flat[i + 2] ?? '';
    const touch = flat[i + 3] ?? '';
    if (!paths.includes(path)) paths.push(path);
    const row = document.createElement('div');
    row.className = 'help-row';
    row.dataset.path = path;
    const cell_action = document.createElement('div');
    cell_action.className = 'help-action' + (touch ? ' help-touch' : '');
    cell_action.textContent = action;
    const cell_outcome = document.createElement('div');
    cell_outcome.className = 'help-outcome';
    cell_outcome.textContent = outcome;
    row.appendChild(cell_action);
    row.appendChild(cell_outcome);
    rows_help.appendChild(row);
  }
  for (const path of paths) {
    const tab = document.createElement('button');
    tab.type = 'button';
    tab.className = 'help-tab';
    tab.dataset.path = path;
    tab.textContent = path;
    tab.setAttribute('role', 'tab');
    tab.addEventListener('click', () => showHelpPath(path));
    strip_help.appendChild(tab);
  }
  showHelpPath(paths[0] ?? '');
}

function showHelpPath(path: string) {
  // Every row stays in DOM and is hidden by attribute rather than rebuilt per tab:
  //   table never changes at runtime, so rebuilding would be work to no end, and
  //   test can count what each tab holds without switching to it.
  for (const tab of Array.from(strip_help.children) as HTMLElement[]) {
    const is_open = tab.dataset['path'] === path;
    tab.classList.toggle('on', is_open);
    tab.setAttribute('aria-selected', is_open ? 'true' : 'false');
  }
  for (const row of Array.from(rows_help.children) as HTMLElement[]) {
    row.hidden = row.dataset['path'] !== path;
  }
  // Swapped with tab rather than one note per tab hidden alongside its rows: there is.
  //   only ever one showing, so one element that changes text cannot go stale.
  note_help.textContent = descriptions_help.get(path) || '';
  rows_help.scrollTop = 0; // Tab always opens at its own first row.
}
buildHelp();

elementById('help-close').addEventListener('click', () => showHelp(false));

function showHelp(is_shown: boolean) {
  panel_help.classList.toggle('show', is_shown);
  button_help.setAttribute('aria-expanded', is_shown ? 'true' : 'false');
}
button_help.addEventListener('click', (e) => {
  e.stopPropagation();
  showHelp(!panel_help.classList.contains('show'));
});

/* ---------------------------------------------------------------------- */
/* Undo/redo: scene-content edits only, mirrors panel.layoutPanel's    */
/* own undo/redo buttons exactly -- see `history.nim` for what is and is   */
/* not on this timeline. Step carries view its edit was made from,         */
/* so camera moves under these too; orbit alone is not step.               */
/* ---------------------------------------------------------------------- */

const button_add = elementById<HTMLButtonElement>('button-add');
const button_undo = elementById<HTMLButtonElement>('button-undo');
const button_redo = elementById<HTMLButtonElement>('button-redo');

function openApplyPickerOnOperands(position_local: PointLocal | null) {
  // Where drag menu's `more…` lands: `nimEndDrag` has already selected both operands.
  //   in order they were dragged, so this only has to open picker that reads that
  //   selection. Refusing to open it would make `more…` dead end, which is exactly what
  //   it exists to stop gesture being.
  //   **Hover menu's picker, not drawer's apply section.** `more…` is fifth
  //   choice on wheel that opened under cursor, and sending it to panel down
  //   side of screen threw hand across viewport and buried two objects it
  //   had just named under list of every other control. Picker lands where wheel
  //   was, already open, already holding last operation of that arity.
  refreshSelectionSnapshot();
  refreshObjectsUI();
  refreshSelectionMenu(position_local);
  if (menu_selection_apply.style.display !== 'none') openSelectionMenuOp();
}

// **Settled scroll, not single jump.** Row outside viewport is placeholder.
//   rather than laid-out row -- see `.object-row`'s `content-visibility` in `shell.html` --
//   so offset of row thousand places down list is estimate until rows
//   above it have actually been measured. One `scrollIntoView` lands on estimate:
//   measured on handle 900 of demo, row arrived 428px lower than it should have,
//   leaving edit form it was opening off bottom of screen. Each pass lays out
//   rows it scrolls past, so estimate is exact where it matters by next one.
//   Stops as soon as row holds still, which on list short enough to be laid out
//   whole is immediately.
const PASSES_SCROLL_SETTLE = 4;
function scrollRowIntoView(row: HTMLElement, passes = PASSES_SCROLL_SETTLE) {
  row.scrollIntoView({ block: 'nearest' }); // Long list can open past it.
  if (passes <= 1) return;
  const settled = row.getBoundingClientRect().top;
  requestAnimationFrame(() => {
    if (Math.abs(row.getBoundingClientRect().top - settled) < 1) return;
    scrollRowIntoView(row, passes - 1);
  });
}

function openPanelTo(handle: number | null) {
  // Open edit session on `handle` (or composing one where null) and bring drawer.
  //   and Objects section far enough open to see it -- shared by top bar's `add`
  //   and selection menu's `edit`, which differ only in what they open onto.
  beginEditSession(handle);
  const section_objects = document.querySelector('.section[data-section="objects"]');
  if (section_objects === null) throw new Error('Missing objects section.');
  section_objects.classList.add('open');
  drawer.classList.add('open');
  button_drawer.classList.add('on');
  refreshObjectsUI();
  // Scrolled once its row stands, which is now or slices from now; see `revealPendingRow`.
  //   Asked at once as well, since list already built ends refresh above without slicing.
  //   Querying row here and giving up where it was not yet built left panel open on
  //   top of list with wanted row thousands of pixels down it.
  key_reveal_pending = handle === null ? KEY_ROW_PENDING : String(handle);
  revealPendingRow();
}

button_add.addEventListener('click', () => {
  // Compose new object as row in Objects list rather than in section of its.
  //   own: adding and editing stage same four things through same interface, so
  //   there is one grid and one preview instead of two of each.
  openPanelTo(null);
});

// One function for buttons and for keys that do same thing. Keys used to.
//   go through `button.click()`, which quietly made them depend on that button's own
//   `disabled` attribute -- refreshed on low-cadence UI tick, so key pressed in
//   frames after edit did nothing at all while timeline plainly had something on
//   it. Measured, not suspected. Mirrors `panel.stepHistory` on desktop side.
//   Restored snapshot's handle numbers need not match, so open session has nothing
//   trustworthy left to commit against and is dropped.
function stepHistory(is_undo: boolean) {
  if (is_undo ? nimUndo() : nimRedo()) {
    endEditSession();
    adoptConstructionSelection();
    refreshObjectsUI();
  } else {
    toast(is_undo ? 'Nothing to undo.' : 'Nothing to redo.');
  }
  refreshUndoRedoButtons();
}

button_undo.addEventListener('click', () => stepHistory(true));
button_redo.addEventListener('click', () => stepHistory(false));
