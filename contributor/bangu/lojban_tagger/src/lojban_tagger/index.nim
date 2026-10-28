## Hold tagged entities and their tags, and read and write them as one text file.
##
##   File holds one header line, then one line per entity: name, tab, then each tag as tanru
##     (`datni+vreji`), space apart. Entities sort by name, and tags keep order they were added.
##
##     lojban_tagger index 1
##     notes/plan.md<TAB>notci datni+vreji
##
##   Tag is stored as tanru, never as lujvo spelling: tanru is what tag is (`tags.nim`), and it
##     stays readable if scoring of 4.12 ever prefers other spelling.
##   Reader refuses whole file at first bad line, naming line and text, rather than keep part:
##     writer that kept part would drop rest of index on next write.
##   Name holds no tab, carriage return or line feed, and is otherwise any text: path, URL,
##     title. Rejected: JSON, which Architect asked to stop defaulting to; line format is typed
##     by its reader, which checks every tag against list.
##   Cost: shell tool reads and writes whole file per command; `seq` and `string` serve it,
##     which STYLE.md §4 admits for tool shell runs once. Lookup by name is binary search.

{.experimental: "strictFuncs".}

import std/[algorithm, options, sequtils, strutils]

import ./tags


type
  Entity* = object  ## Define one tagged thing: name, and its tags.
    name*: string  ## Name of thing, i.e. path, URL or title.
    tags*: seq[Tag]  ## Tags in order added, none twice.

  Index* = object  ## Define every tagged entity, sorted by name.
    entities*: seq[Entity]  ## Entities, names distinct and sorted.

  Loaded* = object  ## Define outcome of reading index file.
    case is_loaded*: bool
    of true:
      index*: Index  ## Index file holds.
    of false:
      line*: int  ## Line, counted from one, reader refused.
      problem*: string  ## What is wrong, ending in offending text.


const
  HEADER* = "lojban_tagger index 1"  ## First line of every index file, naming format and version.
  CHARACTERS_FORBIDDEN* = {'\t', '\r', '\n'}  ## Characters name may not hold.


func isNameValid*(name: string): bool =
  ## Test name is nonempty and holds no tab, carriage return or line feed.
  name.len > 0 and not name.anyIt(it in CHARACTERS_FORBIDDEN)


func position(index: Index, name: string): int =
  ## Find where entity named `name` is, or would be inserted.
  index.entities.lowerBound(name, proc (entity: Entity, key: string): int = cmp(entity.name, key))


func entity*(index: Index, name: string): Option[Entity] =
  ## Find entity named `name`; `none` where index holds none.
  let at = index.position(name)
  if at < index.entities.len and index.entities[at].name == name: some(index.entities[at])
  else: none(Entity)



#[ Changing ]#

func addTags*(index: var Index, name: string, tags: openArray[Tag]) =
  ## Tag entity named `name` with each tag it lacks; entity is made where index holds none.
  ##   No tag changes nothing, so no entity without tag is ever made, which reader would refuse.
  assert name.isNameValid, "Name should hold no tab or line break; got `" & name & "`."
  if tags.len == 0: return
  let at = index.position(name)
  if at == index.entities.len or index.entities[at].name != name:
    index.entities.insert(Entity(name: name), at)
  for tag in tags:
    if tag notin index.entities[at].tags: index.entities[at].tags.add tag


func removeTags*(index: var Index, name: string, tags: openArray[Tag]) =
  ## Remove each tag from entity named `name`; entity left with no tag is removed.
  let at = index.position(name)
  if at == index.entities.len or index.entities[at].name != name: return
  index.entities[at].tags.keepItIf(it notin tags)
  if index.entities[at].tags.len == 0: index.entities.delete(at)



#[ Text ]#

func toText*(index: Index): string =
  ## Render index as file text.
  result = HEADER & "\n"
  for entity in index.entities:
    result.add entity.name & "\t" & entity.tags.mapIt(it.toTanru).join(" ") & "\n"


func readIndex*(text: string): Loaded =
  ## Read file text as index; refuse at first bad line.
  let lines = text.splitLines
  if lines.len == 0 or lines[0] != HEADER:
    return Loaded(is_loaded: false, line: 1, problem: "Header should read `" & HEADER &
        "`; got `" & (if lines.len > 0: lines[0] else: "") & "`.")
  var index: Index
  for n in 1 ..< lines.len:
    let line = lines[n]
    if line.len == 0 and n == lines.high: break
    let fields = line.split('\t')
    if fields.len != 2 or not fields[0].isNameValid:
      return Loaded(is_loaded: false, line: n + 1, problem:
          "Line should hold name, tab, then tags; got `" & line & "`.")
    if index.entities.len > 0 and index.entities[^1].name >= fields[0]:
      return Loaded(is_loaded: false, line: n + 1, problem:
          "Names should be distinct and sorted; got `" & fields[0] & "`.")
    var entity = Entity(name: fields[0])
    for text_tag in fields[1].splitWhitespace:
      let tag = text_tag.readTanru
      if tag.isNone:
        return Loaded(is_loaded: false, line: n + 1, problem:
            "Tag should be gismu of list joined by `+`; got `" & text_tag & "`.")
      if tag.get notin entity.tags: entity.tags.add tag.get
    if entity.tags.len == 0:
      return Loaded(is_loaded: false, line: n + 1, problem:
          "Entity should hold at least one tag; got `" & fields[0] & "`.")
    index.entities.add entity
  Loaded(is_loaded: true, index: index)
