// WebGL context, shader sources, programs and buffer upload; not Nim because these reach browser
//   APIs Nim's JS backend does not express.
//   Presentation alone: every join, meet, pick, drag and camera move is computed by
//   bridge, compiled from same modules desktop draws through (Article II.9).
//   Concatenated into page in order `tools/build.nim` names; see its `SCRIPTS`.

/* ---------------------------------------------------------------------- */
/* Everything above this script is `pga`, `objects`, `mesh`, `camera`,    */
/* `scene`, `picking`, `interaction` and `storyboard`, compiled to JS by  */
/* `nim js` from `visualiser/browser_bridge.nim`: every join, meet, pick, */
/* drag and camera move below runs that compiled code, never JS rewrite.  */
/* This script is presentation only: WebGL, DOM and pointer input, role   */
/* OpenGL/SDL/Dear ImGui play over desktop app's identical geometry. See  */
/* `browser_bridge.nim` doc for what deliberately does NOT carry over.    */
/* ---------------------------------------------------------------------- */

const canvas = elementById<HTMLCanvasElement>('gl');
// No `preserveDrawingBuffer`, deliberately: it makes every frame keep copy of drawing.
//   buffer for whole session, on phone, so that button pressed once can read it
//   afterwards. `captureFrameIfAsked` reads buffer from inside frame that drew it
//   instead, which costs nothing and is what image export uses.
const OPTIONS_CONTEXT: WebGLContextAttributes = { antialias: true, alpha: false };
const context_webgl = (canvas.getContext('webgl', OPTIONS_CONTEXT)
  || canvas.getContext('experimental-webgl', OPTIONS_CONTEXT)) as WebGLRenderingContext | null;
if (context_webgl === null) throw new Error('WebGL unavailable; page cannot draw.');
const gl: WebGLRenderingContext = context_webgl;

// Fan one point record into camera-facing quad at its own radius.
//   Sibling copy of `mesh.radiusDrawnAt` and of GLSL 3.30 source in `renderer.nim`;
//   change to any one is not finished until other two are checked.
//   Quad spans camera's screen axes at centre's depth, so disc shrinks with distance
//   exactly as perspective says and floors at `uDiameterLeast` pixels. Behind near plane
//   it collapses to clip-space point outside frustum.
const SOURCE_VERTEX_POINT = `
  attribute vec2 aCorner;
  attribute vec3 aCentre;
  attribute float aRadius;
  attribute vec3 aLight;
  attribute vec4 aColor;
  uniform mat4 uMVP;
  uniform vec3 uEye;
  uniform vec3 uForward;
  uniform vec3 uRight;
  uniform vec3 uUp;
  uniform float uDepthNear;
  uniform float uTangentHalfView;
  uniform float uHeightPixels;
  uniform float uDiameterLeast;
  varying vec4 vColor;
  varying vec2 vCorner;
  varying float vRadiusPixels;
  varying vec3 vLight;
  void main() {
    float depth = dot(aCentre - uEye, uForward);
    if (depth < uDepthNear) {
      gl_Position = vec4(0.0, 0.0, 2.0, 1.0);
      vColor = vec4(0.0);
      vCorner = vec2(0.0);
      vRadiusPixels = 0.0;
      vLight = vec3(0.0);
      return;
    }
    float world_per_pixel = 2.0*depth*uTangentHalfView/uHeightPixels;
    float radius = max(aRadius, 0.5*uDiameterLeast*world_per_pixel);
    vec3 at = aCentre + aCorner.x*radius*uRight + aCorner.y*radius*uUp;
    gl_Position = uMVP*vec4(at, 1.0);
    vColor = aColor;
    vCorner = aCorner;
    vRadiusPixels = radius/world_per_pixel;
    vLight = vec3(dot(aLight, uRight), dot(aLight, uUp), -dot(aLight, uForward));
  }
`;
// Round point's quad into disc, fading its last pixel of rim, shaded as sphere.
//   Corner pair is unit-circle coordinate, so edge is where its length passes one, and
//   sphere's normal is that pair with height lifted off it. Lit where record carries
//   light, in camera's basis from vertex stage: Lambert toward it over `uAmbient` floor;
//   flat otherwise. Sibling of GLSL 3.30 source in `renderer.nim`.
const SOURCE_FRAGMENT_POINT = `
  precision mediump float;
  varying vec4 vColor;
  varying vec2 vCorner;
  varying float vRadiusPixels;
  varying vec3 vLight;
  uniform float uAmbient;
  void main() {
    float reach = length(vCorner);
    if (reach > 1.0) discard;
    float edge = clamp((1.0 - reach)*vRadiusPixels, 0.0, 1.0);
    float shade = 1.0;
    if (dot(vLight, vLight) > 0.5) {
      vec3 normal = vec3(vCorner, sqrt(max(0.0, 1.0 - reach*reach)));
      shade = uAmbient + (1.0 - uAmbient)*max(0.0, dot(normal, vLight));
    }
    gl_FragColor = vec4(vColor.rgb*shade, vColor.a*edge);
  }
`;
// Plain colour pass-through, every wash program's fragment stage.
const SOURCE_FRAGMENT = `
  precision mediump float;
  varying vec4 vColor;
  void main() {
    gl_FragColor = vColor;
  }
`;

