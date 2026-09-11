// Flatten slice of Dear ImGui this visualiser calls into C entry points Nim can import;
//   not Nim because source cannot reach this at all: Dear ImGui's interface is C++ with
//   overloads, default arguments and namespaces, and Nim's `cpp` backend imports none of
//   those three. That is Article II.9's first ground, and this file is its plainest case in
//   this repository -- there is no glue that would reach these widgets from Nim, at any
//   cost, because there is no symbol to bind.
//   Facade rather than generated binding: it declares exactly widgets used, and every
//   default relied on is written here once rather than repeated at every call site.
// Backends are Dear ImGui's own for SDL3 and OpenGL 3, used unmodified.
//
// Desktop-only; unreachable from browser build. See PROVENANCE.md's "Render Paths".

#include "imgui.h"
#include "backends/imgui_impl_sdl3.h"
#include "backends/imgui_impl_opengl3.h"

#include <SDL3/SDL.h>

#include <cfloat>
#include <utility>

// Build atlas from three faces, merged in order of decreasing generality.
//   No single face covers what this GUI writes.
//   Each range list names only what its own face is here to supply, so glyph is never
//   taken from face that merely happens to have it too.
//   Verified by rendering every non-ASCII codepoint source actually uses against all
//   three faces, none missing; re-run that check before narrowing any range below.
static const ImWchar RANGES_TEXT[] = {
  0x0020, 0x00FF, // Latin and supplement.
  0x02B0, 0x02FF, // Spacing modifiers, which notation accents its operands with.
  0x2010, 0x205F, // Punctuation, superscripts and subscripts.
  0x2080, 0x209F, // Subscript digits, used by basis element names.
  0,
};
static const ImWchar RANGES_MATH[] = {
  0x2190, 0x21FF, // Arrows.
  0x2200, 0x22FF, // Mathematical operators: wedge, antiwedge, dots and complements.
  0x2300, 0x23FF, // Miscellaneous technical.
  0x27C0, 0x27EF, // Miscellaneous Mathematical Symbols-A: geometric (anti)product.
  0x2A00, 0x2AFF, // Supplemental Mathematical Operators.
  0x1D400, 0x1D7FF, // Mathematical alphanumerics: Lengyel's own bold operands.
  0,
};
static const ImWchar RANGES_SYMBOL[] = {
  0x25A0, 0x25FF, // Geometric shapes.
  0x2600, 0x26FF, // Miscellaneous symbols: bulk and weight dual stars.
  0x2700, 0x27BF, // Dingbats: abandon button's own cross.
  0,
};

// Remember whether requested face was accepted.
//   Dear ImGui reports that only at moment of loading, and caller wants to say so once,
//   at startup.
static bool is_font_loaded = false;
// Hold face selected object's name label is set in, heavier than UI text.
//   Null where its file was missing, and label falls back to UI face.
static ImFont *font_label = nullptr;
static float size_font_label = 0.0f;
// Hold two faces standing for other two roles page's stylesheet names: title face every
//   heading is set in, and mono face notation and figures are.
//   Null where file was missing, and role falls back to UI face rather than to nothing --
//   same degrading absent face already earns everywhere else here.
static ImFont *font_title = nullptr;
static ImFont *font_mono = nullptr;

