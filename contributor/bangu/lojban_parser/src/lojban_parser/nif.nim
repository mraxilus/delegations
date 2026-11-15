## ciska lo tricu pe lo selci'a fi pa selci'a be fi `NIF 2027` pe `nim-lang/nifspec` mu'i lo nu lo
##     drata samtci cu tcidu le tricu
##   .i `Nim 3` ralte lo tricu pe vo'a ne'i lo selci'a be fi `NIF`
##   .i `Architect` cuxna `NIF` to `D1 c` pe `#852` toi
##
##   |---------------|--------------------------------------------------------------------|
##   | lo cmene      | lo smuni                                                           |
##   |---------------|--------------------------------------------------------------------|
##   | `TerminalNif` | lo genvla ta'i `NIF`                              |
##   |               | .i lo klesi ce'o lo stuzi .e bo lo lerfu pe lo valsi               |
##   | `LeavesNif`   | lo genvla pe lo tricu poi selrapyzba fi `NIF` |
##   |               | .i `merge.nim` rapyzba le tricu                             |
##   |               | .i ro pezli be le tricu cu sinxa pa le genvla                 |
##   | `toNif`       | lo selci'a be fi `NIF` be'o poi vasru lo tricu        |
##   |               | .i le tricu cu pagbu lo se tcidu gi'a selrapyzba               |
##   |               | .i ro valsi cu zvati lo stuzi pe vo'a                              |
##   |---------------|--------------------------------------------------------------------|
##
## ni'o `(.nif27)` noi minde cu krasi lo selci'a be fi `NIF` gi'e se lidne no stuzi
##   .i `(.lang "cll-21.1")` se lidne `(.nif27)` gi'e cusku lo du'u ro tcita cu cmene lo javni pe
##       `CLL 21.1` .a lo klesi be lo genvla
##   .i lo lerfu pe ro tcita cu mintu lo lerfu poi le gerna cu ciska ke'a
##   .i ro javni poi selcme cu du lo jgena poi vasru lo tcita .e lo jgena
##   .i le tcita cu cmene le javni gi'e lidne lo jgena poi le javni cu vasru ke'a
##   .i no jgena cu ciska lo namcu pe le javni ne'i `CLL 21.1`
##   .i ki'u bo lo cmene be le javni cu jarco le namcu to `LUT_NUMBER_BY_RULE` toi
##   .i `Architect` jdice di'u bu'u `#859` to `comment 6805527878` toi
##   .i lo fukpi be le namcu cu ka'e rinka lo nu pa jgena cu cmene re javni
##   .i lo porsi be lo javni poi ro ke'a vasru lo bavla'i javni po'o cu du pa jgena
##   .i le jgena cu vasru lo tcita be lo javni poi fanmo le porsi
##   .i lo namcu pe lo javni poi krasi le porsi cu se lidne le tcita mu'u `(sumti_6 80 ...)` noi du
##       lo porsi poi selkra `terms<80>` gi'e selfa'o `sumti-6<97>`
##   .i ne'i `CLL 21.1` re fanmo cu jarco pa porsi to `LUT_CHAIN_BY_ENDS` toi
##   .i se ki'u bo le tcidu cu rapyzba ro javni poi zvati lo jbini be le re fanmo
##   .i le tcidu cu rapyzba le multricu
##   .i lo jgena poi ciska no namcu cu krasi no porsi mu'u `(tail_terms)`
##   .i ro genvla cu du lo jgena poi vasru lo tcita .e lo jgena
##   .i lo tcita cu cmene lo klesi be le genvla mu'u `KOhA` .a `BRIVLA`
##   .i ro valsi pe le genvla cu selja'o ci jgena poi se lidne le tcita
##   .i le ci jgena cu jarco lo stuzi poi le valsi cu krasi bu'u ke'a ku'o .e lo stuzi poi se lidne
##       lo romoi lerfu pe le valsi ku'o .e lo lerfu pe le valsi ta'i lo lerpoi mu'u
##       `(BU 15 17 "ta" 18 20 "bu")`
##   .i se ki'u bo ro valsi cu jorne lo stuzi pe le selci'a poi le valsi cu se tcidu fi ke'a
##   .i lo porsi be lo genvla ne'i le tricu cu jarco lo namcu pe ro pagbu
##   .i se ki'u bo no jgena cu vasru lo namcu pe lo pagbu
##   .i lo javni poi selcme cu ciska no stuzi
##   .i le javni cu kuspe lo stuzi pe lo pezli poi le javni cu vasru ke'a
##   .i le tcidu cu lebna le stuzi le pezli
##   .i jdima fa lo nu lo selci'a be fi `NIF` be'o pe le selci'aste cu zenba fi `8.0 percent` ki'u
##       lo stuzi poi se lidne ro valsi to lu lo se ciska be fi `NIF` li'u pe `PROVENANCE.md` toi
##   .i se to'e cuxna fa lo nu ciska lo stuzi po'o poi lo valsi cu krasi bu'u ke'a
##   .i ki'u bo lo tcidu cu na ka'e facki lo du'u ma kau poi stuzi cu fanmo le valsi kei sepi'o lo
##       lerfu po'o
##   .i ki'u bo lo lerfu po'u slaka bu poi zvati ne'i lo valsi cu ciska lo stuzi poi lo lerfu cu
##       vimcu ke'a
##   .i lo se tcidu poi sinxa ro srera to `readTextMarked` .e `#859` toi cu ciska ji'a re klesi be
##       lo jgena
##   .i lo srejge cu selkra lo tcita po'u `srera`
##   .i lo stuzi poi le gerna cu sisti bu'u ke'a se lidne le tcita
##   .i lo tcita be lo javni poi sisti bu'u le stuzi gi'e traji lo ka dizlo cu se lidne le stuzi
##   .i no namcu pe le javni cu selci'a ki'u lo nu lo cmene be le javni cu jarco le namcu to lo
##       seljdi pe `#859` pe `comment 6806614095` toi
##   .i `(nitcu ...)` se lidne le tcita be le javni gi'e vasru lo klesi be ro genvla poi su'o nu
##       genytcidu cu tcidu ke'a bu'u le stuzi
##   .i lo jgena poi le srejge cu vasru ke'a se lidne `(nitcu ...)`
##   .i lo porsi be lo javni cu sisti bu'u lo jgena poi gapru le srejge ki'u lo nu no porsi pe
##       `CLL 21.1` vasru le srejge
##   .i lo pagbu poi no genvla cu vasru ke'a selkra lo tcita po'u `rivbi`
##   .i lo cmene be lo velru'e poi to'e curmi le pagbu cu se lidne le tcita mu'u `selmaho`
##   .i lo stuzi .e lo lerfu pe ro valsi pe le pagbu cu se lidne le cmene
##   .i lo genvla cu ciska lo stuzi .e lo lerfu ta'i le mintu
##   .i lo velru'e po'u `Stream` jmina lo nu to'e curmi pe lo porsi be lo valsi mu'u `Letter`
##   .i lo selci'avla poi le porsi be lo valsi cu to'e curmi ke'a ralte lo stuzi pe vo'a
##   .i lo selci'a poi zo zoi sitna ke'a go'i ji'a
##   .i no `h` basti `'`
##   .i `'` se basti lo basysni
##   .i se to'e cuxna fa lo nu le pagbu cu vasru lo ve pruce po'o
##   .i ki'u bo le porsi be lo valsi .e lo gerna pe lo nu sitna cu dunda lo cmene po'u `Quotation`
##       lo nu to'e curmi
##   .i se ki'u bo lo tcidu cu na ka'e ganse lo nu lo stuzi cu frica lo valsi
##   .i lo pagbu poi se tcita `SU` .a `Erasure` .a `FAhO` sinxa no nu to'e curmi
##   .i ku'i le pagbu cu vasru lo valsi poi no genvla cu tcidu ke'a
##   .i lo pagbu poi se tcita `SU` vasru zo su poi fanmo lo selci'a poi lidne zo su
##   .i lo pagbu poi se tcita `Erasure` vasru lo valsi poi lo nu vimcu cu vimcu ke'a ku'o .e lo
##       cmavo poi vimcu le valsi
##   .i lo pagbu poi se tcita `FAhO` vasru zo fa'o poi fanmo le selci'a
##   .i ro selci'avla poi se lidne zo fa'o se tcita `Stream` gi'e ponse lo nu to'e curmi po'u `FAhO`
##       gi'e ralte lo stuzi pe vo'a
##   .i se ki'u bo ro stuzi pe ro valsi cu zvati pa pezli to `isCovering` pe lo cipra toi
##   .i va'o lo nu `CLL` dunda lo valsi kei ro tcita poi cmene lo sinxa .a lo velru'e .a lo nu to'e
##       curmi cu du lo valsi pe `CLL` gi'e selci'a ta'i `CLL`
##   .i lo cmene be lo selma'o cu mintu lo cmene poi `CLL 20` dunda ke'a mu'u `SU`
##   .i lo jbovla cu selci'a ta'i lo cmale'u mu'u `slinkuhi`
##   .i lo glivla cu stali mu'u `Erasure` pe `CLL 19.13`
##   .i va'o lo nu `CLL` dunda no valsi kei lo tcita cu du pa valsi pe le gimste
##   .i `srera` selsmu zoi gy. errs .gy.
##   .i `nitcu` selsmu zoi gy. needs .gy.
##   .i `rivbi` selsmu zoi gy. avoids .gy.
##   .i `Architect` jdice di'u bu'u `#859`
##   .i se to'e cuxna fa lo jbocme be lo javni pe `CLL 21.1`
##   .i `CLL` dunda no jbocme be lo javni
##   .i se ki'u bo lo tcita be lo javni cu ralte lo cmene pe `CLL 21.1` ca lo nu `CLL` dunda no
##       jbocme
##   .i se to'e cuxna fa lo lujvo po'u `naltcidu` noi basti `rivbi`
##   .i no liste cu vasru `naltcidu`
##   .i lo tcita cu ciska `_` lo stuzi be ro `-`
##   .i no cmene pe `CLL 21.1` vasru `_`
##   .i lo valsi cu ciska `h` lo stuzi be ro `'` ta'i lo nu `CLL 20` ciska `h` ta'i lo brale'u pe
##       `'` ne'i lo cmene be lo selma'o
##   .i la lojban. na ciska `h` to `CLL 3.3` toi
##   .i lo porsi be lo valsi cu to'e curmi `h` poi na zvati lo nu sitna
##   .i se ki'u bo le tcidu cu tcidu `-` fi `_` gi'e tcidu `'` fi `h`
##   .i se ki'u bo no tcita .e no valsi cu nitcu lo basysni pe `NIF`
##   .i lo selci'a poi zo zoi .a zo la'o sitna ke'a cimoi lo lerpoi pe lo genvla pe `ZOI` gi'e stali
##   .i ro midle'u pe `NIF` .e ro stuzi poi mleca lo kutle'u cu se basti `\xx`
##   .i `#` .e `:` .e lo kutle'u .e ro stuzi poi na mleca li parebi cu stali
##   .i se to'e cuxna fa `\2D` pe lo tcita ge'u .e `\27` pe lo valsi
##   .i le velski cu dunda le re basysni
##   .i `Architect` to'e cuxna le re basti sinxa to `#855` toi
##   .i le tcidu pe `nimony` pe `2c5b3dca` tcidu lo tcita ta'i lo stuzi pe le tcita
##   .i se ki'u bo le tcidu cu na galfi `\2D`
##   .i lo javni pe lo datni poi zvati lo jbini be lo samtci cu curmi `NIF` to
##       `CONTRIBUTOR.md, Data` toi
##   .i lo flalu pe lo cipra cu cipra lo tarmi be `NIF`
##   .i `test_nif.nim` ciska ro tricu pe le selci'aste gi'e rapyzba ro le tricu ta'i lo mulno sepi'o
##       lo nu tcidu
##   .i se to'e cuxna fa lo nu lo datni be lo linji cu jarco lo stuzi pe lo valsi
##   .i ki'u bo `NIF` ciska le datni ta'i lo vujnu be fi lo mamjge
##   .i le tcidu pe `nimony` pilno `10 bits` po'o lo nu ralte lo stuzi ne'i lo linji
##   .i se ki'u bo le tcidu cu katna lo stuzi poi zmadu li panoreci lo'o to `#852` toi
##   .i se to'e cuxna fa lo bakfu pe `nimony` zi'e noi na ka'e se fanva fi `JavaScript` to `#852`
##       toi
##   .i le ciska cu rapli ja'i lo namcu pe lo jgena gi'e klama fo lo porsi be lo javni ta'i lo nu le
##       fancu cu pilno vo'a
##   .i ki'u bo `items` .e lo nu cmene lo jgena cu zbasu lo fukpi be le jgena va'o lo nu fanva fi
##       `JavaScript`
##   .i lo tricu poi selrapyzba fi `NIF` to `toTree` pe `merge.nim` toi cu selci'a ta'i lo nu ciska
##       lo se tcidu
##   .i lo pezli be le tricu cu sinxa lo genvla poi `NIF` dunda ke'a
##   .i `'` basti ro `h` pe lo valsi pe le genvla
##   .i ku'i lo selci'a poi lo nu sitna cu vasru ke'a ku'o .e lo selci'avla poi le porsi be lo valsi
##       cu to'e curmi ke'a stali
##   .i lo srejge cu vasru lo stuzi poi le gerna cu sisti bu'u ke'a ta'i lo nu `NIF` dunda le stuzi
##   .i se ki'u bo ro lerfu pe le selci'a be fi `NIF` be'o poi le tricu cu selrapyzba fi ke'a
##       selrapci'a ca lo nu ciska le tricu to `test_merge.nim` toi

