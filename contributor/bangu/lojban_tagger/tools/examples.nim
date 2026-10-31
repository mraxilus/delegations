## Write worked examples of `suggester` as recordings it replays with no credential:
##   `nim r tools/build.nim examples` writes them under `build/examples/`, which git ignores,
##   and prints command replaying each.
##
##   |---------|-----------------------------------------------------------------------|
##   | Example | What `suggester` reads                                                |
##   |---------|-----------------------------------------------------------------------|
##   | alice   | opening of Alice's Adventures in Wonderland, Lewis Carroll, 1865,     |
##   |         | public domain, given as text                                          |
##   | lojban  | `mi ciska lo xatra`, sample written for project, given as text        |
##   | page    | sample page at reserved domain `example.org`, behind one redirect     |
##   |---------|-----------------------------------------------------------------------|
##
##   Every reply of service here is documented shape with illustrative values, never reply
##     captured from service; label of each recording says so, and replay report prints label.
##     Reply captured live replaces it once credential exists (open question in PROVENANCE).
##   Page sample holds what reader must handle: redirect, `<meta>` charset of windows-1252,
##     bytes `93` and `94`, title, script, style, comment and character references.
##   Recordings hold requests this build sends under default settings of each service, endpoint
##     included, so they replay only while endpoint, prompt, schema and passage reading stay;
##     suite holds that.
##   Data person writes is typed Nim, as committed lists are; recording files are written at
##     run time and never committed.
##   Command printed names service and sets every other variable of settings `suggester` reads
##     empty, workspace included, so no setting shell exports changes replay; directory of
##     examples takes mode `0755` whatever umask, since `suggester` refuses directory every user
##     may write. Suite holds both, running each command printed under umask `000`.
##     Cost: mode set on that directory by hand is set again on each run.

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[json, options, os]

import ../app/exchanges
import ../src/lojban_tagger/suggestions


type
  Example* = object  ## Define one worked example: what `suggester` reads, pages, answer.
    name*: string  ## Short name of example.
    argument*: string  ## Text or URL `suggester` reads.
    hops*: seq[(string, Reply)]  ## Each page URL with its reply, in order; empty for text.
    tags*: seq[tuple[gismu, gloss: string]]
      ## Tags answer names, most likely search first, each gismu with its gloss: documented shape,
      ##   values illustrative; `suggester` prints each gismu, one to line.


const
  LABEL_MESSAGES* = "documented shape of Message object, " &
      "`https://platform.claude.com/docs/en/api/messages`; values illustrative, never captured"
    ## Origin of each reply of `claude` here.
  LABEL_CHAT* = "documented shape of chat completion, " &
      "`https://openrouter.ai/docs/api/reference/overview`; values illustrative, never captured"
    ## Origin of each reply of `openrouter` and `chat` here.
  LABEL_PAGE* = "sample page written for project, at reserved domain `example.org`"
    ## Origin of each page hop here.
  DIRECTORY_EXAMPLES = "build" / "examples"  ## Directory examples go to; git ignores it.
  MODE_EXAMPLES = {
    fpUserRead, fpUserWrite, fpUserExec, fpGroupRead, fpGroupExec, fpOthersRead, fpOthersExec,
  }
    ## Mode of directory of examples, i.e. `0755`, whatever umask: `suggester` refuses directory
    ##   every user may write.
  TEXT_ALICE = "Alice was beginning to get very tired of sitting by her sister on the bank, " &
      "and of having nothing to do: once or twice she had peeped into the book her sister " &
      "was reading, but it had no pictures or conversations in it, " &
      "\xE2\x80\x9Cand what is the use of a book,\xE2\x80\x9D thought Alice " &
      "\xE2\x80\x9Cwithout pictures or conversations?\xE2\x80\x9D"
    ## Opening paragraph of chapter 1 of Alice's Adventures in Wonderland, public domain.
  MARKUP_PAGE = "<!DOCTYPE html>\n<html><head><meta charset=\"windows-1252\">" &
      "<title>Alice &amp; her sister</title><style>p { color: gray }</style>" &
      "<script>if (a < b) { note = \"</p>\"; }</script></head>\n<body><!-- sample -->" &
      "<h1>Down the Rabbit-Hole</h1><p>Alice was beginning to get very tired of sitting by " &
      "her sister on the bank, and of having nothing to do: once or twice she had peeped " &
      "into the book her sister was reading, but it had no pictures or conversations in it, " &
      "\x93and what is the use of a book,\x94 thought Alice \x93without pictures or " &
      "conversations?\x94</p><p>So she was considering in her own mind&#8230;</p></body></html>\n"
    ## Sample page in windows-1252; text of chapter 1, public domain.
  EXAMPLES* = [
    Example(
      name: "alice",
      argument: TEXT_ALICE,
      hops: @[],
      tags: @[
        ("cukta", "book"), ("nixli", "girl"), ("ractu", "rabbit she follows"),
        ("kevna", "rabbit hole"), ("mensi", "sister"), ("mlatu", "grinning cat"),
        ("nobli", "queen, as noble"), ("traji", "queen, as highest"), ("turni", "queen, as ruler"),
        ("pixra", "picture"), ("tatpi", "tired"),
      ],
    ),
    Example(
      name: "lojban",
      argument: "mi ciska lo xatra",
      hops: @[],
      tags: @[("xatra", "letter"), ("ciska", "writing")],
    ),
    Example(
      name: "page", argument: "https://example.org/alice",
      hops: @[
        ("https://example.org/alice", Reply(status: 301, location: "/alice.html")),
        ("https://example.org/alice.html", Reply(
          status: 200, content_type: "text/html", body: MARKUP_PAGE,
        )),
      ],
      tags: @[
        ("cukta", "book"), ("ractu", "rabbit"), ("kevna", "rabbit hole"), ("nixli", "girl"),
        ("mensi", "sister"), ("tatpi", "tired"),
      ],
    ),
  ]
    ## Worked examples, each replayed under `claude` and `openrouter`: tags of text and page of
    ##   Alice name what passage holds and what model knows of book, as prompt asks, most likely
    ##   search first.



