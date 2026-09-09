discard """
action: run
cmd: "nim c --hints:off -d:testing -d:nimUnittestAbortOnError:on $options $file"
batchable: true
joinable: true
"""
## Replicate grant `permissions` block actually makes, from 403 that taught it.

import std/[options, strutils, unittest]
import ../src/workflows


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
  ## Workflow as written when its first firing got 403: it reads runs and grants no
  ## `actions`, which block naming any scope sets to `none` rather than leaving alone.


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
    const NONE = "name: check\n\njobs:\n  a:\n    steps:\n      - run: gh issue list\n"
    check NONE.permissionScopes.isNone
    check checkScopes("check.yml", NONE).len == 0
    const EMPTY = "name: c\n\npermissions:\n\njobs:\n  a:\n    steps:\n      - run: gh issue x\n"
    check EMPTY.permissionScopes == some(newSeq[string]())
    check checkScopes("check.yml", EMPTY).len == 1  # empty block grants nothing at all

  test "the block ends where indenting does, so later keys are not read as scopes":
    const AFTER = """
permissions:
  contents: read

jobs:
  a:
    steps:
      - run: gh issue list
"""
    check AFTER.permissionScopes == some(@["contents"])  # `jobs` and `a` are not scopes
    check checkScopes("w.yml", AFTER).len == 1  # `gh issue` still wants `issues`

  test "a job-level block is left to its job, since only column zero is the whole grant":
    const NESTED = "name: x\n\njobs:\n  a:\n    permissions:\n      issues: write\n"
    check NESTED.permissionScopes.isNone
