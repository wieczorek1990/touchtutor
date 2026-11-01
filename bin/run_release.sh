#!/bin/sh

set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/.build/release"
APP_BUNDLE="$BUILD_DIR/TouchTutor.app"

# Create a minimal .app bundle so macOS shows the correct icon
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$BUILD_DIR/TouchTutor" "$APP_BUNDLE/Contents/MacOS/TouchTutor"
chmod +x "$APP_BUNDLE/Contents/MacOS/TouchTutor"

# Copy the resource bundle next to the executable inside the .app
if [ -d "$BUILD_DIR/TouchTutor_TouchTutor.bundle" ]; then
  cp -R "$BUILD_DIR/TouchTutor_TouchTutor.bundle" "$APP_BUNDLE/Contents/Resources/"
fi

# Copy logo.svg for the icon generation
if [ -f "$PROJECT_DIR/Resources/logo.svg" ]; then
  cp "$PROJECT_DIR/Resources/logo.svg" "$APP_BUNDLE/Contents/Resources/"
fi

# Generate the .icns icon from logo.svg if not already present
if [ ! -f "$APP_BUNDLE/Contents/Resources/AppIcon.icns" ] && [ -f "$APP_BUNDLE/Contents/Resources/logo.svg" ]; then
  mkdir -p dist/AppIcon.iconset

  # Use sips to convert SVG to PNG at each required size
  for size_info in "16:icon_16x16.png" "32:icon_16x16@2x.png" "32:icon_32x32.png" "64:icon_32x32@2x.png" \
                   "128:icon_128x128.png" "256:icon_128x128@2x.png" "256:icon_256x256.png" "512:icon_256x256@2x.png" \
                   "512:icon_512x512.png" "1024:icon_512x512@2x.png"; do
    pixel_size="${size_info%%:*}"
    filename="${size_info##*:}"
    sips -s format png --resampleWidth "$pixel_size" "$APP_BUNDLE/Contents/Resources/logo.svg" \
         --out "dist/AppIcon.iconset/$filename" >/dev/null 2>&1 || true
  done

  if [ -d "dist/AppIcon.iconset" ]; then
    iconutil -c icns dist/AppIcon.iconset -o "$APP_BUNDLE/Contents/Resources/AppIcon.icns" 2>/dev/null || true
    rm -rf dist/AppIcon.iconset
  fi
fi

# Write Info.plist
cat > "$APP_BUNDLE/Contents/Info.plist" << EOFPLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>TouchTutor</string>
    <key>CFBundleIdentifier</key>
    <string>tech.soiree.TouchTutor</string>
    <key>CFBundleName</key>
    <string>TouchTutor</string>
    <key>CFBundleDisplayName</key>
    <string>TouchTutor</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOFPLIST

# Open the .app bundle
open "$APP_BUNDLE"
