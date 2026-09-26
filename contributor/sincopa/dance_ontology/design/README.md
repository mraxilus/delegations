# The rotation mark workbench

This directory holds mock-ups of the marks for rotation, drawn before the app draws them. Every page
is a mock-up, and its title says so. The reason for each choice is in `../PROVENANCE.md`, under the
rules of the drawing, the frame picture and the turn sign.

**A check holds a drawing to a rule as it is written.** It does not show that a couple can dance
what the drawing shows. The positions to trust are reference cells that are kept, modelled and
confirmed. `CONFIRMED` in `review_page.nim` holds none yet.

## Pages

- `frames.html` is the frame picture: how a held pair of hands looks, and how a move changes it.
- `signs.html` is the turn sign: how to label a move with an amount of turn.
- `turns-single.html` and `turns-hands.html` show each position a hold turns through, and each move
  between two of them. The first is for one hand, and the second is for two.
- `review.html` lays out each frame position the project draws, card by card, for the Architect to
  rule on.
- `rig.html` plays the sweeps and stills that the body sim recorded.
- `wholecloth.html` is drawn by hand, in `../mockups/wholecloth.html`. Its turns panel draws what
  the body sim found.

`../README.md` gives the address where each page is published.

## Build

```
nim r tools/build.nim pages      # checks every standing rule, then writes every page
nim r tools/build.nim turns      # asks the sim for every hold turning: turns.json
nim r tools/build.nim rig        # records the sweeps the viewer plays: rig.json
nim r tools/build.nim modelled   # records which cards the sim reaches: modelled.json
nim r tools/build.nim pins       # records what each ruled card is drawn as: review-pins.json
nim r tools/build.nim shot       # builds the helper that screenshots a page
```

The build does not write a page whose checks fail. Each page is a product of the build, under
`build/`, and is not committed. The build reads the four JSON files and does not write them. Each
verb that writes one is run by hand.

## Rules

Each rule the drawing was given is quoted here, in the words it arrived in. Each quotation is a copy
of its entry in `rules.nim`, and `../tests/suites/treadme.nim` holds the two copies the same. Under
each is the check in `checks.nim` that holds the drawing to it. Where there is none, it says so, or
names the rule that replaces it. A replaced rule stays in the list, so its number does not move.

### Rule 1

> the hands should only pass through the circle when the hand positions are above

Held by `checkRules`.

### Rule 2

> the hands can only move from their positions at the side of the body only if a level is specified

Held by `checkRules`.

### Rule 3

> the slots are relative to the front facing side of the lead/follow, not from the diagram itself

Held by `checkRules`.

### Rule 4

> high and low wraps go around to the front of the other hand

Held by `checkRules`.

### Rule 5

> low lock goes around the back to the back of the other hand

Held by `checkRules`.

### Rule 6

> in high lock the line goes around the back of the modified body

Held by `checkRules`.

### Rule 7

> lock/wrap positions can only be used when the connecting line goes around no less than just under
> 1/2 of the circumference. it doesn't make sense to have a wrap or a lock without the line actually
> going around the body

Held by `checkRules`. The drawing holds a high lock to this rule too, which rule 41 does not ask.

### Rule 8

> above has no locks/wraps and can only transition to upper wrap or back to default (physical
> restrictions)

Held by `checkRules` for its first half. `FROM_ABOVE` in `rules.nim` holds its second half, and
nothing checks it. The "upper wrap" is read as the high wrap, and that is a reading.

### Rule 9

> the connection is drawn in its two hands' own colours, meeting at its middle, the lead's end in
> the deep shade

Held by `checkRules`.

### Rule 10

> using only the rotations that allow us to change between just those (i.e. assumed all rotations
> are high so no wraps/locks)

Replaced by rule 17: a turn is drawn above, and not high.

### Rule 11

> no additional frame positions, just the addition of rotations that let us travel between them

Held by `checkSingleTurns`, on the turn pages.

### Rule 12

> hand to hand should have 3 positions allowed by rotation

Replaced. Rule 16 gives a single hold no end, and rules 28 and 31 make the chain of two hands seven
positions long.

### Rule 13

> left to left and right to right should technically have 4 (left over right, right over left, and
> the two sides with an extra arm twist, in either direction)

Replaced by rules 28 and 31: the crossed pair walks the same chain of seven as hand to hand.

