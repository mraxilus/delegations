# Coding Constitution

You write code in the style of one programmer: a reference document that also runs. Every
rule below is a decision already made. Apply it. Where a task forces you to break one, say so
and write down the cost.

The examples are Nim, in the vocabulary of a reference library for geometric algebra. Transfer
the decision, and not the syntax. `STYLE.md` says how each rule is spelled in Nim. `EXAMPLES.md`
holds longer worked examples, named by the rule that each one shows. Read one where a rule
alone does not settle a case.

## Precedence

1. Task requirements and correctness.
2. The public contracts of a codebase that already exists. Apply this document in full to new
   code, and to code you materially change. Never churn code that you were not asked to
   touch.
3. Between articles, correctness goes over performance, then elegance, then exposition. The
   first article named wins within each tier:
   - correctness: IV (safety), VIII (honesty), IX (tests);
   - performance: VII (cost);
   - elegance: II (derivation), III (notation), V (names), X (form);
   - exposition: I (exposition), VI (documentation), XI (record).
4. Where this document is silent, choose what a careful reader of the finished file would
   prefer. Record the choice with its cost.

Five mechanisms are gated: the bootstrap diagram (I.5), the façade (I.6), generation (II.4),
notation (III.1) and fixed storage (IV.6). Where the condition of a gate holds, the mechanism
is mandatory. Where it does not hold, to use the mechanism is cargo cult.

## Article I: Code is the reference document

1. Order the files and the definitions for a reader who learns the subject, and not for the
   compiler. Use the use-before-definition form wherever the language allows it.
2. Organise by domain concept (`multivectors`, `grammar`, `intervals`), and never by
   architectural role (`ParserManager`, `MultivectorFactory`). Machinery that belongs to no
   concept of the subject is named for what it does, and stays off the exported surface.
3. Every module opens with a header. Its first line states the purpose, and the lines after
   it give the design decisions and the cost of each. A decision without its cost is
   incomplete.
4. A module that implements an authority (a book, a paper, an RFC) carries aligned plain-text
   tables in its header. They map the code names to the notation of the authority, so that
   book and code read side by side. Its columns align by display width, as the eye reads them.
   A table is a derived view of the declarations. Verify the table against them, and where the
   two disagree the declaration wins.
5. **Bootstrap gate.** Where types build each other at compile time, the umbrella header
   states the bootstrap order as a `->` diagram. The diagram is many to one. Each definition
   is the target of one line alone, and that line names everything that the definition needs.
   Definitions that need exactly the same things may share one line.
6. A library of several modules presents one umbrella module, which re-exports its surface.
   Export only what a caller needs, and reach an internal of a sibling deliberately, never by
   a wider export. The internal says so, and names the sibling that reaches it. **Façade
   gate.** Where the surface is symbolic or generated, the umbrella is a façade of documented
   one-line forwarders. It is the API reference that is also source, and the source of truth
   for the public names.
7. A comment states the decision and its cost, and never the path to it. A superseded design,
   an old figure and a fixed bug go to the log (XI). The provenance file keeps only the reason
   that the design is as it is now (VIII.6). A live trap earns one line, and a test that trips
   on it. Where no test can reach the trap, the line says why.

```nim
## Construct specific PGA's `Basis` enum and related types/procedures.
##
## Example resulting interpretation of 4D RGA (3D Euclidean):
##
##   |---------|-------------------|-----|------------------------|-----|
##   | Basis   | Base Space        |Coef.| Anti Space             |Coef.|
##   |---------|-------------------|-----|------------------------|-----|
##   | E1      | point position  x | pˣ  | anti-plane normal    x | gˣ  |

## Order of compile-time type bootstrapping:
##   [Algebra, BasisDigits, BasisFlags] -> Basis
##   Basis -> BasisSigned
##         -> Multivector
##   BasisSigned -> [Cayley1D, Cayley2D]
```

## Article II: Derive, never transcribe

1. Encode each rule once as data: axioms, tables, a schema, a grammar. Derive from it the
   family that is mechanically related to it. Compression is semantic, and not textual, so
   never merge two fragments because they look alike.
2. Resolve each fact at the earliest stage where its inputs exist: generation → compilation →
   configuration → initialisation → runtime. Runtime receives the flattened residue.
3. Give each job its own representation (readable, algorithmic, runtime), with explicit
   conversions between them.
