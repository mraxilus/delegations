## Drive measurement of this project: `nim r tools/build.nim <command>`.
##   Koch runs suites and holds no verb for instruments, so project carries its own driver
##   (CONTRIBUTOR.md, "Directories inside your project are yours"), one level down from koch.
##
##   |-----------|----------------------------------------------------------------------|
##   | Command   | Effect                                                               |
##   |-----------|----------------------------------------------------------------------|
##   | inspect   | compile bench entry per algebra to C, read it, write static          |
##   |           | measurements as `build/static_<algebra>.json`                        |
##   | bench     | compile and run bench per algebra, plain then instrumented, record   |
##   |           | runtime measurements as `baseline/runtime_<algebra>.json`            |
##   | baseline  | inspect, then record static measurements as                          |
##   |           | `baseline/static_<algebra>.json`                                     |
##   | guard     | compare last inspect against baseline; any count grown is finding    |
##   | trial     | try one change or design at pin, `stale` ones, or `all`, and record  |
##   |           | what each measured as `trials/<name>.json`                           |
##   | pages     | build every page from committed files into `build/<name>.html`       |
##   | published | record URL and digest of page just published, as                     |
##   |           | `published docket <url>`, in `pages/published.json`                  |
##   | drive     | inspect, guard, hold `gaps.md` to regeneration, and hold every       |
##   |           | measurement, trial, file and page to library head (`head.nim`)       |
##   | gaps      | regenerate `gaps.md` and docket from committed baselines             |
##   | show      | print one function's emitted C, its counts, its movement and its     |
##   |           | machine code, as `show ∧` or `show ⟇ cga5d`                          |
##   | sweep     | time general measurands at two to six dimensions, rigid; never in CI |
##   | system    | print system packages build needs, one per line, for caller         |
##   | clean     | remove `build`                                                       |
##   |-----------|----------------------------------------------------------------------|
##   Exit: 0 done, 1 command failed or finding, 2 usage error.
##   Runs from project directory, on compiler nimble file pins, since every path is
##     relative and every build compiles library. `drive` compares static counts only, no
##     timing, so runner's verdict on measurements is same as local one.
##   `drive` also reads library head over network, as Architect chose: pin that lags head is
##     finding on every push until pin follows, so pages always show library as it stands.
##   Cost: `drive` compiles bench and inspect entries once per algebra, seconds each.
##   Cost: `bench` and `trial` measurements name machine they were taken on; committing them
##     records that run and nothing more, as `PROVENANCE.md` says of every pair.

{.experimental: "strictFuncs".}

when compileOption("profiler"): import std/nimprof

import std/[algorithm, json, os, osproc, sequtils, strutils, tables, times]

import ../src/pga_benchmark/[changes, designs, gaps, guard, head, inspector, model, notes]
import ../src/pga_benchmark/pages/[docket, marginalia, shell]
import ../src/pga_benchmark/pages/design as page_design
import ../src/pga_benchmark/pages/trial as page_trial
from ../src/pga_benchmark/trials import
  Candidate, Toolchain, editsDigest, pristineBinary, pristineSuites, readLibrary, runTrial


