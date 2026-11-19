## tcidu lo genvla pe lo jboselci'a ja'i le ci'erge'a pe `CLL 21.1` gi'e zbasu lo tricu pe lo javni
##     poi selcme
##
##   |----------------------|---------------------------------------------------------------------|
##   | lo cmene             | lo smuni                                                            |
##   |----------------------|---------------------------------------------------------------------|
##   | `EBNF`               | le bibi ci'ejva pe `CLL 21.1` ta'i le selci'a pe le cukta      |
##   | `Terminal`           | lo selma'o .a `BRIVLA` .a `CMENE` vu'o noi genlei lo valsi     |
##   | `Node`               | lo javni poi selcme gi'e vasru lo panzi ku'o .a pa genvla    |
##   | `Stop`               | lo stistu .e lo genvla poi le gerna ka'e tcidu ke'a vi    |
##   | `ReadingGrammar`     | lo tricu pe le selci'a .a lo stistu .ebo lo stijva       |
##   | `readGrammar`        | tcidu lo genvla ja'i le gerna pe `CLL 21.1`                    |
##   | `readGrammarMarked`  | tcidu lo genvla gi'e zbasu lo tricu poi sinxa lo stistu   |
##   | `LUT_CHAIN_BY_ENDS`  | lo javni poi jbini re javni                                         |
##   |                      | .i ro jgena cu vasru le bavla'i po'o                                |
##   | `LUT_NUMBER_BY_RULE` | lo namcu pe ro javni pe `CLL 21.1` ja'i lo cmene be le javni        |
##   |----------------------|---------------------------------------------------------------------|
##
## ni'o le gerna cu datni
##   .i `EBNF` vasru le ci'ejva pe `CLL 21.1` zi'e noi mintu le selci'a pe le cukta
##   .i `Logical Language Group` dunda le selci'a ro da
##   .i lo linji poi selkra lo kutle'u cu pagbu le javni poi lidne le linji
##
## ni'o ca lo nu fanva kei ro javni cu selga'i fi lo basyjva
##   .i se ki'u bo no javni cu selci'a re roi to `Article II.9` toi
##   .i lo cipra pe lo nu fanva cu cipra lo du'u le gerna cu vasru lo bibi javni kei .e lo du'u ro
##       cmene be lo javni cu selski kei .e lo du'u ro nu galfi .e ro nu gunma cu fasnu pa roi
##   .i le nu galfi cu selci'a ne'i `REWRITES`
##   .i le nu gunma cu selci'a ne'i `GROUPINGS`
##
## ni'o le snici'e cu mapti `CLL 21.1`
##   .i `|` sinxa lo nu cuxna
##   .i `[]` sinxa lo na'e bilga pagbu
##   .i `&` sinxa lo selsmu be zo ja
##   .i `...` sinxa lo nu rapli
##   .i `()` sinxa lo girzu
##   .i `#` sinxa `[free ...]` noi sinxa lo zifyga'i
##   .i `/X/` sinxa lo nu lo selci'a cu ka'e claxu lo famvla po'u `X`
##
## ni'o `...` zmadu `&` lo ka jorne
##   .i `&` zmadu `|` lo ka jorne
##   .i lo porsi cu zmadu `&` lo ka jorne
##   .i mupli fa lo nu `ZEhA [PU [NAI]]` zvati lo jbini be re `&` ne'i le javni pe li panocino
##
## ni'o `CLL 21.1` na cusku lo du'u xu kau lo porsi cu zmadu `&` lo ka jorne
##   .i le romoi jicmu gerna pe `YACC` zi'e noi `CLL 21.1` sitna lo namcu pe ke'a pilno lo drata nu
##       gunma ne'i le javni pe li sozere po'o
##   .i ne'i le javni ku `&` poi jorne lo temtcita .e lo cmavo be `CAhA` cu zvati ne'i `[NAhE]` .e
##       `[KI]`
##   .i se ki'u bo `GROUPINGS` ciska lo cukla grile'u pe le nu gunma
##   .i jdima fa lo nu `EBNF` stali lo ka mintu le selci'a pe le cukta
##   .i le nu gunma cu selci'a fi pa linji poi lamji `EBNF`
##
## ni'o le javni pe li papanono .e li papanopa cu cusku lo du'u lo gensu'a cu galfi lo valsi pu lo
##     nu le gerna cu tcidu
##   .i ro le gensu'a cu selsni pa valsi
##   .i `ZO any-word` selsni `ZO`
##   .i `LOhU any-word ... LEhU` selsni `LOhU`
##   .i `ZOI any-word anything any-word` selsni `ZOI`
##   .i `any-word (ZEI any-word) ...` selsni `ZEI`
##   .i `any-word BU` selsni `BU`
##   .i `prose.nim` jmina le valsi pe ro gensu'a fi pa pagbu pu lo nu le gerna cu tcidu le valsi to
##       `#814` toi
##
## ni'o le genturfa'i cu pilno le tadji pe `Earley`
##   .i ki'u bo le gerna cu vasru lo javni poi selkra vo'a
##   .i mupli fa `rp-expression` noi selkra vo'a sepi'o `rp-operand`
##   .i le gerna cu vasru lo selcu'a poi ka'e kunti ku'o gi'e ka'e dunda re tricu pa selci'a
##   .i lo tadji po'u `recursive descent` na ka'e tcidu le gerna
##   .i le genturfa'i cu tcidu lo selci'a va'o lo nu su'o cumtricu cu vasru le selci'a
##
## ni'o le tricu cu du le cumtricu poi vasru lo mecraijva poi mulno pu ro genvla
##   .i le pamoi gerna valsi cu krasi lo nu cuxna
##   .i se ki'u bo lo gensu'a poi romoi cfari cu vasru ro valsi poi ka'e pagbu le gensu'a
##   .i va'o lo nu le selci'a cu claxu zo ke'e kei le gensu'a cu mulno bu'u lo fanmo be le selbri to
##       `CLL 5.5` toi
##   .i lo me `relative-clauses` me'u poi se lidne zo be ckini lo romoi sumti poi zo be .a zo bei
##       jorne ke'a to `CLL 5.7` toi
##   .i va'o lo nu su'o re cumtricu cu dunli kei lo pamoi se cuxna pe lo javni cu jinga
##
## ni'o `CLL 21.1` curmi lo nu lo selci'a cu claxu lo famvla va'o po'o lo nu le gerna na dunda re
##     tricu le selci'a
##   .i `CLL 21.1` na cusku lo du'u ma kau poi tricu cu selcu'a
##   .i se ki'u bo lo nu cuxna cu mapti lo mupli pe `CLL`
##   .i lo genturfa'i poi tcidu ro valsi pu lo bavla'i valsi gi'e zmanei lo nu tcidu lo genvla kei
##       lo nu lo javni cu mulno cu cuxna le tricu poi le vi genturfa'i cu cuxna ke'a
##   .i mupli fa `YACC`
##
## ni'o jdima fa lo nu lo temci pe lo nu tcidu ta'i `Earley` cu ka'e zensmi lo tenfa be lo te kancu
##     be lo gerna valsi be'o bei li ci
##   .i lo nu cuxna lo tricu cu karbi lo te kancu be lo javni sinxa poi mulno ne'i ro se kuspe poi
##       le tricu cu vasru ke'a
##   .i se ki'u bo `readGrammar` tcidu ro pagbu be le selci'a
##   .i le selci'a cu selka'a bu'u zo ni'o .e zo .i
##   .i lo temci cu zensmi lo ni le selci'a cu clani to `#849` toi
##   .i ku'i va'o lo nu zo lu .a zo to cu ca'o kalri kei le pagbu poi vasru le kravla cu selfa'o le
##       fanmo be le selci'a gi'e se tcidu pa roi
##
## ni'o lo ni lo selci'a cu clani cu se jimte no da
##   .i se ki'u bo le genturfa'i cu pilno `seq` .e `Table` ca lo nu le samtci cu gunka to
##       `STYLE.md §4` toi
##   .i `stream` pilno `seq` .e `Table`
##
## ni'o lo nu to'e curmi cu cusku lo stuzi poi ro cumtricu cu sisti bu'u ke'a ku'o .e lo javni poi
##     selcme gi'e sisti bu'u le stuzi gi'e traji lo ka ce'u selvau
##
## ni'o lo porsi be lo javni cu porsi lo javni poi selcme ne'i lo tricu
##   .i ro le javni cu vasru le bavla'i javni po'o
##   .i mupli fa lo nu `sumti` vasru `sumti-1` po'o va'o lo nu lo selci'a cu na vasru
##       `relative-clauses`
##   .i ki'u lo nu so'i javni pe `CLL 21.1` jorne ta'i lo porsi kei so'a jgena pe ro tricu cu pagbu
##       lo porsi be lo javni
##
## ni'o ca lo nu fanva kei le genturfa'i cu facki ro porsi be lo javni be'o poi `CLL 21.1` curmi
##     ke'a
##   .i lo cipra cu cipra lo du'u ro re fanmo cu dunda pa porsi po'o
##   .i se ki'u bo `nif.nim` ciska ro porsi sepi'o le re fanmo be le porsi po'o
##   .i lo nu raptcidu cu dunda le multricu
##
## ni'o va'o lo nu le gerna cu to'e curmi lo selci'a kei `readGrammarMarked` dunda lo tricu poi
##     sinxa ro srera
##   .i se ki'u bo lo drata samtci cu ka'e cikre le selci'a ja'i le tricu
##   .i le vi genturfa'i cu jdice no nu cikre to lo seljdi po'u `D1 a` bu'u `#859` toi
##   .i lo srejge cu ponse lo cmene .e lo namcu vu'o pe le javni poi sisti gi'e traji lo ka ce'u
##       selvau ku'o gi'e ponse pa `Stop`
##   .i `Stop` vasru lo stuzi poi ro cumtricu cu sisti bu'u ke'a ku'o .e lo genvla poi su'o cumtricu
##       cu tcidu ke'a bu'u le stuzi
##
## ni'o va'o lo nu le nu tcidu ro pagbu cu katna lo selci'a fi lo pagbu kei ro pagbu cu se tcidu
##     ta'i lo nu sepli
##   .i le srejge pe le selci'a cu vasru lo tricu pe ro pagbu poi se tcidu ge'u .e lo srejge pe ro
##       pagbu poi na se tcidu
##   .i se ki'u bo lo nu tcidu cu rapcfa bu'u ro valsi po'u zo ni'o ge'u .e ro valsi po'u zo .i zi'e
##       poi jorne no da
##   .i `Architect` jdice di'u bu'u `#859`
##
## ni'o lo srejge pe pa pagbu cu vasru lo rairbraricpau poi mapti `CLL 21.1` ku'o .e lo genvla poi
##     zvati lo jbini be le ricpau
##   .i le gacri cu vasru lo mecraigenvla poi na pagbu su'o ricpau
##   .i ba bo le gacri cu vasru lo mleca traji pagbu to `islands` toi
##   .i va'o lo nu ro selcmi cu kanpe ro javni poi selcme kei le selcmi cu facki ro ricpau
##   .i lo du'u le selci'a pu na'e mapti lo javni bu'u ma kau na vajni
##
## ni'o jdima fa lo nu le nu zbasu lo srejge pe pa mulselci'a cu tcidu le mulselci'a pa roi
##   .i ca lo nu `readGrammar` to'e curmi kei `readGrammar` tcidu le mulselci'a pa roi
##   .i jdima fa lo nu ro selcmi pe lo pagbu poi se to'e curmi cu vasru ro javni poi selcme

{.experimental: "strictFuncs".}

import std/[algorithm, options, sequtils, sets, strutils, tables]

import ./[forms, selmaho, tanru]


