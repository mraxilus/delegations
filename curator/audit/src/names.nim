## Read words names may take from glossaries, and check acronyms against them (Article V.6, V.9;
##   GUIDE.md, Names).
##   Check is knoller's (`names.nim` there, `checkNames`), whose rules read one file alone; this
##     module holds what reads glossaries: words they admit, and acronyms they list.
##   V.9: acronym, i.e. run of two or more capitals inside camel or Pascal name, stays only where
##     glossary lists it (`checkAcronyms`). Glossary belongs to this repository, and knoller runs
##     on any, so check is here (D2 of #572). SCREAMING name is all capitals, so its acronyms
##     cannot be told from words and hold by reading. Declarations alone are read, so name library
##     owns, which reaches code only at use site, passes by construction.
##   `JARGON` is closed list of V.6. Caller adds symbols glossaries list under `## Standards` as
##     code spans, and their `**Term**` names, through `exemptionsGlossary`; `exemptionsOf`
##     reads root glossary and glossary of path's own project, and static pass gives them to
##     knoller's check.
##
##   V.1, V.6 and V.11 have fixers in knoller (`names.nim` and `rewrites.nim` there), which
##     `koch fix` gives words this module reads (`fixes.nim`). Acronyms of name are read there
##     too (`acronyms`), since rename refuses new name reading as new acronym.

{.experimental: "strictFuncs".}

import std/[sequtils, strutils]
import ../../knoller/src/knoller
import ./[findings, glossary]


func exemptionsGlossary*(glossary: string): seq[string] =
  ## Collect code spans under `## Standards` and names of terms, as words name may take.
  var is_standards = false
  for line in glossary.splitLines:
    if line.startsWith("#"): is_standards = line == HEADING_STANDARDS
    if is_standards:
      var i = 0
      while true:
        let open = line.find('`', i)
        if open < 0: break
        let close = line.find('`', open + 1)
        if close < 0: break
        for w in line[open + 1 ..< close].split({' ', ','}):
          if w.len > 0: result.add w
        i = close + 1
    if line.isLineTerm: result.add line[2 ..< line.len - 3]


func exemptionsOf*(glossaries: openArray[(string, string)], path: string): seq[string] =
  ## Read words name in path may take beyond table: jargon of V.6, and what root glossary and
  ##   glossary of path's own project list (`exemptionsGlossary`).
  result = JARGON.toSeq
  for (glossary, source) in glossaries:
    let directory = glossary[0 ..< glossary.len - GLOSSARY_ROOT.len]
    if glossary == GLOSSARY_ROOT or path.startsWith(directory):
      result.add source.exemptionsGlossary


func checkAcronyms*(path, source: string; exempt: openArray[string]): seq[Finding] =
  ## Report each acronym of declared name that `exempt` does not list (V.9), case aside.
  let exempt_lower = exempt.mapIt(it.toLowerAscii)
  for d in source.declarations:
    for a in d.name.acronyms:
      if a.toLowerAscii in exempt_lower: continue
      result.add finding(
        path,
        d.line,
        "Acronym stays only where glossary lists it (V.9); got `" & a & "` in `" & d.name & "`.",
      )
