B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=6.3
@EndOfDesignText@
Sub Class_Globals
	Public bw As X2BodyWrapper
	Public Size As B2Vec2
	Private xui As XUI
End Sub

Public Sub Initialize (wrapper As X2BodyWrapper)
	bw = wrapper
	Dim x2 As X2Utils = bw.X2
	Dim LengthMeters As Float = x2.RndFloat(1, 2) 'maximum size is x2.GraphicCache.MAX_SIZE_FOR_ANTIALIAS / x2.mBCPixelsPerMeter
	Size = x2.CreateVec2(LengthMeters, 0.3)
	
	Dim LengthBCPixels As Int = x2.MetersToBCPixels(LengthMeters)
	'get a BitmapCreator from the cache.
	Dim bc As BitmapCreator = x2.GraphicCache.GetBitmapCreator(LengthBCPixels)
	Dim r As B4XRect
	Dim border As Int = 3
	r.Initialize(border, border, LengthBCPixels - border, x2.MetersToBCPixels(Size.Y) - border)
	bc.DrawRectRounded2(r, bw.mGame.BlockBrush, True, border, 5)
	r.Initialize(0, 0, r.Right + border, r.Bottom + border)
	bc.DrawRectRounded(r, 0xAA919191, False, border, 5)
	bc.DrawCircle(r.CenterX, r.CenterY, x2.MetersToBCPixels(0.1), xui.Color_Black, True, 0)
	bc.DrawCircle(r.CenterX, r.CenterY, x2.MetersToBCPixels(0.1) + 2, 0xAA919191, False, 2)
	Dim sb As X2ScaledBitmap
	sb.Bmp = bc.Bitmap.Crop(0, 0, r.Right, r.Bottom) 
	sb.Scale = 1 'scale = 1 !!!
	'This is a temporary graphic.
	Dim GraphicName As String = x2.GraphicCache.GetTempName
	 x2.GraphicCache.PutGraphic(GraphicName, Array(sb))
	bw.GraphicName = GraphicName
	
End Sub

Public Sub Tick (GS As X2GameStep)
	Dim v As B2Vec2 = bw.X2.ScreenAABB.Center.CreateCopy
	'Check the distance from the center.
	v.SubtractFromThis(bw.Body.Position)
	If v.Length > 10 Then
		bw.Delete(GS)
	Else
		bw.UpdateGraphic (GS, False)
	End If
End Sub