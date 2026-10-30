## Run `suggester`: read passage, ask service or recording, print tag checked against lists.
##   `nim r tools/build.nim suggester` compiles it to `binaries/suggester`, with TLS; steps are
##   in `suggestions.nim` and transport in `exchanges.nim`, which this file wires to
##   environment, sockets, files and streams.
##
##   |---------------------------|--------------------------------------------------------|
##   | Usage                     | Effect                                                 |
##   |---------------------------|--------------------------------------------------------|
##   | suggester <text>...       | ask service for tag of text; print tag                 |
##   | suggester <url>           | fetch page, then ask service for tag of its text       |
##   | suggester -               | read text of standard input, as text given goes        |
##   | --record:<directory>      | replay page of 2xx or 3xx, and service reply holding   |
##   |                           | answer model produced; send rest; write each reply     |
##   | --replay:<directory>      | read every exchange from recordings; send nothing      |
##   | --                        | end flags, so passage may open with `-`                |
##   |---------------------------|--------------------------------------------------------|
##   Exit: 0 tag printed, 1 no tag and failure named, 2 usage, input or settings error, nothing
##     sent.
##
##   Standard output gets tag alone, so `tagger tag <name> "$(suggester ...)"` composes both
##     tools; report goes to standard error.
##   Argument opening with `-`, but `-` alone, is flag before text and after it, unless `--`
##     came first; flag usage does not take exits 2 before any setting, credential or socket, so
##     mistyped flag never goes out as passage of paid request.
##     Cost: text holding word opening with `-`, but `-` alone, needs `--` before it.
##   One argument shaped as http or https URL, one token naming host (`isShapedURL`), is page,
##     never text: one `isURL` refuses exits 2 naming URL, before any setting, so mistyped port or
##     host never goes out as passage of paid request. Problem names port rule where port alone
##     fails (`isPortFaulty`), else rule of authority, as RFC 3986 section 3.2 splits it.
##     Cost: such text goes as passage only through `-`.
##   Text given that reads as tag already asks no service, so it needs no credential; text given
##     whose passage holds no visible character (`isBlank`) once cut at `BYTES_PASSAGE_MAX`, as
##     model reads it, exits 2, as page holding none gives no text.
##     Cost: text is read into passage twice, once to test it and once to send it.
##     Cost: text of rarer default-ignorables alone, as U+180E, is not blank (`RANGES_BLANK`), so
##       it goes out.
##   `-` reads passage from standard input, so it never stands on command line, which `ps` shows
##     every user; at most `BYTES_PAGE_MAX` bytes, as page, else exit 2. Text read goes as text
##     given: shortcut, passage, request; URL it holds is text, never fetched.
##     Cost: page is fetched only from argument, so its URL stands on command line, token of its
##       query included; URL given to `-` is tagged as text.
##   Service, endpoint, model, effort, workspace and credential come from environment on each
##     run, as index path does for `tagger`: credential exists only at run time, and rest must
##     agree with it (Article II.2). Credential is read from `LOJBAN_TAGGER_API_KEY`, then from
##     usual name of service; report names variable, never value. `ANTHROPIC_BASE_URL` is never
##     read.
##   Usual name of service is read only where endpoint has host of default endpoint of service,
##     compared without case: key exported for other tools never goes to other host, which
##     reads `LOJBAN_TAGGER_API_KEY` alone, as `chat` does.
##   `LOJBAN_TAGGER_WORKSPACE` names workspace `claude` sends as `anthropic-workspace-id`, which
##     key scoped to no workspace needs on every request; ID of `wrkspc_` and visible ASCII
##     alone, at most `BYTES_WORKSPACE_MAX` bytes, so no line break reaches header. Other service
##     refuses any value. It stays out of stamp, so recording replays under any workspace.
##   Second binary, not verb of `tagger`: `-d:ssl` loads libssl when program starts, so every
##     verb of `tagger` would need it; Architect chose second binary.
##     Cost: second build and binary to ship, and tag from service runs two programs, as
##       `tagger tag <name> "$(suggester ...)"` composes them.
##   Page redirects are followed here, at most `COUNT_REDIRECTS_MAX`, choosing proxy again for
##     each hop; https never falls to http, and URL seen twice ends loop. Service redirect is
##     never followed, so credential stays with its endpoint.
##     Refusal of redirect names location or URL seen twice by scheme, host, port and path alone
##       (`dropSecrets`), as report names page URL, so token in user part, query or fragment,
##       which page may give, never reaches report. Cost: token held in path is named.
##   Record mode makes its directory before it reads or sends, so directory it cannot make refuses
##     run with `Recording`, and nothing is paid for; recording it cannot write after reply is
##     named in note, and tag still prints. Cost: failed send leaves empty directory behind.
##   Record mode replays service reply holding answer model produced (`isAnswered`), never by
##     status alone: tag, and failure of answer itself, replay, so no answer is paid twice;
##     refusal, error by status or inside 2xx, redirect, and body cut, coded or holding no JSON
##     object go out again, as OpenRouter answers 200 holding provider error, which it does not
##     bill and which passes, and as refusal names model to retry where fallback was skipped.
##     Cost: refusal service bills, in category `bio`, `frontier_llm` or `reasoning_extraction`,
##       or after partial output, is paid again on each record run.
##     Cost: recorded reply is read twice, once to choose and once to report.
##   Recordings hold passage, page and reply, so they stay private: record mode makes each
##     directory it makes with mode `0700`, and writes each recording with mode `0600` to new
##     sibling, refusing file or link there, before rename.
##     Cost: no other user, group included, reads recording; sharing one takes copy or `chmod`.
##   Record and replay refuse directory every user may write, as `/tmp`, before any read or send,
##     since other user could plant link where recording goes.
##     Path of recording joins directory and name as written, and each parent made is directory
##       cut at its last `/`, never normalized, so kernel resolves what that check stats, where
##       `joinPath` and `parentDir` drop `<link>/..` lexically.
##       Cost: path named keeps `.` and `..` as written.
##     Cost: owner of directory, and members of group that may write it, are trusted.
##   Recording is read only where file stands at its path itself: link there, as clone or archive
##     keeps it, is refused before read, never followed, so no file outside directory is read,
##     nor its first line echoed.
##     Cost: recording kept as link on purpose is refused.
##   Recording file past its request, cap of its body and `BYTES_FIELDS_MAX` is refused before it
##     is read, and body past its cap once read, so replay holds no more than send would.
##     Caps held by test "recording past its caps is refused: file before it is read, and body
##       past its cap" of `test_suggester.nim`; memory, by test "recording and input past their
##       caps are refused unread, under cap of address space" there.
##     Record writes no file past those caps, naming it in note, so no run writes file later run
##     refuses. Cost: reply whose head passes `BYTES_FIELDS_MAX`, less lines of format, goes
##     unrecorded, so each record run sends it again.
##     Recording that stands but cannot be read is refused with `Recording`, never traceback, as
##       test "recording that stands but cannot be read exits 1 with `Recording`, never
##       traceback" of `test_suggester.nim` holds where suite runs as user other than root.
##     Cost: recording past its caps, or unreadable, fails record run too, sending nothing, until
##       removed by hand.
##   Request of service exchange, which stamp names and recording keeps, is `POST` and endpoint,
##     line break, then body (`requestService` of `exchanges.nim`, which `tools/examples.nim`
##     builds by too), so recording replays for its endpoint alone; request of page hop is `GET`
##     and URL. Credential stays out, so recording replays under any credential.
##     Cost: endpoint is kept as written, so same endpoint spelled otherwise, in case, by `:443` or
##       closing dot, misses its recording, and record mode pays again.
##   Refusal and note of recording name path whose directory alone is made printable and cut;
##     refusal names problem first, so long directory hides neither problem nor stamp.
##     Cost: path named is not whole where directory passes `RUNES_SHOWN` characters.

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[asyncdispatch, net, options, os, sequtils, strutils, times, uri]
from std/posix import close, mkdir, O_CREAT, O_EXCL, open, O_WRONLY

