## Read terminals of lojban text by formal grammar of CLL 21.1, into tree of its named rules.
##
##   |----------------|------------------------------------------------------------|
##   | Code           | Meaning                                                    |
##   |----------------|------------------------------------------------------------|
##   | EBNF           | 88 formal rules of 21.1, as book writes them               |
##   | Terminal       | class of word grammar reads: selma'o, `BRIVLA` or `CMENE`  |
##   | Node           | named rule with what it holds, or one terminal             |
##   | ReadingGrammar | tree of text, or place and rule where grammar stops        |
##   | readGrammar    | read terminals by grammar of 21.1                          |
##   |----------------|------------------------------------------------------------|
##
##   Grammar is data: `EBNF` holds formal rules of 21.1 as book writes them, which Logical
##     Language Group dedicates to public domain; line opening with space goes on with rule
##     before it. Compile time turns each rule into productions, so no rule is written twice
##     (II.9); static checks hold 88 rules, each name defined, and each rewrite below applied once.
##   Notation follows 21.1: `|` choice, `[]` option, `&` and/or, `...` repetition, `()` group,
##     `#` free modifiers, as `[free ...]`, and `/X/` terminator that text may elide.
##     `...` binds closer than `&`, and `&` closer than `|`; juxtaposition closer than `&`, as
##       `ZEhA [PU [NAI]]` stands between two `&` in rule 1030.
##   Constructs that act on words before grammar, as rules 1100 and 1101 say, stand as one word:
##     `ZO any-word` as `ZO`, `LOhU any-word ... LEhU` as `LOhU`, `ZOI any-word anything any-word`
##     as `ZOI`, `any-word (ZEI any-word) ...` as `ZEI`, and `any-word BU` as `BU`; `prose.nim`
##     joins their words before grammar reads them (#814).
##   Parser is Earley's: grammar holds left recursion (`rp-expression` through `rp-operand`),
##     empty options, and ambiguity, which recursive descent reads not. Text reads where any
##     derivation holds it.
##     Tree is derivation closing fewest rules before each terminal, from first, so construct
##       text opens last takes each word it can: elided `ke'e` closes at end of selbri (5.5), and
##       clause after `be` attaches to last linked sumti (5.7). Tie goes to first choice of rule.
##       21.1 lets terminator be elided only where no ambiguity results, and orders no trees, so
##       choice follows examples of CLL; parser reading left to right that prefers to read
##       terminal over closing rule, as YACC does, chooses same tree.
##     Cost: Earley reads in cube of number of terminals at worst, and choice of tree compares
##       closures over each span it holds; sentences are short. Text has no bound on its length,
##       so parser holds `seq` and `Table` at runtime, as `stream` does (STYLE.md §4).
##   Refusal names place where every derivation stops, and named rule that stops innermost there.

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
  ## Formal rules of CLL 21.1, EBNF version, Final Baseline, as version 1.1 writes them.


type
  Terminal* = distinct int  ## Define class of word grammar reads: selma'o, `BRIVLA` or `CMENE`.

  Symbol = object  ## Define symbol of production: terminal, or nonterminal of grammar.
    is_terminal: bool
    code: int  ## Code of terminal, or index of nonterminal.

  Production = object  ## Define one way nonterminal derives sequence of symbols.
    head: int  ## Index of nonterminal it derives.
    body: seq[Symbol]  ## Symbols it derives, in order; empty for empty option.

  Grammar = object  ## Define grammar compiled from `EBNF`: nonterminals and their productions.
    names: seq[string]  ## Name of each nonterminal; helper takes name of rule holding it.
    numbers: seq[Option[int]]  ## Number of each named rule in 21.1; none for helper.
    productions: seq[Production]
    heads: seq[seq[int]]  ## Productions of each nonterminal, in order of its choices.
    nullable: seq[bool]  ## Nonterminal derives empty sequence.
    lengths: seq[int]  ## Least terminals each nonterminal derives.
    start: int  ## Index of `text`, rule 0.

  Builder = object  ## Define grammar under construction from tokens of one rule of `EBNF`.
    grammar: Grammar
    lut_index_by_name: Table[string, int]
    tokens: seq[string]
    at: int  ## Index of next token to read.
    rule: int  ## Index of rule being read, which names its helpers.
    frees: Option[int]  ## Helper `#` stands for, `[free ...]`, built once.

  Node* = object  ## Define node of tree: named rule of 21.1 with nodes it holds, or terminal.
    case is_terminal*: bool
    of true:
      at*: int  ## Index of terminal in terminals read.
    of false:
      rule*: string  ## Name of rule, as `sumti-6`.
      number*: int  ## Number of rule in 21.1, as 97.
      children*: seq[Node]

  ReadingGrammar* = object  ## Define outcome of reading terminals by grammar of 21.1.
    case is_read*: bool
    of true:
      tree*: Node  ## Rule `text` and all it holds.
    of false:
      at*: int  ## Index of terminal where every derivation stops; count of them, where text ends.
      rule*: string  ## Named rule stopping innermost there, with its number, as `sumti-6 97`.

  Item = tuple[production, dot, origin: int]  ## Define Earley item: production, dot, start set.