const EBNF* = """
text 0= [NAI ...] [CMENE ... # | (indicators & free ...)] [joik-jek] text-1
text-1 2= [(I [jek | joik] [[stag] BO] #) ... | NIhO ... #] [paragraphs]
paragraphs 4= paragraph [NIhO ... # paragraphs]
paragraph 10= (statement | fragment) [I # [statement | fragment]] ...
statement 11= statement-1 | prenex statement
statement-1 12= statement-2 [I joik-jek [statement-2]] ...
statement-2 13= statement-3 [I [jek | joik] [stag] BO # [statement-2]]
statement-3 14= sentence | [tag] TUhE # text-1 /TUhU#/
fragment 20= ek # | gihek # | quantifier | NA # | terms /VAU#/ | prenex | relative-clauses |
    links | linkargs
prenex 30= terms ZOhU #
sentence 40= [terms [CU #]] bridi-tail
subsentence 41= sentence | prenex subsentence
bridi-tail 50= bridi-tail-1 [gihek [stag] KE # bridi-tail /KEhE#/ tail-terms]
bridi-tail-1 51= bridi-tail-2 [gihek # bridi-tail-2 tail-terms] ...
bridi-tail-2 52= bridi-tail-3 [gihek [stag] BO # bridi-tail-2 tail-terms]
bridi-tail-3 53= selbri tail-terms | gek-sentence
gek-sentence 54= gek subsentence gik subsentence tail-terms | [tag] KE # gek-sentence /KEhE#/ |
    NA # gek-sentence
tail-terms 71= [terms] /VAU#/
terms 80= terms-1 ...
terms-1 81= terms-2 [PEhE # joik-jek terms-2] ...
terms-2 82= term [CEhE # term] ...
term 83= sumti | (tag | FA #) (sumti | /KU#/) | termset | NA KU #
termset 85= NUhI # gek terms /NUhU#/ gik terms /NUhU#/ | NUhI # terms /NUhU#/
sumti 90= sumti-1 [VUhO # relative-clauses]
sumti-1 91= sumti-2 [(ek | joik) [stag] KE # sumti /KEhE#/]
sumti-2 92= sumti-3 [joik-ek sumti-3] ...
sumti-3 93= sumti-4 [(ek | joik) [stag] BO # sumti-3]
sumti-4 94= sumti-5 | gek sumti gik sumti-4
sumti-5 95= [quantifier] sumti-6 [relative-clauses] | quantifier selbri /KU#/ [relative-clauses]
sumti-6 97= (LAhE # | NAhE BO #) [relative-clauses] sumti /LUhU#/ | KOhA # | lerfu-string /BOI#/
    | LA # [relative-clauses] CMENE ... # | (LA | LE) # sumti-tail /KU#/ | LI # mex /LOhO#/ | ZO
    any-word # | LU text /LIhU#/ | LOhU any-word ... LEhU # | ZOI any-word anything any-word #
sumti-tail 111= [sumti-6 [relative-clauses]] sumti-tail-1 | relative-clauses sumti-tail-1
sumti-tail-1 112= [quantifier] selbri [relative-clauses] | quantifier sumti
relative-clauses 121= relative-clause [ZIhE # relative-clause] ...
relative-clause 122= GOI # term /GEhU#/ | NOI # subsentence /KUhO#/
selbri 130= [tag] selbri-1
selbri-1 131= selbri-2 | NA # selbri
selbri-2 132= selbri-3 [CO # selbri-2]
selbri-3 133= selbri-4 ...
selbri-4 134= selbri-5 [joik-jek selbri-5 | joik [stag] KE # selbri-3 /KEhE#/] ...
selbri-5 135= selbri-6 [(jek | joik) [stag] BO # selbri-5]
selbri-6 136= tanru-unit [BO # selbri-6] | [NAhE #] guhek selbri gik selbri-6
tanru-unit 150= tanru-unit-1 [CEI # tanru-unit-1] ...
tanru-unit-1 151= tanru-unit-2 [linkargs]
tanru-unit-2 152= BRIVLA # | GOhA [RAhO] # | KE # selbri-3 /KEhE#/ | ME # sumti /MEhU#/ [MOI #]
    | (number | lerfu-string) MOI # | NUhA # mex-operator | SE # tanru-unit-2 | JAI # [tag]
    tanru-unit-2 | any-word (ZEI any-word) ... | NAhE # tanru-unit-2 | NU [NAI] # [joik-jek NU
    [NAI] #] ... subsentence /KEI#/
linkargs 160= BE # term [links] /BEhO#/
links 161= BEI # term [links]
quantifier 300= number /BOI#/ | VEI # mex /VEhO#/
mex 310= mex-1 [operator mex-1] ... | FUhA # rp-expression
mex-1 311= mex-2 [BIhE # operator mex-1]
mex-2 312= operand | [PEhO #] operator mex-2 ... /KUhE#/
rp-expression 330= rp-operand rp-operand operator
rp-operand 332= operand | rp-expression
operator 370= operator-1 [joik-jek operator-1 | joik [stag] KE # operator /KEhE#/] ...
operator-1 371= operator-2 | guhek operator-1 gik operator-2 | operator-2 (jek | joik) [stag] BO
    # operator-1
operator-2 372= mex-operator | KE # operator /KEhE#/
mex-operator 374= SE # mex-operator | NAhE # mex-operator | MAhO # mex /TEhU#/ | NAhU # selbri
    /TEhU#/ | VUhU #
operand 381= operand-1 [(ek | joik) [stag] KE # operand /KEhE#/]
operand-1 382= operand-2 [joik-ek operand-2] ...
operand-2 383= operand-3 [(ek | joik) [stag] BO # operand-2]
operand-3 385= quantifier | lerfu-string /BOI#/ | NIhE # selbri /TEhU#/ | MOhE # sumti /TEhU#/ |
    JOhI # mex-2 ... /TEhU#/ | gek operand gik operand-3 | (LAhE # | NAhE BO #) operand /LUhU#/
number 812= PA [PA | lerfu-word] ...
lerfu-string 817= lerfu-word [PA | lerfu-word] ...
lerfu-word 987= BY | any-word BU | LAU lerfu-word | TEI lerfu-string FOI
ek 802= [NA] [SE] A [NAI]
gihek 818= [NA] [SE] GIhA [NAI]
jek 805= [NA] [SE] JA [NAI]
joik 806= [SE] JOI [NAI] | interval | GAhO interval GAhO
interval 932= [SE] BIhI [NAI]
joik-ek 421= joik # | ek #
joik-jek 422= joik # | jek #
gek 807= [SE] GA [NAI] # | joik GI # | stag gik
guhek 808= [SE] GUhA [NAI] #
gik 816= GI [NAI] #
tag 491= tense-modal [joik-jek tense-modal] ...
stag 971= simple-tense-modal [(jek | joik) simple-tense-modal] ...
tense-modal 815= simple-tense-modal # | FIhO # selbri /FEhU#/
simple-tense-modal 972= [NAhE] [SE] BAI [NAI] [KI] | [NAhE] (time [space] | space [time]) & CAhA
    [KI] | KI | CUhE
time 1030= ZI & time-offset ... & ZEhA [PU [NAI]] & interval-property ...
time-offset 1033= PU [NAI] [ZI]
space 1040= VA & space-offset ... & space-interval & (MOhI space-offset)
space-offset 1045= FAhA [NAI] [VA]
space-interval 1046= ((VEhA & VIhA) [FAhA [NAI]]) & space-int-props
space-int-props 1049= (FEhE interval-property) ...
interval-property 1051= number ROI [NAI] | TAhE [NAI] | ZAhO [NAI]
free 32= SEI # [terms [CU #]] selbri /SEhU/ | SOI # sumti [sumti] /SEhU/ | vocative
    [relative-clauses] selbri [relative-clauses] /DOhU/ | vocative [relative-clauses] CMENE ...
    # [relative-clauses] /DOhU/ | vocative [sumti] /DOhU/ | (number | lerfu-string) MAI | TO
    text /TOI/ | XI # (number | lerfu-string) /BOI/ | XI # VEI # mex /VEhO/
vocative 415= (COI [NAI]) ... & DOI
indicators 411= [FUhE] indicator ...
indicator 413= (UI | CAI) [NAI] | Y | DAhO | FUhO
"""
  ## le ci'ejva pe `CLL 21.1`
  ##   .i le javni cu pagbu le romoi jicmu gerna pe `EBNF` gi'e mintu le selci'a pe `CLL 1.1`


type
  Terminal* = distinct int  ## lo selma'o .a `BRIVLA` .a `CMENE` vu'o noi genlei lo valsi

  Symbol = object
    ## lo sinxa pe lo basyjva
    ##   .i le sinxa cu du lo genvla .a lo jvasni pe le gerna
    is_terminal: bool
    code: int  ## lo namcu pe lo genvla .a lo stuna'u pe lo jvasni

  Production = object  ## pa tadji be lo nu pa jvasni cu binxo lo porsi be lo sinxa
    head: int  ## lo stuna'u pe le jvasni poi binxo le porsi
    body: seq[Symbol]
      ## lo porsi be lo sinxa poi selbi'o
      ##   .i le porsi cu kunti va'o lo kutselcu'a

  Grammar = object  ## lo gerna poi selzba fi `EBNF` gi'e vasru lo jvasni .e lo basyjva
    names: seq[string]
      ## lo cmene be ro jvasni
      ##   .i lo djujva cu ponse lo cmene be le javni poi vasru le djujva
    numbers: seq[Option[int]]
      ## lo namcu pe ro javni poi selcme ne'i `CLL 21.1`
      ##   .i lo djujva cu ponse no namcu
    productions: seq[Production]
    heads: seq[seq[int]]  ## lo basyjva pe ro jvasni ja'i le porsi pe le selcu'a
    nullable: seq[bool]  ## le jvasni cu ka'e binxo lo kutpoi
    lengths: seq[int]  ## lo mecraiterkancu be lo genvla poi ro jvasni cu binxo ke'a
    start: int  ## lo stuna'u pe `text` noi du le javni pe li no

  Builder = object  ## lo gerna poi ca'o selzba fi lo pagbu be pa javni pe `EBNF`
    grammar: Grammar
    lut_index_by_name: Table[string, int]
    tokens: seq[string]
    at: int  ## lo stuna'u pe le bavla'i pagbu poi se tcidu
    rule: int
      ## lo stuna'u pe le javni poi ca'o se tcidu
      ##   .i lo djujva cu cpacu lo cmene le javni
    frees: Option[int]
      ## le djujva poi `#` sinxa ke'a zi'e po'u `[free ...]`
      ##   .i le djujva cu selzba pa roi

  Stop* = object
    ## lo stistu pe le selci'a ge'u .e lo genvla poi le gerna ka'e tcidu ke'a vi
    at*: int
      ## lo stuna'u pe le genvla poi ro cumtricu cu sisti bu'u ke'a
      ##   .i va'o lo nu ro cumtricu cu sisti bu'u lo fanmo be le selci'a kei le stuna'u cu du lo te
      ##       kancu be le gerna valsi
    expected*: seq[Terminal]
      ## lo genvla poi su'o cumtricu cu tcidu ke'a bu'u `at` ku'o ja'i le porsi pe le namcu

  Node* = object
    ## lo jgena pe lo tricu
    ##   .i le jgena cu du lo javni poi selcme ne'i `CLL 21.1` gi'e vasru lo jgena ku'o .a lo genvla
    case is_terminal*: bool
    of true:
      at*: int  ## lo stuna'u pe le genvla ne'i lo genvla poi se tcidu
    of false:
      rule*: string  ## lo cmene be le javni mu'u `sumti-6`
      number*: int  ## lo namcu pe le javni ne'i `CLL 21.1` mu'u li soze
      children*: seq[Node]
      stop*: Option[Stop] = none(Stop)
        ## lo stistu pe le gerna va'o lo nu le jgena cu sinxa lo srera
        ##   .i le javni pe le jgena cu du le javni poi sisti vi gi'e traji lo ka ce'u selvau
        ##   .i lo panzi be le jgena cu du lo ricpau poi mapti `CLL 21.1` ku'o .e lo genvla poi
        ##       zvati lo jbini be le tricu pagbu to `readGrammarMarked` toi
        ##   .i va'o lo nu le jgena cu mapti `CLL 21.1` kei le datnypau cu kunti

  ReadingGrammar* = object  ## lo jalge be lo nu tcidu lo genvla ja'i le gerna pe `CLL 21.1`
    case is_read*: bool
    of true:
      tree*: Node  ## le javni po'u `text` ge'u .e ro da poi le javni cu vasru ke'a
    of false:
      at*: int
        ## lo stuna'u pe le genvla poi ro cumtricu cu sisti bu'u ke'a
        ##   .i va'o lo nu ro cumtricu cu sisti bu'u lo fanmo be le selci'a kei le stuna'u cu du lo
        ##       te kancu be le gerna valsi
      rule*: string
        ## le cmene .e le namcu vu'o pe le javni poi selcme gi'e sisti vi gi'e traji lo ka ce'u
        ##     selvau
        ##   .i mupli fa `sumti-6 97`
      head: int
        ## le jvasni pe le javni
        ##   .i le srejge poi `readGrammarMarked` dunda ke'a cpacu le jvasni
      expected: seq[Terminal]
        ## lo genvla poi su'o cumtricu cu tcidu ke'a bu'u `at` ku'o ja'i le porsi pe le namcu

  Item = tuple[production, dot, origin: int]
    ## lo cmima pe `Earley` zi'e noi vasru lo basyjva .e lo stuzi be lo nu tcidu ne'i le basyjva
    ##     be'o .e le selcmi poi le cmima cu cfari ne'i ke'a


const
  TERMINAL_BRIVLA* = Terminal(ord(Selmaho.high) + 1)  ## lo brivla noi gismu ja lujvo ja fu'ivla
  TERMINAL_CMENE* = Terminal(ord(Selmaho.high) + 2)  ## lo cmene
  REWRITES = [
    ("ZO any-word #", "ZO #"), ("LOhU any-word ... LEhU #", "LOhU #"),
    ("ZOI any-word anything any-word #", "ZOI #"), ("any-word (ZEI any-word) ...", "ZEI"),
    ("any-word BU", "BU"),
  ]
    ## lo gensu'a poi le gerna cu tcidu ke'a ta'i pa valsi
    ##   .i `prose.nim` jmina le valsi pe ro gensu'a pu lo nu le gerna cu tcidu to le javni pe li
    ##       papanono .e li papanopa toi
  GROUPINGS = [
    (
      "[NAhE] (time [space] | space [time]) & CAhA [KI]",
      "[NAhE] ((time [space] | space [time]) & CAhA) [KI]",
    ),
  ]
    ## lo nu gunma poi `CLL 21.1` na jdice fi ke'a
    ##   .i le romoi jicmu gerna pe `YACC` zi'e po'u `grammar.300` dunda le nu gunma
    ##   .i ne'i `grammar.300` le javni pe li sozere cu curmi lo nu lo cmavo be `NAhE` cu lidne lo
    ##       temci tcita po'o .a lo cmavo be `CAhA` po'o to le javni pe li sozeci .e li sozebi toi
    ##   .i lo cmavo be `KI` cu ka'e se lidne lo temtcita .a lo cmavo be `CAhA` to le javni pe li
    ##       sozeze toi
  COUNT_RULES = 88
    ## lo te kancu be le ciste javni pe `CLL 21.1`
    ##   .i le javni pe li papanono .e li papanopa cu na se kancu
  BOUND_LENGTH = 1 shl 20
    ## lo jimte be lo mecraiterkancu be lo genvla pe ro jvasni
    ##   .i le jimte cu zmadu ro te kancu poi selfa'i
  DELIMITERS = {'[', ']', '(', ')', '|', '&', '#', '/'}
    ## lo sinxa pe le snici'e
    ##   .i le stodi na vasru `...`


