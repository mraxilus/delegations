## Drive built `suggester` through real recordings, environment, streams and loopback servers:
##   suite compiles `app/suggester.nim`, then drives binary it built, so verdict holds for that
##   build (IX.5-6).
##   CLL covers no service, so suite is `Internal:`, tests named by behaviour (Article IX.10).
##   Binary builds with `-d:ssl`, as it ships, but without `-d:release`, so checks of debug build
##     stay on: sibling of `compileSuggester` in `tools/build.nim` (II.9). Binary, recordings and
##     compiler cache live in fresh directory under `getTempDir`, named by fixed prefix and
##     process, and removed at end. Cost: compile adds seconds to every run of suite.
##   Environment reaches binary as shell prefix, never through `putEnv`: each run blanks every
##     variable binary reads, usual name of each credential and every proxy variable, so
##     environment of host never reaches run, and names sink at `ANTHROPIC_BASE_URL`, which no
##     run may reach. Standard output and error go to files, so tag and report are read apart;
##     standard input comes from file, so run reading it meets end, never pipe left open.
##   `SSL_CERT_FILE` and `SSL_CERT_DIR` pass from host on purpose: `newContext` reads them for
##     trusted roots, which tunnel test needs, and prefix can set either empty, never unset it,
##     while empty one names no root, so context fails.
##     Cost: verdict of tunnel test rests on roots of host, as every https request does.
##   Expected outcome comes from pure pipeline: `toPassage` or `readPage`, `toBody` within
##     `requestService`, `stamp`, `readReply`, `toReport` and `explain`; so suite holds wiring,
##     `test_suggestions.nim` holds each step, and `test_exchanges.nim` holds transport. Problems
##     of settings and credential, and details of refused recordings (`pathShown`,
##     `detailMalformed`), are written out in full: `readSettings`, `findCredential` and
##     `exchange` are private to binary, so suite holds their wording.
##   Servers are raw listeners of `std/asyncnet` on `127.0.0.1`, at port system chooses: each
##     reads request byte for byte, since `std/asynchttpserver` keeps last of repeated header
##     lines, answers reply its target routes to, then closes connection. Suite drives them by
##     `poll` while child runs, and exit of child ends wait, so no verdict reads clock (Article
##     IX.12).
##   Replies are documented shapes of `tools/examples.nim`, or shapes built here after them;
##     none is captured.
##   Random passages, settings and replies, and random texts given, are drawn into pools
##     allocated once, after one seeding per test, and served by `served`.
##   Labels of recordings suite writes hold control bytes, bidirectional marks, ill-formed UTF-8
##     and more than `RUNES_SHOWN` characters: replay note names label made printable and cut,
##     as report names other outside text.
##   Record makes its directory before it sends, refusing where it cannot, so nothing is paid
##     for; recording it cannot write after reply is named in note, and reply is read still.
##     Error text is system's, so checks read its frame: problem, one line of error, then path.
##     Cost: write or read refused by permission stays undriven, since suite may run as root,
##     whom no permission refuses; file or directory in way of recording stands in for write,
##     and link to `/proc/self/mem`, whose read fails even for root, stands in for read.
##   Modes of directories and recordings record makes are read back as set, whatever umask of
##     host, since binary names mode where it makes each.
##   Cost: no root signs loopback server, so TLS past tunnel request and name lookup stay
##     undriven; deadline reads real clock, so its placeholder skips (Article IX.9).

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[
  asyncdispatch, asyncnet, json, options, os, osproc, random, sequtils, strutils, unittest, uri,
]
from std/posix import chmod, Mode
from std/unicode import Rune, toUTF8

import ../../app/exchanges
from ../../app/suggester {.all.} import COUNT_REDIRECTS_MAX, USAGE
import ../../src/lojban_tagger/[suggestions, tags]
import ../../tools/examples


type
  Outcome = object  ## Define what one run of `suggester` prints and exits with.
    output: string  ## Standard output.
    report: string  ## Standard error.
    code: int  ## Exit code.

  Heard = object  ## Define one request server read, byte for byte.
    lines: seq[string]  ## Request line, then each header line, line breaks dropped.
    body: string  ## Body, as many bytes as `content-length` names.

  Server = ref object  ## Define loopback server answering by target, shared with its loop.
    socket: AsyncSocket  ## Listener on `127.0.0.1`.
    port: int  ## Port system chose.
    routes: seq[(string, Reply)]  ## Reply of each target request line names; other is missing.
    heard: seq[Heard]  ## Each request read, in order.
    accepting: Future[void]  ## Loop accepting clients; ends once listener closes.

  Binary = object  ## Define built `suggester`, beside sink each run names at `KEY_BASE`.
    path: string  ## Binary built.
    sink: Server  ## Server no run may reach.

  Sample = object  ## Define one random replay: text given, settings and environment, recording.
    arguments: seq[string]  ## Text given, as arguments binary joins by one space.
    settings: Settings  ## Settings binary should read from environment.
    environment: seq[(string, string)]  ## Variables naming settings.
    reply: Reply  ## Reply recording holds.
    label: string  ## Label recording holds, of `LABELS`.


const
  PREFIX_DIRECTORY = "lojban_tagger_suite_suggester_"  ## Opening of temporary directory name.
  NIM = getCurrentCompilerExe()  ## Compiler building suite, which builds `suggester` too.
  PATH_APP = currentSourcePath().parentDir.parentDir.parentDir / "app" / "suggester.nim"
    ## Source of `suggester`, found from this file.
  KEY_SERVICE = "LOJBAN_TAGGER_SERVICE"  ## Environment name binary reads service from.
  KEY_ENDPOINT = "LOJBAN_TAGGER_ENDPOINT"  ## Environment name binary reads endpoint from.
  KEY_MODEL = "LOJBAN_TAGGER_MODEL"  ## Environment name binary reads model from.
  KEY_EFFORT = "LOJBAN_TAGGER_EFFORT"  ## Environment name binary reads effort from.
  KEY_CREDENTIAL = "LOJBAN_TAGGER_API_KEY"  ## Environment name binary reads credential from first.
  KEY_WORKSPACE = "LOJBAN_TAGGER_WORKSPACE"  ## Environment name binary reads workspace from.
  KEY_BASE = "ANTHROPIC_BASE_URL"  ## Environment name agent reads endpoint from; binary never does.
  LUT_KEY_CREDENTIAL_BY_SERVICE: array[Service, string] =
    ["ANTHROPIC_API_KEY", "OPENROUTER_API_KEY", ""]
    ## Usual name of credential of each service, which binary reads second; `chat` has none.
  NAMES_CREDENTIAL = @[KEY_CREDENTIAL] & @LUT_KEY_CREDENTIAL_BY_SERVICE.filterIt(it.len > 0)
    ## Variables binary reads credential from, under any service.
  NAMES_PROXY = ["HTTPS_PROXY", "HTTP_PROXY", "NO_PROXY", "http_proxy", "https_proxy", "no_proxy"]
    ## Proxy variables, in both cases curl and host set.
  NAMES_BLANK = @[KEY_EFFORT, KEY_ENDPOINT, KEY_MODEL, KEY_SERVICE, KEY_WORKSPACE] &
      NAMES_CREDENTIAL & @NAMES_PROXY
    ## Variables each run blanks where test gives no value: each binary reads, and every proxy.
  MS_POLL = 5
    ## Most milliseconds `poll` waits for event while child runs; exit of child ends loop, so no
    ##   verdict reads time.
  CREDENTIAL_SUITE = "credential-for-suite"  ## Credential live and record runs carry.
  WORKSPACE_LONG = "wrkspc_" & "a".repeat(122)  ## Workspace of 129 bytes, one past cap.
  PROBLEM_WORKSPACE = "Workspace should open with `wrkspc_` and hold at most 128 bytes of " &
      "visible ASCII; got "
    ## Opening of problem binary gives where it refuses workspace of `claude`.
  MODEL_SUITE = "model-of-suite"  ## Model runs name where service has none, or default moves.
  MODEL_SERVED = "model-served"  ## Model reply names where it is not model asked.
  GLOSS_SUITE = "gloss of suite"  ## Gloss answers give where test names none.
  LABEL_SUITE = "documented shape, built in suite"  ## Label of recordings suite builds itself.
  PATH_SERVICE = "/v1/messages"  ## Path fake service answers at.
  STATUS_MISSING = 404  ## Status server answers where no route names target.
  TEXT_GIVEN = "datnyvreji"  ## Text reading as tag already, i.e. `datni+vreji`.
  FORM_GIVEN = "datnyvei"  ## Form 4.12 prefers for `TEXT_GIVEN`, which binary prints.
  TEXT_GIVEN_LONG = "lotconrotybanbalbapybembedbejbesybefybevbixybimbolbogbotmlatu"
    ## Text reading as tag of 18 words in 61 bytes, which binary rendered without bound.
  PIECE_PAGE = "Alice was beginning to get very tired. "  ## Text large page repeats.
  SAMPLES_REPLAY = 200  ## Random replays wiring law reads, seeded.
  FLOOR_REPLAYED = 180
    ## Fewest random replays whose text reads as no tag and holds visible character; 199 read at
    ##   seed `0`.
  FLOOR_SUGGESTED = 24  ## Fewest random replays printing tag; 32 read at seed `0`.
  FLOOR_REFUSED = 140  ## Fewest random replays refused; 167 read at seed `0`.
  FLOOR_CUT = 8  ## Fewest random replays whose passage is cut; 14 read at seed `0`.
  SAMPLES_GIVEN = 200  ## Random texts given shortcut law reads, seeded.
  FLOOR_GIVEN = 100  ## Fewest random texts read as tag; 128 read at seed `0`.
  FLOOR_ASKED = 55  ## Fewest random texts sent to service; 72 read at seed `0`.
  SAMPLES_FLAGS = 100  ## Random flags usage law reads, seeded.
  FLOOR_FLAGS = 80
    ## Fewest random flags refused, past guard of flags usage takes; 97 read at seed `0`.
  PIECES_FLAG = ["-", "h", "help", "record", "replay", ":", "=", " ", "dir", "R", "\xC3\xA9", "\t"]
    ## Pieces random flag joins after its `-`: dashes, names of help and of modes, their
    ##   separators and wrong ones, directory, capital, multibyte and whitespace.
  SAMPLES_BLANK = 100  ## Random texts of one to three code points blank law reads, seeded.
  FLOOR_BLANK = 50  ## Fewest random texts `isBlank` reads as blank; 65 read at seed `0`.
  FLOOR_VISIBLE = 25  ## Fewest random texts holding visible character; 35 read at seed `0`.
  CODE_LOW_MAX = 0x3100
    ## Highest code point of low run random texts draw from: C0, Latin, C1, general punctuation,
    ##   spaces and marks up to ideographic space; no zero, which no argument carries.
  CODES_HIGH = [0xFEFF, 0xFFFD, 0x1F600]
    ## Code points past low run random texts draw too: byte order mark, replacement, emoji.
  BYTES_FIELDS_MAX = 65_536
    ## Bytes recording file may hold past its request and cap of its body, as binary sets it.
  WORDS_PASSAGE = [
    "Alice", "was", "tired", "mi", "ciska", "<passage>", "</passage>", "&amp;", "\"sister\"",
    "it's", "line\nbreak", "tab\there", "caf\xC3\xA9", "\xE2\x80\xA6", "\xC4\x89u", "\xFF",
    "\xE2\x80", "\xED\xA0\x80", "\x01", "\x7F", "\xE2\x80\xAE",
  ]
    ## Words random passages draw: markup, quotes, line breaks, multibyte, ill-formed bytes,
    ##   control and bidirectional marks, Lojban; no zero byte, which no argument carries.
  PIECE_LONG = "Alice \xC3\xA9 "  ## Text long passage repeats: ASCII, then two bytes of one rune.
  COUNT_LONG_MIN = BYTES_PASSAGE_MAX div PIECE_LONG.len + 1
    ## Fewest pieces long passage holds, so it outgrows `BYTES_PASSAGE_MAX`.
  COUNT_LONG_EXTRA = 400  ## Most pieces long passage holds past `COUNT_LONG_MIN`.
  WORDS_ANSWER = [
    "cukta", "datni", "vreji", "ciska", "xatra", "pixra", "tatpi", "brodi", "se", "nu", "na'e",
    "datnyvei", "Ciska", " ci,ska ", "datna", "qwzx", "lo",
  ]
    ## Words random answers draw: gismu, cmavo, lujvo, folded spellings, and words reader refuses.
  GLOSSES = [GLOSS_SUITE, "  gloss \t spaced  ", "gloss \xE2\x80\xAE reversed"]
    ## Glosses random answers give: plain, spaced, and holding bidirectional mark.
  STATUSES_ERROR = [400, 401, 413, 429, 500, 529]  ## Statuses random error replies take.
  LUT_REASON_DECLINED_BY_SERVICE: array[Service, string] =
    ["refusal", "content_filter", "content_filter"]
    ## Stop reason of reply declining in wire format of each service.
  LUT_REASON_TRUNCATED_BY_SERVICE: array[Service, string] = ["max_tokens", "length", "length"]
    ## Stop reason of reply stopped at limit in wire format of each service.
  BODIES_MALFORMED = ["", "not json", "[]", "{\"tanru\": [\"ciska\"]"]
    ## Bodies of 2xx reply reading as no reply of either wire format.
  BODY_ERROR_INSIDE = """{"error":{"code":502,"message":"provider down"}}"""
    ## Body of 200 OpenRouter gives where provider fails after it accepts request, as review found.
  LABEL_FOUND = "evil \e[31mred\e[0m \u202Eabc"
    ## Label suite review found printed raw: escape sequences, then right-to-left override.
  LABEL_CONTROLS = block:
    ## Label holding each code point below U+00A0 report escapes: C0 but line feed, `DEL`, C1.
    var label = "controls "
    for code in 0x00..0x9F:
      if code in 0x20..0x7E or code == 0x0A: continue
      label.add (if code < 0x80: $char(code) else: "\xC2" & char(code))
    label
  LABELS_UNPRINTABLE = [
    LABEL_FOUND,
    LABEL_CONTROLS,
    "marks \u061C \u200E \u200F \u202A \u202B \u202C \u202D \u202E \u2066 \u2067 \u2068 \u2069",
    "ill-formed \xFF \xE2\x80 \xED\xA0\x80 \xC0\xAF",
    "\xC3\xA9".repeat(RUNES_SHOWN + 1),
  ]
    ## Labels note makes printable or cuts: as found, controls, every bidirectional mark,
    ##   ill-formed UTF-8, and one character past `RUNES_SHOWN`.
  LABELS = @[LABEL_MESSAGES, LABEL_CHAT, LABEL_SUITE, "recorded 2026-10-29", ""] &
      @LABELS_UNPRINTABLE
    ## Labels random recordings carry: documented shapes, date, empty, and each unprintable.
  CHARACTERS_CONTROL = {'\x00'..'\x09', '\x0B'..'\x1F', '\x7F'}
    ## Bytes of C0 but line feed, and `DEL`, which act on terminal; no report holds one.
  GISMU_GIVEN = ["cukta", "datni", "gerku", "pixra", "tatpi", "vreji", "xatra"]
    ## Gismu random texts given join into tag.
  TEXTS_ASKED = [
    "se", "lo", "file", "Lojban", "mi ciska lo xatra", "datni+vreji", "datni vreji", "datna",
    "cihska", "qwzx",
  ]
    ## Texts reading as no tag: cmavo alone, English, Lojban prose, tanru joined by `+` or by
    ##   space, unlisted word, unknown letter.
  USERS_REDIRECT = ["", "alice@", "alice:SECRET-PASSWORD@"]
    ## User parts redirect URLs hold: none, name alone, and name with password.
  QUERIES_REDIRECT = ["", "?", "?access_token=SECRET-TOKEN"]
    ## Queries redirect URLs hold: none, empty, and token of capability URL.
  FRAGMENTS_REDIRECT = ["", "#", "#SECRET-FRAGMENT"]
    ## Fragments redirect URLs hold: none, empty, and token.
  SCHEMES_REDIRECT = [("http", true), ("https", true), ("http", false), ("ftp", false)]
    ## Scheme of redirect URL beside whether it loops: loop by http and by https; else location
    ##   refused, falling from https to http, or naming ftp.



