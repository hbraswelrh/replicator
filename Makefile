.PHONY: build test coverage check-coverage lint vet clean serve check release install

VERSION ?= $(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")
COMMIT  ?= $(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")
DATE    ?= $(shell date -u +%Y-%m-%dT%H:%M:%SZ)
LDFLAGS := -ldflags "-X main.Version=$(VERSION) -X main.commit=$(COMMIT) -X main.date=$(DATE)"

build:
	go build $(LDFLAGS) -o bin/replicator ./cmd/replicator

test:
	go test ./... -count=1 -race -coverprofile=coverage.out

coverage:
	go test ./... -count=1 -race -coverprofile=coverage.out
	go tool cover -func=coverage.out

# Enforce coverage ratchets locally (mirrors CI step).
check-coverage: coverage
	@if [ ! -s coverage.out ]; then \
		echo "Error: No coverage profile found"; exit 1; \
	fi
	@GLOBAL_COV=$$(go tool cover -func=coverage.out | grep '^total:' | awk '{print substr($$3, 1, length($$3)-1)}'); \
	if [ -z "$$GLOBAL_COV" ]; then \
		echo "Error: Could not parse global coverage"; exit 1; \
	fi; \
	echo "Global coverage: $${GLOBAL_COV}%"; \
	if [ $$(echo "$$GLOBAL_COV < 55.0" | bc -l) -eq 1 ]; then \
		echo "FAIL: Global coverage $${GLOBAL_COV}% is below the 55% threshold."; exit 1; \
	fi; \
	FAILED=0; \
	for ENTRY in \
		"internal/memory:85" \
		"internal/query:80" \
		"internal/doctor:80" \
		"internal/forge:80" \
		"internal/stats:80" \
		"internal/comms:80" \
		"internal/org:80" \
		"internal/agentkit:80" \
		"internal/gitutil:80" \
		"internal/ui:75" \
		"internal/mcp:70"; \
	do \
		PKG=$${ENTRY%%:*}; \
		THRESHOLD=$${ENTRY##*:}; \
		PKG_COV=$$(go tool cover -func=coverage.out \
			| grep "github.com/unbound-force/replicator/$${PKG}" \
			| awk '{print substr($$3, 1, length($$3)-1)}' \
			| awk '{t+=$$1; c++} END {if(c>0) printf "%.1f", t/c; else print "0.0"}'); \
		if [ $$(echo "$$PKG_COV < $$THRESHOLD" | bc -l) -eq 1 ]; then \
			echo "FAIL: $${PKG} coverage $${PKG_COV}% is below the $${THRESHOLD}% threshold."; \
			FAILED=1; \
		else \
			echo "$${PKG}: $${PKG_COV}% >= $${THRESHOLD}% ✓"; \
		fi; \
	done; \
	if [ "$$FAILED" -eq 1 ]; then exit 1; fi; \
	echo "All coverage ratchets passed."

vet:
	go vet ./...

lint:
	golangci-lint run ./...

clean:
	rm -rf bin/ dist/

# Run the MCP server (for local testing with AI agents).
serve: build
	./bin/replicator serve

# Quick check: vet + test.
check: vet test

# Local release dry-run (no publish).
release:
	goreleaser release --snapshot --clean

# Install to GOPATH/bin.
install:
	go install $(LDFLAGS) ./cmd/replicator
