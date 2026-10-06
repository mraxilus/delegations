# knoller

The fixers and the checks of Nim source that read the text of one file alone. The checks are
those that the fixers clear, and those of form, names, idioms, articles and fixed waits that the
static pass of `curator/audit` reads. `koch fix` runs the fixers through `curator/audit`, which
keeps each fixer that asks the compiler. `audit` imports knoller by a relative path. Knoller also
runs alone, on a file or a directory of any repository.

Authority replicated: none. The rules are those of `CONSTITUTION.md` and `STYLE.md`.

## Use

```sh
knoller [--check] [--nim:path] path...
```

- A path names a file or a directory. A directory stands for the `.nim`, `.nims` and `.nimble`
  files that `git ls-files` lists under it. What git writes on stderr never reaches a path.
- A directory that gives no Nim file is a usage error. Its message says why: the directory is
  outside a git work tree, or git lists no Nim file under it.
- Knoller reads each path whole, from the directory where you run it. So a test file, a stub and
  an umbrella get the same rules from any directory. The output prints each path as you name it.
- Knoller writes only the files that change. With `--check`, it writes no file and reports each
  change that is due.
- After the fix, every check reads the text that the fixers leave. Each finding there is `left`,
  and fails the run. A fence keeps its lines from the fixers, and never from these findings.
- The names check takes no word as exempt beyond the jargon of V.6. A caller such as `koch` adds
  the words that its glossaries list. The check of fixed waits reads each file under a directory
  `tests` or `tools`, at any depth.
- Knoller passes over a nimble file whose copy `atlas.lock` holds, because a rewrite would leave
  that copy stale.
- A group of needless parentheses goes only where the parser of the compiler reads the same tree
  without it. Knoller takes that compiler for each file in this order:
  1. the compiler that `--nim` names;
  2. else the compiler of the pin in the nearest nimble file at or above the directory of the
     file, written `requires "nim == <pin>"` or `requires "nim#<commit>"`;
  3. else `nim` on `PATH`.
- So the `ronri` projects take their commit pin with no option. That matters, because 2.2.12 lexes
  their glyph operators as names. `koch fix` passes the pin of each project too. For a file at
  the root, koch takes the pin of `curator/audit`, and knoller takes `nim` on `PATH`.
- Knoller takes the compiler of a pin from `PATH` where that one serves it, else from
  `~/.cache/knoller/nim/<pin>/`. Else it fetches a release, or builds a commit, into that cache.
  `$KNOLLER_NIM_DIR` moves the cache, for koch too. The first run on a new pin pays the fetch, in
  seconds, or the build, in minutes, once. What a fetch prints goes to stderr, so the output below
  is all that stdout holds.
- Where no compiler answers, knoller removes no parentheses in those files and prints one warning
  that says why. A pin that no compiler serves gives that warning, and so does a directory that
  holds more than one nimble file. Knoller never takes another compiler in silence.
- Knoller has no style option. A fence, from a line `#!fix off` to a line `#!fix on`, keeps its
  lines as written. Each run prints one warning for each fence, which names each rule that breaks
  inside it. So you always see what the fence keeps, and knoller writes none of it.

Each line of output names a path, a line and a rule id, and the output is sorted in that order:

```text
path:line: <rule-id> fixed
path:line: <rule-id> left: <message>
path:line: fence-held warning: <message>
needless-parentheses warning: <message>
N fixed.
```

With `--check`, each `fixed` reads `to fix`. A finding that no fix clears is `left`.

Each line number is a line of the file as given, for a finding left too. A line that the fix
inserts has no such number. So a finding there prints with the path alone, as a finding of the
whole file does, and its message gives its text.

The message of a warning names each rule that breaks inside the fence, in the order of the table
under Rules. It gives the count and the first line of each, as in `inside them expression-spacing
breaks 2 times from line 6 and call-wrapping once at line 7`. A clean fence reads `nothing inside
breaks a rule`. The message ends with the lines that the fence keeps, markers included. A rule
that a fixer clears and a rule left for the hand count alike.

A warning changes no exit code. The exit codes are these:

- 0 for a clean run;
- 1 where a finding is left, or where a change is due under `--check`;
- 2 for a usage error.

## Rules

Each rule id is stable, so a tool can read the output. Each line names its rule by the id, and a
message names no article of a charter. A message reads `<sentence>; got <value>.`, or
`<sentence>.` where it gives no value. A caller such as `koch` adds the article of each rule where
the sentence ends, as in ``Bracket import is alphabetised (X.5); got `strutils, os`.``.

