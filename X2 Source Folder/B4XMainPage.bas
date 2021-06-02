B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=9.85
@EndOfDesignText@
#Region Shared Files
#CustomBuildAction: folders ready, %WINDIR%\System32\Robocopy.exe,"..\..\Shared Files" "..\Files"
'Ctrl + click to sync files: ide://run?file=%WINDIR%\System32\Robocopy.exe&args=..\..\Shared+Files&args=..\Files&FilesSync=True
#End Region

'update x2.b4xlib ide://run?file=%PROJECT%\..\..\..\build_x2lib.bat&WorkingDirectory=%PROJECT%\..\
'open the b4xlib manifest file with notepad++ ide://run?file=%COMSPEC%&args=/c&args=%PROJECT%\..\manifest.txt

Sub Class_Globals
	Private Root As B4XView
	Private xui As XUI
	Public mGame As Game
End Sub

Public Sub Initialize
	
End Sub

'This event will be called once, before the page becomes visible.
Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
	If Root.Width = 0 Or Root.Height = 0 Then
		Wait For  B4XPage_Resize(Width As Int, Height As Int)
	End If
	mGame.Initialize(Root)
	mGame.X2.Start
End Sub

Private Sub B4XPage_Resize (Width As Int, Height As Int)
	mGame.Resize
End Sub