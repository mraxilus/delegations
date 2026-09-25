## Hold pull request's opening role line and its labels to role its branch names.
##   Role line says who speaks; label says whose work it is. On pull request both are branch's
##     own role, since branch grammar names role and delegate on it writes under that role. So
##     one string, derived by `parseBranch`, answers for both, and check is equality rather
##     than presence.
##   Inputs arrive through environment: branch and body from event payload, label names from
##     API, since payload carries none on event that opens pull request.
##   `ledger.yml` reads same two facts daily over open items, which samples rather than gates:
##     pull request living half hour is almost never open when it runs, and it reports after
##     merge rather than before.
##
##   Branch outside grammar reports nothing here: `check-scope` already fails it, and expected role
##     cannot be derived from name grammar rejects.
##   Cost: issue carries no branch, so which label it needs is judgement, and stays ledger's.
##   Cost: comment is unreachable, and is what remains of CONTRIBUTOR.md's first carried rule.
##   Cost: labels are searched for expected string rather than compared whole, since label is
##     added when work hands across and never removed.
##   Empty label list can still be opening's own state rather than delegate's mistake: no API
##     call creates pull request and its label together, so label can land after run reads it,
##     and `labeled` event clears it. Message says so, and one naming wrong label does not.

{.experimental: "strictFuncs".}

import std/[options, strutils, unicode]
import ./[findings, domains]


const
  ROLE_KEY* = "**Role:**"
    ## Opening of role line, bold as every prompt and template writes it.
  COMMENT_OPEN* = "<!--"
    ## Opening of HTML comment, which unfilled template carries after key.
  ECHO_MAX* = 72
    ## Runes echoed back from opening line: it is whatever somebody typed, and body opening
    ## with whole paragraph would otherwise print that paragraph as finding.


func shortened*(line: string): string =
  ## Cut line to `ECHO_MAX` runes, marking cut where one was made.
  if line.runeLen <= ECHO_MAX: line else: line.runeSubStr(0, ECHO_MAX) & "…"


func roleLine*(body: string): string =
  ## Read first non-blank line of body, with any trailing HTML comment dropped.
  ##   Unfilled template opens `**Role:** <!-- curator, or ... -->`, which then reads as key
  ##   alone and fails equality below, rather than passing as line naming no role.
  for line in body.splitLines:
    let s = line.strip
    if s.len == 0: continue
    let open = s.find(COMMENT_OPEN)
    return (if open < 0: s else: s[0 ..< open].strip)
  ""


func checkRole*(branch, body: string, labels: openArray[string]): seq[Finding] =
  ## Report pull request whose opening line or labels do not name role its branch names.
  let parsed = branch.parseBranch
  if parsed.isNone: return
  let expected = parsed.get.roleName
  let opening = body.roleLine
  if opening != ROLE_KEY & " " & expected:
    result.add finding(
      "", 0,
      "Pull request must open with `" & ROLE_KEY & " " & expected &
        "`, which its branch names; got `" & opening.shortened & "`.",
    )
  if expected notin labels:
    let message =
      if labels.len == 0:
        "Pull request carries no label; one is applied after it opens, so the `labeled` " &
          "event clears this. Add `" & expected & "`, copied from branch grammar; got ``."
      else:
        "Pull request must carry label `" & expected & "`, copied from branch grammar; got `" &
          labels.join(", ") & "`."
    result.add finding("", 0, message)