#[ Replies ]#

func example(name: string): Example =
  ## Find worked example of `tools/examples.nim` by name.
  EXAMPLES[EXAMPLES.mapIt(it.name).find(name)]


func urlLoopback(port: int, path: string): string =
  ## Build URL of path on `127.0.0.1` at port.
  "http://127.0.0.1:" & $port & path


func toSettings(service: Service, port: int): Settings =
  ## Build default settings of service sending to fake service at port; `chat`, which has no
  ##   model by default, names `MODEL_SUITE`.
  result = service.toSettings
  result.endpoint = urlLoopback(port, PATH_SERVICE)
  if service == Service.Chat: result.model = MODEL_SUITE


func toEnvironment(settings: Settings): seq[(string, string)] =
  ## Name settings in environment as binary reads them, beside credential of suite.
  result = @[
    (KEY_SERVICE, $settings.service),
    (KEY_ENDPOINT, settings.endpoint),
    (KEY_MODEL, settings.model),
    (KEY_CREDENTIAL, CREDENTIAL_SUITE),
  ]
  if settings.effort.isSome: result.add (KEY_EFFORT, $settings.effort.get)


func toAnswer(words: openArray[string], gloss: string = GLOSS_SUITE): string =
  ## Render answer of schema naming words, as model gives it.
  $ %*{"tanru": words, "gloss": gloss}


func toReplyAnswer(service: Service; answer, model: string): Reply =
  ## Wrap answer in reply of wire format of service, as worked examples do.
  if service == Service.Claude: toReplyMessages(answer, model) else: toReplyChat(answer, model)


func toReplyError(service: Service, status: int): Reply =
  ## Build error reply in wire format of service: envelope of Messages API or of chat completion.
  let body =
    if service == Service.Claude:
      %*{"type": "error", "error": {"type": "overloaded_error", "message": "Overloaded"}}
    else: %*{"error": {"message": "Provider returned error", "code": status}}
  Reply(status: status, content_type: "application/json", body: $body)


func toReplyStopped(service: Service; reason, model: string): Reply =
  ## Build 2xx reply in wire format of service stopping for reason, holding no answer.
  let body =
    if service == Service.Claude:
      %*{
        "id": "msg_suite", "type": "message", "role": "assistant", "model": model, "content": [],
        "stop_reason": reason, "stop_sequence": nil, "stop_details": {"category": "cyber"},
      }
    else:
      %*{
        "id": "gen-suite", "object": "chat.completion", "model": model,
        "choices": [{
          "index": 0, "finish_reason": reason,
          "message": {"role": "assistant", "content": nil, "refusal": nil},
        }],
      }
  Reply(status: 200, content_type: "application/json", body: $body)


func toReplies(service: Service, model: string): seq[Reply] =
  ## Build reply of each outcome `readReply` gives, in wire format of service: tag, error by status,
  ##   error inside 2xx, choice ending in error, redirect, refusal, stop at limit, body of no reply,
  ##   and answer naming unlisted word, ending in cmavo, past cap, or failing readback.
  @[
    toReplyAnswer(service, toAnswer(["xatra", "ciska"]), model),
    toReplyError(service, 401),
    toReplyError(service, 529),
    Reply(status: 200, content_type: "application/json", body: BODY_ERROR_INSIDE),
    toReplyStopped(service, "error", model),
    Reply(status: 307, location: "/elsewhere"),
    toReplyStopped(service, LUT_REASON_DECLINED_BY_SERVICE[service], model),
    toReplyStopped(service, LUT_REASON_TRUNCATED_BY_SERVICE[service], model),
    Reply(status: 200, content_type: "application/json", body: "not json"),
    toReplyAnswer(service, toAnswer(["datna"]), model),
    toReplyAnswer(service, toAnswer(["ciska", "se"]), model),
    toReplyAnswer(service, newSeqWith(COUNT_WORDS_MAX + 1, "ciska").toAnswer, model),
    toReplyAnswer(service, toAnswer(["brodi", "ciska"]), model),
  ]



#[ Servers ]#

func toMessage(reply: Reply): string =
  ## Render reply as server writes it: status line with no reason, each header reply holds,
  ##   length, close, then whole body.
  result = "HTTP/1.1 " & $reply.status & " \r\n"
  for (name, value) in [
    ("content-type", reply.content_type),
    ("content-encoding", reply.content_encoding),
    ("location", reply.location),
  ]:
    if value.len > 0: result.add name & ": " & value & "\r\n"
  result.add "content-length: " & $reply.body.len & "\r\nconnection: close\r\n\r\n" & reply.body


func values(heard: Heard, name: string): seq[string] =
  ## Read value of each header line naming `name`, compared without case.
  for i in 1..<heard.lines.len:
    let at = heard.lines[i].find(": ")
    if at > 0 and heard.lines[i][0..<at].toLowerAscii == name.toLowerAscii:
      result.add heard.lines[i][at+2 .. ^1]


func target(heard: Heard): string =
  ## Read target request line names: path, absolute URL sent through proxy, or host of tunnel.
  let words = heard.lines[0].split(' ')
  if words.len > 1: words[1] else: ""


proc answerClient(server: Server, client: AsyncSocket) {.async.} =
  ## Read one request of client, keep it, and answer reply its target routes to.
  var heard: Heard
  while true:
    let line = await client.recvLine()
    if line in ["", "\r\n"]: break
    heard.lines.add line
  if heard.lines.len == 0: return
  let lengths = heard.values("content-length")
  if lengths.len > 0: heard.body = await client.recv(lengths[0].parseInt)
  server.heard.add heard
  var reply = Reply(status: STATUS_MISSING)
  for (target, routed) in server.routes:
    if target == heard.target: reply = routed
  await client.send(reply.toMessage)


proc acceptClients(server: Server) {.async.} =
  ## Accept clients until listener closes, answering each in turn, then closing it.
  while true:
    var client: AsyncSocket
    try:
      client = await server.socket.accept()
    except CatchableError:
      return  # listener closed
    try:
      await server.answerClient(client)
    except CatchableError:
      discard  # client gone mid answer; its run, not server, holds verdict
    client.close()


proc startServer(routes: seq[(string, Reply)] = @[]): Server =
  ## Start server on `127.0.0.1` at port system chooses, answering routes until `stopServer`.
  result = Server(socket: newAsyncSocket(), routes: routes)
  result.socket.setSockOpt(OptReuseAddr, true)
  result.socket.bindAddr(Port(0), "127.0.0.1")
  result.socket.listen()
  result.port = int(result.socket.getLocalAddr[1])
  result.accepting = result.acceptClients


proc stopServer(server: Server) =
  ## Close listener, then drive loop until loop accepting clients ends.
  server.socket.close()
  waitFor server.accepting


proc socketRefusing(): AsyncSocket =
  ## Bind socket on `127.0.0.1` at port system chooses, never listening and never reused, so its
  ##   port refuses each connection, and no other socket takes port, until caller closes it.
  ##   Sibling of `socketRefusing` in `test_exchanges.nim` (II.9).
  result = newAsyncSocket()
  result.bindAddr(Port(0), "127.0.0.1")



#[ Runs ]#

func toPrefix(environment: openArray[(string, string)]): string =
  ## Render shell prefix: each name of `NAMES_BLANK` blank unless environment gives it value,
  ##   then each other name environment gives; later value of one name wins.
  var assignments = NAMES_BLANK.mapIt((it, ""))
  for (name, value) in environment:
    let at = assignments.mapIt(it[0]).find(name)
    if at < 0: assignments.add (name, value)
    else: assignments[at][1] = value
  assignments.mapIt(it[0] & "=" & quoteShell(it[1])).join(" ")


proc run(
  binary: Binary,
  environment: openArray[(string, string)],
  arguments: openArray[string],
  input = "",
  path_input = "",
): Outcome =
  ## Run binary under environment, sink named at `KEY_BASE`, standard input read from file
  ##   holding `input`, or from `path_input` where named, streams to files; drive servers by
  ##   `poll` until child exits.
  ##   Standard input is always file, so run reading it meets end, never pipe left open.
  let path_read = if path_input.len > 0: path_input else: binary.path.parentDir / "input"
  if path_input.len == 0: writeFile(path_read, input)
  let
    path_output = binary.path.parentDir / "output"
    path_report = binary.path.parentDir / "report"
    command = toPrefix(@[(KEY_BASE, urlLoopback(binary.sink.port, ""))] & @environment) & " " &
        (@[binary.path] & @arguments).map(quoteShell).join(" ") & " <" &
        quoteShell(path_read) & " >" & quoteShell(path_output) & " 2>" & quoteShell(path_report)
    child = startProcess(command, options = {poEvalCommand})
  while child.running: poll(MS_POLL)
  result = Outcome(
    output: readFile(path_output),
    report: readFile(path_report),
    code: child.waitForExit,
  )
  child.close()


func requestService(settings: Settings, passage: Passage): string =
  ## Build request of service exchange as binary stamps and keeps it: method and endpoint, then
  ##   body on next line, so recording replays for its endpoint alone.
  "POST " & settings.endpoint & "\n" & settings.toBody(passage)


func pathRecording(directory, request: string): string =
  ## Build path binary keeps recording of request at: stamp of request, in directory.
  directory / (request.stamp & ".recording")


proc writeRecordings(directory: string, recordings: openArray[Recording]) =
  ## Write each recording under stamp of its request, as binary names it, making directory.
  createDir(directory)
  for recording in recordings:
    writeFile(pathRecording(directory, recording.request), recording.toText)


func noteCredential(name: string): string =
  ## Render note naming variable credential was read from.
  "Credential read from `" & name & "`."


func noteReplayed(path, label: string): string =
  ## Render note naming recording replayed, then its label made printable and cut, as report
  ##   makes outside text.
  "Reply replayed from `" & path & "`: " & label.toPrintable(RUNES_SHOWN) & "."


func noteWritten(path: string): string =
  ## Render note naming recording written.
  "Reply written to `" & path & "`."


func toSuggestion(failure: Failure, detail: string): Suggestion =
  ## Build suggestion failed for reason, detail made printable as binary makes it.
  Suggestion(is_suggested: false, failure: failure, detail: detail.toPrintable(RUNES_SHOWN))


func toSuggestionRecording(detail: string): Suggestion =
  ## Build suggestion refused with `Recording`, detail as binary renders it: never cut whole.
  Suggestion(is_suggested: false, failure: Failure.Recording, detail: detail)


func pathShown(directory, request: string): string =
  ## Render path of recording of request as refusal shows it: directory made printable and cut
  ##   alone, then name holding stamp, whole.
  directory.toPrintable(RUNES_SHOWN) / (request.stamp & ".recording")


