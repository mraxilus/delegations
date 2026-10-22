// Count work of marker and of moving lattice, in engine with its optimiser off; not Nim
//   because counts come from V8's precise coverage, over DevTools protocol Playwright speaks.
//   Check of cost gates on counts, and time is its budget (Article VII.10): `pins.ts` times
//     same work as budget, and these counts pin each fault.
//   Engine runs its interpreter alone (VII.11): tier that inlines function stops its count.
//     So counted build is not build that ships, and `PROVENANCE.md` says so.
//   Band is zero (VII.12): counted code selects nothing by processor, and every input is held,
//     clock among them, so same build reads same count on every run and every machine.
//   Baselines name build they were counted on, and other build is refused, never compared.

import {
  chromium, type Browser, type CDPSession, type LaunchOptions, type Page,
} from '@playwright/test';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { advanceFrames, simulateClock, waitUntil } from './clock';
import { pickPlane } from './ground';
import { report } from './report';

/** Engine flags counted page runs under: interpreter alone, so no tier inlines function. */
export const FLAGS_ENGINE_COUNTED = '--no-opt --no-maglev --no-sparkplug';

/** Build that names counted page: browser's version, its engine flags, and compiler commit. */
interface BuildCounted {
  chromium: string;
  flags: string;
  nim: string;
}

/** Build each baseline below was counted on: Playwright 1.63.0's, and pinned compiler. */
const BUILD_BASELINE: BuildCounted = {
  chromium: '153.0.8010.12',
  flags: FLAGS_ENGINE_COUNTED,
  nim: '27763495bcfe265507ca98aedc1c7064bf1e0e4d',
};

/** Copies and calls of one marker and its pulse for each object of opening scene.
 *
 *  Each baseline is repair's count, and band is zero; readings, and fault's, are in
 *  `PROVENANCE.md`. Count under baseline passes, and baseline is then counted again.
 */
const COPIES_MARKER = 15883; // Fault: outline summed sample by sample.
const CALLS_MARKER = 48642;

/** Calls, copies and bytes lattice adds to `FRAMES_LATTICE` frames of moving camera. */
const CALLS_LATTICE = 4817506; // Fault: fade sampled at each boundary.
const COPIES_LATTICE = 356725; // Pins copy any change adds, as library's `+` added one per sum.
const BYTES_LATTICE = 219136;

/** Calls and copies of one still page frame, as page's own loop draws it, with each kind picked.
 *
 *  Net over whole frame: build, overlay, marker and label. Pins work any change adds where no
 *  span above reads it, as move of library pin can. Opening scene holds points and plane.
 */
const FRAMES_PICKED = [
  { kind: 'point', calls: 29591, copies: 4808 },
  { kind: 'plane', calls: 96476, copies: 9874 },
];

/** Frames page draws after pick before one is counted, so pick's own first frames pass. */
const FRAMES_SETTLED = 2;

/** Frames lattice is counted over, and turn between two, as `drivePinGrid` turns camera. */
const FRAMES_LATTICE = 9;
const RADIANS_TURN = 0.005;

/** Distance lattice is counted at, as `drivePinGrid` counts it. */
const DISTANCE_LATTICE = 300;

/** Clock each counted frame is built at, in seconds: one value, so no path moves with time. */
const SECONDS_COUNTED = 1;

/** Name JS backend gives its deep copy. */
const NAME_COPY = 'nimCopy';

/** Nimble file, whose requirement names compiler commit build driver refuses any other than. */
const PATH_NIMBLE = join(__dirname, '..', '..', 'pga_visualiser.nimble');

/** Calls in page's own script over one counted span. */
interface Calls {
  /** Calls of each function, by name JS backend emits. */
  by_name: Map<string, number>;
  /** Source span of each function reached, as offsets into its script. */
  reached: Array<[number, number]>;
  /** Script those offsets index. */
  script: string;
}

/** Read calls of each function in page's own script since last read; read resets them. */
async function readCalls(devtools: CDPSession, url: string): Promise<Calls> {
  const { result } = await devtools.send('Profiler.takePreciseCoverage');
  const calls: Calls = { by_name: new Map(), reached: [], script: '' };
  for (const script of result) {
    if (script.url !== url) continue;
    for (const one of script.functions) {
      const whole = one.ranges[0];
      if (whole === undefined || whole.count === 0) continue;
      calls.by_name.set(one.functionName, (calls.by_name.get(one.functionName) ?? 0) + whole.count);
      calls.reached.push([whole.startOffset, whole.endOffset]);
      calls.script = script.scriptId;
    }
  }
  return calls;
}

