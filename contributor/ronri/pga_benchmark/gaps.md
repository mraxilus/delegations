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

Each algebra below carries a floor table. The floor is what the algebra demands of any dense
implementation, and it is derived from the axioms rather than measured. A floor spends no zero fill,
no intermediate, no error check and no allocation. It moves its operands read once plus its result
written once. The floor rests on the operation alone, so one row serves every measurand that spells
that operation.

The last column of a floor table is what the library spends on that operation, as multiplies over
bytes moved. An operation whose shape carries no rule yet is absent from the table, rather than
present with a number that has no ground.

## Causes

- **D01, over.** Dense products spend every Cayley-table term where typed forms spend few. Evidence:
  84 gaps. The widest is cga5d/partner_round_point, which spends 1004 multiplies against 10. Closes
  when no typed gap spends more multiplies than its reference.
- **D02, over.** Library calls run slower than typed forms beyond the band. Evidence: 155 gaps. The
  worst is cga5d/partner_sphere, at 278.5 ns against 2.1 ns. Closes when no gap's library median
  exceeds 1.25 times its reference's.
- **D03, over.** Operators zero-fill their full-width result before they write it. Evidence: 174 of
  188 library functions. The most is cga5d `⊛(Multivector)` with 119. Closes when no library
  function calls `nimZeroMem`.
- **D04, over.** Operator chains build full-width intermediates. Evidence: 58 of 188 library
  functions. The most is cga5d `⊛(Multivector)` with 10. Closes when no library function declares a
  local multivector.
- **D05, over.** Error-flag checks survive into release builds. Evidence: 70 of 188 library
  functions. The most is cga5d `⊛(Multivector)` with 273. Closes when no library function branches
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
counts on 2026-09-22, on linux amd64, 4 cores, with nim `27763495bcfe265507ca98aedc1c7064bf1e0e4d`,
pga `9f9019b26b46490f79f383eee693b1abc84a4f63` and flags `-d:release`. The bench ran on 2026-09-22,
on linux amd64, 4 cores, over 40 rounds of 1024 objects. The allocation gauge was live.
Gaps: 111. Over 110, met 1, unmeasured 0.

