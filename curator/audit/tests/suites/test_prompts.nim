## Replicate CURATOR.md duty 10: prompts are short, and state rules rather than incidents.

{.experimental: "strictFuncs".}

import std/[sequtils, strutils, unittest]
import ../../src/[findings, prompts]



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
      found = checkPrompt("AGENTS.md", prompt)
    check found.mapIt(it.line) == @[9]  # fenced example passes, prose line named
    check found[0].brief.endsWith(
      "got `issue 25`; help: state rule and its cost here, and leave incident to record or log",
    )
    check found.anyIt(it.rule == "koch.prompt-incident")


  test "every file that opens delegate is prompt, entry file and coordinator's too":
    check @PATHS_PROMPT == @["AGENTS.md", "CONTRIBUTOR.md", "COORDINATOR.md", "CURATOR.md"]


  test "role file lacking heading of its reading order is finding, since start prints it":
    # Start prints reading order of role from section under that heading, so file that renames
    #   it prints empty list, and nothing else sees it. Domain: each role file, pinned, so list
    #   that drops one fails here; heading absent, cut to its first words, and quoted in fence
    #   alone; and entry file, which holds no reading order of role.
    let absent = "reading order of role that `start` prints is absent; got `" & HEADING_READ &
      "`; help: restore its heading, or rename `HEADING_READ` in `prompts.nim`"
    check @PATHS_ROLE == @["CONTRIBUTOR.md", "COORDINATOR.md", "CURATOR.md"]  # each role file
    for path in PATHS_ROLE:
      check checkPrompt(path, "# Role\n\nDuties.\n").mapIt(it.brief) == @[absent]
      check checkPrompt(path, "# Role\n\nDuties.\n").anyIt(it.rule == "koch.reading-heading")
      check checkPrompt(path, "# Role\n\n## Read first\n\n1. Read.\n").len == 1  # cut
      check checkPrompt(path, "# Role\n\n```md\n" & HEADING_READ & "\n```\n").len == 1  # fence
      check checkPrompt(path, "# Role\n\n" & HEADING_READ & "\n\n1. Read.\n").len == 0
    check checkPrompt("AGENTS.md", "# Entry\n\nRead file of role.\n").len == 0  # no role


  test "prompt over its byte ceiling is finding naming size":
    let
      long = "# P\n\n" & "x".repeat(BYTES_PROMPT)
      found = checkPrompt("AGENTS.md", long)
    check found.len == 1
    check found[0].brief == "prompt over " & $BYTES_PROMPT & " bytes (duty 10); got `" &
      $long.len & "`; expect `at most " & $BYTES_PROMPT & "`; help: prune before adding"
    check found.anyIt(it.rule == "koch.prompt-size")
    check checkPrompt("AGENTS.md", "x".repeat(BYTES_PROMPT)).len == 0  # at ceiling
