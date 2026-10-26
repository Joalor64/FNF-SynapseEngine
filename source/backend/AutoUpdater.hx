package backend;

#if sys
import haxe.Http;
import haxe.Json;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import haxe.io.Path;
import haxe.zip.Reader;
import sys.FileSystem;
import sys.io.File;
#end
#if target.threaded
import sys.thread.Thread;
#end

enum UpdaterStatus
{
	Idle;
	Checking;
	Downloading;
	Installing;
	ReadyToRestart;
	Failed(reason:String);
}

/**
 * @author maybekoi
 * @see https://github.com/Moon4K-Dev/Moon4K-Legacy
 */
class AutoUpdater
{
	static inline var REPO:String = 'Joalor64/FNF-SynapseEngine';
	static inline var API_URL:String = 'https://api.github.com/repos/' + REPO + '/releases/latest';
	static inline var RELEASES_PAGE:String = 'https://github.com/' + REPO + '/releases/latest';

	static var ASSET_NAME:String = #if windows 'SynapseEngine-windows.zip' #elseif mac 'SynapseEngine-mac.zip' #elseif linux 'SynapseEngine-linux.zip' #else null #end;

	static inline var STAGING_DIR:String = '.update';

	static var PRESERVED_FILES:Array<String> = ['modsList.txt'];

	static inline var CONNECTION_TIMEOUT:Float = 5;

	public static var CURRENT_VERSION(get, never):String;

	public static var latestVersion:String = '';
	public static var releaseUrl:String = RELEASES_PAGE;
	public static var mustUpdate:Bool = false;

	public static var status(default, null):UpdaterStatus = Idle;

	static var downloadUrl:String = null;
	static var expectedSha256:String = null;

	static function get_CURRENT_VERSION():String
		return Constants.SYNAPSE_ENGINE_VERSION.trim();

	public static var isChecking(get, never):Bool;

	static function get_isChecking():Bool
		return status.match(Checking);

	public static function checkForUpdates():Void
	{
		#if sys
		if (!status.match(Idle))
			return;

		status = Checking;
		runAsync(function()
		{
			try
			{
				var data:String = httpGetString(API_URL);
				var release:Dynamic = Json.parse(data);

				var tag:String = Std.string(release.tag_name);
				latestVersion = cleanVersion(tag);
				if (release.html_url != null)
					releaseUrl = release.html_url;

				var assets:Array<Dynamic> = release.assets != null ? release.assets : [];
				for (asset in assets)
				{
					if (asset.name == ASSET_NAME)
					{
						downloadUrl = asset.browser_download_url;
						var digest:String = asset.digest;
						if (digest != null && digest.startsWith('sha256:'))
							expectedSha256 = digest.substr('sha256:'.length).toLowerCase();
					}
				}

				mustUpdate = isNewerVersion(latestVersion, CURRENT_VERSION);
				trace('Update check: current v$CURRENT_VERSION, latest v$latestVersion' + (mustUpdate ? ' (update available)' : ''));
				status = Idle;
			}
			catch (e:Dynamic)
			{
				trace('Could not check for updates: $e');
				status = Idle;
			}
		});
		#end
	}

	public static function canAutoInstall():Bool
	{
		#if (sys && (windows || linux))
		return downloadUrl != null;
		#else
		return false;
		#end
	}

	public static function downloadUpdate():Void
	{
		if (!canAutoInstall())
		{
			FlxG.openURL(releaseUrl);
			return;
		}

		#if sys
		if (status.match(Downloading | Installing))
			return;

		status = Downloading;
		runAsync(function()
		{
			try
			{
				var data:Bytes = httpGetBytes(downloadUrl);
				if (data == null || data.length == 0)
					throw 'Downloaded file is empty';

				if (expectedSha256 != null)
				{
					var actual:String = haxe.crypto.Sha256.make(data).toHex().toLowerCase();
					if (actual != expectedSha256)
						throw 'Downloaded file is corrupted (checksum mismatch)';
				}

				status = Installing;
				stageUpdate(data);
				#if linux
				applyStagedUpdate();
				#end
				status = ReadyToRestart;
			}
			catch (e:Dynamic)
			{
				trace('Update failed: $e');
				status = Failed(Std.string(e));
			}
		});
		#end
	}

