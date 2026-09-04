# Quality gates from SPEC §7. `make check` is the bar for every commit.

SCHEME  := Quiet
DEST    := generic/platform=iOS

.PHONY: gen lint format test build check clean

gen: ## Regenerate Quiet.xcodeproj from project.yml
	xcodegen generate

lint: ## Style and banned-API checks
	swiftformat --lint .
	swiftlint --strict

format: ## Apply formatting in place
	swiftformat .

test: ## FilterCore unit tests, including the corpus contract
	swift test --package-path FilterCore

build: ## Compile both targets for a generic iOS device
	xcodebuild -scheme $(SCHEME) -destination '$(DEST)' build CODE_SIGNING_ALLOWED=NO

check: lint test build ## Everything. Must be green before committing.

clean:
	rm -rf FilterCore/.build build
