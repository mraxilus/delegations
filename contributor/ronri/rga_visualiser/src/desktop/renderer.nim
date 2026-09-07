## Own OpenGL resources, and draw meshes through them.
##
## One program per record kind, and plain one for points.
##   Each record type in `mesh` has vertex shader here that widens it over static corner
##   geometry (see each `SOURCE_VERTEX_*` and reference proc it names).
##   CPU hands over compact records and no per-frame expansion.
## Buffers are reuploaded whole each frame rather than tracked for changes.
##   Upload is far below any frame's own reach, and nothing can be stale after user edits
##   coefficient.
## Draw order is opaque first, translucent second, with depth writes off for translucent.
##   Ribbons and points occlude correctly against each other.
##   Plane veils never occlude anything, so objects stay visible through them.
##   Cost is that two veils crossing look order-dependent.
##
## Desktop-only; unreachable from browser build. See PROVENANCE.md's "Render Paths".

{.experimental: "strictFuncs".}

import std/[options, strformat]

import ../rga_visualiser/[camera, mesh]
import ./opengl as gl



#[ Renderer Configuration ]#

# Read `DIAMETER_POINT_LEAST`, `WIDTH_LINE_FURNITURE` and `WIDTH_LINE_OBJECT` from `mesh`.
#   `marker` derives selection marker's clearance from them and cannot import module
#   binding straight to OpenGL; one home, read by both render paths.
const LOG_MAX = 1024
  ## Bound how much of driver's compile log is reported.


const SOURCE_VERTEX_POINT = """
#version 330 core
layout (location = 0) in vec2 in_corner;
layout (location = 1) in vec3 in_centre;
layout (location = 2) in float in_radius;
layout (location = 3) in vec3 in_light;
layout (location = 4) in vec4 in_colour;
uniform mat4 view_projection;
uniform vec3 eye;
uniform vec3 forward;
uniform vec3 axis_right;
uniform vec3 axis_up;
uniform float depth_near;
uniform float tangent_half_view;
uniform float height_pixels;
uniform float diameter_least;
out vec4 vertex_colour;
out vec2 vertex_corner;
out float vertex_radius_pixels;
out vec3 vertex_light;
void main() {
  float depth = dot(in_centre - eye, forward);
  if (depth < depth_near) {
    gl_Position = vec4(0.0, 0.0, 2.0, 1.0);
    vertex_colour = vec4(0.0);
    vertex_corner = vec2(0.0);
    vertex_radius_pixels = 0.0;
    vertex_light = vec3(0.0);
    return;
  }
  float world_per_pixel = 2.0*depth*tangent_half_view/height_pixels;
  float radius = max(in_radius, 0.5*diameter_least*world_per_pixel);
  vec3 at = in_centre + in_corner.x*radius*axis_right + in_corner.y*radius*axis_up;
  gl_Position = view_projection*vec4(at, 1.0);
  vertex_colour = in_colour;
  vertex_corner = in_corner;
  vertex_radius_pixels = radius/world_per_pixel;
  vertex_light = vec3(dot(in_light, axis_right), dot(in_light, axis_up), -dot(in_light, forward));
}
""" ## Fan one point record into camera-facing quad at its own radius.
  ##   Sibling copy of `mesh.radiusDrawnAt` and of `glue.js`'s `SOURCE_VERTEX_POINT`;
  ##   change to any one is not finished until other two are checked.
  ##   Quad spans camera's screen axes at centre's depth, so disc shrinks with distance
  ##   exactly as perspective says and floors at `diameter_least` pixels.
  ##   Behind near plane it collapses to clip-space point outside frustum.
  ##   Light is turned into camera's basis here, once per corner: right, up, toward eye,
  ##   which is basis fragment stage builds sphere's normal in.


const SOURCE_FRAGMENT_POINT = """
#version 330 core
in vec4 vertex_colour;
in vec2 vertex_corner;
in float vertex_radius_pixels;
in vec3 vertex_light;
uniform float ambient;
out vec4 out_colour;
void main() {
  float reach = length(vertex_corner);
  if (reach > 1.0) discard;
  float edge = clamp((1.0 - reach)*vertex_radius_pixels, 0.0, 1.0);
  float shade = 1.0;
  if (dot(vertex_light, vertex_light) > 0.5) {
    vec3 normal = vec3(vertex_corner, sqrt(max(0.0, 1.0 - reach*reach)));
    shade = ambient + (1.0 - ambient)*max(0.0, dot(normal, vertex_light));
  }
  out_colour = vec4(vertex_colour.rgb*shade, vertex_colour.a*edge);
}
""" ## Round point's quad into disc, fading its last pixel of rim, shaded as sphere.
  ##   Corner pair is unit-circle coordinate, so edge is where its length passes one, and
  ##   sphere's normal is that pair with height lifted off it.
  ##   Lit where record carries light: Lambert toward it over `ambient` floor; flat
  ##   otherwise. Sibling of `glue.js`'s `SOURCE_FRAGMENT_POINT`.
  ##   Fade over one pixel of radius keeps small disc from shimmering as it moves.


const SOURCE_FRAGMENT = """
#version 330 core
in vec4 vertex_colour;
out vec4 out_colour;
void main() {
  out_colour = vertex_colour;
}
""" ## Write interpolated vertex colour, every veil program's fragment stage.
  ##   Nothing is lit or textured, so colour passes straight through.


