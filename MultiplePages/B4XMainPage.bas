﻿B4A=true
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
	Private btnPlay As B4XView
End Sub

Public Sub Initialize
End Sub

'This event will be called once, before the page becomes visible.
Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
	Root.LoadLayout("Main")
	Dim gp As GamePage
	B4XPages.AddPage("gamepage", gp.Initialize)
End Sub

Private Sub btnPlay_Click
	B4XPages.ShowPage("gamepage")
End Sub