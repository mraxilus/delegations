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

/** Distance camera arrived at, and how much lattice its frame carried. */
interface Ruled {
  distance: number;
  count: number;
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

/** Build one frame at this distance, counting lattice alone. */
async function ruledAt(page: Page, distance: number): Promise<Ruled> {
  return page.evaluate((given) => {
    nimSetCameraDistance(given);
    const canvas = document.getElementById('gl') as HTMLCanvasElement | null;
    if (canvas === null) return { distance: given, count: 0 };
    const data = nimBuildFrame(
      canvas.width / canvas.height, performance.now() / 1000, canvas.height, false, true,
    );
    // Read distance frame came out at, not one asked for: camera can be mid-tween toward
    //   framing of what is picked, and count against distance it never stood at says nothing.
    return { distance: nimCameraDistance(), count: data.furn_ribbon_verts.length };
  }, distance);
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

  await page.evaluate(() => nimSelectClear());
  await page.keyboard.press('Home');
  await settleCamera(page);
}
