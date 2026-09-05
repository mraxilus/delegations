# Drive every check from one verb: `make check` audits tree, then runs each project's check.
#   Branch verbs take context from CI: `make scope BRANCH=<name> BASE=<ref>`.
#   `make ci` fetches origin/main, then runs same three verbs CI's jobs run; every pull
#   request passes it locally before it is opened.
#   Binary rebuilds whenever curator source changes (Article IX.6).

NIM ?= nim
AUDIT := curator/audit/bin/audit
SOURCES := $(wildcard curator/audit/src/*.nim)
BASE ?= origin/main
BRANCH ?= $(shell git rev-parse --abbrev-ref HEAD)

.PHONY: check ci tree projects scope commits stamp clean

check: $(AUDIT)
	$(AUDIT) all

ci:
	git fetch -q origin main
	$(MAKE) check
	$(MAKE) scope
	$(MAKE) commits

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
	$(NIM) c --hints:off --outdir:curator/audit/bin curator/audit/src/audit.nim

clean:
	rm -rf curator/audit/bin curator/audit/nimcache curator/audit/testresults
