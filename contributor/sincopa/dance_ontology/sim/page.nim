## Drive body sim from browser, as way of poking at constraints.
##
##   Page exists because still figure cannot settle question it
##     is drawn to settle.  Turn body here and arms take pose
##     solver finds; keep turning and joint runs out, and page says
##     which.
##   Nothing here decides what arms do: `sim/carry` holds model this
##     mounts, listens for and draws, and is driven under test where this
##     cannot be, since `std/dom` builds only on JS backend.

{.experimental: "strictFuncs".}

import std/[dom, options, strformat, strutils]

import ./[body, carry, draw, solve, sweep]


#[ Page ]#

proc mount() =
  ## Put controls on page, once.
  var holds = ""
  for i, h in HOLDS:
    holds.add &"""<button id="hd{i}" data-hold="{i}" class="pick">{esc(h.name)}</button>"""
  var levels = ""
  for i, (name, b) in LEVELS:
    levels.add &"""<button id="lv{i}" data-level="{i}" class="pick">{name}</button>"""
  var turns = ""
  for w in Way:
    turns.add &"""<div class="picks"><span class="way">{WAYS[w]}</span>""" &
      &"""<button data-way="{ord(w)}" data-sign="1" class="pick turn" """ &
      &"""title="a quarter, anticlockwise seen from above">&#x21BA; &frac14;</button>""" &
      &"""<button data-way="{ord(w)}" data-sign="-1" class="pick turn" """ &
      &"""title="a quarter, clockwise seen from above">&frac14; &#x21BB;</button></div>"""
  document.getElementById("app").innerHTML = cstring(
    """<div class="stage" id="stage"></div>""" &
    &"""<div class="panel"><div class="picks">{holds}</div>""" &
    &"""<div class="picks">{levels}</div>{turns}""" &
    """<div class="picks"><button id="reset" class="pick">face to face again</button></div>""" &
    """<button id="sweep" class="pick">""" &
    """sweep the follow's turn (about three minutes)</button></div>""" &
    """<div class="says-wrap"><div id="says"></div>""" &
    """<div id="limit"></div></div>""")


proc paint()


proc render() =
  ## Redraw what state says, leaving controls where they are.
  for i, h in HOLDS:
    document.getElementById(cstring(&"hd{i}")).className =
      cstring(if i == hold: "pick on" else: "pick")
  for i, (name, b) in LEVELS:
    document.getElementById(cstring(&"lv{i}")).className =
      cstring(if i == level: "pick on" else: "pick")
  if carried.isNone or carriedKey != keyOf(world()):
    settleFresh()
  let arrived = walked()
  let turning = document.querySelectorAll("button.turn")
  for i in 0 ..< turning.len:
    let b = cast[Element](turning[i])
    if arrived: b.removeAttribute("disabled")
    else: b.setAttribute("disabled", "")
  if not arrived:
    paint()
  if carried.isNone:
    let s = world()
    document.getElementById("stage").innerHTML = cstring(
      draw.plan(s, Verdict()) & draw.elevation(s, Verdict()))
    document.getElementById("says").innerHTML = cstring(
      """<p class="none">No pose holds here: no way of laying the arms keeps every joint """ &
      """in its range and every arm out of every body.</p>""")
    return
  let
    s = carried.get.state
    v = carried.get.verdict
  document.getElementById("stage").innerHTML =
    cstring(draw.plan(s, v) & draw.elevation(s, v))
  document.getElementById("says").innerHTML = cstring(readout(s, v))


var pending = false ## Whether redraw is already booked for next frame.


proc paint() =
  ## Redraw at most once per frame, however fast controls are pressed;
  ## and again after, while quarter is still being walked.
  if pending:
    return
  pending = true
  discard window.requestAnimationFrame(proc (time: float) =
    pending = false
    render())


proc sweepNow() =
  ## Turn follow from rest until something gives, and say where.
  ##   From rest page found: face to face, at distance
  ##     couple settled to there, which sweep then keeps.
  let s = world(restApart)
  document.getElementById("limit").innerHTML = cstring(
    """<p class="limit">Sweeping&hellip; a fiftieth of a turn at a time, each way, """ &
    """until a joint runs out. In a browser this takes about three minutes.</p>""")
  discard setTimeout(proc () =
    let sw = swept(s, Body.Two, most = 1.5)
    if not sw.restHolds:
      document.getElementById("limit").innerHTML = cstring(
        """<p class="limit">No pose holds at the rest, so there is nothing to turn.</p>""")
      return
    func line(b: Block): string =
      if not b.stopped: "no block within a turn and a half"
      else: &"blocks at {formatFloat(b.at, ffDecimal, 2)} turns: {says(sw.rest, b.why)}" &
        (if b.foundAnyway: " (a pose holds a step beyond, but not one the arms can reach)" else: "")
    document.getElementById("limit").innerHTML = cstring(
      &"""<p class="limit">From rest, face to face, standing {turns(restApart)} m apart: """ &
      &"""turning the follow clockwise <b>{line(sw.neg)}</b>; """ &
      &"""anticlockwise <b>{line(sw.pos)}</b>. Nothing in the model holds those numbers; """ &
      &"""they are found by turning until something gives.</p>"""), 30)


proc handle(event: Event) =
  let target = event.target
  if target == nil:
    return
  if target.getAttribute("data-hold") != nil:
    hold = parseInt($target.getAttribute("data-hold"))
    carried = none(Solved)
    paint()
  elif target.getAttribute("data-level") != nil:
    level = parseInt($target.getAttribute("data-level"))
    carried = none(Solved)
    paint()
  elif target.getAttribute("data-way") != nil:
    if inFlight.isNone and carried.isSome:
      inFlight = some(Move(way: Way(parseInt($target.getAttribute("data-way"))),
                           sign: parseFloat($target.getAttribute("data-sign"))))
      moveStart = carried
      tallyStart = tally
      reseedsStart = reseeds
      done = 0.0
      blocked = none(Verdict)
      paint()
  elif $target.getAttribute("id") == "reset":
    carried = none(Solved)
    paint()
  elif $target.getAttribute("id") == "sweep":
    sweepNow()


when isMainModule:
  document.addEventListener("click", handle)
  mount()
  render()
