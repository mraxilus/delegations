# Nim Expression Guide

Use this guide beside the Coding Constitution where the output language is Nim. The
constitution owns the policy for design, naming, documentation, cost, layout and tests. This
guide owns only what is specific to Nim: the choice of construct, pragma discipline, the
idioms, and what each backend does with a value. Where the two overlap, the constitution
wins.

## 1. Construct selection

Map the callable ladder of the constitution onto `func → proc → iterator → template → macro`.
Escalate only on need.

- `func` is the default for a deterministic transformation of a value.
- `proc` only for an effect, for randomness, or for `var` access. Where both mutable and
  immutable access matter, define the overload pair:

  ```nim
  proc `[]`*(m: var Multivector, b: Basis): var float {.inline.} = m.elements[b]
  func `[]`*(m: Multivector, b: Basis): float {.inline.} = m.elements[b]
  ```

- `iterator` only where lazy enumeration is the concept you expose. Yield `lent` from a
  stored pool, so that the walk never copies.
- `template` only for a zero-cost substitution that a function cannot express. That covers
  operand reversal, a typedesc alias, and an alias to an element inside a loop where a `let`
  would copy (§7):

  ```nim
  template `+`*(m: Multivector, s: float): Multivector = s + m
  template scalar*[I: Basis | Grade | GradeAnti](t: typedesc[I]): I = I.low
  template r: untyped = records[i]  # alias, never `let r = records[i]` in a hot loop
  ```

- Use a named `{.inline.}` func for an ordinary public façade, and not a template.
- `macro` only where AST emission is necessary, and only after the semantic model exists in
  ordinary compile-time funcs. Route the emission through a shared helper that takes the
  documentation as a parameter. An undocumented generated declaration is then impossible.
- Nest a helper used once inside the derivation that owns it. Do not promote it to module
  scope for a reuse that you only expect.
- Hand a stored value out with no copy. Return `lent T` from an accessor into storage. Take
  `var T` where the callee reads a large value in place and nothing writes it. Add a comment
  that says `var` is for the copy and not for a write. A `lent` result saves the copy only
  where the caller reads the call inline, and bound to a `let` it copies again.

## 2. Pragma discipline

- `{.experimental: "strictFuncs".}`: this exact form, before the imports, in every production
  module. Never as a pushed ordinary pragma.
- `{.experimental: "codeReordering".}`: only where the reading order of a human should beat
  the declaration order. Const initialisation stays in dependency order in either case.
- `{.compileTime.}`: applied the same way across a whole compile-time family. Never rely on
  incidental const evaluation where the staging is part of the contract.
- `{.inline.}`: for a deliberate thin wrapper and a tiny hot accessor only.
- `{.borrow.}`: enumerate the minimal operations for each distinct type. Annotate a consumer
  that is not obvious at the use site (`{.borrow, compileTime, used.} # Used in cayleys.nim.`).
  Define a repeated mechanical borrow family once, through a documented template:

  ```nim
  template borrowGradeOperations(T: typedesc) =
    func `+`*(g, h: T): T {.borrow.}
    func `==`*(g, h: T): bool {.borrow.}
  borrowGradeOperations(Grade)
  borrowGradeOperations(GradeAnti)
  ```

- `{.pure.}` on a small enum that carries a semantic axis. Always qualify the members
  (`Space.Base`).
- `{.define: "lib.option".}` on a build-configurable constant.
- `{.error: "...".}` for a poisoned operation, and for one that is planned and not written
  yet.
- `{.used.}` with a trailing comment that names the consumer, for a private symbol that
  another module uses.
- No `{.push.}`. No pragma scattered as superstition.

## 3. Compile-time and gated idioms

- Write a lookup table as a const block, with a local `var` to build it and an immutable
  result:

  ```nim
  const lut_basis_to_grade = block:
    var lut: array[Basis, Grade]
    for b in Basis: lut[b] = Grade(b.toFlags.countSetBits)
    lut
  ```

