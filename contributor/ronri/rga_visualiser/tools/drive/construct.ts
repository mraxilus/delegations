// Checks for building objects by dragging one onto another; not Nim because they drive real
//   pointer and touch through Playwright and Chrome's protocol, which only node reaches.
//   Whole gesture application is about: drag one object onto another and third is derived.
//   Suites reach `applyOperation`, never gesture that calls it.

import type { CDPSession, Page } from '@playwright/test';
import { readCamera, settleCamera, spanPivot } from './camera';
import { waitFrames } from './frame';
import { report } from './report';
import { clearTheGlass } from './gestures';
import { pixelOf } from './wheel';
import { dragFinger, tapAt, pinch } from './touch';

/** Put camera back where it opened and drop selection, so each check starts alike. */
async function fromHome(page: Page): Promise<void> {
  await page.keyboard.press('Home');
  await settleCamera(page);
  await page.evaluate(() => nimSelectClear());
}

/** Drive two fingers moving together, which is pan and only pan. */
export async function driveTwoFingerPan(page: Page, cdp: CDPSession): Promise<void> {
  await page.keyboard.press('Home');
  await settleCamera(page);
  const before = await readCamera(page);
  await pinch(page, cdp, { x: 400, y: 400 }, { x: 700, y: 500 }, 80, 80);
  const after = await readCamera(page);

  report(
    'two fingers moving together pan without zooming',
    spanPivot(before, after) > 0.5 && Math.abs(after.distance - before.distance) < 1e-6,
    `pivot moved ${spanPivot(before, after).toFixed(3)}, ` +
      `distance ${after.distance.toFixed(3)}`,
  );
  // Pan slides view across level, so pivot keeps its height exactly. Sliding within plane
  //   facing eye, which is tilted, lifts pivot off ground, and every later orbit then
  //   swings about point in mid-air.
  report(
    'and without lifting the orbit centre off the level it was on',
    Math.abs((after.pivot[2] ?? 0) - (before.pivot[2] ?? 0)) < 1e-6,
    `pivot height ${(before.pivot[2] ?? 0).toFixed(3)} -> ${(after.pivot[2] ?? 0).toFixed(3)}`,
  );
}

/** Drive finger dragging one object onto another, which builds third. */
export async function driveTouchConstruct(page: Page, cdp: CDPSession): Promise<void> {
  await fromHome(page);
  const handles = await page.evaluate(() => nimSceneHandles());
  const first = handles[1];
  const second = handles[2];
  if (first === undefined || second === undefined) {
    report('the scene holds two objects to drag between', false, `${handles.length} objects`);
    return;
  }

  const before = await page.evaluate(() => nimSceneCount());
  const from = await pixelOf(page, first);
  const onto = await pixelOf(page, second);
  if (from === null || onto === null) {
    report('both objects stand on screen', false, 'one had no pixel');
    return;
  }
  await dragFinger(page, cdp, from, onto);
  const after = await page.evaluate(() => nimSceneCount());
  report(
    'a finger dragging one object onto another builds a third',
    after === before + 1, `${after} objects, was ${before}`,
  );
}

/** Drive finger from crowd, which orbits rather than building.
 *
 *  Second point beside first, inside one finger's pick reach, so press is ambiguous: same
 *  drag then orbits and builds nothing, and reader zooms in to separate them. Long press
 *  over same crowd still selects, since still finger competes with nothing.
 */
export async function driveCrowd(page: Page, cdp: CDPSession): Promise<void> {
  await page.keyboard.press('Home');
  await settleCamera(page);
  const handles = await page.evaluate(() => nimSceneHandles());
  const first = handles[1];
  const second = handles[2];
  if (first === undefined || second === undefined) return;

  const rival = await page.evaluate((one) => {
    const model = Array.from(nimObjectCoefficients(one));
    model[1] = (model[1] ?? 0) + 0.05;
    const added = nimAddObject(model, 'rival', nimDefaultInk(), nimDefaultRadius(), false, 0);
    nimSelectClear();
    return added;
  }, first);
  await waitFrames(page, 2);

  const count_before = await page.evaluate(() => nimSceneCount());
  const azimuth_before = await page.evaluate(() => nimCameraAzimuth());
  const from = await pixelOf(page, first);
  const onto = await pixelOf(page, second);
  if (from !== null && onto !== null) {
    await dragFinger(page, cdp, from, onto);
    const count_after = await page.evaluate(() => nimSceneCount());
    const azimuth_after = await page.evaluate(() => nimCameraAzimuth());
    report(
      'a finger dragging from a crowd of objects orbits instead of building',
      count_after === count_before && Math.abs(azimuth_after - azimuth_before) > 0.05,
      `${count_after} objects, was ${count_before}; ` +
        `azimuth ${azimuth_before.toFixed(3)} -> ${azimuth_after.toFixed(3)}`,
    );
  }

  await page.evaluate(() => nimSelectClear());
  await page.keyboard.press('Home');
  await settleCamera(page);
  const still = await pixelOf(page, first);
  if (still !== null) {
    await tapAt(page, cdp, still[0] ?? 0, still[1] ?? 0, 1400);
    const count = await page.evaluate(() => nimSelectionCount());
    report(
      'a long press over a crowd still selects what it is over',
      count === 1, `${count} selected`,
    );
  }

  // Put camera back where orbit found it, and take rival away: later checks frame with
  //   `Home`, which keeps azimuth, and at this one line's anchor lands over point.
  await settleCamera(page);
  await page.evaluate(() => nimSelectClear());
  await page.evaluate(([one, azimuth]) => {
    nimRemoveObject(one as number);
    nimSetCameraAzimuth(azimuth as number);
  }, [rival, azimuth_before]);
  await settleCamera(page);
}

