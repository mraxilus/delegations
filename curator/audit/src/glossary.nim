## Enforce glossary shape: Matt Pocock's CONTEXT.md format under name GLOSSARY.md.
##   Shape: `# <Name>` heading, description, `## Language` heading, then entries of form
##     `**Term**:` line, definition line(s), optional `_Avoid_:` line.
##   Check demands heading, `## Language`, and definition after every term; it never judges
##     content, which is contributor's and Architect's work.
##
##   Cost: zero terms pass; format creates entries lazily as terms resolve.
##
##   People words: root glossary names Architect, Delegate, Curator and Contributor and lists
##     synonyms to avoid under each; those for people are `PEOPLE_WORDS`, and root files and
##     curator records are held to them outside code (curator review, C7). List is people only:
##     full avoid list holds build, rules and version, which have plain senses everywhere.

{.experimental: "strictFuncs".}

import std/strutils
import ./[findings, markdown]


const PEOPLE_WORDS* = [
  "owner", "user", "session", "agent", "bot", "maintainer", "developer", "worker", "author",
  "assistant", "admin", "director", "reviewer", "persona",
]
  ## Words glossary avoids for people, matched whole and without case, plural included.
  ## `identity`, avoided under Role, is left out: it is algebra's word in `curator/probe`.


func isTermLine*(line: string): bool =
  ## Decide whether line opens glossary entry, i.e. `**Term**:`.
  line.len > 5 and line.startsWith("**") and line.endsWith("**:")


func checkGlossary*(path, source: string): seq[Finding] =
  ## Report missing headings and terms lacking definition.
  if not source.firstNonBlank.startsWith("# "):
    result.add finding(path, 1, "Glossary must open with `# <Name>` heading.")
  if "## Language" notin source.headingLines:
    result.add finding(path, 0, "Glossary lacks `## Language` heading.")
  let lines = source.splitLines
  for i, line in lines:
    if not line.isTermLine: continue
    let next = if i + 1 < lines.len: lines[i + 1] else: ""
    let is_defined = next.strip.len > 0 and not next.startsWith("#") and
      not next.isTermLine and not next.startsWith("_Avoid_")
    if not is_defined:
      result.add finding(
        path, i + 1, "Term lacks definition on next line; got `" & line[2 ..< line.len - 3] & "`."
      )


func withoutCode(line: string): string =
  ## Blank backticked spans of one line, so command and path pass unread.
  var is_inside = false
  for c in line:
    if c == '`': is_inside = not is_inside
    result.add(if is_inside or c == '`': ' ' else: c)


func isWordChar(c: char): bool =
  ## Decide whether character continues word.
  c in Letters or c in Digits or c == '_'


func peopleWordsIn*(line: string): seq[string] =
  ## Collect people words line uses outside code, as written, in order.
  let text = line.withoutCode
  var i = 0
  while i < text.len:
    if not text[i].isWordChar:
      inc i
      continue
    var j = i
    while j < text.len and text[j].isWordChar: inc j
    let word = text[i ..< j]
    let bare = word.toLowerAscii.strip(leading = false, chars = {'s'})
    if bare in PEOPLE_WORDS or word.toLowerAscii in PEOPLE_WORDS: result.add word
    i = j


func checkPeopleWords*(path, source: string): seq[Finding] =
  ## Report people word glossary avoids, outside fenced code, code spans and tables.
  let lines = source.fencedOut.splitLines
  for i, line in lines:
    if line.strip.startsWith("|"): continue
    for word in line.peopleWordsIn:
      result.add finding(
        path, i + 1,
        "Glossary avoids this word for people; write agreed term (GLOSSARY.md); got `" &
          word & "`.",
      )
