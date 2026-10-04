// Read what rendered page writes, and faces it declares, as browser computed them; not Nim
//   because every expression here runs inside page through Playwright's `evaluate`, which
//   Nim reaches only as unchecked string, where TypeScript checks it against DOM's own types.
//   Text read is every string page draws:
//   - text nodes, SVG `text` and `tspan` among them, past `script`, `style`, `title`, `desc`,
//     `metadata` and `noscript`, which draw none;
//   - `placeholder`, and `value` of `input` whose type is button, which no text node holds;
//   - strings of `content` on `::before`, `::after` and `::marker`, and string
//     `list-style-type`. Counter of `content` and keyword marker are not read: pages count
//     in decimal, and Chromium paints `disc` as shape rather than glyph.
//   Each string is read with `font-family` and `font-weight` of element drawing it, and
//     `text-transform` applied, since uppercase of character is other codepoint.
//   Every `details` opens first, and every element shows: element behind tab or filter that
//     `:has()` rules hide still carries computed style, so every state of page reads in one
//     pass. Showing is for cost alone. Chromium styles hidden element on demand, one by one,
//     and docket's 28 540 made its read 65 s that way against 1.7 s at most in one pass,
//     measured in Chromium 141 on 2026-10-04. `display` sets no font property, so no verdict
//     moves: every string docket draws read identical both ways.
//   Cost: page is read at one viewport, Playwright's default; string or stack that `@media`
//     gates on other width is unread.

import type { Page } from '@playwright/test';
import type { Declared } from './faces';

/** One string page draws in one element, with stack and weight it is drawn at. */
export interface Run {
  element: string;
  stack: string;
  weight: number;
  codepoints: number[];
}

/** One face page declares, with status browser reached loading it. */
export interface Loaded {
  family: string;
  weight: string;
  status: string;
}

/** Everything one page writes and declares. */
export interface Written {
  runs: Run[];
  declared: Declared[];
  loaded: Loaded[];
  count_elements: number;
}

/** Read every run beyond ASCII page draws, every face it declares, and what each face loaded. */
export async function readWritten(page: Page): Promise<Written> {
  return await page.evaluate(async () => {
    const silent = 'script, style, title, desc, metadata, noscript';
    const types_button = new Set(['button', 'reset', 'submit']);
    const runs: Run[] = [];

    // Name element by tag, id and classes, under ancestors up to one carrying id, at most two.
    const named = (element: Element): string => {
      const classes = (element.getAttribute('class') ?? '').split(/\s+/)
        .filter((name) => name.length > 0).map((name) => `.${name}`).join('');
      return `${element.tagName.toLowerCase()}${element.id ? `#${element.id}` : ''}${classes}`;
    };
    const described = (element: Element): string => {
      const parts = [named(element)];
      let at = element.parentElement;
      while (at !== null && at !== document.body && parts.length < 3 && !element.id) {
        parts.unshift(named(at));
        if (at.id) break;
        at = at.parentElement;
      }
      return parts.join(' > ');
    };
    // Join strings of computed `content` or `list-style-type`, with CSS escapes resolved.
    const stringsOf = (value: string): string => {
      let text = '';
      for (const quoted of value.matchAll(/"((?:[^"\\]|\\.)*)"/g)) {
        text += (quoted[1] ?? '').replace(
          /\\([0-9a-fA-F]{1,6})\s?|\\(.)/g,
          (_: string, hex: string | undefined, plain: string | undefined): string =>
            hex !== undefined ? String.fromCodePoint(parseInt(hex, 16)) : plain ?? '',
        );
      }
      return text;
    };
    // Keep codepoints beyond ASCII that text draws, once each.
    const beyondAscii = (text: string): number[] => {
      const codepoints = new Set<number>();
      for (const character of text) {
        const codepoint = character.codePointAt(0) ?? 0;
        if (codepoint > 0x7F) codepoints.add(codepoint);
      }
      return [...codepoints];
    };
    // Record text element draws under one pseudo-element, styled as that one is.
    //   Style is read only past ASCII test: case of ASCII letter is ASCII letter.
    const add = (element: Element, pseudo: string, text: string, style_pseudo = pseudo):
        void => {
      if (beyondAscii(text).length === 0) return;
      const style = getComputedStyle(element, style_pseudo || null);
      const transform = style.textTransform;
      const codepoints = beyondAscii(
        transform === 'uppercase' ? text.toUpperCase() :
          transform === 'lowercase' ? text.toLowerCase() :
          transform === 'capitalize' ? text + text.toUpperCase() : text,
      );
      if (codepoints.length === 0) return;
      runs.push({
        element: `${described(element)}${pseudo}`,
        stack: style.fontFamily,
        weight: Number(style.fontWeight),
        codepoints,
      });
    };

    // Open every disclosure and show every element, so one style pass reads every state.
    for (const details of document.querySelectorAll('details')) details.open = true;
    const shown = document.createElement('style');
    shown.textContent = 'body * { display: revert !important; }';
    document.head.append(shown);

    // Read text nodes, each in element that draws it.
    const walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT);
    for (let node = walker.nextNode(); node !== null; node = walker.nextNode()) {
      const parent = node.parentElement;
      if (parent === null || parent.closest(silent) !== null) continue;
      add(parent, '', node.textContent ?? '');
    }

    // Read attributes drawn as text, and generated strings of each element.
    const elements = [...document.body.querySelectorAll('*')];
    for (const element of elements) {
      if (element.closest(silent) !== null) continue;
      add(element, '::placeholder', element.getAttribute('placeholder') ?? '', '');
      if (element instanceof HTMLInputElement && types_button.has(element.type)) {
        add(element, '', element.value);
      }
      for (const pseudo of ['::before', '::after', '::marker']) {
        add(element, pseudo, stringsOf(getComputedStyle(element, pseudo).content));
      }
      add(element, '::marker', stringsOf(getComputedStyle(element).listStyleType));
    }

    // Read every face rule of every sheet, as CSSOM serialises its descriptors.
    const declared: Declared[] = [];
    for (const sheet of document.styleSheets) {
      for (const rule of sheet.cssRules) {
        if (!(rule instanceof CSSFontFaceRule)) continue;
        declared.push({
          family: rule.style.getPropertyValue('font-family'),
          weight: rule.style.getPropertyValue('font-weight'),
          range: rule.style.getPropertyValue('unicode-range'),
          source: rule.style.getPropertyValue('src'),
        });
      }
    }

    // Load every face, so one browser refuses reads as refused rather than as never asked.
    const faces = [...document.fonts];
    await Promise.allSettled(faces.map(async (face) => await face.load()));
    const loaded = faces.map((face) => ({
      family: face.family, weight: face.weight, status: face.status,
    }));

    return { runs, declared, loaded, count_elements: elements.length };
  });
}