const
  BUILD = "build"
    ## Directory caches, binaries and fresh documents land in; root `.gitignore` covers it.
  BASELINE = "baseline"
    ## Directory committed documents live in.
  PATH_GAPS = "gaps.md"
    ## Rendered list, committed.
  PATH_DOCKET = BASELINE / "docket.json"
    ## Identifier docket, committed.
  PATH_LOCK = "atlas.lock"
    ## Lock naming library commit.
  ENTRY_BENCH = "src/pga_benchmark/bench.nim"
    ## Entry reaching every measurand; its cache is what inspect reads.
  ENTRY_INSPECT = "src/pga_benchmark/inspect.nim"
    ## Entry reading cache, compiled per algebra for its catalogue.
  FLAGS = "-d:release"
    ## Build flags every measured build carries; documents name them.
  CONFIGS = [("rga4d", 4, false), ("cga5d", 5, true), ("rga3d", 3, false), ("cga4d", 4, true)]
    ## Algebras driven, typed ones first: name, dimensions, conformal.
  SWEEP = 2 .. 6
    ## Dimensions swept, rigid metric, general measurands only.
  SYSTEM = [
    ("git", "read library head and trees `drive` holds pin to"),
    ("curl", "fetch faces asked of shared store, one level down through `koch fetch-assets`"),
    ("coreutils", "`sha256sum` store checks those faces with"),
  ]
    ## System packages build needs beyond compiler. Compiler is toolchain, pinned in nimble
    ##   file; library is Atlas checkout, pinned in lock; faces come from repository's store.
  USAGE = "Usage: nim r tools/build.nim " &
    "<inspect|bench|baseline|guard|trial|pages|published|drive|gaps|show|sweep|system|clean>" &
    " [name|symbol] [url|algebra]\n"
    ## Text printed on usage error; trailing words serve `trial`, `published` and `show`.
  CHECKOUT = "dependencies" / "replications.mraxilus.gitlab.com"
    ## Atlas checkout of library's repository.
  LIBRARY_DIRECTORY = "lengyel/projective_geometric_algebra_illuminated"
    ## Library's directory inside its repository, as git names trees.
  LIBRARY = CHECKOUT / LIBRARY_DIRECTORY
    ## Library at pin, as `nim.cfg` names it.
  DIRECTORY_CHANGES = "changes"
    ## Changes, one Markdown file each (`changes.nim`).
  DIRECTORY_DESIGNS = "designs"
    ## Design explorations, one directory each (`designs.nim`).
  DIRECTORY_TRIALS = "trials"
    ## Trial documents, one per change or design, committed.
  PATH_NOTES = "marginalia" / "notes.md"
    ## Notes on library source (`notes.nim`).
  PATH_SHELL = "pages" / "shell.html"
    ## Shell every page is assembled in.
  PATH_PUBLICATIONS = "pages" / "published.json"
    ## Publications: page name to URL and digest at its last publish.
  PATH_README = "README.md"
    ## File that must name every published URL.
  PATH_KOCH = ".." / ".." / ".." / "koch.nim"
    ## Repository driver, asked for faces.
  TRIALED = ["rga4d", "cga5d"]
    ## Algebras trial measures: typed ones, which both lower bounds cover.
  TRIAL_RUNS = 5
    ## Timed runs of each binary per trial, alternating.
  TITLES = {"rga4d": "Rigid 4D", "cga5d": "Conformal 5D", "rga3d": "Rigid 3D",
    "cga4d": "Conformal 4D"}.toTable
    ## Tab title of each algebra on docket.
  SHOWN_LINES = 40
    ## Lines of one function this driver prints before naming file rest sits in.
  SHOWN_WIDTH = 150
    ## Characters of one line this driver prints before cutting it.



#[ Processes ]#

proc run(command: string; args: openArray[string]) =
  ## Run command with args from project directory; raise on non-zero exit.
  let
    process = startProcess(command, args = args, options = {poUsePath, poParentStreams})
    code = process.waitForExit
  process.close
  if code != 0:
    raise newException(OSError, command & " failed; got exit `" & $code & "`.")


proc nimCommit(): string =
  ## Read commit of compiler on PATH from its version text; `unmeasured` where absent.
  for line in execProcess("nim", args = ["-v"], options = {poUsePath}).splitLines:
    if line.startsWith("git hash: "): return line["git hash: ".len .. ^1].strip
  "unmeasured"


proc pgaCommit(): string =
  ## Read library commit from lock; `unmeasured` where lock names none.
  let items = parseJson(readFile(PATH_LOCK)){"items"}
  if items.isNil: return "unmeasured"
  for _, item in items.pairs: return item{"commit"}.getStr("unmeasured")
  "unmeasured"


func defines(dimensions: int; is_conformal: bool; nim, pga: string): seq[string] =
  ## Spell defines selecting algebra and naming build for its documents.
  @[
    "-d:pga.dimensions=" & $dimensions,
    "-d:pga.is_conformal=" & $is_conformal,
    "-d:pga_benchmark.nim_commit=" & nim,
    "-d:pga_benchmark.pga_commit=" & pga,
    "-d:pga_benchmark.flags=" & FLAGS,
  ]


proc compile(
  entry, binary, cache: string; dimensions: int; is_conformal: bool; nim, pga: string;
  extra: openArray[string] = [],
) =
  ## Compile entry for algebra into binary with its own cache.
  run(
    "nim",
    @["c", "--hints:off", FLAGS, "--nimcache:" & cache, "-o:" & binary] &
      defines(dimensions, is_conformal, nim, pga) & @extra & @[entry],
  )


proc readDocument(path: string): JsonNode =
  ## Read JSON document at path.
  parseJson(readFile(path))



#[ Commands ]#

