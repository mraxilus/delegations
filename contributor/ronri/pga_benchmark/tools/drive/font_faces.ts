// Write bytes of each font face page ships into file of its own, and declare each `@font-face`
//   rule with file it names, as `written.json` holds it; not Nim because rules are what browser
//   read out of page's own stylesheet (`text.ts`), and this module is half of harness that
//   Playwright's API forces into node (see `main.ts`).
//   Bytes come out of built page, as `data:` sources its rules carry, rather than out of store,
//     so `koch drive` reads bytes viewer receives (`font_stacks.nim` of curator reads each file).
//   File is named by SHA-256 digest of its bytes, so pages sharing one shell write each font face
//     once, and name holds to bytes. Files lie in folder `files` beside `written.json`, which names
//     each relative to its own folder. That folder is cleared first, so it holds only files this
//     run writes.

import { createHash } from 'node:crypto';
import { mkdirSync, rmSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import type { Rule } from './text';

/** Folder beside `written.json` holding file of each font face pages ship. */
const DIRECTORY_FILES = 'files';

/** Subtype of font media type and base64 payload of `data:` source, as `src` serialises it. */
const PATTERN_SOURCE = /url\(\s*["']?data:font\/([a-z0-9]+)[^;,]*;base64,([A-Za-z0-9+/=]+)/;

/** File each `data:` source is written to this run, so pages sharing one shell write it once. */
const LUT_FILE_BY_SOURCE = new Map<string, string>();

/** One `@font-face` rule as `written.json` holds it: descriptors, and file its source names. */
export interface Declared {
  family: string;
  weight: string;
  range: string;
  file: string;
}

/** Clear folder of font face files beside `written.json`, so it holds only files run writes. */
export function clearFontFaces(directory: string): void {
  const folder = join(directory, DIRECTORY_FILES);
  rmSync(folder, { recursive: true, force: true });
  mkdirSync(folder, { recursive: true });
  LUT_FILE_BY_SOURCE.clear();
}

/** Write bytes of one `data:` source into folder, named by their digest, and name file; throw
 *  where source is not inlined font. */
function writeFontFace(source: string, folder: string): string {
  const [, subtype, payload] = PATTERN_SOURCE.exec(source) ?? [];
  if (subtype === undefined || payload === undefined) {
    const opening = source.slice(0, 60);
    throw new Error(`Font face is inlined as base64 \`data:\` source of font; got \`${opening}\`.`);
  }
  const bytes = Buffer.from(payload, 'base64');
  const file = `${createHash('sha256').update(bytes).digest('hex')}.${subtype}`;
  writeFileSync(join(folder, file), bytes);
  return file;
}

/** Declare each rule with file its font face is written to, relative to `directory`, writing each
 *  source once this run; throw where source is not inlined font. */
export function writeFontFaces(rules: Rule[], directory: string): Declared[] {
  return rules.map((rule) => {
    let file = LUT_FILE_BY_SOURCE.get(rule.source);
    if (file === undefined) {
      file = join(DIRECTORY_FILES, writeFontFace(rule.source, join(directory, DIRECTORY_FILES)));
      LUT_FILE_BY_SOURCE.set(rule.source, file);
    }
    return { family: rule.family, weight: rule.weight, range: rule.range, file };
  });
}
