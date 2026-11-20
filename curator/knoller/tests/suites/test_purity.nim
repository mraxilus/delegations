## Replicate STYLE.md §1 on pure routines, as `purity.nim` reads it: `proc` whose body shows no
##   effect is candidate, compiler proves each as `func` under every configuration, and fixer
##   writes `func` for each it proves.
##   Compiler is real here: one building this suite (`getCurrentCompilerExe`), as
##   `test_symbols.nim` takes `nimsuggest` beside it.

{.experimental: "strictFuncs".}

import std/[os, sequtils, strutils, tables, tempfiles, unittest]
import ../../src/knoller/[edits, purity, rules]


const
  MODULE_ALGEBRA = """
{.experimental: "strictFuncs".}

import std/[sequtils, strutils, sugar, tables]

type
  BasisDigits = distinct string  ## Define digit representation of basis.
  Algebra = seq[seq[BasisDigits]]  ## Define data structure for generating algebras.

func `&`(a, b: BasisDigits): BasisDigits {.borrow, compileTime.}

func toBasisDigits(digits: string): BasisDigits {.compileTime.} =
  ## Convert from string to digit representation of basis.
  BasisDigits(digits)

func constructAlgebra(dimensions: int): Algebra {.compileTime.} =
  ## Construct algebra for `dimensions`-dimensional PGA.

  proc generateUpTo(algebras: var Table[int, Algebra], dimensions: int) {.compileTime.} =
    ## Populate missing algebras up to `dimensions`-dimensional PGA.
    ##   Limited to 9 dimensions as relies on single digit representation.
    var dimension = 5
    while dimension <= dimensions:
      let prev = algebras[dimension-1]
      var curr = Algebra(@[@[""]])

      # Construct non-(anti)scalar bases.
      let digit_new = BasisDigits($dimension)
      for i in 1..<len(prev):
        curr.add(prev[i] & prev[i-1].map(digits => digits & digit_new))

      # Construct antiscalar.
      let antiscalar = (
        collect(for i in 1..dimension: char(ord('0') + i))
        .join
        .toBasisDigits
      )
      curr.add(@[antiscalar])

      # Update algebra table.
      algebras[dimension] = curr
      dimension += 1

  var algebras = {4: Algebra(@[@[""], @["1"]])}.toTable
  algebras.generateUpTo(dimensions)
  algebras[dimensions]
"""
    ## `generateUpTo` of `pga/algebra.nim:172` of PGA library at `3d9696e`, as found, in module
    ##   holding what it names; rule 11 of #443 takes it as one report of library.
  SITE_GENERATE = (18, 2)  ## Line and column of `proc` of `generateUpTo` in `MODULE_ALGEBRA`.
  DEFINES_NONE: seq[string] = @[]  ## Configuration naming no define, as project alone compiles.
  STORE = """
import std/[locks, sets, tables]

type Store[T] = object  ## Define answers threads share.
  lock: Lock
  done: Table[string, T]
  busy: HashSet[string]

proc claimed[T](store: var Store[T], key: string): bool =
  ## Whether `key` was neither answered nor being answered, and caller now answers it.
  withLock store.lock:
    if key in store.done or key in store.busy: return false
    store.busy.incl key
  true
"""
    ## `claimed` of `simulation/walk.nim:142` of `dance_ontology`, as found: compiler checks it as
    ##   `func`, and its answer depends on order of threads (rule 11 of #443).
  EFFECTS = [
    ("output", "echo x"),
    ("output", "debugEcho x"),
    ("output", "stdout.write $x"),
    ("input", "x = stdin.readLine.len"),
    ("files", "x = readFile(\"a.txt\").len"),
    ("clock", "x = int(epochTime())"),
    ("clock", "x = now().second"),
    ("random numbers", "x = rand(3)"),
    ("random numbers", "x = int(gauss(0.0, 1.0))"),
    ("environment", "x = getEnv(\"HOME\").len"),
    ("process", "x = execProcess(\"ls\").len"),
    ("address", "let p = addr x"),
    ("lock", "withLock lock:\n    inc x"),
    ("lock", "acquire(lock)"),
    ("wait", "wait(cond, lock)"),
    ("signal", "signal(cond)"),
    ("signal", "broadcast(cond)"),
  ]
    ## Kind of effect, and statement naming it, one for each kind §1 and ruling name.


