#!/bin/sh

set -eu

cd "$(dirname "$0")/.."

echo "Guard!"
./bin/format.sh
./bin/test.sh
echo "Done."
