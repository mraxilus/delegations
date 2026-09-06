## Light every point from nearest point that shines.
##
## Sun is item whose `shines` is set; see `scene.shinesAt`. Absence is `mesh.LIGHT_NONE`.
##   Planet and moon take light from nearest sun, in direction from body to sun; sun
##   itself, and scene with no sun, take no light and draw flat.
##   Nearest rather than brightest: catalogue carries no luminosities, and system's own
##   star is nearest to its planets by hundred to one.
## Lights depend on positions alone, never on camera, so both front-ends refresh them only
## where scene's revision moved, beside placements, and only as far as edit reached; see
## `LightCache`, `browser_bridge.ensurePlaced` and `visualiser.renderFrame`.
##
## Shared between desktop (`visualiser.nim`) and browser (`browser_bridge.nim`) render
## paths; see `visualiser.nim`'s "Render Paths" table.

{.experimental: "strictFuncs".}

import std/[math, options]

import pga
import ./[boundary, tessellate, scene]



#[ Lighting ]#

func lightToward*(place: Position, suns: openArray[Position], count: int): Direction =
  ## Report unit direction from `place` toward nearest of first `count` suns.
  ##   `LIGHT_NONE` where there is no sun, or where nearest stands exactly on `place`.
  ##   Components rather than `Direction` arithmetic per sun: allocation per candidate on
  ##   JS backend (Art. VII.1).
  var
    nearest_squared = Inf
    dx, dy, dz = 0.0
  for index in 0 ..< count:
    let
      ox = suns[index].x - place.x
      oy = suns[index].y - place.y
      oz = suns[index].z - place.z
      squared = ox*ox + oy*oy + oz*oz
    if squared < nearest_squared:
      nearest_squared = squared
      dx = ox
      dy = oy
      dz = oz
  if nearest_squared == Inf or nearest_squared <= 0.0: return LIGHT_NONE
  let length = sqrt(nearest_squared)
  Direction(x: dx/length, y: dy/length, z: dz/length)


type LightCache* = object ## Hold every slot's light, and suns it was computed from.
  ## Refreshed once per scene revision, and only as far as edit reaches: sun that moved
  ## or appeared relights everything, planet that moved relights itself alone.
  ##   Suns times points is 1.6 million distances at largest demo, and every add paid it
  ##   until this held frame after edit at 17.8 ms against its 15 ms pin.
  lights*: array[ITEMS_MAX, Direction] ## Per-slot direction toward its sun; see `lightToward`.
  suns: array[ITEMS_MAX, Position] ## Suns last refresh lit from, in slot order.
  count_suns: int ## How many of `suns` are filled.


func gatherSuns(
  scene: Scene, placed: openArray[Placed], suns: var array[ITEMS_MAX, Position]
): int =
  ## Fill `suns` with every visible shining point's place; report how many.
  result = 0
  for slot in 0 ..< scene.bound:
    if not scene.isAlive(slot) or not scene.isVisible(slot): continue
    if scene.shinesAt(slot) and placed[slot].kind == PlacedKind.PointAt:
      suns[result] = placed[slot].at
      inc result


func areSunsHeld(cache: LightCache, suns: array[ITEMS_MAX, Position], count: int): bool =
  ## Report whether suns gathered now are exactly ones cache lit from.
  ##   Exact comparison: same floats out of same placements, so any edit reads unequal.
  if count != cache.count_suns: return false
  for index in 0 ..< count:
    if suns[index].x != cache.suns[index].x or suns[index].y != cache.suns[index].y or
        suns[index].z != cache.suns[index].z:
      return false
  true


func refreshLights*(
  cache: var LightCache, scene: Scene, placed: openArray[Placed],
  revision_since: Option[int]
) =
  ## Bring `cache.lights` up to scene, from frame's own placements.
  ##   `revision_since` is placing revision cache was last refreshed at; none relights
  ##   everything, as does any change among suns. Otherwise only slots placed since are
  ##   relit, same rule `browser_bridge.ensurePlaced` re-places by.
  ##   Sibling of `refreshLights(cache, scene, revision_since)`, which places for itself.
  var suns: array[ITEMS_MAX, Position]
  let count_suns = gatherSuns(scene, placed, suns)
  let is_whole = revision_since.isNone or not cache.areSunsHeld(suns, count_suns)
  cache.suns = suns
  cache.count_suns = count_suns
  for slot in 0 ..< scene.bound:
    if not scene.isAlive(slot): continue
    if not is_whole and scene.revisionPlacingAt(slot) <= revision_since.get: continue
    cache.lights[slot] =
      if scene.shinesAt(slot) or placed[slot].kind != PlacedKind.PointAt: LIGHT_NONE
      else: lightToward(placed[slot].at, suns, count_suns)


proc refreshLights*(cache: var LightCache, scene: Scene, revision_since: Option[int]) =
  ## Bring `cache.lights` up to scene, placing every item first; desktop path.
  ##   Sibling of `refreshLights(cache, scene, placed, revision_since)`.
  var placed: array[ITEMS_MAX, Placed]
  for slot in 0 ..< scene.bound:
    if scene.isAlive(slot):
      placed[slot] = placeObject(scene.geometryOf(slot), scene.anchorOverrideAt(slot))
  refreshLights(cache, scene, placed, revision_since)
