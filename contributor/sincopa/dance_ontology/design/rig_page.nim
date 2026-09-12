## Write viewer page: markup, its two scripts, and faces it draws with.
##
##   Three built things are folded into one self-contained document, as
##     `design/wholecloth` folds its three: sweeps recorded by `design/rig`, and
##     viewer compiled from `design/rig_view` by `nim js`.  Page is published as
##     single file, so nothing may be left to fetch.
##   Faces are inlined by `design/faces`, which also turns Commit Mono's
##     ligatures on at root.  Article X.8: a presentation target ships the faces
##     it draws with, never naming one a viewer may lack.
##
##   Usage: rig_page <dir>   reads design/rig.json and <dir>/rig_view.js,
##                           writes <dir>/rig.html

{.experimental: "strictFuncs".}

import std/[os, strformat, strutils]

import ./[faces, page]


const BODY = """
<main class="rigview">
  <header>
    <p class="kicker">Body sim</p>
    <h1>The rig, as the engine holds it</h1>
    <p class="lede">Every capsule the engine collides, at the world ends the
      engine reports, at the radius it collides on. Nothing is drawn that is not
      simulated, and nothing simulated is left out &mdash; including the gap under
      the hips, because the rig is trunk upward and has no legs. Drag to turn the
      view, scroll to zoom.</p>
  </header>

  <div class="rigwrap">
    <div class="stage"><canvas id="view"></canvas>
      <p class="where" id="where"></p></div>
    <aside class="panel">
      <label class="pickrow">Sweep
        <select id="pick"></select>
      </label>
      <p class="verdict" id="verdict"></p>
      <div class="transport">
        <button id="play" type="button">Pause</button>
        <input id="scrub" type="range" min="0" max="0" value="0" step="1">
      </div>
      <div class="reads" id="reads"></div>
      <p class="note">A joint within five degrees of either end is marked
        <span class="spent-key">spent</span>. The range shown is the rig's, for
        that arm: the shoulder's twist is mirrored between left and right, so its
        two ends are the arm's own rather than the table's.</p>
    </aside>
  </div>
</main>
"""

const SHEET = """<style>
.rigview { max-width: 76rem; margin: 0 auto; padding: 2rem 1.5rem 4rem; }
.rigview header { max-width: 44rem; margin-bottom: 1.5rem; }
.rigview h1 { font: 600 1.6rem/1.2 var(--serif); margin: 0.2rem 0 0.6rem; }
.rigview .lede { font: 0.95rem/1.55 var(--sans); color: var(--dim); margin: 0; }
.rigwrap { display: grid; grid-template-columns: minmax(0, 1fr) 20rem;
  gap: 1.25rem; align-items: start; }
.stage { background: var(--card); border: 1px solid var(--rule);
  border-radius: 0.4rem; padding: 0.5rem; position: relative; }
.stage canvas { width: 100%; height: 32rem; display: block; touch-action: none;
  cursor: grab; }
.where { position: absolute; left: 0.9rem; bottom: 0.7rem; margin: 0;
  font: 0.72rem/1 var(--mono); color: var(--dim); }
.panel { background: var(--card); border: 1px solid var(--rule);
  border-radius: 0.4rem; padding: 0.9rem; }
.pickrow { display: block; font: 600 0.62rem/1.4 var(--mono);
  letter-spacing: 0.12em; text-transform: uppercase; color: var(--faint); }
.pickrow select { display: block; width: 100%; margin-top: 0.35rem;
  font: 0.82rem/1.3 var(--sans); padding: 0.3rem; background: var(--paper);
  color: var(--ink); border: 1px solid var(--rule); border-radius: 0.25rem; }
.verdict { font: 0.8rem/1.45 var(--sans); color: var(--ink);
  margin: 0.7rem 0 0.6rem; }
.transport { display: flex; gap: 0.5rem; align-items: center;
  margin-bottom: 0.8rem; }
.transport button { font: 600 0.62rem/1 var(--mono); letter-spacing: 0.1em;
  text-transform: uppercase; padding: 0.4rem 0.6rem; background: var(--wash);
  color: var(--ink); border: 1px solid var(--rule); border-radius: 0.25rem;
  cursor: pointer; }
.transport input { flex: 1; min-width: 0; }
.arm { margin-bottom: 0.7rem; }
.arm h4 { font: 600 0.62rem/1 var(--mono); letter-spacing: 0.1em;
  text-transform: uppercase; color: var(--dim); margin: 0 0 0.3rem;
  display: flex; align-items: center; gap: 0.35rem; }
.arm h4 i { width: 0.6rem; height: 0.6rem; border-radius: 50%; display: block; }
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
@media (max-width: 56rem) {
  .rigwrap { grid-template-columns: minmax(0, 1fr); }
  .stage canvas { height: 22rem; }
}
</style>"""


when isMainModule:
  let
    dir = if paramCount() >= 1: paramStr(1) else: "."
    data = "design" / "rig.json"
    view = dir / "rig_view.js"
  if not fileExists(data):
    quit(&"Viewer page has no sweeps; run `nim r tools/build.nim rig`: got `{data}`.", 1)
  if not fileExists(view):
    quit(&"Viewer page has no viewer; run `pages` first: got `{view}`.", 1)
  let html = document("The rig, as the engine holds it",
                      SHEET & BODY &
                      "<script>var RIG = " & readFile(data).strip() &
                      ";</script>\n" &
                      "<script>" & readFile(view) & "</script>\n")
  let path = dir / "rig.html"
  writeFile(path, withFaces(html))
  echo "wrote ", path