import ../src/lojban_tagger/[suggestions, tags]
import ./exchanges


type
  Mode {.pure.} = enum  ## Define how run reaches each exchange.
    Live  ## Send every exchange; write nothing.
    Record
      ## Replay recording of same request: page hop of 2xx or 3xx, or service reply holding
      ##   answer model produced (`isAnswered`); send rest, and write each reply.
    Replay  ## Read every exchange from recordings; send nothing, read no credential.

  Command = object  ## Define what arguments ask.
    mode: Mode  ## How run reaches exchanges.
    directory: string  ## Directory of recordings; empty for live run.
    argument: string  ## Text given, joined by one space, or URL; text of input once read.
    is_url: bool  ## Argument is one http or https URL, so page is fetched.
    is_input: bool  ## Argument is `-` alone, so passage is read from standard input.

  Commanded = object  ## Define outcome of reading arguments: command, or usage error.
    case is_read: bool  ## Arguments read as command usage takes.
    of true:
      command: Command  ## Command arguments ask.
    of false:
      problem: string
        ## Fault printed before usage, ending in offending value; empty where usage alone tells it.

  Configured = object  ## Define outcome of reading settings from environment.
    case is_valid: bool  ## Every variable read is valid.
    of true:
      settings: Settings  ## Settings read, defaults applied.
    of false:
      problem: string  ## Which variable is wrong, ending in its value for its name.

  Exchanged = object  ## Define outcome of one exchange in any mode.
    case is_replied: bool  ## Reply came, sent or replayed.
    of true:
      reply: Reply  ## Reply sent or replayed.
      note: string
        ## Report line naming recording replayed, written or unwritten, at path refusal names;
        ##   empty if live.
    of false:
      failure: Failure  ## `Network` or `Recording`.
      detail: string
        ## Offending value, made printable; for `Recording`, problem, then path whose directory
        ##   alone is cut.

  Fetched = object  ## Define outcome of fetching page: passage, or failure; notes of each hop.
    notes: seq[string]  ## Report line of each hop replayed or written.
    case is_read: bool  ## Page gave passage.
    of true:
      passage: Passage  ## Passage final page gives.
    of false:
      failure: Failure  ## `Network`, `Recording` or `Page`.
      detail: string  ## Offending value, made printable.