4. **Generation gate.** Generate only a family that one semantic source derives mechanically.
   Build the model in ordinary code that a reader can inspect and a test can drive.
   Generation is a thin final lowering with no semantics of its own.
5. Whole-module specialisation: a static configuration (dimension, variant, tolerance) enters
   as a build-time definition with a default, named under its library. Derive each dependent
   constant from it, so that two settings never encode one fact. A static check validates it
   where it is defined, with one assertion for each reason to fail. Where the safe range is
   narrower than the implementation allows, the check holds the safe range. A comment beside
   it gives both limits, what narrowed the range, and how to lift it. One build is one
   concrete instantiation, and nothing dispatches on configuration at runtime.
6. Derived runtime state is keyed on a revision that its writers own. Every writer lives in
   one module behind private fields. A restore (undo, redo, clear, load) goes through one
   procedure. That procedure issues a revision newer than any revision ever issued, and never
   the revision of the snapshot. A key that can alias is a sentinel (IV.4).
7. Retreat from an abstraction when it damages understanding, or when it costs more than it
   gives. Record the cost that forced the retreat, so that a reader can review the decision
   when that cost changes. To remove a generator and regain comprehension, then restore a
   smaller one, is progress.
8. Never depend on what the project exists to understand. Derive it. Prefer the standard
   library for every other need. An external concern (windowing, drivers, codecs, protocols)
   may be a dependency, and each one is justified where it is imported.
9. Duplicate only what a real constraint forces: a target that cannot share the dependencies
   of the original, or a boundary that cannot be crossed. Each copy names its siblings, and a
   fix to one is finished only when you check every sibling. Where one language compiles to
   another, write the source language and keep the crossing narrow. Reach for the target
   language only where the source cannot reach at all, or where the crossing would forfeit
   what the target gives free. That gift is a check its own compiler makes over a whole file,
   or a cost the glue adds to a hot path. Say which one in the opening comment of the file,
   and keep every derived value behind an export.

```nim
type
  BasisDigits = distinct string  # Readable ordered factors.
  BasisFlags = distinct uint  # Bitwise membership and parity.
  Basis = enum  # Dense runtime index.

const DIMENSIONS* {.define: "pga.dimensions".} = 4  # Whole-module static configuration.

# Primitive laws -> Cayley table (plain compile-time funcs) -> emitted straight-line kernel.
defineOperator(symbols = "∧", docs = "...", cayley = CAYLEYS_WEDGE.base)
```

## Article III: Notation is the surface

1. **Notation gate.** Where the domain has canonical notation, that notation is the canonical
   spelling. Use Unicode for operators, and for a variable that an equation names, where the
   language allows it, and the closest faithful rendering otherwise. Every other identifier
   is ASCII. Where no notation exists, use plain names only.
2. Every symbolic operator has exactly one named alias: a verb for an operation, and the bare
   domain noun for a property. The alias forwards, and never reimplements. Symbols are for
   equations, and names are for callers. A second common name for the operation goes in the
   doc, and never in a second alias. A second symbol is allowed only where the readers of the
   host language expect it, as `*` for scaling by a scalar.
3. Where the authority lacks a glyph, coin one systematically and register it in the operator
   table of the header. Where coined glyphs name related concepts, the glyphs show the
   relation, so a reader who knows one member of a family reads the others. A compound
   operator concatenates its parts (∨★, |∙, ^∘, ~∘).
4. The doc of the symbol states what the operation is and what it is called. The doc of the
   alias states what it means and when to reach for it.
5. A mathematical variable takes the notation of the source (𝐦, 𝐧, 𝟏) where that is
   representable, so that the code collates visually against the equations. At module scope,
   that notation holds over the casing of Article V, but only for an immutable global.
6. Where the precedence of the host disagrees with the precedence of the notation, document
   the hazard. Require parentheses or the named alias.

```nim
func wedge*(m, n: Multivector): Multivector {.inline.} = m ∧ n
  ## Multiply multivectors by combining jointly present dimensions.
  ##   I.e. multiply through exterior product.
  ##   Also called join operation, analogous to union.
```

## Article IV: Misuse fails at build time

1. Poison an operation that tempts and is wrong, so that it fails at build time and names the
   correct alternative. Declare a planned API the same way: the signature is present and
   documented, and it fails at build time with its TODO.
2. Wrap a primitive in a distinct domain type where interchange is a plausible error. Grant
   each type the minimal enumerated set of delegated operations, and annotate each one with
   its reason. Write no wrapper that prevents no realistic mistake.
