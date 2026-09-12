## Hold one declaration of every file fetched at build time, and fetch it into shared store.
##   CONTRIBUTOR.md names class already: "binaries are never committed, and neither are fonts,
##   images or any file audit cannot read", each recorded with origin, version, licence and
##   checksum. Store is that class kept once rather than once per project.
##   Faces are only instances today, and rows say so by grouping rather than by column: shape
##     is file, address and digest, which is what any such file needs and no more. Asset
##     wanting field this row lacks -- unpacking, or variant set -- is change rather than
##     something this shape already answers. Said here so next reader does not assume it does.
##
##   Reason it exists at all: Article X.8 gives three families to every presentation target, so
##     second target repeats first target's pins. That happened -- `rga_visualiser` and
##     `dance_ontology` each pinned four of same files, byte for byte, in their own
##     `tools/build.nim`. Article II.9 calls that copy real constraint does not force, and asks
##     each copy name its siblings; neither did, and nothing could have told them apart from
##     two different files (repository issue 116).
##
##   Digest is curator's, choice is project's. Store says what bytes `noto-sans-latin-400`
##     is; it never says which files target wants, and targets differ -- one draws maths and
##     symbols, other draws italic serif. So per-project autonomy CONTRIBUTOR.md argues for
##     is untouched: what stops being written twice is only what was already identical.
##   This is repository's first shared build input, and stays only one. Compilers are pinned
##     per project in nimble files, Atlas checkouts per project, npm per project, each
##     deliberately. Bytes of file are not toolchain: they are same bytes whoever fetches.
##
##   Store is `$KOCH_ASSETS_DIR`, else `~/.cache/koch/assets`, beside `~/.cache/koch/nim` that
##     `compilers.nim` keeps and for same reasons: never inside checkout, since audit reads
##     untracked files; keyed by what pins it, so entry cannot serve bytes pin would not have
##     fetched.
##   Keyed by digest rather than by name: two projects asking for one asset share one file by
##     construction, and changed pin is different path rather than stale one. Same property
##     `check.yml` gets from keying cache on file holding digests, one layer down.
##   Fetched file is checked before it is kept, and kept by moving into place, so half-written
##     download is never mistaken for verified one -- same shape `fetchRelease` uses.
##
##   Cost: `sha256sum` and `curl` are shelled out to, as `compilers.nim` does; `koch system`
##     declares both.
##   Nim tarball is not here, deliberately: its digest comes from upstream sidecar at fetch
##     time rather than from table here, and it is stored unpacked by pin because rest of koch
##     resolves toolchains by pin. Different trust and different key, so `compilers.nim` keeps
##     it rather than this pretending one shape serves both.
##   Cost: store grows and nothing prunes it. Face is ~30 kB where compiler is ~300 MB, so
##     what is unbounded here is number of pins repository has ever held, not bytes.
##   Cost: upstream that moves bytes under one address fails every project at once rather
##     than one. That is same failure one digest exists to make loud, and it is louder shared.

{.experimental: "strictFuncs".}

import std/[os, osproc, strutils]
import ./findings


