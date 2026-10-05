## Catalogue every library operation as data: which expression, on what, against which reference.
##   One `Measurand` per operation per algebra, built at compile time under `when`, so every
##   later instrument (timing, C inspection, gap list) walks one list and nothing is
##   benchmarked by hand. Expression is library code over `m` and `n`, fully parenthesised
##   since library's own header warns `∨` parses additive and `∧` multiplicative; reference
##   is expression over same names in typed reference, empty where reference has none.
##   `MISSING` names operations reference carries and library lacks, each one gap.
##
##   Cost: expressions are strings lowered by `parseExpr` where measurands are emitted, so
##     misspelt one fails at that compile rather than here; suite `Internal: Catalogue`
##     compiles every one.
##   Cost: `cite` is book equation where library's own suites cite one, else wiki page name,
##     never invented number.
##   Cost: conformal aliases differ from rigid ones in library (`bulkRound` for `bulk`), so
##     alias names stand under `when`, and suite holds them to umbrella's exports.

{.experimental: "strictFuncs".}

import std/[options, strutils]

import pga

import ./[bound, kinds]


type
  Arity* = range[1..2]  ## Define operand count of measurand.
  Measurand* = object  ## Define one catalogued operation under measurement.
    id*: string  ## Stable ASCII key, e.g. `wedge_point_point`; keys JSON, docket and gaps.
    symbol*: string  ## Library symbol, e.g. `∧`; empty where operation is alias-only compound.
    alias*: string  ## Library named alias from `pga.nim`, e.g. `wedge`; empty where none exists.
    expression*: string
      ## Library expression over `m` and `n`, fully parenthesised, e.g. `(m ∧ n)`.
    arity*: Arity = 1  ## Operand count expression reads; defaulted so object has valid zero value.
    operands*: array[2, Kind]
      ## Kind of `m` and of `n`; second is `General` and unread for unary measurand.
    grade*: Option[int]
      ## Grade `General` operands are drawn at, where operation needs k-vector; none = mixed.
    reference*: string
      ## Reference expression over same names, e.g. `wedge(m, n)`; empty where none.
    cite*: string  ## Book equation, e.g. `2.17`, or `wiki:<Page>` where library suites cite none.
  RowGeneral = tuple[id, symbol, alias, expression: string, arity: int, cite: string]
    ## Define one catalogue row of measurand over dense operands, read by `addGeneral`.
  RowTyped = tuple[
    id, symbol, alias, expression: string,
    operand_m, operand_n: Kind,
    reference, cite: string,
  ]
    ## Define one catalogue row of measurand over typed operands, read by `addTyped`.
  RowUnary = tuple[id, symbol, alias, expression, reference, cite: string]
    ## Define one catalogue row of unary map family of kinds carries, read by `addUnary`.


const
  ALIAS_BULK = when IS_RIGID: "bulk" else: "bulkRound"
    ## Library's name for `∙ m`, which conformal umbrella qualifies as round.
  ALIAS_WEIGHT = when IS_RIGID: "weight" else: "weightRound"  ## Library's name for `∘ m`.
  ALIAS_NORM_BULK = when IS_RIGID: "normBulk" else: "normBulkRound"  ## Library's name for `|∙ m`.
  ALIAS_NORM_WEIGHT = when IS_RIGID: "normWeight" else: "normWeightRound"
    ## Library's name for `|∘ m`.


func addGeneral(catalogue: var seq[Measurand], rows: openArray[RowGeneral]) {.compileTime.} =
  ## Append measurand over dense mixed-grade multivectors, i.e. library's own type, per row.
  for row in rows:
    catalogue.add Measurand(
      id: row.id,
      symbol: row.symbol,
      alias: row.alias,
      expression: row.expression,
      arity: Arity(row.arity),
      operands: [Kind.General, Kind.General],
      grade: none(int),
      reference: "",
      cite: row.cite,
    )


func addTyped(catalogue: var seq[Measurand], rows: openArray[RowTyped]) {.compileTime.} =
  ## Append measurand over typed operands, held to reference expression, per row.
  ##   Arity follows second operand: `General` there marks unary measurand, since no typed
  ##   measurand pairs typed object with dense one.
  for row in rows:
    catalogue.add Measurand(
      id: row.id,
      symbol: row.symbol,
      alias: row.alias,
      expression: row.expression,
      arity: (if row.operand_n == Kind.General: 1 else: 2),
      operands: [row.operand_m, row.operand_n],
      grade: none(int),
      reference: row.reference,
      cite: row.cite,
    )


func addUnary(
  catalogue: var seq[Measurand],
  kinds: openArray[tuple[kind: Kind, name: string]],
  rows: openArray[RowUnary],
) {.compileTime.} =
  ## Append unary measurand per kind and row; id takes name of kind as suffix.
  for (kind, name) in kinds:
    for row in rows:
      catalogue.add Measurand(
        id: row.id & "_" & name,
        symbol: row.symbol,
        alias: row.alias,
        expression: row.expression,
        arity: 1,
        operands: [kind, Kind.General],
        grade: none(int),
        reference: row.reference,
        cite: row.cite,
      )



#[ Catalogue ]#

