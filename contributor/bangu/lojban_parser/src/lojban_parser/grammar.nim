## Read terminals of lojban text by formal grammar of CLL 21.1, into tree of its named rules.
##
##   |--------------------|-----------------------------------------------------------|
##   | Code               | Meaning                                                   |
##   |--------------------|-----------------------------------------------------------|
##   | EBNF               | 88 formal rules of 21.1, as book writes them              |
##   | Terminal           | class of word grammar reads: selma'o, `BRIVLA` or `CMENE` |
##   | Node               | named rule with what it holds, or one terminal            |
##   | Stop               | place grammar stops at, and terminals it would read there |
##   | ReadingGrammar     | tree of text, or place and rule where grammar stops       |
##   | readGrammar        | read terminals by grammar of 21.1                         |
##   | readGrammarMarked  | read terminals into tree that marks where grammar stops   |
##   | LUT_CHAIN_BY_ENDS  | rules between two rules, each node holding next alone     |
##   | LUT_NUMBER_BY_RULE | number of each named rule of 21.1, by its name            |
##   |--------------------|-----------------------------------------------------------|
##
##   Grammar is data: `EBNF` holds formal rules of 21.1 as book writes them, which Logical
##     Language Group dedicates to public domain; line opening with space goes on with rule
##     before it. Compile time turns each rule into productions, so no rule is written twice
##     (II.9); static checks hold 88 rules, each name defined, and each rewrite and grouping below
##     applied once.
##   Notation follows 21.1: `|` choice, `[]` option, `&` and/or, `...` repetition, `()` group,
##     `#` free modifiers, as `[free ...]`, and `/X/` terminator that text may elide.
##     `...` binds closer than `&`, and `&` closer than `|`; juxtaposition closer than `&`, as
##       `ZEhA [PU [NAI]]` stands between two `&` in rule 1030.
##     21.1 leaves order of juxtaposition and `&` unstated. Final baseline YACC grammar, whose
##       numbers 21.1 cross-references, takes other order in rule 972 alone: `&` of tense and
##       CAhA stands inside `[NAhE]` and `[KI]`, so `GROUPINGS` writes its parentheses.
##       Cost: `EBNF` stays text of book, and grouping is one line beside it.
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
##       closures over each span it holds. So text reads part by part, cut at `ni'o` and `.i`
##       (`readGrammar`), and time grows with length of text (#849), save part that holds `lu`
##       or `to` left open, which runs to end and reads in one pass. Text has no bound on its
##       length, so parser holds `seq` and `Table` at runtime, as `stream` does (STYLE.md §4).
##   Refusal names place where every derivation stops, and named rule that stops innermost there.
##   Chain is run of named rules in tree, each holding next rule alone, as `sumti` holds `sumti-1`
##     where text gives no relative clause; layers of 21.1 make most of each tree such runs.
##     Compile time finds each chain 21.1 allows, and holds that two ends give one chain, so tree
##     writes chain by its ends alone and reads back whole (`nif.nim`).
##   Marks: where grammar refuses text, `readGrammarMarked` still gives tree, so other program
##     mends text by its tree; this parser decides no mend (ruling `D1 a` of #859).
##     Error node takes name and number of rule stopping innermost, and `Stop`: place where
##       every derivation stops, and terminals some derivation reads there.
##     Text cut into parts, as passes cut it, reads part by part: error node of text holds tree
##       of each part that reads alone, and error node of each that does not. So reading starts
##       again at each `ni'o`, and at each `.i` that joins nothing, as Architect ruled (#859).
##     Error node of part holds largest branches that keep 21.1, and terminals between them:
##       cover leaves fewest terminals out, then takes fewest pieces (`islands`). Sets seeded
##       with each named rule at each set find each branch, wherever text broke rules before.
##     Cost: error node of whole text reads it in one pass, as refusal of `readGrammar` does, and
##       seeded sets of part refused hold each named rule at each set.

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

  Stop* = object  ## Define place where grammar stops in text, and terminals it would read there.
    at*: int  ## Index of terminal where every derivation stops; count of them, where text ends.
    expected*: seq[Terminal]  ## Terminals some derivation reads at `at`, in order of code.

  Node* = object  ## Define node of tree: named rule of 21.1 with nodes it holds, or terminal.
    case is_terminal*: bool
    of true:
      at*: int  ## Index of terminal in terminals read.
    of false:
      rule*: string  ## Name of rule, as `sumti-6`.
      number*: int  ## Number of rule in 21.1, as 97.
      children*: seq[Node]
      stop*: Option[Stop] = none(Stop)
        ## Place grammar stops at, where node marks error: rule is rule stopping innermost there,
        ##   and children are branches that keep 21.1, with terminals between them
        ##   (`readGrammarMarked`); none where node keeps 21.1.

  ReadingGrammar* = object  ## Define outcome of reading terminals by grammar of 21.1.
    case is_read*: bool
    of true:
      tree*: Node  ## Rule `text` and all it holds.
    of false:
      at*: int  ## Index of terminal where every derivation stops; count of them, where text ends.
      rule*: string  ## Named rule stopping innermost there, with its number, as `sumti-6 97`.
      head: int  ## Nonterminal of that rule, which error node `readGrammarMarked` gives takes.
      expected: seq[Terminal]  ## Terminals some derivation reads at `at`, in order of code.

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
  GROUPINGS = [
    (
      "[NAhE] (time [space] | space [time]) & CAhA [KI]",
      "[NAhE] ((time [space] | space [time]) & CAhA) [KI]",
    ),
  ]
    ## Groupings 21.1 leaves open, as final baseline YACC grammar `grammar.300` gives them: its
    ##   rule 972 takes NAhE before tense or CAhA alone (973, 978), and KI after either (977).
  COUNT_RULES = 88  ## Formal rules 21.1 gives, rules 1100 and 1101 aside.
  BOUND_LENGTH = 1 shl 20  ## Bound on least terminals of nonterminal, above any length found.
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
  ## Join each rule of text with lines going on with it, and apply each rewrite and grouping once.
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


