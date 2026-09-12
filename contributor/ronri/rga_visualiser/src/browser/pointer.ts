// Pointer, touch and wheel input; not Nim because these reach browser APIs Nim's JS backend does
//   not express.
//   Presentation alone: every join, meet, pick, drag and camera move is computed by
//   bridge, compiled from same modules desktop draws through (Article II.9).
//   Concatenated into page in order `tools/build.nim` names; see its `SCRIPTS`.

/* ---------------------------------------------------------------------- */
/* Pointer input.                                                          */
/*   One invariant across every pointer: PRESS TARGET CHOOSES SCHEME.      */
/*   Press that lands on object constructs; one that lands on              */
/*   empty space moves camera. Mirrors `visualiser.handleEvent`.           */
/*   Mouse: left-drag takes whatever two objects make and is never         */
/*   interrupted, right-drag opens choice menu on arrival. From empty      */
/*   space, left orbits, right pans, wheel dollies.                        */
/*   Touch: same, with dwell as only way to open menu --                   */
/*   there is no second button to force it with. Finger that presses       */
/*   object and stays still selects it instead (long-press), so            */
/*   first movement past `TAP_MAX_MOVE` is what decides between two.       */
/*   Two fingers still pinch and pan, and cancel any drag in progress.     */
/* ---------------------------------------------------------------------- */

canvas.addEventListener('contextmenu', (e) => e.preventDefault());

// Live pointers by their own id, so pinch reads two at once.
const pointers = new Map<number, PointLocal>();
let separation_pinch_start: number | null = null;
// Whether two fingers have parted or closed further than tap slop since both came down.
//   Until they have, gesture is pan and only pan: two fingers carried together never
//   hold their separation to pixel, and every notch of that jitter went through zoom,
//   which re-pivots turntable onto whatever middle of frame crossed. Slop itself is not
//   zoomed once crossed; zoom starts from separation where it was crossed, without jump.
let is_pinch_zooming = false;
// Whether two fingers have moved since frame loop last read them.
//   Each finger's move arrives as its own `pointermove`, so between two of them
//   separation and midpoint are one finger new and other old: read there, every step of
//   pan carried together was zoom in by one finger's step and out again by other's,
//   and each of those went through re-pivot. Read once per frame instead, in
//   `settleTwoFingers`, after both have reported.
let is_two_fingers_pending = false;
let pan_last: PointLocal | null = null;
// Button held for camera orbit/pan fallback, while no operation drag is active.
// Mouse button dragging object, or camera scheme press fell back to, or `null`.
let button_mouse_drag: number | 'orbit' | 'pan' | null = null;
let cursor_last: PointLocal | null = null;
// **What pointer asked for, for frame loop to answer once.** Pick and dolly.
//   both walk whole scene, and pointer or trackpad reports several times between two
//   frames; see frame loop, which is where each of these is spent.
let is_hover_stale = false;
let deltas_wheel = 0; // Summed wheel travel awaiting one dolly; `wheel` says why.

// Touch long-press-to-select / tap-to-toggle / drag-to-construct state.
let touch_down_at: number | null = null;
let position_touch_down: PointLocal | null = null;
let has_touch_moved = false;
let has_long_press_fired = false;
// Object finger came down on, and whether that press has become construction drag.
//   `handle_touch_down` is read once at pointerdown, while hover still holds it -- picking
//   again later would report whatever finger has since moved over.
let handle_touch_down = -1, is_touch_dragging = false;
// Whether press landed on something drag may be built from, decided at press and.
//   held for gesture. **Press that can construct never moves camera, not even
//   over pixels before slop is crossed** -- that is press-target rule mouse
//   already follows by choosing its scheme at button. Touch reached same place by
//   different road and got it wrong: finger that eased into its drag orbited for frame
//   or two before slop, which latched `nimSetCameraDragging`, and hover is suppressed
//   while camera moves -- so construction drag that armed moment later ran blind
//   for rest of gesture, previewing nothing and building nothing. Flick that cleared
//   slop in one event armed before any of that and worked, which is what made fault
//   read as intermittent.
let is_touch_press_constructing = false;
// How far press may move and still be press comes from `interaction.PIXELS_TAP_SLOP`:
//   it decides which scheme gesture enters, which is rule about gesture, not
//   presentation number. Tap *timeout* stays here -- that one really is local.
const TAP_MAX_MS = 350, TAP_MAX_MOVE = nimTapSlop();
// How finger's construction drag comes to offer wheel. Mouse reads this off.
//   button it pressed; touch has no second button, so it names one arming that waits.
const ARMING_DRAG_TOUCH = nimDragArmingOnDwell();

