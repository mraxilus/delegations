# Deviations of the port from the library at pin

Each row says how port differs from Nim 2 library, why, and which Nimony behaviour forces it.
Origins:

- **design**: Nimony documents or plainly intends it.
- **missing**: Nim 2 feature or library routine that Nimony lacks, or that Nimony lists as missing.
- **defect, patched**: compiler bug, fixed in `compiler.md`.
- **defect, worked around**: compiler bug left unpatched, with reason.
- **defect, not patched**: compiler bug that port neither patches nor works around, with what it
  costs.
- **choice**: porter's choice among working forms.
- **simplified**: form of Nim 2 library that costs too much, or does nothing, under Nimony.
- **kept**: form of Nim 2 library that port keeps, with what it costs or avoids.
- **Nim 2**: limit of Nim 2 library itself.

`N/` is Nimony checkout, at 941d128 with patches of `compiler.md`, and line numbers refer to it.
`ref/` is library at pin, and `port/` is that library with `change.md` applied, sources
1f09934e0068b5ec; line numbers of `port/` refer to them. Paths under `verify/`, `review/` and
`upstream/` name files of runs that measured port, kept in archive outside repository.
`verify/final_port/` holds full verification of these sources, and its `summary_extra.txt` adds
32-bit regression of cga3d. `verify/final_port_before_review/` holds full verification of port
before review (sources bce49d479e3f183e). Other files under `verify/` hold probes of port before
review, of earlier layouts, or of earlier sources of review, and rows with times from them say so.
`review/` holds runs of review of port, and optional changes O1 to O20 of that review are patches
there (`review/optional/OPTIONAL.md`). Compiler patches are C1 to C9 here, so no name reads as
proposal of this project.

Port keeps modules, names and order of Nim 2 library, apart from what rows say. It adds module
`basis.nim` (S1), splits `cayleys.nim` into folder `cayleys/` of three modules (S2, S3), and
`emitters.nim` becomes plugin program (S4).

## Structure

### S1

- **Nim 2 library:** `algebra.nim` holds configuration, digit form of bases, `Basis`, and code typed
  over `Basis`
- **Port:** `basis.nim` holds configuration, digit form, construction of algebra, and call that
  declares `Basis`. `algebra.nim` imports it, re-exports it without its digit helpers (S7), and
  holds code typed over `Basis`. Doc comment of `pga.nim` gives this order of modules. Its order of
  types starts `[Algebra, BasisDigits] -> Basis`, without `BasisFlags`, which `algebra.nim` declares
  after `Basis`, and it names `BasesSigned` (S8)
- **Origin:** missing
- **Evidence:** No signature or type section of same module sees type that plugin declares, before
  or after call. Toplevel call runs in body phase (`N/src/nimony/sem.nim` 6002-6004, `semmain.nim`
  240-262), and `semcall.nim` 270-283 gives only expansion itself every phase. Type-position plugin
  (`plugins.md` 274-283), as in `type Basis* = defineBasis(...)`, fails on anonymous `enum` it
  returns.

### S2

- **Nim 2 library:** `cayleys.nim` holds types and tables
- **Port:** `cayleys/types.nim` holds types and cell operations (S8). `cayleys.nim` imports it and
  `cayleys/definitions.nim`, and re-exports tables, and types that Nim 2 library makes public (S7)
