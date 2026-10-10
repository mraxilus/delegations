## Replicate header reading of `headers.nim`: four keys, as testament reads them, refusing others.

{.experimental: "strictFuncs".}

import std/[options, strutils, unittest]
import ../../src/assayer/headers


const
  QUOTES = "\"\"\""  ## Triple quote closing header, and opening it after `discard `.
  OPENING = "discard " & QUOTES  ## Line opening header.
  KEYS_GIVEN = [
    ("action", "compile"),
    ("cmd", "\"nim c $options $file\""),
    ("matrix", "\"-d:a; -d:b\""),
    ("targets", "\"js\""),
  ]
    ## Each key header may give, with value other than its default.


func headed(lines: varargs[string]): string =
  ## Write source whose header holds lines, then one line of code.
  OPENING & "\n" & lines.join("\n") & "\n" & QUOTES & "\necho 1\n"



suite "Headers":
  test "header is text between opening and next triple quote, and none asks for nothing":
    check textHeader(headed("action: run")) == ("\naction: run\n", "")  # text kept whole
    check textHeader("echo 1\n") == ("", "")  # no header
    check textHeader("  " & OPENING & "\n" & QUOTES & "\n") == ("", "")  # indented opening is code
    check textHeader(OPENING & "\nmatrix: '''-d:a'''\n" & QUOTES) == ("\nmatrix: " & QUOTES &
        "-d:a" & QUOTES & "\n", "")  # `'''` reads as triple quote


  test "header opening past its last line, twice, or never closed is refusal":
    let
      past = "\n".repeat(LINE_OPENING_MAX) & OPENING & "\n" & QUOTES & "\n"
      last = "\n".repeat(LINE_OPENING_MAX - 1) & OPENING & "\n" & QUOTES & "\n"
    check past.textHeader.refusal == "Header opens past line `10`; got line `11`."  # line 11
    check last.textHeader.refusal == ""  # line 10 is last line header may open on
    check textHeader(headed("action: run") & OPENING & "\n" & QUOTES).refusal ==
        "Header opens twice; got second opening on line `5`."  # second opening anywhere
    check textHeader(OPENING & "\naction: run\n").refusal ==
        "Header opens on line `1` and never closes."  # no closing quote


  test "absent key takes default of testament, and given key its value, in every combination":
    for subset in 0 ..< 1 shl KEYS_GIVEN.len:
      var lines: seq[string]
      for k, (key, value) in KEYS_GIVEN:
        if (subset and (1 shl k)) != 0: lines.add key & ": " & value
      let
        header = headed(lines).headerOf
        is_given = proc(k: int): bool = (subset and (1 shl k)) != 0
      check header.refusal == ""  # every combination reads
      check header.action == (if is_given(0): Action.Compile else: Action.Run)  # `action`
      check header.command == (if is_given(1): "nim c $options $file" else: COMMAND_DEFAULT)
      check header.matrix == (if is_given(2): @["-d:a", "-d:b"] else: @[""])  # `matrix`
      check header.targets == (if is_given(3): {Target.JavaScript} else: {Target.C})  # `targets`


  test "file opening no header asks for defaults alone":
    let header = "echo 1\n".headerOf
    check header == Header()  # defaults
    check header.matrix == @[""] and header.targets == {Target.C}  # one run, C backend


  test "key normalizes, `target` is alias, and each word of targets adds backend":
    check headed("Action: Reject").headerOf.action == Action.Reject  # case and value normalized
    check headed("tar_gets: \"c js\"").headerOf.targets == {Target.C, Target.JavaScript}
    check headed("target: \"c++ objc\"").headerOf.targets ==
        {Target.CPlusPlus, Target.ObjectiveC}  # alias, and `c++` names C++
    check headed("targets: \"c\"", "target: \"js\"").headerOf.targets ==
        {Target.C, Target.JavaScript}  # both keys add
    check headed("targets: \"\"").headerOf.targets == {Target.C}  # empty value asks default


  test "matrix splits at semicolon, each configuration stripped, empty one kept":
    check headed("matrix: \" -d:a ;-d:b \"").headerOf.matrix == @["-d:a", "-d:b"]  # stripped
    check headed("matrix: \"-d:a;\"").headerOf.matrix == @["-d:a", ""]  # empty kept, as testament
    check headed("matrix: \"\"").headerOf.matrix == @[""]  # one configuration of no options


  test "key outside four, key given twice, and value testament lacks are refusals":
    check headed("exitcode: 1").headerOf.refusal ==
        "Header gives key assayer does not read; got `exitcode`."  # testament honours it
    check headed("output: \"1\"").headerOf.refusal ==
        "Header gives key assayer does not read; got `output`."
    check headed("cmd: \"a\"", "CMD: \"b\"").headerOf.refusal ==
        "Header gives key twice; got `CMD`."  # normalized alike
    check headed("action: build").headerOf.refusal ==
        "Header names action testament lacks; got `build`."
    check headed("targets: \"c wasm\"").headerOf.refusal ==
        "Header names target testament lacks; got `wasm`."
    check headed("[section]").headerOf.refusal == "Header opens section; got `[section]`."
    check headed("--define: x").headerOf.refusal == "Header holds option; got `--define`."
    check headed("action: : run").headerOf.refusal.startsWith("Header does not parse; got `")


  test "word names backend as testament names it, case aside, and other word names none":
    check targetOf("c") == some(Target.C)  # C
    check targetOf("cpp") == some(Target.CPlusPlus) and targetOf("c++") == some(Target.CPlusPlus)
    check targetOf("objc") == some(Target.ObjectiveC)  # Objective-C
    check targetOf("JS") == some(Target.JavaScript)  # normalized
    check targetOf("wasm").isNone and targetOf("").isNone  # neither names backend
    for target in Target: check targetOf($target) == some(target)  # round trip of command word


  test "stub shapes of this repository read whole":
    let
      probe = headed(
        "action: run",
        "cmd: \"nim c --hints:off -d:testing -d:nimUnittestAbortOnError:on $options $file\"",
        "matrix: \"-d:probe.modulus=4\"",
      ).headerOf  # `curator/probe/tests/test_modulus_4.nim`
      browser = headed(
        "action: run",
        "matrix: \"-d:nimUnittestAbortOnError:on -d:visualiser.history_capacity=4\"",
        "targets: \"js\"",
      ).headerOf  # `contributor/ronri/rga_visualiser/tests/test_4d_browser.nim`
    check probe.refusal == "" and probe.matrix == @["-d:probe.modulus=4"]  # one configuration
    check probe.command.startsWith("nim c --hints:off")  # command as written
    check browser.command == COMMAND_DEFAULT and browser.targets == {Target.JavaScript}