// Tell mouse click from drag: plain click selects or shift-selects, drag builds.
//   Whether press stayed click is `interaction.isClick`'s to say.
//   All that is left here is which button went down, which is this layer's own
//   numbering.
let button_mouse_down: number | null = null;

function pointerDist(points_flat: PointLocal[]) {
  const [a, b] = points_flat;
  if (a === undefined || b === undefined) return 0;
  return Math.hypot(a.x - b.x, a.y - b.y);
}
function pointerMid(points_flat: PointLocal[]): PointLocal {
  const [a, b] = points_flat;
  if (a === undefined || b === undefined) return { x: 0, y: 0 };
  return { x: (a.x + b.x) / 2, y: (a.y + b.y) / 2 };
}

canvas.addEventListener('pointerdown', (e) => {
  canvas.setPointerCapture(e.pointerId);
  // Every gesture starts by saying it is not camera move; branches below say so where.
  //   they are one. Cleared here rather than only at release because release can go
  //   missing -- pointer cancelled, touch sequence browser tears down -- and flag
  //   left true stops hover ring working for rest of session, with nothing on
  //   screen to say why. Same failure held keys have, handled same way.
  if (pointers.size === 0) nimSetCameraDragging(false);
  const rect = canvas.getBoundingClientRect();
  const local = { x: e.clientX - rect.left, y: e.clientY - rect.top };
  pointers.set(e.pointerId, { x: e.clientX, y: e.clientY });

  if (e.pointerType === 'mouse') {
    nimUpdateCursor(local.x, local.y);
    nimUpdateHover(canvas.clientWidth, canvas.clientHeight);
    // Note press before anything is decided about it: whether it was click is only.
    //   knowable at release, and both branches below can end in one.
    nimBeginPress(now());
    button_mouse_down = e.button;
    // Read off button whether drag decides for you or asks.
    //   What it builds is read off operands at release; mirrors `visualiser.armingFor`.
    const arming_drag = nimDragKindForButton(e.button);
    if (arming_drag >= 0 && nimBeginDrag(arming_drag, now())) {
      button_mouse_drag = e.button;
    } else if (e.button === 0) {
      button_mouse_drag = 'orbit';
    } else if (e.button === 2) {
      button_mouse_drag = 'pan';
    }
    return;
  }

  // Touch/pen:
  //   track for existing multi-touch orbit/pinch/pan gesture, for single-finger tap that toggles
  //   selection membership once selection exists, for long-press that starts one, and for drag off
  //   object that constructs.
  if (pointers.size === 1) {
    touch_down_at = performance.now();
    position_touch_down = local;
    has_touch_moved = false;
    has_long_press_fired = false;
    // Pick object under finger now and hand press to Nim, which owns how long.
    //   hold takes and whether one is due. Frame loop asks it both, which is also what
    //   fills object's own marker -- timer firing on its own could not draw anything.
    //   Handle is kept as well: it is what decides, on first movement, whether this
    //   press was construction drag or camera orbit.
    nimUpdateCursor(local.x, local.y);
    nimUpdateHover(canvas.clientWidth, canvas.clientHeight);
    // Noted like any other press, so that finger's own construction drag is measured.
    //   against where finger landed rather than against last mouse press.
    nimBeginPress(now());
    handle_touch_down = nimHoverHandle();
    // Whether this press *can* become construction drag, decided here at press and.
    //   not re-asked -- same question `interaction.beginDrag` answers when slop is
    //   finally crossed, asked early because moves before that have to know which
    //   scheme they belong to. Sky is hovered wherever nothing else is and is refused
    //   there, so press on it still falls through to camera; so is crowd, several
    //   objects in reach of one finger, which moves view instead; see
    //   `interaction.canConstructByTouch`.
    is_touch_press_constructing = nimCanTouchConstruct();
    if (handle_touch_down >= 0) nimBeginHold(handle_touch_down, now());
  } else {
    touch_down_at = null; // Second finger landed; this is pinch/pan gesture, not tap.
    nimCancelHold();
    // ...and not construction either. Drag reader has visibly abandoned must not.
    //   commit on whichever finger happens to lift first.
    if (is_touch_dragging) { nimCancelDrag(); is_touch_dragging = false; }
    handle_touch_down = -1;
    is_touch_press_constructing = false;
  }
  if (pointers.size === 2) {
    const points_flat = [...pointers.values()];
    separation_pinch_start = pointerDist(points_flat);
    is_pinch_zooming = false;
    pan_last = pointerMid(points_flat);
  }
});

