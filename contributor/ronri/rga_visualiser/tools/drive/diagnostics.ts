// Checks for diagnostics section's own clocks and its tree; not Nim because crossing forfeits
//   check compiler makes over bulk of this file: its `page.evaluate` bodies name
//   `PHASES_DIAGNOSTIC`, `element_phase` and rest of panel's own scope, stated by `page.d.ts`.
//   Reading computed style is not what decides it; glue reaches that too.
//   Rows are written only while drawer is open -- gate that stopped whole refresh costing
//   milliseconds five times second with nobody reading it -- and chevron's rotation is
//   resolvable only on rendered element, since inside `display: none` subtree computed
//   transform answers `none` whatever rule says. So these reach panel way reader does.

import type { Page } from '@playwright/test';
import { readPhases } from './frame';
import { report } from './report';

/** Rows every drawing step owns, which must all read live once branch is open. */
const ROWS_STEP = [
  'build', 'camera', 'furniture', 'scene', 'matrix', 'flatten', 'unaccounted',
  'placing', 'emitting', 'hover', 'upload', 'overlay', 'ui',
];

/** Whether drawer and its diagnostics section stood open, so they can be put back. */
export interface Glass {
  drawer: boolean;
  section: boolean;
}

/** Open drawer and diagnostics section, reporting how they stood before. */
export async function openDiagnostics(page: Page): Promise<Glass> {
  const was = await page.evaluate(() => {
    const drawer = document.querySelector('.drawer');
    const section = document.querySelector('.section[data-section="diagnostics"]');
    const standing = {
      drawer: drawer?.classList.contains('open') ?? false,
      section: section?.classList.contains('open') ?? false,
    };
    if (!standing.drawer) document.getElementById('button-drawer')?.click();
    if (!standing.section) {
      (section?.querySelector('.section-header') as HTMLElement | null)?.click();
    }
    return standing;
  });
  await page.waitForTimeout(500);
  return was;
}

/** Put drawer and section back exactly as they were found. */
export async function closeDiagnostics(page: Page, was: Glass): Promise<void> {
  await page.evaluate((given) => {
    const drawer = document.querySelector('.drawer');
    const section = document.querySelector('.section[data-section="diagnostics"]');
    if ((drawer?.classList.contains('open') ?? false) !== given.drawer) {
      document.getElementById('button-drawer')?.click();
    }
    if ((section?.classList.contains('open') ?? false) !== given.section) {
      (section?.querySelector('.section-header') as HTMLElement | null)?.click();
    }
  }, was);
  await page.waitForTimeout(400);
}

/** Check bridge's own build steps: populated, summing within whole, agreeing with clock.
 *
 *  Bridge reports scenery, scene objects and flatten; those must sum to no more than whole
 *  they are steps of, and agree with wall clock held around call from outside. Bands are
 *  generous: `performance.now` is quantised, and this container is slow.
 */
export async function drivePhaseSums(page: Page): Promise<void> {
  const phases = await readPhases(page);
  const sane = phases.filter((one) =>
    one.build > 0 && one.scene >= 0 && one.furniture >= 0 && one.flatten >= 0 &&
    one.furniture + one.scene + one.flatten <= one.build + 1.0 && one.build <= one.wall + 1.0);
  report(
    'the build reports its phases, and they add up',
    phases.length > 30 && sane.length === phases.length,
    `${sane.length} of ${phases.length} frames consistent`,
  );
}

/** Drive diagnostics tree open, and assert what each branch reveals.
 *
 *  Tree starts wholly closed: reader opens this panel to learn whether frame is slow, and
 *  goes looking for which step only once it is. So subtotals under `build` are checked idle
 *  first, then opened way reader opens them, and only then checked live -- without that
 *  first half, tree that never closed would pass.
 */
