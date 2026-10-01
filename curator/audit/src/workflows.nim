## Hold each workflow's `permissions` block to scopes its own steps use.
##   Block is whole grant rather than addition to default: scope left out of it is set to
##   `none`, not left alone. So workflow naming one scope silently loses every other, and
##   loss shows as `403` on runner rather than as anything readable here.
##   Written after that happened: `watch.yml` named `contents` and `issues`, and its first
##   firing failed reading run it was pointed at, because naming those two revoked
##   `actions: read` it never mentioned.
##
##   Check is deliberately narrow. It reads what steps call, not what they might, and reports
##   only scope that some step demonstrably uses and block leaves out. Workflow declaring no
##   block at all is left alone: it takes repository default, which is somebody's decision
##   rather than drift.
##   Workflow that hands `gh` stored secret, and never run token, reaches by that secret's
##   grant, which no block here sets, so its `gh` marks are skipped. Written when `draft.yml`
##   moved to `ADMIN_TOKEN`, since run token cannot convert pull request to draft.
##   Cost: marks below are text, so step reaching same endpoint by other spelling goes unseen.
##   That is floor, never ceiling -- check catches what it names and claims nothing else.

{.experimental: "strictFuncs".}

import std/[options, strutils]
import ./findings


const
  WORKFLOW_DIRECTORY* = ".github/workflows/"
    ## Directory every workflow lives in.
  PERMISSIONS_KEY* = "permissions:"
    ## Line opening grant, at column zero; job-level block is indented and left to its job.
  CHECKOUT_MARK* = "actions/checkout"
    ## Step that takes run token by default, whatever `GH_TOKEN` env says.
  SCOPE_MARKS* = [
    ("actions", "/actions/"),
    ("actions", "gh run "),
    ("issues", "gh issue "),
    ("pull-requests", "gh pr "),
    ("contents", CHECKOUT_MARK),
  ]
    ## Text step uses scope by, paired with scope it then needs. Endpoint path is what `gh api`
    ## spells; `gh run`, `gh issue` and `gh pr` are same reach through subcommand.
    ## `pull-requests` arrived late: no workflow read pull requests until sweep did, so gap
    ## sat unseen behind check written to stop exactly it.
  RUN_TOKEN_MARKS* = ["${{ github.token }}", "secrets.GITHUB_TOKEN"]
    ## Text that hands run token to step.
  SECRET_TOKEN_MARK* = "GH_TOKEN: ${{ secrets."
    ## Text that hands `gh` stored secret; run token spelled as secret is caught above.


func usesRunToken(workflow: string): bool =
  ## Whether some step of workflow holds run token, by text of `RUN_TOKEN_MARKS`.
  for mark in RUN_TOKEN_MARKS:
    if mark in workflow: return true


func runsAsSecret*(workflow: string): bool =
  ## Whether `gh` runs as stored secret and no step holds run token, so block binds no `gh` mark.
  SECRET_TOKEN_MARK in workflow and not workflow.usesRunToken


func permissionScopes*(workflow: string): Option[seq[string]] =
  ## Read scopes workflow's own top-level `permissions` block names; `none` when it has none.
  ##   Absent block and empty block differ: absent takes repository default, empty grants
  ##   nothing, and only first is left alone.
  var scopes: seq[string]
  var is_inside = false
  for line in workflow.splitLines:
    if line.startsWith(PERMISSIONS_KEY):
      is_inside = true
      continue
    if not is_inside: continue
    if line.len > 0 and line[0] notin {' ', '\t'}: break
    let s = line.strip
    if s.len == 0 or s.startsWith("#"): continue
    let named = s.split(':')[0].strip
    if named.len > 0 and named notin scopes: scopes.add named
  if is_inside: some(scopes) else: none(seq[string])


func checkScopes*(path, workflow: string): seq[Finding] =
  ## Report scope workflow's steps use that its own `permissions` block leaves out.
  let granted = workflow.permissionScopes
  if granted.isNone: return
  let is_secret = workflow.runsAsSecret
  var reported: seq[string]
  for (scope, mark) in SCOPE_MARKS:
    if mark notin workflow or scope in granted.get or scope in reported: continue
    if mark != CHECKOUT_MARK and is_secret: continue  # `gh` reaches by secret's grant
    reported.add scope
    result.add finding(
      path, 0,
      "Steps use `" & mark & "`, so `permissions` must grant `" & scope &
        "`; block is whole grant and scope left out is `none`; got `" &
        granted.get.join(", ") & "`.",
    )
