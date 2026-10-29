## Hold `suggestions.nim` to its laws: answer becomes tag only as lists allow it, request bodies
##   stay stable and fence passage, replies of both wire formats read to tag or named failure,
##   pages read to text, and every report stays printable.
##   CLL covers no service, so suites are `Internal:`, tests named by behaviour (Article IX.10);
##     `Chapter 4` holds what answer takes from 4.11 and 4.12 through `readTanru` and `$`.
##   Replies are documented shapes with illustrative values, each citing its published page:
##     Message object of Messages API, chat completion of OpenRouter; two keyless 401 bodies
##     alone are captures, taken 2026-10-28.
##   Tables of authorities are data here, written apart from library: Table 3-7 of Unicode
##     Standard, index-windows-1252 and labels of WHATWG Encoding Standard, named references of
##     HTML, fields of each request body; project choices among them say so.
##   Random markup trees are written as markup, and reference walk reads text from tree itself,
##     so reader is held to tree, never to second parser of markup.
##   `Network`, `Recording` and `Page` arise in `app/suggester.nim` alone, so suite holds their
##     wording, never how they arise.
##   Samples are drawn into pools allocated once, after one seeding per test, and served by
##     `served`.

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[algorithm, json, options, random, sequtils, strutils, unittest]

import ../../src/lojban_tagger/[commands, dictionary, forms, suggestions {.all.}, tags]
import ../../src/lojban_tagger/lists/gismu
import ../../tools/examples


type
  Part {.pure.} = enum  ## Define kind of node random markup tree holds.
    Text  ## Text, escaped where written.
    Reference  ## Character reference, decoded or kept as written.
    Block  ## Element whose edges break line.
    Inline  ## Element whose edges break nothing.
    Skipped  ## Element whose content is no text.
    Comment  ## Comment, declaration or processing instruction.

  Node = object  ## Define node of random markup tree.
    part: Part  ## Kind of node.
    text: string  ## Text of text node; markup of reference or comment as written.
    decoded: string  ## Text reference stands for.
    name: string  ## Name of element as written, case varied.
    attributes: string  ## Attributes of element as written, opening space included.
    is_void: bool  ## Element is opened alone, holding nothing, as `br` is.
    children: seq[Node]  ## Nodes inside element.


const
  SAMPLES_TANRU = 500  ## Random tanru 4.12 law reads, seeded.
  FLOOR_READBACK = 450  ## Fewest random tanru whose form reads back; 473 read at seed `0`.
  FLOOR_SHARED = 20  ## Fewest random tanru with shared `brod` before head; 27 read at seed `0`.
  FLOOR_CMAVO = 220  ## Fewest random tanru holding cmavo; 254 read at seed `0`.
  SAMPLES_PASSAGE = 300  ## Random passages request laws read under each service, seeded.
  SAMPLES_REPLY = 1000  ## Random replies reading laws read under each service, seeded.
  FLOOR_SUGGESTED = 45
    ## Fewest random replies reading as tag under each service; 56 read under `claude`, 81 under
    ##   others, at seed `0`.
  SAMPLES_MARKUP = 300  ## Random markup trees reader is held to, seeded.
  DEPTH_MARKUP_MAX = 8  ## Most levels of elements random tree nests.
  FLOOR_DEEP = 80  ## Fewest random trees nesting `DEPTH_MARKUP_MAX` levels; 98 read at seed `0`.
  COUNT_NESTED = 100_000  ## Elements nested in one page, far past depth recursion could hold.
  LEVELS_SKIPPED_MAX = 4  ## Most levels of one skipped element exhaustive nesting law reads.
  SAMPLES_BYTES = 1000  ## Random byte strings repair, cut and printable laws read, seeded.
  BYTES_SAMPLE_MAX = 4096  ## Most bytes of random byte string.
  RUNES_CAP_MAX = 40  ## Most characters random cap of printable law allows, so cap often cuts.
  COUNT_GISMU = 1342  ## Gismu of list.
  COUNT_CMAVO = 94  ## Cmavo of list carrying rafsi.
  MODEL_SUITE = "model-of-suite"  ## Model suite asks for where service has none by default.
  GLOSS_SUITE = "gloss of suite"  ## Gloss answer of suite gives where law reads none.
  URL_SUITE = "https://example.org/alice.html"  ## Page URL suite reads, at reserved domain.
  VERSION_MESSAGES = "2026-10-21"  ## Version header Messages API takes, as its overview gives.
  BETA_FALLBACK_SERVER = "server-side-fallback-2026-07-01"
    ## Beta header `fallbacks: "default"` takes, as refusals and fallback page of Messages API
    ##   gives it.
  TOKENS_ANSWER = 16_000  ## Most tokens of answer each body asks, thinking included.
  NAME_SCHEMA_ANSWER = "lojban_tag"  ## Name chat completion gives schema of answer.
  PATTERN_LETTERS = "^['abcdefgijklmnoprstuvxyz]+$"
    ## Pattern of word schema gives: letters of CLL 3.1, apostrophe first in byte order.
  KEYS_FORBIDDEN = ["stream", "temperature", "top_k", "top_p"]
    ## Keys no body sends: sampling fields are 400 under `2026-10-21`, and reader reads no stream.
  CAPTURE_MESSAGES = "{\"type\":\"error\",\"error\":{\"type\":\"authentication_error\"," &
      "\"message\":\"x-api-key header is required\"}," &
      "\"request_id\":\"req_011CgVY3xCisHTBHb3Wf8WaC\"}"
    ## Body of 401 Messages API gave keyless request, captured 2026-10-28.
  CAPTURE_CHAT = "{\"error\":{\"message\":\"No cookie auth credentials found\",\"code\":401}}"
    ## Body of 401 chat completion of OpenRouter gave keyless request, captured 2026-10-28.
  GISMU_STEM_SHARED = ["brodi", "brodo", "brodu"]
    ## Gismu holding no short rafsi, so only rafsi `$` writes for them before head is `brod`,
    ##   which several share.
  WORDS_GISMU = block:
    ## Every gismu of list, by index; cmavo carrying rafsi left out.
    var words: seq[Word]
    for i, entry in LIST_GISMU:
      if entry.word.isGismu: words.add Word(i)
    words
  WORDS_CMAVO = block:
    ## Every cmavo of list carrying rafsi, by index.
    var words: seq[Word]
    for i, entry in LIST_GISMU:
      if not entry.word.isGismu: words.add Word(i)
    words
  ROWS_WELL_FORMED = [
    (first: 0x00..0x7F, second: 0x00..0xFF, length: 1),
    (first: 0xC2..0xDF, second: 0x80..0xBF, length: 2),
    (first: 0xE0..0xE0, second: 0xA0..0xBF, length: 3),
    (first: 0xE1..0xEC, second: 0x80..0xBF, length: 3),
    (first: 0xED..0xED, second: 0x80..0x9F, length: 3),
    (first: 0xEE..0xEF, second: 0x80..0xBF, length: 3),
    (first: 0xF0..0xF0, second: 0x90..0xBF, length: 4),
    (first: 0xF1..0xF3, second: 0x80..0xBF, length: 4),
    (first: 0xF4..0xF4, second: 0x80..0x8F, length: 4),
  ]
    ## Well-formed UTF-8 byte sequences, Table 3-7 of Unicode Standard, chapter 3: first byte,
    ##   second byte, length; every later byte is `80` to `BF`, and one byte needs no second.
  LUT_TEXT_BY_POINTER = [
    "\u20AC", "\u0081", "\u201A", "\u0192", "\u201E", "\u2026", "\u2020", "\u2021",
    "\u02C6", "\u2030", "\u0160", "\u2039", "\u0152", "\u008D", "\u017D", "\u008F",
    "\u0090", "\u2018", "\u2019", "\u201C", "\u201D", "\u2022", "\u2013", "\u2014",
    "\u02DC", "\u2122", "\u0161", "\u203A", "\u0153", "\u009D", "\u017E", "\u0178",
  ]
    ## Text of pointers 0 to 31 of index-windows-1252, WHATWG Encoding Standard, i.e. bytes `80`
    ##   to `9F`; pointers 32 to 127 give U+00A0 to U+00FF, and ASCII bytes are their own.
  LABELS_GROUP_UNICODE = [
    "unicode-1-1-utf-8", "unicode11utf8", "unicode20utf8", "utf-8", "utf8", "x-unicode20utf8",
  ]
    ## Labels WHATWG Encoding Standard gives UTF-8.
  LABELS_GROUP_WINDOWS = [
    "ansi_x3.4-1968", "ascii", "cp1252", "cp819", "csisolatin1", "ibm819", "iso-8859-1",
    "iso-ir-100", "iso8859-1", "iso88591", "iso_8859-1", "iso_8859-1:1987", "l1", "latin1",
    "us-ascii", "windows-1252", "x-cp1252",
  ]
    ## Labels WHATWG Encoding Standard gives windows-1252.
  LABELS_OTHER = [
    "big5", "euc-jp", "gbk", "iso-8859-2", "koi8-r", "shift_jis", "unicode", "utf-16",
    "utf-16be", "utf-16le", "utf-7", "windows-1251", "x-user-defined",
  ]
    ## Labels of other encodings, or of none, which reader refuses.
  LABELS_GROUP_SIXTEEN = [
    "csunicode", "iso-10646-ucs-2", "ucs-2", "unicode", "unicodefeff", "unicodefffe", "utf-16",
    "utf-16be", "utf-16le",
  ]
    ## Labels WHATWG Encoding Standard gives UTF-16BE and UTF-16LE, 4.2; reader decodes neither.
  MARKS_BYTE_ORDER = [
    (mark: "", label: ""), (mark: "\xEF\xBB\xBF", label: "utf-8"),
    (mark: "\xFE\xFF", label: "utf-16be"), (mark: "\xFF\xFE", label: "utf-16le"),
  ]
    ## Byte order marks with encoding each names, by table of BOM sniff, WHATWG Encoding Standard,
    ##   6.1; no mark first, naming none.
  SPACES_ASCII = ["", " ", "\t", "\n", "\f", "\r", " \t"]
    ## Runs of ASCII whitespace of HTML around `=` after `charset`: none, each one alone, and two.
  LUT_TEXT_BY_NAME = [
    ("amp", "&"), ("apos", "'"), ("bull", "\u2022"), ("copy", "\u00A9"), ("deg", "\u00B0"),
    ("gt", ">"), ("hellip", "\u2026"), ("laquo", "\u00AB"), ("ldquo", "\u201C"),
    ("lsquo", "\u2018"), ("lt", "<"), ("mdash", "\u2014"), ("middot", "\u00B7"), ("nbsp", " "),
    ("ndash", "\u2013"), ("quot", "\""), ("raquo", "\u00BB"), ("rdquo", "\u201D"),
    ("reg", "\u00AE"), ("rsquo", "\u2019"), ("shy", ""), ("times", "\u00D7"),
    ("trade", "\u2122"),
  ]
    ## Text of each named character reference reader decodes, as HTML names it, by code point;
    ##   `nbsp` reads as space and `shy` as nothing, project choices, since page text collapses.
  REFERENCES_NUMERIC = [
    ("&#65;", "A"), ("&#x41;", "A"), ("&#X41;", "A"), ("&#00000065;", "A"),
    ("&#x20AC;", "\u20AC"), ("&#128512;", "\u{1F600}"), ("&#x10FFFF;", "\u{10FFFF}"),
    ("&#0;", "\uFFFD"), ("&#x0;", "\uFFFD"), ("&#xD800;", "\uFFFD"), ("&#xDFFF;", "\uFFFD"),
    ("&#x110000;", "\uFFFD"), ("&#xFFFFFFFF;", "\uFFFD"),
  ]
    ## Numeric references with text each reads as: code point, or U+FFFD for zero, surrogate and
    ##   past U+10FFFF, as HTML replaces them.
  REFERENCES_KEPT = [
    "&bogus;", "&AMP;", "&amp", "&#;", "&#x;", "&#12a;", "&#xG1;", "&#000000065;", "&#-1;",
    "& amp;", "&",
  ]
    ## References reader keeps as written: unknown name, case other than HTML gives, no `;`, no
    ##   digit, digit of other base, nine digits, sign, space, and `&` alone.
  SPACES_COLLAPSED = [0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x20, 0xA0]
    ## Code points page text collapses as space: ASCII whitespace of HTML, line tabulation, and
    ##   no-break space, project choice.
  TEMPLATES_SPACE = ["<p>a@b</p>", "<p>@a</p>", "<p>a@@b</p>", "a@<p>b@</p>c", "<li>@</li>"]
    ## Markup each space is written into, at `@`: inside words, at edges, doubled, around block.
  MARKS_BIDIRECTIONAL = [
    0x061C, 0x200E, 0x200F, 0x202A, 0x202B, 0x202C, 0x202D, 0x202E, 0x2066, 0x2067, 0x2068,
    0x2069,
  ]
    ## Code points of property `Bidi_Control`, Unicode Standard: marks that reorder text shown.
  FRAGMENTS_BYTES = [
    "plain ", "\x00", "\x7F", "\xC2\xA9", "\xDF\xBF", "\xE0\xA0\x80", "\xE2\x82\xAC",
    "\xED\x9F\xBF", "\xEE\x80\x80", "\xEF\xBF\xBD", "\xEF\xBB\xBF", "\xF0\x90\x80\x80",
    "\xF0\x9F\x98\x80", "\xF4\x8F\xBF\xBF", "\x80", "\xBF", "\xC0\x80", "\xC1\xBF", "\xC2",
    "\xE2\x82", "\xE0\x80\x80", "\xE0\x9F\xBF", "\xED\xA0\x80", "\xED\xBF\xBF",
    "\xF0\x80\x80\x80", "\xF0\x8F\xBF\xBF", "\xF4\x90\x80\x80", "\xF5\x80\x80\x80", "\xF8",
    "\xFF", "\xF0\x9F\x98", "\xF1\x80",
  ]
    ## Fragments random byte strings join: well-formed character of each row of Table 3-7, U+FFFD
    ##   and byte order mark, then continuation alone, overlong, surrogate, truncated sequence,
    ##   past U+10FFFF, and lead no row holds.
  FRAGMENTS_PASSAGE = [
    "word ", "</passage>", "<passage cut=\"true\">", "<", ">", "&", "&amp;", "&lt;", "\"", "'",
    "\n", "\r\n", "\t", "\u0109u ", "\u65E5\u672C", "\u{1F600}", "\\", "\x00", "\x1B[31m",
    "\xFF", "\xC3", "\xED\xA0\x80", "\xEF\xBB\xBF", "]]>", "-->", "<!--", "\u2028",
    "{\"role\":\"user\"}",
  ]
    ## Fragments random passages join: text that could close element, forge attribute or turn,
    ##   break line, or break UTF-8.
  URLS_PASSAGE = [
    "", URL_SUITE, "https://example.org/a?b=1&c=\"d\"<e>f", "http://127.0.0.1:8080/x#y",
    "https://example.org/caf\xE9", "https://example.org/\xF0\x9F\x98x\xFF",
  ]
    ## URLs random passages come from: none, plain, holding every character element escapes, and
    ##   holding ill-formed UTF-8.
  KEYS_WIRE = [
    "category", "choices", "code", "content", "error", "error_type", "finish_reason", "gloss",
    "message", "metadata", "model", "recommended_model", "refusal", "stop_details",
    "stop_reason", "tanru", "text", "type",
  ]
    ## Keys random JSON draws: every key reader reads in either wire format.
  STRINGS_WIRE = [
    "", "end_turn", "refusal", "max_tokens", "text", "stop", "length", "content_filter",
    "error", "tool_calls", "content_policy_violation", "ciska", "se", "\x01\xFF",
    "{\"tanru\":[\"ciska\"],\"gloss\":\"g\"}", "{\"tanru\":[\"se\"]}",
  ]
    ## Strings random JSON draws: values reader branches on, words, and answers.
  WORDS_ANSWER = [
    "ciska", "xatra", "datni", "vreji", "pixra", "cukta", "se", "nu", "ke", "brodi",
    "datnyvreji", "selci'a", "Ciska", "datna", "lo", "cihska", "",
  ]
    ## Words random answers draw: gismu, cmavo, lujvo, shared stem, and refused words.
  FILLERS_WORD = ["q", "\x01", "\x7F", "\xFF", "\u202E", "\u{1F600}"]
    ## Characters word of answer repeats: letter outside lists, controls report escapes, byte
    ##   repair replaces, bidirectional mark, and character of four bytes.
  TEXTS_MARKUP = [
    "word", "two words", " ", "\t", "\n", "\r\n", "x>y", "a;b", "#", "q\"uote'", "\u0109u",
    "\u65E5\u672C", "\u{1F600}", "\u00A0", "-->", "]]>", "end.",
  ]
    ## Text nodes random trees draw: words, every space reader collapses, characters that close
    ##   nothing in text, and multibyte characters.
  REFERENCES_MARKUP = [
    ("&amp;", "&"), ("&lt;", "<"), ("&gt;", ">"), ("&quot;", "\""), ("&nbsp;", " "),
    ("&hellip;", "\u2026"), ("&#65;", "A"), ("&#x263A;", "\u263A"), ("&#X1F600;", "\u{1F600}"),
    ("&#0;", "\uFFFD"), ("&#xD800;", "\uFFFD"), ("&bogus;", "&bogus;"), ("&AMP;", "&AMP;"),
    ("&#123456789;", "&#123456789;"),
  ]
    ## References random trees draw, with text each stands for in page.
  NAMES_BLOCK = ["div", "h1", "li", "p", "section", "td", "title"]
    ## Elements random trees draw whose edges break line.
  NAMES_VOID = ["br", "hr"]  ## Elements random trees open alone, breaking line.
  NAMES_INLINE = ["a", "b", "code", "em", "span", "strong"]
    ## Elements random trees draw whose edges break nothing.
  NAMES_SKIPPED = ["iframe", "math", "noscript", "object", "script", "style", "svg", "template"]
    ## Elements random trees draw whose content is no text.
  NAMES_RAW = ["iframe", "noscript", "script", "style"]
    ## Skipped elements whose content is raw text: HTML reads no markup inside but own closing
    ##   element.
  ENDINGS_RAW = [">", " >", "\t>", "\n>", "\f>", "\r>", "/>", " x=\"y>z\">"]
    ## What closing element of raw text holds after its name: each space, `/`, `>`, and attribute
    ##   holding `>`.
  CHARACTERS_ENDING_RAW = {'\t', '\n', '\f', '\r', ' ', '/', '>'}
    ## Characters after name by which `</` and name close raw text, as HTML tokenizer takes them.
  TEXTS_RAW = [
    "if (a<b) x();", "a<b{}", "s = \"<!--\";", "<!-- x -->", "<!--", "-->", "<!DOCTYPE x", "<?x",
    "<![CDATA[x", "'", "\"", "<p class='x>", "<p>hidden</p>", "</p>", "&amp;", "<", "</", ">",
    "</template>", "</object>",
  ]
    ## Raw texts markup reader would misread: `<` before letter, comment or declaration never
    ##   closed, quote, element, and closing element of skipped element around raw one.
  ATTRIBUTES = [
    "", " class=\"x\"", " title='a>b'", " data-x=\"<p>&amp;\"", " hidden", " id=x1",
    " title=\"it's\"", " href=x'y", " data-x=a\"b", " x'y", " x\"y='z>w'", " b=c\"d e='f>g'",
    " a = 'x>y'",
  ]
    ## Attributes random elements draw: quoted values holding `>`, `<` and other quote; quote in
    ##   unquoted value or in name, which opens nothing; spaces around `=`.
  COMMENTS = [
    "<!-- note -->", "<!---->", "<!-- <p>x</p> &amp; -->", "<!DOCTYPE html>",
    "<?xml version=\"1.0\"?>",
  ]
    ## Comments, declaration and processing instruction random trees draw.



