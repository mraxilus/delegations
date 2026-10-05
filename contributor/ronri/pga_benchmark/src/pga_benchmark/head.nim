## Hold pin to library head, and measurements, evaluations and pages to pin.
##   Pages show library at pin, and pin follows library head, so what reader sees is library
##     as it stands. Four checks, each finding when it fails, none of them warnings:
##     - pin is head: library's directory at pin is same tree as at head of its repository;
##       verb `head` alone runs it, since its verdict moves with library;
##     - every measurement names pin: static and runtime baselines, every evaluation;
##     - every evaluation names digest of its edits, so edited change or proposal needs new
##       evaluation;
##     - every built page matches digest recorded when it was published.
##   Head is compared by tree of library's directory, never by commit: library lives in
##     directory of larger repository, and commit elsewhere in it changes nothing measured.
##   Checks are pure over values tool side reads (commits, trees, documents, digests), so
##     tests feed them; reading repository and network stays in driver.
##   Restamp: timed record names digest of C its timed builds emitted (`digest_c`). Where pin
##     moves and same builds emit same C at new pin, record moves its stamp to pin and keeps its
##     times, since same C makes same machine code on same compiler and flags; it names commit
##     it was timed at (`measured_at`). Record taken at pin before digests existed takes digest of
##     its builds there (Architect, 2026-10-05).
##     Rejected: timing again at each cosmetic head, which records drift of host alone.
##     Digest names each type hash, and any run of its shape, by order of first appearance,
##       since hash folds path of module into name of type; so any checkout takes same digest.
##     Cost: digest taken at record's own pin after its timing names C of that later build;
##       project code changed between them would go unseen, as stamp alone never saw it.
##
##   Cost: pin that lags head fails `head`, which `head.yml` runs daily and which keeps one
##     issue open until pin follows; no merge waits on it, so library moving is never red here.

{.experimental: "strictFuncs".}

import std/[algorithm, json, strutils, tables]

import ./guard
from ./changes import digestOf


const SHORT = 7  ## Digits of commit findings name, as `git log --oneline` prints.



#[ Library Head ]#

func short(commit: string): string =
  ## Shorten commit for findings.
  if commit.len > SHORT: commit[0..<SHORT] else: commit


func checkHead*(pin, tree_pin, head, tree_head, lock: string): seq[Finding] =
  ## Hold pin to head: library directory's tree at pin must equal its tree at head.
  if head.len == 0 or tree_head.len == 0:
    return @[Finding(path: lock, message: "Library head unread; got `" & head & "`.")]
  if tree_pin != tree_head:
    result.add Finding(
      path: lock,
      message: "Pin lags library head; follow head, re-baseline and re-run every evaluation; " &
          "got head `" & head.short & "`, pin `" & pin.short & "`.",
    )



#[ Measurements At Pin ]#

func checkStamp*(document: JsonNode; pin, path: string): seq[Finding] =
  ## Hold one measurement document to pin: it must be taken at pin's commit.

  func commitTaken(document: JsonNode): string =
    ## Read library commit document was taken at; empty where it names none.
    let node = document{"taken", "pga"}
    if node.isNil or node.kind != JString: "" else: node.getStr

  let taken = document.commitTaken
  if taken != pin:
    result.add Finding(
      path: path,
      message: "Measured at another library commit; re-take it at pin `" & pin.short &
          "`; got `" & taken.short & "`.",
    )


func checkEvaluation*(evaluation: JsonNode; pin, digest, path: string): seq[Finding] =
  ## Hold one evaluation to pin and to its edits: same commit, same digest of edits.
  result = checkStamp(evaluation, pin, path)
  let recorded = evaluation{"edits_digest"}
  if recorded.isNil or recorded.getStr != digest:
    result.add Finding(
      path: path,
      message: "Edits changed since evaluation; run `evaluate` again; got digest `" &
          (if recorded.isNil: "" else: recorded.getStr) & "`.",
    )



#[ Restamp ]#

