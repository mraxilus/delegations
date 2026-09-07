// Checks for what scene and scenery cost, and for rows that break them down; not Nim because
//   they drive real drag and read rows out of DOM, neither of which Nim's JS backend has.
//   Kinds differ by two orders of magnitude -- point is one vertex, plane rim of ribbons each
//   carrying its own join -- so reader asking why scene is slow needs split, not total.
//   Held only way breakdown can be held honest: parts must account for whole they are parts
//   of, frame by frame, and each part must carry count it is time for.

import type { Page } from '@playwright/test';
import { settleCamera } from './camera';
import { settleBranch } from './diagnostics';
import { countFrames, readPhases, type Phase } from './frame';
import { report, reportWithin } from './report';

/** Bound scenery holds itself to: two families of lattice lines, from `mesh.LINES_GRID_MAX`. */
const RECORDS_GRID_MAX = 2 * (2 * 120 + 1);

/** How many frames of sample may miss accounting, at unchanged per-frame tolerance.
 *
 *  Every reading is quantised, so summing six parts against one whole carries rounding before
 *  any real disagreement, and frame whose brackets straddle collection adds more. Demanding
 *  *every* frame account held for ten runs and then failed as container sped up and sample
 *  grew, which is property of sample size, not of accounting. Loosening per-frame tolerance
 *  instead would weaken check on all of them; allowance keeps it exactly as strict per frame,
 *  since real accounting fault misses on every frame and cannot hide inside two.
 *
 *  **Count rather than share, because sample is small and its size is capped by code.**
 *  Share of 0.995 was written for that earlier failure and never took effect: `ceil(0.995n)`
 *  equals `n` for every `n` under 200, so it permitted zero misses at every sample either
 *  caller can produce -- `loaded`'s sampling loop stops at 25 heavy frames, and reaching 200
 *  would need frame rates `requestAnimationFrame` forbids. Growing sample does not rescue
 *  share either: misses are per frame, so larger sample brings proportionally more chances to
 *  straddle and proportional allowance never pulls ahead.
 *  Two rather than one: one leaves roughly red run in sixty on same reasoning that puts two
 *  near one in thousand, and count is honest about sample code caps where share rounds to no
 *  slack at all. Figure is shape rather than rate -- misses clustering, from scheduler pause
 *  or collection cycle, would make it worse, and that is unmeasured (repository issue 47).
 */
export const MISSES_ACCOUNT_MAX = 2;

/** Assert accounting allowance actually allows something, at smallest sample its own
 *  checks admit.
 *
 *  Guards this allowance to: `kinds.length > 30` here, `heavy.length > 20` in `loaded`, so
 *  smallest sample either accepts is 21. Allowance that leaves no room at that size is
 *  allowance in name only -- which is exactly what share of 0.995 was, since `ceil(0.995n)`
 *  equals `n` for every `n` under 200. Check exists because that went unnoticed through ten
 *  runs and one repair that never took effect (repository issue 47).
 *  Reads constant rather than page: what went wrong was arithmetic, not anything browser did.
 */
export function driveAllowance(): void {
  const smallest = 21;
  const floor = smallest - MISSES_ACCOUNT_MAX;
  report(
    'the accounting allowance leaves room at the smallest sample its checks admit',
    floor < smallest && floor > 0,
    `floor ${floor} of ${smallest} frames, so ${smallest - floor} may miss`,
  );
}


/** Open one branch of tree, leaving it open where it already was. */
async function openBranch(page: Page, node: string): Promise<void> {
  await page.evaluate((given) => {
    const branch = document.querySelector(`.diagnostic-node[data-node="${given}"]`);
    if (branch?.classList.contains('open') ?? false) return;
    (branch?.querySelector(':scope > .diagnostic-parent') as HTMLElement | null)?.click();
  }, node);
  await settleBranch(page, node);
}

/** Read reading and name of each of these rows. */
async function readRows(
  page: Page, names: string[],
): Promise<Record<string, { value: string; label: string }>> {
  return page.evaluate((given) => Object.fromEntries(given.map((name) => {
    const value = document.getElementById('diagnostic-' + name);
    return [name, {
      value: value?.textContent ?? '',
      label: value?.closest('.diagnostic-line')?.querySelector('span')?.textContent ?? '',
    }];
  })), names);
}

