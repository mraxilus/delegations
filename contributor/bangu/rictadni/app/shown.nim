## Read what tag page shows from answer of `sample`, or from run of `suggester --serve`: tiles,
##   command of `tagger`, report and status; no element of page is touched here.
##   Tiles come from verdicts `readAnswer` keeps, so page shows gismu reader kept, each once, in
##     order, as `gismu` of `suggestions.nim` prints them; report is never read back (II.9).
##   Run of server gives tiles from gismu child printed, one to line, with no gloss: child prints
##     none, and report holds each.
##     Cost: served tiles carry no gloss; report beside them names each.
##
##   |-----------------|-----------------------------------------------------------------------|
##   | Routine         | Effect                                                                |
##   |-----------------|-----------------------------------------------------------------------|
##   | `toShownAnswer` | read answer of `sample` for text: kept pairs, report and status       |
##   | `toShownServed` | read output, report and exit of child: gismu, report and status       |
##   | `toCommand`     | command of `tagger` that tags note by gismu shown; empty where none   |
##   |-----------------|-----------------------------------------------------------------------|

{.experimental: "strictFuncs".}

import std/[sequtils, strutils]

import ricysoho

import ../src/rictadni/[suggestions, tags]


type
  Pair* = tuple[gismu, gloss: string]  ## Gismu kept, with gloss model gave; empty gloss where none.

  Shown* = object  ## Define what page shows for one answer or run.
    pairs*: seq[Pair]  ## Each gismu kept, in order, each once.
    report*: string  ## Report of answer, as `suggester` writes it to standard error.
    status*: string  ## One sentence under button.
    is_fail*: bool  ## Status reports failure: no gismu, or run refused.


const
  COMMAND_TAG = "tagger tag notes/text.md"  ## Command of `tagger` that tags note, before gismu.
  MODEL_UNNAMED* = "the tier that answered"  ## Model report names where `sample` names none.
  MODEL_PAGE* = "claude-opus-5-5"  ## Model page asks; `sample` takes no schema, so not that of CLI.
  TIER_PAGE* = "complex"  ## Tier page asks where runtime cannot give model.
  EFFORT_PAGE* = Effort.High  ## Effort page asks; `sample` takes low, medium or high alone.
  STATUS_ASKING* = "Asking Claude…"  ## Status while `sample` runs.
  STATUS_BLANK* = "Paste a text first."  ## Status where box holds no text.
  STATUS_NO_RUNTIME* = "This view cannot ask Claude. Open the page on claude.ai, signed in."
    ## Status where runtime gives no `sample`.
  STATUS_REFUSED* = "The page may not ask Claude for you. Allow it to try again."
    ## Status where viewer refused page `sample`.
  STATUS_LIMITED* = "Claude is busy or your usage limit is reached. Wait, then try again."
    ## Status where runtime limits rate.
  STATUS_SERVER* = "Sends text to suggester on this machine, which asks with your key."
    ## Status where page has no runtime, so form posts to server.
  STATUS_RUNTIME* = "Asks " & MODEL_PAGE & " at effort " & $EFFORT_PAGE &
      ", through your own Claude usage."
    ## Status where runtime of Artifact can ask `sample`.


func toStatusKept(count: int): string =
  ## State how many gismu page kept.
  "Kept " & $count & " gismu."


func spanObject*(answer: string): string =
  ## Cut answer to its span from first `{` to last `}`, since model may wrap object in words;
  ##   whole answer where none opens, so reader names what came.
  let start = answer.find('{')
  if start < 0: answer else: answer[start .. max(start, answer.rfind('}'))]


func toShownAnswer*(text, answer, model: string): Shown =
  ## Read answer of `sample` for text: each gismu reader keeps, with gloss, then report.
  let
    read = readAnswer(answer.spanObject, model)
    named = if model.len > 0: model else: MODEL_UNNAMED
  for verdict in read.verdicts:
    if not verdict.is_kept: continue
    for w in verdict.tag.gismu:
      if result.pairs.allIt(it.gismu != $w): result.pairs.add (gismu: $w, gloss: verdict.gloss)
  result.report = read.toReport(toPassage(text), named)
  result.is_fail = result.pairs.len == 0
  result.status =
    if result.is_fail: "Claude gave no gismu of the list; report says why."
    else: toStatusKept(result.pairs.len)


func toShownServed*(output, report: string, code: int): Shown =
  ## Read run of child of server: each gismu it printed, its report, and status by its exit.
  for line in output.splitLines:
    if line.len > 0: result.pairs.add (gismu: line, gloss: "")
  result.report = report
  result.is_fail = code != 0 or result.pairs.len == 0
  result.status =
    case code
    of 0: toStatusKept(result.pairs.len)
    of 1: "No gismu of the list was kept; report says why."
    else: "Suggester refused to run, with exit " & $code & "; report says why."


func toCommand*(pairs: openArray[Pair]): string =
  ## Render command of `tagger` that tags note by each gismu shown; empty where none.
  if pairs.len == 0: return ""
  result = COMMAND_TAG
  for pair in pairs: result.add " " & pair.gismu
