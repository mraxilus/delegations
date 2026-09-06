// Keyboard shortcuts, over document key events; not Nim because these reach browser APIs Nim's JS
//   backend does not express.
//   Presentation alone: every join, meet, pick, drag and camera move is computed by
//   bridge, compiled from same modules desktop draws through (Article II.9).
//   Concatenated into page in order `tools/build.nim` names; see its `SCRIPTS`.

/* ---------------------------------------------------------------------- */
/* Keyboard. Undo and redo were reachable only by pressing their buttons,  */
/*   and drag once begun had no way out at all, though `cancelDrag` has    */
/*   existed and been tested throughout. Nothing new happens here: these   */
/*   are second ways to reach what buttons already do.                     */
/* ---------------------------------------------------------------------- */

document.addEventListener('keydown', (e) => {
  // Typing in field is not shortcut: coefficient or label is edited with very.
  //   keys these bind, and ctrl+z inside input already means browser's own undo.
  const target = e.target as HTMLElement | null;
  if (target && (target.tagName === 'INPUT' || target.tagName === 'TEXTAREA' ||
      target.isContentEditable)) {
    return;
  }

  if (e.key === 'Escape') {
    // Everything in progress, in order reader would expect to shed it: panel.
    //   they just opened, then menu, then gesture underneath.
    if (panel_help.classList.contains('show')) { showHelp(false); return; }
    if (menu_top.classList.contains('show')) {
      menu_top.classList.remove('show');
      button_menu.classList.remove('on');
      return;
    }
    if (nimDragActive()) { nimCancelDrag(); toast('Cancelled.'); return; }
    nimCancelHold();
    if (menu_selection.classList.contains('show')) { clearSelection(); return; }
    if (session_edit !== null) { endEditSession(); refreshObjectsUI(); }
    return;
  }

  // 3D view answers its own keys, but only while it actually has focus -- it is one.
  //   ordinary tab stop (see its `tabindex` in markup), so reader tabs into it,
  //   drives it, and tabs onward. Tab itself is never intercepted: rebinding it inside
  //   canvas is tempting design and risks keyboard trap, which WCAG 2.1.2 rules
  //   out at same level 2.1.1 asks for this in first place.
  //   Which key does what is `interaction.actionFor`'s to say; only DOM's own naming
  //   of keys is translated across, exactly as SDL scancodes are on desktop side.
  if (document.activeElement === canvas && !(e.ctrlKey || e.metaKey || e.altKey)) {
    // `e.code`, physical key, which is what desktop's scancodes name -- see.
    //   `browser_bridge.keyFor`. Key that moves view is held from here until its
    //   `keyup` below; key that acts does so on this press.
    if (nimKeyBound(e.code)) {
      e.preventDefault(); // Arrows would otherwise scroll page under canvas.
      const slot = nimKeyDown(e.code);
      if (slot >= 0) {
        // Shift adds rather than replaces, exactly as shift-click does -- one thing.
        //   shift state means that shared binding table cannot answer alone.
        if (e.shiftKey) toggleSelection(slot, null); else selectOnly(slot, null);
      }
      return;
    }
  }

  // Ctrl on every platform, and cmd as well on macOS, where ctrl+z is not what reader.
  //   with muscle memory presses.
  if (!(e.ctrlKey || e.metaKey)) return;
  const key = e.key.toLowerCase();
  if (key === 'z' && !e.shiftKey) {
    e.preventDefault();
    stepHistory(true);
  } else if ((key === 'z' && e.shiftKey) || key === 'y') {
    e.preventDefault();
    stepHistory(false);
  }
});

// Let go of every held key whenever its release could go missing.
//   Key can only stop moving camera if its release is seen, and there are three ways
//   for one to go missing: release lands while another element has focus, window loses
//   focus entirely, or tab is hidden.
//   First is handled by matching keydown guard; other two let go of everything.
document.addEventListener('keyup', (e) => {
  nimKeyUp(e.code);
});
window.addEventListener('blur', () => { nimReleaseKeysAll(); nimSetCameraDragging(false); });
canvas.addEventListener('blur', () => { nimReleaseKeysAll(); });
document.addEventListener('visibilitychange', () => {
  if (document.hidden) { nimReleaseKeysAll(); nimSetCameraDragging(false); }
});

// Write `disabled` only where it moved.
//   Compared first, so button whose state stands costs its tick one property read and
//   no attribute write.
function writeDisabled(button: HTMLButtonElement, is_disabled: boolean) {
  if (button.disabled !== is_disabled) button.disabled = is_disabled;
}

function refreshUndoRedoButtons() {
  // Dimmed/disabled (via shared .button:disabled rule) whenever there's nothing on.
  //   that side of timeline to move to -- checked after every history-touching
  //   action below, plus once per low-cadence UI tick to catch every other path
  //   (add, apply, remove, load demo, scene load/clear) without hooking each one.
  writeDisabled(button_undo, !nimCanUndo());
  writeDisabled(button_redo, !nimCanRedo());
}
