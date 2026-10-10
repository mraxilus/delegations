## Plan each run of test file: one compile for each backend under each configuration, each into
##   cache of its own, with command built as testament builds it (`prepareTestCmd` of
##   `testament/testament.nim`, Nim 2.2.12).
##   Command is template of header with `$target`, `$options`, `$file`, `$filedir` and `$nim`
##     replaced, and leading `nim ` replaced by compiler, as testament replaces each. Compiler is
##     quoted for shell, where testament writes it bare.
##   Options are default of backend (`-d:nodejs` for JavaScript), then `--nimCache` and `--out` of
##     run, then configuration, so configuration speaks last. `--backend` or `-b` inside
##     configuration moves run to that backend, as testament moves it (`changeTarget`).
##   Runs go configuration by configuration, each under every backend, in order testament takes.
##   Each run compiles into directory of its own under `DIRECTORY_RUNS`, below working directory,
##     named for file, backend and place of configuration (`directoryOf`): two runs share no
##     cache, so none races another, and run of same file and configuration finds its cache again.
##     Testament instead shares one cache across configurations of file, and writes program
##     beside it, which holds only while configurations run one after another.
##   Program lands inside that directory, and runs from working directory, as testament runs it.
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
  ## Read directory run of test file compiles into: file name, backend and place of configuration
  ##   in matrix, then hash of absolute path, so files sharing name in two directories part.
  let name = [path.splitFile.name, $target, $place, path.absoluteOf(root).hash.toHex].join("_")
  root / DIRECTORY_RUNS / name


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
      var run = Run(
        file: path,
        target: target,
        configuration: configuration,
        action: header.action,
        executable: executable,
        execution: @[executable],
      )
      try:
        run.command = head % [
          "target", $target,
          "options", options,
          "file", path.quoteShell,
          "filedir", absolute.parentDir,
          "nim", compiler.quoteShell,
        ]
      except ValueError:
        run.refusal = "Header command holds `$` naming nothing; got `" & header.command & "`."
      if target == Target.JavaScript:
        if node.len == 0: run.refusal = "No Node.js on PATH, which JavaScript run needs."
        run.execution = @[node, REJECTIONS_STRICT, executable]
      result.add run
