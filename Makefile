# Drive every check from one verb: `make check` audits tree, then runs each project's check.
#   Branch verbs take context from CI: `make scope BRANCH=<name> BASE=<ref>`.
#   Binary rebuilds whenever curator source changes (Article IX.6).

NIM ?= nim
AUDIT := curator/bin/audit
SOURCES := $(wildcard curator/src/*.nim)
BASE ?= origin/main
BRANCH ?= $(shell git rev-parse --abbrev-ref HEAD)

.PHONY: check tree projects scope commits stamp clean

check: $(AUDIT)
	$(AUDIT) all

tree: $(AUDIT)
	$(AUDIT) tree

projects: $(AUDIT)
	$(AUDIT) projects

scope: $(AUDIT)
	$(AUDIT) scope --branch:$(BRANCH) --base:$(BASE)

commits: $(AUDIT)
	$(AUDIT) commits --branch:$(BRANCH) --base:$(BASE)

stamp: $(AUDIT)
	@$(AUDIT) stamp

$(AUDIT): $(SOURCES)
	$(NIM) c --hints:off --outdir:curator/bin curator/src/audit.nim

clean:
	rm -rf curator/bin curator/nimcache curator/testresults
