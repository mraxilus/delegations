## Catalogue every library operation as data: what to spell, on what, against which reference.
##   One `Probe` per operation per algebra, built at compile time under `when`, so every
##   later instrument (timing, C inspection, gap list) walks one list and nothing is
##   benchmarked by hand. Spell is library expression over `m` and `n`, fully parenthesised
##   since library's own header warns `∨` parses additive and `∧` multiplicative; reference
##   is expression over same names in typed reference, empty where reference has none.
##   `MISSING` names operations reference carries and library lacks, each one gap row.
##
##   Cost: spells are strings lowered by `parseExpr` where probes are emitted, so misspelt
##     spell fails at that compile rather than here; suite `Catalogue` compiles every one.
##   Cost: `cite` is book equation where library's own suites cite one, else wiki page name,
##     never invented number.
##   Cost: conformal aliases differ from rigid ones in library (`bulkRound` for `bulk`), so
##     alias names stand under `when`, and suite holds them to umbrella's exports.

{.experimental: "strictFuncs".}

import std/options

import pga

import ./kinds


type
  Arity* = range[1 .. 2]
    ## Define operand count of probe.
  Probe* = object
    ## Define one catalogued operation under measurement.
    id*: string
      ## Stable ASCII key, e.g. `wedge_point_point`; keys JSON, ledger and gap rows.
    symbol*: string
      ## Library symbol, e.g. `∧`; empty where operation is alias-only compound.
    alias*: string
      ## Library named alias from `pga.nim`, e.g. `wedge`; empty where none exists.
    spell*: string
      ## Library expression over `m` and `n`, fully parenthesised, e.g. `(m ∧ n)`.
    arity*: Arity = 1
      ## Operand count spell reads; defaulted so object has valid zero value.
    operands*: array[2, Kind]
      ## Kind of `m` and of `n`; second is `General` and unread for unary probe.
    grade*: Option[int]
      ## Grade `General` operands are drawn at, where operation needs k-vector; none = mixed.
    reference*: string
      ## Reference expression over same names, e.g. `wedge(m, n)`; empty where none.
    cite*: string
      ## Book equation, e.g. `2.17`, or `wiki:<Page>` where library suites cite none.


const
  ALIAS_BULK = when IS_RIGID: "bulk" else: "bulkRound"
    ## Library's name for `∙ m`, which conformal umbrella qualifies as round.
  ALIAS_WEIGHT = when IS_RIGID: "weight" else: "weightRound"
    ## Library's name for `∘ m`.
  ALIAS_NORM_BULK = when IS_RIGID: "normBulk" else: "normBulkRound"
    ## Library's name for `|∙ m`.
  ALIAS_NORM_WEIGHT = when IS_RIGID: "normWeight" else: "normWeightRound"
    ## Library's name for `|∘ m`.


func general(
  id, symbol, alias, spell: string; arity: Arity; cite: string
): Probe {.compileTime.} =
  ## Construct probe over dense mixed-grade multivectors, i.e. library's own type.
  Probe(
    id: id,
    symbol: symbol,
    alias: alias,
    spell: spell,
    arity: arity,
    operands: [Kind.General, Kind.General],
    grade: none(int),
    reference: "",
    cite: cite,
  )


func typed(
  id, symbol, alias, spell: string; operands: array[2, Kind]; reference, cite: string
): Probe {.compileTime.} =
  ## Construct probe over typed operands, held to reference expression.
  ##   Arity follows second operand: `General` there marks unary row, since no typed row
  ##   pairs typed object with dense one.
  Probe(
    id: id,
    symbol: symbol,
    alias: alias,
    spell: spell,
    arity: (if operands[1] == Kind.General: 1 else: 2),
    operands: operands,
    grade: none(int),
    reference: reference,
    cite: cite,
  )



#[ Probes ]#

