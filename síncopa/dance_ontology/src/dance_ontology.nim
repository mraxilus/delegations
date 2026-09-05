## Model frames couple can hold in partner dance and moves between them.
##
## Ontology has one state, `Frame`, and one relation, primitive transition
## between two frames.
##   Everything else is derived from those: names, routes, audit of workbook
##     from which model came, and unfinished rotation axis.
##
## Notation gate was evaluated and closed: partner dance has no canonical
## symbolic notation, so plain names are only spelling used.
##
## Umbrella indexes and re-exports model's modules rather than forwarding
## each symbol through documented one-liner.
##   Cost of re-exporting instead of forwarding: per-symbol docs live at
##     definitions, one hop away.  Accepted -- index comments below name that
##     hop, and forwarder layer would restate every signature to say it.
##
## Order of module bootstrapping, each stage importing only earlier ones:
##   [frame, motion]
##   frame -> [transition, rotation]
##   [frame, transition] -> workbook
##   draw/geometry -> draw/terms -> draw/style -> draw/[body, pose]
##   draw/[body, pose] -> draw/route -> draw/figure -> draw/scene
##   [draw/scene, frame, rotation] -> diagram
##   [diagram, draw/[style, terms], frame, motion, transition] -> map
##   [diagram, frame, map, motion, transition] -> spokes
##   [diagram, map, motion, rotation] -> axle
##   draw/ chain is indexed by its own umbrella-less imports: it serves pages
##     and app directly and is not re-exported here.

{.experimental: "strictFuncs".}

## Draw rotation axis as one line, with couple's postures along it.
import ./dance_ontology/axle
## Draw one frame from above, for every place that shows one.
import ./dance_ontology/diagram
## State: `Frame`, its laws, enumeration `FRAMES`, and its names.
import ./dance_ontology/frame
## Draw whole ontology as one picture: frames as places, moves as ways.
import ./dance_ontology/map
## Say when drawing moves, so picture and page agree about it.
import ./dance_ontology/motion
## Model unfinished rotation axis: twist, capacity, wraps and locks.
import ./dance_ontology/rotation
## Draw only where couple are and where they can go next.
import ./dance_ontology/spokes
## Relation: primitives, compounds, moves between frames, and routes.
import ./dance_ontology/transition
## `base` sheet held as data, and its audit against derived model.
import ./dance_ontology/workbook

## Re-export whole surface, so one import serves caller.
export axle, diagram, frame, map, motion, rotation, spokes, transition, workbook
