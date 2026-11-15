// Check that each frame culls from stance it draws, whatever hold of its aim moved camera
//   inside it; not Nim because gestures reach page through Playwright and Chrome's protocol.
//   Law, read per frame: frame draws points that second build at same moment draws, where
//   nothing moves any more. Second build reads stance first one left, so two disagree only
//   where first culled from stance it did not draw. Points are compared where each build's
//   own transform puts them on screen, so view origin either build stood about cancels.
//   Mistake as found: Architect's phone, issue 743, row D. Pinch at frame rule's floor, with
//   plane picked, dropped objects at edge of frame while fingers moved, and they came back
//   once fingers stopped.
//   Domain: each hold `framing.offerAim` makes while camera moves (floor, sky bound, fill),
//   reached by fingers and by keys. Under largest demo, where objects stand at every edge.

import type { CDPSession, Page } from '@playwright/test';
import { placeCamera, readPlaced, settleCamera } from './camera';
import { focusCanvas, holdKeys } from './gestures';
import { report } from './report';
import { asHand, handleLabelled, moveFingers, type Finger } from './touch';

/** One frame as gesture built it, beside second build at same moment. */
interface Rebuilt {
  drawn: number;
  again: number;
  is_same: boolean;
  is_moved: boolean;
}

declare global {
  interface Window {
    /** Each frame's points, built once and again, while `watchRebuilt` stands; oldest first. */
    __rebuilt_frame?: Rebuilt[];
    /** Frame build standing behind `watchRebuilt`'s wrapper, put back once check is done. */
    __build_unrebuilt?: typeof nimBuildFrame;
  }
}

/** Frames of each gesture that must move camera themselves, as hold does, before law counts. */
const FRAMES_MOVED_LEAST = 8;

/** Spreads two fingers make in each gesture: first ones reach hold, rest press past it. */
const SPREADS = 4;

/** Milliseconds each key gesture holds its keys. */
const MILLISECONDS_HELD = 1500;

/** Floats each point's record carries; its centre is first three. */
const FLOATS_POINT = 8;

/** Clip-space distance two builds' places of one point may stand apart: float32 rounding about
 *  two view origins moves place by under one millionth, and distinct stars stand pixels apart. */
const SLACK_PLACE = 1e-5;

/** Stand wrapper in front of frame build that builds each frame twice, at same moment.
 *
 *  Second build hands page its data, so page draws stance camera stands at. First one's
 *  count is frame as gesture built it. Moved is eye or pivot moving across first build:
 *  hold of aim, since no ease runs in these gestures.
 */
async function watchRebuilt(page: Page): Promise<void> {
  await page.evaluate((given) => {
    const scope = globalThis as unknown as { nimBuildFrame: typeof nimBuildFrame };
    const built = scope.nimBuildFrame;
    window.__build_unrebuilt = built;
    window.__rebuilt_frame = [];
    const same = (a: number[], b: number[]): boolean => a.every((one, at) => one === b[at]);
    // Place each point's centre on screen by build's own transform, column-major as WebGL
    //   takes it, sorted across. Read before next build, which writes over same buffers.
    const placesOf = (data: FrameData): number[][] => {
      const [m, records] = [data.view_projection, data.point_vertices];
      const places: number[][] = [];
      for (let at = 0; at + 2 < records.length; at += given.floats) {
        const [x, y, z] = [records[at] ?? 0, records[at + 1] ?? 0, records[at + 2] ?? 0];
        const w = (m[3] ?? 0) * x + (m[7] ?? 0) * y + (m[11] ?? 0) * z + (m[15] ?? 0);
        places.push([
          ((m[0] ?? 0) * x + (m[4] ?? 0) * y + (m[8] ?? 0) * z + (m[12] ?? 0)) / w,
          ((m[1] ?? 0) * x + (m[5] ?? 0) * y + (m[9] ?? 0) * z + (m[13] ?? 0)) / w,
        ]);
      }
      return places.sort((a, b) => (a[0] ?? 0) - (b[0] ?? 0));
    };
    // Match each place of one build to unmatched place of other, within slack, one for one.
    const isSamePlaces = (a: number[][], b: number[][]): boolean => {
      if (a.length !== b.length) return false;
      const is_used = b.map(() => false);
      let from = 0;
      for (const [x = 0, y = 0] of a) {
        while (from < b.length && (b[from]?.[0] ?? 0) < x - given.slack) from += 1;
        let is_found = false;
        for (let at = from; at < b.length && (b[at]?.[0] ?? 0) <= x + given.slack; at += 1) {
          if (!is_used[at] && Math.abs((b[at]?.[1] ?? 0) - y) <= given.slack) {
            is_used[at] = true;
            is_found = true;
            break;
          }
        }
        if (!is_found) return false;
      }
      return true;
    };
    scope.nimBuildFrame = function (...asked: Parameters<typeof nimBuildFrame>): FrameData {
      const [eye, pivot] = [Array.from(nimCameraEye()), Array.from(nimCameraPivot())];
      const first = built(...asked);
      const [drawn, places] = [first.count_points, placesOf(first)];
      const is_moved = !same(eye, Array.from(nimCameraEye())) ||
        !same(pivot, Array.from(nimCameraPivot()));
      const again = built(...asked);
      window.__rebuilt_frame?.push({
        drawn, again: again.count_points, is_same: isSamePlaces(places, placesOf(again)), is_moved,
      });
      return again;
    };
  }, { floats: FLOATS_POINT, slack: SLACK_PLACE });
}

