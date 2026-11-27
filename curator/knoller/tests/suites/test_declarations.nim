## Hold that declaration carries doc (Article VI.1), and where it states its doc and its type
##   (VI.9, X.12; STYLE.md §5): each breach is reported and fixed; doc of several lines, routine
##   doc and default literal of other type are neither; fix changes nothing else, and nothing
##   second time.
##   Missing doc is held over each kind and shape of declaration, and over what passes. Cases
##     held: value or signature of this repository running past its first line, each named
##     where it stands.

{.experimental: "strictFuncs".}

import std/[json, os, osproc, sequtils, strutils, tempfiles, unittest]
import ../../src/knoller/[declarations, reports, tokens]


func fixed(source: string): string =
  ## Fix docs, then defaults, of source, as `koch fix` does.
  let docs = fixDocs("a.nim", source).source
  fixDefaults("a.nim", docs).source


func isSettled(source: string): bool =
  ## Decide whether source reports no declaration finding and fixes to itself again.
  (checkDocs("a.nim", source) & checkDefaults("a.nim", source)).len == 0 and
    source.fixed == source


func documented(source: string): string =
  ## Write missing docs of source, as `koch fix` does.
  fixDocsMissing("a.nim", source).source


func isDocumented(source: string): bool =
  ## Decide whether source reports no missing doc, and fix writes nothing to it.
  checkDocsMissing("a.nim", source).len == 0 and source.documented == source


proc docsRead(source: string): tuple[module: string, docs: seq[(string, string)]] =
  ## Read doc of module and of each entry, as `nim jsondoc` of compiler building suite reads
  ##   source under one-line doc of module.
  let directory = createTempDir("docs", "")
  defer: removeDir(directory)
  writeFile(directory / "a.nim", "## Module.\n\n" & source)
  let (output, code) = execCmdEx(getCurrentCompilerExe().quoteShell &
    " jsondoc --hints:off --warnings:off -o:" & quoteShell(directory / "a.json") & " " &
    quoteShell(directory / "a.nim"))
  doAssert code == 0, "Compiler refused source; got `" & output & "`."
  let page = parseFile(directory / "a.json")
  result.module = page{"moduleDescription"}.getStr
  for entry in page{"entries"}.getElems:
    result.docs.add (entry{"name"}.getStr, entry{"description"}.getStr)


func spellingsCode(source: string): seq[string] =
  ## Read spelling of each token of source but comments, in order.
  for t in source.tokens:
    if t.kind != KindToken.Comment: result.add t.spelling(source)



