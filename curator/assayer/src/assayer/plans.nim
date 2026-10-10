## Plan each run of test file: one compile for each backend under each configuration, each into
##   cache of its own, with command built as testament builds it (`prepareTestCmd` of
##   `testament/testament.nim`, Nim 2.2.12).
##   Command is template of header with `$target`, `$options`, `$file`, `$filedir` and `$nim`
##     replaced, and leading `nim ` replaced by compiler, as testament replaces each. Compiler is
##     quoted for shell, where testament writes it bare.
##   Options are default of backend (`-d:nodejs` for JavaScript), then `--nimCache` and `--out` of
##     run, then configuration, so configuration speaks last. `--backend` or `-b` inside
##     configuration moves run to that backend, as testament moves it (`changeTarget`).
##   Rerun is same command without `--nimCache` and `--out` of run, spaces joined (`Run.rerun`): it
##     reproduces compile by hand, and log keeps command as run.
##   Runs go configuration by configuration, each under every backend, in order testament takes.
##   Each run compiles into directory of its own under `DIRECTORY_RUNS`, below working directory,
##     named for path of file, backend and place of configuration (`directoryOf`), as
##     `tests/test_k/c_2`: two runs share no cache, so none races another, and run of same file and
##     configuration finds its cache again. Report prints that path, so it reads as what it holds.
##     Testament instead shares one cache across configurations of file, and writes program
##     beside it, which holds only while configurations run one after another.
##   Program lands inside that directory, and runs from working directory, as testament runs it.
##     Log of failed run lands beside it (`logOf`).
##   Template naming what testament fills nothing for refuses file before any run (`nameUnfilled`),
##     since every run of file would fail alike.
##
##   Cost: configuration naming its own `--out` or `--nimCache` moves program or cache where run
##     never looks; program it cannot find fails run, by name.
##   Cost: test reading files beside its own program (`getAppDir`) reads cache instead; no test
##     here does.

{.experimental: "strictFuncs".}

import std/[cmdline, hashes, options, os, sequtils, strutils]
import ./headers


const
  DIRECTORY_RUNS* = "nimcache/assayer"
    ## Directory, below working directory, holding cache of each run; ignored at any depth.
  FILE_LOG* = "output.log"  ## Log of failed run, beside its program: each command, whole output.
  NAMES_FILLED = ["target", "options", "file", "filedir", "nim"]
    ## Names testament fills in template of command (`prepareTestCmd`).
  LUT_OPTIONS_BY_TARGET: array[Target, string] = ["", "", "", "-d:nodejs"]
    ## Options each backend adds before all others, as testament adds them.
  PREFIXES_BACKEND = ["-b:", "-b=", "--backend:", "--backend="]
    ## Openings of word of configuration naming backend, as `nim` and testament read it.
  REJECTIONS_STRICT = "--unhandled-rejections=strict"
    ## Option Node.js takes before program, so promise rejected unhandled fails it, as under
    ## testament.


type Run* = object  ## Define one compile of test file, for one backend under one configuration.
  file*: string  ## Path of test file, as named.
  target*: Target  ## Backend compile writes for.
  configuration*: string  ## Options matrix gives run; empty where it gives none.
  action*: Action  ## What run must do to pass.
  command*: string  ## Compile command, whole, as shell reads it.
  rerun*: string  ## Compile command with no cache or program of run, as hand reruns it.
  executable*: string  ## Path compile writes program to, absolute.
  execution*: seq[string]  ## Command line running program: program alone, or Node.js before it.
  refusal*: string  ## Why run cannot start; empty where it can.


func targetIn*(configuration: string, target: Target): Target =
  ## Read backend run compiles for: one last `--backend` or `-b` of configuration names, else
  ##   `target`, as testament reads it.
  ##   Words split as `std/parseopt` splits them (`parseCmdLine`), and value follows `:` or `=`.
  result = target
  for word in configuration.parseCmdLine:
    for prefix in PREFIXES_BACKEND:
      if word.startsWith(prefix): result = word[prefix.len .. ^1].targetOf.get(result)


func absoluteOf*(path, root: string): string =
  ## Read path absolute and normalized, relative one resolved against working directory `root`, so
  ##   two paths naming one file read alike.
  normalizedPath(if path.isAbsolute: path else: root / path)


