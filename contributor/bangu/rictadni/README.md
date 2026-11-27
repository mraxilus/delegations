# rictadni

The name `rictadni` is a lujvo of the tanru `tricu tadni`, tree and study. It means a
dendrologist, a person who studies trees. `tagger read rictadni` reads it as the tag `tricu+tadni`.

A system that tags anything with lojban words and finds it again. A tag is a gismu or a lujvo.
The project `ricyso'o` reads each tag, and this project reduces it to the words of its tanru.

A search matches on its gismu. So a search for one gismu finds every thing whose tag holds that
gismu, alone or inside a lujvo. A search for a lujvo with a cmavo, such as `selci'a`, lists first
each thing whose tag holds it, net of the cmavo around it. So `selci'avei` comes first, but
`selselci'a` does not, because its two `se` cancel.

A search can also use an English word. The keywords of the gismu list and the glosses of the
lujvo list lead that word to gismu.

```text
$ tagger tag notes/plan.md notci datnyvei
notes/plan.md    notci datnyvei
$ tagger find vreji
`vreji` reads as tag `vreji`.
notes/plan.md    notci datnyvei
$ tagger find file
`file` reads as English: datni+vreji (file (incl. computers)), datni+vreji+liste (file directory).
notes/plan.md    notci datnyvei
```

In this example, four spaces stand for the tab that separates a name from its tags.

## Authority

The authority is The Complete Lojban Language (CLL), by John Woldemar Cowan, first edition, 1997.
This project reads each word through the project `ricyso'o`, which replicates the morphology
of chapters 3 and 4. It also folds a tanru by the rules of chapters 5, 7, 9, 12 and 15. This
project replicates the tag of 4.5 and 4.11 itself. It also replicates how a group in chapters 5,
12 and 15 changes a run of tanru units, which a search ranks by. The suites carry the names of
those chapters, and each assertion cites its section.

The word lists come from the Logical Language Group, which placed them in the public domain.
This project commits the English of the gismu list, and the whole lujvo list, as typed Nim
modules under `src/rictadni/lists/`. The words and rafsi of the gismu list stand in
`ricyso'o`, as the Architect ruled.

## Build and test

```sh
nim r koch check                                  # from repository root: every check
nim r koch test contributor/bangu/rictadni        # this project alone
nim r tools/build.nim tagger                      # from project root: build binaries/tagger
nim r tools/build.nim suggester                   # build binaries/suggester, with TLS
nim r tools/build.nim examples                    # write worked examples of suggester
nim r tools/build.nim lists                       # write both lists again from lojban-common
nim r tools/build.nim head                        # compare committed lists with lojban-common
nim r tools/build.nim page                        # build tag page into build/page/tagger.html
nim r tools/build.nim drive                       # build tag page, run its suite, collect it
```

The build needs the compiler that `rictadni.nimble` pins, and `libssl3`, because
`suggester` and the suites compile with TLS. The suites also run the command `openssl`, which
makes a test root for each run, and they need `protoc` to compile. `suggester` needs
`ca-certificates` when it runs. The verbs `lists` and `head` also need the Debian package
`lojban-common`. The verb `system` declares all of them.

Every build also needs the Nim package `ricysoho`, at the commit that `atlas.lock` pins.
`suggester`, the verb `examples` and the suites also need the Nim package
`protobuf_serialization`, which the lock pins too. `nim r koch fetch-deps
contributor/bangu/rictadni` restores both under `dependencies/`, and `nim r koch test` does
so before it runs the suites.

## Use

`tagger` keeps its index in one text file. The option `--index:<path>` names it. Otherwise the
variable `RICTADNI_INDEX` names it, and otherwise it is `rictadni/index` under the data
directory of the user. The tagger still reads the names that it had before the rename. It reads
`LOJBAN_TAGGER_INDEX` where `RICTADNI_INDEX` is unset or empty, and `lojban_tagger/index` where
the new folder holds no index. The first change writes the new folder, and the old file stays as
it is.

- `tag <name> <word>...` adds tags to a thing. A path, a URL or a title is a name.
- `untag <name> <word>...` removes tags.
- `find <term>...` prints each thing that any term finds. The things that meet every term come
  first, then the things that meet one term fewer, and so on. Things that meet the same number of
  terms keep the rank of a lujvo with a cmavo, then the order of the index. A term is a gismu, a
  lujvo or an English word. The report names each term that finds nothing.
- `show [<name>]` prints things with their tags.
- `read <word>...` explains a word: its rafsi, its gismu, its preferred form and its English.

## Suggest

`suggester` asks a language model service for the tags of a text, or of the page at a URL. Each
tag is a gismu that a person might search by to find the text again, even a person who forgets
its title. The model decides how many tags a text needs, and puts the most likely search first.
The tool reads at most the first 32 elements of the answer, and prints each gismu on its own line:

```sh
tagger tag notes/plan.md $(binaries/suggester - < notes/plan.md)
page=https://www.gutenberg.org/ebooks/11
tagger tag "$page" $(binaries/suggester "$page")
```

The command substitution has no quotes, so the shell splits the lines into words. A gismu has
five letters, so no space and no glob character can enter. If you want fewer tags, cut the list,
for example with `binaries/suggester "$page" | head -n 10`.

The argument `-` reads the text from standard input. Use it for a long or private text, because
every user of the machine can read the command line of a process.

The model answers with a list. The tool checks each element of that list against the gismu list.
It drops an element that is not one of those gismu, such as a lujvo, a cmavo or an unknown word.
It also drops a gismu that an earlier element gave. The report names each dropped element by its
position, and the tool keeps the rest. If the tool keeps no gismu, it exits 1.

