B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=6.3
@EndOfDesignText@
Sub Class_Globals
	Public mGame As Game
	Private bc As BitmapCreator
	Private targetbc As BitmapCreator
	Private xui As XUI 'ignore
	Private HalfWidth As Int
	Private SrcRect As B4XRect
	Private TargetView As B4XView
	Private X2 As X2Utils
	'As an optimization we use lower resolution for the background.
	Private BackgroundExtraScale As Float = 1.5
	Private LastCenter As Int = -1000
	Private NewBackground As Boolean
End Sub

Public Sub Initialize (vGame As Game)
	mGame = vGame
	X2 = mGame.X2
	Dim bmp As X2ScaledBitmap = X2.LoadBmp2(File.DirAssets, "swamp.png", X2.ScreenAABB.Width, _
		X2.ScreenAABB.Height, 1, False)
	targetbc = X2.BitmapToBC(bmp.Bmp, BackgroundExtraScale)
	HalfWidth = targetbc.mWidth
	Dim bc As BitmapCreator
	bc.Initialize(targetbc.mWidth * 2, targetbc.mHeight)
	bc.DrawBitmapCreator(targetbc, targetbc.TargetRect, 0, 0, True)
	bc.DrawBitmapCreator(targetbc, targetbc.TargetRect, targetbc.mWidth - 1, 0, True)
	TargetView = mGame.mBackgroundView
	SrcRect.Initialize(0, 0, 0, bc.mHeight)
End Sub

Public Sub Tick (GS As X2GameStep)
	If GS.ShouldDraw Then
		Dim center As Int = X2.MetersToBCPixels(X2.ScreenAABB.Center.X) / BackgroundExtraScale
		If LastCenter = center Then Return
		LastCenter = center
		NewBackground = True
		Dim i As Int = center Mod HalfWidth
		If i < 0 Then i = i + HalfWidth
		SrcRect.Left = i
		SrcRect.Width = targetbc.mWidth
		Dim dt As DrawTask = targetbc.CreateDrawTask(bc, SrcRect, 0, 0, True)
		dt.TargetBC = targetbc
		GS.DrawingTasks.Add(dt)
	End If
End Sub

Public Sub DrawComplete
	If NewBackground = False Then Return
	NewBackground = False
	mGame.X2.SetBitmapWithFitOrFill(TargetView, targetbc.Bitmap)
End Sub