/** Drive drag that pauses over its aim, as careful finger really does.
 *
 *  Dwell wheel opens under finger during that pause, hidden by it; reading release as
 *  "chose nothing" would make exactly careful drags build nothing. Wheel nobody entered
 *  may not veto release. Check holds wheel really did open, so slower dwell cannot turn
 *  this into second copy of quick-lift check.
 */
export async function drivePausedDrag(page: Page, cdp: CDPSession): Promise<void> {
  await fromHome(page);
  const handles = await page.evaluate(() => nimSceneHandles());
  const first = handles[1];
  const second = handles[2];
  if (first === undefined || second === undefined) return;

  const before = await page.evaluate(() => nimSceneCount());
  const from = await pixelOf(page, first);
  const onto = await pixelOf(page, second);
  if (from === null || onto === null) return;

  await dragFinger(page, cdp, from, onto, { lift: false });
  // Wall time, deliberately: how long finger rests is gesture under test, and waiting on
  //   wheel instead would assert what check below is asking.
  await page.waitForTimeout(1100);
  const is_wheel_open = await page.evaluate(() => nimDragMenuOpen());
  await dragFinger(page, cdp, onto, onto, { press: false });
  await waitFrames(page, 2);

  const after = await page.evaluate(() => nimSceneCount());
  report(
    'a paused finger still builds on lifting, through the wheel its pause opened',
    is_wheel_open && after === before + 1,
    `wheel open ${is_wheel_open}; ${after} objects, was ${before}`,
  );
}

/** Drive drag let go of over empty space, which builds nothing and says nothing.
 *
 *  Reader can see nothing happened, and status line for it would fire on every gesture
 *  anybody thought better of.
 */
export async function driveEmptyRelease(page: Page, width: number, height: number): Promise<void> {
  await page.keyboard.press('Home');
  await settleCamera(page);
  await page.evaluate(() => {
    nimSelectClear();
    // Require cleared, not merely hidden: check that only asked whether bar is up would
    //   pass on message never dismissed from earlier gesture.
    const bar = document.getElementById('toast');
    if (bar !== null) {
      bar.classList.remove('show');
      bar.textContent = '';
    }
  });

  const handles = await page.evaluate(() => nimSceneHandles());
  const first = handles[1];
  if (first === undefined) return;
  const from = await pixelOf(page, first);
  if (from === null) return;

  await page.mouse.move(from[0] ?? 0, from[1] ?? 0);
  await page.mouse.down();
  await page.mouse.move(width - 30, height - 30, { steps: 8 });
  await page.mouse.up();
  // Wall time, deliberately: check is that nothing was said, and absence has no condition to
  //   wait on -- window has to be long enough for bar to have shown had it been going to.
  await page.waitForTimeout(300);

  const said = await page.evaluate(() => {
    const bar = document.getElementById('toast');
    return {
      shown: bar !== null && bar.classList.contains('show'),
      text: bar?.textContent ?? '',
    };
  });
  report(
    'a drag released over empty space says nothing at all',
    !said.shown && said.text === '',
    `shown ${said.shown}, text ${JSON.stringify(said.text)}`,
  );
}

/** Drive left-drag over plane that fills view, which orbits rather than building.
 *
 *  Press on such plane used to start construction drag, and with every pixel under plane
 *  there was no empty glass left to orbit from. Camera is dropped onto ground plane so its
 *  disc spans frame; hover must read backdrop throughout, and drag must build nothing.
 */
export async function driveBackdropPlane(
  page: Page, width: number, height: number,
): Promise<void> {
  await clearTheGlass(page);
  const filled = await page.evaluate(async () => {
    const wait = (milliseconds: number): Promise<void> =>
      new Promise((done) => setTimeout(done, milliseconds));
    const ground = nimSceneHandles().find((one) => nimObjectLabel(one) === 'ground') ?? -1;
    nimSetCameraPivot(0, 0, 0);
    nimSetCameraDistance(1.5);
    nimSetCameraAzimuth(0.9);
    nimSetCameraElevation(0.9);
    await wait(300);
    // Off middle, where opening scene's origin point stands; disc spans whole frame.
    const canvas = document.getElementById('gl') as HTMLCanvasElement;
    nimUpdateCursor(canvas.clientWidth / 2 + 180, canvas.clientHeight / 2 + 140);
    nimUpdateHover(canvas.clientWidth, canvas.clientHeight);
    return {
      ground, hovered: nimHoverHandle(), is_backdrop: nimIsHoverBackdrop(),
      azimuth: nimCameraAzimuth(), objects: nimSceneCount(),
    };
  });

  await page.mouse.move(width / 2 + 180, height / 2 + 140);
  await page.mouse.down();
  for (let step = 1; step <= 6; step += 1) {
    await page.mouse.move(width / 2 + 180 + 30 * step, height / 2 + 140);
    await waitFrames(page, 2);
  }
  const is_drag_mid = await page.evaluate(() => nimDragActive());
  await page.mouse.up();
  await settleCamera(page);
  const after = await page.evaluate(
    () => ({ azimuth: nimCameraAzimuth(), objects: nimSceneCount() }),
  );

  report(
    'a plane filling the view is backdrop: a drag on it orbits instead of building',
    filled.hovered === filled.ground && filled.is_backdrop && !is_drag_mid &&
      Math.abs(after.azimuth - filled.azimuth) > 0.05 && after.objects === filled.objects,
    `hovered ${filled.hovered === filled.ground ? 'ground' : 'handle ' + filled.hovered}, ` +
      `backdrop ${filled.is_backdrop}, drag ${is_drag_mid ? 'active' : 'refused'}, azimuth ` +
      `${filled.azimuth.toFixed(3)} -> ${after.azimuth.toFixed(3)}, objects ` +
      `${filled.objects} -> ${after.objects}`,
  );
}
