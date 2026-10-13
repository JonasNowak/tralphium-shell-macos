#!/bin/sh
# Build, assemble Tralphium.app, install to ~/Applications and (re)start it.
set -eu
cd "$(dirname "$0")"

# Pin the SDK when the Command Line Tools ship one that matches the compiler
# (a newer default SDK can mismatch the Swift compiler). Override with SDKROOT.
if [ -z "${SDKROOT:-}" ]; then
    if [ -d "/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk" ]; then
        SDKROOT="/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk"
    else
        SDKROOT=$(xcrun --show-sdk-path 2>/dev/null || true)
    fi
    export SDKROOT
fi

# Build outside the repo: ~/Documents is synced by iCloud, whose file provider
# stamps Finder attributes on build products and makes codesign fail.
SCRATCH=${TRALPHIUM_BUILD_DIR:-$HOME/Library/Caches/Tralphium/build}

swift build -c release --product Tralphium --scratch-path "$SCRATCH"
BINARY=$(swift build -c release --scratch-path "$SCRATCH" --show-bin-path)/Tralphium

APP="$HOME/Applications/Tralphium.app"
mkdir -p "$HOME/Applications"
pkill -x Tralphium 2>/dev/null || true
scripts/assemble-app.sh "$BINARY" "$APP"
open "$APP"
echo "Installed and started: $APP"