{.experimental: "strictFuncs".}

import std/[options, strutils]

import ./[dictionary, grammar, prose, selmaho, stream, tanru]


type
  WordNif* = tuple[start, finish: int, letters: string]
    ## pa valsi pe pa genvla poi `NIF` dunda ke'a
    ##   .i `NIF` dunda le valsi ta'i lo stuzi poi le valsi cu krasi bu'u ke'a ku'o .e lo stuzi poi
    ##       se lidne le valsi ku'o .e lo lerfu pe le valsi
    ##   .i `'` basti ro `h` pe le valsi

  TerminalNif* = tuple[terminal: string, words: seq[WordNif]]
    ## pa genvla poi `NIF` dunda ke'a
    ##   .i lo klesi cu lidne ro valsi
    ##   .i lo pagbu poi no genvla cu vasru ke'a dunda `rivbi` ce'o lo velru'e
    ##   .i le velru'e po'u `Stream` se lidne lo nu to'e curmi pe lo porsi be lo valsi
    ##   .i `rivbi` .e le velru'e .e le nu to'e curmi cu sepli fi lo kutle'u

  LeavesNif* = object
    ## lo genvla pe lo tricu poi selrapyzba fi `NIF`
    ##   .i ro pezli be le tricu cu sinxa pa le genvla
    terminals*: seq[TerminalNif]