func `==`*(a, b: Terminal): bool {.borrow.}
  ## karbi lo re genvla sepi'o lo namcu pe le genvla

func toTerminal*(selmaho: Selmaho): Terminal = Terminal(ord(selmaho))
  ## ralte lo selma'o ta'i lo genvla


func toTerminal*(reading: Reading): Option[Terminal] =
  ## ralte lo valsi ta'i lo genvla
  ##   .i lo cmavo cu selsni lo selma'o be vo'a
  ##   .i lo cmene cu selsni `CMENE`
  ##   .i lo gismu .e lo lujvo .e lo fu'ivla cu selsni `BRIVLA` to `CLL 21.1` toi
  ##   .i lo se tcidu poi se to'e curmi ku'o .e lo cmavo poi no liste cu dunda lo selma'o ke'a
  ##       selsni no genvla
  if not reading.is_word: return none(Terminal)
  case reading.kind
  of Kind.Cmavo:
    if reading.selmaho.isSome: some(reading.selmaho.get.toTerminal) else: none(Terminal)
  of Kind.Cmene: some(TERMINAL_CMENE)
  of Kind.Gismu, Kind.Lujvo, Kind.Fuhivla: some(TERMINAL_BRIVLA)


func `$`*(terminal: Terminal): string =
  ## ciska lo genvla ja'i `CLL 21.1`
  ##   .i lo selma'o cu selci'a sepi'o lo cmene be le selma'o
  ##   .i va'o lo drata `BRIVLA` .a `CMENE` selci'a
  if terminal == TERMINAL_BRIVLA: "BRIVLA"
  elif terminal == TERMINAL_CMENE: "CMENE"
  else: $Selmaho(int(terminal))



#[ ni'o ni'o ni'o lo nu fanva ]#

func toRules(text: string): seq[string] =
  ## jmina ro linji poi pagbu pa javni pe le selci'a ku'o le javni
  ##   .i ba bo pilno ro nu galfi .e ro nu gunma pa roi
  for line in text.splitLines:
    if line.len == 0: continue
    if line[0] == ' ': result[^1].add " " & line.strip
    else: result.add line
  var joined = result.join("\n")
  for (before, after) in @REWRITES & @GROUPINGS:
    doAssert joined.count(before) == 1, "Rewrite should apply once; got `" & before & "`."
    joined = joined.replace(before, after)
  joined.split("\n")


func toTokens(text: string): seq[string] =
  ## fendi le selsku pe pa javni fi lo cmene .e `...` .e lo sinxa pe le snici'e
  var at = 0
  while at < text.len:
    if text[at] == ' ':
      inc at
    elif text.continuesWith("...", at):
      result.add "..."
      at += 3
    elif text[at] in DELIMITERS:
      result.add $text[at]
      inc at
    else:
      let start = at
      while at < text.len and text[at] notin DELIMITERS + {' '} and
          not text.continuesWith("...", at):
        inc at
      result.add text[start ..< at]


func index(builder: var Builder, name: string): int =
  ## facki lo jvasni poi selcme `name`
  ##   .i jmina le jvasni ca lo pamoi nu pilno
  if name notin builder.lut_index_by_name:
    builder.lut_index_by_name[name] = builder.grammar.names.len
    builder.grammar.names.add name
    builder.grammar.numbers.add none(int)
    builder.grammar.heads.add newSeq[int]()
  builder.lut_index_by_name[name]


func addHelper(builder: var Builder): int =
  ## jmina pa jvasni poi sinxa pa pagbu be le javni poi ca'o se tcidu
  ##   .i le jvasni cu selcme le cmene be le javni
  let index = builder.grammar.names.len
  builder.grammar.names.add builder.grammar.names[builder.rule]
  builder.grammar.numbers.add none(int)
  builder.grammar.heads.add newSeq[int]()
  index


func addProduction(builder: var Builder, head: int, body: seq[Symbol]) =
  ## jmina pa basyjva poi `head` binxo `body` sepi'o ke'a
  builder.grammar.heads[head].add builder.grammar.productions.len
  builder.grammar.productions.add Production(head: head, body: body)


func toSymbol(builder: var Builder, name: string): Symbol =
  ## tcidu lo cmene be lo javni ta'i lo jvasni
  ##   .i tcidu lo cmene poi selci'a ta'i lo brale'u ku'o ta'i lo gerna valsi to `CLL 21.1` toi
  if name[0] in {'a' .. 'z'}: return Symbol(is_terminal: false, code: builder.index(name))
  if name == "BRIVLA": return Symbol(is_terminal: true, code: int(TERMINAL_BRIVLA))
  if name == "CMENE": return Symbol(is_terminal: true, code: int(TERMINAL_CMENE))
  let selmaho = name.toSelmaho
  doAssert selmaho.isSome, "Terminal of 21.1 should name selma'o; got `" & name & "`."
  Symbol(is_terminal: true, code: ord(selmaho.get))


func peek(builder: Builder): string =
  ## dunda le bavla'i pagbu
  ##   .i va'o lo nu le javni cu fanmo kei dunda lo kunti lerpoi
  if builder.at < builder.tokens.len: builder.tokens[builder.at] else: ""


func parseAlternation(builder: var Builder): seq[seq[Symbol]]


func toHelper(builder: var Builder, bodies: seq[seq[Symbol]]): Symbol =
  ## jmina pa djujva poi ka'e binxo ro cmima be `bodies`
  ##   .i dunda lo sinxa be le djujva
  let helper = builder.addHelper
  for body in bodies: builder.addProduction(helper, body)
  Symbol(is_terminal: false, code: helper)


func parseItem(builder: var Builder): Symbol =
  ## tcidu pa pagbu po'u lo cmene .a lo na'e bilga pagbu po'u `[]` ge'u .a lo girzu po'u `()` ge'u
  ##     .a lo famvla poi ka'e selcau zi'e po'u `/X/` ge'u .a `#`
  ##   .i va'o lo nu `...` se lidne le pagbu kei le pagbu cu se rapli
  let token = builder.peek
  inc builder.at
  case token
  of "[":
    result = builder.toHelper(builder.parseAlternation & @[newSeq[Symbol]()])
    doAssert builder.peek == "]", "Option should close with `]`."
    inc builder.at
  of "(":
    result = builder.toHelper(builder.parseAlternation)
    doAssert builder.peek == ")", "Group should close with `)`."
    inc builder.at
  of "/":
    var body: seq[Symbol]
    while builder.peek != "/": body.add builder.parseItem
    inc builder.at
    result = builder.toHelper(@[body, newSeq[Symbol]()])  # lo famvla cu selcau gi'a selci'a
  of "#":
    if builder.frees.isNone:
      let
        helper = builder.addHelper
        free = Symbol(is_terminal: false, code: builder.index("free"))
        frees = Symbol(is_terminal: false, code: helper)
      builder.addProduction(helper, @[])
      builder.addProduction(helper, @[frees, free])
      builder.frees = some(helper)
    result = Symbol(is_terminal: false, code: builder.frees.get)
  else:
    result = builder.toSymbol(token)
  while builder.peek == "...":
    inc builder.at
    let repeated = builder.addHelper
    builder.addProduction(repeated, @[result])
    builder.addProduction(repeated, @[Symbol(is_terminal: false, code: repeated), result])
    result = Symbol(is_terminal: false, code: repeated)


func parseSequence(builder: var Builder): seq[Symbol] =
  ## tcidu lo pagbu poi lamji
  ##   .i le nu tcidu cu sisti bu'u `|` .a `&` .a lo fanmo be lo girzu .a lo fanmo be le javni
  while builder.peek notin ["", "|", "&", "]", ")"]: result.add builder.parseItem


func parseAndOr(builder: var Builder): seq[Symbol] =
  ## tcidu lo porsi poi seljo'e `&`
  ##   .i `A & B` du `A | B | A B` to `CLL 21.1` toi
  ##   .i `A & B & C` du `(A & B) & C`
  result = builder.parseSequence
  while builder.peek == "&":
    inc builder.at
    let right = builder.parseSequence
    result = @[builder.toHelper(@[result, right, result & right])]


func parseAlternation(builder: var Builder): seq[seq[Symbol]] =
  ## tcidu lo selcu'a poi seljo'e `|`
  result.add builder.parseAndOr
  while builder.peek == "|":
    inc builder.at
    result.add builder.parseAndOr


func constructGrammar(text: string): Grammar {.compileTime.} =
  ## galfi ro javni pe `EBNF` fi lo basyjva gi'e facki lo jvasni poi ka'e binxo lo kutpoi
  var builder: Builder
  let rules = text.toRules
  doAssert rules.len == COUNT_RULES, "21.1 should give " & $COUNT_RULES & " formal rules."

  # tcidu ro javni
  #   .i le javni cu vasru lo cmene ce'o lo namcu ce'o lo selsku
  for rule in rules:
    let
      (header, expression) = (rule.split("=", 1)[0], rule.split("=", 1)[1])
      (name, number) = (header.splitWhitespace[0], header.splitWhitespace[1].parseInt)
    builder.rule = builder.index(name)
    doAssert builder.grammar.numbers[builder.rule].isNone, "Rule should be defined once."
    builder.grammar.numbers[builder.rule] = some(number)
    builder.tokens = expression.toTokens
    builder.at = 0
    for body in builder.parseAlternation: builder.addProduction(builder.rule, body)
    doAssert builder.at == builder.tokens.len, "Rule should be read whole; got `" & name & "`."
  result = builder.grammar
  for i, name in result.names:
    doAssert result.heads[i].len > 0, "Name should be defined by rule; got `" & name & "`."
  result.start = builder.lut_index_by_name["text"]

  # sinxa lo jvasni poi ka'e binxo lo kutpoi
  #   .i le nu sinxa cu fanmo ca lo nu no cnino cu selfa'i
  result.nullable = newSeq[bool](result.names.len)
  var is_changed = true
  while is_changed:
    is_changed = false
    for production in result.productions:
      if result.nullable[production.head]: continue
      if production.body.allIt(not it.is_terminal and result.nullable[it.code]):
        result.nullable[production.head] = true
        is_changed = true

  # facki lo mecraiterkancu be lo genvla poi ro jvasni cu ka'e binxo ke'a
  #   .i le nu facki cu fanmo ca lo nu no te kancu cu jdika
  #   .i le jimte cu fanta lo nu lo sumji cu cimni
  result.lengths = newSeqWith(result.names.len, BOUND_LENGTH)
  is_changed = true
  while is_changed:
    is_changed = false
    for production in result.productions:
      var total = 0
      for symbol in production.body:
        let length = (if symbol.is_terminal: 1 else: result.lengths[symbol.code])
        total = min(total + length, BOUND_LENGTH)
      if total < result.lengths[production.head]:
        result.lengths[production.head] = total
        is_changed = true

  # cipra lo du'u ro jvasni poi xruti vo'a sepi'o lo basyjva poi vasru pa sinxa po'o cu xruti vo'a
  #     sepi'o pa basti javni po'o
  #   .i `choose` nitcu di'u
  #   .i lo sinxa cu binxo pa javni sinxa po'o va'o lo nu ro datsni pe le basyjva cu ka'e binxo lo
  #       kutpoi
  var units = newSeq[seq[int]](result.names.len)
  for production in result.productions:
    for i, symbol in production.body:
      if symbol.is_terminal or symbol.code == production.head: continue
      let others = production.body[0 ..< i] & production.body[i + 1 .. ^1]
      if others.allIt(not it.is_terminal and result.nullable[it.code]):
        units[production.head].add symbol.code
  for head in 0 ..< result.names.len:
    var
      reached: HashSet[int]
      stack = units[head]
    while stack.len > 0:
      let code = stack.pop
      if reached.containsOrIncl(code): continue
      stack.add units[code]
    doAssert head notin reached, "Unit cycle should be self-loop; got `" & result.names[head] & "`."


const GRAMMAR_EBNF = constructGrammar(EBNF)  ## le gerna pe `CLL 21.1` zi'e noi se fanva pa roi


