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
##   Copy of wrapper is read as wrapper is, apart, and its original says whether they agree.
##
##   Cost: instruction with `rep` lists once per trip, as callgrind counts it, so fill of
##     `rep stos` counts one instruction and 8 bytes per word it writes.
##   Cost: trace runs to million lines per algebra; read line by line, never held whole.

{.experimental: "strictFuncs".}

import std/[json, strutils, tables]


const SYMBOL_DRIVER* = "machine_drive"
  ## C name of driver calling every wrapper, which `machine` exports and reader finds in symbols.


type
  Entry* = object  ## Define one function `machine` lists, at its runtime address.
    name*: string  ## Id of measurand, or C name of driver.
    address*: uint  ## Runtime address of its first instruction.
    is_copy*: bool  ## Whether function is copy of wrapper, later in same C file.
  Work* = object  ## Define machine's work of one wrapper, as trace lists it.
    instructions*: int  ## Instructions executed, each trip of `rep` one.
    bytes_read*: int  ## Bytes loaded, those modify loads among them.
    bytes_written*: int  ## Bytes stored, those modify stores among them.
    is_shared_reached*: bool
      ## Whether any instruction ran outside binary's text, i.e. in shared object.
    is_copy_apart*: bool  ## Whether copy of wrapper, on same operands, read other counts.
  Symbol* = object  ## Define one function of symbol table, at its address in file.
    address*, size*: uint
    name*: string
  Tally* = object  ## Define reader's state, line by line over trace.
    entries: Table[uint, string]  ## Runtime entry of each wrapper to id of its measurand.
    entries_copy: Table[uint, string]  ## Runtime entry of each copy to id of its measurand.
    ids: seq[string]  ## Ids of measurands in order `machine` listed them.
    driver: Slice[uint]  ## Runtime extent of driver, last byte inclusive.
    text: Slice[uint]  ## Runtime extent of binary's text, last byte inclusive.
    opened: string  ## Id of wrapper whose work is being read; empty between wrappers.
    is_copy_opened: bool  ## Whether function whose work is being read is copy.
    works: Table[string, Work]  ## Work of every wrapper entered so far.
    works_copy: Table[string, Work]  ## Work of every copy entered so far.


func parseEntries*(text: string): seq[Entry] =
  ## Read entries `machine` writes: one `<name>\t<hex address>\t<mark>` per line, driver first;
  ##   mark is `copy` for copy, and empty or absent with its tab for any other.
  for line in text.splitLines:
    if line.len == 0: continue
    let fields = line.split('\t')
    if fields.len notin 2..3 or (fields.len == 3 and fields[2] notin ["", "copy"]):
      raise newException(ValueError, "Entry holds name, address and mark; got `" & line & "`.")
    result.add Entry(
      name: fields[0],
      address: fromHex[uint](fields[1]),
      is_copy: fields.len == 3 and fields[2] == "copy",
    )


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


func initTally*(entries: openArray[Entry]; symbols: openArray[Symbol]): Tally =
  ## Ready reader for one trace, from entries `machine` wrote and functions of its binary.
  ##   Binary loads at offset, so runtime entry of driver less its address in file gives it.
  if entries.len == 0 or entries[0].name != SYMBOL_DRIVER:
    raise newException(
      ValueError,
      "Entries open with driver `" & SYMBOL_DRIVER & "`; got `" &
          (if entries.len == 0: "" else: entries[0].name) & "`.",
    )
  var driver = Symbol()
  for symbol in symbols:
    if symbol.name == SYMBOL_DRIVER: driver = symbol
  if driver.size == 0:
    raise newException(
      ValueError,
      "Symbol table holds no sized driver; got `" & $symbols.len & "` functions.",
    )
  let offset = entries[0].address - driver.address
  result.driver = entries[0].address .. entries[0].address + driver.size - 1
  result.text = high(uint) .. low(uint)
  for symbol in symbols:
    if symbol.size == 0: continue
    result.text.a = min(result.text.a, symbol.address + offset)
    result.text.b = max(result.text.b, symbol.address + offset + symbol.size - 1)
  for entry in entries[1 .. ^1]:
    if entry.address in result.entries or entry.address in result.entries_copy:
      raise newException(ValueError, "Two wrappers share one entry; got `" & entry.name & "`.")
    if entry.is_copy:
      result.entries_copy[entry.address] = entry.name
    else:
      result.entries[entry.address] = entry.name
      result.ids.add entry.name


func address(line: string): uint =
  ## Read address of trace line `<mark> <address>,<length or bytes>`.
  fromHex[uint](line[3 ..< line.find(',')].strip)


func bytes(line: string): int =
  ## Read bytes one access of trace line moves, after its comma.
  parseInt(line[line.find(',') + 1 .. ^1].strip)


func work(tally: var Tally): var Work =
  ## Get work of wrapper or copy being read.
  if tally.is_copy_opened: return tally.works_copy[tally.opened]
  tally.works[tally.opened]


func read*(tally: var Tally, line: string) =
  ## Read one trace line into work of wrapper or copy it falls in, if any.
  if line.startsWith("I  "):
    let address = line.address
    if tally.opened.len == 0:
      tally.is_copy_opened = address in tally.entries_copy
      if tally.is_copy_opened: tally.opened = tally.entries_copy[address]
      elif address in tally.entries: tally.opened = tally.entries[address]
      else: return
      if tally.opened in (if tally.is_copy_opened: tally.works_copy else: tally.works):
        raise newException(ValueError, "Wrapper runs twice; got `" & tally.opened & "`.")
      if tally.is_copy_opened: tally.works_copy[tally.opened] = Work()
      else: tally.works[tally.opened] = Work()
    elif address in tally.driver:
      tally.opened = ""
      return
    tally.work.instructions += 1
    if address notin tally.text: tally.work.is_shared_reached = true
  elif tally.opened.len > 0 and line.len > 3 and line[0] == ' ' and line[2] == ' ':
    case line[1]
    of 'L': tally.work.bytes_read += line.bytes
    of 'S': tally.work.bytes_written += line.bytes
    of 'M':
      tally.work.bytes_read += line.bytes
      tally.work.bytes_written += line.bytes
    else: discard


func works*(tally: Tally): seq[(string, Work)] =
  ## Read work of every wrapper, in order `machine` listed them, each beside its copy where it
  ##   has one; trace must hold each, closed.
  if tally.opened.len > 0:
    raise newException(ValueError, "Trace ends inside wrapper; got `" & tally.opened & "`.")
  for id in tally.works_copy.keys:
    if id notin tally.ids:
      raise newException(ValueError, "Copy has no wrapper; got `" & id & "`.")
  for id in tally.entries_copy.values:
    if id notin tally.works_copy:
      raise newException(ValueError, "Trace holds no work of copy; got `" & id & "`.")
  for id in tally.ids:
    if id notin tally.works:
      raise newException(ValueError, "Trace holds no work of wrapper; got `" & id & "`.")
    var work = tally.works[id]
    if id in tally.works_copy:
      let copy = tally.works_copy[id]
      work.is_copy_apart = (copy.instructions, copy.bytes_read, copy.bytes_written) !=
          (work.instructions, work.bytes_read, work.bytes_written)
    result.add (id, work)


func nodeWork*(work: Work): JsonNode =
  ## Build work of one wrapper as object, one field per count or flag.
  %*{
    "instructions": work.instructions,
    "bytes_read": work.bytes_read,
    "bytes_written": work.bytes_written,
    "is_shared_reached": work.is_shared_reached,
    "is_copy_apart": work.is_copy_apart,
  }
