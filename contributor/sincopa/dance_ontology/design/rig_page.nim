## Write viewer page: markup, its two scripts, and faces it draws with.
##
##   Three built things are folded into one self-contained document, as
##     `design/wholecloth` folds its three: sweeps and stills recorded by
##     `design/rig`, and viewer compiled from `design/rig_view` by `nim js`.
##     Page is published as single file, so nothing may be left to fetch.
##   Page is laid out as reference page is, section by section and cell by
##     cell, with sim's own still of each cell drawn beside reference's drawing
##     of it.  Architect: lay reference and sim side by side so each cell can be
##     compared with what it looks like in model.  Cells are cut from built
##     reference page itself rather than drawn again, so what is compared is
##     what was ruled on, badge for badge.
##   Faces are inlined by `design/faces`, which also turns Commit Mono's
##     ligatures on at root.  Article X.8: presentation target ships faces it
##     draws with, never naming one reader may lack.
##
##   Usage: rig_page <dir>   reads design/rig.json, <dir>/rig_view.js and
##                           <dir>/review.html, writes <dir>/rig.html

{.experimental: "strictFuncs".}

import std/[json, os, strformat, strutils, tables]

import ./[faces, page]


const HEAD_BODY = """
<main class="rigview">
  <header>
    <p class="kicker">Body sim</p>
    <h1>The rig, as the engine holds it</h1>
    <p class="lede">The stage draws every capsule that the engine collides. Each one
      stands at the ends the engine reports, at the radius it collides on. The stage
      draws nothing else, and it leaves nothing out. The gap under the hips is the
      rig itself: the rig is the trunk upward, and it has no legs.</p>
    <p class="lede">Each body is lit from its own front. So the lighter side of a
      torso or a head is the side that dancer faces. The shape alone cannot say it,
      because a torso is symmetric front to back and a head is a sphere. To turn the
      view, drag it. To zoom, scroll.</p>
    <p class="lede">Below the stage, every still cell of the reference page stands as
      it stands there, with the sim's own still beside the drawing. The sim winds the couple to that
      facing, lifts their hands, and lets them stand. It keeps the
      standing distance whose pose sits easiest. To put a cell on the stage, click it.
      The arrows and the arrow keys walk from cell to cell, and the sweeps follow the
      stills in one list.</p>
  </header>

  <div class="rigwrap">
    <div class="stage"><canvas id="view"></canvas>
      <p class="where" id="where"></p></div>
    <aside class="panel">
      <div class="nav">
        <button id="prev" type="button" title="previous">&larr;</button>
        <select id="pick"></select>
        <button id="next" type="button" title="next">&rarr;</button>
      </div>
      <p class="verdict" id="verdict"></p>
      <div class="transport" id="transport">
        <button id="play" type="button">Pause</button>
        <input id="scrub" type="range" min="0" max="0" value="0" step="1">
      </div>
      <div class="ref" id="ref"></div>
      <div class="reads" id="reads"></div>
      <p class="note">A joint within five degrees of either end reads
        <span class="spent-key">spent</span>. Each range is the rig's own, for that
        arm. The twist of a shoulder is mirrored between left and right, so the two
        ends belong to the arm rather than to the table.</p>
    </aside>
  </div>
"""

