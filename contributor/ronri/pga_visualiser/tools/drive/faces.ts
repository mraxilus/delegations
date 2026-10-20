// Check that every character page writes has glyph in face page ships, in stack and at weight
//   that draw it; not Nim because what is under check is cascade of page's own stylesheet and
//   bytes of faces it embeds, which only build and harness hold.
//   Each element is held to its own stack and weight, as browser resolves them: its text, value
//   and placeholder of field, and what its `::before` and `::after` generate. Stack read from
//   text of shell would pass element that takes stack of its own.
//   What page writes later stands nowhere yet. Bridge's `nimCodepointsShown` gives every text
//   catalogue, help, notation and units write, as desktop's `--drive-faces` reads them, and
//   strings of page's own scripts give rest. Element that will show such character may not
//   stand yet either, so these, with every character page shows now, are held to every stack
//   some element of page resolves to, at every weight page resolves or its faces declare.
//   Element script builds later takes its stack from rule that stands now, so every stack
//   page's stylesheets declare joins them, read through CSSOM, matched now or not.
//   Faces are read as browser reads them: shell's `@font-face` rules give family, weight and
//   unicode-range, and each file's own `cmap` gives what it holds. Within family, matching
//   picks set of faces that declare one weight, and only its faces are tried; then next
//   family of stack.
//   Family past those page ships -- `-apple-system`, `Arial`, `monospace` -- is viewer's own,
//   so character that reaches one is failure (Article X.8).

import type { Page } from '@playwright/test';
import { readFileSync, readdirSync } from 'node:fs';
import { basename, join } from 'node:path';
import { brotliDecompressSync } from 'node:zlib';
import { report } from './report';

/** Project root, two levels above compiled harness in `build/drive`. */
const ROOT = join(__dirname, '..', '..');

/** Types of `<input>` that show text page or reader writes; rest show none, or browser's own. */
const TYPES_INPUT_TEXT = ['email', 'number', 'password', 'search', 'tel', 'text', 'url'];

/** Tags of WOFF2's known tables, in order format numbers them; `cmap` is first. */
const TAGS_WOFF2_KNOWN = ['cmap', 'head', 'hhea', 'hmtx', 'maxp', 'name', 'OS/2', 'post',
  'cvt ', 'fpgm', 'glyf', 'loca', 'prep', 'CFF '];

/** One `@font-face` rule of shell, with codepoints its file holds. */
interface Face {
  family: string;
  weights: [number, number];
  ranges: [number, number][];
  file: string;
  held: Set<number>;
}

/** Stack and weight browser resolved for one element, named as finding names it. */
interface Resolved {
  element: string;
  stack: string;
  weight: number;
}

/** Characters one element shows, under stack and weight it resolved to. */
interface Shown extends Resolved {
  codepoints: number[];
}

/** Stacks and weights rules of page's stylesheets declare, as browser resolves them. */
interface Declared {
  stacks: { rule: string; stack: string }[];
  weights: number[];
  count_rules: number;
}

/** Read every codepoint one `cmap` table maps to glyph other than `.notdef`. */
function codepointsOfCmap(table: Buffer): Set<number> {
  const held = new Set<number>();
  const count_subtables = table.readUInt16BE(2);
  for (let i = 0; i < count_subtables; i += 1) {
    const at = table.readUInt32BE(4 + 8 * i + 4);
    const format = table.readUInt16BE(at);
    if (format === 4) {
      const count_segments = table.readUInt16BE(at + 6) / 2;
      const ends = at + 14;
      const starts = ends + 2 * count_segments + 2;
      const deltas = starts + 2 * count_segments;
      const offsets = deltas + 2 * count_segments;
      for (let segment = 0; segment < count_segments; segment += 1) {
        const end = table.readUInt16BE(ends + 2 * segment);
        const start = table.readUInt16BE(starts + 2 * segment);
        const delta = table.readInt16BE(deltas + 2 * segment);
        const offset = table.readUInt16BE(offsets + 2 * segment);
        for (let codepoint = start; codepoint <= end && codepoint !== 0xFFFF; codepoint += 1) {
          let glyph = (codepoint + delta) & 0xFFFF;
          if (offset !== 0) {
            const at_glyph = offsets + 2 * segment + offset + 2 * (codepoint - start);
            glyph = table.readUInt16BE(at_glyph);
            if (glyph !== 0) glyph = (glyph + delta) & 0xFFFF;
          }
          if (glyph !== 0) held.add(codepoint);
        }
      }
    } else if (format === 12) {
      const count_groups = table.readUInt32BE(at + 12);
      for (let group = 0; group < count_groups; group += 1) {
        const start = table.readUInt32BE(at + 16 + 12 * group);
        const end = table.readUInt32BE(at + 20 + 12 * group);
        const glyph = table.readUInt32BE(at + 24 + 12 * group);
        for (let codepoint = start; codepoint <= end; codepoint += 1) {
          if (glyph + codepoint - start !== 0) held.add(codepoint);
        }
      }
    }
  }
  return held;
}