export async function driveTree(page: Page): Promise<void> {
  const was = await openDiagnostics(page);

  const closed = await page.evaluate(() => ({
    is_open: document.querySelector('.diagnostic-node[data-node="build"]')
      ?.classList.contains('open') ?? false,
    children: ['furniture', 'scene', 'flatten']
      .map((name) => document.getElementById('diagnostic-' + name)?.textContent ?? ''),
  }));
  report(
    'the frame-time breakdown starts collapsed',
    !closed.is_open && closed.children.every((text) => !/ ms$/.test(text)),
    `node open ${closed.is_open}, children ${JSON.stringify(closed.children)}`,
  );

  await page.evaluate(() => {
    const parent = document.querySelector(
      '.diagnostic-node[data-node="build"] .diagnostic-parent',
    );
    (parent as HTMLElement | null)?.click();
  });
  await page.waitForTimeout(400);
  const rows = await page.evaluate((names) => Object.fromEntries(
    names.map((name) => [name, document.getElementById('diagnostic-' + name)?.textContent ?? '']),
  ), ROWS_STEP);
  report(
    'every drawing step has a live row once its branch is opened',
    Object.values(rows).every((text) => / ms$/.test(text)),
    Object.entries(rows).map(([name, text]) => `${name}: ${text}`).join(', '),
  );

  await driveBranch(page);
  // Open scenery too, for checks below which read every row, then put glass back.
  await page.evaluate(() => {
    const parent = document.querySelector(
      '.diagnostic-node[data-node="furniture"] > .diagnostic-parent',
    );
    (parent as HTMLElement | null)?.click();
  });
  await closeDiagnostics(page, was);
}

/** Assert branch opens its own rows and stops there.
 *
 *  `build` is open here and nothing under it has been touched, so two nested branches must
 *  still be shut: their rows out of layout and their chevrons unturned. Rules that reveal
 *  branch's children used descendant combinator, so opening `build` laid whole tree bare
 *  and turned all three chevrons while row writer went on correctly treating inner nodes as
 *  closed. Every deeper row then sat on screen, apparently expanded, showing em dash for
 *  good. Driving every branch open hid it: only opening outermost one does.
 */
async function driveBranch(page: Page): Promise<void> {
  const shut = await page.evaluate(() => {
    // Ask row's own branch container, not `offsetParent`: everything in drawer sits inside
    //   fixed ancestor, which makes `offsetParent` null whatever branch is doing.
    const isLaid = (id: string): boolean => {
      const box = document.getElementById(id)?.closest('.diagnostic-children');
      return box !== null && box !== undefined && getComputedStyle(box).display !== 'none';
    };
    const isTurned = (node: string): boolean => {
      const chev = document.querySelector(
        '.diagnostic-node[data-node="' + node + '"] > .diagnostic-parent .chev',
      );
      return chev !== null && getComputedStyle(chev).transform !== 'none';
    };
    const standing = {
      grid: isLaid('diagnostic-grid'), points: isLaid('diagnostic-points'),
      is_scenery_turned: isTurned('furniture'), is_scene_turned: isTurned('scene'),
    };
    const parent = document.querySelector(
      '.diagnostic-node[data-node="scene"] > .diagnostic-parent',
    );
    (parent as HTMLElement | null)?.click();
    return standing;
  });
  // Read after chevron's own turn has finished: asked in same tick as click, transition
  //   that has not started yet still reports its old transform.
  await page.waitForTimeout(700);

  const opened = await page.evaluate(() => {
    const isLaid = (id: string): boolean => {
      const box = document.getElementById(id)?.closest('.diagnostic-children');
      return box !== null && box !== undefined && getComputedStyle(box).display !== 'none';
    };
    const isTurned = (node: string): boolean => {
      const chev = document.querySelector(
        '.diagnostic-node[data-node="' + node + '"] > .diagnostic-parent .chev',
      );
      return chev !== null && getComputedStyle(chev).transform !== 'none';
    };
    return {
      points: isLaid('diagnostic-points'), grid: isLaid('diagnostic-grid'),
      is_scene_turned: isTurned('scene'), is_scenery_turned: isTurned('furniture'),
      reading: document.getElementById('diagnostic-points')?.textContent ?? '',
    };
  });
  report(
    'opening a branch reveals its own rows only, and they carry numbers',
    // Shut: neither nested branch is laid out or turned, though their parent is open.
    !shut.grid && !shut.points && !shut.is_scenery_turned && !shut.is_scene_turned &&
      // Opened: scene alone -- its rows appear and chevron turns, scenery stays shut.
      opened.points && opened.is_scene_turned && !opened.grid && !opened.is_scenery_turned &&
      / ms/.test(opened.reading),
    `with build alone open: grid laid ${shut.grid}, points laid ${shut.points}, ` +
      `chevrons turned ${shut.is_scenery_turned}/${shut.is_scene_turned}; after opening ` +
      `scene: points laid ${opened.points} turned ${opened.is_scene_turned} reading ` +
      `"${opened.reading}", grid laid ${opened.grid} turned ${opened.is_scenery_turned}`,
  );
}
