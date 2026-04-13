package backend;

import sys.FileSystem;
import sys.io.File;
import haxe.Http;
import haxe.io.Bytes;
import haxe.zip.Reader;
import haxe.io.BytesOutput;

/**
 * @author maybekoi
 * @see https://github.com/Moon4K-Dev/Moon4K-Legacy
 */
class AutoUpdater
{
	private static inline var VERSION_URL = "https://raw.githubusercontent.com/Joalor64GH/FNF-SynapseEngine/refs/heads/main/gitVersion.txt";
	private static inline var DOWNLOAD_URL =
		#if windows
		"https://github.com/Joalor64GH/FNF-SynapseEngine/releases/latest/download/SynapseEngine-windows.zip"
		#elseif macos
		"https://github.com/Joalor64GH/FNF-SynapseEngine/releases/latest/download/SynapseEngine-mac.zip"
		#elseif linux
		"https://github.com/Joalor64GH/FNF-SynapseEngine/releases/latest/download/SynapseEngine-linux.zip"
		#end;

	#if windows
	private static inline var EXE_NAME = "SynapseEngine.exe";
	private static inline var LIME_DLL = "lime.ndll";
	private static inline var VLC_DLL = "libvlc.dll";
	private static var LOCKED_FILES:Array<String> = [EXE_NAME, LIME_DLL, VLC_DLL];
	#elseif macos
	private static inline var APP_BUNDLE = "SynapseEngine.app";
	private static inline var EXE_NAME = "SynapseEngine";
	private static var LOCKED_FILES:Array<String> = [];
	#elseif linux
	private static inline var EXE_NAME = "SynapseEngine";
	private static var LOCKED_FILES:Array<String> = [];
	#end

	public static var CURRENT_VERSION = Constants.SYNAPSE_ENGINE_VERSION.trim();

	public static var latestVersion:String = "";
	public static var mustUpdate:Bool = false;

	public static function checkForUpdates():Void
	{
		var http = new Http(VERSION_URL);

		http.onData = function(data:String)
		{
			latestVersion = StringTools.trim(data);
			if (isNewerVersion(latestVersion, CURRENT_VERSION))
			{
				mustUpdate = true;
			}
		}

		http.onError = function(error)
		{
			trace("Error checking for updates: " + error);
		}

		trace("Checking for updates...");
		trace("Latest version: " + latestVersion);
		trace("Current version: " + CURRENT_VERSION);

		http.request();
	}

	public static function isNewerVersion(latest:String, current:String):Bool
	{
		var latestParts = latest.split(".");
		var currentParts = current.split(".");

		for (i in 0...3)
		{
			var latestNum = Std.parseInt(latestParts[i]);
			var currentNum = Std.parseInt(currentParts[i]);

			if (latestNum > currentNum)
				return true;
			if (latestNum < currentNum)
				return false;
		}

		return false;
	}

	public static function downloadUpdate():Void
	{
		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.WHITE);
		bg.alpha = 0.6;
		FlxG.state.add(bg);

		var waitTxt:FlxText = new FlxText(0, 0, FlxG.width, "DOWNLOADING UPDATE\nPLEASE WAIT...", 40);
		waitTxt.screenCenter();
		FlxG.state.add(waitTxt);

