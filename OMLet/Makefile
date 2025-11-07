.PHONY: all test clean
all:
	dune build

test:
	dune test
clean:
	dune clean

TEST_COV_D = /tmp/cov
COVERAGE_OPTS = --coverage-path $(TEST_COV_D) --expect bin/

.PHONY: test_coverage coverage
test_coverage: coverage
coverage:
	$(RM) -r $(TEST_COV_D)
	mkdir -p $(TEST_COV_D)
	BISECT_FILE=$(TEST_COV_D)/language dune runtest --no-print-directory \
		--instrument-with bisect_ppx --force
	bisect-ppx-report html $(COVERAGE_OPTS)
	bisect-ppx-report summary $(COVERAGE_OPTS)
	@echo "Use 'xdg-open _coverage/index.html' to see coverage report"

.PHONY: compile
compile:
	@if [ -z "$(file)" ]; then \
		echo "Usage: make compile file=<filename>"; \
		exit 1; \
	fi
	dune build
	_build/default/bin/omlet.exe -fromfile $(file)