// Driver reports absent object as `null` for every `create*` call, and page cannot draw
//   through any of them, so each is named where it fails rather than carried onward as
//   nothing (Article IV.4).
function compileShader(type: GLenum, src: string): WebGLShader {
  const shader = gl.createShader(type);
  if (shader === null) throw new Error('Shader not created.');
  gl.shaderSource(shader, src);
  gl.compileShader(shader);
  if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
    throw new Error(gl.getShaderInfoLog(shader) ?? 'Shader failed to compile.');
  }
  return shader;
}

function createdProgram(): WebGLProgram {
  const made = gl.createProgram();
  if (made === null) throw new Error('Program not created.');
  return made;
}

function createdBuffer(): WebGLBuffer {
  const made = gl.createBuffer();
  if (made === null) throw new Error('Buffer not created.');
  return made;
}
const program = createdProgram();
gl.attachShader(program, compileShader(gl.VERTEX_SHADER, SOURCE_VERTEX_POINT));
gl.attachShader(program, compileShader(gl.FRAGMENT_SHADER, SOURCE_FRAGMENT_POINT));
gl.linkProgram(program);
if (!gl.getProgramParameter(program, gl.LINK_STATUS)) {
  throw new Error(gl.getProgramInfoLog(program) ?? 'Program failed to link.');
}
gl.useProgram(program);

const point_attribs = {
  corner: gl.getAttribLocation(program, 'aCorner'),
  centre: gl.getAttribLocation(program, 'aCentre'),
  radius: gl.getAttribLocation(program, 'aRadius'),
  light: gl.getAttribLocation(program, 'aLight'),
  colour: gl.getAttribLocation(program, 'aColor'),
};
const point_uniforms = {
  mvp: gl.getUniformLocation(program, 'uMVP'),
  eye: gl.getUniformLocation(program, 'uEye'),
  forward: gl.getUniformLocation(program, 'uForward'),
  right: gl.getUniformLocation(program, 'uRight'),
  up: gl.getUniformLocation(program, 'uUp'),
  depth_near: gl.getUniformLocation(program, 'uDepthNear'),
  tangent: gl.getUniformLocation(program, 'uTangentHalfView'),
  height: gl.getUniformLocation(program, 'uHeightPixels'),
  diameter_least: gl.getUniformLocation(program, 'uDiameterLeast'),
  ambient: gl.getUniformLocation(program, 'uAmbient'),
};

// Read from renderer.nim's own constants via nimRenderLineWidths.
//   Never hand-copied literal that could drift out of sync with them.
//   Least point diameter is uniform here, floor point vertex shader holds far disc at.
//   Two line widths are not: each ribbon record carries its width and ribbon vertex
//   shader widens it, because WebGL clamps `gl.lineWidth` to one pixel on most
//   implementations.
const DIAMETER_POINT_LEAST = flatAt(nimRenderLineWidths(), 0);
// Night side of lit point, as fraction of its colour; `mesh.FRACTION_AMBIENT_SHADE`.
const AMBIENT_SHADE = nimShadeAmbient();

