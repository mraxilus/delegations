## Replicate glossary shape: Matt Pocock's CONTEXT.md format, checked structurally.

{.experimental: "strictFuncs".}

import std/[sequtils, strutils, unittest]
import ../../src/glossary
import ./fixtures


func messages(source: string): seq[string] =
  ## Read finding messages of glossary text.
  checkGlossary("g", source).mapIt(it.message)



suite "Glossary":
  test "minimal glossary passes, with or without terms":
    check messages(GLOSSARY_TEXT).len == 0  # heading, description, Standards, Language, term
    check messages("# Empty\n\nNone yet.\n\n## Standards\n\n## Language\n").len == 0  # lazy


  test "heading and both sections required, in order":
    check messages("Intro\n\n## Standards\n\n## Language\n") ==
      @["Glossary must open with `# <Name>` heading."]  # heading
    check messages("# Name\n\n## Terms\n") ==
      @["Glossary lacks `## Standards` heading.", "Glossary lacks `## Language` heading."]
    check messages("# Name\n\n## Language\n") == @["Glossary lacks `## Standards` heading."]
    check messages("# Name\n\n## Language\n\n## Standards\n") ==
      @["Glossary must put `## Standards` before `## Language`."]  # order


  test "standards entry names standard, owner and edition before its symbols":
    const
      head = "# N\n\n## Standards\n\n"
      tail = "\n\n## Language\n"
      good = head & "- **SI**, BIPM, 9th edition: `s` (Table 2)." & tail
    check messages(good).len == 0
    check messages(head & "- **SI**: `s`." & tail) ==
      @["Standard must read `- **Name**, owner and edition: symbols`; got `- **SI**: `s`.`."]
    check messages(head & "- SI, BIPM: `s`." & tail).len == 1  # no bold name
    check messages(head & "None yet." & tail & "\n- a list\n").len == 0  # prose and list outside
    check good.standardsIn == @[(5, "SI")]  # line and name
    check "- **SI**, BIPM, 9th edition: `s`.".isStandardLine
    check not "- **SI** BIPM: `s`.".isStandardLine  # comma after name required
    check not "- **SI**, BIPM".isStandardLine  # colon required


  test "standard shared by projects, or repeated from root, is finding at later place":
    const
      units = "- **SI**, BIPM, 9th: `s`.\n"
      astronomy = "- **IAU**, IAU, 2015: `pc`.\n"
      root = "# delegations\n\n## Standards\n\n" & units & "\n## Language\n"
      glossary_a = "# a\n\n## Standards\n\n" & units & astronomy & "\n## Language\n"
      glossary_b = "# b\n\n## Standards\n\n" & astronomy & "\n## Language\n"
    let found = checkStandardsAcross(
      [("GLOSSARY.md", root), ("x/a/GLOSSARY.md", glossary_a), ("x/b/GLOSSARY.md", glossary_b)],
    )
    check found.mapIt((it.path, it.line)) == @[("x/a/GLOSSARY.md", 5), ("x/b/GLOSSARY.md", 5)]
    check found[0].message.endsWith("got `SI`.")  # repeated from root
    check found[1].message.endsWith("got `IAU`, also in `x/a/GLOSSARY.md`.")  # shared
    check found.allIt(it.is_propagation)  # moving standard is curator's, never held
    check checkStandardsAcross([("GLOSSARY.md", root), ("x/b/GLOSSARY.md", glossary_b)]).len == 0


  test "every term carries definition on next line":
    const head = "# N\n\n## Standards\n\n## Language\n\n"
    check messages(head & "**Order**:\n\n**Invoice**:\nA request.\n") ==
      @["Term lacks definition on next line; got `Order`."]  # blank after term
    check messages(head & "**Order**:\n_Avoid_: Purchase\n") ==
      @["Term lacks definition on next line; got `Order`."]  # avoid before definition
    check messages(head & "**Order**:\nA placed request.\n_Avoid_: Purchase\n")
      .len == 0  # full entry
    check checkGlossary("g", head & "**Order**:\n")[0].line == 7  # line named


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