const
  CONTROLS = {'(', ')', '[', ']', '{', '}', '~', '#', '\'', '"', '\\', ':', '@'}
    ## lo midle'u pe `NIF`
    ##   .i lo lerpoi .e lo cmene cu vasru le midle'u ta'i lo basti sinxa po'o to
    ##       `Control characters` pe le velski toi
  KEPT_STRING = {'#', ':'}
    ## lo midle'u poi lo lerpoi cu vasru ke'a gi'e na basti ke'a to `String literals` toi
  KEPT_IDENTIFIER = {'a'..'z', 'A'..'Z', '0'..'9', '_'}
    ## lo stuzi poi mleca li parebi zi'e poi lo cmene cu vasru ke'a gi'e na basti ke'a to
    ##     `Identifiers` toi
  HEADER* = "(.nif27)\n(.lang \"cll-21.1\")\n"
    ## lo minde poi krasi lo selci'a be fi `NIF`
    ##   .i lo pamoi cu cusku lo namcu pe le tarmi gi'e sinxa le tarmi lo samtci
    ##   .i lo remoi cu cusku lo bangu pe lo tcita pe le selci'a
  TAG_ERROR* = "srera"
    ## lo tcita be lo srejge
    ##   .i zo srera gismu gi'e selsmu zoi gy. x1 errs in doing x2 .gy.
  TAG_EXPECTS* = "nitcu"
    ## lo tcita be lo genvla poi le gerna cu tcidu ke'a bu'u lo stuzi poi le gerna cu sisti bu'u
    ##     ke'a
    ##   .i zo nitcu gismu gi'e selsmu zoi gy. x1 needs x2 .gy.
  TAG_UNREAD* = "rivbi"
    ## lo tcita be lo pagbu poi no genvla cu vasru ke'a
    ##   .i zo rivbi gismu gi'e selsmu zoi gy. x1 avoids x2 .gy.
    ##   .i le gerna cu rivbi le pagbu
  DISTANCE_QUOTED = 2
    ## lo vujnu be lo namcu pe lo se sitna bei lo namcu pe lo cmavo be zoi gy. ZOI .gy.
    ##   .i lo famvla cu zvati lo jbini be le re valsi