// Widen one 16-float ribbon record into corner this invocation is.
//   Sibling copy of `mesh.expandRibbon`, reference suite pins to algebra, and of GLSL
//   3.30 source in `renderer.nim`; change to any one of three is not finished until
//   other two are checked.
//   Clip to near plane, blend clipped end's tint by same fraction, derive across as
//   cross join reduces to, and step off by half width of this end's own
//   world-per-pixel.
const SOURCE_VERTEX_RIBBON = `
  attribute vec2 aCorner;
  attribute vec3 aTail;
  attribute vec3 aHead;
  attribute float aWidth;
  attribute float aFog;
  attribute vec4 aTintTail;
  attribute vec4 aTintHead;
  uniform mat4 uMVP;
  uniform vec3 uEye;
  uniform vec3 uForward;
  uniform float uDepthNear;
  uniform float uTangentHalfView;
  uniform float uHeightPixels;
  varying vec4 vColor;
  varying vec3 vWorld;
  varying float vFog;
  void main() {
    vFog = aFog;
    float depth_tail = dot(aTail - uEye, uForward);
    float depth_head = dot(aHead - uEye, uForward);
    vec3 across_raw = cross(aHead - aTail, uEye - aTail);
    float across_length = length(across_raw);
    if (max(depth_tail, depth_head) < uDepthNear || across_length < 1e-12) {
      gl_Position = vec4(0.0, 0.0, 2.0, 1.0);
      vColor = vec4(0.0);
      vWorld = aTail;
      return;
    }
    vec3 near_end = aTail;
    vec3 far_end = aHead;
    vec4 tint_near = aTintTail;
    vec4 tint_far = aTintHead;
    if (depth_tail < uDepthNear) {
      float fraction = (uDepthNear - depth_tail)/(depth_head - depth_tail);
      near_end = aTail + fraction*(aHead - aTail);
      tint_near = mix(aTintTail, aTintHead, fraction);
    } else if (depth_head < uDepthNear) {
      float fraction = (uDepthNear - depth_head)/(depth_tail - depth_head);
      far_end = aHead + fraction*(aTail - aHead);
      tint_far = mix(aTintHead, aTintTail, fraction);
    }
    vec3 across = across_raw/across_length;
    vec3 at = mix(near_end, far_end, aCorner.x);
    float depth_at = max(dot(at - uEye, uForward), uDepthNear);
    float world_per_pixel = 2.0*depth_at*uTangentHalfView/uHeightPixels;
    at += aCorner.y*0.5*aWidth*world_per_pixel*across;
    gl_Position = uMVP*vec4(at, 1.0);
    vWorld = at;
    vColor = mix(tint_near, tint_far, aCorner.x);
  }
`;
// Fade fogged record by its distance from eye, per fragment.
//   Sibling copy of `mesh.alphaGridFade`, reference fog is held to, and of GLSL 3.30
//   fragment source in `renderer.nim`; change to any one of three is not finished
//   until other two are checked.
//   Per fragment rather than per vertex, so fade is exact along record of any length,
//   which is what lets lattice line be one record instead of chain of fade pieces.
//   Record with fog zero passes through untouched, which is every scene ribbon.
const SOURCE_FRAGMENT_RIBBON = `
  precision mediump float;
  varying vec4 vColor;
  varying highp vec3 vWorld;
  varying highp float vFog;
  uniform highp vec3 uEye;
  uniform highp float uFogFull;
  uniform highp float uFogGone;
  void main() {
    highp float fade = 1.0 - clamp(
      (distance(vWorld, uEye) - uFogFull)/(uFogGone - uFogFull), 0.0, 1.0
    );
    gl_FragColor = vec4(vColor.rgb, vColor.a*mix(1.0, fade, clamp(vFog, 0.0, 1.0)));
  }
`;
const program_ribbon = createdProgram();
gl.attachShader(program_ribbon, compileShader(gl.VERTEX_SHADER, SOURCE_VERTEX_RIBBON));
gl.attachShader(program_ribbon, compileShader(gl.FRAGMENT_SHADER, SOURCE_FRAGMENT_RIBBON));
gl.linkProgram(program_ribbon);
if (!gl.getProgramParameter(program_ribbon, gl.LINK_STATUS)) {
  throw new Error(gl.getProgramInfoLog(program_ribbon) ?? 'Program failed to link.');
}
// Require instancing, extension on WebGL1 and universally shipped.
//   Context without it gets same loud failure context without WebGL gets, not silent
//   picture with no lines.
const extension_instanced = gl.getExtension('ANGLE_instanced_arrays');
if (extension_instanced === null) {
  throw new Error('ANGLE_instanced_arrays is unavailable');
}
const instanced: ANGLE_instanced_arrays = extension_instanced;
const ribbon_attribs = {
  corner: gl.getAttribLocation(program_ribbon, 'aCorner'),
  tail: gl.getAttribLocation(program_ribbon, 'aTail'),
  head: gl.getAttribLocation(program_ribbon, 'aHead'),
  width: gl.getAttribLocation(program_ribbon, 'aWidth'),
  fog: gl.getAttribLocation(program_ribbon, 'aFog'),
  tint_tail: gl.getAttribLocation(program_ribbon, 'aTintTail'),
  tint_head: gl.getAttribLocation(program_ribbon, 'aTintHead'),
};
const ribbon_uniforms = {
  mvp: gl.getUniformLocation(program_ribbon, 'uMVP'),
  eye: gl.getUniformLocation(program_ribbon, 'uEye'),
  forward: gl.getUniformLocation(program_ribbon, 'uForward'),
  depth_near: gl.getUniformLocation(program_ribbon, 'uDepthNear'),
  tangent: gl.getUniformLocation(program_ribbon, 'uTangentHalfView'),
  height: gl.getUniformLocation(program_ribbon, 'uHeightPixels'),
  fog_full: gl.getUniformLocation(program_ribbon, 'uFogFull'),
  fog_gone: gl.getUniformLocation(program_ribbon, 'uFogGone'),
};
// Six (end, side) corners of one ribbon instance, in `expandRibbon`'s own winding.
const buffer_ribbon_corners = createdBuffer();
gl.bindBuffer(gl.ARRAY_BUFFER, buffer_ribbon_corners);
gl.bufferData(gl.ARRAY_BUFFER,
  new Float32Array([0, -1, 1, -1, 1, 1, 0, -1, 1, 1, 0, 1]), gl.STATIC_DRAW);

