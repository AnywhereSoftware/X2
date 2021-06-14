B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=9
@EndOfDesignText@
'version 1.00
Sub Class_Globals
	Private X2 As X2Utils
	Private bc As BitmapCreator
	'As an optimization we use lower resolution for the background.
	Private BackgroundExtraScale As Float = 1.2
	Private UpdateInterval As Int = 2
	Private Images As List
	Private xui As XUI
	Private Counter As Int
	Private mGame As Game
	Private LastCreatedLeft = -99999999, LastDrawnLeft = -999999 As Int
End Sub

Public Sub Initialize (vGame As Game, ImagesPrefix As String, ImagesSuffix As String, NumberOfImages As Int)
	mGame = vGame
	X2 = mGame.X2
	Images.Initialize
	bc.Initialize(X2.MainBC.mWidth / BackgroundExtraScale, X2.MainBC.mHeight / BackgroundExtraScale)
	For i = NumberOfImages - 1 To 0 Step -1
		Dim bmp As X2ScaledBitmap = X2.LoadBmp2(File.DirAssets, $"${ImagesPrefix}_${i}.${ImagesSuffix}"$, X2.ScreenAABB.Width, X2.ScreenAABB.Height, 1, False)
		If i = NumberOfImages - 1 Then
			'The furthest image is copied as-is. We don't want to skip the transparent parts. So it is a BitmapCreator instead of CompressedBC.
			Images.Add(X2.BitmapToBC(bmp.Bmp, BackgroundExtraScale))
		Else
			bc.CopyPixelsFromBitmap(bmp.Bmp)
			Images.Add(bc.ExtractCompressedBC(bc.TargetRect, X2.GraphicCache.CBCCache))
		End If
	Next
	End Sub

Public Sub Tick (GS As X2GameStep)
	Counter = Counter + 1
	If GS.ShouldDraw And Counter Mod UpdateInterval = 0 Then
		Dim left As Int = X2.MetersToBCPixels(X2.ScreenAABB.BottomLeft.X) / BackgroundExtraScale
		If LastDrawnLeft = left Then Return
		LastCreatedLeft = left
		For i = 0 To Images.Size - 1
			'go over each of the images and draw it twice based on the current world coordinates.
			Dim cbc As Object = Images.Get(i)
			Dim dt As DrawTask
			'The further the image the slower it moves:
			Dim FixedLeft As Int = left / ((Images.Size - i) + 3)
			FixedLeft = FixedLeft Mod bc.mWidth
			If FixedLeft < 0 Then FixedLeft = FixedLeft + bc.mWidth
			Dim SrcRect As B4XRect
			SrcRect.Initialize(FixedLeft, 0, bc.mWidth, bc.mHeight)
			dt = bc.CreateDrawTask(cbc, SrcRect, 0, 0, True)
			dt.IsCompressedSource = i > 0
			If FixedLeft > 0 Then
				dt.TargetBC = bc
				GS.DrawingTasks.Add(dt)
				Dim SrcRect As B4XRect
				SrcRect.Initialize(0, 0, FixedLeft, bc.mHeight)
				dt = bc.CreateDrawTask(cbc, SrcRect, bc.mWidth - FixedLeft, 0, True)
				dt.IsCompressedSource = i > 0
			End If
			dt.TargetBC = bc
			GS.DrawingTasks.Add(dt)
			
		Next
	End If
End Sub

Public Sub DrawComplete
	If LastDrawnLeft = LastCreatedLeft Then Return
	LastDrawnLeft = LastCreatedLeft
	X2.SetBitmapWithFitOrFill(mGame.ivBackground, bc.Bitmap)
End Sub


