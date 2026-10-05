## Derive TypeScript declarations of bridge's exports from bridge's own source, as text.
##   Driver compiles no project code, for reason `catalogue.nim` gives, so it reads
##   signatures rather than importing bridge. Module of its own, so suite reaches each
##   reading as it reaches catalogue's.
##   Rejected: hand-written `bridge.d.ts`, second home for each signature (Article I.4).
##   Pure, so suite reaches it on both backends.

{.experimental: "strictFuncs".}

import std/strutils



#[ Declarations ]#

func typeScriptOf(nim_type: string): string =
  ## Map Nim type at bridge boundary onto its TypeScript spelling.
  ##   `FlatBuffer` is opaque handle on JS `Float32Array`, never constructed in Nim; every
  ##   `seq` reaches JS as plain array, since JS backend boxes elements.
  case nim_type.strip
  of "cint", "cfloat", "float", "float32", "int": "number"
  of "bool": "boolean"
  of "cstring", "string": "string"
  of "FlatBuffer": "Float32Array"
  of "seq[cstring]", "seq[string]": "string[]"
  of "seq[cint]", "seq[int]", "seq[float]", "seq[float32]": "number[]"
  of "": "void"
  else: nim_type.strip


func typeOfLiteral(literal: string): string =
  ## Read Nim type that literal default fixes (Article X.12); empty where it fixes none.
  ##   Named constant fixes none, so its parameter states type and never reaches here.
  ##   `none(T)` reads empty too: no `Option` crosses bridge.
  let bare = literal.strip
  if bare in ["false", "true"]: return "bool"
  if bare.startsWith('"'): return "string"
  if bare.startsWith("default(") and bare.endsWith(")"): return bare["default(".len .. ^2]
  let unsigned = bare.strip(trailing = false, chars = {'+', '-'})
  if unsigned.len == 0 or unsigned[0] notin Digits: return ""
  if unsigned.allCharsInSet(Digits + {'_'}): return "int"
  if unsigned.allCharsInSet(Digits + {'+', '-', '.', 'E', '_', 'e'}): return "float"
  ""


func signatureAt*(lines: openArray[string], index: int): string =
  ## Join declaration ending at `index`, i.e. walk back to its `proc` or `func` keyword.
  ##   Signatures wrap across lines, so line carrying pragma is rarely whole declaration.
  var start = index
  while start >= 0 and
      not (lines[start].startsWith("proc ") or lines[start].startsWith("func ")):
    dec start
  if start < 0: return ""
  var parts: seq[string]
  for i in start..index: parts.add lines[i].strip
  parts.join(" ").split("{.exportc")[0].strip


func declarationOf*(signature: string): string =
  ## Render one TypeScript declaration from one Nim signature; empty where unparsable.
  let opened = signature.find('(')
  if opened < 0: return ""
  let
    name = signature[0..<opened].split(' ')[^1].strip
    closed = signature.rfind(')')
  if closed < opened: return ""

  # Nim lets one group carry several types (`a, b: int, c: float`) and lets several names
  #   share one (`a, b: int`), so names accumulate until fragment states type, and that
  #   type covers every name waiting.
  var rendered, waiting: seq[string]
  for group in signature[opened+1..<closed].split(';'):
    for fragment in group.split(','):
      let
        stated_at = fragment.find(':')
        defaulted_at = fragment.find('=')
        is_untyped = defaulted_at >= 0 and (stated_at < 0 or defaulted_at < stated_at)
      if stated_at < 0 and not is_untyped:
        if fragment.strip.len > 0: waiting.add fragment.strip
        continue
      # Default value belongs to declaration, never to type, and never reaches page.
      #   Nim applies it to Nim caller alone: JS call omitting argument passes `undefined`,
      #   which proc then compares and computes with. So every parameter is required on
      #   page, and omission fails type check rather than at run time; see
      #   `bridge.MARKER_SHAPED`.
      #   Literal default states no type, since it fixes one (Article X.12), so type is read
      #   from literal.
      let nim_type =
        if is_untyped: fragment[defaulted_at+1 .. ^1].typeOfLiteral
        elif defaulted_at > stated_at: fragment[stated_at+1..<defaulted_at]
        else: fragment[stated_at+1 .. ^1]
      if nim_type.strip.len == 0: return ""
      waiting.add fragment[0..<(if is_untyped: defaulted_at else: stated_at)].strip
      for name in waiting:
        rendered.add name & ": " & nim_type.typeScriptOf
      waiting.setLen 0
  # Name left without type: declaration short of it lets page omit that argument, and
  #   `undefined` then passes type check. Absent declaration fails at each call instead.
  if waiting.len > 0: return ""

  let
    tail = signature[closed+1 .. ^1].strip
    returned = if tail.startsWith(":"): tail[1 .. ^1].typeScriptOf else: "void"
  "declare function " & name & "(" & rendered.join(", ") & "): " & returned & ";"


func recordOf*(lines: openArray[string], name: string): string =
  ## Render TypeScript interface from Nim object type of `name`; empty where absent.
  ##   Read from bridge rather than kept beside it, so record crossing boundary has one
  ##   home and no second copy can drift from it (Article I.4).
  ##   Found as `type` of its own or as member of `type` section; bridge holds every type
  ##   in one section (Article X.6).
  var
    start = -1
    indent_declared = 0
  for i, line in lines:
    let
      indent = line.len - line.strip(trailing = false).len
      declared = if line.startsWith("type "): line["type ".len .. ^1] else: line[indent .. ^1]
    if declared.startsWith(name & " = object") or declared.startsWith(name & "* = object"):
      start = i
      indent_declared = if line.startsWith("type "): 0 else: indent
      break
  if start < 0: return ""

  var fields: seq[string]
  for i in start + 1 ..< lines.len:
    let line = lines[i]
    if line.strip.len > 0 and line.len - line.strip(trailing = false).len <= indent_declared:
      break
    let bare = line.strip
    if bare.len == 0 or bare.startsWith("##"): continue
    let
      stated = bare.split("##")[0].strip
      split_at = stated.find(':')
    if split_at < 0: continue
    let rendered_type = stated[split_at+1 .. ^1].typeScriptOf
    for field in stated[0..<split_at].split(','):
      if field.strip.len == 0: continue
      fields.add "  " & field.strip & ": " & rendered_type & ";"
  if fields.len == 0: return ""
  "interface " & name & " {\n" & fields.join("\n") & "\n}\n"