const
  TERMINAL_BRIVLA* = Terminal(ord(Selmaho.high) + 1)  ## Brivla: gismu, lujvo or fu'ivla.
  TERMINAL_CMENE* = Terminal(ord(Selmaho.high) + 2)  ## Cmene.
  REWRITES = [
    ("ZO any-word #", "ZO #"), ("LOhU any-word ... LEhU #", "LOhU #"),
    ("ZOI any-word anything any-word #", "ZOI #"), ("any-word (ZEI any-word) ...", "ZEI"),
    ("any-word BU", "BU"),
  ]
    ## Constructs grammar reads as one word, which `prose.nim` joins first (rules 1100, 1101).
  COUNT_RULES = 88  ## Formal rules 21.1 gives, rules 1100 and 1101 aside.
  DELIMITERS = {'[', ']', '(', ')', '|', '&', '#', '/'}  ## Marks of notation, `...` aside.


func `==`*(a, b: Terminal): bool {.borrow.}
  ## Compare terminals by code.

func toTerminal*(selmaho: Selmaho): Terminal = Terminal(ord(selmaho))
  ## Hold selma'o as terminal of grammar.


func toTerminal*(reading: Reading): Option[Terminal] =
  ## Hold word as terminal of grammar: cmavo by its selma'o, cmene as `CMENE`, and gismu, lujvo
  ##   and fu'ivla as `BRIVLA` (21.1); none for refusal, and for cmavo no list gives selma'o.
  if not reading.is_word: return none(Terminal)
  case reading.kind
  of Kind.Cmavo:
    if reading.selmaho.isSome: some(reading.selmaho.get.toTerminal) else: none(Terminal)
  of Kind.Cmene: some(TERMINAL_CMENE)
  of Kind.Gismu, Kind.Lujvo, Kind.Fuhivla: some(TERMINAL_BRIVLA)


func `$`*(terminal: Terminal): string =
  ## Spell terminal as 21.1 does: selma'o by its name, else `BRIVLA` or `CMENE`.
  if terminal == TERMINAL_BRIVLA: "BRIVLA"
  elif terminal == TERMINAL_CMENE: "CMENE"
  else: $Selmaho(int(terminal))



#[ Compiling ]#

func toRules(text: string): seq[string] =
  ## Join each rule of text with lines going on with it, and apply each rewrite once.
  for line in text.splitLines:
    if line.len == 0: continue
    if line[0] == ' ': result[^1].add " " & line.strip
    else: result.add line
  var joined = result.join("\n")
  for (before, after) in REWRITES:
    doAssert joined.count(before) == 1, "Rewrite should apply once; got `" & before & "`."
    joined = joined.replace(before, after)
  joined.split("\n")


func toTokens(text: string): seq[string] =
  ## Split expression of rule into names, marks of notation, and `...`.
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
  ## Find nonterminal named `name`, adding it on first use.
  if name notin builder.lut_index_by_name:
    builder.lut_index_by_name[name] = builder.grammar.names.len
    builder.grammar.names.add name
    builder.grammar.numbers.add none(int)
    builder.grammar.heads.add newSeq[int]()
  builder.lut_index_by_name[name]


func addHelper(builder: var Builder): int =
  ## Add nonterminal standing for part of rule being read, named after that rule.
  let index = builder.grammar.names.len
  builder.grammar.names.add builder.grammar.names[builder.rule]
  builder.grammar.numbers.add none(int)
  builder.grammar.heads.add newSeq[int]()
  index


