#!/bin/sh
# Setup for Linux and Mac devices!
# Make sure you've installed Haxe prior to running this file!
# https://haxe.org/download/
cd ..
echo Installing dependencies
haxe -cp ./actions/libs-installer -D analyzer-optimize -main Main --interp
echo Finished!