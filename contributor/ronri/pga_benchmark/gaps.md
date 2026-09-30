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
  73 gaps. The widest is cga5d/partner_round_point, which spends 518 multiplies against 10. Closes
  when no typed gap spends more multiplies than its reference.
- **D02, over.** Library calls run slower than typed forms beyond the band. Evidence: 151 gaps. The
  worst is cga5d/partner_sphere, at 477.6 ns against 3.7 ns. Closes when no gap's library median
  exceeds 1.25 times its reference's.
- **D03, over.** Operators zero-fill their full-width result before they write it. Evidence: 82 of
  190 library functions. The most is cga5d `⊛(Multivector)` with 108. Closes when no library
  function calls `nimZeroMem`.
- **D04, over.** Operator chains build full-width intermediates. Evidence: 52 of 190 library
  functions. The most is cga5d `⊛(Multivector)` with 8. Closes when no library function declares a
  local multivector.
- **D05, over.** Error-flag checks survive into release builds. Evidence: 64 of 190 library
  functions. The most is cga5d `⊛(Multivector)` with 271. Closes when no library function branches
  on `nimErr_`. The pinned compiler with `--panics:on` already emits none in either implementation.
  A user of the library must know to pass it.
- **D06, over.** Sign and permutation operators cross the module boundary as calls. Evidence: 12 of
  150 library operators, for example rga4d `-(Multivector)`. Closes when every library function
  spending no multiply, add or subtract is inline.
- **D07, over.** Conformal norms return NaN on real objects. Evidence: cga5d/norm_bulk,
  cga5d/norm_weight, cga5d/norm, cga5d/normalize_bulk, cga5d/normalize_weight, cga5d/unitize, and 10
  more. Closes when every bench measurement's NaN share is zero.
- **D08, over.** A transform by motor spells three products, because it has no operator of its own.
  Evidence: rga4d/transform_point_motor, rga4d/transform_line_motor, rga4d/transform_plane_motor.
  Closes when every catalogued measurand spells one library function.
- **D09, over.** The library refuses two norms that the reference carries. Evidence:
  cga5d/norm_center `|⊙`, cga5d/norm_radius `|⊘`, cga4d/norm_center `|⊙`, cga4d/norm_radius `|⊘`.
  Closes when the catalogue's missing list is empty.
- **D10, unmeasured.** The library builds compile-time Cayley tables and drops some, by the audit's
  reading. Evidence: no emitted C reaches it. The audit read `cayleys.nim`. Closes when the project
  measures tables built against tables used. Nothing here reads compile time.

## rga4d

This algebra has 4 dimensions, a rigid metric and a 128-byte multivector. The inspector took the
counts on 2026-09-28, on linux amd64, 4 cores, with nim `27763495bcfe265507ca98aedc1c7064bf1e0e4d`,
pga `bd6b23c590d7e1da91a1ea288a1a4b94dedbf315` and flags `-d:release`. The bench ran 5 times on
2026-09-30, on linux amd64, 4 cores, over 40 rounds of 1024 objects each. Each time is the median of
those runs. The allocation gauge was live.
Gaps: 111. Over 88, met 23, unmeasured 0.