func directoryOf*(path, root: string; target: Target; place: int): string =
  ## Read directory run of test file compiles into: path of file below `root`, extension dropped,
  ##   then backend and place of configuration counted from one, as `tests/test_k/c_2`.
  ##   File outside `root` takes its name and hash of its absolute path instead, so no directory
  ##     climbs out of `DIRECTORY_RUNS`.
  ##   `root` is absolute already, so prefix decides what lies below it; `relativePath` would read
  ##     working directory, which no function here reads.
  let
    absolute = path.absoluteOf(root)
    prefix = if root.endsWith(DirSep): root else: root & DirSep
    key =
      if absolute.startsWith(prefix): absolute[prefix.len .. ^1].changeFileExt("")
      else: absolute.splitFile.name & "_" & absolute.hash.toHex
  root / DIRECTORY_RUNS / key / ($target & "_" & $(place + 1))


func logOf*(run: Run): string =
  ## Read path of log of run, beside its program.
  run.executable.parentDir / FILE_LOG


func nameUnfilled*(command: string): string =
  ## Read first `$` name of template testament fills nothing for, `$` included; empty where none.
  ##   `$$` is dollar itself, and `${name}` reads as `$name`, as `strutils.%` reads both. Digit
  ##     after `$` reads as name too, since testament fills no place by number.
  var i = 0
  while i < command.len:
    if command[i] != '$':
      inc i
      continue
    if i + 1 < command.len and command[i+1] == '$':
      i += 2
      continue
    var name = ""
    if i + 1 < command.len and command[i+1] == '{':
      let closing = command.find('}', i + 2)
      if closing < 0: return command[i .. ^1]
      name = command[i+2..<closing]
      i = closing + 1
    else:
      var j = i + 1
      while j < command.len and command[j] in IdentChars: inc j
      name = command[i+1..<j]
      i = j
    if name notin NAMES_FILLED: return "$" & name
  ""


func refusalTemplate*(command: string): string =
  ## Read why template of command refuses file: `$` name testament fills nothing for; empty where
  ##   template names none.
  let name = command.nameUnfilled
  if name.len == 0: "" else: "header command names `" & name & "`, which testament does not fill"


func spacesJoined*(command: string): string =
  ## Write command with each run of spaces outside quotes as one space, and none at either end;
  ##   empty `$options` of template otherwise leaves two.
  var quote = '\0'
  for c in command:
    if quote != '\0':
      if c == quote: quote = '\0'
    elif c in {'"', '\''}: quote = c
    elif c == ' ' and (result.len == 0 or result[^1] == ' '): continue
    result.add c
  result.strip(leading = false)


func commandOf(head: string; target: Target; options, path, directory, compiler: string): string =
  ## Fill template of command, leading `nim` replaced already, as testament fills it
  ##   (`prepareTestCmd`); `ValueError` where template names what testament fills nothing for.
  head % [
    "target", $target,
    "options", options,
    "file", path.quoteShell,
    "filedir", directory,
    "nim", compiler.quoteShell,
  ]


func runsOf*(path: string; header: Header; compiler, node, root: string): seq[Run] =
  ## Plan each run header asks of test file at path: one for each backend under each
  ##   configuration.
  ##   `compiler` is absolute path of compiler; `node` that of Node.js, empty where PATH holds none;
  ##   `root` is absolute working directory, which cache and `$filedir` resolve against.
  let
    absolute = path.absoluteOf(root)
    head =
      if header.command.startsWith("nim "): compiler.quoteShell & header.command[3 .. ^1]
      else: header.command
  for place, configuration in header.matrix:
    for target_header in header.targets:
      let
        target = configuration.targetIn(target_header)
        directory = directoryOf(path, root, target_header, place)
        extension = if target == Target.JavaScript: "js" else: ExeExt
        executable = directory / path.splitFile.name.changeFileExt(extension)
        options = [
          LUT_OPTIONS_BY_TARGET[target],
          "--nimCache:" & directory.quoteShell,
          "--out:" & executable.quoteShell,
          configuration,
        ].filterIt(it.len > 0).join(" ")
        options_rerun = [LUT_OPTIONS_BY_TARGET[target], configuration].filterIt(it.len > 0)
            .join(" ")
      var run = Run(
        file: path,
        target: target,
        configuration: configuration,
        action: header.action,
        executable: executable,
        execution: @[executable],
      )
      try:
        run.command = commandOf(head, target, options, path, absolute.parentDir, compiler)
        run.rerun =
          commandOf(head, target, options_rerun, path, absolute.parentDir, compiler).spacesJoined
      except ValueError:
        run.refusal = header.command.refusalTemplate
      if target == Target.JavaScript:
        if node.len == 0: run.refusal = "no Node.js on PATH for a JavaScript run"
        run.execution = @[node, REJECTIONS_STRICT, executable]
      result.add run