/** Run `work` on page, and read calls it made alone: counters reset just before it. */
async function countOver<R, A>(
  devtools: CDPSession, page: Page, work: (given: A) => R, given: A,
): Promise<{ calls: Calls; value: R }> {
  const url = page.url();
  // Loosened as `evaluateOver` loosens it: generic argument picks no overload of `evaluate`.
  const loose = work as (given: unknown) => R;
  await readCalls(devtools, url);
  const value = await page.evaluate(loose, given as unknown);
  return { calls: await readCalls(devtools, url), value };
}

/** Advance page one frame through its own loop, after it settles, and read calls of that frame. */
async function countFrame(devtools: CDPSession, page: Page): Promise<Calls> {
  const url = page.url();
  await advanceFrames(page, FRAMES_SETTLED);
  await readCalls(devtools, url);
  await advanceFrames(page, 1);
  return readCalls(devtools, url);
}

/** Open built page on simulated clock, paused, with V8's counters armed. */
async function openCounted(
  browser: Browser, url: string, size: { width: number; height: number }, errors: string[],
): Promise<{ page: Page; devtools: CDPSession }> {
  const page = await browser.newPage({ viewport: size });
  page.on('pageerror', (error) => errors.push(error.message));
  await simulateClock(page);
  await page.goto(url);
  await waitUntil(page, () => typeof nimSceneCount === 'function' && nimSceneCount() > 0, null);
  const devtools = await page.context().newCDPSession(page);
  await devtools.send('Profiler.enable');
  await devtools.send('Debugger.enable');
  await devtools.send('Profiler.startPreciseCoverage', { callCount: true, detailed: false });
  return { page, devtools };
}

/** Sum every call one span counted. */
function callsAll(calls: Calls): number {
  let sum = 0;
  for (const count of calls.by_name.values()) sum += count;
  return sum;
}

/** Count copy sites inside functions one span reached and other did not.
 *
 *  Static count of emitted code, which stays beside count of machine because it names line
 *  (VII.10). Site inside two reached spans, as nested function's, counts once. Pass no
 *  other span to count every function reached.
 */
async function sitesCopy(devtools: CDPSession, calls: Calls, apart?: Calls): Promise<string> {
  if (calls.script.length === 0) return 'no script reached';
  const { scriptSource } = await devtools.send(
    'Debugger.getScriptSource', { scriptId: calls.script },
  );
  const reached = calls.reached.filter(([from, to]) =>
    apart === undefined || !apart.reached.some(([other, end]) => other === from && end === to));
  const sites: number[] = [];
  for (let at = scriptSource.indexOf(`${NAME_COPY}(`); at >= 0;
    at = scriptSource.indexOf(`${NAME_COPY}(`, at + 1)) sites.push(at);
  const inside = sites.filter((at) => reached.some(([from, to]) => at >= from && at < to));
  return `${inside.length} copy sites in the ${reached.length} functions reached`;
}

/** Read build counted page runs: browser's version, engine flags, and pinned compiler. */
function buildRunning(version: string): BuildCounted {
  const pinned = /requires "nim == ([0-9a-f]{40})"/.exec(readFileSync(PATH_NIMBLE, 'utf8'));
  return { chromium: version, flags: FLAGS_ENGINE_COUNTED, nim: pinned?.[1] ?? 'unread' };
}

/** Report one count against its baseline, refused where build is not baseline's. */
function reportCount(
  name: string, value: number, baseline: number, is_build_same: boolean, beside: string,
): void {
  const verdict = is_build_same ? `at most ${baseline}` : 'baseline is from another build';
  report(name, is_build_same && value <= baseline, `${value}, ${verdict}; ${beside}`);
}

/** Count marker and moving lattice on page of their own, in engine with optimiser off.
 *
 *  Browser of its own, since engine flags are process's. Page is on simulated clock, paused,
 *  so no frame or timer runs between counter reset and read: span counts work it asked for.
 */
