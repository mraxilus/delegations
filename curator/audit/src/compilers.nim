## Obtain compiler serving pin, fetching or building one when machine has none.
##   Every project pins its own compiler and one machine has one `nim` on PATH, so `koch ci`
##   could not be green as one command whenever changed set spanned two pins. Resolution
##   removes that: PATH when it already serves, else cache, else fetch.
##
##   Cache is `$KOCH_NIM_DIR`, else `~/.cache/koch/nim/<pin>`, beside Nim's own
##     `~/.cache/nim`. Never inside checkout: audit reads untracked files, so toolchain there
##     would be audited, as first run on `main` proved.
##   Release on platform nim-lang.org publishes arrives as tarball, in seconds. Commit, and
##     platform publishing none, is built from source, in minutes, by recipe `check.yml`
##     already ran, so it is proven rather than new.
##   Fetched compiler is asked what it is before it is trusted: wrong tarball is not
##     toolchain, and half-built tree carries bootstrap `bin/nim` answering with another
##     commit entirely. Build therefore lands beside destination and moves in once finished.
##
##   Rejected: directory developer populates by hand, which leaves defect for anyone who has
##     not; `choosenim` layout, second convention to maintain that cannot serve commit pin.
##   Cost: checker reaches network and may build compiler, once per pin, cached after.
##   Cost: tarball is checked against digest nim-lang.org publishes beside it, which is served
##     by same host over same TLS, so it catches truncated, mirrored or swapped file and not
##     compromised nim-lang.org. Signature would answer that and none is published: no `.asc`
##     exists for these tarballs, read rather than assumed. Header said before that nothing
##     publishable existed to parse, and that was simply wrong -- `<url>.sha256` is exactly
##     `sha256sum` output, for every release checked.
##   Cost: cached toolchain is few hundred megabytes and nothing prunes them.

{.experimental: "strictFuncs".}

import std/[options, os, osproc, strutils]
import ./[findings, projects, toolchain]


const
  CACHE_KEY* = "KOCH_NIM_DIR"
    ## Environment name overriding where toolchains are cached.
  CACHE_DIR* = ".cache/koch/nim"
    ## Default cache, under home and beside Nim's own `~/.cache/nim`.
  DOWNLOAD* = "https://nim-lang.org/download/nim-"
    ## Prefix of published release tarball.
  DIGEST* = ".sha256"
    ## Suffix of digest nim-lang.org publishes beside each tarball, in `sha256sum` format,
    ## i.e. digest, two spaces, file name. Read from site rather than assumed: same
    ## sidecar exists for 2.2.4 and 2.2.12, and no `.asc` is published for either.
  SOURCE* = "https://github.com/nim-lang/Nim"
    ## Repository built from when no tarball serves pin.
  PLATFORMS* = [
    ("linux", "amd64", "linux_x64"),
    ("linux", "i386", "linux_x32"),
    ("macosx", "amd64", "macosx_x64"),
  ]
    ## Platforms nim-lang.org publishes tarball for, as `hostOS`, `hostCPU`, tarball name.
    ## Anything absent here is built from source, which serves every platform Nim serves.


func platformOf*(os_name, cpu: string): string =
  ## Read tarball name nim-lang.org publishes for platform; empty when it publishes none.
  for (name, arch, tarball) in PLATFORMS:
    if name == os_name and arch == cpu: return tarball
  ""


func isBuilt*(pin, platform: string): bool =
  ## Decide whether pin must be built from source rather than fetched as tarball.
  ##   Commit is never published, and platform without tarball has nothing to fetch.
  pin.isCommit or platform.len == 0


func releaseUrl*(version, platform: string): string =
  ## Read address of published tarball for release on platform.
  DOWNLOAD & version & "-" & platform & ".tar.xz"


func digestUrl*(version, platform: string): string =
  ## Read address of digest published beside that tarball.
  releaseUrl(version, platform) & DIGEST


func pinnedDigest*(published: string): string =
  ## Read digest out of what that address serves; empty when text is not one.
  ##   Sidecar is `sha256sum` output, so digest is first field and name is second. Only
  ##   first field is read, and only when it is exactly sixty-four lowercase hex digits:
  ##   page that answered with redirect, error document or nothing at all would
  ##   otherwise arrive as digest that never matches, reporting mismatch where truth is
  ##   that nothing was published.
  let first = published.strip.split(Whitespace)
  if first.len == 0: return ""
  let candidate = first[0]
  if candidate.len != 64: return ""
  for c in candidate:
    if c notin {'0' .. '9', 'a' .. 'f'}: return ""
  candidate


func cacheRoot*(override: string): string =
  ## Read cache directory toolchains live under, override winning when set.
  if override.len > 0: override else: getHomeDir() / CACHE_DIR


