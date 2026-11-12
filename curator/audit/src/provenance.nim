## Enforce provenance header and rules stamp (Article VIII.6, provenance guide).
##   Header is first pipe table in file, `| Field | Value |`, with rows Harness, Author, Date,
##   Style, Rules, Review. Rules value is stamp of rules of content, so stale audit fails and
##   change of such rule cannot merge half-propagated. Stale stamp is propagation, so finding
##   is curator's in any project.
##
##   Stamp is FNV-1a 64-bit over `RULES` documents in order, each without its sections of
##     process (`SECTIONS_PROCESS`), CR stripped, NUL between files, rendered as 16 lowercase
##     hex digits. Section of process says what delegate does, never what project holds, so
##     its edit binds no project and moves no `Rules` row (D1 d of #843). `check-drift` still
##     names it to every older branch, since delegate forgets (`base.nim`).
##   List names sections of process, never sections of content, so it fails closed: new or
##     renamed heading stays stamped until list names it. Section that mixes both stays
##     stamped whole, as Boundaries and Glossary process do, since split would move what
##     contributor code cites. Listed heading its document lacks is finding, so rename leaves
##     no dead row.
##   Cost: edit of mixed section, or of opening above first `##` heading, re-stamps every
##     project as before.
##   Rejected: `std/sha1` (deprecated in Nim 2, warns on every build); `checksums` package
##     (nimble install in CI for one digest); `std/hashes` (unstable across Nim versions).
##   Cost: FNV-1a is change detector, not signature; collision needs adversary, none here.
##   CR stripped so Windows autocrlf checkouts stamp identically.
##
##   Review row is only human-written line: check demands presence, never content, because
##     checker cannot know whether human read anything.
##
##   Claim citing test is checked to cite real one: `Verified by \`x.nim\`` must name file
##     under project's `tests/`. That is only substance check in audit, and it is narrow one:
##     it proves citation resolves, never that named test makes claim beside it. Rest holds
##     by Architect's reading.
##   Citation not ending `.nim` is left alone, so backticked command such as
##     `atlas changed` passes.
##   Cost: claim verified by hand, in browser, or by tool absent from repository cannot be
##     checked at all; GUIDE.md asks such claim to name its tool and date instead.

{.experimental: "strictFuncs".}

import std/[sequtils, sets, strutils, tables]
import ./[findings, markdown]


const
  RULES* = ["CONSTITUTION.md", "STYLE.md", "CONTRIBUTOR.md", "EXAMPLES.md", "GUIDE.md"]
    ## Documents stamp covers, in digest order; CURATOR.md is excluded as curator-only.
  SECTIONS_PROCESS* = [
    ("CONTRIBUTOR.md", "## Read first, in this order"),
    ("CONTRIBUTOR.md", "## Every delegate begins here"),
    ("CONTRIBUTOR.md", "## Carry the unchecked list in the open"),
    ("CONTRIBUTOR.md", "## Branch and commits"),
    ("CONTRIBUTOR.md", "## Before you open a pull request"),
    ("GUIDE.md", "## The queue and the shared allowance"),
    ("GUIDE.md", "## Work for subagents"),
    ("GUIDE.md", "## How to build on a project"),
    ("GUIDE.md", "## Output contract"),
  ]
    ## Sections of process stamp leaves out, as rules document and heading line; every other
    ##   section is stamped, and CONSTITUTION.md, STYLE.md and EXAMPLES.md list none.
  FIELDS* = ["Harness", "Author", "Date", "Style", "Rules", "Review"]
    ## Header rows every PROVENANCE.md carries.
  CITATION* = "verified by `"
    ## Opening of claim naming test that repeats it; matched without case.
  EXT_NIM* = ".nim"  ## Extension citation must carry to be read as file rather than command.
  FNV_OFFSET = 0xcbf29ce484222325'u64
  FNV_PRIME = 0x100000001b3'u64


static:
  # Row outside rules documents, or off `##` heading, matches no section, so stamp would read
  #   that section whole while list claims it left out.
  for (document, heading) in SECTIONS_PROCESS:
    doAssert document in RULES, "Section of process lies in rules document; got `" & document &
      "`."
    doAssert heading.startsWith("## "), "Section of process opens at `## ` line; got `" &
      heading & "`."


