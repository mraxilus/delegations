## Enforce provenance header and rules stamp (Article VIII.6, provenance guide).
##   Header is first pipe table in file, `| Field | Value |`, with rows Agent, Author, Date,
##   Style, Rules, Review. Rules value is stamp of governing documents, so stale audit fails
##   and rules change cannot merge half-propagated.
##
##   Stamp is FNV-1a 64-bit over `RULES` contents in order, CR stripped, NUL between files,
##     rendered as 16 lowercase hex digits.
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
##     checked at all; CONTRIBUTOR.md asks such claim to name its tool and date instead.

{.experimental: "strictFuncs".}

import std/[sets, strutils, tables]
import ./[findings, markdown]


const
  RULES* = ["CONSTITUTION.md", "STYLE.md", "CONTRIBUTOR.md"]
    ## Documents stamp covers, in digest order; CURATOR.md is excluded as curator-only.
  FIELDS* = ["Agent", "Author", "Date", "Style", "Rules", "Review"]
    ## Header rows every PROVENANCE.md carries.
  CITATION* = "verified by `"
    ## Opening of claim naming test that repeats it; matched without case.
  NIM_EXT* = ".nim"
    ## Extension citation must carry to be read as file rather than command.
  FNV_OFFSET = 0xcbf29ce484222325'u64
  FNV_PRIME = 0x100000001b3'u64


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


func headerFields*(source: string): Table[string, string] =
  ## Read first pipe table as field to value; empty when header row is absent.
  let rows = source.tableRows
  if rows.len == 0 or rows[0] != @["Field", "Value"]: return
  for row in rows[1 .. ^1]:
    if row.len == 2 and row[0] notin result: result[row[0]] = row[1]


func isIsoDate*(s: string): bool =
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
    let open = at + CITATION.len
    let close = source.find('`', open)
    if close < 0: break
    let name = source[open ..< close]
    if name.endsWith(NIM_EXT): result.add name
    i = close + 1


func checkCitations*(path, source, tests_prefix: string, paths: HashSet[string]): seq[Finding] =
  ## Report cited test absent from project's tests directory.
  for name in source.citations:
    if tests_prefix & name notin paths:
      result.add finding(
        path, 0,
        "Claim cites test that is absent; write verification that can be repeated, or name " &
          "tool and date instead; got `" & name & "`.",
      )


func checkProvenance*(path, source, stamp_expected: string): seq[Finding] =
  ## Report missing header fields, malformed date, and stale rules stamp.
  let fields = source.headerFields
  if fields.len == 0:
    return @[finding(path, 0, "Header table `| Field | Value |` missing or empty.")]
  for f in FIELDS:
    if f notin fields or fields[f].len == 0:
      result.add finding(path, 0, "Header lacks field; got `" & f & "`.")
  if "Date" in fields and not fields["Date"].isIsoDate:
    result.add finding(path, 0, "Date must be `YYYY-MM-DD`; got `" & fields["Date"] & "`.")
  if "Rules" in fields and fields["Rules"] != stamp_expected:
    result.add finding(
      path, 0,
      "Rules stamp stale; re-audit project, then set `" & stamp_expected & "`; got `" &
        fields["Rules"] & "`.",
    )
