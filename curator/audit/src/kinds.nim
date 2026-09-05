## Register file kinds checker reads: comment syntax and prose rule per kind.
##   Kind absent from registry is kind checker does not read; layout check rejects such
##   file (Article VI.5), so extending registry is curator work done before new kind lands.
##
##   |---------------|----------------------------|-------------|-------|
##   | Kind          | Match                      | Syntax      | Prose |
##   |---------------|----------------------------|-------------|-------|
##   | Nim           | .nim                       | Nim         | yes   |
##   | NimScript     | .nims                      | Nim         | yes   |
##   | Nimble        | .nimble                    | Nim         | yes   |
##   | Cfg           | .cfg                       | Hash        | yes   |
##   | Markdown      | .md                        | None        | no    |
##   | Yaml          | .yml .yaml                 | HashSpaced  | yes   |
##   | GitIgnore     | .gitignore                 | HashLeading | yes   |
##   | GitAttributes | .gitattributes             | HashLeading | yes   |
##   | TypeScript    | .ts                        | Slash       | yes   |
##   | Json          | .json atlas.config atlas.lock | None     | no    |
##   |---------------|----------------------------|-------------|-------|
##
##   Markdown is prose document, not comment: telegraphic rule (VI.5) covers comments only,
##     and CONSTITUTION.md itself uses articles. Form rules still apply to it.
##   Nimble files are NimScript; Cfg covers `nim.cfg` Atlas writes and `koch.nim.cfg`.
##   TypeScript and Json registered ahead of use: owner allows TypeScript where JavaScript
##     is forced, and its tooling needs JSON configuration.
##   Retired: Makefile, with make itself; registry admits no second build verb.
##
##   Cost: match is by basename or extension only, so `nimble.paths` or `.mk` is unread.

{.experimental: "strictFuncs".}

import std/[options, os]


type
  Syntax* {.pure.} = enum
    ## Define how comments are found in file kind.
    None         ## No comments (JSON), or prose document (Markdown).
    Nim          ## `#` line, `#[ ]#` nesting block, outside string and char literals.
    Hash         ## `#` anywhere unless escaped as `\#` (cfg).
    HashSpaced   ## `#` at line start or after whitespace, outside quotes (YAML).
    HashLeading  ## `#` as first non-blank character only (.gitignore).
    Slash        ## `//` line and `/* */` block, outside string and template literals.

  Kind* {.pure.} = enum
    ## Define file kinds checker reads.
    Nim, NimScript, Nimble, Cfg, Markdown, Yaml, GitIgnore, GitAttributes, TypeScript, Json

  KindRule* = object
    ## Define how one kind is read.
    syntax*: Syntax   ## Comment syntax scanner applies.
    is_prose*: bool   ## Telegraphic check applies to comments.


const lut_kind_rule*: array[Kind, KindRule] = [
  Kind.Nim: KindRule(syntax: Syntax.Nim, is_prose: true),
  Kind.NimScript: KindRule(syntax: Syntax.Nim, is_prose: true),
  Kind.Nimble: KindRule(syntax: Syntax.Nim, is_prose: true),
  Kind.Cfg: KindRule(syntax: Syntax.Hash, is_prose: true),
  Kind.Markdown: KindRule(syntax: Syntax.None),
  Kind.Yaml: KindRule(syntax: Syntax.HashSpaced, is_prose: true),
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
  of ".gitignore": return some(Kind.GitIgnore)
  of ".gitattributes": return some(Kind.GitAttributes)
  of "atlas.config", "atlas.lock": return some(Kind.Json)
  else: discard
  case ext
  of ".nim": some(Kind.Nim)
  of ".nims": some(Kind.NimScript)
  of ".nimble": some(Kind.Nimble)
  of ".cfg": some(Kind.Cfg)
  of ".md": some(Kind.Markdown)
  of ".yml", ".yaml": some(Kind.Yaml)
  of ".ts": some(Kind.TypeScript)
  of ".json": some(Kind.Json)
  else: none(Kind)


func rule*(kind: Kind): lent KindRule =
  ## Read rule of kind.
  lut_kind_rule[kind]