const CATALOGUE* = block:
  ## Every operation library exports under this algebra, general measurands first.
  var catalogue: seq[Measurand]

  # Binary products over dense operands.
  catalogue.addGeneral [
    ("wedge", "∧", "wedge", "(m ∧ n)", 2, "2.17"),
    ("wedge_anti", "∨", "wedgeAnti", "(m ∨ n)", 2, "2.29"),
    ("wedge_dot", "⟑", "wedgeDot", "(m ⟑ n)", 2, "wiki:Geometric_product"),
    ("wedge_dot_anti", "⟇", "wedgeDotAnti", "(m ⟇ n)", 2, "wiki:Geometric_product"),
    ("dot", "∙", "dot", "(m ∙ n)", 2, "2.76"),
    ("dot_anti", "∘", "dotAnti", "(m ∘ n)", 2, "2.76"),
    ("contract_bulk", "∨★", "contractBulk", "(m ∨★ n)", 2, "2.119"),
    ("contract_weight", "∨☆", "contractWeight", "(m ∨☆ n)", 2, "2.120"),
    ("expand_bulk", "∧★", "expandBulk", "(m ∧★ n)", 2, "wiki:Expansions"),
    ("expand_weight", "∧☆", "expandWeight", "(m ∧☆ n)", 2, "wiki:Expansions"),
    ("add", "+", "add", "(m + n)", 2, "2.24"),
    ("subtract", "-", "subtract", "(m - n)", 2, "2.24"),
    ("project_central", "", "projectCentral", "projectCentral(m, n)", 2, "wiki:Projections"),
    (
      "project_central_anti", "", "projectCentralAnti", "projectCentralAnti(m, n)",
      2, "wiki:Projections",
    ),
    (
      "project_orthogonal", "", "projectOrthogonal", "projectOrthogonal(m, n)",
      2, "wiki:Projections",
    ),
    (
      "project_orthogonal_anti", "", "projectOrthogonalAnti", "projectOrthogonalAnti(m, n)",
      2, "wiki:Projections",
    ),
  ]

  # Scalar scaling, spelled through exterior product as library defines it.
  catalogue.add Measurand(
    id: "scale",
    symbol: "∧",
    alias: "wedge",
    expression: "(m ∧ n)",
    arity: 2,
    operands: [Kind.Scalar, Kind.General],
    grade: none(int),
    reference: "",
    cite: "2.24",
  )

  # Unary maps over dense operand.
  catalogue.addGeneral [
    ("bulk", "∙", ALIAS_BULK, "(∙ m)", 1, "2.68"),
    ("weight", "∘", ALIAS_WEIGHT, "(∘ m)", 1, "2.68"),
    ("complement_right", "/", "complementRight", "(/ m)", 1, "2.19"),
    ("complement_left", "\\", "complementLeft", "(\\ m)", 1, "2.20"),
    ("reverse", "~", "reverse", "(~ m)", 1, "wiki:Reverses"),
    ("reverse_anti", "~∘", "reverseAnti", "(~∘ m)", 1, "wiki:Reverses"),
    ("dual_bulk", "★", "dualBulk", "(★ m)", 1, "2.103"),
    ("dual_weight", "☆", "dualWeight", "(☆ m)", 1, "2.103"),
    ("negate", "-", "negate", "(- m)", 1, "2.24"),
    ("norm_bulk", "|∙", ALIAS_NORM_BULK, "(|∙ m)", 1, "2.87"),
    ("norm_weight", "|∘", ALIAS_NORM_WEIGHT, "(|∘ m)", 1, "2.88"),
    # Squared norms carry no umbrella alias, so alias stands empty and alias suite skips them.
    #   Cite is equation defining norm, since squared quantity is what stands under its root
    #   and library's own suites cite none.
    #   Expression spells operator in backticks: `²` is no operator character to lexer, so
    #     prefix form splits it off as identifier and `parseExpr` fails.
    ("norm_bulk_squared", "|∙²", "", "(`|∙²`(m))", 1, "2.87"),
    ("norm_weight_squared", "|∘²", "", "(`|∘²`(m))", 1, "2.88"),
    ("norm", "|", "norm", "(| m)", 1, "2.90"),
    ("normalize_bulk", "^∙", "normalizeBulk", "(^∙ m)", 1, "2.89"),
    ("normalize_weight", "^∘", "normalizeWeight", "(^∘ m)", 1, "2.89"),
    ("unitize", "^", "unitize", "(^ m)", 1, "2.89"),
    ("attitude", "⊖", "attitude", "(⊖ m)", 1, "2.73"),
    ("select_grade", "{}", "selectGrade", "(m{Grade(1)})", 1, "2.17"),
    ("select_grade_anti", "{}", "selectGradeAnti", "(m{GradeAnti(1)})", 1, "2.29"),
    ("select_part", "[]", "selectPart", "(m[Basis.E1])", 1, "2.24"),
  ]

  when IS_RIGID:
    catalogue.addGeneral [
      ("support", "∩", "support", "(∩ m)", 1, "wiki:Support"),
      ("support_anti", "∪", "supportAnti", "(∪ m)", 1, "wiki:Support"),
    ]
  when IS_CONFORMAL:
    catalogue.addGeneral [
      ("bulk_flat", "■", "bulkFlat", "(■ m)", 1, "wiki:Flat_bulk"),
      ("weight_flat", "□", "weightFlat", "(□ m)", 1, "wiki:Flat_weight"),
      ("norm_bulk_flat", "|■", "normBulkFlat", "(|■ m)", 1, "wiki:Flat_bulk"),
      ("norm_weight_flat", "|□", "normWeightFlat", "(|□ m)", 1, "wiki:Flat_weight"),
      ("carrier", "⊟", "carrier", "(⊟ m)", 1, "wiki:Carrier"),
      ("carrier_co", "⊞", "carrierCo", "(⊞ m)", 1, "wiki:Cocarrier"),
      ("center", "⊙", "center", "(⊙ m)", 1, "wiki:Center"),
      ("container", "⊡", "container", "(⊡ m)", 1, "wiki:Container"),
    ]
    # Partner reads operand's grade and panics on mixed grade, so pool draws round points.
    catalogue.add Measurand(
      id: "partner",
      symbol: "⊛",
      alias: "partner",
      expression: "(⊛ m)",
      arity: 1,
      operands: [Kind.General, Kind.General],
      grade: some(1),
      reference: "",
      cite: "wiki:Partner",
    )

  # Typed measurands: same library expression on images of typed objects, held to reference.
  when IS_RIGID and DIMENSIONS == 4:
    catalogue.addTyped [
      (
        "wedge_point_point", "∧", "wedge", "(m ∧ n)",
        Kind.Point, Kind.Point, "wedge(m, n)", "2.17",
      ),
      (
        "wedge_line_point", "∧", "wedge", "(m ∧ n)",
        Kind.Line, Kind.Point, "wedge(m, n)", "2.17",
      ),
      (
        "wedge_point_line", "∧", "wedge", "(m ∧ n)",
        Kind.Point, Kind.Line, "wedge(m, n)", "2.18",
      ),
      (
        "wedge_anti_plane_plane", "∨", "wedgeAnti", "(m ∨ n)",
        Kind.Plane, Kind.Plane, "wedgeAnti(m, n)", "2.29",
      ),
      (
        "wedge_anti_plane_line", "∨", "wedgeAnti", "(m ∨ n)",
        Kind.Plane, Kind.Line, "wedgeAnti(m, n)", "2.29",
      ),
      (
        "wedge_anti_line_plane", "∨", "wedgeAnti", "(m ∨ n)",
        Kind.Line, Kind.Plane, "wedgeAnti(m, n)", "2.32",
      ),
      (
        "wedge_anti_line_line", "∨", "wedgeAnti", "(m ∨ n)",
        Kind.Line, Kind.Line, "wedgeAnti(m, n)", "2.29",
      ),
      (
        "wedge_anti_point_plane", "∨", "wedgeAnti", "(m ∨ n)",
        Kind.Point, Kind.Plane, "wedgeAnti(m, n)", "2.29",
      ),
      (
        "dot_point_point", "∙", "dot", "(m ∙ n)",
        Kind.Point, Kind.Point, "dot(m, n)", "2.76",
      ),
      (
        "dot_line_line", "∙", "dot", "(m ∙ n)",
        Kind.Line, Kind.Line, "dot(m, n)", "2.76",
      ),
      (
        "dot_plane_plane", "∙", "dot", "(m ∙ n)",
        Kind.Plane, Kind.Plane, "dot(m, n)", "2.76",
      ),
      (
        "dot_anti_point_point", "∘", "dotAnti", "(m ∘ n)",
        Kind.Point, Kind.Point, "dotAnti(m, n)", "2.76",
      ),
      (
        "dot_anti_line_line", "∘", "dotAnti", "(m ∘ n)",
        Kind.Line, Kind.Line, "dotAnti(m, n)", "2.76",
      ),
      (
        "dot_anti_plane_plane", "∘", "dotAnti", "(m ∘ n)",
        Kind.Plane, Kind.Plane, "dotAnti(m, n)", "2.76",
      ),
      (
        "wedge_dot_anti_motor_motor", "⟇", "wedgeDotAnti", "(m ⟇ n)",
        Kind.Motor, Kind.Motor, "wedgeDotAnti(m, n)", "wiki:Motor",
      ),
      (
        "transform_point_motor", "", "", "((n ⟇ m) ⟇ (~∘ n))",
        Kind.Point, Kind.Motor, "transform(m, n)", "wiki:Motor",
      ),
      (
        "transform_line_motor", "", "", "((n ⟇ m) ⟇ (~∘ n))",
        Kind.Line, Kind.Motor, "transform(m, n)", "wiki:Motor",
      ),
      (
        "transform_plane_motor", "", "", "((n ⟇ m) ⟇ (~∘ n))",
        Kind.Plane, Kind.Motor, "transform(m, n)", "wiki:Motor",
      ),
      (
        "project_orthogonal_point_plane", "", "projectOrthogonal", "projectOrthogonal(m, n)",
        Kind.Point, Kind.Plane, "projectOrthogonal(m, n)", "wiki:Projections",
      ),
      (
        "project_orthogonal_point_line", "", "projectOrthogonal", "projectOrthogonal(m, n)",
        Kind.Point, Kind.Line, "projectOrthogonal(m, n)", "wiki:Projections",
      ),
      (
        "project_orthogonal_line_plane", "", "projectOrthogonal", "projectOrthogonal(m, n)",
        Kind.Line, Kind.Plane, "projectOrthogonal(m, n)", "wiki:Projections",
      ),
      (
        "support_line", "∩", "support", "(∩ m)",
        Kind.Line, Kind.General, "support(m)", "wiki:Support",
      ),
      (
        "support_plane", "∩", "support", "(∩ m)",
        Kind.Plane, Kind.General, "support(m)", "wiki:Support",
      ),
      (
        "support_anti_point", "∪", "supportAnti", "(∪ m)",
        Kind.Point, Kind.General, "supportAnti(m)", "wiki:Support",
      ),
      (
        "support_anti_line", "∪", "supportAnti", "(∪ m)",
        Kind.Line, Kind.General, "supportAnti(m)", "wiki:Support",
      ),
      (
        "reverse_anti_motor", "~∘", "reverseAnti", "(~∘ m)",
        Kind.Motor, Kind.General, "reverseAnti(m)", "wiki:Motor",
      ),
      (
        "unitize_motor", "^", "unitize", "(^ m)",
        Kind.Motor, Kind.General, "unitize(m)", "wiki:Motor",
      ),
      (
        "norm_weight_motor", "|∘", "normWeight", "(|∘ m)",
        Kind.Motor, Kind.General, "normWeight(m)", "wiki:Motor",
      ),
      (
        "norm_bulk_motor", "|∙", "normBulk", "(|∙ m)",
        Kind.Motor, Kind.General, "normBulk(m)", "wiki:Motor",
      ),
    ]

    # Unary maps every flat object carries; one measurand per object kind.
    catalogue.addUnary(
      kinds = [(Kind.Point, "point"), (Kind.Line, "line"), (Kind.Plane, "plane")],
      rows = [
        ("complement_right", "/", "complementRight", "(/ m)", "complementRight(m)", "2.19"),
        ("complement_left", "\\", "complementLeft", "(\\ m)", "complementLeft(m)", "2.20"),
        ("reverse", "~", "reverse", "(~ m)", "reverse(m)", "wiki:Reverses"),
        ("reverse_anti", "~∘", "reverseAnti", "(~∘ m)", "reverseAnti(m)", "wiki:Reverses"),
        ("dual_bulk", "★", "dualBulk", "(★ m)", "dualBulk(m)", "2.103"),
        ("dual_weight", "☆", "dualWeight", "(☆ m)", "dualWeight(m)", "2.103"),
        ("bulk", "∙", "bulk", "(∙ m)", "bulk(m)", "2.68"),
        ("weight", "∘", "weight", "(∘ m)", "weight(m)", "2.68"),
        ("norm_bulk", "|∙", "normBulk", "(|∙ m)", "normBulk(m)", "2.87"),
        ("norm_weight", "|∘", "normWeight", "(|∘ m)", "normWeight(m)", "2.88"),
        # Weight squared norm lands in antiscalar slot, so reference wears `Antiscalar`;
        #   conversion is free, since type is distinct float, and widening reads slot from it.
        ("norm_bulk_squared", "|∙²", "", "(`|∙²`(m))", "normBulkSquared(m)", "2.87"),
        (
          "norm_weight_squared", "|∘²", "", "(`|∘²`(m))",
          "Antiscalar(normWeightSquared(m))", "2.88",
        ),
        ("unitize", "^", "unitize", "(^ m)", "unitize(m)", "2.89"),
        ("attitude", "⊖", "attitude", "(⊖ m)", "attitude(m)", "2.73"),
      ],
    )

  when IS_CONFORMAL and DIMENSIONS == 5:
    catalogue.addTyped [
      (
        "wedge_round_point_round_point", "∧", "wedge", "(m ∧ n)",
        Kind.PointRound, Kind.PointRound, "wedge(m, n)", "2.17",
      ),
      (
        "wedge_dipole_round_point", "∧", "wedge", "(m ∧ n)",
        Kind.Dipole, Kind.PointRound, "wedge(m, n)", "2.17",
      ),
      (
        "wedge_round_point_dipole", "∧", "wedge", "(m ∧ n)",
        Kind.PointRound, Kind.Dipole, "wedge(m, n)", "2.18",
      ),
      (
        "wedge_circle_round_point", "∧", "wedge", "(m ∧ n)",
        Kind.Circle, Kind.PointRound, "wedge(m, n)", "2.17",
      ),
      (
        "wedge_round_point_circle", "∧", "wedge", "(m ∧ n)",
        Kind.PointRound, Kind.Circle, "wedge(m, n)", "2.18",
      ),
      (
        "wedge_dipole_dipole", "∧", "wedge", "(m ∧ n)",
        Kind.Dipole, Kind.Dipole, "wedge(m, n)", "2.17",
      ),
      (
        "wedge_anti_sphere_sphere", "∨", "wedgeAnti", "(m ∨ n)",
        Kind.Sphere, Kind.Sphere, "wedgeAnti(m, n)", "2.29",
      ),
      (
        "wedge_anti_sphere_circle", "∨", "wedgeAnti", "(m ∨ n)",
        Kind.Sphere, Kind.Circle, "wedgeAnti(m, n)", "2.29",
      ),
      (
        "wedge_anti_circle_sphere", "∨", "wedgeAnti", "(m ∨ n)",
        Kind.Circle, Kind.Sphere, "wedgeAnti(m, n)", "2.32",
      ),
      (
        "wedge_anti_circle_circle", "∨", "wedgeAnti", "(m ∨ n)",
        Kind.Circle, Kind.Circle, "wedgeAnti(m, n)", "2.29",
      ),
      (
        "wedge_anti_sphere_dipole", "∨", "wedgeAnti", "(m ∨ n)",
        Kind.Sphere, Kind.Dipole, "wedgeAnti(m, n)", "2.29",
      ),
      (
        "wedge_anti_dipole_sphere", "∨", "wedgeAnti", "(m ∨ n)",
        Kind.Dipole, Kind.Sphere, "wedgeAnti(m, n)", "2.32",
      ),
      (
        "dot_round_point_round_point", "∙", "dot", "(m ∙ n)",
        Kind.PointRound, Kind.PointRound, "dot(m, n)", "2.76",
      ),
      (
        "dot_dipole_dipole", "∙", "dot", "(m ∙ n)",
        Kind.Dipole, Kind.Dipole, "dot(m, n)", "2.76",
      ),
      (
        "dot_circle_circle", "∙", "dot", "(m ∙ n)",
        Kind.Circle, Kind.Circle, "dot(m, n)", "2.76",
      ),
      (
        "dot_sphere_sphere", "∙", "dot", "(m ∙ n)",
        Kind.Sphere, Kind.Sphere, "dot(m, n)", "2.76",
      ),
      (
        "dot_anti_round_point_round_point", "∘", "dotAnti", "(m ∘ n)",
        Kind.PointRound, Kind.PointRound, "dotAnti(m, n)", "2.76",
      ),
      (
        "dot_anti_dipole_dipole", "∘", "dotAnti", "(m ∘ n)",
        Kind.Dipole, Kind.Dipole, "dotAnti(m, n)", "2.76",
      ),
      (
        "dot_anti_circle_circle", "∘", "dotAnti", "(m ∘ n)",
        Kind.Circle, Kind.Circle, "dotAnti(m, n)", "2.76",
      ),
      (
        "dot_anti_sphere_sphere", "∘", "dotAnti", "(m ∘ n)",
        Kind.Sphere, Kind.Sphere, "dotAnti(m, n)", "2.76",
      ),
    ]

    # Unary maps every round object carries; one measurand per object kind.
    catalogue.addUnary(
      kinds = [
        (Kind.PointRound, "round_point"),
        (Kind.Dipole, "dipole"),
        (Kind.Circle, "circle"),
        (Kind.Sphere, "sphere"),
      ],
      rows = [
        ("complement_right", "/", "complementRight", "(/ m)", "complementRight(m)", "2.19"),
        ("complement_left", "\\", "complementLeft", "(\\ m)", "complementLeft(m)", "2.20"),
        ("reverse", "~", "reverse", "(~ m)", "reverse(m)", "wiki:Reverses"),
        ("reverse_anti", "~∘", "reverseAnti", "(~∘ m)", "reverseAnti(m)", "wiki:Reverses"),
        ("dual_bulk", "★", "dualBulk", "(★ m)", "dualBulk(m)", "2.103"),
        ("dual_weight", "☆", "dualWeight", "(☆ m)", "dualWeight(m)", "2.103"),
        ("bulk", "∙", "bulkRound", "(∙ m)", "bulk(m)", "2.68"),
        ("weight", "∘", "weightRound", "(∘ m)", "weight(m)", "2.68"),
        ("bulk_flat", "■", "bulkFlat", "(■ m)", "bulkFlat(m)", "wiki:Flat_bulk"),
        ("weight_flat", "□", "weightFlat", "(□ m)", "weightFlat(m)", "wiki:Flat_weight"),
        ("attitude", "⊖", "attitude", "(⊖ m)", "attitude(m)", "2.73"),
        ("carrier", "⊟", "carrier", "(⊟ m)", "carrier(m)", "wiki:Carrier"),
        ("carrier_co", "⊞", "carrierCo", "(⊞ m)", "carrierCo(m)", "wiki:Cocarrier"),
        ("center", "⊙", "center", "(⊙ m)", "center(m)", "wiki:Center"),
        ("container", "⊡", "container", "(⊡ m)", "container(m)", "wiki:Container"),
        ("partner", "⊛", "partner", "(⊛ m)", "partner(m)", "wiki:Partner"),
      ],
    )
  when IS_RIGID and DIMENSIONS == 3:
    catalogue.addTyped [
      (
        "wedge_point_point", "∧", "wedge", "(m ∧ n)",
        Kind.Point, Kind.Point, "wedge(m, n)", "2.17",
      ),
      (
        "wedge_point_line", "∧", "wedge", "(m ∧ n)",
        Kind.Point, Kind.Line, "wedge(m, n)", "2.18",
      ),
      (
        "wedge_line_point", "∧", "wedge", "(m ∧ n)",
        Kind.Line, Kind.Point, "wedge(m, n)", "2.17",
      ),
      (
        "wedge_anti_line_line", "∨", "wedgeAnti", "(m ∨ n)",
        Kind.Line, Kind.Line, "wedgeAnti(m, n)", "2.29",
      ),
      (
        "wedge_anti_point_line", "∨", "wedgeAnti", "(m ∨ n)",
        Kind.Point, Kind.Line, "wedgeAnti(m, n)", "2.29",
      ),
      (
        "wedge_anti_line_point", "∨", "wedgeAnti", "(m ∨ n)",
        Kind.Line, Kind.Point, "wedgeAnti(m, n)", "2.32",
      ),
      (
        "dot_point_point", "∙", "dot", "(m ∙ n)",
        Kind.Point, Kind.Point, "dot(m, n)", "2.76",
      ),
      (
        "dot_line_line", "∙", "dot", "(m ∙ n)",
        Kind.Line, Kind.Line, "dot(m, n)", "2.76",
      ),
      (
        "dot_anti_point_point", "∘", "dotAnti", "(m ∘ n)",
        Kind.Point, Kind.Point, "dotAnti(m, n)", "2.76",
      ),
      (
        "dot_anti_line_line", "∘", "dotAnti", "(m ∘ n)",
        Kind.Line, Kind.Line, "dotAnti(m, n)", "2.76",
      ),
      (
        "wedge_dot_anti_motor_motor", "⟇", "wedgeDotAnti", "(m ⟇ n)",
        Kind.Motor, Kind.Motor, "wedgeDotAnti(m, n)", "wiki:Motor",
      ),
      (
        "transform_point_motor", "", "", "((n ⟇ m) ⟇ (~∘ n))",
        Kind.Point, Kind.Motor, "transform(m, n)", "wiki:Motor",
      ),
      (
        "transform_line_motor", "", "", "((n ⟇ m) ⟇ (~∘ n))",
        Kind.Line, Kind.Motor, "transform(m, n)", "wiki:Motor",
      ),
      (
        "project_orthogonal_point_line", "", "projectOrthogonal", "projectOrthogonal(m, n)",
        Kind.Point, Kind.Line, "projectOrthogonal(m, n)", "wiki:Projections",
      ),
      (
        "support_line", "∩", "support", "(∩ m)",
        Kind.Line, Kind.General, "support(m)", "wiki:Support",
      ),
      (
        "support_anti_point", "∪", "supportAnti", "(∪ m)",
        Kind.Point, Kind.General, "supportAnti(m)", "wiki:Support",
      ),
      (
        "reverse_anti_motor", "~∘", "reverseAnti", "(~∘ m)",
        Kind.Motor, Kind.General, "reverseAnti(m)", "wiki:Motor",
      ),
      (
        "unitize_motor", "^", "unitize", "(^ m)",
        Kind.Motor, Kind.General, "unitize(m)", "wiki:Motor",
      ),
      (
        "norm_weight_motor", "|∘", "normWeight", "(|∘ m)",
        Kind.Motor, Kind.General, "normWeight(m)", "wiki:Motor",
      ),
      (
        "norm_bulk_motor", "|∙", "normBulk", "(|∙ m)",
        Kind.Motor, Kind.General, "normBulk(m)", "wiki:Motor",
      ),
    ]

    # Unary maps every flat object carries; one measurand per object kind.
    catalogue.addUnary(
      kinds = [(Kind.Point, "point"), (Kind.Line, "line")],
      rows = [
        ("complement_right", "/", "complementRight", "(/ m)", "complementRight(m)", "2.19"),
        ("complement_left", "\\", "complementLeft", "(\\ m)", "complementLeft(m)", "2.20"),
        ("reverse", "~", "reverse", "(~ m)", "reverse(m)", "wiki:Reverses"),
        ("reverse_anti", "~∘", "reverseAnti", "(~∘ m)", "reverseAnti(m)", "wiki:Reverses"),
        ("dual_bulk", "★", "dualBulk", "(★ m)", "dualBulk(m)", "2.103"),
        ("dual_weight", "☆", "dualWeight", "(☆ m)", "dualWeight(m)", "2.103"),
        ("bulk", "∙", "bulk", "(∙ m)", "bulk(m)", "2.68"),
        ("weight", "∘", "weight", "(∘ m)", "weight(m)", "2.68"),
        ("norm_bulk", "|∙", "normBulk", "(|∙ m)", "normBulk(m)", "2.87"),
        ("norm_weight", "|∘", "normWeight", "(|∘ m)", "normWeight(m)", "2.88"),
        # Weight squared norm lands in antiscalar slot, so reference wears `Antiscalar`;
        #   conversion is free, since type is distinct float, and widening reads slot from it.
        ("norm_bulk_squared", "|∙²", "", "(`|∙²`(m))", "normBulkSquared(m)", "2.87"),
        (
          "norm_weight_squared", "|∘²", "", "(`|∘²`(m))",
          "Antiscalar(normWeightSquared(m))", "2.88",
        ),
        ("unitize", "^", "unitize", "(^ m)", "unitize(m)", "2.89"),
        ("attitude", "⊖", "attitude", "(⊖ m)", "attitude(m)", "2.73"),
      ],
    )
  when IS_CONFORMAL and DIMENSIONS == 4:
    catalogue.addTyped [
      (
        "wedge_round_point_round_point", "∧", "wedge", "(m ∧ n)",
        Kind.PointRound, Kind.PointRound, "wedge(m, n)", "2.17",
      ),
      (
        "wedge_dipole_round_point", "∧", "wedge", "(m ∧ n)",
        Kind.Dipole, Kind.PointRound, "wedge(m, n)", "2.17",
      ),
      (
        "wedge_round_point_dipole", "∧", "wedge", "(m ∧ n)",
        Kind.PointRound, Kind.Dipole, "wedge(m, n)", "2.18",
      ),
      (
        "wedge_circle_round_point", "∧", "wedge", "(m ∧ n)",
        Kind.Circle, Kind.PointRound, "wedge(m, n)", "2.17",
      ),
      (
        "wedge_round_point_circle", "∧", "wedge", "(m ∧ n)",
        Kind.PointRound, Kind.Circle, "wedge(m, n)", "2.18",
      ),
      (
        "wedge_dipole_dipole", "∧", "wedge", "(m ∧ n)",
        Kind.Dipole, Kind.Dipole, "wedge(m, n)", "2.17",
      ),
      (
        "wedge_anti_circle_circle", "∨", "wedgeAnti", "(m ∨ n)",
        Kind.Circle, Kind.Circle, "wedgeAnti(m, n)", "2.29",
      ),
      (
        "wedge_anti_circle_dipole", "∨", "wedgeAnti", "(m ∨ n)",
        Kind.Circle, Kind.Dipole, "wedgeAnti(m, n)", "2.29",
      ),
      (
        "wedge_anti_dipole_circle", "∨", "wedgeAnti", "(m ∨ n)",
        Kind.Dipole, Kind.Circle, "wedgeAnti(m, n)", "2.32",
      ),
      (
        "wedge_anti_dipole_dipole", "∨", "wedgeAnti", "(m ∨ n)",
        Kind.Dipole, Kind.Dipole, "wedgeAnti(m, n)", "2.29",
      ),
      (
        "wedge_anti_circle_round_point", "∨", "wedgeAnti", "(m ∨ n)",
        Kind.Circle, Kind.PointRound, "wedgeAnti(m, n)", "2.29",
      ),
      (
        "wedge_anti_round_point_circle", "∨", "wedgeAnti", "(m ∨ n)",
        Kind.PointRound, Kind.Circle, "wedgeAnti(m, n)", "2.32",
      ),
      (
        "dot_round_point_round_point", "∙", "dot", "(m ∙ n)",
        Kind.PointRound, Kind.PointRound, "dot(m, n)", "2.76",
      ),
      (
        "dot_dipole_dipole", "∙", "dot", "(m ∙ n)",
        Kind.Dipole, Kind.Dipole, "dot(m, n)", "2.76",
      ),
      (
        "dot_circle_circle", "∙", "dot", "(m ∙ n)",
        Kind.Circle, Kind.Circle, "dot(m, n)", "2.76",
      ),
      (
        "dot_anti_round_point_round_point", "∘", "dotAnti", "(m ∘ n)",
        Kind.PointRound, Kind.PointRound, "dotAnti(m, n)", "2.76",
      ),
      (
        "dot_anti_dipole_dipole", "∘", "dotAnti", "(m ∘ n)",
        Kind.Dipole, Kind.Dipole, "dotAnti(m, n)", "2.76",
      ),
      (
        "dot_anti_circle_circle", "∘", "dotAnti", "(m ∘ n)",
        Kind.Circle, Kind.Circle, "dotAnti(m, n)", "2.76",
      ),
    ]

    # Unary maps every round object carries; one measurand per object kind.
    catalogue.addUnary(
      kinds = [
        (Kind.PointRound, "round_point"),
        (Kind.Dipole, "dipole"),
        (Kind.Circle, "circle"),
      ],
      rows = [
        ("complement_right", "/", "complementRight", "(/ m)", "complementRight(m)", "2.19"),
        ("complement_left", "\\", "complementLeft", "(\\ m)", "complementLeft(m)", "2.20"),
        ("reverse", "~", "reverse", "(~ m)", "reverse(m)", "wiki:Reverses"),
        ("reverse_anti", "~∘", "reverseAnti", "(~∘ m)", "reverseAnti(m)", "wiki:Reverses"),
        ("dual_bulk", "★", "dualBulk", "(★ m)", "dualBulk(m)", "2.103"),
        ("dual_weight", "☆", "dualWeight", "(☆ m)", "dualWeight(m)", "2.103"),
        ("bulk", "∙", "bulkRound", "(∙ m)", "bulk(m)", "2.68"),
        ("weight", "∘", "weightRound", "(∘ m)", "weight(m)", "2.68"),
        ("bulk_flat", "■", "bulkFlat", "(■ m)", "bulkFlat(m)", "wiki:Flat_bulk"),
        ("weight_flat", "□", "weightFlat", "(□ m)", "weightFlat(m)", "wiki:Flat_weight"),
        ("attitude", "⊖", "attitude", "(⊖ m)", "attitude(m)", "2.73"),
        ("carrier", "⊟", "carrier", "(⊟ m)", "carrier(m)", "wiki:Carrier"),
        ("carrier_co", "⊞", "carrierCo", "(⊞ m)", "carrierCo(m)", "wiki:Cocarrier"),
        ("center", "⊙", "center", "(⊙ m)", "center(m)", "wiki:Center"),
        ("container", "⊡", "container", "(⊡ m)", "container(m)", "wiki:Container"),
        ("partner", "⊛", "partner", "(⊛ m)", "partner(m)", "wiki:Partner"),
      ],
    )
  catalogue