| Id | Rule |
|----|------|
| `trailing-whitespace` | A line ends in no space, tab or carriage return. |
| `file-ending` | A file ends in exactly one newline, so an empty file breaks it. |
| `line-ending` | A line holds no carriage return. No fix reaches it. |
| `tab-in-string` | A tab inside a plain string on one line is written `\t`. |
| `tab` | A line holds no tab. A fix reaches a tab in a plain string alone. |
| `line-width` | A line holds at most 100 characters, where a break can fix it. |
| `trailing-comment` | Two spaces stand before the marker of a trailing comment. |
| `banner-spacing` | The blank lines beside a banner follow its tier. |
| `entry-block` | An entry block holds no binding, so its body moves into `proc main`. |
| `abbreviation` | A name coins no abbreviation, and its full word stands. |
| `acronym` | An acronym in a name stays only where a glossary lists it. |
| `action-verb` | An action is an imperative verb, and a property is the bare noun. |
| `boolean-name` | A boolean opens `is_`, `as_`, `should_`, `found_` or `has_`, a predicate `is`. |
| `lookup-table` | A lookup table reads `lut_<value>_by_<key>`. |
| `name-case` | The case of a name follows its kind. |
| `member-case` | A member of an enum is `PascalCase`, as its type is. |
| `placeholder-letter` | A placeholder of a generic is one capital letter. |
| `notation` | The notation of the source holds over case only for an immutable global. |
| `global-word` | A global shares no word with a type. |
| `article-in-comment` | A comment holds no article. |
| `message-value` | A message echoes its value in backticks. |
| `and-with-or` | A condition that mixes `and` with `or` puts each `and` in parentheses. |
| `not-over-binary` | A `not` over a binary expression takes parentheses. No fix reaches it. |
| `needless-parentheses` | Parentheses go where the parser of the compiler reads the same tree. |
| `to-target-subject-first` | A `to<Target>` call takes its plain subject first. |
| `dotted-command` | A dotted call statement of one call or group argument takes command form. |
| `return-result` | A routine never ends on `return result`. |
| `bracket-import` | A bracket import is in alphabetical order. |
| `import-rank` | The standard library comes first, then packages, then local modules. |
| `import-brackets` | Adjacent imports of one directory share one bracket. |
| `module-bracket` | A bracket of one module drops its bracket. |
| `single-bindings` | Two or more single bindings share one keyword. |
| `strictfuncs` | A module carries `strictFuncs` before its imports. |
| `profiler-import` | An entry module imports the profiler on one line. |
| `stub-keys` | A test stub leaves out `-r`, `batchable` and `joinable`. |
| `used-consumer` | A `{.used.}` carries a comment that names its consumer. No fix reaches it. |
| `push-foreign` | A `{.push.}` stands over foreign bindings alone. No fix reaches it. |
| `random-seed` | A suite that imports `std/random` seeds it. No fix reaches it. |
| `stub-header` | A test stub carries a testament header. No fix reaches it. |
| `debug-output` | A test prints no value without a label, outside a condition. No fix reaches it. |
| `fixed-wait` | Drive code waits on a condition or a clock, and never sleeps. No fix reaches it. |
| `unordered-list` | A list that the language leaves unordered is in alphabetical order. |
| `test-blank-lines` | The blank lines beside a suite or a test follow its tier. |
| `helper-blank-lines` | A nested helper takes one blank line each side; one-line routines stack. |
| `doc-position` | A doc stands where the shape of its declaration puts it. |
| `literal-default` | A parameter with a literal default states no type. |
| `expression-spacing` | A space stands only where the expression rule puts it. |
| `parameter-separators` | Commas stand between parameters, and semicolons between groups. |
| `tuple-separators` | A tuple type takes commas between its fields. |
| `signature-wrapping` | A signature wraps its parameters only where it must. |
| `call-wrapping` | A call takes one argument to a line only where it must. |
| `operator-wrapping` | A line that fits nowhere else breaks after a binary operator. |
| `continuation-indent` | Each line past its statement line takes four spaces more than it. |
| `trailing-separator` | A list of one item to a line ends in a separator. |
| `comment-above` | A trailing comment that does not fit moves to its own line above. |
| `fence` | A fence closes inside the bracket, string or comment it opens in. No fix reaches it. |
| `fence-held` | A fence keeps its lines as written, and each run names what breaks inside it. |
| `unsettled` | A file that the fixers still change after their last round stays as written. |

## Build and test

```sh
nim c -o:knoller curator/knoller/src/knoller.nim  # from repository root: the command line
nim r koch test curator/knoller                   # this project alone: every suite, as one program
nim r koch check                                  # every check a pull request runs
```

This needs the compiler that the project pins in `knoller.nimble`, and git. To serve the pin of
another project, knoller may also need `curl`, `tar` and `sha256sum`, and a C compiler to build a
commit. `koch list-packages` names the packages that hold the first three.

## Published pages

None. Knoller publishes no page.

## Status

The fixers and the checks that read one file alone live here, with the command line, and the
compiler that serves each pin. A test that also reads a check of `audit` stays in its suites.
Unreviewed by a human.