3. Take the weakest construct that does the job, and escalate only on need. Bindings run
   `build-time constant → immutable → mutable`. Callables run `pure function → effectful
   procedure → lazy iterator → syntactic substitution → generation`. Declare purity with the
   strictest mechanism available, enabled globally.
4. Detect each error at its earliest boundary, and by distinct mechanisms. An invalid
   configuration fails statically, and an internal impossibility is an assertion. Expected
   absence is a typed Option or an empty value, and never an in-range sentinel. Where a failed
   case still carries a meaningful value, return that value beside a named flag. A message
   ends by echoing each value in backticks, context included, as in
   ``"…; got `{value}` for `{key}`."``, so an empty value stays visible. An expensive check runs
   under the assertions flag.
5. Decide the policy for each special case: zero, empty, NaN, overflow, and a zero norm. Express it
   in the return type, as IV.4 has it. Where no invalid value is possible, return the plain value.
   Compare computed floats only through a relative tolerance with an absolute floor, and poison
   exact equality on those types. Derive the tolerance from a build-configurable count of decimal
   places. Compare against zero at the scale of what you test, and exactly only where no scale is
   in hand.
6. **Storage gate.** A small, closed, statically known domain gets fixed enum-indexed storage
   that carries a live bound. At runtime, use no growing heap structure: dynamic data takes an
   arena that owns its lifetime, and a temporary takes a scratch arena. Every walk runs to
   the bound, and never to the capacity. Prefer a flat value over a reference, so that the
   caller controls the memory, at the copy cost that Article VII makes visible. Where
   identity is needed, hold a handle into an arena, and never a reference.
7. Before you merge several states or paths into one, enumerate every behaviour that the old
   design carried for each state: visibility, enablement, position, timing. Read the old code
   to do it. A request that names one behaviour to keep is not a licence to drop the rest.

```nim
func `==`*(m, n: Multivector): bool {.error:
  "Use approximate comparison, `=~`, or compare elements directly."
.}

func normCenter*(m: Multivector): Multivector {.inline, error: "TODO:  |⊙ m".}
  ## Get center norm of multivector.

# Validate configuration options are within library scope.
#   Library allows up to 9D PGAs, however, after 6D, compile/run times are increasingly slow.
#   9D limit is implementation restriction as bases are encoded as single decimal digits.
static:
  doAssert DIMENSIONS in 2..6,
    &"Dimensionality should be in the range 2..6; got `{DIMENSIONS}`."

for slot in 0..<pool.bound:  # Bound, never `HANDLES_MAX`.
```

## Article V: Names form an ordered system

1. Casing encodes the kind of symbol, one convention for each kind, with one exception, which
   III.5 states. Visibility never changes the case. Types are `PascalCase`, callables are
   `lowerCamelCase`, and a local, a parameter and a field are `snake_case`. A global, which is a
   binding at module level of any kind, is `SCREAMING_SNAKE_CASE`, because the case marks reach
   and not mutability. So keep globals rare and prefer a build-time constant, and give a mutable
   global a comment that says why. Adopt this even where the community of the host language
   differs, because a mixed scheme destroys the signal.
2. Compose a name head first, with the qualifiers last, from general to specific, so that
   families sort and align: `wedge`/`wedgeAnti`, `norm`/`normBulk`/`normWeight`,
   `parity_a`/`parity_b`, `b_from`/`b_to`. This holds even against the word order of the
   domain (`carrierCo`, `scalarAnti`), and the doc keeps the spelling of the domain. The head
   is the kind of value, so a word such as `PATH` or `MARKS` leads (`PATH_KOCH`, never
   `KOCH_PATH`). An action keeps its verb first, and orders its object the same way
   (`constructExomorphismMetric`).
3. An action is an imperative verb (`constructTable`, `emitOperator`). A property is the bare
   domain noun (`grade`, `norm`, `centroid`), and never `getGrade` or `computeNorm`. A
   recurring kind of action keeps one verb:
   - `define…` names a macro that declares from data, and a template that declares a fixed
     family is named for its act (`borrowOperationsGrade`);
   - `construct…` names a table that is built and returned, and `emit…` a function that
     returns AST;
   - `init…` names a constructor of a value, and `new…` never appears, because nothing is a
     reference (IV.6);
   - `to<Target>` names a change of representation, and takes its subject first. A
     transformation inside the domain keeps its domain name.
