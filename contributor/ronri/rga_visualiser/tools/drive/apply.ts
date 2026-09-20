// Checks for path reader takes to build objects without dragging: pickers, menu, timeline;
//   not Nim because crossing forfeits check compiler makes over bulk of this file: its
//   `page.evaluate` bodies name bridge's derived exports and page's own pick entries, each of
//   which glue would leave unchecked string. DOM alone would not decide it.
//   Pickers name *positions* in list they show; scene names handles. Preview was once built
//   from picker's position passed straight through as handle, which is right only while
//   nothing has been deleted, so every check here runs after delete.

import type { Page } from '@playwright/test';
import { settleCount, settleSelection } from './gestures';
import { report } from './report';

/** Open or shut one drawer section, by name its markup carries. */
async function toggleSection(page: Page, name: string, is_open: boolean): Promise<void> {
  await page.evaluate((given) => {
    const section = document.querySelector(`.section[data-section="${given.name}"]`);
    if (section === null) return;
    if (section.classList.contains('open') !== given.is_open) {
      (section.querySelector('.section-header') as HTMLElement | null)?.click();
    }
  }, { name, is_open });
  await page.waitForFunction((given) => {
    const section = document.querySelector(`.section[data-section="${given.name}"]`);
    return (section?.classList.contains('open') ?? false) === given.is_open;
  }, { name, is_open }, { timeout: 8000, polling: 'raf' });
}

/** Handle added between two readings, or nothing where none was.
 *
 *  Fresh object lands in lowest free handle, which after delete is in middle: "last handle"
 *  is not newest object, and saying so quietly compares wrong one.
 */
function addedHandle(before: number[], after: number[]): number | undefined {
  return after.find((one) => !before.includes(one));
}

/** Drive delete, then apply, and assert picker names operands rather than positions. */
export async function driveApply(page: Page): Promise<void> {
  // Delete way reader deletes -- select, menu, delete -- rather than through bridge:
  //   pickers are rebuilt by reader's own action, not by tick, so scene changed behind
  //   page's back is state no gesture can produce.
  await page.evaluate(() => {
    const handles = nimSceneHandles();
    selectOnly(handles[0] ?? 0, null);
    refreshSelectionMenu(null);
    document.getElementById('selection-menu-delete')?.click();
  });
  await page.waitForFunction(
    () => !nimSceneHandles().includes(0), null, { timeout: 8000, polling: 'raf' },
  );
  const handles_now = await page.evaluate(() => nimSceneHandles());
  report(
    'deleting an object leaves the picker positions offset from the scene handles',
    handles_now[0] !== 0, `handles ${JSON.stringify(handles_now)}`,
  );

  // Open apply section itself, not merely drawer: pickers are filled when their own section
  //   opens rather than on every scene change, since one option per object per picker is
  //   ten thousand elements at largest size. Check stopping at drawer would assert against
  //   control nobody could have looked at.
  await page.click('#button-drawer');
  await toggleSection(page, 'apply', true);
  await page.waitForFunction(() => {
    const first = document.getElementById('op-first') as HTMLSelectElement | null;
    return first !== null && first.options.length === nimSceneCount();
  }, null, { timeout: 8000, polling: 'raf' });
  const filled = await page.evaluate(() => ({
    options: (document.getElementById('op-first') as HTMLSelectElement | null)?.options.length
      ?? -1,
    objects: nimSceneCount(),
  }));
  report(
    'the operand pickers follow a scene the reader has just changed',
    filled.options === filled.objects,
    `${filled.options} options, ${filled.objects} objects`,
  );

  // Shut apply section again: open one keeps preview standing, which is one of three things
  //   frame hold refuses to hold frame over, and later hold checks would break quietly.
  await toggleSection(page, 'apply', false);
  await driveApplyPair(page);
}

/** Ordinal of operation whose symbols read as given, or -1. */
async function operationNamed(page: Page, symbols: string): Promise<number> {
  return page.evaluate((given) => {
    for (let i = 0; i < nimOperationCount(); i += 1) {
      if (nimOperationNotation(i) === given) return i;
    }
    return -1;
  }, symbols);
}

