## Hold diagnostics tree's colour ramp, as shipped.
##
## Tree tints each row by its share of frame: cyan at nothing, orange at half frame or more.
##   Ramp is CET-I1, re-lit to drawer's own text tones.
##   `tools/check_ramp.nim` regenerates every entry from published map and stylesheet
##   tokens, and fails where two disagree, so table cannot drift from what it claims.
##   Two ramps, one per text weight: label and value take hue and chroma from map and
##   lightness from tone untinted text wears, so tinting never disturbs type hierarchy.
##     Cost: second table of `STEPS_RAMP_TREE` triples.
##
## Lives in `core` rather than `browser/`: verifying tool is native and must not import
## browser bridge. Nothing here draws.

{.experimental: "strictFuncs".}

const
  STEPS_RAMP_TREE* = 17
    ## Fix how many samples of map ramp ships.
    ##   Presentation layer interpolates between them.
    ##   `check_ramp` measures that interpolation against map's full 256 entries.

  LIFT_VALUE_RAMP* = 0.15
    ## Fix how far row's value is lifted from label's lightness toward `--ink`'s.
    ##   Small on purpose: lifting whole way desaturates number, half of row reader reads.

  RAMP_TREE_LABEL*: array[STEPS_RAMP_TREE, (float, float, float)] = [
    (0.06362, 0.63569, 0.84006),
    (0.13402, 0.64230, 0.78837),
    (0.18101, 0.64807, 0.73553),
    (0.22064, 0.65284, 0.68127),
    (0.25832, 0.65637, 0.62523),
    (0.29755, 0.65824, 0.56708),
    (0.34169, 0.65770, 0.50665),
    (0.39411, 0.65342, 0.44518),
    (0.45560, 0.64383, 0.38782),
    (0.51630, 0.62993, 0.34518),
    (0.57713, 0.61192, 0.31085),
    (0.63310, 0.59142, 0.28732),
    (0.68453, 0.56870, 0.27599),
    (0.73156, 0.54407, 0.27623),
    (0.77446, 0.51774, 0.28601),
    (0.81370, 0.48972, 0.30279),
    (0.84972, 0.45984, 0.32453),
  ]
    ## Hold row's label ramp, at `--ink-muted`'s lightness.

  RAMP_TREE_VALUE*: array[STEPS_RAMP_TREE, (float, float, float)] = [
    (0.16958, 0.68668, 0.89344),
    (0.21231, 0.69313, 0.84084),
    (0.24834, 0.69878, 0.78708),
    (0.28164, 0.70349, 0.73188),
    (0.31498, 0.70700, 0.67493),
    (0.35094, 0.70887, 0.61592),
    (0.39255, 0.70831, 0.55479),
    (0.44316, 0.70398, 0.49291),
    (0.50372, 0.69425, 0.43566),
    (0.56440, 0.68013, 0.39354),
    (0.62581, 0.66186, 0.36002),
    (0.68270, 0.64111, 0.33730),
    (0.73520, 0.61815, 0.32638),
    (0.78337, 0.59336, 0.32648),
    (0.82740, 0.56696, 0.33569),
    (0.86772, 0.53902, 0.35173),
    (0.90479, 0.50942, 0.37277),
  ]
    ## Hold row's value ramp, one `LIFT_VALUE_RAMP` step brighter.