const
  ASSETS_KEY* = "KOCH_ASSETS_DIR"
    ## Environment name overriding where assets are stored.
  ASSETS_DIR* = ".cache/koch/assets"
    ## Default store, under home and beside `~/.cache/koch/nim`.
  FONTSOURCE = "https://cdn.jsdelivr.net/npm/"
    ## Host serving `woff2` packaged by `@fontsource`, which is what page embeds.
  NOTOFONTS = "https://cdn.jsdelivr.net/gh/notofonts/notofonts.github.io"
    ## Noto project's own release repository, serving TrueType `@fontsource` does not ship.
  COMMIT_MONO = "https://cdn.jsdelivr.net/gh/eigilnikolajsen/commit-mono"
    ## Commit Mono is nobody's Noto, so its TrueType comes from its author's repository.
  ASSETS* = [
    # Page faces: `woff2` through `@fontsource`, version pinned in address, bytes by digest.
    ("commit-mono-latin-400-normal.woff2",
      FONTSOURCE & "@fontsource/commit-mono@5.3.0/files/",
      "86132abb57fc615f2ab900cde4cd9d5796e9791daf1f85d79fc933aa50b3b15c"),
    ("commit-mono-latin-700-normal.woff2",
      FONTSOURCE & "@fontsource/commit-mono@5.3.0/files/",
      "1b00600b728444492b0c4906cb85e0055b889ea32ea4fb29bf25cd90cd0365b4"),
    ("noto-sans-latin-400-normal.woff2",
      FONTSOURCE & "@fontsource/noto-sans@5.3.0/files/",
      "09aee8065d25508f23a4c3d92cd777ac869c52d93fd868a88f025d888a7937d6"),
    ("noto-sans-latin-600-normal.woff2",
      FONTSOURCE & "@fontsource/noto-sans@5.3.0/files/",
      "79e274470d1c5a0118eb325e2ea6f2eb2a449336d7fde1a4f20a2f32fe1119ed"),
    ("noto-sans-math-math-400-normal.woff2",
      FONTSOURCE & "@fontsource/noto-sans-math@5.2.8/files/",
      "90b9ddbed280e379e1af4601eb1d53eee8dd467b4c9174e5fd2d7347fe180d30"),
    ("noto-sans-symbols-2-symbols-400-normal.woff2",
      FONTSOURCE & "@fontsource/noto-sans-symbols-2@5.3.0/files/",
      "9c07d511848c274b5430c75bf98d1f2582680ef5f967947bfbdd06b75ca177c2"),
    ("noto-serif-latin-400-italic.woff2",
      FONTSOURCE & "@fontsource/noto-serif@5.3.0/files/",
      "a7386f772de25b62a3a449fa5d9f3e09916b65cf6a6dfc52f5a103c276fee157"),
    ("noto-serif-latin-400-normal.woff2",
      FONTSOURCE & "@fontsource/noto-serif@5.3.0/files/",
      "4c0cbe3eec50d260754d681c17ee2af49a43d7fd93ce42877f665fcb1a889b87"),
    ("noto-serif-latin-600-normal.woff2",
      FONTSOURCE & "@fontsource/noto-serif@5.3.0/files/",
      "abf0abc765331d7a1bbe6eb3603cf86be1cf3d1edbcf911cc2d52f78998c02d9"),
    # Desktop faces: TrueType and OpenType, which atlas reads and `@fontsource` does not ship.
    ("NotoSans-Regular.ttf",
      NOTOFONTS & "@NotoSans-v2.013/fonts/NotoSans/hinted/ttf/",
      "61b72eacd39533f0e5916cbb458abd7b3cf870667f63f3069dac2a75aa0317a2"),
    ("NotoSans-Bold.ttf",
      NOTOFONTS & "@NotoSans-v2.013/fonts/NotoSans/hinted/ttf/",
      "8e6da60154ae06e5e860777c4ccf8c7338d9b96ba34c1222db40a367d79b35dc"),
    ("NotoSerif-SemiBold.ttf",
      NOTOFONTS & "@NotoSerif-v2.013/fonts/NotoSerif/hinted/ttf/",
      "24d978fa5a0b096fc9e2f8d3f2bd7004634351d19d5b2e3be74b8ed61c68c236"),
    ("NotoSansMath-Regular.ttf",
      NOTOFONTS & "@NotoSansMath-v2.539/fonts/NotoSansMath/unhinted/ttf/",
      "05078db8b3bc7cbbe43fc00f36998db309d6a8d145b2f8a2e665bbdf7fc4cde0"),
    ("NotoSansSymbols2-Regular.ttf",
      NOTOFONTS & "@NotoSansSymbols2-v2.006/fonts/NotoSansSymbols2/unhinted/ttf/",
      "31854bbb3451d30b2b9ed205b7a0779a74b9464e0acdb0170fa41fa76b71d732"),
    ("CommitMonoV142-400Regular.otf",
      COMMIT_MONO & "@1.143/src/fonts/fontlab/",
      "0283fa3bbdb5cb2cb695946a60ea4aa2a0ceb872079304fe548188ab82ee58b2"),
  ]
    ## Every file fetched at build time: its name, address prefix it is fetched from, and
    ## digest of its bytes. Faces are all of them today; licence of each is in PROVENANCE.md,
    ## where CONTRIBUTOR.md already asks for it, rather than in second column here.
    ##   Rows are union of what two projects pinned separately, taken from their own tables
    ##   rather than fetched afresh: where both pinned one file they pinned same digest, and
    ##   that agreement is what made one table safe to write.
    ##   Version lives in address and bytes live in digest, so both move together or neither.


