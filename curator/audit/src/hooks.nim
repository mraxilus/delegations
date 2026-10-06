## Decide what each Claude Code hook answers, from fact hook event and git hand it.
##   Hook is mechanism and not rule: it calls koch verb and holds no rule of its own
##     (CURATOR.md, What no check can reach). Every finding here is one audit already states
##     for gate; this module reads hook's fact and names check holding it, so rule lives once.
##   Events, by verb argument: `path` refuses write outside branch scope; `edit` returns
##     static findings after write; `bash` refuses commit or push on `main` or outside grammar,
##     rewrite of pushed history, and push past pre-push hook, since `koch check` holds what
##     curator branch leaves to contributor (duty 3); `body` holds post before it lands to role
##     line, footer, Simplified Technical English counts, issue title and label, and pull
##     request headings; `stop` refuses end of turn that pushed or posted and closes with
##     neither sign-off block nor working line, and end of any turn whose message names `#N`
##     outside link or cites charter reference with no description; `start` prints role, read
##     order, carried list and drift; `push` and `msg` serve git hooks.
##   `gh api` in Bash posts as GitHub tools do, so `bash` reads each `gh api` write, maps it to
##     tool whose rules it shares, and holds its body as `body` holds tool's; `stop` counts it as
##     post. Hook runs before command, so body comes from literal text or file already written:
##     file same command writes, stdin and shell expansion are refused, with finding naming mend.
##   Pure functions take strings and return findings; procs read transcript JSON and body files,
##     since `parseJson` and file reads are effectful.
##   `coordinator` is role string with no branch: it opens issues and comments, and no item
##     carries it as label, since brief carries label of role it starts (COORDINATOR.md).
##   Sign-off follows order Architect set (GUIDE.md, Output contract): role, context, table,
##     summary, state with where branch stands, decisions, next step. Each decision block reads
##     as card, class says what blocks, and each ⚠️ row names role it waits on; coordinator,
##     once trialed, lifts each block onto card unchanged. So shape check holds what Architect
##     decides on: state word, class and place of each decision, two to four short options, and
##     recommendation naming one.
##   Delegate signs off only when done, blocked or waiting, as Architect set (GUIDE.md, Output
##     contract). Turn that ends while work runs closes with working line instead, naming what
##     runs and what wakes delegate, so each state word marks stop and none means work goes on.
##
##   Cost: hook reaches Claude Code session holding one repository alone, so CI stays gate.
##   Cost: `commandsGit` splits on shell operators by text, so `git` inside quoted string is
##     read as command; refusal then errs on safe side.
##   Cost: post whose body file same command writes, as by heredoc, is refused, so it takes two
##     calls: one writes file, next posts it.
##   Cost: mutation through `gh api graphql` reads as no post, so reading holds its body.
##   Cost: sign-off check reads shape, never whether row or decision says anything; evidence
##     cell of ✅ row must be non-empty and nothing more, and option need not be honest.
##   Cost: `stop` cannot tell coordinator, which holds no branch, from delegate; where it runs
##     for coordinator, whose message is digest, turn that posted is asked once for sign-off,
##     and second stop passes.

{.experimental: "strictFuncs".}

import std/[json, options, os, sequtils, strutils]
import ./[checker, commits, domains, english, findings, markdown, role, scope]


type
  Part {.pure.} = enum  ## Define one part of sign-off block, in order block holds them.
    Role, Context, Table, Summary, State, Decisions, Next

  Decision = object  ## Define one decision block of sign-off, as its shape check reads it.
    number: int  ## `n` of `**D<n>.**`; zero where not digits.
    question: string  ## Text after number, on its first line.
    class: string  ## Text after `Class:`; empty where block lacks item.
    where: string  ## Text after `Where:`; empty where block lacks item.
    has_options: bool  ## Block holds `Options:` item.
    options: seq[tuple[letter: char, label: string]]
      ## Lettered items under `Options:`; label empty where no colon closes it.
    recommends: string  ## Text after `Recommends:`; empty where block lacks item.

  Call* = object  ## Define one tool call of turn, as transcript records it.
    name*: string  ## Tool name, such as `Bash` or `mcp__github__issue_write`.
    command*: string  ## Bash command text; empty for other tools.
    has_body*: bool  ## Input carried `body`, so GitHub write posted text.

  Turn* = object  ## Define what transcript says about turn since last message of person.
    calls*: seq[Call]  ## Tool calls in order.
    text*: string  ## Text of last assistant message.

  Word = object  ## Define one word of shell text, as shell passes it to command.
    text: string  ## Word with quotes and escapes taken out.
    is_expanded: bool  ## Holds `$` or backtick outside single quotes, which shell expands.

  Request* = object  ## Define one `gh api` request of shell text, as `bash` hook reads it.
    endpoint*: string  ## Path as written, such as `repos/o/r/issues/7/comments`.
    action*: string  ## Method, uppercase, such as `POST`; `method` is Nim keyword.
    tool*: string  ## GitHub tool whose rules request shares; empty where none.
    is_create*: bool  ## Method is POST, so request makes new item, as `issue_write` create does.
    has_body*: bool  ## Field `body` or `--input` file given; JSON of file may still hold none.
    body*: string  ## Field `body` written inline.
    path*: string  ## File of `-F body=@PATH` or `--input PATH`, resolved; empty where none.
    is_input*: bool  ## `path` is `--input` JSON, whose `body`, `title` and `labels` it sends.
    expansion*: string
      ## First field `body`, `title` or `labels[]` holding shell expansion; empty where none.
    title*: string  ## Field `title`.
    labels*: seq[string]  ## Each field `labels[]`, in order.


