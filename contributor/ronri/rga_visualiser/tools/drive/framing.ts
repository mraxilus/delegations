// Checks for what picking does to camera; not Nim because buttons are clicked through
//   Playwright, which node alone reaches, and because crossing would forfeit check compiler
//   makes over `page.evaluate` bodies naming bridge's derived exports.
//   Turning about point is what orbit is, so reader who picks objects and turns means to
//   turn about those. Framing used to leave pivot wherever it was whenever everything
//   picked was already on screen, which swung picked object around view instead.

import type { CDPSession, Page } from '@playwright/test';
import { MILLISECONDS_FRAME, evaluateOver } from './clock';
import {
  depthOf, readCamera, settleCamera, spanOf, spanPivot, type Stance,
} from './camera';
import { clearTheGlass } from './gestures';
import { waitFrames } from './frame';
import { report } from './report';
import { pinch, tapAt, touchAt } from './touch';

/** What page saw in frame its first turn went in: pick count, ease, and pivot's distance. */
interface TurnFirst {
  count: number;
  is_easing: boolean;
  middle: number[];
  short: number;
  azimuth: number;
}

declare global {
  interface Window {
    /** Reading of first frame whose ease carries, once tap has armed it. */
    __turn_first?: Promise<TurnFirst>;
  }
}

/** Frames watcher waits for ease before it reports none began; ease is 350 ms. */
const FRAMES_EASE_WAIT = 120;

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
  await settleCamera(page);
  const at_one = await readCamera(page);
  const place_one = await placeOf(page, first);
  await page.evaluate((one) => nimSelectToggle(one), second);
  await settleCamera(page);
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
  centre: number[];
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
      centre: [rect.left + rect.width / 2, rect.top + rect.height / 2],
    };
  }, handle);
}

/** Drive right-click pick from far out, which opens menu and brings camera in.
 *
 *  Wheel out six notches from `Home`, over first pickable point, so it is dot far off, then
 *  click 6 px off its anchor. Menu is up two frames in and keeps its inset from that object's own
 *  anchor; object settles in middle of frame however far off it was clicked; distance fell;
 *  pivot is object itself. Glass is cleared first, since drawer open would take click.
 */
