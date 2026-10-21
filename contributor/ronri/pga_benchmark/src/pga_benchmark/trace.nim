## Read machine's work per measurand from trace valgrind's `lackey` writes over `machine`.
##   Trace lists every instruction executed, `I  <address>,<length>`, and after it every access
##     it made, each `<address>,<bytes>`: load ` L`, store ` S`, and modify ` M`, which loads
##     and stores same bytes. Valgrind's own lines open `==`, and reader skips them.
##   Trace names no function, so `machine` writes runtime entry of every wrapper and of driver
##     calling them, and symbol table (`nm -S`) gives driver's extent and binary's text.
##   Wrapper's work opens at instruction at its entry and closes at first instruction back in
##     driver: its own instructions, its return, and every function it calls; never call
##     instruction, nor what driver does with result. So count is callgrind's inclusive cost.
##   Instruction outside binary's text runs in shared object, such as C library, whose code
##     processor may select at load; wrapper reaching one says so, and band of its counts is
##     zero no longer (VII.12).
##
##   Cost: instruction with `rep` lists once per trip, as callgrind counts it, so fill of
##     `rep stos` counts one instruction and 8 bytes per word it writes.
##   Cost: trace runs to million lines per algebra; read line by line, never held whole.

{.experimental: "strictFuncs".}

import std/[json, strutils, tables]


const SYMBOL_DRIVER* = "machine_drive"
  ## C name of driver calling every wrapper, which `machine` exports and reader finds in symbols.


type
  Work* = object  ## Define machine's work of one wrapper, as trace lists it.
    instructions*: int  ## Instructions executed, each trip of `rep` one.
    bytes_read*: int  ## Bytes loaded, those modify loads among them.
    bytes_written*: int  ## Bytes stored, those modify stores among them.
    is_shared_reached*: bool
      ## Whether any instruction ran outside binary's text, i.e. in shared object.
  Symbol* = object  ## Define one function of symbol table, at its address in file.
    address*, size*: uint
    name*: string
  Tally* = object  ## Define reader's state, line by line over trace.
    entries: Table[uint, string]  ## Runtime entry of each wrapper to id of its measurand.
    ids: seq[string]  ## Ids of measurands in order `machine` listed them.
    driver: Slice[uint]  ## Runtime extent of driver, last byte inclusive.
    text: Slice[uint]  ## Runtime extent of binary's text, last byte inclusive.
    opened: string  ## Id of wrapper whose work is being read; empty between wrappers.
    works: Table[string, Work]  ## Work of every wrapper entered so far.


func parseEntries*(text: string): seq[(string, uint)] =
  ## Read entries `machine` writes: one `<name>\t<hex address>` per line, driver first.
  for line in text.splitLines:
    if line.len == 0: continue
    let fields = line.split('\t')
    if fields.len != 2:
      raise newException(ValueError, "Entry holds name and address; got `" & line & "`.")
    result.add (fields[0], fromHex[uint](fields[1]))


func parseSymbols*(text: string): seq[Symbol] =
  ## Read functions of symbol table `nm -S` prints: `<address> <size> <type> <name>`.
  ##   Function is text symbol, local or global, strong or weak; data and sizeless symbols are
  ##     skipped.
  for line in text.splitLines:
    let fields = line.splitWhitespace
    if fields.len != 4 or fields[2] notin ["t", "T", "w", "W"]: continue
    result.add Symbol(
      address: fromHex[uint](fields[0]),
      size: fromHex[uint](fields[1]),
      name: fields[3],
    )


func initTally*(entries: openArray[(string, uint)]; symbols: openArray[Symbol]): Tally =
  ## Ready reader for one trace, from entries `machine` wrote and functions of its binary.
  ##   Binary loads at offset, so runtime entry of driver less its address in file gives it.
  if entries.len == 0 or entries[0][0] != SYMBOL_DRIVER:
    raise newException(
      ValueError,
      "Entries open with driver `" & SYMBOL_DRIVER & "`; got `" &
          (if entries.len == 0: "" else: entries[0][0]) & "`.",
    )
  var driver = Symbol()
  for symbol in symbols:
    if symbol.name == SYMBOL_DRIVER: driver = symbol
  if driver.size == 0:
    raise newException(
      ValueError,
      "Symbol table holds no sized driver; got `" & $symbols.len & "` functions.",
    )
  let offset = entries[0][1] - driver.address
  result.driver = entries[0][1] .. entries[0][1] + driver.size - 1
  result.text = high(uint) .. low(uint)
  for symbol in symbols:
    if symbol.size == 0: continue
    result.text.a = min(result.text.a, symbol.address + offset)
    result.text.b = max(result.text.b, symbol.address + offset + symbol.size - 1)
  for (id, entry) in entries[1 .. ^1]:
    if entry in result.entries:
      raise newException(ValueError, "Two wrappers share one entry; got `" & id & "`.")
    result.entries[entry] = id
    result.ids.add id


func address(line: string): uint =
  ## Read address of trace line `<mark> <address>,<length or bytes>`.
  fromHex[uint](line[3 ..< line.find(',')].strip)


func bytes(line: string): int =
  ## Read bytes one access of trace line moves, after its comma.
  parseInt(line[line.find(',') + 1 .. ^1].strip)


func read*(tally: var Tally, line: string) =
  ## Read one trace line into work of wrapper it falls in, if any.
  if line.startsWith("I  "):
    let address = line.address
    if tally.opened.len == 0:
      if address notin tally.entries: return
      tally.opened = tally.entries[address]
      if tally.opened in tally.works:
        raise newException(ValueError, "Wrapper runs twice; got `" & tally.opened & "`.")
      tally.works[tally.opened] = Work()
    elif address in tally.driver:
      tally.opened = ""
      return
    tally.works[tally.opened].instructions += 1
    if address notin tally.text: tally.works[tally.opened].is_shared_reached = true
  elif tally.opened.len > 0 and line.len > 3 and line[0] == ' ' and line[2] == ' ':
    case line[1]
    of 'L': tally.works[tally.opened].bytes_read += line.bytes
    of 'S': tally.works[tally.opened].bytes_written += line.bytes
    of 'M':
      tally.works[tally.opened].bytes_read += line.bytes
      tally.works[tally.opened].bytes_written += line.bytes
    else: discard


func works*(tally: Tally): seq[(string, Work)] =
  ## Read work of every wrapper, in order `machine` listed them; trace must hold each, closed.
  if tally.opened.len > 0:
    raise newException(ValueError, "Trace ends inside wrapper; got `" & tally.opened & "`.")
  for id in tally.ids:
    if id notin tally.works:
      raise newException(ValueError, "Trace holds no work of wrapper; got `" & id & "`.")
    result.add (id, tally.works[id])


func nodeWork*(work: Work): JsonNode =
  ## Build work of one wrapper as object, one field per count.
  %*{
    "instructions": work.instructions,
    "bytes_read": work.bytes_read,
    "bytes_written": work.bytes_written,
    "is_shared_reached": work.is_shared_reached,
  }