/** Assert scene's own time is accounted for by kinds it is spent on. */
export async function driveKinds(page: Page): Promise<void> {
  const phases = await readPhases(page);
  const kinds = phases.map((one) => ({
    scene: one.scene,
    parts: one.points + one.lines + one.planes + one.sky + one.preview + one.selected,
    counted: one.count_points + one.count_lines + one.count_planes +
      one.count_sky + one.count_preview + one.count_selected,
  }));
  // Parts may never exceed whole by more than rounding, and must account for bulk of it --
  //   but not for all: phase also walks every handle twice, marks overlay and packs
  //   view-projection, and none of that belongs to any one kind. That remainder is share of
  //   frame rather than fixed cost, so floor is share too.
  const sane = kinds.filter((one) =>
    one.parts <= one.scene + 0.6 &&
    one.parts >= one.scene - Math.max(3.0, 0.3 * one.scene) && one.counted > 0);
  const last = kinds[kinds.length - 1];
  report(
    'the scene phase is accounted for by the kinds it is spent on',
    kinds.length > 30 && sane.length >= kinds.length - MISSES_ACCOUNT_MAX,
    `${sane.length} of ${kinds.length} frames account ` +
      `(floor ${kinds.length - MISSES_ACCOUNT_MAX}), last frame ` +
      `${last === undefined ? '?' : last.parts.toFixed(2)} of ` +
      `${last === undefined ? '?' : last.scene.toFixed(2)} ms over ` +
      `${last === undefined ? '?' : last.counted} objects`,
  );

  await openBranch(page, 'furniture');
  const scenery = await readRows(page, ['grid', 'axes']);
  report(
    'and both halves have their own row, the grid carrying its segment count',
    // Count sits beside row's name, so every value ends in `ms` and times down tree finish in
    //   one column; grid names its segments, axes name none.
    / ms$/.test(scenery['grid']?.value ?? '') && /\(\d+\)$/.test(scenery['grid']?.label ?? '') &&
      / ms$/.test(scenery['axes']?.value ?? '') &&
      !/\(\d+\)$/.test(scenery['axes']?.label ?? ''),
    `grid: ${scenery['grid']?.label} ${scenery['grid']?.value}, ` +
      `axes: ${scenery['axes']?.label} ${scenery['axes']?.value}`,
  );

  await openBranch(page, 'scene');
  const rows = await readRows(page, ['points', 'lines', 'planes', 'sky', 'preview', 'selected']);
  report(
    'each kind reports its own count beside its own name',
    Object.values(rows).every(
      (one) => / ms$/.test(one.value) && /\(\d+\)$/.test(one.label),
    ),
    Object.entries(rows).map(([name, one]) => `${name}: ${one.label} ${one.value}`).join(', '),
  );
}

/** Assert scenery holds its line bound where it used to cost most.
 *
 *  Its price is its segment count, and that count climbs with camera distance until cell steps
 *  decade and drops it back -- so worst frame is not farthest one but one just before step.
 */
export async function driveSceneryBound(page: Page): Promise<void> {
  const far = await page.evaluate(() => {
    const canvas = document.getElementById('gl') as HTMLCanvasElement;
    const aspect = canvas.width / canvas.height;
    const distance_before = nimCameraDistance();
    nimSetCameraDistance(300);
    const milliseconds: number[] = [];
    let segments = 0;
    for (let i = 0; i < 9; i += 1) {
      nimCameraOrbit(0.005, 0); // Move, so furniture cache cannot hold and it rebuilds.
      const data = nimBuildFrame(aspect, performance.now() / 1000, canvas.height, true, true);
      milliseconds.push(data.ms_grid);
      segments = data.count_grid_segments;
    }
    nimSetCameraDistance(distance_before);
    milliseconds.sort((a, b) => a - b);
    return { median: milliseconds[4] ?? 0, segments };
  });
  report(
    'the scenery holds its line bound where it used to cost the most',
    // Bound at one record per lattice line, since fog fade is fragment shader's.
    far.segments > 0 && far.segments <= RECORDS_GRID_MAX,
    `${far.segments} grid records at orbit distance 300, ${far.median.toFixed(1)} ms of grid`,
  );
}

/** Drive real drag, and assert what frame costs while camera moves.
 *
 *  Moving camera rebuilds ground grid every frame, and per-segment churn once put that rebuild
 *  at three times still frame's whole build. Drag is real one, from empty sky, so frames
 *  sampled are frames hand would feel.
 */
