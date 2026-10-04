# knoller

The fixers of Nim source that read the text of one file alone, and the checks that those
fixers clear. `koch fix` runs them through `curator/audit`, which keeps each fixer that asks the
compiler. `audit` imports knoller by a relative path. Knoller also runs alone, on a file or a
directory of any repository.

Authority replicated: none. The rules are those of `CONSTITUTION.md` and `STYLE.md`.

## Use

```sh
knoller [--check] path...
```

- A path names a file or a directory. A directory stands for the `.nim`, `.nims` and `.nimble`
  files that `git ls-files` lists under it. Outside a git work tree, a directory names no file.
- Knoller writes only the files that change. With `--check`, it writes no file and reports each
  change that is due.
- Knoller passes over a nimble file whose copy `atlas.lock` holds, because a rewrite would leave
  that copy stale.
- Knoller has no style option. A fence, from a line `#!fix off` to a line `#!fix on`, keeps its
  lines as written. Each run prints one warning for each fence, which names each rule that breaks
  inside it. So you always see what the fence keeps, and knoller writes none of it.

Each line of output names a path, a line and a rule id, and the output is sorted in that order:

```text
path:line: <rule-id> fixed
path:line: <rule-id> left: <message>
path:line: fence-held warning: <message>
N fixed.
```

With `--check`, each `fixed` reads `to fix`. A finding that no fix clears is `left`.

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

Each rule id is stable, so a tool can read the output. `koch` cites the article of each rule.

| Id | Rule |
|----|------|
| `trailing-whitespace` | A line ends in no space, tab or carriage return. |
| `file-ending` | A file ends in exactly one newline. |
| `tab-in-string` | A tab inside a plain string on one line is written `\t`. |
| `trailing-comment` | Two spaces stand before the marker of a trailing comment. |
| `banner-spacing` | The blank lines beside a banner follow its tier. |
| `entry-block` | An entry block holds no binding, so its body moves into `proc main`. |
| `article-in-comment` | A comment holds no article. |
| `table-alignment` | A table column aligns by display width. |
| `message-value` | A message echoes its value in backticks. |
| `and-with-or` | A condition that mixes `and` with `or` puts each `and` in parentheses. |
| `not-over-binary` | A `not` over a binary expression takes parentheses. No fix reaches it. |
| `to-target-subject-first` | A `to<Target>` call takes its plain subject first. |
| `return-result` | A routine never ends on `return result`. |
| `bracket-import` | A bracket import is in alphabetical order. |
| `import-rank` | The standard library comes first, then packages, then local modules. |
| `import-brackets` | Adjacent imports of one directory share one bracket. |
| `single-bindings` | Two or more single bindings share one keyword. |
| `strictfuncs` | A module carries `strictFuncs` before its imports. |
| `profiler-import` | An entry module imports the profiler on one line. |
| `stub-keys` | A test stub leaves out `-r`, `batchable` and `joinable`. |
| `unordered-list` | A list that the language leaves unordered is in alphabetical order. |
| `test-blank-lines` | The blank lines beside a suite or a test follow its tier. |
| `helper-blank-lines` | A nested helper takes one blank line on each side. |
| `doc-position` | A doc stands where the shape of its declaration puts it. |
| `literal-default` | A parameter with a literal default states no type. |
| `expression-spacing` | A space stands only where the expression rule puts it. |
| `parameter-separators` | Commas stand between parameters, and semicolons between groups. |
| `tuple-separators` | A tuple type takes commas between its fields. |
| `signature-wrapping` | A signature wraps its parameters only where it must. |
| `call-wrapping` | A call takes one argument to a line only where it must. |
| `trailing-separator` | A list of one item to a line ends in a separator. |
| `fence` | A fence closes inside the bracket, string or comment it opens in. No fix reaches it. |
| `fence-held` | A fence keeps its lines as written, and each run names what breaks inside it. |

## Build and test

```sh
nim c -o:knoller curator/knoller/src/knoller.nim  # from repository root: the command line
nim r koch test curator/knoller                   # this project alone: every suite, as one program
nim r koch check                                  # every check a pull request runs
```

This needs the compiler that the project pins in `knoller.nimble`, and git.

## Published pages

None. Knoller publishes no page.

## Status

The fixers that read one file alone live here, with the command line. A test that also reads a
check of `audit` stays in the suites of `audit`. Unreviewed by a human.
