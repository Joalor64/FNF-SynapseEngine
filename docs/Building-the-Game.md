Before doing anything else, make sure to install [Haxe](https://haxe.org/download/) and [HaxeFlixel](https://haxeflixel.com/documentation/install-haxeflixel/).

> [!NOTE]
> All files related to building the game are located in the `art/buildScripts/` directory.

## Windows
1. Download [Visual Studio Build Tools](https://aka.ms/vs/17/release/vs_BuildTools.exe).
2. Wait for the Visual Studio Installer to install.
3. On the Visual Studio installation screen, go to "Individual Components" and select the following:
    * MSVC v143 VS 2022 C++ x64/x86 build tools
    * Windows 10/11 SDK
        * You can skip this by running `msvc.bat`.
4. Once the details are correct, press "Install".
    * ⚠ This will require 4-5GB of available space on your computer.
5. Download and install [Git](https://git-scm.com/downloads/win).
6. Install the dependencies by running `setup.bat`.
7. Open a Command Prompt/Powershell window in the `FNF-SynapseEngine` folder, and run `haxelib run lime test windows` to build and launch the game.
    * You can run `haxelib run lime setup` to make the lime command global, allowing you to execute `lime test windows` directly.
        * Alternatively, you can run one of the build scripts, for example: `test_x64-debug.bat`.

> [!CAUTION]
> Linux and Mac builds have not been tested! <br>
> So if something goes wrong, report it in the [issues](https://github.com/Joalor64/FNF-SynapseEngine/issues) tab!

## Linux
1. Install `g++`.
2. Download and install [Git](https://git-scm.com/downloads/linux).
3. Install the dependencies by running `setup.sh`.
4. Open a Terminal window in the `FNF-SynapseEngine` folder, and run `haxelib run lime test linux` to build and launch the game.
    * You can run `haxelib run lime setup` to make the lime command global, allowing you to execute `lime test linux` directly.
        * Alternatively, you can run one of the build scripts, for example: `build_unix-debug.sh`.

## MacOS
1. Install [`Xcode`](https://developer.apple.com/documentation/xcode) to allow C++ building.
2. Download and install [Git](https://git-scm.com/downloads/mac).
3. Install the dependencies by running `setup.sh`.
4. Open a Terminal window in the `FNF-SynapseEngine` folder, and run `haxelib run lime test mac` to build and launch the game.
    * You can run `haxelib run lime setup` to make the lime command global, allowing you to execute `lime test mac` directly.
        * Alternatively, you can run one of the build scripts, for example: `build_unix-debug.sh`.