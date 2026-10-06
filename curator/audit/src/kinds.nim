## Register file kinds checker reads: comment syntax and prose rule per kind.
##   Kind absent from registry is kind checker does not read; layout check rejects such
##   file (Article VI.5), so extending registry is curator work done before new kind lands.
##
##   |---------------|-------------------------------|-------------|-------|------|-------|
##   | Kind          | Match                         | Syntax      | Prose | Gate | Guide |
##   |---------------|-------------------------------|-------------|-------|------|-------|
##   | Nim           | .nim                          | Nim         | yes   | no   | yes   |
##   | NimScript     | .nims                         | Nim         | yes   | no   | yes   |
##   | Nimble        | .nimble                       | Nim         | yes   | no   | yes   |
##   | Configuration | .cfg                          | Hash        | yes   | no   | no    |
##   | Markdown      | .md                           | None        | no    | no   | no    |
##   | Yaml          | .yml .yaml                    | HashSpaced  | yes   | no   | no    |
##   | GitIgnore     | .gitignore                    | HashLeading | yes   | no   | no    |
##   | GitAttributes | .gitattributes                | HashLeading | yes   | no   | no    |
##   | TypeScript    | .ts                           | Slash       | yes   | yes  | no    |
##   | Cpp           | .cpp .hpp                     | Slash       | yes   | yes  | no    |
##   | C             | .c .h                         | Slash       | yes   | yes  | no    |
##   | Html          | .html                         | Xml         | yes   | no   | no    |
##   | Svg           | .svg                          | Xml         | yes   | no   | no    |
##   | Json          | .json atlas.config atlas.lock | None        | no    | no   | no    |
##   | Shell         | .sh pre-push commit-msg       | Hash        | yes   | yes  | no    |
##   |---------------|-------------------------------|-------------|-------|------|-------|
##
##   Gated kind is one owner admits only where Nim cannot serve; `justification.nim` demands
##     each such file argue for itself in its header, so gate is checked rather than trusted.
##   Guide marks kind whose language has style guide; `koch fix` writes that kind alone, since
##     fixer applies guide. STYLE.md is guide of Nim, and Nim, NimScript and nimble are Nim
##     source, registered with Nim syntax; no other language has guide yet. Checks read every
##     kind still, so finding in other kind stays for hand.
##
##   Markdown is prose document, not comment: telegraphic rule (VI.5) covers comments only,
##     and CONSTITUTION.md itself uses articles. Form rules still apply to it.
##   Nimble files are NimScript; Configuration covers `nim.cfg` Atlas writes and `koch.nim.cfg`.
##   TypeScript and Json registered ahead of use: owner allows TypeScript where JavaScript
##     is forced, and its tooling needs JSON configuration.
##   Cpp and C carry binding shim for library no Nim import expresses; `.hpp` is C++ header
##     and `.h` is C one, since name alone cannot tell them apart.
##   Retired: Makefile, with make itself; registry admits no second build verb.
##   Shell carries hook glue alone: command Claude Code runs, and script git runs as hook;
##     both exist before any Nim can run, so each argues for itself in its header.
##   Html and Svg carry hand-written pages, which live in project's `pages/` or `mockups/`
##     (layout check); generated markup is one long line and fails width, so registry admits
##     what hand writes and rejects what build emits.
##
##   Cost: match is by basename or extension only, so `nimble.paths` or `.mk` is unread.

{.experimental: "strictFuncs".}

import std/[options, os]
from ../../knoller/src/knoller import Dialect


