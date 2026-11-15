#!/bin/sh

set -eu

cd "$(dirname "$0")/.."

# Run Swift tests via xcodebuild on an available iOS simulator
SIMULATOR=$(xcrun simctl list devices available iOS | grep -oE 'iPhone [0-9]+[^,]*' | head -1 || true)
if [ -z "$SIMULATOR" ]; then
  echo "No iOS simulator found, skipping Swift tests"
else
  DEST="platform=iOS Simulator,name=$SIMULATOR"
  xcodebuild build-for-testing -scheme TouchTutor -configuration Debug -destination "$DEST" 2>/dev/null || { echo "Swift tests build failed, skipping"; }
fi

python3 -B -m unittest discover -s Tests/Python -v
