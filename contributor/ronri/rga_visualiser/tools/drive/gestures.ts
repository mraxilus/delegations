// Gestures suites cannot reach: held keys, pinch, tap; not Nim because they are Playwright's
//   own input API, which exists only in node.
//   Nothing in suites presses key, turns wheel or puts two fingers on canvas, so nothing in
//   them catches rule wired to wrong event. This is that layer.

import type { Page } from '@playwright/test';
import { readCamera, type Stance } from './camera';
import { waitFrames } from './frame';

/** What one gesture did to camera: stance either side of it. */
export interface Moved {
  before: Stance;
  after: Stance;
}

/** Clear chrome standing over canvas, before any section that drives canvas.
 *
 *  Sections that opened drawer or menu leave them sitting over canvas, where they swallow
 *  every pointer event, so gesture driven at pixel beneath one never reaches application.
 */
export async function clearTheGlass(page: Page): Promise<void> {
  await page.evaluate(() => {
    clearSelection();
    hideSelectionMenu();
    const drawer = document.querySelector('.drawer');
    if (drawer !== null && drawer.classList.contains('open')) {
      document.getElementById('button-drawer')?.click();
    }
  });
  // Wait on what was asked for rather than on clock: drawer's own transition decides when it
  //   stops taking pointer events, and loaded runner runs that slower than any fixed wait.
  await page.waitForFunction(() => {
    const drawer = document.querySelector('.drawer');
    const menu = document.getElementById('selection-menu');
    return !(drawer?.classList.contains('open') ?? false) &&
      !(menu?.classList.contains('show') ?? false) && nimSelectionCount() === 0;
  }, null, { timeout: 8000, polling: 'raf' });
}

/** Hold keys for however long, and report what camera did across it. */
export async function holdKeys(
  page: Page, codes: string[], milliseconds: number,
): Promise<Moved> {
  const before = await readCamera(page);
  for (const code of codes) await page.keyboard.down(code);
  await page.waitForTimeout(milliseconds);
  for (const code of codes) await page.keyboard.up(code);
  // Two frames, not fixed wait: release has to reach frame loop, and that is measured in
  //   frames. Hold above stays wall time, since how long key is down is what caller asked for.
  await waitFrames(page, 2);
  return { before, after: await readCamera(page) };
}

/** Focus canvas rather than clicking it.
 *
 *  Click on canvas selects whatever is under it, standing framing offer then moves camera on
 *  its own, and every reading would be measuring that instead of gesture under test.
 */
export async function focusCanvas(page: Page): Promise<void> {
  await page.evaluate(() => document.getElementById('gl')?.focus());
}


/** Wait until scene holds this many objects.
 *
 *  Every edit path -- apply, delete, undo -- ends by changing that count, so it is what
 *  "edit landed" means. Waiting on it rather than on clock makes check pass or fail on what
 *  page did, never on how fast machine ran.
 */
export async function settleCount(page: Page, wanted: number): Promise<void> {
  await page.waitForFunction(
    (given) => nimSceneCount() === given, wanted, { timeout: 8000, polling: 'raf' },
  );
}


/** Wait until drawer stands open, or shut.
 *
 *  Drawer slides, so class is set one frame and panel stops taking pointer events later.
 *  Waiting on class rather than on clock leaves slow machine slow rather than wrong.
 */
export async function settleDrawer(page: Page, is_open: boolean): Promise<void> {
  await page.waitForFunction(
    (given) => (document.getElementById('drawer')?.classList.contains('open') ?? false) === given,
    is_open, { timeout: 8000, polling: 'raf' },
  );
}


/** Wait until this many objects stand selected. */
export async function settleSelection(page: Page, wanted: number): Promise<void> {
  await page.waitForFunction(
    (given) => nimSelectionCount() === given, wanted, { timeout: 8000, polling: 'raf' },
  );
}
