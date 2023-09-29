# Notepad++ User Scripts

Add the content of a given script to `/NotepadPlus/InternalCommands/Macros` in the `%APPDATA%\Notepad++\shortcuts.xml` configuration file.  For example:

```xml
<NotepadPlus>
    <InternalCommands />
    <Macros>
        <Macro name="Trim Trailing Space and Save" Ctrl="no" Alt="yes" Shift="yes" Key="83">
            <Action type="2" message="0" wParam="42024" lParam="0" sParam="" />
            <Action type="2" message="0" wParam="41006" lParam="0" sParam="" />
        </Macro>
    </Macros>
	<!-- ... -->
</NotepadPlus>
```