## Hold transport of `exchanges.nim` to its laws: stamp, recording file, URL tests, proxy,
##   redirect and credential by table and sample, and `send` over loopback, TLS included.
##   CLL covers no transport, so suites are `Internal:`, tests named by behaviour (Article IX.10).
##   Stamp meets published vectors of FNV-1a 64, and one law of its arithmetic: each step maps
##     state one to one, so requests of one length that differ in one byte never share stamp.
##   Random recordings hold request and body of any bytes, line breaks often and last often, and
##     file text of other recording; label holds lines of any byte, joined by line breaks, and
##     reads back on one line; header values hold no line break, since `send` unfolds each folded
##     one; every status of one to three digits reads back.
##   Malformed files take one recording whose request and body span lines, each piece of its
##     file with each fault that piece admits; file is written by suite, never by `toText`, and
##     each expected line is counted from pieces before it.
##     Each file holds line too: faulty line itself, as `readIndex` names it; problem ends in what
##     piece holds, line made printable or bytes left of block, as `readIndex` echoes line.
##   Port of URL is held by table of its bounds and by random ports with zeros before them,
##     through `isURL`, `isEndpoint` and `redirect`; scheme of URL and of proxy takes every
##     spelling of `http` and `https` in any case.
##   Proxy URL is held through `send`, port by table of its bounds and by random ports; each
##     opening, host, port and user part with each other is refused naming first part failing of
##     host, scheme, port and user part, which https URL refuses; user part is spelled from
##     symbols no problem holds, so any byte of it leaking into problem shows. Proxy `send` takes
##     meets pin, which refuses https URL for want of context, so laws open no socket; loopback
##     proxy shows what wraps and what is taken.
##     Each user part, empty or holding user, password or both, goes with each spelling of `http`
##       and `https` through tunnel to TLS server: https URL is refused where proxy holds user or
##       password, else tunnelled, server reading no login; http URL is taken, proxy reading login.
##   Redirect resolves every example of RFC 3986 section 5.4; `http:g` keeps its scheme, as
##     strict parser reads it, so has no host and gives no redirect. References of one to three
##     path segments, dot segments among them, hold laws: dot segments removed, target resolves
##     to itself, and `./` before relative path names same place.
##   URL holding whitespace or control character is refused by `redirect` and by `send`, each such
##     byte at start, middle and end; `send` meets live server, so refusal shows nothing went out.
##   Credential laws take every byte at start, middle and end of value; random secrets are spelled
##     from symbols no problem text holds, so any byte of value leaking into problem shows.
##   `send` meets servers of `std/asynchttpserver` in same process, on `127.0.0.1` at port system
##     chooses; raw listener of `std/asyncnet` reads request head byte for byte, since server
##     keeps last of repeated header lines, and gives answers server never writes: folded header
##     lines, and status `099`. Futures are driven by `waitFor` and `poll`; test
##     completes deadline itself once server holds request, so no test reads clock (Article
##     IX.12).
##     Test waits on future of its own beside `send`, never by `or` on deadline: `or` of
##     `std/asyncdispatch` replaces callbacks of futures it waits on, so it would unhook `send`.
##     Waiters that keep callbacks, `addCallback` and `await`, share deadline with sends, and
##     every one wakes; deadline finished before `send` leaves server with no connection.
##     Refused port is held by bound socket that never listens, open for whole test, so no other
##     socket takes port.
##   TLS runs in same process: suite makes test root and four leaves with `openssl` command at
##     run time, in fresh directory it removes at end, so no key is committed, and serves each
##     leaf on `127.0.0.1`; tunnel is raw proxy of `std/asyncnet` answering `CONNECT` and relaying
##     bytes, and answering other request itself, as proxy of http URL does. Each leaf goes to
##     name and to address after every other case, on one context, so pin of one send never
##     decides next; refused handshake shows server read no byte. Listeners close once `send`
##     ends, so send refused before any connection shows nothing read, never waits.
##     Cost: suite needs `openssl` command, which `system` of `tools/build.nim` declares; each
##     certificate holds one day from its making, as OpenSSL checks it against clock of machine.
##     Cost: `localhost` resolves through host file, so name lookup runs for it, and socket of
##     other process on `::1` at same port would answer first.
##     Cost: TLS needs `-d:ssl`, which stub gives; suite run alone without it skips TLS tests
##     (Article IX.9).
##   Samples are drawn into pools allocated once, after one seeding per test, and served by
##     `served`.

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[
  asyncdispatch, asynchttpserver, asyncnet, base64, net, options, os, osproc, random, sequtils,
  streams, strutils, tempfiles, unittest, uri,
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

  Shared = object  ## Define how sends sharing one deadline, and other waiters on it, ended.
    is_held: bool  ## Each server held its request while no send had ended.
    problems: seq[string]  ## Problem of each send once deadline completed; `unfinished` where none.
    count_called: int  ## Callbacks caller put on deadline that ran.
    is_awaited: bool  ## Coroutine of caller awaiting deadline ended.

  Leaf {.pure.} = enum  ## Define leaf certificate test root signs, by hosts it names.
    Both  ## Names `localhost` and `127.0.0.1`.
    Name  ## Names `localhost` alone.
    Address  ## Names `127.0.0.1` alone.
    Wrong  ## Names `wrong.example` alone, as leaf review found accepted.

  Authority = object  ## Define test root and leaves it signs, made at run time in fresh directory.
    directory: string  ## Directory holding keys and certificates; suite removes it at end.
    problem: string  ## Command that failed, with its output; empty where every one ran.
    client: SslContext  ## Context `send` takes: verifies peer against test root alone.
    servers: array[Leaf, SslContext]  ## Context of server presenting each leaf.

  Secured = object  ## Define what each side saw of one request sent with credential over TLS.
    port: int  ## Port server listened on, which URL names.
    sent: Sent  ## Outcome `send` gave.
    head: Head  ## Request server read; no line where handshake was refused or none connected.
    connect: seq[string]  ## Head proxy read where tunnel carried request; else none.


const
  SAMPLES_STAMPS = 500  ## Random requests each stamp law is checked over.
  SAMPLES_RECORDINGS = 300  ## Random recordings round trip is checked over.
  SAMPLES_CREDENTIALS = 400  ## Random values credential law is checked over, under each service.
  SAMPLES_BODIES = 20  ## Random bodies `send` is checked to carry byte for byte.
  SAMPLES_PORTS = 1_000  ## Random ports URL tests are checked over.
  FLOOR_CHANGED = 400  ## Fewest requests holding byte to change; 449 read at seed `0`.
  FLOOR_READ = 350  ## Fewest values read as credential, over every service; 446 read at seed `0`.
  FLOOR_REFUSED = 600  ## Fewest values refused, over every service; 754 read at seed `0`.
  FLOOR_FOLDED = 150  ## Fewest random labels holding line break; 197 read at seed `0`.
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
    "Recording should open with `" & HEADER_RECORDING & "`", "Line should be `label <text>`",
    "Line should be `request <bytes>`",
    "Request should hold bytes its line counts, then line break",
    "Line should be `status <code>`, one to three digits",
    "Line should be `content-type <value>`", "Line should be `content-encoding <value>`",
    "Line should be `location <value>`", "Line should be `body <whole|cut> <bytes>`",
    "Body should hold bytes its line counts, then line break",
  ]
    ## What reader says each piece should be; `problemExpected` adds what piece holds.
  PIECES_BLOCK = {Piece.RequestBytes, Piece.BodyBytes}
    ## Pieces holding block of bytes, whose problem names bytes left rather than line.
  PROBLEM_END = "Recording should end after body"
    ## What reader says at byte after body; problem adds text after body.
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
    @["", "+20", "2000", "2x0", "-20"], @[], @[], @[],
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
  ANSWER_ODD = "HTTP/1.1 099 Odd\r\ncontent-type: text/html;\r\n\tcharset=utf-8\r\n" &
      "location: /a\r\n /b\r\ncontent-length: 2\r\nconnection: close\r\n\r\nhi"
    ## Answer raw listener gives as found: status `099`, and header values folded.
  REPLY_ODD = Reply(
    status: 99,
    content_type: "text/html; charset=utf-8",
    location: "/a /b",
    body: "hi",
  )
    ## Reply `send` should read from `ANSWER_ODD`: each fold one space.
  FOLDS = [" ", "\t", " \t  "]  ## Spaces and tabs opening continuation line of folded header.
  URL_BASE = "http://a/b/c/d;p?q"  ## URL examples of RFC 3986 section 5.4 resolve against.
  SEGMENTS_DOT = ["", ".", "..", "g", "g.", ".g", "..g", ";x"]
    ## Path segments references are built from: empty, dot segments, and names dots stand in.
  COUNT_REFERENCES = 2_175
    ## References of one to three `SEGMENTS_DOT`: relative or absolute, with or without query and
    ##   fragment, but none empty and none opening with `//`, which names authority.
  CHARACTERS_CONTROL = {'\0'..'\x1F', '\x7F'}  ## Control characters of ASCII: C0 set and DEL.
  LUT_HOSTS_BY_LEAF: array[Leaf, seq[string]] = [
    @["localhost", "127.0.0.1"], @["localhost"], @["127.0.0.1"], @["wrong.example"],
  ]
    ## Hosts each leaf names as subject alternative names: address as `IP`, name as `DNS`.
  HOSTS_SECURED = ["localhost", "127.0.0.1"]  ## Hosts TLS requests here name: name, then address.
  HOSTS_DOTTED = [
    ".", "..", ".example", ".EXAMPLE", ".wrong.example", "..wrong.example", ".localhost",
    ".127.0.0.1",
  ]
    ## Hosts opening with dot: dot alone, two, parent of name leaf `Wrong` holds in two cases,
    ##   that name itself behind one dot and two, name of other leaves, and address.
  COUNT_DOTTED = 64
    ## Sends dot law makes: each of `HOSTS_DOTTED` with each leaf, directly and through tunnel.
  HOSTS_CLOSED = [
    ("localhost.", "localhost"), ("wrong.example.", "wrong.example"), ("localhost..", ""),
    ("wrong.example..", ""),
  ]
    ## Names closing with dot, beside name pin should hold: one dot dropped, as certificate names
    ##   host without it; of two, one kept, so no leaf names it.
  COUNT_CLOSED = 16  ## Sends closing law makes: each of `HOSTS_CLOSED` with each leaf.
  COUNT_SECURED = 256
    ## Sends TLS law makes: each of eight cases of leaf and host after each, two sends to pair,
    ##   directly and through tunnel.
  CONFIG_OPENSSL = "[req]\ndistinguished_name = name\n[name]\n"
    ## Configuration `openssl req` reads: bare but for what it demands, so no default of machine
    ##   adds extension.
  EXTENSIONS_LEAF = "basicConstraints = critical,CA:FALSE\n" &
      "keyUsage = critical,digitalSignature\nextendedKeyUsage = serverAuth\n"
    ## Extensions each leaf holds beside its names: no authority, and server of TLS alone.
  ANSWER_TUNNEL = "HTTP/1.1 200 Connection established\r\n\r\n"  ## Answer tunnel gives `CONNECT`.
  BYTES_RELAY = 4_096  ## Most bytes tunnel copies at once.
  PROBLEM_VERIFY = "certificate verify failed"  ## Text OpenSSL gives where peer fails check.
  PROBLEM_CONTEXT = "TLS context should exist for https URL; got ``."
    ## Problem `send` gives for https URL with no context.
  COUNT_SPELLINGS_HTTP = 16  ## Spellings of `http` in any case, i.e. 2^4.
  COUNT_SPELLINGS_HTTPS = 32  ## Spellings of `https` in any case, i.e. 2^5.
  PROBLEM_PROXY_HOST = "Proxy should name host after `//`; got ``."
    ## Problem `send` gives for proxy URL naming no host after `//`.
  SYMBOLS_USER = "!$&*+=~"
    ## Bytes user part of proxy URL here is spelled from: RFC 3986 takes each there, no problem
    ##   holds one, and `+` reads as scheme where `//` is absent.
  USERS_PROXY = [("+", "!$&*=~"), ("!$&*", "+=~"), ("~", "")]
    ## User and password each proxy URL of leak law holds: user of scheme characters alone, user
    ##   of other symbols, and password empty.
  OPENINGS_PROXY = ["http://", "HTTP://", "https://", "socks5h://", "//", ""]
    ## Openings of proxy URL before its user part: scheme `send` takes, in two cases; schemes it
    ##   refuses; none before `//`; and no `//`, so curl reads text as `user:password@host`.
  HOSTS_PROXY = ["127.0.0.1", ""]  ## Hosts of proxy URL: address, and none.
  PORTS_PROXY = [
    ("", true), ("0", false), ("1", true), ("00080", true), ("65535", true), ("65536", false),
    ("65616", false), ("70000", false), ("99999", false), ("000080", false), ("8a", false),
    ("-1", false),
  ]
    ## Ports of proxy URL at bounds of one to five digits from 1 to 65535, beside whether `send`
    ##   takes each: none, zero, five digits with zeros leading, past 65535, six digits, no digits.
  COUNT_PROXIES = 432
    ## Proxy URLs leak law sends: each of `OPENINGS_PROXY`, `HOSTS_PROXY`, `PORTS_PROXY` and
    ##   `USERS_PROXY` with each other.
  LOGINS_PROXY = [
    ("", "", ""), ("@", "", ""), (":@", "", ""), (":+=~@", "", "+=~"), ("!$&*@", "!$&*", ""),
    ("!$&*:@", "!$&*", ""), ("!$&*:+=~@", "!$&*", "+=~"),
  ]
    ## User part opening authority of proxy URL login law sends through, beside user and password
    ##   it holds: none, empty, empty pair, password alone, user alone, user with empty password,
    ##   and both; spelled from `SYMBOLS_USER`, so any byte leaking into problem shows.
  COUNT_LOGINS = 336
    ## Sends login law makes: each of `LOGINS_PROXY` with each spelling of `http` and `https`.
  OPENINGS_VALUE = ["", "http://", "HTTP://", "socks5h://"]
    ## Openings of proxy value port law reads: none, which `proxy` reads as `http://`, scheme in
    ##   two cases, and other scheme.
  USERS_VALUE = ["", "alice@", "alice:secret@", ":secret@", "a:b:c@"]
    ## User parts of proxy value: none, user, both, password alone, and password holding colon.
  HOSTS_VALUE = ["proxy.example", "203.0.113.7", "[2001:db8::7]"]
    ## Hosts of proxy value: name, IPv4 address, and IPv6 address, whose colons are no port.
  PORTS_VALUE = ["", ":", ":3128", ":1080", ":65535"]
    ## Ports of proxy value: none, empty, and three named, 1080 among them.
  CLOSINGS_VALUE = ["", "/"]  ## Closings of proxy value: none, and path.
  COUNT_VALUES = 600
    ## Proxy values port law reads: each of `OPENINGS_VALUE`, `USERS_VALUE`, `HOSTS_VALUE`,
    ##   `PORTS_VALUE` and `CLOSINGS_VALUE` with each other.
  PORT_CURL = "1080"
    ## Port curl assumes where proxy string specifies none (curl manual, option `--proxy`).