suite "Declarations":
  test "one-line doc of type, field, binding and enum member joins its line where it fits":
    let breach = "type\n  Kind {.pure.} = enum\n    ## Kind of thing.\n    A\n      ## First.\n" &
      "    B = 2\n      ## Second.\n\n  Obj* = object\n    ## Holder.\n    x*: int\n" &
      "      ## Count.\n\nconst\n  N* = 3\n    ## Size.\nlet m = 1\n  ## Mass.\n"
    check checkDocs("a.nim", breach).mapIt(it.line) == @[2, 4, 6, 9, 11, 15, 17]
    check breach.fixed == "type\n  Kind {.pure.} = enum  ## Kind of thing.\n    A  ## First.\n" &
      "    B = 2  ## Second.\n\n  Obj* = object  ## Holder.\n    x*: int  ## Count.\n\n" &
      "const\n  N* = 3  ## Size.\nlet m = 1  ## Mass.\n"
    check breach.fixed.isSettled
    check fixDocs("a.nim", breach).fixed[0].rule == Rule.PositionDoc


  test "doc that cannot join takes next line, one level in; trailing doc too wide moves there":
    let
      value = "  NAME = \"" & "x".repeat(60) & "\""
      doc = "## " & "y".repeat(40)
      settled = "const\n" & value & "\n    " & doc & "\n"
    check ("const\n" & value & "\n      " & doc & "\n").fixed == settled  # re-indented
    check ("const\n" & value & "  " & doc & "\n").fixed == settled  # 116 runes split
    check settled.isSettled


  test "doc of several lines, routine doc, and line that is no declaration stay":
    for kept in [
      "const\n  N = 3\n    ## Size,\n    ##   in units.\n",
      "proc f() =\n  ## Do.\n  discard\n",
      "func f(): int = 1\n  ## One.\n",
      "const\n  N = a +\n    b\n    ## Sum.\n",
      "const\n  T = [\n    1,\n  ]\n    ## Table.\n",
      "const N = 3  # Why.\n  ## Size.\n",
      "proc f() =\n  let x = 1\n  ## Next.\n",
      "const N = 3  ## Size,\n             ##   in units.\n",  # continued trailing doc
    ]:
      check kept.isSettled


  test "doc above its declaration moves after it: onto its line where it fits, else next line":
    # Case held: `type Order` of `pga/cayleys.nim` of PGA library at `3d9696e`, line 47, whose doc
    #   stands on line above it, below code (ruling on rule 5 of #443).
    let order = "import std/math\n\n## Define type definition for transwedge order.\n" &
      "type Order = distinct range[0..DIMENSIONS]\n#func `<=`(a, b: Order): bool {.borrow.}\n"
    check checkDocs("a.nim", order).mapIt((it.line, it.brief)) == @[
      (4, "doc stands after its declaration, never above it; got it above `type Order`"),
    ]
    check order.fixed == "import std/math\n\ntype Order = distinct range[0..DIMENSIONS]  ## " &
      "Define type definition for transwedge order.\n#func `<=`(a, b: Order): bool {.borrow.}\n"
    check order.fixed.isSettled
    check fixDocs("a.nim", order).origin == @[1, 2, 4, 5, 6]  # joined line traces to declaration
    check "## Module.\n\n## Size.\nconst N = 3\n".fixed == "## Module.\n\nconst N = 3  ## Size.\n"
      # doc above declaration past start of file moves; doc opening file stays (below)
    let kinds = "## Module.\n\n# Sizes.\n## Size.\nconst N* = 3\n\n## Mass.\nlet m = 1.0\n\n" &
      "type\n  Box = object  ## Box.\n    width: int  ## Width.\n\n" &
      "    ## Depth.\n    depth: int\n" &
      "  Kind = enum  ## Kind.\n    A  ## First.\n\n    ## Second.\n    B\n\n" &
      "## Name, " & "x".repeat(60) & ".\nconst NAME = \"" & "y".repeat(40) & "\"\n\n" &
      "## Pair,\n##   held twice.\nconst P = (1, 1)\n\n## Table.\nconst T = [\n  1,\n]\n"
    check checkDocs("a.nim", kinds).mapIt(it.line) == @[5, 8, 15, 20, 23, 27, 30]
      # doc of module opens file, so `# Sizes.` and doc below it stand past it
    check kinds.fixed == "## Module.\n\n# Sizes.\nconst N* = 3  ## Size.\n\n" &
      "let m = 1.0  ## Mass.\n\n" &
      "type\n  Box = object  ## Box.\n    width: int  ## Width.\n\n    depth: int  ## Depth.\n" &
      "  Kind = enum  ## Kind.\n    A  ## First.\n\n    B  ## Second.\n\n" &
      "const NAME = \"" & "y".repeat(40) & "\"\n  ## Name, " & "x".repeat(60) & ".\n\n" &
      "const P = (1, 1)\n  ## Pair,\n  ##   held twice.\n\nconst T = [\n  1,\n]  ## Table.\n"
        # where missing doc writes it: joined where it fits, else next line; value at its close
    check kinds.fixed.isSettled


  test "doc under no code or doc stays as doc of module, and declaration below takes its own":
    # Rulings `D3 a` and `D1 a` of #980: `nim doc` reads doc that only blank lines and `#`
    #   comments stand above as doc of module, so doc position leaves it, and missing doc reads
    #   declaration below it as one holding none.
    const opening = [
      ("## Size.\nconst N* = 3\n", 2, "## Size.\nconst N* = 3  ## TODO: Document.\n"),
      (
        "## Size,\n##   in units.\nconst N* = 3\n",
        3,
        "## Size,\n##   in units.\nconst N* = 3  ## TODO: Document.\n",
      ),  # doc of several lines
      ("## Mass.\nlet m = 1.0\n", 2, "## Mass.\nlet m = 1.0  ## TODO: Document.\n"),
      (
        "## Box.\ntype Box = object\n  width: int  ## Width.\n",
        2,
        "## Box.\ntype Box = object  ## TODO: Document.\n  width: int  ## Width.\n",
      ),
      (
        "## Do.\nproc f() =\n  discard\n",
        2,
        "## Do.\nproc f() =\n  ## TODO: Document.\n  discard\n",
      ),  # routine, whose doc above neither rule moves
      (
        "# Copyright 2026.\n\n## Products.\nconst N* = 3\n",
        4,
        "# Copyright 2026.\n\n## Products.\nconst N* = 3  ## TODO: Document.\n",
      ),  # under license header and blank line
      (
        "#[\n  License.\n]#\n## Products.\nconst N* = 3\n",
        5,
        "#[\n  License.\n]#\n## Products.\nconst N* = 3  ## TODO: Document.\n",
      ),  # under block comment
      (
        "\n## Size.\nconst N* = 3\n",
        3,
        "\n## Size.\nconst N* = 3  ## TODO: Document.\n",
      ),  # under blank line alone
    ]
      ## Source opening with doc of module, line of declaration below it, and source missing doc
      ##   writes.
    for (source, line, documented) in opening:
      checkpoint source
      check source.isSettled  # doc position moves nothing, and fix writes nothing
      check checkDocsMissing("a.nim", source).mapIt(it.line) == @[line]
      check source.documented == documented
      check documented.isDocumented
      check documented.isSettled


  test "doc that block, value or declaration above may own, and doc of local binding, stay":
    for kept in [
      "proc f() =\n  ## Do.\n  echo 1\n\n  ## Note.\n  let x = 1\n  echo x\n",  # local binding
      "type\n  Box = object\n\n    ## Box.\n    width: int\n",  # type's own, as missing doc reads
      "const A = 1  ## One.\n## Two.\nconst B = 2\n",  # right below declaration: hand decides
      "const\n  A = [\n    1,\n  ]\n  ## Doc.\n  B = 2\n",  # after value over lines
      "## Size.\nconst N = 3  ## Count.\n",  # declaration holding doc of its own
    ]:
      check kept.isSettled


  test "one-line doc inside value over lines moves after `=` where it fits, else after close":
    let breach = "const\n  Cayley1D* =\n    ## Define map.\n    array[Basis, seq[BasisSigned]]\n" &
      "  TABLE = [\n    ## Table.\n    1,\n  ]\n" &
      "proc f() =\n  ## Do.\n  let pairs = @[\n    ## Pairs.\n    (1, 2),\n  ]\n  echo pairs\n"
    check checkDocs("a.nim", breach).mapIt((it.line, it.brief)) == @[
      (2, "doc of value over lines stands after `=` ending its first line; got it below " &
        "`const Cayley1D`"),
      (5, "doc of value over brackets stands after its close; got it below `const TABLE`"),
      (11, "doc of value over brackets stands after its close; got it below `let pairs`"),
    ]
    check breach.fixed == "const\n  Cayley1D* =  ## Define map.\n" &
      "    array[Basis, seq[BasisSigned]]\n  TABLE = [\n    1,\n  ]  ## Table.\n" &
      "proc f() =\n  ## Do.\n  let pairs = @[\n    (1, 2),\n  ]  ## Pairs.\n  echo pairs\n"
        # where `nim doc` reads it, as `Cayley1D* =  ## …` of `pga/cayleys.nim` writes it
    check breach.fixed.isSettled


  test "doc trailing line keeps each line lexer joins to it, so no fix splits it in two":
    # Case held: source below, found by hand on `main` at `6905e55e`, which `koch fix` wrote as
    #   `const Y* =  ## Doc of Y …` and `2  ##   And wraps here.`: one doc became two.
    #   Domain: each line opening value over lines, at each reach, and doc holding design note,
    #   each with doc line below it that lexer joins to doc trailing line above.
    let found = "const Y* =  ## Doc of Y that runs on past one line,\n" &
      "  ##   and wraps here.\n  2\n"
    check found.docsRead.docs == @[("Y", "Doc of Y that runs on past one line, and wraps here.")]
      # one doc, as lexer joins it
    check checkDocs("a.nim", "## Module.\n\n{.experimental: \"strictFuncs\".}\n\n" & found).len == 0
    check found.isSettled
    for kept in [
      "const T* = [  ## Table,\n  ##   of one.\n  1,\n]\n",
      "const C* = max(  ## Call,\n  ##   of two.\n  1, 2)\n",
      "const\n  Y* =  ## Doc,\n    ##   wraps.\n    2\n",  # in section
      "proc f*() =\n  ## Do.\n  let y =  ## Doc,\n    ##   wraps.\n    2\n  discard y\n",  # local
    ]:
      checkpoint kept
      check kept.isSettled
      check kept.fixed.docsRead == kept.docsRead
    let noted = "const N* = 3  ## TODO: Later.\n## Since it grows.\n"
    check noted.docsRead.docs == @[("N", "TODO: Later. Since it grows.")]
    check checkDocsMissing("a.nim", noted).len == 1
    check noted.documented == noted  # note runs on below its line, so hand moves it whole


  test "doc inside value opening `block` moves above its declaration, as `#` comment":
    # Case held: `lut_grade_by_basis` of `func grade*` in `pga/algebra.nim` of PGA library at
    #   `3d9696e`, line 343, whose doc opens body of `block:`, where `nim doc` reads none; ruling
    #   D1 c of #1020 moves it above, with blank line above it.
    #   Domain: top level, section, local, under `if`, label, doc of several lines, and doc after
    #     blank line in body.
    let grade = "func grade*(b: Basis): Grade {.noinit.} =\n" &
      "  ## Count number of vector basis elements present in factorization of basis.\n" &
      "  ##   I.e. number of full dimensions occupied by given basis.\n" &
      "  const lut_grade_by_basis = block:\n    ## Construct LUT for grade of basis element.\n" &
      "    var lut: array[Basis, Grade]\n" &
      "    for b in Basis: lut[b] = Grade(b.toFlags.countSetBits)\n    lut\n\n" &
      "  lut_grade_by_basis[b]\n"
    check checkDocs("a.nim", grade).mapIt((it.line, it.brief)) == @[
      (4, "doc of value opening `block` stands above its declaration, as `#` comment; got it " &
        "inside block of `const lut_grade_by_basis`"),
    ]
    check grade.fixed == grade.replace(
      "basis.\n  const lut_grade_by_basis = block:\n    ## Construct LUT for grade of basis " &
        "element.\n",
      "basis.\n\n  # Construct LUT for grade of basis element.\n" &
        "  const lut_grade_by_basis = block:\n",
    )  # routine's doc stands above, so blank line goes between
    check grade.fixed.isSettled
    check grade.fixed.spellingsCode == grade.spellingsCode
    for (breach, settled) in [
      (
        "const A* = 1  ## A.\nconst B* = block:\n  ## Doc,\n  ##   of two lines.\n  2\n",
        "const A* = 1  ## A.\n\n# Doc,\n#   of two lines.\nconst B* = block:\n  2\n",
      ),  # top level, under code: outline keeps its indent past `#`
      (
        "const\n  C* = block:\n    ## Doc.\n    3\n  D* = block outer:\n    ## Doc.\n    4\n",
        "const\n  # Doc.\n  C* = block:\n    3\n\n  # Doc.\n  D* = block outer:\n    4\n",
      ),  # section: keyword opens its body, so first name takes no blank line
      (
        "proc f*() =\n  if true:\n    let e = block:\n      ## Doc.\n      5\n    discard e\n",
        "proc f*() =\n  if true:\n    # Doc.\n    let e = block:\n      5\n    discard e\n",
      ),  # opens body of `if`, so no blank line
      ("var g* = block:\n\n  ## Doc.\n  6\n", "# Doc.\nvar g* = block:\n  6\n"),  # file opens
    ]:
      checkpoint breach
      check checkDocs("a.nim", breach).len > 0
      check checkDocs("a.nim", breach).allIt(it.brief.startsWith("doc of value opening `block`"))
      check breach.fixed == settled
      check settled.isSettled
      check settled.spellingsCode == breach.spellingsCode
      check settled.docsRead == breach.docsRead  # `nim doc` reads neither place


  test "doc after `block:` moves above its declaration, as `#` comment":
    # Case held: `const X* = block:  ## Doc of X.`, which knoller at `6905e55e` passed with no
    #   finding, though `nim doc` reads none after `block:` (suite "What `nim doc` reads").
    #   Domain: top level, section, local, label, doc lexer joins over lines, and other doc too.
    let found = "const X* = block:  ## Doc of X.\n  1\n"
    check checkDocs("a.nim", found).mapIt((it.line, it.brief)) == @[
      (1, "doc of value opening `block` stands above its declaration, as `#` comment; got it " &
        "after `block:` of `const X`"),
    ]
    check found.fixed == "# Doc of X.\nconst X* = block:\n  1\n"
    check found.fixed.isSettled
    check found.fixed.docsRead == found.docsRead  # `nim doc` reads neither place
    for (breach, settled, name) in [
      (
        "const A* = 1  ## A.\nconst B* = block outer:  ## Doc,\n  ##   of two lines.\n  2\n",
        "const A* = 1  ## A.\n\n# Doc,\n#   of two lines.\nconst B* = block outer:\n  2\n",
        "const B",
      ),  # lexer joins second line to doc after `block outer:`, so both move
      (
        "const\n  C* = block:  ## Doc.\n    3\n",
        "const\n  # Doc.\n  C* = block:\n    3\n",
        "const C",
      ),
      (
        "proc f*() =\n  ## Do.\n  let d = block:  ## Doc.\n    4\n  discard d\n",
        "proc f*() =\n  ## Do.\n\n  # Doc.\n  let d = block:\n    4\n  discard d\n",
        "let d",
      ),
    ]:
      checkpoint breach
      check checkDocs("a.nim", breach).mapIt(it.brief) == @[
        "doc of value opening `block` stands above its declaration, as `#` comment; got it " &
          "after `block:` of `" & name & "`",
      ]
      check breach.fixed == settled
      check settled.isSettled
      check settled.spellingsCode == breach.spellingsCode
      check settled.docsRead == breach.docsRead
    for twice in [
      "# Note.\nconst E* = block:  ## Doc.\n  5\n",
      "# Note.\nconst E* = block:\n  ## Doc.\n  5\n",
    ]:
      checkpoint twice
      check checkDocs("a.nim", twice).mapIt(it.brief) == @[
        "doc of value opening `block` stands above its declaration, as one `#` comment; got " &
          "comment above `const E` and other doc of it, which hand joins",
      ]
      check twice.fixed == twice
      check twice.isDocumented


  test "doc above value opening `block` is `#` comment, blank line above where other line stands":
    # Ruling D1 c of #1020: `nim doc` reads no doc above keyword, and `##` above declaration at
    #   top level joins doc of module, which `#` avoids. Domain: `##` and `#`, at each reach,
    #   under code, under doc of routine, other declaration or module, and under line opening body.
    for kept in [
      "## Module.\n\n# Doc.\nconst A* = block:\n  1\n",  # blank line above
      "const\n  # Doc.\n  B* = block:\n    2\n",  # first in section, under keyword
      "proc f*() =\n  ## Do.\n\n  # Doc,\n  #   of two lines.\n  const c = block:\n    3\n" &
        "  discard c\n",  # local, outline
      "proc f*() =\n  if true:\n    # Doc.\n    let d = block:\n      4\n    discard d\n",
      "proc f*() =\n  ## Do.\n  let e = block:\n    5\n  discard e\n",  # routine's doc, none of `e`
      "## Module.\nconst F* = block:\n  6\n",  # doc of module stays (#980)
      "const G* = 7  ## G,\n## held twice.\nconst H* = block:\n  8\n",  # lexer joins it to `G`
    ]:
      checkpoint kept
      check kept.isSettled
    let opening = "{.experimental: \"strictFuncs\".}\n\n"
    for (breach, settled, brief) in [
      (
        opening & "## Doc.\nconst A* = block:\n  1\n",
        opening & "# Doc.\nconst A* = block:\n  1\n",
        "doc above value opening `block` is `#` comment, since `nim doc` reads none there; " &
          "got `##` above `const A`",
      ),
      (
        "const A* = 1  ## A.\n# Doc.\nconst B* = block:\n  2\n",
        "const A* = 1  ## A.\n\n# Doc.\nconst B* = block:\n  2\n",
        "doc above value opening `block` takes blank line above it; got no blank line above doc " &
          "of `const B`",
      ),
      (
        "proc f*() =\n  ## Do.\n  # Doc.\n  const c = block:\n    3\n  discard c\n",
        "proc f*() =\n  ## Do.\n\n  # Doc.\n  const c = block:\n    3\n  discard c\n",
        "doc above value opening `block` takes blank line above it; got no blank line above doc " &
          "of `const c`",
      ),
      (
        "const\n  A* = 1\n  ## Doc,\n  ##   of two lines.\n  B* = block:\n    2\n",
        "const\n  A* = 1\n\n  # Doc,\n  #   of two lines.\n  B* = block:\n    2\n",
        "doc above value opening `block` is `#` comment, since `nim doc` reads none there; " &
          "got `##` above `const B`",
      ),  # both at once
      (
        "proc f*() =\n  if true:\n    ## Doc.\n    let d = block:\n      4\n    discard d\n",
        "proc f*() =\n  if true:\n    # Doc.\n    let d = block:\n      4\n    discard d\n",
        "doc above value opening `block` is `#` comment, since `nim doc` reads none there; " &
          "got `##` above `let d`",
      ),
    ]:
      checkpoint breach
      check checkDocs("a.nim", breach).mapIt(it.brief) == @[brief]
      check breach.fixed == settled
      check settled.isSettled
      check settled.spellingsCode == breach.spellingsCode
    check (opening & "## Doc.\nconst A* = block:\n  1\n").docsRead.module == "Module.Doc."
    check (opening & "# Doc.\nconst A* = block:\n  1\n").docsRead.module == "Module."


  test "doc of routine named in backticks stays its own, above value opening `block`":
    # Case held: `∪` of `pga/operators.nim` of PGA library at `3d9696e`, line 401, whose doc doc
    #   position read as doc of `const 𝐞̄ₙ` right below it, and wrote as `#`.
    #   Domain: operator of each routine kind, under `when`, and doc after blank line.
    for kept in [
      "when true:\n  func `∪`*(m: int): int =\n    ## Get antisupport.\n    const e = block:\n" &
        "      1\n    m + e\n",
      "proc `+`*(a, b: int): int =\n  ## Add.\n  let s = block:\n    a + b\n  s\n",
      "template `-`*(a: int): int =\n  ## Negate.\n  let s = block:\n    -a\n  s\n",
      "func `*`*(a, b: int): int =\n\n  ## Scale.\n  let s = block:\n    a * b\n  s\n",
    ]:
      checkpoint kept
      check checkDocs("a.nim", kept).len == 0
      check kept.fixed == kept


  test "value whose `block` opens below its `=` reports, and stays for hand to dedent":
    # Case held: `FACINGS` of `simulation/words.nim` of `dance_ontology`, whose doc stands below
    #   body; ruling D1 c of #1020 keeps `block:` on `=` line, so fix would dedent body.
    #   Domain: doc on `=` line, doc below body, and none, at each reach, with label.
    for (source, line, name) in [
      (
        "const FACINGS* =\n  block:\n    var each = 0\n    each\n  ## Name each state.\n",
        1,
        "const FACINGS",
      ),
      ("const F* =  ## Doc.\n  block:\n    6\n", 1, "const F"),
      ("proc f*() =\n  ## Do.\n  let g =\n    block outer:\n      7\n  discard g\n", 3, "let g"),
    ]:
      checkpoint source
      check checkDocs("a.nim", source).mapIt((it.line, it.brief)) == @[
        (line, "value opening `block` keeps `block:` on its `=` line, so body takes one indent; " &
          "got `block` below `=` of `" & name & "`, whose body hand dedents"),
      ]
      check source.fixed == source


  test "next-line doc of several lines, or under line holding comment, stands one level in":
    let breach = "const\n  N = 3\n      ## Size,\n      ##   in units.\n" &
      "  WHY = 1  # Reason.\n      ## Why.\n"
    check checkDocs("a.nim", breach).mapIt((it.line, it.brief)) == @[
      (2, "doc on next line stands one level in; got indent `6`"),
      (5, "doc on next line stands one level in; got indent `6`"),
    ]
    check breach.fixed == "const\n  N = 3\n    ## Size,\n    ##   in units.\n" &
      "  WHY = 1  # Reason.\n    ## Why.\n"
    check breach.fixed.isSettled


  test "routine's doc opens line after its signature, at indent of its body":
    let breach = "proc f() =  ## Do.\n  discard\nfunc g(): int = 1  ## One.\n" &
      "proc h() =\n\n  ## Do.\n  discard\nproc k() =\n      ## Do.\n  discard\n" &
      "func m(): int = 2\n    ## Two.\n"
    check checkDocs("a.nim", breach).mapIt((it.line, it.brief)) == @[
      (1, "doc of routine stands on line after its signature; got it on signature line of " &
        "`proc f`"),
      (3, "doc of routine stands on line after its signature; got it on signature line of " &
        "`func g`"),
      (4, "doc of routine stands on line right after its signature; got blank line above it " &
        "in `proc h`"),
      (8, "doc of routine stands at indent of its body; got indent `6` in `proc k`"),
      (11, "doc of routine stands at indent of its body; got indent `4` in `func m`"),
    ]
    check breach.fixed == "proc f() =\n  ## Do.\n  discard\nfunc g(): int = 1\n  ## One.\n" &
      "proc h() =\n  ## Do.\n  discard\nproc k() =\n  ## Do.\n  discard\n" &
      "func m(): int = 2\n  ## Two.\n"
    check breach.fixed.isSettled


  test "one-line doc under bare `type` joins keyword line, as group doc of block":
    let breach = "type\n  ## Group.\n  A = int  ## One.\n"
    check checkDocs("a.nim", breach).mapIt((it.line, it.brief)) == @[
      (1, "group doc of `type` section stands on keyword line; got `it on next line`"),
    ]
    check breach.fixed == "type  ## Group.\n  A = int  ## One.\n"
    check breach.fixed.isSettled


  test "parameter drops type its literal default gives exactly":
    let breach = "proc f(now: float = 0.0, on: bool = false, s: string = \"a\", c: char = 'x', " &
      "n: int = -1) = discard\nproc g(a: Foo = default(Foo), b: Option[int] = none(int), " &
      "p, q: int = 0x1F) = discard\n"
    check checkDefaults("a.nim", breach).len == 8
    check breach.fixed == "proc f(now = 0.0, on = false, s = \"a\", c = 'x', n = -1) = discard\n" &
      "proc g(a = default(Foo), b = none(int), p, q = 0x1F) = discard\n"
    check breach.fixed.isSettled
    check fixDefaults("a.nim", breach).fixed[0].rule == Rule.DefaultLiteral


  test "default of other type, named constant, template, macro and field stay":
    for kept in [
      "proc k(a: float = 0, b: cfloat = 0.0, c: HalfTurns = 0, d: int = SAMPLES) = discard\n",
      "proc k(e: float32 = 1.0, f: uint8 = 0'u8, g: string = r\"a\") = discard\n",
      "template t(a: int = 0) = discard\nmacro m(a: int = 0) = discard\n",
      "type O = object\n  x: int = 0\n",
    ]:
      check kept.isSettled



  test "declaration of each kind with no doc takes `TODO: Document.` where doc position puts it":
    let breach = "const N* = 3\ntype\n  Shape {.pure.} = enum\n    Round\n  Box* = object\n" &
      "    width*: int\nproc area*(b: Box): int =\n  b.width\nfunc scale*(\n" &
      "  b: Box, factor: int,\n): Box =\n  b\nconst\n  NAME = \"" & "x".repeat(70) & "\"\n" &
      "  WHY = 1  # Reason.\n"
    let found = checkDocsMissing("a.nim", breach)
    check found.mapIt(it.line) == @[1, 3, 4, 5, 6, 7, 9, 14, 15]
    check found.mapIt(it.brief)[0 .. 1] == @[
      "declaration takes doc comment; got `const N`",
      "declaration takes doc comment; got `type Shape`",
    ]
    check found.mapIt(it.brief)[5 .. 6] == @[
      "declaration takes doc comment; got `proc area`",
      "declaration takes doc comment; got `func scale`",
    ]
    check breach.documented == "const N* = 3  ## TODO: Document.\ntype\n" &
      "  Shape {.pure.} = enum  ## TODO: Document.\n    Round  ## TODO: Document.\n" &
      "  Box* = object  ## TODO: Document.\n    width*: int  ## TODO: Document.\n" &
      "proc area*(b: Box): int =\n  ## TODO: Document.\n  b.width\n" &
      "func scale*(\n  b: Box, factor: int,\n): Box =\n  ## TODO: Document.\n  b\n" &
      "const\n  NAME = \"" & "x".repeat(70) & "\"\n    ## TODO: Document.\n" &
      "  WHY = 1  # Reason.\n    ## TODO: Document.\n"  # joined where it fits, else next line
    check breach.documented.isDocumented  # second run writes nothing
    check fixDocsMissing("a.nim", breach).fixed.mapIt(it.rule).deduplicate == @[Rule.DocMissing]


  test "doc in place, local, parameter, placeholder, generated code and stacked borrow pass":
    for kept in [
      "const N = 3  ## Size.\n",
      "const\n  N = 3\n    ## Size.\n",  # next line, one level in
      "const T = [\n  1,\n]  ## Table.\n",  # last line of value
      "const T = block:\n  ## Table.\n  1\n",  # first in block: doc position moves it
      "proc f[T](x: T): T =\n  ## Echo.\n  let y = x\n  y\n",
      "func g() =\n  ##[ Block doc. ]##\n  discard\n",
      "macro m(): untyped =\n  ## Emit.\n  quote do:\n    proc h() = discard\n",
      "# Bounds of order.\nfunc low(a: O): O {.borrow.}\nfunc next(a: O): O = succ(a)\n",
      "const M = 2  ## Mass.\n\n## Doc above.\nconst N = 3\n",  # out of place: position reads it
      "const N = 3  ## TODO: Document.\n",  # doc waiting for text
    ]:
      check kept.isDocumented


  test "names one line declares share one doc, enum members among them, so line reports once":
    let breach = "type P = object\n  ## Pair.\n  left*, right*: int\nlet (a, b) = (1, 2)\n" &
        "type K = enum\n  ## Kind.\n  A, B, C\n  D,\n  E  ## Last.\n"
    check checkDocsMissing("a.nim", breach).mapIt((it.line, it.brief)) == @[
      (3, "declaration takes doc comment; got `field left`"),
      (4, "declaration takes doc comment; got `let a`"),
      (7, "declaration takes doc comment; got `member A`"),  # doc above is its type's own
      (8, "declaration takes doc comment; got `member D`"),  # `,` opens next member, not value
    ]
    check breach.documented == "type P = object\n  ## Pair.\n" &
        "  left*, right*: int  ## TODO: Document.\nlet (a, b) = (1, 2)  ## TODO: Document.\n" &
        "type K = enum\n  ## Kind.\n  A, B, C  ## TODO: Document.\n  D,  ## TODO: Document.\n" &
        "  E  ## Last.\n"
    check breach.documented.isDocumented  # second run writes nothing


  test "doc holding design note keeps note as comment above, and waits for text":
    # Case held: `Bases*` and `toMultivector*` of `pga/multivectors.nim` of PGA library at
    #   `3d9696e`, whose docs hold notes `TODO: Make distinct.` and `TODO: Define via macro.`.
    let breach = "type\n  Bases* = set[int]  ## TODO: Make distinct.\n" &
      "func f*(): int =\n  ## TODO: Define via macro.\n  1\n"
    check checkDocsMissing("a.nim", breach).mapIt(it.brief) == @[
      "doc holds `TODO: Document.` and nothing else; got `## TODO: Make distinct.`",
      "doc holds `TODO: Document.` and nothing else; got `## TODO: Define via macro.`",
    ]
    check breach.documented == "type\n  # TODO: Make distinct.\n" &
      "  Bases* = set[int]  ## TODO: Document.\n# TODO: Define via macro.\n" &
      "func f*(): int =\n  ## TODO: Document.\n  1\n"  # note keeps design journal (VIII.3)
    check breach.documented.isDocumented
    let outlined = "proc g() =\n  ## TODO: Split.\n  ##   Since it grows.\n  discard\n"
    check checkDocsMissing("a.nim", outlined).len == 1
    check outlined.documented == outlined  # outline may elaborate note or text, so hand moves it


  test "forward declaration takes doc of its routine, and fix leaves move of that doc for hand":
    # Case held: `proc dance` of `app/app.nim` of `dance_ontology`, whose definition holds doc.
    let forward = "proc dance(key: string)\n\nproc dance(key: string) =\n  ## Dance.\n  echo key\n"
    check checkDocsMissing("a.nim", forward).mapIt((it.line, it.brief)) == @[
      (1, "forward declaration takes doc of its routine, which `nim doc` reads there; got " &
        "`proc dance`"),
    ]
    check forward.documented == forward and fixDocsMissing("a.nim", forward).fixed.len == 0
    let planned = "func planned*(m: int): int {.error:\n  \"Planned.\"\n.}\n"
    check planned.documented == planned & "  ## TODO: Document.\n"  # no body and no definition


  test "value or signature running on reads doc where it ends":
    for kept in [
      "const\n  DIRECTORY_CACHE* = \".cache/knoller/nim\"\n" &
        "    ## Default cache, under home and beside Nim's own `~/.cache/nim`.\n",
        # `compilers.nim` of `knoller`: value of string alone
      "const MATRIX_REST {.used.}: Matrix =  # Used in `plan.nim`.\n" &
        "  [[1.0, 0.0, 0.0], [0.0, -1.0, 0.0], [0.0, 0.0, -1.0]]\n" &
        "  ## Upper arm's frame at rest in body's terms.\n",
        # `simulation/rigid.nim` of `dance_ontology`: comment after `=`
      "func placings*(rig: Rig, plan: Plan, wind: float, is_away: bool, turner = Body.Two):\n" &
        "    tuple[chests: array[Body, Stance], arms: array[4, ArmPlacing]] =\n" &
        "  ## Where every body of couple stands at this plan.\n  discard\n",
        # `simulation/plan.nim` of `dance_ontology`: return type below parameters
      "const KEYS_DRIVEN = [\n  stepKey(Scancode.BracketRight, uint32(ord(']'))),\n" &
        "]  ## Script one keyboard step per frame for `--drive-keys`.\n",
        # `src/desktop/main.nim` of `pga_visualiser`: bracket inside character literal
      "const STYLE* = \"\"\"<style>\n\"\"\" &\n  \"\"\"</style>\"\"\"\n  ## Style of page.\n",
        # `design/page.nim` of `dance_ontology`: long strings joined over lines
      "const DOC_EMPTY = \"## TODO: Document.\"  ## Doc waiting for honest text.\n",
        # `declarations.nim` of `knoller`: string holding note is no doc
      "let s = \"\"\"\n#!fix off\n\"\"\"  ## Text.\n",
        # `tests/suites/test_fixes.nim` of `audit`: doc trailing close of long string
      "const\n  FLOOR_FUNCTIONS_REFERENCE =\n    when DIMENSIONS == 4 and IS_RIGID: 73\n" &
      "    elif DIMENSIONS == 5 and IS_CONFORMAL: 84\n    else: 1\n" &
      "    ## Reference functions own nimcache holds at pin.\n",
        # `tests/suites.nim` of `pga_benchmark`: branches of `when` below `=`
      "const\n  BYTES_MEMORY_TOTAL* =\n" &
      "      CAPACITY_ARENA_PROGRAM + 2 * CAPACITY_ARENA_FRAME +\n" &
      "      FRAMES_TIMING_MAX * sizeof(float32)\n" &
      "    ## Sum every fixed-size reservation this binary makes.\n",
        # `src/desktop/main.nim` of `pga_visualiser`: sum running on after `+`
      "const FACINGS* =\n  block:\n    var each = 0\n    each\n" &
      "  ## Name each state two stand in to one another.\n",
        # `simulation/words.nim` of `dance_ontology`: `block:` below `=`
      "const WIDE_TEMPO* = Tempo(\n  ## Hold how long this drawing takes to say move.\n" &
      "  quick: 1)\n",
        # `src/dance_ontology/map.nim` of `dance_ontology`: doc right below first line, as cost
    ]:
      check kept.isDocumented
    check checkDocsMissing("a.nim", "let s = \"\"\"\nx\n\"\"\"  ## Text.\nlet t = 1\n").mapIt(
      it.line,
    ) == @[4]  # doc trailing long string stands above next line as no doc of it


  test "value or body opening long string takes doc where string closes, never inside it":
    # Case held: `DRIVE_NIM` of `tests/suites/test_waits.nim` of `audit`, and `HEAD_BODY` of
    #   `design/rig_page.nim` of `dance_ontology`, each value opening long string on its line.
    let
      value = "const\n  PAGE* = \"\"\"\n<p>\n\"\"\"\n  NEXT = 1  ## Next.\n"
      wide = "const PAGE* = \"\"\"\n<p>\n\"\"\" & \"" & "x".repeat(80) & "\"\n"
      body = "func page*(): string = \"\"\"\n<main>\n\"\"\"\n"
    check value.documented == value.replace("\"\"\"\n  NEXT", "\"\"\"  ## TODO: Document.\n  NEXT")
    check wide.documented == wide & "  ## TODO: Document.\n"  # joined line would not fit
    check body.documented == body & "  ## TODO: Document.\n"  # first line after body string
    for source in [value, wide, body]: check source.documented.isDocumented


  test "value over lines takes doc after `=` ending its first line, else at its close":
    # `nim jsondoc` of Nim 2.2.12 and 2.4.0 reads doc of value over lines there alone, and of
    #   `case` value on line below last branch. Nim parses no doc below `=` ending first line,
    #   nor after `=` of named argument or `:` of field inside open bracket.
    let
      field = "const P = Pair(a:\n  1, b: 2)\n"
      argument = "const Q = foo(a =\n  2, b = 3)\n"
      opened = "const R = foo(\n  1, 2)\n"
      chained = "const S = 1 +\n  2\n"
      equals = "const T =\n  foo(1)\n"
      wide = "const " & "W".repeat(90) & " =\n  foo(1)\n"
      cased = "const U = case K\n  of A: 1\n  of B: 2\n"
    check field.documented == "const P = Pair(a:\n  1, b: 2)  ## TODO: Document.\n"
    check argument.documented == "const Q = foo(a =\n  2, b = 3)  ## TODO: Document.\n"
    check opened.documented == "const R = foo(\n  1, 2)  ## TODO: Document.\n"
    check chained.documented == "const S = 1 +\n  2  ## TODO: Document.\n"
    check equals.documented == "const T =  ## TODO: Document.\n  foo(1)\n"
    check wide.documented == wide.replace("foo(1)\n", "foo(1)  ## TODO: Document.\n")
      # joined first line would not fit
    check cased.documented == cased & "  ## TODO: Document.\n"
    for source in [field, argument, opened, chained, equals, wide, cased]:
      check source.documented.isDocumented


  test "value opening `block` with no doc takes `# TODO: Document.` above it, blank line above":
    # Ruling D1 c of #1020: doc of value opening `block` stands above its declaration, as `#`,
    #   since `nim doc` reads none there, and comment there counts as its doc. Domain: global at
    #   top level, in section and under `when`, under code, doc of module, keyword and none; doc in
    #   each place doc position moves from; and local, which takes none.
    let blocked = "const V = block:\n  1\nconst W = block outer:\n  2\n"
    check checkDocsMissing("a.nim", blocked).mapIt((it.line, it.brief)) == @[
      (1, "declaration takes doc comment; got `const V`"),
      (3, "declaration takes doc comment; got `const W`"),
    ]
    check blocked.documented == "# TODO: Document.\nconst V = block:\n  1\n\n" &
      "# TODO: Document.\nconst W = block outer:\n  2\n"
    check blocked.documented.isDocumented
    check blocked.documented.isSettled  # doc position passes what missing doc writes
    for (source, documented) in [
      (
        "## Module.\nconst V* = block:\n  1\n",
        "## Module.\n\n# TODO: Document.\nconst V* = block:\n  1\n",
      ),  # doc of module stays (#980)
      (
        "const\n  A* = 1  ## A.\n  B* = block:\n    2\n",
        "const\n  A* = 1  ## A.\n\n  # TODO: Document.\n  B* = block:\n    2\n",
      ),
      ("const\n  B* = block:\n    2\n", "const\n  # TODO: Document.\n  B* = block:\n    2\n"),
      (
        "when true:\n  let C* = block:\n    3\n",
        "when true:\n  # TODO: Document.\n  let C* = block:\n    3\n",
      ),  # `when` opens no scope, so `C` is global
    ]:
      checkpoint source
      check source.documented == documented
      check documented.isDocumented
      check documented.isSettled
    let below = "const F* =\n  block:\n    6\n"
    check below.documented == "# TODO: Document.\n" & below  # doc position leaves `block` for hand
    for kept in [
      "# Doc.\nconst V = block:\n  1\n",
      "const A = 1  ## A.\n# Doc.\nconst V = block:\n  1\n",  # doc position adds blank line
      "{.experimental: \"strictFuncs\".}\n\n## Doc.\nconst V = block:\n  1\n",  # doc position: `#`
      "const V = block:\n  ## Doc.\n  1\n",  # inside: doc position moves it
      "const V =  ## Doc.\n  block:\n    1\n",  # on `=` line, which hand moves
      "proc f() =\n  ## Do.\n  let v = block:\n    1\n  discard v\n",  # local takes none
    ]:
      checkpoint kept
      check kept.isDocumented


  test "type running over lines reads doc where it closes, and name inside its brackets none":
    # Cases held: `stamp_shown` of `src/desktop/panel.nim` of `pga_visualiser`, `WalkAsk` of
    #   `simulation/walk.nim` and `Posed` of `tests/test_rigid.nim` of `dance_ontology`, and
    #   `DecodeBrotli` of `src/font_files.nim` of `audit`, whose fix broke parse of each.
    for kept in [
      "type Panel = object  ## Panel.\n  stamp_shown*: Option[tuple[\n" &
        "    revision: int, search: string,\n    revision_selection: Option[int]\n  ]]\n" &
        "    ## What list was last filtered against.\n",
      "type WalkAsk = tuple[rig: Rig, band: Band, apart, most,\n" &
        "                    step: float, is_away: bool]\n  ## One walk, by every argument.\n",
      "type DecodeBrotli = proc (\n  size_encoded: csize_t, encoded: ptr uint8\n" &
        "): cint {.cdecl, gcsafe.}\n  ## Define one-shot decode into sized buffer.\n",
    ]:
      check kept.isDocumented
    # Case held: `leaving` of `tests/suites/test_timings.nim` of `pga_visualiser`, routine
    #   declared inside bracket, whose body takes doc as any routine's does.
    let declared = "check not compiles(block:\n  proc leaving() =\n    return\n  leaving())\n"
    check checkDocsMissing("a.nim", declared).mapIt(it.line) == @[2]
    check declared.documented == "check not compiles(block:\n  proc leaving() =\n" &
        "    ## TODO: Document.\n    return\n  leaving())\n"
    let bare = "type Pair = tuple[a: int,\n  b: int]\n"
    check bare.documented == "type Pair = tuple[a: int,\n  b: int]  ## TODO: Document.\n"


  test "one-line routine reads as stacked only under run of such routines and its comment":
    # Case held: `template at` of `src/comments.nim` of `audit`, nested below bindings of routine
    #   whose doc stands above them.
    let nested = "proc scan() =\n  ## Scan.\n  let n = 1\n  template at(k: int): int = k + n\n" &
      "  discard at(0)\n"
    check checkDocsMissing("a.nim", nested).mapIt(it.line) == @[4]
    check "# Bounds.\nfunc low(a: O): O {.borrow.}\nfunc high(a: O): O {.borrow.}\n".isDocumented
    # Case held: `page` of `tests/suites/test_asks.nim` of `dance_ontology`, nested right below
    #   doc of its routine, which is no group comment.
    let below = "func arranged(): float =\n  ## Where follow stands.\n" &
        "  func page(radians: float): float = 90.0 - radians\n  page(1.0)\n"
    check checkDocsMissing("a.nim", below).mapIt(it.line) == @[3]
    # Case held: stack of `design/rig_view.nim` of `dance_ontology`, whose third routine is no
    #   delegation, so run ends there for each routine below it.
    let broken = "# Entries of recording, read as viewer reads them.\n" &
      "proc entry(i: int): JsObject = ENTRIES_ALL[i]\nproc sweep(): JsObject = entry(PICK)\n" &
      "proc moments(recording: JsObject): int = (if has(recording, \"at\"): count(recording.at) " &
      "else: 0)\nproc moments(): int = moments(sweep())\n" &
      "proc isStill(recording: JsObject): bool = has(recording, \"key\")\n"
    check checkDocsMissing("a.nim", broken).mapIt(it.line) == @[4, 5, 6]
    check broken.documented.isDocumented  # one run writes each doc due


  test "fix writes comments alone, so each token of code stays as it was":
    for breach in [
      "const N* = 3\ntype\n  Box* = object\n    width*: int\n" &
        "proc area*(b: Box): int =\n  b.width\n",
      "type\n  Bases* = set[int]  ## TODO: Make distinct.\n" &
        "func f*(): int =\n  ## TODO: Later.\n  1\n",
      "const\n  PAGE* = \"\"\"\n<p>\n\"\"\"\n  NEXT = 1\n" &
        "func page*(): string = \"\"\"\n<main>\n\"\"\"\n",
      "let x = foo(\n  1,\n)\nlet (a, b) = (1, 2)\nconst S = \"## TODO: x\"\n",
      "const V = block:\n  1\nconst W = 2\nconst X = block:\n  3\n",  # `#` above `block` value
    ]:
      check breach.documented != breach  # each source takes doc
      check breach.documented.spellingsCode == breach.spellingsCode


  test "fix traces each line it writes to none, and each line it keeps to its input line":
    let fix = fixDocsMissing("a.nim", "const N = 3\nproc f() =\n  discard\n")
    check fix.source == "const N = 3  ## TODO: Document.\nproc f() =\n  ## TODO: Document.\n" &
      "  discard\n"
    check fix.origin == @[1, 2, 0, 3, 4]  # joined line keeps its input line
    check fix.fixed.mapIt(it.line) == @[1, 2]



