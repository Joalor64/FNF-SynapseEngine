package backend;

import macros.Macros;

class Constants
{
	public static var SYNAPSE_ENGINE_VERSION:String = '0.1.0';
	public static var PSYCH_ENGINE_VERSION:String = '0.6.3';
	public static var GIT_COMMIT_HASH:String = Macros.getCommitId();
	public static var DEFAULT_DIFFICULTIES:Array<String> = ['easy', 'normal', 'hard'/*, 'erect'*/];
}
