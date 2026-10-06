// Watch what page's own draw loop costs, and check it fits inside frame; not Nim because
//   crossing forfeits check compiler makes over wrapper standing in front of `nimBuildFrame`,
//   which reads every field of `FrameData` that `declare` derives.
//   Measured here is part page owns, not wall clock: browser cannot draw faster than
//   compositor presents, so "uncapped" is not thing to reach for.
//   Machine running these checks renders through software GL, so its frame times say more
//   about swiftshader than about anything in this repository. Hence bands, not figures.

import type { Page } from '@playwright/test';
import { settleCamera } from './camera';
import { advanceFrames, waitUntil } from './clock';
import { report, reportWithin } from './report';

/** One frame's clocks and counts, as harness's own wrapper caught them. */
export interface Phase {
  build: number;
  place: number;
  furniture: number;
  scene: number;
  flatten: number;
  grid: number;
  axes: number;
  segments: number;
  points: number;
  lines: number;
  planes: number;
  sky: number;
  preview: number;
  selected: number;
  count_points: number;
  count_lines: number;
  count_planes: number;
  count_sky: number;
  count_preview: number;
  count_selected: number;
  records_ribbon: number;
  records_ring: number;
  records_disc: number;
  is_grown: boolean;
  wall: number;
}

declare global {
  interface Window {
    /** How long each frame's build took, in milliseconds, oldest first. */
    __work_frame?: number[];
    /** Each frame's own clocks and counts, alongside `__work_frame`. */
    __phase_frame?: Phase[];
    /** Motors each frame lifted, while counting wrapper stands in front of frame build. */
    __lifts_frame?: number[];
    /** Page's own frame build, held while counting wrapper stands in front of it. */
    __build_unwrapped?: typeof nimBuildFrame;
    /** How many values page copied while counting stood open; see `driveCopiesStill`. */
    __copies_counted?: number;
    /** How many of those reference library's own functions made, counted apart. */
    __copies_library?: number;
    /** Whether copy counter counts now. */
    __is_counting_copies?: boolean;
    /** JS backend's own copy, held while counting wrapper stands in front of it. */
    __copy_unwrapped?: CopyNim;
  }
}

/** Shape of JS backend's deep copy, `nimCopy`: destination, source, type, and copy made. */
type CopyNim = (destination: unknown, source: unknown, type: unknown) => unknown;

/** Stand wrapper in front of page's frame build, collecting what each frame costs.
 *
 *  Installed once and read by every later section: second wrapper over first would charge
 *  each frame twice.
 */
export async function watchFrames(page: Page): Promise<void> {
  await page.evaluate(() => {
    window.__work_frame = [];
    window.__phase_frame = [];
    const scope = globalThis as unknown as { nimBuildFrame: typeof nimBuildFrame };
    const built = scope.nimBuildFrame;
    scope.nimBuildFrame = function (
      ...given: Parameters<typeof nimBuildFrame>
    ): FrameData {
      const started = performance.now();
      const data = built(...given);
      const wall = performance.now() - started;
      window.__work_frame?.push(wall);
      window.__phase_frame?.push({
        build: data.ms_build, place: data.ms_place, furniture: data.ms_furniture,
        scene: data.ms_scene, flatten: data.ms_flatten,
        grid: data.ms_grid, axes: data.ms_axes, segments: data.count_grid_segments,
        points: data.ms_points, lines: data.ms_lines, planes: data.ms_planes,
        sky: data.ms_sky, preview: data.ms_preview, selected: data.ms_selected,
        count_points: data.count_points, count_lines: data.count_lines,
        count_planes: data.count_planes, count_sky: data.count_sky,
        count_preview: data.count_preview, count_selected: data.count_selected,
        // Count what crossed wire, by record kind. Plane's rim is one ring record, and
        //   demo check below is what would notice it silently becoming many ribbons.
        records_ribbon: data.ribbon_vertices.length / 16,
        records_ring: data.ring_records.length / 14,
        records_disc: data.disc_records.length / 13,
        is_grown: data.is_grown, wall,
      });
      return data;
    };
  });
}

/** How long frames took, sorted into figures check can assert against. */
export interface Work {
  n: number;
  median: number;
  p90: number;
  max: number;
}

/** Read frames collected since this index, or since watching began. */
export async function readWork(page: Page, from = 0): Promise<Work | null> {
  return page.evaluate((given) => {
    const sorted = [...(window.__work_frame ?? [])].slice(given).sort((a, b) => a - b);
    if (sorted.length === 0) return null;
    const at = (share: number): number =>
      sorted[Math.min(sorted.length - 1, Math.floor(share * sorted.length))] ?? 0;
    return {
      n: sorted.length, median: at(0.5), p90: at(0.9),
      max: sorted[sorted.length - 1] ?? 0,
    };
  }, from);
}

/** Least frames phase checks read before their verdict counts.
 *
 *  `MISSES_ACCOUNT_MAX` lets two frames miss; under this floor those two are large share, and
 *  sample cannot tell fault from noise. Each check reports frames it read.
 */
