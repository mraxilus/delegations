// Scene mirror, selection snapshot and toast DOM reflects; not Nim because these reach browser APIs
//   Nim's JS backend does not express.
//   Presentation alone: every join, meet, pick, drag and camera move is computed by
//   bridge, compiled from same modules desktop draws through (Article II.9).
//   Concatenated into page in order `tools/build.nim` names; see its `SCRIPTS`.

/* ---------------------------------------------------------------------- */
/* Scene setup. Every construction, visibility and camera state lives in  */
/* compiled Nim module; this file only tracks what DOM needs to           */
/* reflect and drive it.                                                  */
/* ---------------------------------------------------------------------- */

nimInit(performance.now() / 1000);
let is_axes_shown = true, is_grid_shown = true;

function now() { return performance.now() / 1000; }

/* ---------------------------------------------------------------------- */
/* Selection: ordered multi-select, shared by touch long-press/tap and     */
/* mouse click/shift-click -- see pointer-input section below for          */
/* full gesture design. Nim's own `selection.nim` holds it, through        */
/* `nimSelect*` exports: pick order is what names operation's operands     */
/* m and n, and that rule belongs beside every other rule about            */
/* selection rather than in second implementation over here. Every         */
/* construction path already writes selection itself, so there is no       */
/* two-way sync to keep -- only read.                                      */
/*                                                                          */
/* `handles_selection` below is render snapshot of that answer, not copy      */
/* with rules of its own: frame loop's overlay reads it dozens of           */
/* times second and must not cross JS/Nim boundary to do it.                */
/* ---------------------------------------------------------------------- */

// Ordered: first-picked first (-> operand m), second (-> n).
let handles_selection: number[] = [];

function refreshSelectionSnapshot() {
  handles_selection = nimSelectionHandles();
}

function onSelectionChanged(position_local: PointLocal | null) {
  refreshSelectionSnapshot();
  refreshSelectionMenu(position_local);
  refreshObjectsUI(); // Also re-syncs apply controls and row checkboxes.
}

// Note pick made by pointer, so camera keeps that object under it as view comes in.
//   Cursor is already Nim's (`nimUpdateCursor` on every move and tap), so handle is all
//   bridge needs. Every pointer pick, whichever button: menu is button's business.
function pickByPointer(handle: number) {
  nimPickByPointer(handle);
}

function selectOnly(handle: number, position_local: PointLocal | null) {
  nimSelectOnly(handle);
  onSelectionChanged(position_local);
}

function toggleSelection(handle: number, position_local: PointLocal | null) {
  nimSelectToggle(handle);
  onSelectionChanged(position_local);
}

function clearSelection() {
  nimSelectClear();
  onSelectionChanged(null);
}

// What click on object does, given which button made it and whether shift was held.
//   **Two independent questions**, and keeping them independent is whole design:
//   button says whether selection menu comes up (`nimRevealsMenuOnButton`), shift says
//   whether click adds to selection or replaces it. Left picks silently, right picks
//   and shows menu, and either of them with shift adds or drops instead.
//   **Null position does not mean "no menu"** -- `refreshSelectionMenu(null)` still shows
//   menu, positioned from selection rather than from cursor, which is what
//   keyboard path wants. So non-revealing click hides it afterwards rather than hoping
//   argument covered it. That misreading shipped once here and left button kept popping
//   menu it was supposed to have given up.
//   Both branches live here rather than at two call sites, which used to hold copy
//   each of shift test.
function pickOnClick(handle: number, button: number, is_shifted: boolean) {
  const reveals = nimRevealsMenuOnButton(button);
  // Selection already standing with its menu dismissed is reader who wants that menu.
  //   back, not one who wants to throw selection away -- so reveal it and pick nothing.
  //   Rule is Nim's, asked rather than restated, since desktop asks same one.
  if (reveals && !is_shifted &&
      nimRevealsWithoutPicking(nimSelectionCount() > 0, isSelectionMenuShown())) {
    refreshSelectionMenu(cursor_last);
    return;
  }
  pickByPointer(handle);
  if (is_shifted) toggleSelection(handle, reveals ? cursor_last : null);
  else selectOnly(handle, reveals ? cursor_last : null);
  if (!reveals) hideSelectionMenu();
}