const SOURCE_VERTEX_RIBBON = """
#version 330 core
layout (location = 0) in vec2 in_corner;
layout (location = 1) in vec3 in_tail;
layout (location = 2) in vec3 in_head;
layout (location = 3) in float in_width;
layout (location = 4) in float in_fog;
layout (location = 5) in vec4 in_tint_tail;
layout (location = 6) in vec4 in_tint_head;
uniform mat4 view_projection;
uniform vec3 eye;
uniform vec3 forward;
uniform float depth_near;
uniform float tangent_half_view;
uniform float height_pixels;
out vec4 vertex_colour;
out vec3 vertex_world;
out float vertex_fog;
void main() {
  vertex_fog = in_fog;
  float depth_tail = dot(in_tail - eye, forward);
  float depth_head = dot(in_head - eye, forward);
  vec3 across_raw = cross(in_head - in_tail, eye - in_tail);
  float across_length = length(across_raw);
  if (max(depth_tail, depth_head) < depth_near || across_length < 1e-12) {
    gl_Position = vec4(0.0, 0.0, 2.0, 1.0);
    vertex_colour = vec4(0.0);
    vertex_world = in_tail;
    return;
  }
  vec3 near_end = in_tail;
  vec3 far_end = in_head;
  vec4 tint_near = in_tint_tail;
  vec4 tint_far = in_tint_head;
  if (depth_tail < depth_near) {
    float fraction = (depth_near - depth_tail)/(depth_head - depth_tail);
    near_end = in_tail + fraction*(in_head - in_tail);
    tint_near = mix(in_tint_tail, in_tint_head, fraction);
  } else if (depth_head < depth_near) {
    float fraction = (depth_near - depth_head)/(depth_tail - depth_head);
    far_end = in_head + fraction*(in_tail - in_head);
    tint_far = mix(in_tint_head, in_tint_tail, fraction);
  }
  vec3 across = across_raw/across_length;
  vec3 at = mix(near_end, far_end, in_corner.x);
  float depth_at = max(dot(at - eye, forward), depth_near);
  float world_per_pixel = 2.0*depth_at*tangent_half_view/height_pixels;
  at += in_corner.y*0.5*in_width*world_per_pixel*across;
  gl_Position = view_projection*vec4(at, 1.0);
  vertex_world = at;
  vertex_colour = mix(tint_near, tint_far, in_corner.x);
}
""" ## Widen one ribbon record into corner this invocation is, on GPU.
  ##   Sibling copy of `mesh.expandRibbon`, reference suite pins to algebra, and of WebGL
  ##   source in `glue.js`; change to any one is not finished until other two are checked.
  ##   Line for line: reject segment wholly behind near plane (six coincident clipped
  ##   corners), clip end crossing it and blend tint by same fraction, derive across as
  ##   cross join reduces to, step corner off by half width of its end's world-per-pixel.
  ##   `in_corner` is (end, side).
  ##   `in_fog` and world position pass through for fragment stage's fog; see
  ##   `SOURCE_FRAGMENT_RIBBON`.


const SOURCE_FRAGMENT_RIBBON = """
#version 330 core
in vec4 vertex_colour;
in vec3 vertex_world;
in float vertex_fog;
uniform vec3 eye;
uniform float fog_radius_full;
uniform float fog_radius_gone;
out vec4 out_colour;
void main() {
  float fade = 1.0 - clamp(
    (distance(vertex_world, eye) - fog_radius_full)/(fog_radius_gone - fog_radius_full),
    0.0, 1.0
  );
  out_colour = vec4(
    vertex_colour.rgb, vertex_colour.a*mix(1.0, fade, clamp(vertex_fog, 0.0, 1.0))
  );
}
""" ## Shade one ribbon fragment, fading fogged record by its distance from eye.
  ##   Sibling copy of `mesh.alphaGridFade` and of WebGL source in `glue.js`; change to
  ##   any one is not finished until other two are checked.
  ##   Per fragment rather than per vertex, so fade is exact along record of any length,
  ##   which lets lattice line be one record.
  ##   Record with `fog` zero passes through untouched, which is every scene ribbon.


const CORNERS_RIBBON: array[12, float32] = [
  0.0'f32, -1.0, 1.0, -1.0, 1.0, 1.0, 0.0, -1.0, 1.0, 1.0, 0.0, 1.0,
] ## Six (end, side) corners of one ribbon instance, in `expandRibbon`'s winding.


const SOURCE_VERTEX_DISC = """
#version 330 core
layout (location = 0) in vec2 in_corner;
layout (location = 1) in vec3 in_centre;
layout (location = 2) in vec3 in_arm_first;
layout (location = 3) in vec3 in_arm_second;
layout (location = 4) in vec4 in_fill;
uniform mat4 view_projection;
out vec4 vertex_colour;
void main() {
  vec3 at = in_centre + in_corner.x*in_arm_first + in_corner.y*in_arm_second;
  gl_Position = view_projection*vec4(at, 1.0);
  vertex_colour = in_fill;
}
""" ## Fan one disc record over static corner buffer, on GPU.
  ##   Sibling copy of `mesh.expandDiscVertex` and of WebGL source in `glue.js`; change to
  ##   any one is not finished until other two are checked.
  ##   Each corner is centre plus two radius-scaled arms weighted by its cosine and sine;
  ##   `(0, 0)` lands centre corner on centre exactly.


const SOURCE_VERTEX_DOME = """
#version 330 core
layout (location = 0) in vec3 in_unit;
layout (location = 1) in vec4 in_centre_radius;
layout (location = 2) in vec4 in_tint;
uniform mat4 view_projection;
out vec4 vertex_colour;
void main() {
  vec3 at = in_centre_radius.xyz + in_centre_radius.w*in_unit;
  gl_Position = view_projection*vec4(at, 1.0);
  vertex_colour = in_tint;
}
""" ## Widen one dome record over static unit sphere, on GPU.
  ##   Sibling copy of `mesh.expandDomeVertex`, under same three-way rule as disc source.
  ##   Centre plus unit direction scaled by radius.