func addProduction(builder: var Builder, head: int, body: seq[Symbol]) =
  ## Add production deriving `body` from nonterminal `head`.
  builder.grammar.heads[head].add builder.grammar.productions.len
  builder.grammar.productions.add Production(head: head, body: body)


func toSymbol(builder: var Builder, name: string): Symbol =
  ## Read name of rule as nonterminal, and name in capitals as terminal (21.1).
  if name[0] in {'a' .. 'z'}: return Symbol(is_terminal: false, code: builder.index(name))
  if name == "BRIVLA": return Symbol(is_terminal: true, code: int(TERMINAL_BRIVLA))
  if name == "CMENE": return Symbol(is_terminal: true, code: int(TERMINAL_CMENE))
  let selmaho = name.toSelmaho
  doAssert selmaho.isSome, "Terminal of 21.1 should name selma'o; got `" & name & "`."
  Symbol(is_terminal: true, code: ord(selmaho.get))


func peek(builder: Builder): string =
  ## Name next token, or empty where rule ends.
  if builder.at < builder.tokens.len: builder.tokens[builder.at] else: ""


func parseAlternation(builder: var Builder): seq[seq[Symbol]]


func toHelper(builder: var Builder, bodies: seq[seq[Symbol]]): Symbol =
  ## Add helper deriving each of `bodies`, and stand for it.
  let helper = builder.addHelper
  for body in bodies: builder.addProduction(helper, body)
  Symbol(is_terminal: false, code: helper)


func parseItem(builder: var Builder): Symbol =
  ## Read one item: name, `[]` option, `()` group, `/X/` elidable terminator or `#`, each
  ##   repeated where `...` follows it.
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
    result = builder.toHelper(@[body, newSeq[Symbol]()])  # terminator elided or written
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
  ## Read items side by side, up to `|`, `&`, close of group or end of rule.
  while builder.peek notin ["", "|", "&", "]", ")"]: result.add builder.parseItem


func parseAndOr(builder: var Builder): seq[Symbol] =
  ## Read sequences joined by `&`: `A & B` is `A | B | A B` (21.1), folded from left.
  result = builder.parseSequence
  while builder.peek == "&":
    inc builder.at
    let right = builder.parseSequence
    result = @[builder.toHelper(@[result, right, result & right])]


func parseAlternation(builder: var Builder): seq[seq[Symbol]] =
  ## Read choices joined by `|`.
  result.add builder.parseAndOr
  while builder.peek == "|":
    inc builder.at
    result.add builder.parseAndOr


func constructGrammar(text: string): Grammar {.compileTime.} =
  ## Compile each rule of `EBNF` into productions, and find nonterminals deriving nothing.
  var builder: Builder
  let rules = text.toRules
  doAssert rules.len == COUNT_RULES, "21.1 should give " & $COUNT_RULES & " formal rules."

  # Read each rule: name, number, then expression.
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

  # Mark nonterminals deriving empty sequence, until none more is found.
  result.nullable = newSeq[bool](result.names.len)
  var is_changed = true
  while is_changed:
    is_changed = false
    for production in result.productions:
      if result.nullable[production.head]: continue
      if production.body.allIt(not it.is_terminal and result.nullable[it.code]):
        result.nullable[production.head] = true
        is_changed = true

  # Find least terminals each nonterminal derives, until none lowers; bound keeps sum finite.
  const BOUND_LENGTH = 1 shl 20
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

  # Hold every unit cycle self-loop, as `choose` needs: symbol derives nonterminal alone where
  #   each other symbol of its production may derive nothing.
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


const GRAMMAR_EBNF = constructGrammar(EBNF)  ## Grammar of 21.1, compiled once.



#[ Parsing ]#

