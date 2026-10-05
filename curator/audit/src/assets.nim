## Hold one declaration of every file fetched at build time, and fetch it into shared store.
##   CONTRIBUTOR.md names class already: "binaries are never committed, and neither are fonts,
##   images or any file audit cannot read", each recorded with origin, version, licence and
##   checksum. Store is that class kept once rather than once per project.
##   Faces are only instances today, and rows say so by grouping and by one column: shape is
##     file, address, digest, and codepoints file maps. First three are what any such file
##     needs; fourth is face's, and asset that is no face makes it change. So does asset
##     wanting field this row lacks -- unpacking, or variant set. Said here so next reader does
##     not assume shape already answers either.
##
##   Codepoints are data because coverage check (`coverage.nim`, Article X.8) reads no bytes:
##     static pass runs in about second and fetches nothing, and store lies outside checkout.
##     `test_assets.nim` holds each row to `cmap` of its file's bytes, so new digest with old
##     ranges fails, printing ranges read for row to take.
##   Ranges are spelled as `fc-query --format='%{charset}'` prints them: hex bounds joined by
##     `-`, space apart. So fontconfig reads same text off same bytes, as check independent of
##     suite's reader (measured on every file of store, fontconfig 2.15.0, 2026-10-04).
##     Control characters below `20` are left out, since none draws, and fontconfig leaves them
##     out too. Faces mapping one set share one constant; face whose bytes move splits from it.
##
##   Reason it exists at all: Article X.8 gives three families to every presentation target, so
##     second target repeats first target's pins. Two pins of one file, each in its own
##     `tools/build.nim`, are copy no real constraint forces (Article II.9), and nothing tells
##     such copy apart from two different files.
##
##   Digest is curator's, choice is project's. Store says what bytes `NotoSans-Regular.ttf`
##     is; it never says which files target wants, and targets differ -- one draws maths and
##     symbols, other draws italic serif. So per-project autonomy CONTRIBUTOR.md argues for
##     is untouched: what stops being written twice is only what was already identical.
##   This is repository's first shared build input, and stays only one. Compilers are pinned
##     per project in nimble files, Atlas checkouts per project, npm per project, each
##     deliberately. Bytes of file are not toolchain: they are same bytes whoever fetches.
##
##   Store is `$KOCH_ASSETS_DIR`, else `~/.cache/koch/assets`: repository's own, so koch's, while
##     compiler cache `~/.cache/knoller/nim` is knoller's, which koch uses too. Both stay outside
##     checkout for one reason, since audit reads untracked files; store is keyed by what pins
##     it, so entry cannot serve bytes pin would not have fetched.
##   Keyed by digest rather than by name: two projects asking for one asset share one file by
##     construction, and changed pin is different path rather than stale one. Same property
##     `check.yml` gets from keying cache on file holding digests, one layer down.
##   Fetched file is checked before it is kept, and kept by moving into place, so half-written
##     download is never mistaken for verified one -- same shape `fetchRelease` uses.
##
##   Cost: `sha256sum` and `curl` are shelled out to; `koch list-packages` declares both. Digest is
##     read by `digestOf` of knoller, not copied here, so one reader serves both fetches and
##     store imports knoller for it.
##   Nim tarball is not here, deliberately: its digest comes from upstream sidecar at fetch
##     time rather than from table here, and it is stored unpacked by pin because rest of koch
##     resolves toolchains by pin. Different trust and different key, so knoller's `compilers.nim`
##     keeps it rather than this pretending one shape serves both.
##   Cost: store grows and nothing prunes it. Face is under 1 MB where compiler is ~300 MB, so
##     what is unbounded here is number of pins repository has ever held, not bytes.
##   Cost: upstream that moves bytes under one address fails every project at once rather
##     than one. That is same failure one digest exists to make loud, and it is louder shared.

{.experimental: "strictFuncs".}

import std/[os, osproc, strutils]
import ../../knoller/src/knoller
import ./findings


