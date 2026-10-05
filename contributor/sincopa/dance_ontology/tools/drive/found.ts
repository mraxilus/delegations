// Write what render found, page by page, as data for driver to judge; not Nim because harness
//   that finds it runs in node under Playwright (see `main.ts`), and writing it is all left.
//   Data alone crosses: element and codepoint of each character face of system would draw, and
//     family, weight and status of each face that does not load. Wording, control and verdict
//     are Nim's (`design/render.nim`), where suites reach them (Article II.9).
//   Every page rendered has entry, empty or not, so page that raised nothing reads as rendered.

import { writeFileSync } from 'node:fs';

/** One character beyond ASCII that no face page ships would draw, in element that writes it. */
export interface Character {
  element: string;
  codepoint: number;
}

/** One face page declares that browser did not load. */
export interface Refused {
  family: string;
  weight: string;
  status: string;
}

/** What render found on one page. */
export interface Found {
  characters: Character[];
  faces: Refused[];
}

/** Write what render found on every page, each character once per element, as JSON. */
export function writeFound(path: string, found: Map<string, Found>): void {
  const document: Record<string, Found> = {};
  for (const [page, one] of found) {
    const keys = new Set<string>();
    const characters = one.characters.filter((character) => {
      const key = `${character.element}\n${character.codepoint}`;
      if (keys.has(key)) return false;
      keys.add(key);
      return true;
    });
    document[page] = { characters, faces: one.faces };
  }
  writeFileSync(path, `${JSON.stringify(document, null, 2)}\n`);
}
