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
//   Each touch event is waited on until page holds fingers where it put them, before any
//     simulated time moves. Protocol answers before page sees touch move: browser holds move
//     for its next real frame, which lands anywhere inside following simulated span, so same
//     pinch zoomed by different amounts on fresh pages. Playwright's own mouse already waits.
//     Places, not count of events: two fingers put down together arrive as two starts.
//     Move inside browser's touch slop, 15 px about where finger went down, never arrives;
//     wait ends after `FRAMES_TOUCH_MOST` real rendering steps, which is where any other move
//     has long arrived.

import type { CDPSession, Page } from '@playwright/test';
import { advance } from './clock';
import { depthOf, forwardOf, readCamera, settleCamera, slideOf, spanOf } from './camera';
import { waitFrames } from './frame';
import { report } from './report';
import { pixelOf } from './wheel';

/** One finger's place on screen. */
export interface Finger {
  x: number;
  y: number;
}

/** Attribute on document root where harness's listener writes ids of pointers down. */
const ATTRIBUTE_POINTERS_DOWN = 'pointersDown';

/** Attribute on document root where harness's listener writes where page holds fingers. */
const ATTRIBUTE_TOUCHES_HELD = 'touchesHeld';

/** Real rendering steps touch is waited on before browser is taken to have dropped it. */
const FRAMES_TOUCH_MOST = 3;

/** Pixels finger page holds may stand from where harness put it. */
const PIXELS_TOUCH_SLACK = 1;

/** Open channel two-finger gestures are dispatched down, and start watching pointers.
 *
 *  Listener on window, capturing, so it sees every pointer event page does whatever page
 *  does with it; ids still down are written to document root, where `pointersDown` reads
 *  them without any global page script would have to declare.
 */
export async function openTouch(page: Page): Promise<CDPSession> {
  await page.evaluate((given) => {
    const down = new Set<number>();
    const write = (): void => {
      document.documentElement.dataset[given.down] = [...down].join(',');
    };
    window.addEventListener('pointerdown', (e) => { down.add(e.pointerId); write(); }, true);
    const lift = (e: PointerEvent): void => { down.delete(e.pointerId); write(); };
    window.addEventListener('pointerup', lift, true);
    window.addEventListener('pointercancel', lift, true);
    write();
    const hold = (e: TouchEvent): void => {
      document.documentElement.dataset[given.held] = JSON.stringify(
        Array.from(e.touches, (touch) => [touch.clientX, touch.clientY]),
      );
    };
    for (const kind of ['touchstart', 'touchmove', 'touchend', 'touchcancel'] as const) {
      window.addEventListener(kind, hold, { capture: true, passive: true });
    }
  }, { down: ATTRIBUTE_POINTERS_DOWN, held: ATTRIBUTE_TOUCHES_HELD });
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
  devtools: CDPSession, kind: TouchKind, points: Finger[],
): Promise<void> {
  if (kind === 'touchStart') {
    ids_down = points.map(() => { id_touch_next += 1; return id_touch_next; });
  } else if (kind === 'touchMove' && points.length !== ids_down.length) {
    throw new Error(
      `a touchMove must move every finger down; got ${points.length} of ${ids_down.length}`,
    );
  }
  await devtools.send('Input.dispatchTouchEvent', {
    type: kind,
    touchPoints: points.map((point, index) => ({
      x: point.x, y: point.y, id: ids_down[index] ?? 0,
    })),
  });
  const lifted = kind === 'touchEnd' || kind === 'touchCancel';
  if (lifted) ids_down = [];
  await waitTouchHeld(devtools, lifted ? [] : points);
}

