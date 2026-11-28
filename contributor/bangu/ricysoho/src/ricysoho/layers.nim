## gunma lo jgena pe lo tricu ta'i lo linji poi zvati lo cnita be lo valsi
##   .i pa linji cu sinxa pa porsi be lo jgena poi pa ckini be lo javni cu cmene ke'a to mu'u
##       `sumti` bi'o `sumti-6` toi
##   .i lo jgena poi vasru re jgena pe le ckini cu cfari pa cnino linji
##   .i ro valsi cu skari ja'i lo girzu be le selma'o be ke'a to `D3 a` pe `#1055` toi
##
##   |------------|------------------------------------------------------------------------------|
##   | lo cmene   | lo smuni                                                                     |
##   |------------|------------------------------------------------------------------------------|
##   | `Category` | lo klesi be pa linji be'o poi pa prenu cu viska ke'a                        |
##   | `Group`    | lo girzu be pa valsi be'o poi le skari be le valsi cu sinxa ke'a             |
##   | `Bar`      | pa linji                                                                     |
##   | `Layers`   | ro linji pe pa se tcidu ge'u .e lo ni le linji cu gapru                      |
##   | `toLayers` | lo linji be lo se tcidu                                                      |
##   | `toGroup`  | lo girzu be pa valsi .a pa selma'o                                           |
##   | `toGloss`  | le cmene be le selma'o be pa valsi                                           |
##   |------------|------------------------------------------------------------------------------|
##
## ni'o pa ckini be lo javni cu du lo cmene be lo javni poi se vimcu lo namcu pe ke'a to mu'u
##     `sumti-6` cu cmima `sumti` toi
##   .i lo jgena cu cfari pa cnino linji va'o lo nu le ckini be ke'a cu drata le ckini be lo mamta
##       be ke'a
##   .i ji'a va'o lo nu le jgena .a le mamta cu vasru re jgena pe le ckini
##   .i lo drata jgena cu jmina pa javni le linji pe le mamta
##
## ni'o lo linji cu se cmene ja'i lo ckini .e lo genvla poi zvati ke'a
##   .i lo linji poi se cmene no da cu se vimcu
##   .i le linji pe le jbini be ke'a cu rapcpa ro linji pe le linji
##   .i lo linji poi vasru lo valsi poi le mamta cu vasru ke'a gi'e mintu le klesi cu gunma le mamta
##   .i lo srejge poi le gerna cu sisti bu'u ke'a cu se cmene no da to `readTextMarked` toi
##   .i `Category.Tail` cu se vimcu to `bridi-tail` toi
##   .i ki'u bo le papri na pixra le klesi ca lo nu cfari

{.experimental: "strictFuncs".}

import std/options

import ./[forms, grammar, prose, selmaho, tanru]