func constructChains(grammar: Grammar): Table[(int, int), seq[tuple[rule: string, number: int]]]
    {.compileTime.} =
  ## Construct each chain of named rules, each node holding next alone, keyed by numbers of rule
  ##   opening it and rule closing it; assert each pair of ends gives one chain, holding no cycle.
  ##   Named rule holds rule alone where its production derives that rule and nothing else: each
  ##     other symbol is helper deriving no node, since named rule is node even where empty.
  let count = grammar.names.len
  func isHelper(grammar: Grammar, code: int): bool = grammar.numbers[code].isNone

  # Mark helpers deriving no node: nothing, through helpers alone.
  var nodeless = newSeq[bool](count)
  template isNodeless(symbol: Symbol): bool =
    ## Decide whether symbol derives no node: helper marked so far.
    not symbol.is_terminal and grammar.isHelper(symbol.code) and nodeless[symbol.code]
  var is_changed = true
  while is_changed:
    is_changed = false
    for production in grammar.productions:
      if not grammar.isHelper(production.head) or nodeless[production.head]: continue
      if production.body.allIt(it.isNodeless):
        nodeless[production.head] = true
        is_changed = true

  # Find named rules each nonterminal derives alone, until none more is found.
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

  # Walk each chain from each named rule, keyed by its two ends.
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
  ## Rules of each chain, each node holding next alone, by numbers of rule opening it and rule
  ##   closing it: from `terms` 80 to `sumti-6` 97, each rule of 21.1 between them, in order.


func constructNumbers(grammar: Grammar): Table[string, int] {.compileTime.} =
  ## Construct number of each named rule by its name; assert no two rules share name or number,
  ##   so name gives number, and number gives name.
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
  ## Number of each named rule of 21.1 by its name, as `sumti-6` 97: NIF writes name of rule
  ##   closing each chain alone, and reader takes its number here (ruling on #859, comment
  ##   6805527878).



#[ Parsing ]#