const
  USAGE = "Usage: suggester [--record:<directory>|--replay:<directory>] [--] <text>...|<url>|-\n"
    ## Text printed on usage error.
  RULE_AUTHORITY = "name host and port as RFC 3986 section 3.2 splits them"
    ## Rule problem of URL argument and of endpoint states where `isURL` refuses authority past
    ##   its port alone, i.e. where `isPortFaulty` holds not; proxy problem of `send` in
    ##   `exchanges.nim` words same rule.
  FLAG_RECORD = "--record:"  ## Prefix of flag naming directory record mode writes.
  FLAG_REPLAY = "--replay:"  ## Prefix of flag naming directory replay mode reads.
  KEY_SERVICE = "LOJBAN_TAGGER_SERVICE"  ## Environment name of service.
  KEY_ENDPOINT = "LOJBAN_TAGGER_ENDPOINT"  ## Environment name overriding endpoint.
  KEY_MODEL = "LOJBAN_TAGGER_MODEL"  ## Environment name overriding model.
  KEY_EFFORT = "LOJBAN_TAGGER_EFFORT"  ## Environment name of effort.
  KEY_WORKSPACE = "LOJBAN_TAGGER_WORKSPACE"  ## Environment name of workspace `claude` sends.
  OPENING_WORKSPACE = "wrkspc_"  ## Opening of ID of workspace, as Anthropic issues it.
  BYTES_WORKSPACE_MAX = 128
    ## Most bytes of ID of workspace read; project cap, past length of IDs Anthropic issues.
  KEY_CREDENTIAL = "LOJBAN_TAGGER_API_KEY"  ## Environment name read first for credential.
  LUT_KEY_CREDENTIAL_BY_SERVICE: array[Service, string] =
    ["ANTHROPIC_API_KEY", "OPENROUTER_API_KEY", ""]
    ## Environment name read second where first is unset; `chat` reads first alone.
  NAMES_PROXY = ["HTTPS_PROXY", "NO_PROXY", "http_proxy", "https_proxy", "no_proxy"]
    ## Environment names `proxy` reads; uppercase `HTTP_PROXY` stays unread, as curl leaves it.
  COUNT_REDIRECTS_MAX = 5  ## Redirects page fetch follows, as many as client follows by default.
  MS_DEADLINE_PAGE = 30_000  ## Milliseconds one page hop may take, whole.
  MS_DEADLINE_SERVICE = 600_000
    ## Milliseconds service request may take, whole; long answer without streaming needs it.
  BYTES_FIELDS_MAX = 65_536
    ## Most bytes recording file holds past its request and cap of its body: format line, label
    ##   and fields, i.e. 64 KiB; larger file is refused before it is read.



