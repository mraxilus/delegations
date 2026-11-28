## Replicate CURATOR.md duty 1: citation of section that its document lacks is finding.
##   Each case as found stands with its domain: `koch.nim` citing heading renamed, header of
##   `glossary.nim` citing heading that fence alone holds, and driver of pga_visualiser quoting
##   bold rule that is gone. Match is lenient, as Architect ruled (option b of #892).

{.experimental: "strictFuncs".}

import std/[sequtils, strutils, unittest]
import ../../src/[citations_section, findings, layout]
import ./fixtures


const  # TODO: Document.
  GUIDE = "# Guide\n\n## Work for subagents\n\nHand work off.\n\n## Output contract\n\n" &
    "### The sign-off\n\n#### The table\n\nRows.\n\n## Provenance guide\n\n" &
    "### Prune, never narrate\n\nCut.\n\n- **Verify by a run.** Claim needs run.\n"
    ## Guide of fixture: sections at levels two to four, heading holding comma, and bold rule
    ##   inside subsection.
  HELP = "; help: cite heading or bold rule it holds, or quote its text"
    ## Help that finding of section cited gives beside its sentence.
  CONTRIBUTOR_NOW = "# Contributor\n\n## TypeScript and Node\n\n" &
    "- **`web` builds it, `types` type-checks it, and `drive` drives it**, as three verbs.\n"
    ## `CONTRIBUTOR.md` as commit `930ffa742` left it: rule quoted below is gone.
  DRIVER = """
proc imgui() =
  ## Clone Dear ImGui at pinned commit, unless checkout already stands somewhere.
  ##   Verb fetches what it compiles rather than asking caller to, for reason `drive` fetches
  ##   font faces: check that first wants command run by hand is check runner will not run
  ##   (CONTRIBUTOR.md, "One command drives it").
  discard
"""
    ## Doc of `imgui` in driver of pga_visualiser as found: quote opens on its fifth line.
  KOCH = """
proc runHook() =
  ## Answer one hook event from its stdin facts; dispatch over event name.
  ##   `path`, `edit` and `bash` read checkout call acts in, never root alone: subagent works
  ##     in worktree of its own, on branch of its own (GUIDE.md, Independent changes). Call
  ##     acting in other repository is that repository's, so these three pass it unread.
  discard
"""
    ## Doc of `runHook` in `koch.nim` as found: citation opens on its fourth line.


func findingsTree(entries: varargs[Entry]): seq[Finding] =
  ## Run check over tree holding entries alone.
  @entries.checkCitationsSection


func citeIn(guide, section: string): seq[Finding] =
  ## Run check over guide and one comment of Nim citing section of it.
  findingsTree(entry("GUIDE.md", guide), entry("koch.nim", "## Do (GUIDE.md, " & section & ").\n"))


func cite(section: string): seq[Finding] =
  ## Run check over guide of fixture and one comment of Nim citing section of it.
  citeIn(GUIDE, section)


func citeFrom(tree: Tree; path, citation: string): seq[Finding] =
  ## Run check over tree with file at path holding one comment of citation.
  (tree & @[entry(path, "## Cite (" & citation & ").\n")]).checkCitationsSection



