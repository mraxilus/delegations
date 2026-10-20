discard """
action: run
targets: "js"
cmd: "nim $target --hints:off -d:testing -d:nodejs -d:nimUnittestAbortOnError:on $options $file"
"""
## Hold prose browser writes to same two rules as prose written into markup.
##   Reference and rig viewer build their pages in browser, so no page on disk
##     carries their sentences and `test_marks` cannot read them.  Gap was recorded
##     rather than closed, and Reference held nine sentences and two paragraphs
##     past bounds when this first ran.
##   Two shapes, because two pages are built two ways.  Reference builds markup
##     in pure functions that return it, so law calls them and reads what they
##     return: law runs where mechanism runs (Article IX.5).  Viewer writes its
##     sentences straight into elements, so they are held in one table
##     (`rig_view.VERDICTS`) that law reads instead.
##   Neither needs browser: nothing called here touches document.
##   Runs on JS target alone, because both pages import `std/dom`.
##   Also holds what viewer says of where couple stand to recording it plays: its line is
##     built from recording (`rig_view.where`), so law reads recording itself, through node.

{.experimental: "strictFuncs".}

when compileOption("profiler"): import std/nimprof

import std/[jsffi, math, options, os, strutils, unittest]

import ../design/[plain, rig_view]
from ../design/rig_view {.all.} import toFixed, where
import ../app/app {.all.}
import ../src/dance_ontology


const
  KEPT_RIG = currentSourcePath().parentDir.parentDir / "design" / "rig.json"
    ## Recording viewer plays (`design/rig.KEPT_RIG`), read where this file was compiled.
  FLOOR_MOMENTS = 394
    ## Least moments read: half of 788, every still's and sweep's, read 2026-10-12.  Reader that
    ##   loses its way, by wrong file or wrong keys, reads nearly none.


proc readText(path: cstring): cstring {.importjs: "require('fs').readFileSync(#, 'utf8')".}
  ## Read whole file as text, through node.
func parsed(text: cstring): JsObject {.importjs: "JSON.parse(#)".}
  ## Read JSON text as object, read in place as viewer reads it.


func pages(): seq[(string, string)] =
  ## Every markup Reference builds, named, over states that carry its prose.
  let
    start = startFrame()
    still = default(Motion)
  result.add ("key", renderKey())
  result.add ("arms", renderArms())
  result.add ("marks", renderMarks())
  result.add ("matrix", renderMatrix())
  result.add ("gallery", renderGallery(default(Filter)))
  result.add ("filters", renderFilters(default(Filter)))
  result.add ("spokes", renderSpokesView(start, still, none(Frame)))
  result.add ("map", renderMapView(start, still, none(Frame)))
  result.add ("moves", renderMoves(start))
  result.add ("elsewhere", renderElsewhere(start))
  for view in View:
    result.add ("controls " & $view, renderControls(view))



suite "Internal: The Reference says its prose in few words":
  let built = pages()


  test "every view builds prose to read":
    # Laws below say nothing about markup that holds no paragraph.
    check built.len > 0
    var paragraphs = 0
    for (_, markup) in built:
      paragraphs += markup.prose.len
    check paragraphs > 0


  test "no sentence runs past the bound":
    for (name, markup) in built:
      for said in markup.longSentences:
        checkpoint name & ": " & said
        fail()


  test "no paragraph runs past the bound":
    for (name, markup) in built:
      for said in markup.longParagraphs:
        checkpoint name & ", opening: " & said
        fail()



suite "Internal: The rig viewer says its prose in few words":
  test "every verdict is one paragraph inside both bounds":
    # Viewer writes each verdict into element rather than into markup, so each
    # one stands as its own paragraph.
    for said in VERDICTS:
      let markup = "<p>" & said & "</p>"
      for long in markup.longSentences:
        checkpoint "sentence: " & long
        fail()
      for long in markup.longParagraphs:
        checkpoint "paragraph, opening: " & long
        fail()



suite "Internal: The rig viewer says where couple stand":
  test "every moment of every entry says how far apart couple stand at that moment":
    ## Viewer's line of where couple stand (`rig_view.where`) names metres between two dancers'
    ##   axes at moment shown, to two places, as recording has each stand there (`faces`).
    ##   Walk keeps one distance through sweep, and planned sweep moves couple as plan has them.
    ##   Domain: every moment of every entry of rig's recording, stills and sweeps; still that
    ##     holds no pose keeps no moment, and says so instead.
    ##   Regression of pull request 629, as found on 2026-10-12 in review of `cd9ec9a8`: viewer
    ##     said 0.96 m at every moment of `Chain, cross name · above`, where couple stand 0.37 to
    ##     1.18 m apart, and 0.42 m for `Chain, same name · above`, where they stand 0.36 to
    ##     1.00 m apart.
    let kept = parsed(readText(cstring(KEPT_RIG)))
    var
      wrong: seq[string]
      read = 0
    for kind in ["stills", "sweeps"]:
      let entries = kept[cstring(kind)]
      for i in 0..<entries.length.to(int):
        let entry = entries[i]
        if isUndefined(entry.at): continue
        let name = (if kind == "stills": $entry.key.to(cstring)
                    else: $entry.hold.to(cstring) & " · " & $entry.band.to(cstring))
        for at in 0..<entry.at.length.to(int):
          inc read
          let
            look = entry.faces[at]
            apart = hypot(look[4].to(float) - look[0].to(float),
                          look[5].to(float) - look[1].to(float))
            said = $where(entry, at)
            meant = "stood <b>" & $toFixed(apart, 2) & "</b> m apart"
          if meant notin said: wrong.add name & " moment " & $at
    checkpoint "Moments read: `" & $read & "`.  Wrong distance: `" & $wrong.len & "`, from: `" &
        wrong[0 ..< min(wrong.len, 6)].join(", ") & "`."
    check read >= FLOOR_MOMENTS
    check wrong.len == 0