#[ Arguments ]#

func readCommand(arguments: openArray[string]): Commanded =
  ## Read mode and passage from arguments; usage error where usage is wrong.
  ##   Leading arguments opening with `-` are flags: one `--record:<directory>` or
  ##     `--replay:<directory>`, directory nonempty, then `--`, which ends flags; any other flag
  ##     is usage error, so mistyped flag never goes out as passage of paid request.
  ##   Without `--`, no argument of passage but `-` alone opens with `-`, so flag after text,
  ##     mistyped or not, is usage error too, never read as text; passage opens with `-` only
  ##     where `-` is all of it.
  ##   Passage holding no visible character (`isBlank`) once cut at `BYTES_PASSAGE_MAX`
  ##     (`toPassage`), as model reads it, is usage error, as page holding none gives no text, so
  ##     empty passage never goes out.
  ##   One argument shaped as URL (`isShapedURL`) that `isURL` refuses is usage error naming URL
  ##     by scheme, host, port and path alone (`dropSecrets`), never passage, so mistyped port or
  ##     host never goes out as paid request; problem states `RULE_PORT` where port alone fails
  ##     (`isPortFaulty`), else `RULE_AUTHORITY`.
  var
    command = Command(mode: Mode.Live)
    at = 0
    is_ended = false  # `--` read, so rest is passage, whatever it holds.
  while at < arguments.len and arguments[at].startsWith('-') and arguments[at] != "-":
    let flag = arguments[at]
    inc at
    if flag == "--":
      is_ended = true
      break
    var is_taken = false
    for (prefix, mode) in [(FLAG_RECORD, Mode.Record), (FLAG_REPLAY, Mode.Replay)]:
      if command.mode == Mode.Live and flag.startsWith(prefix) and flag.len > prefix.len:
        (command.mode, command.directory) = (mode, flag[prefix.len .. ^1])
        is_taken = true
    if not is_taken: return Commanded(is_read: false)
  let rest = @arguments[at .. ^1]
  if rest.len == 0: return Commanded(is_read: false)
  if not is_ended and ((rest[0] == "-" and rest.len > 1) or
      rest.anyIt(it.len > 1 and it.startsWith('-'))):
    return Commanded(is_read: false)
  command.argument = rest.join(" ")
  if command.argument.toPassage.text.isBlank: return Commanded(is_read: false)
  if rest.len == 1 and rest[0].isShapedURL and not rest[0].isURL:
    let rule = if rest[0].isPortFaulty: RULE_PORT else: RULE_AUTHORITY
    return Commanded(is_read: false, problem: "URL should " & rule & "; got `" &
        rest[0].dropSecrets.toPrintable(RUNES_SHOWN) & "`.")
  command.is_url = rest.len == 1 and rest[0].isURL
  command.is_input = rest == @["-"]
  Commanded(is_read: true, command: command)


proc readInput(): Option[string] =
  ## Read passage from standard input, at most `BYTES_PAGE_MAX` bytes, as page is read; `none`
  ##   where input holds more, so huge input never fills memory; `IOError` where it cannot be read.
  ##   Memory held by test "recording and input past their caps are refused unread, under cap of
  ##     address space" of `test_suggester.nim`.
  ##   Cost: buffer of cap is allocated, whatever input holds.
  var text = newString(BYTES_PAGE_MAX + 1)
  text.setLen stdin.readBuffer(text[0].addr, text.len)
  if text.len > BYTES_PAGE_MAX: none(string) else: some(text)


