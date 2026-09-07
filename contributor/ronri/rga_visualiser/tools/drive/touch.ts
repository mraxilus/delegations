// Checks for what finger does; not Nim because two-finger input goes through Chrome's own
//   debugging protocol, which only node reaches.
//   Playwright's touch API is single-touch, so pinch is dispatched through CDP directly.
//   Touch is where pinch regression lived, and no suite has finger at all.

import type { CDPSession, Page } from '@playwright/test';
import { readCamera, settleCamera } from './camera';
import { waitFrames } from './frame';
import { report } from './report';
import { pixelOf } from './wheel';

/** One finger's place on screen. */
interface Finger {
  x: number;
  y: number;
}

/** Open channel two-finger gestures are dispatched down. */
export async function openTouch(page: Page): Promise<CDPSession> {
  return page.context().newCDPSession(page);
}

/** Which touch event is dispatched, as Chrome's protocol names them. */
export type TouchKind = 'touchStart' | 'touchMove' | 'touchEnd' | 'touchCancel';

/** Dispatch one touch event, however many fingers are down. */
export async function touchAt(
  cdp: CDPSession, kind: TouchKind, points: Finger[],
): Promise<void> {
  await cdp.send('Input.dispatchTouchEvent', {
    type: kind,
    touchPoints: points.map((point, index) => ({ x: point.x, y: point.y, id: index })),
  });
}

/** Put two fingers down and draw them apart or together, moving their midpoint. */
export async function pinch(
  page: Page, cdp: CDPSession, mid_from: Finger, mid_to: Finger,
  spread_from: number, spread_to: number,
): Promise<void> {
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

/** Put one finger down for however long, then lift it. */
export async function tapAt(
  page: Page, cdp: CDPSession, x: number, y: number, milliseconds = 60,
): Promise<void> {
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
