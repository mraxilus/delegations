discard """
action: run
cmd: "nim c --hints:off -d:testing -d:nimUnittestAbortOnError:on $options $file"
batchable: true
joinable: true
"""
## Replicate CURATOR.md duty 10: prompts are short, and state rules rather than incidents.

import std/[sequtils, strutils, unittest]
import ../src/prompts


suite "Duty 10":
  test "diary reference is date, #N, issue N, pull request N or run N, outside code":
    check diaryReference("Merged on 2026-09-06, then reverted.") == "2026-09-06"
    check diaryReference("See #140 for the shape.") == "#140"
    check diaryReference("Issue 25 asked twice.") == "Issue 25"
    check diaryReference("after pull request 152 merged") == "pull request 152"
    check diaryReference("ready after run 238 green") == "run 238"
    check diaryReference("`#140 opened draft, ready after run 238 green`").len == 0  # code
    check diaryReference("Article II.9 binds; duty 10 says so.").len == 0  # numbers alone
    check diaryReference("Runs 3 configurations.") == "Runs 3"  # plural, capital
    check diaryReference("Overrun 3 times").len == 0  # word bounded
    check diaryReference("Nim 2.2.12 and 2026 alone").len == 0  # no whole date

  test "prompt lines naming incidents are findings, fences pass":
    let prompt = "# P\n\nRule.\n\n```\nissue 25\n```\n\nSince issue 25, rule.\n"
    let found = checkPrompt("CURATOR.md", prompt)
    check found.mapIt(it.line) == @[9]  # fenced example passes, prose line named
    check found[0].message.endsWith("got `issue 25`.")

  test "prompt over its byte ceiling is finding naming size":
    let long = "# P\n\n" & "x".repeat(PROMPT_BYTES)
    let found = checkPrompt("CONTRIBUTOR.md", long)
    check found.len == 1
    check found[0].message == "Prompt over " & $PROMPT_BYTES & " bytes; prune before adding " &
      "(duty 10); got " & $long.len & "."
    check checkPrompt("CONTRIBUTOR.md", "x".repeat(PROMPT_BYTES)).len == 0  # at ceiling
