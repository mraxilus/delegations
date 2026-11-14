## Hold JavaScript build of parser, `src/javascript/bridge.nim`, to native build, in headless
##   Chromium that verb `drive` starts (`tools/drive.nim`): each sentence of fixed sample of Tatoeba
##   takes verdict native build gave it at render, and object of `parseLojban` mirrors
##   `ReadingText` field for field.
##   NIF of every fourth sentence of sample, where it reads, written on JS backend, reads back as
##     model of format gives, and rebuilds its tree whole, by reader of native suite
##     (`suites/reader_nif.nim`); `parseLojbanToNif` gives module of worked example native suite
##     holds, byte for byte.
##     Cost: reading takes about 70 ms each sentence on JS backend, so whole sample would add
##       about 13 s; native suite reads every text of corpora.
##   Sample reaches 86 of 88 named rules of 21.1, and refuses 49 sentences at stream and grammar
##     alike, so one run holds most of parser under JavaScript (`sample_tatoeba/sentences.nim`).
##   Verdict is refusal and rule, as `tools/tatoeba.nim` spells it; empty where sentence reads.
##   Runs in page, apart from `test_suites.nim`, since bridge reaches JavaScript objects through
##     `std/jsffi`, which native build cannot compile. Reporter sends each test to backend, then
##     code of run, so failed check fails `drive` (`report.nim`). No node runs it (ruling on
##     #859), so script is held where it runs: in page.
##   Compiled with `-d:release`, as verb `javascript` builds script, so suite holds build that
##     ships (IX.6); failed check still names its line, which `check` fixes at compile time.
##   Abort define is left out, so every sentence whose verdict moved reports in one run.

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[jsffi, strutils, unittest]

import ../../src/javascript/bridge
import ../../src/lojban_parser/[nif, prose]
import ../sample_tatoeba/sentences
import ../suites/reader_nif
import ./report


const
  STRIDE_NIF = 4  ## Law of NIF reads every fourth sentence of sample.
  COUNT_TREES_LEAST = 40  ## Sentences of that stride that read, of 59; law reads tree of each.


proc verdict(reading: JsObject): string =
  ## Spell outcome of `parseLojban` as verdict of sample: empty where text reads.
  if reading.is_read.to(bool): return ""
  let rule = $reading.rule.to(cstring)
  $reading.refusal.to(cstring) & (if rule.len > 0: " " & rule else: "")



initReporter()


suite "Internal: JavaScript build":
  test "Each sentence of Tatoeba sample takes verdict native build gave it":
    var count = 0
    for sentence in SENTENCES_TATOEBA:
      check parseLojban(cstring(sentence.text)).verdict == sentence.verdict  # native at render
      inc count
    check count == SENTENCES_TATOEBA.len  # IX.3, guard keeps every sentence


  test "Object of text that reads holds occurrences, units and tree":
    let reading = parseLojban("mi klama le zarci")  # Example 2.1 of CLL 1.1
    check reading.is_read.to(bool)  # prose.nim, text reads
    check reading.occurrences.length.to(int) == 4  # one occurrence per word
    check reading.occurrences[0].reading.selmaho.to(cstring) == "KOhA"  # ch. 20, name as spelled
    check reading.occurrences[1].reading.kind.to(cstring) == "Gismu"  # 4.4, `klama`
    check reading.occurrences[1].stress == jsNull  # no capital marks stress
    check reading.occurrences[1].start.to(int) == 3  # stream.nim, byte where `klama` opens
    check reading.occurrences[1].finish.to(int) == 8  # stream.nim, byte past its last letter
    check reading.units.length.to(int) == 4  # one terminal per word
    check reading.units[1].terminal.to(cstring) == "BRIVLA"  # 21.1, terminal of brivla
    check reading.tree.rule.to(cstring) == "text"  # 21.1, rule 0 opens tree
    check reading.tree.number.to(int) == 0


  test "Object of text refused holds refusal, its byte and rule, and stream before it":
    let typo = parseLojban("mi klama le zarc")  # `zarci` missing last letter; constructed
    check not typo.is_read.to(bool)
    check typo.refusal.to(cstring) == "Grammar"  # 21.1 refuses
    check typo.start.to(int) == 12  # byte where `zarc` opens
    check typo.rule.to(cstring) == "sumti-6 97"  # rule 97, innermost open there
    check typo.stream.occurrences[3].reading.kind.to(cstring) == "Cmene"  # 4.8, consonant last
    let tie = parseLojban("iai")  # 4.9 rule 3, `.i.ai` or `.ia.i`; constructed
    check tie.refusal.to(cstring) == "Stream"
    check tie.stream.refusal.to(cstring) == "Split"  # 3.3, two splits of fewest pauses
    check tie.stream.detail.to(cstring) == "ia i, or i ai"


  test "Byte of refusal counts text in UTF-8, apart from index of JavaScript string":
    let
      text = "la'o gy. Größe .gy. cu barda le zarc"  # 19.10, `la'o` quotes name; constructed
      start = parseLojban(cstring(text)).start.to(int)
    check start == text.find("zarc")  # byte where `zarc` opens, as Nim indexes text
    check start == 34
    check cstring(text).toJs.indexOf(cstring("zarc")).to(int) == 32  # `ö` and `ß` one unit each


  test "NIF of every fourth sentence of sample that reads reads back, and rebuilds tree whole":
    var count = 0
    for k in countup(0, SENTENCES_TATOEBA.high, STRIDE_NIF):
      if SENTENCES_TATOEBA[k].verdict.len > 0: continue  # refusal holds no tree
      let reading = SENTENCES_TATOEBA[k].text.readText
      check reading.isReadBack  # `test_nif.nim`, law of native build
      inc count
    check count >= COUNT_TREES_LEAST  # IX.3, guard keeps sentences that read


  test "parseLojbanToNif gives module native build writes, and null where text is refused":
    check $parseLojbanToNif(cstring(EXAMPLE_NIF.text)) == EXAMPLE_NIF.module  # `test_nif.nim`
    check parseLojbanToNif("mi klama le zarc").isNil  # refusal holds no tree; constructed
    let quoted = $parseLojbanToNif("la'o gy. Größe .gy.")  # 19.10, `la'o`; constructed
    check "\"Größe\"" in quoted  # UTF-8 bytes from 128 through string of JavaScript, unescaped


reportEnd(if countFailures() > 0: 1 else: 0)  # code of run, once each test reported
