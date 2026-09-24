// Checks for what finger does; not Nim because two-finger input goes through Chrome's own
//   debugging protocol, which only node reaches.
//   Playwright's touch API is single-touch, so pinch is dispatched through CDP directly.
//   Touch is where pinch regression lived, and no suite has finger at all.
//   Touch ids are never reused across gestures, and every gesture starts by asking page
//     whether any pointer is still down. Id reused from gesture before is indistinguishable
//     from finger left live by dropped or reordered lift: page keys pointers by id, so
//     stale finger is overwritten in silence and pair page reads is not pair harness sent
//     (repository issues 153 and 154). Fresh id leaves stale one standing, where guard names
//     it and gesture's own check fails on it, rather than passing or failing by luck.
//   Guard reads events browser delivered, tracked by listener harness installs, never
//     page's own bookkeeping: page's surface is not widened for test, and what is asserted
//     is what page received.

import type { CDPSession, Page } from '@playwright/test';
import { readCamera, settleCamera, slideOf, spanOf } from './camera';
import { waitFrames } from './frame';
import { report } from './report';
import { pixelOf } from './wheel';

/** One finger's place on screen. */
interface Finger {
  x: number;
  y: number;
}

/** Attribute on document root where harness's listener writes ids of pointers down. */
const ATTRIBUTE_POINTERS_DOWN = 'pointersDown';

/** Open channel two-finger gestures are dispatched down, and start watching pointers.
 *
 *  Listener on window, capturing, so it sees every pointer event page does whatever page
 *  does with it; ids still down are written to document root, where `pointersDown` reads
 *  them without any global page script would have to declare.
 */
export async function openTouch(page: Page): Promise<CDPSession> {
  await page.evaluate((attribute) => {
    const down = new Set<number>();
    const write = (): void => {
      document.documentElement.dataset[attribute] = [...down].join(',');
    };
    window.addEventListener('pointerdown', (e) => { down.add(e.pointerId); write(); }, true);
    const lift = (e: PointerEvent): void => { down.delete(e.pointerId); write(); };
    window.addEventListener('pointerup', lift, true);
    window.addEventListener('pointercancel', lift, true);
    write();
  }, ATTRIBUTE_POINTERS_DOWN);
  return page.context().newCDPSession(page);
}

/** Read ids of pointers page has seen go down and not yet come up. */
export async function pointersDown(page: Page): Promise<number[]> {
  const text = await page.evaluate(
    (attribute) => document.documentElement.dataset[attribute] ?? '', ATTRIBUTE_POINTERS_DOWN,
  );
  return text === '' ? [] : text.split(',').map(Number);
}

/** Report only where pointer is still down as gesture begins, naming it.
 *
 *  Silent when clean, so tally does not grow by one line per gesture; what it adds is
 *  name of stale pointer beside failure that follows, in place of two camera numbers.
 */
async function ensureLifted(page: Page, gesture: string): Promise<void> {
  const ids = await pointersDown(page);
  if (ids.length > 0) {
    report(`no pointer is still down before ${gesture}`, false, `ids ${ids.join(', ')}`);
  }
}

/** Which touch event is dispatched, as Chrome's protocol names them. */
export type TouchKind = 'touchStart' | 'touchMove' | 'touchEnd' | 'touchCancel';

// Ids of fingers down now, and next id to hand out: one id per finger per gesture, never
//   reused, so finger left standing from gesture before cannot wear new finger's id.
let ids_down: number[] = [];
let id_touch_next = 1;

/** Dispatch one touch event, however many fingers are down. */
export async function touchAt(
  cdp: CDPSession, kind: TouchKind, points: Finger[],
): Promise<void> {
  if (kind === 'touchStart') {
    ids_down = points.map(() => { id_touch_next += 1; return id_touch_next; });
  } else if (kind === 'touchMove' && points.length !== ids_down.length) {
    throw new Error(
      `a touchMove must move every finger down; got ${points.length} of ${ids_down.length}`,
    );
  }
  await cdp.send('Input.dispatchTouchEvent', {
    type: kind,
    touchPoints: points.map((point, index) => ({
      x: point.x, y: point.y, id: ids_down[index] ?? 0,
    })),
  });
  if (kind === 'touchEnd' || kind === 'touchCancel') ids_down = [];
}

