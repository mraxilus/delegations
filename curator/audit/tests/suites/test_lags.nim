## Replicate notice of `lags.nim`: each commit of lock naming folder of this repository, against
##   base, as D2 of #927 rules it.

{.experimental: "strictFuncs".}

import std/[options, os, sequtils, strutils, unittest]
import ../../src/lags
import ./fixtures


const
  LOCK = "curator/assayer/atlas.lock"  ## Lock that names knoller, as assayer holds it.
  COMMIT_KNOLLER = "11403468a97c0d3ae922182d894606e2688504e9"  ## Commit assayer locks, at #899.
  COMMIT_OTHER = "29c11c7264289cc4c423f0e0662effbc5fdc6f61"  ## Commit of package of no folder.
  COMMIT_LACKED = "0123456789abcdef0123456789abcdef01234567"  ## Commit no repository holds.
  PARSER = "contributor/bangu/lojban_parser"  ## Folder lojban_tagger locks.


func textLock(items: openArray[(string, string, string)]): string =
  ## Render lock holding items, each as name, address and commit, as Atlas writes them.
  var parts: seq[string]
  for (name, url, commit) in items:
    parts.add "    \"" & name & "\": {\n      \"dir\": \"$deps/" & name & "\",\n" &
      "      \"url\": \"" & url & "\",\n      \"commit\": \"" & commit & "\",\n" &
      "      \"version\": \"\"\n    }"
  "{\n  \"items\": {\n" & parts.join(",\n") & "\n  }\n}\n"



suite "Items":
  test "item names folder of this repository where its address, query cut, is this one":
    # Case: assayer locks knoller, and lojban_tagger locks lojban_parser, each through name
    #   override with `?subdir=`, which Atlas writes percent-encoded (`atlas.config`). Domain:
    #   address of this repository with folder, without folder, of other repository with folder,
    #   package of no folder, and lock that will not parse.
    let lock = textLock([
      ("knoller", ADDRESS_REPOSITORY & "?subdir=curator%2Fknoller", COMMIT_KNOLLER),
      ("nim-stew", "https://github.com/status-im/nim-stew", COMMIT_OTHER),
      ("whole", ADDRESS_REPOSITORY, COMMIT_KNOLLER),
      ("other", "https://github.com/o/r?subdir=curator%2Fknoller", COMMIT_KNOLLER),
      ("plain", ADDRESS_REPOSITORY & ".git/?subdir=" & PARSER, COMMIT_KNOLLER),
    ])
    check itemsRepository(LOCK, lock) == @[
      Locked(lock: LOCK, name: "knoller", folder: "curator/knoller", commit: COMMIT_KNOLLER),
      Locked(lock: LOCK, name: "plain", folder: PARSER, commit: COMMIT_KNOLLER),
    ]  # address without folder names no folder; other repository is no item of this one
    check itemsRepository(LOCK, "not json at all").len == 0  # `checkNimbleLock` reports it
    check itemsRepository(LOCK, "{}").len == 0  # lock of no items



suite "Notice":
  test "notice names count, folder gone and commit git lacks, and nothing where folder holds still":
    let
      knoller =
        Locked(lock: LOCK, name: "knoller", folder: "curator/knoller", commit: COMMIT_KNOLLER)
      lags = [
        Lag(locked: knoller, count: some(5), is_held: true),
        Lag(locked: knoller, count: some(1), is_held: true),
        Lag(locked: knoller, count: some(0), is_held: true),
        Lag(locked: knoller, count: some(2), is_held: false, gone: some("72a00713c")),
        Lag(locked: knoller, count: none(int), is_held: false),
        Lag(locked: knoller, count: none(int), is_held: true),
      ]
      lines = noticesLag(lags, "origin/main")
    check lines.len == 6  # heading, then each item that lags; folder that holds still is silent
    check lines[0].startsWith("Commits of `atlas.lock` ") and "fail nothing" in lines[0]
    check lines[1 .. ^1] == @[
      "  " & LOCK & ": `knoller` at `11403468a` lags `origin/main` by 5 commits that change " &
        "`curator/knoller`.",
      "  " & LOCK & ": `knoller` at `11403468a` lags `origin/main` by 1 commit that changes " &
        "`curator/knoller`.",
      "  " & LOCK & ": `knoller` at `11403468a` names `curator/knoller`, which `origin/main` " &
        "no longer holds: it moved or went at `72a00713c`.",
      "  " & LOCK & ": `knoller` at `11403468a` names `curator/knoller`, which `origin/main` " &
        "no longer holds: it moved or went, at commit git cannot name.",
      "  " & LOCK & ": `knoller` at `11403468a` names commit git lacks, so its lag behind " &
        "`origin/main` is unread.",
    ]
    check noticesLag([lags[2]], "origin/main").len == 0  # nothing lags, so no heading either



suite "Lag":
  test "lag counts commits of base that changed folder since commit of lock (D2 of #927)":
    # Real git on throwaway repository. Domain: change to folder, change elsewhere, folder moved
    #   by commit that git names, and commit of lock that git lacks.
    let root = repoTemp()
    defer: removeDir(root)
    root.writeInto("curator/knoller/src/knoller.nim", "discard\n")
    discard root.git("add -A")
    discard root.git("commit -q -m 'feat(knoller): open'")
    let locked = root.git("rev-parse HEAD").strip
    root.writeInto(LOCK, textLock([
      ("knoller", ADDRESS_REPOSITORY & "?subdir=curator%2Fknoller", locked),
      ("lost", ADDRESS_REPOSITORY & "?subdir=curator%2Fknoller", COMMIT_LACKED),
    ]))
    discard root.git("add -A")
    discard root.git("commit -q -m 'build(assayer): lock knoller'")
    check readLags(root, "main").mapIt((it.locked.name, it.count, it.is_held)) ==
      @[("knoller", some(0), true), ("lost", none(int), true)]  # change outside folder counts none
    root.writeInto("curator/knoller/src/knoller.nim", "discard 1\n")
    discard root.git("commit -q -a -m 'fix(knoller): change'")
    root.writeInto("curator/knoller/src/knoller.nim", "discard 2\n")
    discard root.git("commit -q -a -m 'fix(knoller): change again'")
    check readLags(root, "main")[0].count == some(2)
    discard root.git("mv curator/knoller curator/kneader")
    discard root.git("commit -q -m 'refactor(curator): move knoller'")
    let
      moved = root.git("rev-parse --short HEAD").strip
      gone = readLags(root, "main")[0]
    check not gone.is_held
    check gone.gone == some(moved)  # commit of base that moved folder