func escaped(text: string, is_identifier: bool): string =
  ## ciska lo selci'a
  ##   .i lo basysni `\xx` basti ro stuzi poi `NIF` na vasru ke'a ta'i lo nu stali
  ##   .i `\xx` ciska lo stuzi ta'i re lerfu pe li paxa gi'e pilno lo brale'u
  ##   .i ne'i lo cmene le basysni cu basti ro stuzi poi mleca li parebi gi'e na lerfu gi'e na namcu
  ##       gi'e na du `_`
  ##   .i ne'i lo lerpoi le basysni cu basti ro midle'u poi na du `#` gi'e na du `:` ku'o .e ro
  ##       stuzi poi mleca lo kutle'u ku'o .e `DEL`
  ##   .i ro stuzi poi na mleca li parebi cu stali
  for c in text:
    let is_kept =
      if ord(c) >= 128: true
      elif is_identifier: c in KEPT_IDENTIFIER
      else: ord(c) >= ord(' ') and ord(c) != 127 and (c notin CONTROLS or c in KEPT_STRING)
    if is_kept: result.add c
    else:
      result.add '\\'
      result.add toHex(ord(c), 2)


func tag(name: string): string =
  ## ciska lo cmene be lo javni .a lo klesi be lo genvla ta'i lo tcita
  ##   .i `_` basti ro `-`
  ##   .i lo basysni cu basti ro datstu poi lo cmene cu na vasru ke'a ta'i lo nu stali
  ##   .i no cmene pe le gerna cu nitcu lo basysni
  escaped(name.replace('-', '_'), is_identifier = true)


