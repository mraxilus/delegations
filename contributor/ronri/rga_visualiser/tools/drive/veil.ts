// Check that plane's veil reaches every pixel its pick finds it at; not Nim because it reads
//   canvas through compositor, which only Playwright reaches.
//   Veil is spanned over box on view, and fragment stage casts its own ray at plane, so box cut
//   short of plane's picture cuts plane and nothing else says so: pick reads algebra and not
//   pixels, and every other check passes with veil draws skipped outright.
//   Read from views where box stopped at wrong line would cut plane: level and low, so
//   plane runs up toward its vanishing line; same rolled, so that line crosses view aslant;
//   steep, so line stands far off view; and from underneath, so plane lies on other side.

import type { Page } from '@playwright/test';
import { settleCamera } from './camera';
import { readCanvas, type Spot } from './canvas';
import { waitFrames } from './frame';
import { clearTheGlass } from './gestures';
import { report } from './report';

/** Spacing of spots read across canvas, in CSS pixels, each way.
 *
 *  Fine enough to put three rows inside band that box stopped halfway to plane's centre
 *  would cut in level view, about 46 px tall.
 */
const PIXELS_SPOT_STEP = 15;

/** Least change veil makes to spot, as sum over red, green and blue.
 *
 *  Ground's veil, olive at `ALPHA_VEIL` 0.16 over backdrop, moves spot by about 30.
 */
const LIFT_LEAST = 8;

/** Least spots each view must find on plane and bare beneath it, so view shows plane. */
const SPOTS_ON_PLANE_LEAST = 200;

/** Most any channel of bare spot may stand off backdrop and still read as backdrop. */
const TOLERANCE_BACKDROP = 2;

/** One view plane's veil is read from: eye and pivot as offsets from plane's anchor. */
interface View {
  name: string;
  eye: number[];
  pivot: number[];
  roll: number;
}

/** Views each reading is taken from, about ground, whose normal is world up.
 *
 *  Eye stands inside disc's radius of its centre in all four, so box of its sphere is whole
 *  view, and only vanishing line can stop it.
 */
const VIEWS: View[] = [
  { name: 'level and low', eye: [4, 0, 1], pivot: [-6, 0, 1], roll: 0 },
  { name: 'rolled', eye: [4, 0, 1], pivot: [-6, 0, 1], roll: 0.6 },
  { name: 'steep', eye: [1.5, 0.7, 6], pivot: [0, 0, 0], roll: 0 },
  { name: 'from underneath', eye: [4, 0, -1], pivot: [-6, 0, -1], roll: 0 },
];

/** What one view read: spots on plane, and those of them veil left bare. */
interface Covered {
  name: string;
  on_plane: number;
  bare: number;
  first_bare: Spot | null;
}

/** Sum of channel differences between two RGBA readings, alpha aside. */
function differenceOf(a: number[], b: number[]): number {
  return Math.abs((a[0] ?? 0) - (b[0] ?? 0)) + Math.abs((a[1] ?? 0) - (b[1] ?? 0)) +
    Math.abs((a[2] ?? 0) - (b[2] ?? 0));
}

/** Most common colour among readings, which is backdrop where most spots show nothing. */
function colourCommonest(readings: number[][]): number[] {
  const counts = new Map<string, number>();
  let best: number[] = [];
  let count_best = 0;
  for (const one of readings) {
    const key = `${one[0] ?? 0},${one[1] ?? 0},${one[2] ?? 0}`;
    const count = (counts.get(key) ?? 0) + 1;
    counts.set(key, count);
    if (count > count_best) {
      count_best = count;
      best = one;
    }
  }
  return best;
}

/** Read one view: canvas with plane, canvas without it, and where pick finds plane.
 *
 *  Spot counts only where pick finds plane and canvas without plane shows bare backdrop
 *  there, since world axis drawn in front of veil hides it with no fault of veil's.
 */
