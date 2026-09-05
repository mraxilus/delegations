discard """
action: run
cmd: "nim c --hints:off -d:testing -d:nimUnittestAbortOnError:on $options $file"
batchable: true
joinable: true
"""
## Replicate glossary shape: Matt Pocock's CONTEXT.md format, checked structurally.

import std/[sequtils, strutils, unittest]
import ../src/glossary
import ./fixtures


func messages(source: string): seq[string] =
  ## Read finding messages of glossary text.
  checkGlossary("g", source).mapIt(it.message)


suite "Glossary":
  test "minimal glossary passes, with or without terms":
    check messages(GLOSSARY_TEXT).len == 0  # heading, description, Language, one term
    check messages("# Empty\n\nNothing resolved yet.\n\n## Language\n").len == 0  # lazy

  test "heading and Language section required":
    check messages("Intro\n\n## Language\n") ==
      @["Glossary must open with `# <Name>` heading."]  # heading
    check messages("# Name\n\n## Terms\n") == @["Glossary lacks `## Language` heading."]  # section

  test "every term carries definition on next line":
    check messages("# N\n\n## Language\n\n**Order**:\n\n**Invoice**:\nA request.\n") ==
      @["Term lacks definition on next line; got `Order`."]  # blank after term
    check messages("# N\n\n## Language\n\n**Order**:\n_Avoid_: Purchase\n") ==
      @["Term lacks definition on next line; got `Order`."]  # avoid before definition
    check messages("# N\n\n## Language\n\n**Order**:\nA placed request.\n_Avoid_: Purchase\n")
      .len == 0  # full entry
    check checkGlossary("g", "# N\n\n## Language\n\n**Order**:\n")[0].line == 5  # line named

  test "term line grammar":
    check "**Order**:".isTermLine and not "**Order**".isTermLine  # colon required
    check not "**:".isTermLine and not "Order:".isTermLine  # bold and content required
