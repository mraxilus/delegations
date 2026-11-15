# P12: Hold each cell of a Cayley table in an array with its count

**What it is.** Each cell of a Cayley table becomes `BasesSigned`, an array of terms beside their
count, in place of `seq[BasisSigned]`. The array holds two terms under the conformal metric, and
one under the rigid metric. This is the change that the TODO of the type block at pin asks for.

**What it is for.** The type of a cell states how many terms a product of two bases can have. A
cell that needs more stops the build, with a message that names the cell. The port of the library
to Nimony holds each cell in the same form, so the library and the port share one cell.

**What it costs.** The compile-time evaluator holds the array of a cell as several nodes, where an
empty `seq` is one node. So the library takes more memory and more time to build. P01, P03 and P10
build cells as `seq`, and the change `imports-narrow` names each import of the operators. So each
of them changes where it lands beside this proposal.

## Problem

At pin, each cell of a Cayley table is a `seq[BasisSigned]`. A TODO at the type block asks for an
array with a count in place of the `seq`, above all for the 1D tables, whose cells hold one term at
most. A `seq` states no bound. But the metric pairs no vectors other than 𝐞ₙ₋₁ and 𝐞ₙ. So a product
of two bases has two terms at most under the conformal metric, and one under the rigid metric.

The port of the library to Nimony already holds each cell as an array with a count, in rows S8 and
H1 of the [Nimony Port of pga](https://claude.ai/artifact/KEr1i8zyWLksRFrmfaBnSM). Under Nimony, a
constant `seq` reaches a plugin in the layout of the compiler, so a plugin reads it only through an
internal of the compiler.

## Idea

- **Cell.** `BasesSigned` holds `terms`, an array of `TERMS_CELL` signed bases, and `count`, the
  number of them that the cell holds. `TERMS_CELL` is 2 under the conformal metric, and 1 under the
  rigid metric. Both fields are private, so a caller reads a cell through its operations alone.
- **Operations.** A new section, Cell Operations, gives the cell the calls that the derivation and
  the operators make on a `seq`: `len`, `[]`, `items`, `$` and `add`. `find` and `delete` serve
  `merge` alone, so they stay private and carry `{.compileTime.}`. The exported operations carry no
  such pragma, so an importer reads and builds a cell at run time. `toBasesSigned` makes a cell of
  one term, as `@[term]` did.
- **Bound.** `add` stops the build where the cell is full, with a message that names the term and
  the cell. So a metric whose products have more terms stops the build, and never drops a term.
- **Derivation.** Each constructor builds its cell with `toBasesSigned`, and each filter empties a
  cell with `default(BasesSigned)`. `merge` finds a term with `find` of the cell, so `sequtils`
  leaves the imports. `slice` takes its cell as it is, since that cell holds one term or none.
  `constructExomorphismMetric` takes the one term of each vector cell with `toSigned`.
- **Module doc.** The order of type bootstrapping in `pga.nim` names `BasesSigned` between
  `BasisSigned` and the tables.
- **Packed form.** The doc comment of the cell names a packed form, which builds faster. It holds
  each term in 16 bits of one `uint64`, as 2 × basis + sign + 1, so 0 marks an empty slot. The
  Architect ruled on 2026-11-08 that the fields stay, because they are easier to understand.

Three cells show the form. An empty cell keeps the default term in its array, and its count hides
that term.

| Cell | At pin | With this proposal |
|------|--------|--------------------|
| 𝐞₄ ⟑ 𝐞₅ at cga5d | `@[𝐞₄₅, −𝟏]` | `terms: [𝐞₄₅, −𝟏]`, `count: 2` |
| 𝐞₁ ⟑ 𝐞₂ at rga4d | `@[𝐞₁₂]` | `terms: [𝐞₁₂]`, `count: 1` |
| 𝐞₁ ∧ 𝐞₁ at rga4d | `@[]` | `terms: [𝟏]`, `count: 0` |

## Alternatives

| Option | Why it lost |
|--------|-------------|
| `seq`, as at pin | States no bound; a plugin of the port reads it through a compiler internal |
| Packed cell in one `uint64` | Harder to read, as the Architect ruled on 2026-11-08 |
| `len` and `[]` as templates | Built; same peak memory at cga6d, and no faster |
| `Option[BasisSigned]` in each 1D table | Two cell types, as the library held before `3121342` |

## Costs

- **Build.** The compile-time evaluator holds each value as nodes. An empty `seq` is one node, and a
  cell of this form is several nodes, empty or not. Most cells are empty, so the tables take more
  memory, and the evaluator takes more time to build them. At cga5d and cga6d `import pga` peaks
  at ×1.50 and ×1.49 of the memory at pin, and takes ×1.66 to ×2.19 of the time over four builds.
  Four build claims bound it: the peak at most ×1.5 and the time at most ×2.5, at each of the two.
  At cga5d the peak is 314.8 MiB against 210.5 MiB, so it holds its bound by 0.3%.
- **Run time.** None. Macros alone read the tables, so each operator emits the same C as at pin.
- **Calls of `seq`.** A caller that reads a cell through another call of `seq`, such as `high` or a
  slice, no longer compiles. No module of the library makes such a call.
- **Size.** A metric that pairs more vectors needs a larger `TERMS_CELL`. The library has no such
  metric.
- **Exports.** At pin, `pga/cayleys.nim` exports no routine, and other modules of the library reach
  its private names through `{.all.}`. This change exports eight routines. Four read a cell: `len`,
  `[]`, `items` and `$`. Four build or change one: `[]` of a `var` cell, both `add` and
  `toBasesSigned`. Only the derivation calls the four that build, so an importer that reads a cell
  needs the first four alone.

## Open decisions

- Export the four operations that build or change a cell, as here, or export the four that read a
  cell alone. Where the four that build stay private, they also carry `{.compileTime.}`, as `find`
  and `delete` do.

## Landing

- **P01, `cayley-derivation`.** It replaces `pga/cayleys.nim` whole, and builds its cells as `seq`.
  So whichever lands second is written again against the first. These edits then quote the file of
  P01, or P01 builds its cells with `toBasesSigned` under a new digest.
- **P03, `partner-sign`, and P10, `homogeneous-scalar`.** P03 builds one map as `@[...]`, and P10
  builds two cells as `@[...]` to compare them with cells of tables. Whichever of each pair lands
  second writes `toBasesSigned` there.
- **Change `doc-comments`.** It adds a line under the TODO of the type block, which this proposal
  removes. So that edit is void once this proposal lands. If that change lands first, this
  proposal quotes its two lines. That change also writes in the header of `pga.nim` that the
  tables hold `seq` per cell. It writes in the header of `pga/cayleys.nim` that each cell holds
  `seq`. Both lines are false once this proposal lands, so whichever of the two lands second drops
  or corrects them.
- **Change `imports-narrow`.** It names each symbol that `pga/operators.nim` imports from
  `cayleys`. The operators read each cell through `items`, so with both applied, in either order,
  the build stops on `type mismatch` at `items(cayley[b])`. Whichever of the two lands second adds
  `items` to the import of `cayleys`.
- **P08, `compound-tables`.** It lands after P01, so it meets this proposal as P01 does. Its own
  edits of `pga/cayleys.nim` touch other lines and write no cell as `@[...]`.
- **Changes `cayleys-hygiene` and `doc-comments-2`.** Each edits other lines of
  `pga/cayleys.nim`, so either order applies. `doc-comments-2` also writes beside `export cayleys`
  in `pga.nim` that a read of a table at run time allocates. That comment is false once this
  proposal lands, so whichever lands second drops it.
- **This project.** `dense.nim` builds each cell of one row of a scale table as `@[...]`, in one
  line. When the pin moves to a library with this proposal, that line writes `toBasesSigned`.
  `cells.nim` reads either cell already.

## Evidence

The tables claims read every table that the library exports at each of the nine algebras, through
`cells.nim`. So each cell holds the same terms as at pin, in the same order and with the same signs.
The suites of the library hold the operators that read the tables. `laws.nim` holds the bound
tight: at each algebra, some cell of ⟑ and of ⟇ holds `TERMS_CELL` terms. Under the conformal
metric it also deletes the first of two terms, and holds the second in place. No table runs that
shift, since `merge` deletes the last term of a cell alone. A copy of `delete` that loses the
second term fails `laws.nim` at cga3d.

A copy whose cell holds one term under the conformal metric stops the build at cga3d, where `add`
names the full cell. A copy whose cell holds three terms there fails `laws.nim` at cga3d.

At rga4d and cga5d, the timed binaries of pin and of this proposal were built from one path. Their
C differs only in the header of the build, and in the number in the name of one instance of
`formatValue`. So no operator emits other C.

The packed form of the doc comment was built on 2026-11-08, under Nim 2.4.0 on
`linux amd64, 4 cores`. It passes the suites at the nine algebras, and its 388 tables equal those
at pin. At cga6d it builds `import pga` in ×0.97 of the time at pin and ×0.81 of the peak memory,
median of seven builds. In that run, pin takes about 9.8 s and 618 MiB, and the packed form 9.5 s
and 501 MiB. On 2026-11-15 this proposal takes 21.6 s and 913 MiB there, and pin 10.2 s and
615 MiB, median of three builds in turn. The evaluation is another run of one build for each side,
so its seconds differ. So the packed form takes about half the time and memory of this one there.