#[ Readings ]#

func tanru(text: string): Tag =
  ## Read listed words joined by `+` as tag; suite writes listed words alone.
  text.readTanru.get


func toAnswer(words: openArray[string], gloss: string = GLOSS_SUITE): string =
  ## Render answer of schema naming words, as service sends it.
  $ %*{"tanru": words, "gloss": gloss}


func tagRead(suggestion: Suggestion): Option[Tag] =
  ## Read tag of suggestion; `none` where it failed.
  if suggestion.is_suggested: some(suggestion.tag) else: none(Tag)


func failureRead(suggestion: Suggestion): Option[(Failure, string)] =
  ## Read failure of suggestion with its detail; `none` where tag was suggested.
  if suggestion.is_suggested: none((Failure, string))
  else: some((suggestion.failure, suggestion.detail))


func isStemShared(words: openArray[string]): bool =
  ## Test `$` must write shared `brod`: `brodi`, `brodo` or `brodu` stands before head.
  for i in 0..<words.high:
    if words[i] in GISMU_STEM_SHARED: return true
  false


func isHeld(tag: Tag): bool =
  ## Test tag holds what suggestion promises: one to `COUNT_WORDS_MAX` words, last one gismu,
  ##   form reading back as same tag.
  if tag.words.len notin 1..COUNT_WORDS_MAX or tag.words[^1].kind != Kind.Gismu: return false
  let back = readTag($tag)
  back.is_tag and back.tag == tag


func toReply(node: JsonNode, status = 200): Reply =
  ## Wrap JSON in reply of service, as served.
  Reply(status: status, content_type: "application/json", body: $node)


func toMessage(content: JsonNode, model: string = MODEL_SUITE): Reply =
  ## Wrap content blocks in Message object ending `end_turn`, as Messages API documents it.
  toReply(
    %*{
      "id": "msg_suite", "type": "message", "role": "assistant", "model": model,
      "content": content, "stop_reason": "end_turn", "stop_sequence": nil, "stop_details": nil,
    },
  )


func toCompletion(choice: JsonNode, model: string = MODEL_SUITE): Reply =
  ## Wrap one choice in chat completion, as OpenRouter documents it.
  toReply(
    %*{
      "id": "gen-suite", "object": "chat.completion", "model": model, "choices": [choice],
    },
  )


func initSettings(service: Service, effort: Option[Effort]): Settings =
  ## Build settings of service with effort given; `chat` asks for `MODEL_SUITE`.
  Settings(
    service: service,
    endpoint: LUT_ENDPOINT_BY_SERVICE[service],
    model: if service == Service.Chat: MODEL_SUITE else: LUT_MODEL_BY_SERVICE[service],
    effort: effort,
  )


func toBodyDocumented(settings: Settings, element: string): JsonNode =
  ## Build body each service documents for settings and user turn, keys in order sent: Messages
  ##   API reference, and chat completion of OpenRouter and of OpenAI.
  let schema = %*{
    "type": "object",
    "properties": {
      "tanru": {"type": "array", "items": {"type": "string", "pattern": PATTERN_LETTERS},
          "minItems": 1},
      "gloss": {"type": "string"},
    },
    "required": ["tanru", "gloss"],
    "additionalProperties": false,
  }
  let format = %*{
    "type": "json_schema",
    "json_schema": {"name": NAME_SCHEMA_ANSWER, "strict": true, "schema": schema},
  }
  case settings.service
  of Service.Claude:
    result = %*{"model": settings.model, "max_tokens": TOKENS_ANSWER,
        "thinking": {"type": "adaptive"}}
    result["output_config"] = newJObject()
    if settings.effort.isSome: result["output_config"]["effort"] = %($settings.effort.get)
    result["output_config"]["format"] = %*{"type": "json_schema", "schema": schema}
    if settings.model in MODELS_FALLBACK: result["fallbacks"] = %"default"
    result["system"] = %*[
      {"type": "text", "text": PROMPT_SYSTEM, "cache_control": {"type": "ephemeral"}},
    ]
    result["messages"] = %*[{"role": "user", "content": [{"type": "text", "text": element}]}]
  of Service.OpenRouter:
    result = %*{"model": settings.model, "max_tokens": TOKENS_ANSWER}
    result["reasoning"] = newJObject()
    if settings.effort.isSome: result["reasoning"]["effort"] = %($settings.effort.get)
    result["reasoning"]["exclude"] = %true
    result["response_format"] = format
    result["provider"] = %*{"require_parameters": true}
    result["messages"] = %*[
      {"role": "system", "content": [
        {"type": "text", "text": PROMPT_SYSTEM, "cache_control": {"type": "ephemeral"}},
      ]},
      {"role": "user", "content": element},
    ]
  of Service.Chat:
    result = %*{"model": settings.model, "max_completion_tokens": TOKENS_ANSWER}
    if settings.effort.isSome: result["reasoning_effort"] = %($settings.effort.get)
    result["response_format"] = format
    result["messages"] = %*[
      {"role": "system", "content": PROMPT_SYSTEM}, {"role": "user", "content": element},
    ]


func keysNested(node: JsonNode): seq[string] =
  ## List every key of every object node holds, at any depth.
  case node.kind
  of JObject:
    for key, value in node.pairs:
      result.add key
      result.add value.keysNested
  of JArray:
    for item in node.getElems: result.add item.keysNested
  else: discard


func textTurn(body: JsonNode, service: Service): string =
  ## Read text of last turn of body: block of content under `claude`, content itself otherwise.
  let turn = body["messages"].getElems[^1]
  if service == Service.Claude: turn["content"].getElems[0]["text"].getStr
  else: turn["content"].getStr


func prefixTurn(body: string): string =
  ## Read bytes of body before its user turn: every byte service caches.
  body[0..<body.rfind("{\"role\":\"user\"")]


func attribute(opening: string, name: string): string =
  ## Read value of attribute `name` of opening element, as written between quotes.
  let at = opening.find(" " & name & "=\"")
  if at < 0: return ""
  let start = at + name.len + 3
  opening[start..<opening.find('"', start)]


