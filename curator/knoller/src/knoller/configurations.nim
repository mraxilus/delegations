## Enforce that definitions of one configuration standing next to each other share one block, and
##   that configuration build gets by default comes first (Article X.11), and fix both (`koch
##   fix`), as Architect ruled on rule 14 of #443.
##   Checks report nothing yet, and fixer changes nothing yet; build of rule fills them.

{.experimental: "strictFuncs".}

import ./reports


func readConfigurations*(sources: openArray[string]): Configurations =
  ## Read default of each configuration constant of package, from its modules.
  discard


func checkConfigurations*(path, source: string; configurations: Configurations): seq[Report] =
  ## Report blocks of one configuration side by side, and two-way branch putting default last.
  discard


func fixConfigurations*(path, source: string; configurations: Configurations): Fix =
  ## Join blocks of one configuration side by side, and swap two-way branch putting default last.
  Fix(source: source)