| Id | Measurand | Mul | Div | Bytes | Int | Chk | ns | Status |
|----|-----------|-----|-----|-------|-----|-----|----|--------|
| G001 | wedge | 81/– | 0/– | 384/– | 0/– | 0/– | 35.5/– | met |
| G002 | wedge_anti | 81/– | 0/– | 384/– | 0/– | 0/– | 37.9/– | met |
| G003 | wedge_dot | 192/– | 0/– | 384/– | 0/– | 0/– | 101.6/– | met |
| G004 | wedge_dot_anti | 192/– | 0/– | 384/– | 0/– | 0/– | 107.7/– | met |
| G005 | dot | 8/– | 0/– | 384/– | 0/– | 0/– | 14.3/– | met |
| G006 | dot_anti | 8/– | 0/– | 384/– | 0/– | 0/– | 13.0/– | met |
| G007 | contract_bulk | 54/– | 0/– | 384/– | 0/– | 0/– | 34.4/– | met |
| G008 | contract_weight | 27/– | 0/– | 384/– | 0/– | 0/– | 27.1/– | met |
| G009 | expand_bulk | 27/– | 0/– | 384/– | 0/– | 0/– | 28.8/– | met |
| G010 | expand_weight | 54/– | 0/– | 384/– | 0/– | 0/– | 30.9/– | met |
| G011 | add | 0/– | 0/– | 512/– | 0/– | 0/– | 24.0/– | over |
| G012 | subtract | 0/– | 0/– | 512/– | 0/– | 0/– | 22.5/– | over |
| G013 | project_central | 108/– | 0/– | 1152/– | 2/– | 2/– | 75.5/– | over |
| G014 | project_central_anti | 135/– | 0/– | 1152/– | 2/– | 2/– | 103.8/– | over |
| G015 | project_orthogonal | 135/– | 0/– | 1152/– | 2/– | 2/– | 96.8/– | over |
| G016 | project_orthogonal_anti | 108/– | 0/– | 1152/– | 2/– | 2/– | 59.8/– | over |
| G017 | scale | 16/– | 0/– | 264/– | 0/– | 0/– | 18.4/– | met |
| G018 | bulk | 0/– | 0/– | 256/– | 0/– | 0/– | 4.3/– | met |
| G019 | weight | 0/– | 0/– | 256/– | 0/– | 0/– | 6.5/– | met |
| G020 | complement_right | 0/– | 0/– | 256/– | 0/– | 0/– | 8.5/– | met |
| G021 | complement_left | 0/– | 0/– | 256/– | 0/– | 0/– | 8.6/– | met |
| G022 | reverse | 0/– | 0/– | 256/– | 0/– | 0/– | 8.7/– | met |
| G023 | reverse_anti | 0/– | 0/– | 256/– | 0/– | 0/– | 9.4/– | met |
| G024 | dual_bulk | 0/– | 0/– | 256/– | 0/– | 0/– | 7.2/– | met |
| G025 | dual_weight | 0/– | 0/– | 256/– | 0/– | 0/– | 7.7/– | met |
| G026 | negate | 0/– | 0/– | 384/– | 0/– | 0/– | 14.4/– | over |
| G027 | norm_bulk | 8/– | 0/– | 640/– | 1/– | 1/– | 11.3/– | over |
| G028 | norm_weight | 8/– | 0/– | 640/– | 1/– | 1/– | 11.2/– | over |
| G316 | norm_bulk_squared | 8/– | 0/– | 256/– | 0/– | 0/– | 8.7/– | met |
| G317 | norm_weight_squared | 8/– | 0/– | 256/– | 0/– | 0/– | 7.0/– | met |
| G029 | norm | 16/– | 0/– | 1664/– | 4/– | 4/– | 13.2/– | over |
| G030 | normalize_bulk | 24/– | 1/– | 512/– | 1/– | 1/– | 14.4/– | over |
| G031 | normalize_weight | 24/– | 1/– | 512/– | 1/– | 1/– | 14.8/– | over |
| G032 | unitize | 24/– | 1/– | 512/– | 1/– | 1/– | 14.7/– | over |
| G033 | attitude | 0/– | 0/– | 256/– | 0/– | 0/– | 6.2/– | met |
| G034 | select_grade | 0/– | 0/– | 392/– | 0/– | 0/– | 14.8/– | over |
| G035 | select_grade_anti | 0/– | 0/– | 392/– | 0/– | 1/– | 16.2/– | over |
| G036 | select_part | – | – | – | – | – | 0.9/– | met |
| G037 | support | 162/– | 0/– | 1280/– | 3/– | 3/– | 116.2/– | over |
| G038 | support_anti | 162/– | 0/– | 1792/– | 3/– | 4/– | 97.2/– | over |
| G039 | wedge_point_point | 81/12 | 0/0 | 384/112 | 0/0 | 0/0 | 51.3/14.7 | over |
| G040 | wedge_line_point | 81/12 | 0/0 | 384/112 | 0/0 | 0/0 | 49.8/14.8 | over |
| G041 | wedge_point_line | 81/12 | 0/0 | 384/144 | 0/0 | 0/1 | 42.5/17.3 | over |
| G042 | wedge_anti_plane_plane | 81/12 | 0/0 | 384/112 | 0/0 | 0/0 | 49.7/12.2 | over |
| G043 | wedge_anti_plane_line | 81/12 | 0/0 | 384/112 | 0/0 | 0/0 | 55.6/16.9 | over |
| G044 | wedge_anti_line_plane | 81/12 | 0/0 | 384/144 | 0/0 | 0/1 | 50.1/15.7 | over |
| G045 | wedge_anti_line_line | 81/6 | 0/0 | 384/104 | 0/0 | 0/2 | 56.2/10.9 | over |
| G046 | wedge_anti_point_plane | 81/4 | 0/0 | 384/72 | 0/0 | 0/0 | 52.5/10.2 | over |
| G047 | dot_point_point | 8/3 | 0/0 | 384/72 | 0/0 | 0/0 | 14.4/10.2 | over |
| G048 | dot_line_line | 8/3 | 0/0 | 384/104 | 0/0 | 0/1 | 14.4/9.8 | over |
| G049 | dot_plane_plane | 8/1 | 0/0 | 384/72 | 0/0 | 0/0 | 14.4/9.2 | over |
| G050 | dot_anti_point_point | 8/1 | 0/0 | 384/72 | 0/0 | 0/0 | 13.3/8.4 | over |
| G051 | dot_anti_line_line | 8/3 | 0/0 | 384/104 | 0/0 | 0/1 | 13.2/8.7 | over |
| G052 | dot_anti_plane_plane | 8/3 | 0/0 | 384/72 | 0/0 | 0/0 | 13.2/13.4 | over |
| G053 | wedge_dot_anti_motor_motor | 192/48 | 0/0 | 384/256 | 0/0 | 0/0 | 111.8/28.9 | over |
| G054 | transform_point_motor | –/25 | –/0 | –/192 | –/0 | –/8 | 269.9/19.9 | over |
| G055 | transform_line_motor | –/57 | –/0 | –/400 | –/0 | –/23 | 275.6/34.3 | over |
| G056 | transform_plane_motor | –/36 | –/0 | –/256 | –/0 | –/15 | 295.2/23.6 | over |
| G057 | project_orthogonal_point_plane | 135/14 | 0/0 | 1152/128 | 2/0 | 2/0 | 83.6/14.1 | over |
| G058 | project_orthogonal_point_line | 135/19 | 0/0 | 1152/176 | 2/0 | 2/2 | 83.3/16.6 | over |
| G059 | project_orthogonal_line_plane | 135/27 | 0/0 | 1152/224 | 2/0 | 2/10 | 81.8/17.0 | over |
| G060 | support_line | 162/9 | 0/0 | 1280/112 | 3/0 | 3/1 | 95.1/2.7 | over |
| G061 | support_plane | 162/6 | 0/0 | 1280/64 | 3/0 | 3/0 | 95.7/1.9 | over |
| G062 | support_anti_point | 162/6 | 0/0 | 1792/64 | 3/0 | 4/0 | 96.1/1.9 | over |
| G063 | support_anti_line | 162/9 | 0/0 | 1792/112 | 3/0 | 4/1 | 97.8/2.6 | over |
| G064 | reverse_anti_motor | 0/0 | 0/0 | 256/256 | 0/0 | 0/2 | 8.6/2.6 | over |
| G065 | unitize_motor | 24/12 | 1/1 | 512/320 | 1/0 | 1/4 | 9.8/11.3 | over |
| G066 | norm_weight_motor | 8/4 | 0/0 | 640/72 | 1/0 | 1/2 | 11.0/2.5 | over |
| G067 | norm_bulk_motor | 8/4 | 0/0 | 640/72 | 1/0 | 1/2 | 13.2/2.2 | over |
| G068 | complement_right_point | 0/0 | 0/0 | 256/64 | 0/0 | 0/0 | 8.4/0.9 | over |
| G069 | complement_left_point | 0/0 | 0/0 | 256/64 | 0/0 | 0/0 | 8.4/1.7 | over |
| G070 | reverse_point | 0/0 | 0/0 | 256/96 | 0/0 | 0/0 | 8.5/0.9 | over |
| G071 | reverse_anti_point | 0/0 | 0/0 | 256/96 | 0/0 | 0/0 | 8.5/1.6 | over |
| G072 | dual_bulk_point | 0/0 | 0/0 | 256/64 | 0/0 | 0/0 | 6.5/1.2 | over |
| G073 | dual_weight_point | 0/0 | 0/0 | 256/64 | 0/0 | 0/0 | 7.9/2.1 | over |
| G074 | bulk_point | 0/0 | 0/0 | 256/96 | 0/0 | 0/0 | 4.3/2.1 | over |
| G075 | weight_point | 0/0 | 0/0 | 256/96 | 0/0 | 0/0 | 6.5/2.1 | over |
| G076 | norm_bulk_point | 8/3 | 0/0 | 640/40 | 1/0 | 1/1 | 11.3/1.8 | over |
| G077 | norm_weight_point | 8/0 | 0/0 | 640/40 | 1/0 | 1/0 | 11.8/0.7 | over |
| G318 | norm_bulk_squared_point | 8/3 | 0/0 | 256/40 | 0/0 | 0/0 | 8.5/1.1 | over |
| G319 | norm_weight_squared_point | 8/– | 0/– | 256/– | 0/– | 0/– | 7.0/0.6 | over |
| G078 | unitize_point | 24/3 | 1/1 | 512/128 | 1/0 | 1/0 | 10.2/1.8 | over |
| G079 | attitude_point | 0/0 | 0/0 | 256/40 | 0/0 | 0/0 | 4.4/0.9 | over |
| G080 | complement_right_line | 0/0 | 0/0 | 256/192 | 0/0 | 0/2 | 8.4/4.1 | over |
| G081 | complement_left_line | 0/0 | 0/0 | 256/192 | 0/0 | 0/2 | 8.4/4.1 | over |
| G082 | reverse_line | 0/0 | 0/0 | 256/192 | 0/0 | 0/2 | 8.8/4.0 | over |
| G083 | reverse_anti_line | 0/0 | 0/0 | 256/192 | 0/0 | 0/2 | 8.7/4.0 | over |
| G084 | dual_bulk_line | 0/0 | 0/0 | 256/192 | 0/0 | 0/1 | 6.5/2.6 | over |
| G085 | dual_weight_line | 0/0 | 0/0 | 256/192 | 0/0 | 0/1 | 7.8/1.8 | over |
| G086 | bulk_line | 0/0 | 0/0 | 256/144 | 0/0 | 0/0 | 4.3/2.8 | over |
| G087 | weight_line | 0/0 | 0/0 | 256/144 | 0/0 | 0/0 | 6.5/2.6 | over |
| G088 | norm_bulk_line | 8/3 | 0/0 | 640/56 | 1/0 | 1/2 | 11.8/1.8 | over |
| G089 | norm_weight_line | 8/3 | 0/0 | 640/56 | 1/0 | 1/2 | 11.6/1.8 | over |
| G320 | norm_bulk_squared_line | 8/3 | 0/0 | 256/56 | 0/0 | 0/1 | 8.8/1.8 | over |
| G321 | norm_weight_squared_line | 8/– | 0/– | 256/– | 0/– | 0/– | 6.9/1.8 | over |
| G090 | unitize_line | 24/9 | 1/1 | 512/240 | 1/0 | 1/4 | 10.2/10.6 | over |
| G091 | attitude_line | 0/0 | 0/0 | 256/80 | 0/0 | 0/0 | 5.0/1.3 | over |
| G092 | complement_right_plane | 0/0 | 0/0 | 256/64 | 0/0 | 0/0 | 8.4/1.5 | over |
| G093 | complement_left_plane | 0/0 | 0/0 | 256/64 | 0/0 | 0/0 | 8.6/1.2 | over |
| G094 | reverse_plane | 0/0 | 0/0 | 256/96 | 0/0 | 0/0 | 8.8/1.6 | over |
| G095 | reverse_anti_plane | 0/0 | 0/0 | 256/96 | 0/0 | 0/0 | 9.7/0.9 | over |
| G096 | dual_bulk_plane | 0/0 | 0/0 | 256/64 | 0/0 | 0/0 | 6.5/1.9 | over |
| G097 | dual_weight_plane | 0/0 | 0/0 | 256/64 | 0/0 | 0/0 | 7.7/1.2 | over |
| G098 | bulk_plane | 0/0 | 0/0 | 256/96 | 0/0 | 0/0 | 4.8/2.1 | over |
| G099 | weight_plane | 0/0 | 0/0 | 256/96 | 0/0 | 0/0 | 6.7/2.2 | over |
| G100 | norm_bulk_plane | 8/0 | 0/0 | 640/40 | 1/0 | 1/0 | 10.8/0.7 | over |
| G101 | norm_weight_plane | 8/3 | 0/0 | 640/40 | 1/0 | 1/1 | 11.5/1.8 | over |
| G322 | norm_bulk_squared_plane | 8/1 | 0/0 | 256/40 | 0/0 | 0/0 | 8.5/0.6 | over |
| G323 | norm_weight_squared_plane | 8/– | 0/– | 256/– | 0/– | 0/– | 7.4/1.3 | over |
| G102 | unitize_plane | 24/7 | 1/1 | 512/160 | 1/0 | 1/1 | 12.1/11.3 | over |
| G103 | attitude_plane | 0/0 | 0/0 | 256/80 | 0/0 | 0/0 | 4.4/2.4 | over |

