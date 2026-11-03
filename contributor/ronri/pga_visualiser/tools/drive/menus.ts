// Check selection menu opens where both front-ends open it; not Nim because it presses real keys
//   and drags real pointer through Playwright, whose API exists only in node.
//   Suite holds `interaction.pointMenuHung` alone; this holds page's wiring to it, as desktop's
//   `--drive-keys` and `--drive-drag` hold their own.

import type { Page } from '@playwright/test';
import { waitUntil } from './clock';
import { settleCamera } from './camera';
import { type CopyNim, waitFrames } from './frame';
import { focusCanvas, settleSelection } from './gestures';
import { report } from './report';

/** Read selection menu's box against canvas, as left, top, width and height in its pixels. */
async function boxMenu(page: Page): Promise<number[]> {
  return page.evaluate(() => {
    const canvas = document.getElementById('gl');
    const menu = document.getElementById('selection-menu');
    if (canvas === null || menu === null) return [Number.NaN, Number.NaN, 0, 0];
    const [on, box] = [canvas.getBoundingClientRect(), menu.getBoundingClientRect()];
    return [box.left - on.left, box.top - on.top, box.width, box.height];
  });
}

/** Find two points in view, in page's own pixels, far enough apart for drag to cross.
 *
 *  By kind rather than label: checks before this delete `a` and `b`.
 */
async function pointsApart(page: Page): Promise<{ x: number; y: number }[]> {
  return page.evaluate(() => {
    const canvas = document.getElementById('gl') as HTMLCanvasElement;
    const on = canvas.getBoundingClientRect();
    const [width, height] = [canvas.clientWidth, canvas.clientHeight];
    const found: { x: number; y: number }[] = [];
    for (const one of Array.from(nimSceneHandles())) {
      if (nimObjectKindWord(one) !== 'point') continue;
      const at = nimAnchorScreen(one, width, height);
      const [x, y] = [on.left + (at[0] ?? 0), on.top + (at[1] ?? 0)];
      const is_inside = x > on.left + 60 && y > on.top + 60 && x < on.left + width - 60 &&
        y < on.top + height - 60;
      if ((at[2] ?? 0) <= 0.5 || !is_inside) continue;
      const first = found[0];
      if (first !== undefined && Math.hypot(x - first.x, y - first.y) < 80) continue;
      found.push({ x, y });
      if (found.length === 2) break;
    }
    return found;
  });
}

/** Put camera back where it opened, with nothing selected and canvas holding keyboard. */
async function fromHome(page: Page): Promise<void> {
  await focusCanvas(page);
  await page.keyboard.press('Home');
  await settleCamera(page);
  await page.evaluate(() => clearSelection());
}

/** Leave page as checks after these find it: nothing picked, and camera still at home.
 *
 *  Pick eases camera onto what it picked, and demo after these loads against camera home.
 */
async function toHome(page: Page): Promise<void> {
  await page.evaluate(() => clearSelection());
  await fromHome(page);
}

/** Drive menu that keyboard opens, with no pointer: it hangs by bottom middle at core's point. */
export async function driveMenuHung(page: Page): Promise<void> {
  await fromHome(page);
  await page.keyboard.press('BracketRight');
  await page.keyboard.press('Enter');
  await settleSelection(page, 1);
  await waitFrames(page, 3);
  const [left, top, wide, tall] = await boxMenu(page);
  const hung = await page.evaluate((menu) => {
    const canvas = document.getElementById('gl') as HTMLCanvasElement;
    const [width, height] = [canvas.clientWidth, canvas.clientHeight];
    const handles = Array.from(nimSelectionHandles());
    const anchor = nimAnchorScreen(handles[handles.length - 1] ?? 0, width, height);
    return Array.from(
      nimMenuHung(anchor[0] ?? 0, anchor[1] ?? 0, width, height, menu.wide, menu.tall),
    );
  }, { wide: wide ?? 0, tall: tall ?? 0 });
  const [middle, bottom] = [(left ?? 0) + (wide ?? 0) / 2, (top ?? 0) + (tall ?? 0)];
  const [x, y] = [hung[0] ?? Number.NaN, hung[1] ?? Number.NaN];
  report(
    'a menu opened with no pointer hangs centred above its object',
    Math.abs(middle - x) < 1 && Math.abs(bottom - y) < 1,
    `bottom middle at (${middle.toFixed(1)}, ${bottom.toFixed(1)}), point hung from ` +
      `(${x.toFixed(1)}, ${y.toFixed(1)})`,
  );
  await toHome(page);
}

/** Anchors hang is driven from, as fractions of canvas on each axis: past, near and between
 *  edges, so each bound of its clamp holds some of them.
 */
