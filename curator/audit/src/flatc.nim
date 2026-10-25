## Build `flatc`, compiler of FlatBuffers schemas, at one pinned commit with curator's patch.
##   Data one program writes and another reads is FlatBuffers, as Architect ruled on #755:
##     schema is committed, and schema carries versions of format. `flatc` reads schema and
##     writes Nim and TypeScript that read and write buffers, and turns committed JSON text
##     into buffer.
##   Nim code of release 25.12.19 has faults, each found on records of this repository and
##     each still on upstream `master` of 2026-10-21. Patch here mends them, and nothing goes
##     upstream, as Architect ruled (D2 of #755):
##     - getter of table field reads field's own slot, where slot holds offset to table; any
##       table inside table, or list of tables, crashes reader;
##     - adder skips value equal to type's zero, where reader returns schema's default; hidden
##       object written `is_visible = false` reads back visible;
##     - adder of table field writes it as struct in place, and runtime quits;
##     - runtime writes no file identifier, so TypeScript reader checking it refuses Nim file;
##     - `-o` makes namespace folder under working directory and writes nothing, exit 0.
##   Each edit names exact text it replaces, found exactly once at pin, or build stops: pin
##     moved under patch is loud rather than half-patched.
##
##   Build is repository's, never one project's: one patch serves every project, and two
##     copies of patch would be copy no constraint forces (Article II.9). So store is koch's,
##     beside asset store, and CI caches it keyed on this file (`check.yml`).
##   Store is `$KOCH_FLATC_DIR`, else `~/.cache/koch/flatc`, outside checkout, since audit
##     reads untracked files. Build is named by commit and by digest of edits, so moved pin or
##     changed patch is different folder rather than stale one.
##   Build holds `bin/flatc` and `nim/flatbuffers`, Nim runtime of same commit with its own
##     edits; project imports runtime from there, so generator and runtime never disagree.
##   Built beside destination and moved in once complete, so half-built folder is never read
##     as finished one, as `assets.nim` keeps fetched file.
##
##   Rejected: Ubuntu's `flatbuffers-compiler`, 2.0.8, which predates Nim generator of
##     22.10.25. Rejected: patching generated Nim in each project's build, which second
##     `flatc` can stop matching without warning, and which each project would copy.
##   Cost: cold build clones about 20 MB and compiles for about 1 minute on 4 cores; `git`,
##     `cmake` and `g++` are shelled out to, and `koch list-packages` declares them.
##   Cost: patch is upstream text transcribed, since edit must name what it replaces; release
##     bump re-reads each edit against new pin, and build refuses edit that no longer matches.
##   Cost: Nim and TypeScript runtimes still verify nothing, and Nim enum getter still
##     crashes on value its enum lacks; format read from outside repository answers both.

{.experimental: "strictFuncs".}

import std/[hashes, options, os, osproc, strutils]


type
  Edit* = object  ## Define one exact replacement patch makes in one file of pinned source.
    path*: string  ## File, relative to root of clone.
    before*: string  ## Text found exactly once at pin.
    after*: string  ## Text put in its place.


