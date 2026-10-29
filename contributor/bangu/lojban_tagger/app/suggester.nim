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
##   | --record:<directory>      | replay recorded reply of 2xx or 3xx; send rest; write  |
##   | --replay:<directory>      | read every exchange from recordings; send nothing      |
##   |---------------------------|--------------------------------------------------------|
##   Exit: 0 tag printed, 1 no tag and failure named, 2 usage or settings error, nothing sent.
##
##   Standard output gets tag alone, so `tagger tag <name> "$(suggester ...)"` composes both
##     tools; report goes to standard error.
##   Text given that reads as tag already asks no service, so it needs no credential.
##   Service, endpoint, model, effort and credential come from environment on each run, as
##     index path does for `tagger`: credential exists only at run time, and rest must agree
##     with it (Article II.2). Credential is read from `LOJBAN_TAGGER_API_KEY`, then from usual
##     name of service; report names variable, never value. `ANTHROPIC_BASE_URL` is never read.
##   Second binary, not verb of `tagger`: `-d:ssl` loads libssl when program starts, so every
##     verb of `tagger` would need it; Architect chose second binary.
##   Page redirects are followed here, at most `COUNT_REDIRECTS_MAX`, choosing proxy again for
##     each hop; https never falls to http, and URL seen twice ends loop. Service redirect is
##     never followed, so credential stays with its endpoint.
##   Record mode makes its directory before it sends, so directory it cannot make refuses run
##     with `Recording`, and nothing is paid for; recording it cannot write after reply is named
##     in note, and tag still prints. Cost: failed send leaves empty directory behind.

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[asyncdispatch, net, options, os, sequtils, strutils, times]

import ../src/lojban_tagger/[suggestions, tags]
import ./exchanges


type
  Mode {.pure.} = enum  ## Define how run reaches each exchange.
    Live  ## Send every exchange; write nothing.
    Record  ## Replay recording of 2xx or 3xx for same request; send rest, and write each reply.
    Replay  ## Read every exchange from recordings; send nothing, read no credential.

  Command = object  ## Define what arguments ask.
    mode: Mode  ## How run reaches exchanges.
    directory: string  ## Directory of recordings; empty for live run.
    argument: string  ## Text given, joined by one space, or URL.
    is_url: bool  ## Argument is one http or https URL, so page is fetched.

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
      detail: string  ## Offending value, made printable.

  Fetched = object  ## Define outcome of fetching page: passage, or failure; notes of each hop.
    notes: seq[string]  ## Report line of each hop replayed or written.
    case is_read: bool  ## Page gave passage.
    of true:
      passage: Passage  ## Passage final page gives.
    of false:
      failure: Failure  ## `Network`, `Recording` or `Page`.
      detail: string  ## Offending value, made printable.


const
  USAGE = "Usage: suggester [--record:<directory>|--replay:<directory>] <text>...|<url>\n"
    ## Text printed on usage error.
  FLAG_RECORD = "--record:"  ## Prefix of first argument naming directory record mode writes.
  FLAG_REPLAY = "--replay:"  ## Prefix of first argument naming directory replay mode reads.
  KEY_SERVICE = "LOJBAN_TAGGER_SERVICE"  ## Environment name of service.
  KEY_ENDPOINT = "LOJBAN_TAGGER_ENDPOINT"  ## Environment name overriding endpoint.
  KEY_MODEL = "LOJBAN_TAGGER_MODEL"  ## Environment name overriding model.
  KEY_EFFORT = "LOJBAN_TAGGER_EFFORT"  ## Environment name of effort.
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
  RUNES_SHOWN = 200  ## Most characters of outside text report shows.



#[ Arguments ]#

func readCommand(arguments: openArray[string]): Option[Command] =
  ## Read mode and passage from arguments; `none` where usage is wrong.
  var
    rest = @arguments
    command = Command(mode: Mode.Live)
  if rest.len > 0:
    for (flag, mode) in [(FLAG_RECORD, Mode.Record), (FLAG_REPLAY, Mode.Replay)]:
      if rest[0].startsWith(flag):
        command.mode = mode
        command.directory = rest[0][flag.len .. ^1]
        rest.delete(0)
        break
  if command.mode != Mode.Live and command.directory.len == 0: return none(Command)
  if rest.len == 0 or rest.anyIt(it.startsWith(FLAG_RECORD) or it.startsWith(FLAG_REPLAY)):
    return none(Command)
  command.argument = rest.join(" ")
  if command.argument.strip.len == 0: return none(Command)
  command.is_url = rest.len == 1 and rest[0].isURL
  some(command)


