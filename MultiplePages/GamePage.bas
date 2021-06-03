B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=9
@EndOfDesignText@
Sub Class_Globals
	Private Root As B4XView 'ignore
	Private xui As XUI 'ignore
	Public mGame As Game
End Sub

'You can add more parameters here.
Public Sub Initialize As Object
	Return Me
End Sub

'This event will be called once, before the page becomes visible.
Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
	'load the layout to Root
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
