## Hold scripts to base JavaScript, and read advisories and latest releases of each node lock.
##   Architect asked that code import nothing beyond base JavaScript where it can avoid it, and
##     that npm packages stay up to date, security fixes first, read weekly (#1045).
##   Static part refuses, in `koch check`, each package that script could do without:
##     Each name of `dependencies`, `optionalDependencies` or `peerDependencies` of node manifest
##       is finding, since page or tool ships it; tools of build alone stay, as dev dependencies.
##     Each dev dependency off `PACKAGES_ALLOWED` is finding, and so is each import of TypeScript
##       naming package off it. Specifier opening `.` or `/` is path, and `node:` is built-in.
##     Bare built-in, as `fs`, reads as package, and help names `node:fs`.
##     Each `<script>` of page or SVG, and each `<base>`, under any prefix, whose address is no
##       plain path of project is finding, since page may load package from other host; so is each
##       `srcdoc` of frame, entity and default of attribute.
##     Plain path holds `CHARS_PATH` alone before its query, and opens with no `//`. Rule decodes
##       nothing, since each decode copies browser in part, and each part it leaves out is way past.
##     Tag reads as HTML reads it, since quote outside value that ends it early hides address.
##     Tag inside HTML comment takes same rule, though browser loads none of it.
##     Finding of project blocks branch of its role alone, as each finding inside project does
##       (CURATOR.md, duty 3).
##   Verb `advisories` asks npm registry, so `npm.yml` runs it weekly and `check` never does:
##     answer moves with no commit here, as `releases.nim` holds for nim-lang.org.
##     `npm audit --package-lock-only --json` reads lock alone, with no install; each package it
##       names is finding at lock, so exit is 1.
##     `npm view <name> version` gives latest release of each dev dependency; one locked below it
##       prints line that fails nothing.
##     Answer that cannot stand exits 2: exit of npm other than 0 or 1, text JSON cannot read,
##       `error` object, or exit that disagrees with count of advisories. Read as clean, it would
##       close issue for work never done.
##     Search is pure over answer of each ask (`checkAdvisories`), so suites run it offline.
##
##   Rejected: `npm outdated`, which reads `node_modules` and prints `{}` over lock alone (npm
##     10.9.9, 2026-11-27).
##   Rejected: list of Node built-ins for bare names, which moves with each Node release, where
##     `node:` form names built-in by itself.
##   Cost: imports read by scanner of strings, templates, comments and regular expressions, never
##     parsed: regular expression after word or `)`, as after `return`, reads as division, and
##     its quote can open string, or template that runs across lines. Specifier on line after its
##     keyword reads as none, and so do `module.require('x')`, `require?.('x')` and import built
##     from expression. Such miss can import package that listed tool pulls in and its lock
##     hoists, as `playwright-core`; import of address is expected to fail type check of `types`,
##     which resolves no address (unmeasured).
##   Cost: inline script of page reads as none, and so do frame, object and embed of other host,
##     whose script runs in origin of that host, apart from page. Path holding query mark that
##     reference encodes, or address of other host in comment, is refused, though browser loads
##     neither.
##   Cost: run asks npm once for each lock and once for each dev dependency of it.

{.experimental: "strictFuncs".}

import std/[json, options, os, osproc, sequtils, strutils]
import ./[findings, layout]
from ./dependencies import LOCK_NODE, MANIFEST_NODE
from ./kinds import Kind
from ./releases import isBelow