func fillSets(terminals: openArray[Terminal], is_everywhere = false): seq[seq[Item]] =
  ## Fill Earley sets: set `i` holds items each derivation reaches after `i` terminals.
  ##   Nonterminal deriving nothing is passed when predicted, as Aycock and Horspool do.
  ##   `is_everywhere` predicts each named rule at each set too, so completions hold each span
  ##     any named rule derives, wherever text breaks rules before it (`islands`).
  ##   Hot path, once for each text: set indexes its items by nonterminal each waits for, so
  ##     completion walks those alone, and predicts each nonterminal once. Per set, index and
  ##     marks hold one entry for each nonterminal; items grow with text, and each allocates.
  ##   Body of production is alias, never `let`, which copies its seq at each item (read in
  ##     emitted C); item, three integers, copies by value.

  template add(i: int, item: Item) =
    ## Add item to set `i` once, indexed by nonterminal it waits for.
    let added: Item = item
    if not seen[i].containsOrIncl(added):
      template bodyAdded: untyped = GRAMMAR_EBNF.productions[added.production].body
        ## Alias body of production added.
      if added.dot < bodyAdded.len and not bodyAdded[added.dot].is_terminal:
        waiting[i][bodyAdded[added.dot].code].add result[i].len
      result[i].add added

  result = newSeq[seq[Item]](terminals.len + 1)
  let count_nonterminals = GRAMMAR_EBNF.heads.len
  var
    seen = newSeq[HashSet[Item]](terminals.len + 1)
    waiting = newSeq[seq[seq[int]]](terminals.len + 1)  # index of items by nonterminal awaited
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
        ## Alias body of production of item.
      inc k

      # Complete: advance each item waiting for nonterminal this item derives; list can grow
      #   while walked, where item derives nothing, so walk goes by index.
      if item.dot == body.len:
        let head = GRAMMAR_EBNF.productions[item.production].head
        var j = 0
        while j < waiting[item.origin][head].len:
          let waiter = result[item.origin][waiting[item.origin][head][j]]
          add(i, (waiter.production, waiter.dot + 1, waiter.origin))
          inc j
        continue

      # Scan terminal, or predict nonterminal.
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
  ## Give name and number of rule of nonterminal, as `sumti-6` 97; helper takes its rule's.
  let name = GRAMMAR_EBNF.names[head]
  for i, other in GRAMMAR_EBNF.names:
    let number = GRAMMAR_EBNF.numbers[i]
    if other == name and number.isSome: return (name, number.get)
  doAssert false, "Helper should take name of rule holding it; got `" & name & "`."


func ruleNamed(head: int): string =
  ## Name rule of nonterminal with its number, as `sumti-6 97`; helper takes its rule's.
  let rule = head.toRule
  rule.name & " " & $rule.number


func refusal(sets: openArray[seq[Item]]): ReadingGrammar =
  ## Refuse at last set any derivation reaches, naming rule of item there that waits, has read
  ##   terminal, and started latest; item started in that set has read nothing, and names no rule.
  ##   Terminals items there wait for are those some derivation reads there.
  var last = sets.high
  while sets[last].len == 0: dec last
  var
    best = none(Item)
    expected: seq[Terminal]
  for item in sets[last]:
    template body: untyped = GRAMMAR_EBNF.productions[item.production].body
      ## Alias body of production of item, which `let` would copy.
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


func isDerived(chart: Chart, symbol: Symbol, start, finish: int): bool =
  ## Test chart derives terminals `start ..< finish` from `symbol`: terminal reads one that
  ##   matches it, and nonterminal completes over span, or derives nothing where span is empty.
  if symbol.is_terminal:
    return finish == start + 1 and int(chart.terminals[start]) == symbol.code
  (start == finish and GRAMMAR_EBNF.nullable[symbol.code]) or
    (symbol.code, start) in chart.completions[finish]