const FRACTIONS_ANCHOR = [-0.25, 0.01, 0.5, 0.99, 1.25];

/** Menu sizes hang is driven with, as fractions of canvas: one small, one larger than view. */
const FRACTIONS_MENU = [0.1, 1.5];

/** Drive hang from every anchor and size above, and assert it copies no value.
 *
 *  Page hangs menu again every frame it shows, so one copy in hang is one copy per frame.
 *  JS backend deep-copies through `nimCopy`; outermost call alone counted, as
 *  `driveCopiesStill` counts it. Here, not in suite: suite compiles to C, which makes no such copy.
 */
export async function driveMenuHungCopies(page: Page): Promise<void> {
  const counted = await page.evaluate(({ anchors, menus }) => {
    const scope = globalThis as unknown as { nimCopy?: CopyNim };
    const unwrapped = scope.nimCopy;
    if (typeof unwrapped !== 'function') return null;
    const canvas = document.getElementById('gl') as HTMLCanvasElement;
    const [width, height] = [canvas.clientWidth, canvas.clientHeight];
    let [copies, hangs, depth] = [0, 0, 0];
    scope.nimCopy = function (destination: unknown, source: unknown, type: unknown): unknown {
      if (depth === 0) copies += 1;
      depth += 1;
      try {
        return unwrapped(destination, source, type);
      } finally {
        depth -= 1;
      }
    };
    try {
      for (const across of anchors) {
        for (const down of anchors) {
          for (const size of menus) {
            nimMenuHung(across * width, down * height, width, height, size * width, size * height);
            hangs += 1;
          }
        }
      }
    } finally {
      scope.nimCopy = unwrapped;
    }
    return { copies, hangs };
  }, { anchors: FRACTIONS_ANCHOR, menus: FRACTIONS_MENU });
  report(
    'hanging the selection menu copies no value, wherever it hangs',
    counted !== null && counted.copies === 0,
    counted === null
      ? 'page holds no `nimCopy` to count'
      : `${counted.copies} copies over ${counted.hangs} hangs`,
  );
}

/** Drive right drag from one object onto another and out onto `more…`: picker opens beside
 *  pointer that chose it, as desktop's opens.
 */
export async function driveMoreAtPointer(page: Page): Promise<void> {
  await fromHome(page);
  const [from, onto] = await pointsApart(page);
  if (from === undefined || onto === undefined) {
    report('more… opens the operation picker beside the pointer that chose it', false,
      'no two points stood apart in view');
    return;
  }
  // Right button asks from moment drag arrives over its target, so wheel is open by then.
  await page.mouse.move(from.x, from.y);
  await page.mouse.down({ button: 'right' });
  for (let step = 1; step <= 6; step += 1) {
    await page.mouse.move(
      from.x + ((onto.x - from.x) * step) / 6, from.y + ((onto.y - from.y) * step) / 6,
    );
    await waitFrames(page, 2);
  }
  await waitUntil(page, () => nimDragMenuOpen(), null).catch(() => undefined);
  // `more…` is last of `interaction.DragChoice`, so last wedge of layout bridge reports.
  const wedge = await page.evaluate(() => {
    const canvas = document.getElementById('gl') as HTMLCanvasElement;
    const on = canvas.getBoundingClientRect();
    const layout = nimDragMenuLayout();
    const [x, y] = [layout[layout.length - 3] ?? 0, layout[layout.length - 2] ?? 0];
    return { x, y, page_x: on.left + x, page_y: on.top + y };
  });
  await page.mouse.move(wedge.page_x, wedge.page_y);
  await waitFrames(page, 2);
  await page.mouse.up({ button: 'right' });
  // Read before any frame: release places menu, and later frames carry it with its object
  //   while camera eases onto pair, as they carry every menu pointer placed.
  const inset = await page.evaluate(() => nimInsetMenuPointer());
  const is_picking = await page.evaluate(
    () => document.getElementById('selection-menu-reveal')?.classList.contains('open') ?? false);
  const [left, top] = await boxMenu(page);
  const [wanted_x, wanted_y] = [wedge.x + inset, wedge.y + inset];
  report(
    'more… opens the operation picker beside the pointer that chose it',
    is_picking && Math.abs((left ?? 0) - wanted_x) < 1 && Math.abs((top ?? 0) - wanted_y) < 1,
    `picker open ${is_picking}, corner at (${(left ?? 0).toFixed(1)}, ${(top ?? 0).toFixed(1)}), ` +
      `pointer and inset at (${wanted_x.toFixed(1)}, ${wanted_y.toFixed(1)})`,
  );
  await waitFrames(page, 3);
  await toHome(page);
}