const
  PACKAGES_ALLOWED* = [
    ("@playwright/test", "drives browser through real events for `drive`"),
    ("typescript", "type-checks scripts for `types`"),
    ("@types/node", "declares types of Node built-ins to that check, and holds no code"),
  ]
    ## Packages script may take, each with what base JavaScript cannot do in its place; list grows
    ##   through process-change issue (CONTRIBUTOR.md, TypeScript and Node).
  FIELDS_RUNTIME = ["dependencies", "optionalDependencies", "peerDependencies"]
    ## Fields of manifest naming packages that ship with page or tool.
  FIELD_DEV = "devDependencies"  ## Field of manifest naming tools of build.
  PREFIX_BUILTIN = "node:"  ## Prefix naming Node built-in.
  KEYWORDS_IMPORT = ["from", "import", "require"]
    ## Words whose quoted operand names module, as `from 'x'`, `import 'x'` and `require('x')`.
  QUOTES = {'\'', '"', '`'}  ## Marks that open and close specifier.
  MARKS_BEFORE_EXPRESSION = {
    '(', ',', '=', ':', '[', '!', '&', '|', '?', '{', '}', ';', '+', '-', '*', '%', '<', '>', '~',
    '^',
  }
    ## Last marks of code after which `/` opens regular expression rather than division.
  CHARS_WORD = IdentChars + {'$', '#'}  ## Characters of name of script, private name included.
  CHARS_PATH = Letters + Digits + {'.', '-', '_', '~', '%', '/'}
    ## Characters that plain path of project holds, before its query.
  SPACES_HTML = {' ', '\t', '\n', '\f', '\r'}  ## Spaces that HTML strips at ends of address.
  SPACES_WIDE = [
    "\xC2\xA0", "\xE1\x9A\x80", "\xE2\x80\x80", "\xE2\x80\x81", "\xE2\x80\x82", "\xE2\x80\x83",
    "\xE2\x80\x84", "\xE2\x80\x85", "\xE2\x80\x86", "\xE2\x80\x87", "\xE2\x80\x88", "\xE2\x80\x89",
    "\xE2\x80\x8A", "\xE2\x80\xAF", "\xE2\x81\x9F", "\xE3\x80\x80", "\xEF\xBB\xBF",
  ]
    ## Spaces of script outside ASCII in UTF-8, as JavaScript reads `WhiteSpace`: U+00A0, U+1680,
    ##   U+2000 to U+200A, U+202F, U+205F, U+3000 and U+FEFF.
  SPACES_LINE = {' ', '\t', '\f', '\v'}  ## Spaces of script in ASCII that end no line.
  SECONDS_ASK = 60  ## Seconds npm waits on registry at most for one fetch.
  COMMAND_AUDIT* = "npm audit --package-lock-only --include=dev --json --fetch-retries=1 " &
    "--fetch-timeout=" & $(SECONDS_ASK * 1000)
    ## Command `askAudit` runs in directory of lock, which reads lock alone; `--include=dev` holds
    ##   over `NODE_ENV=production` and `omit=dev`, which drop each listed tool from audit.
  CITE_RULE = " (CONTRIBUTOR.md, TypeScript and Node)"  ## Rule each finding and line cites.


type
  Advisory* = object  ## Define one package that npm names vulnerable in lock.
    name*: string  ## Package, as lock keys it.
    severity*: string  ## Severity npm gives, as `high`.
    range*: string  ## Versions advisory covers, as `<=4.17.23`.
    notes*: seq[string]  ## Title and address of each advisory npm names for package.
    fix*: string  ## Version npm names as fix; empty where it names none.
    has_fix*: bool  ## Npm names fix, by version or as `true` that `npm audit fix` applies.

  Locked* = object  ## Define project carrying node manifest beside its lock.
    directory*: string  ## Project, repository-relative.
    manifest*: string  ## Text of `package.json`.
    lock*: string  ## Text of `package-lock.json`.

  Answer* = tuple[code: int, output: string]  ## Define exit and standard output of one ask.

  Scope {.pure.} = enum  ## Define what scanner of script stands inside.
    Code  ## Code, at top or in `${}` of template.
    Single  ## String that `'` opens.
    Double  ## String that `"` opens.
    Template  ## Template that backtick opens.
    Comment  ## Comment that `/*` opens.



#[ Static Check ]#

func namePackage*(specifier: string): string =
  ## Read package bare specifier names, i.e. `@scope/name` of `@scope/name/sub`, `name` of
  ##   `name/sub`.
  let parts = specifier.split('/')
  if specifier.startsWith('@') and parts.len > 1: parts[0] & "/" & parts[1]
  else: parts[0]