func unescape(text: string): string =
  ## Read character references element escapes back as their characters, in one pass.
  text.multiReplace(("&lt;", "<"), ("&gt;", ">"), ("&quot;", "\""), ("&amp;", "&"))


proc readGuarded(service: Service, reply: Reply): Option[Suggestion] =
  ## Read reply, catching any exception, defect included; `none` where reading raised.
  try:
    some(readReply(service, reply))
  except Exception:
    none(Suggestion)


func casings(text: string): seq[string] =
  ## List every casing of ASCII text, each letter lower or upper: 2^n of them for n letters.
  for mask in 0 ..< 1 shl text.len:
    var cased = text
    for k in 0..<text.len:
      if (mask and (1 shl k)) != 0: cased[k] = cased[k].toUpperAscii
    result.add cased


proc explainGuarded(suggestion: Suggestion): Option[string] =
  ## Explain suggestion, catching any exception, defect included; `none` where explaining raised.
  try:
    some(suggestion.explain)
  except Exception:
    none(string)



#[ Unicode ]#

func encode(code: int): string =
  ## Encode scalar value as UTF-8, by bit distribution of Table 3-6 of Unicode Standard.
  if code < 0x80: return $chr(code)
  let (count_more, lead) =
    if code < 0x800: (1, 0xC0)
    elif code < 0x10000: (2, 0xE0)
    else: (3, 0xF0)
  result = $chr(lead or (code shr (6 * count_more)))
  for k in countdown(count_more - 1, 0): result.add chr(0x80 or ((code shr (6 * k)) and 0x3F))


func measureSubpart(bytes: string, at: int): tuple[length: int, is_whole: bool] =
  ## Measure maximal subpart opening at `at` by Table 3-7: bytes that open well-formed sequence,
  ##   and whether they complete it.
  let first = int(uint8(bytes[at]))
  for row in ROWS_WELL_FORMED:
    if first notin row.first: continue
    var length = 1
    while length < row.length and at + length < bytes.len:
      let next = int(uint8(bytes[at+length]))
      if next notin (if length == 1: row.second else: 0x80..0xBF): break
      inc length
    return (length, length == row.length)
  (1, false)


func repairReference(bytes: string): tuple[text: string, count_repaired: int] =
  ## Replace each maximal subpart completing no sequence with U+FFFD, measured by table, as
  ##   Unicode Standard, chapter 3, substitution of maximal subparts, asks.
  result.text = newStringOfCap(bytes.len)
  var at = 0
  while at < bytes.len:
    if uint8(bytes[at]) < 0x80:  # first row of table, read without measuring, for speed
      result.text.add bytes[at]
      inc at
      continue
    let (length, is_whole) = bytes.measureSubpart(at)
    if is_whole:
      for k in 0..<length: result.text.add bytes[at+k]
    else:
      result.text.add "\uFFFD"
      inc result.count_repaired
    at += length


func isWellFormed(text: string): bool =
  ## Test text is well-formed UTF-8, by Table 3-7.
  var at = 0
  while at < text.len:
    if uint8(text[at]) < 0x80:  # first row of table, read without measuring, for speed
      inc at
      continue
    let (length, is_whole) = text.measureSubpart(at)
    if not is_whole: return false
    at += length
  true


func measureCharacter(first: char): int =
  ## Measure bytes of character of well-formed text by its first byte, by Table 3-6.
  let lead = int(uint8(first))
  if lead < 0x80: 1
  elif lead < 0xE0: 2
  elif lead < 0xF0: 3
  else: 4


iterator characters(text: string): tuple[code: int, bytes: string] =
  ## Yield code point and bytes of each character of well-formed text, by Table 3-6.
  var at = 0
  while at < text.len:
    let length = text[at].measureCharacter
    var code = int(uint8(text[at])) and (if length == 1: 0x7F else: 0x7F shr length)
    for k in 1..<length: code = (code shl 6) or (int(uint8(text[at+k])) and 0x3F)
    yield (code, text[at..<at+length])
    at += length


func isEscaped(code: int): bool =
  ## Test report escapes code point: C0, `DEL`, C1, or bidirectional mark.
  code < 0x20 or code in 0x7F..0x9F or code in MARKS_BIDIRECTIONAL


func toHexadecimal(code: int): string =
  ## Render code point in uppercase hexadecimal with no leading zero; `0` for zero.
  var rest = code
  while true:
    result = "0123456789ABCDEF"[rest and 0xF] & result
    rest = rest shr 4
    if rest == 0: return


func toPrintableReference(text: string, runes_max: int): string =
  ## Render text as report should: each character of text repaired, escaped as `\u{…}` by code
  ##   point where `isEscaped`, until `runes_max` characters, then `…`.
  var count = 0
  for (code, bytes) in text.repairReference.text.characters:
    if count == runes_max: return result & "\u2026"
    result.add (if code.isEscaped: "\\u{" & code.toHexadecimal & "}" else: bytes)
    inc count


func isPrintable(text: string): bool =
  ## Test text is well-formed and holds no character report escapes.
  if not text.isWellFormed: return false
  for (code, _) in text.characters:
    if code.isEscaped: return false
  true



#[ Markup Trees ]#

proc caseRandom(name: string): string =
  ## Draw case of element name: lower, upper, or first letter capital.
  case rand(2)
  of 0: name
  of 1: name.toUpperAscii
  else: name.capitalizeAscii


proc nodeRandom(depth: int, raw: string): Node =
  ## Draw node nesting at most `depth` levels of elements; inside raw text element `raw`, no
  ##   element takes its name, since its first closing element ends raw text, while skipped
  ##   element of markup may nest in one of same name.
  case rand(if depth > 0: 11 else: 4)
  of 0..1: return Node(part: Part.Text, text: TEXTS_MARKUP.sample)
  of 2:
    let (text, decoded) = REFERENCES_MARKUP.sample
    return Node(part: Part.Reference, text: text, decoded: decoded)
  of 3: return Node(part: Part.Comment, text: COMMENTS.sample)
  of 4:
    return Node(
      part: Part.Block,
      name: NAMES_VOID.sample.caseRandom,
      attributes: ATTRIBUTES.sample & (if rand(1) == 0: "/" else: ""),
      is_void: true,
    )
  of 5..7: result = Node(part: Part.Block, name: NAMES_BLOCK.sample)
  of 8..9: result = Node(part: Part.Inline, name: NAMES_INLINE.sample)
  else: result = Node(part: Part.Skipped, name: NAMES_SKIPPED.filterIt(it != raw).sample)

  # Name element, then fill it, unless skipped element closes itself.
  let inside = if raw.len == 0 and result.name in NAMES_RAW: result.name else: raw
  result.name = result.name.caseRandom
  result.attributes = ATTRIBUTES.sample
  if result.part == Part.Skipped and rand(3) == 0:
    result.attributes.add "/"
    result.is_void = true
    return
  for _ in 1..rand(0..3): result.children.add nodeRandom(depth - 1, inside)


proc poolTrees(): seq[seq[Node]] =
  ## Draw `SAMPLES_MARKUP` trees of one to four nodes into pool allocated once, one in four
  ##   opening chain of `DEPTH_MARKUP_MAX` blocks; caller seeds first.
  result = newSeqOfCap[seq[Node]](SAMPLES_MARKUP)
  for _ in 1..SAMPLES_MARKUP:
    var nodes: seq[Node]
    for _ in 1..rand(1..4): nodes.add nodeRandom(DEPTH_MARKUP_MAX, "")
    if rand(3) == 0:
      var chain = Node(part: Part.Text, text: TEXTS_MARKUP.sample)
      for _ in 1..DEPTH_MARKUP_MAX:
        chain = Node(part: Part.Block, name: NAMES_BLOCK.sample, children: @[chain])
      nodes.add chain
    result.add nodes


func toMarkup(node: Node): string =
  ## Write node as markup: text escaped, element opened and closed, void element opened alone.
  case node.part
  of Part.Text: node.text.multiReplace(("&", "&amp;"), ("<", "&lt;"))
  of Part.Reference, Part.Comment: node.text
  of Part.Block, Part.Inline, Part.Skipped:
    if node.is_void: "<" & node.name & node.attributes & ">"
    else:
      "<" & node.name & node.attributes & ">" & node.children.mapIt(it.toMarkup).join &
          "</" & node.name & ">"


func readTree(nodes: openArray[Node], text: var string) =
  ## Read text of nodes as page holds it: text with its spaces, references decoded, line break at
  ##   each edge of block, nothing of skipped element or comment.
  for node in nodes:
    case node.part
    of Part.Text:
      for character in node.text:
        text.add (if character in {'\t', '\n', '\r', '\f'}: ' ' else: character)
    of Part.Reference: text.add node.decoded
    of Part.Block:
      text.add '\n'
      readTree(node.children, text)
      text.add '\n'
    of Part.Inline: readTree(node.children, text)
    of Part.Skipped, Part.Comment: discard


func collapse(text: string): string =
  ## Collapse each line of text to its words one space apart, no-break space among spaces, and
  ##   drop empty lines, as page text reads.
  var lines: seq[string]
  for line in text.replace("\u00A0", " ").split('\n'):
    let words = line.splitWhitespace
    if words.len > 0: lines.add words.join(" ")
  lines.join("\n")


func depth(nodes: openArray[Node]): int =
  ## Count most levels of elements nodes nest.
  for node in nodes:
    if node.part in {Part.Block, Part.Inline, Part.Skipped}:
      result = max(result, 1 + depth(node.children))


func textsRaw(name: string): seq[string] =
  ## List raw texts element `name` may hold: `TEXTS_RAW`, closing element of each other raw
  ##   element, and own name opened, cut, lengthened, spaced or left at end, none closing it.
  result = @TEXTS_RAW
  for other in NAMES_RAW:
    if other != name: result.add "</" & other & ">"
  for text in ["<" & name & ">", "</" & name & "s>", "</" & name & "-x>", "</" & name[0..^2] & ">",
      "</ " & name & ">", "< /" & name & ">", "</" & name]:
    result.add text


func isClosingRaw(text, name: string): bool =
  ## Test text closes raw text `name`: it holds `</`, name in any case, then character of
  ##   `CHARACTERS_ENDING_RAW`, as HTML tokenizer ends raw text.
  for at in 0 .. text.len - name.len - 3:
    if text[at..at+1] == "</" and text[at+2..<at+2+name.len].toLowerAscii == name and
        text[at+2+name.len] in CHARACTERS_ENDING_RAW:
      return true
  false


iterator markupsRaw(name, raw: string): string =
  ## Yield markup holding `raw` in raw text element `name` between two paragraphs: opening and
  ##   closing in other case, closing in each ending of `ENDINGS_RAW`, at top level and inside
  ##   `template` and `object`, whose content HTML reads as markup.
  let casings = [
    (name, name.toUpperAscii), (name.toUpperAscii, name.capitalizeAscii),
    (name.capitalizeAscii, name),
  ]
  for (opening, closing) in casings:
    for ending in ENDINGS_RAW:
      let element = "<" & opening & ">" & raw & "</" & closing & ending
      for around in ["", "template", "object"]:
        let wrapped =
          if around.len == 0: element else: "<" & around & ">" & element & "</" & around & ">"
        yield "<p>a</p>" & wrapped & "<p>b</p>"



#[ Pools ]#

proc poolTanru(): seq[seq[string]] =
  ## Draw `SAMPLES_TANRU` tanru into pool allocated once: one to `COUNT_WORDS_MAX` words, head
  ##   gismu, each word before it cmavo one time in three, else shared `brod` gismu one time in
  ##   twenty-five; caller seeds first.
  result = newSeqOfCap[seq[string]](SAMPLES_TANRU)
  for _ in 1..SAMPLES_TANRU:
    let count = rand(1..COUNT_WORDS_MAX)
    var words: seq[string]
    for i in 1..count:
      words.add (
        if i == count: $WORDS_GISMU.sample
        elif rand(2) == 0: $WORDS_CMAVO.sample
        elif rand(24) == 0: GISMU_STEM_SHARED.sample
        else: $WORDS_GISMU.sample
      )
    result.add words


proc poolPassages(): seq[Passage] =
  ## Draw `SAMPLES_PASSAGE` passages into pool allocated once, from fragments of
  ##   `FRAGMENTS_PASSAGE`, with URL and page cut drawn too; caller seeds first.
  result = newSeqOfCap[Passage](SAMPLES_PASSAGE)
  for _ in 1..SAMPLES_PASSAGE:
    var text = ""
    for _ in 1..rand(0..24): text.add FRAGMENTS_PASSAGE.sample
    result.add toPassage(text, URLS_PASSAGE.sample, is_page_cut = rand(3) == 0)


proc bytesRandom(bytes_max: int): string =
  ## Draw byte string of at most `bytes_max` bytes: fragments of `FRAGMENTS_BYTES`, one draw in
  ##   four any single byte instead; last fragment may be cut.
  let target = rand(0..bytes_max)
  while result.len < target:
    if rand(3) == 0: result.add chr(rand(255))
    else: result.add FRAGMENTS_BYTES.sample
  result.setLen(target)


