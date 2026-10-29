## Send one exchange to service or page, and keep it as recording: transport of `suggester`.
##
##   |---------------------|-------------------------------------------------------------|
##   | Code                | Meaning                                                     |
##   |---------------------|-------------------------------------------------------------|
##   | Credential          | secret key service checks; renders nowhere                  |
##   | readCredential      | read credential from environment value, or refuse it        |
##   | proxy, isBypassed   | proxy for URL, read from environment as curl reads it       |
##   | redirect            | URL redirect names; none where it falls to http             |
##   | send                | send one request within deadline, body read up to cap       |
##   | Recording           | one exchange as file keeps it: label, request, reply        |
##   | stamp               | FNV-1a 64 of request, which names recording file            |
##   |---------------------|-------------------------------------------------------------|
##
##   Every routine but `send` is pure, so suites hold each choice by table; `send` alone opens
##     socket, and suite drives it over loopback.
##   `send` makes fresh client for each request and follows no redirect: client loop would keep
##     its headers across hosts, so credential could reach other host, and it would keep one
##     proxy for every hop. `suggester` follows page redirects itself, choosing proxy again.
##   URL holding whitespace or control character is refused by `send` before client exists, and
##     by `redirect` as target: line break would split request line, and client asserts it holds
##     none, so its `AssertionDefect` would escape `send`.
##   Deadline is future caller passes, so suite completes it itself and reads no clock; body
##     is read from stream up to its cap, so huge page never fills memory.
##     Cost: name lookup blocks before deadline exists; through proxy, only proxy host resolves.
##   Credential goes as Bearer on service request alone, never on page; its `$` is poisoned,
##     so no report or recording can render it.
##   Recording is text its own reader types, as index file is: request and body carry byte
##     counts, so any bytes read back. Stamp is FNV-1a 64, which resists no collision, so
##     whole request is stored and compared. Sibling of `stamp` in
##     `curator/audit/src/provenance.nim`, which project does not import (Article II.9).
##     Rejected: `std/hashes`, whose values change between versions; `std/sha1`, deprecated.
##   Proxy follows curl: `https_proxy` then `HTTPS_PROXY` for https, `http_proxy` alone for
##     http, `no_proxy` then `NO_PROXY` for bypass; loopback always goes direct.
##     Cost: bypass entry of address range is never matched, so such host goes through proxy.

{.experimental: "strictFuncs".}

import std/[asyncdispatch, httpclient, net, options, sequtils, strutils, uri]

import ../src/lojban_tagger/suggestions


type
  Credential* = distinct string  ## Define secret key service checks; renders nowhere.

  Credentialed* = object  ## Define outcome of reading credential from environment value.
    case is_read*: bool  ## Value reads as credential.
    of true:
      credential*: Credential  ## Credential, trimmed.
      name*: string  ## Variable credential was read from.
    of false:
      problem*: string  ## Why value is no credential; names variable and position, never value.

  Sent* = object  ## Define outcome of sending one request: reply, or why none came.
    case is_replied*: bool  ## Reply came before deadline.
    of true:
      reply*: Reply  ## Reply as read, body cut at its cap.
    of false:
      problem*: string  ## `deadline passed`, URL refused, or first line of error; no credential.

  Recording* = object  ## Define one exchange as file keeps it: origin, request and reply.
    label*: string  ## Origin: `recorded <date>`, or documented shape of reply.
    request*: string  ## `GET <url>` of page, or `POST <body>` of service; no credential.
    reply*: Reply  ## Reply as read.

  Recorded* = object  ## Define outcome of reading recording file.
    case is_read*: bool  ## File reads as recording.
    of true:
      recording*: Recording  ## Recording file holds.
    of false:
      line*: int  ## Line, counted from one, reader refused.
      problem*: string  ## What is wrong, ending in offending text.

  Cursor = object  ## Define position of reader in recording text, with line it is on.
    text: string  ## Whole text.
    at: int  ## Byte read next.
    line: int  ## Line of `at`, counted from one.
    line_piece: int  ## Line piece read last opens on, so refusal names faulty line itself.


