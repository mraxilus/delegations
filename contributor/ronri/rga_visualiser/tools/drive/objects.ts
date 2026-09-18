// Checks for what drawer's own list costs, and for how it is kept up to date; not Nim because
//   crossing forfeits check compiler makes over bodies naming `list_objects`, `openPanelTo`
//   and `refreshObjectsUI`, page's own scope which `page.d.ts` states.
//   Row reader cannot see is not built: every row used to be, with whole edit form -- label
//   field, ink picker, and grid with input per basis element -- hidden by stylesheet, which at
//   this size was tens of thousands of elements on page and most of second frozen on one tap;
//   then every row without its form, in slices, which was seconds of list filling instead.

import type { Page } from '@playwright/test';
import { report } from './report';

/** Elements one collapsed row may cost, with slack for rest of page.
 *
 *  Bound per row rather than outright: row count is scene's, and check written against fixed
 *  ceiling stops meaning anything moment capacity moves.
 */
const ELEMENTS_ROW_MAX = 12;

/** Open drawer and its objects section, then wait for list to stand for scene.
 *
 *  List nobody is looking at builds nothing, which is point of gate this check is on other
 *  side of. Rows it builds are those near viewport, so what is waited on is count list says it
 *  stands for, against scene's own count rather than size that was loaded.
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
    () => document.getElementById('objects-list')?.dataset['count'] === String(nimSceneCount()),
    null, { timeout: 120000 },
  );
}

/** Rows window may hold over scroller this tall: screens it covers, over shortest row there is.
 *
 *  Stated here as well as in page (`SCREENS_SLACK_WINDOW`), and that is deliberate: check
 *  reading window out of page would pass whatever page happened to do. Floor of 40 px is well
 *  under 61 px collapsed row measures, so bound is loose where it must be and still tens of rows
 *  against thousands.
 */
const SCREENS_WINDOW = 3;
const PIXELS_ROW_LEAST = 40;
function rowsMost(height_scroller: number): number {
  return Math.ceil((SCREENS_WINDOW * height_scroller) / PIXELS_ROW_LEAST) + 2;
}

/** Assert heading naming section stays reachable while that section's list scrolls under it.
 *
 *  Reader collapsing long list had to scroll all way back to top to reach control that
 *  collapses it. Heading sticks to scroller's own top edge and holds there however far list
 *  runs.
 *  Flush to that edge, with no band above it: sticky offset is inset by scroller's padding, so
 *  heading pinned inside padded scroller cannot cover padding above itself, and rows rode up
 *  through it in plain sight. Clearance chip row needs therefore sits on drawer, outside what
 *  scrolls. Band is sampled rather than inferred -- gap of zero is what *should* follow, and
 *  what is asserted is what reader sees: nothing of list drawn above heading.
 *  Scroll itself is asserted, not only where heading ended: check reading stuck heading while
 *  nothing moved passes on page with no stickiness in it at all.
 *  Desktop answers same rule by bounding its list in its own scrolling region, so heading sits
 *  outside what moves; see `panel.layoutObjects`. One rule, two mechanisms.
 */
