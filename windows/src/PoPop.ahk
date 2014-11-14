#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

#Include %A_ScriptDir%\AHKsock.ahk
    
;Allow multiple instances. This is to allow you to stress-test the server. For more info on how to perform the
;stress-test, see second comment block in the ACCEPTED event of the Send() function in the server script.
#SingleInstance, Off

DEFAULT_IP=10.0.2.2
DEFAULT_PORT=12345
 
;for first use, there isn't a config file, show config window
IfNotExist, config.ini
    GoSub, Config

;determine the ip and port of the server end
IniRead, sServer, config.ini, server, ip, %DEFAULT_IP%
IniRead, sPort, config.ini, server, port, %DEFAULT_PORT%
	
;Register OnExit subroutine so that AHKsock_Close is called before exit
OnExit, CloseAHKsock

;Add menu item for exiting gracefully (see comment block in CloseAHKsock)
Menu, Tray, NoStandard
Menu, Tray, Add, 配置, Config
Menu, Tray, Add, 退出, CloseAHKsock

;Set up an error handler (this is optional)
AHKsock_ErrorHandler("AHKsockErrors")
	
;borrow from http://www.autohotkey.com/board/topic/36510-detect-flashingblinking-window-on-taskbar/?p=229583
DetectHiddenWindows, On
Script_Hwnd := WinExist("ahk_class AutoHotkey ahk_pid " DllCall("GetCurrentProcessId"))
DetectHiddenWindows, Off
;Register shell hook to detect flashing windows.
DllCall("RegisterShellHookWindow", "uint", Script_Hwnd)
OnMessage(DllCall("RegisterWindowMessage", "str", "SHELLHOOK"), "ShellEvent")
;...

Return

CloseAHKsock:
    AHKsock_Close()
	OutputDebug, Exit
ExitApp

Config:
	Gui, config:New,,配置
	IniRead, sServer, config.ini, server, ip, %DEFAULT_IP%
	IniRead, sPort, config.ini, server, port, %DEFAULT_PORT%
	Gui, Add, Text,, Linux宿主机IP:
	Gui, Add, Text,, Linux宿主机端口:
	Gui, Add, Edit, vIp ym, %sServer%
	Gui, Add, Edit, vPort, %sPort%
	Gui, Add, Button, default gSave, 保存
	Gui, Show
Return
	
Save:
	Gui, config:Submit
	IniWrite, %Ip%, config.ini, server, ip
	IniWrite, %Port%, config.ini, server, port
	sServer=%Ip%
	sPort=%Port%
Return

Message := ""

ShellEvent(wParam, lParam) {
	global Message
    if (wParam = 0x8006) { ; HSHELL_FLASH
		
		;lParam contains the ID of the window which flashed:
		WinGetTitle, win_title, ahk_id %lParam%
		WinGetClass, win_class, ahk_id %lParam%
		OutputDebug, %win_title%, %win_class%
		Message = %win_title%
		
		if (win_class = "SessionForm") {
			OutputDebug sessionform
			GoSub DoSend
		}
		if (win_class = "TeamForm") {	
			OutputDebug %wParam%	
			OutputDebug teamform
			GoSub DoSend
		}

	}
}

DoSend:
	OutputDebug, %sServer% %sPort%
	If (i := AHKsock_Connect(sServer, sPort, "Send")) {
		OutputDebug, % "AHKsock_Connect() failed with return value = " i " and ErrorLevel = " ErrorLevel
	}		
Return

Send(sEvent, iSocket = 0, sName = 0, sAddr = 0, sPort = 0, ByRef bRecvData = 0, bRecvDataLength = 0) {
	global Message
	bDataLength := StrPut(Message, "")
	VarSetCapacity(bData, bDataLength)
	StrPut(Message, &bData, "")
	OutputDebug, length: %bDataLength%
	OutputDebug, %sEvent%
	
    If (sEvent = "CONNECTED") {        
        ;Check if the connection attempt was succesful
        If (iSocket = -1) {
            OutputDebug, % "Client - AHKsock_Connect() failed. Exiting..."
            AHKsock_Close()
        } Else OutputDebug, % "Client - AHKsock_Connect() successfully connected!"        
    } Else If (sEvent = "DISCONNECTED") {      
        OutputDebug, % "Client - The server closed the connection. Exiting..."
		AHKsock_Close()
    } Else If (sEvent = "SEND") {   
        bDataSent := 0
        Loop {           
            ;Try to send the data
            If ((i := AHKsock_Send(iSocket, &bData + bDataSent, bDataLength - bDataSent)) < 0) {
                
                ;Check if we received WSAEWOULDBLOCK.
                If (i = -2) {
                    ;That's ok. We can leave and we'll keep sending from
                    ;where we left off the next time we get the SEND event.
                    Return
                    
                ;Something bad has happened with AHKsock_Send
                } Else OutputDebug, % "Client - AHKsock_Send failed with return value = " i " and ErrorLevel = " ErrorLevel
                
            ;We were able to send bytes!
            } Else OutputDebug, % "Sent " i " bytes!"
            
            ;Check if everything was sent
            If (i < bDataLength - bDataSent)
                bDataSent += i ;Advance the offset so that at the next iteration, we'll start sending from where we left off
            Else Break ;We're done
        }

	} Else If (sEvent = "RECEIVED") {
        OutputDebug, receive some data
    }
}

;We're not actually handling errors here. This is here just to make us aware of errors if any do come up.
AHKsockErrors(iError, iSocket) {
    OutputDebug, % "Client - Error " iError " with error code = " ErrorLevel ((iSocket <> -1) ? " on socket " iSocket : "")
}
