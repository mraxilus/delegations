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
##   | --record:<directory>      | replay page of 2xx or 3xx, and service reply reading   |
##   |                           | as tag or paid failure; send rest; write each reply    |
##   | --replay:<directory>      | read every exchange from recordings; send nothing      |
##   | --                        | end flags, so passage may open with `-`                |
##   |---------------------------|--------------------------------------------------------|
##   Exit: 0 tag printed, 1 no tag and failure named, 2 usage or settings error, nothing sent.
##
##   Standard output gets tag alone, so `tagger tag <name> "$(suggester ...)"` composes both
##     tools; report goes to standard error.
##   Leading argument opening with `-` is flag; flag usage does not take exits 2 before any
##     setting, credential or socket, so mistyped flag never goes out as passage of paid request.
##     Cost: text opening with `-` needs `--` before it.
##   Text given that reads as tag already asks no service, so it needs no credential; text given
##     holding no visible character (`isBlank`) exits 2, as page holding none gives no text.
##   `-` reads passage from standard input, so it never stands on command line, which `ps` shows
##     every user; at most `BYTES_PAGE_MAX` bytes, as page, else exit 2. Text read goes as text
##     given: shortcut, passage, request; URL it holds is text, never fetched.
##   Service, endpoint, model, effort, workspace and credential come from environment on each
##     run, as index path does for `tagger`: credential exists only at run time, and rest must
##     agree with it (Article II.2). Credential is read from `LOJBAN_TAGGER_API_KEY`, then from
##     usual name of service; report names variable, never value. `ANTHROPIC_BASE_URL` is never
##     read.
##   `LOJBAN_TAGGER_WORKSPACE` names workspace `claude` sends as `anthropic-workspace-id`, which
##     key scoped to no workspace needs on every request; ID of `wrkspc_` and visible ASCII
##     alone, at most `BYTES_WORKSPACE_MAX` bytes, so no line break reaches header. Other service
##     refuses any value. It stays out of stamp, so recording replays under any workspace.
##   Usual name of service is read only where endpoint has host of default endpoint of service,
##     compared without case: key exported for other tools never goes to other host, which
##     reads `LOJBAN_TAGGER_API_KEY` alone, as `chat` does.
##   Second binary, not verb of `tagger`: `-d:ssl` loads libssl when program starts, so every
##     verb of `tagger` would need it; Architect chose second binary.
##   Page redirects are followed here, at most `COUNT_REDIRECTS_MAX`, choosing proxy again for
##     each hop; https never falls to http, and URL seen twice ends loop. Service redirect is
##     never followed, so credential stays with its endpoint.
##   Record mode makes its directory before it reads or sends, so directory it cannot make refuses
##     run with `Recording`, and nothing is paid for; recording it cannot write after reply is
##     named in note, and tag still prints. Cost: failed send leaves empty directory behind.
##   Recordings hold passage, page and reply, so they stay private: record mode makes each
##     directory it makes with mode `0700`, and writes each recording with mode `0600` to new
##     sibling, refusing file or link there, before rename.
##   Record and replay refuse directory every user may write, as `/tmp`, before any read or send,
##     since other user could plant link where recording goes.
##     Cost: owner of directory, and members of group that may write it, are trusted.
##   Recording file past its request, cap of its body and `BYTES_FIELDS_MAX` is refused before it
##     is read, and body past its cap once read, so replay holds no more than send would.
##     Recording that stands but cannot be read is refused with `Recording`, never traceback.
##   Request of service exchange, which stamp names and recording keeps, is `POST` and endpoint,
##     line break, then body, so recording replays for its endpoint alone; request of page hop
##     is `GET` and URL. Credential stays out, so recording replays under any credential.
##   Record mode replays service reply by how `readReply` reads it, never by status alone: tag,
##     and failure of answer service bills, replay, so no answer is paid twice; reply reading as
##     `Status` goes out again, as OpenRouter answers 200 holding provider error, which it does
##     not bill and which passes.
##     Cost: recorded reply is read twice, once to choose and once to report.

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
      ## Replay recording of same request: page hop of 2xx or 3xx, or service reply reading as
      ##   tag or failure of answer service bills; send rest, and write each reply.
    Replay  ## Read every exchange from recordings; send nothing, read no credential.

  Command = object  ## Define what arguments ask.
    mode: Mode  ## How run reaches exchanges.
    directory: string  ## Directory of recordings; empty for live run.
    argument: string  ## Text given, joined by one space, or URL; text of input once read.
    is_url: bool  ## Argument is one http or https URL, so page is fetched.
    is_input: bool  ## Argument is `-` alone, so passage is read from standard input.

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
      note: string  ## Report line naming recording replayed, written or unwritten; empty if live.
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

