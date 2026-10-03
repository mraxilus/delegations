// Check that every character page writes has glyph in face page ships, at every weight its
//   faces are declared at; not Nim because what is under check is cascade of page's own
//   stylesheet and bytes of faces it embeds, which only build and harness hold.
//   Characters come from two places. Bridge's `nimCodepointsShown` gives every text catalogue,
//   help, notation and units write, as desktop's `--drive-faces` reads them. Literal text of
//   page itself -- its markup and strings of its scripts -- gives what no catalogue holds.
//   Faces are read as browser reads them: shell's `@font-face` rules give family, weight and
//   unicode-range, and each file's own `cmap` gives what it holds. Within family, faces at
//   weight CSS matching picks are tried in turn; then next family of stack.
//   Family past those page ships -- `-apple-system`, `Arial`, `monospace` -- is viewer's own,
//   so character that reaches one is failure (Article X.8).

import type { Page } from '@playwright/test';
import { readFileSync, readdirSync } from 'node:fs';
import { join } from 'node:path';
import { brotliDecompressSync } from 'node:zlib';
import { report } from './report';

/** Project root, two levels above compiled harness in `build/drive`. */
const ROOT = join(__dirname, '..', '..');

/** Variables of shell's stylesheet that name stacks, one for each role page draws. */
const STACKS = ['--sans', '--mono', '--serif'];

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

/** Name face of stack that draws `codepoint` at `weight`, or none where viewer's own would. */
function faceDrawing(faces: Face[], stack: string[], weight: number, codepoint: number):
    Face | undefined {
  for (const family of stack) {
    const own = faces.filter((face) => face.family === family);
    if (own.length === 0) continue;
    const declared = own.flatMap((face) => [face.weights[0], face.weights[1]]);
    const matched = weightMatched(weight, declared);
    // Later rule is asked first where ranges overlap, as CSS orders segmented faces.
    for (const face of [...own].reverse()) {
      if (matched < face.weights[0] || matched > face.weights[1]) continue;
      const is_in_range = face.ranges.length === 0 ||
        face.ranges.some(([start, end]) => codepoint >= start && codepoint <= end);
      if (is_in_range && face.held.has(codepoint)) return face;
    }
  }
  return undefined;
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

/** Assert every character page writes is drawn by face page ships, in every stack. */
export async function driveFacesCovered(page: Page): Promise<void> {
  const shell = readFileSync(join(ROOT, 'pages', 'shell.html'), 'utf8');
  const faces = facesOf(shell);
  // Markup as browser decoded it, entities and filled catalogue words alike, past scripts.
  const from_page = await page.evaluate(() => {
    const found: number[] = [];
    const walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT);
    for (let node = walker.nextNode(); node !== null; node = walker.nextNode()) {
      const parent = node.parentElement?.tagName ?? '';
      if (parent === 'SCRIPT' || parent === 'STYLE') continue;
      for (const character of node.textContent ?? '') found.push(character.codePointAt(0) ?? 0);
    }
    for (const field of document.querySelectorAll('[placeholder]')) {
      for (const character of field.getAttribute('placeholder') ?? '') {
        found.push(character.codePointAt(0) ?? 0);
      }
    }
    return [...nimCodepointsShown(), ...found];
  });
  const codepoints = [...new Set([...from_page, ...codepointsOfScripts()])]
    .filter((codepoint) => codepoint >= 0x20).sort((a, b) => a - b);
  const weights = [...new Set(faces.flatMap((face) => face.weights))].sort((a, b) => a - b);
  for (const variable of STACKS) {
    const declared = new RegExp(`${variable}:\\s*([^;]+);`).exec(shell)?.[1] ?? '';
    const stack = declared.split(',').map((family) => family.trim().replace(/^"|"$/g, ''));
    const missing: string[] = [];
    for (const weight of weights) {
      for (const codepoint of codepoints) {
        if (faceDrawing(faces, stack, weight, codepoint) !== undefined) continue;
        missing.push(`U+${codepoint.toString(16).toUpperCase().padStart(4, '0')} at ${weight}`);
      }
    }
    report(
      `every character the page writes in its ${variable} stack has a face the page ships`,
      missing.length === 0,
      `${codepoints.length} codepoints at weights ${weights.join(', ')}, from ` +
        `${faces.length} faces; missing ${missing.length === 0 ? 'none' : missing.join(', ')}`,
    );
  }
}
