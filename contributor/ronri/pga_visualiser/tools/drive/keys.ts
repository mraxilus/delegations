// Checks for keys view itself reacts to; not Nim because they press real keys through
//   Playwright, whose API exists only in node.
//   Suites test what each motion does to camera. Nothing in them presses key, so nothing
//   in them catches rule wired to wrong key.

import type { Page } from '@playwright/test';
import { advance } from './clock';
import { readCamera, slideOf, spanOf } from './camera';
import { focusCanvas, holdKeys, settleCount, type Moved } from './gestures';
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
  // Flight is ship's: pivot rides along, so separation stays. Spent, it ran down to near
  //   floor and flight stalled short of pivot (repository issue 535).
  const closed = slid.before.distance - slid.after.distance;
  report(
    'a flight ahead keeps its separation, and turns nothing',
    Math.abs(slid.after.azimuth - slid.before.azimuth) < 1e-6 && Math.abs(closed) < 1e-9,
    `azimuth unchanged; separation ${slid.before.distance.toFixed(4)} -> ` +
      `${slid.after.distance.toFixed(4)} over ` +
      `${spanOf(slid.before.eye, slid.after.eye).toFixed(4)} units`,
  );
  // Second hold covers what first did: speed is ship's own, and nothing it flew past or
  //   toward has run it down. Two seconds each, from rest each time.
  const first = await holdKeys(page, ['KeyW'], 2000);
  const second = await holdKeys(page, ['KeyW'], 2000);
  const [span_first, span_second] = [
    spanOf(first.before.eye, first.after.eye), spanOf(second.before.eye, second.after.eye),
  ];
  report(
    'a second hold flies as far as the first, so flight never runs down',
    span_first > 0 && Math.abs(span_second - span_first) < 1e-6 * span_first,
    `${span_first.toFixed(4)} then ${span_second.toFixed(4)} units`,
  );
  // Plus and minus set ship's speed, by four for each second, and move nothing doing it.
  const speed_before = await page.evaluate(() => nimSpeedShip());
  const quickened = await holdKeys(page, ['Equal'], 500);
  const speed_quick = await page.evaluate(() => nimSpeedShip());
  const slowed = await holdKeys(page, ['Minus'], 500);
  const speed_slow = await page.evaluate(() => nimSpeedShip());
  report(
    'plus and minus set the speed of flight, and move nothing while they set it',
    Math.abs(speed_quick / speed_before - 2) < 0.05 &&
      Math.abs(speed_slow / speed_before - 1) < 0.05 &&
      spanOf(quickened.before.eye, quickened.after.eye) < 1e-9 &&
      spanOf(slowed.before.eye, slowed.after.eye) < 1e-9,
    `speed ${speed_before.toFixed(3)} -> ${speed_quick.toFixed(3)} -> ${speed_slow.toFixed(3)} ` +
      'units per second',
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
  // Simulated span: check is that camera stopped, and stopping has no event to wait on --
  //   waiting until it stopped would assert exactly what is being asked.
  await advance(page, 200);
  const later = await readCamera(page);
  const drifted = spanOf(after_release.eye, later.eye);
  report(
    'a released key stops the view',
    drifted < 1e-6,
    `eye moved ${drifted.toFixed(6)} units after release`,
  );
}


/** Read how far and which way eye went over one hold. */
function eyeMoved(moved: Moved): number[] {
  return moved.after.eye.map((value, i) => value - (moved.before.eye[i] ?? 0));
}

/** Press control with key that prints `key` where `code` stands, as layout other than QWERTY
 *  puts it.
 *
 *  Dispatched rather than typed: Playwright types key where QWERTY prints it, and claim is
 *  what page reads when print and place disagree.
 */
async function pressControlPrinted(page: Page, key: string, code: string): Promise<void> {
  await page.evaluate((given) => {
    document.dispatchEvent(new KeyboardEvent(
      'keydown', { key: given.key, code: given.code, ctrlKey: true, bubbles: true },
    ));
  }, { key, code });
}

/** Drive keys under modifier, and undo and redo read off key printed.
 *
 *  Control alone lowers, alt over view key moves nothing, and control with key printing Z or
 *  Y undoes or redoes wherever layout puts it, as desktop's `--drive-chords` holds too.
 */
export async function driveKeysChorded(page: Page): Promise<void> {
  // Free flight, from rest each time: space raises, and control alone must lower, straight
  //   opposite and at its rate. Rate within tenth: half second spans 30 frames or 31, as clock
  //   falls against frame, and frame at top of speed ramp travels about 6% of hold.
  await page.evaluate(() => clearSelection());
  await focusCanvas(page);
  const raised = eyeMoved(await holdKeys(page, ['Space'], 500));
  const lowered = eyeMoved(await holdKeys(page, ['ControlLeft'], 500));
  const [span_raised, span_lowered] = [Math.hypot(...raised), Math.hypot(...lowered)];
  const cosine = raised.reduce((sum, value, i) => sum + value * (lowered[i] ?? 0), 0) /
    (span_raised * span_lowered);
  report(
    'control held alone lowers the view, opposite to where space raises it and at its rate',
    span_lowered > 1e-3 && cosine < -1 + 1e-9 && Math.abs(span_lowered / span_raised - 1) < 0.1,
    `space ${span_raised.toFixed(4)} units, control ${span_lowered.toFixed(4)}, ` +
      `cosine between ${cosine.toFixed(12)}`,
  );

  // Alt belongs to system, so view key under it is not view's.
  const alted = await holdKeys(page, ['AltLeft', 'KeyW'], 500);
  const span_alted = spanOf(alted.before.eye, alted.after.eye);
  report(
    'a view key held under alt moves nothing',
    span_alted < 1e-9,
    `eye moved ${span_alted.toExponential(2)} units`,
  );

  // QWERTZ prints Z where QWERTY prints Y, and Y where it prints Z: delete one object, then
  //   undo and redo it there.
  const count = await page.evaluate(() => nimSceneCount());
  await page.evaluate(() => {
    selectOnly(nimSceneHandles()[0] ?? 0, null);
    document.getElementById('selection-menu-delete')?.click();
  });
  await settleCount(page, count - 1);
  await pressControlPrinted(page, 'z', 'KeyY');
  await settleCount(page, count).catch(() => undefined);
  const undone = await page.evaluate(() => nimSceneCount());
  await pressControlPrinted(page, 'y', 'KeyZ');
  await settleCount(page, count - 1).catch(() => undefined);
  const redone = await page.evaluate(() => nimSceneCount());
  report(
    'control with the key printed z undoes, and with the key printed y redoes, on any layout',
    undone === count && redone === count - 1,
    `deleted to ${count - 1}, undone to ${undone}, redone to ${redone}`,
  );
  // Leave scene as found for checks after this one.
  await page.keyboard.press('Control+z');
  await settleCount(page, count);
}
