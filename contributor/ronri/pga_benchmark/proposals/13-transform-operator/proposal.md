# P13: One operator for the transform of a multivector, built from the types of its operands

**What it is.** `m ⟇⟇~∘ n` transforms 𝐦 by 𝐧 in one call: the sandwich 𝐧 ⟇ 𝐦 ⟇ 𝐧̰, which pin spells
in three steps. Its typed form builds the terms of that sandwich from the types of both operands,
when the code compiles. So each value of each type transforms exactly, and the result takes the
bases that the terms reach. A full operator takes the three steps of pin, whatever the type of
𝐦 is. The alias `transform` of `pga.nim` reads the operator.

**What it is for.** At pin a transform spells three steps, two antiproducts and an antireverse,
which is gap cause D08. With this proposal the transform by a motor type is one function. At
rga4d it spends 82 multiplies and 113 adds and subtractions, where the chain spends 384
and 352. Each transform there then runs at ×0.27 of pin. A typed point and line at rga3d spend the
multiplies and adds of Lengyel's code. At rga4d a typed point and plane spend his multiplies and 3
adds more, and a line 1 multiply and 16 adds more.

**What it costs.** Each pair of types builds its sum when a program first calls it, so
`import pga` builds none. The macro writes out two orders of each sum, and keeps the order of
fewer operations. At cga6d a full multivector by a motor type then adds about 3 s to the build
of a program. The macro holds 142 lines of Nim, where three forms held 226.

## Problem

The library has no operator for a transform. So the catalogue spells each transform by motor as
`((n ⟇ m) ⟇ (~∘ n))`. The gap list names the five transform measurands under D08. Each step
writes a whole multivector, and the next step reads it. Each antiproduct reads every pair of
bases, though a motor holds the antieven bases alone.

At rga4d the reference transforms a point in 35 multiplies, a line in 52 and a plane in 35. The
chain spends 384 on each, and runs 100 to 125 ns against 10.5 to 16 ns of the reference, in the
runtime baselines.

## Idea

- **Terms from types.** `constructSandwich` expands 𝐧 ⟇ 𝐦 ⟇ 𝐧̰ term by term, from
  `CAYLEYS_WEDGE_DOT.anti` and `CAYLEYS_REVERSE.anti`. So each term follows the metric and the
  orientation of the library. It walks the bases of the type of 𝐦, and the pairs of bases of the
  type of 𝐧, when the code compiles. So a motor type reads its antieven pairs alone, and a flector
  type its antiodd pairs. The operator is then correct for each value of each type that it takes
  (IV.8), as the Architect ruled (D49 f).
- **Pairs.** The coefficients of 𝐧 commute, so the terms of 𝐧ᵢ𝐧ⱼ and 𝐧ⱼ𝐧ᵢ merge into one pair.
  A pair of two bases sums both orders, which comes out even in each of the nine algebras. Its
  product reads one of its bases doubled, so each term of a rigid sum weighs ±1.
- **Result type.** The result takes the bases that the terms reach, through `zeroNamed` of P14.
  So a motor transforms a vector to a vector, and a full multivector to a full one.
