// Checks for what build costs under largest demo; not Nim because crossing forfeits check
//   compiler makes over bodies naming bridge's derived exports and page's own scope; glue
//   would leave every one of them source string nothing reads.
//   Bound that only ever runs at default size cannot see regression that shows under load, so
//   these reload at largest and measure there. Each speed bound is 1.5 times slowest delegate
//   reading, and far below fault it catches; see `pins`.

import type { Page } from '@playwright/test';
import { advance, waitUntil } from './clock';
import { settleCamera } from './camera';
import { FRAMES_PHASES_HEAVY_LEAST, readPhases, waitFrames } from './frame';
import { report } from './report';
import { MISSES_ACCOUNT_MAX } from './scenery';

/** Bounds on edits at largest demo, 1.5 times slowest delegate reading; see `pins`.
 *
 *  Readings each is set from are in `PROVENANCE.md`.
 */
const MILLISECONDS_EDIT_TIMELINE = 9.6;
const MILLISECONDS_FRAME_PLACING = 15;

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
    each < MILLISECONDS_EDIT_TIMELINE,
    `${each.toFixed(1)} ms an edit over ${objects} objects, wanted under ` +
      `${MILLISECONDS_EDIT_TIMELINE}`,
  );
}

/** Assert frame after edit is built inside its bound, placing every object as any frame does.
 *
 *  Every frame places whole scene through algebra; see `PROVENANCE.md`, Render paths. So frame
 *  after edit costs what any frame costs, and bound is that frame's: placing, scenery, scene
 *  and flatten at this size. Slip into work per object that grows with scene shows here.
 */
export async function drivePlacingCost(page: Page, objects: number): Promise<void> {
  const median = await page.evaluate(() => {
    const canvas = document.getElementById('gl') as HTMLCanvasElement;
    const aspect = canvas.width / canvas.height;
    const model = nimObjectCoefficients(nimSceneHandles()[0] ?? 0);
    const times: number[] = [];
    for (let i = 0; i < 6; i += 1) {
      const handle = nimAddObject(
        model, 'placed', nimDefaultInk(), nimDefaultRadius(), performance.now() / 1000,
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
    'the frame after an edit places every object inside its bound',
    median >= 0 && median < MILLISECONDS_FRAME_PLACING,
    `${median.toFixed(1)} ms over ${objects} objects, wanted under ${MILLISECONDS_FRAME_PLACING}`,
  );
}

/** Assert undo is drawn by frame after it.
 *
 *  Restored snapshot carried its own revision once, and bump after it landed on revision of
 *  very edit being undone; anything keyed on revision then read undone scene as unchanged.
 *  Frame after undo must draw scene undo restored.
 */
export async function driveUndoDrawn(page: Page): Promise<void> {
  const undone = await page.evaluate(() => {
    const canvas = document.getElementById('gl') as HTMLCanvasElement;
    const aspect = canvas.width / canvas.height;
    const vertices = (): number =>
      nimBuildFrame(aspect, performance.now() / 1000, canvas.height, true, true, true)
        .point_vertices.length / 8;

    const model = nimObjectCoefficients(nimSceneHandles()[0] ?? 0);
    const before = vertices();
    nimAddObject(
      model, 'undone', nimDefaultInk(), nimDefaultRadius(), performance.now() / 1000,
    );
    nimSelectClear();
    const added = vertices();
    nimUndo();
    const after = vertices();
    return { before, added, after };
  });
  report(
    'an undo is drawn by the frame after it',
    undone.added > undone.before && undone.after === undone.before,
    `${undone.before} vertices, ${undone.added} after the add, ${undone.after} after the undo`,
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
      nimAddObject(model, 'filler', nimDefaultInk(), nimDefaultRadius(), 0);
    }
    nimSelectClear(); // Each add selects what it added; leave nothing standing behind.
  });
  await waitFrames(page, 2);
}

/** How long arrow key orbits full scene for, in simulated time. */
const MILLISECONDS_ORBIT_FULL = 800;

/** Drive gesture on full scene, then orbit, and assert refusal and records crossing wire.
 *
 *  On simulated clock: refusal and record counts are what gesture and scene decide, so they
 *  are same on every machine. Orbit is there so records are read off frames reader moves
 *  through.
 */
export async function driveFullRefused(page: Page, errors: string[]): Promise<void> {
  await fillScene(page);
  await page.evaluate(() => { window.__phase_frame = []; });
  const capacity = await page.evaluate(() => nimSceneCapacity());
  await page.mouse.move(720, 450);
  await page.mouse.down();
  for (let i = 0; i < 20; i += 1) await page.mouse.move(720 + 8 * i, 450 + 3 * i);
  await page.mouse.up();
  await settleCamera(page);

  await page.evaluate(() => document.getElementById('gl')?.focus());
  await page.keyboard.down('ArrowRight');
  await advance(page, MILLISECONDS_ORBIT_FULL);
  await page.keyboard.up('ArrowRight');
  await waitFrames(page, 2);

  const after_drag = await page.evaluate(() => nimSceneCount());
  report(
    'a construction gesture on a full scene is refused, not crashed through',
    errors.length === 0 && after_drag === capacity,
    `${after_drag} objects after the drag, ${errors.length} page error(s)`,
  );
  await driveRimRecords(page, await readPhases(page));
}


/** How many frames with scene phase big enough to divide accounting is asked over. */
const FRAMES_HEAVY_WANTED = 25;

/** Orbit full scene on real clock, and assert its breakdown still accounts for it.
 *
 *  Breakdown only exists while it is being read, so check that it adds up has to run in that
 *  state: bridge times placing and emitting halves of every object, which at this size is real
 *  share of frame, so it is gathered only where drawer and diagnostics section are both open.
 *  Sampled by count of heavy frames, not by span of time: slow machine takes longer to reach
 *  that count and still reaches it, so sample size is same on every machine.
 */
export async function driveLoadedAccounting(page: Page): Promise<void> {
  await fillScene(page);
  await page.evaluate(() => {
    const section = document.querySelector('.section[data-section="diagnostics"]');
    if (!drawer.classList.contains('open')) document.getElementById('button-drawer')?.click();
    if (!(section?.classList.contains('open') ?? false)) {
      (section?.querySelector('.section-header') as HTMLElement | null)?.click();
    }
  });
  await waitUntil(page, () => {
    const drawer = document.getElementById('drawer');
    const section = document.querySelector('.section[data-section="diagnostics"]');
    return (drawer?.classList.contains('open') ?? false) &&
      (section?.classList.contains('open') ?? false);
  }, null);

  // Window accounting reads starts only now: fill is many committed edits back to back, which
  //   is not ordinary picture this measures.
  await page.evaluate(() => { window.__phase_frame = []; });
  // Orbit, so frames read are frames reader moves through full scene.
  await page.evaluate(() => document.getElementById('gl')?.focus());
  await page.keyboard.down('ArrowRight');
  try {
    await waitUntil(
      page,
      (wanted) => (window.__phase_frame ?? []).filter((one) => one.scene >= 2.0).length >= wanted,
      FRAMES_HEAVY_WANTED,
    );
  } catch {
    // Too few heavy frames is verdict below, which says how many came.
  }
  await page.keyboard.up('ArrowRight');
  await waitFrames(page, 2);

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
    heavy.length > FRAMES_PHASES_HEAVY_LEAST && sane.length >= heavy.length - MISSES_ACCOUNT_MAX,
    `${sane.length} of ${heavy.length} frames over 2 ms account, worst scene phase ` +
      `${Math.max(0, ...heavy.map((one) => one.scene)).toFixed(2)} ms`,
  );
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
