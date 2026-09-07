## Bind subset of SDL3 visualiser uses.
##
## SDL3 is depended on rather than derived.
##   Windowing and input are external concerns this project exists to look past.
##   Only symbols called are declared, so binding stays readable in one sitting.
##   Declarations import through header, so C compiler owns every struct layout.
##     Cost is that SDL3 development headers must be present to compile.
## Event kinds and flags are mirrored as Nim constants so `case` can bind them.
##   Every value is checked against header's own by generated static assertion, so stale
##   binding fails to compile rather than to work.
##
## Desktop-only; unreachable from browser build. See PROVENANCE.md's "Render Paths".

{.experimental: "strictFuncs".}



#[ Binding Configuration ]#

const HEADER = "<SDL3/SDL.h>"
  ## Name header every declaration below imports through.

# Link SDL3 here rather than in project config.
#   Every binary importing this module then links it without extra flags.
{.passL: "-lSDL3".}



#[ Type Definitions ]#

type
  Window* = pointer ## Refer to opaque `SDL_Window`.
  GlContext* = pointer ## Refer to opaque `SDL_GLContext`.

  EventKind* {.pure.} = enum ## Define event kinds visualiser reacts to.
    Quit = 0x100,
    WindowResized = 0x206,
    WindowFocusLost = 0x20f,
      ## Let held keys go on this; see `interaction.releaseKeysAll`.
      ##   Their releases go to whichever window took focus, and key left held would move
      ##   camera forever.
    KeyDown = 0x300,
    KeyUp = 0x301,
    MouseMotion = 0x400,
    MouseButtonDown = 0x401,
    MouseButtonUp = 0x402,
    MouseWheel = 0x403,

  Scancode* {.pure.} = enum ## Define physical keys visualiser reacts to.
    ## USB HID usage IDs, which is what SDL scancode is.
    ##   Every one is checked against header's macro at compile time by `CHECKS_MIRROR`.
    A = 4,
    D = 7,
    E = 8,
    F = 9,
    Q = 20,
    S = 22,
    W = 26,
    Y = 28,
    Z = 29,
    Return = 40,
    Escape = 41,
    Tab = 43,
      ## Keep unbound by this application.
      ##   Dear ImGui's keyboard navigation owns it, and rebinding it inside view would
      ##   risk keyboard trap WCAG 2.1.2 rules out.
      ##   Declared so `--drive-keys` can synthesise one and prove nav has it.
    Minus = 45,
    Equals = 46,
    BracketLeft = 47,
    BracketRight = 48,
    Home = 74,
    Right = 79,
    Left = 80,
    Down = 81,
    Up = 82,
    ShiftLeft = 225,
    ShiftRight = 229,
      ## Bind both shift keys to same thing.
      ##   Reader holds whichever their other hand is nearer.
      ##   Modifier bitmask cannot serve: what is wanted is shift's own press and release,
      ##   not its state at some other key's event.

  MouseButton* {.pure.} = enum ## Define mouse buttons visualiser reacts to.
    Left = 1,
    Middle = 2,
    Right = 3,

  KeyboardEvent* {.importc: "SDL_KeyboardEvent", header: HEADER, bycopy.} = object
    scancode* {.importc.}: uint32 ## Physical key, independent of layout.
    keycode* {.importc: "key".}: uint32 ## Key as layout names it.
      ## Never read by this application.
      ## Dear ImGui's SDL3 backend reads it, so synthesised event leaving it zero is one
      ## Dear ImGui does not recognise; `--drive-keys` must fill it to prove anything.
    is_down* {.importc: "down".}: bool ## Whether key is pressed rather than released.
    modifiers* {.importc: "mod".}: uint16 ## Modifier keys held as this one went down.

  MouseMotionEvent* {.importc: "SDL_MouseMotionEvent", header: HEADER, bycopy.} = object
    x* {.importc.}: cfloat ## Position in window, in pixels, from top-left.
    y* {.importc.}: cfloat ## Position in window, in pixels, from top-left.
    xrel* {.importc.}: cfloat ## Motion since previous event, in pixels.
    yrel* {.importc.}: cfloat ## Motion since previous event, in pixels.

  MouseButtonEvent* {.importc: "SDL_MouseButtonEvent", header: HEADER, bycopy.} = object
    button* {.importc.}: uint8 ## Which button changed state.

  MouseWheelEvent* {.importc: "SDL_MouseWheelEvent", header: HEADER, bycopy.} = object
    y* {.importc.}: cfloat ## Scroll amount, positive away from user.

  Event* {.importc: "SDL_Event", header: HEADER, union, bycopy.} = object
    kind* {.importc: "type".}: uint32 ## Discriminates union; compare against `EventKind`.
    key* {.importc.}: KeyboardEvent
    motion* {.importc.}: MouseMotionEvent
    button* {.importc.}: MouseButtonEvent
    wheel* {.importc.}: MouseWheelEvent