export async function driveHeaderPinned(page: Page): Promise<void> {
  await openObjects(page);
  const pinned = await page.evaluate(async () => {
    const scroller = document.querySelector('.drawer-scroll') as HTMLElement | null;
    const heading = document.querySelector(
      '.section[data-section="objects"] .section-header',
    ) as HTMLElement | null;
    if (scroller === null || heading === null) return null;
    const settle = () => new Promise((done) => { requestAnimationFrame(() => done(null)); });
    scroller.scrollTop = 0;
    await settle();
    const started = heading.getBoundingClientRect().top;
    const room = scroller.scrollHeight - scroller.clientHeight;
    scroller.scrollTop = room;
    await settle();
    const box = scroller.getBoundingClientRect();
    const held = heading.getBoundingClientRect();
    // Walk band from scroller's own top edge down to heading's underside, asking page itself
    //   what reader would hit there. Row answering anywhere in it is row drawn above heading.
    //   Swept across width, not down one line: first form sampled midline alone and passed
    //   while rows showed in strip 28px wide down right edge, which is where heading's own
    //   band fell short.
    let bled = 0;
    for (let x = Math.ceil(box.left) + 1; x < box.right - 1; x += 4) {
      for (let y = Math.ceil(box.top) + 1; y < held.bottom - 1; y += 3) {
        // Point answering nothing at all is not row. Written out rather than left to `?.`,
        //   which reports `undefined` there and would count every such point as bleed.
        const hit = document.elementFromPoint(x, y);
        if (hit !== null && hit.closest('.object-row') !== null) bled += 1;
      }
    }
    return {
      moved: scroller.scrollTop,
      room,
      started,
      top: held.top,
      bottom: held.bottom,
      edge: box.top,
      floor: box.bottom,
      bled,
    };
  });
  report(
    "the heading naming a section holds its place while that section's list scrolls under it",
    pinned !== null && pinned.moved > 0
      && pinned.top >= pinned.edge - 0.5 && pinned.bottom <= pinned.floor + 0.5
      && Math.abs(pinned.top - pinned.edge) < 1.5,
    pinned === null ? 'no drawer to scroll'
      : `scrolled ${pinned.moved.toFixed(0)} of ${pinned.room.toFixed(0)} px, and the heading`
        + ` sat at ${pinned.started.toFixed(0)} px and holds at ${pinned.top.toFixed(0)},`
        + ` flush to that scroller's own top edge at ${pinned.edge.toFixed(0)}`,
  );
  report(
    'nothing of that list is drawn above the heading it scrolls under',
    pinned !== null && pinned.bled === 0,
    pinned === null ? 'no drawer to scroll'
      : `${pinned.bled} of the sampled points between the scroller's edge and the heading's`
        + ` underside answered with a row`,
  );
}


/** Assert heading wears its band only while rows are passing under it.
 *
 *  Band that is always on is slab on every section, announcing covering it is not doing.
 *  Read as colour rather than as class: class is mechanism, fill is what reader sees, and
 *  check that watched class would pass on heading whose rule had been deleted.
 *  `elementFromPoint` cannot stand in for this. Hit testing answers with element whatever its
 *  fill, so `driveHeaderPinned`'s own sweep reports band covering even where band is clear --
 *  it holds geometry, and this holds paint.
 */
/** Read how opaque computed fill is, whatever notation browser reported it in.
 *
 *  `rgb(…)` and `color(srgb …)` are opaque; `rgba(…, a)` and `color(srgb … / a)` carry own
 *  alpha. Written because fill is `color-mix`, which computes to `color(srgb …)`, and check
 *  spelling out one notation holds syntax where it means to hold paint.
 *  Said again inside `waitForFunction` above, which runs in page and cannot see this.
 */
function alphaOfFill(fill: string): number {
  const sliced = fill.match(/\/\s*([0-9.]+)\s*\)/);
  if (sliced !== null) return Number(sliced[1]);
  const listed = fill.match(/^rgba\(.*,\s*([0-9.]+)\s*\)$/);
  if (listed !== null) return Number(listed[1]);
  return fill === 'transparent' ? 0 : 1;
}