/** Wait, with simulated time held, until page holds fingers as sent or browser dropped move. */
async function waitTouchHeld(devtools: CDPSession, points: Finger[]): Promise<void> {
  const asked = `document.documentElement.dataset.${ATTRIBUTE_TOUCHES_HELD} ?? '[]'`;
  const frame = 'new Promise((done) => (window.__frame_real ?? requestAnimationFrame)(done))';
  const order = (a: number[], b: number[]): number =>
    (a[0] ?? 0) - (b[0] ?? 0) || (a[1] ?? 0) - (b[1] ?? 0);
  const wanted = points.map((point) => [point.x, point.y]).sort(order);
  for (let step = 0; step <= FRAMES_TOUCH_MOST; step += 1) {
    const answer = await devtools.send(
      'Runtime.evaluate', { expression: asked, returnByValue: true },
    );
    const held = (JSON.parse(String(answer.result.value)) as number[][]).sort(order);
    const is_held = held.length === wanted.length && held.every((one, index) =>
      Math.abs((one[0] ?? 0) - (wanted[index]?.[0] ?? 0)) <= PIXELS_TOUCH_SLACK &&
      Math.abs((one[1] ?? 0) - (wanted[index]?.[1] ?? 0)) <= PIXELS_TOUCH_SLACK);
    if (is_held) return;
    if (step < FRAMES_TOUCH_MOST) {
      await devtools.send('Runtime.evaluate', { expression: frame, awaitPromise: true });
    }
  }
}

/** Put two fingers down and draw them apart or together, moving their midpoint. */
export async function pinch(
  page: Page, devtools: CDPSession, mid_from: Finger, mid_to: Finger,
  spread_from: number, spread_to: number,
): Promise<void> {
  await ensureLifted(page, 'a pinch');
  await touchAt(devtools, 'touchStart', [
    { x: mid_from.x - spread_from, y: mid_from.y },
    { x: mid_from.x + spread_from, y: mid_from.y },
  ]);
  for (let step = 1; step <= 8; step += 1) {
    const spread = spread_from + ((spread_to - spread_from) * step) / 8;
    const mid = {
      x: mid_from.x + ((mid_to.x - mid_from.x) * step) / 8,
      y: mid_from.y + ((mid_to.y - mid_from.y) * step) / 8,
    };
    await touchAt(devtools, 'touchMove', [
      { x: mid.x - spread, y: mid.y }, { x: mid.x + spread, y: mid.y },
    ]);
    await waitFrames(page, 2);
  }
  await touchAt(devtools, 'touchEnd', []);
  await settleCamera(page);
}

/** Put one finger down for however long, then lift it. */
export async function tapAt(
  page: Page, devtools: CDPSession, x: number, y: number, milliseconds = 60,
): Promise<void> {
  await ensureLifted(page, 'a tap');
  await touchAt(devtools, 'touchStart', [{ x, y }]);
  // Simulated span: how long finger stays down is what caller asked for, and long press is
  //   decided by that duration rather than by anything page reports.
  await advance(page, milliseconds);
  await touchAt(devtools, 'touchEnd', []);
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
  page: Page, devtools: CDPSession, from: number[], onto: number[], parts: DragParts = {},
): Promise<void> {
  const { press = true, lift = true } = parts;
  const start = { x: from[0] ?? 0, y: from[1] ?? 0 };
  const end = { x: onto[0] ?? 0, y: onto[1] ?? 0 };
  if (press) {
    await ensureLifted(page, 'a finger drag');
    await touchAt(devtools, 'touchStart', [start]);
    for (let step = 1; step <= 10; step += 1) {
      await touchAt(devtools, 'touchMove', [{
        x: start.x + ((end.x - start.x) * step) / 10,
        y: start.y + ((end.y - start.y) * step) / 10,
      }]);
      await waitFrames(page, 2);
    }
  }
  if (lift) {
    await touchAt(devtools, 'touchEnd', []);
    await settleCamera(page);
  }
}

/** Place two fingers as one hand would carry them: spread and turned about their middle,
 *  then slid. */
export function asHand(
  fingers: [Finger, Finger], spread: number, turn: number, slide: Finger,
): [Finger, Finger] {
  const [first, second] = fingers;
  const middle = { x: 0.5 * (first.x + second.x), y: 0.5 * (first.y + second.y) };
  const carried = (finger: Finger): Finger => {
    const across = finger.x - middle.x;
    const down = finger.y - middle.y;
    return {
      x: middle.x + slide.x + spread * (Math.cos(turn) * across - Math.sin(turn) * down),
      y: middle.y + slide.y + spread * (Math.sin(turn) * across + Math.cos(turn) * down),
    };
  };
  return [carried(first), carried(second)];
}

/** Put two fingers down where `at(0)` says, carry them through `at`, and lift at `at(1)`.
 *
 *  For gestures no one spread, slide or twist names: grip holds what fingers took whatever
 *  path they take, so check names path and reads its end.
 */
