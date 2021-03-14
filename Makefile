FLUTTER ?= flutter
FLUTTERRUN ?= $(FLUTTER) run

################################################################################
## Main make targets
################################################################################
.PHONY: run-dev
run-dev:
	$(FLUTTERRUN)

.PHONY: run-prod
run-dev:
	$(FLUTTERRUN) -t lib/main_prod.dart

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