func choose(chart: var Chart, head, start, finish: int): Option[Choice] =
  ## Choose derivation of terminals `start ..< finish` from `head` that closes fewest nonterminals
  ##   at each place, from first; tie goes to first production, then to longer symbol.
  ##   Choice is kept once found. No symbol tries more terminals than symbols after it leave, so
  ##     child spans all of span only where each other symbol may derive nothing: unit cycle,
  ##     which is self-loop (`constructGrammar`). Unit cycle closes more and is never chosen, so
  ##     no choice kept depends on span still open.
  ##   Last symbol of body tries end of span alone, since no other bound reaches whole span;
  ##     every other bound cost time that grew with square of span, on long text.
  ##   Nonterminal before last symbol tries only bound that last symbol ends span from: partial
  ##     at other bound never reaches end. Each such dead child chose itself, and copied closures
  ##     as long as its span; where opener stayed open, that cost grew faster than text (#849).
  let key = (head, start, finish)
  if key in chart.choices: return chart.choices[key]
  if chart.open.containsOrIncl(key): return none(Choice)
  defer: chart.open.excl(key)
  let span = finish - start
  var best = none(Choice)
  for p in GRAMMAR_EBNF.heads[head]:
    template body: untyped = GRAMMAR_EBNF.productions[p].body
      ## Alias body of production `p`, which `let` would copy.
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
        template partial: untyped = partials[m - start]
          ## Alias partial choice ending at `m`, which `let` would copy.
        if partial.isNone: continue
        if symbol.is_terminal:
          if m + 1 + rests[k + 1] <= finish and int(chart.terminals[m]) == symbol.code:
            var next = partial.get
            next.closures.add 0
            next.bounds.add m + 1
            nexts.offer(m + 1 - start, next)
          continue
        let low = (if k == body.high: finish else: m)  # last symbol ends at end of span
        for bound in countdown(finish - rests[k + 1], low):
          if not chart.isDerived(symbol, m, bound): continue
          if k == body.high - 1 and not chart.isDerived(body[^1], bound, finish): continue  # dead
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


func addNodes(chart: Chart, head, start, finish: int, nodes: var seq[Node]) =
  ## Add nodes of choice of `head` over span to `nodes`: named rule adds one node holding its
  ##   children, and helper adds its own nodes in place, for rule holding it.
  ##   Named node takes its place before its children fill it, so build copies no subtree, on
  ##     JavaScript too, whose `add` copies each value; nor closures of choice. Copy at each level
  ##     cost time that grew with square of text, since rule 4 nests one level for each paragraph
  ##     (#849).
  let
    key = (head, start, finish)
    production = chart.choices[key].get.production
    bounds = chart.choices[key].get.bounds
  template addChildren(into: var seq[Node]) =
    ## Add node of each symbol of production to `into`, in order.
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
  ## Read terminals of text by grammar of 21.1 in one pass, into tree of its named rules; refuse
  ##   at place where every derivation stops.
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
  ReadingGrammar(is_read: true, tree: nodes.pop)  # rule 0 is named, so one node



#[ Passes ]#

const
  OPENERS* = [Selmaho.Tuhe, Selmaho.Lu, Selmaho.To]
    ## Selma'o opening text inside text: statement-3, sumti-6 and free (rules 14, 97, 32).
  CLOSERS* = [Selmaho.Tuhu, Selmaho.Lihu, Selmaho.Toi]  ## Terminator of each opener, in its order.
  JOINS = {Selmaho.Ja, Selmaho.Joi, Selmaho.Bihi, Selmaho.Gaho, Selmaho.Bo}
    ## Selma'o after `I`, past NA and SE, that joins statements: jek, joik or BO (rules 12, 13).
  TAGS = {
    Selmaho.Nahe, Selmaho.Se, Selmaho.Bai, Selmaho.Nai, Selmaho.Ki, Selmaho.Cuhe, Selmaho.Zi,
    Selmaho.Pu, Selmaho.Zeha, Selmaho.Va, Selmaho.Faha, Selmaho.Mohi, Selmaho.Veha, Selmaho.Viha,
    Selmaho.Fehe, Selmaho.Tahe, Selmaho.Roi, Selmaho.Zaho, Selmaho.Caha, Selmaho.Pa, Selmaho.Na,
    Selmaho.Ja, Selmaho.Joi,
  }
    ## Selma'o of tag before BO of statement-2 (rule 13, stag); run of them up to BO joins.
  RULE_TEXT_1 = ("text-1", 2)  ## Name and number of rule holding paragraphs of text.
  RULE_PARAGRAPHS = ("paragraphs", 4)
  RULE_PARAGRAPH = ("paragraph", 10)
  RULE_STATEMENT_3 = ("statement-3", 14)
  RULE_FREE = ("free", 32)


