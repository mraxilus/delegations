## Replicate shared store of `assets.nim` header, i.e. one declaration, keyed by digest.
##   Codepoints each font face row carries are held to bytes of its file, read through
##     `font_files.nim` as browser reads them, i.e. codepoint maps to glyph other than `.notdef`.
##     Static pass reads rows and never bytes, so suite alone reads bytes of store.
##   Cost: test fetches each font face store lacks, so cold store needs network and about 6 MB.
##   Fetch itself is held on `file://` addresses, which curl reads with no network; cause and
##     line of fetch that fails are held on text curl printed, and on fake `curl` first on
##     `PATH`, which fails as curl does with no network or server, and skips where it cannot run.

{.experimental: "strictFuncs".}

import std/[os, osproc, sequtils, strutils, tempfiles, unittest]
import ../../src/[assets, findings, font_files]
from ../../../knoller/src/knoller import DIRECTORY_CACHE


const  # TODO: Document.
  DIGEST_ABC = "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
    ## SHA-256 of `abc`, i.e. FIPS 180-2 Appendix B.1.
  DIGEST_EMPTY = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
    ## SHA-256 of no bytes, which empty answer of server carries.
  CAUSE_RESOLVE = "curl: (6) Could not resolve host: cdn.jsdelivr.net"
    ## What curl 8.5.0 prints for fetch of store with network cut, 2026-11-17.
  TEXT_CURL_60 =
      "curl: (60) SSL certificate problem: self-signed certificate\n" &
      "More details here: https://curl.se/docs/sslcerts.html\n" &
      "\n" &
      "curl failed to verify the legitimacy of the server and therefore could not\n" &
      "establish a secure connection to it. To learn more about this situation and\n" &
      "how to fix it, please visit the web page mentioned above.\n"
    ## What curl 8.5.0 prints for error 60 under `-sS`: six lines, one blank.
    ##   Read off `openssl s_server` serving certificate no authority signed, 2026-11-17.


func toSlices(codepoints: seq[int]): seq[Slice[int]] =
  ## Merge sorted codepoints into runs, one slice each.
  for codepoint in codepoints:
    if result.len > 0 and result[^1].b + 1 == codepoint: result[^1].b = codepoint
    else: result.add codepoint .. codepoint


func toText(ranges: seq[Slice[int]]): string =
  ## Render ranges as row spells them: lowercase hex, `low-high` or lone `low`, space apart.

  func toHexLower(codepoint: int): string =
    ## Render codepoint in lowercase hex, no leading zero.
    codepoint.toHex.strip(trailing = false, chars = {'0'}).toLowerAscii

  var tokens: seq[string]
  for bounds in ranges:
    tokens.add(
      if bounds.a == bounds.b: bounds.a.toHexLower
      else: bounds.a.toHexLower & "-" & bounds.b.toHexLower
    )
  tokens.join(" ")


template withCurl(bin, script: string, body: untyped) =
  ## Run body with fake `curl` first on `PATH`: script under `sh`, which fetches nothing.
  ##   So fetch that fails is held as curl fails, with no network.
  ##   Fake answers `--probe` by its full path first, so test skips where it cannot run.
  createDir(bin)
  writeFile(bin / "curl", "#!/bin/sh\n[ \"$1\" = --probe ] && exit 0\n" & script & "\n")
  setFilePermissions(bin / "curl", {fpUserRead, fpUserWrite, fpUserExec})
  if execCmdEx(quoteShellCommand([bin / "curl", "--probe"])).exitCode != 0:
    # Gap: directory mounted `noexec` runs no fake, and shell would reach real curl and
    #   network, so fake fetch is held where directory runs it (Article IX.9).
    skip()
  else:
    let found = getEnv("PATH")
    putEnv("PATH", bin & PathSep & found)
    try: body
    finally: putEnv("PATH", found)