const SOURCE_VERTEX_RING = """
#version 330 core
layout (location = 0) in vec4 in_arc;
layout (location = 1) in vec2 in_corner;
layout (location = 2) in vec3 in_centre;
layout (location = 3) in vec3 in_arm_first;
layout (location = 4) in vec3 in_arm_second;
layout (location = 5) in vec4 in_fill;
layout (location = 6) in float in_width;
uniform mat4 view_projection;
uniform vec3 eye;
uniform vec3 forward;
uniform float depth_near;
uniform float tangent_half_view;
uniform float height_pixels;
out vec4 vertex_colour;
void main() {
  vec3 tail = in_centre + in_arc.x*in_arm_first + in_arc.y*in_arm_second;
  vec3 head = in_centre + in_arc.z*in_arm_first + in_arc.w*in_arm_second;
  float depth_tail = dot(tail - eye, forward);
  float depth_head = dot(head - eye, forward);
  vec3 across_raw = cross(head - tail, eye - tail);
  float across_length = length(across_raw);
  if (max(depth_tail, depth_head) < depth_near || across_length < 1e-12) {
    gl_Position = vec4(0.0, 0.0, 2.0, 1.0);
    vertex_colour = vec4(0.0);
    return;
  }
  vec3 near_end = tail;
  vec3 far_end = head;
  if (depth_tail < depth_near) {
    float fraction = (depth_near - depth_tail)/(depth_head - depth_tail);
    near_end = tail + fraction*(head - tail);
  } else if (depth_head < depth_near) {
    float fraction = (depth_near - depth_head)/(depth_tail - depth_head);
    far_end = head + fraction*(tail - head);
  }
  vec3 across = across_raw/across_length;
  vec3 at = mix(near_end, far_end, in_corner.x);
  float depth_at = max(dot(at - eye, forward), depth_near);
  float world_per_pixel = 2.0*depth_at*tangent_half_view/height_pixels;
  at += in_corner.y*0.5*in_width*world_per_pixel*across;
  gl_Position = view_projection*vec4(at, 1.0);
  vertex_colour = in_fill;
}
""" ## Widen one ring record into whole plane rim, on GPU.
  ##   Sibling copy of `mesh.expandRingVertex` and of WebGL source in `glue.js`; change to
  ##   any one is not finished until other two are checked.
  ##   One instance is entire circle.
  ##     Static corner buffer carries every segment of closed walk, and `in_arc` names
  ##     this invocation's segment as two angles' `(cos, sin)` pairs.
  ##   Two steps, only first ring's: place segment's ends as `SOURCE_VERTEX_DISC` places
  ##   fan corners, then widen pair by ribbon source's body, line for line, since rim is
  ##   line.
  ##     Tint is flat, so ribbon's blend collapses to `in_fill`; fog is zero, so this
  ##     shares plain fragment stage.


const
  COUNT_CORNERS_DISC = 3*SEGMENTS_CIRCLE_HORIZON
    ## Count corners disc fan's static buffer holds.
    ##   `mesh.discCorners` emits exactly this many `(cos, sin)` pairs.
  COUNT_CORNERS_DOME = 6*LATITUDES_HORIZON*LONGITUDES_HORIZON
    ## Count corners dome's static buffer holds.
    ##   `mesh.domeCorners` emits exactly this many unit directions.
  COUNT_CORNERS_RING = 6*SEGMENTS_CIRCLE_HORIZON
    ## Count corners ring's static buffer holds, whole rim at six per segment.
    ##   `mesh.ringCorners` emits exactly this many six-float entries.



#[ Type Definitions ]#

type
  Renderer* = object ## Define every OpenGL name visualiser allocates.
    program: gl.Uint
    location_view_projection: gl.Int
    location_point_eye: gl.Int
    location_point_forward: gl.Int
    location_point_right: gl.Int
    location_point_up: gl.Int
    location_point_depth_near: gl.Int
    location_point_tangent: gl.Int
    location_point_height: gl.Int
    location_point_diameter_least: gl.Int
    location_point_ambient: gl.Int
    array_points: gl.Uint
    buffer_point_corners: gl.Uint
    buffer_points: gl.Uint
    program_ribbon: gl.Uint
    location_ribbon_view_projection: gl.Int
    location_ribbon_eye: gl.Int
    location_ribbon_forward: gl.Int
    location_ribbon_depth_near: gl.Int
    location_ribbon_tangent: gl.Int
    location_ribbon_height: gl.Int
    location_ribbon_fog_full: gl.Int
    location_ribbon_fog_gone: gl.Int
    array_ribbon: gl.Uint
    buffer_ribbon_corners: gl.Uint
    buffer_ribbon_records: gl.Uint
    program_disc: gl.Uint
    location_disc_view_projection: gl.Int
    array_disc: gl.Uint
    buffer_disc_corners: gl.Uint
    buffer_disc_records: gl.Uint
    program_dome: gl.Uint
    location_dome_view_projection: gl.Int
    array_dome: gl.Uint
    buffer_dome_corners: gl.Uint
    buffer_dome_records: gl.Uint
    program_ring: gl.Uint
    location_ring_view_projection: gl.Int
    location_ring_eye: gl.Int
    location_ring_forward: gl.Int
    location_ring_depth_near: gl.Int
    location_ring_tangent: gl.Int
    location_ring_height: gl.Int
    array_ring: gl.Uint
    buffer_ring_corners: gl.Uint
    buffer_ring_records: gl.Uint



#[ Program Construction ]#

proc compileShader(kind: gl.Enum, source: string): gl.Uint =
  ## Compile one shader stage, reporting driver's diagnosis on failure.
  result = gl.createShader(kind)
  var text = cstring(source)
  gl.shaderSource(result, 1, addr text, nil)
  gl.compileShader(result)

  var status: gl.Int
  gl.getShaderiv(result, gl.COMPILE_STATUS, addr status)
  if status != 0: return

  var log: array[LOG_MAX, char]
  gl.getShaderInfoLog(result, LOG_MAX, nil, addr log[0])
  doAssert false, &"Shader stage {kind:#x} must compile; got `{cast[cstring](addr log[0])}`."


proc linkProgram(source_vertex, source_fragment: string): gl.Uint =
  ## Link vertex and fragment stages into program, reporting failure same way.
  let
    shader_vertex = compileShader(gl.VERTEX_SHADER, source_vertex)
    shader_fragment = compileShader(gl.FRAGMENT_SHADER, source_fragment)
  result = gl.createProgram()
  gl.attachShader(result, shader_vertex)
  gl.attachShader(result, shader_fragment)
  gl.linkProgram(result)
  gl.deleteShader(shader_vertex)
  gl.deleteShader(shader_fragment)

  var status: gl.Int
  gl.getProgramiv(result, gl.LINK_STATUS, addr status)
  if status != 0: return

  var log: array[LOG_MAX, char]
  gl.getProgramInfoLog(result, LOG_MAX, nil, addr log[0])
  doAssert false, &"Program must link; got `{cast[cstring](addr log[0])}`."



#[ Renderer Lifetime ]#

type AttributeView = tuple[index: gl.Uint, floats: gl.Int, offset: int]
  ## Define one attribute's window onto record, i.e. attribute, float count and first float.