suite "What `nim doc` reads":
  test "doc after value or on `=` line is read, and doc above, inside block or on keyword none":
    # Case held: rulings of D1 c of #1020 write `#` where Nim reads no doc, and `##` again
    #   where later Nim reads one; so this test fails once compiler building suite reads one
    #   more place. Domain: each place doc of constant, binding, type or local can stand.
    for (source, name, doc) in [
      ("const A* = 1  ## Doc.\n", "A", "Doc."),  # after plain value
      ("const\n  B* = 2  ## Doc.\n", "B", "Doc."),  # after plain value in section
      ("var C* = 3  ## Doc.\n", "C", "Doc."),
      ("type D* = object  ## Doc.\n", "D", "Doc."),
      ("const E* =  ## Doc.\n  5\n", "E", "Doc."),  # on `=` line, value below
      ("const F* =  ## Doc.\n  block:\n    6\n", "F", "Doc."),  # `block:` below, two indents
      ("const G* = block:  ## Doc.\n  7\n", "G", ""),  # after `block:`
      ("const H* = block:\n  ## Doc.\n  8\n", "H", ""),  # first in body of block
      ("const  ## Doc.\n  I* = 9\n", "I", ""),  # on keyword line of section
      ("let  ## Doc.\n  J* = 10\n", "J", ""),
      ("type  ## Doc.\n  K* = object\n", "K", ""),
      ("const\n  ## Doc.\n  L* = 12\n", "L", ""),  # above name in section
    ]:
      check source.docsRead == ("Module.", @[(name, doc)])
    for source in ["## Doc.\nconst M* = 13\n", "\n## Doc.\nconst M* = 13\n"]:
      check source.docsRead == ("Module.Doc.", @[("M", "")])  # above keyword joins module's
    check "proc n*() =\n  ## Do.\n  ## Doc.\n  const O = 1\n  discard O\n".docsRead.docs ==
      @[("n", "Do. Doc.")]  # above local with no blank line joins routine's
    check "proc n*() =\n  ## Do.\n\n  ## Doc.\n  const O = 1\n  discard O\n".docsRead.docs ==
      @[("n", "Do.")]
