## Measure scalars and vectors in drawing's own conventions.
##
##   Bearings run clockwise from straight up page, because that is how
##     pictures are read; y grows downward, as SVG's does.
##   Number is written with one decimal and no negative zero, so two poses
##     that are same pose emit same markup.
##     Cost of one decimal: two points less than one twentieth apart write as
##       one point.  Accepted -- at drawing scale that distance says nothing.

{.experimental: "strictFuncs".}

import std/[math, strutils]


type Point* = tuple ## Position on page, in SVG's own axes.
  x, y: float


func n*(v: float): string =
  ## Write one decimal and no negative zero, i.e. `-0.04` comes out as `0`.
  ##   Two poses that are same pose must emit same markup, not `0`
  ##     against `-0`.
  let written = formatFloat(v, ffDecimal, 1)
  if written in ["0.0", "-0.0"]:
    return "0"
  written.strip(leading = false, chars = {'0'})
         .strip(leading = false, chars = {'.'})

func n*(v: int): string = $v
  ## Write whole number as itself; only floats carry decimal machinery.


func xy*(p: Point): string = n(p.x) & " " & n(p.y)
  ## Write point as SVG path data expects it.


func polar*(cx, cy, radius, degrees: float): Point =
  ## Get point at bearing, measured clockwise from straight up page.
  let rad = degToRad(degrees)
  (cx + radius * sin(rad), cy - radius * cos(rad))


func bearing*(dx, dy: float): float =
  ## Get bearing of vector, in same clockwise-from-up convention.
  radToDeg(arctan2(dx, -dy))


func dist*(a, b: Point): float =
  ## Get straight distance between two points.
  sqrt((a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y))


func wrap180*(degrees: float): float =
  ## Take angle short way round, into (-180, 180].
  floorMod(degrees + 180.0, 360.0) - 180.0


func continuous*(angles: seq[float]): seq[float] =
  ## Say same turning without jump in it.
  ##   Each angle is taken short way from one before, so sequence
  ##     handed to animation is monotonic through half turn instead of
  ##     stepping from 179 to -179.
  ##     Anything interpolating between two frames reads that step as most of
  ##       one turn backwards, and draws body spinning wrong way.
  result = @[wrap180(angles[0])]
  for a in angles[1 .. ^1]:
    result.add result[^1] + wrap180(a - result[^1])


func turn*(point, about: Point; degrees: float): Point =
  ## Rotate point about another, clockwise on page.
  let
    rad = degToRad(degrees)
    (dx, dy) = (point.x - about.x, point.y - about.y)
  (about.x + dx * cos(rad) - dy * sin(rad),
   about.y + dx * sin(rad) + dy * cos(rad))