func constructChains(grammar: Grammar): Table[(int, int), seq[tuple[rule: string, number: int]]]
    {.compileTime.} =
  ## zbasu ro porsi be lo javni poi selcme
  ##   .i ro jgena pe le porsi cu vasru le bavla'i po'o
  ##   .i lo namcu pe le javni poi krasi le porsi ku'o .e lo namcu pe le javni poi fanmo le porsi cu
  ##       ckiku le porsi
  ##   .i cipra lo du'u ro re fanmo cu dunda pa porsi po'o kei .e lo du'u no porsi cu xruti
  ##
  ## ni'o va'o lo nu lo basyjva pe lo javni poi selcme cu binxo pa javni po'o kei le javni poi
  ##     selcme cu vasru le pa javni po'o
  ##   .i ro datsni pe le basyjva cu du lo djujva poi binxo no jgena
  ##   .i ki'u bo ro javni poi selcme cu jgena
  ##   .i le javni cu jgena ji'a va'o lo nu kunti
  let count = grammar.names.len
  func isHelper(grammar: Grammar, code: int): bool = grammar.numbers[code].isNone

  # sinxa lo djujva poi binxo no jgena
  #   .i le djujva cu binxo lo kutpoi sepi'o lo sidju javni po'o
  var nodeless = newSeq[bool](count)
  template isNodeless(symbol: Symbol): bool =
    ## jdice lo du'u xu kau le sinxa cu djujva poi pu selsni ta'i lo nu binxo no jgena
    not symbol.is_terminal and grammar.isHelper(symbol.code) and nodeless[symbol.code]
  var is_changed = true
  while is_changed:
    is_changed = false
    for production in grammar.productions:
      if not grammar.isHelper(production.head) or nodeless[production.head]: continue
      if production.body.allIt(it.isNodeless):
        nodeless[production.head] = true
        is_changed = true

  # facki lo javni poi selcme zi'e poi ro jvasni cu binxo ke'a po'o
  #   .i le nu facki cu fanmo ca lo nu no cnino cu selfa'i
  var alone = newSeq[HashSet[int]](count)
  is_changed = true
  while is_changed:
    is_changed = false
    for production in grammar.productions:
      for i, symbol in production.body:
        if symbol.is_terminal: continue
        let others = production.body[0 ..< i] & production.body[i + 1 .. ^1]
        if not others.allIt(it.isNodeless): continue
        let found =
          if grammar.isHelper(symbol.code): alone[symbol.code] else: [symbol.code].toHashSet
        for code in found:
          if not alone[production.head].containsOrIncl(code): is_changed = true

  # litru ro porsi be lo javni be'o poi selkra lo javni poi selcme
  #   .i le re fanmo be le porsi cu ckiku le porsi
  for top in 0 ..< count:
    if grammar.isHelper(top): continue
    var stack = @[@[top]]
    while stack.len > 0:
      let path = stack.pop
      for next in alone[path[^1]].toSeq.sorted:
        doAssert next notin path, "Chain should hold no cycle; got `" & grammar.names[next] & "`."
        let key = (grammar.numbers[top].get, grammar.numbers[next].get)
        doAssert key notin result, "Two ends should give one chain; got `" & grammar.names[top] &
          "` to `" & grammar.names[next] & "`."
        let chain = path & next
        result[key] = chain.mapIt((rule: grammar.names[it], number: grammar.numbers[it].get))
        stack.add chain


const LUT_CHAIN_BY_ENDS* = GRAMMAR_EBNF.constructChains
  ## lo javni pe ro porsi noi ro jgena pe ke'a vasru le bavla'i po'o
  ##   .i lo namcu pe le javni poi krasi le porsi ku'o .e lo namcu pe le javni poi fanmo le porsi cu
  ##       ckiku le porsi
  ##   .i mupli fa lo porsi poi selkra `terms` noi ckini li bino ku'o gi'e selfa'o `sumti-6` noi
  ##       ckini li soze
  ##   .i le porsi cu porsi ro javni poi jbini le re javni ne'i `CLL 21.1`


func constructNumbers(grammar: Grammar): Table[string, int] {.compileTime.} =
  ## zbasu lo namcu pe ro javni poi selcme ja'i lo cmene be le javni
  ##   .i cipra lo du'u no re javni cu ponse lo mitcme .a lo mitna'u
  ##   .i se ki'u bo lo cmene cu dunda lo namcu
  ##   .i lo namcu cu dunda lo cmene
  var named: Table[int, string]
  for code in 0 ..< grammar.names.len:
    if grammar.numbers[code].isNone: continue
    let (name, number) = (grammar.names[code], grammar.numbers[code].get)
    doAssert name notin result, "Name should name one rule; got `" & name & "`."
    doAssert number notin named, "Number should number one rule; got `" & $number & "`."
    result[name] = number
    named[number] = name
  doAssert result.len == COUNT_RULES, "Each rule should take number; got " & $result.len & "."


const LUT_NUMBER_BY_RULE* = GRAMMAR_EBNF.constructNumbers
  ## lo namcu pe ro javni poi selcme ne'i `CLL 21.1` ja'i lo cmene be le javni
  ##   .i mupli fa li soze noi du le namcu pe `sumti-6`
  ##   .i `NIF` ciska lo cmene po'o be le javni poi fanmo ro porsi
  ##   .i lo tcidu be `NIF` cu cpacu le namcu le vi stodi
  ##   .i `Architect` jdice di'u bu'u `#859` to `comment 6805527878` toi



#[ ni'o ni'o ni'o lo nu tcidu ]#

const WIDTH_BODY = GRAMMAR_EBNF.productions.mapIt(it.body.len).max + 1
  ## lo namcu poi zmadu ro stuzi pe lo nu tcidu ne'i ro basyjva


type
  Completions = seq[Table[int, seq[int]]]
    ## lo basyjva poi mulno ne'i ro selcmi ku'o ja'i lo jvasni .e lo kraselcmi to `keyCompleted` toi

  Choice = object
    ## le cumtricu pe pa jvasni bu'u pa selku'e
    ##   .i le tricu cu cuxna le cumtricu
    closures: seq[int]
      ## lo te kancu be lo javni sinxa pe le cumki tricu zi'e poi mulno bu'u ro stuzi pe le se kuspe
      ##   .i le pamoi te kancu cu ckini le krasi be le selku'e
      ##   .i lo genturfa'i poi tcidu ro valsi pu lo bavla'i valsi cu mulgau le jvasni bu'u le stuzi
      ##       pu lo nu tcidu le genvla pe le stuzi
    production: int
    bounds: seq[int]  ## lo stuzi be lo fanmo be ro sinxa pe le basyjva

  Chart = object
    ## lo mulcmi pe pa pagbu ge'u .e lo selcu'a poi selfa'i ca lo nu cuxna le tricu
    ##   .i ro selcmi cu stali va'o lo nu ro genvla poi lidne le selcmi cu stali to `fillSets` toi
    terminals: seq[Terminal]  ## lo genvla poi le selcmi cu tcidu ke'a
    sets: seq[seq[Item]]  ## le selcmi pe `Earley`
    firsts: seq[int]  ## le pamoi cmima poi denpa ro jvasni ne'i ro selcmi
    lasts: seq[int]  ## le romoi cmima poi denpa ro jvasni ne'i ro selcmi
    nexts: seq[seq[int]]  ## le bavla'i cmima poi denpa le jvasni pe ro cmima ne'i ro selcmi
    predicted: seq[int]  ## lo selcmi poi le jvasni pu se kanpe ne'i ke'a
    completions: Completions  ## to `fillCompletions` toi
    count_completed: int  ## lo te kancu be lo selcmi poi `completions` cu fendi ke'a
    choices: seq[Table[int, Option[Choice]]]
      ## lo selcu'a ja'i le fanmo .e lo jvasni .e lo krasi to `keyCompleted` toi
    open: HashSet[int]
      ## lo selku'e poi ca'o selcu'a gi'e ka'e selrapcpa ki'u lo nu pa jvasni cu xruti vo'a

  ChartsKept* = object
    ## lo mulcmi pe le romoi pagbu poi se tcidu
    ##   .i ro selcmi pe le mulcmi cu stali va'o lo nu ro genvla poi lidne le selcmi cu stali
    ##   .i se ki'u bo lo tcidu be lo mivyselci'a cu tisna lo selcmi po'o pe lo valsi poi cnino
    whole: Chart  ## le mulcmi pe `readWhole`
    everywhere: Chart  ## le mulcmi pe `islands`


func fillSets(chart: var Chart, terminals: openArray[Terminal], is_everywhere: bool) =
  ## tisna lo selcmi pe `Earley`
  ##   .i le selcmi pe `i` vasru lo cmima poi su'o cumtricu cu klama ke'a ba lo nu tcidu lo genvla
  ##       noi lo te kancu be ke'a cu du `i`
  ##   .i ca lo nu kanpe pa jvasni poi ka'e binxo lo kutpoi kei le cmima cu pagre le jvasni
  ##   .i `Aycock` .e `Horspool` pilno le vi tadji
  ##
  ## ni'o `is_everywhere` rinka lo nu ro selcmi cu kanpe ji'a ro javni poi selcme
  ##   .i se ki'u bo le mulcmi cu vasru ro selku'e poi su'o javni poi selcme cu kuspe ke'a
  ##   .i lo du'u le selci'a cu na'e mapti lo javni bu'u ma kau pu le selku'e cu na vajni to
  ##       `islands` toi
  ##
  ## ni'o so'a lo temci pe lo nu tcidu cu zvati le fancu
  ##   .i le fancu cu selpli pa roi ro selci'a
  ##   .i ro selcmi cu fendi lo cmima be vo'a ja'i lo jvasni poi le cmima cu denpa ke'a
  ##   .i se ki'u bo ca lo nu pa jvasni cu mulno kei le fancu cu tcidu lo cmima po'o poi denpa le
  ##       jvasni
  ##   .i ro selcmi cu kanpe ro jvasni pa roi
  ##
  ## ni'o lo cmima poi denpa pa jvasni ne'i pa selcmi cu porsi ta'i lo nu ro le cmima cu jarco le
  ##     bavla'i to `firsts` .e `lasts` .e `nexts` toi
  ##   .i lo namcu poi sinxa ro cmima cu zmadu le stuna'u pe le cmima ne'i le selcmi fo li pa
  ##   .i se ki'u bo li no cu sinxa lo nu no cmima cu zasti
  ##   .i le porsi cu jmina lo cmima ja'i le porsi pe lo nu jmina
  ##   .i lo te kancu be lo cmima cu zensmi lo ni le selci'a cu clani
  ##   .i ro cmima cu cpacu lo ninstu
  ##
  ## ni'o `predicted` cu rinka lo nu ro jvasni cu se kanpe pa roi ne'i ro selcmi
  ##   .i se ki'u bo ro cmima pe lo nu kanpe cu frica
  ##   .i ro cmima pe lo nu tcidu lo genvla cu frica ki'u lo nu ro cmima pe le pu selcmi cu frica
  ##   .i lo cmima pe lo nu tcidu lo genvla cu frica ro cmima poi pagre lo jvasni
  ##   .i se ki'u bo `seen` cu ralte lo cmima po'o poi pagre lo jvasni ne'i le ca selcmi
  ##   .i ro selcmi cu vasru lo cmima ja'i le porsi pe lo nu jmina
  ##   .i `refusal` cu pilno le porsi ca lo nu cuxna
  ##
  ## ni'o pa namcu po'o cu sinxa pa cmima ne'i `seen` gi'e selzba sepi'o lo nu pilji
  ##   .i ki'u bo `shl` cu katna lo namcu ne'i `JavaScript`
  ##
  ## ni'o lo porsi be lo sinxa pe lo basyjva cu selcme pa `template`
  ##   .i `let` na selpli ki'u lo nu `let` fukpi le porsi ca ro cmima
  ##   .i lo na'e zmiku cipra cu tcidu lo samtci pe `C` zi'e poi le fanva cu ciska ke'a
  ##   .i lo cmima cu vasru ci namcu gi'e selfu'i ta'i lo nu fukpi le ci namcu
  ##
  ## ni'o le fancu cu ralte ro selcmi pe `chart` poi ro genvla poi lidne ke'a cu mintu lo genvla pe
  ##     `terminals`
  ##   .i ki'u bo ro selcmi cu sarcu lo genvla po'o poi lidne ke'a
  ##   .i ba bo le fancu cu tcidu le genvla pe le romoi selcmi poi stali gi'e tisna ro selcmi poi se
  ##       lidne ri
  ##   .i ji'a le fancu cu vimcu ro cmima pe `completions` .e `choices` poi le selcmi pe ke'a cu
  ##       cnino

  template key(item: Item): int =
    ## lo namcu poi sinxa le cmima ne'i le ca selcmi
    (item.production * WIDTH_BODY + item.dot) * (terminals.len + 1) + item.origin

  template add(i: int, item: Item) =
    ## jmina le cmima le selcmi pe `i`
    ##   .i le selcmi cu fendi le cmima ja'i le jvasni poi le cmima cu denpa ke'a
    let added: Item = item
    template bodyAdded: untyped = GRAMMAR_EBNF.productions[added.production].body
      ## sinxa le porsi be lo sinxa pe le basyjva pe le selmincmi
    chart.sets[i].add added
    chart.nexts[i].add 0
    if added.dot < bodyAdded.len and not bodyAdded[added.dot].is_terminal:
      let slot = i * count_nonterminals + bodyAdded[added.dot].code
      if chart.lasts[slot] == 0: chart.firsts[slot] = chart.sets[i].len
      else: chart.nexts[i][chart.lasts[slot] - 1] = chart.sets[i].len
      chart.lasts[slot] = chart.sets[i].len

  template advance(i: int, item: Item) =
    ## jmina le cmima poi pagre lo jvasni le selcmi pe `i` va'o lo nu le cmima cu na pu zvati ri
    let advanced: Item = item
    if not seen.containsOrIncl(advanced.key): add(i, advanced)

  let count_nonterminals = GRAMMAR_EBNF.heads.len
  var
    same = 0  # lo te kancu be lo genvla poi stali
    first = 0  # le pamoi selcmi poi le fancu cu tisna ke'a
    seen = initHashSet[int]()  # lo cmima poi pagre lo jvasni ne'i le ca selcmi
  if chart.sets.len > 0:
    let most = min(chart.terminals.len, terminals.len)
    while same < most and chart.terminals[same] == terminals[same]: inc same
    first = same + 1
  chart.sets.setLen(first)
  chart.sets.setLen(terminals.len + 1)
  chart.firsts.setLen(first * count_nonterminals)
  chart.firsts.setLen((terminals.len + 1) * count_nonterminals)
  chart.lasts.setLen(first * count_nonterminals)
  chart.lasts.setLen((terminals.len + 1) * count_nonterminals)
  chart.nexts.setLen(first)
  chart.nexts.setLen(terminals.len + 1)
  chart.count_completed = min(chart.count_completed, first)
  chart.completions.setLen(chart.count_completed)
  chart.choices.setLen(min(chart.choices.len, first))
  chart.choices.setLen(terminals.len + 1)
  chart.terminals = @terminals
  if first == 0:
    chart.predicted = newSeqWith(count_nonterminals, -1)
    chart.predicted[GRAMMAR_EBNF.start] = 0
    for p in GRAMMAR_EBNF.heads[GRAMMAR_EBNF.start]: add(0, (p, 0, 0))
  else:
    # le romoi selcmi poi stali cu tcidu le genvla poi se lidne ri
    #   .i lo cmima poi se kanpe ne'i lo selcmi poi cnino cu na stali
    for head in 0 ..< count_nonterminals:
      if chart.predicted[head] >= first: chart.predicted[head] = -1
    if same < terminals.len:
      for k in 0 ..< chart.sets[same].len:
        let item = chart.sets[same][k]
        template body: untyped = GRAMMAR_EBNF.productions[item.production].body
          ## sinxa le porsi be lo sinxa pe le basyjva pe le cmima
        let is_scanned = item.dot < body.len and body[item.dot].is_terminal and
          int(terminals[same]) == body[item.dot].code
        if is_scanned: add(same + 1, (item.production, item.dot + 1, item.origin))
  for i in first .. terminals.len:
    # ro cmima pe le selcmi cu se tcidu pa roi
    #   .i `firsts` .e `lasts` .e `predicted` .e `seen` cu cpacu no ninstu ne'i le selcmi va'o lo nu
    #       `seen` cu na zenba
    #   .i `nexts` .e le liste be lo cmima cu zenba ta'i lo cmima
    #   .i lo temci pe `seen.clear` cu zensmi lo ni `seen` cu barda
    #   .i lo temci pe ro nu mulno cu zensmi lo klani be le porsi poi le nu mulno cu tcidu ke'a
    seen.clear
    if is_everywhere:
      for head in 0 ..< count_nonterminals:
        if GRAMMAR_EBNF.numbers[head].isNone or chart.predicted[head] == i: continue
        chart.predicted[head] = i
        for p in GRAMMAR_EBNF.heads[head]: add(i, (p, 0, i))
    var k = 0
    while k < chart.sets[i].len:
      let item = chart.sets[i][k]
      template body: untyped = GRAMMAR_EBNF.productions[item.production].body
        ## sinxa le porsi be lo sinxa pe le basyjva pe le cmima
      inc k

      # le cmima cu mulno
      #   .i ro cmima poi denpa le jvasni pe le vi cmima cu klama le bavla'i sinxa
      #   .i va'o lo nu le vi cmima cu binxo lo kutpoi kei le liste cu ka'e zenba ca lo nu le liste
      #       cu se tcidu
      #   .i se ki'u bo le nu tcidu cu pilno lo stuna'u
      if item.dot == body.len:
        let head = GRAMMAR_EBNF.productions[item.production].head
        var at = chart.firsts[item.origin * count_nonterminals + head]
        while at != 0:
          let waiter = chart.sets[item.origin][at - 1]
          advance(i, (waiter.production, waiter.dot + 1, waiter.origin))
          at = chart.nexts[item.origin][at - 1]
        continue

      # tcidu lo genvla gi'a kanpe lo jvasni
      let symbol = body[item.dot]
      if symbol.is_terminal:
        if i < terminals.len and int(terminals[i]) == symbol.code:
          add(i + 1, (item.production, item.dot + 1, item.origin))
        continue
      if chart.predicted[symbol.code] != i:
        chart.predicted[symbol.code] = i
        for p in GRAMMAR_EBNF.heads[symbol.code]: add(i, (p, 0, i))
      if GRAMMAR_EBNF.nullable[symbol.code]:
        advance(i, (item.production, item.dot + 1, item.origin))