| Id | Measurand | Mul | Div | Bytes | Int | Chk | ns | Status |
|----|-----------|-----|-----|-------|-----|-----|----|--------|
| G001 | wedge | 81/– | 0/– | 512/– | 0/– | 0/– | 20.3/– | over |
| G002 | wedge_anti | 81/– | 0/– | 512/– | 0/– | 0/– | 36.1/– | over |
| G003 | wedge_dot | 192/– | 0/– | 512/– | 0/– | 0/– | 74.2/– | over |
| G004 | wedge_dot_anti | 192/– | 0/– | 512/– | 0/– | 0/– | 72.6/– | over |
| G005 | dot | 8/– | 0/– | 512/– | 0/– | 0/– | 14.6/– | over |
| G006 | dot_anti | 8/– | 0/– | 512/– | 0/– | 0/– | 14.5/– | over |
| G007 | contract_bulk | 54/– | 0/– | 512/– | 0/– | 0/– | 15.7/– | over |
| G008 | contract_weight | 27/– | 0/– | 512/– | 0/– | 0/– | 17.9/– | over |
| G009 | expand_bulk | 27/– | 0/– | 512/– | 0/– | 0/– | 18.8/– | over |
| G010 | expand_weight | 54/– | 0/– | 512/– | 0/– | 0/– | 19.8/– | over |
| G011 | add | 0/– | 0/– | 512/– | 0/– | 0/– | 16.3/– | over |
| G012 | subtract | 0/– | 0/– | 512/– | 0/– | 0/– | 16.6/– | over |
| G013 | project_central | 108/– | 0/– | 1408/– | 2/– | 2/– | 61.0/– | over |
| G014 | project_central_anti | 135/– | 0/– | 1408/– | 2/– | 2/– | 49.4/– | over |
| G015 | project_orthogonal | 135/– | 0/– | 1408/– | 2/– | 2/– | 53.2/– | over |
| G016 | project_orthogonal_anti | 108/– | 0/– | 1408/– | 2/– | 2/– | 50.0/– | over |
| G017 | scale | 16/– | 0/– | 392/– | 0/– | 0/– | 15.6/– | over |
| G018 | bulk | 0/– | 0/– | 384/– | 0/– | 0/– | 12.5/– | over |
| G019 | weight | 0/– | 0/– | 384/– | 0/– | 0/– | 12.8/– | over |
| G020 | complement_right | 0/– | 0/– | 384/– | 0/– | 0/– | 14.0/– | over |
| G021 | complement_left | 0/– | 0/– | 384/– | 0/– | 0/– | 14.4/– | over |
| G022 | reverse | 0/– | 0/– | 384/– | 0/– | 0/– | 14.3/– | over |
| G023 | reverse_anti | 0/– | 0/– | 384/– | 0/– | 0/– | 14.1/– | over |
| G024 | dual_bulk | 0/– | 0/– | 384/– | 0/– | 0/– | 12.5/– | over |
| G025 | dual_weight | 0/– | 0/– | 384/– | 0/– | 0/– | 12.9/– | over |
| G026 | negate | 0/– | 0/– | 384/– | 0/– | 0/– | 14.4/– | over |
| G027 | norm_bulk | 8/– | 0/– | 768/– | 1/– | 1/– | 15.4/– | over |
| G028 | norm_weight | 8/– | 0/– | 768/– | 1/– | 1/– | 15.3/– | over |
| G316 | norm_bulk_squared | 8/– | 0/– | 384/– | 0/– | 0/– | 13.5/– | over |
| G317 | norm_weight_squared | 8/– | 0/– | 384/– | 0/– | 0/– | 16.5/– | over |
| G029 | norm | 16/– | 0/– | 1920/– | 4/– | 4/– | 64.9/– | over |
| G030 | normalize_bulk | 24/– | 1/– | 1152/– | 2/– | 18/– | 30.4/– | over |
| G031 | normalize_weight | 24/– | 1/– | 1152/– | 2/– | 18/– | 30.2/– | over |
| G032 | unitize | 24/– | 1/– | 1152/– | 2/– | 18/– | 30.5/– | over |
| G033 | attitude | 81/– | 0/– | 896/– | 1/– | 1/– | 22.1/– | over |
| G034 | select_grade | 0/– | 0/– | 392/– | 0/– | 0/– | 14.6/– | over |
| G035 | select_grade_anti | 0/– | 0/– | 392/– | 0/– | 1/– | 20.0/– | over |
| G036 | select_part | – | – | – | – | – | 0.9/– | met |
| G037 | support | 162/– | 0/– | 1664/– | 3/– | 3/– | 88.2/– | over |
| G038 | support_anti | 162/– | 0/– | 1664/– | 3/– | 3/– | 87.1/– | over |
| G039 | wedge_point_point | 81/12 | 0/0 | 512/112 | 0/0 | 0/0 | 40.4/3.8 | over |
| G040 | wedge_line_point | 81/12 | 0/0 | 512/112 | 0/0 | 0/0 | 41.1/6.1 | over |
| G041 | wedge_point_line | 81/12 | 0/0 | 512/144 | 0/0 | 0/1 | 40.6/6.8 | over |
| G042 | wedge_anti_plane_plane | 81/12 | 0/0 | 512/112 | 0/0 | 0/0 | 36.4/4.1 | over |
| G043 | wedge_anti_plane_line | 81/12 | 0/0 | 512/112 | 0/0 | 0/0 | 36.4/6.2 | over |
| G044 | wedge_anti_line_plane | 81/12 | 0/0 | 512/144 | 0/0 | 0/1 | 35.7/6.6 | over |
| G045 | wedge_anti_line_line | 81/6 | 0/0 | 512/104 | 0/0 | 0/2 | 35.7/4.0 | over |
| G046 | wedge_anti_point_plane | 81/4 | 0/0 | 512/72 | 0/0 | 0/0 | 35.7/3.5 | over |
| G047 | dot_point_point | 8/3 | 0/0 | 512/72 | 0/0 | 0/0 | 14.3/3.5 | over |
| G048 | dot_line_line | 8/3 | 0/0 | 512/104 | 0/0 | 0/1 | 18.7/3.6 | over |
| G049 | dot_plane_plane | 8/1 | 0/0 | 512/72 | 0/0 | 0/0 | 14.7/3.5 | over |
| G050 | dot_anti_point_point | 8/1 | 0/0 | 512/72 | 0/0 | 0/0 | 14.6/3.5 | over |
| G051 | dot_anti_line_line | 8/3 | 0/0 | 512/104 | 0/0 | 0/1 | 14.6/3.5 | over |
| G052 | dot_anti_plane_plane | 8/3 | 0/0 | 512/72 | 0/0 | 0/0 | 14.8/3.5 | over |
| G053 | wedge_dot_anti_motor_motor | 192/48 | 0/0 | 512/256 | 0/0 | 0/0 | 72.3/16.0 | over |
| G054 | transform_point_motor | –/25 | –/0 | –/192 | –/0 | –/8 | 156.2/7.7 | over |
| G055 | transform_line_motor | –/57 | –/0 | –/400 | –/0 | –/23 | 156.5/14.3 | over |
| G056 | transform_plane_motor | –/36 | –/0 | –/256 | –/0 | –/15 | 155.5/12.8 | over |
| G057 | project_orthogonal_point_plane | 135/14 | 0/0 | 1408/128 | 2/0 | 2/0 | 53.4/4.9 | over |
| G058 | project_orthogonal_point_line | 135/19 | 0/0 | 1408/176 | 2/0 | 2/2 | 53.4/6.1 | over |
| G059 | project_orthogonal_line_plane | 135/27 | 0/0 | 1408/224 | 2/0 | 2/10 | 53.4/7.3 | over |
| G060 | support_line | 162/9 | 0/0 | 1664/112 | 3/0 | 3/1 | 65.9/2.4 | over |
| G061 | support_plane | 162/6 | 0/0 | 1664/64 | 3/0 | 3/0 | 66.3/1.9 | over |
| G062 | support_anti_point | 162/6 | 0/0 | 1664/64 | 3/0 | 3/0 | 81.5/1.9 | over |
| G063 | support_anti_line | 162/9 | 0/0 | 1664/112 | 3/0 | 3/1 | 84.2/2.4 | over |
| G064 | reverse_anti_motor | 0/0 | 0/0 | 384/256 | 0/0 | 0/2 | 14.2/4.0 | over |
| G065 | unitize_motor | 24/12 | 1/1 | 1152/320 | 2/0 | 18/4 | 30.3/14.7 | over |
| G066 | norm_weight_motor | 8/4 | 0/0 | 768/72 | 1/0 | 1/2 | 15.3/1.8 | over |
| G067 | norm_bulk_motor | 8/4 | 0/0 | 768/72 | 1/0 | 1/2 | 15.0/2.1 | over |
| G068 | complement_right_point | 0/0 | 0/0 | 384/64 | 0/0 | 0/0 | 14.2/0.8 | over |
| G069 | complement_left_point | 0/0 | 0/0 | 384/64 | 0/0 | 0/0 | 14.3/2.0 | over |
| G070 | reverse_point | 0/0 | 0/0 | 384/96 | 0/0 | 0/0 | 13.6/0.8 | over |
| G071 | reverse_anti_point | 0/0 | 0/0 | 384/96 | 0/0 | 0/0 | 14.1/1.9 | over |
| G072 | dual_bulk_point | 0/0 | 0/0 | 384/64 | 0/0 | 0/0 | 16.2/1.3 | over |
| G073 | dual_weight_point | 0/0 | 0/0 | 384/64 | 0/0 | 0/0 | 16.1/2.2 | over |
| G074 | bulk_point | 0/0 | 0/0 | 384/96 | 0/0 | 0/0 | 15.6/2.2 | over |
| G075 | weight_point | 0/0 | 0/0 | 384/96 | 0/0 | 0/0 | 15.7/2.0 | over |
| G076 | norm_bulk_point | 8/3 | 0/0 | 768/40 | 1/0 | 1/1 | 18.2/2.1 | over |
| G077 | norm_weight_point | 8/0 | 0/0 | 768/40 | 1/0 | 1/0 | 14.0/0.6 | over |
| G318 | norm_bulk_squared_point | 8/3 | 0/0 | 384/40 | 0/0 | 0/0 | 13.6/0.8 | over |
| G319 | norm_weight_squared_point | 8/– | 0/– | 384/– | 0/– | 0/– | 13.5/0.6 | over |
| G078 | unitize_point | 24/3 | 1/1 | 1152/128 | 2/0 | 18/0 | 30.0/2.0 | over |
| G079 | attitude_point | 81/0 | 0/0 | 896/40 | 1/0 | 1/0 | 21.8/0.6 | over |
| G080 | complement_right_line | 0/0 | 0/0 | 384/192 | 0/0 | 0/2 | 14.4/4.0 | over |
| G081 | complement_left_line | 0/0 | 0/0 | 384/192 | 0/0 | 0/2 | 14.3/4.0 | over |
| G082 | reverse_line | 0/0 | 0/0 | 384/192 | 0/0 | 0/2 | 14.0/4.0 | over |
| G083 | reverse_anti_line | 0/0 | 0/0 | 384/192 | 0/0 | 0/2 | 14.2/4.0 | over |
| G084 | dual_bulk_line | 0/0 | 0/0 | 384/192 | 0/0 | 0/1 | 12.7/2.6 | over |
| G085 | dual_weight_line | 0/0 | 0/0 | 384/192 | 0/0 | 0/1 | 13.2/1.5 | over |
| G086 | bulk_line | 0/0 | 0/0 | 384/144 | 0/0 | 0/0 | 12.5/2.6 | over |
| G087 | weight_line | 0/0 | 0/0 | 384/144 | 0/0 | 0/0 | 13.4/2.6 | over |
| G088 | norm_bulk_line | 8/3 | 0/0 | 768/56 | 1/0 | 1/2 | 14.1/2.1 | over |
| G089 | norm_weight_line | 8/3 | 0/0 | 768/56 | 1/0 | 1/2 | 14.6/2.1 | over |
| G320 | norm_bulk_squared_line | 8/3 | 0/0 | 384/56 | 0/0 | 0/1 | 13.9/0.9 | over |
| G321 | norm_weight_squared_line | 8/– | 0/– | 384/– | 0/– | 0/– | 13.5/0.9 | over |
| G090 | unitize_line | 24/9 | 1/1 | 1152/240 | 2/0 | 18/4 | 29.8/13.9 | over |
| G091 | attitude_line | 81/0 | 0/0 | 896/80 | 1/0 | 1/0 | 21.8/1.0 | over |
| G092 | complement_right_plane | 0/0 | 0/0 | 384/64 | 0/0 | 0/0 | 14.1/2.0 | over |
| G093 | complement_left_plane | 0/0 | 0/0 | 384/64 | 0/0 | 0/0 | 14.9/0.8 | over |
| G094 | reverse_plane | 0/0 | 0/0 | 384/96 | 0/0 | 0/0 | 14.0/2.0 | over |
| G095 | reverse_anti_plane | 0/0 | 0/0 | 384/96 | 0/0 | 0/0 | 14.2/0.8 | over |
| G096 | dual_bulk_plane | 0/0 | 0/0 | 384/64 | 0/0 | 0/0 | 13.0/2.1 | over |
| G097 | dual_weight_plane | 0/0 | 0/0 | 384/64 | 0/0 | 0/0 | 13.0/1.1 | over |
| G098 | bulk_plane | 0/0 | 0/0 | 384/96 | 0/0 | 0/0 | 12.8/2.2 | over |
| G099 | weight_plane | 0/0 | 0/0 | 384/96 | 0/0 | 0/0 | 12.9/2.1 | over |
| G100 | norm_bulk_plane | 8/0 | 0/0 | 768/40 | 1/0 | 1/0 | 14.4/0.6 | over |
| G101 | norm_weight_plane | 8/3 | 0/0 | 768/40 | 1/0 | 1/1 | 14.4/2.1 | over |
| G322 | norm_bulk_squared_plane | 8/1 | 0/0 | 384/40 | 0/0 | 0/0 | 14.1/0.7 | over |
| G323 | norm_weight_squared_plane | 8/– | 0/– | 384/– | 0/– | 0/– | 13.9/0.8 | over |
| G102 | unitize_plane | 24/7 | 1/1 | 1152/160 | 2/0 | 18/1 | 30.4/14.8 | over |
| G103 | attitude_plane | 81/0 | 0/0 | 896/80 | 1/0 | 1/0 | 22.7/2.1 | over |

