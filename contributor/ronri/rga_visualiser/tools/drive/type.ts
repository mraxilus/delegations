// Checks that three faces page embeds are drawn in three roles page declares, and that
//   Commit Mono's ligatures reach reader; not Nim because what is asked is browser's own
//   resolved style and its own text measurement, which Nim reaches only through glue that
//   would leave every expression here unchecked string.
//   Declared family is not drawn face: stylesheet naming serif proves nothing where face
//   never loaded, and stack falls through per character. So each role is checked twice --
//   what page asks for, and what reader gets, measured.

import type { Page } from '@playwright/test';
import { report } from './report';

/** Two rows of sequences, one per switch Commit Mono splits its ligatures across.
 *
 *  Arrows and comparisons come from author's opt-in sets alone; rest ride on `calt`, which
 *  browsers apply unasked. Checking one row would pass while other silently drew apart.
 */
const TEXT_SETS = '=> -> <- <= >= != ===';
const TEXT_CALT = '/* */ <> && || ?? :: ...';

/** Feature settings each row is drawn under, written out rather than left to inheritance.
 *
 *  Probe sits in page, so bare `font-feature-settings` would inherit what page sets on root
 *  and compare two identical pictures -- which is exactly how first version of this check
 *  passed while proving nothing.
 */
const FEATURES_SETS = '"calt" 1, "ss01" 1, "ss02" 1';
const FEATURES_CALT = '"calt" 1, "ss01" 0, "ss02" 0';
const FEATURES_NONE = '"calt" 0, "ss01" 0, "ss02" 0';

/** Face each role is drawn in, by first family its stack names. */
const FACE_TITLE = 'Noto Serif UI';
const FACE_BODY = 'Noto Sans UI';
const FACE_CODE = 'Commit Mono UI';