const
  ASSETS_KEY* = "KOCH_ASSETS_DIR"  ## Environment name overriding where assets are stored.
  ASSETS_DIRECTORY* = ".cache/koch/assets"
    ## Default store, under home and outside checkout, in koch's own directory.
  FONTSOURCE = "https://cdn.jsdelivr.net/npm/"
    ## Host serving `woff2` subsets packaged by `@fontsource`.
  NOTOFONTS = "https://cdn.jsdelivr.net/gh/notofonts/notofonts.github.io"
    ## Noto project's own release repository, serving whole TrueType faces.
  COMMIT_MONO = "https://cdn.jsdelivr.net/gh/eigilnikolajsen/commit-mono"
    ## Commit Mono is nobody's Noto, so its TrueType comes from its author's repository.
  RANGES_COMMIT_MONO =
    "20-7e a0-17f 192 1fa-1ff 218-21b 237 2c6-2c7 2c9 2d8-2dd 300-301 308 30a 326 384-386 " &
    "388-38a 38c 38e-3a1 3a3-3ce 3d5 1e80-1e85 1ef2-1ef3 2010-201e 2020-2022 2026 2030 2032-2033 " &
    "2039-203a 203c 203e 2044 204a 2070 2074-208e 20a3-20a4 20a7 20ac 2105 2113 2116-2117 2122 " &
    "2126 212e 2153-215f 218a-218b 2190-2195 21a8 21b9 21d2 21de-21df 21e4-21e5 21e7-21e8 21ea " &
    "2200 2202-220f 2211-2212 2215 2217 2219-221a 221e-221f 2227-222b 2234-2237 2241-224b " &
    "2260-2262 2264-2265 2282-228b 22b8 22c5 22ee-22ef 22f1 2302 2318 2320-2321 2324-2326 2328 " &
    "232b 2387 238b 239b-23ad 23ce 23fb-23fe 2400-2426 2500-252c 252e-25af 25b2 25b6 25bc 25c0 " &
    "25c4 25c6-25c7 25c9-25cb 25ce-25d3 25d5-25d7 25d9-25e5 25e7-25eb 25ef-25f7 2605 2713-2715 " &
    "2717 279c 27e6-27e7 2800-28ff 2919-291c 2987-2988 2b58 e0a0-e0a2 e0b0-e0b3 ee00-ee09 f8ff " &
    "feff fffd"
    ## Codepoints Commit Mono maps: both `woff2` subsets and OpenType file of store map one set.
  RANGES_NOTO_UPRIGHT =
    "20-7e a0-377 37a-37f 384-38a 38c 38e-3a1 3a3-3e1 3f0-52f 10fb 1ab0-1ac0 1ac5 1ac7-1ace " &
    "1c80-1c88 1d00-1df9 1dfb-1f15 1f18-1f1d 1f20-1f45 1f48-1f4d 1f50-1f57 1f59 1f5b 1f5d " &
    "1f5f-1f7d 1f80-1fb4 1fb6-1fc4 1fc6-1fd3 1fd6-1fdb 1fdd-1fef 1ff2-1ff4 1ff6-1ffe 2000-2064 " &
    "2066-2071 2074-208e 2090-209c 20a0-20c0 20f0 2100-215f 2183-2184 2189 2212 25cc 2c60-2c7f " &
    "2de0-2e5d a640-a69f a700-a7ca a7d0-a7d1 a7d3 a7d5-a7d9 a7f2-a7ff a92e ab30-ab6b fb00-fb06 " &
    "fe00 fe20-fe2f feff fffc-fffd 10780-10785 10787-107b0 107b2-107ba 1df00-1df1e"
    ## Codepoints upright Noto Sans and Noto Serif map, at every weight store pins: one set.
  RANGES_NOTO_SERIF_ITALIC =
    "20-7e a0-377 37a-37f 384-38a 38c 38e-3a1 3a3-3e1 3f0-52f 1ab0-1ac0 1ac5 1ac7-1ace 1c80-1c88 " &
    "1d00-1df9 1dfb-1f15 1f18-1f1d 1f20-1f45 1f48-1f4d 1f50-1f57 1f59 1f5b 1f5d 1f5f-1f7d " &
    "1f80-1fb4 1fb6-1fc4 1fc6-1fd3 1fd6-1fdb 1fdd-1fef 1ff2-1ff4 1ff6-1ffe 2000-2064 2066-2071 " &
    "2074-208e 2090-209c 20a0-20bf 20f0 2100-215f 2184 2189 2212 25cc 2c60-2c7f 2de0-2e5d " &
    "a640-a69f a700-a7ca a7d0-a7d1 a7d3 a7d5-a7d9 a7f2-a7ff a92e ab30-ab6b fb00-fb06 fe00 " &
    "fe20-fe2f feff fffc-fffd 10780-10785 10787-107b0 107b2-107ba 11ab0-11ab1 1df00-1df1e"
    ## Codepoints Noto Serif Italic maps, which is set of its own.
    ##   Upright set without `10fb`, `20c0` and `2183`, and with `11ab0-11ab1`.
  RANGES_NOTO_SANS_MATH =
    "20-7e a0 a7 ac b1 d7 f7 123 131 237 2d4-2d5 300-30c 311-312 323 326-327 32c-333 338 33a 33f " &
    "346 34d 391-3a1 3a3-3a9 3b1-3c9 3d1 3d5-3d6 3dc-3dd 3f0-3f1 3f4-3f5 1d46 2000-200b 2016 " &
    "2018-2019 201c-201d 2020 2026 202f 2032-2037 2044 2057 205f 20d0-20dc 20e1 20e5-20ef 2102 " &
    "210a-2113 2115 2119-211d 2124 2128 212c-212d 212f-2131 2133-2138 213c-2140 2145-2149 " &
    "2190-21ae 21b0-21e5 21f1-21f2 21f4-22ff 2308-230b 2310 2319 231c-2321 2336-237a 237c 2395 " &
    "239b-23b7 23d0 23dc-23e1 2474-2475 2500 250c 2510 2514 2518 2550 2571-2572 2577 25a0-25ff " &
    "2605-2606 266d-266f 26aa-26ab 2713 2739 27c0-27ff 2900-2aab 2aad-2aff 2b0e-2b11 2b16-2b1b " &
    "2b1d 2b24-2b25 2b30-2b4c fe00 ff5b ff5d 1d400-1d454 1d456-1d49c 1d49e-1d49f 1d4a2 " &
    "1d4a5-1d4a6 1d4a9-1d4ac 1d4ae-1d4b9 1d4bb 1d4bd-1d4c3 1d4c5-1d505 1d507-1d50a 1d50d-1d514 " &
    "1d516-1d51c 1d51e-1d539 1d53b-1d53e 1d540-1d544 1d546 1d54a-1d550 1d552-1d6a5 1d6a8-1d7cb " &
    "1d7ce-1d7ff 1ee00-1ee03 1ee05-1ee1f 1ee21-1ee22 1ee24 1ee27 1ee29-1ee32 1ee34-1ee37 1ee39 " &
    "1ee3b 1ee42 1ee47 1ee49 1ee4b 1ee4d-1ee4f 1ee51-1ee52 1ee54 1ee57 1ee59 1ee5b 1ee5d 1ee5f " &
    "1ee61-1ee62 1ee64 1ee67-1ee6a 1ee6c-1ee72 1ee74-1ee77 1ee79-1ee7c 1ee7e 1ee80-1ee89 " &
    "1ee8b-1ee9b 1eea1-1eea3 1eea5-1eea9 1eeab-1eebb 1eef0-1eef1 1f780-1f7d8"
    ## Codepoints Noto Sans Math maps: arrows, operators and mathematical alphanumerics.
  RANGES_NOTO_SANS_SYMBOLS_2 =
    "20 23 2a 30-39 7f a0 2022 20e2-20e3 21af 21e6-21f0 21f3 2218-2219 2299 22c4-22c6 2316 2318 " &
    "231a-231b 2324-2328 232b 237b 237d-237f 2394 23ce-23cf 23e9-23ea 23ed-23ef 23f1-2426 " &
    "2440-244a 25a0-2609 260e-2612 2614-2623 2630-2637 263c 2654-2668 267f-268f 269e-26a1 " &
    "26aa-26ac 26bd-26cd 26cf-26e1 2700-2704 2706-2709 270b-271c 2722-2727 2729-274b 274d " &
    "274f-2753 2756-2775 2794 2798-27af 27b1-27be 2800-28ff 2981 29bf 29eb 2b00-2b0d 2b12-2b2f " &
    "2b4d-2b73 2b76-2b95 2b97-2bfd 2bff 4dc0-4dff fff9-fffb 10140-1018e 10190-1019c 101a0 " &
    "101d0-101fd 102e0-102fb 10e60-10e7e 1d2c0-1d2d3 1d2e0-1d2f3 1d300-1d356 1d360-1d378 " &
    "1f000-1f02b 1f030-1f093 1f0a0-1f0ae 1f0b1-1f0bf 1f0c1-1f0cf 1f0d1-1f0f5 1f30d-1f30f 1f315 " &
    "1f31c 1f321-1f32c 1f336 1f378 1f37d 1f393-1f39f 1f3a7 1f3ac-1f3ae 1f3c2 1f3c4 1f3c6 " &
    "1f3ca-1f3ce 1f3d4-1f3e0 1f3ed 1f3f1-1f3f3 1f3f5-1f3f7 1f408 1f415 1f41f 1f426 1f43f " &
    "1f441-1f442 1f446-1f449 1f44c-1f44e 1f453 1f46a 1f47d 1f4a3 1f4b0 1f4b3 1f4b9 1f4bb 1f4bf " &
    "1f4c8-1f4cb 1f4da 1f4df 1f4e4-1f4e6 1f4ea-1f4ed 1f4f7 1f4f9-1f4fb 1f4fd-1f4fe 1f503 " &
    "1f507-1f50a 1f50d 1f512-1f513 1f53e-1f545 1f54a 1f550-1f579 1f57b-1f594 1f597-1f5a3 " &
    "1f5a5-1f5fa 1f650-1f67f 1f687 1f68d 1f691 1f694 1f698 1f6ad 1f6b2 1f6b9-1f6ba 1f6bc " &
    "1f6c6-1f6cb 1f6cd-1f6cf 1f6d3-1f6d7 1f6e0-1f6ea 1f6f0-1f6f3 1f6f7-1f6fc 1f780-1f7d8 " &
    "1f7e0-1f7eb 1f800-1f80b 1f810-1f847 1f850-1f859 1f860-1f887 1f890-1f8ad 1f8b0-1f8b1 1f93b " &
    "1f946 1fa00-1fa53 1fa60-1fa6d 1fa70-1fa74 1fa78-1fa7a 1fa80-1fa86 1fa90-1faa8 1fab0-1fab6 " &
    "1fac0-1fac2 1fad0-1fad6 1fb00-1fb92 1fb94-1fbca 1fbf0-1fbf9"
    ## Codepoints Noto Sans Symbols 2 maps: shapes, dingbats, game pieces and pictographs.
  ASSETS* = [
    # Subset faces: `woff2` through `@fontsource`, version pinned in address, bytes by digest.
    #   Commit Mono alone: it is no Noto, and pages draw its Latin subset. Article X.8 ships
    #   every Noto face whole, so no row declares Noto subset, and `fetch-assets` refuses one.
    ("commit-mono-latin-400-normal.woff2",
      FONTSOURCE & "@fontsource/commit-mono@5.3.0/files/",
      "86132abb57fc615f2ab900cde4cd9d5796e9791daf1f85d79fc933aa50b3b15c",
      RANGES_COMMIT_MONO),
    ("commit-mono-latin-700-normal.woff2",
      FONTSOURCE & "@fontsource/commit-mono@5.3.0/files/",
      "1b00600b728444492b0c4906cb85e0055b889ea32ea4fb29bf25cd90cd0365b4",
      RANGES_COMMIT_MONO),
    # Whole faces: TrueType and OpenType from each face's own release, which pages and desktop
    #   atlas both embed; `@fontsource` ships none of them.
    ("NotoSans-Regular.ttf",
      NOTOFONTS & "@NotoSans-v2.013/fonts/NotoSans/hinted/ttf/",
      "61b72eacd39533f0e5916cbb458abd7b3cf870667f63f3069dac2a75aa0317a2",
      RANGES_NOTO_UPRIGHT),
    ("NotoSans-Bold.ttf",
      NOTOFONTS & "@NotoSans-v2.013/fonts/NotoSans/hinted/ttf/",
      "8e6da60154ae06e5e860777c4ccf8c7338d9b96ba34c1222db40a367d79b35dc",
      RANGES_NOTO_UPRIGHT),
    ("NotoSans-SemiBold.ttf",
      NOTOFONTS & "@NotoSans-v2.013/fonts/NotoSans/hinted/ttf/",
      "cd264c3c623fbcd1c2baca0e4d5c1d99cce45b77d59823b55d098c4562bca61c",
      RANGES_NOTO_UPRIGHT),
    ("NotoSerif-Regular.ttf",
      NOTOFONTS & "@NotoSerif-v2.013/fonts/NotoSerif/hinted/ttf/",
      "504b8ec55d003cade88fb0a7bb93254ad81fd1cb29f4818d260300dbaef5d37b",
      RANGES_NOTO_UPRIGHT),
    ("NotoSerif-Italic.ttf",
      NOTOFONTS & "@NotoSerif-v2.013/fonts/NotoSerif/hinted/ttf/",
      "637c44b0dbd0df16a969548483b01612dd095e306761af14072ae3ab69389b4f",
      RANGES_NOTO_SERIF_ITALIC),
    ("NotoSerif-SemiBold.ttf",
      NOTOFONTS & "@NotoSerif-v2.013/fonts/NotoSerif/hinted/ttf/",
      "24d978fa5a0b096fc9e2f8d3f2bd7004634351d19d5b2e3be74b8ed61c68c236",
      RANGES_NOTO_UPRIGHT),
    ("NotoSansMath-Regular.ttf",
      NOTOFONTS & "@NotoSansMath-v2.539/fonts/NotoSansMath/unhinted/ttf/",
      "05078db8b3bc7cbbe43fc00f36998db309d6a8d145b2f8a2e665bbdf7fc4cde0",
      RANGES_NOTO_SANS_MATH),
    ("NotoSansSymbols2-Regular.ttf",
      NOTOFONTS & "@NotoSansSymbols2-v2.006/fonts/NotoSansSymbols2/unhinted/ttf/",
      "31854bbb3451d30b2b9ed205b7a0779a74b9464e0acdb0170fa41fa76b71d732",
      RANGES_NOTO_SANS_SYMBOLS_2),
    ("CommitMonoV142-400Regular.otf",
      COMMIT_MONO & "@1.143/src/fonts/fontlab/",
      "0283fa3bbdb5cb2cb695946a60ea4aa2a0ceb872079304fe548188ab82ee58b2",
      RANGES_COMMIT_MONO),
  ]
    ## Every file fetched at build time: its name, address prefix it is fetched from, digest of
    ## its bytes, and codepoints its `cmap` maps to glyph. Faces are all of them today; licence
    ## of each is in PROVENANCE.md, where CONTRIBUTOR.md already asks for it, rather than in
    ## column here.
    ##   Each file any project pins stands here once: where several pin one file they share
    ##   its row and so its digest, and that agreement is what makes one table safe.
    ##   Version lives in address and bytes live in digest, so both move together or neither.
    ##   Codepoints follow bytes: suite reads them off bytes digest checks, so digest moved
    ##   without them fails suite.