proc inspect() =
  ## Compile bench entry per algebra to C only, then read its cache into document.
  let
    nim = nimCommit()
    pga = pgaCommit()
  createDir BUILD
  for (name, dimensions, is_conformal) in CONFIGS:
    let cache = BUILD / "cache_" & name
    removeDir cache
    compile(
      ENTRY_BENCH, BUILD / "bench_" & name, cache, dimensions, is_conformal, nim, pga,
      ["--compileOnly"],
    )
    let inspector = BUILD / "inspect_" & name
    compile(
      ENTRY_INSPECT, inspector, BUILD / "cache_inspect_" & name, dimensions, is_conformal,
      nim, pga,
    )
    run(inspector, [cache, BUILD / "static_" & name & ".json", nim, pga, FLAGS])


proc merged(plain, instrumented: JsonNode): JsonNode =
  ## Take timings from plain run and allocation counts from instrumented one.
  result = plain
  result["taken"]["is_allocation_measured"] = instrumented{"taken", "is_allocation_measured"}
  for id, measurand in instrumented{"measurands"}.pairs:
    for implementation in ["library", "reference"]:
      let measurement = measurand{implementation}
      if measurement.isNil or measurement.kind != JObject: continue
      if not result["measurands"].hasKey(id): continue
      let target = result["measurands"][id]{implementation}
      if target.isNil or target.kind != JObject: continue
      target["allocations"] = measurement{"allocations"}


proc bench() =
  ## Compile and run bench per algebra, plain for timings and instrumented for allocations,
  ## and record merged measurements into `baseline/`.
  let
    nim = nimCommit()
    pga = pgaCommit()
  createDir BUILD
  createDir BASELINE
  for (name, dimensions, is_conformal) in CONFIGS:
    let plain = BUILD / "bench_" & name
    compile(ENTRY_BENCH, plain, BUILD / "cache_" & name, dimensions, is_conformal, nim, pga)
    run(plain, [plain & ".json"])
    let instrumented = BUILD / "bench_alloc_" & name
    compile(
      ENTRY_BENCH, instrumented, BUILD / "cache_alloc_" & name, dimensions, is_conformal, nim,
      pga, ["-d:nimAllocStats"],
    )
    run(instrumented, [instrumented & ".json"])
    let
      doc = merged(readDocument(plain & ".json"), readDocument(instrumented & ".json"))
      recorded = BASELINE / "runtime_" & name & ".json"
    writeFile(recorded, pretty(doc) & "\n")
    echo "Recorded ", recorded


proc baseline() =
  ## Inspect, then record every algebra's counts as its baseline.
  inspect()
  createDir BASELINE
  for (name, _, _) in CONFIGS:
    copyFile(BUILD / "static_" & name & ".json", BASELINE / "static_" & name & ".json")
    echo "Recorded ", BASELINE / "static_" & name & ".json"


proc guarded(): seq[Finding] =
  ## Compare last inspect of every algebra against its baseline; print improvements.
  for (name, _, _) in CONFIGS:
    let
      path = BASELINE / "static_" & name & ".json"
      fresh = BUILD / "static_" & name & ".json"
    if not fileExists(path):
      result.add Finding(path: path, message: "No baseline recorded; run `baseline`.")
      continue
    if not fileExists(fresh):
      result.add Finding(path: path, message: "No inspect output to compare; run `inspect`.")
      continue
    let verdict = compare(readDocument(path), readDocument(fresh), path)
    for line in verdict.improvements: echo "notice: ", line
    result.add verdict.findings


proc report(findings: seq[Finding]) =
  ## Print findings and count, and fail where any.
  for f in findings: echo f.render
  echo $findings.len & " finding(s)."
  if findings.len > 0: quit 1


proc guard() =
  ## Compare and report.
  report(guarded())


proc algebras(): seq[Algebra] =
  ## Read every algebra's committed documents, in driven order; bench nil where absent.
  for (name, _, _) in CONFIGS:
    let path = BASELINE / "static_" & name & ".json"
    if not fileExists(path): continue
    var a = Algebra(name: name, measurements_static: readDocument(path))
    let path_runtime = BASELINE / "runtime_" & name & ".json"
    if fileExists(path_runtime): a.measurements_runtime = readDocument(path_runtime)
    result.add a


proc generated(): (string, string) =
  ## Generate list and docket text from committed documents.
  let
    ids =
      if fileExists(PATH_DOCKET): docketOf(readDocument(PATH_DOCKET)) else: docketOf(nil)
    (text, grown) = generate(algebras(), ids)
  (text, pretty(grown.toJson) & "\n")


