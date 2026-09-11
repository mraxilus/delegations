## Bind facade over Dear ImGui declared in `gui_shim.cpp`.
##
## Dear ImGui is depended on rather than derived.
##   Immediate-mode widget set is external concern, like windowing and drivers.
##   Its interface is C++ with overloads and default arguments, which Nim cannot import.
##   `gui_shim.cpp` flattens slice used into C entry points and this module binds them.
##   Cost is that adding widget touches two files.
## Dear ImGui and its SDL3 and OpenGL 3 backends are compiled straight into binary.
##   No prebuilt library has to be found at link time.
##   Sources are expected at `PATH_IMGUI`; see `dependencies.list`.
## Built-in font carries no mathematical operators, so TrueType face is loaded over it.
##   Where file is absent built-in font stands and notation degrades to boxes;
##   `isFontLoaded` reports which happened.
##
## Desktop-only; unreachable from browser build. See PROVENANCE.md's "Render Paths".

{.experimental: "strictFuncs".}

import std/os

import ./sdl3



#[ Dependency Configuration ]#

# Allow caller to point at Dear ImGui checkout elsewhere.
#   E.g. `--define:visualiser.path_imgui=/usr/src/imgui`.
const
  PATH_IMGUI* {.define: "visualiser.path_imgui".} = "../../deps/imgui"

  PATH_IMGUI_ROOTED =
    if isAbsolute(PATH_IMGUI): PATH_IMGUI
    else: currentSourcePath().parentDir / PATH_IMGUI
    ## Resolve dependency against this file, as C compiler runs from elsewhere.

{.passC: "-I" & PATH_IMGUI_ROOTED.}

# Widen `ImWchar` to 32 bits, which Dear ImGui offers and defaults off.
#   Notation uses Lengyel's bold operands (`𝐦`, U+1D426), and 16-bit `ImWchar` cannot
#   express codepoint past U+FFFF.
#   Compiler flag rather than edit to checkout's `imconfig.h`: checkout is build-time
#   dependency never committed, so edit would not survive reclone.
{.passC: "-DIMGUI_USE_WCHAR32".}

# Compile Dear ImGui and its two backends into binary, alongside facade over them.
{.compile: PATH_IMGUI_ROOTED / "imgui.cpp".}
{.compile: PATH_IMGUI_ROOTED / "imgui_draw.cpp".}
{.compile: PATH_IMGUI_ROOTED / "imgui_tables.cpp".}
{.compile: PATH_IMGUI_ROOTED / "imgui_widgets.cpp".}
{.compile: PATH_IMGUI_ROOTED / "backends/imgui_impl_sdl3.cpp".}
{.compile: PATH_IMGUI_ROOTED / "backends/imgui_impl_opengl3.cpp".}
{.compile: "gui_shim.cpp".}



#[ Facade Lifetime ]#

# Import `gui_shim.cpp` one to one; see that file for what each wraps.
# Mark every binding `sideEffect`.
#   Compiler assumes imported body is pure, so `func` calling one would compile; marked,
#   only `proc` may reach effects, which is what makes `func` mean anything here.
proc init*(
  window: Window; context: GlContext;
  path_font, path_font_math, path_font_symbol: cstring; size_font: cfloat;
  path_font_label: cstring; size_label: cfloat;
  path_font_title, path_font_mono: cstring
): bool {.importc: "guiInit", sideEffect.}
  ## Start Dear ImGui over SDL3 window and OpenGL context, loading six faces.
  ##   Fourth face, `path_font_label` at `size_label`, sets selected object's name label;
  ##   heavier than UI text. Missing file leaves label in UI face.
  ##   Fifth sets every heading and sixth sets notation and figures -- title and mono roles,
  ##   which page draws too. Missing file leaves that role in UI face rather than unset.

proc shutdown*() {.importc: "guiShutdown", sideEffect.}
  ## Tear Dear ImGui and both its backends down.

