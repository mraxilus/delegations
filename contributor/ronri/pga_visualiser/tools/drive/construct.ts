// Checks for building objects by dragging one onto another; not Nim because they drive real
//   pointer and touch through Playwright and Chrome's protocol, which only node reaches.
//   Whole gesture application is about: drag one object onto another and third is derived.
//   Suites reach `applyOperation`, never gesture that calls it.

import type { CDPSession, Page } from '@playwright/test';
import { MILLISECONDS_FRAME, advance, evaluateOver } from './clock';
import {
  depthOf, forwardOf, placeCamera, readCamera, readPlaced, settleCamera, spanOf, spanPivot,
} from './camera';
import { waitFrames } from './frame';
import { report } from './report';
import { clearTheGlass } from './gestures';
import { handleAlone, pixelOf } from './wheel';
import {
  asHand, dragFinger, fingerOn, handleLabelled, moveFingers, pointersDown, slipOf, tapAt,
} from './touch';
import type { Finger } from './touch';

/** Put camera back where it opened and drop selection, so each check starts alike. */
async function fromHome(page: Page): Promise<void> {
  await page.keyboard.press('Home');
  await settleCamera(page);
  await page.evaluate(() => nimSelectClear());
}

/** Drive two fingers moving together, which carry what each touched with them.
 *
 *  Points stand at two depths, so no slide square to sight holds both: grip solves for
 *  slide and roll together (repository issue 592).
 */
export async function driveTwoFingerPan(page: Page, devtools: CDPSession): Promise<void> {
  await page.keyboard.press('Home');
  await settleCamera(page);
  // Gesture before this ends in tap; finger it left standing would make three pointers of
  //   this pair, and pan below would then fail for that reason rather than its own.
  const down = await pointersDown(page);
  report(
    'no pointer is still down from the gesture before',
    down.length === 0, `ids ${down.join(', ') || 'none'}`,
  );
  const first = await handleLabelled(page, 'a');
  const second = await handleLabelled(page, 'c');
  const landed: [Finger, Finger] = [await fingerOn(page, first), await fingerOn(page, second)];
  const hand = (along: number): [Finger, Finger] =>
    asHand(landed, 1, 0, { x: 300 * along, y: 100 * along });
  const before = await readCamera(page);
  await moveFingers(page, devtools, hand);
  const after = await readCamera(page);
  const [end_first, end_second] = hand(1);
  const slips = [await slipOf(page, first, end_first), await slipOf(page, second, end_second)];

  report(
    'two fingers moving together carry what they hold with them',
    Math.max(...slips) <= 1 && spanOf(before.eye, after.eye) > 0.5,
    `points ${slips.map((slip) => slip.toFixed(2)).join(' and ')} px off their fingers, ` +
      `eye moved ${spanOf(before.eye, after.eye).toFixed(3)}`,
  );
  // Nothing is selected here, so grip slides and rolls: sight keeps its direction, and
  //   pivot rides along at its own depth. Sight read off eye and pivot through float32, so
  //   bound is float32's.
  report(
    'and leave the sight and the separation as they were',
    spanOf(forwardOf(before), forwardOf(after)) < 1e-6 &&
      Math.abs(after.distance - before.distance) < 1e-9,
    `sight moved ${spanOf(forwardOf(before), forwardOf(after)).toExponential(2)}, ` +
      `distance ${before.distance.toFixed(3)} -> ${after.distance.toFixed(3)}`,
  );
}