const
  VIEWS_POINT = [
    (gl.Uint(1), gl.Int(3), 0), (gl.Uint(2), gl.Int(1), 3), (gl.Uint(3), gl.Int(3), 4),
    (gl.Uint(4), gl.Int(4), 7),
  ] ## Hold point record's four views over `mesh.Vertex`.
    ## Centre, radius, light then colour, after corner's one at location zero.
  VIEWS_CORNER_FLAT = [(gl.Uint(0), gl.Int(2), 0)]
    ## Hold one view over corner buffer of `(end, side)` pairs, ribbon's and disc's alike.
  VIEWS_CORNER_DOME = [(gl.Uint(0), gl.Int(3), 0)]
    ## Hold one view over dome's corner buffer of unit-sphere points.
  VIEWS_CORNER_RING = [(gl.Uint(0), gl.Int(4), 0), (gl.Uint(1), gl.Int(2), 4)]
    ## Hold two views on one ring corner entry: segment's two angles, then `(end, side)`.
  VIEWS_RIBBON = [
    (gl.Uint(1), gl.Int(3), 0), (gl.Uint(2), gl.Int(3), 3), (gl.Uint(3), gl.Int(1), 6),
    (gl.Uint(4), gl.Int(1), 7), (gl.Uint(5), gl.Int(4), 8), (gl.Uint(6), gl.Int(4), 12),
  ] ## Hold record's six views, `mesh.RibbonRecord`'s field order.
  VIEWS_DISC = [
    (gl.Uint(1), gl.Int(3), 0), (gl.Uint(2), gl.Int(3), 3), (gl.Uint(3), gl.Int(3), 6),
    (gl.Uint(4), gl.Int(4), 9),
  ] ## Hold record's four views, `mesh.DiscRecord`'s field order.
  VIEWS_RING = [
    (gl.Uint(2), gl.Int(3), 0), (gl.Uint(3), gl.Int(3), 3), (gl.Uint(4), gl.Int(3), 6),
    (gl.Uint(5), gl.Int(4), 9), (gl.Uint(6), gl.Int(1), 13),
  ] ## Hold record's five views, `mesh.RingRecord`'s field order, after corner's two.
  VIEWS_DOME = [(gl.Uint(1), gl.Int(4), 0), (gl.Uint(2), gl.Int(4), 4)]
    ## Hold record's two views, `mesh.DomeRecord`'s field order.


proc pointViews(
  stride: gl.Sizei, views: openArray[AttributeView], is_instanced: bool, base = 0
) =
  ## Point each view at its floats within current buffer, `base` bytes in.
  ##   `is_instanced` advances view once per instance rather than once per vertex.
  ##   Called at build with `base` zero, and per run at draw time with run's first byte, so
  ##   one table serves both.
  for (index, floats, offset) in views:
    gl.enableVertexAttribArray(index)
    gl.vertexAttribPointer(index, floats, gl.FLOAT_TYPE, gl.FALSE, stride,
      cast[pointer](base + offset*sizeof(float32)))
    if is_instanced: gl.vertexAttribDivisor(index, 1)


proc uploadCorners(buffer: gl.Uint, corners: openArray[float32]) =
  ## Upload static corner geometry every instance of one record kind shares.
  gl.bindBuffer(gl.ARRAY_BUFFER, buffer)
  gl.bufferData(
    gl.ARRAY_BUFFER, gl.Sizeiptr(len(corners)*sizeof(float32)), unsafeAddr corners[0],
    gl.STATIC_DRAW,
  )


proc initPointProgram(renderer: var Renderer) =
  ## Build point program over `mesh.pointCorners`, same source `glue.js` uploads.
  ##   One record per point, fanned into quad by vertex shader; takes ribbon program's
  ##   camera uniforms and camera's two screen axes besides.
  renderer.program = linkProgram(SOURCE_VERTEX_POINT, SOURCE_FRAGMENT_POINT)
  renderer.location_view_projection =
    gl.getUniformLocation(renderer.program, "view_projection")
  renderer.location_point_eye = gl.getUniformLocation(renderer.program, "eye")
  renderer.location_point_forward = gl.getUniformLocation(renderer.program, "forward")
  renderer.location_point_right = gl.getUniformLocation(renderer.program, "axis_right")
  renderer.location_point_up = gl.getUniformLocation(renderer.program, "axis_up")
  renderer.location_point_depth_near = gl.getUniformLocation(renderer.program, "depth_near")
  renderer.location_point_tangent =
    gl.getUniformLocation(renderer.program, "tangent_half_view")
  renderer.location_point_height = gl.getUniformLocation(renderer.program, "height_pixels")
  renderer.location_point_diameter_least =
    gl.getUniformLocation(renderer.program, "diameter_least")
  renderer.location_point_ambient = gl.getUniformLocation(renderer.program, "ambient")
  gl.genVertexArrays(1, addr renderer.array_points)
  gl.genBuffers(1, addr renderer.buffer_point_corners)
  gl.genBuffers(1, addr renderer.buffer_points)
  gl.bindVertexArray(renderer.array_points)
  let corners = pointCorners()
  doAssert len(corners) == 2*COUNT_CORNERS_POINT,
    &"Point corner buffer must hold {2*COUNT_CORNERS_POINT} floats; got `{len(corners)}`."
  uploadCorners(renderer.buffer_point_corners, corners)
  pointViews(gl.Sizei(2*sizeof(float32)), VIEWS_CORNER_FLAT, is_instanced = false)
  gl.bindBuffer(gl.ARRAY_BUFFER, renderer.buffer_points)
  pointViews(gl.Sizei(sizeof(Vertex)), VIEWS_POINT, is_instanced = true)
  gl.bindVertexArray(0)