proc isFontLoaded*(): bool {.importc: "guiFontLoaded", sideEffect.}
  ## Report whether requested faces were accepted rather than default font.

proc isFontTitleLoaded*(): bool {.importc: "guiFontTitleLoaded", sideEffect.}
  ## Report whether headings have title face of their own rather than interface face.

proc isFontMonoLoaded*(): bool {.importc: "guiFontMonoLoaded", sideEffect.}
  ## Report whether notation has mono face of its own rather than interface face.

proc processEvent*(event: ptr Event): bool {.importc: "guiProcessEvent", discardable, sideEffect.}
  ## Hand SDL event to Dear ImGui, reporting whether it wanted it.

proc wantsMouse*(): bool {.importc: "guiWantsMouse", sideEffect.}
  ## Report whether pointer is over Dear ImGui window rather than 3D view.

proc wantsKeyboard*(): bool {.importc: "guiWantsKeyboard", sideEffect.}
  ## Report Dear ImGui's own keyboard-capture flag; `wantsKeys` is guard used.

proc isNavEnabled*(): bool {.importc: "guiIsNavEnabled", sideEffect.}
  ## Report whether Dear ImGui's keyboard navigation is in force.
  ##   What makes every panel control reachable by Tab.

proc wantsKeys*(): bool {.importc: "guiWantsKeys", sideEffect.}
  ## Report whether key belongs to Dear ImGui rather than 3D view.
  ##   See shim on why this is not `wantsKeyboard`.

proc framerate*(): cfloat {.importc: "guiFramerate", sideEffect.}
  ## Report Dear ImGui's smoothed frames per second.

proc frameBegin*() {.importc: "guiFrameBegin", sideEffect.}
  ## Open frame for both backends and Dear ImGui.

proc frameEnd*() {.importc: "guiFrameEnd", sideEffect.}
  ## Render frame's draw lists through OpenGL backend.



#[ Facade Widgets ]#

# Import `gui_shim.cpp` one to one; see that file for what each wraps.
proc windowPlace*(x, y, width, height: cfloat) {.importc: "guiWindowPlace", sideEffect.}
  ## Place next window at `x`, `y` with given size, before `windowBegin`.

proc windowBegin*(name: cstring): bool {.importc: "guiWindowBegin", sideEffect.}
  ## Begin ordinary window named `name`, reporting whether it is open.

proc windowEnd*() {.importc: "guiWindowEnd", sideEffect.}
  ## End window begun by `windowBegin` or `windowBeginPinned`.

proc viewportWidth*(): cfloat {.importc: "guiViewportWidth", sideEffect.}
  ## Report drawable area's width, for anchoring something to corner of it.

proc viewportHeight*(): cfloat {.importc: "guiViewportHeight", sideEffect.}
  ## Report drawable area's height, for anchoring something to corner of it.

proc windowBeginPinned*(name: cstring; x, y, pivot_x, pivot_y: cfloat): bool
  {.importc: "guiWindowBeginPinned", sideEffect.}
  ## Begin undecorated window pinned to `x`/`y`; closed with `windowEnd`.
  ##   `pivot` names which of its corners that is.

proc childBegin*(name: cstring; width, height: cfloat): bool
  {.importc: "guiChildBegin", sideEffect.}
  ## Begin bordered child region of given size, scrolling what overflows it.

proc childBeginBounded*(name: cstring; width, height_max: cfloat): bool
  {.importc: "guiChildBeginBounded", sideEffect.}
  ## Open region as tall as its content, up to bound, scrolling inside bound past it.
  ##   `childEnd` closes it, whatever this returned.


proc childEnd*() {.importc: "guiChildEnd", sideEffect.}


proc menuBegin*(label, id: cstring, is_forced: bool): bool
  {.importc: "guiMenuBegin", sideEffect.}
  ## Draw button opening menu, and open menu's own region where it is showing.
  ##   `is_forced` opens it with no click, for run that cannot click.
  ##   `menuEnd` closes it only where this returned true.