func fillSets(terminals: openArray[Terminal]): seq[seq[Item]] =
  ## Fill Earley sets: set `i` holds items each derivation reaches after `i` terminals.
  ##   Nonterminal deriving nothing is passed when predicted, as Aycock and Horspool do.
  result = newSeq[seq[Item]](terminals.len + 1)
  var seen = newSeq[HashSet[Item]](terminals.len + 1)
  template add(i: int, item: Item) =
    if not seen[i].containsOrIncl(item): result[i].add item
  for p in GRAMMAR_EBNF.heads[GRAMMAR_EBNF.start]: add(0, (p, 0, 0))
  for i in 0 .. terminals.len:
    var k = 0
    while k < result[i].len:
      let
        item = result[i][k]
        body = GRAMMAR_EBNF.productions[item.production].body
      inc k

      # Complete: advance each item waiting for nonterminal this item derives.
      if item.dot == body.len:
        let head = GRAMMAR_EBNF.productions[item.production].head
        for j in 0 ..< result[item.origin].len:
          let
            waiting = result[item.origin][j]
            waiting_body = GRAMMAR_EBNF.productions[waiting.production].body
          if waiting.dot < waiting_body.len and not waiting_body[waiting.dot].is_terminal and
              waiting_body[waiting.dot].code == head:
            add(i, (waiting.production, waiting.dot + 1, waiting.origin))
        continue

      # Scan terminal, or predict nonterminal.
      let symbol = body[item.dot]
      if symbol.is_terminal:
        if i < terminals.len and int(terminals[i]) == symbol.code:
          add(i + 1, (item.production, item.dot + 1, item.origin))
        continue
      for p in GRAMMAR_EBNF.heads[symbol.code]: add(i, (p, 0, i))
      if GRAMMAR_EBNF.nullable[symbol.code]: add(i, (item.production, item.dot + 1, item.origin))


func ruleNamed(head: int): string =
  ## Name rule of nonterminal with its number, as `sumti-6 97`; helper takes its rule's.
  let name = GRAMMAR_EBNF.names[head]
  for i, other in GRAMMAR_EBNF.names:
    let number = GRAMMAR_EBNF.numbers[i]
    if other == name and number.isSome: return name & " " & $number.get
  name


func refusal(sets: openArray[seq[Item]]): ReadingGrammar =
  ## Refuse at last set any derivation reaches, naming rule of item there that waits, has read
  ##   terminal, and started latest; item started in that set has read nothing, and names no rule.
  var last = sets.high
  while sets[last].len == 0: dec last
  var best = none(Item)
  for item in sets[last]:
    let is_waiting = item.dot < GRAMMAR_EBNF.productions[item.production].body.len
    if is_waiting and item.origin < last and (best.isNone or item.origin >= best.get.origin):
      best = some(item)
  let head = if best.isSome: GRAMMAR_EBNF.productions[best.get.production].head
             else: GRAMMAR_EBNF.start
  ReadingGrammar(is_read: false, at: last, rule: head.ruleNamed)


type
  Completions = seq[Table[(int, int), seq[int]]]
    ## Define productions completing in each set, by nonterminal and start set.

  Choice = object  ## Define derivation of nonterminal over span that tree takes.
    closures: seq[int]
      ## Nonterminals of derivation closing at each place of span, from its start; parser reading
      ##   left to right reduces them there, before it reads terminal at that place.
    production: int
    bounds: seq[int]  ## Place where each symbol of body ends.

  Chart = object  ## Define completions of text, and choices found while tree is chosen.
    completions: Completions
    terminals: seq[Terminal]
    choices: Table[(int, int, int), Option[Choice]]  ## Choice by nonterminal, start and end.
    open: HashSet[(int, int, int)]  ## Spans being chosen, which unit cycle reaches again.


func toCompletions(sets: openArray[seq[Item]]): Completions =
  ## Index each completed item by set it ends in, nonterminal, and set it starts in.
  result = newSeq[Table[(int, int), seq[int]]](sets.len)
  for i, items in sets:
    for item in items:
      let production = GRAMMAR_EBNF.productions[item.production]
      if item.dot != production.body.len: continue
      result[i].mgetOrPut((production.head, item.origin), @[]).add item.production
    for key in result[i].keys.toSeq: result[i][key].sort


func isFewer(a, b: seq[int]): bool =
  ## Test closures `a` close fewer nonterminals than `b` at first place where they differ.
  for i in 0 ..< min(a.len, b.len):
    if a[i] != b[i]: return a[i] < b[i]
  false


func offer(partials: var seq[Option[Choice]], i: int, candidate: Choice) =
  ## Keep candidate at place `i` where it closes fewer nonterminals than one kept; tie keeps first.
  if partials[i].isNone or candidate.closures.isFewer(partials[i].get.closures):
    partials[i] = some(candidate)


