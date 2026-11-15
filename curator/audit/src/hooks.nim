## Decide what each Claude Code hook answers, from fact hook event and git hand it.
##   Hook is mechanism and not rule: it calls koch verb and holds no rule of its own
##     (CURATOR.md, What no check can reach). Every finding here is one audit already states
##     for gate; this module reads hook's fact and names check holding it, so rule lives once.
##   Events, by verb argument: `path` refuses write inside repository and outside branch scope;
##     `edit` returns static findings after write; `bash` refuses commit or push on `main` or
##     outside grammar, rewrite of pushed history, and push past pre-push hook, since `koch check`
##     holds what each project clears on its own branch (duty 3); `body` holds post before it
##     lands to role line, Simplified Technical English counts, issue title and label,
##     pull request headings, and closing keyword before issue on line of its own alone; `stop`
##     refuses end of turn that pushed or posted and closes with neither sign-off block nor
##     working line, sign-off out of shape whatever its turn did, end of any turn whose message
##     names `#N` outside link or cites charter reference with no description, and sign-off
##     from turn that read no open issue of its role; `start` prints role, read order, each
##     finding of drift, headings of record branch works on, and carried list; `prompt` reads
##     each message of Architect; `push` and `msg` serve git hooks.
##   `path` and `edit` judge file inside repository alone: file outside it reaches no commit,
##     so both pass it unread, as Architect approved on #847. Both read file through
##     `fileWritten`: path `pathWritten` names in normal form, through each link `pathReal`
##     resolves (#883). So path reads where write tool puts file, since each tool of
##     `TOOLS_EDIT` too drops `..` as text, before link ahead of it resolves (assumed).
##   Hook that sees moment of skill names that skill, as Architect ruled on D2 of #870: `stop`
##     names `/sign-off`, `start` names `/sync` and `/triage`, `edit` names `/propose-term` and
##     `/record`, and `prompt` names `/rule`, `/triage` and `/merged`. Line is hint, never refusal.
##   `gh api` in Bash posts as GitHub tools do, so `bash` reads each `gh api` write, maps it to
##     tool whose rules it shares, and holds its body as `body` holds tool's; `stop` counts it as
##     post. Hook runs before command, so body comes from literal text or file already written:
##     file same command writes, stdin and shell expansion are refused, with finding naming mend.
##   Pure functions take strings and return findings; procs read transcript JSON and body files,
##     since `parseJson` and file reads are effectful. `fileWritten` runs git too, through
##     `checkoutAt`, since git names checkout holding file.
##   `coordinator` is role string with no branch: it opens issues and comments, and no item
##     carries it as label, since brief carries label of role it starts (COORDINATOR.md).
##   Sign-off follows order Architect set (GUIDE.md, Output contract): role, context, rule line,
##     work, summary, state with where branch stands, decisions, next step. Work holds one group
##     for each pull request, its bold line linking it and giving its state, then table of two
##     columns; table of work outside pull request closes it (#844). Phone shows first column
##     alone, so first cell opens with state, number and claim, and second holds evidence or who
##     acts, with tag of each carried rule. Each decision block reads as card, class says what
##     blocks, and each ⚠️ row names role it waits on; coordinator, once trialed, lifts each
##     block onto card unchanged. So shape check holds what Architect decides on: state word,
##     class and place of each decision, two to four short options, and recommendation naming
##     one.
##   Delegate signs off only when done, blocked or waiting, as Architect set (GUIDE.md, Output
##     contract). Turn that ends while work runs closes with working line instead, naming what
##     runs and what wakes delegate, so each state word marks stop and none means work goes on.
##   Sign-off covers all work since last message of Architect, as Architect ruled on #844, so
##     latest one is enough. Each group of pull request in last sign-off that passed comes back,
##     with as many items, until `main` holds its merge or sign-off shows it `closed`, whatever
##     Architect wrote since (`D3 a` of #895); work outside pull request does so inside window
##     alone, since it starts again at each message of Architect. Transcript names message
##     person typed by `origin.kind`, which no wake carries; turn still starts at wake, since
##     what turn did is read from there.
##
##   Cost: hook reaches Claude Code session holding one repository alone, so CI stays gate.
##   Cost: window reads field `origin.kind` of harness; where no entry carries it, window starts
##     with turn, so only sign-offs of that turn are compared, and no group past it.
##   Cost: sign-off whose groups do not read takes findings of its shape alone, so group it drops
##     goes unnamed until next sign-off, which is compared with base before it.
##   Cost: `commandsGit` splits on shell operators by text, so `git` inside quoted string is
##     read as command; refusal then errs on safe side.
##   Cost: post whose body file same command writes, as by heredoc, is refused, so it takes two
##     calls: one writes file, next posts it.
##   Cost: mutation through `gh api graphql` reads as no post, so reading holds its body.
##   Cost: sign-off check reads shape, never whether row or decision says anything; second cell
##     of each row must be non-empty and nothing more, and option need not be honest.
##   Cost: `stop` cannot tell coordinator, which holds no branch, from delegate; where it runs
##     for coordinator, whose message is digest, turn that posted is asked once for sign-off,
##     and second stop passes.

{.experimental: "strictFuncs".}

import std/[json, options, os, sequtils, strutils, uri]
import ./[checker, commits, domains, english, findings, markdown, role, scope]
from ./glossary import GLOSSARY_ROOT
from ./toolchain import DIRECTORY_DRIVER
from ./tree import checkoutAt


