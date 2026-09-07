// Checks for what picking does to camera; not Nim because buttons are clicked through
//   Playwright, which node alone reaches, and because crossing would forfeit check compiler
//   makes over `page.evaluate` bodies naming bridge's derived exports.
//   Turning about point is what orbit is, so reader who picks objects and turns means to
//   turn about those. Framing used to leave pivot wherever it was whenever everything
//   picked was already on screen, which swung picked object around view instead.

import type { CDPSession, Page } from '@playwright/test';
import { depthOf, readCamera, spanOf, spanPivot, type Stance } from './camera';
import { clearTheGlass } from './gestures';
import { report } from './report';
import { pinch, settleCamera } from './touch';

/** Plane's drawn diameter, from `mesh.EXTENT_PLANE_F`, and share of frame it is brought to,
 *  from `framing.FRACTION_HEIGHT_APPROACH_PLANE`. */
const DIAMETER_PLANE = 16, SHARE_HEIGHT_PLANE = 0.40;

/** Where object stands in world, from its own coefficients. */
async function placeOf(page: Page, handle: number): Promise<number[]> {
  return page.evaluate((one) => {
    const c = nimObjectCoefficients(one);
    const weight = c[4] ?? 1;
    return [(c[1] ?? 0) / weight, (c[2] ?? 0) / weight, (c[3] ?? 0) / weight];
  }, handle);
}

/** Handles of every point in scene, which are what these checks pick. */
async function pointsPickable(page: Page): Promise<number[]> {
  return page.evaluate(
    () => nimSceneHandles().filter((one) => nimObjectKindWord(one) === 'point'),
  );
}

/** Drive two picks, and assert orbit centre lands on them and nothing else moves. */
export async function drivePickOrbit(page: Page): Promise<void> {
  await clearTheGlass(page);
  await page.keyboard.press('Home');
  await settleCamera(page);

  const points = await pointsPickable(page);
  const first = points[0];
  const second = points[1];
  if (first === undefined || second === undefined) {
    report('the scene holds two points to pick', false, `${points.length} points`);
    return;
  }

  const before = await readCamera(page);
  await page.evaluate((one) => nimSelectOnly(one), first);
  await page.waitForTimeout(700);
  const at_one = await readCamera(page);
  const place_one = await placeOf(page, first);
  await page.evaluate((one) => nimSelectToggle(one), second);
  await page.waitForTimeout(700);
  const at_two = await readCamera(page);
  const place_two = await placeOf(page, second);
  const middle = place_one.map((v, i) => (v + (place_two[i] ?? 0)) / 2);

  report(
    'picking an object turns the orbit about it, and a pair about their middle',
    spanOf(at_one.pivot, place_one) < 0.01 && spanOf(at_two.pivot, middle) < 0.01,
    `one pick -> ${at_one.pivot.map((v) => v.toFixed(2))} ` +
      `(object at ${place_one.map((v) => v.toFixed(2))}); ` +
      `two -> ${at_two.pivot.map((v) => v.toFixed(2))} ` +
      `(middle ${middle.map((v) => v.toFixed(2))})`,
  );
  report(
    "and re-centring alone never touches the reader's distance or orbit",
    Math.abs(at_two.distance - before.distance) < 1e-6 &&
      Math.abs(at_two.azimuth - before.azimuth) < 1e-6,
    `distance ${before.distance.toFixed(3)} -> ${at_two.distance.toFixed(3)}, ` +
      `azimuth ${before.azimuth.toFixed(4)} -> ${at_two.azimuth.toFixed(4)}`,
  );
}

/** Where menu and its object's anchor stand, in page's own coordinates. */
interface MenuStanding {
  shown: boolean;
  distance: number;
  menu: number[];
  anchor: number[];
}