const
  KEY_FLATC* = "KOCH_FLATC_DIR"  ## Environment name overriding where builds are stored.
  DIRECTORY_FLATC* = ".cache/koch/flatc"
    ## Default store, under home and outside checkout, in koch's own directory.
  REPOSITORY_FLATC = "https://github.com/google/flatbuffers"
    ## Upstream of `flatc` and of its Nim runtime.
  COMMIT_FLATC* = "7e163021e59cca4f8e1e35a7c828b5c6b7915953"
    ## Pin, i.e. release 25.12.19, latest release when patch was written.
  GENERATOR = "src/bfbs_gen_nim.cpp"  ## Nim generator of `flatc`, read from binary schema.
  BUILDER = "nim/flatbuffers/src/builder.nim"  ## Writer of Nim runtime.
  STRUCT = "nim/flatbuffers/src/struct.nim"  ## Reader of Nim runtime, opening buffer at root.
  EDITS* = [
    Edit(  # Table sits apart, and its slot holds offset to it; struct sits in place.
      path: GENERATOR,
      before: """
      case r::Obj: {
        return GenerateType(type, element_type) +
               "(tab: Vtable(Bytes: self.tab.Bytes, Pos: " + offset + "))";
      }""",
      after: """
      case r::Obj: {
        const r::Object* object = GetObject(type, element_type);
        const std::string position = object != nullptr && !object->is_struct()
                                         ? "self.tab.Indirect(" + offset + ")"
                                         : offset;
        return GenerateType(type, element_type) +
               "(tab: Vtable(Bytes: self.tab.Bytes, Pos: " + position + "))";
      }""",
    ),
    Edit(  # Skip value only where it equals default reader returns; optional always writes.
      path: GENERATOR,
      before: """
        code += "  builder.Prepend" + GenerateMethod(field) + "Slot(" +
                NumToString(field->id()) + ", " + variable_name + ", default(" +
                variable_type + "))\n";""",
      after: """
        const r::BaseType field_base = field->type()->base_type();
        std::string skipped = "default(" + variable_type + ")";
        if (IsScalar(field_base) && !field->optional()) {
          if (IsBool(field_base)) {
            skipped = DefaultValue(field);
          } else if (IsFloatingPoint(field_base)) {
            skipped = variable_type + "(" + DefaultValue(field) + ")";
          } else {
            skipped = variable_type + "(" + NumToString(field->default_integer()) + ")";
          }
        }
        if (IsScalar(field_base) && field->optional()) {
          code += "  builder.Prepend(" + variable_name + ")\n";
          code += "  builder.Slot(" + NumToString(field->id()) + ")\n";
        } else {
          code += "  builder.Prepend" + GenerateMethod(field) + "Slot(" +
                  NumToString(field->id()) + ", " + variable_name + ", " + skipped + ")\n";
        }""",
    ),
    Edit(  # Table field is offset, written by plain slot; struct alone sits in place.
      path: GENERATOR,
      before: """
  std::string GenerateMethod(const r::Field* field) const {
    const r::BaseType base_type = field->type()->base_type();
    if (IsStructOrTable(base_type)) {
      return "Struct";
    }
    return "";
  }""",
      after: """
  std::string GenerateMethod(const r::Field* field) const {
    if (IsStruct(field->type())) {
      return "Struct";
    }
    return "";
  }""",
    ),
    Edit(  # Root table finishes buffer with schema's identifier, and reads it back.
      path: GENERATOR,
      before: """
      code += "  return builder.EndObject()\n";
    }""",
      after: """
      code += "  return builder.EndObject()\n";
      const flatbuffers::String* identifier = schema_->file_ident();
      if (object == schema_->root_table() && identifier != nullptr &&
          identifier->size() > 0) {
        code += "const " + object_name + "Identifier* = \"" + identifier->str() + "\"\n";
        code += "proc " + namer_.Function(object_name + "Finish") +
                "*(builder: var Builder, root: uoffset) =\n";
        code += "  builder.Finish(root, " + object_name + "Identifier)\n";
        code += "func " + namer_.Function(object_name + "HasIdentifier") +
                "*(buf: string): bool =\n";
        code += "  buf.HasIdentifier(" + object_name + "Identifier)\n";
      }
    }""",
    ),
    Edit(  # Namespace folder goes under `-o`, where file is then saved.
      path: GENERATOR,
      before: "    EnsureDirExists(path);",
      after: "    EnsureDirExists(options_.output_path + path);",
    ),
    Edit(  # Writer places identifier after root offset, as Python runtime does.
      path: BUILDER,
      before: """
   this.Prep(this.minalign, uoffset.sizeof)
   this.PrependOffsetRelative(rootTable)
   this.finished = true""",
      after: """
   this.Prep(this.minalign, uoffset.sizeof)
   this.PrependOffsetRelative(rootTable)
   this.finished = true

proc Finish*(this; rootTable: uoffset; identifier: string) =
   if identifier.len != 4:
      quit("flatbuffers: file identifier must be 4 bytes")
   if this.nested:
      quit("builder is nested")
   this.nested = true

   this.Prep(this.minalign, uoffset.sizeof + identifier.len)
   this.Prep(uoffset.sizeof, identifier.len)
   for i in countdown(identifier.high, 0):
      this.Place(byte(identifier[i]))
   this.PrependOffsetRelative(rootTable)
   this.finished = true""",
    ),
    Edit(  # Reader tells file of its schema from any other by identifier.
      path: STRUCT,
      before: """
func GetRootAs*(result: var FlatObj; buf: string; offset: uoffset) =
   result.GetRootAs(cast[seq[byte]](buf), offset)""",
      after: """
func GetRootAs*(result: var FlatObj; buf: string; offset: uoffset) =
   result.GetRootAs(cast[seq[byte]](buf), offset)

func HasIdentifier*(buf: string; identifier: string): bool =
   buf.len >= uoffset.sizeof + identifier.len and
      buf[uoffset.sizeof ..< uoffset.sizeof + identifier.len] == identifier""",
    ),
  ]