/** Put back frame build `watchRebuilt` stood in front of. */
async function unwatchRebuilt(page: Page): Promise<void> {
  await page.evaluate(() => {
    const scope = globalThis as unknown as { nimBuildFrame: typeof nimBuildFrame };
    if (window.__build_unrebuilt !== undefined) scope.nimBuildFrame = window.__build_unrebuilt;
    delete window.__build_unrebuilt;
    delete window.__rebuilt_frame;
  });
}

/** One gesture that reaches one hold of aim while camera moves: which hold, and by what. */
interface Held {
  hold: string;
  by: string;
  pick: (page: Page) => Promise<void>;
  gesture: (page: Page, devtools: CDPSession) => Promise<void>;
}

/** Pick object labelled `label` alone, as page's own pick does, with its menu shut. */
async function pickAlone(page: Page, label: string): Promise<void> {
  const handle = await handleLabelled(page, label);
  await page.evaluate((one) => { selectOnly(one, null); hideSelectionMenu(); }, handle);
}

/** Two fingers about middle of frame, spread to three times their gap. */
async function spreadAbout(page: Page, devtools: CDPSession): Promise<void> {
  const middle = await page.evaluate(() => [window.innerWidth / 2, window.innerHeight / 2]);
  const [across, down] = [middle[0] ?? 0, middle[1] ?? 0];
  const apart: [Finger, Finger] = [{ x: across - 60, y: down }, { x: across + 60, y: down }];
  for (let time = 0; time < SPREADS; time += 1) {
    await moveFingers(page, devtools, (along) => asHand(apart, 1 + 2 * along, 0, { x: 0, y: 0 }));
  }
}

/** Gestures that reach each hold, by fingers and by keys.
 *
 *  Fill is reached by key alone: where point fills frame, each finger holds its own face.
 */
const HELD: Held[] = [
  {
    hold: 'the frame floor',
    by: 'two fingers spread with a plane picked',
    pick: (page) => pickAlone(page, 'ecliptic sol'),
    gesture: spreadAbout,
  },
  {
    hold: 'the frame floor',
    by: 'the dolly key held under shift with a plane picked',
    pick: (page) => pickAlone(page, 'ecliptic sol'),
    gesture: async (page) => {
      await focusCanvas(page);
      await holdKeys(page, ['ShiftLeft', 'Equal'], MILLISECONDS_HELD);
    },
  },
  {
    hold: 'the bound of a sky point',
    by: 'an orbit key held with it picked',
    pick: async (page) => {
      const handle = await page.evaluate(
        () => nimSceneHandles().find((one) => nimObjectKindWord(one) === 'horizon point') ?? -1,
      );
      await page.evaluate((one) => { selectOnly(one, null); hideSelectionMenu(); }, handle);
    },
    gesture: async (page) => {
      await focusCanvas(page);
      await holdKeys(page, ['ArrowLeft'], MILLISECONDS_HELD);
    },
  },
  {
    hold: 'the fill of a point',
    by: 'the dolly key held under shift with it picked alone',
    pick: async (page) => {
      const handle = await handleLabelled(page, 'jupiter');
      await page.evaluate((one) => {
        const at = Array.from(nimAnchorWorld(one));
        nimPlaceCamera(
          (at[0] ?? 0) + 0.002, (at[1] ?? 0) - 0.002, (at[2] ?? 0) + 0.001,
          at[0] ?? 0, at[1] ?? 0, at[2] ?? 0,
        );
        selectOnly(one, null);
        hideSelectionMenu();
      }, handle);
    },
    gesture: async (page) => {
      await focusCanvas(page);
      await holdKeys(page, ['ShiftLeft', 'Equal'], MILLISECONDS_HELD);
    },
  },
];

/** Drive each gesture that reaches one hold of aim, and assert law over every frame of it.
 *
 *  Camera is put back after each, and after all, since checks below read sky from where cull
 *  check left it. Focus goes back too: key gestures focus canvas, and keys pressed below land
 *  on whatever holds focus.
 */
export async function driveCullHeld(page: Page, devtools: CDPSession): Promise<void> {
  const placed = await readPlaced(page);
  const focused = await page.evaluateHandle(() => document.activeElement);
  await watchRebuilt(page);
  for (const one of HELD) {
    await page.evaluate(() => clearSelection());
    await placeCamera(page, placed);
    await settleCamera(page);
    await one.pick(page);
    await settleCamera(page);
    const from = await page.evaluate(() => (window.__rebuilt_frame ?? []).length);
    await one.gesture(page, devtools);
    const frames = await page.evaluate(
      (given) => (window.__rebuilt_frame ?? []).slice(given), from,
    );
    const moved = frames.filter((frame) => frame.is_moved).length;
    const other = frames.filter((frame) => !frame.is_same);
    report(
      `each frame held at ${one.hold}, by ${one.by}, draws what a second build then draws`,
      moved >= FRAMES_MOVED_LEAST && other.length === 0,
      `${moved} of ${frames.length} frames moved by their hold; ${other.length} drew other ` +
        `points, as ${other.slice(0, 4).map((frame) => `${frame.drawn} for ${frame.again}`)
          .join(', ') || 'none'}`,
    );
  }
  await unwatchRebuilt(page);
  await page.evaluate(() => clearSelection());
  await placeCamera(page, placed);
  await settleCamera(page);
  await focused.evaluate((element) => {
    if (element instanceof HTMLElement && element !== document.body) element.focus();
    else (document.activeElement as HTMLElement | null)?.blur();
  });
  await focused.dispose();
}