const
  TOOLS_EDIT* = ["Edit", "Write", "MultiEdit", "NotebookEdit"]
    ## Tools that write file; `path` runs before them and `edit` after.
  TOOLS_PULL* = ["mcp__github__create_pull_request", "mcp__github__update_pull_request"]
    ## Tools whose body is pull request body, which follows template rather than footer rule.
  TOOLS_WRITE* = [
    "mcp__github__add_issue_comment", "mcp__github__issue_write",
    "mcp__github__create_pull_request", "mcp__github__update_pull_request",
    "mcp__github__pull_request_review_write", "mcp__github__add_reply_to_pull_request_comment",
    "mcp__github__update_issue_comment", "mcp__github__add_comment_to_pending_review",
  ]
    ## GitHub tools that post; turn calling one ends with sign-off.
  LUT_TOOL_BY_ENDPOINT = [
    ("POST issues", "mcp__github__issue_write"),
    ("PATCH issues/*", "mcp__github__issue_write"),
    ("POST issues/*/comments", "mcp__github__add_issue_comment"),
    ("PATCH issues/comments/*", "mcp__github__update_issue_comment"),
    ("POST pulls", "mcp__github__create_pull_request"),
    ("PATCH pulls/*", "mcp__github__update_pull_request"),
    ("POST pulls/*/reviews", "mcp__github__pull_request_review_write"),
    ("POST pulls/*/comments", "mcp__github__add_comment_to_pending_review"),
    ("POST pulls/*/comments/*/replies", "mcp__github__add_reply_to_pull_request_comment"),
    ("PATCH pulls/comments/*", "mcp__github__add_reply_to_pull_request_comment"),
  ]
    ## Tool whose rules `gh api` write shares, by method and endpoint from `issues` or `pulls`
    ##   on; `*` stands for one segment. Review comment and reply share rules, so edit of one
    ##   takes reply's.
  FLAGS_VALUE = [
    "-X", "--method", "-f", "--raw-field", "-F", "--field", "--input", "-H", "--header", "-q",
    "--jq", "-t", "--template", "-p", "--preview", "--hostname", "--cache",
  ]
    ## Flags of `gh api` taking value, as next word or after `=`; short one also glued to it.
  COORDINATOR = "coordinator"
    ## Role string no branch names: coordinator opens issues and comments, and no pull request.
  FOOTER* = "_Generated by [Claude Code](https://claude.ai/code)_"
    ## Line every issue, comment and review ends with.
  HEADING_SIGNOFF* = "## Sign-off"  ## Heading of closing block (GUIDE.md, Output contract).
  TABLE_SIGNOFF* = "| # | State | Item | Where | Evidence, or who acts |"
    ## Header row of its table, exact.
  LABELS_SIGNOFF: array[Part, string] = [
    "**Role:**", "**Context:**", TABLE_SIGNOFF, "**Summary:**", "**State:**", "**Decisions:**",
    "**Next step:**",
  ]
    ## Parts of block, in order each must appear.
  BLOCKED = "blocked"  ## State word of delegate nothing moves for until Architect decides.
  STATES_SIGNOFF = ["done", "waiting", BLOCKED]
    ## Words `**State:**` opens with, before where branch stands; each one is stop.
  LABEL_WORKING* = "**Working:**"  ## Opening of line closing turn that ends while work runs.
  DECISION_NONE = "None."  ## Text after `**Decisions:**` where block holds no decision.
  CLASS_BLOCKS = "blocks this delegate"  ## Class of decision delegate cannot work around.
  CLASS_BLOCKS_OTHERS = CLASS_BLOCKS & " and "
    ## Opening of class naming role strings that wait too, after `and`, split on comma.
  CLASS_WORKAROUND = "has a workaround:"  ## Opening of class naming workaround after colon.
  CLASS_FACT = "fact"  ## Class of decision Architect must know and need not decide.
  OPTIONS_MIN = 2  ## Options decision offers at least, unless its class is `fact`.
  OPTIONS_MAX = 4  ## Options decision offers at most, which is what decision card holds.
  WORDS_OPTION = 3  ## Words label of option holds at most.
  DECISION_OPENING = "**D"  ## Opening of decision line, before its number.
  DECISION_CLOSING = ".**"  ## Closing of decision number, before question.
  ITEM_CLASS = "- Class:"  ## Item naming class of decision.
  ITEM_WHERE = "- Where:"  ## Item naming issue or pull request where ruling goes.
  ITEM_OPTIONS = "- Options:"  ## Item over lettered options.
  ITEM_RECOMMENDS = "- Recommends:"  ## Item naming letter of option delegate picks, then why.
  OUTSIDE = "outside"  ## Word ⚠️ row opens last cell with where no role acts.
  MARKER_WAIT = "⚠"  ## State marker of row another delegate or outside party acts on.
  MARKER_HOLD = "⏸"  ## State marker of row Architect acts on.
  MARKERS* = ["☑", "✅", MARKER_WAIT, MARKER_HOLD, "⬜"]
    ## State markers in sort order, variation selector stripped.
  SELECTOR = "️"  ## Variation selector some markers carry; stripped before match.
  TAG_CARRIED = "(carried "  ## Tag row carries for carried-list item.
  CARRIED_MAX* = 6  ## Items on carried list (CONTRIBUTOR.md).
  SUBJECT_MERGE = "Merge "  ## Opening of subject git writes for merge commit.
  HEADINGS_PULL* = ["## Intent", "## Scope", "## Verification", "## Record", "## Notes"]
    ## Headings pull request template gives.
  MARK_CHECK* = "koch-check"
    ## File in git dir where `koch check` writes tree hash it passed on, which `pre-push`
    ##   reads; `markPath` places it.
  WORD_ROLE = "Role:"  ## Word after bold marker in sign-off role line.


func isStringRole*(s: string): bool =
  ## Decide whether `s` is role string: `coordinator`, `curator`, `curator/<project>` or
  ##   `contributor/<domain>/<project>`. Coordinator holds no branch, so grammar never names it.
  let parts = s.split('/')
  case parts.len
  of 1: s in [COORDINATOR, CURATOR]
  of 2: parts[0] == CURATOR and parts[1].isNameProject
  of 3: parts[0] == CONTRIBUTOR and parts[1].findDomain.isSome and parts[2].isNameProject
  else: false


func insideRoot*(root, path: string): string =
  ## Read path relative to root; absolute path outside root is returned whole.
  let prefix = root.strip(leading = false, chars = {'/'}) & "/"
  if path.startsWith(prefix): path[prefix.len .. ^1] else: path


func checkPathEdit*(branch, path: string): seq[Finding] =
  ## Report write outside scope branch names, before it happens.
  checkScope(branch, [path])


func segments(command: string): seq[seq[string]] =
  ## Read words of each segment of shell text, split on shell operators.
  var text = command
  for op in ["&&", "||", ";", "|"]: text = text.replace(op, "\n")
  for segment in text.splitLines: result.add segment.splitWhitespace


func commandsGit*(command: string): seq[seq[string]] =
  ## Read arguments of every `git` command in shell text, subcommand first.
  ##   Shell operators split segments; `-c key=value` and `-C dir` before subcommand are
  ##     skipped, so `git -c x=y push` reads as `push`.
  for tokens in command.segments:
    let at = tokens.find("git")
    if at < 0: continue
    var i = at + 1
    while i < tokens.len and tokens[i].startsWith("-"):
      if tokens[i] in ["-c", "-C"]: inc i
      inc i
    result.add tokens[i .. ^1]