export async function moveFingers(
  page: Page, devtools: CDPSession, at: (along: number) => [Finger, Finger], steps = 8,
): Promise<void> {
  await ensureLifted(page, 'two fingers');
  await touchAt(devtools, 'touchStart', at(0));
  for (let step = 1; step <= steps; step += 1) {
    await touchAt(devtools, 'touchMove', at(step / steps));
    await waitFrames(page, 2);
  }
  await touchAt(devtools, 'touchEnd', []);
  await settleCamera(page);
}

/** Find handle of object labelled `label`, or -1. */
export async function handleLabelled(page: Page, label: string): Promise<number> {
  return page.evaluate(
    (name) => nimSceneHandles().find((one) => nimObjectLabel(one) === name) ?? -1, label,
  );
}

/** Read pixel object `handle` is drawn at, as finger landing on it. */
export async function fingerOn(page: Page, handle: number): Promise<Finger> {
  const at = await pixelOf(page, handle);
  return { x: at?.[0] ?? 0, y: at?.[1] ?? 0 };
}

/** Measure pixels between where object `handle` is drawn and where `finger` stands. */
export async function slipOf(page: Page, handle: number, finger: Finger): Promise<number> {
  const at = await pixelOf(page, handle);
  return at === null ? Infinity : Math.hypot((at[0] ?? 0) - finger.x, (at[1] ?? 0) - finger.y);
}

/** Read whether finger landing at `at` would find empty sky: nothing under it but backdrop. */
async function isSkyAt(page: Page, at: Finger): Promise<boolean> {
  return page.evaluate(({ x, y }) => {
    nimUpdateCursor(x, y);
    nimUpdateHover(window.innerWidth, window.innerHeight);
    return nimHoverHandle() < 0 || nimIsHoverBackdrop();
  }, at);
}

/** Place pixels grip holds what each finger took at: fingers as they stand, less slop.
 *
 *  Page's own rule, `interaction.fingersHeld`, read again here as oracle: middle is
 *  fingers' own, and gap and angle count from slop's edge once fingers part, close or turn
 *  past it. Gestures here part and turn one way only, so end alone says whether they crossed.
 */
function heldOf(
  landed: [Finger, Finger], now: [Finger, Finger], slop_gap: number, slop_twist: number,
): [Finger, Finger] {
  const gapOf = (pair: [Finger, Finger]): number =>
    Math.hypot(pair[1].x - pair[0].x, pair[1].y - pair[0].y);
  const angleOf = (pair: [Finger, Finger]): number =>
    Math.atan2(pair[1].y - pair[0].y, pair[1].x - pair[0].x);
  const [gap_landed, gap] = [gapOf(landed), gapOf(now)];
  let turned = angleOf(now) - angleOf(landed);
  if (turned > Math.PI) turned -= 2 * Math.PI;
  if (turned < -Math.PI) turned += 2 * Math.PI;
  const gap_held = Math.abs(gap - gap_landed) > slop_gap
    ? (gap_landed * Math.max(gap, 1)) / (gap_landed + Math.sign(gap - gap_landed) * slop_gap)
    : gap_landed;
  const angle_held = angleOf(landed) +
    (Math.abs(turned) > slop_twist ? turned - Math.sign(turned) * slop_twist : 0);
  const middle = { x: 0.5 * (now[0].x + now[1].x), y: 0.5 * (now[0].y + now[1].y) };
  const across = 0.5 * gap_held * Math.cos(angle_held);
  const down = 0.5 * gap_held * Math.sin(angle_held);
  return [
    { x: middle.x - across, y: middle.y - down }, { x: middle.x + across, y: middle.y + down },
  ];
}

/** Read largest change in camera's turn, roll included: motor's rotation coefficients. */
async function turnOf(page: Page, before: number[]): Promise<number> {
  const after = await page.evaluate(() => Array.from(nimCameraMotor()));
  return Math.max(...[5, 6, 7, 15].map((at) => Math.abs((after[at] ?? 0) - (before[at] ?? 0))));
}

