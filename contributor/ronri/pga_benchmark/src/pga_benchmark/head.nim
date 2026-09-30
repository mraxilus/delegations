## Hold what this project keeps to library head: pin, measurements, evaluations and pages.
##   Pages show library at pin, and pin must be library head, so what reader sees is library
##     as it stands. Four checks, each finding when it fails, none of them warnings:
##     - pin is head: library's directory at pin is same tree as at head of its repository;
##     - every measurement names pin: static and runtime baselines, every evaluation;
##     - every evaluation names digest of its edits, so edited change or proposal needs new
##       evaluation;
##     - every built page matches digest recorded when it was published.
##   Head is compared by tree of library's directory, never by commit: library lives in
##     directory of larger repository, and commit elsewhere in it changes nothing measured.
##   Checks are pure over values tool side reads (commits, trees, documents, digests), so
##     tests feed them; reading repository and network stays in driver.
##
##   Cost: pin that lags head fails every push of this project until pin follows, as
##     Architect chose; library moving is work here, never something to wait out.

{.experimental: "strictFuncs".}

import std/[json, strutils, tables]

import ./guard


const SHORT = 7
  ## Digits of commit findings name, as `git log --oneline` prints.



#[ Library Head ]#

func short(commit: string): string =
  ## Shorten commit for findings.
  if commit.len > SHORT: commit[0 ..< SHORT] else: commit


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

  func takenPga(document: JsonNode): string =
    ## Read library commit document was taken at; empty where it names none.
    let node = document{"taken", "pga"}
    if node.isNil or node.kind != JString: "" else: node.getStr

  let taken = document.takenPga
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
