// Reading what page drew, taken from compositor rather than from drawing buffer; not Nim
//   because capture is Playwright's own and decode is browser's own, neither reachable from
//   Nim except through glue leaving every expression here unchecked string.
//   Context keeps no drawing buffer (see `gl.ts`), so `readPixels` issued from task of its own
//   comes back all zero, and on some browsers comes back all zero from inside drawing frame
//   too. Four checks compared one such reading against another, so blank canvas passed every
//   one of them; hence single reader here, and hence blank reading refused rather than
//   returned.

import type { Page } from '@playwright/test';
import { report } from './report';

/** Spot on canvas, in CSS pixels from top left, as `nimAnchorScreen` reports them. */
export type Spot = [number, number];

/** One reading of what canvas shows. */
export interface Reading {
  /** Hash over every pixel, for comparing one reading against another. */
  mark: number;
  /** Colour at each spot asked for, in order asked, as RGBA. */
  spots: number[][];
  /** How many pixels carry colour at all. */
  lit: number;
  /** How many pixels were read. */
  of: number;
}

/** Canvas every reading is of, unless caller names its own. */
const CANVAS_DRAWN = '#gl';

/** Capture canvas with chrome taken out of shot, then put chrome back.
 *
 *  Element capture takes region of page canvas occupies, not canvas alone, so anything
 *  composited over it lands in reading: undo button lighting up after edit moved 2,411 pixels
 *  and read as scene having changed. Chrome is hidden rather than masked because masking asks
 *  for list of what covers canvas, and that list goes stale.
 *  `opacity` rather than `display` or `visibility`: `display` takes chrome out of layout and
 *  resizes canvas, and `visibility` blurs whatever holds focus -- hiding canvas that way cost
 *  very next check its held key, which slid view 0 units.
 */
async function canvasAlone(page: Page, selector: string): Promise<Buffer> {
  await page.evaluate((given) => {
    const style = document.createElement('style');
    style.id = 'reading-canvas-alone';
    style.textContent = `body > *:not(${given}) { opacity: 0 !important; }`;
    document.head.appendChild(style);
    return new Promise<void>((done) => { requestAnimationFrame(() => { done(); }); });
  }, selector);
  try {
    return await page.locator(selector).screenshot();
  } finally {
    await page.evaluate(() => { document.getElementById('reading-canvas-alone')?.remove(); });
  }
}

/** Read canvas through compositor, refusing reading with nothing drawn in it.
 *
 *  Compositor is asked rather than `gl.readPixels` because it is what reader sees, and
 *  because it is immune to drawing buffer being thrown away after frame that filled it.
 *  Costs around half second per reading, against microseconds for `readPixels`; every caller
 *  reads once per settled picture rather than once per frame, so that buys correctness at
 *  few seconds over whole run.
 *  Blank reading raises rather than reports: canvas nobody can read is instrument lost, not
 *  check failed, and every pixel check resting on it would be passing on nothing.
 */
export async function readCanvas(
  page: Page, spots: Spot[] = [], selector: string = CANVAS_DRAWN,
): Promise<Reading> {
  const encoded = (await canvasAlone(page, selector)).toString('base64');
  const reading = await page.evaluate(async (given): Promise<Reading> => {
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
    let mark = 2166136261;
    let lit = 0;
    for (let i = 0; i < data.length; i += 4) {
      const red = data[i] ?? 0, green = data[i + 1] ?? 0, blue = data[i + 2] ?? 0;
      if (red > 0 || green > 0 || blue > 0) lit += 1;
      mark = Math.imul(mark ^ red, 16777619) ^ green ^ (blue << 8);
    }
    const found = given.spots.map((spot) => {
      const at = (((Math.round(spot[1]) * flat.width) + Math.round(spot[0])) * 4);
      return [data[at] ?? 0, data[at + 1] ?? 0, data[at + 2] ?? 0, data[at + 3] ?? 0];
    });
    return { mark: mark | 0, spots: found, lit, of: flat.width * flat.height };
  }, { encoded, spots });
  if (reading.lit === 0) {
    throw new Error(
      `Canvas read back blank: 0 of ${reading.of} pixels carry colour. Page draws over ` +
      'rgb(16,19,24), so reading with nothing in it is capture of no canvas rather than ' +
      'capture of dark scene. Every pixel check below rests on this reading, so run stops ' +
      'here rather than passing them all on nothing.',
    );
  }
  return reading;
}

/** Read canvas until two readings running agree, and give that settled reading.
 *
 *  Settle is on what canvas shows, since that is what caller goes on to compare; picture
 *  still easing into place would otherwise be compared against its own destination.
 *  Nothing animating may be on screen when this is called -- selection pulse never settles --
 *  and caller wanting reading at fixed moment asks `readCanvas` after its own wait instead.
 */
export async function settleCanvas(page: Page, spots: Spot[] = []): Promise<Reading> {
  let last = await readCanvas(page, spots);
  for (let i = 0; i < 20; i += 1) {
    const now = await readCanvas(page, spots);
    if (now.mark === last.mark) return now;
    last = now;
  }
  throw new Error('Canvas never settled: twenty readings running, no two alike.');
}


/** Assert reader refuses reading of canvas with nothing drawn on it, against its own fixture.
 *
 *  Instrument unable to tell blank canvas from dark one is what let four checks pass on
 *  nothing, so it is checked here against fixture it stands up itself (Article IX.8) rather
 *  than trusted. Fixture is black canvas, which is hardest case: it is what dark scene and no
 *  scene both look like.
 */
export async function driveBlankRefused(page: Page): Promise<void> {
  await page.evaluate(() => {
    const flat = document.createElement('canvas');
    flat.id = 'reading-fixture';
    flat.width = 64;
    flat.height = 64;
    flat.setAttribute('style', 'position:fixed;left:0;top:0;z-index:9999');
    const paper = flat.getContext('2d');
    if (paper !== null) {
      paper.fillStyle = '#000';
      paper.fillRect(0, 0, flat.width, flat.height);
    }
    document.body.appendChild(flat);
  });
  let refused = '';
  try {
    await readCanvas(page, [], '#reading-fixture');
  } catch (raised) {
    refused = raised instanceof Error ? raised.message : String(raised);
  }
  await page.evaluate(() => { document.getElementById('reading-fixture')?.remove(); });
  report(
    'a reading the canvas gave nothing to is refused rather than returned',
    refused.startsWith('Canvas read back blank'),
    refused === '' ? 'black canvas was read as though it carried a picture'
      : `refused: ${refused.slice(0, 46)}...`,
  );
}