export async function driveHeaderBanded(page: Page): Promise<void> {
  await openObjects(page);
  // Read fill and where scroller stands together: check that cannot say how far it scrolled
  //   cannot tell band that failed to arrive from list too short to have one.
  const readAt = async (
    where: 'top' | 'floor',
  ): Promise<{
    fill: string; moved: number; stuck: boolean; edges: number; due: boolean; worn: number;
  }> => {
    await page.evaluate((edge) => {
      const scroller = document.querySelector('.drawer-scroll') as HTMLElement | null;
      if (scroller === null) return;
      scroller.scrollTop = edge === 'top' ? 0 : scroller.scrollHeight - scroller.clientHeight;
    }, where);
    // Settled against fill itself rather than against clock: observer reports after layout and
    //   fill eases in over `--anim`, both of which are page's business rather than this check's.
    //   Waited for fill to *finish*, not merely to start. Half-eased band reports as `rgba(…)`
    //   carrying its alpha, and reading there caught it at 0.66 -- true of that instant and
    //   not of anything worth asserting.
    //   Opacity is what is waited for, never notation. Fill is `color-mix`, which computes to
    //   `color(srgb …)` rather than to `rgb(…)`, and check naming either spelling holds syntax
    //   where it means to hold paint. `alphaOfFill` below says it once for this file; page
    //   cannot see that, so predicate here says it again -- two copies, each naming other.
    await page.waitForFunction((edge) => {
      const heading = document.querySelector('.section[data-section="objects"] .section-header');
      if (heading === null) return false;
      const fill = getComputedStyle(heading).backgroundColor;
      const sliced = fill.match(/\/\s*([0-9.]+)\s*\)/);
      const listed = fill.match(/^rgba\(.*,\s*([0-9.]+)\s*\)$/);
      const alpha = sliced !== null ? Number(sliced[1])
        : listed !== null ? Number(listed[1]) : (fill === 'transparent' ? 0 : 1);
      return edge === 'top' ? alpha === 0 : alpha === 1;
    }, where, { timeout: 8000 }).catch(() => undefined);
    return page.evaluate(() => {
      const heading = document.querySelector('.section[data-section="objects"] .section-header');
      const scroller = document.querySelector('.drawer-scroll') as HTMLElement | null;
      return {
        fill: heading === null ? 'no heading' : getComputedStyle(heading).backgroundColor,
        moved: scroller === null ? -1 : Math.round(scroller.scrollTop),
        // Mechanism beside outcome: band that never arrives is either class never put on or
        //   rule that stopped answering to it, and detail line has to tell those apart.
        stuck: heading !== null && heading.classList.contains('stuck'),
        edges: document.querySelectorAll('.section-edge').length,
        // Every heading, not only this one. Topmost section's sentinel sits exactly at
        //   scroller's top edge at rest, and condition that read `<=` called it pinned from
        //   first paint -- band nobody could see while band was drawer's own ground, pill
        //   plainly wrong once pinned heading took border. Check reading one heading missed it.
        worn: Array.from(document.querySelectorAll('.section-header'))
          .filter((each) => each.classList.contains('stuck')).length,
        // Geometry observer is watching, read here as well. Band missing while this says it
        //   should be there is observer that stopped answering; band missing while this says
        //   otherwise is scroll that did not reach.
        due: (() => {
          const edge = document.querySelector('.section[data-section="objects"] .section-edge');
          if (edge === null || scroller === null) return false;
          return edge.getBoundingClientRect().top <= scroller.getBoundingClientRect().top;
        })(),
      };
    });
  };
  const at_rest = await readAt('top');
  const pinned = await readAt('floor');
  report(
    'the heading carries no band of its own until its list is passing under it',
    alphaOfFill(at_rest.fill) === 0 && pinned.moved > 0 && alphaOfFill(pinned.fill) === 1,
    `at ${at_rest.moved} px it is ${at_rest.fill}, and at ${pinned.moved} px it is`
      + ` ${pinned.fill}; ${pinned.edges} sentinels, the heading reads`
      + ` ${pinned.stuck ? 'stuck' : 'unstuck'} there, and its sentinel is`
      + ` ${pinned.due ? 'above the scrollport' : 'still inside it'}`,
  );
  report(
    'and nothing scrolled means no heading anywhere in the drawer is wearing one',
    at_rest.worn === 0,
    `${at_rest.worn} of ${at_rest.edges} headings read stuck with the drawer at rest`,
  );
}


/** Assert pinned heading wears shape page's own floating controls wear.
 *
 *  Architect asked for heading that floats to read as same kind of thing as chip row's own
 *  pills, which is requirement about *sameness* rather than about any figure. So radius and
 *  border are read off heading and off pill and compared, never spelled out here: check
 *  naming `999px` would pass page whose pills had all moved somewhere else, which is drift this
 *  exists to catch.
 *  Pill read against is `.toggles`, not `.brand`, although `.brand` is one Architect named.
 *  `.brand` is itself drawer's toggle, and `.drawer-toggle.on` takes accent border while drawer
 *  is open -- which it has to be for this check to have heading to read. First form compared
 *  against it and reported `rgb(0, 167, 165)` where heading held `rgb(42, 50, 61)`: exemplar
 *  was in state, not idiom. `.toggles` wears same pill and has no state of its own.
 *  Fill is deliberately *not* compared. Those pills are `--surface` over blur; this one is
 *  opaque, because rows pass under it and heading asked to hide them cannot be seen through.
 *  `driveHeaderBanded` holds that opacity; this holds shape.
 */