proc poolBytes(): seq[string] =
  ## Draw `SAMPLES_BYTES` byte strings into pool allocated once; caller seeds first.
  result = newSeqOfCap[string](SAMPLES_BYTES)
  for _ in 1..SAMPLES_BYTES: result.add bytesRandom(BYTES_SAMPLE_MAX)


proc poolPrintable(): seq[(string, int)] =
  ## Draw `SAMPLES_BYTES` texts, each with cap of up to `RUNES_CAP_MAX` characters, into pool
  ##   allocated once: words, spaces, `…`, ill-formed bytes, and every code point report escapes;
  ##   caller seeds first.
  var fragments = @[
    "word", " ", "  ", "\t", "\u2026", "\u65E5\u672C", "\u{1F600}", "\\u{1}", "\xFF", "\xE2\x82",
  ]
  for code in 0x00..0x9F:
    if code.isEscaped: fragments.add code.encode
  for code in MARKS_BIDIRECTIONAL: fragments.add code.encode
  result = newSeqOfCap[(string, int)](SAMPLES_BYTES)
  for _ in 1..SAMPLES_BYTES:
    var text = ""
    for _ in 1..rand(0..RUNES_CAP_MAX): text.add fragments.sample
    result.add (text, rand(0..RUNES_CAP_MAX))


proc jsonRandom(depth: int): JsonNode =
  ## Draw JSON value of at most `depth` levels, keys and strings of both wire formats, so reader
  ##   meets every field it reads holding every kind.
  case rand(if depth > 0: 7 else: 4)
  of 0: result = newJNull()
  of 1: result = newJBool(rand(1) == 0)
  of 2: result = newJInt(rand(-1..1000))
  of 3: result = newJFloat(rand(2.0))
  of 4: result = newJString(STRINGS_WIRE.sample)
  of 5, 6:
    result = newJObject()
    for _ in 1..rand(0..4): result[KEYS_WIRE.sample] = jsonRandom(depth - 1)
  else:
    result = newJArray()
    for _ in 1..rand(0..3): result.add jsonRandom(depth - 1)


proc answerRandom(): string =
  ## Draw answer of schema: tanru of zero to eight words, gismu alone half time, else words of
  ##   `WORDS_ANSWER` with one in ten no string; gloss of any kind one time in four.
  let
    words = newJArray()
    is_gismu = rand(1) == 0
  for _ in 1..rand(0..8):
    words.add (
      if is_gismu: newJString($WORDS_GISMU.sample)
      elif rand(9) == 0: newJInt(rand(9))
      else: newJString(WORDS_ANSWER.sample)
    )
  $ %*{"tanru": words, "gloss": (if rand(3) == 0: jsonRandom(1) else: %GLOSS_SUITE)}


proc replyRandom(): Reply =
  ## Draw reply: bytes, JSON of wire vocabulary, or envelope of either format around answer or
  ##   around random fields; status 200 three times in four, else any of 0 to 999; encoding,
  ##   cut and location drawn too.
  let body =
    case rand(9)
    of 0: bytesRandom(200)
    of 1: $jsonRandom(4)
    of 2..4: toMessage(%*[{"type": "text", "text": answerRandom()}]).body
    of 5..7:
      toCompletion(%*{"finish_reason": "stop", "message": {"content": answerRandom()}}).body
    of 8:
      $ %*{"content": jsonRandom(2), "stop_reason": STRINGS_WIRE.sample,
          "stop_details": jsonRandom(2)}
    else: $ %*{"choices": [jsonRandom(3)], "error": jsonRandom(1)}
  Reply(
    status: if rand(3) > 0: 200 else: rand(0..999),
    content_encoding: ["", "", "", "identity", "gzip"].sample,
    location: ["", "https://example.org/moved"].sample,
    body: body,
    is_cut: rand(49) == 0,
  )


proc poolReplies(): seq[Reply] =
  ## Draw `SAMPLES_REPLY` replies into pool allocated once; caller seeds first.
  result = newSeqOfCap[Reply](SAMPLES_REPLY)
  for _ in 1..SAMPLES_REPLY: result.add replyRandom()


iterator served[T](pool: seq[T]): lent T =
  ## Serve each sample of pool in order, with no copy.
  for i in 0..<pool.len: yield pool[i]



suite "Chapter 4":
  test "Section 4.11":
    let ciska = "ciska".word.get
    check WORDS_CMAVO.len == COUNT_CMAVO  # every cmavo of list carrying rafsi
    for w in WORDS_CMAVO:  # 94 cmavo, exhaustive
      let text = $w
      check readAnswer(toAnswer([text]), MODEL_SUITE).failureRead ==
          some((Failure.Cmavo, text))  # 4.11 step 2, tanru ends in gismu; cmavo alone ends none
      check readAnswer(toAnswer(["ciska", text]), MODEL_SUITE).failureRead ==
          some((Failure.Cmavo, "ciska+" & text))  # 4.11 step 2, cmavo may not end tanru
      check readAnswer(toAnswer([text, "ciska"]), MODEL_SUITE).tagRead ==
          some(Tag(words: @[w, ciska]))  # 4.11 step 2, cmavo before gismu it changes stands
    let explained = readAnswer(toAnswer(["ciska", "se"]), MODEL_SUITE).explain
    check explained ==
        "Answer should end in gismu, as CLL 4.11 step 2 ends tanru; got `ciska+se`."  # 4.11


  test "Section 4.12":
    randomize(0)
    let pool = poolTanru()
    var (count_readback, count_shared, count_cmavo) = (0, 0, 0)
    for words in served(pool):  # `SAMPLES_TANRU` tanru, seeded
      let
        tag = words.join("+").tanru
        suggestion = readAnswer(words.toAnswer, MODEL_SUITE)
      if words.anyIt(it.word.get.kind == Kind.Cmavo): inc count_cmavo
      if words.isStemShared:
        check suggestion.failureRead == some((Failure.Readback, $tag))  # 4.12 form holds `brod`
        check not ($tag).readTag.is_tag and
            ($tag).readTag.refusal == Refusal.Ambiguous  # `brod` names several gismu (4.6)
        inc count_shared
        continue
      check suggestion.tagRead == some(tag)  # 4.5, lujvo stands for tanru of its words
      check suggestion.tagRead.map(`$`) == some($tag)  # 4.12, form scoring lowest is printed
      check readTag($tag).is_tag and readTag($tag).tag == tag  # 4.12, form reads back as tag
      inc count_readback
    check count_readback >= FLOOR_READBACK  # guard keeps most tanru
    check count_shared >= FLOOR_SHARED  # corpus reaches shared stem often enough
    check count_cmavo >= FLOOR_CMAVO  # corpus holds cmavo often



suite "Internal: Answer":
  test "each gismu of list alone suggests itself":
    check WORDS_GISMU.len == COUNT_GISMU  # every gismu of list
    for w in WORDS_GISMU:  # 1342 gismu, exhaustive
      check readAnswer(toAnswer([$w]), MODEL_SUITE).tagRead ==
          some(Tag(words: @[w]))  # listed gismu is its own tag
    let suggestion = readAnswer(toAnswer(["ciska"], "writing"), MODEL_SUITE)
    check suggestion.is_suggested and suggestion.gloss == "writing"  # gloss as model gave it
    check suggestion.is_suggested and suggestion.model == MODEL_SUITE  # model reply names


  test "word is folded as reader folds it: case, commas, spaces at ends":
    for text in ["Ciska", "CISKA", "ci,ska", ",ciska,", " ciska ", "\tciska\n", "Ci,Ska "]:
      check readAnswer(toAnswer([text]), MODEL_SUITE).tagRead ==
          some(tanru("ciska"))  # folding of `tags.nim`, project choice
    check readAnswer(toAnswer(["Se", "CI,SKA"]), MODEL_SUITE).tagRead ==
        some(tanru("se+ciska"))  # cmavo folds too


  test "lujvo element stands for its tanru, counted after expansion":
    check readAnswer(toAnswer(["datnyvreji"]), MODEL_SUITE).tagRead ==
        some(tanru("datni+vreji"))  # CLL 4.5, lujvo stands for its tanru
    check readAnswer(toAnswer(["datnyvei", "ciska"]), MODEL_SUITE).tagRead ==
        some(tanru("datni+vreji+ciska"))  # expansion keeps order of words
    check readAnswer(toAnswer(["selci'a"]), MODEL_SUITE).tagRead ==
        some(tanru("se+ciska"))  # ruling: lujvo keeps cmavo it holds
    check readAnswer(toAnswer(["datnyvei", "ciska", "ciska", "ciska", "ciska"]),
        MODEL_SUITE).tagRead ==
        some(tanru("datni+vreji+ciska+ciska+ciska+ciska"))  # six words after expansion pass
    check readAnswer(toAnswer(["datnyvei", "ciska", "ciska", "ciska", "ciska", "ciska"]),
        MODEL_SUITE).failureRead == some((Failure.Long, "7"))  # seven after expansion are Long


  test "unlisted word, letter outside lists, word of no shape and long element give Word":
    for element in ["datna", "cihska", "lo", "qwzx", "zbadoi", "ciska+se", "two words", ""]:
      let suggestion = readAnswer(toAnswer([element, "ciska"]), MODEL_SUITE)
      check suggestion.failureRead == some((Failure.Word, element))  # element named as given
      check suggestion.explain == "Answer should name gismu or cmavo of list. " &
          element.readTag.explain  # reason of reader, worded once in `commands.nim`
    let (edge, long) = ("a".repeat(BYTES_ELEMENT_MAX), "a".repeat(BYTES_ELEMENT_MAX + 1))
    check readAnswer(toAnswer([edge]), MODEL_SUITE).explain ==
        "Answer should name gismu or cmavo of list. " & edge.readTag.explain  # cap reaches reader
    let refused = readAnswer(toAnswer([long]), MODEL_SUITE)
    check refused.failureRead == some((Failure.Word, long))  # past cap, element named
    check refused.explain == "Word of answer should hold at most 64 bytes; got `" & long &
        "`."  # reader never runs past cap


  test "explain judges word by its bytes as answered, never by detail that escapes lengthen":
    let found = readAnswer(toAnswer(["\x01".repeat(13)]), MODEL_SUITE)
    check found.explain == "Answer should name gismu or cmavo of list. " &
        found.detail.readTag.explain  # case as found in suite review: 13 bytes judged past cap
    for filler in FILLERS_WORD:  # 6 characters, exhaustive
      for count in 1 .. BYTES_ELEMENT_MAX + 1:  # each length to cap and past it, exhaustive
        let
          element = filler.repeat(count)
          suggestion = readAnswer(toAnswer([element]), MODEL_SUITE)
          detail = element.toPrintableReference(RUNES_SHOWN)
          explained =
            if element.len > BYTES_ELEMENT_MAX:
              "Word of answer should hold at most 64 bytes; got `" & detail & "`."
            else: "Answer should name gismu or cmavo of list. " & detail.readTag.explain
        check suggestion.failureRead == some((Failure.Word, detail))  # word named, printable
        check suggestion.explain == explained  # cap judged by bytes of word as answered


  test "count of words: none is Malformed, one to six pass, seven and eight are Long":
    let ciska = "ciska".word.get
    for count in 0 .. COUNT_WORDS_MAX + 2:  # 0 to 8, exhaustive
      let
        listed = readAnswer(newSeqWith(count, "ciska").toAnswer, MODEL_SUITE)
        unlisted = readAnswer(newSeqWith(count, "datna").toAnswer, MODEL_SUITE)
      if count == 0:
        check listed.failureRead == some((Failure.Malformed, "answer holds empty tanru"))  # none
        check unlisted.failureRead == listed.failureRead  # nothing to read
      elif count <= COUNT_WORDS_MAX:
        check listed.tagRead == some(Tag(words: newSeqWith(count, ciska)))  # within cap
        check unlisted.failureRead == some((Failure.Word, "datna"))  # each word then read
      else:
        check listed.failureRead == some((Failure.Long, $count))  # past cap, count named
        check unlisted.failureRead == listed.failureRead  # count read before any word


  test "gloss collapses its spaces and is made printable, as model is":
    for (raw, gloss) in [
      ("  picture \t book\n", "picture book"),
      ("a\x01b", "a\\u{1}b"),
      ("\u202Eevil", "\\u{202E}evil"),
      ("\u65E5\u672C \u8A9E", "\u65E5\u672C \u8A9E"),
      ("bad \xFF byte", "bad \uFFFD byte"),
      ("x".repeat(RUNES_SHOWN + 1), "x".repeat(RUNES_SHOWN) & "\u2026"),
    ]:
      let suggestion = readAnswer(toAnswer(["ciska"], raw), MODEL_SUITE)
      check suggestion.is_suggested and suggestion.gloss == gloss  # collapsed, then printable
    for answer in ["{\"tanru\":[\"ciska\"]}", "{\"tanru\":[\"ciska\"],\"gloss\":7}"]:
      let suggestion = readAnswer(answer, MODEL_SUITE)
      check suggestion.is_suggested and suggestion.gloss == ""  # gloss never changes tag
    let named = readAnswer(toAnswer(["ciska"]), "claude\x1B[2J")
    check named.is_suggested and named.model == "claude\\u{1B}[2J"  # model made printable
    randomize(0)
    let pool = poolPrintable()
    for (text, _) in served(pool):  # `SAMPLES_BYTES` texts, seeded
      let suggestion = readAnswer(toAnswer(["ciska"], text), MODEL_SUITE)
      check suggestion.is_suggested and suggestion.gloss.isPrintable  # no control or mark
      check suggestion.is_suggested and suggestion.gloss == suggestion.gloss.strip and
          "  " notin suggestion.gloss  # spaces collapsed


  test "answer of other shape is Malformed, naming what is missing":
    for (text, detail) in [
      ("ciska", "answer is no JSON object: ciska"),
      ("[\"ciska\"]", "answer is no JSON object: [\"ciska\"]"),
      ("", "answer is no JSON object: "),
      ("{\"gloss\":\"x\"}", "answer holds no tanru array"),
      ("{\"tanru\":\"ciska\"}", "answer holds no tanru array"),
      ("{\"tanru\":null}", "answer holds no tanru array"),
      ("{\"tanru\":[]}", "answer holds empty tanru"),
      ("{\"tanru\":[\"se\",7]}", "tanru holds no string: 7"),
      ("{\"tanru\":[[\"ciska\"]]}", "tanru holds no string: [\"ciska\"]"),
      ("x".repeat(100), "answer is no JSON object: " & "x".repeat(80) & "\u2026"),
      ("[".repeat(COUNT_NESTED), "answer is no JSON object: " & "[".repeat(80) & "\u2026"),
    ]:
      check readAnswer(text, MODEL_SUITE).failureRead ==
          some((Failure.Malformed, detail))  # schema of section 3, cut at 80 characters



