// Write what collector read, page by page, as `written.json` for `koch drive` to resolve; not Nim
//   because harness that reads it runs in node under Playwright (see `main.ts`), and writing it
//   is all left.
//   Shape is one `curator/audit/src/font_stacks.nim` gives: each page maps to `runs`, `declared`
//     and `refused`. Data alone crosses: `koch drive` resolves each character, holds control
//     page and words each finding (CONTRIBUTOR.md, Pages and assets).
//   Rule names file holding its bytes, since resolver reads `cmap` out of file. Each font face is
//     inlined as `data:` source (`design/font_faces.nim`), so its bytes are written once into
//     `files/` beside `written.json`, named by their SHA-256. They are bytes viewer receives, out
//     of page itself rather than out of store.
//   Every page read has entry, empty or not, so page that draws nothing past ASCII reads as read.

import { createHash } from 'node:crypto';
import { mkdirSync, rmSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import type { Loaded, Run, Written } from './text';

/** Folder beside `written.json` that holds each font face file pages ship. */
const FOLDER_FILES = 'files';

/** Format and base64 payload of `data:` source, as `src` descriptor serialises it. */
const PATTERN_SOURCE = /url\(\s*["']?data:font\/([a-z0-9]+);base64,([A-Za-z0-9+/=]+)/;

/** One `@font-face` rule, with file holding its bytes, as resolver reads it. */
interface Rule {
  family: string;
  weight: string;
  range: string;
  file: string;
}

/** Three lists `written.json` holds for one page. */
interface Lists {
  runs: Run[];
  declared: Rule[];
  refused: Loaded[];
}

/** Write what collector read on every page as JSON, with each font face file beside it. */
export function writeWritten(path: string, pages: Map<string, Written>): void {
  const folder = dirname(path);
  const lut_file_by_source = new Map<string, string>();
  // Write bytes of one `data:` source once, and name their file; throw where source is not inlined.
  const writeFontFace = (source: string): string => {
    const known = lut_file_by_source.get(source);
    if (known !== undefined) return known;
    const [, format, payload] = PATTERN_SOURCE.exec(source) ?? [];
    if (format === undefined || payload === undefined) {
      throw new Error(`Font face is inlined as \`data:\` source; got \`${source.slice(0, 60)}\`.`);
    }
    const bytes = Buffer.from(payload, 'base64');
    const file = `${FOLDER_FILES}/${createHash('sha256').update(bytes).digest('hex')}.${format}`;
    writeFileSync(join(folder, file), bytes);
    lut_file_by_source.set(source, file);
    return file;
  };

  // Clear files earlier run wrote, so folder holds only those this run names.
  rmSync(join(folder, FOLDER_FILES), { recursive: true, force: true });
  mkdirSync(join(folder, FOLDER_FILES), { recursive: true });

  // Name file of each rule, and keep each font face browser did not load.
  const document: Record<string, Lists> = {};
  for (const [page, written] of pages) {
    document[page] = {
      runs: written.runs,
      declared: written.declared.map((rule) => ({
        family: rule.family,
        weight: rule.weight,
        range: rule.range,
        file: writeFontFace(rule.source),
      })),
      refused: written.loaded.filter((font_face) => font_face.status !== 'loaded'),
    };
  }
  writeFileSync(path, `${JSON.stringify(document, null, 2)}\n`);
}