// Fan one 13-float disc record over static corner buffer.
//   Sibling copy of `mesh.expandDiscVertex`, reference suite pins, and of GLSL 3.30
//   source in `renderer.nim`; change to any one of three is not finished until other
//   two are checked.
//   Each corner is centre plus two radius-scaled arms weighted by its own cosine and
//   sine, with `(0, 0)` landing centre corner on centre exactly.
const SOURCE_VERTEX_DISC = `
  attribute vec2 aCorner;
  attribute vec3 aCentre;
  attribute vec3 aArmFirst;
  attribute vec3 aArmSecond;
  attribute vec4 aFill;
  uniform mat4 uMVP;
  varying vec4 vColor;
  void main() {
    vec3 at = aCentre + aCorner.x*aArmFirst + aCorner.y*aArmSecond;
    gl_Position = uMVP*vec4(at, 1.0);
    vColor = aFill;
  }
`;
// Sibling copy of `mesh.expandDomeVertex`, under same three-way rule:
//   each corner is centre plus its own unit direction scaled by radius.
const SOURCE_VERTEX_DOME = `
  attribute vec3 aUnit;
  attribute vec4 aCentreRadius;
  attribute vec4 aTint;
  uniform mat4 uMVP;
  varying vec4 vColor;
  void main() {
    vec3 at = aCentreRadius.xyz + aCentreRadius.w*aUnit;
    gl_Position = uMVP*vec4(at, 1.0);
    vColor = aTint;
  }
`;
// Widen one 14-float ring record into plane's whole rim.
//   Sibling copy of `mesh.expandRingVertex`, reference suite pins, and of GLSL 3.30
//   source in `renderer.nim`; change to any one of three is not finished until other
//   two are checked.
//   Static corner buffer carries every segment of closed walk, so this one instance
//   draws all `SEGMENTS_CIRCLE_HORIZON` of them.
//   Two steps, and second is not new.
//     Place segment's ends on circle exactly as disc source places its fan corners,
//     `centre + cos*arm_first + sin*arm_second`, then widen that pair by ribbon
//     source's own body, verbatim: near clip, across join reduces to, and half width
//     of this end's world-per-pixel.
//     Rim is line, and there is one rule for how wide line is drawn.
//   Tint is flat, so ribbon's blend between two ends collapses to `aFill`, and fog is
//   always zero, so this shares plain fragment stage rather than ribbon's fading one.
const SOURCE_VERTEX_RING = `
  attribute vec4 aArc;
  attribute vec2 aCorner;
  attribute vec3 aCentre;
  attribute vec3 aArmFirst;
  attribute vec3 aArmSecond;
  attribute vec4 aFill;
  attribute float aWidth;
  uniform mat4 uMVP;
  uniform vec3 uEye;
  uniform vec3 uForward;
  uniform float uDepthNear;
  uniform float uTangentHalfView;
  uniform float uHeightPixels;
  varying vec4 vColor;
  void main() {
    vec3 tail = aCentre + aArc.x*aArmFirst + aArc.y*aArmSecond;
    vec3 head = aCentre + aArc.z*aArmFirst + aArc.w*aArmSecond;
    float depth_tail = dot(tail - uEye, uForward);
    float depth_head = dot(head - uEye, uForward);
    vec3 across_raw = cross(head - tail, uEye - tail);
    float across_length = length(across_raw);
    if (max(depth_tail, depth_head) < uDepthNear || across_length < 1e-12) {
      gl_Position = vec4(0.0, 0.0, 2.0, 1.0);
      vColor = vec4(0.0);
      return;
    }
    vec3 near_end = tail;
    vec3 far_end = head;
    if (depth_tail < uDepthNear) {
      float fraction = (uDepthNear - depth_tail)/(depth_head - depth_tail);
      near_end = tail + fraction*(head - tail);
    } else if (depth_head < uDepthNear) {
      float fraction = (uDepthNear - depth_head)/(depth_tail - depth_head);
      far_end = head + fraction*(tail - head);
    }
    vec3 across = across_raw/across_length;
    vec3 at = mix(near_end, far_end, aCorner.x);
    float depth_at = max(dot(at - uEye, uForward), uDepthNear);
    float world_per_pixel = 2.0*depth_at*uTangentHalfView/uHeightPixels;
    at += aCorner.y*0.5*aWidth*world_per_pixel*across;
    gl_Position = uMVP*vec4(at, 1.0);
    vColor = aFill;
  }
`;
function linkWashProgram(source_vertex: string): WebGLProgram {
  const handle = createdProgram();
  gl.attachShader(handle, compileShader(gl.VERTEX_SHADER, source_vertex));
  gl.attachShader(handle, compileShader(gl.FRAGMENT_SHADER, SOURCE_FRAGMENT));
  gl.linkProgram(handle);
  if (!gl.getProgramParameter(handle, gl.LINK_STATUS)) {
    throw new Error(gl.getProgramInfoLog(handle) ?? 'Program failed to link.');
  }
  return handle;
}
const program_disc = linkWashProgram(SOURCE_VERTEX_DISC);
const program_dome = linkWashProgram(SOURCE_VERTEX_DOME);
const disc_attribs = {
  corner: gl.getAttribLocation(program_disc, 'aCorner'),
  centre: gl.getAttribLocation(program_disc, 'aCentre'),
  arm_first: gl.getAttribLocation(program_disc, 'aArmFirst'),
  arm_second: gl.getAttribLocation(program_disc, 'aArmSecond'),
  fill: gl.getAttribLocation(program_disc, 'aFill'),
};
const dome_attribs = {
  unit: gl.getAttribLocation(program_dome, 'aUnit'),
  centre_radius: gl.getAttribLocation(program_dome, 'aCentreRadius'),
  tint: gl.getAttribLocation(program_dome, 'aTint'),
};
const program_ring = linkWashProgram(SOURCE_VERTEX_RING);
const ring_attribs = {
  arc: gl.getAttribLocation(program_ring, 'aArc'),
  corner: gl.getAttribLocation(program_ring, 'aCorner'),
  centre: gl.getAttribLocation(program_ring, 'aCentre'),
  arm_first: gl.getAttribLocation(program_ring, 'aArmFirst'),
  arm_second: gl.getAttribLocation(program_ring, 'aArmSecond'),
  fill: gl.getAttribLocation(program_ring, 'aFill'),
  width: gl.getAttribLocation(program_ring, 'aWidth'),
};
// Very six ribbon program takes, since widening is ribbon's own.
const ring_uniforms = {
  mvp: gl.getUniformLocation(program_ring, 'uMVP'),
  eye: gl.getUniformLocation(program_ring, 'uEye'),
  forward: gl.getUniformLocation(program_ring, 'uForward'),
  depth_near: gl.getUniformLocation(program_ring, 'uDepthNear'),
  tangent: gl.getUniformLocation(program_ring, 'uTangentHalfView'),
  height: gl.getUniformLocation(program_ring, 'uHeightPixels'),
};
const uniform_disc_mvp = gl.getUniformLocation(program_disc, 'uMVP');
const uniform_dome_mvp = gl.getUniformLocation(program_dome, 'uMVP');
// Hold static corner geometry both wash shaders fan records over.
//   Read from mesh.nim's own generators rather than hand-copied table that could drift
//   from references.
const CORNERS_DISC = new Float32Array(nimDiscCorners());
const CORNERS_DOME = new Float32Array(nimDomeCorners());
const COUNT_CORNERS_DISC = CORNERS_DISC.length / 2;
const COUNT_CORNERS_DOME = CORNERS_DOME.length / 3;
const buffer_disc_corners = createdBuffer();
gl.bindBuffer(gl.ARRAY_BUFFER, buffer_disc_corners);
gl.bufferData(gl.ARRAY_BUFFER, CORNERS_DISC, gl.STATIC_DRAW);
const buffer_dome_corners = createdBuffer();
gl.bindBuffer(gl.ARRAY_BUFFER, buffer_dome_corners);
gl.bufferData(gl.ARRAY_BUFFER, CORNERS_DOME, gl.STATIC_DRAW);
// Every segment of rim, six corners each, so one ring record draws whole circle.
const CORNERS_RING = new Float32Array(nimRingCorners());
const COUNT_CORNERS_RING = CORNERS_RING.length / 6;
const buffer_ring_corners = createdBuffer();
gl.bindBuffer(gl.ARRAY_BUFFER, buffer_ring_corners);
gl.bufferData(gl.ARRAY_BUFFER, CORNERS_RING, gl.STATIC_DRAW);
// Two triangles of unit square, one disc per point record.
const CORNERS_POINT = new Float32Array(nimPointCorners());
const COUNT_CORNERS_POINT = CORNERS_POINT.length / 2;
const buffer_point_corners = createdBuffer();
gl.bindBuffer(gl.ARRAY_BUFFER, buffer_point_corners);
gl.bufferData(gl.ARRAY_BUFFER, CORNERS_POINT, gl.STATIC_DRAW);

