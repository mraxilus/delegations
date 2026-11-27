## Hold scripts to base JavaScript, Node built-ins and tools of build that list names.
##   Architect asked that code import nothing beyond base JavaScript where it can avoid it
##     (#1045).
##   Static part refuses, in `koch check`, each package that script could do without:
##     Each name of `dependencies`, `optionalDependencies` or `peerDependencies` of node manifest
##       is finding, since page or tool ships it; tools of build alone stay, as dev dependencies.
##     Each dev dependency off `PACKAGES_ALLOWED` is finding, and so is each import of TypeScript
##       naming package off it. Specifier opening `.` or `/` is path, and `node:` is built-in.
##     Bare built-in, as `fs`, reads as package, and help names `node:fs`.
##     Each `<script>` of page or SVG whose `src` names other host is finding, since page loads
##       package from there.
##     Finding of project blocks branch of its role alone, as each finding inside project does
##       (CURATOR.md, duty 3).
##
##   Rejected: list of Node built-ins for bare names, which moves with each Node release, where
##     `node:` form names built-in by itself.
##   Cost: imports read as text by line, never parsed: string or comment spanning lines ends at
##     each line, so text shaped as import inside it reads as import, and import built from
##     expression reads as none.
##   Cost: inline script of page reads as none; only `src` of `<script>` is read.

{.experimental: "strictFuncs".}

import std/[json, options, os, sequtils, strutils]
import ./[findings, layout]
from ./dependencies import MANIFEST_NODE
from ./kinds import Kind


const
  PACKAGES_ALLOWED* = [
    ("@playwright/test", "drives browser through real events for `drive`"),
    ("typescript", "type-checks scripts for `types`"),
    ("@types/node", "declares types of Node built-ins to that check, and holds no code"),
  ]
    ## Packages script may take, each with what base JavaScript cannot do in its place; list grows
    ##   through process-change issue (CONTRIBUTOR.md, TypeScript and Node).
  FIELDS_RUNTIME = ["dependencies", "optionalDependencies", "peerDependencies"]
    ## Fields of manifest naming packages that ship with page or tool.
  FIELD_DEV = "devDependencies"  ## Field of manifest naming tools of build.
  PREFIX_BUILTIN = "node:"  ## Prefix naming Node built-in.
  KEYWORDS_IMPORT = ["from", "import", "require"]
    ## Words whose quoted operand names module, as `from 'x'`, `import 'x'` and `require('x')`.
  QUOTES = {'\'', '"', '`'}  ## Marks that open and close specifier.
  CITE_RULE = " (CONTRIBUTOR.md, TypeScript and Node)"  ## Rule each finding and line cites.




#[ Static Check ]#

func namePackage*(specifier: string): string =
  ## Read package bare specifier names, i.e. `@scope/name` of `@scope/name/sub`, `name` of
  ##   `name/sub`.
  let parts = specifier.split('/')
  if specifier.startsWith('@') and parts.len > 1: parts[0] & "/" & parts[1]
  else: parts[0]


func isAllowed(name: string): bool =
  ## Decide whether package is on `PACKAGES_ALLOWED`.
  PACKAGES_ALLOWED.anyIt(it[0] == name)


func isPath(specifier: string): bool =
  ## Decide whether specifier names file by path, as `./x`, `../x` or `/x`, rather than package.
  specifier.startsWith('.') or (specifier.startsWith('/') and not specifier.startsWith("//"))


func widthKeyword(line: string, at: int): int =
  ## Measure keyword of import standing alone as word at `at`, never after `.`; `0` where none
  ##   stands there.
  if at > 0 and (line[at - 1] in IdentChars or line[at - 1] == '.'): return 0
  for keyword in KEYWORDS_IMPORT:
    let after = at + keyword.len
    if line.continuesWith(keyword, at) and (after >= line.len or line[after] notin IdentChars):
      return keyword.len
  0


func operand(line: string, at: int): tuple[specifier: string, ending: int] =
  ## Read quoted operand that opens at `at`, past spaces and `(`, with index past its closing
  ##   quote; empty, ending at `at`, where none opens there.
  var cursor = at
  while cursor < line.len and line[cursor] in {' ', '('}: inc cursor
  if cursor >= line.len or line[cursor] notin QUOTES: return ("", at)
  let closing = line.find(line[cursor], cursor + 1)
  if closing < 0: ("", at) else: (line[cursor + 1 ..< closing], closing + 1)