- **Origin:** defect, worked around
- **Evidence:** With types in `cayleys.nim`, first table constant fails: "cannot evaluate expression
  at compile time: constructComplement(Left)", with "expression expected; tag: efld" at enum of same
  module (`sem.nim` 5780), and "Type mismatch" at `product[0]`, where `[]` of cell is template of
  same module (`verify/single/s2_types_in_cayleys.log`). Three causes. First, collector of constant
  program copies node `efld` of enum field as statement, also from routine body, and master fixes it
  (nim-lang/nimony#2866). Second, template `[]` reaches program in raw body of signature phase,
  which C6 does not mend, as raw body holds `(at cell 0)`. Master fails on second cause, also for
  `func` `[]`, `[]=` and `items` of module (`upstream/S2.md`). Third, generic object type of same
  module, in signature of function that constant calls, is undeclared in that program: "undeclared
  identifier: Pair". Containers `Chiral`, `Formal`, `Partial` and `Spatial` are such types. Third
  cause also stops master, with patch of `upstream/S2.md` too
  (`review/umbrella-api/probes/samemod/`). Not patched: second cause is phase order of whole module,
  and no patch of defect list mends third.

### S3

- **Nim 2 library:** Tables first, functions after (`codeReordering`); `defineBasis(DIMENSIONS)`
  before helpers
- **Port:** Tables in `cayleys/definitions.nim`, which imports functions that they call from
  `cayleys/functions.nim`; in `basis.nim`, constant and call of `defineBasis` last
- **Origin:** missing + defect, worked around
- **Evidence:** `const` and `static(...)` evaluate where they stand; routine declared later is
  undeclared. `language.md` 26-31 orders only constants; Nimony has no `codeReordering`. Forward
  declaration does not help: `const` that calls routine before its implementation compiles, and gets
  0. Call of forward declaration with no implementation gets 0 too; Nim 2.4.0 rejects both
  (`upstream/S3.md`). Not patched: layout of port needs no forward declaration. One module with
  functions first also works. Folder puts tables first in module of their own, as Nim 2 library puts
  them first in `cayleys.nim`. Folder adds 2 modules, and no build cost beyond spread of runs. In 3
  alternating runs each, clean rga4d build takes 114.1-118.3 s of CPU with one module (earlier
  layout), and 115.9-123.7 s with folder (port before review). Edit of `emitters.nim` takes
  69.3-74.4 s and 70.6-74.1 s, and clean rga6d build 184.6 s and 178.1 s
  (`verify/single/split_ab/results.txt`).

### S4

- **Nim 2 library:** Macros `defineBasis` (`algebra.nim`), `defineMultivectors`,
  `defineBasisElementConstructors` (`multivectors.nim`), `defineOperator` (`operators.nim`)
- **Port:** Template plugins of same names, in modules that call them. All four name one plugin
  program, `emitters.nim`, which holds macro bodies. Templates have no return type, where macros
  have `untyped`: with return type, Nimony checks emitted code in body phase alone
  (`N/src/nimony/semcall.nim` 270-283). Doc comment of each macro stands under head of its template
- **Origin:** design
- **Evidence:** Plugin is program of its own, which reads and writes NIF trees (`N/doc/plugins.md`
  3-6). `language.md` 4717: macros exist for Nim 2 compatibility. Macro program takes `NimNode` per
  argument: no library helper, no `static` value (`N/src/nimony/macro_plugin.nim` 95-262). One
  program for four templates adds no module. Cost: when source of program changes, nifmake builds it
  again, and each module that declares its templates or imports one that does (`plugins.md`
  145-151). One comment line added to `emitters.nim` makes rga4d suite build check 10 of its 75
  modules again. These are 3 that declare templates, and 7 that import them (names in
  `verify/single/split_ab/results.txt`, of port before review, same layout). On final port, that
  build takes 23.6 s, against 40.4 s for clean build (`verify/final_single/timing.txt`).

### S5

- **Nim 2 library:** `emitters.nim` builds `NimNode` with `std/macros`
- **Port:** Program builds NIF with plugin API `plugins` (`NifBuilder`, `withTree`), in form that
  parser writes. Five emitters of Nim 2 library keep names, order and parameters: `emitFunc`,
  `emitTypeDef`, `emitSubscript`, `emitTerm`, `emitMultivectorOf`; bases are names (S9). Routines
  are `proc`, where Nim 2 library has `func`, and none has export marker, as nothing imports
  program. `emitExport`, `emitIdent`, `emitCall`, `emitInfix`, `emitPrefix`, `emitParams` and
  `emitPragma` stand for `postfix`, `ident`, `newCall`, `infix`, `prefix`, `nnkFormalParams`, and
  `nnkPragma` or `newEmptyNode` of `std/macros`. Macro bodies are `emitEnumBasis`,
  `emitMultivectors`, `emitBasisElementConstructors` and two `emitOperator`. They call emitters
  where macros of Nim 2 library build same nodes in place, and `emitAssignments` holds loop that
  both `defineOperator` macros repeat. `emit` selects body by name of template, and `emitStatements`
  wraps its output. Head comment documents program, where Nim 2 library has `## TODO: Document.`
  Docs of function are comment in its body, as in Nim 2 library (S13)
- **Origin:** design + choice
- **Evidence:** Compiler checks output again in caller's scope. Parsed NIF has export slot after
  name, one `param` per name, return type after parameters (`N/src/nimony/decls.nim` 170-180,
  243-249; `N/doc/tags.md` 59, 70). Each routine of plugin API is `proc`
  (`N/src/nimony/lib/plugins.nim`: 122 `proc`, 7 templates, no `func`). `func` may not call one:
  "cannot call a routine with side effects from a `.noSideEffect` context" (`language.md` 3054,
  3090; `review/emitters/evidence/func_build.log`). Output is statement list: after lone `(type
  ...)` of enum, importer finds no `$` (``undeclared identifier: 'dollar`.Basis'``,
  `review/emitters/runs/lonetype.txt`). Plugin that parses Nim text imports `nimparser`, and builds
  parser with it (`plugins.md` 640-648): one template call then costs 72.2 s CPU, against 11.0 s for
  NIF builder (`verify/single/plugin_parser_cost/summary.txt`).

### S6

- **Nim 2 library:** Macro parameters `static[T]` (`defineBasis(dimensions: static[int])`,
  `defineOperator`); call site `cayley = CAYLEYS_WEDGE.base`
- **Port:** `static[T]` parameters, as Nim 2 library; `defineBasis` takes names of bases in place of
  `dimensions` (S9, S10). Call site `cayley = static(CAYLEYS_WEDGE.base)`; `defineBasis(names =
  static(BASIS_NAMES))`
- **Origin:** design
- **Evidence:** Argument for `static[T]` must be constant expression, and general CTFE is never
  implicit (`sem.nim` `semStaticExpr` 193-197). Field of constant is no constant expression: call
  fails with "write `static(expr)` to evaluate it at compile time" (`sigmatch.nim` 275-277). Name of
  constant is one (`staticmatches.nim` `isConstantArg` 192-199), and reaches plugin as name, not as
  value (`review/operators/probes/constname/`). So each call writes `static(...)`, and plugin
  receives literal value. Plugin rejects name with message, at argument (`emitters.nim` `emit`).
  Macros `defineMultivectors` and `defineBasisElementConstructors` of Nim 2 library have no
  parameters; their templates take `static[T]` values too (S9).

### S7

- **Nim 2 library:** `import ./algebra {.all.}`
- **Port:** Plain import; helpers exported; `pga.nim` hides them again with `export ... except`.
  `algebra.nim` re-exports `basis.nim` without `BasisDigits`, `toBasisDigits` and `toBasisName`, so
  `cayleys/functions.nim` and suite import `basis.nim` for them. `operators.nim` imports `horizon`
  by name from `cayleys/functions.nim`, where Nim 2 library imports `cayleys {.all.}`, and
  `cayleys.nim` re-exports no routine of `cayleys/functions.nim`. `cayleys.nim` re-exports
  `cayleys/types.nim` without its four private types, without `toBasesSigned`, and without fields of
  its three private enums (`Left`, `Right`, `Bulk`, `Weight`, `Base`, `Anti`). `==` of `Order` is
  exported too. `multivectors.nim` exports `index`, so constant of importer can read `m[b]` (L32),
  and `pga.nim` hides it with `export multivectors except index`
- **Origin:** missing + defect, worked around
- **Evidence:** `import m {.all.}`: "wrong `import` statement". `export m except b` hides no `b`
  that `m` re-exports from other module: `doExportExcept` skips name of other module ("doesn't
  belong to exported module, no need to consider", `N/src/nimony/semimport.nim` 438-444), though
  that name still reaches importer (`verify/single/export_except/`), where Nim 2 hides it. Without
  that early return, local build of 941d128 matches Nim 2 for all 12 importers of reproduction.
  Tests `treexport*` of Nimony, 8 in all, do not change (`upstream/S7.md`). So module that
  re-exports leaves name out itself, and `pga.nim` cannot hide `horizon` of `cayleys/functions.nim`
  with `export cayleys except horizon`. `export m except T` of enum type `T` leaves fields of `T`
  exported, and Nimony ignores `{.pure.}` (`N/src/models/nimony_tags.nim` 362), so field names stand
  after `except` too. Else importer's own `enum Left, Right` fails at `ord(Right)`
  (`review/own-cayleys/probes/out/p23_enum_clash_rga3d_*.txt`). `except` hides bare name alone: call
  still finds each exported routine of module that declares type of its argument
  (`N/doc/language.md` 1248-1283). So importer of `pga` can name only public names of Nim 2 library,
  and type `BasesSigned` (S8) (`verify/final_port/summary.txt`, rows `hidden`, which test bare
  name). Its call `toBasesSigned(x)` builds, where Nim 2 has no such name
  (`review/own-cayleys/probes/out/p10_to_bases_signed_rga3d_tree.txt`). Helper stays out of reach of
  call only while other module declares type of its parameter: `Basis` comes from `basis.nim` (S1),
  and table types from `cayleys/types.nim` (S2). With type and helper in one module, importer's call
  builds, whatever `except` lists (`review/umbrella-api/probes/attached/`). Importer of
  `pga/algebra` sees helpers too. Pinned compiler compares `Order` values with `==` of system.
  Master 1df3edf5 has no implicit `==` of distinct type, so `cayleys/functions.nim` needs that
  export there (`review/own-cayleys/runs/rb_tree2_with_ct14_rga3d_cga3d.txt`).

### S8

- **Nim 2 library:** Cell is `seq[BasisSigned]`, written out in `Cayley1D` and `Cayley2D`; no type
  of its own
- **Port:** New public type `BasesSigned`: object of `array[(when IS_CONFORMAL: 2 else: 1),
  BasisSigned]` and count, with `len`, `[]`, `[]=`, `items`, `add` (of term, of cell, and of cell to
  `seq`), `find`, `delete` and `$` in `cayleys/types.nim`. `[]`, `[]=` and `delete` check position
  against count, as `seq` does, with text of Nim 2: "index 3 not in 0 .. 0", "index out of bounds,
  the container is empty", "index out of bounds: '1' < '1' failed". `assert` in `[]` and `[]=`,
  which `-d:danger` removes as it removes bound check of Nim 2; `-d:noAssertions` removes it too,
  and `--boundchecks:off` keeps it. `doAssert` in `delete`, since `delete` of Nim 2 raises in each
  mode. `find` returns position, or -1, as `find` of `seq`. Code of `cayleys/` keeps `seq` form,
  apart from `x.toBasesSigned` for `@[x]`, `default(BasesSigned)` for `@[]`, and `find(x)` for
  `findIt(it == x)`
- **Origin:** design
- **Evidence:** Constant `seq` reaches plugin in compiler's own layout, `len` and `data` of `uarray`
  (`N/src/nimony/exprexec.nim` `unravelPtrUarrayField` 486), so plugin would read compiler internal.
  Array reaches it as plain `(aconstr ...)`. Bound: one term for metric of each basis, and second
  where metric pairs conformal vectors (`constructMetric`). No cell of any table needs more, at any
  dimension (H1). Cell that needs more stops build in `add`, with message (`verify/tc/single/`).
  Position past count stops program in debug and `-d:release` builds, as in Nim 2. Under
  `-d:danger`, `[]` checks nothing, as in Nim 2, and `delete` still stops
  (`review/own-cayleys/runs/probes_set02.txt`, `probes_set03.txt`). Texts after prefix of assertion
  (L31) and `[]=`: `review/fix/f1/r_read.pinned.log`, `r_empty.pinned.log`, `r_delete.pinned.log`,
  `r_set.pinned.log`. Proposal P12 of `pga_benchmark` gives Nim 2 library same cell, with same three
  forms, same checks, and `find` that returns -1 (`proposals/12-cayley-cells/change.md` of
  `pga_benchmark`).

### S9

- **Nim 2 library:** `constructLutKvector`, `constructVectorParity` inside macro
  `defineMultivectors`; macro `defineBasis` names bases from digits, through `emitEnumBasis` of
  `algebra.nim`
- **Port:** Module level in `multivectors.nim` and `basis.nim`; results reach plugin as
  `static(...)` arguments: sets of `Basis`, and names of bases in order, which `toBasisNames`
  (`basis.nim`) makes. `emitEnumBasis` stands in `emitters.nim`, and takes names. Plugin reads
  tables into `seq` types of its own, `BasisSigned`, `BasesSigned`, `Cayley1D` and `Cayley2D`, with
  basis by position
- **Origin:** design + choice
- **Evidence:** Plugin is program without `Basis`. It reads names of `Basis` fields through
  `needTypes` (`plugins.md` 239-245), and cannot call typed library code such as `grade`. Compiler
  builds plugin without `-d:` defines of build (`N/src/nimony/semos.nim` 544-581). So plugin that
  imported `cayleys/types.nim` would get `Basis` of default algebra
  (`review/arch-plugins/probes/p1_defines/main.pinned.log`). Helpers stay typed over `Basis`, so
  type checking stays. Naming stays in library, in `toBasisName` (`basis.nim`); its inverse
  `toDigits` is in `algebra.nim`.

### S10

- **Nim 2 library:** Macro `defineBasis(DIMENSIONS)` calls `constructAlgebra`, which holds nested
  routines
- **Port:** `const BASIS_NAMES = constructAlgebra(DIMENSIONS).toBasisNames`, then `defineBasis(names
  = static(BASIS_NAMES))`; nested routines kept
- **Origin:** defect, worked around
- **Evidence:** Compile-time call to routine that holds nested routine fails in body phase:
  "ambiguous call: 'inner'", then "cannot evaluate expression at compile time: outer(1)", also as
  plugin argument. Phase is trigger, not `static`: `const` inside routine fails too, and
  module-level `const` of same call builds and prints `2` (`verify/single/nested_static/`).
  Collector copies nested routine twice; fix of 3 lines mends reproduction (`upstream/S10.md`). Not
  patched; constant adds one line.

### S11

- **Nim 2 library:** `constructAlgebra` keeps algebras in `Table[int, Algebra]`, from
  `{...}.toTable`
- **Port:** `array[2..9, Algebra]`
- **Origin:** missing + choice
- **Evidence:** Nimony's `Table` has no `toTable`, and its `[]` is `.raises` (`N/lib/std/tables.nim`
  109-115), so each read needs `try` or `getOrQuit` (101-107). Text of Nim 2 library gives
  "undeclared field: 'toTable'", and `[]` outside `try` gives "cannot call a routine marked as
  `.raises`" (`review/record/probes/s11.pinned.log`; `review/algebra/variants/batch3_pinned.txt`,
  variant `tbl2`). Array keeps subscripts of Nim 2 library, and needs no import.

### S12

