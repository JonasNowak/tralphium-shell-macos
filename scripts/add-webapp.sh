#!/bin/bash
# ==============================================================================
# Tralphium - Add Chrome OS-style Web Application (Helium-based)
#
# Usage:
#   ./scripts/add-webapp.sh <url> [name] [--open]
#
# Examples:
#   ./scripts/add-webapp.sh https://youtube.com YouTube
#   ./scripts/add-webapp.sh https://github.com
#   ./scripts/add-webapp.sh https://chatgpt.com ChatGPT --open
# ==============================================================================

set -e

URL=""
NAME=""
SHOULD_OPEN=false

for arg in "$@"; do
    if [ "$arg" = "-h" ] || [ "$arg" = "--help" ]; then
        echo "Usage: $0 <url> [name] [--open]"
        echo "Example: $0 https://youtube.com YouTube"
        exit 0
    elif [ "$arg" = "--open" ]; then
        SHOULD_OPEN=true
    elif [ -z "$URL" ]; then
        URL="$arg"
    elif [ -z "$NAME" ]; then
        NAME="$arg"
    fi
done

if [ -z "$URL" ]; then
    echo "Usage: $0 <url> [name] [--open]"
    echo "Example: $0 https://youtube.com YouTube"
    exit 1
fi

# Ensure URL has scheme
if [[ ! "$URL" =~ ^https?:// ]]; then
    URL="https://$URL"
fi

# Extract host / domain
DOMAIN=$(echo "$URL" | awk -F/ '{print $3}' | sed 's/:.*//')

# Derive name if not specified
if [ -z "$NAME" ]; then
    # Strip www, web, app prefixes
    BASE_NAME=$(echo "$DOMAIN" | sed -E 's/^(www|web|app|mail|m)\.//' | sed -E 's/\.[^.]+$//')
    # Capitalize first letter
    NAME="$(tr '[:lower:]' '[:upper:]' <<< ${BASE_NAME:0:1})${BASE_NAME:1}"
fi

# Sanitize app name for directory
CLEAN_NAME=$(echo "$NAME" | tr '/:' '--')
APPS_DIR="$HOME/Applications"
mkdir -p "$APPS_DIR"

APP_PATH="$APPS_DIR/${CLEAN_NAME}.app"
CONTENTS_PATH="$APP_PATH/Contents"
MACOS_PATH="$CONTENTS_PATH/MacOS"
RESOURCES_PATH="$CONTENTS_PATH/Resources"

echo "==> Creating WebApp '${CLEAN_NAME}' for ${URL}..."

mkdir -p "$MACOS_PATH" "$RESOURCES_PATH"

# Locate Helium
HELIUM_PATH="/Applications/Helium.app"
if [ ! -d "$HELIUM_PATH" ]; then
    HELIUM_PATH="$HOME/Applications/Helium.app"
fi

if [ ! -d "$HELIUM_PATH" ]; then
    echo "Warning: Helium.app not found in /Applications or ~/Applications."
    echo "Defaulting executable to /Applications/Helium.app."
fi

# Create launcher script
LAUNCHER="$MACOS_PATH/launcher"
cat << EOF > "$LAUNCHER"
#!/bin/bash
exec "$HELIUM_PATH/Contents/MacOS/Helium" --app="$URL" "\$@"
EOF
chmod +x "$LAUNCHER"

# Fetch and build AppIcon.icns
TMP_DIR=$(mktemp -d)
trap "rm -rf '$TMP_DIR'" EXIT

ICON_PNG="$TMP_DIR/icon.png"

# Try Google 256px favicon first
curl -s -L --max-time 4 "https://www.google.com/s2/favicons?domain=${DOMAIN}&sz=256" -o "$ICON_PNG" || true

# Check size; if too small, try icon.horse
if [ ! -s "$ICON_PNG" ] || [ $(sips -g pixelWidth "$ICON_PNG" 2>/dev/null | awk '/pixelWidth/ {print $2}') -lt 32 ]; then
    curl -s -L --max-time 4 "https://icon.horse/icon/${DOMAIN}" -o "$ICON_PNG" || true
fi

if [ -s "$ICON_PNG" ]; then
    ICONSET="$TMP_DIR/AppIcon.iconset"
    mkdir -p "$ICONSET"

    sips -z 16 16 "$ICON_PNG" --out "$ICONSET/icon_16x16.png" >/dev/null 2>&1 || true
    sips -z 32 32 "$ICON_PNG" --out "$ICONSET/icon_16x16@2x.png" >/dev/null 2>&1 || true
    sips -z 32 32 "$ICON_PNG" --out "$ICONSET/icon_32x32.png" >/dev/null 2>&1 || true
    sips -z 64 64 "$ICON_PNG" --out "$ICONSET/icon_32x32@2x.png" >/dev/null 2>&1 || true
    sips -z 128 128 "$ICON_PNG" --out "$ICONSET/icon_128x128.png" >/dev/null 2>&1 || true
    sips -z 256 256 "$ICON_PNG" --out "$ICONSET/icon_128x128@2x.png" >/dev/null 2>&1 || true
    sips -z 256 256 "$ICON_PNG" --out "$ICONSET/icon_256x256.png" >/dev/null 2>&1 || true
    sips -z 512 512 "$ICON_PNG" --out "$ICONSET/icon_256x256@2x.png" >/dev/null 2>&1 || true
    sips -z 512 512 "$ICON_PNG" --out "$ICONSET/icon_512x512.png" >/dev/null 2>&1 || true
    sips -z 1024 1024 "$ICON_PNG" --out "$ICONSET/icon_512x512@2x.png" >/dev/null 2>&1 || true

    iconutil -c icns "$ICONSET" -o "$RESOURCES_PATH/AppIcon.icns" >/dev/null 2>&1 || true
fi

# Fallback icon if icns generation failed
if [ ! -f "$RESOURCES_PATH/AppIcon.icns" ] && [ -f "$HELIUM_PATH/Contents/Resources/app.icns" ]; then
    cp "$HELIUM_PATH/Contents/Resources/app.icns" "$RESOURCES_PATH/AppIcon.icns"
fi

# Create Info.plist
BUNDLE_ID="net.imput.helium.webapp.$(echo "$CLEAN_NAME" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9')"
cat << EOF > "$CONTENTS_PATH/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleDisplayName</key>
    <string>${CLEAN_NAME}</string>
    <key>CFBundleExecutable</key>
    <string>launcher</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>${CLEAN_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
</dict>
</plist>
EOF

# Ad-hoc sign bundle
codesign -f -s - "$APP_PATH" >/dev/null 2>&1 || true

# Refresh Tralphium app catalog
open -g "tralphium://refreshApps" 2>/dev/null || true

echo "==> WebApp successfully installed at: $APP_PATH"
echo "    Visible in Tralphium Launchpad, pinnable to shelf."

if [ "$SHOULD_OPEN" = true ]; then
    open "$APP_PATH"
fi
