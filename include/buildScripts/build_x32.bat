@echo off
color 0a
cd /d "%~dp0..\.."
echo BUILDING GAME
haxelib run lime build windows -32 -release -D 32bits -D HXCPP_M32
echo.
echo done.
pause
explorer.exe export\release\windows\bin