// Checks for wheel zoom, and what it aims at; not Nim because they turn real wheel through
//   Playwright, whose API exists only in node.
//   Zoom anchors on very object pointer is over, so pixel it was on is pixel it stays on.
//   Suites cannot reach that: nothing in them has pointer.

import type { Page } from '@playwright/test';
import { depthOf, readCamera, settleCamera, spanOf, type Stance } from './camera';
import { waitFrames } from './frame';
import { report, reportWithin } from './report';

/** Screen pixel one object's anchor draws at, or nothing where it is off screen. */
export async function pixelOf(page: Page, handle: number): Promise<number[] | null> {
  return page.evaluate((one) => {
    const at = nimAnchorScreen(one, window.innerWidth, window.innerHeight);
    return at.length >= 2 ? [at[0] as number, at[1] as number] : null;
  }, handle);
}

/** Pick object standing furthest from every other on screen.
 *
 *  Rather than whichever handle happens to be last. Zoom aims at what `picking.pickNearest`
 *  finds under pointer, and that ranks point above plane, so pointer over two overlapping
 *  objects anchors on thinner one and check would be measuring object it did not aim at.
 *  Opening scene has point sitting few pixels from ground plane's own drawn anchor.
 */
async function handleAlone(page: Page): Promise<number> {
  const handles = await page.evaluate(() => nimSceneHandles());
  const anchors: Array<{ handle: number; at: number[] }> = [];
  for (const handle of handles) {
    const at = await pixelOf(page, handle);
    if (at !== null) anchors.push({ handle, at });
  }
  const apartOf = (one: { handle: number; at: number[] }): number => Math.min(
    ...anchors
      .filter((other) => other.handle !== one.handle)
      .map((other) => Math.hypot(
        (one.at[0] ?? 0) - (other.at[0] ?? 0), (one.at[1] ?? 0) - (other.at[1] ?? 0),
      )),
  );
  const sorted = anchors.map((one) => ({ handle: one.handle, apart: apartOf(one) }))
    .sort((a, b) => b.apart - a.apart);
  return sorted[0]?.handle ?? 0;
}

/** Turn wheel some notches, one way, letting each land. */
async function wheelBy(page: Page, notches: number, step: number): Promise<void> {
  for (let i = 0; i < notches; i += 1) {
    await page.mouse.wheel(0, step);
    await waitFrames(page, 2);
  }
  await settleCamera(page);
}

/** Return to opening stance through key that means it, and check that key on way. */
export async function driveHome(page: Page): Promise<Stance> {
  await page.keyboard.press('Home');
  await settleCamera(page);
  const homed = await readCamera(page);
  report(
    'home returns the camera to where it opened',
    Math.abs(homed.distance - 19) < 1e-6 && Math.abs(homed.pivot[0] ?? 0) < 1e-6 &&
      Math.abs(homed.pivot[1] ?? 0) < 1e-6 && Math.abs((homed.pivot[2] ?? 0) - 1) < 1e-6,
    `distance ${homed.distance.toFixed(3)}, ` +
      `pivot ${homed.pivot.map((v) => v.toFixed(3)).join(', ')}`,
  );
  return homed;
}

/** Drive wheel zoom, and assert what it aimed at. */
export async function driveWheel(page: Page): Promise<void> {
  await driveHome(page);

  const handle_aimed = await handleAlone(page);
  const pixel_before = await pixelOf(page, handle_aimed);
  if (pixel_before === null) {
    report('an object stands on screen to aim the wheel at', false, 'none had a pixel');
    return;
  }
  const before = await readCamera(page);

  await page.mouse.move(pixel_before[0] ?? 0, pixel_before[1] ?? 0);
  await wheelBy(page, 8, -120);
  const pixel_in = await pixelOf(page, handle_aimed);
  const zoomed = await readCamera(page);

  report(
    'the wheel actually zooms',
    zoomed.distance < before.distance * 0.6,
    `distance ${before.distance.toFixed(2)} -> ${zoomed.distance.toFixed(2)}`,
  );

  // Exact, not merely close: zoom anchors on very object pointer is over, so pixel it was
  //   on is pixel it stays on. Anchor on plane through camera's own pivot drifts instead.
  reportWithin(
    'what the pointer is over stays under the pointer',
    Math.hypot(
      (pixel_in?.[0] ?? 0) - (pixel_before[0] ?? 0), (pixel_in?.[1] ?? 0) - (pixel_before[1] ?? 0),
    ),
    0, 1, 'px',
  );

  // Pivot comes to depth of what was zoomed onto, not left behind on level it started at.
  //   Depth along sight line, since object sits off middle of frame and pivot stays on it.
  const world_aimed = await page.evaluate((one) => Array.from(nimAnchorWorld(one)), handle_aimed);
  reportWithin(
    'and the orbit centre comes to its depth',
    Math.abs(depthOf(zoomed, world_aimed) - zoomed.distance), 0, 1e-3, 'units',
  );

  await wheelBy(page, 8, 120);
  const out = await readCamera(page);
  const pixel_out = await pixelOf(page, handle_aimed);
  // Eye and pixel round trip; pivot and distance do not, and are not meant to. Pivot came
  //   to object's depth on way in and stays, so orbit after is about what was zoomed onto.
  const off_eye = spanOf(out.eye, before.eye);
  const off_pixel = Math.hypot(
    (pixel_out?.[0] ?? 0) - (pixel_before[0] ?? 0), (pixel_out?.[1] ?? 0) - (pixel_before[1] ?? 0),
  );
  report(
    'a wheel notch each way is a round trip',
    off_eye < 1e-3 && off_pixel < 1,
    `eye off by ${off_eye.toFixed(4)} units, pixel off by ${off_pixel.toFixed(2)} px`,
  );
}