const
  MODIFIER_CONTROL* = 0x00C0'u16
    ## Test key event's modifiers for either control key.
  MODIFIER_SHIFT* = 0x0003'u16
    ## Test key event's modifiers for either shift key.
  MODIFIER_COMMAND* = 0x0C00'u16
    ## Test key event's modifiers for either command key.
    ##   What reader on macOS presses where everyone else presses control.
  INIT_VIDEO* = 0x20'u32
    ## Ask `init` for video and event subsystems.
  WINDOW_OPENGL* = 0x02'u64
    ## Ask `createWindow` for window OpenGL context can be bound to.
  WINDOW_RESIZABLE* = 0x20'u64
    ## Ask `createWindow` for window user may resize.
  WINDOW_HIDDEN* = 0x08'u64
    ## Ask `createWindow` for window never mapped, as headless render needs no view.
  GL_CONTEXT_MAJOR_VERSION* = 17'u32
  GL_CONTEXT_MINOR_VERSION* = 18'u32
  GL_CONTEXT_PROFILE_MASK* = 20'u32
  GL_DOUBLEBUFFER* = 5'u32
  GL_DEPTH_SIZE* = 6'u32
  GL_MULTISAMPLEBUFFERS* = 13'u32
    ## Ask `glSetAttribute` for multisampled framebuffer at all: 1 for yes, 0 for none.
  GL_MULTISAMPLESAMPLES* = 14'u32
    ## Ask for this many samples per pixel in it.
  GL_CONTEXT_PROFILE_CORE* = 0x0001'i32



#[ Foreign Declarations ]#

# Import SDL3 entry points one to one; see SDL3 documentation for each.
# Mark every binding `sideEffect`.
#   Compiler assumes imported body is pure, so `func` calling one would compile; marked,
#   only `proc` may reach effects, which is what makes `func` mean anything here.
proc init*(flags: uint32): bool {.importc: "SDL_Init", header: HEADER, discardable, sideEffect.}
  ## Start SDL subsystems named by `flags`, reporting success.

proc quit*() {.importc: "SDL_Quit", header: HEADER, sideEffect.}
  ## Shut every SDL subsystem down.

proc getError*(): cstring {.importc: "SDL_GetError", header: HEADER, sideEffect.}
  ## Read message of last SDL failure.

proc setHint*(name, value: cstring): bool
  {.importc: "SDL_SetHint", header: HEADER, discardable, sideEffect.}
  ## Set configuration hint `name` to `value`.

proc createWindow*(title: cstring; width, height: cint; flags: uint64): Window
  {.importc: "SDL_CreateWindow", header: HEADER, sideEffect.}
  ## Open window titled `title` at given size with `flags`.

proc destroyWindow*(window: Window) {.importc: "SDL_DestroyWindow", header: HEADER, sideEffect.}
  ## Close window.