type
  Syntax* {.pure.} = enum  ## Define how comments are found in file kind.
    None  ## No comments (JSON), or prose document (Markdown).
    Nim  ## `#` line, `#[ ]#` nesting block, outside string and char literals.
    Hash  ## `#` anywhere unless escaped as `\#` (cfg).
    HashSpaced  ## `#` at line start or after whitespace, outside quotes (YAML).
    HashLeading  ## `#` as first non-blank character only (.gitignore).
    Slash  ## `//` line and `/* */` block, outside string and template literals.
    Xml  ## `<!-- -->` block, spanning lines (HTML, SVG).

  Kind* {.pure.} = enum  ## Define file kinds checker reads.
    Nim, NimScript, Nimble, Configuration, Markdown, Yaml, GitIgnore, GitAttributes, TypeScript,
    Cpp, C, Html, Svg, Json, Shell

  KindRule* = object  ## Define how one kind is read.
    syntax*: Syntax  ## Comment syntax scanner applies.
    is_prose*: bool  ## Telegraphic check applies to comments.
    is_gated*: bool  ## Language admitted only where Nim cannot serve, so header must argue.
    has_guide*: bool  ## Language has style guide, so `koch fix` writes kind.


const LUT_RULE_BY_KIND*: array[Kind, KindRule] = [
  Kind.Nim: KindRule(syntax: Syntax.Nim, is_prose: true, has_guide: true),
  Kind.NimScript: KindRule(syntax: Syntax.Nim, is_prose: true, has_guide: true),
  Kind.Nimble: KindRule(syntax: Syntax.Nim, is_prose: true, has_guide: true),
  Kind.Configuration: KindRule(syntax: Syntax.Hash, is_prose: true),
  Kind.Markdown: KindRule(syntax: Syntax.None),
  Kind.Yaml: KindRule(syntax: Syntax.HashSpaced, is_prose: true),
  Kind.GitIgnore: KindRule(syntax: Syntax.HashLeading, is_prose: true),
  Kind.GitAttributes: KindRule(syntax: Syntax.HashLeading, is_prose: true),
  Kind.TypeScript: KindRule(syntax: Syntax.Slash, is_prose: true, is_gated: true),
  Kind.Cpp: KindRule(syntax: Syntax.Slash, is_prose: true, is_gated: true),
  Kind.C: KindRule(syntax: Syntax.Slash, is_prose: true, is_gated: true),
  Kind.Html: KindRule(syntax: Syntax.Xml, is_prose: true),
  Kind.Svg: KindRule(syntax: Syntax.Xml, is_prose: true),
  Kind.Json: KindRule(syntax: Syntax.None),
  Kind.Shell: KindRule(syntax: Syntax.Hash, is_prose: true, is_gated: true),
]
  ## Map kind to its rule; header table is derived view of this array.


func kindOf*(path: string): Option[Kind] =
  ## Classify path by basename, then extension; `none` for unregistered kind.
  let (_, base, ext) = path.splitFile
  case base & ext
  of ".gitignore": return some(Kind.GitIgnore)
  of ".gitattributes": return some(Kind.GitAttributes)
  of "atlas.config", "atlas.lock": return some(Kind.Json)
  of "pre-push", "commit-msg": return some(Kind.Shell)
  else: discard
  case ext
  of ".nim": some(Kind.Nim)
  of ".nims": some(Kind.NimScript)
  of ".nimble": some(Kind.Nimble)
  of ".cfg": some(Kind.Configuration)
  of ".md": some(Kind.Markdown)
  of ".yml", ".yaml": some(Kind.Yaml)
  of ".ts": some(Kind.TypeScript)
  of ".cpp", ".hpp": some(Kind.Cpp)
  of ".c", ".h": some(Kind.C)
  of ".html": some(Kind.Html)
  of ".svg": some(Kind.Svg)
  of ".json": some(Kind.Json)
  of ".sh": some(Kind.Shell)
  else: none(Kind)


func rule*(kind: Kind): lent KindRule =
  ## Read rule of kind.
  LUT_RULE_BY_KIND[kind]


func dialectOf*(kind: Kind): Dialect =
  ## Read dialect of knoller kind of Nim source is: module, script or package; every other kind
  ##   reads as module, and no caller asks of one.
  case kind
  of Kind.NimScript: Dialect.Script
  of Kind.Nimble: Dialect.Package
  else: Dialect.Module