canvas.addEventListener('pointermove', (e) => {
  const rect = canvas.getBoundingClientRect();
  cursor_last = { x: e.clientX - rect.left, y: e.clientY - rect.top };

  if (e.pointerType === 'mouse') {
    nimUpdateCursor(cursor_last.x, cursor_last.y);
    if (button_mouse_drag !== null && typeof button_mouse_drag === 'number') {
      // Re-check hover for drag's own destination preview -- next frame, not now; see.
      //   `is_hover_stale`.
      is_hover_stale = true;
      return;
    }
    const prev = pointers.get(e.pointerId);
    if (prev === undefined) return;
    const current = { x: e.clientX, y: e.clientY };
    pointers.set(e.pointerId, current);
    const dx = current.x - prev.x, dy = current.y - prev.y;
    // Camera gesture is not hover, said at *move* rather than at press:
    //   press that never moves is click, and click has to know what it came down on.
    if (button_mouse_drag === 'orbit' || button_mouse_drag === 'pan') nimSetCameraDragging(true);
    if (button_mouse_drag === 'orbit') {
      nimCameraOrbit(
        -dx / canvas.clientWidth * Math.PI * 1.4, dy / canvas.clientHeight * Math.PI * 1.4,
      );
    } else if (button_mouse_drag === 'pan') {
      // Where pointer was and where it is, not how far it moved:
      //   pan grabs level under it and carries that point along, which needs both ends of step.
      nimCameraPanAt(
        prev.x - rect.left, prev.y - rect.top,
        current.x - rect.left, current.y - rect.top,
        canvas.clientWidth, canvas.clientHeight,
      );
    }
    is_hover_stale = true;
    return;
  }

  const prev = pointers.get(e.pointerId);
  if (prev === undefined) return;
  const current = { x: e.clientX, y: e.clientY };
  pointers.set(e.pointerId, current);
  const reach_touch = position_touch_down &&
    Math.hypot(cursor_last.x - position_touch_down.x, cursor_last.y - position_touch_down.y);
  if ((reach_touch ?? 0) > TAP_MAX_MOVE && !has_touch_moved) {
    // One moment this press stops being press. Decided once, here, and never.
    //   revisited: press target chooses scheme, so finger that came down on
    //   object constructs and one that came down on empty space moves camera.
    //   `nimBeginDrag` reads hover reading, which still holds touch-down handle
    //   because touch pointermove has not updated cursor yet -- so it must run before
    //   two lines below start following finger.
    has_touch_moved = true;
    nimCancelHold(); // Moved, so this press will never mature into selection.
    if (handle_touch_down >= 0 && pointers.size === 1) {
      // Finger has no second button to ask wheel for, so it is one pointer that.
      //   still reaches wheel by standing still; see `interaction.MenuArming`.
      is_touch_dragging = nimBeginDrag(ARMING_DRAG_TOUCH, now());
    }
  }

  if (is_touch_dragging) {
    // Follow finger and let frame loop's own `nimUpdateDrag` do rest:
    //   preview, dwell, and menu are all already driven from there. Returning
    //   here is what keeps construction drag from also orbiting camera under it.
    nimUpdateCursor(cursor_last.x, cursor_last.y);
    is_hover_stale = true;
    return;
  }

  if (pointers.size === 1) {
    // One finger that is not constructing and not holding is orbiting, which hover.
    //   ring should sit out; two branches above return before reaching here.
    //   Press that came down on object is not orbiting even now, before its slop is
    //   crossed: it is construction press waiting to become drag, and moving
    //   camera under it would both jerk view and put out hover drag needs.
    if (is_touch_press_constructing) return;
    nimSetCameraDragging(true);
    const dx = current.x - prev.x, dy = current.y - prev.y;
    nimCameraOrbit(
      -dx / canvas.clientWidth * Math.PI * 1.4, dy / canvas.clientHeight * Math.PI * 1.4,
    );
  } else if (pointers.size === 2) {
    nimSetCameraDragging(true); // Two fingers pan and pinch; neither points at anything.
    is_two_fingers_pending = true; // Read by frame loop; see `settleTwoFingers`.
  }
});