type Split = tuple[parts: seq[Slice[int]], inner: int]
  ## Define parts of text that each read alone, and start of text of `tu'e` left open, else end.


func isAmong(terminal: Terminal, selmaho: set[Selmaho]): bool =
  ## Test terminal is cmavo of one of `selmaho`.
  int(terminal) <= ord(Selmaho.high) and Selmaho(int(terminal)) in selmaho


func isRule(node: Node, rule: (string, int)): bool =
  ## Test node is named rule `rule`, by name and number.
  not node.is_terminal and node.rule == rule[0] and node.number == rule[1]


func isJoining(terminals: openArray[Terminal], at: int): bool =
  ## Test `I` at `at` joins statements: jek or joik after it, past NA and SE, or run of tag
  ##   ending at BO (rules 12, 13); such `I` holds no paragraph of its own.
  var k = at + 1
  while k < terminals.len and terminals[k].isAmong({Selmaho.Na, Selmaho.Se}): inc k
  if k < terminals.len and terminals[k].isAmong(JOINS): return true
  k = at + 1
  while k < terminals.len and terminals[k].isAmong(TAGS): inc k
  k > at + 1 and k < terminals.len and terminals[k] == Selmaho.Bo.toTerminal


func isCutAt*(terminals: openArray[Terminal], at: int, before: Option[Terminal]): bool =
  ## Test passes cut text before terminal `at`, where no opener is open: `NIhO` that follows none,
  ##   as `before` gives terminal before it, or `I` that joins nothing (`toParts`).
  let terminal = terminals[at]
  (terminal == Selmaho.Niho.toTerminal and before != some(Selmaho.Niho.toTerminal)) or
    (terminal == Selmaho.I.toTerminal and not terminals.isJoining(at))


func isTracked(
    opened: var seq[tuple[selmaho: Selmaho, at: int]], terminals: openArray[Terminal], i: int,
    ignored: openArray[int],
): bool =
  ## Apply terminal `i` to openers open, innermost last: opener opens, unless `ignored` holds it;
  ##   closer closes nearest opener of its kind, and each opener inside it. True for both.
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
  ## Give index of each opener of terminals `first ..< last` that no closer there closes, in
  ##   order: `tu'e`, `lu` or `to` that waits for its closer in live text.
  var opened: seq[tuple[selmaho: Selmaho, at: int]]
  for i in first ..< last: discard opened.isTracked(terminals, i, [])
  opened.mapIt(it.at)


func toParts(
    terminals: openArray[Terminal], first, last: int, ignored: openArray[int] = []
): Split =
  ## Split terminals `first ..< last` into parts that each read alone: cut before `NIhO` that
  ##   follows none, and before `I` that joins nothing, where no opener is open.
  ##   `inner` opens text of `tu'e` that no `tu'u` closes, which runs to `last`; else it is
  ##     `last`. Each cut stands where no opener is open, so before first opener left open: part
  ##     holding `lu` or `to` left open runs to `last`, and reads in one pass, since later word
  ##     decides where it closes.
  ##   Opener `ignored` holds reads as plain terminal: live text cuts after opener that waits
  ##     for its closer, so each sentence after it goes out at once (ruling on #859).
  var
    starts = @[first]
    opened: seq[tuple[selmaho: Selmaho, at: int]]  # each opener open, innermost last
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
  ## Move index of each terminal of tree, and each place grammar stops at, by `by`: part read
  ##   alone counts from its own start.
  if node.is_terminal: node.at += by
  else:
    if node.stop.isSome: node.stop.get.at += by
    for child in node.children.mitems: child.shift(by)


