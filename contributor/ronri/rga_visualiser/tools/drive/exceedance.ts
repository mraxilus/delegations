// Checks for frame-time distribution curve and axis it is drawn against; not Nim because
//   they read pixels back out of canvas, which lives only in browser.
//   Sparkline holds few seconds and says *when*; this says *how often*, which is question
//   reader chasing occasional stutter is asking.
//   Every frame this container draws is slower than 30 fps, so fast bands cannot be reached
//   by driving page harder: window is fed spread through `recordExceedance`, very call frame
//   loop makes, which exercises drawing without pretending machine is faster than it is.

import type { Page } from '@playwright/test';
import { report } from './report';

/** How deep band at each end to look in for mark's own labels.
 *
 *  This harness's own sampling window, not copy of anything page declares: rates and
 *  durations are drawn over plot rather than in rows of their own, so there is no page-side
 *  row height to read. Comfortably more than line they are set in, and comfortably less than
 *  canvas, which is all it has to be.
 */
const ROW_LABEL_DRAWN = 11;

declare global {
  interface Window {
    /** Page's own `recordExceedance`, kept while stub stands in its place. */
    __record_kept?: (delta_milliseconds: number) => void;
  }
}

/** Stub out frame loop's own feed, so window holds only what check puts in it.
 *
 *  Real frame entering window mid-settle would change very extent being waited for, and on
 *  this container every real frame is slower than anything these checks feed in.
 */
async function holdExceedance(page: Page): Promise<void> {
  await page.evaluate(() => {
    const scope = globalThis as unknown as { recordExceedance: typeof recordExceedance };
    if (window.__record_kept === undefined) window.__record_kept = scope.recordExceedance;
    scope.recordExceedance = () => { /* Held: window is fed by check alone. */ };
  });
}

/** Give frame loop its own feed back. */
async function releaseExceedance(page: Page): Promise<void> {
  await page.evaluate(() => {
    const scope = globalThis as unknown as { recordExceedance: typeof recordExceedance };
    if (window.__record_kept !== undefined) scope.recordExceedance = window.__record_kept;
  });
}

/** Feed window this many durations, drawn from what caller rolls. */
async function feedWindow(page: Page, count: number, rolls: number[][]): Promise<void> {
  await page.evaluate((given) => {
    for (let i = 0; i < given.count; i += 1) {
      const roll = Math.random();
      const band = given.rolls.find((one) => roll < (one[0] ?? 1)) ?? given.rolls[0];
      window.__record_kept?.((band?.[1] ?? 0) + Math.random() * (band?.[2] ?? 1));
    }
  }, { count, rolls });
}

/** Wait until axis has stopped travelling, since it waits and then glides. */
async function settleAxis(page: Page): Promise<void> {
  for (let i = 0; i < 48; i += 1) {
    await page.waitForTimeout(120);
    const is_settled = await page.evaluate(() => {
      drawExceedance();
      return ms_axis_restless === 0;
    });
    if (is_settled && i > 4) break;
  }
}

/** Drive curve as distribution: monotone, accounting for its window, agreeing with samples.
 *
 *  Three properties make curve distribution rather than drawing: every frame is at or over
 *  zero, share never rises as duration does, and buckets account for exactly frames in
 *  window -- plus stated 1-in-100 agreeing with same percentile taken directly off ring,
 *  which is arithmetic buckets stand in for.
 */
