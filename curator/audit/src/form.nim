## Enforce form of source (Article X.1, X.2, X.9, VIII.5): width, whitespace, endings, banners.
##   Per line: no CR; no tab; no trailing whitespace; at most `LINE_MAX` characters counted
##   as Unicode runes, not bytes, where breaking can fix it. Per file: non-empty; ends with
##   exactly one newline. Knoller holds these rules (`form.checkForm` there), which read text
##   alone, so every kind takes one copy of them; this module adds width exemption of this
##   repository, and renders each report with its article (`findingOf`).
##   Per Nim banner, first tier `#[ Title ]#` or second tier `#[[ Title ]]#`: X.2 exactly, as
##     knoller reads it (`checkBanners`) and its fixer writes it: three blank lines before first
##     tier, two before second, one after either, and second tier following its parent at once
##     keeps its own two. Kind of other syntax takes no banner rule.
##   Static pass runs no X.9 yet, which knoller holds (`checkComments`): `koch fix` lands first,
##     so each project clears its gaps by one command on its own branch, and pull request after
##     it wires `fixes.checkFormatting` into static pass (CURATOR.md, duty 3).
##
##   Cost: two-space indent unverified; indent width depends on syntax and stays with review.
##   Cost: `LICENSE.md` exempt from width; third-party text stays verbatim (XI.3 spirit).
##   Cost: X.9 read in Nim syntax alone (Nim, NimScript, nimble); trailing comment of
##     TypeScript, C, C++, YAML, cfg and shell goes unread until each kind gets scanner.

{.experimental: "strictFuncs".}

import std/sequtils
import ../../knoller/src/knoller
import ./[findings, kinds]


const WIDTH_EXEMPT = ["LICENSE.md"]
  ## Root paths whose width goes unchecked: third-party text kept verbatim.



func checkForm*(path, source: string; rule: KindRule): seq[Finding] =
  ## Report form violations of source under kind rule: knoller's form of text, width aside on
  ##   path exempt from it, then banners of Nim syntax, exactly.
  let is_width_exempt = path in WIDTH_EXEMPT
  result = checkForm(path, source).filterIt(
    not (is_width_exempt and it.rule == Rule.LineWidth),
  ).findingsOf
  if rule.syntax == Syntax.Nim: result.add checkBanners(path, source).findingsOf


func formSteps(rule: KindRule): seq[Step] =
  ## List form fixers kind rule names, in order they run: Nim syntax takes every fixer of
  ##   knoller's form, i.e. tabs in strings, comments and banners besides line ends and ending.
  if rule.syntax == Syntax.Nim: @FORM_STEPS else: @[guarded(fixWhitespace), guarded(fixEnding)]


func fixForm*(path, source: string; rule: KindRule): Fix =
  ## Rewrite source so each form check with one mechanical fix holds; report each rewrite.
  ##   Every line is held, so no fixer writes line width check reports.
  result.source = source
  for step in rule.formSteps: result = result.chain(step.run(path, result.source, EVERY))
