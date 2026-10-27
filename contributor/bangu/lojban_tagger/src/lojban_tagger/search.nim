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
##   Matching reads gismu alone, so `selci'a` finds what `ciska` finds. Lojban term holding cmavo
##     also ranks first each entity holding tag whose tanru units hold tanru units of term
##     unbroken, in order (`tanru_units.nim`). Architect ruled that search for `selci'a` lists
##     first each entity whose tag holds `se` right before `ciska`, wherever pair stands, as
##     `selci'a`, `selci'avei` and `veirselci'a` do; that net result of cmavo around pair
##     decides; that longer term ranks by unbroken run too; and that search for `ciska` gives
##     no priority. English term ranks nothing, as Architect ruled, since ruling on rank names
##     term typed in Lojban: word may lead to several meanings, and one holding cmavo would rank
##     what user may not mean, as `writing` would rank jokes by `xajmi se finti`.
##     Tanru units, not words: SE binds only following brivla or "equivalent unit" (CLL 9.4),
##     so `se ciska` is one tanru unit wherever it stands, and folding gives what cmavo around
##     it do. `selselci'a` holds words `se ciska` yet folds to `ciska`, since two `se` cancel
##     (12.11); `selkemci'avei` holds no such tanru unit, since there `se` converts whole
##     group. Run that group around it changes does not rank: its head, where conversion or
##     abstraction binds group (5.11, 12.12), any part, where negation binds it (15.4), and run
##     whose open group runs on in tag. So term `selci'avei` ranks no `selselci'avei`, converse
##     of `selci'avei`.
##     Run, not part of grouped tanru: lujvo makers often leave `ke` out (4.10, 12.11), so rafsi
##     often leave grouping out, and run is what they hold. So term `selci'avei` ranks tag
##     `vreta se ciska vreji`, where left grouping (5.3) binds `vreta` to `se ciska` first.
##     Term whose cmavo all fold away, as `selselci'a`, ranks nothing, as gismu term does.
##     Cost: rank is two tiers, ranked then rest, each in order of index.
##   Term reading as neither Lojban nor known English holds no alternative, so query finds
##     nothing; caller reports term, so empty result says why.
##   Cost: every entity tested against every term; index of shell tool is read whole anyway,
##     so linear walk costs no more than reading it (unmeasured).

{.experimental: "strictFuncs".}

import std/[algorithm, sequtils]

import ./[dictionary, english, index, tags, tanru_units]


type
  Term* = object  ## Define one term of query, as read.
    reading*: Reading  ## Term read as Lojban tag, refused or not.
    meanings*: seq[Meaning]  ## Meanings term leads to as English; empty where Lojban read.
    alternatives*: seq[seq[Word]]  ## Gismu sets, any one of which satisfies term.
    specific*: seq[TanruUnit]
      ## Tanru units of Lojban term holding cmavo, which rank entities first; empty where
      ##   term holds none, or where its cmavo all fold away.


func readTerm*(text: string): Term =
  ## Read term as Lojban tag, else as English.
  result.reading = text.readTag
  if result.reading.is_tag:
    let
      tag = result.reading.tag
      folded = tag.tanruUnits
    result.alternatives = @[tag.gismu.deduplicate.sorted]
    if folded.anyIt(it.links.len > 0 or it.word.kind == Kind.Cmavo): result.specific = folded
    return
  result.meanings = text.meanings
  for meaning in result.meanings:
    let alternative = meaning.words.filterIt(it.kind == Kind.Gismu).deduplicate.sorted
    if alternative notin result.alternatives: result.alternatives.add alternative


func words*(entity: Entity): seq[Word] =
  ## Gather every gismu any tag of entity holds, sorted, none twice.
  for tag in entity.tags: result.add tag.gismu
  result = result.deduplicate.sorted


func isSatisfying*(entity: Entity, term: Term): bool =
  ## Test entity holds every gismu of some alternative of term.
  let held = entity.words
  term.alternatives.anyIt(it.allIt(it in held))


func isRanked*(entity: Entity, terms: openArray[Term]): bool =
  ## Test entity holds tag whose tanru units hold specific tanru units of some term unbroken
  ##   and unchanged.
  for term in terms:
    if entity.tags.anyIt(it.tanruUnits.isHoldingUnchanged(term.specific)): return true
  false


func find*(index: Index, terms: openArray[Term]): seq[Entity] =
  ## Find every entity satisfying every term: ranked ones first, then rest, each tier in order
  ##   of index; none where no term given.
  if terms.len == 0: return
  var rest: seq[Entity]
  for entity in index.entities:
    if not terms.allIt(entity.isSatisfying(it)): continue
    if entity.isRanked(terms): result.add entity
    else: rest.add entity
  result.add rest