func readPart(terminals: openArray[Terminal], part: Slice[int]): Option[Node] =
  ## Read terminals of part alone, as text, into tree whose indexes count from start of text.
  var reading = terminals.toOpenArray(part.a, part.b).readWhole
  if not reading.is_read: return none(Node)
  var tree = move(reading.tree)
  tree.shift(part.a)
  some(tree)


func isGroup(nodes: openArray[Node], terminals: openArray[Terminal], head: Selmaho): bool =
  ## Test nodes are terminals of `head`, then free modifiers alone: `I #` of rule 10, or
  ##   `NIhO ... #` of rule 4. Jek, joik, tag or BO there means statements join instead.
  var k = 0
  while k < nodes.len and nodes[k].is_terminal and terminals[nodes[k].at] == head.toTerminal: inc k
  k > 0 and nodes.toOpenArray(k, nodes.high).allIt(it.isRule(RULE_FREE))


func graftInner(node: var Node, at: int, inner: var Node): bool =
  ## Put text-1 `inner` into statement-3 whose `tu'e` stands at `at`, down last child of each
  ##   node, where text alone read empty text-1 after that `tu'e`.
  if node.is_terminal: return false
  if node.isRule(RULE_STATEMENT_3) and node.children.anyIt(it.is_terminal and it.at == at):
    if not node.children[^1].isRule(RULE_TEXT_1) or node.children[^1].children.len > 0:
      return false
    node.children[^1] = move(inner)
    return true
  node.children.len > 0 and node.children[^1].graftInner(at, inner)


func toNode(rule: (string, int), children: sink seq[Node]): Node =
  ## Make node of named rule holding `children`.
  Node(is_terminal: false, rule: rule[0], number: rule[1], children: children)


func readParts(terminals: openArray[Terminal], first, last: int, trees: var seq[Node]): bool =
  ## Read each part of text of terminals `first ..< last` alone, as passes cut it, into `trees`,
  ##   then each part of text of `tu'e` left open; false where part refuses. Part holding `lu` or
  ##   `to` left open runs to `last`, as `toParts` cuts it.
  let split = terminals.toParts(first, last)
  for part in split.parts:
    let tree = terminals.readPart(part)
    if tree.isNone: return false
    trees.add tree.get  # copy, since `move` of `get` is no lvalue on JavaScript
  split.inner >= last or terminals.readParts(split.inner, last, trees)