### Multivector lower bound

| Op | Shape | Mul | Div | Roots | Bytes | Library mul/bytes |
|----|-------|-----|-----|-------|-------|-------------------|
| `∧` | Wedge | 81 | 0 | 0 | 384 | 81/384 |
| `∨` | Wedge | 81 | 0 | 0 | 384 | 81/384 |
| `⟑` | Geometric | 192 | 0 | 0 | 384 | 192/384 |
| `⟇` | Geometric | 192 | 0 | 0 | 384 | 192/384 |
| `∙` | ScalarForm | 8 | 0 | 0 | 264 | 8/384 |
| `∘` | ScalarForm | 8 | 0 | 0 | 264 | 8/384 |
| `∨★` | ContractBulk | 54 | 0 | 0 | 384 | 54/384 |
| `∨☆` | ContractWeight | 27 | 0 | 0 | 384 | 27/384 |
| `∧★` | ExpandBulk | 27 | 0 | 0 | 384 | 27/384 |
| `∧☆` | ExpandWeight | 54 | 0 | 0 | 384 | 54/384 |
| `+` | Componentwise | 0 | 0 | 0 | 384 | 0/512 |
| `-` | Componentwise | 0 | 0 | 0 | 384 | 0/512 |
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
| `-` | Permutation | 0 | 0 | 0 | 256 | 0/384 |
| `|∙` | Norm | 8 | 0 | 1 | 136 | 8/640 |
| `|∘` | Norm | 8 | 0 | 1 | 136 | 8/640 |
| `|∙²` | SquaredNorm | 8 | 0 | 0 | 136 | 8/256 |
| `|∘²` | SquaredNorm | 8 | 0 | 0 | 136 | 8/256 |
| `|` | 2 Norm | 16 | 0 | 2 | 136 | 16/1664 |
| `^∙` | Unitize | 24 | 1 | 1 | 256 | 24/512 |
| `^∘` | Unitize | 24 | 1 | 1 | 256 | 24/512 |
| `^` | Unitize | 24 | 1 | 1 | 256 | 24/512 |
| `⊖` | ConstantProduct | 0 | 0 | 0 | 256 | 0/256 |
| `{}` | Permutation | 0 | 0 | 0 | 256 | 0/392 |
| `{}` | Permutation | 0 | 0 | 0 | 256 | 0/392 |
| `∩` | Support | 54 | 0 | 0 | 256 | 162/1280 |
| `∪` | SupportAnti | 54 | 0 | 0 | 256 | 162/1792 |
| `((n ⟇ m) ⟇ (~∘ n))` | Permutation + 2 Geometric | 384 | 0 | 0 | 384 | – |

## cga5d

This algebra has 5 dimensions, a conformal metric and a 256-byte multivector. The inspector took the
counts on 2026-09-28, on linux amd64, 4 cores, with nim `27763495bcfe265507ca98aedc1c7064bf1e0e4d`,
pga `bd6b23c590d7e1da91a1ea288a1a4b94dedbf315` and flags `-d:release`. The bench ran 5 times on
2026-09-30, on linux amd64, 4 cores, over 40 rounds of 1024 objects each. Each time is the median of
those runs. The allocation gauge was live.
Gaps: 131. Over 105, met 26, unmeasured 0.

