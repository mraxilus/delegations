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
##   |---------------------|-------------------------------------------------------------|
##   | Code                | RFC 3986, which `redirect` follows                          |
##   |---------------------|-------------------------------------------------------------|
##   | Reference           | R: scheme, authority, path, query, fragment                 |
##   | toReference         | parse of R by regular expression of appendix `B`            |
##   | resolve             | T: reference R resolved against Base (5.2.2), strictly      |
##   | merge               | merge (5.2.3)                                               |
##   | removeDotSegments   | remove_dot_segments (5.2.4)                                 |
##   | toText              | component recomposition (5.3)                               |
##   |---------------------|-------------------------------------------------------------|
##
##   Every routine but `send` and what it calls to reach socket and TLS context (`pinHost`,
##     `exchange`, `readBody` and bindings of OpenSSL) is pure, so suites hold each choice by
##     table; suite drives `send` over loopback.
##   `send` makes fresh client for each request and follows no redirect: client loop would keep
##     its headers across hosts, so credential could reach other host, and it would keep one
##     proxy for every hop. `suggester` follows page redirects itself, choosing proxy again.
##     Cost: each hop and service request opens new connection, and new TLS handshake for
##     https; no connection is reused.
##   `send` pins host of https URL on its context before client exists, since async client of
##     `std/httpclient` names host for SNI alone and checks no certificate against it: name pins
##     as name, address as address, other kind cleared, so trusted leaf naming other host is
##     refused before any byte of request leaves. Empty host is refused, since empty pin checks
##     no name.
##     Cost: context holds one pin at time, so sends sharing context run in turn, as `suggester`
##     runs them; through proxy, target host is pinned for tunnel.
##   Proxy URL should be `http://`, in any case, with host, and port `isPort` takes or none, else
##     `send` refuses it before client exists, naming part: https proxy takes TLS of its own,
##     which no pin covers, and client opens it even for http URL, on context `send` may lack;
##     client reads `socks5` as http proxy, and only `socks5h` as SOCKS, so one kind of proxy
##     stays, which suite drives; client reads port modulo 65536, as it reads port of URL.
##     Host is checked first: text naming none after `//` may hold user where scheme stands, as
##       curl reads `alice:secret@proxy:3128`; host and port stand after last `@` of authority,
##       so problem echoes no user part or password.
##     Cost: proxy reachable only by https or SOCKS is refused, naming its scheme.
##     Cost: `socks5h` proxy is refused though client speaks it: `newConnection` of
##       `std/httpclient` opens SOCKS 5 handshake to it, which names host for proxy to resolve.
##   Proxy URL holding user or password is refused for https URL before client exists: client
##     writes `Proxy-Authorization` on each request it builds, request inside tunnel included,
##     so service and page would read login of proxy. Http URL keeps it, as proxy itself reads
##     that request. Problem names host of proxy, never byte of user part.
##     Cost: proxy needing login cannot reach https.
##   `send` lowercases scheme of URL and of proxy URL before client sees either, and `redirect`
##     scheme of its target, as RFC 3986 section 3.1 compares scheme without case: client compares
##     it with case, so `HTTPS` through proxy would open no tunnel and send request, bearer
##     included, to proxy in clear.
##     Cost: URL client sends differs from URL caller gave where scheme holds capital.
##   `redirect` resolves location as RFC 3986 section 5.2 resolves reference, read strictly:
##     reference holding scheme keeps it, so `http:g` names no host and gives no redirect.
##     Cost: location `http:/page` that browser takes as relative is no redirect here.
##     Rejected: `combine` of `std/uri`, which keeps dot segments that end path and reads empty
##     query or fragment as none.
##   URL holding whitespace or control character is refused by `send` before client exists, and
##     by `redirect` as target: such byte would split or corrupt request line, and client checks
##     line break alone, by assertion.
##   Deadline is future caller passes, so suite completes it itself and reads no clock; body
##     is read from stream up to its cap, so huge body never fills memory.
##     Cost: head of reply has no byte cap: client counts header names against `headerLimit`,
##     never bytes, appends folded line to its value uncounted, and reads line past 1,000,000
##     bytes as next one, so peer sending head until deadline makes process hold all of it.
##     Cost: name lookup blocks before deadline exists; through proxy, only proxy host resolves.
##     `send` races deadline by `addCallback`, so other waiters on it keep their callbacks.
##     Cost: `or` that caller puts on deadline after `send` clears callback of `send`.
##     Cost: deadline that completes while client connects ends `send`, yet request goes out once
##     connection opens: client cancels nothing, and closes no socket it has not opened.
##   Service request waits for whole reply, not streamed, on socket client opens with no TCP
##     keep-alive and keeps private, so `send` cannot set it.
##     Cost: connection network drops while model thinks loses answer service still bills, and
##     record mode writes nothing, so next run pays again; streaming, which keeps bytes moving,
##     is documented remedy, not taken.
##   Credential goes as Bearer on service request alone, never on page; its `$` is poisoned,
##     so no report or recording can render it. Bearer is how authentication guide of Anthropic
##     sends API key, and `x-api-key` its legacy header
##     (https://platform.claude.com/docs/en/manage-claude/authentication, read 2026-10-29).
##     Cost: service reading key from `x-api-key` alone answers 401.
##   Recording is text its own reader types, as index file is: request and body carry byte
##     counts, so any bytes read back. Stamp is FNV-1a 64, which resists no collision, so
##     whole request is stored and compared. Sibling of `stamp` in
##     `curator/audit/src/provenance.nim`, which project does not import (Article II.9).
##     Rejected: `std/hashes`, whose values change between versions; `std/sha1`, deprecated.
##   Label and header values are lines of file: client joins folded header lines by line break,
##     so `send` unfolds each value, as RFC 7230 section 3.2.4 asks of recipient, and `toText`
##     unfolds label; status takes one to three digits, as `send` gives 0 to 599. So every reply
##     `send` gives records, and replay reads it back.
##   Proxy follows curl: `https_proxy` then `HTTPS_PROXY` for https, `http_proxy` alone for
##     http, `no_proxy` then `NO_PROXY` for bypass; loopback always goes direct. Value naming no
##     port, or empty one, takes port 1080, as curl assumes, where client would dial 80.
##     Cost: bypass entry of address range is never matched, so such host goes through proxy.