func directoryCommand*(command, directory: string): string =
  ## Read directory first `git` command of shell text acts in: its `-C`, else last `cd` before
  ##   it, else `directory` call was made in. Relative path resolves against directory so far.
  ##   Worktree is its own checkout on its own branch, so hook reading branch of directory
  ##     command acts in judges subagent's commit by subagent's branch.
  ##   Cost: only first `git` command is read; second one with other `-C` takes first's
  ##     directory.

  template resolved(base, path: string): string =
    let bare = path.strip(chars = {'"', '\''})
    if bare.isAbsolute: bare else: base / bare

  result = directory
  for tokens in command.segments:
    if tokens.len > 1 and tokens[0] == "cd": result = resolved(result, tokens[1])
    let at = tokens.find("git")
    if at < 0: continue
    var i = at + 1
    while i < tokens.len and tokens[i].startsWith("-"):
      if tokens[i] == "-C" and i + 1 < tokens.len: return resolved(result, tokens[i + 1])
      if tokens[i] == "-c": inc i
      inc i
    return


func checkBash*(branch, command: string; is_head_pushed: bool): seq[Finding] =
  ## Report commit or push on `main` or outside grammar, and rewrite of pushed history.
  for arguments in command.commandsGit:
    if arguments.len == 0: continue
    let sub = arguments[0]
    if sub in ["commit", "push"] and (branch == MAIN or branch.parseBranch.isNone):
      result.add finding(
        "",
        0,
        "Never commit to `main`; push to branch inside grammar (CLAUDE.md); got `" & branch & "`.",
      )
    let is_forced = arguments.anyIt(it == "--force" or it == "-f" or it.startsWith("--force-"))
    if sub == "push" and is_forced:
      result.add finding("", 0, "Never rewrite pushed history (XI.2); got `git push --force`.")
    if sub == "push" and "--no-verify" in arguments:
      result.add finding(
        "",
        0,
        "Never push past pre-push hook; `koch check` holds what reddens contributor project " &
          "(CURATOR.md, duty 3); got `git push --no-verify`.",
      )
    if is_head_pushed and ((sub == "commit" and "--amend" in arguments) or sub == "rebase"):
      result.add finding(
        "",
        0,
        "Never rewrite pushed history (XI.2); HEAD is on remote; got `git " & sub & "`.",
      )


func isPost*(tool: string, has_body: bool): bool =
  ## Decide whether tool call posts text: GitHub write tool whose input carries body.
  ##   Update of labels or draft state alone carries none, and has nothing to read.
  tool in TOOLS_WRITE and has_body


func wordsShell(command: string): seq[seq[Word]] =
  ## Read words of each command of shell text, quotes honoured, as shell splits them.
  ##   Operator or newline ends command only outside quotes, so quoted body spanning lines stays
  ##     one word. Single quotes keep each character; double quotes and bare text expand `$` and
  ##     backtick, and backslash escapes.
  ##   Heredoc text is skipped, so apostrophe in it opens no quote; `#` opening word comments out
  ##     rest of line.
  ##   Kept whole past sixty lines: one pass over characters, where each branch is one state of
  ##     quoting, and split would hide which state each character is read in.
  ##   Cost: subshell and substitution outside quotes read as commands of their own; shift `<<`
  ##     reads as heredoc, and redirection as word.
  var
    words: seq[Word]
    word: Word
    is_open = false  # Word begun, though empty quotes leave it empty.
    quote = '\0'  # Quote character open; NUL outside quotes.
    heredocs: seq[tuple[delimiter: string, is_tabbed: bool]]  # Bodies skipped at next newline.
    i = 0

  template close() =
    if is_open: words.add word
    (word, is_open) = (Word(), false)

  template finish() =
    close()
    if words.len > 0: result.add words
    words = @[]

  while i < command.len:
    let c = command[i]
    if quote == '\'':
      if c == '\'': quote = '\0' else: word.text.add c
    elif quote == '"':
      if c == '"': quote = '\0'
      elif c == '\\' and i + 1 < command.len and command[i + 1] in {'$', '`', '"', '\\', '\n'}:
        inc i
        if command[i] != '\n': word.text.add command[i]
      else:
        if c in {'$', '`'}: word.is_expanded = true
        word.text.add c
    elif c == '\\' and i + 1 < command.len:
      inc i
      if command[i] != '\n':
        word.text.add command[i]
        is_open = true
    elif c in {'\'', '"'}:
      quote = c
      is_open = true
    elif c == '#' and not is_open:
      while i + 1 < command.len and command[i + 1] != '\n': inc i
    elif command.continuesWith("<<<", i):
      close()  # Here-string: word follows, and no heredoc opens.
      i += 3
      continue
    elif command.continuesWith("<<", i):
      # Read delimiter, quotes dropped; `<<-` strips leading tabs of its lines.
      close()
      i += 2
      let is_tabbed = i < command.len and command[i] == '-'
      if is_tabbed: inc i
      while i < command.len and command[i] in {' ', '\t'}: inc i
      var delimiter = ""
      while i < command.len and command[i] notin Whitespace + {';', '&', '|', '(', ')', '<', '>'}:
        if command[i] notin {'\'', '"', '\\'}: delimiter.add command[i]
        inc i
      heredocs.add (delimiter: delimiter, is_tabbed: is_tabbed)
      continue
    elif c == '\n':
      # Skip each heredoc body opened on this line, through its delimiter line.
      finish()
      for heredoc in heredocs:
        while i < command.len:
          let
            stop = command.find('\n', i + 1)
            last = if stop < 0: command.len else: stop
            line = command[i + 1 ..< last]
          i = last
          if heredoc.delimiter == (
            if heredoc.is_tabbed: line.strip(trailing = false, chars = {'\t'}) else: line
          ): break
      heredocs = @[]
    elif c in {';', '&', '|', '(', ')'}: finish()
    elif c in {' ', '\t', '\r'}: close()
    else:
      if c in {'$', '`'}: word.is_expanded = true
      word.text.add c
      is_open = true
    inc i
  finish()


func toolOf(action, endpoint: string): string =
  ## Read GitHub tool whose rules request shares, by method and endpoint; empty where none.
  ##   Endpoint is read from `issues` or `pulls` segment after `repos`, so owner and repo may be
  ##     `{owner}/{repo}` or one shell variable, and leading `/`, host and query drop.
  let
    parts = endpoint.split('?')[0].split('/')
    at = parts.find("repos")
  if at < 0: return ""
  for k in at + 1 ..< parts.len:
    if parts[k] notin ["issues", "pulls"]: continue
    let actual = @[action] & parts[k .. ^1]
    for (route, tool) in LUT_TOOL_BY_ENDPOINT:
      let pattern = route.split({' ', '/'})
      if pattern.len == actual.len and (0 ..< actual.len).allIt(pattern[it] in ["*", actual[it]]):
        return tool
  ""


