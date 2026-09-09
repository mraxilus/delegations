// Checks for what drawer's own list costs, and for how it is kept up to date; not Nim because
//   crossing forfeits check compiler makes over bodies naming `list_objects`, `rows_pending`
//   and `refreshObjectsUI`, page's own scope which `page.d.ts` states.
//   Row reader cannot see does not build form it would edit with: every row used to build
//   whole edit form -- label field, ink picker, and grid with input per basis element -- and
//   let stylesheet hide it, which at this size was tens of thousands of elements on page and
//   most of second frozen on one tap.

import type { Page } from '@playwright/test';
import { report } from './report';

/** Elements one collapsed row may cost, with slack for rest of page.
 *
 *  Bound per row rather than outright: row count is scene's, and check written against fixed
 *  ceiling stops meaning anything moment capacity moves.
 */
const ELEMENTS_ROW_MAX = 12;

/** Open drawer and its objects section, then wait for list to stand complete.
 *
 *  List nobody is looking at builds nothing, which is point of gate this check is on other
 *  side of. It fills across frames rather than in one block, which is also what reader sees.
 *  Waited against scene's own count rather than size that was loaded, since list is one row
 *  per live object either way.
 */
async function openObjects(page: Page): Promise<void> {
  await page.evaluate(() => {
    const section = document.querySelector('.section[data-section="objects"]');
    if (!drawer.classList.contains('open')) document.getElementById('button-drawer')?.click();
    if (!(section?.classList.contains('open') ?? false)) {
      (section?.querySelector('.section-header') as HTMLElement | null)?.click();
    }
  });
  await page.waitForFunction(
    () => document.getElementById('objects-list')?.children.length === nimSceneCount(),
    null, { timeout: 120000 },
  );
}

/** Drive objects list open, and assert closed rows build no forms. */
export async function driveObjectsList(page: Page, objects: number): Promise<void> {
  await openObjects(page);
  const standing = await page.evaluate(() => ({
    elements: document.querySelectorAll('*').length,
    rows: document.querySelectorAll('#objects-list > *').length,
    forms: document.querySelectorAll('#objects-list .object-edit').length,
  }));
  report(
    'a closed row builds no edit form, so the page holds thousands of elements and not tens',
    standing.rows >= objects && standing.forms === 0 &&
      standing.elements < ELEMENTS_ROW_MAX * standing.rows,
    `${standing.elements} elements over ${standing.rows} rows ` +
      `(${(standing.elements / standing.rows).toFixed(1)} each), ${standing.forms} edit forms`,
  );

  // Keeps guard above from being way to break editing rather than way to make it cheap.
  const opened = await page.evaluate(() => {
    document.querySelector('.section[data-section="objects"]')?.classList.add('open');
    (document.querySelector('#objects-list .object-edit-toggle') as HTMLElement | null)?.click();
    const open = document.querySelector('#objects-list .object-edit.open');
    return {
      forms: document.querySelectorAll('#objects-list .object-edit').length,
      inputs: open === null ? 0 : open.querySelectorAll('input').length,
    };
  });
  report(
    'and opening a row builds one, with its coefficient grid intact',
    opened.forms === 1 && opened.inputs >= 16,
    `${opened.forms} form, ${opened.inputs} inputs in it`,
  );
  await page.evaluate(() => {
    (document.querySelector('#objects-list .object-edit-cancel') as HTMLElement | null)?.click();
  });
  await page.waitForFunction(
    () => document.querySelectorAll('#objects-list .object-edit').length === 0,
    null, { timeout: 8000, polling: 'raf' },
  );
}

/** Assert edit from selection menu reaches its row, list built or not.
 *
 *  With objects section shut its rows do not exist, and opening panel used to query that row
 *  at once, find none, and never scroll: panel opened onto top of list with wanted row
 *  thousands of pixels down it. Now it waits for row. Deep handle, so row stands only after
 *  most of list.
 */
export async function driveEditFromMenu(page: Page): Promise<void> {
  const reached = await page.evaluate(async () => {
    // Shut section and drop its rows, state load with section shut leaves list in.
    document.querySelector('.section[data-section="objects"]')?.classList.remove('open');
    drawer.classList.remove('open');
    list_objects.innerHTML = '';
    signatures_row.clear();
    await new Promise((done) => setTimeout(done, 200));

    const handle = nimSceneHandlesCreated()[40] ?? 0;
    const started = performance.now();
    nimSelectOnly(handle);
    openPanelTo(handle);
    let frames = 0;
    while (rows_pending !== null && frames < 600) {
      await new Promise((done) => requestAnimationFrame(() => done(null)));
      frames += 1;
    }
    await new Promise((done) => setTimeout(done, 300));
    const row = list_objects.querySelector('.object-row[data-handle="' + handle + '"]');
    const box = row === null ? null : row.getBoundingClientRect();
    return {
      frames, milliseconds: performance.now() - started,
      is_in_view: box !== null && box.top >= -1 && box.top < window.innerHeight,
      top: box === null ? null : box.top,
      has_form: row !== null && row.querySelector('.coefficient-grid') !== null,
      rows: list_objects.children.length, count: nimSceneCount(),
    };
  });
  report(
    'edit from the selection menu scrolls to the row once it stands, form open',
    reached.is_in_view && reached.has_form && reached.frames > 1 &&
      reached.rows === reached.count,
    `row top ${reached.top === null ? 'none' : reached.top.toFixed(0)} px after ` +
      `${reached.frames} frames of building, form ${reached.has_form}, ${reached.rows} rows`,
  );
  await page.evaluate(() => {
    endEditSession();
    nimSelectClear();
    refreshObjectsUI();
  });
  await page.waitForFunction(() => rows_pending === null, null, { timeout: 120000 });
}

