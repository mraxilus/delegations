## tcidu lo gerna valsi pe lo lojbo se ciska ja'i le ciste gerna pe `CLL 21.1` gi'e zbasu lo tricu
##   pe lo javni poi se cmene
##
##   |----------------------|---------------------------------------------------------------------|
##   | lo cmene             | lo smuni                                                            |
##   |----------------------|---------------------------------------------------------------------|
##   | `EBNF`               | le bibi ciste javni pe `CLL 21.1` ta'i le se ciska pe le cukta      |
##   | `Terminal`           | lo selma'o .a `BRIVLA` .a `CMENE` vu'o noi gerna klesi lo valsi     |
##   | `Node`               | lo javni poi se cmene gi'e vasru lo panzi ku'o .a pa gerna valsi    |
##   | `Stop`               | lo sisti stuzi .e lo gerna valsi poi le gerna ka'e tcidu ke'a vi    |
##   | `ReadingGrammar`     | lo tricu pe le se ciska .a lo sisti stuzi .ebo lo sisti javni       |
##   | `readGrammar`        | tcidu lo gerna valsi ja'i le gerna pe `CLL 21.1`                    |
##   | `readGrammarMarked`  | tcidu lo gerna valsi gi'e zbasu lo tricu poi sinxa lo sisti stuzi   |
##   | `LUT_CHAIN_BY_ENDS`  | lo javni poi jbini re javni                                         |
##   |                      | .i ro jgena cu vasru le bavla'i po'o                                |
##   | `LUT_NUMBER_BY_RULE` | lo namcu pe ro javni pe `CLL 21.1` ja'i lo cmene be le javni        |
##   |----------------------|---------------------------------------------------------------------|
##
## ni'o le gerna cu datni
##   .i `EBNF` cu vasru le ciste javni pe `CLL 21.1` zi'e noi mintu le se ciska pe le cukta
##   .i la'o gy. Logical Language Group .gy. cu dunda le se ciska ro da
##   .i lo linji poi se krasi lo kunti lerfu cu pagbu le javni poi lidne le linji
##   .i ca lo nu fanva kei ro javni cu se galfi fi lo basti javni
##   .i se ki'u bo no javni cu se ciska re roi to `Article II.9` toi
##   .i lo cipra pe lo nu fanva cu cipra lo du'u le gerna cu vasru lo bibi javni kei .e lo du'u ro
##     cmene be lo javni cu se skicu kei .e lo du'u ro nu galfi .e ro nu gunma cu fasnu pa roi
##   .i le nu galfi cu se ciska ne'i `REWRITES`
##   .i le nu gunma cu se ciska ne'i `GROUPINGS`
##   .i le sinxa ciste cu mapti `CLL 21.1`
##   .i `|` cu sinxa lo nu cuxna
##   .i `[]` cu sinxa lo na'e bilga pagbu
##   .i `&` cu sinxa lo se smuni be zo ja
##   .i `...` cu sinxa lo nu rapli
##   .i `()` cu sinxa lo girzu
##   .i `#` cu sinxa `[free ...]` noi sinxa lo zifre galfi
##   .i `/X/` cu sinxa lo nu lo se ciska cu ka'e claxu lo fanmo valsi po'u la'o gy. X .gy.
##   .i `...` cu zmadu `&` lo ka jorne
##   .i `&` cu zmadu `|` lo ka jorne
##   .i lo porsi cu zmadu `&` lo ka jorne
##   .i mupli fa lo nu `ZEhA [PU [NAI]]` cu zvati lo jbini be re `&` ne'i le javni pe li panocino
##   .i `CLL 21.1` na cusku lo du'u xu kau lo porsi cu zmadu `&` lo ka jorne
##   .i `CLL 21.1` cu sitna lo namcu pe le romoi jicmu gerna pe la'o gy. YACC .gy.
##   .i le gerna pe la'o gy. YACC .gy. cu pilno lo drata nu gunma ne'i le javni pe li sozere po'o
##   .i ne'i le javni ku `&` poi jorne lo temci tcita .e lo cmavo be la'o gy. CAhA .gy. cu zvati
##     ne'i `[NAhE]` .e `[KI]`
##   .i se ki'u bo `GROUPINGS` cu ciska lo cukla grile'u pe le nu gunma
##   .i jdima fa lo nu `EBNF` cu stali lo ka mintu le se ciska pe le cukta
##   .i le nu gunma cu se ciska fi pa linji poi lamji `EBNF`
##   .i le javni pe li papanono .e li papanopa cu cusku lo du'u lo gerna stura cu galfi lo valsi pu
##     lo nu le gerna cu tcidu
##   .i ro le gerna stura cu se sinxa pa valsi
##   .i `ZO any-word` cu se sinxa `ZO`
##   .i `LOhU any-word ... LEhU` cu se sinxa `LOhU`
##   .i `ZOI any-word anything any-word` cu se sinxa `ZOI`
##   .i `any-word (ZEI any-word) ...` cu se sinxa `ZEI`
##   .i `any-word BU` cu se sinxa `BU`
##   .i `prose.nim` cu jmina le valsi pe ro gerna stura fi pa pagbu pu lo nu le gerna cu tcidu le
##     valsi to `#814` toi
##   .i le genturfa'i cu pilno le tadji pe la'o gy. Earley .gy.
##   .i ki'u bo le gerna cu vasru lo javni poi se krasi vo'a
##   .i mupli fa `rp-expression` noi se krasi vo'a sepi'o `rp-operand`
##   .i le gerna cu vasru ji'a lo se cuxna poi ka'e kunti
##   .i ji'a le gerna cu ka'e dunda re tricu pa se ciska
##   .i lo tadji po'u la'o gy. recursive descent .gy. na ka'e tcidu le gerna
##   .i le genturfa'i cu tcidu lo se ciska va'o lo nu su'o cumki tricu cu vasru le se ciska
##   .i le tricu cu du le cumki tricu poi vasru lo mleca traji javni poi mulno pu ro gerna valsi
##   .i le pamoi gerna valsi cu krasi lo nu cuxna
##   .i se ki'u bo lo gerna stura poi romoi cfari cu vasru ro valsi poi ka'e pagbu le gerna stura
##   .i va'o lo nu le se ciska cu claxu zo ke'e kei le gerna stura cu mulno bu'u lo fanmo be le
##     selbri to `CLL 5.5` toi
##   .i lo me `relative-clauses` me'u poi se lidne zo be cu ckini lo romoi sumti poi zo be .a zo bei
##     cu jorne ke'a to `CLL 5.7` toi
##   .i va'o lo nu su'o re cumki tricu cu dunli kei lo pamoi se cuxna pe lo javni cu jinga
##   .i `CLL 21.1` cu curmi lo nu lo se ciska cu claxu lo fanmo valsi va'o po'o lo nu le gerna na
##     dunda re tricu le se ciska
##   .i `CLL 21.1` na cusku lo du'u ma kau poi tricu cu se cuxna
##   .i se ki'u bo lo nu cuxna cu mapti lo mupli pe la'o gy. CLL .gy.
##   .i lo genturfa'i poi tcidu ro valsi pu lo bavla'i valsi gi'e zmanei lo nu tcidu lo gerna valsi
##     kei lo nu lo javni cu mulno ku'o cu cuxna le tricu poi le vi genturfa'i cu cuxna ke'a
##   .i mupli fa la'o gy. YACC .gy.
##   .i jdima fa lo nu lo temci pe lo nu tcidu ta'i la'o gy. Earley .gy. cu ka'e zenba simsa lo
##     tenfa be lo te kancu be lo gerna valsi be'o bei li ci
##   .i lo nu cuxna lo tricu cu karbi lo te kancu be lo javni sinxa poi mulno ne'i ro se kuspe poi
##     le tricu cu vasru ke'a
##   .i se ki'u bo `readGrammar` cu tcidu ro pagbu be le se ciska
##   .i le se ciska cu se katna bu'u zo ni'o .e zo .i
##   .i lo temci cu zenba simsa lo ni le se ciska cu clani to `#849` toi
##   .i ku'i va'o lo nu zo lu .a zo to cu ca'o kalri kei le pagbu poi vasru le krasi valsi cu se
##     fanmo le fanmo be le se ciska gi'e se tcidu pa roi
##   .i lo ni lo se ciska cu clani cu se jimte no da
##   .i se ki'u bo le genturfa'i cu pilno `seq` .e `Table` ca lo nu le samtci cu gunka to
##     `STYLE.md §4` toi
##   .i `stream` cu pilno ji'a `seq` .e `Table`
##   .i lo nu to'e curmi cu cusku lo stuzi poi ro cumki tricu cu sisti bu'u ke'a ku'o .e lo javni
##     poi se cmene gi'e sisti bu'u le stuzi gi'e traji lo ka ce'u se vasru
##   .i lo porsi be lo javni cu porsi lo javni poi se cmene ne'i lo tricu
##   .i ro le javni cu vasru le bavla'i javni po'o
##   .i mupli fa lo nu `sumti` cu vasru `sumti-1` po'o va'o lo nu lo se ciska cu na vasru
##     `relative-clauses`
##   .i ki'u lo nu so'i javni pe `CLL 21.1` cu jorne ta'i lo porsi kei so'a jgena pe ro tricu cu
##     pagbu lo porsi be lo javni
##   .i ca lo nu fanva kei le genturfa'i cu facki ro porsi be lo javni be'o poi `CLL 21.1` cu curmi
##     ke'a
##   .i lo cipra cu cipra lo du'u ro re fanmo cu dunda pa porsi po'o
##   .i se ki'u bo `nif.nim` cu ciska ro porsi sepi'o le re fanmo be le porsi po'o
##   .i lo nu rapli tcidu cu dunda le mulno tricu
##   .i va'o lo nu le gerna cu to'e curmi lo se ciska kei `readGrammarMarked` cu dunda lo tricu poi
##     sinxa ro srera
##   .i se ki'u bo lo drata samtci cu ka'e cikre le se ciska ja'i le tricu
##   .i le vi genturfa'i cu jdice no nu cikre to lo se jdice po'u `D1 a` bu'u `#859` toi
##   .i lo srera jgena cu ponse lo cmene .e lo namcu vu'o pe le javni poi sisti gi'e traji lo ka
##     ce'u se vasru
##   .i lo srera jgena cu ponse ji'a pa `Stop`
##   .i `Stop` cu vasru lo stuzi poi ro cumki tricu cu sisti bu'u ke'a ku'o .e lo gerna valsi poi
##     su'o cumki tricu cu tcidu ke'a bu'u le stuzi
##   .i va'o lo nu le nu tcidu ro pagbu cu katna lo se ciska fi lo pagbu kei ro pagbu cu se tcidu
##     ta'i lo nu sepli
##   .i le srera jgena pe le se ciska cu vasru lo tricu pe ro pagbu poi se tcidu ku'o ge'u .e lo
##     srera jgena pe ro pagbu poi na se tcidu
##   .i se ki'u bo lo nu tcidu cu rapli cfari bu'u ro valsi po'u zo ni'o ge'u .e ro valsi po'u zo .i
##     zi'e poi jorne no da
##   .i la'o gy. Architect .gy. cu jdice di'u bu'u `#859`
##   .i lo srera jgena pe pa pagbu cu vasru lo traji barda tricu pagbu poi mapti `CLL 21.1` ku'o .e
##     lo gerna valsi poi zvati lo jbini be le tricu pagbu
##   .i le gacri cu vasru lo mleca traji gerna valsi poi na pagbu su'o tricu pagbu
##   .i ba bo le gacri cu vasru lo mleca traji pagbu to `islands` toi
##   .i va'o lo nu ro se cmima cu kanpe ro javni poi se cmene kei le se cmima cu facki ro tricu
##     pagbu
##   .i lo du'u le se ciska pu na'e mapti lo javni bu'u ma kau cu na vajni
##   .i jdima fa lo nu le nu zbasu lo srera jgena pe pa mulno se ciska cu tcidu le mulno se ciska pa
##     roi
##   .i ca lo nu `readGrammar` cu to'e curmi kei `readGrammar` cu tcidu ji'a le mulno se ciska pa
##     roi
##   .i jdima fa ji'a lo nu ro se cmima pe lo pagbu poi se to'e curmi cu vasru ro javni poi se cmene

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
  ## le ciste javni pe `CLL 21.1`
  ##   .i le javni cu pagbu le romoi jicmu gerna pe la'o gy. EBNF .gy. gi'e mintu le se ciska pe
  ##     `CLL 1.1`


