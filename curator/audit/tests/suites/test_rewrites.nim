## Hold edits and rename planner to their contract: each edit applies to source as given, in
##   any order; rename is planned whole from what semantic pass resolves, or refused whole with
##   reason, never in part.

{.experimental: "strictFuncs".}

import std/[algorithm, strutils, tables, unittest]
import ../../src/[rewrites, symbols]


const
  DECLARING = "proc f*(ctx: int): int =\n  ## Read `ctx` back.\n  ctx + 1\n"
    ## File declaring parameter `ctx`, and naming it in its doc.
  USING = "import ./a\nlet ctx = 2\necho f(ctx)\n"
    ## File naming other symbol `ctx`, which rename leaves.
  RENAME = Rename(
    path: "p/a.nim",
    line: 1,
    column: 8,
    name: "ctx",
    renamed: "context",
    rule: "abbreviation (V.6)",
  )
    ## Rename of parameter `ctx` to `context`.


func answers(): Table[string, Answer] =
  ## Answer semantic pass gives both files: parameter in one, global in other.
  let
    parameter = Symbol(kind: "skParam", name: "a.f.ctx", file: "/r/p/a.nim", line: 1, column: 8)
    global = Symbol(kind: "skLet", name: "b.ctx", file: "/r/p/b.nim", line: 2, column: 4)
  result["p/a.nim"] = Answer(path: "p/a.nim")
  result["p/a.nim"].symbols[(1, 8)] = parameter
  result["p/a.nim"].symbols[(3, 2)] = parameter
  result["p/a.nim"].globals["context"] = @[]
  result["p/b.nim"] = Answer(path: "p/b.nim")
  result["p/b.nim"].symbols[(2, 4)] = global
  result["p/b.nim"].symbols[(3, 7)] = global


func planOf(
  declaring = DECLARING, answers = answers(), fenced = initTable[string, seq[int]]()
): Plan =
  ## Plan `RENAME` over both files.
  planRename(RENAME, [("p/a.nim", declaring), ("p/b.nim", USING)], answers, fenced)



suite "Internal: Rewrites":
  test "edits apply to source as given, in any order; insertions at one offset by rank":
    let
      source = "let v = x.float.int\n"
      edits = @[
        Edit(first: 8, after: 8, text: "float(", rank: -7),
        Edit(first: 9, after: 15, text: ")"),
        Edit(first: 8, after: 8, text: "int(", rank: -11),
        Edit(first: 15, after: 19, text: ")"),
      ]
    check source.applied(edits) == "let v = int(float(x))\n"  # outer opens first
    check source.applied(edits.reversed) == "let v = int(float(x))\n"  # order given is none
    check source.applied([Edit(first: 8, after: 9, text: "y")]) == "let v = y.float.int\n"
    check source.applied([]) == source


  test "rename asks every site of old name in scope, and globals of new name in declaring file":
    let queries = RENAME.queriesOf([("p/a.nim", DECLARING), ("p/b.nim", USING)])
    check queries.len == 2
    check queries[0].sites == @[(1, 8), (3, 2)] and queries[0].names == @["context"]
    check queries[1].sites == @[(2, 4), (3, 7)] and queries[1].names.len == 0


  test "rename writes declaration, each use resolving to it, and mention in backticks":
    let plan = planOf()
    check plan.refusal.len == 0
    check DECLARING.applied(plan.edits["p/a.nim"]) ==
      "proc f*(context: int): int =\n  ## Read `context` back.\n  context + 1\n"
    check "p/b.nim" notin plan.edits  # other symbol of same name stays
    check plan.lines == @[("p/a.nim", 1), ("p/a.nim", 3)]


  test "named argument and constructor field resolve through callee they name":
    let
      declaring = "proc f*(ctx: int): int = ctx\n"
      calling = "import ./a\nlet ctx = 2\necho f(ctx = ctx), g(ctx = 1)\n"
      routine = Symbol(kind: "skProc", name: "a.f", file: "/r/p/a.nim", line: 1, column: 5)
      other = Symbol(kind: "skProc", name: "b.g", file: "/r/p/b.nim", line: 9, column: 5)
      parameter = Symbol(kind: "skParam", name: "a.f.ctx", file: "/r/p/a.nim", line: 1, column: 8)
      global = Symbol(kind: "skLet", name: "b.ctx", file: "/r/p/b.nim", line: 2, column: 4)
      files = [("p/a.nim", declaring), ("p/b.nim", calling)]
    check RENAME.queriesOf(files)[1].sites == @[(2, 4), (3, 7), (3, 13), (3, 21), (3, 5), (3, 19)]
    var named = initTable[string, Answer]()
    named["p/a.nim"] = Answer(path: "p/a.nim")
    named["p/a.nim"].symbols[(1, 8)] = parameter
    named["p/a.nim"].symbols[(1, 25)] = parameter
    named["p/b.nim"] = Answer(path: "p/b.nim")
    for site in [(2, 4), (3, 13)]: named["p/b.nim"].symbols[site] = global
    named["p/b.nim"].symbols[(3, 5)] = routine  # `ctx =` of `f` names its parameter
    named["p/b.nim"].symbols[(3, 19)] = other  # `ctx =` of `g` names `g`'s own
    let plan = planRename(RENAME, files, named, initTable[string, seq[int]]())
    check plan.refusal.len == 0
    check calling.applied(plan.edits["p/b.nim"]) ==
      "import ./a\nlet ctx = 2\necho f(context = ctx), g(ctx = 1)\n"


  test "rename is refused whole where any site, or new name, cannot be proved":
    var unresolved = answers()
    unresolved["p/a.nim"].reason = "undeclared identifier"
    check planOf(answers = unresolved).refusal == "declaring file does not compile on its pin"
    var unknown = answers()
    unknown["p/b.nim"].symbols.del((3, 7))
    check planOf(answers = unknown).refusal == "`p/b.nim:3` resolves to no symbol"
    var shadowing = answers()
    shadowing["p/a.nim"].globals["context"] = @[Symbol(kind: "skProc", name: "m.context")]
    check planOf(answers = shadowing).refusal == "`context` would shadow `m.context`"
    let present = DECLARING & "let context = 1\n"
    check planOf(present).refusal == "`context` already stands in `p/a.nim`"
    check planOf(fenced = {"p/a.nim": @[2]}.toTable).refusal == "`p/a.nim:3` is fenced (X.1)"
    let wide = DECLARING.replace("  ctx + 1", "  ctx + " & "1".repeat(92))
    check planOf(wide).refusal.endsWith("would cross 100 characters")
    check planOf(wide).edits.len == 0  # nothing planned in part