/** Read menu's corner and its object's anchor together, so they name same frame. */
async function menuAndAnchor(page: Page, handle: number): Promise<MenuStanding> {
  return page.evaluate((one) => {
    const menu = document.getElementById('selection-menu');
    const box = menu?.getBoundingClientRect();
    const rect = (document.getElementById('gl') as HTMLElement).getBoundingClientRect();
    const at = Array.from(nimAnchorScreen(one, rect.width, rect.height));
    return {
      shown: menu?.classList.contains('show') ?? false,
      distance: nimCameraDistance(),
      menu: [box?.left ?? 0, box?.top ?? 0],
      anchor: [rect.left + (at[0] ?? 0), rect.top + (at[1] ?? 0)],
    };
  }, handle);
}

/** Drive right-click pick from far out, which opens menu and brings camera in.
 *
 *  Wheel out six notches from `Home` so first pickable point is dot far off, then click
 *  6 px off its anchor. Menu is up two frames in, its corner within inset of pointer; that
 *  anchor's pixel is where it was, in flight and settled; distance fell; pivot sits at
 *  object's depth. Glass is cleared first, since drawer standing open would take click.
 */
export async function drivePointerPick(page: Page): Promise<void> {
  await clearTheGlass(page);
  await page.keyboard.press('Home');
  await settleCamera(page);
  const points = await pointsPickable(page);
  const picked = points[0];
  if (picked === undefined) return;

  await page.mouse.move(400, 300);
  for (let notch = 0; notch < 6; notch += 1) {
    await page.mouse.wheel(0, 120);
    await page.waitForTimeout(40);
  }
  await settleCamera(page);
  const far = await readCamera(page);

  const aimed = await page.evaluate((one) => {
    const rect = (document.getElementById('gl') as HTMLElement).getBoundingClientRect();
    const at = Array.from(nimAnchorScreen(one, rect.width, rect.height));
    return {
      x: rect.left + (at[0] ?? 0) + 6, y: rect.top + (at[1] ?? 0) + 4,
      is_in_front: (at[2] ?? 0) > 0.5,
      anchor: [rect.left + (at[0] ?? 0), rect.top + (at[1] ?? 0)],
    };
  }, picked);
  const place = await placeOf(page, picked);

  await page.mouse.move(aimed.x, aimed.y);
  await page.waitForTimeout(100);
  await page.mouse.click(aimed.x, aimed.y, { button: 'right' });
  await page.waitForTimeout(120); // Two frames in: ease under way, menu already up.
  const in_flight = await menuAndAnchor(page, picked);
  await settleCamera(page);
  await page.waitForTimeout(200);
  const opened = await menuAndAnchor(page, picked);
  const near = await readCamera(page);
  await page.evaluate(() => nimCameraPan(0.4, 0.2));
  await page.waitForTimeout(600);
  const panned = await menuAndAnchor(page, picked);

  reportPointerPick(
    { aimed, in_flight, opened, panned }, { far, near }, depthOf(near, place),
  );
  await drivePickAgain(page, picked, near);
}

/** What one pointer pick left behind, at each stage worth asserting on. */
interface Picked {
  aimed: { is_in_front: boolean; x: number; y: number; anchor: number[] };
  in_flight: MenuStanding;
  opened: MenuStanding;
  panned: MenuStanding;
}

