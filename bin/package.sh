#!/bin/bash

set -eu

echo "==> 1. Building release binary..."
swift build -c release

if [ ! -f Resources/AppIcon.icns ] && [ -f Resources/logo.svg ]; then
    echo "==> Generating AppIcon.icns from logo.svg..."
    mkdir -p dist/AppIcon.iconset

    # Use sips to convert SVG to PNG at each required size
    for size_info in "16:icon_16x16.png" "32:icon_16x16@2x.png" "32:icon_32x32.png" "64:icon_32x32@2x.png" \
                     "128:icon_128x128.png" "256:icon_128x128@2x.png" "256:icon_256x256.png" "512:icon_256x256@2x.png" \
                     "512:icon_512x512.png" "1024:icon_512x512@2x.png"; do
      pixel_size="${size_info%%:*}"
      filename="${size_info##*:}"
      sips -s format png --resampleWidth "$pixel_size" Resources/logo.svg \
           --out "dist/AppIcon.iconset/$filename" >/dev/null 2>&1 || true
    done

    iconutil -c icns dist/AppIcon.iconset -o Resources/AppIcon.icns
    rm -rf dist/AppIcon.iconset
fi

echo "==> 2. Creating TouchTutor.app bundle..."
rm -rf dist
mkdir -p dist/TouchTutor.app/Contents/MacOS
mkdir -p dist/TouchTutor.app/Contents/Resources
mkdir -p dist/dmg_staging

cp .build/release/TouchTutor dist/TouchTutor.app/Contents/MacOS/TouchTutor
chmod +x dist/TouchTutor.app/Contents/MacOS/TouchTutor
cp -R .build/release/TouchTutor_TouchTutor.bundle dist/TouchTutor.app/Contents/Resources/
cp Resources/AppIcon.icns dist/TouchTutor.app/Contents/Resources/ 2>/dev/null || true

cat <<EOF > dist/TouchTutor.app/Contents/Info.plist
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
EOF

echo "==> 3. Staging and creating DMG..."
cp -R dist/TouchTutor.app dist/dmg_staging/
ln -s /Applications dist/dmg_staging/Applications

if [ -f Resources/AppIcon.icns ]; then
    cp Resources/AppIcon.icns dist/dmg_staging/.VolumeIcon.icns
    SetFile -c icnC dist/dmg_staging/.VolumeIcon.icns 2>/dev/null || true
    SetFile -a C dist/dmg_staging 2>/dev/null || true
    SetFile -a V dist/dmg_staging/.VolumeIcon.icns 2>/dev/null || true
fi

rm -f TouchTutor.dmg
diskutil image create from \
  --volumeName "TouchTutor" \
  --format UDZO \
  dist/dmg_staging \
  TouchTutor.dmg

rm -rf dist/dmg_staging

echo "==> Done! Output: TouchTutor.dmg"
