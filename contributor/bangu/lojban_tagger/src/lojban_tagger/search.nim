## Find tagged entities by terms, each read as Lojban tag or as English, reduced to gismu.
##
##   Term reads as Lojban first (`tags.nim`), else as English (`dictionary.nim`). Either way it
##     becomes alternatives: gismu sets, any one of which satisfies term. Lojban gives one
##     alternative, gismu of its tanru; English gives one per meaning it leads to.
##   Entity satisfies term where every gismu of one alternative appears in any of its tags;
##     query is satisfied where every term is (conjunction). So `vreji` finds `datnyvei`, and
##     `datnyvei` finds what `datni` and `vreji` tag together.
##     Rejected: matching tags whole, which would make lujvo invisible to search for its gismu,
##     and lose recall Architect asked for ("all tagged entities come up").
##     Cost: order and relation of gismu are lost; `patfu mamta` and `mampa'u` hold one set,
##     so each finds other (CLL 4.5 calls tanru ambiguous for same reason).
##   Term reading as neither Lojban nor known English holds no alternative, so query finds
##     nothing; caller reports term, so empty result says why.
##   Cost: every entity tested against every term; index of shell tool is read whole anyway,
##     so linear walk costs no more than reading it (unmeasured).

{.experimental: "strictFuncs".}

import std/[algorithm, sequtils]

import ./[dictionary, english, index, tags]


type
  Term* = object  ## Define one term of query, as read.
    reading*: Reading  ## Term read as Lojban tag, refused or not.
    meanings*: seq[Meaning]  ## Meanings term leads to as English; empty where Lojban read.
    alternatives*: seq[seq[Word]]  ## Gismu sets, any one of which satisfies term.


func readTerm*(text: string): Term =
  ## Read term as Lojban tag, else as English.
  result.reading = text.readTag
  if result.reading.is_tag:
    result.alternatives = @[result.reading.tag.words.deduplicate.sorted]
    return
  result.meanings = text.meanings
  for meaning in result.meanings:
    let alternative = meaning.words.deduplicate.sorted
    if alternative notin result.alternatives: result.alternatives.add alternative


func words*(entity: Entity): seq[Word] =
  ## Gather every gismu any tag of entity holds, sorted, none twice.
  for tag in entity.tags: result.add tag.words
  result = result.deduplicate.sorted


func isSatisfying*(entity: Entity, term: Term): bool =
  ## Test entity holds every gismu of some alternative of term.
  let held = entity.words
  term.alternatives.anyIt(it.allIt(it in held))


func find*(index: Index, terms: openArray[Term]): seq[Entity] =
  ## Find every entity satisfying every term, in order of index; none where no term given.
  if terms.len == 0: return
  for entity in index.entities:
    if terms.allIt(entity.isSatisfying(it)): result.add entity
