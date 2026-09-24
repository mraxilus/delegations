## Replicate scope rules of `scope.nim` header and CONTRIBUTOR.md boundaries.

import std/[sequtils, strutils, unittest]
import ../../src/[domains, scope]


const OUTSIDE = @[
  "README.md", "curator/audit/src/audit.nim", "curator/probe/README.md",
  "contributor/ronri/beta/x.nim", "contributor/bangu/other/x.nim",
]
  ## Paths outside `contributor/<domain>/alpha/` for every domain.


suite "Scope":
  test "main passes every path":
    check checkScope(MAIN, OUTSIDE).len == 0  # main is merge target

  test "contributor branch confined to project prefix":
    for d in DOMAINS:  # 5 domains, exhaustive
      let prefix = "contributor/" & d.folder & "/alpha/"
      let inside = @[prefix & "x.nim", prefix & "tests/t.nim"]
      check checkScope("contributor/" & d.folder & "/alpha/work", inside).len == 0  # inside
      let found = checkScope("contributor/" & d.folder & "/alpha/work", inside & OUTSIDE)
      check found.mapIt(it.path) == OUTSIDE  # each outside path named
      check found.allIt(it.message == "Path outside branch scope `" & prefix & "`.")  # prefix
    check checkScope("contributor/ronri/alpha/work", ["contributor/ronri/alpha_2/x.nim"]).len ==
      1  # prefix is whole folder

  test "curator project branch confined to its folder":
    let paths = [
      "curator/audit/src/x.nim", "README.md", "curator/probe/README.md",
      "contributor/ronri/alpha/x.nim", "curator/audit_2/x.nim",
    ]
    let found = checkScope("curator/audit/work", paths)
    check found.mapIt(it.path) == paths[1 .. ^1].toSeq  # everything but its own folder
    check found.allIt(it.message == "Path outside branch scope `curator/audit/`.")  # prefix

  test "branch outside grammar is one finding naming branch":
    for branch in ["claude/setup", "ronri/alpha/work"]:  # harness name, old form
      let found = checkScope(branch, ["README.md"])
      check found.len == 1 and found[0].path.len == 0  # branch-level
      check found[0].message.endsWith("got `" & branch & "`.")  # IV.4 echo value

  test "curator writes only records inside contributor project":
    # Rules propagation reaches every project; it does not reach their code.
    let records = [
      CONTRIBUTOR & "/ronri/alpha/PROVENANCE.md",
      CONTRIBUTOR & "/ronri/alpha/GLOSSARY.md",
      CONTRIBUTOR & "/ronri/alpha/README.md",
    ]
    check checkScope("curator/rules", records).len == 0  # stamp, terms, invalidated prose

    # Indexes above project are curator's outright, per repository map and duty 6, which
    #   has curator write domain README whenever domain is added.
    check checkScope("curator/rules", [CONTRIBUTOR & "/README.md"]).len == 0
    check checkScope("curator/rules", [CONTRIBUTOR & "/ronri/README.md"]).len == 0
    check checkScope("curator/rules", ["CONTRIBUTOR.md", "koch.nim"]).len == 0  # own files
    check checkScope("curator/rules", [CURATOR & "/audit/src/scope.nim"]).len == 0  # own root

    # Contributor's code stays contributor's, even for curator propagating rule.
    for path in [
      CONTRIBUTOR & "/ronri/alpha/src/alpha.nim",
      CONTRIBUTOR & "/ronri/alpha/tests/tall.nim",
      CONTRIBUTOR & "/ronri/alpha/alpha.nimble",
      CONTRIBUTOR & "/ronri/alpha/pages/index.html",
    ]:
      let found = checkScope("curator/rules", [path])
      check found.len == 1
      check found[0].path == path

    # Project branches are unaffected: their prefix already decides.
    check checkScope(
      "contributor/ronri/alpha/work", [CONTRIBUTOR & "/ronri/alpha/src/alpha.nim"]
    ).len == 0

  test "content-preserving move is exempt for curator root alone":
    let alpha = CONTRIBUTOR & "/ronri/alpha/src/alpha.nim"
    let beta = CONTRIBUTOR & "/ronri/alpha/src/beta.nim"
    check checkScope("curator/rules", [alpha]).len == 1  # edit to contributor code is finding
    check checkScope("curator/rules", [alpha], [alpha]).len == 0  # same path moved is not
    check checkScope("curator/rules", [alpha, beta], [alpha]).mapIt(it.path) ==
      @[beta]  # exemption covers moved path alone
    # Move never widens project branch: its prefix decides before exemption is read.
    check checkScope("contributor/ronri/beta/work", [alpha], [alpha]).len == 1  # other project
    check checkScope("curator/audit/work", [alpha], [alpha]).len == 1  # curator project