/** Drive finger dragging one object onto another, which builds third. */
export async function driveTouchConstruct(page: Page, devtools: CDPSession): Promise<void> {
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
  await dragFinger(page, devtools, from, onto);
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
export async function driveCrowd(page: Page, devtools: CDPSession): Promise<void> {
  await page.keyboard.press('Home');
  await settleCamera(page);
  const handles = await page.evaluate(() => nimSceneHandles());
  const first = handles[1];
  const second = handles[2];
  if (first === undefined || second === undefined) return;

  const rival = await page.evaluate((one) => {
    const model = Array.from(nimObjectCoefficients(one));
    model[1] = (model[1] ?? 0) + 0.05;
    const added = nimAddObject(model, 'rival', nimDefaultInk(), nimDefaultRadius(), 0);
    nimSelectClear();
    return added;
  }, first);
  await waitFrames(page, 2);

  const count_before = await page.evaluate(() => nimSceneCount());
  const azimuth_before = await page.evaluate(() => nimCameraAzimuth());
  const placed_before = await readPlaced(page);
  const from = await pixelOf(page, first);
  const onto = await pixelOf(page, second);
  if (from !== null && onto !== null) {
    await dragFinger(page, devtools, from, onto);
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
    await tapAt(page, devtools, still[0] ?? 0, still[1] ?? 0, 1400);
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
  await page.evaluate((one) => nimRemoveObject(one), rival);
  await placeCamera(page, placed_before);
  await settleCamera(page);
}

/** Drive drag that pauses over its aim, as careful finger really does.
 *
 *  Dwell wheel opens under finger during that pause, hidden by it; reading release as
 *  "chose nothing" would make exactly careful drags build nothing. Wheel nobody entered
 *  may not veto release. Check holds wheel really did open, so slower dwell cannot turn
 *  this into second copy of quick-lift check.
 */
export async function drivePausedDrag(page: Page, devtools: CDPSession): Promise<void> {
  await fromHome(page);
  const handles = await page.evaluate(() => nimSceneHandles());
  const first = handles[1];
  const second = handles[2];
  if (first === undefined || second === undefined) return;

  const before = await page.evaluate(() => nimSceneCount());
  const from = await pixelOf(page, first);
  const onto = await pixelOf(page, second);
  if (from === null || onto === null) return;

  await dragFinger(page, devtools, from, onto, { lift: false });
  // Simulated span: how long finger rests is gesture under test, and waiting on wheel instead
  //   would assert what check below is asking.
  await advance(page, 1100);
  const is_wheel_open = await page.evaluate(() => nimDragMenuOpen());
  await dragFinger(page, devtools, onto, onto, { press: false });
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
  // Frame drawn after each step, since drag is tracked by frame loop and not by events alone.
  for (let step = 1; step <= 8; step += 1) {
    await page.mouse.move(
      (from[0] ?? 0) + ((width - 30 - (from[0] ?? 0)) * step) / 8,
      (from[1] ?? 0) + ((height - 30 - (from[1] ?? 0)) * step) / 8,
    );
    await waitFrames(page, 1);
  }
  await page.mouse.up();
  // Simulated span: check is that nothing was said, and absence has no condition to wait on
  //   -- span has to be long enough for bar to have shown had it been going to.
  await advance(page, 300);

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
  const filled = await evaluateOver(page, 300 + 2 * MILLISECONDS_FRAME, async () => {
    const wait = (milliseconds: number): Promise<void> =>
      new Promise((done) => setTimeout(done, milliseconds));
    const ground = nimSceneHandles().find((one) => nimObjectLabel(one) === 'ground') ?? -1;
    // 1.5 units off origin and steeply above it, on its far side from opening view.
    nimPlaceCamera(0.58, 0.73, 1.17, 0, 0, 0);
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

/** Drive wheel onto point picked alone until it fills view, then right drag on it.
 *
 *  Nearer than where its sphere reaches every corner shows nothing more of it, so wheel
 *  stops at that depth. There point is backdrop, as plane filling view is: right drag on it
 *  moves view rather than arming drag that asks what to build. One notch back out, corners
 *  stand bare and it is handle again, which brackets stop to within one notch.
 */
export async function drivePointFills(page: Page): Promise<void> {
  await fromHome(page);
  // By kind, not label: checks before this one remove and build objects.
  const dot = await handleAlone(page, 'point');
  if (await page.evaluate((one) => nimObjectKindWord(one), dot) !== 'point') {
    report('a point picked alone stands on screen to wheel onto', false, 'no point on screen');
    return;
  }
  await page.evaluate((one) => nimSelectOnly(one), dot);
  await settleCamera(page);
  const at = await pixelOf(page, dot);
  if (at === null) {
    report('a point picked alone stands on screen to wheel onto', false, 'no pixel');
    return;
  }
  const [x, y] = [at[0] ?? 0, at[1] ?? 0];
  await page.mouse.move(x, y);
  const notch = async (count: number, step: number): Promise<void> => {
    for (let i = 0; i < count; i += 1) {
      await page.mouse.wheel(0, step);
      await waitFrames(page, 2);
    }
    await settleCamera(page);
  };
  const readHover = async (): Promise<{ hovered: number; is_backdrop: boolean }> =>
    page.evaluate(([cx, cy]) => {
      const canvas = document.getElementById('gl') as HTMLCanvasElement;
      nimUpdateCursor(cx ?? 0, cy ?? 0);
      nimUpdateHover(canvas.clientWidth, canvas.clientHeight);
      return { hovered: nimHoverHandle(), is_backdrop: nimIsHoverBackdrop() };
    }, [x, y]);
  // Depth where sphere's radius reaches half diagonal: inverse of `picking.isCoveringView`.
  const filling = await page.evaluate((one) => {
    const canvas = document.getElementById('gl') as HTMLCanvasElement;
    const tangent = Math.tan((0.5 * nimCameraFov() * Math.PI) / 180);
    return nimObjectRadius(one) * canvas.clientHeight /
      (tangent * Math.hypot(canvas.clientWidth, canvas.clientHeight));
  }, dot);
  const world = await page.evaluate((one) => Array.from(nimAnchorWorld(one)), dot);

  await notch(40, -120);
  const capped = await readCamera(page);
  const filled = await readHover();
  await notch(10, -120);
  const held = await readCamera(page);
  await notch(1, 120);
  const backed = await readHover();
  await notch(4, -120);

  const objects = await page.evaluate(() => nimSceneCount());
  const before = await readCamera(page);
  await page.mouse.move(x, y);
  await page.mouse.down({ button: 'right' });
  for (let step = 1; step <= 6; step += 1) {
    await page.mouse.move(x + 30 * step, y);
    await waitFrames(page, 2);
  }
  const is_drag_mid = await page.evaluate(() => nimDragActive() || nimDragMenuOpen());
  await page.mouse.up({ button: 'right' });
  await settleCamera(page);
  const after = await readCamera(page);
  const objects_after = await page.evaluate(() => nimSceneCount());

  // Eye and anchor cross bridge as float32, near 1e-7 of coordinates some units from origin;
  //   over depth near 0.1, that reads as few parts in million.
  const depth = depthOf(capped, world);
  report(
    'a wheel onto a point picked alone stops where its sphere fills the view',
    Math.abs(depth / filling - 1) < 1e-5 && spanOf(held.eye, capped.eye) < 1e-9 * filling,
    `depth ${depth.toPrecision(9)}, filling ${filling.toPrecision(9)}, ten more notches ` +
      `moved eye ${spanOf(held.eye, capped.eye).toExponential(2)}`,
  );
  report(
    'there the point is backdrop, and one notch out it is a handle again',
    filled.hovered === dot && filled.is_backdrop && backed.hovered === dot &&
      !backed.is_backdrop,
    `at fill: hovered ${filled.hovered}, backdrop ${filled.is_backdrop}; one notch out: ` +
      `hovered ${backed.hovered}, backdrop ${backed.is_backdrop}; point ${dot}`,
  );
  report(
    'a right drag on a point that fills the view moves the view and builds nothing',
    !is_drag_mid && Math.abs(after.azimuth - before.azimuth) > 0.05 &&
      objects_after === objects,
    `drag ${is_drag_mid ? 'armed' : 'refused'}, azimuth ${before.azimuth.toFixed(3)} -> ` +
      `${after.azimuth.toFixed(3)}, objects ${objects} -> ${objects_after}`,
  );
}
