## Replicate version rule of `schemas.nim` header, i.e. each edit schema may make, and none other.
##   Shipped schema is scene file of pga_visualiser, written as protobuf schema; each edit is one
##     version step such history makes, or one fault such step could make. Each edit that breaks
##     is held to message of its own rule, so edit failing for other reason never passes as it.
##   Cost: test runs `buf`, so cold store fetches it, about 33 MB, and needs network.

{.experimental: "strictFuncs".}

import std/[options, os, sequtils, strutils, unittest]
import ../../src/[bufbuild, findings, schemas]
import ./fixtures


const
  SHIPPED = """
syntax = "proto3";

package pga_visualiser.scene;

enum Ink {
  BACKDROP = 0;
  OUTLINE = 6;
  ALGEBRA = 7;
  INVALID = 8;
  ROSE = 9;
  COPPER = 10;
}

message Object {
  Ink ink = 1;
  bool is_hidden = 2;
  string label = 3;
  optional double radius = 4;
}
"""
    ## Schema base shipped: one enum with gaps in its numbers, one message.
  FOLDER = "formats"  ## Folder holding schema in repository.
  NAME = "scene.proto"  ## Name of schema in its folder.


proc held(changed: string): seq[Finding] =
  ## Hold `changed` to `SHIPPED` through `buf`, as one schema of `FOLDER`.
  let binary = bufbuildIn(rootBufbuild(getEnv(KEY_BUFBUILD)))
  doAssert binary.isSome, "buf could not be fetched"
  breakingFindings(binary.get, FOLDER, [(NAME, SHIPPED)], [(NAME, changed)])



suite "Schemas":
  test "changed schemas and their folders are read, and nothing else is":
    let paths = ["a/scene.proto", "a/scene.nim", "b/tour.txtpb", "c.proto", "a/wrap.proto"]
    check schemasChanged(paths) == @["a/scene.proto", "c.proto", "a/wrap.proto"]
    check foldersChanged(paths) == @["a", ""]  # once each, root as empty folder


  test "field or value added under new number, or deleted with both reserved, keeps version":
    # Version 4 of scene file added radius, which older file lacks and reads as absent.
    check held(SHIPPED.replace("  optional double radius = 4;\n",
      "  optional double radius = 4;\n  bool shines = 5;\n")).len == 0  # field added
    check held(SHIPPED.replace("  COPPER = 10;\n", "  COPPER = 10;\n  JADE = 12;\n")).len == 0
    check held(SHIPPED.replace("  string label = 3;\n",
      "  reserved 3;\n  reserved \"label\";\n")).len == 0  # field deleted, number and name kept
    check held(SHIPPED.replace("  ALGEBRA = 7;\n",
      "  reserved 7;\n  reserved \"ALGEBRA\";\n")).len == 0  # value deleted, both kept


  test "renumbered value, or deleted, retyped or renamed field, breaks it, naming its rule":
    # Case held: version 6 of scene file dropped `Algebra` and moved every later hue one down,
    #   so older file read wrong colours, and only code written by hand caught it (#755).
    #   Domain is each edit category `WIRE_JSON` of `buf breaking` refuses.
    let edits = [
      (SHIPPED.replace("ALGEBRA = 7;\n  INVALID = 8;\n  ROSE = 9;\n  COPPER = 10;",
        "INVALID = 7;\n  ROSE = 8;\n  COPPER = 9;"),
        "Enum value \"7\" on enum \"Ink\" changed name from \"ALGEBRA\" to \"INVALID\""),
      (SHIPPED.replace("  ALGEBRA = 7;\n", ""),
        "enum value \"7\" on enum \"Ink\" was deleted without reserving the number \"7\""),
      (SHIPPED.replace("  string label = 3;\n", ""),
        "field \"3\" with name \"label\" on message \"Object\" was deleted without reserving " &
          "the number \"3\""),
      (SHIPPED.replace("optional double radius", "optional float radius"),
        "Field \"4\" with name \"radius\" on message \"Object\" changed type from \"double\" " &
          "to \"float\""),
      (SHIPPED.replace("bool is_hidden = 2;", "bool hidden = 2;"),
        "Field \"2\" on message \"Object\" changed name from \"is_hidden\" to \"hidden\""),
    ]  # renumbered, value deleted, field deleted, retyped, renamed
    for (edit, rule) in edits:
      let found = held(edit)
      check found.anyIt(rule in it.message)  # `buf` names rule edit breaks
      check found.allIt(it.path == FOLDER / NAME and it.line > 0)  # schema of branch, at line
      check found.allIt(it.message.startsWith("Schema change breaks version base shipped"))


  test "schema that does not compile is finding, never pass":
    let found = held(SHIPPED.replace("string label = 3;", "string label = 3"))
    check found.len > 0 and found.allIt(it.message.startsWith("Schema does not compile"))
    check found.allIt(it.path == FOLDER / NAME and it.line > 0)


  test "finding names schema in its folder, and line only on side of branch":
    let output = "{\"path\":\"after/scene.proto\",\"start_line\":13,\"type\":\"FIELD_SAME_NAME\"," &
      "\"message\":\"m\"}\n" &
      "{\"path\":\"before/scene.proto\",\"start_line\":4,\"type\":\"COMPILE\"," &
      "\"message\":\"c\"}\n" &
      "Failure: not one object\n"
    let found = findingsBreaking(output, FOLDER)
    check found.mapIt((it.path, it.line)) ==
      @[(FOLDER / NAME, 13), (FOLDER / NAME, 0), (FOLDER, 0)]  # branch, shipped, unread line
    check "`m`" in found[0].message and "as base shipped it" in found[1].message
    check "what is no finding" in found[2].message


  test "check reads base at its tip and branch at HEAD, folder by folder":
    let root = repoTemp()
    defer: removeDir(root)
    root.writeInto(FOLDER / NAME, SHIPPED)
    root.writeInto("top.proto", "syntax = \"proto3\";\n")
    discard root.git("add -A")
    discard root.git("commit -q -m 'feat(alpha): add scene format'")
    check schemasAt(root, "main", "").mapIt(it[0]) == @["top.proto"]  # root read as `main:`
    discard root.git("checkout -q -b work")
    root.writeInto(FOLDER / NAME, SHIPPED.replace("  string label = 3;\n", ""))
    root.writeInto(FOLDER / "fresh" / "tour.proto",
      "syntax = \"proto3\";\nmessage Tour {}\n")
    discard root.git("add -A")
    discard root.git("commit -q -m 'feat(alpha): drop label, add tour format'")
    check schemasAt(root, "HEAD", FOLDER).mapIt(it[0]) == @[NAME]  # subfolder is never read
    check schemasAt(root, "main", FOLDER / "fresh").len == 0  # folder new on branch
    let found = checkSchemas(root, "main")
    check found.len > 0 and found.allIt(it.path == FOLDER / NAME)  # new folder passes
    # Base gains field after branch forked: branch must still read it, so tip is held.
    discard root.git("checkout -q main")
    root.writeInto(FOLDER / NAME, SHIPPED.replace("  optional double radius = 4;\n",
      "  optional double radius = 4;\n  bool shines = 5;\n"))
    discard root.git("commit -q -a -m 'feat(alpha): add shines'")
    discard root.git("checkout -q work")
    check checkSchemas(root, "main").anyIt("name \"shines\"" in it.message)