type
  Part {.pure.} = enum  ## Define one part of sign-off block, in order block holds them.
    Role, Context, Work, Summary, State, Decisions, Next

  Row = object  ## Define one row of table of sign-off, as its shape check reads it.
    cells: seq[string]  ## Stripped cells; two where row keeps its shape.
    state: int  ## Index in `MARKERS` of state first cell opens with; -1 where none.
    first: int  ## Number after state; 0 where first cell gives none, or no claim after it.
    last: int  ## Last number of fold, as `5` of `☑️ 1–5.`; `first` where row names one item.

  Group = object  ## Define one group of sign-off: pull request and its table, or work outside one.
    line: string  ## Bold line opening group; empty where table opens with none.
    number: int  ## Pull request bold line links; 0 outside pull request; -1 where none reads.
    state: string  ## Word after link, such as `draft`; empty where none reads.
    header: string  ## First line of table under bold line; empty where none.
    rows: seq[Row]  ## Rows under header, separator dropped.

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
    labels*: seq[string]  ## Input `labels`, which list of issues filters on.
    state*: string  ## Input `state`, lowercase, which list of issues filters on; empty where none.

  Turn* = object  ## Define what transcript says about turn since last message of person.
    calls*: seq[Call]  ## Tool calls in order.
    text*: string  ## Text of last assistant message.
    signoffs_earlier*: seq[string]
      ## Text of each earlier message holding sign-off since last message of Architect, in order.
    signoffs_before*: seq[seq[string]]
      ## Text of each sign-off before that message, one list for each window that holds one,
      ##   oldest first; empty where no entry names message of Architect by `origin.kind`.

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
    ## Tools whose body is pull request body, which follows template.
  TOOLS_WRITE* = [
    "mcp__github__add_issue_comment", "mcp__github__issue_write",
    "mcp__github__create_pull_request", "mcp__github__update_pull_request",
    "mcp__github__pull_request_review_write", "mcp__github__add_reply_to_pull_request_comment",
    "mcp__github__update_issue_comment", "mcp__github__add_comment_to_pending_review",
  ]
    ## GitHub tools that post; turn calling one ends with sign-off.
  TOOLS_QUEUE = ["mcp__github__list_issues"]
    ## GitHub tools that list issues by label and state; one such read precedes each sign-off.
  LABEL_QUEUE_COORDINATOR = "architect"
    ## Label whose open items are queue of coordinator, since no item carries its role
    ##   (COORDINATOR.md, section `The queue`).
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
  KEYWORDS_CLOSING = [
    "resolves", "resolved", "resolve", "closes", "closed", "close", "fixes", "fixed", "fix",
  ]
    ## Words GitHub reads before issue as order to close it on merge, in any case and any
    ##   sentence, negated or not; longest first, so `closes` is never read as `close`.
  OPENINGS_ISSUE = ["https://github.com/", "http://github.com/"]
    ## Openings of issue URL GitHub reads after closing keyword, before `<owner>/<repo>/issues/<N>`.
  CHARS_SLUG = IdentChars + {'.', '-'}  ## Characters of owner or repository name.
  HEADING_SIGNOFF* = "## Sign-off"  ## Heading of closing block (GUIDE.md, Output contract).
  TABLE_SIGNOFF* = "| Item | Evidence, or who acts |"
    ## Header row of each table of sign-off, exact; first column reads alone on phone.
  BREAK_SIGNOFF = "---"  ## Rule line opening work of sign-off, after its context.
  LABELS_SIGNOFF: array[Part, string] = [
    "**Role:**", "**Context:**", BREAK_SIGNOFF, "**Summary:**", "**State:**", "**Decisions:**",
    "**Next step:**",
  ]
    ## Parts of block, in order each must appear.
  LABEL_OUTSIDE = "**Outside a pull request.**"
    ## Bold line over table of work outside pull request, which closes work of each sign-off.
  OPENING_PULL = "**["  ## Opening of bold line linking pull request of its group.
  CLOSING_PULL = ".**"  ## Close of bold part of that line, before what pull request does.
  SEGMENT_PULL = "/pull/"  ## Segment of address of pull request, before its number.
  CLOSED = "closed"
    ## State of pull request closed with no merge; its group may drop once sign-off shows it.
  STATES_PULL = ["draft", "ready", "merged", CLOSED]
    ## Words bold line gives after link, as state of its pull request.
  OPENING_MERGE = "Merge pull request #"
    ## Opening of subject GitHub gives merge commit, before number; other form closes `(#N)`.
  KIND_HUMAN = "human"
    ## Kind `origin.kind` of transcript entry gives message person typed, which no wake carries.
  WORD_BRANCH = "branch"  ## Word role line gives before last part of branch.
  OPENING_HEAD = ", at `"  ## Opening of where branch stands, after state word.
  CLOSINGS_STATE = ["`, pushed", "`, not pushed"]  ## Closes of state line, after short head.
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
  BOLD = "**"  ## Mark that opens and closes bold text.
  DECISION_OPENING = "**D"  ## Opening of decision line, before its number.
  DECISION_CLOSING = ".**"  ## Closing of decision number, before question.
  ITEM_CLASS = "- Class:"  ## Item naming class of decision.
  ITEM_WHERE = "- Where:"  ## Item naming issue or pull request where ruling goes.
  ITEM_OPTIONS = "- Options:"  ## Item over lettered options.
  ITEM_RECOMMENDS = "- Recommends:"  ## Item naming letter of option delegate picks, then why.
  OUTSIDE = "outside"  ## Word ⚠️ row opens last cell with where no role acts.
  MARKER_WAIT = "⚠"  ## State marker of row another delegate or outside party acts on.
  MARKER_HOLD = "⏸"  ## State marker of row Architect acts on.
  MARKER_UNNEEDED = "➖"  ## State marker of row naming each carried rule that concerns no item.
  MARKERS* = ["☑", "✅", MARKER_WAIT, MARKER_HOLD, "⬜", MARKER_UNNEEDED]
    ## State markers in sort order, variation selector stripped; first two mark row done.
  STATES_DONE = 0 .. 1  ## Indices in `MARKERS` of states that mark row done, which fold holds.
  SELECTOR = "️"  ## Variation selector some markers carry; stripped before match.
  DASHES_FOLD = ["–", "-"]  ## Marks between first and last number of fold, as `☑️ 1–5.`.
  DIGITS_NUMBER = 9  ## Digits number of row or pull request holds at most, so it parses.
  TAG_CARRIED = "carried "  ## Opening of tag of carried rule in second cell, before its numbers.
  JOINTS_TAG = [", and ", " and ", ", "]
    ## Words between numbers of one tag, as in `carried 1, 2 and 4`; longest first.
  CARRIED_MAX* = 6  ## Rules on carried list (CONTRIBUTOR.md).
  SUBJECT_MERGE = "Merge "  ## Opening of subject git writes for merge commit.
  MARK_CHECK* = "koch-check"
    ## File in git dir where `koch check` writes tree hash it passed on, which `pre-push`
    ##   reads; `pathMark` places it.
  WORD_ROLE = "Role:"  ## Word after bold marker in sign-off role line.
  LINE_RULE* = "The skill /rule records this ruling before you act on it."
    ## Line `prompt` adds where message of Architect rules on decision.
  LINE_TRIAGE* = "The skill /triage reads every open item before you answer."
    ## Line `prompt` adds where message asks where work stands, or what delegate owes.
  LINE_MERGED* = "The skill /merged holds the steps after a merge."
    ## Line `prompt` adds where message reports merge.
  LINE_SIGNOFF* = "The skill /sign-off holds these steps."
    ## Line `stop` adds where it refuses message that holds sign-off.
  LINE_SYNC* = "The skill /sync holds the steps."  ## Close of drift line `start` prints.
  LINE_CARRIED* = "The skill /triage reports each item of this list that is not met."
    ## Line `start` prints under carried list.
  LINE_GLOSSARY* = "A glossary takes only a term that the Architect selected; the skill " &
    "/propose-term holds the steps."
    ## Line `edit` adds after write to glossary.
  LINE_RECORD* = "The skill /record holds the steps, and the agent record-reviewer reads " &
    "the diff."
    ## Line `edit` adds after write to record.
  PHRASES_STATUS = [
    "status", "merge order", "next step", "next steps", "priority list", "update the list",
    "duties", "duty", "anything left",
  ]
    ## Phrases of message of Architect that asks where work stands, or what delegate owes.
  WORD_MERGED = "merged"  ## Word of message of Architect that reports merge.
  LETTERS_OPTION = {'a' .. 'd'}  ## Letters that name option of decision.


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


func pathWritten*(tool_input: JsonNode, directory: string): string =
  ## Read path write names, absolute and in normal form: `file_path`, else `notebook_path`
  ##   NotebookEdit sends, resolved against directory call runs in.
  ##   Normal form drops `.`, `..` and doubled slash, so `<root>//x` never reads as `/x`, and
  ##     `..` from folder outside root never reads as outside.
  let named = tool_input{"file_path"}.getStr(tool_input{"notebook_path"}.getStr)
  normalizedPath(if named.isAbsolute: named else: directory / named)


proc pathReal*(path: string): string =
  ## Read path through each symbolic link in it, as file system writes it and as git names top
  ##   of checkout; path stays as given where file system refuses read.
  ##   Nearest part that exists resolves: file that exists resolves whole, new file its directory.
  ##   Cost: up to two `stat` calls for each part tried, then one `realpath`, for each write
  ##     (PROVENANCE.md, Paths of write hooks, has figures). Link to file not yet written,
  ##     and hard link, read where path names them.
  var at = path
  while at.len > 1 and not (fileExists(at) or dirExists(at)): at = at.parentDir
  try: expandFilename(at) / path[at.len .. ^1].strip(trailing = false, chars = {'/'})
  except OSError: path


proc fileWritten*(
  root, directory: string; tool_input: JsonNode
): Option[tuple[checkout, path: string]] =
  ## Read checkout of this repository holding file write names, and path of file inside it, as
  ##   `path` judges it and `edit` audits it.
  ##   None where file lies in other repository, or outside every checkout of this one: no commit
  ##     of root reaches it, so `path` passes it, and `edit` names nothing and audits nothing for
  ##     it, since audit costs seconds for each write.
  let
    file = pathWritten(tool_input, directory).pathReal
    checkout = checkoutAt(root, file.parentDir)
  if checkout.isNone: return
  let path = insideRoot(checkout.get, file)
  if path.isAbsolute: return
  some((checkout: checkout.get, path: path))


