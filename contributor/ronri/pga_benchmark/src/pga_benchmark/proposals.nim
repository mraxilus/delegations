## Read proposal exploration: argument, candidate change, claims, and proposal it builds on.
##   Proposal is future state of library, explored before Architect adopts any of it. One
##     directory each, same files for all, so next exploration starts from same frame:
##
##     ```
##     proposals/<NN>-<name>/proposal.md  argument, opening `# P<NN>: <title>`
##     proposals/<NN>-<name>/change.md    candidate edits to library at pin (`changes.nim`)
##     proposals/<NN>-<name>/claims.json  status, proposal it builds on, claims evaluation checks
##     proposals/<NN>-<name>/*.nim        programs claim runs, named relative to directory
##     ```
##
##   Number is proposal's for good, as RFC's is: allotted in order, never reused, and cited as
##     `P01`. Path and title both carry it, and `checkNumbers` holds them unique and gapless,
##     so no number is freed for another proposal.
##   Status is `proposed`, `implemented` (with library commit) or `withdrawn`. Proposal that is
##     not proposed is frozen: it stays, with its last evaluation, so its citation still leads
##     to what was proposed and measured, and it is no longer applied at pin.
##
##   Change is optional: proposal that only adds programs above library carries none. Claims
##     are data rather than prose, so evaluation checks them and page shows verdicts beside them.
##   Claim kinds: `suites` (library's suites pass), `tables` (pairs of expressions, pristine
##     then changed, equal at named algebras), `program` (compiles and exits zero at named
##     algebras), `count` (one measurand's function spends stated value of one metric),
##     `build` (compiling library alone costs at most stated share of pristine build, in peak
##     memory or seconds compiler reports).
##
##   Figure is paragraph of one image alone, as `![Derivation map](../../pages/map.svg)`: path
##     resolves against proposal's directory, and page embeds SVG it names. SVG lives under
##     `pages/`, since layout admits hand-written markup there alone.
##
##   Cost: builds-on chain is read one link deep per proposal; chain of three reads three.

{.experimental: "strictFuncs".}

import std/[json, options, strutils]

import ./[changes, guard, markdown]


type
  StatusProposal* {.pure.} = enum
    ## Define where proposal stands.
    Proposed, Implemented, Withdrawn
  Proposal* = object
    ## Define one proposal exploration as read from its directory.
    number*: int
      ## Number path and title carry, as `2`; zero where path gives none.
    name*: string
      ## Directory name after number, as `typed-multivectors`.
    directory*: string
      ## Project-relative directory, as `proposals/02-typed-multivectors`.
    title*: string
      ## Heading of `proposal.md` after its citation.
    status*: StatusProposal
      ## Where proposal stands.
    implemented_in*: string
      ## Library commit that implements proposal; empty unless implemented.
    body*: seq[Block]
      ## Blocks of `proposal.md` after title.
    change*: Change
      ## Candidate edits; none where proposal carries no `change.md`.
    builds_on*: string
      ## Name of proposal whose change applies first; empty where none.
    claims*: JsonNode
      ## Claims evaluation checks, in order.
  Figure* = object
    ## Define one figure proposal embeds.
    caption*: string
      ## Text under figure, as image alternative gives it.
    path*: string
      ## Project-relative path of SVG, as `pages/derivation-map.svg`.
    line*: int
      ## Line of `proposal.md` figure stands on, for findings.


const
  CLAIM_KINDS* = ["suites", "tables", "program", "count", "build"]
    ## Claim kinds evaluation knows how to check.
  NUMBER_WIDTH = 2
    ## Digits number is written with, zero-padded, in path and citation.
  STATUS_WORDS = ["proposed", "implemented", "withdrawn"]
    ## Status as `claims.json` spells it, in `StatusProposal` order.


func figureOf*(node: Block, directory: string): Option[Figure] =
  ## Read figure paragraph names: caption, and path resolved against `directory`.
  ##   Path has `..` folded.
  ##   None for any block that is not one image alone.
  ##   Caption may wrap over lines.
  if node.kind != BlockKind.Paragraph: return none(Figure)
  let
    line = node.lines.join(" ").strip
    middle = line.find("](")
  if not line.startsWith("![") or not line.endsWith(")") or middle < 0: return none(Figure)
  var parts: seq[string]
  for part in (directory & "/" & line[middle + 2 .. ^2]).split('/'):
    if part == "..":
      if parts.len > 0: parts.setLen(parts.len - 1)
    elif part.len > 0 and part != ".": parts.add part
  some(Figure(caption: line[2 ..< middle], path: parts.join("/"), line: node.line))


