## Split Nim source into definitions, so page shows change per definition, its body apart.
##   Definition is routine, member of type or constant section, import, test, or other
##     statement, at top level or under `when` and `suite` alone. Head is its signature, read
##     while its brackets stay open; doc is comment lines after head; body is rest, indented
##     under head. Leading doc comment of file is one definition too.
##   Comment, section marker, `when`, `suite` and blank line belong to no definition; page diffs
##     them as other lines, so every line of file reaches page.
##   Two versions of file pair definitions by context, kind and name: same head first, then in
##     order. So overloads pair, and renamed definition reads removed and added.
##
##   Cost: string or comment that spans lines, and bracket inside char literal, misread depth
##     of head; library holds neither in any signature.

{.experimental: "strictFuncs".}

import std/strutils


type
  Definition* = object  ## Define one definition of Nim source.
    kind*: string  ## Word opening it, as `func` or `type`; `statement` for any other.
    name*: string  ## Name it declares, as `⊛`; head of statement for any other.
    context*: string  ## `when` and `suite` lines it sits under, joined by ` / `.
    first*: int  ## Index of its first line in file, from zero.
    head*, doc*, body*: seq[string]  ## Signature, doc comment lines after it, and rest.
  Paired* = object  ## Define one definition as two versions hold it.
    before*, after*: int  ## Index in each version; -1 where version lacks it.


const
  KEYWORDS_ROUTINE = ["func", "proc", "iterator", "template", "macro", "method", "converter"]
    ## Words opening routine.
  KEYWORDS_SECTION = ["type", "const", "let", "var"]  ## Words opening section of members.
  KEYWORDS_IMPORT = ["import", "export", "include", "from"]  ## Words opening import.
  KEYWORDS_CONTAINER = ["when", "elif", "else", "suite"]
    ## Words opening block whose children are definitions of their own.


func indentOf(line: string): int =
  ## Count spaces line opens with.
  line.len - line.strip(trailing = false).len


func wordOf(text: string): string =
  ## Read leading identifier of text; empty where text opens otherwise.
  for c in text:
    if c notin IdentChars: break
    result.add c


func depthAfter(text: string, depth: int): int =
  ## Count brackets left open after text, outside strings, backticks and comment.
  result = depth
  var is_quoted, is_ticked = false
  for index, c in text:
    if c == '"' and not is_ticked and (index == 0 or text[index-1] != '\\'):
      is_quoted = not is_quoted
    elif c == '`' and not is_quoted: is_ticked = not is_ticked
    elif is_quoted or is_ticked: continue
    elif c == '#': break
    elif c in {'(', '[', '{'}: inc result
    elif c in {')', ']', '}'}: dec result


func nameOf(text: string): string =
  ## Read name text declares after its keyword: backticked operator, else identifier.
  let rest = text.strip
  if rest.startsWith("`"):
    let close = rest.find('`', 1)
    return if close > 0: rest[1..<close] else: rest
  rest.wordOf