proc gaps() =
  ## Regenerate list and docket.
  let (text, ids) = generated()
  createDir BASELINE
  writeFile(PATH_GAPS, text)
  writeFile(PATH_DOCKET, ids)
  echo "Wrote ", PATH_GAPS, " and ", PATH_DOCKET


#[ Changes And Designs ]#

proc readChanges(findings: var seq[Finding]): seq[(string, Change)] =
  ## Read every change file, in name order; malformed ones add findings.
  var paths = toSeq(walkFiles(DIRECTORY_CHANGES / "*.md"))
  paths.sort
  for path in paths:
    let (change, why) = parseChange(path, readFile(path))
    findings.add why
    result.add (path.splitFile.name, change)


proc readDesigns(findings: var seq[Finding]): seq[Design] =
  ## Read every design directory, in name order; malformed ones add findings.
  var directories: seq[string]
  for kind, path in walkDir(DIRECTORY_DESIGNS):
    if kind == pcDir: directories.add path
  directories.sort
  for directory in directories:
    let
      argument = directory / "design.md"
      change = directory / "change.md"
      claims = directory / "claims.json"
    var parsed: JsonNode = nil
    if fileExists(claims):
      try: parsed = parseJson(readFile(claims))
      except JsonParsingError: parsed = nil
    let (design, why) = parseDesign(
      directory.lastPathPart,
      if fileExists(argument): readFile(argument) else: "",
      if fileExists(change): readFile(change) else: "",
      parsed,
      directory,
    )
    findings.add why
    result.add design


proc candidatesOf(
  changes: seq[(string, Change)], designs: seq[Design], findings: var seq[Finding]
): seq[Candidate] =
  ## Shape one trial candidate per change and per design; design carries its base chain first.
  ##   Candidate's programs are program texts, so digest moves when program does.
  for (name, change) in changes:
    result.add Candidate(
      name: name,
      path: DIRECTORY_CHANGES / name & ".md",
      changes: @[change],
      claims: newJArray(),
    )
  for design in designs:
    let directory = DIRECTORY_DESIGNS / design.name
    if changes.anyIt(it[0] == design.name):
      findings.add Finding(path: directory, message: "Design shares name with change; got `" &
        design.name & "`.")
    var
      chain = @[design.change]
      seen = @[design.name]
      base = design.builds_on
    while base.len > 0:
      if base in seen:
        findings.add Finding(path: directory, message: "Designs build on each other in cycle; " &
          "got `" & base & "`.")
        break
      let found = designs.filterIt(it.name == base)
      if found.len == 0:
        findings.add Finding(path: directory, message: "Design builds on no design here; got `" &
          base & "`.")
        break
      chain.insert(found[0].change, 0)
      seen.add base
      base = found[0].builds_on
    var programs: seq[string]
    for path in programsOf(design):
      if fileExists(path): programs.add readFile(path)
      else: findings.add Finding(path: directory, message: "Claim runs no such program; got `" &
        path & "`.")
    result.add Candidate(
      name: design.name,
      path: directory,
      changes: chain,
      programs: programs,
      claims: design.claims,
    )


proc readTrials(): Table[string, JsonNode] =
  ## Read every committed trial, keyed by name.
  for path in walkFiles(DIRECTORY_TRIALS / "*.json"):
    result[path.splitFile.name] = readDocument(path)



#[ Library Head ]#

proc git(arguments: openArray[string]): (string, int) =
  ## Run git in library checkout with arguments; output and exit code.
  execCmdEx("git -C " & quoteShell(CHECKOUT) & " " & arguments.mapIt(quoteShell(it)).join(" "))


proc headChecked(pin: string): seq[Finding] =
  ## Hold pin to library head, and checkout to pin: no local edit under library directory.

  proc libraryHead(pin: string): (string, string, string) =
    ## Read tree of library directory at pin, and head commit of library repository with its
    ##   tree; empty where git cannot read one. Fetches only when head is not pin.
    let
      (output_pin, code_pin) = git(["rev-parse", pin & ":" & LIBRARY_DIRECTORY])
      tree_pin = if code_pin == 0: output_pin.strip.splitLines[^1] else: ""
      (remote, code_remote) = git(["ls-remote", "origin", "HEAD"])
    if code_remote != 0: return (tree_pin, "", "")
    var commit_head = ""
    for line in remote.splitLines:
      if line.endsWith("\tHEAD"): commit_head = line.split('\t')[0]
    if commit_head.len == 0: return (tree_pin, "", "")
    if commit_head == pin: return (tree_pin, commit_head, tree_pin)
    let (_, code_fetch) = git(["fetch", "--quiet", "origin", "HEAD"])
    if code_fetch != 0: return (tree_pin, commit_head, "")
    let (output_head, code_head) = git(["rev-parse", "FETCH_HEAD:" & LIBRARY_DIRECTORY])
    (tree_pin, commit_head, if code_head == 0: output_head.strip.splitLines[^1] else: "")

  let (tree_pin, commit_head, tree_head) = libraryHead(pin)
  result.add checkHead(pin, tree_pin, commit_head, tree_head, PATH_LOCK)
  let (edited, code) = git(["status", "--porcelain", "--", LIBRARY_DIRECTORY])
  if code != 0 or edited.strip.len > 0:
    result.add Finding(
      path: LIBRARY,
      message: "Library checkout differs from pin; restore it with `git -C " & CHECKOUT &
        " checkout -- .`; got `" & edited.strip.splitLines[0] & "`.",
    )