/** Apply one operation through bridge and return handle it added. */
async function applied(
  page: Page, operation: number, first: number, second: number,
): Promise<number> {
  const before = await page.evaluate(() => nimSceneHandles());
  await page.evaluate((given) => {
    nimApplyOperation(given.operation, given.first, given.second, performance.now() / 1000);
  }, { operation, first, second });
  await settleCount(page, before.length + 1);
  return addedHandle(before, await page.evaluate(() => nimSceneHandles())) ?? -1;
}

/** Objects naming check builds: four points, two lines, two planes and their meet. */
const COUNT_NAMED = 9;

/** Drive two planes built by joins, then their meet, and assert names stay valid formulas.
 *
 *  Name used to substitute operand names bare, so meet of two joined planes read
 *  `a ∧ b ∧ c ∨ d ∧ e ∧ f`, naming another object than one built.
 *  Brings its own four points, one-letter named and off any common plane: scene's own
 *  points are planets on one ecliptic, whose planes meet in noise, and carry names long
 *  enough for meet's name to hit label's cap.
 */
export async function driveApplyNamed(page: Page): Promise<void> {
  const wedge = await operationNamed(page, '𝐦 ∧ 𝐧');
  const meet = await operationNamed(page, '𝐦 ∨ 𝐧');
  if (wedge < 0 || meet < 0) {
    report(
      'the catalogue holds join and meet, for naming', false, `join ${wedge}, meet ${meet}`,
    );
    return;
  }
  const count_found = await page.evaluate(() => nimSceneCount());
  const capacity = await page.evaluate(() => nimSceneCapacity());
  if (count_found + COUNT_NAMED > capacity) {
    report(
      'the scene has room for the objects the naming check builds', false,
      `${count_found} of ${capacity} held, ${COUNT_NAMED} wanted`,
    );
    return;
  }
  const points = await page.evaluate(() => {
    const corners: [string, number, number, number][] =
      [['p', 0, 0, 0], ['q', 1, 0, 0], ['r', 0, 1, 0], ['s', 0, 0, 1]];
    const added = corners.map(([label, x, y, z]) => {
      const model = new Array<number>(nimBasisCount()).fill(0);
      model[1] = x;
      model[2] = y;
      model[3] = z;
      model[4] = 1;
      return nimAddObject(
        model, label, nimDefaultInk(), nimDefaultRadius(), performance.now() / 1000,
      );
    });
    nimSelectClear();
    return added;
  });
  const [a, b, c, d] = points as [number, number, number, number];
  const line_first = await applied(page, wedge, a, b);
  const plane_first = await applied(page, wedge, line_first, c);
  const line_second = await applied(page, wedge, b, c);
  const plane_second = await applied(page, wedge, line_second, d);
  const met = await applied(page, meet, plane_first, plane_second);
  const names = await page.evaluate((given) => given.map((one) => nimObjectLabel(one)), [
    a, b, c, d, plane_first, plane_second, met,
  ]);
  const [name_a, name_b, name_c, name_d, name_plane_first, name_plane_second, name_met] =
    names as [string, string, string, string, string, string, string];
  const wanted_first = `${name_a} ∧ ${name_b} ∧ ${name_c}`;
  const wanted_second = `${name_b} ∧ ${name_c} ∧ ${name_d}`;
  const wanted_met = `(${wanted_first}) ∨ (${wanted_second})`;
  report(
    'a join of joins stays flat and a meet of joins is parenthesised, so names stay formulas',
    name_plane_first === wanted_first && name_plane_second === wanted_second &&
      name_met === wanted_met,
    `planes ${name_plane_first} and ${name_plane_second}, meet ${name_met}`,
  );
  // Leave scene as found, deleting way reader deletes: later checks count its objects.
  await page.evaluate((given) => {
    selectOnly(given[0] ?? 0, null);
    for (const one of given.slice(1)) toggleSelection(one, null);
    refreshSelectionMenu(null);
    document.getElementById('selection-menu-delete')?.click();
  }, [met, plane_second, line_second, plane_first, line_first, d, c, b, a]);
  await settleCount(page, count_found);
}