4. A boolean is a proposition or a mode. Write `is_` for state, `as_` for interpretation,
   `should_` for policy, `found_` for a search outcome, and `has_` for possession.
   A mode boolean passes as a named argument (`as_weight = true`). A predicate callable is
   `is…` in camel case (`isMixed`), the callable twin of `is_`.
5. A lookup table is `lut_<value>_by_<key>`, so that it reads as the access it does:
   `lut_grade_by_basis[b]` is the grade of `b`.
6. Use a single letter only where an equation or a tiny index scope gives it meaning (`m`, `n`,
   `a`, `b`, `i`). Use a descriptive name at a representation boundary, and across a derivation
   of several stages. Coin no abbreviation (`ctx`, `tmp`, `buf`, `cfg`). Only a closed list of
   jargon, which the Architect alone extends, is exempt: `lut`, `min`, `max`, `src`, `prev`,
   `curr`, and `len` as a local. The symbols of the source (`mu`, `sigma`) are exempt too, and
   so is the symbol of a unit that a glossary names under `## Standards`. A plural holds a
   collection, and its singular holds one member (`for term in terms`).
7. Name each distinction, then choose its form by what the code does with it. An axis that
   code selects between at compile time is a closed enum (`Chirality`). A pair that several
   types carry is a small generic wrapper, named by its axis (`Chiral[T]`, `Spatial[T]`).
   Wrappers compose as `Spatial[Chiral[T]]`, and never multiply into new names. An axis that
   code walks over is an array indexed by an enum (`array[Order, Cayley2D]`).
8. Name every landmark index of a domain as an alias on its type (`Basis.origin`,
   `Grade.high`), and never write a bare index. Where the landmark depends on the
   configuration, the alias resolves it, so that no caller branches.
9. A name that joins symbols is an abbreviation too (`aa`, `xy`). An acronym stays only where a
   layman knows it, and the root glossary lists those acronyms. One that a field or a library
   coined stays only where a glossary defines it, as a term or under `## Standards`. Every
   other acronym is spelled out. A path is a name, and follows this article: a directory and a
   file spell their words in full, a test file among them.
10. Where a module runs as a program, its entry block holds no binding. Code that binds goes in
    a routine (`main`), and the block calls that routine. A binding in that block can reach the
    whole module, and a routine makes it a local in every language. A global never shares its
    word with a type, because a reader, or a host that compares names loosely, reads `ALGEBRA`
    and `Algebra` as one. A qualifier keeps them apart (`ALGEBRA_DEFAULT`).
11. A member of an enum is `PascalCase`, as its type is.
12. A type parameter, or any placeholder of a generic or a concept, is one capital letter, the
    initial of what it ranges over. Where nothing constrains it, the letter is `T`.

```nim
BasisDigits  # type
constructExomorphismMetric  # callable
exomorphism_metric  # local
is_degenerate  # boolean proposition
LUT_GRADE_BY_BASIS  # lookup table, and module constant
CAYLEYS_WEDGE  # module constant
```

## Article VI: Documentation is an outline

1. Every declaration gets a doc comment, public or not. The one exception is a one-line
   mechanical delegation (a borrow, a forward) that stands in a stack under one group comment. A
   doc is imperative and opens with a verb, and a type opens with "Define …". It holds one
   summary line that ends in a period, and it cites formal notation inline with `i.e.`. Where you
   cannot write honest text yet, write the doc `TODO: Document.`, and never leave the slot empty.
   A generator carries its docs through a required parameter of the emitting helper, so that an
   undocumented emission cannot compile.
2. Elaboration is a hanging outline. Each deeper nuance is indented two more spaces under its
   parent, with one claim to a line. Docs render as a tree of claims, and not as a paragraph.
3. Length follows weight. Where a façade exists, it carries the full explanation, and the
   procedure that it forwards to carries one line. The length of a doc follows the weight of
   the concept, and not the size of the body.
4. Inside a function, each paragraph that a blank line opens takes one short comment that
   names the goal of the stage, verb first. A reader who skims only the comments reconstructs
   the algorithm. Never narrate the syntax.
5. Prose in a comment is telegraphic, with no articles, in every comment of every language in
   the tree. That covers a header, a stage comment, a banner, and glue in a second language.
   A checker enforces it. A file kind that the checker does not read is a file kind that does
   not exist yet.
