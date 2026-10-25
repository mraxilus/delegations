## Replicate version rule of `schemas.nim` header, i.e. each edit schema may make, and none other.
##   Shipped schema is version 7 of scene file of pga_visualiser, written as schema; each edit
##     is one version step of its history, or one fault such step could make.
##   Cost: test runs patched `flatc`, so cold store builds it, about 1 minute on 4 cores.

{.experimental: "strictFuncs".}

import std/[options, os, strutils, unittest]
import ../../src/[findings, flatc, schemas]


const SHIPPED = """
namespace pga_visualiser.scene;

file_identifier "RGAS";

enum Ink : ubyte { Backdrop = 0, Outline = 6, Algebra = 7, Invalid = 8, Rose = 9, Copper = 10 }

table Object {
  ink: Ink = Rose;
  is_visible: bool = true;
  label: string;
  radius: double = 0.08;
}

root_type Object;
"""
  ## Schema base shipped: one enum, one table with defaults off type's zero.


proc held(changed: string): seq[Finding] =
  ## Hold `changed` to `SHIPPED` through patched `flatc`, under scratch root.
  let
    folder = flatcIn(rootFlatc(getEnv(KEY_FLATC)))
    root = getTempDir() / "test_schemas_" & $getCurrentProcessId()
  doAssert folder.isSome, "patched flatc could not be built"
  createDir(root / "schemas")
  defer: removeDir(root)
  writeFile(root / "schemas" / "scene.fbs", changed)
  conformFindings(folder.get / "bin" / "flatc", root, [("schemas/scene.fbs", SHIPPED)])



suite "Schemas":
  test "changed schemas are read, and nothing else is":
    check schemasChanged(["a/scene.fbs", "a/scene.nim", "b/data.json", "c.fbs"]) ==
      @["a/scene.fbs", "c.fbs"]


  test "field added with default, or deprecated, keeps version base shipped":
    # Version 4 of scene file added radius, read as default from older file; version 7 dropped
    #   shine, which stays as deprecated slot.
    let added = SHIPPED.replace("  radius: double = 0.08;\n",
      "  radius: double = 0.08;\n  shines: bool;\n")
    check held(added).len == 0
    check held(added.replace("shines: bool;", "shines: bool (deprecated);")).len == 0


  test "renumbered enum, moved, deleted or retyped field, or new default, breaks it":
    # Case held: version 6 of scene file dropped `Algebra` and moved every later hue one down,
    #   so older file read wrong colours, and only code written by hand caught it (#755).
    #   Domain is each edit `flatc --conform` refuses.
    let edits = [
      SHIPPED.replace("Algebra = 7, Invalid = 8, Rose = 9, Copper = 10",
        "Invalid = 7, Rose = 8, Copper = 9"),  # renumbered
      SHIPPED.replace("  label: string;\n  radius: double = 0.08;\n",
        "  radius: double = 0.08;\n  label: string;\n"),  # moved
      SHIPPED.replace("  label: string;\n", ""),  # deleted
      SHIPPED.replace("radius: double = 0.08;", "radius: float = 0.08;"),  # retyped
      SHIPPED.replace("radius: double = 0.08;", "radius: double = 0.1;"),  # new default
    ]
    for edit in edits:
      let found = held(edit)
      check found.len == 1
      check found[0].message.contains("conform")  # `flatc` names what broke
    # Dropping slot while keeping every other number passes: stored numbers never move.
    check held(SHIPPED.replace("Algebra = 7, ", "")).len == 0
