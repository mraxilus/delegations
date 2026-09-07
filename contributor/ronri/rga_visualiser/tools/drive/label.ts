// Checks for name each selected object wears; not Nim because crossing forfeits check compiler
//   makes over its `page.evaluate` bodies, which name bridge's derived exports and page's own
//   `selectOnly`. Overlay's `<text>` is reachable through glue; losing that check is not.
//   Label is placed by `marker.nim` and drawn in object's ink, haloed in backdrop's colour.
//   Selected through page's own entry throughout: bare `nimSelect*` moves Nim's selection
//   and never tells page, so overlay would carry no label at all to read.

import type { Page } from '@playwright/test';
import { settleCamera } from './camera';
import { clearTheGlass } from './gestures';
import { report } from './report';


/** How many steps each orbit is walked in, and how many of those two together make. */
const STEPS_ORBIT = 200, FRAMES_WANTED = 400;

/** Label's own place this step, and window it must stay inside. */
interface Standing {
  x: number;
  y: number;
  width: number;
  height: number;
}

/** Read first overlay label's place, or nothing where overlay carries none. */
async function labelStanding(page: Page): Promise<Standing | null> {
  return page.evaluate(() => {
    const text = document.querySelector('#overlay text');
    const rect = (document.getElementById('gl') as HTMLElement).getBoundingClientRect();
    if (text === null) return null;
    return {
      x: Number(text.getAttribute('x')), y: Number(text.getAttribute('y')),
      width: rect.width, height: rect.height,
    };
  });
}

/** What walking two orbits did to one label. */
interface Walked {
  frames: number;
  hops: number;
  out_of_view: number;
  step_most: number;
}

/** Walk camera round one orbit at this elevation, watching label step by step. */
async function walkOrbit(page: Page, elevation: number, walked: Walked): Promise<void> {
  let before: Standing | null = null, step_before = 0;
  for (let i = 0; i <= STEPS_ORBIT; i += 1) {
    await page.evaluate((given) => {
      nimSetCameraPivot(0, 0, 0);
      nimSetCameraDistance(19);
      nimSetCameraAzimuth(given.azimuth);
      nimSetCameraElevation(given.elevation);
    }, { azimuth: (i / STEPS_ORBIT) * 2 * Math.PI, elevation });
    await page.waitForTimeout(25);

    const at = await labelStanding(page);
    if (at === null) {
      walked.out_of_view += 1;
      before = null;
      continue;
    }
    walked.frames += 1;
    if (at.x < 0 || at.x > at.width || at.y < 0 || at.y > at.height) walked.out_of_view += 1;
    if (before !== null) {
      const step = Math.hypot(at.x - before.x, at.y - before.y);
      // Hop is long step that is also far longer than one before it, which is mock-up
      //   page's own criterion: steady glide is long steps in row, not one lurch.
      if (step > 12 && step > 2 * step_before + 1) walked.hops += 1;
      walked.step_most = Math.max(walked.step_most, step);
      step_before = step;
    }
    before = at;
  }
}

/** Drive full orbit at two elevations, and assert line's label glides through both.
 *
 *  Second elevation carries line through vertical on screen, which is where label's own
 *  placement used to jump from one end of it to other.
 */
export async function driveLabelGlide(page: Page): Promise<void> {
  await clearTheGlass(page);
  await page.keyboard.press('Home');
  await settleCamera(page);
  await page.evaluate(() => clearSelection());

  const line = await page.evaluate(
    () => nimSceneHandles().find((one) => nimObjectKindWord(one) === 'line') ?? -1,
  );
  if (line < 0) {
    report("the scene holds a line to select", false, 'none');
    return;
  }
  await page.evaluate((one) => selectOnly(one, null), line);
  await page.waitForTimeout(300);

  const walked: Walked = { frames: 0, hops: 0, out_of_view: 0, step_most: 0 };
  for (const elevation of [0.4, 1.25]) await walkOrbit(page, elevation, walked);
  report(
    "a line's label glides through a full orbit and a vertical crossing, staying in view",
    walked.frames >= FRAMES_WANTED && walked.hops === 0 && walked.out_of_view === 0,
    `${walked.frames} frames, ${walked.hops} hops, ${walked.out_of_view} out of view, ` +
      `largest step ${walked.step_most.toFixed(1)} px`,
  );
  await page.evaluate(() => clearSelection());
}

/** Drive two picks, and assert each wears its own name above its marker. */
export async function driveLabelWorn(page: Page): Promise<void> {
  const points = await page.evaluate(
    () => nimSceneHandles().filter((one) => nimObjectKindWord(one) === 'point'),
  );
  await page.evaluate((given) => {
    selectOnly(given[0] ?? 0, null);
    toggleSelection(given[1] ?? 0, null);
  }, points);
  await page.waitForTimeout(400); // Overlay is staged by frame loop, not by selection.

  const worn = await page.evaluate((given) => {
    const texts = (): Element[] => Array.from(document.querySelectorAll('#overlay text'));
    const two = texts().map((text) => ({
      text: text.textContent, fill: text.getAttribute('fill'),
      stroke: text.getAttribute('stroke'),
      y: Number(text.getAttribute('y')),
    }));
    const one = given[0] ?? 0;
    const rgb = nimInkColor(nimObjectInk(one));
    const paint = (colour: number[]): string =>
      Math.round((colour[0] ?? 0) * 255) + ',' + Math.round((colour[1] ?? 0) * 255) + ',' +
        Math.round((colour[2] ?? 0) * 255);
    const anchor = Array.from(nimAnchorScreen(one, window.innerWidth, window.innerHeight));
    // Halo wears backdrop's colour at marker.nim's alpha; see `overlay.COLOUR_LABEL_HALO`.
    const halo = 'rgba(' + paint(nimInkColor(nimInkBackdrop())) + ',' +
      (nimOverlayMetrics()[5] ?? 0) + ')';
    const face = texts().length > 0 ? getComputedStyle(texts()[0] as Element) : null;
    return {
      count: two.length, first: two.find((text) => text.text === nimObjectLabel(one)),
      ink: 'rgb(' + paint(rgb) + ')', halo, anchor_y: anchor[1] ?? 0,
      labels: [nimObjectLabel(one), nimObjectLabel(given[1] ?? 0)],
      weight: face?.fontWeight ?? '', size: face?.fontSize ?? '',
    };
  }, points);

  report(
    'a selected object wears its name above its marker, in its ink, haloed',
    worn.count === 2 && worn.first !== undefined && worn.first.fill === worn.ink &&
      worn.first.stroke === worn.halo && worn.first.y < worn.anchor_y &&
      worn.weight === '600' && worn.size === '16px',
    `${worn.count} labels for two selected (${worn.labels.join(', ')}); ` +
      (worn.first === undefined ? 'first label missing'
        : `fill ${worn.first.fill} (ink ${worn.ink}), y ${worn.first.y.toFixed(0)} above ` +
          `anchor ${worn.anchor_y.toFixed(0)}, ${worn.weight} at ${worn.size}`),
  );

  await clearTheGlass(page);
  await page.evaluate(() => clearSelection());
  await page.waitForTimeout(400);
  const count_cleared = await page.evaluate(
    () => document.querySelectorAll('#overlay text').length,
  );
  report(
    'and nothing selected wears no label',
    count_cleared === 0, `${count_cleared} labels with nothing selected`,
  );
}