const vbo = {
  disc: createdBuffer(), dome: createdBuffer(), ring: createdBuffer(),
  ribbon: createdBuffer(), point: createdBuffer(),
  ribbon_furniture: createdBuffer(),
};
const STRIDE_POINT = 11 * 4;
const STRIDE_RIBBON = 16 * 4;
const STRIDE_DISC = 13 * 4;
const STRIDE_DOME = 8 * 4;
const STRIDE_RING = 14 * 4;

// Count furniture vertices its own buffer holds, carried between frames.
//   Bridge stops sending them once camera is still; see `renderFrame`.
let count_furniture_held = 0;
// And same for scene's own buffers, carried for same reason one layer out:
//   frame bridge reports as held has uploaded nothing, so what stands in each buffer is last
//   frame's -- correct, since bridge only says held when it would have written very same bytes.
//   See `FrameData.is_scene_held`.
let count_ribbon_held = 0;
let count_ring_held = 0;
let count_point_held = 0;

// One mesh handed to driver whole, ready to be drawn as one run or two.
//   Separate from drawing because two runs go out in different passes (see draw loop below), and
//   mesh uploaded twice frame would be one real cost of that split.
//   Bridge fills `Float32Array`s page owns and hands back views on them, so there is
//   nothing to convert here and nothing to stage: driver reads very memory
//   flatten wrote. Staging array used to sit here, refilled element by element from
//   boxed `Array` `seq[float32]` is on JS backend -- see `browser_bridge.FlatBuffer`
//   for what that cost and why it is gone. Anything else reaching this is mistake worth
//   hearing about rather than silently copying around.
// Read attribute layout literal as triples of location, float count and byte offset.
//   Array literal alone infers as list of unknown length, whose every read is possibly
//   absent; this states shape once rather than guarding each read.
function ATTRIBUTE_LAYOUT(rows: Array<[number, number, number]>): Array<[number, number, number]> {
  return rows;
}


