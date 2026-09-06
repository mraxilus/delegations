discard """
action: run
cmd: "nim c --hints:off -d:testing -d:nimUnittestAbortOnError:on $options $file"
batchable: true
joinable: true
"""
## Replicate kind registry of `kinds.nim` header table.

import std/[options, unittest]
import ../src/kinds


suite "Article VI":
  test "VI.5 every registered match classifies":
    check kindOf("a/b.nim").get == Kind.Nim  # .nim
    check kindOf("config.nims").get == Kind.NimScript  # .nims
    check kindOf("curator/audit/audit.nimble").get == Kind.Nimble  # .nimble
    check kindOf("koch.nim.cfg").get == Kind.Cfg and kindOf("x/nim.cfg").get == Kind.Cfg  # .cfg
    check kindOf("README.md").get == Kind.Markdown  # .md
    check kindOf("a.yml").get == Kind.Yaml and kindOf("a.yaml").get == Kind.Yaml  # yaml
    check kindOf(".gitignore").get == Kind.GitIgnore  # basename
    check kindOf(".gitattributes").get == Kind.GitAttributes  # basename
    check kindOf("x/app.ts").get == Kind.TypeScript  # .ts
    check kindOf("x/src/shim.cpp").get == Kind.Cpp  # .cpp
    check kindOf("x/src/shim.hpp").get == Kind.Cpp  # .hpp, C++ header by extension
    check kindOf("x/src/glue.c").get == Kind.C  # .c
    check kindOf("x/src/glue.h").get == Kind.C  # .h reads as C, since name cannot tell
    check kindOf("x/pages/index.html").get == Kind.Html  # .html
    check kindOf("x/pages/frame.svg").get == Kind.Svg  # .svg
    check kindOf("package.json").get == Kind.Json  # .json
    check kindOf("x/atlas.config").get == Kind.Json  # atlas basename
    check kindOf("atlas.lock").get == Kind.Json  # atlas basename

  test "VI.5 unregistered kinds are none":
    for path in ["Makefile", "x.mk", "data.csv", "nimble.paths", "a.txt"]:  # 5 cases
      check kindOf(path).isNone  # retired or never registered
