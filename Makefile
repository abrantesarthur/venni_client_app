# GO ?= go
# GOGENERATE ?= $(GO) generate
# GOINSTALL ?= $(GO) install

################################################################################
## Main make targets
################################################################################

# .PHONY: deps
# deps: docker/up docker/wait migrations/up migrations/test/up
# 	$(GOMOD) tidy

# .PHONY: undeps
# undeps: docker/down

# .PHONY: run
# run:
# 	$(GORUN) . api

################################################################################
## test targets
################################################################################

.PHONY: unit_test
unit_test:
	flutter test --name=test/unit/* --coverage
	
.PHONY: widget_test
unit_test:
	flutter test --name=test/widget/* --coverage

.PHONY: integration_test
unit_test:
	flutter test --name=test/integration/* --coverage