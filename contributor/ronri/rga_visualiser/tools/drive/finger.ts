// Checks for drags as finger really performs them, and for scale bar; not Nim because touch
//   goes through Chrome's own protocol and bar is read out of DOM, neither reachable from Nim.
//   These run last, and deliberately so: they build objects, and budget and zoom checks above
//   are written against opening scene's own weight and layout.

import type { CDPSession, Page } from '@playwright/test';
import { settleCamera } from './camera';
import { settleReading, waitFrames } from './frame';
import { clearTheGlass } from './gestures';
import { report } from './report';
import { touchAt } from './touch';
import { pixelOf } from './wheel';

/** Handles of every point in scene, read afresh since checks above delete and build. */
async function pointsLive(page: Page): Promise<number[]> {
  return page.evaluate(
    () => nimSceneHandles().filter((one) => nimObjectKindWord(one) === 'point'),
  );
}

/** Drive finger that eases into its drag rather than flicking.
 *
 *  Press target chooses scheme, so press on object is construction press from moment it lands
 *  -- but touch used to orbit over few pixels before tap slop was crossed, which latched
 *  camera-dragging flag, and hover is suppressed while camera moves. Construction drag that
 *  armed moment later then ran blind for rest of gesture: no destination, no preview, nothing
 *  built. Driven here in sub-slop steps, which is what real finger does and what no
 *  flick-speed check could reach.
 */
export async function driveCreep(page: Page, cdp: CDPSession): Promise<void> {
  await clearTheGlass(page);
  await page.keyboard.press('Home');
  await settleCamera(page);
  await page.evaluate(() => nimSelectClear());

  const points = await pointsLive(page);
  const first = points[0], second = points[1];
  if (first === undefined || second === undefined) {
    report('the scene holds two points to drag between', false, `${points.length} points`);
    return;
  }
  const before = await page.evaluate(() => nimSceneCount());
  const camera_before = await page.evaluate(
    () => ({ azimuth: nimCameraAzimuth(), elevation: nimCameraElevation() }),
  );
  const from = await pixelOf(page, first);
  const onto = await pixelOf(page, second);
  if (from === null || onto === null) return;

  // Four steps of third of slop each, so gesture spends three moves under threshold before
  //   crossing it, which is exactly frames that used to orbit.
  const step_creep = (await page.evaluate(() => nimTapSlop())) / 3;
  const start = { x: from[0] ?? 0, y: from[1] ?? 0 };
  await touchAt(cdp, 'touchStart', [start]);
  await waitFrames(page, 2);
  const away = Math.hypot((onto[0] ?? 0) - start.x, (onto[1] ?? 0) - start.y);
  for (let step = 1; step <= 4; step += 1) {
    const reach = (step * step_creep) / away;
    await touchAt(cdp, 'touchMove', [{
      x: start.x + ((onto[0] ?? 0) - start.x) * reach,
      y: start.y + ((onto[1] ?? 0) - start.y) * reach,
    }]);
    await waitFrames(page, 2);
  }

  // Chase object's live pixel, not memorised one: press starts aim tween, which glides camera
  //   pivot toward drag, so every anchor moves on screen while gesture is still in flight.
  //   Real finger tracks thing it is reaching for; finger creeping to where object stood at
  //   press misses it by exactly tween's progress.
  for (let step = 1; step <= 8; step += 1) {
    const live = await pixelOf(page, second);
    if (live === null) break;
    await touchAt(cdp, 'touchMove', [{
      x: start.x + (((live[0] ?? 0) - start.x) * step) / 8,
      y: start.y + (((live[1] ?? 0) - start.y) * step) / 8,
    }]);
    await waitFrames(page, 2);
  }
  // Last touch settles on wherever object stands now, so hover read below is claim about
  //   picking rather than about how far tween happened to get.
  const settled = await pixelOf(page, second);
  if (settled !== null) {
    await touchAt(cdp, 'touchMove', [{ x: settled[0] ?? 0, y: settled[1] ?? 0 }]);
  }
  await waitFrames(page, 2);
  const mid = await page.evaluate(
    () => ({ hover: nimHoverHandle(), is_dragging: nimDragActive() }),
  );
  await touchAt(cdp, 'touchEnd', []);
  await settleCamera(page);
  const camera_after = await page.evaluate(
    () => ({ azimuth: nimCameraAzimuth(), elevation: nimCameraElevation() }),
  );
  const after = await page.evaluate(() => nimSceneCount());

  report(
    'a finger easing into its drag still sees what it is pointing at',
    mid.is_dragging && mid.hover === second && after === before + 1,
    `dragging ${mid.is_dragging}, hovering ${mid.hover} (wanted ${second}), ` +
      `${after} objects, was ${before}`,
  );
  report(
    'and it never moved the camera on the way',
    Math.abs(camera_after.azimuth - camera_before.azimuth) < 1e-6 &&
      Math.abs(camera_after.elevation - camera_before.elevation) < 1e-6,
    `azimuth ${camera_before.azimuth.toFixed(4)} -> ${camera_after.azimuth.toFixed(4)}, ` +
      `elevation ${camera_before.elevation.toFixed(4)} -> ` +
      `${camera_after.elevation.toFixed(4)}`,
  );
}

