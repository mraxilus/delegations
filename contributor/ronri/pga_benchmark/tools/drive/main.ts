// Render each page `drive` builds, and fail where face of system draws character beyond
//   ASCII; not Nim because question is browser's own cascade, asked through Playwright's API,
//   which Nim reaches only through glue that would leave every expression run inside page
//   unchecked string.
//   Run by `nim r tools/build.nim drive`, which builds every page, wraps each as publish host
//     does into `build/hosted/<name>.html`, and names each file here as argument.
//   Method is second that CONTRIBUTOR.md, Pages and assets, admits: font stack of each
//     element, as browser computes it, resolved against `cmap` of each face page ships
//     (`faces.ts`). Computed style reads every element, hidden ones too, so tab and filter
//     state need no driving, and no glyph is drawn, so verdict moves with no machine's fonts.
//     Rejected: `CSS.getPlatformFontsForNode`, which answers for text laid out alone, so every
//     tab, filter and closed row would need driving open first.
//   Face that browser refuses to load is finding too: its `cmap` reads whole here, yet viewer
//     gets face of system for every character it was declared for.
//   Cost: character is resolved alone, as `cmap` maps it. Browser picks face per cluster, so
//     combining mark whose base face lacks it can draw from face this does not name.
//   Chromium is one `PGA_CHROMIUM` names, else Playwright's own, which `package-lock.json`
//     pins through `@playwright/test` and `drive` fetches first.

import { chromium, type Browser } from '@playwright/test';
import { basename } from 'node:path';
import { pathToFileURL } from 'node:url';
import { faceDrawing, facesOf, familiesOf } from './faces';
import { codepointText, report, type Finding } from './report';
import { readWritten } from './text';

/** Variable naming Chromium to drive in place of Playwright's own. */
const VARIABLE_CHROMIUM = 'PGA_CHROMIUM';

/** Exit code where any finding stands, or harness failed, as driver's own. */
const EXIT_FINDING = 1;

/** Exit code where command line names no page, as driver's usage error. */
const EXIT_USAGE = 2;

/** Render one page, and say every finding it holds. */
async function pageChecked(browser: Browser, path: string): Promise<Finding[]> {
  const name = basename(path, '.html');
  const findings: Finding[] = [];
  const page = await browser.newPage();
  await page.goto(pathToFileURL(path).href);
  const written = await readWritten(page);
  await page.close();

  // Hold every face to loading, since one refused draws nothing it declares.
  for (const face of written.loaded) {
    if (face.status === 'loaded') continue;
    findings.push({
      page: name,
      element: `@font-face ${face.family} ${face.weight}`,
      message: 'Face does not load',
      value: face.status,
    });
  }

  // Resolve every character beyond ASCII down stack of element drawing it.
  const faces = facesOf(written.declared);
  const counted = new Set<number>();
  for (const run of written.runs) {
    const families = familiesOf(run.stack);
    for (const codepoint of run.codepoints) {
      counted.add(codepoint);
      if (faceDrawing(faces, families, run.weight, codepoint) !== undefined) continue;
      findings.push({
        page: name,
        element: run.element,
        message: 'Character drawn by face of system',
        value: codepointText(codepoint),
      });
    }
  }
  console.log(
    `Rendered ${name}: ${written.count_elements} elements, ${written.runs.length} strings ` +
      `beyond ASCII, ${counted.size} distinct characters, ${faces.length} faces.`,
  );
  return findings;
}

/** Render every page command line names, and say exit code. */
async function main(): Promise<number> {
  const paths = process.argv.slice(2);
  if (paths.length === 0) {
    console.error('Usage: node build/drive/main.js <page.html>...');
    return EXIT_USAGE;
  }
  const named = process.env[VARIABLE_CHROMIUM] ?? '';
  const browser = await chromium.launch(named.length > 0 ? { executablePath: named } : {});
  const findings: Finding[] = [];
  try {
    for (const path of paths) findings.push(...await pageChecked(browser, path));
  } finally {
    await browser.close();
  }
  return report(findings) ? EXIT_FINDING : 0;
}

main().then(
  (code) => process.exit(code),
  (error: unknown) => {
    console.error(error instanceof Error ? error.message : String(error));
    process.exit(EXIT_FINDING);
  },
);