export async function drivePointerPick(page: Page): Promise<void> {
  await clearTheGlass(page);
  await page.keyboard.press('Home');
  await settleCamera(page);
  const points = await pointsPickable(page);
  const picked = points[0];
  if (picked === undefined) return;

  // Wheel out over point about to be picked: wheel in free flight refers to object under
  //   pointer, and over empty sky does nothing (repository issue 535).
  const start = await page.evaluate((one) => {
    const rect = (document.getElementById('gl') as HTMLElement).getBoundingClientRect();
    const at = Array.from(nimAnchorScreen(one, rect.width, rect.height));
    return [rect.left + (at[0] ?? 0), rect.top + (at[1] ?? 0)];
  }, picked);
  await page.mouse.move(start[0] ?? 0, start[1] ?? 0);
  for (let notch = 0; notch < 6; notch += 1) {
    await page.mouse.wheel(0, 120);
    await waitFrames(page, 2);
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
  await waitFrames(page, 2);
  await page.mouse.click(aimed.x, aimed.y, { button: 'right' });
  await waitFrames(page, 2); // Ease under way, menu already up.
  const in_flight = await menuAndAnchor(page, picked);
  await settleCamera(page);
  await waitFrames(page, 2);
  const opened = await menuAndAnchor(page, picked);
  const near = await readCamera(page);
  // Shift pivot off object, so object's own anchor travels across frame.
  //   No camera gesture can move it now: pick made it pivot, and orbit, dolly and zoom
  //   all hold pivot at middle of frame. That is what centring buys, and it leaves
  //   moving pivot as only way to shift what menu follows.
  //   Shifted 1.5 units, about 80 px at this reach: far enough to prove menu followed,
  //   and short of frame's edge, where menu flips side to stay on screen.
  await page.evaluate(() => {
    const [eye, at] = [nimCameraEye(), nimCameraPivot()];
    const shift = [1.2, -0.8, 0.4];
    const [e, p] = [eye, at].map((one) => [0, 1, 2].map((i) => (one[i] ?? 0) + (shift[i] ?? 0)));
    nimPlaceCamera(
      e?.[0] ?? 0, e?.[1] ?? 0, e?.[2] ?? 0, p?.[0] ?? 0, p?.[1] ?? 0, p?.[2] ?? 0,
    );
  });
  await settleCamera(page);
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

/** Report three checks one pointer pick answers: menu, centring, and offset as object moves. */
function reportPointerPick(
  picked: Picked, camera: { far: Stance; near: Stance }, depth: number,
): void {
  // Menu keeps its offset from its object's anchor, not from where pointer clicked: pick
  //   carries object to middle of frame and menu rides with it. Offset is inset plus
  //   menu's own box, so it is read as held rather than against `INSET_MENU_POINTER`.
  //   Beside pointer holds at instant of click alone, which no frame can sample: ease has
  //   already carried object by two frames in.
  const from_anchor = (standing: MenuStanding): number[] =>
    [(standing.menu[0] ?? 0) - (standing.anchor[0] ?? 0),
      (standing.menu[1] ?? 0) - (standing.anchor[1] ?? 0)];
  const inset_flight = from_anchor(picked.in_flight);
  const inset_opened = from_anchor(picked.opened);
  const inset_panned = from_anchor(picked.panned);
  // How far object sits from middle of frame, which is where pick puts it.
  const offCentre = (standing: MenuStanding): number => Math.hypot(
    (standing.anchor[0] ?? 0) - (standing.centre[0] ?? 0),
    (standing.anchor[1] ?? 0) - (standing.centre[1] ?? 0),
  );
  const clicked_off = Math.hypot(
    (picked.aimed.anchor[0] ?? 0) - (picked.opened.centre[0] ?? 0),
    (picked.aimed.anchor[1] ?? 0) - (picked.opened.centre[1] ?? 0),
  );
  const moved = Math.hypot(
    (picked.panned.anchor[0] ?? 0) - (picked.opened.anchor[0] ?? 0),
    (picked.panned.anchor[1] ?? 0) - (picked.opened.anchor[1] ?? 0),
  );

  report(
    'a pointer pick opens the menu at once, and it rides its object in',
    picked.aimed.is_in_front && picked.in_flight.shown && picked.opened.shown &&
      Math.abs((inset_flight[0] ?? 0) - (inset_opened[0] ?? 0)) < 2 &&
      Math.abs((inset_flight[1] ?? 0) - (inset_opened[1] ?? 0)) < 2,
    `two frames in: menu ${picked.in_flight.shown ? 'shown' : 'hidden'}, corner ` +
      `${inset_flight.map((v) => v.toFixed(0))} px from the anchor; settled: menu ` +
      `${picked.opened.shown ? 'shown' : 'hidden'}, corner ` +
      `${inset_opened.map((v) => v.toFixed(0))} px from it`,
  );
  report(
    'and brings the picked object to the middle of the frame as it comes in to it',
    clicked_off > 20 && offCentre(picked.opened) < 2 &&
      picked.in_flight.distance < camera.far.distance - 0.01 &&
      camera.near.distance < 0.5 * camera.far.distance &&
      Math.abs(depth - camera.near.distance) < 0.01,
    `clicked ${clicked_off.toFixed(0)} px off the middle, settled ` +
      `${offCentre(picked.opened).toFixed(2)} px from it; distance ` +
      `${camera.far.distance.toFixed(2)} -> ${picked.in_flight.distance.toFixed(2)} in flight ` +
      `-> ${camera.near.distance.toFixed(2)}; object at depth ${depth.toFixed(3)}`,
  );
  report(
    'and keeps its offset from the object as the object moves',
    Math.abs((inset_panned[0] ?? 0) - (inset_opened[0] ?? 0)) < 2 &&
      Math.abs((inset_panned[1] ?? 0) - (inset_opened[1] ?? 0)) < 2 && moved > 50,
    `offset ${inset_opened.map((v) => v.toFixed(0))} at open, ` +
      `${inset_panned.map((v) => v.toFixed(0))} after the anchor moved ${moved.toFixed(0)} px`,
  );
}

/** Pick same object again once wheel has taken reader out until it is dot once more.
 *
 *  Offer it holds is renewed, and camera comes in again. Object is read again where wheel
 *  left it, and picked there.
 *  Wheel stands opposite object across middle of frame. Selection's wheel dollies about pivot
 *  wherever pointer stands, and object off pivot draws in toward middle as wheel goes out,
 *  with menu riding it.
 *    Not over object: menu riding object comes under pointer held there, and takes wheel
 *    from canvas.
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
  const middle = await page.evaluate(() => {
    const rect = (document.getElementById('gl') as HTMLElement).getBoundingClientRect();
    return { x: rect.left + 0.5 * rect.width, y: rect.top + 0.5 * rect.height };
  });
  await page.mouse.move(2 * middle.x - out.x, 2 * middle.y - out.y);
  // Wheel out past hundred units, well past thirty, where 0.08 of radius drops under floor
  //   dot's three pixels.
  for (let notch = 0; notch < 80; notch += 1) {
    await page.mouse.wheel(0, 120);
    await waitFrames(page, 2);
    if ((await readCamera(page)).distance > 100) break;
  }
  await settleCamera(page);
  const notched = await readCamera(page);
  const again = await anchorOf();
  await page.mouse.move(again.x + 4, again.y + 3);
  await waitFrames(page, 2);
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
  await waitFrames(page, 2);
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

/** Least angle, in degrees, sight stands off plane picked alone; `framing.ANGLE_PLANE_LEAST`. */
const DEGREES_PLANE_LEAST = 10;

/** Drive pick of ground from level view and from steep one, and assert only first turns.
 *
 *  Ruling of #454: plane seen along its own face draws as sliver, so its pick lifts view to
 *  ten degrees above it, by least turn. Pick slides pivot onto plane and turns nothing
 *  else, so steep view keeps its elevation.
 */
export async function drivePlaneLifted(page: Page): Promise<void> {
  await clearTheGlass(page);
  const ground = await page.evaluate(() => nimSceneHandles().find(
    (one) => nimObjectKindWord(one) === 'plane' && nimObjectLabel(one) === 'ground',
  ) ?? -1);
  const pickFrom = async (eye: number[]): Promise<number> => {
    await page.evaluate(() => clearSelection());
    await page.evaluate(
      (at) => nimPlaceCamera(at[0] ?? 0, at[1] ?? 0, at[2] ?? 0, 0, 0, 0), eye,
    );
    await settleCamera(page);
    await page.evaluate((one) => { selectOnly(one, null); hideSelectionMenu(); }, ground);
    await settleCamera(page);
    return page.evaluate(() => (nimCameraElevation() * 180) / Math.PI);
  };
  const degreesOf = (eye: number[]): number =>
    (Math.atan2(eye[2] ?? 0, Math.hypot(eye[0] ?? 0, eye[1] ?? 0)) * 180) / Math.PI;
  const eye_level = [30, 22.5, 0.9];
  const eye_steep = [24, 18, 16];
  const level = await pickFrom(eye_level);
  const steep = await pickFrom(eye_steep);
  await page.evaluate(() => clearSelection());
  report(
    'a plane picked from a level view lifts the view to ten degrees above it',
    Math.abs(level - DEGREES_PLANE_LEAST) < 0.01 && Math.abs(steep - degreesOf(eye_steep)) < 0.01,
    `elevation ${level.toFixed(3)} degrees after a pick from ${degreesOf(eye_level).toFixed(3)}, ` +
      `and ${steep.toFixed(3)} after a pick from ${degreesOf(eye_steep).toFixed(3)}`,
  );
}

/** Drive pan while selection stands, which used to be taken straight back.
 *
 *  Standing framing offer re-armed every frame and dragged camera back to where it had
 *  aimed. Reported as touch bug, and neither touch- nor browser-specific. Glass is cleared
 *  first, since pinch starts at drawer's own right edge.
 */
export async function drivePanWhileSelected(page: Page, devtools: CDPSession): Promise<void> {
  await clearTheGlass(page);
  await page.keyboard.press('Home');
  await settleCamera(page);
  await page.evaluate(() => nimSelectOnly(nimSceneHandles()[0] ?? 0));
  await settleCamera(page); // Let framing ease finish before moving by hand.

  const before = await readCamera(page);
  // Two fingers zoom while selection stands, so read eye rather than pivot: pivot
  //   sits on what is picked and stays there by design.
  await pinch(page, devtools, { x: 400, y: 400 }, { x: 400, y: 400 }, 160, 60);
  const at = await readCamera(page);
  await settleCamera(page);
  const after = await readCamera(page);
  report(
    'a move while a selection stands is not taken back',
    spanOf(before.eye, at.eye) > 0.3 && spanOf(at.eye, after.eye) < 0.05,
    `moved ${spanOf(before.eye, at.eye).toFixed(3)}, ` +
      `then drifted ${spanOf(at.eye, after.eye).toFixed(4)}`,
  );
}


/** Drive finger adding second object and turning at once, while pick still eases.
 *
 *  Long press picks one point, tap adds second, and turn starts before ease has carried
 *  pivot to their middle. Middle is where orbit turns about, so it is where pivot has to
 *  end, and middle of frame is where it has to stand. Turn used to stop ease wherever it
 *  was, which left pivot partway and every turn after swinging group about empty point.
 *  Turn goes in through `nimCameraTurnAt`, what finger's own move calls, from watcher page
 *  runs each frame: armed before tap goes out, it turns in first frame whose ease carries,
 *  right after build that armed it. No round trip of protocol then stands between arming and
 *  turn. With four of them there, pivot stood 0.042 to 0.609 short of middle on same code
 *  (repository issue 315): load, not rule, decided how much ease was left.
 *  Two points of check's own, undone after rather than removed: removal is edit of its own,
 *  and would stand on timeline where next check's undo expects edit that check made.
 */
export async function driveGroupTurnedAtOnce(page: Page, devtools: CDPSession): Promise<void> {
  await clearTheGlass(page);
  await page.keyboard.press('Home');
  await settleCamera(page);
  const count_found = await page.evaluate(() => nimSceneCount());
  const [one, two] = await page.evaluate(() => [[2, 1, 0.5], [0, 3, 1.5]].map((at) => {
    const model = new Array(16).fill(0);
    model[1] = at[0] ?? 0;
    model[2] = at[1] ?? 0;
    model[3] = at[2] ?? 0;
    model[4] = 1;
    return nimAddObject(model, 'turned', nimDefaultInk(), nimDefaultRadius(), 0);
  }));
  if (one === undefined || two === undefined) return;
  await page.evaluate(() => nimSelectClear());
  await settleCamera(page);
  const pixelOn = (handle: number): Promise<number[]> => page.evaluate((each) => {
    const at = Array.from(nimAnchorScreen(each, window.innerWidth, window.innerHeight));
    return [at[0] ?? 0, at[1] ?? 0];
  }, handle);

  // Hold past hold-to-select on first, then settle, as reader does before adding more.
  const at_one = await pixelOn(one);
  await tapAt(page, devtools, at_one[0] ?? 0, at_one[1] ?? 0, 1400);
  await settleCamera(page);
  // Arm watcher, then tap second; watcher turns in first frame whose ease carries.
  //   Its frame callback follows page's own in each frame, since page asks for next frame
  //   first, so it reads build that armed ease before `advance` has moved pivot.
  const at_two = await pixelOn(two);
  await page.evaluate(([a, b, frames_most]) => {
    window.__turn_first = new Promise<TurnFirst>((done) => {
      let frames = 0;
      const watch = (): void => {
        frames += 1;
        const is_easing = nimSelectionCount() === 2 && nimCameraCarrying();
        if (!is_easing && frames < (frames_most ?? 0)) {
          requestAnimationFrame(watch);
          return;
        }
        const p = Array.from(nimAnchorWorld(a ?? 0)), q = Array.from(nimAnchorWorld(b ?? 0));
        const middle = p.map((v, i) => 0.5*(v + (q[i] ?? 0)));
        const pivot = Array.from(nimCameraPivot());
        const reading = {
          count: nimSelectionCount(), is_easing, middle, azimuth: nimCameraAzimuth(),
          short: Math.hypot(...pivot.map((v, i) => v - (middle[i] ?? 0))),
        };
        if (is_easing) {
          nimSetCameraDragging(true);
          // Finger's step right from middle of canvas, where orbit holds front of its sphere.
          const canvas = document.getElementById('gl');
          const [wide, tall] = [canvas?.clientWidth ?? 0, canvas?.clientHeight ?? 0];
          const reach = 0.05 * Math.min(wide, tall) / Math.PI;
          nimCameraTurnAt(wide / 2, tall / 2, wide / 2 + reach, tall / 2, wide, tall);
        }
        done(reading);
      };
      requestAnimationFrame(watch);
    });
  }, [one, two, FRAMES_EASE_WAIT]);
  await touchAt(devtools, 'touchStart', [{ x: at_two[0] ?? 0, y: at_two[1] ?? 0 }]);
  await touchAt(devtools, 'touchEnd', []);
  const turned = await evaluateOver(
    page, (FRAMES_EASE_WAIT + 2) * MILLISECONDS_FRAME, () => window.__turn_first,
  );
  await page.evaluate(() => { delete window.__turn_first; });
  if (turned === undefined) return;
  for (let step = 1; step < 10; step += 1) {
    await waitFrames(page, 1);
    await page.evaluate(() => {
      const canvas = document.getElementById('gl');
      const [wide, tall] = [canvas?.clientWidth ?? 0, canvas?.clientHeight ?? 0];
      const reach = 0.05 * Math.min(wide, tall) / Math.PI;
      nimCameraTurnAt(wide / 2, tall / 2, wide / 2 + reach, tall / 2, wide, tall);
    });
  }
  await page.evaluate(() => nimSetCameraDragging(false));
  await settleCamera(page);

  const after = await readCamera(page);
  const { count, is_easing, middle, short, azimuth } = turned;
  // Pivot always stands at middle of frame, so pivot on their middle puts it there too.
  const span = spanOf(after.pivot, middle);
  report(
    'a finger that adds an object and turns at once turns about their middle',
    count === 2 && is_easing && short > 0.05 &&
      Math.abs(after.azimuth - azimuth) > 0.05 && span < 1e-3,
    `${count} picked; turn began with ease ${is_easing ? 'still carrying' : 'done'} and ` +
      `pivot ${short.toFixed(3)} short of their middle; turned ` +
      `${Math.abs(after.azimuth - azimuth).toFixed(3)} rad; pivot ended ` +
      `${span.toFixed(4)} from their middle`,
  );
  const count_left = await page.evaluate(() => {
    nimSelectClear();
    nimUndo();
    nimUndo();
    return nimSceneCount();
  });
  if (count_left !== count_found) {
    report(
      'the group turn leaves the scene as it found it', false,
      `${count_left} objects, found ${count_found}`,
    );
  }
  await settleCamera(page);
}


/** Separation far orbit is asked for, in world units: 150 m, floor orbit had before.
 *
 *  Frame rule holds point picked alone at its fill, about 217 m for demo's far stars, so camera
 *  ends there. Demo's farthest point stands 4.7 million units out, where world's doubles step by
 *  139 m.
 */
const SEPARATION_FAR = 1.0e-9;

/** Pixels far orbit's drag runs across, and how far picked object may stand off middle. */
const PIXELS_ORBIT_FAR = 180, PIXELS_MIDDLE_FAR = 1;

/** Steps far orbit's drag is cut into, one frame drawn after each. */
const STEPS_ORBIT_FAR = 6;

/** Drive pick of demo's farthest point, come in as close as frame rule lets, and orbit.
 *
 *  Point is picked, then picked by pointer once camera stands near it, so pivot is that point.
 *  Asked in to `SEPARATION_FAR`, frame rule stands camera at point's fill, where it fills
 *  frame and press on it turns view. Left drag across `PIXELS_ORBIT_FAR` px orbits it, and
 *  point stands within `PIXELS_MIDDLE_FAR` px of middle before and after: camera's stance,
 *  records and transform are held about view origin, near eye.
 *  As found (repository issue 535): point 4.72 million units out, 320 m away, stood 403.310 px
 *  off middle, and 180 px of drag turned view 0.000 rad.
 *  Geometry rather than time: pixels off middle read same on every machine.
 */
export async function driveFarOrbit(page: Page): Promise<void> {
  await clearTheGlass(page);
  const far = await page.evaluate(() => {
    let [handle, reach] = [-1, 0];
    for (const one of nimSceneHandles()) {
      if (nimObjectKindWord(one) !== 'point') continue;
      const at = Array.from(nimAnchorWorld(one));
      const span = Math.hypot(at[0] ?? 0, at[1] ?? 0, at[2] ?? 0);
      if (span > reach) [handle, reach] = [one, span];
    }
    return { handle, reach };
  });
  if (far.handle < 0) {
    report('the demo holds a point to orbit far out', false, 'no point found');
    return;
  }
  await page.evaluate((one) => nimSelectOnly(one), far.handle);
  await settleCamera(page);
  await page.evaluate((one) => nimPickByPointer(one), far.handle);
  await settleCamera(page);
  await page.evaluate((separation) => nimSetCameraDistance(separation), SEPARATION_FAR);
  await waitFrames(page, 2);
  await settleCamera(page);

  const offMiddle = (): Promise<number> => page.evaluate((one) => {
    const rect = (document.getElementById('gl') as HTMLElement).getBoundingClientRect();
    const at = Array.from(nimAnchorScreen(one, rect.width, rect.height));
    return (at[2] ?? 0) > 0.5
      ? Math.hypot((at[0] ?? 0) - rect.width / 2, (at[1] ?? 0) - rect.height / 2) : Infinity;
  }, far.handle);
  const before = { off: await offMiddle(), azimuth: await page.evaluate(() => nimCameraAzimuth()) };
  const separation = await page.evaluate(() => nimCameraDistance());

  const rect = await page.evaluate(() => {
    const box = (document.getElementById('gl') as HTMLElement).getBoundingClientRect();
    return { left: box.left, top: box.top, width: box.width, height: box.height };
  });
  const [x_start, y_row] = [
    rect.left + rect.width / 2 - PIXELS_ORBIT_FAR / 2, rect.top + rect.height / 2 + 120,
  ];
  await page.mouse.move(x_start, y_row);
  await waitFrames(page, 1);
  await page.mouse.down();
  for (let step = 1; step <= STEPS_ORBIT_FAR; step += 1) {
    await page.mouse.move(x_start + (PIXELS_ORBIT_FAR * step) / STEPS_ORBIT_FAR, y_row);
    await waitFrames(page, 1);
  }
  await page.mouse.up();
  await waitFrames(page, 2);
  const after = { off: await offMiddle(), azimuth: await page.evaluate(() => nimCameraAzimuth()) };
  await page.evaluate(() => nimSelectClear());
  await page.keyboard.press('Home');
  await settleCamera(page);

  const turned = Math.abs(after.azimuth - before.azimuth);
  report(
    'a point millions of units out, orbited close, stays in the middle of the frame',
    before.off <= PIXELS_MIDDLE_FAR && after.off <= PIXELS_MIDDLE_FAR && turned > 0.05,
    `point ${(far.reach / 1e6).toFixed(2)} million units out, ` +
      `${(separation * 149_597_870_700).toFixed(0)} m away; ` +
      `off middle ${before.off.toFixed(3)} px, then ${after.off.toFixed(3)} px after ` +
      `${PIXELS_ORBIT_FAR} px of drag turned ${turned.toFixed(3)} rad`,
  );
}
