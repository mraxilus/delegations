// Checks for mouse pan and what zoom settles onto; not Nim because they drag real buttons
//   through Playwright, whose API exists only in node.
//   Pan grabs level and keeps its height; zoom brings pivot down onto what is under
//   pointer. Suites reach neither: nothing in them has button or wheel.

import type { Page } from '@playwright/test';
import { readCamera, settleCamera, slideOf, spanPivot } from './camera';
import { waitFrames } from './frame';
import { clearTheGlass } from './gestures';
import { report } from './report';

/** Put camera back where it opened, and let its ease settle.
 *
 *  Height read mid-flight is not height check means to measure from. Canvas must hold focus
 *  too: chrome that took it few checks ago swallows key, and `Home` pressed into button
 *  moves nothing.
 */
async function settleHome(page: Page): Promise<void> {
  await page.evaluate(() => {
    nimSelectClear();
    document.getElementById('gl')?.focus();
  });
  await page.keyboard.press('Home');
  await settleCamera(page);
}

/** Drive right-button pan, and assert it keeps pivot on its level. */
export async function drivePan(page: Page): Promise<void> {
  // Clear glass first, or this measures section swallowing press: drag below starts where
  //   drawer stands once open, and drawer opens on left.
  await clearTheGlass(page);
  await settleHome(page);

  const before = await readCamera(page);
  // Start well clear of every object, so right button pans rather than arming drag.
  await page.mouse.move(160, 170);
  await page.mouse.down({ button: 'right' });
  await page.mouse.move(360, 470, { steps: 12 });
  await page.mouse.up({ button: 'right' });
  await settleCamera(page);
  const after = await readCamera(page);

  const height_before = before.pivot[2] ?? 0;
  const height_after = after.pivot[2] ?? 0;
  report(
    'a right-button drag pans, and keeps the orbit centre on its level',
    spanPivot(before, after) > 0.5 && Math.abs(height_after - height_before) < 1e-6 &&
      Math.abs(after.distance - before.distance) < 1e-6,
    `pivot moved ${spanPivot(before, after).toFixed(3)}, ` +
      `height ${height_before.toFixed(3)} -> ${height_after.toFixed(3)}`,
  );
}

/** Drive zoom low in frame, and assert eye follows pointer's own ray.
 *
 *  Free flight has no ground answer and no level one: ray under pointer is what carries
 *  eye, so aiming low takes camera down as well as in. Straight dolly would keep eye on
 *  its own sight axis, and nothing would carry it off that axis.
 */
export async function driveAim(page: Page, width: number, height: number): Promise<void> {
  await settleHome(page);
  const before = await readCamera(page);

  // Low in frame, where ray under pointer dives well under sight axis.
  await page.mouse.move(width / 2, height - 200);
  for (let notch = 0; notch < 8; notch += 1) {
    await page.mouse.wheel(0, -120);
    await waitFrames(page, 2);
  }
  await settleCamera(page);
  const after = await readCamera(page);

  const across = slideOf(before, after);
  const closed = before.distance - after.distance;
  report(
    'zooming low in the frame carries the eye down that ray, not straight in',
    closed > 0.2 * before.distance && across > 0.1,
    `separation ${before.distance.toFixed(2)} -> ${after.distance.toFixed(2)}, ` +
      `eye ${across.toFixed(3)} units off the sight axis`,
  );
}
