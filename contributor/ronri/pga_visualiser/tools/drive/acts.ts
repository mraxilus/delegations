// Check that acts both front-ends share take same effect on each, as `--drive-bulk`,
//   `--drive-fields` and `--drive-hover` hold desktop's; not Nim because it clicks real
//   buttons and types into real fields through Playwright, whose API exists only in node.
//   Suite holds core's rules alone; this holds page's wiring to them (repository issue 632).

import type { Page } from '@playwright/test';
import { settleCamera } from './camera';
import { waitFrames } from './frame';
import { clearTheGlass, focusCanvas, settleSelection } from './gestures';
import { report } from './report';

/** Leave page as checks after these find it: nothing picked, glass clear, camera home and still.
 *
 *  Picks, undo and held keys move camera, and demo after these loads against camera home.
 */
async function toHome(page: Page): Promise<void> {
  await clearTheGlass(page);
  await focusCanvas(page);
  await page.keyboard.press('Home');
  await settleCamera(page);
}

/** Pick first two live objects, as shift-click does, with menu up; return their handles. */
async function pickTwo(page: Page): Promise<number[]> {
  await clearTheGlass(page);
  const picked = await page.evaluate(() => {
    const two = Array.from(nimSceneHandles()).slice(0, 2);
    for (const one of two) toggleSelection(one, null);
    return two;
  });
  await settleSelection(page, picked.length);
  // Menu rides with its object while camera eases onto pick, and click must find it still.
  await settleCamera(page);
  return picked;
}

/** Read whether each of `handles` stands in scene, and whether each is shown. */
async function readStanding(page: Page, handles: number[]): Promise<boolean[][]> {
  return page.evaluate((given) => {
    const alive = new Set(Array.from(nimSceneHandles()));
    return given.map((one) => [alive.has(one), alive.has(one) && nimObjectVisible(one)]);
  }, handles);
}

/** Drive hide, then delete, of two picked objects from selection menu's own buttons.
 *
 *  Each is one act, so one undo brings both back, as desktop's menu takes it.
 */
export async function driveBulkUndo(page: Page): Promise<void> {
  await focusCanvas(page);
  await page.keyboard.press('Home');
  await settleCamera(page);
  const picked = await pickTwo(page);
  await page.click('#selection-menu-hide');
  await waitFrames(page, 2);
  const hidden = await readStanding(page, picked);
  await page.evaluate(() => nimUndo());
  await waitFrames(page, 2);
  const shown = await readStanding(page, picked);
  report(
    'hiding two picked objects takes one step of undo, as on the desktop',
    picked.length === 2 && hidden.every(([, is_shown]) => !is_shown) &&
      shown.every(([, is_shown]) => is_shown),
    `${picked.length} picked; shown after hide ${hidden.map(([, one]) => one)}, ` +
      `after one undo ${shown.map(([, one]) => one)}`,
  );

  await pickTwo(page);
  await page.click('#selection-menu-delete');
  await waitFrames(page, 2);
  const deleted = await readStanding(page, picked);
  await page.evaluate(() => nimUndo());
  await waitFrames(page, 2);
  const restored = await readStanding(page, picked);
  report(
    'deleting two picked objects takes one step of undo, as on the desktop',
    deleted.every(([is_alive]) => !is_alive) && restored.every(([is_alive]) => is_alive),
    `standing after delete ${deleted.map(([one]) => one)}, ` +
      `after one undo ${restored.map(([one]) => one)}`,
  );
  await toHome(page);
}

/** Type `text` into camera field `id` and commit it, as Enter or leaving field does. */
async function typeField(page: Page, id: string, text: string): Promise<void> {
  await page.evaluate(([name, value]) => {
    const field = document.getElementById(name ?? '') as HTMLInputElement | null;
    if (field === null) return;
    field.value = value ?? '';
    field.dispatchEvent(new Event('change'));
  }, [id, text]);
}

/** Drive field of view and distance typed into view section, each held inside core's bounds.
 *
 *  Field of view stays inside 10 to 120 degrees, and distance at zero or below lands on near
 *  limit, as desktop's fields hold them. Field left empty changes nothing, as Dear ImGui's
 *  typed entry does. Puts both back as they were.
 */
