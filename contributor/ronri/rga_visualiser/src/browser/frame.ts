// Frame loop driving upload and draw; not Nim because these reach browser APIs Nim's JS backend
//   does not express.
//   Presentation alone: every join, meet, pick, drag and camera move is computed by
//   bridge, compiled from same modules desktop draws through (Article II.9).
//   Concatenated into page in order `tools/build.nim` names; see its `SCRIPTS`.

/* ---------------------------------------------------------------------- */
/* Frame loop -- pull one frame's tessellated vertices and view-projection */
/* matrix out of compiled Nim module and upload them straight to GL.       */
/* ---------------------------------------------------------------------- */

let ms_refresh_ui = 0;

// **Browser's own rendering, timed by message posted as frame's callback ends.**
//   Message task runs once style, layout, paint and commit that follow callback are
//   done, so its lateness is main-thread share of `display wait + browser`; rest is
//   display and GPU wait. Cut of `idle`, kept out of every sum.
//   `MessageChannel` rather than `setTimeout(0)`: timers are clamped and, under load,
//   deferred behind rendering, and message is neither.
//   Message that still loses to next frame's callback says thread was busy until that
//   frame began, so reading is clamped to handle's whole remainder rather than left to
//   count next frame's work as well -- measured 24 ms on 16.7 ms frame before clamp.
//   One in flight at time. Gated on reader: message per frame is cheap, and still work
//   for nobody while panel is shut.
let is_render_pending = false;
let at_render = 0; // Handle frame that posted message was recorded in.
let ms_render_posted = 0;
function markRendered() {
  is_render_pending = false;
  const written_idle = written_phase['idle'];
  const history_idle = history_phase['idle'];
  const history_render = history_phase['render'];
  const written_render = written_phase['render'];
  if (written_idle === undefined || history_idle === undefined ||
      history_render === undefined || written_render === undefined) return;
  let spent = performance.now() - ms_render_posted;
  if (index_history_frame !== at_render && written_idle[at_render] === 1) {
    spent = Math.min(spent, history_idle[at_render] ?? spent);
  }
  history_render[at_render] = spent > 0 ? spent : 0;
  written_render[at_render] = 1;
}
const channel_render = new MessageChannel();
channel_render.port1.onmessage = markRendered;