#[ Recordings ]#

func answer*(example: Example): string =
  ## Render answer of schema naming tags of example, in order, as model gives it.
  let tags = newJArray()
  for (gismu, gloss) in example.tags: tags.add %*{"gismu": gismu, "gloss": gloss}
  $ %*{"tags": tags}


func toReplyMessages*(answer, model: string): Reply =
  ## Wrap answer in Message object ending `end_turn`, as `LABEL_MESSAGES` documents it.
  Reply(
    status: 200,
    content_type: "application/json",
    body: $ %*{
      "id": "msg_example", "type": "message", "role": "assistant", "model": model,
      "content": [{"type": "text", "text": answer}],
      "stop_reason": "end_turn", "stop_sequence": nil, "stop_details": nil,
      "usage": {"input_tokens": 0, "output_tokens": 0},
    },
  )


func toReplyChat*(answer, model: string): Reply =
  ## Wrap answer in chat completion ending `stop`, as `LABEL_CHAT` documents it.
  Reply(
    status: 200,
    content_type: "application/json",
    body: $ %*{
      "id": "gen-example", "object": "chat.completion", "model": model,
      "choices": [{
        "index": 0, "finish_reason": "stop",
        "message": {"role": "assistant", "content": answer, "refusal": nil},
      }],
      "usage": {"prompt_tokens": 0, "completion_tokens": 0, "total_tokens": 0},
    },
  )


func toSettings*(service: Service): Settings =
  ## Build default settings of service, as `suggester` reads them where environment names none.
  Settings(
    service: service, endpoint: LUT_ENDPOINT_BY_SERVICE[service],
    model: LUT_MODEL_BY_SERVICE[service],
    effort: if service == Service.Chat: none(Effort) else: some(EFFORT_DEFAULT),
  )


func toPassage*(example: Example): Passage =
  ## Build passage `suggester` builds for example: text given, or text of last page hop.
  if example.hops.len == 0: return example.argument.toPassage
  let (url, reply) = example.hops[^1]
  url.readPage(reply).passage


func toRecordings*(example: Example, service: Service): seq[Recording] =
  ## Build recordings replaying example under default settings of service: each page hop,
  ##   then service exchange answering documented answer.
  for (url, reply) in example.hops:
    result.add Recording(label: LABEL_PAGE, request: "GET " & url, reply: reply)
  let
    settings = service.toSettings
    reply =
      if service == Service.Claude: toReplyMessages(example.answer, settings.model)
      else: toReplyChat(example.answer, settings.model)
  result.add Recording(
    label: if service == Service.Claude: LABEL_MESSAGES else: LABEL_CHAT,
    request: settings.requestService(settings.toBody(example.toPassage)),
    reply: reply,
  )



#[ Entry ]#

func toCommand*(example: Example, service: Service): string =
  ## Render shell command replaying example under service from `DIRECTORY_EXAMPLES`, which
  ##   project folder runs: service named, and endpoint, model, effort and workspace set empty,
  ##   so no setting shell exports reaches run.
  "LOJBAN_TAGGER_SERVICE=" & $service & " LOJBAN_TAGGER_ENDPOINT= " &
      "LOJBAN_TAGGER_MODEL= LOJBAN_TAGGER_EFFORT= LOJBAN_TAGGER_WORKSPACE= " &
      "binaries/suggester --replay:" & DIRECTORY_EXAMPLES & " " & example.argument.quoteShell


proc writeExamples*(directory: string) =
  ## Write recordings of every example under `claude` and `openrouter` into directory, made
  ##   with each parent where missing, and given `MODE_EXAMPLES` whatever umask.
  createDir(directory)
  setFilePermissions(directory, MODE_EXAMPLES)
  for example in EXAMPLES:
    for service in [Service.Claude, Service.OpenRouter]:
      for recording in example.toRecordings(service):
        writeFile(directory / (recording.request.stamp & ".recording"), recording.toText)


proc main(): int =
  ## Write recordings of every example under `claude` and `openrouter`; print each command.
  writeExamples(DIRECTORY_EXAMPLES)
  for example in EXAMPLES:
    for service in [Service.Claude, Service.OpenRouter]:
      echo example.toCommand(service)
  0


when isMainModule:
  quit main()
