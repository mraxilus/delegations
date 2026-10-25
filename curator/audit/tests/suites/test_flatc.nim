## Replicate patched build of `flatc` that `flatc.nim` header describes, i.e. pin, edits, store.
##   End-to-end test generates Nim from fixture schema, writes and reads one buffer through it,
##     and has `flatc`'s own C++ reader read same bytes, so each fault patch mends is held on
##     bytes rather than on edit text.
##   Cost: cold store builds `flatc`, about 1 minute on 4 cores, and needs network, `cmake` and
##     `g++`; warm store costs one Nim compile.

{.experimental: "strictFuncs".}

import std/[json, options, os, osproc, strutils, unittest]
import ../../src/flatc


const
  SCHEMA = """
namespace fixture;

file_identifier "FXTR";

table Part { name: string; is_visible: bool = true; ink: ubyte = 9; size: double = 0.08; }

table Whole { first: Part; parts: [Part]; }

root_type Whole;
"""
    ## Fixture schema: table inside table, list of tables, defaults off type's zero.
  PROGRAM = """
import std/[options, os]
import flatbuffers
import fixture/[Part, Whole]

proc part(b: var Builder; name: string; visible: bool; ink: uint8; size: float64): uoffset =
  let named = b.Create(name)
  b.PartStart()
  b.PartAddname(named)
  b.PartAddisVisible(visible)
  b.PartAddink(ink)
  b.PartAddsize(size)
  b.PartEnd()

var b = newBuilder(0)
let
  first = b.part("first", false, 0, 0.0)
  others = [b.part("a", true, 9, 0.08), b.part("b", false, 1, 2.5)]
b.WholeStartpartsVector(others.len.uoffset)
for i in countdown(others.high, 0): b.PrependOffsetRelative(others[i])
let parts = b.EndVector()
b.WholeStart()
b.WholeAddfirst(first)
b.WholeAddparts(parts)
b.WholeFinish(b.WholeEnd())
writeFile(paramStr(1), b.FinishedBytes())

let text = readFile(paramStr(1))
var whole: Whole
whole.GetRootAs(text, 0)
echo WholeHasIdentifier(text), " ", "XXXXXXXX".HasIdentifier(WholeIdentifier)
let one = whole.first.get
echo one.name.get, " ", one.isVisible, " ", one.ink, " ", one.size
for p in whole.parts: echo p.name.get, " ", p.isVisible, " ", p.ink, " ", p.size
"""
    ## Fixture program: write buffer through generated Nim, then read it back.
  READ = "true false\nfirst false 0 0.0\na true 9 0.08\nb false 1 2.5\n"
    ## What fixture program prints once each fault is mended.



suite "Flatc":
  test "store lies outside repository, and override wins":
    check rootFlatc("/tmp/flatc") == "/tmp/flatc"
    check rootFlatc("").endsWith(DIRECTORY_FLATC)
    # Audit reads untracked files, so store inside checkout would be audited.
    check not rootFlatc("").startsWith(".")
    check DIRECTORY_FLATC.parentDir == ".cache/koch"  # store is koch's own, beside assets


  test "edit applies only where its text is found exactly once":
    let edit = Edit(path: "f", before: "old", after: "new")
    check "a old b".patched(edit) == some("a new b")
    check "a b".patched(edit).isNone  # pin moved: edit is refused, never skipped
    check "old old".patched(edit).isNone  # ambiguous: refused rather than guessed


  test "build is named by pin and by patch, so changed edit is different build":
    check KEY_BUILD.startsWith(COMMIT_FLATC[0 ..< 12])
    check digestEdits(EDITS) == digestEdits(EDITS)  # same patch, same name
    var changed = @EDITS
    changed[0].after.add " "
    check digestEdits(changed) != digestEdits(EDITS)  # changed patch never reads stale build


  test "generated Nim reads tables inside tables, keeps defaults, and writes identifier":
    # Case held: release 25.12.19 crashed reading `algebra` and `measurands` of baseline of
    #   pga_benchmark, read hidden object back visible, and wrote no identifier (#755). Domain
    #   is table field, list of tables, scalar at type's zero under other default, identifier,
    #   and `-o`, which wrote nothing.
    let folder = flatcIn(rootFlatc(getEnv(KEY_FLATC)))
    require folder.isSome
    let
      work = getTempDir() / "test_flatc_" & $getCurrentProcessId()
      binary = folder.get / "bin" / "flatc"
      buffer = work / "whole.fxtr"
    createDir(work)
    defer: removeDir(work)
    writeFile(work / "fixture.fbs", SCHEMA)
    writeFile(work / "program.nim", PROGRAM)
    let generated = execCmdEx(quoteShellCommand(
      [binary, "--nim", "-o", work / "generated", work / "fixture.fbs"]
    ))
    check generated.exitCode == 0
    check fileExists(work / "generated" / "fixture" / "Whole.nim")  # `-o` is obeyed
    let ran = execCmdEx(quoteShellCommand([
      getCurrentCompilerExe(), "r", "--hints:off", "--warnings:off",
      "--path:" & folder.get / "nim" / "flatbuffers", "--path:" & work / "generated",
      "--nimcache:" & work / "cache", work / "program.nim", buffer,
    ]))
    check ran.exitCode == 0
    check ran.output == READ
    # C++ reader of `flatc` checks identifier, since `--raw-binary` is absent.
    let read = execCmdEx(quoteShellCommand([
      binary, "-t", "--strict-json", "--defaults-json", "-o", work, work / "fixture.fbs",
      "--", buffer,
    ]))
    check read.exitCode == 0
    let whole = parseFile(work / "whole.json")
    check whole["first"]["is_visible"].getBool == false  # hidden stays hidden
    check whole["parts"][1]["ink"].getInt == 1
