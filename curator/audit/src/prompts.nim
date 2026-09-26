## Hold opening prompts to CURATOR.md duty 10: short, and rules rather than diary.
##   Prompt is pasted into every delegate's first message, so every paragraph is read on every
##     start. Two forms are checked: size, against `PROMPT_BYTES`, and diary references,
##     i.e. date, `#N`, `issue N`, `pull request N` or `run N` in prose, since incident
##     belongs in audit record or log and rule alone belongs here (curator review, C5, C12).
##   Code spans and fences pass, so carried-list example naming `#140` stays legal.
##
##   Cost: article numbers such as `II.9` and duty numbers pass by shape, and so does
##     `2026` alone; only whole date is diary here.

{.experimental: "strictFuncs".}

import std/strutils
import ./[findings, markdown, provenance, record]


const
  PROMPT_PATHS* = ["CONTRIBUTOR.md", "CURATOR.md"]
    ## Files pasted as opening prompts.
  PROMPT_BYTES* = 40_000
    ## Bytes prompt may hold; ceiling guards runaway growth, never trims by length alone.
    ## Number is Architect's.
  DIARY_WORDS* = ["issue", "issues", "pull request", "pull requests", "run", "runs"]
    ## Words that, followed by number, name one incident rather than rule.


func withoutSpans(line: string): string =
  ## Blank backticked spans, so example in code passes.
  var is_inside = false
  for c in line:
    if c == '`': is_inside = not is_inside
    result.add(if is_inside or c == '`': ' ' else: c)


func diaryReference*(line: string): string =
  ## Read first diary reference line carries outside code; empty when none.
  let text = line.withoutSpans
  if text.hasIsoDate:
    for i in 0 .. text.len - 10:
      if text[i ..< i + 10].isIsoDate: return text[i ..< i + 10]
  for i, c in text:
    if c == '#' and i + 1 < text.len and text[i + 1] in Digits:
      var j = i + 1
      while j < text.len and text[j] in Digits: inc j
      return text[i ..< j]
  let lower = text.toLowerAscii
  for word in DIARY_WORDS:
    var at = lower.find(word & " ")
    while at >= 0:
      let after = at + word.len + 1
      let is_bounded = at == 0 or lower[at - 1] notin Letters
      if is_bounded and after < text.len and text[after] in Digits:
        var j = after
        while j < text.len and text[j] in Digits: inc j
        return text[at ..< j]
      at = lower.find(word & " ", at + 1)
  ""


func checkDiary(path, source: string): seq[Finding] =
  ## Report prose line of prompt naming date, issue, pull request or run.
  let lines = source.fencedOut.splitLines
  for i, line in lines:
    let found = line.diaryReference
    if found.len > 0:
      result.add finding(
        path, i + 1,
        "Prompt names incident; state rule and its cost here, and leave incident to record " &
          "or log (duty 10); got `" & found & "`.",
      )


func checkPromptSize(path, source: string): seq[Finding] =
  ## Report prompt over `PROMPT_BYTES`.
  if source.len > PROMPT_BYTES:
    result.add finding(
      path, 0,
      "Prompt over " & $PROMPT_BYTES & " bytes; prune before adding (duty 10); got " &
        $source.len & ".",
    )


func checkPrompt*(path, source: string): seq[Finding] =
  ## Run both prompt checks over one prompt.
  result = checkDiary(path, source)
  result.add checkPromptSize(path, source)
