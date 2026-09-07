## Bind subset of OpenGL 3.3 core visualiser uses.
##
## Driver is depended on rather than derived, as windowing is: external.
##   Only entry points called are declared.
##   Declarations import through header, so C compiler resolves every prototype and enum.
## Prototypes come from `GL_GLEXT_PROTOTYPES`, which links entry points directly.
##   Holds on Linux, where libGL exports every core symbol.
##   TODO: Fetch entry points through `SDL_GL_GetProcAddress` elsewhere.
##     Would turn each declaration into loaded function pointer.
##     Deferred until visualiser needs to leave Linux.
## Enumerants are written as literals rather than imported.
##   Values are fixed by OpenGL specification and never renumbered.
##
## Desktop-only; unreachable from browser build. See PROVENANCE.md's "Render Paths".

{.experimental: "strictFuncs".}



#[ Binding Configuration ]#

const HEADER = "<GL/gl.h>"
  ## Name header every declaration below imports through.

# Ask header for prototypes above OpenGL 1.1, and link loader.
#   Here rather than in project config, so every binary importing this module builds
#   without extra flags.
{.passC: "-DGL_GLEXT_PROTOTYPES".}
{.passL: "-lGL".}



#[ Type Definitions ]#

type
  Bitfield* = uint32 ## Mirror `GLbitfield`.
  Boolean* = uint8 ## Mirror `GLboolean`.
  Char* = char ## Mirror `GLchar`.
  Enum* = uint32 ## Mirror `GLenum`.
  Float* = float32 ## Mirror `GLfloat`.
  Int* = int32 ## Mirror `GLint`.
  Sizei* = int32 ## Mirror `GLsizei`.
  Sizeiptr* = int ## Mirror `GLsizeiptr`.
  Uint* = uint32 ## Mirror `GLuint`.


const
  COLOR_BUFFER_BIT* = 0x00004000'u32
  DEPTH_BUFFER_BIT* = 0x00000100'u32
  DEPTH_TEST* = 0x0B71'u32
  BLEND* = 0x0BE2'u32
  MULTISAMPLE* = 0x809D'u32
  PROGRAM_POINT_SIZE* = 0x8642'u32
  SRC_ALPHA* = 0x0302'u32
  ONE_MINUS_SRC_ALPHA* = 0x0303'u32
  LESS* = 0x0201'u32
  ARRAY_BUFFER* = 0x8892'u32
  DYNAMIC_DRAW* = 0x88E8'u32
  STATIC_DRAW* = 0x88E4'u32
  FLOAT_TYPE* = 0x1406'u32
  UNSIGNED_BYTE* = 0x1401'u32
  RGB* = 0x1907'u32
  PACK_ALIGNMENT* = 0x0D05'u32
  TRIANGLES* = 0x0004'u32
  TRIANGLE_STRIP* = 0x0005'u32
  LINES* = 0x0001'u32
  POINTS* = 0x0000'u32
  VERTEX_SHADER* = 0x8B31'u32
  FRAGMENT_SHADER* = 0x8B30'u32
  COMPILE_STATUS* = 0x8B81'u32
  LINK_STATUS* = 0x8B82'u32
  VERSION* = 0x1F02'u32
  FALSE* = 0'u8
  TRUE* = 1'u8



#[ Foreign Declarations ]#

# Import OpenGL entry points one to one; see OpenGL reference for each.
# Mark every binding `sideEffect`.
#   Compiler assumes imported body is pure, so `func` calling one would compile; marked,
#   only `proc` may reach effects, which is what makes `func` mean anything here.
proc clearColor*(red, green, blue, alpha: Float)
  {.importc: "glClearColor", header: HEADER, sideEffect.}
  ## Set colour `clear` fills colour buffer with.

proc clear*(mask: Bitfield) {.importc: "glClear", header: HEADER, sideEffect.}
  ## Clear buffers named by `mask` to their set values.

proc viewport*(x, y: Int; width, height: Sizei)
  {.importc: "glViewport", header: HEADER, sideEffect.}
  ## Map clip space onto window rectangle at `x`, `y` of given size.

proc enable*(capability: Enum) {.importc: "glEnable", header: HEADER, sideEffect.}
  ## Turn capability on.

proc disable*(capability: Enum) {.importc: "glDisable", header: HEADER, sideEffect.}
  ## Turn capability off.

proc blendFunc*(source, destination: Enum) {.importc: "glBlendFunc", header: HEADER, sideEffect.}
  ## Set how fragment colour blends with what is already drawn.

proc depthFunc*(function: Enum) {.importc: "glDepthFunc", header: HEADER, sideEffect.}
  ## Set comparison depth test passes on.

proc depthMask*(flag: Boolean) {.importc: "glDepthMask", header: HEADER, sideEffect.}
  ## Say whether depth writes land.

proc lineWidth*(width: Float) {.importc: "glLineWidth", header: HEADER, sideEffect.}
  ## Set width `LINES` rasterise at, hint most targets clamp to one pixel.

proc getString*(name: Enum): cstring {.importc: "glGetString", header: HEADER, sideEffect.}
  ## Read driver string named by `name`, e.g. `VERSION`.

proc pixelStorei*(name: Enum, parameter: Int)
  {.importc: "glPixelStorei", header: HEADER, sideEffect.}
  ## Set pixel transfer parameter, e.g. pack alignment for readback.