| Id | Measurand | Mul | Div | Bytes | Int | Chk | ns | Status |
|----|-----------|-----|-----|-------|-----|-----|----|--------|
| G104 | wedge | 243/– | 0/– | 768/– | 0/– | 0/– | 135.7/– | met |
| G105 | wedge_anti | 243/– | 0/– | 768/– | 0/– | 0/– | 139.3/– | met |
| G106 | wedge_dot | 1024/– | 0/– | 768/– | 0/– | 0/– | 771.8/– | met |
| G107 | wedge_dot_anti | 1024/– | 0/– | 768/– | 0/– | 0/– | 777.1/– | met |
| G108 | dot | 32/– | 0/– | 768/– | 0/– | 0/– | 33.9/– | met |
| G109 | dot_anti | 32/– | 0/– | 768/– | 0/– | 0/– | 31.5/– | met |
| G110 | contract_bulk | 243/– | 0/– | 768/– | 0/– | 0/– | 137.2/– | met |
| G111 | contract_weight | 243/– | 0/– | 768/– | 0/– | 0/– | 138.1/– | met |
| G112 | expand_bulk | 243/– | 0/– | 768/– | 0/– | 0/– | 128.9/– | met |
| G113 | expand_weight | 243/– | 0/– | 768/– | 0/– | 0/– | 127.3/– | met |
| G114 | add | 0/– | 0/– | 1024/– | 0/– | 0/– | 34.7/– | over |
| G115 | subtract | 0/– | 0/– | 1024/– | 0/– | 0/– | 32.3/– | over |
| G116 | project_central | 486/– | 0/– | 2304/– | 2/– | 2/– | 307.9/– | over |
| G117 | project_central_anti | 486/– | 0/– | 2304/– | 2/– | 2/– | 267.9/– | over |
| G118 | project_orthogonal | 486/– | 0/– | 2304/– | 2/– | 2/– | 283.6/– | over |
| G119 | project_orthogonal_anti | 486/– | 0/– | 2304/– | 2/– | 2/– | 279.3/– | over |
| G120 | scale | 32/– | 0/– | 520/– | 0/– | 0/– | 25.3/– | met |
| G121 | bulk | 0/– | 0/– | 512/– | 0/– | 0/– | 16.2/– | met |
| G122 | weight | 0/– | 0/– | 512/– | 0/– | 0/– | 16.8/– | met |
| G123 | complement_right | 0/– | 0/– | 512/– | 0/– | 0/– | 15.9/– | met |
| G124 | complement_left | 0/– | 0/– | 512/– | 0/– | 0/– | 16.8/– | met |
| G125 | reverse | 0/– | 0/– | 512/– | 0/– | 0/– | 15.7/– | met |
| G126 | reverse_anti | 0/– | 0/– | 512/– | 0/– | 0/– | 16.4/– | met |
| G127 | dual_bulk | 0/– | 0/– | 512/– | 0/– | 0/– | 15.9/– | met |
| G128 | dual_weight | 0/– | 0/– | 512/– | 0/– | 0/– | 15.8/– | met |
| G129 | negate | 0/– | 0/– | 768/– | 0/– | 0/– | 22.1/– | over |
| G130 | norm_bulk | 32/– | 0/– | 1280/– | 1/– | 1/– | 51.2/– | over |
| G131 | norm_weight | 32/– | 0/– | 1280/– | 1/– | 1/– | 48.7/– | over |
| G324 | norm_bulk_squared | 32/– | 0/– | 512/– | 0/– | 0/– | 23.9/– | met |
| G325 | norm_weight_squared | 32/– | 0/– | 512/– | 0/– | 0/– | 23.5/– | met |
| G132 | norm | 64/– | 0/– | 3328/– | 4/– | 4/– | 84.5/– | over |
| G133 | normalize_bulk | 64/– | 1/– | 1024/– | 1/– | 1/– | 64.5/– | over |
| G134 | normalize_weight | 64/– | 1/– | 1024/– | 1/– | 1/– | 38.2/– | over |
| G135 | unitize | 64/– | 1/– | 1024/– | 1/– | 1/– | 39.2/– | over |
| G136 | attitude | 0/– | 0/– | 512/– | 0/– | 0/– | 17.9/– | met |
| G137 | select_grade | 0/– | 0/– | 776/– | 0/– | 0/– | 19.2/– | over |
| G138 | select_grade_anti | 0/– | 0/– | 776/– | 0/– | 1/– | 20.4/– | over |
| G139 | select_part | – | – | – | – | – | 0.9/– | met |
| G140 | bulk_flat | 0/– | 0/– | 512/– | 0/– | 0/– | 17.2/– | met |
| G141 | weight_flat | 0/– | 0/– | 512/– | 0/– | 0/– | 14.9/– | met |
| G142 | norm_bulk_flat | 32/– | 0/– | 1280/– | 1/– | 1/– | 50.8/– | over |
| G143 | norm_weight_flat | 32/– | 0/– | 1280/– | 1/– | 1/– | 48.1/– | over |
| G144 | carrier | 0/– | 0/– | 512/– | 0/– | 0/– | 16.8/– | met |
| G145 | carrier_co | 243/– | 0/– | 2048/– | 2/– | 2/– | 83.2/– | over |
| G146 | center | 486/– | 0/– | 3584/– | 4/– | 4/– | 217.4/– | over |
| G147 | container | 243/– | 0/– | 2560/– | 3/– | 3/– | 147.8/– | over |
| G148 | partner | 518/– | 0/– | 30720/– | 8/– | 271/– | 340.0/– | over |
| G149 | wedge_round_point_round_point | 243/20 | 0/0 | 768/160 | 0/0 | 0/0 | 125.3/15.3 | over |
| G150 | wedge_dipole_round_point | 243/30 | 0/0 | 768/200 | 0/0 | 0/0 | 125.3/23.5 | over |
| G151 | wedge_round_point_dipole | 243/30 | 0/0 | 768/280 | 0/0 | 0/1 | 130.0/28.2 | over |
| G152 | wedge_circle_round_point | 243/20 | 0/0 | 768/160 | 0/0 | 0/0 | 126.3/18.2 | over |
| G153 | wedge_round_point_circle | 243/20 | 0/0 | 768/160 | 0/0 | 0/0 | 133.0/17.8 | over |
| G154 | wedge_dipole_dipole | 243/30 | 0/0 | 768/200 | 0/0 | 0/0 | 174.7/27.6 | over |
| G155 | wedge_anti_sphere_sphere | 243/20 | 0/0 | 768/160 | 0/0 | 0/0 | 192.3/20.7 | over |
| G156 | wedge_anti_sphere_circle | 243/30 | 0/0 | 768/200 | 0/0 | 0/0 | 198.7/31.5 | over |
| G157 | wedge_anti_circle_sphere | 243/30 | 0/0 | 768/280 | 0/0 | 0/1 | 139.5/32.7 | over |
| G158 | wedge_anti_circle_circle | 243/30 | 0/0 | 768/200 | 0/0 | 0/0 | 204.6/21.7 | over |
| G159 | wedge_anti_sphere_dipole | 243/20 | 0/0 | 768/160 | 0/0 | 0/0 | 215.2/17.5 | over |
| G160 | wedge_anti_dipole_sphere | 243/20 | 0/0 | 768/160 | 0/0 | 0/0 | 138.8/17.3 | over |
| G161 | dot_round_point_round_point | 32/5 | 0/0 | 768/88 | 0/0 | 0/0 | 34.0/10.3 | over |
| G162 | dot_dipole_dipole | 32/10 | 0/0 | 768/168 | 0/0 | 0/3 | 33.9/14.2 | over |
| G163 | dot_circle_circle | 32/10 | 0/0 | 768/168 | 0/0 | 0/3 | 33.8/14.5 | over |
| G164 | dot_sphere_sphere | 32/5 | 0/0 | 768/88 | 0/0 | 0/0 | 33.9/10.6 | over |
| G165 | dot_anti_round_point_round_point | 32/5 | 0/0 | 768/88 | 0/0 | 0/1 | 31.8/10.6 | over |
| G166 | dot_anti_dipole_dipole | 32/10 | 0/0 | 768/168 | 0/0 | 0/4 | 31.8/14.2 | over |
| G167 | dot_anti_circle_circle | 32/10 | 0/0 | 768/168 | 0/0 | 0/4 | 31.7/14.2 | over |
| G168 | dot_anti_sphere_sphere | 32/5 | 0/0 | 768/88 | 0/0 | 0/1 | 31.7/10.6 | over |
| G169 | complement_right_round_point | 0/0 | 0/0 | 512/80 | 0/0 | 0/0 | 16.7/2.3 | over |
| G170 | complement_left_round_point | 0/0 | 0/0 | 512/120 | 0/0 | 0/1 | 16.7/3.7 | over |
| G171 | reverse_round_point | 0/0 | 0/0 | 512/120 | 0/0 | 0/0 | 16.2/8.0 | over |
| G172 | reverse_anti_round_point | 0/0 | 0/0 | 512/120 | 0/0 | 0/0 | 16.2/8.0 | over |
| G173 | dual_bulk_round_point | 0/0 | 0/0 | 512/80 | 0/0 | 0/0 | 16.7/1.9 | over |
| G174 | dual_weight_round_point | 0/0 | 0/0 | 512/80 | 0/0 | 0/0 | 16.6/2.3 | over |
| G175 | bulk_round_point | 0/0 | 0/0 | 512/120 | 0/0 | 0/0 | 17.6/1.7 | over |
| G176 | weight_round_point | 0/0 | 0/0 | 512/120 | 0/0 | 0/0 | 17.1/2.7 | over |
| G177 | bulk_flat_round_point | 0/0 | 0/0 | 512/120 | 0/0 | 0/0 | 18.5/1.7 | over |
| G178 | weight_flat_round_point | 0/0 | 0/0 | 512/80 | 0/0 | 0/0 | 15.5/2.1 | over |
| G179 | attitude_round_point | 0/0 | 0/0 | 512/48 | 0/0 | 0/0 | 19.1/1.0 | over |
| G180 | carrier_round_point | 0/0 | 0/0 | 512/72 | 0/0 | 0/0 | 16.6/1.0 | over |
| G181 | carrier_co_round_point | 243/0 | 0/0 | 2048/48 | 2/0 | 2/0 | 96.0/0.9 | over |
| G182 | center_round_point | 486/5 | 0/0 | 3584/120 | 4/0 | 4/0 | 218.2/2.2 | over |
| G183 | container_round_point | 243/8 | 0/0 | 2560/80 | 3/0 | 3/0 | 149.7/2.6 | over |
| G184 | partner_round_point | 518/10 | 0/0 | 30720/120 | 8/0 | 271/0 | 396.9/3.6 | over |
| G185 | complement_right_dipole | 0/0 | 0/0 | 512/400 | 0/0 | 0/2 | 16.8/6.9 | over |
| G186 | complement_left_dipole | 0/0 | 0/0 | 512/480 | 0/0 | 0/3 | 16.8/9.0 | over |
| G187 | reverse_dipole | 0/0 | 0/0 | 512/320 | 0/0 | 0/2 | 16.8/3.7 | over |
| G188 | reverse_anti_dipole | 0/0 | 0/0 | 512/560 | 0/0 | 0/3 | 16.8/4.0 | over |
| G189 | dual_bulk_dipole | 0/0 | 0/0 | 512/320 | 0/0 | 0/1 | 16.7/4.4 | over |
| G190 | dual_weight_dipole | 0/0 | 0/0 | 512/160 | 0/0 | 0/0 | 17.6/3.6 | over |
| G191 | bulk_dipole | 0/0 | 0/0 | 512/240 | 0/0 | 0/0 | 17.5/4.2 | over |
| G192 | weight_dipole | 0/0 | 0/0 | 512/240 | 0/0 | 0/0 | 17.1/5.1 | over |
| G193 | bulk_flat_dipole | 0/0 | 0/0 | 512/240 | 0/0 | 0/0 | 18.8/3.7 | over |
| G194 | weight_flat_dipole | 0/0 | 0/0 | 512/240 | 0/0 | 0/0 | 16.2/4.6 | over |
| G195 | attitude_dipole | 0/0 | 0/0 | 512/120 | 0/0 | 0/0 | 20.8/2.4 | over |
| G196 | carrier_dipole | 0/0 | 0/0 | 512/128 | 0/0 | 0/0 | 16.8/1.8 | over |
| G197 | carrier_co_dipole | 243/0 | 0/0 | 2048/112 | 2/0 | 2/0 | 126.6/2.1 | over |
| G198 | center_dipole | 486/16 | 0/0 | 3584/160 | 4/0 | 4/1 | 273.5/4.3 | over |
| G199 | container_dipole | 243/18 | 0/0 | 2560/160 | 3/0 | 3/2 | 168.5/8.8 | over |
| G200 | partner_dipole | 518/29 | 0/0 | 30720/320 | 8/0 | 271/4 | 372.3/7.2 | over |
| G201 | complement_right_circle | 0/0 | 0/0 | 512/400 | 0/0 | 0/2 | 16.7/7.2 | over |
| G202 | complement_left_circle | 0/0 | 0/0 | 512/480 | 0/0 | 0/3 | 16.7/9.2 | over |
| G203 | reverse_circle | 0/0 | 0/0 | 512/320 | 0/0 | 0/2 | 16.3/3.8 | over |
| G204 | reverse_anti_circle | 0/0 | 0/0 | 512/560 | 0/0 | 0/3 | 16.3/4.0 | over |
| G205 | dual_bulk_circle | 0/0 | 0/0 | 512/160 | 0/0 | 0/0 | 16.7/4.0 | over |
| G206 | dual_weight_circle | 0/0 | 0/0 | 512/320 | 0/0 | 0/1 | 16.7/4.3 | over |
| G207 | bulk_circle | 0/0 | 0/0 | 512/240 | 0/0 | 0/0 | 17.6/5.3 | over |
| G208 | weight_circle | 0/0 | 0/0 | 512/240 | 0/0 | 0/0 | 17.1/4.7 | over |
| G209 | bulk_flat_circle | 0/0 | 0/0 | 512/240 | 0/0 | 0/0 | 18.3/4.6 | over |
| G210 | weight_flat_circle | 0/0 | 0/0 | 512/240 | 0/0 | 0/0 | 15.9/4.1 | over |
| G211 | attitude_circle | 0/0 | 0/0 | 512/160 | 0/0 | 0/0 | 18.9/5.1 | over |
| G212 | carrier_circle | 0/0 | 0/0 | 512/112 | 0/0 | 0/0 | 16.8/1.3 | over |
| G213 | carrier_co_circle | 243/0 | 0/0 | 2048/224 | 2/0 | 2/1 | 98.6/2.9 | over |
| G214 | center_circle | 486/18 | 0/0 | 3584/160 | 4/0 | 4/1 | 334.9/8.1 | over |
| G215 | container_circle | 243/16 | 0/0 | 2560/120 | 3/0 | 3/0 | 207.2/4.3 | over |
| G216 | partner_circle | 518/29 | 0/0 | 30720/320 | 8/0 | 271/2 | 381.2/9.3 | over |
| G217 | complement_right_sphere | 0/0 | 0/0 | 512/80 | 0/0 | 0/0 | 17.0/1.6 | over |
| G218 | complement_left_sphere | 0/0 | 0/0 | 512/120 | 0/0 | 0/1 | 16.7/3.8 | over |
| G219 | reverse_sphere | 0/0 | 0/0 | 512/120 | 0/0 | 0/0 | 16.3/8.3 | over |
| G220 | reverse_anti_sphere | 0/0 | 0/0 | 512/120 | 0/0 | 0/0 | 16.2/9.4 | over |
| G221 | dual_bulk_sphere | 0/0 | 0/0 | 512/80 | 0/0 | 0/0 | 16.8/2.1 | over |
| G222 | dual_weight_sphere | 0/0 | 0/0 | 512/80 | 0/0 | 0/0 | 16.6/2.1 | over |
| G223 | bulk_sphere | 0/0 | 0/0 | 512/80 | 0/0 | 0/0 | 18.2/2.1 | over |
| G224 | weight_sphere | 0/0 | 0/0 | 512/120 | 0/0 | 0/0 | 17.1/3.0 | over |
| G225 | bulk_flat_sphere | 0/0 | 0/0 | 512/120 | 0/0 | 0/0 | 18.4/1.5 | over |
| G226 | weight_flat_sphere | 0/0 | 0/0 | 512/120 | 0/0 | 0/0 | 16.2/3.0 | over |
| G227 | attitude_sphere | 0/0 | 0/0 | 512/120 | 0/0 | 0/0 | 20.9/4.9 | over |
| G228 | carrier_sphere | 0/0 | 0/0 | 512/48 | 0/0 | 0/0 | 19.2/1.0 | over |
| G229 | carrier_co_sphere | 243/0 | 0/0 | 2048/72 | 2/0 | 2/0 | 120.8/2.1 | over |
| G230 | center_sphere | 486/8 | 0/0 | 3584/80 | 4/0 | 4/0 | 367.7/5.1 | over |
| G231 | container_sphere | 243/5 | 0/0 | 2560/120 | 3/0 | 3/0 | 230.4/2.6 | over |
| G232 | partner_sphere | 518/10 | 0/0 | 30720/120 | 8/0 | 271/0 | 477.6/3.7 | over |

