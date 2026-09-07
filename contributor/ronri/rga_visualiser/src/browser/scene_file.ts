// Scene file download and upload; not Nim because these reach browser APIs Nim's JS backend does
//   not express.
//   Presentation alone: every join, meet, pick, drag and camera move is computed by
//   bridge, compiled from same modules desktop draws through (Article II.9).
//   Concatenated into page in order `tools/build.nim` names; see its `SCRIPTS`.

/* ---------------------------------------------------------------------- */
/* Scene save/load: pack and parse exact `.rgascene` binary format         */
/* `scene.nim`'s own doc comment documents (magic/version/basis-count/     */
/* object-count/per-object ink+visible+label+16 float64+radius+shines), so    */
/* build saves loads on desktop build and vice versa. Packing lives       */
/* here rather than in Nim, since `DataView` already does exactly this     */
/* natively -- see `bridge.nim`'s own doc comment.                */
/* ---------------------------------------------------------------------- */

function saveScene() {
  // Creation order, not handle order: version-3 file promises its sequence is order.
  //   scene was built in, and removed-then-re-added object sits in reused handle
  //   well before objects that predate it. Loading walks sequence back one object at
  //   time, so writing handle order here would replay construction that never happened.
  const handles = nimSceneHandlesCreated();
  const count_basis = nimBasisCount();
  // Labels go out as UTF-8 bytes, which is what format holds and what `scene.nim`.
  //   writes: derived label carries operator notation (`a ∧ b`, `a ∨ b`, `a ⊖ b`), and
  //   JavaScript string's own `.length` counts UTF-16 units while `charCodeAt` truncated to
  //   byte throws away everything above U+00FF. Both together wrote shorter length than
  //   bytes that followed, so every object after first non-ASCII label parsed from
  //   wrong offset. Measured: `a ⊖ b` came back on desktop as `a` and replacement
  //   glyph.
  const encoder = new TextEncoder();
  const objects = handles.map((handle) => ({
    ink: nimObjectInk(handle),
    visible: nimObjectVisible(handle),
    label: encoder.encode(nimObjectLabel(handle)),
    coefficients: nimObjectCoefficients(handle),
    radius: nimObjectRadius(handle),
    shines: nimObjectShines(handle),
  }));

  let size = 4 + 1 + 1 + 4;
  for (const object of objects) size += 1 + 1 + 1 + object.label.length + count_basis * 8 + 8 + 1;

  const buffer = new ArrayBuffer(size);
  const view = new DataView(buffer);
  let offset = 0;
  // Magic and version come from `scene.nim` through bridge, never from literals here:
  //   version was literal `1` and stayed one through format's bump to 2, so this
  //   build stamped every file it saved with version its own content was not.
  const magic = nimSceneMagic();
  for (let i = 0; i < magic.length; i++) {
    view.setUint8(offset, magic.charCodeAt(i));
    offset += 1;
  }
  view.setUint8(offset, nimSceneVersion()); offset += 1;
  view.setUint8(offset, count_basis); offset += 1;
  view.setUint32(offset, objects.length, true); offset += 4;

  for (const object of objects) {
    view.setUint8(offset, object.ink); offset += 1;
    view.setUint8(offset, object.visible ? 1 : 0); offset += 1;
    view.setUint8(offset, object.label.length); offset += 1;
    for (const byte of object.label) { view.setUint8(offset, byte); offset += 1; }
    for (let i = 0; i < count_basis; i++) {
      view.setFloat64(offset, object.coefficients[i] ?? 0, true);
      offset += 8;
    }
    view.setFloat64(offset, object.radius, true); offset += 8;
    view.setUint8(offset, object.shines ? 1 : 0); offset += 1;
  }

  deliverFile(
    new Blob([buffer], { type: 'application/octet-stream' }), 'scene.rgascene',
    'application/octet-stream',
    'A scene file holding ' + objects.length + ' object(s)',
  );
}

function loadSceneFile(file: File) {
  const reader = new FileReader();
  reader.onload = () => {
    try {
      const read = reader.result;
      if (!(read instanceof ArrayBuffer)) throw new Error('Scene file unread.');
      const outcome = parseAndLoadScene(read);
      toast(outcome);
      adoptConstructionSelection(); // nimSceneClear() inside already cleared hover.
    } catch (err) {
      toast(String(err instanceof Error ? err.message : err));
    }
  };
  reader.onerror = () => toast('Could not read `' + file.name + '`.');
  reader.readAsArrayBuffer(file);
}

