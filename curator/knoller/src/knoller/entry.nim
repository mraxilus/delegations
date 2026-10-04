## Move body of entry block into `proc main`, so block holds no binding (Article V.10).
##   `fixBlockEntry` moves body of entry block into `proc main` above it, doc `TODO: Document.`
##     (VI.1), and leaves block calling `main()`; body keeps lines and indent.
##   `blockEntry` refuses block routine would read otherwise: guard beyond `isMainModule`, which
##     would compile body where guard fails; `{.global.}`, `{.threadvar.}` or foreign pragma;
##     statement or export marker module level holds alone, at any depth; `quit` with value at
##     block's own indent, whose code `quit main()` would carry; and `main` named already.
##
##   Rejected: `proc main` inside block, which V.10 allows; STYLE.md §1 and every program of
##     tree put it at module level, and block then holds one call.
##   Cost: value bound in moved block lives on stack, not in static storage; large array
##     there can overflow stack, which `nim check` never reads.

{.experimental: "strictFuncs".}

import std/strutils
import ./[declared, reports, tokens, views]


const
  MAIN_GUARD* = "when isMainModule:"  ## Block that makes module entry of program (STYLE.md §1).
  PRAGMAS_MODULE = [
    "dynlib", "exportc", "exportcpp", "extern", "global", "header", "importc", "importcpp",
    "importjs", "importobjc", "threadvar",
  ]
    ## Pragmas binding name at module level alone, or across foreign boundary, never in routine.
  KEYWORDS_MODULE = ["converter", "export", "from", "import", "include", "method"]
    ## Keywords opening statement module level holds alone, or bringing what routine may not
    ##   hold, as `include` brings exported declarations.
  ROUTINE_ENTRY* = "main"  ## Routine entry block calls (V.10).


type
  BlockEntry* = object
    ## Define entry block of module, bindings it holds, and why fix cannot move its body (V.10).
    head: int  ## Zero-based line of `when isMainModule:`; `-1` where none is read.
    first: int  ## Zero-based first line of body, leading blank lines left out.
    last: int  ## Zero-based last line of body; comment opening line below it stays below block.
    indent: int  ## Indent of body's first line of code.
    bindings*: seq[(int, string)]  ## One-based line and name of each binding block holds.
    refusal*: string  ## Why fix leaves block to hand; empty where body moves into `proc main`.


func blockEntry*(source: string): BlockEntry =
  ## Read entry block of module, each binding it holds, and why fix cannot move its body into
  ##   `proc main` (V.10): more than one block, guard beyond `isMainModule`, pragma or statement
  ##   no routine holds, export marker, `quit` with value at block's own indent, or `main` taken.
  ##   Block binding nothing reads no refusal, since nothing moves.
  result.head = -1
  for d in source.declarations:
    if d.kind == NameKind.Binding and d.reach == Reach.Entry: result.bindings.add (d.line, d.name)
  if result.bindings.len == 0: return
  let
    lines = source.split('\n')
    code = source.codeOnly.split('\n')
    tokens = source.tokens
    partners = tokens.partners
    starts = source.lineStarts
  var heads: seq[int]
  for i, line in code:
    if line.indentOf == 0 and line.identifierAt(0) == "when" and "isMainModule" in line:
      heads.add i
  if heads.len != 1:
    result.refusal = "module holds `" & $heads.len & "` entry blocks"
    return
  result.head = heads[0]
  if code[result.head].strip != MAIN_GUARD:
    result.refusal = "`" & code[result.head].strip & "` guards more than `isMainModule`"
    return

  # Body runs to first line of code at indent 0; comment opening its line there stays below.
  var stop = result.head + 1
  while stop < code.len and (code[stop].strip.len == 0 or code[stop].indentOf > 0): inc stop
  result.first = result.head + 1
  while lines[result.first].strip.len == 0: inc result.first
  for t in tokens:
    if t.line <= result.head or t.line >= stop: continue
    if t.kind == TokenKind.Comment and t.first == starts[t.line]: continue
    result.last = max(result.last, t.lastLine(source))
  for i in result.first .. result.last:
    if code[i].strip.len == 0: continue
    result.indent = code[i].indentOf
    break

  # Refuse what routine cannot hold, or would read otherwise than block.
  for k, t in tokens:
    if t.line < result.first or t.line > result.last: continue
    if t.kind == TokenKind.Open and t.spelling(source) == "{." and partners[k] > k:
      for m in k + 1 ..< partners[k]:
        let word = tokens[m].spelling(source)
        if tokens[m].kind == TokenKind.Word and word in PRAGMAS_MODULE:
          result.refusal = "`{." & word & ".}` binds at module level alone"
          return
    let is_marker = t.kind == TokenKind.Operator and t.spelling(source) == "*" and k > 0 and
      tokens[k - 1].kind == TokenKind.Word and tokens[k - 1].after == t.first
    if is_marker:
      result.refusal = "export marker of `" & tokens[k - 1].spelling(source) &
        "` stands at module level alone"
      return
  for i in result.first .. result.last:
    if code[i].strip.len == 0: continue
    let
      word = code[i].identifierAt(0)
      rest = code[i].strip[word.len .. ^1].strip
    if word in KEYWORDS_MODULE:
      result.refusal = "`" & word & "` stands at module level alone"
      return
    if code[i].indentOf == result.indent and word == "quit" and rest notin ["", "()"]:
      result.refusal = "`quit` at block's own indent returns value, which `quit main()` would carry"
      return
  for t in tokens:
    if t.kind == TokenKind.Word and t.spelling(source).identity == ROUTINE_ENTRY:
      result.refusal = "`" & t.spelling(source) & "` stands in module already"
      return


func fixBlockEntry*(path, source: string): Fix =
  ## Move body of entry block into `proc main` above block, documented `TODO: Document.` (VI.1),
  ##   and leave block calling `main()` (V.10). Block whose move `blockEntry` refuses stays.
  ##   Body keeps its lines and indent, since block and routine indent body alike.
  let entry = source.blockEntry
  result.source = source
  if entry.bindings.len == 0 or entry.refusal.len > 0: return
  let
    lines = source.split('\n')
    margin = ' '.repeat(entry.indent)
  var shaped: seq[string]

  template keep(i: int) =
    shaped.add lines[i]
    result.origin.add i + 1

  template insert(line: string) =
    shaped.add line
    result.origin.add 0

  for i in 0 ..< entry.head: keep(i)
  insert "proc " & ROUTINE_ENTRY & "() ="
  insert margin & "## TODO: Document."
  for i in entry.first .. entry.last: keep(i)
  insert ""
  insert ""
  keep(entry.head)
  insert margin & ROUTINE_ENTRY & "()"
  for i in entry.last + 1 ..< lines.len: keep(i)
  result.source = shaped.join("\n")
  for (line, _) in entry.bindings: result.fixed.add initReport(path, line, Rule.EntryBlock)