type
  Terminal* = distinct int  ## lo selma'o .a `BRIVLA` .a `CMENE` vu'o noi gerna klesi lo valsi

  Symbol = object
    ## lo sinxa pe lo basti javni
    ##   .i le sinxa cu du lo gerna valsi .a lo javni sinxa pe le gerna
    is_terminal: bool
    code: int  ## lo namcu pe lo gerna valsi .a lo stuzi namcu pe lo javni sinxa

  Production = object  ## pa tadji be lo nu pa javni sinxa cu binxo lo porsi be lo sinxa
    head: int  ## lo stuzi namcu pe le javni sinxa poi binxo le porsi
    body: seq[Symbol]
      ## lo porsi be lo sinxa poi se binxo
      ##   .i le porsi cu kunti va'o lo kunti se cuxna

  Grammar = object  ## lo gerna poi se zbasu fi `EBNF` gi'e vasru lo javni sinxa .e lo basti javni
    names: seq[string]
      ## lo cmene be ro javni sinxa
      ##   .i lo sidju javni cu ponse lo cmene be le javni poi vasru le sidju javni
    numbers: seq[Option[int]]
      ## lo namcu pe ro javni poi se cmene ne'i `CLL 21.1`
      ##   .i lo sidju javni cu ponse no namcu
    productions: seq[Production]
    heads: seq[seq[int]]  ## lo basti javni pe ro javni sinxa ja'i le porsi pe le se cuxna
    nullable: seq[bool]  ## le javni sinxa cu ka'e binxo lo kunti porsi
    lengths: seq[int]  ## lo mleca traji te kancu be lo gerna valsi poi ro javni sinxa cu binxo ke'a
    start: int  ## lo stuzi namcu pe `text` noi du le javni pe li no

  Builder = object  ## lo gerna poi ca'o se zbasu fi lo pagbu be pa javni pe `EBNF`
    grammar: Grammar
    lut_index_by_name: Table[string, int]
    tokens: seq[string]
    at: int  ## lo stuzi namcu pe le bavla'i pagbu poi se tcidu
    rule: int
      ## lo stuzi namcu pe le javni poi ca'o se tcidu
      ##   .i lo sidju javni cu cpacu lo cmene le javni
    frees: Option[int]
      ## le sidju javni poi `#` cu sinxa ke'a zi'e po'u `[free ...]`
      ##   .i le sidju javni cu se zbasu pa roi

  Stop* = object
    ## lo sisti stuzi pe le se ciska ge'u .e lo gerna valsi poi le gerna ka'e tcidu ke'a vi
    at*: int
      ## lo stuzi namcu pe le gerna valsi poi ro cumki tricu cu sisti bu'u ke'a
      ##   .i va'o lo nu ro cumki tricu cu sisti bu'u lo fanmo be le se ciska kei le stuzi namcu cu
      ##     du lo te kancu be le gerna valsi
    expected*: seq[Terminal]
      ## lo gerna valsi poi su'o cumki tricu cu tcidu ke'a bu'u `at` ku'o ja'i le porsi pe le namcu

  Node* = object
    ## lo jgena pe lo tricu
    ##   .i le jgena cu du lo javni poi se cmene ne'i `CLL 21.1` gi'e vasru lo jgena ku'o .a lo
    ##     gerna valsi
    case is_terminal*: bool
    of true:
      at*: int  ## lo stuzi namcu pe le gerna valsi ne'i lo gerna valsi poi se tcidu
    of false:
      rule*: string  ## lo cmene be le javni mu'u `sumti-6`
      number*: int  ## lo namcu pe le javni ne'i `CLL 21.1` mu'u li soze
      children*: seq[Node]
      stop*: Option[Stop] = none(Stop)
        ## lo sisti stuzi pe le gerna va'o lo nu le jgena cu sinxa lo srera
        ##   .i le javni pe le jgena cu du le javni poi sisti vi gi'e traji lo ka ce'u se vasru
        ##   .i lo panzi be le jgena cu du lo tricu pagbu poi mapti `CLL 21.1` ku'o .e lo gerna
        ##     valsi poi zvati lo jbini be le tricu pagbu to `readGrammarMarked` toi
        ##   .i va'o lo nu le jgena cu mapti `CLL 21.1` kei le datni pagbu cu kunti

  ReadingGrammar* = object  ## lo jalge be lo nu tcidu lo gerna valsi ja'i le gerna pe `CLL 21.1`
    case is_read*: bool
    of true:
      tree*: Node  ## le javni po'u `text` ge'u .e ro da poi le javni cu vasru ke'a
    of false:
      at*: int
        ## lo stuzi namcu pe le gerna valsi poi ro cumki tricu cu sisti bu'u ke'a
        ##   .i va'o lo nu ro cumki tricu cu sisti bu'u lo fanmo be le se ciska kei le stuzi namcu
        ##     cu du lo te kancu be le gerna valsi
      rule*: string
        ## le cmene .e le namcu vu'o pe le javni poi se cmene gi'e sisti vi gi'e traji lo ka ce'u se
        ##   vasru
        ##   .i mupli fa `sumti-6 97`
      head: int
        ## le javni sinxa pe le javni
        ##   .i le srera jgena poi `readGrammarMarked` cu dunda ke'a cu cpacu le javni sinxa
      expected: seq[Terminal]
        ## lo gerna valsi poi su'o cumki tricu cu tcidu ke'a bu'u `at` ku'o ja'i le porsi pe le
        ##   namcu

  Item = tuple[production, dot, origin: int]
    ## lo cmima pe la'o gy. Earley .gy. zi'e noi vasru lo basti javni .e lo stuzi be lo nu tcidu
    ##   ne'i le basti javni be'o .e le se cmima poi le cmima cu cfari ne'i ke'a


const
  TERMINAL_BRIVLA* = Terminal(ord(Selmaho.high) + 1)  ## lo brivla noi gismu ja lujvo ja fu'ivla
  TERMINAL_CMENE* = Terminal(ord(Selmaho.high) + 2)  ## lo cmene
  REWRITES = [
    ("ZO any-word #", "ZO #"), ("LOhU any-word ... LEhU #", "LOhU #"),
    ("ZOI any-word anything any-word #", "ZOI #"), ("any-word (ZEI any-word) ...", "ZEI"),
    ("any-word BU", "BU"),
  ]
    ## lo gerna stura poi le gerna cu tcidu ke'a ta'i pa valsi
    ##   .i `prose.nim` cu jmina le valsi pe ro gerna stura pu lo nu le gerna cu tcidu to le javni
    ##     pe li papanono .e li papanopa toi
  GROUPINGS = [
    (
      "[NAhE] (time [space] | space [time]) & CAhA [KI]",
      "[NAhE] ((time [space] | space [time]) & CAhA) [KI]",
    ),
  ]
    ## lo nu gunma poi `CLL 21.1` na jdice fi ke'a
    ##   .i le romoi jicmu gerna pe la'o gy. YACC .gy. zi'e po'u `grammar.300` cu dunda le nu gunma
    ##   .i ne'i `grammar.300` le javni pe li sozere cu curmi lo nu lo cmavo be la'o gy. NAhE .gy.
    ##     cu lidne lo temci tcita po'o .a lo cmavo be la'o gy. CAhA .gy. po'o to le javni pe li
    ##     sozeci .e li sozebi toi
    ##   .i lo cmavo be la'o gy. KI .gy. cu ka'e se lidne lo temci tcita .a lo cmavo be la'o gy.
    ##     CAhA .gy. to le javni pe li sozeze toi
  COUNT_RULES = 88
    ## lo te kancu be le ciste javni pe `CLL 21.1`
    ##   .i le javni pe li papanono .e li papanopa cu na se kancu
  BOUND_LENGTH = 1 shl 20
    ## lo jimte be lo mleca traji te kancu be lo gerna valsi pe ro javni sinxa
    ##   .i le jimte cu zmadu ro te kancu poi se facki
  DELIMITERS = {'[', ']', '(', ')', '|', '&', '#', '/'}
    ## lo sinxa pe le sinxa ciste
    ##   .i le stodi na vasru `...`