proc initRibbonProgram(renderer: var Renderer) =
  ## Build ribbon program, its six shared corners, and one record buffer beside them.
  renderer.program_ribbon = linkProgram(SOURCE_VERTEX_RIBBON, SOURCE_FRAGMENT_RIBBON)
  renderer.location_ribbon_view_projection =
    gl.getUniformLocation(renderer.program_ribbon, "view_projection")
  renderer.location_ribbon_eye = gl.getUniformLocation(renderer.program_ribbon, "eye")
  renderer.location_ribbon_forward =
    gl.getUniformLocation(renderer.program_ribbon, "forward")
  renderer.location_ribbon_depth_near =
    gl.getUniformLocation(renderer.program_ribbon, "depth_near")
  renderer.location_ribbon_tangent =
    gl.getUniformLocation(renderer.program_ribbon, "tangent_half_view")
  renderer.location_ribbon_height =
    gl.getUniformLocation(renderer.program_ribbon, "height_pixels")
  renderer.location_ribbon_fog_full =
    gl.getUniformLocation(renderer.program_ribbon, "fog_radius_full")
  renderer.location_ribbon_fog_gone =
    gl.getUniformLocation(renderer.program_ribbon, "fog_radius_gone")
  gl.genVertexArrays(1, addr renderer.array_ribbon)
  gl.genBuffers(1, addr renderer.buffer_ribbon_corners)
  gl.genBuffers(1, addr renderer.buffer_ribbon_records)
  gl.bindVertexArray(renderer.array_ribbon)
  uploadCorners(renderer.buffer_ribbon_corners, CORNERS_RIBBON)
  pointViews(gl.Sizei(2*sizeof(float32)), VIEWS_CORNER_FLAT, is_instanced = false)
  gl.bindBuffer(gl.ARRAY_BUFFER, renderer.buffer_ribbon_records)
  pointViews(gl.Sizei(sizeof(RibbonRecord)), VIEWS_RIBBON, is_instanced = true)
  gl.bindVertexArray(0)


proc initDiscProgram(renderer: var Renderer) =
  ## Build disc program over `mesh.discCorners`, same source `glue.js` uploads.
  renderer.program_disc = linkProgram(SOURCE_VERTEX_DISC, SOURCE_FRAGMENT)
  renderer.location_disc_view_projection =
    gl.getUniformLocation(renderer.program_disc, "view_projection")
  gl.genVertexArrays(1, addr renderer.array_disc)
  gl.genBuffers(1, addr renderer.buffer_disc_corners)
  gl.genBuffers(1, addr renderer.buffer_disc_records)
  gl.bindVertexArray(renderer.array_disc)
  let corners = discCorners()
  doAssert len(corners) == 2*COUNT_CORNERS_DISC,
    &"Disc corner buffer must hold {2*COUNT_CORNERS_DISC} floats; got `{len(corners)}`."
  uploadCorners(renderer.buffer_disc_corners, corners)
  pointViews(gl.Sizei(2*sizeof(float32)), VIEWS_CORNER_FLAT, is_instanced = false)
  gl.bindBuffer(gl.ARRAY_BUFFER, renderer.buffer_disc_records)
  pointViews(gl.Sizei(sizeof(DiscRecord)), VIEWS_DISC, is_instanced = true)
  gl.bindVertexArray(0)


proc initRingProgram(renderer: var Renderer) =
  ## Build ring program over `mesh.ringCorners`, same source `glue.js` uploads.
  ##   Takes ribbon program's camera uniforms too, because widening it runs is ribbon's.
  renderer.program_ring = linkProgram(SOURCE_VERTEX_RING, SOURCE_FRAGMENT)
  renderer.location_ring_view_projection =
    gl.getUniformLocation(renderer.program_ring, "view_projection")
  renderer.location_ring_eye = gl.getUniformLocation(renderer.program_ring, "eye")
  renderer.location_ring_forward = gl.getUniformLocation(renderer.program_ring, "forward")
  renderer.location_ring_depth_near =
    gl.getUniformLocation(renderer.program_ring, "depth_near")
  renderer.location_ring_tangent =
    gl.getUniformLocation(renderer.program_ring, "tangent_half_view")
  renderer.location_ring_height =
    gl.getUniformLocation(renderer.program_ring, "height_pixels")
  gl.genVertexArrays(1, addr renderer.array_ring)
  gl.genBuffers(1, addr renderer.buffer_ring_corners)
  gl.genBuffers(1, addr renderer.buffer_ring_records)
  gl.bindVertexArray(renderer.array_ring)
  let corners = ringCorners()
  doAssert len(corners) == 6*COUNT_CORNERS_RING,
    &"Ring corner buffer must hold {6*COUNT_CORNERS_RING} floats; got `{len(corners)}`."
  uploadCorners(renderer.buffer_ring_corners, corners)
  pointViews(gl.Sizei(6*sizeof(float32)), VIEWS_CORNER_RING, is_instanced = false)
  gl.bindBuffer(gl.ARRAY_BUFFER, renderer.buffer_ring_records)
  pointViews(gl.Sizei(sizeof(RingRecord)), VIEWS_RING, is_instanced = true)
  gl.bindVertexArray(0)


proc initDomeProgram(renderer: var Renderer) =
  ## Build dome program over `mesh.domeCorners`, same source `glue.js` uploads.
  renderer.program_dome = linkProgram(SOURCE_VERTEX_DOME, SOURCE_FRAGMENT)
  renderer.location_dome_view_projection =
    gl.getUniformLocation(renderer.program_dome, "view_projection")
  gl.genVertexArrays(1, addr renderer.array_dome)
  gl.genBuffers(1, addr renderer.buffer_dome_corners)
  gl.genBuffers(1, addr renderer.buffer_dome_records)
  gl.bindVertexArray(renderer.array_dome)
  let corners = domeCorners()
  doAssert len(corners) == 3*COUNT_CORNERS_DOME,
    &"Dome corner buffer must hold {3*COUNT_CORNERS_DOME} floats; got `{len(corners)}`."
  uploadCorners(renderer.buffer_dome_corners, corners)
  pointViews(gl.Sizei(3*sizeof(float32)), VIEWS_CORNER_DOME, is_instanced = false)
  gl.bindBuffer(gl.ARRAY_BUFFER, renderer.buffer_dome_records)
  pointViews(gl.Sizei(sizeof(DomeRecord)), VIEWS_DOME, is_instanced = true)
  gl.bindVertexArray(0)


