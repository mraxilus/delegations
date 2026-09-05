## Compute ordered pitch-class intervals and transpositions in twelve-tone equal temperament.
##   Replicates Open Music Theory (openmusictheory.github.io), pages Pitch (class),
##   Interval (class), Transposition and Intervals.
##
##   |-----------------|----------|--------------------------------------------------|
##   | Code            | Notation | Meaning                                          |
##   |-----------------|----------|--------------------------------------------------|
##   | PitchClass      | 0..11    | C = 0, C♯ = 1, ..., B = 11                        |
##   | Interval        | n        | ordered pitch-class interval, clockwise semitones |
##   | p + i           | Tₙ(p)    | transposition, i.e. p + n mod 12                 |
##   | q - p           | n        | interval from p up to q, i.e. q − p mod 12       |
##   | p - i           | T₁₂₋ₙ(p) | transposition down                               |
##   | i.invert        | 12 − n   | inversion; chromatic sizes add up to 12          |
##   | i.intervalClass | ic       | interval class, shortest distance either way     |
##   |-----------------|----------|--------------------------------------------------|
##
##   Decisions:
##     Pitch classes are enum members named in sharp spelling, so code collates against
##       integer notation and every table is enum-indexed (Article IV.6).
##       Cost: enharmonic spelling is display only; diatonic quality (augmented against
##       minor) and compound intervals are out of scope.
##     Interval is `distinct range[0 .. 11]`: sum of two pitch classes is poisoned, and
##       out-of-range literal fails at compile time. Cost: callers convert through `int`.
##     `SPELLING` selects sharp or flat display at build time (Article II.5); one build is
##       one spelling and nothing dispatches on it at runtime.
##   Cost model unread: no hot path exists, every operation is one addition (unmeasured).

{.experimental: "strictFuncs".}


const SPELLING* {.define: "intervals.spelling".} = "sharp"
  ## Display spelling of accidentals, `sharp` or `flat`; validated statically below.

static:
  doAssert SPELLING in ["sharp", "flat"],
    "Spelling should be `sharp` or `flat`; got `" & SPELLING & "`."


type
  PitchClass* {.pure.} = enum
    ## Define twelve pitch classes in integer notation, i.e. C = 0 through B = 11.
    C, C♯, D, D♯, E, F, F♯, G, G♯, A, A♯, B

  Interval* = distinct range[0 .. 11]
    ## Define ordered pitch-class interval in semitones, i.e. clockwise distance.


const
  OCTAVE = 12
    ## Semitones per octave; modulus of every operation.
  lut_pitch_flat: array[PitchClass, string] = [
    "C", "D♭", "D", "E♭", "E", "F", "G♭", "G", "A♭", "A", "B♭", "B",
  ]
    ## Flat spelling per pitch class; sharp spelling is enum name itself.
  lut_interval_name: array[0 .. 11, string] = [
    "P1", "m2", "M2", "m3", "M3", "P4", "TT", "P5", "m6", "M6", "m7", "M7",
  ]
    ## Specific interval name per semitone count; tritone written `TT`.


func `==`*(a, b: Interval): bool {.borrow.}
  ## Compare intervals by semitone count.

func semitones*(i: Interval): int {.inline.} = int(i)
  ## Read semitone count of interval.



#[ Transposition ]#

func `+`*(p: PitchClass, i: Interval): PitchClass =
  ## Transpose pitch class up by interval, i.e. Tₙ(p) = p + n mod 12.
  PitchClass((ord(p) + i.semitones) mod OCTAVE)

func transpose*(p: PitchClass, i: Interval): PitchClass {.inline.} = p + i
  ## Transpose pitch class up by interval.
  ##   I.e. add through `+`; reach for name in prose, symbol in equations.

func `-`*(p: PitchClass, i: Interval): PitchClass =
  ## Transpose pitch class down by interval, i.e. T₁₂₋ₙ(p).
  PitchClass((ord(p) - i.semitones + OCTAVE) mod OCTAVE)

func `+`*(p, q: PitchClass): PitchClass {.error:
  "Add `Interval` to `PitchClass`; pitch classes do not sum."
.}
  ## Poison sum of two pitch classes.



#[ Measurement ]#

func `-`*(q, p: PitchClass): Interval =
  ## Measure ordered interval from `p` up to `q`, i.e. q − p mod 12, clockwise.
  Interval((ord(q) - ord(p) + OCTAVE) mod OCTAVE)

func invert*(i: Interval): Interval =
  ## Invert interval, i.e. chromatic sizes of interval and inversion add up to 12.
  ##   Unison inverts to unison, since 12 mod 12 is 0; doc says so and caller can detect it.
  Interval((OCTAVE - i.semitones) mod OCTAVE)

func intervalClass*(i: Interval): Interval =
  ## Read interval class, i.e. shortest distance either way around clock, 0 through 6.
  Interval(min(i.semitones, i.invert.semitones))



#[ Display ]#

func name*(i: Interval): string =
  ## Read specific interval name, e.g. `P5` for seven semitones.
  lut_interval_name[i.semitones]

func `$`*(p: PitchClass): string =
  ## Render pitch class in build's spelling.
  when SPELLING == "flat": lut_pitch_flat[p] else: system.`$`(p)

func `$`*(i: Interval): string =
  ## Render interval by its specific name.
  i.name