extern "C" {

bool guiInit(SDL_Window* window, SDL_GLContext context, const char* path_font,
             const char* path_font_math, const char* path_font_symbol, float size_font,
             const char* path_font_label, float size_label, const char* path_font_title,
             const char* path_font_mono) {
  IMGUI_CHECKVERSION();
  if (ImGui::CreateContext() == nullptr) return false;
  ImGui::StyleColorsDark();
  // Let keyboard reach panels at all.
  //   Without this every button, combo and field here is pointer-only, total WCAG 2.1.1
  //   failure, and no amount of binding keys in application itself could fix it, since
  //   widgets are Dear ImGui's and only its own navigation can move between them.
  ImGui::GetIO().ConfigFlags |= ImGuiConfigFlags_NavEnableKeyboard;
  // Keep panel layout in memory only, so running visualiser leaves no file behind.
  ImGui::GetIO().IniFilename = nullptr;
  ImGui::GetStyle().WindowRounding = 4.0f;
  ImGui::GetStyle().FrameRounding = 3.0f;
  if (!ImGui_ImplSDL3_InitForOpenGL(window, context)) return false;
  if (!ImGui_ImplOpenGL3_Init("#version 330 core")) return false;
  if (path_font != nullptr && path_font[0] != '\0') {
    ImFontAtlas* atlas = ImGui::GetIO().Fonts;
    is_font_loaded =
        atlas->AddFontFromFileTTF(path_font, size_font, nullptr, RANGES_TEXT) != nullptr;
    // Merge two supplementary faces into that same font rather than adding separate fonts.
    //   Merged range is drawn without caller having to push font around whichever
    //   character happens to need it, which no caller could do mid-string anyway.
    ImFontConfig merge;
    merge.MergeMode = true;
    for (auto pair : {std::pair<const char*, const ImWchar*>{path_font_math, RANGES_MATH},
                      {path_font_symbol, RANGES_SYMBOL}}) {
      if (pair.first == nullptr || pair.first[0] == '\0') continue;
      if (atlas->AddFontFromFileTTF(pair.first, size_font, &merge, pair.second) == nullptr)
        is_font_loaded = false;
    }
    // Add label's own face second, so UI face stays atlas's default.
    //   Same two supplementary faces merged in at label's size: label carries operator
    //   notation too, and wedge drew as box without them.
    size_font_label = size_label;
    if (path_font_label != nullptr && path_font_label[0] != '\0') {
      font_label = atlas->AddFontFromFileTTF(path_font_label, size_label, nullptr, RANGES_TEXT);
      if (font_label != nullptr) {
        for (auto pair : {std::pair<const char*, const ImWchar*>{path_font_math, RANGES_MATH},
                          {path_font_symbol, RANGES_SYMBOL}}) {
          if (pair.first == nullptr || pair.first[0] == '\0') continue;
          atlas->AddFontFromFileTTF(pair.first, size_label, &merge, pair.second);
        }
      }
    }
    // Add title face third, at UI size. No supplementary range is merged into it:
    //   headings are words this source writes -- `apply`, `view`, `diagnostics`,
    //   `objects (n of m)` -- and none carries operator or subscript. Merging both ranges
    //   again would cost atlas two more copies of them for glyphs no heading asks for.
    if (path_font_title != nullptr && path_font_title[0] != '\0')
      font_title = atlas->AddFontFromFileTTF(path_font_title, size_font, nullptr, RANGES_TEXT);
    // Add mono face last, with both supplementary ranges merged in.
    //   Unlike headings, text set in it is exactly text carrying notation: coefficient
    //   line reads `horizon plane: 2.038 e321` with wedge and subscripts in it, so absent
    //   merge would draw boxes in very rows this face exists for.
    if (path_font_mono != nullptr && path_font_mono[0] != '\0') {
      font_mono = atlas->AddFontFromFileTTF(path_font_mono, size_font, nullptr, RANGES_TEXT);
      if (font_mono != nullptr) {
        for (auto pair : {std::pair<const char*, const ImWchar*>{path_font_math, RANGES_MATH},
                          {path_font_symbol, RANGES_SYMBOL}}) {
          if (pair.first == nullptr || pair.first[0] == '\0') continue;
          atlas->AddFontFromFileTTF(pair.first, size_font, &merge, pair.second);
        }
      }
    }
  }
  return true;
}

void guiShutdown() {
  ImGui_ImplOpenGL3_Shutdown();
  ImGui_ImplSDL3_Shutdown();
  ImGui::DestroyContext();
}

bool guiFontLoaded() { return is_font_loaded; }

// Report whether title and mono roles got faces of their own, rather than falling back.
//   Separate from `guiFontLoaded`, which answers for interface face and its merged ranges:
//   role drawn in wrong face is not run that failed to start, and headless run says which.
bool guiFontTitleLoaded() { return font_title != nullptr; }

bool guiFontMonoLoaded() { return font_mono != nullptr; }

bool guiProcessEvent(const SDL_Event* event) { return ImGui_ImplSDL3_ProcessEvent(event); }

bool guiWantsMouse() { return ImGui::GetIO().WantCaptureMouse; }

bool guiWantsKeyboard() { return ImGui::GetIO().WantCaptureKeyboard; }

// Report whether keyboard navigation is actually in force.
//   For headless run to check configuration it cannot check behaviour of: window that
//   never takes focus never gives Dear ImGui focus its navigation needs, so scripted Tab
//   demonstrates nothing there, while this at least demonstrates flag is set.
bool guiIsNavEnabled() {
  return (ImGui::GetIO().ConfigFlags & ImGuiConfigFlags_NavEnableKeyboard) != 0;
}

// Report whether Dear ImGui should get key rather than 3D view behind it.
//   Not `WantCaptureKeyboard`, which is wrong here.
//     Enabling keyboard navigation makes that flag true from very first frame, with
//     nothing focused and nobody having pressed Tab, so using it swallows every view key
//     outright; `--drive-keys` shows camera still at its opening placement.
//   Two things genuinely mean "these keys are ImGui's": text field is taking input, or
//   navigation has actually landed on widget.
//     Neither is true while reader is simply looking at scene, which is when view wants
//     its own keys.
bool guiWantsKeys() {
  return ImGui::GetIO().WantTextInput || ImGui::IsAnyItemFocused();
}

float guiFramerate() { return ImGui::GetIO().Framerate; }

void guiFrameBegin() {
  ImGui_ImplOpenGL3_NewFrame();
  ImGui_ImplSDL3_NewFrame();
  ImGui::NewFrame();
}

void guiFrameEnd() {
  ImGui::Render();
  ImGui_ImplOpenGL3_RenderDrawData(ImGui::GetDrawData());
}

void guiWindowPlace(float x, float y, float width, float height) {
  ImGui::SetNextWindowPos(ImVec2(x, y), ImGuiCond_FirstUseEver);
  ImGui::SetNextWindowSize(ImVec2(width, height), ImGuiCond_FirstUseEver);
}

// Report drawable area, so caller can anchor something to corner of it.
//   Changes with window, which is point.
float guiViewportWidth() { return ImGui::GetIO().DisplaySize.x; }
float guiViewportHeight() { return ImGui::GetIO().DisplaySize.y; }

// Begin window pinned where it is put, with nothing reader could grab.
//   No title bar, no resize corner, no scrollbar, and sized to whatever it ends up
//   holding.
//   `pivot` is which of window's own corners `x`/`y` names.
//     (1, 1) anchors its bottom-right, which is what corner affordance wants and what
//     caller would otherwise have to compute by laying window out once and measuring it.
bool guiWindowBeginPinned(const char *name, float x, float y, float pivot_x,
                          float pivot_y) {
  ImGui::SetNextWindowPos(ImVec2(x, y), ImGuiCond_Always, ImVec2(pivot_x, pivot_y));
  return ImGui::Begin(name, nullptr,
                      ImGuiWindowFlags_NoTitleBar | ImGuiWindowFlags_NoResize |
                          ImGuiWindowFlags_NoMove | ImGuiWindowFlags_NoScrollbar |
                          ImGuiWindowFlags_NoSavedSettings |
                          ImGuiWindowFlags_AlwaysAutoResize);
}

bool guiWindowBegin(const char* name) { return ImGui::Begin(name); }

void guiWindowEnd() { ImGui::End(); }

bool guiChildBegin(const char* name, float width, float height) {
  return ImGui::BeginChild(name, ImVec2(width, height), ImGuiChildFlags_Borders);
}

// Region hugging its own content up to bound, and scrolling inside that bound past it.
//   For list whose length is scene's to decide: fixed height leaves short list sitting in
//   blank, and unbounded list pushes everything under it off window.
//   Auto-size is measured only while region is on screen (see `ImGuiChildFlags_AutoResizeY`),
//   which is what this wants: region scrolled out of view is not one reader is reading.
bool guiChildBeginBounded(const char* name, float width, float height_max) {
  ImGui::SetNextWindowSizeConstraints(ImVec2(0.0f, 0.0f), ImVec2(FLT_MAX, height_max));
  return ImGui::BeginChild(
    name, ImVec2(width, 0.0f), ImGuiChildFlags_Borders | ImGuiChildFlags_AutoResizeY);
}

void guiChildEnd() { ImGui::EndChild(); }

// Menu opened by button, drawn as popup under it.
//   Browser hides what is reached for rarely behind `☰` in its chip row; this is that
//   control in idiom Dear ImGui has for it, so two front-ends put one thing in one place.
//   `is_forced` opens it without click, for headless run that has no pointer to click with
//   -- same door `--drive-help` uses on help's tabs.
//   Caller closes with `guiMenuEnd` only where this returned true, which is what
//   `ImGui::BeginPopup` asks of every caller.
bool guiMenuBegin(const char* label, const char* id, bool is_forced) {
  if (ImGui::Button(label) || is_forced) ImGui::OpenPopup(id);
  // Hang menu from its own button rather than from pointer, which is where popup opens by
  //   default. Browser's menu hangs from its chip, and menu that lands somewhere else each
  //   time is menu reader has to find twice.
  const ImGuiStyle& style = ImGui::GetStyle();
  ImGui::SetNextWindowPos(
    ImVec2(ImGui::GetItemRectMin().x, ImGui::GetItemRectMax().y + style.ItemSpacing.y));
  return ImGui::BeginPopup(id);
}

void guiMenuEnd() { ImGui::EndPopup(); }

void guiText(const char* text) { ImGui::TextUnformatted(text); }

// Wrap at panel's own right edge instead of clipping.
//   For line whose length is data's to decide: full multivector runs past any width
//   worth reserving for it.
void guiTextWrapped(const char* text) {
  ImGui::PushTextWrapPos(0.0f);
  ImGui::TextUnformatted(text);
  ImGui::PopTextWrapPos();
}

// Wrap at width caller states, for window that sizes itself to its contents.
//   Zero, what `guiTextWrapped` passes, means content region's right edge, which in
//   auto-sizing window is decided by widest item in it.
//     Wrapped paragraph is then both input to that width and consequence of it, and
//     settles wherever circularity leaves it.
//   Help panel already knows width it wants, so it says so.
void guiTextWrappedAt(const char* text, float width) {
  ImGui::PushTextWrapPos(ImGui::GetCursorPosX() + width);
  ImGui::TextUnformatted(text);
  ImGui::PopTextWrapPos();
}

void guiTextTinted(const char* text, float red, float green, float blue) {
  ImGui::PushStyleColor(ImGuiCol_Text, ImVec4(red, green, blue, 1.0f));
  ImGui::TextUnformatted(text);
  ImGui::PopStyleColor();
}

// Draw section header at browser's own weight rather than Dear ImGui's default.
//   Default is saturated blue bar per section; five stacked read as loudest thing in
//   panel whose job is to sit over 3D scene.
//   Tones are browser's `--surface-raised` and `--border`, so header is legible as
//   header and no louder than that.
bool guiHeader(const char* label, bool is_open_first) {
  ImGui::PushStyleColor(ImGuiCol_Header, ImVec4(0.106f, 0.129f, 0.169f, 1.0f));
  ImGui::PushStyleColor(ImGuiCol_HeaderHovered, ImVec4(0.165f, 0.196f, 0.239f, 1.0f));
  ImGui::PushStyleColor(ImGuiCol_HeaderActive, ImVec4(0.204f, 0.243f, 0.298f, 1.0f));
  // Heading is title role, so it is set in title face -- here rather than at call sites,
  //   since every heading this panel has comes through this one door.
  //   `0.0f` keeps current size: face is chosen, scale is not.
  if (font_title != nullptr) ImGui::PushFont(font_title, 0.0f);
  const bool is_open = ImGui::CollapsingHeader(
      label, is_open_first ? ImGuiTreeNodeFlags_DefaultOpen : 0);
  if (font_title != nullptr) ImGui::PopFont();
  ImGui::PopStyleColor(3);
  return is_open;
}

// Set text between these two in mono face, for notation and for figures whose columns line up.
//   Pair rather than one entry point per widget: callers already draw such text through
//   `guiText`, `guiTextWrapped` and `guiTextTinted`, and wrapping each would be three more
//   doors for one decision.
//   No-op where mono face was not loaded, so absent face degrades to UI face.
void guiMonoPush() {
  if (font_mono != nullptr) ImGui::PushFont(font_mono, 0.0f);
}

void guiMonoPop() {
  if (font_mono != nullptr) ImGui::PopFont();
}

bool guiButton(const char* label) { return ImGui::Button(label); }

bool guiButtonSmall(const char* label) { return ImGui::SmallButton(label); }

// Draw one segment of segmented control: button that shows whether it is option in force.
//   Both choices stay visible and switching costs one click rather than opening list.
//   Both states are styled explicitly, from browser's own `.toggles button` rules.
//     Segment not in force must be recessive, and Dear ImGui's default button is
//     prominent blue that would otherwise make it read as selected one.
bool guiButtonToggle(const char* label, bool is_on, float width) {
  if (is_on) {
    ImGui::PushStyleColor(ImGuiCol_Button, ImVec4(0.0f, 0.655f, 0.647f, 0.22f));
    ImGui::PushStyleColor(ImGuiCol_ButtonHovered, ImVec4(0.0f, 0.655f, 0.647f, 0.34f));
    ImGui::PushStyleColor(ImGuiCol_ButtonActive, ImVec4(0.0f, 0.655f, 0.647f, 0.48f));
    ImGui::PushStyleColor(ImGuiCol_Text, ImVec4(0.741f, 0.953f, 0.941f, 1.0f));
    ImGui::PushStyleColor(ImGuiCol_Border, ImVec4(0.0f, 0.655f, 0.647f, 1.0f));
  } else {
    // Fill and border rather than leave transparent, unlike browser's own segment.
    //   There pill's track is what makes unselected segment visible, and panel drawn
    //   straight onto scene has no track to sit on.
    //   Tones are browser's `--surface` and `--border` so two controls still read as same
    //   thing.
    ImGui::PushStyleColor(ImGuiCol_Button, ImVec4(0.086f, 0.106f, 0.133f, 0.82f));
    ImGui::PushStyleColor(ImGuiCol_ButtonHovered, ImVec4(1.0f, 1.0f, 1.0f, 0.06f));
    ImGui::PushStyleColor(ImGuiCol_ButtonActive, ImVec4(1.0f, 1.0f, 1.0f, 0.12f));
    ImGui::PushStyleColor(ImGuiCol_Text, ImVec4(0.545f, 0.588f, 0.639f, 1.0f));
    ImGui::PushStyleColor(ImGuiCol_Border, ImVec4(0.165f, 0.196f, 0.239f, 1.0f));
  }
  ImGui::PushStyleVar(ImGuiStyleVar_FrameBorderSize, 1.0f);
  const bool pressed = ImGui::Button(label, ImVec2(width, 0.0f));
  ImGui::PopStyleVar();
  ImGui::PopStyleColor(5);
  return pressed;
}

// Draw button filling width caller names, for one that leads its own section.
//   Way browser's `.btn.primary` does; Dear ImGui's plain button is only as wide as its
//   own label.
bool guiButtonWide(const char* label, float width) {
  return ImGui::Button(label, ImVec2(width, 0.0f));
}

bool guiCheckbox(const char* label, bool* value) { return ImGui::Checkbox(label, value); }

bool guiDragFloat(const char* label, float* value, float speed, float lowest,
                  float highest) {
  // Show four significant digits, not four decimal places.
  //   Coefficient of 3.5 should read "3.5", not "3.5000", and one of 1664 should not
  //   lose its integer part to padding.
  return ImGui::DragFloat(label, value, speed, lowest, highest, "%.4g");
}

bool guiDragFloat3(const char* label, float* values, float speed) {
  return ImGui::DragFloat3(label, values, speed, 0.0f, 0.0f, "%.4g");
}

bool guiInputText(const char* label, char* buffer, int capacity) {
  return ImGui::InputText(label, buffer, (size_t)capacity);
}

bool guiCombo(const char* label, int* index, const char* const items[], int count) {
  return ImGui::Combo(label, index, items, count);
}

bool guiColorEdit3(const char* label, float* values) {
  return ImGui::ColorEdit3(label, values, ImGuiColorEditFlags_NoInputs);
}

void guiSeparator() { ImGui::Separator(); }

// Begin one row of tabs, and one tab in it.
//   Split into four calls because Nim cannot import C++ scope guard, so caller pairs
//   begin with end exactly as it does for window.
//   `BeginTabItem` takes no open flag: every tab here is permanent, and closable tab
//   draws X caller has nothing to do about.
bool guiTabBarBegin(const char *name) { return ImGui::BeginTabBar(name); }

void guiTabBarEnd() { ImGui::EndTabBar(); }

// Begin one tab; `is_forced` opens it whatever reader last left open.
//   How headless run reaches tab it cannot click; see
//   `visualiser.Options.index_help_driven`.
//   Passed every frame while it is set, so nothing else can take selection back.
bool guiTabBegin(const char *label, bool is_forced) {
  return ImGui::BeginTabItem(label, nullptr,
                             is_forced ? ImGuiTabItemFlags_SetSelected : 0);
}

void guiTabEnd() { ImGui::EndTabItem(); }

// Report how tall bordered child region holding `count` lines of plain text has to be.
//   Caller sizing one then need not restate Dear ImGui's own line spacing, window padding
//   and border width, three numbers it would guess at and re-guess whenever loaded font
//   changes.
//   `count` lines stack as count*line - one spacing, since spacing sits between lines
//   rather than after each.
float guiChildHeightForRows(int count) {
  const ImGuiStyle &style = ImGui::GetStyle();
  return count * ImGui::GetTextLineHeightWithSpacing() - style.ItemSpacing.y +
         2.0f * (style.WindowPadding.y + style.ChildBorderSize);
}

void guiSeparatorText(const char* label) { ImGui::SeparatorText(label); }

void guiSameLine() { ImGui::SameLine(); }

// Continue current line at fixed distance from its start.
//   Column of controls then lines up under one another regardless of how long each one's
//   own name is.
//   Dear ImGui draws widget's label to its right; this is what lets caller put it on left.
void guiSameLineAt(float offset) { ImGui::SameLine(offset); }

// Treat everything between two as one item.
//   Name stacked over its own control then still advances `guiSameLine` by width of pair.
//   Dear ImGui lays widgets out one per line unless told otherwise, and has no notion of
//   labelled cell.
void guiGroupBegin() { ImGui::BeginGroup(); }

void guiGroupEnd() { ImGui::EndGroup(); }

// Measure text as it will be drawn.
//   Caller laying out column can size it from what actually goes in column rather than
//   from number tuned by eye against today's longest entry.
float guiTextWidth(const char *text) { return ImGui::CalcTextSize(text).x; }

// Report width `guiButtonSmall` would draw this label at.
//   For caller lining run of them up against right edge rather than letting whatever
//   precedes them decide where they sit.
float guiButtonSmallWidth(const char* label) {
  return ImGui::CalcTextSize(label).x + ImGui::GetStyle().FramePadding.x * 2.0f;
}

// Continue current line with `width` of it reserved against right edge.
//   Run of controls then ends flush there whatever sits to its left.
void guiAlignRight(float width) {
  ImGui::SameLine(0.0f, 0.0f);
  ImGui::SetCursorPosX(ImGui::GetCursorPosX() + ImGui::GetContentRegionAvail().x - width);
}

void guiIdPush(int id) { ImGui::PushID(id); }

void guiIdPop() { ImGui::PopID(); }

// Report width still free on current line.
//   Caller laying widgets out with `sameLine` can decide for itself where to wrap; Dear
//   ImGui runs them off edge otherwise.
float guiContentWidth() { return ImGui::GetContentRegionAvail().x; }

// Room left down page, for region that has to end before what follows it.
//   Sibling of width above: list bounded by this scrolls inside window rather than
//   making window scroll, which is what keeps its header on screen.
float guiContentHeight() { return ImGui::GetContentRegionAvail().y; }

void guiWidthPush(float width) { ImGui::PushItemWidth(width); }

void guiWidthPop() { ImGui::PopItemWidth(); }

void guiDisabledPush(bool is_disabled) { ImGui::BeginDisabled(is_disabled); }

void guiDisabledPop() { ImGui::EndDisabled(); }

// Draw row with its own selected-state highlight, for list where one entry is current.
//   Sized explicitly so following widgets share line rather than being pushed below by
//   selectable's own default full-remaining-width.
bool guiSelectable(const char* label, bool is_selected, float width) {
  return ImGui::Selectable(label, is_selected, 0, ImVec2(width, 0.0f));
}

// Dim everything drawn until matching pop, for content present but out of focus.
//   Multiplies rather than replaces, so nesting inside disabled block keeps that block's
//   own dimming too.
//   Unlike `guiDisabledPush` this leaves widgets live: hidden object's own row must stay
//   clickable in order to unhide it.
void guiAlphaPush(float alpha) {
  ImGui::PushStyleVar(ImGuiStyleVar_Alpha, ImGui::GetStyle().Alpha * alpha);
}

void guiAlphaPop() { ImGui::PopStyleVar(); }

// Tint every widget's text until matching pop, for run sharing one item's colour.
//   `guiTextTinted` covers single-label case; this covers whole row.
void guiTextColorPush(float red, float green, float blue) {
  ImGui::PushStyleColor(ImGuiCol_Text, ImVec4(red, green, blue, 1.0f));
}

void guiTextColorPop() { ImGui::PopStyleColor(); }

// Attach tooltip to whatever widget was laid out immediately before this call.
//   Control gains on-hover explanation without separate marker glyph competing for space.
void guiTooltip(const char* text) {
  if (ImGui::IsItemHovered(ImGuiHoveredFlags_DelayNormal)) ImGui::SetTooltip("%s", text);
}

// Draw standalone "(?)" for concept with no single widget to hang explanation off.
//   Wrapped to readable width rather than one unbroken line.
void guiHelpMarker(const char* text) {
  ImGui::TextDisabled("(?)");
  if (ImGui::IsItemHovered(ImGuiHoveredFlags_DelayNormal)) {
    ImGui::BeginTooltip();
    ImGui::PushTextWrapPos(ImGui::GetFontSize() * 25.0f);
    ImGui::TextUnformatted(text);
    ImGui::PopTextWrapPos();
    ImGui::EndTooltip();
  }
}

// Fill fraction in one colour, remainder in another.
//   Caller can mean "active" and "free" rather than accept theme's own default
//   progress-bar colours.
void guiProgressBar(float fraction, const char* overlay, float width, float height,
                     float r_fill, float g_fill, float b_fill,
                     float r_track, float g_track, float b_track) {
  ImGui::PushStyleColor(ImGuiCol_PlotHistogram, ImVec4(r_fill, g_fill, b_fill, 1.0f));
  ImGui::PushStyleColor(ImGuiCol_FrameBg, ImVec4(r_track, g_track, b_track, 1.0f));
  ImGui::ProgressBar(fraction, ImVec2(width, height), overlay);
  ImGui::PopStyleColor(2);
}

// Draw live line graph over `count` samples, read starting `offset` frames back.
//   Caller's own ring buffer needs no shifting to stay in chronological order on screen.
void guiPlotLines(const char* label, const float* values, int count, int offset,
                   const char* overlay, float scale_min, float scale_max,
                   float width, float height) {
  ImGui::PlotLines(label, values, count, offset, overlay, scale_min, scale_max,
                    ImVec2(width, height));
}

// Draw one small filled cell per pool handle, wrapped to panel's own width.
//   `colours` holds three floats per cell, red then green then blue.
//   Caller alone decides what handle's colour means, so nothing here has to know which
//   handles are occupied or which palette live one is drawn in.
void guiPoolBar(const float* colours, int count, float cell_size) {
  const float spacing = 2.0f;
  const float avail = ImGui::GetContentRegionAvail().x;
  const int fitted = (int)((avail + spacing) / (cell_size + spacing));
  const int per_row = avail > cell_size ? (fitted < 1 ? 1 : fitted) : count;
  const int rows = (count + per_row - 1) / per_row;

  ImDrawList* draw_list = ImGui::GetWindowDrawList();
  const ImVec2 origin = ImGui::GetCursorScreenPos();
  for (int i = 0; i < count; ++i) {
    const int row = i / per_row;
    const int column = i % per_row;
    const ImVec2 top_left(origin.x + column * (cell_size + spacing),
                           origin.y + row * (cell_size + spacing));
    const ImVec2 bottom_right(top_left.x + cell_size, top_left.y + cell_size);
    const ImU32 colour = ImGui::ColorConvertFloat4ToU32(
        ImVec4(colours[i * 3], colours[i * 3 + 1], colours[i * 3 + 2], 1.0f));
    draw_list->AddRectFilled(top_left, bottom_right, colour, 2.0f);
  }
  ImGui::Dummy(ImVec2(avail, rows * (cell_size + spacing)));
}

// Choose which layer overlay draw lands on.
//   Two, and difference matters: Dear ImGui draws background list beneath every window
//   and foreground list above them all, and both sit above 3D scene, which OpenGL has
//   already rasterised by time any of this runs.
//   Mark on object goes beneath windows.
//     It annotates scene geometry that panel itself occludes, so drawing it above panel
//     puts selection ring over panel that is covering very object it rings.
//   Only drag menu draws above: it is control being steered, not mark on anything, and
//   wedge reader is reaching for should not slide under chrome.
static ImDrawList *overlayList(bool is_over_windows) {
  return is_over_windows ? ImGui::GetForegroundDrawList()
                         : ImGui::GetBackgroundDrawList();
}

// Draw line onto overlay layer, for feedback that belongs to 3D view rather than panel.
//   Rubber-band line while dragging, ring around whatever cursor is over.
//   Screen space only; caller does projection.
void guiOverlayLine(float x1, float y1, float x2, float y2, float red, float green,
                     float blue, float alpha, float thickness) {
  overlayList(false)->AddLine(
      ImVec2(x1, y1), ImVec2(x2, y2),
      ImGui::ColorConvertFloat4ToU32(ImVec4(red, green, blue, alpha)), thickness);
}

// Stroke whole circle onto layer `is_over_windows` picks.
//   Serves both layers: marker's full ring (through `guiOverlayArc` below, beneath panels
//   with every other mark) and drag menu's own centre dot (above them, with rest of that
//   menu).
//   Only overlay call with foot in both, so choice is parameter here and settled by what
//   each of others draws everywhere else.
void guiOverlayCircle(float cx, float cy, float radius, float red, float green, float blue,
                       float alpha, float thickness, int is_over_windows) {
  overlayList(is_over_windows != 0)->AddCircle(
      ImVec2(cx, cy), radius,
      ImGui::ColorConvertFloat4ToU32(ImVec4(red, green, blue, alpha)), 0, thickness);
}

// Draw part of circle, clockwise from twelve o'clock.
//   For press filling its own marker as it matures into selection.
//   `fraction` is how much of turn to stroke, in 0 .. 1.
//   Whole turn is handed to AddCircle above rather than traced here, so marker that is
//   not animating lands on exactly same pixels as plain ring.
//   Clockwise in screen terms, which is why angle subtracts: y runs downward here, so
//   sense that reads as clockwise to viewer is one that decreases angle.
void guiOverlayArc(float cx, float cy, float radius, float fraction, float red, float green,
                   float blue, float alpha, float thickness) {
  if (fraction <= 0.0f) return;
  if (fraction >= 1.0f) {
    guiOverlayCircle(cx, cy, radius, red, green, blue, alpha, thickness, 0);
    return;
  }
  const float TURN = 6.28318530717958647692f;
  const float START = -TURN * 0.25f; // Twelve o'clock, with y downward.
  ImDrawList *list = overlayList(false);
  list->PathArcTo(ImVec2(cx, cy), radius, START, START - TURN * fraction, 0);
  list->PathStroke(ImGui::ColorConvertFloat4ToU32(ImVec4(red, green, blue, alpha)),
                   ImDrawFlags_None, thickness);
}

// Draw marker's own polyline as one path rather than run of separate line calls.
//   Dear ImGui then joins its corners instead of leaving nick at each one, visible on
//   thin overlay stroke, and whole reason plane's marker is path at all.
//   `points` addresses `count` pairs of floats, x then y.
void guiOverlayPolyline(const float *points, int count, float red, float green, float blue,
                        float alpha, float thickness, int is_closed) {
  if (count < 2) return;
  ImDrawList *list = overlayList(false);
  for (int i = 0; i < count; ++i) {
    list->PathLineTo(ImVec2(points[2 * i], points[2 * i + 1]));
  }
  list->PathStroke(ImGui::ColorConvertFloat4ToU32(ImVec4(red, green, blue, alpha)),
                   is_closed ? ImDrawFlags_Closed : ImDrawFlags_None, thickness);
}

// Fill marker's own closed outline, for shape whose width varies along its length.
//   Cannot be stroke: orientation pulse tapering down its tail, and drag band's head.
//   `points` addresses `count` pairs of floats, x then y, already closed.
//     Caller shapes ribbon (`marker.ribbonAlong`), this only fills it.
//   Concave rather than convex: ribbon following curved outline bends away from
//   straight, and convex fill would bridge that bend with chord across marker.
//   Wound to fixed handedness here rather than by caller, because it is Dear ImGui that
//   cares and no one else.
//     Its antialiased fill offsets each edge by normal `(dy, -dx)`, which points out of
//     shape for one winding and into it for other.
//     Handed ribbon wound wrong way it pushes whole transparent fringe inward, under
//     fill, and mark comes out with hard aliased edges; figures in `PROVENANCE.md`.
//     Pulse's own winding flips with orientation it reports, so this cannot be settled
//     once at call site.
void guiOverlayRibbon(const float *points, int count, float red, float green, float blue,
                      float alpha) {
  if (count < 3) return;
  float twice_area = 0.0f;
  for (int i = 0, j = count - 1; i < count; j = i++) {
    twice_area += points[2 * j] * points[2 * i + 1] - points[2 * i] * points[2 * j + 1];
  }
  ImDrawList *list = overlayList(false);
  for (int n = 0; n < count; ++n) {
    const int i = twice_area >= 0.0f ? n : count - 1 - n;
    list->PathLineTo(ImVec2(points[2 * i], points[2 * i + 1]));
  }
  list->PathFillConcave(ImGui::ColorConvertFloat4ToU32(ImVec4(red, green, blue, alpha)));
}

// Fill rounded rectangle centred on `cx`/`cy` onto layer above every window.
//   For one wedge of drag menu; see `overlayList` for why menu alone draws there.
//   Centred rather than placed from corner because every caller of it knows where
//   wedge's middle goes and nothing else about its size, which comes from label it has
//   to hold.
void guiOverlayChip(float cx, float cy, float width, float height, float red, float green,
                    float blue, float alpha, float rounding) {
  overlayList(true)->AddRectFilled(
      ImVec2(cx - 0.5f * width, cy - 0.5f * height),
      ImVec2(cx + 0.5f * width, cy + 0.5f * height),
      ImGui::ColorConvertFloat4ToU32(ImVec4(red, green, blue, alpha)), rounding);
}

// Write text centred on `cx`/`cy` onto drag menu's own layer, above every window.
//   In font already loaded.
//   Centred here rather than by caller so measurement and placement use same font
//   metrics; caller offsetting by its own guess drifts as soon as face loaded is not one
//   it guessed against.
void guiOverlayText(float cx, float cy, float red, float green, float blue, float alpha,
                    const char *text) {
  const ImVec2 size = ImGui::CalcTextSize(text);
  overlayList(true)->AddText(
      ImVec2(cx - 0.5f * size.x, cy - 0.5f * size.y),
      ImGui::ColorConvertFloat4ToU32(ImVec4(red, green, blue, alpha)), text);
}

// Write text centred on `cx`/`cy` in fill colour, outlined in stroke colour.
//   Outline is text drawn again at eight one-pixel offsets beneath fill: draw list has
//   no stroked text, and eight copies read as round outline at this size.
//   Background list rather than menu's own, as markers are: beneath panels, over scene.
// Measure name label as `guiOverlayLabel` will draw it, in its own face and size.
float guiLabelWidth(const char *text) {
  ImFont *font = font_label != nullptr ? font_label : ImGui::GetFont();
  const float size = size_font_label > 0.0f ? size_font_label : ImGui::GetFontSize();
  return font->CalcTextSizeA(size, FLT_MAX, 0.0f, text).x;
}

void guiOverlayLabel(float cx, float cy, float fill_red, float fill_green, float fill_blue,
                     float stroke_red, float stroke_green, float stroke_blue, float alpha,
                     const char *text) {
  // Set in label face at its own size; UI face where label face was not loaded.
  ImFont *font = font_label != nullptr ? font_label : ImGui::GetFont();
  const float size = size_font_label > 0.0f ? size_font_label : ImGui::GetFontSize();
  const ImVec2 extent = font->CalcTextSizeA(size, FLT_MAX, 0.0f, text);
  const ImVec2 at(cx - 0.5f * extent.x, cy - 0.5f * extent.y);
  ImDrawList *list = overlayList(false);
  const ImU32 stroke =
      ImGui::ColorConvertFloat4ToU32(ImVec4(stroke_red, stroke_green, stroke_blue, alpha));
  for (int dx = -1; dx <= 1; dx += 1) {
    for (int dy = -1; dy <= 1; dy += 1) {
      if (dx == 0 && dy == 0) continue;
      list->AddText(font, size, ImVec2(at.x + (float)dx, at.y + (float)dy), stroke, text);
    }
  }
  list->AddText(
      font, size, at,
      ImGui::ColorConvertFloat4ToU32(ImVec4(fill_red, fill_green, fill_blue, 1.0f)), text);
}

} // extern "C"