/** Count sampled pixels of canvas this handle answers hover at. */
async function pixelsPicking(page: Page, handle: number): Promise<number> {
  return page.evaluate((one) => {
    let found = 0;
    for (let y = 40; y < window.innerHeight - 40; y += 40) {
      for (let x = 40; x < window.innerWidth - 40; x += 40) {
        nimUpdateCursor(x, y);
        nimUpdateHover(window.innerWidth, window.innerHeight);
        if (nimHoverHandle() === one) found += 1;
      }
    }
    return found;
  }, handle);
}

/** Drive gesture that builds plane, and assert it is pickable over disc it is drawn as.
 *
 *  Hit test read depth of raw meet, whose weight carries which side ray crossed from, so plane
 *  met from behind its normal read as standing behind eye and could not be picked anywhere at
 *  all -- while ground plane, whose normal happens to face eye, picked fine and hid it.
 */
export async function drivePlaneBuilt(page: Page, cdp: CDPSession): Promise<void> {
  await clearTheGlass(page);
  // Drop lines earlier gestures left: each built same join again, and coincident lines under
  //   one finger are crowd touch refuses to drag from. Line built below is then alone.
  await page.evaluate(() => {
    for (const one of nimSceneHandles()) {
      if (nimObjectKindWord(one) === 'line') nimRemoveObject(one);
    }
  });
  // Stand three points of this check's own, and span plane from those rather than from
  //   whichever points earlier checks left.
  //   Claim below is about pixels disc covers, and plane sight nearly lies in says nothing
  //   about picking: it draws sliver whatever picking does, and frame rule turns nothing
  //   for anything finite. Points scene happened to carry spanned exactly such plane.
  //   `x + y + z = 3` faces opening sight within twenty degrees. Each point stands about
  //   170 px from every seed and from other two, well clear of `RADIUS_CROWD_TOUCH`.
  const spanning = await page.evaluate(() => [[3, 0, 0], [0, 3, 0], [0, 0, 3]].map((at) => {
    const model = new Array(16).fill(0);
    model[1] = at[0] ?? 0;
    model[2] = at[1] ?? 0;
    model[3] = at[2] ?? 0;
    model[4] = 1;
    return nimAddObject(model, 'span', nimDefaultInk(), nimDefaultRadius(), 0);
  }));
  await page.keyboard.press('Home');
  await settleCamera(page);
  await page.evaluate(() => nimSelectClear());

  // Name planes standing before drag, so plane read back below is one drag built rather
  //   than any plane earlier check left.
  const planes_before = await page.evaluate(() => nimSceneHandles().filter(
    (one) => nimObjectKindWord(one) === 'plane',
  ));
  const from = await pixelOf(page, spanning[0] ?? 0);
  const onto = await pixelOf(page, spanning[1] ?? 0);
  const third = await pixelOf(page, spanning[2] ?? 0);
  if (from === null || onto === null || third === null) return;

  await touchAt(cdp, 'touchStart', [{ x: from[0] ?? 0, y: from[1] ?? 0 }]);
  for (let step = 1; step <= 8; step += 1) {
    await touchAt(cdp, 'touchMove', [{
      x: (from[0] ?? 0) + (((onto[0] ?? 0) - (from[0] ?? 0)) * step) / 8,
      y: (from[1] ?? 0) + (((onto[1] ?? 0) - (from[1] ?? 0)) * step) / 8,
    }]);
    await waitFrames(page, 2);
  }
  await touchAt(cdp, 'touchEnd', []);
  await settleCamera(page);

  const line = await page.evaluate(
    () => nimSceneHandles().find((one) => nimObjectKindWord(one) === 'line') ?? -1,
  );
  const on_line = await page.evaluate((one) => {
    const at = nimAnchorScreen(one, window.innerWidth, window.innerHeight);
    return at.length === 0 ? null : [at[0] ?? 0, at[1] ?? 0];
  }, line);
  if (on_line === null) return;

  // Mouse, not finger, for this leg: line's anchor stands within crowd reach of point, which
  //   is exactly what touch refuses to drag from, and what is under test is plane's pick.
  await page.mouse.move(on_line[0] ?? 0, on_line[1] ?? 0);
  await page.mouse.down({ button: 'left' });
  // Chase third point's live pixel, for reason creep leg above records: press starts aim
  //   tween, and over this drag it carries that point far enough that drag aimed where it
  //   stood at press lets go over empty glass and builds nothing.
  for (let step = 1; step <= 8; step += 1) {
    const live = (await pixelOf(page, spanning[2] ?? 0)) ?? third;
    await page.mouse.move(
      (on_line[0] ?? 0) + (((live[0] ?? 0) - (on_line[0] ?? 0)) * step) / 8,
      (on_line[1] ?? 0) + (((live[1] ?? 0) - (on_line[1] ?? 0)) * step) / 8,
    );
    await waitFrames(page, 2);
  }
  const dropped = (await pixelOf(page, spanning[2] ?? 0)) ?? third;
  await page.mouse.move(dropped[0] ?? 0, dropped[1] ?? 0);
  await waitFrames(page, 2);
  await page.mouse.up({ button: 'left' });
  await settleCamera(page);

  const plane = await page.evaluate((standing) => nimSceneHandles().find(
    (one) => nimObjectKindWord(one) === 'plane' && !standing.includes(one),
  ) ?? -1, planes_before);
  // Sweep canvas for pixel that picks it: disc this size covers good part of view, so finding
  //   none at all is fault this guards against.
  const found = plane < 0 ? 0 : await pixelsPicking(page, plane);
  report(
    'a plane the gesture built can be pointed at where it is drawn',
    plane >= 0 && found > 0, `plane handle ${plane}, picked at ${found} sampled pixels`,
  );
  await drivePlaneSides(page);
}