/** Read `cmap` table out of TrueType, OpenType or WOFF2 file. */
function cmapOf(bytes: Buffer): Buffer {
  if (bytes.toString('latin1', 0, 4) !== 'wOF2') {
    const count_tables = bytes.readUInt16BE(4);
    for (let i = 0; i < count_tables; i += 1) {
      const record = 12 + 16 * i;
      if (bytes.toString('latin1', record, record + 4) === 'cmap') {
        const at = bytes.readUInt32BE(record + 8);
        return bytes.subarray(at, at + bytes.readUInt32BE(record + 12));
      }
    }
    throw new Error('Face holds no `cmap` table.');
  }
  // WOFF2: table directory of variable-length entries, then one Brotli stream of tables in
  //   directory order. `cmap` is never transformed, so its bytes stand as stored.
  let at = 48;
  const readBase128 = (): number => {
    let value = 0;
    for (let i = 0; i < 5; i += 1) {
      const byte = bytes[at] ?? 0;
      at += 1;
      value = value * 128 + (byte & 0x7F);
      if ((byte & 0x80) === 0) return value;
    }
    throw new Error('WOFF2 length runs past five bytes.');
  };
  const tables: { tag: string; length: number }[] = [];
  for (let i = 0; i < bytes.readUInt16BE(12); i += 1) {
    const flags = bytes[at] ?? 0;
    at += 1;
    let tag = TAGS_WOFF2_KNOWN[flags & 0x3F] ?? '';
    if ((flags & 0x3F) === 63) {
      tag = bytes.toString('latin1', at, at + 4);
      at += 4;
    }
    const version = flags >> 6;
    const length_original = readBase128();
    const is_transformed = tag === 'glyf' || tag === 'loca' ? version === 0 :
      tag === 'hmtx' && version === 1;
    tables.push({ tag, length: is_transformed ? readBase128() : length_original });
  }
  const stream = brotliDecompressSync(bytes.subarray(at));
  let offset = 0;
  for (const table of tables) {
    if (table.tag === 'cmap') return stream.subarray(offset, offset + table.length);
    offset += table.length;
  }
  throw new Error('WOFF2 holds no `cmap` table.');
}

/** Read every `@font-face` rule of shell, with what its file holds. */
function facesOf(shell: string): Face[] {
  const faces: Face[] = [];
  for (const rule of shell.matchAll(/@font-face\s*\{([^}]*)\}/g)) {
    const body = rule[1] ?? '';
    const family = /font-family:\s*"([^"]+)"/.exec(body)?.[1] ?? '';
    const weights = (/font-weight:\s*([0-9 ]+);/.exec(body)?.[1] ?? '400').trim().split(/\s+/)
      .map(Number);
    const ranges: [number, number][] = [];
    for (const range of (/unicode-range:\s*([^;]+);/.exec(body)?.[1] ?? '').split(',')) {
      const bounds = /U\+([0-9A-Fa-f]+)(?:-([0-9A-Fa-f]+))?/.exec(range.trim());
      if (bounds === null) continue;
      const start = parseInt(bounds[1] ?? '0', 16);
      ranges.push([start, bounds[2] === undefined ? start : parseInt(bounds[2], 16)]);
    }
    const file = /@EMBED:([^@]+)@/.exec(body)?.[1] ?? '';
    const held = codepointsOfCmap(cmapOf(readFileSync(join(ROOT, 'build', 'fonts', file))));
    faces.push({
      family, weights: [weights[0] ?? 400, weights[1] ?? weights[0] ?? 400], ranges, file, held,
    });
  }
  return faces;
}

/** Pick weight CSS matching settles on for `wanted`, among weights family declares. */
function weightMatched(wanted: number, declared: number[]): number {
  if (declared.includes(wanted)) return wanted;
  const above = declared.filter((weight) => weight > wanted).sort((a, b) => a - b);
  const below = declared.filter((weight) => weight < wanted).sort((a, b) => b - a);
  const window = above.filter((weight) => weight <= 500);
  if (wanted >= 400 && wanted <= 500 && window.length > 0) return window[0] ?? wanted;
  if (wanted <= 500) return below[0] ?? above[0] ?? wanted;
  return above[0] ?? below[0] ?? wanted;
}

/** Split resolved `font-family` into its families, unquoted, in order stack tries them. */
function familiesOf(stack: string): string[] {
  return [...stack.matchAll(/"([^"]*)"|'([^']*)'|([^,"']+)/g)]
    .map((match) => (match[1] ?? match[2] ?? match[3] ?? '').trim())
    .filter((family) => family.length > 0);
}