export async function driveHeaderStyled(page: Page): Promise<void> {
  await openObjects(page);
  const worn = await page.evaluate(async () => {
    const scroller = document.querySelector('.drawer-scroll') as HTMLElement | null;
    const heading = document.querySelector(
      '.section[data-section="objects"] .section-header',
    ) as HTMLElement | null;
    const pill = document.querySelector('.toggles') as HTMLElement | null;
    if (scroller === null || heading === null || pill === null) return null;
    // Read while pinned: shape is what heading wears once it has lifted off list.
    scroller.scrollTop = scroller.scrollHeight - scroller.clientHeight;
    await new Promise((done) => { requestAnimationFrame(() => done(null)); });
    const shapeOf = (node: HTMLElement) => {
      const style = getComputedStyle(node);
      return {
        radius: style.borderTopLeftRadius,
        width: style.borderTopWidth,
        style: style.borderTopStyle,
        colour: style.borderTopColor,
      };
    };
    return {
      heading: shapeOf(heading), pill: shapeOf(pill),
      stuck: heading.classList.contains('stuck'),
    };
  });
  report(
    'a heading that has lifted off its list wears the pill the page\'s own controls wear',
    worn !== null && worn.stuck
      && worn.heading.radius === worn.pill.radius
      && worn.heading.width === worn.pill.width
      && worn.heading.style === worn.pill.style
      && worn.heading.colour === worn.pill.colour,
    worn === null ? 'no drawer to scroll'
      : `heading reads ${worn.stuck ? 'stuck' : 'unstuck'} and wears ${worn.heading.radius}`
        + ` with ${worn.heading.width} ${worn.heading.style} ${worn.heading.colour};`
        + ` the chip row's pill wears ${worn.pill.radius} with ${worn.pill.width}`
        + ` ${worn.pill.style} ${worn.pill.colour}`,
  );
}


/** Assert long list stands as its section opens, and only rows near viewport are built.
 *
 *  Every row used to be built, in time-bounded slices: 5,038 rows took 33 frames of 80 ms and
 *  2.9 s in front of reader on every first opening at that size, and 45,813 elements stood
 *  after. List is window over its keys now, so opening it builds tens of rows whatever scene
 *  holds, and scrolling to either end finds that end's row standing and no more than window.
 *  Section is shut and reopened rather than read on first build: closed section builds
 *  nothing, so this times opening itself and not load that preceded it.
 *  Time is reported, never asserted: how long tens of rows take is runner's business, and what
 *  holds on every runner is count.
 */
