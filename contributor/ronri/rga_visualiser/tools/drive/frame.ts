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
  is_held: boolean;
  is_scene_held: boolean;
  wall: number;
}

declare global {
  interface Window {
    /** How long each frame's build took, in milliseconds, oldest first. */
    __work_frame?: number[];
    /** How many of those frames reused furniture held from frame before. */
    __held_frame?: number;
    /** Each frame's own clocks and counts, alongside `__work_frame`. */
    __phase_frame?: Phase[];
  }
}

/** Stand wrapper in front of page's frame build, collecting what each frame costs.
 *
 *  Installed once and read by every later section: second wrapper over first would charge
 *  each frame twice.
 */
export async function watchFrames(page: Page): Promise<void> {
  await page.evaluate(() => {
    window.__work_frame = [];
    window.__held_frame = 0;
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
      if (data.is_furniture_held) window.__held_frame = (window.__held_frame ?? 0) + 1;
      window.__phase_frame?.push({
        build: data.ms_build, furniture: data.ms_furniture,
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
        is_held: data.is_furniture_held, is_scene_held: data.is_scene_held, wall,
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
  held: number;
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
      max: sorted[sorted.length - 1] ?? 0, held: window.__held_frame ?? 0,
    };
  }, from);
}

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


/** How many real frames still scene's cost is sampled over. */
const FRAMES_SAMPLE_STILL = 60;

/** Bounds on still frame's build, 1.5 times slowest delegate reading; see `pins`.
 *
 *  Readings each is set from are in `PROVENANCE.md`.
 */
const MILLISECONDS_STILL_MEDIAN = 1.5;
const MILLISECONDS_STILL_P90 = 2.9;

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
