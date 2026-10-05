## Read proposed change to library from its Markdown file, and apply it to library's files at pin.
##   Change is Markdown, so reader reads it and audit checks it: title, then why, then one
##     section per edit. Edit is quote and replacement, or whole file with digest of what it
##     replaces:
##
##     ```
##     ## Edit `pga/operators.nim`           quote must occur once at pin; replacement follows
##     ## Replace `pga/cayleys.nim` from `9f3a...`   file at pin must hash to digest
##     ```
##
##   Quote rather than line range: line numbers move with every library commit, quote moves
##     only when its own lines do, so change that still applies at head is one that still says
##     what it meant. Quote found nowhere, or twice, is finding, never guess.
##   Digest guards whole-file replacement, which carries no quote: file that changed at head
##     makes replacement stale, and staleness is finding rather than silent overwrite.
##   Application is pure over map of path to text, so tests feed synthetic library and evaluation
##     runner feeds checkout.
##
##   Cost: digest is `std/hashes` of file text, not cryptographic; it detects change, which is
##     all it is asked, and needs no process or package.

{.experimental: "strictFuncs".}

import std/[hashes, strutils, tables]

import ./[guard, markdown]


type
  Edit* = object  ## Define one edit to one library file.
    path*: string  ## Library-relative path, as `pga/operators.nim`.
    quote*: string  ## Text at pin edit replaces; empty for whole-file replacement.
    replacement*: string  ## Text put in its place, or whole new file.
    digest*: string
      ## Digest file at pin must have, for whole-file replacement; empty for quote edit.
    line*: int  ## Line of change file edit's section opens on, for findings.
  Change* = object  ## Define one proposed change: title, why, and edits in order.
    title*: string  ## Heading of change file.
    why*: seq[Block]  ## Blocks between title and first edit.
    edits*: seq[Edit]  ## Edits applied in order.


const
  OPENING_EDIT = "Edit `"  ## Opening of heading naming quote edit.
  OPENING_REPLACE = "Replace `"  ## Opening of heading naming whole-file replacement.
  SEPARATOR_DIGEST = "` from `"  ## Text between path and digest in replacement heading.



#[ Digests ]#

func digestOf*(text: string): string =
  ## Digest text as 16 hexadecimal digits.
  toHex(cast[uint64](hash(text))).toLowerAscii



#[ Parsing ]#

func pathBetween(heading, opening: string): string =
  ## Read path in backticks after opening; empty when heading does not carry one.
  if not heading.startsWith(opening): return ""
  let close = heading.find('`', opening.len)
  if close < 0: "" else: heading[opening.len..<close]


func parseChange*(path, source: string): (Change, seq[Finding]) =
  ## Read change file at path; malformed section is finding naming its line.
  let blocks = parseBlocks(source)
  var
    change: Change
    findings: seq[Finding]
    i = 0

  # Take title from first heading, which must be level one.
  if blocks.len == 0 or blocks[0].kind != KindBlock.Heading or blocks[0].level != 1:
    return (change, @[Finding(path: path, line: 1, message: "Change needs `# Title`; got none.")])
  change.title = blocks[0].lines[0]
  i = 1

  # Take why up to first edit section.
  while i < blocks.len and not (blocks[i].kind == KindBlock.Heading and blocks[i].level == 2):
    change.why.add blocks[i]
    inc i

  # Take each edit section with its fences.
  while i < blocks.len:
    let heading = blocks[i]
    inc i
    if heading.kind != KindBlock.Heading or heading.level != 2: continue
    var fences: seq[Block]
    while i < blocks.len and blocks[i].kind == KindBlock.Fence:
      fences.add blocks[i]
      inc i
    let
      text = heading.lines[0]
      path_edit = text.pathBetween(OPENING_EDIT)
      path_replace = text.pathBetween(OPENING_REPLACE)
    if path_edit.len > 0:
      if fences.len != 2:
        findings.add Finding(
          path: path,
          line: heading.line,
          message: "Edit needs quote and replacement fences; got `" & $fences.len & "`.",
        )
        continue
      change.edits.add Edit(
        path: path_edit,
        quote: fences[0].lines.join("\n"),
        replacement: fences[1].lines.join("\n"),
        line: heading.line,
      )
    elif path_replace.len > 0:
      let
        opening = OPENING_REPLACE & path_replace & SEPARATOR_DIGEST
        digest = if text.startsWith(opening): text[opening.len .. ^1].strip(chars = {'`'}) else: ""
      if digest.len == 0 or fences.len != 1:
        findings.add Finding(
          path: path,
          line: heading.line,
          message: "Replace needs digest and one fence; got `" & text & "`.",
        )
        continue
      change.edits.add Edit(
        path: path_replace,
        replacement: fences[0].lines.join("\n") & "\n",
        digest: digest,
        line: heading.line,
      )
    else:
      findings.add Finding(
        path: path,
        line: heading.line,
        message: "Section is neither Edit nor Replace; got `" & text & "`.",
      )
  (change, findings)



#[ Application ]#

func applyChange*(files: var Table[string, string], change: Change, source: string): seq[Finding] =
  ## Apply change to map of library path to text, in order; each misfit is finding.
  ##   Quote must occur exactly once; whole-file digest must match text at pin.
  for edit in change.edits:
    if edit.path notin files:
      result.add Finding(
        path: source,
        line: edit.line,
        message: "Library holds no such file; got `" & edit.path & "`.",
      )
      continue
    let text = files[edit.path]
    if edit.digest.len > 0:
      let digest = text.digestOf
      if digest != edit.digest:
        result.add Finding(
          path: source,
          line: edit.line,
          message: "File changed since replacement was written; got digest `" & digest & "`.",
        )
        continue
      files[edit.path] = edit.replacement
      continue
    let count = text.count(edit.quote)
    if count != 1:
      result.add Finding(
        path: source,
        line: edit.line,
        message: "Quote must occur once in `" & edit.path & "`; got `" & $count & "`.",
      )
      continue
    files[edit.path] = text.replace(edit.quote, edit.replacement)


func lineOf*(text, quote: string): int =
  ## Read line quote opens on, counted from one; zero where quote is absent.
  let at = text.find(quote)
  if at < 0: 0 else: text[0..<at].count('\n') + 1
