## Register file kinds checker reads: comment syntax and form rule per kind.
##   Kind absent from registry is kind checker does not read; layout check rejects such
##   file (Article VI.5), so extending registry is curator work done before new kind lands.
##
##   |---------------|----------------|-------------|-------|------------|
##   | Kind          | Match          | Syntax      | Prose | Recipe tab |
##   |---------------|----------------|-------------|-------|------------|
##   | Nim           | .nim           | Nim         | yes   | no         |
##   | NimScript     | .nims          | Nim         | yes   | no         |
##   | Markdown      | .md            | None        | no    | no         |
##   | Yaml          | .yml .yaml     | HashSpaced  | yes   | no         |
##   | Makefile      | Makefile       | Hash        | yes   | yes        |
##   | GitIgnore     | .gitignore     | HashLeading | yes   | no         |
##   | GitAttributes | .gitattributes | HashLeading | yes   | no         |
##   | TypeScript    | .ts            | Slash       | yes   | no         |
##   | Json          | .json          | None        | no    | no         |
##   |---------------|----------------|-------------|-------|------------|
##
##   Markdown is prose document, not comment: telegraphic rule (VI.5) covers comments only,
##     and CONSTITUTION.md itself uses articles. Form rules still apply to it.
##   TypeScript and Json registered ahead of use: owner allows TypeScript where JavaScript
##     is forced, and its tooling needs JSON configuration.
##
##   Cost: match is by basename or extension only, so `Makefile.inc` or `.mk` is unread.

{.experimental: "strictFuncs".}

import std/[options, os]


type
  Syntax* {.pure.} = enum
    ## Define how comments are found in file kind.
    None         ## No comments (JSON), or prose document (Markdown).
    Nim          ## `#` line, `#[ ]#` nesting block, outside string and char literals.
    Hash         ## `#` anywhere unless escaped as `\#` (Makefile).
    HashSpaced   ## `#` at line start or after whitespace, outside quotes (YAML).
    HashLeading  ## `#` as first non-blank character only (.gitignore).
    Slash        ## `//` line and `/* */` block, outside string and template literals.

  Kind* {.pure.} = enum
    ## Define file kinds checker reads.
    Nim, NimScript, Markdown, Yaml, Makefile, GitIgnore, GitAttributes, TypeScript, Json

  KindRule* = object
    ## Define how one kind is read and formed.
    syntax*: Syntax         ## Comment syntax scanner applies.
    is_prose*: bool         ## Telegraphic check applies to comments.
    has_recipe_tab*: bool   ## Tab allowed as first character of line (make recipes).


const lut_kind_rule*: array[Kind, KindRule] = [
  Kind.Nim: KindRule(syntax: Syntax.Nim, is_prose: true),
  Kind.NimScript: KindRule(syntax: Syntax.Nim, is_prose: true),
  Kind.Markdown: KindRule(syntax: Syntax.None),
  Kind.Yaml: KindRule(syntax: Syntax.HashSpaced, is_prose: true),
  Kind.Makefile: KindRule(syntax: Syntax.Hash, is_prose: true, has_recipe_tab: true),
  Kind.GitIgnore: KindRule(syntax: Syntax.HashLeading, is_prose: true),
  Kind.GitAttributes: KindRule(syntax: Syntax.HashLeading, is_prose: true),
  Kind.TypeScript: KindRule(syntax: Syntax.Slash, is_prose: true),
  Kind.Json: KindRule(syntax: Syntax.None),
]
  ## Map kind to its rule; header table is derived view of this array.


func kindOf*(path: string): Option[Kind] =
  ## Classify path by basename, then extension; `none` for unregistered kind.
  let (_, base, ext) = path.splitFile
  case base & ext
  of "Makefile": return some(Kind.Makefile)
  of ".gitignore": return some(Kind.GitIgnore)
  of ".gitattributes": return some(Kind.GitAttributes)
  else: discard
  case ext
  of ".nim": some(Kind.Nim)
  of ".nims": some(Kind.NimScript)
  of ".md": some(Kind.Markdown)
  of ".yml", ".yaml": some(Kind.Yaml)
  of ".ts": some(Kind.TypeScript)
  of ".json": some(Kind.Json)
  else: none(Kind)


func rule*(kind: Kind): lent KindRule =
  ## Read rule of kind.
  lut_kind_rule[kind]