proc menuEnd*() {.importc: "guiMenuEnd", sideEffect.}
  ## Close region `menuBegin` opened.
  ## End child region begun by `childBegin`.

proc text*(text: cstring) {.importc: "guiText", sideEffect.}
  ## Write text unformatted.

proc textWrapped*(text: cstring) {.importc: "guiTextWrapped", sideEffect.}
  ## Write text wrapped at panel's own right edge instead of clipping.

proc textWrappedAt*(text: cstring, width: cfloat) {.importc: "guiTextWrappedAt", sideEffect.}
  ## Write text wrapped at `width`, for window that sizes itself to its contents.

proc textTinted*(text: cstring; red, green, blue: cfloat) {.importc: "guiTextTinted", sideEffect.}
  ## Write text in given colour.

proc header*(label: cstring, is_open_first: bool): bool {.importc: "guiHeader", sideEffect.}
  ## Draw section header at browser's weight, reporting whether section is open.

proc button*(label: cstring): bool {.importc: "guiButton", sideEffect.}
  ## Draw button, reporting whether it was pressed.

proc buttonSmall*(label: cstring): bool {.importc: "guiButtonSmall", sideEffect.}
  ## Draw button without frame padding, reporting whether it was pressed.

proc buttonToggle*(label: cstring, is_on: bool, width: cfloat): bool
  {.importc: "guiButtonToggle", sideEffect.}
  ## Draw one segment of segmented control, tinted where it is option in force.

proc buttonWide*(label: cstring, width: cfloat): bool {.importc: "guiButtonWide", sideEffect.}
  ## Draw button filling given width, for one leading its section.

proc checkbox*(label: cstring, value: ptr bool): bool {.importc: "guiCheckbox", sideEffect.}
  ## Draw checkbox bound to `value`, reporting whether it changed.

proc dragFloat*(
  label: cstring; value: ptr cfloat; speed, lowest, highest: cfloat
): bool {.importc: "guiDragFloat", sideEffect.}
  ## Draw draggable number bound to `value`, reporting whether it changed.

proc dragFloat3*(
  label: cstring, values: ptr cfloat, speed: cfloat
): bool {.importc: "guiDragFloat3", sideEffect.}
  ## Draw three draggable numbers bound to `values`, reporting change.

proc inputText*(label: cstring, buffer: cstring, capacity: cint): bool
  {.importc: "guiInputText", sideEffect.}
  ## Draw text field editing `buffer` in place, reporting whether it changed.

proc combo*(
  label: cstring, index: ptr cint, entries: ptr cstring, count: cint
): bool {.importc: "guiCombo", sideEffect.}
  ## Draw drop-down over `items`, writing choice to `index`, reporting change.

proc colorEdit3*(label: cstring, values: ptr cfloat): bool {.importc: "guiColorEdit3", sideEffect.}
  ## Draw colour editor over three floats, reporting whether it changed.

proc childHeightForRows*(count: cint): cfloat {.importc: "guiChildHeightForRows", sideEffect.}
  ## Report how tall bordered `childBegin` region holding `count` text lines must be.
  ##   Measured against font loaded.

proc tabBarBegin*(name: cstring): bool {.importc: "guiTabBarBegin", sideEffect.}
  ## Begin row of tabs; closed with `tabBarEnd`, entered only where it returns true.

proc tabBarEnd*() {.importc: "guiTabBarEnd", sideEffect.}
  ## End row of tabs.

proc tabBegin*(label: cstring, is_forced: bool): bool {.importc: "guiTabBegin", sideEffect.}
  ## Begin one tab in row; true only for tab open, and closed with `tabEnd` only then.
  ##   `is_forced` opens it regardless of what reader last chose; see shim.

