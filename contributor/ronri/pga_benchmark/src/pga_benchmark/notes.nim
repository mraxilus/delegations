## Read notes on library source, each anchored by quote, and locate them at pin.
##   Marginalia is library read at pin with notes in its margin. Note is Markdown section:
##
##     ```
##     ## Out-of-range grade                 title
##     `pga/multivectors.nim` · decide       file quoted, then status
##     (fence)                               lines of library note is about, verbatim
##     Body, any Markdown.                   what note says
##     ```
##
##   Anchor is quote, never line number: quote that still occurs once at pin is note still
##     about same lines, wherever they moved, and quote that does not is note gone stale.
##     Stale note is finding, so page never points at lines that say something else.
##   Line shown on page is computed at build from where quote stands, never written by hand.
##
##   Cost: two notes may quote same lines; each is its own anchor, and page shows both.

{.experimental: "strictFuncs".}

import std/[strutils, tables]

import ./[changes, guard, markdown]


type
  Note* = object  ## Define one note on library source.
    title*: string  ## Heading of section.
    path*: string  ## Library-relative file quoted, as `pga/multivectors.nim`.
    status*: string  ## Short verdict after file, as `decide`; empty where file gives none.
    quote*: string  ## Lines of library note is about, verbatim at pin.
    body*: seq[Block]  ## Blocks after quote.
    line*: int  ## Line of notes file section opens on, for findings.
  Notes* = object  ## Define whole notes file: blocks before first note, then notes in order.
    lead*: seq[Block]  ## Blocks before first note, title included.
    items*: seq[Note]  ## Notes in file order.


const STATUS_JOIN = " · "  ## Text between quoted file and status in note's first line.



#[ Parsing ]#

func parseNotes*(path, source: string): (Notes, seq[Finding]) =
  ## Read notes file at path; section without file line or fence is finding.
  let blocks = parseBlocks(source)
  var
    notes: Notes
    findings: seq[Finding]
    i = 0

  # Take lead up to first note.
  while i < blocks.len and not (blocks[i].kind == KindBlock.Heading and blocks[i].level == 2):
    notes.lead.add blocks[i]
    inc i

  # Take each note: heading, file line, fence, then body up to next note.
  while i < blocks.len:
    let heading = blocks[i]
    inc i
    var note = Note(title: heading.lines[0], line: heading.line)
    let has_file = i < blocks.len and blocks[i].kind == KindBlock.Paragraph and
        blocks[i].lines[0].startsWith("`")
    if not has_file or i + 1 >= blocks.len or blocks[i+1].kind != KindBlock.Fence:
      findings.add Finding(
        path: path,
        line: heading.line,
        message: "Note needs file line and quoted fence; got `" & note.title & "`.",
      )
      while i < blocks.len and not (blocks[i].kind == KindBlock.Heading and blocks[i].level == 2):
        inc i
      continue
    let
      first = blocks[i].lines.join(" ")
      close = first.find('`', 1)
    note.path = if close > 1: first[1..<close] else: ""
    let joined = first.find(STATUS_JOIN)
    if joined >= 0: note.status = first[joined+STATUS_JOIN.len .. ^1].strip
    note.quote = blocks[i+1].lines.join("\n")
    i += 2
    while i < blocks.len and not (blocks[i].kind == KindBlock.Heading and blocks[i].level == 2):
      note.body.add blocks[i]
      inc i
    notes.items.add note
  (notes, findings)



#[ Anchors ]#

func checkAnchors*(notes: Notes, files: Table[string, string], source: string): seq[Finding] =
  ## Hold every note's quote to library at pin: its file exists and quote occurs once.
  for note in notes.items:
    if note.path notin files:
      result.add Finding(
        path: source,
        line: note.line,
        message: "Note quotes no library file; got `" & note.path & "`.",
      )
      continue
    let count = files[note.path].count(note.quote)
    if count != 1:
      result.add Finding(
        path: source,
        line: note.line,
        message: "Note's quote must occur once at pin; got `" & $count & "` in `" &
            note.path & "`.",
      )


func lineAt*(note: Note, files: Table[string, string]): int =
  ## Read line note's quote opens on at pin; zero where file or quote is absent.
  if note.path notin files: 0 else: files[note.path].lineOf(note.quote)