func binOf*(root, pin: string): string =
  ## Read directory holding compiler serving pin, once it is cached.
  root / pin / "bin"


func missing*(dir, pin, bin: string): seq[Finding] =
  ## Report pin no compiler serves, naming cache koch tried, so remedy is visible.
  @[finding(
    dir, 0,
    "No compiler serves project pin, and fetching one failed; install it under `" & bin &
      "`, or make network reachable, then run again; got `" & pin & "`.",
  )]


proc digestOf*(path: string): string =
  ## Read file's SHA-256, as `sha256sum` writes it; empty when it cannot be read.
  ##   Shelled out rather than computed here for reason `std/sha1` is rejected: it is
  ##   deprecated and too weak, and digest of this strength lives in `checksums`, which is
  ##   package this project does not take (audit is standard library alone).
  let (written, code) = execCmdEx("sha256sum " & quoteShell(path))
  if code != 0: return ""
  pinnedDigest(written)


proc fetchRelease(version, platform, dir: string): bool =
  ## Download published tarball, check it against digest published beside it, and unpack it
  ## as `dir`; false when any step fails.
  ##   Tarball holds one top folder, `nim-<version>`, which becomes `dir` itself so every
  ##   pin has same shape whether fetched or built.
  ##   Digest is fetched from same host over same TLS as tarball, so what it defends against
  ##   is truncated, mirrored or swapped file, never nim-lang.org itself. That is weaker than
  ##   signature and is what is published: no `.asc` exists for these tarballs, checked
  ##   rather than assumed. Repository pins every other fetch it makes; this is that pin for
  ##   one that had none, and its limit is stated instead of overclaimed.
  let work = dir & ".fetching"
  removeDir(work)
  createDir(work)
  defer: removeDir(work)
  let archive = work / "nim.tar.xz"
  if runIn(work, "curl", ["-sSLf", "-o", archive, releaseUrl(version, platform)]) != 0:
    return false
  let sidecar = work / "nim.tar.xz.sha256"
  if runIn(work, "curl", ["-sSLf", "-o", sidecar, digestUrl(version, platform)]) != 0:
    echo "No digest published at " & digestUrl(version, platform) & "; refusing tarball."
    return false
  let (wanted, got) = (pinnedDigest(readFile(sidecar)), archive.digestOf)
  if wanted.len == 0 or wanted != got:
    echo "Digest of tarball does not match published one; wanted `" & wanted &
      "`, got `" & got & "`."
    return false
  if runIn(work, "tar", ["xf", archive]) != 0: return false
  let unpacked = work / ("nim-" & version)
  if not dirExists(unpacked): return false
  moveDir(unpacked, dir)
  true


proc buildSource(pin, dir: string): bool =
  ## Clone Nim, check pin out and build it, then move finished tree to `dir`.
  ##   Same recipe `check.yml` runs for commit pin, so it is proven rather than new.
  ##   Version pin arrives here only where no tarball is published, and its tag is `v<x>`.
  ##   Build happens beside `dir` and moves in once done, as fetch does: half-built tree
  ##   carries `bin/nim` of bootstrap stage, which answers `--version` with another commit
  ##   entirely, so second koch reading it mid-build would take it for finished toolchain
  ##   (measured 2026-09-06, probing bootstrap binary five minutes before boot completed).
  let work = dir & ".building"
  removeDir(work)
  removeDir(dir)
  let reference = if pin.isCommit: pin else: "v" & pin
  if runIn(".", "git", ["clone", "--filter=blob:none", "--quiet", SOURCE, work]) != 0:
    return false
  if runIn(work, "git", ["checkout", "--quiet", reference]) != 0: return false
  if runIn(work, "sh", ["build_all.sh"]) != 0: return false
  moveDir(work, dir)
  true


proc resolve*(pin: string, running: Compiler, root: string): Option[string] =
  ## Read `bin` of toolchain serving pin, fetching or building it when absent.
  ##   `none` is failure; `some("")` names compiler on PATH, which CI installs per job and
  ##   so always takes first branch. Two outcomes stay apart, since empty string means
  ##   PATH everywhere else here and would otherwise read as success.
  if pin.serves(running): return some("")
  let bin = binOf(root, pin)
  if pin.serves(compilerAt(bin / NIM)): return some(bin)
  let dir = root / pin
  createDir(root)
  echo "== fetching Nim " & pin
  let platform = platformOf(hostOS, hostCPU)
  let is_built =
    if pin.isBuilt(platform): buildSource(pin, dir)
    else: fetchRelease(pin, platform, dir)

  # Fetched compiler is asked what it is: wrong tarball or half-built tree is not toolchain.
  if is_built and pin.serves(compilerAt(bin / NIM)): return some(bin)
  removeDir(dir)
  none(string)
