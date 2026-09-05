# Rebuild and drive every test with testament: `make check` (Article IX.6).
#   Testament places each test binary beside its source; git ignores those with `nimcache/`
#   and `testresults/`.

NIM ?= nim

.PHONY: check clean

check:
	testament --nim:$(shell command -v $(NIM)) pattern "tests/t*.nim"

clean:
	rm -rf bin nimcache testresults
	find tests -maxdepth 1 -type f -not -name "*.nim" -delete
