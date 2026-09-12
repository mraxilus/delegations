// Camera numeric fields; not Nim because these reach browser APIs Nim's JS backend does not
//   express.
//   Presentation alone: every join, meet, pick, drag and camera move is computed by
//   bridge, compiled from same modules desktop draws through (Article II.9).
//   Concatenated into page in order `tools/build.nim` names; see its `SCRIPTS`.

/* ---------------------------------------------------------------------- */
/* View panel: camera numeric fields, mirroring panel.layoutView exactly. */
/* ---------------------------------------------------------------------- */

const fields_camera = {
  azimuth: elementById<HTMLInputElement>('cam-azimuth'),
  elevation: elementById<HTMLInputElement>('cam-elevation'),
  distance: elementById<HTMLInputElement>('cam-distance'),
  fov: elementById<HTMLInputElement>('cam-fov'),
  tx: elementById<HTMLInputElement>('cam-pivot-x'),
  ty: elementById<HTMLInputElement>('cam-pivot-y'),
  tz: elementById<HTMLInputElement>('cam-pivot-z'),
};
let are_fields_camera_focused = false;
Object.values(fields_camera).forEach((element) => {
  element.addEventListener('focus', () => { are_fields_camera_focused = true; });
  element.addEventListener('blur', () => { are_fields_camera_focused = false; });
});
// Commit each field on change.
//   Falls back to value camera treats as its own floor for that quantity where box is
//   left empty or unparseable.
function commitCameraField(
  field: HTMLInputElement, apply: (value: number) => void, fallback: number,
) {
  field.addEventListener('change', () => apply(parseFloat(field.value) || fallback));
}
commitCameraField(fields_camera.azimuth, nimSetCameraAzimuth, 0);
commitCameraField(fields_camera.elevation, nimSetCameraElevation, 0);
commitCameraField(fields_camera.distance, nimSetCameraDistance, 0.1);
commitCameraField(fields_camera.fov, nimSetCameraFov, 45);

function commitPivot() {
  nimSetCameraPivot(
    parseFloat(fields_camera.tx.value) || 0,
    parseFloat(fields_camera.ty.value) || 0,
    parseFloat(fields_camera.tz.value) || 0,
  );
}
fields_camera.tx.addEventListener('change', commitPivot);
fields_camera.ty.addEventListener('change', commitPivot);
fields_camera.tz.addEventListener('change', commitPivot);

// Each field's last written value, so still camera formats and writes nothing.
//   Seven `nimFormatNumber` calls and seven input writes ran five times second for
//   numbers that had not moved. `NaN` before first tick: equal to nothing, so first
//   comparison always writes.
const camera_written = {
  azimuth: NaN, elevation: NaN, distance: NaN, fov: NaN, tx: NaN, ty: NaN, tz: NaN,
};
function writeCameraField(name: keyof typeof camera_written, value: number) {
  if (camera_written[name] === value) return;
  camera_written[name] = value;
  // `nimFormatNumber`, not `toFixed` here: angle of 1.05 should read `1.05` rather.
  //   than `1.050`, and desktop draws every one of these with same widget.
  fields_camera[name].value = nimFormatNumber(value);
}

function refreshCameraFields() {
  if (are_fields_camera_focused) return; // Don't fight value user is mid-typing.
  writeCameraField('azimuth', nimCameraAzimuth());
  writeCameraField('elevation', nimCameraElevation());
  writeCameraField('distance', nimCameraDistance());
  writeCameraField('fov', nimCameraFov());
  const pivot = nimCameraPivot();
  writeCameraField('tx', pivot[0] ?? 0);
  writeCameraField('ty', pivot[1] ?? 0);
  writeCameraField('tz', pivot[2] ?? 0);
}

// **Asked for here, taken inside frame that draws it.** Context is created without.
//   `preserveDrawingBuffer` (see its own note), so canvas read from task of its own finds
//   drawing buffer already composited and thrown away -- read comes back blank or
//   fails outright, which is image button doing nothing at all. `preserveDrawingBuffer:
//   true` would fix it by making every frame keep copy forever, on phones, to serve
//   button pressed once in session; capturing between last draw call and yield
//   costs nothing and is same capture-then-yield shape `runStoryboard` uses.
//
//   Two theories for moving this into handler instead -- `renderFrame` then synchronous
//   `toDataURL` -- were tried and **both are false**, recorded so they are not re-derived:
//
//   - *It would keep transient activation `navigator.share` needs.* It is not lost:
//     window is around five seconds and spans task boundary. Measured against stub
//     that refuses without `navigator.userActivation.isActive` -- this build passes it.
//   - *It would stop backgrounded tab stranding capture,* since `requestAnimationFrame`
//     stops there. Did not reproduce: tapping and backgrounding page immediately still
//     delivered file.
//
//   With no measured benefit left, asynchronous read wins on cost: `toDataURL` blocks
//   main thread for whole encode, which on phone-sized canvas is most of second of
//   frozen UI.
let is_capture_wanted = false;
elementById('button-export-png').title = nimWording(Wording.TipMenuSaveImage);
elementById('button-export-png').addEventListener('click', () => {
  is_capture_wanted = true;
  toast('Capturing the next frame\u2026');
});

function captureFrameIfAsked() {
  if (!is_capture_wanted) return;
  is_capture_wanted = false;
  const [width, height] = [canvas.width, canvas.height];
  canvas.toBlob((blob) => {
    // `toBlob` hands back null where encoding failed. Unchecked, next line threw into.
    //   async callback nobody watches -- silence on top of silence.
    if (blob === null) {
      toast('The browser could not encode this frame as a PNG.');
      return;
    }
    deliverFile(
      blob, 'rga_visualiser.png', 'image/png',
      'A ' + width + '\u00d7' + height + ' image of this view',
    );
  }, 'image/png');
}

// **One button per size, built from what bridge reports.** Counts are
// `orrery.ScaleOrrery`'s and nothing here knows them: size added or renamed there shows up
// as button without this file or markup being touched. Button is labelled with
// count because count is what reader picking between benchmark scenes is choosing.
for (const scale of nimDemoScales()) {
  const objects = nimDemoObjects(scale);
  const button = document.createElement('button');
  button.className = 'button';
  button.type = 'button';
  button.id = `button-load-demo-${objects}`;
  button.textContent = String(objects);
  button.title = nimDemoWording(objects, scale === nimDemoScaleDefault());
  button.addEventListener('click', () => {
    nimLoadDemo(scale, now(), canvas.width, canvas.height);
    toast(nimOrreryMessage(nimSceneCount(), nimSceneCapacity()));
    adoptConstructionSelection();
  });
  elementById('button-demo-scales').appendChild(button);
}
