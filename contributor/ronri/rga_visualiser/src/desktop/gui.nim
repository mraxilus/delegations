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
  PATH_IMGUI* {.define: "visualiser.path_imgui".} = "../../dependencies/imgui"

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



#[ Face Roles ]#

type FaceRole* {.pure, size: sizeof(cint).} = enum  ## Define role whose face sets text.
  ## Ordinal is what `guiFaceHasGlyph` reads, so order here is order there.
  Interface,  ## Every text no other role takes.
  Label,  ## Selected object's name, over scene.
  Title,  ## Every panel heading.
  Mono,  ## Notation, and figures whose columns line up.



#[ Facade Lifetime ]#

# Import `gui_shim.cpp` one to one; see that file for what each wraps.
# Mark every binding `sideEffect`.
#   Compiler assumes imported body is pure, so `func` calling one would compile; marked,
#   only `proc` may reach effects, which is what makes `func` mean anything here.
proc init*(
  window: Window;
  context: GlContext;
  path_font, path_font_math, path_font_symbol: cstring;
  size_font: cfloat;
  path_font_label: cstring;
  size_label: cfloat;
  path_font_title, path_font_mono: cstring;
): bool {.sideEffect, importc: "guiInit".}
  ## Start Dear ImGui over SDL3 window and OpenGL context, loading six faces.
  ##   Fourth face, `path_font_label` at `size_label`, sets selected object's name label;
  ##   heavier than UI text. Missing file leaves label in UI face.
  ##   Fifth sets every heading and sixth sets notation and figures -- title and mono roles,
  ##   which page draws too. Missing file leaves that role in UI face rather than unset.

proc shutdown*() {.sideEffect, importc: "guiShutdown".}
  ## Tear Dear ImGui and both its backends down.

proc isFontLoaded*(): bool {.sideEffect, importc: "guiFontLoaded".}
  ## Report whether requested faces were accepted rather than default font.

proc isFontTitleLoaded*(): bool {.sideEffect, importc: "guiFontTitleLoaded".}
  ## Report whether headings have title face of their own rather than interface face.

proc isFontMonoLoaded*(): bool {.sideEffect, importc: "guiFontMonoLoaded".}
  ## Report whether notation has mono face of its own rather than interface face.

proc hasGlyph*(role: FaceRole, codepoint: uint32): bool {.sideEffect, importc: "guiFaceHasGlyph".}
  ## Report whether `role`'s face draws `codepoint` from glyph of its own, never `.notdef`.

proc processEvent*(event: ptr Event): bool {.discardable, sideEffect, importc: "guiProcessEvent".}
  ## Hand SDL event to Dear ImGui, reporting whether it wanted it.

proc wantsMouse*(): bool {.sideEffect, importc: "guiWantsMouse".}
  ## Report whether pointer is over Dear ImGui window rather than 3D view.

proc wantsKeyboard*(): bool {.sideEffect, importc: "guiWantsKeyboard".}
  ## Report Dear ImGui's own keyboard-capture flag; `wantsKeys` is guard used.

proc isNavEnabled*(): bool {.sideEffect, importc: "guiIsNavEnabled".}
  ## Report whether Dear ImGui's keyboard navigation is in force.
  ##   What makes every panel control reachable by Tab.

proc wantsKeys*(): bool {.sideEffect, importc: "guiWantsKeys".}
  ## Report whether key belongs to Dear ImGui rather than 3D view.
  ##   See shim on why this is not `wantsKeyboard`.

proc framerate*(): cfloat {.sideEffect, importc: "guiFramerate".}
  ## Report Dear ImGui's smoothed frames per second.

proc frameBegin*() {.sideEffect, importc: "guiFrameBegin".}
  ## Open frame for both backends and Dear ImGui.

proc frameEnd*() {.sideEffect, importc: "guiFrameEnd".}
  ## Render frame's draw lists through OpenGL backend.



#[ Facade Widgets ]#

# Import `gui_shim.cpp` one to one; see that file for what each wraps.
proc windowPlace*(x, y, width, height: cfloat) {.sideEffect, importc: "guiWindowPlace".}
  ## Place next window at `x`, `y` with given size, before `windowBegin`.

proc windowBegin*(name: cstring): bool {.sideEffect, importc: "guiWindowBegin".}
  ## Begin ordinary window named `name`, reporting whether it is open.

