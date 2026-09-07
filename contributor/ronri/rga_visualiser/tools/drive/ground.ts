// Check ground reaches camera wherever it has dollied to; not Nim because crossing forfeits
//   check compiler makes over its `page.evaluate` bodies, which name `nimBuildFrame` and read
//   `FrameData`'s own fields -- both derived into `build/bridge.d.ts` and checked there.
//   Camera dollied past fog's cap would have ground stop reaching what it looks at, and
//   further out meet black void with no reference at all: no grid, no axes.
//   Driven through page's own frame build, so what is counted is what would be drawn.

import type { Page } from '@playwright/test';
import { report } from './report';

/** Distances camera is put at, spanning its whole dolly reach. */
const DISTANCES_REACH = [19, 300, 1000, 5000, 40000, 1000000];

/** Distance camera arrived at, and how much grid its frame carried. */
interface Ground {
  distance: number;
  count: number;
}

/** Build one frame at this distance, counting grid alone. */
async function groundAt(page: Page, distance: number): Promise<Ground> {
  return page.evaluate((given) => {
    nimSetCameraDistance(given);
    const canvas = document.getElementById('gl') as HTMLCanvasElement | null;
    if (canvas === null) return { distance: given, count: 0 };
    const data = nimBuildFrame(
      canvas.width / canvas.height, performance.now() / 1000, canvas.height, false, true,
    );
    // Read distance frame came out at, not one asked for: camera can be mid-tween toward
    //   framing of scene, and count against distance it never stood at says nothing.
    return { distance: nimCameraDistance(), count: data.furn_ribbon_verts.length };
  }, distance);
}

/** Drive camera out to its reach, and assert ground follows it.
 *
 *  Axes are switched off throughout: their three lines are drawn by rule of their own and
 *  would hold count above zero in exactly case this guards against.
 */
export async function driveGround(page: Page): Promise<void> {
  await page.evaluate(() => nimSelectClear());
  await page.keyboard.press('Home');
  await page.waitForTimeout(150);

  const grounds: Ground[] = [];
  for (const distance of DISTANCES_REACH) grounds.push(await groundAt(page, distance));
  report(
    'there is ground under the camera at every distance it can reach',
    grounds.every((at) => at.count > 0),
    grounds.map((at) => `${at.distance.toFixed(0)}: ${at.count}`).join(', '),
  );

  // Cell steps by decades to keep that true, so what is drawn stays inside mark fixed cell
  //   was bounded by rather than growing with reach.
  const most = Math.max(...grounds.map((at) => at.count));
  const near = grounds[1]?.count ?? 0;
  report(
    'and no more of it is drawn far out than close in',
    most <= 1.1 * near, `most ${most}, at 300 ${near}`,
  );

  await page.keyboard.press('Home');
  await page.waitForTimeout(150);
}
