// Checks for demo preset, which is build's own stress case; not Nim because button is pressed
//   through Playwright, which node alone reaches, and because crossing would forfeit check
//   compiler makes over bodies naming bridge's derived exports -- wiring rename breaks first.
//   Nim suite already checks what *scene* contains; what only this can check is that
//   pressing button gets that scene onto page, and that camera it leaves behind holds
//   arrangement.
//   Which size: arrangement comes in three, and this runs at default -- what reader gets
//   pressing button without thinking about it. Checks under load re-load at largest, because
//   band that only ever runs at default cannot see regression that shows under load.

import type { Page } from '@playwright/test';
import { settleCamera } from './camera';
import { readCanvas, settleCanvas } from './canvas';
import { report } from './report';

/** Kinds preset must carry, each of which draws something. */
const KINDS_DRAWING = [
  'point', 'line', 'plane', 'horizon point', 'horizon line', 'horizon plane',
];

/** How many objects default size comes to, or override named for run driven by hand. */
export async function objectsDefault(page: Page): Promise<number> {
  const named = Number(process.env['RGA_DEMO_OBJECTS'] ?? 0);
  return named || page.evaluate(() => nimDemoObjects(nimDemoScaleDefault()));
}

/** How many objects largest size comes to. */
export async function objectsLargest(page: Page): Promise<number> {
  return page.evaluate(() => {
    const scales = nimDemoScales();
    return nimDemoObjects(scales[scales.length - 1] ?? 0);
  });
}

/** Press button that loads this size, as reader would, and wait for scene to arrive. */
export async function loadDemo(page: Page, objects: number): Promise<void> {
  await page.click('#button-menu');
  await page.click(`#button-load-demo-${objects}`);
  await page.click('#button-menu'); // Shut popover again, as reader would.
  await page.waitForFunction(
    (given) => nimSceneCount() === given, objects, { timeout: 120000 },
  );
  await settleCamera(page);
}

/** Drive demo button, and assert what it puts on page and where it leaves camera. */
export async function driveDemo(page: Page, objects: number): Promise<void> {
  await loadDemo(page, objects);
  const demo = await page.evaluate(() => {
    const tally: Record<string, number> = {};
    for (const one of nimSceneHandles()) {
      const word = nimObjectKindWord(one);
      tally[word] = (tally[word] ?? 0) + 1;
    }
    return {
      count: nimSceneCount(), capacity: nimSceneCapacity(), tally,
      distance: nimCameraDistance(),
    };
  });

  // Preset used to fill pool exactly, back when arrangement's own tables were whole of it.
  //   Star catalogue carries far more stars than any scene has room for, so what fills scene
  //   is target and handles above it are deliberate headroom: reader can build on top of
  //   loaded demo rather than meeting refusal. Count comes from bridge rather than being
  //   written here, so sizes stay arrangement's to change.
  report(
    'the demo button fills its target and leaves the rest of the pool free',
    demo.count === objects && demo.capacity > demo.count,
    `${demo.count} of ${demo.capacity} handles, ${demo.capacity - demo.count} free`,
  );

  // Every kind, and nothing that draws nothing: three collinear points wedge to no clean
  //   grade, and such object holds handle while drawing nothing at all.
  //   Lines carry ceiling, alone among kinds: line is infinite and every one crosses whole
  //   frame whatever it joins, so they were cut to few that mean something. Presence alone
  //   would let them creep back. Kind word reports line in horizon as its own kind, so `line`
  //   here counts only finite ones.
  //   Presence, not proportions: counts each size comes to are Nim suite's to check at all
  //   three; what only this can see is that pressing button put every kind on page.
  const undrawn = Object.keys(demo.tally).filter((word) => !KINDS_DRAWING.includes(word));
  report(
    'it carries every drawable kind, including one of each at horizon, and nothing blank',
    KINDS_DRAWING.every((word) => (demo.tally[word] ?? 0) >= 1) && undrawn.length === 0 &&
      (demo.tally['line'] ?? 0) >= 2 && (demo.tally['line'] ?? 0) <= 3,
    Object.entries(demo.tally).map(([word, n]) => `${word} ${n}`).join(', '),
  );
  // On opening camera demo loads inside its own inner planets.
  report(
    'and it stands the camera back far enough to hold what it built',
    demo.distance > 40, `camera at ${demo.distance.toFixed(1)}, opening distance is 19`,
  );
}

/** Assert culling changes no pixel, at three cameras.
 *
 *  Points outside view are skipped before emitting. Hashed at demo's own camera, dollied in
 *  and orbited, with cull on and then off, each once picture has settled; at demo's own
 *  camera most points are off screen and count row must say so.
 */
