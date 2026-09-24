## Build fixtures checker tests drive: synthetic trees, temporary git repositories.
##   Checker writes its own fixtures (Article IX.8): `goodTree` is smallest tree passing
##   every static check, so each negative test mutates one thing and names what broke.
##
##   Cost: `goodTree` repeats layout rules as data; when layout grows, fixture grows with it,
##     and `taudit` proves they still agree.

import std/[json, os, osproc, strutils, tempfiles]
import ../src/[domains, kinds, layout, provenance, dependencies]


func entry*(path, content: string): Entry =
  ## Construct tree entry with kind classified from path.
  Entry(path: path, kind: path.kindOf, content: content)


func provenanceText*(stamp: string): string =
  ## Render minimal PROVENANCE.md header carrying stamp.
  "# Provenance\n\n| Field | Value |\n|---|---|\n| Harness | Test |\n| Author | Test |\n" &
    "| Date | 2026-01-01 |\n| Style | CONSTITUTION.md and STYLE.md, followed. |\n" &
    "| Rules | " & stamp & " |\n| Review | **Unreviewed.** |\n"


const
  GLOSSARY_TEXT* = "# Fixture\n\nFixture glossary.\n\n## Language\n\n**Term**:\nOne thing.\n"
    ## Minimal glossary passing shape check.
  PIN* = "2.2.4"
    ## Compiler version fixture projects pin, and driver version fixture workflow states.
  NIMBLE_TEXT* = "# Package description; requirements live here.\n\nversion = \"0.1.0\"\n" &
    "srcDir = \"src\"\n\nrequires \"nim == " & PIN & "\"\n"
    ## Minimal nimble file pinning compiler exactly and requiring no package.
  WORKFLOW_TEXT* = "# Run checks.\nname: check\n\nenv:\n  NIM_VERSION: '" & PIN & "'\n"
    ## Minimal workflow stating driver version, which must equal `curator/audit` pin.
  LOCK_TEXT* = "{\n  \"items\": {\n    \"replications.example.invalid\": {\n" &
    "      \"dir\": \"$deps/replications.example.invalid\",\n" &
    "      \"commit\": \"0123456789abcdef\"\n    }\n  }\n}\n"
    ## Minimal Atlas lock naming one checkout directory.
  RULES_TEXT* = [
    "# Constitution\n\nRules.\n", "# Style\n\nSpelling.\n", "# Contributor\n\nDuties.\n",
  ]
    ## Contents of rules documents in fixture tree, in `RULES` order.
  ALPHA_DIR* = CONTRIBUTOR & "/ronri/alpha"
    ## Contributor project in fixture tree.
  AUDIT_DIR* = CURATOR & "/audit"
    ## Curator project in fixture tree.


func readmeText*(): string =
  ## Render root README.md holding domain table derived from `DOMAINS`.
  result = "# Fixture\n\n| Folder | Name | Theme |\n|---|---|---|\n"
  for d in DOMAINS: result.add "| " & d.folder & " | " & d.name & " | " & d.theme & " |\n"


func projectEntries*(dir: string, stamp: string): seq[Entry] =
  ## Build entries of one complete project directory.
  @[
    entry(dir & "/README.md", "# Project\n\nPurpose.\n"),
    entry(dir & "/PROVENANCE.md", provenanceText(stamp)),
    entry(dir & "/GLOSSARY.md", GLOSSARY_TEXT),
    entry(dir & "/" & dir.projectName & NIMBLE_EXT, NIMBLE_TEXT),
    entry(dir & "/tests/tall.nim", "## Test everything.\n\ndiscard\n"),
  ]


func goodTree*(): Tree =
  ## Build smallest tree passing every static check, with projects in both roots.
  let stamp_now = stamp(RULES_TEXT)
  result = @[
    entry("README.md", readmeText()),
    entry("LICENSE.md", "# Licence\n\nText.\n"),
    entry("CLAUDE.md", "# Claude\n\nRead rules.\n"),
    entry("GLOSSARY.md", "# Fixture\n\nWords.\n\n## Language\n\n**Term**:\nOne thing.\n"),
    entry("CURATOR.md", "# Curator\n\nDuties.\n"),
    entry("koch.nim", "## Drive checks.\n\ndiscard\n"),
    entry("koch.nim.cfg", "# Flags for koch.\nhints:off\n"),
    entry(".gitignore", "# Build products.\nbin/\n"),
    entry(".gitattributes", "# Endings.\n* text=auto eol=lf\n"),
    entry(".github/workflows/check.yml", WORKFLOW_TEXT),
  ]
  for k, rule in RULES: result.add entry(rule, RULES_TEXT[k])
  for root in ROOTS: result.add entry(root & "/README.md", "# " & root & "\n\nProjects.\n")
  for d in DOMAINS:
    result.add entry(
      CONTRIBUTOR & "/" & d.folder & "/README.md", "# " & d.name & "\n\n" & d.theme & "\n"
    )
  result.add projectEntries(AUDIT_DIR, stamp_now)
  result.add projectEntries(ALPHA_DIR, stamp_now)


func with*(tree: Tree, entries: varargs[Entry]): Tree =
  ## Copy tree plus entries, for fixture holding file good tree has none of.
  result = tree
  for e in entries: result.add e


func without*(tree: Tree, path: string): Tree =
  ## Copy tree minus entry at path.
  for e in tree:
    if e.path != path: result.add e


func replaced*(tree: Tree, path, content: string): Tree =
  ## Copy tree with entry at path carrying new content.
  for e in tree:
    result.add (if e.path == path: entry(path, content) else: e)


proc git*(root: string, args: string): string =
  ## Run git in root with fixed identity; raise on failure, return stdout.
  let command = "git -C " & root.quoteShell &
    " -c user.name=Test -c user.email=test@example.invalid -c commit.gpgsign=false " & args
  let (output, code) = execCmdEx(command)
  doAssert code == 0, "git failed; got `" & output & "`."
  output


proc writeInto*(root, path, content: string) =
  ## Write file under root, creating directories.
  createDir(root / path.parentDir)
  writeFile(root / path, content)


proc tempRepo*(): string =
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
  pretty(%*{
    "items": newJObject(),
    "nimbleFile": {"filename": "probe" & NIMBLE_EXT, "content": lines},
  }) & "\n"