proc tabEnd*() {.importc: "guiTabEnd", sideEffect.}
  ## End tab begun by `tabBegin`.

proc monoPush*() {.importc: "guiMonoPush", sideEffect.}
  ## Set text written until `monoPop` in mono face: notation, figures, message line.
  ##   Pair rather than mono twin of every text proc: three of them write such text, and
  ##   caller says role once around block instead.
  ##   No-op where mono face was not loaded, so absent face degrades rather than raising.

proc monoPop*() {.importc: "guiMonoPop", sideEffect.}
  ## Stop setting text in mono face, returning to interface face.

proc separator*() {.importc: "guiSeparator", sideEffect.}
  ## Draw horizontal rule.

proc separatorText*(label: cstring) {.importc: "guiSeparatorText", sideEffect.}
  ## Draw horizontal rule carrying `label`.

proc sameLine*() {.importc: "guiSameLine", sideEffect.}
  ## Continue current line rather than starting next.

proc sameLineAt*(offset: cfloat) {.importc: "guiSameLineAt", sideEffect.}
  ## Continue current line at fixed distance from its start.
  ##   Column of controls then lines up whatever length of each name.

proc groupBegin*() {.importc: "guiGroupBegin", sideEffect.}
  ## Start treating what follows as one item.
  ##   Name stacked over its control then advances `sameLine` by width of pair.

proc groupEnd*() {.importc: "guiGroupEnd", sideEffect.}
  ## End group begun by `groupBegin`.

proc buttonSmallWidth*(label: cstring): cfloat {.importc: "guiButtonSmallWidth", sideEffect.}
  ## Report width `buttonSmall` would draw this label at.
  ##   For caller that must know before placing anything.

proc textWidth*(text: cstring): cfloat {.importc: "guiTextWidth", sideEffect.}
  ## Measure text as it will be drawn, in pixels.

proc alignRight*(width: cfloat) {.importc: "guiAlignRight", sideEffect.}
  ## Continue current line with `width` reserved against right edge.
  ##   Run of controls then ends flush there.

proc idPush*(id: cint) {.importc: "guiIdPush", sideEffect.}
  ## Push `id`, so repeated labels in loop stay distinct widgets.

proc idPop*() {.importc: "guiIdPop", sideEffect.}
  ## Pop id pushed by `idPush`.

proc contentWidth*(): cfloat {.importc: "guiContentWidth", sideEffect.}
  ## Report width still free on current line.


proc contentHeight*(): cfloat {.importc: "guiContentHeight", sideEffect.}
  ## Report height still free down page, for region ending before what follows it.

proc widthPush*(width: cfloat) {.importc: "guiWidthPush", sideEffect.}
  ## Set item width until `widthPop`.

proc widthPop*() {.importc: "guiWidthPop", sideEffect.}
  ## Restore item width `widthPush` replaced.

proc disabledPush*(is_disabled: bool) {.importc: "guiDisabledPush", sideEffect.}
  ## Disable every widget until `disabledPop` where `is_disabled`.

proc disabledPop*() {.importc: "guiDisabledPop", sideEffect.}
  ## End stretch `disabledPush` opened.

proc selectable*(
  label: cstring, is_selected: bool, width: cfloat
): bool {.importc: "guiSelectable", sideEffect.}
  ## Draw row with own selected-state highlight, reporting whether pressed.

proc alphaPush*(alpha: cfloat) {.importc: "guiAlphaPush", sideEffect.}
  ## Dim everything drawn until `alphaPop`, for content present but out of focus.

proc alphaPop*() {.importc: "guiAlphaPop", sideEffect.}
  ## Restore alpha `alphaPush` replaced.

proc textColorPush*(red, green, blue: cfloat) {.importc: "guiTextColorPush", sideEffect.}
  ## Tint every widget's text until `textColorPop`.

proc textColorPop*() {.importc: "guiTextColorPop", sideEffect.}
  ## Restore text colour `textColorPush` replaced.

