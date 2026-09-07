// Checks for what build costs under largest demo; not Nim because crossing forfeits check
//   compiler makes over bodies naming bridge's derived exports and page's own scope; glue
//   would leave every one of them source string nothing reads.
//   Band that only ever runs at default size cannot see regression that shows under load, so
//   these reload at largest and measure there. Every band is far above what it measures and
//   far below fault it catches, so slow container never decides it.

import type { Page } from '@playwright/test';
import { settleCamera } from './camera';
import { readPhases, waitFrames } from './frame';
import { report } from './report';

/** Share of frames whose kinds must account, as still-scene check uses. */
const SHARE_KINDS_ACCOUNT = 0.995;

/** Assert edit past timeline capacity copies one scene, not whole timeline.
 *
 *  Step is whole scene, so once timeline is full retiring its oldest was one whole-scene copy
 *  per step for one visibility toggle -- dropped frames on edit reader makes without thinking.
 *  It is ring now and costs one scene copy at any depth. Measured *past* capacity on purpose:
 *  under it old shape and new one cost same, so check that edits fresh timeline would pass
 *  either way.
 */
export async function driveTimelineCost(page: Page, objects: number): Promise<void> {
  const each = await page.evaluate(() => {
    const handle = nimSceneHandles()[0] ?? 0;
    const was_visible = nimObjectVisible(handle);
    for (let i = 0; i < 40; i += 1) nimSetVisible(handle, i % 2 === 0); // Fill timeline.
    const started = performance.now();
    for (let i = 0; i < 20; i += 1) nimSetVisible(handle, i % 2 === 0);
    const spent = (performance.now() - started) / 20;
    nimSetVisible(handle, was_visible); // Leave scene as demo built it.
    return spent;
  });
  report(
    'an edit past the timeline capacity copies one scene, not the whole timeline',
    each < 40, `${each.toFixed(1)} ms an edit over ${objects} objects`,
  );
}

/** Assert frame after edit re-places handle it touched, not whole scene.
 *
 *  Placement cache refilled every live handle on any change of revision, so frame after one
 *  add re-ran whole placing side.
 */
export async function drivePlacingCost(page: Page, objects: number): Promise<void> {
  const median = await page.evaluate(() => {
    const canvas = document.getElementById('gl') as HTMLCanvasElement;
    const aspect = canvas.width / canvas.height;
    const model = nimObjectCoefficients(nimSceneHandles()[0] ?? 0);
    const times: number[] = [];
    for (let i = 0; i < 6; i += 1) {
      const handle = nimAddObject(
        model, 'placed', nimDefaultInk(), nimDefaultRadius(), false, performance.now() / 1000,
      );
      const started = performance.now();
      nimBuildFrame(aspect, performance.now() / 1000, canvas.height, true, true, true);
      times.push(performance.now() - started);
      nimRemoveObject(handle);
      nimBuildFrame(aspect, performance.now() / 1000, canvas.height, true, true, true);
    }
    nimSelectClear();
    times.sort((a, b) => a - b);
    return times[3] ?? -1;
  });
  report(
    'the frame after an edit re-places one handle, not every handle',
    median < 15, `${median.toFixed(1)} ms over ${objects} objects`,
  );
}

/** Assert undo made while frame is held is drawn.
 *
 *  Restored snapshot carried its own revision, and bump after it landed on revision of very
 *  edit being undone, so hold kept last frame's meshes: undone object stayed on screen until
 *  camera moved. Hold is engaged first, on purpose -- fault only shows once it has.
 */