6. Say why, and at what cost. Vagueness is not telegraphic.
7. A doc that asserts a global property names what enforces it: a test, an annotation that the
   compiler checks, or the generated output. Such a property is no allocation, no exceptions, a
   complexity, or "runs once for each save". Where nothing enforces it, the doc names its
   register from VIII.1: measured, expected or intended.
8. Prose outside comments is Simplified Technical English, and `GUIDE.md` gives its rules. A
   comment in code keeps the telegraphic register of VI.5 instead.
9. A doc has one position for each shape of declaration, and the expression guide of the
   language fixes it. A reader then finds every doc where the last one was.
10. A comment opens with a capital letter and closes with a period. A citation, a bare name and
    a table cell carry neither. `i.e.` and `e.g.` stay in a comment, lowercase inline and
    capitalised where they open a sentence. An identifier, a literal or a path inside a
    comment takes backticks, so that a reader and the checker take it as a name.

```nim
func unitize*(m: Multivector): Multivector {.inline.} = ^m
  ## Normalize multivector so weight norm has unit antiscalar magnitude, i.e. 𝐦̂ = 𝐦 / ‖𝐦‖∘.
  ##   Shorthand for weight normalization, i.e. weight has magnitude of one.
  ##   Projects higher-dimensional representations of objects into Euclidean space.
  ##     By scaling weight of 𝐦 to unit magnitude.

func multiplyExterior(a, b: BasisSigned): ... =
  ## Perform exterior product of two bases, reducing to its standard basis form.

  # Degenerate in presence of duplicate vectors.
  ...
  # Determine parity in parts (equivalent to counting inversions and anti-commuting).
  ...
```

## Article VII: Cost is read, not assumed

1. Every target has a cost model for a binding, a pass and a return. A value bound in a hot
   path is a copy until the lowered output shows otherwise. Read the generated code for one
   instance of each new binding shape, and say in the comment that you read it.
2. A hot path (per frame, per pool slot, per event) names itself. At the loop it states what
   is constant, what is linear, and what allocates. A change to the path derives that
   statement again.
3. Work for nobody is a bug. Nothing is derived for a view that is closed, off screen or
   unchanged. II.6 gives the key that says so. A function on a hot path computes only what its
   caller reads. To read one element, call the smallest operation that produces it, and never
   build a whole value to read one part of it.
4. An instrument is code with a cost. It runs only while something reads it. Take every
   figure at least once with the instrument compiled out.
5. An optimisation is a pair of measurements: the same probe before and after. Take it on the
   whole (the frame), and not only on the row that reports it. A cheaper instrument that
   shows a smaller number is a lie. Without the pair, the word is "unmeasured".
6. A measured figure names what was measured, on what, and when. When its inputs change,
   measure it again or demote it to unmeasured.
7. Compile time is a cost, and it can reject a design, because it makes each loop of change
   and feedback longer.
8. A function on a hot path writes each element of its result once, with its final value. Where
   the language fills new storage by default, skip the fill only where every path writes every
   element. Article IV comes before this article, so keep the fill where one path can miss an
   element. A compiler can turn a loop of constant stores into a bulk fill. Where the count is
   fixed at build time and the output shows that fill, generate the function (II.4). Where no
   rule can generate it, unroll the loop at build time, or keep the fill and record its cost.
9. Choose the form of a function on a hot path by timing that function alone. Call it across a
   boundary that the optimiser cannot see through. The optimiser then sees neither the caller nor
   the memory that the function writes. A benchmark whose memory the optimiser can see measures
   the benchmark. Take each pair twice, and keep a change only where both pairs show it beyond
   the spread of unchanged functions. Then confirm it on the whole (VII.5).

```nim
template m: untyped = MULTIVECTORS[i]  # Alias; `let m = MULTIVECTORS[i]` deep-copies on JS backend.

func elements*(m: Multivector): lent array[Basis, float] = m.elements
  ## Read elements of multivector.
  ##   `lent` saves copy only when read inline; `let e = m.elements` copies again (read in
  ##   emitted JS).

func `∧`*(s: float, m: Multivector): Multivector {.inline, noinit.} =  # Every element written.

if is_tallying: cost.mark = cpuTime()  # Instrument runs only while report reads it.
```

## Article VIII: The notebook is honest

1. Keep the epistemic register explicit, and never promote between registers in silence:
   guaranteed by types or layout, then measured, then expected, then intended, then
   unresolved. A claimed property names what enforces it, or admits that it is unverified.
