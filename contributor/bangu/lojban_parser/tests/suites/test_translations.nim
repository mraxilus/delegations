## Hold parser to translations into lojban, Alice and Oz, where pinned page is present: each
##   paragraph reads, or is refused as counted here; record names rule each class of refusal
##   breaks.
##   Pages stay out of repository (ruling `D3 a` of #819). `nim r tools/build.nim translations`
##     fetches them into `build/translations/`, and suite skips translation whose page is absent
##     or moved from pin, as runner, which fetches none, does (Article IX.9).
##   Counts are of paragraphs, and of paragraphs that read, at pins of 2026-11-06; change of
##     parser that moves verdict of paragraph moves count of read ones, and fails here.
##   Paragraph and its reading come from `tools/translations.nim`, verdict from
##     `tools/tatoeba.nim`, so suites and verbs define them once (II.9).

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[options, os, unittest]

import ../../tools/[tatoeba, translations]


const
  ROOT = currentSourcePath().parentDir.parentDir.parentDir  ## Project, which pages stand under.
  COUNTS = [("alis", 856, 783), ("oz", 173, 56)]
    ## Name of each translation, with its paragraphs and those that read, at its pin.



suite "Internal: Translations":
  for (name, count_paragraphs, count_read) in COUNTS:
    test "Each paragraph of " & name & " reads or is refused as counted, where page is present":
      var paragraphs = none(seq[string])
      for translation in TRANSLATIONS:
        if translation.name == name: paragraphs = translation.readTranslation(ROOT)
      if paragraphs.isNone: skip()  # page absent or moved; verb `translations` fetches it
      else:
        var read = 0
        for paragraph in paragraphs.get:
          if paragraph.reading.verdict.len == 0: inc read
        check paragraphs.get.len == count_paragraphs  # `D3 a`, paragraphs of pinned page
        check read == count_read  # `D5 c`, paragraphs parser reads at pin