A text of at most 64 bytes that reads as a tag of at most six words asks no service, and needs no
key. The tool then prints the gismu of that tag, and leaves out its cmavo.

Usage: `suggester [--record:<directory>|--replay:<directory>] [--] <text>...|<url>|-`, or
`suggester [--record:<directory>|--replay:<directory>] --serve[:<port>]` for the tag page.

Before `--`, a word that starts with `-` and is no flag is a usage error, wherever it stands. So
a mistyped flag never sends a paid request. Put `--` before a text that holds such a word.

| Variable | Default | Effect |
|---|---|---|
| `RICTADNI_SERVICE` | `claude` | `claude`, `openrouter`, or `chat` for another server |
| `RICTADNI_ENDPOINT` | the URL of the service | `chat` needs one |
| `RICTADNI_MODEL` | `claude-sonnet-5-5`, or `anthropic/claude-sonnet-5.5` | `chat` needs one |
| `RICTADNI_EFFORT` | `xhigh`, none for `chat` | `low`, `medium`, `high`, `xhigh` or `max` |
| `RICTADNI_API_KEY` | none | The key, read first |
| `RICTADNI_WORKSPACE` | none | Workspace ID for a key that no workspace scopes |

Each variable still reads under its name before the rename, as `LOJBAN_TAGGER_MODEL` for
`RICTADNI_MODEL`, where the variable of the new name is unset or empty.

Where `RICTADNI_API_KEY` and `LOJBAN_TAGGER_API_KEY` are both unset, `claude` reads
`ANTHROPIC_API_KEY`, and `openrouter` reads `OPENROUTER_API_KEY`. Each reads that name only for
the host of its default endpoint. So a key that you set for other tools never goes to another
host. The report names the variable that it read, and never the key. Put the key in the
environment, never on the command line.

Get a Claude key at `https://platform.claude.com/settings/keys`, and scope it to one workspace
when you create it. Otherwise, set `RICTADNI_WORKSPACE` to the ID of the workspace, which
starts with `wrkspc_`. Get an OpenRouter key at `https://openrouter.ai/settings/keys`.

The tool reads `https_proxy`, `HTTPS_PROXY`, `http_proxy`, `no_proxy` and `NO_PROXY` as curl
reads them, and a proxy with no port takes port 1080. A proxy with no scheme takes `http://`, and
a proxy with a scheme must use `http://`. For an https URL, the proxy must hold no user name or
password. The client would also send them to the host behind the proxy.

- `--record:<directory>` writes each reply to a file. A later run replays a page reply of 2xx or
  3xx, and a service reply that holds an answer of the model. It sends other requests again, such
  as a refusal or an error that the service reports.
- `--replay:<directory>` reads every reply from files. It needs no key and no network.
- An exchange file holds the text and the reply, so the tool makes the directory with mode 0700,
  and writes each file with mode 0600. It refuses a directory that every user may write, such as
  `/tmp`, and a link at the path of an exchange file.
- An exchange holds its endpoint too, so it replays only for that endpoint.
- `nim r tools/build.nim examples` writes worked examples to `build/examples/`, and prints the
  command that replays each one. Their replies are documented shapes, not live replies.

### Exchange files

An exchange file holds one request and its reply. It starts with a frame of 28 bytes: the line
`rictadni exchange 2`, then the length and the CRC-32C of the message, in four bytes each.
The message follows, in the Protocol Buffers format that `app/exchanges.proto` gives. The tool
checks the frame before it reads the message, so it refuses a file that is cut or changed. A
file written before the rename opens with `lojban_tagger exchange 2`, in a frame of 33 bytes, and
the tool still reads it.

To read a file, give its message to `protoc`. Run this command from the folder of the project:

```sh
tail -c +29 build/examples/390a130dbd59a40f.exchange |
  protoc --decode=rictadni.Exchange app/exchanges.proto
```

The command prints the first hop of the example `page` as text. `app/exchanges_example.txtpb`
holds the same text. `head -n 1` prints the line that names the format.

## Pages

The tag page takes a pasted text and shows the gismu that a person might search by to find it.
It has two front ends, which share one source, `pages/tagger.html`:

- **On your machine.** Build the page, then serve it from the project folder:

  ```sh
  nim r tools/build.nim page
  binaries/suggester --serve
  ```

  Open `http://127.0.0.1:8461/`. The form sends each text to `suggester` itself, with your key
  and the default model, and the page shows the gismu and the report. `--serve:<port>` takes
  another port, and `RICTADNI_PAGE` names another built page. The server answers only requests
  of its own host and origin, and no other site may frame it. It has no token, so each user of
  your machine can spend your key through it.
- **As an Artifact on claude.ai.** The published page is at
  `https://claude.ai/artifact/VCrXVVid41EzZSx67N9SCr`, and only its owner can open it. It asks
  Opus 5.5 at effort `high` through the Claude usage of the viewer, and needs no key.

Both front ends read each answer with the reader of `suggester`, compiled to JavaScript for the
page.

## Status

The tag page serves on your machine, and a suite posts a text to it and reads the report back.
`nim r tools/build.nim drive` runs a suite of the page in Chromium. Its Artifact has not asked
Claude live yet, so the answers of Opus at `high` without a schema are unmeasured.

The tags, the index, the search and the command line work, and the suites hold them to CLL. They
read each word through `ricyso'o`.

`suggester` works on recorded replies. On 2026-10-31, it read a live page,
`https://www.gutenberg.org/ebooks/11`, through the HTTP proxy of a sandbox with TLS. On
2026-11-26, it read one live reply of the Messages API through the proxy of a cloud sandbox. A
text of 125 bytes gave 14 gismu, and the replay of that exchange file gave the same 14. Nothing
here has been read line by line by a human.
