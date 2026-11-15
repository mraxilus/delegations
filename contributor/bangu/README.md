# bangu

Language.

One folder for each project sits directly under this one. Each one carries README.md,
PROVENANCE.md, GLOSSARY.md, `<project>.nimble` and `tests/`. To start one, follow
[CONTRIBUTOR.md](../../CONTRIBUTOR.md) on branch `contributor/bangu/<project>/<name>`.

## What `ri` repeats

By [section 7.6](https://lojban.github.io/cll/7/6/) of The Complete Lojban Language (CLL), each
`ri` repeats the last complete sumti before it. Sumti take their order from where each one
begins, so a sumti inside another one is more recent than the sumti that holds it. After
`lo tcidu be lo se ciska`, `ri` repeats the inner `lo se ciska`, and not the whole sumti.
A sumti that holds the `ri` is not complete yet, so `ri` never repeats it. `ri` skips most
other cmavo of `KOhA`, such as `mi`, and each letter word of `BY`, but not `ti`, `ta` or `tu`.
An earlier `ri` stands for the sumti that it repeats.

If `ri` would repeat a sumti that you do not mean, write the one that you mean in full. Or put
`goi ko'a` after it where it first stands, and write `ko'a` from then on (CLL 7.5). `ra` repeats
a recent sumti and `ru` an older one, and the reader must guess which (CLL 7.6). A check of
grammar passes a `ri` that repeats a sumti that you do not mean. So find what each `ri` repeats
in each record or comment that you write.
