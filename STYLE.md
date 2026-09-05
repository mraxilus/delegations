# Nim Expression Guide

Use alongside the Coding Constitution when the output language is Nim. The constitution
owns design, naming, documentation, cost, layout and testing policy; this guide owns only
what is Nim-specific: construct selection, pragma discipline, idioms, and what each backend
does with a value. Where the two overlap, the constitution wins.

## 1. Construct selection

Map the constitution's callable ladder onto `func → proc → iterator → template → macro`,
escalating only on need.

- `func` is the default for deterministic value transformations.
- `proc` only for effects, randomness, or `var` access. Where mutable and immutable access
  both matter, define the overload pair:

  ```nim
  proc `[]`*(m: var Multivector, b: Basis): var float {.inline.} = m.elements[b]
  func `[]`*(m: Multivector, b: Basis): float {.inline.} = m.elements[b]
  ```

- `iterator` only when lazy enumeration is the exposed concept; yield `lent` from a stored
  pool so iteration never copies.
- `template` only for zero-cost substitution a function cannot express: operand reversal,
  typedesc aliases, and an alias to an element inside a loop where a `let` would copy (§7):

  ```nim
  template `+`*(m: Multivector, s: float): Multivector = s + m
  template scalar*[I: Basis | Grade | GradeAnti](t: typedesc[I]): I = I.low
  template r: untyped = records[i]  # alias, never `let r = records[i]` in a hot loop
  ```

- A named `{.inline.}` func, not a template, for an ordinary public façade.
- `macro` only for necessary AST emission, after the semantic model exists in ordinary
  compile-time funcs. Route emission through a shared helper that takes documentation as a
  parameter, so an undocumented generated declaration is impossible.
- Nest a single-use helper inside its sole owning derivation; do not promote it to module
  scope for speculative reuse.
- Hand a stored value out without copying: return `lent T` from an accessor into storage;
  take `var T` where the callee reads a large value in place and nothing writes it, with a
  comment saying `var` is for the copy, not for writing. A `lent` result saves the copy only
  when the caller reads the call inline; bound to a `let` it copies again.

## 2. Pragma discipline

- `{.experimental: "strictFuncs".}` — exact form, before imports, in every production
  module. Never as a pushed ordinary pragma.
- `{.experimental: "codeReordering".}` — only where human reading order should beat
  declaration order; const initialisation stays dependency-ordered regardless.
- `{.compileTime.}` — applied uniformly across an entire compile-time family; never rely on
  incidental const evaluation when staging is part of the contract.
- `{.inline.}` — deliberate thin wrappers and tiny hot accessors only.
- `{.borrow.}` — enumerate minimal operations per distinct type; annotate non-obvious
  consumers at the use site (`{.borrow, compileTime, used.} # Used in cayleys.nim.`). Define
  a repeated mechanical borrow family once through a documented template:

  ```nim
  template borrowGradeOperations(T: typedesc) =
    func `+`*(g, h: T): T {.borrow.}
    func `==`*(g, h: T): bool {.borrow.}
  borrowGradeOperations(Grade)
  borrowGradeOperations(GradeAnti)
  ```

- `{.pure.}` on small semantic-axis enums; always qualify members (`Space.Base`).
- `{.define: "lib.option".}` on build-configurable constants.
- `{.error: "...".}` for poisoned and planned-but-unimplemented operations.
- `{.used.}` plus a trailing comment naming the consumer, for cross-module private symbols.
- No `{.push.}`; no pragma scattered as superstition.

## 3. Compile-time and gated idioms

- Lookup tables as const blocks, a local `var` while building, immutable result:

  ```nim
  const lut_basis_to_grade = block:
    var lut: array[Basis, Grade]
    for b in Basis: lut[b] = Grade(b.toFlags.countSetBits)
    lut
  ```

- Static configuration validated in `static: doAssert` with ``&"…; got `{X}`."``.
- Expensive checks under `when compileOption("assertions"):`; profiler import under
  `when compileOption("profiler"): import std/nimprof` in entry modules.
- `when` for configuration and typedesc branches
  (`let g = when G is Grade: b.grade else: b.gradeAnti`); never a runtime branch on a
  statically known distinction.
- An instrument is gated on its reader, not on a build flag: `if is_tallying:` around each
  clock read and tally, with `is_tallying` set by the panel that displays the result. Measure
  the path once with the gate closed before reporting any figure it produces.

