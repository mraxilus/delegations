// Pins for every repaired performance fault; not Nim because crossing forfeits check compiler
//   makes over bodies timing bridge calls by name -- `nimUpdateHover`, `nimAnchorScreen`,
//   `nimSelectionMarker` -- each checked against signature `declare` derived.
//   Speed checks, and only kind that reads real clock. Each bound is 1.5 times slowest reading
//   delegate container gave, rounded up: runner and delegate meet it, and fault it pins, every
//   one large multiplier while it was alive, does not. Readings each bound is set from, and
//   reading of fault it pins, live in PROVENANCE.md.
//   Raising bound is sign-off: bound is changed only with justification recorded beside readings
//   it is set from, never adjusted to quiet failure unexamined. Failure just past bound on slow
//   run says re-measure against previous commit first; failure at multiples of it is fault
//   this exists for.
//   Figure is median of batches, frame apart, wherever one call is too short to time alone:
//   single mean of few hundred calls moves with one collection or one preemption.

import type { Page } from '@playwright/test';
import { MILLISECONDS_FRAME, evaluateOver } from './clock';
import { settleCamera } from './camera';
import { waitFrames } from './frame';
import { pickPlane } from './ground';
import { report, reportWithin } from './report';
import { pixelOf } from './wheel';

/** Ceiling each repaired fault is pinned under: 1.5 times slowest delegate reading.
 *
 *  Readings each is set from, and reading of fault it pins, are in `PROVENANCE.md`.
 */
export const MILLISECONDS_PICK_HOVER = 2.6; // Fault: scene copied for each handle.
export const MILLISECONDS_PICK_HOVER_LOADED = 7.2; // Same pick, at 5,038 objects.
const MICROSECONDS_ANCHOR = 15; // Fault: extent tuple and object copied for each lookup.
const MILLISECONDS_MARKER_PAIR = 1.1; // Fault: outline summed sample by sample.
const MILLISECONDS_GRID_MOVING = 26; // Fault: fade sampled at each boundary.
const MILLISECONDS_EMITTING_MOVING = 2; // Fault: ribbon expanded on CPU.

/** Batches each pin times, frame apart; odd, so median is one batch's figure. */
const BATCHES_ANCHOR = 15;
const BATCHES_MARKER = 9;

/** Calls in one timed batch: enough to span many ticks of page's coarsened clock. */
const CALLS_ANCHOR = 200;
const PAIRS_MARKER = 5;

/** Time hover pick, which must stay off copy paths.
 *
 *  It walks scene by handle, never through pairs whose object carries whole scene by value on
 *  this backend, and steps horizon circle off fixed angle table. It runs on every pointer
 *  move, which is why no frame row ever showed it.
 */
export async function drivePinPick(page: Page): Promise<void> {
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
  reportWithin(
    'a hover pick stays off the scene-copy paths', median, 0, MILLISECONDS_PICK_HOVER,
    'ms median',
  );
}

/** Time anchor lookup, which must stay projection rather than copy.
 *
 *  Overlay view cache hands out no extent-and-matrix value pair, and object is read by handle.
 *  Warm batch first and untimed: first batch on page read dearest of all, every time.
 */
export async function drivePinAnchor(page: Page): Promise<void> {
  const median = await page.evaluate(async (given) => {
    const canvas = document.getElementById('gl') as HTMLCanvasElement;
    const handle = nimSceneHandles()[0] ?? 0;
    const meanOf = (calls: number): number => {
      const started = performance.now();
      for (let i = 0; i < calls; i += 1) {
        nimAnchorScreen(handle, canvas.clientWidth, canvas.clientHeight);
      }
      return (1000 * (performance.now() - started)) / calls;
    };
    meanOf(given.calls);
    const means: number[] = [];
    for (let batch = 0; batch < given.batches; batch += 1) {
      await new Promise((done) => requestAnimationFrame(done));
      means.push(meanOf(given.calls));
    }
    means.sort((a, b) => a - b);
    return means[Math.floor(means.length / 2)] ?? -1;
  }, { batches: BATCHES_ANCHOR, calls: CALLS_ANCHOR });
  reportWithin(
    'an anchor lookup stays a projection, not a copy', median, 0, MICROSECONDS_ANCHOR,
    'us, median of batch means',
  );
}

/** Time marker and its pulse, which must shape into caller storage.
 *
 *  Worst live kind, never first handle: point's marker is ring of four floats and line's or
 *  plane's is sampled outline order of magnitude dearer, so pin that happened to time point
 *  would pass while selected plane cost multiples of it -- which is exactly how this cost
 *  stayed hidden until it was decomposed.
 */