func spelling*(stage: RefusalText): string =
  ## ciska lo cmene be lo velru'e ta'i lo nu `CLL` ciska lo valsi pe le velru'e
  ##   .i lo cmene be lo selma'o cu mintu lo cmene poi `CLL 20` dunda ke'a
  ##   .i lo jbovla cu selci'a ta'i lo cmale'u
  ##   .i lo glivla pe `CLL` stali
  case stage
  of RefusalText.Su: $Selmaho.Su
  of RefusalText.Faho: $Selmaho.Faho
  of RefusalText.Selmaho: "selmaho"
  else: $stage


func spelling*(refusal: Refusal): string =
  ## ciska lo cmene be lo nu to'e curmi pe lo porsi be lo valsi ta'i lo nu `CLL` ciska lo valsi pe
  ##     le nu to'e curmi
  ##   .i lo cmene be lo selma'o cu mintu lo cmene poi `CLL 20` dunda ke'a
  ##   .i lo jbovla cu selci'a ta'i lo cmale'u
  ##   .i lo glivla pe `CLL` stali
  case refusal
  of Refusal.Faho: $Selmaho.Faho
  of Refusal.Slinkuhi: "slinkuhi"
  else: $refusal


func letters(occurrence: Occurrence): string =
  ## ciska lo selci'avla ta'i lo lerpoi
  ##   .i va'o lo nu le selci'avla cu valsi kei `h` basti ro `'`
  ##   .i lo selci'a poi lo nu sitna cu vasru ke'a stali
  ##   .i lo basysni cu basti ro stuzi poi lo lerpoi cu na vasru ke'a ta'i lo nu stali
  let text =
    if occurrence.reading.is_word: occurrence.text.replace('\'', 'h') else: occurrence.text
  escaped(text, is_identifier = false)


