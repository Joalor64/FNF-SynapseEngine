package scripts;

import substates.ScriptedSubState;

class Globals
{
	public static var Function_Stop:Dynamic = 1;
	public static var Function_Continue:Dynamic = 0;
	public static var Function_Halt:Dynamic = 2;

	public static inline function getInstance():Dynamic
	{
		var gameOver = ScriptedSubState.getSubStateByTag('gameover');
		return (PlayState.instance.isDead && gameOver != null) ? gameOver : PlayState.instance;
	}
}
