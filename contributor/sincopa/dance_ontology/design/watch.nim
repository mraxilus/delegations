## Watch stills that C cards show, which Architect left standing: report each move, judge none.
##
##   Architect kept C01 to C07 at first look, unconfirmed, and asked that they stay as they
##     stand (issue 611).  Every law of simulation holds their moments as it holds every other,
##     with no exception; watch says only where one has moved.
##   Fixture is every capsule end of still each watched card shows, as page shows it, to tenth
##     of millimetre (`design/twins.stillsShown`).  Twin card shows still it names, mirrored,
##     so which still that is comes from recording, never from here.
##     Cost: still two watched cards show is written twice, as itself and mirrored.  Accepted
##       -- card that comes to show other still then moves, and watch says so.
##   Card whose still holds no pose is written with no capsule, so verb records that too.
##   Fixture is written by `tools/build.nim watched`, by hand, in pull request that moves those
##     stills, so its diff shows each end before and after.  Never run to quiet watch.
##     Cost: one more fixture written by hand.  Accepted -- writing it again is whole answer to
##       move, so watch never blocks fix, and no move goes unseen.

{.experimental: "strictFuncs".}

import std/[json, os, strutils]

import ./twins


const
  WATCHED* = ["C01", "C02", "C03", "C04", "C05", "C06", "C07"]
    ## Cards watched: those Architect left standing (issue 611).
  KEPT_WATCHED* = currentSourcePath().parentDir / "watched-fixtures.json"
    ## Where fixture is kept, beside recording it is written from.
  MOVE_WATCHED* = 0.001
    ## Metres capsule end of watched still may move and pass unreported (issue 611).


func watchedIn*(recording: JsonNode): string =
  ## Write fixture of still each watched card shows, from rig recording, as page shows it: each
  ## card by name, one capsule to line, as `[who, arm, mark, a x, a y, a z, z x, z y, z z]`.
  ##   Card whose still holds no pose is written with no capsule.
  let shown = stillsShown(recording)
  var cards: seq[string]
  for card in WATCHED:
    var capsules: seq[string]
    for still in shown:
      if still["key"].getStr != card or not still.hasKey("points"): continue
      let points = still["points"][0]
      for i, tag in still["tag"].getElems:
        var figures: seq[string]
        for figure in tag: figures.add $figure.getInt
        for k in 0..5: figures.add $points[6*i+k].getFloat
        capsules.add "    [" & figures.join(", ") & "]"
    cards.add "  \"" & card & "\": [" &
        (if capsules.len == 0: "]" else: "\n" & capsules.join(",\n") & "\n  ]")
  "{\n" & cards.join(",\n") & "\n}\n"
