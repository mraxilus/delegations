## Build fixtures checker tests drive: synthetic trees, temporary git repositories.
##   Checker writes its own fixtures (Article IX.8): `treeGood` is smallest tree passing
##   every static check, so each negative test mutates one thing and names what broke.
##   It holds each project list of own prose names (`prose_own.nim`), as it holds each domain
##     `DOMAINS` names, since check of that list reports entry whose project tree lacks.
##
##   Cost: `treeGood` repeats layout rules as data; when layout grows, fixture grows with it,
##     and `taudit` proves they still agree.

{.experimental: "strictFuncs".}

import std/[json, os, osproc, strutils, tempfiles]
import ../../../knoller/src/knoller
import ../../src/[domains, kinds, layout, markdown, prose_own, provenance]


func entry*(path, content: string): Entry =
  ## Construct tree entry with kind classified from path.
  Entry(path: path, kind: path.classify, content: content)


func textProvenance*(stamp: string): string =
  ## Render minimal PROVENANCE.md header carrying stamp.
  "# Provenance\n\n| Field | Value |\n|---|---|\n| Harness | Test |\n| Author | Test |\n" &
    "| Date | 2026-01-01 |\n| Style | CONSTITUTION.md and STYLE.md, followed. |\n" &
    "| Rules | " & stamp & " |\n| Review | **Unreviewed.** |\n"


