## Read proposal exploration: argument, candidate change, claims, and proposal it builds on.
##   Proposal is future state of library, explored before Architect adopts any of it. One
##     directory each, one shape for all, so next exploration starts from same frame:
##
##     ```
##     proposals/<name>/proposal.md    argument: what, why, alternatives weighed, open decisions
##     proposals/<name>/change.md    candidate edits to library at pin (`changes.nim` format)
##     proposals/<name>/claims.json  proposal it builds on, and claims evaluation checks
##     proposals/<name>/*.nim        programs claim runs against changed library
##     ```
##
##   Change is optional: proposal that only adds programs above library carries none. Claims
##     are data rather than prose, so evaluation checks them and page shows verdicts beside them.
##   Claim kinds: `suites` (library's suites pass), `tables` (pairs of expressions, pristine
##     then changed, equal at named algebras), `program` (compiles and exits zero at named
##     algebras), `count` (one measurand's function spends stated value of one metric),
##     `build` (compiling bench entry costs at most stated share of pristine build, in peak
##     memory or seconds compiler reports).
##
##   Cost: builds-on chain is read one link deep per proposal; chain of three reads three.

{.experimental: "strictFuncs".}

import std/json

import ./[changes, guard, markdown]


type Proposal* = object
  ## Define one proposal exploration as read from its directory.
  name*: string
    ## Directory name, as `typed-multivectors`.
  title*: string
    ## Heading of `proposal.md`.
  body*: seq[Block]
    ## Blocks of `proposal.md` after title.
  change*: Change
    ## Candidate edits; none where proposal carries no `change.md`.
  builds_on*: string
    ## Proposal whose change applies first; empty where none.
  claims*: JsonNode
    ## Claims evaluation checks, in order.


const CLAIM_KINDS* = ["suites", "tables", "program", "count", "build"]
  ## Claim kinds evaluation knows how to check.


func parseProposal*(
  name, argument, change: string;
  claims: JsonNode;
  directory: string;
): (Proposal, seq[Finding]) =
  ## Read proposal from argument and change texts and parsed claims; `change` empty where proposal
  ##   carries none, `claims` nil where file is not JSON.
  var
    proposal = Proposal(name: name, claims: newJArray())
    findings: seq[Finding]
  let blocks = parseBlocks(argument)
  if blocks.len == 0 or blocks[0].kind != BlockKind.Heading or blocks[0].level != 1:
    findings.add Finding(
      path: directory & "/proposal.md",
      line: 1,
      message: "Proposal needs `# Title`; got none.",
    )
  else:
    proposal.title = blocks[0].lines[0]
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
    if claim{"kind"}.getStr == "program": result.add claim{"path"}.getStr
