// Check tally and how each is said; not Nim because harness runs in node under Playwright,
//   whose API Nim reaches only through foreign-function glue that would leave every
//   browser-side expression unchecked string (see PROVENANCE, Driven Checks).
//   Reports every check, pass or fail, and exits non-zero if any failed: one run says
//   everything wrong, not first thing.

let count_failed = 0;
let count_run = 0;

/** Say one check's outcome, and remember whether it failed. */
export function report(name: string, is_passing: boolean, detail?: string): void {
  count_run += 1;
  if (!is_passing) count_failed += 1;
  const mark = is_passing ? '  ok  ' : ' FAIL ';
  console.log(`${mark} ${name}${detail === undefined ? '' : ` -- ${detail}`}`);
}

/** Say whether reading falls inside band, and what it was either way.
 *
 *  Timing-dependent quantities are asserted as bands, never figures: how far held key
 *  travels depends on frames drawn while it was down, and flaky check gets deleted rather
 *  than fixed.
 */
export function reportWithin(
  name: string, value: number, low: number, high: number, units: string,
): void {
  report(
    name, value >= low && value <= high,
    `${value.toFixed(3)} ${units}, wanted ${low}..${high}`,
  );
}

/** Count of checks run so far. */
export function countRun(): number { return count_run; }

/** Count of checks that failed so far. */
export function countFailed(): number { return count_failed; }
