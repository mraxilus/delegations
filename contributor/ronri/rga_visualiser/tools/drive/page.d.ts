// Page's own script-scope names harness drives; not Nim because these are what browser holds
//   at run time, and only TypeScript can state them to type-checker.
//   Bridge's 157 exports are *not* here: they are derived into `build/bridge.d.ts` by
//   `tools/build.nim declare`, so no signature of theirs is written twice.
//   These four are exception, hand-written because nothing derives them: they
//   live in `src/browser/*.ts` at script scope, which no generator reads yet.
//   Kept to four on purpose. Reach for bridge export first, then for DOM; add here only
//   where neither can say it.

/** Drop every selected object, as `state` does for chrome that asks. */
declare function clearSelection(): void;

/** Shut selection menu, which standing open swallows pointer events over canvas. */
declare function hideSelectionMenu(): void;

/** Run diagnostics tick now, rather than waiting for its own slower cadence. */
declare function refreshDiagnostics(): void;

/** Say one line to reader, in transient bar. Harness reads it to check what was said. */
declare function toast(message: string): void;
