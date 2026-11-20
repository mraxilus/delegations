## Report each constructor package calls both by dot and by prefix call, since subject test of
##   STYLE.md §5 gives one answer for one routine, so calls of one constructor take one form.
##   Caller counts calls of each constructor across package (`callsConstructor`), and passes
##     them in (`NamesPackage`), since rule reads one file.
##   Check counts and reports nothing yet: rule 15 of #443 lands in its build.

{.experimental: "strictFuncs".}

import ./reports


type Calls* = object  ## Define calls of one constructor across package, by form.
  name*: string  ## Constructor, as `initElement`.
  dotted*: int  ## Calls taking dot on plain receiver.
  prefixed*: int  ## Calls taking prefix call on plain first argument.


func callsConstructor*(sources: openArray[string]): seq[Calls] =
  ## Count calls of each constructor sources declare, by form, across them: modules of package.
  discard


func checkConstructors*(path, source: string; calls: openArray[Calls]): seq[Report] =
  ## Report each call of constructor in form fewer calls across package take, or in either form
  ##   where they tie (STYLE.md §5); `calls` counts each across package.
  discard
