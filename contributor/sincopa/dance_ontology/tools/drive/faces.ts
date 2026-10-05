// Resolve font stack of element against `cmap` of each face page ships; not Nim because
//   faces here are those browser read out of page's own stylesheet, and this module is half
//   of harness that Playwright's API forces into node (see `main.ts`).
//   Ported from `pga_benchmark`'s `tools/drive/faces.ts`, itself ported from
//   `rga_visualiser`'s: `cmap` reader, TrueType and WOFF2, and weight matching of CSS Fonts 4.
//   Fix to one is finished only when others are checked. Same as `pga_benchmark`'s, line for
//   line, in what it does:
//   - Faces come out of built page, as `data:` sources its `@font-face` rules carry, rather
//     than out of store, so check holds bytes viewer receives.
//   - Family page does not ship ends search, rather than being stepped over. Viewer's own face
//     of that name, or of generic family, would draw character, whatever stands after it.
//   Within family, faces at weight CSS matching picks are asked in turn, later rule first,
//   for `unicode-range` and `cmap`; then next family of stack.

import { brotliDecompressSync } from 'node:zlib';

/** Tags of WOFF2's known tables, in order format numbers them; `cmap` is first. */
const TAGS_WOFF2_KNOWN = ['cmap', 'head', 'hhea', 'hmtx', 'maxp', 'name', 'OS/2', 'post',
  'cvt ', 'fpgm', 'glyf', 'loca', 'prep', 'CFF '];

/** Base64 payload of `data:` source, as `src` descriptor serialises it. */
const PATTERN_SOURCE = /url\(\s*["']?data:[^;,]*;base64,([A-Za-z0-9+/=]+)/;

/** Codepoints each face source maps, so pages sharing one shell decode each face once. */
const HELD_BY_SOURCE = new Map<string, Set<number>>();

/** One `@font-face` rule as browser's CSSOM serialises it. */
export interface Declared {
  family: string;
  weight: string;
  range: string;
  source: string;
}

/** One `@font-face` rule, with codepoints its file maps. */
export interface Face {
  family: string;
  weights: [number, number];
  ranges: [number, number][];
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

/** Read codepoints face of one `data:` source maps; throw where source is not inlined. */
function heldOf(source: string): Set<number> {
  const known = HELD_BY_SOURCE.get(source);
  if (known !== undefined) return known;
  const payload = PATTERN_SOURCE.exec(source)?.[1];
  if (payload === undefined) {
    throw new Error(`Face is inlined as \`data:\` source; got \`${source.slice(0, 60)}\`.`);
  }
  const held = codepointsOfCmap(cmapOf(Buffer.from(payload, 'base64')));
  HELD_BY_SOURCE.set(source, held);
  return held;
}

/** Read weight descriptor, keyword or number, single or range, as its two bounds. */
function weightsOf(descriptor: string): [number, number] {
  const weights = descriptor.trim().split(/\s+/)
    .map((word) => word === 'bold' ? 700 : word === 'normal' || word === '' ? 400 : Number(word));
  return [weights[0] ?? 400, weights[1] ?? weights[0] ?? 400];
}

/** Read `unicode-range` descriptor as inclusive bounds; empty where rule sets none. */
function rangesOf(descriptor: string): [number, number][] {
  const ranges: [number, number][] = [];
  for (const range of descriptor.split(',')) {
    const bounds = /U\+([0-9A-Fa-f?]+)(?:-([0-9A-Fa-f]+))?/i.exec(range.trim());
    if (bounds === null) continue;
    const start = bounds[1] ?? '0';
    // Wildcard `?` spans every hex digit it stands for, as `U+4??` is `U+400-4FF`.
    ranges.push(bounds[2] !== undefined ? [parseInt(start, 16), parseInt(bounds[2], 16)] :
      [parseInt(start.replace(/\?/g, '0'), 16), parseInt(start.replace(/\?/g, 'F'), 16)]);
  }
  return ranges;
}

/** Read family names of font stack, unquoted and lowercase, as CSS compares them. */
export function familiesOf(stack: string): string[] {
  return (stack.match(/\s*(?:"[^"]*"|'[^']*'|[^,]+)/g) ?? [])
    .map((family) => family.trim().replace(/^["']|["']$/g, '').toLowerCase())
    .filter((family) => family.length > 0);
}

/** Read every `@font-face` rule page declares, with what its file maps. */
export function facesOf(declared: Declared[]): Face[] {
  return declared.map((rule) => ({
    family: familiesOf(rule.family)[0] ?? '',
    weights: weightsOf(rule.weight),
    ranges: rangesOf(rule.range),
    held: heldOf(rule.source),
  }));
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

/** Name face of stack that draws `codepoint` at `weight`; none where face of system would. */
export function faceDrawing(faces: Face[], families: string[], weight: number, codepoint: number):
    Face | undefined {
  for (const family of families) {
    const own = faces.filter((face) => face.family === family);
    if (own.length === 0) return undefined;
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
