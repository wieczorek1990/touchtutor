#!/bin/sh

set -eu

cd "$(dirname "$0")/.."

./bin/format.sh
./bin/test.sh