func readCommand(arguments: openArray[string]): Option[Command] =
  ## Read mode and passage from arguments; `none` where usage is wrong.
  ##   Leading arguments opening with `-` are flags: one `--record:<directory>` or
  ##     `--replay:<directory>`, directory nonempty, then `--`, which ends flags; any other flag
  ##     is usage error, so mistyped flag never goes out as passage of paid request.
  ##   Without `--`, passage holds no flag of mode, and opens with `-` only where `-` is all of
  ##     it, so flag is never read as text.
  ##   Passage holding no visible character (`isBlank`) is usage error, as page holding none
  ##     gives no text, so empty passage never goes out.
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
    if not is_taken: return none(Command)
  let rest = @arguments[at .. ^1]
  if rest.len == 0: return none(Command)
  if not is_ended and ((rest[0] == "-" and rest.len > 1) or
      rest.anyIt(it.startsWith(FLAG_RECORD) or it.startsWith(FLAG_REPLAY))):
    return none(Command)
  command.argument = rest.join(" ")
  if command.argument.isBlank: return none(Command)
  command.is_url = rest.len == 1 and rest[0].isURL
  command.is_input = rest == @["-"]
  some(command)


proc readInput(): Option[string] =
  ## Read passage from standard input, at most `BYTES_PAGE_MAX` bytes, as page is read; `none`
  ##   where input holds more, so huge input never fills memory; `IOError` where it cannot be read.
  ##   Cost: buffer of cap is allocated, whatever input holds.
  var text = newString(BYTES_PAGE_MAX + 1)
  text.setLen(stdin.readBuffer(text[0].addr, text.len))
  if text.len > BYTES_PAGE_MAX: none(string) else: some(text)


func readSettings(service, endpoint, model, effort, workspace: string): Configured =
  ## Read settings from environment values; empty value takes default of service.
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
  let shown = "`" & workspace.toPrintable(RUNES_SHOWN) & "` for `" & KEY_WORKSPACE & "`."
  if workspace.len > 0 and chosen != Service.Claude:
    return Configured(is_valid: false, problem: "Workspace should be named for service " &
        "`claude` alone; got " & shown)
  if workspace.len > 0 and (not workspace.startsWith(OPENING_WORKSPACE) or
      workspace.len > BYTES_WORKSPACE_MAX or workspace.anyIt(it notin {'!'..'~'})):
    return Configured(is_valid: false, problem: "Workspace should open with `" &
        OPENING_WORKSPACE & "` and hold at most " & $BYTES_WORKSPACE_MAX & " bytes of " &
        "visible ASCII; got " & shown)
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
        " alone, since host of endpoint is not `" & host & "`; got none.")
  Credentialed(is_read: false, problem: "Credential should be set in " & named & "; got none.")


func isReplayed(reply: Reply, service: Option[Service]): bool =
  ## Test record mode replays recorded reply: page hop of 2xx or 3xx; reply of `service` reading
  ##   as tag or as failure of answer service bills, never as `Status`, so error by status, error
  ##   inside 2xx and redirect go out again.
  if service.isNone: return reply.status in 200..399
  let suggestion = service.get.readReply(reply)
  suggestion.is_suggested or suggestion.failure != Failure.Status


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
  if directory.len == 0 or dirExists(directory): return
  createDirectoryPrivate(directory.parentDir)
  if mkdir(directory.cstring, 0o700) == 0: return
  let error = osLastError()  # Before `dirExists`, whose failed `stat` would set its own.
  if not dirExists(directory): raiseOSError(error, directory)


