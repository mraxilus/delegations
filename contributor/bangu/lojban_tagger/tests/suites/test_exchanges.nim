## Hold transport of `exchanges.nim` to its laws: stamp, recording file, URL tests, proxy,
##   redirect and credential by table and sample, and `send` over loopback.
##   CLL covers no transport, so suites are `Internal:`, tests named by behaviour (Article IX.10).
##   Stamp meets published vectors of FNV-1a 64, and one law of its arithmetic: each step maps
##     state one to one, so requests of one length that differ in one byte never share stamp.
##   Random recordings hold request and body of any bytes, line breaks often and last often, and
##     file text of other recording; label and header values hold any byte but line break.
##     Corpus holds no line break in label or header value, and no status outside three digits:
##     `toText` writes either, and `readRecording` refuses it; should writer refuse it instead?
##   Malformed files take one recording whose request and body span lines, each piece of its
##     file with each fault that piece admits; file is written by suite, never by `toText`, and
##     each expected line is counted from pieces before it.
##     Reader names line after faulty line it reads whole, so line is held only where reader
##     stops before reading faulty line: text ends there, or block miscounts (TODO in test).
##   Redirect resolves examples of RFC 3986 section 5.4 but five whose dot segments `combine` of
##     `std/uri` resolves otherwise: `.`, `..`, `../..`, `./g/.` and `../../../../g`; should
##     `redirect` resolve them itself?
##   URL holding whitespace or control character is refused by `redirect` and by `send`, each such
##     byte at start, middle and end; `send` meets live server, so refusal shows nothing went out.
##   Credential laws take every byte at start, middle and end of value; random secrets are spelled
##     from symbols no problem text holds, so any byte of value leaking into problem shows.
##   `send` meets servers of `std/asynchttpserver` in same process, on `127.0.0.1` at port system
##     chooses; raw listener of `std/asyncnet` reads request head byte for byte, since server
##     keeps last of repeated header lines. Futures are driven by `waitFor` and `poll`; test
##     completes deadline itself once server holds request, so no test reads clock (Article
##     IX.12).
##     Test waits on future of its own beside `send`, never on deadline: `or` of
##     `std/asyncdispatch` replaces callbacks of futures it waits on, so it would unhook `send`.
##   Samples are drawn into pools allocated once, after one seeding per test, and served by
##     `served`.
##   Cost: stub builds without `-d:ssl`, so TLS and tunnel through proxy stay untested, and every
##     host is address, so name lookup does too; placeholder test reports gap (Article IX.9).

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[
  asyncdispatch, asynchttpserver, asyncnet, options, random, sequtils, strutils, unittest, uri,
]

import ../../app/exchanges
import ../../src/lojban_tagger/suggestions


type
  Piece {.pure.} = enum  ## Define piece of recording file, in order file holds them.
    Header  ## First line: format and version.
    Label  ## Line `label <text>`.
    Request  ## Line `request <bytes>`.
    RequestBytes  ## Request, then line break.
    Status  ## Line `status <code>`.
    ContentType  ## Line `content-type <value>`.
    ContentEncoding  ## Line `content-encoding <value>`.
    Location  ## Line `location <value>`.
    Body  ## Line `body <whole|cut> <bytes>`.
    BodyBytes  ## Body, then line break.

  Fault {.pure.} = enum  ## Define how one piece of recording file goes wrong.
    Missing  ## Text ends before piece.
    Unbroken  ## Text ends before line break closing piece.
    Renamed  ## First letter of piece capitalised.
    Unspaced  ## Space after field name dropped, as editor trimming line end drops it.
    Doubled  ## Piece stands twice, so copy stands where next piece should.
    Dropped  ## Piece left out, so next piece stands where it should.
    Valued  ## Value field refuses.
    Short  ## Count names one byte more than block holds.
    Long  ## Count names one byte fewer than block holds.
    Trailing  ## Byte follows last piece.

  Malformed = object  ## Define one malformed file, with line and problem reader should give.
    piece: Piece  ## Piece holding fault.
    fault: Fault  ## Fault of piece.
    at: Piece  ## Piece reader should refuse at: piece itself, or next where copy stands there.
    text: string  ## File text.
    line: int  ## Line reader should refuse at, counted from one.
    problem: string  ## Problem reader should give.

  Stamped = object  ## Define one random request, beside copy holding one byte changed.
    request: string  ## Request.
    changed: string  ## Request with one byte changed; empty where request is.

  Head = object  ## Define request as raw listener read it, byte for byte.
    lines: seq[string]  ## Request line, then each header line, line breaks dropped.
    body: string  ## Body, as many bytes as `content-length` names.

  Server = ref object  ## Define loopback server answering by path, shared with its handlers.
    listener: AsyncHttpServer  ## Server of `std/asynchttpserver`, bound to `127.0.0.1`.
    port: int  ## Port system chose.
    body: string  ## Bytes routes `/sized/<n>` and `/chunked/<n>` serve first `n` of.
    location: string  ## Location route `/moved/<status>` names.
    held: Future[void]  ## Future route `/held` completes once it holds request unanswered.
    targets: seq[string]  ## Target of each request read, as its request line names it.
    count_connections: int  ## Connections accepted.
    accepting: Future[void]  ## Loop accepting connections; ends once listener closes.


