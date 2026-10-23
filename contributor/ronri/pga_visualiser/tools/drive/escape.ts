// Check Escape sheds one thing for each press, in order both front-ends ask core for; not Nim
//   because it presses real key through Playwright, whose API exists only in node.
//   Suite walks `interaction.backOut` alone; this holds page's wiring to it, as desktop's
//   `--drive-escape` holds its own.

import type { Page } from '@playwright/test';
import { advanceFrames } from './clock';
import { focusCanvas, settleSelection } from './gestures';
import { report } from './report';

/** One letter for each thing Escape sheds, in `interaction.BackOut`'s order.
 *
 *  Help, top menu, gesture, edit, selection menu (P for its pop-up), selection.
 */
const LETTERS_STANDING = 'HMGEPS';

/** Read what stands on page, as letter for each, in `BackOut`'s order. */
async function standing(page: Page): Promise<string> {
  const flags = await page.evaluate(() => [
    document.getElementById('help-panel')?.classList.contains('show') ?? false,
    document.getElementById('top-menu')?.classList.contains('show') ?? false,
    nimDragActive() || nimHoldHandle() >= 0,
    session_edit !== null,
    isSelectionMenuShown(),
    nimSelectionCount() > 0,
  ]);
  return flags.map((is_standing, i) => (is_standing ? LETTERS_STANDING[i] : '')).join('');
}

/** Stand up everything Escape sheds at once, then press it until nothing stands. */
export async function driveEscape(page: Page): Promise<void> {
  // Selection with its menu, edit on it, hold on another, then top menu and help over all.
  //   Opened through page's own entries: claim is order Escape sheds them in, and each
  //   control's way of opening one is check of its own.
  await page.evaluate(() => {
    const [first, second] = nimSceneHandles();
    selectOnly(first ?? 0, null);
    beginEditSession(first ?? 0);
    refreshObjectsUI();
    nimBeginHold(second ?? 0, performance.now() / 1000);
    document.getElementById('button-menu')?.click();
    showHelp(true);
  });
  await settleSelection(page, 1);
  const seen = [await standing(page)];
  // One press more than there are things, which must shed nothing.
  for (let press = 0; press <= LETTERS_STANDING.length; press += 1) {
    // Canvas holds focus, as reader's would: Escape inside field is field's own.
    await focusCanvas(page);
    await page.keyboard.press('Escape');
    await advanceFrames(page, 2);
    seen.push(await standing(page));
  }
  // After press k stands what stood before, less first k: one thing for each press.
  const wanted = seen.map((_, k) => LETTERS_STANDING.slice(k));
  report(
    'escape sheds one thing for each press: help, top menu, hold, edit, selection menu, selection',
    seen.join(' ') === wanted.join(' '),
    seen.map((letters) => letters || '-').join(' -> '),
  );
}