func checkPathEdit*(branch, path: string): seq[Finding] =
  ## Report write outside scope branch names, before it happens.
  ##   Path `insideRoot` hands on whole lies outside root, so it passes, since no commit reaches
  ##     it. `koch check` holds each path branch changed before push, and `check-scope` holds
  ##     them on pull request.
  if path.isAbsolute: return
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
        "Never push past pre-push hook; `koch check` holds what each project clears on its own " &
          "branch (CURATOR.md, duty 3); got `git push --no-verify`.",
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


func tool(action, endpoint: string): string =
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


func toRequest(arguments: openArray[Word], directory: string): Request =
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
  result.tool = tool(result.action, result.endpoint)


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
        result.add toRequest(words[i + 2 .. ^1], working)
        break


func isPost*(request: Request): bool =
  ## Decide whether `gh api` request posts text: write tool's rules hold, carrying body.
  isPost(request.tool, request.has_body)


func blankComments(text: string): string =
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


func stopIssue(text: string, at: int): int =
  ## Read issue reference opening at `at` of text: `#N`, `<owner>/<repo>#N`, or issue URL.
  ##   Return index past it; `-1` where none opens there, or word character runs on after `N`.
  var i = at
  for opening in OPENINGS_ISSUE:
    if text.continuesWith(opening, at):
      i = at + opening.len
      for part in 0 .. 1:
        let start = i
        while i < text.len and text[i] in CHARS_SLUG: inc i
        if i == start or i >= text.len or text[i] != '/': return -1
        inc i
      if not text.continuesWith("issues/", i): return -1
      i += "issues/".len
  if i == at:
    while i < text.len and text[i] in CHARS_SLUG: inc i
    if i > at:
      if i >= text.len or text[i] != '/': return -1
      inc i
      let start = i
      while i < text.len and text[i] in CHARS_SLUG: inc i
      if i == start: return -1
    if i >= text.len or text[i] != '#': return -1
    inc i
  let start = i
  while i < text.len and text[i] in Digits: inc i
  if i == start or (i < text.len and text[i] in IdentChars): -1 else: i


iterator phrasesClosing(text: string): tuple[start, issue, stop: int] =
  ## Yield span of each closing keyword of text with issue after it, as GitHub reads them:
  ##   keyword as whole word in any case, optional colon, whitespace across line break, issue.
  var i = 0
  while i < text.len:
    var (issue, stop) = (-1, -1)
    if text[i] in Letters and (i == 0 or text[i - 1] notin IdentChars):
      for keyword in KEYWORDS_CLOSING:
        var j = i + keyword.len
        if j > text.len or text[i ..< j].toLowerAscii != keyword: continue
        if j < text.len and text[j] in IdentChars: continue
        if j < text.len and text[j] == ':': inc j
        while j < text.len and text[j] in Whitespace: inc j
        if j > i + keyword.len: (issue, stop) = (j, text.stopIssue(j))
        break
    if stop < 0: inc i
    else:
      yield (i, issue, stop)
      i = stop


func checkClosing(body: string): seq[Finding] =
  ## Report closing keyword before issue anywhere but on line whose whole text it is, as
  ##   `Closes #859`. GitHub closes issue on merge whatever sentence says, so "does not close
  ##   #859" closes #859, as body of #860 did. Code spans and fenced code close nothing.
  let text = body.fencedOut.splitLines.mapIt(it.blankSpansCode).join("\n")
  for (start, at, stop) in text.phrasesClosing:
    let
      phrase = text[start ..< stop]
      issue = text[at ..< stop]
      opening = text.rfind('\n', last = start) + 1
    var closing = text.find('\n', stop)
    if closing < 0: closing = text.len
    if '\n' notin phrase and text[opening ..< closing].strip == phrase: continue
    result.add finding(
      "",
      0,
      "Body holds closing keyword before issue only on line of its own, as `Closes " & issue &
        "`, since GitHub closes issue whatever sentence says; drop keyword, or put issue " &
        "first, as `" & issue & " stays open`; got `" & phrase.splitWhitespace.join(" ") & "`.",
    )


func checkBody*(
  tool, branch, title, body: string; labels: openArray[string]; is_create: bool
): seq[Finding] =
  ## Report post that breaks what every post keeps, before it lands.
  let parsed = branch.parseBranch
  if parsed.isSome:
    let expected = KEY_ROLE & " " & parsed.get.nameRole
    if body.lineRole != expected:
      result.add finding(
        "",
        0,
        "Post must open with `" & expected & "`; got " & body.openingQuoted & ".",
      )
  if tool in TOOLS_PULL or tool == "mcp__github__issue_write": result.add checkClosing(body)
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
    let shown = body.section(HEADINGS_PULL[2]).blankComments.strip
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


func numberAt(text: string, at: int): tuple[number, stop: int] =
  ## Read number whose digits open at byte `at` of text, and index past them; `stop` is `at`
  ##   where no digit opens there, or where digits run past `DIGITS_NUMBER`.
  var stop = at
  while stop < text.len and text[stop] in Digits: inc stop
  if stop == at or stop - at > DIGITS_NUMBER: return (0, at)
  (text[at ..< stop].parseInt, stop)


func spanTag(cell: string, at: int): tuple[numbers: seq[int], stop: int] =
  ## Read numbers of tag of carried rule opening at byte `at` of cell, as `carried 3 and 4`, and
  ##   index past last one; none where no number follows, so word in prose opens no tag.
  var i = at + TAG_CARRIED.len
  while true:
    let (number, stop) = cell.numberAt(i)
    if stop == i: return
    result.numbers.add number
    result.stop = stop
    i = -1  # Index of next number; none until joint before one reads.
    for joint in JOINTS_TAG:
      let next = stop + joint.len
      if cell.continuesWith(joint, stop) and cell.numberAt(next).stop > next:
        i = next
        break
    if i < 0: return


func tagsCarried(cell: string): seq[int] =
  ## Read numbers of each tag of carried rule in cell, as `carried 5` or `carried 3 and 4`.
  ##   Tag opens cell or follows character no word holds, so `uncarried 3` names none.
  var at = cell.find(TAG_CARRIED)
  while at >= 0:
    if at == 0 or cell[at - 1] notin Letters: result.add cell.spanTag(at).numbers
    at = cell.find(TAG_CARRIED, at + 1)


func actorRow(cell: string): string =
  ## Read word second cell of row opens with, past tag of carried rule that opens it.
  var text = cell
  if text.startsWith(TAG_CARRIED):
    let span = text.spanTag(0)
    if span.numbers.len > 0: text = text[span.stop .. ^1].strip(chars = Whitespace + {',', ':'})
  if text.len == 0: "" else: text.splitWhitespace[0].strip(chars = {',', ':'})


func decisionsIn(lines: openArray[string]): seq[Decision] =
  ## Read each `**D<n>.**` block of lines, with items under it, in order.
  ##   Option is item opening `- <letter>.` below `Options:`, at any indent, so flat list
  ##     reads as nested one does.
  ##   Item is read with bold taken out, since card sets label of each option and letter of
  ##     pick in bold (#844), and bold changes no word that shape check reads.
  for line in lines:
    let raw = line.strip
    if raw.startsWith(DECISION_OPENING) and raw.len > DECISION_OPENING.len and
        raw[DECISION_OPENING.len] in Digits:
      var close = DECISION_OPENING.len
      while close < raw.len and raw[close] in Digits: inc close
      result.add Decision(
        number: raw[DECISION_OPENING.len ..< close].parseInt,
        question:
          if raw.continuesWith(DECISION_CLOSING, close):
            raw[close + DECISION_CLOSING.len .. ^1].strip
          else: "",
      )
      continue
    if result.len == 0: continue
    let s = raw.replace(BOLD, "")
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