func readSettings(service, endpoint, model, effort: string): Configured =
  ## Read settings from environment values; empty value takes default of service.

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
  Configured(
    is_valid: true,
    settings: Settings(
      service: chosen,
      endpoint: endpoint_used,
      model: model_used,
      effort: effort_used,
    ),
  )



#[ Exchanges ]#

proc findCredential(service: Service): Credentialed =
  ## Read credential from first variable holding one: `LOJBAN_TAGGER_API_KEY`, then usual name
  ##   of service.
  let names = [KEY_CREDENTIAL, LUT_KEY_CREDENTIAL_BY_SERVICE[service]]
  for name in names:
    if name.len > 0 and getEnv(name).strip.len > 0:
      return readCredential(name, getEnv(name), service)
  let named = names.filterIt(it.len > 0).mapIt("`" & it & "`").join(" or ")
  Credentialed(is_read: false, problem: "Credential should be set in " & named & "; got none.")


proc exchange(
  request, url, body: string;
  headers: seq[(string, string)];
  credential: Option[Credential];
  bytes_max, ms_deadline: int;
  command: Command;
  context: var SslContext;
): Exchanged =
  ## Answer one exchange by mode: replay recording, or send, and write recording in record mode.
  ##   Record mode makes directory before sending, refusing where it cannot; write failing after
  ##   reply is named in note, and reply is kept.
  let path = command.directory / (request.stamp & ".recording")
  if command.mode != Mode.Live and fileExists(path):
    let recorded = readFile(path).readRecording
    if not recorded.is_read:
      return Exchanged(is_replied: false, failure: Failure.Recording,
          detail: (path & ":" & $recorded.line & ": " & recorded.problem).toPrintable(RUNES_SHOWN))
    if recorded.recording.request != request:
      return Exchanged(is_replied: false, failure: Failure.Recording,
          detail: (path & " holds other request").toPrintable(RUNES_SHOWN))
    if command.mode == Mode.Replay or recorded.recording.reply.status in 200..399:
      let label = recorded.recording.label.toPrintable(RUNES_SHOWN)
      return Exchanged(is_replied: true, reply: recorded.recording.reply,
          note: "Reply replayed from `" & path & "`: " & label & ".")
  if command.mode == Mode.Replay:
    return Exchanged(is_replied: false, failure: Failure.Recording,
        detail: (path & " missing").toPrintable(RUNES_SHOWN))
  if command.mode == Mode.Record:
    try:
      createDir(command.directory)
    except CatchableError as error:
      return Exchanged(is_replied: false, failure: Failure.Recording,
          detail: (path & " unwritable: " & error.msg.splitLines[0]).toPrintable(RUNES_SHOWN))
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
  var note = ""
  if command.mode == Mode.Record:
    let recording = Recording(
      label: "recorded " & now().utc.format("yyyy-MM-dd"),
      request: request,
      reply: sent.reply,
    )
    try:
      writeFile(path & ".writing", recording.toText)
      moveFile(path & ".writing", path)
      note = "Reply written to `" & path & "`."
    except CatchableError as error:
      discard tryRemoveFile(path & ".writing")
      note = "Reply should be written to `" & path & "`; got `" &
          error.msg.splitLines[0].toPrintable(RUNES_SHOWN) & "`."
  Exchanged(is_replied: true, reply: sent.reply, note: note)


proc fetch(url: string, command: Command, context: var SslContext): Fetched =
  ## Fetch page through `exchange`, following at most `COUNT_REDIRECTS_MAX` redirects, refusing
  ##   loop and fall from https to http.
  var
    current = url
    seen = @[url]
    notes: seq[string]
  for hop in 0..COUNT_REDIRECTS_MAX:
    let exchanged = exchange("GET " & current, current, "", @[], none(Credential),
        BYTES_PAGE_MAX, MS_DEADLINE_PAGE, command, context)
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
  let command = parsed.get
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
    let found = settings.service.findCredential
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
    exchanged = exchange("POST " & body, settings.endpoint, body, settings.toHeaders,
        credential, BYTES_REPLY_MAX, MS_DEADLINE_SERVICE, command, context)
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