/** Assert plane picks from underneath as readily as from above.
 *
 *  Plane has two faces and neither is its front: hit test asks where sight ray crosses, and
 *  where is not side. Reading crossing's orientation as its depth makes plane met from behind
 *  its own normal report itself behind eye and go unpickable over its whole disc. Ground plane
 *  is honest subject: it lies flat, so above and below are same view mirrored.
 */
async function drivePlaneSides(page: Page): Promise<void> {
  const ground = await page.evaluate(
    () => nimSceneHandles().find((one) => nimObjectLabel(one) === 'ground') ?? -1,
  );
  // Hide everything else, so point or line standing in front cannot take pixel plane would
  //   have answered for and make two sides differ for that reason.
  const hidden = await page.evaluate((keep) => {
    const away = nimSceneHandles().filter((one) => one !== keep && nimObjectVisible(one));
    for (const one of away) nimSetVisible(one, false);
    return away;
  }, ground);

  // Eye stays on its own bearing and separation, and rises or falls by `rise` over run.
  const seenAt = async (rise: number): Promise<number> => {
    await page.evaluate((given) => {
      const eye = nimCameraEye(), pivot = nimCameraPivot(), distance = nimCameraDistance();
      const across = (eye[0] ?? 0) - (pivot[0] ?? 0), along = (eye[1] ?? 0) - (pivot[1] ?? 0);
      const run = Math.hypot(across, along);
      const out = [across / run, along / run, given];
      const scale = distance / Math.hypot(...out);
      nimPlaceCamera(
        (pivot[0] ?? 0) + scale * (out[0] ?? 0), (pivot[1] ?? 0) + scale * (out[1] ?? 0),
        (pivot[2] ?? 0) + scale * (out[2] ?? 0), pivot[0] ?? 0, pivot[1] ?? 0, pivot[2] ?? 0,
      );
    }, rise);
    return pixelsPicking(page, ground);
  };
  const above = await seenAt(1.26);
  const below = await seenAt(-1.26);
  const edge_on = await seenAt(0.0);
  await page.evaluate((away) => {
    for (const one of away) nimSetVisible(one, true);
  }, hidden);
  await page.keyboard.press('Home');

  report(
    'and from underneath it, as readily as from above',
    above > 20 && below > 20 && Math.min(above, below) > 0.5 * Math.max(above, below),
    `${above} pixels from above, ${below} from below, ${edge_on} edge-on`,
  );
}