func isAllowed(name: string): bool =
  ## Decide whether package is on `PACKAGES_ALLOWED`.
  PACKAGES_ALLOWED.anyIt(it[0] == name)


func isPath(specifier: string): bool =
  ## Decide whether specifier names file by path, as `./x`, `../x` or `/x`, rather than package.
  specifier.startsWith('.') or (specifier.startsWith('/') and not specifier.startsWith("//"))


func keywordAt(text: string, at: int): string =
  ## Read keyword of import that opens word at `at`, never after `.` of member or character of
  ##   name; empty where none opens there.
  ##   Spread `...` is no member, so `...require('x')` names module.
  ##   End of word needs no test: `operand` reads only quote past spaces and `(`.
  let is_spread = at >= 3 and text[at - 3 ..< at] == "..."
  if at > 0 and not is_spread and (text[at - 1] in CHARS_WORD or text[at - 1] == '.'): return ""
  for keyword in KEYWORDS_IMPORT:
    if text.continuesWith(keyword, at): return keyword
  ""


func widthSpaceWide(text: string, at: int): int =
  ## Measure space of `SPACES_WIDE` that opens at `at`; `0` where none opens there.
  for space in SPACES_WIDE:
    if text.continuesWith(space, at): return space.len
  0


func operand(text: string; at: int; is_call: bool): tuple[specifier: string, ending: int] =
  ## Read quoted operand that opens at `at`, past spaces of line and comment on same line, and past
  ##   `(` of call, with index past its closing quote on same line; empty, ending at `at`, where
  ##   none opens there.
  var cursor = at
  while cursor < text.len:
    if text[cursor] in SPACES_LINE or (is_call and text[cursor] == '('): inc cursor
    elif text.widthSpaceWide(cursor) > 0: cursor += text.widthSpaceWide(cursor)
    elif text.continuesWith("/*", cursor):
      let closing = text.find("*/", cursor + 2)
      if closing < 0 or '\n' in text[cursor ..< closing]: return ("", at)
      cursor = closing + 2
    else: break
  if cursor >= text.len or text[cursor] notin QUOTES: return ("", at)
  let closing = text.find(text[cursor], cursor + 1)
  if closing < 0 or '\n' in text[cursor + 1 ..< closing]: return ("", at)
  (text[cursor + 1 ..< closing], closing + 1)


func endExpression(text: string, at: int): int =
  ## Find index past regular expression that `/` at `at` opens, on its line; `at + 1` where none
  ##   closes there, so `/` reads as division.
  var
    cursor = at + 1
    is_class = false
  while cursor < text.len and text[cursor] != '\n':
    let c = text[cursor]
    if c == '\\': inc cursor
    elif c == '[': is_class = true
    elif c == ']': is_class = false
    elif c == '/' and not is_class: return cursor + 1
    inc cursor
  at + 1