export async function driveMoving(page: Page, width: number): Promise<void> {
  const from = await countFrames(page);
  await page.mouse.move(width / 2, 60);
  await page.mouse.down();
  for (let i = 0; i < 40; i += 1) {
    await page.mouse.move(
      width / 2 + 350 * Math.sin(i / 6), 60 + 20 * Math.cos(i / 6), { steps: 3 },
    );
  }
  await page.mouse.up();

  const moving = await page.evaluate((given) => {
    const sorted = (window.__work_frame ?? []).slice(given).sort((a, b) => a - b);
    if (sorted.length < 10) return null;
    const at = (share: number): number =>
      sorted[Math.min(sorted.length - 1, Math.floor(share * sorted.length))] ?? 0;
    return { n: sorted.length, median: at(0.5), p90: at(0.9) };
  }, from);

  const phases = (await readPhases(page, from)).filter((one) => one.furniture > 0.05);
  reportSceneryAccounts(phases);
  report(
    'the camera was really moved for the moving-frame sample',
    moving !== null, `${moving === null ? 0 : moving.n} frames sampled mid-drag`,
  );
  // Band is what catches collapse class reader felt without timing this container. It is close
  //   to bone on loaded shared runner: identical code has measured wide apart hours apart.
  //   Failure just past band says to re-measure against previous commit before believing it;
  //   failure well past it is collapse this exists for.
  reportWithin(
    'a frame is still assembled inside its budget while the camera moves',
    moving === null ? -1 : moving.median, 0, 26, 'ms',
  );
}

/** Assert scenery's two halves account for scenery itself, frame by frame.
 *
 *  Axes are three lines however far camera stands; grid is however many ground reach asks for,
 *  and its cost *is* its segment count. Slack is proportional: bracket around two halves also
 *  spans mesh clear and loop between them, and on frame scheduler interrupts that gap grows
 *  with frame rather than by fixed amount.
 */
function reportSceneryAccounts(phases: Phase[]): void {
  const offOf = (one: Phase): number => one.grid + one.axes - one.furniture;
  const sane = phases.filter((one) =>
    offOf(one) <= Math.max(0.6, 0.08 * one.furniture) &&
    offOf(one) >= -Math.max(1.0, 0.12 * one.furniture) && one.segments > 0);
  // Worst frame, not last: bare count says nothing about what went wrong.
  const worst = phases.length === 0 ? undefined
    : phases.reduce((a, b) => (Math.abs(offOf(b)) > Math.abs(offOf(a)) ? b : a));
  report(
    'the scenery is accounted for by the grid and the axes it is drawn from',
    phases.length > 3 && sane.length === phases.length,
    `${sane.length} of ${phases.length} rebuilt frames account` +
      (worst === undefined ? '' :
        `, worst ${worst.grid.toFixed(1)} + ${worst.axes.toFixed(1)} of ` +
        `${worst.furniture.toFixed(1)} ms (off by ${offOf(worst).toFixed(2)}) over ` +
        `${worst.segments} segments`),
  );
}

/** Assert still camera holds its ground and axes rather than rebuilding them. */
export async function driveHold(page: Page): Promise<void> {
  await page.keyboard.press('Home');
  await settleCamera(page);
  const from = await countFrames(page);
  // Wall time, deliberately: share of frames that held over span of real time is measurement
  //   here, not race waiting to be won.
  await page.waitForTimeout(1500);
  const still = await readPhases(page, from);
  const held = still.filter((one) => one.is_held).length;
  report(
    'a still camera holds its ground and axes rather than rebuilding them',
    still.length > 10 && held > 0.8 * still.length,
    `${held} of ${still.length} frames held`,
  );

  // Stated directly too, since share of frames could be right by accident: move camera, so
  //   next call must build, and one after it must hold.
  const twice = await page.evaluate(() => {
    const canvas = document.getElementById('gl') as HTMLCanvasElement;
    const aspect = canvas.width / canvas.height;
    const once = (): FrameData =>
      nimBuildFrame(aspect, performance.now() / 1000, canvas.height, true, true);
    nimCameraOrbit(0.05, 0.0);
    const first = once();
    const second = once();
    return {
      first: { is_held: first.is_furniture_held, floats: first.furn_ribbon_verts.length },
      second: { is_held: second.is_furniture_held, floats: second.furn_ribbon_verts.length },
    };
  });
  report(
    'a still camera builds its ground and axes once and holds them',
    twice.first.floats > 0 && !twice.first.is_held &&
      twice.second.is_held && twice.second.floats === 0,
    `first ${twice.first.floats} floats (held ${twice.first.is_held}), ` +
      `second ${twice.second.floats} (held ${twice.second.is_held})`,
  );

  // Camera that has moved rebuilds them, or view would keep grid it has left.
  const rebuilt = await page.evaluate(() => {
    const canvas = document.getElementById('gl') as HTMLCanvasElement;
    const aspect = canvas.width / canvas.height;
    nimBuildFrame(aspect, performance.now() / 1000, canvas.height, true, true);
    nimCameraOrbit(0.3, 0.0);
    const after = nimBuildFrame(aspect, performance.now() / 1000, canvas.height, true, true);
    return { is_held: after.is_furniture_held, floats: after.furn_ribbon_verts.length };
  });
  report(
    'and a camera that has moved builds them again',
    !rebuilt.is_held && rebuilt.floats > 0,
    `held ${rebuilt.is_held}, ${rebuilt.floats} floats`,
  );
}