suite "Assets":
  test "store lies outside repository, and override wins":
    check rootStore("/tmp/assets") == "/tmp/assets"
    check rootStore("").endsWith(DIRECTORY_ASSETS)
    # Audit reads untracked files, so store inside checkout would be audited.
    check not rootStore("").startsWith(".")
    check DIRECTORY_ASSETS.parentDir == ".cache/koch"  # store is koch's own
    check DIRECTORY_CACHE.parentDir == ".cache/knoller"  # compiler cache is knoller's, koch uses it


  test "asset is stored under its digest, never under its name":
    # Two projects asking for one font face share one entry by construction, and moved pin is
    #   different entry rather than stale one.
    const font_face = "NotoSans-Regular.ttf"
    let digest = font_face.digestDeclared
    check pathStore("/s", font_face) == "/s" / digest
    check font_face notin pathStore("/s", font_face)  # name is nowhere in path
    check pathStore("/s", "not-a-font-face.woff2").len == 0  # undeclared font face has no path


  test "address carries version, so bytes and version move together or neither":
    const font_face = "commit-mono-latin-700-normal.woff2"
    let address = font_face.address
    check address.startsWith("https://")
    check address.endsWith(font_face)
    check "@fontsource/commit-mono@" in address  # package and its version, in address
    check address("not-a-font-face.woff2").len == 0


  test "TrueType comes from Noto's own repository, since fontsource ships none":
    # Atlas reads TrueType and `@fontsource` packages `woff2` alone, so desktop font faces have
    #   their own upstream; store holds both rather than one project holding each.
    check "notofonts" in "NotoSans-Regular.ttf".address
    check "notofonts" in "NotoSansMath-Regular.ttf".address
    check "commit-mono" in "CommitMonoV142-400Regular.otf".address  # its author's own
    check "fontsource" in "commit-mono-latin-400-normal.woff2".address


  test "every row is one file, one address and one digest of sixty-four hex digits":
    var files: seq[string]
    for (file, prefix, digest, _) in ASSETS:
      check file.len > 0
      check file notin files  # nothing declared twice, which is what store exists to stop
      files.add file
      check prefix.startsWith("https://")
      check prefix.endsWith("/")  # prefix is directory; file is appended to it
      check digest.len == 64
      for c in digest: check c in {'0' .. '9', 'a' .. 'f'}


  test "store holds what projects share, once, and what one project alone wants":
    # Projects wanting one font face share its row, so one digest serves each of them, which is
    #   Article II.9's own test. These five are what every page project draws.
    for file in [
      "commit-mono-latin-400-normal.woff2", "NotoSans-Regular.ttf", "NotoSans-SemiBold.ttf",
      "NotoSansMath-Regular.ttf", "NotoSerif-SemiBold.ttf",
    ]:
      check file.digestDeclared.len == 64
    # And what only one of them wants, so none loses font face by sharing one table.
    check "NotoSerif-Italic.ttf".digestDeclared.len == 64  # dance_ontology alone
    check "CommitMonoV142-400Regular.otf".digestDeclared.len == 64  # pga_visualiser alone


  test "each Noto font face a page draws is declared whole (Article X.8)":
    # Noto was chosen so that no character of page falls outside its font faces, and subset undoes
    #   that; so every Noto font face pages draw has its whole TrueType file here.
    for file in [
      "NotoSans-Regular.ttf", "NotoSans-SemiBold.ttf", "NotoSansMath-Regular.ttf",
      "NotoSansSymbols2-Regular.ttf", "NotoSerif-Italic.ttf", "NotoSerif-Regular.ttf",
      "NotoSerif-SemiBold.ttf",
    ]:
      check file.digestDeclared.len == 64


  test "no row declares Noto subset, while Commit Mono keeps its own (Article X.8)":
    # Store declaring no Noto subset is what stops page shipping one: `fetch-assets` refuses
    #   any file no row declares. Commit Mono is no Noto, and pages draw its Latin subset.
    for (file, prefix, _, _) in ASSETS:
      if file.toLowerAscii.startsWith("noto"):
        check file.endsWith(".ttf")  # whole TrueType, never `woff2` subset (Article X.8)
        check "notofonts" in prefix  # Noto's own release, never `@fontsource` (Article X.8)
    for file in ["commit-mono-latin-400-normal.woff2", "commit-mono-latin-700-normal.woff2"]:
      check file.digestDeclared.len == 64  # X.8 binds Noto alone (Article X.8)


  test "archive takes name carrying its version, and is fetched from whole address of release":
    # Each release of headless shell keeps one upstream file name, so name store gives archive
    #   carries version, and its address is whole rather than prefix plus name (issue 864).
    const archive = "chrome-headless-shell-linux64-153.0.8010.12.zip"
    check archive.digestDeclared ==
      "a9da028861a0cf789ff25c2fed45f5f1aaf969ed9247835b6a7821a4f7af9d1d"
    check archive.address == "https://storage.googleapis.com/chrome-for-testing-public/" &
      "153.0.8010.12/linux64/chrome-headless-shell-linux64.zip"
    check pathStore("/s", archive) == "/s" / archive.digestDeclared  # keyed by digest too
    check archive & " " & archive.digestDeclared & "\n" in declaration()  # published row


  test "every archive row is one name, one whole address and one digest, apart from font faces":
    # Archive maps no codepoints, so it takes table of its own, and font face checks never
    #   read it; one name still means one file across both tables.
    var names: seq[string]
    for (file, _, _, _) in ASSETS: names.add file
    for (file, whole, digest) in ARCHIVES:
      check file notin names  # nothing declared twice, in either table
      names.add file
      check whole.startsWith("https://")
      check not whole.endsWith("/")  # whole address of one file, never prefix
      check digest.len == 64
      for c in digest: check c in {'0' .. '9', 'a' .. 'f'}


  test "asset nobody declared is finding naming what was asked for":
    let found = unknown("fraunces-latin-400-normal.woff2")
    check found.len == 1
    check found[0].brief.endsWith(
      "got `fraunces-latin-400-normal.woff2`; help: add row naming its address and digest, or " &
        "ask for one it declares",
    )
    check found.anyIt(it.rule == "koch.unknown-asset")
    check "assets.nim" in found[0].path  # names table to add row to


  test "asset declared that store could not fetch or check is finding naming what was asked for":
    check unfetched("fraunces-latin-400-normal.woff2").mapIt((it.rule, it.brief)) == @[(
      "koch.asset-fetch",
      "asset is declared but could not be fetched or checked; got " &
        "`fraunces-latin-400-normal.woff2`",
    )]


  test "declaration publishes every row, so no consumer parses this source":
    # Project holding law that its font faces are declared reads these rows, never `assets.nim`
    #   as text: published rows are contract such read stands in for.
    let rows = declaration().strip.splitLines
    check rows.len == ASSETS.len + ARCHIVES.len  # every row of both tables, none extra
    for row in rows:
      let parts = row.split(' ')
      check parts.len == 2  # neither column holds space, so `split` is enough
      check parts[1].len == 64  # digest, rendered whole
      check parts[1] == parts[0].digestDeclared  # column two is what store declares for column one
      check parts[0].address.len > 0  # column one names row store knows
    # Ends in newline, so appending or piping row-wise needs no special case.
    check declaration().endsWith("\n")
    # Proven by asking for one that is there: consumer checks membership without parsing.
    check "NotoSerif-SemiBold.ttf " in declaration()


  test "no declared row can be read as a path, which both project builds rely on":
    # Verb prints paths when files are named and rows when none are. Both contributor
    #   builds tell them apart by shape -- one keeps lines that `fileExists`, other keeps
    #   lines starting `/` -- so row that looked like absolute path would be copied as
    #   font face by one and counted as served by other. Neither project can check this; store
    #   owns row shape, so store holds law.
    for row in declaration().strip.splitLines:
      check not row.startsWith('/')  # never absolute path
      check not row.fileExists  # nor relative one that happens to resolve


  test "fetch says why bytes did not land, in curl's own words or by digest, and keeps none":
    # Case as found (#953): scheduled run of `check` on `main` at `7786ce6` failed at
    #   `check path.len > 0` of font face test below, and its log named no cause, since fetch
    #   dropped what curl printed. Domain: curl fails, bytes carry other digest, bytes carry
    #   declared one; landing path holds bytes exactly where why is empty.
    let directory = createTempDir("test_assets_", "_fetch")
    defer: removeDir(directory)
    let
      landing = directory / "landing"
      source = directory / "source"
      empty = directory / "empty"
      missing = directory / "missing"
    writeFile(source, "abc")
    writeFile(empty, "")
    writeFile(landing, "stale")
    let failed = fetchLanding(landing, "file://" & missing, DIGEST_ABC)
    check failed.startsWith("curl: (37) ")  # curl's own error, its exit code first
    check missing in failed  # names what curl could not read
    check '\n' notin failed  # one line, which message of fetch carries whole
    check not fileExists(landing)  # stale bytes at landing path gone, never read as landed
    check fetchLanding(landing, "file://" & empty, DIGEST_ABC) ==
        "digest " & DIGEST_EMPTY & ", wanted " & DIGEST_ABC  # refused, both digests named
    check not fileExists(landing)  # bytes curl wrote and digest refused never kept
    check fetchLanding(landing, "file://" & source, DIGEST_ABC).len == 0  # landed, no why
    check readFile(landing) == "abc"  # bytes of address, at landing path


  test "cause of fetch that fails is what curl printed, on one line, else its exit code":
    # Curl prints some errors over several lines, as error 60 over six, so lines join.
    check causeCurl(TEXT_CURL_60, 60) ==
        "curl: (60) SSL certificate problem: self-signed certificate " &
        "More details here: https://curl.se/docs/sslcerts.html " &
        "curl failed to verify the legitimacy of the server and therefore could not " &
        "establish a secure connection to it. To learn more about this situation and " &
        "how to fix it, please visit the web page mentioned above."  # six lines, one apart
    check causeCurl(CAUSE_RESOLVE & "\n", 6) == CAUSE_RESOLVE  # one line, as printed
    check causeCurl("", 143) == "curl exited 143"  # nothing printed still gives cause
    check causeCurl("\n \n", 7) == "curl exited 7"  # blank lines print nothing


  test "fetch reads its cause through every line curl printed, else through its exit code":
    # Fake `curl` prints error 60 as curl 8.5.0 does, so fetch is held on six lines with no
    #   server, and on curl that prints nothing.
    let directory = createTempDir("test_assets_", "_curl")
    defer: removeDir(directory)
    let (landing, said) = (directory / "landing", directory / "said")
    writeFile(said, TEXT_CURL_60)
    withCurl(directory / "bin", "cat " & said.quoteShell & " >&2; exit 60"):
      check fetchLanding(landing, "https://localhost/x", DIGEST_ABC) ==
          causeCurl(TEXT_CURL_60, 60)  # six lines read as one
    withCurl(directory / "bin", "exit 7"):
      check fetchLanding(landing, "https://localhost/x", DIGEST_ABC) ==
          "curl exited 7"  # printed nothing, yet cause named
      check not fileExists(landing)  # nothing landed


  test "line of fetch that fails names file, address and why, and never reads as path":
    # Project builds take lines of `koch fetch-assets` that open with `/`, or name file that
    #   exists, as paths, as test of rows above says; line opening with word passes neither.
    const font_face = "NotoSans-Regular.ttf"
    let line = lineFailure(font_face, font_face.address, CAUSE_RESOLVE)
    check "`" & font_face & "`" in line  # file
    check "`" & font_face.address & "`" in line  # address
    check "`" & CAUSE_RESOLVE & "`" in line  # why
    check not line.startsWith('/')  # never absolute path
    check not line.fileExists  # nor relative one


  test "fetch that does not land writes its line to log, so log of run names cause":
    # Case as found (#953): log of run named no cause. Fake `curl` fails as curl does with
    #   network cut, and what `assetIn` writes to its log is what log of run shows.
    const font_face = "NotoSans-Regular.ttf"
    let directory = createTempDir("test_assets_", "_log")
    defer: removeDir(directory)
    let written = directory / "log"
    withCurl(directory / "bin", "echo " & CAUSE_RESOLVE.quoteShell & " >&2; exit 6"):
      var log = open(written, fmWrite)
      let path = assetIn(directory / "store", font_face, log)
      log.close
      check path.len == 0  # not landed, so no path
      check readFile(written) ==
          lineFailure(font_face, font_face.address, CAUSE_RESOLVE) & "\n"  # one line, whole


  test "each font face row carries codepoints its file maps, read from its bytes (Article X.8)":
    # Coverage check reads rows and never bytes, so rows say what bytes hold. Font face store lacks
    #   is fetched once; store keeps it under its digest, and later run reads it in place.
    let root = rootStore(getEnv(KEY_ASSETS))
    for (file, _, _, ranges) in ASSETS:
      let path = assetIn(root, file)
      check path.len > 0  # fetched, and digest held
      if path.len == 0: continue
      let read = readFile(path).cmap.codepoints.toSlices.toText
      if read != ranges: checkpoint "Row of `" & file & "` spells what its bytes do not map."
      check read == ranges  # row spells what `cmap` maps; `read` is text row takes (Article X.8)


  test "ranges read as row spells them, sorted and apart, and render back to same text":
    check "20-7e a0 2190-2195".toRanges == @[0x20 .. 0x7E, 0xA0 .. 0xA0, 0x2190 .. 0x2195]
    for (_, _, _, ranges) in ASSETS:
      let read = ranges.toRanges
      check read.toText == ranges  # one spelling for each set
      check read[0].a > CONTROL_MAX  # no control character (`assets.nim` header)
      for i in 1 ..< read.len:
        check read[i - 1].b + 1 < read[i].a  # sorted, and runs merged
