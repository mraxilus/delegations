## Replicate Article VIII.6 and provenance guide: header table and rules stamp.

import std/[sequtils, sets, strutils, tables, unittest]
import ../../src/[provenance]
import ./fixtures


suite "Article VIII":
  test "VIII.6 stamp is deterministic, sensitive and CR-blind":
    check stamp(["a", "b"]) == stamp(["a", "b"])  # same input, same stamp
    check stamp(["a", "b"]).len == 16 and stamp(["a", "b"]).allCharsInSet(HexDigits)  # 16 hex
    check stamp(["a", "b"]) != stamp(["a", "c"])  # one byte changes stamp
    check stamp(["a", "b"]) != stamp(["b", "a"])  # order matters
    check stamp(["ab", ""]) != stamp(["a", "b"])  # boundary matters
    check stamp(["x\r\ny"]) == stamp(["x\ny"])  # CRLF checkout stamps same
    check stamp(["x\r\ny"]).allCharsInSet({'0'..'9', 'a'..'f'})  # lowercase

  test "VIII.6 header fields parse from first table":
    let fields = provenanceText("deadbeefdeadbeef").headerFields
    check fields.len == 6 and fields["Rules"] == "deadbeefdeadbeef"  # six rows read
    check "# x\n\n| Other | Table |\n|---|---|\n| a | b |\n".headerFields.len == 0  # header row

  test "VIII.6 missing field, bad date, stale stamp":
    let good = provenanceText("deadbeefdeadbeef")
    check checkProvenance("p", good, "deadbeefdeadbeef").len == 0  # complete header passes
    check checkProvenance("p", "# x\n\nprose\n", "s").mapIt(it.message) ==
      @["Header table `| Field | Value |` missing or empty."]  # no table
    let unreviewed = good.replace("| Review | **Unreviewed.** |\n", "")
    check checkProvenance("p", unreviewed, "deadbeefdeadbeef").mapIt(it.message) ==
      @["Header lacks field; got `Review`."]  # review row required
    check checkProvenance("p", good.replace("2026-01-01", "1 Jan 2026"), "deadbeefdeadbeef")
      .mapIt(it.message) == @["Date must be `YYYY-MM-DD`; got `1 Jan 2026`."]  # ISO date
    let stale = checkProvenance("p", good, "0000000000000000")
    check stale.len == 1 and stale[0].message.endsWith("got `deadbeefdeadbeef`.")  # stale
    check "`0000000000000000`" in stale[0].message  # expected stamp named

  test "VIII.6 Rules row is rewritten in place, padding and neighbours kept":
    let old = provenanceText("deadbeefdeadbeef")
    let written = old.withRulesRow("0123456789abcdef")
    check written.headerFields["Rules"] == "0123456789abcdef"  # row carries new stamp
    check written.replace("0123456789abcdef", "deadbeefdeadbeef") == old  # nothing else moved
    check written.withRulesRow("0123456789abcdef") == written  # idempotent
    let padded = "| Field  | Value |\n|--------|-------|\n| Rules  | deadbeefdeadbeef |\n"
    check padded.withRulesRow("0123456789abcdef") ==
      "| Field  | Value |\n|--------|-------|\n| Rules  | 0123456789abcdef |\n"  # padding kept
    check "# x\n\nprose\n".withRulesRow("0123456789abcdef") == "# x\n\nprose\n"  # no row
    check "| Rules | a |\n| Rules | b |\n".withRulesRow("c") ==
      "| Rules | c |\n| Rules | b |\n"  # first row only, as headerFields reads first

  test "VIII.6 ISO date grammar":
    check "2026-09-05".isIsoDate and not "2026-9-5".isIsoDate  # zero-padded
    check not "2026/09/05".isIsoDate and not "".isIsoDate  # separators

  test "VIII.6 claim citing test is checked to cite real one":
    let present = ["p/tests/tfoo.nim", "p/tests/tbar.nim"].toHashSet
    check citations("Verified by `tfoo.nim`: two rows pass.\n") == @["tfoo.nim"]
    check citations("verified by `tfoo.nim` and by `tbar.nim`") == @["tfoo.nim"]  # first only
    check citations("Verified by `atlas changed` exiting zero.").len == 0  # command, not file
    check citations("Nothing cited here.").len == 0

    check checkCitations("p/PROVENANCE.md", "Verified by `tfoo.nim`.", "p/tests/", present).len == 0
    let found = checkCitations(
      "p/PROVENANCE.md", "Verified by `tgone.nim`.", "p/tests/", present
    )
    check found.len == 1
    check found[0].path == "p/PROVENANCE.md"
    check found[0].message.endsWith("got `tgone.nim`.")  # Article IV.4 echoes value

    # Citation naming another project's test does not resolve here.
    check checkCitations(
      "p/PROVENANCE.md", "Verified by `tlaws.nim`.", "p/tests/",
      ["q/tests/tlaws.nim"].toHashSet
    ).len == 1