func detailMalformed(recorded: Recorded; directory, request: string): string =
  ## Render detail of malformed recording: problem reader names, period dropped, then its line
  ##   and path shown.
  var problem = recorded.problem
  problem.removeSuffix('.')
  problem & " at line " & $recorded.line & " of " & pathShown(directory, request)


func toOutcome(
  suggestion: Suggestion, passage: Passage, model: string, notes: openArray[string]
): Outcome =
  ## Build outcome pure pipeline gives once passage exists: each note, then report of
  ##   suggestion; tag alone on output and exit 0, or nothing and exit 1.
  Outcome(
    output: if suggestion.is_suggested: $suggestion.tag & "\n" else: "",
    report: notes.mapIt(it & "\n").join & suggestion.toReport(passage, model),
    code: if suggestion.is_suggested: 0 else: 1,
  )


func toOutcome(suggestion: Suggestion, notes: openArray[string]): Outcome =
  ## Build outcome of page that gave no passage: each note, then explanation; exit 1.
  Outcome(report: notes.mapIt(it & "\n").join & suggestion.explain & "\n", code: 1)


func toOutcome(failure: Failure, detail: string, notes: openArray[string]): Outcome =
  ## Build outcome of page that gave no passage, detail made printable as binary makes it.
  toSuggestion(failure, detail).toOutcome(notes)


func toOutcomeGiven(text: string): Outcome =
  ## Build outcome of text reading as tag already: form alone on output, report naming tanru;
  ##   failure explained alone, exit 1.
  let given = text.readTagGiven.get
  if not given.is_suggested: return Outcome(report: given.explain & "\n", code: 1)
  Outcome(output: $given.tag & "\n", report: toReportGiven(text, given.tag), code: 0)


func isDate(text: string): bool =
  ## Test text is date as `yyyy-MM-dd` writes it: four digits, two, then two, joined by `-`.
  text.len == 10 and text[4] == '-' and text[7] == '-' and
      (text[0..3] & text[5..6] & text[8..9]).allIt(it in Digits)


func readFramed(text, opening, closing: string): Option[string] =
  ## Read what text holds between opening and closing; `none` where text holds other frame.
  if text.len < opening.len + closing.len or not text.startsWith(opening) or
      not text.endsWith(closing):
    return none(string)
  some(text[opening.len..<text.len-closing.len])



#[ Samples ]#

proc argumentsRandom(): seq[string] =
  ## Draw text given as one to four arguments of one to six words of `WORDS_PASSAGE` each; one
  ##   time in twenty, one argument past `BYTES_PASSAGE_MAX`, so passage is cut.
  if rand(19) == 0: return @[PIECE_LONG.repeat(COUNT_LONG_MIN + rand(COUNT_LONG_EXTRA))]
  for _ in 1..rand(1..4):
    var words: seq[string]
    for _ in 1..rand(1..6): words.add WORDS_PASSAGE.sample
    result.add words.join(" ")


proc replyRandom(service: Service, model: string): Reply =
  ## Draw reply in wire format of service: answer of one to seven words of `WORDS_ANSWER`, by
  ##   model asked or other, most often; else error status, refusal, stop at limit, body of no
  ##   reply, or answer cut or coded.
  let served = if rand(3) == 0: MODEL_SERVED else: model
  var words: seq[string]
  for _ in 1..rand(1 .. COUNT_WORDS_MAX + 1): words.add WORDS_ANSWER.sample
  result = toReplyAnswer(service, toAnswer(words, GLOSSES.sample), served)
  case rand(9)
  of 5: result = toReplyError(service, STATUSES_ERROR.sample)
  of 6: result = toReplyStopped(service, LUT_REASON_DECLINED_BY_SERVICE[service], served)
  of 7: result = toReplyStopped(service, LUT_REASON_TRUNCATED_BY_SERVICE[service], served)
  of 8: result = Reply(status: 200, content_type: "application/json", body: BODIES_MALFORMED.sample)
  of 9:
    if rand(1) == 0: result.is_cut = true
    else: result.content_encoding = "gzip"
  else: discard


proc sampleRandom(endpoint: string): Sample =
  ## Draw random replay: arguments; service, naming endpoint, model and effort one time in two
  ##   each, and `chat` naming endpoint and model always; reply in its wire format; label.
  let service = rand(Service)
  result = Sample(
    arguments: argumentsRandom(),
    settings: service.toSettings,
    environment: @[(KEY_SERVICE, $service)],
  )
  if service == Service.Chat or rand(1) == 0:
    result.settings.endpoint = endpoint
    result.environment.add (KEY_ENDPOINT, endpoint)
  if service == Service.Chat or rand(1) == 0:
    result.settings.model = MODEL_SUITE
    result.environment.add (KEY_MODEL, MODEL_SUITE)
  if rand(1) == 0:
    let effort = rand(Effort)
    result.settings.effort = some(effort)
    result.environment.add (KEY_EFFORT, $effort)
  result.reply = replyRandom(service, result.settings.model)
  result.label = LABELS.sample


proc textGivenRandom(): string =
  ## Draw text given: tag of one to three gismu of `GISMU_GIVEN` in form `$` renders, its case,
  ##   commas or whitespace changed, or padded past `BYTES_ELEMENT_MAX`, one time in eight each;
  ##   else, one time in four, text of `TEXTS_ASKED`.
  if rand(3) == 0: return TEXTS_ASKED.sample
  var words: seq[string]
  for _ in 1..rand(1..3): words.add GISMU_GIVEN.sample
  result = $readTanru(words.join("+")).get
  case rand(7)
  of 0: result = result.toUpperAscii
  of 1: result.insert(",", rand(result.len))
  of 2: result = " " & result & "\t"
  of 3: result.add " ".repeat(BYTES_ELEMENT_MAX)
  else: discard


proc poolSamples(endpoint: string): seq[Sample] =
  ## Draw `SAMPLES_REPLAY` random replays into pool allocated once; caller seeds first.
  result = newSeqOfCap[Sample](SAMPLES_REPLAY)
  for _ in 1..SAMPLES_REPLAY: result.add sampleRandom(endpoint)


proc poolGiven(): seq[string] =
  ## Draw `SAMPLES_GIVEN` random texts given into pool allocated once; caller seeds first.
  result = newSeqOfCap[string](SAMPLES_GIVEN)
  for _ in 1..SAMPLES_GIVEN: result.add textGivenRandom()


proc flagRandom(): string =
  ## Draw flag: `-`, then one to four pieces of `PIECES_FLAG`, so it may spell `--`, help, mode
  ##   with `:`, `=` or space, or none of them.
  result = "-"
  for _ in 1..rand(1..4): result.add PIECES_FLAG.sample


proc poolFlags(directory: string): seq[seq[string]] =
  ## Draw `SAMPLES_FLAGS` random argument lists into pool allocated once: random flag, after
  ##   flag of replay into directory one time in two, then text; caller seeds first.
  result = newSeqOfCap[seq[string]](SAMPLES_FLAGS)
  for _ in 1..SAMPLES_FLAGS:
    let leading = if rand(1) == 0: @["--replay:" & directory] else: @[]
    result.add leading & @[flagRandom(), "mi ciska"]


proc poolBlank(): seq[string] =
  ## Draw `SAMPLES_BLANK` random texts into pool allocated once: one to three code points, each
  ##   one exported `isBlank` reads as blank three times in four, else any code point drawn;
  ##   caller seeds first.
  let
    codes = toSeq(1..CODE_LOW_MAX) & @CODES_HIGH
    blanks = codes.filterIt(Rune(it).toUTF8.isBlank)
  result = newSeqOfCap[string](SAMPLES_BLANK)
  for _ in 1..SAMPLES_BLANK:
    var text = ""
    for _ in 1..rand(1..3): text.add Rune(if rand(3) < 3: blanks.sample else: codes.sample).toUTF8
    result.add text


func isFlagTaken(flag: string): bool =
  ## Test usage takes flag: `--`, or mode naming nonempty directory; `-` alone is passage.
  flag == "--" or ((flag.startsWith("--record:") or flag.startsWith("--replay:")) and
      flag.len > "--record:".len)


iterator served[T](pool: seq[T]): lent T =
  ## Serve each sample of pool in order, with no copy.
  for i in 0..<pool.len: yield pool[i]