proc tooltip*(text: cstring) {.importc: "guiTooltip", sideEffect.}
  ## Attach tooltip to widget laid out immediately before this call.

proc helpMarker*(text: cstring) {.importc: "guiHelpMarker", sideEffect.}
  ## Draw standalone `(?)` carrying `text` on hover.

proc progressBar*(
  fraction: cfloat; overlay: cstring; width, height: cfloat;
  red_fill, green_fill, blue_fill, red_track, green_track, blue_track: cfloat;
) {.importc: "guiProgressBar", sideEffect.}
  ## Fill `fraction` of bar in one colour, remainder in another.

proc plotLines*(
  label: cstring; values: ptr cfloat; count, offset: cint; overlay: cstring;
  scale_min, scale_max, width, height: cfloat;
) {.importc: "guiPlotLines", sideEffect.}
  ## Draw live line graph over `count` samples, read from `offset` frames back.

proc poolBar*(colours: ptr cfloat, count: cint, cell_size: cfloat)
  {.importc: "guiPoolBar", sideEffect.}
  ## Draw one square cell per pool slot, wrapped to panel's width.
  ##   `colours` addresses `count` * 3 floats, red then green then blue per cell.

proc overlayLine*(x1, y1, x2, y2, red, green, blue, alpha, thickness: cfloat)
  {.importc: "guiOverlayLine", sideEffect.}
  ## Draw line onto overlay layer, for feedback belonging to 3D view.

proc overlayCircle*(
  cx, cy, radius, red, green, blue, alpha, thickness: cfloat; is_over_windows: cint
) {.importc: "guiOverlayCircle", sideEffect.}
  ## Stroke whole circle.
  ##   `is_over_windows` picks layer: zero for mark on object, which panels cover; one for
  ##   drag menu's centre dot, part of control being steered; see shim's `overlayList`.

proc overlayArc*(
  cx, cy, radius, fraction, red, green, blue, alpha, thickness: cfloat
) {.importc: "guiOverlayArc", sideEffect.}
  ## Stroke `fraction` of circle, clockwise from twelve o'clock; whole one at 1.

proc overlayChip*(
  cx, cy, width, height, red, green, blue, alpha, rounding: cfloat
) {.importc: "guiOverlayChip", sideEffect.}
  ## Fill rounded rectangle centred on `cx`/`cy`, for one wedge of drag menu.

proc overlayText*(cx, cy, red, green, blue, alpha: cfloat; text: cstring)
  {.importc: "guiOverlayText", sideEffect.}
  ## Write text centred on `cx`/`cy`, measured against font loaded.

proc labelWidth*(text: cstring): cfloat {.importc: "guiLabelWidth", sideEffect.}
  ## Measure name label as `overlayLabel` draws it, in label's face.
  ##   For pushing it beside line by its own box.

proc overlayLabel*(
  cx, cy, fill_red, fill_green, fill_blue, stroke_red, stroke_green, stroke_blue,
  alpha: cfloat; text: cstring
) {.importc: "guiOverlayLabel", sideEffect.}
  ## Write text centred on `cx`/`cy` in fill colour, outlined in stroke colour at `alpha`.
  ##   Selected object's name above its marker; on background list, as markers are.

proc overlayPolyline*(
  points: ptr cfloat; count: cint; red, green, blue, alpha, thickness: cfloat;
  is_closed: cint
) {.importc: "guiOverlayPolyline", sideEffect.}
  ## Stroke one joined path through `count` points, `points` addressing that many x/y pairs.
  ##   One call rather than segment each, so corners join cleanly.

proc overlayRibbon*(
  points: ptr cfloat; count: cint; red, green, blue, alpha: cfloat
) {.importc: "guiOverlayRibbon", sideEffect.}
  ## Fill one closed outline through `count` points.
  ##   For mark whose width varies along its length: orientation pulse, and drag band's
  ##   head.
