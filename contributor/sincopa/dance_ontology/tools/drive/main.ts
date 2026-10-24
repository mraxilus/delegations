// Read each page `drive` builds, and control page `koch drive` writes, with one collector, and
//   write what it read for `koch drive` to resolve; not Nim because question is browser's own
//   cascade, asked through Playwright's API, which Nim reaches only through glue that would leave
//   every expression run inside page unchecked string.
//   Run by `nim r tools/build.nim drive`, which builds every page, wraps each as publish host
//     does into `build/hosted/<name>.html`, and names output file, then each page, then control
//     page where it stands, here as arguments. Page is named by its file, so control page
//     `build/font-faces/control.html` reads as page `control`.
//   Writes `written.json` (`written.ts`); `koch drive` resolves font stack of each element against
//     `cmap` of each font face page ships, and reports each finding (CONTRIBUTOR.md, Pages and
//     assets). This resolves nothing and judges nothing.
//   Chromium is one `DANCE_CHROMIUM` names, else Playwright's own, which `package-lock.json`
//     pins through `@playwright/test` and `drive` fetches first. `design/shot.nim` reads same
//     variable, so one browser serves both.

import { chromium, type Browser } from '@playwright/test';
import { basename } from 'node:path';
import { pathToFileURL } from 'node:url';
import { readWritten, type Written } from './text';
import { writeWritten } from './written';

/** Variable naming Chromium to drive in place of Playwright's own. */
const VARIABLE_CHROMIUM = 'DANCE_CHROMIUM';

/** Exit code where harness failed before writing what it read, as driver's own. */
const EXIT_FAILED = 1;

/** Exit code where command line names no output or no page, as driver's usage error. */
const EXIT_USAGE = 2;

/** Render one page, and read what it writes and declares. */
async function pageWritten(browser: Browser, path: string): Promise<Written> {
  const page = await browser.newPage();
  await page.goto(pathToFileURL(path).href);
  const written = await readWritten(page);
  await page.close();

  // Say what page holds, so run shows each page was read.
  const counted = new Set(written.runs.flatMap((run) => run.codepoints));
  console.log(
    `Read ${basename(path, '.html')}: ${written.count_elements} elements, ` +
      `${written.runs.length} strings beyond ASCII, ${counted.size} distinct characters, ` +
      `${written.declared.length} font faces.`,
  );
  return written;
}

/** Render every page command line names, write what each held, and say exit code. */
async function main(): Promise<number> {
  const [output, ...paths] = process.argv.slice(2);
  if (output === undefined || paths.length === 0) {
    console.error('Usage: node build/drive/main.js <written.json> <page.html>...');
    return EXIT_USAGE;
  }
  const named = process.env[VARIABLE_CHROMIUM] ?? '';
  const browser = await chromium.launch(named.length > 0 ? { executablePath: named } : {});
  const pages = new Map<string, Written>();
  try {
    for (const path of paths) pages.set(basename(path, '.html'), await pageWritten(browser, path));
  } finally {
    await browser.close();
  }
  writeWritten(output, pages);
  return 0;
}

main().then(
  (code) => process.exit(code),
  (error: unknown) => {
    console.error(error instanceof Error ? error.message : String(error));
    process.exit(EXIT_FAILED);
  },
);
