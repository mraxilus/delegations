## cipra le genturfa'i sepi'o lo xe fanva be fi la lojban. be'o po'u `Alice` .e `Oz` va'o lo nu lo
##     stopapri cu zvati
##   .i ro ju'agri cu se tcidu gi'a se to'e curmi ta'i lo nu vi se kancu
##   .i `PROVENANCE.md` cusku le javni poi ro klesi be lo nu to'e curmi cu na'e mapti ke'a
##
## ni'o le papri na selra'e `delegations` to `D3 a` pe `#819` toi
##   .i lo minde po'u `nim r tools/build.nim translations` cpacu le papri gi'e punji le papri fi
##       `build/translations/`
##   .i va'o lo nu lo papri be pa xe fanva cu na zvati gi'a na mapti le stosni kei le cipra cu na
##       tcidu le xe fanva
##   .i le cipskami noi cpacu no papri cu zukte ta'i le mintu to `Article IX.9` toi
##
## ni'o le te kancu cu du lo te kancu be lo ju'agri be'o .e lo te kancu be lo ju'agri poi se tcidu
##     ku'o ja'i le stosni pe de'i `2026-11-06`
##   .i lo nu galfi le genturfa'i kei poi galfi lo seljdi pe su'o ju'agri cu galfi lo te kancu be lo
##       ju'agri poi se tcidu
##   .i se ki'u bo le vi cipra cu fliba
##
## ni'o lo ju'agri .e lo se tcidu pe le ju'agri cu selkra `tools/translations.nim`
##   .i lo seljdi cu selkra `tools/tatoeba.nim`
##   .i se ki'u bo lo cipra jo'u lo minde cu skicu le ju'agri .e le se tcidu .e le seljdi pa roi to
##       `Article II.9` toi

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[options, os, unittest]

import ../../tools/[tatoeba, translations]


const
  ROOT = currentSourcePath().parentDir.parentDir.parentDir
    ## le vi selgu'a noi le papri cu cnita ke'a
  COUNTS = [("alis", 856, 783), ("oz", 173, 56)]
    ## lo cmene be ro xe fanva be'o jo'u lo te kancu be lo ju'agri be'o jo'u lo te kancu be lo
    ##     ju'agri poi se tcidu
    ##   .i ro le te kancu cu mapti le stopapri



suite "Internal: Translations":
  for (name, count_paragraphs, count_read) in COUNTS:
    test "Each paragraph of " & name & " reads or is refused as counted, where page is present":
      var paragraphs = none(seq[string])
      for translation in TRANSLATIONS:
        if translation.name == name: paragraphs = translation.readTranslation(ROOT)
      # le papri cu na zvati gi'a na mapti le stosni
      #   .i lo minde po'u `translations` cpacu le papri
      if paragraphs.isNone: skip()
      else:
        var read = 0
        for paragraph in paragraphs.get:
          if paragraph.reading.verdict.len == 0: inc read
        check paragraphs.get.len == count_paragraphs  # `D3 a` to lo ju'agri pe le stopapri toi
        # lo ju'agri poi le genturfa'i cu tcidu ke'a ne'i le stopapri
        check read == count_read  # `D5 c`
