# usage: make [CONFIG=debug|release]

ifeq ($(CONFIG), debug)
    CFLAGS=-Onone -g
else
    CFLAGS=-O
endif

PLIST=$(shell grep -A1 $(1) src/Info.plist | tail -1 | cut -d'>' -f2 | cut -d'<' -f1)


Darker.app: SDK_PATH=$(shell xcrun --show-sdk-path --sdk macosx)
Darker.app: src/*
	@mkdir -p Darker.app/Contents/MacOS/
	# compile x64
	swiftc ${CFLAGS} src/main.swift -target x86_64-apple-macos10.10 -emit-executable -sdk ${SDK_PATH} -o bin_x64
	# compile arm64
	swiftc ${CFLAGS} src/main.swift -target arm64-apple-macos10.10 -emit-executable -sdk ${SDK_PATH} -o bin_arm64
	# make universal bundle
	lipo -create bin_x64 bin_arm64 -o Darker.app/Contents/MacOS/Darker
	@rm bin_x64 bin_arm64
	@echo 'APPL????' > Darker.app/Contents/PkgInfo
	@mkdir -p Darker.app/Contents/Resources/
	@cp src/AppIcon.icns Darker.app/Contents/Resources/AppIcon.icns
	@cp src/Info.plist Darker.app/Contents/Info.plist
	@touch Darker.app

.PHONY: sign
sign: Darker.app
	codesign -v -s 'Apple Development' --options=runtime --timestamp Darker.app
	@echo
	@echo 'Verify Signature...'
	@echo
	codesign -dvv Darker.app
	@echo
	codesign -vvv --deep --strict Darker.app
	@echo
	spctl -vvv --assess --type exec Darker.app

.PHONY: release
release: VERSION=$(call PLIST,CFBundleShortVersionString)
release: Darker.app
	tar -czf "Darker_v${VERSION}.tar.gz" Darker.app
