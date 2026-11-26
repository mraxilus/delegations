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


proc held(changed: string, shipped = SHIPPED): seq[Finding] =
  ## Hold `changed` to `shipped` through `buf`, as one schema of `FOLDER`.
  let binary = bufbuildIn(rootBufbuild(getEnv(KEY_BUFBUILD)))
  doAssert binary.isSome, "buf could not be fetched"
  breakingFindings(binary.get, FOLDER, [(NAME, shipped)], [(NAME, changed)])



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


  test "renumbered value, or deleted, retyped or renamed field, or changed optional, breaks it":
    # Case held: version 6 of scene file dropped `Algebra` and moved every later hue one down,
    #   so older file read wrong colours, and only code written by hand caught it (#755).
    #   Domain is each edit category `WIRE_JSON` of `buf breaking` refuses, and each change of
    #   `optional`, which bytes hide but absent field reads differently under.
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
      (SHIPPED.replace("optional double radius", "double radius"),
        "Field \"4\" with name \"radius\" on message \"Object\" changed cardinality from " &
          "\"optional with explicit presence\" to \"optional with implicit presence\""),
      (SHIPPED.replace("bool is_hidden", "optional bool is_hidden"),
        "Field \"2\" with name \"is_hidden\" on message \"Object\" changed cardinality from " &
          "\"optional with implicit presence\" to \"optional with explicit presence\""),
    ]  # renumbered, value deleted, field deleted, retyped, renamed, `optional` dropped or added
    for (edit, rule) in edits:
      let found = held(edit)
      check found.anyIt(rule in it.brief)  # `buf` names rule edit breaks
      check found.allIt(it.path == FOLDER / NAME and it.line > 0)  # schema of branch, at line
      check found.allIt(it.brief.startsWith("schema change breaks version base shipped"))


  test "schema that does not compile is finding, never pass":
    let found = held(SHIPPED.replace("string label = 3;", "string label = 3"))
    check found.len > 0 and found.allIt(it.brief.startsWith("schema does not compile"))
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
    check "`m`" in found[0].brief and "as base shipped it" in found[1].brief
    check "what is no finding" in found[2].brief


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
    check checkSchemas(root, "main").anyIt("name \"shines\"" in it.brief)


  test "new package of folder passes where each field holds, and break under it still fails":
    # Case held: rictadni moves package `lojban_tagger` to `rictadni` (#981); `buf` pairs
    #   messages by full name, so shipped side reads under new package before compare.
    let moved = SHIPPED.replace("package pga_visualiser.scene;", "package pga_visualiser.scenes;")
    check held(moved).len == 0  # package alone moves
    let retyped = held(moved.replace("optional double radius", "optional float radius"))
    check retyped.anyIt("changed type from \"double\" to \"float\"" in it.brief)
    let timed = moved.replace("package pga_visualiser.scenes;\n",
      "package pga_visualiser.scenes;\n\nimport \"google/protobuf/timestamp.proto\";\n").replace(
      "  optional double radius = 4;\n",
      "  optional double radius = 4;\n  google.protobuf.Timestamp seen = 5;\n")
    check held(timed).len == 0  # package of file it imports is no package of folder


  test "schema renamed under new package is held, so moved file hides no break":
    let binary = bufbuildIn(rootBufbuild(getEnv(KEY_BUFBUILD)))
    doAssert binary.isSome, "buf could not be fetched"
    let
      moved = SHIPPED.replace("package pga_visualiser.scene;", "package pga_visualiser.scenes;")
      found = breakingFindings(binary.get, FOLDER, [(NAME, SHIPPED)],
        [("scenes.proto", moved.replace("  string label = 3;\n", ""))])
    check found.anyIt("\"label\" on message \"Object\" was deleted" in it.brief)
    check breakingFindings(binary.get, FOLDER, [(NAME, SHIPPED)], [("scenes.proto", moved)])
      .len == 0


  test "qualified name of old package reads under new one, from root or not":
    let moved = SHIPPED.replace("package pga_visualiser.scene;", "package pga_visualiser.scenes;")
    for name in [".pga_visualiser.scene.Ink", "pga_visualiser.scene.Ink"]:
      let qualified = SHIPPED.replace("  Ink ink = 1;", "  " & name & " ink = 1;")
      check qualified != SHIPPED
      check held(moved, qualified).len == 0


  test "new package beside `Any`, `service` or `extend` is refused, since full name reaches data":
    let
      typed = SHIPPED.replace("package pga_visualiser.scene;\n",
        "package pga_visualiser.scene;\n\nimport \"google/protobuf/any.proto\";\n")
      any = typed.replace("  optional double radius = 4;\n",
        "  optional double radius = 4;\n  google.protobuf.Any extra = 5;\n")
      deep = typed.replace("  optional double radius = 4;\n",
        "  optional double radius = 4;\n\n  message Part {\n    google.protobuf.Any extra = 1;\n" &
          "  }\n")  # `Any` in message nested in message
      served = SHIPPED & "\nservice Gallery {\n  rpc Show(Object) returns (Object);\n}\n"
      described = SHIPPED.replace("package pga_visualiser.scene;\n",
        "package pga_visualiser.scene;\n\nimport \"google/protobuf/descriptor.proto\";\n")
      extended = described & "\nextend google.protobuf.FieldOptions {\n  string unit = 50000;\n}\n"
      nested = described.replace("  optional double radius = 4;\n",
        "  optional double radius = 4;\n\n  extend google.protobuf.FieldOptions {\n" &
          "    string unit = 50000;\n  }\n")  # `extend` inside message
    for shipped in [any, deep, served, extended, nested]:
      check held(shipped, shipped).len == 0  # each compiles, and holds as shipped
      let found = held(shipped.replace("package pga_visualiser.scene;",
        "package pga_visualiser.scenes;"), shipped)
      check found.len == 1
      check found.allIt("beside `Any`, `service` or `extend`" in it.brief)


  test "folder whose packages split or merge, so no one package of base maps to one, is refused":
    let
      binary = bufbuildIn(rootBufbuild(getEnv(KEY_BUFBUILD))).get
      tour = "syntax = \"proto3\";\n\npackage two;\n\nmessage Tour {}\n"
      one = SHIPPED.replace("package pga_visualiser.scene;", "package one;")
      split = breakingFindings(binary, FOLDER, [(NAME, SHIPPED)],
        [(NAME, one), ("tour.proto", tour)])
      merged = breakingFindings(binary, FOLDER, [(NAME, SHIPPED), ("tour.proto", tour)],
        [(NAME, one), ("tour.proto", tour.replace("package two;", "package one;"))])
    for found in [split, merged]:
      check found.len == 1
      check found.allIt("no one package of base maps to one of branch" in it.brief)


  test "package in each form that `buf` reads moves, so renamed schema holds each field":
    # Cases review found (#996): read of text missed each form, and `buf` pairs by full name.
    let
      binary = bufbuildIn(rootBufbuild(getEnv(KEY_BUFBUILD))).get
      statement = "package pga_visualiser.scene;"
      moved = SHIPPED.replace(statement, "package scenes;")
      root = SHIPPED.replace(statement & "\n", "")
      retype = ("optional double radius", "optional float radius")
    for (shipped, branch) in [
      (SHIPPED.replace(statement, statement & "  // scene format"), moved),
      (SHIPPED.replace(statement, "/* scene format */ " & statement), moved),
      (SHIPPED.replace(statement, "package  pga_visualiser.scene ;"), moved),
      (SHIPPED.replace("\"proto3\";\n\n" & statement, "\"proto3\"; " & statement), moved),
      (root, SHIPPED),  # root package, then one
      (SHIPPED, root),  # one package, then root
    ]:
      check breakingFindings(binary, FOLDER, [(NAME, shipped)], [("other.proto", branch)]).len == 0
      let found = breakingFindings(binary, FOLDER, [(NAME, shipped)],
        [("other.proto", branch.replace(retype[0], retype[1]))])
      check found.anyIt("changed type from \"double\" to \"float\"" in it.brief)


  test "package nested under moved one, or one that ends alike, keeps its name and each field":
    # Case review found (#996): read of text moved `a.b` with `a`, so renamed `a.b` hid break.
    let
      binary = bufbuildIn(rootBufbuild(getEnv(KEY_BUFBUILD))).get
      tour = "syntax = \"proto3\";\n\npackage pga_visualiser.scene.tour;\n\nmessage Tour {\n" &
        "  string s = 1;\n}\n"
      far = "syntax = \"proto3\";\n\npackage far.pga_visualiser.scene;\n\nmessage Ink {\n" &
        "  string s = 1;\n}\n"
      ending = SHIPPED.replace("package pga_visualiser.scene;\n",
        "package pga_visualiser.scene;\n\nimport \"far.proto\";\n").replace(
        "  optional double radius = 4;\n",
        "  optional double radius = 4;\n  far.pga_visualiser.scene.Ink far = 5;\n")
      shipped = [(NAME, ending), ("tour.proto", tour), ("far.proto", far)]
      moved = ending.replace("package pga_visualiser.scene;", "package scenes;")
    check breakingFindings(binary, FOLDER, shipped,
      [(NAME, moved), ("tour.proto", tour), ("far.proto", far)]).len == 0
    let found = breakingFindings(binary, FOLDER, shipped,
      [(NAME, moved), ("trip.proto", tour.replace("string s", "int32 s")), ("far.proto", far)])
    check found.anyIt("changed type from \"string\" to \"int32\"" in it.brief)


  test "name of type in each form of text moves, and `Any` in comment names none":
    let mapped = SHIPPED.replace("  optional double radius = 4;\n",
      "  optional double radius = 4;\n  map<string,pga_visualiser.scene.Object> parts = 5;\n")
    for shipped in [
      SHIPPED & "\n// No google.protobuf.Any here.\n",
      mapped,
      mapped.replace("string,pga", "string,/* part */pga"),
    ]:
      check held(shipped.replace("pga_visualiser.scene", "scenes"), shipped).len == 0