### Floor

| Op | Shape | Mul | Div | Roots | Bytes | Library mul/bytes |
|----|-------|-----|-----|-------|-------|-------------------|
| `∧` | Wedge | 81 | 0 | 0 | 384 | 81/512 |
| `∨` | Wedge | 81 | 0 | 0 | 384 | 81/512 |
| `⟑` | Geometric | 192 | 0 | 0 | 384 | 192/512 |
| `⟇` | Geometric | 192 | 0 | 0 | 384 | 192/512 |
| `∙` | ScalarForm | 8 | 0 | 0 | 264 | 8/512 |
| `∘` | ScalarForm | 8 | 0 | 0 | 264 | 8/512 |
| `∨★` | ContractBulk | 54 | 0 | 0 | 384 | 54/512 |
| `∨☆` | ContractWeight | 27 | 0 | 0 | 384 | 27/512 |
| `∧★` | ExpandBulk | 27 | 0 | 0 | 384 | 27/512 |
| `∧☆` | ExpandWeight | 54 | 0 | 0 | 384 | 54/512 |
| `+` | Componentwise | 0 | 0 | 0 | 384 | 0/512 |
| `-` | Componentwise | 0 | 0 | 0 | 384 | 0/512 |
| `∧` | Scale | 16 | 0 | 0 | 264 | 16/392 |
| `∙` | Permutation | 0 | 0 | 0 | 256 | 0/384 |
| `∘` | Permutation | 0 | 0 | 0 | 256 | 0/384 |
| `/` | Permutation | 0 | 0 | 0 | 256 | 0/384 |
| `\` | Permutation | 0 | 0 | 0 | 256 | 0/384 |
| `~` | Permutation | 0 | 0 | 0 | 256 | 0/384 |
| `~∘` | Permutation | 0 | 0 | 0 | 256 | 0/384 |
| `★` | Permutation | 0 | 0 | 0 | 256 | 0/384 |
| `☆` | Permutation | 0 | 0 | 0 | 256 | 0/384 |
| `-` | Permutation | 0 | 0 | 0 | 256 | 0/384 |
| `|∙` | Norm | 8 | 0 | 1 | 136 | 8/768 |
| `|∘` | Norm | 8 | 0 | 1 | 136 | 8/768 |
| `|∙²` | SquaredNorm | 8 | 0 | 0 | 136 | 8/384 |
| `|∘²` | SquaredNorm | 8 | 0 | 0 | 136 | 8/384 |
| `^∙` | Unitize | 24 | 1 | 1 | 256 | 24/1152 |
| `^∘` | Unitize | 24 | 1 | 1 | 256 | 24/1152 |
| `^` | Unitize | 24 | 1 | 1 | 256 | 24/1152 |
| `⊖` | Attitude | 0 | 0 | 0 | 256 | 81/896 |
| `{}` | Permutation | 0 | 0 | 0 | 256 | 0/392 |

## cga5d

This algebra has 5 dimensions, a conformal metric and a 256-byte multivector. The inspector took the
counts on 2026-09-22, on linux amd64, 4 cores, with nim `27763495bcfe265507ca98aedc1c7064bf1e0e4d`,
pga `9f9019b26b46490f79f383eee693b1abc84a4f63` and flags `-d:release`. The bench ran on 2026-09-22,
on linux amd64, 4 cores, over 40 rounds of 1024 objects. The allocation gauge was live.
Gaps: 131. Over 130, met 1, unmeasured 0.

| Id | Measurand | Mul | Div | Bytes | Int | Chk | ns | Status |
|----|-----------|-----|-----|-------|-----|-----|----|--------|
| G104 | wedge | 243/– | 0/– | 1024/– | 0/– | 0/– | 65.9/– | over |
| G105 | wedge_anti | 243/– | 0/– | 1024/– | 0/– | 0/– | 91.4/– | over |
| G106 | wedge_dot | 1024/– | 0/– | 1024/– | 0/– | 0/– | 330.3/– | over |
| G107 | wedge_dot_anti | 1024/– | 0/– | 1024/– | 0/– | 0/– | 335.6/– | over |
| G108 | dot | 32/– | 0/– | 1024/– | 0/– | 0/– | 20.5/– | over |
| G109 | dot_anti | 32/– | 0/– | 1024/– | 0/– | 0/– | 23.8/– | over |
| G110 | contract_bulk | 243/– | 0/– | 1024/– | 0/– | 0/– | 100.3/– | over |
| G111 | contract_weight | 243/– | 0/– | 1024/– | 0/– | 0/– | 101.8/– | over |
| G112 | expand_bulk | 243/– | 0/– | 1024/– | 0/– | 0/– | 94.5/– | over |
| G113 | expand_weight | 243/– | 0/– | 1024/– | 0/– | 0/– | 90.1/– | over |
| G114 | add | 0/– | 0/– | 1024/– | 0/– | 0/– | 21.7/– | over |
| G115 | subtract | 0/– | 0/– | 1024/– | 0/– | 0/– | 21.2/– | over |
| G116 | project_central | 486/– | 0/– | 2816/– | 2/– | 2/– | 184.0/– | over |
| G117 | project_central_anti | 486/– | 0/– | 2816/– | 2/– | 2/– | 167.5/– | over |
| G118 | project_orthogonal | 486/– | 0/– | 2816/– | 2/– | 2/– | 180.4/– | over |
| G119 | project_orthogonal_anti | 486/– | 0/– | 2816/– | 2/– | 2/– | 170.6/– | over |
| G120 | scale | 32/– | 0/– | 776/– | 0/– | 0/– | 16.3/– | over |
| G121 | bulk | 0/– | 0/– | 768/– | 0/– | 0/– | 12.5/– | over |
| G122 | weight | 0/– | 0/– | 768/– | 0/– | 0/– | 12.5/– | over |
| G123 | complement_right | 0/– | 0/– | 768/– | 0/– | 0/– | 16.3/– | over |
| G124 | complement_left | 0/– | 0/– | 768/– | 0/– | 0/– | 16.2/– | over |
| G125 | reverse | 0/– | 0/– | 768/– | 0/– | 0/– | 16.3/– | over |
| G126 | reverse_anti | 0/– | 0/– | 768/– | 0/– | 0/– | 16.8/– | over |
| G127 | dual_bulk | 0/– | 0/– | 768/– | 0/– | 0/– | 16.4/– | over |
| G128 | dual_weight | 0/– | 0/– | 768/– | 0/– | 0/– | 16.3/– | over |
| G129 | negate | 0/– | 0/– | 768/– | 0/– | 0/– | 16.4/– | over |
| G130 | norm_bulk | 32/– | 0/– | 1536/– | 1/– | 1/– | 20.9/– | over |
| G131 | norm_weight | 32/– | 0/– | 1536/– | 1/– | 1/– | 21.6/– | over |
| G324 | norm_bulk_squared | 32/– | 0/– | 768/– | 0/– | 0/– | 16.4/– | over |
| G325 | norm_weight_squared | 32/– | 0/– | 768/– | 0/– | 0/– | 16.1/– | over |
| G132 | norm | 64/– | 0/– | 3840/– | 4/– | 4/– | 75.0/– | over |
| G133 | normalize_bulk | 64/– | 1/– | 2304/– | 2/– | 34/– | 49.0/– | over |
| G134 | normalize_weight | 64/– | 1/– | 2304/– | 2/– | 34/– | 48.6/– | over |
| G135 | unitize | 64/– | 1/– | 2304/– | 2/– | 34/– | 49.3/– | over |
| G136 | attitude | 243/– | 0/– | 1792/– | 1/– | 1/– | 50.9/– | over |
| G137 | select_grade | 0/– | 0/– | 776/– | 0/– | 0/– | 15.4/– | over |
| G138 | select_grade_anti | 0/– | 0/– | 776/– | 0/– | 1/– | 16.3/– | over |
| G139 | select_part | – | – | – | – | – | 1.2/– | met |
| G140 | bulk_flat | 0/– | 0/– | 768/– | 0/– | 0/– | 12.6/– | over |
| G141 | weight_flat | 0/– | 0/– | 768/– | 0/– | 0/– | 12.5/– | over |
| G142 | norm_bulk_flat | 32/– | 0/– | 1536/– | 1/– | 1/– | 21.3/– | over |
| G143 | norm_weight_flat | 32/– | 0/– | 1536/– | 1/– | 1/– | 21.9/– | over |
| G144 | carrier | 243/– | 0/– | 1792/– | 1/– | 1/– | 47.0/– | over |
| G145 | carrier_co | 243/– | 0/– | 2560/– | 2/– | 2/– | 52.4/– | over |
| G146 | center | 486/– | 0/– | 4352/– | 4/– | 4/– | 137.4/– | over |
| G147 | container | 486/– | 0/– | 4352/– | 4/– | 4/– | 113.6/– | over |
| G148 | partner | 1004/– | 0/– | 34560/– | 10/– | 273/– | 271.8/– | over |
| G149 | wedge_round_point_round_point | 243/20 | 0/0 | 1024/160 | 0/0 | 0/0 | 85.1/5.0 | over |
| G150 | wedge_dipole_round_point | 243/30 | 0/0 | 1024/200 | 0/0 | 0/0 | 83.2/12.1 | over |
| G151 | wedge_round_point_dipole | 243/30 | 0/0 | 1024/280 | 0/0 | 0/1 | 85.1/11.8 | over |
| G152 | wedge_circle_round_point | 243/20 | 0/0 | 1024/160 | 0/0 | 0/0 | 87.6/6.6 | over |
| G153 | wedge_round_point_circle | 243/20 | 0/0 | 1024/160 | 0/0 | 0/0 | 117.0/9.7 | over |
| G154 | wedge_dipole_dipole | 243/30 | 0/0 | 1024/200 | 0/0 | 0/0 | 93.5/10.5 | over |
| G155 | wedge_anti_sphere_sphere | 243/20 | 0/0 | 1024/160 | 0/0 | 0/0 | 93.6/5.7 | over |
| G156 | wedge_anti_sphere_circle | 243/30 | 0/0 | 1024/200 | 0/0 | 0/0 | 91.2/12.4 | over |
| G157 | wedge_anti_circle_sphere | 243/30 | 0/0 | 1024/280 | 0/0 | 0/1 | 90.7/12.0 | over |
| G158 | wedge_anti_circle_circle | 243/30 | 0/0 | 1024/200 | 0/0 | 0/0 | 88.1/13.4 | over |
| G159 | wedge_anti_sphere_dipole | 243/20 | 0/0 | 1024/160 | 0/0 | 0/0 | 109.2/7.0 | over |
| G160 | wedge_anti_dipole_sphere | 243/20 | 0/0 | 1024/160 | 0/0 | 0/0 | 95.8/6.5 | over |
| G161 | dot_round_point_round_point | 32/5 | 0/0 | 1024/88 | 0/0 | 0/0 | 23.2/3.7 | over |
| G162 | dot_dipole_dipole | 32/10 | 0/0 | 1024/168 | 0/0 | 0/3 | 20.7/5.2 | over |
| G163 | dot_circle_circle | 32/10 | 0/0 | 1024/168 | 0/0 | 0/3 | 20.9/5.2 | over |
| G164 | dot_sphere_sphere | 32/5 | 0/0 | 1024/88 | 0/0 | 0/0 | 22.0/3.7 | over |
| G165 | dot_anti_round_point_round_point | 32/5 | 0/0 | 1024/88 | 0/0 | 0/1 | 23.2/3.7 | over |
| G166 | dot_anti_dipole_dipole | 32/10 | 0/0 | 1024/168 | 0/0 | 0/4 | 21.0/5.3 | over |
| G167 | dot_anti_circle_circle | 32/10 | 0/0 | 1024/168 | 0/0 | 0/4 | 20.7/5.3 | over |
| G168 | dot_anti_sphere_sphere | 32/5 | 0/0 | 1024/88 | 0/0 | 0/1 | 20.8/3.7 | over |
| G169 | complement_right_round_point | 0/0 | 0/0 | 768/80 | 0/0 | 0/0 | 16.3/2.1 | over |
| G170 | complement_left_round_point | 0/0 | 0/0 | 768/120 | 0/0 | 0/1 | 16.3/4.8 | over |
| G171 | reverse_round_point | 0/0 | 0/0 | 768/120 | 0/0 | 0/0 | 16.3/11.8 | over |
| G172 | reverse_anti_round_point | 0/0 | 0/0 | 768/120 | 0/0 | 0/0 | 16.1/11.8 | over |
| G173 | dual_bulk_round_point | 0/0 | 0/0 | 768/80 | 0/0 | 0/0 | 16.6/1.3 | over |
| G174 | dual_weight_round_point | 0/0 | 0/0 | 768/80 | 0/0 | 0/0 | 16.4/2.1 | over |
| G175 | bulk_round_point | 0/0 | 0/0 | 768/120 | 0/0 | 0/0 | 12.5/2.4 | over |
| G176 | weight_round_point | 0/0 | 0/0 | 768/120 | 0/0 | 0/0 | 12.8/2.5 | over |
| G177 | bulk_flat_round_point | 0/0 | 0/0 | 768/120 | 0/0 | 0/0 | 13.5/1.2 | over |
| G178 | weight_flat_round_point | 0/0 | 0/0 | 768/80 | 0/0 | 0/0 | 12.5/0.9 | over |
| G179 | attitude_round_point | 243/0 | 0/0 | 1792/48 | 1/0 | 1/0 | 50.9/0.4 | over |
| G180 | carrier_round_point | 243/0 | 0/0 | 1792/72 | 1/0 | 1/0 | 47.2/0.9 | over |
| G181 | carrier_co_round_point | 243/0 | 0/0 | 2560/48 | 2/0 | 2/0 | 51.4/0.7 | over |
| G182 | center_round_point | 486/5 | 0/0 | 4352/120 | 4/0 | 4/0 | 136.4/2.0 | over |
| G183 | container_round_point | 486/8 | 0/0 | 4352/80 | 4/0 | 4/0 | 111.0/2.0 | over |
| G184 | partner_round_point | 1004/10 | 0/0 | 34560/120 | 10/0 | 273/0 | 271.6/2.2 | over |
| G185 | complement_right_dipole | 0/0 | 0/0 | 768/400 | 0/0 | 0/2 | 16.3/6.1 | over |
| G186 | complement_left_dipole | 0/0 | 0/0 | 768/480 | 0/0 | 0/3 | 16.3/8.1 | over |
| G187 | reverse_dipole | 0/0 | 0/0 | 768/320 | 0/0 | 0/2 | 16.1/3.3 | over |
| G188 | reverse_anti_dipole | 0/0 | 0/0 | 768/560 | 0/0 | 0/3 | 16.3/3.3 | over |
| G189 | dual_bulk_dipole | 0/0 | 0/0 | 768/320 | 0/0 | 0/1 | 16.3/3.5 | over |
| G190 | dual_weight_dipole | 0/0 | 0/0 | 768/160 | 0/0 | 0/0 | 16.1/3.9 | over |
| G191 | bulk_dipole | 0/0 | 0/0 | 768/240 | 0/0 | 0/0 | 12.8/3.6 | over |
| G192 | weight_dipole | 0/0 | 0/0 | 768/240 | 0/0 | 0/0 | 13.4/4.7 | over |
| G193 | bulk_flat_dipole | 0/0 | 0/0 | 768/240 | 0/0 | 0/0 | 12.8/3.2 | over |
| G194 | weight_flat_dipole | 0/0 | 0/0 | 768/240 | 0/0 | 0/0 | 12.5/4.4 | over |
| G195 | attitude_dipole | 243/0 | 0/0 | 1792/120 | 1/0 | 1/0 | 51.2/2.0 | over |
| G196 | carrier_dipole | 243/0 | 0/0 | 1792/128 | 1/0 | 1/0 | 47.1/1.5 | over |
| G197 | carrier_co_dipole | 243/0 | 0/0 | 2560/112 | 2/0 | 2/0 | 52.5/1.3 | over |
| G198 | center_dipole | 486/16 | 0/0 | 4352/160 | 4/0 | 4/1 | 142.3/3.5 | over |
| G199 | container_dipole | 486/18 | 0/0 | 4352/160 | 4/0 | 4/2 | 117.4/3.8 | over |
| G200 | partner_dipole | 1004/29 | 0/0 | 34560/320 | 10/0 | 273/4 | 292.3/4.7 | over |
| G201 | complement_right_circle | 0/0 | 0/0 | 768/400 | 0/0 | 0/2 | 18.8/6.1 | over |
| G202 | complement_left_circle | 0/0 | 0/0 | 768/480 | 0/0 | 0/3 | 18.7/8.1 | over |
| G203 | reverse_circle | 0/0 | 0/0 | 768/320 | 0/0 | 0/2 | 16.1/3.3 | over |
| G204 | reverse_anti_circle | 0/0 | 0/0 | 768/560 | 0/0 | 0/3 | 16.3/3.3 | over |
| G205 | dual_bulk_circle | 0/0 | 0/0 | 768/160 | 0/0 | 0/0 | 16.5/3.3 | over |
| G206 | dual_weight_circle | 0/0 | 0/0 | 768/320 | 0/0 | 0/1 | 16.4/3.5 | over |
| G207 | bulk_circle | 0/0 | 0/0 | 768/240 | 0/0 | 0/0 | 12.5/4.8 | over |
| G208 | weight_circle | 0/0 | 0/0 | 768/240 | 0/0 | 0/0 | 13.5/4.7 | over |
| G209 | bulk_flat_circle | 0/0 | 0/0 | 768/240 | 0/0 | 0/0 | 13.6/4.6 | over |
| G210 | weight_flat_circle | 0/0 | 0/0 | 768/240 | 0/0 | 0/0 | 13.2/3.7 | over |
| G211 | attitude_circle | 243/0 | 0/0 | 1792/160 | 1/0 | 1/0 | 51.7/4.9 | over |
| G212 | carrier_circle | 243/0 | 0/0 | 1792/112 | 1/0 | 1/0 | 47.7/1.2 | over |
| G213 | carrier_co_circle | 243/0 | 0/0 | 2560/224 | 2/0 | 2/1 | 51.3/2.6 | over |
| G214 | center_circle | 486/18 | 0/0 | 4352/160 | 4/0 | 4/1 | 138.6/3.8 | over |
| G215 | container_circle | 486/16 | 0/0 | 4352/120 | 4/0 | 4/0 | 113.6/3.5 | over |
| G216 | partner_circle | 1004/29 | 0/0 | 34560/320 | 10/0 | 273/2 | 283.6/5.1 | over |
| G217 | complement_right_sphere | 0/0 | 0/0 | 768/80 | 0/0 | 0/0 | 16.3/1.2 | over |
| G218 | complement_left_sphere | 0/0 | 0/0 | 768/120 | 0/0 | 0/1 | 16.2/3.8 | over |
| G219 | reverse_sphere | 0/0 | 0/0 | 768/120 | 0/0 | 0/0 | 16.1/11.8 | over |
| G220 | reverse_anti_sphere | 0/0 | 0/0 | 768/120 | 0/0 | 0/0 | 16.1/12.1 | over |
| G221 | dual_bulk_sphere | 0/0 | 0/0 | 768/80 | 0/0 | 0/0 | 16.3/1.5 | over |
| G222 | dual_weight_sphere | 0/0 | 0/0 | 768/80 | 0/0 | 0/0 | 16.2/1.5 | over |
| G223 | bulk_sphere | 0/0 | 0/0 | 768/80 | 0/0 | 0/0 | 12.5/0.9 | over |
| G224 | weight_sphere | 0/0 | 0/0 | 768/120 | 0/0 | 0/0 | 12.5/2.7 | over |
| G225 | bulk_flat_sphere | 0/0 | 0/0 | 768/120 | 0/0 | 0/0 | 12.6/1.2 | over |
| G226 | weight_flat_sphere | 0/0 | 0/0 | 768/120 | 0/0 | 0/0 | 13.1/2.5 | over |
| G227 | attitude_sphere | 243/0 | 0/0 | 1792/120 | 1/0 | 1/0 | 50.8/4.3 | over |
| G228 | carrier_sphere | 243/0 | 0/0 | 1792/48 | 1/0 | 1/0 | 48.1/0.4 | over |
| G229 | carrier_co_sphere | 243/0 | 0/0 | 2560/72 | 2/0 | 2/0 | 53.3/1.0 | over |
| G230 | center_sphere | 486/8 | 0/0 | 4352/80 | 4/0 | 4/0 | 140.0/2.2 | over |
| G231 | container_sphere | 486/5 | 0/0 | 4352/120 | 4/0 | 4/0 | 115.6/2.3 | over |
| G232 | partner_sphere | 1004/10 | 0/0 | 34560/120 | 10/0 | 273/0 | 278.5/2.1 | over |

### Floor

| Op | Shape | Mul | Div | Roots | Bytes | Library mul/bytes |
|----|-------|-----|-----|-------|-------|-------------------|
| `∧` | Wedge | 243 | 0 | 0 | 768 | 243/1024 |
| `∨` | Wedge | 243 | 0 | 0 | 768 | 243/1024 |
| `⟑` | Geometric | 1024 | 0 | 0 | 768 | 1024/1024 |
| `⟇` | Geometric | 1024 | 0 | 0 | 768 | 1024/1024 |
| `∙` | ScalarForm | 32 | 0 | 0 | 520 | 32/1024 |
| `∘` | ScalarForm | 32 | 0 | 0 | 520 | 32/1024 |
| `+` | Componentwise | 0 | 0 | 0 | 768 | 0/1024 |
| `-` | Componentwise | 0 | 0 | 0 | 768 | 0/1024 |
| `∧` | Scale | 32 | 0 | 0 | 520 | 32/776 |
| `∙` | Permutation | 0 | 0 | 0 | 512 | 0/768 |
| `∘` | Permutation | 0 | 0 | 0 | 512 | 0/768 |
| `/` | Permutation | 0 | 0 | 0 | 512 | 0/768 |
| `\` | Permutation | 0 | 0 | 0 | 512 | 0/768 |
| `~` | Permutation | 0 | 0 | 0 | 512 | 0/768 |
| `~∘` | Permutation | 0 | 0 | 0 | 512 | 0/768 |
| `★` | Permutation | 0 | 0 | 0 | 512 | 0/768 |
| `☆` | Permutation | 0 | 0 | 0 | 512 | 0/768 |
| `-` | Permutation | 0 | 0 | 0 | 512 | 0/768 |
| `|∙` | Norm | 32 | 0 | 1 | 264 | 32/1536 |
| `|∘` | Norm | 32 | 0 | 1 | 264 | 32/1536 |
| `|∙²` | SquaredNorm | 32 | 0 | 0 | 264 | 32/768 |
| `|∘²` | SquaredNorm | 32 | 0 | 0 | 264 | 32/768 |
| `^∙` | Unitize | 64 | 1 | 1 | 512 | 64/2304 |
| `^∘` | Unitize | 64 | 1 | 1 | 512 | 64/2304 |
| `^` | Unitize | 64 | 1 | 1 | 512 | 64/2304 |
| `⊖` | Attitude | 0 | 0 | 0 | 512 | 243/1792 |
| `{}` | Permutation | 0 | 0 | 0 | 512 | 0/776 |
| `■` | Permutation | 0 | 0 | 0 | 512 | 0/768 |
| `□` | Permutation | 0 | 0 | 0 | 512 | 0/768 |

## rga3d

This algebra has 3 dimensions, a rigid metric and a 64-byte multivector. The inspector took the
counts on 2026-09-22, on linux amd64, 4 cores, with nim `27763495bcfe265507ca98aedc1c7064bf1e0e4d`,
pga `9f9019b26b46490f79f383eee693b1abc84a4f63` and flags `-d:release`. The bench ran on 2026-09-22,
on linux amd64, 4 cores, over 40 rounds of 1024 objects. The allocation gauge was live.
Gaps: 40. Over 39, met 1, unmeasured 0.

| Id | Measurand | Mul | Div | Bytes | Int | Chk | ns | Status |
|----|-----------|-----|-----|-------|-----|-----|----|--------|
| G233 | wedge | 27/– | 0/– | 256/– | 0/– | 0/– | 6.2/– | over |
| G234 | wedge_anti | 27/– | 0/– | 256/– | 0/– | 0/– | 6.3/– | over |
| G235 | wedge_dot | 48/– | 0/– | 256/– | 0/– | 0/– | 15.4/– | over |
| G236 | wedge_dot_anti | 48/– | 0/– | 256/– | 0/– | 0/– | 15.9/– | over |
| G237 | dot | 4/– | 0/– | 256/– | 0/– | 0/– | 14.4/– | over |
| G238 | dot_anti | 4/– | 0/– | 256/– | 0/– | 0/– | 13.3/– | over |
| G239 | contract_bulk | 18/– | 0/– | 256/– | 0/– | 0/– | 6.5/– | over |
| G240 | contract_weight | 9/– | 0/– | 256/– | 0/– | 0/– | 15.1/– | over |
| G241 | expand_bulk | 9/– | 0/– | 256/– | 0/– | 0/– | 14.9/– | over |
| G242 | expand_weight | 18/– | 0/– | 256/– | 0/– | 0/– | 7.1/– | over |
| G243 | add | 0/– | 0/– | 256/– | 0/– | 0/– | 5.0/– | over |
| G244 | subtract | 0/– | 0/– | 256/– | 0/– | 0/– | 5.0/– | over |
| G245 | project_central | 36/– | 0/– | 704/– | 2/– | 2/– | 12.1/– | over |
| G246 | project_central_anti | 45/– | 0/– | 704/– | 2/– | 2/– | 13.5/– | over |
| G247 | project_orthogonal | 45/– | 0/– | 704/– | 2/– | 2/– | 13.5/– | over |
| G248 | project_orthogonal_anti | 36/– | 0/– | 704/– | 2/– | 2/– | 11.1/– | over |
| G249 | scale | 8/– | 0/– | 200/– | 0/– | 0/– | 4.6/– | over |
| G250 | bulk | 0/– | 0/– | 192/– | 0/– | 0/– | 4.6/– | over |
| G251 | weight | 0/– | 0/– | 192/– | 0/– | 0/– | 4.9/– | over |
| G252 | complement_right | 0/– | 0/– | 192/– | 0/– | 0/– | 4.9/– | over |
| G253 | complement_left | 0/– | 0/– | 192/– | 0/– | 0/– | 5.0/– | over |
| G254 | reverse | 0/– | 0/– | 192/– | 0/– | 0/– | 1.6/– | over |
| G255 | reverse_anti | 0/– | 0/– | 192/– | 0/– | 0/– | 1.6/– | over |
| G256 | dual_bulk | 0/– | 0/– | 192/– | 0/– | 0/– | 11.8/– | over |
| G257 | dual_weight | 0/– | 0/– | 192/– | 0/– | 0/– | 12.8/– | over |
| G258 | negate | 0/– | 0/– | 192/– | 0/– | 0/– | 4.5/– | over |
| G259 | norm_bulk | 4/– | 0/– | 384/– | 1/– | 1/– | 4.2/– | over |
| G260 | norm_weight | 4/– | 0/– | 384/– | 1/– | 1/– | 4.8/– | over |
| G326 | norm_bulk_squared | 4/– | 0/– | 192/– | 0/– | 0/– | 14.4/– | over |
| G327 | norm_weight_squared | 4/– | 0/– | 192/– | 0/– | 0/– | 14.6/– | over |
| G261 | norm | 8/– | 0/– | 960/– | 4/– | 4/– | 13.0/– | over |
| G262 | normalize_bulk | 12/– | 1/– | 576/– | 2/– | 10/– | 10.9/– | over |
| G263 | normalize_weight | 12/– | 1/– | 576/– | 2/– | 10/– | 11.8/– | over |
| G264 | unitize | 12/– | 1/– | 576/– | 2/– | 10/– | 11.3/– | over |
| G265 | attitude | 27/– | 0/– | 448/– | 1/– | 1/– | 4.9/– | over |
| G266 | select_grade | 0/– | 0/– | 200/– | 0/– | 0/– | 4.1/– | over |
| G267 | select_grade_anti | 0/– | 0/– | 200/– | 0/– | 1/– | 4.9/– | over |
| G268 | select_part | – | – | – | – | – | 0.6/– | met |
| G269 | support | 54/– | 0/– | 832/– | 3/– | 3/– | 9.6/– | over |
| G270 | support_anti | 54/– | 0/– | 832/– | 3/– | 3/– | 10.0/– | over |

### Floor

| Op | Shape | Mul | Div | Roots | Bytes | Library mul/bytes |
|----|-------|-----|-----|-------|-------|-------------------|
| `∧` | Wedge | 27 | 0 | 0 | 192 | 27/256 |
| `∨` | Wedge | 27 | 0 | 0 | 192 | 27/256 |
| `⟑` | Geometric | 48 | 0 | 0 | 192 | 48/256 |
| `⟇` | Geometric | 48 | 0 | 0 | 192 | 48/256 |
| `∙` | ScalarForm | 4 | 0 | 0 | 136 | 4/256 |
| `∘` | ScalarForm | 4 | 0 | 0 | 136 | 4/256 |
| `∨★` | ContractBulk | 18 | 0 | 0 | 192 | 18/256 |
| `∨☆` | ContractWeight | 9 | 0 | 0 | 192 | 9/256 |
| `∧★` | ExpandBulk | 9 | 0 | 0 | 192 | 9/256 |
| `∧☆` | ExpandWeight | 18 | 0 | 0 | 192 | 18/256 |
| `+` | Componentwise | 0 | 0 | 0 | 192 | 0/256 |
| `-` | Componentwise | 0 | 0 | 0 | 192 | 0/256 |
| `∧` | Scale | 8 | 0 | 0 | 136 | 8/200 |
| `∙` | Permutation | 0 | 0 | 0 | 128 | 0/192 |
| `∘` | Permutation | 0 | 0 | 0 | 128 | 0/192 |
| `/` | Permutation | 0 | 0 | 0 | 128 | 0/192 |
| `\` | Permutation | 0 | 0 | 0 | 128 | 0/192 |
| `~` | Permutation | 0 | 0 | 0 | 128 | 0/192 |
| `~∘` | Permutation | 0 | 0 | 0 | 128 | 0/192 |
| `★` | Permutation | 0 | 0 | 0 | 128 | 0/192 |
| `☆` | Permutation | 0 | 0 | 0 | 128 | 0/192 |
| `-` | Permutation | 0 | 0 | 0 | 128 | 0/192 |
| `|∙` | Norm | 4 | 0 | 1 | 72 | 4/384 |
| `|∘` | Norm | 4 | 0 | 1 | 72 | 4/384 |
| `|∙²` | SquaredNorm | 4 | 0 | 0 | 72 | 4/192 |
| `|∘²` | SquaredNorm | 4 | 0 | 0 | 72 | 4/192 |
| `^∙` | Unitize | 12 | 1 | 1 | 128 | 12/576 |
| `^∘` | Unitize | 12 | 1 | 1 | 128 | 12/576 |
| `^` | Unitize | 12 | 1 | 1 | 128 | 12/576 |
| `⊖` | Attitude | 0 | 0 | 0 | 128 | 27/448 |
| `{}` | Permutation | 0 | 0 | 0 | 128 | 0/200 |

## cga4d

This algebra has 4 dimensions, a conformal metric and a 128-byte multivector. The inspector took the
counts on 2026-09-22, on linux amd64, 4 cores, with nim `27763495bcfe265507ca98aedc1c7064bf1e0e4d`,
pga `9f9019b26b46490f79f383eee693b1abc84a4f63` and flags `-d:release`. The bench ran on 2026-09-22,
on linux amd64, 4 cores, over 40 rounds of 1024 objects. The allocation gauge was live.
Gaps: 47. Over 46, met 1, unmeasured 0.

| Id | Measurand | Mul | Div | Bytes | Int | Chk | ns | Status |
|----|-----------|-----|-----|-------|-----|-----|----|--------|
| G271 | wedge | 81/– | 0/– | 512/– | 0/– | 0/– | 20.3/– | over |
| G272 | wedge_anti | 81/– | 0/– | 512/– | 0/– | 0/– | 35.6/– | over |
| G273 | wedge_dot | 256/– | 0/– | 512/– | 0/– | 0/– | 95.3/– | over |
| G274 | wedge_dot_anti | 256/– | 0/– | 512/– | 0/– | 0/– | 94.3/– | over |
| G275 | dot | 16/– | 0/– | 512/– | 0/– | 0/– | 15.7/– | over |
| G276 | dot_anti | 16/– | 0/– | 512/– | 0/– | 0/– | 16.1/– | over |
| G277 | contract_bulk | 81/– | 0/– | 512/– | 0/– | 0/– | 35.1/– | over |
| G278 | contract_weight | 81/– | 0/– | 512/– | 0/– | 0/– | 36.9/– | over |
| G279 | expand_bulk | 81/– | 0/– | 512/– | 0/– | 0/– | 41.4/– | over |
| G280 | expand_weight | 81/– | 0/– | 512/– | 0/– | 0/– | 41.4/– | over |
| G281 | add | 0/– | 0/– | 512/– | 0/– | 0/– | 16.0/– | over |
| G282 | subtract | 0/– | 0/– | 512/– | 0/– | 0/– | 15.9/– | over |
| G283 | project_central | 162/– | 0/– | 1408/– | 2/– | 2/– | 74.4/– | over |
| G284 | project_central_anti | 162/– | 0/– | 1408/– | 2/– | 2/– | 76.8/– | over |
| G285 | project_orthogonal | 162/– | 0/– | 1408/– | 2/– | 2/– | 73.6/– | over |
| G286 | project_orthogonal_anti | 162/– | 0/– | 1408/– | 2/– | 2/– | 75.4/– | over |
| G287 | scale | 16/– | 0/– | 392/– | 0/– | 0/– | 15.3/– | over |
| G288 | bulk | 0/– | 0/– | 384/– | 0/– | 0/– | 12.1/– | over |
| G289 | weight | 0/– | 0/– | 384/– | 0/– | 0/– | 12.5/– | over |
| G290 | complement_right | 0/– | 0/– | 384/– | 0/– | 0/– | 6.1/– | over |
| G291 | complement_left | 0/– | 0/– | 384/– | 0/– | 0/– | 6.0/– | over |
| G292 | reverse | 0/– | 0/– | 384/– | 0/– | 0/– | 6.4/– | over |
| G293 | reverse_anti | 0/– | 0/– | 384/– | 0/– | 0/– | 7.2/– | over |
| G294 | dual_bulk | 0/– | 0/– | 384/– | 0/– | 0/– | 6.2/– | over |
| G295 | dual_weight | 0/– | 0/– | 384/– | 0/– | 0/– | 6.6/– | over |
| G296 | negate | 0/– | 0/– | 384/– | 0/– | 0/– | 14.6/– | over |
| G297 | norm_bulk | 16/– | 0/– | 768/– | 1/– | 1/– | 16.9/– | over |
| G298 | norm_weight | 16/– | 0/– | 768/– | 1/– | 1/– | 16.9/– | over |
| G328 | norm_bulk_squared | 16/– | 0/– | 384/– | 0/– | 0/– | 15.2/– | over |
| G329 | norm_weight_squared | 16/– | 0/– | 384/– | 0/– | 0/– | 15.1/– | over |
| G299 | norm | 32/– | 0/– | 1920/– | 4/– | 4/– | 68.1/– | over |
| G300 | normalize_bulk | 32/– | 1/– | 1152/– | 2/– | 18/– | 33.0/– | over |
| G301 | normalize_weight | 32/– | 1/– | 1152/– | 2/– | 18/– | 34.5/– | over |
| G302 | unitize | 32/– | 1/– | 1152/– | 2/– | 18/– | 36.2/– | over |
| G303 | attitude | 81/– | 0/– | 896/– | 1/– | 1/– | 21.6/– | over |
| G304 | select_grade | 0/– | 0/– | 392/– | 0/– | 0/– | 14.5/– | over |
| G305 | select_grade_anti | 0/– | 0/– | 392/– | 0/– | 1/– | 16.2/– | over |
| G306 | select_part | – | – | – | – | – | 0.9/– | met |
| G307 | bulk_flat | 0/– | 0/– | 384/– | 0/– | 0/– | 12.1/– | over |
| G308 | weight_flat | 0/– | 0/– | 384/– | 0/– | 0/– | 12.5/– | over |
| G309 | norm_bulk_flat | 16/– | 0/– | 768/– | 1/– | 1/– | 16.7/– | over |
| G310 | norm_weight_flat | 16/– | 0/– | 768/– | 1/– | 1/– | 17.0/– | over |
| G311 | carrier | 81/– | 0/– | 896/– | 1/– | 1/– | 22.4/– | over |
| G312 | carrier_co | 81/– | 0/– | 1280/– | 2/– | 2/– | 24.0/– | over |
| G313 | center | 162/– | 0/– | 2176/– | 4/– | 4/– | 64.4/– | over |
| G314 | container | 162/– | 0/– | 2176/– | 4/– | 4/– | 60.8/– | over |
| G315 | partner | 340/– | 0/– | 11136/– | 10/– | 145/– | 174.3/– | over |

### Floor

| Op | Shape | Mul | Div | Roots | Bytes | Library mul/bytes |
|----|-------|-----|-----|-------|-------|-------------------|
| `∧` | Wedge | 81 | 0 | 0 | 384 | 81/512 |
| `∨` | Wedge | 81 | 0 | 0 | 384 | 81/512 |
| `⟑` | Geometric | 256 | 0 | 0 | 384 | 256/512 |
| `⟇` | Geometric | 256 | 0 | 0 | 384 | 256/512 |
| `∙` | ScalarForm | 16 | 0 | 0 | 264 | 16/512 |
| `∘` | ScalarForm | 16 | 0 | 0 | 264 | 16/512 |
| `+` | Componentwise | 0 | 0 | 0 | 384 | 0/512 |
| `-` | Componentwise | 0 | 0 | 0 | 384 | 0/512 |
| `∧` | Scale | 16 | 0 | 0 | 264 | 16/392 |
| `∙` | Permutation | 0 | 0 | 0 | 256 | 0/384 |
| `∘` | Permutation | 0 | 0 | 0 | 256 | 0/384 |
| `/` | Permutation | 0 | 0 | 0 | 256 | 0/384 |
| `\` | Permutation | 0 | 0 | 0 | 256 | 0/384 |
| `~` | Permutation | 0 | 0 | 0 | 256 | 0/384 |
| `~∘` | Permutation | 0 | 0 | 0 | 256 | 0/384 |
| `★` | Permutation | 0 | 0 | 0 | 256 | 0/384 |
| `☆` | Permutation | 0 | 0 | 0 | 256 | 0/384 |
| `-` | Permutation | 0 | 0 | 0 | 256 | 0/384 |
| `|∙` | Norm | 16 | 0 | 1 | 136 | 16/768 |
| `|∘` | Norm | 16 | 0 | 1 | 136 | 16/768 |
| `|∙²` | SquaredNorm | 16 | 0 | 0 | 136 | 16/384 |
| `|∘²` | SquaredNorm | 16 | 0 | 0 | 136 | 16/384 |
| `^∙` | Unitize | 32 | 1 | 1 | 256 | 32/1152 |
| `^∘` | Unitize | 32 | 1 | 1 | 256 | 32/1152 |
| `^` | Unitize | 32 | 1 | 1 | 256 | 32/1152 |
| `⊖` | Attitude | 0 | 0 | 0 | 256 | 81/896 |
| `{}` | Permutation | 0 | 0 | 0 | 256 | 0/392 |
| `■` | Permutation | 0 | 0 | 0 | 256 | 0/384 |
| `□` | Permutation | 0 | 0 | 0 | 256 | 0/384 |