func readSettings(service, endpoint, model, effort, workspace: string): Configured =
  ## Read settings from environment values; empty value takes default of service.
  ##   Endpoint refused names its fault: shape of URL where `isShapedURL` refuses it; `RULE_PORT`
  ##     where port alone fails `isURL` (`isPortFaulty`), else `RULE_AUTHORITY`; scheme, https or
  ##     http to loopback host, only where URL is well formed.
  ##   Workspace is for `claude` alone: `OPENING_WORKSPACE`, then visible ASCII alone, so no line
  ##     break splits header, at most `BYTES_WORKSPACE_MAX` bytes; empty names none.

  func refuse(text, name: string): Configured =
    ## Build outcome refusing settings, naming variable.
    Configured(is_valid: false, problem: text & "; got `` for `" & name & "`.")

  let found = if service.len == 0: some(Service.Claude) else: service.readService
  if found.isNone:
    return Configured(is_valid: false, problem: "Service should be `claude`, `openrouter` or " &
        "`chat`; got `" & service.toPrintable(RUNES_SHOWN) & "` for `" & KEY_SERVICE & "`.")
  let
    chosen = found.get
    endpoint_used = if endpoint.len > 0: endpoint else: LUT_ENDPOINT_BY_SERVICE[chosen]
    model_used = if model.len > 0: model else: LUT_MODEL_BY_SERVICE[chosen]
  if endpoint_used.len == 0:
    return refuse("Endpoint should be named for service `" & $chosen & "`", KEY_ENDPOINT)
  if not endpoint_used.isURL:
    let rule =
      if not endpoint_used.isShapedURL: "be http or https URL with host and no whitespace"
      elif endpoint_used.isPortFaulty: RULE_PORT
      else: RULE_AUTHORITY
    return Configured(is_valid: false, problem: "Endpoint should " & rule & "; got `" &
        endpoint_used.toPrintable(RUNES_SHOWN) & "` for `" & KEY_ENDPOINT & "`.")
  if not endpoint_used.isEndpoint:
    return Configured(is_valid: false, problem: "Endpoint should be https, or http to " &
        "loopback host; got `" & endpoint_used.toPrintable(RUNES_SHOWN) & "` for `" &
        KEY_ENDPOINT & "`.")
  if model_used.len == 0:
    return refuse("Model should be named for service `" & $chosen & "`", KEY_MODEL)
  var effort_used = if chosen == Service.Chat: none(Effort) else: some(EFFORT_DEFAULT)
  if effort.len > 0:
    effort_used = effort.readEffort
    if effort_used.isNone:
      return Configured(is_valid: false, problem: "Effort should be `low`, `medium`, `high`, " &
          "`xhigh` or `max`; got `" & effort.toPrintable(RUNES_SHOWN) & "` for `" & KEY_EFFORT &
          "`.")
  let shown = workspace.toPrintable(RUNES_SHOWN)
  if workspace.len > 0 and chosen != Service.Claude:
    return Configured(is_valid: false, problem: "Workspace should be named for service " &
        "`claude` alone; got `" & shown & "` for `" & KEY_WORKSPACE & "`.")
  if workspace.len > 0 and (not workspace.startsWith(OPENING_WORKSPACE) or
      workspace.len > BYTES_WORKSPACE_MAX or workspace.anyIt(it notin {'!'..'~'})):
    return Configured(is_valid: false, problem: "Workspace should open with `" &
        OPENING_WORKSPACE & "` and hold at most " & $BYTES_WORKSPACE_MAX & " bytes of " &
        "visible ASCII; got `" & shown & "` for `" & KEY_WORKSPACE & "`.")
  Configured(
    is_valid: true,
    settings: Settings(
      service: chosen,
      endpoint: endpoint_used,
      model: model_used,
      effort: effort_used,
      workspace: workspace,
    ),
  )



#[ Exchanges ]#

proc findCredential(settings: Settings): Credentialed =
  ## Read credential from first variable holding one: `LOJBAN_TAGGER_API_KEY`, then usual name
  ##   of service, read only where endpoint has host of default endpoint of service, compared
  ##   without case; other host reads first alone, so key exported for other tools never goes
  ##   there, and problem says why.
  let
    host = LUT_ENDPOINT_BY_SERVICE[settings.service].parseUri.hostname
    is_usual = host.len > 0 and settings.endpoint.parseUri.hostname.toLowerAscii == host
    names =
      if is_usual: @[KEY_CREDENTIAL, LUT_KEY_CREDENTIAL_BY_SERVICE[settings.service]]
      else: @[KEY_CREDENTIAL]
  for name in names:
    if getEnv(name).strip.len > 0: return readCredential(name, getEnv(name), settings.service)
  let named = names.mapIt("`" & it & "`").join(" or ")
  if host.len > 0 and not is_usual:
    return Credentialed(is_read: false, problem: "Credential should be set in " & named &
        " alone, since host of endpoint is not `" & host & "`; got ``.")
  Credentialed(is_read: false, problem: "Credential should be set in " & named & "; got ``.")


