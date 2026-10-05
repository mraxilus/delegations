## Run `Declarations` suite: one module of shared suite, which `../suites.nim` imports in order.

{.experimental: "strictFuncs".}

import ./fixtures
import ../../tools/declarations



suite "Declarations":
  test "every parameter reaches its declaration, one whose literal fixes its type included":
    # Article X.12 drops type where literal default fixes it, so `koch fix` wrote
    #   `is_tally_skipped = false` on `nimBuildFrame`. Reading took type from colon alone and
    #   dropped that parameter, so page's sixth argument failed `types` with `TS2554`.
    check declarationOf("proc nimBuildFrame(handle: cint; is_tally_skipped = false)") ==
      "declare function nimBuildFrame(handle: number, is_tally_skipped: boolean): void;"
    check declarationOf("""func nimSized(count = 3, scale = 1.5, label = "a"): cint""") ==
      "declare function nimSized(count: number, scale: number, label: string): number;"
    check declarationOf("proc nimShared(is_shown, is_held = false)") ==
      "declare function nimShared(is_shown: boolean, is_held: boolean): void;"
    check declarationOf("proc nimTyped(count: cint = 2)") ==
      "declare function nimTyped(count: number): void;"


  test "a parameter whose type cannot be read leaves no declaration, never one short":
    # Declaration one parameter short lets page omit that argument, and `undefined` then
    #   passes type check. Absent declaration fails at every call, naming export.
    check declarationOf("proc nimNamed(count: cint, scale = SCALE_DEFAULT)") == ""
    check declarationOf("proc nimBare(count: cint, scale)") == ""
