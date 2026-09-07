// Page's own script-scope names harness drives; not Nim because these are what browser holds
//   at run time, and only TypeScript can state them to type-checker.
//   Bridge's 157 exports are *not* here: they are derived into `build/bridge.d.ts` by
//   `tools/build.nim declare`, so no signature of theirs is written twice.
//   These are exception, hand-written because nothing derives them: they live in
//   `src/browser/*.ts` at script scope, which no generator reads yet.
//   Two groups only: page's own selection and chrome entries, and exceedance window, whose
//   buckets and axis no bridge export reaches. Add here only where neither bridge export
//   nor DOM can say it.

/** Drop every selected object, as `state` does for chrome that asks. */
declare function clearSelection(): void;

/** Select one object alone, and tell page, as every pick path does.
 *
 *  Not `nimSelectOnly`: that moves Nim's own selection and leaves page's render snapshot
 *  behind it, so overlay draws no marker and its comet never advances.
 */
declare function selectOnly(handle: number, position_local: null): void;

/** Add or drop one object from selection, and tell page, as shift-click does. */
declare function toggleSelection(handle: number, position_local: null): void;

/** Rebuild selection menu against selection standing now, as every pick path does. */
declare function refreshSelectionMenu(position_local: null): void;

/** Shut selection menu, which standing open swallows pointer events over canvas. */
declare function hideSelectionMenu(): void;

/** Run diagnostics tick now, rather than waiting for its own slower cadence. */
declare function refreshDiagnostics(): void;

/** Say one line to reader, in transient bar. Harness reads it to check what was said. */
declare function toast(message: string): void;

/** Show or hide help, as its own button does. */
declare function showHelp(is_shown: boolean): void;

/** Marker kind page draws horizon line's bands as; mirrors `marker.MarkerKind`. */
declare const MARKER_BANDS: number;

/* Exceedance window, which `src/browser/diagnostics.ts` owns. */

/** Take one frame's duration into rolling window, as frame loop does every frame. */
declare function recordExceedance(delta_milliseconds: number): void;

/** Refill `shares_exceedance` from buckets, and report how many frames window holds. */
declare function scanExceedance(): number;

/** Redraw curve now, rather than waiting for section's own slower cadence. */
declare function drawExceedance(): void;

/** How many buckets window is cut into. */
declare const BUCKETS_EXCEEDANCE: number;

/** How many milliseconds one bucket spans. */
declare const MILLISECONDS_BUCKET: number;

/** Narrowest axis may draw, whatever window holds. */
declare const MILLISECONDS_AXIS_LEAST: number;

/** Share of frames at or over each bucket's own duration, filled by `scanExceedance`. */
declare const shares_exceedance: Float64Array;

/** How many frames fell in each bucket. */
declare const buckets_exceedance: Int32Array;

/** Every frame duration window holds, oldest overwritten first. */
declare const history_exceedance: Float32Array;

/** When axis's extent first differed from what is drawn; zero while it is settled. */
declare let ms_axis_restless: number;

/* Frame-time tree, its ramp and rings, which `src/browser/diagnostics.ts` owns. */

/** Every timing row, as name paired with id of element carrying its reading. */
declare const PHASES_DIAGNOSTIC: Array<[string, string]>;

/** Rows page's own frame is broken into, whose sum with idle is whole frame. */
declare const PHASES_TOP_DIAGNOSTIC: string[];

/** Element each row's reading is written into. */
declare const element_phase: Record<string, HTMLElement | null>;

/** Line each row's reading sits on, name and all. */
declare const element_row: Record<string, Element | null>;

/** Colour ramp rows are tinted along, each step as label and value colour. */
declare const RAMP_TREE: Array<{ label: number[]; value: number[] }>;

/** Where along ramp this share of frame sits. */
declare function positionRampTree(share: number): number;

/** Share of frame ramp's far end stands for. */
declare const SHARE_RAMP_FULL_DIAGNOSTIC: number;

/** Share of frame ramp's linear toe reaches to. */
declare const SHARE_RAMP_KNEE_DIAGNOSTIC: number;

/** Write colour as CSS, way page writes every one it draws. */
declare function rgbToCss(rgb: number[]): string;

/** How many frames every ring holds. */
declare const FRAMES_HISTORY: number;

/** Each frame's whole duration, oldest overwritten first. */
declare const history_frame: number[];

/** Slot next frame is written into. */
declare let index_history_frame: number;

/** Clock panel's own reading last ran on; every field, row and ruler is written there. */
declare let ms_refresh_ui: number;

/** Each row's own readings, over same ring. */
declare const history_phase: Record<string, Float64Array>;

/** Whether each slot of each row's ring was written this time round. */
declare const written_phase: Record<string, Uint8Array>;

/** Advance frame ring by one, as draw loop does every frame. */
declare function recordFrameTime(delta_milliseconds: number): void;

/** Write one row's reading into frame ring's current slot. */
declare function recordPhaseTime(name: string, delta_milliseconds: number): void;

/** Median of one row's readings over reading window. */
declare function medianPhase(name: string): number;

/** How many frames reading window spans. */
declare function framesRecent(): number;

/* Frame loop's own entry, which `src/browser/frame.ts` owns. */

/** Draw one frame, which is where every record page uploaded is issued. */
declare function renderFrame(now_seconds: number): void;

/** Pool grid's own geometry, as its last draw laid it out. */
declare const geometry_pool_drawn: {
  cell: number; gap: number; columns: number; rows: number; height: number;
};

/** How many objects of each kind last frame drew. */
declare const count_phase: Record<string, number>;

/** How many points last frame skipped for lying outside view. */
declare let count_points_culled: number;

/* Drawer and its objects list, which `src/browser/drawer.ts` and `objects_section.ts` own. */

/** Drawer itself, for reading whether it stands open. */
declare const drawer: HTMLElement;

/** List every live object gets one row in. */
declare const list_objects: HTMLElement;

/** Signature each standing row was built from, which reconciler diffs against. */
declare const signatures_row: Map<string, unknown>;

/** Rows still to build this pass, or nothing once list stands complete. */
declare let rows_pending: unknown;

/** Open drawer onto this object's own row, scrolling to it once it stands. */
declare function openPanelTo(handle: number | null): void;

/** Close whatever edit session stands, discarding its staged values. */
declare function endEditSession(): void;

/** Rebuild objects list against scene standing now. */
declare function refreshObjectsUI(): void;