export async function driveUndoDrawn(page: Page): Promise<void> {
  const undone = await page.evaluate(async () => {
    const canvas = document.getElementById('gl') as HTMLCanvasElement;
    const aspect = canvas.width / canvas.height;
    const build = (): FrameData =>
      nimBuildFrame(aspect, performance.now() / 1000, canvas.height, true, true, true);
    const sleep = (milliseconds: number): Promise<void> =>
      new Promise((done) => setTimeout(done, milliseconds));
    const stateOf = (data: FrameData): { verts: number; is_held: boolean } =>
      ({ verts: data.point_verts.length / 11, is_held: data.is_scene_held });

    const model = nimObjectCoefficients(nimSceneHandles()[0] ?? 0);
    const before = stateOf(build());
    nimAddObject(
      model, 'undone', nimDefaultInk(), nimDefaultRadius(), false, performance.now() / 1000,
    );
    nimSelectClear();
    let is_held = false;
    for (let i = 0; i < 60 && !is_held; i += 1) {
      await sleep(50);
      is_held = build().is_scene_held;
    }
    const added = stateOf(build());
    nimUndo();
    const after = stateOf(build());
    return { is_held, before, added, after };
  });
  report(
    'an undo made while the frame is held is drawn',
    undone.is_held && undone.added.verts > undone.before.verts &&
      undone.after.verts === undone.before.verts && !undone.after.is_held,
    `held ${undone.is_held}; ${undone.before.verts} verts, ${undone.added.verts} after the ` +
      `add, ${undone.after.verts} after the undo`,
  );
}

/** Assert hover pick over largest demo skips discs it cannot be over.
 *
 *  Each plane was meet through algebra whether or not cursor was anywhere near its disc, which
 *  was half of every pick at this size. Broad phase skips ones it cannot be over; meet still
 *  decides rest.
 */
export async function drivePinPickLoaded(page: Page, ceiling: number): Promise<void> {
  const median = await page.evaluate(() => {
    const canvas = document.getElementById('gl') as HTMLCanvasElement;
    nimUpdateCursor(canvas.clientWidth / 2, canvas.clientHeight / 2);
    const times: number[] = [];
    for (let i = 0; i < 25; i += 1) {
      const started = performance.now();
      nimUpdateHover(canvas.clientWidth, canvas.clientHeight);
      times.push(performance.now() - started);
    }
    times.sort((a, b) => a - b);
    return times[12] ?? -1;
  });
  report(
    'a hover pick over the largest demo skips the discs it cannot be over',
    median >= 0 && median <= ceiling, `${median.toFixed(3)} ms median, wanted 0..${ceiling}`,
  );
}

/** Fill every free handle, so gesture below meets full scene.
 *
 *  Preset fills its target and leaves rest of pool free on purpose, so reader can build on top
 *  of loaded demo -- which means gesture would legitimately succeed and refusal check would
 *  silently check nothing. Copying point demo already placed, rather than composing one here,
 *  because what is under test is gesture's own guard.
 */
async function fillScene(page: Page): Promise<void> {
  await page.evaluate(() => {
    const model = nimObjectCoefficients(nimSceneHandles()[0] ?? 0);
    while (nimSceneCount() < nimSceneCapacity()) {
      nimAddObject(model, 'filler', nimDefaultInk(), nimDefaultRadius(), false, 0);
    }
    nimSelectClear(); // Each add selects what it added; leave nothing standing behind.
  });
  await waitFrames(page, 2);
}

/** Drive gesture on full scene, then orbit, and assert refusal and accounting under load.
 *
 *  Breakdown only exists while it is being read, so check that it adds up has to run in that
 *  state: bridge times placing and emitting halves of every object, which at this size is real
 *  share of frame, so it is gathered only where drawer and diagnostics section are both open.
 */