export async function drivePinMarker(page: Page): Promise<void> {
  const worst = await page.evaluate(async (given) => {
    const canvas = document.getElementById('gl') as HTMLCanvasElement;
    const meanOf = (handle: number): number => {
      const started = performance.now();
      for (let i = 0; i < given.pairs; i += 1) {
        nimSelectionMarker(handle, canvas.clientWidth, canvas.clientHeight, 1, false, 0);
        nimSelectionPulse(handle, canvas.clientWidth, canvas.clientHeight, 1, false, 0);
      }
      return (performance.now() - started) / given.pairs;
    };
    let worst_at = { milliseconds: 0, word: 'none' };
    for (const handle of nimSceneHandles()) {
      const means: number[] = [];
      for (let batch = 0; batch < given.batches; batch += 1) {
        await new Promise((done) => requestAnimationFrame(done));
        means.push(meanOf(handle));
      }
      means.sort((a, b) => a - b);
      const milliseconds = means[Math.floor(means.length / 2)] ?? 0;
      if (milliseconds > worst_at.milliseconds) {
        worst_at = { milliseconds, word: nimObjectKindWord(handle) };
      }
    }
    return worst_at;
  }, { batches: BATCHES_MARKER, pairs: PAIRS_MARKER });
  reportWithin(
    `a marker and its pulse shape without copying (worst: ${worst.word})`,
    worst.milliseconds, 0, MILLISECONDS_MARKER_PAIR, 'ms, median of batch means',
  );
}

/** Time moving grid and CPU emit, which must stay at one record per line.
 *
 *  Moving-camera rebuild is frame this repository has spent most rounds on, and its cost is
 *  line count and nothing else now, fog fade having moved into fragment shader.
 */
export async function drivePinGrid(page: Page): Promise<void> {
  // Lattice lies on plane picked, so one is picked: world rules no ground of its own.
  await pickPlane(page);
  const pinned = await page.evaluate(() => {
    const canvas = document.getElementById('gl') as HTMLCanvasElement;
    const aspect = canvas.width / canvas.height;
    const distance_before = nimCameraDistance();
    nimSetCameraDistance(300);
    const grid: number[] = [], emitting: number[] = [];
    for (let i = 0; i < 9; i += 1) {
      // Turned outright, not by drag's rule: this wants view moved, and that rule
      //   looks rather than orbits wherever nothing is picked.
      nimCameraOrbit(0.005, 0);
      const data = nimBuildFrame(
        aspect, performance.now() / 1000, canvas.height, true, true, false,
      );
      grid.push(data.ms_grid);
      emitting.push(data.ms_emitting);
    }
    nimSetCameraDistance(distance_before);
    nimSelectClear();
    grid.sort((a, b) => a - b);
    emitting.sort((a, b) => a - b);
    return { grid: grid[4] ?? -1, emitting: emitting[4] ?? -1 };
  });
  reportWithin(
    'the moving grid stays at one record per line', pinned.grid, 0,
    MILLISECONDS_GRID_MOVING, 'ms median',
  );
  reportWithin(
    'the CPU emit stays a copy of records, not an expansion', pinned.emitting, 0,
    MILLISECONDS_EMITTING_MOVING, 'ms median',
  );
}

/** Assert overlay reuses its own elements rather than rebuilding layer.
 *
 *  Mark nodes standing now, let draw loop run, and same nodes must still be there: layer
 *  cleared wholesale creates fresh nodes every frame and keeps none.
 */
export async function drivePinPool(page: Page): Promise<void> {
  // Earlier checks left camera wherever they orbited it; hover below needs anchor on screen.
  await page.keyboard.press('Home');
  await settleCamera(page);
  const handle = await page.evaluate(() => nimSceneHandles()[0] ?? 0);
  const pixel = await pixelOf(page, handle);
  if (pixel === null) {
    report('the first object stands on screen to hover', false, 'no pixel');
    return;
  }
  await page.mouse.move(pixel[0] ?? 0, pixel[1] ?? 0);
  await waitFrames(page, 2);

  const pooled = await evaluateOver(page, 150 + 2 * MILLISECONDS_FRAME, async () => {
    const layer = document.getElementById('overlay');
    if (layer === null) return { before: 0, after: 0, kept: 0 };
    const marked = (element: Element): { __probe_pool?: boolean } =>
      element as unknown as { __probe_pool?: boolean };
    const before = layer.children.length;
    for (const element of layer.children) marked(element).__probe_pool = true;
    await new Promise((done) => setTimeout(done, 150));
    let kept = 0;
    for (const element of layer.children) if (marked(element).__probe_pool === true) kept += 1;
    return { before, after: layer.children.length, kept };
  });
  report(
    'the overlay reuses its elements across frames rather than rebuilding',
    pooled.before > 0 && pooled.kept > 0,
    `${pooled.kept} of ${pooled.after} elements survived from ${pooled.before} ` +
      'marked a few frames earlier',
  );
}
