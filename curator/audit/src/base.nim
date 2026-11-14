## Enforce that branch carries base's rules and checker, i.e. what decides meaning of green, and
##   name each change of charter to branch that predates it.
##   Pull request green against yesterday's `main` can merge into today's and be false on
##   arrival: that happened, and `main` ran red until stamp was corrected. GitHub offers
##   "require branches to be up to date", which prevents it. That setting is blanket, and this
##   check is narrow form of it.
##
##   Only two kinds of path matter. Charter (`RULES`) holds rules of content, which move stamp
##     every project claims, and sections of process, which move none yet say what delegate
##     does; delegate forgets both, so every change of charter reaches each older branch
##     (#843). Checker (`isChecker`) decides what audit accepts, so branch predating it was
##     measured by older ruler.
##   Everything else may differ freely: another project's code cannot make this branch's
##     stamp false, and demanding branch be current with all of it is friction for nothing.
##
##   Finding names each `##` section of each charter document that base changed since fork, on
##     one line, with `git diff <fork>..<base> -- <document>` that shows change. So delegate
##     reads what changed, and never one sentence on how to merge. It asks for re-audit and
##     re-stamp only where stamped text of that document moved (`textStamped`); change of
##     process alone asks to read and merge. Checker is one finding more, naming its paths.
##   Section is named by heading line, since citation names it so; opening above first heading
##     has none, so its first line names it. Section that moved keeps its text, yet stamp reads
##     parts in order, so move is change too. Document that differs while no section does, as
##     heading written twice can hide, names each heading, so changed document never passes.
##   Start hook prints these findings at start, resume and compaction (`hooks.nim`).
##
##   Cost: merging change of charter, process included, reddens every open pull request until
##     each merges base; Architect chose that price of fresh reading over new step (#843).
##   Cost: check reads pull request time, never merge time. Branch green at ten can still
##     merge at five past after another lands. Window shrinks from days to minutes; only
##     merge queue closes it.
##   Cost: fork and each rules document at both ends cost two reads of git per document, and
##     only where base gained governing path.

{.experimental: "strictFuncs".}

import std/[sequtils, strutils, tables]
import ./[findings, markdown, plan, provenance, tree]


type Drift* = object  ## Define what base changed since branch forked, as drift reads it.
  fork*: string  ## Merge base, abbreviated, as command that shows change names it.
  base*: string  ## Ref branch is compared with, such as `origin/main`.
  gained*: seq[string]  ## Paths base changed since fork.
  rules_fork*: array[RULES.len, string]  ## Each `RULES` document at fork; empty where none.
  rules_base*: array[RULES.len, string]  ## Each `RULES` document at base; empty where none.


func isGoverning*(path: string): bool =
  ## Decide whether path decides what green means, i.e. charter document or checker.
  path in RULES or path.isChecker


proc readDrift*(root, base: string): Drift =
  ## Read what base changed since branch forked: paths, then fork and each rules document at
  ##   both ends where one path governs, since drift reads them for nothing else.
  result = Drift(base: base, gained: pathsGained(root, base))
  if not result.gained.anyIt(it.isGoverning): return
  let fork = fieldsGit(root, ["merge-base", base, "HEAD"])[0].strip
  result.fork = fieldsGit(root, ["rev-parse", "--short", fork])[0].strip
  for k, rule in RULES:
    result.rules_fork[k] = textAt(root, fork, rule)
    result.rules_base[k] = textAt(root, base, rule)


func headingsChanged(fork, base: string): seq[string] =
  ## Name each `##` section that differs between document at fork and at base: heading line,
  ##   in order base holds them, then each heading base dropped, then each that moved.

  # Gather text of each heading at both ends; heading written twice joins its parts.
  var texts_fork, texts_base: OrderedTable[string, string]
  for part in fork.sections: texts_fork.mgetOrPut(part.heading, "").add part.text
  for part in base.sections: texts_base.mgetOrPut(part.heading, "").add part.text

  # Collect heading whose text differs or that one end lacks, then each that changed place.
  var changed: seq[string]
  for heading, text in texts_base:
    if heading notin texts_fork or texts_fork[heading] != text: changed.add heading
  for heading in texts_fork.keys:
    if heading notin texts_base: changed.add heading
  let
    kept_base = toSeq(texts_base.keys).filterIt(it in texts_fork)
    kept_fork = toSeq(texts_fork.keys).filterIt(it in texts_base)
  for i, heading in kept_base:
    if heading != kept_fork[i] and heading notin changed: changed.add heading
  if changed.len == 0 and fork != base:
    changed = toSeq(texts_base.keys).filterIt(it.len > 0)

  # Name opening, which has no heading, by its first line at either end.
  for heading in changed:
    result.add(if heading.len > 0: heading else: (texts_base[""] & texts_fork[""]).firstNonBlank)


func checkBase*(drift: Drift): seq[Finding] =
  ## Report each charter document base changed since branch forked, naming each changed section
  ##   and command that shows change, then checker branch predates.
  for k, rule in RULES:
    if rule notin drift.gained: continue
    let changed = headingsChanged(drift.rules_fork[k], drift.rules_base[k])
    if changed.len == 0: continue
    let
      shown = "`git diff " & drift.fork & ".." & drift.base & " -- " & rule & "`"
      is_moved = textStamped(rule, drift.rules_fork[k]) != textStamped(rule, drift.rules_base[k])
      action =
        if is_moved: ", merge base, re-audit against each change, then re-stamp, as /sync says"
        else: ", then merge base, as /sync says; sections of process move no stamp"
    result.add finding(
      rule,
      0,
      "Base changed sections since branch forked; read " & shown & action & "; got " &
        changed.mapIt("`" & it & "`").join(", ") & ".",
    )
  var behind: seq[string]
  for path in drift.gained:
    if path.isChecker and path notin behind: behind.add path
  if behind.len == 0: return
  result.add finding(
    "",
    0,
    "Branch predates checker on base; merge base, then check again, as /sync says; got `" &
      behind.join(", ") & "`.",
  )