func site(source, text: string): (int, int) =
  ## Read line and column of first `text` in source.
  let at = source.find(text)
  (source[0 ..< at].count('\n') + 1, at - source[0 ..< at].rfind('\n') - 1)


proc proven(source: string; configurations: openArray[seq[string]] = [DEFINES_NONE]): Pures =
  ## Prove candidates of source, as module of its own in temporary directory, by real compiler.
  let directory = createTempDir("knoller_", "_purity")
  defer: removeDir(directory)
  writeFile(directory / "a.nim", source)
  let sites = candidatesPure([("a.nim", source)]).getOrDefault("a.nim")
  provenPure(source, sites, directory, getCurrentCompilerExe(), configurations)



suite "Style §1":
  test "proc whose body shows no effect is candidate, as `generateUpTo` of PGA library is":
    # Case: `pga/algebra.nim:172` of PGA library at `3d9696e`, nested in `constructAlgebra`;
    #   it writes its `var` parameter and its locals alone, which `strictFuncs` admits.
    check candidatesPure([("pga/algebra.nim", MODULE_ALGEBRA)]) ==
      {"pga/algebra.nim": @[SITE_GENERATE]}.toTable


  test "proc naming effect stays, of each kind §1 and ruling name":
    # Domain: output, input, files, clock, random numbers, environment, process, address, lock,
    #   wait and signal, one statement each; same proc without it is candidate.
    let pure = "proc f(x: var int, lock: var Lock, cond: var Cond) =\n  inc x\n"
    check candidatesPure([("a.nim", pure)]).getOrDefault("a.nim") == @[(1, 0)]
    for (kind, statement) in EFFECTS:
      let source = pure & "  " & statement & "\n"
      checkpoint kind & ": " & statement
      check candidatesPure([("a.nim", source)]).getOrDefault("a.nim").len == 0


  test "proc taking lock stays, as `claimed` of `dance_ontology` does":
    # Case: `simulation/walk.nim:142` of `dance_ontology`; compiler checks it as `func`, but
    #   another thread sees each lock, so ruling of rule 11 (#443) counts it as effect.
    check candidatesPure([("simulation/walk.nim", STORE)]).len == 0
    let unlocked = STORE.replace("  withLock store.lock:\n    if", "  block:\n    if")
    check candidatesPure([("simulation/walk.nim", unlocked)])["simulation/walk.nim"] ==
      @[unlocked.site("proc claimed")]


  test "proc reading global var stays, and proc reading global let or const is candidate":
    for (binding, count) in [("var", 0), ("let", 1), ("const", 1)]:
      let source = binding & " LIMIT = 3\n\nproc capped(x: int): int = min(x, LIMIT)\n"
      check candidatesPure([("a.nim", source)]).getOrDefault("a.nim").len == count
    let other = ("b.nim", "var COUNTER* = 0\n")  # global of another module of project
    check candidatesPure([("a.nim", "proc f(): int = COUNTER\n"), other]).len == 0


  test "proc calling project proc that stays stays, and proc calling candidate is candidate":
    # Domain: chain of three procs, to any depth; last echoes, or computes alone.
    for (last, count) in [("echo x", 0), ("discard x + 1", 3)]:
      let source = "proc a(x: int) = b(x)\nproc b(x: int) = c(x)\nproc c(x: int) =\n  " & last &
        "\n"
      check candidatesPure([("a.nim", source)]).getOrDefault("a.nim").len == count
    let across = [("a.nim", "proc a(x: int) = b(x)\n"), ("b.nim", "proc b*(x: int) = echo x\n")]
    check candidatesPure(across).len == 0  # proc of another module of project stays too


  test "proc calling routine project declares nowhere, and pure list holds not, stays":
    for (call, count) in [
      ("discard frobnicate(x)", 0),
      ("discard x.frobnicate", 0),
      ("frobnicate x", 0),
      ("discard sqrt(float(x)) + float(x.len)", 1),
      ("discard ($x).strip.split(',').mapIt(it.len)", 1),
    ]:
      let source = "proc f(x: seq[int]) =\n  " & call & "\n"
      checkpoint call
      check candidatesPure([("a.nim", source)]).getOrDefault("a.nim").len == count


  test "forward, foreign, emitted, substituted and routine-taking proc, lambda and type are none":
    for source in [
      "proc f(x: int): int\n",  # forward declaration
      "proc f(x: cint): cint {.importc, header: \"a.h\".}\n",
      "macro m(): untyped =\n  result = quote do:\n    proc f(x: int): int = x\n",
      "template t() =\n  proc f(x: int): int = x\n",
      "proc f(g: proc (x: int): int, x: int): int = g(x)\n",
      "let f = proc (x: int): int = x\n",
      "type F = proc (x: int): int\n",
      "func f(x: int): int = x\n",  # already `func`
      "method f(x: RootObj): int {.base.} = 0\n",
      "iterator f(x: int): int = yield x\n",
      "converter f(x: int): float = float(x)\n",
    ]:
      checkpoint source
      check candidatesPure([("a.nim", source)]).len == 0
    check candidatesPure([("a.nim", "proc f*(x: int): int = x\n")])["a.nim"] == @[(1, 0)]


  test "compiler proves each candidate it checks as `func`, and refuses one it rejects":
    # Domain: candidate syntax passes and `strictFuncs` refuses, as write through `ref`.
    let source = MODULE_ALGEBRA &
      "\ntype Cell = ref object\n  x: int\n\nproc reset(cell: Cell) =\n  cell.x = 0\n"
    check candidatesPure([("a.nim", source)])["a.nim"].len == 2
    let pures = proven(source)
    check pures.reason.len == 0
    check pures.sites == @[SITE_GENERATE]


  test "candidate stays where any configuration refuses it, and none proves where no file checks":
    let source = "{.experimental: \"strictFuncs\".}\n\nproc f(p: ref int): int =\n" &
      "  when defined(knoller_effect):\n    p[] = 1\n  2\n"
    check proven(source, [DEFINES_NONE]).sites == @[(3, 0)]
    check proven(source, [DEFINES_NONE, @["-d:knoller_effect"]]).sites.len == 0
    check proven(source, [@["-d:knoller_effect"]]).sites.len == 0
    let broken = proven(source & "let y: int = \"a\"\n")  # checks clean in no configuration
    check broken.sites.len == 0 and broken.reason.contains("type mismatch")


  test "included file checks inside text of file including it":
    let
      directory = createTempDir("knoller_", "_purity")
      included = "proc f(c: Cell): int = c.x\n"  # `Cell` stands in includer alone
      sites = candidatesPure([("b.nim", included), ("a.nim", "type Cell = object\n  x: int\n")])
    defer: removeDir(directory)
    check sites["b.nim"] == @[(1, 0)]
    let
      nim = getCurrentCompilerExe()
      prefix = "{.experimental: \"strictFuncs\".}\ntype Cell = object\n  x: int\n"
    check provenPure(included, sites["b.nim"], directory, nim, [DEFINES_NONE], prefix = prefix)
      .sites == @[(1, 0)]
    check provenPure(included, sites["b.nim"], directory, nim, [DEFINES_NONE]).reason.len > 0


  test "check reports each `proc` compiler proves, and fix writes `func` off fenced line":
    let
      source = "proc f(x: int): int = x\nproc g(x: int): int = x\nlet h = 1\n"
      pures = Pures(sites: @[(1, 0), (2, 0), (3, 0)])  # last names no `proc`, so reads none
      found = checkPure("a.nim", source, pures)
    check found.mapIt(it.line) == @[1, 2]
    check found.allIt(it.rule == Rule.PureFunc)
    check found[0].message ==
      "Routine with no effect beyond its parameters is `func`; got `proc f`."
    let (edits, reports) = editsPure("a.nim", source, pures, [])
    check source.applied(edits) == "func f(x: int): int = x\nfunc g(x: int): int = x\nlet h = 1\n"
    check reports.mapIt(it.line) == @[1, 2]
    check editsPure("a.nim", source, pures, [0])[1].mapIt(it.line) == @[2]  # fenced line stays
    let held = [Edit(first: 2, after: 3, text: "o")]  # other fixer writes inside `proc`
    check editsPure("a.nim", source, pures, [], held)[1].mapIt(it.line) == @[2]
    check checkPure("a.nim", source, Pures(reason: "error", sites: @[(1, 0)])).len == 0
