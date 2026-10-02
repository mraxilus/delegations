// Checks for mouse pan and what zoom settles onto; not Nim because they drag real buttons
//   through Playwright, whose API exists only in node.
//   Pan holds depth it grabbed under pointer; zoom brings pivot down onto what is under
//   pointer. Suites reach neither: nothing in them has button or wheel.

import type { Page } from '@playwright/test';
import { readCamera, settleCamera, slideOf, spanOf } from './camera';
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

/** Drive left-button drag with nothing picked, and assert it looks rather than orbits.
 *
 *  Both front-ends called `orbit` outright, whatever was picked, so free flight's own
 *  `look` never reached drag: eye swung round pivot where reader meant to turn in place.
 */
export async function driveLook(page: Page): Promise<void> {
  await clearTheGlass(page);
  await settleHome(page);

  const before = await readCamera(page);
  // Start well clear of every object, so press moves camera rather than arming drag.
  await page.mouse.move(160, 170);
  await page.mouse.down({ button: 'left' });
  await page.mouse.move(360, 300, { steps: 12 });
  await page.mouse.up({ button: 'left' });
  await settleCamera(page);
  const after = await readCamera(page);

  report(
    'a left drag with nothing picked turns the sight and leaves the eye standing',
    spanOf(before.eye, after.eye) < 1e-6 &&
      Math.abs(after.azimuth - before.azimuth) > 1e-3,
    `eye moved ${spanOf(before.eye, after.eye).toFixed(6)} units, ` +
      `azimuth ${before.azimuth.toFixed(4)} -> ${after.azimuth.toFixed(4)}`,
  );
  // Pivot is what moves instead: it rides ahead of eye on sight, at same separation.
  report(
    'and it carries the orbit centre round instead, at the separation it had',
    spanOf(before.pivot, after.pivot) > 0.5 &&
      Math.abs(after.distance - before.distance) < 1e-6,
    `pivot moved ${spanOf(before.pivot, after.pivot).toFixed(3)}, ` +
      `separation ${after.distance.toFixed(3)}`,
  );
  // Mouse holds what is under it, as finger does: object beside cursor moves with it, one
  //   for one. Aim by rate slid it several times as far, and against cursor.
  //   Pressed 40 px left of object, on nothing it would build from, so press turns view.
  await settleHome(page);
  const seenBeside = async (): Promise<number[]> => page.evaluate(() => Array.from(
    nimAnchorScreen(nimSceneHandles()[0] ?? 0, window.innerWidth, window.innerHeight),
  ));
  const seen_before = await seenBeside();
  const press = { x: (seen_before[0] ?? 0) - 40, y: seen_before[1] ?? 0 };
  const is_open = await page.evaluate(({ x, y }) => {
    nimUpdateCursor(x, y);
    nimUpdateHover(window.innerWidth, window.innerHeight);
    return nimHoverHandle() < 0 || nimIsHoverBackdrop();
  }, press);
  await page.mouse.move(press.x, press.y);
  await page.mouse.down({ button: 'left' });
  await page.mouse.move(press.x + 60, press.y + 40, { steps: 10 });
  await page.mouse.up({ button: 'left' });
  await settleCamera(page);
  const seen_after = await seenBeside();
  const across = (seen_after[0] ?? 0) - (seen_before[0] ?? 0);
  const down = (seen_after[1] ?? 0) - (seen_before[1] ?? 0);
  report(
    'and a left drag carries the picture with the cursor, one for one',
    is_open && Math.abs(across / 60 - 1) < 0.05 && Math.abs(down / 40 - 1) < 0.05,
    `pressed on ${is_open ? 'open sky' : 'an object'}; object beside cursor moved ` +
      `${across.toFixed(1)} px across and ${down.toFixed(1)} px down, for a cursor moved 60 and 40`,
  );

  // Put view back: look swings sight right off scene, and checks after this one read
  //   what is drawn rather than press their own Home first.
  await settleHome(page);
}

/** Drive right-button pan, and assert it slides across sight and holds pivot under cursor.
 *
 *  Press comes down on nothing, so pan holds pivot's depth, and pivot slides as far as one
 *  pixel there spans, for each pixel dragged. Suite holds grab at any depth by projection;
 *  this holds page's wiring of it: press takes grab, and step reads canvas height.
 */
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

  // Nothing is selected on opening page, so right drag strafes along camera's own axes.
  const across = slideOf(before, after);
  report(
    'a right-button drag strafes across the sight line, and turns nothing',
    spanOf(before.eye, after.eye) > 0.5 &&
      Math.abs(across - spanOf(before.eye, after.eye)) < 1e-3 &&
      Math.abs(after.azimuth - before.azimuth) < 1e-6 &&
      Math.abs(after.distance - before.distance) < 1e-6,
    `eye moved ${spanOf(before.eye, after.eye).toFixed(3)}, ` +
      `${across.toFixed(3)} of it across the sight line`,
  );
  // Fault: rate of fixed share of separation for each pixel ran 1.74 times cursor at 900 px.
  const lens = await page.evaluate(() => ({
    degrees: nimCameraFov(),
    height: document.getElementById('gl')?.clientHeight ?? 0,
  }));
  const per_pixel =
    (2 * before.distance * Math.tan((lens.degrees * Math.PI) / 360)) / lens.height;
  const dragged = Math.hypot(360 - 160, 470 - 170);
  const carried = spanOf(before.pivot, after.pivot) / per_pixel;
  report(
    'and it carries the pivot with the cursor, one for one',
    Math.abs(carried / dragged - 1) < 0.01,
    `pivot carried ${carried.toFixed(1)} px at its own depth, for a cursor moved ` +
      `${dragged.toFixed(1)} px`,
  );
}