// Draw one frame, and nothing else. Split out of `frame()` so PNG button can draw and.
//   read back **inside its own click**, without also re-running per-tick simulation that
//   frame() does around it. Mirrors `visualiser.renderFrame`, which is split same way and
//   for same reason: desktop's storyboard capture drives it directly too.
function renderFrame(now_seconds: number) {
  resize();
  const aspect = canvas.width / canvas.height;

  // **Fine breakdown is gathered only where it is being read.** Bridge times.
  //   placing and emitting halves of *every object*, so five-thousand-point scene reads
  //   clock three times per object per frame -- measured at 2.8 ms of 16 ms build,
  //   for rows that are not on screen unless this section is expanded. Per-kind
  //   *counts* still come back either way; only times are skipped. Same argument as
  //   pool grid, objects list and operand pickers.
  const data = nimBuildFrame(
    aspect, now_seconds, canvas.height, is_axes_shown, is_grid_shown,
    !(drawer.classList.contains('open') && section_diagnostics.classList.contains('open')),
  );
  // Record bridge's own three phases into same rings this side's phases use.
  //   Bridge times them where only it can see them.
  recordPhaseTime('build', data.ms_build);
  // Frame's prologue and its view matrix, which used to belong to no row, and.
  //   residue named phases still fail to cover -- so `build` now sums from what is
  //   under it instead of merely being larger than sum.
  recordPhaseTime('camera', data.ms_camera);
  recordPhaseTime('matrix', data.ms_matrix);
  recordPhaseTime('unaccounted', data.ms_unaccounted);
  // Second cut: same milliseconds re-divided by which side of algebra.
  //   boundary they fell on. Recorded like any other row and kept out of every sum by
  //   `PHASES_CUT_DIAGNOSTIC`.
  recordPhaseTime('placing', data.ms_placing);
  recordPhaseTime('emitting', data.ms_emitting);
  // Measured between frames and reported by this one; see bridge's own note.
  recordPhaseTime('hover', data.ms_hover_pick);
  recordPhaseTime('furniture', data.ms_furniture);
  // Scenery's own two halves, which bridge has clocked apart since grid's.
  //   segment budget went in: axes are three lines at any distance, grid however
  //   many ground reach asks for, and only split says which of them moved.
  recordPhaseTime('grid', data.ms_grid);
  recordPhaseTime('axes', data.ms_axes);
  recordPhaseTime('scene', data.ms_scene);
  recordPhaseTime('flatten', data.ms_flatten);
  // Scene phase broken out by kind of object each millisecond went to, with.
  //   counts kept beside them. Counts are latest rather than ringed: median count would
  //   lag deletion by two seconds and read as scene that still holds what it no longer
  //   does, while *time* wants its median precisely because single frame flickers.
  recordPhaseTime('points', data.ms_points);
  recordPhaseTime('lines', data.ms_lines);
  recordPhaseTime('planes', data.ms_planes);
  recordPhaseTime('sky', data.ms_sky);
  recordPhaseTime('ghost', data.ms_ghost);
  recordPhaseTime('selected', data.ms_selected);
  for (const name in COUNTS_DIAGNOSTIC) {
    const field = COUNTS_DIAGNOSTIC[name];
    if (field === undefined) continue;
    count_phase[name] = data[field] as number;
  }
  count_points_culled = data.count_points_culled;

  // **Every frame is drawn, still or moving.** Held frame could skip clear and draws.
  //   and leave compositor showing last presentation, and did for one round: on
  //   device it changed spikes not at all, and reader would rather still and moving
  //   frames behave alike than have still ones cheap. Records are still held above;
  //   that changes nothing about what is drawn or when.
  const ms_before_draw = performance.now();
  const ratio_pixel = ratioPixel();
  gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

  // Ribbon program's camera, once frame:
  //   widening runs in its vertex shader now, fed by exactly DrawScale fields mesh.expandRibbon
  //   reads.
  gl.useProgram(program_ribbon);
  gl.uniformMatrix4fv(ribbon_uniforms.mvp, false, data.view_projection);
  gl.uniform3f(ribbon_uniforms.eye, data.camera_eye_x, data.camera_eye_y, data.camera_eye_z);
  gl.uniform3f(ribbon_uniforms.forward,
    data.camera_forward_x, data.camera_forward_y, data.camera_forward_z);
  gl.uniform1f(ribbon_uniforms.depth_near, data.camera_depth_near);
  gl.uniform1f(ribbon_uniforms.tangent, data.camera_tangent_half_view);
  gl.uniform1f(ribbon_uniforms.height, data.camera_height_pixels);
  // Furniture fog's two radii, for fragment stage's fade of fogged records.
  gl.uniform1f(ribbon_uniforms.fog_full, data.fog_radius_full);
  gl.uniform1f(ribbon_uniforms.fog_gone, data.fog_radius_gone);

  // World furniture first, with normal depth test/write.
  //   One record segment now -- kept rather than re-uploaded where bridge says furniture is
  //   unchanged, since grid and axes are function of camera alone.
  //   Mirrors renderer.nim's own drawMeshes(MESHES_FURNITURE, ...) call exactly.
  if (!data.is_furniture_held) {
    count_furniture_held = uploadBuffer(data.furn_ribbon_verts, vbo.ribbon_furniture, 16);
  }
  drawRibbons(vbo.ribbon_furniture, count_furniture_held, 0, false);

  // Draw scene objects last, opaque kinds before translucent washes.
  //   Depth writes off for washes, so translucent plane never occludes line or point
  //   that happens to sit behind it; it only tints over whatever was already drawn
  //   there.
  //   Mirrors renderer.nim's own drawMeshes(MESHES, ...) call exactly.
  // Upload only where bridge rebuilt.
  //   Held frame's buffers already hold this frame's records, and re-uploading
  //   identical bytes is copy hold exists to skip.
  //   Draws below still run; framebuffer is cleared every frame.
  if (!data.is_scene_held) count_ribbon_held = uploadBuffer(data.ribbon_verts, vbo.ribbon, 16);
  const count_ribbon = count_ribbon_held;
  drawRibbons(vbo.ribbon, count_ribbon, data.ribbon_over, false);
  // Draw plane rims, one record each, straight after lines they are drawn like.
  //   Widening is ribbon program's own, so this program takes same six camera uniforms
  //   and same pass.
  gl.useProgram(program_ring);
  gl.uniformMatrix4fv(ring_uniforms.mvp, false, data.view_projection);
  gl.uniform3f(ring_uniforms.eye, data.camera_eye_x, data.camera_eye_y, data.camera_eye_z);
  gl.uniform3f(ring_uniforms.forward,
    data.camera_forward_x, data.camera_forward_y, data.camera_forward_z);
  gl.uniform1f(ring_uniforms.depth_near, data.camera_depth_near);
  gl.uniform1f(ring_uniforms.tangent, data.camera_tangent_half_view);
  gl.uniform1f(ring_uniforms.height, data.camera_height_pixels);
  if (!data.is_scene_held) count_ring_held = uploadBuffer(data.ring_records, vbo.ring, 14);
  const count_ring = count_ring_held;
  drawRings(count_ring, data.ring_over, false);
  // Point program's camera, once per frame, with both screen axes disc spans.
  //   Least diameter scaled by device pixel ratio, since `uHeightPixels` is framebuffer's.
  gl.useProgram(program);
  gl.uniformMatrix4fv(point_uniforms.mvp, false, data.view_projection);
  gl.uniform3f(point_uniforms.eye, data.camera_eye_x, data.camera_eye_y, data.camera_eye_z);
  gl.uniform3f(point_uniforms.forward,
    data.camera_forward_x, data.camera_forward_y, data.camera_forward_z);
  gl.uniform3f(point_uniforms.right,
    data.camera_right_x, data.camera_right_y, data.camera_right_z);
  gl.uniform3f(point_uniforms.up, data.camera_up_x, data.camera_up_y, data.camera_up_z);
  gl.uniform1f(point_uniforms.depth_near, data.camera_depth_near);
  gl.uniform1f(point_uniforms.tangent, data.camera_tangent_half_view);
  gl.uniform1f(point_uniforms.height, data.camera_height_pixels);
  gl.uniform1f(point_uniforms.diameter_least, DIAMETER_POINT_LEAST * ratio_pixel);
  gl.uniform1f(point_uniforms.ambient, AMBIENT_SHADE);
  if (!data.is_scene_held) count_point_held = uploadBuffer(data.point_verts, vbo.point, 11);
  const count_point = count_point_held;
  drawPoints(count_point, data.point_over, false);
  // Washes:
  //   one record disc or dome, fanned out by their own vertex shaders and walked in scene order
  //   through run list.
  //   Both programs get this frame's matrix before walk, which switches between them per run.
  gl.useProgram(program_disc);
  gl.uniformMatrix4fv(uniform_disc_mvp, false, data.view_projection);
  gl.useProgram(program_dome);
  gl.uniformMatrix4fv(uniform_dome_mvp, false, data.view_projection);
  if (!data.is_scene_held) {
    uploadBuffer(data.disc_records, vbo.disc, 13);
    uploadBuffer(data.dome_records, vbo.dome, 8);
  }
  gl.depthMask(false);
  drawWashRuns(data.wash_runs, data.wash_run_over, false);
  gl.depthMask(true);

  // Draw overlay over all of it, against depth buffer cleared first.
  //   Cleared rather than test turned off: nothing unselected is left to reject against,
  //   so selected object still shows through whatever stands before it, and selected
  //   objects reject one another by depth exactly as main pass does. With test off,
  //   emission order decided among them, and selected planet drawn after its moon
  //   buried moon standing in front of it.
  //   Second pass over every kind rather than tail on each: selected line drawn only
  //   after other lines is still tinted by plane's wash, which is later kind.
  //   Washes write no depth here either, as in main pass.
  //   Mirrors `renderer.drawMeshes`.
  if (data.ribbon_over + data.ring_over + data.point_over + data.wash_run_over > 0) {
    gl.clear(gl.DEPTH_BUFFER_BIT);
    gl.useProgram(program_ribbon);
    drawRibbons(vbo.ribbon, count_ribbon, data.ribbon_over, true);
    gl.useProgram(program_ring);
    drawRings(count_ring, data.ring_over, true);
    gl.useProgram(program);
    drawPoints(count_point, data.point_over, true);
    gl.depthMask(false);
    drawWashRuns(data.wash_runs, data.wash_run_over, true);
    gl.depthMask(true);
  }
  // Command submission only:
  //   GL runs asynchronously, so what CPU clock can honestly bracket here is upload and draw-call
  //   issue, not GPU's own work.
  recordPhaseTime('upload', performance.now() - ms_before_draw);
}