suite "Duty 1":
  test "citation of heading renamed is finding at its line, as found in `koch.nim`":
    # Case as found: `runHook` cited heading Independent changes of guide, renamed four days
    #   before to Work for subagents, so citation named nothing.
    let found = findingsTree(entry("GUIDE.md", GUIDE), entry("koch.nim", KOCH))
    check found.len == 1  # duty 1
    check found.len == 1 and found[0].path == "koch.nim" and found[0].line == 4  # its line
    check found.len == 1 and found[0].brief.endsWith("got `Independent changes`" & HELP)  # duty 1
    check found.len == 1 and "`GUIDE.md`" in found[0].brief  # names document lacking it
    let mended = KOCH.replace("Independent changes", "Work for subagents")
    check findingsTree(entry("GUIDE.md", GUIDE), entry("koch.nim", mended)).len == 0  # duty 1


  test "rename of heading is finding at each citation that names it, in every kind read":
    # Domain: one heading cited from Markdown and from comments of each syntax; rename leaves
    #   each citation naming nothing.
    let
      citations = [
        entry("README.md", "# Fixture\n\nSee (`GUIDE.md`, Work for subagents).\n"),
        entry("koch.nim", "## Drive (GUIDE.md, Work for subagents).\n"),
        entry(".github/workflows/check.yml", "# Run (GUIDE.md, Work for subagents).\nname: x\n"),
        entry("koch.nim.cfg", "# Flags (GUIDE.md, Work for subagents).\nhints:off\n"),
        entry("pages/main.ts", "// Draw (GUIDE.md, Work for subagents).\nlet x = 1;\n"),
        entry("pages/index.html", "<!-- Page (GUIDE.md, Work for subagents). -->\n<p></p>\n"),
      ]
      renamed = GUIDE.replace("## Work for subagents", "## Subagents")
    check findingsTree(@[entry("GUIDE.md", GUIDE)] & @citations).len == 0  # duty 1
    let found = findingsTree(@[entry("GUIDE.md", renamed)] & @citations)
    check found.mapIt(it.path) == citations.mapIt(it.path)  # one finding at each citation
    check found.allIt(it.brief.endsWith("got `Work for subagents`" & HELP))  # duty 1
    check found.mapIt(it.line) == @[3, 1, 1, 1, 1, 1]  # line citation stands on


  test "heading that fence alone holds names nothing, as found in `glossary.nim`":
    # Case as found: header of `glossary.nim` cited heading Language of guide, which stands only
    #   in fenced example of glossary format there; line meant root glossary.
    let
      guide = "# Guide\n\n## Glossary process\n\n```md\n## Language\n```\n"
      glossary = "# delegations\n\nWords.\n\n## Standards\n\n## Language\n\n**Architect**:\nOne.\n"
      header = "## Enforce glossary shape.\n##   People words: root files and curator records " &
        "are held\n##     to them outside code (GUIDE.md, Language). List is people only.\n"
      path = "curator/audit/src/glossary.nim"
      found = findingsTree(
        entry("GUIDE.md", guide), entry("GLOSSARY.md", glossary), entry(path, header)
      )
    check found.len == 1 and found[0].line == 3  # duty 1
    check found.len == 1 and found[0].brief.endsWith("got `Language`" & HELP)  # duty 1
    let mended = header.replace("GUIDE.md, Language", "GLOSSARY.md, Language")
    check findingsTree(
      entry("GUIDE.md", guide), entry("GLOSSARY.md", glossary), entry(path, mended)
    ).len == 0  # duty 1, root glossary holds it
    # Domain: heading in fence at each level names nothing, and outside fence names section.
    for level in 2 .. 6:
      let heading = "#".repeat(level) & " Language"
      check citeIn("# Guide\n\n```md\n" & heading & "\n```\n", "Language").len == 1  # fence
      check citeIn("# Guide\n\n" & heading & "\n", "Language").len == 0  # duty 1
    check citeIn("# Guide\n\n```md\n## Open\n\n## Language\n", "Language").len == 1  # left open


  test "citation inside fence of Markdown is example, never read":
    let
      fenced = "# Fixture\n\n```md\n(`GUIDE.md`, Independent changes)\n```\n"
      plain = "# Fixture\n\n(`GUIDE.md`, Independent changes)\n"
    check findingsTree(entry("GUIDE.md", GUIDE), entry("README.md", fenced)).len == 0  # fence
    check findingsTree(entry("GUIDE.md", GUIDE), entry("README.md", plain)).len == 1  # duty 1


  test "bold rule that is gone is finding, as found in driver of pga_visualiser":
    # Case as found: driver of pga_visualiser quoted bold rule One command drives it of
    #   contributor prompt, which commit `930ffa742` removed.
    let
      path = DIRECTORY_ALPHA & "/tools/build.nim"
      found = findingsTree(entry("CONTRIBUTOR.md", CONTRIBUTOR_NOW), entry(path, DRIVER))
    check found.len == 1 and found[0].path == path and found[0].line == 5  # duty 1
    check found.len == 1 and found[0].brief.endsWith("got `\"One command drives it\"`" & HELP)
    check found.len == 1 and "`CONTRIBUTOR.md`" in found[0].brief  # names document
    let before = CONTRIBUTOR_NOW & "\n- **One command drives it, and the runner runs that one.**\n"
    check findingsTree(entry("CONTRIBUTOR.md", before), entry(path, DRIVER)).len == 0  # held


  test "bold rule opens line or list item, and its text runs to closing `**`":
    # Domain: line, bullet, number and term of glossary each open bold rule, last stop or colon
    #   cut; bold text wrapping to next line reads whole; bold inside line opens none.
    let rules = "# Contributor\n\n## Boundaries\n\n- **Scope.** Only paths.\n" &
      "3. **A check that reddens a project.** Duty.\n\n**Hand work to subagents.** Read.\n\n" &
      "**Role**:\nString.\n\n- **Each subagent that changes files works in worktree of its own,\n" &
      "  on branch of its own.** Hooks read.\n\nText with **Inner rule** inside.\n"
    for section in [
      "Scope", "A check that reddens a project", "\"A check that reddens a project\"",
      "Hand work to subagents", "Role", "Each subagent that changes files",
      "Each subagent that changes files works in worktree of its own, on branch of its own",
      "Boundaries, Scope",
    ]:
      let found = findingsTree(
        entry("CONTRIBUTOR.md", rules),
        entry("koch.nim", "## Drive (CONTRIBUTOR.md, " & section & ").\n"),
      )
      check found.len == 0  # duty 1, bold rule
    let inner = findingsTree(
      entry("CONTRIBUTOR.md", rules), entry("koch.nim", "## Drive (CONTRIBUTOR.md, Inner rule).\n")
    )
    check inner.len == 1  # bold inside line opens no rule
    for opener in ["* ", "+ ", "> "]:
      let opened = "# Guide\n\n" & opener & "**Keep it short.** Text.\n"
      check citeIn(opened, "Keep it short").len == 0  # star, plus and quote open rule too
    check citeIn("# Guide\n\n**Open bold\n\n**Next.** Text.\n", "Open bold")
      .len == 1  # close is sought in paragraph of rule alone
    check citeIn("# Guide\n\n- **Scope.** Text.\n\n- **Role.** Text.\n", "Scope and Role")
      .len == 0  # last stop is cut, so `and` follows whole rule
    check citeIn("# Guide\n\n```md\n- **Keep it short.**\n```\n", "Keep it short")
      .len == 1  # rule that fence alone holds is example


  test "match passes case and articles, first words, and quote that document holds":
    # Lenient match, as Architect ruled (option b of #892): telegraphic comment drops articles.
    for section in [
      "Work For Subagents", "The Work for subagents", "Work", "Work for", "\"Hand work off\"",
      "`Hand work off`", "under \"Hand work off\"", "\"hand the work off.\"",
    ]:
      check cite(section).len == 0  # option b of #892
    let chain = "# Provenance\n\n## Rules of the chain\n\nRules.\n"
    check citeIn(chain, "Rules of chain").len == 0  # article dropped, as dance_ontology cites
    check citeIn("# Guide\n\n## An open question\n\nText.\n", "Open question")
      .len == 0  # `an` is article
    check citeIn("# Guide\n\n## A check that reddens\n\nText.\n", "Check that reddens")
      .len == 0  # `a` is article
    check citeIn("# Guide\n\n- **A check that reddens a project.** Duty.\n", "A check that reddens")
      .len == 0  # first words drop article too
    check cite("\"Claim needs run\"").len == 0  # quote of last words of document
    check findingsTree(
      entry("GUIDE.md", GUIDE), entry("koch.nim", "## Follow (GUIDE.md, Prune) and cut it.\n")
    ).len == 0  # first words end at first mark


  test "match fails where document holds no such heading, first words or text":
    for section in [
      "Work for agents", "Subagents", "Work for subagents now", "\"Hand work on\"",
      "`Hand off work`", "Output contract, The tables", "\"Hand off\"",
      "section \"Hand work on\"",
    ]:
      let found = cite(section)
      check found.len == 1  # duty 1
      check found.len == 1 and found[0].message.endsWith("got `" & section & "`.")  # as written
    check citeIn("# Guide\n\n```md\nKeep it short.\n```\n", "\"Keep it short\"")
      .len == 1  # quote that fence alone holds is example


  test "longest heading opening text wins, so heading holding comma reads whole":
    check cite("Prune, never narrate").len == 0  # comma inside heading
    check cite("Work for subagents, gives the test").len == 0  # prose after comma
    check cite("Work for subagents. Then more").len == 0  # stop ends citation
    let rules = "# Guide\n\n## Rules\n\nText.\n\n## Rules, Old and new\n\nText.\n"
    check citeIn(rules, "Rules, Old and new").len == 0  # longest wins over heading it opens
    let costs = "# Guide\n\n## Alpha\n\n### Cost\n\n#### Small\n\n## Beta\n\n### Cost\n\n" &
      "#### Large\n"
    check citeIn(costs, "Cost, Large").len == 0  # tie keeps each heading of that name
    let longer = "# Guide\n\n## Rules\n\n### Old\n\n## Rules of cost\n\n### Cost\n"
    check citeIn(longer, "Rules, Cost").len == 1  # mark ends name, so longer heading is unread


  test "subsection lies inside section before it, at any depth":
    check cite("Output contract, The sign-off").len == 0  # one level down
    check cite("Output contract, The table").len == 0  # two levels down
    check cite("Output contract, The sign-off, The table").len == 0  # each inside last
    check cite("Provenance guide, Prune, never narrate").len == 0  # comma in subsection
    check cite("Provenance guide, Verify by a run").len == 0  # bold rule inside
    check cite("Output contract, Prune, never narrate").len == 1  # lies in other section
    check cite("Work for subagents, The table").len == 1  # duty 1


  test "second section after `and` stands beside first":
    check cite("Work for subagents and Output contract").len == 0  # both stand
    let found = cite("Work for subagents and Figures")
    check found.len == 1 and found[0].brief.endsWith("got `Work for subagents and Figures`" & HELP)
    check cite("Work for subagents and the rest").len == 0  # prose after `and`
    let planned = "# Provenance\n\n## Planned turn\n\nTurn.\n\n## Figures\n\nTimes.\n"
    check citeIn(planned, "Planned turn and Figures").len == 0  # as dance_ontology cites
    check cite("Output contract, The sign-off and Prune, never narrate")
      .len == 1  # second section among candidates of first, so in same section


  test "heading is two to six `#` then space, so title and seventh level name none":
    let levels = "# Title\n\n## Two\n\n### Three\n\n#### Four\n\n##### Five\n\n###### Six\n\n" &
      "####### Seven\n\n##Glued\n"
    for section in ["Two", "Three", "Four", "Five", "Six"]:
      check citeIn(levels, section).len == 0  # duty 1
    for section in ["Title", "Seven", "Glued"]:
      check citeIn(levels, section).len == 1  # names no section


  test "forms that name no heading are skipped":
    for section in [
      "VI.5", "Article IV.7", "duty 3", "Duty 3", "duties 1 and 2", "section 4", "§5",
      "which every delegate reads", "`STYLE.md` and `EXAMPLES.md`", "`koch.nim`",
      "`<project>.nimble`", "README.md", "Section 4", "Duties 1 and 2",
    ]:
      check cite(section).len == 0  # names no heading
    check findingsTree(entry("koch.nim", "## Drive (NOTICE.md, Text).\n")).len == 0  # no file
    check findingsTree(
      entry("notes.md", "# Notes\n\n## Kept\n"), entry("koch.nim", "## Do (notes.md, Gone).\n")
    ).len == 0  # name in lower case names no document
    check findingsTree(entry("GUIDE.md", GUIDE), entry("koch.nim", "## (GUIDE.md,Nothing).\n"))
      .len == 0  # comma with no space opens no citation


  test "document resolves at nearest folder holding it, then root; path from root or file":
    let
      record = DIRECTORY_ALPHA & "/PROVENANCE.md"
      source = DIRECTORY_ALPHA & "/src/alpha.nim"
      tree = @[
        entry("GUIDE.md", GUIDE),
        entry(record, "# Provenance\n\n## Figures\n\nTimes.\n"),
        entry(DIRECTORY_ALPHA & "/src/GUIDE.md", "# Local\n\n## Local rule\n\nHere.\n"),
      ]
    check tree.citeFrom(source, "PROVENANCE.md, Figures").len == 0  # record of own project
    let found = tree.citeFrom(source, "PROVENANCE.md, Toolchain")
    check found.len == 1 and ("`" & record & "`") in found[0].brief  # names record resolved
    check tree.citeFrom(source, "GUIDE.md, Local rule").len == 0  # nearest folder wins
    check tree.citeFrom(source, "GUIDE.md, Work for subagents").len == 1  # root left unread
    check tree.citeFrom(DIRECTORY_ALPHA & "/tools/build.nim", "GUIDE.md, Work for subagents")
      .len == 0  # root, where no nearer folder holds it
    check tree.citeFrom("koch.nim", record & ", Figures").len == 0  # path from root
    check tree.citeFrom("koch.nim", record & ", Toolchain").len == 1  # duty 1
    check tree.citeFrom("koch.nim", "alpha/PROVENANCE.md, Toolchain").len == 0  # tree lacks
    check tree.citeFrom(source, "../PROVENANCE.md, Figures").len == 0  # from folder of file
    check tree.citeFrom(source, "../PROVENANCE.md, Toolchain").len == 1  # duty 1
    check tree.citeFrom(DIRECTORY_ALPHA & "/README.md", "./PROVENANCE.md, Toolchain")
      .len == 1  # `./` from folder of file
    check tree.citeFrom(source, "../../../../../PROVENANCE.md, Toolchain").len == 0  # above root
    check tree.citeFrom(source, "../../../../../GUIDE.md, Toolchain")
      .len == 0  # above root names nothing, though root holds guide


  test "comment lines that follow each other join, and line end ends name":
    let guide = entry("GUIDE.md", GUIDE)
    check findingsTree(guide, entry("koch.nim", "## Hand (GUIDE.md, Work for\n##   subagents).\n"))
      .len == 0  # wrapped citation reads whole
    let wrapped =
      findingsTree(guide, entry("koch.nim", "## Hand (GUIDE.md, Work for\n##   agents).\n"))
    check wrapped.len == 1 and wrapped[0].line == 1  # line document name stands on
    # Case held: suite of pga_benchmark ends two lines of code with comments, first citing heading
    #   with no stop after it; joined, second comment would read as rest of heading.
    let trailing = "check a  # GUIDE.md, Output contract\ncheck b  # reader sees more\n"
    check findingsTree(guide, entry("koch.nim", trailing)).len == 0  # line end ends name
    check findingsTree(guide, entry("koch.nim", trailing.replace(" contract", ""))).len == 0
    let markdown = "# Fixture\n\nSee (`GUIDE.md`, Work for\nsubagents) here.\n"
    check findingsTree(guide, entry("README.md", markdown)).len == 0  # paragraph reads whole
    let above = "## See GUIDE.md, Output\nlet x = 1  # contracts\n"
    check findingsTree(guide, entry("koch.nim", above)).len == 0  # after code, joins none above
    let below = "let x = 1  # See GUIDE.md, Output\n## contracts\n"
    check findingsTree(guide, entry("koch.nim", below)).len == 0  # line below continues none
    let between = "## See GUIDE.md, Output\nlet x = 1\n## contracts\n"
    check findingsTree(guide, entry("koch.nim", between)).len == 0  # code between keeps apart
    let paired = "## Hand (GUIDE.md, Work for\n##   subagents and Output contract).\n"
    check findingsTree(guide, entry("koch.nim", paired)).len == 0  # line end inside name passed
    let ended = "# Fixture\n\nSee GUIDE.md, Output contract\nfor more.\n"
    check findingsTree(guide, entry("README.md", ended)).len == 0  # line end ends name
    let cut = "# Fixture\n\nSee GUIDE.md, Output\n\ncontracts follow.\n"
    check findingsTree(guide, entry("README.md", cut)).len == 0  # blank line cuts paragraph
    let
      split = "## Hand work over, as\n## GUIDE.md, Independent changes says.\n"
      found = findingsTree(guide, entry("koch.nim", split))
    check found.len == 1 and found[0].line == 2  # finding at line that name opens on


  test "string literal and file of no comments are unread":
    let
      guide = entry("GUIDE.md", GUIDE)
      quoted = "let s = \"(GUIDE.md, Independent changes)\"\n"
    check findingsTree(guide, entry("koch.nim", quoted)).len == 0  # literal is data
    check findingsTree(guide, entry("package.json", "{\"x\": \"" & quoted & "\"}\n"))
      .len == 0  # kind of no comments
    check findingsTree(guide, entry("koch.nim", "let s = 1  # (GUIDE.md, Independent changes)\n"))
      .len == 1  # comment after code is read


  test "backtick closing span of whole citation ends it":
    # Domain: guide cites contributor prompt with name and heading in one code span.
    let contributor = entry("CONTRIBUTOR.md", "# Contributor\n\n## Boundaries\n\nScope.\n")
    check findingsTree(contributor, entry("README.md", "As `CONTRIBUTOR.md, Boundaries` does.\n"))
      .len == 0  # span ends citation
    check findingsTree(contributor, entry("README.md", "As `CONTRIBUTOR.md, Bounds` does.\n"))
      .len == 1  # duty 1
    let unopened = "## Run `cat GUIDE.md`, Then.\n"
    check findingsTree(entry("GUIDE.md", GUIDE), entry("koch.nim", unopened))
      .len == 0  # backtick closing name needs one opening it