		trace("Attempting to download from: " + DOWNLOAD_URL);
		var data = downloadWithRedirects(DOWNLOAD_URL);
		if (data != null && data.length > 0)
		{
			handleDownloadedData(data);
		}
		else
		{
			trace("Download failed");
			var errorText = new FlxText(0, 0, FlxG.width,
				"Download failed. Please check your internet connection and try again.\n"
				+ "Error details: Unable to connect to update server.\n"
				+ "URL: "
				+ DOWNLOAD_URL);
			errorText.alignment = CENTER;
			errorText.screenCenter();
			FlxG.state.add(errorText);
		}
	}

	private static function downloadWithRedirects(url:String, redirectCount:Int = 0):Bytes
	{
		if (redirectCount > 5)
		{
			trace("Too many redirects");
			return null;
		}

		try
		{
			var http = new Http(url);
			var output = new BytesOutput();
			var result:Bytes = null;

			http.onStatus = function(status:Int)
			{
				trace("HTTP Status: " + status);
				if (status >= 300 && status < 400)
				{
					var newUrl = http.responseHeaders.get("Location");
					if (newUrl != null)
					{
						trace("Redirecting to: " + newUrl);
						result = downloadWithRedirects(newUrl, redirectCount + 1);
					}
				}
			}

			http.onError = function(error:String)
			{
				trace("HTTP Error: " + error);
			}

			http.customRequest(false, output);

			if (result == null)
			{
				result = output.getBytes();
			}

			return result;
		}
		catch (e:Dynamic)
		{
			trace("Error downloading update: " + e);
			return null;
		}
	}

	private static function handleDownloadedData(data:Bytes):Void
	{
		try
		{
			if (data == null || data.length == 0)
			{
				throw "Downloaded data is empty";
			}
			var tempPath = "temp_update.zip";
			trace("Downloading update, size: " + data.length + " bytes");
			File.saveBytes(tempPath, data);
			trace("Update downloaded successfully");

			if (!FileSystem.exists(tempPath) || FileSystem.stat(tempPath).size == 0)
			{
				throw "Downloaded file is empty or doesn't exist";
			}

			extractUpdate(tempPath);
		}
		catch (e:Dynamic)
		{
			trace("Error saving update: " + e);
			FlxG.state.add(new FlxText(0, 0, FlxG.width, "Update save failed: " + e));
		}
	}

	private static function extractUpdate(zipPath:String):Void
	{
		try
		{
			var zipFile = File.read(zipPath, true);
			var entries = Reader.readZip(zipFile);
			zipFile.close();

			trace("Zip file opened, entries count: " + entries.length);

			for (entry in entries)
			{
				var fileName = entry.fileName;
				trace("Extracting: " + fileName);

				if (isLockedFile(fileName))
				{
					var content = Reader.unzip(entry);
					File.saveBytes(fileName + ".new", content);
					trace("Saved new version of: " + fileName + " (as .new)");
				}
				else
				{
					var content = Reader.unzip(entry);
					var path = haxe.io.Path.directory(fileName);
					if (path != "" && !FileSystem.exists(path))
					{
						FileSystem.createDirectory(path);
					}
					File.saveBytes(fileName, content);
					trace("Extracted: " + fileName);
				}
			}

			FileSystem.deleteFile(zipPath);
			trace("Temporary zip file deleted");
			finishUpdate();
		}
		catch (e:Dynamic)
		{
			trace("Error during extraction: " + e);
			FlxG.state.add(new FlxText(0, 0, FlxG.width, "Extraction failed: " + e));
		}
	}

	private static function isLockedFile(fileName:String):Bool
	{
		#if windows
		for (locked in LOCKED_FILES)
		{
			if (fileName == locked)
			{
				return true;
			}
		}
		#end
		return false;
	}

	private static function finishUpdate():Void
	{
		#if windows
		finishUpdateWindows();
		#elseif macos
		finishUpdateMacOS();
		#elseif linux
		finishUpdateLinux();
		#end
	}

	#if windows
	private static function finishUpdateWindows():Void
	{
		var batchContent = '@echo off\n' + 'timeout /t 1 /nobreak > NUL\n' + 'move /y SynapseEngine.exe.new SynapseEngine.exe\n'
			+ 'move /y lime.ndll.new lime.ndll\n' + 'move /y libvlc.dll.new libvlc.dll\n' + 'start "" SynapseEngine.exe\n' + 'del "%~f0"';

		File.saveContent("finish_update.bat", batchContent);

		Sys.command("start finish_update.bat");
		Application.current.window.close();
	}
	#end

	#if macos
	private static function finishUpdateMacOS():Void
	{
		var appPath = Sys.programPath();
		var appBundlePath = appPath;
		while (appBundlePath != "" && !StringTools.endsWith(appBundlePath, ".app"))
		{
			appBundlePath = haxe.io.Path.directory(appBundlePath);
		}

		if (appBundlePath == "" || !FileSystem.exists(appBundlePath))
		{
			trace("Could not locate .app bundle, using relative path");
			appBundlePath = APP_BUNDLE;
		}

		var shellScript = '#!/bin/bash\n' + 'sleep 1\n' + 'open "' + appBundlePath + '"\n' + 'rm "$0"';

		var scriptPath = "finish_update.sh";
		File.saveContent(scriptPath, shellScript);

		Sys.command("chmod", ["+x", scriptPath]);
		Sys.command("bash", [scriptPath, "&"]);

		Application.current.window.close();
	}
	#end

	#if linux
	private static function finishUpdateLinux():Void
	{
		var shellScript = '#!/bin/bash\n' + 'sleep 1\n' + 'chmod +x "' + EXE_NAME + '"\n' + './' + EXE_NAME + ' &\n' + 'rm "$0"';

		var scriptPath = "finish_update.sh";
		File.saveContent(scriptPath, shellScript);

		Sys.command("chmod", ["+x", scriptPath]);
		Sys.command("bash", [scriptPath, "&"]);

		Application.current.window.close();
	}
	#end
}