export async function driveCurve(page: Page): Promise<void> {
  const curve = await page.evaluate(() => {
    const counted = scanExceedance();
    let is_monotone = true;
    for (let i = 1; i < BUCKETS_EXCEEDANCE; i += 1) {
      if ((shares_exceedance[i] ?? 0) > (shares_exceedance[i - 1] ?? 0) + 1e-12) {
        is_monotone = false;
      }
    }
    let held = 0;
    for (let i = 0; i < BUCKETS_EXCEEDANCE; i += 1) held += buckets_exceedance[i] ?? 0;
    // Same percentile, taken slow honest way off samples themselves.
    const sorted = Array.from(history_exceedance.slice(0, counted)).sort((a, b) => a - b);
    const direct = sorted[Math.min(sorted.length - 1, Math.floor(sorted.length * 0.99))] ?? 0;
    let bucketed = 0;
    for (let i = BUCKETS_EXCEEDANCE - 1; i >= 0; i -= 1) {
      if ((shares_exceedance[i] ?? 0) >= 0.01) {
        bucketed = i * MILLISECONDS_BUCKET;
        break;
      }
    }
    const canvas = document.getElementById('exceedance') as HTMLCanvasElement;
    const pixels = canvas.getContext('2d')
      ?.getImageData(0, 0, canvas.width, canvas.height).data ?? new Uint8ClampedArray();
    let lit = 0;
    for (let i = 3; i < pixels.length; i += 4) if ((pixels[i] ?? 0) > 8) lit += 1;
    const at_zero = shares_exceedance[0] ?? 0;
    return { counted, held, is_monotone, at_zero, direct, bucketed, lit };
  });

  report(
    'the frame-time curve is a distribution, and the window accounts for itself',
    curve.counted > 60 && curve.held === curve.counted && curve.is_monotone &&
      Math.abs(curve.at_zero - 1) < 1e-9,
    `${curve.counted} frames, ${curve.held} in buckets, monotone ${curve.is_monotone}, ` +
      `P(at or over 0) = ${curve.at_zero}`,
  );
  report(
    'and its stated 1-in-100 agrees with the samples it was taken from',
    // Allow bucket and half: curve reports bucket's own lower edge, and direct percentile
    //   lands anywhere inside that bucket.
    Math.abs(curve.direct - curve.bucketed) <= 1.0 && curve.lit > 200,
    `curve says ${curve.bucketed.toFixed(1)} ms, samples say ${curve.direct.toFixed(1)} ms, ` +
      `${curve.lit} pixels drawn`,
  );
}

/** Where curve reaches on canvas, and what axis says it spans. */
interface Reach {
  top: number;
  bottom: number;
  rightmost: number;
  height: number;
  width: number;
  milliseconds: number;
}

/** Read how far curve's own ink reaches, and axis's stated extent. */
async function readReach(page: Page): Promise<Reach> {
  return page.evaluate(() => {
    const canvas = document.getElementById('exceedance') as HTMLCanvasElement;
    const pixels = canvas.getContext('2d')
      ?.getImageData(0, 0, canvas.width, canvas.height).data ?? new Uint8ClampedArray();
    // Curve alone: gridlines are drawn at fifth of this opacity.
    let top = canvas.height, bottom = -1, rightmost = -1;
    for (let y = 0; y < canvas.height; y += 1) {
      for (let x = 0; x < canvas.width; x += 1) {
        if ((pixels[(y * canvas.width + x) * 4 + 3] ?? 0) < 200) continue;
        if (y < top) top = y;
        if (y > bottom) bottom = y;
        if (x > rightmost) rightmost = x;
      }
    }
    const said = document.getElementById('diagnostic-exceedance-axis')?.textContent ?? '';
    return {
      top, bottom, rightmost, height: canvas.height, width: canvas.width,
      milliseconds: Number((said.match(/0–(\d+(?:\.\d+)?) ms/) ?? [])[1]),
    };
  });
}