func toRule(head: int): tuple[name: string, number: int] =
  ## dunda lo cmene .e lo namcu vu'o pe le javni pe le jvasni mu'u `sumti-6` .e li soze
  ##   .i lo djujva cu cpacu le cmene .e le namcu vu'o pe le javni poi vasru le djujva
  let name = GRAMMAR_EBNF.names[head]
  for i, other in GRAMMAR_EBNF.names:
    let number = GRAMMAR_EBNF.numbers[i]
    if other == name and number.isSome: return (name, number.get)
  doAssert false, "Helper should take name of rule holding it; got `" & name & "`."


func ruleNamed(head: int): string =
  ## dunda lo cmene .e lo namcu vu'o pe le javni pe le jvasni ta'i pa lerpoi mu'u `sumti-6 97`
  ##   .i lo djujva cu cpacu le cmene .e le namcu vu'o pe le javni poi vasru le djujva
  let rule = head.toRule
  rule.name & " " & $rule.number


func refusal(sets: openArray[seq[Item]]): ReadingGrammar =
  ## to'e curmi bu'u le romoi se cmima poi su'o cumtricu cu klama ke'a
  ##   .i cusku le javni pe le cmima poi zvati le selcmi gi'e denpa gi'e pu tcidu pa genvla gi'e
  ##       romoi cfari
  ##   .i lo cmima poi cfari ne'i le selcmi cu tcidu no genvla gi'e cusku no javni
  ##   .i lo genvla poi le cmima pe le selcmi cu denpa ke'a du lo genvla poi su'o cumtricu cu tcidu
  ##       ke'a vi
  var last = sets.high
  while sets[last].len == 0: dec last
  var
    best = none(Item)
    expected: seq[Terminal]
  for item in sets[last]:
    template body: untyped = GRAMMAR_EBNF.productions[item.production].body
      ## sinxa le porsi be lo sinxa pe le basyjva pe le cmima
      ##   .i lo nu pilno `let` cu rinka lo nu fukpi le porsi
    let is_waiting = item.dot < body.len
    if is_waiting and body[item.dot].is_terminal: expected.add Terminal(body[item.dot].code)
    if is_waiting and item.origin < last and (best.isNone or item.origin >= best.get.origin):
      best = some(item)
  let head = if best.isSome: GRAMMAR_EBNF.productions[best.get.production].head
             else: GRAMMAR_EBNF.start
  expected = expected.sortedByIt(int(it)).deduplicate(isSorted = true)
  ReadingGrammar(
    is_read: false, at: last, rule: head.ruleNamed, head: head, expected: expected,
  )


const WIDTH_KEY = high(int32) div GRAMMAR_EBNF.heads.len
  ## lo namcu poi zmadu lo krasi be ro pagbu
  ##   .i ro lo namcu pe `keyCompleted` cu mleca li re te'a ci pa


func keyCompleted(head, start: int): int =
  ## lo namcu poi sinxa lo jvasni .e lo kraselcmi ne'i pa selcmi pe `Completions` .e `Chart.choices`
  ##   .i pa namcu po'o cu sinxa le re namcu
  ##   .i le namcu cu stali va'o lo nu lo selcmi cu zenba
  ##   .i `PROVENANCE.md` cu jarco le krinu .e le namcu
  head * WIDTH_KEY + start


func keyChosen(width, head, start, finish: int): int =
  ## lo namcu poi sinxa lo jvasni .e lo krasi .e lo fanmo ne'i `Chart.open`
  ##   .i le gerna cu vasru ci ci re jvasni
  ##   .i le namcu cu mleca li re te'a ci pa va'o lo nu `width` cu na zmadu li re mu vo ci
  ##   .i va'o lo nu `width` cu zmadu li re mu vo ci kei `JavaScript` cu cusku lo nu dukse
  (head * width + start) * width + finish


func fillCompletions(chart: var Chart) =
  ## fendi ro mulcmi pe lo selcmi poi `completions` na pu fendi ke'a ku'o ja'i le selcmi poi le
  ##     cmima cu fanmo ne'i ke'a ku'o .e le jvasni .e le selcmi poi le cmima cu cfari ne'i ke'a
  chart.completions.setLen(chart.sets.len)
  for i in chart.count_completed ..< chart.sets.len:
    for item in chart.sets[i]:
      let production = GRAMMAR_EBNF.productions[item.production]
      if item.dot != production.body.len: continue
      let key = keyCompleted(production.head, item.origin)
      chart.completions[i].mgetOrPut(key, @[]).add item.production
    for key in chart.completions[i].keys.toSeq: chart.completions[i][key].sort
  chart.count_completed = chart.sets.len

func isFewer(a, b: seq[int]): bool =
  ## jdice lo du'u xu kau `a` mleca `b` lo ka mulgau lo jvasni kei bu'u le pamoi stuzi poi `a` .e
  ##     `b` frica bu'u ke'a
  for i in 0 ..< min(a.len, b.len):
    if a[i] != b[i]: return a[i] < b[i]
  false


func offer(partials: var seq[Option[Choice]], i: int, candidate: sink Choice) =
  ## ralte le cumselcu'a bu'u le stuzi pe `i` va'o lo nu le cumselcu'a cu mleca le selra'e lo ka
  ##     mulgau lo jvasni
  ##   .i va'o lo nu dunli kei le pamoi cu stali
  ##   .i ne'i `C` le cumselcu'a cu se muvgau gi'e se fukpi no roi
  ##   .i ne'i `JavaScript` lo nu cpacu le cumselcu'a cu fukpi le liste pe le cumselcu'a ci roi
  ##   .i lo na'e zmiku cipra cu tcidu le samtci pe `C` .e `JavaScript`
  if partials[i].isNone or candidate.closures.isFewer(partials[i].get.closures):
    partials[i] = some(candidate)


func extend(next: var Choice, closures: openArray[int]) =
  ## jmina lo te kancu be lo javni sinxa pe pa panzi `next`
  ##   .i le pamoi te kancu be le panzi cu mulno bu'u le romoi stuzi pe `next`
  ##   .i `closures` cu tcidu le liste pe le panzi ne'i `Chart.choices` gi'e fukpi no liste
  ##   .i lo na'e zmiku cipra cu tcidu le samtci pe `C` .e `JavaScript`
  next.closures[^1] += closures[0]
  for c in 1 ..< closures.len: next.closures.add closures[c]


func isDerived(chart: Chart, symbol: Symbol, start, finish: int): bool =
  ## jdice lo du'u xu kau `chart` jarco lo nu `symbol` binxo le genvla pe `start ..< finish`
  ##   .i va'o lo nu `symbol` genvla kei `symbol` binxo pa gerna valsi po'o poi mintu `symbol`
  ##   .i va'o lo nu `symbol` jvasni kei `symbol` mulno bu'u le selku'e gi'a binxo lo kutpoi va'o lo
  ##       nu le selku'e cu kunti
  if symbol.is_terminal:
    return finish == start + 1 and int(chart.terminals[start]) == symbol.code
  (start == finish and GRAMMAR_EBNF.nullable[symbol.code]) or
    keyCompleted(symbol.code, start) in chart.completions[finish]