func indexQuoted*(letters: openArray[string]): int =
  ## dunda lo namcu pe lo valsi pe lo genvla pe `ZOI`
  ##   .i le valsi cu vasru lo selci'a poi zo zoi .a zo la'o sitna ke'a
  ##   .i le fancu cu pilno lo lerfu pe lo valsi pe le genvla gi'e tcidu `h` ta'i lo nu tcidu `'`
  ##   .i le valsi cu remoi lo valsi poi se lidne lo cmavo be zoi gy. ZOI .gy.
  ##   .i ro cmavo be zoi gy. BAhE .gy. poi basna le cmavo cu lidne le cmavo to le javni pe li
  ##       papanono toi
  while result < letters.len and letters[result].replace('h', '\'').selmaho != some(Selmaho.Zoi):
    inc result
  result += DISTANCE_QUOTED


func byteAt*(reading: ReadingMarked, at: int): int =
  ## dunda lo stuzi poi le pagbu poi `at` sinxa ke'a krasi bu'u ke'a
  ##   .i va'o lo nu `at` du lo klani be lo pagbu kei dunda lo ni le selci'a cu barda kei noi stuzi
  ##       lo fanmo be le selci'a
  if at < reading.units.len: reading.occurrences[reading.units[at].words[0]].start
  else: reading.size


func addLeaf(text: var string, terminal: TerminalNif) =
  ## jmina lo genvla poi `NIF` dunda ke'a ku'o lo selci'a ta'i lo nu lo se tcidu cu ciska lo genvla
  ##   .i lo klesi .a `rivbi` joi bo lo cmene pe `rivbi` lidne lo stuzi .e lo lerfu pe ro valsi
  ##   .i `h` basti ro `'`
  ##   .i ku'i lo selci'a poi lo nu sitna cu vasru ke'a ku'o .e lo selci'avla poi le porsi be lo
  ##       valsi cu to'e curmi ke'a stali
  var letters: seq[string]
  for k in 0 ..< terminal.words.len: letters.add terminal.words[k].letters
  let
    names = terminal.terminal.split(' ')
    is_kept = names.len > 1 and names[0] == TAG_UNREAD and names[1] == RefusalText.Stream.spelling
    quoted = (if names[0] == $Selmaho.Zoi: some(letters.indexQuoted) else: none(int))
  text.add '('
  text.add names[0].tag
  for k in 1 ..< names.len:
    text.add ' '
    text.add names[k].tag
  for k in 0 ..< terminal.words.len:
    template word: untyped = terminal.words[k]
      ## datcme le valsi
      ##   .i `let` zbasu lo fukpi be le valsi va'o lo nu fanva fi `JavaScript`
    let is_quoted = quoted == some(k)
    text.add ' '
    text.add $word.start
    text.add ' '
    text.add $word.finish
    text.add " \""
    text.add escaped(
      if is_kept or is_quoted: word.letters else: word.letters.replace('\'', 'h'),
      is_identifier = false,
    )
    text.add '"'
  text.add ')'