func toRow(cells: seq[string]): Row =
  ## Read row of table: state first cell opens with, then number or fold, period and claim.
  ##   `first` stays 0 where any of them is missing, so shape check names first cell whole.
  result = Row(cells: cells, state: -1)
  if cells.len == 0: return
  let text = cells[0].replace(SELECTOR, "")
  for k, marker in MARKERS:
    if not text.startsWith(marker): continue
    result.state = k
    var at = marker.len
    while at < text.len and text[at] == ' ': inc at
    let (first, after_first) = text.numberAt(at)
    if after_first == at: return
    var (last, stop) = (first, after_first)
    for dash in DASHES_FOLD:
      if text.continuesWith(dash, stop):
        let fold = text.numberAt(stop + dash.len)
        if fold.stop > stop + dash.len: (last, stop) = fold
        break
    if text.continuesWith(".", stop) and text[stop + 1 .. ^1].strip.len > 0:
      (result.first, result.last) = (first, last)
    return


func toGroup(line: string): Group =
  ## Read bold line opening group: work outside pull request, or link to pull request and state.
  ##   Number stays -1 where line links no pull request, and state empty where no word follows
  ##     link inside bold.
  if line == LABEL_OUTSIDE: return Group(line: line, number: 0)
  result = Group(line: line, number: -1)
  let middle = line.find("](")
  if not line.startsWith(OPENING_PULL) or middle < 0: return
  let close = line.find(')', middle + 2)
  if close < 0: return
  let
    address = line[middle + 2 ..< close]
    at = address.find(SEGMENT_PULL)
  if at < 0: return
  let (number, stop) = address.numberAt(at + SEGMENT_PULL.len)
  if stop == at + SEGMENT_PULL.len: return
  result.number = number
  let rest = line[close + 1 .. ^1]
  if not rest.startsWith(", ") or CLOSING_PULL notin rest: return
  var i = 2
  while i < rest.len and rest[i] in Letters: inc i
  result.state = rest[2 ..< i]


func groupsIn(lines: openArray[string]): seq[Group] =
  ## Read groups of work of sign-off in order: each bold line, then rows of its table.
  ##   Table line before any bold line opens group with none, which shape check refuses; other
  ##     line, as text of bold line wrapped onto next, is passed over.
  for line in lines:
    let s = line.strip
    if s.startsWith(BOLD): result.add s.toGroup
    elif s.startsWith("|"):
      if result.len == 0: result.add Group(number: -1)
      if result[^1].header.len == 0: result[^1].header = s
      else:
        for cells in s.rowsTable: result[^1].rows.add cells.toRow


func partsAt(lines: openArray[string]): array[Part, int] =
  ## Read line each part of sign-off opens on, each searched after part found before it; -1
  ##   where none follows.
  var pos = 0
  for part, label in LABELS_SIGNOFF:
    result[part] = -1
    for j in pos ..< lines.len:
      if lines[j].startsWith(label):
        result[part] = j
        break
    if result[part] >= 0: pos = result[part] + 1


func linesWork(lines: seq[string], starts: array[Part, int]): seq[string] =
  ## Read lines of work of sign-off: after its rule line up to summary, or after context where
  ##   rule line is missing, so its groups still read.
  let opening = if starts[Part.Work] >= 0: starts[Part.Work] else: starts[Part.Context]
  lines[opening + 1 ..< starts[Part.Summary]]


func findingsRows(groups: seq[Group], numbers: openArray[int]): seq[Finding] =
  ## Report rows out of shape: cells, state, number, order, evidence, who acts, fold and tag.
  ##   Rows number from 1 across tables, and sort by state inside each table. ⚠️ row opens
  ##     second cell with role that acts, or `outside`, so coordinator sees which delegate
  ##     blocks which; ⏸️ row names decision it waits on, so its card carries it.
  ##   Table whose header is out of shape is named alone, since its rows cannot be read.
  var is_readable = true
  for g in groups:
    if g.header == TABLE_SIGNOFF: continue
    is_readable = false
    result.add finding(
      "",
      0,
      "Sign-off table opens with header `" & TABLE_SIGNOFF & "`; got `" &
        (if g.header.len == 0: "none" else: g.header.shortened) & "`.",
    )
  if not is_readable: return
  var
    expected = 1  # Number next row takes.
    unneeded = 0  # ➖ rows so far.
  for g in groups:
    var last = 0  # State of row before, in this table.
    for row in g.rows:
      if row.cells.len != 2:
        result.add finding(
          "",
          0,
          "Sign-off row holds two cells, `Item` and `Evidence, or who acts`; got `" &
            $row.cells.len & "`.",
        )
        continue
      if row.state < 0:
        let word = if row.cells[0].len == 0: "" else: row.cells[0].splitWhitespace[0]
        result.add finding(
          "",
          0,
          "Sign-off row opens first cell with state, one of ☑️ ✅ ⚠️ ⏸️ ⬜ ➖; got `" & word & "`.",
        )
        continue
      if row.first == 0:
        result.add finding(
          "",
          0,
          "Sign-off row opens first cell with state, number and claim, as `✅ 3. A test covers " &
            "each rafsi form`; got `" & row.cells[0].shortened & "`.",
        )
        continue
      let
        name = $row.first
        marker = MARKERS[row.state]
        evidence = row.cells[1]
      if row.first != expected or row.last < row.first:
        result.add finding(
          "",
          0,
          "Sign-off rows are numbered from 1 in order across its tables; got `" & name & "`.",
        )
      expected = max(row.first, row.last) + 1
      if row.state < last:
        result.add finding(
          "",
          0,
          "Sign-off states sort ☑️ ✅ ⚠️ ⏸️ ⬜ ➖ inside each table; got `" &
            row.cells[0].splitWhitespace[0] & "` after later state.",
        )
      else: last = row.state
      if row.last > row.first and row.state notin STATES_DONE:
        result.add finding(
          "",
          0,
          "Sign-off folds done rows alone, as `☑️ 1–5.`; got `" & row.cells[0].splitWhitespace[0] &
            "` in row `" & name & "`.",
        )
      if evidence.len == 0:
        result.add finding(
          "",
          0,
          "Sign-off row holds evidence, or who acts, in its second cell; got empty cell in row `" &
            name & "`.",
        )
      let actor = evidence.actorRow
      if marker == MARKER_WAIT and actor != OUTSIDE and not actor.isStringRole:
        result.add finding(
          "",
          0,
          "Sign-off ⚠️ row opens second cell with role string or `" & OUTSIDE & "`, after any " &
            "carried tag; got `" & actor & "` in row `" & name & "`.",
        )
      let named = evidence.numbersDecision
      if marker == MARKER_HOLD and (named.len == 0 or named.anyIt(it notin numbers)):
        result.add finding(
          "",
          0,
          "Sign-off ⏸️ row names decision it waits on as `D<n>`; got `" & evidence & "` in row `" &
            name & "`.",
        )
      if marker == MARKER_UNNEEDED:
        inc unneeded
        if g.number != 0:
          result.add finding(
            "",
            0,
            "Sign-off ➖ row stands in table `" & LABEL_OUTSIDE & "`; got it in row `" & name & "`.",
          )
        if evidence.tagsCarried.len == 0:
          result.add finding(
            "",
            0,
            "Sign-off ➖ row names each carried rule that concerns no item by its tag, as " &
              "`carried 3 and 4`; got `" & evidence.shortened & "` in row `" & name & "`.",
          )
      for n in evidence.tagsCarried:
        if n < 1 or n > CARRIED_MAX:
          result.add finding(
            "",
            0,
            "Carried tag names rule 1 to " & $CARRIED_MAX & "; got `" & $n & "`.",
          )
  if unneeded > 1:
    result.add finding("", 0, "Sign-off holds one ➖ row; got `" & $unneeded & "`.")