func isReplayed(reply: Reply, service: Option[Service]): bool =
  ## Test record mode replays recorded reply: page hop of 2xx or 3xx; reply of `service` holding
  ##   answer model produced (`isAnswered`), so refusal, error by status or inside 2xx, redirect,
  ##   and body cut, coded or holding no JSON object go out again.
  if service.isNone: return reply.status in 200..399
  service.get.isAnswered(reply)


proc isShared(directory: string): bool =
  ## Test every user may write directory, as `/tmp` lets them, so other user could plant link
  ##   where recording goes; false where no directory stands at path.
  try:
    dirExists(directory) and fpOthersWrite in getFilePermissions(directory)
  except OSError:
    false


proc createDirectoryPrivate(directory: string) =
  ## Make directory, and each parent missing, with mode `0700`, so no other user lists or reads
  ##   recordings; directory standing keeps its mode. `OSError` where one cannot be made.
  ##   Parent is directory cut at its last `/`, never normalized as `parentDir` normalizes it, so
  ##     kernel resolves each parent as it resolves directory, `..` after link included.
  if directory.len == 0 or dirExists(directory): return
  let trimmed = directory.strip(leading = false, chars = {'/'})
  createDirectoryPrivate(trimmed[0 ..< max(trimmed.rfind('/'), 0)])
  if mkdir(cstring(directory), 0o700) == 0: return
  let error = osLastError()  # Before `dirExists`, whose failed `stat` would set its own.
  if not dirExists(directory): raiseOSError(error, directory)


proc writePrivate(path, text: string) =
  ## Write text to file made new at path with mode `0600`, so no other user reads it; file or
  ##   link standing at path is refused, as `O_EXCL` refuses it. `OSError` or `IOError` where
  ##   write fails.
  let handle = open(cstring(path), O_WRONLY or O_CREAT or O_EXCL, cint(0o600))
  if handle < 0: raiseOSError(osLastError(), path)
  var file: File
  if not file.open(FileHandle(handle), fmWrite):
    discard close(handle)
    raiseOSError(osLastError(), path)
  try:
    file.write(text)
  finally:
    file.close()


