// Check page draws through WebGL2 where browser offers it, and through WebGL1 where it does not;
//   not Nim because what is under check is which context browser grants, which only browser
//   holds.
//   Browser without WebGL2, and WebGL1 without `EXT_frag_depth`, are stood in for: script put in
//   before page's own refuses each. Phone of #743 offered WebGL1 without that extension.
//   Each page of its own runs on simulated clock without multisampling, as every correctness
//   check does, and is read once its picture stands still, so two paths that draw alike give
//   one reading.

import type { Browser } from '@playwright/test';
import { settleCanvas, type Reading } from './canvas';
import { advance, simulateClock, waitUntil } from './clock';
import { report } from './report';

/** What stood-in browser refuses page. */
interface Refusal {
  is_two_refused: boolean;
  is_depth_refused: boolean;
}

/** Context page drew through, what it showed, and what it raised. */
interface Drawn {
  kind: string;
  reading: Reading;
  errors: string[];
}

/** Simulated span opening scene takes to stand still, from its first frame. */
const MILLISECONDS_OPENING = 2000;

/** Context call, as stand-in replaces it. */
type ContextCall = (this: HTMLCanvasElement, kind: string, options?: unknown) => unknown;
/** Extension call, as stand-in replaces it. */
type ExtensionCall = (this: WebGLRenderingContext, name: string) => unknown;

/** Open page afresh under `refusal`, and read what it drew through and what it showed. */
async function drawnUnder(
  browser: Browser, url: string, size: { width: number; height: number }, refusal: Refusal,
): Promise<Drawn> {
  const page = await browser.newPage({ viewport: size });
  const errors: string[] = [];
  page.on('pageerror', (error) => errors.push(error.message));
  await simulateClock(page);
  await page.addInitScript((given) => {
    window.should_antialias = false;
    if (given.is_two_refused) {
      const holder = HTMLCanvasElement.prototype as unknown as { getContext: ContextCall };
      const context = holder.getContext;
      holder.getContext = function (kind, options) {
        return kind === 'webgl2' ? null : context.call(this, kind, options);
      };
    }
    if (given.is_depth_refused) {
      const holder = WebGLRenderingContext.prototype as unknown as { getExtension: ExtensionCall };
      const extension = holder.getExtension;
      holder.getExtension = function (name) {
        return name === 'EXT_frag_depth' ? null : extension.call(this, name);
      };
    }
  }, refusal);
  await page.goto(url);
  await waitUntil(page, () => typeof nimSceneCount === 'function' && nimSceneCount() > 0, null);
  await advance(page, MILLISECONDS_OPENING);
  const kind = await page.evaluate(() => {
    const canvas = document.getElementById('gl') as HTMLCanvasElement | null;
    if (canvas === null) return 'no canvas';
    if (canvas.getContext('webgl2') !== null) return 'WebGL2';
    return canvas.getContext('webgl') === null ? 'no context' : 'WebGL1';
  });
  const reading = await settleCanvas(page);
  await page.close();
  return { kind, reading, errors };
}

/** Draw page through each path browser may offer it, and compare what each showed. */
export async function driveContextPaths(
  browser: Browser, url: string, size: { width: number; height: number },
): Promise<void> {
  const two = await drawnUnder(
    browser, url, size, { is_two_refused: false, is_depth_refused: false });
  const one = await drawnUnder(
    browser, url, size, { is_two_refused: true, is_depth_refused: false });
  const bare = await drawnUnder(
    browser, url, size, { is_two_refused: true, is_depth_refused: true });
  const said = (drawn: Drawn): string => `${drawn.kind}, mark ${drawn.reading.mark}`;

  report('where the browser offers WebGL2, the page draws through it', two.kind === 'WebGL2',
    `drew through ${said(two)}`);
  report(
    'where it offers WebGL1 alone, the page draws through that, the picture WebGL2 draws',
    one.kind === 'WebGL1' && one.reading.mark === two.reading.mark,
    `WebGL1 path ${said(one)}, WebGL2 path ${said(two)}`,
  );
  report(
    'where WebGL1 lacks per-fragment depth, the page still draws, a picture of its own',
    bare.kind === 'WebGL1' && bare.reading.mark !== one.reading.mark,
    `that path ${said(bare)}, with per-fragment depth ${said(one)}`,
  );
  const errors = [...two.errors, ...one.errors, ...bare.errors];
  report('no path raised an error', errors.length === 0, errors.join(' | '));
}