const PROBES* = block:
  ## Every operation library exports under this algebra, general rows first.
  var s: seq[Probe]

  # Binary products over dense operands.
  s.add general("wedge", "∧", "wedge", "(m ∧ n)", 2, "2.17")
  s.add general("wedge_anti", "∨", "wedgeAnti", "(m ∨ n)", 2, "2.29")
  s.add general("wedge_dot", "⟑", "wedgeDot", "(m ⟑ n)", 2, "wiki:Geometric_product")
  s.add general("wedge_dot_anti", "⟇", "wedgeDotAnti", "(m ⟇ n)", 2, "wiki:Geometric_product")
  s.add general("dot", "∙", "dot", "(m ∙ n)", 2, "2.76")
  s.add general("dot_anti", "∘", "dotAnti", "(m ∘ n)", 2, "2.76")
  s.add general("contract_bulk", "∨★", "contractBulk", "(m ∨★ n)", 2, "2.119")
  s.add general("contract_weight", "∨☆", "contractWeight", "(m ∨☆ n)", 2, "2.120")
  s.add general("expand_bulk", "∧★", "expandBulk", "(m ∧★ n)", 2, "wiki:Expansions")
  s.add general("expand_weight", "∧☆", "expandWeight", "(m ∧☆ n)", 2, "wiki:Expansions")
  s.add general("add", "+", "add", "(m + n)", 2, "2.24")
  s.add general("subtract", "-", "subtract", "(m - n)", 2, "2.24")
  s.add general(
    "project_central", "", "projectCentral", "projectCentral(m, n)", 2, "wiki:Projections"
  )
  s.add general(
    "project_central_anti", "", "projectCentralAnti", "projectCentralAnti(m, n)", 2,
    "wiki:Projections",
  )
  s.add general(
    "project_orthogonal", "", "projectOrthogonal", "projectOrthogonal(m, n)", 2,
    "wiki:Projections",
  )
  s.add general(
    "project_orthogonal_anti", "", "projectOrthogonalAnti", "projectOrthogonalAnti(m, n)", 2,
    "wiki:Projections",
  )

  # Scalar scaling, spelled through exterior product as library defines it.
  s.add Probe(
    id: "scale", symbol: "∧", alias: "wedge", spell: "(m ∧ n)", arity: 2,
    operands: [Kind.Scalar, Kind.General], grade: none(int), reference: "", cite: "2.24",
  )

  # Unary maps over dense operand.
  s.add general("bulk", "∙", ALIAS_BULK, "(∙ m)", 1, "2.68")
  s.add general("weight", "∘", ALIAS_WEIGHT, "(∘ m)", 1, "2.68")
  s.add general("complement_right", "/", "complementRight", "(/ m)", 1, "2.19")
  s.add general("complement_left", "\\", "complementLeft", "(\\ m)", 1, "2.20")
  s.add general("reverse", "~", "reverse", "(~ m)", 1, "wiki:Reverses")
  s.add general("reverse_anti", "~∘", "reverseAnti", "(~∘ m)", 1, "wiki:Reverses")
  s.add general("dual_bulk", "★", "dualBulk", "(★ m)", 1, "2.103")
  s.add general("dual_weight", "☆", "dualWeight", "(☆ m)", 1, "2.103")
  s.add general("negate", "-", "negate", "(- m)", 1, "2.24")
  s.add general("norm_bulk", "|∙", ALIAS_NORM_BULK, "(|∙ m)", 1, "2.87")
  s.add general("norm_weight", "|∘", ALIAS_NORM_WEIGHT, "(|∘ m)", 1, "2.88")
  s.add general("norm", "|", "norm", "(| m)", 1, "2.90")
  s.add general("normalize_bulk", "^∙", "normalizeBulk", "(^∙ m)", 1, "2.89")
  s.add general("normalize_weight", "^∘", "normalizeWeight", "(^∘ m)", 1, "2.89")
  s.add general("unitize", "^", "unitize", "(^ m)", 1, "2.89")
  s.add general("attitude", "⊖", "attitude", "(⊖ m)", 1, "2.73")
  s.add general("select_grade", "{}", "selectGrade", "(m{Grade(1)})", 1, "2.17")
  s.add general(
    "select_grade_anti", "{}", "selectGradeAnti", "(m{GradeAnti(1)})", 1, "2.29"
  )
  s.add general("select_part", "[]", "selectPart", "(m[Basis.E1])", 1, "2.24")

  when IS_RIGID:
    s.add general("support", "∩", "support", "(∩ m)", 1, "wiki:Support")
    s.add general("support_anti", "∪", "supportAnti", "(∪ m)", 1, "wiki:Support")
  when IS_CONFORMAL:
    s.add general("bulk_flat", "■", "bulkFlat", "(■ m)", 1, "wiki:Flat_bulk")
    s.add general("weight_flat", "□", "weightFlat", "(□ m)", 1, "wiki:Flat_weight")
    s.add general("norm_bulk_flat", "|■", "normBulkFlat", "(|■ m)", 1, "wiki:Flat_bulk")
    s.add general("norm_weight_flat", "|□", "normWeightFlat", "(|□ m)", 1, "wiki:Flat_weight")
    s.add general("carrier", "⊟", "carrier", "(⊟ m)", 1, "wiki:Carrier")
    s.add general("carrier_co", "⊞", "carrierCo", "(⊞ m)", 1, "wiki:Cocarrier")
    s.add general("center", "⊙", "center", "(⊙ m)", 1, "wiki:Center")
    s.add general("container", "⊡", "container", "(⊡ m)", 1, "wiki:Container")
    # Partner reads operand's grade and panics on mixed grade, so pool draws round points.
    s.add Probe(
      id: "partner", symbol: "⊛", alias: "partner", spell: "(⊛ m)", arity: 1,
      operands: [Kind.General, Kind.General], grade: some(1), reference: "",
      cite: "wiki:Partner",
    )

  # Typed rows: same library spell on images of typed objects, held to reference.
  #   Tuples read id, symbol, alias, spell, kinds of m and n, reference, cite.
  when IS_RIGID and DIMENSIONS == 4:
    for row in [
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
    ]:
      s.add typed(row[0], row[1], row[2], row[3], [row[4], row[5]], row[6], row[7])

    # Unary maps every flat object carries; one row per object kind.
    for (kind, name) in [(Kind.Point, "point"), (Kind.Line, "line"), (Kind.Plane, "plane")]:
      for row in [
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
        ("unitize", "^", "unitize", "(^ m)", "unitize(m)", "2.89"),
        ("attitude", "⊖", "attitude", "(⊖ m)", "attitude(m)", "2.73"),
      ]:
        s.add typed(
          row[0] & "_" & name, row[1], row[2], row[3], [kind, Kind.General], row[4], row[5]
        )
  s


