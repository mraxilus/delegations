## Replicate consonant clusters of CLL chapter 3 against `clusters.nim`.
##   Domain is seventeen consonants, so every pair and every triple is enumerated (Article IX.3).
##   Rules are restated here from CLL text, apart from tables `clusters.nim` derives, so suite
##     checks derivation rather than repeating it.

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/unittest

import ../../src/lojban_tagger/clusters


const
  ORDER_CONSONANTS = "bcdfgjklmnprstvxz"  ## Seventeen consonants in order of 3.1.
  VOICED = "bdgjvz"  ## Voiced column of 3.6 table.
  UNVOICED = "cfkpstx"  ## Unvoiced column of 3.6 table.
  LUT_UNVOICED_BY_VOICED = [('b', 'p'), ('d', 't'), ('g', 'k'), ('v', 'f'), ('j', 'c'), ('z', 's')]
    ## Rows of 3.6 table, voiced member first.


func unvoiced(c: char): char =
  ## Read unvoiced partner of voiced consonant, from 3.6 table.
  for (voiced, partner) in LUT_UNVOICED_BY_VOICED:
    if voiced == c: return partner
  c



suite "Chapter 3":
  test "Section 3.6":
    var count_permissible = 0
    for a in ORDER_CONSONANTS:
      for b in ORDER_CONSONANTS:  # 289 pairs, exhaustive
        let
          is_doubled = a == b
          is_voicing_mixed = (a in VOICED and b in UNVOICED) or (a in UNVOICED and b in VOICED)
          is_sibilant_both = a in "cjsz" and b in "cjsz"
          is_named = a & b in ["cx", "kx", "xc", "xk", "mz"]
        if is_doubled: check not isPairPermissible(a, b)  # 3.6 rule 1
        if is_voicing_mixed: check not isPairPermissible(a, b)  # 3.6 rule 2
        if is_sibilant_both: check not isPairPermissible(a, b)  # 3.6 rule 3
        if is_named: check not isPairPermissible(a, b)  # 3.6 rule 4
        if not (is_doubled or is_voicing_mixed or is_sibilant_both or is_named):
          check isPairPermissible(a, b)  # 3.6, pairs appear freely outside four rules
          inc count_permissible
    check count_permissible > 0  # 3.6, rules leave pairs to appear
    check not isPairPermissible('b', 'f')  # 3.6, "bf" is forbidden
    check not isPairPermissible('s', 'd')  # 3.6, "sd" is forbidden
    check isPairPermissible('f', 'l') and isPairPermissible('v', 'l')  # 3.6, "fl" and "vl"
    check isPairPermissible('l', 's') and isPairPermissible('l', 'z')  # 3.6, "ls" and "lz"
    check not isPairPermissible('m', 'z')  # 3.6, Example 6.1, `y` breaks "mz" of "djeimyz"
    check isPairPermissible('z', 'm')  # 3.6 rule 4 names "mz" alone, never "zm"
    check not isPairPermissible('a', 'b') and not isPairPermissible('\'', 'b')  # 3.6, consonants


  test "Section 3.7":
    var count_initial = 0
    for a in ORDER_CONSONANTS:
      for b in ORDER_CONSONANTS:  # 289 pairs, exhaustive
        if not isPairInitial(a, b): continue
        inc count_initial
        check isPairPermissible(a, b)  # 3.7, initial pairs restrict permissible pairs of 3.6
        if a in VOICED and b in VOICED:
          check isPairInitial(a.unvoiced, b.unvoiced)  # 3.7, voiced pair implies unvoiced one
    check count_initial == 48  # 3.7, "just 48 such permissible initial consonant pairs"
    check isPairInitial('c', 'n') and not isPairInitial('j', 'n')  # 3.7, converse fails
    for pair in ["bl", "cf", "dj", "jb", "sf", "tc", "xr", "zv"]:
      check isPairInitial(pair[0], pair[1])  # 3.7 list, one per row it spans
    for a in ORDER_CONSONANTS:
      for b in ORDER_CONSONANTS:
        for c in ORDER_CONSONANTS:  # 4913 triples, exhaustive
          let is_expected = isPairPermissible(a, b) and isPairInitial(b, c) and
              a & b & c notin ["ndj", "ndz", "ntc", "nts"]
          check isTriplePermissible(a, b, c) == is_expected  # 3.7, three rules on triples
    for triple in ["ndj", "ndz", "ntc", "nts"]:
      check isPairPermissible(triple[0], triple[1]) and isPairInitial(triple[1], triple[2])
      check not isTriplePermissible(triple[0], triple[1], triple[2])  # 3.7, forbidden by name