const
  SAMPLES_STAMPS = 500  ## Random requests each stamp law is checked over.
  SAMPLES_RECORDINGS = 300  ## Random recordings round trip is checked over.
  SAMPLES_CREDENTIALS = 400  ## Random values credential law is checked over, under each service.
  SAMPLES_BODIES = 20  ## Random bodies `send` is checked to carry byte for byte.
  FLOOR_CHANGED = 400  ## Fewest requests holding byte to change; 449 read at seed `0`.
  FLOOR_READ = 350  ## Fewest values read as credential, over every service; 446 read at seed `0`.
  FLOOR_REFUSED = 600  ## Fewest values refused, over every service; 754 read at seed `0`.
  BYTES_SAMPLE_MAX = 4_096  ## Most bytes of random request or body.
  BYTES_CAP = 10_000  ## Cap `send` reads body up to here.
  BYTES_CHUNK = 1_000
    ## Bytes of each chunk chunked route serves; divides `BYTES_CAP`, so piece of stream ends at
    ##   cap, while length route reads pieces of `BufferSize`, 4,000 bytes, one spanning cap.
  CREDENTIAL_SUITE = "credential-for-suite"  ## Credential requests here carry, where one does.
  CREDENTIAL_GIVEN = some(Credential(CREDENTIAL_SUITE))  ## `CREDENTIAL_SUITE`, as `send` takes it.
  NAME_CREDENTIAL = "LOJBAN_TAGGER_API_KEY"  ## Variable each credential here is read from.
  SYMBOLS_SECRET = "!#$%&*+=?@^|~"  ## Bytes random secrets are spelled from; no problem holds one.
  DIGITS_STAMP = {'0'..'9', 'a'..'f'}  ## Digits stamp is written in.
  TEXT_PASSAGE = "Alice <b>&amp;</b> \"her sister\"\non bank\xE2\x80\xA6"
    ## Passage service requests here carry: markup, quotes, line break and multibyte.
  RECORDING_BASE = Recording(
    label: "documented shape",
    request: "POST {\"a\":\n1}",
    reply: Reply(status: 200, content_type: "application/json", body: "{\n}"),
  )
    ## Recording malformed files start from; request and body span two lines each.
  PIECES_BASE: array[Piece, string] = [
    HEADER_RECORDING & "\n", "label documented shape\n", "request 13\n", "POST {\"a\":\n1}\n",
    "status 200\n", "content-type application/json\n", "content-encoding \n", "location \n",
    "body whole 3\n", "{\n}\n",
  ]
    ## File of `RECORDING_BASE`, piece by piece, as format names them.
  LUT_PROBLEM_BY_PIECE: array[Piece, string] = [
    "", "Line should be `label <text>`.", "Line should be `request <bytes>`.",
    "Request should hold bytes its line counts.", "Line should be `status <code>`, three digits.",
    "Line should be `content-type <value>`.", "Line should be `content-encoding <value>`.",
    "Line should be `location <value>`.", "Line should be `body <whole|cut> <bytes>`.",
    "Body should hold bytes its line counts.",
  ]
    ## Problem reader gives at each piece; header problem echoes line, so `problemExpected`
    ##   builds it.
  PROBLEM_END = "Recording should end after body."  ## Problem reader gives at byte after body.
  FAULTS_LINE = {Fault.Missing, Fault.Unbroken, Fault.Renamed, Fault.Doubled, Fault.Dropped}
    ## Faults every line piece admits.
  FAULTS_BLOCK = {Fault.Missing, Fault.Unbroken, Fault.Short, Fault.Long}
    ## Faults every block piece admits.
  LUT_FAULTS_BY_PIECE: array[Piece, set[Fault]] = [
    FAULTS_LINE + {Fault.Valued}, FAULTS_LINE + {Fault.Unspaced},
    FAULTS_LINE + {Fault.Unspaced, Fault.Valued}, FAULTS_BLOCK,
    FAULTS_LINE + {Fault.Unspaced, Fault.Valued}, FAULTS_LINE + {Fault.Unspaced},
    FAULTS_LINE + {Fault.Unspaced}, FAULTS_LINE + {Fault.Unspaced},
    FAULTS_LINE + {Fault.Unspaced, Fault.Valued}, FAULTS_BLOCK + {Fault.Trailing},
  ]
    ## Faults each piece admits: header holds no field name to unspace, and label and header
    ##   values take any text, so no value of theirs is refused.
  LUT_VALUES_BY_PIECE: array[Piece, seq[string]] = [
    @["lojban_tagger recording 2"], @[], @["", "x", "-1", "1 3", "1234567890"], @[],
    @["", "20", "2000", "2x0", "-20"], @[], @[], @[],
    @[
      "whole", "cut", "part 3", "whole x", "whole -3", "whole  3", "whole 3 3",
      "whole 1234567890",
    ],
    @[],
  ]
    ## Values each piece refuses: whole line of header, else value after name of field.
  COUNT_MALFORMED = 75  ## Malformed files: every piece with every fault and value it admits.
  ANSWER_RAW = "HTTP/1.1 201 Created\r\ncontent-type: text/plain; charset=utf-8\r\n" &
      "content-encoding: identity\r\nlocation: /next\r\ncontent-length: 5\r\n" &
      "connection: close\r\n\r\nhello"
    ## Answer raw listener gives each request.
  REPLY_RAW = Reply(
    status: 201,
    content_type: "text/plain; charset=utf-8",
    content_encoding: "identity",
    location: "/next",
    body: "hello",
  )
    ## Reply `send` should read from `ANSWER_RAW`.
  ANSWER_FOLDED = "HTTP/1.1 302 Found\r\nlocation: /a\r\n /b\r\ncontent-length: 0\r\n" &
      "connection: close\r\n\r\n"
    ## Answer raw listener gives where redirect folds its location onto second line.
  URL_BASE = "http://a/b/c/d;p?q"  ## URL examples of RFC 3986 section 5.4 resolve against.
  CHARACTERS_CONTROL = {'\0'..'\x1F', '\x7F'}  ## Control characters of ASCII: C0 set and DEL.


func lineFirst(piece: Piece): int =
  ## Count first line of piece in `PIECES_BASE`, from one.
  result = 1
  for before in Piece:
    if before < piece: result += PIECES_BASE[before].count('\n')


func problemExpected(piece: Piece, text: string): string =
  ## Build problem reader gives at piece of text; header problem ends in first line text holds.
  if piece != Piece.Header: return LUT_PROBLEM_BY_PIECE[piece]
  let first = if '\n' in text: text.split('\n')[0] else: ""
  "Recording should open with `" & HEADER_RECORDING & "`; got `" & first & "`."


