## Hold parser to fixed sample of lojban sentences of Tatoeba against `prose.nim`: each sentence
##   keeps verdict parser gave at render, and each refused one breaks rule of CLL cited here.
##   Sample is `tests/sample_tatoeba/sentences.nim`, which verb `tatoeba` of `tools/build.nim`
##     writes under licence of Tatoeba beside it (ruling `D4 c` of #819); never library output.
##   Verdict holds sentence that reads to reading, and refused one to its refusal and rule, so
##     change of parser that moves any verdict fails here, naming sentence.
##   Each refused sentence of sample is read here against CLL 1.1, and its citation gives rule it
##     breaks. Rule refusal names is where reading stops, which can lie past rule broken.
##   Features sample reaches stay reached, counted against `COUNT_FEATURES_TATOEBA`; reading and
##     features come from `tools/tatoeba.nim`, so suite and verb define them once (II.9).
##   Sample does not cover yet: rules no sentence of export reaches, `rp-expression` and
##     `rp-operand` of reverse Polish mex, which `test_grammar.nim` holds by Section 18.16.

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[sets, unittest]

import ../../tools/tatoeba
import ../sample_tatoeba/sentences


const IDS_REFUSED = [
  634760,  # 4.8, `sepide` ends in vowel, so no cmene; rule 32 takes no `se pi de` after `mi'e`
  645249,  # 972, CAhA takes no NAI: `ka'enai`
  645284,  # 97, cmene `jim` stands as sumti only after `la`
  656510,  # 972, CAhA takes no NAI: `ka'enai`
  657753,  # 131, `na` stands before selbri, never after it
  678056,  # 1100, `ba'e` makes `pei` word of its own, which no rule takes after `.i`
  1484737,  # 4.11, `s` and `b` need `y` between them: `dusybarda`
  1502454,  # 4.8, cmene holds no `la` after vowel: `Milan`
  1576931,  # 111, brivla `xotli` after tail term `ti` needs `le` before `ti`
  2024281,  # 97, NAhE before sumti needs `bo`: `je'a bo ko'a`
  2063807,  # 111, `la do` needs selbri after `do`
  2108189,  # 131, `na` takes selbri, and no rule takes `bo` after it
  2119742,  # 97, cmene `tom` stands as sumti only after `la`
  2159050,  # 4.7, `djunko` fails test of slinku'i, as `badjunko` is lujvo
  2253980,  # 134, `je` joins selbri, and `cu` opens none
  2312326,  # 131, NA takes no NAI: `ja'anai`
  2332321,  # 50, bridi tails join by GIhA, never `je`
  2577894,  # 97, cmene takes `la`, never `lo`: `lo tom`
  2626994,  # 972, NAhE stands before what it negates, never at end: `je'a`
  2688629,  # 161, `bei` takes term, and `se irsi` is selbri
  2793895,  # 97, cmene `borg` stands as sumti only after `la`
  2802254,  # 972, SE takes BAI alone among tags, never FAhA `ne'i`
  2803459,  # 81, terms join by `pe'e je`, never bare `je` after `vau`
  2808680,  # chapter 20, `di'ai` stands in no selma'o CLL 1.1 gives
  2853152,  # 152, NAI follows no brivla: `djica nai`
  2864592,  # 152, NAI follows no brivla: `slabu nai`
  2988210,  # 152, NAI follows no brivla: `lakne nai`
  3083055,  # 97, NAI follows no KOhA: `mi nai`
  3807272,  # 385, MOhE takes sumti, and `namcrgogolo` is brivla
  3807297,  # 19.10, delimiter closing text of `zoi` is word opening it: `dy` against `gy`
  3843946,  # 3.1, `H` and `!` are no letters of lojban
  3855768,  # 812, NAI follows no PA: `su'e nai`
  3989793,  # 97, LAhE takes sumti, and `pu ku` is term
  4167581,  # 112, `ku` closes sumti, and `djuno` is selbri
  4225380,  # 3.3, comma parts syllables of one run, and stands where no pause may
  4226728,  # 135, `je ca bo` takes selbri after it, never `cu`
  4285480,  # 3.3, `i'e` and `ei'e` open with vowel, so text owes period before one of them
  4412245,  # 4.1, `vfd` holds no vowel, so it fits no class of word
  4436842,  # 807, GA takes NAI, never JA: `ganai`
  5181396,  # 152, `nu` takes bridi, and `lo ckafi` holds no selbri
  5181743,  # 3.3, apostrophe stands between vowels alone: `mi''a`
  5183488,  # 383, numbers join by ek or joik, never `je`: `pa je su'e`
  5912012,  # 3.9, capital marks stressed syllable or its vowel, never consonant alone: `Mi`
  8639562,  # 122, `ne` takes term, and `facki` is selbri
  8721221,  # 160, `be` takes term after it
  8738058,  # 40, terms stand before `cu`, so `na ku` after it has no place
  10789002,  # 152, `jai` takes one tag, then brivla; `pu` opens second tag
  12406452,  # 4.8, `ziri` ends in vowel, so no cmene; `la zi` then breaks rule 97
  13820484,  # 3.6, `s` and `b` differ in voicing, so no word holds `sb`: `beisbol`
]
  ## Number of each refused sentence of sample, read against CLL 1.1; citation gives rule broken.



suite "Internal: Tatoeba":
  test "Each sentence of sample keeps verdict parser gave, and sample keeps its features":
    var
      moved: seq[int]
      reached: HashSet[string]
    for sentence in SENTENCES_TATOEBA:
      let (verdict, features) = sentence.text.reading
      if verdict != sentence.verdict: moved.add sentence.id
      reached.incl features
    check moved == newSeq[int]()  # D4 c, each verdict as rendered
    check reached.len == COUNT_FEATURES_TATOEBA  # D4 c, features sample was chosen for


  test "Each refused sentence of sample is read against CLL, with rule it breaks":
    var refused: HashSet[int]
    for sentence in SENTENCES_TATOEBA:
      if sentence.verdict.len > 0: refused.incl sentence.id
    check refused == IDS_REFUSED.toHashSet  # IDS_REFUSED, citation beside each number
