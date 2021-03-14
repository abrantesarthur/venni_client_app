FLUTTER ?= flutter
FLUTTERRUN ?= $(FLUTTER) run

################################################################################
## Main make targets
################################################################################
.PHONY: run-dev
run-dev:
	$(FLUTTERRUN) -t lib/main_dev.dart

.PHONY: run
run:
	$(FLUTTERRUN) -t lib/main_prod.dart

################################################################################
## test targets
################################################################################

.PHONY: unit_test
unit_test:
	flutter test test/unit/* --coverage
	
.PHONY: widget_test
widget_test:
	flutter test test/widget/* --coverage

.PHONY: integration_test
integration_test:
	flutter test test/integration/* --coverage

.PHONY: test
test:
	flutter test test/*