const MISSING* = block:
  ## Operations reference carries and library lacks, each one gap; ids spelled alike.
  var missing: seq[Measurand]
  when IS_CONFORMAL:
    missing.addGeneral [
      ("norm_center", "|⊙", "normCenter", "", 1, "wiki:Center_norm"),
      ("norm_radius", "|⊘", "normRadius", "", 1, "wiki:Radius_norm"),
    ]
  missing


const TEMPLATES* = [("^", "^∘")]
  ## Symbols library spells as template over another.
  ##   C carries only second's function; suite holds each pair to library source.

const SHAPES* = [
  ("∧", Shape.Wedge), ("∨", Shape.Wedge),
  ("⟑", Shape.Geometric), ("⟇", Shape.Geometric),
  ("∨★", Shape.ContractBulk), ("∨☆", Shape.ContractWeight),
  ("∧★", Shape.ExpandBulk), ("∧☆", Shape.ExpandWeight),
  ("+", Shape.Componentwise), ("-", Shape.Componentwise),
  ("|∙²", Shape.NormSquared), ("|∘²", Shape.NormSquared),
  ("|∙", Shape.Norm), ("|∘", Shape.Norm),
  ("|■", Shape.Norm), ("|□", Shape.Norm),
  ("^∙", Shape.Unitize), ("^∘", Shape.Unitize), ("^", Shape.Unitize),
  ("⊖", Shape.ProductConstant),
  ("⊟", Shape.ProductConstant), ("⊞", Shape.ProductConstant),
  ("∩", Shape.Support), ("∪", Shape.SupportAnti),
  ("⊙", Shape.Center), ("⊡", Shape.Container),
  ("/", Shape.Permutation), ("\\", Shape.Permutation),
  ("~", Shape.Permutation), ("~∘", Shape.Permutation),
  ("★", Shape.Permutation), ("☆", Shape.Permutation),
  ("■", Shape.Permutation), ("□", Shape.Permutation),
  ("{}", Shape.Permutation),
]
  ## Arithmetic shape of each library symbol, i.e. which rule derives its lower bound.
  ##   Symbol absent here carries no lower bound, and gap list shows dash rather than
  ##   number without ground. Binary `∙` and `∘` stand apart, since library spells same
  ##   symbol for bilinear form and for unary part.