func digest(data: openArray[string]): uint64 =
  ## Digest strings in order with FNV-1a 64-bit, CR removed, NUL between strings.
  result = FNV_OFFSET
  for k, s in data:
    if k > 0: result = (result xor 0'u64) * FNV_PRIME
    for c in s:
      if c == '\r': continue
      result = (result xor uint64(ord(c))) * FNV_PRIME


func stamp*(rules: openArray[string]): string =
  ## Render rules stamp as 16 lowercase hex digits.
  rules.digest.toHex(16).toLowerAscii


func textStamped(path, source: string): string =
  ## Read rules document as stamp digests it: every part but each section of process
  ##   `SECTIONS_PROCESS` lists for path.
  for part in source.sections:
    if (path, part.heading) notin SECTIONS_PROCESS: result.add part.text


func stampRules*(documents: openArray[string]): string =
  ## Render stamp of rules documents given in `RULES` order, each without its sections of
  ##   process.
  var stamped: seq[string]
  for k, rule in RULES: stamped.add textStamped(rule, documents[k])
  stamped.stamp


func checkSectionsProcess*(path, source: string): seq[Finding] =
  ## Report each section of process `SECTIONS_PROCESS` lists for document at path that it
  ##   lacks, so renamed heading never leaves row that matches nothing.
  let headings = source.sections.mapIt(it.heading)
  for (document, heading) in SECTIONS_PROCESS:
    if document == path and heading notin headings:
      result.add finding(
        path,
        0,
        "Section of process that stamp leaves out is absent; restore its heading, or rename " &
          "or drop its row of `SECTIONS_PROCESS` in `provenance.nim`; got `" & heading & "`.",
      )


func fieldsHeader*(source: string): Table[string, string] =
  ## Read first pipe table as field to value; empty when header row is absent.
  let rows = source.rowsTable
  if rows.len == 0 or rows[0] != @["Field", "Value"]: return
  for row in rows[1 .. ^1]:
    if row.len == 2 and row[0] notin result: result[row[0]] = row[1]


func rewriteRowRules*(source, stamp_new: string): string =
  ## Rewrite first `Rules` row's value to stamp, keeping every other byte; source unchanged
  ##   when no such row exists. Row is found as `fieldsHeader` finds it, by its first cell,
  ##   so what `koch stamp --write` sets is what check then reads.
  var is_done = false
  for line in source.splitLines(keepEol = true):
    let s = line.strip
    if not is_done and s.len >= 2 and s.startsWith("|") and s.endsWith("|"):
      let cells = s[1 ..< s.high].split('|')
      if cells.len == 2 and cells[0].strip == "Rules":
        let mid = line.find('|', line.find('|') + 1)
        result.add line[0 .. mid] & " " & stamp_new & " " & line[line.rfind('|') .. ^1]
        is_done = true
        continue
    result.add line


func isDateIso*(s: string): bool =
  ## Decide whether `s` is `YYYY-MM-DD`.
  s.len == 10 and s[4] == '-' and s[7] == '-' and
    (s[0 .. 3] & s[5 .. 6] & s[8 .. 9]).allCharsInSet(Digits)


func citations*(source: string): seq[string] =
  ## Collect test files claims cite, in order of appearance.
  let lower = source.toLowerAscii
  var i = 0
  while true:
    let at = lower.find(CITATION, i)
    if at < 0: break
    let
      open = at + CITATION.len
      close = source.find('`', open)
    if close < 0: break
    let name = source[open ..< close]
    if name.endsWith(EXT_NIM): result.add name
    i = close + 1


func checkCitations*(path, source, prefix_tests: string; paths: HashSet[string]): seq[Finding] =
  ## Report cited test absent from project's tests directory.
  for name in source.citations:
    if prefix_tests & name notin paths:
      result.add finding(
        path,
        0,
        "Claim cites test that is absent; write verification that can be repeated, or name " &
          "tool and date instead; got `" & name & "`.",
      )


func checkProvenance*(path, source, stamp_expected: string): seq[Finding] =
  ## Report missing header fields, malformed date, and stale rules stamp.
  let fields = source.fieldsHeader
  if fields.len == 0:
    return @[finding(path, 0, "Header table `| Field | Value |` missing or empty.")]
  for f in FIELDS:
    if f notin fields or fields[f].len == 0:
      result.add finding(path, 0, "Header lacks field; got `" & f & "`.")
  if "Date" in fields and not fields["Date"].isDateIso:
    result.add finding(path, 0, "Date must be `YYYY-MM-DD`; got `" & fields["Date"] & "`.")
  if "Rules" in fields and fields["Rules"] != stamp_expected:
    result.add finding(
      path,
      0,
      "Rules stamp stale; re-audit project, then set `" & stamp_expected & "`; got `" &
        fields["Rules"] & "`.",
      is_propagation = true,
    )