{.experimental: "strictFuncs".}

import std/[asyncdispatch, httpclient, net, options, sequtils, strutils, uri]
when defined(ssl):
  import std/openssl  # Names of libraries TLS of `std/net` loads, which host pin binds against.

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
    request*: string
      ## `GET <url>` of page, or `POST <endpoint>`, line break, then body of service, so
      ##   recording replays for its endpoint alone; no credential.
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
    at_piece: int  ## Byte piece read last opens at, so refusal echoes what piece holds.

  Reference = object  ## Define reference as five components, i.e. R of RFC 3986 section 5.2.
    scheme: Option[string]  ## Scheme, before `:`; `none` where reference holds none.
    authority: Option[string]  ## Authority, after `//`; `none` where reference holds none.
    path: string  ## Path; empty where reference holds none.
    query: Option[string]  ## Query, after `?`; `none` where reference holds none.
    fragment: Option[string]  ## Fragment, after `#`; `none` where reference holds none.


const
  HEADER_RECORDING* = "lojban_tagger recording 1"  ## First line of recording file: format, version.
  USER_AGENT* = "lojban_tagger"  ## Agent every request names.
  STATUSES_REDIRECT* = [301, 302, 303, 307, 308]  ## Statuses `redirect` follows, as client does.
  CHARACTERS_CONTROL = {'\0'..'\x1F', '\x7F'}  ## Control characters of ASCII: C0 set and DEL.
  LUT_OPENING_BY_SERVICE*: array[Service, string] = ["sk-ant-", "sk-or-", ""]
    ## Opening of credentials each service issues; opening of other service is refused.
  PROBLEM_CONTEXT = "TLS context should exist for https URL; got ``."
    ## Problem `send` gives for https URL with no context, whose host it cannot pin.
  PORT_CURL = "1080"  ## Port curl assumes where proxy string specifies none, as `proxy` gives.


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


func isPort(text: string): bool =
  ## Test text is port client reaches as named: one to five digits from 1 to 65535, as RFC 6335
  ##   section 6 ranges it; client reads larger number modulo 65536, so `65616` would reach 80.
  text.len in 1..5 and text.allIt(it in Digits) and text.parseInt in 1..65_535