### Multivector lower bound

| Op | Shape | Mul | Div | Roots | Bytes | Library mul/bytes |
|----|-------|-----|-----|-------|-------|-------------------|
| `∧` | Wedge | 243 | 0 | 0 | 768 | 243/768 |
| `∨` | Wedge | 243 | 0 | 0 | 768 | 243/768 |
| `⟑` | Geometric | 1024 | 0 | 0 | 768 | 1024/768 |
| `⟇` | Geometric | 1024 | 0 | 0 | 768 | 1024/768 |
| `∙` | ScalarForm | 32 | 0 | 0 | 520 | 32/768 |
| `∘` | ScalarForm | 32 | 0 | 0 | 520 | 32/768 |
| `∨★` | ContractBulk | 243 | 0 | 0 | 768 | 243/768 |
| `∨☆` | ContractWeight | 243 | 0 | 0 | 768 | 243/768 |
| `∧★` | ExpandBulk | 243 | 0 | 0 | 768 | 243/768 |
| `∧☆` | ExpandWeight | 243 | 0 | 0 | 768 | 243/768 |
| `+` | Componentwise | 0 | 0 | 0 | 768 | 0/1024 |
| `-` | Componentwise | 0 | 0 | 0 | 768 | 0/1024 |
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
| `-` | Permutation | 0 | 0 | 0 | 512 | 0/768 |
| `|∙` | Norm | 32 | 0 | 1 | 264 | 32/1280 |
| `|∘` | Norm | 32 | 0 | 1 | 264 | 32/1280 |
| `|∙²` | SquaredNorm | 32 | 0 | 0 | 264 | 32/512 |
| `|∘²` | SquaredNorm | 32 | 0 | 0 | 264 | 32/512 |
| `|` | 2 Norm | 64 | 0 | 2 | 264 | 64/3328 |
| `^∙` | Unitize | 64 | 1 | 1 | 512 | 64/1024 |
| `^∘` | Unitize | 64 | 1 | 1 | 512 | 64/1024 |
| `^` | Unitize | 64 | 1 | 1 | 512 | 64/1024 |
| `⊖` | ConstantProduct | 0 | 0 | 0 | 512 | 0/512 |
| `{}` | Permutation | 0 | 0 | 0 | 512 | 0/776 |
| `{}` | Permutation | 0 | 0 | 0 | 512 | 0/776 |
| `■` | Permutation | 0 | 0 | 0 | 512 | 0/512 |
| `□` | Permutation | 0 | 0 | 0 | 512 | 0/512 |
| `|■` | Norm | 32 | 0 | 1 | 264 | 32/1280 |
| `|□` | Norm | 32 | 0 | 1 | 264 | 32/1280 |
| `⊟` | ConstantProduct | 0 | 0 | 0 | 512 | 0/512 |
| `⊞` | ConstantProduct | 0 | 0 | 0 | 512 | 243/2048 |
| `⊙` | Center | 162 | 0 | 0 | 512 | 486/3584 |
| `⊡` | Container | 162 | 0 | 0 | 512 | 243/2560 |
| `⊛` | Permutation + Container + JoinCarrier | 324 | 0 | 0 | 512 | 518/30720 |