function frame() {
  const now_seconds = now();

  const now_milliseconds = performance.now();
  const seconds_frame = (now_milliseconds - time_frame_last) / 1000;
  recordFrameTime(now_milliseconds - time_frame_last);
  time_frame_last = now_milliseconds;

  // Move camera by one frame's worth of whatever key is held, before drawing.
  //   Scaled by frame's own elapsed time, so hold travels same distance on 60 Hz screen
  //   and 144 Hz one.
  //   Which way it moves camera is `interaction.driveHeld`'s to say, never this file's.
  nimDriveHeld(seconds_frame);
  settleTwoFingers();

  // Press that has now lasted long enough selects its item. Checked here rather than by.
  //   timer that fires on its own, so that moment marker finishes filling is
  //   moment selection lands -- `interaction.isHoldMature` is stated against same
  //   progress marker was just drawn at, so two cannot disagree by frame.
  // One question, not two.
  //   Asking "is it mature" beside flag kept here for "have I already acted on that" needs two to
  //   agree, and they stopped agreeing once hold outlived its own release:
  //   this handler clears its flag on lift while hold is still settling and still mature, so next
  //   frame selected item again and toggled it straight back off.
  //   `nimTakeMaturedHold` answers once and never again.
  const handle_matured = nimTakeMaturedHold(now_seconds);
  if (handle_matured >= 0) {
    // Selected, but hold is **kept**:
    //   its marker stays swollen clear of finger for as long as that finger is down, and settles
    //   only once `nimReleaseHold` says it may.
    has_long_press_fired = true; // Still needed, to stop release also reading as tap.
    pickByPointer(handle_matured);
    toggleSelection(handle_matured, position_touch_down);
  }
  // And retire it once that settle is spent, so finished hold stops being drawn at all.
  if (nimIsHoldSpent(now_seconds)) nimCancelHold();

  // Recompute what drag in progress would build, and whether its dwell has come due.
  //   Before frame that ghosts answer is assembled.
  //   Runs every frame rather than on pointermove alone: dwell is time passing over
  //   cursor that is deliberately still, so there is no move event to hang it off.
  //   Mirrors `visualiser.renderFrame`'s order.
  // Take one dolly and one pick per frame, whatever pointer reported.
  //   Device reporting faster than display would otherwise pay for answers nobody read:
  //   `picking.pickNearest` walks every live handle.
  //   Coalesced here, after `nimDriveHeld` so camera is where this frame will draw it,
  //   and before drag update and build so both read answer this frame's cursor
  //   deserves.
  //   Presses do not come through here.
  //     `pointerdown`, touch-down and `handleTap` each need hover reading before their
  //     own handler returns, since `nimBeginDrag`, `handle_touch_down` and selection are
  //     decided from it, so they pick on spot and are only paths that still do.
  if (deltas_wheel !== 0) {
    nimCameraDollyAt(
      Math.exp(deltas_wheel * 0.0012), canvas.clientWidth, canvas.clientHeight,
    );
    deltas_wheel = 0;
    is_hover_stale = true; // Camera moved under cursor that did not.
  }
  if (is_hover_stale) {
    is_hover_stale = false;
    nimUpdateHover(canvas.clientWidth, canvas.clientHeight);
  }

  if (nimDragActive()) nimUpdateDrag(now_seconds);

  renderFrame(now_seconds);

  // Immediately after last draw call and before this callback yields, which is only.
  //   moment drawing buffer is still there to read; see `captureFrameIfAsked`.
  captureFrameIfAsked();

  const ms_before_overlay = performance.now();
  if (is_overlay_shown) refreshOverlay(cursor_last);
  updateSelectionMenuPosition();
  // Menu placement folded in with markers rather than kept as row of its own: it is.
  //   one early-returning call reading 0.00 in every state but one, and its old bracket
  //   enclosed overlay's own `recordPhaseTime` -- so that row had been charging its
  //   bookkeeping to itself.
  recordPhaseTime('overlay', performance.now() - ms_before_overlay);

  // Refresh UI (camera fields, diagnostics) at lower cadence than draw loop.
  //   No visual harm in number lagging frame, and it keeps DOM writes off hot path.
  //   Paced by clock rather than by frame count, so readings settle over same window
  //   they are averaged over however fast or slow machine is drawing.
  //     Fixed frame count is fraction of second on desktop and much longer on
  //     labouring phone, and digits would change at whichever of those reader happened
  //     to be on.
  // Redraw travelling axis at frame's own rate.
  //   Panel refreshes few times second, which would show glide as steps rather than
  //   movement.
  //   Only while it travels, and only while curve is actually on screen. On frame
  //   rather than in idle time, since it is animation; charged to `ui` like rest.
  if (is_axis_gliding && isDiagnosticsShown()) {
    const ms_before_glide = performance.now();
    drawExceedance();
    addPhaseTime('ui', performance.now() - ms_before_glide);
  }
  const ms_now_ui = performance.now();
  // One reading for every kind of UI work this frame did, through `addPhaseTime`:
  //   glide redraw above, tick here and slow pass in idle time after all land in same
  //   handle. Row build runs every frame while it has rows left; rest runs on its own
  //   five-a-second cadence; frame doing neither leaves handle unwritten.
  const is_ticking_ui = ms_now_ui - ms_refresh_ui >= MILLISECONDS_WINDOW_READING;
  if (is_ticking_ui || rows_pending !== null) {
    const ms_before_ui = performance.now();
    sliceObjectRows();
    if (is_ticking_ui) {
      ms_refresh_ui = ms_now_ui;
      refreshCameraFields();
      refreshRuler();
      refreshDiagnostics();
      refreshUndoRedoButtons(); // catches every history-touching path this tick's own
        // click handlers above don't reach directly (add, apply, remove, load demo,
        // scene load/clear).
      syncOperandsToSelection(); // catches selection changes from tap-to-select too.
      refreshAddButton(); // catches paths that fill or empty scene without click.
    }
    addPhaseTime('ui', performance.now() - ms_before_ui);
  }

  // Time browser's rendering of this frame; see `markRendered`.
  if (!is_render_pending && isDiagnosticsShown()) {
    is_render_pending = true;
    at_render = index_history_frame;
    ms_render_posted = performance.now();
    channel_render.port2.postMessage(0);
  }

  requestAnimationFrame(frame);
}

refreshObjectsUI();
refreshUndoRedoButtons();
requestAnimationFrame(frame);
