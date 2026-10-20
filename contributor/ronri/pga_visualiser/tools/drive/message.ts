// Check that outcome page reports stands as long as Nim says and then takes itself away;
//   not Nim because what is under check is duration that page's own timers keep in real
//   browser, which harness alone holds. Runs on simulated clock, which moves those timers.
//   Window had no check like this because window had no such behaviour: its line stood
//   until something replaced it. `message.messageFade` states rule, suite holds it as
//   arithmetic, and this holds page to it as it runs.

import type { Page } from '@playwright/test';
import { advance, waitUntil } from './clock';
import { report } from './report';

/** Read what page believes outcome's life to be, straight from bridge. */
async function lifeOfMessage(page: Page): Promise<[number, number]> {
  const seconds = await page.evaluate(() => nimMessageSeconds());
  return [(seconds[0] ?? 0)*1000, (seconds[1] ?? 0)*1000];
}

/** Raise one outcome and wait for it to go, without touching it again.
 *
 *  Simulated clock, as every correctness check: duration *is* thing under check, and page's
 *  own timers keep it, so `advance` moves exactly what toast waits on.
 *  Second half steps frames until toast goes, rather than advancing its exact life, so check
 *  reads going itself rather than arithmetic; toast that never goes is only failure worth
 *  reporting.
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
  await advance(page, standing*0.5);
  const shown_halfway = await isShown();

  let is_gone = true;
  try {
    await waitUntil(
      page, () => !(document.getElementById('toast')?.classList.contains('show') ?? false),
      undefined,
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