const CHAINS* = [
  # Norm reads two slots, each one root over bilinear form, i.e. `‖m‖∙` then `‖m‖∘`.
  ("(| m)", @[Shape.Norm, Shape.Norm]),
  # Support, center and container fold their maps into one table (`Shape.Support` and
  #   siblings). Partner is cubic, so it stays chain: container of weight dual, then antiwedge
  #   against carrier, i.e. `(m☆)⊡ ∨ m⊟`, each step one folded table.
  ("(⊛ m)", @[Shape.Permutation, Shape.Container, Shape.JoinCarrier]),
  # Projection takes dual product, then full product, i.e. `n ∨ (m ∧☆ n)`.
  ("projectCentral(m, n)", @[Shape.ExpandBulk, Shape.Wedge]),
  ("projectCentralAnti(m, n)", @[Shape.ContractBulk, Shape.Wedge]),
  ("projectOrthogonal(m, n)", @[Shape.ExpandWeight, Shape.Wedge]),
  ("projectOrthogonalAnti(m, n)", @[Shape.ContractWeight, Shape.Wedge]),
  # Sandwich reverses one operand, then takes two geometric antiproducts.
  ("((n ⟇ m) ⟇ (~∘ n))", @[Shape.Permutation, Shape.Geometric, Shape.Geometric]),
]
  ## Steps of each measurand library composes from several operators, keyed by expression.
  ##   Expression is what distinguishes compound measurand, since such measurand spells no
  ##   symbol of its own and typed rows repeat general row's expression. Bound of chain is
  ##   sum over steps, and record marks it as estimate rather than proved minimum.