// Move camera by two fingers' travel since frame loop last looked.
//   Run from `frame` before it draws, once per frame both fingers have reported in;
//   see `is_two_fingers_pending`.
function settleTwoFingers() {
  if (!is_two_fingers_pending) return;
  is_two_fingers_pending = false;
  if (pointers.size !== 2) return;
  const rect = canvas.getBoundingClientRect();
  const points_flat = [...pointers.values()];
  const separation = pointerDist(points_flat);
  const mid = pointerMid(points_flat);
  // Zoom at middle of frame, not aimed at pinch's own midpoint.
  //   Pan below already moves view by that midpoint's own travel, so aiming zoom
  //   there too translates view twice for one gesture, and pinch anywhere but dead
  //   centre slides scene while it scales it.
  //   Wheel has no pan beside it, which is why aiming at pointer is right there.
  //   Through anchor at middle rather than plain dolly, so pivot lands on planet
  //   pinch arrives at and orbit turns about it; plane, ground and level under middle
  //   leave pivot on its level. See `interaction.dollyAtCentre`.
  if (separation_pinch_start !== null && !is_pinch_zooming &&
      Math.abs(separation - separation_pinch_start) > TAP_MAX_MOVE) {
    is_pinch_zooming = true;
    separation_pinch_start = separation;
  }
  if (is_pinch_zooming) {
    nimCameraDollyCentred(
      (separation_pinch_start ?? separation) / Math.max(1, separation),
      canvas.clientWidth, canvas.clientHeight,
    );
    separation_pinch_start = separation;
  }

  if (pan_last) {
    // Grab and carry two fingers' own midpoint exactly as mouse drag is.
    //   Same rule for both, so fix to one is fix to both.
    nimCameraPanAt(
      pan_last.x - rect.left, pan_last.y - rect.top,
      mid.x - rect.left, mid.y - rect.top,
      canvas.clientWidth, canvas.clientHeight,
    );
  }
  pan_last = mid;
}

function endMouseDrag(e: PointerEvent) {
  if (typeof button_mouse_drag === 'number') {
    // `nimEndDrag` resolves press itself: click over object comes back as.
    //   `clicked_handle` with eagerly-begun drag already abandoned, actual drag as
    //   whatever it built. Which of two it was is `interaction.endDrag`'s answer, so
    //   this build and desktop cannot come to disagree about where line is.
    const result = nimEndDrag(now());
    if (result.clicked_handle >= 0) {
      pickOnClick(result.clicked_handle, button_mouse_drag, e.shiftKey);
    } else {
      toast(result.message);
      if (result.created_handle >= 0) adoptConstructionSelection();
      else if (result.is_more) openApplyPickerOnOperands(cursor_last);
    }
  } else if (button_mouse_down !== null && nimIsClick(now())) {
    // Plain click that began no drag to end -- so it landed on empty space, or on one.
    //   thing that *is* empty space: horizon plane, which nimBeginDrag refuses so this
    //   press could still have become orbit or pan. Clicking it selects it, which is
    //   only way pointer can, since it can never be dragged from. **Either button**,
    //   on same rule as above: right click on sky behaving unlike right click on
    //   anything else would be rule with hole in it.
    if (nimIsHoverBackdrop() && nimHoverHandle() >= 0) {
      pickOnClick(nimHoverHandle(), button_mouse_down, e.shiftKey);
    } else if (button_mouse_down === 0 && !e.shiftKey) {
      // Mirrors touch's own "tapping empty space always cancels" rule. Shift+click over.
      //   empty space is left no-op, not clear -- shift means "preserve what I have" --
      //   and so is right click, whose job on empty space is to pan.
      clearSelection();
    }
  }

  button_mouse_drag = null;
  button_mouse_down = null;
  nimSetCameraDragging(false);
}