func `==`*(a, b: Terminal): bool {.borrow.}
  ## karbi lo re gerna valsi sepi'o lo namcu pe le gerna valsi

func toTerminal*(selmaho: Selmaho): Terminal = Terminal(ord(selmaho))
  ## ralte lo selma'o ta'i lo gerna valsi


func toTerminal*(reading: Reading): Option[Terminal] =
  ## ralte lo valsi ta'i lo gerna valsi
  ##   .i lo cmavo cu se sinxa lo selma'o be vo'a
  ##   .i lo cmene cu se sinxa `CMENE`
  ##   .i lo gismu .e lo lujvo .e lo fu'ivla cu se sinxa `BRIVLA` to `CLL 21.1` toi
  ##   .i lo se tcidu poi se to'e curmi ku'o .e lo cmavo poi no liste cu dunda lo selma'o ke'a ku'o
  ##     cu se sinxa no gerna valsi
  if not reading.is_word: return none(Terminal)
  case reading.kind
  of Kind.Cmavo:
    if reading.selmaho.isSome: some(reading.selmaho.get.toTerminal) else: none(Terminal)
  of Kind.Cmene: some(TERMINAL_CMENE)
  of Kind.Gismu, Kind.Lujvo, Kind.Fuhivla: some(TERMINAL_BRIVLA)


func `$`*(terminal: Terminal): string =
  ## ciska lo gerna valsi ja'i `CLL 21.1`
  ##   .i lo selma'o cu se ciska sepi'o lo cmene be le selma'o
  ##   .i va'o lo drata `BRIVLA` .a `CMENE` cu se ciska
  if terminal == TERMINAL_BRIVLA: "BRIVLA"
  elif terminal == TERMINAL_CMENE: "CMENE"
  else: $Selmaho(int(terminal))



#[ ni'o ni'o ni'o lo nu fanva ]#

func toRules(text: string): seq[string] =
  ## jmina ro linji poi pagbu pa javni pe le se ciska ku'o le javni
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
  ## fendi le se cusku pe pa javni fi lo cmene .e `...` .e lo sinxa pe le sinxa ciste
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
  ## facki lo javni sinxa poi se cmene `name`
  ##   .i jmina le javni sinxa ca lo pamoi nu pilno
  if name notin builder.lut_index_by_name:
    builder.lut_index_by_name[name] = builder.grammar.names.len
    builder.grammar.names.add name
    builder.grammar.numbers.add none(int)
    builder.grammar.heads.add newSeq[int]()
  builder.lut_index_by_name[name]


func addHelper(builder: var Builder): int =
  ## jmina pa javni sinxa poi sinxa pa pagbu be le javni poi ca'o se tcidu
  ##   .i le javni sinxa cu se cmene le cmene be le javni
  let index = builder.grammar.names.len
  builder.grammar.names.add builder.grammar.names[builder.rule]
  builder.grammar.numbers.add none(int)
  builder.grammar.heads.add newSeq[int]()
  index


func addProduction(builder: var Builder, head: int, body: seq[Symbol]) =
  ## jmina pa basti javni poi `head` cu binxo `body` sepi'o ke'a
  builder.grammar.heads[head].add builder.grammar.productions.len
  builder.grammar.productions.add Production(head: head, body: body)


func toSymbol(builder: var Builder, name: string): Symbol =
  ## tcidu lo cmene be lo javni ta'i lo javni sinxa
  ##   .i tcidu lo cmene poi se ciska ta'i lo barda lerfu ku'o ta'i lo gerna valsi to `CLL 21.1` toi
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
  ## jmina pa sidju javni poi ka'e binxo ro cmima be `bodies`
  ##   .i dunda lo sinxa be le sidju javni
  let helper = builder.addHelper
  for body in bodies: builder.addProduction(helper, body)
  Symbol(is_terminal: false, code: helper)


func parseItem(builder: var Builder): Symbol =
  ## tcidu pa pagbu po'u lo cmene .a lo na'e bilga pagbu po'u `[]` ge'u .a lo girzu po'u `()` ge'u
  ##   .a lo fanmo valsi poi ka'e se claxu zi'e po'u `/X/` ge'u .a `#`
  ##   .i va'o lo nu `...` cu se lidne le pagbu kei le pagbu cu se rapli
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
    result = builder.toHelper(@[body, newSeq[Symbol]()])  # lo fanmo valsi cu se claxu gi'a se ciska
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
  ## tcidu lo porsi poi se jorne `&`
  ##   .i `A & B` cu du `A | B | A B` to `CLL 21.1` toi
  ##   .i `A & B & C` cu du `(A & B) & C`
  result = builder.parseSequence
  while builder.peek == "&":
    inc builder.at
    let right = builder.parseSequence
    result = @[builder.toHelper(@[result, right, result & right])]


func parseAlternation(builder: var Builder): seq[seq[Symbol]] =
  ## tcidu lo se cuxna poi se jorne `|`
  result.add builder.parseAndOr
  while builder.peek == "|":
    inc builder.at
    result.add builder.parseAndOr


func constructGrammar(text: string): Grammar {.compileTime.} =
  ## galfi ro javni pe `EBNF` fi lo basti javni gi'e facki lo javni sinxa poi ka'e binxo lo kunti
  ##   porsi
  var builder: Builder
  let rules = text.toRules
  doAssert rules.len == COUNT_RULES, "21.1 should give " & $COUNT_RULES & " formal rules."

  # tcidu ro javni
  #   .i le javni cu vasru lo cmene ce'o lo namcu ce'o lo se cusku
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

  # sinxa lo javni sinxa poi ka'e binxo lo kunti porsi
  #   .i le nu sinxa cu fanmo ca lo nu no cnino cu se facki
  result.nullable = newSeq[bool](result.names.len)
  var is_changed = true
  while is_changed:
    is_changed = false
    for production in result.productions:
      if result.nullable[production.head]: continue
      if production.body.allIt(not it.is_terminal and result.nullable[it.code]):
        result.nullable[production.head] = true
        is_changed = true

  # facki lo mleca traji te kancu be lo gerna valsi poi ro javni sinxa cu ka'e binxo ke'a
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

  # cipra lo du'u ro javni sinxa poi xruti vo'a sepi'o lo basti javni poi vasru pa sinxa po'o cu
  #   xruti vo'a sepi'o pa basti javni po'o
  #   .i `choose` cu nitcu di'u
  #   .i lo sinxa cu binxo pa javni sinxa po'o va'o lo nu ro drata sinxa pe le basti javni cu ka'e
  #     binxo lo kunti porsi
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
  ## zbasu ro porsi be lo javni poi se cmene
  ##   .i ro jgena pe le porsi cu vasru le bavla'i po'o
  ##   .i lo namcu pe le javni poi krasi le porsi ku'o .e lo namcu pe le javni poi fanmo le porsi cu
  ##     ckiku le porsi
  ##   .i cipra lo du'u ro re fanmo cu dunda pa porsi po'o kei .e lo du'u no porsi cu xruti
  ##   .i va'o lo nu lo basti javni pe lo javni poi se cmene cu binxo pa javni po'o kei le javni poi
  ##     se cmene cu vasru le pa javni po'o
  ##   .i ro drata sinxa pe le basti javni cu du lo sidju javni poi binxo no jgena
  ##   .i ki'u bo ro javni poi se cmene cu jgena
  ##   .i le javni cu jgena ji'a va'o lo nu kunti
  let count = grammar.names.len
  func isHelper(grammar: Grammar, code: int): bool = grammar.numbers[code].isNone

  # sinxa lo sidju javni poi binxo no jgena
  #   .i le sidju javni cu binxo lo kunti porsi sepi'o lo sidju javni po'o
  var nodeless = newSeq[bool](count)
  template isNodeless(symbol: Symbol): bool =
    ## jdice lo du'u xu kau le sinxa cu sidju javni poi pu se sinxa ta'i lo nu binxo no jgena
    not symbol.is_terminal and grammar.isHelper(symbol.code) and nodeless[symbol.code]
  var is_changed = true
  while is_changed:
    is_changed = false
    for production in grammar.productions:
      if not grammar.isHelper(production.head) or nodeless[production.head]: continue
      if production.body.allIt(it.isNodeless):
        nodeless[production.head] = true
        is_changed = true

  # facki lo javni poi se cmene zi'e poi ro javni sinxa cu binxo ke'a po'o
  #   .i le nu facki cu fanmo ca lo nu no cnino cu se facki
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

  # litru ro porsi be lo javni be'o poi se krasi lo javni poi se cmene
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
  ## lo javni pe ro porsi noi ro jgena pe ke'a cu vasru le bavla'i po'o
  ##   .i lo namcu pe le javni poi krasi le porsi ku'o .e lo namcu pe le javni poi fanmo le porsi cu
  ##     ckiku le porsi
  ##   .i mupli fa lo porsi poi se krasi `terms` noi ckini li bino ku'o gi'e se fanmo `sumti-6` noi
  ##     ckini li soze
  ##   .i le porsi cu porsi ro javni poi jbini le re javni ne'i `CLL 21.1`