func toReference(text: string): Reference =
  ## Split text into five components of reference, as regular expression of RFC 3986 appendix
  ##   `B` splits it; empty query or fragment stays apart from none.
  ##   Sibling of `dropSecrets` of `src/lojban_tagger/suggestions.nim`, which splits URL by same
  ##     expression; that pure module cannot import this one, which imports it (Article II.9).
  var rest = text
  let at_scheme = rest.find({':', '/', '?', '#'})
  if at_scheme > 0 and rest[at_scheme] == ':':
    result.scheme = some(rest[0..<at_scheme])
    rest = rest[at_scheme+1 .. ^1]
  if rest.startsWith("//"):
    var stop = rest.find({'/', '?', '#'}, 2)
    if stop < 0: stop = rest.len
    result.authority = some(rest[2..<stop])
    rest = rest[stop .. ^1]
  let at_fragment = rest.find('#')
  if at_fragment >= 0:
    result.fragment = some(rest[at_fragment+1 .. ^1])
    rest = rest[0..<at_fragment]
  let at_query = rest.find('?')
  if at_query >= 0:
    result.query = some(rest[at_query+1 .. ^1])
    rest = rest[0..<at_query]
  result.path = rest


func toText(reference: Reference): string =
  ## Recompose reference from its components, i.e. section 5.3 of RFC 3986.
  if reference.scheme.isSome: result.add reference.scheme.get & ":"
  if reference.authority.isSome: result.add "//" & reference.authority.get
  result.add reference.path
  if reference.query.isSome: result.add "?" & reference.query.get
  if reference.fragment.isSome: result.add "#" & reference.fragment.get


func isURL*(text: string): bool =
  ## Test text is one http or https URL with host, port of `isPort` or none, and no whitespace,
  ##   which `suggester` fetches.
  if text.len == 0 or text.anyIt(it in Whitespace): return false
  let uri = text.parseUri
  uri.scheme.toLowerAscii in ["http", "https"] and uri.hostname.len > 0 and
      (uri.port.len == 0 or uri.port.isPort)


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
  ##   added where value has no scheme, and port 1080 where client would read none, as curl
  ##   assumes 1080 where proxy names no port, and client would dial 80.
  let uri = url.parseUri
  if uri.hostname.isLoopback: return none(string)
  if uri.hostname.isBypassed(environment.lookup(["no_proxy", "NO_PROXY"])): return none(string)
  let value =
    case uri.scheme.toLowerAscii
    of "https": environment.lookup(["https_proxy", "HTTPS_PROXY"])
    of "http": environment.lookup(["http_proxy"])
    else: ""
  if value.len == 0: return none(string)
  var reference = (if "://" in value: value else: "http://" & value).toReference
  if reference.authority.isSome and reference.toText.parseUri.port.len == 0:
    let authority = reference.authority.get
    reference.authority = some(authority & (if authority.endsWith(':'): "" else: ":") & PORT_CURL)
  some(reference.toText)


func removeDotSegments(path: string): string =
  ## Remove segments `.` and `..` from path, i.e. remove_dot_segments of RFC 3986 section 5.2.4;
  ##   branches run its steps `A` to `E` in order.
  var input = path
  while input.len > 0:
    if input.startsWith("../"): input = input[3 .. ^1]
    elif input.startsWith("./"): input = input[2 .. ^1]
    elif input.startsWith("/./"): input = input[2 .. ^1]
    elif input == "/.": input = "/"
    elif input.startsWith("/../") or input == "/..":
      input = "/" & input[min(4, input.len) .. ^1]
      result.setLen max(result.rfind('/'), 0)
    elif input in [".", ".."]: input = ""
    else:
      var stop = input.find('/', 1)
      if stop < 0: stop = input.len
      result.add input[0..<stop]
      input = input[stop .. ^1]


func merge(base: Reference, path: string): string =
  ## Merge relative path with path of base, i.e. merge of RFC 3986 section 5.2.3.
  if base.authority.isSome and base.path.len == 0: return "/" & path
  base.path[0..base.path.rfind('/')] & path


