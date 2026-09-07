// Checks for hover during camera gesture, and for help; not Nim because pointer is driven
//   through Playwright, which node alone reaches, and because crossing would forfeit check
//   compiler makes over `page.evaluate` bodies naming bridge's derived exports.
//   Hover rule is sampled every step, not only at end: one frame of highlight is one too
//   many, and suite that read only final state would miss string of them lighting up.

import type { Page } from '@playwright/test';
import { clearTheGlass } from './gestures';
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
    await page.waitForTimeout(20);
  }
  await page.mouse.up();
  await page.waitForTimeout(150);
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

/** Drive help, which stays open while reader uses what it describes. */
export async function driveHelp(page: Page, width: number, height: number): Promise<void> {
  await page.evaluate(() => showHelp(true));
  await page.waitForTimeout(200);
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
  await page.waitForTimeout(200);
  report(
    'the help closes when the reader closes it',
    !(await page.evaluate(
      () => document.getElementById('help-panel')?.classList.contains('show') ?? false,
    )),
    'closed by its own button',
  );
}