func choose(chart: var Chart, head, start, finish: int): bool =
  ## cuxna le cumtricu poi `head` binxo le genvla pe `start ..< finish` sepi'o ke'a zi'e poi mecrai
  ##     lo ka mulgau lo jvasni bu'u ro stuzi
  ##   .i le se cuxna cu zvati `chart.choices`
  ##   .i le jalge cu jarco lo du'u xu kau le se cuxna cu zasti
  ##   .i se ki'u bo lo nu pilno le selcu'a cu fukpi no liste
  ##   .i le pamoi stuzi cu krasi lo nu cuxna
  ##   .i va'o lo nu dunli kei le pamoi basti javni cu jinga
  ##   .i ba bo lo sinxa poi zmadu lo ka clani cu jinga
  ##
  ## ni'o le selcu'a cu selra'e ba lo nu selfa'i
  ##   .i no sinxa cu troci lo nu kuspe lo genvla poi le sinxa poi se lidne cu nitcu ke'a
  ##   .i se ki'u bo lo panzi cu kuspe le mulselku'e va'o po'o lo nu ro datsni cu ka'e binxo lo
  ##       kutpoi
  ##   .i ro jvasni poi xruti vo'a sepi'o lo basyjva poi vasru pa sinxa po'o cu xruti vo'a sepi'o pa
  ##       basti javni po'o to `constructGrammar` toi
  ##   .i lo cumtricu poi xruti cu zmadu lo drata lo ka mulgau lo jvasni gi'e no roi selcu'a
  ##   .i se ki'u bo no selcu'a poi selra'e cu nitcu lo selku'e poi ca'o selcu'a
  ##
  ## ni'o le romoi sinxa pe le basyjva cu pilno le fanmo be le se kuspe po'o ta'i lo korbi
  ##   .i ki'u bo no datkoi cu rinka lo nu le basyjva cu kuspe le mulselku'e
  ##   .i lo temci pe ro datkoi pu zensmi lo pilji be lo klani be le selku'e be'o bei le klani ne'i
  ##       lo claselci'a
  ##
  ## ni'o le jvasni poi lidne le romoi sinxa cu pilno lo korbi po'o poi le romoi sinxa cu selfa'o le
  ##     fanmo be le selku'e va'o lo nu cfari bu'u ke'a
  ##   .i lo na'e mulno poi zvati lo datkoi cu no roi klama le fanmo
  ##   .i ro panzi poi no roi selpli pu selcu'a gi'e pu fukpi lo te kancu be lo javni sinxa poi
  ##       mulno
  ##   .i le te kancu pu clasmi le selku'e be le panzi
  ##   .i va'o lo nu pa kravla pu ca'o kalri kei le jdima pu zmadu le selci'a lo ka zenba to `#849`
  ##       toi
  let key = keyCompleted(head, start)
  if key in chart.choices[finish]: return chart.choices[finish][key].isSome
  let opened = keyChosen(chart.sets.len, head, start, finish)
  if chart.open.containsOrIncl(opened): return false
  defer: chart.open.excl(opened)
  let
    span = finish - start
    is_completed = span == 0 or key in chart.completions[finish]
  var best = none(Choice)
  for p in GRAMMAR_EBNF.heads[head]:
    template body: untyped = GRAMMAR_EBNF.productions[p].body
      ## sinxa le porsi be lo sinxa pe le basyjva po'u `p`
      ##   .i lo nu pilno `let` cu rinka lo nu fukpi le porsi
    if span == 0 and body.anyIt(it.is_terminal or not GRAMMAR_EBNF.nullable[it.code]): continue
    # `[]` cu dunda le liste sepi'o `lent` gi'e fukpi no da
    #   .i se to'e cuxna fa `getOrDefault` noi fukpi le liste
    #   .i lo na'e zmiku cipra cu tcidu le samtci pe `C` .e `JavaScript`
    if span > 0 and (not is_completed or p notin chart.completions[finish][key]): continue

    # tcidu ro sinxa pe le basyjva pu lo bavla'i sinxa
    #   .i bu'u ro stuzi le na'e mulno poi mecrai lo ka mulgau lo jvasni vi cu selra'e
    #   .i ro sinxa cu curmi lo nu lo sinxa poi se lidne cu ponse lo bazgenvla
    var
      # le mecraiterkancu be lo genvla poi ro rebla be le porsi cu binxo ke'a
      #   .i le klani be le porsi cu stodi
      #   .i se ki'u bo ne'i `C` le porsi cu cpacu no ninstu
      #   .i ne'i `JavaScript` ro basyjva cu zbasu pa `Int32Array`
      #   .i lo na'e zmiku cipra cu tcidu le samtci pe `C` .e `JavaScript`
      rests: array[WIDTH_BODY, int]
      partials = newSeq[Option[Choice]](span + 1)
    for k in countdown(body.high, 0):
      let length = (if body[k].is_terminal: 1 else: GRAMMAR_EBNF.lengths[body[k].code])
      rests[k] = rests[k + 1] + length
    partials[0] = some(Choice(closures: @[0], production: p))
    for k, symbol in body:
      var nexts = newSeq[Option[Choice]](span + 1)
      for m in start .. finish:
        template partial: untyped = partials[m - start]
          ## sinxa le na'e mulno se cuxna poi fanmo bu'u `m`
          ##   .i lo nu pilno `let` cu rinka lo nu fukpi le na'e mulno se cuxna
        if partial.isNone: continue
        if symbol.is_terminal:
          if m + 1 + rests[k + 1] <= finish and int(chart.terminals[m]) == symbol.code:
            var next = partial.get
            next.closures.add 0
            next.bounds.add m + 1
            nexts.offer(m + 1 - start, next)
          continue
        # le romoi sinxa cu selfa'o le fanmo be le selku'e
        let low = (if k == body.high: finish else: m)
        for bound in countdown(finish - rests[k + 1], low):
          if not chart.isDerived(symbol, m, bound): continue
          if k == body.high - 1 and not chart.isDerived(body[^1], bound, finish): continue  # morsi
          if not chart.choose(symbol.code, m, bound): continue
          var next = partial.get
          next.extend(chart.choices[bound][keyCompleted(symbol.code, m)].get.closures)
          next.bounds.add bound
          nexts.offer(bound - start, next)
      partials = nexts
    if partials[span].isNone: continue
    var whole = partials[span].get
    inc whole.closures[^1]  # `head` mulno bu'u le fanmo be le selku'e
    if best.isNone or whole.closures.isFewer(best.get.closures): best = some(whole)
  result = best.isSome
  chart.choices[finish][key] = best


func addNodes(chart: Chart, head, start, finish: int, nodes: var seq[Node]) =
  ## jmina lo jgena pe le selcu'a pe `head` bu'u le selku'e fi `nodes`
  ##   .i ro javni poi selcme cu jmina pa jgena poi vasru lo panzi be vo'a
  ##   .i ro djujva cu jmina lo jgena pe vo'a lo javni poi vasru le djujva
  ##
  ## ni'o lo jgena pe lo javni poi selcme cu zvati lo stuzi pe vo'a pu lo nu lo panzi be le jgena cu
  ##     tisna le jgena
  ##   .i se ki'u bo le nu zbasu cu fukpi no ricpau
  ##   .i di'u jetnu ji'a ne'i `JavaScript` noi `add` pe ke'a fukpi ro datni
  ##   .i le nu zbasu cu fukpi no `closures` pe le selcu'a
  ##   .i lo temci pe lo nu fukpi bu'u ro jgena cu pu zensmi lo pilji be lo klani be le selci'a be'o
  ##       bei le klani
  ##   .i ki'u bo ro ju'agri cu rinka lo nu le javni pe li vo cu punji pa jgena ne'i pa jgena to
  ##       `#849` toi
  let
    key = keyCompleted(head, start)
    production = chart.choices[finish][key].get.production
    bounds = chart.choices[finish][key].get.bounds
  template addChildren(into: var seq[Node]) =
    ## jmina lo jgena pe ro sinxa pe le basyjva fi `into` ja'i le porsi
    var at = start
    for k, symbol in GRAMMAR_EBNF.productions[production].body:
      if symbol.is_terminal: into.add Node(is_terminal: true, at: at)
      else: chart.addNodes(symbol.code, at, bounds[k], into)
      at = bounds[k]
  if GRAMMAR_EBNF.numbers[head].isNone:
    addChildren(nodes)
    return
  nodes.add Node(
    is_terminal: false, rule: GRAMMAR_EBNF.names[head], number: GRAMMAR_EBNF.numbers[head].get,
  )
  addChildren(nodes[^1].children)


func readWhole(chart: var Chart, terminals: openArray[Terminal]): ReadingGrammar =
  ## tcidu lo genvla pe le selci'a ja'i le gerna pe `CLL 21.1` pa roi gi'e zbasu lo tricu pe lo
  ##     javni poi selcme
  ##   .i to'e curmi bu'u le stuzi poi ro cumtricu cu sisti bu'u ke'a
  ##   .i `chart` cu ralte ro selcmi poi stali to `fillSets` toi
  chart.fillSets(terminals, is_everywhere = false)
  var is_whole = false
  for item in chart.sets[^1]:
    let
      production = GRAMMAR_EBNF.productions[item.production]
      is_text = production.head == GRAMMAR_EBNF.start and item.origin == 0
    if is_text and item.dot == production.body.len: is_whole = true
  if not is_whole: return chart.sets.refusal
  chart.fillCompletions
  var nodes: seq[Node]
  doAssert chart.choose(GRAMMAR_EBNF.start, 0, terminals.len),
      "Text grammar reads should derive tree."
  chart.addNodes(GRAMMAR_EBNF.start, 0, terminals.len, nodes)
  # le javni pe li no cu selcme
  #   .i se ki'u bo lo jgena cu pa mei
  ReadingGrammar(is_read: true, tree: nodes.pop)


func readWhole(terminals: openArray[Terminal]): ReadingGrammar =
  ## tcidu lo genvla pe le selci'a sepi'o lo mulcmi poi cnino
  var chart: Chart
  chart.readWhole(terminals)



#[ ni'o ni'o ni'o lo nu tcidu ro pagbu ]#

const
  OPENERS* = [Selmaho.Tuhe, Selmaho.Lu, Selmaho.To]
    ## lo selma'o poi krasi lo selci'a ne'i lo selci'a
    ##   .i le selma'o cu pagbu `statement-3` .e `sumti-6` .e `free` to le javni pe li pavo .e li
    ##       soze .e li cire toi
  CLOSERS* = [Selmaho.Tuhu, Selmaho.Lihu, Selmaho.Toi]
    ## lo famvla pe ro kravla ja'i le porsi pe `OPENERS`
  JOINS = {Selmaho.Ja, Selmaho.Joi, Selmaho.Bihi, Selmaho.Gaho, Selmaho.Bo}
    ## lo selma'o poi se lidne `I` gi'e jorne lo jufra ta'i lo me `jek` me'u .a lo me `joik` me'u .a
    ##     `BO`
    ##   .i le selma'o cu ka'e se lidne lo cmavo be `NA` be'o .e lo cmavo be `SE` to le javni pe li
    ##       pare .e li paci toi
  TAGS = {
    Selmaho.Nahe, Selmaho.Se, Selmaho.Bai, Selmaho.Nai, Selmaho.Ki, Selmaho.Cuhe, Selmaho.Zi,
    Selmaho.Pu, Selmaho.Zeha, Selmaho.Va, Selmaho.Faha, Selmaho.Mohi, Selmaho.Veha, Selmaho.Viha,
    Selmaho.Fehe, Selmaho.Tahe, Selmaho.Roi, Selmaho.Zaho, Selmaho.Caha, Selmaho.Pa, Selmaho.Na,
    Selmaho.Ja, Selmaho.Joi,
  }
    ## lo selma'o pe lo tcita poi lidne `BO` ne'i `statement-2` to le javni pe li paci .e `stag` toi
    ##   .i lo porsi be le selma'o be'o poi selfa'o `BO` jorne lo jufra
  RULE_TEXT_1 = ("text-1", 2)
    ## lo cmene .e lo namcu vu'o pe le javni poi vasru lo se ciska ju'agri
  RULE_PARAGRAPHS = ("paragraphs", 4)
  RULE_PARAGRAPH = ("paragraph", 10)
  RULE_STATEMENT_3 = ("statement-3", 14)
  RULE_FREE = ("free", 32)


type Split = tuple[parts: seq[Slice[int]], inner: int]
  ## lo pagbu be lo selci'a be'o poi se tcidu ta'i lo nu sepli ku'o .e lo krasi be le selci'a pe zo
  ##     tu'e poi ca'o kalri
  ##   .i va'o lo drata le krasi cu du le fanmo


func isAmong(terminal: Terminal, selmaho: set[Selmaho]): bool =
  ## jdice lo du'u xu kau le genvla cu cmavo pa cmima be `selmaho`
  int(terminal) <= ord(Selmaho.high) and Selmaho(int(terminal)) in selmaho


func isRule(node: Node, rule: (string, int)): bool =
  ## jdice lo du'u xu kau le jgena cu du le javni po'u `rule` kei sepi'o lo cmene .e lo namcu
  not node.is_terminal and node.rule == rule[0] and node.number == rule[1]


func isJoining(terminals: openArray[Terminal], at: int): bool =
  ## jdice lo du'u xu kau le cmavo be `I` be'o poi zvati `at` jorne lo jufra
  ##   .i va'o lo nu le cmavo cu lidne lo me `jek` me'u .a lo me `joik` kei le cmavo cu jorne
  ##   .i lo cmavo be `NA` be'o .e lo cmavo be `SE` cu ka'e zvati lo jbini
  ##   .i va'o lo nu le cmavo cu lidne lo porsi be lo tcita poi selfa'o `BO` kei le cmavo cu jorne
  ##       to le javni pe li pare .e li paci toi
  ##   .i ro le cmavo poi jorne cu vasru no ju'agri pe vo'a
  var k = at + 1
  while k < terminals.len and terminals[k].isAmong({Selmaho.Na, Selmaho.Se}): inc k
  if k < terminals.len and terminals[k].isAmong(JOINS): return true
  k = at + 1
  while k < terminals.len and terminals[k].isAmong(TAGS): inc k
  k > at + 1 and k < terminals.len and terminals[k] == Selmaho.Bo.toTerminal


func isCutAt*(terminals: openArray[Terminal], at: int, before: Option[Terminal]): bool =
  ## jdice lo du'u xu kau le nu tcidu ro pagbu cu katna le selci'a pu le genvla pe `at` va'o lo nu
  ##     no kravla cu ca'o kalri
  ##   .i le genvla cu du lo cmavo be `NIhO` be'o poi se lidne no cmavo be `NIhO` ku'o .a lo cmavo
  ##       be `I` poi jorne no da to `toParts` toi
  ##   .i `before` dunda le genvla poi lidne `at`
  let terminal = terminals[at]
  (terminal == Selmaho.Niho.toTerminal and before != some(Selmaho.Niho.toTerminal)) or
    (terminal == Selmaho.I.toTerminal and not terminals.isJoining(at))


func isTracked(
    opened: var seq[tuple[selmaho: Selmaho, at: int]], terminals: openArray[Terminal], i: int,
    ignored: openArray[int],
): bool =
  ## galfi le liste be lo kravla poi ca'o kalri sepi'o le genvla pe `i`
  ##   .i le romoi pe le liste cu traji lo ka ce'u selvau
  ##   .i lo kravla cu kalri va'o lo nu `ignored` na vasru le kravla
  ##   .i lo famvla cu fanmo le kravla poi mapti le famvla gi'e traji lo ka ce'u jibni le famvla
  ##       ku'o .e ro kravla poi zvati ne'i le kravla
  ##   .i le jalge cu du `true` va'o lo nu le genvla cu kravla gi'a famvla
  let terminal = terminals[i]
  if terminal.isAmong({OPENERS[0], OPENERS[1], OPENERS[2]}):
    if i notin ignored: opened.add (Selmaho(int(terminal)), i)
    return true
  if not terminal.isAmong({CLOSERS[0], CLOSERS[1], CLOSERS[2]}): return false
  let opener = OPENERS[CLOSERS.find(Selmaho(int(terminal)))]
  var k = opened.high
  while k >= 0 and opened[k].selmaho != opener: dec k
  if k >= 0: opened.setLen(k)
  true