## 4. Types and data

- `distinct` wrappers over primitives (`BasisDigits = distinct string`); give them only the
  iterators and accessors they need.
- `Option[T]` for expected absence, never `-1`, `NaN` or an in-range sentinel. Where a
  foreign boundary cannot carry an `Option`, translate through one named constant at the
  boundary proc's return, never upstream of it.
- Enum-indexed fixed arrays for closed static domains (`array[Basis, float]`); `range` types
  for bounded indices. A fixed pool carries its live extent as a field (`bound`), and every
  walk is `for slot in 0 ..< pool.bound`.
- Object field defaults inline (`is_negated*: bool = false`).
- `seq`, `Table` and `string` as data structures only at compile time or in tools run once
  from a shell; at runtime, `string` only for display (`$`, messages).

## 5. Signatures, imports, calls

- Bracket imports, grouped and consolidated: `import std/[bitops, options]`, then
  `import ./[algebra {.all.}, helpers]`; `{.all.}` only for deliberate sibling or test
  access to internals.
- Commas between parameters while every type appears once (`m: Multivector, b: Basis`).
  Escalate to semicolons between groups only when some group holds several parameters of
  one type (`a, b: X; c: Y`). A formatter that promotes every comma to a semicolon is
  wrong here; configure or ignore it. Return type and pragmas on the closing line of a
  multi-line signature:

  ```nim
  func filterFactors(
    cayley: Cayley1D; factors, exclusions: seq[Basis]; as_exclusions = false
  ): Cayley1D {.compileTime.} =
  ```

- Implicit `result` for structured accumulation; a bare final expression for a simple
  computed value; explicit `return` mainly for guard exits. Never end with `return result`.
- Bind value-producing `case` and `if` expressions to `let`.
- UFCS for unary semantic chains (`b.toDigits.toFlags`); backticks for operator
  definitions; raw strings (`r"\"`) and backtick-quoted calls (`` m.`∧ ☆`n ``) where
  tokenisation demands.
- `*` on every intentional export, nothing else; the umbrella module re-exports the coherent
  surface (`import ./pga/[...]` then `export ...`).
- Membership in a hot path is two comparisons (`slot >= 0 and slot < N`), not
  `slot in 0 ..< N`, which allocates on the JS backend (§7).

## 6. Test harness

- Testament matrix headers on per-configuration stubs, which `include` one shared suite:

  ```nim
  discard """
  action: run
  cmd: "nim c --hints:on -d:testing -d:nimUnittestAbortOnError:on $options -r $file"
  matrix: "-d:pga.dimensions=3 -d:pga.is_conformal=false"
  batchable: true
  joinable: true
  """
  include "../suites.nim"
  ```

- `std/unittest` suites and `check`; `randomize(0)`; a preallocated sample pool served by
  `lent` iterators:

  ```nim
  iterator randMultivectors(count = SAMPLES):
      (lent Multivector, lent Multivector, lent Multivector) = ...
  ```

- Compare floats through `=~` with the build-configurable tolerance; `==` on those types is
  poisoned and must not compile.

## 7. Targets

What a binding costs depends on the backend, and the constitution (Article VII) requires
the lowered output to be read. What to look for:

- **C and C++ backends.** A `let` of an object copies the struct; `lent` and `var` are
  pointers; `array[N, T]` of objects is contiguous. The emitted C sits in the nimcache
  directory; grep the proc's name there.
- **JS backend.** Every object and array is a JS object, and copying is deep: `let x = y` of
  an object emits `nimCopy`; a by-value parameter copies at the call; a by-value return
  copies on the way out; `lent` and `var` avoid the copy only when the value is read inline.
  `slot in a ..< b` builds a slice object; `seq.add` and string concatenation allocate.
  Check: `grep -c nimCopy` on the emitted file, and read one call site of each new binding
  shape. A `let` of a scalar is free on both backends.
- Boundaries (`{.importc.}`, `{.importjs.}`, `{.exportc.}`) are where each target's rule is
  documented, once, beside the declaration that crosses it.

Do not imitate snapshot defects: no debug `echo` in committed tests, no trailing whitespace,
no misspellings, no missing `{.compileTime.}` inside an otherwise staged family.