export async function driveFieldsHeld(page: Page): Promise<void> {
  await clearTheGlass(page);
  await focusCanvas(page);
  await page.keyboard.press('Home');
  await settleCamera(page);
  const [fov_before, distance_before] = await page.evaluate(
    () => [nimCameraFov(), nimCameraDistance()]);
  const read = () => page.evaluate(() => nimCameraFov());
  await typeField(page, 'cam-fov', '200');
  const fov_wide = await read();
  await typeField(page, 'cam-fov', '1');
  const fov_narrow = await read();
  await typeField(page, 'cam-fov', '');
  const fov_empty = await read();
  const [least, most] = await page.evaluate(
    () => [nimFieldOfViewLeast(), nimFieldOfViewMost()]);
  report(
    'a typed field of view is held inside 10 to 120 degrees, as on the desktop',
    fov_wide === most && fov_narrow === least && fov_empty === least,
    `typed 200 reads ${fov_wide}, 1 reads ${fov_narrow}, empty reads ${fov_empty}`,
  );

  const near = await page.evaluate(() => nimDistanceLimitNear());
  const readDistance = () => page.evaluate(() => nimCameraDistance());
  await typeField(page, 'cam-distance', '0');
  const distance_zero = await readDistance();
  await typeField(page, 'cam-distance', '-5');
  const distance_below = await readDistance();
  // Dolly scales distance by ratio, so landing reads near limit to rounding of that ratio.
  const isNear = (distance: number) => Math.abs(distance - near) <= near * 1e-9;
  report(
    'a typed distance at zero or below lands on the near limit, as on the desktop',
    isNear(distance_zero) && isNear(distance_below),
    `typed 0 reads ${distance_zero}, -5 reads ${distance_below}, near limit ${near}`,
  );

  // Home puts distance back, and keeps field of view, which is typed back.
  await typeField(page, 'cam-fov', String(fov_before));
  await focusCanvas(page);
  await page.keyboard.press('Home');
  await settleCamera(page);
  const distance_home = await readDistance();
  report(
    'and both fields go back as they were, for the checks after these',
    (await read()) === fov_before && Math.abs(distance_home - distance_before) < 1e-6,
    `field of view ${await read()} against ${fov_before}, distance ${distance_home} ` +
      `against ${distance_before}`,
  );
}

/** Rest mouse at middle of view, pick by keyboard, hold right arrow, then let go.
 *
 *  Keyboard pick carries its object to middle, under mouse that never moves, so hover must
 *  follow ease there. Held arrow then orbits about pick, which stays under mouse, so hover
 *  must drop for whole move and come back once it ends, as desktop's `--drive-hover` holds.
 *  Hover is read in every frame of hold: one lit frame is one too many.
 */
export async function driveHoverWhileMoving(page: Page): Promise<void> {
  await clearTheGlass(page);
  await focusCanvas(page);
  await page.keyboard.press('Home');
  await settleCamera(page);
  const middle = await page.evaluate(() => {
    const canvas = document.getElementById('gl') as HTMLCanvasElement;
    const on = canvas.getBoundingClientRect();
    return { x: on.left + canvas.clientWidth / 2, y: on.top + canvas.clientHeight / 2 };
  });
  await page.mouse.move(middle.x, middle.y);
  await waitFrames(page, 2);
  await page.keyboard.press('BracketRight');
  await page.keyboard.press('Enter');
  await settleSelection(page, 1);
  await settleCamera(page);
  await waitFrames(page, 2);
  const picked = await page.evaluate(() => Array.from(nimSelectionHandles())[0] ?? -1);
  const hovered_eased = await page.evaluate(() => nimHoverHandle());
  report(
    'hover follows what the camera eases under a still pointer, as on the desktop',
    picked >= 0 && hovered_eased === picked,
    `picked ${picked}, hovered ${hovered_eased} once settled`,
  );

  const frames_held = 12;
  await page.keyboard.down('ArrowRight');
  let lit = 0;
  for (let frame = 0; frame < frames_held; frame += 1) {
    await waitFrames(page, 1);
    if ((await page.evaluate(() => nimHoverHandle())) >= 0) lit += 1;
  }
  await page.keyboard.up('ArrowRight');
  await waitFrames(page, 3);
  const hovered_after = await page.evaluate(() => nimHoverHandle());
  report(
    'a held key hides hover for its whole move, and it comes back once the move ends',
    lit === 0 && hovered_after === picked,
    `${lit} of ${frames_held} frames lit mid-move, hovered ${hovered_after} after`,
  );
  await toHome(page);
}