/** Drive spread window, and assert curve wears each budget's own colour and spans plot. */
export async function driveAxis(page: Page): Promise<void> {
  await holdExceedance(page);
  await feedWindow(page, 3000, [[0.7, 5, 3], [0.92, 9, 7], [0.99, 17, 15], [1, 34, 40]]);
  await settleAxis(page);

  const bands = await page.evaluate(() => {
    const canvas = document.getElementById('exceedance') as HTMLCanvasElement;
    const pixels = canvas.getContext('2d')
      ?.getImageData(0, 0, canvas.width, canvas.height).data ?? new Uint8ClampedArray();
    const counted = new Map<string, number>();
    for (let i = 0; i < pixels.length; i += 4) {
      if ((pixels[i + 3] ?? 0) < 200) continue;
      const rgb = `${pixels[i]},${pixels[i + 1]},${pixels[i + 2]}`;
      counted.set(rgb, (counted.get(rgb) ?? 0) + 1);
    }
    // Tokens stylesheet sets, as canvas would have written them.
    const wanted = ['--speed-fast', '--speed-good', '--speed-fair', '--speed-poor'].map(
      (token) => {
        const hex = getComputedStyle(document.documentElement).getPropertyValue(token).trim();
        return [1, 3, 5].map((at) => parseInt(hex.slice(at, at + 2), 16)).join(',');
      },
    );
    return {
      drawn: wanted.filter((rgb) => (counted.get(rgb) ?? 0) > 15).length,
      wanted: wanted.length,
    };
  });
  report(
    'the curve wears the colour of the budget each part of it is inside',
    bands.drawn >= 3, `${bands.drawn} of ${bands.wanted} band colours on the canvas`,
  );

  const reach = await readReach(page);
  report(
    'the curve climbs from 0% at the fastest frame to 100% at the slowest',
    // Sample bottom to top of canvas, which plot is whole of: rates and durations are drawn
    //   over it rather than in rows of their own, so curve owns full height. And out to
    //   slowest frame window holds, axis being fitted to exactly that frame. Allow axis's
    //   own deadband of far edge: glide settles couple of percent short rather than landing
    //   exactly on it, which is axis holding still rather than chasing last half-millisecond.
    reach.top <= 2 && reach.bottom >= reach.height - 3 &&
      reach.rightmost >= reach.width * 0.95,
    `drawn from row ${reach.top} to ${reach.bottom} of ${reach.height}, ` +
      `out to column ${reach.rightmost} of ${reach.width}`,
  );
  await driveFloor(page, reach);
}

/** Assert axis stops at 30 fps mark rather than zooming into fast window's own noise.
 *
 *  Window holding nothing slow would otherwise draw axis far narrower. Room past that mark
 *  to write its own labels, which is why floor is little wider than mark rather than it.
 */
async function driveFloor(page: Page, reach: Reach): Promise<void> {
  const least = await page.evaluate(() => MILLISECONDS_AXIS_LEAST);
  await feedWindow(page, 1024, [[1, 5, 9]]);
  await settleAxis(page);
  const floored = await page.evaluate(() => {
    const said = document.getElementById('diagnostic-exceedance-axis')?.textContent ?? '';
    return Number((said.match(/0–(\d+(?:\.\d+)?) ms/) ?? [])[1]);
  });
  report(
    'and its axis follows the window without ever closing below the 30 fps mark',
    Number.isFinite(reach.milliseconds) && reach.milliseconds >= 33 &&
      // Allow axis's own deadband at floor: glide settles near extent rather than exactly
      //   on it, and floor is extent like any other.
      Number.isFinite(floored) && floored >= least - 1 && floored <= least + 2,
    `a mixed window reads 0-${reach.milliseconds} ms, a fast one 0-${floored} ms`,
  );
  await driveMarks(page, least);
}

/** What axis wrote on itself, counted out of canvas by opacity. */
interface AxisInk {
  width: number;
  marks: number[];
  named: Array<{ above: number; below: number }>;
  ink_margin: number;
}

/** Read everything axis writes on itself out of canvas, by opacity.
 *
 *  Four things drawn there are laid down at four different alphas -- gridlines faintest,
 *  then dashed budget marks, then labels, then curve opaque -- so each can be counted apart
 *  from others without knowing where any of them went.
 */
