// Render each page `drive` builds, and write as data what each draws, font faces it ships, and
//   where two blocks of card touch; not Nim because question is browser's own cascade and
//   layout, asked through Playwright's API, which Nim reaches only through glue that would leave
//   every expression run inside page unchecked string.
//   Run by `nim r tools/build.nim drive`, which builds every page and control page of layout,
//     wraps each as publish host does into `build/hosted/<name>.html`, and names output files,
//     then each page, here as arguments (`argumentsHarness` of `render.nim`).
//   Verdict is never here. `koch drive` resolves `written.json` and judges font faces
//     (`font_stacks.nim` of curator; CONTRIBUTOR.md, Pages and assets), and driver judges
//     crowded file (`render.nim`).
//   Collector (`text.ts`) reads each page, and control page `koch drive` writes, which lands as
//     page `control`. Layout (`layout.ts`) reads each page, and control page of layout, which
//     stays out of `written.json`: it is no page project ships, and `koch drive` would judge it
//     as one.
//   Data alone crosses, keyed by page: in `written.json`, shape curator reads, i.e. `runs`,
//     `declared` and `refused`; in crowded file, each pair of blocks of card that touch.
//   Chromium is one `PGA_CHROMIUM` names, else Playwright's own, which `package-lock.json`
//     pins through `@playwright/test` and `drive` fetches first.

import { chromium, type Browser } from '@playwright/test';
import { mkdirSync, writeFileSync } from 'node:fs';
import { basename, dirname } from 'node:path';
import { pathToFileURL } from 'node:url';
import { clearFontFaces, writeFontFaces, type Declared } from './font_faces';
import { readCrowded, type Crowded } from './layout';
import { collect, type Refused, type Run } from './text';

/** Variable naming Chromium to drive in place of Playwright's own. */
const VARIABLE_CHROMIUM = 'PGA_CHROMIUM';

/** Exit code where harness failed before writing what it read, as driver's own. */
const EXIT_FAILED = 1;

/** Exit code where command line names no output or no page, as driver's usage error. */
const EXIT_USAGE = 2;

/** Option naming page read for layout alone; twin of `FLAG_LAYOUT_ONLY` in `render.nim`. */
const FLAG_LAYOUT_ONLY = '--layout-only';

/** Option naming page read for text alone; twin of `FLAG_TEXT_ONLY` in `render.nim`. */
const FLAG_TEXT_ONLY = '--text-only';

/** Text printed on usage error. */
const USAGE = 'Usage: node build/drive/main.js <written.json> <crowded.json> <page.html>... ' +
  `[${FLAG_LAYOUT_ONLY} <page.html>] [${FLAG_TEXT_ONLY} <page.html>]`;

/** What one page writes, as `written.json` holds it for `koch drive`. */
interface Written {
  runs: Run[];
  declared: Declared[];
  refused: Refused[];
}

/** One page command line names, with reads it takes. */
interface Named {
  path: string;
  should_read_layout: boolean;
  should_read_text: boolean;
}

/** What reads of one page gave; read page did not take gives nothing. */
interface Read {
  written?: Written;
  crowded?: Crowded[];
}

/** Read pages command line names after output files, each with reads it takes; none where option
 *  names no page. */
function parsePages(words: string[]): Named[] | undefined {
  const pages: Named[] = [];
  for (let k = 0; k < words.length; k += 1) {
    const word = words[k] ?? '';
    if (word !== FLAG_LAYOUT_ONLY && word !== FLAG_TEXT_ONLY) {
      pages.push({ path: word, should_read_layout: true, should_read_text: true });
      continue;
    }
    k += 1;
    const path = words[k];
    if (path === undefined) return undefined;
    pages.push({
      path,
      should_read_layout: word === FLAG_LAYOUT_ONLY,
      should_read_text: word === FLAG_TEXT_ONLY,
    });
  }
  return pages;
}

/** Render one page, take each read command line asks of it, and say what each gave. */
async function pageRead(browser: Browser, named: Named, directory: string): Promise<Read> {
  const page = await browser.newPage();
  await page.goto(pathToFileURL(named.path).href);
  const read: Read = {};
  const said: string[] = [];

  // Read layout first, since collector shows every element and so lays page out anew.
  if (named.should_read_layout) {
    read.crowded = await readCrowded(page);
    said.push(`${read.crowded.length} crowded pairs`);
  }

  // Collect what page draws, and write each font face it ships beside `written.json`.
  if (named.should_read_text) {
    const collected = await collect(page);
    read.written = {
      runs: collected.runs,
      declared: writeFontFaces(collected.rules, directory),
      refused: collected.refused,
    };
    const codepoints = new Set(collected.runs.flatMap((run) => run.codepoints));
    said.push(
      `${collected.count_elements} elements`,
      `${collected.runs.length} strings beyond ASCII`,
      `${codepoints.size} distinct characters`,
      `${read.written.declared.length} font faces declared`,
      `${collected.refused.length} refused`,
    );
  }
  await page.close();
  console.log(`Rendered ${basename(named.path, '.html')}: ${said.join(', ')}.`);
  return read;
}

/** Write one document mapping each page read to what was read of it, as JSON. */
function writeDocument(path: string, pages: Map<string, unknown>): void {
  mkdirSync(dirname(path), { recursive: true });
  writeFileSync(path, `${JSON.stringify(Object.fromEntries(pages), null, 2)}\n`);
}

/** Render every page command line names, write what each held, and say exit code. */
async function main(): Promise<number> {
  const [path_written, path_crowded, ...words] = process.argv.slice(2);
  const pages = parsePages(words);
  if (path_written === undefined || path_crowded === undefined || pages === undefined ||
      pages.length === 0) {
    console.error(USAGE);
    return EXIT_USAGE;
  }
  const directory = dirname(path_written);
  clearFontFaces(directory);
  const path_chromium = process.env[VARIABLE_CHROMIUM] ?? '';
  const browser = await chromium.launch(
    path_chromium.length > 0 ? { executablePath: path_chromium } : {},
  );
  console.log(`Chromium ${browser.version()} renders each page.`);
  const written = new Map<string, Written>();
  const crowded = new Map<string, Crowded[]>();
  const names = new Set<string>();
  try {
    for (const named of pages) {
      const name = basename(named.path, '.html');
      if (names.has(name)) throw new Error(`Each page read has name of its own; got \`${name}\`.`);
      names.add(name);
      const read = await pageRead(browser, named, directory);
      if (read.written !== undefined) written.set(name, read.written);
      if (read.crowded !== undefined) crowded.set(name, read.crowded);
    }
  } finally {
    await browser.close();
  }
  writeDocument(path_written, written);
  writeDocument(path_crowded, crowded);
  return 0;
}

main().then(
  (code) => process.exit(code),
  (error: unknown) => {
    console.error(error instanceof Error ? error.message : String(error));
    process.exit(EXIT_FAILED);
  },
);