func resolve(reference, base: Reference): Reference =
  ## Resolve reference against base, i.e. T of RFC 3986 section 5.2.2, read strictly: reference
  ##   holding scheme keeps it, even scheme of base.
  result = reference
  if reference.scheme.isSome or reference.authority.isSome:
    if reference.scheme.isNone: result.scheme = base.scheme
    result.path = removeDotSegments(reference.path)
    return
  (result.scheme, result.authority) = (base.scheme, base.authority)
  if reference.path.len == 0:
    result.path = base.path
    if reference.query.isNone: result.query = base.query
  elif reference.path.startsWith('/'): result.path = removeDotSegments(reference.path)
  else: result.path = removeDotSegments(base.merge(reference.path))


func lowercaseScheme(url: string): string =
  ## Lowercase scheme of URL, split as RFC 3986 appendix `B` splits it, since section 3.1 compares
  ##   scheme without case and client of `std/httpclient` compares it with case.
  let at = url.find({':', '/', '?', '#'})
  if at > 0 and url[at] == ':': url[0..<at].toLowerAscii & url[at .. ^1]
  else: url


func redirect*(url: string, reply: Reply): Option[string] =
  ## Resolve URL redirect names, as RFC 3986 section 5.2 resolves location against `url`;
  ##   `none` where status is no redirect, target is no http or https URL with host, holds
  ##   whitespace or control character, or https falls to http; scheme of target lowercased.
  if reply.status notin STATUSES_REDIRECT or reply.location.len == 0: return none(string)
  let target = reply.location.strip.toReference.resolve(url.toReference).toText.lowercaseScheme
  if not target.isURL or target.find(Whitespace + CHARACTERS_CONTROL) >= 0: return none(string)
  let is_falling = url.parseUri.scheme.toLowerAscii == "https" and
      target.parseUri.scheme.toLowerAscii == "http"
  if is_falling: return none(string)
  some(target)


func stamp*(request: string): string =
  ## Stamp request by FNV-1a 64, as 16 lowercase hex digits; names recording file.
  var hash = 0xcbf29ce484222325'u64
  for character in request: hash = (hash xor uint64(ord(character))) * 0x100000001b3'u64
  hash.toHex.toLowerAscii



#[ Recordings ]#

func unfold(text: string): string =
  ## Unfold text onto one line: each line break, with spaces and tabs after it, becomes one space,
  ##   as RFC 7230 section 3.2.4 replaces obs-fold of header value.
  var is_folding = false
  for character in text:
    if character == '\n':
      result.add ' '
      is_folding = true
    elif not is_folding or character notin {' ', '\t'}:
      result.add character
      is_folding = false


func toText*(recording: Recording): string =
  ## Render recording as file text; request and body carry byte counts, so any bytes read back;
  ##   label is unfolded onto its one line.
  let reply = recording.reply
  HEADER_RECORDING & "\n" &
      "label " & recording.label.unfold & "\n" &
      "request " & $recording.request.len & "\n" & recording.request & "\n" &
      "status " & $reply.status & "\n" &
      "content-type " & reply.content_type & "\n" &
      "content-encoding " & reply.content_encoding & "\n" &
      "location " & reply.location & "\n" &
      "body " & (if reply.is_cut: "cut" else: "whole") & " " & $reply.body.len & "\n" &
      reply.body & "\n"


func readLine(cursor: var Cursor): Option[string] =
  ## Read line at cursor, its break consumed; `none` where text ends first.
  (cursor.line_piece, cursor.at_piece) = (cursor.line, cursor.at)
  let close = cursor.text.find('\n', cursor.at)
  if close < 0: return none(string)
  result = some(cursor.text[cursor.at..<close])
  cursor.at = close + 1
  inc cursor.line


