// Check that outcome page reports stands as long as Nim says and then takes itself away;
//   not Nim because what is under check is duration measured against real clock in real
//   browser, which harness alone holds.
//   Window had no check like this because window had no such behaviour: its line stood
//   until something replaced it. `message.messageFade` states rule, suite holds it as
//   arithmetic, and this holds page to it as it runs.

import type { Page } from '@playwright/test';
import { report } from './report';

/** Read what page believes outcome's life to be, straight from bridge. */
async function lifeOfMessage(page: Page): Promise<[number, number]> {
  const seconds = await page.evaluate(() => nimMessageSeconds());
  return [(seconds[0] ?? 0)*1000, (seconds[1] ?? 0)*1000];
}

/** Raise one outcome and wait for it to go, without touching it again.
 *
 *  Wall clock deliberately, unlike `driveRendered`: there what mattered was frames drawn
 *  and clock made check load-dependent, while here duration *is* thing under check.
 *  Second half waits on condition rather than sleeping exactly as long as toast should
 *  last, so machine that fires its timer late still passes; toast that never goes is only
 *  failure worth reporting.
 */
export async function driveMessageGoes(page: Page): Promise<void> {
  const [standing, fading] = await lifeOfMessage(page);
  report(
    'the page takes the outcome\'s life from Nim rather than from a number of its own',
    standing > 0 && fading > 0,
    `stands ${standing} ms, fades ${fading} ms`,
  );

  await page.evaluate(() => {
    // Clear whatever earlier check left up, so this measures its own toast and not one
    //   that was already on screen.
    const bar = document.getElementById('toast');
    if (bar !== null) { bar.classList.remove('show'); bar.textContent = ''; }
    toast('Driven check speaking.');
  });
  const isShown = () => page.evaluate(
    () => document.getElementById('toast')?.classList.contains('show') ?? false);
  const shown_at_once = await isShown();
  // Half its stand in it is still up. Timer cannot fire early, so this is no race.
  await page.waitForTimeout(standing*0.5);
  const shown_halfway = await isShown();

  let is_gone = true;
  try {
    await page.waitForFunction(
      () => !(document.getElementById('toast')?.classList.contains('show') ?? false),
      undefined, { timeout: standing + fading + 5000 },
    );
  } catch {
    is_gone = false;
  }
  report(
    'an outcome stands, then takes itself off the page with nobody dismissing it',
    shown_at_once && shown_halfway && is_gone,
    `shown ${shown_at_once}, still shown halfway ${shown_halfway}, gone ${is_gone}`,
  );
}
