#!/bin/sh
cd "$(dirname "$0")/../.." || exit 1
haxelib run lime build cpp -release