proc initRenderer*(): Renderer =
  ## Build every program, point vertex buffer, and each record kind's instanced array.
  ##   Each array carries its static corner geometry.
  ##   OpenGL context must already be current.
  result.initPointProgram()
  result.initRibbonProgram()
  # Build veil and rim programs on one shape.
  #   Each has static corner geometry from `mesh`'s generators, same source `glue.js`
  #   uploads through `nim*Corners`, and one record buffer of divisor-one instance
  #   attributes beside it.
  result.initDiscProgram()
  result.initRingProgram()
  result.initDomeProgram()

  gl.enable(gl.DEPTH_TEST)
  gl.depthFunc(gl.LESS)
  gl.enable(gl.BLEND)
  gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)
  gl.enable(gl.PROGRAM_POINT_SIZE)
  # Smooth ribbon edges by multisampling.
  #   Ribbon is ordinary triangle pair, so nothing smooths its edges as `GL_LINE_SMOOTH`
  #   smoothed line's; without this thin grid ribbon rasterises only where it covers pixel
  #   centre, and whole grid reads as dotted.
  #   Context asks for multisampled framebuffer in `visualiser.main`; this turns it on.
  #   Browser asks `antialias: true`.
  gl.enable(gl.MULTISAMPLE)



#[ Frame Drawing ]#

proc clearFrame*(width, height: int) =
  ## Clear colour and depth to backdrop, resizing viewport first.
  let backdrop = Ink.Backdrop.colour
  gl.viewport(0, 0, gl.Sizei(width), gl.Sizei(height))
  gl.clearColor(backdrop.red, backdrop.green, backdrop.blue, 1.0)
  gl.clear(gl.COLOR_BUFFER_BIT or gl.DEPTH_BUFFER_BIT)


proc uploadPoints(renderer: Renderer, meshes: MeshSet) =
  ## Hand point records to driver whole, ready to be drawn as one run or two.
  ##   Separate from drawing because two runs are issued in different passes; see
  ##   `drawMeshes`.
  ##   Mesh uploaded twice per frame would be one real cost of that split.
  let count = meshes.points.count_vertices
  if count == 0: return
  gl.bindVertexArray(renderer.array_points)
  gl.bindBuffer(gl.ARRAY_BUFFER, renderer.buffer_points)
  gl.bufferData(
    gl.ARRAY_BUFFER,
    gl.Sizeiptr(count*sizeof(Vertex)),
    unsafeAddr meshes.points.vertices[0],
    gl.DYNAMIC_DRAW,
  )


proc uploadRibbons(renderer: Renderer, meshes: MeshSet) =
  ## Hand this frame's ribbon records to driver whole; shader does rest.
  if meshes.ribbons.count == 0: return
  gl.bindBuffer(gl.ARRAY_BUFFER, renderer.buffer_ribbon_records)
  gl.bufferData(
    gl.ARRAY_BUFFER,
    gl.Sizeiptr(meshes.ribbons.count*sizeof(RibbonRecord)),
    unsafeAddr meshes.ribbons.records[0],
    gl.DYNAMIC_DRAW,
  )


proc uploadVeils(renderer: Renderer, meshes: MeshSet) =
  ## Hand this frame's disc, ring and dome records to driver whole; shaders fan them.
  ##   Rings ride along on same upload schedule, not because rim is veil: it is drawn
  ##   opaque, with lines.
  if meshes.rings.count > 0:
    gl.bindBuffer(gl.ARRAY_BUFFER, renderer.buffer_ring_records)
    gl.bufferData(
      gl.ARRAY_BUFFER,
      gl.Sizeiptr(meshes.rings.count*sizeof(RingRecord)),
      unsafeAddr meshes.rings.records[0],
      gl.DYNAMIC_DRAW,
    )
  if meshes.discs.count > 0:
    gl.bindBuffer(gl.ARRAY_BUFFER, renderer.buffer_disc_records)
    gl.bufferData(
      gl.ARRAY_BUFFER,
      gl.Sizeiptr(meshes.discs.count*sizeof(DiscRecord)),
      unsafeAddr meshes.discs.records[0],
      gl.DYNAMIC_DRAW,
    )
  if meshes.domes.count > 0:
    gl.bindBuffer(gl.ARRAY_BUFFER, renderer.buffer_dome_records)
    gl.bufferData(
      gl.ARRAY_BUFFER,
      gl.Sizeiptr(meshes.domes.count*sizeof(DomeRecord)),
      unsafeAddr meshes.domes.records[0],
      gl.DYNAMIC_DRAW,
    )


func runOfRibbons(ribbons: RibbonMesh, is_overlay: bool): tuple[first, count: int] =
  ## Say which stretch of ribbon records belongs to which pass; `runOf`'s rule.
  let split =
    if ribbons.index_overlay.isSome: clamp(ribbons.index_overlay.get, 0, ribbons.count)
    else: ribbons.count
  if is_overlay: (first: split, count: ribbons.count - split)
  else: (first: 0, count: split)


proc drawRibbonRun(renderer: Renderer, meshes: MeshSet, is_overlay: bool) =
  ## Draw one run of already-uploaded ribbon records as instanced triangle pairs.
  ##   GL 3.3 has no base instance, so run not starting at first record re-points five
  ##   instance attributes at its first byte.
  ##     Same pointers `initRenderer` set, offset by run's start.
  let run = runOfRibbons(meshes.ribbons, is_overlay)
  if run.count == 0: return
  gl.bindVertexArray(renderer.array_ribbon)
  gl.bindBuffer(gl.ARRAY_BUFFER, renderer.buffer_ribbon_records)
  pointViews(
    gl.Sizei(sizeof(RibbonRecord)), VIEWS_RIBBON, is_instanced = true,
    base = run.first*sizeof(RibbonRecord),
  )
  gl.drawArraysInstanced(gl.TRIANGLES, 0, 6, gl.Sizei(run.count))


func runOfRings(rings: RingMesh, is_overlay: bool): tuple[first, count: int] =
  ## Say which stretch of ring records belongs to which pass; `runOf`'s rule.
  let split =
    if rings.index_overlay.isSome: clamp(rings.index_overlay.get, 0, rings.count)
    else: rings.count
  if is_overlay: (first: split, count: rings.count - split)
  else: (first: 0, count: split)


