// Checks that every backdrop blur shows, that drawer's blur softens what lies behind it, and
//   what that blur costs frame; not Nim because computed style, compositor capture and frame
//   timing are browser's own, and Nim reaches them only through glue that would leave every
//   expression here unchecked string.
//   Blur stays on for reader, by ruling of #453, and every other check runs with it off,
//   through page's own experiment pill: it is compositor work over canvas that changes each
//   frame, which software rasteriser pays most for, and no other check asks about it.

import type { Page } from '@playwright/test';
import { advanceFrames } from './clock';
import { report } from './report';

/** Every blurred surface page declares, with radius it declares; mirrors `pages/shell.html`. */
const BLURS_DECLARED: [string, string][] = [
  ['.brand', 'blur(10px)'],
  ['.toggles', 'blur(10px)'],
  ['.help-open', 'blur(9px)'],
  ['.drawer', 'blur(16px)'],
];

/** Share of steps that reading of detail stands above: steps of line edges, not of empty sky.
 *
 *  Lines crossing drawer cover well under one percent of its band, so mean over it is mostly
 *  empty backdrop and moves little either way.
 */
const SHARE_STEP_READ = 0.999;

/** Share of detail behind drawer that its blur may leave.
 *
 *  Harness read 20.76 luma levels without blur and 0.72 through it, share of 0.035; drawer
 *  whose blur dropped out reads near one.
 */
const SHARE_DETAIL_BLURRED = 0.25;

/** Least detail, in luma levels, scene behind drawer must show without blur.
 *
 *  Guards against reading nothing: blur over blank backdrop softens nothing, and ratio of two
 *  blank readings says nothing about blur.
 */
const DETAIL_SHARP_LEAST = 5;

/** Columns kept clear of drawer's right edge, whose one-pixel border no blur touches. */
const PIXELS_EDGE_SKIPPED = 4;

/** Rows kept clear at top and bottom of drawer, where brand pill and scale bar stand over it.
 *
 *  Both draw sharp whatever drawer does, so band holding them reads same detail either way.
 */
const PIXELS_CHROME_CLEARED = 70;

/** How many real frames blur's cost is sampled over, each way. */
const FRAMES_SAMPLE_BLUR = 40;

/** Bound on what drawer's blur adds to median frame at largest scene, in ms.
 *
 *  1.5 times slowest reading of runner and delegate, frames paced to display as reader sees
 *  them; readings are in `PROVENANCE.md`, Browser front-end, beside it.
 */
const MILLISECONDS_BLUR_DRAWER = 25;

/** Switch every blur on or off through page's own experiment pill, as reader's click does.
 *
 *  Pill rather than class written here: pill holds its own state, and check of pills
 *  (`rings.driveExperiments`) reads state it left.
 */
export async function setBlur(page: Page, is_on: boolean): Promise<void> {
  await page.evaluate((wanted) => {
    const pill = document.getElementById('toggle-blur');
    if (pill !== null && pill.classList.contains('on') !== wanted) pill.click();
  }, is_on);
}

/** Read backdrop filter each declared surface computes to, in order declared. */
async function filtersComputed(page: Page): Promise<string[]> {
  return page.evaluate((declared) => declared.map(([selector]) => {
    const element = document.querySelector(selector);
    return element === null ? 'absent' : getComputedStyle(element).backdropFilter;
  }), BLURS_DECLARED);
}

/** Assert every surface blurs by radius it declares when page opens, and none with pill off.
 *
 *  Run first on fresh page, before harness turns blur off: what page opens with is what
 *  reader sees.
 */
export async function driveBlurDeclared(page: Page): Promise<void> {
  const opened = await filtersComputed(page);
  const wanted = BLURS_DECLARED.map(([, filter]) => filter);
  report(
    'every blurred surface blurs by its declared radius when the page opens',
    opened.every((filter, i) => filter === wanted[i]),
    BLURS_DECLARED.map(([selector], i) => `${selector} ${opened[i] ?? 'none'}`).join(', '),
  );
  await setBlur(page, false);
  const left = await page.evaluate(() => Array.from(document.querySelectorAll('*'))
    .filter((element) => getComputedStyle(element).backdropFilter !== 'none').length);
  await setBlur(page, true);
  const back = await filtersComputed(page);
  report(
    'and the pill takes every blur off, and puts each back',
    left === 0 && back.every((filter, i) => filter === wanted[i]),
    `${left} surfaces still blurred with the pill off`,
  );
}

/** Read detail of page region through compositor: step between neighbours at `SHARE_STEP_READ`.
 *
 *  Compositor rather than canvas: blur is compositor's own work, and canvas holds none of it.
 */
async function detailOf(
  page: Page, clip: { x: number; y: number; width: number; height: number },
): Promise<number> {
  const encoded = (await page.screenshot({ clip })).toString('base64');
  return page.evaluate(async (given) => {
    const image = new Image();
    await new Promise<void>((done, fail) => {
      image.onload = (): void => { done(); };
      image.onerror = (): void => { fail(new Error('capture did not decode')); };
      image.src = `data:image/png;base64,${given.encoded}`;
    });
    const flat = document.createElement('canvas');
    flat.width = image.width;
    flat.height = image.height;
    const paper = flat.getContext('2d');
    if (paper === null) throw new Error('no 2d context to decode capture into');
    paper.drawImage(image, 0, 0);
    const data = paper.getImageData(0, 0, flat.width, flat.height).data;
    const lumaAt = (x: number, y: number): number => {
      const at = (y * flat.width + x) * 4;
      return 0.2126 * (data[at] ?? 0) + 0.7152 * (data[at + 1] ?? 0) + 0.0722 * (data[at + 2] ?? 0);
    };
    const steps: number[] = [];
    for (let y = 0; y + 1 < flat.height; y += 1) {
      for (let x = 0; x + 1 < flat.width; x += 1) {
        const here = lumaAt(x, y);
        steps.push(Math.abs(lumaAt(x + 1, y) - here), Math.abs(lumaAt(x, y + 1) - here));
      }
    }
    steps.sort((a, b) => a - b);
    return steps[Math.floor(given.share * (steps.length - 1))] ?? 0;
  }, { encoded, share: SHARE_STEP_READ });
}