function adoptConstructionSelection() {
  // Pick up outcome every construction path already decided.
  //   Each picked its own new object (see nimAddItem/nimApplyOperation/nimEndDrag's own
  //   doc comments), or cleared selection (nimLoadDemo/nimUndo/nimRedo on success).
  refreshSelectionSnapshot();
  hideSelectionMenu(); // Construction action never itself opens selection menu --
    // matches today's behaviour (add/apply/drag never popped tap-menu either).
  refreshObjectsUI();
}

/* ---------------------------------------------------------------------- */
/* Toast: outcome of last action, matching desktop panel's own            */
/* one-line status message, shown transiently rather than pinned.         */
/* ---------------------------------------------------------------------- */

const element_toast = elementById('toast');
let timer_toast: ReturnType<typeof setTimeout> | undefined;
function toast(message: string) {
  // Say nothing for empty message, which is one caller decided not to say.
  //   Drag released over empty space, say; showing empty bar for it is worse than saying
  //   nothing.
  //   Desktop guards its own status line this way; this is that guard, on this side.
  if (!message) return;
  element_toast.textContent = message;
  element_toast.classList.remove('actionable');
  element_toast.classList.add('show');
  clearTimeout(timer_toast);
  timer_toast = setTimeout(() => element_toast.classList.remove('show'), 3200);
}

function toastWithLink(
  message: string, url: string, filename: string, label: string, url_image?: string,
) {
  // Toast reader can act on, held until dismissed. For one case page cannot.
  //   resolve on its own: file is ready and every automatic route to it may have been
  //   refused, silently, by frame this page does not control. Tap *reader* makes on
  //   real anchor is most permitted route there is, so offer that rather than assert
  //   download happened.
  element_toast.textContent = '';
  const line = document.createElement('div');
  line.textContent = message;
  const link = document.createElement('a');
  link.className = 'toast-action';
  link.href = url;
  link.download = filename;
  link.textContent = label;
  link.rel = 'noopener';
  // `url_image` set means file is one reader can save straight off screen, and.
  //   showing it is worth space: drawing blob into `<img>` is not navigation, so
  //   it is only route measured to survive frame sandboxed without `allow-downloads`
  //   -- where press on anchor above is refused in silence, as is every automatic
  //   route. Offered beside link, never instead of it, since where downloads *are*
  //   permitted link is one tap and this is press-and-hold.
  const preview = document.createElement('img');
  const hint = document.createElement('div');
  if (url_image !== undefined) {
    preview.className = 'toast-preview';
    preview.src = url_image;
    preview.alt = filename;
    hint.className = 'toast-hint';
    hint.textContent = 'or press and hold the image to save it';
  }
  // Something to do about it, in words, above evidence. Measured on Android phone in.
  //   Claude app: that frame withholds `allow-downloads`, `allow-popups` and
  //   `web-share` policy all three, so no route from inside it can produce file and no
  //   amount of further work here will change that. Saying so is more use than link that
  //   cannot fire, and same page opened as its own tab downloads normally.
  const advice = document.createElement('div');
  advice.className = 'toast-hint';
  advice.textContent = 'If nothing arrives, this frame is blocking it — '
    + 'open this page in its own browser tab and save from there.';
  // What was tried and what came back, beside thing it was tried on. Every round of.
  //   this fault so far ended with reader who could only report "nothing happened"; this
  //   is what turns next report into diagnosis.
  const detail = document.createElement('div');
  detail.className = 'toast-detail';
  detail.textContent = report_delivery.join(' · ');
  const dismiss = document.createElement('button');
  dismiss.className = 'toast-dismiss';
  dismiss.type = 'button';
  dismiss.textContent = 'dismiss';
  dismiss.addEventListener('click', () => {
    element_toast.classList.remove('show', 'actionable');
  });
  element_toast.append(line, link);
  if (url_image !== undefined) element_toast.append(preview, hint);
  element_toast.append(advice, detail, dismiss);
  element_toast.classList.add('show', 'actionable');
  clearTimeout(timer_toast); // No expiry: see above.
}