func located(base, path: string): string =
  ## Read path against base; stdin `-`, absolute path and path under `~` stay as written.
  if path == "-" or path.isAbsolute or path.startsWith('~'): path else: base / path


func requestOf(arguments: openArray[Word], directory: string): Request =
  ## Read one `gh api` request from words after `api`: each flag with its value, and first other
  ##   word as endpoint.
  ##   Method is `-X` or `--method`, else POST where field or input file is given, else GET, as
  ##     `gh api` sets it. `-F body=@PATH` and `--input PATH` name file `checkPosts` reads; `-f`
  ##     takes `@` as text, as `gh api` does.
  var
    is_field = false
    i = 0
  while i < arguments.len:
    var (flag, holder) = (arguments[i].text, arguments[i])
    inc i
    var value = ""
    if flag.startsWith("--") and '=' in flag:
      value = flag.split('=', 1)[1]
      flag = flag.split('=', 1)[0]
    elif flag in FLAGS_VALUE:
      if i >= arguments.len: break
      (value, holder) = (arguments[i].text, arguments[i])
      inc i
    elif flag.len > 2 and flag[0] == '-' and flag[0 .. 1] in FLAGS_VALUE:
      value = flag[2 .. ^1]
      flag = flag[0 .. 1]
    elif flag.startsWith("-"): continue
    else:
      if result.endpoint.len == 0: result.endpoint = flag
      continue
    case flag
    of "-X", "--method": result.action = value.toUpperAscii
    of "--input":
      (result.path, result.is_input, result.has_body) = (located(directory, value), true, true)
      is_field = true
    of "-f", "--raw-field", "-F", "--field":
      let equal = value.find('=')
      if equal < 0: continue
      is_field = true
      let (key, content) = (value[0 ..< equal], value[equal + 1 .. ^1])
      if key notin ["body", "title", "labels[]"]: continue
      if key == "body": result.has_body = true
      if key == "body" and flag in ["-F", "--field"] and content.startsWith('@'):
        result.path = located(directory, content[1 .. ^1])
        continue
      if holder.is_expanded and result.expansion.len == 0: result.expansion = value
      case key
      of "body": result.body = content
      of "title": result.title = content
      else: result.labels.add content
    else: discard

  # Default method as `gh api` does, then tool whose rules write shares.
  if result.action.len == 0: result.action = if is_field: "POST" else: "GET"
  result.is_create = result.action == "POST"
  result.tool = toolOf(result.action, result.endpoint)


func requests*(command, directory: string): seq[Request] =
  ## Read every `gh api` request of shell text: endpoint, method, tool whose rules it shares,
  ##   and fields `body`, `title` and `labels[]`.
  ##   File resolves against directory command acts in: `directory`, moved by each `cd` before
  ##     it. Stdin `-` and path under `~` stay as written, so `checkPosts` names them unread.
  var working = directory
  for words in command.wordsShell:
    if words[0].text == "cd":
      working = located(working, if words.len > 1: words[1].text else: "~")
      continue
    for i in 0 ..< words.len - 1:
      let name = words[i].text
      if (name == "gh" or name.endsWith("/gh")) and words[i + 1].text == "api":
        result.add requestOf(words[i + 2 .. ^1], working)
        break


func isPost*(request: Request): bool =
  ## Decide whether `gh api` request posts text: write tool's rules hold, carrying body.
  isPost(request.tool, request.has_body)


func outsideComments(text: string): string =
  ## Blank every HTML comment, so template left unfilled reads as empty.
  var rest = text
  while true:
    let open = rest.find(COMMENT_OPEN)
    if open < 0: break
    let close = rest.find("-->", open)
    if close < 0:
      rest = rest[0 ..< open]
      break
    rest = rest[0 ..< open] & rest[close + 3 .. ^1]
  rest


func checkBody*(
  tool, branch, title, body: string; labels: openArray[string]; is_create: bool
): seq[Finding] =
  ## Report post that breaks what every post keeps, before it lands.
  let parsed = branch.parseBranch
  if parsed.isSome:
    let expected = KEY_ROLE & " " & parsed.get.roleName
    if body.lineRole != expected:
      result.add finding(
        "",
        0,
        "Post must open with `" & expected & "`; got `" & body.lineRole.shortened & "`.",
      )
  if tool notin TOOLS_PULL and not body.strip.endsWith(FOOTER):
    result.add finding("", 0, "Post must end with footer `" & FOOTER & "`; got no footer.")
  result.add findingsEnglish("post", body)
  if tool == "mcp__github__issue_write" and is_create:
    if title.parseSubject.isSome:
      result.add finding(
        "",
        0,
        "Issue title is claim, never `type(scope):` subject; got `" & title & "`.",
      )
    if COORDINATOR in labels or not labels.anyIt(it.isStringRole):
      result.add finding(
        "",
        0,
        "Issue must carry role label of its work, copied from grammar, and never `" &
          COORDINATOR & "`; got `" & labels.join(", ") & "`.",
      )
  if tool == "mcp__github__create_pull_request":
    let headings = body.linesHeading
    for h in HEADINGS_PULL:
      if h notin headings:
        result.add finding("", 0, "Pull request body must carry `" & h & "`; got none.")
    let shown = body.section(HEADINGS_PULL[2]).outsideComments.strip
    if HEADINGS_PULL[2] in headings and shown.len == 0:
      result.add finding("", 0, "Verification must show change; got template comment alone.")


proc checkPosts*(branch, command, directory: string): seq[Finding] =
  ## Report each `gh api` post of shell text that `checkBody` refuses, or whose body hook cannot
  ##   read before command runs, with mend: literal path, or file written in earlier call.
  ##   `--input` JSON with no `body` is no post, as tool call with none is not.
  for request in requests(command, directory):
    if not request.isPost: continue
    if request.expansion.len > 0:
      result.add finding(
        "",
        0,
        "Hook reads `gh api` post before shell expands it; write body to file in earlier call, " &
          "name it as `-F body=@<path>`, and write title and labels literally; got `" &
          request.expansion.shortened & "`.",
      )
      continue
    var (title, body, labels) = (request.title, request.body, request.labels)
    if request.path.len > 0:
      if request.path == "-" or request.path.startsWith('~') or request.path.contains({'$', '`'}):
        result.add finding(
          "",
          0,
          "Hook reads `gh api` post before command runs, so body from shell variable or stdin " &
            "is unread; name file by literal path; got `" & request.path & "`.",
        )
        continue
      if not request.path.fileExists:
        result.add finding(
          "",
          0,
          "Hook reads `gh api` post before command runs, so it cannot read file command itself " &
            "writes; write file in earlier call; got missing `" & request.path & "`.",
        )
        continue
      body = readFile(request.path)
      if request.is_input:
        let data =
          try: body.parseJson
          except JsonParsingError, ValueError: newJNull()
        if data.kind != JObject:
          result.add finding(
            "",
            0,
            "`--input` file of `gh api` post must hold JSON object; got `" & request.path & "`.",
          )
          continue
        if data{"body"} == nil: continue
        body = data{"body"}.getStr
        title = data{"title"}.getStr(title)
        if data{"labels"} != nil: labels = data{"labels"}.getElems.mapIt(it.getStr)
    result.add checkBody(request.tool, branch, title, body, labels, request.is_create)


