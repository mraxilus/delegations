## Enforce glossary shape: Matt Pocock's CONTEXT.md format under name GLOSSARY.md.
##   Shape: `# <Name>` heading, description, `## Language` heading, then entries of form
##     `**Term**:` line, definition line(s), optional `_Avoid_:` line.
##   Check demands heading, `## Language`, and definition after every term; it never judges
##     content, which is contributor's and owner's work.
##
##   Cost: zero terms pass; format creates entries lazily as terms resolve.

{.experimental: "strictFuncs".}

import std/strutils
import ./[findings, markdown]


func isTermLine*(line: string): bool =
  ## Decide whether line opens glossary entry, i.e. `**Term**:`.
  line.len > 5 and line.startsWith("**") and line.endsWith("**:")


func checkGlossary*(path, source: string): seq[Finding] =
  ## Report missing headings and terms lacking definition.
  if not source.firstNonBlank.startsWith("# "):
    result.add finding(path, 1, "Glossary must open with `# <Name>` heading.")
  if "## Language" notin source.headingLines:
    result.add finding(path, 0, "Glossary lacks `## Language` heading.")
  let lines = source.splitLines
  for i, line in lines:
    if not line.isTermLine: continue
    let next = if i + 1 < lines.len: lines[i + 1] else: ""
    let is_defined = next.strip.len > 0 and not next.startsWith("#") and
      not next.isTermLine and not next.startsWith("_Avoid_")
    if not is_defined:
      result.add finding(
        path, i + 1, "Term lacks definition on next line; got `" & line[2 ..< line.len - 3] & "`."
      )