func addUnit(text: var string, node: Node, reading: ReadingText | ReadingMarked) =
  ## jmina lo genvla pe lo se tcidu lo selci'a
  ##   .i lo klesi cu lidne lo stuzi .e lo lerfu pe ro valsi
  ##   .i va'o lo nu no genvla cu vasru lo pagbu kei lo valsi pe le pagbu cu se lidne `rivbi` ce'o
  ##       lo velru'e poi to'e curmi le pagbu
  ##   .i le velru'e po'u `Stream` se lidne lo nu to'e curmi pe lo porsi be lo valsi
  template unit: untyped = reading.units[node.at]
    ## datcme lo pagbu pe le genvla
    ##   .i `let` zbasu lo fukpi be le pagbu va'o lo nu fanva fi `JavaScript`
  text.add '('
  text.add (if unit.is_read: ($unit.terminal).tag else: TAG_UNREAD)
  if not unit.is_read:
    when reading is ReadingMarked:
      text.add ' '
      text.add unit.refusal.spelling.tag
      if unit.refusal == RefusalText.Stream:
        text.add ' '
        text.add reading.occurrences[unit.words[0]].reading.refusal.spelling.tag
    else:
      doAssert false, "Reading that reads should hold no unit refused."
  for k in 0 ..< unit.words.len:
    template word: untyped = reading.occurrences[unit.words[k]]
      ## datcme lo valsi pe le pagbu
      ##   .i `let` zbasu lo fukpi be le valsi va'o lo nu fanva fi `JavaScript`
    text.add ' '
    text.add $word.start
    text.add ' '
    text.add $word.finish
    text.add " \""
    text.add word.letters
    text.add '"'
  text.add ')'


func addNode(text: var string, node: Node, reading: ReadingText | ReadingMarked | LeavesNif)


func addRule(
    text: var string, node: Node, top: int, reading: ReadingText | ReadingMarked | LeavesNif
) =
  ## jmina lo javni poi selcme ku'o lo selci'a
  ##   .i va'o lo nu lo javni cu vasru pa javni po'o kei le fancu cu jmina le selvau ta'i lo pagbu
  ##       be lo porsi poi krasi bu'u `top`
  ##   .i lo javni poi fanmo lo porsi cu ciska lo tcita pe vo'a ge'u ce'o `top` ce'o lo jgena pe
  ##       vo'a
  ##   .i va'o lo nu le porsi cu selkra le javni poi fanmo le porsi kei `top` na selci'a
  ##   .i lo srejge cu fanmo lo porsi poi gapru le srejge
  ##   .i le srejge cu ciska `srera` ce'o lo stuzi poi le gerna cu sisti bu'u ke'a ku'o ce'o lo
  ##       tcita be lo javni poi sisti bu'u le stuzi be'o ce'o `nitcu` joi lo genvla poi se tcidu
  ##       bu'u le stuzi
  let is_chain = node.stop.isNone and node.children.len == 1 and
    not node.children[0].is_terminal and node.children[0].stop.isNone
  if is_chain:
    text.addRule(node.children[0], top, reading)
    return
  text.add '('
  if node.stop.isSome:
    when reading is ReadingMarked or reading is LeavesNif:
      text.add TAG_ERROR
      text.add ' '
      text.add $(when reading is LeavesNif: node.stop.get.at else: reading.byteAt(node.stop.get.at))
      text.add ' '
    else:
      doAssert false, "Reading that reads should hold no error node."
  text.add node.rule.tag
  if node.stop.isNone and top != node.number:
    text.add ' '
    text.add $top
  if node.stop.isSome:
    text.add " ("
    text.add TAG_EXPECTS
    for k in 0 ..< node.stop.get.expected.len:
      text.add ' '
      text.add ($node.stop.get.expected[k]).tag
    text.add ')'
  for k in 0 ..< node.children.len:
    text.add ' '
    text.addNode(node.children[k], reading)
  text.add ')'




