# Rebuild and drive every law with testament, then build every page: `make check`, `make pages`
#   (Article IX.6). Tool binaries land in bin/, which root .gitignore covers at any depth.
#   `pages` writes shells from their Nim hosts, compiles browser scripts, folds each into one
#   self-contained file, renders review page and frame pictures, builds four mark pages, sweeps
#   turns natively and splices whole-cloth page. `verdicts` is instrument run, not build:
#   answers land in sim/verdicts.md. `shot` builds screenshot helper for node and Playwright.

NIM ?= nim
BUILD := build
DANGER := -d:danger --hints:off
RELEASE := -d:release --hints:off

.PHONY: check pages verdicts shot clean

check:
	testament --nim:$(shell command -v $(NIM)) pattern "tests/t*.nim"

pages:
	mkdir -p $(BUILD)/app $(BUILD)/sim $(BUILD)/review $(BUILD)/design
	$(NIM) c -r --hints:off --outdir:bin tools/pages.nim $(BUILD)
	$(NIM) js $(RELEASE) -o:$(BUILD)/app/app.js app/app.nim
	$(NIM) js $(RELEASE) -o:$(BUILD)/sim/sim.js sim/page.nim
	$(NIM) c -r --hints:off --outdir:bin tools/bundle.nim $(BUILD)/app app
	$(NIM) c -r --hints:off --outdir:bin tools/bundle.nim $(BUILD)/sim sim
	$(NIM) c -r --hints:off --outdir:bin tools/review.nim $(BUILD)/review
	$(NIM) c -r --hints:off --outdir:bin design/marks.nim $(BUILD)/design
	$(NIM) c -r $(DANGER) --outdir:bin design/turns.nim
	$(NIM) js $(RELEASE) -o:$(BUILD)/design/wholecloth_turns.js design/wholecloth_turns.nim
	$(NIM) c -r --hints:off --outdir:bin design/wholecloth.nim $(BUILD)/design

verdicts:
	$(NIM) c -r $(DANGER) --outdir:bin sim/verdicts.nim

shot:
	mkdir -p $(BUILD)/design
	$(NIM) js --hints:off -d:nodejs -o:$(BUILD)/design/shot.js design/shot.nim

clean:
	rm -rf bin $(BUILD) nimcache testresults
	find tests -maxdepth 1 -type f -not -name "*.nim" -delete