func constructNumbers(grammar: Grammar): Table[string, int] {.compileTime.} =
  ## zbasu lo namcu pe ro javni poi se cmene ja'i lo cmene be le javni
  ##   .i cipra lo du'u no re javni cu ponse lo mintu cmene .a lo mintu namcu
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
  ## lo namcu pe ro javni poi se cmene ne'i `CLL 21.1` ja'i lo cmene be le javni
  ##   .i mupli fa li soze noi du le namcu pe `sumti-6`
  ##   .i la'o gy. NIF .gy. cu ciska lo cmene po'o be le javni poi fanmo ro porsi
  ##   .i lo tcidu be la'o gy. NIF .gy. cu cpacu le namcu le vi stodi
  ##   .i la'o gy. Architect .gy. cu jdice di'u bu'u `#859` to `comment 6805527878` toi



#[ ni'o ni'o ni'o lo nu tcidu ]#

func fillSets(terminals: openArray[Terminal], is_everywhere = false): seq[seq[Item]] =
  ## tisna lo se cmima pe la'o gy. Earley .gy.
  ##   .i le se cmima pe `i` cu vasru lo cmima poi su'o cumki tricu cu klama ke'a ba lo nu tcidu lo
  ##     gerna valsi noi lo te kancu be ke'a cu du `i`
  ##   .i ca lo nu kanpe pa javni sinxa poi ka'e binxo lo kunti porsi kei le cmima cu pagre le javni
  ##     sinxa
  ##   .i la'o gy. Aycock .gy. .e la'o gy. Horspool .gy. cu pilno le vi tadji
  ##   .i `is_everywhere` cu rinka lo nu ro se cmima cu kanpe ji'a ro javni poi se cmene
  ##   .i se ki'u bo le mulno cmima cu vasru ro se kuspe poi su'o javni poi se cmene cu kuspe ke'a
  ##   .i lo du'u le se ciska cu na'e mapti lo javni bu'u ma kau pu le se kuspe cu na vajni to
  ##     `islands` toi
  ##   .i so'a lo temci pe lo nu tcidu cu zvati le fancu
  ##   .i le fancu cu se pilno pa roi ro se ciska
  ##   .i ro se cmima cu fendi lo cmima be vo'a ja'i lo javni sinxa poi le cmima cu denpa ke'a
  ##   .i se ki'u bo ca lo nu pa javni sinxa cu mulno kei le fancu cu tcidu lo cmima po'o poi denpa
  ##     le javni sinxa
  ##   .i ro se cmima cu kanpe ro javni sinxa pa roi
  ##   .i ne'i ro se cmima `waiting` .e `predicted` cu vasru lo pagbu
  ##   .i ro javni sinxa cu ponse pa le pagbu
  ##   .i lo te kancu be lo cmima cu zenba simsa lo ni le se ciska cu clani
  ##   .i ro cmima cu cpacu lo cnino stuzi
  ##   .i lo porsi be lo sinxa pe lo basti javni cu se cmene pa `template`
  ##   .i `let` na se pilno ki'u lo nu `let` cu fukpi le porsi ca ro cmima
  ##   .i lo na'e zmiku cipra cu tcidu lo samtci pe la'o gy. C .gy. zi'e poi le fanva cu ciska ke'a
  ##   .i lo cmima cu vasru ci namcu gi'e se fukpi ta'i lo nu fukpi le ci namcu

  template add(i: int, item: Item) =
    ## jmina le cmima le se cmima pe `i` pa roi
    ##   .i le se cmima cu fendi le cmima ja'i le javni sinxa poi le cmima cu denpa ke'a
    let added: Item = item
    if not seen[i].containsOrIncl(added):
      template bodyAdded: untyped = GRAMMAR_EBNF.productions[added.production].body
        ## sinxa le porsi be lo sinxa pe le basti javni pe le se jmina cmima
      if added.dot < bodyAdded.len and not bodyAdded[added.dot].is_terminal:
        waiting[i][bodyAdded[added.dot].code].add result[i].len
      result[i].add added

  result = newSeq[seq[Item]](terminals.len + 1)
  let count_nonterminals = GRAMMAR_EBNF.heads.len
  var
    seen = newSeq[HashSet[Item]](terminals.len + 1)
    waiting = newSeq[seq[seq[int]]](terminals.len + 1)  # lo cmima ja'i lo javni sinxa poi se denpa
    predicted = newSeq[seq[bool]](terminals.len + 1)
  for i in 0..terminals.len:
    waiting[i] = newSeq[seq[int]](count_nonterminals)
    predicted[i] = newSeq[bool](count_nonterminals)
  for p in GRAMMAR_EBNF.heads[GRAMMAR_EBNF.start]: add(0, (p, 0, 0))
  for i in 0..terminals.len:
    if is_everywhere:
      for head in 0 ..< count_nonterminals:
        if GRAMMAR_EBNF.numbers[head].isNone or predicted[i][head]: continue
        predicted[i][head] = true
        for p in GRAMMAR_EBNF.heads[head]: add(i, (p, 0, i))
    var k = 0
    while k < result[i].len:
      let item = result[i][k]
      template body: untyped = GRAMMAR_EBNF.productions[item.production].body
        ## sinxa le porsi be lo sinxa pe le basti javni pe le cmima
      inc k

      # le cmima cu mulno
      #   .i ro cmima poi denpa le javni sinxa pe le vi cmima cu klama le bavla'i sinxa
      #   .i va'o lo nu le vi cmima cu binxo lo kunti porsi kei le liste cu ka'e zenba ca lo nu le
      #     liste cu se tcidu
      #   .i se ki'u bo le nu tcidu cu pilno lo stuzi namcu
      if item.dot == body.len:
        let head = GRAMMAR_EBNF.productions[item.production].head
        var j = 0
        while j < waiting[item.origin][head].len:
          let waiter = result[item.origin][waiting[item.origin][head][j]]
          add(i, (waiter.production, waiter.dot + 1, waiter.origin))
          inc j
        continue

      # tcidu lo gerna valsi gi'a kanpe lo javni sinxa
      let symbol = body[item.dot]
      if symbol.is_terminal:
        if i < terminals.len and int(terminals[i]) == symbol.code:
          add(i + 1, (item.production, item.dot + 1, item.origin))
        continue
      if not predicted[i][symbol.code]:
        predicted[i][symbol.code] = true
        for p in GRAMMAR_EBNF.heads[symbol.code]: add(i, (p, 0, i))
      if GRAMMAR_EBNF.nullable[symbol.code]: add(i, (item.production, item.dot + 1, item.origin))


func toRule(head: int): tuple[name: string, number: int] =
  ## dunda lo cmene .e lo namcu vu'o pe le javni pe le javni sinxa mu'u `sumti-6` .e li soze
  ##   .i lo sidju javni cu cpacu le cmene .e le namcu vu'o pe le javni poi vasru le sidju javni
  let name = GRAMMAR_EBNF.names[head]
  for i, other in GRAMMAR_EBNF.names:
    let number = GRAMMAR_EBNF.numbers[i]
    if other == name and number.isSome: return (name, number.get)
  doAssert false, "Helper should take name of rule holding it; got `" & name & "`."


func ruleNamed(head: int): string =
  ## dunda lo cmene .e lo namcu vu'o pe le javni pe le javni sinxa ta'i pa lerpoi mu'u `sumti-6 97`
  ##   .i lo sidju javni cu cpacu le cmene .e le namcu vu'o pe le javni poi vasru le sidju javni
  let rule = head.toRule
  rule.name & " " & $rule.number


func refusal(sets: openArray[seq[Item]]): ReadingGrammar =
  ## to'e curmi bu'u le romoi se cmima poi su'o cumki tricu cu klama ke'a
  ##   .i cusku le javni pe le cmima poi zvati le se cmima gi'e denpa gi'e pu tcidu pa gerna valsi
  ##     gi'e romoi cfari
  ##   .i lo cmima poi cfari ne'i le se cmima cu tcidu no gerna valsi gi'e cusku no javni
  ##   .i lo gerna valsi poi le cmima pe le se cmima cu denpa ke'a cu du lo gerna valsi poi su'o
  ##     cumki tricu cu tcidu ke'a vi
  var last = sets.high
  while sets[last].len == 0: dec last
  var
    best = none(Item)
    expected: seq[Terminal]
  for item in sets[last]:
    template body: untyped = GRAMMAR_EBNF.productions[item.production].body
      ## sinxa le porsi be lo sinxa pe le basti javni pe le cmima
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


type
  Completions = seq[Table[(int, int), seq[int]]]
    ## lo basti javni poi mulno ne'i ro se cmima ku'o ja'i lo javni sinxa .e lo krasi se cmima

  Choice = object
    ## le cumki tricu pe pa javni sinxa bu'u pa se kuspe
    ##   .i le tricu cu cuxna le cumki tricu
    closures: seq[int]
      ## lo te kancu be lo javni sinxa pe le cumki tricu zi'e poi mulno bu'u ro stuzi pe le se kuspe
      ##   .i le pamoi te kancu cu ckini le krasi be le se kuspe
      ##   .i lo genturfa'i poi tcidu ro valsi pu lo bavla'i valsi cu mulgau le javni sinxa bu'u le
      ##     stuzi pu lo nu tcidu le gerna valsi pe le stuzi
    production: int
    bounds: seq[int]  ## lo stuzi be lo fanmo be ro sinxa pe le basti javni

  Chart = object
    ## lo mulno cmima pe le se ciska ge'u .e lo se cuxna poi se facki ca lo nu cuxna le tricu
    completions: Completions
    terminals: seq[Terminal]
    choices: Table[(int, int, int), Option[Choice]]
      ## lo se cuxna ja'i lo javni sinxa .e lo krasi .e lo fanmo
    open: HashSet[(int, int, int)]
      ## lo se kuspe poi ca'o se cuxna gi'e ka'e se rapli cpacu ki'u lo nu pa javni sinxa cu xruti
      ##   vo'a