func unclosed(terminals: openArray[Terminal], first, last: int): seq[int] =
  ## dunda lo stuna'u pe ro kravla poi zvati `first ..< last` zi'e poi no famvla poi zvati vi cu
  ##     fanmo ke'a ku'o ja'i le porsi
  ##   .i le kravla cu du zo tu'e .a zo lu .a zo to gi'e denpa lo famvla pe vo'a ne'i lo mivyselci'a
  var opened: seq[tuple[selmaho: Selmaho, at: int]]
  for i in first ..< last: discard opened.isTracked(terminals, i, [])
  opened.mapIt(it.at)


func toParts(
    terminals: openArray[Terminal], first, last: int, ignored: openArray[int] = []
): Split =
  ## fendi le genvla pe `first ..< last` fi lo pagbu poi se tcidu ta'i lo nu sepli
  ##   .i katna pu ro cmavo be `NIhO` be'o poi se lidne no cmavo be `NIhO` ku'o .e ro cmavo be `I`
  ##       be'o poi jorne no da
  ##   .i le nu katna cu fasnu va'o lo nu no kravla cu ca'o kalri
  ##
  ## ni'o `inner` krasi le selci'a pe zo tu'e poi no me zo tu'u cu fanmo ke'a
  ##   .i le selci'a cu selfa'o `last`
  ##   .i va'o lo drata `inner` du `last`
  ##
  ## ni'o ro nu katna cu zvati lo stuzi poi no kravla cu ca'o kalri vi ke'a
  ##   .i se ki'u bo ro nu katna cu zvati pu le pamoi krasi valsi poi ca'o kalri
  ##   .i va'o lo nu zo lu .a zo to cu ca'o kalri kei le pagbu poi vasru le kravla cu selfa'o `last`
  ##       gi'e se tcidu pa roi
  ##   .i ki'u bo lo valsi poi se lidne le kravla cu jdice lo du'u ma kau poi stuzi cu fanmo le
  ##       gensu'a pe le kravla
  ##
  ## ni'o lo kravla poi `ignored` vasru ke'a se tcidu ta'i lo sapygenvla
  ##   .i lo mivyselci'a cu selka'a ba ro kravla poi denpa lo famvla pe vo'a
  ##   .i se ki'u bo ro jufra poi se lidne le kravla cu selbe'i gi'e na denpa le famvla
  ##   .i `Architect` jdice di'u bu'u `#859`
  var
    starts = @[first]
    # ro kravla poi ca'o kalri
    #   .i le romoi cu traji lo ka ce'u selvau
    opened: seq[tuple[selmaho: Selmaho, at: int]]
  for i in first ..< last:
    if opened.isTracked(terminals, i, ignored): continue
    if opened.len == 0 and i > starts[^1] and terminals.isCutAt(i, some(terminals[i - 1])):
      starts.add i
  let
    is_inner = opened.len > 0 and opened[0].selmaho == Selmaho.Tuhe
    inner = (if is_inner: opened[0].at + 1 else: last)
  var parts: seq[Slice[int]]
  for k, start in starts:
    parts.add start .. (if k < starts.high: starts[k + 1] else: inner) - 1
  (parts, inner)


func shift(node: var Node, by: int) =
  ## jmina `by` ro stuzi poi le gerna cu sisti bu'u ke'a ku'o .e lo stuna'u pe ro genvla pe le tricu
  ##   .i va'o lo nu pa pagbu cu se tcidu ta'i lo nu sepli kei le stuna'u pe le krasi be le pagbu cu
  ##       du li no
  if node.is_terminal: node.at += by
  else:
    if node.stop.isSome: node.stop.get.at += by
    for child in node.children.mitems: child.shift(by)


func readPart(terminals: openArray[Terminal], part: Slice[int]): Option[Node] =
  ## tcidu le genvla pe le pagbu ta'i lo selci'a poi sepli
  ##   .i zbasu lo tricu
  ##   .i ne'i le tricu le stuna'u pe le krasi be le mulselci'a cu du li no
  var reading = terminals.toOpenArray(part.a, part.b).readWhole
  if not reading.is_read: return none(Node)
  var tree = move(reading.tree)
  tree.shift(part.a)
  some(tree)


func isGroup(nodes: openArray[Node], terminals: openArray[Terminal], head: Selmaho): bool =
  ## jdice lo du'u xu kau le jgena cu du lo genvla pe `head` ge'u ce'o lo zifre galfi po'o
  ##   .i mupli fa `I #` ja'i le javni pe li pano
  ##   .i mupli fa `NIhO ... #` ja'i le javni pe li vo
  ##   .i va'o lo nu lo me `jek` me'u .a lo me `joik` me'u .a lo tcita .a lo cmavo be `BO` cu zvati
  ##       vi kei lo jufra cu jorne
  var k = 0
  while k < nodes.len and nodes[k].is_terminal and terminals[nodes[k].at] == head.toTerminal: inc k
  k > 0 and nodes.toOpenArray(k, nodes.high).allIt(it.isRule(RULE_FREE))


func graftInner(node: var Node, at: int, inner: var Node): bool =
  ## punji `inner` noi me `text-1` ku'o lo jgena po'u `statement-3` zi'e poi zo tu'e pe ke'a zvati
  ##     `at`
  ##   .i le jgena cu selfa'i ne'i le romoi panzi be ro jgena
  ##   .i va'o lo nu le selci'a cu se tcidu ta'i lo nu sepli kei le jgena po'u `text-1` zi'e poi se
  ##       lidne zo tu'e cu kunti
  if node.is_terminal: return false
  if node.isRule(RULE_STATEMENT_3) and node.children.anyIt(it.is_terminal and it.at == at):
    if not node.children[^1].isRule(RULE_TEXT_1) or node.children[^1].children.len > 0:
      return false
    node.children[^1] = move(inner)
    return true
  node.children.len > 0 and node.children[^1].graftInner(at, inner)


func toNode(rule: (string, int), children: sink seq[Node]): Node =
  ## zbasu lo jgena poi vasru `children` zi'e pe lo javni poi selcme
  Node(is_terminal: false, rule: rule[0], number: rule[1], children: children)


func readParts(terminals: openArray[Terminal], first, last: int, trees: var seq[Node]): bool =
  ## tcidu ro pagbu be le selci'a pe le genvla pe `first ..< last` ta'i lo nu sepli
  ##   .i le pagbu cu selka'a ta'i le nu tcidu ro pagbu
  ##   .i punji le tricu `trees`
  ##   .i ba bo tcidu ro pagbu be le selci'a pe zo tu'e poi ca'o kalri
  ##   .i va'o lo nu pa pagbu cu se to'e curmi kei le jalge cu du `false`
  ##   .i va'o lo nu zo lu .a zo to cu ca'o kalri kei le pagbu poi vasru le kravla cu selfa'o `last`
  ##       ja'i le nu `toParts` katna
  let split = terminals.toParts(first, last)
  for part in split.parts:
    let tree = terminals.readPart(part)
    if tree.isNone: return false
    # fukpi
    #   .i ki'u bo `get` na dunda lo me `lvalue` me'u noi `move` nitcu ke'a ne'i `JavaScript`
    trees.add tree.get
  split.inner >= last or terminals.readParts(split.inner, last, trees)


func assemble(
    terminals: openArray[Terminal], first, last: int, parts: var seq[Node], at: var int
): Option[Node] =
  ## zbasu le tricu poi lo nu tcidu le mulselci'a cu dunda ke'a le selci'a pe le genvla pe
  ##     `first ..< last`
  ##   .i le tricu cu sruri le tricu pe ro pagbu be le selci'a
  ##   .i le tricu pe le pagbu cu se lebna fi `parts`
  ##   .i le nu lebna cu krasi `at` gi'e mapti le porsi poi `readParts` dunda ke'a
  ##   .i le jgena poi sruri cu du `text 0` .e `text-1 2` .e `paragraphs 4` .e `paragraph 10` to le
  ##       javni pe li no bi'o li pano toi
  ##
  ## ni'o ro pagbu cu vasru lo jgena
  ##   .i ro le jgena cu ckini pa javni po'o
  ##   .i lo tricu pe lo selcu'a cu stodi va'o lo nu le selku'e .e le javni cu stodi
  ##   .i ro javni poi sruri pa pagbu cu mulno ta'i lo mitytadji bu'u le re korbi be le pagbu
  ##   .i lo flalu cu cipra di'u sepi'o lo nu tcidu le mulselci'a
  ##
  ## ni'o va'o lo nu lo javni pe le nu tcidu ro pagbu cu spofu kei le jalge cu kunti
  ##   .i ba bo le mulselci'a cu se tcidu pa roi
  let split = terminals.toParts(first, last)
  if at + split.parts.len > parts.len: return none(Node)
  var trees: seq[Node]
  for _ in split.parts:
    trees.add move(parts[at])
    inc at

  # le pamoi pagbu cu dunda `text 0` .e lo jgena pe `text-1` zi'e poi lidne le ju'agri pe le pagbu
  #   .i ro ju'agri cu selvau lo girzu poi vasru lo cmavo be `NIhO` gi'e lidne le ju'agri ku'o .e lo
  #       jgena pe `paragraph` to le javni pe li re .e li vo toi
  var
    text = move(trees[0])
    text_1 = text.children.pop  # le javni pe li no cu selfa'o `text-1`
    paragraphs: seq[tuple[group, nodes: seq[Node]]]
  if text_1.children.len > 0 and text_1.children[^1].isRule(RULE_PARAGRAPHS):
    var first_paragraphs = text_1.children.pop
    if first_paragraphs.children.len != 1: return none(Node)
    paragraphs.add (newSeq[Node](), move(first_paragraphs.children[0].children))
  for k in 1 ..< trees.len:
    if trees[k].children.len != 1 or not trees[k].children[0].isRule(RULE_TEXT_1):
      return none(Node)  # le pagbu cu selkra lo valsi poi lo se ciska po'o cu ka'e selkra ke'a
    var
      part = move(trees[k].children[0])
      nodes: seq[Node]
      has_paragraph = false
    if part.children.len > 0 and part.children[^1].isRule(RULE_PARAGRAPHS):
      var part_paragraphs = part.children.pop
      if part_paragraphs.children.len != 1: return none(Node)
      nodes = move(part_paragraphs.children[0].children)
      has_paragraph = true
    let head = terminals[part.children[0].at]
    if head == Selmaho.I.toTerminal:
      if not part.children.isGroup(terminals, Selmaho.I): return none(Node)
      if paragraphs.len == 0:
        if text_1.children.anyIt(it.is_terminal and terminals[it.at] == Selmaho.Niho.toTerminal):
          # le javni pe li re cu selkra `I` .a `NIhO` gi'e no roi selkra le re mei
          return none(Node)
        for node in part.children.mitems: text_1.children.add move(node)
        if has_paragraph: paragraphs.add (newSeq[Node](), move(nodes))
      else:
        for node in part.children.mitems: paragraphs[^1].nodes.add move(node)
        for node in nodes.mitems: paragraphs[^1].nodes.add move(node)
    elif head == Selmaho.Niho.toTerminal:
      if not part.children.isGroup(terminals, Selmaho.Niho): return none(Node)
      if paragraphs.len == 0:
        if text_1.children.len > 0: return none(Node)  # le javni pe li re cu selkra pa girzu po'o
        for node in part.children.mitems: text_1.children.add move(node)
        if has_paragraph: paragraphs.add (newSeq[Node](), move(nodes))
      else:
        if not has_paragraph: return none(Node)  # le javni pe li vo cu vasru `paragraph` ba `NIhO`
        paragraphs.add (move(part.children), move(nodes))
    else:
      return none(Node)

  # le selci'a pe zo tu'e poi ca'o kalri cu selfa'o le fanmo
  #   .i zbasu le tricu pe le selci'a fi le pagbu be le selci'a gi'e punji le tricu le drastu
  if split.inner < last:
    var inner = terminals.assemble(split.inner, last, parts, at)
    if inner.isNone or paragraphs.len == 0: return none(Node)
    if inner.get.children.len != 1 or not inner.get.children[0].isRule(RULE_TEXT_1):
      # le selci'a pe zo tu'e me `text-1`
      #   .i `text-1` na selkra lo krapau pe `text`
      return none(Node)
    var inner_text_1 = move(inner.get.children[0])
    if paragraphs[^1].nodes.len == 0: return none(Node)
    if not paragraphs[^1].nodes[^1].graftInner(split.inner - 1, inner_text_1):
      return none(Node)

  # punji ro ju'agri ne'i le ju'agri poi lidne ke'a
  #   .i le nu punji cu krasi le romoi ju'agri
  #   .i ro ju'agri cu vasru le girzu pe le bavla'i ju'agri ge'u .e le rebla poi se lidne le girzu
  #       to le javni pe li vo toi
  var rest: seq[Node]
  for k in countdown(paragraphs.high, 0):
    var children = @[RULE_PARAGRAPH.toNode(move(paragraphs[k].nodes))]
    if rest.len > 0:
      for node in paragraphs[k + 1].group.mitems: children.add move(node)
      children.add rest.pop
    rest.add RULE_PARAGRAPHS.toNode(children)
  if rest.len > 0: text_1.children.add rest.pop
  text.children.add text_1
  some(text)


func buildText(terminals: openArray[Terminal], first, last: int): Option[Node] =
  ## tcidu ro pagbu be le selci'a pe le genvla pe `first ..< last` gi'e zbasu le tricu poi lo nu
  ##     tcidu le mulselci'a cu dunda ke'a gi'e sruri le jgena pe le pagbu to `assemble` toi
  ##   .i va'o lo nu pa pagbu cu se to'e curmi kei .a lo nu lo javni pe le nu tcidu ro pagbu cu
  ##       spofu kei le jalge cu kunti
  ##   .i ba bo le mulselci'a cu se tcidu pa roi
  ##   .i le nu tcidu cu cusku ro nu to'e curmi
  var
    trees: seq[Node]
    at = 0
  if not terminals.readParts(first, last, trees): return none(Node)
  terminals.assemble(first, last, trees, at)