export const FRAMES_PHASES_LEAST = 30;

/** Least frames over 2 ms that accounting under demo reads: fewer leave too few to divide. */
export const FRAMES_PHASES_HEAVY_LEAST = 20;

/** Read each frame's clocks, dropping first two, which carry page's own warm-up. */
export async function readPhases(page: Page, from = 2): Promise<Phase[]> {
  return page.evaluate((given) => (window.__phase_frame ?? []).slice(given), from);
}

/** How many frames have been collected, for section timing window of its own. */
export async function countFrames(page: Page): Promise<number> {
  return page.evaluate(() => (window.__work_frame ?? []).length);
}

/** Wait until page has drawn this many more frames.
 *
 *  Gesture paced by frames asks for exactly what it needs, and slow machine takes longer
 *  rather than dropping steps. Simulated page moves its clock that far; see `clock`.
 */
export async function waitFrames(page: Page, frames: number): Promise<void> {
  await advanceFrames(page, frames);
}


/** Wait until panel has run one more reading of its own.
 *
 *  Ruler, camera fields, diagnostics rows and curves are written on tick five times second
 *  rather than every frame, so scene standing as check wants it is not yet panel showing
 *  that. Waits on tick's own clock, so it asserts nothing about any row read afterwards.
 */
export async function settleReading(page: Page): Promise<void> {
  const at = await page.evaluate(() => ms_refresh_ui);
  await waitUntil(page, (given) => ms_refresh_ui > given, at);
}


/** How many frames loop is asked to build, on simulated clock. */
const FRAMES_LOOP = 60;

/** Assert draw loop builds one frame for each frame of time that passes.
 *
 *  On simulated clock, so count is exact: loop that stalled, or built two frames for one,
 *  misses it on every machine alike.
 */
export async function driveLoopRuns(page: Page): Promise<void> {
  const from = await countFrames(page);
  await advanceFrames(page, FRAMES_LOOP);
  const built = (await countFrames(page)) - from;
  report(
    'the draw loop keeps building frames', built === FRAMES_LOOP,
    `${built} of ${FRAMES_LOOP} simulated frames built`,
  );
}


/** Frames each state is counted over; more than one, so steady state is what is read. */
const FRAMES_LIFTS = 3;

/** Assert each frame page builds reads camera's stance once, still and while camera moves.
 *
 *  Eye and frame are each read off stance through camera's motor, so each read lifts motor
 *  again and lifts counted are reads. Counted at page's own frame build, wrapped as
 *  `watchFrames` wraps it, so frames counted are frames page's loop built. Nothing is
 *  selected, so aim reads nothing of its own; drag is real one, from empty sky.
 *  Clears Nim's selection alone, as `driveGround` does, and leaves page's own snapshot of it:
 *  checks after this one read that snapshot.
 *  Count rather than time: count reads same on every machine, and load never moves it.
 */
export async function driveStanceReadOnce(page: Page, width: number): Promise<void> {
  await page.evaluate(() => nimSelectClear());
  await page.keyboard.press('Home');
  await settleCamera(page);
  await page.evaluate(() => {
    const scope = globalThis as unknown as { nimBuildFrame: typeof nimBuildFrame };
    const unwrapped = scope.nimBuildFrame;
    window.__build_unwrapped = unwrapped;
    window.__lifts_frame = [];
    scope.nimBuildFrame = function (
      ...given: Parameters<typeof nimBuildFrame>
    ): FrameData {
      nimSetCountingLifts(true);
      const data = unwrapped(...given);
      window.__lifts_frame?.push(nimCountLifts());
      nimSetCountingLifts(false);
      return data;
    };
  });
  await advanceFrames(page, FRAMES_LIFTS);
  const still = await page.evaluate(() => window.__lifts_frame?.splice(0) ?? []);

  // One frame drawn after each move, so each counted frame follows turn of its own.
  const before = await page.evaluate(() => nimCameraAzimuth());
  await page.mouse.move(width / 2, 60);
  await page.mouse.down();
  for (let i = 1; i <= FRAMES_LIFTS; i += 1) {
    await page.mouse.move(width / 2 + 40 * i, 60, { steps: 2 });
    await advanceFrames(page, 1);
  }
  const moving = await page.evaluate(() => window.__lifts_frame?.splice(0) ?? []);
  await page.mouse.up();
  const after = await page.evaluate(() => nimCameraAzimuth());

  await page.evaluate(() => {
    const scope = globalThis as unknown as { nimBuildFrame: typeof nimBuildFrame };
    if (window.__build_unwrapped !== undefined) scope.nimBuildFrame = window.__build_unwrapped;
  });
  const isOnce = (lifts: number[]): boolean =>
    lifts.length >= FRAMES_LIFTS && lifts.every((one) => one === 1);
  report(
    "a frame reads the camera's stance once, still and while the camera moves",
    isOnce(still) && isOnce(moving) && Math.abs(after - before) > 1e-6,
    `lifts per frame still [${still.join(', ')}], moving [${moving.join(', ')}]; ` +
      `azimuth ${before.toFixed(3)} -> ${after.toFixed(3)}`,
  );
}


