## Replicate umbrella: whole static audit over fixture tree, and stamp derivation.

{.experimental: "strictFuncs".}

import std/[algorithm, sequtils, strutils, unittest]
import ../../../knoller/src/knoller
import ../../src/[audit, provenance]
import ./fixtures



suite "Audit":
  test "good tree is clean under every static check":
    check goodTree().auditTree.len == 0  # layout, form, prose, provenance, glossary


  test "rules stamp derives from tree contents in RULES order":
    check goodTree().rulesStamp == stamp(RULES_TEXT)  # same digest as fixture
    check goodTree().without("STYLE.md").rulesStamp ==
      stamp([RULES_TEXT[0], "", RULES_TEXT[2], RULES_TEXT[3], RULES_TEXT[4]])  # missing is empty


  test "one change to any rules document goes stale in every project":
    let
      changed = goodTree().replaced("CONTRIBUTOR.md", RULES_TEXT[2] & "More.\n")
      stale = changed.auditTree.filterIt("stale" in it.message)
    check stale.mapIt(it.path).sorted ==
      @[ALPHA_DIRECTORY & "/PROVENANCE.md", AUDIT_DIRECTORY & "/PROVENANCE.md"]  # every project
    let curator_only = changed.replaced("CURATOR.md", "# Curator\n\nChanged.\n")
    check curator_only.auditTree.len == stale.len  # CURATOR.md is not stamped


  test "top-level glossary shape reaches umbrella":
    let termless =
      goodTree().replaced("GLOSSARY.md", "# delegations\n\nWords.\n\n## Standards\n\n## Language\n")
    check termless.auditTree.len == 0  # zero terms pass, since terms wait on agreement
    let undefined = goodTree().replaced(
      "GLOSSARY.md",
      "# delegations\n\nWords.\n\n## Standards\n\n## Language\n\n**Stamp**:\n",
    )
    check undefined.auditTree.mapIt(it.path) == @["GLOSSARY.md"]  # shape checked at root
    check "lacks definition" in undefined.auditTree[0].message  # same check projects get


  test "idioms of any Nim code reach scripts and packages, and module's rules stay on modules":
    # Case held: `auditTree` ran `checkIdioms` on `Kind.Nim` alone (`audit.nim`), so `.nims` and
    #   `.nimble` took none of it (#557); domain is each kind of Nim, each reporting idioms that
    #   read any Nim code, and `strictFuncs`, which STYLE.md §2 asks of module, reported nowhere
    #   else.
    let
      breach = "{.push inline.}\nproc f() = discard\n{.pop.}\nproc g(): int =\n  return result\n"
      found = @[
        "`{.push.}` stands only over foreign bindings, which `{.pop.}` closes (STYLE.md §2); " &
          "got `{.push inline.}`.",
        "Bare `return` exits early with `result`, and routine ends on value itself (STYLE.md " &
          "§5); got `return result`.",
      ]
      nimble = ALPHA_DIRECTORY & "/alpha.nimble"
    for (tree, path) in [
      (goodTree().with(entry(ALPHA_DIRECTORY & "/src/a.nim", STRICT_FUNCS & "\n\n" & breach)),
        ALPHA_DIRECTORY & "/src/a.nim"),
      (goodTree().with(entry(ALPHA_DIRECTORY & "/config.nims", breach)),
        ALPHA_DIRECTORY & "/config.nims"),
      (goodTree().replaced(nimble, TEXT_NIMBLE & breach), nimble),
    ]:
      check tree.auditTree.filterIt(it.path == path).mapIt(it.message).sorted == found.sorted
    let script = goodTree().with(entry(ALPHA_DIRECTORY & "/tests/helpers.nims", "echo x\n"))
    check script.auditTree.mapIt(it.message) == @[
      "Test leaves no debug output; label report, or print under failing condition (VIII.5); " &
        "got `echo x`.",
    ]  # test rules of any Nim code read script under `tests/` too


  test "acronym check reads glossary of root and of project, in each kind of Nim":
    # Domain: acronym root glossary lists, acronym project glossary lists, and acronym neither
    #   lists, in module, script and package. V.9 is audit's, since knoller reads no glossary.
    let
      heading = "## Standards\n"
      root = GLOSSARY_TEXT.replace(heading, heading & "\n- **Acronyms**, Architect: `JSON`.\n")
      project = GLOSSARY_TEXT.replace(heading, heading & "\n- **Graphics**, Khronos: `GL`.\n")
      source = "func toJSON*() = discard\nfunc toGL*() = discard\nfunc toXML*() = discard\n"
      module = ALPHA_DIRECTORY & "/src/a.nim"
      script = ALPHA_DIRECTORY & "/config.nims"
      nimble = ALPHA_DIRECTORY & "/alpha.nimble"
      listed = goodTree().replaced("GLOSSARY.md", root).replaced(
        ALPHA_DIRECTORY & "/GLOSSARY.md",
        project,
      )
    for (tree, path) in [
      (listed.with(entry(module, STRICT_FUNCS & "\n\n" & source)), module),
      (listed.with(entry(script, source)), script),
      (listed.replaced(nimble, TEXT_NIMBLE & source), nimble),
    ]:
      check tree.auditTree.mapIt((it.path, it.message)) ==
          @[(path, "Acronym stays only where glossary lists it (V.9); got `XML` in `toXML`.")]
    let unlisted = goodTree().with(entry(module, STRICT_FUNCS & "\n\n" & source))
    check unlisted.auditTree.mapIt(it.message).filterIt("Acronym" in it).len == 3  # none listed


  test "form and prose findings reach umbrella":
    let messy =
      goodTree() & @[entry(ALPHA_DIRECTORY & "/src/x.nim", "# the trap \n\n" & STRICT_FUNCS & "\n")]
    check messy.auditTree.mapIt(it.message) == @[
      "Line ends with whitespace (VIII.5).",
      "Comment holds article (VI.5); got `the`.",
    ]  # both checks ran