function uploadBuffer(data: Float32Array, handle_buffer: WebGLBuffer, floats_each: number) {
  if (!(data instanceof Float32Array)) {
    throw new Error('uploadBuffer wants a Float32Array from the bridge, not ' + typeof data);
  }
  // Empty buffer uploads nothing and draws nothing, which zero says outright;
  //   `null` said same thing only by coercing to zero wherever count was used.
  if (data.length === 0) return 0;
  gl.bindBuffer(gl.ARRAY_BUFFER, handle_buffer);
  gl.bufferData(gl.ARRAY_BUFFER, data, gl.DYNAMIC_DRAW);
  return data.length / floats_each;
}

// One run of uploaded record buffer, drawn as instanced triangle pairs.
//   `count_over` is how many records at END are overlay run, exactly as `drawPoints`'s split;
//   run that does not start at first record re-points five instance attributes at its own first
//   byte, since WebGL1 has no base instance.
//   Mirrors `renderer.drawRibbonRun`.
function drawRibbons(
  handle_buffer: WebGLBuffer, count: number, count_over: number, is_overlay: boolean,
) {
  if (!count) return;
  const split = Math.max(0, count - Math.min(count_over || 0, count));
  const first = is_overlay ? split : 0;
  const span = is_overlay ? count - split : split;
  if (span === 0) return;
  gl.bindBuffer(gl.ARRAY_BUFFER, buffer_ribbon_corners);
  gl.enableVertexAttribArray(ribbon_attribs.corner);
  gl.vertexAttribPointer(ribbon_attribs.corner, 2, gl.FLOAT, false, 8, 0);
  instanced.vertexAttribDivisorANGLE(ribbon_attribs.corner, 0);
  gl.bindBuffer(gl.ARRAY_BUFFER, handle_buffer);
  const base = first * STRIDE_RIBBON;
  for (const [attrib, floats, offset] of ATTRIBUTE_LAYOUT([
    [ribbon_attribs.tail, 3, 0], [ribbon_attribs.head, 3, 12], [ribbon_attribs.width, 1, 24],
    [ribbon_attribs.fog, 1, 28],
    [ribbon_attribs.tint_tail, 4, 32], [ribbon_attribs.tint_head, 4, 48],
  ])) {
    gl.enableVertexAttribArray(attrib);
    gl.vertexAttribPointer(attrib, floats, gl.FLOAT, false, STRIDE_RIBBON, base + offset);
    instanced.vertexAttribDivisorANGLE(attrib, 1);
  }
  instanced.drawArraysInstancedANGLE(gl.TRIANGLES, 0, 6, span);
  // Divisors are context state, not program state: left at one they would corrupt.
  //   plain program's reads of these same attribute indices next draw.
  for (const attrib of [ribbon_attribs.tail, ribbon_attribs.head, ribbon_attribs.width,
    ribbon_attribs.fog, ribbon_attribs.tint_tail, ribbon_attribs.tint_head]) {
    instanced.vertexAttribDivisorANGLE(attrib, 0);
    gl.disableVertexAttribArray(attrib);
  }
}