## rga3d

This algebra has 3 dimensions, a rigid metric and a 64-byte multivector. The inspector took the
counts on 2026-09-28, on linux amd64, 4 cores, with nim `27763495bcfe265507ca98aedc1c7064bf1e0e4d`,
pga `bd6b23c590d7e1da91a1ea288a1a4b94dedbf315` and flags `-d:release`. The bench ran 5 times on
2026-09-30, on linux amd64, 4 cores, over 40 rounds of 1024 objects each. Each time is the median of
those runs. The allocation gauge was live.
Gaps: 40. Over 17, met 23, unmeasured 0.

| Id | Measurand | Mul | Div | Bytes | Int | Chk | ns | Status |
|----|-----------|-----|-----|-------|-----|-----|----|--------|
| G233 | wedge | 27/– | 0/– | 192/– | 0/– | 0/– | 8.9/– | met |
| G234 | wedge_anti | 27/– | 0/– | 192/– | 0/– | 0/– | 9.5/– | met |
| G235 | wedge_dot | 48/– | 0/– | 192/– | 0/– | 0/– | 28.9/– | met |
| G236 | wedge_dot_anti | 48/– | 0/– | 192/– | 0/– | 0/– | 29.2/– | met |
| G237 | dot | 4/– | 0/– | 192/– | 0/– | 0/– | 13.7/– | met |
| G238 | dot_anti | 4/– | 0/– | 192/– | 0/– | 0/– | 9.7/– | met |
| G239 | contract_bulk | 18/– | 0/– | 192/– | 0/– | 0/– | 15.4/– | met |
| G240 | contract_weight | 9/– | 0/– | 192/– | 0/– | 0/– | 13.4/– | met |
| G241 | expand_bulk | 9/– | 0/– | 192/– | 0/– | 0/– | 12.9/– | met |
| G242 | expand_weight | 18/– | 0/– | 192/– | 0/– | 0/– | 16.1/– | met |
| G243 | add | 0/– | 0/– | 256/– | 0/– | 0/– | 13.3/– | over |
| G244 | subtract | 0/– | 0/– | 256/– | 0/– | 0/– | 11.9/– | over |
| G245 | project_central | 36/– | 0/– | 576/– | 2/– | 2/– | 22.0/– | over |
| G246 | project_central_anti | 45/– | 0/– | 576/– | 2/– | 2/– | 23.4/– | over |
| G247 | project_orthogonal | 45/– | 0/– | 576/– | 2/– | 2/– | 23.7/– | over |
| G248 | project_orthogonal_anti | 36/– | 0/– | 576/– | 2/– | 2/– | 22.3/– | over |
| G249 | scale | 8/– | 0/– | 136/– | 0/– | 0/– | 14.6/– | met |
| G250 | bulk | 0/– | 0/– | 128/– | 0/– | 0/– | 2.5/– | met |
| G251 | weight | 0/– | 0/– | 128/– | 0/– | 0/– | 4.4/– | met |
| G252 | complement_right | 0/– | 0/– | 128/– | 0/– | 0/– | 2.9/– | met |
| G253 | complement_left | 0/– | 0/– | 128/– | 0/– | 0/– | 2.9/– | met |
| G254 | reverse | 0/– | 0/– | 128/– | 0/– | 0/– | 3.2/– | met |
| G255 | reverse_anti | 0/– | 0/– | 128/– | 0/– | 0/– | 1.8/– | met |
| G256 | dual_bulk | 0/– | 0/– | 128/– | 0/– | 0/– | 3.8/– | met |
| G257 | dual_weight | 0/– | 0/– | 128/– | 0/– | 0/– | 3.4/– | met |
| G258 | negate | 0/– | 0/– | 192/– | 0/– | 0/– | 4.8/– | over |
| G259 | norm_bulk | 4/– | 0/– | 320/– | 1/– | 1/– | 9.4/– | over |
| G260 | norm_weight | 4/– | 0/– | 320/– | 1/– | 1/– | 9.7/– | over |
| G326 | norm_bulk_squared | 4/– | 0/– | 128/– | 0/– | 0/– | 4.6/– | met |
| G327 | norm_weight_squared | 4/– | 0/– | 128/– | 0/– | 0/– | 3.6/– | met |
| G261 | norm | 8/– | 0/– | 832/– | 4/– | 4/– | 10.0/– | over |
| G262 | normalize_bulk | 12/– | 1/– | 256/– | 1/– | 1/– | 7.4/– | over |
| G263 | normalize_weight | 12/– | 1/– | 256/– | 1/– | 1/– | 5.4/– | over |
| G264 | unitize | 12/– | 1/– | 256/– | 1/– | 1/– | 5.4/– | over |
| G265 | attitude | 0/– | 0/– | 128/– | 0/– | 0/– | 2.8/– | met |
| G266 | select_grade | 0/– | 0/– | 200/– | 0/– | 0/– | 4.8/– | over |
| G267 | select_grade_anti | 0/– | 0/– | 200/– | 0/– | 1/– | 5.4/– | over |
| G268 | select_part | – | – | – | – | – | 0.7/– | met |
| G269 | support | 54/– | 0/– | 640/– | 3/– | 3/– | 13.8/– | over |
| G270 | support_anti | 54/– | 0/– | 896/– | 3/– | 4/– | 19.1/– | over |

