## Hold English of gismu list of Logical Language Group as typed entries, one per line.
##   Written by `nim r tools/build.nim lists` from `gismu.txt` of Debian
##   package `lojban-common`, SHA-256 `f2fc4cff4f265ad02717d56733b4627f`
##   `fa78c616db78dcaa44caab694e1dd5b7`; never edit by hand, run verb again.
##   Entries keep order of list: gismu and cmavo carrying rafsi, alphabetically.
##   Rafsi of each word stand in gismu list of `lojban_parser`, entry for entry.
##   Derived from material Logical Language Group placed in public domain; facts of
##     derivation stated here as group asks: columns cut to fields of `entries.nim`,
##     carriage returns removed, spaces at field ends trimmed. Further information about
##     Lojban: Logical Language Group, Inc., 2904 Beau Lane, Fairfax VA 22031 USA,
##     https://www.lojban.org/.

{.experimental: "strictFuncs".}

import ../entries


const LIST_GISMU* = [
  EntryGismuEnglish(
    word: "bacru",
    keyword: "utter",
    hint: "",
    definition: "x1 utters verbally/says/phonates/speaks [vocally makes sound] x2",
  ),
  EntryGismuEnglish(
    word: "badna",
    keyword: "banana",
    hint: "",
    definition: "x1 is a banana/plantain [fruit/plant] of species/breed x2",
  ),
  EntryGismuEnglish(
    word: "badri",
    keyword: "sad",
    hint: "",
    definition: "x1 is sad/depressed/dejected/[unhappy/feels sorrow/grief] about x2 (abstraction)",
  ),
  EntryGismuEnglish(
    word: "bajra",
    keyword: "run",
    hint: "",
    definition: "x1 runs on surface x2 using limbs x3 with gait x4",
  ),
  EntryGismuEnglish(
    word: "bakfu",
    keyword: "bundle",
    hint: "'pack'",
    definition: "x1 is a bundle/package/cluster/clump/pack [shape/form] containing x2, held " &
        "together by x3",
  ),
  EntryGismuEnglish(
    word: "bakni",
    keyword: "bovine",
    hint: "'ox'",
    definition: "x1 is a cow/cattle/kine/ox/[bull/steer/calf] [beef-producer/bovine] of " &
        "species/breed x2",
  ),
  EntryGismuEnglish(
    word: "bakri",
    keyword: "chalk",
    hint: "",
    definition: "x1 is a quantity of/contains/is made of chalk from source x2 in form x3",
  ),
  EntryGismuEnglish(
    word: "baktu",
    keyword: "bucket",
    hint: "",
    definition: "x1 is a bucket/pail/can/deep, solid, wide-topped container of contents x2, made " &
        "of material x3",
  ),
  EntryGismuEnglish(
    word: "balji",
    keyword: "bulb",
    hint: "'bulge'",
    definition: "x1 is a bulb [body-part] of plant/species x2; [metaphor: rounded, bulgy]",
  ),
  EntryGismuEnglish(
    word: "balni",
    keyword: "balcony",
    hint: "",
    definition: "x1 is a balcony/overhang/ledge/shelf of building/structure x2",
  ),
  EntryGismuEnglish(
    word: "balre",
    keyword: "blade",
    hint: "",
    definition: "x1 is a blade of tool/weapon x2",
  ),
  EntryGismuEnglish(
    word: "balvi",
    keyword: "future",
    hint: "'later'",
    definition: "x1 is in the future of/later than/after x2 in time sequence; x1 is latter; x2 " &
        "is former",
  ),
  EntryGismuEnglish(
    word: "bancu",
    keyword: "beyond",
    hint: "",
    definition: "x1 exceeds/is beyond limit/boundary x2 from x3 in property/amount x4 (ka/ni)",
  ),
  EntryGismuEnglish(
    word: "bandu",
    keyword: "defend",
    hint: "",
    definition: "x1 (event) defends/protects x2 (object/state) from threat/peril/potential x3 " &
        "(event)",
  ),
  EntryGismuEnglish(
    word: "banfi",
    keyword: "amphibian",
    hint: "",
    definition: "x1 is an amphibian of species/breed x2",
  ),
  EntryGismuEnglish(
    word: "bangu",
    keyword: "language",
    hint: "",
    definition: "x1 is a/the language/dialect used by x2 to express/communicate x3 (si'o/du'u, " &
        "not quote)",
  ),
  EntryGismuEnglish(
    word: "banli",
    keyword: "great",
    hint: "'grand'",
    definition: "x1 is great/grand in property x2 (ka) by standard x3",
  ),
  EntryGismuEnglish(
    word: "banro",
    keyword: "grow",
    hint: "",
    definition: "x1 grows/expands [an increasing development] to size/into form x2 from x3",
  ),
  EntryGismuEnglish(
    word: "banxa",
    keyword: "bank",
    hint: "",
    definition: "x1 is a bank owned by/in banking system x2 for banking function(s) x3 (event)",
  ),
  EntryGismuEnglish(
    word: "banzu",
    keyword: "suffice",
    hint: "",
    definition: "x1 (object) suffices/is enough/sufficient for purpose x2 under conditions x3",
  ),
  EntryGismuEnglish(
    word: "bapli",
    keyword: "force",
    hint: "'compel'",
    definition: "x1 [force] (ka) forces/compels event x2 to occur; x1 determines property x2 to " &
        "manifest",
  ),
  EntryGismuEnglish(
    word: "barda",
    keyword: "big",
    hint: "'large'",
    definition: "x1 is big/large in property/dimension(s) x2 (ka) as compared with standard/norm " &
        "x3",
  ),
  EntryGismuEnglish(
    word: "bargu",
    keyword: "arch",
    hint: "",
    definition: "x1 arches/curves over/around x2 and is made of x3; x1 is an arch over/around x2 " &
        "of material x3",
  ),
  EntryGismuEnglish(
    word: "barja",
    keyword: "bar",
    hint: "",
    definition: "x1 is a tavern/bar/pub serving x2 to audience/patrons x3",
  ),
  EntryGismuEnglish(
    word: "barna",
    keyword: "mark",
    hint: "",
    definition: "x1(s) is a/are mark(s)/spot(s) on x2 of material x3",
  ),
  EntryGismuEnglish(
    word: "bartu",
    keyword: "out",
    hint: "",
    definition: "x1 is on the outside of x2; x1 is exterior to x2",
  ),
  EntryGismuEnglish(
    word: "basna",
    keyword: "emphasize",
    hint: "'accent'",
    definition: "x1 emphasizes/accentuates/gives emphasis/stress/accent to x2 by (action) x3",
  ),
  EntryGismuEnglish(
    word: "basti",
    keyword: "replace",
    hint: "'substitute'",
    definition: "x1 replaces/substitutes for/instead of x2 in circumstance x3; x1 is a " &
        "replacement/substitute",
  ),
  EntryGismuEnglish(
    word: "batci",
    keyword: "bite",
    hint: "",
    definition: "x1 bites/pinches x2 on/at specific locus x3 with x4",
  ),
  EntryGismuEnglish(
    word: "batke",
    keyword: "button",
    hint: "",
    definition: "x1 is a button/knob/[handle] on/for item x2, with purpose x3, made of material x4",
  ),
  EntryGismuEnglish(
    word: "bavmi",
    keyword: "barley",
    hint: "",
    definition: "x1 is a quantity of barley [grain] of species/strain x2",
  ),
  EntryGismuEnglish(
    word: "baxso",
    keyword: "Malay-Indonesian",
    hint: "'Bahasa'",
    definition: "x1 reflects Malay-Indonesian common language/culture in aspect x2",
  ),
  EntryGismuEnglish(
    word: "bebna",
    keyword: "foolish",
    hint: "'boob'",
    definition: "x1 is foolish/silly in event/action/property [folly] (ka) x2; x1 is a boob",
  ),
  EntryGismuEnglish(
    word: "bemro",
    keyword: "North American",
    hint: "",
    definition: "x1 reflects North American culture/nationality/geography in aspect x2",
  ),
  EntryGismuEnglish(
    word: "bende",
    keyword: "crew",
    hint: "'band'",
    definition: "x1 is a crew/team/gang/squad/band of persons x2 directed/led by x3 organized " &
        "for purpose x4",
  ),
  EntryGismuEnglish(
    word: "bengo",
    keyword: "Bengali",
    hint: "",
    definition: "x1 reflects Bengali/Bangladesh culture/nationality/language in aspect x2",
  ),
  EntryGismuEnglish(
    word: "benji",
    keyword: "transfer",
    hint: "'send'",
    definition: "x1 transfers/sends/transmits x2 to receiver x3 from transmitter/origin x4 via " &
        "means/medium x5",
  ),
  EntryGismuEnglish(
    word: "bersa",
    keyword: "son",
    hint: "",
    definition: "x1 is a son of mother/father/parents x2 [not necessarily biological]",
  ),
  EntryGismuEnglish(
    word: "berti",
    keyword: "north",
    hint: "",
    definition: "x1 is to the north/northern side [right-hand-rule pole] of x2 according to " &
        "frame of reference x3",
  ),
  EntryGismuEnglish(
    word: "besna",
    keyword: "brain",
    hint: "",
    definition: "x1 is a/the brain [body-part] of x2; [metaphor: intelligence, mental control]",
  ),
  EntryGismuEnglish(
    word: "betfu",
    keyword: "abdomen",
    hint: "'belly'",
    definition: "x1 is a/the abdomen/belly/lower trunk [body-part] of x2; [metaphor: midsection]",
  ),
  EntryGismuEnglish(
    word: "betri",
    keyword: "tragedy",
    hint: "'tragic'",
    definition: "x1 is a tragedy/disaster/tragic for x2",
  ),
  EntryGismuEnglish(
    word: "bevri",
    keyword: "carry",
    hint: "'bear'",
    definition: "x1 carries/hauls/bears/transports cargo x2 to x3 from x4 over path x5; x1 is a " &
        "carrier/[porter]",
  ),
  EntryGismuEnglish(
    word: "bi",
    keyword: "8",
    hint: "",
    definition: "digit/number: 8 (digit)",
  ),
  EntryGismuEnglish(
    word: "bi'i",
    keyword: "unordered interval",
    hint: "",
    definition: "non-logical interval connective: unordered between ... and ... (rafsi " &
        "represents any interval)",
  ),
  EntryGismuEnglish(
    word: "bidju",
    keyword: "bead",
    hint: "",
    definition: "x1 is a bead/pebble [shape/form] of material x2",
  ),
  EntryGismuEnglish(
    word: "bifce",
    keyword: "bee",
    hint: "",
    definition: "x1 is a bee/wasp/hornet of species/breed x2",
  ),
  EntryGismuEnglish(
    word: "bikla",
    keyword: "whip",
    hint: "'beat, lash'",
    definition: "x1 whips/lashes/snaps [a sudden violent motion]",
  ),
  EntryGismuEnglish(
    word: "bilga",
    keyword: "obliged",
    hint: "",
    definition: "x1 is bound/obliged to/has the duty to do/be x2 in/by standard/agreement x3; x1 " &
        "must do x2",
  ),
  EntryGismuEnglish(
    word: "bilma",
    keyword: "ill",
    hint: "",
    definition: "x1 is ill/sick/diseased with symptoms x2 from disease x3",
  ),
  EntryGismuEnglish(
    word: "bilni",
    keyword: "military",
    hint: "",
    definition: "x1 is military/regimented/is strongly organized/prepared by system x2 for " &
        "purpose x3",
  ),
  EntryGismuEnglish(
    word: "bindo",
    keyword: "Indonesian",
    hint: "",
    definition: "x1 reflects Indonesian culture/nationality/language in aspect x2",
  ),
  EntryGismuEnglish(
    word: "binra",
    keyword: "insure",
    hint: "",
    definition: "x1 insures/indemnifies x2 (person) against peril x3 (event) providing " &
        "benefit(s) x4 (event)",
  ),
  EntryGismuEnglish(
    word: "binxo",
    keyword: "become",
    hint: "",
    definition: "x1 becomes/changes/converts/transforms into x2 under conditions x3",
  ),
  EntryGismuEnglish(
    word: "birje",
    keyword: "beer",
    hint: "",
    definition: "x1 is made of/contains/is a amount of beer/ale/brew brewed from x2",
  ),
  EntryGismuEnglish(
    word: "birka",
    keyword: "arm",
    hint: "",
    definition: "x1 is a/the arm [body-part] of x2; [metaphor: branch with strength]",
  ),
  EntryGismuEnglish(
    word: "birti",
    keyword: "certain",
    hint: "",
    definition: "x1 is certain/sure/positive/convinced that x2 is true",
  ),
  EntryGismuEnglish(
    word: "bisli",
    keyword: "ice",
    hint: "",
    definition: "x1 is a quantity of/is made of/contains ice [frozen crystal] of " &
        "composition/material x2",
  ),
  EntryGismuEnglish(
    word: "bitmu",
    keyword: "wall",
    hint: "",
    definition: "x1 is a wall/fence separating x2 and x3 (unordered) of/in structure x4",
  ),
  EntryGismuEnglish(
    word: "blabi",
    keyword: "white",
    hint: "",
    definition: "x1 is white/very-light colored [color adjective]",
  ),
  EntryGismuEnglish(
    word: "blaci",
    keyword: "glass",
    hint: "",
    definition: "x1 is a quantity of/is made of/contains glass of composition including x2",
  ),
  EntryGismuEnglish(
    word: "blanu",
    keyword: "blue",
    hint: "",
    definition: "x1 is blue [color adjective]",
  ),
  EntryGismuEnglish(
    word: "bliku",
    keyword: "block",
    hint: "",
    definition: "x1 is a block [3-dimensional shape/form] of material x2, surfaces/sides x3",
  ),
  EntryGismuEnglish(
    word: "bloti",
    keyword: "boat",
    hint: "",
    definition: "x1 is a boat/ship/vessel [vehicle] for carrying x2, propelled by x3",
  ),
  EntryGismuEnglish(
    word: "bo",
    keyword: "short scope link",
    hint: "",
    definition: "short scope joiner; joins various constructs with shortest scope and right " &
        "grouping",
  ),
  EntryGismuEnglish(
    word: "bolci",
    keyword: "ball",
    hint: "",
    definition: "x1 is a ball/sphere/orb/globe [shape/form] of material x2; x1 is a spherical " &
        "object [made of x2]",
  ),
  EntryGismuEnglish(
    word: "bongu",
    keyword: "bone",
    hint: "",
    definition: "x1 is a/the bone/ivory [body-part], performing function x2 in body of x3; " &
        "[metaphor: calcium]",
  ),
  EntryGismuEnglish(
    word: "botpi",
    keyword: "bottle",
    hint: "",
    definition: "x1 is a bottle/jar/urn/flask/closable container for x2, made of material x3 " &
        "with lid x4",
  ),
  EntryGismuEnglish(
    word: "boxfo",
    keyword: "sheet",
    hint: "'foil'",
    definition: "x1 is a sheet/foil/blanket [2-dimensional shape/form flexible in 3 dimensions] " &
        "of material x2",
  ),
  EntryGismuEnglish(
    word: "boxna",
    keyword: "wave",
    hint: "",
    definition: "x1 is a wave [periodic pattern] in medium x2, wave-form x3, wave-length x4, " &
        "frequency x5",
  ),
  EntryGismuEnglish(
    word: "bradi",
    keyword: "enemy",
    hint: "'adversary'",
    definition: "x1 is an enemy/opponent/adversary/foe of x2 in struggle x3",
  ),
  EntryGismuEnglish(
    word: "bratu",
    keyword: "hail",
    hint: "",
    definition: "x1 is hail/sleet/freezing rain/solid precipitation of material/composition " &
        "including x2",
  ),
  EntryGismuEnglish(
    word: "brazo",
    keyword: "Brazilian",
    hint: "",
    definition: "x1 reflects Brazilian culture/nationality/language in aspect x2",
  ),
  EntryGismuEnglish(
    word: "bredi",
    keyword: "ready",
    hint: "",
    definition: "x1 is ready/prepared for x2 (event)",
  ),
  EntryGismuEnglish(
    word: "bridi",
    keyword: "predicate",
    hint: "",
    definition: "x1 (text) is a predicate relationship with relation x2 among arguments " &
        "(sequence/set) x3",
  ),
  EntryGismuEnglish(
    word: "brife",
    keyword: "breeze",
    hint: "",
    definition: "x1 is a breeze/wind/gale from direction x2 with speed x3; x1 blows from x2",
  ),
  EntryGismuEnglish(
    word: "briju",
    keyword: "office",
    hint: "'bureau'",
    definition: "x1 is an office/bureau/work-place of worker x2 at location x3",
  ),
  EntryGismuEnglish(
    word: "brito",
    keyword: "British",
    hint: "",
    definition: "x1 reflects British/United Kingdom culture/nationality in aspect x2",
  ),
  EntryGismuEnglish(
    word: "broda",
    keyword: "predicate var 1",
    hint: "",
    definition: "1st assignable variable predicate (context determines place structure)",
  ),
  EntryGismuEnglish(
    word: "brode",
    keyword: "predicate var 2",
    hint: "",
    definition: "2nd assignable variable predicate (context determines place structure)",
  ),
  EntryGismuEnglish(
    word: "brodi",
    keyword: "predicate var 3",
    hint: "",
    definition: "3rd assignable variable predicate (context determines place structure)",
  ),
  EntryGismuEnglish(
    word: "brodo",
    keyword: "predicate var 4",
    hint: "",
    definition: "4th assignable variable predicate (context determines place structure)",
  ),
  EntryGismuEnglish(
    word: "brodu",
    keyword: "predicate var 5",
    hint: "",
    definition: "5th assignable variable predicate (context determines place structure)",
  ),
  EntryGismuEnglish(
    word: "bruna",
    keyword: "brother",
    hint: "",
    definition: "x1 is brother of/fraternal to x2 by bond/tie/standard/parent(s) x3; [not " &
        "necess. biological]",
  ),
  EntryGismuEnglish(
    word: "bu",
    keyword: "word to lerfu",
    hint: "",
    definition: "convert any single word to BY",
  ),
  EntryGismuEnglish(
    word: "bu'a",
    keyword: "some selbri 1",
    hint: "",
    definition: "logically quantified predicate variable: some selbri 1",
  ),
  EntryGismuEnglish(
    word: "budjo",
    keyword: "Buddhist",
    hint: "",
    definition: "x1 pertains to the Buddhist culture/religion/ethos in aspect x2",
  ),
  EntryGismuEnglish(
    word: "bukpu",
    keyword: "cloth",
    hint: "",
    definition: "x1 is an amount of cloth/fabric of type/material x2",
  ),
  EntryGismuEnglish(
    word: "bumru",
    keyword: "fog",
    hint: "",
    definition: "x1 is foggy/misty/covered by a fog/mist/vapor of liquid x2",
  ),
  EntryGismuEnglish(
    word: "bunda",
    keyword: "pound",
    hint: "",
    definition: "x1 is x2 (def. 1) local weight unit(s) [non-metric], standard x3, subunits " &
        "[e.g. ounces] x4",
  ),
  EntryGismuEnglish(
    word: "bunre",
    keyword: "brown",
    hint: "",
    definition: "x1 is brown/tan [color adjective]",
  ),
  EntryGismuEnglish(
    word: "burcu",
    keyword: "brush",
    hint: "",
    definition: "x1 is a brush for purpose x2 (event) with bristles x3",
  ),
  EntryGismuEnglish(
    word: "burna",
    keyword: "embarrassed",
    hint: "",
    definition: "x1 is embarrassed/disconcerted/flustered/ill-at-ease about/under conditions x2 " &
        "(abstraction)",
  ),
  EntryGismuEnglish(
    word: "ca'a",
    keyword: "actually is",
    hint: "",
    definition: "modal aspect: actuality/ongoing event",
  ),
  EntryGismuEnglish(
    word: "cabna",
    keyword: "now",
    hint: "",
    definition: "x1 is current at/in the present of/during/concurrent/simultaneous with x2 in time",
  ),
  EntryGismuEnglish(
    word: "cabra",
    keyword: "apparatus",
    hint: "",
    definition: "x1 is apparatus/mechanism/device/equipment for function x2 " &
        "controlled/[triggered] by x3 (agent)",
  ),
  EntryGismuEnglish(
    word: "cacra",
    keyword: "hour",
    hint: "",
    definition: "x1 is x2 hours in duration (default is 1 hour) by standard x3",
  ),
  EntryGismuEnglish(
    word: "cadzu",
    keyword: "walk",
    hint: "",
    definition: "x1 walks/strides/paces on surface x2 using limbs x3",
  ),
  EntryGismuEnglish(
    word: "cafne",
    keyword: "often",
    hint: "",
    definition: "x1 (event) often/frequently/commonly/customarily occurs/recurs by standard x2",
  ),
  EntryGismuEnglish(
    word: "cakla",
    keyword: "chocolate",
    hint: "",
    definition: "x1 is made of/contains/is a quantity of chocolate/cocoa",
  ),
  EntryGismuEnglish(
    word: "calku",
    keyword: "shell",
    hint: "",
    definition: "x1 is a shell/husk [hard, protective covering] around x2 composed of x3",
  ),
  EntryGismuEnglish(
    word: "canci",
    keyword: "vanish",
    hint: "",
    definition: "x1 vanishes/disappears from location x2; x1 ceases to be observed at x2 using " &
        "senses/sensor x3",
  ),
  EntryGismuEnglish(
    word: "cando",
    keyword: "idle",
    hint: "",
    definition: "x1 is idle/at rest/inactive",
  ),
  EntryGismuEnglish(
    word: "cange",
    keyword: "farm",
    hint: "'grange, agrarian'",
    definition: "x1 is a farm/ranch at x2, farmed by x3, raising/producing x4; (adjective:) x1 " &
        "is agrarian",
  ),
  EntryGismuEnglish(
    word: "canja",
    keyword: "exchange",
    hint: "",
    definition: "x1 exchanges/trades/barters commodity x2 for x3 with x4; x1, x4 is a " &
        "trader/merchant/businessman",
  ),
  EntryGismuEnglish(
    word: "canko",
    keyword: "window",
    hint: "",
    definition: "x1 is a window/portal/opening [portal] in wall/building/structure x2",
  ),
  EntryGismuEnglish(
    word: "canlu",
    keyword: "space",
    hint: "'volume'",
    definition: "x1 is space/volume/region/room [at-least-3-dimensional area] occupied by x2",
  ),
  EntryGismuEnglish(
    word: "canpa",
    keyword: "shovel",
    hint: "",
    definition: "x1 is a shovel/spade [bladed digging implement] for digging x2",
  ),
  EntryGismuEnglish(
    word: "canre",
    keyword: "sand",
    hint: "",
    definition: "x1 is a quantity of/contains/is made of sand/grit from source x2 of composition " &
        "including x3",
  ),
  EntryGismuEnglish(
    word: "canti",
    keyword: "gut",
    hint: "'entrails'",
    definition: "x1 is a/the gut(s)/entrails/intestines/viscera/innards/digestive system " &
        "[body-part] of x2",
  ),
  EntryGismuEnglish(
    word: "carce",
    keyword: "cart",
    hint: "",
    definition: "x1 is a cart/carriage/wagon [wheeled vehicle] for carrying x2, propelled by x3",
  ),
  EntryGismuEnglish(
    word: "carmi",
    keyword: "intense",
    hint: "",
    definition: "x1 is intense/bright/saturated/brilliant in property (ka) x2 as " &
        "received/measured by observer x3",
  ),
  EntryGismuEnglish(
    word: "carna",
    keyword: "turn",
    hint: "",
    definition: "x1 turns/rotates/revolves around axis x2 in direction x3",
  ),
  EntryGismuEnglish(
    word: "cartu",
    keyword: "chart",
    hint: "",
    definition: "x1 is a chart/diagram/map of/about x2 showing formation/data-points x3",
  ),
  EntryGismuEnglish(
    word: "carvi",
    keyword: "rain",
    hint: "",
    definition: "x1 rains/showers/[precipitates] to x2 from x3; x1 is precipitation [not limited " &
        "to 'rain']",
  ),
  EntryGismuEnglish(
    word: "casnu",
    keyword: "discuss",
    hint: "",
    definition: "x1(s) (mass normally, but 1 individual/jo'u possible) discuss(es)/talk(s) about " &
        "topic/subject x2",
  ),
  EntryGismuEnglish(
    word: "catke",
    keyword: "shove",
    hint: "",
    definition: "x1 [agent] shoves/pushes x2 at locus x3",
  ),
  EntryGismuEnglish(
    word: "catlu",
    keyword: "look",
    hint: "",
    definition: "x1 looks at/examines/views/inspects/regards/watches/gazes at x2",
  ),
  EntryGismuEnglish(
    word: "catni",
    keyword: "authority",
    hint: "",
    definition: "x1 has authority/is an official in/on/over matter/sphere/persons x2 derived on " &
        "basis x3",
  ),
  EntryGismuEnglish(
    word: "catra",
    keyword: "kill",
    hint: "'slaughter'",
    definition: "x1 (agent) kills/slaughters/murders x2 by action/method x3",
  ),
  EntryGismuEnglish(
    word: "caxno",
    keyword: "shallow",
    hint: "",
    definition: "x1 is shallow in extent in direction/property x2 away from reference point x3 " &
        "by standard x4",
  ),
  EntryGismuEnglish(
    word: "ce",
    keyword: "in a set with",
    hint: "",
    definition: "non-logical connective: set link, unordered; \"and also\", but forming a set",
  ),
  EntryGismuEnglish(
    word: "ce'i",
    keyword: "percent",
    hint: "",
    definition: "digit/number: % percentage symbol, hundredths",
  ),
  EntryGismuEnglish(
    word: "ce'o",
    keyword: "in a sequence with",
    hint: "",
    definition: "non-logical connective: ordered sequence link; \"and then\", forming a sequence",
  ),
  EntryGismuEnglish(
    word: "cecla",
    keyword: "launcher",
    hint: "",
    definition: "x1 launches/fires/shoots projectile/missile x2, propelled by x3 " &
        "[propellant/propulsion]",
  ),
  EntryGismuEnglish(
    word: "cecmu",
    keyword: "community",
    hint: "",
    definition: "x1 is a community/colony of organisms x2",
  ),
  EntryGismuEnglish(
    word: "cedra",
    keyword: "era",
    hint: "",
    definition: "x1 is an era/epoch/age characterized by x2 (event/property/interval/idea)",
  ),
  EntryGismuEnglish(
    word: "cenba",
    keyword: "vary",
    hint: "",
    definition: "x1 varies/changes in property/quantity x2 (ka/ni) in amount/degree x3 under " &
        "conditions x4",
  ),
  EntryGismuEnglish(
    word: "censa",
    keyword: "holy",
    hint: "'sacred'",
    definition: "x1 is holy/sacred to person/people/culture/religion/cult/group x2",
  ),
  EntryGismuEnglish(
    word: "centi",
    keyword: ".01",
    hint: "metric 'centi'",
    definition: "x1 is a hundredth [1/100; 1x10**-2] of x2 in dimension/aspect x3 (default is " &
        "units)",
  ),
  EntryGismuEnglish(
    word: "cerda",
    keyword: "heir",
    hint: "",
    definition: "x1 is an heir to/is to inherit x2 (object/quality) from x3 according to rule x4",
  ),
  EntryGismuEnglish(
    word: "cerni",
    keyword: "morning",
    hint: "",
    definition: "x1 is a morning [dawn until after typical start-of-work for locale] of day x2 " &
        "at location x3",
  ),
  EntryGismuEnglish(
    word: "certu",
    keyword: "expert",
    hint: "",
    definition: "x1 is an expert/pro/has prowess in/is skilled at x2 (event/activity) by " &
        "standard x3",
  ),
  EntryGismuEnglish(
    word: "cevni",
    keyword: "god",
    hint: "'divinity'",
    definition: "x1 is a/the god/deity of people(s)/religion x2 with dominion over x3 [sphere]; " &
        "x1 is divine",
  ),
  EntryGismuEnglish(
    word: "cfari",
    keyword: "initiate",
    hint: "",
    definition: "x1 [state/event/process] commences/initiates/starts/begins to occur; " &
        "(intransitive verb)",
  ),
  EntryGismuEnglish(
    word: "cfika",
    keyword: "fiction",
    hint: "",
    definition: "x1 is a work of fiction about plot/theme/subject x2/under convention x2 by " &
        "author x3",
  ),
  EntryGismuEnglish(
    word: "cfila",
    keyword: "flaw",
    hint: "",
    definition: "x1 (property - ka) is a flaw/fault/defect in x2 causing x3",
  ),
  EntryGismuEnglish(
    word: "cfine",
    keyword: "wedge",
    hint: "",
    definition: "x1 is a wedge [shape/form/tool] of material x2",
  ),
  EntryGismuEnglish(
    word: "cfipu",
    keyword: "confusing",
    hint: "",
    definition: "x1 (event/state) confuses/baffles x2 [observer] due to [confusing] property x3 " &
        "(ka)",
  ),
  EntryGismuEnglish(
    word: "ci",
    keyword: "3",
    hint: "",
    definition: "digit/number: 3 (digit)",
  ),
  EntryGismuEnglish(
    word: "ciblu",
    keyword: "blood",
    hint: "",
    definition: "x1 is blood/vital fluid of organism x2",
  ),
  EntryGismuEnglish(
    word: "cicna",
    keyword: "cyan",
    hint: "",
    definition: "x1 is cyan/turquoise/greenish-blue [color adjective]",
  ),
  EntryGismuEnglish(
    word: "cidja",
    keyword: "food",
    hint: "'feed'",
    definition: "x1 is food/feed/nutriment for x2; x1 is edible/gives nutrition to x2",
  ),
  EntryGismuEnglish(
    word: "cidni",
    keyword: "knee",
    hint: "",
    definition: "x1 is a/the knee/elbow/knuckle [hinged joint, body-part] of limb x2 of body x3",
  ),
  EntryGismuEnglish(
    word: "cidro",
    keyword: "hydrogen",
    hint: "",
    definition: "x1 is a quantity of/contains/is made of hydrogen (H); [metaphor: light, " &
        "flammable]",
  ),
  EntryGismuEnglish(
    word: "cifnu",
    keyword: "infant",
    hint: "",
    definition: "x1 is an infant/baby [helpless through youth/incomplete development] of species " &
        "x2",
  ),
  EntryGismuEnglish(
    word: "cigla",
    keyword: "gland",
    hint: "",
    definition: "x1 is a/the gland [body-part] secreting x2, of body x3; x2 is a secretion of x1",
  ),
  EntryGismuEnglish(
    word: "cikna",
    keyword: "awake",
    hint: "",
    definition: "(adjective:) x1 is awake/alert/conscious",
  ),
  EntryGismuEnglish(
    word: "cikre",
    keyword: "repair",
    hint: "'fix'",
    definition: "x1 repairs/mends/fixes x2 for use x3",
  ),
  EntryGismuEnglish(
    word: "ciksi",
    keyword: "explain",
    hint: "",
    definition: "x1 (person) explains x2 (event/state/property) to x3 with explanation x4 (du'u)",
  ),
  EntryGismuEnglish(
    word: "cilce",
    keyword: "wild",
    hint: "",
    definition: "(adjective:) x1 is wild/untamed",
  ),
  EntryGismuEnglish(
    word: "cilmo",
    keyword: "moist",
    hint: "",
    definition: "x1 is moist/wet/damp with liquid x2",
  ),
  EntryGismuEnglish(
    word: "cilre",
    keyword: "learn",
    hint: "",
    definition: "x1 learns x2 (du'u) about subject x3 from source x4 (obj./event) by method x5 " &
        "(event/process)",
  ),
  EntryGismuEnglish(
    word: "cilta",
    keyword: "thread",
    hint: "'filament'",
    definition: "x1 is a thread/filament/wire [shape/form] of material x2",
  ),
  EntryGismuEnglish(
    word: "cimde",
    keyword: "dimension",
    hint: "",
    definition: "x1 (property - ka) is a dimension of space/object x2 according to rules/model x3",
  ),
  EntryGismuEnglish(
    word: "cimni",
    keyword: "infinite",
    hint: "",
    definition: "x1 is infinite/unending/eternal in property/dimension x2, to degree x3 " &
        "(quantity)/of type x3",
  ),
  EntryGismuEnglish(
    word: "cinba",
    keyword: "kiss",
    hint: "'buss'",
    definition: "x1 (agent) kisses/busses x2 at locus x3",
  ),
  EntryGismuEnglish(
    word: "cindu",
    keyword: "oak",
    hint: "",
    definition: "x1 is an oak, a type of tree of species/strain x2",
  ),
  EntryGismuEnglish(
    word: "cinfo",
    keyword: "lion",
    hint: "",
    definition: "x1 is a lion/[lioness] of species/breed x2",
  ),
  EntryGismuEnglish(
    word: "cinje",
    keyword: "wrinkle",
    hint: "",
    definition: "x1 is a wrinkle/crease/fold [shape/form] in x2",
  ),
  EntryGismuEnglish(
    word: "cinki",
    keyword: "insect",
    hint: "",
    definition: "x1 is an insect/arthropod of species x2; [bug/beetle]",
  ),
  EntryGismuEnglish(
    word: "cinla",
    keyword: "thin",
    hint: "'lean'",
    definition: "x1 is thin in direction/dimension x2 by standard x3; [relatively short in " &
        "smallest dimension]",
  ),
  EntryGismuEnglish(
    word: "cinmo",
    keyword: "emotion",
    hint: "",
    definition: "x1 feels emotion x2 (ka) about x3",
  ),
  EntryGismuEnglish(
    word: "cinri",
    keyword: "interesting",
    hint: "'interests'",
    definition: "x1 (abstraction) interests/is interesting to x2; x2 is interested in x1",
  ),
  EntryGismuEnglish(
    word: "cinse",
    keyword: "sexual",
    hint: "",
    definition: "x1 in activity/state x2 exhibits sexuality/gender/sexual orientation x3 (ka) by " &
        "standard x4",
  ),
  EntryGismuEnglish(
    word: "cinta",
    keyword: "paint",
    hint: "",
    definition: "x1 [material] is a paint of pigment/active substance x2, in a base of x3",
  ),
  EntryGismuEnglish(
    word: "cinza",
    keyword: "tongs",
    hint: "",
    definition: "x1 is a/are tong(s)/chopsticks/pincers/tweezers/pliers [tool/body-part] for x2 " &
        "to pinch x3",
  ),
  EntryGismuEnglish(
    word: "cipni",
    keyword: "bird",
    hint: "",
    definition: "x1 is a bird/avian/fowl of species x2",
  ),
  EntryGismuEnglish(
    word: "cipra",
    keyword: "test",
    hint: "'proof'",
    definition: "x1 (process/event) is a test for/proof of property/state x2 in subject x3 " &
        "(individ./set/mass)",
  ),
  EntryGismuEnglish(
    word: "cirko",
    keyword: "lose",
    hint: "",
    definition: "x1 loses person/thing x2 at/near x3; x1 loses property/feature x2 in " &
        "conditions/situation x3",
  ),
  EntryGismuEnglish(
    word: "cirla",
    keyword: "cheese",
    hint: "",
    definition: "x1 is a quantity of/contains cheese/curd from source x2",
  ),
  EntryGismuEnglish(
    word: "ciska",
    keyword: "write",
    hint: "'scribe'",
    definition: "x1 inscribes/writes x2 on display/storage medium x3 with writing implement x4; " &
        "x1 is a scribe",
  ),
  EntryGismuEnglish(
    word: "cisma",
    keyword: "smile",
    hint: "",
    definition: "x1 smiles/grins (facial expression)",
  ),
  EntryGismuEnglish(
    word: "ciste",
    keyword: "system",
    hint: "",
    definition: "x1 (mass) system interrelated by structure x2 among components x3 (set) " &
        "displaying x4 (ka)",
  ),
  EntryGismuEnglish(
    word: "citka",
    keyword: "eat",
    hint: "",
    definition: "x1 eats/ingests/consumes (transitive verb) x2",
  ),
  EntryGismuEnglish(
    word: "citno",
    keyword: "young",
    hint: "'junior'",
    definition: "x1 is young/youthful [relatively short in elapsed duration] by standard x2",
  ),
  EntryGismuEnglish(
    word: "citri",
    keyword: "history",
    hint: "",
    definition: "x1 is a history of x2 according to x3 (person)/from point-of-view x3",
  ),
  EntryGismuEnglish(
    word: "citsi",
    keyword: "season",
    hint: "",
    definition: "x1 is a season/is seasonal [cyclical interval], defined by interval/property " &
        "x2, of year(s) x3",
  ),
  EntryGismuEnglish(
    word: "civla",
    keyword: "louse",
    hint: "",
    definition: "x1 is a louse/flea [blood-sucking arthropod] of species/breed x2, parasitic on x3",
  ),
  EntryGismuEnglish(
    word: "cizra",
    keyword: "strange",
    hint: "'bizarre'",
    definition: "x1 is strange/weird/deviant/bizarre/odd to x2 in property x3 (ka)",
  ),
  EntryGismuEnglish(
    word: "ckabu",
    keyword: "rubber",
    hint: "",
    definition: "x1 is a quantity of/contains/is made of rubber/latex from source x2 of " &
        "composition including x3",
  ),
  EntryGismuEnglish(
    word: "ckafi",
    keyword: "coffee",
    hint: "",
    definition: "x1 is made of/contains/is a quantity of coffee from source/bean/grain x2",
  ),
  EntryGismuEnglish(
    word: "ckaji",
    keyword: "quality",
    hint: "",
    definition: "x1 has/is characterized by property/feature/trait/aspect/dimension x2 (ka); x2 " &
        "is manifest in x1",
  ),
  EntryGismuEnglish(
    word: "ckana",
    keyword: "bed",
    hint: "",
    definition: "x1 is a bed/pallet of material x2 for holding/supporting x3 (person/object/event)",
  ),
  EntryGismuEnglish(
    word: "ckape",
    keyword: "peril",
    hint: "",
    definition: "x1 is perilous/dangerous/potentially harmful to x2 under conditions x3",
  ),
  EntryGismuEnglish(
    word: "ckasu",
    keyword: "ridicule",
    hint: "'scoff'",
    definition: "x1 ridicules/mocks/scoffs at x2 about x3 (property/event) by doing activity x4 " &
        "(event)",
  ),
  EntryGismuEnglish(
    word: "ckeji",
    keyword: "ashamed",
    hint: "",
    definition: "x1 feels ashamed/mortified/humiliated under conditions x2 before " &
        "community/audience x3",
  ),
  EntryGismuEnglish(
    word: "ckiku",
    keyword: "key",
    hint: "",
    definition: "x1 is a key fitting/releasing/opening/unlocking lock x2, and having relevant " &
        "properties x3",
  ),
  EntryGismuEnglish(
    word: "ckilu",
    keyword: "scale",
    hint: "",
    definition: "x1 (si'o) is a scale of units for measuring/observing/determining x2 (state)",
  ),
  EntryGismuEnglish(
    word: "ckini",
    keyword: "related",
    hint: "'akin, kin'",
    definition: "x1 is related to/associated with/akin to x2 by relationship x3",
  ),
  EntryGismuEnglish(
    word: "ckire",
    keyword: "grateful",
    hint: "",
    definition: "x1 is grateful/thankful to/appreciative of x2 for x3 (event/property)",
  ),
  EntryGismuEnglish(
    word: "ckule",
    keyword: "school",
    hint: "",
    definition: "x1 is school/institute/academy at x2 teaching subject(s) x3 to audien./commun. " &
        "x4 operated by x5",
  ),
  EntryGismuEnglish(
    word: "ckunu",
    keyword: "conifer",
    hint: "'cone'",
    definition: "x1 is a conifer/pine/fir of species/strain x2 with cones x3",
  ),
  EntryGismuEnglish(
    word: "cladu",
    keyword: "loud",
    hint: "",
    definition: "x1 is loud/noisy at observation point x2 by standard x3",
  ),
  EntryGismuEnglish(
    word: "clani",
    keyword: "long",
    hint: "",
    definition: "x1 is long in dimension/direction x2 (default longest dimension) by measurement " &
        "standard x3",
  ),
  EntryGismuEnglish(
    word: "claxu",
    keyword: "without",
    hint: "'lack'",
    definition: "x1 is without/lacking/free of/lacks x2; x1 is x2-less",
  ),
  EntryGismuEnglish(
    word: "clika",
    keyword: "mossy",
    hint: "",
    definition: "x1 is a moss/lichen of species/strain x2 growing on x3; (adjective:) x1 is mossy",
  ),
  EntryGismuEnglish(
    word: "clira",
    keyword: "early",
    hint: "",
    definition: "x1 (event) is early by standard x2",
  ),
  EntryGismuEnglish(
    word: "clite",
    keyword: "polite",
    hint: "",
    definition: "x1 is polite/courteous/civil in matter x2 according to standard/custom x3",
  ),
  EntryGismuEnglish(
    word: "cliva",
    keyword: "leave",
    hint: "",
    definition: "x1 leaves/goes away/departs/parts/separates from x2 via route x3",
  ),
  EntryGismuEnglish(
    word: "clupa",
    keyword: "loop",
    hint: "",
    definition: "x1 is a loop/circuit of x2 [material]",
  ),
  EntryGismuEnglish(
    word: "cmaci",
    keyword: "mathematics",
    hint: "",
    definition: "x1 is a mathematics of type/describing x2",
  ),
  EntryGismuEnglish(
    word: "cmalu",
    keyword: "small",
    hint: "",
    definition: "x1 is small in property/dimension(s) x2 (ka) as compared with standard/norm x3",
  ),
  EntryGismuEnglish(
    word: "cmana",
    keyword: "mountain",
    hint: "",
    definition: "x1 is a mountain/hill/mound/[rise]/[peak]/[summit]/[highlands] projecting from " &
        "land mass x2",
  ),
  EntryGismuEnglish(
    word: "cmavo",
    keyword: "structure word",
    hint: "",
    definition: "x1 is a structure word of grammatical class x2, with meaning/function x3 in " &
        "usage (language) x4",
  ),
  EntryGismuEnglish(
    word: "cmene",
    keyword: "name",
    hint: "",
    definition: "x1 (quoted word(s)) is a/the name/title/tag of x2 to/used-by namer/name-user x3 " &
        "(person)",
  ),
  EntryGismuEnglish(
    word: "cmila",
    keyword: "laugh",
    hint: "'smile'",
    definition: "x1 laughs (emotional expression)",
  ),
  EntryGismuEnglish(
    word: "cmima",
    keyword: "member",
    hint: "",
    definition: "x1 is a member/element of set x2; x1 belongs to group x2; x1 is " &
        "amid/among/amongst group x2",
  ),
  EntryGismuEnglish(
    word: "cmoni",
    keyword: "moan",
    hint: "",
    definition: "x1 utters moan/groan/howl/scream [non-linguistic utterance] x2 expressing x3 " &
        "(property)",
  ),
  EntryGismuEnglish(
    word: "cnano",
    keyword: "norm",
    hint: "",
    definition: "x1 [value] is a norm/average in property/amount x2 (ka/ni) among x3(s) (set) by " &
        "standard x4",
  ),
  EntryGismuEnglish(
    word: "cnebo",
    keyword: "neck",
    hint: "",
    definition: "x1 is a/the neck [body-part] of x2; [metaphor: a relatively narrow point]",
  ),
  EntryGismuEnglish(
    word: "cnemu",
    keyword: "reward",
    hint: "",
    definition: "x1 (agent) rewards x2 [recipient] for atypical x3 (event/property) with " &
        "reward/desserts x4",
  ),
  EntryGismuEnglish(
    word: "cnici",
    keyword: "orderly",
    hint: "'neat'",
    definition: "x1 is orderly/neat/ordered in property/quantity x2 (ka/ni)",
  ),
  EntryGismuEnglish(
    word: "cnino",
    keyword: "new",
    hint: "",
    definition: "x1 is new/unfamiliar/novel to observer x2 in feature x3 (ka) by standard x4; x1 " &
        "is a novelty",
  ),
  EntryGismuEnglish(
    word: "cnisa",
    keyword: "lead",
    hint: "",
    definition: "x1 is a quantity of/contains/is made of lead (Pb); [metaphor: heavy, malleable, " &
        "soft metal]",
  ),
  EntryGismuEnglish(
    word: "cnita",
    keyword: "beneath",
    hint: "",
    definition: "x1 is directly/vertically beneath/below/under/underneath/down from x2 in frame " &
        "of reference x3",
  ),
  EntryGismuEnglish(
    word: "co",
    keyword: "tanru inversion",
    hint: "",
    definition: "tanru inversion operator; \"... of type ...\"; allows modifier trailing sumti " &
        "without sumti links",
  ),
  EntryGismuEnglish(
    word: "co'a",
    keyword: "initiative",
    hint: "",
    definition: "interval event contour: at the starting point of ...; " &
        "initiative                   >|<    |",
  ),
  EntryGismuEnglish(
    word: "co'e",
    keyword: "unspecif bridi",
    hint: "",
    definition: "elliptical/unspecified bridi relationship",
  ),
  EntryGismuEnglish(
    word: "co'u",
    keyword: "cessative",
    hint: "",
    definition: "interval event contour: at the ending point of ... even if not done; " &
        "cessative      |  >< |",
  ),
  EntryGismuEnglish(
    word: "cokcu",
    keyword: "soak up",
    hint: "",
    definition: "x1 soaks up/absorbs/sucks up x2 from x3 into x4; x1 is an absorbant",
  ),
  EntryGismuEnglish(
    word: "condi",
    keyword: "deep",
    hint: "",
    definition: "x1 is deep in extent in direction/property x2 away from reference point x3 by " &
        "standard x4",
  ),
  EntryGismuEnglish(
    word: "cortu",
    keyword: "pain",
    hint: "'hurt'",
    definition: "x1 hurts/feels pain/hurt at locus x2",
  ),
  EntryGismuEnglish(
    word: "cpacu",
    keyword: "get",
    hint: "'acquire'",
    definition: "x1 gets/procures/acquires/obtains/accepts x2 from source x3 [previous possessor " &
        "not implied]",
  ),
  EntryGismuEnglish(
    word: "cpana",
    keyword: "upon",
    hint: "",
    definition: "x1 is upon/atop/resting on/lying on [the upper surface of] x2 in frame of " &
        "reference/gravity x3",
  ),
  EntryGismuEnglish(
    word: "cpare",
    keyword: "climb",
    hint: "",
    definition: "x1 climbs/clambers/creeps/crawls on surface x2 in direction x3 using x4 " &
        "[limbs/tools]",
  ),
  EntryGismuEnglish(
    word: "cpedu",
    keyword: "request",
    hint: "",
    definition: "x1 requests/asks/petitions/solicits for x2 of/from x3 in manner/form x4",
  ),
  EntryGismuEnglish(
    word: "cpina",
    keyword: "pungent",
    hint: "",
    definition: "x1 is pungent/piquant/peppery/spicy/irritating to sense x2",
  ),
  EntryGismuEnglish(
    word: "cradi",
    keyword: "radio",
    hint: "",
    definition: "x1 broadcasts/transmits [using radio waves] x2 via station/frequency x3 to " &
        "[radio] receiver x4",
  ),
  EntryGismuEnglish(
    word: "crane",
    keyword: "front",
    hint: "",
    definition: "x1 is anterior/ahead/forward/(in/on) the front of x2 which " &
        "faces/in-frame-of-reference x3",
  ),
  EntryGismuEnglish(
    word: "creka",
    keyword: "shirt",
    hint: "",
    definition: "x1 is a shirt/blouse/top [upper-body garment - not necessarily sleeved or " &
        "buttoned], material x2",
  ),
  EntryGismuEnglish(
    word: "crepu",
    keyword: "harvest",
    hint: "'reap'",
    definition: "x1 (agent) harvests/reaps/gathers crop/product/objects x2 from source/area x3",
  ),
  EntryGismuEnglish(
    word: "cribe",
    keyword: "bear",
    hint: "",
    definition: "x1 is a bear/ursoid of species/breed x2",
  ),
  EntryGismuEnglish(
    word: "crida",
    keyword: "fairy",
    hint: "",
    definition: "x1 is a fairy/elf/gnome/brownie/pixie/goblin/kobold [mythical humanoid] of " &
        "mythos/religion x2",
  ),
  EntryGismuEnglish(
    word: "crino",
    keyword: "green",
    hint: "",
    definition: "x1 is green/verdant [color adjective]",
  ),
  EntryGismuEnglish(
    word: "cripu",
    keyword: "bridge",
    hint: "",
    definition: "x1 is a bridge/span over/across x2 between x3 and x4 [unordered, typically " &
        "destination first]",
  ),
  EntryGismuEnglish(
    word: "crisa",
    keyword: "summer",
    hint: "",
    definition: "x1 is summer/summertime [hot season] of year x2 at location x3",
  ),
  EntryGismuEnglish(
    word: "critu",
    keyword: "autumn",
    hint: "",
    definition: "x1 is autumn/fall [harvest/cooling season] of year x2 at location x3",
  ),
  EntryGismuEnglish(
    word: "ctaru",
    keyword: "tide",
    hint: "",
    definition: "x1 is a tide [cyclical/periodic expansion] in x2 caused by x3",
  ),
  EntryGismuEnglish(
    word: "ctebi",
    keyword: "lip",
    hint: "'labial'",
    definition: "x1 is a/the lip [body-part]/rim of orifice x2 of body x3; (adjective:) x1 is " &
        "labial",
  ),
  EntryGismuEnglish(
    word: "cteki",
    keyword: "tax",
    hint: "",
    definition: "x1 is a tax/levy/duty on goods/services/event x2 levied against x3 by " &
        "authority/collector x4",
  ),
  EntryGismuEnglish(
    word: "ctile",
    keyword: "petroleum",
    hint: "'oil'",
    definition: "x1 is a quantity of petroleum/oil from source x2",
  ),
  EntryGismuEnglish(
    word: "ctino",
    keyword: "shadow",
    hint: "'shade'",
    definition: "x1 is a shadow/the shade of object x2, made by light/energy source x3",
  ),
  EntryGismuEnglish(
    word: "ctuca",
    keyword: "teach",
    hint: "",
    definition: "x1 teaches audience x2 ideas/methods/lore x3 (du'u) about subject(s) x4 by " &
        "method x5 (event)",
  ),
  EntryGismuEnglish(
    word: "cukla",
    keyword: "round",
    hint: "'circular'",
    definition: "x1 is round/circular [2-dimensional shape/form]; x1 is a disk/circle/ring",
  ),
  EntryGismuEnglish(
    word: "cukta",
    keyword: "book",
    hint: "",
    definition: "x1 is a book containing work x2 by author x3 for audience x4 preserved in " &
        "medium x5",
  ),
  EntryGismuEnglish(
    word: "culno",
    keyword: "full",
    hint: "",
    definition: "x1 is full/completely filled with x2",
  ),
  EntryGismuEnglish(
    word: "cumki",
    keyword: "possible",
    hint: "'maybe'",
    definition: "x1 (event/state/property) is possible under conditions x2; x1 may/might occur; " &
        "x1 is a maybe",
  ),
  EntryGismuEnglish(
    word: "cumla",
    keyword: "humble",
    hint: "'humility'",
    definition: "x1 is humble/modest about x2 (abstraction); x1 displays humility about x2",
  ),
  EntryGismuEnglish(
    word: "cunmi",
    keyword: "millet",
    hint: "",
    definition: "x1 is a quantity of millet [grain] of species/strain x2",
  ),
  EntryGismuEnglish(
    word: "cunso",
    keyword: "random",
    hint: "'chance'",
    definition: "x1 is random/fortuitous/unpredictable under conditions x2, with probability " &
        "distribution x3",
  ),
  EntryGismuEnglish(
    word: "cuntu",
    keyword: "affair",
    hint: "",
    definition: "x1 is an affair/organized activity involving person(s) x2 (ind./mass); x1 is " &
        "x2's business",
  ),
  EntryGismuEnglish(
    word: "cupra",
    keyword: "produce",
    hint: "",
    definition: "x1 produces x2 [product] by process x3",
  ),
  EntryGismuEnglish(
    word: "curmi",
    keyword: "let",
    hint: "'permit'",
    definition: "x1 (agent) lets/permits/allows x2 (event) under conditions x3; x1 grants " &
        "privilege x2",
  ),
  EntryGismuEnglish(
    word: "curnu",
    keyword: "worm",
    hint: "",
    definition: "x1 is a worm/invertebrate animal of species/breed x2",
  ),
  EntryGismuEnglish(
    word: "curve",
    keyword: "pure",
    hint: "",
    definition: "x1 is pure/unadulterated/unmitigated/simple in property x2 (ka)",
  ),
  EntryGismuEnglish(
    word: "cusku",
    keyword: "express",
    hint: "",
    definition: "x1 (agent) expresses/says x2 (sedu'u/text/lu'e concept) for audience x3 via " &
        "expressive medium x4",
  ),
  EntryGismuEnglish(
    word: "cutci",
    keyword: "shoe",
    hint: "",
    definition: "x1 is a shoe/boot/sandal for covering/protecting [feet/hooves] x2, and of " &
        "material x3",
  ),
  EntryGismuEnglish(
    word: "cutne",
    keyword: "chest",
    hint: "",
    definition: "x1 is a/the chest/thorax/upper trunk/[rib cage/breast] [body-part] of x2",
  ),
  EntryGismuEnglish(
    word: "cuxna",
    keyword: "choose",
    hint: "",
    definition: "x1 chooses/selects x2 [choice] from set/sequence of alternatives x3 (complete " &
        "set)",
  ),
  EntryGismuEnglish(
    word: "da",
    keyword: "something 1",
    hint: "",
    definition: "logically quantified existential pro-sumti: there exists something 1 (usually " &
        "restricted)",
  ),
  EntryGismuEnglish(
    word: "da'a",
    keyword: "all except",
    hint: "",
    definition: "digit/number: all except n; all but n; (default 1)",
  ),
  EntryGismuEnglish(
    word: "dacru",
    keyword: "drawer",
    hint: "",
    definition: "x1 is a drawer/file in structure x2, a [sliding compartment] container for " &
        "contents x3",
  ),
  EntryGismuEnglish(
    word: "dacti",
    keyword: "object",
    hint: "'thing'",
    definition: "x1 is a material object enduring in space-time; x1 is a thing",
  ),
  EntryGismuEnglish(
    word: "dadjo",
    keyword: "Taoist",
    hint: "",
    definition: "x1 pertains to the Taoist culture/ethos/religion in aspect x2",
  ),
  EntryGismuEnglish(
    word: "dakfu",
    keyword: "knife",
    hint: "",
    definition: "x1 is a knife (tool) for cutting x2, with blade of material x3",
  ),
  EntryGismuEnglish(
    word: "dakli",
    keyword: "sack",
    hint: "",
    definition: "x1 is a sack/bag with contents x2, and of material x3",
  ),
  EntryGismuEnglish(
    word: "damba",
    keyword: "fight",
    hint: "'combat'",
    definition: "x1 fights/combats/struggles with x2 over issue x3 (abstract); x1 is a " &
        "fighter/combatant",
  ),
  EntryGismuEnglish(
    word: "damri",
    keyword: "drum",
    hint: "",
    definition: "x1 is a drum/cymbal/gong [percussion musical instrument] with beater/actuator x2",
  ),
  EntryGismuEnglish(
    word: "dandu",
    keyword: "hang",
    hint: "'dangle, suspend'",
    definition: "x1 hangs/dangles/is suspended from x2 by/at/with joint x3",
  ),
  EntryGismuEnglish(
    word: "danfu",
    keyword: "answer",
    hint: "",
    definition: "x1 is the answer/response/solution/[reply] to question/problem x2",
  ),
  EntryGismuEnglish(
    word: "danlu",
    keyword: "animal",
    hint: "",
    definition: "x1 is an animal/creature of species x2; x1 is biologically animate",
  ),
  EntryGismuEnglish(
    word: "danmo",
    keyword: "smoke",
    hint: "",
    definition: "x1 is made of/contains/is a quantity of smoke/smog/air pollution from source x2",
  ),
  EntryGismuEnglish(
    word: "danre",
    keyword: "pressure",
    hint: "",
    definition: "x1 (force) puts pressure on/presses/applies force to x2",
  ),
  EntryGismuEnglish(
    word: "dansu",
    keyword: "dance",
    hint: "",
    definition: "x1 (individual, mass) dances to accompaniment/music/rhythm x2",
  ),
  EntryGismuEnglish(
    word: "danti",
    keyword: "projectile",
    hint: "",
    definition: "x1 is a ballistic projectile [e.g. bullet/missile] for firing by " &
        "[gun/propelling launcher] x2",
  ),
  EntryGismuEnglish(
    word: "daplu",
    keyword: "island",
    hint: "",
    definition: "x1 is an island/atoll/key of [material/properties] x2 in surroundings/body x3; " &
        "x1 is insular",
  ),
  EntryGismuEnglish(
    word: "dapma",
    keyword: "curse",
    hint: "'damn'",
    definition: "x1 curses/damns/condemns x2 to fate (event) x3",
  ),
  EntryGismuEnglish(
    word: "dargu",
    keyword: "road",
    hint: "",
    definition: "x1 is a road/highway to x2 from x3 with route x4 (x2/x3 may be unordered)",
  ),
  EntryGismuEnglish(
    word: "darlu",
    keyword: "argue",
    hint: "",
    definition: "x1 argues for stand x2 against stand x3; [an opponent is not necessary]",
  ),
  EntryGismuEnglish(
    word: "darno",
    keyword: "far",
    hint: "",
    definition: "x1 is far/distant from x2 in property x3 (ka)",
  ),
  EntryGismuEnglish(
    word: "darsi",
    keyword: "audacity",
    hint: "'dare'",
    definition: "x1 shows audacity/chutzpah in behavior x2 (event/activity); x1 dares to do/be " &
        "x2 (event/ka)",
  ),
  EntryGismuEnglish(
    word: "darxi",
    keyword: "hit",
    hint: "",
    definition: "x1 hits/strikes/[beats] x2 with instrument [or body-part] x3 at locus x4",
  ),
  EntryGismuEnglish(
    word: "daski",
    keyword: "pocket",
    hint: "",
    definition: "x1 is a pocket/pouch of/in garment/item x2",
  ),
  EntryGismuEnglish(
    word: "dasni",
    keyword: "wear",
    hint: "",
    definition: "x1 wears/is robed/garbed in x2 as a garment of type x3",
  ),
  EntryGismuEnglish(
    word: "daspo",
    keyword: "destroy",
    hint: "'despoil'",
    definition: "x1 (event) destroys/ruins/wrecks/despoils x2; x1 is destructive",
  ),
  EntryGismuEnglish(
    word: "dasri",
    keyword: "ribbon",
    hint: "",
    definition: "x1 is a ribbon/tape/strip/band/stripe of material x2",
  ),
  EntryGismuEnglish(
    word: "datka",
    keyword: "duck",
    hint: "",
    definition: "x1 is a duck/[drake] of species/breed x2",
  ),
  EntryGismuEnglish(
    word: "datni",
    keyword: "data",
    hint: "",
    definition: "x1 (du'u) [fact/measurement] is data/information/statistic(s) about x2 gathered " &
        "by method x3",
  ),
  EntryGismuEnglish(
    word: "decti",
    keyword: ".1",
    hint: "metric 'deci'",
    definition: "x1 is a tenth [1/10; 1x10**-1] of x2 in dimension/aspect x3 (default is units)",
  ),
  EntryGismuEnglish(
    word: "degji",
    keyword: "finger",
    hint: "'digit'",
    definition: "x1 is a/the finger/digit/toe [body-part] on limb/body site x2 of body x3; " &
        "[metaphor: peninsula]",
  ),
  EntryGismuEnglish(
    word: "dejni",
    keyword: "owe",
    hint: "'debt-or'",
    definition: "x1 owes x2 in debt/obligation to creditor x3 in return for x4 [service, loan]; " &
        "x1 is a debtor",
  ),
  EntryGismuEnglish(
    word: "dekpu",
    keyword: "gallon",
    hint: "'peck'",
    definition: "x1 is x2 (default 1) local volume unit(s) [non-metric; e.g. bushel], standard " &
        "x3, x4 subunits",
  ),
  EntryGismuEnglish(
    word: "dekto",
    keyword: "10",
    hint: "metric 'deka'",
    definition: "x1 is ten [10; 1*10**1] of x2 in dimension/aspect x3 (default is units)",
  ),
  EntryGismuEnglish(
    word: "delno",
    keyword: "candela",
    hint: "'candle-power'",
    definition: "x1 is x2 candela [metric unit] in luminosity (default is 1) by standard x3",
  ),
  EntryGismuEnglish(
    word: "dembi",
    keyword: "bean",
    hint: "",
    definition: "x1 is a bean/pea/leguminous seed from plant [legume] x2",
  ),
  EntryGismuEnglish(
    word: "denci",
    keyword: "tooth",
    hint: "'dental'",
    definition: "x1 is a/the tooth [body-part] of x2; (adjective:) x1 is dental",
  ),
  EntryGismuEnglish(
    word: "denmi",
    keyword: "dense",
    hint: "",
    definition: "x1 is dense/concentrated/packed/intense in property x2 (ka) at location/locus x3",
  ),
  EntryGismuEnglish(
    word: "denpa",
    keyword: "wait",
    hint: "'pause'",
    definition: "x1 awaits/waits/pauses for/until x2 at state x3 before starting/continuing x4 " &
        "(activity/process)",
  ),
  EntryGismuEnglish(
    word: "dertu",
    keyword: "dirt",
    hint: "",
    definition: "x1 is a quantity of/contains/is made of dirt/soil/earth/ground from source x2 " &
        "of composition x3",
  ),
  EntryGismuEnglish(
    word: "derxi",
    keyword: "heap",
    hint: "",
    definition: "x1 is a heap/pile/stack/mound/hill of materials x2 at location x3",
  ),
  EntryGismuEnglish(
    word: "desku",
    keyword: "shake",
    hint: "",
    definition: "x1 shakes/quakes/trembles/quivers/shudders/wobbles/vibrates from force x2",
  ),
  EntryGismuEnglish(
    word: "detri",
    keyword: "date",
    hint: "",
    definition: "x1 is the date [day,{week},{month},year] of event/state x2, at location x3, by " &
        "calendar x4",
  ),
  EntryGismuEnglish(
    word: "dicra",
    keyword: "interrupt",
    hint: "'disturb, disrupt'",
    definition: "x1 (event) interrupts/stops/halts/[disrupts] x2 (object/event/process) due to " &
        "quality x3",
  ),
  EntryGismuEnglish(
    word: "dikca",
    keyword: "electric",
    hint: "'charge'",
    definition: "x1 is electricity [electric charge or current] in/on x2 of polarity/quantity x3 " &
        "(def. negative)",
  ),
  EntryGismuEnglish(
    word: "diklo",
    keyword: "local",
    hint: "",
    definition: "x1 is local to x2; x1 is confined to locus x2 within range x3",
  ),
  EntryGismuEnglish(
    word: "dikni",
    keyword: "regular",
    hint: "'cyclical'",
    definition: "x1 is regular/cyclical/periodic in property (ka)/activity x2 with " &
        "period/interval x3",
  ),
  EntryGismuEnglish(
    word: "dilcu",
    keyword: "quotient",
    hint: "'division'",
    definition: "x1 is a quotient of 'x2/x3' [dividend x2 divided by divisor x3], leaving " &
        "remainder x4",
  ),
  EntryGismuEnglish(
    word: "dilnu",
    keyword: "cloud",
    hint: "",
    definition: "x1 is a cloud/mass of clouds of material x2 in air mass x3 at floor/base " &
        "elevation x4",
  ),
  EntryGismuEnglish(
    word: "dimna",
    keyword: "fate",
    hint: "'doom'",
    definition: "x1 is a fate/destiny of x2; [doom, curse are mabla-forms]; x2 is " &
        "fated/predestined/doomed to x1",
  ),
  EntryGismuEnglish(
    word: "dinju",
    keyword: "building",
    hint: "",
    definition: "x1 is a building/edifice for purpose x2",
  ),
  EntryGismuEnglish(
    word: "dinko",
    keyword: "nail",
    hint: "",
    definition: "x1 is a nail/tack [pointed driven/frictional fastener] of type/size x2 (ka), " &
        "made of material x3",
  ),
  EntryGismuEnglish(
    word: "dirba",
    keyword: "dear",
    hint: "",
    definition: "x1 is dear/precious/darling to x2; x1 is emotionally valued by x2",
  ),
  EntryGismuEnglish(
    word: "dirce",
    keyword: "radiate",
    hint: "",
    definition: "x1 radiates/emits x2 under conditions x3",
  ),
  EntryGismuEnglish(
    word: "dirgo",
    keyword: "drop",
    hint: "",
    definition: "x1 is a drop [small, cohesive shape] of material [liquid/vapor] x2 in " &
        "surrounding material x3",
  ),
  EntryGismuEnglish(
    word: "dizlo",
    keyword: "low",
    hint: "",
    definition: "x1 is low/down/downward in frame of reference x2 as compared with " &
        "baseline/standard height x3",
  ),
  EntryGismuEnglish(
    word: "djacu",
    keyword: "water",
    hint: "'aqua-'",
    definition: "x1 is made of/contains/is a quantity/expanse of water; (adjective:) x1 is " &
        "aqueous/[aquatic]",
  ),
  EntryGismuEnglish(
    word: "djedi",
    keyword: "full day",
    hint: "",
    definition: "x1 is x2 full days in duration (default is 1 day) by standard x3; (adjective:) " &
        "x1 is diurnal",
  ),
  EntryGismuEnglish(
    word: "djica",
    keyword: "desire",
    hint: "",
    definition: "x1 desires/wants/wishes x2 (event/state) for purpose x3",
  ),
  EntryGismuEnglish(
    word: "djine",
    keyword: "ring",
    hint: "",
    definition: "x1 is a ring/annulus/torus/circle [shape/form] of material x2, inside diam. x3, " &
        "outside diam. x4",
  ),
  EntryGismuEnglish(
    word: "djuno",
    keyword: "know",
    hint: "",
    definition: "x1 knows fact(s) x2 (du'u) about subject x3 by epistemology x4",
  ),
  EntryGismuEnglish(
    word: "do",
    keyword: "you",
    hint: "",
    definition: "pro-sumti: you listener(s); identified by vocative",
  ),
  EntryGismuEnglish(
    word: "donri",
    keyword: "daytime",
    hint: "",
    definition: "x1 is the daytime of day x2 at location x3; (adjective:) x1 is diurnal (vs. " &
        "nocturnal)",
  ),
  EntryGismuEnglish(
    word: "dotco",
    keyword: "German",
    hint: "'Deutsch'",
    definition: "x1 reflects German/Germanic culture/nationality/language in aspect x2",
  ),
  EntryGismuEnglish(
    word: "draci",
    keyword: "drama",
    hint: "",
    definition: "x1 is a drama/play about x2 [plot/theme/subject] by dramatist x3 for audience " &
        "x4 with actors x5",
  ),
  EntryGismuEnglish(
    word: "drani",
    keyword: "correct",
    hint: "'right'",
    definition: "x1 is correct/proper/right/perfect in property/aspect x2 (ka) in situation x3 " &
        "by standard x4",
  ),
  EntryGismuEnglish(
    word: "drata",
    keyword: "other",
    hint: "",
    definition: "x1 isn't the-same-thing-as/is different-from/other-than x2 by standard x3; x1 " &
        "is something else",
  ),
  EntryGismuEnglish(
    word: "drudi",
    keyword: "roof",
    hint: "",
    definition: "x1 is a roof/top/ceiling/lid of x2",
  ),
  EntryGismuEnglish(
    word: "du",
    keyword: "same identity as",
    hint: "",
    definition: "identity selbri; = sign; x1 identically equals x2, x3, etc.; attached sumti " &
        "refer to same thing",
  ),
  EntryGismuEnglish(
    word: "du'u",
    keyword: "bridi abstract",
    hint: "",
    definition: "abstractor: predication/bridi abstractor; x1 is predication [bridi] expressed " &
        "in sentence x2",
  ),
  EntryGismuEnglish(
    word: "dugri",
    keyword: "logarithm",
    hint: "",
    definition: "x1 is the logarithm of x2 with base x3",
  ),
  EntryGismuEnglish(
    word: "dukse",
    keyword: "excess",
    hint: "",
    definition: "x1 is an excess of/too much of x2 by standard x3",
  ),
  EntryGismuEnglish(
    word: "dukti",
    keyword: "opposite",
    hint: "'contrary'",
    definition: "x1 is polar opposite from/contrary to x2 in property/on scale x3 (property/si'o)",
  ),
  EntryGismuEnglish(
    word: "dunda",
    keyword: "give",
    hint: "'donate'",
    definition: "x1 [donor] gives/donates gift/present x2 to recipient/beneficiary x3 [without " &
        "payment/exchange]",
  ),
  EntryGismuEnglish(
    word: "dunja",
    keyword: "freeze",
    hint: "'jell'",
    definition: "x1 freezes/jells/solidifies at temperature x2 and pressure x3",
  ),
  EntryGismuEnglish(
    word: "dunku",
    keyword: "anguish",
    hint: "",
    definition: "x1 is anguished/distressed/emotionally wrought/stressed by x2",
  ),
  EntryGismuEnglish(
    word: "dunli",
    keyword: "equal",
    hint: "",
    definition: "x1 is equal/congruent to/as much as x2 in property/dimension/quantity x3",
  ),
  EntryGismuEnglish(
    word: "dunra",
    keyword: "winter",
    hint: "",
    definition: "x1 is winter/wintertime [cold season] of year x2 at location x3",
  ),
  EntryGismuEnglish(
    word: "dzena",
    keyword: "elder",
    hint: "",
    definition: "x1 is an elder/ancestor of x2 by bond/tie/degree x3; x1's generation precedes " &
        "x2's parents",
  ),
  EntryGismuEnglish(
    word: "dzipo",
    keyword: "Antarctican",
    hint: "",
    definition: "x1 reflects Antarctican culture/nationality/geography in aspect x2",
  ),
  EntryGismuEnglish(
    word: "facki",
    keyword: "discover",
    hint: "'find'",
    definition: "x1 discovers/finds out x2 (du'u) about subject/object x3; x1 finds (fi) x3 " &
        "(object)",
  ),
  EntryGismuEnglish(
    word: "fadni",
    keyword: "ordinary",
    hint: "",
    definition: "x1 [member] is ordinary/common/typical/usual in property x2 (ka) among members " &
        "of x3 (set)",
  ),
  EntryGismuEnglish(
    word: "fagri",
    keyword: "fire",
    hint: "",
    definition: "x1 is a fire/flame in fuel x2 burning-in/reacting-with oxidizer x3 (default " &
        "air/oxygen)",
  ),
  EntryGismuEnglish(
    word: "falnu",
    keyword: "sail",
    hint: "",
    definition: "x1 is a sail for gathering propelling material x2 on vehicle/motor x3",
  ),
  EntryGismuEnglish(
    word: "famti",
    keyword: "aunt or uncle",
    hint: "",
    definition: "x1 is an aunt/uncle of x2 by bond/tie x3; x1 is an associated member of x2's " &
        "parent's generation",
  ),
  EntryGismuEnglish(
    word: "fancu",
    keyword: "function",
    hint: "",
    definition: "x1 is a function/single-valued mapping from domain x2 to range x3 defined by " &
        "expression/rule x4",
  ),
  EntryGismuEnglish(
    word: "fange",
    keyword: "alien",
    hint: "'foreign'",
    definition: "x1 is alien/foreign/[exotic]/unfamiliar to x2 in property x3 (ka)",
  ),
  EntryGismuEnglish(
    word: "fanmo",
    keyword: "end",
    hint: "'final'",
    definition: "x1 is an end/finish/termination of thing/process x2; [not necessarily implying " &
        "completeness]",
  ),
  EntryGismuEnglish(
    word: "fanri",
    keyword: "factory",
    hint: "'foundry'",
    definition: "x1 is a factory/foundry/industrial plant/mill producing x2 from materials x3",
  ),
  EntryGismuEnglish(
    word: "fanta",
    keyword: "prevent",
    hint: "",
    definition: "x1 prevents/keeps/stops/restrains/constrains event x2 from occurring",
  ),
  EntryGismuEnglish(
    word: "fanva",
    keyword: "translate",
    hint: "",
    definition: "x1 translates text/utterance x2 to language x3 from language x4 with " &
        "translation result x5",
  ),
  EntryGismuEnglish(
    word: "fanza",
    keyword: "annoy",
    hint: "",
    definition: "x1 (event) annoys/irritates/bothers/distracts x2",
  ),
  EntryGismuEnglish(
    word: "fapro",
    keyword: "oppose",
    hint: "",
    definition: "x1 opposes/balances/contends against opponent(s) x2 (person/force ind./mass) " &
        "about x3 (abstract)",
  ),
  EntryGismuEnglish(
    word: "farlu",
    keyword: "fall",
    hint: "",
    definition: "x1 falls/drops to x2 from x3 in gravity well/frame of reference x4",
  ),
  EntryGismuEnglish(
    word: "farna",
    keyword: "direction",
    hint: "",
    definition: "x1 is the direction of x2 (object/event) from origin/in frame of reference x3",
  ),
  EntryGismuEnglish(
    word: "farvi",
    keyword: "develop",
    hint: "'evolve'",
    definition: "x1 develops/evolves towards/into x2 from x3 through stages x4",
  ),
  EntryGismuEnglish(
    word: "fasnu",
    keyword: "event",
    hint: "'happen'",
    definition: "x1 (event) is an event that happens/occurs/takes place; x1 is an " &
        "incident/happening/occurrence",
  ),
  EntryGismuEnglish(
    word: "fatci",
    keyword: "fact",
    hint: "",
    definition: "x1 (du'u) is a fact/reality/truth/actuality, in the absolute",
  ),
  EntryGismuEnglish(
    word: "fatne",
    keyword: "reverse",
    hint: "",
    definition: "x1 [sequence] is in reverse order from x2 [sequence]; x1 (object) is inverted " &
        "from x2 (object)",
  ),
  EntryGismuEnglish(
    word: "fatri",
    keyword: "distribute",
    hint: "",
    definition: "x1 is distributed/allotted/allocated/shared among x2 with shares/portions x3; " &
        "(x2/x3 fa'u)",
  ),
  EntryGismuEnglish(
    word: "febvi",
    keyword: "boil",
    hint: "",
    definition: "x1 boils/evaporates at temperature x2 and pressure x3",
  ),
  EntryGismuEnglish(
    word: "femti",
    keyword: "1E-15",
    hint: "metric 'femto'",
    definition: "x1 is 1x10**-15 of x2 in dimension/aspect x3 (default is units)",
  ),
  EntryGismuEnglish(
    word: "fendi",
    keyword: "divide",
    hint: "",
    definition: "x1 (agent) divides/partitions/separates x2 into sections/parts/ind. x3 by " &
        "method/partition x4",
  ),
  EntryGismuEnglish(
    word: "fengu",
    keyword: "angry",
    hint: "",
    definition: "x1 is angry/mad at x2 for x3 (action/state/property)",
  ),
  EntryGismuEnglish(
    word: "fenki",
    keyword: "crazy",
    hint: "'frenzy'",
    definition: "x1 (action/event) is crazy/insane/mad/frantic/in a frenzy (one sense) by " &
        "standard x2",
  ),
  EntryGismuEnglish(
    word: "fenra",
    keyword: "crack",
    hint: "",
    definition: "x1 is a crack/fissure/pass/cleft/ravine/chasm/[defect/flaw] [shape/form] in x2",
  ),
  EntryGismuEnglish(
    word: "fenso",
    keyword: "sew",
    hint: "",
    definition: "x1 sews/stitches/sutures materials x2 (ind./set) together with tool(s) x3, " &
        "using filament x4",
  ),
  EntryGismuEnglish(
    word: "fepni",
    keyword: "cent",
    hint: "'penny'",
    definition: "x1 is measured in kopeck/cent money-subunits as x2 [quantity], in monetary " &
        "system x3",
  ),
  EntryGismuEnglish(
    word: "fepri",
    keyword: "lung",
    hint: "'pulmonary'",
    definition: "x1 is a/the lung [body-part] of x2; [metaphor: breathing/respiratory " &
        "apparatus/bellows]",
  ),
  EntryGismuEnglish(
    word: "ferti",
    keyword: "fertile",
    hint: "",
    definition: "x1 is fertile/conducive for supporting the growth/development of x2; x1 is " &
        "fruitful/prolific",
  ),
  EntryGismuEnglish(
    word: "festi",
    keyword: "waste",
    hint: "",
    definition: "x1(s) is/are waste product(s) [left to waste] by x2 (event/activity)",
  ),
  EntryGismuEnglish(
    word: "fetsi",
    keyword: "female",
    hint: "'fem-'",
    definition: "x1 is a female/doe of species x2 evidencing feminine trait(s) x3 (ka); x1 is " &
        "feminine",
  ),
  EntryGismuEnglish(
    word: "figre",
    keyword: "fig",
    hint: "",
    definition: "x1 is a fig [fruit/tree] of species/strain x2",
  ),
  EntryGismuEnglish(
    word: "filso",
    keyword: "Palestinian",
    hint: "'Philistine'",
    definition: "x1 reflects Palestinian culture/nationality in aspect x2",
  ),
  EntryGismuEnglish(
    word: "finpe",
    keyword: "fish",
    hint: "'fin'",
    definition: "x1 is a fish of species x2 [metaphorical extension to sharks, non-fish aquatic " &
        "vertebrates]",
  ),
  EntryGismuEnglish(
    word: "finti",
    keyword: "invent",
    hint: "",
    definition: "x1 invents/creates/composes/authors x2 for function/purpose x3 from existing " &
        "elements/ideas x4",
  ),
  EntryGismuEnglish(
    word: "flalu",
    keyword: "law",
    hint: "",
    definition: "x1 is a law specifying x2 (state/event) for community x3 under conditions x4 by " &
        "lawgiver(s) x5",
  ),
  EntryGismuEnglish(
    word: "flani",
    keyword: "flute",
    hint: "",
    definition: "x1 is a flute/pipe/fife/recorder [flute-like/air-reed musical instrument]",
  ),
  EntryGismuEnglish(
    word: "flecu",
    keyword: "flow",
    hint: "'flush'",
    definition: "x1 is a current/flow/river of/in x2 flowing in direction to/towards x3 from " &
        "direction/source x4",
  ),
  EntryGismuEnglish(
    word: "fliba",
    keyword: "fail",
    hint: "'baffle'",
    definition: "x1 fails at doing x2 (state/event); x1 is a failure at its role in x2",
  ),
  EntryGismuEnglish(
    word: "flira",
    keyword: "face",
    hint: "",
    definition: "x1 is a/the face [head/body-part] of x2; (adjective:) x1 is facial",
  ),
  EntryGismuEnglish(
    word: "fo'a",
    keyword: "it-6",
    hint: "",
    definition: "pro-sumti: he/she/it/they #6 (specified by goi)",
  ),
  EntryGismuEnglish(
    word: "fo'e",
    keyword: "it-7",
    hint: "",
    definition: "pro-sumti: he/she/it/they #7 (specified by goi)",
  ),
  EntryGismuEnglish(
    word: "fo'i",
    keyword: "it-8",
    hint: "",
    definition: "pro-sumti: he/she/it/they #8 (specified by goi)",
  ),
  EntryGismuEnglish(
    word: "foldi",
    keyword: "field",
    hint: "",
    definition: "x1 is a field [shape/form] of material x2; x1 is a broad uniform expanse of x2",
  ),
  EntryGismuEnglish(
    word: "fonmo",
    keyword: "foam",
    hint: "",
    definition: "x1 is a quantity of foam/froth/suds of material x2, with bubbles/vacuoles of " &
        "material x3",
  ),
  EntryGismuEnglish(
    word: "fonxa",
    keyword: "telephone",
    hint: "",
    definition: "x1 is a telephone transceiver/modem attached to system/network x2",
  ),
  EntryGismuEnglish(
    word: "forca",
    keyword: "fork",
    hint: "",
    definition: "x1 is a fork/fork-type tool/utensil for purpose x2 with tines/prongs x3 on " &
        "base/support x4",
  ),
  EntryGismuEnglish(
    word: "fraso",
    keyword: "French",
    hint: "'France'",
    definition: "x1 reflects French/Gallic culture/nationality/language in aspect x2",
  ),
  EntryGismuEnglish(
    word: "frati",
    keyword: "react",
    hint: "",
    definition: "x1 reacts/responds/answers with action x2 to stimulus x3 under conditions x4; " &
        "x1 is responsive",
  ),
  EntryGismuEnglish(
    word: "fraxu",
    keyword: "forgive",
    hint: "",
    definition: "x1 forgives x2 for event/state/activity x3",
  ),
  EntryGismuEnglish(
    word: "frica",
    keyword: "differ",
    hint: "",
    definition: "x1 differs/is distinct from/contrasts with/is unlike x2 in " &
        "property/dimension/quantity x3",
  ),
  EntryGismuEnglish(
    word: "friko",
    keyword: "African",
    hint: "",
    definition: "x1 reflects African culture/nationality/geography in aspect x2",
  ),
  EntryGismuEnglish(
    word: "frili",
    keyword: "easy",
    hint: "'freely'",
    definition: "x1 (action) is easy/simple/facile for x2 (agent) under conditions x3; x2 does " &
        "x1 freely/easily",
  ),
  EntryGismuEnglish(
    word: "frinu",
    keyword: "fraction",
    hint: "",
    definition: "x1 is a fraction, with numerator x2, denominator x3 (x2/x3)",
  ),
  EntryGismuEnglish(
    word: "friti",
    keyword: "offer",
    hint: "",
    definition: "x1 offers/proffers x2 [offering] to x3 with conditions x4",
  ),
  EntryGismuEnglish(
    word: "frumu",
    keyword: "frown",
    hint: "",
    definition: "x1 frowns/grimaces (facial expression)",
  ),
  EntryGismuEnglish(
    word: "fukpi",
    keyword: "copy",
    hint: "",
    definition: "x1 is a copy/replica/duplicate/clone of x2 in form/medium x3 made by method x4 " &
        "(event)",
  ),
  EntryGismuEnglish(
    word: "fulta",
    keyword: "float",
    hint: "",
    definition: "x1 (passive) floats on/in fluid (gas/liquid) x2; x1 is buoyant",
  ),
  EntryGismuEnglish(
    word: "funca",
    keyword: "luck",
    hint: "'fortune'",
    definition: "x1 (event/property) is determined by the luck/fortune of x2; (note mabla/zabna " &
        "not implied)",
  ),
  EntryGismuEnglish(
    word: "fusra",
    keyword: "rotten",
    hint: "'rot'",
    definition: "x1 rots/decays/ferments with decay/fermentation agent x2; x1 is " &
        "rotten/decayed/fermented",
  ),
  EntryGismuEnglish(
    word: "fuzme",
    keyword: "responsible",
    hint: "",
    definition: "x1 is responsible/accountable for x2 (action/resulting state) to " &
        "judge/authority x3",
  ),
  EntryGismuEnglish(
    word: "gacri",
    keyword: "cover",
    hint: "",
    definition: "x1 is a cover/[lid/top] for covering/concealing/sheltering x2",
  ),
  EntryGismuEnglish(
    word: "gadri",
    keyword: "article",
    hint: "",
    definition: "x1 is an article/descriptor labelling description x2 (text) in language x3 with " &
        "semantics x4",
  ),
  EntryGismuEnglish(
    word: "galfi",
    keyword: "modify",
    hint: "'alter'",
    definition: "x1 (event) modifies/alters/changes/transforms/converts x2 into x3",
  ),
  EntryGismuEnglish(
    word: "galtu",
    keyword: "high",
    hint: "",
    definition: "x1 is high/up/upward in frame of reference x2 as compared with " &
        "baseline/standard height x3",
  ),
  EntryGismuEnglish(
    word: "galxe",
    keyword: "throat",
    hint: "'gullet'",
    definition: "x1 is a/the throat/gullet [body-part] of x2; [metaphor: narrow(ing) opening of " &
        "a deep hole]",
  ),
  EntryGismuEnglish(
    word: "ganlo",
    keyword: "closed",
    hint: "",
    definition: "x1 (portal/passage/entrance-way) is closed/shut/not open, preventing " &
        "passage/access to x2 by x3",
  ),
  EntryGismuEnglish(
    word: "ganra",
    keyword: "broad",
    hint: "",
    definition: "x1 is broad/wide in dimension x2 [2nd most significant dimension] by standard x3",
  ),
  EntryGismuEnglish(
    word: "ganse",
    keyword: "sense",
    hint: "",
    definition: "x1 [observer] senses/detects/notices stimulus property x2 (ka) by means x3 " &
        "under conditions x4",
  ),
  EntryGismuEnglish(
    word: "ganti",
    keyword: "gonad",
    hint: "'testes'",
    definition: "x1 is a/the testes/ovary/testicle/scrotum/balls/gonad/stamen/pistil [body-part] " &
        "of x2, gender x3",
  ),
  EntryGismuEnglish(
    word: "ganxo",
    keyword: "anus",
    hint: "'asshole/arsehole'",
    definition: "x1 is a/the anus/anal orifice/asshole/arsehole [body-part] of x2; [metaphor: " &
        "exit, waste exit]",
  ),
  EntryGismuEnglish(
    word: "ganzu",
    keyword: "organize",
    hint: "",
    definition: "x1 organizes x2 [relative chaos] into x3 [ordered/organized result] by " &
        "system/principle(s) x4",
  ),
  EntryGismuEnglish(
    word: "gapci",
    keyword: "gas",
    hint: "",
    definition: "x1 is gaseous/fumes/a gas/vapor of material/composition including x2, under " &
        "conditions x3",
  ),
  EntryGismuEnglish(
    word: "gapru",
    keyword: "above",
    hint: "'up'",
    definition: "x1 is directly/vertically above/upwards-from x2 in gravity/frame of reference x3",
  ),
  EntryGismuEnglish(
    word: "garna",
    keyword: "rail",
    hint: "'bar'",
    definition: "x1 is a rail/railing/bar [tool] supporting/restraining x2, of material x3",
  ),
  EntryGismuEnglish(
    word: "gasnu",
    keyword: "do",
    hint: "",
    definition: "x1 [person/agent] is an agentive cause of event x2; x1 does/brings about x2",
  ),
  EntryGismuEnglish(
    word: "gasta",
    keyword: "steel",
    hint: "",
    definition: "x1 is a quantity of/is made of/contains steel of composition including x2",
  ),
  EntryGismuEnglish(
    word: "genja",
    keyword: "root",
    hint: "",
    definition: "x1 is a root [body-part] of plant/species x2; [metaphor: immobile, supporting, " &
        "nourishing]",
  ),
  EntryGismuEnglish(
    word: "gento",
    keyword: "Argentinian",
    hint: "",
    definition: "x1 reflects Argentinian culture/nationality in aspect x2",
  ),
  EntryGismuEnglish(
    word: "genxu",
    keyword: "hook",
    hint: "",
    definition: "x1 is a hook/crook [shape/form] of material x2",
  ),
  EntryGismuEnglish(
    word: "gerku",
    keyword: "dog",
    hint: "",
    definition: "x1 is a dog/canine/[bitch] of species/breed x2",
  ),
  EntryGismuEnglish(
    word: "gerna",
    keyword: "grammar",
    hint: "",
    definition: "x1 is the grammar/rules/defining form of language x2 for structure/text x3",
  ),
  EntryGismuEnglish(
    word: "gidva",
    keyword: "guide",
    hint: "",
    definition: "x1 (person/object/event) guides/conducts/pilots/leads x2 (active participants) " &
        "in/at x3 (event)",
  ),
  EntryGismuEnglish(
    word: "gigdo",
    keyword: "1E9",
    hint: "metric 'giga'",
    definition: "x1 is a billion [British milliard] [1x10**9] of x2 in dimension/aspect x3 " &
        "(default is units)",
  ),
  EntryGismuEnglish(
    word: "ginka",
    keyword: "camp",
    hint: "",
    definition: "x1 is a camp/encampment/temporary residence of x2 at location x3",
  ),
  EntryGismuEnglish(
    word: "girzu",
    keyword: "group",
    hint: "",
    definition: "x1 is group/cluster/team showing common property (ka) x2 due to set x3 linked " &
        "by relations x4",
  ),
  EntryGismuEnglish(
    word: "gismu",
    keyword: "root word",
    hint: "",
    definition: "x1 is a (Lojban) root word expressing relation x2 among argument roles x3, with " &
        "affix(es) x4",
  ),
  EntryGismuEnglish(
    word: "glare",
    keyword: "hot",
    hint: "'warm'",
    definition: "x1 is hot/[warm] by standard x2",
  ),
  EntryGismuEnglish(
    word: "gleki",
    keyword: "happy",
    hint: "'gay'",
    definition: "x1 is happy/gay/merry/glad/gleeful about x2 (event/state)",
  ),
  EntryGismuEnglish(
    word: "gletu",
    keyword: "copulate",
    hint: "'coitus'",
    definition: "x1 copulates/fucks/mates/has coitus/sexual intercourse with x2",
  ),
  EntryGismuEnglish(
    word: "glico",
    keyword: "English",
    hint: "",
    definition: "x1 is English/pertains to English-speaking culture in aspect x2",
  ),
  EntryGismuEnglish(
    word: "gluta",
    keyword: "glove",
    hint: "",
    definition: "x1 is a mitten/glove [hand and lower arm garment] of material x2",
  ),
  EntryGismuEnglish(
    word: "gocti",
    keyword: "1E-24",
    hint: "'yocto'",
    definition: "x1 is 1x10**-24 of x2 in dimension/aspect x3 (default is units)",
  ),
  EntryGismuEnglish(
    word: "gotro",
    keyword: "1E24",
    hint: "'yotta'",
    definition: "x1 is 1x10**24 of x2 in dimension/aspect x3 (default is units)",
  ),
  EntryGismuEnglish(
    word: "gradu",
    keyword: "unit",
    hint: "'degree, grad'",
    definition: "x1 [magnitude] is a unit/degree of/on scale/reference standard x2 (si'o) " &
        "measuring property x3",
  ),
  EntryGismuEnglish(
    word: "grake",
    keyword: "gram",
    hint: "",
    definition: "x1 is x2 gram(s) [metric unit] in mass (default is 1) by standard x3",
  ),
  EntryGismuEnglish(
    word: "grana",
    keyword: "rod",
    hint: "",
    definition: "x1 is a rod/pole/staff/stick/cane [shape/form] of material x2",
  ),
  EntryGismuEnglish(
    word: "grasu",
    keyword: "grease",
    hint: "",
    definition: "x1 is a quantity of/is made of/contains grease/fat/oil from source x2",
  ),
  EntryGismuEnglish(
    word: "greku",
    keyword: "frame",
    hint: "",
    definition: "x1 is a frame/structure/skeleton/outline supporting/load-bearing/determining " &
        "the form of x2",
  ),
  EntryGismuEnglish(
    word: "grusi",
    keyword: "gray",
    hint: "",
    definition: "x1 is gray [color adjective]",
  ),
  EntryGismuEnglish(
    word: "grute",
    keyword: "fruit",
    hint: "",
    definition: "x1 is a fruit [body-part] of species x2",
  ),
  EntryGismuEnglish(
    word: "gubni",
    keyword: "public",
    hint: "",
    definition: "x1 is public/un-hidden/open/jointly available to/owned by all among community " &
        "x2 (mass)",
  ),
  EntryGismuEnglish(
    word: "gugde",
    keyword: "country",
    hint: "",
    definition: "x1 is the country of peoples x2 with land/territory x3; (people/territory " &
        "relationship)",
  ),
  EntryGismuEnglish(
    word: "gundi",
    keyword: "industry",
    hint: "",
    definition: "x1 is industry/industrial/systematic manufacturing activity producing x2 by " &
        "process/means x3",
  ),
  EntryGismuEnglish(
    word: "gunka",
    keyword: "work",
    hint: "",
    definition: "x1 [person] labors/works on/at x2 [activity] with goal/objective x3",
  ),
  EntryGismuEnglish(
    word: "gunma",
    keyword: "jointly",
    hint: "'mass'",
    definition: "x1 is a mass/team/aggregate/whole, together composed of components x2, " &
        "considered jointly",
  ),
  EntryGismuEnglish(
    word: "gunro",
    keyword: "roll",
    hint: "'trundle'",
    definition: "x1 rolls/trundles on/against surface x2 rotating on axis/axle x3; x1 is a roller",
  ),
  EntryGismuEnglish(
    word: "gunse",
    keyword: "goose",
    hint: "",
    definition: "x1 is a goose/[gander] of species/breed x2",
  ),
  EntryGismuEnglish(
    word: "gunta",
    keyword: "attack",
    hint: "",
    definition: "x1 (person/mass) attacks/invades/commits aggression upon victim x2 with " &
        "goal/objective x3",
  ),
  EntryGismuEnglish(
    word: "gurni",
    keyword: "grain",
    hint: "",
    definition: "x1 is grain/[British: corn]/cereal from plant/species x2",
  ),
  EntryGismuEnglish(
    word: "guska",
    keyword: "scrape",
    hint: "",
    definition: "x1 blade/scraper/erosive scrapes/erodes/abrades x2 from x3",
  ),
  EntryGismuEnglish(
    word: "gusni",
    keyword: "illumine",
    hint: "'light'",
    definition: "x1 [energy] is light/illumination illuminating x2 from light source x3",
  ),
  EntryGismuEnglish(
    word: "gusta",
    keyword: "restaurant",
    hint: "",
    definition: "x1 is a restaurant/cafe/diner serving type-of-food x2 to audience x3",
  ),
  EntryGismuEnglish(
    word: "gutci",
    keyword: "cubit",
    hint: "'foot'",
    definition: "x1 is x2 (default 1) short local distance unit(s) [non-metric], standard x3, x4 " &
        "subunits",
  ),
  EntryGismuEnglish(
    word: "gutra",
    keyword: "womb",
    hint: "'uterus'",
    definition: "x1 is a/the womb/uterus [body-part] of x2; [metaphor: nourishing, protective, " &
        "giving birth]",
  ),
  EntryGismuEnglish(
    word: "guzme",
    keyword: "melon",
    hint: "",
    definition: "x1 is a melon/squash [fruit/plant] of species/strain x2",
  ),
  EntryGismuEnglish(
    word: "ja",
    keyword: "tanru or",
    hint: "",
    definition: "logical connective: tanru-internal afterthought or",
  ),
  EntryGismuEnglish(
    word: "jabre",
    keyword: "brake",
    hint: "",
    definition: "x1 brakes/causes to slow motion/activity x2 with device/mechanism/principle x3",
  ),
  EntryGismuEnglish(
    word: "jadni",
    keyword: "adorn",
    hint: "",
    definition: "x1 (object) adorns/decorates x2; x1 is an adornment/decoration of x2; x2 is " &
        "fancy/decorated",
  ),
  EntryGismuEnglish(
    word: "jakne",
    keyword: "rocket",
    hint: "",
    definition: "x1 is a rocket [vehicle] propelled by jet expelling x2 carrying payload x3",
  ),
  EntryGismuEnglish(
    word: "jalge",
    keyword: "result",
    hint: "",
    definition: "x1 (action/event/state) is a result/outcome/conclusion of antecedent x2 " &
        "(event/state/process)",
  ),
  EntryGismuEnglish(
    word: "jalna",
    keyword: "starch",
    hint: "",
    definition: "x1 is a quantity of/contains/is made of starch from source x2 of composition " &
        "including x3",
  ),
  EntryGismuEnglish(
    word: "jalra",
    keyword: "cockroach",
    hint: "",
    definition: "x1 is a cockroach/[orthopteran/termite] of order/species/breed x2",
  ),
  EntryGismuEnglish(
    word: "jamfu",
    keyword: "foot",
    hint: "",
    definition: "x1 is a/the foot [body-part] of x2; [metaphor: lowest portion] (adjective:) x1 " &
        "is pedal",
  ),
  EntryGismuEnglish(
    word: "jamna",
    keyword: "war",
    hint: "",
    definition: "x1 (person/mass) wars against x2 over territory/matter x3; x1 is at war with x2",
  ),
  EntryGismuEnglish(
    word: "janbe",
    keyword: "bell",
    hint: "",
    definition: "x1 is a bell/chime/[tuning fork] [tuned percussion instrument] producing " &
        "sound/note x2",
  ),
  EntryGismuEnglish(
    word: "janco",
    keyword: "shoulder",
    hint: "",
    definition: "x1 is a/the shoulder/hip/joint [body-part] attaching limb/extremity x2 to body x3",
  ),
  EntryGismuEnglish(
    word: "janli",
    keyword: "collide",
    hint: "",
    definition: "x1 collides with/crashes/bumps/runs into x2",
  ),
  EntryGismuEnglish(
    word: "jansu",
    keyword: "diplomat",
    hint: "'consul'",
    definition: "x1 is a diplomat/consul representing polity x2 in/at negotiation x3 for " &
        "function/purpose x4",
  ),
  EntryGismuEnglish(
    word: "janta",
    keyword: "account",
    hint: "",
    definition: "x1 is an account/bill/invoice for goods/services x2, billed to x3 by x4",
  ),
  EntryGismuEnglish(
    word: "jarbu",
    keyword: "suburb",
    hint: "",
    definition: "x1 is a suburban area of city/metropolis x2",
  ),
  EntryGismuEnglish(
    word: "jarco",
    keyword: "show",
    hint: "",
    definition: "x1 (agent) shows/exhibits/displays/[reveals]/demonstrates x2 (property) to " &
        "audience x3",
  ),
  EntryGismuEnglish(
    word: "jarki",
    keyword: "narrow",
    hint: "",
    definition: "x1 is narrow in dimension x2 [2nd most significant dimension] by standard x3",
  ),
  EntryGismuEnglish(
    word: "jaspu",
    keyword: "passport",
    hint: "",
    definition: "x1 is a passport issued to x2 (person) by authority x3 allowing x4 (activity)",
  ),
  EntryGismuEnglish(
    word: "jatna",
    keyword: "captain",
    hint: "",
    definition: "x1 is captain/commander/leader/in-charge/boss of vehicle/domain x2",
  ),
  EntryGismuEnglish(
    word: "javni",
    keyword: "rule",
    hint: "",
    definition: "x1 is a rule prescribing/mandating/requiring x2 (event/state) within " &
        "system/community x3",
  ),
  EntryGismuEnglish(
    word: "jbama",
    keyword: "bomb",
    hint: "",
    definition: "x1 is a bomb/explosive device with explosive material/principle x2",
  ),
  EntryGismuEnglish(
    word: "jbari",
    keyword: "berry",
    hint: "",
    definition: "x1 is a berry (fruit/plant) of plant/species x2",
  ),
  EntryGismuEnglish(
    word: "jbena",
    keyword: "born",
    hint: "'bear'",
    definition: "x1 is born to x2 at time x3 [birthday] and place x4 [birthplace]; x1 is native " &
        "to (fo) x4",
  ),
  EntryGismuEnglish(
    word: "jbera",
    keyword: "borrow",
    hint: "",
    definition: "x1 (agent) borrows/temporarily takes/assumes x2 (object) from source x3 for " &
        "interval x4",
  ),
  EntryGismuEnglish(
    word: "jbini",
    keyword: "between",
    hint: "",
    definition: "x1 is between/among set of points/bounds/limits x2 (set)/amidst mass x2 in " &
        "property x3 (ka)",
  ),
  EntryGismuEnglish(
    word: "jdari",
    keyword: "firm",
    hint: "'hard'",
    definition: "x1 is firm/hard/resistant/unyielding to force x2 under conditions x3",
  ),
  EntryGismuEnglish(
    word: "jdice",
    keyword: "decide",
    hint: "",
    definition: "x1 (person) decides/makes decision x2 (du'u) about matter x3 (event/state)",
  ),
  EntryGismuEnglish(
    word: "jdika",
    keyword: "decrease",
    hint: "",
    definition: "x1 (experiencer) decreases/contracts/is reduced/diminished in property/quantity " &
        "x2 by amount x3",
  ),
  EntryGismuEnglish(
    word: "jdima",
    keyword: "price",
    hint: "",
    definition: "x1 [amount] is the price of x2 to purchaser/consumer x3 set by vendor x4",
  ),
  EntryGismuEnglish(
    word: "jdini",
    keyword: "money",
    hint: "'dinero'",
    definition: "x1 is money/currency issued by x2; (adjective:) x1 is " &
        "financial/monetary/pecuniary/fiscal",
  ),
  EntryGismuEnglish(
    word: "jduli",
    keyword: "jelly",
    hint: "",
    definition: "x1 is a quantity of jelly/semisolid [texture] of material/composition including " &
        "x2",
  ),
  EntryGismuEnglish(
    word: "je",
    keyword: "tanru and",
    hint: "",
    definition: "logical connective: tanru-internal afterthought and",
  ),
  EntryGismuEnglish(
    word: "jecta",
    keyword: "polity",
    hint: "'state'",
    definition: "x1 is a polity/state governing territory/domain x2; [government/territory " &
        "relationship]",
  ),
  EntryGismuEnglish(
    word: "jeftu",
    keyword: "week",
    hint: "",
    definition: "x1 is x2 weeks in duration (default is 1 week) by standard x3",
  ),
  EntryGismuEnglish(
    word: "jegvo",
    keyword: "Jehovist",
    hint: "",
    definition: "x1 pertains to the common Judeo-Christian-Moslem culture/religion/nationality " &
        "in aspect x2",
  ),
  EntryGismuEnglish(
    word: "jei",
    keyword: "truth abstract",
    hint: "",
    definition: "abstractor: truth-value abstractor; x1 is truth value of [bridi] under " &
        "metaphysics x2",
  ),
  EntryGismuEnglish(
    word: "jelca",
    keyword: "burn",
    hint: "",
    definition: "x1 burns/[ignites/is flammable/inflammable] at temperature x2 in atmosphere x3",
  ),
  EntryGismuEnglish(
    word: "jemna",
    keyword: "gem",
    hint: "",
    definition: "x1 is a gem/polished stone/pearl of type x2 from gemstone/material/source x3",
  ),
  EntryGismuEnglish(
    word: "jenca",
    keyword: "shock",
    hint: "",
    definition: "x1 (event) shocks/stuns x2",
  ),
  EntryGismuEnglish(
    word: "jendu",
    keyword: "axle",
    hint: "'spindle'",
    definition: "x1 is an axle/spindle [tool] on which x2 rotates, of material/properties x3",
  ),
  EntryGismuEnglish(
    word: "jenmi",
    keyword: "army",
    hint: "",
    definition: "x1 (mass) is an army serving group/community x2 (mass) in function x3 (activity)",
  ),
  EntryGismuEnglish(
    word: "jerna",
    keyword: "earn",
    hint: "",
    definition: "x1 (agent/person) earns/[deserves/merits] wages/salary/pay x2 for work/service " &
        "x3 (activity)",
  ),
  EntryGismuEnglish(
    word: "jersi",
    keyword: "chase",
    hint: "'pursue'",
    definition: "x1 chases/pursues/(physically) follows after x2; volition is not implied for x1 " &
        "or x2",
  ),
  EntryGismuEnglish(
    word: "jerxo",
    keyword: "Algerian",
    hint: "",
    definition: "x1 reflects Algerian culture/nationality in aspect x2",
  ),
  EntryGismuEnglish(
    word: "jesni",
    keyword: "needle",
    hint: "",
    definition: "x1 is a needle [pointed shape/form, not tool] of material x2",
  ),
  EntryGismuEnglish(
    word: "jetce",
    keyword: "jet",
    hint: "",
    definition: "x1 is a jet [expelled stream] of material x2 expelled from x3",
  ),
  EntryGismuEnglish(
    word: "jetnu",
    keyword: "true",
    hint: "",
    definition: "x1 (du'u) is true/truth by standard/epistemology/metaphysics x2",
  ),
  EntryGismuEnglish(
    word: "jgalu",
    keyword: "claw",
    hint: "'talon'",
    definition: "x1 is a/the claw/nail/talon [body-part] of x2; [metaphor: pointed, penetrating, " &
        "physical weapon]",
  ),
  EntryGismuEnglish(
    word: "jganu",
    keyword: "angle",
    hint: "",
    definition: "x1 is an angle [2-dimensional shape/form] from vertex x2 subtended by lateral " &
        "[segment] x3",
  ),
  EntryGismuEnglish(
    word: "jgari",
    keyword: "grasp",
    hint: "'grip'",
    definition: "x1 grasps/holds/clutches/seizes/grips/[hugs] x2 with x3 (part of x1) at locus " &
        "x4 (part of x2)",
  ),
  EntryGismuEnglish(
    word: "jgena",
    keyword: "knot",
    hint: "",
    definition: "x1 is a knot/tangle in/between x2 (object/jo'u-objects)",
  ),
  EntryGismuEnglish(
    word: "jgina",
    keyword: "gene",
    hint: "",
    definition: "x1 is a gene of creature [or locus on creature] x2 determining trait/process x3",
  ),
  EntryGismuEnglish(
    word: "jgira",
    keyword: "pride",
    hint: "",
    definition: "x1 (person) feels/has pride in/about x2 (abstraction)",
  ),
  EntryGismuEnglish(
    word: "jgita",
    keyword: "guitar",
    hint: "'guitar'",
    definition: "x1 is guitar/violin/fiddle/harp [stringed musical instrument] with " &
        "actuator/plectrum/bow x2",
  ),
  EntryGismuEnglish(
    word: "jibni",
    keyword: "near",
    hint: "",
    definition: "x1 is near/close to/approximates x2 in property/quantity x3 (ka/ni)",
  ),
  EntryGismuEnglish(
    word: "jibri",
    keyword: "job",
    hint: "",
    definition: "x1 is a job/occupation/employment/vocation (a type of work regularly done for " &
        "pay) of person x2",
  ),
  EntryGismuEnglish(
    word: "jicla",
    keyword: "stir",
    hint: "",
    definition: "x1 (object, or event: force) stirs/mixes/[roils/agitates] fluid (gas/liquid) x2",
  ),
  EntryGismuEnglish(
    word: "jicmu",
    keyword: "basis",
    hint: "",
    definition: "x1 is a basis/foundation/underlying or fundamental principle of x2; x1 is at " &
        "the bottom of x2",
  ),
  EntryGismuEnglish(
    word: "jijnu",
    keyword: "intuit",
    hint: "",
    definition: "x1 (person) intuits x2 (du'u) about subject x3; [epistemology]",
  ),
  EntryGismuEnglish(
    word: "jikca",
    keyword: "socialize",
    hint: "'social'",
    definition: "x1 interacts/behaves socially with x2; x1 socializes with/is sociable towards x2",
  ),
  EntryGismuEnglish(
    word: "jikru",
    keyword: "liquor",
    hint: "",
    definition: "x1 is made of/contains/is a quantity of liquor/spirits distilled from x2",
  ),
  EntryGismuEnglish(
    word: "jilka",
    keyword: "alkali",
    hint: "",
    definition: "x1 is a quantity of/contains/is made of alkali/base of composition including x2",
  ),
  EntryGismuEnglish(
    word: "jilra",
    keyword: "jealous",
    hint: "",
    definition: "x1 (person) is jealous of/envies x2 (person) about/for x3 (property - ka)",
  ),
  EntryGismuEnglish(
    word: "jimca",
    keyword: "branch",
    hint: "'limb'",
    definition: "x1 is a branch/bough/limb of x2; x2 forks into branches x1; [preferred over " &
        "metaphorical birka]",
  ),
  EntryGismuEnglish(
    word: "jimpe",
    keyword: "understand",
    hint: "'comprehend'",
    definition: "x1 understands/comprehends fact/truth x2 (du'u) about subject x3; x1 " &
        "understands (fi) x3",
  ),
  EntryGismuEnglish(
    word: "jimte",
    keyword: "limit",
    hint: "",
    definition: "x1 is a limit/extreme/bound/border/[confinement] of x2 in property/domain x3",
  ),
  EntryGismuEnglish(
    word: "jinci",
    keyword: "shears",
    hint: "",
    definition: "x1 is a pair of shears/scissors for cutting x2",
  ),
  EntryGismuEnglish(
    word: "jinga",
    keyword: "win",
    hint: "'gain'",
    definition: "x1 (person/team) wins/gains prize x2 from/over x3 [competitors/losers] in " &
        "competition x4",
  ),
  EntryGismuEnglish(
    word: "jinku",
    keyword: "vaccine",
    hint: "",
    definition: "x1 is a vaccine/immune-system stimulant protecting x2 against disease x3 " &
        "introduced by method x4",
  ),
  EntryGismuEnglish(
    word: "jinme",
    keyword: "metal",
    hint: "",
    definition: "x1 is a quantity of/contains/is made of made of metal of composition including x2",
  ),
  EntryGismuEnglish(
    word: "jinru",
    keyword: "immerse",
    hint: "",
    definition: "x1 (object/person) is immersed/submerged/bathes in liquid x2",
  ),
  EntryGismuEnglish(
    word: "jinsa",
    keyword: "clean",
    hint: "",
    definition: "x1 (object) is clean/pure of material/contaminant/dirt x2 by standard x3",
  ),
  EntryGismuEnglish(
    word: "jinto",
    keyword: "well",
    hint: "",
    definition: "x1 is a well/spring of fluid x2 at location x3",
  ),
  EntryGismuEnglish(
    word: "jinvi",
    keyword: "opine",
    hint: "",
    definition: "x1 thinks/opines x2 [opinion] (du'u) is true about subject/issue x3 on grounds x4",
  ),
  EntryGismuEnglish(
    word: "jinzi",
    keyword: "innate",
    hint: "",
    definition: "x1 (property - ka) is an innate/inherent/intrinsic/natural " &
        "property/quality/aspect of x2",
  ),
  EntryGismuEnglish(
    word: "jipci",
    keyword: "chicken",
    hint: "",
    definition: "x1 is a chicken/[hen/cock/rooster]/small fowl [a type of bird] of species/breed " &
        "x2",
  ),
  EntryGismuEnglish(
    word: "jipno",
    keyword: "tip",
    hint: "'point'",
    definition: "x1 is a tip/point/vertex/extremity/end [0-dimension shape/form] on object x2 at " &
        "locus x3",
  ),
  EntryGismuEnglish(
    word: "jirna",
    keyword: "horn",
    hint: "",
    definition: "x1 is a/the horn [body-part] of x2; [metaphor: pointed extremity]",
  ),
  EntryGismuEnglish(
    word: "jisra",
    keyword: "juice",
    hint: "",
    definition: "x1 is made of/contains/is a quantity of juice/nectar from-source/of-type x2",
  ),
  EntryGismuEnglish(
    word: "jitfa",
    keyword: "false",
    hint: "",
    definition: "x1 (du'u) is false/is an untruth by standard/epistemology/metaphysics x2",
  ),
  EntryGismuEnglish(
    word: "jitro",
    keyword: "control",
    hint: "",
    definition: "x1 has control over/harnesses/manages/directs/conducts x2 in x3 " &
        "(activity/event/performance)",
  ),
  EntryGismuEnglish(
    word: "jivbu",
    keyword: "weave",
    hint: "",
    definition: "x1 weaves x2 from material/[yarn] x3",
  ),
  EntryGismuEnglish(
    word: "jivna",
    keyword: "compete",
    hint: "'rival'",
    definition: "x1 competes/vies with opponent x2 in contest/competition x3 (event) for gain " &
        "x4; x1 rivals x2",
  ),
  EntryGismuEnglish(
    word: "jmaji",
    keyword: "gather",
    hint: "",
    definition: "x1 (mass/jo'u) gathers/collects at location x2 from locations x3 (mass/jo'u)",
  ),
  EntryGismuEnglish(
    word: "jmifa",
    keyword: "shoal",
    hint: "'reef'",
    definition: "x1 is a shoal [shallow hazard]/reef of material x2 in body of water x3",
  ),
  EntryGismuEnglish(
    word: "jmina",
    keyword: "add",
    hint: "'augment'",
    definition: "x1 adds/combines x2 to/with x3, with result x4; x1 augments x2 by amount x3",
  ),
  EntryGismuEnglish(
    word: "jmive",
    keyword: "live",
    hint: "",
    definition: "x1 lives/is alive by standard x2; x1 is an organism/living thing",
  ),
  EntryGismuEnglish(
    word: "jo",
    keyword: "tanru iff",
    hint: "",
    definition: "logical connective: tanru-internal afterthought biconditional/iff/if-and-only-if",
  ),
  EntryGismuEnglish(
    word: "jo'e",
    keyword: "union",
    hint: "",
    definition: "non-logical connective: union of sets",
  ),
  EntryGismuEnglish(
    word: "jo'u",
    keyword: "in common with",
    hint: "",
    definition: "non-logical connective: in common with; along with (unmixed)",
  ),
  EntryGismuEnglish(
    word: "joi",
    keyword: "in a mass with",
    hint: "",
    definition: "non-logical connective: mixed conjunction; \"and\" meaning \"mixed together\", " &
        "forming a mass",
  ),
  EntryGismuEnglish(
    word: "jordo",
    keyword: "Jordanian",
    hint: "",
    definition: "x1 reflects Jordanian culture/nationality in aspect x2",
  ),
  EntryGismuEnglish(
    word: "jorne",
    keyword: "joined",
    hint: "",
    definition: "x1 is joined to/connects to/is united with x2 at common locus x3; x1 and x2 are " &
        "a union",
  ),
  EntryGismuEnglish(
    word: "ju",
    keyword: "tanru whether",
    hint: "",
    definition: "logical connective: tanru-internal afterthought whether-or-not",
  ),
  EntryGismuEnglish(
    word: "jubme",
    keyword: "table",
    hint: "",
    definition: "x1 is a table/flat solid upper surface of material x2, supported by " &
        "legs/base/pedestal x3",
  ),
  EntryGismuEnglish(
    word: "judri",
    keyword: "address",
    hint: "",
    definition: "x1 is an address of/are coordinates of x2 in system x3",
  ),
  EntryGismuEnglish(
    word: "jufra",
    keyword: "sentence",
    hint: "'phrase'",
    definition: "x1 (text) is a sentence/statement about x2 [topic/subject/predicate/focus] in " &
        "language x3",
  ),
  EntryGismuEnglish(
    word: "jukni",
    keyword: "spider",
    hint: "'arachnid'",
    definition: "x1 is a spider/arachnid/[crustacean/crab/lobster/non-insect arthropod] of " &
        "species/breed x2",
  ),
  EntryGismuEnglish(
    word: "jukpa",
    keyword: "cook",
    hint: "",
    definition: "x1 cooks/prepares food-for-eating x2 by recipe/method x3 (process)",
  ),
  EntryGismuEnglish(
    word: "julne",
    keyword: "net",
    hint: "",
    definition: "x1 is a net/filter allowing passage of x2, prohibiting passage of x3, netting " &
        "properties x4",
  ),
  EntryGismuEnglish(
    word: "jundi",
    keyword: "attentive",
    hint: "'attend'",
    definition: "x1 is attentive towards/attends/tends/pays attention to object/affair x2",
  ),
  EntryGismuEnglish(
    word: "jungo",
    keyword: "Chinese",
    hint: "",
    definition: "x1 reflects Chinese [Mandarin, Cantonese, Wu, etc.] " &
        "culture/nationality/language in aspect x2",
  ),
  EntryGismuEnglish(
    word: "junla",
    keyword: "clock",
    hint: "",
    definition: "x1 is clock/watch/timer measuring time units x2 to precision x3 with timing " &
        "mechanism/method x4",
  ),
  EntryGismuEnglish(
    word: "junri",
    keyword: "serious",
    hint: "",
    definition: "x1 (person) is serious/earnest/has gravity about x2 (event/state/activity)",
  ),
  EntryGismuEnglish(
    word: "junta",
    keyword: "weight",
    hint: "",
    definition: "x1 is the weight of object x2 in [gravitational or other force] field x3",
  ),
  EntryGismuEnglish(
    word: "jurme",
    keyword: "germ",
    hint: "",
    definition: "x1 is a bacteria/germ/microbe/protozoan/amoeba [1-celled life] of " &
        "species/defining property x2",
  ),
  EntryGismuEnglish(
    word: "jursa",
    keyword: "severe",
    hint: "'harsh'",
    definition: "x1 (event/action/state) is severe/harsh to x2 [victim/experiencer]",
  ),
  EntryGismuEnglish(
    word: "jutsi",
    keyword: "species",
    hint: "",
    definition: "x1 is a species of genus x2, family x3, etc.; [open-ended tree-structure " &
        "categorization]",
  ),
  EntryGismuEnglish(
    word: "juxre",
    keyword: "clumsy",
    hint: "'awkward'",
    definition: "x1 (action) is clumsy/awkward by standard x2",
  ),
  EntryGismuEnglish(
    word: "jvinu",
    keyword: "view",
    hint: "",
    definition: "x1 is the view/scene/panorama/sight/prospect of x2 (object/location) from " &
        "point-of-view x3",
  ),
  EntryGismuEnglish(
    word: "ka",
    keyword: "property abstract",
    hint: "",
    definition: "abstractor: property/quality abstractor (-ness); x1 is quality/property " &
        "exhibited by [bridi]",
  ),
  EntryGismuEnglish(
    word: "kabri",
    keyword: "cup",
    hint: "",
    definition: "x1 is a cup/glass/tumbler/mug/vessel/[bowl] containing contents x2, and of " &
        "material x3",
  ),
  EntryGismuEnglish(
    word: "kacma",
    keyword: "camera",
    hint: "",
    definition: "x1 is a camera/photographic equipment recording illumination type x2 images to " &
        "medium x3",
  ),
  EntryGismuEnglish(
    word: "kadno",
    keyword: "Canadian",
    hint: "",
    definition: "x1 reflects Canadian culture/nationality in aspect x2",
  ),
  EntryGismuEnglish(
    word: "kafke",
    keyword: "cough",
    hint: "",
    definition: "x1 coughs/farts/burps up/out x2 [predominantly gaseous] from orifice x3",
  ),
  EntryGismuEnglish(
    word: "kagni",
    keyword: "company",
    hint: "",
    definition: "x1 is a company/corporation/firm/partnership chartered by authority x2 for " &
        "purpose x3",
  ),
  EntryGismuEnglish(
    word: "kajde",
    keyword: "warn",
    hint: "'caution'",
    definition: "x1 (event/experience) warns/cautions x2 (person) of/about danger x3 " &
        "(event/state/property)",
  ),
  EntryGismuEnglish(
    word: "kajna",
    keyword: "shelf",
    hint: "'counter'",
    definition: "x1 is a shelf/counter/bar in/on/attached to supporting object x2, for purpose x3",
  ),
  EntryGismuEnglish(
    word: "kakne",
    keyword: "able",
    hint: "'can'",
    definition: "x1 is able to do/be/capable of doing/being x2 (event/state) under conditions x3 " &
        "(event/state)",
  ),
  EntryGismuEnglish(
    word: "kakpa",
    keyword: "dig",
    hint: "",
    definition: "x1 (agent) digs x2 [material] up/out of x3 [source/hole] with limbs/tool(s) x4",
  ),
  EntryGismuEnglish(
    word: "kalci",
    keyword: "feces",
    hint: "'shit'",
    definition: "x1 is a/the feces/excrement/dung/shit of x2 (animal/person); (adjective:) x1 is " &
        "fecal (matter)",
  ),
  EntryGismuEnglish(
    word: "kalri",
    keyword: "open",
    hint: "",
    definition: "x1 (portal/passage/entrance-way) is open/ajar/not shut permitting " &
        "passage/access to x2 by x3",
  ),
  EntryGismuEnglish(
    word: "kalsa",
    keyword: "chaotic",
    hint: "",
    definition: "x1 is chaotic/disordered in property/aspect x2 (ka)",
  ),
  EntryGismuEnglish(
    word: "kalte",
    keyword: "hunt",
    hint: "",
    definition: "x1 hunts/stalks prey/quarry/game x2 for purpose x3",
  ),
  EntryGismuEnglish(
    word: "kamju",
    keyword: "column",
    hint: "",
    definition: "x1 is a column/pillar of material x2",
  ),
  EntryGismuEnglish(
    word: "kamni",
    keyword: "committee",
    hint: "",
    definition: "x1 (mass) is a committee with task/purpose x2 of body x3",
  ),
  EntryGismuEnglish(
    word: "kampu",
    keyword: "common",
    hint: "",
    definition: "x1 (property - ka) is common/general/universal among members of set x2 " &
        "(complete set)",
  ),
  EntryGismuEnglish(
    word: "kanba",
    keyword: "goat",
    hint: "'kid, billy, baa'",
    definition: "x1 is a goat/angora/[billy-goat/kid] of species/breed x2",
  ),
  EntryGismuEnglish(
    word: "kancu",
    keyword: "count",
    hint: "",
    definition: "x1 (agent) counts the number in set x2 to be x3 [number/count] counting [off] " &
        "by units x4",
  ),
  EntryGismuEnglish(
    word: "kandi",
    keyword: "dim",
    hint: "",
    definition: "x1 is dim/dull/pale/non-intense in property x2 (ka) as received/measured by " &
        "observer x3",
  ),
  EntryGismuEnglish(
    word: "kanji",
    keyword: "calculate",
    hint: "'reckon'",
    definition: "x1 calculates/reckons/computes x2 [value (ni)/state] from data x3 by process x4",
  ),
  EntryGismuEnglish(
    word: "kanla",
    keyword: "eye",
    hint: "'ocular'",
    definition: "x1 is a/the eye [body-part] of x2; [metaphor: sensory apparatus]; (adjective:) " &
        "x1 is ocular",
  ),
  EntryGismuEnglish(
    word: "kanro",
    keyword: "healthy",
    hint: "",
    definition: "x1 is healthy/fit/well/in good health by standard x2",
  ),
  EntryGismuEnglish(
    word: "kansa",
    keyword: "with",
    hint: "'accompany'",
    definition: "x1 is with/accompanies/is a companion of x2, in state/condition/enterprise x3 " &
        "(event/state)",
  ),
  EntryGismuEnglish(
    word: "kantu",
    keyword: "quantum",
    hint: "",
    definition: "x1 is a quantum/ray/elementary particle/smallest measurable increment of " &
        "property/activity x2",
  ),
  EntryGismuEnglish(
    word: "kanxe",
    keyword: "conjunction",
    hint: "",
    definition: "x1 is a conjunction, stating that x2 (du'u) and x3 (du'u) are both true",
  ),
  EntryGismuEnglish(
    word: "karbi",
    keyword: "compare",
    hint: "",
    definition: "x1 [observer] compares x2 with x3 in property x4 (ka), determining comparison " &
        "x5 (state)",
  ),
  EntryGismuEnglish(
    word: "karce",
    keyword: "car",
    hint: "",
    definition: "x1 is a car/automobile/truck/van [a wheeled motor vehicle] for carrying x2, " &
        "propelled by x3",
  ),
  EntryGismuEnglish(
    word: "karda",
    keyword: "card",
    hint: "",
    definition: "x1 is a card [small nearly-2-dimensional shape/form] of material x2, shape x3",
  ),
  EntryGismuEnglish(
    word: "kargu",
    keyword: "costly",
    hint: "",
    definition: "x1 (object/commodity/property/event) is costly/expensive/dear to x2 by standard " &
        "x3",
  ),
  EntryGismuEnglish(
    word: "karli",
    keyword: "collar",
    hint: "",
    definition: "x1 is a collar/ring/belt/band around/surrounding x2 made of material x3",
  ),
  EntryGismuEnglish(
    word: "karni",
    keyword: "journal",
    hint: "",
    definition: "x1 is a journal/periodical/magazine/[newspaper] with content x2 published by x3 " &
        "for audience x4",
  ),
  EntryGismuEnglish(
    word: "katna",
    keyword: "cut",
    hint: "",
    definition: "x1 (tool/blade/force) cuts [through]/splits/divides x2 (object) into pieces x3",
  ),
  EntryGismuEnglish(
    word: "kavbu",
    keyword: "capture",
    hint: "'catch'",
    definition: "x1 captures/catches/apprehends/seizes/nabs x2 with trap/restraint x3",
  ),
  EntryGismuEnglish(
    word: "ke",
    keyword: "start grouping",
    hint: "",
    definition: "start grouping of tanru, etc; ... type of ... ; overrides normal tanru left " &
        "grouping",
  ),
  EntryGismuEnglish(
    word: "ke'e",
    keyword: "end grouping",
    hint: "",
    definition: "elidable terminator: end of tanru left grouping override (usually elidable)",
  ),
  EntryGismuEnglish(
    word: "kecti",
    keyword: "pity",
    hint: "",
    definition: "x1 (person) pities/feels sorry for x2 (person) about x3 (abstraction)",
  ),
  EntryGismuEnglish(
    word: "kei",
    keyword: "end abstraction",
    hint: "",
    definition: "elidable terminator: end abstraction bridi (often elidable)",
  ),
  EntryGismuEnglish(
    word: "kelci",
    keyword: "play",
    hint: "",
    definition: "x1 [agent] plays with plaything/toy x2",
  ),
  EntryGismuEnglish(
    word: "kelvo",
    keyword: "kelvin",
    hint: "",
    definition: "x1 is x2 degree(s) Kelvin [metric unit] in temperature (default is 1) by " &
        "standard x3",
  ),
  EntryGismuEnglish(
    word: "kenra",
    keyword: "cancer",
    hint: "",
    definition: "x1 is a cancer [malignant disease] in x2",
  ),
  EntryGismuEnglish(
    word: "kensa",
    keyword: "outer space",
    hint: "",
    definition: "x1 is outer space near/associated with celestial body/region x2",
  ),
  EntryGismuEnglish(
    word: "kerfa",
    keyword: "hair",
    hint: "",
    definition: "x1 is a/the hair/fur [body-part] of x2 at body location x3",
  ),
  EntryGismuEnglish(
    word: "kerlo",
    keyword: "ear",
    hint: "'aural, earlobe'",
    definition: "x1 is a/the ear [body-part] of x2; [metaphor: sensory apparatus, information " &
        "gathering]",
  ),
  EntryGismuEnglish(
    word: "ketco",
    keyword: "South American",
    hint: "'Quechua'",
    definition: "x1 reflects South American culture/nationality/geography in aspect x2",
  ),
  EntryGismuEnglish(
    word: "kevna",
    keyword: "cavity",
    hint: "'cave'",
    definition: "x1 is a cavity/hole/hollow/cavern in x2; x1 is concave within x2; x2 is hollow " &
        "at locus x1",
  ),
  EntryGismuEnglish(
    word: "kicne",
    keyword: "cushion",
    hint: "",
    definition: "x1 cushions x2 with material x3; x1 is a cushion/pillow/pad [for x2] of padding " &
        "material x3",
  ),
  EntryGismuEnglish(
    word: "kijno",
    keyword: "oxygen",
    hint: "",
    definition: "x1 is a quantity of/contains/is made of oxygen (O); [metaphor: supporting " &
        "life/combustion]",
  ),
  EntryGismuEnglish(
    word: "kilto",
    keyword: "1000",
    hint: "metric 'kilo'",
    definition: "x1 is a thousand [1000; 1x10**3] of x2 in dimension/aspect x3 (default is units)",
  ),
  EntryGismuEnglish(
    word: "kinli",
    keyword: "sharp",
    hint: "'keen'",
    definition: "x1 is sharp/keen at locus x2",
  ),
  EntryGismuEnglish(
    word: "kisto",
    keyword: "Pakistani",
    hint: "",
    definition: "x1 reflects Pakistani/Pashto culture/nationality/language in aspect x2",
  ),
  EntryGismuEnglish(
    word: "klaji",
    keyword: "street",
    hint: "'avenue'",
    definition: "x1 is a street/avenue/lane/drive/cul-de-sac/way/alley/[road] at x2 accessing x3",
  ),
  EntryGismuEnglish(
    word: "klaku",
    keyword: "weep",
    hint: "",
    definition: "x1 weeps/cries tears x2 about/for reason x3 (event/state)",
  ),
  EntryGismuEnglish(
    word: "klama",
    keyword: "come",
    hint: "",
    definition: "x1 comes/goes to destination x2 from origin x3 via route x4 using means/vehicle " &
        "x5",
  ),
  EntryGismuEnglish(
    word: "klani",
    keyword: "quantity",
    hint: "",
    definition: "x1 is a quantity quantified/measured/enumerated by x2 (quantifier) on scale x3 " &
        "(si'o)",
  ),
  EntryGismuEnglish(
    word: "klesi",
    keyword: "class",
    hint: "",
    definition: "x1 (mass/si'o) is a class/category/subgroup/subset within x2 with defining " &
        "property x3 (ka)",
  ),
  EntryGismuEnglish(
    word: "klina",
    keyword: "clear",
    hint: "",
    definition: "x1 (object/medium) is clear/transparent/without obstacle to in-the-clear x2 " &
        "[transmission]",
  ),
  EntryGismuEnglish(
    word: "kliru",
    keyword: "chlorine",
    hint: "",
    definition: "x1 is a quantity of/contains/is made of halogen of type x2 [chlorine, fluorine, " &
        "iodine, etc.]",
  ),
  EntryGismuEnglish(
    word: "kliti",
    keyword: "clay",
    hint: "",
    definition: "x1 is a quantity of/contains/is made of clay [moist, clammy dirt] of " &
        "composition including x2",
  ),
  EntryGismuEnglish(
    word: "klupe",
    keyword: "screw",
    hint: "",
    definition: "x1 is a screw [fastener] for purpose x2, threads [pitch, material] x3, frame " &
        "[size, material] x4",
  ),
  EntryGismuEnglish(
    word: "kluza",
    keyword: "loose",
    hint: "'blouse'",
    definition: "x1 (obj.) is loose/bloused/not tight on x2 (obj.) at locus x3",
  ),
  EntryGismuEnglish(
    word: "kobli",
    keyword: "cabbage",
    hint: "'cole-'",
    definition: "x1 is a quantity of cabbage/lettuce/leafy vegetable of species/strain x2",
  ),
  EntryGismuEnglish(
    word: "kojna",
    keyword: "corner",
    hint: "",
    definition: "x1 is a corner/point/at-least-3-dimensional [solid] angle [shape/form] in/on " &
        "x2, of material x3",
  ),
  EntryGismuEnglish(
    word: "kolme",
    keyword: "coal",
    hint: "",
    definition: "x1 is a quantity of/contains/is made of coal/peat/anthracite/bituminous from " &
        "source x2",
  ),
  EntryGismuEnglish(
    word: "komcu",
    keyword: "comb",
    hint: "",
    definition: "x1 is a comb [many-needled shape] of material x2 with tines/needles x3",
  ),
  EntryGismuEnglish(
    word: "konju",
    keyword: "cone",
    hint: "",
    definition: "x1 is a cone [shape/form] of material x2 with vertex x3",
  ),
  EntryGismuEnglish(
    word: "korbi",
    keyword: "edge",
    hint: "'border, curb'",
    definition: "x1 is an edge/margin/border/curb/boundary of x2 next-to/bordering-on x3",
  ),
  EntryGismuEnglish(
    word: "korcu",
    keyword: "bent",
    hint: "'crooked, corkscrew'",
    definition: "(adjective:) x1 is bent/crooked/not straight or direct/[twisted]/folded",
  ),
  EntryGismuEnglish(
    word: "korka",
    keyword: "cork",
    hint: "",
    definition: "x1 is a quantity of/contains/is made of cork/bark from tree/species x2; " &
        "[material]",
  ),
  EntryGismuEnglish(
    word: "kosta",
    keyword: "coat",
    hint: "",
    definition: "x1 is a coat/jacket/sweater/cloak/[cape/shawl/pullover] [extra outer garment] " &
        "of material x2",
  ),
  EntryGismuEnglish(
    word: "kramu",
    keyword: "acre",
    hint: "",
    definition: "x1 is x2 local area unit(s) [non-metric] (default 1) by standard x3, x4 subunits",
  ),
  EntryGismuEnglish(
    word: "krasi",
    keyword: "source",
    hint: "'origin'",
    definition: "x1 (site/event) is a source/start/beginning/origin of x2 (object/event/process)",
  ),
  EntryGismuEnglish(
    word: "krati",
    keyword: "represent",
    hint: "'proxy'",
    definition: "x1 represents/is an agent/proxy/stands-in for [absent] x2 in " &
        "matter(s)/function(s) x3",
  ),
  EntryGismuEnglish(
    word: "krefu",
    keyword: "recur",
    hint: "",
    definition: "x1 (event) is the x3'rd recurrence/repetition of x2 (abstract); x2 happens " &
        "again in [form] x1",
  ),
  EntryGismuEnglish(
    word: "krici",
    keyword: "believe",
    hint: "'creed'",
    definition: "x1 believes [without evidence/proof] belief/creed x2 (du'u) is true/assumed " &
        "about subject x3",
  ),
  EntryGismuEnglish(
    word: "krili",
    keyword: "crystal",
    hint: "",
    definition: "x1 is a quantity of/contains/is made of crystal of composition x2 in " &
        "form/arrangement x3",
  ),
  EntryGismuEnglish(
    word: "krinu",
    keyword: "reason",
    hint: "",
    definition: "x1 (event/state) is a reason/justification/explanation for/causing/permitting " &
        "x2 (event/state)",
  ),
  EntryGismuEnglish(
    word: "krixa",
    keyword: "cry out",
    hint: "",
    definition: "x1 cries out/yells/howls sound x2; x1 is a crier",
  ),
  EntryGismuEnglish(
    word: "kruca",
    keyword: "intersect",
    hint: "'cross'",
    definition: "x1 intersects/crosses/traverses x2 at locus x3",
  ),
  EntryGismuEnglish(
    word: "kruji",
    keyword: "cream",
    hint: "",
    definition: "x1 is made of/contains/is a quantity of cream/emulsion/puree [consistency] of " &
        "composition x2",
  ),
  EntryGismuEnglish(
    word: "kruvi",
    keyword: "curve",
    hint: "",
    definition: "x1 is a curve/turn/bend in x2, at locus x3, and defined by set of " &
        "points/properties x4",
  ),
  EntryGismuEnglish(
    word: "ku'a",
    keyword: "intersection",
    hint: "",
    definition: "non-logical connective: intersection of sets",
  ),
  EntryGismuEnglish(
    word: "kubli",
    keyword: "cube",
    hint: "",
    definition: "x1 is a cube/regular polyhedron/polygon of dimensions x2 (def. 3), " &
        "surfaces/sides x3 (def. 6)",
  ),
  EntryGismuEnglish(
    word: "kucli",
    keyword: "curious",
    hint: "",
    definition: "x1 is curious/wonders about/is interested in/[inquisitive about] x2 " &
        "(object/abstract)",
  ),
  EntryGismuEnglish(
    word: "kufra",
    keyword: "comfort",
    hint: "",
    definition: "x1 feels comfort/is comfortable with conditions/environmental property(ies) x2",
  ),
  EntryGismuEnglish(
    word: "kukte",
    keyword: "delicious",
    hint: "'cooked, tasty'",
    definition: "x1 is delicious/tasty/delightful to observer/sense x2 [person, or sensory " &
        "activity]",
  ),
  EntryGismuEnglish(
    word: "kulnu",
    keyword: "culture",
    hint: "",
    definition: "x1 [mass of ideas, customs, skills, arts] is culture of nation/ethos x2 (mass); " &
        "x1 is ethnic",
  ),
  EntryGismuEnglish(
    word: "kumfa",
    keyword: "room",
    hint: "",
    definition: "x1 is a room of/in structure x2 surrounded by partitions/walls/ceiling/floor x3 " &
        "(mass/jo'u)",
  ),
  EntryGismuEnglish(
    word: "kumte",
    keyword: "camel",
    hint: "",
    definition: "x1 is a camel/llama/alpaca/vicuna/dromedary of species/breed x2",
  ),
  EntryGismuEnglish(
    word: "kunra",
    keyword: "mineral",
    hint: "'mined'",
    definition: "x1 is/contains/is made from a mineral/ore of type/metal x2 mined from " &
        "location/lode/mine x3",
  ),
  EntryGismuEnglish(
    word: "kunti",
    keyword: "empty",
    hint: "'vacant'",
    definition: "x1 [container] is empty/vacant of x2 [material]; x1 is hollow",
  ),
  EntryGismuEnglish(
    word: "kurfa",
    keyword: "square",
    hint: "",
    definition: "x1 is a right-angled shape/form defined by set of vertices x2, dimensions x3 " &
        "(default 2)",
  ),
  EntryGismuEnglish(
    word: "kurji",
    keyword: "take care of",
    hint: "'care'",
    definition: "x1 takes-care-of/looks after/attends to/provides for/is caretaker for x2 " &
        "(object/event/person)",
  ),
  EntryGismuEnglish(
    word: "kurki",
    keyword: "bitter",
    hint: "'acrid'",
    definition: "x1 is bitter/acrid/sharply disagreeable to observer/sense x2",
  ),
  EntryGismuEnglish(
    word: "kuspe",
    keyword: "range",
    hint: "'span'",
    definition: "x1 ranges/extends/spans/persists/reaches across/over " &
        "interval/gap/area/scope/extent/range x2",
  ),
  EntryGismuEnglish(
    word: "kusru",
    keyword: "cruel",
    hint: "",
    definition: "x1 (person) is cruel/mean/unkind to victim x2",
  ),
  EntryGismuEnglish(
    word: "labno",
    keyword: "wolf",
    hint: "'lobo'",
    definition: "x1 is a wolf/lupine of species/breed x2",
  ),
  EntryGismuEnglish(
    word: "lacpu",
    keyword: "pull",
    hint: "",
    definition: "x1 pulls/tugs/draws/drags x2 by handle/at locus x3",
  ),
  EntryGismuEnglish(
    word: "lacri",
    keyword: "rely",
    hint: "",
    definition: "x1 relies/depends/counts on/trusts x2 to bring about/ensure/maintain x3 " &
        "(event/state)",
  ),
  EntryGismuEnglish(
    word: "ladru",
    keyword: "milk",
    hint: "'lactic'",
    definition: "x1 is made of/contains/is a quantity of milk from source x2; (adjective:) x1 is " &
        "lactic/dairy",
  ),
  EntryGismuEnglish(
    word: "lafti",
    keyword: "lift",
    hint: "",
    definition: "x1 (force) lifts/applies raising/supporting force to x2 at locus x3 in gravity " &
        "well x4",
  ),
  EntryGismuEnglish(
    word: "lakne",
    keyword: "probable",
    hint: "'likely'",
    definition: "x1 (event/state/property) is probable/likely under conditions x2",
  ),
  EntryGismuEnglish(
    word: "lakse",
    keyword: "wax",
    hint: "",
    definition: "x1 is quantity of wax [substance especially soft/moldable when warm] from " &
        "source x2",
  ),
  EntryGismuEnglish(
    word: "lalxu",
    keyword: "lake",
    hint: "'lagoon'",
    definition: "x1 is a lake/lagoon/pool at site/within land mass x2",
  ),
  EntryGismuEnglish(
    word: "lamji",
    keyword: "adjacent",
    hint: "",
    definition: "x1 is adjacent/beside/next to/in contact with x2 in property/sequence x3 in " &
        "direction x4",
  ),
  EntryGismuEnglish(
    word: "lanbi",
    keyword: "protein",
    hint: "'albumin'",
    definition: "x1 is a quantity of protein/albumin of type x2 composed of amino acids " &
        "(sequence/jo'u)",
  ),
  EntryGismuEnglish(
    word: "lanci",
    keyword: "flag",
    hint: "'banner'",
    definition: "x1 is a flag/banner/standard of/symbolizing x2 with pattern(s) x3 on material x4",
  ),
  EntryGismuEnglish(
    word: "lanka",
    keyword: "basket",
    hint: "",
    definition: "x1 is a basket with contents x2, woven from material x3",
  ),
  EntryGismuEnglish(
    word: "lanli",
    keyword: "analyze",
    hint: "",
    definition: "x1 analyzes/examines-in-detail x2 by method/technique/system x3 " &
        "[process/activity]",
  ),
  EntryGismuEnglish(
    word: "lanme",
    keyword: "sheep",
    hint: "'lanolin, lamb'",
    definition: "x1 is a sheep/[lamb/ewe/ram] of species/breed x2 of flock x3",
  ),
  EntryGismuEnglish(
    word: "lante",
    keyword: "can",
    hint: "",
    definition: "x1 is a can/tightly sealed/pre-sealed container for perishable contents x2, " &
        "made of x3",
  ),
  EntryGismuEnglish(
    word: "lanxe",
    keyword: "balance",
    hint: "",
    definition: "x1 is in balance/equilibrium under forces x2 (mass)",
  ),
  EntryGismuEnglish(
    word: "lanzu",
    keyword: "family",
    hint: "'clan'",
    definition: "x1 (mass) is a family with members including x2 bonded/tied/joined according to " &
        "standard x3",
  ),
  EntryGismuEnglish(
    word: "larcu",
    keyword: "art",
    hint: "",
    definition: "x1 (process) is an art [creative application] of craft/skill x2 (idea/activity)",
  ),
  EntryGismuEnglish(
    word: "lasna",
    keyword: "fasten",
    hint: "'lash'",
    definition: "x1 (agent) fastens/connects/attaches/binds/lashes x2 to x3 with fastener x4",
  ),
  EntryGismuEnglish(
    word: "lastu",
    keyword: "brass",
    hint: "",
    definition: "x1 is a quantity of/contains/is made of brass [copper/zinc alloy] of " &
        "composition including x2",
  ),
  EntryGismuEnglish(
    word: "latmo",
    keyword: "Latin",
    hint: "",
    definition: "x1 reflects Latin/Roman/Romance culture/empire/language in aspect x2",
  ),
  EntryGismuEnglish(
    word: "latna",
    keyword: "lotus",
    hint: "",
    definition: "x1 is a lotus, plant/flower/herb of species/strain x2 symbolizing x3 to " &
        "culture/religion x4",
  ),
  EntryGismuEnglish(
    word: "lazni",
    keyword: "lazy",
    hint: "",
    definition: "x1 (person) is lazy/avoiding work/effort concerning action x2",
  ),
  EntryGismuEnglish(
    word: "le'e",
    keyword: "the stereotypical",
    hint: "",
    definition: "non-veridical descriptor: the stereotype of those described as ...",
  ),
  EntryGismuEnglish(
    word: "lebna",
    keyword: "take",
    hint: "",
    definition: "x1 takes/gets/gains/obtains/seizes/[removes] x2 (object/property) from x3 " &
        "(possessor)",
  ),
  EntryGismuEnglish(
    word: "lenjo",
    keyword: "lens",
    hint: "",
    definition: "x1 is a lens/glass [focussing shape/form] focussing x2 to focus/foci x3 by " &
        "means/material x4",
  ),
  EntryGismuEnglish(
    word: "lenku",
    keyword: "cold",
    hint: "'cool'",
    definition: "x1 is cold/cool by standard x2",
  ),
  EntryGismuEnglish(
    word: "lerci",
    keyword: "late",
    hint: "",
    definition: "x1 (event) is late by standard x2",
  ),
  EntryGismuEnglish(
    word: "lerfu",
    keyword: "letteral",
    hint: "",
    definition: "x1 (la'e zo BY/word-bu) is a letter/digit/symbol in alphabet/character-set x2 " &
        "representing x3",
  ),
  EntryGismuEnglish(
    word: "li'i",
    keyword: "experience abstract",
    hint: "",
    definition: "abstractor: experience abstractor; x1 is x2's experience of [bridi] " &
        "(participant or observer)",
  ),
  EntryGismuEnglish(
    word: "libjo",
    keyword: "Libyan",
    hint: "",
    definition: "x1 reflects Libyan culture/nationality in aspect x2",
  ),
  EntryGismuEnglish(
    word: "lidne",
    keyword: "precede",
    hint: "'leader'",
    definition: "x1 precedes/leads x2 in sequence x3; x1 is former/preceding/previous; x2 is " &
        "latter/following",
  ),
  EntryGismuEnglish(
    word: "lifri",
    keyword: "experience",
    hint: "'life'",
    definition: "x1 [person/passive/state] undergoes/experiences x2 (event/experience); x2 " &
        "happens to x1",
  ),
  EntryGismuEnglish(
    word: "lijda",
    keyword: "religion",
    hint: "",
    definition: "x1 is a religion of believers including x2 sharing common " &
        "beliefs/practices/tenets including x3",
  ),
  EntryGismuEnglish(
    word: "limna",
    keyword: "swim",
    hint: "",
    definition: "x1 (agent) swims in fluid x2",
  ),
  EntryGismuEnglish(
    word: "lindi",
    keyword: "lightning",
    hint: "",
    definition: "x1 is lightning/electrical arc/thunderbolt striking at/extending to x2 from x3",
  ),
  EntryGismuEnglish(
    word: "linji",
    keyword: "line",
    hint: "",
    definition: "x1 is a line/among lines [1-dimensional shape/form] defined by set of points x2",
  ),
  EntryGismuEnglish(
    word: "linsi",
    keyword: "chain",
    hint: "'links'",
    definition: "x1 is a length of chain/links of material x2 with link properties x3",
  ),
  EntryGismuEnglish(
    word: "linto",
    keyword: "lightweight",
    hint: "",
    definition: "x1 is light in mass/weight by standard x2",
  ),
  EntryGismuEnglish(
    word: "lisri",
    keyword: "story",
    hint: "",
    definition: "x1 is a story/tale/yarn/narrative about plot/subject/moral x2 by storyteller x3 " &
        "to audience x4",
  ),
  EntryGismuEnglish(
    word: "liste",
    keyword: "list",
    hint: "",
    definition: "x1 (physical object) is a list/catalog/register of sequence/set x2 in order x3 " &
        "in medium x4",
  ),
  EntryGismuEnglish(
    word: "litce",
    keyword: "liter",
    hint: "",
    definition: "x1 is x2 liter(s) [metric unit] in volume (default is 1) by standard x3",
  ),
  EntryGismuEnglish(
    word: "litki",
    keyword: "liquid",
    hint: "",
    definition: "x1 is liquid/fluid, of composition/material including x2, under conditions x3",
  ),
  EntryGismuEnglish(
    word: "litru",
    keyword: "travel",
    hint: "",
    definition: "x1 travels/journeys/goes/moves via route x2 using means/vehicle x3; x1 is a " &
        "traveller",
  ),
  EntryGismuEnglish(
    word: "livga",
    keyword: "liver",
    hint: "",
    definition: "x1 is a/the liver [body-part] of x2",
  ),
  EntryGismuEnglish(
    word: "livla",
    keyword: "fuel",
    hint: "",
    definition: "x1 is a fuel/energy-source for powering x2",
  ),
  EntryGismuEnglish(
    word: "lo'e",
    keyword: "the typical",
    hint: "",
    definition: "veridical descriptor: the typical one(s) who really is(are) ...",
  ),
  EntryGismuEnglish(
    word: "logji",
    keyword: "logic",
    hint: "",
    definition: "x1 [rules/methods] is a logic for deducing/concluding/inferring/reasoning " &
        "to/about x2 (du'u)",
  ),
  EntryGismuEnglish(
    word: "lojbo",
    keyword: "Lojbanic",
    hint: "",
    definition: "x1 reflects [Loglandic]/Lojbanic language/culture/nationality/community in " &
        "aspect x2",
  ),
  EntryGismuEnglish(
    word: "loldi",
    keyword: "floor",
    hint: "",
    definition: "x1 is a floor/bottom/ground of x2",
  ),
  EntryGismuEnglish(
    word: "lorxu",
    keyword: "fox",
    hint: "",
    definition: "x1 is a fox [bushy-tailed wild dog/canine] of species/breed x2",
  ),
  EntryGismuEnglish(
    word: "lubno",
    keyword: "Lebanese",
    hint: "",
    definition: "x1 reflects Lebanese culture/nationality in aspect x2",
  ),
  EntryGismuEnglish(
    word: "lujvo",
    keyword: "affix compound",
    hint: "",
    definition: "x1 (text) is a compound predicate word with meaning x2 and arguments x3 built " &
        "from metaphor x4",
  ),
  EntryGismuEnglish(
    word: "lumci",
    keyword: "wash",
    hint: "",
    definition: "x1 (agent) washes/cleanses x2 of soil/contaminant x3 in/with cleaning " &
        "material(s) x4",
  ),
  EntryGismuEnglish(
    word: "lunbe",
    keyword: "bare",
    hint: "",
    definition: "x1 is bare/naked/nude; x1 is without cover/clothes/[protection]",
  ),
  EntryGismuEnglish(
    word: "lunra",
    keyword: "lunar",
    hint: "",
    definition: "x1 is Earth's moon (default); x1 is a major natural satellite/moon of planet x2",
  ),
  EntryGismuEnglish(
    word: "lunsa",
    keyword: "condense",
    hint: "",
    definition: "x1 condenses/liquefies on/into x2 at temperature x3, pressure x4; x1 is " &
        "dew/condensate on x2",
  ),
  EntryGismuEnglish(
    word: "mabla",
    keyword: "derogative",
    hint: "",
    definition: "x1 is a derogative connotation/sense of x2 used by x3; x3 derogates/'curses at' " &
        "x2 in form x1",
  ),
  EntryGismuEnglish(
    word: "mabru",
    keyword: "mammal",
    hint: "",
    definition: "x1 is a mammal/'animal'/beast of species x2",
  ),
  EntryGismuEnglish(
    word: "macnu",
    keyword: "manual",
    hint: "",
    definition: "x1 (event/action/process) is manual [not automatic] in function x2 under " &
        "conditions x3",
  ),
  EntryGismuEnglish(
    word: "makcu",
    keyword: "mature",
    hint: "",
    definition: "x1 is mature/ripe/fully-grown/adult in development-quality x2 (ka)",
  ),
  EntryGismuEnglish(
    word: "makfa",
    keyword: "magic",
    hint: "",
    definition: "x1 is magic/supernatural/sorcery/witchcraft/wizardry to x2, performed by " &
        "person/force/deity x3",
  ),
  EntryGismuEnglish(
    word: "maksi",
    keyword: "magnet",
    hint: "",
    definition: "x1 is magnetic [adjective] producing magnetic field x2",
  ),
  EntryGismuEnglish(
    word: "malsi",
    keyword: "temple",
    hint: "",
    definition: "x1 is a temple/church/sanctuary/synagogue/shrine of religion x2 at " &
        "location/serving area x3",
  ),
  EntryGismuEnglish(
    word: "mamta",
    keyword: "mother",
    hint: "'mom'",
    definition: "x1 is a mother of x2; x1 bears/mothers/acts maternally toward x2; [not " &
        "necessarily biological]",
  ),
  EntryGismuEnglish(
    word: "manci",
    keyword: "wonder",
    hint: "",
    definition: "x1 feels wonder/awe/marvels about x2",
  ),
  EntryGismuEnglish(
    word: "manfo",
    keyword: "uniform",
    hint: "",
    definition: "x1 (object/event) is uniform/homogeneous in property x2 (ka)",
  ),
  EntryGismuEnglish(
    word: "manku",
    keyword: "dark",
    hint: "",
    definition: "x1 is dark/lacking in illumination",
  ),
  EntryGismuEnglish(
    word: "manri",
    keyword: "reference",
    hint: "",
    definition: "x1 is a frame of reference/standard for observing/measuring/determining x2, " &
        "with/by rules x3",
  ),
  EntryGismuEnglish(
    word: "mansa",
    keyword: "satisfy",
    hint: "",
    definition: "x1 satisfies evaluator x2 in property (ka)/state x3",
  ),
  EntryGismuEnglish(
    word: "manti",
    keyword: "ant",
    hint: "",
    definition: "x1 is an ant of species/breed x2",
  ),
  EntryGismuEnglish(
    word: "mapku",
    keyword: "cap",
    hint: "",
    definition: "x1 is a cap/hat/crown/helmet/piece of headgear [head-top garment] of material x2",
  ),
  EntryGismuEnglish(
    word: "mapni",
    keyword: "cotton",
    hint: "",
    definition: "x1 is a quantity of/contains/is made of cotton [type of fabric/material]",
  ),
  EntryGismuEnglish(
    word: "mapti",
    keyword: "fit",
    hint: "'match'",
    definition: "x1 fits/matches/suits/is compatible/appropriate/corresponds to/with x2 in " &
        "property/aspect x3",
  ),
  EntryGismuEnglish(
    word: "marbi",
    keyword: "shelter",
    hint: "'harbor'",
    definition: "x1 is a shelter/haven/refuge/retreat/harbor for/protecting x2 from " &
        "danger/threat x3",
  ),
  EntryGismuEnglish(
    word: "marce",
    keyword: "vehicle",
    hint: "",
    definition: "x1 is a vehicle/mode of transport carrying x2 in/on surface/medium x3, " &
        "propelled by x4",
  ),
  EntryGismuEnglish(
    word: "marde",
    keyword: "morals",
    hint: "",
    definition: "x1 are the ethics/morals/moral standards/ethical standards of x2 (ind./mass) " &
        "about situation x3",
  ),
  EntryGismuEnglish(
    word: "margu",
    keyword: "mercury",
    hint: "",
    definition: "x1 is a quantity of/contains/made of mercury/quicksilver; [metaphor: fluid " &
        "metal; temperature]",
  ),
  EntryGismuEnglish(
    word: "marji",
    keyword: "material",
    hint: "'matter'",
    definition: "x1 is material/stuff/matter of type/composition including x2 in shape/form x3",
  ),
  EntryGismuEnglish(
    word: "marna",
    keyword: "hemp",
    hint: "'marijuana'",
    definition: "x1 is a quantity of hemp/marijuana/jute of species/strain x2",
  ),
  EntryGismuEnglish(
    word: "marxa",
    keyword: "mash",
    hint: "",
    definition: "x1 [force] mashes/crushes/squashes/smashes x2 into pulp/mash/crumbs/deformed " &
        "mass x3",
  ),
  EntryGismuEnglish(
    word: "masno",
    keyword: "slow",
    hint: "",
    definition: "x1 is slow/sluggish at doing/being/bringing about x2 (event/state)",
  ),
  EntryGismuEnglish(
    word: "masti",
    keyword: "month",
    hint: "",
    definition: "x1 is x2 months in duration (default is 1 month) by month standard x3",
  ),
  EntryGismuEnglish(
    word: "matci",
    keyword: "mat",
    hint: "",
    definition: "x1 is a mat/pad/mattress/pallet [flat, soft, dense form] of material x2",
  ),
  EntryGismuEnglish(
    word: "matli",
    keyword: "linen",
    hint: "",
    definition: "x1 is a quantity of/contains/is made of linen/flax [type of fabric/material]",
  ),
  EntryGismuEnglish(
    word: "matne",
    keyword: "butter",
    hint: "",
    definition: "x1 is a quantity of/contains butter/oleo/margarine/shortening from source x2",
  ),
  EntryGismuEnglish(
    word: "matra",
    keyword: "motor",
    hint: "",
    definition: "x1 is a motor/engine, driving/propelling/providing power to x2",
  ),
  EntryGismuEnglish(
    word: "mavji",
    keyword: "oats",
    hint: "",
    definition: "x1 is a quantity of oats [grain] of species/strain x2",
  ),
  EntryGismuEnglish(
    word: "maxri",
    keyword: "wheat",
    hint: "",
    definition: "x1 is a quantity of wheat [grain] of species/strain x2",
  ),
  EntryGismuEnglish(
    word: "mebri",
    keyword: "brow",
    hint: "",
    definition: "x1 is a/the brow/forehead [projecting flat/smooth head/body-part] of x2",
  ),
  EntryGismuEnglish(
    word: "megdo",
    keyword: "1E6",
    hint: "metric 'mega'",
    definition: "x1 is a million [1x10**6] of x2 in dimension/aspect x3 (default is units)",
  ),
  EntryGismuEnglish(
    word: "mei",
    keyword: "cardinal selbri",
    hint: "",
    definition: "convert number to cardinality selbri; x1 is the mass formed from set x2 with " &
        "member(s) x3",
  ),
  EntryGismuEnglish(
    word: "mekso",
    keyword: "MEX",
    hint: "",
    definition: "x1 [quantifier/expression] is a mathematical expression interpreted under " &
        "rules/convention x2",
  ),
  EntryGismuEnglish(
    word: "melbi",
    keyword: "beautiful",
    hint: "",
    definition: "x1 is beautiful/pleasant to x2 in aspect x3 (ka) by aesthetic standard x4",
  ),
  EntryGismuEnglish(
    word: "meljo",
    keyword: "Malaysian",
    hint: "",
    definition: "x1 reflects Malaysian/Malay culture/nationality/language in aspect x2",
  ),
  EntryGismuEnglish(
    word: "menli",
    keyword: "mind",
    hint: "'mental'",
    definition: "x1 is a mind/intellect/psyche/mentality/[consciousness] of body x2",
  ),
  EntryGismuEnglish(
    word: "mensi",
    keyword: "sister",
    hint: "",
    definition: "x1 is a sister of/sororal to x2 by bond/tie/standard/parent(s) x3; [not " &
        "necessarily biological]",
  ),
  EntryGismuEnglish(
    word: "mentu",
    keyword: "minute",
    hint: "",
    definition: "x1 is x2 minutes in duration (default is 1 minute) by standard x3",
  ),
  EntryGismuEnglish(
    word: "merko",
    keyword: "American",
    hint: "",
    definition: "x1 pertains to USA/American culture/nationality/dialect in aspect x2",
  ),
  EntryGismuEnglish(
    word: "merli",
    keyword: "measure",
    hint: "",
    definition: "x1 (agent) measures/evaluates x2 [quantity] as x3 units on scale x4 (si'o), " &
        "with accuracy x5",
  ),
  EntryGismuEnglish(
    word: "mexno",
    keyword: "Mexican",
    hint: "",
    definition: "x1 reflects Mexican culture/nationality in aspect x2",
  ),
  EntryGismuEnglish(
    word: "mi",
    keyword: "me",
    hint: "",
    definition: "pro-sumti: me/we the speaker(s)/author(s); identified by self-vocative",
  ),
  EntryGismuEnglish(
    word: "midju",
    keyword: "middle",
    hint: "",
    definition: "x1 is in/at the middle/center/midpoint/[is a focus] of x2; (adjective:) x1 is " &
        "central",
  ),
  EntryGismuEnglish(
    word: "mifra",
    keyword: "code",
    hint: "'cipher'",
    definition: "x1 is encoded/cipher text of plain-text x2 by code/coding system x3; x1 is in " &
        "code; x3 is a code",
  ),
  EntryGismuEnglish(
    word: "mikce",
    keyword: "doctor",
    hint: "'medic'",
    definition: "x1 doctors/treats/nurses/[cures]/is physician/midwife to x2 for ailment x3 by " &
        "treatment/cure x4",
  ),
  EntryGismuEnglish(
    word: "mikri",
    keyword: "1E-6",
    hint: "metric 'micro'",
    definition: "x1 is a millionth [1x10**-6] of x2 in dimension/aspect x3 (default is units)",
  ),
  EntryGismuEnglish(
    word: "milti",
    keyword: ".001",
    hint: "metric 'milli'",
    definition: "x1 is a thousandth [1/1000; 1x10**-3] of x2 in dimension/aspect x3 (default is " &
        "units)",
  ),
  EntryGismuEnglish(
    word: "milxe",
    keyword: "mild",
    hint: "",
    definition: "x1 is mild/non-extreme/gentle/middling/somewhat in property x2 (ka); x1 is not " &
        "very x2",
  ),
  EntryGismuEnglish(
    word: "minde",
    keyword: "command",
    hint: "",
    definition: "x1 issues commands/orders to x2 for result x3 (event/state) to happen; x3 is " &
        "commanded to occur",
  ),
  EntryGismuEnglish(
    word: "minji",
    keyword: "machine",
    hint: "",
    definition: "x1 is a machine for use/function x2; [automated apparatus, without direct " &
        "function control]",
  ),
  EntryGismuEnglish(
    word: "minli",
    keyword: "mile",
    hint: "",
    definition: "x1 is x2 (default 1) long local distance unit(s) [non-metric], x3 subunits, " &
        "standard x4",
  ),
  EntryGismuEnglish(
    word: "minra",
    keyword: "reflect",
    hint: "'mirror'",
    definition: "x1 reflects/mirrors/echoes x2 [object/radiation] to observer/point x3 as x4; x2 " &
        "bounces on x1",
  ),
  EntryGismuEnglish(
    word: "mintu",
    keyword: "same",
    hint: "'identical'",
    definition: "x1 is the same/identical thing as x2 by standard x3; (x1 and x2 interchangeable)",
  ),
  EntryGismuEnglish(
    word: "mipri",
    keyword: "secret",
    hint: "",
    definition: "x1 keeps x2 secret/hidden from x3 by method x4; x2 is a secret; x1 " &
        "hides/conceals x2",
  ),
  EntryGismuEnglish(
    word: "mirli",
    keyword: "deer",
    hint: "",
    definition: "x1 is a deer/elk/moose/[hart/stag/doe] of species/breed x2",
  ),
  EntryGismuEnglish(
    word: "misno",
    keyword: "famous",
    hint: "",
    definition: "x1 (person/object/event) is famous/renowned/is a celebrity among community of " &
        "persons x2 (mass)",
  ),
  EntryGismuEnglish(
    word: "misro",
    keyword: "Egyptian",
    hint: "'Mizraim'",
    definition: "x1 reflects Egyptian culture/nationality in aspect x2",
  ),
  EntryGismuEnglish(
    word: "mitre",
    keyword: "meter",
    hint: "",
    definition: "x1 is x2 meter(s) [metric unit] in length (default 1) measured in direction x3 " &
        "by standard x4",
  ),
  EntryGismuEnglish(
    word: "mixre",
    keyword: "mixture",
    hint: "",
    definition: "x1 (mass) is a mixture/blend/colloid/commingling with ingredients including x2",
  ),
  EntryGismuEnglish(
    word: "mlana",
    keyword: "side",
    hint: "'lateral'",
    definition: "x1 is to the side of/lateral to x2 and facing x3 from point of " &
        "view/in-frame-of-reference x4",
  ),
  EntryGismuEnglish(
    word: "mlatu",
    keyword: "cat",
    hint: "",
    definition: "x1 is a cat/[puss/pussy/kitten] [feline animal] of species/breed x2; " &
        "(adjective:) x1 is feline",
  ),
  EntryGismuEnglish(
    word: "mleca",
    keyword: "less",
    hint: "",
    definition: "x1 is less than x2 in property/quantity x3 (ka/ni) by amount x4",
  ),
  EntryGismuEnglish(
    word: "mledi",
    keyword: "mold",
    hint: "",
    definition: "x1 is a mold/fungus/mushrooms/truffles of species/strain x2 parasitic/growing " &
        "on x3",
  ),
  EntryGismuEnglish(
    word: "mluni",
    keyword: "satellite",
    hint: "'moon'",
    definition: "x1 is a satellite/moon orbiting x2 with characteristics x3, orbital parameters x4",
  ),
  EntryGismuEnglish(
    word: "mo'a",
    keyword: "too few",
    hint: "",
    definition: "digit/number: too few; subjective",
  ),
  EntryGismuEnglish(
    word: "mo'i",
    keyword: "space motion",
    hint: "",
    definition: "mark motions in space-time",
  ),
  EntryGismuEnglish(
    word: "moi",
    keyword: "ordinal selbri",
    hint: "",
    definition: "convert number to ordinal selbri; x1 is (n)th member of set x2 ordered by rule x3",
  ),
  EntryGismuEnglish(
    word: "mokca",
    keyword: "point",
    hint: "'moment'",
    definition: "x1 is a point/instant/moment [0-dimensional shape/form] in/on/at time/place x2",
  ),
  EntryGismuEnglish(
    word: "moklu",
    keyword: "mouth",
    hint: "'oral'",
    definition: "x1 is a/the mouth/oral cavity [body-part] of x2; (metaphor: entrance/intake for " &
        "consumption)",
  ),
  EntryGismuEnglish(
    word: "molki",
    keyword: "mill",
    hint: "",
    definition: "x1 is a mill/foundry/industrial plant/[assembly line] performing process x2",
  ),
  EntryGismuEnglish(
    word: "molro",
    keyword: "mole",
    hint: "",
    definition: "x1 is x2 mole(s) [metric unit] in substance (default is 1) by standard x3",
  ),
  EntryGismuEnglish(
    word: "morji",
    keyword: "remember",
    hint: "'memory'",
    definition: "x1 remembers/recalls/recollects fact(s)/memory x2 (du'u) about subject x3",
  ),
  EntryGismuEnglish(
    word: "morko",
    keyword: "Moroccan",
    hint: "",
    definition: "x1 reflects Moroccan culture/nationality in aspect x2",
  ),
  EntryGismuEnglish(
    word: "morna",
    keyword: "pattern",
    hint: "'form'",
    definition: "x1 is/reflects/represents a pattern of forms/events x2 arranged according to " &
        "structure x3",
  ),
  EntryGismuEnglish(
    word: "morsi",
    keyword: "dead",
    hint: "'mort-'",
    definition: "x1 is dead/has ceased to be alive",
  ),
  EntryGismuEnglish(
    word: "mosra",
    keyword: "friction",
    hint: "'rub'",
    definition: "x1 is friction [force opposing motion] due to contact/rubbing between x2 and " &
        "x3; (fe) x2 rubs x3",
  ),
  EntryGismuEnglish(
    word: "mraji",
    keyword: "rye",
    hint: "",
    definition: "x1 is a quantity of rye [grain] of species/strain x2",
  ),
  EntryGismuEnglish(
    word: "mrilu",
    keyword: "mail",
    hint: "",
    definition: "x1 mails/posts [transfer via intermediary service] x2 to x3 from x4 by " &
        "carrier/network/system x5",
  ),
  EntryGismuEnglish(
    word: "mruli",
    keyword: "hammer",
    hint: "",
    definition: "x1 [tool] is a hammer for/hammers x2 [target] consisting of weight/head x3 " &
        "propelled by x4",
  ),
  EntryGismuEnglish(
    word: "mu",
    keyword: "5",
    hint: "",
    definition: "digit/number: 5 (digit)",
  ),
  EntryGismuEnglish(
    word: "mu'e",
    keyword: "point-event abstract",
    hint: "",
    definition: "abstractor: achievement (event) abstractor; x1 is the " &
        "event-as-a-point/achievement of [bridi]",
  ),
  EntryGismuEnglish(
    word: "mucti",
    keyword: "immaterial",
    hint: "",
    definition: "x1 is immaterial/not physical/without material form",
  ),
  EntryGismuEnglish(
    word: "mudri",
    keyword: "wood",
    hint: "'lumber'",
    definition: "x1 is a quantity of/is made of/contains wood/lumber from tree(s) of " &
        "type/species x2",
  ),
  EntryGismuEnglish(
    word: "mukti",
    keyword: "motive",
    hint: "",
    definition: "x1 (action/event/state) motivates/is a motive/incentive for action/event x2, " &
        "per volition of x3",
  ),
  EntryGismuEnglish(
    word: "mulno",
    keyword: "complete",
    hint: "",
    definition: "x1 (event) is complete/done/finished; x1 (object) has become whole in property " &
        "x2 by standard x3",
  ),
  EntryGismuEnglish(
    word: "munje",
    keyword: "universe",
    hint: "",
    definition: "x1 is a universe/cosmos [complete and ordered entirety] of domain/sphere x2 " &
        "defined by rules x3",
  ),
  EntryGismuEnglish(
    word: "mupli",
    keyword: "example",
    hint: "",
    definition: "x1 is an example/sample/specimen/instance/case/illustration of common " &
        "property(s) x2 of set x3",
  ),
  EntryGismuEnglish(
    word: "murse",
    keyword: "glimmering",
    hint: "",
    definition: "x1 is the [astronomical] twilight/dawn/dusk/half-light/glimmering of day x2 at " &
        "location x3",
  ),
  EntryGismuEnglish(
    word: "murta",
    keyword: "curtain",
    hint: "",
    definition: "x1 is a curtain/blinds/drapes for covering/obscuring aperture x2, and made of " &
        "material x3",
  ),
  EntryGismuEnglish(
    word: "muslo",
    keyword: "Islamic",
    hint: "",
    definition: "x1 pertains to the Islamic/Moslem/Koranic [Quranic] culture/religion/nation in " &
        "aspect x2",
  ),
  EntryGismuEnglish(
    word: "mutce",
    keyword: "much",
    hint: "",
    definition: "x1 is much/extreme in property x2 (ka), towards x3 extreme/direction; x1 is, in " &
        "x2, very x3",
  ),
  EntryGismuEnglish(
    word: "muvdu",
    keyword: "move",
    hint: "",
    definition: "x1 (object) moves to destination/receiver x2 [away] from origin x3 over " &
        "path/route x4",
  ),
  EntryGismuEnglish(
    word: "muzga",
    keyword: "museum",
    hint: "",
    definition: "x1 is a museum for preserving [and possibly exhibiting] x2 at location x3",
  ),
  EntryGismuEnglish(
    word: "na",
    keyword: "bridi negator",
    hint: "",
    definition: "bridi contradictory negator; scope is an entire bridi; logically negates in " &
        "some cmavo compounds",
  ),
  EntryGismuEnglish(
    word: "na'e",
    keyword: "scalar contrary",
    hint: "",
    definition: "contrary scalar negator: other than ...; not ...; a scale or set is implied",
  ),
  EntryGismuEnglish(
    word: "nabmi",
    keyword: "problem",
    hint: "",
    definition: "x1 (event/state) is a problem to/encountered by x2 in situation/task/inquiry x3",
  ),
  EntryGismuEnglish(
    word: "nakni",
    keyword: "male",
    hint: "'masculine'",
    definition: "x1 is a male/buck of species x2 evidencing masculine trait(s) x3 (ka); x1 is " &
        "masculine",
  ),
  EntryGismuEnglish(
    word: "nalci",
    keyword: "wing",
    hint: "",
    definition: "x1 is a/the wing [body-part] of x2; [metaphor: lateral supporting surface]",
  ),
  EntryGismuEnglish(
    word: "namcu",
    keyword: "number",
    hint: "",
    definition: "x1 (li) is a number/quantifier/digit/value/figure (noun); refers to the value " &
        "and not the symbol",
  ),
  EntryGismuEnglish(
    word: "nanba",
    keyword: "bread",
    hint: "",
    definition: "x1 is a quantity of/contains bread [leavened or unleavened] made from grains x2",
  ),
  EntryGismuEnglish(
    word: "nanca",
    keyword: "year",
    hint: "",
    definition: "x1 is x2 years in duration (default is 1 year) by standard x3; (adjective:) x1 " &
        "is annual",
  ),
  EntryGismuEnglish(
    word: "nandu",
    keyword: "difficult",
    hint: "'hard'",
    definition: "x1 is difficult/hard/challenging for x2 under conditions x3; x1 challenges " &
        "(non-agentive) x2",
  ),
  EntryGismuEnglish(
    word: "nanla",
    keyword: "boy",
    hint: "'lad'",
    definition: "x1 is a boy/lad [young male person] of age x2 immature by standard x3",
  ),
  EntryGismuEnglish(
    word: "nanmu",
    keyword: "man",
    hint: "",
    definition: "x1 is a man/men; x1 is a male humanoid person [not necessarily adult]",
  ),
  EntryGismuEnglish(
    word: "nanvi",
    keyword: "1E-9",
    hint: "metric 'nano'",
    definition: "x1 is a billionth/thousand-millionth [1x10**-9] of x2 in dimension/aspect x3 " &
        "(default is units)",
  ),
  EntryGismuEnglish(
    word: "narge",
    keyword: "nut",
    hint: "",
    definition: "x1 is a nut [body-part: hard-shelled fruit] from plant/species x2 with shell x3 " &
        "and kernel x4",
  ),
  EntryGismuEnglish(
    word: "narju",
    keyword: "orange",
    hint: "",
    definition: "x1 is orange [color adjective]",
  ),
  EntryGismuEnglish(
    word: "natfe",
    keyword: "deny",
    hint: "",
    definition: "x1 (du'u) contradicts/denies/refutes/negates x2 (du'u) under rules/logic x3",
  ),
  EntryGismuEnglish(
    word: "natmi",
    keyword: "nation",
    hint: "",
    definition: "x1 is a nation/ethnic group of peoples x2; [people sharing a history/culture]",
  ),
  EntryGismuEnglish(
    word: "navni",
    keyword: "neon",
    hint: "",
    definition: "x1 is a quantity of/contains/is made of inert gas of type x2 " &
        "[neon/argon/radon/xenon]",
  ),
  EntryGismuEnglish(
    word: "naxle",
    keyword: "canal",
    hint: "",
    definition: "x1 is a canal/channel to x2 from x3 with route x4",
  ),
  EntryGismuEnglish(
    word: "nazbi",
    keyword: "nose",
    hint: "'nasal'",
    definition: "x1 is the nose [body-part] of x2 with nostril(s)/nasal passage(s) x3; " &
        "[metaphor: protrusion]",
  ),
  EntryGismuEnglish(
    word: "nejni",
    keyword: "energy",
    hint: "",
    definition: "x1 is energy of type x2 in form x3",
  ),
  EntryGismuEnglish(
    word: "nelci",
    keyword: "fond",
    hint: "'likes'",
    definition: "x1 is fond of/likes/has a taste for x2 (object/state)",
  ),
  EntryGismuEnglish(
    word: "nenri",
    keyword: "in",
    hint: "'inner'",
    definition: "x1 is in/inside/within x2; x1 is on the inside/interior of x2 [totally within " &
        "the bounds of x2]",
  ),
  EntryGismuEnglish(
    word: "ni",
    keyword: "amount abstract",
    hint: "",
    definition: "abstractor: quantity/amount abstractor; x1 is quantity/amount of [bridi] " &
        "measured on scale x2",
  ),
  EntryGismuEnglish(
    word: "nibli",
    keyword: "necessitate",
    hint: "",
    definition: "x1 logically necessitates/entails/implies action/event/state x2 under " &
        "rules/logic system x3",
  ),
  EntryGismuEnglish(
    word: "nicte",
    keyword: "night",
    hint: "",
    definition: "x1 is a nighttime of day x2 at location x3; (adjective:) x1 is at night/nocturnal",
  ),
  EntryGismuEnglish(
    word: "nikle",
    keyword: "nickel",
    hint: "",
    definition: "x1 is made of/contains/is a quantity of nickel/other metal resistant to oxidation",
  ),
  EntryGismuEnglish(
    word: "nilce",
    keyword: "furniture",
    hint: "",
    definition: "x1 [furniture items] furnishes x2 [location] serving purpose/function x3",
  ),
  EntryGismuEnglish(
    word: "nimre",
    keyword: "citrus",
    hint: "'lime'",
    definition: "x1 is a quantity of citrus [fruit/tree, etc.] of species/strain x2",
  ),
  EntryGismuEnglish(
    word: "ninmu",
    keyword: "woman",
    hint: "'women'",
    definition: "x1 is a woman/women; x1 is a female humanoid person [not necessarily adult]",
  ),
  EntryGismuEnglish(
    word: "nirna",
    keyword: "nerve",
    hint: "",
    definition: "x1 is a nerve/neuron [body-part] of x2; [metaphor: information/control network " &
        "connection]",
  ),
  EntryGismuEnglish(
    word: "nitcu",
    keyword: "need",
    hint: "",
    definition: "x1 needs/requires/is dependent on/[wants] necessity x2 for purpose/action/stage " &
        "of process x3",
  ),
  EntryGismuEnglish(
    word: "nivji",
    keyword: "knit",
    hint: "",
    definition: "x1 (agent) knits x2 [cloth/object] from yarn/thread x3",
  ),
  EntryGismuEnglish(
    word: "nixli",
    keyword: "girl",
    hint: "",
    definition: "x1 is a girl [young female person] of age x2 immature by standard x3",
  ),
  EntryGismuEnglish(
    word: "no",
    keyword: "0",
    hint: "",
    definition: "digit/number: 0 (digit)",
  ),
  EntryGismuEnglish(
    word: "no'e",
    keyword: "scalar midpoint not",
    hint: "",
    definition: "midpoint scalar negator: neutral point between je'a and to'e; \"not really\"",
  ),
  EntryGismuEnglish(
    word: "nobli",
    keyword: "noble",
    hint: "",
    definition: "x1 is noble/aristocratic/elite/high-born/titled in/under " &
        "culture/society/standard x2",
  ),
  EntryGismuEnglish(
    word: "notci",
    keyword: "message",
    hint: "'note'",
    definition: "x1 is a message/notice/memorandum about subject x2 from author x3 to intended " &
        "audience x4",
  ),
  EntryGismuEnglish(
    word: "nu",
    keyword: "event abstract",
    hint: "",
    definition: "abstractor: generalized event abstractor; x1 is " &
        "state/process/achievement/activity of [bridi]",
  ),
  EntryGismuEnglish(
    word: "nu'o",
    keyword: "can but has not",
    hint: "",
    definition: "modal aspect: can but has not; unrealized potential",
  ),
  EntryGismuEnglish(
    word: "nukni",
    keyword: "magenta",
    hint: "'fuchsin'",
    definition: "x1 is magenta/fuchsia/purplish-red [color adjective]",
  ),
  EntryGismuEnglish(
    word: "nupre",
    keyword: "promise",
    hint: "",
    definition: "x1 (agent) promises/commits/assures/threatens x2 (event/state) to x3 " &
        "[beneficiary/victim]",
  ),
  EntryGismuEnglish(
    word: "nurma",
    keyword: "rural",
    hint: "",
    definition: "x1 is a rural/rustic/pastoral area of x2; x1 is in the country",
  ),
  EntryGismuEnglish(
    word: "nutli",
    keyword: "neutral",
    hint: "",
    definition: "x1 is neutral/not taking sides/medial/not towards any extreme on scale/in " &
        "dissension x2",
  ),
  EntryGismuEnglish(
    word: "nuzba",
    keyword: "news",
    hint: "",
    definition: "x1 (du'u) is news/tidings/new information about subject x2 from source x3, to " &
        "observer x4",
  ),
  EntryGismuEnglish(
    word: "pa",
    keyword: "1",
    hint: "",
    definition: "digit/number: 1 (digit)",
  ),
  EntryGismuEnglish(
    word: "pacna",
    keyword: "hope",
    hint: "",
    definition: "x1 hopes/wishes for/desires x2 (event), expected likelihood x3 (0-1); x1 hopes " &
        "that x2 happens",
  ),
  EntryGismuEnglish(
    word: "pagbu",
    keyword: "part",
    hint: "",
    definition: "x1 is a part/component/piece/portion/segment of x2 [where x2 is a whole/mass]; " &
        "x2 is partly x1",
  ),
  EntryGismuEnglish(
    word: "pagre",
    keyword: "pass through",
    hint: "",
    definition: "x1 passes through/penetrates barrier/medium/portal x2 to destination side x3 " &
        "from origin side x4",
  ),
  EntryGismuEnglish(
    word: "pajni",
    keyword: "judge",
    hint: "",
    definition: "x1 judges/referees/arbitrates/is a judge determining/deciding matter x2 " &
        "(abstract)",
  ),
  EntryGismuEnglish(
    word: "palci",
    keyword: "evil",
    hint: "",
    definition: "x1 is evil/depraved/wicked [morally bad] by standard x2",
  ),
  EntryGismuEnglish(
    word: "palku",
    keyword: "pants",
    hint: "",
    definition: "x1 are pants/trousers/slacks/leggings [legged garment] of material x2",
  ),
  EntryGismuEnglish(
    word: "palne",
    keyword: "tray",
    hint: "'pan, platter'",
    definition: "x1 is a tray/platter/flat container [pan/sheet/griddle] of contents x2, and " &
        "made of material x3",
  ),
  EntryGismuEnglish(
    word: "palta",
    keyword: "plate",
    hint: "'platter'",
    definition: "x1 is a plate/dish/platter/saucer [flat/mildly concave food service bed] made " &
        "of material x2",
  ),
  EntryGismuEnglish(
    word: "pambe",
    keyword: "pump",
    hint: "",
    definition: "x1 is a pump/injector [tool/apparatus] pumping/inserting fluid x2 to x3 from x4 " &
        "by means x5",
  ),
  EntryGismuEnglish(
    word: "panci",
    keyword: "odor",
    hint: "'fragrance'",
    definition: "x1 is an odor/fragrance/scent/smell emitted by x2 and detected by " &
        "observer/sensor x3",
  ),
  EntryGismuEnglish(
    word: "pandi",
    keyword: "punctuate",
    hint: "",
    definition: "x1 (agent) punctuates x2 (expression) with symbol/word x3 with " &
        "syntactic/semantic effect x4",
  ),
  EntryGismuEnglish(
    word: "panje",
    keyword: "sponge",
    hint: "",
    definition: "x1 is a quantity of/contains/is made of sponge/porous material",
  ),
  EntryGismuEnglish(
    word: "panka",
    keyword: "park",
    hint: "",
    definition: "x1 is a park/land reserve managed by community/polity/company x2 for purpose x3",
  ),
  EntryGismuEnglish(
    word: "panlo",
    keyword: "slice",
    hint: "",
    definition: "x1 is a slice [thin flat portion] of x2 (mass)",
  ),
  EntryGismuEnglish(
    word: "panpi",
    keyword: "peace",
    hint: "",
    definition: "x1 is at peace with x2",
  ),
  EntryGismuEnglish(
    word: "panra",
    keyword: "parallel",
    hint: "",
    definition: "x1 parallels x2 differing only in property x3 (ka; jo'u/fa'u term) by " &
        "standard/geometry x4",
  ),
  EntryGismuEnglish(
    word: "pante",
    keyword: "protest",
    hint: "",
    definition: "x1 protests/objects to/complains about x2 (event/state) to audience x3 with " &
        "action x4",
  ),
  EntryGismuEnglish(
    word: "panzi",
    keyword: "offspring",
    hint: "",
    definition: "x1 is a [biological] offspring/child/kid/hybrid of parent(s) x2; (adjective:) " &
        "x1 is filial",
  ),
  EntryGismuEnglish(
    word: "papri",
    keyword: "page",
    hint: "'paper'",
    definition: "x1 is a [physical] page/leaf of book/document/bound mass of pages x2",
  ),
  EntryGismuEnglish(
    word: "parbi",
    keyword: "ratio",
    hint: "'rate'",
    definition: "x1 (me'o, fraction) is a ratio/rate of x2 (quantity) with respect to x3 " &
        "(quantity), [x2:x3]",
  ),
  EntryGismuEnglish(
    word: "pastu",
    keyword: "robe",
    hint: "'tunic'",
    definition: "x1 is a robe/tunic/gown/cloak/dress/[coveralls] [a long/full body garment] of " &
        "material x2",
  ),
  EntryGismuEnglish(
    word: "patfu",
    keyword: "father",
    hint: "'pop, padre'",
    definition: "x1 is a father of x2; x1 begets/sires/acts paternal towards x2; [not " &
        "necessarily biological]",
  ),
  EntryGismuEnglish(
    word: "patlu",
    keyword: "potato",
    hint: "",
    definition: "x1 is a potato [an edible tuber] of variety/cultivar x2",
  ),
  EntryGismuEnglish(
    word: "patxu",
    keyword: "pot",
    hint: "",
    definition: "x1 is a pot/kettle/urn/tub/sink, a deep container for contents x2, of " &
        "material/properties x3",
  ),
  EntryGismuEnglish(
    word: "pe'a",
    keyword: "figurative",
    hint: "",
    definition: "marks figurative usage (non-literal) speech/text as a rafsi",
  ),
  EntryGismuEnglish(
    word: "pelji",
    keyword: "paper",
    hint: "'page'",
    definition: "x1 is paper from source x2",
  ),
  EntryGismuEnglish(
    word: "pelxu",
    keyword: "yellow",
    hint: "",
    definition: "x1 is yellow/golden [color adjective]",
  ),
  EntryGismuEnglish(
    word: "pemci",
    keyword: "poem",
    hint: "",
    definition: "x1 is a poem/verse about plot/theme/subject/pattern x2 by author x3 for " &
        "intended audience x4",
  ),
  EntryGismuEnglish(
    word: "penbi",
    keyword: "pen",
    hint: "",
    definition: "x1 is a pen using ink x2 applied by process x3",
  ),
  EntryGismuEnglish(
    word: "pencu",
    keyword: "touch",
    hint: "",
    definition: "x1 (agent) touches x2 with x3 [a locus on x1 or an instrument] at x4 [a locus " &
        "on x2]",
  ),
  EntryGismuEnglish(
    word: "pendo",
    keyword: "friend",
    hint: "",
    definition: "x1 is/acts as a friend of/to x2 (experiencer); x2 befriends x1",
  ),
  EntryGismuEnglish(
    word: "penmi",
    keyword: "meet",
    hint: "",
    definition: "x1 meets/encounters x2 at/in location x3",
  ),
  EntryGismuEnglish(
    word: "pensi",
    keyword: "think",
    hint: "'pensive'",
    definition: "x1 thinks/considers/cogitates/reasons/is pensive about/reflects upon " &
        "subject/concept x2",
  ),
  EntryGismuEnglish(
    word: "perli",
    keyword: "pear",
    hint: "",
    definition: "x1 is a pear [fruit] of species/strain x2",
  ),
  EntryGismuEnglish(
    word: "pesxu",
    keyword: "paste",
    hint: "",
    definition: "x1 is paste/pulp/dough/mash/mud/slurry [soft, smooth-textured, moist solid] of " &
        "composition x2",
  ),
  EntryGismuEnglish(
    word: "petso",
    keyword: "1E15",
    hint: "metric 'peta'",
    definition: "x1 is 1x10**15 of x2 in dimension/aspect x3 (default is units)",
  ),
  EntryGismuEnglish(
    word: "pezli",
    keyword: "leaf",
    hint: "",
    definition: "x1 is a leaf of plant x2; x1 is foliage of x2",
  ),
  EntryGismuEnglish(
    word: "pi",
    keyword: "decimal point",
    hint: "",
    definition: "digit/number: base point; default decimal",
  ),
  EntryGismuEnglish(
    word: "pi'u",
    keyword: "cross product",
    hint: "",
    definition: "non-logical connective: cross product; Cartesian product of sets",
  ),
  EntryGismuEnglish(
    word: "picti",
    keyword: "1E-12",
    hint: "metric 'pico'",
    definition: "x1 is a trillionth [1x10**-12] of x2 in dimension/aspect x3 (default is units)",
  ),
  EntryGismuEnglish(
    word: "pijne",
    keyword: "pin",
    hint: "",
    definition: "x1 is a pin/peg (needle-shaped tool) for fastening to/piercing x2, of " &
        "material/properties x3",
  ),
  EntryGismuEnglish(
    word: "pikci",
    keyword: "beg",
    hint: "'supplicate'",
    definition: "x1 begs/pleads/supplicates/entreats/implores/beseeches/prays [asks with " &
        "humility] x2 for x3",
  ),
  EntryGismuEnglish(
    word: "pikta",
    keyword: "ticket",
    hint: "",
    definition: "x1 is a ticket entitling x2 to entitlement/privilege x3 (event/state) under " &
        "conditions x4",
  ),
  EntryGismuEnglish(
    word: "pilji",
    keyword: "multiply",
    hint: "'multiply'",
    definition: "x1 is the product/total/result of factors/multiplicands (x2 and x3) x2 " &
        "multiplied by x3",
  ),
  EntryGismuEnglish(
    word: "pilka",
    keyword: "crust",
    hint: "'peel'",
    definition: "x1 is a crust/rind/peel/skin/hide/outer cover of x2",
  ),
  EntryGismuEnglish(
    word: "pilno",
    keyword: "use",
    hint: "'employ'",
    definition: "x1 uses/employs x2 [tool, apparatus, machine, agent, acting entity, material] " &
        "for purpose x3",
  ),
  EntryGismuEnglish(
    word: "pimlu",
    keyword: "feather",
    hint: "'plume'",
    definition: "x1 is a/the feather/plume(s)/plumage [body-part] of animal/species x2",
  ),
  EntryGismuEnglish(
    word: "pinca",
    keyword: "urine",
    hint: "'piss'",
    definition: "x1 is a/the urine/piss/pee of x2",
  ),
  EntryGismuEnglish(
    word: "pindi",
    keyword: "poor",
    hint: "'indigent'",
    definition: "x1 is poor/indigent/impoverished/lacking in goods/possessions/property x2",
  ),
  EntryGismuEnglish(
    word: "pinfu",
    keyword: "prisoner",
    hint: "'captive'",
    definition: "x1 is a prisoner/captive of x2, restrained/held/confined by means/force x3",
  ),
  EntryGismuEnglish(
    word: "pinji",
    keyword: "penis",
    hint: "",
    definition: "x1 is a/the clitoris/penis [projecting reproductive organ; body-part] of x2",
  ),
  EntryGismuEnglish(
    word: "pinka",
    keyword: "comment",
    hint: "",
    definition: "x1 (text) is a comment/remark/observation about subject x2 expressed by x3 to " &
        "audience x4",
  ),
  EntryGismuEnglish(
    word: "pinsi",
    keyword: "pencil",
    hint: "",
    definition: "x1 is a pencil/crayon/stylus applying lead/marking material x2, frame/support " &
        "[of material] x3",
  ),
  EntryGismuEnglish(
    word: "pinta",
    keyword: "level",
    hint: "'horizontal'",
    definition: "x1 is flat/level/horizontal in gravity/frame of reference x2",
  ),
  EntryGismuEnglish(
    word: "pinxe",
    keyword: "drink",
    hint: "",
    definition: "x1 (agent) drinks/imbibes beverage/drink/liquid refreshment x2 from/out-of " &
        "container/source x3",
  ),
  EntryGismuEnglish(
    word: "pipno",
    keyword: "piano",
    hint: "",
    definition: "x1 is a piano/harpsichord/synthesizer/organ; a keyboard musical instrument",
  ),
  EntryGismuEnglish(
    word: "pixra",
    keyword: "picture",
    hint: "",
    definition: "x1 is a picture/illustration representing/showing x2, made by artist x3 in " &
        "medium x4",
  ),
  EntryGismuEnglish(
    word: "plana",
    keyword: "plump",
    hint: "",
    definition: "x1 is plump/fat/obese [excessively thick/bulbous/swollen] by standard x2",
  ),
  EntryGismuEnglish(
    word: "platu",
    keyword: "plan",
    hint: "'plot'",
    definition: "x1 (agent) plans/designs/plots plan/arrangement/plot/[schematic] x2 for " &
        "state/process x3",
  ),
  EntryGismuEnglish(
    word: "pleji",
    keyword: "pay",
    hint: "",
    definition: "x1 pays/compensates/remunerates/[rewards] payment x2 to recipient/payee x3 for " &
        "goods/services x4",
  ),
  EntryGismuEnglish(
    word: "plibu",
    keyword: "pubic",
    hint: "",
    definition: "x1 is a/the pubic area/external genitalia [body-part] of x2",
  ),
  EntryGismuEnglish(
    word: "plini",
    keyword: "planet",
    hint: "",
    definition: "x1 is a planet revolving around x2 with planetary characteristics x3, orbital " &
        "parameters x4",
  ),
  EntryGismuEnglish(
    word: "plipe",
    keyword: "leap",
    hint: "",
    definition: "x1 (agent/object) leaps/jumps/springs/bounds to x2 from x3 reaching height x4 " &
        "propelled by x5",
  ),
  EntryGismuEnglish(
    word: "plise",
    keyword: "apple",
    hint: "",
    definition: "x1 is an apple [fruit] of species/strain x2",
  ),
  EntryGismuEnglish(
    word: "plita",
    keyword: "plane",
    hint: "",
    definition: "x1 is a plane [2-dimensional shape/form] defined by points x2 (set); x1 is " &
        "flat/[smooth]",
  ),
  EntryGismuEnglish(
    word: "plixa",
    keyword: "plow",
    hint: "",
    definition: "x1 (agent) plows/furrows/tills [cuts into and turns up] x2 with tool x3 " &
        "propelled by x4",
  ),
  EntryGismuEnglish(
    word: "pluja",
    keyword: "complicated",
    hint: "'complex'",
    definition: "x1 is complex/complicated/involved in aspect/property x2 (ka) by standard x3",
  ),
  EntryGismuEnglish(
    word: "pluka",
    keyword: "pleasant",
    hint: "",
    definition: "x1 (event/state) seems pleasant to/pleases x2 under conditions x3",
  ),
  EntryGismuEnglish(
    word: "pluta",
    keyword: "route",
    hint: "",
    definition: "x1 is a route/path/way/course/track to x2 from x3 via/defined by points " &
        "including x4 (set)",
  ),
  EntryGismuEnglish(
    word: "polje",
    keyword: "fold",
    hint: "",
    definition: "x1 (force) folds/creases x2 at locus/loci/forming crease(s)/bend(s) x3",
  ),
  EntryGismuEnglish(
    word: "polno",
    keyword: "Polynesian",
    hint: "",
    definition: "x1 reflects Polynesian/Oceanian (geographic region) " &
        "culture/nationality/languages in aspect x2",
  ),
  EntryGismuEnglish(
    word: "ponjo",
    keyword: "Japanese",
    hint: "'Nippon'",
    definition: "x1 reflects Japanese culture/nationality/language in aspect x2",
  ),
  EntryGismuEnglish(
    word: "ponse",
    keyword: "possess",
    hint: "",
    definition: "x1 possesses/owns/has x2 under law/custom x3; x1 is owner/proprietor of x2 " &
        "under x3",
  ),
  EntryGismuEnglish(
    word: "porpi",
    keyword: "break",
    hint: "",
    definition: "x1 breaks/fractures/shatters/[splits/splinters/cracks] into pieces x2",
  ),
  EntryGismuEnglish(
    word: "porsi",
    keyword: "sequence",
    hint: "",
    definition: "x1 [ordered set] is sequenced/ordered/listed by comparison/rules x2 on " &
        "unordered set x3",
  ),
  EntryGismuEnglish(
    word: "porto",
    keyword: "Portuguese",
    hint: "",
    definition: "x1 reflects Portuguese culture/nationality/language in aspect x2",
  ),
  EntryGismuEnglish(
    word: "prali",
    keyword: "profit",
    hint: "",
    definition: "x1 is a profit/gain/benefit/advantage to x2 accruing/resulting from " &
        "activity/process x3",
  ),
  EntryGismuEnglish(
    word: "prami",
    keyword: "love",
    hint: "",
    definition: "x1 loves/feels strong affectionate devotion towards x2 (object/state)",
  ),
  EntryGismuEnglish(
    word: "prane",
    keyword: "perfect",
    hint: "",
    definition: "x1 is perfect/ideal/archetypical/faultless/flawless/un-improvable in " &
        "property/aspect x2 (ka)",
  ),
  EntryGismuEnglish(
    word: "preja",
    keyword: "spread",
    hint: "",
    definition: "x1 spreads/expands over/into x2 from initial state x3",
  ),
  EntryGismuEnglish(
    word: "prenu",
    keyword: "person",
    hint: "",
    definition: "x1 is a person/people (noun) [not necessarily human]; x1 displays personality/a " &
        "persona",
  ),
  EntryGismuEnglish(
    word: "preti",
    keyword: "question",
    hint: "'query'",
    definition: "x1 (quoted text) is a question/query about subject x2 by questioner x3 to " &
        "audience x4",
  ),
  EntryGismuEnglish(
    word: "prije",
    keyword: "wise",
    hint: "'sage'",
    definition: "x1 is wise/sage about matter x2 (abstraction) to observer x3",
  ),
  EntryGismuEnglish(
    word: "prina",
    keyword: "print",
    hint: "",
    definition: "x1 is a print/impression/image on/in surface x2 of/made by/using " &
        "tool/press/implement/object x3",
  ),
  EntryGismuEnglish(
    word: "pritu",
    keyword: "right",
    hint: "",
    definition: "x1 is to the right/right-hand side of x2 which faces/in-frame-of-reference x3",
  ),
  EntryGismuEnglish(
    word: "prosa",
    keyword: "prose",
    hint: "",
    definition: "x1 is prose about plot/theme/subject x2 by author x3 for intended audience x4",
  ),
  EntryGismuEnglish(
    word: "pruce",
    keyword: "process",
    hint: "",
    definition: "x1 is a process with inputs x2, outputs/results x3, passing through " &
        "steps/stages x4",
  ),
  EntryGismuEnglish(
    word: "pruni",
    keyword: "elastic",
    hint: "'springy'",
    definition: "(adjective:) x1 is elastic/springy",
  ),
  EntryGismuEnglish(
    word: "pruxi",
    keyword: "spirit",
    hint: "",
    definition: "x1 is spiritual/pertains to the soul in nature [either energy or being]; x1 is " &
        "ghostly/ethereal",
  ),
  EntryGismuEnglish(
    word: "pu'i",
    keyword: "can and has",
    hint: "",
    definition: "modal aspect: can and has; demonstrated potential",
  ),
  EntryGismuEnglish(
    word: "pu'u",
    keyword: "process abstract",
    hint: "",
    definition: "abstractor: process (event) abstractor; x1 is process of [bridi] proceeding in " &
        "stages x2",
  ),
  EntryGismuEnglish(
    word: "pulce",
    keyword: "dust",
    hint: "'pulverized'",
    definition: "x1 is dust/precipitate [suspensible solid] from x2 in medium/on surface x3",
  ),
  EntryGismuEnglish(
    word: "pulji",
    keyword: "police",
    hint: "",
    definition: "x1 is a police officer/[enforcer/vigilante] enforcing law(s)/rule(s)/order x2",
  ),
  EntryGismuEnglish(
    word: "pulni",
    keyword: "pulley",
    hint: "",
    definition: "x1 is a pulley [tool] for performing action/function x2 rotating on axle x3",
  ),
  EntryGismuEnglish(
    word: "punji",
    keyword: "put",
    hint: "",
    definition: "x1 (agent) puts/places/sets x2 on/at surface/locus x3",
  ),
  EntryGismuEnglish(
    word: "punli",
    keyword: "swelling",
    hint: "",
    definition: "x1 is a swelling/protrusion/convexity [shape/form] at/in/on x2, of material x3",
  ),
  EntryGismuEnglish(
    word: "purci",
    keyword: "past",
    hint: "'earlier'",
    definition: "x1 is in the past of/earlier than/before x2 in time sequence; x1 is former; x2 " &
        "is latter",
  ),
  EntryGismuEnglish(
    word: "purdi",
    keyword: "garden",
    hint: "",
    definition: "x1 is a garden/tended/cultivated field of family/community/farmer x2 growing " &
        "plants/crop x3",
  ),
  EntryGismuEnglish(
    word: "purmo",
    keyword: "powder",
    hint: "",
    definition: "x1 is a powder of material x2",
  ),
  EntryGismuEnglish(
    word: "racli",
    keyword: "sane",
    hint: "'rational'",
    definition: "x1 (action/activity/behavior) is sane/rational by standard x2",
  ),
  EntryGismuEnglish(
    word: "ractu",
    keyword: "rabbit",
    hint: "",
    definition: "x1 is a rabbit/hare/[doe] of species/breed x2",
  ),
  EntryGismuEnglish(
    word: "radno",
    keyword: "radian",
    hint: "",
    definition: "x1 is x2 radian(s) [metric unit] in angular measure (default is 1) by standard x3",
  ),
  EntryGismuEnglish(
    word: "rafsi",
    keyword: "affix",
    hint: "",
    definition: "x1 is an affix/suffix/prefix/combining-form for word/concept x2, " &
        "form/properties x3, language x4",
  ),
  EntryGismuEnglish(
    word: "ragve",
    keyword: "across",
    hint: "",
    definition: "x1 is located across/on the other side of gap/boundary x2 from x3; x1 is " &
        "opposite (fi) x3",
  ),
  EntryGismuEnglish(
    word: "rakso",
    keyword: "Iraqi",
    hint: "",
    definition: "x1 reflects Iraqi culture/nationality in aspect x2",
  ),
  EntryGismuEnglish(
    word: "raktu",
    keyword: "trouble",
    hint: "",
    definition: "x1 (object/person/event/situation) troubles/disturbs x2 (person) causing " &
        "problem(s) x3",
  ),
  EntryGismuEnglish(
    word: "ralci",
    keyword: "delicate",
    hint: "'fragile'",
    definition: "x1 is delicate/fragile/subtle/refined in property x2 (ka)",
  ),
  EntryGismuEnglish(
    word: "ralju",
    keyword: "principal",
    hint: "",
    definition: "x1 is principal/chief/leader/main/[staple], most significant among x2 (set) in " &
        "property x3 (ka)",
  ),
  EntryGismuEnglish(
    word: "ralte",
    keyword: "retain",
    hint: "",
    definition: "x1 retains/keeps/holds x2 in its possession",
  ),
  EntryGismuEnglish(
    word: "randa",
    keyword: "yield",
    hint: "'surrender'",
    definition: "x1 yields/gives way/surrenders to x2 (force/agent) under conditions x3",
  ),
  EntryGismuEnglish(
    word: "rango",
    keyword: "organ",
    hint: "",
    definition: "x1 is a/the body organ [body-part] of body/species x2 performing function x3",
  ),
  EntryGismuEnglish(
    word: "ranji",
    keyword: "continue",
    hint: "",
    definition: "x1 (event/state) continues/persists over interval x2; x1 (property - ka) is " &
        "continuous over x2",
  ),
  EntryGismuEnglish(
    word: "ranmi",
    keyword: "myth",
    hint: "",
    definition: "x1 is a myth/legend, a culturally significant story about x2 in mythos x3 of " &
        "culture x4",
  ),
  EntryGismuEnglish(
    word: "ransu",
    keyword: "bronze",
    hint: "",
    definition: "x1 is a quantity of/contains/is made of bronze of composition including x2",
  ),
  EntryGismuEnglish(
    word: "ranti",
    keyword: "soft",
    hint: "",
    definition: "x1 is soft/malleable/moldable/yielding to force x2 in conditions x3",
  ),
  EntryGismuEnglish(
    word: "ranxi",
    keyword: "irony",
    hint: "",
    definition: "x1 is ironic(al)/contrary to expectation x2 in state/property/aspect x3",
  ),
  EntryGismuEnglish(
    word: "rapli",
    keyword: "repeat",
    hint: "",
    definition: "x1 [action] repeats/is repeated for a total of x2 (quantity) occurrences",
  ),
  EntryGismuEnglish(
    word: "rarna",
    keyword: "natural",
    hint: "",
    definition: "x1 is natural/spontaneous/instinctive, not [consciously] caused by person(s)",
  ),
  EntryGismuEnglish(
    word: "ratcu",
    keyword: "rat",
    hint: "",
    definition: "x1 is a rat of species/breed x2",
  ),
  EntryGismuEnglish(
    word: "ratni",
    keyword: "atom",
    hint: "",
    definition: "x1 is an atom of element/atomic number x2 of isotope number/atomic weight x3",
  ),
  EntryGismuEnglish(
    word: "re",
    keyword: "2",
    hint: "",
    definition: "digit/number: 2 (digit)",
  ),
  EntryGismuEnglish(
    word: "rebla",
    keyword: "tail",
    hint: "",
    definition: "x1 is a/the tail/appendix [body-part] of x2; [metaphor: trailing, following " &
        "portion/appendage]",
  ),
  EntryGismuEnglish(
    word: "rectu",
    keyword: "meat",
    hint: "'flesh'",
    definition: "x1 is a quantity of/contains meat/flesh from source/animal x2",
  ),
  EntryGismuEnglish(
    word: "remna",
    keyword: "human",
    hint: "",
    definition: "x1 is a human/human being/man (non-specific gender-free sense); (adjective:) x1 " &
        "is human",
  ),
  EntryGismuEnglish(
    word: "renro",
    keyword: "throw",
    hint: "",
    definition: "x1 throws/launches/casts/hurls x2 to/at/in direction x3 (propulsion derives " &
        "internally to x1)",
  ),
  EntryGismuEnglish(
    word: "renvi",
    keyword: "survive",
    hint: "",
    definition: "x1 survives/endures/undergoes/abides/lasts/persists through x2 for " &
        "interval/duration x3",
  ),
  EntryGismuEnglish(
    word: "respa",
    keyword: "reptile",
    hint: "",
    definition: "x1 is a reptile of species/breed x2",
  ),
  EntryGismuEnglish(
    word: "ricfu",
    keyword: "rich",
    hint: "",
    definition: "x1 is rich/wealthy in goods/possessions/property/aspect x2",
  ),
  EntryGismuEnglish(
    word: "rigni",
    keyword: "disgusting",
    hint: "'repugnant'",
    definition: "x1 is repugnant to/causes disgust to x2 under conditions x3",
  ),
  EntryGismuEnglish(
    word: "rijno",
    keyword: "silver",
    hint: "'argent'",
    definition: "x1 is made of/contains/is a quantity of silver/argentum (Ag); [metaphor: " &
        "valuable, tarnishing]",
  ),
  EntryGismuEnglish(
    word: "rilti",
    keyword: "rhythm",
    hint: "",
    definition: "x1 (sequence/non-text quote) is a rhythm/beat of music/expressive form x2",
  ),
  EntryGismuEnglish(
    word: "rimni",
    keyword: "rhyme",
    hint: "",
    definition: "x1 rhymes/alliterates with x2 in language/phonetics x3, matching sound " &
        "correspondence x4 (ka)",
  ),
  EntryGismuEnglish(
    word: "rinci",
    keyword: "drain",
    hint: "",
    definition: "x1 liquid/fluid drains/strains/flushes from source x2 through drain/strainer x3 " &
        "by force x4",
  ),
  EntryGismuEnglish(
    word: "rinju",
    keyword: "restrain",
    hint: "",
    definition: "x1 is restrained/held [back]/constrained/kept by restraint x2 against x3 (event)",
  ),
  EntryGismuEnglish(
    word: "rinka",
    keyword: "cause",
    hint: "",
    definition: "x1 (event/state) effects/physically causes effect x2 (event/state) under " &
        "conditions x3",
  ),
  EntryGismuEnglish(
    word: "rinsa",
    keyword: "greet",
    hint: "",
    definition: "x1 (agent) greets/hails/[welcomes/says hello to]/responds to arrival of x2 in " &
        "manner x3 (action)",
  ),
  EntryGismuEnglish(
    word: "rirci",
    keyword: "rare",
    hint: "",
    definition: "x1 [member] is rare/unusual/uncommon/atypical in property x2 (ka) among members " &
        "of x3 (set)",
  ),
  EntryGismuEnglish(
    word: "rirni",
    keyword: "parent",
    hint: "'rear'",
    definition: "x1 is a parent of/raises/rears x2; x1 mentors/acts parental toward " &
        "child/protege x2",
  ),
  EntryGismuEnglish(
    word: "rirxe",
    keyword: "river",
    hint: "",
    definition: "x1 is a river of land mass x2, draining watershed x3 into x4/terminating at x4",
  ),
  EntryGismuEnglish(
    word: "rismi",
    keyword: "rice",
    hint: "",
    definition: "x1 is a quantity of rice [a type of grain] of strain/cultivar x2",
  ),
  EntryGismuEnglish(
    word: "risna",
    keyword: "heart",
    hint: "'cardiac'",
    definition: "x1 is a/the heart [body-part] of x2; [emotional/shape metaphors are NOT " &
        "culturally neutral]",
  ),
  EntryGismuEnglish(
    word: "ritli",
    keyword: "rite",
    hint: "",
    definition: "x1 is a rite/ceremony/ritual for purpose/goal x2, by custom/in community x3, " &
        "with form/rules x4",
  ),
  EntryGismuEnglish(
    word: "rivbi",
    keyword: "avoid",
    hint: "'evade'",
    definition: "x1 avoids/evades/shuns/escapes/skirts [fate] x2 (event) through action/state x3 " &
        "(event)",
  ),
  EntryGismuEnglish(
    word: "ro",
    keyword: "each",
    hint: "",
    definition: "digit/number: each, all",
  ),
  EntryGismuEnglish(
    word: "roi",
    keyword: "quantified tense",
    hint: "",
    definition: "converts number to an objectively quantified tense interval modifier; defaults " &
        "to time tense",
  ),
  EntryGismuEnglish(
    word: "rokci",
    keyword: "rock",
    hint: "",
    definition: "x1 is a quantity of/is made of/contains rock/stone of type/composition x2 from " &
        "location x3",
  ),
  EntryGismuEnglish(
    word: "romge",
    keyword: "chrome",
    hint: "",
    definition: "x1 is a highly reflective/polished non-tarnishing metallic surface, of metal x2 " &
        "[often chromium]",
  ),
  EntryGismuEnglish(
    word: "ropno",
    keyword: "European",
    hint: "",
    definition: "x1 reflects European culture/nationality/geography/Indo-European languages in " &
        "aspect x2",
  ),
  EntryGismuEnglish(
    word: "rorci",
    keyword: "procreate",
    hint: "",
    definition: "x1 engenders/procreates/begets x2 with coparent x3",
  ),
  EntryGismuEnglish(
    word: "rotsu",
    keyword: "thick",
    hint: "'stout'",
    definition: "x1 is thick in dimension/direction x2 by standard x3; [relatively long in " &
        "smallest dimension]",
  ),
  EntryGismuEnglish(
    word: "rozgu",
    keyword: "rose",
    hint: "",
    definition: "x1 is a rose [flower - characterized by prickly stem/fragrance] of " &
        "species/strain x2",
  ),
  EntryGismuEnglish(
    word: "ruble",
    keyword: "weak",
    hint: "'feeble'",
    definition: "x1 is weak/feeble/frail in property/quality/aspect x2 (ka) by standard x3",
  ),
  EntryGismuEnglish(
    word: "rufsu",
    keyword: "rough",
    hint: "",
    definition: "x1 is rough/coarse/uneven/[grainy/scabrous/rugged] in texture/regularity",
  ),
  EntryGismuEnglish(
    word: "runme",
    keyword: "melt",
    hint: "'runny'",
    definition: "x1 melts [becomes liquid from solid state] at temperature x2 and pressure x3",
  ),
  EntryGismuEnglish(
    word: "runta",
    keyword: "dissolve",
    hint: "",
    definition: "x1 dissolves in solvent x2 forming solution/[suspension] x3 under conditions x4",
  ),
  EntryGismuEnglish(
    word: "rupnu",
    keyword: "dollar",
    hint: "'ruble'",
    definition: "x1 is measured in major-money-units (dollar/yuan/ruble) as x2 (quantity), " &
        "monetary system x3",
  ),
  EntryGismuEnglish(
    word: "rusko",
    keyword: "Russian",
    hint: "",
    definition: "x1 reflects Russian culture/nationality/language in aspect x2",
  ),
  EntryGismuEnglish(
    word: "rutni",
    keyword: "artifact",
    hint: "",
    definition: "x1 is an artifact; x1 is artificial; x1 is made/caused by people/se kulnu x2; " &
        "x1 is man-made",
  ),
  EntryGismuEnglish(
    word: "sabji",
    keyword: "provide",
    hint: "'supply'",
    definition: "x1 [source] provides/supplies/furnishes x2 [supply/commodity] to x3 [recipient]",
  ),
  EntryGismuEnglish(
    word: "sabnu",
    keyword: "cabin",
    hint: "",
    definition: "x1 is a cabin of vehicle x2",
  ),
  EntryGismuEnglish(
    word: "sacki",
    keyword: "match",
    hint: "",
    definition: "x1 is a match [incendiary device] made of x2",
  ),
  EntryGismuEnglish(
    word: "saclu",
    keyword: "decimal",
    hint: "",
    definition: "x1 (me'o) is the [decimal/binary] equivalent of fractional x2 (me'o) in base x3 " &
        "(quantity)",
  ),
  EntryGismuEnglish(
    word: "sadjo",
    keyword: "Saudi",
    hint: "",
    definition: "x1 reflects Saudi Arabian culture/nationality in aspect x2",
  ),
  EntryGismuEnglish(
    word: "sakci",
    keyword: "suck",
    hint: "",
    definition: "x1 sucks/is suction/vacuum/relatively low pressure of fluid/gas x2 relative to " &
        "high pressure x3",
  ),
  EntryGismuEnglish(
    word: "sakli",
    keyword: "slide",
    hint: "'slip'",
    definition: "x1 slides/slips/glides on x2",
  ),
  EntryGismuEnglish(
    word: "sakta",
    keyword: "sugar",
    hint: "'sucrose'",
    definition: "x1 is made of/contains/is a quantity of sugar [sweet edible] from source x2 of " &
        "composition x3",
  ),
  EntryGismuEnglish(
    word: "salci",
    keyword: "celebrate",
    hint: "",
    definition: "x1 celebrates/recognizes/honors x2 (event/abstract) with activity/[party] x3",
  ),
  EntryGismuEnglish(
    word: "salpo",
    keyword: "slope",
    hint: "",
    definition: "x1 is sloped/inclined/slanted/aslant with angle x2 to horizon/frame x3",
  ),
  EntryGismuEnglish(
    word: "salta",
    keyword: "salad",
    hint: "",
    definition: "x1 (mass) is a quantity of salad [food] with ingredients/components including x2",
  ),
  EntryGismuEnglish(
    word: "samcu",
    keyword: "cassava",
    hint: "'yam'",
    definition: "x1 is a quantity of cassava/taro/manioc/tapioca/yam [edible starchy root] of " &
        "species/strain x2",
  ),
  EntryGismuEnglish(
    word: "sampu",
    keyword: "simple",
    hint: "",
    definition: "x1 is simple/unmixed/uncomplicated in property x2 (ka)",
  ),
  EntryGismuEnglish(
    word: "sance",
    keyword: "sound",
    hint: "",
    definition: "x1 is sound produced/emitted by x2",
  ),
  EntryGismuEnglish(
    word: "sanga",
    keyword: "sing",
    hint: "",
    definition: "x1 sings/chants x2 [song/hymn/melody/melodic sounds] to audience x3",
  ),
  EntryGismuEnglish(
    word: "sanji",
    keyword: "conscious",
    hint: "",
    definition: "x1 is conscious/aware of x2 (object/abstract); x1 discerns/recognizes x2 " &
        "(object/abstract)",
  ),
  EntryGismuEnglish(
    word: "sanli",
    keyword: "stand",
    hint: "",
    definition: "x1 stands [is vertically oriented] on surface x2 supported by " &
        "limbs/support/pedestal x3",
  ),
  EntryGismuEnglish(
    word: "sanmi",
    keyword: "meal",
    hint: "",
    definition: "x1 (mass) is a meal composed of dishes including x2",
  ),
  EntryGismuEnglish(
    word: "sanso",
    keyword: "sauce",
    hint: "",
    definition: "x1 is a sauce/topping/gravy/frosting for use with x2, containing ingredient(s) " &
        "including x3",
  ),
  EntryGismuEnglish(
    word: "santa",
    keyword: "umbrella",
    hint: "",
    definition: "x1 is an umbrella/parasol shielding x2 from x3, made of material x4, supported " &
        "by x5",
  ),
  EntryGismuEnglish(
    word: "sarcu",
    keyword: "necessary",
    hint: "",
    definition: "x1 (abstract) is necessary/required for continuing state/process x2 under " &
        "conditions x3",
  ),
  EntryGismuEnglish(
    word: "sarji",
    keyword: "support",
    hint: "",
    definition: "x1 supports/holds up/is underpinning of/[helps] x2 against force/opposition x3 " &
        "with/by means x4",
  ),
  EntryGismuEnglish(
    word: "sarlu",
    keyword: "spiral",
    hint: "",
    definition: "x1 is a spiral/helix/whorl/[vortex] [shape/form] with limits x2, of " &
        "dimensionality x3",
  ),
  EntryGismuEnglish(
    word: "sarxe",
    keyword: "harmonious",
    hint: "",
    definition: "x1 is harmonious/concordant/in agreement/concord with x2 in property x3 (ka)",
  ),
  EntryGismuEnglish(
    word: "saske",
    keyword: "science",
    hint: "",
    definition: "x1 (mass of facts) is science of/about subject matter x2 based on methodology x3",
  ),
  EntryGismuEnglish(
    word: "satci",
    keyword: "exact",
    hint: "'precise'",
    definition: "x1 [measurement/match] is exact/precise to precision x2 in property/quantity x3 " &
        "(ka/ni)",
  ),
  EntryGismuEnglish(
    word: "satre",
    keyword: "stroke",
    hint: "",
    definition: "x1 (agent) strokes/rubs/pets x2 with x3",
  ),
  EntryGismuEnglish(
    word: "savru",
    keyword: "noise",
    hint: "'clamor'",
    definition: "x1 is a noise/din/clamor [sensory input without useful information] to x2 via " &
        "sensory channel x3",
  ),
  EntryGismuEnglish(
    word: "sazri",
    keyword: "operate",
    hint: "",
    definition: "x1 operates/drives/runs x2 [apparatus/machine] with " &
        "goal/objective/use/end/function x3",
  ),
  EntryGismuEnglish(
    word: "se",
    keyword: "2nd conversion",
    hint: "",
    definition: "2nd conversion; switch 1st/2nd places",
  ),
  EntryGismuEnglish(
    word: "sefta",
    keyword: "surface",
    hint: "",
    definition: "x1 is surface/face [bounded shape/form] of [higher-dimension] object x2, on " &
        "side x3, edges x4",
  ),
  EntryGismuEnglish(
    word: "selci",
    keyword: "cell",
    hint: "",
    definition: "x1 is a cell/atom/unit/molecule of x2; x1 is an indivisible, most basic subunit " &
        "of x2",
  ),
  EntryGismuEnglish(
    word: "selfu",
    keyword: "serve",
    hint: "",
    definition: "x1 (agent) serves x2 with service x3 (activity); x1 is a servant (noun) of x2 " &
        "performing x3",
  ),
  EntryGismuEnglish(
    word: "semto",
    keyword: "Semitic",
    hint: "",
    definition: "x1 reflects Semitic [metaphor: Middle-Eastern] language/culture/nationality in " &
        "aspect x2",
  ),
  EntryGismuEnglish(
    word: "senci",
    keyword: "sneeze",
    hint: "",
    definition: "x1 sneezes (intransitive verb)",
  ),
  EntryGismuEnglish(
    word: "senpi",
    keyword: "doubt",
    hint: "'skeptic'",
    definition: "x1 doubts/is dubious/doubtful/skeptical/questions that x2 (du'u) is true",
  ),
  EntryGismuEnglish(
    word: "senta",
    keyword: "layer",
    hint: "'stratum'",
    definition: "x1 is a layer/stratum [shape/form] of x2 [material] within " &
        "structure/continuum/composite x3",
  ),
  EntryGismuEnglish(
    word: "senva",
    keyword: "dream",
    hint: "'reverie'",
    definition: "x1 dreams about/that x2 (fact/idea/event/state); x2 is a dream/reverie of x1",
  ),
  EntryGismuEnglish(
    word: "sepli",
    keyword: "apart",
    hint: "'separate'",
    definition: "x1 is apart/separate from x2, separated by " &
        "partition/wall/gap/interval/separating medium x3",
  ),
  EntryGismuEnglish(
    word: "serti",
    keyword: "stairs",
    hint: "",
    definition: "x1 are stairs/stairway/steps for climbing structure x2 with steps x3",
  ),
  EntryGismuEnglish(
    word: "setca",
    keyword: "insert",
    hint: "",
    definition: "x1 (agent) inserts/interposes/puts/deposits x2 into interior x3/into " &
        "among/between members of x3",
  ),
  EntryGismuEnglish(
    word: "sevzi",
    keyword: "self",
    hint: "",
    definition: "x1 is a self/ego/id/identity-image of x2",
  ),
  EntryGismuEnglish(
    word: "sfani",
    keyword: "fly",
    hint: "",
    definition: "x1 is a fly [a small non-stinging flying insect] of species/breed x2",
  ),
  EntryGismuEnglish(
    word: "sfasa",
    keyword: "punish",
    hint: "'spank, castigate'",
    definition: "x1 (agent) punishes x2 for infraction x3 (event/state/action) with punishment " &
        "x4 (event/state)",
  ),
  EntryGismuEnglish(
    word: "sfofa",
    keyword: "sofa",
    hint: "",
    definition: "x1 is a sofa/couch (noun)",
  ),
  EntryGismuEnglish(
    word: "sfubu",
    keyword: "dive",
    hint: "'swoop'",
    definition: "x1 dives/swoops [manner of controlled falling] to x2 from x3",
  ),
  EntryGismuEnglish(
    word: "si'o",
    keyword: "concept abstract",
    hint: "",
    definition: "abstractor: idea/concept abstractor; x1 is x2's concept of [bridi]",
  ),
  EntryGismuEnglish(
    word: "siclu",
    keyword: "whistle",
    hint: "",
    definition: "x1 [sound source] whistles/makes whistling sound/note/tone/melody x2",
  ),
  EntryGismuEnglish(
    word: "sicni",
    keyword: "coin",
    hint: "'specie'",
    definition: "x1 is a coin/token/is specie issued by x2 having value x3 of composition " &
        "including x4",
  ),
  EntryGismuEnglish(
    word: "sidbo",
    keyword: "idea",
    hint: "",
    definition: "x1 (idea abstract) is an idea/concept/thought about x2 (object/abstract) by " &
        "thinker x3",
  ),
  EntryGismuEnglish(
    word: "sidju",
    keyword: "help",
    hint: "'aid'",
    definition: "x1 helps/assists/aids object/person x2 do/achieve/maintain event/activity x3",
  ),
  EntryGismuEnglish(
    word: "sigja",
    keyword: "cigar",
    hint: "",
    definition: "x1 is a cigar/cigarette/cigarillo made from tobacco/smokable substance x2 by x3",
  ),
  EntryGismuEnglish(
    word: "silka",
    keyword: "silk",
    hint: "",
    definition: "x1 is a quantity of/contains/is made of silk produced by x2",
  ),
  EntryGismuEnglish(
    word: "silna",
    keyword: "salt",
    hint: "",
    definition: "x1 is a portion/quantity of salt from source x2, of composition including x3",
  ),
  EntryGismuEnglish(
    word: "simlu",
    keyword: "seem",
    hint: "",
    definition: "x1 seems/appears to have property(ies) x2 to observer x3 under conditions x4",
  ),
  EntryGismuEnglish(
    word: "simsa",
    keyword: "similar",
    hint: "",
    definition: "x1 is similar/parallel to x2 in property/quantity x3 (ka/ni); x1 looks/appears " &
        "like x2",
  ),
  EntryGismuEnglish(
    word: "simxu",
    keyword: "mutual",
    hint: "",
    definition: "x1 (set) has members who mutually/reciprocally x2 (event [x1 should be " &
        "reflexive in 1+ sumti])",
  ),
  EntryGismuEnglish(
    word: "since",
    keyword: "snake",
    hint: "",
    definition: "x1 is a snake/serpent of species/breed x2",
  ),
  EntryGismuEnglish(
    word: "sinma",
    keyword: "esteem",
    hint: "",
    definition: "x1 esteems/respects/venerates/highly regards x2 [object of respect]",
  ),
  EntryGismuEnglish(
    word: "sinso",
    keyword: "sine",
    hint: "",
    definition: "x1 is the trigonometric sine of angle/arcsine x2",
  ),
  EntryGismuEnglish(
    word: "sinxa",
    keyword: "sign",
    hint: "",
    definition: "x1 is a sign/symbol/signal representing/referring/signifying/meaning x2 to " &
        "observer x3",
  ),
  EntryGismuEnglish(
    word: "sipna",
    keyword: "sleep",
    hint: "",
    definition: "x1 is asleep (adjective); x1 sleeps/is sleeping",
  ),
  EntryGismuEnglish(
    word: "sirji",
    keyword: "straight",
    hint: "",
    definition: "x1 is straight/direct/line segment/interval between x2 and x3; (adjective:)  x1 " &
        "is linear",
  ),
  EntryGismuEnglish(
    word: "sirxo",
    keyword: "Syrian",
    hint: "",
    definition: "x1 reflects Syrian culture/nationality in aspect x2",
  ),
  EntryGismuEnglish(
    word: "sisku",
    keyword: "seek",
    hint: "",
    definition: "x1 seeks/searches/looks for property x2 among set x3 (complete specification of " &
        "set)",
  ),
  EntryGismuEnglish(
    word: "sisti",
    keyword: "cease",
    hint: "",
    definition: "x1 [agent] ceases/stops/halts/ends activity/process/state x2 [not necessarily " &
        "completing it]",
  ),
  EntryGismuEnglish(
    word: "sitna",
    keyword: "cite",
    hint: "",
    definition: "x1 cites/quotes/refers to/makes reference to source x2 for " &
        "information/statement x3 (du'u)",
  ),
  EntryGismuEnglish(
    word: "sivni",
    keyword: "private",
    hint: "",
    definition: "x1 is private/personal/privy/[secret/confidential/confined] to x2; x1 is " &
        "not-public/hidden",
  ),
  EntryGismuEnglish(
    word: "skaci",
    keyword: "skirt",
    hint: "",
    definition: "x1 is a skirt/kilt/dress of material x2; x1 is skirted [garment open at the " &
        "bottom; not legged]",
  ),
  EntryGismuEnglish(
    word: "skami",
    keyword: "computer",
    hint: "",
    definition: "x1 is a computer for purpose x2",
  ),
  EntryGismuEnglish(
    word: "skapi",
    keyword: "pelt",
    hint: "'skin'",
    definition: "x1 is a pelt/skin/hide/leather from x2",
  ),
  EntryGismuEnglish(
    word: "skari",
    keyword: "color",
    hint: "",
    definition: "x1 is/appears to be of color/hue x2 as perceived/seen by x3 under conditions x4",
  ),
  EntryGismuEnglish(
    word: "skicu",
    keyword: "describe",
    hint: "",
    definition: "x1 tells about/describes x2 (object/event/state) to audience x3 with " &
        "description x4 (property)",
  ),
  EntryGismuEnglish(
    word: "skiji",
    keyword: "ski",
    hint: "",
    definition: "x1 is a ski/skid/skate/runner for surface (of material) x2 supporting " &
        "skier/skater/sled/cargo x3",
  ),
  EntryGismuEnglish(
    word: "skina",
    keyword: "cinema",
    hint: "",
    definition: "x1 is a cinema/movie/film about x2 [plot/theme/subject/activity], filmmaker x3, " &
        "for audience x4",
  ),
  EntryGismuEnglish(
    word: "skori",
    keyword: "cord",
    hint: "",
    definition: "x1 is cord/cable/rope/line/twine/cordage/woven strands of material x2",
  ),
  EntryGismuEnglish(
    word: "skoto",
    keyword: "Scottish",
    hint: "",
    definition: "x1 reflects Gaelic/Scottish culture/nationality/language in aspect x2",
  ),
  EntryGismuEnglish(
    word: "skuro",
    keyword: "groove",
    hint: "'furrow'",
    definition: "x1 is a groove/trench/furrow [shape/form] in object/surface x2",
  ),
  EntryGismuEnglish(
    word: "slabu",
    keyword: "familiar",
    hint: "",
    definition: "x1 is old/familiar/well-known to observer x2 in feature x3 (ka) by standard x4",
  ),
  EntryGismuEnglish(
    word: "slaka",
    keyword: "syllable",
    hint: "",
    definition: "x1 is a syllable in language x2",
  ),
  EntryGismuEnglish(
    word: "slami",
    keyword: "acid",
    hint: "",
    definition: "x1 is a quantity of/contains/is made of acid of composition x2; (adjective:) x1 " &
        "is acidic",
  ),
  EntryGismuEnglish(
    word: "slanu",
    keyword: "cylinder",
    hint: "",
    definition: "x1 is a cylinder [shape/form] of material x2",
  ),
  EntryGismuEnglish(
    word: "slari",
    keyword: "sour",
    hint: "",
    definition: "x1 is sour/tart to observer x2",
  ),
  EntryGismuEnglish(
    word: "slasi",
    keyword: "plastic",
    hint: "",
    definition: "x1 is a quantity of/is made of/contains plastic/polymer of type/component " &
        "unit(s) x2",
  ),
  EntryGismuEnglish(
    word: "sligu",
    keyword: "solid",
    hint: "",
    definition: "x1 is solid, of composition/material including x2, under conditions x3",
  ),
  EntryGismuEnglish(
    word: "slilu",
    keyword: "oscillate",
    hint: "",
    definition: "x1 oscillates at rate/frequency x2 through set/sequence-of-states x3 (complete " &
        "specification)",
  ),
  EntryGismuEnglish(
    word: "sliri",
    keyword: "sulfur",
    hint: "",
    definition: "x1 is a quantity of/contains/is made of sulfur/brimstone (S); [metaphor: foul " &
        "odor, volcanic]",
  ),
  EntryGismuEnglish(
    word: "slovo",
    keyword: "Slavic",
    hint: "",
    definition: "x1 reflects Slavic language/culture/ethos in aspect x2",
  ),
  EntryGismuEnglish(
    word: "sluji",
    keyword: "muscle",
    hint: "",
    definition: "x1 is a/the muscle [body-part] controlling x2, of body x3; [metaphor: tools of " &
        "physical power]",
  ),
  EntryGismuEnglish(
    word: "sluni",
    keyword: "onion",
    hint: "",
    definition: "x1 is a quantity of/contains onions/scallions of type/cultivar x2",
  ),
  EntryGismuEnglish(
    word: "smacu",
    keyword: "mouse",
    hint: "",
    definition: "x1 is a mouse of species/breed x2",
  ),
  EntryGismuEnglish(
    word: "smadi",
    keyword: "guess",
    hint: "'surmise'",
    definition: "x1 guesses/conjectures/surmises x2 (du'u) is true about subject x3; " &
        "[epistemology]",
  ),
  EntryGismuEnglish(
    word: "smaji",
    keyword: "quiet",
    hint: "'silent'",
    definition: "x1 (source) is quiet/silent/[still] at observation point x2 by standard x3",
  ),
  EntryGismuEnglish(
    word: "smani",
    keyword: "monkey",
    hint: "'simian'",
    definition: "x1 is a monkey/ape/simian/baboon/chimpanzee of species/breed x2",
  ),
  EntryGismuEnglish(
    word: "smoka",
    keyword: "sock",
    hint: "",
    definition: "x1 is a sock/stocking [flexible foot and lower leg garment] of material x2",
  ),
  EntryGismuEnglish(
    word: "smuci",
    keyword: "spoon",
    hint: "",
    definition: "x1 is a spoon/scoop (tool) for use x2, made of material x3",
  ),
  EntryGismuEnglish(
    word: "smuni",
    keyword: "meaning",
    hint: "",
    definition: "x1 is a meaning/interpretation of x2 recognized/seen/accepted by x3",
  ),
  EntryGismuEnglish(
    word: "snada",
    keyword: "succeed",
    hint: "'accomplish'",
    definition: "x1 [agent] succeeds in/achieves/completes/accomplishes x2 as a result of " &
        "effort/attempt/try x3",
  ),
  EntryGismuEnglish(
    word: "snanu",
    keyword: "south",
    hint: "",
    definition: "x1 is to the south/southern side of x2 according to frame of reference x3",
  ),
  EntryGismuEnglish(
    word: "snidu",
    keyword: "second",
    hint: "",
    definition: "x1 is x2 seconds in duration (default is 1 second) by standard x3",
  ),
  EntryGismuEnglish(
    word: "snime",
    keyword: "snow",
    hint: "",
    definition: "x1 is made of/contains/is a quantity/expanse of snow",
  ),
  EntryGismuEnglish(
    word: "snipa",
    keyword: "sticky",
    hint: "",
    definition: "x1 adheres/sticks to x2; (adjective:) x1 is sticky/gummy/adhesive",
  ),
  EntryGismuEnglish(
    word: "snuji",
    keyword: "sandwich",
    hint: "",
    definition: "x1 is a sandwich/layering [not restricted to food] of x2 sandwiched between x3",
  ),
  EntryGismuEnglish(
    word: "snura",
    keyword: "secure",
    hint: "",
    definition: "x1 is secure/safe from threat x2 (event)",
  ),
  EntryGismuEnglish(
    word: "snuti",
    keyword: "accidental",
    hint: "",
    definition: "x1 (event/state) is an accident/unintentional on the part of x2; x1 is an " &
        "accident",
  ),
  EntryGismuEnglish(
    word: "so",
    keyword: "9",
    hint: "",
    definition: "digit/number: 9 (digit)",
  ),
  EntryGismuEnglish(
    word: "so'a",
    keyword: "almost all",
    hint: "",
    definition: "digit/number: almost all (digit/number)",
  ),
  EntryGismuEnglish(
    word: "so'e",
    keyword: "most",
    hint: "",
    definition: "digit/number: most",
  ),
  EntryGismuEnglish(
    word: "so'i",
    keyword: "many",
    hint: "",
    definition: "digit/number: many",
  ),
  EntryGismuEnglish(
    word: "so'o",
    keyword: "several",
    hint: "",
    definition: "digit/number: several",
  ),
  EntryGismuEnglish(
    word: "so'u",
    keyword: "few",
    hint: "",
    definition: "digit/number: few",
  ),
  EntryGismuEnglish(
    word: "sobde",
    keyword: "soya",
    hint: "",
    definition: "x1 is a quantity of soya [grain/bean] of species/strain x2",
  ),
  EntryGismuEnglish(
    word: "sodna",
    keyword: "sodium",
    hint: "",
    definition: "x1 is a quantity of/contains/is made of alkali metal of type x2 [default sodium]",
  ),
  EntryGismuEnglish(
    word: "sodva",
    keyword: "soda",
    hint: "",
    definition: "x1 is made of/contains/is a quantity of a carbonated beverage/soda of " &
        "flavor/brand x2",
  ),
  EntryGismuEnglish(
    word: "softo",
    keyword: "Soviet",
    hint: "",
    definition: "x1 reflects Russian empire/USSR/ex-USSR (Soviet]/CIS culture/nationality in " &
        "aspect x2",
  ),
  EntryGismuEnglish(
    word: "solji",
    keyword: "gold",
    hint: "",
    definition: "x1 is a quantity of/contains/is made of gold (Au); [metaphor: valuable, heavy, " &
        "non-reactive]",
  ),
  EntryGismuEnglish(
    word: "solri",
    keyword: "solar",
    hint: "",
    definition: "x1 is the sun of home planet x2 (default Earth) of race x3; (adjective:) x1 is " &
        "solar",
  ),
  EntryGismuEnglish(
    word: "sombo",
    keyword: "sow",
    hint: "",
    definition: "x1 sows/plants x2 [crop/plants] at/in x3",
  ),
  EntryGismuEnglish(
    word: "sonci",
    keyword: "soldier",
    hint: "",
    definition: "x1 is a soldier/warrior/fighter of army x2",
  ),
  EntryGismuEnglish(
    word: "sorcu",
    keyword: "store",
    hint: "",
    definition: "x1 is a store/deposit/supply/reserve of materials/energy x2 in containment x3",
  ),
  EntryGismuEnglish(
    word: "sorgu",
    keyword: "sorghum",
    hint: "",
    definition: "x1 is a quantity of sorghum of species/strain x2",
  ),
  EntryGismuEnglish(
    word: "sovda",
    keyword: "egg",
    hint: "'ovum'",
    definition: "x1 is an egg/ovum/sperm/pollen/gamete of/from organism [mother/father] x2",
  ),
  EntryGismuEnglish(
    word: "spaji",
    keyword: "surprise",
    hint: "",
    definition: "x1 (event/action abstract) surprises/startles/is unexpected [and generally " &
        "sudden] to x2",
  ),
  EntryGismuEnglish(
    word: "spali",
    keyword: "polish",
    hint: "",
    definition: "x1 (agent) polishes object/surface x2 with polish x3, applied using tool x4",
  ),
  EntryGismuEnglish(
    word: "spano",
    keyword: "Spanish",
    hint: "",
    definition: "x1 reflects Spanish-speaking culture/nationality/language in aspect x2",
  ),
  EntryGismuEnglish(
    word: "spati",
    keyword: "plant",
    hint: "",
    definition: "x1 is a plant/herb/greenery of species/strain/cultivar x2",
  ),
  EntryGismuEnglish(
    word: "speni",
    keyword: "married",
    hint: "'spouse'",
    definition: "x1 is married to x2; x1 is a spouse of x2 under " &
        "law/custom/tradition/system/convention x3",
  ),
  EntryGismuEnglish(
    word: "spisa",
    keyword: "piece",
    hint: "",
    definition: "x1 [object/substance] is a piece/portion/lump/chunk/particle of x2 [substance]",
  ),
  EntryGismuEnglish(
    word: "spita",
    keyword: "hospital",
    hint: "",
    definition: "x1 is a hospital treating patient(s) x2 for condition/injuries/disease/illness x3",
  ),
  EntryGismuEnglish(
    word: "spofu",
    keyword: "broken",
    hint: "",
    definition: "x1 is broken/inoperable/broken down/non-utile/not usable for function x2",
  ),
  EntryGismuEnglish(
    word: "spoja",
    keyword: "explode",
    hint: "",
    definition: "x1 bursts/explodes/violently breaks up/decomposes/combusts into " &
        "pieces/energy/fragments x2",
  ),
  EntryGismuEnglish(
    word: "spuda",
    keyword: "reply",
    hint: "'respond'",
    definition: "x1 answers/replies to/responds to person/object/event/situation/stimulus x2 " &
        "with response x3",
  ),
  EntryGismuEnglish(
    word: "sputu",
    keyword: "spit",
    hint: "",
    definition: "x1 spits/expectorates x2 [predominantly liquid] from x3 to/onto x4",
  ),
  EntryGismuEnglish(
    word: "sraji",
    keyword: "vertical",
    hint: "'upright'",
    definition: "x1 is vertical/upright/erect/plumb/oriented straight up and down in reference " &
        "frame/gravity x2",
  ),
  EntryGismuEnglish(
    word: "sraku",
    keyword: "scratch",
    hint: "",
    definition: "x1 [abrasive/cutting/scratching object/implement] " &
        "scratches/[carves]/erodes/cuts [into] x2",
  ),
  EntryGismuEnglish(
    word: "sralo",
    keyword: "Australian",
    hint: "",
    definition: "x1 reflects Australian culture/nationality/geography/dialect in aspect x2",
  ),
  EntryGismuEnglish(
    word: "srana",
    keyword: "pertain",
    hint: "'concerns'",
    definition: "x1 pertains to/is germane/relevant to/concerns/is related/associated with/is " &
        "about x2",
  ),
  EntryGismuEnglish(
    word: "srasu",
    keyword: "grass",
    hint: "",
    definition: "x1 is a blade/expanse of grass of species x2",
  ),
  EntryGismuEnglish(
    word: "srera",
    keyword: "err",
    hint: "",
    definition: "x1 errs in doing/being/making mistake x2 (event), an error under conditions x3 " &
        "by standard x4",
  ),
  EntryGismuEnglish(
    word: "srito",
    keyword: "Sanskrit",
    hint: "",
    definition: "x1 reflects Sanskrit language/Sanskritic/Vedic culture/nationality in aspect x2",
  ),
  EntryGismuEnglish(
    word: "sruma",
    keyword: "assume",
    hint: "",
    definition: "x1 assumes/supposes that x2 (du'u) is true about subject x3; [epistemology]",
  ),
  EntryGismuEnglish(
    word: "sruri",
    keyword: "surround",
    hint: "",
    definition: "x1 encircles/encloses/is surrounding x2 in direction(s)/dimension(s)/plane x3",
  ),
  EntryGismuEnglish(
    word: "stace",
    keyword: "honest",
    hint: "",
    definition: "x1 is honest/open/truthfully revealing to/candid/frank with x2 about " &
        "matter/fact x3",
  ),
  EntryGismuEnglish(
    word: "stagi",
    keyword: "vegetable",
    hint: "'stalky'",
    definition: "x1 is the edible x2 portion of plant x3; x1 is a vegetable",
  ),
  EntryGismuEnglish(
    word: "staku",
    keyword: "ceramic",
    hint: "",
    definition: "x1 is a quantity of/contains/is made of ceramic made by x2, of composition x3, " &
        "in form/shape x4",
  ),
  EntryGismuEnglish(
    word: "stali",
    keyword: "remain",
    hint: "'stay'",
    definition: "x1 remains/stays at/abides/lasts with x2",
  ),
  EntryGismuEnglish(
    word: "stani",
    keyword: "stalk",
    hint: "",
    definition: "x1 is a/the stalk/stem/trunk [body-part] of plant/species x2; [metaphor: main " &
        "support]",
  ),
  EntryGismuEnglish(
    word: "stapa",
    keyword: "step",
    hint: "",
    definition: "x1 steps/treads on/in surface x2 using limbs x3",
  ),
  EntryGismuEnglish(
    word: "stasu",
    keyword: "soup",
    hint: "'stew'",
    definition: "x1 is a quantity of soup/stew/olla/olio [food] of ingredients including x2",
  ),
  EntryGismuEnglish(
    word: "stati",
    keyword: "talent",
    hint: "",
    definition: "x1 has a talent/aptitude/innate skill for doing/being x2",
  ),
  EntryGismuEnglish(
    word: "steba",
    keyword: "frustration",
    hint: "",
    definition: "x1 feels frustration about x2 (abstraction)",
  ),
  EntryGismuEnglish(
    word: "steci",
    keyword: "specific",
    hint: "'special'",
    definition: "x1 (ka) is specific/particular/specialized/[special]/a defining property of x2 " &
        "among x3 (set)",
  ),
  EntryGismuEnglish(
    word: "stedu",
    keyword: "head",
    hint: "",
    definition: "x1 is a/the head [body-part] of x2; [metaphor: uppermost portion]",
  ),
  EntryGismuEnglish(
    word: "stela",
    keyword: "lock",
    hint: "",
    definition: "x1 is a lock/seal of/on/for sealing x2 with/by locking mechanism x3",
  ),
  EntryGismuEnglish(
    word: "stero",
    keyword: "steradian",
    hint: "",
    definition: "x1 is x2 steradian(s) [metric unit] in solid angle (default is 1) by standard x3",
  ),
  EntryGismuEnglish(
    word: "stici",
    keyword: "west",
    hint: "",
    definition: "x1 is to the west/western side of x2 according to frame of reference x3",
  ),
  EntryGismuEnglish(
    word: "stidi",
    keyword: "suggest",
    hint: "",
    definition: "x1 (agent) suggests/proposes idea/action x2 to audience x3; x1 (event) inspires " &
        "x2 in/among x3",
  ),
  EntryGismuEnglish(
    word: "stika",
    keyword: "adjust",
    hint: "",
    definition: "x1 (event) adjusts/regulates/changes x2 (ka/ni) in amount/degree x3",
  ),
  EntryGismuEnglish(
    word: "stizu",
    keyword: "chair",
    hint: "'stool'",
    definition: "x1 is a chair/stool/seat/bench, a piece or portion of a piece of furniture " &
        "intended for sitting",
  ),
  EntryGismuEnglish(
    word: "stodi",
    keyword: "constant",
    hint: "'stable'",
    definition: "x1 is constant/invariant/unchanging in property x2 (ka) in response to " &
        "stimulus/conditions x3",
  ),
  EntryGismuEnglish(
    word: "stuna",
    keyword: "east",
    hint: "",
    definition: "x1 is to the east/eastern side of x2 according to frame of reference x3",
  ),
  EntryGismuEnglish(
    word: "stura",
    keyword: "structure",
    hint: "",
    definition: "x1 is a structure/arrangement/organization of x2 [set/system/complexity]",
  ),
  EntryGismuEnglish(
    word: "stuzi",
    keyword: "site",
    hint: "'position'",
    definition: "x1 is an inherent/inalienable site/place/position/situation/spot/location of x2 " &
        "(object/event)",
  ),
  EntryGismuEnglish(
    word: "su'e",
    keyword: "at most",
    hint: "",
    definition: "digit/number: at most (all); no more than",
  ),
  EntryGismuEnglish(
    word: "su'o",
    keyword: "at least",
    hint: "",
    definition: "digit/number: at least (some); no less than",
  ),
  EntryGismuEnglish(
    word: "su'u",
    keyword: "unspecif abstract",
    hint: "",
    definition: "abstractor: generalized abstractor (how); x1 is [bridi] as a non-specific " &
        "abstraction of type x2",
  ),
  EntryGismuEnglish(
    word: "sucta",
    keyword: "abstract",
    hint: "",
    definition: "x1 (si'o) is abstracted/generalized/idealized from x2 [something concrete] by " &
        "rules x3",
  ),
  EntryGismuEnglish(
    word: "sudga",
    keyword: "dry",
    hint: "",
    definition: "x1 is dry of liquid x2; (adjective:) x1 is arid",
  ),
  EntryGismuEnglish(
    word: "sufti",
    keyword: "hoof",
    hint: "",
    definition: "x1 is a/the hoof [body-part] of x2",
  ),
  EntryGismuEnglish(
    word: "suksa",
    keyword: "sudden",
    hint: "",
    definition: "x1 (event/state) is sudden/sharply changes at stage/point x2 in " &
        "process/property/function x3",
  ),
  EntryGismuEnglish(
    word: "sumji",
    keyword: "sum",
    hint: "",
    definition: "x1 is a mathematical sum/result/total of x2 plus/increased by x3",
  ),
  EntryGismuEnglish(
    word: "sumne",
    keyword: "smell",
    hint: "",
    definition: "x1 (experiencer) smells/scents (transitive verb) x2; x2 smells/has odor/scent " &
        "to observer x1",
  ),
  EntryGismuEnglish(
    word: "sumti",
    keyword: "argument",
    hint: "",
    definition: "x1 is a/the argument of predicate/function x2 filling place x3 (kind/number)",
  ),
  EntryGismuEnglish(
    word: "sunga",
    keyword: "garlic",
    hint: "",
    definition: "x1 is a quantity of garlic [bulb] of species/strain x2",
  ),
  EntryGismuEnglish(
    word: "sunla",
    keyword: "wool",
    hint: "",
    definition: "x1 is a quantity of/made from/consists of wool [tight curly hair] from " &
        "animal/species/source x2",
  ),
  EntryGismuEnglish(
    word: "surla",
    keyword: "relax",
    hint: "",
    definition: "x1 relaxes/rests/is at ease in/by doing/being x2 (activity)",
  ),
  EntryGismuEnglish(
    word: "sutra",
    keyword: "fast",
    hint: "'swift'",
    definition: "x1 is fast/swift/quick/hastes/rapid at doing/being/bringing about x2 " &
        "(event/state)",
  ),
  EntryGismuEnglish(
    word: "ta",
    keyword: "that there",
    hint: "",
    definition: "pro-sumti: that there; nearby demonstrative it; indicated thing/place near " &
        "listener",
  ),
  EntryGismuEnglish(
    word: "tabno",
    keyword: "carbon",
    hint: "",
    definition: "x1 is a quantity of/contains/is made of carbon/graphite/[diamond]/charcoal; x1 " &
        "is organic",
  ),
  EntryGismuEnglish(
    word: "tabra",
    keyword: "trumpet",
    hint: "'brass'",
    definition: "x1 is a horn/trumpet/trombone/bugle [brass-wind/lip-reed musical instrument]",
  ),
  EntryGismuEnglish(
    word: "tadji",
    keyword: "method",
    hint: "",
    definition: "x1 [process] is a method/technique/approach/means for doing x2 (event) under " &
        "conditions x3",
  ),
  EntryGismuEnglish(
    word: "tadni",
    keyword: "study",
    hint: "",
    definition: "x1 studies/is a student of x2; x1 is a scholar; (adjective:) x1 is scholarly",
  ),
  EntryGismuEnglish(
    word: "tagji",
    keyword: "snug",
    hint: "'tight'",
    definition: "x1 is snug/tight on x2 in dimension/direction x3 at locus x4",
  ),
  EntryGismuEnglish(
    word: "talsa",
    keyword: "challenge",
    hint: "",
    definition: "x1 (person) challenges x2 at/in property x3",
  ),
  EntryGismuEnglish(
    word: "tamca",
    keyword: "tomato",
    hint: "",
    definition: "x1 is a tomato [fruit/vegetable/plant] of species/strain x2",
  ),
  EntryGismuEnglish(
    word: "tamji",
    keyword: "thumb",
    hint: "",
    definition: "x1 is a/the thumb/big toe [body-part] on limb x2 of x3; [metaphor based on " &
        "relative shape]",
  ),
  EntryGismuEnglish(
    word: "tamne",
    keyword: "cousin",
    hint: "",
    definition: "x1 is cousin to x2 by bond/tie x3; [non-immediate family member, default same " &
        "generation]",
  ),
  EntryGismuEnglish(
    word: "tanbo",
    keyword: "board",
    hint: "",
    definition: "x1 is a board/plank [3-dimensional long flat rectangle] of material x2",
  ),
  EntryGismuEnglish(
    word: "tance",
    keyword: "tongue",
    hint: "",
    definition: "x1 is a/the tongue [body-part] of x2; (metaphor: similar to nazbi, tamji, degji)",
  ),
  EntryGismuEnglish(
    word: "tanjo",
    keyword: "tangent",
    hint: "",
    definition: "x1 is the trigonometric tangent of angle/arctangent x2",
  ),
  EntryGismuEnglish(
    word: "tanko",
    keyword: "tobacco",
    hint: "",
    definition: "x1 is a quantity of tobacco [leaf] of species/strain x2",
  ),
  EntryGismuEnglish(
    word: "tanru",
    keyword: "phrase compound",
    hint: "",
    definition: "x1 is a binary metaphor formed with x2 modifying x3, giving meaning x4 in " &
        "usage/instance x5",
  ),
  EntryGismuEnglish(
    word: "tansi",
    keyword: "pan",
    hint: "",
    definition: "x1 is a pan/basin/tub/sink, a shallow container for contents x2, of " &
        "material/properties x3",
  ),
  EntryGismuEnglish(
    word: "tanxe",
    keyword: "box",
    hint: "'trunk'",
    definition: "x1 is a box/carton/trunk/crate for contents x2, and made of material x3",
  ),
  EntryGismuEnglish(
    word: "tapla",
    keyword: "tile",
    hint: "",
    definition: "x1 is a tile/cake [shape/form] of material x2, shape x3, thickness x4",
  ),
  EntryGismuEnglish(
    word: "tarbi",
    keyword: "embryo",
    hint: "",
    definition: "x1 is an embryo/zygote/fetus/fertilized egg with mother x2, and father x3",
  ),
  EntryGismuEnglish(
    word: "tarci",
    keyword: "star",
    hint: "",
    definition: "x1 is a star/sun with stellar properties x2",
  ),
  EntryGismuEnglish(
    word: "tarla",
    keyword: "tar",
    hint: "",
    definition: "x1 is a quantity of/contains/is made of tar/asphalt from source x2",
  ),
  EntryGismuEnglish(
    word: "tarmi",
    keyword: "shape",
    hint: "'form'",
    definition: "x1 [ideal] is the conceptual shape/form of object/abstraction/manifestation x2 " &
        "(object/abstract)",
  ),
  EntryGismuEnglish(
    word: "tarti",
    keyword: "behave",
    hint: "",
    definition: "x1 behaves/conducts oneself as/in-manner x2 (event/property) under conditions x3",
  ),
  EntryGismuEnglish(
    word: "taske",
    keyword: "thirst",
    hint: "",
    definition: "x1 thirsts for x2; x1 needs/wants drink/fluid/lubrication x2",
  ),
  EntryGismuEnglish(
    word: "tatpi",
    keyword: "tired",
    hint: "",
    definition: "x1 is tired/fatigued by effort/situation x2 (event); x1 needs/wants rest",
  ),
  EntryGismuEnglish(
    word: "tatru",
    keyword: "breast",
    hint: "'teat'",
    definition: "x1 is a/the breast/mammary/teat [body-part] of x2; [metaphor: projection " &
        "providing liquid]",
  ),
  EntryGismuEnglish(
    word: "tavla",
    keyword: "talk",
    hint: "'palaver'",
    definition: "x1 talks/speaks to x2 about subject x3 in language x4",
  ),
  EntryGismuEnglish(
    word: "taxfu",
    keyword: "garment",
    hint: "",
    definition: "x1 is dress/a garment/clothing for wearing by x2 (gender/species/body part) " &
        "serving purpose x3",
  ),
  EntryGismuEnglish(
    word: "tcaci",
    keyword: "custom",
    hint: "'habit'",
    definition: "x1 is a custom/habit/[ritual/rut] of x2 under conditions x3",
  ),
  EntryGismuEnglish(
    word: "tcadu",
    keyword: "city",
    hint: "'town'",
    definition: "x1 is a town/city of metropolitan area x2, in political unit x3, serving " &
        "hinterland/region x4",
  ),
  EntryGismuEnglish(
    word: "tcana",
    keyword: "station",
    hint: "",
    definition: "x1 is a station/node of/in/on transport/communication/distribution " &
        "system/network x2",
  ),
  EntryGismuEnglish(
    word: "tcati",
    keyword: "tea",
    hint: "",
    definition: "x1 is made of/contains/is a quantity of tea brewed from leaves x2",
  ),
  EntryGismuEnglish(
    word: "tcena",
    keyword: "stretch",
    hint: "",
    definition: "x1 stretches/extends to range x2 [interval/extent] in dimension x3 from relaxed " &
        "range x4",
  ),
  EntryGismuEnglish(
    word: "tcica",
    keyword: "deceive",
    hint: "'cheat, trick'",
    definition: "x1 (event/experience) misleads/deceives/dupes/fools/cheats/tricks x2 into x3 " &
        "(event/state)",
  ),
  EntryGismuEnglish(
    word: "tcidu",
    keyword: "read",
    hint: "",
    definition: "x1 [agent] reads x2 [text] from surface/document/reading material x3; x1 is a " &
        "reader",
  ),
  EntryGismuEnglish(
    word: "tcika",
    keyword: "time of day",
    hint: "",
    definition: "x1 [hours, {minutes}, {seconds}] is the time/hour of state/event x2 on day x3 " &
        "at location x4",
  ),
  EntryGismuEnglish(
    word: "tcila",
    keyword: "detail",
    hint: "",
    definition: "x1 is a detail/feature/particular of x2",
  ),
  EntryGismuEnglish(
    word: "tcima",
    keyword: "weather",
    hint: "'climate'",
    definition: "x1 is weather at place/region x2; (adjective:) x1 is meteorological",
  ),
  EntryGismuEnglish(
    word: "tcini",
    keyword: "situation",
    hint: "'state'",
    definition: "x1 [state/property] is a situation/condition/state/position/are " &
        "conditions/circumstances of x2",
  ),
  EntryGismuEnglish(
    word: "tcita",
    keyword: "label",
    hint: "'tag'",
    definition: "x1 is a label/tag of x2 showing information x3",
  ),
  EntryGismuEnglish(
    word: "te",
    keyword: "3rd conversion",
    hint: "",
    definition: "3rd conversion; switch 1st/3rd places",
  ),
  EntryGismuEnglish(
    word: "temci",
    keyword: "time",
    hint: "",
    definition: "x1 is the time-duration/interval/period/[elapsed time] from time/event x2 to " &
        "time/event x3",
  ),
  EntryGismuEnglish(
    word: "tenfa",
    keyword: "exponential",
    hint: "",
    definition: "x1 is the exponential result of base x2 to power/exponent x3",
  ),
  EntryGismuEnglish(
    word: "tengu",
    keyword: "texture",
    hint: "",
    definition: "x1 (property-ka) is a texture of x2",
  ),
  EntryGismuEnglish(
    word: "terdi",
    keyword: "earth",
    hint: "'terrestrial'",
    definition: "x1 is the Earth/the home planet of race x2; (adjective:) x1 is " &
        "terrestrial/earthbound",
  ),
  EntryGismuEnglish(
    word: "terpa",
    keyword: "fear",
    hint: "'terror'",
    definition: "x1 fears x2; x1 is afraid/scared/frightened by/fearful of x2 (event/tu'a object)",
  ),
  EntryGismuEnglish(
    word: "terto",
    keyword: "1E12",
    hint: "metric 'tera'",
    definition: "x1 is a trillion [1x10**12] of x2 in dimension/aspect x3 (default is units)",
  ),
  EntryGismuEnglish(
    word: "ti",
    keyword: "this here",
    hint: "",
    definition: "pro-sumti: this here; immediate demonstrative it; indicated thing/place near " &
        "speaker",
  ),
  EntryGismuEnglish(
    word: "tigni",
    keyword: "perform",
    hint: "",
    definition: "x1 performs x2 [performance] for/before audience x3",
  ),
  EntryGismuEnglish(
    word: "tikpa",
    keyword: "kick",
    hint: "",
    definition: "x1 kicks [hits with x1's foot/feet x4] x2 in/at locus x3, using x1's foot/feet x4",
  ),
  EntryGismuEnglish(
    word: "tilju",
    keyword: "heavy",
    hint: "'weighty'",
    definition: "x1 is heavy/weighty in mass/weight by standard x2",
  ),
  EntryGismuEnglish(
    word: "tinbe",
    keyword: "obey",
    hint: "",
    definition: "x1 obeys/follows the command/rule x2 made by x3; (adjective:) x1 is obedient",
  ),
  EntryGismuEnglish(
    word: "tinci",
    keyword: "tin",
    hint: "",
    definition: "x1 is a quantity of/contains/is made of tin (Sn); [metaphor: cheap or base metal]",
  ),
  EntryGismuEnglish(
    word: "tinsa",
    keyword: "stiff",
    hint: "",
    definition: "x1 is stiff/rigid/inflexible/resistant in direction x2 against force x3 under " &
        "conditions x4",
  ),
  EntryGismuEnglish(
    word: "tirna",
    keyword: "hear",
    hint: "",
    definition: "x1 hears x2 against background/noise x3; x2 is audible; (adjective:) x1 is aural",
  ),
  EntryGismuEnglish(
    word: "tirse",
    keyword: "iron",
    hint: "",
    definition: "x1 is a quantity of/contains/is made of iron (Fe); [metaphor: strong, durable, " &
        "tarnishing]",
  ),
  EntryGismuEnglish(
    word: "tirxu",
    keyword: "tiger",
    hint: "",
    definition: "x1 is a tiger/leopard/jaguar/[tigress] of species/breed x2 with coat markings x3",
  ),
  EntryGismuEnglish(
    word: "tisna",
    keyword: "fill",
    hint: "'stuff'",
    definition: "x1 (object) fills/becomes stuffed [up]/inflates/blows up with material x2; x2 " &
        "pours into x1",
  ),
  EntryGismuEnglish(
    word: "titla",
    keyword: "sweet",
    hint: "",
    definition: "x1 is sweet/sugary/saccharine to observer x2",
  ),
  EntryGismuEnglish(
    word: "tivni",
    keyword: "television",
    hint: "",
    definition: "x1 broadcasts/televises programming x2 via medium/channel x3 to television " &
        "receiver x4",
  ),
  EntryGismuEnglish(
    word: "tixnu",
    keyword: "daughter",
    hint: "",
    definition: "x1 is a daughter of mother/father/parents x2; [not necessarily biological]",
  ),
  EntryGismuEnglish(
    word: "to'e",
    keyword: "polar opposite",
    hint: "",
    definition: "polar opposite scalar negator",
  ),
  EntryGismuEnglish(
    word: "toknu",
    keyword: "oven",
    hint: "",
    definition: "x1 is an oven [enclosure that heats its contents] for baking/heating/drying x2",
  ),
  EntryGismuEnglish(
    word: "toldi",
    keyword: "butterfly",
    hint: "",
    definition: "x1 is a butterfly/moth of species/breed x2",
  ),
  EntryGismuEnglish(
    word: "tonga",
    keyword: "tone",
    hint: "",
    definition: "x1 is a tone/note of frequency/pitch x2 from source x3",
  ),
  EntryGismuEnglish(
    word: "tordu",
    keyword: "short",
    hint: "",
    definition: "x1 is short in dimension/direction x2 (default longest dimension) by " &
        "measurement standard x3",
  ),
  EntryGismuEnglish(
    word: "torni",
    keyword: "twist",
    hint: "'torsion'",
    definition: "x1 twists under load/force/torsion x2",
  ),
  EntryGismuEnglish(
    word: "traji",
    keyword: "superlative",
    hint: "'extreme'",
    definition: "x1 is superlative in property x2 (ka), the x3 extreme (ka; default ka zmadu) " &
        "among set/range x4",
  ),
  EntryGismuEnglish(
    word: "trano",
    keyword: "nitrogen",
    hint: "",
    definition: "x1 is a quantity of/contains/is made of nitrogen/ammonia/nitrates",
  ),
  EntryGismuEnglish(
    word: "trati",
    keyword: "taut",
    hint: "",
    definition: "x1 is taut/tense/strained tight in direction x2",
  ),
  EntryGismuEnglish(
    word: "trene",
    keyword: "train",
    hint: "",
    definition: "x1 is a train [vehicle] of cars/units x2 (mass) for rails/system/railroad x3, " &
        "propelled by x4",
  ),
  EntryGismuEnglish(
    word: "tricu",
    keyword: "tree",
    hint: "",
    definition: "x1 is a tree of species/cultivar x2",
  ),
  EntryGismuEnglish(
    word: "trina",
    keyword: "attract",
    hint: "",
    definition: "x1 attracts/appeals to/lures x2 (person/event) with property/quality x3 (ka)",
  ),
  EntryGismuEnglish(
    word: "trixe",
    keyword: "behind",
    hint: "",
    definition: "x1 is posterior/behind/back/in the rear of x2 which faces/in-frame-of-reference " &
        "x3",
  ),
  EntryGismuEnglish(
    word: "troci",
    keyword: "try",
    hint: "",
    definition: "x1 tries/attempts/makes an effort to do/attain x2 (event/state/property) by " &
        "actions/method x3",
  ),
  EntryGismuEnglish(
    word: "tsali",
    keyword: "strong",
    hint: "",
    definition: "x1 is strong/powerful/[tough] in property/quality x2 (ka) by standard x3",
  ),
  EntryGismuEnglish(
    word: "tsani",
    keyword: "sky",
    hint: "",
    definition: "x1 is an expanse of sky/the heavens at place x2; [celestial]",
  ),
  EntryGismuEnglish(
    word: "tsapi",
    keyword: "seasoning",
    hint: "",
    definition: "x1 is a seasoning/condiment/spice causing flavor/effect x2 (event/property)",
  ),
  EntryGismuEnglish(
    word: "tsiju",
    keyword: "seed",
    hint: "",
    definition: "x1(s) is/are (a) seed(s)/spore(s) [body-part] of organism x2 for producing " &
        "offspring x3",
  ),
  EntryGismuEnglish(
    word: "tsina",
    keyword: "stage",
    hint: "",
    definition: "x1 is a stage/platform/dais/[scaffold] at/in x2 supporting x3, made of material " &
        "x4",
  ),
  EntryGismuEnglish(
    word: "tu",
    keyword: "that yonder",
    hint: "",
    definition: "pro-sumti: that yonder; distant demonstrative it; indicated thing far from " &
        "speaker & listener",
  ),
  EntryGismuEnglish(
    word: "tubnu",
    keyword: "tube",
    hint: "",
    definition: "x1 is a length of tubing/pipe/hollow cylinder [shape/form] of material x2, " &
        "hollow of material x3",
  ),
  EntryGismuEnglish(
    word: "tugni",
    keyword: "agree",
    hint: "",
    definition: "x1 [person] agrees with person(s)/position/side x2 that x3 (du'u) is true about " &
        "matter x4",
  ),
  EntryGismuEnglish(
    word: "tujli",
    keyword: "tulip",
    hint: "",
    definition: "x1 is a tulip (defined by flower shape) of species/strain x2",
  ),
  EntryGismuEnglish(
    word: "tumla",
    keyword: "land",
    hint: "",
    definition: "x1 is a parcel/expanse of land at location x2; x1 is terrain",
  ),
  EntryGismuEnglish(
    word: "tunba",
    keyword: "sibling",
    hint: "",
    definition: "x1 is a sibling of x2 by bond/tie/standard/parent(s) x3",
  ),
  EntryGismuEnglish(
    word: "tunka",
    keyword: "copper",
    hint: "",
    definition: "x1 is made of/contains/is a quantity of copper (Cu); [metaphor: reddish, " &
        "electrical conductor]",
  ),
  EntryGismuEnglish(
    word: "tunlo",
    keyword: "swallow",
    hint: "",
    definition: "x1 gulps/swallows",
  ),
  EntryGismuEnglish(
    word: "tunta",
    keyword: "poke",
    hint: "'stab'",
    definition: "x1 (object, usually pointed) pokes/jabs/stabs/prods x2 (experiencer)",
  ),
  EntryGismuEnglish(
    word: "tuple",
    keyword: "leg",
    hint: "",
    definition: "x1 is a/the leg [body-part] of x2; [metaphor: supporting branch]",
  ),
  EntryGismuEnglish(
    word: "turni",
    keyword: "govern",
    hint: "",
    definition: "x1 governs/rules/is ruler/governor/sovereign/reigns over " &
        "people/territory/domain/subjects x2",
  ),
  EntryGismuEnglish(
    word: "tutci",
    keyword: "tool",
    hint: "",
    definition: "x1 is a tool/utensil/resource/instrument/implement used for doing x2; [form " &
        "determines function]",
  ),
  EntryGismuEnglish(
    word: "tutra",
    keyword: "territory",
    hint: "",
    definition: "x1 is territory/domain/space of/belonging to/controlled by x2",
  ),
  EntryGismuEnglish(
    word: "va",
    keyword: "there at",
    hint: "",
    definition: "location tense distance: near to ... ; there at ...; a medium/small distance " &
        "from ...",
  ),
  EntryGismuEnglish(
    word: "vacri",
    keyword: "air",
    hint: "",
    definition: "x1 is a quantity of air/normally-gaseous atmosphere of planet x2, of " &
        "composition including x3",
  ),
  EntryGismuEnglish(
    word: "vajni",
    keyword: "important",
    hint: "'significant'",
    definition: "x1 (object/event) is important/significant to x2 (person/event) in aspect/for " &
        "reason x3 (nu/ka)",
  ),
  EntryGismuEnglish(
    word: "valsi",
    keyword: "word",
    hint: "",
    definition: "x1 is a word meaning/causing x2 in language x3; (adjective: x1 is lexical/verbal)",
  ),
  EntryGismuEnglish(
    word: "vamji",
    keyword: "value",
    hint: "",
    definition: "x1 (ni) is the equivalent value/worth of x2 [item(s) of value] to x3 for " &
        "use/appreciation x4",
  ),
  EntryGismuEnglish(
    word: "vamtu",
    keyword: "vomit",
    hint: "",
    definition: "x1 vomits/regurgitates x2; x1 throws x2 up; [violent] digestive expulsion",
  ),
  EntryGismuEnglish(
    word: "vanbi",
    keyword: "environment",
    hint: "'ambient'",
    definition: "x1 (ind./mass) is part of an environment/surroundings/context/ambience of x2",
  ),
  EntryGismuEnglish(
    word: "vanci",
    keyword: "evening",
    hint: "",
    definition: "x1 is an evening [from end-of-work until sleep typical for locale] of day x2 at " &
        "location x3",
  ),
  EntryGismuEnglish(
    word: "vanju",
    keyword: "wine",
    hint: "",
    definition: "x1 is made of/contains/is a quantity of wine from fruit/grapes x2",
  ),
  EntryGismuEnglish(
    word: "vasru",
    keyword: "contain",
    hint: "'vessel'",
    definition: "x1 contains/holds/encloses/includes contents x2 within; x1 is a vessel " &
        "containing x2",
  ),
  EntryGismuEnglish(
    word: "vasxu",
    keyword: "breathe",
    hint: "'vascular'",
    definition: "x1 breathes/respires x2 [gas]",
  ),
  EntryGismuEnglish(
    word: "ve",
    keyword: "4th conversion",
    hint: "",
    definition: "4th conversion; switch 1st/4th places",
  ),
  EntryGismuEnglish(
    word: "ve'e",
    keyword: "whole space interval",
    hint: "",
    definition: "location tense interval: the whole of space (rafsi is used to represent any " &
        "space interval)",
  ),
  EntryGismuEnglish(
    word: "vecnu",
    keyword: "sell",
    hint: "'vend'",
    definition: "x1 [seller] sells/vends x2 [goods/service/commodity] to buyer x3 for " &
        "amount/cost/expense x4",
  ),
  EntryGismuEnglish(
    word: "venfu",
    keyword: "revenge",
    hint: "'avenge'",
    definition: "x1 takes revenge on/retaliates against x2 (person) for wrong x3 (nu) with " &
        "vengeance x4 (nu)",
  ),
  EntryGismuEnglish(
    word: "vensa",
    keyword: "spring",
    hint: "'vernal'",
    definition: "x1 is spring/springtime [warming season] of year x2 at location x3; " &
        "(adjective:) x1 is vernal",
  ),
  EntryGismuEnglish(
    word: "verba",
    keyword: "child",
    hint: "",
    definition: "x1 is a child/kid/juvenile [a young person] of age x2, immature by standard x3",
  ),
  EntryGismuEnglish(
    word: "vi",
    keyword: "here at",
    hint: "",
    definition: "location tense distance: here at ... ; at, near, or a very short/tiny distance " &
        "from ...",
  ),
  EntryGismuEnglish(
    word: "vibna",
    keyword: "vagina",
    hint: "",
    definition: "x1 is a/the vagina [body-part] of x2",
  ),
  EntryGismuEnglish(
    word: "vidni",
    keyword: "video",
    hint: "",
    definition: "x1 is a video monitor/CRT/screen [machine] serving function x2",
  ),
  EntryGismuEnglish(
    word: "vidru",
    keyword: "virus",
    hint: "",
    definition: "x1 is a virus of species/breed/defining property x2 capable of infecting [at] x3",
  ),
  EntryGismuEnglish(
    word: "vifne",
    keyword: "fresh",
    hint: "",
    definition: "(adjective:) x1 is fresh/unspoiled",
  ),
  EntryGismuEnglish(
    word: "vikmi",
    keyword: "excrete",
    hint: "",
    definition: "x1 [body] excretes waste x2 from source x3 via means/route x4",
  ),
  EntryGismuEnglish(
    word: "viknu",
    keyword: "viscous",
    hint: "'thick'",
    definition: "x1 is thick/viscous under conditions x2",
  ),
  EntryGismuEnglish(
    word: "vimcu",
    keyword: "remove",
    hint: "",
    definition: "x1 removes/subtracts/deducts/takes away x2 from x3 with/leaving " &
        "result/remnant/remainder x4",
  ),
  EntryGismuEnglish(
    word: "vindu",
    keyword: "poison",
    hint: "'venom'",
    definition: "x1 is poisonous/venomous/toxic/a toxin to x2",
  ),
  EntryGismuEnglish(
    word: "vinji",
    keyword: "airplane",
    hint: "",
    definition: "x1 is an airplane/aircraft [flying vehicle] for carrying passengers/cargo x2, " &
        "propelled by x3",
  ),
  EntryGismuEnglish(
    word: "vipsi",
    keyword: "deputy",
    hint: "'vice'",
    definition: "x1 is a deputy/vice/subordinate in aspect [or organization principle] x2 (ka) " &
        "to principal x3",
  ),
  EntryGismuEnglish(
    word: "virnu",
    keyword: "brave",
    hint: "'valiant, virtue'",
    definition: "x1 is brave/valiant/courageous in activity x2 (event) by standard x3",
  ),
  EntryGismuEnglish(
    word: "viska",
    keyword: "see",
    hint: "'vision'",
    definition: "x1 sees/views/perceives visually x2 under conditions x3",
  ),
  EntryGismuEnglish(
    word: "vitci",
    keyword: "irregular",
    hint: "'intermittent'",
    definition: "x1 is irregular/occasional/intermittent in property/action/aspect x2",
  ),
  EntryGismuEnglish(
    word: "vitke",
    keyword: "guest",
    hint: "'visit'",
    definition: "x1 is a guest/visitor of x2 at place/event x3; x1 visits x2/x3",
  ),
  EntryGismuEnglish(
    word: "vitno",
    keyword: "permanent",
    hint: "'eternal'",
    definition: "x1 is permanent/lasting/[eternal] in property x2 (ka) by standard x3 " &
        "[time-span/expectant one]",
  ),
  EntryGismuEnglish(
    word: "vlagi",
    keyword: "vulva",
    hint: "",
    definition: "x1 is a/the vulva [body-part] of x2",
  ),
  EntryGismuEnglish(
    word: "vlile",
    keyword: "violent",
    hint: "",
    definition: "x1 is an event/state/act of violence",
  ),
  EntryGismuEnglish(
    word: "vlina",
    keyword: "alternation",
    hint: "",
    definition: "x1 is a logical alternation/disjunction, stating that x2 (du'u) and/or x3 " &
        "(du'u) is/are true",
  ),
  EntryGismuEnglish(
    word: "vlipa",
    keyword: "powerful",
    hint: "",
    definition: "x1 has the power to bring about x2 under conditions x3; x1 is powerful in " &
        "aspect x2 under x3",
  ),
  EntryGismuEnglish(
    word: "vo",
    keyword: "4",
    hint: "",
    definition: "digit/number: 4 (digit)",
  ),
  EntryGismuEnglish(
    word: "vofli",
    keyword: "flight",
    hint: "'fly'",
    definition: "x1 flies [in air/atmosphere] using lifting/propulsion means x2",
  ),
  EntryGismuEnglish(
    word: "voksa",
    keyword: "voice",
    hint: "",
    definition: "x1 is a voice/speech sound of individual x2",
  ),
  EntryGismuEnglish(
    word: "vorme",
    keyword: "door",
    hint: "",
    definition: "x1 is a doorway/gateway/access way between x2 and x3 of structure x4",
  ),
  EntryGismuEnglish(
    word: "vraga",
    keyword: "lever",
    hint: "",
    definition: "x1 is a lever [tool] [of apparatus] for doing x2 [function/action], with " &
        "fulcrum x3 and arm x4",
  ),
  EntryGismuEnglish(
    word: "vreji",
    keyword: "record",
    hint: "",
    definition: "x1 is a record of x2 (data/facts/du'u) about x3 (object/event) preserved in " &
        "medium x4",
  ),
  EntryGismuEnglish(
    word: "vreta",
    keyword: "reclining",
    hint: "'rest'",
    definition: "x1 lies/rests/reclines/reposes on x2; x1 is reclining/recumbent/lying on x2",
  ),
  EntryGismuEnglish(
    word: "vrici",
    keyword: "miscellaneous",
    hint: "'various'",
    definition: "x1 (set/mass/ind.) is miscellaneous/various/assorted in property x2 (ka)",
  ),
  EntryGismuEnglish(
    word: "vrude",
    keyword: "virtue",
    hint: "",
    definition: "x1 is virtuous/saintly/[fine/moral/nice/holy/morally good] by standard x2",
  ),
  EntryGismuEnglish(
    word: "vrusi",
    keyword: "taste",
    hint: "'flavor'",
    definition: "x1 (ka) is a taste/flavor of/emitted by x2; x2 tastes of/like x1",
  ),
  EntryGismuEnglish(
    word: "vu",
    keyword: "yonder at",
    hint: "",
    definition: "location tense distance: far from ... ; yonder at ... ; a long distance from ...",
  ),
  EntryGismuEnglish(
    word: "vukro",
    keyword: "Ukrainian",
    hint: "",
    definition: "x1 reflects Ukrainian language/culture/nationality in aspect x2",
  ),
  EntryGismuEnglish(
    word: "xa",
    keyword: "6",
    hint: "",
    definition: "digit/number: 6 (digit)",
  ),
  EntryGismuEnglish(
    word: "xabju",
    keyword: "dwell",
    hint: "'inhabit'",
    definition: "x1 dwells/lives/resides/abides at/inhabits/is a resident of " &
        "location/habitat/nest/home/abode x2",
  ),
  EntryGismuEnglish(
    word: "xadba",
    keyword: "half",
    hint: "",
    definition: "x1 is exactly/approximately half/semi-/demi-/hemi- of x2 by standard x3",
  ),
  EntryGismuEnglish(
    word: "xadni",
    keyword: "body",
    hint: "",
    definition: "x1 is a/the body/corpus/corpse of x2; (adjective:) x1 is corporal/corporeal",
  ),
  EntryGismuEnglish(
    word: "xagji",
    keyword: "hunger",
    hint: "",
    definition: "x1 hungers for x2; x1 needs/wants food/fuel x2",
  ),
  EntryGismuEnglish(
    word: "xagri",
    keyword: "reed",
    hint: "",
    definition: "x1 is a oboe/clarinet/saxophone [reed musical instrument] with reed x2",
  ),
  EntryGismuEnglish(
    word: "xajmi",
    keyword: "funny",
    hint: "'comic'",
    definition: "x1 is funny/comical to x2 in property/aspect x3 (nu/ka); x3 is what is funny " &
        "about x1 to x2",
  ),
  EntryGismuEnglish(
    word: "xaksu",
    keyword: "use up",
    hint: "",
    definition: "x1 (event) uses up/depletes/consumes/[wastes] x2 [resource]",
  ),
  EntryGismuEnglish(
    word: "xalbo",
    keyword: "levity",
    hint: "'frivolous'",
    definition: "x1 uses levity/is non-serious/frivolous about x2 (abstraction)",
  ),
  EntryGismuEnglish(
    word: "xalka",
    keyword: "alcohol",
    hint: "",
    definition: "x1 is a quantity of/contains/is made of alcohol of type x2 from source/process x3",
  ),
  EntryGismuEnglish(
    word: "xalni",
    keyword: "panic",
    hint: "",
    definition: "x1 (person) is panicked by crisis x2 (event/state)",
  ),
  EntryGismuEnglish(
    word: "xamgu",
    keyword: "good",
    hint: "",
    definition: "x1 (object/event) is good/beneficial/nice/[acceptable] for x2 by standard x3",
  ),
  EntryGismuEnglish(
    word: "xampo",
    keyword: "ampere",
    hint: "",
    definition: "x1 is x2 ampere(s) [metric unit] in current (default is 1) by standard x3",
  ),
  EntryGismuEnglish(
    word: "xamsi",
    keyword: "sea",
    hint: "",
    definition: "x1 is a sea/ocean/gulf/[atmosphere] of planet x2, of fluid x3; (adjective:) x1 " &
        "is marine",
  ),
  EntryGismuEnglish(
    word: "xance",
    keyword: "hand",
    hint: "",
    definition: "x1 is a/the hand [body-part] of x2; [metaphor: manipulating tool, waldo]",
  ),
  EntryGismuEnglish(
    word: "xanka",
    keyword: "nervous",
    hint: "'anxious'",
    definition: "x1 is nervous/anxious about x2 (abstraction) under conditions x3",
  ),
  EntryGismuEnglish(
    word: "xanri",
    keyword: "imaginary",
    hint: "'unreal'",
    definition: "x1 [concept] exists in the imagination of/is imagined by/is imaginary to x2",
  ),
  EntryGismuEnglish(
    word: "xanto",
    keyword: "elephant",
    hint: "",
    definition: "x1 is an elephant of species/breed x2",
  ),
  EntryGismuEnglish(
    word: "xarci",
    keyword: "weapon",
    hint: "'arms'",
    definition: "x1 is a weapon/arms for use against x2 by x3",
  ),
  EntryGismuEnglish(
    word: "xarju",
    keyword: "pig",
    hint: "'hog'",
    definition: "x1 is a pig/hog/swine/[boar] [pork/ham/bacon-producer] of species/breed x2",
  ),
  EntryGismuEnglish(
    word: "xarnu",
    keyword: "stubborn",
    hint: "",
    definition: "x1 is stubborn/willfully opposing/resisting x2 about x3 (event/state)",
  ),
  EntryGismuEnglish(
    word: "xasli",
    keyword: "donkey",
    hint: "'ass'",
    definition: "x1 is a donkey/jackass of species/breed x2",
  ),
  EntryGismuEnglish(
    word: "xasne",
    keyword: "sweat",
    hint: "",
    definition: "x1 is a/the sweat/perspiration from body x2, excreted by gland(s)/organs x3",
  ),
  EntryGismuEnglish(
    word: "xatra",
    keyword: "letter",
    hint: "",
    definition: "x1 is a letter/missive/[note] to intended audience x2 from author/originator x3 " &
        "with content x4",
  ),
  EntryGismuEnglish(
    word: "xatsi",
    keyword: "1E-18",
    hint: "metric 'atto'",
    definition: "x1 is 1x10**-18 of x2 in dimension/aspect x3 (default is units)",
  ),
  EntryGismuEnglish(
    word: "xazdo",
    keyword: "Asiatic",
    hint: "",
    definition: "x1 reflects Asiatic culture/nationality/geography in aspect x2",
  ),
  EntryGismuEnglish(
    word: "xe",
    keyword: "5th conversion",
    hint: "",
    definition: "5th conversion; switch 1st/5th places",
  ),
  EntryGismuEnglish(
    word: "xebni",
    keyword: "hate",
    hint: "",
    definition: "x1 hates/despises x2 (object/abstraction); x1 is full of hate for x2; x2 is " &
        "odious to x1",
  ),
  EntryGismuEnglish(
    word: "xebro",
    keyword: "Hebrew",
    hint: "",
    definition: "x1 reflects Hebrew/Jewish/Israeli culture/nationality/language in aspect x2",
  ),
  EntryGismuEnglish(
    word: "xecto",
    keyword: "100",
    hint: "metric 'hecto'",
    definition: "x1 is a hundred [100; 1x10**2] of x2 in dimension/aspect x3 (default is units)",
  ),
  EntryGismuEnglish(
    word: "xedja",
    keyword: "jaw",
    hint: "",
    definition: "x1 is a/the jaw [body-part] of x2",
  ),
  EntryGismuEnglish(
    word: "xekri",
    keyword: "black",
    hint: "",
    definition: "x1 is black/extremely dark-colored [color adjective]",
  ),
  EntryGismuEnglish(
    word: "xelso",
    keyword: "Greek",
    hint: "'Hellas'",
    definition: "x1 reflects Greek/Hellenic culture/nationality/language in aspect x2",
  ),
  EntryGismuEnglish(
    word: "xendo",
    keyword: "kind",
    hint: "",
    definition: "x1 (person) is kind to x2 in actions/behavior x3",
  ),
  EntryGismuEnglish(
    word: "xenru",
    keyword: "regret",
    hint: "'rue'",
    definition: "x1 regrets/rues (abstraction) x2; x1 is regretful/rueful/sorry/[remorseful] " &
        "about x2",
  ),
  EntryGismuEnglish(
    word: "xexso",
    keyword: "1E18",
    hint: "metric 'exa'",
    definition: "x1 is 1x10**18 of x2 in dimension/aspect x3 (default is units)",
  ),
  EntryGismuEnglish(
    word: "xindo",
    keyword: "Hindi",
    hint: "",
    definition: "x1 reflects Hindi language/culture/religion in aspect x2",
  ),
  EntryGismuEnglish(
    word: "xinmo",
    keyword: "ink",
    hint: "",
    definition: "x1 is a quantity of ink of color/pigment x2 used by writing device x3",
  ),
  EntryGismuEnglish(
    word: "xirma",
    keyword: "horse",
    hint: "",
    definition: "x1 is a horse/equine/[colt/mare/stallion/pony] of species/breed x2",
  ),
  EntryGismuEnglish(
    word: "xislu",
    keyword: "wheel",
    hint: "",
    definition: "x1 is a wheel [tool] of device/vehicle x2, made of materials/having properties x3",
  ),
  EntryGismuEnglish(
    word: "xispo",
    keyword: "Hispanic",
    hint: "",
    definition: "x1 reflects Hispano-American culture/nationalities in aspect x2",
  ),
  EntryGismuEnglish(
    word: "xlali",
    keyword: "bad",
    hint: "'mal-'",
    definition: "x1 is bad for x2 by standard x3; x1 is poor/unacceptable to x2",
  ),
  EntryGismuEnglish(
    word: "xlura",
    keyword: "influence",
    hint: "'lure'",
    definition: "x1 (agent) influences/lures/tempts x2 into action/state x3 by " &
        "influence/threat/lure x4",
  ),
  EntryGismuEnglish(
    word: "xotli",
    keyword: "hotel",
    hint: "",
    definition: "x1 is a hotel/inn/hostel at location x2 operated by x3",
  ),
  EntryGismuEnglish(
    word: "xrabo",
    keyword: "Arabic",
    hint: "",
    definition: "x1 reflects Arabic-speaking culture/nationality in aspect x2",
  ),
  EntryGismuEnglish(
    word: "xrani",
    keyword: "injure",
    hint: "'hurt'",
    definition: "x1 (event) injures/harms/damages victim x2 in property x3 (ka) resulting in " &
        "injury x4 (state)",
  ),
  EntryGismuEnglish(
    word: "xriso",
    keyword: "Christian",
    hint: "",
    definition: "x1 pertains to the Christian religion/culture/nationality in aspect x2",
  ),
  EntryGismuEnglish(
    word: "xruba",
    keyword: "buckwheat",
    hint: "'rhubarb'",
    definition: "x1 is a quantity of buckwheat/rhubarb/sorrel grass of species/strain x2",
  ),
  EntryGismuEnglish(
    word: "xruki",
    keyword: "turkey",
    hint: "",
    definition: "x1 is a turkey [food/bird] of species/breed x2",
  ),
  EntryGismuEnglish(
    word: "xrula",
    keyword: "flower",
    hint: "",
    definition: "x1 is a/the flower/blossom/bloom [body-part] of plant/species x2; (adjective:) " &
        "x1 is floral",
  ),
  EntryGismuEnglish(
    word: "xruti",
    keyword: "return",
    hint: "",
    definition: "x1 (agent) returns x2 to origin/earlier state x3 from x4; x1 moves/gives x2 " &
        "back to x3 from x4",
  ),
  EntryGismuEnglish(
    word: "xukmi",
    keyword: "chemical",
    hint: "",
    definition: "x1 is an instance of substance/chemical/drug x2 (individual or mass) with " &
        "purity x3",
  ),
  EntryGismuEnglish(
    word: "xunre",
    keyword: "red",
    hint: "",
    definition: "x1 is red/crimson/ruddy [color adjective]",
  ),
  EntryGismuEnglish(
    word: "xurdo",
    keyword: "Urdu",
    hint: "",
    definition: "x1 reflects Urdu language/culture/nationality in aspect x2",
  ),
  EntryGismuEnglish(
    word: "xusra",
    keyword: "assert",
    hint: "",
    definition: "x1 (agent) asserts/claims/declares x2 (du'u) is true [can be used for " &
        "epistemology of authority]",
  ),
  EntryGismuEnglish(
    word: "xutla",
    keyword: "smooth",
    hint: "",
    definition: "x1 is smooth/even/[soft/silky] in texture/regularity",
  ),
  EntryGismuEnglish(
    word: "za'i",
    keyword: "state abstract",
    hint: "",
    definition: "abstractor: state (event) abstractor; x1 is continuous state of [bridi] being " &
        "true",
  ),
  EntryGismuEnglish(
    word: "za'o",
    keyword: "superfective",
    hint: "",
    definition: "interval event contour: continuing too long after natural end of ...; " &
        "superfective  |     ---->",
  ),
  EntryGismuEnglish(
    word: "zabna",
    keyword: "favorable",
    hint: "",
    definition: "x1 is a favorable connotation/sense/way-of-looking-at x2 used by x3",
  ),
  EntryGismuEnglish(
    word: "zajba",
    keyword: "gymnast",
    hint: "",
    definition: "x1 is a gymnast at/performs gymnastics feat x2",
  ),
  EntryGismuEnglish(
    word: "zalvi",
    keyword: "grind",
    hint: "'pulverize'",
    definition: "x1 [individual or mass of hard surfaces] grinds/pulverizes/crushes x2 into " &
        "powder x3",
  ),
  EntryGismuEnglish(
    word: "zanru",
    keyword: "approve",
    hint: "",
    definition: "x1 approves of/gives favor to plan/action x2 (object/event)",
  ),
  EntryGismuEnglish(
    word: "zarci",
    keyword: "market",
    hint: "'mart'",
    definition: "x1 is a market/store/exchange/shop(s) selling/trading (for) x2, operated " &
        "by/with participants x3",
  ),
  EntryGismuEnglish(
    word: "zargu",
    keyword: "buttock",
    hint: "'arse'",
    definition: "x1 is a/the buttock(s)/arse/rear/seat [body-part] of x2; [metaphor: rounded " &
        "surface, support]",
  ),
  EntryGismuEnglish(
    word: "zasni",
    keyword: "temporary",
    hint: "'transient'",
    definition: "x1 is temporary/not permanent/expected to change in property x2 (ka) by " &
        "standard/expectant x3",
  ),
  EntryGismuEnglish(
    word: "zasti",
    keyword: "exist",
    hint: "",
    definition: "x1 exists/is real/actual/reality for x2 under metaphysics x3",
  ),
  EntryGismuEnglish(
    word: "zbabu",
    keyword: "soap",
    hint: "",
    definition: "x1 is a quantity of/contains/is made of soap from source x2 of composition " &
        "including x3",
  ),
  EntryGismuEnglish(
    word: "zbani",
    keyword: "bay",
    hint: "",
    definition: "x1 is a bay in/of coast/shoreline x2",
  ),
  EntryGismuEnglish(
    word: "zbasu",
    keyword: "make",
    hint: "",
    definition: "x1 makes/assembles/builds/manufactures/creates x2 out of " &
        "materials/parts/components x3",
  ),
  EntryGismuEnglish(
    word: "zbepi",
    keyword: "pedestal",
    hint: "'base'",
    definition: "x1 is a pedestal/base/stand/pallet supporting x2 (object/event), of " &
        "materials/properties x3",
  ),
  EntryGismuEnglish(
    word: "zdani",
    keyword: "nest",
    hint: "'den'",
    definition: "x1 is a nest/house/lair/den/[home] of/for x2",
  ),
  EntryGismuEnglish(
    word: "zdile",
    keyword: "amusing",
    hint: "'amused'",
    definition: "x1 (abstract) is amusing/entertaining to x2 in property/aspect x3; x3 is what " &
        "amuses x2 about x1",
  ),
  EntryGismuEnglish(
    word: "ze",
    keyword: "7",
    hint: "",
    definition: "digit/number: 7 (digit)",
  ),
  EntryGismuEnglish(
    word: "ze'e",
    keyword: "whole time interval",
    hint: "",
    definition: "time tense interval: the whole of time (rafsi is used to represent any time " &
        "interval)",
  ),
  EntryGismuEnglish(
    word: "ze'o",
    keyword: "outward",
    hint: "",
    definition: "location tense relation/direction; beyond/outward/receding from ...",
  ),
  EntryGismuEnglish(
    word: "zekri",
    keyword: "crime",
    hint: "",
    definition: "x1 (event/state) is a punishable crime/[taboo/sin] to " &
        "people/culture/judges/jury x2",
  ),
  EntryGismuEnglish(
    word: "zenba",
    keyword: "increase",
    hint: "'augment'",
    definition: "x1 (experiencer) increases/is incremented/augmented in property/quantity x2 by " &
        "amount x3",
  ),
  EntryGismuEnglish(
    word: "zepti",
    keyword: "1E-21",
    hint: "'zepto'",
    definition: "x1 is 1x10**-21 of x2 in dimension/aspect x3 (default is units)",
  ),
  EntryGismuEnglish(
    word: "zetro",
    keyword: "1E21",
    hint: "'zetta'",
    definition: "x1 is 1x10**21 of x2 in dimension/aspect x3 (default is units)",
  ),
  EntryGismuEnglish(
    word: "zgana",
    keyword: "observe",
    hint: "",
    definition: "x1 observes/[notices]/watches/beholds x2 using senses/means x3 under conditions " &
        "x4",
  ),
  EntryGismuEnglish(
    word: "zgike",
    keyword: "music",
    hint: "",
    definition: "x1 is music performed/produced by x2 (event)",
  ),
  EntryGismuEnglish(
    word: "zi'o",
    keyword: "nonexistent it",
    hint: "",
    definition: "pro-sumti: fills a sumti place, deleting it from selbri place structure;changes " &
        "selbri semantics",
  ),
  EntryGismuEnglish(
    word: "zifre",
    keyword: "free",
    hint: "",
    definition: "x1 is free/at liberty to do/be x2 (event/state) under conditions x3",
  ),
  EntryGismuEnglish(
    word: "zinki",
    keyword: "zinc",
    hint: "",
    definition: "x1 is a quantity of/contains/is made of zinc (Zn); [metaphor: hard metal]",
  ),
  EntryGismuEnglish(
    word: "zirpu",
    keyword: "purple",
    hint: "",
    definition: "x1 is purple/violet [color adjective]",
  ),
  EntryGismuEnglish(
    word: "zivle",
    keyword: "invest",
    hint: "",
    definition: "x1 (agent) invests resources x2 in investment x3 expecting return/profit x4 " &
        "(object(s)/event)",
  ),
  EntryGismuEnglish(
    word: "zmadu",
    keyword: "more",
    hint: "",
    definition: "x1 exceeds/is more than x2 in property/quantity x3 (ka/ni) by amount/excess x4",
  ),
  EntryGismuEnglish(
    word: "zmiku",
    keyword: "automatic",
    hint: "",
    definition: "x1 is automatic in function x2 under conditions x3",
  ),
  EntryGismuEnglish(
    word: "zo'a",
    keyword: "tangential to",
    hint: "",
    definition: "location tense relation/direction; tangential to/passing by ...",
  ),
  EntryGismuEnglish(
    word: "zo'i",
    keyword: "inward",
    hint: "",
    definition: "location tense relation/direction; nearer than .../inward/approaching from ...",
  ),
  EntryGismuEnglish(
    word: "zu'o",
    keyword: "activity abstract",
    hint: "",
    definition: "abstractor: activity (event) abstractor; x1 is abstract activity of [bridi] " &
        "composed of x2",
  ),
  EntryGismuEnglish(
    word: "zukte",
    keyword: "act",
    hint: "",
    definition: "x1 is a volitional entity employing means/taking action x2 for purpose/goal " &
        "x3/to end x3",
  ),
  EntryGismuEnglish(
    word: "zumri",
    keyword: "maize",
    hint: "",
    definition: "x1 is a quantity of maize/corn [grain] of species/strain x2",
  ),
  EntryGismuEnglish(
    word: "zungi",
    keyword: "guilt",
    hint: "",
    definition: "x1 feels guilt/remorse about x2 (abstraction)",
  ),
  EntryGismuEnglish(
    word: "zunle",
    keyword: "left",
    hint: "",
    definition: "x1 is to the left/left-hand side of x2 which faces/in-frame-of-reference x3",
  ),
  EntryGismuEnglish(
    word: "zunti",
    keyword: "interfere",
    hint: "'hinder'",
    definition: "x1 (evt./state) interferes with/hinders/disrupts x2 (evt./state/process) due to " &
        "quality x3 (ka)",
  ),
  EntryGismuEnglish(
    word: "zutse",
    keyword: "sit",
    hint: "",
    definition: "x1 sits [assumes sitting position] on surface x2",
  ),
  EntryGismuEnglish(
    word: "zvati",
    keyword: "at",
    hint: "",
    definition: "x1 (object/event) is at/attending/present at x2 (event/location)",
  ),
]
  ## Every entry of gismu list, in its order.