/** Assert list reconciles against what is standing rather than rebuilding.
 *
 *  Two properties, and first is what makes second safe to rely on: refresh that changes
 *  nothing keeps very same elements, and refresh that changes one row keeps every other one.
 *  Held on element identity rather than on clock, so it cannot flake -- and identity is
 *  exactly claim, since rebuilt row is different object however fast it was made.
 */
export async function driveReconcile(page: Page): Promise<void> {
  const reconciled = await page.evaluate(() => {
    const rowsNow = (): Element[] =>
      Array.from(document.querySelectorAll('#objects-list > *'));
    const isSame = (a: Element[], b: Element[]): boolean =>
      a.length === b.length && a.every((node, i) => node === b[i]);

    const before_idle = rowsNow();
    refreshObjectsUI();
    const after_idle = rowsNow();
    const handle = nimSceneHandles()[0] ?? 0;
    const before_hide = rowsNow();
    nimSetVisible(handle, false);
    refreshObjectsUI();
    const after_hide = rowsNow();
    let moved = 0;
    for (let i = 0; i < after_hide.length; i += 1) {
      if (after_hide[i] !== before_hide[i]) moved += 1;
    }
    nimSetVisible(handle, true);
    refreshObjectsUI();
    return {
      is_idle_kept: isSame(before_idle, after_idle), touched_by_hide: moved,
      rows: after_hide.length,
    };
  });
  report(
    'an unchanged refresh writes nothing, and a hide rebuilds one row of a thousand',
    reconciled.is_idle_kept && reconciled.touched_by_hide === 1,
    `idle kept every element: ${reconciled.is_idle_kept}; a hide rebuilt ` +
      `${reconciled.touched_by_hide} of ${reconciled.rows} rows`,
  );
}

/** Assert diagnostics tick writes rows that moved and no others.
 *
 *  Every one of those writes is text node browser must re-style and re-lay out afterwards, and
 *  that work lands in what is left of frame rather than in tick's own row -- so tick that
 *  looked like few milliseconds of script was closer to twice that of frame, several times
 *  second, which is what reader saw as stutter.
 */
export async function driveTickWrites(page: Page): Promise<void> {
  const written = await page.evaluate(async () => {
    const wait = (milliseconds: number): Promise<void> =>
      new Promise((done) => setTimeout(done, milliseconds));
    if (!drawer.classList.contains('open')) document.getElementById('button-drawer')?.click();
    for (const node of document.querySelectorAll('.diagnostic-node')) {
      node.classList.add('open');
    }
    await wait(400);

    const descriptor = Object.getOwnPropertyDescriptor(Node.prototype, 'textContent');
    let writes = 0;
    Object.defineProperty(Node.prototype, 'textContent', {
      ...descriptor,
      set(value: string) {
        writes += 1;
        descriptor?.set?.call(this, value);
      },
    });
    const scope = globalThis as unknown as { refreshDiagnostics: typeof refreshDiagnostics };
    const original = scope.refreshDiagnostics;
    const per_tick: number[] = [];
    scope.refreshDiagnostics = function (): void {
      writes = 0;
      original();
      per_tick.push(writes);
    };
    await wait(1600);
    scope.refreshDiagnostics = original;
    if (descriptor !== undefined) {
      Object.defineProperty(Node.prototype, 'textContent', descriptor);
    }
    return {
      ticks: per_tick.length, worst: Math.max(0, ...per_tick),
      rows: document.querySelectorAll('[id^="diagnostic-"]').length,
    };
  });
  report(
    'the diagnostics tick writes only the rows that moved',
    written.ticks > 2 && written.worst > 0 && written.worst <= 20,
    `${written.worst} text writes at worst over ${written.ticks} ticks, ` +
      `${written.rows} rows on the tree`,
  );
}

/** Assert slow figures are redrawn on their own slower clock, and not at all when shut.
 *
 *  Exceedance curve covers whole window and sparkline and ring medians span seconds: none of
 *  them can change inside one tick, and redrawing them at panel's own rate was half of it.
 *  Counted rather than timed -- call count cannot flake.
 */
