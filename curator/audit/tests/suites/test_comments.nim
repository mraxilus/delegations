## Replicate comment extraction claims of `comments.nim` header, per syntax.

{.experimental: "strictFuncs".}

import std/[options, random, sequtils, unittest]
import ../../src/[claims_log, comments, kinds]


const  # TODO: Document.
  SEED_TEXTS = 7  ## Seed of random texts that rows of log quote.
  COUNT_TEXTS = 2_000  ## Rows of log written, one for each random text.
  CHARS_TEXT = ['"', '\\', '\'', '#', ' ', 'a', '\t', '\n']
    ## Characters each text draws from: those that open, close or escape string, and others.


func texts(source: string, syntax: Syntax): seq[string] =
  ## Read comment texts only.
  comments(source, syntax).mapIt(it.text)


func lines(source: string, syntax: Syntax): seq[int] =
  ## Read comment lines only.
  comments(source, syntax).mapIt(it.line)



suite "Article VI":
  test "VI.5 Nim line and doc comments":
    check texts("x = 1 # note\n## doc\n### deep\n", Syntax.Nim) ==
      @["note", "doc", "deep"]  # marker runs stripped
    check lines("x = 1 # note\n\n## doc\n", Syntax.Nim) == @[1, 3]  # one-based lines


  test "VI.5 Nim string and char literals hide hashes":
    check texts("""a = "# not" # yes
""", Syntax.Nim) == @["yes"]  # plain string
    check texts("a = r\"C:\\#\"\"\" # yes\n", Syntax.Nim) == @["yes"]  # raw string with ""
    check texts("a = \"\"\"\n# inside\n\"\"\" # yes\n", Syntax.Nim) == @["yes"]  # triple string
    check texts("a = '#' # yes\n", Syntax.Nim) == @["yes"]  # char literal
    check texts("a = '\\n' # yes\n", Syntax.Nim) == @["yes"]  # escaped char literal
    check texts("a = 1'i32 # yes\n", Syntax.Nim) == @["yes"]  # numeric suffix quote
    check texts("discard \"\"\"\naction: run\n\"\"\"\n# after\n", Syntax.Nim) ==
      @["after"]  # testament header is string


  test "VI.5 Nim block comments nest and span lines":
    check texts("#[ Basis Conversion ]#\n", Syntax.Nim) == @["Basis Conversion"]  # banner
    check texts("#[ one\n two #[ inner ]# tail\n three ]# x = 1 # four\n", Syntax.Nim) ==
      @["one", "two inner tail", "three four"]  # nesting, per line, whitespace collapsed
    check texts("##[ doc block ]##\n", Syntax.Nim) == @["doc block"]  # doc block


  test "VI.5 cfg hash":
    check texts("hints:off # quiet\npath:\"a#b\" # yes\n", Syntax.Hash) ==
      @["quiet", "b\" # yes"]  # no string literals in cfg
    check texts("x = \\# literal\n", Syntax.Hash).len == 0  # escaped hash only


  test "VI.5 YAML hash after whitespace outside quotes":
    check texts("key: value # note\nurl: 'a#b' # yes\nq: \"x # y\"\n", Syntax.HashSpaced) ==
      @["note", "yes"]  # quotes hide hash
    check texts("key: a#b\n", Syntax.HashSpaced).len == 0  # unspaced hash is data
    check texts("# top\n  # indented\n", Syntax.HashSpaced) == @["top", "indented"]  # line start


  test "VI.5 hash after quote escaped in double quotes stays data, as in row of log (#1011)":
    check texts("text: \"wait \\\"once #980 merges\\\"\"\n", Syntax.HashSpaced).len ==
      0  # escaped quote keeps string open
    check texts("q: \"a\\\\\" # yes\n", Syntax.HashSpaced) == @["yes"]  # escaped backslash
    check texts("p: 'C:\\' # yes\n", Syntax.HashSpaced) == @["yes"]  # single quotes escape none


  test "VI.5 each row that writer of log writes holds no comment, whatever text it quotes":
    var
      rng = initRand(SEED_TEXTS)
      commented: seq[string]  # Rows whose scan finds comment.
    for _ in 1 .. COUNT_TEXTS:
      var text = ""
      for _ in 1 .. rng.rand(12): text.add rng.sample(CHARS_TEXT)
      let row = lineClaim(Claim(kind: "reviewer", text: text, result: text))
      if comments(row, Syntax.HashSpaced).len > 0: commented.add row
    check commented.len == 0  # writer quotes each string, so no `#` stands outside quotes


  test "VI.5 gitignore leading hash only":
    check texts("# note\nbin/ # not comment\n  # spaced\n", Syntax.HashLeading) ==
      @["note", "spaced"]  # first non-blank only


  test "VI.5 TypeScript slash forms":
    check texts("let a = 1; // one\n/* two */ let b = \"//\"; // three\n", Syntax.Slash) ==
      @["one", "two three"]  # line, block, string
    check texts("let s = `//${x}`; // yes\n", Syntax.Slash) == @["yes"]  # template literal
    check texts("/**\n * Doc line\n * more\n */\n", Syntax.Slash) == @["Doc line", "more"]  # stars
    check texts("let c = 'it\\'s'; // yes\n", Syntax.Slash) == @["yes"]  # escaped quote


  test "VI.5 protobuf schema and its text format comment forms":
    # Schema documents declaration with `//` line above it; record comments with `#`.
    const schema = "// Scene file.\nmessage Object {\n  string label = 3 [json_name = \"a//b\"];" &
      "  // shown\n  double radius = 4;  /* world units */\n}\n"
    check texts(schema, classify("scene.proto").get.rule.syntax) ==
      @["Scene file.", "shown", "world units"]  # line, line after string, block
    const record = "# Tour scene.\nobjects { label: \"a # b\"  # shown\n}\n"
    check texts(record, classify("tour.txtpb").get.rule.syntax) ==
      @["Tour scene.", "shown"]  # line, line after string holding `#`


  test "VI.5 markup comments span lines and repeat":
    check texts("<p>x</p><!-- note -->\n", Syntax.Xml) == @["note"]  # one comment
    check texts("<!-- one --><p>x</p><!-- two -->\n", Syntax.Xml) ==
      @["one two"]  # several on line, joined
    check texts("<!-- one\n  two -->\n<p>x</p>\n", Syntax.Xml) ==
      @["one", "two"]  # spanning lines, per line
    check texts("<p>plain</p>\n", Syntax.Xml).len == 0  # markup is not comment
    check texts("<svg><!--<circle/>--></svg>\n", Syntax.Xml) == @["<circle/>"]  # markup inside


  test "VI.5 none yields nothing":
    check texts("# looks like comment\n", Syntax.None).len == 0  # Markdown, JSON
