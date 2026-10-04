// Drive built page through real events, and assert what they reached; not Nim because
//   Playwright's API and node's process are what this speaks, and Nim reaches them only
//   through glue that would leave every browser-side expression unchecked string.
//   Run it by `nim r tools/build.nim drive`, which builds page first when it is stale.
//   Chromium is one `RGA_CHROMIUM` names, else Playwright's own pinned build, else one on
//   `PATH`; `chromiumChosen` says why that order. Software rendering is forced, so figures
//   here are not this machine's GPU.

import { chromium, type Browser, type Page } from '@playwright/test';
import { accessSync, constants, existsSync } from 'node:fs';
import { delimiter, join } from 'node:path';
import { countFailed, countRun, report } from './report';
import { focusCanvas } from './gestures';
import { driveKeys } from './keys';
import { driveAim, driveLook, drivePan, driveStretch } from './pan';
import { driveWheel } from './wheel';
import { driveFingerTurntable, driveTouchSelect, drivePinch, openTouch } from './touch';
import {
  driveBackdropPlane, driveCrowd, driveEmptyRelease, drivePausedDrag, drivePointFills,
  driveTouchConstruct, driveTwoFingerPan,
} from './construct';
import { driveApply, driveApplyNamed, driveReachable, driveUndo } from './apply';
import { driveMessageGoes } from './message';
import {
  driveGroupTurnedAtOnce, drivePanWhileSelected, drivePickOrbit, drivePlanePick,
  drivePointerPick,
} from './framing';
import {
  driveFrameLabelCorner, driveLabelFirstFrame, driveLabelGlide, driveLabelHeldInView,
  driveLabelWorn,
} from './label';
import { driveChipRowFits, driveHelp, driveHoverDuringGesture } from './chrome';
import { driveTypeDrawn, driveTypeLigatures, driveTypeRoles } from './type';
import { driveBlurCost, driveBlurDeclared, driveDrawerBlurs, setBlur } from './blur';
import { driveFacesCovered } from './faces';
import { driveCreep, drivePlaneBuilt, driveRuler } from './finger';
import { driveHoldScene } from './hold';
import { driveDrawerCost, drivePlacementHeld } from './pool';
import {
  driveCulling, driveDemo, driveDiscUnderfoot, driveFarSky, driveLineCrossing, driveOccluded,
  driveZoomLoaded, loadDemo, objectsDefault, objectsLargest,
} from './demo';
import {
  driveFullRefused, driveLoadedAccounting, drivePinPickLoaded, drivePlacingCost,
  driveTimelineCost, driveUndoDrawn,
} from './loaded';
import {
  driveEditFromMenu, driveHeaderBanded, driveHeaderPinned, driveHeaderStyled,
  driveListSearched, driveListWindowed, driveObjectsList, drivePerFrame,
  driveReconcile,
  driveTickCadence, driveTickWrites,
} from './objects';
import { driveComet } from './comet';
import { driveShadedFromAbove } from './shade';
import { driveStyleDeclared } from './style';
import { driveHeapUnit, drivePhaseSums, driveTree } from './diagnostics';
import { driveAxis, driveAxisGlide, driveCurve, driveScaleSwitch } from './exceedance';
import { driveSums, driveTint, openEveryBranch } from './ramp';
import {
  drivePinAnchor, drivePinGrid, drivePinMarker, drivePinPick, drivePinPool,
  MILLISECONDS_PICK_HOVER_LOADED,
} from './pins';
import { driveRings, driveRingsTimed } from './rings';
import {
  driveAllowance, driveHold, driveKinds, driveMoving, driveSceneryBound,
} from './scenery';
import { driveGround } from './ground';
import { driveBlankRefused } from './canvas';
import { driveFrameWork, driveLoopRuns, watchFrames } from './frame';
import { driveHostSave } from './host';
import { driveViewSection } from './view';
import { advance, hastenTransitions, simulateClock, waitUntil } from './clock';

/** Simulated span tree stands open for before curve and rows are read: five of its ticks. */
const MILLISECONDS_TREE_TICKS = 1000;

/** Viewport every check below is written against. */
const SIZE_VIEW = { width: 1200, height: 900 };

/** Assembled page, as `tools/build.nim web` writes it. */
const PATH_PAGE = join(__dirname, '..', '..', 'build', 'rga_visualiser.html');

/** Chromium to drive, in order of what pins each candidate.
 *
 *  `RGA_CHROMIUM` names one outright and stays first, since that is what override is for;
 *  nothing outside this project sets it. Failing that, Playwright's own build is what
 *  `package-lock.json` pins -- lock fixes `@playwright/test`, version fixes browser
 *  revision -- so this machine and runner drive one binary rather than two. Last is
 *  `chromium` on `PATH`, which on Ubuntu 24.04 carries no version of its own, and is here
 *  for machine that cannot fetch Playwright's.
 *  Undefined lets Playwright resolve its own, which is what `launch` does given no path.
 *  `tools/build.nim drive` fetches that build before running this, so reaching `PATH` at
 *  all means fetch was skipped or refused.
 */
