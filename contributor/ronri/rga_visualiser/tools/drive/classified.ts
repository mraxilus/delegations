// Check that one frame classifies each live object once, its overlay included; not Nim because
//   crossing forfeits check compiler makes over bodies wrapping `nimBuildFrame` and page's own
//   `updateSelectionMenuPosition`, and naming `nimCountKinds` -- signatures `declare` derives
//   and `page.d.ts` states.
//   Every frame build places every live object once, and each reader of that frame reads its
//   placement. So classifications one frame makes are live count, and each reader that asks
//   multivector again reads over it.
//   Count rather than time: count reads same on every machine, and load never moves it.

import type { Page } from '@playwright/test';
import { settleCamera } from './camera';
import { advanceFrames } from './clock';
import { clearTheGlass } from './gestures';
import { report } from './report';

/** Frames each state is counted over; more than one, so steady state is what is read. */
const FRAMES_CLASSIFIED = 3;

/** Kinds one object is picked alone as, each in turn, wherever scene holds one. */
const KINDS_CLASSIFIED = [
  'point', 'horizon point', 'line', 'horizon line', 'plane', 'horizon plane',
];

/** Word bridge names multivector with no geometry by; such object draws no marker. */
const WORD_NOTHING = 'mixed grade, nothing to draw';

/** Places left drag may start from, tried in turn until one stands over nothing to drag. */
const STARTS_ORBIT: Array<[number, number]> = [
  [0.5, 0.08], [0.08, 0.5], [0.92, 0.5], [0.5, 0.92], [0.15, 0.15], [0.85, 0.85],
];

/** Pixels pointer travels across for each frame of orbit. */
const PIXELS_STEP_ORBIT = 40;

/** One state's classifications for each frame counted, beside markers its overlay shaped. */
interface Counted {
  state: string;
  kinds: number[];
  shaped: number[];
  shaped_least: number;
}

declare global {
  interface Window {
    /** Classifications each counted frame made, from its build to its menu's placing. */
    __kinds_frame?: number[];
    /** Markers each counted frame shaped, over same window. */
    __shaped_frame?: number[];
    /** Page's own frame build, held while counting wrapper stands in front of it. */
    __build_classified?: typeof nimBuildFrame;
    /** Page's own menu placing, held while counting wrapper stands in front of it. */
    __menu_classified?: typeof updateSelectionMenuPosition;
  }
}

/** Read frames counted since last read, emptying both lists. */
async function readCounted(page: Page, state: string, shaped_least: number): Promise<Counted> {
  const read = await page.evaluate(() => ({
    kinds: window.__kinds_frame?.splice(0) ?? [],
    shaped: window.__shaped_frame?.splice(0) ?? [],
  }));
  return { state, kinds: read.kinds, shaped: read.shaped, shaped_least };
}

/** Count frames in state page stands in now, from empty lists. */
async function countFrames(page: Page, state: string, shaped_least: number): Promise<Counted> {
  await page.evaluate(() => {
    window.__kinds_frame = [];
    window.__shaped_frame = [];
  });
  await advanceFrames(page, FRAMES_CLASSIFIED);
  return readCounted(page, state, shaped_least);
}

/** Assert one frame classifies each live object once, overlay included, in every state.
 *
 *  As found (repository issue 556): page's overlay asked bridge for each selected object's
 *  marker, label and anchor from its multivector, and each call classified it and found its
 *  anchor again, though frame's placement held both. Aim and lattice of frame walked selection
 *  same way, so every object selected cost frame several classifications more for each.
 *  Domain: largest demo with nothing selected, one object of each kind selected alone, and
 *  every object selected; pointer hovering object; and left drag orbiting about selection.
 *  Hover pick that names hovered object is counted alone, and reads frame's placements, so it
 *  classifies nothing; desktop runs it in every frame.
 *  Window opens as frame build starts, and closes as overlay places selection menu, last of
 *  what frame loop draws: one frame's build, its overlay, and menu that follows selection.
 *  Markers shaped in same window are counted beside it, so overlay that drew nothing cannot
 *  pass for one that drew once.
 */