func assembleText*(terminals: openArray[Terminal], parts: openArray[Node]): Option[Node] =
  ## zbasu le tricu pe le selci'a fi le tricu pe ro pagbu be le selci'a be'o poi se tcidu ta'i lo nu
  ##     sepli
  ##   .i le pagbu cu selpoi ja'i le nu tcidu ro pagbu to `readGrammarParts` toi
  ##   .i se ki'u bo le pagbu cu cirko no pagbu be le tricu poi `readGrammar` dunda ke'a le selci'a
  ##       poi le pagbu cu pagbu ke'a
  ##
  ## ni'o le tricu pe pa selci'a poi vasru pa pagbu po'o cu du le tricu pe le pagbu
  ##   .i va'o lo nu lo javni pe le nu tcidu ro pagbu cu spofu kei le jalge cu kunti
  ##   .i ba bo lo nu tcidu le mulno se ciska po'o cu tcidu le selci'a
  let
    split = terminals.toParts(0, terminals.len)
    is_one = split.parts.len == 1 and split.inner == terminals.len
  if is_one: return (if parts.len == 1: some(parts[0]) else: none(Node))
  var
    trees = @parts
    at = 0
  result = terminals.assemble(0, terminals.len, trees, at)
  if at != trees.len: return none(Node)


func readGrammar*(terminals: openArray[Terminal]): ReadingGrammar =
  ## tcidu lo genvla pe le selci'a ja'i le gerna pe `CLL 21.1` gi'e zbasu lo tricu pe lo javni poi
  ##     selcme
  ##   .i to'e curmi bu'u le stuzi poi ro cumtricu cu sisti bu'u ke'a
  ##   .i tcidu ro pagbu be le selci'a
  ##   .i se ki'u bo lo temci cu zensmi lo ni le selci'a cu clani to `#849` toi
  ##
  ## ni'o lo nu tcidu le mulselci'a pa roi cu tcidu le selci'a va'o lo nu le nu tcidu ro pagbu cu na
  ##     ka'e tcidu kei gi'e cusku ro nu to'e curmi
  ##   .i lo selci'a poi vasru pa pagbu po'o cu se tcidu pa roi ca
  ##   .i ki'u bo lo nu tcidu ro pagbu cu tcidu le selci'a ta'i le mitytadji gi'e rapyzba le tricu
  ##   .i va'o lo nu le selci'a cu se to'e curmi kei lo nu tcidu ro pagbu cu tcidu le selci'a re roi
  let split = terminals.toParts(0, terminals.len)
  if split.parts.len > 1 or split.inner < terminals.len:
    let built = terminals.buildText(0, terminals.len)
    if built.isSome: return ReadingGrammar(is_read: true, tree: built.get)
  terminals.readWhole



#[ ni'o ni'o ni'o lo nu sinxa lo srera ]#

func toError(reading: ReadingGrammar, children: sink seq[Node]): Node =
  ## zbasu lo srejge poi vasru `children` zi'e pe le nu to'e curmi
  ##   .i le srejge cu ponse le javni poi sisti gi'e traji lo ka ce'u selvau ku'o .e le stistu pe le
  ##       gerna ge'u .e lo genvla poi su'o cumtricu cu tcidu ke'a vi
  let rule = reading.head.toRule
  Node(
    is_terminal: false, rule: rule.name, number: rule.number, children: children,
    stop: some(Stop(at: reading.at, expected: reading.expected)),
  )


func islands(chart: var Chart, terminals: openArray[Terminal], first, last: int): seq[Node] =
  ## gacri le genvla pe `first ..< last` sepi'o lo ricpau poi mapti `CLL 21.1` ku'o .e lo genvla poi
  ##     zvati lo jbini be le ricpau
  ##   .i le gacri cu vasru lo mecraigenvla poi zvati lo jbini
  ##   .i ba bo le gacri cu vasru lo mecraipau
  ##   .i va'o lo nu dunli kei le gacri poi le pamoi pagbu pe ke'a traji lo ka ce'u clani cu jinga
  ##
  ## ni'o ro ricpau cu du lo javni poi selcme gi'e kuspe le selku'e pe le ricpau gi'e ponse lo
  ##     mecraina'u
  ##   .i va'o lo nu le valsi pe le selku'e cu se tcidu ta'i lo nu sepli kei le javni cu du le javni
  ##       pe li no zi'e po'u `text`
  ##   .i se ki'u bo le ricpau cu du le tricu poi le valsi cu dunda ke'a ta'i lo nu sepli
  ##
  ## ni'o se to'e cuxna fa lo javni poi ponse lo zmaraina'u
  ##   .i ki'u bo lo datcumtricu pe le selku'e cu ka'e vasru le javni
  ##   .i mupli fa lo nu lu mi klama li'u se tcidu ta'i `sumti-tail` noi ckini li papapa ku'o .enai
  ##       `sentence` noi ckini li vono
  ##   .i ne'i `sumti-tail` zo mi sinxa lo ponse be le klama
  ##
  ## ni'o `chart` cu ralte ro selcmi poi stali to `fillSets` toi
  let count = last - first
  if count == 0: return
  chart.fillSets(terminals.toOpenArray(first, last - 1), is_everywhere = true)
  chart.fillCompletions

  # le stedu be lo ricpau poi kuspe ro selku'e ku'o ja'i le krasi .e le fanmo
  #   .i le stedu cu du lo javni poi selcme gi'e ponse lo mecraina'u vi
  var heads = newSeq[Table[int, int]](count)
  for finish in 1 .. count:
    for key in chart.completions[finish].keys:
      let (head, start) = (key div WIDTH_KEY, key mod WIDTH_KEY)
      if start >= finish or GRAMMAR_EBNF.numbers[head].isNone: continue
      let is_outer = finish notin heads[start] or
        GRAMMAR_EBNF.numbers[head].get < GRAMMAR_EBNF.numbers[heads[start][finish]].get
      if is_outer: heads[start][finish] = head

  # le gacri be le genvla poi zvati ro stuzi bi'o le fanmo
  #   .i le nu facki cu krasi le romoi stuzi
  #   .i le gacri cu vasru lo te kancu be lo gerna valsi poi zvati lo jbini be'o .e lo te kancu be
  #       lo pagbu be'o .e le fanmo be le pamoi pagbu be'o .e le stedu be le ricpau pe le pamoi
  #       pagbu
  #   .i va'o lo nu le pamoi pagbu cu gerna valsi po'o kei le stedu cu kunti
  var covers = newSeq[tuple[between, pieces, finish: int, head: Option[int]]](count + 1)
  for start in countdown(count - 1, 0):
    covers[start] = (
      covers[start + 1].between + 1, covers[start + 1].pieces + 1, start + 1, none(int)
    )
    for finish, head in heads[start]:
      let
        cost = (covers[finish].between, covers[finish].pieces + 1)
        kept = (covers[start].between, covers[start].pieces)
      if cost < kept or (cost == kept and finish > covers[start].finish):
        covers[start] = (cost[0], cost[1], finish, some(head))

  # zbasu ro pagbu ja'i le porsi
  #   .i ro ricpau cu ponse le tricu poi lo pagbu poi se tcidu ta'i lo nu sepli cu dunda ke'a
  var start = 0
  while start < count:
    let cover = covers[start]
    if cover.head.isNone:
      result.add Node(is_terminal: true, at: first + start)
    else:
      doAssert chart.choose(cover.head.get, start, cover.finish),
          "Span completions hold should derive tree."
      # le javni cu selcme
      #   .i se ki'u bo lo jgena cu pa mei
      chart.addNodes(cover.head.get, start, cover.finish, result)
      result[^1].shift(first)
    start = cover.finish


func islands(terminals: openArray[Terminal], first, last: int): seq[Node] =
  ## gacri le genvla pe `first ..< last` sepi'o lo mulcmi poi cnino
  var chart: Chart
  chart.islands(terminals, first, last)


func markPart(charts: var ChartsKept, terminals: openArray[Terminal], part: Slice[int]): Node =
  ## tcidu le pagbu ta'i lo selci'a poi sepli gi'e zbasu lo tricu
  ##   .i ne'i le tricu le stuna'u pe le krasi be le mulselci'a cu du li no
  ##   .i va'o lo nu le gerna cu to'e curmi le pagbu kei zbasu lo srejge pe le pagbu zi'e poi vasru
  ##       lo ricpau poi mapti `CLL 21.1` to `islands` toi
  ##   .i `charts` cu ralte le mulcmi pe le pagbu
  var reading = charts.whole.readWhole(terminals.toOpenArray(part.a, part.b))
  if reading.is_read:
    result = move(reading.tree)
    result.shift(part.a)
    return
  result = reading.toError(charts.everywhere.islands(terminals, part.a, part.b + 1))
  result.stop.get.at += part.a


func markText(
    charts: var ChartsKept, terminals: openArray[Terminal], first, last: int,
    ignored: openArray[int] = [],
): seq[Node] =
  ## dunda lo pagbu be le selci'a pe le genvla pe `first ..< last` ta'i lo nu le nu tcidu ro pagbu
  ##     cu katna to `toParts` toi
  ##   .i le pagbu cu du lo tricu pe ro pagbu poi se tcidu ta'i lo nu sepli ge'u .e lo srejge pe ro
  ##       pagbu poi na se tcidu
  ##   .i ba bo dunda lo pagbu be le selci'a pe zo tu'e poi ca'o kalri
  ##   .i va'o lo nu zo lu .a zo to cu ca'o kalri kei le pagbu poi vasru le kravla cu selfa'o `last`
  ##   .i lo kravla poi `ignored` vasru ke'a se tcidu ta'i lo sapygenvla
  let split = terminals.toParts(first, last, ignored)
  for part in split.parts: result.add charts.markPart(terminals, part)
  if split.inner < last: result.add charts.markText(terminals, split.inner, last, ignored)


func readGrammarParts*(
    charts: var ChartsKept, terminals: openArray[Terminal], is_live = false
): tuple[parts: seq[Node], open: seq[int]] =
  ## tcidu lo genvla ja'i le gerna pe `CLL 21.1` gi'e zbasu lo jgena pe ro pagbu ta'i lo nu le nu
  ##     tcidu ro pagbu cu katna
  ##   .i le jgena cu du lo tricu pe ro pagbu poi se tcidu ta'i lo nu sepli ge'u .e lo srejge pe ro
  ##       pagbu poi na se tcidu
  ##   .i ba bo le jgena cu du lo pagbu be le selci'a pe zo tu'e poi ca'o kalri
  ##   .i `assembleText` zbasu le tricu pe le selci'a fi le jgena
  ##   .i se ki'u bo le jgena cu cirko no pagbu be le tricu
  ##
  ## ni'o lo mivyselci'a cu selka'a ba ro kravla poi denpa lo famvla pe vo'a
  ##   .i se ki'u bo ro jufra poi se lidne le kravla cu se tcidu ta'i lo nu sepli to `is_live` toi
  ##   .i `open` dunda lo stuna'u pe ro le kravla
  ##   .i le famvla cu raptcidu le kravla
  ##
  ## ni'o `charts` cu ralte le mulcmi pe le romoi pagbu poi se tcidu
  ##   .i se ki'u bo lo nu tcidu le pagbu poi zenba cu tisna lo selcmi po'o pe lo valsi poi cnino
  let open = (if is_live: terminals.unclosed(0, terminals.len) else: @[])
  (charts.markText(terminals, 0, terminals.len, open), open)


func readGrammarParts*(
    terminals: openArray[Terminal], is_live = false
): tuple[parts: seq[Node], open: seq[int]] =
  ## tcidu lo genvla ta'i lo nu `readGrammarParts` tcidu kei sepi'o lo mulcmi poi cnino
  var charts: ChartsKept
  charts.readGrammarParts(terminals, is_live)


func readGrammarMarked*(terminals: openArray[Terminal]): Node =
  ## tcidu lo genvla ja'i le gerna pe `CLL 21.1` gi'e zbasu lo tricu pe lo javni poi selcme ta'i lo
  ##     nu `readGrammar` zbasu
  ##   .i va'o lo nu le gerna cu to'e curmi le genvla cu zbasu lo srejge pe le mulno selci'a
  ##   .i se ki'u bo le tricu cu sinxa ro srera to `#859` toi
  ##
  ## ni'o va'o lo nu le selci'a cu selka'a fi lo pagbu kei le srejge pe le selci'a cu vasru lo tricu
  ##     pe ro pagbu poi se tcidu ta'i lo nu sepli ge'u .e lo srejge pe ro pagbu poi na se tcidu
  ##   .i se ki'u bo lo nu tcidu cu rapcfa bu'u ro pagbu
  ##   .i le srejge pe lo selci'a poi vasru pa pagbu po'o cu vasru lo ricpau poi mapti `CLL 21.1`
  ##       ku'o .e lo genvla poi zvati lo jbini be le tricu pagbu to `islands` toi
  var reading = terminals.readGrammar
  if reading.is_read: return move(reading.tree)
  let
    split = terminals.toParts(0, terminals.len)
    is_parted = split.parts.len > 1 or split.inner < terminals.len
  var charts: ChartsKept
  reading.toError(
    if is_parted: charts.markText(terminals, 0, terminals.len)
    else: terminals.islands(0, terminals.len)
  )