func digestEdits*(edits: openArray[Edit]): string =
  ## Hash each edit's file and text into 16 hex digits, so changed patch is different build.
  var h: Hash = 0
  for edit in edits: h = h !& hash(edit.path) !& hash(edit.before) !& hash(edit.after)
  toHex(!$h)


const KEY_BUILD* = COMMIT_FLATC[0 ..< 12] & "-" & digestEdits(EDITS)
  ## Name build takes in store: short pin, then digest of patch.


func rootFlatc*(override: string): string =
  ## Read directory builds are stored under, override winning when set.
  if override.len > 0: override else: getHomeDir() / DIRECTORY_FLATC


func patched*(text: string; edit: Edit): Option[string] =
  ## Apply edit to text; none where its `before` is not found exactly once.
  if text.count(edit.before) != 1: return none(string)
  some(text.replace(edit.before, edit.after))


proc ran(command: string; arguments: openArray[string]): bool =
  ## Run command with arguments, printing its output to stderr where it fails.
  let (output, code) = execCmdEx(quoteShellCommand(@[command] & @arguments))
  if code != 0:
    stderr.writeLine "`" & command & " " & arguments.join(" ") & "` exited " & $code & ":"
    stderr.write output
  code == 0


proc buildFlatc(folder: string): bool =
  ## Clone pin, apply each edit, build `flatc`, keep binary and Nim runtime in `folder`.
  ##   False where any step fails, with reason on stderr; stdout stays path alone.
  let
    staging = folder & ".building"
    source = staging / "source"
    build = source / "build"
  removeDir(staging)
  createDir(source)
  defer: removeDir(staging)
  stderr.writeLine "Building flatc at " & COMMIT_FLATC & " with " & $EDITS.len &
    " edits; about 1 minute on 4 cores."
  if not ran("git", ["init", "-q", source]): return false
  if not ran("git", ["-C", source, "fetch", "-q", "--depth", "1", REPOSITORY_FLATC,
      COMMIT_FLATC]):
    return false
  if not ran("git", ["-C", source, "checkout", "-q", "FETCH_HEAD"]): return false
  for edit in EDITS:
    let changed = readFile(source / edit.path).patched(edit)
    if changed.isNone:
      stderr.writeLine "Edit of `" & edit.path & "` no longer matches pin exactly once; " &
        "re-read it against `" & COMMIT_FLATC & "`."
      return false
    writeFile(source / edit.path, changed.get)
  if not ran("cmake", ["-S", source, "-B", build, "-DCMAKE_BUILD_TYPE=Release",
      "-DFLATBUFFERS_BUILD_TESTS=OFF", "-DFLATBUFFERS_BUILD_FLATLIB=OFF",
      "-DFLATBUFFERS_BUILD_FLATHASH=OFF"]):
    return false
  if not ran("cmake", ["--build", build, "--target", "flatc", "--parallel",
      $countProcessors()]):
    return false
  createDir(staging / "bin")
  copyFileWithPermissions(build / "flatc", staging / "bin" / "flatc")
  copyDir(source / "nim" / "flatbuffers", staging / "nim" / "flatbuffers")
  removeDir(source)
  moveDir(staging, folder)
  true


proc flatcIn*(root: string): Option[string] =
  ## Read folder holding `bin/flatc` and `nim/flatbuffers`, building it where store lacks it.
  ##   Folder already present is trusted: name is pin and patch, and build moves in only
  ##   whole, so folder at that path was built from them.
  let folder = root / KEY_BUILD
  if fileExists(folder / "bin" / "flatc"): return some(folder)
  createDir(root)
  if buildFlatc(folder): some(folder) else: none(string)
