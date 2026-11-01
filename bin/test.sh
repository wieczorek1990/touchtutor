#!/bin/sh

set -eu

cd "$(dirname "$0")/.."

swift test
python3 -B -m unittest discover -s Tests/Python -v
