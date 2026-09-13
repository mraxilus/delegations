## Read operator surface library's own sources export, so catalogue is held to it, not to memory.
##   Library defines generated operators as `defineOperator(symbols = "∧", ...)` calls,
##   hand-written ones as backticked `func`/`template` declarations, and named aliases as
##   plain exported funcs in its umbrella, each under `when IS_RIGID:` or
##   `when IS_CONFORMAL:` where algebra decides. Reader here tracks those blocks by
##   indentation, so one call answers what one algebra exports.
##   Pure string functions: suite calls them on `staticRead` of restored sources at compile
##   time, and on fixtures it writes itself.
##
##   Cost: reader knows two gates by name and treats every other `when` as transparent, so
##     gate spelled another way would leak declarations into wrong algebra; suites cover
##     both gates and `else:` on fixtures.

{.experimental: "strictFuncs".}

import std/strutils


type Gate {.pure.} = enum
  ## Define which algebras block of source applies to.
  Any, Rigid, Conformal


type Frame = object
  ## Define one open `when` block: its indent and which algebra it admits.
  indent: int
  gate: Gate


func indentOf(line: string): int =
  ## Count leading spaces of line.
  for c in line:
    if c != ' ': break
    inc result


func gateOf(stripped: string): Gate =
  ## Read gate named by `when` line, `Any` for every other `when`.
  if stripped.startsWith("when IS_RIGID:"): Gate.Rigid
  elif stripped.startsWith("when IS_CONFORMAL:"): Gate.Conformal
  else: Gate.Any


func flipped(gate: Gate): Gate =
  ## Read gate `else:` opens under given `when`.
  case gate
  of Gate.Rigid: Gate.Conformal
  of Gate.Conformal: Gate.Rigid
  of Gate.Any: Gate.Any


func admits(frames: seq[Frame]; is_conformal: bool): bool =
  ## Decide whether innermost named gate admits algebra.
  for i in countdown(frames.high, 0):
    case frames[i].gate
    of Gate.Rigid: return not is_conformal
    of Gate.Conformal: return is_conformal
    of Gate.Any: discard
  true


func between(s, opening, closing: string): string =
  ## Read text between first `opening` and next `closing`; empty where either is absent.
  let start = s.find(opening)
  if start < 0: return ""
  let after = start + opening.len
  let stop = s.find(closing, after)
  if stop < 0: return ""
  s[after ..< stop]


iterator admitted(source: string; is_conformal: bool): string =
  ## Yield stripped lines algebra admits, tracking `when` gates by indentation.
  var frames: seq[Frame]
  for line in source.splitLines:
    let stripped = line.strip
    if stripped.len == 0 or stripped.startsWith("#"): continue
    let indent = line.indentOf
    while frames.len > 0 and indent <= frames[^1].indent:
      # Line at or above block's indent closes it, unless it is that block's `else:`.
      if indent == frames[^1].indent and stripped.startsWith("else:"):
        frames[^1].gate = frames[^1].gate.flipped
        break
      frames.setLen(frames.len - 1)
    if stripped.startsWith("else:") and frames.len > 0 and indent == frames[^1].indent:
      continue
    if stripped.startsWith("when ") and stripped.endsWith(":"):
      frames.add Frame(indent: indent, gate: stripped.gateOf)
      continue
    if frames.admits(is_conformal): yield stripped



#[ Surface ]#

func symbolsIn*(source: string; is_conformal: bool): seq[string] =
  ## Read operator symbols source defines for algebra, generated and hand-written alike.
  ##   Generated: `symbols = "∧",` inside `defineOperator`. Hand-written: backticked name
  ##   of exported `func` or `template`. Order is first appearance; duplicates dropped.
  for line in source.admitted(is_conformal):
    var symbol = ""
    if line.startsWith("symbols = "):
      symbol = line.between("\"", "\"")
    elif line.startsWith("func `") or line.startsWith("template `"):
      symbol = line.between("`", "`")
    if symbol.len > 0 and symbol notin result: result.add symbol


func aliasesIn*(source: string; is_conformal: bool): seq[string] =
  ## Read names of exported plain funcs source declares for algebra, i.e. named aliases.
  ##   Order is first appearance; overloads collapse to one name.
  for line in source.admitted(is_conformal):
    if not line.startsWith("func "): continue
    let stop = line.find('*')
    if stop < 5: continue
    let name = line[5 ..< stop]
    if name.len == 0 or name[0] == '`': continue
    if name notin result: result.add name
