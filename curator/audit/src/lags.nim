## Name each commit of `atlas.lock` that names folder of this repository and lags base, in lines
##   that fail nothing (D2 of #927).
##   Item of lock names this repository where its address, query cut and `.git` or `/` dropped,
##     is `ADDRESS_REPOSITORY`. Its folder is `subdir` of that query, percent-decoded: name
##     override of `atlas.config` maps package to it, and Atlas writes it into lock so. Address
##     with no folder names whole repository, which Atlas reads as no one package, so it names
##     no item here.
##   Lag is count of commits of base that changed folder outside its records (`FILES_PROJECT`)
##     since commit of lock: `git rev-list --count <commit>..<base> -- <folder>`, each record
##     left out by `:(exclude)`. Count of commits is Architect's ruling; records left out is
##     curator's choice, since re-stamp writes stamp row into record of every project and no
##     code. Record of project keeping its own prose is left out too, though plan reads it as
##     code (`prose_own.nim`): its own suite reads it, and no project that locks it compiles it.
##   Folder base no longer holds moved or went; line says so, and names last commit of base that
##     changed folder, which removed it, where git names one, since count of such folder says
##     nothing of where it went.
##   Commit git lacks, as of branch no fetch brought, leaves count unread, and its line says so.
##     Base git lacks names no lag at all, since each commit would read as lacked.
##   Lines, never finding: lag is work of project holding lock, which moves lock when it wants
##     what changed, and lock that lags builds as it did. `koch check` prints them against
##     `origin/main`, and `start` hook prints same lines, since both print `noticesLag`.
##
##   Rejected: plain count of each commit that changed folder, which re-stamp alone moves.
##   Cost: record that code of package reads, as by `staticRead`, changes what lock builds, and
##     counts nothing.
##   Cost: git lists tree once and reads base once, then runs twice for each item of this
##     repository, and once more for each item whose folder base no longer holds.
##   Cost: address of this repository is named here once; fork or rename of repository names
##     another, and notice falls silent.

{.experimental: "strictFuncs".}

import std/[json, options, os, strutils, uri]
import ../../knoller/src/knoller
import ./[layout, tree]


const  # TODO: Document.
  ADDRESS_REPOSITORY* = "https://github.com/mraxilus/delegations"
    ## Address of this repository, as lock names package that one of its folders holds.
  KEY_FOLDER = "subdir="  ## Key of query naming folder of repository that package stands in.
  MAGIC_EXCLUDE = ":(exclude)"  ## Magic of git pathspec leaving path out of what others name.
  WIDTH_COMMIT = 9  ## Characters of commit that line shows, as records of this repository do.


type  # TODO: Document.
  Locked* = object  ## Define one item of lock that names folder of this repository.
    lock*: string  ## Lock holding item, repository-relative.
    name*: string  ## Name of item, as lock keys it.
    folder*: string  ## Folder of this repository item names, from `subdir` of its address.
    commit*: string  ## Commit item holds, as lock writes it.

  Lag* = object  ## Define what base did to folder of locked item since its commit.
    locked*: Locked  ## Item of lock.
    count*: Option[int]
      ## Commits of base that changed folder outside its records since commit of item; none
      ##   where git cannot count.
    is_held*: bool  ## Base holds folder.
    gone*: Option[string]
      ## Last commit of base that changed folder it no longer holds, short; none where base
      ##   holds folder, or git names none.


func trimmed(address: string): string =
  ## Read address with no query, `.git` or closing `/`, so two spellings of one repository agree.
  result = address.split('?')[0]
  result.removeSuffix('/')
  result.removeSuffix(".git")
  result.removeSuffix('/')


func pathsCode(folder: string): seq[string] =
  ## Name folder as pathspecs of git that leave out its records, so commit changing record alone
  ##   changes none of them.
  result = @[folder]
  for record in FILES_PROJECT: result.add MAGIC_EXCLUDE & folder & "/" & record


proc itemsRepository*(path, lock: string): seq[Locked] =
  ## Read each item of lock whose address names folder of this repository, in order lock holds.
  ##   Lock that will not parse names none, since `checkNimbleLock` reports it.
  var node: JsonNode
  try: node = parseJson(lock)
  except CatchableError: return
  if node.kind != JObject or node{"items"}.isNil or node["items"].kind != JObject: return
  for name, item in node["items"]:
    let address = item{"url"}.getStr
    if '?' notin address or address.trimmed != ADDRESS_REPOSITORY: continue
    var folder = ""
    for part in address.split('?', 1)[1].split('&'):
      if part.startsWith(KEY_FOLDER):
        folder = part[KEY_FOLDER.len .. ^1].decodeUrl.strip(chars = {'/'})
    if folder.len == 0: continue
    result.add Locked(lock: path, name: name, folder: folder, commit: item{"commit"}.getStr)


proc readLags*(root, base: string): seq[Lag] =
  ## Read what base did since commit of each item of each lock of tree that names folder of this
  ##   repository: commits that changed folder outside its records, whether base holds it, and
  ##   where it went.
  ##   Base git lacks, as where fetch failed or no `origin` stands, names no lag: each item would
  ##     read as commit git lacks, which names wrong cause.
  ##   Read of git that fails leaves its field as it stood, so line says what stays unread.
  try: discard fieldsGit(root, ["rev-parse", "--verify", "--quiet", base & "^{commit}"])
  except IOError: return
  for path in root.listPaths:
    if path.extractFilename != FILE_LOCK: continue
    for locked in itemsRepository(path, readFile(root / path)):
      var lag = Lag(locked: locked, is_held: true)
      try: lag.is_held = fieldsGit(root, ["ls-tree", base, "--", locked.folder]).len > 0
      except IOError: discard
      try:
        let range = locked.commit & ".." & base
        lag.count = some(
          fieldsGit(root, @["rev-list", "--count", range, "--"] & locked.folder.pathsCode)[0]
            .strip.parseInt
        )
      except IOError, ValueError: discard
      if not lag.is_held:
        try:
          let last = fieldsGit(root, ["log", "-1", "--format=%h", base, "--", locked.folder])
          if last.len > 0: lag.gone = some(last[0].strip)
        except IOError: discard
      result.add lag


func noticesLag*(lags: openArray[Lag], base: string): seq[string] =
  ## Render heading, then one line for each item whose folder base changed outside its records
  ##   since its commit, no longer holds, or git cannot count against; empty where none lags.
  for lag in lags:
    let
      item = lag.locked
      head = "  " & item.lock & ": `" & item.name & "` at `" &
        item.commit[0 ..< min(WIDTH_COMMIT, item.commit.len)] & "`"
    if not lag.is_held:
      let at =
        if lag.gone.isSome: " at `" & lag.gone.get & "`" else: ", at commit git cannot name"
      result.add head & " names `" & item.folder & "`, which `" & base &
        "` no longer holds: it moved or went" & at & "."
    elif lag.count.isNone:
      result.add head & " names commit git lacks, so its lag behind `" & base & "` is unread."
    elif lag.count.get > 0:
      let commits = if lag.count.get == 1: " commit that changes `" else: " commits that change `"
      result.add head & " lags `" & base & "` by " & $lag.count.get & commits & item.folder &
        "` outside its records."
  if result.len == 0: return
  result.insert(
    "Commits of `atlas.lock` that name folder of this repository and lag `" & base &
      "`; they fail nothing, and project moves its lock when it wants what changed " &
      "(GUIDE.md, How to add a dependency):",
    0,
  )
