# Nim Expression Guide

Use this guide beside the Coding Constitution where the output language is Nim. The
constitution owns the policy for design, naming, documentation, cost, layout and tests. This
guide owns only what is specific to Nim: the choice of construct, pragma discipline, the
idioms, and what each backend does with a value. Where the two overlap, the constitution
wins. `EXAMPLES.md` holds longer worked examples, which both documents point into.

## 1. Construct selection

Map the callable ladder of the constitution onto `func → proc → iterator → template → macro`,
and its binding ladder onto `const → let → var`. Escalate only on need.

- `when isMainModule:` is the entry block that V.10 names. `when` opens no scope, so the block
  holds no binding. Code that binds goes in `proc main`, and the block calls it, as
  `quit main()` or `main()`. Nim compares an identifier by its first letter exactly, and the
  rest without case or underscore. So `ALGEBRA` and `Algebra` are one name, and V.10 keeps them
  apart with a qualifier.
- `func` is the default for a deterministic transformation of a value.
- `proc` only for an effect beyond its parameters, or for randomness. A `func` may take a
  `var` parameter, because `strictFuncs` does not count a write to it as a side effect.
- Where both mutable and immutable access matter, define an overload pair of `func`s, because
  a `func` may take a `var` parameter. Raw access into storage becomes a `template` pair only
  where the project measured the cost of the call and recorded it:

  ```nim
  func `[]`*(m: var Multivector, b: Basis): var float = m.elements[b]
  func `[]`*(m: Multivector, b: Basis): float = m.elements[b]
  ```

- `iterator` only where lazy enumeration is the concept you expose. Yield `lent` from a
  stored pool, so that the walk never copies.
- `template` only for a zero-cost substitution that a function cannot express, or where the
  measured cost of a call is too high. That covers operand reversal and a typedesc alias. It
  also covers an alias to an element inside a loop, where a `let` would copy (§7):

  ```nim
  template `+`*(m: Multivector, s: float): Multivector =
    ## Add multivector and scalar, i.e. 𝐦 + 𝐬.
    s + m

  template scalar*[I: Basis | Grade | GradeAnti](t: typedesc[I]): I = I.low
  template m: untyped = MULTIVECTORS[i]  # Alias, never `let m = MULTIVECTORS[i]` in hot loop.
  ```

- Use a named `{.inline.}` func for an ordinary public façade, and not a template.
- `macro` only where AST emission is necessary, and only after the semantic model exists in
  ordinary compile-time funcs. Route the emission through a shared helper that takes the
  documentation as a parameter. An undocumented generated declaration is then impossible.
- Nest a helper used once inside the derivation that owns it. Do not promote it to module
  scope for a reuse that you only expect. The nested helper comes first in the body of the
  routine that owns it, after the doc and before the first stage. One blank line stands on
  each side of it, but a routine on one line, such as a `{.borrow.}` with no body, stacks. It
  takes no blank line after the head or doc of the routine around it, or after another routine
  on one line. One blank line still stands between the last of them and a stage or a longer
  routine.
- Hand a stored value out with no copy. Return `lent T` from an accessor into storage. Take
  `var T` where the callee reads a large value in place and nothing writes it. Add a comment
  that says `var` is for the copy and not for a write. A `lent` result saves the copy only
  where the caller reads the call inline, and bound to a `let` it copies again.

## 2. Pragma discipline

- `{.experimental: "strictFuncs".}`: this exact form, before the imports, in every module, a
  test suite included. Never as a pushed ordinary pragma.
- `{.experimental: "codeReordering".}`: the mechanism that lets Nim follow the reading order
  of Article I.1. Use it wherever that order puts a use before its definition.
- `{.compileTime.}`: applied the same way across a whole compile-time family. Never rely on
  incidental const evaluation where the staging is part of the contract.
- `{.inline.}`: for a deliberate thin wrapper and a tiny hot accessor. Inline a larger body
  only where a measurement shows the gain.
- `{.noinit.}`: only on a routine that writes every element of `result` on every path (VII.8).
  An emitted kernel and a loop over the whole domain qualify. Otherwise Nim zeroes `result`
  first, and a partial write under the pragma leaves memory undefined. On the JS backend an
  array `result` is always a new array of zeros, so the pragma changes nothing there.
- A pragma that the compiler checks is the annotation that VI.7 names, such as
  `{.raises: [].}` for no exceptions.
