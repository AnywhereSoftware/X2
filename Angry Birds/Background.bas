B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=6.3
@EndOfDesignText@
Sub Class_Globals
	Public mGame As Game
	Private bc As BitmapCreator
	Private X2 As X2Utils
	'As an optimization we use lower resolution for the background.
	Private BackgroundExtraScale As Float = 1.5
	Private Image As BitmapCreator
	Private xui As XUI 'ignore
	Private Counter As Int
	Private UpdateInterval As Int = 1
End Sub

Public Sub Initialize (vGame As Game)
	mGame = vGame
	X2 = mGame.X2
	bc.Initialize(X2.MainBC.mWidth / BackgroundExtraScale, X2.MainBC.mHeight / BackgroundExtraScale)
	Dim sb As X2ScaledBitmap = X2.LoadBmp(File.DirAssets, "background.jpg", _
		 mGame.TotalWidth / BackgroundExtraScale, mGame.WorldHeight / BackgroundExtraScale, False)
	Image = X2.BitmapToBC(sb.Bmp, 1)
End Sub

Public Sub Tick (GS As X2GameStep)
	Counter = Counter + 1
	If GS.ShouldDraw And Counter Mod UpdateInterval = 0 Then
		Dim left As Int = X2.MetersToBCPixels(X2.ScreenAABB.BottomLeft.X) / BackgroundExtraScale
		Dim SrcRect As B4XRect
		SrcRect.Initialize(left, 0, left + X2.MetersToBCPixels(X2.ScreenAABB.Width), Image.mHeight)
		Dim dt As DrawTask = bc.CreateDrawTask(Image, SrcRect, 0, 0, True)
		dt.TargetBC = bc
		GS.DrawingTasks.Add(dt)
	End If
End Sub

Public Sub DrawComplete
	mGame.X2.SetBitmapWithFitOrFill(mGame.ivBackground, bc.Bitmap)
End Sub


