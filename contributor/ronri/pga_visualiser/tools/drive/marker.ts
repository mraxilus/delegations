// Check that overlay shapes each marker it draws once; not Nim because crossing forfeits check
//   compiler makes over bodies wrapping `nimSelectionMarker` and naming `nimCountShaped` and
//   page's own `selectOnly` -- signatures `declare` derives and `page.d.ts` states.
//   Overlay asks bridge for marker, then its pulse, then its label, each by call of its own.
//   Bridge keeps marker call's outline in one entry, `MARKER_SHAPED`, which pulse and label
//   read wherever every input matches; call that leaves input out misses, shapes again, and
//   drops entry, so label shapes third time.
//   Count rather than time: count reads same on every machine, and load never moves it.

import type { Page } from '@playwright/test';
import { advanceFrames } from './clock';
import { clearTheGlass } from './gestures';
import { report } from './report';

/** Frames each kind is counted over; more than one, so steady state is what is read. */
const FRAMES_COUNTED = 3;

/** Kinds whose markers differ in shape: ring, rails, and loop lying on plane. */
const KINDS_SHAPED = ['point', 'line', 'plane'];

declare global {
  interface Window {
    /** How many markers overlay drew since counter was reset. */
    __drawn_marker?: number;
    /** Page's own marker export, held while counting wrapper stands in front of it. */
    __marker_unwrapped?: typeof nimSelectionMarker;
  }
}

/** Select each kind alone, and assert overlay shapes every marker it draws once.
 *
 *  Markers drawn are counted at page's own call, so hover or focus marker drawn beside
 *  selected one counts on both sides alike. Frame that drew nothing cannot pass: each
 *  counted frame must draw selected object's marker.
 */
export async function driveMarkerShapedOnce(page: Page): Promise<void> {
  await clearTheGlass(page);
  await page.evaluate(() => {
    const scope = globalThis as unknown as { nimSelectionMarker: typeof nimSelectionMarker };
    const unwrapped = scope.nimSelectionMarker;
    window.__marker_unwrapped = unwrapped;
    scope.nimSelectionMarker = function (
      ...given: Parameters<typeof nimSelectionMarker>
    ): number[] {
      window.__drawn_marker = (window.__drawn_marker ?? 0) + 1;
      return unwrapped(...given);
    };
  });

  let is_passing = true;
  const readings: string[] = [];
  for (const kind of KINDS_SHAPED) {
    const handle = await page.evaluate(
      (word) => nimSceneHandles().find((one) => nimObjectKindWord(one) === word) ?? -1, kind,
    );
    if (handle < 0) {
      is_passing = false;
      readings.push(`no ${kind} in the scene`);
      continue;
    }
    // Time stands still between these calls, so frames counted are frames advanced.
    await page.evaluate((one) => {
      selectOnly(one, null);
      window.__drawn_marker = 0;
      nimSetCountingShaped(true);
    }, handle);
    await advanceFrames(page, FRAMES_COUNTED);
    const counted = await page.evaluate(() => {
      const shaped = nimCountShaped();
      nimSetCountingShaped(false);
      return { drawn: window.__drawn_marker ?? 0, shaped };
    });
    if (counted.drawn < FRAMES_COUNTED || counted.shaped !== counted.drawn) is_passing = false;
    readings.push(`${kind}: ${counted.shaped} shaped for ${counted.drawn} drawn`);
  }

  await page.evaluate(() => {
    const scope = globalThis as unknown as { nimSelectionMarker: typeof nimSelectionMarker };
    if (window.__marker_unwrapped !== undefined) {
      scope.nimSelectionMarker = window.__marker_unwrapped;
    }
    clearSelection();
  });
  report(
    'an overlay frame shapes each marker it draws once, its pulse and label reusing it',
    is_passing, `${readings.join(', ')}, over ${FRAMES_COUNTED} frames each`,
  );
}