function releasePointer(e: PointerEvent) {
  if (e.pointerType === 'mouse') {
    endMouseDrag(e);
    pointers.delete(e.pointerId);
    return;
  }

  // Touch:
  //   tap is same-finger down+up within time/distance bounds, with no second finger ever joining
  //   and no long-press already having fired -- resolves into selection toggle (see `handleTap`).
  //   Released, whether or not hold had matured; frame that matured it has already
  //   selected object. Hold itself lives on for one settle, which is what shrinks
  //   marker back -- `nimIsHoldSpent` retires it in draw loop.
  nimReleaseHold(now());
  if (is_touch_dragging) {
    // Construction drag ends exactly as mouse's own does -- same call, same three.
    //   outcomes -- because it *is* same gesture reached by different pointer.
    //   Drag is never also tap, so this branch runs instead of `handleTap`.
    //   `pointercancel` is browser saying it has taken gesture over, which is not
    //   release: it cancels rather than building something reader never let go of.
    if (e.type === 'pointercancel') {
      nimCancelDrag();
    } else {
      const result = nimEndDrag(now());
      toast(result.message);
      if (result.created_handle >= 0) adoptConstructionSelection();
      else if (result.is_more) openApplyPickerOnOperands(cursor_last);
    }
    is_touch_dragging = false;
  } else if (!has_long_press_fired && touch_down_at !== null && !has_touch_moved &&
      pointers.size === 1 && performance.now() - touch_down_at < TAP_MAX_MS) {
    if (position_touch_down !== null) handleTap(position_touch_down);
  }
  touch_down_at = null;
  has_long_press_fired = false;
  handle_touch_down = -1;
  pointers.delete(e.pointerId);
  if (pointers.size < 2) {
    separation_pinch_start = null; is_pinch_zooming = false; pan_last = null;
    is_two_fingers_pending = false;
  }
  if (pointers.size === 0) nimSetCameraDragging(false);
  if (pointers.size === 0) nimClearHover(); // No finger left touching canvas -- there's
    // no cursor position left to be "hovering" anything, so don't let last touch-down's
    // own hover reading linger and draw its ring forever.
}
canvas.addEventListener('pointerup', releasePointer);
canvas.addEventListener('pointercancel', releasePointer);
canvas.addEventListener('pointerleave', (e) => { if (e.buttons === 0) releasePointer(e); });

canvas.addEventListener('wheel', (e) => {
  e.preventDefault();
  // Toward what pointer is over, way map zooms.
  //   Where that is comes from cursor this build already tracks, so wheel says it same way picking
  //   does.
  const rect = canvas.getBoundingClientRect();
  nimUpdateCursor(e.clientX - rect.left, e.clientY - rect.top);
  // **Summed here, applied once by frame loop.** Trackpad reports several notches.
  //   between two frames, and each dolly runs `picking.anchorZoomAt` to find what
  //   cursor is over -- full pick over every live handle, 11.4 ms on 1,024-object demo.
  //   Six notches frame measured 83.8 ms of picking on frame, for 136 ms gap, and
  //   every answer but last was thrown away. Factor is `exp(k*delta)`, so summing
  //   deltas and exponentiating once is same zoom, not approximation of it.
  deltas_wheel += e.deltaY;
}, { passive: false });

/* ---- Touch tap-to-toggle / mouse click-to-select ---- */
/*   Long-pressing (touch) or plain-clicking (mouse) object selects it; further         */
/*   tap or shift-click toggles another object into/out of same selection.               */
/*   selection menu's own content depends purely on how many objects are selected --     */
/*   see `refreshSelectionMenu` -- 1 or 2 offer apply (revealing unary/binary catalogue   */
/*   dropdown) plus hide/delete; 3+ offer only hide/delete, bulk-acting on every          */
/*   selected handle at once. Tapping/clicking empty space, or menu's own close            */
/*   button, always clears whole selection.                                              */