/** Report three checks one pointer pick answers: menu, anchor, and offset under pan. */
function reportPointerPick(
  picked: Picked, camera: { far: Stance; near: Stance }, depth: number,
): void {
  const away = (standing: MenuStanding): number[] =>
    [(standing.menu[0] ?? 0) - (standing.anchor[0] ?? 0),
      (standing.menu[1] ?? 0) - (standing.anchor[1] ?? 0)];
  const from_pointer = [
    (picked.opened.menu[0] ?? 0) - picked.aimed.x, (picked.opened.menu[1] ?? 0) - picked.aimed.y,
  ];
  const away_opened = away(picked.opened), away_panned = away(picked.panned);
  const drift = (standing: MenuStanding): number => Math.hypot(
    (standing.anchor[0] ?? 0) - (picked.aimed.anchor[0] ?? 0),
    (standing.anchor[1] ?? 0) - (picked.aimed.anchor[1] ?? 0),
  );
  const moved = Math.hypot(
    (picked.panned.anchor[0] ?? 0) - (picked.opened.anchor[0] ?? 0),
    (picked.panned.anchor[1] ?? 0) - (picked.opened.anchor[1] ?? 0),
  );

  report(
    'a pointer pick opens the menu at once beside the pointer',
    picked.aimed.is_in_front && picked.in_flight.shown && picked.opened.shown &&
      Math.abs((from_pointer[0] ?? 0) - 8) < 2 && Math.abs((from_pointer[1] ?? 0) - 8) < 2,
    `two frames in: menu ${picked.in_flight.shown ? 'shown' : 'hidden'}; settled: menu ` +
      `${picked.opened.shown ? 'shown' : 'hidden'}, corner ` +
      `${from_pointer.map((v) => v.toFixed(0))} px from pointer (inset 8)`,
  );
  report(
    'and keeps the picked object under the pointer as the camera comes in to it',
    drift(picked.in_flight) < 1.5 && drift(picked.opened) < 1.5 &&
      picked.in_flight.distance < camera.far.distance - 0.01 &&
      camera.near.distance < 0.5 * camera.far.distance &&
      Math.abs(depth - camera.near.distance) < 0.01,
    `anchor drifted ${drift(picked.in_flight).toFixed(2)} px in flight, ` +
      `${drift(picked.opened).toFixed(2)} px settled; distance ` +
      `${camera.far.distance.toFixed(2)} -> ${picked.in_flight.distance.toFixed(2)} in flight ` +
      `-> ${camera.near.distance.toFixed(2)}; object at depth ${depth.toFixed(3)}`,
  );
  report(
    'and keeps its offset from the object as the view pans',
    Math.abs((away_panned[0] ?? 0) - (away_opened[0] ?? 0)) < 2 &&
      Math.abs((away_panned[1] ?? 0) - (away_opened[1] ?? 0)) < 2 && moved > 50,
    `offset ${away_opened.map((v) => v.toFixed(0))} at open, ` +
      `${away_panned.map((v) => v.toFixed(0))} after pan moved anchor ${moved.toFixed(0)} px`,
  );
}

/** Pick same object again once wheel has taken reader out until it is dot once more.
 *
 *  Offer it holds is renewed, and camera comes in again. Wheel over object, so zoom stays
 *  anchored on it and it is still under pointer to be picked.
 */
async function drivePickAgain(page: Page, picked: number, near: Stance): Promise<void> {
  const anchorOf = (): Promise<{ x: number; y: number; is_in_front: boolean }> =>
    page.evaluate((one) => {
      const rect = (document.getElementById('gl') as HTMLElement).getBoundingClientRect();
      const at = Array.from(nimAnchorScreen(one, rect.width, rect.height));
      return {
        x: rect.left + (at[0] ?? 0), y: rect.top + (at[1] ?? 0),
        is_in_front: (at[2] ?? 0) > 0.5,
      };
    }, picked);

  const out = await anchorOf();
  await page.mouse.move(out.x, out.y);
  // Wheel out past hundred units, well past thirty, where 0.08 of radius drops under floor
  //   dot's three pixels.
  for (let notch = 0; notch < 80; notch += 1) {
    await page.mouse.wheel(0, 120);
    await page.waitForTimeout(40);
    if ((await readCamera(page)).distance > 100) break;
  }
  await settleCamera(page);
  const notched = await readCamera(page);
  const again = await anchorOf();
  await page.mouse.move(again.x + 4, again.y + 3);
  await page.waitForTimeout(100);
  await page.mouse.click(again.x + 4, again.y + 3, { button: 'right' });
  await settleCamera(page);
  const repicked = await readCamera(page);

  report(
    'a second pick of the object the camera already holds comes in again',
    again.is_in_front && notched.distance > 3 * near.distance &&
      repicked.distance < 0.5 * notched.distance &&
      (await page.evaluate(() => nimSelectionHandles().length)) === 1,
    `distance ${near.distance.toFixed(2)} -> notch ${notched.distance.toFixed(2)} ` +
      `-> re-pick ${repicked.distance.toFixed(2)}`,
  );
}