export async function driveCounted(
  options: LaunchOptions, url: string, size: { width: number; height: number },
): Promise<void> {
  const browser = await chromium.launch({
    ...options,
    args: [...(options.args ?? []), `--js-flags=${FLAGS_ENGINE_COUNTED}`],
  });
  const errors_page: string[] = [];
  const { page, devtools } = await openCounted(browser, url, size, errors_page);

  const build = buildRunning(browser.version());
  const is_build_same = build.chromium === BUILD_BASELINE.chromium &&
    build.flags === BUILD_BASELINE.flags && build.nim === BUILD_BASELINE.nim;
  report(
    'the counted page runs the build its baselines were counted on', is_build_same,
    `Chromium ${build.chromium}, flags ${build.flags}, Nim ${build.nim}`,
  );

  const markersShaped = (): number => {
    const canvas = document.getElementById('gl') as HTMLCanvasElement;
    const handles = nimSceneHandles();
    for (const handle of handles) {
      nimSelectionMarker(handle, canvas.clientWidth, canvas.clientHeight, 1, false, 0);
      nimSelectionPulse(handle, canvas.clientWidth, canvas.clientHeight, 1, false, 0);
    }
    return handles.length;
  };
  // First call does work no later call repeats, so steady state is what is counted.
  await page.evaluate(markersShaped);
  const marker = await countOver(devtools, page, markersShaped, null);
  const sites_marker = await sitesCopy(devtools, marker.calls);
  reportCount(
    'a marker and its pulse copy no more than the repair does, summing no sample',
    marker.calls.by_name.get(NAME_COPY) ?? 0, COPIES_MARKER, is_build_same,
    `copies over ${marker.value} objects, ${sites_marker}`,
  );
  reportCount(
    'a marker and its pulse make no more calls than the repair does',
    callsAll(marker.calls), CALLS_MARKER, is_build_same, `calls over ${marker.value} objects`,
  );

  // Lattice lies on plane picked, so one is picked: world rules no ground of its own.
  await pickPlane(page);
  await page.evaluate((distance) => nimSetCameraDistance(distance), DISTANCE_LATTICE);
  const frameBuilt = (given: { seconds: number; is_grid_shown: boolean }): number => {
    const canvas = document.getElementById('gl') as HTMLCanvasElement;
    const data = nimBuildFrame(
      canvas.width / canvas.height, given.seconds, canvas.height, false, given.is_grid_shown,
      true,
    );
    return data.furniture_ribbon_vertices.byteLength;
  };
  // First frame does work no later frame repeats, as first marker does.
  await page.evaluate(frameBuilt, { seconds: SECONDS_COUNTED, is_grid_shown: true });
  let calls_lattice = 0;
  let copies_lattice = 0;
  let bytes_lattice = 0;
  let sites_lattice = '';
  const per_frame: number[] = [];
  for (let frame = 0; frame < FRAMES_LATTICE; frame += 1) {
    await page.evaluate((radians) => nimCameraOrbit(radians, 0), RADIANS_TURN);
    const bare = await countOver(
      devtools, page, frameBuilt, { seconds: SECONDS_COUNTED, is_grid_shown: false },
    );
    const ruled = await countOver(
      devtools, page, frameBuilt, { seconds: SECONDS_COUNTED, is_grid_shown: true },
    );
    const added = callsAll(ruled.calls) - callsAll(bare.calls);
    per_frame.push(added);
    calls_lattice += added;
    copies_lattice += (ruled.calls.by_name.get(NAME_COPY) ?? 0) -
      (bare.calls.by_name.get(NAME_COPY) ?? 0);
    bytes_lattice += ruled.value - bare.value;
    if (frame === 0) sites_lattice = await sitesCopy(devtools, ruled.calls, bare.calls);
  }
  reportCount(
    'the moving lattice makes no more calls than the repair does, fading no boundary',
    calls_lattice, CALLS_LATTICE, is_build_same,
    `calls over ${FRAMES_LATTICE} frames, ${per_frame.join(' ')} each, ${sites_lattice}`,
  );
  reportCount(
    'the moving lattice copies no more than its baseline', copies_lattice, COPIES_LATTICE,
    is_build_same, `copies over ${FRAMES_LATTICE} frames`,
  );
  reportCount(
    'the moving lattice uploads no more bytes than the repair does', bytes_lattice,
    BYTES_LATTICE, is_build_same, `bytes over ${FRAMES_LATTICE} frames`,
  );
  await devtools.send('Profiler.stopPreciseCoverage');
  await page.close();

  // Page of its own, so camera that lattice moved and picks it made reach no frame counted here.
  const picked = await openCounted(browser, url, size, errors_page);
  for (const one of FRAMES_PICKED) {
    const handle = await picked.page.evaluate(
      (word) => nimSceneHandles().find((each) => nimObjectKindWord(each) === word) ?? -1,
      one.kind,
    );
    if (handle >= 0) await picked.page.evaluate((each) => { selectOnly(each, null); }, handle);
    const frame = await countFrame(picked.devtools, picked.page);
    reportCount(
      `a still frame with a ${one.kind} picked makes no more calls than its baseline`,
      handle < 0 ? Infinity : callsAll(frame), one.calls, is_build_same, 'calls of one frame',
    );
    reportCount(
      `a still frame with a ${one.kind} picked copies no more than its baseline`,
      handle < 0 ? Infinity : frame.by_name.get(NAME_COPY) ?? 0, one.copies, is_build_same,
      'copies of one frame',
    );
  }
  await picked.devtools.send('Profiler.stopPreciseCoverage');
  report(
    'the counted page raised no error', errors_page.length === 0, errors_page.join(' | '),
  );
  await browser.close();
}
