## Name each rule knoller fixes or reports, so report carries its rule rather than wording.
##   Name is enum's string, as reports name rule (`expression spacing`); id is its slug, i.e.
##     letters and digits in lowercase, each other run one `-` (`expression-spacing`), stable
##     for tool reading output.
##   Article citing each rule is caller's: `curator/audit` holds `CITATIONS`, indexed by
##     `Rule`, so rule without citation fails to compile there.
##   Rule with no fixer names check alone: `LineEnding`, `Tab`, `LineWidth`, `NotOverBinary`,
##     `Fence` for fence fix cannot read, and `FenceHeld` for lines fence keeps as written, which
##     run reports as warning.
##   List holds rules of style source can break, alone. Fixers that do not settle are fault of
##     tool, so their fix carries message of its own (`Fix.unsettled`), and no article cites it.

{.experimental: "strictFuncs".}

import std/strutils


type Rule* {.pure.} = enum  ## Define one rule knoller fixes or reports, in order chain runs.
  Conversion = "type conversion"
    ## Type conversion is prefix call; semantic pass settles it before chain runs.
  UsedMarker = "marker used"
    ## Private symbol sibling reaches carries `{.used.}` and comment naming sibling, and
    ##   `{.all.}` reaches private symbol; semantic pass settles both before chain runs.
  PureFunc = "func pure"
    ## Routine with no effect beyond its parameters is `func`; compiler settles it before chain
    ##   runs.
  WhitespaceTrailing = "trailing whitespace"  ## Line ends in space, tab or CR.
  FileEnding = "file ending"  ## File ends in exactly one newline, so empty file breaks it.
  LineEnding = "line ending"  ## Line holds no CR, so each line ends in LF alone.
  TabInString = "tab in string"  ## Tab inside one-line plain string is written `\t`.
  Tab = "tab"  ## Line holds no tab.
  LineWidth = "line width"  ## Line holds at most `LINE_MAX` runes, where break can fix it.
  CommentTrailing = "trailing comment"  ## Two spaces stand before trailing comment's marker.
  SpacingBanner = "banner spacing"  ## Blank lines beside banner follow its tier.
  BlockEntry = "entry block"  ## Entry block holds no binding; body moves into `proc main`.
  Abbreviation = "abbreviation"  ## Name coins no abbreviation; its full word stands.
  VerbAction = "action verb"  ## Action is imperative verb, and property is bare noun.
  NameBoolean = "boolean name"  ## Boolean opens `is_` or its siblings; predicate opens `is`.
  TableLookup = "lookup table"  ## Lookup table reads `lut_<value>_by_<key>`.
  CaseName = "name case"  ## Case of name follows its kind.
  CaseMember = "member case"  ## Member of enum is `PascalCase`, as its type is.
  LetterPlaceholder = "placeholder letter"  ## Placeholder of generic is one capital letter.
  Notation = "notation"  ## Notation of source holds over case only for immutable global.
  WordGlobal = "global word"  ## Global shares no word with type.
  HeadRepresentation = "representation head"
    ## Name holding value in another representation leads with that value.
  CutName = "name cut"  ## Name opens with its head where words decide order of cut.
  SuffixRoutine = "routine suffix"
    ## Routine closes with `Of` only where its name spells generic type.
  SuffixGeneric = "generic suffix"
    ## Type closes with `Of` only where alias of its instance takes its bare name.
  NameCollection = "collection name"  ## Collection type takes plural of its member.
  AliasLandmark = "landmark alias"  ## Landmark index stands as alias its type declares.
  ArticleInComment = "article in comment"  ## Comment drops its articles.
  FormComment = "comment form"
    ## Claim of comment opens with capital and closes with period; each name stands in backticks.
  OutlineDoc = "doc outline"  ## Nuance stands two spaces past where parent's text starts.
  SummaryDoc = "doc summary"  ## Doc holds one summary line, whose sentence ends in period.
  ValueMessage = "message value"  ## Message echoes its value in backticks.
  BracesInterpolation = "interpolation braces"
    ## Interpolated string takes each value in braces, and joins none to it by `&`.
  EchoMessage = "message echo"
    ## Message echoes each value in backticks, before `got` and with none, and states claim first.
  AndWithOr = "and with or"  ## Condition mixing `and` with `or` parenthesises each `and`.
  NotOverBinary = "not over binary"  ## `not` over binary expression takes parentheses.
  ParenthesesNeedless = "needless parentheses"  ## Parentheses parser groups anyway go.
  SubjectTarget = "to<Target> subject first"  ## `to<Target>` call takes its subject first.
  PrefixConversion = "conversion prefix"
    ## Conversion of compound argument is prefix call, and constructor takes one call form.
  CallGeneration = "generation call"  ## Call of `define…` or `emit…` routine is prefix call.
  CommandDotted = "dotted command"  ## Dotted call statement of one call argument drops `(`.
  ReturnResult = "return result"  ## Routine never ends on `return result`.
  ImportBracket = "bracket import"  ## Bracket import is alphabetised.
  RankImport = "import rank"  ## Standard library, then packages, then local modules.
  BracketsImport = "import brackets"  ## Adjacent imports of one directory share one bracket.
  BracketModule = "module bracket"  ## Bracket of one module drops its bracket.
  BindingsSingle = "single bindings"  ## Consecutive single bindings share one keyword.
  StrictFuncs = "strictFuncs"  ## Module carries `strictFuncs` before its imports.
  ImportProfiler = "profiler import"  ## Entry module imports profiler on two lines.
  KeysStub = "stub keys"  ## Test stub leaves out `-r`, `batchable` and `joinable`.
  ConsumerUsed = "used consumer"  ## `{.used.}` carries comment naming its consumer.
  PushForeign = "push foreign"  ## `{.push.}` stands only over foreign bindings `{.pop.}` closes.
  FamilyCompileTime = "compile-time family"
    ## Routine compile time alone runs carries `compileTime`, as its family does, and no runtime
    ##   pragma.
  StaticWhen = "when static"  ## Branch on what build fixes is `when`, never `if`.
  SeedRandom = "random seed"  ## Suite importing `std/random` seeds it.
  HeaderStub = "stub header"  ## Test stub carries testament header.
  OutputDebug = "debug output"  ## Test leaves no unlabelled `echo`; other debug output warns.
  ReasonSkip = "skip reason"  ## Skip gives reason, gap skips, and no test leaves run.
  WaitFixed = "fixed wait"  ## Drive code waits on condition or clock, never span of real time.
  ListUnordered = "unordered list"  ## List language leaves unordered is alphabetised.
  BlockConfiguration = "configuration block"
    ## Adjacent blocks of one configuration share one, and default configuration comes first.
  LinesBlankTest = "test blank lines"  ## Blank lines beside suite and test follow tier.
  LinesBlankHelper = "helper blank lines"  ## Nested helper takes one blank line each side.
  LinesBlankDefinition = "definition blank lines"  ## Blank lines before definition follow its kind.
  PositionDoc = "doc position"  ## Doc stands where shape of declaration puts it.
  DefaultLiteral = "literal default"  ## Parameter with literal default states no type.
  SpacingExpression = "expression spacing"  ## Space stands only where expression rule puts it.
  SeparatorsParameter = "parameter separators"  ## Commas between parameters, `;` between groups.
  SeparatorsTuple = "tuple separators"  ## Tuple type takes commas between fields.
  WrappingSignature = "signature wrapping"  ## Signature wraps parameters only where it must.
  WrappingCall = "call wrapping"  ## Call takes one argument to line only where it must.
  WrappingOperator = "operator wrapping"  ## Line fitting nowhere breaks after binary operator.
  IndentContinuation = "continuation indent"  ## Line after operator takes four spaces more.
  DocMissing = "missing doc"
    ## Declaration takes doc, which reads `## TODO: Document.` while it waits for text.
  CommentAbove = "comment above"  ## Trailing comment that does not fit takes own line above.
  CommentStage = "stage comment"
    ## Paragraph that blank line opens takes comment naming its stage's purpose.
  Fence = "fence"  ## Fence closes inside bracket, string or comment it opens in.
  FenceHeld = "fence held"  ## Fence keeps its lines as written; run warns of each fence.


func slug*(name: string): string =
  ## Read slug of name: name in lowercase, each run of other characters one `-`, none at either
  ##   end; caller naming checks of its own, as koch, reads its ids so.
  for c in name.toLowerAscii:
    if c in {'a' .. 'z', '0' .. '9'}: result.add c
    elif result.len > 0 and result[^1] != '-': result.add '-'
  result.removeSuffix('-')


func id*(rule: Rule): string =
  ## Read stable id of rule: slug of its name.
  slug($rule)