proc windowEnd*() {.sideEffect, importc: "guiWindowEnd".}
  ## End window begun by `windowBegin` or `windowBeginPinned`.

proc viewportWidth*(): cfloat {.sideEffect, importc: "guiViewportWidth".}
  ## Report drawable area's width, for anchoring something to corner of it.

proc viewportHeight*(): cfloat {.sideEffect, importc: "guiViewportHeight".}
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


proc childEnd*() {.sideEffect, importc: "guiChildEnd".}
  ## Close region `childBegin` or `childBeginBounded` opened.


proc menuBegin*(label, id: cstring; width: cfloat; is_forced: bool): bool
  {.importc: "guiMenuBegin", sideEffect.}
  ## Draw button opening menu, and open menu's own region where it is showing.
  ##   Menu hangs by its right edge from that button; `width` of zero sizes button to label.
  ##   `is_forced` opens it with no click, for run that cannot click.
  ##   `menuEnd` closes it only where this returned true.


proc menuEnd*() {.sideEffect, importc: "guiMenuEnd".}
  ## Close region `menuBegin` opened.
  ## End child region begun by `childBegin`.

proc text*(text: cstring) {.sideEffect, importc: "guiText".}
  ## Write text unformatted.

proc textWrapped*(text: cstring) {.sideEffect, importc: "guiTextWrapped".}
  ## Write text wrapped at panel's own right edge instead of clipping.

proc textWrappedAt*(text: cstring, width: cfloat) {.sideEffect, importc: "guiTextWrappedAt".}
  ## Write text wrapped at `width`, for window that sizes itself to its contents.

proc textTinted*(text: cstring; red, green, blue: cfloat) {.sideEffect, importc: "guiTextTinted".}
  ## Write text in given colour.

proc header*(label: cstring, is_open_first: bool): bool {.sideEffect, importc: "guiHeader".}
  ## Draw section header at browser's weight, reporting whether section is open.

proc button*(label: cstring): bool {.sideEffect, importc: "guiButton".}
  ## Draw button, reporting whether it was pressed.

proc buttonSmall*(label: cstring): bool {.sideEffect, importc: "guiButtonSmall".}
  ## Draw button without frame padding, reporting whether it was pressed.

proc buttonToggle*(label: cstring, is_on: bool, width: cfloat): bool
  {.importc: "guiButtonToggle", sideEffect.}
  ## Draw one segment of segmented control, tinted where it is option in force.

proc buttonWide*(label: cstring, width: cfloat): bool {.sideEffect, importc: "guiButtonWide".}
  ## Draw button filling given width, for one leading its section.

proc checkbox*(label: cstring, value: ptr bool): bool {.sideEffect, importc: "guiCheckbox".}
  ## Draw checkbox bound to `value`, reporting whether it changed.

proc dragFloat*(
  label: cstring; value: ptr cfloat; speed, lowest, highest: cfloat
): bool {.sideEffect, importc: "guiDragFloat".}
  ## Draw draggable number bound to `value`, reporting whether it changed.

proc dragFloat3*(
  label: cstring, values: ptr cfloat, speed: cfloat
): bool {.sideEffect, importc: "guiDragFloat3".}
  ## Draw three draggable numbers bound to `values`, reporting change.

proc inputText*(label: cstring, buffer: cstring, capacity: cint): bool
  {.importc: "guiInputText", sideEffect.}
  ## Draw text field editing `buffer` in place, reporting whether it changed.

proc inputSearch*(label, hint, buffer: cstring; capacity: cint): bool
  {.importc: "guiInputSearch", sideEffect.}
  ## Draw search field editing `buffer` in place, `hint` showing while empty; report change.
  ##   Escape clears it, then leaves it, as page's field does.

proc focusNext*() {.sideEffect, importc: "guiFocusNext".}
  ## Hand keyboard to next widget drawn.

proc openNext*() {.sideEffect, importc: "guiOpenNext".}
  ## Open next collapsing header drawn, whatever reader left it at.

proc combo*(
  label: cstring, index: ptr cint, entries: ptr cstring, count: cint
): bool {.sideEffect, importc: "guiCombo".}
  ## Draw drop-down over `items`, writing choice to `index`, reporting change.

proc colorEdit3*(label: cstring, values: ptr cfloat): bool {.sideEffect, importc: "guiColorEdit3".}
  ## Draw colour editor over three floats, reporting whether it changed.

