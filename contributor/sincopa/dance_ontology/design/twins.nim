## Each still as rig page shows it: reflected twin card shows still its mirror twin keeps,
## mirrored across couple's line, each arm recoloured as arm of other side.
##
##   Recording keeps each answered still once (`design/rig`).  Twin card keeps none of its
##     own: it names card whose still it mirrors (`mirror`).  Where no card asks that answer,
##     twin card keeps answered still itself, and names itself.
##   Mirror flips every point's x, which is across couple's line, and every turn's sign.
##     Each arm's capsules keep their place and take other arm's name, so page paints them
##     in other arm's colour.  Each arm's readings move to other arm's place, so readout keeps
##     its order, and twist and its two ends turn other way, as rig states left arm's ends
##     mirrored (`rigid.twistEnds`).
##   One place to say so, read by page (`design/rig_page`) and by laws that read stills
##     (`suites/test_asks.nim`), so what laws hold is what page shows.
##   Joined hands keep their order: page draws each as dot, and laws find each arm by name.
##     Strain each pose tried keeps answered still's order.

{.experimental: "strictFuncs".}

import std/json


const ARM_MARKS = ["upper", "fore", "palm", "girdle"]
  ## Marks of capsule that belongs to one arm, so mirror names it as other arm's.

func negated(figure: JsonNode): JsonNode =
  ## Figure turned other sign, written as recording writes it: whole number stays whole.
  if figure.kind == JInt: %(-figure.getInt) else: %(-figure.getFloat)

func flipped(rows: JsonNode, every: int, places: openArray[int]): JsonNode =
  ## Each row with figures at `places` of each group of `every` turned other sign.
  result = newJArray()
  for row in rows:
    var moment = newJArray()
    for k, figure in row.getElems:
      moment.add (if k mod every in places: negated(figure) else: figure)
    result.add moment

func mirrored*(kept: JsonNode, key: string, marks, dofs: seq[string]): JsonNode =
  ## Still `kept` seen in mirror across couple's line, under card `key`, each arm recoloured.
  ##   `marks` and `dofs` are recording's own names, so mirror reads which capsule is arm's
  ##     and which reading is twist from recording itself.
  result = kept.copy
  result["key"] = %key
  result["hold"] = %key
  if result.hasKey("mirror"): result.delete("mirror")
  result["turns"] = negated(kept["turns"])
  if kept["why"].getStr != "None":
    result["whose"] = %[kept["whose"][0].getInt, 1 - kept["whose"][1].getInt]
  if not kept.hasKey("at"): return
  var tag = newJArray()
  for owner in kept["tag"]:
    let (who, arm, mark) = (owner[0].getInt, owner[1].getInt, owner[2].getInt)
    tag.add %[who, (if marks[mark] in ARM_MARKS: 1 - arm else: arm), mark]
  result["tag"] = tag
  result["points"] = flipped(kept["points"], 3, [0])
  result["grips"] = flipped(kept["grips"], 3, [0])
  result["faces"] = flipped(kept["faces"], 2, [0])
  var at = newJArray()
  for turned in kept["at"]: at.add negated(turned)
  result["at"] = at
  # Readings, arm by arm: each place reads arm of other side, twist turned other way.
  let
    twist = dofs.find("twist")
    arms = kept["arm"].getElems
  var image: seq[int]  ## Place of each arm's other side, in `arm`.
  for owner in arms:
    for j, other in arms:
      if other[0].getInt == owner[0].getInt and other[1].getInt == 1 - owner[1].getInt:
        image.add j
  var
    lower = newJArray()
    upper = newJArray()
  for i in 0..<arms.len:
    for dof in 0..<dofs.len:
      let k = image[i] * dofs.len + dof
      if dof == twist:
        lower.add negated(kept["upper"][k])
        upper.add negated(kept["lower"][k])
      else:
        lower.add kept["lower"][k]
        upper.add kept["upper"][k]
  result["lower"] = lower
  result["upper"] = upper
  var angles = newJArray()
  for row in kept["angles"]:
    var moment = newJArray()
    for i in 0..<arms.len:
      for dof in 0..<dofs.len:
        let figure = row[image[i] * dofs.len + dof]
        moment.add (if dof == twist: negated(figure) else: figure)
    angles.add moment
  result["angles"] = angles

func stillsShown*(recording: JsonNode): seq[JsonNode] =
  ## Every still of recording as page shows it, twin card as still it names, mirrored.
  var marks, dofs: seq[string]
  for name in recording["marks"]: marks.add name.getStr
  for name in recording["dofs"]: dofs.add name.getStr
  let stills = recording["stills"].getElems
  for still in stills:
    if not still.hasKey("mirror"):
      result.add still
      continue
    let named = still["mirror"].getStr
    var kept = still
    for other in stills:
      if other["key"].getStr == named: kept = other
    doAssert kept.hasKey("turns"), "Twin card names no still it can mirror; got `" & named & "`."
    result.add mirrored(kept, still["key"].getStr, marks, dofs)