func assemble(
    terminals: openArray[Terminal], first, last: int, parts: var seq[Node], at: var int
): Option[Node] =
  ## Build tree one pass gives text of terminals `first ..< last` around tree of each of its
  ##   parts, taken from `parts` at `at` on, in order `readParts` gives them: `text 0`,
  ##   `text-1 2`, `paragraphs 4` and `paragraph 10` (rules 0 to 10).
  ##   Part holds nodes of one rule each: tree of choice is fixed for span and rule, and closures
  ##     of rules around part fall at its ends alike. Law holds this against one pass.
  ##   None where rule of passes breaks; one pass then reads whole text.
  let split = terminals.toParts(first, last)
  if at + split.parts.len > parts.len: return none(Node)
  var trees: seq[Node]
  for _ in split.parts:
    trees.add move(parts[at])
    inc at

  # First part gives `text 0` and nodes of `text-1` before its paragraphs; each paragraph is
  #   group of `NIhO` before it, and nodes of `paragraph` (rules 2, 4).
  var
    text = move(trees[0])
    text_1 = text.children.pop  # rule 0 ends in text-1
    paragraphs: seq[tuple[group, nodes: seq[Node]]]
  if text_1.children.len > 0 and text_1.children[^1].isRule(RULE_PARAGRAPHS):
    var first_paragraphs = text_1.children.pop
    if first_paragraphs.children.len != 1: return none(Node)
    paragraphs.add (newSeq[Node](), move(first_paragraphs.children[0].children))
  for k in 1 ..< trees.len:
    if trees[k].children.len != 1 or not trees[k].children[0].isRule(RULE_TEXT_1):
      return none(Node)  # part opens with what only text opens with
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
          return none(Node)  # rule 2 opens with `I` or with `NIhO`, never both
        for node in part.children.mitems: text_1.children.add move(node)
        if has_paragraph: paragraphs.add (newSeq[Node](), move(nodes))
      else:
        for node in part.children.mitems: paragraphs[^1].nodes.add move(node)
        for node in nodes.mitems: paragraphs[^1].nodes.add move(node)
    elif head == Selmaho.Niho.toTerminal:
      if not part.children.isGroup(terminals, Selmaho.Niho): return none(Node)
      if paragraphs.len == 0:
        if text_1.children.len > 0: return none(Node)  # rule 2 opens with one group
        for node in part.children.mitems: text_1.children.add move(node)
        if has_paragraph: paragraphs.add (newSeq[Node](), move(nodes))
      else:
        if not has_paragraph: return none(Node)  # rule 4 holds paragraph after `NIhO`
        paragraphs.add (move(part.children), move(nodes))
    else:
      return none(Node)

  # Text of `tu'e` left open runs to end: build it from its parts too, and put it in place.
  if split.inner < last:
    var inner = terminals.assemble(split.inner, last, parts, at)
    if inner.isNone or paragraphs.len == 0: return none(Node)
    if inner.get.children.len != 1 or not inner.get.children[0].isRule(RULE_TEXT_1):
      return none(Node)  # text of `tu'e` is text-1, which opens with no prefix of text
    var inner_text_1 = move(inner.get.children[0])
    if paragraphs[^1].nodes.len == 0: return none(Node)
    if not paragraphs[^1].nodes[^1].graftInner(split.inner - 1, inner_text_1):
      return none(Node)

  # Nest paragraphs from last, each holding group of next and rest after it (rule 4).
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
  ## Read text of terminals `first ..< last` part by part, and build tree one pass gives around
  ##   their nodes (`assemble`); none where part refuses, or where rule of passes breaks: one
  ##   pass then reads whole text, and gives each refusal.
  var
    trees: seq[Node]
    at = 0
  if not terminals.readParts(first, last, trees): return none(Node)
  terminals.assemble(first, last, trees, at)


func assembleText*(terminals: openArray[Terminal], parts: openArray[Node]): Option[Node] =
  ## Build tree of text from tree of each of its parts, read alone, in order passes give them
  ##   (`readGrammarParts`); so parts lose nothing of tree `readGrammar` gives text they read.
  ##   Text of one part is that part; none where rule of passes breaks, and one pass alone reads
  ##     text.
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
  ## Read terminals of text by grammar of 21.1, into tree of its named rules; refuse at place
  ##   where every derivation stops.
  ##   Reads text part by part, so time grows with length of text alone (#849). One pass over
  ##     whole text reads where passes cannot, and gives each refusal.
  ##   Text of one part reads in one pass at once, as passes would only read it so and build
  ##     its tree again; where it refuses, passes would read it twice.
  let split = terminals.toParts(0, terminals.len)
  if split.parts.len > 1 or split.inner < terminals.len:
    let built = terminals.buildText(0, terminals.len)
    if built.isSome: return ReadingGrammar(is_read: true, tree: built.get)
  terminals.readWhole



#[ Marks ]#

func toError(reading: ReadingGrammar, children: sink seq[Node]): Node =
  ## Make error node of refusal, holding `children`: rule stopping innermost, and place grammar
  ##   stops at, with terminals some derivation reads there.
  let rule = reading.head.toRule
  Node(
    is_terminal: false, rule: rule.name, number: rule.number, children: children,
    stop: some(Stop(at: reading.at, expected: reading.expected)),
  )