/** Say first family of resolved stack, unquoted, for element selector names. */
async function familyOf(page: Page, selector: string): Promise<string> {
  return await page.evaluate((given) => {
    const element = document.querySelector(given);
    if (element === null) return '';
    const stack = window.getComputedStyle(element).fontFamily;
    return (stack.split(',')[0] ?? '').trim().replace(/^["']|["']$/g, '');
  }, selector);
}

/** Open drawer, so section heading and its count are laid out where they can be measured. */
async function openDrawer(page: Page): Promise<void> {
  await page.evaluate(() => {
    if (!drawer.classList.contains('open')) document.getElementById('button-drawer')?.click();
  });
  await page.waitForFunction(() => drawer.classList.contains('open'), null, { timeout: 10000 });
}

/** Assert every embedded face loaded, and that each of three roles resolves to its own.
 *
 *  Roles are checked on elements page builds rather than on probes, so rule is held against
 *  what reader meets: heading, body line and coefficient expression.
 */
export async function driveTypeRoles(page: Page): Promise<void> {
  await openDrawer(page);
  const loaded = await page.evaluate((faces) => faces.map(
    (face) => document.fonts.check(`13px "${face}"`),
  ), [FACE_TITLE, FACE_BODY, FACE_CODE]);
  report(
    'every face the page embeds is loaded, not merely named',
    loaded.every((is_there) => is_there),
    `${FACE_TITLE} ${loaded[0]}, ${FACE_BODY} ${loaded[1]}, ${FACE_CODE} ${loaded[2]}`,
  );

  const family_title = await familyOf(page, '.section-header');
  report(
    'a heading that names a section asks for the title face',
    family_title === FACE_TITLE, `.section-header resolves to ${family_title || 'nothing'}`,
  );
  const family_body = await familyOf(page, 'body');
  report(
    'and body text asks for the interface face',
    family_body === FACE_BODY, `body resolves to ${family_body || 'nothing'}`,
  );
  const family_count = await familyOf(page, '.objects-count');
  report(
    'and a figure inside that heading stays in the interface face rather than inheriting it',
    family_count === FACE_BODY, `.objects-count resolves to ${family_count || 'nothing'}`,
  );
  const family_tab = await familyOf(page, '.help-tab');
  report(
    'and a control that names a view is a label, not a title',
    family_tab === '' || family_tab === FACE_BODY,
    `.help-tab resolves to ${family_tab || 'no tab built yet'}`,
  );
}

/** Assert heading is drawn in title face, rather than only asking for it.
 *
 *  Asked in pixels rather than in widths, and that is second attempt worth recording: first
 *  compared heading's own width against canvas measuring same string in each face, and it was
 *  wrong twice. Heading carries `letter-spacing`, which canvas does not, so live width sat
 *  above both figures; and two faces measured `apply` at same 35.0 px anyway, so width could
 *  not have parted them even without that. Picture parts them whatever their advances.
 *  Heading is shot as page has it, then again with interface face forced onto it: same picture
 *  twice means serif never arrived and stack fell through, which is exactly failure declared
 *  family cannot see.
 */
export async function driveTypeDrawn(page: Page): Promise<void> {
  await openDrawer(page);
  const shotWith = async (family: string): Promise<Buffer> => {
    await page.evaluate((given) => {
      const heading = document.querySelector('.section-header') as HTMLElement | null;
      if (heading !== null) heading.style.fontFamily = given;
    }, family);
    return await page.locator('.section-header').first().screenshot();
  };
  try {
    const drawn = await shotWith('');
    const sans = await shotWith('var(--sans)');
    report(
      'the heading is drawn in the title face, in pixels rather than in what it asked for',
      !drawn.equals(sans),
      `${drawn.length} bytes as the page has it, ${sans.length} bytes forced to the interface face`,
    );
  } finally {
    await page.evaluate(() => {
      const heading = document.querySelector('.section-header') as HTMLElement | null;
      if (heading !== null) heading.style.fontFamily = '';
    });
  }
}

/** Draw probe in mono face under one feature setting, and say its picture and its width. */
async function probeDrawn(
  page: Page, text: string, features: string,
): Promise<{ shot: Buffer, width: number }> {
  const width = await page.evaluate(([text, given]) => {
    let probe = document.getElementById('probe-ligature');
    if (probe === null) {
      probe = document.createElement('div');
      probe.id = 'probe-ligature';
      document.body.appendChild(probe);
    }
    probe.textContent = text ?? '';
    probe.style.cssText = 'position:fixed; left:8px; top:8px; z-index:99;'
      + ' font-family: var(--mono); font-size: 28px; color: #fff; background: #000;'
      + ` padding: 4px; white-space: pre; font-feature-settings: ${given ?? 'normal'};`;
    return probe.getBoundingClientRect().width;
  }, [text, features]);
  return { shot: await page.locator('#probe-ligature').screenshot(), width };
}

/** Assert both halves of Commit Mono's ligatures reach reader, and that they cost no column.
 *
 *  Face splits them: `calt` carries most and is on unasked, while arrows and comparisons come
 *  from `ss01` and `ss02`, which are opt-in. Page asks for sets and protects `calt`, so both
 *  are checked -- arrow row against sets, and everything-off against `calt` alone, which is
 *  what would break where reset wrote `font-variant-ligatures: none` for crispness.
 *  Read in pixels, since monospace ligature keeps its columns by design and no width moves.
 */
export async function driveTypeLigatures(page: Page): Promise<void> {
  try {
    const sets = await probeDrawn(page, TEXT_SETS, FEATURES_SETS);
    const calt = await probeDrawn(page, TEXT_SETS, FEATURES_CALT);
    report(
      "the arrows and comparisons draw joined, which is Commit Mono's own opt-in sets",
      !sets.shot.equals(calt.shot),
      `\`${TEXT_SETS}\` drew ${sets.shot.length} bytes under ${FEATURES_SETS}`
        + ` and ${calt.shot.length} bytes with the sets off`,
    );
    const alive = await probeDrawn(page, TEXT_CALT, FEATURES_CALT);
    const dead = await probeDrawn(page, TEXT_CALT, FEATURES_NONE);
    report(
      'and the ligatures that ride on the default feature are still alive, not reset away',
      !alive.shot.equals(dead.shot),
      `\`${TEXT_CALT}\` drew ${alive.shot.length} bytes with \`calt\``
        + ` and ${dead.shot.length} bytes without it`,
    );
    report(
      'and no ligature costs a column, so mono text still lines up',
      Math.abs(sets.width - calt.width) < 0.5 && Math.abs(alive.width - dead.width) < 0.5,
      `${sets.width.toFixed(1)} px against ${calt.width.toFixed(1)} px, and`
        + ` ${alive.width.toFixed(1)} px against ${dead.width.toFixed(1)} px`,
    );
  } finally {
    await page.evaluate(() => { document.getElementById('probe-ligature')?.remove(); });
  }
}
