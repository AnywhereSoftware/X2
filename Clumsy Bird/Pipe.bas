B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=6.47
@EndOfDesignText@
Sub Class_Globals
	Public bw As X2BodyWrapper
	Private cbc As CompressedBC
	Private rect As B4XRect
End Sub

Public Sub Initialize (wrapper As X2BodyWrapper, size As B2Vec2)
	bw = wrapper
	Dim x2 As X2Utils = bw.X2
	cbc = bw.X2.GraphicCache.GetGraphic2(bw.GraphicName, 0, 0, False, bw.FlipVertical)
	If bw.Name = "top pipe" Then
		rect.Initialize(0, cbc.mHeight - x2.MetersToBCPixels(size.Y), cbc.mWidth, cbc.mHeight)
	Else
		rect.Initialize(0, 0, cbc.mWidth, x2.MetersToBCPixels(size.Y))
	End If
End Sub

Public Sub Tick (GS As X2GameStep)
	If bw.IsVisible = False Then
		bw.Delete(GS)
		Return
	End If
	If GS.ShouldDraw Then
		Dim bcposition As B2Vec2 = bw.X2.WorldPointToMainBC(bw.Body.Position.X, bw.Body.Position.Y)
		Dim dt As DrawTask = bw.X2.CreateDrawTaskFromCompressedBC(cbc, bcposition, rect)
		GS.DrawingTasks.Add(dt)
	End If
End Sub