/** Open drawer with its contents hidden, so its frosted backdrop is all region shows. */
async function openDrawerBare(page: Page): Promise<{ x: number; y: number; width: number;
  height: number; }> {
  await page.evaluate(() => {
    const drawer = document.getElementById('drawer');
    if (drawer !== null && !drawer.classList.contains('open')) {
      document.getElementById('button-drawer')?.click();
    }
    const style = document.createElement('style');
    style.id = 'reading-drawer-bare';
    style.textContent = '.drawer > * { visibility: hidden !important; }';
    document.head.appendChild(style);
  });
  await advanceFrames(page, 4);
  return page.evaluate((cleared) => {
    const box = (document.getElementById('drawer') as HTMLElement).getBoundingClientRect();
    return {
      x: Math.max(0, Math.ceil(box.left)), y: Math.ceil(box.top) + cleared.rows,
      width: Math.floor(box.width) - cleared.columns,
      height: Math.floor(box.height) - 2 * cleared.rows,
    };
  }, { columns: PIXELS_EDGE_SKIPPED, rows: PIXELS_CHROME_CLEARED });
}

/** Shut drawer opened by `openDrawerBare`, and show its contents again. */
async function shutDrawerBare(page: Page): Promise<void> {
  await page.evaluate(() => {
    document.getElementById('reading-drawer-bare')?.remove();
    if (document.getElementById('drawer')?.classList.contains('open') ?? false) {
      document.getElementById('button-drawer')?.click();
    }
  });
  await advanceFrames(page, 4);
}

/** Assert drawer's blur softens scene behind it, against same region with blur off.
 *
 *  Computed style alone passes where compositor drops filter: style says what was asked,
 *  and capture says what reader got.
 */
export async function driveDrawerBlurs(page: Page): Promise<void> {
  const clip = await openDrawerBare(page);
  await setBlur(page, false);
  await advanceFrames(page, 2);
  const sharp = await detailOf(page, clip);
  await setBlur(page, true);
  await advanceFrames(page, 2);
  const soft = await detailOf(page, clip);
  await shutDrawerBare(page);
  report(
    'the drawer blurs the scene behind it',
    sharp >= DETAIL_SHARP_LEAST && soft <= SHARE_DETAIL_BLURRED * sharp,
    `step ${soft.toFixed(2)} through the blur against ${sharp.toFixed(2)} without it, ` +
      `over ${clip.width} by ${clip.height} px`,
  );
}

/** Sample median frame on real clock while camera moves, so compositor redraws every frame.
 *
 *  Camera's distance steps out and back each frame: canvas then changes every frame, and
 *  blur over still canvas is cached rather than paid.
 */
async function medianFrame(page: Page, frames: number): Promise<number> {
  return page.evaluate(async (count) => {
    const next = (): Promise<number> => new Promise((done) => requestAnimationFrame(done));
    const distance = nimCameraDistance();
    const deltas: number[] = [];
    let last = await next();
    for (let i = 0; i < count; i += 1) {
      nimSetCameraDistance(distance * (i % 2 === 0 ? 1.001 : 1.0));
      const now = await next();
      deltas.push(now - last);
      last = now;
    }
    nimSetCameraDistance(distance);
    deltas.sort((a, b) => a - b);
    return deltas[Math.floor(deltas.length / 2)] ?? -1;
  }, frames);
}

/** Assert drawer's blur adds to median frame no more than its bound, at largest scene.
 *
 *  Speed check, so on real clock, and sampled as count of frames each way. Open drawer over
 *  largest scene is where blur costs most: it redraws over every frame canvas changes.
 */
export async function driveBlurCost(page: Page, objects: number): Promise<void> {
  await page.evaluate(() => {
    if (!(document.getElementById('drawer')?.classList.contains('open') ?? false)) {
      document.getElementById('button-drawer')?.click();
    }
  });
  await page.waitForFunction(() => {
    const box = document.getElementById('drawer')?.getBoundingClientRect();
    return box !== undefined && box.left >= 0;
  });
  await setBlur(page, false);
  const without = await medianFrame(page, FRAMES_SAMPLE_BLUR);
  await setBlur(page, true);
  const blurred = await medianFrame(page, FRAMES_SAMPLE_BLUR);
  await setBlur(page, false);
  await page.evaluate(() => { document.getElementById('button-drawer')?.click(); });
  const added = blurred - without;
  report(
    `the drawer's blur adds no more than its bound to a frame over ${objects} objects`,
    added <= MILLISECONDS_BLUR_DRAWER,
    `median ${blurred.toFixed(1)} ms with it and ${without.toFixed(1)} ms without, so it adds ` +
      `${added.toFixed(1)} ms, wanted at most ${MILLISECONDS_BLUR_DRAWER}`,
  );
}