/** Drive camera out by decades, and assert scale bar measures what it says.
 *
 *  Bar drawn from one derivation and labelled from another is classic way map scale goes
 *  quietly wrong, so both halves are checked against bridge's own ruler -- and at two
 *  distances apart, since span steps 1-2-5 by decade and bar that ignored step would still
 *  pass at single distance.
 */
export async function driveRuler(page: Page): Promise<void> {
  const rulers = [];
  for (const distance of [19, 4000]) {
    await page.evaluate((given) => nimSetCameraDistance(given), distance);
    await settleCamera(page);
    await settleReading(page);
    rulers.push(await page.evaluate((given) => {
      const metrics = nimRuler(window.innerWidth, window.innerHeight);
      const span = metrics[0] ?? 0, pixels = metrics[1] ?? 0;
      return {
        distance: given, span, pixels,
        label: document.getElementById('ruler-label')?.textContent ?? '',
        reading: nimRulerReading(span),
        width: document.getElementById('ruler-bar')?.getBoundingClientRect().width ?? 0,
        is_hidden: document.getElementById('ruler')?.hidden ?? true,
      };
    }, distance));
  }
  await page.evaluate(() => nimSetCameraDistance(19));

  // Largest 1-2-5 step at or under 130 px lands no shorter than two fifths of it.
  const isStep = (span: number): boolean => {
    const lead = span / Math.pow(10, Math.floor(Math.log10(span)));
    return [1, 2, 5].some((step) => Math.abs(lead - step) < 1e-9);
  };
  const true_ones = rulers.filter((one) =>
    !one.is_hidden && one.span > 0 && isStep(one.span) &&
    Math.abs(one.width - one.pixels) <= 1.5 && one.pixels <= 130 && one.pixels >= 52 &&
    one.label === one.reading);
  report(
    'the scale bar is as long as the distance it claims, at every reach',
    true_ones.length === rulers.length && rulers[0]?.span !== rulers[1]?.span,
    rulers.map((one) => `at ${one.distance}: "${one.label}" over ${one.width.toFixed(1)}px ` +
      `(claims ${one.pixels.toFixed(1)}px)`).join('; '),
  );

  // Bar belongs to view it measures, so it stays put and drawer is simply drawn over it. It
  //   used to step aside to drawer's far edge, which on phone -- where drawer is full-width
  //   sheet -- put it off-screen entirely; reading that vanishes when panel opens is worse
  //   than one panel is sitting on.
  const covered = await page.evaluate(() => {
    const ruler = document.getElementById('ruler');
    const drawer = document.querySelector('.drawer');
    if (ruler === null || drawer === null) return null;
    const closed = ruler.getBoundingClientRect();
    document.getElementById('button-drawer')?.click();
    const open = ruler.getBoundingClientRect();
    const layerOf = (element: Element): number => Number(getComputedStyle(element).zIndex);
    const is_shown = getComputedStyle(ruler).display !== 'none' &&
      getComputedStyle(ruler).visibility !== 'hidden' && !ruler.hidden;
    document.getElementById('button-drawer')?.click(); // Leave it as it was found.
    return {
      moved: Math.abs(open.left - closed.left) + Math.abs(open.top - closed.top),
      is_shown, ruler: layerOf(ruler), drawer: layerOf(drawer), width: open.width,
    };
  });
  report(
    'the drawer covers the scale bar rather than moving it aside or hiding it',
    covered !== null && covered.moved === 0 && covered.is_shown && covered.width > 0 &&
      covered.ruler < covered.drawer,
    covered === null ? 'no ruler on the page'
      : `moved ${covered.moved}px, shown ${covered.is_shown}, layer ${covered.ruler} under ` +
        `the drawer's ${covered.drawer}`,
  );
}