export async function driveClassifiedOnce(page: Page): Promise<void> {
  await clearTheGlass(page);
  await page.evaluate(() => {
    const scope = globalThis as unknown as {
      nimBuildFrame: typeof nimBuildFrame;
      updateSelectionMenuPosition: typeof updateSelectionMenuPosition;
    };
    const build = scope.nimBuildFrame;
    const menu = scope.updateSelectionMenuPosition;
    window.__build_classified = build;
    window.__menu_classified = menu;
    window.__kinds_frame = [];
    window.__shaped_frame = [];
    scope.nimBuildFrame = function (...given: Parameters<typeof nimBuildFrame>): FrameData {
      nimSetCountingKinds(true);
      nimSetCountingShaped(true);
      return build(...given);
    };
    scope.updateSelectionMenuPosition = function (): void {
      menu();
      window.__kinds_frame?.push(nimCountKinds());
      window.__shaped_frame?.push(nimCountShaped());
      nimSetCountingKinds(false);
      nimSetCountingShaped(false);
    };
  });
  const live = await page.evaluate(() => nimSceneCount());
  const counted: Counted[] = [];
  const missing: string[] = [];
  let kinds_pick = -1;

  counted.push(await countFrames(page, 'nothing selected', 0));

  // One object of each kind alone, with menu standing beside it as pick leaves it.
  for (const kind of KINDS_CLASSIFIED) {
    const handle = await page.evaluate(
      (word) => nimSceneHandles().find((one) => nimObjectKindWord(one) === word) ?? -1, kind,
    );
    if (handle < 0) {
      missing.push(kind);
      continue;
    }
    await page.evaluate((one) => selectOnly(one, null), handle);
    counted.push(await countFrames(page, `one ${kind} selected`, 1));
  }

  // Every object at once, each with marker, pulse and label of its own.
  const drawable = await page.evaluate((word) => {
    nimSelectClear();
    nimSelectAddAll(nimSceneHandles());
    refreshSelectionSnapshot();
    return nimSceneHandles().filter((one) => nimObjectKindWord(one) !== word).length;
  }, WORD_NOTHING);
  counted.push(await countFrames(page, 'every object selected', drawable));

  // Pointer resting on point standing in view, which overlay marks as hovered.
  await clearTheGlass(page);
  const rect = await page.evaluate(() => {
    const box = (document.getElementById('gl') as HTMLElement).getBoundingClientRect();
    return { left: box.left, top: box.top, width: box.width, height: box.height };
  });
  const over = await page.evaluate((box) => {
    for (const one of nimSceneHandles()) {
      if (nimObjectKindWord(one) !== 'point') continue;
      const at = Array.from(nimAnchorScreen(one, box.width, box.height));
      const [x, y, in_front] = [at[0] ?? -1, at[1] ?? -1, at[2] ?? 0];
      if (in_front > 0.5 && x > 0.2 * box.width && x < 0.8 * box.width &&
          y > 0.2 * box.height && y < 0.8 * box.height) return { x, y };
    }
    return null;
  }, rect);
  if (over === null) missing.push('point in view to hover');
  else {
    // Pick where pointer stands, as press does: page's loop picks again only once something
    //   marks hover stale. Pick reads frame's placements, so it classifies nothing at all.
    await page.mouse.move(rect.left + over.x, rect.top + over.y);
    const hovered = await page.evaluate((box) => {
      nimSetCountingKinds(true);
      nimUpdateHover(box.width, box.height);
      const kinds = nimCountKinds();
      nimSetCountingKinds(false);
      return { handle: nimHoverHandle(), kinds };
    }, rect);
    kinds_pick = hovered.kinds;
    if (hovered.handle < 0) missing.push('hover over point in view');
    else counted.push(await countFrames(page, 'object hovered', 1));
  }

  // Left drag from glass over nothing to drag, orbiting about one point selected alone.
  const point = await page.evaluate(
    () => nimSceneHandles().find((one) => nimObjectKindWord(one) === 'point') ?? -1,
  );
  let start: [number, number] | null = null;
  if (point >= 0) {
    await page.evaluate((one) => {
      selectOnly(one, null);
      hideSelectionMenu();
    }, point);
    await settleCamera(page);
    for (const [share_x, share_y] of STARTS_ORBIT) {
      await page.mouse.move(rect.left + share_x * rect.width, rect.top + share_y * rect.height);
      const is_bare = await page.evaluate((box) => {
        nimUpdateHover(box.width, box.height);
        return nimHoverHandle() < 0 || nimIsHoverBackdrop();
      }, rect);
      if (is_bare) {
        start = [rect.left + share_x * rect.width, rect.top + share_y * rect.height];
        break;
      }
    }
  }
  if (start === null) missing.push('bare glass to orbit from');
  else {
    const before = await page.evaluate(() => nimCameraAzimuth());
    await page.evaluate(() => {
      window.__kinds_frame = [];
      window.__shaped_frame = [];
    });
    await page.mouse.down();
    for (let step = 1; step <= FRAMES_CLASSIFIED; step += 1) {
      await page.mouse.move(start[0] + PIXELS_STEP_ORBIT * step, start[1], { steps: 2 });
      await advanceFrames(page, 1);
    }
    const orbit = await readCounted(page, 'left drag orbiting', 1);
    await page.mouse.up();
    const after = await page.evaluate(() => nimCameraAzimuth());
    const is_dragging = await page.evaluate(() => nimDragActive());
    if (Math.abs(after - before) <= 1e-6 || is_dragging) missing.push('orbit that turned view');
    else counted.push(orbit);
  }

  await page.evaluate(() => {
    const scope = globalThis as unknown as {
      nimBuildFrame: typeof nimBuildFrame;
      updateSelectionMenuPosition: typeof updateSelectionMenuPosition;
    };
    if (window.__build_classified !== undefined) scope.nimBuildFrame = window.__build_classified;
    if (window.__menu_classified !== undefined) {
      scope.updateSelectionMenuPosition = window.__menu_classified;
    }
    nimSetCountingKinds(false);
    nimSetCountingShaped(false);
  });
  await clearTheGlass(page);
  await page.keyboard.press('Home');
  await settleCamera(page);

  const isOnce = (one: Counted): boolean =>
    one.kinds.length >= FRAMES_CLASSIFIED && one.kinds.every((kinds) => kinds === live) &&
    one.shaped.length === one.kinds.length &&
    one.shaped.every((shaped) => shaped >= one.shaped_least);
  report(
    'a frame classifies each live object once, overlay included, whatever is picked or moving',
    missing.length === 0 && counted.every(isOnce) && kinds_pick === 0,
    `${live} live; ` +
      counted.map((one) => `${one.state} [${one.kinds.join(', ')}]` +
        ` shaping [${one.shaped.join(', ')}]`).join('; ') +
      `; hover pick ${kinds_pick}` +
      (missing.length > 0 ? `; no ${missing.join(', no ')}` : ''),
  );
}