async function readAxisInk(page: Page): Promise<AxisInk> {
  return page.evaluate((row) => {
    const canvas = document.getElementById('exceedance') as HTMLCanvasElement;
    const width = canvas.width, height = canvas.height;
    const pixels = canvas.getContext('2d')
      ?.getImageData(0, 0, width, height).data ?? new Uint8ClampedArray();
    const alphaAt = (x: number, y: number): number => pixels[(y * width + x) * 4 + 3] ?? 0;
    const isLabel = (x: number, y: number): boolean =>
      alphaAt(x, y) > 120 && alphaAt(x, y) < 230;

    // Find dashed mark as column that starts at very top and carries its alpha down. Both
    //   halves are needed: percentages stacked in left margin put antialiased pixels at that
    //   alpha down similar span of column, and only full-height line begins at row 0. Dash
    //   pattern leaves gaps, so third of rows is bar.
    const marks: number[] = [];
    for (let x = 0; x < width; x += 1) {
      let down = 0, first = height;
      for (let y = 0; y < height; y += 1) {
        if (alphaAt(x, y) <= 60 || alphaAt(x, y) >= 120) continue;
        if (y < first) first = y;
        down += 1;
      }
      if (first <= 2 && down > height * 0.3) marks.push(x);
    }
    let ink_margin = 0;
    for (let y = row; y < height - row; y += 1) {
      for (let x = 0; x < 26; x += 1) if (isLabel(x, y)) ink_margin += 1;
    }
    // Check each mark is named at both ends: label ink in top row and in bottom row, within
    //   reach of mark's own column on whichever side it took.
    const named = marks.map((x) => {
      let above = 0, below = 0;
      for (let away = -16; away <= 16; away += 1) {
        const at = x + away;
        if (at < 0 || at >= width) continue;
        for (let y = 0; y < row; y += 1) if (isLabel(at, y)) above += 1;
        for (let y = height - row; y < height; y += 1) if (isLabel(at, y)) below += 1;
      }
      return { above, below };
    });
    return { width, marks, named, ink_margin };
  }, ROW_LABEL_DRAWN);
}

/** Assert both scales name their heights, and every mark is named at both ends.
 *
 *  Linear drew bare rules and not one word, so reader could see that some height mattered
 *  without being told which; log named two of its three decades and left ceiling -- whole
 *  reason to switch to it -- unnamed. Checked in both, because only one was ever right.
 */
async function driveMarks(page: Page, least: number): Promise<void> {
  // Toggle through element itself rather than real click: drawer is shut at this point, and
  //   Playwright rightly refuses to click what reader cannot see. Under test here is what
  //   axis draws, not how switch is reached.
  const toggleLog = async (): Promise<void> => {
    await page.evaluate(() => {
      document.getElementById('toggle-exceedance-log')?.click();
      drawExceedance();
    });
  };
  const ink_linear = (await readAxisInk(page)).ink_margin;
  await toggleLog();
  const ink_log = (await readAxisInk(page)).ink_margin;
  await toggleLog();
  report(
    'both scales of the axis name the heights they are read against',
    ink_linear > 40 && ink_log > 40,
    `${ink_linear} pixels of label linear, ${ink_log} log`,
  );

  // Dashed line is one ruler read from both ends -- rate above it, duration below -- so
  //   reader never converts between two in their head.
  const ink_floor = await readAxisInk(page);
  report(
    'every budget mark is named as a rate above it and a duration below it',
    ink_floor.marks.length >= 3 &&
      ink_floor.named.every((mark) => mark.above > 0 && mark.below > 0),
    `${ink_floor.marks.length} marks at columns ${ink_floor.marks.join(', ')}, ` +
      `named ${ink_floor.named.map((one) => `${one.above}/${one.below}`).join(' ')}`,
  );
  // At floor of exactly 1000/30, 30 fps line landed *on* right edge, half pixel outside
  //   canvas, and its label flipped to cramped inside-left branch, alone among marks in
  //   reading right to left. Floor now carries room for it.
  report(
    'the 30 fps mark stands inside the axis at its narrowest, with room to name it',
    ink_floor.marks.length > 0 &&
      (ink_floor.marks[ink_floor.marks.length - 1] ?? 0) <= ink_floor.width - 15,
    `slowest mark at column ${ink_floor.marks[ink_floor.marks.length - 1]} ` +
      `of ${ink_floor.width}, on a 0-${least.toFixed(1)} ms floor`,
  );

  // Slowest mark is drawn by same rule every other one is -- only where axis reaches it --
  //   so it is absent from fast window above and present once window holds frames that slow.
  //   Floor does not widen to accommodate it: 30 fps is what sets minimum.
  await feedWindow(page, 1024, [[1, 10, 80]]);
  await settleAxis(page);
  const ink_wide = await readAxisInk(page);
  report(
    'and the 15 fps mark appears only once the window holds a frame that slow',
    // Counts alone: that each mark is named is check above's business, and check that fails
    //   for two reasons tells you neither.
    ink_floor.marks.length === 3 && ink_wide.marks.length === 4,
    `${ink_floor.marks.length} marks on a fast window, ${ink_wide.marks.length} on a slow one`,
  );
  await releaseExceedance(page);
}