const SHEET = """<style>
.rigview { max-width: 76rem; margin: 0 auto; padding: 2rem 1.5rem 4rem; }
.rigview header { max-width: 44rem; margin-bottom: 1.5rem; }
.rigview h1 { font-size: 1.6rem; line-height: 1.2; font-weight: 600; margin: 0.2rem 0 0.6rem; }
.rigview .lede { font: 0.95rem/1.55 var(--sans); color: var(--dim); margin: 0 0 0.6rem; }
.rigwrap { display: grid; grid-template-columns: minmax(0, 1fr) 20rem;
  gap: 1.25rem; align-items: start; }
.stage { background: var(--card); border: 1px solid var(--rule);
  border-radius: 0.4rem; padding: 0.5rem; position: relative; }
.stage canvas { width: 100%; height: 30rem; display: block; touch-action: none;
  cursor: grab; }
.where { position: absolute; left: 0.9rem; bottom: 0.7rem; margin: 0;
  font: 0.72rem/1 var(--mono); color: var(--dim); }
.panel { background: var(--card); border: 1px solid var(--rule);
  border-radius: 0.4rem; padding: 0.9rem; }
.nav { display: flex; gap: 0.4rem; align-items: center; }
.nav select { flex: 1; min-width: 0; font: 0.82rem/1.3 var(--sans);
  padding: 0.3rem; background: var(--paper); color: var(--ink);
  border: 1px solid var(--rule); border-radius: 0.25rem; }
.nav button { font: 600 0.8rem/1 var(--mono); padding: 0.4rem 0.55rem;
  background: var(--wash); color: var(--ink); border: 1px solid var(--rule);
  border-radius: 0.25rem; cursor: pointer; }
.verdict { font: 0.8rem/1.45 var(--sans); color: var(--ink);
  margin: 0.7rem 0 0.6rem; }
.transport { display: flex; gap: 0.5rem; align-items: center;
  margin-bottom: 0.8rem; }
.transport button { font: 600 0.62rem/1 var(--mono); letter-spacing: 0.1em;
  text-transform: uppercase; padding: 0.4rem 0.6rem; background: var(--wash);
  color: var(--ink); border: 1px solid var(--rule); border-radius: 0.25rem;
  cursor: pointer; }
.transport input { flex: 1; min-width: 0; }
.ref { margin: 0 0 0.8rem; }
.ref .art { position: relative; max-width: 14rem; }
.ref .art svg { display: block; width: 100%; height: auto; }
.ref figcaption { display: flex; flex-direction: column; gap: .1rem;
  font: .7rem/1.35 var(--sans); padding-top: .35rem; }
.ref code { font: .64rem var(--mono); color: var(--faint); }
.ref span { color: var(--dim); font: .64rem/1.3 var(--mono); }
.arm { margin-bottom: 0.7rem; }
.arm .who { font: 600 0.62rem/1 var(--mono); letter-spacing: 0.1em;
  text-transform: uppercase; color: var(--dim); margin: 0 0 0.3rem;
  display: flex; align-items: center; gap: 0.35rem; }
.arm .who i { width: 0.6rem; height: 0.6rem; border-radius: 50%; display: block; }
.dof { display: grid; grid-template-columns: 3.6rem 1fr 2.2rem 3.4rem;
  gap: 0.35rem; align-items: center; font: 0.64rem/1.4 var(--mono);
  color: var(--dim); }
.dof .track { position: relative; height: 0.42rem; background: var(--wash);
  border-radius: 0.21rem; }
.dof .track b { position: absolute; top: -0.1rem; width: 0.2rem;
  height: 0.62rem; background: var(--rule-strong); border-radius: 0.1rem;
  transform: translateX(-50%); }
.dof em { font-style: normal; text-align: right; color: var(--ink); }
.dof u { text-decoration: none; color: var(--faint); font-size: 0.9em; }
.dof.spent { color: var(--right); }
.dof.spent em { color: var(--right); font-weight: 700; }
.dof.spent .track b { background: var(--right); width: 0.3rem; }
.spent-key { color: var(--right); font-weight: 700; }
.note { font: 0.68rem/1.5 var(--sans); color: var(--faint);
  margin: 0.9rem 0 0; }
.cells { margin-top: 2rem; }
.cells .lede { font: 0.88rem/1.5 var(--sans); }
.pair { display: grid; grid-template-columns: 1fr 1fr; gap: .4rem;
  align-items: start; }
.pair .sim { min-width: 0; }
.thumb { display: block; width: 100%; aspect-ratio: 1 / 1; cursor: pointer;
  background: var(--paper); border-radius: 3px; }
.held { margin: .2rem 0 0; font: .6rem/1.3 var(--mono); color: var(--dim); }
figure.pic.picked { outline: 2px solid var(--ink); outline-offset: 2px; }
@media (max-width: 56rem) {
  .rigwrap { grid-template-columns: minmax(0, 1fr); }
  .stage canvas { height: 22rem; }
}
</style>"""


const TITLE* = "The Rig, as the Engine Holds It"
  ## Page's own name, after work's name: what browser tab and published gallery show.


func esc(s: string): string =
  s.multiReplace(("&", "&amp;"), ("<", "&lt;"), (">", "&gt;"))

func between(s, opener, closer: string; start: int): tuple[at, stop: int] =
  ## Where text between one opener and closer after it lies; `at` is -1 if none.
  let a = s.find(opener, start)
  if a < 0: return (-1, -1)
  let b = s.find(closer, a + opener.len)
  if b < 0: return (-1, -1)
  (a + opener.len, b)

func attribute(tag, name: string): string =
  ## One attribute's value off one opening tag.
  let (a, b) = between(tag, name & "=\"", "\"", 0)
  if a < 0: "" else: tag[a ..< b]


type Cell = object ## One still cell of reference page, as built page holds it.
  id: string
  asks: seq[string]  ## Questions it stands for, as `design/asks` keys them.
  classes: string    ## Its own classes, carrying kept and modelled.
  art: string        ## Inner markup of its drawing, badges and all.
  caption: string    ## Its caption, whole.

