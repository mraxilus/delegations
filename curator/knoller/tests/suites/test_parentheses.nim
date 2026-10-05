## Replicate rule of `parentheses.nim` header: parentheses around prefix term or plain operand
##   beside binary operator, and around plain operand after prefix operator, go where parser
##   proves it; every other group stays, and fix changes nothing second time.
##   Parser is stub (`stubs.nim`), answering as commit pin of `ronri` projects does.

{.experimental: "strictFuncs".}

import std/[sequtils, strutils, tables, unittest]
import ../../src/knoller/[parentheses, reports]
import ./stubs


const LINKS =
  "      let\n        task = SETTLES[i]\n        links = @(PAIRS[task.pair][0])\n" &
  "        is_away = PAIRS[task.pair][1]\n"
  ## Lines 77 to 80 of `tests/test_read.nim` of `dance_ontology` (#539), as found.


func proofsOf(source: string): Proofs =
  ## Answer source by stub parser, as caller holds answer before fix runs again.
  result.answers[source] = source.stubbed


func fixed(source: string): string =
  ## Fix parentheses of source, parser answering, as `koch fix` does.
  fixParentheses("a.nim", source, source.proofsOf).source


func isSettled(source: string): bool =
  ## Decide whether source reports no parentheses finding and fixes to itself again.
  let proofs = source.proofsOf
  checkParentheses("a.nim", source, proofs).len == 0 and source.fixed == source and
    fixParentheses("a.nim", source, proofs).fixed.len == 0



suite "Parentheses":
  test "parentheses around prefix term or plain operand go, as parser groups it so":
    for (breach, mended, count) in [
      (  # `suites.nim:330` of PGA library: prefix terms beside binary operator
        "let distance_b = (|∙ ⊖(𝐦 ∧ 𝐧)) + (|∘ (𝐦 ∧ ⊖𝐧))\n",
        "let distance_b = |∙ ⊖(𝐦 ∧ 𝐧) + |∘ (𝐦 ∧ ⊖𝐧)\n",
        2,
      ),
      (  # `suites.nim:329`
        "let distance_a = (|∙ ⊖(𝐦 ∧ 𝐧)) div (|∙ (⊖𝐦 ∧ ⊖𝐧))\n",
        "let distance_a = |∙ ⊖(𝐦 ∧ 𝐧) div |∙ (⊖𝐦 ∧ ⊖𝐧)\n",
        2,
      ),
      (  # `suites.nim:262`: plain operand after prefix operator
        "check (∙𝐦 ∧ ■(𝐧)) + (□(𝐦) ∧ ∙𝐧)\n",
        "check (∙𝐦 ∧ ■𝐧) + (□𝐦 ∧ ∙𝐧)\n",
        2,
      ),
      ("let c = ☆(m) ∧ 𝐞ₙ\n", "let c = ☆m ∧ 𝐞ₙ\n", 1),  # `operators.nim:456`
      (  # `algebra.nim:257`: plain operand beside binary operator; outer binary group stays
        "let mask = not ((2'u^(DIMENSIONS)) - 1)\n",
        "let mask = not ((2'u^DIMENSIONS) - 1)\n",
        1,
      ),
      ("let x = (a.b(c)[i]) + 1\n", "let x = a.b(c)[i] + 1\n", 1),  # call, index, field glued
    ]:
      check checkParentheses("a.nim", breach, breach.proofsOf).len == count
      check breach.fixed == mended
      check mended.isSettled  # second run writes nothing
    let named = "let c = ☆(m) ∧ n\n"
    check checkParentheses("a.nim", named, named.proofsOf)[0].message.endsWith("got `(m)`.")


  test "group whose removal glues tokens, or that holds binary expression or suffix, stays":
    for kept in [
      "check \\(/𝐮) =~ 𝐮\n",  # `\/` would lex one operator
      "check ^(|𝐦) =~ x\n",
      "check ★𝐦 =~ /(∙𝐦)\n",
      "let d = m ∧ ☆( ⊟ m)\n",
      "let s = sign * ⊡( ☆ m) ∨ ⊟ m\n",
      "let x = b + -(1)\n",  # `-1` would lex one literal
      "let x = (■m).x + y\n",  # `■m.x` reads `■(m.x)`
      "let y = (^distance_b){Grade.scalar}\n",
      "flags = flags or (1'u shl (i-1))\n",  # binary expression, whatever its precedence
      "let c = (a and b) or d\n",  # X.4 parentheses
      "let t = (a, b)\n",  # tuple
      "x.f (a, b)\n",  # argument of command form
      "let y = f(a) + g(b)\n",  # call
      "proc f(a: int) = discard\n",  # signature
      "let y = (a)\n",  # no operator beside it
      "check (|∙ x) =~ y\n",  # after command head, `|∙` would read binary
      "let p = a^(-b)\n",  # wrapped exponent of power operator, `^-` would lex one operator
      "let p = a ^ (-b)\n",  # spacing glues power operator, so guard reads it glued
      "let p = a^(-1)\n",
    ]:
      check kept.isSettled


  test "group parser reads otherwise without it stays, and bare operand after sigil goes":
    check LINKS.isSettled  # `@PAIRS[task.pair][0]` reads `(@PAIRS)[task.pair][0]`
    for kept in [
      "let s = @(x.items)\n",  # sigil binds name before field, call or index
      "let s = @(f(a))\n",
      "let s = @@(x[0])\n",
      "let s = @(x[i])\n",  # X.4 example
    ]:
      check kept.isSettled
    check "let s = @(x)\n".fixed == "let s = @x\n"
    check "let s = @x\n".isSettled  # second run writes nothing


  test "check and fix agree: each names only groups parser proves, none where no answer holds":
    let
      source = "let x = (a.b(c)[i]) + @(x[0])\n"
      proofs = source.proofsOf
    check proofs.answers[source] == @[8]  # `(x[0])` refused
    check checkParentheses("a.nim", source, proofs).mapIt(it.message.split("got ")[1]) ==
      @["`(a.b(c)[i])`."]
    check fixParentheses("a.nim", source, proofs).fixed.len == 1
    let unanswered = fixParentheses("a.nim", source, Proofs())
    check unanswered.source == source and unanswered.fixed.len == 0  # nothing proven, nothing
    check unanswered.asked == @[source]  # source holding candidate asks parser
    check checkParentheses("a.nim", source, Proofs()).len == 0  # check names none fix keeps
    check fixParentheses("a.nim", source, proofs).asked.len == 0  # answered source asks none
    check fixParentheses("a.nim", "let y = (a)\n", Proofs()).asked.len == 0  # no candidate


  test "candidates are three kinds alone, in source order, each with its spans":
    let groups = candidatesOf("let x = (|∙ m) + ■(n) * (a and b) + 2^(k)\n")
    check groups.mapIt(it.got) == @["(|∙ m)", "(n)", "(k)"]  # binary group no candidate
    check groups[0].opening == (8, 9) and groups[0].closing == (15, 16)  # `∙` three bytes
    check candidatesOf("let y = (\n  a) + b\n").len == 0  # spanning lines