/** Drive right-click on ground plane, which brings it to its own size. */
export async function drivePlanePick(page: Page): Promise<void> {
  await clearTheGlass(page);
  await page.keyboard.press('Home');
  await settleCamera(page);
  await page.evaluate(() => clearSelection());

  const plane = await page.evaluate(() => nimSceneHandles().find(
    (one) => nimObjectKindWord(one) === 'plane' && nimObjectLabel(one) === 'ground',
  ) ?? -1);
  const rect = await page.evaluate(() => {
    const r = (document.getElementById('gl') as HTMLElement).getBoundingClientRect();
    return { left: r.left, top: r.top, width: r.width, height: r.height };
  });
  const press = {
    x: rect.left + rect.width * 0.62, y: rect.top + rect.height * 0.7,
  };
  const hovered = await page.evaluate((at) => {
    const canvas = document.getElementById('gl') as HTMLCanvasElement;
    nimUpdateCursor(at.x, at.y);
    nimUpdateHover(canvas.clientWidth, canvas.clientHeight);
    return nimHoverHandle();
  }, { x: press.x - rect.left, y: press.y - rect.top });

  await page.mouse.move(press.x, press.y);
  await page.waitForTimeout(100);
  await page.mouse.click(press.x, press.y, { button: 'right' });
  await settleCamera(page);
  const camera = await readCamera(page);
  const centre = await page.evaluate((one) => Array.from(nimAnchorWorld(one)), plane);
  const depth = depthOf(camera, centre);
  const fov = await page.evaluate(() => nimCameraFov());
  const wanted = DIAMETER_PLANE /
    (2 * SHARE_HEIGHT_PLANE * Math.tan(((fov / 2) * Math.PI) / 180));
  const is_menu_up = await page.evaluate(
    () => document.getElementById('selection-menu')?.classList.contains('show') ?? false,
  );
  report(
    'a plane picked by pointer is brought to two fifths of the frame',
    hovered === plane && Math.abs(depth - wanted) < 0.01 * wanted && is_menu_up,
    `hover ${hovered} (ground ${plane}); disc centre at depth ` +
      `${depth.toFixed(3)}, wanted ${wanted.toFixed(3)}`,
  );
}

/** Drive pan while selection stands, which used to be taken straight back.
 *
 *  Standing framing offer re-armed every frame and dragged camera back to where it had
 *  aimed. Reported as touch bug, and neither touch- nor browser-specific. Glass is cleared
 *  first, since pinch starts at drawer's own right edge.
 */
export async function drivePanWhileSelected(page: Page, cdp: CDPSession): Promise<void> {
  await clearTheGlass(page);
  await page.keyboard.press('Home');
  await settleCamera(page);
  await page.evaluate(() => nimSelectOnly(nimSceneHandles()[0] ?? 0));
  await page.waitForTimeout(700); // Let framing ease finish before moving by hand.

  const before = await readCamera(page);
  await pinch(page, cdp, { x: 400, y: 400 }, { x: 650, y: 520 }, 80, 80);
  const at = await readCamera(page);
  await page.waitForTimeout(700);
  const after = await readCamera(page);
  report(
    'a pan while a selection stands is not taken back',
    spanPivot(before, at) > 0.3 && spanPivot(at, after) < 0.05,
    `panned ${spanPivot(before, at).toFixed(3)}, then drifted ${spanPivot(at, after).toFixed(4)}`,
  );
}
