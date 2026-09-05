discard """
action: run
cmd: "nim c --hints:off -d:testing -d:nimUnittestAbortOnError:on $options $file"
batchable: true
joinable: true
"""
## Replicate umbrella: whole static audit over fixture tree, and stamp derivation.

import std/[sequtils, strutils, unittest]
import ../src/[audit, layout, provenance]
import ./fixtures


suite "Audit":
  test "good tree is clean under every static check":
    check goodTree().auditTree.len == 0  # layout, form, prose, provenance, glossary

  test "rules stamp derives from tree contents in RULES order":
    check goodTree().rulesStamp == stamp(RULES_TEXT)  # same digest as fixture
    check goodTree().without("STYLE.md").rulesStamp ==
      stamp([RULES_TEXT[0], "", RULES_TEXT[2]])  # missing document digests empty

  test "one change to any rules document goes stale in every project":
    let changed = goodTree().replaced("CONTRIBUTOR.md", RULES_TEXT[2] & "More.\n")
    let stale = changed.auditTree.filterIt("stale" in it.message)
    check stale.mapIt(it.path) == @["curator/PROVENANCE.md", "ronri/alpha/PROVENANCE.md"]  # all
    let curator_only = changed.replaced("CURATOR.md", "# Curator\n\nChanged.\n")
    check curator_only.auditTree.len == stale.len  # CURATOR.md is not stamped

  test "form and prose findings reach umbrella":
    let messy = goodTree() & @[entry("ronri/alpha/src/x.nim", "# the trap \n")]
    check messy.auditTree.mapIt(it.message) ==
      @["Line ends with whitespace.", "Comment holds article; got `the`."]  # both checks ran
