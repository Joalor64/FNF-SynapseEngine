package states;

import hxvlc.flixel.FlxVideoSprite;

class VideoState extends FlxState
{
	#if VIDEOS_ALLOWED
	public var vidPath:String;
	public var onComplete:Void->Void;

	public function new(vidPath:String, onComplete:Void->Void = null)
	{
		super();

		this.vidPath = vidPath;
		this.onComplete = onComplete;
	}

	override function create()
	{
		super.create();

		var video:FlxVideoSprite = new FlxVideoSprite();
		video.antialiasing = ClientPrefs.data.globalAntialiasing;
		video.bitmap.onFormatSetup.add(() ->
		{
			if (video.bitmap != null && video.bitmap.bitmapData != null)
			{
				final scale:Float = Math.min(FlxG.width / video.bitmap.bitmapData.width, FlxG.height / video.bitmap.bitmapData.height);
				video.setGraphicSize(video.bitmap.bitmapData.width * scale, video.bitmap.bitmapData.height * scale);
				video.screenCenter();
			}
		});
		add(video);
		video.load(Paths.video(vidPath));
		video.play();
		video.bitmap.onEndReached.add(() ->
		{
			video.stop();
			video.destroy();
			onComplete();
		});
	}
	#end
}