proc drawRingRun(renderer: Renderer, meshes: MeshSet, is_overlay: bool) =
  ## Draw one run of already-uploaded ring records, each instance whole plane rim.
  ##   Re-points instance attributes at run's first byte, `drawRibbonRun`'s rule.
  ##   Mirrors `glue.js`'s `drawRings`.
  let run = runOfRings(meshes.rings, is_overlay)
  if run.count == 0: return
  gl.bindVertexArray(renderer.array_ring)
  gl.bindBuffer(gl.ARRAY_BUFFER, renderer.buffer_ring_records)
  pointViews(
    gl.Sizei(sizeof(RingRecord)), VIEWS_RING, is_instanced = true,
    base = run.first*sizeof(RingRecord),
  )
  gl.drawArraysInstanced(
    gl.TRIANGLES, 0, gl.Sizei(COUNT_CORNERS_RING), gl.Sizei(run.count)
  )


func runOf(mesh: Mesh, is_overlay: bool): tuple[first, count: int] =
  ## Say which stretch of one mesh belongs to depth-tested run or to overlay run.
  ##   Empty where mesh has no such run, ordinary case for overlay; see
  ##   `mesh.Mesh.index_overlay`.
  let split =
    if mesh.index_overlay.isSome: clamp(mesh.index_overlay.get, 0, mesh.count_vertices)
    else: mesh.count_vertices
  if is_overlay: (first: split, count: mesh.count_vertices - split)
  else: (first: 0, count: split)


proc drawPointRun(renderer: Renderer, meshes: MeshSet, is_overlay: bool) =
  ## Draw one run of already-uploaded point records, each instance one disc.
  ##   Re-points instance attributes at run's first byte, `drawRibbonRun`'s rule.
  ##   Mirrors `glue.js`'s `drawPoints`.
  let run = runOf(meshes.points, is_overlay)
  if run.count == 0: return
  gl.bindVertexArray(renderer.array_points)
  gl.bindBuffer(gl.ARRAY_BUFFER, renderer.buffer_points)
  pointViews(
    gl.Sizei(sizeof(Vertex)), VIEWS_POINT, is_instanced = true,
    base = run.first*sizeof(Vertex),
  )
  gl.drawArraysInstanced(
    gl.TRIANGLE_STRIP, 0, gl.Sizei(COUNT_CORNERS_POINT), gl.Sizei(run.count)
  )


func runsOfVeils(veils: VeilRuns, is_overlay: bool): tuple[begin, until: int] =
  ## Say which stretch of veil runs belongs to which pass: `runOf`'s rule at run grain.
  ##   Run never straddles mark; see `mesh.VeilRuns`.
  let split =
    if veils.index_overlay.isSome: clamp(veils.index_overlay.get, 0, veils.count)
    else: veils.count
  if is_overlay: (begin: split, until: veils.count)
  else: (begin: 0, until: split)


proc drawVeilRun(renderer: Renderer, run: VeilRun) =
  ## Draw one run of veils through its kind's program.
  ##   Re-points instance views at run's first byte, as `drawRibbonRun` does.
  case run.kind
  of VeilKind.Disc:
    gl.useProgram(renderer.program_disc)
    gl.bindVertexArray(renderer.array_disc)
    gl.bindBuffer(gl.ARRAY_BUFFER, renderer.buffer_disc_records)
    pointViews(
      gl.Sizei(sizeof(DiscRecord)), VIEWS_DISC, is_instanced = true,
      base = int(run.first)*sizeof(DiscRecord),
    )
    gl.drawArraysInstanced(
      gl.TRIANGLES, 0, gl.Sizei(COUNT_CORNERS_DISC), gl.Sizei(run.count)
    )
  of VeilKind.Dome:
    gl.useProgram(renderer.program_dome)
    gl.bindVertexArray(renderer.array_dome)
    gl.bindBuffer(gl.ARRAY_BUFFER, renderer.buffer_dome_records)
    pointViews(
      gl.Sizei(sizeof(DomeRecord)), VIEWS_DOME, is_instanced = true,
      base = int(run.first)*sizeof(DomeRecord),
    )
    gl.drawArraysInstanced(
      gl.TRIANGLES, 0, gl.Sizei(COUNT_CORNERS_DOME), gl.Sizei(run.count)
    )


proc drawVeilRuns(renderer: Renderer, meshes: MeshSet, is_overlay: bool) =
  ## Walk one pass's stretch of veil draw order, drawing each run through its program.
  ##   Two veils then blend in order scene emitted them.
  ##   Mirrors `glue.js`'s `drawVeilRuns`.
  let (begin, until) = runsOfVeils(meshes.veils, is_overlay)
  for i in begin ..< until: renderer.drawVeilRun(meshes.veils.runs[i])


func hasOverlay(meshes: MeshSet): bool =
  ## Report whether anything in this set asked to be drawn over rest of it.
  if runOfRibbons(meshes.ribbons, is_overlay = true).count > 0: return true
  if runOfRings(meshes.rings, is_overlay = true).count > 0: return true
  if runOf(meshes.points, is_overlay = true).count > 0: return true
  let (begin, until) = runsOfVeils(meshes.veils, is_overlay = true)
  until > begin


