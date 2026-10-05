## Replicate rule of `parentheses.nim` header: parentheses around prefix term or plain operand
##   beside binary operator, and around plain operand after prefix operator, go; every other
##   group stays, and fix changes nothing second time.

{.experimental: "strictFuncs".}

import std/[sequtils, strutils, unittest]
import ../../src/knoller/[parentheses, reports]


func fixed(source: string): string =
  ## Fix parentheses of source, as `koch fix` does.
  fixParentheses("a.nim", source).source


func isSettled(source: string): bool =
  ## Decide whether source reports no parentheses finding and fixes to itself again.
  checkParentheses("a.nim", source).len == 0 and source.fixed == source and
    fixParentheses("a.nim", source).fixed.len == 0



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
      check checkParentheses("a.nim", breach).len == count
      check breach.fixed == mended
      check mended.isSettled  # second run writes nothing
    check checkParentheses("a.nim", "let c = ☆(m) ∧ n\n")[0].message.endsWith("got `(m)`.")


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
