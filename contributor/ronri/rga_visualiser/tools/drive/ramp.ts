// Checks for colour each timing row wears, and for breakdown adding up; not Nim because
//   they read back inline colour and rendered geometry, both of which only browser has.
//   Twenty-odd numbers say nothing about which to look at; continuous ramp keyed on each
//   row's share of *frame* does. Checked as ordering rather than against fixed colours, so
//   retuning ramp does not mean rewriting this.

import type { Page } from '@playwright/test';
import { settleReading } from './frame';
import { report } from './report';

/** Open drawer, its diagnostics section and every branch of tree.
 *
 *  Refresh skips what is closed, so shut node's rows would be read stale.
 */
async function openEveryBranch(page: Page): Promise<void> {
  await page.evaluate(() => {
    const drawer = document.querySelector('.drawer');
    if (!(drawer?.classList.contains('open') ?? false)) {
      document.getElementById('button-drawer')?.click();
    }
    const section = document.querySelector('.section[data-section="diagnostics"]');
    if (!(section?.classList.contains('open') ?? false)) {
      (section?.querySelector('.section-header') as HTMLElement | null)?.click();
    }
    for (const node of document.querySelectorAll('.diagnostic-node')) {
      if (node.classList.contains('open')) continue;
      (node.querySelector(':scope > .diagnostic-parent') as HTMLElement | null)?.click();
    }
  });
  await page.waitForFunction(() => Array.from(
    document.querySelectorAll('.diagnostic-node'),
  ).every((node) => node.classList.contains('open')), null, { timeout: 8000, polling: 'raf' });
  await settleReading(page);
}

/** One row's reading and where along ramp its colour puts it. */
interface Tinted {
  name: string;
  milliseconds: number;
  step: number;
}

/** Drive tree open, and assert costlier rows never wear cooler colours. */
export async function driveTint(page: Page): Promise<void> {
  await openEveryBranch(page);
  const tinted = await page.evaluate(() => {
    // Where along ramp row sits, recovered from colour it actually wears: ramp is monotone
    //   in share, so nearest sampled step to row's own colour is its position on it. Read
    //   this way rather than recomputed, so check tests what page drew rather than agreeing
    //   with it by construction.
    const scratch = document.createElement('span');
    const steps: string[] = [];
    for (const stop of RAMP_TREE) {
      scratch.style.color = rgbToCss(stop.value);
      steps.push(scratch.style.color);
    }
    const read = (text: string): number[] => (text.match(/\d+/g) ?? []).map(Number);
    const positionOf = (colour: string): number => {
      const exact = steps.indexOf(colour);
      if (exact >= 0) return exact;
      // Between two shipped steps: parse and take nearest, which is all ordering needs.
      const wanted = read(colour);
      if (wanted.length < 3) return -1;
      let best = -1, closest = Infinity;
      for (let i = 0; i < steps.length; i += 1) {
        const step = read(steps[i] ?? '');
        const apart = Math.hypot(...[0, 1, 2].map((c) => (step[c] ?? 0) - (wanted[c] ?? 0)));
        if (apart < closest) {
          closest = apart;
          best = i;
        }
      }
      return best;
    };

    const rows: Array<{ name: string; milliseconds: number; step: number }> = [];
    for (const [name] of PHASES_DIAGNOSTIC) {
      const value = element_phase[name] ?? null;
      if (value === null || (element_row[name] ?? null) === null) continue;
      const said = Number((value.textContent?.match(/^([\d.]+)/) ?? [])[1]);
      if (!Number.isFinite(said) || value.style.color === '') continue;
      rows.push({ name, milliseconds: said, step: positionOf(value.style.color) });
    }
    return { rows, idle: element_phase['idle']?.style.color ?? '' };
  });

  // Sort by cost and walk: never cheaper row further along ramp. Equal step is allowed;
  //   rows page left untinted carry no step and sit out of comparison.
  const ranked: Tinted[] = tinted.rows.filter((one) => one.step >= 0 && one.name !== 'idle')
    .sort((a, b) => b.milliseconds - a.milliseconds);
  let is_ordered = true;
  for (let i = 1; i < ranked.length; i += 1) {
    if ((ranked[i]?.step ?? 0) > (ranked[i - 1]?.step ?? 0)) is_ordered = false;
  }
  report(
    'a costlier timing row never wears a cooler colour than a cheaper one',
    ranked.length >= 4 && is_ordered,
    `${ranked.length} tinted rows, worst-first: ` +
      ranked.slice(0, 5).map((one) => `${one.name} ${one.milliseconds} step ${one.step}`)
        .join(', '),
  );
  // Frame's leftover is largest share of healthy frame, so tinting it would paint best case
  //   in ramp's loudest colour.
  report(
    "and the frame's own idle time is left uncoloured, being no work at all",
    tinted.idle === '',
    `idle carries ${tinted.idle === '' ? 'no inline colour' : tinted.idle}`,
  );
  await driveRamp(page, ranked);
}

