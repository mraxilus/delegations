## Visualise rigid geometric algebra objects and operations, for either front-end.
##
## Umbrella of shared core: everything here is reachable from browser and desktop alike,
## and nothing here knows which one is drawing (Article II.9).
##   Front-end owns window, input device and graphics API; core owns geometry, scene and
##   every decision about where mark goes.
##   Facade re-exports coherent surface, so caller writes `import rga_visualiser` rather
##   than naming modules it happens to need today (Article I.6).
##
## Order of bootstrapping, by what each module needs before it:
##   [euclid, objects, projections, format, message, ramp, neighbourhood, starfield,
##    timings, wording]
##     -> [boundary, mesh] -> tessellate
##     -> [camera, scene]
##     -> [history, lighting, orrery, picking, storyboard]
##     -> [interaction, marker] -> [help, selection] -> framing
##
##   |------------------|--------------------------------------------------------------|
##   | Module           | Holds                                                        |
##   |------------------|--------------------------------------------------------------|
##   | `objects`        | Point, line and plane as multivectors, and their shapes      |
##   | `projections`    | Projections `pga` withdrew, until library's own return       |
##   | `euclid`         | Positions, directions, matrices, tolerance comparison        |
##   | `format`         | Magnitudes and coefficients as text, same on both backends   |
##   | `message`        | What each outcome says, and how long it stands               |
##   | `wording`        | Every word either front-end shows, once and keyed            |
##   | `ramp`           | Colour ramps and their validated steps                       |
##   | `neighbourhood`  | Nearby-star catalogue as data                                |
##   | `starfield`      | Wider sky, generated from SIMBAD                             |
##   | `timings`        | Frame clocks and their tallies                               |
##   | `boundary`       | Grid, axes and horizon that frame scene                      |
##   | `mesh`           | Records front-end uploads: ribbons, discs, domes, rings      |
##   | `tessellate`     | Objects into those records, at drawn extent                  |
##   | `camera`         | Orbit, dolly, pan, projection, screen placement              |
##   | `scene`          | Handles, labels, operations catalogue, save and load           |
##   | `history`        | Undo and redo over scene content                             |
##   | `lighting`       | Which shining point lights each body                         |
##   | `orrery`         | Demo scenes at three sizes                                   |
##   | `picking`        | Which object pointer is over                                 |
##   | `storyboard`     | Scripted seeds and frames                                    |
##   | `interaction`    | Drags, taps and what release applies                         |
##   | `marker`         | Selection rings, rails, comets and label placement           |
##   | `help`           | Rows front-end shows, and keys they name                     |
##   | `selection`      | What is picked, and revision that says so                    |
##   | `framing`        | Aiming camera at what was chosen                             |
##   |------------------|--------------------------------------------------------------|

{.experimental: "strictFuncs".}

import ./rga_visualiser/[
  boundary, camera, euclid, format, framing, help, history, interaction, lighting, marker,
  mesh, message, neighbourhood, objects, orrery, picking, projections, ramp, scene,
  selection, starfield, storyboard, tessellate, timings, wording,
]

export
  boundary, camera, euclid, format, framing, help, history, interaction, lighting, marker,
  mesh, message, neighbourhood, objects, orrery, picking, projections, ramp, scene,
  selection, starfield, storyboard, tessellate, timings, wording