func islands(terminals: openArray[Terminal], first, last: int): seq[Node] =
  ## Cover terminals `first ..< last` by branches that keep 21.1, and terminals between them:
  ##   fewest terminals between, then fewest pieces, and tie goes to longest piece first.
  ##   Branch is named rule of least number deriving its span: rule 0, `text`, where its words
  ##     read alone, so branch is tree they give alone. Rule of greatest number was rejected:
  ##     other derivation of span may hold it, as `mi klama` read as `sumti-tail` 111 with
  ##     possessor `mi` in place of `sentence` 40.
  let count = last - first
  if count == 0: return
  var chart = Chart(
    completions:
      terminals.toOpenArray(first, last - 1).fillSets(is_everywhere = true).toCompletions,
    terminals: terminals[first ..< last],
  )

  # Head of branch over each span, by start and end: named rule of least number there.
  var heads = newSeq[Table[int, int]](count)
  for finish in 1 .. count:
    for (head, start) in chart.completions[finish].keys:
      if start >= finish or GRAMMAR_EBNF.numbers[head].isNone: continue
      let is_outer = finish notin heads[start] or
        GRAMMAR_EBNF.numbers[head].get < GRAMMAR_EBNF.numbers[heads[start][finish]].get
      if is_outer: heads[start][finish] = head

  # Cover of terminals from each place to end, from last place back: terminals between,
  #   pieces, and end of first piece, with head of its branch; none for terminal alone.
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

  # Build each piece in order: branch with its tree, as part read alone would give it.
  var start = 0
  while start < count:
    let cover = covers[start]
    if cover.head.isNone:
      result.add Node(is_terminal: true, at: first + start)
    else:
      doAssert chart.choose(cover.head.get, start, cover.finish).isSome,
          "Span completions hold should derive tree."
      chart.addNodes(cover.head.get, start, cover.finish, result)  # named, so one node
      result[^1].shift(first)
    start = cover.finish


func markPart(terminals: openArray[Terminal], part: Slice[int]): Node =
  ## Read part alone, as text, into tree whose indexes count from start of text; where grammar
  ##   refuses it, into error node of part, holding branches that keep 21.1 (`islands`).
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
  ## Give pieces of text of terminals `first ..< last` as passes cut it (`toParts`): tree of
  ##   each part that reads alone, and error node of each that does not; then pieces of text of
  ##   `tu'e` left open. Part holding `lu` or `to` left open runs to `last`. Opener `ignored`
  ##   holds reads as plain terminal.
  let split = terminals.toParts(first, last, ignored)
  for part in split.parts: result.add terminals.markPart(part)
  if split.inner < last: result.add terminals.markText(split.inner, last, ignored)


func readGrammarParts*(
    terminals: openArray[Terminal], is_live = false
): tuple[parts: seq[Node], open: seq[int]] =
  ## Read terminals by grammar of 21.1 into node of each part, as passes cut them: tree of each
  ##   part that reads alone, error node of each that does not, then parts of text of `tu'e`
  ##   left open; `assembleText` builds tree of text from them, so they lose nothing of it.
  ##   Live text cuts after opener that waits for its closer, so each sentence after it reads
  ##     alone (`is_live`); `open` gives index of each such opener, which closer reads again.
  let open = (if is_live: terminals.unclosed(0, terminals.len) else: @[])
  (terminals.markText(0, terminals.len, open), open)


func readGrammarMarked*(terminals: openArray[Terminal]): Node =
  ## Read terminals by grammar of 21.1 into tree of its named rules, as `readGrammar` does; where
  ##   grammar refuses them, into error node of whole text, so tree marks each error (#859).
  ##   Error node of text cut into parts holds tree of each part that reads alone, and error
  ##     node of each that does not, so reading starts again at each part; text of one part
  ##     holds branches that keep 21.1, and terminals between them (`islands`).
  var reading = terminals.readGrammar
  if reading.is_read: return move(reading.tree)
  let
    split = terminals.toParts(0, terminals.len)
    is_parted = split.parts.len > 1 or split.inner < terminals.len
  reading.toError(
    if is_parted: terminals.markText(0, terminals.len) else: terminals.islands(0, terminals.len)
  )