func lineFirst(piece: Piece): int =
  ## Count first line of piece in `PIECES_BASE`, from one.
  result = 1
  for before in Piece:
    if before < piece: result += PIECES_BASE[before].count('\n')


func problemExpected(piece: Piece, text: string): string =
  ## Build problem reader gives at piece of text: what piece should be, then what it holds, as
  ##   line made printable, empty where text ends before line break, or as bytes left of block.
  var opening = 0
  for _ in 1..<lineFirst(piece): opening = text.find('\n', opening) + 1
  if piece in PIECES_BLOCK:
    return LUT_PROBLEM_BY_PIECE[piece] & "; got `" & $(text.len - opening) & "` bytes left."
  let close = text.find('\n', opening)
  LUT_PROBLEM_BY_PIECE[piece] & "; got `" &
      (if close < 0: "" else: text[opening..<close].toPrintable(80)) & "`."


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
          if fault == Fault.Trailing:
            (lineFirst(piece) + own.count('\n'), PROBLEM_END & "; got `x`.")
          else: (lineFirst(at), problemExpected(at, text))
        result.add Malformed(
          piece: piece,
          fault: fault,
          at: at,
          text: text,
          line: line,
          problem: problem,
        )


func referencesDotted(): seq[string] =
  ## Build each reference of one to three `SEGMENTS_DOT` joined by `/`, relative or absolute,
  ##   with or without query and fragment holding dot segments; none empty, none opening `//`.
  var paths: seq[string]
  for a in SEGMENTS_DOT:
    paths.add a
    for b in SEGMENTS_DOT:
      paths.add a & "/" & b
      for c in SEGMENTS_DOT: paths.add a & "/" & b & "/" & c
  for path in paths:
    for opening in ["", "/"]:
      for closing in ["", "?y/../x#s/./x"]:
        let reference = opening & path & closing
        if reference.len > 0 and not reference.startsWith("//"): result.add reference