export async function driveListWindowed(page: Page): Promise<void> {
  await openObjects(page);
  const stood = await page.evaluate(async () => {
    const section = document.querySelector('.section[data-section="objects"]');
    const header = section?.querySelector('.section-header') as HTMLElement | null;
    const list = document.getElementById('objects-list');
    const scroller = document.querySelector('.drawer-scroll') as HTMLElement | null;
    if (header === null || list === null || scroller === null) return null;
    const settle = () => new Promise((done) => { requestAnimationFrame(() => done(null)); });
    const rowsNow = () => list.querySelectorAll('.object-row').length;
    header.click();                                   // shut it
    await settle();
    const started = performance.now();
    header.click();                                   // open again; rows stand before this returns
    const milliseconds = performance.now() - started;
    const at_once = rowsNow();
    const count = Number(list.dataset['count'] ?? '0');
    const elements = list.querySelectorAll('*').length;
    const page = document.querySelectorAll('*').length;
    await settle();
    // Newest object heads list and oldest ends it: list reads most recently added first.
    const created = nimSceneHandlesCreated();
    const key_last = String(created[0] ?? -1);
    const key_first = String(created[created.length - 1] ?? -1);
    // Two frames, not one: scroll event lands in next frame and window settles in it.
    scroller.scrollTop = scroller.scrollHeight - scroller.clientHeight;
    await settle();
    await settle();
    const box_scroller = scroller.getBoundingClientRect();
    const box_last = list.querySelector('.object-row[data-key="' + key_last + '"]')
      ?.getBoundingClientRect() ?? null;
    const at_floor = rowsNow();
    // List's own top, not scroller's: sections above it stand open, so at scroll 0 list lies
    //   below fold and its first rows, standing, are off screen.
    scroller.scrollTop = list.getBoundingClientRect().top - box_scroller.top + scroller.scrollTop;
    await settle();
    await settle();
    const box_first = list.querySelector('.object-row[data-key="' + key_first + '"]')
      ?.getBoundingClientRect() ?? null;
    const at_top = rowsNow();
    const isShown = (box: DOMRect | null) =>
      box !== null && box.bottom > box_scroller.top && box.top < box_scroller.bottom;
    return {
      milliseconds, at_once, count, want: nimSceneCount(), height: scroller.clientHeight,
      at_floor, is_last_shown: isShown(box_last), at_top, is_first_shown: isShown(box_first),
      elements, page,
    };
  });
  const most = stood === null ? 0 : rowsMost(stood.height);
  report(
    'a long list stands the moment its section opens, and only the rows near the viewport exist',
    stood !== null && stood.count === stood.want && stood.at_once > 0 && stood.at_once <= most,
    stood === null ? 'no list to open'
      : `${stood.at_once} rows stood for ${stood.count} objects ${stood.milliseconds.toFixed(1)}`
        + ` ms after the click, against ${most} allowed over a ${stood.height} px scroller;`
        + ` ${stood.elements} elements in the list and ${stood.page} on the page`,
  );
  report(
    "scrolling to either end of it finds that end's row on screen, within the same bound",
    stood !== null && stood.is_last_shown && stood.at_floor <= most
      && stood.is_first_shown && stood.at_top <= most,
    stood === null ? 'no list to scroll'
      : `at the floor the oldest object's row is ${stood.is_last_shown ? 'shown' : 'not shown'}`
        + ` among ${stood.at_floor} rows, and back at the top the newest is`
        + ` ${stood.is_first_shown ? 'shown' : 'not shown'} among ${stood.at_top}`,
  );
}


