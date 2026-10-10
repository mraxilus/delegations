# Gaps

The driver writes this file. To make it again, run `nim r tools/build.nim gaps`, which reads
`baseline/*.json`. Do not edit it by hand. Every gap keeps its number, because
`baseline/docket.json` holds the numbers and the driver reuses none. The pinned compiler emits C for
the `bench` entry, and the inspector counts that C. A cell gives the library value first and the
reference value second.

A gap is over where the library spends more than its reference. It is also over where the library
spends a zero fill, an intermediate, an error check, an allocation or a NaN. Time is over where the
library median is more than 1.25 times the reference median. A gap is met in every other case. Bytes
are modelled movement for each call, and runtime measurements are medians of the last bench that ran
by hand.

Each operation carries two lower bounds, and the library stands above both. The multivector lower
bound is what the algebra demands of any implementation over a dense multivector. It is derived from
the axioms, and it is never measured. The type optimised lower bound is the typed reference, which
is measured rather than derived. Work that reaches the first bound changes no type, and work that
reaches the second changes every one.

Each algebra below carries a table of multivector lower bounds. That bound spends no zero fill, no
intermediate, no error check and no allocation, and it moves its operands read once plus its result
written once. It rests on the operation alone, so one row serves every measurand that spells that
operation. The last column is what the library spends there, as multiplies over bytes moved. An
operation whose shape carries no rule is absent, rather than present without ground.

A shape of several steps names a chain, which the library composes from several operators. The bound
of a chain sums what each step demands, and a step that carries no rule adds nothing. Such a bound
is an estimate of that chain, and never a proved minimum, because a special routine can share work
between steps. Every other bound in these tables is derived from the axioms alone.

## Causes

- **D01, over.** Dense products spend every Cayley-table term where typed forms spend few. Evidence:
  128 gaps. The widest is cga5d/partner_round_point, which spends 518 multiplies against 10. Closes
  when no typed gap spends more multiplies than its reference.
- **D02, over.** Library calls run slower than typed forms beyond the band. Evidence: 262 gaps. The
  worst is cga5d/carrier_co_round_point, at 59.3 ns against 0.4 ns. Closes when no gap's library
  median exceeds 1.25 times its reference's.
- **D03, over.** Operators zero-fill their full-width result before they write it. Evidence: 68 of
  188 library functions. The most is cga5d `⊛(Multivector)` with 108. Closes when no library
  function calls `nimZeroMem`.
- **D04, over.** Operator chains build full-width intermediates. Evidence: 52 of 188 library
  functions. The most is cga5d `⊛(Multivector)` with 8. Closes when no library function declares a
  local multivector.
- **D05, over.** Error-flag checks survive into release builds. Evidence: 64 of 188 library
  functions. The most is cga5d `⊛(Multivector)` with 271. Closes when no library function branches
  on `nimErr_`. The pinned compiler with `--panics:on` already emits none in either implementation.
  A user of the library must know to pass it.
- **D06, over.** Sign and permutation operators cross the module boundary as calls. Evidence: 8 of
  150 library operators, for example rga4d `{}(Multivector,int)`. Closes when every library function
  spending no multiply, add or subtract is inline.
- **D07, over.** Conformal norms return NaN on real objects. Evidence: cga5d/norm_bulk,
  cga5d/norm_weight, cga5d/norm, cga5d/normalize_bulk, cga5d/normalize_weight, cga5d/unitize, and 10
  more. Closes when every bench measurement's NaN share is zero.
- **D08, over.** A transform by motor spells three products, because it has no operator of its own.
  Evidence: rga4d/transform_point_motor, rga4d/transform_line_motor, rga4d/transform_plane_motor,
  rga3d/transform_point_motor, rga3d/transform_line_motor. Closes when every catalogued measurand
  spells one library function.
- **D09, over.** The library refuses two norms that the reference carries. Evidence:
  cga5d/norm_center `|⊙`, cga5d/norm_radius `|⊘`, cga4d/norm_center `|⊙`, cga4d/norm_radius `|⊘`.
  Closes when the catalogue's missing list is empty.
- **D10, unmeasured.** The library builds compile-time Cayley tables and drops some, by the audit's
  reading. Evidence: no emitted C reaches it. The audit read `cayleys.nim`. Closes when the project
  measures tables built against tables used. Nothing here reads compile time.

## rga4d

This algebra has 4 dimensions, a rigid metric and a 128-byte multivector. The inspector took the
counts on 2026-10-09, on linux amd64, 4 cores, with nim `27763495bcfe265507ca98aedc1c7064bf1e0e4d`,
pga `e993419c1f90efba72848d146606f903e1cc141e` and flags `-d:release`. The bench ran 5 times on
2026-10-03, on linux amd64, 4 cores, over 40 rounds of 1024 objects each. Each time is the median of
those runs. It ran at pga `d9be8aefc193f6ee0a7a3fead25cd4fe1d8f09cf`, which emits the same C as the
pin. The allocation gauge was live.
Gaps: 111. Over 85, met 26, unmeasured 0.