func findingsCarried(groups: seq[Group]): seq[Finding] =
  ## Report carried rule that no row names, or that stands beside item and in ➖ row too.
  ##   Rule may stand beside two items, as one rule can concern two pull requests. Table whose
  ##     header is out of shape is unread, so no rule is reported for it.
  if groups.anyIt(it.header != TABLE_SIGNOFF): return
  var beside, unneeded: seq[int]
  for g in groups:
    for row in g.rows:
      if row.cells.len != 2: continue
      for n in row.cells[1].tagsCarried:
        if row.state >= 0 and MARKERS[row.state] == MARKER_UNNEEDED: unneeded.add n
        else: beside.add n
  for n in unneeded:
    if n in beside:
      result.add finding(
        "",
        0,
        "Carried rule stands beside item it concerns, or in ➖ row, and never in both; got `" &
          $n & "`.",
      )
  let missing = toSeq(1 .. CARRIED_MAX).filterIt(it notin beside and it notin unneeded)
  if missing.len > 0:
    result.add finding(
      "",
      0,
      "Sign-off names each carried rule beside item it concerns, or in ➖ row (CONTRIBUTOR.md, " &
        "Carry the unchecked list in the open); got none for `" & missing.mapIt($it).join(", ") &
        "`.",
    )


func findingsWork(groups: seq[Group], numbers: openArray[int]): seq[Finding] =
  ## Report work of sign-off out of shape: its groups, then rows and carried rules of its tables.
  ##   Each pull request takes one group, whose bold line links it and gives its state, and work
  ##     outside one takes last table, once, even where ➖ row is its only row (#844).
  var
    outside = 0  # Groups of work outside pull request, so far.
    seen: seq[int]  # Pull requests that group links, so far.
  for g in groups:
    if g.line.len == 0:
      result.add finding(
        "",
        0,
        "Sign-off table follows bold line of its group (GUIDE.md, The table); got `" &
          g.header.shortened & "`.",
      )
    elif g.number < 0 or (g.number > 0 and g.state.len == 0):
      result.add finding(
        "",
        0,
        "Sign-off group opens with bold line that links its pull request and gives its state, " &
          "as `**[Lujvo search (#912)](url), draft.**`, or with `" & LABEL_OUTSIDE & "`; got `" &
          g.line.shortened & "`.",
      )
    elif g.number > 0 and g.state notin STATES_PULL:
      result.add finding(
        "",
        0,
        "Pull request state on bold line is one of " & STATES_PULL.join(", ") & "; got `" &
          g.state & "`.",
      )
    if g.number == 0: inc outside
    elif outside > 0:
      result.add finding(
        "",
        0,
        "Sign-off puts table `" & LABEL_OUTSIDE & "` after each group of pull request; got `" &
          g.line.shortened & "` after it.",
      )
    if g.number > 0:
      if g.number in seen:
        result.add finding(
          "",
          0,
          "Sign-off holds one group for each pull request; got `#" & $g.number & "` twice.",
        )
      else: seen.add g.number
  if outside != 1:
    result.add finding(
      "",
      0,
      "Sign-off holds table `" & LABEL_OUTSIDE & "` once, even where ➖ row is its only row; " &
        "got `" & $outside & "`.",
    )
  result.add findingsRows(groups, numbers)
  result.add findingsCarried(groups)


func isStateRest(text: string): bool =
  ## Decide whether text after state word gives where branch stands alone: short head, then
  ##   `pushed` or `not pushed`, since bold line of each pull request gives its state and run.
  if not text.startsWith(OPENING_HEAD): return false
  let close = text.find('`', OPENING_HEAD.len)
  close > OPENING_HEAD.len and text[OPENING_HEAD.len ..< close].allCharsInSet(HexDigits) and
    text[close .. ^1] in CLOSINGS_STATE


func atSignoff(message: string): int =
  ## Read index of line holding heading of last sign-off of message; -1 where none.
  ##   Heading inside fence is quoted example, so it opens no sign-off.
  result = -1
  let lines = message.fencedOut.splitLines
  for i, line in lines:
    if line.strip == HEADING_SIGNOFF: result = i


func isSignoff*(message: string): bool =
  ## Decide whether message holds sign-off: its heading, outside fence.
  message.atSignoff >= 0


