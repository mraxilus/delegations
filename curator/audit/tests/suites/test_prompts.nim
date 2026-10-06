## Replicate CURATOR.md duty 10: prompts are short, and state rules rather than incidents.

{.experimental: "strictFuncs".}

import std/[sequtils, strutils, unittest]
import ../../src/prompts



suite "Duty 10":
  test "diary reference is date, #N, issue N, pull request N or run N, outside code":
    check referenceDiary("Merged on 2026-09-06, then reverted.") == "2026-09-06"
    check referenceDiary("See #140 for the shape.") == "#140"
    check referenceDiary("Issue 25 asked twice.") == "Issue 25"
    check referenceDiary("after pull request 152 merged") == "pull request 152"
    check referenceDiary("ready after run 238 green") == "run 238"
    check referenceDiary("`#140 opened draft, ready after run 238 green`").len == 0  # code
    check referenceDiary("Article II.9 binds; duty 10 says so.").len == 0  # numbers alone
    check referenceDiary("Runs 3 configurations.") == "Runs 3"  # plural, capital
    check referenceDiary("Overrun 3 times").len == 0  # word bounded
    check referenceDiary("Nim 2.2.12 and 2026 alone").len == 0  # no whole date


  test "prompt lines naming incidents are findings, fences pass":
    let
      prompt = "# P\n\nRule.\n\n```\nissue 25\n```\n\nSince issue 25, rule.\n"
      found = checkPrompt("CURATOR.md", prompt)
    check found.mapIt(it.line) == @[9]  # fenced example passes, prose line named
    check found[0].message.endsWith("got `issue 25`.")


  test "every file that opens delegate is prompt, coordinator's too":
    check PATHS_PROMPT == ["CONTRIBUTOR.md", "COORDINATOR.md", "CURATOR.md"]


  test "prompt over its byte ceiling is finding naming size":
    let
      long = "# P\n\n" & "x".repeat(BYTES_PROMPT)
      found = checkPrompt("CONTRIBUTOR.md", long)
    check found.len == 1
    check found[0].message == "Prompt over " & $BYTES_PROMPT & " bytes; prune before adding " &
      "(duty 10); got `" & $long.len & "`."
    check checkPrompt("CONTRIBUTOR.md", "x".repeat(BYTES_PROMPT)).len == 0  # at ceiling
