// Pins for every repaired performance fault; not Nim because crossing forfeits check compiler
//   makes over bodies timing bridge calls by name -- `nimUpdateHover`, `nimAnchorScreen`,
//   `nimSelectionMarker` -- each checked against signature `declare` derived.
//   Bands are generous enough to survive loaded shared runner, tight enough to catch fault
//   class returning, since every fault below was large multiplier while it was alive.
//   Faults themselves, their causes and their measurements live in PROVENANCE.md.
//   Raising band is sign-off: band is changed only with justification recorded beside ledger
//   entry it pins, never adjusted to quiet failure unexamined. Failure just past band on slow
//   run says re-measure against previous commit first; failure at multiples of it is fault
//   this exists for.

import type { Page } from '@playwright/test';
import { report, reportWithin } from './report';
import { pixelOf } from './wheel';

/** Ceiling each repaired fault is pinned under, with cost it was repaired to. */
export const MILLISECONDS_PICK_HOVER = 5; // Repaired 1.5 ms; scene-copy-per-handle fault was 7.1.
const MICROSECONDS_ANCHOR = 100; // Repaired 8 us; extent-tuple and object-copy fault was 280.
const MILLISECONDS_MARKER_PAIR = 4; // Worst live kind; repaired ~1.2 ms, per-sample sums ~3.2.
const MILLISECONDS_GRID_MOVING = 20; // Repaired 8.7 ms; per-boundary fade sampling was 26.1.
const MILLISECONDS_EMITTING_MOVING = 4.5; // Repaired ~1.2 ms; CPU ribbon expansion was 6.3.

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
 */
export async function drivePinAnchor(page: Page): Promise<void> {
  const mean = await page.evaluate(() => {
    const canvas = document.getElementById('gl') as HTMLCanvasElement;
    const handle = nimSceneHandles()[0] ?? 0;
    const started = performance.now();
    for (let i = 0; i < 400; i += 1) {
      nimAnchorScreen(handle, canvas.clientWidth, canvas.clientHeight);
    }
    return (1000 * (performance.now() - started)) / 400;
  });
  reportWithin(
    'an anchor lookup stays a projection, not a copy', mean, 0, MICROSECONDS_ANCHOR, 'us mean',
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
  const worst = await page.evaluate(() => {
    const canvas = document.getElementById('gl') as HTMLCanvasElement;
    let worst_at = { milliseconds: 0, word: 'none' };
    for (const handle of nimSceneHandles()) {
      const started = performance.now();
      for (let i = 0; i < 30; i += 1) {
        nimSelectionMarker(handle, canvas.clientWidth, canvas.clientHeight, 1, false, 0);
        nimSelectionPulse(handle, canvas.clientWidth, canvas.clientHeight, 1, false);
      }
      const milliseconds = (performance.now() - started) / 30;
      if (milliseconds > worst_at.milliseconds) {
        worst_at = { milliseconds, word: nimObjectKindWord(handle) };
      }
    }
    return worst_at;
  });
  reportWithin(
    `a marker and its pulse shape without copying (worst: ${worst.word})`,
    worst.milliseconds, 0, MILLISECONDS_MARKER_PAIR, 'ms mean',
  );
}

/** Time moving grid and CPU emit, which must stay at one record per line.
 *
 *  Moving-camera rebuild is frame this repository has spent most rounds on, and its cost is
 *  line count and nothing else now, fog fade having moved into fragment shader.
 */
export async function drivePinGrid(page: Page): Promise<void> {
  const pinned = await page.evaluate(() => {
    const canvas = document.getElementById('gl') as HTMLCanvasElement;
    const aspect = canvas.width / canvas.height;
    const distance_before = nimCameraDistance();
    nimSetCameraDistance(300);
    const grid: number[] = [], emitting: number[] = [];
    for (let i = 0; i < 9; i += 1) {
      nimCameraOrbit(0.005, 0); // Move, so furniture cache cannot hold.
      const data = nimBuildFrame(aspect, performance.now() / 1000, canvas.height, true, true);
      grid.push(data.ms_grid);
      emitting.push(data.ms_emitting);
    }
    nimSetCameraDistance(distance_before);
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
  await page.waitForTimeout(800);
  const handle = await page.evaluate(() => nimSceneHandles()[0] ?? 0);
  const pixel = await pixelOf(page, handle);
  if (pixel === null) {
    report('the first object stands on screen to hover', false, 'no pixel');
    return;
  }
  await page.mouse.move(pixel[0] ?? 0, pixel[1] ?? 0);
  await page.waitForTimeout(250);

  const pooled = await page.evaluate(async () => {
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