async function coveredFrom(
  page: Page, plane: number, anchor: number[], view: View, spots: Spot[],
): Promise<Covered> {
  await page.evaluate((given) => {
    const at = (base: number[], offset: number[], i: number): number =>
      (base[i] ?? 0) + (offset[i] ?? 0);
    nimPlaceCamera(
      at(given.anchor, given.eye, 0), at(given.anchor, given.eye, 1),
      at(given.anchor, given.eye, 2), at(given.anchor, given.pivot, 0),
      at(given.anchor, given.pivot, 1), at(given.anchor, given.pivot, 2),
    );
    if (given.roll !== 0) nimCameraRoll(given.roll);
    nimClearHover();
  }, { anchor, eye: view.eye, pivot: view.pivot, roll: view.roll });
  await waitFrames(page, 2);
  const shown = await readCanvas(page, spots);
  await page.evaluate((one) => nimSetVisible(one, false), plane);
  await waitFrames(page, 2);
  const without = await readCanvas(page, spots);
  await page.evaluate((one) => nimSetVisible(one, true), plane);
  // Pick through page's own hover, at each spot's pixel centre, once both readings are taken:
  //   hover draws its marker, which neither reading may carry.
  const picked = await page.evaluate((given) => {
    const found: boolean[] = [];
    for (const spot of given.spots) {
      nimUpdateCursor(spot[0] + 0.5, spot[1] + 0.5);
      nimUpdateHover(window.innerWidth, window.innerHeight);
      found.push(nimHoverHandle() === given.plane);
    }
    nimClearHover();
    return found;
  }, { spots, plane });

  const backdrop = colourCommonest(without.spots);
  let on_plane = 0;
  let bare = 0;
  let first_bare: Spot | null = null;
  for (let i = 0; i < spots.length; i += 1) {
    const before = without.spots[i] ?? [];
    const is_backdrop = [0, 1, 2].every(
      (channel) => Math.abs((before[channel] ?? 0) - (backdrop[channel] ?? 0)) <=
        TOLERANCE_BACKDROP,
    );
    if (!(picked[i] ?? false) || !is_backdrop) continue;
    on_plane += 1;
    if (differenceOf(shown.spots[i] ?? [], before) >= LIFT_LEAST) continue;
    bare += 1;
    first_bare ??= spots[i] ?? null;
  }
  return { name: view.name, on_plane, bare, first_bare };
}

/** Assert plane's veil reaches every spot its pick finds it at, from every view of `VIEWS`.
 *
 *  Pick is algebra's meet of sight ray with plane, bounded by disc, so it is reference veil
 *  is held to. Every other object is hidden, so no point or line takes spot from plane, and
 *  shown again after.
 */
export async function driveVeilCovers(page: Page): Promise<void> {
  const claim = "a plane's veil reaches every spot its pick finds it at, low, rolled, steep " +
    'and from underneath';
  await clearTheGlass(page);
  const plane = await page.evaluate(
    () => nimSceneHandles().find((one) => nimObjectLabel(one) === 'ground') ?? -1,
  );
  if (plane < 0) {
    report(claim, false, 'no ground plane in the opening scene');
    return;
  }
  const anchor = await page.evaluate((one) => Array.from(nimAnchorWorld(one)), plane);
  const hidden = await page.evaluate((keep) => {
    const away = nimSceneHandles().filter((one) => one !== keep && nimObjectVisible(one));
    for (const one of away) nimSetVisible(one, false);
    return away;
  }, plane);
  const size = await page.evaluate(() => [window.innerWidth, window.innerHeight]);
  const spots: Spot[] = [];
  const half = Math.floor(PIXELS_SPOT_STEP / 2);
  for (let y = half; y < (size[1] ?? 0); y += PIXELS_SPOT_STEP) {
    for (let x = half; x < (size[0] ?? 0); x += PIXELS_SPOT_STEP) spots.push([x, y]);
  }

  const covered: Covered[] = [];
  for (const view of VIEWS) covered.push(await coveredFrom(page, plane, anchor, view, spots));

  await page.evaluate((away) => {
    for (const one of away) nimSetVisible(one, true);
  }, hidden);
  await page.evaluate(() => document.getElementById('gl')?.focus());
  await page.keyboard.press('Home');
  await settleCamera(page);

  report(
    claim,
    covered.every((one) => one.on_plane >= SPOTS_ON_PLANE_LEAST && one.bare === 0),
    covered.map((one) => `${one.name}: ${one.on_plane - one.bare} of ${one.on_plane} spots ` +
      'veiled' + (one.first_bare === null ? '' :
        `, first bare at (${one.first_bare[0]}, ${one.first_bare[1]})`)).join('; '),
  );
}