export async function driveCulling(page: Page): Promise<void> {
  /** How many camera moves are asked at, and which is which. */
  const MOVES = 3;
  const readings: Array<{
    on: { mark: number; points: number; off: number };
    off: { mark: number; points: number; off: number };
  }> = [];
  const counted = async (): Promise<{ points: number; off: number }> => page.evaluate(() => ({
    points: count_phase['points'] ?? 0, off: count_points_culled,
  }));
  for (let move = 0; move < MOVES; move += 1) {
    await page.evaluate((given) => {
      // Demo's own camera first, then closer, then round: each shows different share of scene.
      if (given === 1) nimCameraDolly(0.3);
      else if (given === 2) nimCameraOrbit(0.9, 0.3);
    }, move);
    await page.evaluate(() => nimSetCulling(true));
    const shown_on = await settleCanvas(page);
    const on = { mark: shown_on.mark, ...(await counted()) };
    await page.evaluate(() => nimSetCulling(false));
    const shown_off = await settleCanvas(page);
    const off = { mark: shown_off.mark, ...(await counted()) };
    readings.push({ on, off });
  }
  await page.evaluate(() => nimSetCulling(true));
  report(
    'points outside the view are skipped before emitting, and not one pixel changes',
    readings.every((one) => one.on.mark === one.off.mark &&
      one.on.points + one.on.off === one.off.points && one.off.off === 0) &&
      readings.some((one) => one.on.off > 0),
    readings.map((one) => `${one.on.points} of ${one.on.points + one.on.off} drawn, ` +
      `${one.on.mark === one.off.mark ? 'same' : 'different'} pixels`).join('; '),
  );
}

/** Drive camera onto line through planet and its moon, and assert disc hides what is behind.
 *
 *  Eye is set on line from planet through moon, beyond moon, so moon sits at middle of frame
 *  in front of planet's disc. Pointer sampled across disc must never hover anything deeper
 *  than planet: stars behind it used to win on distance to their own centres. Pixel at moon's
 *  centre must be moon's whether moon alone is selected or planet with it: overlay drawn with
 *  depth off buried moon under planet selected after it.
 */
export async function driveOccluded(page: Page): Promise<void> {
  const occluded = await page.evaluate(async () => {
    const wait = (milliseconds: number): Promise<void> =>
      new Promise((done) => setTimeout(done, milliseconds));
    const handleOf = (label: string): number =>
      nimSceneHandles().find((one) => nimObjectLabel(one) === label) ?? -1;
    const planet = handleOf('jupiter'), moon = handleOf('io');
    const placeOf = (one: number): number[] => Array.from(nimAnchorWorld(one)).slice(0, 3);
    const at_planet = placeOf(planet), at_moon = placeOf(moon);
    const heading = at_moon.map((v, i) => v - (at_planet[i] ?? 0));
    const span = Math.hypot(...heading);
    // Put whole camera back after: later checks zoom at this sky from where it stood.
    const before = {
      pivot: Array.from(nimCameraPivot()), distance: nimCameraDistance(),
      azimuth: nimCameraAzimuth(), elevation: nimCameraElevation(),
    };
    nimSetCameraPivot(at_planet[0] ?? 0, at_planet[1] ?? 0, at_planet[2] ?? 0);
    nimSetCameraAzimuth(Math.atan2(heading[1] ?? 0, heading[0] ?? 0));
    nimSetCameraElevation(Math.asin((heading[2] ?? 0) / span));
    nimSetCameraDistance(span * 6);
    await wait(500);

    const canvas = document.getElementById('gl') as HTMLCanvasElement;
    const width = canvas.clientWidth, height = canvas.clientHeight;
    const centre = Array.from(nimAnchorScreen(planet, width, height));
    const eye = Array.from(nimCameraEye());
    const pivot = Array.from(nimCameraPivot());
    const reach = Math.hypot(...pivot.map((v, i) => v - (eye[i] ?? 0)));
    const forward = pivot.map((v, i) => (v - (eye[i] ?? 0)) / reach);
    const depthOf = (one: number): number => placeOf(one)
      .reduce((sum, v, i) => sum + (v - (eye[i] ?? 0)) * (forward[i] ?? 0), 0);
    // Disc's radius in pixels, as mesh measures it.
    const per_pixel = (2 * depthOf(planet) *
      Math.tan(((nimCameraFov() * Math.PI) / 180) / 2)) / height;
    const radius = nimObjectRadius(planet) / per_pixel;

    const deeper: string[] = [];
    let sampled = 0;
    for (let ring = 0.2; ring <= 0.9; ring += 0.175) {
      for (let step = 0; step < 12; step += 1) {
        const angle = (step / 12) * 2 * Math.PI;
        nimUpdateCursor(
          (centre[0] ?? 0) + ring * radius * Math.cos(angle),
          (centre[1] ?? 0) + ring * radius * Math.sin(angle),
        );
        nimUpdateHover(width, height);
        sampled += 1;
        const hovered = nimHoverHandle();
        if (hovered >= 0 && depthOf(hovered) > depthOf(planet) + 1e-6) {
          deeper.push(nimObjectLabel(hovered));
        }
      }
    }

    return {
      radius, sampled, deeper, planet, moon, before,
      spot: [Math.round(centre[0] ?? 0), Math.round(centre[1] ?? 0)] as [number, number],
      is_moon_in_front: depthOf(moon) < depthOf(planet),
      is_moon_at_centre: Math.hypot(
        ...Array.from(nimAnchorScreen(moon, width, height)).slice(0, 2)
          .map((v, i) => v - (centre[i] ?? 0)),
      ) < 1,
    };
  });

  // Selection pulses, so canvas never settles here: each reading is taken at fixed wait after
  //   its own edit, as this check has always taken them, rather than waited into stillness.
  await page.evaluate((given) => { nimSelectClear(); nimSelectToggle(given); }, occluded.moon);
  await page.waitForTimeout(400);
  const alone = (await readCanvas(page, [occluded.spot])).spots[0] ?? [];
  await page.evaluate((given) => nimSelectToggle(given), occluded.planet);
  await page.waitForTimeout(400);
  const both = (await readCanvas(page, [occluded.spot])).spots[0] ?? [];
  await page.evaluate((given) => {
    nimSelectClear();
    nimSetCameraPivot(given.pivot[0] ?? 0, given.pivot[1] ?? 0, given.pivot[2] ?? 0);
    nimSetCameraDistance(given.distance);
    nimSetCameraAzimuth(given.azimuth);
    nimSetCameraElevation(given.elevation);
  }, occluded.before);
  await page.waitForTimeout(200);

  report(
    "nothing behind a planet's disc is hovered through it",
    occluded.radius > 40 && occluded.deeper.length === 0,
    `${occluded.sampled} samples inside ${occluded.radius.toFixed(0)} px disc, ` +
      `${occluded.deeper.length} hovered deeper than it` +
      (occluded.deeper.length === 0 ? '' : `: ${occluded.deeper.slice(0, 3).join(', ')}`),
  );
  report(
    'the canvas gave a pixel at all, rather than a blank readback',
    alone.slice(0, 3).some((v) => v > 0),
    `pixel at moon ${JSON.stringify(alone.slice(0, 3))}; page's darkest surface is ` +
      'rgb(16,19,24), so all zero is readback of nothing rather than dark scene',
  );
  report(
    'a selected moon in front of a selected planet is drawn in front of it',
    occluded.is_moon_in_front && occluded.is_moon_at_centre &&
      alone.every((v, i) => Math.abs(v - (both[i] ?? 0)) <= 2),
    `pixel at moon ${JSON.stringify(alone.slice(0, 3))} alone, ` +
      `${JSON.stringify(both.slice(0, 3))} with its planet selected too`,
  );
  await page.keyboard.press('Home');
  await settleCamera(page);
}

