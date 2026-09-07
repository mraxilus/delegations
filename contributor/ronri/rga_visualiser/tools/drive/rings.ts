// Checks for rings each timing row is read over, and for experiment pills; not Nim because
//   they write into page's own rings and read what rows then say, all of which is browser.
//   Both synthetic runs below fill rings by hand, and advancing frame ring clears every row's
//   presence as it goes -- so they hand rings back exactly as they found them. Without that,
//   check reading real row after one of these reads ring this harness itself wiped, and
//   reports page broken when it was driving that was.

import type { Page } from '@playwright/test';
import { report } from './report';

/** Every ring, kept while synthetic runs stand in their place. */
interface Rings {
  at: number;
  frames: number[];
  phases: Record<string, number[][]>;
}

/** Copy every ring out of page, so synthetic runs can be undone. */
async function keepRings(page: Page): Promise<Rings> {
  return page.evaluate(() => {
    const phases: Record<string, number[][]> = {};
    for (const [name] of PHASES_DIAGNOSTIC) {
      phases[name] = [
        Array.from(history_phase[name] ?? []), Array.from(written_phase[name] ?? []),
      ];
    }
    return { at: index_history_frame, frames: Array.from(history_frame), phases };
  });
}

/** Put every ring back exactly as `keepRings` found it. */
async function restoreRings(page: Page, kept: Rings): Promise<void> {
  await page.evaluate((given) => {
    const scope = globalThis as unknown as { index_history_frame: number };
    scope.index_history_frame = given.at;
    for (let i = 0; i < given.frames.length; i += 1) {
      history_frame[i] = given.frames[i] ?? 0;
    }
    for (const [name] of PHASES_DIAGNOSTIC) {
      history_phase[name]?.set(given.phases[name]?.[0] ?? []);
      written_phase[name]?.set(given.phases[name]?.[1] ?? []);
    }
  }, kept);
}

/** Drive rings by hand, and assert what rows read back off them. */
export async function driveRings(page: Page): Promise<void> {
  const kept = await keepRings(page);

  // Every mobile browser coarsens and jitters its clock against timing attacks, so
  //   sub-millisecond row can measure as zero or below. Absence used to be marked by
  //   negative in value's own range, which made such reading indistinguishable from "this
  //   never ran" -- and left every sub-millisecond row of tree em dash on phone.
  const unmeasured = await page.evaluate(() => {
    for (const node of document.querySelectorAll('.diagnostic-node')) node.classList.add('open');
    // Frame ring is advanced first and rows written into it after, exactly as draw loop does
    //   it, so slots line up way they really would.
    for (let i = 0; i < 240; i += 1) {
      recordFrameTime(16.7);
      recordPhaseTime('sky', i % 2 === 0 ? 0 : -0.4);
    }
    refreshDiagnostics();
    return {
      text: document.getElementById('diagnostic-sky')?.textContent ?? '',
      median: medianPhase('sky'),
    };
  });
  report(
    'a step too quick for the clock to measure still reports, at zero',
    unmeasured.median === 0 && unmeasured.text.startsWith('0.00 (0.00) ms'),
    `the row reads "${unmeasured.text}", median ${unmeasured.median}`,
  );

  // One frame's number changes several times faster than it can be read, which is what made
  //   these rows flicker. Row alternating between 1 ms and 9 ms every frame: newest frame is
  //   always one or other, and only averaged reading lands between them.
  const smoothed = await page.evaluate(() => {
    for (const node of document.querySelectorAll('.diagnostic-node')) node.classList.add('open');
    for (let i = 0; i < 240; i += 1) {
      recordFrameTime(16.7);
      recordPhaseTime('overlay', i % 2 === 0 ? 1 : 9);
    }
    refreshDiagnostics();
    return {
      text: document.getElementById('diagnostic-overlay')?.textContent ?? '',
      frames: framesRecent(),
    };
  });

  // Rows are window means, which dilute one spike past telling whether page authored it;
  //   readout reads that frame's own slots. One 30 ms frame carrying 6 ms of `ui` among
  //   16.7 ms frames carrying 0.5, so page, its largest row and browser's remainder are all
  //   known.
  const slowest = await page.evaluate(() => {
    for (let i = 0; i < 240; i += 1) {
      recordPhaseTime('build', 1);
      recordPhaseTime('ui', i === 100 ? 6 : 0.5);
      recordPhaseTime('render', i === 100 ? 3 : 0.2);
      recordFrameTime(i === 100 ? 30 : 16.7);
    }
    refreshDiagnostics();
    return (document.getElementById('diagnostic-slowest')?.textContent ?? '') + ' / ' +
      (document.getElementById('diagnostic-slowest-split')?.textContent ?? '');
  });
  report(
    'the slowest frame in the ring is named, split between the page and the browser',
    slowest === '30.0 ms / 7.0 (ui 6.0) · 23.0 (render 3.0)',
    `the rows read "${slowest}"`,
  );

  await driveExperiments(page);
  await restoreRings(page, kept);
  await driveRendered(page);
  await driveAccounted(page);
  report(
    'a reading is the mean over the last 200 ms, not whatever the newest frame said',
    // 200 ms of 16.7 ms frames is dozen of them, and dozen alternating 1s and 9s mean 5.
    smoothed.text.startsWith('5.00 ') && smoothed.frames >= 9 && smoothed.frames <= 16,
    `the row reads "${smoothed.text}" over ${smoothed.frames} frames`,
  );
}