func addNode(text: var string, node: Node, reading: ReadingText | ReadingMarked | LeavesNif) =
  ## jmina lo jgena pe lo tricu lo selci'a
  ##   .i va'o lo nu le jgena cu javni kei le fancu cu jmina lo porsi poi krasi bu'u le jgena gi'e
  ##       porsi lo javni poi selcme
  ##   .i va'o lo nu le jgena cu genvla kei le fancu cu jmina lo klesi ce'o lo stuzi .e bo lo lerfu
  ##       pe ro valsi
  ##   .i va'o lo nu no genvla cu vasru lo pagbu kei lo valsi pe le pagbu cu se lidne `rivbi` ce'o
  ##       lo velru'e poi to'e curmi le pagbu
  ##   .i le velru'e po'u `Stream` se lidne lo nu to'e curmi pe lo porsi be lo valsi
  if not node.is_terminal:
    text.addRule(node, node.number, reading)
    return
  when reading is LeavesNif:
    text.addLeaf(reading.terminals[node.at])
  else:
    text.addUnit(node, reading)




func toNif*(reading: ReadingText): string =
  ## ciska lo tricu pe lo se tcidu fi lo selci'a be fi `NIF`
  ##   .i lo minde cu lidne lo jgena pe le javni po'u `text`
  ##   .i le jgena cu lidne lo fanmo be lo linji
  doAssert reading.is_read, "Reading should read, since refusal holds no tree; got refusal `" &
    $reading.refusal & "`."
  result = HEADER
  result.addNode(reading.tree, reading)
  result.add '\n'


func toNif*(reading: ReadingMarked): string =
  ## ciska lo tricu pe lo se tcidu poi sinxa ro srera ku'o fi lo selci'a be fi `NIF`
  ##   .i lo minde cu lidne lo gejyjge
  ##   .i le gejyjge cu lidne lo fanmo be lo linji
  ##   .i va'o lo nu le selci'a cu se tcidu kei le selci'a be fi `NIF` cu mintu lo selci'a be
  ##       `readText`
  result = HEADER
  result.addNode(reading.tree, reading)
  result.add '\n'


func toNif*(node: Node, reading: ReadingMarked): string =
  ## ciska pa jgena pe lo tricu pe lo se tcidu fi `NIF` ta'i lo nu lo selci'a be fi `NIF` cu ciska
  ##     le jgena
  ##   .i le fancu cu ciska no minde
  ##   .i ne'i lo mivyselci'a lo jgena pe ro pagbu be le selci'a cu selbe'i ne'i lo linji pe vo'a to
  ##       `live.nim` toi
  result.addNode(node, reading)


func toNifParts*(reading: ReadingMarked): string =
  ## ciska lo selci'a be fi `NIF` be'o poi ro jgena pe ke'a panzi lo genja be le se tcidu
  ##   .i ro jgena cu zvati lo linji pe vo'a
  ##   .i le jgena cu du lo jgena pe ro pagbu be le selci'a ge'u .e ro pagbu poi se to'e curmi gi'e
  ##       zvati lo jbini be le pagbu be le se ciska to `readTextParts` toi
  ##   .i lo mivyselci'a cu ciska le jgena ta'i le mintu
  result = HEADER
  for k in 0 ..< reading.tree.children.len:
    result.addNode(reading.tree.children[k], reading)
    result.add '\n'


func toNif*(trees: openArray[Node], leaves: LeavesNif): string =
  ## ciska ro tricu poi selrapyzba fi `NIF` ku'o ta'i lo jgena pe lo selci'a be fi `NIF` ta'i lo nu
  ##     ciska lo se tcidu
  ##   .i lo minde cu lidne ro tricu
  ##   .i ro tricu cu zvati lo linji pe vo'a
  ##   .i se ki'u bo lo nu jmina lo pagbu cu ciska lo tricu pe lo nu tcidu le mulselci'a .a ro tricu
  ##       poi le nu jmina cu dunda ke'a va'o lo nu lo srera cu stali to `merge.nim` toi
  result = HEADER
  for k in 0 ..< trees.len:
    result.addNode(trees[k], leaves)
    result.add '\n'
