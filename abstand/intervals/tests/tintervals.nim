discard """
action: run
cmd: "nim c --hints:off -d:testing -d:nimUnittestAbortOnError:on $options $file"
matrix: "-d:intervals.spelling=sharp; -d:intervals.spelling=flat"
batchable: true
joinable: true
"""
## Replicate Open Music Theory pages, suite per page, in both spellings.

import std/unittest
import ../src/intervals


iterator enumeratePairs(): (PitchClass, Interval) =
  ## Yield every pitch class with every interval, i.e. 144 pairs, exhaustive.
  for p in PitchClass:
    for n in 0 .. 11:
      yield (p, Interval(n))


suite "Pitch (class)":
  test "integer notation C = 0 through B = 11":
    check ord(PitchClass.C) == 0  # C = 0
    check ord(PitchClass.C♯) == 1 and ord(PitchClass.A♯) == 10  # C-sharp = 1, B-flat = 10
    check ord(PitchClass.B) == 11 and PitchClass.high.ord == 11  # B = 11, twelve classes


suite "Transposition":
  test "Tn adds n to every element mod 12":
    for p, i in enumeratePairs():  # 144 pairs
      check ord(p + i) == (ord(p) + i.semitones) mod 12  # add n (mod 12)
      check p.transpose(i) == p + i  # alias forwards
    check PitchClass.B + Interval(4) == PitchClass.D♯  # T4 {11, 2, 4} = {3, 6, 8}
    check PitchClass.D + Interval(4) == PitchClass.F♯  # T4 {11, 2, 4} = {3, 6, 8}
    check PitchClass.E + Interval(4) == PitchClass.G♯  # T4 {11, 2, 4} = {3, 6, 8}

  test "subtracting first from second recovers Tn":
    for p, i in enumeratePairs():  # 144 pairs
      check (p + i) - p == i  # subtract first thing from second
      check (p - i) + i == p  # down then up round-trips

  test "unison is identity and octave is unreachable":
    for p in PitchClass:  # 12 classes
      check p + Interval(0) == p  # T0
    check not compiles(Interval(12))  # simple intervals only

  test "pitch classes do not sum":
    check not compiles(PitchClass.C + PitchClass.D)  # poisoned


suite "Interval (class)":
  test "ordered pitch-class interval runs clockwise":
    check PitchClass.A♯ - PitchClass.G == Interval(3)  # from G to A-sharp equals 3
    check PitchClass.G - PitchClass.A♯ == Interval(9)  # from A-sharp to G equals 9

  test "interval class is shortest distance either way":
    check (PitchClass.A♯ - PitchClass.G).intervalClass == Interval(3)  # G to A-sharp is 3
    check (PitchClass.G - PitchClass.A♯).intervalClass == Interval(3)  # A-sharp to G is 3
    for n in 0 .. 11:  # 12 intervals
      check Interval(n).intervalClass.semitones <= 6  # at most half clock
      check Interval(n).intervalClass == Interval(n).invert.intervalClass  # order-free

  test "both directions add up to octave":
    for p in PitchClass:
      for q in PitchClass:  # 144 pairs
        check ((q - p).semitones + (p - q).semitones) mod 12 == 0  # clockwise both ways


suite "Intervals":
  test "chromatic intervals of inversion pair add up to 12":
    for n in 1 .. 11:  # 11 non-unison intervals
      check Interval(n).semitones + Interval(n).invert.semitones == 12  # add up to 12
    check Interval(0).invert == Interval(0)  # unison, mod 12

  test "inversion is involution":
    for n in 0 .. 11:  # 12 intervals
      check Interval(n).invert.invert == Interval(n)  # inverts back

  test "semitone table of simple intervals":
    check Interval(0).name == "P1" and Interval(1).name == "m2"  # unison 0, minor second 1
    check Interval(2).name == "M2" and Interval(3).name == "m3"  # major second 2, minor third 3
    check Interval(4).name == "M3" and Interval(5).name == "P4"  # major third 4, fourth 5
    check Interval(6).name == "TT" and Interval(7).name == "P5"  # tritone 6, fifth 7
    check Interval(8).name == "m6" and Interval(9).name == "M6"  # minor sixth 8, major sixth 9
    check Interval(10).name == "m7" and Interval(11).name == "M7"  # sevenths 10, 11

  test "major inverts into minor, perfect stays perfect":
    for n in 0 .. 11:  # 12 intervals
      let (quality, quality_inverted) = (Interval(n).name[0], Interval(n).invert.name[0])
      case quality
      of 'M': check quality_inverted == 'm'  # major inverts into minor
      of 'm': check quality_inverted == 'M'  # and vice versa
      of 'P': check quality_inverted == 'P'  # perfect inverts into perfect
      else: check quality_inverted == 'T'  # tritone is its own inversion


suite "Spelling":
  test "display follows build spelling, naturals agree":
    when SPELLING == "sharp":
      check $PitchClass.C♯ == "C♯" and $PitchClass.A♯ == "A♯"  # sharp build
    else:
      check $PitchClass.C♯ == "D♭" and $PitchClass.A♯ == "B♭"  # flat build
    check $PitchClass.C == "C" and $PitchClass.B == "B"  # naturals
    check $Interval(7) == "P5"  # interval renders by name