function chromiumChosen(): string | undefined {
  const named = process.env['RGA_CHROMIUM'];
  if (named !== undefined && named.length > 0) return named;
  if (existsSync(chromium.executablePath())) return undefined;
  return chromiumOnPath();
}

/** First executable `chromium` on `PATH`, or undefined where none is. */
function chromiumOnPath(): string | undefined {
  for (const directory of (process.env['PATH'] ?? '').split(delimiter)) {
    for (const name of ['chromium', 'chromium-browser']) {
      const candidate = join(directory, name);
      // Executable bit rather than existence: directory of that name is not browser, and
      //   `command -v` tests same thing.
      try {
        accessSync(candidate, constants.X_OK);
        return candidate;
      } catch {
        continue;
      }
    }
  }
  return undefined;
}

/** Wait until page's own scene stands, not for fixed time.
 *
 *  Build carries whole compiled module inline, and how long that takes to run is machine's
 *  business rather than check's.
 */
async function waitScene(page: Page): Promise<void> {
  await waitUntil(page, () => typeof nimSceneCount === 'function' && nimSceneCount() > 0, null);
}

/** Drive every correctness check, on page whose time moves only when check moves it.
 *
 *  Verdicts here are same on every machine: slow one takes longer to reach them. Page's own
 *  timing readouts all read zero on this clock, so checks of them run in `driveMeasured`.
 */
async function driveSimulated(browser: Browser): Promise<void> {
  const page = await browser.newPage({ viewport: SIZE_VIEW, hasTouch: true });
  const errors_page: string[] = [];
  page.on('pageerror', (error) => errors_page.push(error.message));

  await simulateClock(page);
  await page.goto(`file://${PATH_PAGE}`);
  await waitScene(page);
  // Two fingers go through Chrome's own protocol, and so does style engine's timeline, so
  //   channel opens once here.
  const devtools = await openTouch(page);
  await hastenTransitions(devtools);
  await focusCanvas(page);
  // Counts and flags each frame carries, for hold and rim checks; times on this page read zero.
  await watchFrames(page);

  // Stylesheet first, before anything reads what it drew: declaration browser dropped is
  //   layout nobody wrote, and every check below is against page it styled.
  await driveStyleDeclared(page);
  // Blur's own checks next, on page as it opened; every check after them runs without it, by
  //   ruling of #453 (`blur.ts`).
  await driveBlurDeclared(page);
  await driveDrawerBlurs(page);
  await setBlur(page, false);

  // Reader every pixel check leans on, checked before any of them lean on it.
  await driveBlankRefused(page);
  await driveKeys(page);
  await driveWheel(page);
  await drivePan(page);
  await driveLook(page);
  await driveAim(page, SIZE_VIEW.width, SIZE_VIEW.height);

  await drivePinch(page, devtools);
  await driveFingerTurntable(page, devtools);
  await driveTouchSelect(page, devtools);
  await driveTwoFingerPan(page, devtools);
  await driveTouchConstruct(page, devtools);
  await driveCrowd(page, devtools);
  await drivePausedDrag(page, devtools);
  await driveEmptyRelease(page, SIZE_VIEW.width, SIZE_VIEW.height);
  // Beside it, and its opposite: what *is* said goes away again by itself.
  await driveMessageGoes(page);

  await driveApply(page);
  await drivePickOrbit(page);
  await drivePointerPick(page);
  await drivePlanePick(page);
  await driveLabelGlide(page);
  await driveLabelWorn(page);
  await driveBackdropPlane(page, SIZE_VIEW.width, SIZE_VIEW.height);
  await drivePointFills(page);
  await drivePanWhileSelected(page, devtools);
  await driveStretch(page);
  await driveGroupTurnedAtOnce(page, devtools);
  await driveUndo(page);
  await driveReachable(page);
  await driveViewSection(page);

  await driveHoverDuringGesture(page, SIZE_VIEW.width, SIZE_VIEW.height);
  await driveHelp(page, SIZE_VIEW.width, SIZE_VIEW.height);
  // Sweeps viewport and puts it back; kept beside other chrome checks rather than among
  //   drawer's, since what it reads is row above drawer and not drawer itself.
  await driveChipRowFits(page);
  // After help, so tab strip exists to be asked which face it is drawn in.
  await driveTypeRoles(page);
  await driveTypeDrawn(page);
  await driveTypeLigatures(page);
  // After role checks: those ask which face each role draws in, and this asks whether each
  //   character page writes has glyph there.
  await driveFacesCovered(page);
  await driveShadedFromAbove(page);
  await driveComet(page);
  await driveGround(page);
  await driveLoopRuns(page);
  // Curve, rows and rings below are what tree shows, so tree is open while they are read, and
  //   long enough for its tick to have asked curve and rows of it at least once.
  await openEveryBranch(page);
  await advance(page, MILLISECONDS_TREE_TICKS);
  await driveCurve(page);
  await driveAxis(page);
  await driveAxisGlide(page);
  await driveScaleSwitch(page);
  // Rings check every experiment pill from page's own default, which has blur on.
  await setBlur(page, true);
  await driveRings(page);
  await setBlur(page, false);
  driveAllowance();
  await driveHold(page);
  await drivePinPool(page);

  await driveCreep(page, devtools);
  await drivePlaneBuilt(page, devtools);
  await driveRuler(page);
  await driveHoldScene(page);
  await driveDrawerCost(page);
  await drivePlacementHeld(page);

  // Demo runs last, and under load: it builds thousands of objects, and every check above is
  //   written against opening scene's own weight.
  await driveDemo(page, await objectsDefault(page));
  // Under default size, where arena has room: largest size below fills it to capacity.
  await driveApplyNamed(page);
  const objects_largest = await objectsLargest(page);
  await loadDemo(page, objects_largest);
  await driveCulling(page);
  await driveOccluded(page);
  await driveFarSky(page);
  await driveDiscUnderfoot(page);
  await driveLineCrossing(page, SIZE_VIEW.width, SIZE_VIEW.height);
  await driveLabelHeldInView(page);
  await driveLabelFirstFrame(page);
  await driveFrameLabelCorner(page);
  await driveZoomLoaded(page);
  await driveUndoDrawn(page);
  await driveFullRefused(page, errors_page);
  await driveObjectsList(page, objects_largest);
  await driveHeaderPinned(page);
  await driveHeaderBanded(page);
  await driveHeaderStyled(page);
  // After heading checks, since it shuts section and opens it again and scrolls list to
  //   either end: one above reads shape heading wears where it stands.
  await driveListWindowed(page);
  await driveEditFromMenu(page);
  await driveListSearched(page);
  await driveReconcile(page);
  await driveTickWrites(page);
  await driveTickCadence(page);
  await drivePerFrame(page);

  // Page erroring at all is failure, whatever every check above said.
  report('the page raised no error', errors_page.length === 0, errors_page.join(' | '));
  await page.close();
}

