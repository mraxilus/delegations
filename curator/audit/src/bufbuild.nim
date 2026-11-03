## Fetch `buf` of Buf, i.e. `@bufbuild`, tool holding protobuf schema to version it shipped.
##   Data one program writes and another reads is Protocol Buffers, as Architect ruled on #761,
##     D1: schema is committed, and field numbers carry versions of format. `buf breaking`
##     compares changed schema with copy base shipped, and refuses change breaking older data.
##   Binary is repository's, never one project's: one check serves every schema, so store is
##     koch's, beside store of assets. Runner caches no store of it, since fetch takes seconds.
##   Store is `$KOCH_BUF_DIR`, else `~/.cache/koch/buf`, outside checkout, since audit reads
##     untracked files. Binary is named by version, so moved pin is different path.
##   Fetched from npm's registry, which serves each platform's binary as tarball and publishes
##     its SHA-512 beside it. Tarball is checked before it is unpacked, and binary moves in whole.
##
##   Rejected: `protoc`, which compiles schema and holds none to older version.
##   Rejected: `buf convert` for committed record, which drops misspelt field silently;
##     `protoc --encode` refuses it, so project declares `protobuf-compiler` instead.
##   Cost: Linux on x86-64 alone; other machine gets finding naming what to add.
##   Cost: about 33 MB fetched once per version, unpacked to 47 MB binary.

{.experimental: "strictFuncs".}

import std/[options, os, osproc, strutils]


const
  KEY_BUFBUILD* = "KOCH_BUF_DIR"  ## Environment name overriding where binaries are stored.
  DIRECTORY_BUFBUILD* = ".cache/koch/buf"
    ## Default store, under home and outside checkout, in koch's own directory.
  VERSION_BUFBUILD* = "1.75.0"  ## Pin, i.e. latest release when rule of data was written.
  TARBALL_BUFBUILD =
    "https://registry.npmjs.org/@bufbuild/buf-linux-x64/-/buf-linux-x64-" &
    VERSION_BUFBUILD & ".tgz"
    ## Package npm serves for Linux on x86-64.
  DIGEST_BUFBUILD* =
    "606189031d25a4c084eda3168cd38971fa04686fdefa26079d30b8499d0fe5e4b821f7ccaf203d678fdb6f59b" &
    "5c0d5c0109f004c530464e024ff9c7d544e3b8a"
    ## SHA-512 of tarball, in hex; npm publishes same bytes in base64 as `dist.integrity`.
  ENTRY_BUFBUILD = "package/bin/buf"  ## Binary's path inside tarball.


func rootBufbuild*(override: string): string =
  ## Read directory binaries are stored under, override winning when set.
  if override.len > 0: override else: getHomeDir() / DIRECTORY_BUFBUILD


func pathBufbuild*(root: string): string =
  ## Read path binary of pinned version takes in store.
  root / VERSION_BUFBUILD / "buf"


proc ran(arguments: openArray[string]): tuple[output: string, ok: bool] =
  ## Run command, printing its output to stderr where it fails.
  let (output, code) = execCmdEx(quoteShellCommand(arguments))
  if code != 0:
    stderr.writeLine "`" & arguments.join(" ") & "` exited " & $code & ":"
    stderr.write output
  (output, code == 0)


proc fetchBufbuild(path: string): bool =
  ## Fetch tarball, check its digest, unpack binary, and move it to `path` whole.
  ##   False where any step fails, with reason on stderr; stdout stays path alone.
  when not (defined(linux) and defined(amd64)):
    stderr.writeLine "No buf is declared for this platform; add its tarball and digest to " &
      "`curator/audit/src/bufbuild.nim`."
    false
  else:
    let
      staging = path.parentDir & ".fetching"
      tarball = staging / "buf.tgz"
    removeDir(staging)
    createDir(staging)
    defer: removeDir(staging)
    if not ran(["curl", "-sSLf", "-o", tarball, TARBALL_BUFBUILD]).ok: return false
    let summed = ran(["sha512sum", tarball])
    if not summed.ok: return false
    if summed.output.splitWhitespace[0] != DIGEST_BUFBUILD:
      stderr.writeLine "Tarball of buf does not carry digest declared for it; wanted `" &
        DIGEST_BUFBUILD & "`."
      return false
    if not ran(["tar", "-xzf", tarball, "-C", staging, ENTRY_BUFBUILD]).ok: return false
    createDir(path.parentDir)
    moveFile(staging / ENTRY_BUFBUILD, path)
    true


proc bufbuildIn*(root: string): Option[string] =
  ## Read path to `buf` in store, fetching it where store lacks it.
  ##   Binary already present is trusted: its folder is pin, and it moves in only whole and
  ##   only once its tarball carried declared digest.
  let path = pathBufbuild(root)
  if fileExists(path): return some(path)
  if fetchBufbuild(path): some(path) else: none(string)
