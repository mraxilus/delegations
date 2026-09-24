**Role:** <!-- Write `curator`, `curator/<project>` or `contributor/<domain>/<project>`, the
role that your branch names. Label this pull request with that same string. Copy it, and never
compose it. -->

## Intent

<!-- One paragraph: what changes, and why. The title follows `type(scope): summary`. -->

## Scope

- Branch: `contributor/<domain>/<project>/<name>`, `curator/<project>/<name>` or `curator/<name>`
- Anything that the `check-scope` job allows and a reader would not expect

## Verification

<!-- What ran, and on which build: the result of `nim r koch check`, the sample counts, and
     every figure with its pair.
     Then show the change. Give a screenshot where it is visual, a worked example where it is
     not, and one line that says why where neither one fits. The screenshot goes in the
     message to the Architect and not here, because GitHub takes no image from an API.
     Link every page that this change published again. A reader opens a page, and a
     description of one is not a page. -->

## Record

<!-- These boxes are about this change. The standing list of what nothing checks belongs in
     the conversation and not here. See "Carry the unchecked list in the open". -->

- [ ] PROVENANCE.md holds the design by subsystem, in a commit of its own, each claim marked
- [ ] GLOSSARY.md holds every term that resolved
- [ ] Every mistake found earned a test that fails without the fix, and not one written to pass
- [ ] The assumptions, the trade-offs and the open questions are below

## Notes

<!-- The material assumptions, the choices of representation and staging, and the questions
     still open. -->