const
  HEADER_RECORDING* = "lojban_tagger recording 1"  ## First line of recording file: format, version.
  USER_AGENT* = "lojban_tagger"  ## Agent every request names.
  STATUSES_REDIRECT* = [301, 302, 303, 307, 308]  ## Statuses `redirect` follows, as client does.
  CHARACTERS_CONTROL = {'\0'..'\x1F', '\x7F'}  ## Control characters of ASCII: C0 set and DEL.
  LUT_OPENING_BY_SERVICE*: array[Service, string] = ["sk-ant-", "sk-or-", ""]
    ## Opening of credentials each service issues; opening of other service is refused.


func `$`*(credential: Credential): string {.error:
    "Credential renders nowhere; `send` alone writes it, into `authorization` of request.".}
  ## Refuse to render credential, so no report, recording or error can hold it.



#[ Choices ]#

func readCredential*(name, value: string; service: Service): Credentialed =
  ## Read credential from value of variable `name`: trimmed; visible ASCII alone, so no line
  ##   break splits header; opening of other service refused.
  let trimmed = value.strip
  if trimmed.len == 0:
    return Credentialed(is_read: false, problem: "Credential should be set; got `` for `" &
        name & "`.")
  for at, character in trimmed:
    if character notin {'!'..'~'}:
      return Credentialed(is_read: false, problem: "Credential should hold visible ASCII " &
          "alone; got byte `" & $ord(character) & "` at `" & $at & "` for `" & name & "`.")
  for other in Service:
    let opening = LUT_OPENING_BY_SERVICE[other]
    if other != service and opening.len > 0 and trimmed.startsWith(opening):
      return Credentialed(is_read: false, problem: "Credential should be issued by service `" &
          $service & "`; got opening `" & opening & "` for `" & name & "`.")
  Credentialed(is_read: true, credential: Credential(trimmed), name: name)


func isURL*(text: string): bool =
  ## Test text is one http or https URL with host and no whitespace, which `suggester` fetches.
  if text.len == 0 or text.anyIt(it in Whitespace): return false
  let uri = text.parseUri
  uri.scheme.toLowerAscii in ["http", "https"] and uri.hostname.len > 0


func isLoopback*(host: string): bool =
  ## Test host is `localhost`, IPv4 address in `127.0.0.0/8`, or `::1`.
  let lowered = host.toLowerAscii
  if lowered in ["localhost", "::1", "[::1]"]: return true
  let parts = lowered.split('.')
  parts.len == 4 and parts[0] == "127" and
      parts.allIt(it.len in 1..3 and it.allIt(it in Digits) and it.parseInt <= 255)


func isEndpoint*(url: string): bool =
  ## Test URL may carry credential: https, or http to loopback host.
  if not url.isURL: return false
  let uri = url.parseUri
  uri.scheme.toLowerAscii == "https" or uri.hostname.isLoopback


func isBypassed*(host, list: string): bool =
  ## Test bypass list names host: `*`, host itself, or domain host ends in, leading dot or none.
  let lowered = host.toLowerAscii
  for entry in list.split(','):
    let name = entry.strip.toLowerAscii
    if name.len == 0: continue
    if name == "*": return true
    let bare = if name.startsWith('.'): name[1 .. ^1] else: name
    if bare.len > 0 and (lowered == bare or lowered.endsWith("." & bare)): return true
  false


func lookup(environment: openArray[(string, string)], names: openArray[string]): string =
  ## Read value of first name environment gives nonempty, trimmed; empty where none.
  for name in names:
    for (key, value) in environment:
      if key == name and value.strip.len > 0: return value.strip


func proxy*(url: string, environment: openArray[(string, string)]): Option[string] =
  ## Choose proxy for URL: https takes `https_proxy`, else `HTTPS_PROXY`; http takes
  ##   `http_proxy` alone, as curl reads it; loopback and bypassed hosts go direct; `http://`
  ##   added where value has no scheme.
  let uri = url.parseUri
  if uri.hostname.isLoopback: return none(string)
  if uri.hostname.isBypassed(environment.lookup(["no_proxy", "NO_PROXY"])): return none(string)
  let value =
    case uri.scheme.toLowerAscii
    of "https": environment.lookup(["https_proxy", "HTTPS_PROXY"])
    of "http": environment.lookup(["http_proxy"])
    else: ""
  if value.len == 0: return none(string)
  some(if "://" in value: value else: "http://" & value)