/** Drive alignment and ramp rule, and assert rows spread down ramp they are keyed on. */
async function driveRamp(page: Page, ranked: Tinted[]): Promise<void> {
  // Measure where `ms` itself ends, not where its box does: row is flex-laid with value
  //   right-aligned, so box's own edge is identical whatever it contains. Range over two
  //   characters measures thing reader's eye actually runs along.
  const aligned = await page.evaluate(() => {
    const edges = new Set<number>();
    const trailing: string[] = [];
    for (const [name] of PHASES_DIAGNOSTIC) {
      const value = element_phase[name] ?? null;
      if (value === null || value.firstChild === null) continue;
      const text = value.textContent ?? '';
      const at = text.lastIndexOf('ms');
      if (at < 0) continue;
      const span = document.createRange();
      span.setStart(value.firstChild, at);
      span.setEnd(value.firstChild, at + 2);
      edges.add(Math.round(span.getBoundingClientRect().right));
      if (!/ ms$/.test(text)) trailing.push(name + ': ' + text);
    }
    return { edges: [...edges], trailing };
  });
  report(
    'every timing row ends its unit in the same column',
    aligned.edges.length === 1 && aligned.trailing.length === 0,
    `${aligned.edges.length} distinct ms column(s) at ${aligned.edges.join(', ')}` +
      (aligned.trailing.length === 0 ? '' : `; trailing past ms: ${aligned.trailing.join(', ')}`),
  );

  // Ramp says row's share of frame, walked by ratio rather than by difference, ending at
  //   whole frame. Checked on rule itself: decade of cost must be fixed distance along ramp
  //   wherever it is taken, linear toe must be worth exactly one more of those, ends must be
  //   nothing and whole frame, and walk must never go backwards. Tolerance is tight because
  //   symlog makes decades exactly equal; approximation that only converges to it misses.
  const rule = await page.evaluate(() => {
    const walked: number[] = [];
    for (let i = 0; i <= 100; i += 1) walked.push(positionRampTree(i / 100));
    return {
      full: SHARE_RAMP_FULL_DIAGNOSTIC, knee: SHARE_RAMP_KNEE_DIAGNOSTIC,
      at_none: positionRampTree(0), at_full: positionRampTree(1),
      toe: positionRampTree(SHARE_RAMP_KNEE_DIAGNOSTIC),
      decade_low: positionRampTree(0.1) - positionRampTree(0.01),
      decade_high: positionRampTree(1) - positionRampTree(0.1),
      is_rising: walked.every((at, i) => i === 0 || at > (walked[i - 1] ?? 0)),
      steps: RAMP_TREE.length,
    };
  });
  const decade_apart = Math.abs(rule.decade_low - rule.decade_high);
  const toe_apart = Math.abs(rule.toe - rule.decade_low);
  report(
    'a decade of cost is a fixed distance along the tree ramp, whole frame to whole ramp',
    rule.full === 1 && rule.at_none === 0 && rule.at_full === 1 && rule.is_rising &&
      decade_apart < 1e-9 && toe_apart < 1e-9 && rule.steps > 8,
    `knee at ${rule.knee} of the frame over ${rule.steps} steps; under the knee spans ` +
      `${rule.toe.toFixed(4)} of the ramp, 1% -> 10% spans ` +
      `${rule.decade_low.toFixed(4)}, 10% -> all spans ${rule.decade_high.toFixed(4)}`,
  );

  // Ratio scale is what makes ramp discriminate on real frame: laid out linearly, rows of
  //   comfortable session all landed within two of seventeen steps and tree read as one
  //   colour. Measured in ramp steps recovered from what page drew; counting distinct
  //   colours would not bite, since rounding alone makes near-identical rows differ.
  const spread_least = Math.ceil((rule.steps - 1) / 3);
  const lowest = ranked.length === 0 ? 0 : Math.min(...ranked.map((one) => one.step));
  const highest = ranked.length === 0 ? 0 : Math.max(...ranked.map((one) => one.step));
  report(
    'the tinted rows spread down the ramp rather than crowding its first steps',
    highest - lowest >= spread_least,
    `the rows cover ${highest - lowest} of the ramp's ${rule.steps} steps ` +
      `(${lowest} to ${highest}), floor ${spread_least}`,
  );

  // Shipped ramp is one tool verified against CET-I1: its ends are map's own, so hand-edited
  //   table or stale build shows up here rather than only on screen.
  const ends = await page.evaluate(() => ({
    first: (RAMP_TREE[0]?.label ?? []).map((c) => Math.round(c * 255)),
    last: (RAMP_TREE[RAMP_TREE.length - 1]?.label ?? []).map((c) => Math.round(c * 255)),
  }));
  report(
    "the shipped ramp runs from the map's cyan to its orange",
    (ends.first[2] ?? 0) > (ends.first[0] ?? 0) && (ends.last[0] ?? 0) > (ends.last[2] ?? 0) &&
      (ends.first[1] ?? 0) > 100 && (ends.last[1] ?? 0) > 60,
    `cyan end rgb(${ends.first.join(', ')}), orange end rgb(${ends.last.join(', ')})`,
  );
}

