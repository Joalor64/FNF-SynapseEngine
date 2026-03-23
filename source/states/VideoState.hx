package states;

import objects.VideoSprite;

class VideoState extends FlxState
{
	#if VIDEOS_ALLOWED
	public var vidPath:String;
	public var isWaiting:Bool;
	public var canSkip:Bool;
	public var loop:Bool;
	public var onComplete:Void->Void;

	public function new(vidPath:String, isWaiting:Bool = false, canSkip:Bool = false, loop:Bool = false, onComplete:Void->Void = null)
	{
		super();

		this.vidPath = vidPath;
		this.isWaiting = isWaiting;
		this.canSkip = canSkip;
		this.loop = loop;
		this.onComplete = onComplete;
	}

	override function create()
	{
		super.create();

		var video:VideoSprite = new VideoSprite(vidPath, isWaiting, canSkip, loop);
		video.finishCallback = onComplete;
		add(video);
		video.play();
	}
	#end
}
