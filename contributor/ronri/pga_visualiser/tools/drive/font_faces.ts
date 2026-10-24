// Read what page draws, each `@font-face` rule it declares and what each font face loaded, into
//   `build/font-faces/written.json` for `koch drive` (CONTRIBUTOR.md, Pages and assets); not Nim
//   because what is read is browser's own cascade, which only Playwright's API reaches.
//   Verdict is `koch drive`'s, never this project's: it writes control page before `drive`, and
//     once `drive` passes resolves this file down each font stack against `cmap` of each font
//     face, and reports each finding (`curator/audit/src/font_stacks.nim`). This resolves nothing
//     and judges nothing.
//   Each element is run in its own stack and at its own weight, as browser resolves them: its
//     text, value and placeholder of field, and what its `::before` and `::after` generate.
//     Stack read from text of shell would pass element that takes stack of its own.
//   What page writes later stands nowhere yet. Bridge's `nimCodepointsShown` gives every text
//     catalogue, help, notation and units write, as desktop's `--drive-faces` reads them, and
//     strings of page's own scripts give rest. Element that will show such character may not
//     stand yet either, so these, with every character page shows now, are one run for each
//     stack some element of page resolves to or some rule declares, at each weight page
//     resolves, its rules declare or its font faces declare.
//     Element script builds later takes its stack from rule that stands now, so every stack
//     page's stylesheets declare joins them, read through CSSOM, matched now or not.
//   Runs keep ASCII, as check this replaced did, so stack whose font faces lack Latin still
//     fails; resolver reads every codepoint run gives.
//   Control page has no bridge and no script of this project, so its runs are what it shows.
//     Same collector reads it, so place collector skips is numeral `koch drive` reports missing.
//   Rule names file holding its bytes, since resolver reads `cmap` out of file. Each font face
//     is inlined as `data:` source, so its bytes go once into `files/` beside `written.json`,
//     named by their SHA-256: bytes viewer receives, out of page itself.

