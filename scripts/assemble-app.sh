#!/bin/sh
# Assemble Tralphium.app from a built binary and sign it.
# usage: assemble-app.sh BINARY APP
#
# Signing: macOS ties Accessibility grants to the code signature. An ad-hoc
# signature changes with every build, so grants would be lost each time. Run
# scripts/setup-signing.sh once to create a stable local identity.
set -eu

if [ $# -ne 2 ]; then
    echo "usage: $0 BINARY APP" >&2
    exit 2
fi

ROOT=$(cd "$(dirname "$0")/.." && pwd)
BINARY=$1
APP=$2
PLIST="$ROOT/Support/Info.plist"
IDENTITY=${SIGN_IDENTITY-"Tralphium Local Signing"}

if [ "$IDENTITY" != "-" ] && ! security find-identity -p codesigning 2>/dev/null | grep -q "\"$IDENTITY\""; then
    echo "note: ad-hoc signature, Accessibility grants will not survive the next build (scripts/setup-signing.sh)" >&2
    IDENTITY=-
fi

BUILD_NUMBER=${BUILD_NUMBER:-$(git -C "$ROOT" rev-list --count HEAD 2>/dev/null || echo 1)}

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BINARY" "$APP/Contents/MacOS/Tralphium"
cp "$PLIST" "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" "$APP/Contents/Info.plist"
[ -f "$ROOT/Support/AppIcon.icns" ] && cp "$ROOT/Support/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"

codesign --force --sign "$IDENTITY" "$APP"
echo "Assembled $APP"