- **Full operator.** `Multivector` is the instance of `MultivectorOf` over every basis. So a full
  𝐧 takes a function of its own, generic in 𝐦 alone, which Nim picks over the form of two types.
  It spells the three steps of pin for each type of 𝐦, as the Architect ruled (D1 b on #990). A
  sum over every pair spends 204 multiplies and 607 adds at rga4d, which is more adds than the
  chain. Code that needs speed types both the object and the operator.
- **Two orders.** Each coefficient of the result is one sum of terms ±𝐧ᵢ𝐦ₖ𝐧ⱼ. The sum has two
  orders: multiply 𝐧 by 𝐧 first, or 𝐧 by 𝐦 first. The macro writes out both, counts the
  multiplies and adds of each, and keeps the order of fewer. An add of a negated term is a
  subtraction in C, and counts as one add. A tie keeps the matrix.
  The count reads the Cayley tables alone, so the choice reads no time and holds on every
  machine. So no order is written by hand for one object or one algebra, as the Architect ruled
  (D1 a on #1056).
- **Matrix.** It multiplies 𝐧 by 𝐧 first. It names the product of each pair once, and a cross
  pair reads its second basis doubled, so each basis doubles once at most. In a coefficient, the
  factor of a basis of 𝐦 is an entry, a signed sum of products of pairs. The coefficient sums
  each entry times its basis of 𝐦. So the matrix pays one product for each pair of 𝐧, and one
  multiply for each entry.
- **Entries.** Where an entry is more than one bare pair, the macro names it once, up to its
  sign. So two coefficients that read one entry compute it once, as Lengyel computes his matrix
  once, and the count reads each entry once. The macro finds an entry by its code, with its first
  term positive.
- **Chain.** It multiplies 𝐧 by 𝐦 first: 𝐭 = 𝐧 ⟇ 𝐦, then 𝐭 ⟇ 𝐧̰. It spells both antiproducts
  from `CAYLEYS_WEDGE_DOT.anti`, as `emitMultipliedByBasis` of P04 spells one. 𝐭 holds only the
  bases that some coefficient of the result reads, and the sign of the antireverse folds into
  each term. One 𝐭 serves each coefficient, but the chain reads each cross pair twice.
- **Neither order wins on every pair.** Both the size of 𝐧 and the size of 𝐦 move the choice.
  At cga6d a scalar by a motor keeps the matrix, at 556 operations against 1 040. A vector by the
  same motor keeps the chain, at 1 108 against 1 755. So the count decides, pair by pair.
- **Place.** The operator carries `inline` and `noinit`, as each form of P04 does. It stands in
  the typed section of `pga/operators.nim`, and edits no table of `pga/cayleys.nim`. Each order
  is a function nested in the macro, since the macro alone calls it, and each reads `emitSum`
  and `emitBasis` of P04.
- **Symbol.** The compound operators of `pga.nim` join their steps outer first, as `∨∧★` stands
  for 𝐧 ∨ (𝐦 ∧ 𝐧★). So `⟇⟇~∘` stands for 𝐧 ⟇ (𝐦 ⟇ 𝐧̰), as the Architect ruled on 2026-11-15.
  Nim 2.4.0 reads `⟇`, `~` and `∘` as characters of one operator.
- **Alias.** `transform(m, n)` reads `m ⟇⟇~∘ n`, as the Architect ruled (D50 a). Its row joins the
  compound operators of the header of `pga.nim`.
- **Tests.** Two tests join the suite `Typed operators` of P04. One holds the operator near the
  chain for seven pairs of typed operators, and its type to the bases that the chain reaches. The
  operator and the chain sum their terms in other orders, so they agree within the tolerance of
  `=~` alone. The other test holds a full, a vector and an even 𝐦 by a full operator to the chain
  exactly. It also holds the type of that result to full, and the alias to the operator.

Each cell gives multiplies, and adds with subtractions, for a full 𝐦 by a motor type. The chain
is counted from its two tables, and the operator as the evaluation reads its C:

| Algebra | Chain | This proposal | Reference, point | Time of transforms, of pin |
|---------|-------|---------------|------------------|----------------------------|
| rga3d | 96 and 80 | 23 and 16 | 14 and 10 | ×0.27 |
| rga4d | 384 and 352 | 82 and 113 | 35 and 40 | ×0.27 |

## Alternatives

| Option | Why it lost |
|--------|-------------|
| Antieven pairs for any 𝐧 | A reflection operator transforms each multivector to zero (D49 f) |
| Every pair for full operands | 204 multiplies and 607 adds at rga4d, more adds than the chain |
| Sum for a typed 𝐦 by a full 𝐧 | Code that needs speed types its operator (D1 b on #990) |
| Chain as one function | Closes D08, but spends what the chain spends |
| A pair counted twice | 72 adds more at rga4d, one for each of 76 reads of a cross pair, less 4 |
| First basis of each pair doubled | More operations on 21 of 130 pairs of types, fewer on 1 |
| Each entry where it is read | Count reads more than the C, so a line at rga4d takes the chain |
| Matrix alone, or chain alone | Each is more than ×1.9 of the faster order on some pair of types |
| Three forms of 2026-11-27 | Five rules where two orders serve, tails ×1.35 and ×1.66 (D1 a) |
| Cross form or chain | Three of the five rules, and a line at rga4d of 52 and 52 (D1 a on #1056) |
| Weight folded first | Same counts, but bulk comes first by convention (D1 a of 2026-11-27) |
| Choice by time | It reads one machine, which the goal of the library keeps out |
| Count weighted by cycles | It reads the cores of some machines, and moves 1 choice of 148 |
| Shared sums of two terms | The compiler fails its loop bound at six dimensions (D1 a on #1056) |
| Line through quaternion 𝐤 | Lengyel's form for one object, which no rule of the tables gives |

## Costs

- **Build of a call.** Each pair of types builds both orders once in the virtual machine of the
  compiler, the first time a program calls it. At cga6d a full multivector by a motor type adds
  2.9 s to the build of a program, and 86 MiB to the peak of the compiler. The three forms add
  3.6 s and 123 MiB there, on the same machine. At rga4d the call moves the build by less than the
  spread of the builds.
- **Build of `import pga`.** It builds no sum. In the evaluation, it takes 9.81 s at cga6d against
  8.74 s at pin, with P04 and P14 under it. At cga5d it peaks at 210.6 MiB, against 210.5 MiB at
  pin.
- **Size.** At rga4d the function holds 134 lines of C, inline in each caller. The macro holds
  142 lines of Nim, and runs only when the code compiles.
- **Lengyel's five.** The two orders spend more adds than three of the transforms of Lengyel's
  reference. A point and a plane at rga4d spend 3 adds more, and a line 1 multiply and 16 adds
  more. The line runs at ×1.13 of his time, and the point at rga3d at ×1.12, though it spends his
  counts. So [the gap of P13's table to Lengyel
  (#1015)](https://github.com/mraxilus/delegations/issues/1015) stays open, as the Architect ruled
  (D1 a on #1056).
- **Dimensions.** The matrix grows with the pairs of 𝐧 and its entries, and the chain with 𝐭,
  so the chain wins more pairs at more dimensions. For a full 𝐦 by a motor type, the macro keeps
  the matrix at cga5d: 464 multiplies and 1 167 adds, against 2 048 and 1 984 of the chain at pin.
  At rga6d it keeps the chain: 3 072 and 2 944, against 6 144 and 6 016. At cga6d it keeps the
  chain: 4 096 and 3 968, against 8 192 and 8 064.

## Open decisions

None. The Architect ruled D1 a on [the transform of P13 by two orders
(#1056)](https://github.com/mraxilus/delegations/pull/1056) on 2026-11-28. The macro writes out
two orders and keeps the order of fewer operations, so #1015 stays open. The Architect also asked
that the macro follow the style of the pga library, and that one example show each step from the
macro to the assembly. The Evidence below holds that example.

The rulings of 2026-11-26 and 2026-11-27 on #1056 chose a cover of doubled bases, sums in order,
the bulk folded first and the fewest of three forms. D1 a of 2026-11-28 replaces each of them.

The Architect ruled D48 a, D49 f and D50 a on
[the list of decisions (#921)](https://github.com/mraxilus/delegations/issues/921). The Architect
ruled D1 b on [the typed transform of P13 (#990)](https://github.com/mraxilus/delegations/pull/990),
so a full operator takes the chain, whatever the type of 𝐦 is.

## Landing

- **P04, `basis-set-forms`.** This proposal builds on it. Its operator stands beside the forms of
  P04, reads their helpers, and names its result through `zeroNamed` of P14. Every edit quotes
  text of pin as P04 leaves it.
- **P01, `cayley-derivation`.** It replaces `pga/cayleys.nim` whole, and keeps
  `CAYLEYS_WEDGE_DOT`, `CAYLEYS_REVERSE` and the fields of each term. This proposal edits no line
  of that file, so either order applies.
- **P12, `cayley-cells`.** It gives each cell a fixed array, and keeps `items` over it.
  `constructSandwich` and the chain read each cell through `items`, so either order applies.
- **P09, `object-names`.** It names `Motor` at rga4d, a basis-set type of the antieven bases. So
  `transform(p, motor)` reads the sum of this proposal at the type `Motor`.
- **Change `doc-comments`.** It writes in the header of `pga.nim` that `pga/operators.nim` holds
  two macros. P04 adds three, and this proposal one. It also moves the four rows of the
  projections out of the table of that header. This proposal adds its row after the last of them,
  so whichever of the two lands second quotes the other.
- **This project.** The catalogue spells each transform as `(m ⟇⟇~∘ n)` where the library
  declares the operator, and as the chain at pin. Where the operator takes a motor at its type,
  the motor reads the typed pool of motors, so the measurands time and count this sum. Against
  the library of this proposal, the suites of this project pass at rga3d and rga4d. At cga4d and
  cga5d, the suites that hold its symbols and aliases to the exports fail. The catalogue holds
  transforms under the rigid metric alone, so its conformal part then needs a measurand of `⟇⟇~∘`
  and `transform`.

## Evidence

`laws.nim` holds the operator equal to the chain on 256 seeded samples of ten pairs of types, at
each of the nine algebras. The pairs take a full multivector by a motor part, a flector part and
a vector. They take a vector, a bivector and a motor part by a motor part, and a vector by a
vector. They take a vector, a motor part and a full multivector by a full multivector. Across the
nine algebras they reach both orders: a bivector by a motor part takes the matrix at rga3d and
rga4d, and the chain at cga5d.

The laws also hold the type of each result to the bases that the chain reaches, and the alias
equal to the chain. By a full multivector, they hold the result to the chain bit for bit, and its
type to full. Ten count claims hold the multiplies and the adds of each transform measurand:
82 and 113 at rga4d, and 23 and 16 at rga3d. The operator spends no zero fill, intermediate or
error check there.

Its evaluation of 2026-11-28 times the transforms at ×0.27 of pin at rga4d, 19.05 ns against
71.56 to 71.58 ns. At rga3d they take ×0.27, 4.79 to 4.85 ns against 17.86 to 17.92 ns. The other
measurands read ×0.93 to ×1.09. The suites pass at the four algebras, with the two tests of this
proposal. It ran on the Xeon of family 6 model 173, and pin ran in the same run, so each ratio
compares one machine.

**One example, from the macro to the assembly.** A point by a motor at rga3d is the smallest
transform of Lengyel's reference. The motor 𝐧 = 0.25𝐞₁ + 0.5𝐞₂ + 0.6𝐞₃ + 0.8𝐞₃₂₁ rotates about a
point, with cos θ = 0.28 and sin θ = 0.96. It moves the point 𝐦 = 𝐞₁ + 2𝐞₂ + 𝐞₃, at (1, 2), to
(−0.54, 1.72).

```nim
const
  POINT = {Basis.E1, Basis.E2, Basis.E3}
  MOTOR = {Basis.E1, Basis.E2, Basis.E3, Basis.E321}

proc transformPoint(p: ptr MultivectorOf[POINT], q: ptr MultivectorOf[MOTOR],
                    r: ptr MultivectorOf[POINT]) {.noinline, exportc: "transform_point".} =
  r[] = p[] ⟇⟇~∘ q[]
```

The macro writes out both orders and counts each. The matrix spends 14 multiplies and 10 adds,
and the chain 18 and 11. So the macro keeps the matrix. Nim prints the code that it emits as
below:

```nim
let
  doubled_E3 = n[Basis.E3] + n[Basis.E3]
  pair_E1_E3 = n[Basis.E1] * doubled_E3
  doubled_E321 = n[Basis.E321] + n[Basis.E321]
  pair_E2_E321 = n[Basis.E2] * doubled_E321
  pair_E3_E3 = n[Basis.E3] * n[Basis.E3]
  pair_E3_E321 = n[Basis.E3] * doubled_E321
  pair_E321_E321 = n[Basis.E321] * n[Basis.E321]
  pair_E1_E321 = n[Basis.E1] * doubled_E321
  pair_E2_E3 = n[Basis.E2] * doubled_E3
let
  entry_0 = pair_E3_E3 + -pair_E321_E321
  entry_1 = pair_E1_E3 + pair_E2_E321
  entry_2 = pair_E1_E321 + -pair_E2_E3
  entry_3 = pair_E3_E3 + pair_E321_E321
result[Basis.E1] = -(entry_0 * m[Basis.E1]) +
    -(pair_E3_E321 * m[Basis.E2]) +
    entry_1 * m[Basis.E3]
result[Basis.E2] = pair_E3_E321 * m[Basis.E1] +
    -(entry_0 * m[Basis.E2]) +
    -(entry_2 * m[Basis.E3])
result[Basis.E3] = entry_3 * m[Basis.E3]
```

The chain that the macro drops reads 𝐭 = 𝐧 ⟇ 𝐦 first. Each coefficient of the result then
multiplies 𝐭 by 𝐧 again, so it reads the pair of 𝐞₃ and 𝐞₃₂₁ twice, where the matrix names it once:

```nim
let
  t_E1 = n[Basis.E2] * m[Basis.E3] + -(n[Basis.E3] * m[Basis.E2]) + n[Basis.E321] * m[Basis.E1]
  t_E2 = -(n[Basis.E1] * m[Basis.E3]) + n[Basis.E3] * m[Basis.E1] + n[Basis.E321] * m[Basis.E2]
  t_E3 = n[Basis.E321] * m[Basis.E3]
  t_E321 = -(n[Basis.E3] * m[Basis.E3])
result[Basis.E1] = t_E1 * n[Basis.E321] + -(t_E2 * n[Basis.E3]) + t_E3 * n[Basis.E2] +
    -(t_E321 * n[Basis.E1])
result[Basis.E2] = t_E1 * n[Basis.E3] + t_E2 * n[Basis.E321] + -(t_E3 * n[Basis.E1]) +
    -(t_E321 * n[Basis.E2])
result[Basis.E3] = t_E3 * n[Basis.E321] + -(t_E321 * n[Basis.E3])
```

On the example, the entries are the matrix of a rigid motion of the plane. Entry 0 is −cos θ, the
pair of 𝐞₃ and 𝐞₃₂₁ is sin θ, and entries 1 and 2 are the translation:

| Name | Value | Name | Value |
|---|---|---|---|
| `doubled_E3` | 1.2 | `entry_0` | −0.28 |
| `doubled_E321` | 1.6 | `entry_1` | 1.1 |
| `pair_E3_E3` | 0.36 | `entry_2` | −0.2 |
| `pair_E321_E321` | 0.64 | `entry_3` | 1.0 |
| `pair_E3_E321` | 0.96 | `result[E1]` | 0.28 − 1.92 + 1.1 = −0.54 |
| `pair_E1_E321` | 0.4 | `result[E2]` | 0.96 + 0.56 + 0.2 = 1.72 |
| `pair_E2_E3` | 0.6 | `result[E3]` | 1.0 |

Nim writes the C below for gcc. Each `let` is a local, and each subscript is a constant index:

```c
doubled_E3_1 = (((NF) (*n_p1).elements[(((NI) 2) - 0)]) + ((NF) (*n_p1).elements[(((NI) 2) - 0)]));
pair_E1_E3_1 = (((NF) (*n_p1).elements[(((NI) 0) - 0)]) * ((NF) doubled_E3_1));
/* … the other seven products of pairs, one line each … */
entry0_1 = (((NF) pair_E3_E3_1) + ((NF) (-(pair_E321_E321_1))));
entry1_1 = (((NF) pair_E1_E3_1) + ((NF) pair_E2_E321_1));
entry2_1 = (((NF) pair_E1_E321_1) + ((NF) (-(pair_E2_E3_1))));
entry3_1 = (((NF) pair_E3_E3_1) + ((NF) pair_E321_E321_1));
result.elements[(((NI) 2) - 0)] = (((NF) entry3_1) * ((NF) m_p0.elements[(((NI) 2) - 0)]));
```

gcc at `-O3` packs two lanes in each SSE2 register, so one instruction can compute two values.
Each comment gives the low lane, then the high lane:

```asm
endbr64                       # landing pad of an indirect branch
movapd 0x10(%rsi),%xmm0       # [n.E3, n.E321]
movapd (%rsi),%xmm6           # [n.E1, n.E2]
movsd  0x10(%rdi),%xmm3       # m.E3
movsd  (%rdi),%xmm5           # m.E1
movapd %xmm0,%xmm2            # [n.E3, n.E321]
movapd %xmm0,%xmm7            # [n.E3, n.E321]
movapd %xmm6,%xmm1            # [n.E1, n.E2]
movupd (%rdi),%xmm4           # [m.E1, m.E2]
addpd  %xmm0,%xmm2            # [doubled_E3, doubled_E321]
movapd %xmm0,%xmm8            # [n.E3, n.E321]
shufpd $0x1,%xmm0,%xmm0       # [n.E321, n.E3]
unpckhpd %xmm7,%xmm7          # [n.E321, n.E321]
addpd  %xmm0,%xmm0            # [doubled_E321, doubled_E3], the same doubles in the other lanes
unpcklpd %xmm6,%xmm1          # [n.E1, n.E1]
unpckhpd %xmm6,%xmm6          # [n.E2, n.E2]
mov    $0xffffffffffffff98,%rax  # address of the error flag of Nim
mulsd  %xmm7,%xmm7            # pair_E321_E321
unpckhpd %xmm4,%xmm4          # [m.E2, m.E2]
mulpd  %xmm2,%xmm1            # [pair_E1_E3, pair_E1_E321]
unpckhpd %xmm2,%xmm2          # [doubled_E321, doubled_E321]
cmpb   $0x0,%fs:(%rax)        # test the error flag
mulpd  %xmm6,%xmm0            # [pair_E2_E321, pair_E2_E3]
mulsd  %xmm8,%xmm2            # pair_E3_E321
movapd %xmm1,%xmm6            # [pair_E1_E3, pair_E1_E321]
addpd  %xmm0,%xmm6            # [entry_1, unused]
subpd  %xmm0,%xmm1            # [unused, entry_2]
movapd %xmm3,%xmm0            # m.E3
unpcklpd %xmm0,%xmm0          # [m.E3, m.E3]
movsd  %xmm6,%xmm1            # [entry_1, entry_2]
movapd %xmm8,%xmm6            # [n.E3, n.E321]
mulsd  %xmm8,%xmm6            # pair_E3_E3
mulpd  %xmm0,%xmm1            # [entry_1 · m.E3, entry_2 · m.E3]
movapd %xmm6,%xmm8            # pair_E3_E3
addsd  %xmm7,%xmm6            # entry_3
subsd  %xmm7,%xmm8            # entry_0
mulsd  %xmm3,%xmm6            # result[E3] = entry_3 · m.E3
movapd %xmm8,%xmm0            # entry_0
mulsd  %xmm5,%xmm0            # entry_0 · m.E1
mulsd  %xmm2,%xmm5            # pair_E3_E321 · m.E1
unpcklpd %xmm8,%xmm2          # [pair_E3_E321, entry_0]
xorpd  0x3a06(%rip),%xmm0     # −(entry_0 · m.E1), the one negation
mulpd  %xmm2,%xmm4            # [pair_E3_E321 · m.E2, entry_0 · m.E2]
unpcklpd %xmm5,%xmm0          # [−(entry_0 · m.E1), pair_E3_E321 · m.E1]
subpd  %xmm4,%xmm0            # first two terms of result[E1] and of result[E2]
movapd %xmm0,%xmm2            # copy of both
subpd  %xmm1,%xmm0            # [unused, result[E2]], less entry_2 · m.E3
addpd  %xmm1,%xmm2            # [result[E1], unused], plus entry_1 · m.E3
movsd  %xmm2,%xmm0            # [result[E1], result[E2]]
jne    11170 <transform_point+0xe0>  # error path of Nim, where the flag is set
movups %xmm0,(%rdx)           # store result[E1] and result[E2]
movsd  %xmm6,0x10(%rdx)       # store result[E3]
ret
```

The 10 multiply instructions compute the 14 multiplies of the emitted code, since 4 of them fill
both lanes. The 9 adds and subtractions compute its 10 adds, and one of them doubles 𝐞₃ and 𝐞₃₂₁
again in the other lanes. One `xorpd` negates the first term of a coefficient, since the compiler
keeps the order of each sum. The test of the error flag comes from the wrapper, since Nim tests
its flag after each call that the wrapper makes.

**Lengyel's five transforms.** A typed object by a typed motor reads the sum of its own two types.
Each takes the matrix:

| Algebra | Object | Operator: multiplies, adds | Lengyel: multiplies, adds | Of his time |
|---|---|---|---|---|
| rga4d | point | 35, 43 | 35, 40 | ×1.01 to ×1.09 |
| rga4d | line | 53, 70 | 52, 54 | ×1.13 to ×1.14 |
| rga4d | plane | 35, 43 | 35, 40 | ×1.06 to ×1.08 |
| rga3d | point | 14, 10 | 14, 10 | ×1.11 to ×1.12 |
| rga3d | line | 14, 10 | 14, 10 | ×1.00 |

Each count reads the code that the macro emits. Each pair ran four times on 2026-11-28, on the
Xeon of family 6 model 173, with seven passes in a copy of the timed loop of `measurements.nim`.
Each ratio is the time of the operator against the time of Lengyel's code in the same run. On the
same machine, the three forms of 2026-11-27 read ×1.01 to ×1.06, ×1.00, ×0.98 to ×1.04, ×0.96
and ×1.01 to ×1.02. The point at rga3d spends his counts, but gcc packs its lanes in other pairs,
and it runs at ×1.12.

**130 pairs of types.** The same loop timed 130 pairs of types at the nine algebras on 2026-11-28,
twice each, on the same machine. They take each grade, a motor part and a flector part, by a
motor type and by a flector type. In the same binary, it timed the operator, the three forms of
2026-11-27, and each order alone. Each ratio below is against the fastest of six forms for that
pair:

| Rule | Median | 90th percentile | Worst | Within ×1.10 |
|---|---|---|---|---|
| Two orders, this proposal | ×1.005 | ×1.15 | ×1.27 | 110 of 130 |
| Three forms of 2026-11-27 | ×1.03 | ×1.35 | ×1.66 | 90 of 130 |

Against the three forms, the median reads ×0.99. A bivector by a motor at cga6d reads ×0.61,
where the typed chain wrote out terms that no coefficient reads. A flector by a motor at rga5d
reads ×1.27, where the cross form spent fewer operations than either order.

llvm-mca 18 also models the cycles of each form, as the geometric mean of four x86 cores. Against
the fastest of six forms, the 90th percentile reads ×1.19 for the two orders and ×1.47 for the
three forms. With `-march=x86-64-v3`, it reads ×1.31 and ×1.45. For AArch64 under clang, on
three cores, it reads ×1.43 and ×1.28, so the three forms fit that model better. No rule of the
macro reads a target, so the operator keeps that cost.

A full 𝐦 by a motor at rga6d keeps the chain, at 3 072 multiplies and 2 944 adds. The cross form
spent 1 704 and 2 567 there, so this pair spends ×1.41 the operations of the three forms.

The counts of the chain, of the other algebras and of the forms that lost come from scripts that
read the tables of pin. The build of one call is the median of four builds of a program with the
call, against four without it. The scripts are not committed, so these figures are assumed until
a claim holds them. No claim holds the order that each pair keeps either. The laws hold each
order equal to the chain, but they pass whichever order the macro keeps. So the order and the
counts of each typed transform above are assumed too.
