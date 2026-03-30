package backend;

#if DISCORD_ALLOWED
import hxdiscord_rpc.Discord;
import hxdiscord_rpc.Types;
import sys.thread.Thread;

class DiscordClient
{
	public static var initialized:Bool = false;

	private static final _defaultID:String = '1477060024458281123';

	public static var clientID(default, set):String = _defaultID;

	private static function set_clientID(newID:String):String
	{
		var change:Bool = (clientID != newID);
		clientID = newID;

		if (change && initialized)
		{
			shutdown();
			load();
			changePresence();
		}
		return newID;
	}

	#if MODS_ALLOWED
	public static function loadModRPC()
	{
		var pack:Dynamic = Mods.getPack();
		if (pack != null && pack.discordRPC != null && pack.discordRPC != clientID)
			clientID = pack.discordRPC;
	}
	#end

	public static function load():Void
	{
		if (initialized)
			return;

		final handlers:DiscordEventHandlers = new DiscordEventHandlers();
		handlers.ready = cpp.Function.fromStaticFunction(onReady);
		handlers.disconnected = cpp.Function.fromStaticFunction(onDisconnected);
		handlers.errored = cpp.Function.fromStaticFunction(onError);
		Discord.Initialize(clientID, cpp.RawPointer.addressOf(handlers), false, null);

		Thread.create(function():Void
		{
			while (true)
			{
				Discord.RunCallbacks();
				Sys.sleep(1);
			}
		});

		if (Lib.application != null && !Lib.application.onExit.has(shutdown))
			Lib.application.onExit.add(shutdown);

		initialized = true;
	}

	public static function changePresence(details:String = 'In the Menus', ?state:String, ?smallImageKey:String, ?hasStartTimestamp:Bool,
			?endTimestamp:Float):Void
	{
		final discordPresence:DiscordRichPresence = new DiscordRichPresence();
		var startTimestamp:Float = if (hasStartTimestamp) Date.now().getTime() else 0;

		if (endTimestamp > 0)
			endTimestamp = startTimestamp + endTimestamp;

		discordPresence.details = details;

		if (state != null)
			discordPresence.state = state;

		discordPresence.largeImageKey = 'icon';
		discordPresence.largeImageText = 'Synapse Engine v${Constants.SYNAPSE_ENGINE_VERSION}';
		discordPresence.smallImageKey = smallImageKey;
		discordPresence.startTimestamp = Std.int(startTimestamp / 1000);
		discordPresence.endTimestamp = Std.int(endTimestamp / 1000);
		Discord.UpdatePresence(cpp.RawConstPointer.addressOf(discordPresence));
	}

	private static function onReady(request:cpp.RawConstPointer<DiscordUser>):Void
	{
		final user:cpp.Star<DiscordUser> = cpp.ConstPointer.fromRaw(request).ptr;

		if (Std.parseInt(cast(user.discriminator, String)) != 0)
			trace('(Discord) Connected to User "${cast (user.username, String)}#${cast (user.discriminator, String)}"');
		else
			trace('(Discord) Connected to User "${cast (user.username, String)}"');

		changePresence('Just Started');
	}

	public static function resetClientID():Void
	{
		clientID = _defaultID;
	}

	public static function shutdown(?exitCode:Int):Void
	{
		if (!initialized)
			return;
		initialized = false;
		Discord.Shutdown();
	}

	private static function onDisconnected(errorCode:Int, message:cpp.ConstCharStar):Void
	{
		trace('(Discord) Disconnected ($errorCode: ${cast (message, String)})');
	}

	private static function onError(errorCode:Int, message:cpp.ConstCharStar):Void
	{
		trace('(Discord) Error ($errorCode: ${cast (message, String)})');
	}
}
#end