	public static function restart():Void
	{
		#if (sys && windows)
		var exeName:String = Path.withoutDirectory(Sys.programPath());
		var script:String = '@echo off\r\n'
			+ 'cd /d "%~dp0"\r\n'
			+ ':wait\r\n'
			+ 'tasklist /FI "IMAGENAME eq $exeName" 2>NUL | find /I "$exeName" >NUL && (timeout /t 1 /nobreak >NUL & goto wait)\r\n'
			+ 'robocopy "$STAGING_DIR" "." /E /MOVE /NFL /NDL /NJH /NJS /NP >NUL\r\n'
			+ 'start "" "$exeName"\r\n'
			+ '(goto) 2>nul & del "%~f0"\r\n';
		var scriptPath:String = Path.join([gameDir(), 'finish_update.bat']);
		File.saveContent(scriptPath, script);
		Sys.command('start "" /min "$scriptPath"');
		Sys.exit(0);
		#elseif (sys && linux)
		var exe:String = Sys.programPath();
		Sys.command('sh', ['-c', 'cd "${gameDir()}" && nohup "$exe" >/dev/null 2>&1 &']);
		Sys.exit(0);
		#end
	}

	public static function cleanVersion(version:String):String
	{
		if (version == null)
			return '';
		version = version.trim();
		if (version.startsWith('v') || version.startsWith('V'))
			version = version.substr(1);
		return version;
	}

	public static function isNewerVersion(latest:String, current:String):Bool
	{
		var latestParts:Array<Int> = versionNumbers(latest);
		var currentParts:Array<Int> = versionNumbers(current);
		if (latestParts.length == 0)
			return false;

		for (i in 0...Std.int(Math.max(latestParts.length, currentParts.length)))
		{
			var a:Int = i < latestParts.length ? latestParts[i] : 0;
			var b:Int = i < currentParts.length ? currentParts[i] : 0;
			if (a != b)
				return a > b;
		}
		return false;
	}

	static function versionNumbers(version:String):Array<Int>
	{
		version = cleanVersion(version);
		for (separator in ['-', '+', ' '])
		{
			var index:Int = version.indexOf(separator);
			if (index != -1)
				version = version.substr(0, index);
		}

		var numbers:Array<Int> = [];
		if (version.length == 0)
			return numbers;

		for (part in version.split('.'))
		{
			var number:Null<Int> = Std.parseInt(part);
			numbers.push(number == null ? 0 : number);
		}
		return numbers;
	}

	#if sys
	static function gameDir():String
	{
		var dir:String = Path.directory(Sys.programPath());
		return dir == '' ? '.' : dir;
	}

	static function stageUpdate(zipData:Bytes):Void
	{
		var entries = Reader.readZip(new BytesInput(zipData));
		var names:Array<String> = [for (entry in entries) normalizeZipPath(entry.fileName)];

		var prefix:String = commonTopFolder(names);

		var stagingRoot:String = Path.join([gameDir(), STAGING_DIR]);
		if (FileSystem.exists(stagingRoot))
			deleteRecursive(stagingRoot);
		FileSystem.createDirectory(stagingRoot);

		var written:Int = 0;
		var index:Int = 0;
		for (entry in entries)
		{
			var name:String = names[index++];
			if (prefix != null)
				name = name.substr(prefix.length);

			if (name.length == 0 || name.endsWith('/'))
				continue;

			if (!isSafeRelativePath(name))
			{
				trace('Skipping unsafe path in update: ${entry.fileName}');
				continue;
			}

			if (shouldPreserve(name))
				continue;

			var target:String = Path.join([stagingRoot, name]);
			createParentDirectories(target);
			File.saveBytes(target, Reader.unzip(entry));
			written++;
		}

		if (written == 0)
			throw 'The update archive is empty';
	}