suite "Internal: Suggester":
  let
    directory = getTempDir() / (PREFIX_DIRECTORY & $getCurrentProcessId())
    binary = Binary(path: directory / "suggester", sink: startServer())
  removeDir(directory)
  createDir(directory)
  let (output_compile, code_compile) = execCmdEx(
    quoteShell(NIM) & " c --hints:off -d:ssl --nimcache:" & quoteShell(directory / "cache") &
    " -o:" & quoteShell(binary.path) & " " & quoteShell(PATH_APP),
  )


  test "binary builds from `app/suggester.nim` with TLS, as it ships":
    checkpoint output_compile
    check code_compile == 0  # one command rebuilds, then drives (IX.6)
    check fileExists(binary.path)  # binary written where asked


  test "replay of each worked example prints what pure pipeline gives, under both services":
    for example in EXAMPLES:
      for service in [Service.Claude, Service.OpenRouter]:
        let
          directory_case = directory / "examples" / (example.name & "_" & $service)
          recordings = example.toRecordings(service)
          expected = toOutcome(
            service.readReply(recordings[^1].reply),
            example.toPassage,
            service.toSettings.model,
            recordings.mapIt(noteReplayed(pathRecording(directory_case, it.request), it.label)),
          )
        writeRecordings(directory_case, recordings)
        var argument_lists = @[@[example.argument]]
        if example.hops.len == 0: argument_lists.add example.argument.split(' ')
        for arguments in argument_lists:
          let
            replay = @["--replay:" & directory_case]
            outcome = binary.run([(KEY_SERVICE, $service)], replay & arguments)
          check outcome == expected  # output, report and exit of pure pipeline, notes first
          check outcome.output == $readTanru(example.tanru).get & "\n"  # tanru example documents


  test "replay of random passage, settings and reply prints what pure pipeline gives":
    randomize(0)
    let
      directory_case = directory / "random"
      replay = @["--replay:" & directory_case]
      endpoint = startServer()
      pool = poolSamples(urlLoopback(endpoint.port, PATH_SERVICE))
    createDir(directory_case)
    var (passed, count_suggested, count_refused, count_cut) = (0, 0, 0, 0)
    for sample in served(pool):
      let text = sample.arguments.join(" ")
      if text.readTagGiven.isSome or text.isBlank:
        continue  # text reading as tag asks nothing, and blank text is usage; laws below
      inc passed
      let
        passage = text.toPassage
        request = requestService(sample.settings, passage)
        path = pathRecording(directory_case, request)
        suggestion = sample.settings.service.readReply(sample.reply)
      writeFile(path, Recording(label: sample.label, request: request, reply: sample.reply).toText)
      let outcome = binary.run(sample.environment, replay & sample.arguments)
      check outcome == toOutcome(suggestion, passage, sample.settings.model,
          [noteReplayed(path, sample.label)])  # settings read from environment, reply as read
      if suggestion.is_suggested: inc count_suggested else: inc count_refused
      if passage.is_cut: inc count_cut
    check endpoint.heard.len == 0  # replay opens no socket
    check passed >= FLOOR_REPLAYED  # guard leaves enough texts sent to service
    check count_suggested >= FLOOR_SUGGESTED  # replies printing tag are common
    check count_refused >= FLOOR_REFUSED  # replies refused are common
    check count_cut >= FLOOR_CUT  # passages past `BYTES_PASSAGE_MAX` occur
    stopServer(endpoint)


  test "text reading as tag prints its form and asks nothing, in every mode":
    let
      endpoint = startServer()
      directory_case = directory / "given"
      url_endpoint = urlLoopback(endpoint.port, PATH_SERVICE)
      live = @[(KEY_ENDPOINT, url_endpoint), (KEY_CREDENTIAL, CREDENTIAL_SUITE)]
      expected = Outcome(
        output: FORM_GIVEN & "\n",
        report: toReportGiven(TEXT_GIVEN, readTag(TEXT_GIVEN).tag),
        code: 0,
      )
    for flags in [@[], @["--record:" & directory_case], @["--replay:" & directory_case]]:
      for environment in [
        newSeq[(string, string)](),  # no credential, which live run would need
        @[(KEY_SERVICE, "bogus")],  # service no run accepts
        live,  # credential and endpoint server counting each request
      ]:
        check binary.run(environment, flags & @[TEXT_GIVEN]) == expected  # form, and tanru named
    check endpoint.heard.len == 0  # no service asked
    check not dirExists(directory_case)  # no recording read or written
    stopServer(endpoint)


  test "text reading as tag past `COUNT_WORDS_MAX` words exits 1 with `Long`, reading no setting":
    let expected = Outcome(report: toSuggestion(Failure.Long, "18").explain & "\n", code: 1)
    check binary.run([(KEY_SERVICE, "bogus")], [TEXT_GIVEN_LONG]) ==
        expected  # review finding logic-1, 2026-10-29: memory grew without bound; service unread


  test "text prints form exactly where `readTagGiven` reads it as tag, and asks service else":
    randomize(0)
    let
      directory_case = directory / "asked"  # never made, so recording of each request misses
      settings = Service.Claude.toSettings
      pool = poolGiven()
    var (count_given, count_asked) = (0, 0)
    for text in served(pool):
      let outcome = binary.run([], ["--replay:" & directory_case, text])
      if text.readTagGiven.isSome:
        inc count_given
        check outcome == text.toOutcomeGiven  # form alone, no service asked
        continue
      inc count_asked
      let
        passage = text.toPassage
        shown = pathShown(directory_case, requestService(settings, passage))
      check outcome == toOutcome(toSuggestionRecording("missing at " & shown), passage,
          settings.model, [])  # sent to service, whose recording is missing
    check count_given >= FLOOR_GIVEN  # texts reading as tag are common
    check count_asked >= FLOOR_ASKED  # texts sent to service are common


  test "replay reads no credential and opens no socket, so endpoint and proxy hear nothing":
    let (endpoint, proxy) = (startServer(), startServer())
    for example in EXAMPLES:
      for service in [Service.Claude, Service.OpenRouter]:
        let directory_case = directory / "unread" / (example.name & "_" & $service)
        var
          settings = service.toSettings
          recordings = example.toRecordings(service)
        settings.endpoint = urlLoopback(endpoint.port, PATH_SERVICE)
        recordings[^1].request = requestService(settings, example.toPassage)  # endpoint named
        writeRecordings(directory_case, recordings)
        let outcome = binary.run(
          [
            (KEY_SERVICE, $service),
            (KEY_ENDPOINT, urlLoopback(endpoint.port, PATH_SERVICE)),
            (KEY_CREDENTIAL, "sk-ant-\rrefused"),
            (LUT_KEY_CREDENTIAL_BY_SERVICE[service], "sk-or-\rrefused"),
            ("https_proxy", urlLoopback(proxy.port, "")),
            ("http_proxy", urlLoopback(proxy.port, "")),
          ],
          ["--replay:" & directory_case, example.argument],
        )
        check outcome.code == 0  # tag printed, though live run refuses both credentials
        check outcome.output == $readTanru(example.tanru).get & "\n"  # tag of recordings
        check "Credential" notin outcome.report  # no credential read, so none named
    check endpoint.heard.len == 0  # no socket to endpoint
    check proxy.heard.len == 0  # nor to proxy, for page or service
    stopServer(endpoint)
    stopServer(proxy)


  test "missing recording exits 1 naming file under stamp of request":
    let
      directory_case = directory / "missing"  # never made
      (text, page) = (example("lojban"), example("page"))
      settings = Service.Claude.toSettings
      passage = text.argument.toPassage
      shown_text = pathShown(directory_case, requestService(settings, passage))
      shown_page = pathShown(directory_case, "GET " & page.argument)
    check binary.run([], ["--replay:" & directory_case, text.argument]) ==
        toOutcome(toSuggestionRecording("missing at " & shown_text), passage, settings.model,
        [])  # problem, then stamp of service request named
    check binary.run([], ["--replay:" & directory_case, page.argument]) ==
        toOutcome(toSuggestionRecording("missing at " & shown_page), [])  # stamp of first hop
    check not dirExists(directory_case)  # replay makes nothing
    let
      directory_hops = directory / "hops"
      hops = page.toRecordings(Service.Claude)[0 ..< ^1]
      passage_hops = page.toPassage
      shown_service = pathShown(directory_hops, requestService(settings, passage_hops))
    writeRecordings(directory_hops, hops)
    check binary.run([], ["--replay:" & directory_hops, page.argument]) ==
        toOutcome(toSuggestionRecording("missing at " & shown_service), passage_hops,
        settings.model, hops.mapIt(noteReplayed(pathRecording(directory_hops, it.request),
        it.label)))  # each hop replayed, then stamp of service request named


  test "recording malformed or holding other request exits 1 naming file and line":
    let
      directory_case = directory / "malformed"
      text = example("lojban")
      settings = Service.Claude.toSettings
      passage = text.argument.toPassage
      request = requestService(settings, passage)
      path = pathRecording(directory_case, request)
      reply = toReplyMessages(text.answer, settings.model)
      whole = Recording(label: LABEL_SUITE, request: request, reply: reply).toText
    createDir(directory_case)
    for malformed in [
      "",
      "lojban_tagger recording 2\n" & whole.split('\n', 1)[1],
      whole[0 ..< ^2],
      whole & "\n",
    ]:
      writeFile(path, malformed)
      let recorded = malformed.readRecording
      check not recorded.is_read  # file malformed
      if recorded.is_read: continue
      check binary.run([], ["--replay:" & directory_case, text.argument]) ==
          toOutcome(detailMalformed(recorded, directory_case, request).toSuggestionRecording,
          passage, settings.model, [])  # problem of reader, then line and path
    writeFile(path, Recording(label: LABEL_SUITE, request: "POST {}", reply: reply).toText)
    check binary.run([], ["--replay:" & directory_case, text.argument]) ==
        toOutcome(toSuggestionRecording("other request at " & pathShown(directory_case,
        request)), passage, settings.model, [])  # stamp alone never matches, whole request does


  test "refusal of recording names problem, then path whose directory alone is cut":
    # Review finding logic-10, 2026-10-29: detail was path then problem, cut whole at
    #   `RUNES_SHOWN`, so long directory hid stamp and problem.
    let
      server = startServer()
      settings = Service.Claude.toSettings(server.port)
      text = example("lojban")
      passage = text.argument.toPassage
      request = requestService(settings, passage)
      reply = toReplyMessages(text.answer, settings.model)
      long = directory / "long" / "d".repeat(99) / "e".repeat(99) / "f".repeat(99)
      name = request.stamp & ".recording"
      below = long / "file" / "below"  # file in way of directory record makes
      replay = ["--replay:" & long, text.argument]
    server.routes = @[(PATH_SERVICE, reply)]
    check long.len >= 300  # directory name of 300 characters, past `RUNES_SHOWN`
    let missing = binary.run(settings.toEnvironment, replay)
    check missing == toOutcome(toSuggestionRecording("missing at " & pathShown(long, request)),
        passage, settings.model, [])  # `--replay:<long directory> 'mi ciska lo xatra'`
    createDir(long)
    writeFile(long / name, Recording(label: LABEL_SUITE, request: "POST {}", reply: reply).toText)
    let other = binary.run(settings.toEnvironment, replay)
    check other == toOutcome(toSuggestionRecording("other request at " & pathShown(long,
        request)), passage, settings.model, [])  # other request, then path
    writeFile(long / name, "")
    let malformed = binary.run(settings.toEnvironment, replay)
    check malformed == toOutcome(toSuggestionRecording(detailMalformed("".readRecording, long,
        request)), passage, settings.model, [])  # problem of reader, then line and path
    writeFile(below.parentDir, "")
    let unwritable = binary.run(settings.toEnvironment, ["--record:" & below, text.argument])
    check unwritable.report.readFramed(noteCredential(KEY_CREDENTIAL) &
        "\nRecording should hold this request; got `unwritable: ", " at " &
        pathShown(below, request) & "`.\n").isSome  # error of system, then path
    for outcome in [missing, other, malformed, unwritable]:
      check outcome.code == 1 and name in outcome.report  # stamp named whole, past cut
    check server.heard.len == 0  # nothing sent
    stopServer(server)


  test "recording replays for endpoint it was made for alone, as its request names endpoint":
    # Review finding logic-9, 2026-10-29: request stamped and kept was `POST` and body alone, so
    #   reply recorded from one server replayed as reply of other.
    let
      text = example("lojban")
      passage = text.argument.toPassage
      directory_case = directory / "endpoints"
    for service in Service:
      var (settings_a, settings_b) = (service.toSettings, service.toSettings)
      settings_a.endpoint = "https://a.example.org/v1/messages"  # replay sends nothing to either
      settings_b.endpoint = "https://b.example.org/v1/messages"
      if service == Service.Chat: (settings_a.model, settings_b.model) = (MODEL_SUITE, MODEL_SUITE)
      let
        request_a = requestService(settings_a, passage)
        reply = toReplyAnswer(service, text.answer, settings_a.model)
        directory_service = directory_case / $service
        replay = ["--replay:" & directory_service, text.argument]
      writeRecordings(directory_service, [Recording(label: LABEL_SUITE, request: request_a,
          reply: reply)])
      check binary.run(settings_a.toEnvironment, replay) == toOutcome(service.readReply(reply),
          passage, settings_a.model, [noteReplayed(pathRecording(directory_service, request_a),
          LABEL_SUITE)])  # endpoint recording was made for replays it
      check binary.run(settings_b.toEnvironment, replay) == toOutcome(toSuggestionRecording(
          "missing at " & pathShown(directory_service, requestService(settings_b, passage))),
          passage, settings_b.model, [])  # other endpoint misses it, under its own stamp


  test "replay note names label made printable and cut, as report names other outside text":
    # Regression, found in suite review: note named label as file held it, control bytes raw.
    let
      directory_case = directory / "labels"
      text = example("lojban")
      settings = Service.Claude.toSettings
      passage = text.argument.toPassage
      request = requestService(settings, passage)
      path = pathRecording(directory_case, request)
      reply = toReplyMessages(text.answer, settings.model)
      suggestion = Service.Claude.readReply(reply)
      replay = ["--replay:" & directory_case, text.argument]
    createDir(directory_case)
    writeFile(path, Recording(label: LABEL_FOUND, request: request, reply: reply).toText)
    let found = binary.run([], replay)  # `--replay:D 'mi ciska lo xatra'`, label `LABEL_FOUND`
    check found.report == "Reply replayed from `" & path &
        "`: evil \\u{1B}[31mred\\u{1B}[0m \\u{202E}abc.\n" &
        suggestion.toReport(passage, settings.model)  # case as found in suite review
    for label in @LABELS_UNPRINTABLE & @["\xC3\xA9".repeat(RUNES_SHOWN)]:  # label at cap kept whole
      writeFile(path, Recording(label: label, request: request, reply: reply).toText)
      let outcome = binary.run([], replay)
      check outcome == toOutcome(suggestion, passage, settings.model,
          [noteReplayed(path, label)])  # label as `toPrintable` makes it, then tag
      check outcome.report.allIt(it notin CHARACTERS_CONTROL)  # no control reaches terminal


  test "record sends request service expects, writes reply, then replays it with no request":
    let text = example("lojban")
    for service in Service:
      let
        server = startServer()
        settings = service.toSettings(server.port)
        environment = settings.toEnvironment
        directory_case = directory / "record" / $service
        passage = text.argument.toPassage
        body = settings.toBody(passage)
        path = pathRecording(directory_case, requestService(settings, passage))
        reply = toReplyAnswer(service, text.answer, settings.model)
        suggestion = service.readReply(reply)
      server.routes = @[(PATH_SERVICE, reply)]
      let written = binary.run(environment, ["--record:" & directory_case, text.argument])
      check written == toOutcome(suggestion, passage, settings.model,
          [noteCredential(KEY_CREDENTIAL), noteWritten(path)])  # tag, and file written named
      check server.heard.len == 1  # one request sent
      if server.heard.len == 1:
        let heard = server.heard[0]
        check heard.lines[0] == "POST " & PATH_SERVICE & " HTTP/1.1"  # to endpoint named
        check heard.body == body  # body bytes of `toBody`
        check settings.toHeaders.allIt(heard.values(it[0]) == @[it[1]])  # each header, once
        check heard.lines.countIt(it.toLowerAscii.startsWith("anthropic-")) ==
            settings.toHeaders.countIt(it[0].startsWith("anthropic-"))  # Anthropic's own alone
        check service != Service.Claude or (heard.values("anthropic-version").len == 1 and
            heard.values("anthropic-beta").len == 1)  # version, and beta of fallback model
        check heard.values("authorization") == @["Bearer " & CREDENTIAL_SUITE]  # once, as Bearer
        check heard.values("accept-encoding") == @["identity"]  # no coding reader cannot read
        check heard.values("user-agent") == @[USER_AGENT]  # agent of tool
      let recorded = readFile(path).readRecording
      check recorded.is_read  # file binary wrote reads back
      if not recorded.is_read: continue
      let label = recorded.recording.label
      check recorded.recording.request ==
          requestService(settings, passage)  # endpoint and body, no credential
      check recorded.recording.reply == reply  # reply as served
      check label.startsWith("recorded ") and label["recorded ".len .. ^1].isDate  # date of run
      check walkDir(directory_case).toSeq.len == 1  # recording alone, sibling renamed over it
      let again = binary.run(environment, ["--record:" & directory_case, text.argument])
      check again == toOutcome(suggestion, passage, settings.model,
          [noteCredential(KEY_CREDENTIAL), noteReplayed(path, label)])  # recording replayed
      check server.heard.len == 1  # 2xx kept, so never paid twice
      let replayed = binary.run(environment, ["--replay:" & directory_case, text.argument])
      check replayed == toOutcome(suggestion, passage, settings.model,
          [noteReplayed(path, label)])  # same tag, credential unread
      check server.heard.len == 1  # replay sends nothing
      for outcome in [written, again, replayed]:
        check CREDENTIAL_SUITE notin outcome.output & outcome.report  # credential in no stream
      for file in walkDirRec(directory_case):
        check CREDENTIAL_SUITE notin readFile(file)  # nor in any file
      stopServer(server)


  test "workspace of `LOJBAN_TAGGER_WORKSPACE` goes in header of `claude`, and none where empty":
    # Review finding wire-2, 2026-10-29: key scoped to no workspace got 400 on every request, and
    #   no variable named workspace, so `anthropic-workspace-id` never went.
    let
      server = startServer()
      text = example("lojban")
    for workspace in ["wrkspc_01jdemo0workspace0suite", WORKSPACE_LONG[0 ..< ^1], ""]:
      var settings = Service.Claude.toSettings(server.port)
      settings.workspace = workspace
      server.routes = @[(PATH_SERVICE, toReplyMessages(text.answer, settings.model))]
      let
        count_before = server.heard.len
        outcome = binary.run(settings.toEnvironment & @[(KEY_WORKSPACE, workspace)],
            [text.argument])
      check outcome.code == 0  # tag printed
      check server.heard.len == count_before + 1  # one request sent
      if server.heard.len != count_before + 1: continue
      let heard = server.heard[^1]
      check heard.values("anthropic-workspace-id") ==
          (if workspace.len > 0: @[workspace] else: @[])  # once where set, at cap too; else none
      check settings.toHeaders.allIt(heard.values(it[0]) == @[it[1]])  # headers of `toHeaders`
      check heard.body == settings.toBody(text.argument.toPassage)  # body holds no workspace
    stopServer(server)


  test "credential comes from `LOJBAN_TAGGER_API_KEY` first, then usual name of service":
    let
      text = example("lojban")
      passage = text.argument.toPassage
    for (service, environment, value) in [
      (Service.Claude, @[(KEY_CREDENTIAL, "first"), ("ANTHROPIC_API_KEY", "second")], "first"),
      (Service.Claude, @[(KEY_CREDENTIAL, " first\t")], "first"),  # trimmed
      (Service.OpenRouter, @[(KEY_CREDENTIAL, "first"), ("OPENROUTER_API_KEY", "second")],
          "first"),
      (Service.Chat, @[(KEY_CREDENTIAL, "first"), ("ANTHROPIC_API_KEY", "other")], "first"),
    ]:
      let
        server = startServer()
        settings = service.toSettings(server.port)
        reply = toReplyAnswer(service, text.answer, settings.model)
      server.routes = @[(PATH_SERVICE, reply)]
      let
        named = settings.toEnvironment.filterIt(it[0] notin NAMES_CREDENTIAL) & environment
        outcome = binary.run(named, [text.argument])
      check outcome == toOutcome(service.readReply(reply), passage, settings.model,
          [noteCredential(KEY_CREDENTIAL)])  # variable named, never value
      check server.heard.mapIt(it.values("authorization")) ==
          @[@["Bearer " & value]]  # value of first variable set, trimmed, as Bearer
      stopServer(server)
    for (service, environment, name) in [
      (Service.Claude, @[("ANTHROPIC_API_KEY", "second")], "ANTHROPIC_API_KEY"),
      (Service.Claude, @[(KEY_CREDENTIAL, " \t"), ("ANTHROPIC_API_KEY", "second")],
          "ANTHROPIC_API_KEY"),  # blank value reads as unset
      (Service.OpenRouter, @[("OPENROUTER_API_KEY", "second"), ("ANTHROPIC_API_KEY", "other")],
          "OPENROUTER_API_KEY"),  # usual name of service, never of other
    ]:
      let
        settings = service.toSettings  # default endpoint, whose host usual name serves
        request = requestService(settings, passage)
        reply = toReplyAnswer(service, text.answer, settings.model)
        directory_case = directory / "usual" / $service / name
      writeRecordings(directory_case, [Recording(label: LABEL_SUITE, request: request,
          reply: reply)])
      check binary.run(@[(KEY_SERVICE, $service)] & environment, ["--record:" & directory_case,
          text.argument]) == toOutcome(service.readReply(reply), passage, settings.model, [
        noteCredential(name),
        noteReplayed(pathRecording(directory_case, request), LABEL_SUITE),
      ])  # usual name read for default endpoint; recording replays, so nothing is sent


  test "usual name of credential is read for host of default endpoint of service alone":
    # Review finding security-6, 2026-10-29: key in `ANTHROPIC_API_KEY` went as Bearer to
    #   endpoint of any host, where `LOJBAN_TAGGER_API_KEY` was unset.
    let
      server = startServer()
      text = example("lojban")
      passage = text.argument.toPassage
      found = Service.Claude.toSettings(server.port)
      refused = "Credential should be set in `LOJBAN_TAGGER_API_KEY` alone, since host of " &
          "endpoint is not `api.anthropic.com`; got ``.\n"
    check binary.run(found.toEnvironment.filterIt(it[0] != KEY_CREDENTIAL) &
        @[("ANTHROPIC_API_KEY", CREDENTIAL_SUITE)], [text.argument]) == Outcome(report: refused,
        code: 2)  # case as found: endpoint on loopback names `LOJBAN_TAGGER_API_KEY` alone
    var count_usual, count_refused = 0
    for service in [Service.Claude, Service.OpenRouter]:
      let
        usual = LUT_KEY_CREDENTIAL_BY_SERVICE[service]
        host = LUT_ENDPOINT_BY_SERVICE[service].parseUri.hostname
      for endpoint in [
        LUT_ENDPOINT_BY_SERVICE[service],
        LUT_ENDPOINT_BY_SERVICE[service].replace(host, host.toUpperAscii),  # host without case
        "https://" & host & ":443/v1/messages",
        "https://" & host & ".example.org/v1/messages",  # host longer, of other domain
        "https://" & host & "@example.org/v1/messages",  # user part naming host, of other host
        "https://example.org/v1/messages",
        urlLoopback(server.port, PATH_SERVICE),
      ]:
        var settings = service.toSettings
        settings.endpoint = endpoint
        let
          request = requestService(settings, passage)
          reply = toReplyAnswer(service, text.answer, settings.model)
          directory_case = directory / "hosts" / $service / endpoint.stamp
          is_usual = endpoint.parseUri.hostname.toLowerAscii == host
        writeRecordings(directory_case, [Recording(label: LABEL_SUITE, request: request,
            reply: reply)])
        let outcome = binary.run(
          [(KEY_SERVICE, $service), (KEY_ENDPOINT, endpoint), (usual, CREDENTIAL_SUITE)],
          ["--record:" & directory_case, text.argument],
        )
        if is_usual:
          inc count_usual
          check outcome == toOutcome(service.readReply(reply), passage, settings.model,
              [noteCredential(usual), noteReplayed(pathRecording(directory_case, request),
              LABEL_SUITE)])  # usual name read for host of default endpoint, without case
          continue
        inc count_refused
        check outcome == Outcome(report: "Credential should be set in `LOJBAN_TAGGER_API_KEY` " &
            "alone, since host of endpoint is not `" & host & "`; got ``.\n",
            code: 2)  # other host reads first name alone, and says why
    check count_usual == 6 and count_refused == 8  # both sides of law, for both services
    check server.heard.len == 0  # usual key never sent, nor any request
    stopServer(server)


  test "record writes reply of any status, replays tag or paid failure alone, and replay any":
    # Review findings wire-1 and logic-4, 2026-10-29: record replayed service reply by status
    #   alone, so error inside 2xx, which service bills not, was replayed on every later run.
    let text = example("lojban")
    var
      covered: set[Failure]
      count_kept, count_sent = 0
    for service in Service:
      let
        server = startServer()
        settings = service.toSettings(server.port)
        passage = text.argument.toPassage
      for i, reply in service.toReplies(settings.model):
        server.routes = @[(PATH_SERVICE, reply)]
        let
          directory_case = directory / "statuses" / $service / $i
          record = @["--record:" & directory_case, text.argument]
          path = pathRecording(directory_case, requestService(settings, passage))
          suggestion = service.readReply(reply)
          is_kept = suggestion.is_suggested or suggestion.failure != Failure.Status
          count_before = server.heard.len
          first = binary.run(settings.toEnvironment, record)
          recorded = readFile(path).readRecording
        check first == toOutcome(suggestion, passage, settings.model,
            [noteCredential(KEY_CREDENTIAL), noteWritten(path)])  # sent and written, any status
        check recorded.is_read and recorded.recording.reply == reply  # reply as served
        if not recorded.is_read: continue
        let second = binary.run(settings.toEnvironment, record)
        check second == toOutcome(suggestion, passage, settings.model, [
          noteCredential(KEY_CREDENTIAL),
          if is_kept: noteReplayed(path, recorded.recording.label) else: noteWritten(path),
        ])  # tag and paid failure replayed; `Status` sent and written again (`Mode.Record`)
        check server.heard.len - count_before ==
            (if is_kept: 1 else: 2)  # sent again where reply reads as `Status` alone
        let
          label = readFile(path).readRecording.recording.label
          replay = ["--replay:" & directory_case, text.argument]
          replayed = binary.run(settings.toEnvironment, replay)
        check replayed == toOutcome(suggestion, passage, settings.model,
            [noteReplayed(path, label)])  # any reply replayed, credential unread
        check server.heard.len - count_before == (if is_kept: 1 else: 2)  # replay sends nothing
        if not suggestion.is_suggested: covered.incl suggestion.failure
        if is_kept: inc count_kept else: inc count_sent
      stopServer(server)
    check covered == {Failure.Status..Failure.high}  # each failure `readReply` gives, exhaustive
    check count_kept > 0 and count_sent > 0  # both sides of law reached


  test "record sends again OpenRouter reply of 200 holding error, and never replays it":
    let
      refusing = socketRefusing()  # held until test ends, so no other socket takes its port
      settings = Service.OpenRouter.toSettings(int(refusing.getLocalAddr[1]))
      directory_case = directory / "inside"
      text = "mi ciska lo xatra"
      request = requestService(settings, text.toPassage)
      reply = Reply(status: 200, content_type: "application/json", body: BODY_ERROR_INSIDE)
    writeRecordings(directory_case, [Recording(label: LABEL_SUITE, request: request, reply: reply)])
    let outcome = binary.run(settings.toEnvironment, ["--record:" & directory_case, text])
    check outcome.code == 1 and outcome.output == ""  # no tag
    check outcome.report.startsWith(noteCredential(KEY_CREDENTIAL) &
        "\nService or page should answer; got `")  # review finding wire-1, 2026-10-29: `Network`
    check "replayed" notin outcome.report  # request went out again, to port that refuses
    check readFile(pathRecording(directory_case, request)).readRecording.recording.reply ==
        reply  # recording kept, since no reply came to write over it
    refusing.close()


  test "record replays page hop of 2xx or 3xx, and sends other hop again, as before":
    let
      server = startServer()
      settings = Service.Claude.toSettings(server.port)
      url = urlLoopback(server.port, "/start")
      page = Reply(status: 200, content_type: "text/plain", body: example("alice").argument)
    server.routes = @[
      ("/start", page),
      ("/fresh", page),
      (PATH_SERVICE, toReplyMessages(example("alice").answer, settings.model)),
    ]
    for i, recorded in [
      Reply(status: 200, content_type: "text/plain", body: "recorded page"),
      Reply(status: 302, location: "/fresh"),
      Reply(status: 304),
      Reply(status: 404, content_type: "text/html", body: "<p>gone</p>"),
      Reply(status: 500),
    ]:
      let
        directory_case = directory / "hops_kept" / $i
        path = pathRecording(directory_case, "GET " & url)
        is_kept = recorded.status in 200..399
        note = if is_kept: noteReplayed(path, LABEL_PAGE) else: noteWritten(path)
        count_before = server.heard.len
      writeRecordings(directory_case, [Recording(label: LABEL_PAGE, request: "GET " & url,
          reply: recorded)])
      let
        outcome = binary.run(settings.toEnvironment, ["--record:" & directory_case, url])
        lines = outcome.report.splitLines
        is_sent = "/start" in server.heard[count_before .. ^1].mapIt(it.target)
      check lines.len > 1 and lines[1] == note  # hop of 2xx or 3xx replayed, other one written
      check is_sent != is_kept  # page sent again exactly where its status is no 2xx or 3xx
    stopServer(server)


  test "refused connection exits 1 with `Network`, and record writes nothing":
    let
      refusing = socketRefusing()  # held until test ends, so no other socket takes its port
      port = int(refusing.getLocalAddr[1])
      directory_case = directory / "refused"
      opening = noteCredential(KEY_CREDENTIAL) & "\nService or page should answer; got `"
    for argument in [example("lojban").argument, urlLoopback(port, "/page")]:
      for flags in [@[], @["--record:" & directory_case]]:
        let outcome = binary.run(
          [(KEY_ENDPOINT, urlLoopback(port, PATH_SERVICE)), (KEY_CREDENTIAL, CREDENTIAL_SUITE)],
          flags & @[argument],
        )
        check outcome.code == 1 and outcome.output == ""  # no tag
        check outcome.report.startsWith(opening) and outcome.report.endsWith("`.\n")  # named
        if not outcome.report.startsWith(opening) or outcome.report.len < opening.len + 3:
          continue
        let detail = outcome.report[opening.len ..< ^3]
        check detail.len > 0 and '\n' notin detail  # first line of error alone
        check CREDENTIAL_SUITE notin detail  # credential never in error
    check dirExists(directory_case)  # record makes directory before it sends
    check walkDir(directory_case).toSeq.len == 0  # failed transport writes nothing
    refusing.close()


  test "record refuses directory it cannot make before it sends, naming recording":
    # Regression, found in suite review: record made directory only after reply, then raised.
    let
      server = startServer()
      settings = Service.Claude.toSettings(server.port)
      environment = settings.toEnvironment
      text = example("lojban")
      url = urlLoopback(server.port, "/page")
      file = directory / "unmade" / "file"
      opening = noteCredential(KEY_CREDENTIAL) &
          "\nRecording should hold this request; got `unwritable: "
      shown_found = pathShown(file, requestService(settings, "mi ciska".toPassage))
    server.routes = @[
      (PATH_SERVICE, toReplyMessages(text.answer, settings.model)),
      ("/page", Reply(status: 200, content_type: "text/plain", body: example("alice").argument)),
    ]
    createDir(file.parentDir)
    writeFile(file, "")  # `touch F`
    let
      found = binary.run(environment, ["--record:" & file, "mi ciska"])  # `--record:F 'mi ciska'`
      error_found = found.report.readFramed(opening, " at " & shown_found & "`.\n")
    check found.code == 1 and found.output == "" and error_found.isSome  # as found in review
    check server.heard.len == 0  # nothing sent, so nothing paid for
    for directory_record in [file, file / "below"]:  # file, then directory below file
      for (argument, request) in [
        (text.argument, requestService(settings, text.argument.toPassage)),
        (url, "GET " & url),  # page, refused before its first hop
      ]:
        let
          outcome = binary.run(environment, ["--record:" & directory_record, argument])
          error = outcome.report.readFramed(opening, " at " &
              pathShown(directory_record, request) & "`.\n")
        check outcome.code == 1 and outcome.output == ""  # no tag
        check error.isSome and error.get.len > 0 and '\n' notin error.get  # error, then path
    check server.heard.len == 0  # nothing sent for any directory, text or page
    check readFile(file) == ""  # file in way left as it was
    stopServer(server)


  test "record keeps reply whose recording it cannot write, naming path and error in note":
    # Regression, found in suite review: record raised where it could not write recording, after
    #   service answered, so tag paid for was lost.
    let
      server = startServer()
      settings = Service.Claude.toSettings(server.port)
      environment = settings.toEnvironment
      text = example("lojban")
      passage = text.argument.toPassage
      answer = toReplyMessages(text.answer, settings.model)
      directory_case = directory / "unwritten"
      path = pathRecording(directory_case, requestService(settings, passage))
      opening = noteCredential(KEY_CREDENTIAL) & "\nReply should be written to `"
    for (blocked, reply) in [
      (path, answer),  # directory at `<stamp>.recording`, so rename fails: as found in suite review
      (path, toReplyError(Service.Claude, 529)),  # reply giving no tag
      (path & ".writing", answer),  # directory at sibling, so write fails before rename
      (path & ".writing", toReplyError(Service.Claude, 529)),
    ]:
      server.routes = @[(PATH_SERVICE, reply)]
      removeDir(directory_case)
      createDir(blocked)
      let
        count_before = server.heard.len
        expected = toOutcome(Service.Claude.readReply(reply), passage, settings.model, [])
        outcome = binary.run(environment, ["--record:" & directory_case, text.argument])
        error = outcome.report.readFramed(opening & path & "`; got `", "`.\n" & expected.report)
      check outcome.output == expected.output and outcome.code == expected.code  # tag kept
      check error.isSome and error.get.len > 0 and '\n' notin error.get  # path, then error
      check server.heard.len == count_before + 1  # sent once, and read
      check walkDir(directory_case).toSeq.mapIt(it.path) == @[blocked]  # nothing left beside
    let
      url = urlLoopback(server.port, "/page")
      page = Reply(status: 200, content_type: "text/plain", body: example("alice").argument)
      passage_page = url.readPage(page).passage
      path_page = pathRecording(directory_case, "GET " & url)
      path_service = pathRecording(directory_case, requestService(settings, passage_page))
      expected_page = toOutcome(Service.Claude.readReply(answer), passage_page, settings.model,
          [noteWritten(path_service)])
    server.routes = @[("/page", page), (PATH_SERVICE, answer)]
    removeDir(directory_case)
    createDir(path_page)
    let
      outcome_page = binary.run(environment, ["--record:" & directory_case, url])
      error_page = outcome_page.report.readFramed(opening & path_page & "`; got `", "`.\n" &
          expected_page.report)
    check outcome_page.output == expected_page.output and outcome_page.code == 0  # tag kept
    check error_page.isSome and error_page.get.len > 0 and
        '\n' notin error_page.get  # page hop named, service request written after it
    stopServer(server)


  test "record makes each directory it makes with mode 0700, and each recording with 0600":
    # Review finding security-5, 2026-10-29: under umask `0022`, directory and recording, which
    #   hold passage, page and reply, were readable by every user.
    let
      server = startServer()
      settings = Service.Claude.toSettings(server.port)
      text = example("lojban")
      standing = directory / "private"  # made by suite with mode 0755, so record keeps it
      directory_case = standing / "made" / "below"
      path = pathRecording(directory_case, requestService(settings, text.argument.toPassage))
      mode_standing = {fpUserRead, fpUserWrite, fpUserExec, fpGroupRead, fpGroupExec,
          fpOthersRead, fpOthersExec}
    server.routes = @[(PATH_SERVICE, toReplyMessages(text.answer, settings.model))]
    createDir(standing)
    setFilePermissions(standing, mode_standing)
    check binary.run(settings.toEnvironment, ["--record:" & directory_case,
        text.argument]).code == 0  # tag printed, recording written
    check getFilePermissions(standing) == mode_standing  # directory standing keeps its mode
    for made in [standing / "made", directory_case]:
      check getFilePermissions(made) == {fpUserRead, fpUserWrite, fpUserExec}  # 0700 where made
    check getFilePermissions(path) == {fpUserRead, fpUserWrite}  # recording 0600
    check walkDir(directory_case).toSeq.mapIt(it.path) == @[path]  # recording alone, renamed
    stopServer(server)


  test "directory every user may write is refused, naming it, before any send or read":
    # Review finding security-4, 2026-10-29: other user may plant link in such directory, so
    #   replay printed file it named, and record wrote over it.
    let
      server = startServer()
      settings = Service.Claude.toSettings(server.port)
      text = example("lojban")
      passage = text.argument.toPassage
      request = requestService(settings, passage)
      reply = toReplyMessages(text.answer, settings.model)
      url = urlLoopback(server.port, "/page")
      shared = directory / "shared"
      refused = toSuggestionRecording("writable by every user at " &
          shared.toPrintable(RUNES_SHOWN))
    server.routes = @[
      (PATH_SERVICE, reply),
      ("/page", Reply(status: 200, content_type: "text/plain", body: example("alice").argument)),
    ]
    writeRecordings(shared, [Recording(label: LABEL_SUITE, request: request, reply: reply)])
    check chmod(cstring(shared), Mode(0o1777)) == 0  # mode of `/tmp`
    for (flags, notes) in [
      (@["--record:" & shared], @[noteCredential(KEY_CREDENTIAL)]),
      (@["--replay:" & shared], @[]),
    ]:
      check binary.run(settings.toEnvironment, flags & @[text.argument]) == toOutcome(refused,
          passage, settings.model, notes)  # refused, though recording of request stands there
      check binary.run(settings.toEnvironment, flags & @[url]) ==
          toOutcome(refused, notes)  # page refused before its first hop
    check server.heard.len == 0  # nothing sent
    check walkDir(shared).toSeq.len == 1  # nothing written beside recording standing
    stopServer(server)


  test "recording past its caps is refused: file before it is read, and body past its cap":
    # Review finding security-4, 2026-10-29: replay read recording of any size, and replayed
    #   body past cap of reply.
    let
      text = example("lojban")
      settings = Service.Claude.toSettings
      passage = text.argument.toPassage
      request = requestService(settings, passage)
      directory_case = directory / "caps"
      path = pathRecording(directory_case, request)
      shown = pathShown(directory_case, request)
      bytes_file_max = request.len + BYTES_REPLY_MAX + BYTES_FIELDS_MAX
      whole = Recording(label: LABEL_SUITE, request: request,
          reply: toReplyMessages(text.answer, settings.model)).toText
      replay = ["--replay:" & directory_case, text.argument]
    createDir(directory_case)
    for size in [bytes_file_max + 1, bytes_file_max + BYTES_REPLY_MAX]:
      writeFile(path, whole & "x".repeat(size - whole.len))  # read whole, it would be malformed
      check binary.run([], replay) == toOutcome(toSuggestionRecording("larger than " &
          $bytes_file_max & " bytes at " & shown), passage, settings.model,
          [])  # refused by size alone
    for count in [BYTES_REPLY_MAX + 1, BYTES_REPLY_MAX + 1_000]:
      let body = Reply(status: 200, content_type: "application/json", body: "x".repeat(count))
      writeFile(path, Recording(label: LABEL_SUITE, request: request, reply: body).toText)
      check getFileSize(path) <= bytes_file_max  # file within its cap, so body is read
      check binary.run([], replay) == toOutcome(toSuggestionRecording("body over " &
          $BYTES_REPLY_MAX & " bytes at " & shown), passage, settings.model,
          [])  # body past cap of reply never replayed
    let at_cap = whole & "x".repeat(bytes_file_max - whole.len)
    writeFile(path, at_cap)
    check binary.run([], replay) == toOutcome(toSuggestionRecording(detailMalformed(
        at_cap.readRecording, directory_case, request)), passage, settings.model,
        [])  # file at its cap is read, and reader refuses what follows body


  test "recording that stands but cannot be read exits 1 with `Recording`, never traceback":
    # Link at path of recording to `/proc/self/mem`: `fileExists` and size take it, and read at
    #   offset 0 fails with `EIO` even for root, whom no permission refuses, as suite may run.
    let
      server = startServer()
      settings = Service.Claude.toSettings(server.port)
      text = example("lojban")
      directory_case = directory / "unreadable"
      request = requestService(settings, text.argument.toPassage)
      path = pathRecording(directory_case, request)
      opening = "Recording should hold this request; got `unreadable: "
    server.routes = @[(PATH_SERVICE, toReplyMessages(text.answer, settings.model))]
    createDir(directory_case)
    createSymlink("/proc/self/mem", path)
    for (flags, notes) in [
      (@["--replay:" & directory_case], ""),
      (@["--record:" & directory_case], noteCredential(KEY_CREDENTIAL) & "\n"),
    ]:
      let
        outcome = binary.run(settings.toEnvironment, flags & @[text.argument])
        error = outcome.report.readFramed(notes & opening, " at " &
            pathShown(directory_case, request) & "`.\n")
      check outcome.code == 1 and outcome.output == ""  # no tag
      check error.isSome and error.get.len > 0 and
          '\n' notin error.get  # review finding logic-5, 2026-10-29: first line of error alone
    check server.heard.len == 0  # recording standing is refused, never sent around
    stopServer(server)


  test "page over loopback follows redirect, reads markup, and cuts page past its cap":
    let
      page = example("page")
      reply_page = page.hops[^1][1]  # markup of windows-1252: script, style, comment, references
      large = PIECE_PAGE.repeat(BYTES_PAGE_MAX div PIECE_PAGE.len + 1)[0..BYTES_PAGE_MAX]
      reply_exact = Reply(status: 200, content_type: "text/plain", body: large[0 ..< ^1])
      reply_large = Reply(status: 200, content_type: "text/plain", body: large)
      server = startServer(
        @[
          ("/moved", Reply(status: 302, location: "/page")),
          ("/page", reply_page),
          ("/exact", reply_exact),
          ("/large", reply_large),
        ],
      )
      settings = Service.Claude.toSettings(server.port)
      reply_service = toReplyMessages(page.answer, settings.model)
      suggestion = Service.Claude.readReply(reply_service)
    server.routes.add (PATH_SERVICE, reply_service)
    for (start, final, reply_read) in [
      ("/moved", "/page", reply_page),
      ("/exact", "/exact", reply_exact),  # page of `BYTES_PAGE_MAX` bytes kept whole
      ("/large", "/large", Reply(
        status: 200,
        content_type: "text/plain",
        body: reply_exact.body,
        is_cut: true,
      )),  # one byte more cut, and rest unread
    ]:
      let paged = urlLoopback(server.port, final).readPage(reply_read)
      check paged.is_read  # page gives passage
      if not paged.is_read: continue
      let
        count_before = server.heard.len
        outcome = binary.run(settings.toEnvironment, [urlLoopback(server.port, start)])
        heard = server.heard[count_before .. ^1]
      check outcome == toOutcome(suggestion, paged.passage, settings.model,
          [noteCredential(KEY_CREDENTIAL)])  # tag of passage page gives, cut lines first
      check heard.mapIt(it.target) == (if start == final: @[final] else: @[start, final]) &
          @[PATH_SERVICE]  # each hop once, then service
      check heard.len > 0 and heard[^1].body == settings.toBody(paged.passage)  # text of page
      check heard[0 ..< ^1].allIt(it.values("authorization").len == 0)  # page gets no credential
    let
      directory_case = directory / "page"
      url_moved = urlLoopback(server.port, "/moved")
      url_page = urlLoopback(server.port, "/page")
      passage = url_page.readPage(reply_page).passage
      requests = @["GET " & url_moved, "GET " & url_page, requestService(settings, passage)]
      paths = requests.mapIt(pathRecording(directory_case, it))
    check binary.run(settings.toEnvironment, ["--record:" & directory_case, url_moved]) ==
        toOutcome(suggestion, passage, settings.model,
        @[noteCredential(KEY_CREDENTIAL)] & paths.mapIt(noteWritten(it)))  # each hop written
    stopServer(server)  # replay needs no server
    let recordings = paths.mapIt(readFile(it).readRecording)
    check recordings.allIt(it.is_read)  # each file reads back
    if recordings.allIt(it.is_read):
      check recordings.mapIt(it.recording.request) == requests  # each hop, then service
      check recordings.mapIt(it.recording.reply) ==
          @[Reply(status: 302, location: "/page"), reply_page, reply_service]  # as served
      check binary.run(settings.toEnvironment, ["--replay:" & directory_case, url_moved]) ==
          toOutcome(suggestion, passage, settings.model, (0..2).mapIt(noteReplayed(paths[it],
          recordings[it].recording.label)))  # same tag, read from files alone, same endpoint


  test "page refused by status, type, coding, charset or text exits 1 with `Page`, naming it":
    let
      server = startServer()
      environment = Service.Claude.toSettings(server.port).toEnvironment
      credential = noteCredential(KEY_CREDENTIAL)
    for (path, reply) in [
      ("/gone", Reply(status: 404, content_type: "text/html", body: "<p>gone</p>")),
      ("/failed", Reply(status: 500)),
      ("/unchanged", Reply(status: 304)),  # no redirect, so status refused
      ("/pdf", Reply(status: 200, content_type: "application/pdf", body: "%PDF-1.7")),
      ("/zipped", Reply(
        status: 200,
        content_type: "text/html",
        content_encoding: "gzip",
        body: "\x1F\x8B\x08\x00",
      )),
      ("/japanese", Reply(status: 200, content_type: "text/plain; charset=shift_jis", body: "x")),
      ("/script", Reply(status: 200, content_type: "text/html", body: "<script>a()</script>")),
    ]:
      server.routes = @[(path, reply), (PATH_SERVICE, toReplyError(Service.Claude, 500))]
      let
        url = urlLoopback(server.port, path)
        paged = url.readPage(reply)
        count_before = server.heard.len
      check not paged.is_read  # pure reader refuses page
      if paged.is_read: continue
      check binary.run(environment, [url]) ==
          toOutcome(Failure.Page, paged.detail, [credential])  # named by what refused it
      check server.heard[count_before .. ^1].mapIt(it.target) == @[path]  # page alone, no service
    for location in ["", "ftp://example.org/file"]:
      server.routes = @[("/moved", Reply(status: 302, location: location))]
      check binary.run(environment, [urlLoopback(server.port, "/moved")]) ==
          toOutcome(Failure.Page, "redirect to " & location, [credential])  # no http target
    stopServer(server)


  test "redirect chain reads page within `COUNT_REDIRECTS_MAX` hops, and refuses one hop more":
    let
      server = startServer()
      settings = Service.Claude.toSettings(server.port)
      reply_page = Reply(status: 200, content_type: "text/plain", body: example("alice").argument)
      reply_service = toReplyMessages(example("alice").answer, settings.model)
      credential = noteCredential(KEY_CREDENTIAL)
    for count in 0 .. COUNT_REDIRECTS_MAX + 1:
      let chain = (0..count).mapIt("/chain/" & $count & "/" & $it)
      server.routes = (0..<count).mapIt((chain[it], Reply(status: 302, location: chain[it+1]))) &
          @[(chain[^1], reply_page), (PATH_SERVICE, reply_service)]
      let
        count_before = server.heard.len
        outcome = binary.run(settings.toEnvironment, [urlLoopback(server.port, chain[0])])
        targets = server.heard[count_before .. ^1].mapIt(it.target)
      if count <= COUNT_REDIRECTS_MAX:
        let passage = urlLoopback(server.port, chain[^1]).readPage(reply_page).passage
        check outcome == toOutcome(Service.Claude.readReply(reply_service), passage,
            settings.model, [credential])  # page read after each redirect
        check targets == chain & @[PATH_SERVICE]  # each hop once, then service
      else:
        check outcome == toOutcome(Failure.Page, "more than " & $COUNT_REDIRECTS_MAX &
            " redirects", [credential])  # one redirect past cap refused
        check targets == chain[0..COUNT_REDIRECTS_MAX]  # hop past cap never requested
    stopServer(server)


  test "redirect loop exits 1 with `Page`, naming URL seen again, each URL requested once":
    let
      server = startServer()
      environment = Service.Claude.toSettings(server.port).toEnvironment
    for length in 1 .. COUNT_REDIRECTS_MAX + 1:
      for back in 0..<length:
        let loop = (0..<length).mapIt("/loop/" & $length & "/" & $back & "/" & $it)
        server.routes = (0..<length).mapIt((loop[it], Reply(
          status: 302,
          location: if it + 1 < length: loop[it+1] else: loop[back],
        )))
        let
          count_before = server.heard.len
          outcome = binary.run(environment, [urlLoopback(server.port, loop[0])])
        check outcome == toOutcome(Failure.Page, "redirect loop at " &
            urlLoopback(server.port, loop[back]), [noteCredential(KEY_CREDENTIAL)])  # URL seen
        check server.heard[count_before .. ^1].mapIt(it.target) == loop  # each URL once
    stopServer(server)


  test "refused or looping redirect names URL by scheme, host, port and path alone":
    # Recheck claim completeness-2, 2026-10-29: detail named whole URL, so token capability or
    #   presigned URL holds in query reached report, though `toPassage` keeps it from passage URL.
    let
      server = startServer()
      environment = Service.Claude.toSettings(server.port).toEnvironment
      capability = "/shared/doc?access_token=SECRET-CAPABILITY-123"
      signed = "/bucket/loop?X-Amz-Signature=SIGNED-SECRET-789"
      directory_case = directory / "trimmed"
      start = "https://localhost:8443/dl"
      presigned = "http://127.0.0.1:8080/bucket/obj?X-Amz-Signature=SIGNED-SECRET-456&" &
          "X-Amz-Credential=AKIAPROBE"
    server.routes = @[
      (capability, Reply(status: 302, location: urlLoopback(server.port, capability))),
      ("/dl-loop", Reply(status: 302, location: signed)),
      (signed, Reply(status: 302, location: signed)),
    ]
    for (path, trimmed) in [(capability, "/shared/doc"), ("/dl-loop", "/bucket/loop")]:
      check binary.run(environment, [urlLoopback(server.port, path)]) == toOutcome(Failure.Page,
          "redirect loop at " & urlLoopback(server.port, trimmed), [noteCredential(
          KEY_CREDENTIAL)])  # cases as found: token user gave, then token page gave in redirect
    stopServer(server)
    writeRecordings(directory_case, [Recording(label: LABEL_SUITE, request: "GET " & start,
        reply: Reply(status: 302, location: presigned))])
    check binary.run([], ["--replay:" & directory_case, start]) == toOutcome(Failure.Page,
        "redirect to http://127.0.0.1:8080/bucket/obj", [noteReplayed(pathRecording(directory_case,
        "GET " & start), LABEL_SUITE)])  # as found: https falls; replayed, as suite drives no TLS
    var count = 0  # Cases made, so each refused location has start of its own.
    for user in USERS_REDIRECT:
      for query in QUERIES_REDIRECT:
        for fragment in FRAGMENTS_REDIRECT:  # 27 URLs, exhaustive, replayed for any scheme and host
          for (scheme, is_loop) in SCHEMES_REDIRECT:
            let
              url = scheme & "://" & user & "example.org:8080/page" & query & fragment
              start_case = if is_loop: url else: "https://example.org/start/" & $count
              opening = if is_loop: "redirect loop at " else: "redirect to "
            inc count
            writeRecordings(directory_case, [Recording(label: LABEL_SUITE,
                request: "GET " & start_case, reply: Reply(status: 302, location: url))])
            let outcome = binary.run([], ["--replay:" & directory_case, start_case])
            check outcome == toOutcome(Failure.Page, opening & scheme & "://example.org:8080/page",
                [noteReplayed(pathRecording(directory_case, "GET " & start_case),
                LABEL_SUITE)])  # RFC 3986 appendix `B`: scheme, host, port and path alone
            check "SECRET" notin outcome.report  # no user part, query or fragment named


  test "request off loopback goes through proxy environment names, and credential never with it":
    let
      page = Reply(status: 200, content_type: "text/plain", body: example("alice").argument)
      url = "http://example.org/alice"
      proxy = startServer(@[(url, page)])
      service = startServer()
      settings = Service.Claude.toSettings(service.port)
      reply = toReplyMessages(example("alice").answer, settings.model)
      url_proxy = urlLoopback(proxy.port, "")
      proxies = @[("http_proxy", url_proxy), ("https_proxy", url_proxy)]
    service.routes = @[(PATH_SERVICE, reply)]
    check binary.run(settings.toEnvironment & proxies, [url]) ==
        toOutcome(Service.Claude.readReply(reply), url.readPage(page).passage, settings.model,
        [noteCredential(KEY_CREDENTIAL)])  # page read through proxy
    check proxy.heard.mapIt(it.target) == @[url]  # absolute form, as proxy reads it
    check service.heard.len == 1  # service on loopback goes direct
    let
      endpoint = "https://api.example.org" & PATH_SERVICE
      tunnelled = binary.run(settings.toEnvironment & proxies & @[(KEY_ENDPOINT, endpoint)],
          [example("lojban").argument])
    check tunnelled.code == 1 and tunnelled.output == ""  # proxy refused tunnel
    check tunnelled.report.startsWith(noteCredential(KEY_CREDENTIAL) &
        "\nService or page should answer; got `")  # refusal named as `Network`
    check proxy.heard.mapIt(it.target) == @[url, "api.example.org:443"]  # tunnel, never direct
    check proxy.heard.allIt(it.lines.allIt(CREDENTIAL_SUITE notin it))  # credential never seen
    check service.heard.len == 1  # nothing else reached service
    stopServer(proxy)
    stopServer(service)


  test "settings refused exit 2 naming variable, and send or write nothing":
    let
      server = startServer()
      endpoint = urlLoopback(server.port, PATH_SERVICE)
      directory_case = directory / "settings"
      every = @[@[], @["--record:" & directory_case], @["--replay:" & directory_case]]
      sending = every[0..1]
      chat = @[(KEY_SERVICE, "chat"), (KEY_ENDPOINT, endpoint), (KEY_MODEL, MODEL_SUITE)]
    for (modes, environment, problem) in [
      (every, @[(KEY_SERVICE, "bogus")], "Service should be `claude`, `openrouter` or `chat`; " &
          "got `bogus` for `LOJBAN_TAGGER_SERVICE`."),
      (every, @[(KEY_SERVICE, "Claude")], "Service should be `claude`, `openrouter` or " &
          "`chat`; got `Claude` for `LOJBAN_TAGGER_SERVICE`."),  # spelled as enum, no fold
      (every, @[(KEY_EFFORT, "extreme")], "Effort should be `low`, `medium`, `high`, `xhigh` " &
          "or `max`; got `extreme` for `LOJBAN_TAGGER_EFFORT`."),
      (every, @[(KEY_ENDPOINT, "http://api.example.org/v1")], "Endpoint should be https, or " &
          "http to loopback host; got `http://api.example.org/v1` for `LOJBAN_TAGGER_ENDPOINT`."),
      (every, @[(KEY_ENDPOINT, "api.example.org/v1")], "Endpoint should be https, or http to " &
          "loopback host; got `api.example.org/v1` for `LOJBAN_TAGGER_ENDPOINT`."),  # no URL
      (every, @[(KEY_SERVICE, "chat")], "Endpoint should be named for service `chat`; got `` " &
          "for `LOJBAN_TAGGER_ENDPOINT`."),
      (every, chat[0..1], "Model should be named for service `chat`; got `` for " &
          "`LOJBAN_TAGGER_MODEL`."),
      (every, @[(KEY_WORKSPACE, "wrkspc_a\rb")], PROBLEM_WORKSPACE & "`wrkspc_a\\u{D}b` for " &
          "`LOJBAN_TAGGER_WORKSPACE`."),  # carriage return would split header
      (every, @[(KEY_WORKSPACE, "wrkspc_a\nb")], PROBLEM_WORKSPACE & "`wrkspc_a\\u{A}b` for " &
          "`LOJBAN_TAGGER_WORKSPACE`."),
      (every, @[(KEY_WORKSPACE, "wrkspc_a b")], PROBLEM_WORKSPACE & "`wrkspc_a b` for " &
          "`LOJBAN_TAGGER_WORKSPACE`."),
      (every, @[(KEY_WORKSPACE, "workspace_a")], PROBLEM_WORKSPACE & "`workspace_a` for " &
          "`LOJBAN_TAGGER_WORKSPACE`."),  # opening other than ID of workspace
      (every, @[(KEY_WORKSPACE, WORKSPACE_LONG)], PROBLEM_WORKSPACE & "`" & WORKSPACE_LONG &
          "` for `LOJBAN_TAGGER_WORKSPACE`."),  # one byte past cap
      (every, @[(KEY_SERVICE, "openrouter"), (KEY_WORKSPACE, "wrkspc_a")], "Workspace should " &
          "be named for service `claude` alone; got `wrkspc_a` for `LOJBAN_TAGGER_WORKSPACE`."),
      (every, chat & @[(KEY_WORKSPACE, " ")], "Workspace should be named for service `claude` " &
          "alone; got ` ` for `LOJBAN_TAGGER_WORKSPACE`."),  # any value set, blank included
      (sending, @[(KEY_ENDPOINT, endpoint), (KEY_CREDENTIAL, "sk-ant-sec\rret")],
          "Credential should hold visible ASCII alone; got byte `13` at `10` for " &
          "`LOJBAN_TAGGER_API_KEY`."),  # carriage return would split header
      (sending, @[(KEY_ENDPOINT, endpoint), (KEY_CREDENTIAL, "sk-or-secret")],
          "Credential should be issued by service `claude`; got opening `sk-or-` for " &
          "`LOJBAN_TAGGER_API_KEY`."),
      (sending, @[("ANTHROPIC_API_KEY", "sk-or-secret")], "Credential should be issued by " &
          "service `claude`; got opening `sk-or-` for `ANTHROPIC_API_KEY`."),  # default endpoint
      (sending, @[(KEY_SERVICE, "openrouter"), ("OPENROUTER_API_KEY", "sk-ant-secret")],
          "Credential should be issued by service `openrouter`; got opening `sk-ant-` for " &
          "`OPENROUTER_API_KEY`."),
      (sending, @[], "Credential should be set in `LOJBAN_TAGGER_API_KEY` or " &
          "`ANTHROPIC_API_KEY`; got ``."),
      (sending, @[(KEY_SERVICE, "openrouter"), ("ANTHROPIC_API_KEY", "sk-ant-secret")],
          "Credential should be set in `LOJBAN_TAGGER_API_KEY` or `OPENROUTER_API_KEY`; got " &
          "``."),  # usual name of other service unread
      (sending, @[(KEY_ENDPOINT, endpoint)], "Credential should be set in " &
          "`LOJBAN_TAGGER_API_KEY` alone, since host of endpoint is not `api.anthropic.com`; " &
          "got ``."),  # endpoint off host of service reads first name alone
      (sending, @[(KEY_SERVICE, "openrouter"), (KEY_ENDPOINT, endpoint), ("OPENROUTER_API_KEY",
          "sk-or-secret")], "Credential should be set in `LOJBAN_TAGGER_API_KEY` alone, since " &
          "host of endpoint is not `openrouter.ai`; got ``."),
      (sending, chat & @[("ANTHROPIC_API_KEY", "sk-ant-secret"), ("OPENROUTER_API_KEY",
          "sk-or-secret")], "Credential should be set in `LOJBAN_TAGGER_API_KEY`; got ``."),
    ]:
      for flags in modes:
        let outcome = binary.run(environment, flags & @[example("lojban").argument])
        check outcome == Outcome(report: problem & "\n", code: 2)  # problem alone, nothing printed
        check environment.allIt(it[0] notin NAMES_CREDENTIAL or
            it[1] notin outcome.report)  # value of credential never named
    check server.heard.len == 0  # nothing sent
    check not dirExists(directory_case)  # nothing written
    stopServer(server)


  test "usage error exits 2, prints usage, and sends or writes nothing":
    let
      server = startServer()
      directory_case = directory / "usage"
      environment = Service.Claude.toSettings(server.port).toEnvironment
    for arguments in [
      newSeq[string](),
      @["--record:"],
      @["--replay:"],
      @["--record:", TEXT_GIVEN],  # flag of empty directory, though text reads as tag
      @["--replay:", "mi ciska"],
      @["--record:" & directory_case],  # no passage
      @["--replay:" & directory_case],
      @["mi ciska", "--record:" & directory_case],  # flag after first argument
      @["--replay:" & directory_case, "--replay:" & directory_case, "mi ciska"],
      @["--record:" & directory_case, "mi", "--replay:" & directory_case],
      @[""],  # blank passage
      @[" ", "\t"],
      @["--record:" & directory_case, "\n"],
      @["-", "mi ciska"],  # `-` opens passage of standard input alone, so text after it is flag
      @["--record:" & directory_case, "-", "mi"],
    ]:
      check binary.run(environment, arguments) == Outcome(report: USAGE, code: 2)  # usage alone
    check server.heard.len == 0  # nothing sent
    check not dirExists(directory_case)  # nothing written
    stopServer(server)


  test "flag before passage other than mode, `--` or `-` exits 2 with usage, sending nothing":
    randomize(0)
    let
      server = startServer()
      directory_case = directory / "flags"  # never made, so nothing reads or writes it
      live = Service.Claude.toSettings(server.port).toEnvironment
      pool = poolFlags(directory_case)
    for arguments in [
      @["--help"],
      @["-h"],
      @["--replay=" & directory_case, "mi ciska lo xatra"],
      @["--replay", directory_case, "mi ciska lo xatra"],
    ]:
      for environment in [live, live & @[(KEY_SERVICE, "bogus")]]:  # credential, then bad service
        check binary.run(environment, arguments) == Outcome(report: USAGE,
            code: 2)  # review finding logic-3, 2026-10-29: each sent paid request with credential
    var passed = 0
    for arguments in served(pool):
      if arguments[^2].isFlagTaken: continue  # random flag usage takes; tests above and below
      inc passed
      check binary.run(live, arguments) == Outcome(report: USAGE, code: 2)  # any other flag
    check passed >= FLOOR_FLAGS  # guard leaves enough flags refused
    check server.heard.len == 0  # nothing sent, though credential and endpoint are set
    check not dirExists(directory_case)  # nothing written
    stopServer(server)


  test "`--` ends flags, so passage after it may open with `-`":
    let
      directory_case = directory / "dashes"  # never made, so recording of each request misses
      settings = Service.Claude.toSettings
    for (arguments, text) in [
      (@["--", "-ish"], "-ish"),
      (@["--", "--help"], "--help"),
      (@["--", "-", "mi"], "- mi"),
      (@["--", "--record:" & directory_case], "--record:" & directory_case),
      (@["--", "mi", "--replay:" & directory_case], "mi --replay:" & directory_case),
    ]:
      let
        passage = text.toPassage
        shown = pathShown(directory_case, requestService(settings, passage))
      check binary.run([], @["--replay:" & directory_case] & arguments) ==
          toOutcome(toSuggestionRecording("missing at " & shown), passage, settings.model,
          [])  # passage after `--` read as text, flag of mode among it too


  test "text holding no visible character exits 2 with usage, as exported `isBlank` reads it":
    randomize(0)
    let
      server = startServer()
      live = Service.Claude.toSettings(server.port).toEnvironment
      directory_case = directory / "blank"  # never made, so recording of each request misses
      settings = Service.Claude.toSettings
      pool = poolBlank()
    for text in ["\xEF\xBB\xBF", "\xC2\xA0"]:  # `suggester $'\xEF\xBB\xBF'`, then lone NBSP
      for environment in [live, @[(KEY_SERVICE, "bogus")]]:  # credential, then bad service
        check binary.run(environment, [text]) == Outcome(report: USAGE,
            code: 2)  # review finding logic-11, 2026-10-29: empty passage went out, paid
    check server.heard.len == 0  # nothing sent
    var count_blank, count_visible = 0
    for text in served(pool):
      let outcome = binary.run([], ["--replay:" & directory_case, text])
      if text.isBlank:
        inc count_blank
        check outcome == Outcome(report: USAGE, code: 2)  # blank text read as no text given
        continue
      inc count_visible
      let
        passage = text.toPassage
        shown = pathShown(directory_case, requestService(settings, passage))
        expected =
          if text.readTagGiven.isSome: text.toOutcomeGiven
          else: toOutcome(toSuggestionRecording("missing at " & shown), passage, settings.model, [])
      check outcome == expected  # text holding visible character asks shortcut, then service
    check count_blank >= FLOOR_BLANK  # blank texts are common
    check count_visible >= FLOOR_VISIBLE  # texts holding visible character are common
    stopServer(server)


  test "`-` reads passage from standard input up to `BYTES_PAGE_MAX` bytes, as text given goes":
    # Review finding security-5, 2026-10-29: passage went on command line, which `ps` shows.
    let
      server = startServer()
      live = Service.Claude.toSettings(server.port).toEnvironment
      settings = Service.Claude.toSettings
      directory_case = directory / "reading"
      missing = directory_case / "missing"  # never made, so recording of each request misses
      over = "Text on standard input should hold at most " & $BYTES_PAGE_MAX &
          " bytes; got more than `" & $BYTES_PAGE_MAX & "`.\n"
    for example in EXAMPLES:
      if example.hops.len > 0: continue  # page of URL, never text of input
      for service in [Service.Claude, Service.OpenRouter]:
        let directory_example = directory_case / (example.name & "_" & $service)
        writeRecordings(directory_example, example.toRecordings(service))
        let
          replay = @["--replay:" & directory_example]
          given = binary.run([(KEY_SERVICE, $service)], replay & @[example.argument])
        check given.code == 0  # recording of text given as argument replays
        for flags in [@["-"], @["--", "-"]]:
          check binary.run([(KEY_SERVICE, $service)], replay & flags, input = example.argument) ==
              given  # same stamp, so same recording and report
    check binary.run([(KEY_SERVICE, "bogus")], ["-"], input = TEXT_GIVEN) ==
        TEXT_GIVEN.toOutcomeGiven  # shortcut reads text of input too, reading no setting
    for text in ["https://example.org/alice", "a".repeat(BYTES_PAGE_MAX)]:  # URL, text at cap
      let
        passage = text.toPassage
        shown = pathShown(missing, requestService(settings, passage))
      check binary.run([], ["--replay:" & missing, "-"], input = text) == toOutcome(
          toSuggestionRecording("missing at " & shown), passage, settings.model,
          [])  # text whole, never page fetched
    check binary.run(live, ["-"], input = "a".repeat(BYTES_PAGE_MAX + 1)) ==
        Outcome(report: over, code: 2)  # one byte past cap refused, with cap named
    for text in ["", "\n", "\xEF\xBB\xBF"]:
      check binary.run(live, ["-"], input = text) == Outcome(report: USAGE,
          code: 2)  # blank input refused as blank text given
    let
      opening = "Text on standard input should be readable; got `"
      unread = binary.run(live, ["-"], path_input = directory)
      error = unread.report.readFramed(opening, "`.\n")
    check unread.code == 2 and unread.output == ""  # input refused, nothing printed
    check error.isSome and error.get.len > 0 and '\n' notin error.get  # first line of error
    check server.heard.len == 0  # nothing sent past cap, blank or unread
    check not dirExists(missing)  # nothing written
    stopServer(server)


  test "each failure exits 1, prints nothing, and reports what pure pipeline names":
    let
      text = example("lojban").argument
      settings = Service.Claude.toSettings
      passage = text.toPassage
      request = requestService(settings, passage)
    var covered: set[Failure]
    for reply in [
      toReplyError(Service.Claude, 529),
      toReplyStopped(Service.Claude, "refusal", settings.model),
      toReplyStopped(Service.Claude, "max_tokens", settings.model),
      Reply(status: 200, content_type: "application/json", body: "not json"),
      toReplyMessages(toAnswer(["datna"]), settings.model),
      toReplyMessages(toAnswer(["ciska", "se"]), settings.model),
      toReplyMessages(newSeqWith(COUNT_WORDS_MAX + 1, "ciska").toAnswer, settings.model),
      toReplyMessages(toAnswer(["brodi", "ciska"]), settings.model),
    ]:
      let suggestion = Service.Claude.readReply(reply)
      check not suggestion.is_suggested  # reply reads as failure
      if suggestion.is_suggested: continue
      let directory_case = directory / "failures" / $suggestion.failure
      writeRecordings(directory_case, [Recording(label: LABEL_SUITE, request: request,
          reply: reply)])
      check binary.run([], ["--replay:" & directory_case, text]) == toOutcome(suggestion,
          passage, settings.model, [noteReplayed(pathRecording(directory_case, request),
          LABEL_SUITE)])  # explained after note, nothing printed, exit 1
      covered.incl suggestion.failure
    let
      directory_none = directory / "failures" / "none"  # never made
      shown_none = pathShown(directory_none, request)
    check binary.run([], ["--replay:" & directory_none, text]) == toOutcome(
        toSuggestionRecording("missing at " & shown_none), passage, settings.model,
        [])  # missing
    covered.incl Failure.Recording
    let
      url = "https://example.org/gone"
      gone = Reply(status: 404, content_type: "text/html", body: "<p>gone</p>")
      directory_page = directory / "failures" / "page"
      path_page = pathRecording(directory_page, "GET " & url)
    writeRecordings(directory_page, [Recording(label: LABEL_SUITE, request: "GET " & url,
        reply: gone)])
    check binary.run([], ["--replay:" & directory_page, url]) == toOutcome(Failure.Page,
        url.readPage(gone).detail, [noteReplayed(path_page, LABEL_SUITE)])  # page refused
    covered.incl Failure.Page
    let
      refusing = socketRefusing()  # held until refused run ends, so no other socket takes port
      url_closed = urlLoopback(int(refusing.getLocalAddr[1]), PATH_SERVICE)
      refused = binary.run([(KEY_ENDPOINT, url_closed), (KEY_CREDENTIAL, CREDENTIAL_SUITE)], [text])
    refusing.close()
    check refused.code == 1 and refused.output == ""  # no tag
    check refused.report.startsWith(noteCredential(KEY_CREDENTIAL) &
        "\nService or page should answer; got `")  # connection refused, named
    covered.incl Failure.Network
    check covered == {Failure.low..Failure.high}  # every failure, exhaustive


  test "no run reaches `ANTHROPIC_BASE_URL`, which host sets for agent and binary never reads":
    check binary.sink.heard.len == 0  # sink heard nothing, over every run of suite


  test "binary ends stalled exchange at its deadline":
    skip()  # IX.9 gap: deadline reads real clock (IX.12); `test_exchanges.nim` holds `send` to it

  stopServer(binary.sink)
  removeDir(directory)
