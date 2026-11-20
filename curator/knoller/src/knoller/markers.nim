## Enforce Article I.6 and STYLE.md §5 on sibling markers: private symbol sibling reaches through
##   `{.all.}`, and its own module never uses, carries `{.used.}` and comment naming sibling;
##   `{.all.}` import reaches private symbol. Check and fixer read uses caller passes (`Uses`), as
##   semantic pass answered them.
##   Rulings of rule 7 (#443) fix three readings:
##   - Q1: sibling is module of package outside its `tests`; suite reaching internal needs no
##     marker, since test reaches internals by design. Its `{.all.}` still reaches something.
##   - Q2: marker stands only where sibling reaches symbol and its own module never uses it, as
##     compiler confirms: each such symbol is hint that it is declared and never used.
##   - Q3: `{.all.}` import of module outside package is not read, and its markers belong to
##     its own package.
##   Private symbol is name module declares at top level, under blocks opening no scope (`when`
##     chain, section keyword), outside entry block, with no `*`: routine, operator among them,
##     type, and single binding (`privatesTop`). Each is asked where every use of it stands
##     (`use`), at last byte of its name, or first of its operator, so implicit `result` that
##     routine at column 5 declares never answers. Answer lines of other symbol at same place,
##     as one `{.borrow.}` calls, are left out by name and type; use inside its own name is none.
##   Use counts where compiler resolves it, implicit call among them: `for d in x` calls `items`,
##     and `x[i]` calls `[]`. Caller asks in entry of each file importing module with `{.all.}`,
##     under each configuration its stubs give, so each `when` branch one takes is read.
##   `from M {.all.} import a, b` names its reach in its text, so it reaches where it names
##     private symbol of `M`.
##   Comment names sibling where it holds file name of each sibling reaching symbol, in any
##     spelling, as `# Used in cayleys.nim.`; comment rule decides backticks.
##   Fixer puts `used` among bare pragmas of block in dictionary order (X.10), or opens
##     `{.used.}` after name and its placeholders and parameters; comment `# Used in `x.nim`.`
##     trails line holding pragma. Doc cannot share line with plain comment, so trailing doc moves
##     to next line, one level in; fix moves that line, and caller traces it (`originApplied`).
##     Line holding plain comment, marker whose comment names no sibling, line marker would widen
##     past `LINE_MAX`, fenced line (X.1), and span edit of other fixer writes keep it for hand.
##   Fixer drops `{.all.}` of import reaching nothing, with space before it.
##
##   Cost: binding line declaring several names is unread, so its symbols take no marker.
##   Cost: use inside template body of module counts as use of module, where compiler may count
##     it only at expansion; fewer reports, never false one.
##   Cost: forward declaration answers its routine's own name as use, so forward-declared
##     symbol takes no marker.

{.experimental: "strictFuncs".}

import std/tables
import ./[edits, reports, symbols]


type
  UsePrivate* = object  ## Define where semantic pass finds private symbol used.
    siblings*: seq[string]
      ## File name of each sibling using it, outside `tests` of package, as `cayleys.nim`.
    is_own*: bool  ## Own module uses it, beyond its declaration.

  Uses* = object  ## Define what semantic pass tells marker rule of one file.
    reason*: string  ## Why pass resolved nothing for file; empty where it resolved.
    privates*: Table[(int, int), UsePrivate]
      ## Use of each private symbol file declares at top level, by one-based line and zero-based
      ##   byte column of its name; symbol no module of package imports with `{.all.}` is absent.
    imports*: Table[(int, int), bool]
      ## Whether each `{.all.}` import of module of package reaches private symbol, by line and
      ##   column of module it names; import of module outside package is absent.

  Private* = object  ## Define private symbol module declares at top level.
    name*: string  ## Name as declared, operator in backticks.
    keyword*: string  ## Keyword declaring it: routine's, `type`, `const`, `let` or `var`.
    line*: int  ## One-based line of name.
    column*: int  ## Zero-based byte column of first byte of name.
    index: int  ## Index of name token.

  ImportAll* = object  ## Define item of import that opens it with `{.all.}`.
    module*: string  ## Module as import names it, as `./algebra`.
    item: string  ## Name of item as written, as `algebra`.
    line*: int  ## One-based line of module's name.
    column*: int  ## Zero-based byte column of module's name.
    names*: seq[string]  ## Names `from … import` lists; empty for `import`.
    first: int  ## Byte offset of space before `{.all.}`, span fixer drops.
    after: int  ## Byte offset after `.}`.



func privatesTop*(source: string): seq[Private] =
  ## Read each private symbol source declares at top level: routine, operator among them, type and
  ##   single binding, under blocks opening no scope, outside entry block, with no `*`.
  discard


func queryUses*(path, source: string): Query =
  ## Build what marker rule asks semantic pass of module: every use of each private symbol.
  result.path = path


func importsAll*(source: string): seq[ImportAll] =
  ## Read each item of `import` or `from` statement that `{.all.}` opens: module it names, its
  ##   place, and span of `{.all.}`; bracket imports name each module apart.
  discard


func usesPackage*(
  files: openArray[(string, string)]; answers: openArray[(string, Answer)]; root: string
): Table[string, Uses] =
  ## Read uses of each file of package from answers of semantic pass, by path relative to root.
  discard


func checkMarkers*(path, source: string; uses: Uses): seq[Report] =
  ## Report each private symbol sibling reaches without its marker, and each `{.all.}` that
  ##   reaches none (STYLE.md §5).
  discard


func editsMarkers*(
  path, source: string; uses: Uses; fenced: openArray[int]; held: openArray[Edit] = []
): (seq[Edit], seq[Report]) =
  ## Read edits writing each marker and dropping each `{.all.}` check reports, and one report
  ##   per symbol or import.
  discard