type  # lo klesi pe lo linji .e lo girzu
  Category* {.pure.} = enum  ## lo klesi be pa linji be'o poi pa prenu cu viska ke'a
    Bridi  ## pa bridi to `sentence` toi
    Tail  ## lo romoi pagbu be pa bridi to `bridi-tail` toi
    Sumti  ## pa sumti
    Selbri  ## pa selbri poi vasru pa pagbu po'o
    Tanru  ## pa selbri poi vasru su'o re pagbu
    Unit  ## pa pagbu be pa tanru
    Clause  ## pa jufra poi skicu pa sumti to `relative-clause` toi
    Abstraction  ## pa pagbu be pa tanru poi vasru zo nu .a pa drata cmavo be `NU`
    Linked  ## lo sumti poi zo be jorne ke'a pa pagbu be pa selbri to `linkargs` toi
    Tagged  ## pa sumti poi pa cmavo be `FA` .a pa tcita cu lidne ke'a
    Tag  ## pa tcita poi lidne no sumti
    Number  ## pa namcu .a pa klani
    Free  ## pa valsi .a pa jufra poi na pagbu le bridi to `free` toi

  Group* {.pure.} = enum  ## lo girzu be pa valsi be'o poi le skari be le valsi cu sinxa ke'a
    Predicate  ## lo brivla .e lo cmavo poi zbasu lo selbri
    Sumti  ## lo cmene .e lo cmavo poi zbasu lo sumti
    Number  ## lo cmavo poi zbasu lo namcu
    Tag  ## lo tcita
    Link  ## lo cmavo poi jorne ja punji
    Free  ## lo cmavo poi na pagbu le bridi
    Structure  ## lo cmavo poi fanmo ja fendi
    Refused  ## pa valsi poi le porsi be lo valsi cu to'e curmi ke'a

  Bar* = object  ## pa linji
    category*: Category
    rule*: string  ## lo pamoi javni pe le linji
    number*: int  ## lo namcu pe le javni ne'i `CLL 21.1`
    chain*: seq[string]  ## ro javni poi le linji cu gunma ke'a ta'i le porsi
    first*: int  ## lo stuna'u pe le pamoi valsi pe le linji ne'i `occurrences`
    last*: int  ## lo stuna'u pe le romoi valsi pe le linji ne'i `occurrences`
    parent*: int
      ## lo stuna'u pe le linji poi vasru le linji
      ##   .i li -1 va'o lo nu no linji cu vasru le linji
    depth*: int  ## lo klani be lo linji poi vasru le linji
    height*: int
      ## lo klani be lo linji poi le linji cu vasru ke'a gi'e gapru ke'a ze'u
      ##   .i li 0 va'o lo nu le linji cu vasru no linji

  Layers* = object  ## ro linji pe pa se tcidu ge'u .e lo ni le linji cu gapru
    bars*: seq[Bar]  ## ro linji ta'i lo porsi poi le mamta cu lidne le panzi ku'o
    rows*: int  ## lo klani be lo pagbu be lo ni gapru be'o poi le linji cu nitcu ke'a

  Raw = object  ## pa linji poi na ca'o se cmene
    family: string
    rule: string
    number: int
    chain: seq[string]
    kids: seq[int]
    parent: int
    first: int
    last: int
    has_nu: bool  ## pa genvla be `NU` cu zvati le linji
    has_fa: bool  ## pa genvla be `FA` cu zvati le linji
    is_stop: bool
      ## le linji cu du pa srejge poi le gerna cu sisti bu'u ke'a to `readGrammarMarked` toi
    category: Option[Category]


func family(rule: string): string =
  ## le ckini be pa javni to mu'u `sumti-6` ja'i `sumti` toi
  var cut = rule.len
  while cut > 0 and rule[cut - 1] in {'0' .. '9'}: dec cut
  if cut < rule.len and cut > 0 and rule[cut - 1] == '-': rule[0 ..< cut - 1] else: rule


func isSelmaho(terminal: Terminal, selmaho: Selmaho): bool = terminal == selmaho.toTerminal


func walk(raws: var seq[Raw], reading: ReadingMarked, node: Node, family_parent: string,
    parent: int, is_split_parent: bool): (int, int) =
  ## jmina lo linji pe `node` ge'u .e lo linji pe ro jgena poi `node` vasru ke'a
  ##   .i jarco le stuna'u pe le pamoi valsi .e le romoi valsi pe `node`
  if node.is_terminal:
    let unit = reading.units[node.at]
    if parent >= 0 and unit.is_read:
      if unit.terminal.isSelmaho(Selmaho.Nu): raws[parent].has_nu = true
      if unit.terminal.isSelmaho(Selmaho.Fa): raws[parent].has_fa = true
    return (unit.words[0], unit.words[^1])
  # lo srejge cu ckini no javni gi'e se cmene no da
  let here = if node.stop.isSome: "" else: node.rule.family
  var same = 0
  for child in node.children:
    if not child.is_terminal and child.rule.family == here: inc same
  let is_split = same >= 2
  var branch = parent
  if parent < 0 or here != family_parent or is_split_parent or is_split:
    raws.add Raw(family: here, rule: node.rule, number: node.number, chain: @[node.rule],
        parent: parent, is_stop: node.stop.isSome)
    branch = raws.high
    if parent >= 0: raws[parent].kids.add branch
  else:
    raws[branch].chain.add node.rule
  var (first, last) = (int.high, -1)
  for child in node.children:
    let (a, b) = raws.walk(reading, child, here, branch, is_split)
    first = min(first, a)
    last = max(last, b)
  if branch != parent:
    raws[branch].first = first
    raws[branch].last = last
  (first, last)


func folded(reading: ReadingMarked): seq[Raw] =
  ## gunma ro porsi be lo jgena be pa ckini ta'i pa linji
  discard result.walk(reading, reading.tree, "", -1, false)


