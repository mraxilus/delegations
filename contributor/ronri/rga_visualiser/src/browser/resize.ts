// Canvas resize against device pixel ratio; not Nim because these reach browser APIs Nim's JS
//   backend does not express.
//   Presentation alone: every join, meet, pick, drag and camera move is computed by
//   bridge, compiled from same modules desktop draws through (Article II.9).
//   Concatenated into page in order `tools/build.nim` names; see its `SCRIPTS`.

/* ---------------------------------------------------------------------- */
/* Resize                                                                   */
/* ---------------------------------------------------------------------- */

// **Experiments: one suspect off at time, its cost read off rows.** Browser's main.
//   thread spends most of frame on device after callback returns (`style + layout +
//   paint` at 10.7 ms median of 16.7 on still scene), and page cannot tell apart from
//   inside what it spends it on: every backdrop blur over canvas that changes each
//   frame, canvas at full pixel ratio with antialiasing, or SVG overlay's paint. Each
//   pill switches one off at runtime; reader flips one, watches row, and reports.
//   None is saved: these are instruments, not settings.
let cap_ratio_pixel = 2.5;
function ratioPixel() {
  return Math.min(window.devicePixelRatio || 1, cap_ratio_pixel);
}
function wireExperiment(id: string, apply: (is_on: boolean) => void) {
  const toggle = elementIfPresent(id);
  if (toggle === null) return;
  toggle.addEventListener('click', () => {
    const is_on = toggle.classList.toggle('on');
    apply(is_on);
  });
}
wireExperiment('toggle-blur', (is_on) => {
  document.body.classList.toggle('without-blur', !is_on);
});
wireExperiment('toggle-full-ratio', (is_on) => {
  cap_ratio_pixel = is_on ? 2.5 : 1;
  resize();
});
// Overlay's refresh stops with its paint.
//   Writing to layer with no layout cost `overlay + menu` 4.6 ms mean on device, which
//   is experiment's own artefact standing in page's column.
let is_overlay_shown = true;
wireExperiment('toggle-overlay', (is_on) => {
  is_overlay_shown = is_on;
  svg_overlay.style.display = is_on ? '' : 'none';
});

function resize() {
  const ratio_pixel = ratioPixel();
  const w = Math.round(canvas.clientWidth * ratio_pixel);
  const h = Math.round(canvas.clientHeight * ratio_pixel);
  if (canvas.width !== w || canvas.height !== h) {
    canvas.width = w;
    canvas.height = h;
    gl.viewport(0, 0, w, h);
  }
  svg_overlay.setAttribute('viewBox', '0 0 ' + canvas.clientWidth + ' ' + canvas.clientHeight);
}
window.addEventListener('resize', resize);