/** Apply same pair twice, through picker and through bridge, and compare what came out. */
async function driveApplyPair(page: Page): Promise<void> {
  const before_picker = await page.evaluate(() => nimSceneHandles());
  const applied = await page.evaluate(() => {
    const handles = nimSceneHandles();
    const first = document.getElementById('op-first') as HTMLSelectElement | null;
    const second = document.getElementById('op-second') as HTMLSelectElement | null;
    const chosen = document.getElementById('op-select') as HTMLSelectElement | null;
    if (first !== null) first.value = '0';
    if (second !== null) second.value = '1';
    const operation = parseInt(chosen?.value ?? '0', 10);
    document.getElementById('button-apply')?.click();
    return { operation, first: handles[0] ?? 0, second: handles[1] ?? 0 };
  });
  await settleCount(page, before_picker.length + 1);

  const after_picker = await page.evaluate(() => nimSceneHandles());
  const by_picker = addedHandle(before_picker, after_picker);
  await page.evaluate((given) => {
    nimApplyOperation(given.operation, given.first, given.second, performance.now() / 1000);
  }, applied);
  await settleCount(page, before_picker.length + 2);
  const by_bridge = addedHandle(after_picker, await page.evaluate(() => nimSceneHandles()));

  const name = 'apply builds from the operands its pickers name, not from their positions';
  if (by_picker === undefined || by_bridge === undefined) {
    // Report rather than throw, since this is shape regression takes here: reading position
    //   as handle names one delete above freed, and applying to dead operand builds nothing.
    report(
      name, false,
      `picker built ${by_picker === undefined ? 'nothing' : 'handle ' + by_picker}` +
        `, bridge ${by_bridge === undefined ? 'nothing' : 'handle ' + by_bridge}`,
    );
    return;
  }
  // Compare by coefficients rather than by where they are drawn: operation picker may
  //   default to one whose result stands in horizon, which has no drawn anchor to compare.
  const span = await page.evaluate(([one, other]) => {
    const built_picker = nimObjectCoefficients(one as number);
    const built_bridge = nimObjectCoefficients(other as number);
    return Math.max(
      ...built_picker.map((value, index) => Math.abs(value - (built_bridge[index] ?? 0))),
    );
  }, [by_picker, by_bridge]);
  report(name, span < 1e-9, `the two agree to ${span.toExponential(1)} across every coefficient`);
}

/** Drive undo by key, which used to reach nothing in frames right after edit.
 *
 *  Buttons key answers through were refreshed on low-cadence tick, so key pressed inside
 *  that window found no button to press.
 */
export async function driveUndo(page: Page): Promise<void> {
  const before = await page.evaluate(() => nimSceneCount());
  await page.evaluate(() => document.getElementById('gl')?.focus());
  await page.keyboard.press('Control+z');
  await settleCount(page, before - 1);
  const after = await page.evaluate(() => nimSceneCount());
  report(
    'undo reaches the timeline in the frames right after an edit',
    after === before - 1, `${after} objects, was ${before}`,
  );
}

/** Drive selection menu's own apply, which is route with no dragging in it.
 *
 *  WCAG 2.5.7: every operation drag reaches is reachable without dragging, through
 *  selection, menu, apply. Route is what is checked, never its wording. Selected through
 *  page's own helpers, so menu's view of selection is one finger would have left.
 */
export async function driveReachable(page: Page): Promise<void> {
  await page.evaluate(() => {
    const handles = nimSceneHandles();
    selectOnly(handles[0] ?? 0, null);
    toggleSelection(handles[1] ?? 0, null);
  });
  await settleSelection(page, 2);
  const before = await page.evaluate(() => nimSceneCount());

  // Press menu's apply twice, by design: first press opens picker beside it, second commits
  //   whatever that picker names.
  await page.evaluate(() => document.getElementById('selection-menu-apply')?.click());
  await page.waitForFunction(() => {
    const chosen = document.getElementById('selection-menu-select') as HTMLSelectElement | null;
    return chosen !== null && chosen.options.length > 0;
  }, null, { timeout: 8000, polling: 'raf' });
  await page.evaluate(() => {
    const chosen = document.getElementById('selection-menu-select') as HTMLSelectElement | null;
    if (chosen !== null) {
      chosen.value = chosen.options[0]?.value ?? '';
      chosen.dispatchEvent(new Event('change'));
    }
    document.getElementById('selection-menu-apply')?.click();
  });
  await settleCount(page, before + 1);
  const after = await page.evaluate(() => nimSceneCount());
  report(
    'every operation is reachable without dragging at all',
    after === before + 1, `${after} objects, was ${before}`,
  );
}