func named(raws: var seq[Raw]) =
  ## cmene ro linji ja'i le ckini .e lo genvla poi zvati ke'a
  for k in 0 ..< raws.len:
    template raw: untyped = raws[k]
    var kids_selbri, kids_unit, kids_sumti, kids_tag = 0
    for kid in raw.kids:
      case raws[kid].family
      of "selbri": inc kids_selbri
      of "tanru-unit": inc kids_unit
      of "sumti": inc kids_sumti
      of "tag": inc kids_tag
      else: discard
    if raw.is_stop:
      raw.category = none(Category)
      continue
    raw.category = case raw.family
      of "sentence": some(Category.Bridi)
      of "bridi-tail": some(Category.Tail)
      of "sumti": some(Category.Sumti)
      of "selbri":
        some(if kids_selbri + kids_unit >= 2: Category.Tanru else: Category.Selbri)
      of "tanru-unit":
        if raw.has_nu: some(Category.Abstraction) else: none(Category)
      of "relative-clause": some(Category.Clause)
      of "linkargs": some(Category.Linked)
      of "term":
        if kids_sumti > 0 and (raw.has_fa or kids_tag > 0): some(Category.Tagged)
        else: none(Category)
      of "tag": some(Category.Tag)
      of "quantifier", "number", "mex": some(Category.Number)
      of "free": some(Category.Free)
      else: none(Category)
  # lo pagbu be lo tanru .e lo tcita pe lo sumti poi tcita
  for k in 0 ..< raws.len:
    let parent = raws[k].parent
    if parent < 0: continue
    let above = raws[parent].category
    if raws[k].family in ["selbri", "tanru-unit"] and above == some(Category.Tanru) and
        raws[k].category != some(Category.Abstraction):
      raws[k].category = some(
          if raws[k].category == some(Category.Tanru): Category.Tanru else: Category.Unit)
    if raws[k].family == "tag" and above == some(Category.Tagged):
      raws[k].category = none(Category)
    if raws[k].category == some(Category.Number) and above == some(Category.Number):
      raws[k].category = none(Category)


func isSame(above, below: Category): bool =
  ## pa linji cu gunma le mamta va'o lo nu le re linji cu vasru lo mintu valsi
  above == below or (above == Category.Selbri and below == Category.Tanru) or
      (above == Category.Unit and below == Category.Unit)


func project(shown: var seq[Bar], raws: seq[Raw], k, parent: int) =
  ## jmina pa linji poi se cmene ku'o gi'a gunma ri le mamta ja'i `isSame`
  ##   .i ba bo jmina ro linji poi ri vasru ke'a
  var here = parent
  let raw = raws[k]
  if raw.category.isSome:
    let category = raw.category.get
    if parent >= 0 and shown[parent].first == raw.first and shown[parent].last == raw.last and
        shown[parent].category.isSame(category):
      if shown[parent].category == Category.Selbri: shown[parent].category = category
      shown[parent].chain.add raw.chain
    else:
      shown.add Bar(category: category, rule: raw.rule, number: raw.number, chain: raw.chain,
          first: raw.first, last: raw.last, parent: parent)
      here = shown.high
  for kid in raw.kids: shown.project(raws, kid, here)


func toLayers*(reading: ReadingMarked): Layers =
  ## lo linji be lo se tcidu
  ##   .i lo mamta cu lidne lo panzi ne'i `bars`
  var raws = reading.folded
  raws.named
  var shown: seq[Bar]
  for k in 0 ..< raws.len:
    if raws[k].parent < 0: shown.project(raws, k, -1)
  # lo romoi pagbu be lo bridi cu se vimcu
  var index = newSeq[int](shown.len)
  for k in 0 ..< shown.len:
    var parent = shown[k].parent
    while parent >= 0 and shown[parent].category == Category.Tail: parent = shown[parent].parent
    if shown[k].category == Category.Tail:
      index[k] = -1
      continue
    var bar = shown[k]
    bar.parent = if parent >= 0: index[parent] else: -1
    bar.depth = if bar.parent >= 0: result.bars[bar.parent].depth + 1 else: 0
    index[k] = result.bars.len
    result.bars.add bar
  for k in countdown(result.bars.high, 0):
    let parent = result.bars[k].parent
    if parent >= 0: result.bars[parent].height = max(result.bars[parent].height,
        result.bars[k].height + 1)
  for bar in result.bars: result.rows = max(result.rows, bar.height + 1)