/** Drive right-button drag while selection stands, and assert it zooms by what it holds.
 *
 *  Vertical stretches from pivot's row, so point press took keeps pointer's height. It turns
 *  nothing: turn chasing point's column spun view and levelled it, zoomed far out. Suite
 *  holds it by projection; this holds page's wiring: press takes point, and step reads
 *  canvas size and selection's reach.
 *  Off middle column, where that turn was greatest. Pressed where nothing stands, since right
 *  press on object arms drag instead. Last drag runs down from top of frame with drift
 *  across, as hand drags.
 */
export async function driveStretch(page: Page): Promise<void> {
  await clearTheGlass(page);
  await settleHome(page);
  await page.evaluate(() => nimSelectOnly(nimSceneHandles()[0] ?? 0));
  await settleCamera(page); // Let framing ease finish before moving by hand.
  const size = await page.evaluate(() => ({
    width: document.getElementById('gl')?.clientWidth ?? 0,
    height: document.getElementById('gl')?.clientHeight ?? 0,
  }));
  const row = size.height / 2;
  const column = size.width / 2;

  // Away from pivot's row on either side, and toward it.
  const drags = [
    { way: 'above it and away', press: { x: column + 80, y: row - 90 }, reach: row - 220 },
    { way: 'below it and away', press: { x: column - 80, y: row + 90 }, reach: row + 210 },
    { way: 'toward it', press: { x: column + 80, y: row - 380 }, reach: row - 60 },
  ];
  for (const { way, press, reach } of drags) {
    const is_open = await page.evaluate(({ x, y }) => {
      nimUpdateCursor(x, y);
      nimUpdateHover(window.innerWidth, window.innerHeight);
      return nimHoverHandle() < 0 || nimIsHoverBackdrop();
    }, press);
    const before = await readCamera(page);
    const rise_before = await page.evaluate(() => nimCameraElevation());
    await page.mouse.move(press.x, press.y);
    await page.mouse.down({ button: 'right' });
    await page.mouse.move(press.x, reach, { steps: 12 });
    await page.mouse.up({ button: 'right' });
    const held = await page.evaluate(
      ({ width, height }) => Array.from(nimCameraPanHeldAt(width, height)), size,
    );
    await settleCamera(page);
    const after = await readCamera(page);
    const rise_after = await page.evaluate(() => nimCameraElevation());
    const slip = Math.abs((held[1] ?? 0) - reach);
    const turned = Math.max(
      Math.abs(after.azimuth - before.azimuth), Math.abs(rise_after - rise_before),
    );
    const is_closer = reach < row ? reach < press.y : reach > press.y;
    report(
      `a vertical right drag with a selection, ${way}, zooms and turns nothing`,
      is_open && (held[2] ?? 0) > 0 && slip < 0.5 && turned < 1e-5 &&
        (after.distance < before.distance) === is_closer &&
        spanOf(before.pivot, after.pivot) < 1e-4,
      `pressed on ${is_open ? 'open sky' : 'an object'}; point ${slip.toFixed(3)} px off the ` +
        `cursor's height, turned ${turned.toFixed(6)}, separation ` +
        `${before.distance.toFixed(2)} -> ${after.distance.toFixed(2)}`,
    );
  }

  // Down from very top with hand's drift across: turn stays left drag's own along pivot's
  //   row. Turn that carried point press took swung azimuth 0.17 radians for each step.
  const top = { x: column + 3, y: 8 };
  const is_top_open = await page.evaluate(({ x, y }) => {
    nimUpdateCursor(x, y);
    nimUpdateHover(window.innerWidth, window.innerHeight);
    return nimHoverHandle() < 0 || nimIsHoverBackdrop();
  }, top);
  const bearings: number[] = [await page.evaluate(() => nimCameraAzimuth())];
  await page.mouse.move(top.x, top.y);
  await page.mouse.down({ button: 'right' });
  for (let step = 1; step <= 24; step += 1) {
    await page.mouse.move(top.x + (step % 2 ? 4 : -2) + step * 0.5, top.y + step * 16);
    bearings.push(await page.evaluate(() => nimCameraAzimuth()));
  }
  await page.mouse.up({ button: 'right' });
  // Largest turn of one step, against 0.17 radians of turn that carried point press took.
  const jump = Math.max(...bearings.slice(1).map((b, i) => Math.abs(b - (bearings[i] ?? b))));
  report(
    'a right drag down from the top with a drift across turns as a left drag, and never jumps',
    is_top_open && jump < 0.03,
    `pressed on ${is_top_open ? 'open sky' : 'an object'}; largest turn of one step ` +
      `${jump.toFixed(4)} radians, drifting 2 to 4 px across each of 24`,
  );
}

/** Drive zoom low in frame, and assert eye follows pointer's own ray.
 *
 *  Free flight has no ground answer and no level one: ray under pointer is what carries
 *  eye, so aiming low takes camera down as well as in. Straight dolly would keep eye on
 *  its own sight axis, and nothing would carry it off that axis.
 */
export async function driveAim(page: Page, width: number, height: number): Promise<void> {
  await settleHome(page);
  const before = await readCamera(page);

  // Low in frame, where ray under pointer dives well under sight axis.
  await page.mouse.move(width / 2, height - 200);
  for (let notch = 0; notch < 8; notch += 1) {
    await page.mouse.wheel(0, -120);
    await waitFrames(page, 2);
  }
  await settleCamera(page);
  const after = await readCamera(page);

  const across = slideOf(before, after);
  const closed = before.distance - after.distance;
  report(
    'zooming low in the frame carries the eye down that ray, not straight in',
    closed > 0.2 * before.distance && across > 0.1,
    `separation ${before.distance.toFixed(2)} -> ${after.distance.toFixed(2)}, ` +
      `eye ${across.toFixed(3)} units off the sight axis`,
  );
}