proc exchange(
  request, url, body: string;
  headers: seq[(string, string)];
  credential: Option[Credential];
  service: Option[Service];
  bytes_max, ms_deadline: int;
  command: Command;
  context: var SslContext;
): Exchanged =
  ## Answer one exchange by mode: replay recording, or send, and write recording in record mode.
  ##   `service` names wire format of service exchange, whose reply record mode reads before it
  ##     replays it (`isReplayed`); `none` for page hop.
  ##   Record mode makes directory before reading or sending, mode `0700` where it makes it,
  ##     refusing where it cannot; write failing after reply is named in note, and reply is kept,
  ##     as is reply whose file would pass caps below, which note names unwritten.
  ##   Directory every user may write is refused before any read or send; link or other than
  ##     file at path of recording is refused before it is read, never followed; recording file
  ##     past request, `bytes_max` and `BYTES_FIELDS_MAX` is refused before it is read, and body
  ##     past `bytes_max` is refused once read.
  ##   Recording that stands but cannot be read is refused, naming first line of error.
  ##   Refusal names problem in words of tool first, then path, so long directory never hides
  ##     either: outside text, directory and error, is made printable and cut alone, and name
  ##     holding stamp stays whole. Note names path as refusal does.

  func refuse(detail: string): Exchanged =
    ## Build outcome refusing recording; caller made each outside part of detail printable.
    Exchanged(is_replied: false, failure: Failure.Recording, detail: detail)

  func toLine(error: ref Exception): string =
    ## Render first line of error, made printable and cut, as outside text.
    error.msg.splitLines[0].toPrintable(RUNES_SHOWN)

  func joinVerbatim(directory, name: string): string =
    ## Join directory and name with one `/` between them, `..` and `.` kept as written, so kernel
    ##   resolves directory `isShared` stats; `joinPath` drops `<link>/..` lexically.
    if directory.endsWith('/'): directory & name else: directory & "/" & name

  let
    name = request.stamp & ".recording"
    path = command.directory.joinVerbatim(name)
    shown_directory = command.directory.toPrintable(RUNES_SHOWN)
    shown = shown_directory.joinVerbatim(name)
    bytes_file_max = request.len + bytes_max + BYTES_FIELDS_MAX

  # Make directory of record mode, private where made, then refuse directory every user writes.
  if command.mode == Mode.Record:
    try:
      createDirectoryPrivate(command.directory)
    except CatchableError as error:
      return refuse("unwritable: " & error.toLine & " at " & shown)
  if command.mode != Mode.Live and command.directory.isShared:
    return refuse("writable by every user at " & shown_directory)

  # Replay recording of same request within its caps, as mode and `isReplayed` choose.
  if command.mode != Mode.Live and fileExists(path):
    var text = ""
    try:
      if getFileInfo(path, followSymlink = false).kind != pcFile:
        return refuse("link or other than file at " & shown)
      if getFileSize(path) > bytes_file_max:
        return refuse("larger than " & $bytes_file_max & " bytes at " & shown)
      text = readFile(path)
    except CatchableError as error:
      return refuse("unreadable: " & error.toLine & " at " & shown)
    let recorded = text.readRecording
    if not recorded.is_read:
      var problem = recorded.problem  # Words of reader, piece it echoes made printable and cut.
      problem.removeSuffix('.')
      return refuse(problem & " at line " & $recorded.line & " of " & shown)
    if recorded.recording.request != request: return refuse("other request at " & shown)
    if recorded.recording.reply.body.len > bytes_max:
      return refuse("body over " & $bytes_max & " bytes at " & shown)
    if command.mode == Mode.Replay or recorded.recording.reply.isReplayed(service):
      let label = recorded.recording.label.toPrintable(RUNES_SHOWN)
      return Exchanged(is_replied: true, reply: recorded.recording.reply,
          note: "Reply replayed from `" & shown & "`: " & label & ".")
  if command.mode == Mode.Replay: return refuse("missing at " & shown)

  # Send within deadline, through proxy environment names.
  when defined(ssl):
    if context.isNil and url.toLowerAscii.startsWith("https:"):
      try:
        context = newContext(verifyMode = CVerifyPeerUseEnvVars)
      except CatchableError as error:
        return Exchanged(is_replied: false, failure: Failure.Network,
            detail: error.msg.toPrintable(RUNES_SHOWN))
  let
    environment = NAMES_PROXY.mapIt((it, getEnv(it)))
    sent = waitFor send(url, body, headers, credential, url.proxy(environment), context,
        bytes_max, sleepAsync(ms_deadline))
  if not sent.is_replied:
    return Exchanged(is_replied: false, failure: Failure.Network,
        detail: sent.problem.toPrintable(RUNES_SHOWN))

  # Write reply in record mode: new sibling of mode `0600`, then rename over recording; file past
  #   caps replay reads is never written, so no run writes file later run refuses.
  var note = ""
  if command.mode == Mode.Record:
    let text = Recording(
      label: "recorded " & now().utc.format("yyyy-MM-dd"),
      request: request,
      reply: sent.reply,
    ).toText
    if text.len > bytes_file_max:
      note = "Reply should be written to `" & shown & "`; got `larger than " & $bytes_file_max &
          " bytes`."
    else:
      try:
        discard tryRemoveFile(path & ".writing")  # Sibling left by run that ended before rename.
        writePrivate(path & ".writing", text)
        moveFile(path & ".writing", path)
        note = "Reply written to `" & shown & "`."
      except CatchableError as error:
        discard tryRemoveFile(path & ".writing")
        note = "Reply should be written to `" & shown & "`; got `" & error.toLine & "`."
  Exchanged(is_replied: true, reply: sent.reply, note: note)


