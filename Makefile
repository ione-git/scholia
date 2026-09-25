DESTINATION ?= platform=iOS Simulator,name=iPhone 17 Pro,OS=26.4.1
DERIVED_DATA ?= build/DerivedData
XCODEBUILD = xcodebuild -project Scholia.xcodeproj -scheme Scholia -destination '$(DESTINATION)' -derivedDataPath $(DERIVED_DATA)
SOURCES = App UITests Packages

.PHONY: generate build test lint format device

generate:
	xcodegen generate --quiet

build: generate
	$(XCODEBUILD) build-for-testing -quiet

test: generate
	$(XCODEBUILD) test -quiet -resultBundlePath build/Results-$$(date +%s).xcresult $(if $(ONLY),-only-testing:$(ONLY))

lint:
	xcrun swift-format lint --strict --recursive $(SOURCES)

format:
	xcrun swift-format format --in-place --recursive $(SOURCES)

device: generate
	@test -n "$(DEVICE)" || (echo "usage: make device DEVICE=<device id>" && exit 1)
	xcodebuild -project Scholia.xcodeproj -scheme Scholia -configuration Debug -destination 'id=$(DEVICE)' -derivedDataPath $(DERIVED_DATA) -allowProvisioningUpdates -quiet build
	xcrun devicectl device install app --device $(DEVICE) $(DERIVED_DATA)/Build/Products/Debug-iphoneos/Scholia.app
	xcrun devicectl device process launch --device $(DEVICE) com.ione.scholia
