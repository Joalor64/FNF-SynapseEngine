package backend.external;

#if windows
@:buildXml('
    <target id="haxe">
        <lib name="dwmapi.lib" if="windows" />
    </target>
    ')
@:cppFileCode('
    #include <Windows.h>
    #include <dwmapi.h>
    ')
class WindowsAPI
{
	@:functionCode('
        HWND window = FindWindowA(NULL, Application::current->window->title.c_str());
        int value = enable ? 1 : 0;

        if (window != NULL) {
            DwmSetWindowAttribute(window, 20, &value, sizeof(value));

            ShowWindow(window, 0);
            ShowWindow(window, 1);
            SetFocus(window);
        }
    ')
    public static function setDarkMode(enable:Bool):Void {}

    public static function darkMode(enable:Bool):Void
	{
		setDarkMode(enable);
	}

	@:functionCode('
        int result = MessageBox(GetActiveWindow(), message, caption, icon | MB_SETFOREGROUND);
    ')
	public static function showMessageBox(caption:String, message:String, icon:MessageBoxIcon = MSG_WARNING):Void {}

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