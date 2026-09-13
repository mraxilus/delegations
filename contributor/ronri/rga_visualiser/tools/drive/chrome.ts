// Checks for hover during camera gesture, and for help; not Nim because pointer is driven
//   through Playwright, which node alone reaches, and because crossing would forfeit check
//   compiler makes over `page.evaluate` bodies naming bridge's derived exports.
//   Hover rule is sampled every step, not only at end: one frame of highlight is one too
//   many, and suite that read only final state would miss string of them lighting up.

import type { Page } from '@playwright/test';
import { settleCamera } from './camera';
import { clearTheGlass } from './gestures';
import { waitFrames } from './frame';
import { report } from './report';
import { pixelOf } from './wheel';

/** Drive orbit sweeping objects past pointer, which must highlight none.
 *
 *  Orbit rather than pan: pan carries world along with drag, so what was under cursor stays
 *  under it, while orbit sweeps objects past pointer that is also moving — which is case
 *  that used to light up string of them.
 */
export async function driveHoverDuringGesture(
  page: Page, width: number, height: number,
): Promise<void> {
  await page.keyboard.press('Home');
  // Clear what earlier checks left on screen, or this measures menu and drawer instead.
  await clearTheGlass(page);

  // Read handles afresh: checks above delete and build, so list captured earlier no longer
  //   names what is alive here.
  const handles = await page.evaluate(() => nimSceneHandles());
  const swept = handles[1];
  if (swept === undefined) {
    report('an object stands to sweep past', false, `${handles.length} objects`);
    return;
  }
  const pixel_swept = await pixelOf(page, swept);
  if (pixel_swept === null) {
    report('that object stands on screen', false, 'no pixel');
    return;
  }

  const start = { x: 80, y: height - 80 };
  await page.mouse.move(start.x, start.y);
  await page.mouse.down();
  let hovered_moving = -1;
  for (let step = 1; step <= 10; step += 1) {
    await page.mouse.move(
      start.x + (((pixel_swept[0] ?? 0) - start.x) * step) / 10,
      start.y + (((pixel_swept[1] ?? 0) - start.y) * step) / 10,
    );
    await page.evaluate(() => nimUpdateHover(window.innerWidth, window.innerHeight));
    const handle = await page.evaluate(() => nimHoverHandle());
    if (handle >= 0) hovered_moving = handle;
    await waitFrames(page, 2);
  }
  await page.mouse.up();
  await settleCamera(page);
  report(
    'a camera drag sweeping over objects highlights none of them',
    hovered_moving < 0, `handle hovered mid-gesture: ${hovered_moving}`,
  );

  // Aim at where that object stands *now*: gesture moved world under pointer, so its old
  //   pixel holds nothing, and asking there would say nothing about rule.
  const settled = await pixelOf(page, swept);
  if (settled === null) return;
  await page.mouse.move(settled[0] ?? 0, settled[1] ?? 0);
  await page.evaluate(() => nimUpdateHover(window.innerWidth, window.innerHeight));
  const after = await page.evaluate(() => nimHoverHandle());
  report(
    'the highlight comes back the moment the gesture ends',
    after >= 0, `hovering handle ${after} after the release`,
  );
  void width;
}

/** Wait until help panel stands up, or gone. */
async function settleHelp(page: Page, is_shown: boolean): Promise<void> {
  await page.waitForFunction(
    (given) =>
      (document.getElementById('help-panel')?.classList.contains('show') ?? false) === given,
    is_shown, { timeout: 8000, polling: 'raf' },
  );
}


