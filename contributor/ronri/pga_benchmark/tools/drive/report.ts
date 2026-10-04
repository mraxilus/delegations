// Say each finding of render in repository's finding form; not Nim because harness that holds
//   findings runs in node under Playwright (see `main.ts`), and printing them is all left.
//   Form is `<page>: <element>: <message>; got <value>.`, value in backticks, as `guard.nim`
//     renders `<path>:<line>: <message>`: page stands where path does, element where line
//     does, and message ends by echoing offending value (Article IV.4).
//   One finding per page, element and value: element drawn many times names its fault once.

/** One broken rule, at one page and one element, with value that broke it. */
export interface Finding {
  page: string;
  element: string;
  message: string;
  value: string;
}

/** Spell codepoint as Unicode names it, as `U+2603`. */
export function codepointText(codepoint: number): string {
  return `U+${codepoint.toString(16).toUpperCase().padStart(4, '0')}`;
}

/** Render finding as one line. */
export function render(finding: Finding): string {
  return `${finding.page}: ${finding.element}: ${finding.message}; got \`${finding.value}\`.`;
}

/** Print every finding once, in order found, then count; say whether any was found. */
export function report(findings: Finding[]): boolean {
  const lines = [...new Set(findings.map(render))];
  for (const line of lines) console.log(line);
  console.log(`${lines.length} finding(s) in rendered pages.`);
  return lines.length > 0;
}
