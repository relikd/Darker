APP_NAME := Darker

# usage: make [CONFIG=debug|release]
ifeq ($(CONFIG), debug)
	CFLAGS=-Onone -g
else
	CFLAGS=-O
endif

PLIST=$(shell grep -A1 $(1) src/Info.plist | tail -1 | cut -d'>' -f2 | cut -d'<' -f1)
HAS_SIGN_IDENTITY=$(shell security find-identity -v -p codesigning | grep -q "Apple Development" && echo 1 || echo 0)


.PHONY: release
release: VERSION=$(call PLIST,CFBundleShortVersionString)
release: ${APP_NAME}.app
	@echo
	@echo ... Zip ...
	@rm -rf "${APP_NAME}_${VERSION}.zip"
	zip "${APP_NAME}_${VERSION}.zip" -qr "${APP_NAME}.app"


${APP_NAME}.app: OS_VER=$(call PLIST,LSMinimumSystemVersion)
${APP_NAME}.app: SDK_PATH=$(shell xcrun --show-sdk-path --sdk macosx)
${APP_NAME}.app: src/* img/AppIcon.icns $(wildcard res/*)
	@mkdir -p ${APP_NAME}.app/Contents/MacOS/
	@echo
	@echo ... Build Executable ...
	swiftc ${CFLAGS} src/main.swift -target x86_64-apple-macos${OS_VER} -emit-executable -sdk "${SDK_PATH}" -o bin_x64
	swiftc ${CFLAGS} src/main.swift -target arm64-apple-macos${OS_VER} -emit-executable -sdk "${SDK_PATH}" -o bin_arm64
	lipo -create bin_x64 bin_arm64 -o "${APP_NAME}.app/Contents/MacOS/${APP_NAME}"
	@rm bin_x64 bin_arm64
	@echo
	@echo ... Generate Meta Data ...
	echo 'APPL????' > "${APP_NAME}.app/Contents/PkgInfo"
	cp src/Info.plist "${APP_NAME}.app/Contents/Info.plist"
	@echo
	@echo ... Copy Other Resources ...
	@mkdir -p "${APP_NAME}.app/Contents/Resources/"
ifneq ($(wildcard res/*),)
	rsync -a res/ "${APP_NAME}.app/Contents/Resources/" --exclude .DS_Store --del
endif
	cp img/AppIcon.icns "${APP_NAME}.app/Contents/Resources/"
	@echo
	@echo ... Final Touches ...
	@find "${APP_NAME}.app" -name .DS_Store -delete
	touch "${APP_NAME}.app"
	@echo
	@echo ... Code Sign ...
ifeq ($(HAS_SIGN_IDENTITY),1)
	-codesign -v -s 'Apple Development' --options=runtime --timestamp "${APP_NAME}.app"
else
	-codesign -v -s - "${APP_NAME}.app"
endif
	@echo
	@echo ... Verify Signature ...
	codesign -dvv "${APP_NAME}.app"
	@echo
	codesign -vvv --strict "${APP_NAME}.app"
ifeq ($(HAS_SIGN_IDENTITY),1)
	@echo
	-spctl -vvv --assess --type exec "${APP_NAME}.app"
endif


.PHONY: clean
clean:
	rm -rf "${APP_NAME}.app" bin_x64 bin_arm64