import type { Browser, Page } from '@playwright/test';
import { createHash } from 'node:crypto';
import { existsSync, mkdirSync, readFileSync, readdirSync, rmSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { pathToFileURL } from 'node:url';

/** Project root, two levels above compiled harness in `build/drive`. */
const ROOT = join(__dirname, '..', '..');

/** Folder `koch drive` writes control page into, and reads `written.json` from. */
const DIRECTORY_FONT_FACES = join(ROOT, 'build', 'font-faces');

/** Control page `koch drive` writes before `drive`; absent where verb runs alone. */
const PATH_CONTROL = join(DIRECTORY_FONT_FACES, 'control.html');

/** What collector read on each page, for `koch drive` to resolve. */
const PATH_WRITTEN = join(DIRECTORY_FONT_FACES, 'written.json');

/** Folder beside `written.json` holding each font face file pages ship. */
const FOLDER_FILES = 'files';

/** Page `written.json` names for control page, as resolver reads it. */
const PAGE_CONTROL = 'control';

/** Types of `<input>` that show text page or reader writes; rest show none, or browser's own. */
const TYPES_INPUT_TEXT = ['email', 'number', 'password', 'search', 'tel', 'text', 'url'];

/** Format and base64 payload of `data:` source, as CSSOM serialises `src` descriptor. */
const PATTERN_SOURCE = /url\(\s*["']?data:font\/([a-z0-9]+);base64,([A-Za-z0-9+/=]+)/;

/** Weight keyword or number of `font-weight` descriptor, as number. */
const LUT_WEIGHT_BY_KEYWORD: Record<string, number> = { normal: 400, bold: 700 };

/** One string element draws, with stack and weight browser resolved for it. */
interface Run {
  element: string;
  stack: string;
  weight: number;
  codepoints: number[];
}

/** One `@font-face` rule, with file holding its bytes, as resolver reads it. */
interface Rule {
  family: string;
  weight: string;
  range: string;
  file: string;
}

/** One font face browser did not load. */
interface Refused {
  family: string;
  weight: string;
  status: string;
}

/** Three lists `written.json` holds for one page. */
interface Written {
  runs: Run[];
  declared: Rule[];
  refused: Refused[];
}

/** One `@font-face` rule as CSSOM serialises it, before its bytes are written to file. */
interface RuleRead {
  family: string;
  weight: string;
  range: string;
  source: string;
}

/** What collector read on one page, before font face files are written. */
interface WrittenRead {
  runs: Run[];
  declared: RuleRead[];
  refused: Refused[];
}

/** Stacks and weights rules of page's stylesheets declare, as browser resolves them. */
interface Declared {
  stacks: { rule: string; stack: string }[];
  weights: number[];
}

/** What collector read on each page, by name `written.json` gives it. */
const lut_read_by_page = new Map<string, WrittenRead>();

/** Read every character beyond ASCII that strings of page's own scripts hold. */
function readCodepointsScripts(): number[] {
  const codepoints: number[] = [];
  const directory = join(ROOT, 'src', 'browser');
  for (const name of readdirSync(directory).filter((one) => one.endsWith('.ts'))) {
    const source = readFileSync(join(directory, name), 'utf8')
      .replace(/\/\*[\s\S]*?\*\//g, '').replace(/\/\/.*$/gm, '');
    for (const literal of source.matchAll(/'([^'\n]*)'|"([^"\n]*)"|`([^`]*)`/g)) {
      const text = literal[1] ?? literal[2] ?? literal[3] ?? '';
      for (const character of text) {
        const codepoint = character.codePointAt(0) ?? 0;
        if (codepoint > 0x7E) codepoints.push(codepoint);
      }
    }
  }
  return codepoints;
}

/** Read every stack and weight that rules of page's stylesheets declare, as browser resolves them.
 *
 *  Walks every rule of every sheet, into `@media`, `@supports`, `@layer`, nested rules and
 *  imported sheets, whether or not it matches now. Each rule's own declarations go on probe
 *  under hidden holder, so browser resolves `var()` and `font` shorthand itself: once against
 *  document as it stands, then once under custom properties of each rule that declares some,
 *  since element built later may sit under such rule.
 *  Left out, each for its reason: `@font-face`, whose family names font face rather than stack;
 *  and `inherit` or `unset`, which declare no stack of their own, since element then takes
 *  its parent's, which other rule or body declares.
 */
async function readDeclared(page: Page): Promise<Declared> {
  return page.evaluate(() => {
    const rules: CSSRule[] = [];
    const gather = (list: CSSRuleList): void => {
      for (const rule of list) {
        rules.push(rule);
        if (rule instanceof CSSImportRule && rule.styleSheet !== null) {
          gather(rule.styleSheet.cssRules);
        }
        if ('cssRules' in rule) gather(rule.cssRules as CSSRuleList);
      }
    };
    for (const sheet of [...document.styleSheets, ...document.adoptedStyleSheets]) {
      gather(sheet.cssRules);
    }
    const styles = rules.flatMap((rule) => (
      rule instanceof CSSFontFaceRule || !('style' in rule) ? [] :
        [{ rule, style: rule.style as CSSStyleDeclaration }]
    ));
    const isDeclared = (style: CSSStyleDeclaration, longhand: string): boolean => {
      // Shorthand holding `var()` leaves its longhands empty until computed.
      const value = (style.getPropertyValue(longhand) || style.getPropertyValue('font')).trim();
      return value !== '' && value !== 'inherit' && value !== 'unset';
    };
    const declaring = styles.filter(({ style }) => isDeclared(style, 'font-family'));
    const contexts: [string, string][][] = [[]];
    for (const { style } of styles) {
      const own = [...style].filter((name) => name.startsWith('--'))
        .map((name): [string, string] => [name, style.getPropertyValue(name)]);
      if (own.length > 0) contexts.push(own);
    }
    const holder = document.createElement('div');
    const probe = document.createElement('div');
    holder.append(probe);
    document.body.append(holder);
    const stacks = new Map<string, string>();
    const weights = new Set<number>();
    for (const context of contexts) {
      holder.style.cssText = 'display: none';
      for (const [name, value] of context) holder.style.setProperty(name, value);
      for (const { rule, style } of declaring) {
        probe.style.cssText = style.cssText;
        const computed = window.getComputedStyle(probe);
        // Selector, or head of rule that has none, as stylesheet writes it.
        const head = rule.cssText.slice(0, rule.cssText.indexOf('{')).trim();
        if (!stacks.has(computed.fontFamily)) stacks.set(computed.fontFamily, head);
        if (isDeclared(style, 'font-weight')) weights.add(Number(computed.fontWeight));
      }
    }
    holder.remove();
    return { stacks: [...stacks].map(([stack, rule]) => ({ rule, stack })), weights: [...weights] };
  });
}

/** Read weights one `font-weight` descriptor names: keyword, number, or range of two. */
function toWeights(descriptor: string): number[] {
  return descriptor.trim().split(/\s+/).filter((word) => word.length > 0)
    .map((word) => LUT_WEIGHT_BY_KEYWORD[word] ?? Number(word));
}

/** Read what one page draws, declares and loaded, as `name` of `written.json`.
 *
 *  `is_own` marks this project's page: it adds what that page can write later, from bridge and
 *  from strings of its scripts, which control page has neither of.
 */
export async function readFontFaces(page: Page, name: string, is_own: boolean): Promise<void> {
  const gathered = await page.evaluate(async ({ types_text, is_own_page }) => {
    // Tag, then id where it has one, else classes under nearest ancestor that has id.
    const toName = (element: Element): string => {
      const tag = element.tagName.toLowerCase();
      if (element.id !== '') return `${tag}#${element.id}`;
      const own = tag + [...element.classList].map((one) => `.${one}`).join('');
      const holder = element.parentElement?.closest('[id]') ?? null;
      return holder === null ? own : `#${holder.id} ${own}`;
    };
    const shown = new Map<string, { element: string; stack: string; weight: number;
      codepoints: Set<number> }>();
    const add = (name_element: string, style: CSSStyleDeclaration, text: string): void => {
      if (text.length === 0) return;
      const stack = style.fontFamily;
      const weight = Number(style.fontWeight);
      const key = `${name_element}|${stack}|${weight}`;
      const entry = shown.get(key) ??
        { element: name_element, stack, weight, codepoints: new Set<number>() };
      for (const character of text) entry.codepoints.add(character.codePointAt(0) ?? 0);
      shown.set(key, entry);
    };
    // Markup as browser decoded it, entities and filled catalogue words alike, past scripts.
    //   SVG text is text node too, so it reads here with its own resolved stack.
    const walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT);
    for (let node = walker.nextNode(); node !== null; node = walker.nextNode()) {
      const parent = node.parentElement;
      if (parent === null || parent.tagName === 'SCRIPT' || parent.tagName === 'STYLE') continue;
      add(toName(parent), window.getComputedStyle(parent), node.textContent ?? '');
    }
    const resolved = new Map<string, { element: string; stack: string; weight: number }>();
    const elements = [document.body, ...document.body.querySelectorAll('*')];
    for (const element of elements) {
      if (element.tagName === 'SCRIPT' || element.tagName === 'STYLE') continue;
      // Checkbox draws no text, and file field's button draws browser's own words in its own
      //   font face.
      if (element instanceof HTMLInputElement && !types_text.includes(element.type)) continue;
      const style = window.getComputedStyle(element);
      const key = `${style.fontFamily}|${style.fontWeight}`;
      if (!resolved.has(key)) {
        resolved.set(key, {
          element: toName(element), stack: style.fontFamily, weight: Number(style.fontWeight),
        });
      }
      // Field's value is text it shows, and no text node holds it.
      if (element instanceof HTMLInputElement) add(toName(element), style, element.value);
      const placeholder = element.getAttribute('placeholder');
      if (placeholder !== null) {
        add(
          `${toName(element)}::placeholder`,
          window.getComputedStyle(element, '::placeholder'),
          placeholder,
        );
      }
      for (const pseudo of ['::before', '::after']) {
        const style_pseudo = window.getComputedStyle(element, pseudo);
        for (const literal of style_pseudo.content.matchAll(/"((?:[^"\\]|\\.)*)"/g)) {
          const text = (literal[1] ?? '').replace(/\\(.)/g, '$1');
          add(`${toName(element)}${pseudo}`, style_pseudo, text);
        }
      }
    }

    // Every `@font-face` rule of every sheet, as CSSOM serialises its descriptors.
    const rules: RuleRead[] = [];
    const gather = (list: CSSRuleList): void => {
      for (const rule of list) {
        if (rule instanceof CSSFontFaceRule) {
          rules.push({
            family: rule.style.getPropertyValue('font-family'),
            weight: rule.style.getPropertyValue('font-weight'),
            range: rule.style.getPropertyValue('unicode-range'),
            source: rule.style.getPropertyValue('src'),
          });
        }
        if (rule instanceof CSSImportRule && rule.styleSheet !== null) {
          gather(rule.styleSheet.cssRules);
        }
        if ('cssRules' in rule) gather(rule.cssRules as CSSRuleList);
      }
    };
    for (const sheet of document.styleSheets) gather(sheet.cssRules);

    // Load every font face, so one browser refuses reads as refused rather than as never asked.
    const font_faces = [...document.fonts];
    await Promise.allSettled(font_faces.map(async (font_face) => await font_face.load()));
    const refused = font_faces.filter((font_face) => font_face.status !== 'loaded')
      .map((font_face) => ({
        family: font_face.family, weight: font_face.weight, status: font_face.status,
      }));

    return {
      shown: [...shown.values()].map((entry) => ({ ...entry, codepoints: [...entry.codepoints] })),
      count_elements: elements.length,
      resolved: [...resolved.values()],
      catalogue: is_own_page ? nimCodepointsShown() : [],
      rules,
      refused,
    };
  }, { types_text: TYPES_INPUT_TEXT, is_own_page: is_own });

  // Each element in its own stack, at its own weight.
  const isDrawn = (codepoint: number): boolean => codepoint >= 0x20;
  const runs_shown: Run[] = gathered.shown.map((one) => ({
    element: one.element, stack: one.stack, weight: one.weight,
    codepoints: one.codepoints.filter(isDrawn).sort((a, b) => a - b),
  })).filter((run) => run.codepoints.length > 0);
  const codepoints_shown = new Set(runs_shown.flatMap((run) => run.codepoints));

  // What page can write, now or later, in every stack some element resolves to or some rule
  //   declares, at every weight in play.
  const writable = [...new Set([
    ...codepoints_shown, ...gathered.catalogue,
    ...(is_own ? readCodepointsScripts() : []),
  ])].filter(isDrawn).sort((a, b) => a - b);
  const declared = await readDeclared(page);
  const lut_element_by_stack = new Map<string, string>();
  for (const one of gathered.resolved) {
    if (!lut_element_by_stack.has(one.stack)) lut_element_by_stack.set(one.stack, one.element);
  }
  // Stack no element resolves to yet is named by first rule that declares it.
  for (const one of declared.stacks) {
    if (!lut_element_by_stack.has(one.stack)) {
      lut_element_by_stack.set(one.stack, `rule ${one.rule}`);
    }
  }
  const weights = [...new Set([
    ...gathered.resolved.map((one) => one.weight), ...declared.weights,
    ...gathered.rules.flatMap((rule) => toWeights(rule.weight)),
  ])].sort((a, b) => a - b);
  const runs_later: Run[] = [];
  if (writable.length > 0) {
    for (const [stack, element] of lut_element_by_stack) {
      for (const weight of weights) {
        runs_later.push({
          element: `text written later in ${element} at ${weight}`, stack, weight,
          codepoints: writable,
        });
      }
    }
  }

  lut_read_by_page.set(name, {
    runs: [...runs_shown, ...runs_later], declared: gathered.rules, refused: gathered.refused,
  });
  console.log(
    `Read font faces of ${name}: ${gathered.count_elements} elements, ${codepoints_shown.size} ` +
      `characters shown, ${writable.length} it can write, in ${lut_element_by_stack.size} ` +
      `stacks at weights ${weights.join(', ')}, ${gathered.rules.length} font faces declared, ` +
      `${gathered.refused.length} refused.`,
  );
}