func readBlock(cursor: var Cursor, count: int): Option[string] =
  ## Read `count` bytes at cursor and line break after them; `none` where text holds fewer.
  (cursor.line_piece, cursor.at_piece) = (cursor.line, cursor.at)
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

  func refuse(cursor: Cursor, shape: string): Recorded =
    ## Build outcome refusing line piece read last on its own line: shape it should have, then
    ##   line it holds made printable, empty where text ends before line break.
    let
      close = cursor.text.find('\n', cursor.at_piece)
      held =
        if close < 0: ""
        else: cursor.text[cursor.at_piece..<close].toPrintable(RUNES_ANSWER_SHOWN)
    Recorded(is_read: false, line: cursor.line_piece, problem: shape & "; got `" & held & "`.")

  func refuseBlock(cursor: Cursor, shape: string): Recorded =
    ## Build outcome refusing block read last on line it opens on: shape it should have, then
    ##   bytes left from where it opens.
    let left = cursor.text.len - cursor.at_piece
    Recorded(is_read: false, line: cursor.line_piece, problem: shape & "; got `" & $left &
        "` bytes left.")

  let header = cursor.readLine
  if header.isNone or header.get != HEADER_RECORDING:
    return cursor.refuse("Recording should open with `" & HEADER_RECORDING & "`")
  var recording: Recording
  let label = cursor.readField("label")
  if label.isNone: return cursor.refuse("Line should be `label <text>`")
  recording.label = label.get
  let count_request = cursor.readField("request")
  if count_request.isNone or not count_request.get.allIt(it in Digits) or
      count_request.get.len notin 1..9:
    return cursor.refuse("Line should be `request <bytes>`")
  let request = cursor.readBlock(count_request.get.parseInt)
  if request.isNone:
    return cursor.refuseBlock("Request should hold bytes its line counts, then line break")
  recording.request = request.get
  let status = cursor.readField("status")
  if status.isNone or not status.get.allIt(it in Digits) or status.get.len notin 1..3:
    return cursor.refuse("Line should be `status <code>`, one to three digits")
  recording.reply.status = status.get.parseInt
  for (name, field) in [("content-type", 0), ("content-encoding", 1), ("location", 2)]:
    let value = cursor.readField(name)
    if value.isNone: return cursor.refuse("Line should be `" & name & " <value>`")
    case field
    of 0: recording.reply.content_type = value.get
    of 1: recording.reply.content_encoding = value.get
    else: recording.reply.location = value.get
  let
    body = cursor.readField("body")
    words = if body.isSome: body.get.split(' ') else: @[]
  if words.len != 2 or words[0] notin ["whole", "cut"] or not words[1].allIt(it in Digits) or
      words[1].len notin 1..9:
    return cursor.refuse("Line should be `body <whole|cut> <bytes>`")
  recording.reply.is_cut = words[0] == "cut"
  let bytes = cursor.readBlock(words[1].parseInt)
  if bytes.isNone:
    return cursor.refuseBlock("Body should hold bytes its line counts, then line break")
  recording.reply.body = bytes.get
  if cursor.at != text.len:  # Byte after body stands on line of cursor, opening no piece.
    return Recorded(is_read: false, line: cursor.line, problem: "Recording should end after " &
        "body; got `" & text[cursor.at .. ^1].toPrintable(RUNES_ANSWER_SHOWN) & "`.")
  Recorded(is_read: true, recording: recording)



#[ Sending ]#