- `{.borrow.}`: enumerate the minimal operations for each distinct type. Annotate a consumer
  that is not obvious at the use site
  (`` {.borrow, compileTime, used.}  # Used in `cayleys.nim`. ``). Define a repeated mechanical
  borrow family once, through a documented template:

  ```nim
  template borrowOperationsGrade(T: typedesc) =
    func `+`*(g, h: T): T {.borrow.}
    func `==`*(g, h: T): bool {.borrow.}
  borrowOperationsGrade(Grade)
  borrowOperationsGrade(GradeAnti)
  ```

  A parameter of type `typedesc` alone stands for any type, as a generic does, so it is one
  capital letter (V.12). `t: typedesc[I]` stays a parameter, since `I` is the placeholder.

- `{.pure.}` on a small enum that carries a semantic axis. Always qualify the members
  (`Space.Base`).
- `{.define: "lib.option".}` on a build-configurable constant.
- `{.error: "...".}` for a poisoned operation, and for one that is planned and not written
  yet.
- `{.used.}` with a trailing comment that names the consumer, for a private symbol that
  another module uses.
- No `{.push.}` of an ordinary pragma, so that the pragmas of a routine stay visible where it
  is defined. A push that `{.pop.}` closes over one block of foreign bindings (`header:`,
  `importc`) is allowed. No pragma scattered as superstition.

## 3. Compile-time and gated idioms

- Write a lookup table as a const block, with a local `var` to build it and an immutable
  result:

  ```nim
  const LUT_GRADE_BY_BASIS = block:
    var lut: array[Basis, Grade]
    for b in Basis: lut[b] = Grade(b.toFlags.countSetBits)
    lut
  ```

- Validate a static configuration in `static: doAssert`, with ``&"…; got `{X}`."``.
- Write `{x=}` in a message where the value alone would not say which binding it is
  (`{digits=}`).
- Put an expensive check under `when compileOption("assertions"):`. Put the profiler import in
  every entry module, library umbrella and test entry alike, right after the pragmas, on two
  lines:

  ```nim
  when compileOption("profiler"):
    import std/nimprof
  ```

  Then `--profiler:on` works with no edit. A stub that includes its shared suite (§6) takes the
  import from that suite, since the include makes one module of both.
- Use `when` for a configuration branch and a typedesc branch
  (`let g = when G is Grade: b.grade else: b.gradeAnti`). Never take a runtime branch on a
  distinction that is known statically.
- An instrument is gated on its reader, and not on a build flag. Write `if is_tallying:`
  around each clock read and each tally. The panel that displays the result sets
  `is_tallying`. Measure the path once with the gate closed, before you report any figure
  that it produces.

## 4. Types and data

- Wrap a primitive in a `distinct` type (`BasisDigits = distinct string`). Give it only the
  iterators and accessors that it needs.
- Use `Option[T]` for expected absence, and never `-1`, `NaN` or an in-range sentinel. Where
  a foreign boundary cannot carry an `Option`, translate through one named constant. Put that
  constant at the return of the boundary proc, and never upstream of it.
- Use an enum-indexed fixed array for a closed static domain (`array[Basis, float]`), and a
  `range` type for a bounded index. A fixed pool carries its live extent as a field
  (`bound`), and every walk is `for slot in 0..<pool.bound`.
- Give a distinct type whose domain you walk an `items` iterator over its typedesc, so that
  `for k in Order:` reads as the domain.
- Define `=~` as `abs(a - b) <= TOLERANCE_ABS * max(1, abs(a), abs(b))`, and derive
  `TOLERANCE_ABS` from the count of places. Near zero, that form falls to its absolute floor,
  so a zero test takes the scale of what it tests (Article IV.5).
- Give an object field its default inline (`is_negated*: bool = false`).
- Use `seq`, `Table` and `string` as data structures only at compile time, or in a tool that
  a shell runs once. At runtime, use `string` only for display (`$`, messages).

## 5. Signatures, imports, calls

- A doc comment is `##`, so an empty slot is `## TODO: Document.` (VI.1). A doc takes one
  position for each shape of declaration (VI.9). A type, a field, a binding and an enum member
  take it after them on the same line, where the joined line fits. Otherwise the doc takes the
  next line, indented one level.
- A one-line routine takes its doc on the next line, indented to the body. A longer routine
  takes it as the first line of the body. A `type` block takes a group doc on the keyword line.
- Group related bindings under one `const`, `let` or `var` section (X.5).
- Write bracket imports, grouped and consolidated, each group alphabetised:
  `import std/[bitops, options]`, one blank line, then `import ./[algebra {.all.}, helpers]`.
  A single module takes no bracket (`import std/math`). Use `{.all.}` only for deliberate
  access to internals, from a sibling or a test. A private symbol that a sibling reaches that
  way carries `{.used.}`, and a comment that names the sibling:

  ```nim
  func `and`(a, b: BasisFlags): BasisFlags {.borrow, compileTime, used.}  # Used in `cayleys.nim`.
  ```

- Put commas between parameters while every type appears once (`m: Multivector, b: Basis`).
  Escalate to semicolons between groups only where one group holds several parameters of one
  type (`a, b: X; c: Y`). The rule holds on one line and across several. A tuple type takes
  commas between its fields (`tuple[basis: BasisSigned, is_degenerate: bool]`). A formatter
  that promotes every comma to a semicolon is wrong here, so configure it or ignore it.
- A signature that does not fit on its line wraps its parameters onto one line of their own.
  Where that line does not fit either, put one parameter, or one group of a shared type, on
  each line, each with a trailing separator. Put the return type and the pragmas on the
  closing line:

  ```nim
  func filterFactors(
    cayley: var Cayley1D, factors: seq[Basis], as_exclusions = false
  ) {.compileTime.} =

  func constructProductsTransitional(
    complement, dual: Cayley1D; wedges: Spatial[Cayley2D]; chirality: Chirality; space: Space
  ): array[Order, Cayley2D] {.compileTime.} =
  ```

- A call written one argument to a line, with a comma after its last argument, stays so even
  where it fits. That comma is the one mark of the split that the hand wants. A call without it
  joins its line where it fits. Where it does not fit, it keeps the line breaks of the hand while
  each line fits. Otherwise it puts one argument on each line, with a trailing comma. A generator
  call and a constructor name their arguments, and a positional call stays positional:

  ```nim
  CAYLEY_EXPAND_BULK_RIGHT* = constructProductInterior(
    CAYLEYS_DUAL.base.right,
    CAYLEYS_WEDGE.base,
    Chirality.Right,
  )
  ```

- An expression that does not fit breaks after a binary operator, because Nim refuses a line
  that opens with one. Each line of the expression past its statement line takes four spaces
  more than that line, and all of them take that one indent. A chain that opens on the line
  after `=` takes the four spaces too, its first line included. Any other value on its own line
  after `=` keeps one level, as an `if` expression or a split call does. A call and a signature
  keep their layout of one level, as above.

  An expression can open its own line after an opening bracket or the comma of a list. Then
  every line of it takes the indent of that line. A bare value that opens its statement line
  keeps the four spaces, since no bracket or comma sets it apart from the body:

  ```nim
  let depth = offset_x * bounds.forward.x + offset_y * bounds.forward.y +
      offset_z * bounds.forward.z
  result.add BasisSigned(
    basis: product.basis,
    is_negated: (
      m_from.is_negated xor
      n_from.is_negated xor
      term.is_negated
    ),
  )

  const
    RANGES_NOTO_SANS_MATH =
        "20-7e a0 a7 33a 33f " &
        "346 34d 391-3a1 2016 " &
        "2018-2019 201c-201d "
    STEP_TWIST =
      if DIMENSIONS == 3: STEP_SPATIAL
      else: STEP_PLANAR
  ```

  The four spaces keep the head of a block apart from its body. Where the line right above a body
  would stand at the indent of the body, every continuation line of the head takes them. They
  stand past the first line of the head. That holds inside a call too, whose layout of one level
  would put the line on the body. A head that closes on its own `):` or `) =` already stands
  apart:

  ```nim
  if check(a_long_name, first_condition or second_condition or
      (second_condition and first_condition)):
    echo a_long_name
  ```

- A parameter with a default states its type only where the default does not fix it
  (`as_exclusions = false`, `count: int = SAMPLES`). Only a literal fixes it, `default(T)` and
  `none(T)` among them. A field states its type always. An empty-collection default is
  written one way in a project.
- Use the implicit `result` for a structured accumulation. Use a bare final expression for a
  simple computed value. Use an explicit `return` only for an early exit. Never end with
  `return result`.
- Bind a `case` or `if` expression that produces a value to a `let`, or to a `const` where
  the value is known at compile time.
- Use UFCS where the first argument is plainly the subject: a query, an accessor, or a
  `to<Target>` conversion, chained where it reads (`b.toDigits.toFlags`). A conversion of a
  compound argument stays a prefix call (`toMultivector(a + b)`), so that no parentheses hide
  it. An `init…` call may take its subject the same way (`b.initElement(1)`). Use a prefix
  call for `construct…`, `define…` and `emit…`, for a type conversion (`Grade(x)`, never
  `x.Grade`), and wherever no argument plainly dominates. Use backticks for an operator
  definition. Use a raw string (`r"\"`) and a backtick-quoted call (`` m.`∧ ☆`n ``) where the
  tokeniser demands one.
- A dotted call that is a whole statement takes the command form where its one argument is a
  call or a parenthesised expression. So write `result.add BasisSigned(basis: b)` and
  `x.f (a, b)`, with no double bracket. Inside an expression the call form stays, since the
  command form can read otherwise there.
- A first-tier banner is `#[ Title Case ]#`, and a second-tier banner is `#[[ Title Case ]]#`.
  Each one stands alone on its line, and is never indented.
- `nim r koch fix` is the formatter. It applies each fix that a check names, and nothing else,
  so your reading holds every other rule of layout. It leaves the lines between `#!fix off`
  and `#!fix on` as written (X.1). `--dry-run` prints each change, and writes none.
- Put `*` on every intentional export, and on nothing else. The umbrella module re-exports
  the coherent surface (`import ./pga/[...]`, then `export ...`).
- Membership in a hot path is two comparisons (`slot >= 0 and slot < N`). Do not write
  `slot in 0..<N`, which allocates on the JS backend (§7).

## 6. Test harness

- Put a testament matrix header on the stub for each configuration. Each stub does `include`
  of one shared suite. Leave `-r` out of `cmd`, because testament runs the binary itself,
  and `-r` then runs every test twice. Leave out `batchable` and `joinable`, because koch
  runs `testament pattern`, which reads neither:

  ```nim
  discard """
  action: run
  cmd: "nim c --hints:off -d:testing -d:nimUnittestAbortOnError:on $options $file"
  matrix: "-d:pga.dimensions=3 -d:pga.is_conformal=false"
  """
  include "suites.nim"
  ```

- A test file is `tests/test_<name>.nim` (V.9), and koch runs testament over those files. A
  project with one configuration and many suite modules keeps them as
  `tests/suites/test_<module>.nim`, one for each module. One stub imports each of them, so the
  compiler reads the standard library once and not once for each suite. That stub leaves out
  `-d:nimUnittestAbortOnError:on`, so that every failure shows in one run.
  `curator/audit/tests/test_suites.nim` is the worked example.

- Use `std/unittest` suites and `check`, with `randomize(0)`, and a preallocated sample pool
  that `lent` iterators serve:

  ```nim
  iterator multivectorsRandom(count: int = SAMPLES):
      (lent Multivector, lent Multivector, lent Multivector) = ...
  ```

- A placeholder test calls `skip()`, and never `discard`, so that the run prints `[SKIPPED]`.
  `skip()` does not stop the body. A test that cannot run under a configuration therefore
  puts its body in the other branch of `when`:

  ```nim
  test "Equation 2.87-89":
    when IS_CONFORMAL: skip()  # TODO: Enable when conformal dot product fixed.
    else:
      for 𝐦, _, _ in multivectorsRandom():
        check |∙𝐦 =~ sqrt(𝐦 ∙ 𝐦)  # 2.87
  ```

- A citation comment is `#`, two spaces after the assertion: `check 𝐮 ∧ 𝐯 =~ -(𝐯 ∧ 𝐮)  # 2.4`
  (IX.1).
- Compare floats through `=~`, with the build-configurable tolerance. `==` on those types is
  poisoned, and must not compile.

## 7. Targets

What a binding costs depends on the backend. The constitution (Article VII) asks you to read
the lowered output. A `let` of a scalar is free on both backends. What to look for:

- **C and C++ backends.** A `let` of an object copies the struct. `lent` and `var` are
  pointers. An `array[N, T]` of objects is contiguous. The emitted C sits in the nimcache
  directory, so grep there for the name of the proc.
- **Fills on C and C++ backends (VII.8).** gcc turns a loop of constant stores into `memset`,
  and the default fill of `result` is a `memset` too. Above a size that depends on `-march`,
  gcc emits that `memset` as `rep stos`, which costs more than straight stores. Generate such a
  function from its semantic source where one exists (II.4). Otherwise unroll the loop with a
  macro that emits one copy of the body for each value, or keep the fill and record its cost.
  `{.unroll.}` is parsed and then ignored.
- **Timing one function (VII.9).** Call an `{.inline.}` function through a `{.volatile.}`
  variable of its procedure type. The C compiler then emits its body out of line, and cannot
  inline it into the caller.
- **JS backend.** Every object and array is a JS object, every copy is deep, and a
  `let x = y` of an object emits `nimCopy`. A by-value parameter copies at the call, and a
  by-value return copies on the way out. `lent` and `var` avoid the copy only where the
  caller reads the value inline. `slot in a..<b` builds a slice object, and `seq.add` and
  string concatenation allocate. Check with `grep -c nimCopy` on the emitted file, and read
  one call site of each new binding shape.
- A boundary (`{.importc.}`, `{.importjs.}`, `{.exportc.}`) is where the rule of each target
  is documented, once, beside the declaration that crosses it.

Do not imitate the defects of a snapshot. Leave no debug `echo` in a committed test, no
trailing whitespace, no misspelling, and no missing `{.compileTime.}` inside a family that is
otherwise staged.