func choose(chart: var Chart, head, start, finish: int): Option[Choice] =
  ## Choose derivation of terminals `start ..< finish` from `head` that closes fewest nonterminals
  ##   at each place, from first; tie goes to first production, then to longer symbol.
  ##   Choice is kept once found. No symbol tries more terminals than symbols after it leave, so
  ##     child spans all of span only where each other symbol may derive nothing: unit cycle,
  ##     which is self-loop (`constructGrammar`). Unit cycle closes more and is never chosen, so
  ##     no choice kept depends on span still open.
  let key = (head, start, finish)
  if key in chart.choices: return chart.choices[key]
  if chart.open.containsOrIncl(key): return none(Choice)
  defer: chart.open.excl(key)
  let span = finish - start
  var best = none(Choice)
  for p in GRAMMAR_EBNF.heads[head]:
    let body = GRAMMAR_EBNF.productions[p].body
    if span == 0 and body.anyIt(it.is_terminal or not GRAMMAR_EBNF.nullable[it.code]): continue
    if span > 0 and p notin chart.completions[finish].getOrDefault((head, start)): continue

    # Match body left to right, keeping at each place partial that closes fewest there; each
    #   symbol leaves terminals enough for symbols after it.
    var
      rests = newSeq[int](body.len + 1)  # least terminals symbols from each on derive
      partials = newSeq[Option[Choice]](span + 1)
    for k in countdown(body.high, 0):
      let length = (if body[k].is_terminal: 1 else: GRAMMAR_EBNF.lengths[body[k].code])
      rests[k] = rests[k + 1] + length
    partials[0] = some(Choice(closures: @[0], production: p))
    for k, symbol in body:
      var nexts = newSeq[Option[Choice]](span + 1)
      for m in start .. finish:
        let partial = partials[m - start]
        if partial.isNone: continue
        if symbol.is_terminal:
          if m + 1 + rests[k + 1] <= finish and int(chart.terminals[m]) == symbol.code:
            var next = partial.get
            next.closures.add 0
            next.bounds.add m + 1
            nexts.offer(m + 1 - start, next)
          continue
        for bound in countdown(finish - rests[k + 1], m):
          let is_derived =
            (bound == m and GRAMMAR_EBNF.nullable[symbol.code]) or
            (symbol.code, m) in chart.completions[bound]
          if not is_derived: continue
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
    inc whole.closures[^1]  # head closes at its end
    if best.isNone or whole.closures.isFewer(best.get.closures): best = some(whole)
  chart.choices[key] = best
  best


func toNodes(chart: Chart, head, start, finish: int): seq[Node] =
  ## Build nodes of choice of `head` over span: named rule makes one node, and helper gives its
  ##   nodes to rule holding it.
  let
    choice = chart.choices[(head, start, finish)].get
    body = GRAMMAR_EBNF.productions[choice.production].body
  var
    children: seq[Node]
    at = start
  for k, symbol in body:
    if symbol.is_terminal: children.add Node(is_terminal: true, at: at)
    else: children.add chart.toNodes(symbol.code, at, choice.bounds[k])
    at = choice.bounds[k]
  if GRAMMAR_EBNF.numbers[head].isNone: return children
  @[Node(
    is_terminal: false, rule: GRAMMAR_EBNF.names[head], number: GRAMMAR_EBNF.numbers[head].get,
    children: children,
  )]


func readGrammar*(terminals: openArray[Terminal]): ReadingGrammar =
  ## Read terminals of text by grammar of 21.1, into tree of its named rules; refuse at place
  ##   where every derivation stops.
  let sets = terminals.fillSets
  var is_whole = false
  for item in sets[^1]:
    let
      production = GRAMMAR_EBNF.productions[item.production]
      is_text = production.head == GRAMMAR_EBNF.start and item.origin == 0
    if is_text and item.dot == production.body.len: is_whole = true
  if not is_whole: return sets.refusal
  var chart = Chart(completions: sets.toCompletions, terminals: @terminals)
  doAssert chart.choose(GRAMMAR_EBNF.start, 0, terminals.len).isSome,
      "Text grammar reads should derive tree."
  ReadingGrammar(is_read: true, tree: chart.toNodes(GRAMMAR_EBNF.start, 0, terminals.len)[0])