// One run of uploaded ring buffer, drawn as instanced rims:
//   each instance is whole plane's circle, `COUNT_CORNERS_RING` corners of it.
//   Splits its two runs exactly as `drawRibbons` does, and re-points five instance attributes at
//   run's own first byte for same reason -- WebGL1 has no base instance.
//   Mirrors `renderer.drawRingRun`.
function drawRings(count: number, count_over: number, is_overlay: boolean) {
  if (!count) return;
  const split = Math.max(0, count - Math.min(count_over || 0, count));
  const first = is_overlay ? split : 0;
  const span = is_overlay ? count - split : split;
  if (span === 0) return;
  gl.bindBuffer(gl.ARRAY_BUFFER, buffer_ring_corners);
  for (const [attrib, floats, offset] of ATTRIBUTE_LAYOUT([
    [ring_attribs.arc, 4, 0], [ring_attribs.corner, 2, 16],
  ])) {
    gl.enableVertexAttribArray(attrib);
    gl.vertexAttribPointer(attrib, floats, gl.FLOAT, false, 24, offset);
    instanced.vertexAttribDivisorANGLE(attrib, 0);
  }
  gl.bindBuffer(gl.ARRAY_BUFFER, vbo.ring);
  const base = first * STRIDE_RING;
  const records: Array<[number, number, number]> = [
    [ring_attribs.centre, 3, 0], [ring_attribs.arm_first, 3, 12],
    [ring_attribs.arm_second, 3, 24], [ring_attribs.fill, 4, 36],
    [ring_attribs.width, 1, 52],
  ];
  for (const [attrib, floats, offset] of records) {
    gl.enableVertexAttribArray(attrib);
    gl.vertexAttribPointer(attrib, floats, gl.FLOAT, false, STRIDE_RING, base + offset);
    instanced.vertexAttribDivisorANGLE(attrib, 1);
  }
  instanced.drawArraysInstancedANGLE(gl.TRIANGLES, 0, COUNT_CORNERS_RING, span);
  // Divisors are context state, not program state: left at one they would corrupt.
  //   plain program's reads of these same attribute indices next draw.
  for (const [attrib] of records) {
    instanced.vertexAttribDivisorANGLE(attrib, 0);
    gl.disableVertexAttribArray(attrib);
  }
  for (const attrib of [ring_attribs.arc, ring_attribs.corner]) {
    gl.disableVertexAttribArray(attrib);
  }
}

// One instanced wash draw:
//   `record_attribs` re-pointed at run's first record (WebGL1 has no base instance), corner attrib
//   from static buffer, divisors reset after -- they are context state, and left at one they would
//   corrupt plain program's reads of same attribute indices.
//   Shared by disc and dome runs below.
function drawWashInstances(
  buffer_corners: WebGLBuffer, floats_corner: number, count_corners: number,
  corner_attrib: number, handle_records: WebGLBuffer, stride: number,
  record_attribs: Array<[number, number, number]>, first: number, count: number,
) {
  gl.bindBuffer(gl.ARRAY_BUFFER, buffer_corners);
  gl.enableVertexAttribArray(corner_attrib);
  gl.vertexAttribPointer(corner_attrib, floats_corner, gl.FLOAT, false,
    floats_corner * 4, 0);
  instanced.vertexAttribDivisorANGLE(corner_attrib, 0);
  gl.bindBuffer(gl.ARRAY_BUFFER, handle_records);
  const base = first * stride;
  for (const [attrib, floats, offset] of record_attribs) {
    gl.enableVertexAttribArray(attrib);
    gl.vertexAttribPointer(attrib, floats, gl.FLOAT, false, stride, base + offset);
    instanced.vertexAttribDivisorANGLE(attrib, 1);
  }
  instanced.drawArraysInstancedANGLE(gl.TRIANGLES, 0, count_corners, count);
  for (const [attrib] of record_attribs) {
    instanced.vertexAttribDivisorANGLE(attrib, 0);
    gl.disableVertexAttribArray(attrib);
  }
}