- Validate a static configuration in `static: doAssert`, with ``&"…; got `{X}`."``.
- Put an expensive check under `when compileOption("assertions"):`. Put the profiler import
  under `when compileOption("profiler"): import std/nimprof`, in an entry module.
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
  (`bound`), and every walk is `for slot in 0 ..< pool.bound`.
- Give an object field its default inline (`is_negated*: bool = false`).
- Use `seq`, `Table` and `string` as data structures only at compile time, or in a tool that
  a shell runs once. At runtime, use `string` only for display (`$`, messages).

## 5. Signatures, imports, calls

- Write bracket imports, grouped and consolidated: `import std/[bitops, options]`, then
  `import ./[algebra {.all.}, helpers]`. Use `{.all.}` only for deliberate access to
  internals, from a sibling or a test.
- Put commas between parameters while every type appears once (`m: Multivector, b: Basis`).
  Escalate to semicolons between groups only where one group holds several parameters of one
  type (`a, b: X; c: Y`). A formatter that promotes every comma to a semicolon is wrong here,
  so configure it or ignore it. Put the return type and the pragmas on the closing line of a
  multi-line signature:

  ```nim
  func filterFactors(
    cayley: Cayley1D; factors, exclusions: seq[Basis]; as_exclusions = false
  ): Cayley1D {.compileTime.} =
  ```

- Use the implicit `result` for a structured accumulation. Use a bare final expression for a
  simple computed value. Use an explicit `return` mostly for a guard exit. Never end with
  `return result`.
- Bind a `case` or `if` expression that produces a value to a `let`.
- Use UFCS for a unary semantic chain (`b.toDigits.toFlags`), and backticks for an operator
  definition. Use a raw string (`r"\"`) and a backtick-quoted call (`` m.`∧ ☆`n ``) where the
  tokeniser demands one.
- Put `*` on every intentional export, and on nothing else. The umbrella module re-exports
  the coherent surface (`import ./pga/[...]`, then `export ...`).
- Membership in a hot path is two comparisons (`slot >= 0 and slot < N`). Do not write
  `slot in 0 ..< N`, which allocates on the JS backend (§7).

## 6. Test harness

- Put a testament matrix header on the stub for each configuration. Each stub does `include`
  of one shared suite. Leave `-r` out of `cmd`, because testament runs the binary itself,
  and `-r` then runs every test twice:

  ```nim
  discard """
  action: run
  cmd: "nim c --hints:on -d:testing -d:nimUnittestAbortOnError:on $options $file"
  matrix: "-d:pga.dimensions=3 -d:pga.is_conformal=false"
  batchable: true
  joinable: true
  """
  include "../suites.nim"
  ```

- Use `std/unittest` suites and `check`, with `randomize(0)`, and a preallocated sample pool
  that `lent` iterators serve:

  ```nim
  iterator randMultivectors(count = SAMPLES):
      (lent Multivector, lent Multivector, lent Multivector) = ...
  ```

- Compare floats through `=~`, with the build-configurable tolerance. `==` on those types is
  poisoned, and must not compile.

## 7. Targets

What a binding costs depends on the backend. The constitution (Article VII) asks you to read
the lowered output. A `let` of a scalar is free on both backends. What to look for:

- **C and C++ backends.** A `let` of an object copies the struct. `lent` and `var` are
  pointers. An `array[N, T]` of objects is contiguous. The emitted C sits in the nimcache
  directory, so grep there for the name of the proc.
- **JS backend.** Every object and array is a JS object, every copy is deep, and a
  `let x = y` of an object emits `nimCopy`. A by-value parameter copies at the call, and a
  by-value return copies on the way out. `lent` and `var` avoid the copy only where the
  caller reads the value inline. `slot in a ..< b` builds a slice object, and `seq.add` and
  string concatenation allocate. Check with `grep -c nimCopy` on the emitted file, and read
  one call site of each new binding shape.
- A boundary (`{.importc.}`, `{.importjs.}`, `{.exportc.}`) is where the rule of each target
  is documented, once, beside the declaration that crosses it.

Do not imitate the defects of a snapshot. Leave no debug `echo` in a committed test, no
trailing whitespace, no misspelling, and no missing `{.compileTime.}` inside a family that is
otherwise staged.
