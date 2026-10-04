## Read proposal exploration: argument, candidate change, claims, and proposals it builds on.
##   Proposal is future state of library, explored before Architect adopts any of it. One
##     directory each, same files for all, so next exploration starts from same frame:
##
##     ```
##     proposals/<NN>-<name>/proposal.md  argument, opening `# P<NN>: <title>`
##     proposals/<NN>-<name>/change.md    candidate edits to library at pin (`changes.nim`)
##     proposals/<NN>-<name>/claims.json  status, proposals it builds on, claims evaluation checks
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
##   Proposals build on others as graph without cycles, as Architect ruled on 2026-10-04: each
##     names those whose changes it needs, and is decided on its own. `dependenciesOf` lists
##     what adopting proposal needs first; `dependentsOf` lists what rejecting it blocks.
##
##   Cost: graph is walked once per proposal and again per dependent, so `n` proposals cost
##     `n²` walks; five cost twenty-five.

{.experimental: "strictFuncs".}

import std/[json, options, sequtils, strutils]

import ./[changes, guard, markdown]


type
  StatusProposal* {.pure.} = enum  ## Define where proposal stands.
    Proposed, Implemented, Withdrawn
  Proposal* = object  ## Define one proposal exploration as read from its directory.
    number*: int  ## Number path and title carry, as `2`; zero where path gives none.
    name*: string  ## Directory name after number, as `typed-multivectors`.
    directory*: string  ## Project-relative directory, as `proposals/02-typed-multivectors`.
    title*: string  ## Heading of `proposal.md` after its citation.
    status*: StatusProposal  ## Where proposal stands.
    implemented_in*: string  ## Library commit that implements proposal; empty unless implemented.
    body*: seq[Block]  ## Blocks of `proposal.md` after title.
    change*: Change  ## Candidate edits; none where proposal carries no `change.md`.
    builds_on*: seq[string]  ## Names of proposals whose changes apply first; empty where none.
    claims*: JsonNode  ## Claims evaluation checks, in order.
  Figure* = object  ## Define one figure proposal embeds.
    caption*: string  ## Text under figure, as image alternative gives it.
    path*: string  ## Project-relative path of SVG, as `pages/derivation-map.svg`.
    line*: int  ## Line of `proposal.md` figure stands on, for findings.


const
  KINDS_CLAIM* = ["suites", "tables", "program", "count", "build"]
    ## Claim kinds evaluation knows how to check.
  WIDTH_NUMBER = 2  ## Digits number is written with, zero-padded, in path and citation.
  WORDS_STATUS = ["proposed", "implemented", "withdrawn"]
    ## Status as `claims.json` spells it, in `StatusProposal` order.


func figureOf*(node: Block, directory: string): Option[Figure] =
  ## Read figure paragraph names: caption, and path resolved against `directory`.
  ##   Path has `..` folded.
  ##   None for any block that is not one image alone.
  ##   Caption may wrap over lines.
  if node.kind != KindBlock.Paragraph: return none(Figure)
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
  "P" & align($proposal.number, WIDTH_NUMBER, '0')


func isImplemented*(proposal: Proposal): bool =
  ## Tell whether library implements proposal, at commit proposal names.
  proposal.status == StatusProposal.Implemented


func isFrozen*(proposal: Proposal): bool =
  ## Tell whether proposal is implemented or withdrawn, so no longer applied at pin.
  proposal.status != StatusProposal.Proposed


func parseProposal*(
  argument, change: string; claims: JsonNode; directory: string
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
  if dash == WIDTH_NUMBER and base[0 ..< dash].allCharsInSet(Digits):
    proposal.number = parseInt(base[0 ..< dash])
    proposal.name = base[dash + 1 .. ^1]
  else:
    proposal.name = base
    findings.add Finding(
      path: directory,
      message: "Proposal directory needs its number, as `01-" & base & "`; got `" & base & "`.",
    )
  let blocks = parseBlocks(argument)
  if blocks.len == 0 or blocks[0].kind != KindBlock.Heading or blocks[0].level != 1:
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
  let bases = claims{"builds_on"}
  if bases.isNil or bases.kind != JArray or bases.getElems.anyIt(it.kind != JString):
    findings.add Finding(
      path: directory & "/claims.json",
      message: "Builds on must list proposal names, as `[\"cayley-derivation\"]`; got `" &
          (if bases.isNil: "none" else: $bases) & "`.",
    )
  else:
    for base in bases: proposal.builds_on.add base.getStr
  let status = claims{"status"}.getStr
  if status notin WORDS_STATUS:
    findings.add Finding(
      path: directory & "/claims.json",
      message: "Status must be proposed, implemented or withdrawn; got `" & status & "`.",
    )
  else:
    proposal.status = StatusProposal(WORDS_STATUS.find(status))
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
    if kind notin KINDS_CLAIM:
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
            align($number, WIDTH_NUMBER, '0') & "` missing.",
      )


func visit(
  proposals: openArray[Proposal];
  name, directory: string;
  walk: var seq[string];
  order: var seq[Proposal];
  findings: var seq[Finding];
) =
  ## Add proposal `name` to `order` after every proposal it builds on, depth first.
  ##   `walk` holds names on path from root, so name met twice on it is cycle.
  ##   Implemented proposal stops walk: library holds its edits.
  if name in walk:
    findings.add Finding(
      path: directory,
      message: "Proposals build on each other in cycle; got `" & name & "`.",
    )
    return
  if order.anyIt(it.name == name): return
  let found = proposals.filterIt(it.name == name)
  if found.len == 0:
    findings.add Finding(
      path: directory,
      message: "Proposal builds on no proposal here; got `" & name & "`.",
    )
    return
  if found[0].isImplemented: return
  if found[0].isFrozen:
    findings.add Finding(
      path: directory,
      message: "Proposal builds on withdrawn proposal; got `" & found[0].citation & "`.",
    )
    return
  walk.add name
  for base in found[0].builds_on: visit(proposals, base, directory, walk, order, findings)
  walk.setLen(walk.len - 1)
  order.add found[0]


func dependenciesOf*(
  proposals: openArray[Proposal], proposal: Proposal
): (seq[Proposal], seq[Finding]) =
  ## List proposals adopting `proposal` needs first, each after those it builds on.
  ##   Order is order changes apply in; implemented ones are absent, since library holds them.
  ##   Unknown names, withdrawn ones and cycles add findings at `proposal`'s directory.
  var
    walk = @[proposal.name]
    order: seq[Proposal]
    findings: seq[Finding]
  for base in proposal.builds_on:
    visit(proposals, base, proposal.directory, walk, order, findings)
  (order, findings)


func dependentsOf*(proposals: openArray[Proposal], proposal: Proposal): seq[Proposal] =
  ## List proposed proposals that rejecting `proposal` blocks, in number order.
  ##   Blocked one needs `proposal` directly or through another.
  for other in proposals:
    if other.isFrozen or other.name == proposal.name: continue
    if dependenciesOf(proposals, other)[0].anyIt(it.name == proposal.name): result.add other


func basesToward*(proposals: openArray[Proposal]; proposal, target: Proposal): seq[Proposal] =
  ## List bases `proposal` reaches `target` through, in number order.
  ##   Empty where proposal builds on target directly, since no path needs naming.
  if target.name in proposal.builds_on: return
  for base in proposals:
    if base.name in proposal.builds_on and
        dependenciesOf(proposals, base)[0].anyIt(it.name == target.name):
      result.add base