func definitionsOf*(lines: openArray[string]): seq[Definition] =
  ## Split lines into definitions, at top level and under `when` and `suite`, in order.

  func blockEnd(lines: openArray[string]; first, last, level: int): int =
    ## Find line after block opening at `first`: next line at `level` or less, blank aside.
    result = first + 1
    while result < last and
        (lines[result].strip.len == 0 or lines[result].indentOf > level):
      inc result

  func scan(lines: openArray[string]; first, last, level: int; context, member: string):
      seq[Definition] =
    ## Split lines `first ..< last` at `level` into definitions; `member` names kind of section.
    var index = first

    # Leading doc comment of file is one definition.
    if first == 0 and level == 0:
      while index < last and lines[index].startsWith("##"): inc index
      if index > 0:
        result.add Definition(
          kind: "doc", name: "module", first: 0, head: @lines[0..<index],
        )

    while index < last:
      let
        line = lines[index]
        stripped = line.strip
      if stripped.len == 0 or line.indentOf != level or stripped.startsWith("#"):
        inc index
        continue
      let
        word = stripped.wordOf
        code = stripped.split('#', 1)[0].strip  # Line less its comment.

      # Descend into block whose children are definitions: `when`, its branches, and `suite`.
      if member.len == 0 and word in KEYWORDS_CONTAINER and stripped.endsWith(":"):
        let finish = blockEnd(lines, index, last, level)
        var child = index + 1
        while child < finish and lines[child].strip.len == 0: inc child
        if child < finish:
          let label = stripped[0 ..< ^1].strip
          result.add scan(
            lines, child, finish, lines[child].indentOf,
            (if context.len > 0: context & " / " & label else: label), "",
          )
        index = finish
        continue

      # Descend into bare section keyword: each member is definition of section's kind.
      if member.len == 0 and word in KEYWORDS_SECTION and code == word:
        let finish = blockEnd(lines, index, last, level)
        var child = index + 1
        while child < finish and lines[child].strip.len == 0: inc child
        if child < finish:
          result.add scan(lines, child, finish, lines[child].indentOf, context, word)
        index = finish
        continue

      # Read head while brackets stay open, then doc lines, then body indented under head.
      var
        definition = Definition(context: context, first: index)
        depth = depthAfter(line, 0)
        at = index
      definition.head.add line
      while depth > 0 and at + 1 < last:
        inc at
        definition.head.add lines[at]
        depth = depthAfter(lines[at], depth)
      inc at
      if member.len > 0 and definition.head.len > 1:
        # Member whose value spans lines keeps its first line as head; value is body, in order.
        definition.body = definition.head[1 .. ^1]
        definition.head.setLen(1)
      while definition.body.len == 0 and at < last and lines[at].indentOf > level and
          lines[at].strip.startsWith("##"):
        definition.doc.add lines[at]
        inc at
      let finish = blockEnd(lines, at - 1, last, level)
      for body in at ..< finish: definition.body.add lines[body]
      while definition.body.len > 0 and definition.body[^1].strip.len == 0:
        definition.body.setLen(definition.body.len - 1)

      if member.len > 0:
        definition.kind = member
        definition.name = stripped.nameOf
      elif word in KEYWORDS_ROUTINE or word in KEYWORDS_SECTION or word == "test":
        definition.kind = word
        definition.name = stripped[word.len .. ^1].strip(chars = {' ', '"'}).nameOf
        if word == "test":
          let (open, close) = (stripped.find('"'), stripped.rfind('"'))
          if close > open: definition.name = stripped[open+1 ..< close]
      elif word in KEYWORDS_IMPORT:
        definition.kind = "import"
      else:
        definition.kind = "statement"
        definition.name = definition.head.join(" ").splitWhitespace.join(" ")
      result.add definition
      index = finish

  scan(lines, 0, lines.len, 0, "", "")


func pairDefinitions*(before, after: openArray[Definition]): seq[Paired] =
  ## Pair definitions of two versions, by context, kind and name; same head first, then in
  ##   order. Each removed definition stands after pair it followed in `before`.

  func keyOf(definition: Definition): string =
    ## Join what pairs definition: context, kind and name.
    definition.context & "\0" & definition.kind & "\0" & definition.name

  func headOf(definition: Definition): string =
    ## Fold whitespace of head, so layout alone pairs no head apart.
    definition.head.join(" ").splitWhitespace.join(" ")

  var
    partner_after = newSeq[int](after.len)
    is_taken = newSeq[bool](before.len)
  for index in 0..<after.len: partner_after[index] = -1
  for is_strict in [true, false]:
    for index, definition in after:
      if partner_after[index] >= 0: continue
      for other, candidate in before:
        if not is_taken[other] and candidate.keyOf == definition.keyOf and
            (not is_strict or candidate.headOf == definition.headOf):
          partner_after[index] = other
          is_taken[other] = true
          break

  # Walk `after` in order; first emit removed definitions that stood before next pair, so
  #   removal stands before addition in same gap, as in diff of lines.
  var next_before = 0
  for index in 0..<after.len:
    var bound = before.len
    for ahead in index..<after.len:
      if partner_after[ahead] >= 0:
        bound = partner_after[ahead]
        break
    while next_before < bound:
      if not is_taken[next_before]: result.add Paired(before: next_before, after: -1)
      inc next_before
    let other = partner_after[index]
    if other >= 0: next_before = max(next_before, other + 1)
    result.add Paired(before: other, after: index)
  while next_before < before.len:
    if not is_taken[next_before]: result.add Paired(before: next_before, after: -1)
    inc next_before
