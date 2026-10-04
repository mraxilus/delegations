## Enforce glossary shape: Matt Pocock's CONTEXT.md format under name GLOSSARY.md.
##   Shape: `# <Name>` heading, description, `## Standards` heading, `## Language` heading,
##     then entries of form `**Term**:` line, definition line(s), optional `_Avoid_:` line.
##   Standards entry is `- **Name**, owner and edition: symbols`, each symbol with its table or
##     clause; check demands bold name closed by comma and colon after it, never edition's
##     truth (GUIDE.md, Glossary process).
##   Check demands both headings in that order, entry shape, and definition after every term;
##     it never judges content, which is contributor's and Architect's work.
##   Across glossaries: standard project repeats from root, or two projects both list, is
##     finding at later place naming root as its home, since root holds what two projects
##     share. Moving standard is propagation, so finding is curator's in any project.
##
##   Cost: zero terms and zero standards pass; format creates entries lazily as they resolve.
##   Cost: standard renamed by one word passes across check; it catches copy, never paraphrase,
##     as `duplicates.nim` does.
##
##   People words: root glossary names Architect, Delegate, Curator and Contributor and lists
##     synonyms to avoid under each; those for people are `PEOPLE_WORDS`, and root files and
##     curator records are held to them outside code (curator review, C7). List is people only:
##     full avoid list holds build, rules and version, which have plain senses everywhere.

{.experimental: "strictFuncs".}

import std/[strutils, tables]
import ./[findings, markdown]


const
  STANDARDS_HEADING* = "## Standards"
    ## Heading under which glossary names standards its symbols come from.
  LANGUAGE_HEADING* = "## Language"  ## Heading under which glossary defines its terms.
  ROOT_GLOSSARY* = "GLOSSARY.md"
    ## Path of root glossary, home of every standard two projects share.


const PEOPLE_WORDS* = [
  "owner", "user", "session", "agent", "bot", "maintainer", "developer", "worker", "author",
  "assistant", "admin", "director", "reviewer", "persona",
]
  ## Words glossary avoids for people, matched whole and without case, plural included.
  ## `identity`, avoided under Role, is left out: it is algebra's word in `curator/probe`.


func isTermLine*(line: string): bool =
  ## Decide whether line opens glossary entry, i.e. `**Term**:`.
  line.len > 5 and line.startsWith("**") and line.endsWith("**:")


func isStandardLine*(line: string): bool =
  ## Decide whether line opens standards entry, i.e. `- **Name**, owner and edition: symbols`.
  if not line.startsWith("- **"): return false
  let close = line.find("**", 4)
  close > 4 and close + 2 < line.len and line[close + 2] == ',' and ':' in line[close + 2 .. ^1]


func standardsIn*(source: string): seq[(int, string)] =
  ## Collect one-based line and bold name of every standards entry, in order.
  var is_inside = false
  let lines = source.splitLines
  for i, line in lines:
    if line.startsWith("#"):
      is_inside = line == STANDARDS_HEADING
      continue
    if is_inside and line.isStandardLine:
      result.add (i + 1, line[4 ..< line.find("**", 4)])


func checkGlossary*(path, source: string): seq[Finding] =
  ## Report missing or misplaced headings, malformed standards, and terms lacking definition.
  if not source.firstNonBlank.startsWith("# "):
    result.add finding(path, 1, "Glossary must open with `# <Name>` heading.")
  let headings = source.headingLines
  if STANDARDS_HEADING notin headings:
    result.add finding(path, 0, "Glossary lacks `## Standards` heading.")
  if LANGUAGE_HEADING notin headings:
    result.add finding(path, 0, "Glossary lacks `## Language` heading.")
  if headings.find(STANDARDS_HEADING) > headings.find(LANGUAGE_HEADING) and
      LANGUAGE_HEADING in headings:
    result.add finding(path, 0, "Glossary must put `## Standards` before `## Language`.")
  let lines = source.splitLines
  var is_standards = false
  for i, line in lines:
    if line.startsWith("#"): is_standards = line == STANDARDS_HEADING
    if is_standards and line.startsWith("- ") and not line.isStandardLine:
      result.add finding(
        path,
        i + 1,
        "Standard must read `- **Name**, owner and edition: symbols`; got `" & line & "`.",
      )
    if not line.isTermLine: continue
    let
      next = if i + 1 < lines.len: lines[i + 1] else: ""
      is_defined = next.strip.len > 0 and not next.startsWith("#") and
        not next.isTermLine and not next.startsWith("_Avoid_")
    if not is_defined:
      result.add finding(
        path,
        i + 1,
        "Term lacks definition on next line; got `" & line[2 ..< line.len - 3] & "`.",
      )


func checkStandardsAcross*(glossaries: openArray[(string, string)]): seq[Finding] =
  ## Report standard project glossary repeats from root, or two project glossaries both list.
  ##   Later place is named, since earlier one is where it belongs unless root should hold it.
  var root_names: seq[string]
  for (path, source) in glossaries:
    if path == ROOT_GLOSSARY:
      for (_, name) in source.standardsIn: root_names.add name
  var first_seen = initTable[string, string]()
  for (path, source) in glossaries:
    if path == ROOT_GLOSSARY: continue
    for (line, name) in source.standardsIn:
      if name in root_names:
        result.add finding(
          path,
          line,
          "Standard is in root glossary already, so project must not repeat it; got `" &
            name & "`.",
          is_propagation = true,
        )
      elif name in first_seen:
        result.add finding(
          path,
          line,
          "Standard two projects list belongs in root glossary; got `" & name &
            "`, also in `" & first_seen[name] & "`.",
          is_propagation = true,
        )
      else: first_seen[name] = path


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
    let
      word = text[i ..< j]
      bare = word.toLowerAscii.strip(leading = false, chars = {'s'})
    if bare in PEOPLE_WORDS or word.toLowerAscii in PEOPLE_WORDS: result.add word
    i = j


func checkPeopleWords*(path, source: string): seq[Finding] =
  ## Report people word glossary avoids, outside fenced code, code spans and tables.
  let lines = source.fencedOut.splitLines
  for i, line in lines:
    if line.strip.startsWith("|"): continue
    for word in line.peopleWordsIn:
      result.add finding(
        path,
        i + 1,
        "Glossary avoids this word for people; write agreed term (GLOSSARY.md); got `" &
          word & "`.",
      )