/** Name face of stack that draws `codepoint` at `weight`, or none where viewer's own would.
 *
 *  Matching picks set of faces, never face: faces of family that declare same weight form one
 *  set, and engine asks only faces of set it picks. Where two sets both hold weight asked --
 *  face at 400 and faces at 400 to 600 -- which one it picks is engine's, so character counts
 *  as drawn only where each such set, or family after it, draws it.
 */
function faceDrawing(faces: Face[], stack: string[], weight: number, codepoint: number):
    Face | undefined {
  const [family, ...rest] = stack;
  if (family === undefined) return undefined;
  // Family names match without case, as CSS matches them.
  const own = faces.filter((face) => face.family.toLowerCase() === family.toLowerCase());
  if (own.length === 0) return faceDrawing(faces, rest, weight, codepoint);
  const sets = new Map<string, Face[]>();
  for (const face of own) {
    const key = face.weights.join(' ');
    sets.set(key, [...(sets.get(key) ?? []), face]);
  }
  const isHolding = (set: Face[], at: number): boolean =>
    at >= (set[0]?.weights[0] ?? 0) && at <= (set[0]?.weights[1] ?? 0);
  const matched = [...sets.values()].some((set) => isHolding(set, weight)) ? weight :
    weightMatched(weight, own.flatMap((face) => [face.weights[0], face.weights[1]]));
  const drawing = [...sets.values()].filter((set) => isHolding(set, matched)).map((set) => {
    // Later rule is asked first where ranges overlap, as CSS orders segmented faces.
    const face = [...set].reverse().find((one) => one.held.has(codepoint) &&
      (one.ranges.length === 0 ||
        one.ranges.some(([start, end]) => codepoint >= start && codepoint <= end)));
    return face ?? faceDrawing(faces, rest, weight, codepoint);
  });
  return drawing.every((face) => face !== undefined) ? drawing[0] : undefined;
}

/** Read every character beyond ASCII that strings of page's own scripts hold. */
function codepointsOfScripts(): number[] {
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
 *  Left out, each for its reason: `@font-face`, whose family names face rather than stack;
 *  and `inherit` or `unset`, which declare no stack of their own, since element then takes
 *  its parent's, which other rule or body declares.
 */
async function declaredOf(page: Page): Promise<Declared> {
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
    return {
      stacks: [...stacks].map(([stack, rule]) => ({ rule, stack })),
      weights: [...weights],
      count_rules: declaring.length,
    };
  });
}

/** Say codepoint as Unicode writes it. */
function nameOfCodepoint(codepoint: number): string {
  return `U+${codepoint.toString(16).toUpperCase().padStart(4, '0')}`;
}