proc readPixels*(
  x, y: Int; width, height: Sizei; format, kind: Enum; pixels: pointer
) {.importc: "glReadPixels", header: HEADER, sideEffect.}
  ## Read framebuffer rectangle into `pixels`.

proc genVertexArrays*(count: Sizei, arrays: ptr Uint)
  {.importc: "glGenVertexArrays", header: HEADER, sideEffect.}
  ## Create `count` vertex array objects into `arrays`.

proc bindVertexArray*(array_object: Uint)
  {.importc: "glBindVertexArray", header: HEADER, sideEffect.}
  ## Make vertex array current, or none at zero.

proc genBuffers*(count: Sizei, buffers: ptr Uint)
  {.importc: "glGenBuffers", header: HEADER, sideEffect.}
  ## Create `count` buffer objects into `buffers`.

proc bindBuffer*(target: Enum, buffer: Uint) {.importc: "glBindBuffer", header: HEADER, sideEffect.}
  ## Make buffer current on `target`.

proc bufferData*(target: Enum, size: Sizeiptr, data: pointer, usage: Enum)
  {.importc: "glBufferData", header: HEADER, sideEffect.}
  ## Upload `size` bytes from `data` into current buffer, with usage hint.

proc vertexAttribPointer*(
  index: Uint, size: Int, kind: Enum, normalized: Boolean, stride: Sizei, offset: pointer
) {.importc: "glVertexAttribPointer", header: HEADER, sideEffect.}
  ## Point attribute at its components within current buffer.

proc enableVertexAttribArray*(index: Uint)
  {.importc: "glEnableVertexAttribArray", header: HEADER, sideEffect.}
  ## Turn attribute `index` on for current vertex array.

proc vertexAttribDivisor*(index: Uint, divisor: Uint)
  {.importc: "glVertexAttribDivisor", header: HEADER, sideEffect.}
  ## Advance attribute `index` once per `divisor` instances, not per vertex.

proc drawArraysInstanced*(mode: Enum, first: Int, count: Sizei, instances: Sizei)
  {.importc: "glDrawArraysInstanced", header: HEADER, sideEffect.}
  ## Draw `count` vertices from `first`, `instances` times over.

proc drawArrays*(mode: Enum, first: Int, count: Sizei)
  {.importc: "glDrawArrays", header: HEADER, sideEffect.}
  ## Draw `count` vertices from `first`.

proc createShader*(kind: Enum): Uint {.importc: "glCreateShader", header: HEADER, sideEffect.}
  ## Create empty shader stage of `kind`.

proc shaderSource*(shader: Uint, count: Sizei, sources: ptr cstring, lengths: ptr Int)
  {.importc: "glShaderSource", header: HEADER, sideEffect.}
  ## Set shader's source strings.

proc compileShader*(shader: Uint) {.importc: "glCompileShader", header: HEADER, sideEffect.}
  ## Compile shader from its source.

proc getShaderiv*(shader: Uint, name: Enum, parameters: ptr Int)
  {.importc: "glGetShaderiv", header: HEADER, sideEffect.}
  ## Read shader parameter `name` into `parameters`.

proc getShaderInfoLog*(shader: Uint, capacity: Sizei, length: ptr Sizei, log: ptr Char)
  {.importc: "glGetShaderInfoLog", header: HEADER, sideEffect.}
  ## Read shader's compile log into `log`, up to `capacity` bytes.

proc deleteShader*(shader: Uint) {.importc: "glDeleteShader", header: HEADER, sideEffect.}
  ## Delete shader stage.

proc createProgram*(): Uint {.importc: "glCreateProgram", header: HEADER, sideEffect.}
  ## Create empty program.

proc attachShader*(program, shader: Uint) {.importc: "glAttachShader", header: HEADER, sideEffect.}
  ## Attach compiled stage to program.

proc linkProgram*(program: Uint) {.importc: "glLinkProgram", header: HEADER, sideEffect.}
  ## Link program's attached stages.

proc getProgramiv*(program: Uint, name: Enum, parameters: ptr Int)
  {.importc: "glGetProgramiv", header: HEADER, sideEffect.}
  ## Read program parameter `name` into `parameters`.

proc getProgramInfoLog*(program: Uint, capacity: Sizei, length: ptr Sizei, log: ptr Char)
  {.importc: "glGetProgramInfoLog", header: HEADER, sideEffect.}
  ## Read program's link log into `log`, up to `capacity` bytes.

proc useProgram*(program: Uint) {.importc: "glUseProgram", header: HEADER, sideEffect.}
  ## Make program current for drawing.

proc getUniformLocation*(program: Uint, name: cstring): Int
  {.importc: "glGetUniformLocation", header: HEADER, sideEffect.}
  ## Find uniform `name` in program; GL answers -1 where absent.

proc uniformMatrix4fv*(location: Int, count: Sizei, transpose: Boolean, value: ptr Float)
  {.importc: "glUniformMatrix4fv", header: HEADER, sideEffect.}
  ## Set matrix uniform from `count` matrices at `value`.

proc uniform1f*(location: Int, value: Float) {.importc: "glUniform1f", header: HEADER, sideEffect.}
  ## Set float uniform.

proc uniform1i*(location: Int, value: Int) {.importc: "glUniform1i", header: HEADER, sideEffect.}
  ## Set int uniform.

proc uniform3f*(location: Int; x, y, z: Float)
  {.importc: "glUniform3f", header: HEADER, sideEffect.}
  ## Set three-float uniform.