### Multivector lower bound

| Op | Shape | Mul | Div | Roots | Bytes | Library mul/bytes |
|----|-------|-----|-----|-------|-------|-------------------|
| `∧` | Wedge | 27 | 0 | 0 | 192 | 27/192 |
| `∨` | Wedge | 27 | 0 | 0 | 192 | 27/192 |
| `⟑` | Geometric | 48 | 0 | 0 | 192 | 48/192 |
| `⟇` | Geometric | 48 | 0 | 0 | 192 | 48/192 |
| `∙` | ScalarForm | 4 | 0 | 0 | 136 | 4/192 |
| `∘` | ScalarForm | 4 | 0 | 0 | 136 | 4/192 |
| `∨★` | ContractBulk | 18 | 0 | 0 | 192 | 18/192 |
| `∨☆` | ContractWeight | 9 | 0 | 0 | 192 | 9/192 |
| `∧★` | ExpandBulk | 9 | 0 | 0 | 192 | 9/192 |
| `∧☆` | ExpandWeight | 18 | 0 | 0 | 192 | 18/192 |
| `+` | Componentwise | 0 | 0 | 0 | 192 | 0/256 |
| `-` | Componentwise | 0 | 0 | 0 | 192 | 0/256 |
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
| `-` | Permutation | 0 | 0 | 0 | 128 | 0/192 |
| `|∙` | Norm | 4 | 0 | 1 | 72 | 4/320 |
| `|∘` | Norm | 4 | 0 | 1 | 72 | 4/320 |
| `|∙²` | SquaredNorm | 4 | 0 | 0 | 72 | 4/128 |
| `|∘²` | SquaredNorm | 4 | 0 | 0 | 72 | 4/128 |
| `|` | 2 Norm | 8 | 0 | 2 | 72 | 8/832 |
| `^∙` | Unitize | 12 | 1 | 1 | 128 | 12/256 |
| `^∘` | Unitize | 12 | 1 | 1 | 128 | 12/256 |
| `^` | Unitize | 12 | 1 | 1 | 128 | 12/256 |
| `⊖` | ConstantProduct | 0 | 0 | 0 | 128 | 0/128 |
| `{}` | Permutation | 0 | 0 | 0 | 128 | 0/200 |
| `{}` | Permutation | 0 | 0 | 0 | 128 | 0/200 |
| `∩` | Support | 18 | 0 | 0 | 128 | 54/640 |
| `∪` | SupportAnti | 18 | 0 | 0 | 128 | 54/896 |

## cga4d

This algebra has 4 dimensions, a conformal metric and a 128-byte multivector. The inspector took the
counts on 2026-09-28, on linux amd64, 4 cores, with nim `27763495bcfe265507ca98aedc1c7064bf1e0e4d`,
pga `bd6b23c590d7e1da91a1ea288a1a4b94dedbf315` and flags `-d:release`. The bench ran 5 times on
2026-09-30, on linux amd64, 4 cores, over 40 rounds of 1024 objects each. Each time is the median of
those runs. The allocation gauge was live.
Gaps: 47. Over 21, met 26, unmeasured 0.