proc childHeightForRows*(count: cint): cfloat {.sideEffect, importc: "guiChildHeightForRows".}
  ## Report how tall bordered `childBegin` region holding `count` text lines must be.
  ##   Measured against font loaded.

proc tabBarBegin*(name: cstring): bool {.sideEffect, importc: "guiTabBarBegin".}
  ## Begin row of tabs; closed with `tabBarEnd`, entered only where it returns true.

proc tabBarEnd*() {.sideEffect, importc: "guiTabBarEnd".}
  ## End row of tabs.

proc tabBegin*(label: cstring, is_forced: bool): bool {.sideEffect, importc: "guiTabBegin".}
  ## Begin one tab in row; true only for tab open, and closed with `tabEnd` only then.
  ##   `is_forced` opens it regardless of what reader last chose; see shim.

proc tabEnd*() {.sideEffect, importc: "guiTabEnd".}
  ## End tab begun by `tabBegin`.

proc monoPush*() {.sideEffect, importc: "guiMonoPush".}
  ## Set text written until `monoPop` in mono face: notation, figures, message line.
  ##   Pair rather than mono twin of every text proc: three of them write such text, and
  ##   caller says role once around block instead.
  ##   No-op where mono face was not loaded, so absent face degrades rather than raising.

proc monoPop*() {.sideEffect, importc: "guiMonoPop".}
  ## Stop setting text in mono face, returning to interface face.

proc separator*() {.sideEffect, importc: "guiSeparator".}
  ## Draw horizontal rule.

proc separatorText*(label: cstring) {.sideEffect, importc: "guiSeparatorText".}
  ## Draw horizontal rule carrying `label`.

proc sameLine*() {.sideEffect, importc: "guiSameLine".}
  ## Continue current line rather than starting next.


proc sameLineGap*(spacing: cfloat) {.sideEffect, importc: "guiSameLineGap".}
  ## Continue line with spacing given, for row cut into groups.

proc sameLineAt*(offset: cfloat) {.sideEffect, importc: "guiSameLineAt".}
  ## Continue current line at fixed distance from its start.
  ##   Column of controls then lines up whatever length of each name.

proc groupBegin*() {.sideEffect, importc: "guiGroupBegin".}
  ## Start treating what follows as one item.
  ##   Name stacked over its control then advances `sameLine` by width of pair.

proc groupEnd*() {.sideEffect, importc: "guiGroupEnd".}
  ## End group begun by `groupBegin`.

proc buttonSmallWidth*(label: cstring): cfloat {.sideEffect, importc: "guiButtonSmallWidth".}
  ## Report width `buttonSmall` would draw this label at.
  ##   For caller that must know before placing anything.

proc textWidth*(text: cstring): cfloat {.sideEffect, importc: "guiTextWidth".}
  ## Measure text as it will be drawn, in pixels.

proc alignRight*(width: cfloat) {.sideEffect, importc: "guiAlignRight".}
  ## Continue current line with `width` reserved against right edge.
  ##   Run of controls then ends flush there.

proc idPush*(id: cint) {.sideEffect, importc: "guiIdPush".}
  ## Push `id`, so repeated labels in loop stay distinct widgets.

proc idPop*() {.sideEffect, importc: "guiIdPop".}
  ## Pop id pushed by `idPush`.

proc contentWidth*(): cfloat {.sideEffect, importc: "guiContentWidth".}
  ## Report width still free on current line.


proc contentHeight*(): cfloat {.sideEffect, importc: "guiContentHeight".}
  ## Report height still free down page, for region ending before what follows it.

proc widthPush*(width: cfloat) {.sideEffect, importc: "guiWidthPush".}
  ## Set item width until `widthPop`.

proc widthPop*() {.sideEffect, importc: "guiWidthPop".}
  ## Restore item width `widthPush` replaced.

proc disabledPush*(is_disabled: bool) {.sideEffect, importc: "guiDisabledPush".}
  ## Disable every widget until `disabledPop` where `is_disabled`.

proc disabledPop*() {.sideEffect, importc: "guiDisabledPop".}
  ## End stretch `disabledPush` opened.

proc selectable*(
  label: cstring, is_selected: bool, width: cfloat
): bool {.sideEffect, importc: "guiSelectable".}
  ## Draw row with own selected-state highlight, reporting whether pressed.

proc alphaPush*(alpha: cfloat) {.sideEffect, importc: "guiAlphaPush".}
  ## Dim everything drawn until `alphaPop`, for content present but out of focus.

