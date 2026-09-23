discard """
action: run
targets: "js"
cmd: "nim $target --hints:off -d:testing -d:nodejs -d:nimUnittestAbortOnError:on $options $file"
batchable: true
joinable: false
"""
## Hold prose browser writes to same two rules as prose written into markup.
##   Reference and rig viewer build their pages in browser, so no page on disk
##     carries their sentences and `tmarks` cannot read them.  Gap was recorded
##     rather than closed, and Reference held nine sentences and two paragraphs
##     past bounds when this first ran.
##   Two shapes, because two pages are built two ways.  Reference builds markup
##     in pure functions that return it, so law calls them and reads what they
##     return: law runs where mechanism runs (Article IX.5).  Viewer writes its
##     sentences straight into elements, so they are held in one table
##     (`rig_view.VERDICTS`) that law reads instead.
##   Neither needs browser: nothing called here touches document.
##   Runs on JS target alone, because both pages import `std/dom`.

import std/[options, unittest]

import ../design/plain
import ../design/rig_view
import ../app/app {.all.}
import ../src/dance_ontology


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


suite "the Reference says its prose in few words":
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


suite "the rig viewer says its prose in few words":
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
