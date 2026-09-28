// Check that every point is shaded from world's up; not Nim because it reads canvas.
//   Light is presentation alone: nothing in scene carries one, so no sun is placed. Point
//   wide enough to sample is added on opening scene's first point, read once, removed.

import type { Page } from '@playwright/test';
import { settleCamera } from './camera';
import { readCanvas } from './canvas';
import { waitFrames } from './frame';
import { report } from './report';
import { pixelOf } from './wheel';

/** Drawn radius of sampled point, in world units: about hundred pixels at opening camera. */
const RADIUS_SAMPLED = 2.0;
/** How far above and below disc's centre samples are taken, in pixels, well inside its rim. */
const PIXELS_SAMPLE_OFF = 40;
/** How much brighter upper sample must read than lower, as ratio of luminance.
 *
 *  Lambert from above at opening camera's elevation puts upper sample near 0.8 of full and
 *  lower near ambient's 0.25, ratio about three; bound is loose so veil crossing one sample
 *  cannot fail it, and tight enough that flat disc, ratio one, does.
 */
const RATIO_LIT_LEAST = 1.15;

/** Assert wide disc's upper half is brighter than its lower on screen.
 *
 *  Light comes from world's up and from nothing in scene, so there is no sun to place and
 *  check holds over any scene. Opening camera stands above horizontal, so world's up leans
 *  toward screen's top and lit side is upper half. Read through compositor as every pixel
 *  check is; selection cleared first so no marker ring crosses either sample.
 */
export async function driveShadedFromAbove(page: Page): Promise<void> {
  const claim = 'a point is shaded from above: its upper half is brighter than its lower';
  // Canvas takes keys only while focused, and check before this one left focus elsewhere.
  await page.evaluate(() => document.getElementById('gl')?.focus());
  await page.keyboard.press('Home');
  await settleCamera(page);
  const handle = await page.evaluate((radius) => {
    // First point, by kind word: opening scene's first handle need not be one.
    const point = nimSceneHandles().find((one) => nimObjectKindWord(one) === 'point');
    if (point === undefined) return -1;
    const model = Array.from(nimObjectCoefficients(point));
    const added = nimAddObject(model, 'shaded', nimDefaultInk(), radius, 0);
    // Adding selects, and selection offers camera aim it glides to frame later, which
    //   moved disc between pixel read and capture. Cleared at once, and pivot put on disc,
    //   so it stands mid-frame at opening distance, whole and in front of everything.
    nimSelectClear();
    // Whole camera slides onto disc, so sight stands.
    const at = Array.from(nimAnchorWorld(added));
    const eye = nimCameraEye(), pivot = nimCameraPivot();
    nimPlaceCamera(
      (eye[0] ?? 0) + (at[0] ?? 0) - (pivot[0] ?? 0),
      (eye[1] ?? 0) + (at[1] ?? 0) - (pivot[1] ?? 0),
      (eye[2] ?? 0) + (at[2] ?? 0) - (pivot[2] ?? 0),
      at[0] ?? 0, at[1] ?? 0, at[2] ?? 0,
    );
    return added;
  }, RADIUS_SAMPLED);
  if (handle < 0) {
    report(claim, false, 'no point in the opening scene to widen');
    return;
  }
  await settleCamera(page);
  await waitFrames(page, 2);
  const pixel = await pixelOf(page, handle);
  if (pixel === null) {
    report(claim, false, 'no pixel for the sampled point');
    return;
  }
  const x = pixel[0] ?? 0;
  const y = pixel[1] ?? 0;
  // Whole column through disc is read, so detail line shows profile and not two numbers.
  const offsets = [-100, -80, -60, -PIXELS_SAMPLE_OFF, -20, 0, 20, PIXELS_SAMPLE_OFF, 60, 80, 100];
  const reading = await readCanvas(page, offsets.map((off): [number, number] => [x, y + off]));
  const luminance = (rgba: number[]): number =>
    0.2126 * (rgba[0] ?? 0) + 0.7152 * (rgba[1] ?? 0) + 0.0722 * (rgba[2] ?? 0);
  const column = offsets.map((off, i) => `${off}:${luminance(reading.spots[i] ?? []).toFixed(0)}`);
  const upper = luminance(reading.spots[offsets.indexOf(-PIXELS_SAMPLE_OFF)] ?? []);
  const lower = luminance(reading.spots[offsets.indexOf(PIXELS_SAMPLE_OFF)] ?? []);
  const stance = await page.evaluate((one) => ({
    radius: nimObjectRadius(one), distance: nimCameraDistance(), elevation: nimCameraElevation(),
    width: window.innerWidth, height: window.innerHeight,
  }), handle);
  report(
    claim,
    lower > 0 && upper > lower * RATIO_LIT_LEAST,
    `luminance ${upper.toFixed(1)} at ${PIXELS_SAMPLE_OFF} px above the centre against ` +
      `${lower.toFixed(1)} below, on a disc of radius ${stance.radius} at (${x.toFixed(0)}, ` +
      `${y.toFixed(0)}) in ${stance.width}x${stance.height}, camera ` +
      `${stance.distance.toFixed(1)} out at ${stance.elevation.toFixed(2)} rad; ` +
      `column ${column.join(' ')}`,
  );
  await page.evaluate((one) => { nimRemoveObject(one); }, handle);
  // Camera back where it opened, for every check after.
  await page.evaluate(() => document.getElementById('gl')?.focus());
  await page.keyboard.press('Home');
  await settleCamera(page);
}
