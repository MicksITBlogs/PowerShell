;** AUTOIT3 settings
#AutoIt3Wrapper_UseX64=Y                         ;(Y/N) Use X64 versions for AutoIt3_x64 or AUT2EXE_x64. Default=N
;** AUT2EXE settings


If $CmdLine[0] = 0 Then 
    ; Rerun ourself and let this copy return to the task sequencer 
    Run('"' & @AutoItExe & '" rerun') 
	Exit 
EndIf

Sleep(2000)
$WindowName = "Installation Progress"
If WinExists($WindowName) Then 
    $size = WinGetPos($WindowName)
	$size[1] = 0
    WinMove($WindowName, "", $size[0], $size[1]) 
EndIf
