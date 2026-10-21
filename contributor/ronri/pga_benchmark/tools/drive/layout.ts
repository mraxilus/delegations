// Read where two blocks of card touch, as browser lays page out; not Nim because each read runs
//   inside page through Playwright's `evaluate`, as `text.ts` says.
//   Card is element of class `card`. Its children that draw box read in order, summary of
//     `details` among them, and two in turn that share column and stand closer than `GAP_MIN`
//     are one crowded pair. Card that is `details` opens first, so its body lays out.
//   Read runs once for each tab page offers, radio input of `nav.tabs`, since card behind other
//     tab draws no box. Read precedes `readWritten`, whose `display: revert` lays page out anew.
//   Cost: page is read at one viewport, Playwright's default; card that `@media` lays out
//     otherwise at other width is unread. Pair side by side, as columns of grid, is not compared.

import type { Page } from '@playwright/test';

/** Least gap, in CSS pixels, between two blocks of card that stack. */
export const GAP_MIN = 4;

/** One pair of blocks of card that stand closer than `GAP_MIN`. */
export interface Crowded {
  element: string;
  between: string;
  gap: number;
}

/** Read every pair of blocks of card that stand closer than `GAP_MIN`, on each tab of page. */
export async function readCrowded(page: Page): Promise<Crowded[]> {
  return await page.evaluate(async (gap_min: number) => {
    await document.fonts.ready;
    const crowded: Crowded[] = [];
    const keys = new Set<string>();

    // Name element by tag, id and classes, as `text.ts` names it.
    const named = (element: Element): string => {
      const classes = (element.getAttribute('class') ?? '').split(/\s+/)
        .filter((name) => name.length > 0).map((name) => `.${name}`).join('');
      return `${element.tagName.toLowerCase()}${element.id ? `#${element.id}` : ''}${classes}`;
    };

    // Read pairs of one card as laid out now, each pair once over every tab.
    const readCard = (card: Element): void => {
      const blocks = [...card.children].filter((child) => {
        const box = child.getBoundingClientRect();
        return box.width > 0 && box.height > 0;
      });
      for (let k = 1; k < blocks.length; k++) {
        const above = blocks[k - 1]!.getBoundingClientRect();
        const below = blocks[k]!.getBoundingClientRect();
        const is_column_shared = below.left < above.right && above.left < below.right;
        if (!is_column_shared || below.top <= above.top) continue;
        const gap = Math.round(below.top - above.bottom);
        if (gap >= gap_min) continue;
        const pair = {
          element: named(card),
          between: `${named(blocks[k - 1]!)}, ${named(blocks[k]!)}`,
          gap,
        };
        const key = `${pair.element}\n${pair.between}`;
        if (keys.has(key)) continue;
        keys.add(key);
        crowded.push(pair);
      }
    };

    for (const details of document.querySelectorAll('details.card')) {
      (details as HTMLDetailsElement).open = true;
    }
    const tabs = [...document.querySelectorAll<HTMLInputElement>('nav.tabs input[type="radio"]')];
    for (const tab of tabs.length > 0 ? tabs : [null]) {
      if (tab !== null) tab.checked = true;
      for (const card of document.querySelectorAll('.card')) readCard(card);
    }
    return crowded;
  }, GAP_MIN);
}
