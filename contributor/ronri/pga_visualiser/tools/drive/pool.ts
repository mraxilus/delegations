// Checks for what drawer costs to keep up to date; not Nim because crossing forfeits check
//   compiler makes over bodies naming `nimPoolCellColors` and `geometry_pool_drawn` -- derived
//   or stated, never guessed.
//   Every figure diagnostics refresh writes is inside drawer, and it used to run several
//   times second regardless: milliseconds landing on one frame in twelve, against frame of
//   about one. That is what stutter is made of.

import type { Page } from '@playwright/test';
import { MILLISECONDS_FRAME, advance, evaluateOver } from './clock';
import { settleDrawer } from './gestures';
import { report } from './report';

declare global {
  interface Window {
    /** How many times pool strip has been rebuilt since counter was reset. */
    __cells?: number;
  }
}

/** Count pool-strip rebuilds, which are expensive half of drawer's own refresh. */
async function watchCells(page: Page): Promise<void> {
  await page.evaluate(() => {
    window.__cells = 0;
    const scope = globalThis as unknown as { nimPoolCellColors: typeof nimPoolCellColors };
    const original = scope.nimPoolCellColors;
    scope.nimPoolCellColors = function (): number[] {
      window.__cells = (window.__cells ?? 0) + 1;
      return original();
    };
  });
}

/** Drive drawer shut and open, and assert its refresh is gated on being read. */
export async function driveDrawerCost(page: Page): Promise<void> {
  await page.evaluate(() => {
    if (document.getElementById('drawer')?.classList.contains('open') ?? false) {
      document.getElementById('button-drawer')?.click();
    }
  });
  await watchCells(page);
  // Simulated span: figure reported is rebuilds over span of page's own time, so span is
  //   measurement rather than race.
  await advance(page, 1500);
  const shut = await page.evaluate(() => window.__cells ?? -1);
  report(
    'a shut drawer costs nothing to keep up to date',
    shut === 0, `${shut} pool-strip rebuilds over ~1.5 s with the drawer shut`,
  );

  // Section has to be opened too: tick returns at once while it is collapsed, so check that
  //   only opens drawer proves nothing about gate it names.
  await page.evaluate(() => {
    document.getElementById('button-drawer')?.click();
    document.querySelector('.section[data-section="diagnostics"]')?.classList.add('open');
    window.__cells = 0;
  });
  await advance(page, 1500); // Same window as above, and same reason.
  const open = await page.evaluate(() => window.__cells ?? -1);
  report(
    'and an open one draws the pool grid on a scene change, not on a clock',
    open <= 2, `${open} pool-grid draws over ~1.5 s with the drawer and section open`,
  );

  // Other half of same gate, and half "costs nothing" check can never fail on its own.
  const edited = await evaluateOver(page, 600 + 2 * MILLISECONDS_FRAME, async () => {
    window.__cells = 0;
    nimRemoveObject(nimSceneHandles()[0] ?? 0);
    await new Promise((done) => setTimeout(done, 600));
    return window.__cells ?? -1;
  });
  report(
    'and an edit reaches it', edited >= 1, `${edited} pool-grid draws after removing one object`,
  );
  await drivePoolGrid(page);
}

/** Assert every pool handle has cell, and every cell has pixel.
 *
 *  Strip this replaced was flex row of one span per handle with gap between: gap alone
 *  overflowed strip, so flex shrank every cell to zero and whole thing drew as gap, correctly
 *  coloured and completely invisible. Nothing caught it -- elements were all there and
 *  colours were all right. This asks two questions that would have.
 */
async function drivePoolGrid(page: Page): Promise<void> {
  const grid = await page.evaluate(() => {
    const canvas = document.getElementById('pool-grid') as HTMLCanvasElement | null;
    if (canvas === null) return null;
    // Read from draw itself rather than re-deriving here: choice of cell size is thing being
    //   checked, and check that repeats derivation agrees with itself whatever reached canvas.
    const { cell, columns, rows } = geometry_pool_drawn;
    const ratio = Math.min(window.devicePixelRatio || 1, 2.5);
    const data = canvas.getContext('2d')
      ?.getImageData(0, 0, canvas.width, canvas.height).data ?? new Uint8ClampedArray();
    let lit = 0;
    for (let i = 3; i < data.length; i += 4) if ((data[i] ?? 0) > 0) lit += 1;
    return {
      columns, rows, addressable: columns * rows, capacity: nimSceneCapacity(),
      cell_device: cell * ratio, height: Math.round(canvas.clientHeight),
      share_painted: lit / Math.max(1, canvas.width * canvas.height),
    };
  });
  report(
    'every pool slot has a cell, and every cell has a pixel',
    grid !== null && grid.addressable >= grid.capacity && grid.cell_device >= 1 &&
      grid.height > 0 && grid.share_painted > 0.5,
    grid === null ? 'no pool grid on the page'
      : `${grid.columns}x${grid.rows} cells for ${grid.capacity} handles, ` +
        `${grid.cell_device}px a side, ${grid.height}px tall, ` +
        `${(grid.share_painted * 100).toFixed(0)}% of the canvas painted`,
  );
  await page.evaluate(() => {
    if (document.getElementById('drawer')?.classList.contains('open') ?? false) {
      document.getElementById('button-drawer')?.click();
    }
  });
  await settleDrawer(page, false);
}
