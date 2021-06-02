B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=6.47
@EndOfDesignText@
Sub Class_Globals
	Public X2 As X2Utils
	Private xui As XUI 'ignore
	Public world As B2World
	Public Ground As X2BodyWrapper
	Private ivForeground As B4XView
	Private ivBackground As B4XView
	Public lblStats As B4XView
	Public TileMap As X2TileMap
	Public Const ObjectLayer As String = "Object Layer 1"
	Private cvs As B4XCanvas
End Sub

Public Sub Initialize (Parent As B4XView)
	Parent.LoadLayout("GameLayout")
	world.Initialize("world", world.CreateVec2(0, -3))
	X2.Initialize(Me, ivForeground, world)
	Dim WorldWidth As Float = 6 'meters
	Dim WorldHeight As Float = WorldWidth / 1.333 'same ratio as in the designer script
	X2.ConfigureDimensions(world.CreateVec2(WorldWidth / 2, WorldHeight / 2), WorldWidth)
	'Load the graphics and add them to the cache.
	'comment to disable debug drawing
	'X2.EnableDebugDraw
	CreateStaticBackground
	Dim p As B4XView = xui.CreatePanel("")
	p.SetLayoutAnimated(0, 0, 0, X2.MainBC.mWidth, X2.MainBC.mHeight)
	cvs.Initialize(p)
	Start
	
End Sub

Private Sub CreateStaticBackground
	Dim bc As BitmapCreator
	bc.Initialize(ivBackground.Width / xui.Scale / 2, ivBackground.Height / xui.Scale / 2)
	bc.FillGradient(Array As Int(0xFF006EFF, 0xFF00DAAD), bc.TargetRect, "TOP_BOTTOM")
	X2.SetBitmapWithFitOrFill(ivBackground, bc.Bitmap)
End Sub

Public Sub Resize
	X2.ImageViewResized
End Sub

Public Sub Tick (GS As X2GameStep)
	For Each body As B2Body In world.AllBodies
		Dim bw As X2BodyWrapper = body.Tag
		If body.GetContactList(True).Size > 0 Then
			bw.CurrentFrame = 1
		Else
			bw.CurrentFrame = 0
		End If
	Next
End Sub

Public Sub Start
	X2.Reset
	TileMap.Initialize(X2, File.DirAssets, "collisions.json", Null)
	TileMap.SetSingleTileDimensionsInMeters(X2.ScreenAABB.Width / TileMap.TilesPerRow, X2.ScreenAABB.Height / TileMap.TilesPerColumn)
	TileMap.PrepareObjectsDef(ObjectLayer)
	Dim ol As X2ObjectsLayer = TileMap.Layers.Get(ObjectLayer)
	For Each template As X2TileObjectTemplate In ol.ObjectsById.Values
		Dim bw As X2BodyWrapper = TileMap.CreateObject(template)
		CreateGraphics(bw, template)
	Next
	X2.Start
End Sub

Private Sub CreateGraphics (bw As X2BodyWrapper, template As X2TileObjectTemplate)
	cvs.ClearRect(cvs.TargetRect)
	Dim size As B2Vec2 = X2.GetShapeWidthAndHeight(template.FixtureDef.Shape)
	Dim rect As B4XRect
	rect.Initialize(0, 0, X2.MetersToBCPixels(size.X), X2.MetersToBCPixels(size.Y))
	Dim images As List
	images.Initialize
	Dim clrs() As Int
	Dim text As String
	If bw.Name = "ground" Then
		clrs = Array As Int(xui.Color_Red, xui.Color_Green)
		If bw.Body.FirstFixture.IsSensor Then
			text = "Sensor"
		Else
			Dim explanation As String
			Dim mb As Int = TileMap.GetCustomProperty(template, "mask bits")
			Select mb
				Case 0
					explanation = "none"
				Case 65529
					explanation = "FFFF - 4 - 2"
				Case 65531
					explanation = "FFFF - 4"
				Case 65535
					explanation = "all"
			End Select
			text = $"Mask bits: ${mb} / ${explanation}"$
		End If
	Else
		clrs = Array As Int(0xFFFC7676, 0xFF8EFC76)
		text = $"Category bits: ${TileMap.GetCustomProperty(template, "category bits")}"$
	End If
	Dim fnt As B4XFont = xui.CreateDefaultBoldFont(16 / xui.Scale)
	Dim r As B4XRect = cvs.MeasureText(text, fnt)
	Dim BaseLine As Int = rect.CenterY - r.Height / 2 - r.Top
	For Each c As Int In clrs
		cvs.DrawRect(rect, c, True, 0)
		cvs.DrawText(text, rect.CenterX, BaseLine, fnt, xui.Color_White, "CENTER")
		Dim sb As X2ScaledBitmap
		sb.Scale = 1
		sb.Bmp = cvs.CreateBitmap.Crop(0, 0, rect.Width, rect.Height)
		images.Add(sb)
	Next
	Dim temp As String = X2.GraphicCache.GetTempName
	X2.GraphicCache.PutGraphic(temp, images)
	bw.GraphicName = temp
End Sub


Public Sub DrawingComplete
	
End Sub

'Return True to stop the game loop
Public Sub BeforeTimeStep (GS As X2GameStep) As Boolean
	Return False
End Sub