const  # TODO: Document.
  TEXT_GLOSSARY* = "# Fixture\n\nFixture glossary.\n\n## Standards\n\n## Language\n\n" &
    "**Term**:\nOne thing.\n"
    ## Minimal glossary passing shape check.
  PIN* = "2.2.4"
    ## Compiler version fixture projects pin, and driver version fixture workflow states.
  COMMIT* = "295bafc0d7e9a0c9a3ba0d9b39b5b0b6a4c1d2e3"
    ## Compiler commit, forty lowercase hex, standing where test pins commit, not version.
  TEXT_NIMBLE* = "# Package description; requirements live here.\n\nversion = \"0.1.0\"\n" &
    "srcDir = \"src\"\n\nrequires \"nim == " & PIN & "\"\n"
    ## Minimal nimble file pinning compiler exactly and requiring no package.
  TEXT_WORKFLOW* = "# Run checks.\nname: check\n\nenv:\n  NIM_VERSION: '" & PIN & "'\n"
    ## Minimal workflow stating driver version, which must equal `curator/audit` pin.
  TEXT_LOCK* = "{\n  \"items\": {\n    \"replications.example.invalid\": {\n" &
    "      \"dir\": \"$deps/replications.example.invalid\",\n" &
    "      \"commit\": \"0123456789abcdef\"\n    }\n  }\n}\n"
    ## Minimal Atlas lock naming one checkout directory.
  TEXT_RULES* = [
    "# Constitution\n\nRules.\n", "# Style\n\nSpelling.\n", "# Contributor\n\nDuties.\n",
    "# Examples\n\nCases.\n", "# Guide\n\nSteps.\n",
  ]
    ## Contents of rules documents in fixture tree, in `RULES` order.
  TEXT_PROCESS* = [
    "",
    "",
    "## Read first, in this order\n\nRead.\n\n## Every delegate begins here\n\nBegin.\n\n" &
      "## Carry the unchecked list in the open\n\nCarry.\n\n## Branch and commits\n\n" &
      "Branch.\n\n## Before you open a pull request\n\nCheck.\n",
    "",
    "## The queue and the shared allowance\n\nWait.\n\n## Work for subagents\n\nHand off.\n\n" &
      "## How to build on a project\n\nBuild.\n\n## Output contract\n\nSign off.\n",
  ]
    ## Sections of process that follow `TEXT_RULES` in each rules document of fixture tree, in
    ##   `RULES` order, one for each row of `SECTIONS_PROCESS`. Stamp leaves them out, so tree
    ##   stamps as `TEXT_RULES` alone; row added there without section here is finding of
    ##   good tree, which names its heading.
  TEXT_CURATOR* = "# Curator\n\nDuties.\n\n## Read first, in this order\n\nRead.\n"
    ## Curator prompt of fixture tree, holding reading order of role under its heading.
  DIRECTORY_ALPHA* = CONTRIBUTOR & "/ronri/alpha"  ## Contributor project in fixture tree.
  DIRECTORY_PARSER* = CONTRIBUTOR & "/bangu/ricysoho"
    ## Project list of own prose names, which fixture tree holds for that list's sake.
  DIRECTORY_TAGGER* = CONTRIBUTOR & "/bangu/rictadni"
    ## Project of same domain that list of own prose leaves out; fixture tree holds none of it.
  PROSE_LOJBAN* =
      "mi klama le zarci .i do klama le zdani .i le gerku cu viska le mlatu .i le mlatu\n" &
      "cu bajra .i mi tavla do le zarci .i do ciska lo xatra mi .i le xatra cu cmalu\n"
    ## Paragraph of record in lojban, 38 words: `.i` opens each sentence, and no stop closes one,
    ## so English check reads one sentence.
  DIRECTORY_AUDIT* = CURATOR & "/audit"  ## Curator project in fixture tree.
  BODY_EXAMPLE* =
      "**Role:** contributor/ronri/pga_benchmark\n\n" &
      "## What\n" &
      "This adds the change `maps-noalias`, which marks the operand of each map `noalias`. " &
      "The body of each map keeps its form, and the Proposals page gains the change.\n\n" &
      "- One edit to `defineOperator` in `pga/operators.nim` gives the operand of each " &
      "map the pragma `noalias`.\n" &
      "- The evaluation, `evaluations/maps-noalias.json`, is taken under Nim 2.4.0 at " &
      "rga4d and cga5d.\n" &
      "- The marginalia tab of Proposals gains the change. No other page changes.\n\n" &
      "## Why\n" &
      "Under Nim 2.4.0, each map writes its result in place while it reads its operand. " &
      "Where gcc cannot tell the result from the operand, it emits no vector instruction. " &
      "[The map-form decision (#783)](https://github.com/mraxilus/delegations/issues/783) " &
      "ruled for this mark over a change to the form of each map.\n\n" &
      "- Rejected: read first, `maps-read-first`, as that ruling says. It changes the " &
      "form of each map, and in loops it sets the order of loads and stores by hand.\n" &
      "- The gain shows where a routine takes a multivector through its parameters. In " &
      "a loop over arrays, gcc already sees the two apart.\n\n" &
      "## Evidence\n" &
      "The change cuts the instructions of 142 of 451 measured functions, and adds to " &
      "none. No timed function changes, and every result stays the same.\n\n" &
      "- `nim r koch check` at `f134e361`: 0 findings. Run 1530 of `check` is green.\n" &
      "- Machine counts under valgrind and gcc 13.3.0, on 2026-11-01: `reverse` at cga5d " &
      "falls from 87 instructions to 46, and `dual_weight` at cga5d from 83 to 66.\n" &
      "- The timed functions compare equal under `objdump`: 111 of 111 at rga4d, and " &
      "135 of 135 at cga5d.\n" &
      "- Results hold: where one multivector is both operand and result, Nim 2.4.0 copies " &
      "through a temporary. The suites pass, 33 of 33 at rga4d and 28 of 28 at cga5d.\n" &
      "- Published again: [Proposals](https://claude.ai/artifact/CW9ZL5eotsVYrZPjMnTLoG).\n\n" &
      "<details><summary>Worked example: the machine counts, at pin and with the " &
      "change</summary>\n\n" &
      "Each cell counts the instructions of one call.\n\n" &
      "| Figure | Pin | `noalias` |\n" &
      "|--------|----:|----------:|\n" &
      "| Measurands with fewer instructions, of 451 | | 142 |\n" &
      "| Measurands with more instructions, of 451 | | 0 |\n" &
      "| `reverse` at rga4d | 45 | 27 |\n" &
      "| `reverse` at cga5d | 87 | 46 |\n" &
      "| `dual_weight` at cga5d | 83 | 66 |\n" &
      "| `complement_left` at cga5d | 87 | 63 |\n\n" &
      "- The cases that hold the promise: `a = ☆a`, `p[] = ☆q[]` with two pointers to " &
      "one multivector, `x = \\y` with one multivector as both, and `s[1] = ☆s[1]`.\n" &
      "- The time ratios run ×0.94 to ×1.04 at rga4d and ×0.82 to ×1.11 at cga5d, on " &
      "code that does not change. The spread of the pages stays ×0.85 to ×1.10, now over " &
      "3 403 ratios in place of 3 157.\n" &
      "- The evaluation ran on a core of family 6, model 207. The machine counts and " &
      "the timed functions were read on model 85. Neither depends on the core, since " &
      "gcc builds them without `-march`.\n\n" &
      "</details>\n\n" &
      "## Next steps\n" &
      "Nothing remains on this branch. After the merge, the change waits on the Architect, " &
      "who decides whether the library takes it.\n\n" &
      "- Closes #783, the map-form decision, when this merges.\n" &
      "- The library takes `maps-noalias` only when the Architect applies it there, as " &
      "with each change on the marginalia tab.\n"
    ## Body #845 gives as example of form, applied to #790, byte for byte as Architect wrote it.


