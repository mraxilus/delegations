## Share chrome every mark page uses: style sheet, key,
## wrapper.
##
##   Five explorations live on five pages -- frame picture, turn
##     sign, one turn mock-up per kind of hold, and sheet every drawn
##     position is ruled on -- because they are separate questions that
##     happen to be related, and page that holds more than one of them
##     makes each harder to read.
##   What they do share is palette and furniture, which is here so it
##     cannot drift between them.
##   Page body is template with `{marker}` holes and `filled` closes
##     them, refusing to build while any marker is unfilled -- same
##     discipline `tools/review.nim` uses for review page.
##     Cost of markers over inline calls: figure's caption and its part key
##       sit some lines apart in page module.  Accepted -- template
##       stays readable as page it is.

{.experimental: "strictFuncs".}

import std/[options, strformat, strutils]

import ./rules
import ../tools/title
import ../src/dance_ontology/draw/[body, geometry, style]


const STYLE* = """<style>
:root {
  color-scheme: light dark;
  --paper: #fbfaf8; --card: #ffffff; --ink: #1a1a1a; --dim: #6b6660;
  --faint: #948d85; --rule: #ddd8d0; --rule-strong: #c2bbb0; --wash: #f1eee9;
  --left: #3d7fd0; --right: #d0763d;
  --left-deep: #133a72; --right-deep: #723a13;
  --mono: ui-monospace, "SF Mono", SFMono-Regular, Menlo, Consolas, monospace;
  --sans: ui-sans-serif, system-ui, -apple-system, "Segoe UI", sans-serif;
}
@media (prefers-color-scheme: dark) { :root:not([data-theme="light"]) {
  --paper: #16151a; --card: #1e1d24; --ink: #ece9e4; --dim: #9a948c;
  --faint: #857f8e; --rule: #33313a; --rule-strong: #4a4754; --wash: #232128;
  --left: #8fbdf2; --right: #f0a273;
  --left-deep: #2f6ab5; --right-deep: #b25f26; } }
:root[data-theme="dark"] { --paper: #16151a; --card: #1e1d24; --ink: #ece9e4;
  --dim: #9a948c; --faint: #857f8e; --rule: #33313a; --rule-strong: #4a4754;
  --wash: #232128; --left: #8fbdf2; --right: #f0a273;
  --left-deep: #2f6ab5; --right-deep: #b25f26; }

* { box-sizing: border-box; }
body { margin: 0; padding: 2rem 1.25rem 5rem; background: var(--paper);
  color: var(--ink); font: 16px/1.6 var(--sans); }
.sheet { max-width: 62rem; margin: 0 auto; }
h1, h2, h3 { text-wrap: balance; }
.kicker { font: 500 0.7rem/1 var(--mono); letter-spacing: 0.18em;
  text-transform: uppercase; color: var(--dim); margin: 0; }
h1 { font-size: clamp(1.8rem, 5vw, 2.4rem); line-height: 1.05; margin: 0.7rem 0 0;
  letter-spacing: -0.025em; font-weight: 650; }
.top { border-bottom: 2px solid var(--ink); padding-bottom: 1.25rem;
  margin-bottom: 1.5rem; }
.standfirst { margin: 0.85rem 0 0; color: var(--dim); max-width: 42rem; }
.sibling { margin: 0.85rem 0 0; font-size: 0.9rem; color: var(--dim); }
.sibling b { color: var(--ink); }

section { margin: 2.75rem 0 0; }
.head { display: flex; align-items: baseline; gap: 0.8rem; flex-wrap: wrap;
  border-bottom: 1px solid var(--rule); padding-bottom: 0.6rem; }
.head .n { font: 600 0.72rem/1 var(--mono); letter-spacing: 0.14em;
  text-transform: uppercase; color: var(--faint); }
.head h2 { margin: 0; font-size: 1.3rem; letter-spacing: -0.015em; }
section > p { max-width: 44rem; }

.plate { border: 1px solid var(--rule); border-radius: 6px; background: var(--card);
  padding: 1.1rem 1.2rem 1.2rem; margin: 1.25rem 0 0; }
.plate.pick { border-color: var(--right); border-width: 1px 1px 1px 3px; }
.plate h3 { margin: 0 0 0.15rem; font-size: 1rem; }
.plate h3 .tag { font: 600 0.62rem/1 var(--mono); letter-spacing: 0.12em;
  text-transform: uppercase; color: var(--right); margin-left: 0.5rem; }
.plate p { font-size: 0.88rem; color: var(--dim); margin: 0.45rem 0 0;
  max-width: 46rem; }
.row { display: flex; gap: 1.15rem; margin: 1.1rem 0 0; flex-wrap: wrap;
  align-items: flex-end; }
.row.mid { align-items: center; }
figure { margin: 0; text-align: center; }
figcaption { font: 0.66rem/1.4 var(--mono); color: var(--faint); margin-top: 0.3rem; }
figcaption b { color: var(--ink); font-weight: 600; }
svg.f { display: block; width: 160px; height: 160px; }
svg.tiny { display: block; width: 84px; height: 84px; }
svg.wide { display: block; width: 152px; height: 152px; }
svg.mv { display: block; }
svg.still { display: none; }
@media (prefers-reduced-motion: reduce) {
  svg.moving { display: none; } svg.still { display: block; } }
table.grid { border-collapse: collapse; margin: 1.1rem 0 0; }
table.grid th { font: 600 0.62rem/1.3 var(--mono); letter-spacing: 0.06em;
  text-transform: uppercase; color: var(--faint); text-align: center;
  padding: 0.4rem 0.5rem; vertical-align: bottom; }
table.grid tr th:first-child { text-align: right; white-space: nowrap; }
table.grid td { text-align: center; padding: 0.2rem 0.5rem;
  border-top: 1px solid var(--rule); color: var(--faint); }
table.grid td svg { margin: 0 auto; }

table.slots { border-collapse: collapse; font-size: 0.82rem; text-align: left; }
table.slots th, table.slots td { padding: 0.3rem 0.9rem 0.3rem 0;
  border-bottom: 1px solid var(--rule); white-space: nowrap; }
table.slots th { font: 600 0.64rem/1.4 var(--mono); letter-spacing: 0.08em;
  text-transform: uppercase; color: var(--faint); }
table.slots td { color: var(--dim); }
table.slots td:first-child { color: var(--ink); }

.key { display: grid; gap: 0.5rem 1rem; margin: 1.1rem 0 0;
  grid-template-columns: auto 1fr; align-items: center; font-size: 0.87rem; }
.key svg { display: block; }
.key span { color: var(--dim); }
.key b { color: var(--ink); font-weight: 620; }

.note { margin: 1.25rem 0 0; padding: 0.9rem 1.1rem; background: var(--wash);
  border-left: 3px solid var(--rule-strong); border-radius: 0 4px 4px 0;
  font-size: 0.89rem; }
.note p { margin: 0; color: var(--dim); }
.note p + p { margin-top: 0.5rem; }
.note b { color: var(--ink); }
code { font: 0.88em var(--mono); background: var(--wash); padding: 0.1em 0.35em;
  border-radius: 3px; }
.foot { margin-top: 3rem; padding-top: 1.25rem; border-top: 1px solid var(--rule);
  font-size: 0.9rem; color: var(--dim); }
.foot b { color: var(--ink); }
</style>
<svg width="0" height="0" style="position:absolute" aria-hidden="true"><defs>
  <pattern id="hL" width="3" height="3" patternTransform="rotate(45)" patternUnits="userSpaceOnUse">
    <line x1="0" y1="0" x2="0" y2="3" stroke="var(--left)" stroke-width="1.4"/>
  </pattern>
  <pattern id="hR" width="3" height="3" patternTransform="rotate(45)" patternUnits="userSpaceOnUse">
    <line x1="0" y1="0" x2="0" y2="3" stroke="var(--right)" stroke-width="1.4"/>
  </pattern>
  <pattern id="hLd" width="3" height="3" patternTransform="rotate(45)" """ &
    """patternUnits="userSpaceOnUse">
    <line x1="0" y1="0" x2="0" y2="3" stroke="var(--left-deep)" stroke-width="1.4"/>
  </pattern>
  <pattern id="hRd" width="3" height="3" patternTransform="rotate(45)" """ &
    """patternUnits="userSpaceOnUse">
    <line x1="0" y1="0" x2="0" y2="3" stroke="var(--right-deep)" stroke-width="1.4"/>
  </pattern>
</defs></svg>
""" ## Whole shared style sheet, plus hatch patterns `above`
    ## fill points at.  Colour values live only here -- `style.nim` names
    ## custom properties, this defines them.


