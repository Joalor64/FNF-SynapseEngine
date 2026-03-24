package backend.external;

#if windows
@:cppFileCode('
    #include <Windows.h>
    ')
class WindowsAPI
{
	@:functionCode('
        int result = MessageBox(GetActiveWindow(), message, caption, icon | MB_SETFOREGROUND);
    ')
	public static function showMessageBox(caption:String, message:String, icon:MessageBoxIcon = MSG_WARNING):Void
	{
	}

	public static function messageBox(caption:String, message:String, icon:MessageBoxIcon = MSG_WARNING):Void
	{
		showMessageBox(caption, message, icon);
	}
}

@:enum abstract MessageBoxIcon(Int)
{
	var MSG_ERROR:MessageBoxIcon = 0x00000010;
	var MSG_QUESTION:MessageBoxIcon = 0x00000020;
	var MSG_WARNING:MessageBoxIcon = 0x00000030;
	var MSG_INFORMATION:MessageBoxIcon = 0x00000040;
}
#end
