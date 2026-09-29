## Read design exploration: argument, candidate change, claims, and design it builds on.
##   Design is future state of library, explored before Architect adopts any of it. One
##     directory each, one shape for all, so next exploration starts from same frame:
##
##     ```
##     designs/<name>/design.md    argument: what, why, alternatives weighed, open decisions
##     designs/<name>/change.md    candidate edits to library at pin (`changes.nim` format)
##     designs/<name>/claims.json  design it builds on, and claims trial checks
##     designs/<name>/*.nim        programs claim runs against changed library
##     ```
##
##   Change is optional: design that only adds programs above library carries none. Claims
##     are data rather than prose, so trial checks them and page shows verdicts beside them.
##   Claim kinds: `suites` (library's suites pass), `tables` (pairs of expressions, pristine
##     then changed, equal at named algebras), `program` (compiles and exits zero at named
##     algebras), `count` (one measurand's function spends stated value of one metric),
##     `build` (compiling bench entry costs at most stated share of pristine build, in peak
##     memory or seconds compiler reports).
##
##   Cost: builds-on chain is read one link deep per design; chain of three reads three.

{.experimental: "strictFuncs".}

import std/json

import ./[changes, guard, markdown]


type Design* = object
  ## Define one design exploration as read from its directory.
  name*: string
    ## Directory name, e.g. `typed-multivectors`.
  title*: string
    ## Heading of `design.md`.
  body*: seq[Block]
    ## Blocks of `design.md` after title.
  change*: Change
    ## Candidate edits; none where design carries no `change.md`.
  builds_on*: string
    ## Design whose change applies first; empty where none.
  claims*: JsonNode
    ## Claims trial checks, in order.


const CLAIM_KINDS* = ["suites", "tables", "program", "count", "build"]
  ## Claim kinds trial knows how to check.


func parseDesign*(
  name, argument, change: string, claims: JsonNode, directory: string
): (Design, seq[Finding]) =
  ## Read design from argument and change texts and parsed claims; `change` empty where design
  ##   carries none, `claims` nil where file is not JSON.
  var
    design = Design(name: name, claims: newJArray())
    findings: seq[Finding]
  let blocks = parseBlocks(argument)
  if blocks.len == 0 or blocks[0].kind != BlockKind.Heading or blocks[0].level != 1:
    findings.add Finding(
      path: directory & "/design.md",
      line: 1,
      message: "Design needs `# Title`; got none.",
    )
  else:
    design.title = blocks[0].lines[0]
    design.body = blocks[1 .. ^1]
  if change.len > 0:
    let (parsed, why) = parseChange(directory & "/change.md", change)
    design.change = parsed
    findings.add why
  if claims.isNil or claims.kind != JObject:
    findings.add Finding(
      path: directory & "/claims.json",
      message: "Claims are not JSON object; got none.",
    )
    return (design, findings)
  design.builds_on = claims{"builds_on"}.getStr
  let listed = claims{"claims"}
  if listed.isNil or listed.kind != JArray:
    findings.add Finding(
      path: directory & "/claims.json",
      message: "Claims need `claims` array; got none.",
    )
    return (design, findings)
  for claim in listed:
    let kind = claim{"kind"}.getStr
    if kind notin CLAIM_KINDS:
      findings.add Finding(
        path: directory & "/claims.json",
        message: "Claim kind unknown; got `" & kind & "`.",
      )
      continue
    design.claims.add claim
  (design, findings)


func programsOf*(design: Design): seq[string] =
  ## List program paths design's claims run, project-relative, in order.
  for claim in design.claims:
    if claim{"kind"}.getStr == "program": result.add claim{"path"}.getStr
