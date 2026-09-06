// CSS sizes, kept by observer rather than read per frame; not Nim because these reach browser APIs
//   Nim's JS backend does not express.
//   Presentation alone: every join, meet, pick, drag and camera move is computed by
//   bridge, compiled from same modules desktop draws through (Article II.9).
//   Concatenated into page in order `tools/build.nim` names; see its `SCRIPTS`.

/* ---------------------------------------------------------------------- */
/* Sizes: every CSS size low-cadence tick reads, kept by observer.        */
/* ---------------------------------------------------------------------- */

// **Kept by `ResizeObserver`, never measured inside tick.** `clientWidth` read after
//   tick's own writes forces browser to lay whole document out there and then, inside
//   frame: measured at 0.9 ms of 1.3 ms tick on pool grid. Ruler, curve and
//   sparkline each read theirs same way, after writes tick had just made; that cost
//   is unmeasured on desktop, where layout is cheap, and is only mechanism found for
//   once-second spike phone showed. Observer answers same question for nothing,
//   after layout browser was doing anyway, and fires once when it starts watching.
//   Measured once here, before any frame: observer's first report lands after first
//   frame's own callback, and 0x0 canvas until then would draw nothing.
//   Callback runs after layout, so reads inside it are free.
//   `onResize` is where size's readers ask for their redraw.
//   Without observer size stands as first measured; every browser this build runs in
//   has one, and pool grid already leant on it.
function sizeObserved(element: HTMLElement | null, onResize: () => void) {
  const size = { width: 0, height: 0 };
  if (element === null) return size;
  size.width = element.clientWidth;
  size.height = element.clientHeight;
  if (typeof ResizeObserver !== 'function') return size;
  new ResizeObserver(() => {
    size.width = element.clientWidth;
    size.height = element.clientHeight;
    onResize();
  }).observe(element);
  return size;
}
// Canvas's own, read by ruler's tick.
//   Window's resize handler still measures for itself: it runs once per resize event,
//   not five times second.
const size_canvas = sizeObserved(canvas, () => {});