func specifiersScript*(text: string): seq[tuple[line: int, specifier: string]] =
  ## Read each module script names, with its line, i.e. quoted operand of `from`, `import` or
  ##   `require` in code.
  ##   Scanner holds stack of scopes, so keyword inside string, template, comment or regular
  ##     expression names none, and import inside `${}` of template names its module.
  ##   Keyword after `.` or character of name names none, and `from` takes no `(`.
  ##   Stays one routine, since scopes, braces of each `${}` and last mark of code move together.
  var
    scopes = @[Scope.Code]
    braces = @[0]
    line = 1
    cursor = 0
    mark = ';'  # Last mark of code; `;` stands for start of text, where expression may open.
  while cursor < text.len:
    let c = text[cursor]
    if c == '\n': inc line
    case scopes[^1]
    of Scope.Comment:
      if text.continuesWith("*/", cursor):
        scopes.setLen(scopes.len - 1)
        inc cursor
    of Scope.Single, Scope.Double, Scope.Template:
      let closing =
        case scopes[^1]
        of Scope.Single: '\''
        of Scope.Double: '"'
        else: '`'
      if c == '\\':
        if cursor + 1 < text.len and text[cursor + 1] == '\n': inc line
        inc cursor
      elif c == closing or (c == '\n' and scopes[^1] != Scope.Template):
        scopes.setLen(scopes.len - 1)
      elif scopes[^1] == Scope.Template and text.continuesWith("${", cursor):
        scopes.add Scope.Code
        braces.add 0
        inc cursor
    of Scope.Code:
      if text.continuesWith("//", cursor):
        while cursor + 1 < text.len and text[cursor + 1] != '\n': inc cursor
      elif text.continuesWith("/*", cursor):
        scopes.add Scope.Comment
        inc cursor
      elif c in QUOTES:
        scopes.add (
          case c
          of '\'': Scope.Single
          of '"': Scope.Double
          else: Scope.Template
        )
        mark = c
      elif c == '}' and scopes.len > 1 and braces[^1] == 0:
        scopes.setLen(scopes.len - 1)
        braces.setLen(braces.len - 1)
      elif c == '/' and mark in MARKS_BEFORE_EXPRESSION:
        cursor = text.endExpression(cursor)
        mark = '/'
        continue
      elif text.keywordAt(cursor).len > 0:
        let
          keyword = text.keywordAt(cursor)
          (specifier, ending) = text.operand(cursor + keyword.len, is_call = keyword != "from")
        result.add (line: line, specifier: specifier)
        cursor = max(ending, cursor + keyword.len)
        mark = 'x'
        continue
      else:
        if c == '{': inc braces[^1]
        elif c == '}': braces[^1] = max(braces[^1] - 1, 0)
        # Postfix `++` or `--` ends operand, so `/` after it divides.
        if c in {'+', '-'} and cursor > 0 and text[cursor - 1] == c and
            (cursor < 2 or text[cursor - 2] != c):
          mark = 'x'
        elif c notin Whitespace: mark = c
    inc cursor
  result = result.filterIt(it.specifier.len > 0)


func checkScript*(path, text: string): seq[Finding] =
  ## Report each import of package off `PACKAGES_ALLOWED` at its line; path and built-in pass.
  for (line, specifier) in text.specifiersScript:
    if specifier.isPath or specifier.startsWith(PREFIX_BUILTIN): continue
    let name = specifier.namePackage
    if name.isAllowed: continue
    result.add finding(
      path,
      line,
      "Script imports package off list of `packages_node.nim`; take base JavaScript, or ask " &
        "curator to list tool it cannot replace" & CITE_RULE & "; got `" & specifier & "`.",
      help = "Node built-in takes form `" & PREFIX_BUILTIN & name & "`.",
    )


func lineKey(text, key: string, after = 0): int =
  ## Find line of first `"key"` at or after line `after`, one-based; `0` where text holds none.
  let lines = text.splitLines
  for i in max(after - 1, 0) ..< lines.len:
    if ("\"" & key & "\"") in lines[i]: return i + 1
  0


proc checkManifest*(path, text: string): seq[Finding] =
  ## Report each runtime package of node manifest, and each dev dependency off `PACKAGES_ALLOWED`.
  let node =
    try: parseJson(text)
    except JsonParsingError, ValueError:
      return @[finding(path, 0, "Node manifest unreadable as JSON; got `" & path & "`.")]
  if node.kind != JObject: return
  for field in FIELDS_RUNTIME:
    if field notin node or node[field].kind != JObject: continue
    let at = text.lineKey(field)
    for name, _ in node[field]:
      result.add finding(
        path,
        text.lineKey(name, at),
        "Manifest ships package with page or tool; take base JavaScript, since only tools of " &
          "build stay, as dev dependencies" & CITE_RULE & "; got `" & name & "` in `" & field &
          "`.",
      )
  if FIELD_DEV in node and node[FIELD_DEV].kind == JObject:
    let at = text.lineKey(FIELD_DEV)
    for name, _ in node[FIELD_DEV]:
      if name.isAllowed: continue
      result.add finding(
        path,
        text.lineKey(name, at),
        "Dev dependency is off list of `packages_node.nim`; take base JavaScript, or ask " &
          "curator to list tool it cannot replace" & CITE_RULE & "; got `" & name & "`.",
      )