/** Put two fingers down and draw them apart or together, moving their midpoint. */
export async function pinch(
  page: Page, cdp: CDPSession, mid_from: Finger, mid_to: Finger,
  spread_from: number, spread_to: number,
): Promise<void> {
  await ensureLifted(page, 'a pinch');
  await touchAt(cdp, 'touchStart', [
    { x: mid_from.x - spread_from, y: mid_from.y },
    { x: mid_from.x + spread_from, y: mid_from.y },
  ]);
  for (let step = 1; step <= 8; step += 1) {
    const spread = spread_from + ((spread_to - spread_from) * step) / 8;
    const mid = {
      x: mid_from.x + ((mid_to.x - mid_from.x) * step) / 8,
      y: mid_from.y + ((mid_to.y - mid_from.y) * step) / 8,
    };
    await touchAt(cdp, 'touchMove', [
      { x: mid.x - spread, y: mid.y }, { x: mid.x + spread, y: mid.y },
    ]);
    await waitFrames(page, 2);
  }
  await touchAt(cdp, 'touchEnd', []);
  await settleCamera(page);
}

/** Turn two fingers about their own midpoint, holding their separation. */
export async function twist(
  page: Page, cdp: CDPSession, mid: Finger, spread: number, radians: number,
): Promise<void> {
  await ensureLifted(page, 'a twist');
  const at = (turn: number) => [
    { x: mid.x - spread*Math.cos(turn), y: mid.y - spread*Math.sin(turn) },
    { x: mid.x + spread*Math.cos(turn), y: mid.y + spread*Math.sin(turn) },
  ];
  await touchAt(cdp, 'touchStart', at(0));
  for (let step = 1; step <= 8; step += 1) {
    await touchAt(cdp, 'touchMove', at((radians*step)/8));
    await waitFrames(page, 2);
  }
  await touchAt(cdp, 'touchEnd', []);
  await settleCamera(page);
}

/** Put one finger down for however long, then lift it. */
export async function tapAt(
  page: Page, cdp: CDPSession, x: number, y: number, milliseconds = 60,
): Promise<void> {
  await ensureLifted(page, 'a tap');
  await touchAt(cdp, 'touchStart', [{ x, y }]);
  // Wall time, deliberately: how long finger stays down is what caller asked for, and long
  //   press is decided by that duration rather than by anything page reports.
  await page.waitForTimeout(milliseconds);
  await touchAt(cdp, 'touchEnd', []);
  await settleCamera(page);
}

/** How much of one finger drag to perform, for gestures checked in two halves. */
export interface DragParts {
  press?: boolean;
  lift?: boolean;
}

/** Drag one finger from place to place, in steps application can follow.
 *
 *  Press and lift are separable, so check can pause mid-drag and read what opened under
 *  finger before letting go.
 */
export async function dragFinger(
  page: Page, cdp: CDPSession, from: number[], onto: number[], parts: DragParts = {},
): Promise<void> {
  const { press = true, lift = true } = parts;
  const start = { x: from[0] ?? 0, y: from[1] ?? 0 };
  const end = { x: onto[0] ?? 0, y: onto[1] ?? 0 };
  if (press) {
    await ensureLifted(page, 'a finger drag');
    await touchAt(cdp, 'touchStart', [start]);
    for (let step = 1; step <= 10; step += 1) {
      await touchAt(cdp, 'touchMove', [{
        x: start.x + ((end.x - start.x) * step) / 10,
        y: start.y + ((end.y - start.y) * step) / 10,
      }]);
      await waitFrames(page, 2);
    }
  }
  if (lift) {
    await touchAt(cdp, 'touchEnd', []);
    await settleCamera(page);
  }
}