func tagsCarried(cell: string): seq[int] =
  ## Read every `(carried N)` of cell as N; `0` where N is not digit.
  var at = cell.find(TAG_CARRIED)
  while at >= 0:
    let
      rest = cell[at + TAG_CARRIED.len .. ^1]
      close = rest.find(')')
      number = if close > 0: rest[0 ..< close].strip else: ""
    result.add(if number.len > 0 and number.allCharsInSet(Digits): number.parseInt else: 0)
    at = cell.find(TAG_CARRIED, at + 1)


func decisionsIn(lines: openArray[string]): seq[Decision] =
  ## Read each `**D<n>.**` block of lines, with items under it, in order.
  ##   Option is item opening `- <letter>.` below `Options:`, at any indent, so flat list
  ##     reads as nested one does.
  for line in lines:
    let s = line.strip
    if s.startsWith(DECISION_OPENING) and s.len > DECISION_OPENING.len and
        s[DECISION_OPENING.len] in Digits:
      var close = DECISION_OPENING.len
      while close < s.len and s[close] in Digits: inc close
      result.add Decision(
        number: s[DECISION_OPENING.len ..< close].parseInt,
        question:
          if s.continuesWith(DECISION_CLOSING, close):
            s[close + DECISION_CLOSING.len .. ^1].strip
          else: "",
      )
      continue
    if result.len == 0: continue
    if s.startsWith(ITEM_CLASS): result[^1].class = s[ITEM_CLASS.len .. ^1].strip
    elif s.startsWith(ITEM_WHERE): result[^1].where = s[ITEM_WHERE.len .. ^1].strip
    elif s.startsWith(ITEM_OPTIONS): result[^1].has_options = true
    elif s.startsWith(ITEM_RECOMMENDS):
      result[^1].recommends = s[ITEM_RECOMMENDS.len .. ^1].strip
    elif result[^1].has_options and s.len > 3 and s.startsWith("- ") and
        s[2] in LowercaseLetters and s[3] == '.':
      let
        item = s[4 .. ^1]
        colon = item.find(':')
      result[^1].options.add (letter: s[2], label: if colon < 0: "" else: item[0 ..< colon].strip)


func findingsDecision(d: Decision, at: int): seq[Finding] =
  ## Report decision block out of shape: number, class, place, options, pick and question.
  ##   Class `fact` asks nothing, so it offers no option and picks none; every other class
  ##     asks question with two to four options, and names pick among them.
  let name = "`D" & $d.number & "`"
  if d.number != at + 1:
    result.add finding("", 0, "Decisions are numbered from D1 in order; got `" & name & "`.")
  if d.class.len == 0: result.add finding("", 0, "Decision " & name & " lacks `Class:`; got none.")
  if d.where.len == 0: result.add finding("", 0, "Decision " & name & " lacks `Where:`; got none.")
  if d.class.startsWith(CLASS_BLOCKS_OTHERS):
    let roles = d.class[CLASS_BLOCKS_OTHERS.len .. ^1].replace(" and ", ",").split(',')
    for r in roles:
      if not r.strip.isStringRole:
        result.add finding(
          "",
          0,
          "Class names each role that waits too as role string; got `" & r.strip & "`.",
        )
  elif d.class.len > 0 and d.class notin [CLASS_BLOCKS, CLASS_FACT] and
      not (d.class.startsWith(CLASS_WORKAROUND) and d.class.len > CLASS_WORKAROUND.len):
    result.add finding(
      "",
      0,
      "Class is `" & CLASS_BLOCKS & "`, `" & CLASS_BLOCKS_OTHERS & "<role>`, `" &
        CLASS_WORKAROUND & " <workaround>` or `" & CLASS_FACT & "`; got `" & d.class & "`.",
    )
  if d.class == CLASS_FACT:
    if d.has_options or d.options.len > 0:
      result.add finding(
        "",
        0,
        "Decision of class `fact` offers no option; got `" & $d.options.len & "` in `" & name &
          "`.",
      )
    if d.recommends.len > 0:
      result.add finding(
        "",
        0,
        "Decision of class `fact` picks no option; got `" & d.recommends.shortened & "`.",
      )
    return
  if d.options.len < OPTIONS_MIN or d.options.len > OPTIONS_MAX:
    result.add finding(
      "",
      0,
      "Decision " & name & " offers " & $OPTIONS_MIN & " to " & $OPTIONS_MAX & " options; got `" &
        $d.options.len & "`.",
    )
  for o in d.options:
    if o.label.len == 0:
      result.add finding(
        "",
        0,
        "Option reads `<letter>. <label>: <consequence>`; got `" & o.letter & "` in `" & name &
          "`.",
      )
    elif o.label.splitWhitespace.len > WORDS_OPTION:
      result.add finding(
        "",
        0,
        "Option label holds at most " & $WORDS_OPTION & " words; got `" & o.label & "`.",
      )
  let pick = d.recommends.split({',', ' ', '.', ':'})[0]
  if d.recommends.len == 0:
    result.add finding("", 0, "Decision " & name & " lacks `Recommends:`; got none.")
  elif pick.len != 1 or pick[0] notin d.options.mapIt(it.letter):
    result.add finding(
      "",
      0,
      "Recommends names letter of one option of " & name & "; got `" & pick & "`.",
    )
  if not d.question.endsWith("?"):
    result.add finding(
      "",
      0,
      "Question of " & name & " ends with `?`; got `" & d.question.shortened & "`.",
    )


func numbersDecision(cell: string): seq[int] =
  ## Read every `D<n>` word of cell as n.
  for word in cell.split({' ', ',', '.', ';', ':', '(', ')'}):
    if word.len > 1 and word[0] == 'D' and word[1 .. ^1].allCharsInSet(Digits):
      result.add word[1 .. ^1].parseInt