function handleTap(position_local: PointLocal) {
  const rect = canvas.getBoundingClientRect();
  nimUpdateCursor(position_local.x, position_local.y);
  nimUpdateHover(canvas.clientWidth, canvas.clientHeight);
  const hovered = nimHoverHandle();

  // Sky counts as empty space to *tap*, deliberately, though mouse click selects.
  //   it: tapping empty space is only way finger has to dismiss selection, and
  //   spending it on selecting backdrop would take that away. Touch reaches sky
  //   through long-press instead -- which is where its marker fills anyway.
  if (hovered < 0 || nimIsHoverBackdrop()) {
    clearSelection(); // Tapping empty space always cancels.
    return;
  }
  if (handles_selection.length === 0) return; // Not in select mode yet -- only long-press
    // starts one; plain tap before that is no-op, same as before this feature.
  pickByPointer(hovered);
  toggleSelection(hovered, position_local);
}

const menu_selection = elementById('selection-menu');
const menu_selection_apply = elementById('selection-menu-apply');
const menu_selection_edit = elementById('selection-menu-edit');
const menu_selection_hide = elementById('selection-menu-hide');
const menu_selection_delete = elementById('selection-menu-delete');
const menu_selection_reveal = elementById('selection-menu-reveal');
const menu_selection_select = elementById<HTMLSelectElement>('selection-menu-select');
const menu_selection_back = elementById('selection-menu-back');
const menu_selection_close = elementById('selection-menu-close');
let arity_menu_last = -1; // Arity last used to rebuild selection-menu-select's own
  // <option> list -- like drawer's own populateOperations, only rebuilds when it
  // actually changes, not on every reveal.

function populateSelectionMenuOptions(arity: number) {
  if (arity === arity_menu_last) return;
  arity_menu_last = arity;
  menu_selection_select.innerHTML = '';
  const count = nimOperationCount();
  for (let i = 0; i < count; i++) {
    if (nimOperationArity(i) !== arity) continue;
    const option = document.createElement('option');
    option.value = String(i);
    option.textContent = nimOperationNotation(i);
    menu_selection_select.appendChild(option);
  }
}

function openSelectionMenuOp() {
  // "apply" itself never moves -- it stays leftmost element of one single row.
  //   throughout; this only animates picker+back group open immediately to its
  //   right (see .selection-menu-reveal's own max-width transition). hide/delete step
  //   aside while picking operation, matching old two-row design's own behaviour
  //   (its second row never carried them either) -- ✕ stays, as it always did.
  const arity = nimSelectionArity();
  populateSelectionMenuOptions(arity);
  // Open on whatever was last applied at this arity, and preview it straight away.
  //   Rather than on head of list; picker's answer is worth seeing while choosing, not
  //   only once apply is pressed.
  menu_selection_select.value = String(nimOperationRemembered(arity));
  previewSelectionMenuOperation();
  menu_selection_reveal.classList.add('open');
  menu_selection_edit.style.display = 'none';
  menu_selection_hide.style.display = 'none';
  menu_selection_delete.style.display = 'none';
}

function previewSelectionMenuOperation() {
  // Both operands come from selection in pick order, exactly as apply reads them.
  const first = handles_selection[0];
  const second = handles_selection.length > 1 ? handles_selection[1] : handles_selection[0];
  if (first === undefined || second === undefined) return;
  nimPreviewOperation(parseInt(menu_selection_select.value, 10), first, second);
}

function closeSelectionMenuOp() {
  // Nothing is being chosen any more, so nothing is being previewed.
  //   Drawer's own section may still be open behind this menu, so ask it to speak up again rather
  //   than leaving view blank while control that has something to say is on screen.
  nimClearPreview();
  previewDrawerOperation();
  menu_selection_reveal.classList.remove('open');
  menu_selection_edit.style.display = handles_selection.length === 1 ? '' : 'none';
  menu_selection_hide.style.display = '';
  menu_selection_delete.style.display = '';
}

