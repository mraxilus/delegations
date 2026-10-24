## Judge where blocks of card touch when harness rendered pages, and hold it to control that proves
##   layout read sees.
##   Harness (`tools/drive/`) renders each page and writes, as data, every pair of blocks of card
##     that stand closer than 4 px. It judges nothing: wording and verdict are here, where suites
##     reach them (Article II.9).
##   Verdict on font faces is not here. Harness writes what each page draws, and font faces it
##     ships, into `build/font-faces/written.json`, and `koch drive` judges that file
##     (`font_stacks.nim` of curator; CONTRIBUTOR.md, Pages and assets). Harness reads control
##     page `koch drive` writes there as page `control`, which proves collector sees.
##   Control page here is positive control of layout read. Its cards come from fixture
##     `tests/fixtures/control_render.json`, built into page through shell, so it ships styles
##     every page ships. Card marked crowded sets inline margin of zero on its second block, which
##     no style of shell outranks; other card keeps margins shell gives, so it holds shell to
##     spacing each block.
##     Control's expected findings are never page's failure. Expected finding absent is finding
##     instead, since read that misses it is blind; finding control does not expect is one too.
##     Harness reads it for layout alone, so it stays out of `written.json`: it is no page project
##     ships, and `koch drive` would judge it as one.
##   Fixture lives under `tests/`, since suites read it as `drive` does.
##   Harness names element with id as `<tag>#<id>`, then its classes (`tools/drive/layout.ts`), so
##     control's card `crowded` is `details#crowded.card`; misnamed one reads as blind, so drive
##     holds naming too.

{.experimental: "strictFuncs".}

import std/[json, options, os]

import ../[guard, markdown]


type CardControl* = object  ## Define one card of control page.
  id*: string  ## Id harness names card by, as `details#<id>.card`.
  is_crowded*: bool  ## Second block of card sits on first, so pair must raise finding.


const
  CONTROL* = "control_render"  ## Name control page renders under, beside every page.
  FLAG_LAYOUT_ONLY = "--layout-only"
    ## Option naming page harness reads for layout alone; twin in `tools/drive/main.ts`.
  FLAG_TEXT_ONLY = "--text-only"
    ## Option naming page harness reads for text alone; twin in `tools/drive/main.ts`.



#[ Control ]#

func cards*(control: JsonNode): seq[CardControl] =
  ## Read cards of control fixture, in order written.
  for card in control{"cards"}.getElems:
    result.add CardControl(id: card{"id"}.getStr, is_crowded: card{"is_crowded"}.getBool)


func bodyControl*(cards: openArray[CardControl]): string =
  ## Render control's body: one open card each, of two blocks, second set on first where card is
  ##   crowded.
  for card in cards:
    let style = if card.is_crowded: " style=\"margin-top: 0 !important\"" else: ""
    result.add "<details class=\"card\" id=\"" & escapeHtml(card.id) & "\" open>" &
        "<summary><h3>Card</h3></summary><p>First block.</p><p" & style &
        ">Second block.</p></details>"


func crowdedExpected*(cards: openArray[CardControl]): seq[string] =
  ## List cards control must raise as crowded, each as harness names it.
  for card in cards:
    if card.is_crowded: result.add "details#" & card.id & ".card"



#[ Harness ]#

func argumentsHarness*(
  written, crowded, control: string; pages: openArray[string]; control_font_faces: Option[string]
): seq[string] =
  ## List command line of harness: files it writes, `written` and `crowded`, then each page for
  ##   both reads, `control` for layout alone, and control page of font faces for text alone.
  ##   Control page of font faces is one `koch drive` writes and leaves in place; where none
  ##     exists, `written` holds pages alone, and nothing judges it.
  result = @[written, crowded]
  result.add pages
  result.add [FLAG_LAYOUT_ONLY, control]
  if control_font_faces.isSome: result.add [FLAG_TEXT_ONLY, control_font_faces.get]



#[ Verdict ]#

func checkCrowded*(
  crowded: JsonNode; expected: openArray[string]; control, directory: string
): seq[Finding] =
  ## Turn each pair of blocks of card that harness found too close into finding at its page;
  ##   hold control to exactly cards it expects crowded.
  ##   Document maps page name to its pairs (element, between, gap); control absent from it
  ##     raised nothing, so each expected is blind.
  var seen: seq[string]
  for page, pairs in crowded.pairs:
    let path = directory / page & ".html"
    for pair in pairs.getElems:
      let element = pair{"element"}.getStr
      if page == control and element in expected:
        if element notin seen: seen.add element
        continue
      result.add Finding(
        path: path,
        message: element & ": Blocks of card touch; got `" & pair{"between"}.getStr & "` at `" &
            $pair{"gap"}.getInt & " px`.",
      )
  let path_control = directory / control & ".html"
  if expected.len == 0:
    result.add Finding(
      path: path_control,
      message: "Control expects no crowded card, so layout check proves nothing; got `0` " &
          "expected.",
    )
  for element in expected:
    if element in seen: continue
    result.add Finding(
      path: path_control,
      message: element & ": Check is blind, since control raised no crowded pair here; got none.",
    )