/** Drive six wheel notches at centre and off centre, and assert what each keeps.
 *
 *  Far clip used to sit at fixed multiple of orbit distance whatever scene held, so notches in
 *  at demo's centre left almost no points drawn; and zoom anchored on whatever star was under
 *  pointer, so notches off centre carried pivot several opening distances away. Off-centre
 *  spot sits right of middle, clear of drawer standing open on left.
 */
export async function driveZoomLoaded(page: Page): Promise<void> {
  await settleCamera(page);
  const opened = await page.evaluate(
    () => ({ distance: nimCameraDistance(), pivot: Array.from(nimCameraPivot()) }),
  );
  const box = await page.evaluate(() => {
    const rect = (document.getElementById('gl') as HTMLElement).getBoundingClientRect();
    return { x: rect.left, y: rect.top, width: rect.width, height: rect.height };
  });
  const zoomAt = async (across: number, down: number): Promise<{
    distance: number; pivot: number[]; points: number;
  }> => {
    await page.mouse.move(box.x + across * box.width, box.y + down * box.height);
    for (let i = 0; i < 6; i += 1) {
      await page.mouse.wheel(0, -400);
      await settleCamera(page);
    }
    await settleCamera(page);
    const after = await page.evaluate(() => ({
      distance: nimCameraDistance(), pivot: Array.from(nimCameraPivot()),
      points: count_phase['points'] ?? 0,
    }));
    await page.evaluate(() => document.getElementById('gl')?.focus());
    await page.keyboard.press('Home');
    await settleCamera(page);
    return after;
  };

  const centre = await zoomAt(0.5, 0.5);
  const corner = await zoomAt(0.85, 0.2);
  const carried = Math.hypot(
    ...corner.pivot.map((v, i) => v - (opened.pivot[i] ?? 0)),
  );
  report(
    'six notches in at the centre keep the field drawn behind the near stars',
    centre.distance < 0.1 * opened.distance && centre.points >= 200,
    `${centre.points} points drawn at distance ${centre.distance.toFixed(1)}, ` +
      `from ${opened.distance.toFixed(1)}`,
  );
  report(
    'six notches in off-centre keep the target within one opening distance',
    carried <= 1.0 * opened.distance,
    `target carried ${carried.toFixed(0)} units over an opening distance of ` +
      `${opened.distance.toFixed(0)}`,
  );
}