func redirect*(url: string, reply: Reply): Option[string] =
  ## Resolve URL redirect names; `none` where status is no redirect, location is no http or
  ##   https URL, target holds whitespace or control character, or https falls to http.
  if reply.status notin STATUSES_REDIRECT or reply.location.len == 0: return none(string)
  let
    origin = url.parseUri
    resolved = combine(origin, reply.location.strip.parseUri)
    scheme = resolved.scheme.toLowerAscii
    target = $resolved
  if scheme notin ["http", "https"] or resolved.hostname.len == 0: return none(string)
  if target.find(Whitespace + CHARACTERS_CONTROL) >= 0: return none(string)
  if origin.scheme.toLowerAscii == "https" and scheme == "http": return none(string)
  some(target)


func stamp*(request: string): string =
  ## Stamp request by FNV-1a 64, as 16 lowercase hex digits; names recording file.
  var hash = 0xcbf29ce484222325'u64
  for character in request: hash = (hash xor uint64(ord(character))) * 0x100000001b3'u64
  hash.toHex.toLowerAscii



#[ Recordings ]#

func toText*(recording: Recording): string =
  ## Render recording as file text; request and body carry byte counts, so any bytes read back.
  let reply = recording.reply
  HEADER_RECORDING & "\n" &
      "label " & recording.label & "\n" &
      "request " & $recording.request.len & "\n" & recording.request & "\n" &
      "status " & $reply.status & "\n" &
      "content-type " & reply.content_type & "\n" &
      "content-encoding " & reply.content_encoding & "\n" &
      "location " & reply.location & "\n" &
      "body " & (if reply.is_cut: "cut" else: "whole") & " " & $reply.body.len & "\n" &
      reply.body & "\n"


func readLine(cursor: var Cursor): Option[string] =
  ## Read line at cursor, its break consumed; `none` where text ends first.
  cursor.line_piece = cursor.line
  let close = cursor.text.find('\n', cursor.at)
  if close < 0: return none(string)
  result = some(cursor.text[cursor.at..<close])
  cursor.at = close + 1
  inc cursor.line


func readBlock(cursor: var Cursor, count: int): Option[string] =
  ## Read `count` bytes at cursor and line break after them; `none` where text holds fewer.
  cursor.line_piece = cursor.line
  if count < 0 or cursor.at + count >= cursor.text.len or cursor.text[cursor.at+count] != '\n':
    return none(string)
  result = some(cursor.text[cursor.at..<cursor.at+count])
  cursor.line += result.get.count('\n') + 1
  cursor.at += count + 1


func readField(cursor: var Cursor, name: string): Option[string] =
  ## Read line `<name> <value>`, value possibly empty; `none` where line is other.
  let line = cursor.readLine
  if line.isNone or not line.get.startsWith(name & " "): return none(string)
  some(line.get[name.len+1 .. ^1])


func readRecording*(text: string): Recorded =
  ## Read recording file; refuse at first malformed line, naming it, as `readIndex` does.
  var cursor = Cursor(text: text, line: 1)

  func refuse(cursor: Cursor, problem: string): Recorded =
    ## Build outcome refusing recording at line piece read last opens on: faulty line itself.
    Recorded(is_read: false, line: cursor.line_piece, problem: problem)

  let header = cursor.readLine
  if header.isNone or header.get != HEADER_RECORDING:
    return cursor.refuse("Recording should open with `" & HEADER_RECORDING & "`; got `" &
        (if header.isSome: header.get.toPrintable(80) else: "") & "`.")
  var recording: Recording
  let label = cursor.readField("label")
  if label.isNone: return cursor.refuse("Line should be `label <text>`.")
  recording.label = label.get
  let count_request = cursor.readField("request")
  if count_request.isNone or not count_request.get.allIt(it in Digits) or
      count_request.get.len notin 1..9:
    return cursor.refuse("Line should be `request <bytes>`.")
  let request = cursor.readBlock(count_request.get.parseInt)
  if request.isNone: return cursor.refuse("Request should hold bytes its line counts.")
  recording.request = request.get
  let status = cursor.readField("status")
  if status.isNone or not status.get.allIt(it in Digits) or status.get.len notin 3..3:
    return cursor.refuse("Line should be `status <code>`, three digits.")
  recording.reply.status = status.get.parseInt
  for (name, field) in [("content-type", 0), ("content-encoding", 1), ("location", 2)]:
    let value = cursor.readField(name)
    if value.isNone: return cursor.refuse("Line should be `" & name & " <value>`.")
    case field
    of 0: recording.reply.content_type = value.get
    of 1: recording.reply.content_encoding = value.get
    else: recording.reply.location = value.get
  let
    body = cursor.readField("body")
    words = if body.isSome: body.get.split(' ') else: @[]
  if words.len != 2 or words[0] notin ["whole", "cut"] or not words[1].allIt(it in Digits) or
      words[1].len notin 1..9:
    return cursor.refuse("Line should be `body <whole|cut> <bytes>`.")
  recording.reply.is_cut = words[0] == "cut"
  let bytes = cursor.readBlock(words[1].parseInt)
  if bytes.isNone: return cursor.refuse("Body should hold bytes its line counts.")
  recording.reply.body = bytes.get
  if cursor.at != text.len:  # Byte after body stands on line of cursor, opening no piece.
    return Recorded(is_read: false, line: cursor.line, problem: "Recording should end after body.")
  Recorded(is_read: true, recording: recording)



