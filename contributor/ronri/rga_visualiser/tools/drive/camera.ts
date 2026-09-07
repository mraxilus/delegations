// Camera readings harness compares gestures against; not Nim because these run inside
//   `page.evaluate`, in browser, where only TypeScript checks them against bridge's derived
//   declarations.
//   Every reading comes from bridge, never from harness's own arithmetic on screen: what is
//   under test is whether gesture reached rule, not whether rule is right. Suites test rule.

import type { Page } from '@playwright/test';

declare global {
  interface Window {
    /** Stance last poll read, so next one can tell whether ease has stopped. */
    __stance_last?: number[];
  }
}

/** Where camera stands, as bridge reports it. */
export interface Stance {
  distance: number;
  pivot: number[];
  eye: number[];
  azimuth: number;
}

/** Read camera's whole stance in one crossing, as plain arrays `evaluate` can return. */
export async function readCamera(page: Page): Promise<Stance> {
  return page.evaluate(() => ({
    distance: nimCameraDistance(),
    pivot: Array.from(nimCameraPivot()),
    eye: Array.from(nimCameraEye()),
    azimuth: nimCameraAzimuth(),
  }));
}

/** Distance between two world points. */
export function spanOf(a: number[], b: number[]): number {
  return Math.hypot(
    (a[0] ?? 0) - (b[0] ?? 0), (a[1] ?? 0) - (b[1] ?? 0), (a[2] ?? 0) - (b[2] ?? 0),
  );
}

/** Unit sight direction, eye toward pivot. */
export function forwardOf(camera: Stance): number[] {
  const span = spanOf(camera.pivot, camera.eye);
  return camera.pivot.map((v, i) => (v - (camera.eye[i] ?? 0)) / span);
}

/** Depth of world point along camera's sight line, from eye. */
export function depthOf(camera: Stance, at: number[]): number {
  const forward = forwardOf(camera);
  return at.reduce((sum, v, i) => sum + (v - (camera.eye[i] ?? 0)) * (forward[i] ?? 0), 0);
}

/** How far eye moved across its own sight line, zoom's motion along it set aside. */
export function slideOf(before: Stance, after: Stance): number {
  const forward = forwardOf(before);
  const step = after.eye.map((v, i) => v - (before.eye[i] ?? 0));
  const along = step.reduce((sum, v, i) => sum + v * (forward[i] ?? 0), 0);
  return Math.hypot(...step.map((v, i) => v - along * (forward[i] ?? 0)));
}

/** How far pivot itself travelled between two stances. */
export function spanPivot(before: Stance, after: Stance): number {
  return spanOf(before.pivot, after.pivot);
}


/** Wait until camera's own ease has stopped, rather than for long enough that it usually has.
 *
 *  Polled on page's own frame boundary and compared against previous reading, so it settles in
 *  frames rather than in wall time: loaded runner draws frames slower, and this waits for them
 *  instead of racing them. Fixed sleep here was harness's commonest flake (repository issue 47).
 *  Raises where camera never stops, which is fault worth failing on rather than sleeping past.
 */
export async function settleCamera(page: Page): Promise<void> {
  await page.evaluate(() => { delete window.__stance_last; });
  await page.waitForFunction(() => {
    const now_at = [nimCameraDistance(), nimCameraAzimuth(), ...Array.from(nimCameraPivot())];
    const before = window.__stance_last;
    window.__stance_last = now_at;
    return before !== undefined && before.length === now_at.length &&
      before.every((v, i) => Math.abs(v - (now_at[i] ?? 0)) < 1e-9);
  }, null, { timeout: 8000, polling: 'raf' });
}