func findingsRow(rows: seq[seq[string]], numbers: openArray[int]): seq[Finding] =
  ## Report rows of sign-off table out of shape: cells, order, evidence, carried tags, who acts.
  ##   ⚠️ row opens last cell with role that acts, or `outside`, so coordinator sees which
  ##     delegate blocks which; ⏸️ row names decision it waits on, so its card carries it.
  var
    last = 0
    seen: seq[int]
  for i, row in rows:
    if row.len != 5:
      result.add finding("", 0, "Sign-off row must hold five cells; got `" & $row.len & "`.")
      continue
    if row[0] != $(i + 1):
      result.add finding("", 0, "Sign-off rows are numbered from 1 in order; got `" & row[0] & "`.")
    let
      marker = row[1].replace(SELECTOR, "")
      state = MARKERS.find(marker)
    if state < 0:
      result.add finding("", 0, "Sign-off state must be one of ☑️ ✅ ⚠️ ⏸️ ⬜; got `" & row[1] & "`.")
    elif state < last:
      result.add finding(
        "",
        0,
        "Sign-off states sort ☑️ ✅ ⚠️ ⏸️ ⬜; got `" & row[1] & "` after later state.",
      )
    else: last = state
    if state == 1 and row[4].len == 0:
      result.add finding(
        "",
        0,
        "Sign-off ✅ row needs evidence; got empty cell in row `" & row[0] & "`.",
      )
    let actor = if row[4].len == 0: "" else: row[4].splitWhitespace[0].strip(chars = {',', ':'})
    if marker == MARKER_WAIT and actor != OUTSIDE and not actor.isStringRole:
      result.add finding(
        "",
        0,
        "Sign-off ⚠️ row opens last cell with role string or `" & OUTSIDE & "`; got `" & actor &
          "` in row `" & row[0] & "`.",
      )
    let named = row[4].numbersDecision
    if marker == MARKER_HOLD and (named.len == 0 or named.anyIt(it notin numbers)):
      result.add finding(
        "",
        0,
        "Sign-off ⏸️ row names decision it waits on as `D<n>`; got `" & row[4] & "` in row `" &
          row[0] & "`.",
      )
    for n in row[2].tagsCarried:
      if n < 1 or n > CARRIED_MAX:
        result.add finding(
          "",
          0,
          "Carried tag names item 1 to " & $CARRIED_MAX & "; got `" & $n & "`.",
        )
      elif n in seen:
        result.add finding("", 0, "Carried item tagged twice; got `" & $n & "`.")
      else: seen.add n


func checkSignoff*(message, branch: string): seq[Finding] =
  ## Report message that lacks sign-off block, or holds it out of shape.
  let lines = message.splitLines
  var at = -1
  for i, line in lines:
    if line.strip == HEADING_SIGNOFF: at = i
  if at < 0:
    return @[finding(
      "", 0, "Message holds no `" & HEADING_SIGNOFF & "` block (GUIDE.md, Output contract)."
    )]
  let after = lines[at + 1 .. ^1]
  for line in after:
    if line.startsWith("#"):
      result.add finding("", 0, "Nothing follows sign-off; got heading `" & line & "`.")
  var
    starts: array[Part, int]
    pos = 0
  for part, label in LABELS_SIGNOFF:
    starts[part] = -1
    for j in pos ..< after.len:
      if after[j].startsWith(label):
        starts[part] = j
        break
    if starts[part] < 0:
      result.add finding("", 0, "Sign-off lacks `" & label & "` in its order; got none.")
    else: pos = starts[part] + 1
  if starts.anyIt(it < 0): return

  template rest(part: Part): string =
    after[starts[part]][LABELS_SIGNOFF[part].len .. ^1].strip

  let
    text_role = Part.Role.rest.split(',')[0].strip
    parsed = branch.parseBranch
    word_state = Part.State.rest.split({',', ' '})[0]
    decisions = decisionsIn(after[starts[Part.Decisions] + 1 ..< starts[Part.Next]])
  if parsed.isSome and text_role != parsed.get.roleName:
    result.add finding(
      "",
      0,
      "Sign-off role must be `" & parsed.get.roleName & "`; got `" & text_role & "`.",
    )
  if word_state notin STATES_SIGNOFF:
    result.add finding(
      "",
      0,
      "Sign-off state is one of " & STATES_SIGNOFF.join(", ") &
        (if word_state == "working": ", and turn while work runs closes with line `" &
           LABEL_WORKING & "`"
         else: "") & "; got `" & word_state & "`.",
    )
  elif (word_state == BLOCKED) != decisions.anyIt(it.class.startsWith(CLASS_BLOCKS)):
    result.add finding(
      "",
      0,
      "Sign-off state is `" & BLOCKED & "` exactly when decision blocks; got `" & word_state & "`.",
    )
  if decisions.len == 0 and Part.Decisions.rest != DECISION_NONE:
    result.add finding(
      "",
      0,
      "Sign-off with no decision writes `" & LABELS_SIGNOFF[Part.Decisions] & " " &
        DECISION_NONE & "`; got `" & Part.Decisions.rest.shortened & "`.",
    )
  elif decisions.len > 0 and Part.Decisions.rest.len > 0:
    result.add finding(
      "",
      0,
      "Decisions label stands alone over its blocks; got `" & Part.Decisions.rest.shortened & "`.",
    )
  for i, d in decisions: result.add findingsDecision(d, i)
  result.add findingsRow(
    after[starts[Part.Table] + 1 ..< starts[Part.Summary]].join("\n").rowsTable,
    decisions.mapIt(it.number),
  )
  var k = starts[Part.Next] + 1
  while k < after.len and after[k].strip.len > 0: inc k
  for line in after[k .. ^1]:
    if line.strip.len > 0:
      result.add finding(
        "",
        0,
        "Nothing follows Next step of sign-off; got `" & line.shortened & "`.",
      )
  var prose: seq[string]
  for line in after:
    if line.strip.startsWith("|"): continue
    var text = line
    for label in LABELS_SIGNOFF:
      if text.startsWith(label): text = text[label.len .. ^1].strip
    prose.add text
  result.add findingsEnglish("sign-off", prose.join("\n"))


func labelDefined(line: string): string =
  ## Read label that line defines as `[label]: url`, lowercased; empty where it defines none.
  let s = line.strip(trailing = false)
  if line.len - s.len > 3 or not s.startsWith("["): return ""
  let close = s.find(']')
  if close < 2 or not s[close + 1 .. ^1].startsWith(":") or s[close + 2 .. ^1].strip.len == 0:
    return ""
  s[1 ..< close].toLowerAscii


