## Replicate umbrella: whole static audit over fixture tree, and stamp derivation.

{.experimental: "strictFuncs".}

import std/[algorithm, os, sequtils, strutils, unittest]
import ../../../knoller/src/knoller
import ../../src/[audit, domains, provenance]
import ./fixtures



suite "Audit":
  test "good tree is clean under every static check":
    check treeGood().auditTree.len == 0  # layout, form, prose, provenance, glossary


  test "rules stamp derives from tree contents in RULES order":
    check treeGood().stampRules == stamp(TEXT_RULES)  # same digest as fixture
    check treeGood().without("STYLE.md").stampRules ==
      stamp([TEXT_RULES[0], "", TEXT_RULES[2], TEXT_RULES[3], TEXT_RULES[4]])  # missing is empty


  test "one change to any rules document goes stale in every project":
    let
      changed = treeGood().replaced("CONTRIBUTOR.md", TEXT_RULES[2] & "More.\n")
      stale = changed.auditTree.filterIt("stale" in it.message)
    check stale.mapIt(it.path).sorted ==
      @[DIRECTORY_ALPHA & "/PROVENANCE.md", DIRECTORY_AUDIT & "/PROVENANCE.md"]  # every project
    let curator_only = changed.replaced("CURATOR.md", "# Curator\n\nChanged.\n")
    check curator_only.auditTree.len == stale.len  # CURATOR.md is not stamped


  test "top-level glossary shape reaches umbrella":
    let termless =
      treeGood().replaced("GLOSSARY.md", "# delegations\n\nWords.\n\n## Standards\n\n## Language\n")
    check termless.auditTree.len == 0  # zero terms pass, since terms wait on agreement
    let undefined = treeGood().replaced(
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
      nimble = DIRECTORY_ALPHA & "/alpha.nimble"
    for (tree, path) in [
      (treeGood().with(entry(DIRECTORY_ALPHA & "/src/a.nim", STRICT_FUNCS & "\n\n" & breach)),
        DIRECTORY_ALPHA & "/src/a.nim"),
      (treeGood().with(entry(DIRECTORY_ALPHA & "/config.nims", breach)),
        DIRECTORY_ALPHA & "/config.nims"),
      (treeGood().replaced(nimble, TEXT_NIMBLE & breach), nimble),
    ]:
      check tree.auditTree.filterIt(it.path == path).mapIt(it.message).sorted == found.sorted
    let script = treeGood().with(entry(DIRECTORY_ALPHA & "/tests/helpers.nims", "echo x\n"))
    check script.auditTree.mapIt(it.message) == @[
      "Test leaves no debug output; label report, or print under failing condition (VIII.5); " &
        "got `echo x`.",
    ]  # test rules of any Nim code read script under `tests/` too


  test "acronym check reads glossary of root and of project, in each kind of Nim":
    # Domain: acronym root glossary lists, acronym project glossary lists, and acronym neither
    #   lists, in module, script and package. V.9 is audit's, since knoller reads no glossary.
    let
      heading = "## Standards\n"
      root = TEXT_GLOSSARY.replace(heading, heading & "\n- **Acronyms**, Architect: `JSON`.\n")
      project = TEXT_GLOSSARY.replace(heading, heading & "\n- **Graphics**, Khronos: `GL`.\n")
      source = "func toJSON*() = discard\nfunc toGL*() = discard\nfunc toXML*() = discard\n"
      module = DIRECTORY_ALPHA & "/src/a.nim"
      script = DIRECTORY_ALPHA & "/config.nims"
      nimble = DIRECTORY_ALPHA & "/alpha.nimble"
      listed = treeGood().replaced("GLOSSARY.md", root).replaced(
        DIRECTORY_ALPHA & "/GLOSSARY.md",
        project,
      )
    for (tree, path) in [
      (listed.with(entry(module, STRICT_FUNCS & "\n\n" & source)), module),
      (listed.with(entry(script, source)), script),
      (listed.replaced(nimble, TEXT_NIMBLE & source), nimble),
    ]:
      check tree.auditTree.mapIt((it.path, it.message)) ==
          @[(path, "Acronym stays only where glossary lists it (V.9); got `XML` in `toXML`.")]
    let unlisted = treeGood().with(entry(module, STRICT_FUNCS & "\n\n" & source))
    check unlisted.auditTree.mapIt(it.message).filterIt("Acronym" in it).len == 3  # none listed


  test "form and prose findings reach umbrella":
    let messy =
      treeGood() & @[entry(DIRECTORY_ALPHA & "/src/x.nim", "# the trap \n\n" & STRICT_FUNCS & "\n")]
    check messy.auditTree.mapIt(it.message) == @[
      "Line ends with whitespace (VIII.5).",
      "Comment holds article (VI.5); got `the`.",
    ]  # both checks ran


  test "Pruned row reads history of record across move":
    # Case held: `findingsPruned` read `git log -- <path>` without `--follow`, so move of
    #   `rga_visualiser` to `pga_visualiser` lost commits of old path, and true row naming
    #   `70ced35e` was finding (#631). Domain: commit before move, move itself, edit after it,
    #   and commit that never touched record.
    func pruned(named: string): string =
      textProvenance("y").replace("| Review |", "| Pruned | " & named[0..7] & " |\n| Review |")

    let
      root = repoTemp()
      after = CONTRIBUTOR & "/ronri/beta/PROVENANCE.md"
    defer: removeDir(root)
    root.writeInto(DIRECTORY_ALPHA & "/PROVENANCE.md", textProvenance("x"))
    discard root.git("add -A")
    discard root.git("commit -q -m 'docs(alpha): open record'")
    let opened = root.git("rev-parse HEAD").strip
    root.writeInto("README.md", "# r\n")
    discard root.git("add -A")
    discard root.git("commit -q -m 'docs(curator): add readme'")
    let elsewhere = root.git("rev-parse HEAD").strip
    discard root.git("mv " & DIRECTORY_ALPHA & " " & CONTRIBUTOR & "/ronri/beta")
    discard root.git("commit -q -m 'chore(curator): move alpha to beta'")
    let moved = root.git("rev-parse HEAD").strip
    root.writeInto(after, textProvenance("y"))
    discard root.git("commit -q -am 'docs(beta): change stamp'")
    let edited = root.git("rev-parse HEAD").strip
    for named in [opened, moved, edited]:
      check findingsPruned(root, @[entry(after, pruned(named))]).len == 0  # record touched
    check findingsPruned(root, @[entry(after, pruned(elsewhere))]).mapIt(it.message) == @[
      "`Pruned` must name commit that touched this record; got `" & elsewhere[0..7] & "`.",
    ]  # commit beside record still finding
