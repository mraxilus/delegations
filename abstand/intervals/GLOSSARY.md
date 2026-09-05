# intervals

Ordered pitch-class intervals and transposition in twelve-tone equal temperament, as Open
Music Theory presents them.

## Language

**Pitch class**:
One of twelve pitches under octave equivalence, in integer notation C = 0 through B = 11.
_Avoid_: note, tone, pitch

**Interval**:
The ordered pitch-class interval: semitones counted clockwise from one pitch class up to
another, 0 through 11.
_Avoid_: distance, gap, step count

**Interval class**:
The shortest distance between two pitch classes either way around the clock, 0 through 6.
_Avoid_: unordered interval, absolute interval

**Transposition**:
Adding an interval to a pitch class modulo 12, written Tₙ.
_Avoid_: shift, offset

**Inversion**:
The interval whose chromatic size, added to the original's, makes 12.
_Avoid_: complement, reverse

**Spelling**:
Whether accidentals display as sharps or flats; a build-time choice that never changes
which pitch class is meant.
_Avoid_: notation mode, enharmonic mode

**Specific interval name**:
The quality-and-size label of a simple interval, `P1` through `M7`, with the tritone as
`TT`.
_Avoid_: interval type, quality