/** Drive pinch zoom, which is what finger has instead of wheel. */
export async function drivePinch(page: Page, cdp: CDPSession): Promise<void> {
  await page.keyboard.press('Home');
  await settleCamera(page);

  // Pinch well off centre, which is where aimed zoom shows itself: midpoint never moves,
  //   so pinch that also translated view would drag it toward that corner.
  const mid = { x: 300, y: 300 };
  const before = await readCamera(page);
  await pinch(page, cdp, mid, mid, 40, 160);
  const after = await readCamera(page);

  report(
    'a pinch zooms',
    after.distance < before.distance * 0.8,
    `distance ${before.distance.toFixed(2)} -> ${after.distance.toFixed(2)}`,
  );
  report(
    'a pinch leaves the orbit alone',
    Math.abs(after.azimuth - before.azimuth) < 1e-3,
    `azimuth ${before.azimuth.toFixed(4)} -> ${after.azimuth.toFixed(4)}`,
  );

  // Twist rolls, which is sixth degree of freedom and has no keyboard beside it on touch.
  //   Read against eye and sight, which roll leaves exactly alone.
  await page.keyboard.press('Home');
  await settleCamera(page);
  const upright = await readCamera(page);
  await twist(page, cdp, { x: 400, y: 400 }, 120, 0.9);
  const rolled = await readCamera(page);
  const across = slideOf(upright, rolled);
  report(
    'a twist rolls, and moves the eye no distance at all',
    across < 1e-3 && spanOf(upright.eye, rolled.eye) < 1e-3 &&
      Math.abs(rolled.distance - upright.distance) < 1e-6,
    `eye moved ${spanOf(upright.eye, rolled.eye).toFixed(6)} units`,
  );
  report(
    'and a twist leaves the sight where it was pointing',
    Math.abs(rolled.azimuth - upright.azimuth) < 1e-3,
    `azimuth ${upright.azimuth.toFixed(4)} -> ${rolled.azimuth.toFixed(4)}`,
  );

  // Direction, read off screen: picture must turn whichever way fingers turned, and
  //   sign went through unturned, so twist rolled against them.
  await page.keyboard.press('Home');
  await settleCamera(page);
  const handle = await page.evaluate(() => nimSceneHandles()[0] ?? 0);
  const seen = async (): Promise<number[]> => page.evaluate((one) => Array.from(
    nimAnchorScreen(one, window.innerWidth, window.innerHeight),
  ), handle);
  const centre = await page.evaluate(
    () => [window.innerWidth / 2, window.innerHeight / 2],
  );
  const start = await seen();
  // Fingers turned clockwise on screen, since y grows down and this angle grows.
  await twist(page, cdp, { x: 400, y: 400 }, 120, 0.9);
  const swung = await seen();
  const angleOf = (at: number[]): number => Math.atan2(
    (at[1] ?? 0) - (centre[1] ?? 0), (at[0] ?? 0) - (centre[0] ?? 0),
  );
  let carried = angleOf(swung) - angleOf(start);
  if (carried > Math.PI) carried -= 2 * Math.PI;
  if (carried < -Math.PI) carried += 2 * Math.PI;
  report(
    'and a twist carries the picture the way the fingers turned',
    carried > 0.2,
    `fingers turned +0.900, picture turned ${carried.toFixed(3)} about the frame's middle`,
  );
}

/** Read whether finger landing at `at` would turn camera rather than start construction.
 *
 *  Asks same question press asks, through same two bridge calls, before any finger lands:
 *  press over object would build rather than turn, and check would then read nothing.
 */
async function isOpenSky(page: Page, at: Finger): Promise<boolean> {
  return page.evaluate(({ x, y }) => {
    nimUpdateCursor(x, y);
    nimUpdateHover(window.innerWidth, window.innerHeight);
    return !nimCanTouchConstruct();
  }, at);
}

/** Drive one finger's turn as turntable, which follows finger and passes over top.
 *
 *  Sideways swipe with nothing picked is where turning about camera's own axes, with roll
 *  put back after, sank sight: each step tipped it down and roll put back only horizon.
 *  Free aim now carries sky under finger, one for one, so swipe back undoes swipe.
 *  Downward drag with object picked climbs past straight down onto far side, which is
 *  what bounded turntable refused.
 */