- **Nim 2 library:** Checks of defines stop build before `defineBasis(DIMENSIONS)` runs
- **Port:** Constant and call of `defineBasis` stand under `when DIMENSIONS in 2..6`
- **Origin:** choice
- **Evidence:** Without branch, `-d:pga.dimensions=1` reports message of check, and also "cannot
  evaluate expression at compile time: toBasisNames(constructAlgebra(DIMENSIONS))": below 2D,
  `constructAlgebra` has no algebra (`verify/single/s13_no_guard_dimensions_1.log`). With branch,
  build reports message of check alone, as Nim 2 does, for 0, 1, 7 and 10
  (`verify/final_port/summary.txt`, rows `guard`; `review/behaviour/guard/results.txt`). Negative
  value adds three errors "invalid array index type", at `array[1 shl DIMENSIONS, string]` of
  `basis.nim` 132, 136 and 170, outside branch (`review/own-record/probes/guard/guard.dneg.log`).
  Invalid value of define adds errors of its own (L3).

### S13

- **Nim 2 library:** `nim doc` shows docs of each function that macros generate
- **Port:** Plugin writes docs as comment in body of each function, as Nim 2 library does; no reader
  sees them
- **Origin:** missing + defect, not patched
- **Evidence:** Compiler skips comment in body (`N/src/nimony/sem.nim` 5926-5930), so docs cost
  nothing. Plugin API has no way to give docs to declaration. Doc tool of Nimony shows function of
  plugin without docs, on 941d128 and on 1df3edf5, also with docs as decoration of head
  (`review/emitters/probes/docs/`). `nimony doc` of 941d128 fails on any module with constant that
  runs program: "cannot open: ....sc.nif"; master builds it (`review/emitters/probes/doc_const/`).

## Above 6D

Nim 2 library allows `DIMENSIONS` in 2..6, and its comment calls 9D the limit of its digit encoding.
Above 6D, these limits apply.

### H1

- **Limit:** Fixed cell holds 2 terms in CGA, 1 in RGA (S8)
- **Origin:** design
- **Evidence:** Holds at every dimension: metric pairs one pair of vectors only, `𝐞ₙ₋₁` and `𝐞ₙ`
  (`constructMetric`), and product of two bases then has 2 terms at most. Counts agree: port has 2
  in CGA at 7D and 9D, and 1 in RGA at 9D; Nim 2 library, with `seq` cells, has 2 in CGA at 6D-9D
  over all 15 tables, and 1 in RGA at 9D. Both count with tables at run time
  (`verify/single/cell_terms/`). Port builds 2D-6D with tables in constants, so cell that needed
  more would stop that build.

### H2

