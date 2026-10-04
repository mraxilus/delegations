## Name each rule knoller fixes or reports, so report carries its rule rather than wording.
##   Name is enum's string, as reports name rule (`expression spacing`); id is its slug, i.e.
##     letters and digits in lowercase, each other run one `-` (`expression-spacing`), stable
##     for tool reading output.
##   Article citing each rule is caller's: `curator/audit` holds `CITATIONS`, indexed by
##     `Rule`, so rule without citation fails to compile there.
##   Rule with no fixer names check alone: `NotOverBinary`, `Fence` for fence fix cannot read,
##     and `FenceHeld` for lines fence keeps as written, which run reports as warning.

{.experimental: "strictFuncs".}

import std/strutils


type Rule* {.pure.} = enum  ## Define one rule knoller fixes or reports, in order chain runs.
  TrailingWhitespace = "trailing whitespace"  ## Line ends in space, tab or CR.
  FileEnding = "file ending"  ## File ends in exactly one newline.
  TabInString = "tab in string"  ## Tab inside one-line plain string is written `\t`.
  TrailingComment = "trailing comment"  ## Two spaces stand before trailing comment's marker.
  BannerSpacing = "banner spacing"  ## Blank lines beside banner follow its tier.
  EntryBlock = "entry block"  ## Entry block holds no binding; body moves into `proc main`.
  ArticleInComment = "article in comment"  ## Comment drops its articles.
  TableAlignment = "table alignment"  ## Table column aligns by display width.
  MessageValue = "message value"  ## Message echoes its value in backticks.
  AndWithOr = "and with or"  ## Condition mixing `and` with `or` parenthesises each `and`.
  NotOverBinary = "not over binary"  ## `not` over binary expression takes parentheses.
  TargetSubject = "to<Target> subject first"  ## `to<Target>` call takes its subject first.
  ReturnResult = "return result"  ## Routine never ends on `return result`.
  BracketImport = "bracket import"  ## Bracket import is alphabetised.
  ImportRank = "import rank"  ## Standard library, then packages, then local modules.
  ImportBrackets = "import brackets"  ## Adjacent imports of one directory share one bracket.
  SingleBindings = "single bindings"  ## Consecutive single bindings share one keyword.
  StrictFuncs = "strictFuncs"  ## Module carries `strictFuncs` before its imports.
  ProfilerImport = "profiler import"  ## Entry module imports profiler on one line.
  StubKeys = "stub keys"  ## Test stub leaves out `-r`, `batchable` and `joinable`.
  UnorderedList = "unordered list"  ## List language leaves unordered is alphabetised.
  TestBlankLines = "test blank lines"  ## Blank lines beside suite and test follow tier.
  HelperBlankLines = "helper blank lines"  ## Nested helper takes one blank line each side.
  DocPosition = "doc position"  ## Doc stands where shape of declaration puts it.
  LiteralDefault = "literal default"  ## Parameter with literal default states no type.
  ExpressionSpacing = "expression spacing"  ## Space stands only where expression rule puts it.
  ParameterSeparators = "parameter separators"  ## Commas between parameters, `;` between groups.
  TupleSeparators = "tuple separators"  ## Tuple type takes commas between fields.
  SignatureWrapping = "signature wrapping"  ## Signature wraps parameters only where it must.
  CallWrapping = "call wrapping"  ## Call takes one argument to line only where it must.
  TrailingSeparator = "trailing separator"  ## List of one item to line ends in separator.
  Fence = "fence"  ## Fence closes inside bracket, string or comment it opens in.
  FenceHeld = "fence held"  ## Fence keeps its lines as written; run warns of each fence.


func id*(rule: Rule): string =
  ## Read stable id of rule: its name in lowercase, each run of other characters one `-`.
  for c in ($rule).toLowerAscii:
    if c in {'a' .. 'z', '0' .. '9'}: result.add c
    elif result.len > 0 and result[^1] != '-': result.add '-'
  result.removeSuffix('-')
