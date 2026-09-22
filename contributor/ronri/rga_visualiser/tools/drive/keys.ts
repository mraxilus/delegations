// Checks for keys view itself reacts to; not Nim because they press real keys through
//   Playwright, whose API exists only in node.
//   Suites test what each motion does to camera. Nothing in them presses key, so nothing
//   in them catches rule wired to wrong key.

import type { Page } from '@playwright/test';
import { readCamera, slideOf, spanPivot } from './camera';
import { holdKeys } from './gestures';
import { report, reportWithin } from './report';

/** Drive held keys, and assert what each reached. */
export async function driveKeys(page: Page): Promise<void> {
  // Nothing is selected on opening page, so camera flies rather than slides.
  //   Speed climbs toward its cap over hold, so half second covers well under flat rate
  //   map reading used to cover.
  const slid = await holdKeys(page, ['KeyW'], 500);
  reportWithin(
    'a held key flies the view forward', spanPivot(slid.before, slid.after), 1, 25, 'units',
  );
  const across = slideOf(slid.before, slid.after);
  const risen = (slid.after.eye[2] ?? 0) - (slid.before.eye[2] ?? 0);
  report(
    'a flight follows the sight line, and dives with it',
    across < 1e-3 && risen < -1e-3,
    `${across.toFixed(6)} units across the sight line, and z moved ${risen.toFixed(4)}`,
  );
  report(
    'a flight leaves the orbit reading alone',
    Math.abs(slid.after.azimuth - slid.before.azimuth) < 1e-6 &&
      Math.abs(slid.after.distance - slid.before.distance) < 1e-6,
    'azimuth and distance unchanged',
  );

  // Release, which key handling must see: held key whose release is missed keeps moving.
  const after_release = await readCamera(page);
  // Wall time, deliberately: check is that camera stopped, and stopping has no event to wait
  //   on -- waiting until it stopped would assert exactly what is being asked.
  await page.waitForTimeout(200);
  const later = await readCamera(page);
  report(
    'a released key stops the view',
    spanPivot(after_release, later) < 1e-6,
    `pivot moved ${spanPivot(after_release, later).toFixed(6)} units after release`,
  );
}