func toGroup*(selmaho: Selmaho): Group =
  ## lo girzu be pa selma'o to `CLL 20` toi
  case selmaho
  of Selmaho.Goha, Selmaho.Se, Selmaho.Jai, Selmaho.Nuha, Selmaho.Cei, Selmaho.Me, Selmaho.Co:
    Group.Predicate
  of Selmaho.Koha, Selmaho.Le, Selmaho.La, Selmaho.Lahe, Selmaho.Li, Selmaho.Lu, Selmaho.Zo,
      Selmaho.Zoi, Selmaho.Lohu:
    Group.Sumti
  of Selmaho.Pa, Selmaho.By, Selmaho.Moi, Selmaho.Mai, Selmaho.Vuhu, Selmaho.Maho, Selmaho.Vei,
      Selmaho.Nihe, Selmaho.Mohe, Selmaho.Tei, Selmaho.Bu, Selmaho.Lau, Selmaho.Xi, Selmaho.Johi,
      Selmaho.Peho, Selmaho.Fuha, Selmaho.Nahu, Selmaho.Bihe:
    Group.Number
  of Selmaho.Fa, Selmaho.Bai, Selmaho.Pu, Selmaho.Zi, Selmaho.Va, Selmaho.Veha, Selmaho.Viha,
      Selmaho.Faha, Selmaho.Mohi, Selmaho.Zeha, Selmaho.Zaho, Selmaho.Tahe, Selmaho.Roi,
      Selmaho.Caha, Selmaho.Ki, Selmaho.Cuhe, Selmaho.Fiho, Selmaho.Fehe, Selmaho.Na,
      Selmaho.Nahe, Selmaho.Nai:
    Group.Tag
  of Selmaho.A, Selmaho.Ja, Selmaho.Joi, Selmaho.Ga, Selmaho.Gi, Selmaho.Giha, Selmaho.Guha,
      Selmaho.Bihi, Selmaho.Bo, Selmaho.Ke, Selmaho.Cehe, Selmaho.Pehe, Selmaho.Noi, Selmaho.Goi,
      Selmaho.Nu, Selmaho.Be, Selmaho.Bei, Selmaho.Soi, Selmaho.Nuhi, Selmaho.Vuho, Selmaho.Zihe,
      Selmaho.Gaho:
    Group.Link
  of Selmaho.Ui, Selmaho.Cai, Selmaho.Y, Selmaho.Coi, Selmaho.Doi, Selmaho.Sei, Selmaho.To,
      Selmaho.Daho, Selmaho.Fuhe, Selmaho.Fuho, Selmaho.Si, Selmaho.Sa, Selmaho.Su, Selmaho.Bahe:
    Group.Free
  of Selmaho.Cu, Selmaho.I, Selmaho.Niho, Selmaho.Zohu, Selmaho.Ku, Selmaho.Kei, Selmaho.Vau,
      Selmaho.Kuho, Selmaho.Gehu, Selmaho.Beho, Selmaho.Lihu, Selmaho.Lehu, Selmaho.Toi,
      Selmaho.Sehu, Selmaho.Tehu, Selmaho.Boi, Selmaho.Loho, Selmaho.Luhu, Selmaho.Mehu,
      Selmaho.Nuhu, Selmaho.Kuhe, Selmaho.Veho, Selmaho.Fehu, Selmaho.Dohu, Selmaho.Tuhe,
      Selmaho.Tuhu, Selmaho.Kehe, Selmaho.Faho, Selmaho.Zei, Selmaho.Raho, Selmaho.Foi:
    Group.Structure


func toGroup*(reading: Reading): Group =
  ## lo girzu be pa valsi
  ##   .i lo brivla cu cmima `Group.Predicate`
  ##   .i lo cmene cu cmima `Group.Sumti`
  ##   .i lo cmavo poi no selma'o cu cmima `Group.Structure`
  if not reading.is_word: return Group.Refused
  if reading.selmaho.isSome: return reading.selmaho.get.toGroup
  case reading.kind
  of Kind.Cmene: Group.Sumti
  of Kind.Cmavo: Group.Structure
  of Kind.Gismu, Kind.Lujvo, Kind.Fuhivla: Group.Predicate


func toGloss*(reading: Reading): string =
  ## le cmene be le selma'o be pa valsi to `BRIVLA` .a `CMENE` va'o lo brivla .a lo cmene toi
  ##   .i lo kunti lerpoi va'o lo nu le porsi be lo valsi cu to'e curmi le valsi
  if not reading.is_word: return ""
  if reading.selmaho.isSome: return $reading.selmaho.get
  case reading.kind
  of Kind.Cmene: "CMENE"
  of Kind.Cmavo: ""
  of Kind.Gismu, Kind.Lujvo, Kind.Fuhivla: "BRIVLA"