	static function shouldPreserve(relativePath:String):Bool
	{
		if (PRESERVED_FILES.contains(relativePath))
			return FileSystem.exists(Path.join([gameDir(), relativePath]));

		if (relativePath.startsWith('mods/'))
			return FileSystem.exists(Path.join([gameDir(), relativePath]));

		return false;
	}

	#if linux
	static function applyStagedUpdate():Void
	{
		var stagingRoot:String = Path.join([gameDir(), STAGING_DIR]);
		moveTree(stagingRoot, gameDir());
		deleteRecursive(stagingRoot);
		Sys.command('chmod', ['+x', Sys.programPath()]);
	}

	static function moveTree(from:String, to:String):Void
	{
		for (name in FileSystem.readDirectory(from))
		{
			var source:String = Path.join([from, name]);
			var target:String = Path.join([to, name]);
			if (FileSystem.isDirectory(source))
			{
				if (!FileSystem.exists(target))
					FileSystem.createDirectory(target);
				moveTree(source, target);
			}
			else
				FileSystem.rename(source, target);
		}
	}
	#end

	static function normalizeZipPath(path:String):String
	{
		path = path.replace('\\', '/');
		while (path.startsWith('./'))
			path = path.substr(2);
		return path;
	}

	static function commonTopFolder(names:Array<String>):String
	{
		var prefix:String = null;
		for (name in names)
		{
			var slash:Int = name.indexOf('/');
			if (slash == -1)
				return null;
			var top:String = name.substr(0, slash + 1);
			if (prefix == null)
				prefix = top;
			else if (prefix != top)
				return null;
		}
		return prefix;
	}

	static function isSafeRelativePath(path:String):Bool
	{
		if (path.startsWith('/') || path.indexOf(':') != -1)
			return false;
		for (part in path.split('/'))
			if (part == '..')
				return false;
		return true;
	}

	static function createParentDirectories(file:String):Void
	{
		var dir:String = Path.directory(file);
		if (dir != '' && !FileSystem.exists(dir))
			FileSystem.createDirectory(dir);
	}

	static function deleteRecursive(path:String):Void
	{
		if (!FileSystem.exists(path))
			return;
		if (FileSystem.isDirectory(path))
		{
			for (name in FileSystem.readDirectory(path))
				deleteRecursive(Path.join([path, name]));
			FileSystem.deleteDirectory(path);
		}
		else
			FileSystem.deleteFile(path);
	}

	static function httpGetString(url:String):String
	{
		var bytes:Bytes = httpGetBytes(url);
		return bytes == null ? null : bytes.toString();
	}

	static function httpGetBytes(url:String, redirects:Int = 0):Bytes
	{
		if (redirects > 5)
			throw 'Too many redirects';

		var http:Http = new Http(url);
		http.cnxTimeout = CONNECTION_TIMEOUT;
		http.setHeader('User-Agent', 'SynapseEngine/' + CURRENT_VERSION);
		http.setHeader('Accept', url == API_URL ? 'application/vnd.github+json' : 'application/octet-stream');

		var statusCode:Int = 0;
		var error:String = null;
		http.onStatus = function(code:Int) statusCode = code;
		http.onError = function(msg:String) error = msg;

		var output = new haxe.io.BytesOutput();
		http.customRequest(false, output);

		if (statusCode >= 300 && statusCode < 400)
		{
			var location:String = getHeader(http, 'Location');
			if (location == null)
				throw 'Redirect without a location (HTTP $statusCode)';
			return httpGetBytes(location, redirects + 1);
		}

		if (error != null)
			throw error;
		if (statusCode != 0 && (statusCode < 200 || statusCode >= 300))
			throw 'HTTP $statusCode';

		return output.getBytes();
	}

	static function getHeader(http:Http, name:String):String
	{
		if (http.responseHeaders == null)
			return null;
		for (key in http.responseHeaders.keys())
			if (key.toLowerCase() == name.toLowerCase())
				return http.responseHeaders.get(key);
		return null;
	}
	#end

	static function runAsync(job:Void->Void):Void
	{
		#if target.threaded
		Thread.create(job);
		#else
		job();
		#end
	}
}