func checkSignoff*(message, branch: string): seq[Finding] =
  ## Report message that lacks sign-off block, or holds it out of shape.
  ##   Missing rule line is named, and work still reads from line after context, so table of
  ##     form before #844 is named for what it lacks.
  let
    lines = message.splitLines
    at = message.atSignoff
  if at < 0:
    return @[finding(
      "", 0, "Message holds no `" & HEADING_SIGNOFF & "` block (GUIDE.md, Output contract)."
    )]
  let
    after = lines[at + 1 .. ^1]
    starts = after.partsAt
  for line in after:
    if line.startsWith("#"):
      result.add finding("", 0, "Nothing follows sign-off; got heading `" & line & "`.")
  for part, label in LABELS_SIGNOFF:
    if starts[part] < 0:
      result.add finding("", 0, "Sign-off lacks `" & label & "` in its order; got none.")
  var readable = starts
  readable[Part.Work] = 0  # Work reads after context where its rule line is missing.
  if readable.anyIt(it < 0): return

  template rest(part: Part): string =
    after[starts[part]][LABELS_SIGNOFF[part].len .. ^1].strip

  let
    rest_role = Part.Role.rest
    text_role = rest_role.split(',')[0].strip
    parsed = branch.parseBranch
    rest_state = Part.State.rest
    word_state = rest_state.split({',', ' '})[0]
    decisions = decisionsIn(after[starts[Part.Decisions] + 1 ..< starts[Part.Next]])
  if parsed.isSome:
    let tail = ", " & WORD_BRANCH & " `" & parsed.get.name & "`"
    if text_role != parsed.get.nameRole:
      result.add finding(
        "",
        0,
        "Sign-off role must be `" & parsed.get.nameRole & "`; got `" & text_role & "`.",
      )
    elif rest_role[text_role.len .. ^1] != tail:
      result.add finding(
        "",
        0,
        "Sign-off role line closes with word `" & WORD_BRANCH & "` and last part of branch, as `" &
          tail & "`; got `" & rest_role[text_role.len .. ^1] & "`.",
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
  if word_state in STATES_SIGNOFF and not rest_state[word_state.len .. ^1].isStateRest:
    result.add finding(
      "",
      0,
      "Sign-off state line gives state word, short head and `pushed` or `not pushed` alone, as " &
        "`blocked, at `3f2a9c1`, pushed`, and leaves pull request and run to its bold line; " &
        "got `" & rest_state.shortened & "`.",
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
  result.add findingsWork(after.linesWork(starts).groupsIn, decisions.mapIt(it.number))
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


func numbersMerged(subjects: openArray[string]): seq[int] =
  ## Read number of each pull request whose merge subject names, in either form GitHub writes:
  ##   `(#N)` at its end, or `Merge pull request #N` at its start.
  for subject in subjects:
    let
      s = subject.strip
      open = s.rfind("(#")
    if open >= 0 and s.endsWith(")"):
      let (number, stop) = s.numberAt(open + 2)
      if stop > open + 2 and stop == s.high: result.add number
    if s.startsWith(OPENING_MERGE):
      let (number, stop) = s.numberAt(OPENING_MERGE.len)
      if stop > OPENING_MERGE.len: result.add number


func groupsSignoff(message: string): seq[Group] =
  ## Read groups of last sign-off of message; none where block lacks part other than rule line.
  let at = message.atSignoff
  if at < 0: return
  let
    after = message.splitLines[at + 1 .. ^1]
    starts = after.partsAt
  var readable = starts
  readable[Part.Work] = 0  # Work reads after context where its rule line is missing.
  if readable.anyIt(it < 0): return
  after.linesWork(starts).groupsIn


func count(g: Group): int =
  ## Count items group holds: each row once, fold as each item it names, and ➖ row as none.
  for row in g.rows:
    if row.state >= 0 and MARKERS[row.state] == MARKER_UNNEEDED: continue
    result += (if row.first > 0 and row.last >= row.first: row.last - row.first + 1 else: 1)


func findingsGroups(
  message, base: string; merged: openArray[int]; is_window_same: bool
): seq[Finding] =
  ## Report group of base that message drops or shrinks: each one comes back, with as many items,
  ##   until `main` holds merge of its pull request, or base shows it `closed`.
  ##   Work outside pull request starts again at each message of Architect, so its group is read
  ##     only where base sits in window of message; group of pull request is read past it
  ##     (`D3 a` of #895).
  ##   Group is matched by number of its pull request and counted, since item may change words
  ##     (Question 2 of #844); so row moves to no other group. Finding quotes first cell of each
  ##     row group held, since compaction may have taken them from what delegate sees.
  ##   Message whose groups do not read, as one lacking part or linking no pull request, gives
  ##     none, since group it holds would read as dropped; its shape check names what is wrong.
  let now = message.groupsSignoff
  if now.len == 0 or now.anyIt(it.number < 0): return
  for b in base.groupsSignoff:
    if b.number < 0 or (b.number == 0 and not is_window_same): continue
    var at = -1
    for i, g in now:
      if g.number == b.number: at = i
    let held = b.rows
      .filterIt(it.cells.len > 0 and (it.state < 0 or MARKERS[it.state] != MARKER_UNNEEDED))
      .mapIt("`" & it.cells[0] & "`")
      .join(", ")
    if at < 0:
      if b.number == 0 or b.number in merged or b.state == CLOSED: continue
      result.add finding(
        "",
        0,
        "Sign-off keeps group of each pull request until `origin/main` holds its merge or one " &
          "sign-off shows it `" & CLOSED & "` (GUIDE.md, The table); got none for `#" &
          $b.number & "`, which held " & held & ".",
      )
    elif now[at].count < b.count:
      let name = if b.number == 0: LABEL_OUTSIDE.strip(chars = {'*'}) else: "#" & $b.number
      result.add finding(
        "",
        0,
        "Sign-off keeps each item of group that sign-off before it held, folded past twelve " &
          "rows (GUIDE.md, The table); got `" & $now[at].count & "` items in `" & name &
          "`, which held `" & $b.count & "`: " & held & ".",
      )


func checkSignoffWindow*(
  message, branch: string; earlier, subjects: openArray[string]; before: openArray[seq[string]] = []
): seq[Finding] =
  ## Report sign-off that drops or shrinks group of last sign-off that passed: group of pull
  ##   request whatever Architect wrote since (`D3 a` of #895), and work outside one since last
  ##   message of Architect alone, so latest sign-off is enough (#844).
  ##   `earlier` holds sign-offs of this window, and `before` those of each window before it,
  ##     oldest first. Earlier sign-off passed where its block keeps its shape, and its groups
  ##     keep those of one that passed before it by same rule; replay of those verdicts over each
  ##     window finds base, and no field of harness is read.
  ##   Merge shows in first-parent subject of `main` that koch hands in, at no cost to shared
  ##     allowance; close shows on GitHub alone, so its group shows `closed` once, then drops.
  ##   Cost: verdict of block alone is replayed, so sign-off refused only for bare number or
  ##     reference serves as base, as its rows stand whole.
  let merged = subjects.numbersMerged
  var
    base = ""
    window_base = -1  # Window base sits in, counted from oldest; this one is `before.len`.
  for window, signoffs in @before & @[@earlier]:
    for s in signoffs:
      if checkSignoff(s, branch).len > 0: continue
      if findingsGroups(s, base, merged, is_window_same = window == window_base).len == 0:
        (base, window_base) = (s, window)
  findingsGroups(message, base, merged, is_window_same = window_base == before.len)


func labelDefined(line: string): string =
  ## Read label that line defines as `[label]: url`, lowercased; empty where it defines none.
  let s = line.strip(trailing = false)
  if line.len - s.len > 3 or not s.startsWith("["): return ""
  let close = s.find(']')
  if close < 2 or not s[close + 1 .. ^1].startsWith(":") or s[close + 2 .. ^1].strip.len == 0:
    return ""
  s[1 ..< close].toLowerAscii


func linksOut(line: string, labels: openArray[string]): string =
  ## Blank each link of line (`spansLink`); bracket opening no link stays text.
  result = line
  for (start, stop) in line.spansLink(labels):
    for k in start ..< stop: result[k] = ' '


func numbersAt(text: string): seq[(int, string)] =
  ## Read each `#N` of text with its index. `#` after word character, `&` or `/` opens no
  ##   number: `&#N;` is character reference, `x#N` fragment or name in other repository.
  var i = 0
  while i < text.len:
    let is_number = text[i] == '#' and i + 1 < text.len and text[i + 1] in Digits and
      (i == 0 or text[i - 1] notin IdentChars + {'&', '/'})
    if not is_number:
      inc i
      continue
    var j = i + 1
    while j < text.len and text[j] in Digits: inc j
    result.add (i, text[i ..< j])
    i = j


func checkNumbersBare*(message: string): seq[Finding] =
  ## Report each `#N` of message that stands bare before any link holding it (GUIDE.md, Output
  ##   contract). First mention is link, as `[the ledger fix (#456)](url)`, and after it `#456`
  ##   alone names same item, as Claude Code links it. Row of table names its item in its own
  ##   cells, so number in row is first mention as well.
  ##   Code and links are skipped; definition line `[label]: url` is link too, as is `[label]`
  ##     it defines (`checkLinksReference` reports both). Each number reports once.
  let lines = message.fencedOut.splitLines
  var
    labels: seq[string]
    named: seq[string]  # Numbers that link or row named already.
    seen: seq[string]
  for line in lines:
    let label = line.labelDefined
    if label.len > 0: labels.add label
  for line in lines:
    if line.labelDefined.len > 0: continue
    let
      code_out = line.blankSpansCode
      is_row = line.strip.startsWith("|")
    var linked: seq[(int, string)]  # Start of each link of line, with each number it holds.
    for (start, stop) in code_out.spansLink(labels):
      for (_, number) in code_out[start ..< stop].numbersAt: linked.add (start, number)
    for (at, number) in code_out.linksOut(labels).numbersAt:
      if is_row: named.add number
      elif number notin named and not linked.anyIt(it[0] < at and it[1] == number) and
          number notin seen:
        seen.add number
        result.add finding(
          "",
          0,
          "Message names `" & number & "` bare before any link to it; give first mention as " &
            "one link of short description and number, as `[the ledger fix (#456)](address)`, " &
            "then number alone (GUIDE.md, Output contract).",
        )
    for (_, number) in linked: named.add number


func checkLinksReference*(message: string): seq[Finding] =
  ## Report link message gives by reference (GUIDE.md, Output contract): Claude Code shows
  ##   `[text][label]` as raw text where definition `[label]: url` stands below it, so each link
  ##   is written inline. One finding names first label defined; code is skipped.
  for line in message.fencedOut.splitLines:
    let label = line.labelDefined
    if label.len > 0:
      return @[finding(
        "",
        0,
        "Message gives link `[" & label & "]` by reference; write each link inline, as " &
          "`[the ledger fix (#456)](address)`, since Claude Code shows reference link as raw " &
          "text where its address stands below it (GUIDE.md, Output contract).",
      )]


func checkReferencesBare*(message: string): seq[Finding] =
  ## Report each charter reference of message that stands with no description (GUIDE.md, Output
  ##   contract): article `X.9`, after `Article ` or not, or `duty 3`, capital at sentence start.
  ##   Reference passes inside parentheses where word holding letter stands before opening one,
  ##     on same line, as rule's own examples cite it: `expression spacing (X.9)`. So
  ##     `(X.2, X.9)` after text passes whole, and line or bullet opening with `(` fails.
  ##   Description is given once: reference that message described before passes bare.
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
    described: seq[string]
    seen: seq[string]
  for line in lines:
    let label = line.labelDefined
    if label.len > 0: labels.add label
  for line in lines:
    if line.labelDefined.len > 0: continue
    let text = line.blankSpansCode.linksOut(labels)
    var i = 0
    while i < text.len:
      let after = text.referenceEnd(i)
      if after == i:
        inc i
        continue
      let
        reference = text[i ..< after]
        key = reference.toLowerAscii
      if line.isDescribed(text, i, after): described.add key
      elif key notin described and key notin seen:
        seen.add key
        result.add finding(
          "",
          0,
          "Message cites `" & reference & "` with no description; cite each article and duty " &
            "first by short description and its reference, as `expression spacing (X.9)`, " &
            "then reference alone (GUIDE.md, Output contract).",
        )
      i = after


func checkEndTurn*(message, branch: string; is_writing: bool): seq[Finding] =
  ## Report end of turn: sign-off out of shape, whatever turn did, and turn that pushed or posted
  ##   with neither sign-off nor working line.
  ##   Sign-off can close turn that wrote nothing, so each one takes shape check, as Architect
  ##     ruled on #844. Working line is last line holding text, with text after label; reader
  ##     alone judges whether it names what runs and what wakes delegate.
  if message.isSignoff: return checkSignoff(message, branch)
  if not is_writing: return
  let last = message.strip.splitLines[^1].strip
  if last.startsWith(LABEL_WORKING) and last[LABEL_WORKING.len .. ^1].strip.len > 0: return
  @[finding(
    "", 0, "Turn that pushed or posted ends with `" & HEADING_SIGNOFF & "` block once done, " &
      "blocked or waiting, or with line `" & LABEL_WORKING & "` while work runs (GUIDE.md, " &
      "Output contract); got neither."
  )]


func filtersList(words: openArray[Word]): tuple[labels: seq[string], state: string] =
  ## Read label and state filters of `gh issue list`, from words after `list`.
  ##   Flag takes value as next word, after `=`, or glued to short form, as `gh` reads it;
  ##     labels split on comma.
  var i = 0
  while i < words.len:
    var (flag, value) = (words[i].text, "")
    inc i
    if flag.startsWith("--") and '=' in flag:
      (flag, value) = (flag.split('=', 1)[0], flag.split('=', 1)[1])
    elif flag in ["--label", "-l", "--state", "-s"]:
      if i < words.len: value = words[i].text
      inc i
    elif flag.len > 2 and flag[0 .. 1] in ["-l", "-s"]:
      (flag, value) = (flag[0 .. 1], flag[2 .. ^1])
    case flag
    of "--label", "-l": result.labels.add value.split(',')
    of "--state", "-s": result.state = value.toLowerAscii
    else: discard


func isQueueRead(call: Call, label: string): bool =
  ## Decide whether call lists open issues labelled `label`, or open issues of every label.
  ##   `mcp__github__list_issues` returns both states where input names none; `gh issue list`
  ##     and `gh api` list of `issues` return open issues alone where none is named.
  ##   Cost: read through any other tool, as search, or as `gh api` field `-f labels=`, counts
  ##     for nothing.
  if call.name in TOOLS_QUEUE:
    return call.state != "closed" and (call.labels.len == 0 or label in call.labels)
  if call.name != "Bash": return false

  # Read each `gh issue list` of shell text.
  for words in call.command.wordsShell:
    for i in 0 ..< words.len - 2:
      let name = words[i].text
      if not (name == "gh" or name.endsWith("/gh")): continue
      if words[i + 1].text != "issue" or words[i + 2].text notin ["list", "ls"]: break
      let (labels, state) = words.toOpenArray(i + 3, words.high).filtersList
      if state != "closed" and (labels.len == 0 or label in labels): return true
      break

  # Read each `gh api` list of issues of one repository, its filters in query.
  for request in call.command.requests(""):
    let parts = request.endpoint.split('?', 1)
    if request.action != "GET" or "repos" notin parts[0].split('/') or
        not parts[0].strip(chars = {'/'}).endsWith("/issues"):
      continue
    var (labels, state) = (newSeq[string](), "")
    for pair in (if parts.len > 1: parts[1] else: "").split('&'):
      let (key, value) = (pair.split('=', 1)[0], pair.split('=', 1)[^1].decodeUrl)
      if key == "labels": labels.add value.split(',')
      elif key == "state": state = value.toLowerAscii
    if state != "closed" and (labels.len == 0 or label in labels): return true
  false


func roleSignoff(message: string): string =
  ## Read role string of last sign-off of message: its role line, up to first comma; empty
  ##   where message holds no sign-off, or block no role line.
  let at = message.atSignoff
  if at < 0: return ""
  for line in message.splitLines[at + 1 .. ^1]:
    if line.startsWith(LABELS_SIGNOFF[Part.Role]):
      return line[LABELS_SIGNOFF[Part.Role].len .. ^1].split(',')[0].strip
  ""


func checkSignoffRead*(message: string, calls: openArray[Call]): seq[Finding] =
  ## Report sign-off from turn that read no open issue of its role (GUIDE.md, Output contract).
  ##   Request can arrive while delegate works, and reads at start see none of it (#742).
  ##   Role comes from role line of sign-off; line naming no role string asks nothing here, as
  ##     `checkSignoff` reads its shape. Coordinator reads label `architect` in its place.
  ##   Cost: hook sees that read happened, and never that delegate took what it showed.
  let role = message.roleSignoff
  if not role.isStringRole: return
  let label = if role == COORDINATOR: LABEL_QUEUE_COORDINATOR else: role
  if calls.anyIt(it.isQueueRead(label)): return
  @[finding(
    "", 0, "Sign-off follows read of open issues labelled `" & label & "` in its turn, " &
      "through `mcp__github__list_issues` or `gh issue list`, since request can arrive while " &
      "delegate works (GUIDE.md, Output contract); got none."
  )]


func reasonStop*(found, unread: openArray[Finding]; has_signoff = false): string =
  ## Render why `stop` hook refuses message ending turn, one finding to line.
  ##   Message is on screen once hook reads it, so delegate replies with diff of each error
  ##     alone; whole message sent again reads twice (D1 of #570), and so does each line of it.
  ##   Reply passes unread, since `stop_hook_active` is set, so its `-` line refuses nothing.
  ##   Unread queue takes read in place of diff: what waits there can change sign-off, so
  ##     delegate takes it first and replies with one line naming it (#742).
  ##   Refused message holding sign-off closes with line naming skill that holds its steps.
  var parts: seq[string]
  if found.len > 0:
    parts.add "Mend message that ends this turn (GUIDE.md, Output contract). Reply with a " &
      "diff of each error alone: one `diff` block, each wrong phrase after `-`, that phrase " &
      "mended after `+`. Message stands above it, so never send it, a line of it, or its " &
      "sign-off again:\n" & found.mapIt(it.message).join("\n")
  if unread.len > 0:
    parts.add "Read queue before this sign-off stands (GUIDE.md, Output contract): list open " &
      "issues that line below names, take first what waits there, and reply with one line " &
      "naming it, and no diff:\n" & unread.mapIt(it.message).join("\n")
  if has_signoff: parts.add LINE_SIGNOFF
  parts.join("\n")


func pathMark*(root, directory_git: string): string =
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


func pathRecord*(branch: string): string =
  ## Read path of record branch works on: its project's, or audit's on curator root branch,
  ##   whose work is checker and charter; empty outside grammar.
  let parsed = branch.parseBranch
  if parsed.isNone: return ""
  case parsed.get.role
  of Role.Curator: DIRECTORY_DRIVER & "/" & FILE_RECORD
  of Role.CuratorProject, Role.Contributor: parsed.get.prefix & FILE_RECORD


func contextStart*(
  branch, contributor, heading_carried, record: string; drift: seq[Finding]
): string =
  ## Compose text `start` adds to context: role, read order, grammar warning, drift, headings
  ##   of record, list.
  ##   Drift is each finding of `check-drift`, one to line: sections base changed and command
  ##   that shows them, so start asks for new stamp only where finding does.
  ##   Record is text of file `pathRecord` names; empty where branch has none yet. Delegate
  ##     reads its headings, then each section work touches, and Open questions (GUIDE.md); line
  ##     each heading opens on lets it read that section alone.
  let parsed = branch.parseBranch
  var lines: seq[string]
  if parsed.isNone:
    lines.add "Branch `" & branch & "` is outside grammar; push to `curator/<name>`, " &
      "`curator/<project>/<name>` or `contributor/<domain>/<project>/<name>` (CLAUDE.md)."
  else:
    let prompt = if parsed.get.role == Role.Contributor: "CONTRIBUTOR.md" else: "CURATOR.md"
    lines.add "Role: " & parsed.get.nameRole & ", on branch `" & branch & "`."
    lines.add "Read first: CONSTITUTION.md, STYLE.md, GLOSSARY.md, then " & prompt &
      ", then GUIDE.md."
  if drift.len > 0:
    lines.add "Base changed charter or checker since this branch forked; read each change " &
      "below, then merge `origin/main` (`check-drift`). " & LINE_SYNC
    for f in drift: lines.add "  " & f.render
  lines.add "Turn that pushed or posted ends with `" & HEADING_SIGNOFF & "` once done, " &
    "blocked or waiting, else with line `" & LABEL_WORKING & "` (GUIDE.md, Output contract)."
  if record.len > 0:
    lines.add ""
    lines.add "Record `" & branch.pathRecord & "`: read each section that your work touches, " &
      "and Open questions, from line where its heading opens (GUIDE.md, How to build on a " &
      "project)."
    var line = 1
    for part in record.sections:
      if part.heading.len > 0: lines.add $line & ": " & part.heading
      line += part.text.count('\n')
  lines.add ""
  lines.add heading_carried
  lines.add contributor.section(heading_carried).strip
  lines.add ""
  lines.add LINE_CARRIED
  lines.join("\n")


func wordsPrompt(message: string): seq[string] =
  ## Split message into lowercase words of letters and digits, so punctuation parts no phrase.
  var word = ""
  for c in message.toLowerAscii & " ":
    if c in {'a' .. 'z', '0' .. '9'}: word.add c
    elif word.len > 0:
      result.add word
      word = ""


func isRuling(words: openArray[string]): bool =
  ## Decide whether message rules on decision: it names `D<n>`, or is one option letter alone.
  if words.len == 1 and words[0].len == 1 and words[0][0] in LETTERS_OPTION: return true
  words.anyIt(it.len >= 2 and it[0] == 'd' and it[1] in Digits)


func contextPrompt*(message: string): string =
  ## Compose lines naming each skill whose moment message of Architect holds; empty where none.
  ##   Phrase matches whole words, so `status` matches `status?` and never `statuses`.
  ##   Line is hint and refuses nothing, so word that matches by chance costs one line read.
  ##   Notice of harness opens with tag, as `<task-notification>` does, and Architect asked
  ##     nothing in it, so it takes no line.
  if message.strip.startsWith('<'): return ""
  let
    words = message.wordsPrompt
    text = " " & words.join(" ") & " "
  var lines: seq[string]
  if words.isRuling: lines.add LINE_RULE
  if " " & WORD_MERGED & " " in text: lines.add LINE_MERGED
  if PHRASES_STATUS.anyIt(" " & it & " " in text): lines.add LINE_TRIAGE
  lines.join("\n")


func contextEdit*(path: string): string =
  ## Compose line naming skill whose moment write to path is; empty for any other file.
  let name = path.splitPath.tail
  if name == GLOSSARY_ROOT: LINE_GLOSSARY
  elif name == FILE_RECORD: LINE_RECORD
  else: ""


func contextFindings*(path: string, held, own: openArray[Finding]): string =
  ## Compose lines naming findings write left in path: own ones to fix before push, then held
  ##   ones, which block no push and which their project clears (CURATOR.md, duty 3).
  var parts: seq[string]
  if own.len > 0:
    parts.add "koch check-files reports " & $own.len & " finding(s) in `" & path &
      "`; fix before push:"
    parts.add own.mapIt(it.path & ":" & $it.line & ": " & it.message)
  if held.len > 0:
    parts.add "koch check-files holds " & $held.len & " finding(s) in `" & path &
      "` for its project, which clears them in its next pull request (CURATOR.md, duty 3):"
    parts.add held.mapIt(it.path & ":" & $it.line & ": " & it.message)
  parts.join("\n")


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
  ## Read tool calls since last message person wrote, text of last assistant message, and each
  ##   earlier sign-off: since last message of Architect, and before it by window.
  ##   Transcript is JSON lines; message of person is `user` entry holding text and no tool
  ##     result, since tool results arrive as `user` entries too. Wake arrives same way, so turn
  ##     starts at it, and what turn did reads from there.
  ##   Message of Architect is `user` entry whose `origin.kind` is `human`, as Architect ruled on
  ##     #844; wake carries other kind, or none. Where no entry carries field, window starts with
  ##     turn, as before harness wrote it, and no window before it reads; where none is human,
  ##     window holds whole transcript.
  ##   Each message of Architect opens window, and sign-off before first one sits in window of
  ##     its own; window that holds no sign-off is left out.
  var entries: seq[JsonNode]
  for line in transcript.splitLines:
    if line.strip.len == 0: continue
    try: entries.add line.parseJson
    except JsonParsingError, ValueError: discard
  var
    start = 0
    window = 0
    has_origin = false
    messages: seq[int]  # Index of each message of Architect, in order.
  for i, e in entries:
    if e{"type"}.getStr != "user": continue
    let kind = e{"origin", "kind"}
    if kind != nil:
      has_origin = true
      if kind.getStr == KIND_HUMAN:
        window = i
        messages.add i
    let content = e{"message", "content"}
    if content == nil: continue
    if content.kind == JString: start = i
    elif content.kind == JArray and
        content.getElems.anyIt(it{"type"}.getStr == "text") and
        not content.getElems.anyIt(it{"type"}.getStr == "tool_result"):
      start = i
  if not has_origin: window = start

  # Read calls of turn, its last text, and each assistant text that names heading of sign-off.
  var
    at_message = -1
    texts: seq[tuple[at: int, text: string]]  # Texts naming heading, in order.
  for i in (if has_origin: 0 else: min(start, window)) .. entries.high:
    let e = entries[i]
    if e{"type"}.getStr != "assistant": continue
    let content = e{"message", "content"}
    if content == nil or content.kind != JArray: continue
    var text: seq[string]
    for item in content.getElems:
      case item{"type"}.getStr
      of "tool_use":
        if i < start: continue
        result.calls.add Call(
          name: item{"name"}.getStr,
          command: item{"input", "command"}.getStr,
          has_body: item{"input", "body"} != nil,
          labels: item{"input", "labels"}.getElems.mapIt(it.getStr),
          state: item{"input", "state"}.getStr.toLowerAscii,
        )
      of "text": text.add item{"text"}.getStr
      else: discard
    if text.len == 0: continue
    let joined = text.join("\n")
    if i >= start: (result.text, at_message) = (joined, i)
    if HEADING_SIGNOFF in joined: texts.add (at: i, text: joined)

  # Sort each earlier sign-off into last window, or into window it sits in before that one.
  var opened_last = -1  # Messages of Architect at or before sign-off sorted last.
  for (at, text) in texts:
    if at == at_message or not text.isSignoff: continue
    if at >= window:
      result.signoffs_earlier.add text
      continue
    let opened = messages.countIt(it <= at)
    if opened != opened_last: result.signoffs_before.add newSeq[string]()
    opened_last = opened
    result.signoffs_before[^1].add text


func isSignoffEarlier*(turn: Turn): bool =
  ## Decide whether transcript holds sign-off before last message of turn, in its window or in
  ##   window before it, so stop hook reads subjects of `main` and compares groups of sign-off.
  turn.signoffs_earlier.len > 0 or turn.signoffs_before.len > 0