#[ Pages ]#

proc facesFromStore(): Table[string, string] =
  ## Ask `koch fetch-assets` for each face shell draws with, and read bytes of each.
  ##   Store checks digest; count of paths is asserted, since verb prints nothing for face
  ##   it could not serve, and short list would pair wrong bytes with right name.
  let (written, code) = execCmdEx(
    "nim r --hints:off --warnings:off " & quoteShell(PATH_KOCH) & " fetch-assets " &
      FACES.quoteShellCommand
  )
  if code != 0:
    raise newException(OSError,
      "`koch fetch-assets` would not serve every face; got exit `" & $code & "`.")
  var paths: seq[string]
  for line in written.strip.splitLines:
    if line.strip.len > 0 and fileExists(line.strip): paths.add line.strip
  if paths.len != FACES.len:
    raise newException(OSError,
      "`koch fetch-assets` named " & $paths.len & " paths for " & $FACES.len & " faces.")
  for index, face in FACES: result[face] = readFile(paths[index])


proc publications(): JsonNode =
  ## Read publication of every published page; empty where none.
  if fileExists(PATH_PUBLICATIONS): readDocument(PATH_PUBLICATIONS) else: newJObject()


proc builtPages(faces: Table[string, string]): OrderedTable[string, string] =
  ## Build every page from committed files: docket, marginalia, then one per design.

  func linksHtml(names: openArray[string]; published: JsonNode; self: string): string =
    ## Link every other published page, in page order, led by separator; empty where none.
    var links: seq[string]
    for name in names:
      let url = published{name, "url"}.getStr
      if name == self or url.len == 0: continue
      links.add "<a href=\"" & url & "\">" & name & "</a>"
    if links.len == 0: "" else: " · " & links.join(" · ")

  func titled(name: string): string =
    ## Title design page by its name, as `Cayley Derivation`.
    name.split('-').mapIt(it.capitalizeAscii).join(" ")

  var ignored: seq[Finding]
  let
    pin = pgaCommit()
    published = publications()
    text_shell = readFile(PATH_SHELL)
    changes = readChanges(ignored)
    designs = readDesigns(ignored)
    trials = readTrials()
    files = readLibrary(LIBRARY)
    (notes, _) = parseNotes(PATH_NOTES, readFile(PATH_NOTES))
    names = @["docket", "marginalia"] & designs.mapIt(it.name)
  var
    sheets: seq[Sheet]
    baselines: Table[string, JsonNode]
    overlays: seq[Overlay]
    documents: seq[JsonNode]
  for (name, dimensions, _) in CONFIGS:
    let path = BASELINE / "static_" & name & ".json"
    if not fileExists(path): continue
    baselines[name] = readDocument(path)
    sheets.add Sheet(
      name: name,
      title: TITLES[name],
      dimensions: dimensions,
      measurements_static: baselines[name],
      measurements_runtime: readDocument(BASELINE / "runtime_" & name & ".json"),
    )
  for _, document in trials.pairs: documents.add document
  let spread = spreadOf(documents)
  for design in designs:
    if design.name notin trials: continue
    var overlay = Overlay(name: design.name, title: design.title,
      url: published{design.name, "url"}.getStr)
    for algebra, measured in trials[design.name]{"algebras"}.pairs:
      overlay.functions[algebra] = measured{"functions"}
    overlays.add overlay
  result["docket"] = assemble(text_shell, "PGA Gap Docket",
    docketBody(sheets, readDocument(PATH_DOCKET), overlays, pin,
      linksHtml(names, published, "docket")), faces)
  var proposals: seq[Proposal]
  for (name, change) in changes:
    proposals.add Proposal(name: name, change: change, trial: trials.getOrDefault(name))
  result["marginalia"] = assemble(text_shell, "PGA Marginalia",
    marginaliaBody(proposals, notes, files, baselines, spread, pin,
      linksHtml(names, published, "marginalia")), faces)
  for design in designs:
    result[design.name] = assemble(text_shell, titled(design.name),
      designBody(design, trials.getOrDefault(design.name), files, baselines, spread, pin,
        linksHtml(names, published, design.name)), faces)