### Rule 14

> the rotations should be high, such that there should be no body wrapping, also make sure any
> twists are visually clear just like the crossover

Held by `checkSingleTurns`, which checks that nothing wraps a body. Rule 17 replaces its level: a
turn is drawn above.

### Rule 15

> for each mock up, a static image version of every derived position and full set of animated
> transitions between states

Held by `checkSingleTurns`.

### Rule 16

> if held high, they can turn infinitely in either direction, so all we add is the additional
> quarter turn orientations for each of the 4 single hand connections

Held by `checkSingleTurns`.

### Rule 17

> all turns should be in the "above" position, not the high. high/low causes wraps/locks, so we're
> currently making the assumption to avoid those

Held by `checkSingleTurns` and `checkHandTurns`.

### Rule 18

> the leads' transitions should still be in the 2 stage form, stage 1 is the lead turns with the
> original perspective stage 2 is reorienting the perspective

Held by `checkSingleTurns`.

### Rule 19

> you should also include orbit turns not just the axis turns

Held by `checkSingleTurns` and `checkHandTurns`.

### Rule 20

> make sure orbit turns keep their bearing, youre currently combining orbit and axis turns to keep
> the partner facing the other

Replaced by rule 32.

### Rule 21

> also, the animations should also have the above level as that's the only valid one for the current
> scope

Held by `checkSingleTurns` and `checkHandTurns`.

### Rule 22

> an arm shouldn't settle in a hand cell it's not connected to. it should bend around all hand cells
> and chevrons as to not imply connection and not obscure direction. it is however fine to animate
> smoothly past it as it would do now for a full turn for example

Held by `checkSingleTurns`, on the turn pages. The frame page does not follow it yet.

### Rule 23

> the current line finding does a good job of finding the shortest line, but we also need to balance
> simplicity. prefer paths that have fewers bends (ideally 1) as well as length. in many cases I
> see, 1 bend can be used with minimal change to the overall line

Held by `checkSingleTurns`.

### Rule 24

> prefer smooth long curves instead of sharp breaks as well. some of these can be accomplished with
> a singular bezier with a more gentle curvature just as well as the current sharp direction changes

Held by `checkSingleTurns`.

### Rule 25

