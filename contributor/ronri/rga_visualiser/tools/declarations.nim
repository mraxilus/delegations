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
      let stated_at = fragment.find(':')
      if stated_at < 0:
        if fragment.strip.len > 0: waiting.add fragment.strip
        continue
      waiting.add fragment[0..<stated_at].strip
      # Default value belongs to declaration, never to type, and never reaches page.
      #   Nim applies it to Nim caller alone: JS call omitting argument passes `undefined`,
      #   which proc then compares and computes with. So every parameter is required on
      #   page, and omission fails type check rather than at run time; see
      #   `bridge.MARKER_SHAPED`.
      let
        stated = fragment[stated_at+1 .. ^1]
        defaulted = stated.find('=')
        rendered_type = (if defaulted >= 0: stated[0..<defaulted] else: stated).typeScriptOf
      for name in waiting:
        rendered.add name & ": " & rendered_type
      waiting.setLen 0

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