func digestSources*(sources: openArray[(string, string)], pin: string): string =
  ## Digest C of one build: every file by name, in name order, with pin's commit left out, and
  ##   each run of 20 to 32 letters and digits after `__`, as Nim spells type hashes, named by
  ##   order of first appearance.
  ##   Few such runs are module names, as `pureZcollectionsZtables`; they read alike at any path.
  ##   Build names commit in documents it writes, so commit is text two pins' C differ by
  ##     even where library compiles alike.
  ##   Type hash folds path of module into name of type, so same tree at two checkout paths
  ##     emits C that differs in hashes alone; body of each type stays, so type that changes
  ##     shape still moves digest.

  func numbered(text: string, seen: var Table[string, string]): string =
    ## Replace each run of 20 to 32 letters and digits after `__` by `H` and its order.
    const
      alphanumeric = {'a'..'z', 'A'..'Z', '0'..'9'}
      width = 20..32
    result = newStringOfCap(text.len)
    var index = 0
    while index < text.len:
      if index + 1 < text.len and text[index] == '_' and text[index+1] == '_':
        var stop = index + 2
        while stop < text.len and text[stop] in alphanumeric: inc stop
        if stop - index - 2 in width:
          let hash = text[index+2..<stop]
          if hash notin seen: seen[hash] = "H" & $seen.len
          result.add "__" & seen[hash]
          index = stop
          continue
      result.add text[index]
      inc index

  var
    sorted = @sources
    seen: Table[string, string]
    text = ""
  sorted.sort
  for (name, source) in sorted:
    let pinless = if pin.len > 0: source.replace(pin, "") else: source
    text.add name & "\0" & pinless.numbered(seen) & "\0"
  digestOf(text)


func checkRestamp*(recorded, digests: JsonNode; taken, pin, path, again: string): seq[Finding] =
  ## Hold timed figures to C they were timed on: none where they may stand at pin.
  ##   Figures taken at pin stand without digest, and restamp records digest given.
  ##   `taken` is commit figures stand at, empty where they no longer stand anywhere.
  ##   `again` names verb that takes figures again.
  if recorded.isNil:
    if taken.len > 0 and taken == pin: return
    return @[Finding(
      path: path,
      message: "Not current at pin, and names no digest of C it was timed on; " & again &
          "; got `" & taken.short & "`.",
    )]
  if recorded != digests:
    result.add Finding(
      path: path,
      message: "Builds C other than C it was timed on; " & again & "; got `" & $digests & "`.",
    )


func isRestamped*(evaluation: JsonNode; pin, digest: string): bool =
  ## Tell whether evaluation stands at pin on its edits, with digest of C at every algebra, so
  ##   restamp has nothing to move; restamp cut short then resumes where it stopped.
  if checkEvaluation(evaluation, pin, digest, "").len > 0: return false
  let algebras = evaluation{"algebras"}
  if algebras.isNil or algebras.len == 0: return false
  for _, algebra in algebras.pairs:
    if not algebra.hasKey("digest_c"): return false
  true


func stampMoved*(taken: JsonNode, pin: string): JsonNode =
  ## Copy stamp moved to pin, naming commit figures were timed at where it moves.
  ##   Earlier `measured_at` stays, since figures were measured there and nowhere since.
  result = taken.copy
  let commit = result{"pga"}.getStr
  if commit != pin:
    if not result.hasKey("measured_at"): result["measured_at"] = %commit
    result["pga"] = %pin


func restamped*(document, digests: JsonNode; pin: string): JsonNode =
  ## Copy timed record standing at pin: its digests, and its stamp moved to pin.
  result = document.copy
  result["digest_c"] = digests
  result["taken"] = stampMoved(document{"taken"}, pin)



#[ Published Pages ]#

func checkPublished*(
  built: Table[string, string]; publications: JsonNode; readme, path: string
): seq[Finding] =
  ## Hold every built page to digest of its publication, and README to every URL.
  ##   Publications map page name to `url` and `digest`; README must name every URL, so reader
  ##   of repository finds each page and two copies of one URL cannot drift apart.
  for name, digest in built.pairs:
    let recorded = publications{name, "digest"}
    if recorded.isNil or recorded.getStr != digest:
      result.add Finding(
        path: path,
        message: "Page `" & name & "` changed since it was published; publish " &
            "`build/" & name & ".html`, then run `published " & name & " <url>`; got `" & digest &
            "`.",
      )
  for name, entry in publications.pairs:
    if name notin built:
      result.add Finding(
        path: path,
        message: "Publication names page build makes no more; got `" & name & "`.",
      )
    let url = entry{"url"}.getStr
    if url.len > 0 and url notin readme:
      result.add Finding(
        path: "README.md",
        message: "README omits URL page is published at; got `" & url & "`.",
      )
