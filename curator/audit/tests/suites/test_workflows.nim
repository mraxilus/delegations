## Replicate grant `permissions` block makes: scope left out is `none`, never left alone.

{.experimental: "strictFuncs".}

import std/[options, strutils, unittest]
import ../../src/workflows


const READS_RUNS = """
name: watch

permissions:
  contents: read
  issues: write

jobs:
  red:
    steps:
      - run: gh api "repos/$REPO/actions/runs/$RUN_ID"
"""
  ## Workflow reading runs and granting no `actions`, which block naming any scope sets to
  ## `none` rather than leaving alone, so read gets 403.



suite "Workflows":
  test "a scope the block leaves out is none, so using it is a finding":
    let found = checkScopes(".github/workflows/watch.yml", READS_RUNS)
    check found.len == 1
    check found[0].path == ".github/workflows/watch.yml"
    check "actions" in found[0].message
    # Message names what it read, so reader is not left guessing which scopes were granted.
    check "contents, issues" in found[0].message


  test "granting it clears the finding, and nothing else changes":
    let granted = READS_RUNS.replace("permissions:\n", "permissions:\n  actions: read\n")
    check checkScopes(".github/workflows/watch.yml", granted).len == 0


  test "each scope is reported once, however many steps reach for it":
    let twice = READS_RUNS & "      - run: gh run view \"$RUN_ID\"\n"
    check checkScopes("w.yml", twice).len == 1  # two marks, one scope, one finding


  test "a workflow declaring no block is left alone, since that is a decision":
    # Absent block takes repository default; empty block grants nothing. Only first
    #   is somebody's choice rather than drift, so only second is read.
    const blockless = "name: check\n\njobs:\n  a:\n    steps:\n      - run: gh issue list\n"
    check blockless.scopesPermission.isNone
    check checkScopes("check.yml", blockless).len == 0
    const empty = "name: c\n\npermissions:\n\njobs:\n  a:\n    steps:\n      - run: gh issue x\n"
    check empty.scopesPermission == some(newSeq[string]())
    check checkScopes("check.yml", empty).len == 1  # empty block grants nothing at all


  test "the block ends where indenting does, so later keys are not read as scopes":
    const after = """
permissions:
  contents: read

jobs:
  a:
    steps:
      - run: gh issue list
"""
    check after.scopesPermission == some(@["contents"])  # `jobs` and `a` are not scopes
    check checkScopes("w.yml", after).len == 1  # `gh issue` still wants `issues`


  test "a job-level block is left to its job, since only column zero is the whole grant":
    const nested = "name: x\n\njobs:\n  a:\n    permissions:\n      issues: write\n"
    check nested.scopesPermission.isNone


  test "listing pull requests wants `pull-requests`, which no other mark reaches":
    # `gh pr` is its own reach: `issues` does not cover it, so block granting only that
    #   loses it to `none`, and workflow listing pull requests gets 403.
    const listing = """
name: sweep

permissions:
  actions: read
  issues: write

jobs:
  a:
    steps:
      - run: gh pr list --state open --json number,isDraft
"""
    let found = checkScopes(".github/workflows/sweep.yml", listing)
    check found.len == 1
    check "pull-requests" in found[0].message
    check "actions, issues" in found[0].message  # names what was granted
    let granted = listing.replace("  issues: write\n", "  issues: write\n  pull-requests: read\n")
    check checkScopes(".github/workflows/sweep.yml", granted).len == 0


  test "a step that runs `gh` as a stored secret reaches by that secret, not the block":
    # Run token cannot convert pull request to draft, so `draft.yml` hands `gh` stored
    #   secret; block then grants nothing, and that is right rather than drift.
    const secret = """
name: draft

permissions: {}

jobs:
  a:
    steps:
      - env:
          GH_TOKEN: ${{ secrets.ADMIN_TOKEN }}
        run: gh pr ready "$NUMBER" --undo
"""
    check secret.isTokenOtherHanded
    check checkScopes("draft.yml", secret).len == 0
    let run_token = secret.replace("secrets.ADMIN_TOKEN", "github.token")
    check not run_token.isTokenOtherHanded
    check checkScopes("draft.yml", run_token).len == 1  # same step with run token wants grant
    # Run token spelled as secret is still run token, so block still binds.
    check not secret.replace("secrets.ADMIN_TOKEN", "secrets.GITHUB_TOKEN").isTokenOtherHanded


  test "a token minted in a step is not the run token either, so the block binds no `gh` mark":
    # `draft.yml` mints token of GitHub App in step, since fine-grained token is refused too.
    const minted = """
name: draft

permissions: {}

jobs:
  a:
    steps:
      - id: token
        uses: actions/create-github-app-token@v2
      - env:
          GH_TOKEN: ${{ steps.token.outputs.token }}
        run: gh pr ready "$NUMBER" --undo
"""
    check minted.isTokenOtherHanded
    check checkScopes("draft.yml", minted).len == 0


  test "weekly schedule and DAYS_RECENT name one window":
    # Window is named twice, as cron and as constant, so change of one alone is finding.
    const weekly =
      "on:\n  schedule:\n    - cron: '0 6 * * 1'\njobs:\n  a:\n    run: koch --recent\n"
    check weekly.daysCron == 7
    check checkWindow("check.yml", weekly, 7).len == 0
    check "got `7` days against `1`" in checkWindow("check.yml", weekly, 1)[0].message
    check weekly.replace("* * 1", "* * *").daysCron == 1
    check weekly.replace("* * 1", "* * 1-5").daysCron == 0  # shape untaught reads as 0
    check checkWindow("ledger.yml", weekly.replace("--recent", ""), 1).len == 0  # no window
