discard """
action: run
cmd: "nim c --hints:off -d:testing -d:nimUnittestOutputLevel:PRINT_FAILURES $options $file"
"""
## pilno ro cipra poi zvati `suites/` ta'i pa samtci .i se ki'u bo le liste .e le fadni samtci pe
##   la'o gy. Nim .gy. cu se fanva pa roi
##   .i le vi datnyvei cu se tarmi lo tarmi be `curator/audit/tests/test_suites.nim` noi
##     `STYLE.md §6` cu cusku ke'a ta'i lo mupli .i le tarmi cu rapli se ciska vi ki'u lo nu le vi
##     se gunka cu cpacu no da pe `curator` .i se ki'u bo lo nu cikre pa le re datnyvei cu mulno
##     va'o lo nu cipra fi le drata kei po'o to `Article II.9` toi
##   .i ro cipra cu zvati lo datnyvei pe vo'a .i le cipra cu se cpacu sepi'o `import` gi'e na se
##     cpacu sepi'o `include` .i se ki'u bo lo sidju fancu pe re cipra cu no roi damba .i ro cipra
##     cu ka'e gunka ji'a ta'i lo nu sepli sepi'o `nim r tests/suites/test_<module>.nim`
##   .i lo liste be lo se cpacu cu se tcidu fi `suites/` ca lo nu fanva gi'e no roi se ciska .i se
##     ki'u bo ro cipra poi se jmina cu se pilno
##   .i no se jdice ca lo nu fanva cu rinka lo nu le samtci cu sisti ba lo pamoi nu fliba .i se ki'u
##     bo pa nu gunka cu jarco ro cipra poi fliba gi'e na jarco lo pamoi po'o
##   .i jdima fa lo nu lo srera pe lo nu fanva pa cipra cu fanta lo nu ro cipra cu gunka

{.warning[UnusedImport]: off.}  # lo cipra cu gunka mu'i lo se jalge gi'e benji no da

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[algorithm, macros, os, strutils]


macro importSuites(): untyped =
  ## cpacu ro `suites/test_*.nim` ta'i lo porsi sepi'o lo mulno judri .i lo judri poi na mulno cu se
  ##   tcidu ja'i lo stuzi be `macros.nim` gi'e na se tcidu ja'i lo stuzi be le vi datnyvei
  let directory = currentSourcePath().parentDir / "suites"
  var names: seq[string]
  for kind, name in walkDir(directory, relative = true):
    if kind == pcFile and name.startsWith("test_") and name.endsWith(".nim"): names.add name
  names.sort
  result = newStmtList()
  for name in names: result.add nnkImportStmt.newTree(newLit(directory / name))


importSuites()
