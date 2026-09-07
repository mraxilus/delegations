// Watch what page's own draw loop costs, and check it fits inside frame; not Nim because
//   crossing forfeits check compiler makes over wrapper standing in front of `nimBuildFrame`,
//   which reads every field of `FrameData` that `declare` derives.
//   Measured here is part page owns, not wall clock: browser cannot draw faster than
//   compositor presents, so "uncapped" is not thing to reach for.
//   Machine running these checks renders through software GL, so its frame times say more
//   about swiftshader than about anything in this repository. Hence bands, not figures.

import type { Page } from '@playwright/test';
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
        records_ribbon: data.ribbon_verts.length / 16,
        records_ring: data.ring_records.length / 14,
        records_disc: data.disc_records.length / 13,
        is_held: data.is_furniture_held, wall,
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

/** Drive still scene for few seconds, and assert its frames fit inside their own budget. */
export async function driveFrameWork(page: Page): Promise<void> {
  await page.evaluate(() => {
    nimSelectClear();
    document.getElementById('gl')?.focus();
  });
  await page.keyboard.press('Home');
  await page.waitForTimeout(600);
  await watchFrames(page);
  await page.waitForTimeout(2500);

  const work = await readWork(page);
  report(
    'the draw loop keeps building frames', work !== null && work.n > 30,
    `${work === null ? 0 : work.n} frames sampled`,
  );
  // Bands rather than figures: this is real machine's real clock. Figures that matter are
  //   measurements recorded in PROVENANCE.md, taken on this same software renderer.
  //   Bands catch collapse class reader felt, over scene assembling every point through
  //   algebra, which is stress project exists to apply.
  reportWithin(
    'a frame is assembled in a fraction of its own budget',
    work === null ? -1 : work.median, 0, 18, 'ms',
  );
  reportWithin(
    'and its slowest tenth stays inside one', work === null ? -1 : work.p90, 0, 30, 'ms',
  );
}