func toCompletions(sets: openArray[seq[Item]]): Completions =
  ## fendi ro mulno cmima ja'i le se cmima poi le cmima cu fanmo ne'i ke'a ku'o .e le javni sinxa .e
  ##   le se cmima poi le cmima cu cfari ne'i ke'a
  result = newSeq[Table[(int, int), seq[int]]](sets.len)
  for i, items in sets:
    for item in items:
      let production = GRAMMAR_EBNF.productions[item.production]
      if item.dot != production.body.len: continue
      result[i].mgetOrPut((production.head, item.origin), @[]).add item.production
    for key in result[i].keys.toSeq: result[i][key].sort


func isFewer(a, b: seq[int]): bool =
  ## jdice lo du'u xu kau `a` cu mleca `b` lo ka mulgau lo javni sinxa kei bu'u le pamoi stuzi poi
  ##   `a` .e `b` cu frica bu'u ke'a
  for i in 0 ..< min(a.len, b.len):
    if a[i] != b[i]: return a[i] < b[i]
  false


func offer(partials: var seq[Option[Choice]], i: int, candidate: Choice) =
  ## ralte le cumki se cuxna bu'u le stuzi pe `i` va'o lo nu le cumki se cuxna cu mleca le se ralte
  ##   lo ka mulgau lo javni sinxa
  ##   .i va'o lo nu dunli kei le pamoi cu stali
  if partials[i].isNone or candidate.closures.isFewer(partials[i].get.closures):
    partials[i] = some(candidate)


func isDerived(chart: Chart, symbol: Symbol, start, finish: int): bool =
  ## jdice lo du'u xu kau `chart` cu jarco lo nu `symbol` cu binxo le gerna valsi pe
  ##   `start ..< finish`
  ##   .i va'o lo nu `symbol` cu gerna valsi kei `symbol` cu binxo pa gerna valsi po'o poi mintu
  ##     `symbol`
  ##   .i va'o lo nu `symbol` cu javni sinxa kei `symbol` cu mulno bu'u le se kuspe gi'a binxo lo
  ##     kunti porsi va'o lo nu le se kuspe cu kunti
  if symbol.is_terminal:
    return finish == start + 1 and int(chart.terminals[start]) == symbol.code
  (start == finish and GRAMMAR_EBNF.nullable[symbol.code]) or
    (symbol.code, start) in chart.completions[finish]


func choose(chart: var Chart, head, start, finish: int): Option[Choice] =
  ## cuxna le cumki tricu poi `head` cu binxo le gerna valsi pe `start ..< finish` sepi'o ke'a zi'e
  ##   poi mleca traji lo ka mulgau lo javni sinxa bu'u ro stuzi
  ##   .i le pamoi stuzi cu krasi lo nu cuxna
  ##   .i va'o lo nu dunli kei le pamoi basti javni cu jinga
  ##   .i ba bo lo sinxa poi zmadu lo ka clani cu jinga
  ##   .i le se cuxna cu se ralte ba lo nu se facki
  ##   .i no sinxa cu troci lo nu kuspe lo gerna valsi poi le sinxa poi se lidne cu nitcu ke'a
  ##   .i se ki'u bo lo panzi cu kuspe le mulno se kuspe va'o po'o lo nu ro drata sinxa cu ka'e
  ##     binxo lo kunti porsi
  ##   .i ro javni sinxa poi xruti vo'a sepi'o lo basti javni poi vasru pa sinxa po'o cu xruti vo'a
  ##     sepi'o pa basti javni po'o to `constructGrammar` toi
  ##   .i lo cumki tricu poi xruti cu zmadu lo drata lo ka mulgau lo javni sinxa gi'e no roi se
  ##     cuxna
  ##   .i se ki'u bo no se cuxna poi se ralte cu nitcu lo se kuspe poi ca'o se cuxna
  ##   .i le romoi sinxa pe le basti javni cu pilno le fanmo be le se kuspe po'o ta'i lo korbi
  ##   .i ki'u bo no drata korbi cu rinka lo nu le basti javni cu kuspe le mulno se kuspe
  ##   .i lo temci pe ro drata korbi pu zenba simsa lo pilji be lo klani be le se kuspe be'o bei le
  ##     klani ne'i lo clani se ciska
  ##   .i le javni sinxa poi lidne le romoi sinxa cu pilno lo korbi po'o poi le romoi sinxa cu se
  ##     fanmo le fanmo be le se kuspe va'o lo nu cfari bu'u ke'a
  ##   .i lo na'e mulno poi zvati lo drata korbi cu no roi klama le fanmo
  ##   .i ro panzi poi no roi se pilno pu se cuxna gi'e pu fukpi lo te kancu be lo javni sinxa poi
  ##     mulno
  ##   .i le te kancu pu clani simsa le se kuspe be le panzi
  ##   .i va'o lo nu pa krasi valsi pu ca'o kalri kei le jdima pu zmadu le se ciska lo ka zenba to
  ##     `#849` toi
  let key = (head, start, finish)
  if key in chart.choices: return chart.choices[key]
  if chart.open.containsOrIncl(key): return none(Choice)
  defer: chart.open.excl(key)
  let span = finish - start
  var best = none(Choice)
  for p in GRAMMAR_EBNF.heads[head]:
    template body: untyped = GRAMMAR_EBNF.productions[p].body
      ## sinxa le porsi be lo sinxa pe le basti javni po'u `p`
      ##   .i lo nu pilno `let` cu rinka lo nu fukpi le porsi
    if span == 0 and body.anyIt(it.is_terminal or not GRAMMAR_EBNF.nullable[it.code]): continue
    if span > 0 and p notin chart.completions[finish].getOrDefault((head, start)): continue

    # tcidu ro sinxa pe le basti javni pu lo bavla'i sinxa
    #   .i bu'u ro stuzi le na'e mulno poi mleca traji lo ka mulgau lo javni sinxa vi cu se ralte
    #   .i ro sinxa cu curmi lo nu lo sinxa poi se lidne cu ponse lo banzu gerna valsi
    var
      # le mleca traji te kancu be lo gerna valsi poi ro rebla be le porsi cu binxo ke'a
      rests = newSeq[int](body.len + 1)
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
        # le romoi sinxa cu se fanmo le fanmo be le se kuspe
        let low = (if k == body.high: finish else: m)
        for bound in countdown(finish - rests[k + 1], low):
          if not chart.isDerived(symbol, m, bound): continue
          if k == body.high - 1 and not chart.isDerived(body[^1], bound, finish): continue  # morsi
          let child = chart.choose(symbol.code, m, bound)
          if child.isNone: continue
          var next = partial.get
          next.closures[^1] += child.get.closures[0]
          next.closures.add child.get.closures[1 .. ^1]
          next.bounds.add bound
          nexts.offer(bound - start, next)
      partials = nexts
    if partials[span].isNone: continue
    var whole = partials[span].get
    inc whole.closures[^1]  # `head` cu mulno bu'u le fanmo be le se kuspe
    if best.isNone or whole.closures.isFewer(best.get.closures): best = some(whole)
  chart.choices[key] = best
  best


func addNodes(chart: Chart, head, start, finish: int, nodes: var seq[Node]) =
  ## jmina lo jgena pe le se cuxna pe `head` bu'u le se kuspe fi `nodes`
  ##   .i ro javni poi se cmene cu jmina pa jgena poi vasru lo panzi be vo'a
  ##   .i ro sidju javni cu jmina lo jgena pe vo'a lo javni poi vasru le sidju javni
  ##   .i lo jgena pe lo javni poi se cmene cu zvati lo stuzi pe vo'a pu lo nu lo panzi be le jgena
  ##     cu tisna le jgena
  ##   .i se ki'u bo le nu zbasu cu fukpi no tricu pagbu
  ##   .i di'u jetnu ji'a ne'i la'o gy. JavaScript .gy. noi `add` pe ke'a cu fukpi ro datni
  ##   .i le nu zbasu cu fukpi ji'a no `closures` pe le se cuxna
  ##   .i lo temci pe lo nu fukpi bu'u ro jgena pu zenba simsa lo pilji be lo klani be le se ciska
  ##     be'o bei le klani
  ##   .i ki'u bo ro ju'agri cu rinka lo nu le javni pe li vo cu punji pa jgena ne'i pa jgena to
  ##     `#849` toi
  let
    key = (head, start, finish)
    production = chart.choices[key].get.production
    bounds = chart.choices[key].get.bounds
  template addChildren(into: var seq[Node]) =
    ## jmina lo jgena pe ro sinxa pe le basti javni fi `into` ja'i le porsi
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


func readWhole(terminals: openArray[Terminal]): ReadingGrammar =
  ## tcidu lo gerna valsi pe le se ciska ja'i le gerna pe `CLL 21.1` pa roi gi'e zbasu lo tricu pe
  ##   lo javni poi se cmene
  ##   .i to'e curmi bu'u le stuzi poi ro cumki tricu cu sisti bu'u ke'a
  let sets = terminals.fillSets
  var is_whole = false
  for item in sets[^1]:
    let
      production = GRAMMAR_EBNF.productions[item.production]
      is_text = production.head == GRAMMAR_EBNF.start and item.origin == 0
    if is_text and item.dot == production.body.len: is_whole = true
  if not is_whole: return sets.refusal
  var
    chart = Chart(completions: sets.toCompletions, terminals: @terminals)
    nodes: seq[Node]
  doAssert chart.choose(GRAMMAR_EBNF.start, 0, terminals.len).isSome,
      "Text grammar reads should derive tree."
  chart.addNodes(GRAMMAR_EBNF.start, 0, terminals.len, nodes)
  # le javni pe li no cu se cmene
  #   .i se ki'u bo lo jgena cu pa mei
  ReadingGrammar(is_read: true, tree: nodes.pop)



#[ ni'o ni'o ni'o lo nu tcidu ro pagbu ]#

