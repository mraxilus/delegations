// Check that every declaration page's own stylesheet makes is one browser understands; not Nim
//   because only browser knows what CSS it supports, and asking it is whole point -- no list
//   kept here can be as right as `CSS.supports`, and list that drifts is worse than none.
//   Written after repository-wide rename of word `item` to `object` turned all thirteen
//   `align-items` into `align-objects`, which is not property at all. Parser drops unknown
//   declaration in silence, so nothing centred vertically anywhere in drawer for five days and
//   no check, review or build said one word about it.

import type { Page } from '@playwright/test';
import { report } from './report';

/** Floor on how many declarations sweep has to find before its verdict means anything.
 *
 *  Page authors well over four hundred. Number sits far below that rather than near it: this
 *  guards against sweep reading nothing, not against stylesheet shrinking.
 *  First run of this check reported "none unknown" out of **none read**, which is verdict any
 *  page at all would have earned.
 */
const DECLARATIONS_LEAST = 300;

/** Assert page declares no property browser does not know, and no value it will not take.
 *
 *  **Authored text is read, not `cssRules`.** Parser discards declaration whose property it
 *  does not know, so model it builds cannot be asked what it threw away -- sweep over
 *  `cssRules` passes on very page this check exists for, and this one did until it was run
 *  against that page. `<style>`'s own `textContent` is what author wrote, dropped and all.
 *  Blocks of `@font-face` are skipped: `src`, `font-display` and `unicode-range` are
 *  descriptors rather than properties, and `CSS.supports` knows only properties. Custom
 *  properties are skipped for opposite reason -- they take any value by design.
 *  Value carrying `var()` is passed as `inherit` instead: substitution happens after parsing,
 *  so `CSS.supports` refuses every such value whatever property it is on. Property's name is
 *  still put to browser, which is half this bug was.
 *  Vendor-prefixed property is asked about under plain name too: browser serves
 *  `-webkit-backdrop-filter` as alias it does not expose to `CSS.supports`, and prefixed
 *  fallback beside plain one is deliberate rather than typo.
 */
export async function driveStyleDeclared(page: Page): Promise<void> {
  const found = await page.evaluate((least) => {
    const sheet = document.querySelector('style');
    const source = (sheet?.textContent ?? '').replace(/\/\*[\s\S]*?\*\//g, '');
    const unknown: string[] = [];
    let declared = 0;
    // Walk text rather than split it: `url(data:font/woff2;base64,...)` carries semicolons of
    //   its own, so only semicolon outside every bracket ends declaration.
    let prelude = '';
    let piece = '';
    let depth = 0;
    const blocks: string[] = [];
    const take = (): void => {
      const text = piece.trim();
      piece = '';
      const at = text.indexOf(':');
      if (at < 0 || depth === 0) return;
      if (blocks[blocks.length - 1]?.startsWith('@font-face') ?? false) return;
      const name = text.slice(0, at).trim();
      // Property's name is identifier and nothing else. Guard is against prose, not against
      //   typos: comment carrying `*/` of its own ends early, and tail of it then reads as
      //   declaration with colon in it.
      if (!/^-?[a-zA-Z][-a-zA-Z0-9]*$/.test(name)) return;
      if (name.startsWith('--')) return;
      const written = text.slice(at + 1).trim().replace(/\s*!important$/, '');
      const value = written.includes('var(') ? 'inherit' : written;
      declared += 1;
      // Vendor prefix is asked about under its own name and under plain one. `CSS.supports`
      //   answers for properties browser exposes, and it serves `-webkit-backdrop-filter` as
      //   alias it does not expose -- prefixed fallback is deliberate, not typo.
      const plain = name.replace(/^-(?:webkit|moz|ms|o)-/, '');
      if (!CSS.supports(name, value) && !CSS.supports(plain, value)) {
        unknown.push(`${name}: ${written}`);
      }
    };
    let brackets = 0;
    for (const letter of source) {
      if (letter === '(') brackets += 1;
      else if (letter === ')') brackets -= 1;
      if (brackets > 0) { piece += letter; continue; }
      if (letter === '{') {
        blocks.push(prelude.trim());
        prelude = '';
        piece = '';
        depth += 1;
        continue;
      }
      if (letter === '}') { take(); blocks.pop(); depth -= 1; continue; }
      if (letter === ';') { take(); continue; }
      piece += letter;
      if (depth === 0) prelude += letter;
    }
    return {
      declared,
      unknown,
      is_read: declared > least,
      // Predicate answering `true` to everything passes report above on any page at all, so
      //   check asks browser outright whether it can still tell two spellings apart.
      is_telling:
        CSS.supports('align-items', 'center') && !CSS.supports('align-objects', 'center'),
    };
  }, DECLARATIONS_LEAST);
  report(
    'every declaration the page makes is one the browser understands',
    found.unknown.length === 0 && found.is_read,
    `${found.declared} declarations read`
      + (found.unknown.length === 0 ? ', none unknown'
        : `, ${found.unknown.length} unknown: ${found.unknown.slice(0, 6).join('; ')}`),
  );
  report(
    'and it can tell them apart, since the spelling a rename produced is refused',
    found.is_telling,
    'align-items is accepted where align-objects is refused',
  );
}