func cellsOf(html: string): Table[string, seq[Cell]] =
  ## Every still cell of reference page, by section letter, in page's order.
  ##   Cells are cut from built page, since drawing there is what was ruled on.
  var section = ""
  var at = 0
  while true:
    let h2 = html.find("<h2>", at)
    let fig = html.find("<figure class=\"pic", at)
    if fig < 0: break
    if h2 >= 0 and h2 < fig:
      section = $html[h2 + 4]
      at = h2 + 4
      continue
    let shut = html.find("</figure>", fig)
    doAssert shut > fig, "A cell on reference page never closes."
    let whole = html[fig ..< shut + "</figure>".len]
    at = shut + 1
    if section notin ["A", "B", "C", "D"]: continue
    let tagEnd = whole.find('>')
    let opening = whole[0 .. tagEnd]
    var cell = Cell(classes: attribute(opening, "class"))
    let asks = attribute(opening, "data-asks")
    if asks.len > 0: cell.asks = asks.split(' ')
    let (a, b) = between(whole, "<code>", "</code>", 0)
    doAssert a > 0, "A cell on reference page carries no identifier."
    cell.id = whole[a ..< b]
    let art = whole.find("<div class=\"art")
    doAssert art >= 0, &"A cell carries no drawing; got `{cell.id}`."
    let artOpen = whole.find('>', art) + 1
    let artShut = whole.find("</div>", artOpen)
    cell.art = whole[artOpen ..< artShut]
    let (c, d) = between(whole, "<figcaption>", "</figcaption>", 0)
    cell.caption = "<figcaption>" & whole[c ..< d] & "</figcaption>"
    result.mgetOrPut(section, @[]).add cell

func sheetOf(html: string): string =
  ## Reference page's own style, so its cells look here as they do there.
  var at = 0
  while true:
    let (a, b) = between(html, "<style>", "</style>", at)
    doAssert a >= 0, "Reference page carries no style block for its cells."
    let sheet = html[a ..< b]
    if ".pic {" in sheet: return "<style>" & sheet & "</style>"
    at = b


proc cellsBody(review: string; data: JsonNode): string =
  ## Lay every still cell out as reference page does, sim's still beside it.
  var entryOf: Table[string, int]
  var held: Table[string, string]
  for i, still in data["stills"].getElems:
    let key = still["key"].getStr
    entryOf[key] = i
    let apart = still["apart"].getFloat
    held[key] = (if still.hasKey("at") and still["at"].len > 0:
                   &"holds, stood {apart:.2f} m apart"
                 else: "no pose holds at any distance")
  let cells = cellsOf(review)
  const TITLES = [("A", "The standard diagram"),
                  ("B", "Single-hand turn positions"),
                  ("C", "The cross-name chain, face-to-face at rest"),
                  ("D", "The same-name chain, pillion lead at rest")]
  result.add """<section class="cells"><p class="lede">Every cell here is the
    reference page's own, badge for badge, with the sim's still beside it. A cell
    that folds several questions together shows the first of them. The picker above
    holds every one.</p>"""
  for (letter, title) in TITLES:
    result.add &"<h2>{letter} &middot; {esc(title)}</h2><div class=\"grid wide\">"
    for cell in cells.getOrDefault(letter):
      var entries: seq[string]
      for key in cell.asks:
        if key in entryOf: entries.add $entryOf[key]
      result.add &"""<figure class="{cell.classes}" data-id="{cell.id}" """ &
        &"""data-entries="{entries.join(" ")}"><div class="pair">""" &
        &"""<div class="art">{cell.art}</div><div class="sim">"""
      if entries.len > 0:
        result.add &"""<canvas class="thumb" data-entry="{entries[0]}"></canvas>""" &
          &"""<p class="held">{esc(held[cell.asks[0]])}</p>"""
      else:
        result.add """<p class="held">not asked of sim</p>"""
      result.add &"""</div></div>{cell.caption}</figure>"""
    result.add "</div>"
  result.add "</section></main>"


when isMainModule:
  let
    dir = if paramCount() >= 1: paramStr(1) else: "."
    data = "design" / "rig.json"
    view = dir / "rig_view.js"
    review = dir / "review.html"
  if not fileExists(data):
    quit(&"Viewer page has no sweeps; run `nim r tools/build.nim rig`: got `{data}`.", 1)
  if not fileExists(view):
    quit(&"Viewer page has no viewer; run `pages` first: got `{view}`.", 1)
  if not fileExists(review):
    quit(&"Viewer page has no reference to lay beside; run `pages` first: got `{review}`.", 1)
  let
    reviewHtml = readFile(review)
    dataText = readFile(data).strip()
    html = document(TITLE,
                    sheetOf(reviewHtml) & SHEET & HEAD_BODY &
                    cellsBody(reviewHtml, parseJson(dataText)) &
                    "<script>var RIG = " & dataText & ";</script>\n" &
                    "<script>" & readFile(view) & "</script>\n")
  writeFile(dir / "rig.html", withFaces(html))
  echo "wrote ", dir / "rig.html"
