discard """
action: run
targets: "js"
cmd: "nim $target --hints:off -d:testing -d:nodejs -d:nimUnittestAbortOnError:on $options $file"
"""
## Hold whole-cloth page to draw every moment of its recording, each at its own place of play.
##   Page plays sweep by place, and draws what lies between two moments either side of it
##     (`wholecloth_scene.fillScene`).  Moment that no place reaches is pose page never draws.
##   Law calls page's own lookup over page's own recording, read through node as page reads
##     it: law runs where mechanism runs (Article IX.5).
##   Runs on JS target alone, because lookup reads recording as `JsObject`.

{.experimental: "strictFuncs".}

when compileOption("profiler"): import std/nimprof

import std/[jsffi, math, os, strutils, unittest]

import ../design/wholecloth_scene


const
  KEPT_TURNS = currentSourcePath().parentDir.parentDir / "design" / "turns.json"
    ## Recording page plays (`design/turns`), read where this file was compiled.
  FLOOR_MOMENTS = 1387
    ## Least moments read: half of 2775, every moment of eighteen sweeps, read 2026-10-17.
    ##   Reader that loses its way, by wrong file or wrong keys, reads nearly none.
  FLOOR_RUNS = 6
    ## Least turns read that hold several poses: half of 12, six in each chain held above, read
    ##   2026-10-17.
  REACH = 1.0  ## Furthest drawn joint may lie from its moment's, in millimetres: rounding alone.


proc readText(path: cstring): cstring {.importjs: "require('fs').readFileSync(#, 'utf8')".}
  ## Read whole file as text, through node.

func toJsObject(text: cstring): JsObject {.importjs: "JSON.parse(#)".}
  ## Read JSON text as object, read in place as page reads it.


func reach(scene: Scene, moment: JsObject): float =
  ## Measure furthest any joint of `scene` lies from same joint of `moment`, in millimetres.
  for i in 0..<scene.connection_count:
    let connection = moment.connections[i]
    for k in 0..<4:
      var lead, follow = 0.0
      for axis in 0..<3:
        lead += (scene.connections[i].lead[k][axis] - connection.lead[k][axis].to(float))^2
        follow += (scene.connections[i].follow[k][axis] - connection.follow[k][axis].to(float))^2
      result = max(result, sqrt(max(lead, follow)))



suite "Internal: The whole-cloth page plays every recorded moment":
  test "each moment of each sweep is drawn at its own place":
    ## Page drawn at place of each moment shows that moment, within `REACH`.
    ##   Domain: every moment of every sweep of `design/turns.json`.
    ##   Regression of pull request 629, as found on 2026-10-12: page found moments by turn,
    ##     so at turn where plan poses arms again it drew first and last pose alone, and jumped
    ##     492 mm in no time in `L-r.R-l|above` at 0.02 of turn.
    let sweeps = readText(cstring(KEPT_TURNS)).toJsObject.sweeps
    var
      scene: Scene
      missed: seq[string]
      read = 0
      worst = 0.0
    for key in sweeps.keys:
      let frames = sweeps[key].frames
      for k in 0..<frames.length.to(int):
        inc read
        doAssert fillScene(scene, frames, placeOf(frames[k])),
          "Sweep that holds moments draws one; got none at `" & $key & "`."
        let away = reach(scene, frames[k])
        worst = max(worst, away)
        if away > REACH:
          missed.add $key & " at " & $frames[k].turn.to(float) & " (" &
              formatFloat(away, ffDecimal, 0) & " mm)"
    checkpoint "Moments read: `" & $read & "`.  Not drawn: `" & $missed.len &
        "`, furthest: `" & formatFloat(worst, ffDecimal, 0) & " mm`, from: `" &
        missed[0..<min(missed.len, 6)].join(", ") & "`."
    check read >= FLOOR_MOMENTS
    check missed.len == 0



  test "at a turn that holds several poses, page draws one plan stood last there":
    ## Page drawn at place of such turn (`placeAt`) shows pose plan stood last there, within
    ##   `REACH`.  Plan stood first one pose of run that is not marked stood again (`reseed`),
    ##   so one it stood last lies at other end of run.
    ##   Domain: every turn that holds several poses, in every sweep of `design/turns.json`.
    let sweeps = readText(cstring(KEPT_TURNS)).toJsObject.sweeps
    var
      scene: Scene
      missed: seq[string]
      read = 0
    for key in sweeps.keys:
      let
        frames = sweeps[key].frames
        count = frames.length.to(int)
      var next = 0
      while next < count:
        let
          first = next
          turn = frames[first].turn.to(float)
        var last = first
        while last + 1 < count and frames[last+1].turn.to(float) == turn: inc last
        next = last + 1
        if last == first: continue

        # Take end of run away from one plan stood first; that end must be marked.
        inc read
        let stood_last =
          if not frames[first].reseed.to(bool): last
          elif not frames[last].reseed.to(bool): first
          else: -1
        doAssert stood_last >= 0, "Run starts at one unmarked pose; got none at `" & $key &
          "` turn `" & $turn & "`."
        doAssert fillScene(scene, frames, placeAt(frames, turn)),
          "Sweep that holds moments draws one; got none at `" & $key & "`."
        if reach(scene, frames[stood_last]) > REACH: missed.add $key & " at " & $turn
    checkpoint "Turns read: `" & $read & "`.  Wrong pose: `" & $missed.len & "`, from: `" &
        missed[0..<min(missed.len, 6)].join(", ") & "`."
    check read >= FLOOR_RUNS
    check missed.len == 0