const
  OPENERS* = [Selmaho.Tuhe, Selmaho.Lu, Selmaho.To]
    ## lo selma'o poi krasi lo se ciska ne'i lo se ciska
    ##   .i le selma'o cu pagbu `statement-3` .e `sumti-6` .e `free` to le javni pe li pavo .e li
    ##     soze .e li cire toi
  CLOSERS* = [Selmaho.Tuhu, Selmaho.Lihu, Selmaho.Toi]
    ## lo fanmo valsi pe ro krasi valsi ja'i le porsi pe `OPENERS`
  JOINS = {Selmaho.Ja, Selmaho.Joi, Selmaho.Bihi, Selmaho.Gaho, Selmaho.Bo}
    ## lo selma'o poi se lidne `I` gi'e jorne lo jufra ta'i lo me `jek` me'u .a lo me `joik` me'u .a
    ##   la'o gy. BO .gy.
    ##   .i le selma'o cu ka'e se lidne lo cmavo be la'o gy. NA .gy. be'o .e lo cmavo be la'o gy. SE
    ##     .gy. to le javni pe li pare .e li paci toi
  TAGS = {
    Selmaho.Nahe, Selmaho.Se, Selmaho.Bai, Selmaho.Nai, Selmaho.Ki, Selmaho.Cuhe, Selmaho.Zi,
    Selmaho.Pu, Selmaho.Zeha, Selmaho.Va, Selmaho.Faha, Selmaho.Mohi, Selmaho.Veha, Selmaho.Viha,
    Selmaho.Fehe, Selmaho.Tahe, Selmaho.Roi, Selmaho.Zaho, Selmaho.Caha, Selmaho.Pa, Selmaho.Na,
    Selmaho.Ja, Selmaho.Joi,
  }
    ## lo selma'o pe lo tcita poi lidne la'o gy. BO .gy. ne'i `statement-2` to le javni pe li paci
    ##   .e `stag` toi
    ##   .i lo porsi be le selma'o be'o poi se fanmo la'o gy. BO .gy. cu jorne lo jufra
  RULE_TEXT_1 = ("text-1", 2)
    ## lo cmene .e lo namcu vu'o pe le javni poi vasru lo se ciska ju'agri
  RULE_PARAGRAPHS = ("paragraphs", 4)
  RULE_PARAGRAPH = ("paragraph", 10)
  RULE_STATEMENT_3 = ("statement-3", 14)
  RULE_FREE = ("free", 32)


type Split = tuple[parts: seq[Slice[int]], inner: int]
  ## lo pagbu be lo se ciska be'o poi se tcidu ta'i lo nu sepli ku'o .e lo krasi be le se ciska pe
  ##   zo tu'e poi ca'o kalri
  ##   .i va'o lo drata le krasi cu du le fanmo


func isAmong(terminal: Terminal, selmaho: set[Selmaho]): bool =
  ## jdice lo du'u xu kau le gerna valsi cu cmavo pa cmima be `selmaho`
  int(terminal) <= ord(Selmaho.high) and Selmaho(int(terminal)) in selmaho


func isRule(node: Node, rule: (string, int)): bool =
  ## jdice lo du'u xu kau le jgena cu du le javni po'u `rule` kei sepi'o lo cmene .e lo namcu
  not node.is_terminal and node.rule == rule[0] and node.number == rule[1]


func isJoining(terminals: openArray[Terminal], at: int): bool =
  ## jdice lo du'u xu kau le cmavo be `I` be'o poi zvati `at` cu jorne lo jufra
  ##   .i va'o lo nu le cmavo cu lidne lo me `jek` me'u .a lo me `joik` me'u kei le cmavo cu jorne
  ##   .i lo cmavo be la'o gy. NA .gy. be'o .e lo cmavo be la'o gy. SE .gy. cu ka'e zvati lo jbini
  ##   .i va'o lo nu le cmavo cu lidne lo porsi be lo tcita poi se fanmo la'o gy. BO .gy. kei le
  ##     cmavo cu jorne ji'a to le javni pe li pare .e li paci toi
  ##   .i ro le cmavo poi jorne cu vasru no ju'agri pe vo'a
  var k = at + 1
  while k < terminals.len and terminals[k].isAmong({Selmaho.Na, Selmaho.Se}): inc k
  if k < terminals.len and terminals[k].isAmong(JOINS): return true
  k = at + 1
  while k < terminals.len and terminals[k].isAmong(TAGS): inc k
  k > at + 1 and k < terminals.len and terminals[k] == Selmaho.Bo.toTerminal


func isCutAt*(terminals: openArray[Terminal], at: int, before: Option[Terminal]): bool =
  ## jdice lo du'u xu kau le nu tcidu ro pagbu cu katna le se ciska pu le gerna valsi pe `at` va'o
  ##   lo nu no krasi valsi cu ca'o kalri
  ##   .i le gerna valsi cu du lo cmavo be `NIhO` be'o poi se lidne no cmavo be `NIhO` ku'o .a lo
  ##     cmavo be `I` poi jorne no da to `toParts` toi
  ##   .i `before` cu dunda le gerna valsi poi lidne `at`
  let terminal = terminals[at]
  (terminal == Selmaho.Niho.toTerminal and before != some(Selmaho.Niho.toTerminal)) or
    (terminal == Selmaho.I.toTerminal and not terminals.isJoining(at))


func isTracked(
    opened: var seq[tuple[selmaho: Selmaho, at: int]], terminals: openArray[Terminal], i: int,
    ignored: openArray[int],
): bool =
  ## galfi le liste be lo krasi valsi poi ca'o kalri sepi'o le gerna valsi pe `i`
  ##   .i le romoi pe le liste cu traji lo ka ce'u se vasru
  ##   .i lo krasi valsi cu kalri va'o lo nu `ignored` cu na vasru le krasi valsi
  ##   .i lo fanmo valsi cu fanmo le krasi valsi poi mapti le fanmo valsi gi'e traji lo ka ce'u
  ##     jibni le fanmo valsi ku'o .e ro krasi valsi poi zvati ne'i le krasi valsi
  ##   .i le jalge cu du `true` va'o lo nu le gerna valsi cu krasi valsi gi'a fanmo valsi
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
  ## dunda lo stuzi namcu pe ro krasi valsi poi zvati `first ..< last` zi'e poi no fanmo valsi poi
  ##   zvati vi cu fanmo ke'a ku'o ja'i le porsi
  ##   .i le krasi valsi cu du zo tu'e .a zo lu .a zo to gi'e denpa lo fanmo valsi pe vo'a ne'i lo
  ##     jmive se ciska
  var opened: seq[tuple[selmaho: Selmaho, at: int]]
  for i in first ..< last: discard opened.isTracked(terminals, i, [])
  opened.mapIt(it.at)


func toParts(
    terminals: openArray[Terminal], first, last: int, ignored: openArray[int] = []
): Split =
  ## fendi le gerna valsi pe `first ..< last` fi lo pagbu poi se tcidu ta'i lo nu sepli
  ##   .i katna pu ro cmavo be `NIhO` be'o poi se lidne no cmavo be `NIhO` ku'o .e ro cmavo be `I`
  ##     be'o poi jorne no da
  ##   .i le nu katna cu fasnu va'o lo nu no krasi valsi cu ca'o kalri
  ##   .i `inner` cu krasi le se ciska pe zo tu'e poi no me zo tu'u me'u cu fanmo ke'a
  ##   .i le se ciska cu se fanmo `last`
  ##   .i va'o lo drata `inner` cu du `last`
  ##   .i ro nu katna cu zvati lo stuzi poi no krasi valsi cu ca'o kalri vi ke'a
  ##   .i se ki'u bo ro nu katna cu zvati pu le pamoi krasi valsi poi ca'o kalri
  ##   .i va'o lo nu zo lu .a zo to cu ca'o kalri kei le pagbu poi vasru le krasi valsi cu se fanmo
  ##     `last` gi'e se tcidu pa roi
  ##   .i ki'u bo lo valsi poi se lidne le krasi valsi cu jdice lo du'u ma kau poi stuzi cu fanmo le
  ##     gerna stura pe le krasi valsi
  ##   .i lo krasi valsi poi `ignored` cu vasru ke'a cu se tcidu ta'i lo sampu gerna valsi
  ##   .i lo jmive se ciska cu se katna ba ro krasi valsi poi denpa lo fanmo valsi pe vo'a
  ##   .i se ki'u bo ro jufra poi se lidne le krasi valsi cu se benji gi'e na denpa le fanmo valsi
  ##   .i la'o gy. Architect .gy. cu jdice di'u bu'u `#859`
  var
    starts = @[first]
    # ro krasi valsi poi ca'o kalri
    #   .i le romoi cu traji lo ka ce'u se vasru
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
  ## jmina `by` ro stuzi poi le gerna cu sisti bu'u ke'a ku'o .e lo stuzi namcu pe ro gerna valsi pe
  ##   le tricu
  ##   .i va'o lo nu pa pagbu cu se tcidu ta'i lo nu sepli kei le stuzi namcu pe le krasi be le
  ##     pagbu cu du li no
  if node.is_terminal: node.at += by
  else:
    if node.stop.isSome: node.stop.get.at += by
    for child in node.children.mitems: child.shift(by)


func readPart(terminals: openArray[Terminal], part: Slice[int]): Option[Node] =
  ## tcidu le gerna valsi pe le pagbu ta'i lo se ciska poi sepli
  ##   .i zbasu lo tricu
  ##   .i ne'i le tricu le stuzi namcu pe le krasi be le mulno se ciska cu du li no
  var reading = terminals.toOpenArray(part.a, part.b).readWhole
  if not reading.is_read: return none(Node)
  var tree = move(reading.tree)
  tree.shift(part.a)
  some(tree)


func isGroup(nodes: openArray[Node], terminals: openArray[Terminal], head: Selmaho): bool =
  ## jdice lo du'u xu kau le jgena cu du lo gerna valsi pe `head` ge'u ce'o lo zifre galfi po'o
  ##   .i mupli fa `I #` ja'i le javni pe li pano
  ##   .i mupli fa ji'a `NIhO ... #` ja'i le javni pe li vo
  ##   .i va'o lo nu lo me `jek` me'u .a lo me `joik` me'u .a lo tcita .a lo cmavo be la'o gy. BO
  ##     .gy. cu zvati vi kei lo jufra cu jorne
  var k = 0
  while k < nodes.len and nodes[k].is_terminal and terminals[nodes[k].at] == head.toTerminal: inc k
  k > 0 and nodes.toOpenArray(k, nodes.high).allIt(it.isRule(RULE_FREE))