export async function driveFingerTurntable(page: Page, cdp: CDPSession): Promise<void> {
  await page.keyboard.press('Home');
  await settleCamera(page);
  await page.evaluate(() => nimSelectClear());
  await settleCamera(page);

  const sky = { x: 160, y: 170 };
  if (!(await isOpenSky(page, sky))) {
    report('a finger starts its turn on open sky', false, `(${sky.x}, ${sky.y}) is not sky`);
    return;
  }
  // Free aim carries sky under finger with it, so drag that comes back brings sight back.
  //   Rate turned sight by angle screen does not show, and drift of its steps stayed.
  const standing = await readCamera(page);
  const level = await page.evaluate(() => nimCameraElevation());
  await dragFinger(page, cdp, [sky.x, sky.y], [sky.x + 600, sky.y]);
  const swung = await readCamera(page);
  await dragFinger(page, cdp, [sky.x + 600, sky.y], [sky.x, sky.y]);
  const back = await readCamera(page);
  const level_back = await page.evaluate(() => nimCameraElevation());
  report(
    'a finger swiped away and back turns the sight and brings it back',
    Math.abs(swung.azimuth - standing.azimuth) > 0.3 &&
      Math.abs(back.azimuth - standing.azimuth) < 1e-5 && Math.abs(level_back - level) < 1e-5 &&
      spanOf(standing.eye, back.eye) < 1e-6,
    `azimuth ${standing.azimuth.toFixed(4)} -> ${swung.azimuth.toFixed(4)} -> ` +
      `${back.azimuth.toFixed(4)}, elevation ${level.toFixed(6)} -> ${level_back.toFixed(6)}`,
  );

  // Picture follows finger one for one with nothing picked: swipe right and down carries
  //   object beside finger right and down by as much. Mouse aims instead.
  //   Finger lands 40 px left of object, which is nearest open sky reaches it, so what it
  //   carries and what is read stand close enough on screen to move alike.
  await page.keyboard.press('Home');
  await settleCamera(page);
  const beside = await page.evaluate(() => nimSceneHandles()[0] ?? -1);
  const seenBeside = async (): Promise<number[]> => page.evaluate((one) => Array.from(
    nimAnchorScreen(one, window.innerWidth, window.innerHeight),
  ), beside);
  const seen_before = await seenBeside();
  const landing = { x: (seen_before[0] ?? 0) - 40, y: seen_before[1] ?? 0 };
  if (!(await isOpenSky(page, landing))) {
    report('a finger lands on open sky beside an object', false, 'no sky 40 px left of it');
    return;
  }
  await dragFinger(page, cdp, [landing.x, landing.y], [landing.x + 60, landing.y + 40]);
  const seen_after = await seenBeside();
  const across = (seen_after[0] ?? 0) - (seen_before[0] ?? 0);
  const down = (seen_after[1] ?? 0) - (seen_before[1] ?? 0);
  report(
    'and the picture follows a finger with nothing picked, one for one',
    Math.abs(across / 60 - 1) < 0.05 && Math.abs(down / 40 - 1) < 0.05,
    `object beside finger moved ${across.toFixed(1)} px across and ${down.toFixed(1)} px ` +
      'down, for a finger moved 60 and 40',
  );

  // Picked object anchors orbit, and ease has to finish before drag reads anything.
  await page.keyboard.press('Home');
  await settleCamera(page);
  const handle = await page.evaluate(() => nimSceneHandles()[1] ?? -1);
  if (handle < 0) {
    report('the scene holds an object to orbit', false, 'no second object');
    return;
  }
  await page.evaluate((one) => nimSelectOnly(one), handle);
  await settleCamera(page);
  if (!(await isOpenSky(page, sky))) {
    report('a finger starts its orbit on open sky', false, `(${sky.x}, ${sky.y}) is not sky`);
    await page.evaluate(() => nimSelectClear());
    return;
  }
  const before = await readCamera(page);
  // Far enough to climb 0.4 radians past straight down, at finger's half turn per short
  //   side of canvas.
  const reach = await page.evaluate(() => {
    const canvas = document.getElementById('gl');
    const short = Math.min(canvas?.clientWidth ?? 0, canvas?.clientHeight ?? 0);
    return (0.5 * Math.PI - nimCameraElevation() + 0.4) * short / Math.PI;
  });
  await dragFinger(page, cdp, [sky.x, sky.y], [sky.x, sky.y + reach]);
  const after = await readCamera(page);
  const outward = (camera: typeof before): number[] => [
    (camera.eye[0] ?? 0) - (camera.pivot[0] ?? 0), (camera.eye[1] ?? 0) - (camera.pivot[1] ?? 0),
  ];
  const [was, now_at] = [outward(before), outward(after)];
  const facing = (was[0] ?? 0) * (now_at[0] ?? 0) + (was[1] ?? 0) * (now_at[1] ?? 0);
  report(
    'a finger dragged down orbits over the top and onto the far side',
    facing < 0 && spanOf(before.pivot, after.pivot) < 1e-6 &&
      Math.abs(after.distance - before.distance) < 1e-6,
    `eye's level offset turned ${facing < 0 ? 'round' : 'back'}, ` +
      `pivot moved ${spanOf(before.pivot, after.pivot).toFixed(6)}`,
  );
  await page.evaluate(() => nimSelectClear());
  await page.keyboard.press('Home');
  await settleCamera(page);
}