proc alphaPop*() {.sideEffect, importc: "guiAlphaPop".}
  ## Restore alpha `alphaPush` replaced.

proc textColorPush*(red, green, blue: cfloat) {.sideEffect, importc: "guiTextColorPush".}
  ## Tint every widget's text until `textColorPop`.

proc textColorPop*() {.sideEffect, importc: "guiTextColorPop".}
  ## Restore text colour `textColorPush` replaced.

proc tooltip*(text: cstring) {.sideEffect, importc: "guiTooltip".}
  ## Attach tooltip to widget laid out immediately before this call.

proc helpMarker*(text: cstring) {.sideEffect, importc: "guiHelpMarker".}
  ## Draw standalone `(?)` carrying `text` on hover.

proc progressBar*(
  fraction: cfloat;
  overlay: cstring;
  width, height: cfloat;
  red_fill, green_fill, blue_fill, red_track, green_track, blue_track: cfloat;
) {.sideEffect, importc: "guiProgressBar".}
  ## Fill `fraction` of bar in one colour, remainder in another.

proc plotLines*(
  label: cstring;
  values: ptr cfloat;
  count, offset: cint;
  overlay: cstring;
  scale_min, scale_max, width, height: cfloat;
) {.sideEffect, importc: "guiPlotLines".}
  ## Draw live line graph over `count` samples, read from `offset` frames back.

proc poolBar*(colours: ptr cfloat, count: cint, cell_size: cfloat)
  {.importc: "guiPoolBar", sideEffect.}
  ## Draw one square cell per pool slot, wrapped to panel's width.
  ##   `colours` addresses `count` * 3 floats, red then green then blue per cell.

proc overlayLine*(x1, y1, x2, y2, red, green, blue, alpha, thickness: cfloat)
  {.importc: "guiOverlayLine", sideEffect.}
  ## Draw line onto overlay layer, for feedback belonging to 3D view.

proc overlayCircle*(
  centre_x, centre_y, radius, red, green, blue, alpha, thickness: cfloat; is_over_windows: cint
) {.sideEffect, importc: "guiOverlayCircle".}
  ## Stroke whole circle.
  ##   `is_over_windows` picks layer: zero for mark on object, which panels cover; one for
  ##   drag menu's centre dot, part of control being steered; see shim's `overlayList`.

proc overlayArc*(
  centre_x, centre_y, radius, fraction, red, green, blue, alpha, thickness: cfloat
) {.sideEffect, importc: "guiOverlayArc".}
  ## Stroke `fraction` of circle, clockwise from twelve o'clock; whole one at 1.

proc overlayChip*(
  centre_x, centre_y, width, height, red, green, blue, alpha, rounding: cfloat
) {.sideEffect, importc: "guiOverlayChip".}
  ## Fill rounded rectangle centred on `centre_x`/`centre_y`, for one wedge of drag menu.

proc overlayText*(centre_x, centre_y, red, green, blue, alpha: cfloat; text: cstring)
  {.importc: "guiOverlayText", sideEffect.}
  ## Write text centred on `centre_x`/`centre_y`, measured against font loaded.

proc labelWidth*(text: cstring): cfloat {.sideEffect, importc: "guiLabelWidth".}
  ## Measure name label as `overlayLabel` draws it, in label's face.
  ##   For pushing it beside line by its own box.

proc overlayLabel*(
  centre_x, centre_y, fill_red, fill_green, fill_blue, stroke_red, stroke_green, stroke_blue,
  alpha: cfloat; text: cstring
) {.sideEffect, importc: "guiOverlayLabel".}
  ## Write text centred on `centre_x`/`centre_y` in fill colour, outlined in stroke colour at
  ##   `alpha`.
  ##   Selected object's name above its marker; on background list, as markers are.

proc overlayPolyline*(
  points: ptr cfloat; count: cint; red, green, blue, alpha, thickness: cfloat; is_closed: cint
) {.sideEffect, importc: "guiOverlayPolyline".}
  ## Stroke one joined path through `count` points, `points` addressing that many x/y pairs.
  ##   One call rather than segment each, so corners join cleanly.

proc overlayRibbon*(
  points: ptr cfloat; count: cint; red, green, blue, alpha: cfloat
) {.sideEffect, importc: "guiOverlayRibbon".}
  ## Fill one closed outline through `count` points.
  ##   For mark whose width varies along its length: orientation pulse, and drag band's
  ##   head.
