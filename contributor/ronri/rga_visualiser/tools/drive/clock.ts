// Move page's time only when check asks it to; not Nim because Playwright's clock is what
//   stands in for page's timers, and Nim reaches it only through glue.
//   Correctness checks run on simulated clock: page's timers, animation frames and
//   `performance.now` are Playwright's, and they move only on `runFor`. Slow machine then
//   takes longer in real time to reach same verdict, and never reaches another one.
//   Speed checks, and checks of page's own timing readouts, run on second page left on real
//   clock; see `main.ts`. Same helpers serve both, and ask which clock page runs on.
//   Browser's own rendering step still runs on real frames: resize, scroll, media-query and
//   resize-observer events, and touch moves, fire there. So each simulated frame waits for one
//   real rendering step first, and whatever last action or frame set off reaches page before
//   time moves, in same order on every machine. Without it, viewport sweep read toggles in row
//   at 394 px on one run and in menu on next, from same code.

import type { CDPSession, Page } from '@playwright/test';

/** Simulated milliseconds between two animation frames.
 *
 *  Playwright's clock fires animation frames on 16 ms boundaries, so this is exact rather than
 *  rounded 60 fps.
 */
export const MILLISECONDS_FRAME = 16;

/** Most frames `waitUntil` steps before it gives up.
 *
 *  Simulated frames, not wall time: 30 simulated seconds, far past any ease or transition this
 *  page runs. Condition still false by then never becomes true, and saying so is verdict.
 */
export const FRAMES_UNTIL_MOST = 1875;

/** Playback rate given to document timeline, where CSS transitions run.
 *
 *  Playwright's clock moves page's scripts, not its style engine: transitions keep real time.
 *  At this rate longest one, 350 ms, ends inside first real frame after it starts, so no
 *  check waits on real time to see transition finish.
 */
const RATE_TIMELINE = 10000;

/** Idle period each idle callback is granted on simulated clock, as browser grants at most. */
const MILLISECONDS_IDLE = 50;

/** Pages whose time is simulated. */
const pages_simulated = new WeakSet<Page>();

declare global {
  interface Window {
    /** Browser's own animation frame, kept before clock stands in for it. */
    __frame_real?: (callback: FrameRequestCallback) => number;
  }
}

/** Put page on simulated clock, paused, before its scripts run.
 *
 *  Called before `goto`, since clock must stand in front of page's first timer.
 */
export async function simulateClock(page: Page): Promise<void> {
  // Registered before clock, so it runs first and keeps frame clock replaces.
  await page.addInitScript(() => {
    window.__frame_real = window.requestAnimationFrame.bind(window);
  });
  await page.clock.install({ time: new Date('2026-01-01T00:00:00Z') });
  await page.clock.pauseAt(new Date('2026-01-01T00:00:01Z'));
  // Idle period as browser grants it at longest, 50 ms, rather than none at all.
  //   Playwright's idle callback says no time remains and no timeout passed, so work that asks
  //   for room before running, as diagnostics' slow pass does, would wait on it for ever.
  await page.addInitScript((milliseconds) => {
    const idle = window.requestIdleCallback;
    window.requestIdleCallback = (job, options) => idle(
      (deadline) => job({ didTimeout: deadline.didTimeout, timeRemaining: () => milliseconds }),
      options,
    );
  }, MILLISECONDS_IDLE);
  pages_simulated.add(page);
}

/** Run page's CSS transitions at `RATE_TIMELINE`, so none is waited on in real time.
 *
 *  Called after `goto`: rate belongs to document's timeline, which navigation replaces.
 */
export async function hastenTransitions(devtools: CDPSession): Promise<void> {
  await devtools.send('Animation.enable');
  await devtools.send('Animation.setPlaybackRate', { playbackRate: RATE_TIMELINE });
}

/** Whether this page runs on simulated clock. */
export function isSimulated(page: Page): boolean {
  return pages_simulated.has(page);
}

/** Let browser's own rendering step run once, with simulated time held. */
async function renderReal(page: Page): Promise<void> {
  await page.evaluate(() => new Promise<void>((done) => {
    const frame = window.__frame_real;
    if (frame === undefined) done(); else frame(() => done());
  }));
}

/** Move simulated time this far, one frame at time, each after real rendering step. */
async function runSpan(page: Page, milliseconds: number): Promise<void> {
  let left = milliseconds;
  while (left > 0) {
    const step = Math.min(left, MILLISECONDS_FRAME);
    await renderReal(page);
    await page.clock.runFor(step);
    left -= step;
  }
}

/** Move simulated time on by this many milliseconds, firing every timer and frame inside it.
 *
 *  What stood in for fixed sleep: how long gesture is held, or how long absence is watched,
 *  is now span of page's own time, and same on every machine.
 */
export async function advance(page: Page, milliseconds: number): Promise<void> {
  if (!isSimulated(page)) {
    throw new Error('`advance` moves simulated time; this page runs on real clock.');
  }
  await runSpan(page, milliseconds);
}

/** Let page draw this many more frames.
 *
 *  Simulated page moves its clock that far; real one waits on its own animation frames.
 */
export async function advanceFrames(page: Page, frames: number): Promise<void> {
  if (isSimulated(page)) {
    await runSpan(page, frames * MILLISECONDS_FRAME);
    return;
  }
  await page.evaluate((given) => new Promise<void>((done) => {
    let seen = 0;
    const step = (): void => {
      seen += 1;
      if (seen >= given) done(); else requestAnimationFrame(step);
    };
    requestAnimationFrame(step);
  }), frames);
}

/** Step page one frame at time until condition holds, and raise where it never does.
 *
 *  Condition is read at each frame boundary, so where it first holds is same frame on every
 *  machine. Real-clock page polls on its own frames, bounded by time rather than frames.
 */
export async function waitUntil<A>(
  page: Page, condition: (given: A) => boolean, given: A,
  frames_most: number = FRAMES_UNTIL_MOST,
): Promise<void> {
  if (!isSimulated(page)) {
    await page.waitForFunction(
      condition as (given: unknown) => boolean, given as unknown,
      { timeout: frames_most * MILLISECONDS_FRAME, polling: 'raf' },
    );
    return;
  }
  for (let frame = 0; frame <= frames_most; frame += 1) {
    if (await page.evaluate(condition as (given: unknown) => boolean, given as unknown)) return;
    await runSpan(page, MILLISECONDS_FRAME);
  }
  throw new Error(`Condition still false after ${frames_most} simulated frames.`);
}

/** Run page function that waits on page's own timers, while simulated time moves this far.
 *
 *  Clock yields to page between timers, so function's own awaits resolve in order, each at its
 *  own simulated moment. Span must cover every wait function makes: one still waiting at end
 *  of span raises, rather than sleeping on. Real-clock page runs function as it stands.
 */
export async function evaluateOver<R, A = undefined>(
  page: Page, milliseconds: number, work: (given: A) => R | Promise<R>, given?: A,
): Promise<R> {
  const loose = work as (given: unknown) => R | Promise<R>;
  if (!isSimulated(page)) return page.evaluate(loose, given as unknown);
  let is_done = false;
  const running = page.evaluate(loose, given as unknown);
  const noted = running.then(() => { is_done = true; }, () => { is_done = true; });
  await runSpan(page, milliseconds);
  // Page answered before clock did, on one connection, so answer that came has been read.
  if (!is_done) {
    throw new Error(`Page function still waiting after ${milliseconds} simulated ms.`);
  }
  await noted;
  return running;
}