/** Drive help, which stays open while reader uses what it describes. */
export async function driveHelp(page: Page, width: number, height: number): Promise<void> {
  await page.evaluate(() => showHelp(true));
  await settleHelp(page, true);
  // Wall time either side, deliberately: check is that neither click shut panel, and panel
  //   staying up has no event to wait on -- window has to be long enough for it to have gone.
  await page.mouse.click(width / 2, height - 80);
  await page.waitForTimeout(200);
  await page.click('#button-drawer');
  await page.waitForTimeout(200);
  report(
    'the help stays open while the reader uses what it describes',
    await page.evaluate(
      () => document.getElementById('help-panel')?.classList.contains('show') ?? false,
    ),
    'still open after a click on the canvas and on the drawer',
  );

  const rows = await page.evaluate(() => {
    // Tab strip names its tabs; open catalogue one and count what it renders.
    const tab = Array.from(document.querySelectorAll('#help-tabs button'))
      .find((button) => button.textContent?.trim() === 'operations');
    if (tab === undefined) return -1;
    (tab as HTMLElement).click();
    // Every path's rows live in one box, shown and hidden by tab; count this tab's own.
    return document.querySelectorAll('#help-rows .help-row[data-path="operations"]').length;
  });
  const offered = await page.evaluate(() => nimOperationCount());
  report(
    'the help lists every operation the build offers',
    rows === offered, `${rows} rows, ${offered} operations`,
  );

  await page.click('#help-close');
  await settleHelp(page, false);
  report(
    'the help closes when the reader closes it',
    !(await page.evaluate(
      () => document.getElementById('help-panel')?.classList.contains('show') ?? false,
    )),
    'closed by its own button',
  );
}

/** Widths chip row is swept at, either side of where its toggles move into menu.
 *
 *  395 is width row measured as last fitting six controls; 394 overflows by one pixel. Both are
 *  asked, so check holds boundary itself rather than two points far from it -- rule written one
 *  pixel out passes every sweep that never lands on it.
 *  320 is narrowest phone worth drawing, and 1200 is suite's own viewport.
 */
const WIDTHS_ROW_SWEPT = [1200, 500, 396, 395, 394, 360, 320];

/** Assert chip row fits at every width, and that its toggles are reachable wherever they sit.
 *
 *  Row carries six controls and fits down to 395px. Below that flex took overflow out of chips
 *  themselves, shrinking every control to keep group that no longer fit -- brand worst, since it
 *  is what gives. Axes and grid move into menu popover there instead.
 *  Reachability is asserted beside fit, deliberately: row that fits because two controls were
 *  dropped on floor is not fixed, it is broken more quietly. Toggles are counted wherever
 *  they are, and asked to be exactly one pair at every width.
 */
export async function driveChipRowFits(page: Page): Promise<void> {
  const swept: string[] = [];
  let fitted = true;
  let reachable = true;
  for (const width of WIDTHS_ROW_SWEPT) {
    await page.setViewportSize({ width, height: 800 });
    await waitFrames(page, 3);
    const read = await page.evaluate(() => {
      const row = document.querySelector('.chip-row');
      const menu = document.getElementById('top-menu');
      const toggles = document.querySelector('.toggles');
      if (row === null || menu === null || toggles === null) return null;
      const right = Math.max(...Array.from(row.querySelectorAll('button'))
        .map((each) => each.getBoundingClientRect().right));
      return {
        over: Math.round(Math.max(0, right - window.innerWidth)),
        // Where pair actually stands, asked of DOM rather than of breakpoint, so check reads
        //   what reader would reach for, never what rule intended.
        housed: menu.contains(toggles) ? 'menu' : 'row',
        pairs: document.querySelectorAll('#toggle-axes, #toggle-grid').length,
      };
    });
    if (read === null) { fitted = false; break; }
    if (read.over > 0) fitted = false;
    if (read.pairs !== 2) reachable = false;
    swept.push(`${width}: ${read.over} px over, in the ${read.housed}`);
  }
  await page.setViewportSize({ width: 1200, height: 900 });
  await waitFrames(page, 3);
  report(
    'the chip row fits at every width, and its toggles are reachable wherever they sit',
    fitted && reachable,
    swept.join('; '),
  );
}
