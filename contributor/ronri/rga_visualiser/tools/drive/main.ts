// Drive built page through real events, and assert what they reached; not Nim because
//   Playwright's API and node's process are what this speaks, and Nim reaches them only
//   through glue that would leave every browser-side expression unchecked string.
//   Run it by `nim r tools/build.nim drive`, which builds page first when it is stale.
//   Chromium is one `RGA_CHROMIUM` names, else Playwright's own pinned build, else one on
//   `PATH`; `chromiumChosen` says why that order. Software rendering is forced, so figures
//   here are not this machine's GPU.

import { chromium } from '@playwright/test';
import { accessSync, constants, existsSync } from 'node:fs';
import { delimiter, join } from 'node:path';
import { countFailed, countRun, report } from './report';
import { focusCanvas } from './gestures';
import { driveKeys } from './keys';
import { driveAim, drivePan } from './pan';
import { driveWheel } from './wheel';
import { driveTouchSelect, drivePinch, openTouch } from './touch';
import {
  driveBackdropPlane, driveCrowd, driveEmptyRelease, drivePausedDrag, driveTouchConstruct,
  driveTwoFingerPan,
} from './construct';
import { driveApply, driveReachable, driveUndo } from './apply';
import { driveMessageGoes } from './message';
import {
  drivePanWhileSelected, drivePickOrbit, drivePlanePick, drivePointerPick,
} from './framing';
import { driveLabelGlide, driveLabelWorn } from './label';
import { driveHelp, driveHoverDuringGesture } from './chrome';
import { driveTypeDrawn, driveTypeLigatures, driveTypeRoles } from './type';
import { driveCreep, drivePlaneBuilt, driveRuler } from './finger';
import { driveHoldScene } from './hold';
import { driveDrawerCost, drivePlacementHeld } from './pool';
import {
  driveCulling, driveDemo, driveOccluded, driveZoomLoaded, loadDemo, objectsDefault,
  objectsLargest,
} from './demo';
import {
  driveLoadedAccounting, drivePinPickLoaded, drivePlacingCost, driveTimelineCost,
  driveUndoDrawn,
} from './loaded';
import {
  driveEditFromMenu, driveHeaderPinned, driveObjectsList, drivePerFrame, driveReconcile,
  driveTickCadence, driveTickWrites,
} from './objects';
import { driveComet } from './comet';
import { drivePhaseSums, driveTree } from './diagnostics';
import { driveAxis, driveAxisGlide, driveCurve, driveScaleSwitch } from './exceedance';
import { driveSums, driveTint } from './ramp';
import {
  drivePinAnchor, drivePinGrid, drivePinMarker, drivePinPick, drivePinPool,
  MILLISECONDS_PICK_HOVER,
} from './pins';
import { driveRings } from './rings';
import {
  driveAllowance, driveHold, driveKinds, driveMoving, driveSceneryBound,
} from './scenery';
import { driveGround } from './ground';
import { driveBlankRefused } from './canvas';
import { driveFrameWork } from './frame';

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

async function main(): Promise<void> {
  const executable = chromiumChosen();
  const browser = await chromium.launch({
    ...(executable === undefined ? {} : { executablePath: executable }),
    args: ['--use-gl=swiftshader', '--enable-unsafe-swiftshader', '--no-sandbox'],
  });
  const page = await browser.newPage({ viewport: SIZE_VIEW, hasTouch: true });

  const errors_page: string[] = [];
  page.on('pageerror', (error) => errors_page.push(error.message));

  await page.goto(`file://${PATH_PAGE}`);
  // Page is up when its own scene stands, not after fixed wait: build carries whole compiled
  //   module inline, and how long that takes to run is machine's business rather than check's.
  await page.waitForFunction(
    () => typeof nimSceneCount === 'function' && nimSceneCount() > 0,
    null, { timeout: 60000, polling: 'raf' },
  );
  await focusCanvas(page);

  // Reader every pixel check leans on, checked before any of them lean on it.
  await driveBlankRefused(page);
  await driveKeys(page);
  await driveWheel(page);
  await drivePan(page);
  await driveAim(page, SIZE_VIEW.width, SIZE_VIEW.height);

  // Two fingers go through Chrome's own protocol, so channel opens once here.
  const cdp = await openTouch(page);
  await drivePinch(page, cdp);
  await driveTouchSelect(page, cdp);
  await driveTwoFingerPan(page, cdp);
  await driveTouchConstruct(page, cdp);
  await driveCrowd(page, cdp);
  await drivePausedDrag(page, cdp);
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
  await drivePanWhileSelected(page, cdp);
  await driveUndo(page);
  await driveReachable(page);

  await driveHoverDuringGesture(page, SIZE_VIEW.width, SIZE_VIEW.height);
  await driveHelp(page, SIZE_VIEW.width, SIZE_VIEW.height);
  // After help, so tab strip exists to be asked which face it is drawn in.
  await driveTypeRoles(page);
  await driveTypeDrawn(page);
  await driveTypeLigatures(page);
  await driveComet(page);
  await driveGround(page);
  await driveFrameWork(page);
  await drivePhaseSums(page);
  await driveTree(page);
  await driveCurve(page);
  await driveAxis(page);
  await driveTint(page);
  await driveSums(page);
  await driveAxisGlide(page);
  await driveScaleSwitch(page);
  await driveRings(page);
  driveAllowance();
  await driveKinds(page);
  await driveSceneryBound(page);
  await driveMoving(page, SIZE_VIEW.width);
  await driveHold(page);

  await drivePinPick(page);
  await drivePinAnchor(page);
  await drivePinMarker(page);
  await drivePinGrid(page);
  await drivePinPool(page);

  await driveCreep(page, cdp);
  await drivePlaneBuilt(page, cdp);
  await driveRuler(page);
  await driveHoldScene(page);
  await driveDrawerCost(page);
  await drivePlacementHeld(page);

  // Demo runs last, and under load: it builds thousands of objects, and every check above is
  //   written against opening scene's own weight.
  await driveDemo(page, await objectsDefault(page));
  const objects_largest = await objectsLargest(page);
  await loadDemo(page, objects_largest);
  await driveCulling(page);
  await driveOccluded(page);
  await driveZoomLoaded(page);
  await driveTimelineCost(page, objects_largest);
  await drivePlacingCost(page, objects_largest);
  await driveUndoDrawn(page);
  await drivePinPickLoaded(page, MILLISECONDS_PICK_HOVER);
  await driveLoadedAccounting(page, errors_page);
  await driveObjectsList(page, objects_largest);
  await driveHeaderPinned(page);
  await driveEditFromMenu(page);
  await driveReconcile(page);
  await driveTickWrites(page);
  await driveTickCadence(page);
  await drivePerFrame(page);

  // Page erroring at all is failure, whatever every check above said.
  report('the page raised no error', errors_page.length === 0, errors_page.join(' | '));

  await browser.close();
  console.log(`\n${countRun() - countFailed()} of ${countRun()} checks passed.`);
  process.exit(countFailed() === 0 ? 0 : 1);
}

void main();