func casesMalformed(): seq[Malformed] =
  ## Build each piece of `PIECES_BASE` with each fault, and each value, `LUT_FAULTS_BY_PIECE`
  ##   and `LUT_VALUES_BY_PIECE` give it; reader should refuse at piece, or at next one where
  ##   copy stands in its place.
  for piece in Piece:
    var before, after: string
    for other in Piece:
      if other < piece: before.add PIECES_BASE[other]
      elif other > piece: after.add PIECES_BASE[other]
    let
      own = PIECES_BASE[piece]
      space = own.find(' ')
    for fault in LUT_FAULTS_BY_PIECE[piece]:
      var (texts, at) = (newSeq[string](), piece)
      case fault
      of Fault.Missing: texts.add before
      of Fault.Unbroken: texts.add before & own[0 ..< ^1]
      of Fault.Renamed: texts.add before & own.capitalizeAscii & after
      of Fault.Unspaced: texts.add before & own[0..<space] & own[space+1 .. ^1] & after
      of Fault.Doubled:
        texts.add before & own & own & after
        at = succ(piece)
      of Fault.Dropped: texts.add before & after
      of Fault.Valued:
        let name = if piece == Piece.Header: "" else: own[0..space]
        for value in LUT_VALUES_BY_PIECE[piece]: texts.add before & name & value & "\n" & after
      of Fault.Short, Fault.Long:
        let
          line_count = PIECES_BASE[pred(piece)]
          opening = before[0 ..< ^line_count.len] & line_count[0..line_count.rfind(' ')]
          count = own.len - 1 + (if fault == Fault.Short: 1 else: -1)
        texts.add opening & $count & "\n" & own & after
      of Fault.Trailing: texts.add before & own & "x"
      for text in texts:
        let (line, problem) =
          if fault == Fault.Trailing: (lineFirst(piece) + own.count('\n'), PROBLEM_END)
          else: (lineFirst(at), problemExpected(at, text))
        result.add Malformed(
          piece: piece,
          fault: fault,
          at: at,
          text: text,
          line: line,
          problem: problem,
        )


proc lineRandom(length_max: int): string =
  ## Draw bytes of one line: empty one time in four, else any byte but line break.
  if rand(3) == 0: return ""
  result = newString(rand(1..length_max))
  for character in result.mitems:
    let code = rand(254)
    character = char(if code >= ord('\n'): code + 1 else: code)


proc bytesRandom(): string =
  ## Draw bytes of request or body: empty, line breaks alone, file text of recording, or up to
  ##   `BYTES_SAMPLE_MAX` of any byte, line break one time in eight and last one time in four.
  case rand(7)
  of 0: return ""
  of 1: return "\n".repeat(rand(1..3))
  of 2: return RECORDING_BASE.toText
  else: discard
  result = newString(rand(1..BYTES_SAMPLE_MAX))
  for character in result.mitems: character = (if rand(7) == 0: '\n' else: char(rand(255)))
  if rand(3) == 0: result[^1] = '\n'


proc recordingRandom(): Recording =
  ## Draw recording: label and header values of any byte but line break, status of three
  ##   digits, request and body of any bytes, cut half time.
  Recording(
    label: lineRandom(80),
    request: bytesRandom(),
    reply: Reply(
      status: rand(100..999),
      content_type: lineRandom(80),
      content_encoding: lineRandom(16),
      location: lineRandom(200),
      body: bytesRandom(),
      is_cut: rand(1) == 0,
    ),
  )


proc valueRandom(): string =
  ## Draw credential value: empty one time in sixteen; else opening of random service, then
  ##   eight to forty bytes of `SYMBOLS_SECRET`, holding byte outside visible ASCII one time in
  ##   three, then whitespace at either end one time in four.
  if rand(15) == 0: return ""
  var secret = newString(rand(8..40))
  for character in secret.mitems: character = SYMBOLS_SECRET.sample
  if rand(2) == 0:
    secret.insert($char(if rand(1) == 0: rand(0..32) else: rand(127..255)), rand(secret.len))
  result = LUT_OPENING_BY_SERVICE[rand(Service)] & secret
  if rand(3) == 0: result = [" ", "\t", "\v", "\f"].sample & result & "\r\n"


proc poolStamps(): seq[Stamped] =
  ## Draw `SAMPLES_STAMPS` random requests into pool allocated once, each beside copy with one
  ##   byte changed to other byte; caller seeds first.
  result = newSeqOfCap[Stamped](SAMPLES_STAMPS)
  for _ in 1..SAMPLES_STAMPS:
    var sample = Stamped(request: bytesRandom())
    if sample.request.len > 0:
      sample.changed = sample.request
      let at = rand(sample.changed.high)
      sample.changed[at] = char((ord(sample.changed[at]) + rand(1..255)) mod 256)
    result.add sample


proc poolRecordings(): seq[Recording] =
  ## Draw `SAMPLES_RECORDINGS` random recordings into pool allocated once; caller seeds first.
  result = newSeqOfCap[Recording](SAMPLES_RECORDINGS)
  for _ in 1..SAMPLES_RECORDINGS: result.add recordingRandom()


proc poolValues(): seq[string] =
  ## Draw `SAMPLES_CREDENTIALS` random credential values into pool allocated once; caller seeds
  ##   first.
  result = newSeqOfCap[string](SAMPLES_CREDENTIALS)
  for _ in 1..SAMPLES_CREDENTIALS: result.add valueRandom()


proc poolBodies(): seq[string] =
  ## Draw `SAMPLES_BODIES` random bodies into pool allocated once; caller seeds first.
  result = newSeqOfCap[string](SAMPLES_BODIES)
  for _ in 1..SAMPLES_BODIES: result.add bytesRandom()


iterator served[T](pool: seq[T]): lent T =
  ## Serve each sample of pool in order, with no copy.
  for i in 0..<pool.len: yield pool[i]


func urlLoopback(port: int, path: string): string =
  ## Build URL of path on `127.0.0.1` at port.
  "http://127.0.0.1:" & $port & path


func problemURL(code, at: int): string =
  ## Build problem `send` gives for URL holding byte `code` at `at`.
  "URL should hold no whitespace or control character; got byte `" & $code & "` at `" & $at &
      "`."


func values(head: Head, name: string): seq[string] =
  ## Read value of each header line naming `name`, compared without case, as `send` writes it.
  for i in 1..<head.lines.len:
    let at = head.lines[i].find(": ")
    if at > 0 and head.lines[i][0..<at].toLowerAscii == name.toLowerAscii:
      result.add head.lines[i][at+2 .. ^1]


func toChunked(bytes: string): string =
  ## Render answer `200` carrying bytes in chunks of `BYTES_CHUNK`, as chunked coding frames them.
  result = "HTTP/1.1 200 OK\r\ntransfer-encoding: chunked\r\n\r\n"
  var at = 0
  while at < bytes.len:
    let piece = bytes[at..<min(at+BYTES_CHUNK, bytes.len)]
    result.add piece.len.toHex & "\r\n" & piece & "\r\n"
    at += BYTES_CHUNK
  result.add "0\r\n\r\n"