func chainOf*(p: Measurand): seq[Shape] =
  ## Read steps measurand composes, empty where library spells it with one operator.
  for (expression, parts) in CHAINS:
    if p.expression == expression: return parts
  @[]


func shapeOf*(p: Measurand): Shape =
  ## Read arithmetic shape of measurand, from its symbol, arity and operand kinds.
  ##   Unary `∙` and `∘` read bulk and weight parts, which are permutations; binary ones
  ##   are bilinear forms landing in one slot.
  # Product against scalar operand scales every slot, whatever symbol spells it.
  if p.arity == 2 and Kind.Scalar in p.operands: return Shape.Scale
  if p.symbol in ["∙", "∘"]:
    return (if p.arity == 2: Shape.FormScalar else: Shape.Permutation)
  for (symbol, shape) in SHAPES:
    if p.symbol == symbol:
      # Componentwise covers binary sum and difference; unary `-` negates in place.
      if shape == Shape.Componentwise and p.arity == 1: return Shape.Permutation
      return shape
  Shape.Unknown


func boundOf*(p: Measurand, m: Metric): BoundLower =
  ## Derive multivector lower bound of measurand, by chain where library composes it.
  let parts = p.chainOf
  if parts.len > 0: return boundLowerOfChain(parts, m, p.arity)
  boundLowerOf(p.shapeOf, m, p.arity)


