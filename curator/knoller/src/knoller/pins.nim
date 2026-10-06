## Read compiler pin nimble file names: exact version, or exact commit of compiler itself.
##   Pin sits beside package requirements as `requires "nim == <pin>"`, so one scan of
##   `requires` literals reads both (`requireLiterals`); `curator/audit` reads package
##   requirements through same scan.
##   Pin is exact for reason `atlas.lock` is exact: it records compiler code was verified on.
##     Range, label such as `devel`, and short commit read as no pin, since none names one
##     compiler.
##   Commit is full forty lowercase hex characters, as `atlas.lock` records commits. Nimble also
##     writes commit as `nim#<commit>`, so pin reads that form too; `#` of branch or tag, such as
##     `nim#devel`, moves, and reads as no pin.
##   Policy of one form is caller's: `curator/audit` demands `nim == <pin>` (CURATOR.md duty 8),
##     and reads what follows `nim` through `requirementNim`.
##
##   Cost: parser reads `requires` lines only; `when` branches count as unconditional, and every
##     literal on line is taken.

{.experimental: "strictFuncs".}

import std/[options, strutils]


const
  NIM* = "nim"  ## Requirement name pin carries, and name of compiler in its `bin`.
  EXACT* = "=="  ## Operator exact pin uses; ranges are rejected.
  MARK_COMMIT = "#"  ## Mark opening commit nimble names after package, as `nim#<commit>`.
  CHARS_VERSION = Digits + {'.'}  ## Characters version string is built from.
  CHARS_COMMIT = {'0'..'9', 'a'..'f'}  ## Characters commit pin is built from; lowercase hex only.
  COMMIT_LEN* = 40  ## Length of full git commit, which is what pin carries.
  NAME_END = {' ', '#', '@', '>', '<', '=', '~', '^'}
    ## Characters ending package name inside requirement.


func isVersion*(s: string): bool =
  ## Decide whether `s` is dotted version, i.e. digit runs separated by single dots.
  if s.len == 0 or not s.allCharsInSet(CHARS_VERSION): return false
  for part in s.split('.'):
    if part.len == 0: return false
  true


func isCommit*(s: string): bool =
  ## Decide whether `s` is full lowercase git commit.
  s.len == COMMIT_LEN and s.allCharsInSet(CHARS_COMMIT)


func isPin*(s: string): bool =
  ## Decide whether `s` names compiler exactly, as commit or as version.
  ##   Commit is tested first: forty digits would satisfy both, and absurd version loses.
  s.isCommit or s.isVersion


func namePackage*(requirement: string): string =
  ## Read package name from requirement, i.e. text before version, hash or space.
  for i, c in requirement:
    if c in NAME_END: return requirement[0..<i]
  requirement


func requireLiterals*(nimble: string): seq[string] =
  ## Collect every string literal on `requires` lines, compiler pin included.
  for line in nimble.splitLines:
    let s = line.strip
    if not s.startsWith("requires"): continue
    let rest = s[8 .. ^1]

    # Take every string literal on line.
    var i = 0
    while i < rest.len:
      if rest[i] != '"':
        inc i
        continue
      let close = rest.find('"', i + 1)
      if close < 0: break
      result.add rest[i+1..<close]
      i = close + 1


func requirementNim*(nimble: string): Option[string] =
  ## Read what follows `nim` in first requirement of compiler nimble text names, e.g. `== 2.2.12`;
  ##   `none` where it names none.
  for requirement in nimble.requireLiterals:
    if requirement.namePackage.toLowerAscii != NIM: continue
    return some(requirement[requirement.namePackage.len .. ^1].strip)
  none(string)


func pinNim*(nimble: string): Option[string] =
  ## Read exact Nim pin of nimble text, as `nim == <pin>` or `nim#<commit>`; `none` when absent
  ##   or inexact.
  let rest = nimble.requirementNim.get("")
  if rest.startsWith(EXACT):
    let pin = rest[EXACT.len .. ^1].strip
    if pin.isPin: return some(pin)
  elif rest.startsWith(MARK_COMMIT):
    let commit = rest[MARK_COMMIT.len .. ^1].strip
    if commit.isCommit: return some(commit)
  none(string)