menu_selection_select.addEventListener('change', previewSelectionMenuOperation);

function refreshSelectionMenu(position_local: PointLocal | null) {
  const n = handles_selection.length;
  if (n === 0) { hideSelectionMenu(); return; }
  menu_selection_apply.style.display = (n === 1 || n === 2) ? '' : 'none'; // 3+: no apply --
    // this menu has no operand pickers, so it cannot say which two of three it would use.
  menu_selection_edit.style.display = n === 1 ? '' : 'none'; // One object has one editor.
  menu_selection_hide.textContent = nimSelectionAllHidden() ? 'show' : 'hide';
  closeSelectionMenuOp(); // Any fresh selection change resets picker closed.
  if (position_local) {
    positionSelectionMenuAt(position_local);
  } else {
    offset_menu_selection = null; // Opened with no pointer: above object, as ever.
    updateSelectionMenuPosition();
  }
  menu_selection.classList.add('show');
}

// Whether floating selection menu is currently up. Its own reader because it is now.
//   question click rule asks (see `pickOnClick`), not just class this file toggles.
function isSelectionMenuShown() {
  return menu_selection.classList.contains('show');
}

function hideSelectionMenu() {
  menu_selection.classList.remove('show');
  closeSelectionMenuOp();
  arity_menu_last = -1;
  offset_menu_selection = null;
}

// Where menu's top-left corner stands from last-picked object's anchor, in canvas pixels,.
//   while pointer placed it; null where it was opened with no pointer and sits above
//   object instead. Offset rather than fixed spot, so orbiting carries menu with object
//   instead of snapping it back to object's centre next frame -- what every frame used
//   to do, one frame after click had placed it.
let offset_menu_selection: PointLocal | null = null;
// How far menu's corner stands from pointer that opened it, in pixels.
//   Context menu's own convention: beside pointer, not under it.
const INSET_MENU_POINTER = 8;
// How far menu stands above object it was opened over with no pointer, in pixels.
const LIFT_MENU_ANCHOR = 60;

// Read where last-picked object stands on canvas, or null off screen or behind eye.
function anchorOfSelectionMenu() {
  if (handles_selection.length === 0) return null;
  const handle_anchor = handles_selection[handles_selection.length - 1];
  if (handle_anchor === undefined) return null;
  const anchor = nimAnchorScreen(handle_anchor, canvas.clientWidth, canvas.clientHeight);
  return (anchor[2] ?? 0) > 0.5
    ? { x: anchor[0] ?? 0, y: anchor[1] ?? 0 }
    : null;
}

// Put menu's top-left corner at canvas-local point, kept inside window.
function placeSelectionMenu(corner_local: PointLocal) {
  const rect = canvas.getBoundingClientRect();
  // Reserved right margin covers widest state this popover reaches: op-picker.
  //   row (select sized to its own longest notation, e.g. "𝐧 ∨ (𝐦 ∧ 𝐧☆)", plus "apply"/
  //   "back") now that select's own width is content-sized rather than truncated.
  menu_selection.style.left =
    Math.max(8, Math.min(rect.left + corner_local.x, window.innerWidth - 300)) + 'px';
  menu_selection.style.top =
    Math.max(8, Math.min(rect.top + corner_local.y, window.innerHeight - 60)) + 'px';
}

// Open menu beside pointer, and remember where that is from object it is about.
function positionSelectionMenuAt(position_local: PointLocal) {
  const corner = {
    x: position_local.x + INSET_MENU_POINTER, y: position_local.y + INSET_MENU_POINTER,
  };
  const anchor = anchorOfSelectionMenu();
  offset_menu_selection = anchor ? { x: corner.x - anchor.x, y: corner.y - anchor.y } : null;
  placeSelectionMenu(corner);
}

function updateSelectionMenuPosition() {
  // Keep menu with most-recently-selected handle every frame it's open: at offset pointer.
  //   left it, or above object where no pointer opened it. Most recent rather than
  //   average across all selected, which would jump around as membership changes.
  if (!menu_selection.classList.contains('show') || handles_selection.length === 0) return;
  const anchor = anchorOfSelectionMenu();
  if (anchor === null) return; // Off-screen -- leave menu at its last valid spot.
  if (offset_menu_selection !== null) {
    placeSelectionMenu({
      x: anchor.x + offset_menu_selection.x, y: anchor.y + offset_menu_selection.y,
    });
  } else {
    placeSelectionMenu({ x: anchor.x, y: anchor.y - LIFT_MENU_ANCHOR });
  }
}

