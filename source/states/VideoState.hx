package states;

import objects.VideoSprite;

// To-Do: re-do this code
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
	}
	#end
}
