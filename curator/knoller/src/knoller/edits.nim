## Edit source by byte span, as fixers resting on semantic pass plan it (`conversions.nim`).
##   Edit replaces byte span of source as given, or inserts where span is empty. Edits never
##     overlap, but insertions may share offset; rank orders them, lower first, so wrapper
##     planned outside another opens before it (`int(float(x))`).

{.experimental: "strictFuncs".}

import std/algorithm


type Edit* = object  ## Define one edit: byte span of source as given, text replacing it, rank.
  first*: int  ## Byte offset span opens at.
  after*: int  ## Byte offset after span; equal to `first` for insertion.
  text*: string
  rank*: int  ## Order among insertions at one offset: lower first.


func applied*(source: string, edits: openArray[Edit]): string =
  ## Apply edits to source, last first, so earlier offsets hold; insertions at one offset in
  ##   rank order.
  result = source
  for edit in edits.sortedByIt((-it.first, -(it.after - it.first), -it.rank)):
    result = result[0 ..< edit.first] & edit.text & result[edit.after .. ^1]


func isTouching*(a, b: Edit): bool =
  ## Decide whether two edits write one byte, or one inserts strictly inside other's span.
  if a.first == a.after: b.first < a.first and a.first < b.after
  elif b.first == b.after: a.first < b.first and b.first < a.after
  else: a.first < b.after and b.first < a.after