/** Write bytes of one `data:` source once into folder of files, and name file; throw where
 *  source is not inlined, since resolver reads bytes and not address. */
function writeFontFace(source: string, lut_file_by_source: Map<string, string>): string {
  const known = lut_file_by_source.get(source);
  if (known !== undefined) return known;
  const [, format, payload] = PATTERN_SOURCE.exec(source) ?? [];
  if (format === undefined || payload === undefined) {
    throw new Error(`Font face is inlined as \`data:\` source; got \`${source.slice(0, 60)}\`.`);
  }
  const bytes = Buffer.from(payload, 'base64');
  const file = `${FOLDER_FILES}/${createHash('sha256').update(bytes).digest('hex')}.${format}`;
  writeFileSync(join(DIRECTORY_FONT_FACES, file), bytes);
  lut_file_by_source.set(source, file);
  return file;
}

/** Read control page `koch drive` wrote, where one stands, then write `written.json`. */
export async function writeFontFaces(browser: Browser): Promise<void> {
  const found_control = existsSync(PATH_CONTROL);
  if (found_control) {
    const page = await browser.newPage();
    await page.goto(pathToFileURL(PATH_CONTROL).href);
    await readFontFaces(page, PAGE_CONTROL, false);
    await page.close();
  }

  // Clear files earlier run wrote, so folder holds only those this run names.
  rmSync(join(DIRECTORY_FONT_FACES, FOLDER_FILES), { recursive: true, force: true });
  mkdirSync(join(DIRECTORY_FONT_FACES, FOLDER_FILES), { recursive: true });
  const lut_file_by_source = new Map<string, string>();
  const pages: Record<string, Written> = {};
  for (const [page, read] of lut_read_by_page) {
    pages[page] = {
      runs: read.runs,
      declared: read.declared.map((rule) => ({
        family: rule.family, weight: rule.weight, range: rule.range,
        file: writeFontFace(rule.source, lut_file_by_source),
      })),
      refused: read.refused,
    };
  }
  writeFileSync(PATH_WRITTEN, `${JSON.stringify(pages, null, 2)}\n`);
  const count_pages = lut_read_by_page.size - (found_control ? 1 : 0);
  console.log(found_control ?
    `Wrote ${PATH_WRITTEN} from ${count_pages} page and control page.` :
    `Wrote ${PATH_WRITTEN} from ${count_pages} page, and no control page: none stands at ` +
      `${PATH_CONTROL}.`);
  console.log('Findings on font faces are `koch drive`\'s: it writes control page, runs `drive`, ' +
    'then resolves that file.');
}