proc listenRaw(): AsyncSocket =
  ## Open listener of `std/asyncnet` on `127.0.0.1` at port system chooses.
  result = newAsyncSocket()
  result.setSockOpt(OptReuseAddr, true)
  result.bindAddr(Port(0), "127.0.0.1")
  result.listen()


proc readHead(listener: AsyncSocket, answer: string = ANSWER_RAW): Future[Head] {.async.} =
  ## Accept one connection, read its request byte for byte, give it `answer`, then close.
  let client = await listener.accept()
  var head: Head
  while true:
    let line = await client.recvLine()
    if line in ["", "\r\n"]: break
    head.lines.add line
  let lengths = head.values("content-length")
  if lengths.len > 0: head.body = await client.recv(lengths[0].parseInt)
  await client.send(answer)
  client.close()
  return head


proc answer(server: Server, request: Request) {.async.} =
  ## Answer request by its path: `/moved/<status>`, `/sized/<n>`, `/chunked/<n>` and `/held`,
  ##   else `204`; keep target its request line names.
  server.targets.add $request.url
  let parts = request.url.path.split('/')
  case parts[1]
  of "moved":
    let headers = newHttpHeaders({"location": server.location})
    await request.respond(HttpCode(parts[2].parseInt), "", headers)
  of "sized": await request.respond(Http200, server.body[0..<parts[2].parseInt])
  of "chunked": await request.client.send(server.body[0..<parts[2].parseInt].toChunked)
  of "held":
    server.held.complete()
    discard await request.client.recv(1)  # hold until client closes, never answering
  else: await request.respond(Http204, "")


proc acceptConnections(server: Server) {.async.} =
  ## Accept connections until listener closes, counting each, and answer each request.

  proc answerServer(request: Request): Future[void] {.closure, gcsafe.} = server.answer(request)
    ## Answer request as `server` does, in shape `acceptRequest` takes.

  while true:
    try:
      await server.listener.acceptRequest(answerServer)
    except CatchableError:
      return
    inc server.count_connections


proc startServer(body = ""): Server =
  ## Start server on `127.0.0.1` at port system chooses, accepting until `stopServer`.
  result = Server(listener: newAsyncHttpServer(), body: body, held: newFuture[void]("held"))
  result.listener.listen(Port(0), "127.0.0.1")
  result.port = int(result.listener.getPort)
  result.accepting = result.acceptConnections


proc stopServer(server: Server) =
  ## Close listener, then drive loop until loop accepting connections ends.
  server.listener.close()
  waitFor server.accepting


proc portClosed(): int =
  ## Bind server on `127.0.0.1` to port system chooses, then close it, so port refuses connection.
  let listener = newAsyncHttpServer()
  listener.listen(Port(0), "127.0.0.1")
  result = int(listener.getPort)
  listener.close()


proc sendLoopback(
  url, body: string;
  headers: seq[(string, string)] = @[];
  credential = none(Credential);
  proxy_url = none(string);
): Sent =
  ## Send through `send` with cap `BYTES_CAP` and deadline no one completes, driving loop until
  ##   it ends; problem goes to checkpoint, so failing check names it.
  result = waitFor send(
    url,
    body,
    headers,
    credential,
    proxy_url,
    nil,
    BYTES_CAP,
    newFuture[void]("deadline"),
  )
  if not result.is_replied: checkpoint "Problem: " & result.problem



