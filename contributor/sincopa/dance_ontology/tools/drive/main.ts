// Render each page `drive` builds, and write where face of system would draw character beyond
//   ASCII; not Nim because question is browser's own cascade, asked through Playwright's API,
//   which Nim reaches only through glue that would leave every expression run inside page
//   unchecked string.
//   Run by `nim r tools/build.nim drive`, which builds every page and control page, wraps each
//     as publish host does into `build/hosted/<name>.html`, and names output file, then each
//     page, here as arguments. Driver judges what this writes (`design/render.nim`); this
//     judges none.
//   Ported from `pga_benchmark`'s `tools/drive/`, which holds reasons for its method: font
//     stack of each element, as browser computes it, resolved against `cmap` of each face page
//     ships (`faces.ts`), second method CONTRIBUTOR.md, Pages and assets, admits. Fix to one
//     is finished only when other is checked.
//   Face that browser refuses to load is written too: its `cmap` reads whole here, yet viewer
//     gets face of system for every character it was declared for.
//   Cost: character is resolved alone, as `cmap` maps it. Browser picks face per cluster, so
//     combining mark whose base face lacks it can draw from face this does not name.
//   Chromium is one `DANCE_CHROMIUM` names, else Playwright's own, which `package-lock.json`
//     pins through `@playwright/test` and `drive` fetches first. `design/shot.nim` reads same
//     variable, so one browser serves both.

import { chromium, type Browser } from '@playwright/test';
import { basename } from 'node:path';
import { pathToFileURL } from 'node:url';
import { faceDrawing, facesOf, familiesOf } from './faces';
import { writeFound, type Found } from './found';
import { readWritten } from './text';

/** Variable naming Chromium to drive in place of Playwright's own. */
const VARIABLE_CHROMIUM = 'DANCE_CHROMIUM';

/** Exit code where harness failed before writing what it found, as driver's own. */
const EXIT_FAILED = 1;

/** Exit code where command line names no output or no page, as driver's usage error. */
const EXIT_USAGE = 2;

/** Render one page, and say what it found there. */
async function pageFound(browser: Browser, path: string): Promise<Found> {
  const name = basename(path, '.html');
  const page = await browser.newPage();
  await page.goto(pathToFileURL(path).href);
  const written = await readWritten(page);
  await page.close();

  // Keep every face browser refused, since one refused draws nothing it declares.
  const found: Found = {
    characters: [],
    faces: written.loaded.filter((face) => face.status !== 'loaded'),
  };

  // Resolve every character beyond ASCII down stack of element drawing it.
  const faces = facesOf(written.declared);
  const counted = new Set<number>();
  for (const run of written.runs) {
    const families = familiesOf(run.stack);
    for (const codepoint of run.codepoints) {
      counted.add(codepoint);
      if (faceDrawing(faces, families, run.weight, codepoint) !== undefined) continue;
      found.characters.push({ element: run.element, codepoint });
    }
  }
  console.log(
    `Rendered ${name}: ${written.count_elements} elements, ${written.runs.length} strings ` +
      `beyond ASCII, ${counted.size} distinct characters, ${faces.length} faces.`,
  );
  return found;
}

/** Render every page command line names, write what each held, and say exit code. */
async function main(): Promise<number> {
  const [output, ...paths] = process.argv.slice(2);
  if (output === undefined || paths.length === 0) {
    console.error('Usage: node build/drive/main.js <found.json> <page.html>...');
    return EXIT_USAGE;
  }
  const named = process.env[VARIABLE_CHROMIUM] ?? '';
  const browser = await chromium.launch(named.length > 0 ? { executablePath: named } : {});
  const found = new Map<string, Found>();
  try {
    for (const path of paths) found.set(basename(path, '.html'), await pageFound(browser, path));
  } finally {
    await browser.close();
  }
  writeFound(output, found);
  return 0;
}

main().then(
  (code) => process.exit(code),
  (error: unknown) => {
    console.error(error instanceof Error ? error.message : String(error));
    process.exit(EXIT_FAILED);
  },
);
