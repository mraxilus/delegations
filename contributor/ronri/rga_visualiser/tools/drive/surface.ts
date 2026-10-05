// Check that no surface over scene blurs what lies behind it, and that each fills at one alpha;
//   not Nim because stylesheet's rules and computed style are browser's own, and Nim reaches
//   them only through glue that would leave every expression here unchecked string.
//   Scene shows through each surface by its fill alone, by Architect's instruction. Blur cost
//   one frame of display over largest scene; `PROVENANCE.md`, Browser front-end, keeps reading.

import type { Page } from '@playwright/test';
import { alphaOfFill } from './objects';
import { report } from './report';

/** Alpha every surface over scene fills at; mirrors `--surface` in `pages/shell.html`. */
const ALPHA_SURFACE = 0.88;

/** Distance alpha may stand from `ALPHA_SURFACE`: half of one byte, as fill is stored. */
const ALPHA_SLACK = 0.5 / 255;

/** Every surface over scene that fills with `--surface`; mirrors `pages/shell.html`. */
const SURFACES = ['.brand', '.toggles', '.help-open', '.drawer'];

/** Opaque bands of drawer, which mix `--surface` over `--bg` so rows passing under them hide. */
const BANDS = ['.section-header', '.objects-search'];

/** Clear colour bands are read over, for that reading alone.
 *
 *  Page's own clear colour sits so near tone of `--surface` that mix of any weight paints
 *  within one level of drawer's ground. Over white, one percent of weight moves red two levels.
 */
const CLEAR_FAR = 'rgb(255, 255, 255)';

/** Levels each channel of band may stand from drawer's ground over `CLEAR_FAR`.
 *
 *  Both are computed rather than painted, so nothing rounds to whole level; half of one keeps
 *  verdict clear of six figures computed colour is written to.
 */
const LEVELS_SLACK = 0.5;

/** Read red, green and blue of computed fill, from 0 to 255, whatever notation it is in.
 *
 *  `color(srgb …)` carries channels from 0 to 1, and `rgb(…)` and `rgba(…)` from 0 to 255.
 */
function levelsOf(fill: string): number[] {
  const scale = fill.startsWith('color(') ? 255 : 1;
  return (fill.match(/[0-9.]+(?:e-[0-9]+)?/g) ?? []).slice(0, 3)
    .map((each) => Number(each) * scale);
}

/** Assert no rule and no element declares backdrop filter, and every surface fills at its alpha.
 *
 *  Rules and computed style both: rule for state no element holds yet computes on nothing, and
 *  style that script sets appears in no rule.
 *  Opaque bands are read as colour rather than as alpha: their fill is `color-mix`, opaque at
 *  any weight, so only drawer's ground over same clear colour says whether weight is alpha.
 */
export async function driveSurfacesFilled(page: Page): Promise<void> {
  const read = await page.evaluate((given) => {
    // Find every rule that declares filter, inside grouping and nested rules too.
    const declared: string[] = [];
    const walk = (rules: CSSRuleList): void => {
      for (const rule of Array.from(rules)) {
        if (rule instanceof CSSStyleRule) {
          const filter = rule.style.getPropertyValue('backdrop-filter') ||
            rule.style.getPropertyValue('-webkit-backdrop-filter');
          if (filter !== '' && filter !== 'none') declared.push(`${rule.selectorText} ${filter}`);
        }
        if ('cssRules' in rule) walk((rule as CSSGroupingRule).cssRules);
      }
    };
    for (const sheet of Array.from(document.styleSheets)) walk(sheet.cssRules);
    const computed = Array.from(document.querySelectorAll('*'))
      .filter((element) => getComputedStyle(element).backdropFilter !== 'none')
      .map((element) => `${element.tagName.toLowerCase()}#${element.id}`);

    // Read fill of every element each surface's selector matches.
    const fills = given.surfaces.map((selector) => Array.from(document.querySelectorAll(selector))
      .map((element) => getComputedStyle(element).backgroundColor));

    // Read bands over far clear colour, then hand page its own back.
    const root = document.documentElement.style;
    const clear = root.getPropertyValue('--bg');
    root.setProperty('--bg', given.clear);
    const bands = given.bands.map((selector) => Array.from(document.querySelectorAll(selector))
      .map((element) => getComputedStyle(element).backgroundColor));
    root.setProperty('--bg', clear);
    return { declared, computed, fills, bands };
  }, { surfaces: SURFACES, bands: BANDS, clear: CLEAR_FAR });

  report(
    'no rule and no element of the page declares a backdrop filter',
    read.declared.length === 0 && read.computed.length === 0,
    `${read.declared.length} rules declare one (${read.declared.join(', ')}), and ` +
      `${read.computed.length} elements compute one (${read.computed.join(', ')})`,
  );
  report(
    `and every surface over the scene fills at alpha ${ALPHA_SURFACE}`,
    read.fills.every((each) => each.length > 0 &&
      each.every((fill) => Math.abs(alphaOfFill(fill) - ALPHA_SURFACE) <= ALPHA_SLACK)),
    SURFACES.map((selector, i) => `${selector} ${(read.fills[i] ?? []).join(' ') || 'absent'}`)
      .join(', '),
  );

  // Composite drawer's own fill over far clear colour, as compositor would.
  const surface = read.fills[SURFACES.indexOf('.drawer')]?.[0] ?? 'absent';
  const alpha = alphaOfFill(surface);
  const far = levelsOf(CLEAR_FAR);
  const ground = levelsOf(surface).map((level, k) => level * alpha + (far[k] ?? 0) * (1 - alpha));
  report(
    'and every opaque band of the drawer is the drawer\'s own ground over the same clear colour',
    ground.length === 3 && read.bands.every((each) => each.length > 0 &&
      each.every((fill) => levelsOf(fill)
        .every((level, k) => Math.abs(level - (ground[k] ?? -1)) <= LEVELS_SLACK))),
    `ground ${ground.map((level) => level.toFixed(1)).join(' ')} over ${CLEAR_FAR}, ` +
      BANDS.map((selector, i) => `${selector} ` +
        ((read.bands[i] ?? []).map((fill) => levelsOf(fill).map((level) => level.toFixed(1))
          .join(' ')).join(', ') || 'absent')).join(', '),
  );
}