when defined(ssl):
  proc SSL_CTX_get0_param(context: SslCtx): pointer {.cdecl, importc, dynlib: DLLSSLName.}
    ## Read verification parameters of context, which each connection it opens copies.
  proc X509_VERIFY_PARAM_set1_host(
    parameters: pointer, name: cstring, length: csize_t
  ): cint {.cdecl, importc, dynlib: DLLUtilName.}
    ## Set name peer certificate should hold, clearing names set before; nil clears alone; 1 done.
  proc X509_VERIFY_PARAM_set1_ip(
    parameters: pointer, address: cstring, length: csize_t
  ): cint {.cdecl, importc, dynlib: DLLUtilName.}
    ## Set address peer certificate should hold, as raw bytes; nil clears it; 1 done.
  proc X509_VERIFY_PARAM_set1_ip_asc(
    parameters: pointer, address: cstring
  ): cint {.cdecl, importc, dynlib: DLLUtilName.}
    ## Set address peer certificate should hold, as text; 1 done, 0 where text is no address.


  proc pinHost(context: SslContext, host: string): bool =
    ## Pin host on context, so each connection it opens next refuses certificate naming other
    ##   host: name as name, address as address, other kind cleared; false where host is empty,
    ##   whose pin checks nothing, or where OpenSSL refuses it.
    ##   Host `parseUri` gives holds no brackets, so IPv6 address reads as address.
    if host.len == 0: return false
    let parameters = SSL_CTX_get0_param(context.context)
    if host.isIpAddress:
      X509_VERIFY_PARAM_set1_ip_asc(parameters, host.cstring) == 1 and
          X509_VERIFY_PARAM_set1_host(parameters, nil, 0) == 1
    else:
      X509_VERIFY_PARAM_set1_host(parameters, host.cstring, csize_t(host.len)) == 1 and
          X509_VERIFY_PARAM_set1_ip(parameters, nil, 0) == 1


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
  ## Send request, then read reply: status, headers kept and unfolded, body up to `bytes_max`.
  let
    method_request = if body.len > 0: HttpPost else: HttpGet
    response = await client.request(url, httpMethod = method_request, body = body, headers = fields)
    (bytes, is_cut) = await response.readBody(bytes_max)
  return Reply(
    status: int(response.code),
    content_type: response.headers.getOrDefault("content-type").toString.unfold,
    content_encoding: response.headers.getOrDefault("content-encoding").toString.unfold,
    location: response.headers.getOrDefault("location").toString.unfold,
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
  ##   Deadline finished already sends nothing, since client still connecting would send later.
  ##   Proxy URL naming no host after `//`, scheme other than `http` in any case, or port other
  ##     than `isPort` takes sends nothing, problem naming first such part and no user part;
  ##     client sees scheme of URL and of proxy URL lowercased.
  ##   Proxy URL holding user or password sends nothing for https URL, since client repeats its
  ##     login inside tunnel; problem names host of proxy, never user part.
  ##   https URL pins its host on `context`, so certificate naming other host is refused; no
  ##     context, or host TLS cannot pin, sends nothing.
  ##   Agent, encoding and bearer are its own, whatever caller headers name.

  proc race(a, b: FutureBase): Future[void] =
    ## Complete future once `a` or `b` finishes, by `addCallback`, which keeps callbacks others
    ##   put on either; `or` of `std/asyncdispatch` sets `callback=`, which clears them.
    let raced = newFuture[void]("race")
    for future in [a, b]:
      future.addCallback proc() =
        if not raced.finished: raced.complete()
    raced

  let at = url.find(Whitespace + CHARACTERS_CONTROL)
  if at >= 0:
    return Sent(is_replied: false, problem: "URL should hold no whitespace or control " &
        "character; got byte `" & $ord(url[at]) & "` at `" & $at & "`.")
  if deadline.finished: return Sent(is_replied: false, problem: "deadline passed")
  let
    url_sent = url.lowercaseScheme
    uri = url_sent.parseUri
  if proxy_url.isSome:
    let proxied = proxy_url.get.parseUri
    if proxied.opaque or proxied.hostname.len == 0:
      return Sent(is_replied: false, problem: "Proxy should name host after `//`; got ``.")
    if proxied.scheme.toLowerAscii != "http":
      return Sent(is_replied: false, problem: "Proxy should be `http://`; got `" &
          proxied.scheme & "`.")
    if proxied.port.len > 0 and not proxied.port.isPort:
      return Sent(is_replied: false, problem: "Proxy should name port of one to five digits " &
          "from 1 to 65535, or none; got `" & proxied.port & "`.")
    if uri.scheme == "https" and (proxied.username.len > 0 or proxied.password.len > 0):
      return Sent(is_replied: false, problem: "Proxy should hold no user part for https URL, " &
          "since client repeats `Proxy-Authorization` inside tunnel; got user part for `" &
          proxied.hostname & "`.")
  when defined(ssl):
    if uri.scheme == "https":
      if context.isNil:
        return Sent(is_replied: false, problem: PROBLEM_CONTEXT)
      if not context.pinHost(uri.hostname):
        return Sent(is_replied: false, problem: "Host should be name or address TLS can pin; " &
            "got `" & uri.hostname & "`.")
  let proxy_used = if proxy_url.isSome: newProxy(proxy_url.get.lowercaseScheme) else: nil
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
  fields["user-agent"] = USER_AGENT
  fields["accept-encoding"] = "identity"
  if credential.isSome: fields["authorization"] = "Bearer " & string(credential.get)
  let replying = client.exchange(url_sent, body, fields, bytes_max)
  await race(replying, deadline)
  client.close()
  if not replying.finished: return Sent(is_replied: false, problem: "deadline passed")
  if replying.failed:
    let lines = replying.readError.msg.splitLines
    return Sent(is_replied: false, problem: if lines.len > 0: lines[0] else: "error")
  Sent(is_replied: true, reply: replying.read)
