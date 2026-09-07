// Checks for mouse pan and what zoom settles onto; not Nim because they drag real buttons
//   through Playwright, whose API exists only in node.
//   Pan grabs level and keeps its height; zoom brings pivot down onto what is under
//   pointer. Suites reach neither: nothing in them has button or wheel.

import type { Page } from '@playwright/test';
import { readCamera, settleCamera, spanPivot } from './camera';
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

/** Drive zoom over ground, and assert pivot comes down onto it.
 *
 *  Anchored on plane through pivot, zoom leaves pivot stranded on level it started at
 *  however far reader goes in; anchored on object or ground under pointer, it comes down.
 */
export async function driveAim(page: Page, width: number, height: number): Promise<void> {
  await settleHome(page);
  const before = await readCamera(page);

  // Low in frame, where sight ray reaches ground well in front of camera.
  await page.mouse.move(width / 2, height - 200);
  for (let notch = 0; notch < 8; notch += 1) {
    await page.mouse.wheel(0, -120);
    await waitFrames(page, 2);
  }
  await settleCamera(page);
  const after = await readCamera(page);

  const height_before = before.pivot[2] ?? 0;
  const height_after = after.pivot[2] ?? 0;
  report(
    'zooming in over the ground brings the orbit centre down onto it',
    height_before > 0.9 && height_after < height_before - 0.2 && height_after > -0.5,
    `pivot height ${height_before.toFixed(2)} -> ${height_after.toFixed(2)}, ` +
      `distance ${after.distance.toFixed(2)}`,
  );
}
