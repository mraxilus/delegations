// Checks for marker on horizon line, and comet that runs along it; not Nim because they
//   read what page would actually stroke, through DOM and bridge, in browser.
//   Circles of that marker run out to line's own vanishing points, and uncut one laps in
//   hundreds of thousands of pixels of outline no camera can show: comet travelling at
//   fixed screen pace would be off screen for all but few frames in thousand.
//   Driven rather than reasoned, since what matters is what page strokes.

import type { Page } from '@playwright/test';
import { report, reportWithin } from './report';

/** Whether every point falls inside canvas, within one pixel of its edge. */
async function insideCanvas(page: Page, points: number[][]): Promise<boolean> {
  return page.evaluate((given) => {
    const canvas = document.getElementById('gl');
    if (canvas === null) return false;
    return given.every(
      ([x, y]) => (x ?? 0) >= -1 && (y ?? 0) >= -1 &&
        (x ?? 0) <= canvas.clientWidth + 1 && (y ?? 0) <= canvas.clientHeight + 1,
    );
  }, points);
}

/** Where comet's head stands now, or nothing where it has none yet. */
async function headOf(page: Page, handle: number): Promise<number[] | null> {
  return page.evaluate((one) => {
    const canvas = document.getElementById('gl');
    if (canvas === null) return null;
    const flat = nimSelectionPulse(one, canvas.clientWidth, canvas.clientHeight, 1, false, 0);
    if (flat.length === 0 || (flat[0] ?? 0) < 1) return null;
    return [flat[2] as number, flat[3] as number];
  }, handle);
}

/** Build plane's attitude, which is horizon line, and check how it is marked. */
export async function driveComet(page: Page): Promise<void> {
  await page.evaluate(() => showHelp(false));
  await page.keyboard.press('Home');
  await page.waitForTimeout(150);

  const horizon = await page.evaluate(() => {
    const plane = nimSceneHandles().find((one) => nimObjectKindWord(one) === 'plane');
    if (plane === undefined) return null;
    const before = nimSceneHandles();
    // `Attitude` is catalogue's own first operation, and plane's attitude is pencil of
    //   directions lying in it — line in horizon.
    nimApplyOperation(0, plane, plane, performance.now() / 1000);
    const built = nimSceneHandles().find((one) => !before.includes(one));
    // Stand level with ground, so sky bands wrap in front of camera rather than above
    //   its top edge.
    nimSetCameraElevation(0.0);
    // Page's own pick path, not `nimSelectOnly`: overlay draws from snapshot that only
    //   this refreshes, and comet advances once per marker overlay strokes.
    nimSelectClear();
    if (built !== undefined) selectOnly(built, null);
    return built ?? null;
  });
  if (horizon === null) {
    report("a plane's attitude is drawn as bands the window itself bounds", false, 'none built');
    return;
  }

  const marker = await page.evaluate((one) => {
    const canvas = document.getElementById('gl');
    if (canvas === null) return { kind: -1, points: [] as number[][] };
    const flat = nimSelectionMarker(one, canvas.clientWidth, canvas.clientHeight, 1, false, 0);
    const points: number[][] = [];
    for (let i = 4; i + 1 < flat.length; i += 2) {
      points.push([flat[i] as number, flat[i + 1] as number]);
    }
    return { kind: flat.length === 0 ? -1 : (flat[0] as number), points };
  }, horizon);

  // Page's own mirror of marker kinds, read from it rather than copied here.
  const kind_bands = await page.evaluate(() => MARKER_BANDS);
  report(
    "a plane's attitude is drawn as bands the window itself bounds",
    marker.kind === kind_bands && marker.points.length > 0 &&
      await insideCanvas(page, marker.points),
    `kind ${marker.kind}, ${marker.points.length} points`,
  );

  // Wait for comet to have head before timing how far it travels: object was built moments
  //   ago and fresh one starts its pulse at zero, so sampling straight away sometimes
  //   catches it before there is head, which reads as off screen.
  let head_first: number[] | null = null;
  for (let waited = 0; waited < 40 && head_first === null; waited += 1) {
    head_first = await headOf(page, horizon);
    if (head_first === null) await page.waitForTimeout(50);
  }
  await page.waitForTimeout(500);
  const head_second = await headOf(page, horizon);

  const travelled = head_first === null || head_second === null
    ? -1
    : Math.hypot(
      (head_second[0] ?? 0) - (head_first[0] ?? 0), (head_second[1] ?? 0) - (head_first[1] ?? 0),
    );
  report(
    'its comet is on screen and travelling along it',
    head_first !== null && head_second !== null &&
      await insideCanvas(page, [head_first, head_second]),
    `head ${JSON.stringify(head_first)} then ${JSON.stringify(head_second)}`,
  );
  // Band rather than exact figure: page's own frame pacing decides how much of that half
  //   second clock actually saw.
  reportWithin('its comet covers a screen pace, not a lap of the sky', travelled, 5, 60, 'px');
}