func storeRoot*(override: string): string =
  ## Read directory assets are stored under, override winning when set.
  if override.len > 0: override else: getHomeDir() / ASSETS_DIR


func addressOf*(file: string): string =
  ## Read address asset is fetched from; empty when store declares no such asset.
  for (name, prefix, _) in ASSETS:
    if name == file: return prefix & name
  ""


func digestOf*(file: string): string =
  ## Read digest declared for asset; empty when store declares no such asset.
  for (name, _, digest) in ASSETS:
    if name == file: return digest
  ""


func declaration*(): string =
  ## Render every declared asset as `<file> <digest>`, one per line, ending in newline.
  ##   Published so no consumer parses this source. Project holding law that its faces are
  ##     declared read `assets.nim` as text -- second parser for format only this module
  ##     owns, which is duplication store exists to end, one layer up (repository issue 134).
  ##   Two columns rather than three: address is fetcher's business, digest is what consumer
  ##     checks bytes against. Neither column can hold space, so `split` reads row.
  ##   Row never reads as path, and suite holds it so: verb prints paths when files are named
  ##     and rows when none are, and both project builds tell those apart by shape alone.
  for (file, _, digest) in ASSETS:
    result.add file & " " & digest & "\n"


func pathOf*(root, file: string): string =
  ## Read path asset takes in store, which is its digest; empty when none is declared.
  ##   Digest names file rather than its name doing so, since two projects asking for one
  ##   asset then share one entry, and moved pin is different entry rather than stale one.
  let digest = file.digestOf
  if digest.len == 0: "" else: root / digest


func unknown*(file: string): seq[Finding] =
  ## Report asset no row declares, naming file asked for.
  @[finding(
    "curator/audit/src/assets.nim", 0,
    "Store declares no such asset; add row naming its address and digest, or ask for one " &
      "it declares; got `" & file & "`.",
  )]


proc readDigest*(path: string): string =
  ## Read file's SHA-256 as `sha256sum` writes it; empty when it cannot be read.
  let (written, code) = execCmdEx("sha256sum " & quoteShell(path))
  if code != 0: return ""
  let first = written.strip.split(Whitespace)
  if first.len == 0: return ""
  let candidate = first[0]
  if candidate.len != 64: return ""
  for c in candidate:
    if c notin {'0' .. '9', 'a' .. 'f'}: return ""
  candidate


proc fetchAsset*(root, file: string): bool =
  ## Fetch asset into store and keep it only when its bytes carry declared digest.
  ##   Downloaded beside destination and moved in once checked, so half-written file is never
  ##   read as verified one.
  let (address, digest) = (file.addressOf, file.digestOf)
  if address.len == 0 or digest.len == 0: return false
  createDir(root)
  let landing = root / digest & ".fetching"
  removeFile(landing)
  defer: removeFile(landing)
  if execCmdEx("curl -sSLf -o " & quoteShell(landing) & " " & quoteShell(address))[1] != 0:
    return false
  let got = landing.readDigest
  if got != digest:
    echo "Asset does not carry digest declared for it; wanted `" & digest & "`, got `" &
      got & "`."
    return false
  moveFile(landing, root / digest)
  true


proc assetIn*(root, file: string): string =
  ## Read path to asset in store, fetching it when store holds none; empty when it cannot.
  ##   Entry already present is trusted without re-reading its bytes: name is digest, so
  ##   file at that path either carries it or was never written there by this.
  let path = pathOf(root, file)
  if path.len == 0: return ""
  if fileExists(path): return path
  if fetchAsset(root, file): path else: ""