func document*(title, page_body: string): string =
  ## Wrap one page: shared style sheet, then whatever page is about.
  ##   Title is what browser tab and published gallery both show, so
  ##     it carries name of work as well as name of page.
  ##   Every page this wraps is exploration, so all five take mockup form.
  &"<meta charset=\"utf-8\">\n<title>{MOCKUP} — {title}</title>\n" &
    &"{STYLE}{page_body}"


func filled*(template_body: string;
    fills: openArray[tuple[marker, value: string]]): string =
  ## Close every `{marker}` hole in page template, and refuse build that
  ## leaves one open or fills one that is not there.
  result = template_body
  for (marker, value) in fills:
    let token = "{" & marker & "}"
    doAssert token in result, &"No hole for a fill; got `{marker}`."
    result = result.replace(token, value)
  let leftover = result.find('{')
  doAssert leftover < 0,
    &"A hole is unfilled; got `{result[leftover .. min(leftover + 40, result.high)]}`."


type Swatch* {.pure.} = enum ## Five ways key draws pair of hands.
  Free, Unsaid, Low, High, Above


func swatch*(kind: Swatch): string =
  ## Draw swatch pair: lead's square in its side, follow's circle
  ## in its.
  ##   Fills, shades and fade come from same code hands
  ##     themselves use.  Key that drew them its own way could drift from
  ##     figures it sits beside -- and had: it faded at 0.4 against
  ##     hands' 0.5.
  let
    level = case kind
            of Swatch.Low: some Level.Low
            of Swatch.High: some Level.High
            of Swatch.Above: some Level.Above
            else: none(Level)
    faint = if kind == Swatch.Free: &" opacity=\"{FREE_FADE}\"" else: ""
  var bits =
    @["""<svg viewBox="0 0 36 16" width="36" height="16" aria-hidden="true">"""]
  for (leads, arm, cx) in [(true, Arm.L, 7.0), (false, Arm.R, 28.0)]:
    let
      ink = if leads: DEEP[arm] else: INK[arm]
      fill = fillOf(level, arm, leads)
    if leads:
      bits.add &"""<rect x="1" y="2" width="12" height="12" rx="1.5"""" &
        &""" fill="{fill}" stroke="{ink}" stroke-width="1.5"{faint}/>"""
    else:
      bits.add &"""<circle cx="28" cy="8" r="6" fill="{fill}"""" &
        &""" stroke="{ink}" stroke-width="1.5"{faint}/>"""
    if kind == Swatch.High:
      bits.add &"""<circle cx="{n(cx)}" cy="8" r="2.7" fill="{ink}"/>"""
  bits.join("") & "</svg>"


func fig*(svg, cap: string): string =
  ## Set one figure beside its caption.
  &"<figure>{svg}<figcaption>{cap}</figcaption></figure>"
