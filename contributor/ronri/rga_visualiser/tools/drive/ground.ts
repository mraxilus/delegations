// Check picked plane's lattice reaches camera wherever it has dollied to; not Nim because
//   crossing forfeits check compiler makes over its `page.evaluate` bodies, which name
//   `nimBuildFrame` and read `FrameData`'s own fields -- both derived into
//   `build/bridge.d.ts` and checked there.
//   World rules no ground: its origin is Sol, and no plane through it is anybody's floor.
//   Plane picked is what is ruled, and camera dollied past fog's cap would have lattice stop
//   reaching what it looks at.
//   Driven through page's own frame build, so what is counted is what would be drawn.

import type { Page } from '@playwright/test';
import { settleCamera } from './camera';
import { report } from './report';

/** Distances camera is put at, spanning its whole dolly reach. */
const DISTANCES_REACH = [19, 300, 1000, 5000, 40000, 1000000];

/** Floats in one ribbon record, `mesh.RibbonRecord`: tail at 0 to 2, head at 3 to 5. */
const FLOATS_RIBBON_RECORD = 16;

/** Distance under which two parallel records lie on one line, in world units.
 *
 *  Tenth of least cell, `SIZE_CELL_GRID` at 10: lines of one family stand whole cell apart,
 *  and pieces of one line stand apart by float32 rounding alone.
 */
const UNITS_ONE_LINE = 1;

/** Sine of angle under which two records run one way: families cross square, at sine 1. */
const SINE_ONE_WAY = 1e-3;

/** Three coordinates of world position or direction. */
type Triple = [number, number, number];

/** Distance camera arrived at, and how much lattice its frame carried. */
interface Ruled {
  distance: number;
  count: number;
  records: number;
  lines: number;
}

/** Pick scene's first plane alone, so furniture carries lattice to measure; report handle.
 *
 *  Minus one where scene holds no plane. For every check whose subject is lattice's cost.
 */
export async function pickPlane(page: Page): Promise<number> {
  return page.evaluate(() => {
    const plane = nimSceneHandles().find((handle) => nimObjectKindWord(handle) === 'plane') ?? -1;
    if (plane >= 0) nimSelectOnly(plane);
    return plane;
  });
}

/** Build one frame at this distance, counting lattice alone, and lines its records lie on.
 *
 *  Record lies on new line unless parallel to earlier one and within `UNITS_ONE_LINE` of it.
 *  Counted from records page uploads, so count is what is drawn, not what `mesh` says it laid.
 */
async function ruledAt(page: Page, distance: number): Promise<Ruled> {
  return page.evaluate((given) => {
    nimSetCameraDistance(given.distance);
    const canvas = document.getElementById('gl') as HTMLCanvasElement | null;
    if (canvas === null) return { distance: given.distance, count: 0, records: 0, lines: 0 };
    const data = nimBuildFrame(
      canvas.width / canvas.height, performance.now() / 1000, canvas.height, false, true,
    );
    const floats = data.furniture_ribbon_vertices;
    const at = (index: number): number => floats[index] ?? 0;
    const across = (u: Triple, v: Triple): number => Math.hypot(
      u[1] * v[2] - u[2] * v[1], u[2] * v[0] - u[0] * v[2], u[0] * v[1] - u[1] * v[0],
    );
    const records = Math.floor(floats.length / given.floats);
    const earlier: { tail: Triple; direction: Triple }[] = [];
    let lines = 0;
    for (let i = 0; i < records; i += 1) {
      const first = i * given.floats;
      const tail: Triple = [at(first), at(first + 1), at(first + 2)];
      const along: Triple =
        [at(first + 3) - tail[0], at(first + 4) - tail[1], at(first + 5) - tail[2]];
      const length = Math.hypot(...along);
      const direction: Triple = [along[0] / length, along[1] / length, along[2] / length];
      const is_on_earlier = earlier.some((other) => {
        const offset: Triple =
          [tail[0] - other.tail[0], tail[1] - other.tail[1], tail[2] - other.tail[2]];
        return across(direction, other.direction) < given.sine &&
          across(offset, other.direction) < given.apart;
      });
      if (!is_on_earlier) lines += 1;
      earlier.push({ tail, direction });
    }
    // Read distance frame came out at, not one asked for: camera can be mid-tween toward
    //   framing of what is picked, and count against distance it never stood at says nothing.
    return { distance: nimCameraDistance(), count: floats.length, records, lines };
  }, { distance, floats: FLOATS_RIBBON_RECORD, apart: UNITS_ONE_LINE, sine: SINE_ONE_WAY });
}

/** Drive camera out to its reach, and assert picked plane's lattice follows it.
 *
 *  Axes are switched off throughout: their three lines are drawn by rule of their own and
 *  would hold count above zero in exactly case this guards against.
 */
export async function driveGround(page: Page): Promise<void> {
  await page.evaluate(() => nimSelectClear());
  await page.keyboard.press('Home');
  await settleCamera(page);
  const bare = await ruledAt(page, 19);
  report(
    'with nothing picked no plane is ruled, since the world has no ground',
    bare.count === 0, `${bare.count} lattice vertices`,
  );

  const plane = await pickPlane(page);
  const ruled: Ruled[] = [];
  for (const distance of DISTANCES_REACH) ruled.push(await ruledAt(page, distance));
  report(
    'a picked plane is ruled at every distance the camera can reach',
    plane >= 0 && ruled.every((at) => at.count > 0),
    `plane ${plane}; ` + ruled.map((at) => `${at.distance.toFixed(0)}: ${at.count}`).join(', '),
  );

  // Cell steps by decades to keep that true, so what is drawn stays inside mark fixed cell
  //   was bounded by rather than growing with reach.
  const most = Math.max(...ruled.map((at) => at.count));
  const near = ruled[1]?.count ?? 0;
  report(
    'and no more of it is drawn far out than close in',
    most <= 1.1 * near, `most ${most}, at 300 ${near}`,
  );

  // One record for each line, since fog fade is fragment shader's.
  //   Line cut into pieces, each faded apart, lays several records on one line: that fault
  //   read 26.1 ms of moving grid at 300. Count holds it on any machine, where time could not.
  report(
    'the lattice lays one record for each line it rules, at every distance',
    ruled.every((at) => at.records > 0 && at.lines === at.records),
    ruled.map((at) => `${at.distance.toFixed(0)}: ${at.records} on ${at.lines}`).join(', '),
  );

  await page.evaluate(() => nimSelectClear());
  await page.keyboard.press('Home');
  await settleCamera(page);
}