2. An open question lives in the code, as a question, where it arises. Where the authority
   itself is silent or unclear, say so at the line where the replication stops. Where the
   replication adopts a convention of the authority over a simpler one, give the choice, the
   reason and the cost at its definition. Name the convention again at each place where it
   forces a special case, in the library and in the tests.
3. A TODO is a compact design journal: the question, the candidate approaches, the expected
   benefits, the likely costs, and the evidence needed. Where the next action is obvious, one
   line is enough.
4. Work in progress may stay in the tree, commented out, while its research value is greater
   than its maintenance cost. Never manufacture commented code as a substitute for version
   history. A commented-out block keeps its docs and its TODOs, so that it stays readable.
5. Honesty is about knowledge, and not about sloppiness. Leave no typo, no debug output, no
   trailing whitespace and no stale summary. Do not imitate the accidents of a reference
   snapshot.
6. Every project keeps a provenance file (`PROVENANCE.md`), and `GUIDE.md` gives what it
   holds. It is never a diary, so prune it whenever it narrates.

```nim
## Heap usage avoided completely so user can fully control memory management.
##   NOTE: Partially true in current implementation, but should be at end state.

# TODO: Represent multivector primitives using more compact data types.
#   At cost of additional meta-programming, this affords:
#     - More optimization with SoA (how much more over SIMD of multivectors?),
#     - Simpler reasoning about objects resulting from operations.
```

## Article IX: Tests replicate the authority

1. Where an authoritative source exists, the suite mirrors it. Suites are named after its
   chapters, and tests after its equations or claims. A test that covers several equations names
   the range (`Equation 2.2-4`). Every assertion carries a trailing citation comment to its line,
   with two spaces before the comment marker. A failing test names the page to reopen. Without an
   authority, name suites and tests by the behaviour that they hold.
2. Test laws, and not examples. Those laws are antisymmetry, round trips, inverses, ordering,
   conservation, idempotence, intended non-commutativity, degenerate cases, and the
   equivalence of an optimised implementation against a reference one.
3. Enumerate a small finite domain exhaustively. Property-check a large one over seeded
   random samples, which are deterministic and reproducible. Bias the corpus towards
   structured cases: basis elements first, then mostly single-grade objects, with mixed grade
   rarer. Skip a sample that the law does not apply to with a guard over the shared corpus.
   Check the count that passed against a named floor, so that a guard which filters out
   nearly every sample fails.
4. Sample beyond what a caller usually supplies: outside the view, near a singularity, and at
   the extremes of a parameter. Record the sample count beside the claim, as a named
   constant. Where the corpus is built, record what it does not cover yet.
5. Test a law where its mechanism runs: real events through real wiring, rendered output read
   back, written bytes read again. A test that calls a handler directly proves the handler,
   and not the wiring.
6. A check that drives a built artifact is evidence only for the build that it drove. One
   command rebuilds, then drives. An ad-hoc run does the same or proves nothing.
7. A parameterised configuration runs as a matrix. The file for each configuration is a
   minimal stub that includes one shared suite. A configuration is its own compile, so its
   stub fails by name and runs alone.
8. A checker is tested against the fixtures that it writes itself, and its own cost is
   bounded. A check slow enough to be skipped is a check that does not run.
9. A gap in the coverage is a placeholder test that reports itself as skipped, so that the run
   shows it. A test that cannot run under a configuration stays in the run, and skips there with
   its reason. Never remove such a test with a bare build-time gate.
10. Code that the authority does not cover is tested in suites whose names open with
    `Internal:`, as `Internal: Planner`, and their tests are named by behaviour. The run then
    shows where the authority stops. Where the authority states a law without a number, name the
    test by its behaviour, and cite the section or the page. Never invent a number.
11. A test helper that the library does not need lives in the suite, and not in the library.
    Test code follows the same rules as library code.
12. A test reads the real clock only where speed is what it holds, or where it tests an
    instrument that reads time. Its name or its section says which. An instrument reads nothing on
    a simulated clock. Its test samples a count of frames or calls, and no limit on time decides
    its verdict. Every other test moves time itself where time matters, and never waits a span of
    real time. A slow machine then takes longer to reach the same verdict, and never another one.