proc drawMeshes*(
  renderer: Renderer, meshes: MeshSet, view_projection: Matrix4, scale: DrawScale
) =
  ## Draw every mesh, opaque kinds before translucent ones, then overlay over both.
  ##   Takes frame's `DrawScale` because ribbon program needs camera.
  ##     Widening, near clip and screen-constant width run in its vertex shader, fed by
  ##     fields `mesh.expandRibbon` reads.
  ##   Overlay is second pass over every kind, not tail on each one.
  ##     Tail leaves selected line over other lines and still tinted by plane's veil,
  ##     because veil is later kind and overlay run writes no depth for it to be rejected
  ##     against.
  ##   Overlay is drawn against depth buffer cleared first, not with test off.
  ##     Nothing unselected is left to reject against, so selected object shows through
  ##     whatever stands before it; selected objects still reject one another by depth.
  gl.useProgram(renderer.program_ribbon)
  gl.uniformMatrix4fv(
    renderer.location_ribbon_view_projection, 1, gl.FALSE, view_projection.elementsAddress
  )
  gl.uniform3f(renderer.location_ribbon_eye,
    gl.Float(scale.eye.x), gl.Float(scale.eye.y), gl.Float(scale.eye.z))
  gl.uniform3f(renderer.location_ribbon_forward,
    gl.Float(scale.forward.x), gl.Float(scale.forward.y), gl.Float(scale.forward.z))
  gl.uniform1f(renderer.location_ribbon_depth_near, gl.Float(scale.depthNear))
  gl.uniform1f(renderer.location_ribbon_tangent, gl.Float(scale.tangentHalfView))
  gl.uniform1f(renderer.location_ribbon_height, gl.Float(scale.heightPixels))
  # Set furniture fog's two radii, for fragment stage's fade.
  #   One schedule per frame, from same rule placement cuts chords with.
  let fog = fogFurnitureFor(scale.extentFurniture)
  gl.uniform1f(renderer.location_ribbon_fog_full, gl.Float(fog.radius_full))
  gl.uniform1f(renderer.location_ribbon_fog_gone, gl.Float(fog.radius_gone))
  renderer.uploadRibbons(meshes)

  # Give point program ribbon program's camera and both screen axes.
  #   Disc is spanned across them at centre's depth; see `mesh.radiusDrawnAt`.
  gl.useProgram(renderer.program)
  gl.uniformMatrix4fv(
    renderer.location_view_projection, 1, gl.FALSE, view_projection.elementsAddress
  )
  gl.uniform3f(renderer.location_point_eye,
    gl.Float(scale.eye.x), gl.Float(scale.eye.y), gl.Float(scale.eye.z))
  gl.uniform3f(renderer.location_point_forward,
    gl.Float(scale.forward.x), gl.Float(scale.forward.y), gl.Float(scale.forward.z))
  gl.uniform3f(renderer.location_point_right,
    gl.Float(scale.axis_right.x), gl.Float(scale.axis_right.y), gl.Float(scale.axis_right.z))
  gl.uniform3f(renderer.location_point_up,
    gl.Float(scale.axis_up.x), gl.Float(scale.axis_up.y), gl.Float(scale.axis_up.z))
  gl.uniform1f(renderer.location_point_depth_near, gl.Float(scale.depthNear))
  gl.uniform1f(renderer.location_point_tangent, gl.Float(scale.tangentHalfView))
  gl.uniform1f(renderer.location_point_height, gl.Float(scale.heightPixels))
  gl.uniform1f(renderer.location_point_diameter_least, gl.Float(DIAMETER_POINT_LEAST))
  gl.uniform1f(renderer.location_point_ambient, gl.Float(FRACTION_AMBIENT_SHADE))
  renderer.uploadPoints(meshes)

  # Give both veil programs this frame's matrix before run walk.
  #   Walk switches between them per run.
  gl.useProgram(renderer.program_disc)
  gl.uniformMatrix4fv(
    renderer.location_disc_view_projection, 1, gl.FALSE, view_projection.elementsAddress
  )
  gl.useProgram(renderer.program_dome)
  gl.uniformMatrix4fv(
    renderer.location_dome_view_projection, 1, gl.FALSE, view_projection.elementsAddress
  )
  # Give ring program ribbon program's whole camera.
  #   Rim is widened in screen space by very rule line is.
  gl.useProgram(renderer.program_ring)
  gl.uniformMatrix4fv(
    renderer.location_ring_view_projection, 1, gl.FALSE, view_projection.elementsAddress
  )
  gl.uniform3f(renderer.location_ring_eye,
    gl.Float(scale.eye.x), gl.Float(scale.eye.y), gl.Float(scale.eye.z))
  gl.uniform3f(renderer.location_ring_forward,
    gl.Float(scale.forward.x), gl.Float(scale.forward.y), gl.Float(scale.forward.z))
  gl.uniform1f(renderer.location_ring_depth_near, gl.Float(scale.depthNear))
  gl.uniform1f(renderer.location_ring_tangent, gl.Float(scale.tangentHalfView))
  gl.uniform1f(renderer.location_ring_height, gl.Float(scale.heightPixels))
  renderer.uploadVeils(meshes)

  # Draw opaque kinds first, so they own depth buffer.
  gl.useProgram(renderer.program_ribbon)
  renderer.drawRibbonRun(meshes, is_overlay = false)
  gl.useProgram(renderer.program_ring)
  renderer.drawRingRun(meshes, is_overlay = false)
  gl.useProgram(renderer.program)
  renderer.drawPointRun(meshes, is_overlay = false)

  # Draw veils without writing depth, so objects stay visible through them.
  gl.depthMask(gl.FALSE)
  renderer.drawVeilRuns(meshes, is_overlay = false)
  gl.depthMask(gl.TRUE)

  # Draw overlay over all of it, against depth cleared first.
  #   With test off, emission order decided among selected objects, and planet selected
  #   after its moon buried moon standing in front of it. Veils write no depth here
  #   either, as above.
  if meshes.hasOverlay:
    gl.clear(gl.DEPTH_BUFFER_BIT)
    gl.useProgram(renderer.program_ribbon)
    renderer.drawRibbonRun(meshes, is_overlay = true)
    gl.useProgram(renderer.program_ring)
    renderer.drawRingRun(meshes, is_overlay = true)
    gl.useProgram(renderer.program)
    renderer.drawPointRun(meshes, is_overlay = true)
    gl.depthMask(gl.FALSE)
    renderer.drawVeilRuns(meshes, is_overlay = true)
    gl.depthMask(gl.TRUE)
  gl.bindVertexArray(0)



#[ Frame Capture ]#

proc capturePixels*(width, height: int; pixels: var openArray[uint8]) =
  ## Read framebuffer back as tightly packed RGB triples, first row nearest bottom.
  ##   Caller owns fixed storage, sized to largest export this build allows.
  ##   Window resized past that bound fails loudly rather than silently reallocating.
  let count = width*height*3
  doAssert len(pixels) >= count,
    &"Readback buffer must hold {count} bytes; got `{len(pixels)}`."
  gl.pixelStorei(gl.PACK_ALIGNMENT, 1)
  gl.readPixels(
    0, 0, gl.Sizei(width), gl.Sizei(height), gl.RGB, gl.UNSIGNED_BYTE, addr pixels[0]
  )