#[ Sending ]#

proc readBody(response: AsyncResponse, bytes_max: int): Future[(string, bool)] {.async.} =
  ## Read body until stream ends, or `bytes_max` bytes are held; flag cut where more came.
  var body = ""
  while true:
    let (is_more, data) = await response.bodyStream.read()
    if not is_more: return (body, false)
    if body.len + data.len > bytes_max:
      body.add data[0..<bytes_max-body.len]
      return (body, true)
    body.add data


proc exchange(client: AsyncHttpClient; url, body: string; fields: HttpHeaders; bytes_max: int):
    Future[Reply] {.async.} =
  ## Send request, then read reply: status, headers kept, body up to `bytes_max`.
  let
    method_request = if body.len > 0: HttpPost else: HttpGet
    response = await client.request(url, httpMethod = method_request, body = body, headers = fields)
    (bytes, is_cut) = await response.readBody(bytes_max)
  return Reply(
    status: int(response.code),
    content_type: response.headers.getOrDefault("content-type").toString,
    content_encoding: response.headers.getOrDefault("content-encoding").toString,
    location: response.headers.getOrDefault("location").toString,
    body: bytes,
    is_cut: is_cut,
  )


proc send*(
  url, body: string;
  headers: seq[(string, string)];
  credential: Option[Credential];
  proxy_url: Option[string];
  context: SslContext;
  bytes_max: int;
  deadline: Future[void];
):
    Future[Sent] {.async.} =
  ## Send one request, GET or POST where body holds text, through fresh client following no
  ##   redirect; read body until `bytes_max`; end when `deadline` completes first.
  ##   URL holding whitespace or control character is refused, naming byte, and nothing is sent.
  let at = url.find(Whitespace + CHARACTERS_CONTROL)
  if at >= 0:
    return Sent(is_replied: false, problem: "URL should hold no whitespace or control " &
        "character; got byte `" & $ord(url[at]) & "` at `" & $at & "`.")
  let proxy_used = if proxy_url.isSome: newProxy(proxy_url.get) else: nil
  when defined(ssl):
    let client = newAsyncHttpClient(
      userAgent = USER_AGENT,
      maxRedirects = 0,
      sslContext = context,
      proxy = proxy_used,
    )
  else:
    let client = newAsyncHttpClient(userAgent = USER_AGENT, maxRedirects = 0, proxy = proxy_used)
  let fields = newHttpHeaders()
  for (name, value) in headers: fields[name] = value
  fields["accept-encoding"] = "identity"
  if credential.isSome: fields["authorization"] = "Bearer " & string(credential.get)
  let replying = client.exchange(url, body, fields, bytes_max)
  try:
    await replying or deadline
  except CatchableError:
    discard
  client.close()
  if not replying.finished: return Sent(is_replied: false, problem: "deadline passed")
  if replying.failed:
    let lines = replying.readError.msg.splitLines
    return Sent(is_replied: false, problem: if lines.len > 0: lines[0] else: "error")
  Sent(is_replied: true, reply: replying.read)