| Id | Measurand | Mul | Div | Bytes | Int | Chk | ns | Status |
|----|-----------|-----|-----|-------|-----|-----|----|--------|
| G001 | wedge | 81/– | 0/– | 384/– | 0/– | 0/– | 28.9/– | met |
| G002 | wedge_anti | 81/– | 0/– | 384/– | 0/– | 0/– | 28.3/– | met |
| G003 | wedge_dot | 192/– | 0/– | 384/– | 0/– | 0/– | 65.2/– | met |
| G004 | wedge_dot_anti | 192/– | 0/– | 384/– | 0/– | 0/– | 68.3/– | met |
| G005 | dot | 8/– | 0/– | 384/– | 0/– | 0/– | 6.3/– | met |
| G006 | dot_anti | 8/– | 0/– | 384/– | 0/– | 0/– | 6.2/– | met |
| G007 | contract_bulk | 54/– | 0/– | 384/– | 0/– | 0/– | 14.7/– | met |
| G008 | contract_weight | 27/– | 0/– | 384/– | 0/– | 0/– | 8.0/– | met |
| G009 | expand_bulk | 27/– | 0/– | 384/– | 0/– | 0/– | 7.8/– | met |
| G010 | expand_weight | 54/– | 0/– | 384/– | 0/– | 0/– | 14.8/– | met |
| G011 | add | 0/– | 0/– | 384/– | 0/– | 0/– | 4.7/– | met |
| G012 | subtract | 0/– | 0/– | 384/– | 0/– | 0/– | 4.9/– | met |
| G013 | project_central | 108/– | 0/– | 1152/– | 2/– | 2/– | 36.3/– | over |
| G014 | project_central_anti | 135/– | 0/– | 1152/– | 2/– | 2/– | 41.7/– | over |
| G015 | project_orthogonal | 135/– | 0/– | 1152/– | 2/– | 2/– | 47.2/– | over |
| G016 | project_orthogonal_anti | 108/– | 0/– | 1152/– | 2/– | 2/– | 30.0/– | over |
| G017 | scale | 16/– | 0/– | 264/– | 0/– | 0/– | 5.6/– | met |
| G018 | bulk | 0/– | 0/– | 256/– | 0/– | 0/– | 2.7/– | met |
| G019 | weight | 0/– | 0/– | 256/– | 0/– | 0/– | 5.8/– | met |
| G020 | complement_right | 0/– | 0/– | 256/– | 0/– | 0/– | 4.1/– | met |
| G021 | complement_left | 0/– | 0/– | 256/– | 0/– | 0/– | 6.0/– | met |
| G022 | reverse | 0/– | 0/– | 256/– | 0/– | 0/– | 6.3/– | met |
| G023 | reverse_anti | 0/– | 0/– | 256/– | 0/– | 0/– | 4.0/– | met |
| G024 | dual_bulk | 0/– | 0/– | 256/– | 0/– | 0/– | 5.2/– | met |
| G025 | dual_weight | 0/– | 0/– | 256/– | 0/– | 0/– | 2.7/– | met |
| G026 | negate | 0/– | 0/– | 256/– | 0/– | 0/– | 2.9/– | met |
| G027 | norm_bulk | 8/– | 0/– | 640/– | 1/– | 1/– | 10.6/– | over |
| G028 | norm_weight | 8/– | 0/– | 640/– | 1/– | 1/– | 10.6/– | over |
| G316 | norm_bulk_squared | 8/– | 0/– | 256/– | 0/– | 0/– | 5.7/– | met |
| G317 | norm_weight_squared | 8/– | 0/– | 256/– | 0/– | 0/– | 5.0/– | met |
| G029 | norm | 16/– | 0/– | 1664/– | 4/– | 4/– | 12.2/– | over |
| G030 | normalize_bulk | 24/– | 1/– | 512/– | 1/– | 1/– | 6.8/– | over |
| G031 | normalize_weight | 24/– | 1/– | 512/– | 1/– | 1/– | 6.7/– | over |
| G032 | unitize | 24/– | 1/– | 512/– | 1/– | 1/– | 6.7/– | over |
| G033 | attitude | 0/– | 0/– | 256/– | 0/– | 0/– | 2.7/– | met |
| G034 | select_grade | 0/– | 0/– | 392/– | 0/– | 0/– | 13.6/– | over |
| G035 | select_grade_anti | 0/– | 0/– | 392/– | 0/– | 1/– | 14.7/– | over |
| G036 | select_part | – | – | – | – | – | 0.7/– | met |
| G037 | support | 162/– | 0/– | 1280/– | 3/– | 3/– | 88.0/– | over |
| G038 | support_anti | 162/– | 0/– | 1280/– | 3/– | 3/– | 56.4/– | over |
| G039 | wedge_point_point | 81/12 | 0/0 | 384/112 | 0/0 | 0/0 | 29.3/3.0 | over |
| G040 | wedge_line_point | 81/12 | 0/0 | 384/112 | 0/0 | 0/0 | 29.1/3.6 | over |
| G041 | wedge_point_line | 81/12 | 0/0 | 384/112 | 0/0 | 0/0 | 29.2/4.1 | over |
| G042 | wedge_anti_plane_plane | 81/12 | 0/0 | 384/112 | 0/0 | 0/0 | 28.2/3.2 | over |
| G043 | wedge_anti_plane_line | 81/12 | 0/0 | 384/112 | 0/0 | 0/0 | 28.1/3.7 | over |
| G044 | wedge_anti_line_plane | 81/12 | 0/0 | 384/112 | 0/0 | 0/0 | 28.4/3.7 | over |
| G045 | wedge_anti_line_line | 81/6 | 0/0 | 384/104 | 0/0 | 0/0 | 28.2/2.5 | over |
| G046 | wedge_anti_point_plane | 81/4 | 0/0 | 384/72 | 0/0 | 0/0 | 28.3/2.0 | over |
| G047 | dot_point_point | 8/3 | 0/0 | 384/72 | 0/0 | 0/0 | 6.2/1.6 | over |
| G048 | dot_line_line | 8/3 | 0/0 | 384/104 | 0/0 | 0/0 | 6.2/1.8 | over |
| G049 | dot_plane_plane | 8/1 | 0/0 | 384/72 | 0/0 | 0/0 | 6.2/1.1 | over |
| G050 | dot_anti_point_point | 8/1 | 0/0 | 384/72 | 0/0 | 0/0 | 6.2/1.1 | over |
| G051 | dot_anti_line_line | 8/3 | 0/0 | 384/104 | 0/0 | 0/0 | 6.2/1.8 | over |
| G052 | dot_anti_plane_plane | 8/3 | 0/0 | 384/72 | 0/0 | 0/0 | 6.2/1.6 | over |
| G053 | wedge_dot_anti_motor_motor | 192/48 | 0/0 | 384/256 | 0/0 | 0/0 | 68.5/13.1 | over |
| G054 | transform_point_motor | –/25 | –/0 | –/160 | –/0 | –/0 | 140.7/6.5 | over |
| G055 | transform_line_motor | –/57 | –/0 | –/208 | –/0 | –/0 | 138.1/12.2 | over |
| G056 | transform_plane_motor | –/36 | –/0 | –/160 | –/0 | –/0 | 138.3/8.5 | over |
| G057 | project_orthogonal_point_plane | 135/14 | 0/0 | 1152/128 | 2/0 | 2/0 | 47.2/3.8 | over |
| G058 | project_orthogonal_point_line | 135/19 | 0/0 | 1152/144 | 2/0 | 2/0 | 47.4/4.5 | over |
| G059 | project_orthogonal_line_plane | 135/27 | 0/0 | 1152/176 | 2/0 | 2/0 | 47.4/5.7 | over |
| G060 | support_line | 162/9 | 0/0 | 1280/80 | 3/0 | 3/0 | 88.0/2.3 | over |
| G061 | support_plane | 162/6 | 0/0 | 1280/64 | 3/0 | 3/0 | 89.3/1.5 | over |
| G062 | support_anti_point | 162/6 | 0/0 | 1280/64 | 3/0 | 3/0 | 56.5/1.5 | over |
| G063 | support_anti_line | 162/9 | 0/0 | 1280/80 | 3/0 | 3/0 | 56.7/2.2 | over |
| G064 | reverse_anti_motor | 0/0 | 0/0 | 256/192 | 0/0 | 0/0 | 4.0/1.4 | over |
| G065 | unitize_motor | 24/12 | 1/1 | 512/256 | 1/0 | 1/0 | 6.5/3.9 | over |
| G066 | norm_weight_motor | 8/4 | 0/0 | 640/72 | 1/0 | 1/0 | 10.6/1.6 | over |
| G067 | norm_bulk_motor | 8/4 | 0/0 | 640/72 | 1/0 | 1/0 | 10.8/1.9 | over |
| G068 | complement_right_point | 0/0 | 0/0 | 256/64 | 0/0 | 0/0 | 4.1/0.7 | over |
| G069 | complement_left_point | 0/0 | 0/0 | 256/64 | 0/0 | 0/0 | 6.2/0.7 | over |
| G070 | reverse_point | 0/0 | 0/0 | 256/96 | 0/0 | 0/0 | 6.5/0.7 | over |
| G071 | reverse_anti_point | 0/0 | 0/0 | 256/96 | 0/0 | 0/0 | 4.0/0.7 | over |
| G072 | dual_bulk_point | 0/0 | 0/0 | 256/64 | 0/0 | 0/0 | 5.3/0.8 | over |
| G073 | dual_weight_point | 0/0 | 0/0 | 256/64 | 0/0 | 0/0 | 2.8/0.8 | over |
| G074 | bulk_point | 0/0 | 0/0 | 256/96 | 0/0 | 0/0 | 2.8/0.8 | over |
| G075 | weight_point | 0/0 | 0/0 | 256/96 | 0/0 | 0/0 | 6.0/0.8 | over |
| G076 | norm_bulk_point | 8/3 | 0/0 | 640/40 | 1/0 | 1/0 | 10.4/1.8 | over |
| G077 | norm_weight_point | 8/0 | 0/0 | 640/40 | 1/0 | 1/0 | 10.8/0.5 | over |
| G318 | norm_bulk_squared_point | 8/3 | 0/0 | 256/40 | 0/0 | 0/0 | 5.8/0.8 | over |
| G319 | norm_weight_squared_point | 8/– | 0/– | 256/– | 0/– | 0/– | 5.2/0.5 | over |
| G078 | unitize_point | 24/3 | 1/1 | 512/128 | 1/0 | 1/0 | 7.0/1.2 | over |
| G079 | attitude_point | 0/0 | 0/0 | 256/40 | 0/0 | 0/0 | 2.7/0.6 | over |
| G080 | complement_right_line | 0/0 | 0/0 | 256/144 | 0/0 | 0/0 | 4.1/1.7 | over |
| G081 | complement_left_line | 0/0 | 0/0 | 256/144 | 0/0 | 0/0 | 6.0/1.7 | over |
| G082 | reverse_line | 0/0 | 0/0 | 256/144 | 0/0 | 0/0 | 6.3/1.9 | over |
| G083 | reverse_anti_line | 0/0 | 0/0 | 256/144 | 0/0 | 0/0 | 4.0/1.9 | over |
| G084 | dual_bulk_line | 0/0 | 0/0 | 256/144 | 0/0 | 0/0 | 5.2/2.4 | over |
| G085 | dual_weight_line | 0/0 | 0/0 | 256/144 | 0/0 | 0/0 | 2.7/1.3 | over |
| G086 | bulk_line | 0/0 | 0/0 | 256/144 | 0/0 | 0/0 | 2.7/2.5 | over |
| G087 | weight_line | 0/0 | 0/0 | 256/144 | 0/0 | 0/0 | 5.8/2.5 | over |
| G088 | norm_bulk_line | 8/3 | 0/0 | 640/56 | 1/0 | 1/0 | 10.8/1.8 | over |
| G089 | norm_weight_line | 8/3 | 0/0 | 640/56 | 1/0 | 1/0 | 10.6/1.8 | over |
| G320 | norm_bulk_squared_line | 8/3 | 0/0 | 256/56 | 0/0 | 0/0 | 5.8/0.9 | over |
| G321 | norm_weight_squared_line | 8/– | 0/– | 256/– | 0/– | 0/– | 5.0/0.9 | over |
| G090 | unitize_line | 24/9 | 1/1 | 512/192 | 1/0 | 1/0 | 7.0/3.2 | over |
| G091 | attitude_line | 0/0 | 0/0 | 256/80 | 0/0 | 0/0 | 2.7/0.9 | over |
| G092 | complement_right_plane | 0/0 | 0/0 | 256/64 | 0/0 | 0/0 | 4.1/0.7 | over |
| G093 | complement_left_plane | 0/0 | 0/0 | 256/64 | 0/0 | 0/0 | 6.0/0.7 | over |
| G094 | reverse_plane | 0/0 | 0/0 | 256/96 | 0/0 | 0/0 | 6.3/0.7 | over |
| G095 | reverse_anti_plane | 0/0 | 0/0 | 256/96 | 0/0 | 0/0 | 4.0/0.7 | over |
| G096 | dual_bulk_plane | 0/0 | 0/0 | 256/64 | 0/0 | 0/0 | 5.2/0.8 | over |
| G097 | dual_weight_plane | 0/0 | 0/0 | 256/64 | 0/0 | 0/0 | 2.7/0.8 | over |
| G098 | bulk_plane | 0/0 | 0/0 | 256/96 | 0/0 | 0/0 | 2.7/0.8 | over |
| G099 | weight_plane | 0/0 | 0/0 | 256/96 | 0/0 | 0/0 | 5.8/0.8 | over |
| G100 | norm_bulk_plane | 8/0 | 0/0 | 640/40 | 1/0 | 1/0 | 10.5/0.5 | over |
| G101 | norm_weight_plane | 8/3 | 0/0 | 640/40 | 1/0 | 1/0 | 10.6/1.8 | over |
| G322 | norm_bulk_squared_plane | 8/1 | 0/0 | 256/40 | 0/0 | 0/0 | 5.6/0.5 | over |
| G323 | norm_weight_squared_plane | 8/– | 0/– | 256/– | 0/– | 0/– | 5.0/0.8 | over |
| G102 | unitize_plane | 24/7 | 1/1 | 512/128 | 1/0 | 1/0 | 6.7/3.2 | over |
| G103 | attitude_plane | 0/0 | 0/0 | 256/80 | 0/0 | 0/0 | 2.8/2.0 | over |

### Multivector lower bound

