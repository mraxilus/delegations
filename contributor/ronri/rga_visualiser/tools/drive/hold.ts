// Checks for scene hold, which is frame matching last one skipping its whole rebuild; not Nim
//   because crossing forfeits check compiler makes over body wrapping `nimBuildFrame` and
//   reading `FrameData`'s fields, every one derived or stated by `page.d.ts`.
//   Danger of hold is not that it fails to engage -- that costs milliseconds -- but that it
//   engages when it should not, and shows picture no longer matching scene. So both halves are
//   held here, and second through *drawn pixels* rather than through flag: hold that released
//   but drew old records would pass flag check.
//   Pixels come from `canvas.readCanvas`, which reads through compositor and refuses blank
//   reading; earlier `readPixels` copy here reported no change at all on browsers whose
//   drawing buffer is gone by then, which read as hold never reaching canvas.

import type { Page } from '@playwright/test';
import { readCanvas } from './canvas';
import { waitFrames } from './frame';
import { report } from './report';

/** Each edit path checked, named as reader would name it. */
const EDITS = [
  'hiding an object', 'showing it again', 'recolouring an object', 'moving a coefficient',
  'selecting an object', 'removing an object', 'undoing that removal', 'redoing it',
];

declare global {
  interface Window {
    /** How many frames held their records, and how many rebuilt. */
    __hold?: { held: number; built: number };
  }
}

/** Wrap page's frame build, counting frames that held their records against those that did not. */
async function watchHold(page: Page): Promise<void> {
  await page.evaluate(() => {
    nimSelectClear();
    document.getElementById('gl')?.focus();
    window.__hold = { held: 0, built: 0 };
    const scope = globalThis as unknown as { nimBuildFrame: typeof nimBuildFrame };
    const built = scope.nimBuildFrame;
    scope.nimBuildFrame = function (
      ...given: Parameters<typeof nimBuildFrame>
    ): FrameData {
      const data = built(...given);
      const counted = window.__hold;
      if (counted !== undefined) {
        if (data.is_scene_held) counted.held += 1; else counted.built += 1;
      }
      return data;
    };
    // One rebuild owed to counter above, so both sides of hold are seen. Inside same task as
    //   counter, so no frame can spend it first; recolouring object to ink it already wears
    //   moves revision and not one pixel.
    const first = nimSceneHandles()[0] ?? 0;
    nimSetInk(first, nimObjectInk(first));

  });
}

/** Run one edit path by its own name, through very export page's controls call. */
async function runEdit(page: Page, what: string): Promise<void> {
  await page.evaluate((given) => {
    const second = nimSceneHandles()[1] ?? 0;
    if (given === 'hiding an object') nimSetVisible(second, false);
    else if (given === 'showing it again') nimSetVisible(second, true);
    else if (given === 'recolouring an object') nimSetInk(second, 4);
    else if (given === 'moving a coefficient') nimSetCoefficient(second, 1, 4.5);
    else if (given === 'selecting an object') nimSelectOnly(second);
    else if (given === 'removing an object') nimRemoveObject(second);
    else if (given === 'undoing that removal') nimUndo();
    else if (given === 'redoing it') nimRedo();
  }, what);
}

/** Drive still scene, then every edit, and assert hold engages and releases. */
export async function driveHoldScene(page: Page): Promise<void> {
  await watchHold(page);
  // Wall time, deliberately: figure is share of frames that held over span of real time.
  await page.waitForTimeout(1200);
  const idle = await page.evaluate(() => ({ ...(window.__hold ?? { held: 0, built: 0 }) }));
  report(
    'a still camera over a still scene holds its records instead of rebuilding them',
    idle.held > 0.5 * (idle.held + idle.built) && idle.built > 0,
    `${idle.held} held, ${idle.built} rebuilt over ~1.2 s`,
  );

  let released = 0, redrawn = 0;
  const missed: string[] = [];
  for (const what of EDITS) {
    const before = (await readCanvas(page)).mark;
    await page.evaluate(() => { window.__hold = { held: 0, built: 0 }; });
    await runEdit(page, what);
    // Wall time, deliberately: check is that edit released hold and reached canvas, and
    //   waiting on either would assert what is being asked.
    await page.waitForTimeout(500);
    const after = (await readCanvas(page)).mark;
    const seen = await page.evaluate(() => ({ ...(window.__hold ?? { held: 0, built: 0 }) }));
    if (seen.built > 0) released += 1;
    if (after !== before) redrawn += 1;
    if (seen.built === 0 || after === before) {
      missed.push(`${what}: ${seen.built} rebuilt, canvas ` +
        `${after === before ? 'unchanged' : 'changed'}`);
    }
  }
  report(
    'and every edit releases the hold and reaches the canvas',
    released === EDITS.length && redrawn === EDITS.length,
    `${released} of ${EDITS.length} released, ${redrawn} of ${EDITS.length} redrawn` +
      (missed.length === 0 ? '' : `; ${missed.join('; ')}`),
  );
  await page.evaluate(() => nimSelectClear());
  await waitFrames(page, 2);
}