function parseAndLoadScene(buffer: ArrayBuffer) {
  const view = new DataView(buffer);
  if (buffer.byteLength < 10) throw new Error('`' + 'file' + '` is not a scene file.');
  let offset = 0;
  // Both expectations come from `scene.nim` through bridge, for reason `saveScene`.
  //   above gives: literal here is exactly what drifted out of step with format.
  const magic_wanted = nimSceneMagic();
  let magic = '';
  for (let i = 0; i < magic_wanted.length; i++) magic += String.fromCharCode(view.getUint8(i));
  offset = magic_wanted.length;
  if (magic !== magic_wanted) throw new Error('File is not a scene file.');
  // *range* through bridge, not this build's own writing version: every version.
  //   ever written stays readable, and which those are is `scene.readsSceneVersion`'s
  //   answer rather than pair of literals here to fall out of step with it.
  const version = view.getUint8(offset); offset += 1;
  if (!nimSceneReadsVersion(version)) {
    throw new Error('File is a scene file of a version this build cannot read.');
  }
  const count_basis_file = view.getUint8(offset); offset += 1;
  const count_basis_here = nimBasisCount();
  if (count_basis_file !== count_basis_here) {
    throw new Error(
      'File was saved under a different PGA dimension or metric; this build reads ' +
      count_basis_here + '-term multivectors.',
    );
  }
  const count_object = view.getUint32(offset, true); offset += 4;
  if (count_object > nimSceneCapacity()) {
    throw new Error(
      'File holds ' + count_object + ' objects, more than this build’s ' +
      nimSceneCapacity() + '-object capacity.',
    );
  }

  const parsed = [];
  for (let i = 0; i < count_object; i++) {
    if (offset + 3 > buffer.byteLength) {
      throw new Error('File is truncated partway through object ' + i + '.');
    }
    const ink = view.getUint8(offset); offset += 1;
    const visible = view.getUint8(offset) !== 0; offset += 1;
    const length_label = view.getUint8(offset); offset += 1;
    if (offset + length_label > buffer.byteLength) {
      throw new Error(
        'File is truncated partway through object ' + i + '’s label.',
      );
    }
    // Decoded as UTF-8, for reason `saveScene` gives: byte-per-character would read.
    //   every operator in derived label as two or three Latin-1 characters of noise.
    const label = new TextDecoder().decode(
      new Uint8Array(buffer, offset, length_label),
    );
    offset += length_label;
    if (offset + count_basis_here * 8 > buffer.byteLength) {
      throw new Error('File is truncated partway through object ' + i + '’s geometry.');
    }
    const coefficients = new Array(count_basis_here);
    for (let b = 0; b < count_basis_here; b++) {
      coefficients[b] = view.getFloat64(offset, true);
      offset += 8;
    }
    // Radius only where file's version wrote one; which versions did is Nim's rule.
    //   Older file's objects take theirs from upgrade chain, so value passed is moot.
    let radius = nimDefaultRadius();
    if (nimSceneHasRadius(version)) {
      if (offset + 8 > buffer.byteLength) {
        throw new Error('File is truncated partway through object ' + i + '’s radius.');
      }
      radius = view.getFloat64(offset, true);
      offset += 8;
    }
    let shines = false;
    if (nimSceneHasShine(version)) {
      if (offset + 1 > buffer.byteLength) {
        throw new Error('File is truncated partway through object ' + i + '’s shine.');
      }
      shines = view.getUint8(offset) !== 0;
      offset += 1;
    }
    parsed.push({ ink, visible, label, coefficients, radius, shines });
  }

  nimSceneClear();
  // In file order, which from version 3 on is order objects were built: each is.
  //   stamped to appear beat after last, so scene replays its own construction.
  //   Version rides along because older file's palette ordinals mean something
  //   else; mapping is Nim's, not this parser's.
  //   One clock reading for whole arrival, taken before loop: read per object it
  //   would creep forward by however long parsing took, which is stagger nobody chose.
  const arrived = now();
  for (const object of parsed) {
    const handle = nimSceneAddRaw(
      version, object.ink, object.visible, object.label, object.coefficients, object.radius,
      object.shines, count_object, arrived,
    );
    if (handle < 0) throw new Error('File names an unknown palette slot or radius for an object.');
  }
  return 'Loaded ' + count_object + ' object(s) from scene file.';
}
