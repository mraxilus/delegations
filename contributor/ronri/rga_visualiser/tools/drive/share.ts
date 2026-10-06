// Check page's library share against engine's own profiler, and its word where it may not
//   sample; not Nim because Chrome's protocol and its profiler are what this reads, and Nim
//   reaches them only through glue.
//   Page samples with browser's sampling profiler, which runs only on page served with
//   `Document-Policy: js-profiling`. Harness serves it so on page of its own, and reads
//   engine's profiler over same span through Chrome's protocol. Both name owner of each
//   sample by page's own rule, `nimShareOwner`, so only sampling differs between them.

import type { Page } from '@playwright/test';
import { closeDiagnostics, openDiagnostics } from './diagnostics';
import { loadDemo, objectsLargest } from './demo';
import { waitUntil } from './clock';
import { report } from './report';

/** Busy samples page pools before both profilers stop, at largest demo.
 *
 *  About 12 s of sampling there, against which engine rests on about 2,900; figures in
 *  `PROVENANCE.md`. Count rather than span, so slow runner samples as long as it needs.
 */
const SAMPLES_SHARE_COMPARED = 350;

/** Engine's sampling interval, in microseconds: ten times page's, so its error is small. */
const MICROSECONDS_SAMPLE_ENGINE = 1000;

/** Standard errors two shares may differ by, and points of bias beside them.
 *
 *  Bias: profiler slightly changes what it measures, by up to 4 points across sessions.
 */
const ERRORS_SHARE_AGREED = 4;
const POINTS_SHARE_BIAS = 2;

/** Frames engine's profile names that are not page's script at work. */
const NAMES_NOT_BUSY = new Set(['(idle)', '(program)', '(garbage collector)', '(root)']);

/** One node of engine's profile, as much of it as this reads. */
interface NodeProfile {
  id: number;
  callFrame: { functionName: string };
  children?: number[];
}

/** Busy samples by owner, `share.Owner` order: rest, project algebra, library. */
type CountsShare = [number, number, number];

/** Count engine's busy samples by owner, each stack owned by highest owner on it. */
async function countEngine(
  page: Page, nodes: NodeProfile[], samples: number[],
): Promise<CountsShare> {
  const parent = new Map<number, number>();
  for (const node of nodes) for (const child of node.children ?? []) parent.set(child, node.id);
  const by_id = new Map(nodes.map((node) => [node.id, node]));
  const names = [...new Set(nodes.map((node) => node.callFrame.functionName))];
  const owners = await page.evaluate(
    (given) => given.map((name) => nimShareOwner(name)), names,
  );
  const owner_of_name = new Map(names.map((name, i) => [name, owners[i] ?? 0]));
  const counts: CountsShare = [0, 0, 0];
  for (const id of samples) {
    const name = by_id.get(id)?.callFrame.functionName ?? '(idle)';
    if (NAMES_NOT_BUSY.has(name)) continue;
    let owner = 0;
    for (let at: number | undefined = id; at !== undefined; at = parent.get(at)) {
      owner = Math.max(owner, owner_of_name.get(by_id.get(at)?.callFrame.functionName ?? '') ?? 0);
    }
    if (owner === 2) counts[2] += 1;
    else if (owner === 1) counts[1] += 1;
    else counts[0] += 1;
  }
  return counts;
}

/** Report one owner's share on both profilers, and whether they agree within sampling error. */
function reportAgreed(
  name: string, owner: 1 | 2, page_counts: CountsShare, engine_counts: CountsShare,
): void {
  const busy_page = page_counts[0] + page_counts[1] + page_counts[2];
  const busy_engine = engine_counts[0] + engine_counts[1] + engine_counts[2];
  const share_page = 100 * page_counts[owner] / Math.max(busy_page, 1);
  const share_engine = 100 * engine_counts[owner] / Math.max(busy_engine, 1);
  const p = share_engine / 100;
  const error = 100 * Math.sqrt(p * (1 - p) * (1 / Math.max(busy_page, 1) + 1 / busy_engine));
  const bound = ERRORS_SHARE_AGREED * error + POINTS_SHARE_BIAS;
  report(
    name, busy_engine > 0 && Math.abs(share_page - share_engine) <= bound,
    `page ${share_page.toFixed(1)}% of ${busy_page}, engine ${share_engine.toFixed(1)}% of ` +
      `${busy_engine}, bound ${bound.toFixed(1)} points`,
  );
}

/** Assert page served without policy says why it cannot sample, in both rows.
 *
 *  Domain: page opened from file, as reader opens downloaded copy; browser has profiler,
 *  and refuses it to that page.
 */
export async function driveShareRefused(page: Page): Promise<void> {
  const was = await openDiagnostics(page);
  const reason = await page.evaluate(() => nimWording(Wording.NoteDiagnosticsSharePolicy));
  await page.waitForFunction(
    (given) => document.getElementById('diagnostic-share-library')?.textContent === given,
    reason,
  ).catch(() => undefined);
  const rows = await page.evaluate(() => [
    document.getElementById('diagnostic-share-library')?.textContent ?? '',
    document.getElementById('diagnostic-share-algebra')?.textContent ?? '',
  ]);
  report(
    'the page says why it cannot sample its library share, where the browser refuses',
    rows.every((row) => row === reason), rows.join(' | '),
  );
  await closeDiagnostics(page, was);
}

/** Assert page's library share, and its project algebra's, agree with engine's profiler.
 *
 *  Page given here must be served with `Document-Policy: js-profiling`. Largest demo, every
 *  object placed every frame, nothing selected: steady load, so one span of each profiler
 *  reads same work. Both run at once until page has pooled `SAMPLES_SHARE_COMPARED`, and
 *  engine stops as window that reached it lands. Bound is drawn from both sample counts, so
 *  agreement is read against sampling error rather than against fixed margin.
 */
export async function driveShareAgrees(page: Page): Promise<void> {
  await loadDemo(page, await objectsLargest(page));
  const engine = await page.context().newCDPSession(page);
  await engine.send('Profiler.enable');
  await engine.send('Profiler.setSamplingInterval', { interval: MICROSECONDS_SAMPLE_ENGINE });
  await openDiagnostics(page);
  await engine.send('Profiler.start');
  // Page's count grows only as each window's trace lands, so it is read just after one has.
  await waitUntil(
    page, (given) => nimSharePooled().reduce((sum, count) => sum + count, 0) >= given,
    SAMPLES_SHARE_COMPARED,
  );
  const { profile } = await engine.send('Profiler.stop');
  const pooled = await page.evaluate(() => nimSharePooled());
  const page_counts: CountsShare = [pooled[0] ?? 0, pooled[1] ?? 0, pooled[2] ?? 0];
  const engine_counts = await countEngine(
    page, profile.nodes as NodeProfile[], profile.samples ?? [],
  );
  const row = await page.evaluate(
    () => document.getElementById('diagnostic-share-library')?.textContent ?? '',
  );
  report(
    'the page samples its library share where the browser allows it',
    /^\d+\.\d%, n \d+$/.test(row) && page_counts[0] + page_counts[1] + page_counts[2] >= 100,
    `${row}, pooled ${page_counts.join(' ')}`,
  );
  reportAgreed(
    'the page\'s library share agrees with the engine\'s own profiler', 2, page_counts,
    engine_counts,
  );
  reportAgreed(
    'the page\'s project algebra share agrees with the engine\'s own profiler', 1,
    page_counts, engine_counts,
  );
  await engine.detach();
}