| Op | Shape | Mul | Div | Roots | Bytes | Library mul/bytes |
|----|-------|-----|-----|-------|-------|-------------------|
| `∧` | Wedge | 81 | 0 | 0 | 384 | 81/384 |
| `∨` | Wedge | 81 | 0 | 0 | 384 | 81/384 |
| `⟑` | Geometric | 192 | 0 | 0 | 384 | 192/384 |
| `⟇` | Geometric | 192 | 0 | 0 | 384 | 192/384 |
| `∙` | FormScalar | 8 | 0 | 0 | 264 | 8/384 |
| `∘` | FormScalar | 8 | 0 | 0 | 264 | 8/384 |
| `∨★` | ContractBulk | 54 | 0 | 0 | 384 | 54/384 |
| `∨☆` | ContractWeight | 27 | 0 | 0 | 384 | 27/384 |
| `∧★` | ExpandBulk | 27 | 0 | 0 | 384 | 27/384 |
| `∧☆` | ExpandWeight | 54 | 0 | 0 | 384 | 54/384 |
| `+` | Componentwise | 0 | 0 | 0 | 384 | 0/384 |
| `-` | Componentwise | 0 | 0 | 0 | 384 | 0/384 |
| `projectCentral` | ExpandBulk + Wedge | 108 | 0 | 0 | 384 | 108/1152 |
| `projectCentralAnti` | ContractBulk + Wedge | 135 | 0 | 0 | 384 | 135/1152 |
| `projectOrthogonal` | ExpandWeight + Wedge | 135 | 0 | 0 | 384 | 135/1152 |
| `projectOrthogonalAnti` | ContractWeight + Wedge | 108 | 0 | 0 | 384 | 108/1152 |
| `∧` | Scale | 16 | 0 | 0 | 264 | 16/264 |
| `∙` | Permutation | 0 | 0 | 0 | 256 | 0/256 |
| `∘` | Permutation | 0 | 0 | 0 | 256 | 0/256 |
| `/` | Permutation | 0 | 0 | 0 | 256 | 0/256 |
| `\` | Permutation | 0 | 0 | 0 | 256 | 0/256 |
| `~` | Permutation | 0 | 0 | 0 | 256 | 0/256 |
| `~∘` | Permutation | 0 | 0 | 0 | 256 | 0/256 |
| `★` | Permutation | 0 | 0 | 0 | 256 | 0/256 |
| `☆` | Permutation | 0 | 0 | 0 | 256 | 0/256 |
| `-` | Permutation | 0 | 0 | 0 | 256 | 0/256 |
| `|∙` | Norm | 8 | 0 | 1 | 136 | 8/640 |
| `|∘` | Norm | 8 | 0 | 1 | 136 | 8/640 |
| `|∙²` | NormSquared | 8 | 0 | 0 | 136 | 8/256 |
| `|∘²` | NormSquared | 8 | 0 | 0 | 136 | 8/256 |
| `|` | 2 Norm | 16 | 0 | 2 | 136 | 16/1664 |
| `^∙` | Unitize | 24 | 1 | 1 | 256 | 24/512 |
| `^∘` | Unitize | 24 | 1 | 1 | 256 | 24/512 |
| `^` | Unitize | 24 | 1 | 1 | 256 | 24/512 |
| `⊖` | ProductConstant | 0 | 0 | 0 | 256 | 0/256 |
| `{}` | Permutation | 0 | 0 | 0 | 256 | 0/392 |
| `{}` | Permutation | 0 | 0 | 0 | 256 | 0/392 |
| `∩` | Support | 54 | 0 | 0 | 256 | 162/1280 |
| `∪` | SupportAnti | 54 | 0 | 0 | 256 | 162/1280 |
| `((n ⟇ m) ⟇ (~∘ n))` | Permutation + 2 Geometric | 384 | 0 | 0 | 384 | – |

## cga5d

This algebra has 5 dimensions, a conformal metric and a 256-byte multivector. The inspector took the
counts on 2026-10-09, on linux amd64, 4 cores, with nim `27763495bcfe265507ca98aedc1c7064bf1e0e4d`,
pga `e993419c1f90efba72848d146606f903e1cc141e` and flags `-d:release`. The bench ran 5 times on
2026-10-03, on linux amd64, 4 cores, over 40 rounds of 1024 objects each. Each time is the median of
those runs. It ran at pga `d9be8aefc193f6ee0a7a3fead25cd4fe1d8f09cf`, which emits the same C as the
pin. The allocation gauge was live.
Gaps: 131. Over 102, met 29, unmeasured 0.

| Id | Measurand | Mul | Div | Bytes | Int | Chk | ns | Status |
|----|-----------|-----|-----|-------|-----|-----|----|--------|
| G104 | wedge | 243/– | 0/– | 768/– | 0/– | 0/– | 97.3/– | met |
| G105 | wedge_anti | 243/– | 0/– | 768/– | 0/– | 0/– | 97.4/– | met |
| G106 | wedge_dot | 1024/– | 0/– | 768/– | 0/– | 0/– | 525.1/– | met |
| G107 | wedge_dot_anti | 1024/– | 0/– | 768/– | 0/– | 0/– | 529.7/– | met |
| G108 | dot | 32/– | 0/– | 768/– | 0/– | 0/– | 18.3/– | met |
| G109 | dot_anti | 32/– | 0/– | 768/– | 0/– | 0/– | 17.4/– | met |
| G110 | contract_bulk | 243/– | 0/– | 768/– | 0/– | 0/– | 96.4/– | met |
| G111 | contract_weight | 243/– | 0/– | 768/– | 0/– | 0/– | 100.5/– | met |
| G112 | expand_bulk | 243/– | 0/– | 768/– | 0/– | 0/– | 99.6/– | met |
| G113 | expand_weight | 243/– | 0/– | 768/– | 0/– | 0/– | 103.5/– | met |
| G114 | add | 0/– | 0/– | 768/– | 0/– | 0/– | 9.9/– | met |
| G115 | subtract | 0/– | 0/– | 768/– | 0/– | 0/– | 9.2/– | met |
| G116 | project_central | 486/– | 0/– | 2304/– | 2/– | 2/– | 214.6/– | over |
| G117 | project_central_anti | 486/– | 0/– | 2304/– | 2/– | 2/– | 188.3/– | over |
| G118 | project_orthogonal | 486/– | 0/– | 2304/– | 2/– | 2/– | 213.6/– | over |
| G119 | project_orthogonal_anti | 486/– | 0/– | 2304/– | 2/– | 2/– | 189.5/– | over |
| G120 | scale | 32/– | 0/– | 520/– | 0/– | 0/– | 6.5/– | met |
| G121 | bulk | 0/– | 0/– | 512/– | 0/– | 0/– | 12.7/– | met |
| G122 | weight | 0/– | 0/– | 512/– | 0/– | 0/– | 12.2/– | met |
| G123 | complement_right | 0/– | 0/– | 512/– | 0/– | 0/– | 7.0/– | met |
| G124 | complement_left | 0/– | 0/– | 512/– | 0/– | 0/– | 7.0/– | met |
| G125 | reverse | 0/– | 0/– | 512/– | 0/– | 0/– | 11.1/– | met |
| G126 | reverse_anti | 0/– | 0/– | 512/– | 0/– | 0/– | 9.5/– | met |
| G127 | dual_bulk | 0/– | 0/– | 512/– | 0/– | 0/– | 12.4/– | met |
| G128 | dual_weight | 0/– | 0/– | 512/– | 0/– | 0/– | 11.4/– | met |
| G129 | negate | 0/– | 0/– | 512/– | 0/– | 0/– | 5.7/– | met |
| G130 | norm_bulk | 32/– | 0/– | 1280/– | 1/– | 1/– | 20.6/– | over |
| G131 | norm_weight | 32/– | 0/– | 1280/– | 1/– | 1/– | 18.6/– | over |
| G324 | norm_bulk_squared | 32/– | 0/– | 512/– | 0/– | 0/– | 17.1/– | met |
| G325 | norm_weight_squared | 32/– | 0/– | 512/– | 0/– | 0/– | 15.9/– | met |
| G132 | norm | 64/– | 0/– | 3328/– | 4/– | 4/– | 26.8/– | over |
| G133 | normalize_bulk | 64/– | 1/– | 1024/– | 1/– | 1/– | 28.4/– | over |
| G134 | normalize_weight | 64/– | 1/– | 1024/– | 1/– | 1/– | 28.1/– | over |
| G135 | unitize | 64/– | 1/– | 1024/– | 1/– | 1/– | 28.0/– | over |
| G136 | attitude | 0/– | 0/– | 512/– | 0/– | 0/– | 12.9/– | met |
| G137 | select_grade | 0/– | 0/– | 776/– | 0/– | 0/– | 12.5/– | over |
| G138 | select_grade_anti | 0/– | 0/– | 776/– | 0/– | 1/– | 13.6/– | over |
| G139 | select_part | – | – | – | – | – | 0.9/– | met |
| G140 | bulk_flat | 0/– | 0/– | 512/– | 0/– | 0/– | 13.0/– | met |
| G141 | weight_flat | 0/– | 0/– | 512/– | 0/– | 0/– | 13.2/– | met |
| G142 | norm_bulk_flat | 32/– | 0/– | 1280/– | 1/– | 1/– | 19.3/– | over |
| G143 | norm_weight_flat | 32/– | 0/– | 1280/– | 1/– | 1/– | 18.8/– | over |
| G144 | carrier | 0/– | 0/– | 512/– | 0/– | 0/– | 12.4/– | met |
| G145 | carrier_co | 243/– | 0/– | 2048/– | 2/– | 2/– | 60.1/– | over |
| G146 | center | 486/– | 0/– | 3584/– | 4/– | 4/– | 168.8/– | over |
| G147 | container | 243/– | 0/– | 2560/– | 3/– | 3/– | 103.8/– | over |
| G148 | partner | 518/– | 0/– | 30720/– | 8/– | 271/– | 251.0/– | over |
| G149 | wedge_round_point_round_point | 243/20 | 0/0 | 768/160 | 0/0 | 0/0 | 99.2/4.0 | over |
| G150 | wedge_dipole_round_point | 243/30 | 0/0 | 768/200 | 0/0 | 0/0 | 98.3/6.1 | over |
| G151 | wedge_round_point_dipole | 243/30 | 0/0 | 768/200 | 0/0 | 0/0 | 96.5/6.1 | over |
| G152 | wedge_circle_round_point | 243/20 | 0/0 | 768/160 | 0/0 | 0/0 | 101.1/5.4 | over |
| G153 | wedge_round_point_circle | 243/20 | 0/0 | 768/160 | 0/0 | 0/0 | 101.6/5.9 | over |
| G154 | wedge_dipole_dipole | 243/30 | 0/0 | 768/200 | 0/0 | 0/0 | 101.2/8.6 | over |
| G155 | wedge_anti_sphere_sphere | 243/20 | 0/0 | 768/160 | 0/0 | 0/0 | 100.2/4.7 | over |
| G156 | wedge_anti_sphere_circle | 243/30 | 0/0 | 768/200 | 0/0 | 0/0 | 100.6/6.5 | over |
| G157 | wedge_anti_circle_sphere | 243/30 | 0/0 | 768/200 | 0/0 | 0/0 | 102.0/6.4 | over |
| G158 | wedge_anti_circle_circle | 243/30 | 0/0 | 768/200 | 0/0 | 0/0 | 97.3/8.8 | over |
| G159 | wedge_anti_sphere_dipole | 243/20 | 0/0 | 768/160 | 0/0 | 0/0 | 100.2/5.8 | over |
| G160 | wedge_anti_dipole_sphere | 243/20 | 0/0 | 768/160 | 0/0 | 0/0 | 100.6/5.4 | over |
| G161 | dot_round_point_round_point | 32/5 | 0/0 | 768/88 | 0/0 | 0/0 | 18.4/2.0 | over |
| G162 | dot_dipole_dipole | 32/10 | 0/0 | 768/168 | 0/0 | 0/0 | 18.3/3.9 | over |
| G163 | dot_circle_circle | 32/10 | 0/0 | 768/168 | 0/0 | 0/0 | 18.3/3.9 | over |
| G164 | dot_sphere_sphere | 32/5 | 0/0 | 768/88 | 0/0 | 0/0 | 18.3/2.0 | over |
| G165 | dot_anti_round_point_round_point | 32/5 | 0/0 | 768/88 | 0/0 | 0/0 | 17.6/2.2 | over |
| G166 | dot_anti_dipole_dipole | 32/10 | 0/0 | 768/168 | 0/0 | 0/0 | 17.8/4.0 | over |
| G167 | dot_anti_circle_circle | 32/10 | 0/0 | 768/168 | 0/0 | 0/0 | 17.9/4.0 | over |
| G168 | dot_anti_sphere_sphere | 32/5 | 0/0 | 768/88 | 0/0 | 0/0 | 17.7/2.2 | over |
| G169 | complement_right_round_point | 0/0 | 0/0 | 512/80 | 0/0 | 0/0 | 7.1/2.0 | over |
| G170 | complement_left_round_point | 0/0 | 0/0 | 512/80 | 0/0 | 0/0 | 7.2/2.0 | over |
| G171 | reverse_round_point | 0/0 | 0/0 | 512/120 | 0/0 | 0/0 | 9.9/1.8 | over |
| G172 | reverse_anti_round_point | 0/0 | 0/0 | 512/120 | 0/0 | 0/0 | 9.9/1.8 | over |
| G173 | dual_bulk_round_point | 0/0 | 0/0 | 512/80 | 0/0 | 0/0 | 12.6/2.0 | over |
| G174 | dual_weight_round_point | 0/0 | 0/0 | 512/80 | 0/0 | 0/0 | 11.5/2.0 | over |
| G175 | bulk_round_point | 0/0 | 0/0 | 512/120 | 0/0 | 0/0 | 12.9/2.2 | over |
| G176 | weight_round_point | 0/0 | 0/0 | 512/120 | 0/0 | 0/0 | 12.2/2.3 | over |
| G177 | bulk_flat_round_point | 0/0 | 0/0 | 512/120 | 0/0 | 0/0 | 13.0/1.0 | over |
| G178 | weight_flat_round_point | 0/0 | 0/0 | 512/80 | 0/0 | 0/0 | 13.1/0.8 | over |
| G179 | attitude_round_point | 0/0 | 0/0 | 512/48 | 0/0 | 0/0 | 12.9/0.6 | over |
| G180 | carrier_round_point | 0/0 | 0/0 | 512/72 | 0/0 | 0/0 | 12.4/0.9 | over |
| G181 | carrier_co_round_point | 243/0 | 0/0 | 2048/48 | 2/0 | 2/0 | 59.3/0.4 | over |
| G182 | center_round_point | 486/5 | 0/0 | 3584/120 | 4/0 | 4/0 | 159.8/1.9 | over |
| G183 | container_round_point | 243/8 | 0/0 | 2560/80 | 3/0 | 3/0 | 102.3/1.8 | over |
| G184 | partner_round_point | 518/10 | 0/0 | 30720/120 | 8/0 | 271/0 | 253.3/2.2 | over |
| G185 | complement_right_dipole | 0/0 | 0/0 | 512/160 | 0/0 | 0/0 | 7.1/2.3 | over |
| G186 | complement_left_dipole | 0/0 | 0/0 | 512/160 | 0/0 | 0/0 | 7.1/2.4 | over |
| G187 | reverse_dipole | 0/0 | 0/0 | 512/240 | 0/0 | 0/0 | 9.8/3.3 | over |
| G188 | reverse_anti_dipole | 0/0 | 0/0 | 512/240 | 0/0 | 0/0 | 9.9/3.3 | over |
| G189 | dual_bulk_dipole | 0/0 | 0/0 | 512/160 | 0/0 | 0/0 | 12.3/4.4 | over |
| G190 | dual_weight_dipole | 0/0 | 0/0 | 512/160 | 0/0 | 0/0 | 11.7/4.0 | over |
| G191 | bulk_dipole | 0/0 | 0/0 | 512/240 | 0/0 | 0/0 | 13.3/3.6 | over |
| G192 | weight_dipole | 0/0 | 0/0 | 512/240 | 0/0 | 0/0 | 12.2/4.7 | over |
| G193 | bulk_flat_dipole | 0/0 | 0/0 | 512/240 | 0/0 | 0/0 | 13.1/3.1 | over |
| G194 | weight_flat_dipole | 0/0 | 0/0 | 512/240 | 0/0 | 0/0 | 13.6/4.1 | over |
| G195 | attitude_dipole | 0/0 | 0/0 | 512/120 | 0/0 | 0/0 | 13.7/1.7 | over |
| G196 | carrier_dipole | 0/0 | 0/0 | 512/128 | 0/0 | 0/0 | 12.4/1.3 | over |
| G197 | carrier_co_dipole | 243/0 | 0/0 | 2048/112 | 2/0 | 2/0 | 60.5/1.1 | over |
| G198 | center_dipole | 486/16 | 0/0 | 3584/120 | 4/0 | 4/0 | 164.8/4.0 | over |
| G199 | container_dipole | 243/18 | 0/0 | 2560/120 | 3/0 | 3/0 | 103.9/4.6 | over |
| G200 | partner_dipole | 518/29 | 0/0 | 30720/240 | 8/0 | 271/0 | 257.2/5.7 | over |
| G201 | complement_right_circle | 0/0 | 0/0 | 512/160 | 0/0 | 0/0 | 7.0/2.5 | over |
| G202 | complement_left_circle | 0/0 | 0/0 | 512/160 | 0/0 | 0/0 | 7.0/2.5 | over |
| G203 | reverse_circle | 0/0 | 0/0 | 512/240 | 0/0 | 0/0 | 9.8/3.1 | over |
| G204 | reverse_anti_circle | 0/0 | 0/0 | 512/240 | 0/0 | 0/0 | 9.5/3.1 | over |
| G205 | dual_bulk_circle | 0/0 | 0/0 | 512/160 | 0/0 | 0/0 | 12.2/2.8 | over |
| G206 | dual_weight_circle | 0/0 | 0/0 | 512/160 | 0/0 | 0/0 | 11.4/2.7 | over |
| G207 | bulk_circle | 0/0 | 0/0 | 512/240 | 0/0 | 0/0 | 13.0/4.1 | over |
| G208 | weight_circle | 0/0 | 0/0 | 512/240 | 0/0 | 0/0 | 12.1/4.7 | over |
| G209 | bulk_flat_circle | 0/0 | 0/0 | 512/240 | 0/0 | 0/0 | 13.1/4.3 | over |
| G210 | weight_flat_circle | 0/0 | 0/0 | 512/240 | 0/0 | 0/0 | 13.2/3.3 | over |
| G211 | attitude_circle | 0/0 | 0/0 | 512/160 | 0/0 | 0/0 | 12.9/4.6 | over |
| G212 | carrier_circle | 0/0 | 0/0 | 512/112 | 0/0 | 0/0 | 12.4/1.0 | over |
| G213 | carrier_co_circle | 243/0 | 0/0 | 2048/128 | 2/0 | 2/0 | 60.0/2.5 | over |
| G214 | center_circle | 486/18 | 0/0 | 3584/120 | 4/0 | 4/0 | 159.6/4.6 | over |
| G215 | container_circle | 243/16 | 0/0 | 2560/120 | 3/0 | 3/0 | 102.9/3.2 | over |
| G216 | partner_circle | 518/29 | 0/0 | 30720/240 | 8/0 | 271/0 | 264.5/5.7 | over |
| G217 | complement_right_sphere | 0/0 | 0/0 | 512/80 | 0/0 | 0/0 | 7.0/1.1 | over |
| G218 | complement_left_sphere | 0/0 | 0/0 | 512/80 | 0/0 | 0/0 | 7.0/1.1 | over |
| G219 | reverse_sphere | 0/0 | 0/0 | 512/120 | 0/0 | 0/0 | 9.4/1.8 | over |
| G220 | reverse_anti_sphere | 0/0 | 0/0 | 512/120 | 0/0 | 0/0 | 9.5/1.8 | over |
| G221 | dual_bulk_sphere | 0/0 | 0/0 | 512/80 | 0/0 | 0/0 | 12.2/1.3 | over |
| G222 | dual_weight_sphere | 0/0 | 0/0 | 512/80 | 0/0 | 0/0 | 11.4/1.3 | over |
| G223 | bulk_sphere | 0/0 | 0/0 | 512/80 | 0/0 | 0/0 | 13.1/0.8 | over |
| G224 | weight_sphere | 0/0 | 0/0 | 512/120 | 0/0 | 0/0 | 12.2/2.4 | over |
| G225 | bulk_flat_sphere | 0/0 | 0/0 | 512/120 | 0/0 | 0/0 | 13.0/1.0 | over |
| G226 | weight_flat_sphere | 0/0 | 0/0 | 512/120 | 0/0 | 0/0 | 13.1/2.2 | over |
| G227 | attitude_sphere | 0/0 | 0/0 | 512/120 | 0/0 | 0/0 | 12.9/3.9 | over |
| G228 | carrier_sphere | 0/0 | 0/0 | 512/48 | 0/0 | 0/0 | 12.4/0.6 | over |
| G229 | carrier_co_sphere | 243/0 | 0/0 | 2048/72 | 2/0 | 2/0 | 60.2/1.0 | over |
| G230 | center_sphere | 486/8 | 0/0 | 3584/80 | 4/0 | 4/0 | 162.7/1.9 | over |
| G231 | container_sphere | 243/5 | 0/0 | 2560/120 | 3/0 | 3/0 | 102.9/2.2 | over |
| G232 | partner_sphere | 518/10 | 0/0 | 30720/120 | 8/0 | 271/0 | 259.6/2.1 | over |

### Multivector lower bound

| Op | Shape | Mul | Div | Roots | Bytes | Library mul/bytes |
|----|-------|-----|-----|-------|-------|-------------------|
| `∧` | Wedge | 243 | 0 | 0 | 768 | 243/768 |
| `∨` | Wedge | 243 | 0 | 0 | 768 | 243/768 |
| `⟑` | Geometric | 1024 | 0 | 0 | 768 | 1024/768 |
| `⟇` | Geometric | 1024 | 0 | 0 | 768 | 1024/768 |
| `∙` | FormScalar | 32 | 0 | 0 | 520 | 32/768 |
| `∘` | FormScalar | 32 | 0 | 0 | 520 | 32/768 |
| `∨★` | ContractBulk | 243 | 0 | 0 | 768 | 243/768 |
| `∨☆` | ContractWeight | 243 | 0 | 0 | 768 | 243/768 |
| `∧★` | ExpandBulk | 243 | 0 | 0 | 768 | 243/768 |
| `∧☆` | ExpandWeight | 243 | 0 | 0 | 768 | 243/768 |
| `+` | Componentwise | 0 | 0 | 0 | 768 | 0/768 |
| `-` | Componentwise | 0 | 0 | 0 | 768 | 0/768 |
| `projectCentral` | ExpandBulk + Wedge | 486 | 0 | 0 | 768 | 486/2304 |
| `projectCentralAnti` | ContractBulk + Wedge | 486 | 0 | 0 | 768 | 486/2304 |
| `projectOrthogonal` | ExpandWeight + Wedge | 486 | 0 | 0 | 768 | 486/2304 |
| `projectOrthogonalAnti` | ContractWeight + Wedge | 486 | 0 | 0 | 768 | 486/2304 |
| `∧` | Scale | 32 | 0 | 0 | 520 | 32/520 |
| `∙` | Permutation | 0 | 0 | 0 | 512 | 0/512 |
| `∘` | Permutation | 0 | 0 | 0 | 512 | 0/512 |
| `/` | Permutation | 0 | 0 | 0 | 512 | 0/512 |
| `\` | Permutation | 0 | 0 | 0 | 512 | 0/512 |
| `~` | Permutation | 0 | 0 | 0 | 512 | 0/512 |
| `~∘` | Permutation | 0 | 0 | 0 | 512 | 0/512 |
| `★` | Permutation | 0 | 0 | 0 | 512 | 0/512 |
| `☆` | Permutation | 0 | 0 | 0 | 512 | 0/512 |
| `-` | Permutation | 0 | 0 | 0 | 512 | 0/512 |
| `|∙` | Norm | 32 | 0 | 1 | 264 | 32/1280 |
| `|∘` | Norm | 32 | 0 | 1 | 264 | 32/1280 |
| `|∙²` | NormSquared | 32 | 0 | 0 | 264 | 32/512 |
| `|∘²` | NormSquared | 32 | 0 | 0 | 264 | 32/512 |
| `|` | 2 Norm | 64 | 0 | 2 | 264 | 64/3328 |
| `^∙` | Unitize | 64 | 1 | 1 | 512 | 64/1024 |
| `^∘` | Unitize | 64 | 1 | 1 | 512 | 64/1024 |
| `^` | Unitize | 64 | 1 | 1 | 512 | 64/1024 |
| `⊖` | ProductConstant | 0 | 0 | 0 | 512 | 0/512 |
| `{}` | Permutation | 0 | 0 | 0 | 512 | 0/776 |
| `{}` | Permutation | 0 | 0 | 0 | 512 | 0/776 |
| `■` | Permutation | 0 | 0 | 0 | 512 | 0/512 |
| `□` | Permutation | 0 | 0 | 0 | 512 | 0/512 |
| `|■` | Norm | 32 | 0 | 1 | 264 | 32/1280 |
| `|□` | Norm | 32 | 0 | 1 | 264 | 32/1280 |
| `⊟` | ProductConstant | 0 | 0 | 0 | 512 | 0/512 |
| `⊞` | ProductConstant | 0 | 0 | 0 | 512 | 243/2048 |
| `⊙` | Center | 162 | 0 | 0 | 512 | 486/3584 |
| `⊡` | Container | 162 | 0 | 0 | 512 | 243/2560 |
| `⊛` | Permutation + Container + JoinCarrier | 324 | 0 | 0 | 512 | 518/30720 |

## rga3d

This algebra has 3 dimensions, a rigid metric and a 64-byte multivector. The inspector took the
counts on 2026-10-09, on linux amd64, 4 cores, with nim `27763495bcfe265507ca98aedc1c7064bf1e0e4d`,
pga `e993419c1f90efba72848d146606f903e1cc141e` and flags `-d:release`. The bench ran 5 times on
2026-10-03, on linux amd64, 4 cores, over 40 rounds of 1024 objects each. Each time is the median of
those runs. It ran at pga `d9be8aefc193f6ee0a7a3fead25cd4fe1d8f09cf`, which emits the same C as the
pin. The allocation gauge was live.
Gaps: 88. Over 62, met 26, unmeasured 0.

| Id | Measurand | Mul | Div | Bytes | Int | Chk | ns | Status |
|----|-----------|-----|-----|-------|-----|-----|----|--------|
| G233 | wedge | 27/– | 0/– | 192/– | 0/– | 0/– | 7.2/– | met |
| G234 | wedge_anti | 27/– | 0/– | 192/– | 0/– | 0/– | 7.3/– | met |
| G235 | wedge_dot | 48/– | 0/– | 192/– | 0/– | 0/– | 13.1/– | met |
| G236 | wedge_dot_anti | 48/– | 0/– | 192/– | 0/– | 0/– | 13.0/– | met |
| G237 | dot | 4/– | 0/– | 192/– | 0/– | 0/– | 2.4/– | met |
| G238 | dot_anti | 4/– | 0/– | 192/– | 0/– | 0/– | 2.2/– | met |
| G239 | contract_bulk | 18/– | 0/– | 192/– | 0/– | 0/– | 4.4/– | met |
| G240 | contract_weight | 9/– | 0/– | 192/– | 0/– | 0/– | 3.6/– | met |
| G241 | expand_bulk | 9/– | 0/– | 192/– | 0/– | 0/– | 3.2/– | met |
| G242 | expand_weight | 18/– | 0/– | 192/– | 0/– | 0/– | 4.6/– | met |
| G243 | add | 0/– | 0/– | 192/– | 0/– | 0/– | 2.1/– | met |
| G244 | subtract | 0/– | 0/– | 192/– | 0/– | 0/– | 2.3/– | met |
| G245 | project_central | 36/– | 0/– | 576/– | 2/– | 2/– | 10.2/– | over |
| G246 | project_central_anti | 45/– | 0/– | 576/– | 2/– | 2/– | 11.2/– | over |
| G247 | project_orthogonal | 45/– | 0/– | 576/– | 2/– | 2/– | 12.6/– | over |
| G248 | project_orthogonal_anti | 36/– | 0/– | 576/– | 2/– | 2/– | 8.5/– | over |
| G249 | scale | 8/– | 0/– | 136/– | 0/– | 0/– | 2.0/– | met |
| G250 | bulk | 0/– | 0/– | 128/– | 0/– | 0/– | 1.5/– | met |
| G251 | weight | 0/– | 0/– | 128/– | 0/– | 0/– | 1.5/– | met |
| G252 | complement_right | 0/– | 0/– | 128/– | 0/– | 0/– | 2.4/– | met |
| G253 | complement_left | 0/– | 0/– | 128/– | 0/– | 0/– | 2.4/– | met |
| G254 | reverse | 0/– | 0/– | 128/– | 0/– | 0/– | 1.4/– | met |
| G255 | reverse_anti | 0/– | 0/– | 128/– | 0/– | 0/– | 1.4/– | met |
| G256 | dual_bulk | 0/– | 0/– | 128/– | 0/– | 0/– | 1.5/– | met |
| G257 | dual_weight | 0/– | 0/– | 128/– | 0/– | 0/– | 1.5/– | met |
| G258 | negate | 0/– | 0/– | 128/– | 0/– | 0/– | 1.4/– | met |
| G259 | norm_bulk | 4/– | 0/– | 320/– | 1/– | 1/– | 1.8/– | over |
| G260 | norm_weight | 4/– | 0/– | 320/– | 1/– | 1/– | 1.8/– | over |
| G326 | norm_bulk_squared | 4/– | 0/– | 128/– | 0/– | 0/– | 1.9/– | met |
| G327 | norm_weight_squared | 4/– | 0/– | 128/– | 0/– | 0/– | 1.5/– | met |
| G261 | norm | 8/– | 0/– | 832/– | 4/– | 4/– | 3.6/– | over |
| G262 | normalize_bulk | 12/– | 1/– | 256/– | 1/– | 1/– | 3.5/– | over |
| G263 | normalize_weight | 12/– | 1/– | 256/– | 1/– | 1/– | 3.5/– | over |
| G264 | unitize | 12/– | 1/– | 256/– | 1/– | 1/– | 3.5/– | over |
| G265 | attitude | 0/– | 0/– | 128/– | 0/– | 0/– | 1.5/– | met |
| G266 | select_grade | 0/– | 0/– | 200/– | 0/– | 0/– | 3.5/– | over |
| G267 | select_grade_anti | 0/– | 0/– | 200/– | 0/– | 1/– | 3.6/– | over |
| G268 | select_part | – | – | – | – | – | 0.5/– | met |
| G269 | support | 54/– | 0/– | 640/– | 3/– | 3/– | 10.9/– | over |
| G270 | support_anti | 54/– | 0/– | 640/– | 3/– | 3/– | 10.1/– | over |
| G330 | wedge_point_point | 27/6 | 0/0 | 192/72 | 0/0 | 0/0 | 7.6/1.9 | over |
| G331 | wedge_point_line | 27/3 | 0/0 | 192/56 | 0/0 | 0/0 | 7.6/1.8 | over |
| G332 | wedge_line_point | 27/3 | 0/0 | 192/56 | 0/0 | 0/0 | 7.7/1.8 | over |
| G333 | wedge_anti_line_line | 27/6 | 0/0 | 192/72 | 0/0 | 0/0 | 7.3/1.9 | over |
| G334 | wedge_anti_point_line | 27/3 | 0/0 | 192/56 | 0/0 | 0/0 | 7.4/1.8 | over |
| G335 | wedge_anti_line_point | 27/3 | 0/0 | 192/56 | 0/0 | 0/0 | 7.3/1.8 | over |
| G336 | dot_point_point | 4/2 | 0/0 | 192/56 | 0/0 | 0/0 | 2.3/1.5 | over |
| G337 | dot_line_line | 4/1 | 0/0 | 192/56 | 0/0 | 0/0 | 2.3/1.2 | over |
| G338 | dot_anti_point_point | 4/1 | 0/0 | 192/56 | 0/0 | 0/0 | 2.2/1.1 | over |
| G339 | dot_anti_line_line | 4/2 | 0/0 | 192/56 | 0/0 | 0/0 | 2.2/1.3 | over |
| G340 | wedge_dot_anti_motor_motor | 48/12 | 0/0 | 192/128 | 0/0 | 0/0 | 13.1/3.3 | over |
| G341 | transform_point_motor | –/15 | –/0 | –/80 | –/0 | –/0 | 26.6/3.7 | over |
| G342 | transform_line_motor | –/15 | –/0 | –/80 | –/0 | –/0 | 26.5/3.8 | over |
| G343 | project_orthogonal_point_line | 45/10 | 0/0 | 576/72 | 2/0 | 2/0 | 12.7/2.9 | over |
| G344 | support_line | 54/4 | 0/0 | 640/48 | 3/0 | 3/0 | 10.9/0.9 | over |
| G345 | support_anti_point | 54/4 | 0/0 | 640/48 | 3/0 | 3/0 | 10.1/0.9 | over |
| G346 | reverse_anti_motor | 0/0 | 0/0 | 128/96 | 0/0 | 0/0 | 1.4/1.0 | over |
| G347 | unitize_motor | 12/6 | 1/1 | 256/128 | 1/0 | 1/0 | 3.4/2.7 | over |
| G348 | norm_weight_motor | 4/2 | 0/0 | 320/40 | 1/0 | 1/0 | 1.7/1.5 | over |
| G349 | norm_bulk_motor | 4/2 | 0/0 | 320/40 | 1/0 | 1/0 | 1.8/1.8 | over |
| G350 | complement_right_point | 0/0 | 0/0 | 128/48 | 0/0 | 0/0 | 2.4/0.7 | over |
| G351 | complement_left_point | 0/0 | 0/0 | 128/48 | 0/0 | 0/0 | 2.4/0.7 | over |
| G352 | reverse_point | 0/0 | 0/0 | 128/48 | 0/0 | 0/0 | 1.4/0.8 | over |
| G353 | reverse_anti_point | 0/0 | 0/0 | 128/48 | 0/0 | 0/0 | 1.4/0.7 | over |
| G354 | dual_bulk_point | 0/0 | 0/0 | 128/48 | 0/0 | 0/0 | 1.5/0.8 | over |
| G355 | dual_weight_point | 0/0 | 0/0 | 128/48 | 0/0 | 0/0 | 1.5/0.7 | over |
| G356 | bulk_point | 0/0 | 0/0 | 128/48 | 0/0 | 0/0 | 1.5/0.8 | over |
| G357 | weight_point | 0/0 | 0/0 | 128/48 | 0/0 | 0/0 | 1.5/0.6 | over |
| G358 | norm_bulk_point | 4/2 | 0/0 | 320/32 | 1/0 | 1/0 | 1.8/1.8 | over |
| G359 | norm_weight_point | 4/0 | 0/0 | 320/32 | 1/0 | 1/0 | 1.8/0.5 | over |
| G360 | norm_bulk_squared_point | 4/2 | 0/0 | 128/32 | 0/0 | 0/0 | 1.9/0.6 | over |
| G361 | norm_weight_squared_point | 4/– | 0/– | 128/– | 0/– | 0/– | 1.5/0.6 | over |
| G362 | unitize_point | 12/2 | 1/1 | 256/48 | 1/0 | 1/0 | 3.5/1.2 | over |
| G363 | attitude_point | 0/0 | 0/0 | 128/32 | 0/0 | 0/0 | 1.5/0.4 | over |
| G364 | complement_right_line | 0/0 | 0/0 | 128/48 | 0/0 | 0/0 | 2.4/0.7 | over |
| G365 | complement_left_line | 0/0 | 0/0 | 128/48 | 0/0 | 0/0 | 2.4/0.7 | over |
| G366 | reverse_line | 0/0 | 0/0 | 128/48 | 0/0 | 0/0 | 1.4/0.7 | over |
| G367 | reverse_anti_line | 0/0 | 0/0 | 128/48 | 0/0 | 0/0 | 1.4/0.8 | over |
| G368 | dual_bulk_line | 0/0 | 0/0 | 128/48 | 0/0 | 0/0 | 1.5/0.7 | over |
| G369 | dual_weight_line | 0/0 | 0/0 | 128/48 | 0/0 | 0/0 | 1.5/0.8 | over |
| G370 | bulk_line | 0/0 | 0/0 | 128/48 | 0/0 | 0/0 | 1.5/0.7 | over |
| G371 | weight_line | 0/0 | 0/0 | 128/48 | 0/0 | 0/0 | 1.5/0.8 | over |
| G372 | norm_bulk_line | 4/0 | 0/0 | 320/32 | 1/0 | 1/0 | 1.8/0.5 | over |
| G373 | norm_weight_line | 4/2 | 0/0 | 320/32 | 1/0 | 1/0 | 1.8/1.8 | over |
| G374 | norm_bulk_squared_line | 4/1 | 0/0 | 128/32 | 0/0 | 0/0 | 1.9/0.6 | over |
| G375 | norm_weight_squared_line | 4/– | 0/– | 128/– | 0/– | 0/– | 1.5/0.6 | over |
| G376 | unitize_line | 12/5 | 1/1 | 256/48 | 1/0 | 1/0 | 3.5/3.0 | over |
| G377 | attitude_line | 0/0 | 0/0 | 128/48 | 0/0 | 0/0 | 1.5/0.8 | over |

### Multivector lower bound

| Op | Shape | Mul | Div | Roots | Bytes | Library mul/bytes |
|----|-------|-----|-----|-------|-------|-------------------|
| `∧` | Wedge | 27 | 0 | 0 | 192 | 27/192 |
| `∨` | Wedge | 27 | 0 | 0 | 192 | 27/192 |
| `⟑` | Geometric | 48 | 0 | 0 | 192 | 48/192 |
| `⟇` | Geometric | 48 | 0 | 0 | 192 | 48/192 |
| `∙` | FormScalar | 4 | 0 | 0 | 136 | 4/192 |
| `∘` | FormScalar | 4 | 0 | 0 | 136 | 4/192 |
| `∨★` | ContractBulk | 18 | 0 | 0 | 192 | 18/192 |
| `∨☆` | ContractWeight | 9 | 0 | 0 | 192 | 9/192 |
| `∧★` | ExpandBulk | 9 | 0 | 0 | 192 | 9/192 |
| `∧☆` | ExpandWeight | 18 | 0 | 0 | 192 | 18/192 |
| `+` | Componentwise | 0 | 0 | 0 | 192 | 0/192 |
| `-` | Componentwise | 0 | 0 | 0 | 192 | 0/192 |
| `projectCentral` | ExpandBulk + Wedge | 36 | 0 | 0 | 192 | 36/576 |
| `projectCentralAnti` | ContractBulk + Wedge | 45 | 0 | 0 | 192 | 45/576 |
| `projectOrthogonal` | ExpandWeight + Wedge | 45 | 0 | 0 | 192 | 45/576 |
| `projectOrthogonalAnti` | ContractWeight + Wedge | 36 | 0 | 0 | 192 | 36/576 |
| `∧` | Scale | 8 | 0 | 0 | 136 | 8/136 |
| `∙` | Permutation | 0 | 0 | 0 | 128 | 0/128 |
| `∘` | Permutation | 0 | 0 | 0 | 128 | 0/128 |
| `/` | Permutation | 0 | 0 | 0 | 128 | 0/128 |
| `\` | Permutation | 0 | 0 | 0 | 128 | 0/128 |
| `~` | Permutation | 0 | 0 | 0 | 128 | 0/128 |
| `~∘` | Permutation | 0 | 0 | 0 | 128 | 0/128 |
| `★` | Permutation | 0 | 0 | 0 | 128 | 0/128 |
| `☆` | Permutation | 0 | 0 | 0 | 128 | 0/128 |
| `-` | Permutation | 0 | 0 | 0 | 128 | 0/128 |
| `|∙` | Norm | 4 | 0 | 1 | 72 | 4/320 |
| `|∘` | Norm | 4 | 0 | 1 | 72 | 4/320 |
| `|∙²` | NormSquared | 4 | 0 | 0 | 72 | 4/128 |
| `|∘²` | NormSquared | 4 | 0 | 0 | 72 | 4/128 |
| `|` | 2 Norm | 8 | 0 | 2 | 72 | 8/832 |
| `^∙` | Unitize | 12 | 1 | 1 | 128 | 12/256 |
| `^∘` | Unitize | 12 | 1 | 1 | 128 | 12/256 |
| `^` | Unitize | 12 | 1 | 1 | 128 | 12/256 |
| `⊖` | ProductConstant | 0 | 0 | 0 | 128 | 0/128 |
| `{}` | Permutation | 0 | 0 | 0 | 128 | 0/200 |
| `{}` | Permutation | 0 | 0 | 0 | 128 | 0/200 |
| `∩` | Support | 18 | 0 | 0 | 128 | 54/640 |
| `∪` | SupportAnti | 18 | 0 | 0 | 128 | 54/640 |
| `((n ⟇ m) ⟇ (~∘ n))` | Permutation + 2 Geometric | 96 | 0 | 0 | 192 | – |

## cga4d

This algebra has 4 dimensions, a conformal metric and a 128-byte multivector. The inspector took the
counts on 2026-10-09, on linux amd64, 4 cores, with nim `27763495bcfe265507ca98aedc1c7064bf1e0e4d`,
pga `e993419c1f90efba72848d146606f903e1cc141e` and flags `-d:release`. The bench ran 5 times on
2026-10-03, on linux amd64, 4 cores, over 40 rounds of 1024 objects each. Each time is the median of
those runs. It ran at pga `d9be8aefc193f6ee0a7a3fead25cd4fe1d8f09cf`, which emits the same C as the
pin. The allocation gauge was live.
Gaps: 113. Over 84, met 29, unmeasured 0.

| Id | Measurand | Mul | Div | Bytes | Int | Chk | ns | Status |
|----|-----------|-----|-----|-------|-----|-----|----|--------|
| G271 | wedge | 81/– | 0/– | 384/– | 0/– | 0/– | 28.7/– | met |
| G272 | wedge_anti | 81/– | 0/– | 384/– | 0/– | 0/– | 28.1/– | met |
| G273 | wedge_dot | 256/– | 0/– | 384/– | 0/– | 0/– | 89.4/– | met |
| G274 | wedge_dot_anti | 256/– | 0/– | 384/– | 0/– | 0/– | 92.2/– | met |
| G275 | dot | 16/– | 0/– | 384/– | 0/– | 0/– | 7.2/– | met |
| G276 | dot_anti | 16/– | 0/– | 384/– | 0/– | 0/– | 7.2/– | met |
| G277 | contract_bulk | 81/– | 0/– | 384/– | 0/– | 0/– | 28.0/– | met |
| G278 | contract_weight | 81/– | 0/– | 384/– | 0/– | 0/– | 29.0/– | met |
| G279 | expand_bulk | 81/– | 0/– | 384/– | 0/– | 0/– | 28.9/– | met |
| G280 | expand_weight | 81/– | 0/– | 384/– | 0/– | 0/– | 28.6/– | met |
| G281 | add | 0/– | 0/– | 384/– | 0/– | 0/– | 4.7/– | met |
| G282 | subtract | 0/– | 0/– | 384/– | 0/– | 0/– | 4.9/– | met |
| G283 | project_central | 162/– | 0/– | 1152/– | 2/– | 2/– | 62.9/– | over |
| G284 | project_central_anti | 162/– | 0/– | 1152/– | 2/– | 2/– | 62.9/– | over |
| G285 | project_orthogonal | 162/– | 0/– | 1152/– | 2/– | 2/– | 64.5/– | over |
| G286 | project_orthogonal_anti | 162/– | 0/– | 1152/– | 2/– | 2/– | 62.9/– | over |
| G287 | scale | 16/– | 0/– | 264/– | 0/– | 0/– | 5.6/– | met |
| G288 | bulk | 0/– | 0/– | 256/– | 0/– | 0/– | 6.4/– | met |
| G289 | weight | 0/– | 0/– | 256/– | 0/– | 0/– | 3.6/– | met |
| G290 | complement_right | 0/– | 0/– | 256/– | 0/– | 0/– | 4.1/– | met |
| G291 | complement_left | 0/– | 0/– | 256/– | 0/– | 0/– | 6.1/– | met |
| G292 | reverse | 0/– | 0/– | 256/– | 0/– | 0/– | 6.3/– | met |
| G293 | reverse_anti | 0/– | 0/– | 256/– | 0/– | 0/– | 4.0/– | met |
| G294 | dual_bulk | 0/– | 0/– | 256/– | 0/– | 0/– | 4.2/– | met |
| G295 | dual_weight | 0/– | 0/– | 256/– | 0/– | 0/– | 4.3/– | met |
| G296 | negate | 0/– | 0/– | 256/– | 0/– | 0/– | 2.8/– | met |
| G297 | norm_bulk | 16/– | 0/– | 640/– | 1/– | 1/– | 12.4/– | over |
| G298 | norm_weight | 16/– | 0/– | 640/– | 1/– | 1/– | 12.1/– | over |
| G328 | norm_bulk_squared | 16/– | 0/– | 256/– | 0/– | 0/– | 6.1/– | met |
| G329 | norm_weight_squared | 16/– | 0/– | 256/– | 0/– | 0/– | 5.5/– | met |
| G299 | norm | 32/– | 0/– | 1664/– | 4/– | 4/– | 14.0/– | over |
| G300 | normalize_bulk | 32/– | 1/– | 512/– | 1/– | 1/– | 10.5/– | over |
| G301 | normalize_weight | 32/– | 1/– | 512/– | 1/– | 1/– | 11.2/– | over |
| G302 | unitize | 32/– | 1/– | 512/– | 1/– | 1/– | 11.3/– | over |
| G303 | attitude | 0/– | 0/– | 256/– | 0/– | 0/– | 6.2/– | met |
| G304 | select_grade | 0/– | 0/– | 392/– | 0/– | 0/– | 12.5/– | over |
| G305 | select_grade_anti | 0/– | 0/– | 392/– | 0/– | 1/– | 14.0/– | over |
| G306 | select_part | – | – | – | – | – | 0.7/– | met |
| G307 | bulk_flat | 0/– | 0/– | 256/– | 0/– | 0/– | 6.3/– | met |
| G308 | weight_flat | 0/– | 0/– | 256/– | 0/– | 0/– | 6.0/– | met |
| G309 | norm_bulk_flat | 16/– | 0/– | 640/– | 1/– | 1/– | 12.4/– | over |
| G310 | norm_weight_flat | 16/– | 0/– | 640/– | 1/– | 1/– | 12.5/– | over |
| G311 | carrier | 0/– | 0/– | 256/– | 0/– | 0/– | 5.2/– | met |
| G312 | carrier_co | 81/– | 0/– | 1024/– | 2/– | 2/– | 22.4/– | over |
| G313 | center | 162/– | 0/– | 1792/– | 4/– | 4/– | 70.9/– | over |
| G314 | container | 81/– | 0/– | 1280/– | 3/– | 3/– | 39.0/– | over |
| G315 | partner | 178/– | 0/– | 9216/– | 8/– | 143/– | 102.0/– | over |
| G378 | wedge_round_point_round_point | 81/12 | 0/0 | 384/112 | 0/0 | 0/0 | 29.4/3.2 | over |
| G379 | wedge_dipole_round_point | 81/12 | 0/0 | 384/112 | 0/0 | 0/0 | 28.4/3.8 | over |
| G380 | wedge_round_point_dipole | 81/12 | 0/0 | 384/112 | 0/0 | 0/0 | 28.2/4.1 | over |
| G381 | wedge_circle_round_point | 81/4 | 0/0 | 384/72 | 0/0 | 0/0 | 28.4/2.1 | over |
| G382 | wedge_round_point_circle | 81/4 | 0/0 | 384/72 | 0/0 | 0/0 | 29.0/2.0 | over |
| G383 | wedge_dipole_dipole | 81/6 | 0/0 | 384/104 | 0/0 | 0/0 | 29.5/2.6 | over |
| G384 | wedge_anti_circle_circle | 81/12 | 0/0 | 384/112 | 0/0 | 0/0 | 28.3/3.3 | over |
| G385 | wedge_anti_circle_dipole | 81/12 | 0/0 | 384/112 | 0/0 | 0/0 | 27.9/4.2 | over |
| G386 | wedge_anti_dipole_circle | 81/12 | 0/0 | 384/112 | 0/0 | 0/0 | 29.8/4.0 | over |
| G387 | wedge_anti_dipole_dipole | 81/6 | 0/0 | 384/104 | 0/0 | 0/0 | 24.8/2.6 | over |
| G388 | wedge_anti_circle_round_point | 81/4 | 0/0 | 384/72 | 0/0 | 0/0 | 24.9/2.1 | over |
| G389 | wedge_anti_round_point_circle | 81/4 | 0/0 | 384/72 | 0/0 | 0/0 | 25.2/2.0 | over |
| G390 | dot_round_point_round_point | 16/4 | 0/0 | 384/72 | 0/0 | 0/0 | 7.1/1.9 | over |
| G391 | dot_dipole_dipole | 16/6 | 0/0 | 384/104 | 0/0 | 0/0 | 7.1/2.3 | over |
| G392 | dot_circle_circle | 16/4 | 0/0 | 384/72 | 0/0 | 0/0 | 7.2/1.9 | over |
| G393 | dot_anti_round_point_round_point | 16/4 | 0/0 | 384/72 | 0/0 | 0/0 | 7.1/1.9 | over |
| G394 | dot_anti_dipole_dipole | 16/6 | 0/0 | 384/104 | 0/0 | 0/0 | 7.2/2.3 | over |
| G395 | dot_anti_circle_circle | 16/4 | 0/0 | 384/72 | 0/0 | 0/0 | 7.2/1.9 | over |
| G396 | complement_right_round_point | 0/0 | 0/0 | 256/64 | 0/0 | 0/0 | 4.1/1.1 | over |
| G397 | complement_left_round_point | 0/0 | 0/0 | 256/64 | 0/0 | 0/0 | 6.1/1.1 | over |
| G398 | reverse_round_point | 0/0 | 0/0 | 256/96 | 0/0 | 0/0 | 6.3/0.7 | over |
| G399 | reverse_anti_round_point | 0/0 | 0/0 | 256/96 | 0/0 | 0/0 | 4.0/0.7 | over |
| G400 | dual_bulk_round_point | 0/0 | 0/0 | 256/64 | 0/0 | 0/0 | 4.2/1.1 | over |
| G401 | dual_weight_round_point | 0/0 | 0/0 | 256/64 | 0/0 | 0/0 | 4.3/1.1 | over |
| G402 | bulk_round_point | 0/0 | 0/0 | 256/96 | 0/0 | 0/0 | 6.4/0.7 | over |
| G403 | weight_round_point | 0/0 | 0/0 | 256/96 | 0/0 | 0/0 | 3.6/0.8 | over |
| G404 | bulk_flat_round_point | 0/0 | 0/0 | 256/96 | 0/0 | 0/0 | 6.2/0.8 | over |
| G405 | weight_flat_round_point | 0/0 | 0/0 | 256/64 | 0/0 | 0/0 | 6.0/0.3 | over |
| G406 | attitude_round_point | 0/0 | 0/0 | 256/40 | 0/0 | 0/0 | 6.2/0.6 | over |
| G407 | carrier_round_point | 0/0 | 0/0 | 256/56 | 0/0 | 0/0 | 5.2/0.7 | over |
| G408 | carrier_co_round_point | 81/0 | 0/0 | 1024/40 | 2/0 | 2/0 | 22.4/0.5 | over |
| G409 | center_round_point | 162/4 | 0/0 | 1792/96 | 4/0 | 4/0 | 69.3/1.4 | over |
| G410 | container_round_point | 81/6 | 0/0 | 1280/64 | 3/0 | 3/0 | 38.9/1.4 | over |
| G411 | partner_round_point | 178/8 | 0/0 | 9216/96 | 8/0 | 143/0 | 102.7/1.5 | over |
| G412 | complement_right_dipole | 0/0 | 0/0 | 256/144 | 0/0 | 0/0 | 4.1/1.6 | over |
| G413 | complement_left_dipole | 0/0 | 0/0 | 256/144 | 0/0 | 0/0 | 6.1/1.6 | over |
| G414 | reverse_dipole | 0/0 | 0/0 | 256/144 | 0/0 | 0/0 | 6.3/1.9 | over |
| G415 | reverse_anti_dipole | 0/0 | 0/0 | 256/144 | 0/0 | 0/0 | 4.0/1.9 | over |
| G416 | dual_bulk_dipole | 0/0 | 0/0 | 256/144 | 0/0 | 0/0 | 4.2/2.4 | over |
| G417 | dual_weight_dipole | 0/0 | 0/0 | 256/144 | 0/0 | 0/0 | 4.3/2.0 | over |
| G418 | bulk_dipole | 0/0 | 0/0 | 256/144 | 0/0 | 0/0 | 6.4/2.4 | over |
| G419 | weight_dipole | 0/0 | 0/0 | 256/144 | 0/0 | 0/0 | 3.6/2.3 | over |
| G420 | bulk_flat_dipole | 0/0 | 0/0 | 256/144 | 0/0 | 0/0 | 6.3/2.5 | over |
| G421 | weight_flat_dipole | 0/0 | 0/0 | 256/144 | 0/0 | 0/0 | 6.0/2.4 | over |
| G422 | attitude_dipole | 0/0 | 0/0 | 256/80 | 0/0 | 0/0 | 6.2/1.0 | over |
| G423 | carrier_dipole | 0/0 | 0/0 | 256/72 | 0/0 | 0/0 | 5.4/1.4 | over |
| G424 | carrier_co_dipole | 81/0 | 0/0 | 1024/72 | 2/0 | 2/0 | 22.5/1.4 | over |
| G425 | center_dipole | 162/9 | 0/0 | 1792/80 | 4/0 | 4/0 | 69.9/2.1 | over |
| G426 | container_dipole | 81/9 | 0/0 | 1280/80 | 3/0 | 3/0 | 39.0/2.1 | over |
| G427 | partner_dipole | 178/15 | 0/0 | 9216/144 | 8/0 | 143/0 | 104.1/2.9 | over |
| G428 | complement_right_circle | 0/0 | 0/0 | 256/64 | 0/0 | 0/0 | 4.1/1.1 | over |
| G429 | complement_left_circle | 0/0 | 0/0 | 256/64 | 0/0 | 0/0 | 6.1/1.1 | over |
| G430 | reverse_circle | 0/0 | 0/0 | 256/96 | 0/0 | 0/0 | 6.3/0.7 | over |
| G431 | reverse_anti_circle | 0/0 | 0/0 | 256/96 | 0/0 | 0/0 | 4.0/0.7 | over |
| G432 | dual_bulk_circle | 0/0 | 0/0 | 256/64 | 0/0 | 0/0 | 4.2/1.0 | over |
| G433 | dual_weight_circle | 0/0 | 0/0 | 256/64 | 0/0 | 0/0 | 4.3/1.0 | over |
| G434 | bulk_circle | 0/0 | 0/0 | 256/64 | 0/0 | 0/0 | 6.4/0.3 | over |
| G435 | weight_circle | 0/0 | 0/0 | 256/96 | 0/0 | 0/0 | 3.6/0.9 | over |
| G436 | bulk_flat_circle | 0/0 | 0/0 | 256/96 | 0/0 | 0/0 | 6.3/0.8 | over |
| G437 | weight_flat_circle | 0/0 | 0/0 | 256/96 | 0/0 | 0/0 | 6.0/0.9 | over |
| G438 | attitude_circle | 0/0 | 0/0 | 256/80 | 0/0 | 0/0 | 6.2/1.1 | over |
| G439 | carrier_circle | 0/0 | 0/0 | 256/40 | 0/0 | 0/0 | 5.2/0.5 | over |
| G440 | carrier_co_circle | 81/0 | 0/0 | 1024/56 | 2/0 | 2/0 | 22.4/0.7 | over |
| G441 | center_circle | 162/6 | 0/0 | 1792/64 | 4/0 | 4/0 | 69.2/1.4 | over |
| G442 | container_circle | 81/4 | 0/0 | 1280/96 | 3/0 | 3/0 | 38.9/1.0 | over |
| G443 | partner_circle | 178/8 | 0/0 | 9216/96 | 8/0 | 143/0 | 107.6/1.4 | over |

### Multivector lower bound

| Op | Shape | Mul | Div | Roots | Bytes | Library mul/bytes |
|----|-------|-----|-----|-------|-------|-------------------|
| `∧` | Wedge | 81 | 0 | 0 | 384 | 81/384 |
| `∨` | Wedge | 81 | 0 | 0 | 384 | 81/384 |
| `⟑` | Geometric | 256 | 0 | 0 | 384 | 256/384 |
| `⟇` | Geometric | 256 | 0 | 0 | 384 | 256/384 |
| `∙` | FormScalar | 16 | 0 | 0 | 264 | 16/384 |
| `∘` | FormScalar | 16 | 0 | 0 | 264 | 16/384 |
| `∨★` | ContractBulk | 81 | 0 | 0 | 384 | 81/384 |
| `∨☆` | ContractWeight | 81 | 0 | 0 | 384 | 81/384 |
| `∧★` | ExpandBulk | 81 | 0 | 0 | 384 | 81/384 |
| `∧☆` | ExpandWeight | 81 | 0 | 0 | 384 | 81/384 |
| `+` | Componentwise | 0 | 0 | 0 | 384 | 0/384 |
| `-` | Componentwise | 0 | 0 | 0 | 384 | 0/384 |
| `projectCentral` | ExpandBulk + Wedge | 162 | 0 | 0 | 384 | 162/1152 |
| `projectCentralAnti` | ContractBulk + Wedge | 162 | 0 | 0 | 384 | 162/1152 |
| `projectOrthogonal` | ExpandWeight + Wedge | 162 | 0 | 0 | 384 | 162/1152 |
| `projectOrthogonalAnti` | ContractWeight + Wedge | 162 | 0 | 0 | 384 | 162/1152 |
| `∧` | Scale | 16 | 0 | 0 | 264 | 16/264 |
| `∙` | Permutation | 0 | 0 | 0 | 256 | 0/256 |
| `∘` | Permutation | 0 | 0 | 0 | 256 | 0/256 |
| `/` | Permutation | 0 | 0 | 0 | 256 | 0/256 |
| `\` | Permutation | 0 | 0 | 0 | 256 | 0/256 |
| `~` | Permutation | 0 | 0 | 0 | 256 | 0/256 |
| `~∘` | Permutation | 0 | 0 | 0 | 256 | 0/256 |
| `★` | Permutation | 0 | 0 | 0 | 256 | 0/256 |
| `☆` | Permutation | 0 | 0 | 0 | 256 | 0/256 |
| `-` | Permutation | 0 | 0 | 0 | 256 | 0/256 |
| `|∙` | Norm | 16 | 0 | 1 | 136 | 16/640 |
| `|∘` | Norm | 16 | 0 | 1 | 136 | 16/640 |
| `|∙²` | NormSquared | 16 | 0 | 0 | 136 | 16/256 |
| `|∘²` | NormSquared | 16 | 0 | 0 | 136 | 16/256 |
| `|` | 2 Norm | 32 | 0 | 2 | 136 | 32/1664 |
| `^∙` | Unitize | 32 | 1 | 1 | 256 | 32/512 |
| `^∘` | Unitize | 32 | 1 | 1 | 256 | 32/512 |
| `^` | Unitize | 32 | 1 | 1 | 256 | 32/512 |
| `⊖` | ProductConstant | 0 | 0 | 0 | 256 | 0/256 |
| `{}` | Permutation | 0 | 0 | 0 | 256 | 0/392 |
| `{}` | Permutation | 0 | 0 | 0 | 256 | 0/392 |
| `■` | Permutation | 0 | 0 | 0 | 256 | 0/256 |
| `□` | Permutation | 0 | 0 | 0 | 256 | 0/256 |
| `|■` | Norm | 16 | 0 | 1 | 136 | 16/640 |
| `|□` | Norm | 16 | 0 | 1 | 136 | 16/640 |
| `⊟` | ProductConstant | 0 | 0 | 0 | 256 | 0/256 |
| `⊞` | ProductConstant | 0 | 0 | 0 | 256 | 81/1024 |
| `⊙` | Center | 54 | 0 | 0 | 256 | 162/1792 |
| `⊡` | Container | 54 | 0 | 0 | 256 | 81/1280 |
| `⊛` | Permutation + Container + JoinCarrier | 108 | 0 | 0 | 256 | 178/9216 |
