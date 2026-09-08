// Drive built page through real events, and assert what they reached; not Nim because
//   Playwright's API and node's process are what this speaks, and Nim reaches them only
//   through glue that would leave every browser-side expression unchecked string.
//   Run it by `nim r tools/build.nim drive`, which builds page first when it is stale.
//   Chromium comes from `PLAYWRIGHT_BROWSERS_PATH`, or from `RGA_CHROMIUM` where that names
//   one. Software rendering is forced, so figures here are not this machine's GPU.

import { chromium } from '@playwright/test';
import { existsSync } from 'node:fs';
import { join } from 'node:path';
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
import {
  drivePanWhileSelected, drivePickOrbit, drivePlanePick, drivePointerPick,
} from './framing';
import { driveLabelGlide, driveLabelWorn } from './label';
import { driveHelp, driveHoverDuringGesture } from './chrome';
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
  driveEditFromMenu, driveObjectsList, drivePerFrame, driveReconcile, driveTickCadence,
  driveTickWrites,
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

/** Chromium to drive, where Playwright's own copy is not what is installed.
 *
 *  Environments often carry Chromium for Playwright other than pinned one, and fetching
 *  second is not this harness's business. `RGA_CHROMIUM` names one outright; failing
 *  that, standard `PLAYWRIGHT_BROWSERS_PATH` usually holds `chromium` beside its numbered
 *  builds. Absent both, Playwright resolves its own.
 */
function chromiumChosen(): string | undefined {
  const named = process.env['RGA_CHROMIUM'];
  if (named !== undefined && named.length > 0) return named;
  const installed = process.env['PLAYWRIGHT_BROWSERS_PATH'];
  if (installed === undefined) return undefined;
  const beside = join(installed, 'chromium');
  return existsSync(beside) ? beside : undefined;
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