/** Drive speed checks, and checks of page's own timing readouts, on real clock.
 *
 *  Speed check is only kind that may read real clock, and its bound is upper limit runner and
 *  delegate meet with measured margin; see `PROVENANCE.md`. Readout checks need real clock to
 *  read anything, and sample fixed count of frames, so their verdict does not move with speed.
 */
async function driveMeasured(browser: Browser): Promise<void> {
  const page = await browser.newPage({ viewport: SIZE_VIEW, hasTouch: true });
  const errors_page: string[] = [];
  page.on('pageerror', (error) => errors_page.push(error.message));

  await page.goto(`file://${PATH_PAGE}`);
  await waitScene(page);
  await focusCanvas(page);
  // Blur off for every timing below but its own, so no other bound carries its cost.
  await setBlur(page, false);

  await driveFrameWork(page);
  await drivePhaseSums(page);
  await driveTree(page);
  await driveTint(page);
  await driveSums(page);
  await driveHeapUnit(page);
  await driveRingsTimed(page);
  await driveKinds(page);
  await driveSceneryBound(page);
  await driveMoving(page, SIZE_VIEW.width);
  await drivePinPick(page);
  await drivePinAnchor(page);
  await drivePinMarker(page);
  await drivePinGrid(page);

  const objects_largest = await objectsLargest(page);
  await loadDemo(page, objects_largest);
  await driveTimelineCost(page, objects_largest);
  await drivePlacingCost(page, objects_largest);
  await drivePinPickLoaded(page, MILLISECONDS_PICK_HOVER_LOADED);
  await driveLoadedAccounting(page);
  await driveBlurCost(page, objects_largest);

  report(
    'the measured page raised no error', errors_page.length === 0, errors_page.join(' | '),
  );
  await page.close();
}

async function main(): Promise<void> {
  const executable = chromiumChosen();
  const browser = await chromium.launch({
    ...(executable === undefined ? {} : { executablePath: executable }),
    args: ['--use-gl=swiftshader', '--enable-unsafe-swiftshader', '--no-sandbox'],
  });

  await driveSimulated(browser);
  await driveMeasured(browser);
  // Page of its own, since host it stands in has to be there before page's script runs.
  await driveHostSave(browser, `file://${PATH_PAGE}`, SIZE_VIEW);

  await browser.close();
  console.log(`\n${countRun() - countFailed()} of ${countRun()} checks passed.`);
  process.exit(countFailed() === 0 ? 0 : 1);
}

void main();
