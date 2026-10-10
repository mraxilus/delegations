## Read testament header of test file: `action`, `cmd`, `matrix` and `targets`, as testament reads
##   them (`testament/specs.nim`, Nim 2.2.12); every other key is refusal.
##   Header is text between `discard """` and next `"""` (`textHeader`). Opening counts only where
##     no space stands before it, so indented one is code, and only by line `LINE_OPENING_MAX`.
##     Second opening anywhere in file is refusal, and so is opening never closed.
##   File opening no header asks for defaults, which are testament's: action `run`, command
##     `COMMAND_DEFAULT`, one configuration of no options, C backend.
##   Text parses as configuration file through `std/parsecfg`, each key normalized as testament
##     normalizes it: lowercase, underscores dropped. `cmd` stays as written, since compiler
##     replacing its leading `nim` is planner's to know (`plans.nim`).
##   Key outside four is refusal, never passed by: testament honours keys such as `output` and
##     `exitcode`, so run passing here what they fail there would report green for check never
##     made. Key given twice is refusal too; testament stops on assertion there.
##
##   Cost: inline error markers (`#[tt.`) go unread, so reject run checks file of its last error
##     alone; `NIM_COMPILE_TO_CPP`, which turns default backend of testament to C++, goes unread
##     too.

{.experimental: "strictFuncs".}

import std/[options, parsecfg, streams, strutils]


const
  OPENING = "discard \"\"\""  ## Text opening header.
  QUOTES = "\"\"\""  ## Text closing header.
  LINE_OPENING_MAX* = 10  ## Last line header may open on, as testament has it.
  KEYS = "`action`, `cmd`, `matrix` and `targets`"  ## Keys header may give, as messages list them.
  ACTIONS = "`compile`, `reject` and `run`"  ## Actions testament reads, as messages list them.
  TARGETS = "`c`, `cpp`, `c++`, `objc` and `js`"  ## Backend words testament reads, as listed.
  COMMAND_DEFAULT* =
    "nim $target --hints:on -d:testing --nimblePath:build/deps/pkgs2 $options $file"
    ## Compile command testament takes where header names none, word for word.


type
  Action* {.pure.} = enum  ## Define what run must do to pass, i.e. value of `action`.
    Compile = "compile"  ## Compile, printing no error.
    Reject = "reject"  ## Fail to compile, error naming test file.
    Run = "run"  ## Compile, then exit 0.

  Target* {.pure.} = enum  ## Define backend run compiles for, named as `nim` command names it.
    C = "c"  ## C.
    CPlusPlus = "cpp"  ## C++, which `targets` names `c++` too.
    ObjectiveC = "objc"  ## Objective-C.
    JavaScript = "js"  ## JavaScript, which Node.js runs.

  Header* = object  ## Define what testament header of test file asks.
    action*: Action = Action.Run  ## What each run must do to pass.
    command*: string = COMMAND_DEFAULT  ## Template of compile command, as written.
    matrix*: seq[string] = @[""]  ## Options of each configuration, in order.
    targets*: set[Target] = {Target.C}  ## Backends, each compiled under every configuration.
    refusal*: string  ## Why header cannot be read; empty where it can.


func targetOf*(word: string): Option[Target] =
  ## Read backend word names, as testament reads `targets` and `--backend`; `none` where it names
  ##   none.
  ##   Word is normalized first, as testament normalizes it, so `JS` names JavaScript too.
  case word.normalize
  of "c": some(Target.C)
  of "cpp", "c++": some(Target.CPlusPlus)
  of "objc": some(Target.ObjectiveC)
  of "js": some(Target.JavaScript)
  else: none(Target)


func textHeader*(source: string): tuple[text, refusal: string] =
  ## Read text of testament header source opens, as testament reads it; both empty where source
  ##   opens none.
  ##   `'''` inside reads as `"""`, and `\31` as unit separator, since testament replaces both.
  var
    first = -1
    last = -1
    line = 1
    line_opening = 0
    i = 0
  while i < source.len:
    if (i == 0 or source[i-1] != ' ') and source.continuesWith(OPENING, i):
      if first >= 0:
        return ("", "header opens twice, again on line " & $line)
      if line > LINE_OPENING_MAX:
        return ("", "header opens on line " & $line & ", past line " & $LINE_OPENING_MAX)
      i += OPENING.len
      first = i
      line_opening = line
    elif first >= 0 and last < 0 and source.continuesWith(QUOTES, i):
      last = i
      i += QUOTES.len
    else:
      if source[i] == '\n': inc line
      inc i
  if first < 0: return ("", "")
  if last < 0: return ("", "header opens on line " & $line_opening & " and never closes")
  (source[first..<last].multiReplace(("'''", QUOTES), ("\\31", "\31")), "")


proc headerOf*(source: string): Header =
  ## Read testament header source opens, as testament reads it; defaults where source opens none,
  ##   and refusal where header cannot be read.
  ##   Proc, since `std/parsecfg` reads through stream, whose calls compiler cannot prove pure.
  ##   `result` starts from `Header()`, since implicit result starts zeroed, without defaults of
  ##     its fields.
  let (text, refusal) = source.textHeader
  if refusal.len > 0: return Header(refusal: refusal)
  result = Header()
  var
    parser: CfgParser
    keys: seq[string]
    matrix: seq[string]
    targets: set[Target]
  parser.open(newStringStream(text), "", 1)
  defer: parser.close
  while true:
    let event = parser.next
    case event.kind
    of cfgEof: break
    of cfgSectionStart:
      return Header(refusal: "header opens section `[" & event.section & "]`; testament ignores it")
    of cfgOption:
      return Header(refusal: "header holds option `--" & event.key & "`; testament ignores it")
    of cfgError:
      return Header(refusal: "header does not parse: " & event.msg)
    of cfgKeyValuePair:
      let key = event.key.normalize
      if key in keys: return Header(refusal: "header gives key `" & event.key & "` twice")
      keys.add key
      case key
      of "action":
        case event.value.normalize
        of "compile": result.action = Action.Compile
        of "reject": result.action = Action.Reject
        of "run": result.action = Action.Run
        else:
          return Header(refusal: "header action `" & event.value & "` is none of " & ACTIONS)
      of "cmd": result.command = event.value
      of "matrix":
        for configuration in event.value.split(';'): matrix.add configuration.strip
      of "targets", "target":
        for word in event.value.splitWhitespace:
          let target = word.targetOf
          if target.isNone:
            return Header(refusal: "header target `" & word & "` is none of " & TARGETS)
          targets.incl target.get
      else:
        return Header(refusal: "header key `" & event.key & "` is not read; assayer reads " & KEYS)
  if matrix.len > 0: result.matrix = matrix
  if targets != {}: result.targets = targets
