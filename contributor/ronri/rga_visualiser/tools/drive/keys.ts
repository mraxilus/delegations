// Checks for keys view itself reacts to; not Nim because they press real keys through
//   Playwright, whose API exists only in node.
//   Suites test what each motion does to camera. Nothing in them presses key, so nothing
//   in them catches rule wired to wrong key.

import type { Page } from '@playwright/test';
import { readCamera, slideOf, spanOf } from './camera';
import { holdKeys } from './gestures';
import { report, reportWithin } from './report';

/** Drive held keys, and assert what each reached. */
export async function driveKeys(page: Page): Promise<void> {
  // Nothing is selected on opening page, so camera flies rather than slides.
  //   Speed climbs toward its cap over hold, so half second covers well under flat rate
  //   map reading used to cover.
  const scale_before = await page.evaluate(() => nimCameraScaleLocal());
  const slid = await holdKeys(page, ['KeyW'], 500);
  const scale_after = await page.evaluate(() => nimCameraScaleLocal());
  //   Eye is what moves, not pivot: flight ahead holds pivot where it stands.
  reportWithin(
    'a held key flies the view forward', spanOf(slid.before.eye, slid.after.eye),
    1, 25, 'units',
  );
  const across = slideOf(slid.before, slid.after);
  const risen = (slid.after.eye[2] ?? 0) - (slid.before.eye[2] ?? 0);
  report(
    'a flight follows the sight line, and dives with it',
    across < 1e-3 && risen < -1e-3,
    `${across.toFixed(6)} units across the sight line, and z moved ${risen.toFixed(4)}`,
  );
  // Flight ahead holds pivot where it stands, so separation gives up exactly what eye
  //   covered: that is what keeps near clip and furniture on scale reader flies into.
  const closed = slid.before.distance - slid.after.distance;
  report(
    'a flight ahead spends its separation, and turns nothing',
    Math.abs(slid.after.azimuth - slid.before.azimuth) < 1e-6 &&
      Math.abs(closed - spanOf(slid.before.eye, slid.after.eye)) < 1e-3,
    `azimuth unchanged; separation gave up ${closed.toFixed(4)} of ` +
      `${slid.before.distance.toFixed(4)}`,
  );

  // Frustum and furniture read reach to nearest drawn object ahead, so flying in draws
  //   that scale in by exactly what eye covered. Separation alone kept scale of stance
  //   reader set off from, and near clip is one four-hundredth of it.
  const drawn_in = scale_before - scale_after;
  report(
    'flying in draws the frustum scale in with it',
    scale_after > 0 && Math.abs(drawn_in - spanOf(slid.before.eye, slid.after.eye)) < 1e-2,
    `scale ${scale_before.toFixed(4)} -> ${scale_after.toFixed(4)}`,
  );

  // Release, which key handling must see: held key whose release is missed keeps moving.
  const after_release = await readCamera(page);
  // Wall time, deliberately: check is that camera stopped, and stopping has no event to wait
  //   on -- waiting until it stopped would assert exactly what is being asked.
  await page.waitForTimeout(200);
  const later = await readCamera(page);
  const drifted = spanOf(after_release.eye, later.eye);
  report(
    'a released key stops the view',
    drifted < 1e-6,
    `eye moved ${drifted.toFixed(6)} units after release`,
  );
}