/** Drive two fingers, which hold what each touched, less slop, as mouse holds what it grabs.
 *
 *  Ruled on repository issue 592: each finger stays on point it touched, and view moves to
 *  hold that; selection is orbited, so pivot stays on it. Zoom and twist wait for slop, as
 *  they did before grip, and count from its edge. Over empty sky in free flight, finger
 *  holds place at frame's own scale, so zoom out goes on once objects shrink from under it.
 */
export async function drivePinch(page: Page, devtools: CDPSession): Promise<void> {
  const [slop_gap, slop_twist] = await page.evaluate(() => [nimTapSlop(), nimTwistSlop()]);
  await page.keyboard.press('Home');
  await settleCamera(page);

  // Fingers land on two points at two depths and move as one hand: spread, twist and slide
  //   at once. Each point staying under pixel grip holds it at is whole rule.
  const first = await handleLabelled(page, 'a');
  const second = await handleLabelled(page, 'c');
  const landed: [Finger, Finger] = [await fingerOn(page, first), await fingerOn(page, second)];
  const hand = (along: number): [Finger, Finger] =>
    asHand(landed, 1 + 0.3 * along, 0.25 * along, { x: 30 * along, y: 20 * along });
  const before = await readCamera(page);
  await moveFingers(page, devtools, hand);
  const after = await readCamera(page);
  const [held_first, held_second] = heldOf(landed, hand(1), slop_gap, slop_twist);
  const slips = [await slipOf(page, first, held_first), await slipOf(page, second, held_second)];
  report(
    'two fingers hold the points they touched, less slop, through a spread, a twist and a slide',
    Math.max(...slips) <= 1 && spanOf(before.eye, after.eye) > 0.1,
    `points ${slips.map((slip) => slip.toFixed(2)).join(' and ')} px off where grip holds ` +
      `them, eye moved ${spanOf(before.eye, after.eye).toFixed(3)}`,
  );
  // Sight read off eye and pivot through float32, so bound is float32's.
  report(
    'and turn no sight with nothing selected, only slide and roll',
    spanOf(forwardOf(before), forwardOf(after)) < 1e-6,
    `sight moved ${spanOf(forwardOf(before), forwardOf(after)).toExponential(2)}`,
  );

  // Fingers on empty sky hold places at depth of object shown nearest them, near pivot's
  //   depth: spread flies eye toward them, slide carries it across, and pivot comes to
  //   their depth, never short of it.
  await page.keyboard.press('Home');
  await settleCamera(page);
  const sky: [Finger, Finger] = [{ x: 300, y: 110 }, { x: 600, y: 110 }];
  const is_sky = (await isSkyAt(page, sky[0])) && (await isSkyAt(page, sky[1]));
  const stood = await readCamera(page);
  const motor_stood = await page.evaluate(() => Array.from(nimCameraMotor()));
  await moveFingers(
    page, devtools, (along) => asHand(sky, 1 + 1.5 * along, 0, { x: 40 * along, y: 30 * along }),
  );
  const flown = await readCamera(page);
  const turn_sky = await turnOf(page, motor_stood);
  report(
    'two fingers on empty sky zoom and slide the view, and draw the pivot in with them',
    is_sky && depthOf(stood, flown.eye) > 0.1 && turn_sky < 1e-6 &&
      flown.distance < stood.distance && flown.distance > 0.2 * stood.distance,
    `on sky ${is_sky}, eye came ${depthOf(stood, flown.eye).toFixed(3)} in, turned ` +
      `${turn_sky.toExponential(2)}, separation ${stood.distance.toFixed(4)} -> ` +
      `${flown.distance.toFixed(4)}`,
  );

  // Fingers carried together wobble inside slop: they slide alone, and neither zoom nor roll.
  await page.keyboard.press('Home');
  await settleCamera(page);
  const carried = await readCamera(page);
  const motor_carried = await page.evaluate(() => Array.from(nimCameraMotor()));
  await moveFingers(page, devtools, (along) => {
    const wobble = Math.round(8 * along) % 2 === 0 ? 1 : -1;
    return asHand(
      sky, 1 + (along > 0 ? (wobble * 8) / 300 : 0), along > 0 ? wobble * 0.15 : 0,
      { x: 120 * along, y: 60 * along },
    );
  });
  const slid = await readCamera(page);
  const turn_carried = await turnOf(page, motor_carried);
  report(
    'two fingers carried together, wobbling inside the slop, slide and neither zoom nor roll',
    slideOf(carried, slid) > 0.1 && Math.abs(depthOf(carried, slid.eye)) < 1e-4 &&
      turn_carried < 1e-6,
    `slid ${slideOf(carried, slid).toFixed(3)}, came ` +
      `${depthOf(carried, slid.eye).toExponential(2)} in, turned ${turn_carried.toExponential(2)}`,
  );

  // Twist on sky about middle of frame: roll alone holds both places, so picture turns
  //   with fingers by what lies past slop, and eye moves nowhere.
  await page.keyboard.press('Home');
  await settleCamera(page);
  const across: [Finger, Finger] = [{ x: 300, y: 110 }, { x: 900, y: 790 }];
  const is_across_sky = (await isSkyAt(page, across[0])) && (await isSkyAt(page, across[1]));
  const centre = await page.evaluate(() => [window.innerWidth / 2, window.innerHeight / 2]);
  const marked = await handleLabelled(page, 'b');
  const upright = await readCamera(page);
  const start = await fingerOn(page, marked);
  await moveFingers(page, devtools, (along) => asHand(across, 1, 0.3 * along, { x: 0, y: 0 }));
  const rolled = await readCamera(page);
  const swung = await fingerOn(page, marked);
  const angleOf = (at: Finger): number =>
    Math.atan2(at.y - (centre[1] ?? 0), at.x - (centre[0] ?? 0));
  let turned = angleOf(swung) - angleOf(start);
  if (turned > Math.PI) turned -= 2 * Math.PI;
  if (turned < -Math.PI) turned += 2 * Math.PI;
  report(
    'a twist on empty sky turns the picture by what lies past the slop, and moves the eye nowhere',
    is_across_sky && Math.abs(turned - (0.3 - slop_twist)) < 1e-3 &&
      spanOf(upright.eye, rolled.eye) < 1e-3,
    `on sky ${is_across_sky}, fingers turned +0.300, picture turned ${turned.toFixed(4)} ` +
      `about the frame's middle, eye moved ${spanOf(upright.eye, rolled.eye).toExponential(2)}`,
  );

  // Pinched in four times away from middle, with nothing selected: each lands on sky once
  //   objects shrink, and each still zooms out.
  await page.keyboard.press('Home');
  await settleCamera(page);
  const apart: [Finger, Finger] = [{ x: 400, y: 250 }, { x: 800, y: 250 }];
  const pinched = (along: number): [Finger, Finger] =>
    asHand(apart, 1 - 0.75 * along, 0, { x: 0, y: 0 });
  const centre_scene = await page.evaluate(() => Array.from(nimCameraPivot()));
  const outward: number[] = [];
  for (let time = 0; time < 4; time += 1) {
    const out_from = await readCamera(page);
    await moveFingers(page, devtools, pinched);
    const out_to = await readCamera(page);
    outward.push(spanOf(out_to.eye, centre_scene) / spanOf(out_from.eye, centre_scene));
  }
  report(
    'four pinches in, with nothing selected, each zoom out',
    outward.every((ratio) => ratio > 2),
    `eye out from the opening pivot by ${outward.map((ratio) => ratio.toFixed(2)).join(', ')}`,
  );

  // With selection, two fingers orbit, dolly and roll about it, so pivot stays on it.
  await page.keyboard.press('Home');
  await settleCamera(page);
  const picked = await handleLabelled(page, 'o');
  await page.evaluate((one) => nimSelectOnly(one), picked);
  await settleCamera(page);
  const framed = await readCamera(page);
  const around: [Finger, Finger] = [{ x: 480, y: 470 }, { x: 730, y: 420 }];
  const orbit = (along: number): [Finger, Finger] =>
    asHand(around, 1 + 0.4 * along, -0.2 * along, { x: 20 * along, y: 10 * along });
  await moveFingers(page, devtools, orbit);
  const orbited = await readCamera(page);
  report(
    'with a selection two fingers orbit about it, and the pivot stays on it',
    spanOf(framed.pivot, orbited.pivot) < 1e-6 && orbited.distance < framed.distance,
    `pivot moved ${spanOf(framed.pivot, orbited.pivot).toExponential(2)}, ` +
      `distance ${framed.distance.toFixed(3)} -> ${orbited.distance.toFixed(3)}`,
  );
  // Pinched in four times away from middle: dolly meets fingers' gap each time.
  const dollied: number[] = [];
  for (let time = 0; time < 4; time += 1) {
    const out_from = await readCamera(page);
    await moveFingers(page, devtools, pinched);
    const out_to = await readCamera(page);
    dollied.push(out_to.distance / out_from.distance);
  }
  const held_on = await readCamera(page);
  await page.evaluate(() => clearSelection());
  report(
    'four pinches in, with a selection, each zoom out, and the pivot stays on it',
    dollied.every((ratio) => ratio > 2) &&
      spanOf(framed.pivot, held_on.pivot) < 1e-6 * held_on.distance,
    `distance out by ${dollied.map((ratio) => ratio.toFixed(2)).join(', ')}, pivot moved ` +
      `${spanOf(framed.pivot, held_on.pivot).toExponential(2)}`,
  );

  // Spread two frames into ease of right-click pick of `b`, over sky. With selection, two fingers
  //   orbit, dolly and roll about pivot it already has, so ease still lands pivot on `b`.
  //   Not halt, which stops ease where it stands: pivot stayed short of `b`, and every turn
  //   after went about that.
  await page.keyboard.press('Home');
  await settleCamera(page);
  const handle_b = await handleLabelled(page, 'b');
  const world_b = await page.evaluate((one) => Array.from(nimAnchorWorld(one)), handle_b);
  const on_b = await fingerOn(page, handle_b);
  const over_sky = await page.evaluate(() => {
    const rect = (document.getElementById('gl') as HTMLElement).getBoundingClientRect();
    return { x: rect.left + 0.5 * rect.width, y: rect.top + 0.15 * rect.height };
  });
  await page.mouse.click(on_b.x, on_b.y, { button: 'right' });
  await waitFrames(page, 2);
  await pinch(page, devtools, over_sky, over_sky, 60, 90);
  const spread = await readCamera(page);
  await page.evaluate(() => clearSelection());
  report(
    'and a spread inside the ease of a pick still lands the pivot on it',
    spanOf(spread.pivot, world_b) < 1e-4,
    `pivot off the point by ${spanOf(spread.pivot, world_b).toExponential(2)}`,
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
export async function driveFingerTurntable(page: Page, devtools: CDPSession): Promise<void> {
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
  await dragFinger(page, devtools, [sky.x, sky.y], [sky.x + 600, sky.y]);
  const swung = await readCamera(page);
  await dragFinger(page, devtools, [sky.x + 600, sky.y], [sky.x, sky.y]);
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
  await dragFinger(page, devtools, [landing.x, landing.y], [landing.x + 60, landing.y + 40]);
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
  // Finger holds point on sphere about pivot, so it lands just above pivot, on open sky,
  //   and drags down through middle; two such drags climb past straight down.
  const middle = await page.evaluate((one) => Array.from(
    nimAnchorScreen(one, window.innerWidth, window.innerHeight),
  ), handle);
  const above = { x: middle[0] ?? 0, y: (middle[1] ?? 0) - 40 };
  const before = await readCamera(page);
  for (let drag = 0; drag < 2; drag += 1) {
    if (!(await isOpenSky(page, above))) {
      report('a finger starts its orbit on open sky', false, `(${above.x}, ${above.y}) is not sky`);
      await page.evaluate(() => nimSelectClear());
      return;
    }
    await dragFinger(page, devtools, [above.x, above.y], [above.x, above.y + 240]);
  }
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
export async function driveTouchSelect(page: Page, devtools: CDPSession): Promise<void> {
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
  await tapAt(page, devtools, pixel_first[0] ?? 0, pixel_first[1] ?? 0, 1400);
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
  await tapAt(page, devtools, pixel_second[0] ?? 0, pixel_second[1] ?? 0);
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
  await tapAt(page, devtools, empty[0] ?? 0, empty[1] ?? 0);
  const count_empty = await page.evaluate(() => nimSelectionCount());
  report(
    'a tap on empty space clears the selection', count_empty === 0, `${count_empty} selected`,
  );
}