func codeSpansOut(line: string): string =
  ## Blank each code span of line: run of backticks opens it, next run of same length closes
  ##   it, and run left open stays text, as CommonMark reads it.
  var i = 0
  while i < line.len:
    if line[i] != '`':
      result.add line[i]
      inc i
      continue
    var n = 0
    while i + n < line.len and line[i + n] == '`': inc n
    var
      j = i + n
      close = -1
    while j < line.len and close < 0:
      if line[j] != '`':
        inc j
        continue
      var m = 0
      while j + m < line.len and line[j + m] == '`': inc m
      if m == n: close = j
      j += m
    if close < 0:
      result.add line[i ..< i + n]
      i += n
    else:
      result.add ' '.repeat(close + n - i)
      i = close + n


func linksOut(line: string, labels: openArray[string]): string =
  ## Blank each link of line: `[text](url)`, and `[text][label]` or `[label]` whose label
  ##   message defines. Bracket opening no link stays text.
  var i = 0
  while i < line.len:
    if line[i] != '[':
      result.add line[i]
      inc i
      continue
    let close = line.find(']', i + 1)
    if close < 0:
      result.add line[i .. ^1]
      break
    let text = line[i + 1 ..< close]
    var stop = -1  # Index past link; none where bracket opens no link.
    if close + 1 < line.len and line[close + 1] == '(':
      let paren = line.find(')', close + 2)
      if paren >= 0: stop = paren + 1
    elif close + 1 < line.len and line[close + 1] == '[':
      let shut = line.find(']', close + 2)
      if shut >= 0:
        let label = line[close + 2 ..< shut]
        if (if label.len == 0: text else: label).toLowerAscii in labels: stop = shut + 1
    elif text.toLowerAscii in labels: stop = close + 1
    if stop < 0:
      result.add '['
      inc i
    else:
      result.add ' '.repeat(stop - i)
      i = stop


func checkNumbersBare*(message: string): seq[Finding] =
  ## Report each `#N` of message outside link and outside code (GUIDE.md, Output contract).
  ##   Definition line `[label]: url` is link too, as is `[label]` it defines. `#` after word
  ##     character, `&` or `/` opens no number: `&#N;` is character reference, `x#N` fragment
  ##     or name in other repository. Each number reports once.
  let lines = message.fencedOut.splitLines
  var
    labels: seq[string]
    seen: seq[string]
  for line in lines:
    let label = line.labelDefined
    if label.len > 0: labels.add label
  for line in lines:
    if line.labelDefined.len > 0: continue
    let text = line.codeSpansOut.linksOut(labels)
    var i = 0
    while i < text.len:
      let is_number = text[i] == '#' and i + 1 < text.len and text[i + 1] in Digits and
        (i == 0 or text[i - 1] notin IdentChars + {'&', '/'})
      if not is_number:
        inc i
        continue
      var j = i + 1
      while j < text.len and text[j] in Digits: inc j
      let number = text[i ..< j]
      if number notin seen:
        seen.add number
        result.add finding(
          "",
          0,
          "Message names `" & number & "` outside link; name each issue and pull request by " &
            "short description and its number, as one link (GUIDE.md, Output contract).",
        )
      i = j


func checkReferencesBare*(message: string): seq[Finding] =
  ## Report each charter reference of message that stands with no description (GUIDE.md, Output
  ##   contract): article `X.9`, after `Article ` or not, or `duty 3`, capital at sentence start.
  ##   Reference passes inside parentheses where word holding letter stands before opening one,
  ##     on same line, as rule's own examples cite it: `expression spacing (X.9)`. So
  ##     `(X.2, X.9)` after text passes whole, and line or bullet opening with `(` fails.
  ##   Code and links are skipped as `checkNumbersBare` skips them. Reference opens after no word
  ##     character, `.`, `/` or `-`, and closes before no word character and no `.` with digit,
  ##     so `2.2.12`, `D2`, `§5`, `MIX.3` and `IX.2.1` cite none. Each reference reports once.

  func referenceEnd(text: string, at: int): int =
    ## Read index past reference opening at `at` of text; `at` itself where none opens there.
    if at > 0 and text[at - 1] in IdentChars + {'.', '/', '-'}: return at
    var i = at
    if text.continuesWith("duty ", at) or text.continuesWith("Duty ", at): i += "duty ".len
    else:
      while i < text.len and text[i] in {'I', 'V', 'X'}: inc i
      if i == at or i >= text.len or text[i] != '.': return at
      inc i
    let digits = i
    while i < text.len and text[i] in Digits: inc i
    let is_longer = i < text.len and
      (text[i] in IdentChars or (text[i] == '.' and i + 1 < text.len and text[i + 1] in Digits))
    if i == digits or is_longer: at else: i

  func isDescribed(line, text: string; at, after: int): bool =
    ## Decide whether span `at ..< after` of line stands inside parentheses, with word holding
    ##   letter before opening one; `text` is line with code and links blanked, same length.
    var
      depth = 0
      open = -1
      close = -1
    for i in countdown(at - 1, 0):
      if text[i] == ')': inc depth
      elif text[i] == '(' and depth > 0: dec depth
      elif text[i] == '(':
        open = i
        break
    depth = 0
    for i in after ..< text.len:
      if text[i] == '(': inc depth
      elif text[i] == ')' and depth > 0: dec depth
      elif text[i] == ')':
        close = i
        break
    if open < 0 or close < 0: return false
    let words = line[0 ..< open].splitWhitespace
    words.len > 0 and words[^1].contains(Letters)

  let lines = message.fencedOut.splitLines
  var
    labels: seq[string]
    seen: seq[string]
  for line in lines:
    let label = line.labelDefined
    if label.len > 0: labels.add label
  for line in lines:
    if line.labelDefined.len > 0: continue
    let text = line.codeSpansOut.linksOut(labels)
    var i = 0
    while i < text.len:
      let after = text.referenceEnd(i)
      if after == i:
        inc i
        continue
      let reference = text[i ..< after]
      if not line.isDescribed(text, i, after) and reference.toLowerAscii notin seen:
        seen.add reference.toLowerAscii
        result.add finding(
          "",
          0,
          "Message cites `" & reference & "` with no description; cite each article and duty " &
            "by short description and its reference, as `expression spacing (X.9)` (GUIDE.md, " &
            "Output contract).",
        )
      i = after


func checkEndTurn*(message, branch: string): seq[Finding] =
  ## Report end of turn that pushed or posted: sign-off once delegate stops, else working line.
  ##   Working line is last line holding text, with text after label; reader alone judges
  ##     whether it names what runs and what wakes delegate.
  if message.splitLines.anyIt(it.strip == HEADING_SIGNOFF):
    return checkSignoff(message, branch)
  let last = message.strip.splitLines[^1].strip
  if last.startsWith(LABEL_WORKING) and last[LABEL_WORKING.len .. ^1].strip.len > 0: return
  @[finding(
    "", 0, "Turn that pushed or posted ends with `" & HEADING_SIGNOFF & "` block once done, " &
      "blocked or waiting, or with line `" & LABEL_WORKING & "` while work runs (GUIDE.md, " &
      "Output contract); got neither."
  )]