menu_selection_apply.addEventListener('click', () => {
  // Serve both roles with one button: first press opens picker, second commits.
  //   Picker animates open to this same button's own right; button itself never moves
  //   or relabels.
  //   Second press commits with whatever operation is currently selected, instead of
  //   separate "go" button appearing once picker opens.
  if (!menu_selection_reveal.classList.contains('open')) {
    openSelectionMenuOp();
    return;
  }
  const n = handles_selection.length;
  if (n !== 1 && n !== 2) return; // Guard only -- apply is hidden for 0/3+ anyway.
  if (nimSceneCount() >= nimSceneCapacity()) { toast(nimFullMessage()); return; }
  const first = handles_selection[0];
  const second = n === 2 ? handles_selection[1] : first; // Unary ignores second operand.
  if (first === undefined || second === undefined) return;
  const result = nimApplyOperation(
    parseInt(menu_selection_select.value, 10), first, second, now());
  toast(result.message);
  adoptConstructionSelection();
});
menu_selection_edit.addEventListener('click', () => {
  // Offer edit here, since reaching object's editor otherwise means hunting its row.
  //   Even with that object already picked and its own menu on screen.
  if (handles_selection.length !== 1) return; // Guard only -- hidden for 0 and 2+ anyway.
  openPanelTo(handles_selection[0] ?? null);
  hideSelectionMenu(); // Panel owns interaction now; pick itself stays.
});

menu_selection_back.addEventListener('click', closeSelectionMenuOp);

menu_selection_hide.addEventListener('click', () => {
  // Whichever way button reads is what it does, so objects it hid can be brought.
  //   back from same place -- `nimSelectionAllHidden` owns what "hidden" means for
  //   whole selection, way row button reads `nimObjectVisible` for one object.
  const show = nimSelectionAllHidden();
  for (const handle of handles_selection) nimSetVisible(handle, show);
  toast(nimVisibilityMessage(handles_selection.length, show));
  refreshSelectionMenu(null); // Relabels button for what it would now do.
  refreshObjectsUI(); // Selection itself is kept -- hiding doesn't invalidate handle.
});

menu_selection_delete.addEventListener('click', () => {
  const n = handles_selection.length;
  for (const handle of handles_selection) nimRemoveObject(handle);
  toast(nimDeletedMessage(n));
  clearSelection();
  refreshObjectsUI();
});

menu_selection_close.addEventListener('click', clearSelection);

document.addEventListener('pointerdown', (e) => {
  // Only tap/click landing outside canvas, menu itself, drawer.
  //   (interacting with Objects list/panel must not dismiss selection menu
  //   or clear selection), and top chip-row (save/load scene lives there too)
  //   should dismiss it here -- dismissing on canvas's own down event would race
  //   handleTap/endMouseDrag's own resolution of that same gesture.
  const target = e.target as Node | null;
  if (menu_selection.classList.contains('show') && !menu_selection.contains(target) &&
      e.target !== canvas && !drawer.contains(target) && !row_chip.contains(target)) {
    clearSelection();
  }
  // **Help is not dismissed by tap outside it**, unlike two popovers either side.
  //   of this. It is opened to be read *while* doing thing it describes -- that is
  //   whole reason it is cut by way of working rather than by kind of control -- and
  //   first touch of that thing used to close it, including touch on canvas. It goes
  //   when reader says so: its own close button, `?` that opened it, or escape.
  // Top menu: same shape of guard, its own state/target -- tap landing outside.
  //   popover and outside its own trigger button closes it.
  if (menu_top.classList.contains('show') && !menu_top.contains(e.target as Node | null)
      && e.target !== button_menu
      && !button_menu.contains(e.target as Node | null)) {
    menu_top.classList.remove('show');
    button_menu.classList.remove('on');
  }
});