func nameShapeOf*(p: Measurand): string =
  ## Name shape of measurand: one shape, or steps of chain joined by plus.
  ##   Repeated step carries its count rather than its name twice, since whole chain of
  ##   partner outruns width record allows. `stepsOf` carries chain itself.
  let parts = p.chainOf
  if parts.len == 0: return $p.shapeOf
  var
    steps: seq[string]
    counts: seq[int]
  for part in parts:
    let at = steps.find($part)
    if at < 0:
      steps.add $part
      counts.add 1
    else:
      inc counts[at]
  for i, step in steps:
    if result.len > 0: result.add " + "
    result.add (if counts[i] > 1: $counts[i] & " " else: "") & step


func nameDenseOf*(p: Measurand): string =
  ## Name dense form of general measurand, as `denseWedgeAnti` for `wedge_anti`.
  result = "dense"
  for word in p.id.split('_'): result.add word.capitalizeAscii


func stepsOf*(p: Measurand): seq[string] =
  ## Name every step of measurand's chain in order, empty where it carries none.
  for part in p.chainOf: result.add $part


const INLINED* = ["[]"]
  ## Symbols library spells as template over field read, so C carries no function at all.
  ##   Head made component accessor template, where it was `func` with `{.inline.}`, so
  ##   emission suite passes over these rather than demanding function that cannot exist.
  ##   Suite holds each one to library source.


func emitted*(p: Measurand): string =
  ## Read symbol of function library emits for measurand: template's target, else own symbol.
  for (symbol, target) in TEMPLATES:
    if p.symbol == symbol: return target
  p.symbol


func headEmitted*(p: Measurand): string =
  ## Name function library emits for measurand; empty where expression composes several.
  if p.symbol.len > 0: return p.emitted
  if p.alias.len > 0 and p.expression.startsWith(p.alias & "("): return p.alias
  ""


func symbolsOf*(measurands: openArray[Measurand]): seq[string] =
  ## Read distinct symbols measurands spell, in first-seen order; tool and test side.
  for p in measurands:
    if p.symbol.len > 0 and p.symbol notin result: result.add p.symbol


func aliasesOf*(measurands: openArray[Measurand]): seq[string] =
  ## Read distinct aliases measurands name, in first-seen order; tool and test side.
  for p in measurands:
    if p.alias.len > 0 and p.alias notin result: result.add p.alias


func idsOf*(measurands: openArray[Measurand]): seq[string] =
  ## Read ids of measurands in order; tool and test side.
  for p in measurands: result.add p.id