proc getWindowSizeInPixels*(window: Window; width, height: ptr cint): bool
  {.importc: "SDL_GetWindowSizeInPixels", header: HEADER, discardable, sideEffect.}
  ## Read window's drawable size in pixels, which may exceed logical size.

proc glSetAttribute*(attribute: uint32, value: cint): bool
  {.importc: "SDL_GL_SetAttribute", header: HEADER, discardable, sideEffect.}
  ## Set OpenGL context attribute, before context is created.

proc glCreateContext*(window: Window): GlContext
  {.importc: "SDL_GL_CreateContext", header: HEADER, sideEffect.}
  ## Create OpenGL context for window and make it current.

proc glDestroyContext*(context: GlContext): bool
  {.importc: "SDL_GL_DestroyContext", header: HEADER, discardable, sideEffect.}
  ## Delete OpenGL context.

proc glSetSwapInterval*(interval: cint): bool
  {.importc: "SDL_GL_SetSwapInterval", header: HEADER, discardable, sideEffect.}
  ## Set vertical sync: 1 waits for display, 0 does not.

proc glSwapWindow*(window: Window): bool
  {.importc: "SDL_GL_SwapWindow", header: HEADER, discardable, sideEffect.}
  ## Present back buffer.

proc getModState*(): uint16 {.importc: "SDL_GetModState", header: HEADER, sideEffect.}
  ## Read which modifier keys are held right now, testable against `MODIFIER_` masks.
  ##   Mouse-button event carries no modifiers, so shift-clicking has to ask.

proc setModState*(modifiers: uint16) {.importc: "SDL_SetModState", header: HEADER, sideEffect.}
  ## Say which modifiers are held, for scripted gesture with no real keyboard behind it.
  ##   `SDL_PushEvent` only enqueues, never touching state `getModState` reads.
  ##   See desktop entry's `driveSelect`, only caller.

proc pollEvent*(event: ptr Event): bool {.importc: "SDL_PollEvent", header: HEADER, sideEffect.}
  ## Take next queued event into `event`, reporting whether there was one.

proc pushEvent*(event: ptr Event): bool
  {.importc: "SDL_PushEvent", header: HEADER, discardable, sideEffect.}
  ## Put event on same queue `pollEvent` drains; see desktop entry's `driveDrag`.
  ##   Scripted gesture then reaches application through identical path real one does.
  ##   Posting straight to handler would prove nothing about wiring between them, where
  ##   bugs have hidden.



#[ Binding Validation ]#