func attributes(text: string; at: int): seq[tuple[name, value: string]] =
  ## Read each attribute of tag from `at`, past its name, to `>` that ends it, as HTML reads it:
  ##   `a="v"`, `a='v'`, `a=v` or bare `a`, names lowercase.
  ##   Quote opens value only past `=` and its spaces; elsewhere it is character of name or of bare
  ##     value. Spaces are those of HTML alone, since wider set opens quote that browser reads as
  ##     bare, and so ends tag before browser does, which hides each attribute after.
  var cursor = at
  while cursor < text.len:
    while cursor < text.len and text[cursor] in SPACES_HTML + {'/'}: inc cursor
    if cursor >= text.len or text[cursor] == '>': return

    # Name opens at any other character, `=` too, and runs to space, `/`, `>` or `=`.
    let opening = cursor
    inc cursor
    while cursor < text.len and text[cursor] notin SPACES_HTML + {'/', '>', '='}: inc cursor
    let name = text[opening ..< cursor].toLowerAscii
    while cursor < text.len and text[cursor] in SPACES_HTML: inc cursor
    if cursor >= text.len or text[cursor] != '=':
      result.add (name: name, value: "")
      continue

    # Value past `=`, quoted to its closing quote, or bare to space or `>`.
    inc cursor
    while cursor < text.len and text[cursor] in SPACES_HTML: inc cursor
    if cursor < text.len and text[cursor] in {'"', '\''}:
      let
        closing = text.find(text[cursor], cursor + 1)
        ending = if closing < 0: text.len else: closing
      result.add (name: name, value: text[cursor + 1 ..< ending])
      cursor = ending + 1
    else:
      let value = cursor
      while cursor < text.len and text[cursor] notin SPACES_HTML + {'>'}: inc cursor
      result.add (name: name, value: text[value ..< cursor])


func isPathPlain(value: string): bool =
  ## Decide whether address names path of project alone: past spaces at its ends, its path before
  ##   first `?` or `#` holds `CHARS_PATH` alone, and opens with no `//`.
  ##   Rule decodes nothing, since each decode copies browser in part and leaves way past it; so
  ##     reference, `\`, `:`, control, space and character outside ASCII in path are refused.
  let
    address = value.strip(chars = SPACES_HTML)
    ending = address.find({'?', '#'})
    path = if ending < 0: address else: address[0 ..< ending]
  path.allCharsInSet(CHARS_PATH) and not path.startsWith("//")


func tagsNamed(
  text, name: string
): seq[tuple[line: int, attributes: seq[tuple[name, value: string]]]] =
  ## Read each tag of text with name, under any prefix, as `svg:script`, with no regard to case of
  ##   letters, as its line and attributes.
  let lowered = text.toLowerAscii
  var at = lowered.find('<')
  while at >= 0:
    var ending = at + 1
    while ending < text.len and text[ending] notin Whitespace + {'>', '/'}: inc ending
    let written = lowered[at + 1 ..< ending]
    if written[written.rfind(':') + 1 .. ^1] == name:
      result.add (line: text[0 ..< at].count('\n') + 1, attributes: text.attributes(ending))
    at = lowered.find('<', at + 1)