| Id | Measurand | Mul | Div | Bytes | Int | Chk | ns | Status |
|----|-----------|-----|-----|-------|-----|-----|----|--------|
| G271 | wedge | 81/– | 0/– | 384/– | 0/– | 0/– | 35.6/– | met |
| G272 | wedge_anti | 81/– | 0/– | 384/– | 0/– | 0/– | 37.9/– | met |
| G273 | wedge_dot | 256/– | 0/– | 384/– | 0/– | 0/– | 145.3/– | met |
| G274 | wedge_dot_anti | 256/– | 0/– | 384/– | 0/– | 0/– | 151.7/– | met |
| G275 | dot | 16/– | 0/– | 384/– | 0/– | 0/– | 17.5/– | met |
| G276 | dot_anti | 16/– | 0/– | 384/– | 0/– | 0/– | 16.3/– | met |
| G277 | contract_bulk | 81/– | 0/– | 384/– | 0/– | 0/– | 50.9/– | met |
| G278 | contract_weight | 81/– | 0/– | 384/– | 0/– | 0/– | 50.5/– | met |
| G279 | expand_bulk | 81/– | 0/– | 384/– | 0/– | 0/– | 43.2/– | met |
| G280 | expand_weight | 81/– | 0/– | 384/– | 0/– | 0/– | 43.1/– | met |
| G281 | add | 0/– | 0/– | 512/– | 0/– | 0/– | 24.2/– | over |
| G282 | subtract | 0/– | 0/– | 512/– | 0/– | 0/– | 25.1/– | over |
| G283 | project_central | 162/– | 0/– | 1152/– | 2/– | 2/– | 89.8/– | over |
| G284 | project_central_anti | 162/– | 0/– | 1152/– | 2/– | 2/– | 83.4/– | over |
| G285 | project_orthogonal | 162/– | 0/– | 1152/– | 2/– | 2/– | 95.3/– | over |
| G286 | project_orthogonal_anti | 162/– | 0/– | 1152/– | 2/– | 2/– | 95.0/– | over |
| G287 | scale | 16/– | 0/– | 264/– | 0/– | 0/– | 17.3/– | met |
| G288 | bulk | 0/– | 0/– | 256/– | 0/– | 0/– | 8.4/– | met |
| G289 | weight | 0/– | 0/– | 256/– | 0/– | 0/– | 9.0/– | met |
| G290 | complement_right | 0/– | 0/– | 256/– | 0/– | 0/– | 5.3/– | met |
| G291 | complement_left | 0/– | 0/– | 256/– | 0/– | 0/– | 6.9/– | met |
| G292 | reverse | 0/– | 0/– | 256/– | 0/– | 0/– | 7.2/– | met |
| G293 | reverse_anti | 0/– | 0/– | 256/– | 0/– | 0/– | 5.3/– | met |
| G294 | dual_bulk | 0/– | 0/– | 256/– | 0/– | 0/– | 5.3/– | met |
| G295 | dual_weight | 0/– | 0/– | 256/– | 0/– | 0/– | 5.6/– | met |
| G296 | negate | 0/– | 0/– | 384/– | 0/– | 0/– | 14.0/– | over |
| G297 | norm_bulk | 16/– | 0/– | 640/– | 1/– | 1/– | 13.2/– | over |
| G298 | norm_weight | 16/– | 0/– | 640/– | 1/– | 1/– | 13.5/– | over |
| G328 | norm_bulk_squared | 16/– | 0/– | 256/– | 0/– | 0/– | 8.5/– | met |
| G329 | norm_weight_squared | 16/– | 0/– | 256/– | 0/– | 0/– | 8.4/– | met |
| G299 | norm | 32/– | 0/– | 1664/– | 4/– | 4/– | 15.4/– | over |
| G300 | normalize_bulk | 32/– | 1/– | 512/– | 1/– | 1/– | 31.3/– | over |
| G301 | normalize_weight | 32/– | 1/– | 512/– | 1/– | 1/– | 19.4/– | over |
| G302 | unitize | 32/– | 1/– | 512/– | 1/– | 1/– | 20.8/– | over |
| G303 | attitude | 0/– | 0/– | 256/– | 0/– | 0/– | 8.4/– | met |
| G304 | select_grade | 0/– | 0/– | 392/– | 0/– | 0/– | 14.8/– | over |
| G305 | select_grade_anti | 0/– | 0/– | 392/– | 0/– | 1/– | 18.7/– | over |
| G306 | select_part | – | – | – | – | – | 0.7/– | met |
| G307 | bulk_flat | 0/– | 0/– | 256/– | 0/– | 0/– | 6.6/– | met |
| G308 | weight_flat | 0/– | 0/– | 256/– | 0/– | 0/– | 7.7/– | met |
| G309 | norm_bulk_flat | 16/– | 0/– | 640/– | 1/– | 1/– | 13.2/– | over |
| G310 | norm_weight_flat | 16/– | 0/– | 640/– | 1/– | 1/– | 13.7/– | over |
| G311 | carrier | 0/– | 0/– | 256/– | 0/– | 0/– | 6.8/– | met |
| G312 | carrier_co | 81/– | 0/– | 1024/– | 2/– | 2/– | 32.4/– | over |
| G313 | center | 162/– | 0/– | 1792/– | 4/– | 4/– | 102.6/– | over |
| G314 | container | 81/– | 0/– | 1280/– | 3/– | 3/– | 54.1/– | over |
| G315 | partner | 178/– | 0/– | 9216/– | 8/– | 143/– | 130.8/– | over |

### Multivector lower bound

| Op | Shape | Mul | Div | Roots | Bytes | Library mul/bytes |
|----|-------|-----|-----|-------|-------|-------------------|
| `∧` | Wedge | 81 | 0 | 0 | 384 | 81/384 |
| `∨` | Wedge | 81 | 0 | 0 | 384 | 81/384 |
| `⟑` | Geometric | 256 | 0 | 0 | 384 | 256/384 |
| `⟇` | Geometric | 256 | 0 | 0 | 384 | 256/384 |
| `∙` | ScalarForm | 16 | 0 | 0 | 264 | 16/384 |
| `∘` | ScalarForm | 16 | 0 | 0 | 264 | 16/384 |
| `∨★` | ContractBulk | 81 | 0 | 0 | 384 | 81/384 |
| `∨☆` | ContractWeight | 81 | 0 | 0 | 384 | 81/384 |
| `∧★` | ExpandBulk | 81 | 0 | 0 | 384 | 81/384 |
| `∧☆` | ExpandWeight | 81 | 0 | 0 | 384 | 81/384 |
| `+` | Componentwise | 0 | 0 | 0 | 384 | 0/512 |
| `-` | Componentwise | 0 | 0 | 0 | 384 | 0/512 |
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
| `-` | Permutation | 0 | 0 | 0 | 256 | 0/384 |
| `|∙` | Norm | 16 | 0 | 1 | 136 | 16/640 |
| `|∘` | Norm | 16 | 0 | 1 | 136 | 16/640 |
| `|∙²` | SquaredNorm | 16 | 0 | 0 | 136 | 16/256 |
| `|∘²` | SquaredNorm | 16 | 0 | 0 | 136 | 16/256 |
| `|` | 2 Norm | 32 | 0 | 2 | 136 | 32/1664 |
| `^∙` | Unitize | 32 | 1 | 1 | 256 | 32/512 |
| `^∘` | Unitize | 32 | 1 | 1 | 256 | 32/512 |
| `^` | Unitize | 32 | 1 | 1 | 256 | 32/512 |
| `⊖` | ConstantProduct | 0 | 0 | 0 | 256 | 0/256 |
| `{}` | Permutation | 0 | 0 | 0 | 256 | 0/392 |
| `{}` | Permutation | 0 | 0 | 0 | 256 | 0/392 |
| `■` | Permutation | 0 | 0 | 0 | 256 | 0/256 |
| `□` | Permutation | 0 | 0 | 0 | 256 | 0/256 |
| `|■` | Norm | 16 | 0 | 1 | 136 | 16/640 |
| `|□` | Norm | 16 | 0 | 1 | 136 | 16/640 |
| `⊟` | ConstantProduct | 0 | 0 | 0 | 256 | 0/256 |
| `⊞` | ConstantProduct | 0 | 0 | 0 | 256 | 81/1024 |
| `⊙` | Center | 54 | 0 | 0 | 256 | 162/1792 |
| `⊡` | Container | 54 | 0 | 0 | 256 | 81/1280 |
| `⊛` | Permutation + Container + JoinCarrier | 108 | 0 | 0 | 256 | 178/9216 |
