## Demand each file of gated kind argue for itself in its header (CONTRIBUTOR.md Language).
##   Owner admits TypeScript where JavaScript is forced, and C++ or C where no Nim import
##   expresses library. That gate lived in prose alone: registry admitted `.ts` on extension
##   and asked nothing, so "only where unavoidable" bound nobody. Check reads gate instead.
##
##   Rule is marker in header: `MARKER` must appear in comment block opening file. Marker is
##     phrase rather than tag, so justification reads as sentence and cannot be satisfied by
##     empty ceremony; what follows it is argument, which only review can weigh.
##   Header is first run of comments in file, gaps of one line allowed, so `#pragma once`
##     before block and blank line inside it both keep run whole.
##
##   Rejected: marker anywhere in file, which admits argument buried at line 900; marker on
##     line 1 exactly, which forbids include guard above header; separate register of
##     justified files, second place truth lives, drifting from files it describes.
##   Cost: check proves justification exists and is stated where reader looks, never that it
##     is true; curator reading pull request weighs claim, as with every rejected-alternative
##     note.
##   Cost: run tolerating one-line gap can reach comment on first code line, so marker there
##     passes; laxity is deliberate, since alternative is finding on correct header.

{.experimental: "strictFuncs".}

import std/strutils
import ./[findings, kinds, comments]


const
  MARKER* = "not Nim because"
    ## Phrase header of gated file must carry, followed by its reason.
  GAP_MAX = 2
    ## Widest line step keeping header run whole; `2` admits one blank line.


func header*(found: seq[Comment]): string =
  ## Join text of comment block opening file, i.e. run from first comment until gap.
  if found.len == 0: return ""
  var texts = @[found[0].text]
  for i in 1 ..< found.len:
    if found[i].line - found[i - 1].line > GAP_MAX: break
    texts.add found[i].text
  texts.join(" ")


func checkJustification*(path, source: string, rule: KindRule): seq[Finding] =
  ## Report file of gated kind whose header carries no justification marker.
  if not rule.is_gated: return
  if MARKER in comments(source, rule.syntax).header: return
  result.add finding(
    path, 1,
    "Gated language needs justification in header, as `" & MARKER & " <reason>`; got " &
      "nothing.",
  )