func checkPage*(path, text: string): seq[Finding] =
  ## Report each `<script>` and `<base>` whose address is no plain path of project, each `srcdoc`
  ##   of frame, and each entity and default of attribute, which can name address; at line of each.
  ##   Script takes address from `src`, or from `href` under any prefix, as `xlink:href` of SVG.
  ##   Tag inside comment takes same rule, though browser loads none of it.
  for (name, is_base) in [("script", false), ("base", true)]:
    for (line, attributes) in text.tagsNamed(name):
      for (attribute, value) in attributes:
        let is_address =
          if is_base: attribute == "href"
          else: attribute in ["src", "href"] or attribute.endsWith(":href")
        if not is_address or value.isPathPlain: continue
        result.add finding(
          path,
          line,
          "Page loads script from other host, or may; take base JavaScript, or script of " &
            "project at plain path" & CITE_RULE & "; got `" & value.escape("", "") & "`.",
        )
  for (line, attributes) in text.tagsNamed("iframe"):
    if attributes.anyIt(it.name == "srcdoc"):
      result.add finding(
        path,
        line,
        "Frame holds document in `srcdoc`, which can load script from other host in origin of " &
          "page; frame page of project at plain path by `src`" & CITE_RULE & "; got `srcdoc`.",
      )
  let lowered = text.toLowerAscii
  for (declaration, kind) in [("<!entity", "entity"), ("<!attlist", "default of attribute")]:
    var at = lowered.find(declaration)
    while at >= 0:
      result.add finding(
        path,
        text[0 ..< at].count('\n') + 1,
        "Page declares " & kind & ", which can name address of script from other host" &
          CITE_RULE & "; got `" & declaration.toUpperAscii & "`.",
      )
      at = lowered.find(declaration, at + 1)


proc checkPackagesNode*(tree: Tree): seq[Finding] =
  ## Run each part of static check over tree: manifests, scripts, then pages.
  for e in tree:
    if e.path.extractFilename == MANIFEST_NODE: result.add checkManifest(e.path, e.content)
    elif e.kind == some(Kind.TypeScript): result.add checkScript(e.path, e.content)
    elif e.kind in [some(Kind.Html), some(Kind.Svg)]: result.add checkPage(e.path, e.content)



#[ Advisories ]#

proc readAudit*(answer: Answer): tuple[advisories: seq[Advisory], failure: string] =
  ## Read advisories of one `npm audit --json`; failure names why answer cannot stand.
  if answer.code notin [0, 1]:
    return (@[], "npm audit exited `" & $answer.code & "`, which names neither clean lock nor " &
      "advisory")
  let node =
    try: parseJson(answer.output)
    except JsonParsingError, ValueError: return (@[], "npm audit printed text JSON cannot read")
  if node.kind != JObject or "error" in node:
    return (@[], "npm audit answered with error")
  let total = node{"metadata", "vulnerabilities", "total"}
  if total.isNil or total.kind != JInt or "vulnerabilities" notin node or
      node["vulnerabilities"].kind != JObject:
    return (@[], "npm audit gave no count of advisories")
  for name, entry in node["vulnerabilities"]:
    var advisory = Advisory(
      name: name, severity: entry{"severity"}.getStr, range: entry{"range"}.getStr
    )
    for via in entry{"via"}.getElems:
      if via.kind == JObject: advisory.notes.add via{"title"}.getStr & ", " & via{"url"}.getStr
    let fix = entry{"fixAvailable"}
    if not fix.isNil and fix.kind == JObject: advisory.fix = fix{"version"}.getStr
    advisory.has_fix = not fix.isNil and (fix.kind == JObject or fix.getBool)
    result.advisories.add advisory
  # Exit that disagrees with count marks answer npm did not finish.
  if (answer.code == 1) != (result.advisories.len > 0) or total.getInt != result.advisories.len:
    return (@[], "npm audit exited `" & $answer.code & "` beside " & $total.getInt &
      " advisories")


func failureNamed*(project: string, directories: openArray[string]): string =
  ## Read why verb refuses project named on command line; empty where none is named, or where
  ##   named one carries node manifest beside its lock.
  ##   Project named with no lock asks npm nothing, so its exit 0 would read as clean lock.
  if project.len == 0 or directories.len > 0: return ""
  "project carries no node manifest beside its lock; got `" & project & "`."


proc versionLocked*(lock, name: string): Option[string] =
  ## Read version lock holds for dependency of project; none where lock names none.
  let node =
    try: parseJson(lock)
    except JsonParsingError, ValueError: return none(string)
  let version = node{"packages", "node_modules/" & name, "version"}
  if version.isNil or version.kind != JString: none(string) else: some(version.getStr)