proc pages() =
  ## Build every page into `build/`, and print each with its digest.
  createDir BUILD
  for name, page in builtPages(facesFromStore()).pairs:
    writeFile(BUILD / name & ".html", page)
    echo "Built ", BUILD / name & ".html", "  ", pageDigest(page), "  ", page.len div 1024,
      " KiB"


proc publishedAt(name, url: string) =
  ## Record page just published: its URL, and digest of page as built now.
  let built = builtPages(facesFromStore())
  if name notin built:
    raise newException(ValueError, "No page named `" & name & "`.")
  var entries = publications()
  entries[name] = %*{"url": url, "digest": pageDigest(built[name])}
  writeFile(PATH_PUBLICATIONS, pretty(entries) & "\n")
  echo "Recorded ", name, " at ", url
  for other, page in built.pairs:
    if other != name and entries{other, "digest"}.getStr != pageDigest(page):
      echo "notice: ", other, " differs from its publication; publish it and record it too."



#[ Trials ]#

proc trialOf(which: string) =
  ## Try one change or design at pin, every one for `all`, or those `drive` would name for
  ##   `stale`; write each trial document.

  func machine(): string =
    ## Describe machine trial ran on, as bench documents do.
    hostOS & " " & hostCPU & ", " & $countProcessors() & " cores"

  var findings: seq[Finding]
  let
    changes = readChanges(findings)
    designs = readDesigns(findings)
    candidates = candidatesOf(changes, designs, findings)
  if findings.len > 0: report(findings)
  let
    pin = pgaCommit()
    tried = readTrials()
    selected = case which
      of "all": candidates
      of "stale": candidates.filterIt(it.name notin tried or checkTrial(tried[it.name], pin,
        editsDigest(it.changes, it.claims, it.programs), "").len > 0)
      else: candidates.filterIt(it.name == which)
  if selected.len == 0 and which == "stale":
    echo "Every trial is current."
    return
  if selected.len == 0: raise newException(ValueError, "No change or design named `" & which &
    "`.")
  let chain = Toolchain(library: LIBRARY, work: BUILD / "trials", nim: nimCommit(),
    pga: pgaCommit(), flags: FLAGS, runs: TRIAL_RUNS)
  var
    algebras: seq[trials.Algebra]
    baselines: Table[string, JsonNode]
    pristine: Table[string, string]
  for (name, dimensions, is_conformal) in CONFIGS:
    if name notin TRIALED: continue
    let algebra = trials.Algebra(name: name, dimensions: dimensions, is_conformal: is_conformal)
    algebras.add algebra
    baselines[name] = readDocument(BASELINE / "static_" & name & ".json")
    pristine[name] = pristineBinary(chain, algebra)
  let
    suites_pin = pristineSuites(chain, algebras)
    taken = %*{"date": now().format("yyyy-MM-dd"), "machine": machine(), "nim": chain.nim,
      "pga": chain.pga, "flags": FLAGS, "runs": TRIAL_RUNS}
  createDir DIRECTORY_TRIALS
  for candidate in selected:
    echo "Trying ", candidate.name
    let (document, why) = runTrial(chain, candidate, algebras, baselines, pristine, suites_pin,
      taken)
    removeDir chain.work / candidate.name
    if document.isNil:
      findings.add why
      continue
    writeFile(DIRECTORY_TRIALS / candidate.name & ".json", pretty(document) & "\n")
    echo "Recorded ", DIRECTORY_TRIALS / candidate.name & ".json"
  report(findings)


