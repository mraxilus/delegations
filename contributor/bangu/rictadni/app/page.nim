## Expose to tag page, compiled to JavaScript, prompt and reader of `suggestions.nim`.
##   One source serves both front ends: page asks `sample` of Artifact runtime with prompt built
##     here, and reads answer with same `readAnswer` as `suggester` (II.9: no copy in script).
##   Cost: page carries gismu list twice, in prompt and in reader; size read in PROVENANCE.md.
##
##   |---------------------|---------------------------------------------------------------|
##   | Export              | Effect                                                        |
##   |---------------------|---------------------------------------------------------------|
##   | `rictadniPrompt`    | one user turn: system text, passage element, shape of answer  |
##   | `rictadniGismu`     | gismu kept from answer, one to line                           |
##   | `rictadniReport`    | report of answer, as `suggester` writes it to standard error  |
##   |---------------------|---------------------------------------------------------------|

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/strutils

import ricysoho

import ../src/rictadni/suggestions


func rictadniPrompt(text: cstring): cstring {.exportc.} =
  ## Build one user turn for `sample` from text pasted in page.
  cstring(toPromptAlone(toPassage($text)))


func rictadniGismu(answer, model: cstring): cstring {.exportc.} =
  ## Read answer of `sample`, and give each gismu kept, one to line.
  var lines: seq[string]
  for word in readAnswer($answer, $model).verdicts.gismu: lines.add $word
  cstring(lines.join("\n"))


func rictadniReport(text, answer, model: cstring): cstring {.exportc.} =
  ## Read answer of `sample`, and give report that `suggester` writes for it.
  cstring(readAnswer($answer, $model).toReport(toPassage($text), $model))