const MISSING* = block:
  ## Operations reference carries and library lacks, each one gap row; ids of same shape.
  var s: seq[Probe]
  when IS_CONFORMAL:
    s.add Probe(
      id: "norm_center", symbol: "|⊙", alias: "normCenter", spell: "", arity: 1,
      operands: [Kind.General, Kind.General], grade: none(int), reference: "",
      cite: "wiki:Center_norm",
    )
    s.add Probe(
      id: "norm_radius", symbol: "|⊘", alias: "normRadius", spell: "", arity: 1,
      operands: [Kind.General, Kind.General], grade: none(int), reference: "",
      cite: "wiki:Radius_norm",
    )
  s


func symbolsOf*(probes: openArray[Probe]): seq[string] =
  ## Read distinct symbols probes spell, in first-seen order; tool and test side.
  for p in probes:
    if p.symbol.len > 0 and p.symbol notin result: result.add p.symbol


func aliasesOf*(probes: openArray[Probe]): seq[string] =
  ## Read distinct aliases probes name, in first-seen order; tool and test side.
  for p in probes:
    if p.alias.len > 0 and p.alias notin result: result.add p.alias


func idsOf*(probes: openArray[Probe]): seq[string] =
  ## Read ids of probes in order; tool and test side.
  for p in probes: result.add p.id