proc pinnedChecked(pin: string): seq[Finding] =
  ## Hold everything to pin: stamps, trials, changes, designs, notes, pages and publications.
  for (name, _, _) in CONFIGS:
    for kind in ["static", "runtime"]:
      let path = BASELINE / kind & "_" & name & ".json"
      if fileExists(path): result.add checkStamp(readDocument(path), pin, path)
  let
    changes = readChanges(result)
    designs = readDesigns(result)
    candidates = candidatesOf(changes, designs, result)
    files = readLibrary(LIBRARY)
    trials = readTrials()
  for candidate in candidates:
    var copy = files
    for change in candidate.changes: result.add applyChange(copy, change, candidate.path)
    let path = DIRECTORY_TRIALS / candidate.name & ".json"
    if candidate.name notin trials:
      result.add Finding(path: path, message: "No trial yet; run `trial " &
        candidate.name & "`.")
      continue
    let digest = editsDigest(candidate.changes, candidate.claims, candidate.programs)
    result.add checkTrial(trials[candidate.name], pin, digest, path)
  for name in trials.keys:
    if not candidates.anyIt(it.name == name):
      result.add Finding(path: DIRECTORY_TRIALS / name & ".json",
        message: "Trial names no change or design; got `" & name & "`.")
  let (notes, why) = parseNotes(PATH_NOTES, readFile(PATH_NOTES))
  result.add why
  result.add checkAnchors(notes, files, PATH_NOTES)
  var digests: Table[string, string]
  for name, page in builtPages(facesFromStore()).pairs: digests[name] = pageDigest(page)
  result.add checkPublished(digests, publications(), readFile(PATH_README), PATH_PUBLICATIONS)


proc drive() =
  ## Inspect, check against baselines, hold committed list and docket to regeneration, and
  ##   hold pin to library head and every measurement, trial, file and page to pin.
  let pin = pgaCommit()
  var findings = headChecked(pin)
  inspect()
  findings.add guarded()
  let (text, ids) = generated()
  if not fileExists(PATH_GAPS) or readFile(PATH_GAPS) != text:
    findings.add Finding(path: PATH_GAPS, message: "List differs from regeneration; run `gaps`.")
  if not fileExists(PATH_DOCKET) or readFile(PATH_DOCKET) != ids:
    findings.add Finding(
      path: PATH_DOCKET,
      message: "Docket differs from regeneration; run `gaps`.",
    )
  findings.add pinnedChecked(pin)
  report(findings)


proc sweep() =
  ## Time general measurands at every swept dimension, rigid metric, and print medians.
  let
    nim = nimCommit()
    pga = pgaCommit()
  createDir BUILD
  var docs: seq[JsonNode]
  for dimensions in SWEEP:
    let
      name = "sweep_" & $dimensions & "d"
      binary = BUILD / name
    compile(ENTRY_BENCH, binary, BUILD / "cache_" & name, dimensions, false, nim, pga)
    run(binary, [binary & ".json"])
    docs.add readDocument(binary & ".json")
  var header = "measurand".alignLeft(26)
  for dimensions in SWEEP: header.add ($dimensions & "d").align(10)
  echo header
  for id, _ in docs[0]{"measurands"}.pairs:
    var line = id.alignLeft(26)
    for doc in docs:
      let measurement = doc{"measurands", id, "library"}
      line.add(
        if measurement.isNil or measurement.kind != JObject: "–".align(10)
        else: formatFloat(measurement{"ns_median"}.getFloat, ffDecimal, 1).align(10),
      )
    echo line


func shortened(text, stem, plain: string): string =
  ## Replace mangled type name and its hash with plain one, wherever stem appears.
  var i = 0
  while true:
    let at = text.find(stem & "__", i)
    if at < 0:
      result.add text[i .. ^1]
      break
    result.add text[i ..< at]
    result.add plain
    var j = at + stem.len + 2
    while j < text.len and (text[j].isAlphaNumeric or text[j] == '_'): inc j
    i = j


func unindexed(text: string): string =
  ## Replace `(((Basis) n) - 0)` with `n`, which is what compiler spells there.
  const OPEN = "(((Basis) "
  const CLOSE = ") - 0)"
  var i = 0
  while true:
    let at = text.find(OPEN, i)
    if at < 0:
      result.add text[i .. ^1]
      break
    let close = text.find(CLOSE, at)
    if close < 0:
      result.add text[i .. ^1]
      break
    result.add text[i ..< at]
    result.add text[at + OPEN.len ..< close]
    i = close + CLOSE.len


func readable(text: string): string =
  ## Rewrite emitted C so reader sees types and slots rather than hashes.
  ##   Reading aid alone: cache holds exact text every count is read from.
  text.shortened(MULTIVECTOR, "Multivector").shortened("tyEnum_Basis", "Basis").unindexed


proc disassembled(cache, name: string): seq[string] =
  ## Read machine code of one function from whichever object file in cache holds it.
  for path in walkFiles(cache / "*.o"):
    let (text, code) = execCmdEx("objdump -d --no-show-raw-insn " & quoteShell(path))
    if code != 0: continue
    var is_inside = false
    for line in text.splitLines:
      if line.contains("<" & name & ">:"): is_inside = true
      if not is_inside: continue
      result.add line
      if line.contains("\tret"): return
    if result.len > 0: return