/** Drive thirty frames, and assert build accounts for itself row by row.
 *
 *  For long time it did not, and nothing said so: frame's prologue and its view matrix
 *  belonged to no row, so `build` was simply larger than sum of what it showed and reader
 *  had no way to know how much was missing. Every span is now named, residue included.
 */
export async function driveSums(page: Page): Promise<void> {
  const summed = await page.evaluate(() => {
    const runs: Array<{
      build: number; children: number; placing: number; emitting: number;
    }> = [];
    for (let i = 0; i < 30; i += 1) {
      nimSetCameraAzimuth(0.01 * i); // Rebuild furniture, so sum covers real work.
      const data = nimBuildFrame(1200 / 900, performance.now() / 1000, 900, true, true);
      const children = data.ms_camera + data.ms_furniture + data.ms_scene +
        data.ms_matrix + data.ms_flatten + data.ms_unaccounted;
      runs.push({
        build: data.ms_build, children,
        placing: data.ms_placing, emitting: data.ms_emitting,
      });
    }
    const worst = runs.reduce((a, b) =>
      (Math.abs(b.build - b.children) > Math.abs(a.build - a.children) ? b : a));
    return {
      n: runs.length, off: worst.build - worst.children,
      build: worst.build, children: worst.children,
      placing: Math.max(...runs.map((one) => one.placing)),
      emitting: Math.max(...runs.map((one) => one.emitting)),
    };
  });
  report(
    'build accounts for itself: its rows sum to it, with the residue named',
    // Exact but for clock's own resolution: these are all reads of one timer, so only slack
    //   needed is rounding it does, not proportional tolerance.
    Math.abs(summed.off) <= 0.05,
    `worst of ${summed.n} frames: ${summed.build.toFixed(2)} against ` +
      `${summed.children.toFixed(2)} from its rows, off by ${summed.off.toFixed(3)} ms`,
  );
  // Both sides of algebra boundary must carry real time on frame that draws scene: split
  //   reading zero on one side is bracket that never ran, which is failure cut like this
  //   hides.
  report(
    'and both sides of the algebra boundary carry time on a frame that draws',
    summed.placing > 0.01 && summed.emitting > 0.01,
    `placing peaked at ${summed.placing.toFixed(2)} ms, emitting at ` +
      `${summed.emitting.toFixed(2)} ms`,
  );
}