suite "Internal: Exchange":
  test "stamp gives published vectors of FNV-1a 64, as sixteen lowercase hexadecimal digits":
    check stamp("") == "cbf29ce484222325"  # FNV-1a 64 of empty text, i.e. offset basis
    check stamp("a") == "af63dc4c8601ec8c"  # FNV-1a 64 test vector
    check stamp("foobar") == "85944171f73967e8"  # FNV-1a 64 test vector
    randomize(0)
    let pool = poolStamps()
    for sample in served(pool):
      let stamped = stamp(sample.request)
      check stamped.len == 16 and stamped.allIt(it in DIGITS_STAMP)  # sixteen lowercase digits
      check stamp(sample.request) == stamped  # same request, same stamp


  test "stamp changes wherever one byte of request changes":
    randomize(0)
    let pool = poolStamps()
    var passed = 0
    for sample in served(pool):
      if sample.request.len == 0: continue
      inc passed
      check stamp(sample.changed) != stamp(sample.request)  # each step maps state one to one
    check passed >= FLOOR_CHANGED  # guard leaves enough requests holding byte to change


  test "recording reads back as written, request and body of any bytes":
    randomize(0)
    let pool = poolRecordings()
    for recording in served(pool):
      let
        text = recording.toText
        recorded = text.readRecording
      check text.startsWith(HEADER_RECORDING & "\n")  # format and version open file
      check recorded.is_read  # file of any request and body reads
      if not recorded.is_read:
        checkpoint $recorded.line & ": " & recorded.problem
        continue
      check recorded.recording == recording  # every field back, byte for byte


  test "malformed recording is refused naming its first faulty piece, each piece with each fault":
    check RECORDING_BASE.toText == PIECES_BASE.join  # file holds pieces in order format names
    check RECORDING_BASE.toText.readRecording.is_read  # whole file reads, so fault alone refuses
    let cases = casesMalformed()
    var (pieces, faults) = (default(set[Piece]), default(set[Fault]))
    for malformed in cases:
      let
        recorded = malformed.text.readRecording
        named = $malformed.piece & " " & $malformed.fault & ": "
      check not recorded.is_read  # refused
      if recorded.is_read: continue
      check named & recorded.problem == named & malformed.problem  # what faulty line should be
      # TODO: Hold line of fault reader reads whole too, once it names that line, not next one.
      if malformed.fault in {Fault.Missing, Fault.Unbroken, Fault.Trailing} or
          malformed.at in {Piece.RequestBytes, Piece.BodyBytes}:
        check named & $recorded.line == named & $malformed.line  # line of fault, from one
      pieces.incl malformed.piece
      faults.incl malformed.fault
    check cases.len == COUNT_MALFORMED  # every piece with every fault and value it admits
    check pieces == {Piece.low..Piece.high} and faults == {Fault.low..Fault.high}  # exhaustive


  test "URL is one http or https URL with host and no whitespace":
    for (text, expected) in [
      ("http://example.org", true),
      ("https://example.org/a?b=c#d", true),  # path, query and fragment
      ("HTTPS://EXAMPLE.ORG/", true),  # scheme in capitals
      ("https://user:secret@example.org/", true),  # user part before host
      ("http://127.0.0.1:8080/page", true),
      ("http://[::1]:8080/page", true),
      ("example.org", false),  # no scheme
      ("ftp://example.org/file", false),  # scheme neither http nor https
      ("file:///etc/hosts", false),  # no host
      ("http://", false),
      ("http:example.org", false),  # no authority
      ("http:// example.org", false),  # whitespace
      ("http://example.org/a b", false),
      ("http://example.org/\n", false),
      ("\thttp://example.org", false),
      ("", false),
      ("mailto:someone@example.org", false),
      ("javascript:alert(1)", false),
    ]:
      check text.isURL == expected  # one http or https URL with host and no whitespace


  test "loopback host is `localhost`, `127.0.0.0/8` or `::1`, in any case":
    for (host, expected) in [
      ("localhost", true),
      ("LocalHost", true),  # case folded
      ("127.0.0.1", true),
      ("127.255.255.254", true),  # whole range of eight bits
      ("127.0.0.01", true),  # three digits or fewer each
      ("::1", true),
      ("[::1]", true),  # bracketed as URL writes it
      ("localhost.example.org", false),  # name under other domain
      ("127.0.0.1.example.org", false),
      ("128.0.0.1", false),
      ("0.0.0.0", false),
      ("10.0.0.1", false),
      ("127.0.0.256", false),  # part past 255
      ("127.0.0.0001", false),  # part of four digits
      ("127.0.0", false),  # three parts
      ("127.0.0.1.2", false),  # five parts
      ("127..0.1", false),  # empty part
      ("127.0.0.-1", false),
      ("::2", false),
      ("", false),
    ]:
      check host.isLoopback == expected  # `localhost`, `127.0.0.0/8` or `::1` alone


  test "endpoint is https, or http to loopback host":
    for (url, expected) in [
      ("https://api.anthropic.com/v1/messages", true),  # https to any host
      ("HTTPS://api.example.org/", true),
      ("http://127.0.0.1:8080/v1/messages", true),  # http to loopback
      ("http://localhost/v1", true),
      ("http://[::1]:9000/v1", true),
      ("http://127.9.9.9/v1", true),
      ("http://api.anthropic.com/v1/messages", false),  # http to other host: credential in clear
      ("http://localhost.example.org/", false),
      ("http://127.0.0.1.example.org/", false),
      ("http://10.0.0.1/", false),
      ("ftp://127.0.0.1/", false),  # no URL
      ("https://", false),
      ("https://example.org/a b", false),
      ("", false),
    ]:
      check url.isEndpoint == expected  # credential travels encrypted, or never leaves host


  test "proxy follows curl: https takes lowercase first, http takes `http_proxy` alone":
    let
      lower = ("https_proxy", "http://lower.example:3128")
      upper = ("HTTPS_PROXY", "http://upper.example:3128")
      plain = ("http_proxy", "http://plain.example:3128")
      shout = ("HTTP_PROXY", "http://shout.example:3128")
      (https, http) = ("https://api.example.org/v1", "http://api.example.org/v1")
      bypass = [("no_proxy", "other.org"), ("NO_PROXY", "example.org")]
    for (url, environment, expected) in [
      (https, @[lower], some(lower[1])),
      (https, @[upper], some(upper[1])),
      (https, @[lower, upper], some(lower[1])),  # lowercase first, as curl reads it
      (https, @[upper, lower], some(lower[1])),  # whatever order environment lists
      (https, @[("https_proxy", " "), upper], some(upper[1])),  # blank value reads as unset
      (https, @[plain, shout], none(string)),  # proxy of http never carries https
      (http, @[plain], some(plain[1])),
      (http, @[shout], none(string)),  # uppercase `HTTP_PROXY` unread, as curl leaves it
      (http, @[lower, upper], none(string)),  # proxy of https never carries http
      (https, @[("https_proxy", "lower.example:3128")], some(lower[1])),  # scheme added
      (https, @[("https_proxy", "socks5h://s.example:1080")], some("socks5h://s.example:1080")),
      (https, @[("https_proxy", " http://lower.example:3128 ")], some(lower[1])),  # trimmed
      ("HTTPS://api.example.org/", @[lower], some(lower[1])),  # scheme in capitals
      ("https://127.0.0.1:8443/v1", @[lower, upper], none(string)),  # loopback goes direct
      ("http://localhost:8080/v1", @[plain], none(string)),
      ("http://[::1]:8080/v1", @[plain], none(string)),
      (https, @[lower, ("no_proxy", "example.org")], none(string)),  # bypass list names host
      (https, @[lower, ("NO_PROXY", "example.org")], none(string)),
      (https, @[lower] & @bypass, some(lower[1])),  # lowercase list first, as curl reads it
      (https, @[lower, ("no_proxy", " "), ("NO_PROXY", "example.org")], none(string)),
      ("https://API.Example.ORG/", @[lower, ("no_proxy", ".example.org")], none(string)),
      (https, @[lower, ("no_proxy", "*")], none(string)),
      ("ftp://api.example.org/", @[lower, upper, plain], none(string)),  # no proxy for ftp
      (https, newSeq[(string, string)](), none(string)),  # environment names no proxy
    ]:
      check url.proxy(environment) == expected  # variable as curl picks it, bypass, then scheme


  test "bypass list names host by `*`, host itself or domain it ends in, case folded":
    for (host, list, expected) in [
      ("example.org", "*", true),  # every host
      ("example.org", "example.org", true),  # host itself
      ("api.example.org", "example.org", true),  # domain host ends in
      ("api.example.org", ".example.org", true),  # domain with leading dot
      ("example.org", ".example.org", true),  # leading dot names domain itself too
      ("api.example.org", "org", true),  # top level domain names every host under it
      ("API.Example.ORG", "example.org", true),  # host case folded
      ("api.example.org", "EXAMPLE.org", true),  # entry case folded
      ("api.example.org", " other.org , example.org ", true),  # entries trimmed, any position
      ("badexample.org", "example.org", false),  # domain ends only at dot
      ("example.org.evil", "example.org", false),
      ("example.org", "other.org", false),
      ("example.org", "", false),  # empty list
      ("example.org", ",, ,", false),  # empty entries
      ("example.org", ".", false),  # dot alone names nothing
      ("api.example.org", "*.example.org", false),  # `*` names every host only alone, as curl
      ("10.1.2.3", "10.0.0.0/8", false),  # cost: address range never matched
    ]:
      check host.isBypassed(list) == expected  # entry names host, domain or every host


  test "redirect resolves location as RFC 3986 section 5.4 resolves reference":
    for (reference, expected) in [
      ("g", "http://a/b/c/g"),
      ("./g", "http://a/b/c/g"),
      ("g/", "http://a/b/c/g/"),
      ("/g", "http://a/g"),
      ("//g", "http://g"),
      ("?y", "http://a/b/c/d;p?y"),
      ("g?y", "http://a/b/c/g?y"),
      ("#s", "http://a/b/c/d;p?q#s"),
      ("g#s", "http://a/b/c/g#s"),
      ("g?y#s", "http://a/b/c/g?y#s"),
      (";x", "http://a/b/c/;x"),
      ("g;x", "http://a/b/c/g;x"),
      ("g;x?y#s", "http://a/b/c/g;x?y#s"),
      ("./", "http://a/b/c/"),
      ("../", "http://a/b/"),
      ("../g", "http://a/b/g"),
      ("../../", "http://a/"),
      ("../../g", "http://a/g"),  # last of normal examples, 5.4.1
      ("../../../g", "http://a/g"),  # first of abnormal examples, 5.4.2
      ("/./g", "http://a/g"),
      ("/../g", "http://a/g"),
      ("g.", "http://a/b/c/g."),
      (".g", "http://a/b/c/.g"),
      ("g..", "http://a/b/c/g.."),
      ("..g", "http://a/b/c/..g"),
      ("./../g", "http://a/b/g"),
      ("g/./h", "http://a/b/c/g/h"),
      ("g/../h", "http://a/b/c/h"),
      ("g;x=1/./y", "http://a/b/c/g;x=1/y"),
      ("g;x=1/../y", "http://a/b/c/y"),
      ("g?y/./x", "http://a/b/c/g?y/./x"),
      ("g?y/../x", "http://a/b/c/g?y/../x"),
      ("g#s/./x", "http://a/b/c/g#s/./x"),
      ("g#s/../x", "http://a/b/c/g#s/../x"),
    ]:
      check URL_BASE.redirect(Reply(status: 302, location: reference)) ==
          some(expected)  # RFC 3986 5.4, base `http://a/b/c/d;p?q`


  test "redirect follows statuses of `STATUSES_REDIRECT` alone, and only to http or https":
    for status in 100..599:
      check "https://example.org/a".redirect(Reply(status: status, location: "/b")).isSome ==
          (status in STATUSES_REDIRECT)  # 301, 302, 303, 307 and 308, as client follows
    for (url, location, expected) in [
      ("https://example.org/a/b", "c", some("https://example.org/a/c")),  # relative path
      ("https://example.org/a/b", "/c", some("https://example.org/c")),  # absolute path
      ("https://example.org/a", "https://other.example/x", some("https://other.example/x")),
      ("https://example.org/a", "//other.example/x", some("https://other.example/x")),  # https
      ("http://example.org/a", "//other.example/x", some("http://other.example/x")),  # http
      ("http://example.org/a", "https://example.org/a", some("https://example.org/a")),  # rises
      ("https://example.org/a", " /c ", some("https://example.org/c")),  # location trimmed
      ("https://example.org/a", "http://example.org/a", none(string)),  # never falls to http
      ("https://example.org/a", "HTTP://example.org/a", none(string)),  # nor in capitals
      ("https://example.org/a", "ftp://example.org/file", none(string)),  # neither http nor https
      ("https://example.org/a", "javascript:alert(1)", none(string)),
      ("https://example.org/a", "mailto:someone@example.org", none(string)),
      ("https://example.org/a", "g:h", none(string)),  # RFC 3986 5.4.1, scheme `g`
      ("https://example.org/a", "", none(string)),  # no location
    ]:
      for status in STATUSES_REDIRECT:
        check url.redirect(Reply(status: status, location: location)) ==
            expected  # target resolved, or none where it leaves http and https or falls


  test "redirect refuses target holding whitespace or control character, wherever it stands":
    # Regression: target kept space and line break, which `send` then wrote into request line.
    let base = "http://a.example/"
    check base.redirect(Reply(status: 302, location: "/b c")).isNone  # case as found in review
    check base.redirect(Reply(status: 302, location: "/a\n /b")).isNone  # case as found: folded
    for code in 0..255:
      let
        character = char(code)
        is_refused = character in Whitespace + CHARACTERS_CONTROL
      for (location, is_end) in [
        (character & "/c", true), ("/c" & character & "d", false), ("/c" & character, true),
      ]:
        let
          target = base.redirect(Reply(status: 302, location: location))
          is_trimmed = is_end and character in Whitespace
          named = location.escape & ": "
        check named & $target.isSome ==
            named & $(is_trimmed or not is_refused)  # domain: refused unless trimmed at end
        if target.isSome:
          check named & $target.get.find(Whitespace + CHARACTERS_CONTROL) ==
              named & "-1"  # domain: target holds none
      let moved = (base & "b" & character & "/").redirect(Reply(status: 302, location: "c"))
      check $code & ": " & $moved.isSome ==
          $code & ": " & $(not is_refused)  # domain: base holding one refused too


  test "credential is read trimmed, and refused naming variable and fault, never value":
    for (value, service, expected) in [
      ("sk-ant-secret", Service.Claude, "sk-ant-secret"),
      (" \tsk-ant-secret\r\n", Service.Claude, "sk-ant-secret"),  # whitespace at ends trimmed
      ("sk-or-secret", Service.OpenRouter, "sk-or-secret"),
      ("plain-secret", Service.Chat, "plain-secret"),
      ("plain-secret", Service.Claude, "plain-secret"),  # no opening is no other service's
    ]:
      let read = readCredential(NAME_CREDENTIAL, value, service)
      check read.is_read  # visible ASCII, issued by no other service
      if not read.is_read: continue
      check string(read.credential) == expected and read.name == NAME_CREDENTIAL  # trimmed
    let
      byte_at = "Credential should hold visible ASCII alone; got byte `"
      named = "` for `" & NAME_CREDENTIAL & "`."
    for (value, service, expected) in [
      ("", Service.Claude, "Credential should be set; got `" & named),
      (" \r\n\t", Service.Claude, "Credential should be set; got `" & named),  # blank is unset
      ("sk-ant-sec\rret", Service.Claude, byte_at & "13` at `10" & named),  # would split header
      ("sk-ant-sec\nret", Service.Claude, byte_at & "10` at `10" & named),
      ("sk-ant-sec ret", Service.Claude, byte_at & "32` at `10" & named),
      ("sk-ant-sec\x80ret", Service.Claude, byte_at & "128` at `10" & named),
      ("sk-or-secret", Service.Claude, "Credential should be issued by service `claude`; " &
          "got opening `sk-or-" & named),  # key of OpenRouter never goes to Anthropic
      ("sk-ant-secret", Service.OpenRouter, "Credential should be issued by service " &
          "`openrouter`; got opening `sk-ant-" & named),
      ("sk-ant-secret", Service.Chat, "Credential should be issued by service `chat`; " &
          "got opening `sk-ant-" & named),
      ("sk-or-secret", Service.Chat, "Credential should be issued by service `chat`; " &
          "got opening `sk-or-" & named),
    ]:
      let read = readCredential(NAME_CREDENTIAL, value, service)
      check not read.is_read  # refused
      if read.is_read: continue
      check read.problem == expected  # names variable, and byte, position or opening
      check value.strip.len == 0 or value.strip notin read.problem  # never value


  test "byte outside visible ASCII is refused where it stands, and whitespace at ends trimmed":
    for service in Service:
      let opening = LUT_OPENING_BY_SERVICE[service]
      for code in 0..255:
        let character = char(code)
        for (value, at) in [
          ($character & opening & "secret", 0),
          (opening & "sec" & character & "ret", opening.len + 3),
          (opening & "secret" & character, opening.len + 6),
        ]:
          let
            read = readCredential(NAME_CREDENTIAL, value, service)
            is_trimmed = character in Whitespace and (at == 0 or at == value.high)
          check read.is_read == (character in {'!'..'~'} or is_trimmed)  # visible ASCII alone
          if read.is_read:
            check string(read.credential) == value.strip  # kept whole, or trimmed at ends
            continue
          check read.problem == "Credential should hold visible ASCII alone; got byte `" &
              $code & "` at `" & $at & "` for `" & NAME_CREDENTIAL & "`."  # byte and position


  test "problem names variable, and no byte of value, under every service":
    randomize(0)
    let pool = poolValues()
    var (count_read, count_refused) = (0, 0)
    for value in served(pool):
      for service in Service:
        let read = readCredential(NAME_CREDENTIAL, value, service)
        if read.is_read:
          inc count_read
          check string(read.credential) == value.strip  # value trimmed, nothing else changed
          continue
        inc count_refused
        check read.problem.allIt(it notin SYMBOLS_SECRET)  # no byte of secret leaks
        check read.problem.endsWith("` for `" & NAME_CREDENTIAL & "`.")  # names variable last
    check count_read >= FLOOR_READ  # guard leaves enough values read
    check count_refused >= FLOOR_REFUSED  # guard leaves enough values refused


  test "credential renders nowhere: `$`, echo and concatenation refuse to compile":
    let read = readCredential(NAME_CREDENTIAL, "sk-ant-secret", Service.Claude)
    check read.is_read  # credential read
    check not compiles($read.credential)  # `$` poisoned (Article IV.1)
    check not compiles(echo read.credential)  # nor printed, which renders through `$`
    check not compiles("Bearer " & read.credential)  # nor joined to text: `send` alone writes it