func reasonStop*(found: openArray[Finding]): string =
  ## Render why `stop` hook refuses message ending turn, one finding to line.
  ##   Message is on screen once hook reads it, so delegate replies with corrected lines
  ##     alone; whole message sent again reads twice (D1 of #570).
  "Mend message that ends this turn (GUIDE.md, Output contract). Reply with corrected lines " &
    "alone; message stands above them, so never send it or its sign-off again:\n" &
    found.mapIt(it.message).join("\n")


func markPath*(root, directory_git: string): string =
  ## Place check mark in git directory, as `git rev-parse --git-dir` names it from root.
  ##   Literal `.git/` fails in worktree, where `.git` is file naming directory under main
  ##     checkout's `.git/worktrees/`. Git names directory relative in main checkout and
  ##     absolute in worktree; either way each checkout holds own mark, since each has own HEAD.
  (if directory_git.isAbsolute: directory_git else: root / directory_git) / MARK_CHECK


func checkPush*(recorded, tree_pushed: string): seq[Finding] =
  ## Report push of tree `koch check` did not pass on.
  if recorded.strip != tree_pushed.strip:
    result.add finding(
      "",
      0,
      "`nim r koch check` must pass on exact commit pushed (CLAUDE.md); last green tree `" &
        recorded.strip & "`; got `" & tree_pushed.strip & "`.",
    )


func checkMessage*(
  branch, message: string; earlier: openArray[string]; staged: openArray[string]
): seq[Finding] =
  ## Report commit breaking subject form, scope, ladder, body or record apart, before it lands.
  ##   Merge commit passes: git writes its subject, and commit check excludes merges upstream
  ##     (`commits.nim`), so duty to merge `main` into branch (CURATOR.md, duty 2) needs no
  ##     bypass of hook.
  ##   Comment lines git adds, and all below its scissors line, are dropped before body is read.
  ##   Subject is first paragraph, its lines joined by one space, as git reads it.
  ##   Earlier subjects give ladder context alone: finding of theirs is `check-commits`' to
  ##     report, and `--amend` keeps old head among them. One earlier finding cancels one same
  ##     finding, so bad subject written again still reports.
  ##   Cost: under `--amend`, ladder reads old head as commit before new one.
  var
    lines_subject, body: seq[string]
    is_subject_read = false
  for line in message.splitLines:
    if line.startsWith("# ------------------------ >8"): break
    if line.startsWith("#"): continue
    if is_subject_read: body.add line
    elif line.strip.len > 0: lines_subject.add line.strip
    elif lines_subject.len > 0:
      is_subject_read = true
      body.add line
  let subject = lines_subject.join(" ")
  if subject.startsWith(SUBJECT_MERGE): return
  var before = checkCommits(branch, earlier).mapIt(it.message)
  for f in checkCommits(branch, @[subject] & @earlier):
    let at = before.find(f.message)
    if at >= 0: before.delete(at)
    else: result.add f
  result.add checkBody(subject, body.join("\n"))
  result.add checkCommitRecord(subject, staged)


func startContext*(branch, contributor, heading_carried: string; drift: seq[Finding]): string =
  ## Compose text `start` adds to context: role, read order, grammar warning, drift, list.
  let parsed = branch.parseBranch
  var lines: seq[string]
  if parsed.isNone:
    lines.add "Branch `" & branch & "` is outside grammar; push to `curator/<name>`, " &
      "`curator/<project>/<name>` or `contributor/<domain>/<project>/<name>` (CLAUDE.md)."
  else:
    let prompt = if parsed.get.role == Role.Contributor: "CONTRIBUTOR.md" else: "CURATOR.md"
    lines.add "Role: " & parsed.get.roleName & ", on branch `" & branch & "`."
    lines.add "Read first: CONSTITUTION.md, STYLE.md, GLOSSARY.md, then " & prompt &
      ", then GUIDE.md."
  if drift.len > 0:
    lines.add "Base gained charter or checker your branch lacks; merge `origin/main` and " &
      "re-stamp (`check-drift`)."
  lines.add "Turn that pushed or posted ends with `" & HEADING_SIGNOFF & "` once done, " &
    "blocked or waiting, else with line `" & LABEL_WORKING & "` (GUIDE.md, Output contract)."
  lines.add ""
  lines.add heading_carried
  lines.add contributor.section(heading_carried).strip
  lines.join("\n")


func isTurnWriting*(calls: openArray[Call]): bool =
  ## Decide whether turn pushed or posted: `git push` in Bash, GitHub write with body, or
  ##   `gh api` write with body in Bash.
  ##   Label or draft update carries no body and is no post, as `body` and `bash` hooks read it.
  ##   Cost: `--input` file counts as body, since stop reads no file; JSON holding none still
  ##     asks turn for sign-off or working line.
  for c in calls:
    if isPost(c.name, c.has_body): return true
    if c.name != "Bash": continue
    if c.command.commandsGit.anyIt(it.len > 0 and it[0] == "push"): return true
    if c.command.requests("").anyIt(it.isPost): return true
  false


proc parseTurn*(transcript: string): Turn =
  ## Read tool calls since last message person wrote, and text of last assistant message.
  ##   Transcript is JSON lines; message of person is `user` entry holding text and no tool
  ##   result, since tool results arrive as `user` entries too.
  var entries: seq[JsonNode]
  for line in transcript.splitLines:
    if line.strip.len == 0: continue
    try: entries.add line.parseJson
    except JsonParsingError, ValueError: discard
  var start = 0
  for i, e in entries:
    if e{"type"}.getStr != "user": continue
    let content = e{"message", "content"}
    if content == nil: continue
    if content.kind == JString: start = i
    elif content.kind == JArray and
        content.getElems.anyIt(it{"type"}.getStr == "text") and
        not content.getElems.anyIt(it{"type"}.getStr == "tool_result"):
      start = i
  for e in entries[start .. ^1]:
    if e{"type"}.getStr != "assistant": continue
    let content = e{"message", "content"}
    if content == nil or content.kind != JArray: continue
    var text: seq[string]
    for item in content.getElems:
      case item{"type"}.getStr
      of "tool_use":
        result.calls.add Call(
          name: item{"name"}.getStr,
          command: item{"input", "command"}.getStr,
          has_body: item{"input", "body"} != nil,
        )
      of "text": text.add item{"text"}.getStr
      else: discard
    if text.len > 0: result.text = text.join("\n")