proc fetch(url: string, command: Command, context: var SslContext): Fetched =
  ## Fetch page through `exchange`, following at most `COUNT_REDIRECTS_MAX` redirects, refusing
  ##   loop and fall from https to http.
  ##   Refusal names location or URL seen twice by scheme, host, port and path alone
  ##     (`dropSecrets`), as report names page URL.
  var
    current = url
    seen = @[url]
    notes: seq[string]
  for hop in 0..COUNT_REDIRECTS_MAX:
    let exchanged = exchange("GET " & current, current, "", @[], none(Credential),
        none(Service), BYTES_PAGE_MAX, MS_DEADLINE_PAGE, command, context)
    if not exchanged.is_replied:
      return Fetched(notes: notes, is_read: false, failure: exchanged.failure,
          detail: exchanged.detail)
    if exchanged.note.len > 0: notes.add exchanged.note
    let target = current.redirect(exchanged.reply)
    if target.isNone:
      if exchanged.reply.status in STATUSES_REDIRECT:
        let location = exchanged.reply.location.dropSecrets
        return Fetched(notes: notes, is_read: false, failure: Failure.Page,
            detail: ("redirect to " & location).toPrintable(RUNES_SHOWN))
      let paged = current.readPage(exchanged.reply)
      if not paged.is_read:
        return Fetched(notes: notes, is_read: false, failure: Failure.Page, detail: paged.detail)
      return Fetched(notes: notes, is_read: true, passage: paged.passage)
    if target.get in seen:
      return Fetched(notes: notes, is_read: false, failure: Failure.Page,
          detail: ("redirect loop at " & target.get.dropSecrets).toPrintable(RUNES_SHOWN))
    seen.add target.get
    current = target.get
  Fetched(notes: notes, is_read: false, failure: Failure.Page,
      detail: "more than " & $COUNT_REDIRECTS_MAX & " redirects")



#[ Entry ]#

proc main(): int =
  ## Read arguments and environment, build passage, ask service or recording, print tag and
  ##   report.
  let parsed = commandLineParams().readCommand
  if not parsed.is_read:
    if parsed.problem.len > 0: stderr.writeLine parsed.problem
    stderr.write USAGE
    return 2
  var command = parsed.command

  # Read passage of standard input, capped as page, before any setting; it goes as text given.
  if command.is_input:
    try:
      let text = readInput()
      if text.isNone:
        stderr.writeLine "Text on standard input should hold at most " & $BYTES_PAGE_MAX &
            " bytes; got more than `" & $BYTES_PAGE_MAX & "`."
        return 2
      command.argument = text.get
    except IOError as error:
      stderr.writeLine "Text on standard input should be readable; got `" &
          error.msg.splitLines[0].toPrintable(RUNES_SHOWN) & "`."
      return 2
    if command.argument.toPassage.text.isBlank:
      stderr.write USAGE
      return 2

  # Answer text given as tag at once; else read settings and credential, then ask service.
  if not command.is_url:
    let given = command.argument.readTagGiven
    if given.isSome and not given.get.is_suggested:
      stderr.writeLine given.get.explain
      return 1
    if given.isSome:
      stdout.write $given.get.tag & "\n"
      stderr.write toReportGiven(command.argument, given.get.tag)
      return 0
  let configured = readSettings(
    getEnv(KEY_SERVICE),
    getEnv(KEY_ENDPOINT),
    getEnv(KEY_MODEL),
    getEnv(KEY_EFFORT),
    getEnv(KEY_WORKSPACE),
  )
  if not configured.is_valid:
    stderr.writeLine configured.problem
    return 2
  let settings = configured.settings
  var
    credential = none(Credential)
    notes: seq[string]
    context: SslContext = nil
    passage: Passage
  if command.mode != Mode.Replay:
    let found = settings.findCredential
    if not found.is_read:
      stderr.writeLine found.problem
      return 2
    credential = some(found.credential)
    notes.add "Credential read from `" & found.name & "`."
  if command.is_url:
    let fetched = fetch(command.argument, command, context)
    notes.add fetched.notes
    if not fetched.is_read:
      for note in notes: stderr.writeLine note
      stderr.writeLine Suggestion(
        is_suggested: false,
        failure: fetched.failure,
        detail: fetched.detail,
      ).explain
      return 1
    passage = fetched.passage
  else:
    passage = command.argument.toPassage
  let
    body = settings.toBody(passage)
    exchanged = exchange(settings.requestService(body), settings.endpoint, body,
        settings.toHeaders, credential, some(settings.service), BYTES_REPLY_MAX,
        MS_DEADLINE_SERVICE, command, context)
    suggestion =
      if exchanged.is_replied: settings.service.readReply(exchanged.reply)
      else: Suggestion(is_suggested: false, failure: exchanged.failure, detail: exchanged.detail)
  if exchanged.is_replied and exchanged.note.len > 0: notes.add exchanged.note
  for note in notes: stderr.writeLine note
  stderr.write suggestion.toReport(passage, settings.model)
  if not suggestion.is_suggested: return 1
  stdout.write $suggestion.tag & "\n"
  0


when isMainModule:
  quit main()