suite "Internal: Send":
  test "request arrives as built, naming agent, identity and one bearer where credential is given":
    randomize(0)
    let
      listener = listenRaw()
      url = urlLoopback(int(listener.getLocalAddr[1]), "/v1/messages?beta=true")
      passage = TEXT_PASSAGE.toPassage
      bodies = poolBodies()
    var requests: seq[tuple[body: string, headers: seq[(string, string)], has_credential: bool]]
    for service in Service:
      var efforts = @[none(Effort)]
      for effort in Effort: efforts.add some(effort)
      for effort in efforts:
        let settings = Settings(
          service: service,
          endpoint: url,
          model: "model-for-suite",
          effort: effort,
        )
        for has_credential in [false, true]:
          requests.add (settings.toBody(passage), settings.toHeaders, has_credential)
    requests.add ("", newSeq[(string, string)](), false)  # page, as `suggester` fetches it
    for body in served(bodies):
      requests.add (body, @[("content-type", "text/plain")], requests.len mod 2 == 0)
    for request in requests:
      let
        reading = listener.readHead
        credential = if request.has_credential: CREDENTIAL_GIVEN else: none(Credential)
        sent = sendLoopback(url, request.body, request.headers, credential)
      check sent.is_replied and sent.reply == REPLY_RAW  # status, headers kept, body as served
      if not sent.is_replied: continue
      let
        head = waitFor reading
        method_request = if request.body.len > 0: "POST" else: "GET"
        bearers = if request.has_credential: @["Bearer " & CREDENTIAL_SUITE] else: @[]
      check head.lines[0] == method_request & " /v1/messages?beta=true HTTP/1.1"  # by body
      check head.body == request.body  # body byte for byte
      check head.values("content-length") ==
          (if request.body.len > 0: @[$request.body.len] else: @[])  # length of body; GET none
      check request.headers.allIt(head.values(it[0]) == @[it[1]])  # each header once, as given
      check head.values("authorization") == bearers  # one bearer where credential given, else none
      check head.values("accept-encoding") == @["identity"]  # no coding reader cannot read
      check head.values("user-agent") == @[USER_AGENT]  # agent of tool
      check head.lines.countIt(CREDENTIAL_SUITE in it) == bearers.len  # credential nowhere else
    listener.close()


  test "credential replaces authorization caller names, and identity replaces its encoding":
    let
      listener = listenRaw()
      url = urlLoopback(int(listener.getLocalAddr[1]), "/v1/messages")
      decoys = @[
        ("Authorization", "Bearer decoy"), ("accept-encoding", "gzip"),
        ("content-type", "application/json"),
      ]
      reading = listener.readHead
      sent = sendLoopback(url, "{}", decoys, CREDENTIAL_GIVEN)
    check sent.is_replied  # answered
    if sent.is_replied:
      let head = waitFor reading
      check head.values("authorization") == @["Bearer " & CREDENTIAL_SUITE]  # one, credential's
      check head.values("accept-encoding") == @["identity"]  # one, identity
      check head.values("content-type") == @["application/json"]  # other header kept
    listener.close()


  test "redirect comes back unfollowed, and server at its location sees nothing":
    let (origin, target) = (startServer(), startServer())
    var count = 0
    for status in STATUSES_REDIRECT:
      for body in ["", "{\"a\":1}"]:
        for location in [urlLoopback(target.port, "/count"), "/count"]:
          origin.location = location
          let sent = sendLoopback(
            urlLoopback(origin.port, "/moved/" & $status),
            body,
            credential = CREDENTIAL_GIVEN,
          )
          inc count
          check sent.is_replied and sent.reply.status == status  # 3xx itself comes back
          check sent.is_replied and sent.reply.location == location  # location kept for `fetch`
    check origin.targets.len == count  # one request each, none followed back to origin
    check origin.count_connections == count  # each request on fresh connection
    check target.targets.len == 0  # server at location saw nothing, credential least of all
    let control = sendLoopback(urlLoopback(target.port, "/count"), "")
    check control.is_replied and target.targets == @["/count"]  # yet it listened all along
    stopServer(origin)
    stopServer(target)


  test "body keeps min(size, cap) bytes, cut exactly where size exceeds cap, by length or chunks":
    randomize(0)
    var bytes = newString(3 * BYTES_CAP)
    for character in bytes.mitems: character = char(rand(255))
    let server = startServer(bytes)
    for size in [0, 1, BYTES_CAP - 1, BYTES_CAP, BYTES_CAP + 1, 3 * BYTES_CAP]:
      for route in ["/sized/", "/chunked/"]:
        let sent = sendLoopback(urlLoopback(server.port, route & $size), "")
        check sent.is_replied and sent.reply.status == 200  # answered
        if not sent.is_replied: continue
        check sent.reply.body == bytes[0..<min(size, BYTES_CAP)]  # first bytes, up to cap
        check (route, size, sent.reply.is_cut) ==
            (route, size, size > BYTES_CAP)  # cut exactly where bytes stay unread
    stopServer(server)


  test "deadline completed by test while server holds request ends send with `deadline passed`":
    let
      server = startServer()
      deadline = newFuture[void]("deadline")
      sending = send(
        urlLoopback(server.port, "/held"),
        "{\"a\":1}",
        @[],
        CREDENTIAL_GIVEN,
        none(string),
        nil,
        BYTES_CAP,
        deadline,
      )
    waitFor server.held or sending
    check server.held.finished and not sending.finished  # server holds request; send awaits reply
    deadline.complete()  # test ends wait itself, so no clock is read
    poll()  # run callbacks completed deadline queued
    check sending.finished  # send ended once deadline completed, awaiting no byte
    check server.targets == @["/held"]  # request reached server
    if sending.finished:
      let sent = sending.read
      check not sent.is_replied and sent.problem == "deadline passed"  # named, never reply
    stopServer(server)


  test "request goes through proxy given, in absolute form, and target sees nothing":
    let
      (proxy_server, target) = (startServer(), startServer())
      sent = sendLoopback(
        urlLoopback(target.port, "/count"),
        "",
        proxy_url = some(urlLoopback(proxy_server.port, "")),
      )
    check sent.is_replied and sent.reply.status == 204  # proxy answered
    check proxy_server.targets == @[urlLoopback(target.port, "/count")]  # whole URL, as proxy reads
    check target.targets.len == 0  # no request went direct
    stopServer(proxy_server)
    stopServer(target)


  test "closed port gives problem of one line, holding no credential":
    let sent = sendLoopback(
      urlLoopback(portClosed(), "/v1/messages"),
      "{\"a\":1}",
      credential = CREDENTIAL_GIVEN,
    )
    check not sent.is_replied  # no reply
    if not sent.is_replied:
      check sent.problem.len > 0 and '\n' notin sent.problem  # first line of error alone
      check CREDENTIAL_SUITE notin sent.problem  # credential never in problem


  test "URL holding whitespace or control character is refused naming byte, and nothing goes out":
    # Regression: line break in URL let `AssertionDefect` of client out of `send`; folded
    #   location of redirect led there.
    let found = sendLoopback("http://127.0.0.1:9/a\nb", "")  # case as found in review
    check not found.is_replied and found.problem == problemURL(10, 20)  # case as found: refused
    let
      listener = listenRaw()
      url_moved = urlLoopback(int(listener.getLocalAddr[1]), "/moved")
      reading = listener.readHead(ANSWER_FOLDED)
      moved = sendLoopback(url_moved, "")
    discard waitFor reading
    check moved.is_replied and moved.reply.status == 302  # case as found: folded answer read
    check moved.is_replied and url_moved.redirect(moved.reply).isNone  # case as found: refused
    listener.close()
    let
      server = startServer()
      url = urlLoopback(server.port, "/count")
    for code in 0..255:
      let character = char(code)
      if character notin Whitespace + CHARACTERS_CONTROL: continue
      for (text, at) in [
        (character & url, 0), (url & character & "x", url.len), (url & character, url.len),
      ]:
        let sent = sendLoopback(text, "{}", credential = CREDENTIAL_GIVEN)
        check not sent.is_replied and sent.problem == problemURL(code, at)  # domain: byte named
    check server.targets.len == 0 and server.count_connections == 0  # domain: nothing went out
    let control = sendLoopback(url, "")
    check control.is_replied and server.targets == @["/count"]  # yet it listened all along
    stopServer(server)


  test "https goes through context and tunnel of proxy given":
    skip()  # Article IX.9, gap: stub builds without `-d:ssl`, and no root signs loopback server