/** Drive long press and tap, which is how finger selects. */
export async function driveTouchSelect(page: Page, cdp: CDPSession): Promise<void> {
  await page.keyboard.press('Home');
  await settleCamera(page);
  await page.evaluate(() => nimSelectClear());
  await settleCamera(page);

  const handles = await page.evaluate(() => nimSceneHandles());
  const first = handles[1];
  if (first === undefined) {
    report('the scene holds objects to press', false, `${handles.length} objects`);
    return;
  }
  const pixel_first = await pixelOf(page, first);
  if (pixel_first === null) {
    report('the first object stands on screen', false, 'no pixel');
    return;
  }

  // Hold well past hold-to-select, only way finger has to start selection.
  await tapAt(page, cdp, pixel_first[0] ?? 0, pixel_first[1] ?? 0, 1400);
  const count_held = await page.evaluate(() => nimSelectionCount());
  report('a long press selects what it is over', count_held === 1, `${count_held} selected`);

  // Read second object's pixel afresh, after ease: picking turns orbit about what was
  //   picked, so view is still gliding when press lets go, and pixel read before names
  //   where that object *was*.
  await settleCamera(page);
  const second = handles[2];
  if (second === undefined) return;
  const pixel_second = await pixelOf(page, second);
  if (pixel_second === null) return;
  await tapAt(page, cdp, pixel_second[0] ?? 0, pixel_second[1] ?? 0);
  const count_tapped = await page.evaluate(() => nimSelectionCount());
  report(
    'a tap toggles a second object into the selection',
    count_tapped === 2, `${count_tapped} selected`,
  );

  await settleCamera(page);
  // Find pixel with nothing under it: picks above moved view, so no corner is empty by
  //   right. Lower half only, since page's own controls stand along top and down right.
  const empty = await page.evaluate((size) => {
    const candidates: Array<[number, number]> = [
      [40, size.height - 40], [40, size.height - 140], [140, size.height - 40],
      [size.width / 2, size.height - 40], [size.width / 2, size.height - 140],
      [40, size.height / 2],
    ];
    for (const [x, y] of candidates) {
      nimUpdateCursor(x, y);
      nimUpdateHover(size.width, size.height);
      if (nimHoverHandle() < 0 || nimIsHoverBackdrop()) return [x, y];
    }
    return candidates[0] ?? [40, 40];
  }, { width: 1200, height: 900 });
  await tapAt(page, cdp, empty[0] ?? 0, empty[1] ?? 0);
  const count_empty = await page.evaluate(() => nimSelectionCount());
  report(
    'a tap on empty space clears the selection', count_empty === 0, `${count_empty} selected`,
  );
}