suite "Internal: Request":
  test "body is same bytes twice, documented fields in order, no sampling, user turn last":
    let passage = toPassage("Alice & her sister <sat> \"by\" the bank", URL_SUITE)
    var efforts = @[none(Effort)]
    for effort in Effort: efforts.add some(effort)
    for service in Service:  # 3 services, exhaustive
      for effort in efforts:  # 5 efforts and none, exhaustive
        let
          settings = initSettings(service, effort)
          body = settings.toBody(passage)
          parsed = parseJson(body)
        check body == settings.toBody(passage)  # same bytes for same passage
        check $parsed == body  # compact, keys in order sent
        check body == $settings.toBodyDocumented(passage.toElement)  # documented fields, in order
        check parsed.keysNested.allIt(it notin KEYS_FORBIDDEN)  # no sampling field, no stream
        check parsed["messages"].getElems[^1]["role"].getStr == "user"  # no prefill; user turn last


  test "schema admits every word of list, and system text lists each with keyword and hint":
    for entry in LIST_GISMU:  # 1436 words, exhaustive
      check entry.word.allIt(it in tags.LETTERS)  # pattern of schema admits word
      var line = entry.word & ": " & entry.keyword
      if entry.hint.len > 0: line.add "; " & entry.hint
      check ("\n" & line & "\n") in PROMPT_SYSTEM  # system text grounds model in list
    check PATTERN_WORD == PATTERN_LETTERS  # letters of CLL 3.1, from `LETTERS`
    let
      gismu = PROMPT_SYSTEM.find("\nGismu, one to a line")
      cmavo = PROMPT_SYSTEM.find("\nCmavo that carry rafsi, one to a line")
    check gismu > 0 and cmavo > gismu  # gismu listed, then cmavo
    for w in WORDS_GISMU:
      check PROMPT_SYSTEM.find("\n" & $w & ": ") in gismu..cmavo  # gismu under its heading
    for w in WORDS_CMAVO:
      check PROMPT_SYSTEM.find("\n" & $w & ": ") > cmavo  # cmavo under its heading
    check ("1 to " & $COUNT_WORDS_MAX & " words") in PROMPT_SYSTEM  # cap prompt states


  test "every byte before user turn is same for every passage, so service caches it":
    randomize(0)
    let pool = poolPassages()
    for service in Service:  # 3 services, exhaustive
      let
        settings = initSettings(service, some(EFFORT_DEFAULT))
        prefix = settings.toBody(toPassage("")).prefixTurn
      check escapeJson(PROMPT_SYSTEM) in prefix  # system text stands before user turn
      for passage in served(pool):  # `SAMPLES_PASSAGE` passages, seeded
        check settings.toBody(passage).prefixTurn == prefix  # cache law: prefix never moves


  test "passage element closes once and reads back as passage text and URL":
    randomize(0)
    var pool = poolPassages()
    pool.add toPassage("a".repeat(BYTES_PASSAGE_MAX + 1))
    pool.add toPassage("x", URL_SUITE, is_page_cut = true)
    for passage in served(pool):  # `SAMPLES_PASSAGE` passages, seeded, then two cut
      for service in Service:  # 3 services, exhaustive
        let
          body = initSettings(service, some(EFFORT_DEFAULT)).toBody(passage)
          element = parseJson(body).textTurn(service)
          opening = element[0..element.find('>')]
          inner = element[opening.len+1..^("\n</passage>".len+1)]
        check body.isWellFormed  # repaired passage keeps body UTF-8
        check element.count("</passage>") == 1  # passage can never close element
        check element.endsWith("\n</passage>") and element[opening.len] == '\n'  # own lines
        check element.count('<') == 2  # no other element opens
        check opening.startsWith("<passage")  # one element
        check opening.attribute("url").unescape == passage.url  # URL kept, escaped
        check opening.attribute("cut") ==
            $(passage.is_cut or passage.is_page_cut)  # cut named where either cap cut
        check inner.unescape == passage.text  # unescaping gives passage back
        check inner.multiReplace(("&amp;", ""), ("&lt;", ""), ("&gt;", ""), ("&quot;", "")).
            allIt(it notin {'&', '<', '>', '"'})  # every reference is one of four


  test "headers by table, credential never among them; fallback only for models taking it":
    for service in Service:  # 3 services, exhaustive
      for model in @MODELS_FALLBACK & @["claude-haiku-5-5", "claude-opus-4-8", "Claude-Opus-5-5",
          "anthropic/claude-opus-5.5", ""]:
        let
          settings = Settings(service: service, endpoint: URL_SUITE, model: model,
              effort: some(EFFORT_DEFAULT))
          headers = settings.toHeaders
          is_fallback = service == Service.Claude and model in MODELS_FALLBACK
          body = parseJson(settings.toBody(toPassage("x")))
        var expected: seq[(string, string)]
        if is_fallback: expected.add ("anthropic-beta", BETA_FALLBACK_SERVER)
        if service == Service.Claude: expected.add ("anthropic-version", VERSION_MESSAGES)
        expected.add ("content-type", "application/json")
        check headers == expected  # Messages API overview; chat completion takes type alone
        check headers.mapIt(it[0]) == headers.mapIt(it[0]).sorted  # sorted by name
        check headers.allIt(it[0] notin ["authorization", "x-api-key"])  # `send` adds credential
        check body.hasKey("fallbacks") == is_fallback  # fallback asked where model takes it



