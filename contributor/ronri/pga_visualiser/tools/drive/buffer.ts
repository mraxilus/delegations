// Check page draws across its whole drawing buffer where GL limits its viewport; not Nim
//   because what is under check is browser's own buffer and viewport, which only browser holds.
//   Limit is stood in for: script put in before page's own caps viewport as GL does at
//   `MAX_VIEWPORT_DIMS`, and reports that cap. Chromium cuts every buffer to its own limit, so
//   stand-in sets one below buffer page would ask for, as Firefox of #725 did at 4,096.
//   Page of its own runs on simulated clock, as every correctness check does.

import type { Browser } from '@playwright/test';
import { advanceFrames, simulateClock, waitUntil } from './clock';
import { report } from './report';

/** Page's size in CSS pixels, at which `RATIO_DEVICE` asks for 4000 by 1750 buffer. */
const SIZE_PAGE = { width: 1600, height: 700 };
/** Device pixel ratio, page's own cap. */
const RATIO_DEVICE = 2.5;
/** Viewport limit stood in for, below width of buffer page would ask for uncapped. */
const LIMIT_VIEWPORT = 3300;

/** What page's canvas, buffer and viewport measure: canvas in CSS pixels, rest in pixels. */
interface Measures {
  width_canvas: number;
  height_canvas: number;
  width_buffer: number;
  height_buffer: number;
  width_viewport: number;
  height_viewport: number;
}

/** Open page afresh in `browser`, under viewport limit stood in before its own script runs. */
export async function driveBufferCovered(browser: Browser, url: string): Promise<void> {
  const page = await browser.newPage({ viewport: SIZE_PAGE, deviceScaleFactor: RATIO_DEVICE });
  const errors: string[] = [];
  page.on('pageerror', (error) => errors.push(error.message));
  await simulateClock(page);
  await page.addInitScript((limit) => {
    const kinds: { prototype: WebGLRenderingContextBase }[] = [WebGLRenderingContext];
    if (typeof WebGL2RenderingContext === 'function') kinds.push(WebGL2RenderingContext);
    for (const { prototype } of kinds) {
      const viewport = prototype.viewport;
      const getParameter = prototype.getParameter;
      prototype.viewport = function (
        this: WebGLRenderingContextBase, x: number, y: number, width: number, height: number,
      ): void {
        viewport.call(this, x, y, Math.min(width, limit), Math.min(height, limit));
      };
      prototype.getParameter = function (this: WebGLRenderingContextBase, name: number): unknown {
        if (name === this.MAX_VIEWPORT_DIMS) return new Int32Array([limit, limit]);
        return getParameter.call(this, name);
      };
    }
  }, LIMIT_VIEWPORT);
  await page.goto(url);
  await waitUntil(page, () => typeof nimSceneCount === 'function' && nimSceneCount() > 0, null);
  await advanceFrames(page, 2);
  const measures = await page.evaluate((): Measures | null => {
    const canvas = document.getElementById('gl') as HTMLCanvasElement | null;
    const context = canvas?.getContext('webgl') ?? null;
    if (canvas === null || context === null) return null;
    const viewport = context.getParameter(context.VIEWPORT) as Int32Array;
    return {
      width_canvas: canvas.clientWidth, height_canvas: canvas.clientHeight,
      width_buffer: context.drawingBufferWidth, height_buffer: context.drawingBufferHeight,
      width_viewport: viewport[2] ?? 0, height_viewport: viewport[3] ?? 0,
    };
  });
  const said = measures === null ? 'no canvas or context' :
    `buffer ${measures.width_buffer} by ${measures.height_buffer}, viewport ` +
    `${measures.width_viewport} by ${measures.height_viewport}, limit ${LIMIT_VIEWPORT}`;

  report(
    'under a viewport limit below the buffer it would ask for, the page draws across its ' +
      'whole drawing buffer',
    measures !== null && measures.width_viewport === measures.width_buffer &&
      measures.height_viewport === measures.height_buffer,
    said,
  );
  // Buffer stretches to canvas, so shape other than canvas's draws every pixel oblong; and one
  //   smaller than limit allows throws away detail limit would keep.
  const width_shaped = measures === null ? 0 :
    Math.round(measures.height_buffer * measures.width_canvas / measures.height_canvas);
  report(
    'and that buffer keeps the shape of the canvas, as wide as the limit lets it be',
    measures !== null && Math.abs(measures.width_buffer - width_shaped) <= 1 &&
      measures.width_buffer === LIMIT_VIEWPORT,
    measures === null ? said :
      `${said}, canvas ${measures.width_canvas} by ${measures.height_canvas} CSS pixels`,
  );
  report(
    'the page under a viewport limit raised no error', errors.length === 0, errors.join(' | '),
  );
  await page.close();
}
