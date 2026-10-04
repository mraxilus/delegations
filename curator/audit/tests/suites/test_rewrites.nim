## Hold edits and rename planner to their contract: each edit applies to source as given, in
##   any order; rename is planned whole from what semantic pass resolves, or refused whole with
##   reason, never in part.

{.experimental: "strictFuncs".}

import std/[algorithm, strutils, tables, unittest]
import ../../src/[rewrites, symbols, tokens]


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


  test "rename spans each site by its own spelling, which Nim reads as declared name":
    let
      declaring = "proc f*(tmp_dir: int): int = tmpDir + 1\n"
      rename = Rename(
        path: "p/a.nim",
        line: 1,
        column: 8,
        name: "tmp_dir",
        renamed: "temporary_directory",
        rule: "abbreviation (V.6)",
      )
      parameter =
        Symbol(kind: "skParam", name: "a.f.tmp_dir", file: "/r/p/a.nim", line: 1, column: 8)
    var spelled = initTable[string, Answer]()
    spelled["p/a.nim"] = Answer(path: "p/a.nim")
    for site in [(1, 8), (1, 29)]: spelled["p/a.nim"].symbols[site] = parameter
    spelled["p/a.nim"].globals["temporary_directory"] = @[]
    let plan = planRename(rename, [("p/a.nim", declaring)], spelled, initTable[string, seq[int]]())
    check plan.refusal.len == 0
    check declaring.applied(plan.edits["p/a.nim"]) ==
      "proc f*(temporary_directory: int): int = temporary_directory + 1\n"  # `tmpDir` whole


  test "rename Nim reads as same name skips presence and shadow, since it changes no reading":
    let
      declaring = "proc f*(localValue: int): int = localValue\n"
      other = "let local_value = 2\n"
      rename = Rename(
        path: "p/a.nim",
        line: 1,
        column: 8,
        name: "localValue",
        renamed: "local_value",
        rule: "parameter case (V.1)",
      )
      parameter =
        Symbol(kind: "skParam", name: "a.f.localValue", file: "/r/p/a.nim", line: 1, column: 8)
      global = Symbol(kind: "skLet", name: "b.local_value", file: "/r/p/b.nim", line: 1, column: 4)
    var same = initTable[string, Answer]()
    same["p/a.nim"] = Answer(path: "p/a.nim")
    for site in [(1, 8), (1, 32)]: same["p/a.nim"].symbols[site] = parameter
    same["p/a.nim"].globals["local_value"] = @[global]  # one name to Nim already
    same["p/b.nim"] = Answer(path: "p/b.nim")
    same["p/b.nim"].symbols[(1, 4)] = global
    let plan = planRename(
      rename,
      [("p/a.nim", declaring), ("p/b.nim", other)],
      same,
      initTable[string, seq[int]](),
    )
    check plan.refusal.len == 0  # V.1
    check declaring.applied(plan.edits["p/a.nim"]) ==
      "proc f*(local_value: int): int = local_value\n"  # V.1
    check "p/b.nim" notin plan.edits  # other symbol keeps its spelling


  test "rename to keyword or to implicit `result` is refused, as compiler reads either otherwise":
    for (renamed, refusal) in [
      ("type", "`type` is keyword"),
      ("t_ype", "`t_ype` is keyword"),
      ("result", "`result` names implicit result of routine"),
    ]:
      var rename = RENAME
      rename.renamed = renamed
      let files = [("p/a.nim", DECLARING), ("p/b.nim", USING)]
      check planRename(rename, files, answers(), initTable[string, seq[int]]()).refusal == refusal
    check not "Type".isKeyword  # first letter exact, so `Type` is name


  test "rename is refused whole where any site, or new name, cannot be proved":
    var unresolved = answers()
    unresolved["p/a.nim"].reason = "undeclared identifier"
    check planOf(answers = unresolved).refusal == "declaring file does not compile on its pin"
    var unknown = answers()
    unknown["p/b.nim"].symbols.del((3, 7))
    check planOf(answers = unknown).refusal == "`p/b.nim:3` resolves to no symbol"
    var elsewhere = answers()
    elsewhere["p/a.nim"].symbols[(1, 8)].line = 9  # site uses name declared on other line
    check planOf(answers = elsewhere).refusal == "`p/a.nim:1` names symbol declared elsewhere"
    var shadowing = answers()
    shadowing["p/a.nim"].globals["context"] = @[Symbol(kind: "skProc", name: "m.context")]
    check planOf(answers = shadowing).refusal == "`context` would shadow `m.context`"
    let present = DECLARING & "let context = 1\n"
    check planOf(present).refusal == "`context` already stands in `p/a.nim`"
    check planOf(fenced = {"p/a.nim": @[2]}.toTable).refusal == "`p/a.nim:3` is fenced (X.1)"
    let wide = DECLARING.replace("  ctx + 1", "  ctx + " & "1".repeat(92))
    check planOf(wide).refusal.endsWith("would cross 100 characters")
    check planOf(wide).edits.len == 0  # nothing planned in part