export async function driveLoadedAccounting(page: Page, errors: string[]): Promise<void> {
  await fillScene(page);
  await page.evaluate(() => {
    const section = document.querySelector('.section[data-section="diagnostics"]');
    if (!drawer.classList.contains('open')) document.getElementById('button-drawer')?.click();
    if (!(section?.classList.contains('open') ?? false)) {
      (section?.querySelector('.section-header') as HTMLElement | null)?.click();
    }
  });
  await page.waitForFunction(() => {
    const drawer = document.getElementById('drawer');
    const section = document.querySelector('.section[data-section="diagnostics"]');
    return (drawer?.classList.contains('open') ?? false) &&
      (section?.classList.contains('open') ?? false);
  }, null, { timeout: 8000, polling: 'raf' });

  // Window accounting reads starts only now: fill is many committed edits back to back, which
  //   is not ordinary picture this measures.
  await page.evaluate(() => { window.__phase_frame = []; });
  const capacity = await page.evaluate(() => nimSceneCapacity());
  await page.mouse.move(720, 450);
  await page.mouse.down();
  for (let i = 0; i < 20; i += 1) await page.mouse.move(720 + 8 * i, 450 + 3 * i);
  await page.mouse.up();
  await settleCamera(page);

  // Then orbit, because still camera over still scene is now held frame: hold skips
  //   tessellation, flatten and uploads together where nothing has moved, so idle window
  //   records frames whose scene phase is legitimately zero and there is nothing to divide.
  //   What this is about is cost of drawing while view moves, which is case reader waits on.
  //   Orbited until sample is big enough, not for fixed time: fixed window kept finding fewer
  //   heavy frames as thing it guards got faster, which is sample size, not accounting.
  await page.evaluate(() => document.getElementById('gl')?.focus());
  await page.keyboard.down('ArrowRight');
  let heavy_seen = 0;
  for (let round = 0; round < 40 && heavy_seen < 25; round += 1) {
    // Wall time, deliberately: each round is sampling window, and loop ends on sample size
    //   rather than on clock.
    await page.waitForTimeout(400);
    heavy_seen = (await readPhases(page)).filter((one) => one.scene >= 2.0).length;
  }
  await page.keyboard.up('ArrowRight');
  await waitFrames(page, 2);

  const after_drag = await page.evaluate(() => nimSceneCount());
  report(
    'a construction gesture on a full scene is refused, not crashed through',
    errors.length === 0 && after_drag === capacity,
    `${after_drag} objects after the drag, ${errors.length} page error(s)`,
  );

  // Same accounting as still scene, asked where numbers mean something: on fast container
  //   opening scene's whole phase is under millisecond and every reading is quantised, so
  //   lower bound is inert there. Under demo phase is order of magnitude larger.
  const phases = await readPhases(page);
  const heavy = phases.map((one) => ({
    scene: one.scene,
    parts: one.points + one.lines + one.planes + one.sky + one.preview + one.selected,
  })).filter((one) => one.scene >= 2.0);
  const sane = heavy.filter((one) =>
    one.parts <= one.scene + 0.6 && one.parts >= one.scene - Math.max(3.0, 0.3 * one.scene));
  report(
    'and under it the same accounting still holds, on a phase big enough to divide',
    heavy.length > 20 && sane.length >= SHARE_KINDS_ACCOUNT * heavy.length,
    `${sane.length} of ${heavy.length} frames over 2 ms account, worst scene phase ` +
      `${Math.max(0, ...heavy.map((one) => one.scene)).toFixed(2)} ms`,
  );
  await driveRimRecords(page, phases);
}

/** Assert plane's rim crosses wire as one ring record, not many ribbons.
 *
 *  Rim used to arrive as one ribbon record per segment: on scene of this many planes that was
 *  most of all ribbon traffic and largest single cost in frame. What makes this real pin
 *  rather than restatement is that ceiling is far below old figure -- regression putting rim
 *  back on CPU would blow through it by orders of magnitude. Floor is planes actually loaded,
 *  read from scene rather than written down: with no planes drawn, "few ribbons" is vacuous.
 */
async function driveRimRecords(
  page: Page, phases: Array<{ records_ribbon: number; records_ring: number; records_disc: number }>,
): Promise<void> {
  const planes = await page.evaluate(() => {
    let counted = 0;
    for (const one of nimSceneHandles()) {
      const word = nimObjectKindWord(one);
      if (word === 'plane' || word === 'horizon plane') counted += 1;
    }
    return counted;
  });
  const records = phases.length === 0 ? null : {
    ribbon: Math.max(...phases.map((one) => one.records_ribbon)),
    ring: Math.max(...phases.map((one) => one.records_ring)),
    disc: Math.max(...phases.map((one) => one.records_disc)),
  };
  report(
    'a plane rim crosses the wire as one ring record, not ninety-six ribbons',
    records !== null && records.ribbon <= 64 && records.ring >= planes &&
      records.ring >= records.disc,
    records === null ? 'no frames recorded'
      : `${records.ribbon} ribbon, ${records.ring} ring, ${records.disc} disc records over ` +
        `${planes} planes`,
  );
}
