## Replicate command form of `commands.nim` header: dotted call statement whose one argument is
##   call or parenthesised expression drops its double bracket; every other call stays, and fix
##   changes nothing second time.

{.experimental: "strictFuncs".}

import std/[sequtils, strutils, unittest]
import ../../src/knoller/[commands, reports]


const HEAD = "proc p() =\n"  ## Routine whose body holds each case, as statements.


func fixed(source: string): string =
  ## Fix command form of source, as `koch fix` does.
  fixCommands("a.nim", source).source


func isSettled(source: string): bool =
  ## Decide whether source reports no command finding and fixes to itself again.
  checkCommands("a.nim", source).len == 0 and source.fixed == source and
    fixCommands("a.nim", source).fixed.len == 0



suite "Commands":
  test "dotted call statement whose one argument is call drops its double bracket":
    for (breach, mended) in [
      (  # `cayleys.nim:390` of PGA library
        "  result[a][b].add(BasisSigned(\n    basis: term.basis,\n" &
          "    is_negated: dual_signed.is_negated xor term.is_negated,\n  ))\n",
        "  result[a][b].add BasisSigned(\n    basis: term.basis,\n" &
          "    is_negated: dual_signed.is_negated xor term.is_negated,\n  )\n",
      ),
      (  # `cayleys.nim:516`
        "  result[a][b].add(BasisSigned(basis: product_center.basis, is_negated: is_negated))\n",
        "  result[a][b].add BasisSigned(basis: product_center.basis, is_negated: is_negated)\n",
      ),
      (  # `cayleys.nim:754`
        "  destination[bm][bn].add(BasisSigned(\n    basis: term.basis,\n" &
          "    is_negated: term.is_negated xor as_negated\n  ))\n",
        "  destination[bm][bn].add BasisSigned(\n    basis: term.basis,\n" &
          "    is_negated: term.is_negated xor as_negated\n  )\n",
      ),
      (  # `multivectors.nim:96` and `:109`
        "  result.add(emitFunc(\n    name = toLower($b),\n    params = nnkFormalParams.newTree(\n" &
          "      ident\"Multivector\",\n    ),\n    is_public = true,\n  ))\n",
        "  result.add emitFunc(\n    name = toLower($b),\n    params = nnkFormalParams.newTree(\n" &
          "      ident\"Multivector\",\n    ),\n    is_public = true,\n  )\n",
      ),
      ("  x.f((a, b))\n", "  x.f (a, b)\n"),  # parenthesised expression
      ("  x.f(Foo[T](a))\n", "  x.f Foo[T](a)\n"),  # generic call
    ]:
      check checkCommands("a.nim", HEAD & breach).mapIt(it.line) == @[2]
      check (HEAD & breach).fixed == HEAD & mended
      check (HEAD & mended).isSettled  # second run writes nothing
    check checkCommands("a.nim", HEAD & "  x.f(g(a))\n")[0].message.endsWith("got `x.f(g`.")


  test "command form, plain call, other argument and call inside expression stay":
    for kept in [
      "  result[b].add BasisSigned(\n    basis: b, is_negated: n\n  )\n",  # `cayleys.nim:257`
      "  result[m][n].add BasisSigned(\n    basis: b,\n  )\n",  # `cayleys.nim:271`
      "  f(g(x))\n",  # plain call
      "  x.f(g(a), b)\n",  # two arguments
      "  x.f(\n    g(a),\n  )\n",  # comma after last argument
      "  x.f(g(a) + 1)\n",  # argument of other shape
      "  x.f(g(a).h)\n",
      "  x.f(@[a])\n",
      "  let y = x.f(g(a))\n",  # call inside expression
      "  y = x.f(g(a))\n",
      "  discard x.f(g(a))\n",
      "  x.f(g(a)) + 1\n",
      "  let z = a +\n    x.f(g(b))\n",  # continuation
      "  foo(a,\n    x.f(g(b)))\n",
    ]:
      check (HEAD & kept).isSettled