proc writePrivate(path, text: string) =
  ## Write text to file made new at path with mode `0600`, so no other user reads it; file or
  ##   link standing at path is refused, as `O_EXCL` refuses it. `OSError` or `IOError` where
  ##   write fails.
  let handle = open(path.cstring, O_WRONLY or O_CREAT or O_EXCL, cint(0o600))
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
  ##     refusing where it cannot; write failing after reply is named in note, and reply is kept.
  ##   Directory every user may write is refused before any read or send; recording file past
  ##     request, `bytes_max` and `BYTES_FIELDS_MAX` is refused before it is read, and body past
  ##     `bytes_max` is refused once read.
  ##   Recording that stands but cannot be read is refused, naming first line of error.
  ##   Refusal names problem in words of tool first, then path, so long directory never hides
  ##     either: outside text, directory and error, is made printable and cut alone, and name
  ##     holding stamp stays whole.

  func refuse(detail: string): Exchanged =
    ## Build outcome refusing recording; caller made each outside part of detail printable.
    Exchanged(is_replied: false, failure: Failure.Recording, detail: detail)

  func toLine(error: ref Exception): string =
    ## Render first line of error, made printable and cut, as outside text.
    error.msg.splitLines[0].toPrintable(RUNES_SHOWN)

  let
    name = request.stamp & ".recording"
    path = command.directory / name
    shown_directory = command.directory.toPrintable(RUNES_SHOWN)
    shown = shown_directory / name
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
          note: "Reply replayed from `" & path & "`: " & label & ".")
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

  # Write reply in record mode: new sibling of mode `0600`, then rename over recording.
  var note = ""
  if command.mode == Mode.Record:
    let recording = Recording(
      label: "recorded " & now().utc.format("yyyy-MM-dd"),
      request: request,
      reply: sent.reply,
    )
    try:
      discard tryRemoveFile(path & ".writing")  # Sibling left by run that ended before rename.
      writePrivate(path & ".writing", recording.toText)
      moveFile(path & ".writing", path)
      note = "Reply written to `" & path & "`."
    except CatchableError as error:
      discard tryRemoveFile(path & ".writing")
      note = "Reply should be written to `" & path & "`; got `" & error.toLine & "`."
  Exchanged(is_replied: true, reply: sent.reply, note: note)


func requestService(settings: Settings, body: string): string =
  ## Build request of service exchange, which stamp names and recording keeps: `POST` and
  ##   endpoint, line break, then body, so recording replays for its endpoint alone.
  ##   Sibling of `toRecordings` in `tools/examples.nim`, which builds same request (II.9).
  "POST " & settings.endpoint & "\n" & body


proc fetch(url: string, command: Command, context: var SslContext): Fetched =
  ## Fetch page through `exchange`, following at most `COUNT_REDIRECTS_MAX` redirects, refusing
  ##   loop and fall from https to http.
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
        return Fetched(notes: notes, is_read: false, failure: Failure.Page,
            detail: ("redirect to " & exchanged.reply.location).toPrintable(RUNES_SHOWN))
      let paged = current.readPage(exchanged.reply)
      if not paged.is_read:
        return Fetched(notes: notes, is_read: false, failure: Failure.Page, detail: paged.detail)
      return Fetched(notes: notes, is_read: true, passage: paged.passage)
    if target.get in seen:
      return Fetched(notes: notes, is_read: false, failure: Failure.Page,
          detail: ("redirect loop at " & target.get).toPrintable(RUNES_SHOWN))
    seen.add target.get
    current = target.get
  Fetched(notes: notes, is_read: false, failure: Failure.Page,
      detail: "more than " & $COUNT_REDIRECTS_MAX & " redirects")



#[ Entry ]#

proc main(): int =
  ## Read arguments and environment, build passage, ask service or recording, print tag and
  ##   report.
  let parsed = commandLineParams().readCommand
  if parsed.isNone:
    stderr.write USAGE
    return 2
  var command = parsed.get

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
    if command.argument.isBlank:
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
