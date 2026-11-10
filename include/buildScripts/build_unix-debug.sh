#!/bin/sh
# go to the repo root (two folders up from this script), wherever it's run from
cd "$(dirname "$0")/../.." || exit 1
haxelib run lime build cpp -debug