func tableHeader*(source: string): seq[seq[string]] =
  ## Read pipe table of module header, i.e. `##   |` lines with prefix cut, heading row first.
  ##   Suites read it from `staticRead` source, so table is checked against declarations it
  ##   describes (Article I.4) without src exporting reader nothing else needs.
  var table: string
  for line in source.splitLines:
    if line.startsWith("##   |"): table.add line["##   ".len .. ^1] & "\n"
  table.rowsTable


func textReadme*(): string =
  ## Render root README.md holding domain table derived from `DOMAINS`.
  result = "# Fixture\n\n| Folder | Name | Theme |\n|---|---|---|\n"
  for d in DOMAINS: result.add "| " & d.folder & " | " & d.name & " | " & d.theme & " |\n"


func bodyPull*(line_role: string): string =
  ## Render pull request body below role line in form of template, i.e. four sections, each
  ##   opening with summary of one sentence, and one point.
  line_role & "\n\n## What\n\nThis adds one check.\n\n- One point.\n\n## Why\n\n" &
    "Each role is typed twice.\n\n## Evidence\n\nThe suites pass.\n\n## Next steps\n\n" &
    "Nothing remains.\n"


func entriesProject*(directory: string, stamp: string): seq[Entry] =
  ## Build entries of one complete project directory.
  @[
    entry(directory & "/README.md", "# Project\n\nPurpose.\n"),
    entry(directory & "/PROVENANCE.md", textProvenance(stamp)),
    entry(directory & "/GLOSSARY.md", TEXT_GLOSSARY),
    entry(directory & "/" & directory.nameProject & EXTENSIONS[Dialect.Package], TEXT_NIMBLE),
    entry(
      directory & "/tests/tall.nim",
      "## Test everything.\n\n" & STRICT_FUNCS & "\n\ndiscard\n",
    ),
  ]


func treeGood*(): Tree =
  ## Build smallest tree passing every static check, with projects in both roots.
  let stamp_now = stamp(TEXT_RULES)
  result = @[
    entry("README.md", textReadme()),
    entry("LICENSE.md", "# Licence\n\nText.\n"),
    entry("AGENTS.md", "# Entry\n\nRead file of role.\n"),
    entry("CLAUDE.md", "# Claude Code\n\nImport entry file.\n\n@AGENTS.md\n"),
    entry(
      "GLOSSARY.md",
      "# Fixture\n\nWords.\n\n## Standards\n\n## Language\n\n**Term**:\nOne thing.\n",
    ),
    entry("CURATOR.md", TEXT_CURATOR),
    entry("koch.nim", "## Drive checks.\n\n" & STRICT_FUNCS & "\n\ndiscard\n"),
    entry("koch.nim.cfg", "# Flags for koch.\nhints:off\n"),
    entry(".gitignore", "# Build products.\nbin/\n"),
    entry(".gitattributes", "# Endings.\n* text=auto eol=lf\n"),
    entry(".github/workflows/check.yml", TEXT_WORKFLOW),
  ]
  for k, rule in RULES: result.add entry(rule, TEXT_RULES[k] & TEXT_PROCESS[k])
  for root in ROOTS: result.add entry(root & "/README.md", "# " & root & "\n\nProjects.\n")
  for d in DOMAINS:
    result.add entry(
      CONTRIBUTOR & "/" & d.folder & "/README.md",
      "# " & d.name & "\n\n" & d.theme & "\n",
    )
  result.add entriesProject(DIRECTORY_AUDIT, stamp_now)
  result.add entriesProject(DIRECTORY_ALPHA, stamp_now)
  for p in PROJECTS_PROSE_OWN:
    result.add entriesProject(p.directory, stamp_now)
    if p.should_demand_suite:
      result.add entry(p.directory & "/" & p.suite, "## Hold prose.\n\n" & STRICT_FUNCS & "\n")


func with*(tree: Tree, entries: varargs[Entry]): Tree =
  ## Copy tree plus entries, for fixture holding file good tree has none of.
  result = tree
  for e in entries: result.add e


func without*(tree: Tree, path: string): Tree =
  ## Copy tree minus entry at path.
  for e in tree:
    if e.path != path: result.add e


func replaced*(tree: Tree; path, content: string): Tree =
  ## Copy tree with entry at path carrying new content.
  for e in tree:
    result.add (if e.path == path: entry(path, content) else: e)


proc git*(root: string, arguments: string): string =
  ## Run git in root with fixed identity; raise on failure, return stdout.
  let command = "git -C " & root.quoteShell &
    " -c user.name=Test -c user.email=test@example.invalid -c commit.gpgsign=false " & arguments
  let (output, code) = execCmdEx(command)
  doAssert code == 0, "git failed; got `" & output & "`."
  output