const lut_mirror_to_symbol = [
  (int(EventKind.Quit), "SDL_EVENT_QUIT"),
  (int(EventKind.WindowResized), "SDL_EVENT_WINDOW_RESIZED"),
  (int(EventKind.WindowFocusLost), "SDL_EVENT_WINDOW_FOCUS_LOST"),
  (int(EventKind.KeyDown), "SDL_EVENT_KEY_DOWN"),
  (int(EventKind.KeyUp), "SDL_EVENT_KEY_UP"),
  (int(EventKind.MouseMotion), "SDL_EVENT_MOUSE_MOTION"),
  (int(EventKind.MouseButtonDown), "SDL_EVENT_MOUSE_BUTTON_DOWN"),
  (int(EventKind.MouseButtonUp), "SDL_EVENT_MOUSE_BUTTON_UP"),
  (int(EventKind.MouseWheel), "SDL_EVENT_MOUSE_WHEEL"),
  (int(Scancode.Escape), "SDL_SCANCODE_ESCAPE"),
  (int(Scancode.A), "SDL_SCANCODE_A"),
  (int(Scancode.D), "SDL_SCANCODE_D"),
  (int(Scancode.E), "SDL_SCANCODE_E"),
  (int(Scancode.F), "SDL_SCANCODE_F"),
  (int(Scancode.W), "SDL_SCANCODE_W"),
  (int(Scancode.ShiftLeft), "SDL_SCANCODE_LSHIFT"),
  (int(Scancode.ShiftRight), "SDL_SCANCODE_RSHIFT"),
  (int(Scancode.S), "SDL_SCANCODE_S"),
  (int(Scancode.Y), "SDL_SCANCODE_Y"),
  (int(Scancode.Z), "SDL_SCANCODE_Z"),
  (int(Scancode.Q), "SDL_SCANCODE_Q"),
  (int(Scancode.Return), "SDL_SCANCODE_RETURN"),
  (int(Scancode.Tab), "SDL_SCANCODE_TAB"),
  (int(Scancode.Minus), "SDL_SCANCODE_MINUS"),
  (int(Scancode.Equals), "SDL_SCANCODE_EQUALS"),
  (int(Scancode.BracketLeft), "SDL_SCANCODE_LEFTBRACKET"),
  (int(Scancode.BracketRight), "SDL_SCANCODE_RIGHTBRACKET"),
  (int(Scancode.Home), "SDL_SCANCODE_HOME"),
  (int(Scancode.Right), "SDL_SCANCODE_RIGHT"),
  (int(Scancode.Left), "SDL_SCANCODE_LEFT"),
  (int(Scancode.Down), "SDL_SCANCODE_DOWN"),
  (int(Scancode.Up), "SDL_SCANCODE_UP"),
  (int(MODIFIER_CONTROL), "SDL_KMOD_CTRL"),
  (int(MODIFIER_SHIFT), "SDL_KMOD_SHIFT"),
  (int(MODIFIER_COMMAND), "SDL_KMOD_GUI"),
  (int(MouseButton.Left), "SDL_BUTTON_LEFT"),
  (int(MouseButton.Middle), "SDL_BUTTON_MIDDLE"),
  (int(MouseButton.Right), "SDL_BUTTON_RIGHT"),
  (int(INIT_VIDEO), "SDL_INIT_VIDEO"),
  (int(WINDOW_OPENGL), "SDL_WINDOW_OPENGL"),
  (int(WINDOW_RESIZABLE), "SDL_WINDOW_RESIZABLE"),
  (int(WINDOW_HIDDEN), "SDL_WINDOW_HIDDEN"),
  (int(GL_CONTEXT_MAJOR_VERSION), "SDL_GL_CONTEXT_MAJOR_VERSION"),
  (int(GL_CONTEXT_MINOR_VERSION), "SDL_GL_CONTEXT_MINOR_VERSION"),
  (int(GL_CONTEXT_PROFILE_MASK), "SDL_GL_CONTEXT_PROFILE_MASK"),
  (int(GL_DOUBLEBUFFER), "SDL_GL_DOUBLEBUFFER"),
  (int(GL_DEPTH_SIZE), "SDL_GL_DEPTH_SIZE"),
  (int(GL_MULTISAMPLEBUFFERS), "SDL_GL_MULTISAMPLEBUFFERS"),
  (int(GL_MULTISAMPLESAMPLES), "SDL_GL_MULTISAMPLESAMPLES"),
  (int(GL_CONTEXT_PROFILE_CORE), "SDL_GL_CONTEXT_PROFILE_CORE"),
] ## Pair every mirrored value with header's name for it.


const CHECKS_MIRROR = block:
  ## Generate one static assertion per mirrored value, from table above.
  ##   Both sides of each check are read from one table, so mirror cannot drift from
  ##   assertion guarding it.
  ##   Assertions are C++ because only C++ compiler sees header's values; they cost
  ##   nothing at run time.
  var text = "#include " & HEADER & "\n"
  for (mirrored, symbol) in lut_mirror_to_symbol:
    text &= "static_assert((long long)(" & symbol & ") == " & $mirrored &
      ", \"SDL3 binding is stale: " & symbol & " was renumbered.\");\n"
  text

{.emit: CHECKS_MIRROR.}