/** How many still frames copies are counted over; more than one, so steady state is read. */
const FRAMES_COPIES = 3;

/** Mark of reference library's own functions in compiled names: its directory, as JS backend
 *  mangles it into each function it compiles from there.
 */
const MARK_LIBRARY = 'projective95geometric95algebra95illuminatedZpga';

/** Count values still frames copy, and assert each frame copies fewer than scene has objects.
 *
 *  JS backend deep-copies through `nimCopy`, and copy for each object turns frame linear in
 *  scene for no drawn change. Bound is object count: any such copy reaches it on its own.
 *  Count rather than time: count reads same on every machine, and load never moves it.
 *  Counts outermost call alone, since copy of nested value calls `nimCopy` again for each
 *  member. Every frame places, builds and flattens whole scene, so count is all of frame's.
 *  Copies reference library's own functions make are counted apart and reported, not bound:
 *  every frame runs library for whole scene, and what it costs is library's to answer for;
 *  see `PROVENANCE.md`, Render paths. Copy's maker is function calling it, read off stack.
 */
export async function driveCopiesStill(page: Page, objects: number): Promise<void> {
  const is_wrapped = await page.evaluate((mark) => {
    const scope = globalThis as unknown as { nimCopy?: CopyNim };
    const unwrapped = scope.nimCopy;
    if (typeof unwrapped !== 'function') return false;
    window.__copy_unwrapped = unwrapped;
    window.__copies_counted = 0;
    window.__copies_library = 0;
    window.__is_counting_copies = false;
    let depth = 0;
    scope.nimCopy = function (destination: unknown, source: unknown, type: unknown): unknown {
      if (depth === 0 && window.__is_counting_copies === true) {
        // Line 0 names error, line 1 this wrapper, line 2 function asking for copy.
        const maker = (new Error().stack ?? '').split('\n')[2] ?? '';
        if (maker.includes(mark)) window.__copies_library = (window.__copies_library ?? 0) + 1;
        else window.__copies_counted = (window.__copies_counted ?? 0) + 1;
      }
      depth += 1;
      try {
        return unwrapped(destination, source, type);
      } finally {
        depth -= 1;
      }
    };
    return true;
  }, MARK_LIBRARY);

  const from = await countFrames(page);
  await page.evaluate(() => { window.__is_counting_copies = true; });
  await advanceFrames(page, FRAMES_COPIES);
  const copies = await page.evaluate(() => {
    window.__is_counting_copies = false;
    const scope = globalThis as unknown as { nimCopy?: CopyNim };
    if (window.__copy_unwrapped !== undefined) scope.nimCopy = window.__copy_unwrapped;
    return { project: window.__copies_counted ?? 0, library: window.__copies_library ?? 0 };
  });
  const phases = await readPhases(page, from);

  report(
    'a still frame under the largest demo copies fewer values than the scene has objects',
    is_wrapped && phases.length === FRAMES_COPIES && copies.project < objects * FRAMES_COPIES,
    is_wrapped
      ? `${copies.project} copies over ${phases.length} frames, for ${objects} objects; ` +
        `library's own ${copies.library}, apart`
      : 'page holds no `nimCopy` to count',
  );
}


/** How many real frames still scene's cost is sampled over. */
const FRAMES_SAMPLE_STILL = 60;

/** Bounds on still frame's build, 1.5 times slowest delegate reading; see `pins`.
 *
 *  Readings each is set from are in `PROVENANCE.md`.
 */
const MILLISECONDS_STILL_MEDIAN = 2.1;
const MILLISECONDS_STILL_P90 = 3.2;

/** Sample still scene, and assert its frames fit inside their own budget.
 *
 *  Speed check, so on real clock. Sample is count of frames rather than span of time, so its
 *  size is same on every machine, and only figures sampled move with speed.
 */
export async function driveFrameWork(page: Page): Promise<void> {
  await page.evaluate(() => {
    nimSelectClear();
    document.getElementById('gl')?.focus();
  });
  await page.keyboard.press('Home');
  await settleCamera(page);
  await watchFrames(page);
  await waitUntil(
    page, (given) => (window.__work_frame ?? []).length >= given, FRAMES_SAMPLE_STILL,
  );

  const work = await readWork(page);
  // Bounds rather than figures: this is real machine's real clock. Figures that matter are
  //   measurements recorded in PROVENANCE.md, taken on this same software renderer.
  reportWithin(
    'a frame is assembled in a fraction of its own budget',
    work === null ? -1 : work.median, 0, MILLISECONDS_STILL_MEDIAN, 'ms',
  );
  reportWithin(
    'and its slowest tenth stays inside it', work === null ? -1 : work.p90, 0,
    MILLISECONDS_STILL_P90, 'ms',
  );
}