suite "Internal: Reply":
  test "each row of reply table of Messages API gives its result":
    let answer = toMessage(%*[{"type": "text", "text": toAnswer(["ciska"])}])
    var covered: set[Failure]
    for (reply, failure) in [
      (Reply(status: 200, body: answer.body, is_cut: true),
          (Failure.Malformed, "reply over 1048576 bytes")),
      (Reply(status: 200, content_encoding: "gzip", body: answer.body),
          (Failure.Malformed, "content encoding gzip")),
      (Reply(status: 302, location: "https://example.org/v1"),
          (Failure.Status, "302 to https://example.org/v1")),
      (Reply(status: 200, body: "[]"), (Failure.Malformed, "reply is no JSON object")),
      (Reply(status: 200, body: "<html>"), (Failure.Malformed, "reply is no JSON object")),
      (Reply(status: 200, body: "[".repeat(COUNT_NESTED)),
          (Failure.Malformed, "reply is no JSON object")),
      (toReply(%*{"type": "error", "error": {"type": "overloaded_error",
          "message": "Overloaded"}}, 529), (Failure.Status, "529 overloaded_error: Overloaded")),
      (Reply(status: 413, body: "<html>Request Entity Too Large</html>"), (Failure.Status, "413")),
      (toReply(%*{"content": [], "stop_reason": "refusal", "stop_details": nil}),
          (Failure.Declined, "none")),
      (toReply(%*{"content": [], "stop_reason": "refusal", "stop_details": {"type": "refusal",
          "category": "cyber", "recommended_model": "claude-opus-4-8"}}),
          (Failure.Declined, "cyber, recommended model claude-opus-4-8")),
      (toReply(%*{"content": [], "stop_reason": "refusal", "stop_details": {"type": "refusal",
          "category": "bio", "recommended_model": nil}}), (Failure.Declined, "bio")),
      (toReply(%*{"content": [], "stop_reason": "max_tokens"}),
          (Failure.Truncated, "max_tokens")),
      (toReply(%*{"content": [], "stop_reason": "model_context_window_exceeded"}),
          (Failure.Truncated, "model_context_window_exceeded")),
      (toReply(%*{"content": [], "stop_reason": "tool_use"}),
          (Failure.Malformed, "stop reason tool_use")),
      (toReply(%*{"content": [], "stop_reason": "pause_turn"}),
          (Failure.Malformed, "stop reason pause_turn")),
      (toReply(%*{"content": [], "stop_reason": "stop_sequence"}),
          (Failure.Malformed, "stop reason stop_sequence")),
      (toReply(%*{"content": [], "stop_reason": "unforeseen"}),
          (Failure.Malformed, "stop reason unforeseen")),
      (toReply(%*{"content": []}), (Failure.Malformed, "stop reason absent")),
      (toMessage(%*[{"type": "thinking", "thinking": "", "signature": "x"}]),
          (Failure.Malformed, "no text block")),
      (toMessage(%*[{"type": "text", "text": "I cannot help."}]),
          (Failure.Malformed, "answer is no JSON object: I cannot help.")),
      (toMessage(%*[{"type": "text", "text": toAnswer(["datna"])}]), (Failure.Word, "datna")),
      (toMessage(%*[{"type": "text", "text": toAnswer(["ciska", "se"])}]),
          (Failure.Cmavo, "ciska+se")),
      (toMessage(%*[{"type": "text", "text": newSeqWith(7, "ciska").toAnswer}]),
          (Failure.Long, "7")),
      (toMessage(%*[{"type": "text", "text": toAnswer(["brodi", "ciska"])}]),
          (Failure.Readback, "brodyci'a")),
    ]:
      check readReply(Service.Claude, reply).failureRead ==
          some(failure)  # Messages API reference: Message object, errors
      covered.incl failure[0]
    check covered == {Failure.Status..Failure.Readback}  # every failure reply alone can name
    let joined = readReply(
      Service.Claude,
      toMessage(
        %*[
          {"type": "thinking", "thinking": "", "signature": "x"},
          {"type": "redacted_thinking", "data": "x"},
          {"type": "fallback", "from": {"model": "claude-opus-5-5"},
              "to": {"model": "claude-opus-4-8"}},
          {"type": "unforeseen", "text": "{\"tanru\":[\"datna\"]}"},
          {"type": "text", "text": "{\"tanru\":[\"pixra\","},
          {"type": "text", "text": "\"cukta\"],\"gloss\":\"picture book\"}"},
        ],
        "claude-opus-4-8",
      ),
    )
    check joined.tagRead == some(tanru("pixra+cukta"))  # text blocks joined, others skipped
    check joined.is_suggested and joined.model == "claude-opus-4-8"  # model served is named
    check readReply(Service.Claude, Reply(status: 200, content_encoding: "identity",
        body: answer.body)).tagRead == some(tanru("ciska"))  # identity is no encoding


  test "each row of reply table of chat completion gives its result":
    for service in [Service.OpenRouter, Service.Chat]:  # both readers of format, exhaustive
      var covered: set[Failure]
      for (reply, failure) in [
        (Reply(status: 200, body: "{}", is_cut: true),
            (Failure.Malformed, "reply over 1048576 bytes")),
        (Reply(status: 200, content_encoding: "br", body: "{}"),
            (Failure.Malformed, "content encoding br")),
        (Reply(status: 307, location: "/v1"), (Failure.Status, "307 to /v1")),
        (Reply(status: 200, body: "\"text\""), (Failure.Malformed, "reply is no JSON object")),
        (toReply(%*{"error": {"code": 403, "message": "Flagged", "metadata": {
            "error_type": "refusal"}}}, 403), (Failure.Declined, "Flagged")),
        (toReply(%*{"error": {"code": 403, "message": "Flagged", "metadata": {
            "error_type": "content_policy_violation"}}}, 403), (Failure.Declined, "Flagged")),
        (toReply(%*{"error": {"code": 429, "message": "Rate limit exceeded", "metadata": {
            "error_type": "rate_limit_exceeded"}}}, 429),
            (Failure.Status, "429 rate_limit_exceeded: Rate limit exceeded")),
        (Reply(status: 502, body: "Bad Gateway"), (Failure.Status, "502")),
        (toReply(%*{"id": "gen-suite", "error": {"code": 502, "message": "Provider down",
            "metadata": {"error_type": "provider_unavailable"}}}),
            (Failure.Status, "502 provider_unavailable: Provider down")),
        (toReply(%*{"id": "gen-suite", "error": {"code": 403, "message": "Declined",
            "metadata": {"error_type": "refusal"}}}), (Failure.Declined, "Declined")),
        (toReply(%*{"id": "gen-suite"}), (Failure.Malformed, "no choice")),
        (toReply(%*{"choices": []}), (Failure.Malformed, "no choice")),
        (toCompletion(%*{"finish_reason": "error", "message": {"content": "partial"},
            "error": {"code": 502, "message": "Provider disconnected mid-stream"}}),
            (Failure.Status, "502: Provider disconnected mid-stream")),
        (toCompletion(%*{"finish_reason": "error", "message": {"content": "partial"}}),
            (Failure.Status, "200: ")),
        (toCompletion(%*{"finish_reason": "content_filter", "message": {"content": nil,
            "refusal": "I cannot help."}}), (Failure.Declined, "I cannot help.")),
        (toCompletion(%*{"finish_reason": "content_filter", "message": {"content": nil,
            "refusal": nil}}), (Failure.Declined, "content_filter")),
        (toCompletion(%*{"finish_reason": "length", "message": {"content": ""}}),
            (Failure.Truncated, "length")),
        (toCompletion(%*{"finish_reason": "tool_calls", "message": {"content": nil}}),
            (Failure.Malformed, "finish reason tool_calls")),
        (toCompletion(%*{"finish_reason": nil, "message": {"content": "x"}}),
            (Failure.Malformed, "finish reason absent")),
        (toCompletion(%*{"finish_reason": "unforeseen", "message": {"content": "x"}}),
            (Failure.Malformed, "finish reason unforeseen")),
        (toCompletion(%*{"finish_reason": "stop", "message": {"content": nil}}),
            (Failure.Malformed, "content is no string")),
        (toCompletion(%*{"finish_reason": "stop", "message": {"content": [{"type": "text",
            "text": "x"}]}}), (Failure.Malformed, "content is no string")),
        (toCompletion(%*{"finish_reason": "stop", "message": {"content": toAnswer(["datna"])}}),
            (Failure.Word, "datna")),
        (toCompletion(%*{"finish_reason": "stop", "message": {"content": toAnswer(["ciska",
            "se"])}}), (Failure.Cmavo, "ciska+se")),
        (toCompletion(%*{"finish_reason": "stop", "message": {"content": toAnswer(
            newSeqWith(8, "ciska"))}}), (Failure.Long, "8")),
        (toCompletion(%*{"finish_reason": "stop", "message": {"content": toAnswer(["brodo",
            "ciska"])}}), (Failure.Readback, "brodyci'a")),
      ]:
        check readReply(service, reply).failureRead ==
            some(failure)  # chat completion of OpenRouter: errors, choices, finish reasons
        covered.incl failure[0]
      check covered == {Failure.Status..Failure.Readback}  # every failure reply alone can name
      let answered = readReply(
        service,
        toCompletion(
          %*{"finish_reason": "stop", "message": {
            "role": "assistant", "content": toAnswer(["pixra", "cukta"]), "refusal": nil}},
          "anthropic/claude-opus-4.8",
        ),
      )
      check answered.tagRead == some(tanru("pixra+cukta"))  # content of first choice is answer
      check answered.is_suggested and answered.model == "anthropic/claude-opus-4.8"  # model named


  test "no status gives tag with error envelope, empty body or markup body":
    for service in Service:  # 3 services, exhaustive
      let envelope =
        if service == Service.Claude:
          $ %*{"type": "error", "error": {"type": "api_error", "message": "Internal error"}}
        else:
          $ %*{"error": {"code": 500, "message": "Internal error", "metadata": {
            "error_type": "server"}}}
      for status in 100..599:  # 500 statuses, exhaustive
        for body in [envelope, "", "<html><body>Bad Gateway</body></html>"]:
          let
            failure = readReply(service, Reply(status: status, body: body)).failureRead
            expected =
              if status notin 200..299 or (service != Service.Claude and body == envelope):
                Failure.Status
              else: Failure.Malformed
          check failure.isSome and failure.get[0] == expected  # no tag without answer
          if status in 200..299: continue
          check failure.isSome and failure.get[1].startsWith($status)  # status named first


  test "random bodies with random statuses never raise, and any tag keeps its promise":
    randomize(0)
    let pool = poolReplies()
    for service in Service:  # 3 services, exhaustive
      var count_suggested = 0
      for reply in served(pool):  # `SAMPLES_REPLY` replies, seeded
        let read = readGuarded(service, reply)
        check read.isSome  # reader never raises, defect included
        if read.isNone: continue
        let suggestion = read.get
        if suggestion.is_suggested:
          check suggestion.tag.isHeld  # every word listed, head gismu, form reads back
          inc count_suggested
          continue
        check suggestion.failure in Failure.Status..Failure.Readback  # reply names no transport
        check suggestion.detail.isPrintable  # detail made printable
        check suggestion.explainGuarded.isSome  # explain never raises
      check count_suggested >= FLOOR_SUGGESTED  # corpus reaches answers that read


  test "keyless 401 bodies captured 2026-10-28 give Status":
    check readReply(Service.Claude, Reply(status: 401, content_type: "application/json",
        body: CAPTURE_MESSAGES)).failureRead == some((Failure.Status,
        "401 authentication_error: x-api-key header is required"))  # captured, Messages API
    for service in [Service.OpenRouter, Service.Chat]:
      check readReply(service, Reply(status: 401, body: CAPTURE_CHAT)).failureRead ==
          some((Failure.Status, "401: No cookie auth credentials found"))  # captured, no type


  test "error envelope names status, then type where it has one, then message":
    for status in [400, 401, 429, 500, 529]:  # client and server errors both formats document
      for (kind, message) in [("", ""), ("", "Overloaded"), ("x_error", ""),
          ("x_error", "Overloaded")]:  # type and message each present or absent, exhaustive
        let
          detail = $status & (if kind.len > 0: " " & kind else: "") & ": " & message
          error_claude = %*{"message": message}
          error_chat = %*{"code": status, "message": message}
        if kind.len > 0:
          error_claude["type"] = %kind
          error_chat["metadata"] = %*{"error_type": kind}
        check readReply(Service.Claude, toReply(%*{"type": "error", "error": error_claude},
            status)).failureRead == some((Failure.Status, detail))  # Messages API, errors
        for service in [Service.OpenRouter, Service.Chat]:
          for status_served in [status, 200]:  # error by status, then inside 2xx by code
            check readReply(service, toReply(%*{"error": error_chat}, status_served)).
                failureRead == some((Failure.Status, detail))  # chat completion, errors


  test "each worked example reads to its tanru under every service":
    for example in EXAMPLES:  # 3 examples, exhaustive
      let gloss = parseJson(example.answer)["gloss"].getStr
      for service in [Service.Claude, Service.OpenRouter]:
        let suggestion = readReply(service, example.toRecordings(service)[^1].reply)
        check suggestion.tagRead == some(tanru(example.tanru))  # recording replays to tanru
        check suggestion.is_suggested and suggestion.gloss == gloss  # gloss as answer gives
        check suggestion.is_suggested and
            suggestion.model == LUT_MODEL_BY_SERVICE[service]  # model of service named
      check readReply(Service.Chat, toReplyChat(example.answer, MODEL_SUITE)).tagRead ==
          some(tanru(example.tanru))  # `chat` reads chat completion as `openrouter` does


  test "content coding is read without case, so every casing of identity is no coding":
    let
      answer = toAnswer(["ciska"])
      completion = toCompletion(%*{"finish_reason": "stop", "message": {"content": answer}}).body
      lut_body_by_service: array[Service, string] =
        [toMessage(%*[{"type": "text", "text": answer}]).body, completion, completion]
    var page = Reply(status: 200, content_type: "text/plain", content_encoding: "Identity",
        body: "x")
    check readPage(URL_SUITE, page).is_read  # case as found in suite review: refused
    check readReply(
      Service.Claude,
      Reply(status: 200, content_encoding: "IDENTITY", body: lut_body_by_service[Service.Claude]),
    ).tagRead ==
        some(tanru("ciska"))  # case as found in suite review: refused
    for coding in "identity".casings:  # 256 casings, exhaustive
      page.content_encoding = coding
      check readPage(URL_SUITE, page).is_read  # RFC 9110 8.4.1, codings are case-insensitive
      for service in Service:  # 3 services, exhaustive
        check readReply(service, Reply(status: 200, content_encoding: coding,
            body: lut_body_by_service[service])).tagRead == some(tanru("ciska"))  # 8.4.1
    for coding in ["gzip", "GZIP", "Br", "deflate", "Compress", "x-gzip", "zstd", "identity, br"]:
      page.content_encoding = coding
      let paged = readPage(URL_SUITE, page)
      check not paged.is_read and paged.detail == "content encoding " & coding  # named as given
      for service in Service:  # 3 services, exhaustive
        check readReply(
          service,
          Reply(status: 200, content_encoding: coding, body: lut_body_by_service[service]),
        ).failureRead ==
            some((Failure.Malformed, "content encoding " & coding))  # named as given