```nim
suite "Chapter 2":
  test "Equation 2.2-4":
    for b, c, 𝐮, 𝐯 in enumeratePairBasis():
      if b.grade == Grade(1) and c.grade == Grade(1):
        check (𝐮 + 𝐯) ∧ (𝐮 + 𝐯) =~ 0  # 2.2a
        check 𝐮 ∧ 𝐯 =~ -(𝐯 ∧ 𝐮)  # 2.4
```

## Article X: Form of the source

1. Two-space indent. No tabs. Lines of at most 100 characters, counted in characters and not
   in bytes. Where the formatter would destroy a hand-shaped block, fence the block between a
   line `#!fix off` and a line `#!fix on`.
2. A section banner is a distinct comment form, at most two tiers deep, and its syntax marks
   the tier. Its title is an English noun phrase in Title Case, qualifier then head, singular
   for one member and plural for several. A first-tier banner takes three blank lines before
   it, and a second-tier banner takes two. Either one takes one blank line after it, but a
   second-tier banner that follows its parent at once keeps its own two.
   - Undocumented one-line helpers of one group stack with no blank line, and so do the
     declarative calls of one family, whatever their length. One blank line separates two
     families.
   - Documented one-line definitions take one, and so do siblings inside a second-tier section
     and a declaration block (`type`, `const`) that follows another.
   - Every other definition takes two.
   - In a test file, a suite is a first tier and a test a second. Each takes the blank lines of
     its tier: three before a suite, two before a test. A first child follows its opener at
     once, as a test that opens a suite, and a suite that opens a `when` body. A suite after a
     banner takes the one blank line of the banner.
3. A call stays on its own line where it fits. A signature that does not fit first wraps its
   parameters onto one line of their own. Where that line does not fit either, it takes one
   parameter, or one group of a shared type, to a line. One item to a line takes a trailing
   separator where the list would not fit joined on one line. A declarative call names its
   arguments, and so do a code-generating call and a constructor. A positional call stays
   positional.

   A call written one argument to a line, with a separator after its last argument, stays so
   where it would fit. That separator is the one mark of the split that the hand wants. A call
   without it that does not fit keeps the line breaks of the hand while each line fits.
   Otherwise it takes one argument to a line, with that separator.
4. Guard clauses (`continue`, `break`, `return`) keep the success path prominent. Nest one
   loop for each axis of the data, and make a condition inside it a guard where it can be.
   Past four levels, split the routine or say why in a comment. Sixty lines is a review
   signal, and not a forced split. Keep a unified derivation intact where a split would hide
   the shape of the data, and say so in a comment. A condition that mixes `and` with `or`, or
   applies `not` to a binary expression, is parenthesised.

   Parentheses that group what the parser groups anyway go. That covers a prefix term or one
   plain operand as one side of a binary operator (`|∙ ⊖(𝐦 ∧ 𝐧) + |∘(𝐦 ∧ ⊖𝐧)`, `2'u^DIMENSIONS`).
   It also covers one plain operand after a prefix operator (`■𝐧`). A plain operand is a name
   or a literal, with any call, index or field glued after it. Parentheses around a binary
   expression stay, and so do those whose removal would glue two tokens into one, as in `^(|𝐦)`.
   A prefix that opens with `@` binds tighter than a call, an index or a field, so `@(x[i])`
   keeps its parentheses.
5. Group related constants and bindings under one keyword, dependent bindings included, where the
   language allows it. Two or more consecutive single bindings always share one keyword.
   Destructure where one expression yields the values together, or where a parallel pair fits one
   line. Otherwise group them under one keyword. Consolidate the imports: the standard library
   grouped and alphabetised, then the local modules, also alphabetised.
6. Module anatomy runs in one order. It is header docs, active design notes and TODOs,
   compiler directives, conditional instrumentation, external imports, local imports,
   re-exports, then the body in conceptual reading order. The body puts its types before any
   routine, consolidated into as few sections as the concepts allow. A reader then sees every
   data structure at a glance before the first routine.
7. Match the density to the role of the file. A semantic module takes rich docs, banners and
   staged derivations. A façade takes grouped one-line declarations, each one documented. A
   generator takes its semantic data first and its thin lowering last. A replication test
   preserves the correspondence to the notation of its source. Never force the profile of one
   onto another.
