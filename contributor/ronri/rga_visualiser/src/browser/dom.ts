// Document lookup and typed element handles; not Nim because these reach browser APIs Nim's JS
//   backend does not express.
//   Presentation alone: every join, meet, pick, drag and camera move is computed by
//   bridge, compiled from same modules desktop draws through (Article II.9).
//   Concatenated into page in order `tools/build.nim` names; see its `SCRIPTS`.

// Read element page's markup promises, failing loudly where markup and script disagree.
//   `document.getElementById` reports `null` for absent id, and every caller here would
//   then fail later, somewhere else, on property of nothing. Shell and scripts are built
//   together and shipped as one file, so absent id is defect in this build rather than
//   condition to handle: throwing names id at moment lookup fails (Article IV.4).
//   Caller states element kind it expects, since markup knows which is which and type
//   system cannot read markup.
function elementById<T extends Element = HTMLElement>(id: string): T {
  const found = document.getElementById(id);
  if (found === null) throw new Error("Missing element `" + id + "`.");
  return found as unknown as T;
}


// Read element markup may or may not carry, for control that is genuinely optional.
//   Separate from `elementById` so absence is decision taken at lookup rather than
//   surprise at use, and type says which controls this build treats as optional.
//   Every caller guards its result; that guard is what makes lookup optional, and losing
//   it would turn absent control into thrown error mid-frame.
function elementIfPresent<T extends Element = HTMLElement>(id: string): T | null {
  return document.getElementById(id) as unknown as T | null;
}


// Point in canvas coordinates, i.e. pixels from canvas's own top left.
//   Named once here because pointer, overlay, selection menu and frame loop all pass it
//   between them, and second spelling of same pair would drift.
interface PointLocal {
  x: number;
  y: number;
}


// Read one number from bridge's flat buffer, where walk's own bound already guarantees it
// stands.
//   Buffers arrive from bridge carrying their own count, and every walk here is bounded by
//   that count, so index inside it is always written. Reader states that once rather than
//   guarding at every read, and zero is what unwritten handle would mean anyway.
function flatAt(flat: ArrayLike<number>, index: number): number {
  return flat[index] ?? 0;
}


// Read one point of marker's flattened outline, where walk's own bound guarantees it
// stands.
//   Same reasoning as `flatAt`, one dimension up: markers arrive as pairs and every walk
//   here is bounded by their count, so origin is what unwritten pair would mean.
function pointAt(points: Array<[number, number]>, index: number): [number, number] {
  return points[index] ?? [0, 0];
}