func storeRoot*(override: string): string =
  ## Read directory assets are stored under, override winning when set.
  if override.len > 0: override else: getHomeDir() / ASSETS_DIRECTORY


func addressOf*(file: string): string =
  ## Read address asset is fetched from; empty when store declares no such asset.
  for (name, prefix, _, _) in ASSETS:
    if name == file: return prefix & name
  ""


func declaredDigest*(file: string): string =
  ## Read digest declared for asset; empty when store declares no such asset.
  for (name, _, digest, _) in ASSETS:
    if name == file: return digest
  ""


func toRanges*(text: string): seq[Slice[int]] =
  ## Read codepoint ranges row spells, i.e. hex `low-high` or lone `low`, space apart.
  ##   Malformed token raises, and `coverage.nim` reads rows in `const`, so bad row fails build:
  ##   earliest boundary there is (Article IV.4).
  for token in text.splitWhitespace:
    let
      bounds = token.split('-')
      low = bounds[0].parseHexInt
    result.add low .. (if bounds.len > 1: bounds[1].parseHexInt else: low)


func declaration*(): string =
  ## Render every declared asset as `<file> <digest>`, one per line, ending in newline.
  ##   Published so no consumer parses this source. Project reading `assets.nim` as text to
  ##     hold law that its faces are declared is second parser for format only this module
  ##     owns, which is duplication store exists to end, one layer up.
  ##   Two columns rather than three: address is fetcher's business, digest is what consumer
  ##     checks bytes against. Neither column can hold space, so `split` reads row.
  ##   Row never reads as path, and suite holds it so: verb prints paths when files are named
  ##     and rows when none are, and both project builds tell those apart by shape alone.
  for (file, _, digest, _) in ASSETS:
    result.add file & " " & digest & "\n"


func pathOf*(root, file: string): string =
  ## Read path asset takes in store, which is its digest; empty when none is declared.
  ##   Digest names file rather than its name doing so, since two projects asking for one
  ##   asset then share one entry, and moved pin is different entry rather than stale one.
  let digest = file.declaredDigest
  if digest.len == 0: "" else: root / digest


func unknown*(file: string): seq[Finding] =
  ## Report asset no row declares, naming file asked for.
  @[finding(
    "curator/audit/src/assets.nim", 0,
    "Store declares no such asset; add row naming its address and digest, or ask for one " &
      "it declares; got `" & file & "`.",
  )]


proc fetchAsset(root, file: string): bool =
  ## Fetch asset into store and keep it only when its bytes carry declared digest.
  ##   Downloaded beside destination and moved in once checked, so half-written file is never
  ##   read as verified one.
  let (address, digest) = (file.addressOf, file.declaredDigest)
  if address.len == 0 or digest.len == 0: return false
  createDir(root)
  let landing = root / digest & ".fetching"
  removeFile(landing)
  defer: removeFile(landing)
  if execCmdEx("curl -sSLf -o " & quoteShell(landing) & " " & quoteShell(address))[1] != 0:
    return false
  let got = landing.digestOf
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
