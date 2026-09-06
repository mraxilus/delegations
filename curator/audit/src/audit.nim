## Audit repository against CONSTITUTION.md, STYLE.md and CONTRIBUTOR.md; library umbrella.
##   Command line lives in root `koch.nim`, as Nim's own koch drives its repository; this
##   module composes static checks so koch holds dispatch only.
##
##   Order of module bootstrapping:
##     findings -> domains -> kinds -> comments -> [prose, form]
##     findings -> projects -> dependencies
##     [domains, kinds, markdown, dependencies] -> layout -> [provenance, glossary]
##     domains -> [scope, commits]
##     [kinds, layout] -> tree
##     everything -> audit -> koch
##
##   Cost: tool runs once per check, so no hot path exists and Article VII figures stay
##     unmeasured by design; whole-tree audit time is recorded in PROVENANCE.md.

{.experimental: "strictFuncs".}

import std/options
import ./[findings, kinds, prose, form, layout, provenance, glossary]

export layout.Tree, layout.Entry, layout.projectDirs


func rulesStamp*(tree: Tree): string =
  ## Compute stamp of rules documents as tree holds them; missing document digests empty.
  var contents: seq[string]
  for rule in RULES:
    var content = ""
    for e in tree:
      if e.path == rule: content = e.content
    contents.add content
  contents.stamp


func auditTree*(tree: Tree): seq[Finding] =
  ## Run every static check over tree.
  result = tree.checkLayout
  let stamp_now = tree.rulesStamp
  let dirs = tree.projectDirs
  for e in tree:
    if e.kind.isNone: continue
    if e.path == "GLOSSARY.md": result.add checkGlossary(e.path, e.content)
    let rule = e.kind.get.rule
    result.add checkForm(e.path, e.content, rule)
    if rule.is_prose: result.add checkProse(e.path, e.content, rule.syntax)
    for dir in dirs:
      if e.path == dir & "/PROVENANCE.md": result.add checkProvenance(e.path, e.content, stamp_now)
      if e.path == dir & "/GLOSSARY.md": result.add checkGlossary(e.path, e.content)