func citation*(proposal: Proposal): string =
  ## Cite proposal by its number, as `P02`.
  "P" & align($proposal.number, NUMBER_WIDTH, '0')


func isImplemented*(proposal: Proposal): bool =
  ## Tell whether library implements proposal, at commit proposal names.
  proposal.status == StatusProposal.Implemented


func isFrozen*(proposal: Proposal): bool =
  ## Tell whether proposal is implemented or withdrawn, so no longer applied at pin.
  proposal.status != StatusProposal.Proposed


func parseProposal*(
  argument, change: string;
  claims: JsonNode;
  directory: string;
): (Proposal, seq[Finding]) =
  ## Read proposal from its directory: argument and change texts and parsed claims.
  ##   `change` is empty where proposal carries none.
  ##   `claims` is nil where file is not JSON.
  var
    proposal = Proposal(directory: directory, claims: newJArray())
    findings: seq[Finding]
  let
    base = directory.rsplit('/', 1)[^1]
    dash = base.find('-')
  if dash == NUMBER_WIDTH and base[0 ..< dash].allCharsInSet(Digits):
    proposal.number = parseInt(base[0 ..< dash])
    proposal.name = base[dash + 1 .. ^1]
  else:
    proposal.name = base
    findings.add Finding(
      path: directory,
      message: "Proposal directory needs its number, as `01-" & base & "`; got `" & base & "`.",
    )
  let blocks = parseBlocks(argument)
  if blocks.len == 0 or blocks[0].kind != BlockKind.Heading or blocks[0].level != 1:
    findings.add Finding(
      path: directory & "/proposal.md",
      line: 1,
      message: "Proposal needs `# " & proposal.citation & ": Title`; got none.",
    )
  else:
    let heading = blocks[0].lines[0]
    if heading.startsWith(proposal.citation & ": "):
      proposal.title = heading[proposal.citation.len + 2 .. ^1]
    else:
      proposal.title = heading
      findings.add Finding(
        path: directory & "/proposal.md",
        line: 1,
        message: "Title must open with its citation, as `" & proposal.citation & ": `; got `" &
          heading & "`.",
      )
    proposal.body = blocks[1 .. ^1]
  if change.len > 0:
    let (parsed, why) = parseChange(directory & "/change.md", change)
    proposal.change = parsed
    findings.add why
  if claims.isNil or claims.kind != JObject:
    findings.add Finding(
      path: directory & "/claims.json",
      message: "Claims are not JSON object; got none.",
    )
    return (proposal, findings)
  proposal.builds_on = claims{"builds_on"}.getStr
  let status = claims{"status"}.getStr
  if status notin STATUS_WORDS:
    findings.add Finding(
      path: directory & "/claims.json",
      message: "Status must be proposed, implemented or withdrawn; got `" & status & "`.",
    )
  else:
    proposal.status = StatusProposal(STATUS_WORDS.find(status))
  proposal.implemented_in = claims{"implemented_in"}.getStr
  if proposal.status == StatusProposal.Implemented and proposal.implemented_in.len == 0:
    findings.add Finding(
      path: directory & "/claims.json",
      message: "Implemented proposal needs `implemented_in`, library commit; got none.",
    )
  let listed = claims{"claims"}
  if listed.isNil or listed.kind != JArray:
    findings.add Finding(
      path: directory & "/claims.json",
      message: "Claims need `claims` array; got none.",
    )
    return (proposal, findings)
  for claim in listed:
    let kind = claim{"kind"}.getStr
    if kind notin CLAIM_KINDS:
      findings.add Finding(
        path: directory & "/claims.json",
        message: "Claim kind unknown; got `" & kind & "`.",
      )
      continue
    proposal.claims.add claim
  (proposal, findings)


func programsOf*(proposal: Proposal): seq[string] =
  ## List program paths proposal's claims run, project-relative, in order.
  for claim in proposal.claims:
    if claim{"kind"}.getStr == "program":
      result.add proposal.directory & "/" & claim{"path"}.getStr


func checkNumbers*(proposals: openArray[Proposal]): seq[Finding] =
  ## Hold numbers unique and gapless from one, so none is freed or taken twice.
  var seen: seq[int]
  for proposal in proposals:
    if proposal.number == 0: continue
    if proposal.number in seen:
      result.add Finding(
        path: proposal.directory,
        message: "Proposal number is taken; got `" & proposal.citation & "`.",
      )
    seen.add proposal.number
  for number in 1 .. max(seen & @[0]):
    if number notin seen:
      result.add Finding(
        path: "proposals",
        message: "Proposal numbers skip one, so it was freed; got `P" &
          align($number, NUMBER_WIDTH, '0') & "` missing.",
      )