/** Assert each experiment pill switches its suspect off, and back on.
 *
 *  Blur through one class on body, pixel ratio through canvas's own backing store, overlay
 *  through its display.
 */
async function driveExperiments(page: Page): Promise<void> {
  const pills = await page.evaluate(() => {
    const canvas = document.getElementById('gl') as HTMLCanvasElement;
    const width_full = canvas.width;
    const click = (id: string): void => document.getElementById(id)?.click();
    click('toggle-blur');
    const is_blur_off = document.body.classList.contains('without-blur');
    click('toggle-blur');
    const is_blur_back = !document.body.classList.contains('without-blur');
    click('toggle-full-ratio');
    const width_low = canvas.width;
    click('toggle-full-ratio');
    const width_back = canvas.width;
    click('toggle-overlay');
    const is_overlay_off = document.getElementById('overlay')?.style.display === 'none';
    click('toggle-overlay');
    const is_overlay_back = document.getElementById('overlay')?.style.display === '';
    return {
      is_blur_off, is_blur_back, width_full, width_low, width_back,
      ratio: Math.min(window.devicePixelRatio || 1, 2.5), is_overlay_off, is_overlay_back,
    };
  });
  report(
    'each experiment pill switches its suspect off, and back on',
    pills.is_blur_off && pills.is_blur_back && pills.is_overlay_off && pills.is_overlay_back &&
      pills.width_back === pills.width_full &&
      (pills.ratio === 1 ? pills.width_low === pills.width_full
        : pills.width_low < pills.width_full),
    `blur ${pills.is_blur_off}/${pills.is_blur_back}, canvas ${pills.width_full} -> ` +
      `${pills.width_low} -> ${pills.width_back} at ratio ${pills.ratio}, overlay ` +
      `${pills.is_overlay_off}/${pills.is_overlay_back}`,
  );
}

/** Assert browser's own rendering is timed frame by frame while panel is shown.
 *
 *  Message posted as callback ends runs once style, layout, paint and commit are done; row
 *  is main-thread share of what is left of frame, never more than that remainder. Read off
 *  live ring rather than synthetic one: synthetic loop advances ring by exactly one wrap
 *  inside one task, which puts in-flight message back on its own slot.
 */
async function driveRendered(page: Page): Promise<void> {
  const rendered = await page.evaluate(async () => {
    if (!(document.getElementById('drawer')?.classList.contains('open') ?? false)) {
      document.getElementById('button-drawer')?.click();
    }
    document.querySelector('.section[data-section="diagnostics"]')?.classList.add('open');
    written_phase['render']?.fill(0); // Only frames timed from here on are read.
    await new Promise((done) => setTimeout(done, 1200));
    let written = 0, bad = 0;
    for (let i = 0; i < FRAMES_HISTORY; i += 1) {
      if (i === index_history_frame || written_phase['render']?.[i] !== 1) continue;
      written += 1;
      const value = history_phase['render']?.[i] ?? -1;
      if (!(value >= 0) || value > (history_frame[i] ?? 0) + 1) bad += 1;
    }
    return {
      written, bad, text: document.getElementById('diagnostic-render')?.textContent ?? '',
    };
  });
  report(
    "the browser's style, layout and paint are timed frame by frame while the panel is shown",
    rendered.written >= 20 && rendered.bad === 0 && / ms$/.test(rendered.text),
    `${rendered.written} frames timed, ${rendered.bad} out of range, row "${rendered.text}"`,
  );
}

/** Assert rows account for whole frame, not fraction of it.
 *
 *  Everything page spends is its own rows; rest of frame is waiting on display plus browser's
 *  own style, layout, paint, compositing and collection. Without that remainder on panel,
 *  spike could not be told from stall in page's own code, which is first thing reader needs.
 */
async function driveAccounted(page: Page): Promise<void> {
  const accounted = await page.evaluate(() => {
    const off: number[] = [];
    for (let i = 2; i < FRAMES_HISTORY - 2; i += 1) {
      const at = (index_history_frame + i) % FRAMES_HISTORY;
      if (written_phase['idle']?.[at] !== 1) continue;
      let sum = history_phase['idle']?.[at] ?? 0;
      for (const name of PHASES_TOP_DIAGNOSTIC) {
        if (written_phase[name]?.[at] === 1) sum += history_phase[name]?.[at] ?? 0;
      }
      off.push(Math.abs((history_frame[at] ?? 0) - sum));
    }
    return { n: off.length, worst: off.length === 0 ? 0 : Math.max(...off) };
  });
  report(
    'the breakdown rows account for the whole frame they break down',
    // Exact but for float rounding on bridge's own three rows.
    accounted.n > 100 && accounted.worst < 0.05,
    `${accounted.n} frames reconstructed, worst off by ${accounted.worst.toFixed(4)} ms`,
  );
}