suite "Internal: Page":
  test "markup reads as text reference walk reads from random tree":
    randomize(0)
    let pool = poolTrees()
    var count_deep = 0
    for nodes in served(pool):  # `SAMPLES_MARKUP` trees, seeded
      var text = ""
      readTree(nodes, text)
      check readMarkup(nodes.mapIt(it.toMarkup).join) ==
          text.collapse  # text of tree, one pass, spaces collapsed
      if nodes.depth >= DEPTH_MARKUP_MAX: inc count_deep
    check count_deep >= FLOOR_DEEP  # corpus reaches deepest nesting often


  test "raw text of script, style, iframe and noscript ends only at its own closing element":
    check readMarkup("<script>if (a<b) x();</script><p>Hello</p>") ==
        "Hello"  # case as found in suite review: `<` before letter lost rest of page
    check readMarkup("<style>a<b{}</style><p>Hello</p>") == "Hello"  # case as found, in style
    check readMarkup("<script>s = \"<!--\";</script><p>Hello</p>") ==
        "Hello"  # case as found in suite review: `<!--` never closed lost rest of page
    for name in NAMES_RAW:  # 4 elements, exhaustive
      for raw in name.textsRaw:  # each raw text, exhaustive
        check not raw.isClosingRaw(name)  # corpus never closes raw text early
        for markup in markupsRaw(name, raw):
          check readMarkup(markup) == "a\nb"  # HTML tokenizer, end tag name state of raw text
      check readMarkup("<p>a</p><" & name & ">x<b") == "a"  # raw text never closed runs to end


  test "skipped element nested in one of same name is skipped whole":
    check readMarkup("<template><template></template>secret</template><p>Hello</p>") ==
        "Hello"  # case as found in suite review: inner closing element ended skip
    for name in NAMES_SKIPPED:
      if name in NAMES_RAW: continue  # raw text nests nothing; test above holds it
      for levels in 1..LEVELS_SKIPPED_MAX:  # 1 to 4 levels, exhaustive
        for (opening, closing) in [(name, name.toUpperAscii), (name.capitalizeAscii, name)]:
          let markup = "<p>a</p>" & ("<" & opening & ">x").repeat(levels) &
              ("</" & closing & ">y").repeat(levels) & "<p>b</p>"
          check readMarkup(markup) == "a\ny\nb"  # text after outermost closing element alone
      check readMarkup("<p>a</p><" & name & "><" & name & "/>x</" & name & "><p>b</p>") ==
          "a\nb"  # element closing itself opens no level
      let deep = ("<" & name & ">").repeat(COUNT_NESTED) &
          ("</" & name & ">hidden").repeat(COUNT_NESTED - 1) & "</" & name & "><p>deep</p>"
      check readMarkup(deep) == "deep"  # levels counted, not recursed, so nesting overflows nothing


  test "quote opens attribute value alone, so quote in name or unquoted value closes nothing":
    check readMarkup("<a href=x'y>text</a><p>Hello</p>") ==
        "text\nHello"  # case as found in suite review: quote in unquoted value lost rest of page
    for attribute in ATTRIBUTES:  # 13 attributes, exhaustive
      for (name, text) in [
        ("p", "a\nx\nb"), ("span", "a\nx\nb"), ("template", "a\nb"), ("script", "a\nb"),
      ]:
        let markup = "<p>a</p><" & name & attribute & ">x</" & name & attribute & "><p>b</p>"
        check readMarkup(markup) == text  # HTML tokenizer, before attribute value state
    check readMarkup("<p>a</p><span =\"x>\">y</span>") ==
        "a\n\">y"  # `=` opening name is no assignment, so quote after it opens nothing
    check readMarkup("<p>a</p><span title='x>y") == "a"  # quoted value never closed runs to end


  test "100,000 nested elements read in one pass":
    for (opening, closing) in [("<div>", "</div>"), ("<span class=\"x\">", "</span>"),
        ("<p>", "")]:
      let markup = opening.repeat(COUNT_NESTED) & "deep" & closing.repeat(COUNT_NESTED)
      check readMarkup(markup) == "deep"  # no recursion, so nesting overflows nothing
    let paged = readPage(
      URL_SUITE,
      Reply(status: 200, content_type: "text/html", body: "<div>".repeat(COUNT_NESTED) & "deep"),
    )
    check paged.is_read and paged.passage.text == "deep"  # page of unclosed nesting reads


  test "character references by table: named, decimal, hexadecimal, invalid, unknown":
    for (name, text) in LUT_TEXT_BY_NAME:  # 23 names, exhaustive
      let reference = "&" & name & ";"
      check readReference(reference, 0) == (text, reference.len)  # HTML named references
    for (reference, text) in REFERENCES_NUMERIC:
      check readReference(reference, 0) == (text, reference.len)  # HTML numeric references
    for reference in REFERENCES_KEPT:
      check readReference(reference, 0) == ("&", 1)  # unknown or malformed: `&` alone
      check readMarkup("x" & reference & "y") == "x" & reference & "y"  # kept as written
    check readMarkup("a&amp;lt;b") == "a&lt;b"  # decoded once, never again
    check readMarkup("&lt;p&gt;x&lt;/p&gt;") == "<p>x</p>"  # decoded text opens no element


  test "space written as reference collapses as space written raw does":
    check readMarkup("<p>a&#10;b</p>") == "a b"  # case as found in suite review: `&#10;` broke line
    for code in SPACES_COLLAPSED:  # 7 spaces, exhaustive
      let hexadecimal = code.toHex(2)
      for reference in ["&#" & $code & ";", "&#x" & hexadecimal.toLowerAscii & ";",
          "&#X" & hexadecimal & ";", "&#000" & $code & ";"]:
        for markup in TEMPLATES_SPACE:  # 5 places, exhaustive
          check readMarkup(markup.replace("@", reference)) ==
              readMarkup(markup.replace("@", code.encode))  # reference stands for its character


  test "numeric references 128 to 159 read through windows-1252, as HTML maps them":
    check readMarkup("a&#150;b") == "a\u2013b"  # case as found in suite review: read as C1 control
    for code in 0x80..0x9F:  # 32 numbers, exhaustive
      for reference in ["&#" & $code & ";", "&#x" & code.toHex(2) & ";"]:
        check readReference(reference, 0) == (LUT_TEXT_BY_POINTER[code-0x80],
            reference.len)  # HTML numeric reference end state, table of index-windows-1252


  test "repair keeps first sequence or replaces its lead alone, by Table 3-7, for every pair":
    var wrong: seq[(int, int)]
    for first in 0..255:
      for second in 0..255:  # 65,536 pairs, exhaustive
        let bytes = chr(first) & chr(second) & "\x80\x80"
        var length = 0
        for row in ROWS_WELL_FORMED:
          if first in row.first and (row.length == 1 or second in row.second): length = row.length
        let
          tail = repairEncoding(bytes[max(length, 1)..^1])
          expected =
            if length > 0: (bytes[0..<length] & tail.text, tail.count_repaired)
            else: ("\uFFFD" & tail.text, tail.count_repaired + 1)
        if repairEncoding(bytes) != expected: wrong.add (first, second)
    check wrong == newSeq[(int, int)]()  # Table 3-7 of Unicode Standard, chapter 3


  test "repair matches maximal subparts, gives well-formed text, is idempotent, counts each":
    randomize(0)
    let pool = poolBytes()
    for bytes in served(pool):  # `SAMPLES_BYTES` strings, seeded
      let repaired = repairEncoding(bytes)
      check repaired == bytes.repairReference  # substitution of maximal subparts, chapter 3
      check repaired.text.isWellFormed  # Table 3-7
      check repairEncoding(repaired.text) == (repaired.text, 0)  # idempotent
      check repaired.count_repaired ==
          repaired.text.count("\uFFFD") - bytes.count("\uFFFD")  # count is replacements made
      check not bytes.isWellFormed or repaired == (bytes, 0)  # well-formed text unchanged


  test "windows-1252 decodes every byte as index of WHATWG Encoding Standard gives it":
    var bytes, expected: string
    for code in 0..255:  # 256 bytes, exhaustive
      let text = if code in 0x80..0x9F: LUT_TEXT_BY_POINTER[code-0x80] else: code.encode
      check decode($chr(code), "windows-1252") == some(text)  # index-windows-1252
      bytes.add chr(code)
      expected.add text
    for label in LABELS_GROUP_WINDOWS:  # 17 labels, exhaustive
      check decode(bytes, label) == some(expected)  # every label names one decoder
    for label in LABELS_GROUP_UNICODE:  # 6 labels, exhaustive
      check decode(bytes, label) == some(bytes)  # UTF-8 kept as is; repair follows
    for label in LABELS_OTHER:
      check decode(bytes, label).isNone  # no other encoding is read


  test "charset label by table: header, meta, default, aliases":
    for (content_type, body, is_markup, label) in [
      ("text/html; charset=UTF-8", "", true, "utf-8"),
      ("text/html; charset=\"ISO-8859-1\"", "", true, "iso-8859-1"),
      ("text/html;charset='latin1'", "", true, "latin1"),
      ("text/plain; charset=us-ascii; format=flowed", "", false, "us-ascii"),
      ("text/html", "<meta charset=\"windows-1252\">", true, "windows-1252"),
      ("text/html", "<META CHARSET=WINDOWS-1252>", true, "windows-1252"),
      ("text/html", "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=Shift_JIS\">",
          true, "shift_jis"),
      ("text/html", "<meta name=\"viewport\" content=\"x\"><meta charset=latin1/>", true,
          "latin1"),
      ("text/html; charset=utf-8", "<meta charset=\"windows-1252\">", true, "utf-8"),
      ("text/plain", "<meta charset=\"windows-1252\">", false, "utf-8"),
      ("text/html", " ".repeat(1024) & "<meta charset=\"latin1\">", true, "utf-8"),
      ("text/html", "", true, "utf-8"),
      ("", "", false, "utf-8"),
    ]:
      check readCharset(content_type, body, is_markup) ==
          label  # header first, then `<meta>` of first 1,024 bytes of markup, else UTF-8
    let paged = readPage(
      URL_SUITE,
      Reply(status: 200, content_type: "text/html",
          body: "<meta charset=\"windows-1252\"><p>\x93caf\xE9\x94</p>"),
    )
    check paged.is_read and paged.passage.text == "\u201Ccaf\u00E9\u201D"  # label of meta read


  test "byte order mark names encoding before any label, and mark of UTF-16 is refused":
    let
      little = readPage(
        URL_SUITE,
        Reply(status: 200, content_type: "text/html",
            body: "\xFF\xFE<\x00h\x00t\x00m\x00l\x00>\x00"),
      )
      big = readPage(
        URL_SUITE,
        Reply(status: 200, content_type: "text/plain", body: "\xFE\xFF\x00H\x00e\x00l\x00l\x00o"),
      )
      labelled = readPage(
        URL_SUITE,
        Reply(status: 200,
            content_type: "text/plain; charset=windows-1252", body: "\xEF\xBB\xBFcaf\xC3\xA9"),
      )
    check not little.is_read and
        little.detail == "charset utf-16"  # review finding logic-7, 2026-10-29: NULs were sent
    check not big.is_read and
        big.detail == "charset utf-16"  # review finding logic-7, 2026-10-29: NULs were sent
    check labelled.is_read and labelled.passage.text ==
        "caf\u00E9"  # review finding logic-7, 2026-10-29: read `caf\u00C3\u00A9`
    let labels = deduplicate(
      @[""] & @LABELS_GROUP_UNICODE & @LABELS_GROUP_WINDOWS & @LABELS_OTHER & @LABELS_GROUP_SIXTEEN,
    )
    var wrong: seq[(string, string, string, string)]
    for (mark, marked) in MARKS_BYTE_ORDER:  # 3 marks and none, exhaustive
      for header in labels:  # each label and none, exhaustive
        for meta in labels:
          for kind in ["", "text/html", "application/xhtml+xml", "text/plain"]:

            # Read label as encoding sniffing of HTML, 13.2.3.2, reads it: mark, header, prescan.
            let
              opening = if meta.len > 0: "<meta charset=\"" & meta & "\">" else: ""
              is_markup = kind != "text/plain"
              label =
                if marked.len > 0: marked
                elif header.len > 0: header
                elif is_markup and meta in LABELS_GROUP_SIXTEEN: "utf-8"
                elif is_markup and meta.len > 0: meta
                else: "utf-8"
              word =
                if label in LABELS_GROUP_UNICODE: "caf\u00E9"
                elif label in LABELS_GROUP_WINDOWS: "caf\u00C3\u00A9"
                else: ""

            # Hold page to label: UTF-16 refused, other unread labels refused, else word decoded.
            let
              paged = readPage(URL_SUITE, Reply(
                status: 200,
                content_type: kind & (if header.len > 0: "; charset=" & header else: ""),
                body: mark & opening & "<p>caf\xC3\xA9</p>",
              ))
              is_held =
                if marked in LABELS_GROUP_SIXTEEN:
                  not paged.is_read and paged.detail == "charset utf-16"
                elif word.len == 0: not paged.is_read and paged.detail == "charset " & label
                elif is_markup: paged.is_read and paged.passage.text == word
                else: paged.is_read and paged.passage.text == opening & "<p>" & word & "</p>"
            if not is_held: wrong.add (mark, header, meta, kind)
    check wrong == newSeq[(string, string, string, string)]()  # WHATWG 6.1, decode: mark first


  test "meta naming UTF-16 reads as UTF-8, and spaces may stand around `=` after charset":
    let
      sixteen = readPage(
        URL_SUITE,
        Reply(status: 200, content_type: "text/html",
            body: "<meta charset=\"utf-16\"><p>caf\xC3\xA9</p>"),
      )
      spaced = readPage(
        URL_SUITE,
        Reply(status: 200, content_type: "text/html",
            body: "<meta charset = \"windows-1252\"><p>caf\xE9</p>"),
      )
    check sixteen.is_read and
        sixteen.passage.text == "caf\u00E9"  # review finding logic-7, 2026-10-29: refused
    check spaced.is_read and
        spaced.passage.text == "caf\u00E9"  # review finding logic-7, 2026-10-29: read `caf\uFFFD`
    for label in LABELS_GROUP_SIXTEEN:  # 9 labels, exhaustive
      for markup in ["<meta charset=\"" & label & "\">",
          "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=" & label & "\">"]:
        check readCharset("text/html", markup, true) ==
            "utf-8"  # HTML 13.2.3.2, prescan, step 14: UTF-16BE/LE set to UTF-8
      check readCharset("text/html; charset=" & label, "", true) ==
          label  # header label kept, so decode refuses it
    for before in SPACES_ASCII:
      for after in SPACES_ASCII:  # 7 runs before `=` by 7 after, exhaustive
        let assignment = "charset" & before & "=" & after
        for (content_type, body) in [
          ("text/html; " & assignment & "windows-1252", ""),
          ("text/html", "<meta " & assignment & "\"windows-1252\">"),
          ("text/html", "<meta http-equiv=\"Content-Type\" content=\"text/html; " & assignment &
              "windows-1252\">"),
        ]:
          check readCharset(content_type, body, true) ==
              "windows-1252"  # HTML 2.5.3, steps 3 and 5: spaces after `charset` and `=` skipped
    check readCharset("text/html; charset x; charset=latin1", "", true) ==
        "latin1"  # HTML 2.5.3, step 4: `charset` with no `=` after it is passed by


  test "cut keeps longest prefix within cap on character boundary":
    randomize(0)
    let pool = poolBytes()
    for bytes in served(pool):  # `SAMPLES_BYTES` strings, seeded
      let text = repairEncoding(bytes).text
      for bytes_max in [0, 1, 2, 3, 4, text.len div 3, text.len div 2, text.len - 3,
          text.len - 2, text.len - 1, text.len, text.len + 1]:
        if bytes_max < 0: continue
        let kept = text.cut(bytes_max)
        check text.startsWith(kept)  # prefix
        check kept.len <= bytes_max or text.len <= bytes_max  # within cap
        check text.len > bytes_max or kept == text  # nothing cut where text fits
        check kept.len == text.len or
            (uint8(text[kept.len]) and 0xC0) != 0x80  # on character boundary
        check kept.len == text.len or
            kept.len + text[kept.len].measureCharacter > bytes_max  # longest such prefix


  test "passage drops byte order mark, repairs and counts, and cuts at its cap":
    let
      marked = toPassage("\xEF\xBB\xBFabc")
      inner = toPassage("a\xEF\xBB\xBFb")
      repaired = toPassage("\xFFa\xC3")
      fitting = toPassage("a".repeat(BYTES_PASSAGE_MAX))
      over = toPassage("a".repeat(BYTES_PASSAGE_MAX + 1))
      straddling = toPassage("a".repeat(BYTES_PASSAGE_MAX - 1) & "\u20AC")
      paged = toPassage("x", URL_SUITE, is_page_cut = true)
    check marked.text == "abc" and marked.count_bytes == 3  # leading mark dropped
    check inner.text == "a\uFEFFb"  # mark inside is text
    check repaired.text == "\uFFFDa\uFFFD" and repaired.count_repaired == 2  # each subpart
    check repaired.count_bytes == 7  # bytes after repair
    check not fitting.is_cut and fitting.text.len == BYTES_PASSAGE_MAX  # cap holds whole text
    check over.is_cut and over.text.len == BYTES_PASSAGE_MAX  # cut at cap
    check over.count_bytes == BYTES_PASSAGE_MAX + 1  # bytes before cut kept
    check straddling.is_cut and straddling.text == "a".repeat(BYTES_PASSAGE_MAX - 1)  # boundary
    check paged.url == URL_SUITE and paged.is_page_cut and not paged.is_cut  # page facts kept


  test "URL of passage is repaired as text is, so every body stays UTF-8":
    let found = toPassage("x", url = "https://example.org/caf\xE9")
    check found.url == "https://example.org/caf\uFFFD"  # case as found in suite review: kept raw
    for service in Service:  # 3 services, exhaustive
      let body = initSettings(service, some(EFFORT_DEFAULT)).toBody(found)
      check body.isWellFormed  # case as found in suite review: body held byte `E9`
    let paged = readPage("https://example.org/caf\xE9",
        Reply(status: 200, content_type: "text/plain", body: "x"))
    check paged.is_read and
        paged.passage.url == "https://example.org/caf\uFFFD"  # page repairs URL as passage does
    randomize(0)
    let pool = poolBytes()
    for bytes in served(pool):  # `SAMPLES_BYTES` strings, seeded
      check toPassage("x", bytes).url ==
          bytes.repairReference.text  # substitution of maximal subparts, chapter 3


  test "page refusals by table: status, encoding, type, charset, no text":
    for (reply, detail) in [
      (Reply(status: 404, content_type: "text/html", body: "<p>x</p>"), "status 404"),
      (Reply(status: 199, body: "x"), "status 199"),
      (Reply(status: 301, location: "/alice.html"), "status 301"),
      (Reply(status: 503, body: "x"), "status 503"),
      (Reply(status: 200, content_encoding: "gzip", body: "x"), "content encoding gzip"),
      (Reply(status: 200, content_encoding: "br", body: "x"), "content encoding br"),
      (Reply(status: 200, content_type: "application/pdf", body: "%PDF"), "type application/pdf"),
      (Reply(status: 200, content_type: "Image/PNG; x=y", body: "x"), "type image/png"),
      (Reply(status: 200, content_type: "application/json", body: "{}"), "type application/json"),
      (Reply(status: 200, content_type: "\x1B[31mtext/html", body: "x"),
          "type \\u{1B}[31mtext/html"),
      (Reply(status: 200, content_type: "text/html; charset=shift_jis", body: "x"),
          "charset shift_jis"),
      (Reply(status: 200, content_type: "text/plain; charset=utf-16le", body: "x"),
          "charset utf-16le"),
      (Reply(status: 200, content_type: "text/html", body: "<meta charset=koi8-r><p>x</p>"),
          "charset koi8-r"),
      (Reply(status: 200, content_type: "text/html", body: ""), "no text"),
      (Reply(status: 200, content_type: "text/plain", body: " \n\t "), "no text"),
      (Reply(status: 200, content_type: "text/html", body: "<script>x</script><!-- y -->"),
          "no text"),
      (Reply(status: 200, content_type: "text/html", body: "<p>&nbsp;</p>"), "no text"),
      (Reply(status: 200, content_type: "text/html", body: "\xEF\xBB\xBF"), "no text"),
    ]:
      let paged = readPage(URL_SUITE, reply)
      check not paged.is_read and paged.detail == detail  # refusal names what is wrong
    for (reply, text) in [
      (Reply(status: 200, content_type: "text/plain", body: "a <b>c</b> &amp;"),
          "a <b>c</b> &amp;"),
      (Reply(status: 200, content_type: "text/html", body: "<p>a</p><p>b &amp; c</p>"),
          "a\nb & c"),
      (Reply(status: 200, content_type: "application/xhtml+xml", body: "<p>a</p>"), "a"),
      (Reply(status: 200, content_type: "TEXT/HTML; Charset=ISO-8859-1", body: "<p>caf\xE9</p>"),
          "caf\u00E9"),
      (Reply(status: 200, body: "  <p>a</p>"), "a"),
      (Reply(status: 200, body: "a <p>"), "a <p>"),
      (Reply(status: 203, content_type: "text/css", body: "p { }"), "p { }"),
      (Reply(status: 299, content_encoding: "identity", content_type: "text/plain", body: "x"),
          "x"),
      (Reply(status: 200, content_type: "text/plain", body: "\xEF\xBB\xBFx\xFFy"), "x\uFFFDy"),
    ]:
      let paged = readPage(URL_SUITE, reply)
      check paged.is_read and paged.passage.text == text  # type, charset and markup read
      check paged.is_read and paged.passage.url == URL_SUITE  # final URL kept
    let cut = readPage(
      URL_SUITE,
      Reply(status: 200, content_type: "text/plain", body: "x", is_cut: true),
    )
    check cut.is_read and cut.passage.is_page_cut  # page cut reaches passage


  test "byte order mark is no text, so page reads as page without it":
    let marked = readPage(URL_SUITE, Reply(status: 200, body: "\xEF\xBB\xBF<p>Hello</p>"))
    check marked.is_read and marked.passage.text == "Hello"  # case as found in suite review
    for content_type in ["", "text/html", "application/xhtml+xml", "text/plain"]:
      for body in ["<p>Hello</p>", " \n<p>a</p><p>b</p>", "plain <b>x</b>", "a <p>",
          "<!DOCTYPE html><title>t</title>", "x\xFFy", ""]:
        let
          plain = readPage(URL_SUITE, Reply(status: 200, content_type: content_type, body: body))
          paged = readPage(
            URL_SUITE,
            Reply(status: 200, content_type: content_type, body: "\xEF\xBB\xBF" & body),
          )
        check paged.is_read == plain.is_read  # WHATWG Encoding Standard, decode: mark dropped
        if paged.is_read and plain.is_read:
          check paged.passage == plain.passage  # mark changes no text, count or type read
        elif not paged.is_read and not plain.is_read:
          check paged.detail == plain.detail  # mark changes no refusal


  test "sample page of worked examples reads as text its paragraph gives":
    let
      page = EXAMPLES.filterIt(it.name == "page")[0]
      alice = EXAMPLES.filterIt(it.name == "alice")[0]
      (url, reply) = page.hops[^1]
      paged = url.readPage(reply)
    check paged.is_read and paged.passage.text == "Alice & her sister\nDown the Rabbit-Hole\n" &
        alice.argument & "\nSo she was considering in her own mind\u2026"  # windows-1252 read
    check page.toPassage == paged.passage  # example builds passage `suggester` builds



