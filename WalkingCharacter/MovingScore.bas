B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=6.3
@EndOfDesignText@
Sub Class_Globals
	Private xui As XUI
	Private bw As X2BodyWrapper
	Private StartBCPosition, TargetBCPosition As B2Vec2
	Private degrees As Int
End Sub

Public Sub Initialize (wrapper As X2BodyWrapper, score As Int)
	bw = wrapper
	'This body doesn't have any fixture so it is always considered to be invisible.
	'We must set TickIfInvisible to True or it will never tick. A better option would have to create a fixture...
	bw.TickIfInvisible = True
	'create the score graphics
	Dim x2 As X2Utils = bw.X2
	Dim GraphicName As String = "score " & score
	If x2.GraphicCache.GetGraphicsCount(GraphicName) = 0 Then
		Dim cvs As B4XCanvas = x2.GraphicCache.GetCanvas(50) 
		Dim bmps As List
		bmps.Initialize
		Dim FontSize As Float = 30 / xui.Scale
		Dim fnt As B4XFont = xui.CreateDefaultBoldFont(FontSize)
		Dim r As B4XRect = cvs.MeasureText(score, fnt)
		Dim BaseLine As Int = cvs.TargetRect.CenterY - r.Height / 2 - r.Top
		'Creating new graphics is a relatively heavy operation. Use cached graphics whenever possible.
		For Each clr As Int In Array(0xFF00B2FF, xui.Color_White)
			cvs.ClearRect(cvs.TargetRect)
			cvs.DrawText(score,  cvs.TargetRect.CenterX, BaseLine, fnt, clr, "CENTER")
			Dim sb As X2ScaledBitmap
			sb.Scale = 1
			'Use X2.CreateImmutableBitmap if not cropping.
			Log(score)
			sb.Bmp = cvs.CreateBitmap.Crop(cvs.TargetRect.CenterX - r.Width / 2, cvs.TargetRect.CenterY - r.Height / 2, r.Width + 1, r.Height + 1)
			bmps.Add(sb)
		Next
		bw.X2.GraphicCache.PutGraphic2(GraphicName, bmps, False, 5) 'no antialiasing.
	End If
	bw.GraphicName = GraphicName 'this also sets bw.NumberOfFrames
	bw.SwitchFrameIntervalMs = 200
	StartBCPosition = bw.X2.WorldPointToMainBC(bw.Body.Position.X, bw.Body.Position.Y)
	Dim target As B2Vec2
	target.Set(bw.X2.ScreenAABB.BottomLeft.X + 0.5, bw.X2.ScreenAABB.TopRight.Y - 0.2)
	TargetBCPosition = bw.X2.WorldPointToMainBC(target.X, target.Y)
End Sub
 
Public Sub Tick (GS As X2GameStep)
	bw.SwitchFrameIfNeeded(GS)
	Dim CurrentTime As Int = bw.GetCurrentTime(GS)
	'(target - start) * CurrentTime / TimeToLive + start
	Dim position As B2Vec2 = TargetBCPosition.CreateCopy
	position.SubtractFromThis(StartBCPosition)
	position.MultiplyThis(CurrentTime / bw.TimeToLiveMs)
	position.AddToThis(StartBCPosition)
	degrees = degrees + 2 'making the score rotate will work, however rotating "temporary" graphics can have an impact on the performance.
	If GS.ShouldDraw Then
		GS.DrawingTasks.Add(bw.X2.GraphicCache.GetDrawTask(bw.GraphicName, bw.CurrentFrame, degrees, False, False, position.X, position.Y))
	End If
	If CurrentTime > bw.TimeToLiveMs Then
		bw.Delete(GS)
	End If
End Sub