> reposition the lead such that when the follow orbits or the lead turns on axis, the 2nd animation
> stage doesn't have to move the result around, i.e. lead position should remain fixed as much as
> possible (obviously this can't really be the case when the lead orbits, a reposition/re entering)
> will still be necessary I think

Held by `checkSingleTurns`, on the turn pages. The frame page does not follow it yet.

### Rule 26

> make the second animation stage quicker or something so it has less emphasis. or whatever the
> recommended UX is to make it less noticeable than the actual rotation itself

Held by `checkSingleTurns`.

### Rule 27

> the two twisted ends in reality the arms make an overlapping box shape. on one side of the twist
> the lead left is over the right (reversed for other end of twist). the arms should reflect that
> visual on both ends of the twist. there should be two crossovers one on the leads side of the
> arms, one on the follows. for both sides of the twist chain. there should be a visible box/diamond
> between the crossovers (hence the preliminary names, Left over Right box, Right over Left box)

Held by `checkHandTurns`, for crossings that alternate. Rule 28 replaces the diamond it drew with
one measured off the pose.

### Rule 28

> the animations are very jankey and tied to the final visual representations of the box/diamond
> state, add the half turns which should actually form an X overhead when partners are facing the
> same direction (similar to the existing L-over-R etc. when facing one another) as states
> in-between the outside 2

Held by `checkHandTurns`.

### Rule 29

> the animations don't have the proper breaks that the static images do, they seem to not be
> tracking which arms are over/under because of this and they are instances where they end up on the
> wrong z order, fix

Held by `checkHandTurns`.

### Rule 30

> the boxes/diamonds are the ends of the turn chain this highlighted is not allowed. all I'm
> referring to is that double box is not allowed

Held by `checkHandTurns`.

### Rule 31

> both hand to hand and the overs are essentially the same thing but with one half turn of offset.
> the neutral (non crossed) state in hand to hand is when partners are facing, and the same state in
> the other set is when a partner is facing away (in between Left over and Right over). hand to hand
> actually has an extra half turn on both ends (which I previously thought only the other pattern
> had). this means both patterns follow the same logic, just one starts with the partners facing
> each other, and the other starts with both partners facing the same way

Held by `checkHandTurns`.

### Rule 32

> orbit should not maintain bearing, but instead keep whatever side faces the center, facing the
> center otherwise we can't equate the 1/2 turns

Held by `checkSingleTurns` and `checkHandTurns`.

### Rule 33

> the swan zig zag is a bit to large, make it tighter so it looks more readable. also, the above
> level hatching appears to be a background that moves around a lot as the squares/circles move, it
> should stay visually consistent during animation

Held by `checkSingleTurns` and `checkHandTurns`.

### Rule 34

> the hatching is good, but revert the swan change, it looks worse

Replaced by rule 35. The width of the swan is set by eye, and its check is a backstop.

### Rule 35

> they both have the same issue, go back to the tighter version try to make the swan arm, even
> tighter to the straighter arm, but make it smoother (a simpler curved, right now it looks
> jagged/sharp)

Held by `checkHandTurns`.

### Rule 36

> above: connection held above head. high: connection held above shoulder level (about neck). low:
> connection held below shoulder level (about torso)

The workbench does not check it. The sim reports levels in its words, through `../sim/words.nim`.

### Rule 37

> lock: where a lead/follow's arm is bent behind their back (low) or bent to the shoulder of the
> same arm. To get into low lock, the form must enter from a low position only due to
> physical/safety limitations

The workbench does not check it. The sim reports a hand behind its own back as a lock.

### Rule 38

> wrap: where a lead/follow's arm is crossed around the front of their body under (low) or over
> (high) their other arm

The workbench does not check it. It does not draw the crossing with the other arm yet. The sim
reports a hand across the front of its own body as a wrap.

### Rule 39

> generated two hand combinations for up to 1 modifier per lead/follow (maximum 2 total across all 4
> hands); permutations with 2 modifiers for a single person are excluded, until deemed necessary

Nothing checks it. The drawing holds one level and one way for each connection, and not for each
arm.

### Rule 40

> half-closed, Left to left held low: wrap at left@0.5, lock at right@1

The workbench does not check it. `../sim/verdicts.md` gives what the sim finds for Left to left held
low, turned from face to face.

### Rule 41

> that applies to everything but high lock

It answers the second sentence of rule 7. Nothing checks it. The drawing does not follow it, and
holds a high lock to rule 7 as well.

## Layout

The drawing is in `../src/dance_ontology/draw/`, because the app draws these marks too. The
workbench imports it from there.

```
../src/dance_ontology/draw/
  terms.nim     what a drawing of a couple is made of: sides, levels, holds
  geometry.nim  scalars and vectors, in the conventions of the drawing
  style.nim     the palette, and the width of a connection
  pose.nim      the couple in world coordinates, and each way to rotate them
  body.nim      one dancer: circle, chevron, spots, hands
  route.nim     a connection, routed as a taut string round two bodies
  figure.nim    whole pictures, still and moving
  scene.nim     each of the app's frames
```

```
design/
  rules.nim              each rule, in the words it arrived in; re-exports draw/terms
  checks.nim             each standing rule, checked on every build
  parts.nim              each figure the mark pages place, keyed by name
  sign.nim               the turn sign
  page.nim               the style sheet, key and wrapper the mark pages share
  frame_page.nim         frames.html
  sign_page.nim          signs.html
  turns_single_page.nim  turns-single.html
  hands_page.nim         turns-hands.html
  review_page.nim        review.html, and which cards are kept and confirmed
  marks.nim              builds the five pages above
  plain.nim              reads prose, and holds it to the two countable rules
  faces.nim              the faces each page embeds
  asks.nim               what each reference card asks of the body sim
  modelled.nim           which cards the sim reaches: modelled.json
  turns.nim              every hold turning, asked of the sim: turns.json
  rig.nim                the sweeps and stills the viewer plays: rig.json
  rig_page.nim           rig.html
  rig_view.nim           the viewer, which draws what the engine collides
  drawn.nim              where each point of the world lands on the viewer's canvas
  wholecloth.nim         splices the data of the sim into wholecloth.html
  wholecloth_turns.nim   the turns panel of wholecloth.html
  shot.nim               a screenshot of one page, light and dark
```