suite "Internal: Report":
  test "printable text holds no control or bidirectional mark, and stays within its cap":
    check toPrintable("\x00", 10) == "\\u{0}"  # case as found in suite review: escape held no digit
    for code in 0x00..0x9F:
      if not code.isEscaped: continue
      check toPrintable(code.encode, 1) == "\\u{" & code.toHexadecimal & "}"  # C0, DEL, C1
    for code in MARKS_BIDIRECTIONAL:  # 12 marks, exhaustive
      check toPrintable(code.encode, 1) == "\\u{" & code.toHexadecimal & "}"  # `Bidi_Control`
    var ascii = ""
    for character in ' '..'~': ascii.add character
    check toPrintable(ascii, ascii.len) == ascii  # printable ASCII unchanged
    check toPrintable(ascii, 3) == " !\"\u2026"  # cut with `…` past cap
    check toPrintable("\xFF", 5) == "\uFFFD"  # repaired first
    randomize(0)
    let pool = poolPrintable()
    for (text, runes_max) in served(pool):  # `SAMPLES_BYTES` texts, seeded
      let printable = text.toPrintable(runes_max)
      check printable.isPrintable  # no C0, C1, `DEL` or bidirectional mark
      check printable == text.toPrintableReference(runes_max)  # each character until cap


  test "each failure explains itself, ending in its detail in backticks":
    let found = Suggestion(is_suggested: false, failure: Failure.Readback, detail: "ciska")
    check found.explainGuarded ==
        some("Form should read back as its tag; got `ciska`.")  # case as found in suite review
    for failure in Failure:  # 11 members, exhaustive
      for detail in ["", "x", "two words", "datna", "brodyci'a", "ciska+se", "7", "ciska",
          "datnyvreji", "selci'a"]:
        let explained =
          Suggestion(is_suggested: false, failure: failure, detail: detail).explainGuarded
        check explained.isSome  # explain never raises, detail reading as tag included
        if explained.isNone: continue
        check explained.get.endsWith("`" & detail & "`.")  # IV.4, message ends in its value
        check explained.get[0] in {'A'..'Z'}  # sentence
    check Suggestion(is_suggested: false, failure: Failure.Truncated,
        detail: "max_tokens").explain == "Answer should end before its limit; lower effort or " &
        "shorten passage; got `max_tokens`."  # remedy named


  test "report names page, page cut, repair and passage cut where each applies, then outcome":
    let
      suggested = Suggestion(is_suggested: true, tag: tanru("datni+vreji"), gloss: "data file",
          model: "served-model")
      gismu = Suggestion(is_suggested: true, tag: tanru("ciska"), gloss: "writing",
          model: "served-model")
      failed = Suggestion(is_suggested: false, failure: Failure.Long, detail: "7")
    for flags in 0..15:  # 16 combinations of four facts, exhaustive
      let passage = Passage(
        text: "x",
        url: if (flags and 1) != 0: URL_SUITE else: "",
        is_page_cut: (flags and 2) != 0,
        count_repaired: if (flags and 4) != 0: 3 else: 0,
        is_cut: (flags and 8) != 0,
        count_bytes: 70_000,
      )
      var lines = ""
      if (flags and 1) != 0: lines.add "Page came from `" & URL_SUITE & "`.\n"
      if (flags and 2) != 0: lines.add "Page held more than `4194304` bytes; rest never read.\n"
      if (flags and 4) != 0:
        lines.add "Passage held `3` ill-formed UTF-8 subparts; each became U+FFFD.\n"
      if (flags and 8) != 0: lines.add "Passage held `70000` bytes; model read first `65536`.\n"
      check failed.toReport(passage, "served-model") ==
          lines & failed.explain & "\n"  # facts first, then failure
      check suggested.toReport(passage, "served-model") == lines & "Service suggests tag " &
          "`datni+vreji`, i.e. `datnyvei`, glossed `data file` by `served-model`.\n"  # tag, form
      check suggested.toReport(passage, "asked-model") == lines & "Service suggests tag " &
          "`datni+vreji`, i.e. `datnyvei`, glossed `data file` by `served-model`, where " &
          "`asked-model` was asked.\n"  # served model differing is named
      check gismu.toReport(passage, "served-model") == lines & "Service suggests tag " &
          "`ciska`, glossed `writing` by `served-model`.\n"  # gismu is its own form
    check failed.toReport(toPassage("x", "https://example.org/\x1B[2J"), "m") ==
        "Page came from `https://example.org/\\u{1B}[2J`.\n" & failed.explain &
        "\n"  # URL made printable


  test "text reading as tag already takes shortcut; prose, cmavo alone and long text do not":
    check readTagGiven("datnyvreji") == some(tanru("datni+vreji"))  # reads as tag, no service
    check readTagGiven(" Datnyvreji\n") == some(tanru("datni+vreji"))  # folded as reader folds
    check readTagGiven("ciska") == some(tanru("ciska"))  # gismu is tag
    for text in ["mi nelci lo nu tcidu lo cukta", "Lojban", "se", "lo", "", "datni+vreji",
        "picture book"]:
      check readTagGiven(text).isNone  # prose, English, cmavo alone, tanru go to service
    let padded = " ".repeat(BYTES_ELEMENT_MAX - 5) & "ciska"
    check readTagGiven(padded) == some(tanru("ciska"))  # 64 bytes reach reader
    check readTagGiven(" " & padded).isNone  # 65 bytes never reach it
    check toReportGiven(" datnyvreji\n", tanru("datni+vreji")) == "`datnyvreji` reads as tag " &
        "`datni+vreji` already, so no service is asked.\n"  # text given, trimmed, and its tanru