proc writeInto*(root, path, content: string) =
  ## Write file under root, creating directories.
  createDir(root / path.parentDir)
  writeFile(root / path, content)


func bits*(value: float): uint64 =
  ## Bits of float, so that compare holds to last bit, and `-0.0` stands apart from `0.0`.
  cast[uint64](value)


proc repoTemp*(): string =
  ## Create temporary git repository on branch `main` with one empty commit.
  result = createTempDir("delegations_", "_fixture")
  discard result.git("init -q -b main")
  discard result.git("commit -q --allow-empty -m 'chore(curator): init'")


proc lockWith*(nimble: string): string =
  ## Render lock storing copy of nimble text, as Atlas writes one on `atlas pin`.
  ##   Lines are split on newline rather than by `splitLines`, so joining them reproduces
  ##   original text exactly, trailing newline included.
  var lines = newJArray()
  for line in nimble.split('\n'): lines.add %line
  pretty(
    %*{
      "items": newJObject(),
      "nimbleFile": {"filename": "probe" & EXTENSIONS[Dialect.Package], "content": lines},
    },
  ) & "\n"


func bigEndian16(value: int): string =
  ## Render `value` as big-endian `uint16`, as OpenType stores every integer.
  $chr((value shr 8) and 0xFF) & $chr(value and 0xFF)


func bigEndian32(value: int): string =
  ## Render `value` as big-endian `uint32`.
  bigEndian16((value shr 16) and 0xFFFF) & bigEndian16(value and 0xFFFF)


func subtableFormat12*(runs: openArray[(Slice[int], int)]): string =
  ## Render `cmap` subtable of format 12: each run of codepoints onto run of glyphs from its own.
  result = bigEndian16(12) & bigEndian16(0) & bigEndian32(16 + 12 * runs.len) & bigEndian32(0) &
    bigEndian32(runs.len)
  for (codepoints, glyph) in runs:
    result.add bigEndian32(codepoints.a) & bigEndian32(codepoints.b) & bigEndian32(glyph)


func subtableFormat4*(runs: openArray[(Slice[int], int)]): string =
  ## Render `cmap` subtable of format 4: each run of codepoints in first plane onto run of glyphs
  ##   from its own, through delta, then closing segment at `ffff` that maps nothing.
  var ends, starts, deltas, offsets: string
  for (codepoints, glyph) in runs:
    ends.add bigEndian16(codepoints.b)
    starts.add bigEndian16(codepoints.a)
    deltas.add bigEndian16((glyph - codepoints.a) and 0xFFFF)
    offsets.add bigEndian16(0)
  ends.add bigEndian16(0xFFFF)
  starts.add bigEndian16(0xFFFF)
  deltas.add bigEndian16(1)
  offsets.add bigEndian16(0)
  let count = runs.len + 1
  bigEndian16(4) & bigEndian16(16 + 8 * count) & bigEndian16(0) & bigEndian16(2 * count) &
    bigEndian16(0).repeat(3) & ends & bigEndian16(0) & starts & deltas & offsets


func tableCmap*(subtables: openArray[(int, int, string)]): string =
  ## Render `cmap` table: each subtable under its platform and encoding, in order given.
  result = bigEndian16(0) & bigEndian16(subtables.len)
  var
    offset = 4 + 8 * subtables.len
    body = ""
  for (platform, encoding, subtable) in subtables:
    result.add bigEndian16(platform) & bigEndian16(encoding) & bigEndian32(offset)
    offset += subtable.len
    body.add subtable
  result.add body


func fileFontFace*(tables: openArray[(string, string)]): string =
  ## Render TrueType file holding each table under its tag, as OpenType's table directory lays out.
  result = bigEndian32(0x00010000) & bigEndian16(tables.len) & bigEndian16(0).repeat(3)
  var
    offset = 12 + 16 * tables.len
    body = ""
  for (tag, table) in tables:
    result.add tag & bigEndian32(0) & bigEndian32(offset) & bigEndian32(table.len)
    offset += table.len
    body.add table
  result.add body


func fileFontFace*(codepoints: openArray[Slice[int]]): string =
  ## Render TrueType file mapping each run of codepoints to glyphs from `1`, through one Unicode
  ##   subtable of format 12, as font face of store maps them.
  var
    runs: seq[(Slice[int], int)]
    glyph = 1
  for run in codepoints:
    runs.add (run, glyph)
    glyph += run.len
  fileFontFace([("cmap", tableCmap([(3, 10, subtableFormat12(runs))]))])