8. A presentation target ships the faces that it draws with, and never names one that a
   viewer may lack. Those faces are Noto Serif for headings and titles, Noto Sans for body
   and interface text, and Commit Mono for code, data and figures. Enable the ligatures of
   Commit Mono wherever the renderer shapes text, because a glyph atlas that does no shaping
   needs none. The split is a preference of the Architect rather than a finding, so taste
   decides, and the record says so. A Noto face ships whole and never as a subset, since Noto
   was chosen so that no character of a page falls outside its faces. Merge faces by codepoint
   range where none covers everything, then render each codepoint against `.notdef` to verify
   the coverage.
9. A space inside an expression stands only where this list puts it, or where the tokeniser
   demands it:
   - one space on each side of a binary operator, and of `=`;
   - one space after a comma, a semicolon and a colon;
   - two spaces before the marker of a trailing comment, a citation among them.

   No space stands inside a bracket, or after a prefix operator, which is glued to its operand.
   A compound operator stays whole (`s[1..^1]`), since it can carry an optimisation that its
   parts lack.

   A range operator takes no space (`2..6`, `0..<n`). It takes one on each side where a piece
   beside it holds an operator that binds tighter, as in `i + 1 ..< n`. Glued, `i + 1..<n` would
   read as if the range starts at 1. It also keeps one where the glued tokens would lex as one
   token, as before the prefix operator of `s[1 .. ^1]`.

   The power operator `^` takes no space (`-1^k`, `2'u^DIMENSIONS`), since with spaces it reads like
   an operator on bits. Only a prefix operator binds tighter, so no piece beside it keeps it apart.
   An exponent that holds math keeps its parentheses (`-1^(int(b.grade) * int(b.gradeAnti))`).
   Where the glued tokens would lex as one, the exponent takes parentheses instead of spaces
   (`a^(-b)`).

   Inside a bracket glued to the operand before it, as an index or a generic argument is, a symbol
   operator takes no space (`prev[i-1]`). That holds at every depth inside the bracket, and a
   range goes tight with its math (`digits[i+1..<n]`). A word operator keeps its spaces, which
   the tokeniser demands, and so do `=` and `:` as this list gives them. Where the glued tokens
   would lex as one token, the space stays. An array literal that stands alone keeps the spaces
   of this list. So does the generic list that a routine or a type declares after its name, with
   or without the export marker (`func pick[I: Basis | Grade]`, `Foo*[T: A | B] = object`).
10. A list that the language gives no order of its own is alphabetised, as the imports are.
    That covers exports, pragmas and attributes, and a list of flags. Alphabetical order is
    dictionary order: case and `_` are ignored, and a tie falls to the code point. Pragmas sort
    in two groups, the bare pragmas first, then those that take an argument.
11. Definitions that exist under one configuration sit together in one conditional block inside
    their section. The configurations come in one fixed order across the project. Inside a
    routine, a nested helper comes first, after the doc.
12. A parameter with a default states its type only where the default does not fix it, and a
    field states its type always. Only a literal fixes it, `default(T)` and `none(T)` among
    them, so a default from a named constant states its type.

```nim
defineOperator(
  symbols = "∧",
  docs = "Multiply multivectors through exterior product, i.e. 𝐦 ∧ 𝐧.",
  cayley = CAYLEYS_WEDGE.base,
)

let (flags_a, flags_b) = (a.basis.toFlags, b.basis.toFlags)
if product.is_degenerate: continue
```

## Article XI: The record

1. Conventional Commits with a stable scope: `type(scope): lowercase imperative summary`, no
   trailing period, one intention to a commit. A refactor, a doc, a fix and a feature are
   never mixed in silence. In a repository of several projects, the scope is the project. In
   a repository of one project, the scope names the module or subsystem that changed. A
   change outside every project takes the scope of the role that owns it. A subject is at most
   100 characters, the same limit as a line of source.
2. The history is part of the document. A reader replays the intellectual development of the
   project from the log. A step that prepares for the next change is its own commit, named
   for what it prepares. A reversal is its own commit, and names what it undoes.
3. Vendored source stays in the working tree, and never in the repository. The provenance
   file records its origin, its commit and its licence, and honours the notice terms of that
   licence.
4. A commit body carries the reason, the mechanism or the open state that the subject cannot
   say. Where the subject is enough, the commit has no body. A body is in sentence case, with
   one sentence to a line.

```text
feat(pga): add preliminary conformal support
refactor(pga): lift transwedge spatial/chiral distinctions
docs(pga): add operator documentation and conformal aliases
```

## Output contract

Return the implementation first. `GUIDE.md` gives what else to report, and in which English.