/** Drive objects list open, and assert closed rows build no forms and unseen rows nothing. */
export async function driveObjectsList(page: Page, objects: number): Promise<void> {
  await openObjects(page);
  const standing = await page.evaluate(() => {
    const list = document.getElementById('objects-list');
    return {
      elements: list?.querySelectorAll('*').length ?? 0,
      rows: document.querySelectorAll('#objects-list > .object-row').length,
      forms: document.querySelectorAll('#objects-list .object-edit').length,
      count: Number(list?.dataset['count'] ?? '0'),
      height: document.querySelector('.drawer-scroll')?.clientHeight ?? 0,
    };
  });
  const most = rowsMost(standing.height);
  report(
    'a closed row builds no edit form, and a row the reader cannot see is not built at all',
    standing.count >= objects && standing.rows > 0 && standing.rows <= most
      && standing.forms === 0 && standing.elements < ELEMENTS_ROW_MAX * standing.rows,
    `${standing.rows} rows stand for ${standing.count} objects, against ${most} allowed; ` +
      `${standing.elements} elements in them ` +
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

/** Assert edit from selection menu opens onto its row, however deep in list it is.
 *
 *  Row outside window does not exist until list is scrolled to it, and opening panel used to
 *  query that row at once, find none, and never scroll: panel opened onto top of list with
 *  wanted row thousands of pixels down it. Panel now scrolls to row's offset and renders window
 *  there before returning, so row is read as standing before any frame has run. Deep handle,
 *  so row stands only at its own offset. In view means under pinned heading, which covers
 *  scroller's own top edge, with whole form above scroller's floor.
 */
export async function driveEditFromMenu(page: Page): Promise<void> {
  const reached = await page.evaluate(async () => {
    // Shut section and drawer, state load with section shut leaves them in.
    document.querySelector('.section[data-section="objects"]')?.classList.remove('open');
    drawer.classList.remove('open');
    await new Promise((done) => setTimeout(done, 200));

    const handle = nimSceneHandlesCreated()[40] ?? 0;
    const rowOf = () => list_objects.querySelector('.object-row[data-handle="' + handle + '"]');
    const started = performance.now();
    nimSelectOnly(handle);
    openPanelTo(handle);
    const milliseconds = performance.now() - started;
    const is_standing_at_once = rowOf() !== null;
    await new Promise((done) => setTimeout(done, 300));
    const row = rowOf();
    const box = row === null ? null : row.getBoundingClientRect();
    const ceiling = document.querySelector('.section[data-section="objects"] .section-header')
      ?.getBoundingClientRect().bottom ?? 0;
    const floor = document.querySelector('.drawer-scroll')?.getBoundingClientRect().bottom ?? 0;
    return {
      milliseconds, is_standing_at_once,
      is_in_view: box !== null && box.top >= ceiling - 1 && box.bottom <= floor + 1,
      top: box === null ? null : box.top, bottom: box === null ? null : box.bottom,
      ceiling, floor,
      has_form: row !== null && row.querySelector('.coefficient-grid') !== null,
      rows: list_objects.querySelectorAll('.object-row').length,
      count: Number(list_objects.dataset['count'] ?? '0'), want: nimSceneCount(),
    };
  });
  const span = (at: number | null) => (at === null ? 'none' : at.toFixed(0));
  report(
    'edit from the selection menu opens onto its row, however deep, with its whole form in view',
    reached.is_standing_at_once && reached.is_in_view && reached.has_form
      && reached.count === reached.want,
    `row spans ${span(reached.top)} to ${span(reached.bottom)} px, under a heading ending at ` +
      `${reached.ceiling.toFixed(0)} and above a floor at ${reached.floor.toFixed(0)}; it stood ` +
      `${reached.is_standing_at_once ? 'before' : 'only after'} the call returned, ` +
      `${reached.milliseconds.toFixed(1)} ms; form ${reached.has_form}, ${reached.rows} rows ` +
      `for ${reached.count} objects`,
  );
  await page.evaluate(() => {
    endEditSession();
    nimSelectClear();
    refreshObjectsUI();
  });
}

/** Assert list reconciles against what is standing rather than rebuilding.
 *
 *  Two properties, and first is what makes second safe to rely on: refresh that changes
 *  nothing keeps very same elements, and refresh that changes one row keeps every other one.
 *  Held on element identity rather than on clock, so it cannot flake -- and identity is
 *  exactly claim, since rebuilt row is different object however fast it was made.
 */
export async function driveReconcile(page: Page): Promise<void> {
  const reconciled = await page.evaluate(async () => {
    const rowsNow = (): Element[] =>
      Array.from(document.querySelectorAll('#objects-list > .object-row'));
    const isSame = (a: Element[], b: Element[]): boolean =>
      a.length === b.length && a.every((node, i) => node === b[i]);
    const settle = () => new Promise((done) => { requestAnimationFrame(() => done(null)); });

    // List at rest first. Row's height is read frame after it is built or changes size, and
    //   window's far edge follows on next render: form check before this closed is 530 px
    //   shorter as row, so refresh read as idle here would extend window by nine rows, and
    //   rows built at that edge are measured frame later still, so rest arrives over several
    //   frames. Settled by identity, refresh per frame until one keeps every element, rather
    //   than by fixed two frames, which slower runner overran once rows wrapped long
    //   coefficients; bound is many times what fast container needs.
    refreshObjectsUI();
    let rows_last = rowsNow();
    let frames_settling = 0;
    for (; frames_settling < 40; frames_settling += 1) {
      await settle();
      refreshObjectsUI();
      const rows_now = rowsNow();
      if (isSame(rows_now, rows_last)) break;
      rows_last = rows_now;
    }
    const before_idle = rowsNow();
    refreshObjectsUI();
    const after_idle = rowsNow();
    // Handle off row that stands: rows outside window are not there to be kept or rebuilt.
    const handle = Number((rowsNow()[0] as HTMLElement | undefined)?.dataset['handle'] ?? '0');
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
      rows: after_hide.length, frames_settling,
    };
  });
  report(
    'an unchanged refresh writes nothing, and a hide rebuilds one row alone',
    reconciled.is_idle_kept && reconciled.touched_by_hide === 1,
    `idle kept every element: ${reconciled.is_idle_kept} after ${reconciled.frames_settling} ` +
      `settling frame(s); a hide rebuilt ${reconciled.touched_by_hide} of ${reconciled.rows} rows`,
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

/** Assert slow figures are asked for on their own slower clock, and not at all when shut.
 *
 *  Exceedance curve covers whole window and sparkline and ring medians span seconds: none of
 *  them can change inside one tick, and redrawing them at panel's own rate was half of it.
 *  Counted rather than timed, so no clock decides verdict -- but count has to be of thing
 *  claim is about. Asks are tick's; redraws are not, since axis switch draws on press and
 *  frame loop draws every frame while axis glides. Counting redraws made this check pass
 *  only while those two stayed quiet, which is what reddened it.
 */
export async function driveTickCadence(page: Page): Promise<void> {
  const cadence = await page.evaluate(async () => {
    const wait = (milliseconds: number): Promise<void> =>
      new Promise((done) => setTimeout(done, milliseconds));
    const scope = globalThis as unknown as {
      askSlowPass: typeof askSlowPass; drawExceedance: typeof drawExceedance;
      refreshDiagnostics: typeof refreshDiagnostics;
    };
    const original_ask = scope.askSlowPass;
    let curves = 0;
    scope.askSlowPass = function (
      is_curve: boolean, is_sparkline: boolean, is_medians: boolean, is_pool: boolean,
    ): void {
      if (is_curve) curves += 1;
      original_ask(is_curve, is_sparkline, is_medians, is_pool);
    };
    const original_curve = scope.drawExceedance;
    let draws = 0;
    scope.drawExceedance = function (): void {
      draws += 1;
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
    let pressed = 0, drew_on_press = 0;
    for (let i = 0; i < 4; i += 1) {
      const drawn_before = draws;
      toggle?.click();
      pressed += 1;
      // Handler draws synchronously, so its redraw has landed by time `click` returns.
      if (draws === drawn_before + 1) drew_on_press += 1;
      await wait(120);
    }
    await wait(1300);
    const open = { ticks, curves, draws, pressed, drew_on_press };

    // Whole tick is skipped with section collapsed inside open drawer: both canvases would
    //   otherwise fall back to made-up width and draw for nobody.
    const section = document.querySelector('.section[data-section="diagnostics"]');
    section?.classList.remove('open');
    ticks = 0;
    curves = 0;
    draws = 0;
    await wait(1500);
    const collapsed = { ticks, curves, draws };
    section?.classList.add('open');
    scope.askSlowPass = original_ask;
    scope.drawExceedance = original_curve;
    scope.refreshDiagnostics = original_tick;
    return { open, collapsed };
  });
  report(
    'the panel asks for its slower figures on their own slower clock',
    cadence.open.ticks >= 8 && cadence.open.curves > 0 &&
      cadence.open.curves * 3 <= cadence.open.ticks,
    `${cadence.open.curves} curve asks over ${cadence.open.ticks} ticks, ` +
      `${cadence.open.draws} redraws in all`,
  );
  report(
    'and the axis switch redraws on the press, without the tick asking',
    cadence.open.drew_on_press === cadence.open.pressed &&
      cadence.open.draws > cadence.open.curves,
    `${cadence.open.drew_on_press} of ${cadence.open.pressed} presses drew on the spot; ` +
      `${cadence.open.draws} redraws against ${cadence.open.curves} asks`,
  );
  report(
    'and a collapsed diagnostics section costs the tick nothing at all',
    cadence.collapsed.draws === 0,
    `${cadence.collapsed.draws} curve redraws over ${cadence.collapsed.ticks} ticks ` +
      `with the section shut, against ${cadence.collapsed.curves} ask(s) dropped`,
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