proc showFunction(symbol, algebra: string) =
  ## Print one emitted function: what it is, what it spends, what it moves, what it becomes.
  ##   Compiles bench entry whole rather than to C alone, so cache holds object file and
  ##   machine code can be read beside C. Reads that cache with same inspector every
  ##   measurement uses, so figures here and figures in `gaps.md` come from one reading.
  var found_algebra = false
  for (name, dimensions, is_conformal) in CONFIGS:
    if name != algebra: continue
    found_algebra = true
    let
      nim = nimCommit()
      pga = pgaCommit()
    createDir BUILD
    let cache = BUILD / "cache_show_" & name
    compile(ENTRY_BENCH, BUILD / "show_" & name, cache, dimensions, is_conformal, nim, pga)
    let size = 8 shl dimensions
    var seen = 0
    for f in inspectCache(cache):
      if f.symbol != symbol: continue
      inc seen
      let
        c = f.body.count
        m = movement(f, c, size)
      echo ""
      echo "── ", f.symbol, "(", f.parameters.join(","), ") → ", f.stem_result,
        "   ", algebra, ", ", size, "-byte multivector"
      echo "   emitted as ", (if f.is_inline: "static N_INLINE" else: "N_NIMCALL"),
        " `", f.name, "`"
      echo ""
      echo "   counts, callees folded in"
      echo "     multiplies    ", c.multiplies
      echo "     divides       ", c.divides
      echo "     zero fills    ", c.zero_fills, "   × ", size, " bytes"
      echo "     intermediates ", c.intermediates, "   × ", size, " bytes"
      echo "     copies        ", c.copies, "   × ", size, " bytes"
      echo "     error checks  ", c.checks
      echo "     lines of C    ", c.lines
      echo ""
      echo "   bytes moved = operands read + result written"
      echo "               + (zero fills + intermediates + copies) × width"
      echo "     operands read     ", m.bytes_read
      echo "     result written    ", m.bytes_written
      echo "     zero fills        ", m.bytes_zeroed
      echo "     intermediates     ", m.bytes_intermediates
      echo "     copies            ", m.bytes_copied
      echo "     ───────────────── ", m.bytes_moved
      echo ""
      echo "   emitted C"
      var printed = 0
      for line in f.body.readable.splitLines:
        if printed >= SHOWN_LINES:
          echo "     … ", c.lines - printed, " more lines; whole body is in ", cache
          break
        echo "     ", (if line.len > SHOWN_WIDTH: line[0 ..< SHOWN_WIDTH] & " …" else: line)
        inc printed
      echo ""
      echo "   machine code"
      let lines = disassembled(cache, f.name)
      if lines.len == 0:
        echo "     no symbol of its own, since it is inline; read its caller instead."
        continue
      for i, line in lines:
        if i >= SHOWN_LINES:
          echo "     … ", lines.len - i, " more instructions."
          break
        echo "     ", line
    if seen == 0:
      echo "No function spells `", symbol, "` in ", algebra, "."
  if not found_algebra:
    raise newException(ValueError, "No algebra named `" & algebra & "`.")


proc system() =
  ## Print every system package this build needs, one per line and nothing else.
  for (package, _) in SYSTEM: echo package


proc clean() =
  ## Remove every product, leaving only what git holds.
  removeDir BUILD
  echo "Removed ", BUILD



#[ Entry Point ]#

when isMainModule:
  let
    verb = if paramCount() > 0: paramStr(1) else: ""
    arguments =
      case verb
      of "show": 2 .. 3
      of "trial": 2 .. 2
      of "published": 3 .. 3
      else: 1 .. 1
  if paramCount() notin arguments:
    stderr.write USAGE
    quit 2
  try:
    case paramStr(1)
    of "show":
      showFunction(paramStr(2), if paramCount() >= 3: paramStr(3) else: CONFIGS[0][0])
    of "inspect": inspect()
    of "bench": bench()
    of "baseline": baseline()
    of "guard": guard()
    of "trial": trialOf(paramStr(2))
    of "pages": pages()
    of "published": publishedAt(paramStr(2), paramStr(3))
    of "drive": drive()
    of "gaps": gaps()
    of "sweep": sweep()
    of "system": system()
    of "clean": clean()
    else:
      stderr.write USAGE
      quit 2
  except CatchableError as e:
    stderr.write e.msg & "\n"
    quit 1
