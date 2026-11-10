@echo off
color 0a
cd /d "%~dp0..\.."
echo BUILDING GAME
haxelib run lime test windows -debug
echo.
echo done.
pause