// Walk one pass's stretch of wash draw order, drawing each run through its kind's program.
//   `wash_runs` is [kind, first, count] per run, `count_runs_over` how many runs at end
//   are overlay stretch.
//   Two washes then still blend in order scene emitted them; mirrors
//   `renderer.drawWashRuns`.
function drawWashRuns(
  wash_runs: Float32Array, count_runs_over: number, is_overlay: boolean,
) {
  const count_runs = wash_runs.length / 3;
  const split = count_runs - Math.min(count_runs_over || 0, count_runs);
  const begin = is_overlay ? split : 0;
  const end = is_overlay ? count_runs : split;
  for (let i = begin; i < end; i += 1) {
    const kind = wash_runs[3 * i] ?? 0;
    const first = wash_runs[3 * i + 1] ?? 0;
    const count = wash_runs[3 * i + 2] ?? 0;
    if (kind === 0) {
      gl.useProgram(program_disc);
      drawWashInstances(buffer_disc_corners, 2, COUNT_CORNERS_DISC, disc_attribs.corner,
        vbo.disc, STRIDE_DISC, ATTRIBUTE_LAYOUT([
          [disc_attribs.centre, 3, 0], [disc_attribs.arm_first, 3, 12],
          [disc_attribs.arm_second, 3, 24], [disc_attribs.fill, 4, 36],
        ]), first, count);
    } else {
      gl.useProgram(program_dome);
      drawWashInstances(buffer_dome_corners, 3, COUNT_CORNERS_DOME, dome_attribs.unit,
        vbo.dome, STRIDE_DOME, ATTRIBUTE_LAYOUT([
          [dome_attribs.centre_radius, 4, 0], [dome_attribs.tint, 4, 16],
        ]), first, count);
    }
  }
}

// One run of uploaded point records, drawn as instanced camera-facing discs.
//   `count_over` is how many records at END are overlay run; `is_overlay` picks which of
//   two runs to draw. Re-points three instance attributes at run's own first byte, since
//   WebGL1 has no base instance, and resets divisors after, as `drawRings` does.
//   Mirrors `renderer.drawPointRun`.
function drawPoints(count: number, count_over: number, is_overlay: boolean) {
  if (!count) return;
  const split = Math.max(0, count - Math.min(count_over || 0, count));
  const first = is_overlay ? split : 0;
  const span = is_overlay ? count - split : split;
  if (span === 0) return;
  gl.bindBuffer(gl.ARRAY_BUFFER, buffer_point_corners);
  gl.enableVertexAttribArray(point_attribs.corner);
  gl.vertexAttribPointer(point_attribs.corner, 2, gl.FLOAT, false, 8, 0);
  instanced.vertexAttribDivisorANGLE(point_attribs.corner, 0);
  gl.bindBuffer(gl.ARRAY_BUFFER, vbo.point);
  const base = first * STRIDE_POINT;
  const records: Array<[number, number, number]> = [
    [point_attribs.centre, 3, 0], [point_attribs.radius, 1, 12], [point_attribs.light, 3, 16],
    [point_attribs.colour, 4, 28],
  ];
  for (const [attrib, floats, offset] of records) {
    gl.enableVertexAttribArray(attrib);
    gl.vertexAttribPointer(attrib, floats, gl.FLOAT, false, STRIDE_POINT, base + offset);
    instanced.vertexAttribDivisorANGLE(attrib, 1);
  }
  instanced.drawArraysInstancedANGLE(gl.TRIANGLE_STRIP, 0, COUNT_CORNERS_POINT, span);
  for (const [attrib] of records) {
    instanced.vertexAttribDivisorANGLE(attrib, 0);
    gl.disableVertexAttribArray(attrib);
  }
  gl.disableVertexAttribArray(point_attribs.corner);
}

function rgbToCss(rgb: number[]) {
  const byteOf = (c: number) =>
    Math.round(Math.min(1, Math.max(0, c)) * 255).toString(16).padStart(2, '0');
  return '#' + rgb.map(byteOf).join('');
}

gl.enable(gl.DEPTH_TEST);
gl.enable(gl.BLEND);
gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);
const backdrop = nimBackdropColor();
gl.clearColor(backdrop[0] ?? 0, backdrop[1] ?? 0, backdrop[2] ?? 0, 1.0);
document.documentElement.style.setProperty('--bg', rgbToCss(backdrop));
