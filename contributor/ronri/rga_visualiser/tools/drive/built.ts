// Checks that every frame builds its scene records, and that every edit reaches canvas; not Nim
//   because crossing forfeits check compiler makes over body wrapping `nimBuildFrame` and
//   reading `FrameData`'s fields, every one derived or stated by `page.d.ts`.
//   Still frame builds, uploads and draws whole scene as moving one does; see `PROVENANCE.md`,
//   Render paths. Frame that kept last frame's records would send none, which first check sees.
//   Second holds edit through *drawn pixels* rather than through records: frame that built
//   right records and drew old ones would pass record check.
//   Pixels come from `canvas.readCanvas`, which reads through compositor and refuses blank
//   reading; earlier `readPixels` copy here reported no change at all on browsers whose
//   drawing buffer is gone by then, which read as edit never reaching canvas.

import type { Page } from '@playwright/test';
import { advance } from './clock';
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
    /** Records each frame built, summed over every stream, since counter was reset. */
    __built?: number[];
  }
}

/** Wrap page's frame build, keeping count of records each frame sends. */
async function watchBuilt(page: Page): Promise<void> {
  await page.evaluate(() => {
    nimSelectClear();
    document.getElementById('gl')?.focus();
    window.__built = [];
    const scope = globalThis as unknown as { nimBuildFrame: typeof nimBuildFrame };
    const built = scope.nimBuildFrame;
    scope.nimBuildFrame = function (
      ...given: Parameters<typeof nimBuildFrame>
    ): FrameData {
      const data = built(...given);
      window.__built?.push(
        data.ribbon_vertices.length + data.point_vertices.length + data.ring_records.length +
          data.disc_records.length + data.dome_records.length,
      );
      return data;
    };
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

/** Drive still scene, then every edit, and assert each frame builds and each edit is drawn. */
export async function driveSceneBuilt(page: Page): Promise<void> {
  await watchBuilt(page);
  // Simulated span: every frame over it is read, and fixed span is same count on any machine.
  await advance(page, 1200);
  const still = await page.evaluate(() => [...(window.__built ?? [])]);
  const first = still[0] ?? 0;
  report(
    'a still camera over a still scene builds its whole records on every frame',
    still.length > 10 && first > 0 && still.every((one) => one === first),
    `${still.length} frames over ~1.2 s, records from ${Math.min(...still)} to ` +
      `${Math.max(...still)} floats`,
  );

  let redrawn = 0;
  const missed: string[] = [];
  for (const what of EDITS) {
    const before = (await readCanvas(page)).mark;
    await runEdit(page, what);
    // Simulated span: check is that edit reached canvas, and waiting on that would assert
    //   what is being asked.
    await advance(page, 500);
    const after = (await readCanvas(page)).mark;
    if (after !== before) redrawn += 1;
    else missed.push(`${what}: canvas unchanged`);
  }
  report(
    'and every edit reaches the canvas',
    redrawn === EDITS.length,
    `${redrawn} of ${EDITS.length} redrawn` + (missed.length === 0 ? '' : `; ${missed.join('; ')}`),
  );
  await page.evaluate(() => nimSelectClear());
  await waitFrames(page, 2);
}
