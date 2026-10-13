#!/bin/sh
# Run the Core tests (Swift Testing). Without Xcode, Swift Testing lives in
# the Command Line Tools but not on SwiftPM's search path, so add it by hand.
set -eu
cd "$(dirname "$0")"

# Build outside the repo: ~/Documents is synced by iCloud, whose file provider
# stamps Finder attributes on build products and makes codesign fail.
SCRATCH=${TRALPHIUM_BUILD_DIR:-$HOME/Library/Caches/Tralphium/build}

if [ -z "${SDKROOT:-}" ]; then
    if [ -d "/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk" ]; then
        SDKROOT="/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk"
    else
        SDKROOT=$(xcrun --show-sdk-path 2>/dev/null || true)
    fi
    export SDKROOT
fi

CLT=/Library/Developer/CommandLineTools
FW=$CLT/Library/Developer/Frameworks
LIB=$CLT/Library/Developer/usr/lib

if [ ! -d "$FW/Testing.framework" ]; then
    # Xcode (or a toolchain that already has the paths): plain swift test.
    exec swift test --scratch-path "$SCRATCH" "$@"
fi

swift test --scratch-path "$SCRATCH" \
    -Xswiftc -F"$FW" \
    -Xswiftc -plugin-path -Xswiftc "$CLT/usr/lib/swift/host/plugins/testing" \
    -Xlinker -F"$FW" \
    -Xlinker -rpath -Xlinker "$FW" \
    -Xlinker -rpath -Xlinker "$LIB" \
    "$@"