- **Limit:** At 8D, `for b in Basis`, and `default` of `array[Basis, T]`, never end
- **Origin:** defect, not patched
- **Evidence:** 8D `Basis` has 256 values, in 1 byte. Nimony's `..` counts in type of its bounds:
  `var i = a; while i <= b: yield i; inc i` (`N/lib/std/system/iterators.nim` 14-20), so `i` wraps
  after last value, and loop starts again. `default` of array fills it with same loop. Nim 2 counts
  small ordinal types in `int` (`lib/system/iterators_1.nim` 95-102). `0'u8..255'u8`, and enum of
  256 values: 1001 passes, until `break`, against 256 under Nim 2; `default(array[E, Cell])` with
  `E` of 256 values: no end in 20 s; at 128 values, both compilers agree
  (`verify/single/range_wrap/outputs.txt`). Port at 8D: grade constant runs without end; with
  `items` counted in `int`, run loops without end in `default(Cayley1D)` of `constructMetric`
  (`verify/single/cell_terms/results_port_8d.txt`). 9D `Basis` has 512 values, in 2 bytes, and port
  counts it. Loops that end at `Basis.scalarAnti` wrap too: 4 in `multivectors.nim` of port, and 5
  in Nim 2 library. Fifth is in macro body, which `emitters.nim` holds. So fix belongs in
  `iterators.nim`: `upstream/dropped/patches/H2.diff` tests `a <= b` once, and breaks before `inc`,
  as `items` of `set[T]` does. With it, each reproduction ends with count of Nim 2, also `default`
  of array, which `defaults.nim` 36-38 fills with `..`. Also, 237 of 237 tests of Nimony pass in 9
  folders (`upstream/dropped/H2.md`). Not in `compiler.md`: no supported dimension reaches 256
  bases. Upstream holds defect as nim-lang/nimony#2749, closed: master makes constant `b == high(T)`
  compile-time error by contract (nim-lang/nimony#2880), and closed nim-lang/nimony#2777, which held
  same change as `H2.diff` (`upstream/README.md`). On master 1df3edf5, `for e in E` over enum of 128
  to 255 values fails with "contract violated" (`upstream/H2c.md`); port stays on 941d128.

### H3

- **Limit:** Nim 2 library builds no table at 8D or 9D
- **Origin:** Nim 2
- **Evidence:** "VM problem: stack frame too large"
  (`verify/single/cell_terms/ref_compile_time_8d.log`).

## Language

### L1

- **Nim 2 library:** `{.compileTime.}` on derivation
- **Port:** Removed
- **Origin:** design
- **Evidence:** Pragma undeclared. Nimony evaluates `const` by compiling ordinary code (`porting.md`
  §9); no VM split.

### L2

- **Nim 2 library:** `{.experimental: "strictFuncs".}`; `{.experimental: "codeReordering".}`
  (`algebra.nim`, `cayleys.nim`, `multivectors.nim`)
- **Port:** Removed
- **Origin:** design
- **Evidence:** Unsupported pragma, each (`review/multivectors/runs/a1_reorder.txt`,
  `a3_strictfuncs.txt`). `func` is free of side effects by default (`differences.md`). Body of
  routine sees what module declares later, so `{}` stays before `LUT_BASES_BY_GRADE` in
  `multivectors.nim` (`review/multivectors/runs/a2_forward.pinned.txt`); `const` and `static(...)`
  do not (S3).

### L3

- **Nim 2 library:** `{.define: "pga.dimensions".} = 4`
- **Port:** `{.intdefine: ...} = 4`, `booldefine`
- **Origin:** missing
- **Evidence:** `language.md` 4869 describes `intdefine`, `booldefine`, `strdefine`; generic
  `define` absent (`sempragmas.nim` 631). Nimony compares name of define as written, where Nim 2
  ignores case and underscores. With `-d:pga.DIMENSIONS=2`, `-d:pga.isConformal` or
  `-d:pga.floatWidth=32`, port builds default algebra without message
  (`review/own-record/probes/guard/defines.spelling.log`;
  `review/umbrella-api/probes/defines/results.txt`). Boolean define takes no `yes` or `y`, which Nim
  2 takes as true (`N/src/nimony/semdecls.nim` 264-268). Invalid value, such as
  `-d:pga.is_conformal=yes` or `-d:pga.dimensions=abc`, gives message of define first, then more
  errors. Among them are messages of conformal and float width checks, which do not hold; Nim 2
  reports invalid integer alone. With type on define, as `: int`, invalid integer stops compiler at
  `exprexec.nim` 434 assertion, with no message of define, so port gives no type
  (`review/fix/defines_invalid.txt`; `review/own-record/probes/guard/defines.yes.log`).

### L4

- **Nim 2 library:** `static: doAssert DIMENSIONS in 2..6, &"...{DIMENSIONS}..."`
- **Port:** `when DIMENSIONS notin 2..6:` with message in `const` of that branch, then `{.error:
  message.}`. Next two checks are `elif` branches of same `when`
- **Origin:** missing
- **Evidence:** "unsupported statement: staticstmt". Statement `{.error.}` folds only literal or
  constant name, not even `"a" & "b"` (`semconst.nim` 222-232: no in-process folding of `&`);
  constant inside branch is evaluated only when its condition holds. Nimony goes on after
  `{.error.}`: with three `when` statements, two failed checks give "attempt to redeclare: message"
  and first message twice (`review/own-core/logs/guard_00_base.txt`). One chain reports first failed
  check alone, as `static` block of Nim 2 library does, also with `-d:release` and `-d:danger`
  (`review/own-core/logs/cfg_final.txt`).

### L5

- **Nim 2 library:** Zero-initialized `result`, locals
- **Port:** `result = default(T)`, or zero value written out, such as `""`, `{}`, `@[]` and
  `none[Grade]()`; `= @[]` on `seq` local (`bases` of `constructExomorphismMetric`); or `{.noinit.}`
  on lookup-table locals that loop fills whole
- **Origin:** design
- **Evidence:** `porting.md` §4. Module-level `var` needs no initializer: check covers locals
  (`language.md` 1572-1573), and C zeroes global. Cost on pinned compiler: its C holds `default(T)`
  of object as zero fill of temporary array, and builds object from it. gcc keeps two fills, where
  Nim 2 fills once. `initElement` takes 30.9 ns against 11.3 ns of Nim 2 (4D), 54.3 against 30.7
  (6D), and `{}` 22.3 against 13.3 (4D), on final port
  (`review/gap-runtime-cost-and-math-backend/bench/runs/`; R3). Master 1df3edf5 writes one compound
  literal: there, `initElement` of port before review took 13.1 ns, as Nim 2, on loaded machine
  (`runs_before_review/summaryset_master_rga4d.txt`).

### L6

- **Nim 2 library:** `for b in Basis`
- **Port:** Kept, through `items(typedesc[Basis])` in `algebra.nim`
- **Origin:** missing
- **Evidence:** `porting.md` §10 table lists `for e in MyEnum` as missing. Needs patch C7, in one
  module as in several (`verify/abl_single.txt`; `upstream/dropped/P7.md`). At 8D, loop never ends
  (H2).

### L7

- **Nim 2 library:** Two `[]` templates (value, and `var` for `static` basis), each with
  `static(index[B](b))` branch
- **Port:** Value `[]` template as Nim 2 library, without `static` branch (X2); `[]=` template in
  place of `var` template
- **Origin:** design + missing
- **Evidence:** No overloading on `var` alone: both templates match, "ambiguous call" (`{.feature:
  "varToverloads".}`, `language.md` 4852, would allow pair, but each calling module would need it).
  `m[b] = c` needs `[]=`: `sem.nim` `semSubscriptAsgn` 2167-2208 never falls back to `[]` (missing).
  Expansion of `[]` stays assignable, so `m[b] += c` and `/=` work as in Nim 2, and `m[b]` passes as
  `var` argument. `addr m[b]` has no form: Nimony rejects `addr` of expansion of template `[]`
  ("invalid expression for `addr` operation"), also without `pga` and on master
  (`review/umbrella-api/probes/addr/`). Needs patch C9 for method-call syntax on result, e.g.
  `m[b].sqrt` (`verify/abl_single.txt`).

### L8

- **Nim 2 library:** `index` returns `range[0..B.card-1]`: `range[...](b)` for full set, else lookup
  table in `const` inside generic
- **Port:** Same `range` result; counts `card(B * bases_up_to[b]) - 1`, where `bases_up_to` is
  `const` table of `{S..b}` for each `b`, inside `index`; then states bound with one `{.assume.}`
- **Origin:** missing + design
- **Evidence:** `const` inside generic runs without `B` ("undeclared identifier: B"; `semconst.nim`
  144: "XXX future note: consider when the expression depends on a generic param"). `B == {...}`
  does not fold (no set equality in `expreval.nim`), so test compares `card`. Nimony proves `range`
  at compile time and emits no check (`differences.md` 57-64). Prover bounds neither `ord(b)` of
  enum ("cannot prove 'b' is in range 0..3") nor `card(...) - 1`. `{.assume.}` gives programmer's
  word (`language.md` 3167-3190), here true since `doAssert` in `index` checks `b in B`. With `int`
  result, each access keeps bounds check. `const` that does not use `B` works inside generic. Nimony
  writes it once per instance, into C of main module, and declares it `extern const` in each other C
  file. So C compiler folds constant `b` in main module only. In other module, constant `b` costs
  table read and bit count, 20 instructions against one load
  (`review/gap-runtime-cost-and-math-backend/probes/fold/asm_user.txt`). Range set `{S..b}` of
  run-time `b` is loop, one basis per pass (`N/src/hexer/desugar.nim` 731-815). With that loop, 6D
  subset kernel takes 3063 ns against 205 ns of Nim 2 (`verify/final/timing_old_index.txt`). With
  table, it takes 334 ns against 190 ns (`probe_idx/runs6.txt`). For run-time `b`, port still counts
  bits of `B * bases_up_to[b]` on each access, where Nim 2 reads index from table of that `B` (R2).
  C compiler has no `popcnt` by default. Table of index for each `B` does not build: `const` and
  `static(...)` see no `B` in generic, and `let ... {.global.}` fails in C or at link
  (`review/gap-runtime-cost-and-math-backend/probes/idx/`). Table at module level is `extern const`
  in each other C file. 4D subset kernel then takes 89.7 ns, against 65.4 ns with table inside
  `index` (`probe_idx/runs4.txt`). Table read `bases_up_to[b]` keeps one bound check for run-time
  `b`, since unproven index keeps its check (`N/src/nimony/contracts_fir.nim` 3675-3683). Prover
  takes bound from type of `b` only when that type is `range` or integer type, and `Basis` is enum
  (`contracts_fir.nim` 1880-1890, 688-744). `{.assume: Basis.scalar <= b and b <=
  Basis.scalarAnti.}` removes check, and same bound on `ord(b)` does not. 4D subset kernel takes
  64.4 ns without check, against 64.1 ns with it, so port keeps shorter source (`probe_idx/guard/`).
  Timings of this row come from earlier layouts of port, whose `index` gives same C
  (`review/gap-runtime-cost-and-math-backend/findings.md`, finding 7).

### L9

- **Nim 2 library:** `scalar*[I: Basis | Grade | GradeAnti]`, `` `{}`*[G: Grade | GradeAnti] ``
- **Port:** Same single definitions, with `{.untyped.}`
- **Origin:** design
- **Evidence:** Generic body binds once at definition (`porting.md` §10); `{.untyped.}` defers
  checking to instantiation (`language.md` 4312-4326). On master 1df3edf5 with 8 patches of defect
  list, form without `{.untyped.}` builds, and `Grade.scalar` is `low(int)`: no error protects it
  (`review/algebra/probes/behave/l9_masterp_3false.txt`).

### L10

- **Nim 2 library:** `borrowOperationsGrade(T: typedesc)` template
- **Port:** Same template, with `{.untyped, dirty.}`; its six routines keep text of Nim 2 library
- **Origin:** defect, worked around
- **Evidence:** Typed template: `[Bug] (stmts) expected, but got (err ... cannot .borrow)`
  (`semdecls.nim` 1107). Reason: `.borrow` inside generic is meant to wait for instantiation
  (`semdecls.nim` 1177-1183), but gate reads `c.routine.inGeneric`, and nested `func` gets fresh
  routine with 0 (`semdata.nim` 43-44). [Bug] hides errors that typed form gets anyway: "not a type"
  for `T`, as for `untyped` parameter in test `ttemplate_param_as_type.nim` 7-8 of Nimony. With gate
  also reading `c.inGenericDefinition`, generic form `template borrowOps[T](t: typedesc[T])` builds,
  and prints result of Nim 2 (`upstream/L10.md`). Untyped template gives each routine of its body
  fresh symbol, unless routine has `inject` (`semuntyped.nim` 214-218), so operators are not visible
  after call: "type mismatch: got: auto but wanted: GradeAnti". `dirty` injects each declaration
  that is no parameter, and all six operators give results of Nim 2 across modules. `{.dirty.}`
  alone stops at same "[Bug]" (`review/algebra/variants/batch1_pinned.txt`, variants `l10`, `l10b`;
  `batch4_pinned.txt`, `l10dirty`, `l10dirty2`). Not patched: untyped form keeps template of Nim 2
  library.

### L12

- **Nim 2 library:** Parameters `operands_m = default(seq[Basis])`, `operands_n`, `products` of 2D
  `filterBases` (`cayleys.nim`)
- **Port:** Type given: `operands_m: seq[Basis] = default(seq[Basis])`
- **Origin:** defect, worked around
- **Evidence:** Compiler prints "BUG: unhandled type: auto" for call that it checks before
  declaration of callee is complete (`upstream/L12.md`, which gives likely cause). `applyConstant`
  calls 2D `filterBases` above its declaration. Three other filters and suite have no caller above
  them, and keep text of Nim 2 library (`review/record/probes/l12.pinned.log`). Not patched: typed
  form adds one type to each of three parameters.

### L13

- **Nim 2 library:** `Algebra(@[@[""]])`
- **Port:** `toAlgebra(@[@[""]])`, nested in `constructAlgebra`
- **Origin:** missing
- **Evidence:** No conversion from `seq[seq[string]]` to `seq[seq[BasisDigits]]`.

### L14

- **Nim 2 library:** `template in(c, b: BasisDigits)` in `algebra.nim`
- **Port:** Same template, same module; body copies `string(b)` into local first (L17)
- **Origin:** kept; problem avoided
- **Evidence:** Same template in other module is ambiguous with system `in` (`N/lib/std/system.nim`
  143-147): `untyped` parameter matches with no cost, so both rank equal (`sigmatch.nim` 2372-2376,
  3112-3122), and only module of origin breaks tie (`language.md` 1374-1376). Template and its
  caller stay where Nim 2 library has them, so tie never forms.

### L15

- **Nim 2 library:** `iterator items = (for d in ...: yield d)`
- **Port:** Block body (`basis.nim`)
- **Origin:** defect, worked around
- **Evidence:** `finalir.nim` 668 assertion, for any `for` loop in parentheses with body of one
  statement, in iterator or not (`upstream/dropped/L15.md`, which locates cause). Master 1df3edf5
  fixes it (nim-lang/nimony#2970). Not patched: block body differs by one line.

### L16

- **Nim 2 library:** `doAssert FLOAT_WIDTH in {32, 64}`
- **Port:** `!= 32 and != 64`, as `elif` branch (L4)
- **Origin:** missing + defect, worked around
- **Evidence:** Nimony has no set of `int`: "type int64 is too large to be a set element type". In
  `when` and in `const`, `expreval.nim` 674 assertion stops compiler before that message
  (`upstream/L16.md`; `review/own-core/probes/l16/`). Array form `notin [32, 64]` works, at cost of
  one compiled program (`review/record/probes/cnt_l16.txt`).

### L17

- **Nim 2 library:** `c in string(b)`
- **Port:** Local copy first
- **Origin:** defect, worked around
- **Evidence:** C compiler: "lvalue required as unary '&' operand": C code takes address of
  conversion `string(b)`, also for `var` parameter. Likely cause: `semConvArg` keeps `(conv ...)`
  for `distinct string`, where other distinct types get `(dconv ...)` (`upstream/L17.md`). Not
  patched: fix not tested.

### L18

- **Nim 2 library:** `doAssert` (always on)
- **Port:** Local `doAssert` template over `failedAssertImpl` (`algebra.nim`)
- **Origin:** missing
- **Evidence:** Nimony has `assert` only, removed by `-d:danger` (`N/lib/std/assertions.nim` 1-31).
  `failedAssertImpl` is noreturn, so `toBasis` needs no dummy `result`.

### L19

- **Nim 2 library:** `@[]` in first `case` branch (`inclusions` of `constructParts`)
- **Port:** Element type given
- **Origin:** missing
- **Evidence:** "could not infer type for T". `@[]` in later branch takes type of first, so
  `exclusions` keeps text of Nim 2 library (`review/record/probes/l19.pinned.log`,
  `l19b.pinned.log`).

### L20

- **Nim 2 library:** `when compileOption("profiler"): import std/nimprof`, `expandMacros:`, `when
  compileOption("assertions"):` around two `assert`
- **Port:** Removed; plain `assert`, which `-d:danger` removes as gate does
- **Origin:** missing
- **Evidence:** None exists in Nimony: `compileOption` is private to `system/nimrtshim.nim` 56; no
  `nimprof`; `std/macros` has no `expandMacros`.

### L21

- **Nim 2 library:** Assertion messages with `{x}` interpolation
- **Port:** Same content, by concatenation; `$` for `BasisSigned` and for `BasesSigned`, `toBinary`
  for `:b`, and `$` of full multivector for `{norm=}` of suite
- **Origin:** missing
- **Evidence:** No `strformat`; no generic object `$` (`porting.md` §10), which `{norm=}` of Nim 2
  uses for `MultivectorScalars`.

### L23

- **Nim 2 library:** `initElement(if h.is_negated: -1 else: 1)`
- **Port:** `initElement(Coefficient(if h.is_negated: -1 else: 1))`
- **Origin:** missing
- **Evidence:** `if` expression does not pass expected `float` into literal branches: `f(if c: -1
  else: 1)` with `f(x: float)` gives "Type mismatch". Conversion keeps literals of Nim 2 library and
  works at both float widths.

### L24

- **Nim 2 library:** Suite iterator `sampleMultivectors` draws random numbers
- **Port:** Marked `{.sideEffect.}`
- **Origin:** design
- **Evidence:** Iterators are `noSideEffect` by default, and nothing is inferred (`language.md`
  3054, 3090).

### L25

- **Nim 2 library:** `reciprocal = if n != 0: 1.0 / n else: 1.0` and `result[b] = m[b] * reciprocal`
  in `^∙`, `^∘`; `max(1.0, max(abs(a), abs(b)))` in `=~`
- **Port:** `1.0 / float(n)` and `Coefficient(m[b] * reciprocal)`; `max(1.0, float(max(abs(a),
  abs(b))))`
- **Origin:** design
- **Evidence:** Nim 2 types `1.0 / n` and `max(1.0, x)` with `float32` operand as `float` (64-bit),
  and narrows 64-bit product on assignment. Nimony types literal as its `float32` operand, and
  narrows no float value unasked (`language.md` 81, 4853). Conversions state what Nim 2 does. With
  them, at `-d:pga.float_width=32` regression is identical to Nim 2: rga3d 11186 lines and cga5d
  48732 lines (`verify/final_port/summary.txt`, rows `regress_f32`), and cga3d 11620 lines
  (`verify/final_port/summary_extra.txt`). `=~` agrees on pairs whose difference equals tolerance
  (`review/own-kernels/runs/final_cmp.txt`, also for cga3d). Without them, regression of port before
  review differs in 46 lines of rga3d and 76 of cga5d
  (`verify/final_port_before_review/summary.txt`). Each value differs by one unit in last place of
  `float32`, and `=~` differs on such pairs. At 64 bits, conversions do nothing.

### L26

- **Nim 2 library:** `float` into `Coefficient` without conversion: `result[b] = gauss(mu, sigma)`
  in suite; at `-d:pga.float_width=32`, also each float literal or value that importer passes
- **Port:** `Coefficient(gauss(mu, sigma))` in suite; importer converts too
- **Origin:** design + choice
- **Evidence:** Only widening conversion is implicit (`N/doc/language.md` 81). Narrowing of float
  value needs `{.feature: "lenientFloats".}`, since it can lose precision
  (`N/src/nimony/sigmatch.nim` 1893-1898, nim-lang/nimony#1899). `language.md` 1087 still lists
  `float64` to `float32`, as Nim 2 manual does. Shows only at `-d:pga.float_width=32`. With that
  feature in suite, line of Nim 2 library builds and passes at both widths
  (`review/own-tests/optional/behaviour-12.diff`). Port converts: one local conversion, valid Nim 2,
  where feature loosens whole module. Importer meets same rule. Routine with `Coefficient` parameter
  rejects float literal that `float32` does not hold exactly, such as `e1(1.7)` or `m =~ 0.7`, and
  each `float` value. Importer writes `Coefficient(0.1)` or `0.1'f32`, or puts feature in its own
  module (`review/behaviour/tc/typing_f32.rga3d_f32.txt`, `tc/lenient.rga3d_f32.txt`).

### L27

- **Nim 2 library:** `const` in bodies of `test` (`suites.nim` 112-115, 129-132)
- **Port:** `let` (X3)
- **Origin:** defect, worked around
- **Evidence:** Compiler checks each argument of call before it picks overload, also argument for
  `untyped` parameter, then drops result (`N/src/nimony/semcall.nim` 1680, `sigmatch.nim`
  1562-1564); expansion checks body again. Body of `suite`, then `test`, is checked 4 times, so each
  `const` program there would run 4 times. Same pass runs compile-time code with bindings that
  program does not use, and can raise errors that Nim 2 does not. Nim 2 and `language.md` 4436-4437
  do not check `untyped` argument. Constant in n nested `untyped` calls runs 2^n times for n = 0 to
  3, on 941d128 too; under Nim 2 it runs once (`upstream/L27.md`).

### L28

- **Nim 2 library:** Nested `proc generateUpTo`, called from `func constructAlgebra`
- **Port:** `func`
- **Origin:** design
- **Evidence:** Call of `proc` fails: "cannot call a routine with side effects from a
  `.noSideEffect` context" (`verify/single/proc_in_func/build.log`). Nimony treats plain `proc` as
  having side effects by default (`language.md` 3054), where Nim 2 infers that it has none.

### L29

- **Nim 2 library:** `{.error: "..."}` on routine: `==` of `Multivector` (`multivectors.nim`),
  `normCenter` (`pga.nim`); call prints text of pragma
- **Port:** Same text
- **Origin:** design
- **Evidence:** Call stops build under both compilers. Nimony prints "'==' is not available for type
  <MultivectorOf[]>", and drops text of pragma (`language.md` 3410-3411; `N/src/hexer/duplifier.nim`
  1968-1985). It checks only code that it generates: `compiles(m == n)` is `true`, and `typeof(m ==
  n)` and `sizeof(m.normCenter)` build, where Nim 2 rejects each
  (`review/multivectors/runs/c1_eq.*.rga3d.build`; `review/behaviour/tc/misc2.rga3d.txt`,
  `tc/cga.cga3d.txt`).

### L30

- **Nim 2 library:** `Basis` is `{.pure.}` (`newEnum(pure = true)`): its field loses against other
  symbol of same name
- **Port:** Plugin emits `{.pure.}` too, with no effect
- **Origin:** missing
- **Evidence:** Nimony ignores `pure` (`N/src/models/nimony_tags.nim` 362). Where importer declares
  enum field with name of basis, as in `Compass = enum N, E, S, W`, `ord(S)` and `$S` fail with
  "Type mismatch"; Nim 2 takes field of importer (`review/umbrella-api/probes/pure_clash.nim`,
  `out/pure_clash.*`). Other uses agree, such as `let c = S` and `c == S`
  (`review/umbrella-api/tc/api_pure.rga3d.pinned.txt`).

### L31

- **Nim 2 library:** Failed check raises `AssertionDefect`, `IndexDefect`, `UnpackDefect` or
  `ValueError`, which caller can catch; message and stack trace go to stderr
- **Port:** Same cases fail, in debug, `-d:release` and `-d:danger` builds. Process ends with exit
  code 1 and no stack trace. `doAssert` and `get` of empty `Option` write to stdout, and index check
  to stderr
- **Origin:** design + missing
- **Evidence:** Nimony has exception system of its own (`differences.md` 56). Its `get` of empty
  `Option` ends program, "since exceptions are not yet wired up" (`N/lib/std/options.nim` 15-17,
  30-31). Assertion writes with `echo`, then quits (`N/lib/std/assertions.nim` 11-13); index check
  writes with `writeErr` (`N/lib/std/system/panics.nim` 86). Text after prefix is that of Nim 2 for
  both `doAssert` of `multivectors.nim`, and for `parseFloat` (B6). In library, only `⊛` and its
  alias `partner` reach `get` of empty `Option`, for multivector of mixed grade
  (`review/operators/probes/partner_mixed*.nim`). Cell index past count stops program as in Nim 2
  (S8). Under `-d:danger`, grade past end of `LUT_BASES_BY_GRADE` reads beyond table under both;
  port then stops with "stack smashing detected". Cases and modes:
  `review/behaviour/tc/fail.rga3d.txt`, `tc/modes.rga3d_rel.txt`, `tc/modes.rga3d_dng.txt`,
  `out/streams_port.txt`; for new text of `parseFloat`, `review/own-kernels/runs/errs.pinned.*.txt`.

### L32

- **Nim 2 library:** Constant of importer reads `m[b]` or `cell[i]`, or converts `int(b.grade)`
- **Port:** `m[b]` builds, as `multivectors.nim` exports `index` (S7). `cell[i]` and conversion
  fail: "cannot evaluate expression at compile time"
- **Origin:** defect, worked around + defect, not patched
- **Evidence:** Program of constant of other module lacks routine that template calls and its module
  does not export: `index` of `[]`, until exported (`review/fix/f1/p_mv.port.log`,
  `p_mv.final.log`). Template that reads private field fails in constant of importer: `cell[i]`
  reads `elements`, also on port before review, and with no check in `[]`
  (`review/fix/f1/p_cell.old.log`, `p_cell.v2.log`, `p_cell.final.log`). Conversion of `distinct`
  value to its base fails as whole constant. Importer uses `len` and `items` of cell, or reads at
  run time (`review/behaviour/repro/constpriv/`, `review/behaviour/tc/const.rga3d.txt`).

## Standard library

`N/lib/std/` has no `strformat`, `sugar` or `unittest` module.

### B1

- **Nim 2 library:** `strformat` (`&`, `fmt`, `{c:+1G}`)
- **Port:** Concatenation; `strutils.formatFloat` with `precision = -1`, `toUpperAscii` and sign
  reproduce `+1G`, as `strformat` of Nim 2 does (`lib/pure/strformat.nim` 521-556)
- **Origin:** missing
- **Evidence:** No module. Text equals C `%+G` for 1800045 values, in debug, `-d:release` and
  `-d:danger` builds, and `$` of multivector prints text of Nim 2
  (`review/own-kernels/runs/final_cmp.txt`). Cost: `$` takes 1.12 to 1.13 times time of Nim 2, where
  C `snprintf` takes 0.74 (R7, optional change O20).

### B2

- **Nim 2 library:** `sugar.collect`, `=>`
- **Port:** Loop for `collect` (`basis.nim` `generateUpTo`), `mapIt` for `=>` (B4), loops in
  `emitters.nim`
- **Origin:** missing
- **Evidence:** No module.

### B3

- **Nim 2 library:** `seq & seq`
- **Port:** `concat`
- **Origin:** missing
- **Evidence:** `&` for strings only (`system/stringimpl.nim` 970); `concat` at `sequtils.nim` 27.
  Cells take `add` and `find` of their own (S8).

### B4

- **Nim 2 library:** `prev[i-1].map(digits => digits & digit_new)`
- **Port:** `concat(prev[i], prev[i-1].mapIt(it & digit_new))`
- **Origin:** missing (`=>`, `&` of `seq`)
- **Evidence:** No `sugar`, and `&` for strings only (B3). `mapIt` captures no `i` of caller, in 9
  contexts under pinned compiler and unpatched 941d128, as locals of template get fresh symbols
  (`upstream/dropped/B4.md`).

### B5

- **Nim 2 library:** `countTrailingZeroBits`
- **Port:** `trailingZeroBits`
- **Origin:** missing (other name)
- **Evidence:** `bitops.nim` 75. Call runs only when input is not 0, so zero input, where two
  differ, never occurs.

### B6

- **Nim 2 library:** `strutils.parseFloat(s): float` (raises)
- **Port:** `parseutils.parseFloat(s, var x)`, whole input checked by `doAssert`, with text of Nim 2
  (`invalid float: abc`)
- **Origin:** missing
- **Evidence:** `strutils.nim` has none; `parseutils.nim` 229. Invalid literal stops program with
  "[Assertion Failure] invalid float: abc", where Nim 2 raises `ValueError` (L31;
  `review/own-kernels/runs/errs.pinned.d.txt`). Grammar is that of Nimony's parser, port of Rust's
  `dec2flt` (`parseutils.nim` 223-236). It reads `infinity`, which Nim 2 rejects, and no lone `.`,
  which Nim 2 reads as 0.0; `-nan` loses its sign bit. Of 90 literals, 83 agree, each with same bits
  (`review/multivectors/runs/p1_parse.*.txt`; `review/behaviour/tc/literals.rga3d.txt`).

### B7

- **Nim 2 library:** `string &= Rune`
- **Port:** `add`
- **Origin:** missing
- **Evidence:** `unicode.nim` 355 gives only `add`.

### B8

- **Nim 2 library:** `for b in someSlice`
- **Port:** `for b in someSlice.a .. someSlice.b`
- **Origin:** missing
- **Evidence:** `items` exists for `openArray`, `set`, `string` only.

### B9

- **Nim 2 library:** `std/unittest`
- **Port:** `tests/unittest.nim`: same status lines. Under `-d:nimUnittestAbortOnError:on` (also
  define with no value) it exits 1 inside first failed check, as Nim 2 module does. Otherwise
  `exitOnFailure`, last line of suite, exits 1 where any test failed, as Nim 2 module does when
  program ends. Failed assertion in test body ends program at once (L31), where Nim 2 module marks
  test `[FAILED]` and runs next test. Test files keep testament header of Nim 2 library, which
  nothing reads under Nimony
- **Origin:** missing
- **Evidence:** No module, and no exit hook in Nimony's library: probe with one failed test exits 1,
  and with none exits 0 (`verify/single/exit_status.txt`). Two failing probes give output and exit
  code of Nim 2 in modes `on`, `off` and no define, also with `-d:release` and `-d:danger`. Only
  location prefix of check line differs (`review/own-tests/probes/fail/final*/vs_nim2.txt`). Nim 2
  module also prints value of each operand of failed comparison that is no literal
  (`lib/pure/unittest.nim` 656-697). Assertion in test body:
  `review/tests/probes/fail/nim2/run_assert_probe_none.log`, `nimony/run_assert_probe_none.log`.
  `cmd` of header holds `--hints:on`, which is no option of `nimony`: build prints usage text, and
  builds nothing (`review/tests/probes/misc/stub_cmd.build.log`).

### B10

- **Nim 2 library:** `random.gauss`
- **Port:** `gauss` in suite: ratio of uniforms, as `gauss` of Nim 2
- **Origin:** missing
- **Evidence:** Not in `random.nim`. Generator, seeding and integer draws of Nimony's module are
  those of Nim 2 (`N/lib/std/random.nim` 29-70); `rand(max: float)` rounds differently (83-85).
  Suite draws samples of Nim 2: same zero pattern, largest relative difference 7.3e-12 at 64 bits,
  bit-identical at 32 bits (`review/own-tests/dump/out/`); each test runs as many checks as under
  Nim 2 (`review/own-tests/count/out/`).

### B11

- **Nim 2 library:** `assert` in `system`
- **Port:** `import std/assertions`
- **Origin:** design
- **Evidence:** `assertions.nim` 1-31.

### B12

- **Nim 2 library:** `$` of `char` in `system`
- **Port:** `import std/strutils` (`cayleys/functions.nim`)
- **Origin:** missing (other module)
- **Evidence:** Nimony has it in `N/lib/std/strutils.nim` 240 alone.

### B13

- **Nim 2 library:** `for operand, product in exomorphism` (`cayleys.nim`): `pairs` of `array[Basis,
  T]` gives key as `Basis`
- **Port:** Same loop; `iterator pairs*[T](a: array[Basis, T]): (Basis, T)` in `cayleys/types.nim`
- **Origin:** missing
- **Evidence:** Nimony has `pairs` for `openArray` alone, with `int` key
  (`N/lib/std/system/openarrays.nim` 69), so without iterator `result[operand]` takes `int` index.
  Same iterator in `algebra.nim`, beside `items` of `Basis`, stops build of grade table on pinned
  compiler: "expression expected; tag: typevar"
  (`review/cayley-types/tree_pairsgen/build_suite_algebra_variant.log`). Importer of `pga` gets
  `Basis` key for 1D table, 2D table and array of its own, also inside `const`
  (`review/own-cayleys/probes/out/`, `q2`, `q3`, `q4`).

### B14

- **Nim 2 library:** `echo m` prints multivector through `$`
- **Port:** Same `$`; importer writes `echo $m`
- **Origin:** design
- **Evidence:** Nimony's `echo` calls `write stdout, x` (`N/lib/std/syncio.nim` 460-464), and no
  `write` takes object (288-326). `echo m` gives "Type mismatch"
  (`review/multivectors/runs/c4_echo.pinned.rga3d.build`).

### B15

- **Nim 2 library:** `std/math` calls C library: `sqrt` in norms, `^∙`, `^∘`; `pow` in
  `TOLERANCE_ABS`; `binom` in `LUT_BASES_BY_GRADE`; `sqrt` and `ln` in `gauss` of suite
- **Port:** Same calls. Default build takes routines of Nimony; `-d:useLibcIo` takes those of C
  library
- **Origin:** design
- **Evidence:** Nimony defines `nimNativeIo` unless `-d:useLibc` or `-d:useLibcIo` is given
  (`N/src/nimony/nimony.nim` 430-438). `std/math` then imports `math/power.nim` and others, not
  `math/cmath.nim` (`N/lib/std/math.nim` 5-16). `sqrt` (port of musl, `math/power.nim` 57-105) and
  `binom` give bits of Nim 2 on 80066 and 496 inputs. `pow`, `ln` and `cos` differ by one unit in
  last place on 1 % to 10 % of inputs (`review/gap-runtime-cost-and-math-backend/mathdiff/`).
  Library sees it in `TOLERANCE_ABS` alone. At 64 bits, `-d:pga.float_tolerance=` 5, 11, 17, 20, 21,
  24, 29, 32 or 39 gives other value than Nim 2 (`review/own-core/logs/cfg_final.txt`). Default 9,
  and each tolerance 0..40 at 32 bits, give value of Nim 2. With `-d:useLibcIo`, each value is that
  of Nim 2, also in constants. Suite and regression give same status and same bytes with flag as
  without (rga3d, cga3d, also with `-d:danger`;
  `review/gap-runtime-cost-and-math-backend/flags/results.txt`, port before review). Own `sqrt` is
  call into other C file, which costs time (R1).

## Run time

Release builds (`-d:release`, gcc 13.3), one kernel per class of public routine, operands in C
locals under both compilers. Times are of final port on idle machine, load average 1.0 to 1.6:
minimum over 10 rounds of fastest batch
(`review/gap-runtime-cost-and-math-backend/bench/runs/TABLE.md`). For 101 of 144 ratios, port before
review, on loaded machine, came within 0.05 of these (`runs_before_review/TABLE.md`). Time of kernel
can depend on code around it. `verify/bench.nim` times 6 kernels in one routine under both
compilers, and gives `∨` 1.01 and subset kernel 1.03 at 4D, where `TABLE.md` gives 0.68 and 1.45
(`verify/final_single/timing.txt`). Under Nimony, `-d:danger` changes times by at most 9 % at 4D and
3 % at 5D, apart from `grade`.

### R1

- **Routines:** Norms, `^∙`, `^∘`, `^`
- **Port / Nim 2:** 4D 1.6 to 2.6; 5D 1.9 to 3.4; 6D 1.1 to 1.4. With `-d:useLibcIo`: 0.93 to 1.00;
  1.0 to 1.8; 0.95 to 1.02
- **Cause:** Own `sqrt` of Nimony is call into other C file, 8 to 17 ns more per kernel than
  `sqrtsd` (B15)

### R2

- **Routines:** Run-time basis on subset multivector: `toMultivectorOf`, `toMultivector`,
  `toMultivectorScalars`
- **Port / Nim 2:** Subset kernel 1.45 (4D), 2.0 (5D), 1.71 (6D); conversions 1.1 to 2.5, 2.2 to
  2.8, 1.8 to 2.1
- **Cause:** Bit count per access (L8)

### R3

- **Routines:** `result = default(T)`: `initElement`, `{}`, conversions
- **Port / Nim 2:** `initElement` 2.7 (4D), 2.6 (5D), 1.77 (6D); `{}` 1.68, 2.3 to 2.4, 0.98
- **Cause:** Two zero fills (L5)

### R4

- **Routines:** Short routines that return `Multivector`: `+`, `-`, scalar `*`, generated unary
  operators, constructors
- **Port / Nim 2:** 5D: `+` 3.0 to 3.3, negation 2.0 to 2.9, scalar `*` 2.4. `~` and `\` 3.5 to 4.8,
  constructors 2.4 to 2.6, other unary operators 1.1 to 2.0. 4D: 1.07 or less. 6D: 0.91 or less,
  apart from constructors, 1.72, near `initElement` (R3)
- **Cause:** gcc keeps copies of 256-byte result in memory, and its loads cross two stores. clang 18
  on same C: `+` takes 2.6 ns, against 6.0 ns of Nim 2 with gcc

### R5

- **Routines:** Products `∧`, `∨`, `⟑`, `∨★`
- **Port / Nim 2:** 4D 0.68 to 0.99; 5D 1.12 to 1.34; 6D 0.85 to 1.16
- **Cause:** As R4 at 5D; at 6D, `⟑` keeps operands on stack

### R6

- **Routines:** `grade`
- **Port / Nim 2:** 0.35 to 0.92
- **Cause:** Not examined

### R7

- **Routines:** `$`
- **Port / Nim 2:** 1.12 to 1.13
- **Cause:** `formatFloat` of Nimony (B1), not examined further. With C `snprintf` for `%+G`
  (optional change O20), `$` takes 0.74 at 4D, with same text (`runs/summaryset_o20_rga4d.txt`)

## Simplified

### X1

- **Nim 2 library:** Lookup tables in compile-time-only `toBasis`, `toFlags`,
  `isNegatedFromOrderLexicographic`
- **Port:** Direct computation; `toBasis` searches bases, with `==` borrowed for `BasisFlags`
- **Reason:** Each `const` costs Nimony one compiled program (`porting.md` §9, about 5 s). These run
  only at compile time, natively, so table saves nothing. Run-time `grade` table kept. Table of
  `toBasis` does not build as written: Nimony indexes `array[size_of_flags, T]` by base type, and
  `BasisFlags` value gives "Type mismatch" (`review/record/probes/x1_tobasis.pinned.log`).

### X2

- **Nim 2 library:** `when compiles(static(b)): m.elements[static(index[B](b))]`
- **Port:** `m.elements[index[B](b)]`
- **Reason:** Nimony decides `when` of template where template is defined, and `compiles(static(b))`
  is false there for parameter `b` (`sem.nim` `semWhenImpl` 2497-2529;
  `review/multivectors/probes/w1_when_compiles.nim`, `runs/w1_when_compiles.*`). Text of Nim 2
  library builds, and its `static` branch never runs, so port leaves it out
  (`review/multivectors/runs/check_e6c_static_branch.pinned.txt`). `index` is `inline`, its `range`
  result removes bounds check, and its table is in C of main module (L8). So constant `b` folds in C
  there, and costs table read and bit count in each other module. Lost: constant out-of-set index on
  subset multivector fails at run time (`doAssert`), not at compile time. `{.requires: b in B.}`
  gives only run-time check, since prover cannot decide set membership.

### X3

- **Nim 2 library:** `const` for test data `ELEMENTS`, for 6 values of two tests (`suites.nim`
  112-115, 129-132), and for `digits_valid` in `toBasisDigits`
- **Port:** `let`
- **Reason:** Each `const` that calls routine costs Nimony one compiled program, and L27 runs those
  of tests 4 times. Values are same at run time, and library runs none of them at run time. Two
  tests then check `$` and `toBasisName` at run time, where Nim 2 needs `const` for its
  compile-time-only routines (L1). Clean suite build on earlier layout of port, in alternating runs:
  rga4d 46.9 s to 35.8 s, and rga6d 121.0 s to 83.6 s. 42 programs replace 51
  (`verify/single/let_ab/`).

## Compiler patches (`compiler.md`)

For each patch, compiler that lacks only that patch fails to build rga3d suite on source of port,
1f09934e0068b5ec (`verify/abl_single.txt`; its logs in `verify/abl_single/` carry earlier patch
numbers, which that file maps). Last column gives first error. Module layout of S2 avoids defects of
constant programs that no patch mends (S2). Compiler with all 9 patches builds all 9 algebras, and
suite and regression match Nim 2 (`verify/final_port/summary.txt`, diff 9ca500b51259c999). Upstream
master fixes C6 (nim-lang/nimony#2866), C7 (nim-lang/nimony#2909) and C9 (nim-lang/nimony#2884) by
2c5b3dca, and C1 (nim-lang/nimony#2970), C4 and C5 (nim-lang/nimony#2949) by 1df3edf5, apart from
`dconv` case of `upstream/P5d.md` (`upstream/README.md`).

### C1

- **File:** `exprexec.nim`
- **Defect:** Each serializer loop names its index `idx.0`, so inner loop declares second `idx`,
  which outer increment and subscript then use, and outer index stays 0
- **Effect without patch:** Hang: `.out.nif` repeats first row without end (30 GB in 4 minutes), for
  constant array of arrays or of `seq`; `seq` of `seq` works (`upstream/dropped/P1.md`)
- **Review:** clean. Master 1df3edf5 fixes it (nim-lang/nimony#2970)
- **rga3d without it:** pga/multivectors.nim(58, 40) Error: cannot evaluate expression at compile
  time: constructLutKvector(), after "index out of bounds: 4 notin 0..3" in its program; then
  pga/cayleys/definitions.nim(36, 20) Error: cannot evaluate expression at compile time: block: (let
  base: array[0..7, array[0..7, BasesSigned]] = constructProductExterior(CAYLEYS_COMPLEMENT, Base);
  ..., and "File size limit exceeded": `.out.nif` reaches limit of 2 GB that run sets; cache grows
  to 5.9G (`verify/abl_single/port_single_P1_rga3d.log`)

### C2

- **File:** `expreval.nim`
- **Defect:** No folding of `CONST.field`
- **Effect without patch:** `static(CAYLEYS_WEDGE.base)`, even `const b = C.field`, cannot be
  evaluated. Patch covers field alone: element of tuple or array constant still fails.
  `upstream/P2.md` extends it to elements, for master
- **Review:** clean (in-process folding is upstream's practice)
- **rga3d without it:** pga/operators.nim(43, 37) Error: cannot evaluate expression at compile time:
  CAYLEYS_PARTS.bulk.round

### C3

- **File:** `exprexec.nim`
- **Defect:** Copied constant value names private fields by `Ident`
- **Effect without patch:** Constant that uses value of other constant with private fields:
  "undeclared field"
- **Review:** clean
- **rga3d without it:** pga/cayleys/definitions.nim(30, 33) Error: cannot evaluate expression at
  compile time: block: (let base: array[0..7, BasesSigned] =
  constructExomorphismMetric(CAYLEY_METRIC); ..., then pga/cayleys/types.nim(28, 18) Error:
  undeclared field: 'elements' for type BasesSigned

### C4

- **File:** `exprexec.nim`
- **Defect:** `distinct` value written as base without conversion, and its type without space
- **Effect without patch:** Constant of `distinct` type cannot be written: "Type mismatch" at
  `writeNifInt`. With C4 alone, value is written, and its reading trips C5
  (`upstream/dropped/P4P5.md`). Master 1df3edf5 fixes it (nim-lang/nimony#2949), which closed
  nim-lang/nimony#2926
- **Review:** clean
- **rga3d without it:** pga/algebra.nim(235, 30) Error: cannot evaluate expression at compile time:
  block: (var lut: array[0..7, Grade]; for b in items(Basis): ..., then Type mismatch

### C5

- **File:** `expreval.nim`
- **Defect:** `(conv Distinct v)` not unwrapped; error path drops one token per two-token wrapper
- **Effect without patch:** "beginRead with unclosed tags" crash; "setJump on Symbol" crash for
  constant `Letter(300)` of `distinct char`, without P4. Master 1df3edf5 fixes crash
  (nim-lang/nimony#2949). `upstream/P5d.md` also unwraps `dconv`, which `const s = @[D(1), D(2)]`
  needs
- **Review:** clean
- **rga3d without it:** compiler assertion `b.openTags.len == 0` "beginRead with unclosed tags"
  (`nifcore.nim` 1920)

### C6

- **File:** `exprexec.nim`
- **Defect:** `const` runs in signature phase, so copied same-module routine has raw body that names
  its callees and types by `Ident` only
- **Effect without patch:** "undeclared identifier" for routine that calls another routine of module
- **Review:** local workaround, not fix to send upstream: matches names, may copy too much; real fix
  checks needed bodies first. Master fixes it by name lookup in scope of module
  (nim-lang/nimony#2866)
- **rga3d without it:** pga/basis.nim(181, 51) Error: cannot evaluate expression at compile time:
  toBasisNames(constructAlgebra(DIMENSIONS)), then pga/basis.nim(85, 31) Error: undeclared
  identifier: Algebra (rerun: `remove.py` leaves one call at other indent, `verify/abl_single.txt`)

### C7

- **File:** `hexer/iterinliner.nim`
- **Defect:** Inlined iterator keeps `typedesc` parameter as run-time local
- **Effect without patch:** Inline iterator with `typedesc` parameter, such as `iterator items(t:
  typedesc[E])`, in one module as in two: "type expected but got: (typedesc ...)"
  (`upstream/dropped/P7.md`)
- **Review:** clean. Master fixes it with same change (nim-lang/nimony#2909)
- **rga3d without it:** pga/algebra.nim(235, 30) Error: cannot evaluate expression at compile time:
  block: (var lut: array[0..7, Grade]; for b in items(Basis): ..., then "type expected but got:
  (typedesc ...)"

### C8

- **File:** `typeprops.nim`, `sem.nim`
- **Defect:** Template-expanded constant inside static aggregate stays `(expr X)`, and helpers that
  peel it misjudge last child of unbounded cursor
- **Effect without patch:** `MultivectorOf[{Basis.scalar..Basis.scalarAnti}]` does not match
  `set[Basis]`
- **Review:** clean
- **rga3d without it:** pga/multivectors.nim(25, 32) Error: `(setconstr (set Basis) (range (expr
  (expr S)) (expr (expr E321))))` does not match constraint `set[Basis]` (module suffixes left out)

### C9

- **File:** `sem.nim` `tryBuiltinDot`
- **Defect:** Re-check of private field access re-stamps access token with module being compiled,
  though token must name writing module "no matter where it is re-checked"
  (`findObjFieldConsiderVis` doc)
- **Effect without patch:** Cross-module template `[]` over private `elements` fails in method-call
  syntax: `m[b].sqrt` gives "undeclared field: 'elements'", while `sqrt(m[b])` works. Nim 2 library
  uses this form 7 times in `operators.nim`
- **Review:** clean: keeps incoming token, one line. Master fixes it with same change
  (nim-lang/nimony#2884)
- **rga3d without it:** pga/multivectors.nim(98, 4) Error: undeclared field: 'elements' for type
  MultivectorOf[]

## Type checking

Kept:
- `Cayley1D = array[Basis, BasesSigned]`, `Cayley2D`, `BasisSigned.basis: Basis`, and derivation
  typed over `Basis`.
- Plugin templates typed `static[Cayley1D]` and `static[Cayley2D]`, as macros of Nim 2 library.
  Object of tables, table with `Basis` cells, and integer `as_unary` fail at call site, before
  plugin runs, under both compilers (`verify/tc/`, `nim2_*`; port: `verify/tc/single/summary.txt`;
  plugin of port: `review/own-emitters/probes/tc/summary.txt`).
- Same-shaped table indexed by integer, `array[0..15, BasesSigned]`, passes `static[Cayley1D]` under
  both compilers. Nim 2 macro then runs on it; port plugin rejects it with message (`emitters.nim`
  `emit`).
- Plugin checks outer index only. `array[Basis, array[0..15, BasesSigned]]` passes it, and table
  indexed by other enum of 16 values fails later, in emitted code: `result[o0] = 0.0` gives "Type
  mismatch" (`verify/tc/single/extra/`). Nim 2 macro signatures accept both
  (`verify/tc/nim2_inner_int.nim`, `nim2_other_enum.nim`).
- Cell of wrong type fails in derivation: `cell.add Grade(1)` gives "Type mismatch", and `cell.add
  BasisSigned(basis: Basis.scalar)` builds (`review/own-record/probes/cell/`).
- Cell that needs more terms than `BasesSigned` holds stops build, with message of `add`
  (`verify/tc/single/nimony_cell_overflow.log`).
- Key of `for operand, product in table` is `Basis` (B13).
- Templates of `multivectors.nim` take `static[T]` too: argument that is no constant fails at call
  site ("Type mismatch"), where plain parameter lets it reach plugin (`review/multivectors/runs/`).
- Name of constant without `static(...)` passes `static[T]`. Plugin rejects it with message:
  "argument must be `static(...)` value, not name of constant; got `CAYLEY_ATTITUDE`"
  (`emitters.nim` `emit`; `review/own-emitters/logs/guard_default.txt`).
- Plugin output is checked again in caller's scope.

Weaker than Nim 2:
- Table indexed by enum or distinct type accepts plain `int` index, which Nim 2 rejects: `cayley[3]`
  of `array[Basis, T]`, `LUT_BASES_BY_GRADE[1]`, and `CAYLEYS_WEDGES_TRANS.base[k]`. `array[Basis,
  T]` rejects `Grade` index (`verify/tc/single/extra/`; `review/behaviour/tc/typing.rga3d.txt`,
  a01-a06; `review/behaviour/probes/cover.nim`). Reason: system overload `` `[]`*[I, T; J:
  SomeInteger](x: array[I, T], i: J) `` (`N/lib/std/system.nim` 26). Origin: design, deliberate and
  tested: commit 4c351242 "fixes nim-lang/nimony#2750: any integer indexes an array relative to its
  index range", test `tests/nimony/misc/tarray_ord_index.nim`. Only way back is distinct or object
  wrapper around each table, at cost of structure.
- Constant out-of-set index on subset multivector fails at run time, not compile time (X2).
  `compiles(...)` of it is `true`, where Nim 2 gives `false` (`review/behaviour/tc/misc2.rga3d.txt`,
  j02).
- `let c: MultivectorOdd = a.toMultivectorOf` with `a: Multivector1` builds, as `B` comes from
  expected type; Nim 2 gives "cannot instantiate: 'B'" (`review/behaviour/tc/typing.rga3d.txt`,
  d11).
- `compiles(m == n)` is `true`, and `typeof(m == n)` and `sizeof(m.normCenter)` build, where Nim 2
  rejects each (L29).
- Call finds exported routine of `cayleys/types.nim` through type of its argument: importer calls
  `toBasesSigned(x)`, which Nim 2 does not have (S7).
- `Basis(99)` builds as constant, and `$` of it is empty string; Nim 2 rejects it
  (`review/behaviour/tc/typing.rga3d.txt`, g01).
- Inside plugin, `Basis` values are names, and positions in `Basis` order, that `emitters.nim` reads
  from NIF trees, not typed values (S9).

Stricter than Nim 2:
- `static` argument of importer must be literal, name or `static(...)` (S6): `e1("1" & ".5")` fails.
  Set of subset type takes names of bases, `Basis.scalar` and `Basis.scalarAnti` only (C8).
  `MultivectorOf[{Basis.origin}]` and `MultivectorOf[{Basis.scalar.succ, Basis.scalarAnti}]` give
  "... does not match constraint set[Basis]". Named constant or `static(...)` works under both
  compilers (`review/behaviour/tc/static.rga3d.txt`; `review/multivectors/runs/c3_subset_*`).
- At `-d:pga.float_width=32`, routine with `Coefficient` parameter rejects float literal that
  `float32` does not hold exactly, and each `float` value (L26).
- Constant of importer cannot read `cell[i]`, or convert `int(b.grade)` (L32).
- `==` of two table objects, such as `CAYLEYS_WEDGE == CAYLEYS_WEDGE`, fails: Nimony has no `==` of
  array of arrays. `==` of two cells builds (`review/behaviour/tc/typing.rga3d.txt`, f04, f05).
- `LUT_BASES_BY_GRADE[GradeAnti(1)]` fails, where Nim 2 takes any `distinct int` as index of
  `array[Grade.low..Grade.high, T]` (a07).
- Cell is no `seq`: `let c: seq[BasisSigned] = table[b]`, `table[b] = @[...]`, `x in cell`, `for i,
  t in cell`, `cell.high`, `default(typeof(cell))` and `for t in mitems(cell)` fail (S8; f01, f02,
  f07, f08, f09, f15; `mitems`: no such iterator in `cayleys/types.nim`).
- Importer writes `echo $m` (B14), has no `addr m[b]` (L7), and no `items` of `Slice` (B8).
