// Gestures suites cannot reach: held keys, pinch, tap; not Nim because they are Playwright's
//   own input API, which exists only in node.
//   Nothing in suites presses key, turns wheel or puts two fingers on canvas, so nothing in
//   them catches rule wired to wrong event. This is that layer.

import type { Page } from '@playwright/test';
import { readCamera, type Stance } from './camera';

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
  await page.waitForTimeout(200);
}

/** Hold keys for however long, and report what camera did across it. */
export async function holdKeys(
  page: Page, codes: string[], milliseconds: number,
): Promise<Moved> {
  const before = await readCamera(page);
  for (const code of codes) await page.keyboard.down(code);
  await page.waitForTimeout(milliseconds);
  for (const code of codes) await page.keyboard.up(code);
  await page.waitForTimeout(80);
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