proc lineRandom(length_max: int): string =
  ## Draw bytes of one line: empty one time in four, else any byte but line break.
  if rand(3) == 0: return ""
  result = newString(rand(1..length_max))
  for character in result.mitems:
    let code = rand(254)
    character = char(if code >= ord('\n'): code + 1 else: code)


proc labelRandom(): string =
  ## Draw label: one to three lines of `lineRandom`, each line break followed by up to two spaces
  ##   or tabs, as folded header holds them.
  result = lineRandom(40)
  for _ in 1..rand(2):
    result.add '\n'
    for _ in 1..rand(2): result.add [' ', '\t'].sample
    result.add lineRandom(40)


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
  ## Draw recording: label of `labelRandom`, header values of any byte but line break, status of
  ##   one to three digits, request and body of any bytes, cut half time.
  Recording(
    label: labelRandom(),
    request: bytesRandom(),
    reply: Reply(
      status: rand(0..999),
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


proc poolPorts(): seq[string] =
  ## Draw `SAMPLES_PORTS` random ports into pool allocated once: number up to 999,999, under
  ##   70,000 half time, after up to two zeros; caller seeds first.
  result = newSeqOfCap[string](SAMPLES_PORTS)
  for _ in 1..SAMPLES_PORTS:
    let number = if rand(1) == 0: rand(70_000) else: rand(999_999)
    result.add "0".repeat(rand(2)) & $number


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


func problemHost(host: string): string =
  ## Build problem `send` gives for https URL whose host TLS cannot pin.
  "Host should be name or address TLS can pin; got `" & host & "`."


func outcome(sent: Sent): string =
  ## Read outcome of `send` as text: problem it gave, or `replied`, so check names either.
  if sent.is_replied: "replied" else: sent.problem


func isEchoing(problem: string): bool =
  ## Test problem has form Article IV.4 gives: what should be, then `; got`, ending in value in
  ##   backticks, empty backticks where value is absent, as `readCredential` writes it.
  let at = problem.find("; got ")
  at > 0 and " should " in problem[0..<at] and problem.endsWith("`.")


func problemProxy(scheme: string): string =
  ## Build problem `send` gives for proxy URL whose scheme is other than `http`.
  "Proxy should be `http://`; got `" & scheme & "`."


func problemProxyUser(host: string): string =
  ## Build problem `send` gives for https URL through proxy URL holding user or password: names
  ##   host of proxy, never its user part.
  "Proxy should hold no user part for https URL, since client repeats `Proxy-Authorization` " &
      "inside tunnel; got user part for `" & host & "`."


func problemProxyPort(port: string): string =
  ## Build problem `send` gives for proxy URL whose port client would read as other port.
  "Proxy should name port of one to five digits from 1 to 65535, or none; got `" & port & "`."


func spellingsCase(word: string): seq[string] =
  ## Build every spelling of word in any case, each letter lower or upper: 2^n for n letters.
  result = @[""]
  for character in word:
    var grown: seq[string]
    for spelled in result: grown.add @[spelled & character.toLowerAscii,
        spelled & character.toUpperAscii]
    result = grown


func casesSecured(): seq[tuple[leaf: Leaf, host: string, should_tunnel: bool]] =
  ## Build each leaf with each host of `HOSTS_SECURED`, every case after every case, directly
  ##   then through tunnel, so each ordered pair stands next to each other once in each way.
  var cases: seq[(Leaf, string)]
  for leaf in Leaf:
    for host in HOSTS_SECURED: cases.add (leaf, host)
  for should_tunnel in [false, true]:
    for (leaf_before, host_before) in cases:
      for (leaf, host) in cases:
        result.add @[(leaf_before, host_before, should_tunnel), (leaf, host, should_tunnel)]


func casesProxy(): seq[tuple[url, problem: string]] =
  ## Build proxy URL of each opening, host, port and user part with each other, beside outcome
  ##   `sendProxied` should give: first part failing of host, scheme, port and user part named,
  ##   user part failing for https URL `sendProxied` sends, as each of `USERS_PROXY` holds user.
  for opening in OPENINGS_PROXY:
    let scheme = if "://" in opening: opening[0..<opening.find("://")] else: ""
    for host in HOSTS_PROXY:
      for (port, is_taken) in PORTS_PROXY:
        let problem =
          if opening.len == 0 or host.len == 0: PROBLEM_PROXY_HOST
          elif scheme.toLowerAscii != "http": problemProxy(scheme)
          elif not is_taken: problemProxyPort(port)
          else: problemProxyUser(host)
        for (user, password) in USERS_PROXY:
          result.add (opening & user & ":" & password & "@" & host & ":" & port, problem)


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


proc listenRaw(is_buffered = true): AsyncSocket =
  ## Open listener of `std/asyncnet` on `127.0.0.1` at port system chooses; connection it accepts
  ##   unbuffered gives each read what arrived, where buffered one waits for every byte asked.
  result = newAsyncSocket(buffered = is_buffered)
  result.setSockOpt(OptReuseAddr, true)
  result.bindAddr(Port(0), "127.0.0.1")
  result.listen()


proc readHead(
  listener: AsyncSocket, answer: string = ANSWER_RAW, context: SslContext = nil
): Future[Head] {.async.} =
  ## Accept one connection, as server of TLS where `context` is given, read its request byte for
  ##   byte, give it `answer`, then close; connection ending before any line, as refused
  ##   handshake ends it, gets no answer.
  let client = await listener.accept()
  when defined(ssl):
    if not context.isNil: context.wrapConnectedSocket(client, handshakeAsServer)
  var head: Head
  while true:
    let line = await client.recvLine()
    if line in ["", "\r\n"]: break
    head.lines.add line
  if head.lines.len > 0:
    let lengths = head.values("content-length")
    if lengths.len > 0: head.body = await client.recv(lengths[0].parseInt)
    await client.send(answer)
  client.close()
  return head


proc readHeads(listener: AsyncSocket): Future[seq[Head]] {.async.} =
  ## Read head of each connection listener accepts, one at time, answering each `ANSWER_RAW`,
  ##   until listener closes; give heads in order, so count shows each connection.
  var heads: seq[Head]
  while true:
    try:
      heads.add await listener.readHead
    except CatchableError:
      return heads


proc relay(source, sink: AsyncSocket) {.async.} =
  ## Copy bytes from source to sink until source ends, or either side fails as tunnel closes it.
  while true:
    var data = ""
    try:
      data = await source.recv(BYTES_RELAY)
      if data.len > 0: await sink.send(data)
    except CatchableError:
      return
    if data.len == 0: return


proc tunnel(listener: AsyncSocket): Future[seq[string]] {.async.} =
  ## Accept one connection of unbuffered listener and read its head; for `CONNECT`, connect to
  ##   `127.0.0.1` at port it names, whatever host it names, answer `200`, and relay bytes both
  ##   ways until either way ends; for other request, as proxy takes http URL, read body
  ##   `content-length` names and answer `ANSWER_RAW`; give head read.
  let client = await listener.accept()
  var lines: seq[string]
  while true:
    let line = await client.recvLine()
    if line in ["", "\r\n"]: break
    lines.add line
  if lines.len == 0:
    client.close()
    return lines
  if not lines[0].startsWith("CONNECT "):
    let lengths = Head(lines: lines).values("content-length")
    var body = ""
    while lengths.len > 0 and body.len < lengths[0].parseInt:
      let data = await client.recv(lengths[0].parseInt - body.len)
      if data.len == 0: break
      body.add data
    await client.send(ANSWER_RAW)
    client.close()
    return lines
  let
    port = lines[0].split(' ')[1].rsplit(':', maxsplit = 1)[^1].parseInt
    upstream = await asyncnet.dial("127.0.0.1", Port(port), buffered = false)
    ended = newFuture[void]("ended")
  await client.send(ANSWER_TUNNEL)
  for relaying in [relay(client, upstream), relay(upstream, client)]:
    relaying.addCallback proc() =
      if not ended.finished: ended.complete()
  await ended
  client.close()
  upstream.close()
  return lines


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


proc socketRefusing(): AsyncSocket =
  ## Bind socket on `127.0.0.1` at port system chooses, never listening and never reused, so its
  ##   port refuses each connection, and no other socket takes port, until caller closes it.
  result = newAsyncSocket()
  result.bindAddr(Port(0), "127.0.0.1")


proc awaitDeadline(deadline: Future[void]) {.async.} =
  ## Await deadline, as coroutine of caller beside `send` does.
  await deadline


proc sendSharing(count: int): Shared =
  ## Hold `count` sends, each at server of its own, sharing one deadline with waiters of caller:
  ##   callback put on it before sends, callback put on it after them, and coroutine awaiting it;
  ##   then complete deadline, and run callbacks it queues once.
  let deadline = newFuture[void]("deadline")
  var
    servers: seq[Server]
    sendings: seq[Future[Sent]]
    count_called = 0
  deadline.addCallback proc() = inc count_called
  for _ in 1..count:
    servers.add startServer()
    sendings.add send(
      urlLoopback(servers[^1].port, "/held"),
      "{}",
      @[],
      CREDENTIAL_GIVEN,
      none(string),
      nil,
      BYTES_CAP,
      deadline,
    )
  deadline.addCallback proc() = inc count_called
  let awaiting = awaitDeadline(deadline)
  while not (servers.allIt(it.held.finished) or sendings.anyIt(it.finished)): poll()
  result.is_held = servers.allIt(it.held.finished) and not sendings.anyIt(it.finished)
  deadline.complete()
  poll()  # run callbacks completed deadline queued
  for sending in sendings:
    result.problems.add(
      if not sending.finished: "unfinished"
      elif sending.read.is_replied: "replied"
      else: sending.read.problem
    )
  (result.count_called, result.is_awaited) = (count_called, awaiting.finished)
  for server in servers: stopServer(server)


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


when defined(ssl):
  proc makeAuthority(): Authority =
    ## Make test root and each leaf it signs, by `openssl` in fresh directory at run time, so no
    ##   key is committed: keys on curve P-256, each certificate valid one day; first command
    ##   that fails names problem, and no context is made.

    proc run(directory: string, arguments: seq[string]): string =
      ## Run `openssl` in directory with arguments as list, so no shell reads them; command and
      ##   output where it fails, else empty.
      try:
        let process = startProcess(
          "openssl",
          workingDir = directory,
          args = arguments,
          options = {poStdErrToStdOut, poUsePath},
        )
        let
          output = process.outputStream.readAll
          code = process.waitForExit
        process.close()
        if code != 0: result = "openssl " & arguments.join(" ") & ": " & output
      except OSError as error:
        result = "Command `openssl` should run; got `" & error.msg & "`."

    result.directory = createTempDir("lojban_tagger_tls_", "")
    writeFile(result.directory / "openssl.cnf", CONFIG_OPENSSL)
    var commands = @[
      @["genpkey", "-algorithm", "EC", "-pkeyopt", "ec_paramgen_curve:prime256v1", "-out",
          "root.key"],
      @["req", "-config", "openssl.cnf", "-x509", "-new", "-key", "root.key", "-sha256",
          "-days", "1", "-subj", "/CN=lojban_tagger test root", "-addext",
          "basicConstraints=critical,CA:TRUE", "-addext", "keyUsage=critical,keyCertSign",
          "-out", "root.crt"],
    ]
    for leaf in Leaf:
      let
        name = $leaf
        names = LUT_HOSTS_BY_LEAF[leaf].mapIt((if it.isIpAddress: "IP:" else: "DNS:") & it)
      writeFile(result.directory / (name & ".ext"),
          "subjectAltName = " & names.join(",") & "\n" & EXTENSIONS_LEAF)
      commands.add @["genpkey", "-algorithm", "EC", "-pkeyopt", "ec_paramgen_curve:prime256v1",
          "-out", name & ".key"]
      commands.add @["req", "-config", "openssl.cnf", "-new", "-key", name & ".key", "-subj",
          "/CN=lojban_tagger test leaf", "-out", name & ".csr"]
      commands.add @["x509", "-req", "-in", name & ".csr", "-CA", "root.crt", "-CAkey",
          "root.key", "-set_serial", $(ord(leaf) + 2), "-days", "1", "-sha256", "-extfile",
          name & ".ext", "-out", name & ".crt"]
    for command in commands:
      result.problem = run(result.directory, command)
      if result.problem.len > 0: return
    result.client = newContext(verifyMode = CVerifyPeer, caFile = result.directory / "root.crt")
    for leaf in Leaf:
      result.servers[leaf] = newContext(
        verifyMode = CVerifyNone,
        certFile = result.directory / ($leaf & ".crt"),
        keyFile = result.directory / ($leaf & ".key"),
      )


  proc sendSecured(
    authority: Authority,
    leaf: Leaf,
    host: string,
    should_tunnel = false,
    scheme = "https",
    user_part = "",
  ): Secured =
    ## Send request with credential to server presenting `leaf` at `<scheme>://<host>:<port>`,
    ##   directly or through tunnel of `CONNECT` proxy whose URL opens authority with `user_part`,
    ##   by context every call shares; close listeners once `send` ends, then drive loop until
    ##   server and tunnel end.
    ##   Server and tunnel accept before `send` ends, as handshake and tunnel need them, or
    ##     never: closing listener fails accept still waiting, which reads as nothing read, so
    ##     refusal before any connection ends red, never waiting on connection that never comes.
    let listener = listenRaw()
    result.port = int(listener.getLocalAddr[1])
    let
      url = scheme & "://" & host & ":" & $result.port & "/v1/messages"
      reading = listener.readHead(context = authority.servers[leaf])
    var
      proxy: AsyncSocket
      tunnelling: Future[seq[string]]
      proxy_url = none(string)
    if should_tunnel:
      proxy = listenRaw(is_buffered = false)
      tunnelling = proxy.tunnel
      proxy_url = some("http://" & user_part & "127.0.0.1:" & $int(proxy.getLocalAddr[1]))
    result.sent = waitFor send(
      url,
      "{}",
      @[],
      CREDENTIAL_GIVEN,
      proxy_url,
      authority.client,
      BYTES_CAP,
      newFuture[void]("deadline"),
    )
    listener.close()
    if should_tunnel: proxy.close()
    try: result.head = waitFor reading
    except CatchableError: discard  # Accept failed as listener closed: server read nothing.
    if should_tunnel:
      try: result.connect = waitFor tunnelling
      except CatchableError: discard  # Accept failed as proxy closed: proxy read nothing.


  proc sendProxied(proxy_url: string): Sent =
    ## Send request with credential to https URL through `proxy_url`, with no TLS context, so
    ##   proxy `send` takes meets pin, which refuses for want of context, and no socket opens.
    waitFor send(
      "https://api.example.test/v1/messages",
      "{}",
      @[],
      CREDENTIAL_GIVEN,
      some(proxy_url),
      nil,
      BYTES_CAP,
      newFuture[void]("deadline"),
    )



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


  test "recording reads back as written, request and body of any bytes, label on one line":
    # Regression, found in review: `toText` wrote label holding line break, and status of two
    #   digits, each of which `readRecording` refused.
    let
      folded = Recording(label: "a\nb", reply: Reply(status: 200)).toText.readRecording
      short = Recording(reply: Reply(status: 99)).toText.readRecording
    check folded.is_read and folded.recording.label == "a b"  # case as found: one line
    check short.is_read and short.recording.reply.status == 99  # case as found: two digits
    randomize(0)
    let pool = poolRecordings()
    var count_folded = 0
    for recording in served(pool):
      let
        text = recording.toText
        recorded = text.readRecording
      check text.startsWith(HEADER_RECORDING & "\n")  # format and version open file
      check recorded.is_read  # domain: file of any recording reads
      if not recorded.is_read:
        checkpoint $recorded.line & ": " & recorded.problem
        continue
      let back = recorded.recording
      check back.request == recording.request  # domain: request back, byte for byte
      check back.reply == recording.reply  # domain: reply back, byte for byte
      check '\n' notin back.label and back.toText == text  # domain: label as written, one line
      if '\n' in recording.label: inc count_folded
      else: check back.label == recording.label  # domain: label of one line back as it was
    check count_folded >= FLOOR_FOLDED  # guard leaves enough labels holding line break
    for status in 0..999:
      let
        recorded = Recording(reply: Reply(status: status)).toText.readRecording
        named = $status & ": "
      check named & $recorded.is_read == named & "true"  # domain: one to three digits read
      if recorded.is_read:
        check recorded.recording.reply.status == status  # domain: status back as written


  test "malformed recording is refused naming its first faulty piece, each piece with each fault":
    check RECORDING_BASE.toText == PIECES_BASE.join  # file holds pieces in order format names
    check RECORDING_BASE.toText.readRecording.is_read  # whole file reads, so fault alone refuses
    # Regression, found in review: reader named line after faulty line it had read whole.
    check readRecording("lojban_tagger recording 1\nLabel x\n").line == 2  # case as found: was 3
    check readRecording("Lojban_tagger recording 1\n").line == 1  # case as found: was 2
    # Regression, found in review: refusal named shape alone, so edited line, and carriage
    #   return after status, stayed hidden.
    let
      labelled = readRecording(HEADER_RECORDING & "\nLabel secret-looking text\n")
      returned = readRecording(PIECES_BASE[Piece.Header..Piece.RequestBytes].join &
          "status 200\r\n")
    check not labelled.is_read and labelled.problem == "Line should be `label <text>`; got " &
        "`Label secret-looking text`."  # case as found: review finding rules-3, 2026-10-29
    check not returned.is_read and returned.problem == "Line should be `status <code>`, one " &
        "to three digits; got `status 200\\u{D}`."  # case as found: carriage return shown
    let cases = casesMalformed()
    var (pieces, faults) = (default(set[Piece]), default(set[Fault]))
    for malformed in cases:
      let
        recorded = malformed.text.readRecording
        named = $malformed.piece & " " & $malformed.fault & ": "
      check not recorded.is_read  # refused
      if recorded.is_read: continue
      check named & recorded.problem == named & malformed.problem  # what faulty line should be
      check named & $recorded.line == named & $malformed.line  # domain: faulty line, from one
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


  test "URL names port of one to five digits from 1 to 65535, or none, wherever it is read":
    # Regression, found in review: client reads port modulo 65536, so `:65616` reached port 80.
    for (port, expected) in [
      ("", true),  # RFC 3986 3.2.3: empty port is default of scheme
      ("0", false),  # port zero reaches no service
      ("1", true),
      ("00080", true),  # five digits, zeros leading
      ("65535", true),  # largest of sixteen bits
      ("65536", false),  # would wrap to 0
      ("65616", false),  # would wrap to 80
      ("110103", false),  # case as found: review finding logic-8, 2026-10-29, reached 44567
      ("99999", false),
      ("000080", false),  # six digits
      ("8a", false),  # digits alone
      ("-1", false),
    ]:
      for url in ["http://127.0.0.1:" & port & "/page", "https://example.org:" & port & "/page"]:
        let named = url & ": "
        check named & $url.isURL == named & $expected  # RFC 6335 6: port of 16 bits, 0 reserved
        check named & $url.isEndpoint == named & $expected  # endpoint holds same port
        check named & $"http://127.0.0.1/a".redirect(Reply(status: 302, location: url)).isSome ==
            named & $expected  # redirect target holds same port
    randomize(0)
    let pool = poolPorts()
    for port in served(pool):
      let
        url = "https://example.org:" & port & "/page"
        is_port = port.len <= 5 and port.parseInt in 1..65_535
        named = port & ": "
      check named & $url.isURL == named & $is_port  # domain: RFC 6335 6
      check named & $url.isEndpoint == named & $is_port  # domain: endpoint holds same port
      check named & $"http://127.0.0.1/a".redirect(Reply(status: 302, location: url)).isSome ==
          named & $is_port  # domain: redirect target holds same port


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


  test "proxy value naming no port takes 1080, as curl assumes, whatever else value holds":
    # Regression, found in recheck of transport, 2026-10-29: header says proxy follows curl, which
    #   assumes port 1080 where value names none, yet client dialed 80 for such value.
    let found = "https://api.example.org/v1".proxy(@[("https_proxy", "proxy.example")])
    check found == some("http://proxy.example:1080")  # case as found: was `http://proxy.example`
    check found.isSome and found.get.parseUri.port == PORT_CURL  # case as found: client read ``
    var count = 0
    for opening in OPENINGS_VALUE:
      for user_part in USERS_VALUE:
        for host in HOSTS_VALUE:
          for port in PORTS_VALUE:
            for closing in CLOSINGS_VALUE:
              let
                value = opening & user_part & host & port & closing
                port_dialed = if port.len <= 1: PORT_CURL else: port[1 .. ^1]
                scheme = if opening.len > 0: opening else: "http://"
                expected = scheme & user_part & host & ":" & port_dialed & closing
                chosen = "https://api.example.org/v1".proxy(@[("https_proxy", value)])
                named = value & ": "
              inc count
              check named & $chosen == named & $some(expected)  # domain: curl manual, `--proxy`
              if chosen.isSome:
                check named & chosen.get.parseUri.port ==
                    named & port_dialed  # domain: port client dials, as it reads value
    check count == COUNT_VALUES  # each opening, user part, host, port and closing with each other


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
      (".", "http://a/b/c/"),  # case as found in review: was `http://a/b/c/.`
      ("./", "http://a/b/c/"),
      ("..", "http://a/b/"),  # case as found: was `http://a/b/c/..`
      ("../", "http://a/b/"),
      ("../g", "http://a/b/g"),
      ("../..", "http://a/"),  # case as found: was `http://a/b/..`
      ("../../", "http://a/"),
      ("../../g", "http://a/g"),  # last of normal examples, 5.4.1
      ("../../../g", "http://a/g"),  # first of abnormal examples, 5.4.2
      ("../../../../g", "http://a/g"),  # case as found: was `http://a/.g`
      ("/./g", "http://a/g"),
      ("/../g", "http://a/g"),
      ("g.", "http://a/b/c/g."),
      (".g", "http://a/b/c/.g"),
      ("g..", "http://a/b/c/g.."),
      ("..g", "http://a/b/c/..g"),
      ("./../g", "http://a/b/g"),
      ("./g/.", "http://a/b/c/g/"),  # case as found: was `http://a/b/c/g/.`
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


  test "redirect removes dot segments of any path, and resolves its own target to itself":
    # Regression, found in review: `combine` of `std/uri` kept dot segments that end path, as `.`
    #   and `..`, and gave `http://a/.g` for `../../../../g`.
    let references = referencesDotted()
    check references.len == COUNT_REFERENCES  # guard leaves every reference but `//` and empty
    for reference in references:
      let
        target = URL_BASE.redirect(Reply(status: 302, location: reference))
        named = reference & ": "
      check named & $target.isSome == named & "true"  # domain: path reference resolves
      if target.isNone: continue
      let segments = target.get.parseUri.path.split('/')
      check named & $segments.filterIt(it in [".", ".."]) == named & "@[]"  # domain: removed
      check named & $URL_BASE.redirect(Reply(status: 302, location: target.get)) ==
          named & $target  # domain: target resolves to itself
      if reference[0] notin {'/', '?', '#'}:
        check named & $URL_BASE.redirect(Reply(status: 302, location: "./" & reference)) ==
            named & $target  # domain: `./` before relative path names same place


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
      (URL_BASE, "http:g", none(string)),  # RFC 3986 5.4.2, strict: scheme kept, so no host
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


  test "redirect gives target with scheme lowercased, whatever case location or URL spells":
    # Regression, found in review: target kept `HTTPS` of location, which client read as no https.
    let
      location_found = "HTTPS://cdn.example/b"
      found = "https://public.example/a".redirect(Reply(status: 302, location: location_found))
    check found ==
        some("https://cdn.example/b")  # case as found: review finding security-2, 2026-10-29
    for spelled in spellingsCase("http") & spellingsCase("https"):
      let
        (lowered, named) = (spelled.toLowerAscii, spelled & ": ")
        location = spelled & "://cdn.example/b"
        moved = "http://public.example/a".redirect(Reply(status: 302, location: location))
        kept = (spelled & "://public.example/a").redirect(Reply(status: 302, location: "/b"))
      check named & $moved ==
          named & $some(lowered & "://cdn.example/b")  # domain: RFC 3986 6.2.2.1, location's
      check named & $kept ==
          named & $some(lowered & "://public.example/b")  # domain: RFC 3986 6.2.2.1, URL's


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
  when defined(ssl):
    let authority = makeAuthority()


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


  test "agent of tool replaces agent caller names, in any spelling and any count":
    # Regression, found in review: caller header `User-Agent: decoy` replaced `USER_AGENT`.
    let
      listener = listenRaw()
      url = urlLoopback(int(listener.getLocalAddr[1]), "/page")
      reading_found = listener.readHead
      found = sendLoopback(url, "", @[("User-Agent", "decoy")])
    check found.is_replied  # answered
    if found.is_replied:
      let head = waitFor reading_found
      check head.values("user-agent") == @[USER_AGENT]  # case as found: was `decoy`
    for decoys in [
      @[("user-agent", "decoy")], @[("USER-AGENT", "decoy")], @[("uSeR-aGeNt", "decoy")],
      @[("User-Agent", "a"), ("user-agent", "b")],
    ]:
      for body in ["", "{}"]:
        let
          reading = listener.readHead
          sent = sendLoopback(url, body, decoys, CREDENTIAL_GIVEN)
          named = $decoys & " " & body & ": "
        check sent.is_replied  # answered
        if not sent.is_replied: continue
        let head = waitFor reading
        check named & $head.values("user-agent") ==
            named & $(@[USER_AGENT])  # domain: one agent, tool's own
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


  test "deadline shared with other waiters ends each send, and wakes each other waiter":
    # Regression, found in review: `or` in `send` cleared callbacks put on deadline before it,
    #   so of two sends sharing one deadline, first never ended.
    let found = sendSharing(2)
    check found.is_held  # case as found: two requests held
    check found.problems == @["deadline passed", "deadline passed"]  # case as found: both end
    for count in 1..3:
      let shared = sendSharing(count)
      check shared.is_held  # each request held until deadline
      check shared.problems == newSeqWith(count, "deadline passed")  # domain: each send ends
      check shared.count_called == 2  # domain: callbacks before and after sends both ran
      check shared.is_awaited  # domain: coroutine awaiting deadline ended


  test "deadline finished before send sends nothing, whether completed or failed":
    # Regression, found in review: `send` gave `deadline passed`, yet its request went out later
    #   on same loop, since closing client still connecting closes nothing.
    let
      server = startServer()
      deadline_early = newFuture[void]("deadline")
    deadline_early.complete()
    let early = waitFor send(
      urlLoopback(server.port, "/early"),
      "",
      @[],
      none(Credential),
      none(string),
      nil,
      BYTES_CAP,
      deadline_early,
    )
    check not early.is_replied and early.problem == "deadline passed"  # case as found
    for is_failed in [false, true]:
      for (body, credential) in [("", none(Credential)), ("{}", CREDENTIAL_GIVEN)]:
        let deadline = newFuture[void]("deadline")
        if is_failed: deadline.fail(newException(IOError, "deadline failed"))
        else: deadline.complete()
        let sent = waitFor send(
          urlLoopback(server.port, "/early"),
          body,
          @[],
          credential,
          none(string),
          nil,
          BYTES_CAP,
          deadline,
        )
        check not sent.is_replied and sent.problem == "deadline passed"  # domain: named
    let control = sendLoopback(urlLoopback(server.port, "/control"), "")
    check control.is_replied and server.targets == @["/control"]  # domain: nothing went out
    check server.count_connections == 1  # domain: no connection but control's
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


  test "proxy whose scheme is other than `http`, in any case, is refused before client exists":
    # Regression, found in review: http URL through `https://` proxy made client open TLS to
    #   proxy on nil context, so program ended with `SIGSEGV`.
    let
      server = startServer()
      found = sendLoopback(
        "http://example.org/page",
        "",
        proxy_url = some("https://127.0.0.1:" & $server.port),
      )
    check found.outcome ==
        problemProxy("https")  # case as found: review finding logic-2, 2026-10-29
    check spellingsCase("http").len == COUNT_SPELLINGS_HTTP  # every spelling of `http`
    check spellingsCase("https").len == COUNT_SPELLINGS_HTTPS  # every spelling of `https`
    for scheme in spellingsCase("http") & spellingsCase("https") & @["socks5", "socks5h"]:
      let
        proxy_url = some(scheme & "://127.0.0.1:" & $server.port)
        named = scheme & ": "
      if scheme.toLowerAscii == "http":
        let sent = sendLoopback("http://example.org/page", "", proxy_url = proxy_url)
        check named & sent.outcome == named & "replied"  # domain: RFC 3986 3.1, scheme in any case
        continue
      for url in ["http://example.org/page", "https://example.org/page"]:
        let
          sent = sendLoopback(url, "{}", credential = CREDENTIAL_GIVEN, proxy_url = proxy_url)
          named_url = named & url & ": "
        check named_url & sent.outcome ==
            named_url & problemProxy(scheme)  # domain: no proxy but `http`, scheme named
    check server.targets ==
        newSeqWith(COUNT_SPELLINGS_HTTP, "http://example.org/page")  # domain: refused sent nothing
    check server.count_connections == COUNT_SPELLINGS_HTTP  # domain: no connection but accepted
    stopServer(server)


  test "proxy port past 65535 is refused naming it, and port it would wrap onto hears nothing":
    # Regression, found in review: client reads port of proxy modulo 65536, as it reads port of
    #   URL, so proxy named at `P + 65536` was reached at `P`.
    let
      server = startServer()
      wrapped = $(server.port + 65_536)
      found = sendLoopback(
        "http://example.org/page",
        "",
        proxy_url = some("http://127.0.0.1:" & wrapped),
      )
    check found.outcome ==
        problemProxyPort(wrapped)  # case as found: review finding logic-8, 2026-10-29
    check server.targets.len == 0  # case as found: was reached at port it wraps onto
    for port in [
      "0", "65536", $(server.port + 2 * 65_536), "0" & $server.port, "00" & $server.port,
    ]:
      let sent = sendLoopback(
        "http://example.org/page",
        "",
        proxy_url = some("http://127.0.0.1:" & port),
      )
      check port & ": " & sent.outcome ==
          port & ": " & problemProxyPort(port)  # domain: RFC 6335 6, each wraps onto 0 or `P`
    let
      (user, password) = USERS_PROXY[0]
      control = sendLoopback(
        "http://example.org/page",
        "",
        proxy_url = some("http://" & user & ":" & password & "@127.0.0.1:" & $server.port),
      )
    check control.outcome == "replied"  # port of five digits taken, user part beside it
    check server.targets == @["http://example.org/page"]  # domain: refused proxy reached nothing
    check server.count_connections == 1  # domain: no connection but control's
    stopServer(server)


  test "proxy port of one to five digits from 1 to 65535, or none, is taken, and no other":
    when not defined(ssl): skip()  # Article IX.9: proxy taken meets pin, which needs `-d:ssl`
    else:
      for (port, is_taken) in PORTS_PROXY:
        let
          sent = sendProxied("http://127.0.0.1:" & port)
          expected = if is_taken: PROBLEM_CONTEXT else: problemProxyPort(port)
          named = port & ": "
        check named & sent.outcome == named & expected  # RFC 6335 6: port of 16 bits, 0 reserved
      randomize(0)
      let pool = poolPorts()
      for port in served(pool):
        let
          is_taken = port.len <= 5 and port.parseInt in 1..65_535
          sent = sendProxied("http://127.0.0.1:" & port)
          expected = if is_taken: PROBLEM_CONTEXT else: problemProxyPort(port)
          named = port & ": "
        check named & sent.outcome == named & expected  # domain: RFC 6335 6
      check authority.problem == ""  # `openssl` made root and leaves
      let tunnelled = authority.sendSecured(Leaf.Both, "localhost", should_tunnel = true)
      check tunnelled.sent.outcome == "replied"  # proxy taken still tunnels
      check tunnelled.connect.filterIt(it.startsWith("CONNECT ")) ==
          @["CONNECT localhost:" & $tunnelled.port & " HTTP/1.1"]  # RFC 9110 9.3.6, tunnel


  test "proxy refusal names host, scheme, port or user part, first failing, never its user part":
    when not defined(ssl): skip()  # Article IX.9: proxy taken meets pin, which needs `-d:ssl`
    else:
      let found = sendProxied("alice:secret@127.0.0.1:3128")
      check found.outcome ==
          PROBLEM_PROXY_HOST  # case as found fixing review finding logic-8, 2026-10-29
      check "alice" notin found.outcome and
          "secret" notin found.outcome  # case as found: `alice`, user as curl reads it, echoed
      let cases = casesProxy()
      check cases.len == COUNT_PROXIES  # each opening, host, port and user part with each other
      for (url, problem) in cases:
        let
          sent = sendProxied(url)
          named = url & ": "
        check named & sent.outcome == named & problem  # domain: host, scheme, port, user part
        check named & $sent.outcome.anyIt(it in SYMBOLS_USER) ==
            named & "false"  # domain: no byte of user part, as curl reads `user:password@host`


  test "proxy holding user or password is refused for https URL, so login never enters tunnel":
    # Regression, found in recheck claim regressions-app-7, 2026-10-29: client of
    #   `std/httpclient` writes `Proxy-Authorization` on each request it builds, so request
    #   inside tunnel took proxy login to service and page.
    when not defined(ssl): skip()  # Article IX.9: TLS needs `-d:ssl`, which stub gives
    else:
      check authority.problem == ""  # `openssl` made root and leaves
      let found = authority.sendSecured(
        Leaf.Both,
        "localhost",
        should_tunnel = true,
        user_part = "alice:proxy-s3cret@",
      )
      check $found.head.values("proxy-authorization") ==
          "@[]"  # case as found: server read `Basic YWxpY2U6cHJveHktczNjcmV0`, proxy login
      check found.sent.outcome == problemProxyUser("127.0.0.1")  # case as found: refused
      check found.connect.len == 0  # case as found: proxy read nothing
      check "alice" notin found.sent.outcome and
          "proxy-s3cret" notin found.sent.outcome  # case as found: no byte of login
      var count = 0
      for (user_part, user, password) in LOGINS_PROXY:
        let is_login = user.len > 0 or password.len > 0
        for scheme in spellingsCase("https") & spellingsCase("http"):
          let
            secured = authority.sendSecured(
              Leaf.Both,
              "localhost",
              should_tunnel = true,
              scheme = scheme,
              user_part = user_part,
            )
            is_secured = scheme.toLowerAscii == "https"
            proxied = Head(lines: secured.connect)
            named = scheme & " " & user_part & ": "
          inc count
          check named & $secured.head.values("proxy-authorization") ==
              named & "@[]"  # domain: server never reads login of proxy
          check named & $secured.sent.outcome.anyIt(it in SYMBOLS_USER) ==
              named & "false"  # domain: no byte of user part
          if is_secured and is_login:
            check named & secured.sent.outcome ==
                named & problemProxyUser("127.0.0.1")  # domain: refused before client exists
            check named & $secured.connect.len == named & "0"  # domain: proxy read nothing
            continue
          check named & secured.sent.outcome == named & "replied"  # domain: rest taken
          if is_secured:
            check named & $proxied.values("proxy-authorization") ==
                named & "@[]"  # domain: no login, so none at proxy either
            continue
          let logins = if user.len > 0: @["Basic " & encode(user & ":" & password)] else: @[]
          check named & $proxied.values("proxy-authorization") ==
              named & $logins  # domain: http keeps login, which proxy itself reads
      check count == COUNT_LOGINS  # each user part with each spelling of `http` and `https`


  test "https URL in any case opens tunnel through proxy, so proxy never sees credential":
    # Regression, found in review: client compares scheme with case, so `HTTPS://` endpoint sent
    #   whole request, bearer included, to proxy in clear.
    when not defined(ssl): skip()  # Article IX.9: TLS needs `-d:ssl`, which stub gives
    else:
      check authority.problem == ""  # `openssl` made root and leaves
      let
        proxy = listenRaw()
        proxy_url = some(urlLoopback(int(proxy.getLocalAddr[1]), ""))
        reading = proxy.readHeads
        urls = @["HTTPS://api.example.test/v1/messages"] &
            spellingsCase("https").mapIt(it & "://api.example.test/v1/messages")
      for url in urls:
        discard waitFor send(
          url,
          "{}",
          @[],
          CREDENTIAL_GIVEN,
          proxy_url,
          authority.client,
          BYTES_CAP,
          newFuture[void]("deadline"),
        )
      proxy.close()
      let heads = waitFor reading
      check heads.len == COUNT_SPELLINGS_HTTPS + 1  # one connection to proxy each
      for (url, head) in zip(urls, heads):
        let
          first = if head.lines.len > 0: head.lines[0] else: ""
          named = url & ": "
        check named & first ==
            named & "CONNECT api.example.test:443 HTTP/1.1"  # case as found, then domain: RFC 9110
        check named & $head.values("authorization") ==
            named & "@[]"  # case as found, then domain: credential never to proxy


  test "http URL in any case is served, direct, in origin form":
    let server = startServer()
    for spelled in spellingsCase("http"):
      let sent = sendLoopback(spelled & "://127.0.0.1:" & $server.port & "/count", "")
      check spelled & ": " & sent.outcome == spelled & ": replied"  # RFC 3986 3.1, any case
    check server.targets ==
        newSeqWith(COUNT_SPELLINGS_HTTP, "/count")  # RFC 9112 3.2.1, origin form each time
    stopServer(server)


  test "closed port gives problem of one line, holding no credential":
    let
      refusing = socketRefusing()
      sent = sendLoopback(
        urlLoopback(int(refusing.getLocalAddr[1]), "/v1/messages"),
        "{\"a\":1}",
        credential = CREDENTIAL_GIVEN,
      )
    check not sent.is_replied  # no reply
    if not sent.is_replied:
      check sent.problem.len > 0 and '\n' notin sent.problem  # first line of error alone
      check CREDENTIAL_SUITE notin sent.problem  # credential never in problem
    refusing.close()


  test "folded header comes back on one line, and recording of reply reads back as sent":
    # Regression, found in review: folded `content-type` and status `099` gave reply whose
    #   recording `readRecording` refused, so replay refused file record mode wrote.
    let
      listener = listenRaw()
      url = urlLoopback(int(listener.getLocalAddr[1]), "/odd")
      reading_odd = listener.readHead(ANSWER_ODD)
      odd = sendLoopback(url, "")
    discard waitFor reading_odd
    check odd.is_replied and odd.reply == REPLY_ODD  # case as found: one line, status 99
    if odd.is_replied:
      let
        recording = Recording(label: "recorded", request: "GET " & url, reply: odd.reply)
        recorded = recording.toText.readRecording
      check recorded.is_read and recorded.recording == recording  # case as found: reads back
    for fold in FOLDS:
      for count in 1..3:
        let
          value = "a" & ("\r\n" & fold & "b").repeat(count)
          answer = "HTTP/1.1 200 OK\r\ncontent-type: " & value & "\r\ncontent-encoding: " &
              value & "\r\nlocation: " & value & "\r\ncontent-length: 0\r\n\r\n"
          reading = listener.readHead(answer)
          sent = sendLoopback(url, "")
          unfolded = "a" & " b".repeat(count)
          named = fold.escape & " " & $count & ": "
        discard waitFor reading
        check sent.is_replied  # answered
        if not sent.is_replied: continue
        check named & sent.reply.content_type == named & unfolded  # domain: each fold one space
        check named & sent.reply.content_encoding == named & unfolded  # domain: every header
        check named & sent.reply.location == named & unfolded  # domain: location too
    listener.close()


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


  test "TLS refuses leaf naming other host before request leaves, directly and through tunnel":
    # Regression, found in review: client sets host for SNI alone, so leaf naming `wrong.example`
    #   alone received bearer at `https://localhost:P/v1/messages`, and so did proxy ending tunnel
    #   for `api.example.test` with that leaf.
    when not defined(ssl): skip()  # Article IX.9: TLS needs `-d:ssl`, which stub gives
    else:
      check authority.problem == ""  # `openssl` made root and leaves
      if authority.problem.len == 0:
        for (host, should_tunnel) in [("localhost", false), ("api.example.test", true)]:
          let found = authority.sendSecured(Leaf.Wrong, host, should_tunnel)
          check PROBLEM_VERIFY in
              found.sent.outcome  # case as found: review finding security-1, 2026-10-29
          check found.head.lines.len == 0  # case as found: server read no byte, credential least
        check casesSecured().len == COUNT_SECURED  # every ordered pair of cases, in each way
        for (leaf, host, should_tunnel) in casesSecured():
          let
            secured = authority.sendSecured(leaf, host, should_tunnel)
            is_named = host in LUT_HOSTS_BY_LEAF[leaf]
            named = $leaf & " " & host & (if should_tunnel: " tunnelled: " else: ": ")
          check named & $secured.sent.is_replied ==
              named & $is_named  # domain: RFC 9110 4.3.4, leaf names host, whatever send before
          if is_named:
            check named & $secured.head.values("authorization") ==
                named & $(@["Bearer " & CREDENTIAL_SUITE])  # domain: bearer reaches host named
          else:
            check named & $(PROBLEM_VERIFY in secured.sent.outcome) ==
                named & "true"  # domain: refused by check of certificate, never otherwise
            check named & $secured.head.lines.len ==
                named & "0"  # domain: server read no byte of request
          if not should_tunnel: continue
          let target = host & ":" & $secured.port
          check named & $secured.connect.filterIt(it.startsWith("CONNECT ")) ==
              named & $(@["CONNECT " & target & " HTTP/1.1"])  # domain: RFC 9110 9.3.6, tunnel
          check named & $secured.connect.anyIt(CREDENTIAL_SUITE in it) ==
              named & "false"  # domain: proxy never sees credential


  test "host opening with dot is refused before any connection, as OpenSSL reads any subdomain":
    # Regression, found in recheck claim regressions-app-2, 2026-10-29: OpenSSL reads pinned
    #   name opening with `.` as any subdomain of rest, so leaf naming `api.example.test` alone
    #   received bearer at `https://.example.test`, through proxy that routes such name.
    when not defined(ssl): skip()  # Article IX.9: TLS needs `-d:ssl`, which stub gives
    else:
      check authority.problem == ""  # `openssl` made root and leaves
      let found = authority.sendSecured(Leaf.Wrong, ".example", should_tunnel = true)
      check found.sent.outcome ==
          problemHost(".example")  # case as found, in shape of suite: was `replied`
      check found.head.lines.len == 0  # case as found: leaf naming `wrong.example` read bearer
      check found.connect.len == 0  # case as found: tunnel opened for `.example`
      var count = 0
      for host in HOSTS_DOTTED:
        for leaf in Leaf:
          for should_tunnel in [false, true]:
            let
              secured = authority.sendSecured(leaf, host, should_tunnel = should_tunnel)
              named = $leaf & " " & host & (if should_tunnel: " tunnelled: " else: ": ")
            inc count
            check named & secured.sent.outcome ==
                named & problemHost(host)  # domain: refused, whatever leaf names
            check named & $secured.head.lines.len == named & "0"  # domain: server read no byte
            check named & $secured.connect.len == named & "0"  # domain: proxy read nothing
      check count == COUNT_DOTTED  # each host opening with dot, each leaf, each way


  test "name closing with dot pins without that dot, as certificate names host without it":
    # Regression, found in recheck claim regressions-app-3, 2026-10-29: pin kept dot closing
    #   absolute name, so OpenSSL refused leaf naming same host without it, which curl takes.
    #   Name closing with dot resolves nowhere here, so law drives tunnel alone, which names host
    #     to proxy as written.
    when not defined(ssl): skip()  # Article IX.9: TLS needs `-d:ssl`, which stub gives
    else:
      check authority.problem == ""  # `openssl` made root and leaves
      let found = authority.sendSecured(Leaf.Name, "localhost.", should_tunnel = true)
      check found.sent.outcome == "replied"  # case as found: was `certificate verify failed`
      check found.head.values("authorization") ==
          @["Bearer " & CREDENTIAL_SUITE]  # case as found: bearer reaches host leaf names
      var count = 0
      for (host, pinned) in HOSTS_CLOSED:
        for leaf in Leaf:
          let
            secured = authority.sendSecured(leaf, host, should_tunnel = true)
            is_named = pinned in LUT_HOSTS_BY_LEAF[leaf]
            named = $leaf & " " & host & ": "
          inc count
          check named & $secured.sent.is_replied ==
              named & $is_named  # domain: RFC 5280 4.2.1.6, name of certificate closes no dot
          if is_named:
            check named & $secured.head.values("authorization") ==
                named & $(@["Bearer " & CREDENTIAL_SUITE])  # domain: bearer reaches host named
          else:
            check named & $(PROBLEM_VERIFY in secured.sent.outcome) ==
                named & "true"  # domain: refused by check of certificate, never otherwise
            check named & $secured.head.lines.len ==
                named & "0"  # domain: server read no byte of request
          let target = host & ":" & $secured.port
          check named & $secured.connect.filterIt(it.startsWith("CONNECT ")) ==
              named & $(@["CONNECT " & target & " HTTP/1.1"])  # domain: tunnel keeps dot of name
      check count == COUNT_CLOSED  # each name closing with dot, each leaf


  test "https URL with no context, or with host TLS cannot pin, is refused, and nothing goes out":
    when not defined(ssl): skip()  # Article IX.9: TLS needs `-d:ssl`, which stub gives
    else:
      check authority.problem == ""  # `openssl` made root and leaves
      let
        listener = listenRaw()
        port = int(listener.getLocalAddr[1])
        reading = listener.readHead
      for url in [
        "https://127.0.0.1:" & $port & "/v1", "HTTPS://127.0.0.1:" & $port & "/v1",
        "https://localhost:" & $port & "/v1",
      ]:
        for proxy_url in [none(string), some(urlLoopback(port, ""))]:
          let
            sent = sendLoopback(url, "{}", credential = CREDENTIAL_GIVEN, proxy_url = proxy_url)
            named = url & " " & $proxy_url & ": "
          check named & sent.outcome == named & PROBLEM_CONTEXT  # pin needs context
      for proxy_url in [none(string), some(urlLoopback(port, ""))]:
        let sent = waitFor send(
          "https:///v1/messages",
          "{}",
          @[],
          CREDENTIAL_GIVEN,
          proxy_url,
          authority.client,
          BYTES_CAP,
          newFuture[void]("deadline"),
        )
        check sent.outcome == problemHost("")  # empty pin checks no name, so tunnel would pass
      let control = sendLoopback(urlLoopback(port, "/control"), "")
      check control.is_replied  # listener answers
      check (waitFor reading).lines[0] == "GET /control HTTP/1.1"  # first connection is control's
      listener.close()


  test "each refusal of input `send` makes ends in value refused, in backticks, empty where none":
    # Regression, found in review: https URL with no context gave problem ending `got none.`,
    #   where Article IV.4 echoes value in backticks, as `readCredential` writes absent one.
    when not defined(ssl): skip()  # Article IX.9: TLS refusals need `-d:ssl`, which stub gives
    else:
      let found = sendLoopback("https://127.0.0.1:9/v1", "{}", credential = CREDENTIAL_GIVEN)
      check found.outcome ==
          PROBLEM_CONTEXT  # case as found: review of phase 1 against IV.4, 2026-10-29
      check found.outcome.isEchoing  # case as found: was `got none.`
      for (url, proxy_url) in [
        ("http://127.0.0.1:9/a b", none(string)),  # URL holding whitespace
        ("http://127.0.0.1:9/a", some("http://:3128")),  # proxy naming no host
        ("http://127.0.0.1:9/a", some("socks5h://127.0.0.1:1080")),  # proxy of other scheme
        ("http://127.0.0.1:9/a", some("http://127.0.0.1:70000")),  # proxy port past 65535
        ("https://127.0.0.1:9/a", some("http://alice:secret@127.0.0.1:3128")),  # login, https
        ("https://127.0.0.1:9/a", none(string)),  # https URL with no context
      ]:
        let sent = sendLoopback(url, "{}", credential = CREDENTIAL_GIVEN, proxy_url = proxy_url)
        check url & ": " & $sent.outcome.isEchoing == url & ": true"  # domain: IV.4, each kind
      let pinned = waitFor send(
        "https:///a",
        "{}",
        @[],
        CREDENTIAL_GIVEN,
        none(string),
        authority.client,
        BYTES_CAP,
        newFuture[void]("deadline"),
      )
      check pinned.outcome.isEchoing  # domain: IV.4, host TLS cannot pin, empty one

  when defined(ssl):
    removeDir(authority.directory)
