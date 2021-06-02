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
	Private Images As List
	Private Height As Int
	Private xui As XUI
	Private Counter As Int
	Private UpdateInterval As Int = 1
End Sub

Public Sub Initialize (vGame As Game)
	mGame = vGame
	X2 = mGame.X2
	Images.Initialize
	'Update the background every 2 iterations:
	If xui.IsB4A Then UpdateInterval = 2
	bc.Initialize(X2.MainBC.mWidth / BackgroundExtraScale, X2.MainBC.mHeight / BackgroundExtraScale)
	For i = 4 To 1 Step - 1
		Dim bmp As X2ScaledBitmap = X2.LoadBmp2(File.DirAssets, $"landscape${i}.png"$, X2.ScreenAABB.Width, X2.ScreenAABB.Height, 1, False)
		If i = 4 Then
			'The furthest image is copied as-is. We don't want to skip the transparent parts. So it is a BitmapCreator instead of CompressedBC.
			Images.Add(X2.BitmapToBC(bmp.Bmp, BackgroundExtraScale))
		Else
			bc.CopyPixelsFromBitmap(bmp.Bmp)
			Images.Add(bc.ExtractCompressedBC(bc.TargetRect, X2.GraphicCache.CBCCache))
		End If
	Next
	'The ground height. The area underneath the ground level is covered by the green brown ground.
	Height = bc.mHeight - X2.MetersToBCPixels(mGame.GroundLevel) / BackgroundExtraScale
End Sub

Public Sub Tick (GS As X2GameStep)
	Counter = Counter + 1
	If GS.ShouldDraw And Counter Mod UpdateInterval = 0 Then
		Dim left As Int = X2.MetersToBCPixels(X2.ScreenAABB.BottomLeft.X) / BackgroundExtraScale
		For i = 0 To Images.Size - 1
			'go over each of the images and draw it twice based on the current world coordinates.
			Dim cbc As Object = Images.Get(i)
			Dim dt As DrawTask
			'The further the image the slower it moves:
			Dim FixedLeft As Int = left / ((Images.Size - i) + 3)
			FixedLeft = FixedLeft Mod bc.mWidth
			If FixedLeft < 0 Then FixedLeft = FixedLeft + bc.mWidth
			Dim SrcRect As B4XRect
			SrcRect.Initialize(FixedLeft, 0, bc.mWidth, Height)
			dt = bc.CreateDrawTask(cbc, SrcRect, 0, 0, True)
			dt.IsCompressedSource = i > 0
			If FixedLeft > 0 Then
				dt.TargetBC = bc
				GS.DrawingTasks.Add(dt)
				Dim SrcRect As B4XRect
				SrcRect.Initialize(0, 0, FixedLeft, Height)
				dt = bc.CreateDrawTask(cbc, SrcRect, bc.mWidth - FixedLeft, 0, True)
				dt.IsCompressedSource = i > 0
			End If
			dt.TargetBC = bc
			GS.DrawingTasks.Add(dt)
		Next
	End If
End Sub

Public Sub DrawComplete
	mGame.X2.SetBitmapWithFitOrFill(mGame.ivBackground, bc.Bitmap)
End Sub