func graftInner(node: var Node, at: int, inner: var Node): bool =
  ## punji `inner` noi me `text-1` me'u ku'o lo jgena po'u `statement-3` zi'e poi zo tu'e pe ke'a cu
  ##   zvati `at`
  ##   .i le jgena cu se facki ne'i le romoi panzi be ro jgena
  ##   .i va'o lo nu le se ciska cu se tcidu ta'i lo nu sepli kei le jgena po'u `text-1` zi'e poi se
  ##     lidne zo tu'e cu kunti
  if node.is_terminal: return false
  if node.isRule(RULE_STATEMENT_3) and node.children.anyIt(it.is_terminal and it.at == at):
    if not node.children[^1].isRule(RULE_TEXT_1) or node.children[^1].children.len > 0:
      return false
    node.children[^1] = move(inner)
    return true
  node.children.len > 0 and node.children[^1].graftInner(at, inner)


func toNode(rule: (string, int), children: sink seq[Node]): Node =
  ## zbasu lo jgena poi vasru `children` zi'e pe lo javni poi se cmene
  Node(is_terminal: false, rule: rule[0], number: rule[1], children: children)


func readParts(terminals: openArray[Terminal], first, last: int, trees: var seq[Node]): bool =
  ## tcidu ro pagbu be le se ciska pe le gerna valsi pe `first ..< last` ta'i lo nu sepli
  ##   .i le pagbu cu se katna ta'i le nu tcidu ro pagbu
  ##   .i punji le tricu `trees`
  ##   .i ba bo tcidu ro pagbu be le se ciska pe zo tu'e poi ca'o kalri
  ##   .i va'o lo nu pa pagbu cu se to'e curmi kei le jalge cu du `false`
  ##   .i va'o lo nu zo lu .a zo to cu ca'o kalri kei le pagbu poi vasru le krasi valsi cu se fanmo
  ##     `last` ja'i le nu `toParts` cu katna
  let split = terminals.toParts(first, last)
  for part in split.parts:
    let tree = terminals.readPart(part)
    if tree.isNone: return false
    # fukpi
    #   .i ki'u bo `get` na dunda lo me `lvalue` me'u noi `move` cu nitcu ke'a ne'i la'o gy.
    #     JavaScript .gy.
    trees.add tree.get
  split.inner >= last or terminals.readParts(split.inner, last, trees)


func assemble(
    terminals: openArray[Terminal], first, last: int, parts: var seq[Node], at: var int
): Option[Node] =
  ## zbasu le tricu poi lo nu tcidu le mulno se ciska cu dunda ke'a le se ciska pe le gerna valsi pe
  ##   `first ..< last`
  ##   .i le tricu cu sruri le tricu pe ro pagbu be le se ciska
  ##   .i le tricu pe le pagbu cu se lebna fi `parts`
  ##   .i le nu lebna cu krasi `at` gi'e mapti le porsi poi `readParts` cu dunda ke'a
  ##   .i le jgena poi sruri cu du `text 0` .e `text-1 2` .e `paragraphs 4` .e `paragraph 10` to le
  ##     javni pe li no bi'o li pano toi
  ##   .i ro pagbu cu vasru lo jgena
  ##   .i ro le jgena cu ckini pa javni po'o
  ##   .i lo tricu pe lo se cuxna cu stodi va'o lo nu le se kuspe .e le javni cu stodi
  ##   .i ro javni poi sruri pa pagbu cu mulno ta'i lo mintu tadji bu'u le re korbi be le pagbu
  ##   .i lo flalu cu cipra di'u sepi'o lo nu tcidu le mulno se ciska
  ##   .i va'o lo nu lo javni pe le nu tcidu ro pagbu cu spofu kei le jalge cu kunti
  ##   .i ba bo le mulno se ciska cu se tcidu pa roi
  let split = terminals.toParts(first, last)
  if at + split.parts.len > parts.len: return none(Node)
  var trees: seq[Node]
  for _ in split.parts:
    trees.add move(parts[at])
    inc at

  # le pamoi pagbu cu dunda `text 0` .e lo jgena pe `text-1` zi'e poi lidne le ju'agri pe le pagbu
  #   .i ro ju'agri cu se vasru lo girzu poi vasru lo cmavo be `NIhO` gi'e lidne le ju'agri ku'o .e
  #     lo jgena pe `paragraph` to le javni pe li re .e li vo toi
  var
    text = move(trees[0])
    text_1 = text.children.pop  # le javni pe li no cu se fanmo `text-1`
    paragraphs: seq[tuple[group, nodes: seq[Node]]]
  if text_1.children.len > 0 and text_1.children[^1].isRule(RULE_PARAGRAPHS):
    var first_paragraphs = text_1.children.pop
    if first_paragraphs.children.len != 1: return none(Node)
    paragraphs.add (newSeq[Node](), move(first_paragraphs.children[0].children))
  for k in 1 ..< trees.len:
    if trees[k].children.len != 1 or not trees[k].children[0].isRule(RULE_TEXT_1):
      return none(Node)  # le pagbu cu se krasi lo valsi poi lo se ciska po'o cu ka'e se krasi ke'a
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
          # le javni pe li re cu se krasi `I` .a `NIhO` gi'e no roi se krasi le re mei
          return none(Node)
        for node in part.children.mitems: text_1.children.add move(node)
        if has_paragraph: paragraphs.add (newSeq[Node](), move(nodes))
      else:
        for node in part.children.mitems: paragraphs[^1].nodes.add move(node)
        for node in nodes.mitems: paragraphs[^1].nodes.add move(node)
    elif head == Selmaho.Niho.toTerminal:
      if not part.children.isGroup(terminals, Selmaho.Niho): return none(Node)
      if paragraphs.len == 0:
        if text_1.children.len > 0: return none(Node)  # le javni pe li re cu se krasi pa girzu po'o
        for node in part.children.mitems: text_1.children.add move(node)
        if has_paragraph: paragraphs.add (newSeq[Node](), move(nodes))
      else:
        if not has_paragraph: return none(Node)  # le javni pe li vo cu vasru `paragraph` ba `NIhO`
        paragraphs.add (move(part.children), move(nodes))
    else:
      return none(Node)

  # le se ciska pe zo tu'e poi ca'o kalri cu se fanmo le fanmo
  #   .i zbasu ji'a le tricu pe le se ciska fi le pagbu be le se ciska gi'e punji le tricu le drani
  #     stuzi
  if split.inner < last:
    var inner = terminals.assemble(split.inner, last, parts, at)
    if inner.isNone or paragraphs.len == 0: return none(Node)
    if inner.get.children.len != 1 or not inner.get.children[0].isRule(RULE_TEXT_1):
      # le se ciska pe zo tu'e cu me `text-1` me'u
      #   .i `text-1` na se krasi lo krasi pagbu pe `text`
      return none(Node)
    var inner_text_1 = move(inner.get.children[0])
    if paragraphs[^1].nodes.len == 0: return none(Node)
    if not paragraphs[^1].nodes[^1].graftInner(split.inner - 1, inner_text_1):
      return none(Node)

  # punji ro ju'agri ne'i le ju'agri poi lidne ke'a
  #   .i le nu punji cu krasi le romoi ju'agri
  #   .i ro ju'agri cu vasru le girzu pe le bavla'i ju'agri ge'u .e le rebla poi se lidne le girzu
  #     to le javni pe li vo toi
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
  ## tcidu ro pagbu be le se ciska pe le gerna valsi pe `first ..< last` gi'e zbasu le tricu poi lo
  ##   nu tcidu le mulno se ciska cu dunda ke'a gi'e sruri le jgena pe le pagbu to `assemble` toi
  ##   .i va'o lo nu pa pagbu cu se to'e curmi kei .a lo nu lo javni pe le nu tcidu ro pagbu cu
  ##     spofu kei le jalge cu kunti
  ##   .i ba bo le mulno se ciska cu se tcidu pa roi
  ##   .i le nu tcidu cu cusku ro nu to'e curmi
  var
    trees: seq[Node]
    at = 0
  if not terminals.readParts(first, last, trees): return none(Node)
  terminals.assemble(first, last, trees, at)


func assembleText*(terminals: openArray[Terminal], parts: openArray[Node]): Option[Node] =
  ## zbasu le tricu pe le se ciska fi le tricu pe ro pagbu be le se ciska be'o poi se tcidu ta'i lo
  ##   nu sepli
  ##   .i le pagbu cu se porsi ja'i le nu tcidu ro pagbu to `readGrammarParts` toi
  ##   .i se ki'u bo le pagbu cu cirko no pagbu be le tricu poi `readGrammar` cu dunda ke'a le se
  ##     ciska poi le pagbu cu pagbu ke'a
  ##   .i le tricu pe pa se ciska poi vasru pa pagbu po'o cu du le tricu pe le pagbu
  ##   .i va'o lo nu lo javni pe le nu tcidu ro pagbu cu spofu kei le jalge cu kunti
  ##   .i ba bo lo nu tcidu le mulno se ciska po'o cu tcidu le se ciska
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
  ## tcidu lo gerna valsi pe le se ciska ja'i le gerna pe `CLL 21.1` gi'e zbasu lo tricu pe lo javni
  ##   poi se cmene
  ##   .i to'e curmi bu'u le stuzi poi ro cumki tricu cu sisti bu'u ke'a
  ##   .i tcidu ro pagbu be le se ciska
  ##   .i se ki'u bo lo temci cu zenba simsa lo ni le se ciska cu clani to `#849` toi
  ##   .i lo nu tcidu le mulno se ciska pa roi cu tcidu le se ciska va'o lo nu le nu tcidu ro pagbu
  ##     cu na ka'e tcidu
  ##   .i le nu tcidu le mulno se ciska cu cusku ro nu to'e curmi
  ##   .i lo se ciska poi vasru pa pagbu po'o cu se tcidu pa roi ca ku
  ##   .i ki'u bo lo nu tcidu ro pagbu cu tcidu le se ciska ta'i le mintu tadji gi'e rapli zbasu le
  ##     tricu
  ##   .i va'o lo nu le se ciska cu se to'e curmi kei lo nu tcidu ro pagbu cu tcidu le se ciska re
  ##     roi
  let split = terminals.toParts(0, terminals.len)
  if split.parts.len > 1 or split.inner < terminals.len:
    let built = terminals.buildText(0, terminals.len)
    if built.isSome: return ReadingGrammar(is_read: true, tree: built.get)
  terminals.readWhole



