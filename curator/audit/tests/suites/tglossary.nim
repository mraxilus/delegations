## Replicate glossary shape: Matt Pocock's CONTEXT.md format, checked structurally.

import std/[sequtils, strutils, unittest]
import ../../src/glossary
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

  test "people words glossary avoids stay out of governed prose":
    check peopleWordsIn("The owner merges by hand.") == @["owner"]
    check peopleWordsIn("Sessions end; each session carries its own.") == @["Sessions", "session"]
    check peopleWordsIn("Run `git config user.name` first.").len == 0  # code span
    check peopleWordsIn("The Architect and the delegate.").len == 0  # agreed terms
    check peopleWordsIn("The browser is used by many.").len == 0  # `used` is not `user`
    check peopleWordsIn("assets, agents").len == 1  # plural read as its word
    let found = checkPeopleWords("CURATOR.md", "# T\n\nowner\n| Author | x |\n```\nbot\n```\n")
    check found.mapIt(it.line) == @[3]  # table row and fence skipped
    check found[0].message.endsWith("got `owner`.")