export async function driveTickCadence(page: Page): Promise<void> {
  const cadence = await page.evaluate(async () => {
    const wait = (milliseconds: number): Promise<void> =>
      new Promise((done) => setTimeout(done, milliseconds));
    const scope = globalThis as unknown as {
      drawExceedance: typeof drawExceedance; refreshDiagnostics: typeof refreshDiagnostics;
    };
    const original_curve = scope.drawExceedance;
    let curves = 0;
    scope.drawExceedance = function (): void {
      curves += 1;
      original_curve();
    };
    const original_tick = scope.refreshDiagnostics;
    let ticks = 0;
    scope.refreshDiagnostics = function (): void {
      ticks += 1;
      original_tick();
    };
    // Axis switch redraws curve on spot, which is its own claim and not tick's: four
    //   presses inside window leave switch as it was found and add four redraws that no
    //   cadence asked for.
    const toggle = document.getElementById('toggle-exceedance-log');
    await wait(1200);
    for (let i = 0; i < 4; i += 1) {
      toggle?.click();
      await wait(120);
    }
    await wait(1300);
    const open = { ticks, curves };

    // Whole tick is skipped with section collapsed inside open drawer: both canvases would
    //   otherwise fall back to made-up width and draw for nobody.
    const section = document.querySelector('.section[data-section="diagnostics"]');
    section?.classList.remove('open');
    ticks = 0;
    curves = 0;
    await wait(1500);
    const collapsed = { ticks, curves };
    section?.classList.add('open');
    scope.drawExceedance = original_curve;
    scope.refreshDiagnostics = original_tick;
    return { open, collapsed };
  });
  report(
    'the panel redraws its slower figures on their own slower clock',
    cadence.open.ticks >= 8 && cadence.open.curves > 0 &&
      cadence.open.curves * 3 <= cadence.open.ticks,
    `${cadence.open.curves} curve redraws over ${cadence.open.ticks} ticks`,
  );
  report(
    'and a collapsed diagnostics section costs the tick nothing at all',
    cadence.collapsed.curves === 0,
    `${cadence.collapsed.curves} curve redraws over ${cadence.collapsed.ticks} ticks ` +
      'with the section shut',
  );
}

/** Assert burst of pointer and wheel events costs one pick and one dolly per frame.
 *
 *  Pick walks every live handle, so answer computed per input event and thrown away is most
 *  expensive thing pointer can ask for; trackpad reports several wheel notches between two
 *  frames and mouse several moves.
 */
export async function drivePerFrame(page: Page): Promise<void> {
  const counted = await page.evaluate(async () => {
    const canvas = document.getElementById('gl') as HTMLCanvasElement;
    const rect = canvas.getBoundingClientRect();
    const x = rect.left + rect.width * 0.5, y = rect.top + rect.height * 0.5;
    let picks = 0, dollies = 0;
    const scope = globalThis as unknown as {
      nimUpdateHover: typeof nimUpdateHover; nimCameraDollyAt: typeof nimCameraDollyAt;
    };
    const original_hover = scope.nimUpdateHover;
    scope.nimUpdateHover = function (width: number, height: number): void {
      picks += 1;
      original_hover(width, height);
    };
    const original_dolly = scope.nimCameraDollyAt;
    scope.nimCameraDollyAt = function (
      factor: number, width: number, height: number,
    ): void {
      dollies += 1;
      original_dolly(factor, width, height);
    };
    const send = (kind: string, at_x: number, at_y: number, buttons: number): void => {
      canvas.dispatchEvent(new PointerEvent(kind, {
        pointerId: 1, pointerType: 'mouse', isPrimary: true, bubbles: true, cancelable: true,
        clientX: at_x, clientY: at_y, buttons, button: buttons === 0 ? -1 : 0,
      }));
    };

    send('pointerdown', x, y, 1);
    picks = 0; // Press picks inside its own handler, by design.
    dollies = 0;
    let frames = 0;
    await new Promise((done) => {
      const step = (): void => {
        // Six of each frame, which is ordinary trackpad against sixty-hertz display. All
        //   notches one way: frame's travel summing to nothing is no zoom, and frame loop
        //   rightly does not spend pick on it.
        for (let k = 0; k < 6; k += 1) {
          send('pointermove', x + k * 3, y + k * 2, 1);
          canvas.dispatchEvent(new WheelEvent('wheel', {
            deltaY: frames % 2 ? 6 : -6, clientX: x, clientY: y,
            bubbles: true, cancelable: true,
          }));
        }
        frames += 1;
        if (frames < 30) requestAnimationFrame(step); else requestAnimationFrame(() => done(null));
      };
      requestAnimationFrame(step);
    });
    send('pointerup', x, y, 0);
    scope.nimUpdateHover = original_hover;
    scope.nimCameraDollyAt = original_dolly;
    return { frames, picks, dollies, events: frames * 6 };
  });
  report(
    'a burst of pointer and wheel events costs one pick and one dolly a frame, not one each',
    counted.picks <= counted.frames + 2 && counted.dollies <= counted.frames + 2 &&
      counted.picks > 0 && counted.dollies > 0,
    `${counted.events} moves and ${counted.events} notches over ${counted.frames} frames ` +
      `drew ${counted.picks} picks and ${counted.dollies} dollies`,
  );
  await page.evaluate(() => {
    if (drawer.classList.contains('open')) document.getElementById('button-drawer')?.click();
  });
}