#[ ni'o ni'o ni'o lo nu sinxa lo srera ]#

func toError(reading: ReadingGrammar, children: sink seq[Node]): Node =
  ## zbasu lo srera jgena poi vasru `children` zi'e pe le nu to'e curmi
  ##   .i le srera jgena cu ponse le javni poi sisti gi'e traji lo ka ce'u se vasru ku'o .e le sisti
  ##     stuzi pe le gerna ge'u .e lo gerna valsi poi su'o cumki tricu cu tcidu ke'a vi
  let rule = reading.head.toRule
  Node(
    is_terminal: false, rule: rule.name, number: rule.number, children: children,
    stop: some(Stop(at: reading.at, expected: reading.expected)),
  )


func islands(terminals: openArray[Terminal], first, last: int): seq[Node] =
  ## gacri le gerna valsi pe `first ..< last` sepi'o lo tricu pagbu poi mapti `CLL 21.1` ku'o .e lo
  ##   gerna valsi poi zvati lo jbini be le tricu pagbu
  ##   .i le gacri cu vasru lo mleca traji gerna valsi poi zvati lo jbini
  ##   .i ba bo le gacri cu vasru lo mleca traji pagbu
  ##   .i va'o lo nu dunli kei le gacri poi le pamoi pagbu pe ke'a cu traji lo ka ce'u clani cu
  ##     jinga
  ##   .i ro tricu pagbu cu du lo javni poi se cmene gi'e kuspe le se kuspe pe le tricu pagbu gi'e
  ##     ponse lo mleca traji namcu
  ##   .i va'o lo nu le valsi pe le se kuspe cu se tcidu ta'i lo nu sepli kei le javni cu du le
  ##     javni pe li no zi'e po'u `text`
  ##   .i se ki'u bo le tricu pagbu cu du le tricu poi le valsi cu dunda ke'a ta'i lo nu sepli
  ##   .i se to'e cuxna fa lo javni poi ponse lo zmadu traji namcu
  ##   .i ki'u bo lo drata cumki tricu pe le se kuspe cu ka'e vasru le javni
  ##   .i mupli fa lo nu lu mi klama li'u cu se tcidu ta'i `sumti-tail` noi ckini li papapa ku'o
  ##     gi'e na se tcidu ta'i `sentence` noi ckini li vono
  ##   .i ne'i `sumti-tail` zo mi cu sinxa lo ponse be le klama
  let count = last - first
  if count == 0: return
  var chart = Chart(
    completions:
      terminals.toOpenArray(first, last - 1).fillSets(is_everywhere = true).toCompletions,
    terminals: terminals[first ..< last],
  )

  # le stedu be lo tricu pagbu poi kuspe ro se kuspe ku'o ja'i le krasi .e le fanmo
  #   .i le stedu cu du lo javni poi se cmene gi'e ponse lo mleca traji namcu vi
  var heads = newSeq[Table[int, int]](count)
  for finish in 1 .. count:
    for (head, start) in chart.completions[finish].keys:
      if start >= finish or GRAMMAR_EBNF.numbers[head].isNone: continue
      let is_outer = finish notin heads[start] or
        GRAMMAR_EBNF.numbers[head].get < GRAMMAR_EBNF.numbers[heads[start][finish]].get
      if is_outer: heads[start][finish] = head

  # le gacri be le gerna valsi poi zvati ro stuzi bi'o le fanmo
  #   .i le nu facki cu krasi le romoi stuzi
  #   .i le gacri cu vasru lo te kancu be lo gerna valsi poi zvati lo jbini ku'o be'o .e lo te kancu
  #     be lo pagbu be'o .e le fanmo be le pamoi pagbu be'o .e le stedu be le tricu pagbu pe le
  #     pamoi pagbu
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
  #   .i ro tricu pagbu cu ponse le tricu poi lo pagbu poi se tcidu ta'i lo nu sepli cu dunda ke'a
  var start = 0
  while start < count:
    let cover = covers[start]
    if cover.head.isNone:
      result.add Node(is_terminal: true, at: first + start)
    else:
      doAssert chart.choose(cover.head.get, start, cover.finish).isSome,
          "Span completions hold should derive tree."
      # le javni cu se cmene
      #   .i se ki'u bo lo jgena cu pa mei
      chart.addNodes(cover.head.get, start, cover.finish, result)
      result[^1].shift(first)
    start = cover.finish


func markPart(terminals: openArray[Terminal], part: Slice[int]): Node =
  ## tcidu le pagbu ta'i lo se ciska poi sepli gi'e zbasu lo tricu
  ##   .i ne'i le tricu le stuzi namcu pe le krasi be le mulno se ciska cu du li no
  ##   .i va'o lo nu le gerna cu to'e curmi le pagbu kei zbasu lo srera jgena pe le pagbu zi'e poi
  ##     vasru lo tricu pagbu poi mapti `CLL 21.1` to `islands` toi
  var reading = terminals.toOpenArray(part.a, part.b).readWhole
  if reading.is_read:
    result = move(reading.tree)
    result.shift(part.a)
    return
  result = reading.toError(terminals.islands(part.a, part.b + 1))
  result.stop.get.at += part.a


func markText(
    terminals: openArray[Terminal], first, last: int, ignored: openArray[int] = []
): seq[Node] =
  ## dunda lo pagbu be le se ciska pe le gerna valsi pe `first ..< last` ta'i lo nu le nu tcidu ro
  ##   pagbu cu katna to `toParts` toi
  ##   .i le pagbu cu du lo tricu pe ro pagbu poi se tcidu ta'i lo nu sepli ku'o ge'u .e lo srera
  ##     jgena pe ro pagbu poi na se tcidu
  ##   .i ba bo dunda lo pagbu be le se ciska pe zo tu'e poi ca'o kalri
  ##   .i va'o lo nu zo lu .a zo to cu ca'o kalri kei le pagbu poi vasru le krasi valsi cu se fanmo
  ##     `last`
  ##   .i lo krasi valsi poi `ignored` cu vasru ke'a cu se tcidu ta'i lo sampu gerna valsi
  let split = terminals.toParts(first, last, ignored)
  for part in split.parts: result.add terminals.markPart(part)
  if split.inner < last: result.add terminals.markText(split.inner, last, ignored)


func readGrammarParts*(
    terminals: openArray[Terminal], is_live = false
): tuple[parts: seq[Node], open: seq[int]] =
  ## tcidu lo gerna valsi ja'i le gerna pe `CLL 21.1` gi'e zbasu lo jgena pe ro pagbu ta'i lo nu le
  ##   nu tcidu ro pagbu cu katna
  ##   .i le jgena cu du lo tricu pe ro pagbu poi se tcidu ta'i lo nu sepli ku'o ge'u .e lo srera
  ##     jgena pe ro pagbu poi na se tcidu
  ##   .i ba bo le jgena cu du lo pagbu be le se ciska pe zo tu'e poi ca'o kalri
  ##   .i `assembleText` cu zbasu le tricu pe le se ciska fi le jgena
  ##   .i se ki'u bo le jgena cu cirko no pagbu be le tricu
  ##   .i lo jmive se ciska cu se katna ba ro krasi valsi poi denpa lo fanmo valsi pe vo'a
  ##   .i se ki'u bo ro jufra poi se lidne le krasi valsi cu se tcidu ta'i lo nu sepli to `is_live`
  ##     toi
  ##   .i `open` cu dunda lo stuzi namcu pe ro le krasi valsi
  ##   .i le fanmo valsi cu rapli tcidu le krasi valsi
  let open = (if is_live: terminals.unclosed(0, terminals.len) else: @[])
  (terminals.markText(0, terminals.len, open), open)


func readGrammarMarked*(terminals: openArray[Terminal]): Node =
  ## tcidu lo gerna valsi ja'i le gerna pe `CLL 21.1` gi'e zbasu lo tricu pe lo javni poi se cmene
  ##   ta'i lo nu `readGrammar` cu zbasu
  ##   .i va'o lo nu le gerna cu to'e curmi le gerna valsi kei zbasu lo srera jgena pe le mulno se
  ##     ciska
  ##   .i se ki'u bo le tricu cu sinxa ro srera to `#859` toi
  ##   .i va'o lo nu le se ciska cu se katna fi lo pagbu kei le srera jgena pe le se ciska cu vasru
  ##     lo tricu pe ro pagbu poi se tcidu ta'i lo nu sepli ku'o ge'u .e lo srera jgena pe ro pagbu
  ##     poi na se tcidu
  ##   .i se ki'u bo lo nu tcidu cu rapli cfari bu'u ro pagbu
  ##   .i le srera jgena pe lo se ciska poi vasru pa pagbu po'o cu vasru lo tricu pagbu poi mapti
  ##     `CLL 21.1` ku'o .e lo gerna valsi poi zvati lo jbini be le tricu pagbu to `islands` toi
  var reading = terminals.readGrammar
  if reading.is_read: return move(reading.tree)
  let
    split = terminals.toParts(0, terminals.len)
    is_parted = split.parts.len > 1 or split.inner < terminals.len
  reading.toError(
    if is_parted: terminals.markText(0, terminals.len) else: terminals.islands(0, terminals.len)
  )