func specifiersScript*(text: string): seq[tuple[line: int, specifier: string]] =
  ## Read each module script names, by line, i.e. quoted operand of `from`, `import` or `require`.
  ##   Keyword counts outside string alone, so `Array.from('x')` and `'start from'` name none.
  ##   Line opening comment is skipped, and `//` outside string ends line.
  let lines = text.splitLines
  for i, line in lines:
    let opening = line.strip
    if opening.startsWith("//") or opening.startsWith("*") or opening.startsWith("/*"): continue
    var
      cursor = 0
      quote = none(char)
    while cursor < line.len:
      let c = line[cursor]
      if quote.isSome:
        if c == '\\': inc cursor
        elif c == quote.get: quote = none(char)
        inc cursor
        continue
      if c in QUOTES:
        quote = some(c)
        inc cursor
        continue
      if line.continuesWith("//", cursor): break
      let width = line.widthKeyword(cursor)
      if width == 0:
        inc cursor
        continue
      let (specifier, ending) = line.operand(cursor + width)
      if specifier.len > 0: result.add (line: i + 1, specifier: specifier)
      cursor = max(ending, cursor + width)


func checkScript*(path, text: string): seq[Finding] =
  ## Report each import of package off `PACKAGES_ALLOWED` at its line; path and built-in pass.
  for (line, specifier) in text.specifiersScript:
    if specifier.isPath or specifier.startsWith(PREFIX_BUILTIN): continue
    let name = specifier.namePackage
    if name.isAllowed: continue
    result.add finding(
      path,
      line,
      "Script imports package off list of `packages_node.nim`; take base JavaScript, or ask " &
        "curator to list tool it cannot replace" & CITE_RULE & "; got `" & specifier & "`.",
      help = "Node built-in takes form `" & PREFIX_BUILTIN & name & "`.",
    )


func lineKey(text, key: string, after = 0): int =
  ## Find line of first `"key"` at or after line `after`, one-based; `0` where text holds none.
  let lines = text.splitLines
  for i in max(after - 1, 0) ..< lines.len:
    if ("\"" & key & "\"") in lines[i]: return i + 1
  0


proc checkManifest*(path, text: string): seq[Finding] =
  ## Report each runtime package of node manifest, and each dev dependency off `PACKAGES_ALLOWED`.
  let node =
    try: parseJson(text)
    except JsonParsingError, ValueError:
      return @[finding(path, 0, "Node manifest unreadable as JSON; got `" & path & "`.")]
  if node.kind != JObject: return
  for field in FIELDS_RUNTIME:
    if field notin node or node[field].kind != JObject: continue
    let at = text.lineKey(field)
    for name, _ in node[field]:
      result.add finding(
        path,
        text.lineKey(name, at),
        "Manifest ships package with page or tool; take base JavaScript, since only tools of " &
          "build stay, as dev dependencies" & CITE_RULE & "; got `" & name & "` in `" & field &
          "`.",
      )
  if FIELD_DEV in node and node[FIELD_DEV].kind == JObject:
    let at = text.lineKey(FIELD_DEV)
    for name, _ in node[FIELD_DEV]:
      if name.isAllowed: continue
      result.add finding(
        path,
        text.lineKey(name, at),
        "Dev dependency is off list of `packages_node.nim`; take base JavaScript, or ask " &
          "curator to list tool it cannot replace" & CITE_RULE & "; got `" & name & "`.",
      )


func checkPage*(path, text: string): seq[Finding] =
  ## Report each `<script>` whose `src` names other host, at its line.
  let lines = text.splitLines
  for i, line in lines:
    var at = line.find("<script")
    while at >= 0:
      let
        ending = line.find('>', at)
        tag = if ending > at: line[at .. ending] else: line[at .. ^1]
        key = tag.find("src=")
      if key >= 0 and key + 4 < tag.len and tag[key + 4] in {'"', '\''}:
        let
          opening = key + 4
          closing = tag.find(tag[opening], opening + 1)
          source = if closing > opening: tag[opening + 1 ..< closing] else: ""
        if "://" in source or source.startsWith("//"):
          result.add finding(
            path,
            i + 1,
            "Page loads script from other host; take base JavaScript, or script of project" &
              CITE_RULE & "; got `" & source & "`.",
          )
      at = line.find("<script", at + 1)


proc checkPackagesNode*(tree: Tree): seq[Finding] =
  ## Run each part of static check over tree: manifests, scripts, then pages.
  for e in tree:
    if e.path.extractFilename == MANIFEST_NODE: result.add checkManifest(e.path, e.content)
    elif e.kind == some(Kind.TypeScript): result.add checkScript(e.path, e.content)
    elif e.kind in [some(Kind.Html), some(Kind.Svg)]: result.add checkPage(e.path, e.content)