/** Assert every character page writes is drawn by face page ships, in stack that draws it. */
export async function driveFacesCovered(page: Page): Promise<void> {
  const shell = readFileSync(join(ROOT, 'pages', 'shell.html'), 'utf8');
  const faces = facesOf(shell);
  const name_page = basename(new URL(page.url()).pathname);
  const gathered = await page.evaluate((types_text) => {
    // Tag, then id where it has one, else classes under nearest ancestor that has id.
    const nameOf = (element: Element): string => {
      const tag = element.tagName.toLowerCase();
      if (element.id !== '') return `${tag}#${element.id}`;
      const own = tag + [...element.classList].map((name) => `.${name}`).join('');
      const holder = element.parentElement?.closest('[id]') ?? null;
      return holder === null ? own : `#${holder.id} ${own}`;
    };
    const shown = new Map<string, { resolved: Resolved; codepoints: Set<number> }>();
    const holders = new Set<Element>();
    const add = (element: Element, name: string, style: CSSStyleDeclaration, text: string):
        void => {
      if (text.length === 0) return;
      holders.add(element);
      const resolved = { element: name, stack: style.fontFamily, weight: Number(style.fontWeight) };
      const key = `${name}|${resolved.stack}|${resolved.weight}`;
      const entry = shown.get(key) ?? { resolved, codepoints: new Set<number>() };
      for (const character of text) entry.codepoints.add(character.codePointAt(0) ?? 0);
      shown.set(key, entry);
    };
    // Markup as browser decoded it, entities and filled catalogue words alike, past scripts.
    const walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT);
    for (let node = walker.nextNode(); node !== null; node = walker.nextNode()) {
      const parent = node.parentElement;
      if (parent === null || parent.tagName === 'SCRIPT' || parent.tagName === 'STYLE') continue;
      add(parent, nameOf(parent), window.getComputedStyle(parent), node.textContent ?? '');
    }
    const resolved = new Map<string, Resolved>();
    for (const element of [document.body, ...document.body.querySelectorAll('*')]) {
      if (element.tagName === 'SCRIPT' || element.tagName === 'STYLE') continue;
      // Checkbox draws no text, and file field's button draws browser's own words in its own face.
      if (element instanceof HTMLInputElement && !types_text.includes(element.type)) continue;
      const style = window.getComputedStyle(element);
      const key = `${style.fontFamily}|${style.fontWeight}`;
      if (!resolved.has(key)) {
        resolved.set(key, {
          element: nameOf(element), stack: style.fontFamily, weight: Number(style.fontWeight),
        });
      }
      // Field's value is text it shows, and no text node holds it.
      if (element instanceof HTMLInputElement) add(element, nameOf(element), style, element.value);
      const placeholder = element.getAttribute('placeholder');
      if (placeholder !== null) {
        add(
          element,
          `${nameOf(element)}::placeholder`,
          window.getComputedStyle(element, '::placeholder'),
          placeholder,
        );
      }
      for (const pseudo of ['::before', '::after']) {
        const style_pseudo = window.getComputedStyle(element, pseudo);
        for (const literal of style_pseudo.content.matchAll(/"((?:[^"\\]|\\.)*)"/g)) {
          const text = (literal[1] ?? '').replace(/\\(.)/g, '$1');
          add(element, `${nameOf(element)}${pseudo}`, style_pseudo, text);
        }
      }
    }
    return {
      shown: [...shown.values()].map((entry) => ({
        ...entry.resolved, codepoints: [...entry.codepoints],
      })),
      count_holders: holders.size,
      resolved: [...resolved.values()],
      catalogue: nimCodepointsShown(),
    };
  }, TYPES_INPUT_TEXT);

  // Each element in its own stack, at its own weight.
  const shown: Shown[] = gathered.shown.map((one) => ({
    ...one, codepoints: one.codepoints.filter((codepoint) => codepoint >= 0x20),
  }));
  const missing_shown: string[] = [];
  for (const one of shown) {
    const stack = familiesOf(one.stack);
    const missing = one.codepoints.filter(
      (codepoint) => faceDrawing(faces, stack, one.weight, codepoint) === undefined,
    ).sort((a, b) => a - b);
    if (missing.length === 0) continue;
    missing_shown.push(
      `${name_page} ${one.element} at ${one.weight}: ${missing.map(nameOfCodepoint).join(' ')}`,
    );
  }
  const stacks_shown = new Set(shown.map((one) => one.stack));
  const count_shown = new Set(shown.flatMap((one) => one.codepoints)).size;
  report(
    'every character an element of the page shows has a face the page ships, in the stack ' +
      'and at the weight that element resolves to',
    missing_shown.length === 0,
    `${gathered.count_holders} elements, ${count_shown} codepoints, in ${stacks_shown.size} ` +
      `stacks, from ${faces.length} faces; missing ` +
      `${missing_shown.length === 0 ? 'none' : missing_shown.join('; ')}`,
  );

  // What page can write, now or later, in every stack some element resolves to or some rule
  //   declares, at every weight in play.
  const writable = [...new Set([
    ...shown.flatMap((one) => one.codepoints), ...gathered.catalogue, ...codepointsOfScripts(),
  ])].filter((codepoint) => codepoint >= 0x20).sort((a, b) => a - b);
  const declared = await declaredOf(page);
  const stacks = new Map<string, string>();
  for (const one of gathered.resolved) {
    if (!stacks.has(one.stack)) stacks.set(one.stack, one.element);
  }
  // Stack no element resolves to yet is named by first rule that declares it.
  for (const one of declared.stacks) {
    if (!stacks.has(one.stack)) stacks.set(one.stack, `rule ${one.rule}`);
  }
  const weights = [...new Set([
    ...gathered.resolved.map((one) => one.weight), ...declared.weights,
    ...faces.flatMap((face) => face.weights),
  ])].sort((a, b) => a - b);
  const missing_writable: string[] = [];
  for (const [stack, element] of stacks) {
    const families = familiesOf(stack);
    for (const weight of weights) {
      const missing = writable.filter(
        (codepoint) => faceDrawing(faces, families, weight, codepoint) === undefined,
      );
      if (missing.length === 0) continue;
      missing_writable.push(
        `${name_page} ${element} at ${weight}: ${missing.map(nameOfCodepoint).join(' ')}`,
      );
    }
  }
  report(
    'and every character the page can write has a face the page ships, in every stack an ' +
      'element of the page resolves to or a rule of its stylesheets declares',
    missing_writable.length === 0,
    `${writable.length} codepoints of page, catalogue and scripts, in ${stacks.size} stacks ` +
      `(${declared.stacks.length} declared by ${declared.count_rules} rules) at weights ` +
      `${weights.join(', ')}, from ${faces.length} faces; missing ` +
      `${missing_writable.length === 0 ? 'none' : missing_writable.join('; ')}`,
  );
}
