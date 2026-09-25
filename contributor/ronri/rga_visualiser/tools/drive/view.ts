// Checks for view section of drawer; not Nim because they read page's own fields, which
//   exist only in browser.
//   Suites test what a typed motor settles on. Nothing in them types into page, so nothing
//   in them catches field wired to wrong coefficient, or row shown in wrong state.

import type { Page } from '@playwright/test';
import { report } from './report';

/** What view section shows, read in one crossing. */
interface Shown {
  count_motor: number;
  turn: number;
  azimuth: string;
  is_distance_shown: boolean;
  is_speed_shown: boolean;
}

/** Read view section as reader sees it. */
async function readShown(page: Page): Promise<Shown> {
  return page.evaluate(() => {
    const fields = document.querySelectorAll<HTMLInputElement>('#cam-motor input');
    return {
      count_motor: fields.length,
      // Field under turn about world up's own coefficient; found by grade and name.
      turn: parseFloat(fields[7]?.value ?? 'NaN'),
      azimuth: (document.getElementById('cam-azimuth') as HTMLOutputElement).value,
      is_distance_shown: !(document.getElementById('cam-distance-field')?.hidden ?? true),
      is_speed_shown: !(document.getElementById('cam-speed-field')?.hidden ?? true),
    };
  });
}

/** Wait out two refresh ticks of drawer's own low cadence. */
async function waitTicks(page: Page): Promise<void> {
  await page.waitForTimeout(450);
}

/** Drive view section: motor as value, readings off it, rows by selection. */
export async function driveViewSection(page: Page): Promise<void> {
  await page.evaluate(() => nimSelectClear());
  await waitTicks(page);
  const opening = await readShown(page);
  const names = await page.evaluate(() => [...Array(nimBasisCount()).keys()].map(nimBasisName));
  report(
    'the view shows its motor as every coefficient of one multivector',
    opening.count_motor === names.length && names[7] !== undefined &&
      names[7].includes('₄₃'),
    `${opening.count_motor} fields for ${names.length} basis blades; field 7 is ${names[7]}`,
  );
  report(
    'with nothing selected the view reads speed, and no distance',
    opening.is_speed_shown && !opening.is_distance_shown,
    `speed ${opening.is_speed_shown}, distance ${opening.is_distance_shown}`,
  );

  // Type turn about world up's coefficient: camera turns, and field shows motion it names.
  const azimuth_before = await page.evaluate(() => nimCameraAzimuth());
  await page.evaluate(() => {
    const field = document.querySelectorAll<HTMLInputElement>('#cam-motor input')[7];
    if (field === undefined) return;
    field.value = String(parseFloat(field.value) + 0.2);
    field.dispatchEvent(new Event('change'));
  });
  await waitTicks(page);
  const typed = opening.turn + 0.2;
  const turned = await readShown(page);
  const weight = await page.evaluate(() => {
    const motor = nimCameraMotor();
    return Math.hypot(motor[5] ?? 0, motor[6] ?? 0, motor[7] ?? 0, motor[15] ?? 0);
  });
  const azimuth_after = await page.evaluate(() => nimCameraAzimuth());
  report(
    'a typed coefficient turns the camera, and settles on a unit motor',
    Math.abs(azimuth_after - azimuth_before) > 0.1 && Math.abs(weight - 1) < 1e-4 &&
      Math.abs(turned.turn - typed) > 1e-3 && turned.azimuth !== opening.azimuth,
    `azimuth ${opening.azimuth} -> ${turned.azimuth}; typed ${typed.toFixed(4)}, ` +
      `settled ${turned.turn}; weight ${weight.toFixed(6)}`,
  );

  // Selection swaps distance in for speed, since frame rule measures from it.
  await page.evaluate(() => nimSelectOnly(nimSceneHandles()[0] ?? 0));
  await waitTicks(page);
  const picked = await readShown(page);
  report(
    'with a selection the view reads distance, and no speed',
    picked.is_distance_shown && !picked.is_speed_shown,
    `distance ${picked.is_distance_shown}, speed ${picked.is_speed_shown}`,
  );

  // Recorded edit to another object, then undo: pick survives step.
  const [first, second] = await page.evaluate(() => nimSceneHandles().slice(0, 2));
  await page.evaluate((handle) => nimSetInk(handle, 0), second ?? 0);
  await page.evaluate(() => document.getElementById('gl')?.focus());
  await page.keyboard.press('Control+z');
  await waitTicks(page);
  const kept = await page.evaluate(() => Array.from(nimSelectionHandles()));
  report(
    'undo keeps what is selected where the step still names it',
    kept.length === 1 && kept[0] === first,
    `selected [${kept.join(', ')}] after undo, picked ${first}`,
  );

  // Hand opening view back to checks after this one.
  await page.evaluate(() => nimSelectClear());
  await page.keyboard.press('Home');
  await waitTicks(page);
}
