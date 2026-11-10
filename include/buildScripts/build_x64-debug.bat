@echo off
color 0a
cd /d "%~dp0..\.."
echo BUILDING GAME
haxelib run lime build windows -debug
echo.
echo done.
pause
explorer.exe export\debug\windows\bin