proc namesDev*(manifest: string): seq[string] =
  ## Read each dev dependency node manifest names, in its order.
  let node =
    try: parseJson(manifest)
    except JsonParsingError, ValueError: return
  if node.kind == JObject and FIELD_DEV in node and node[FIELD_DEV].kind == JObject:
    for name, _ in node[FIELD_DEV]: result.add name


proc checkAdvisories*(
  locked: openArray[Locked], audit, latest: proc(argument: string): Answer
): tuple[lines: seq[string], found: seq[Finding], failure: string] {.effectsOf: [audit, latest].} =
  ## Read advisories of each lock through `audit`, and latest release of each dev dependency
  ##   through `latest`; return lines verb prints, finding for each advisory, and failure of
  ##   search that cannot stand, which prints no line and finds nothing.
  for project in locked:
    let
      path_lock = project.directory & "/" & LOCK_NODE
      (advisories, failure) = readAudit(audit(project.directory))
    if failure.len > 0:
      return (@[], @[], failure & "; got `" & path_lock & "`.")

    # Name each advisory, with its fix, then each dev dependency behind its latest release.
    if advisories.len == 0:
      result.lines.add "Advisories that npm names in `" & path_lock & "`: none."
    else:
      result.lines.add "Advisories that npm names in `" & path_lock & "`; move each package " &
        "to its fix" & CITE_RULE & ":"
    for advisory in advisories:
      let fix =
        if advisory.fix.len > 0: "fix `" & advisory.fix & "`"
        elif advisory.has_fix: "fix by `npm audit fix`"
        else: "no fix"
      result.lines.add "  `" & advisory.name & "`, " & advisory.severity & ", `" &
        advisory.range & "`, " & fix & ":"
      for note in advisory.notes: result.lines.add "    " & note & "."
      result.found.add finding(
        path_lock,
        0,
        "Lock holds package that npm names in advisory; move it to its fix" & CITE_RULE &
          "; got `" & advisory.name & "`.",
      )
    var behind: seq[string]
    for name in project.manifest.namesDev:
      let
        answer = latest(name)
        release = answer.output.strip
      if answer.code != 0 or release.len == 0 or release.contains({' ', '\n', '{', '['}):
        return (@[], @[], "npm view gave no latest release of `" & name & "`; got `" &
          path_lock & "`.")
      let version = project.lock.versionLocked(name)
      if version.isNone:
        return (@[], @[], "Lock names no version of dev dependency `" & name & "`; got `" &
          path_lock & "`.")
      if version.get.isBelow(release):
        behind.add "  `" & name & "`: locks `" & version.get & "` against `" & release & "`."
    if behind.len > 0:
      result.lines.add "Dev dependencies behind latest release; each moves with its project, " &
        "and fails nothing" & CITE_RULE & ":"
      result.lines.add behind


proc askAudit*(directory: string): Answer =
  ## Ask npm registry for advisories of lock in directory, reading lock alone.
  let (output, code) =
    try: execCmdEx(COMMAND_AUDIT, options = {poEvalCommand, poUsePath}, workingDir = directory)
    except OSError: ("", 127)
  (code: code, output: output)


proc askLatest*(name: string): Answer =
  ## Ask npm registry for latest release of package.
  let command = "npm view " & quoteShell(name) & " version --fetch-retries=1 --fetch-timeout=" &
    $(SECONDS_ASK * 1000)
  let (output, code) =
    try: execCmdEx(command, options = {poEvalCommand, poUsePath})
    except OSError: ("", 127)
  (code: code, output: output)


proc readLocked*(root: string, directories: openArray[string]): seq[Locked] =
  ## Read manifest and lock of each project directory, in given order.
  for directory in directories:
    result.add Locked(
      directory: directory,
      manifest: readFile(root / directory / MANIFEST_NODE),
      lock: readFile(root / directory / LOCK_NODE),
    )
