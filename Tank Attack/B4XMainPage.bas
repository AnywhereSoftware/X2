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

'Ctrl + click to export as zip: ide://run?File=%B4X%\Zipper.jar&Args=Project.zip&VMArgs=-DZeroSharedFiles%3DTrue

Sub Class_Globals
	Private Root As B4XView
	Private xui As XUI
	Public mGame As Game
End Sub

Public Sub Initialize
'	B4XPages.GetManager.LogEvents = True
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

Private Sub B4XPage_Appear
	If mGame.IsInitialized And mGame.X2.IsRunning = False Then
		mGame.X2.Start
	End If
End Sub

Private Sub B4XPage_Disappear
	If mGame.IsInitialized Then
		mGame.X2.Stop
	End If
End Sub