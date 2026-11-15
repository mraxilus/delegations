## rapyzba lo zunsna gunma pe `CLL 3` gi'e cipra lo du'u `clusters.nim` mapti le selzba
##   .i lo se cipra cu du le paze zunsna
##   .i se ki'u bo ro zunsna remei .e ro zunsna cimei cu se liste to `Article IX.3` toi
##   .i le vi cipra cu rapsku le javni ja'i lo selci'a pe `CLL` gi'e na pilno lo liste poi
##       `clusters.nim` zbasu ke'a
##   .i se ki'u bo le cipra cu cipra lo nu zbasu le liste kei gi'e na rapli le nu zbasu

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/unittest

import ../../src/lojban_parser/clusters


const
  ORDER_CONSONANTS = "bcdfgjklmnprstvxz"  ## le paze zunsna ta'i lo porsi pe `CLL 3.1`
  VOICED = "bdgjvz"  ## lo voksa zunsna pe le liste pe `CLL 3.6`
  UNVOICED = "cfkpstx"  ## lo na'e voksa zunsna pe le liste pe `CLL 3.6`
  LUT_UNVOICED_BY_VOICED = [('b', 'p'), ('d', 't'), ('g', 'k'), ('v', 'f'), ('j', 'c'), ('z', 's')]
    ## lo linji be le liste pe `CLL 3.6`
    ##   .i lo voksa zunsna cu pamoi


func unvoiced(c: char): char =
  ## dunda lo na'e voksa zunsna poi kansa le voksa zunsna ne'i le liste pe `CLL 3.6`
  for (voiced, partner) in LUT_UNVOICED_BY_VOICED:
    if voiced == c: return partner
  c



suite "Chapter 3":
  test "Section 3.6":
    var count_permissible = 0
    for a in ORDER_CONSONANTS:
      for b in ORDER_CONSONANTS:  # ro le rebiso zunsna remei
        let
          is_doubled = a == b
          is_voicing_mixed = (a in VOICED and b in UNVOICED) or (a in UNVOICED and b in VOICED)
          is_sibilant_both = a in "cjsz" and b in "cjsz"
          is_named = a & b in ["cx", "kx", "xc", "xk", "mz"]
        if is_doubled: check not isPairPermissible(a, b)  # le pamoi javni pe `CLL 3.6`
        if is_voicing_mixed: check not isPairPermissible(a, b)  # le remoi javni pe `CLL 3.6`
        if is_sibilant_both: check not isPairPermissible(a, b)  # le cimoi javni pe `CLL 3.6`
        if is_named: check not isPairPermissible(a, b)  # le vomoi javni pe `CLL 3.6`
        if not (is_doubled or is_voicing_mixed or is_sibilant_both or is_named):
          # ja'i `CLL 3.6` ro zunsna remei poi le vo javni na fanta ke'a selcru
          check isPairPermissible(a, b)  # `CLL 3.6`
          inc count_permissible
    check count_permissible > 0  # ja'i `CLL 3.6` le javni cu curmi su'o zunsna remei
    check not isPairPermissible('b', 'f')  # ja'i `CLL 3.6` zoi gy. bf .gy. na selcru
    check not isPairPermissible('s', 'd')  # ja'i `CLL 3.6` zoi gy. sd .gy. na selcru
    # ja'i `CLL 3.6` zoi gy. fl .gy. .e zoi gy. vl .gy. selcru
    check isPairPermissible('f', 'l') and isPairPermissible('v', 'l')  # `CLL 3.6`
    # ja'i `CLL 3.6` zoi gy. ls .gy. .e zoi gy. lz .gy. selcru
    check isPairPermissible('l', 's') and isPairPermissible('l', 'z')  # `CLL 3.6`
    # `CLL 3.6` .e `Example 3.8`
    #   .i `y` fendi zoi gy. mz .gy. pe zoi gy. djeimyz .gy.
    check not isPairPermissible('m', 'z')  # `CLL 3.6`
    # le vomoi javni pe `CLL 3.6` cusku zoi gy. mz .gy. po'o gi'e no roi cusku zoi gy. zm .gy.
    check isPairPermissible('z', 'm')  # `CLL 3.6`
    # ja'i `CLL 3.6` lo zunsna po'o cu zbasu lo zunsna remei
    check not isPairPermissible('a', 'b') and not isPairPermissible('\'', 'b')  # `CLL 3.6`


  test "Section 3.7":
    var count_initial = 0
    for a in ORDER_CONSONANTS:
      for b in ORDER_CONSONANTS:  # ro le rebiso zunsna remei
        if not isPairInitial(a, b): continue
        inc count_initial
        # ja'i `CLL 3.7` ro zunsna remei poi ka'e krasi lo valsi cu selcru ja'i `CLL 3.6`
        check isPairPermissible(a, b)  # `CLL 3.7`
        if a in VOICED and b in VOICED:
          # ja'i `CLL 3.7` lo nu lo voksa zunsna remei cu ka'e krasi lo valsi cu nibli lo nu lo na'e
          #     voksa zunsna remei poi mapti cu ka'e krasi lo valsi
          check isPairInitial(a.unvoiced, b.unvoiced)  # `CLL 3.7`
    # `CLL 3.7` cusku zoi gy. just 48 such permissible initial consonant pairs .gy.
    check count_initial == 48  # `CLL 3.7`
    # ja'i `CLL 3.7` lo fatne be lo nibli na jetnu
    check isPairInitial('c', 'n') and not isPairInitial('j', 'n')  # `CLL 3.7`
    for pair in ["bl", "cf", "dj", "jb", "sf", "tc", "xr", "zv"]:
      # le liste pe `CLL 3.7`
      #   .i ro linji be le liste cu vasru pa le remei
      check isPairInitial(pair[0], pair[1])  # `CLL 3.7`
    for a in ORDER_CONSONANTS:
      for b in ORDER_CONSONANTS:
        for c in ORDER_CONSONANTS:  # ro le vosopaci zunsna cimei
          let is_expected = isPairPermissible(a, b) and isPairInitial(b, c) and
              a & b & c notin ["ndj", "ndz", "ntc", "nts"]
          check isTriplePermissible(a, b, c) == is_expected  # le ci cimei javni pe `CLL 3.7`
    for triple in ["ndj", "ndz", "ntc", "nts"]:
      check isPairPermissible(triple[0], triple[1]) and isPairInitial(triple[1], triple[2])
      # `CLL 3.7` cusku le zunsna cimei gi'e to'e curmi ri
      check not isTriplePermissible(triple[0], triple[1], triple[2])  # `CLL 3.7`
