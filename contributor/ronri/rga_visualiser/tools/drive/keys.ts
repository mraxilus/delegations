// Checks for keys view itself reacts to; not Nim because they press real keys through
//   Playwright, whose API exists only in node.
//   Suites test what slide does to pivot. Nothing in them presses key, so nothing in them
//   catches rule wired to wrong key.

import type { Page } from '@playwright/test';
import { readCamera, spanPivot } from './camera';
import { holdKeys } from './gestures';
import { report, reportWithin } from './report';

/** Drive held keys, and assert what each reached. */
export async function driveKeys(page: Page): Promise<void> {
  const slid = await holdKeys(page, ['KeyW'], 500);
  reportWithin(
    'a held key slides the view', spanPivot(slid.before, slid.after), 4, 25, 'units',
  );
  report(
    'a slide keeps the height it started at',
    Math.abs((slid.after.pivot[2] ?? 0) - (slid.before.pivot[2] ?? 0)) < 1e-3,
    `z ${(slid.before.pivot[2] ?? 0).toFixed(4)} -> ${(slid.after.pivot[2] ?? 0).toFixed(4)}`,
  );
  report(
    'a slide leaves the orbit alone',
    Math.abs(slid.after.azimuth - slid.before.azimuth) < 1e-6 &&
      Math.abs(slid.after.distance - slid.before.distance) < 1e-6,
    'azimuth and distance unchanged',
  );

  // Release, which key handling must see: held key whose release is missed keeps moving.
  const after_release = await readCamera(page);
  await page.waitForTimeout(200);
  const later = await readCamera(page);
  report(
    'a released key stops the view',
    spanPivot(after_release, later) < 1e-6,
    `pivot moved ${spanPivot(after_release, later).toFixed(6)} units after release`,
  );
}
