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
	Private water As X2BodyWrapper
	Private waterlevel As Float
	Private waterlevelsBCPixels As Int
	Private TotalMassOfBodies As Map
	Private Names() As String
	Private BackgroundBC As BitmapCreator
End Sub

Public Sub Initialize (Parent As B4XView)
	Parent.LoadLayout("GameLayout")
	world.Initialize("world", world.CreateVec2(0, -10))
	X2.Initialize(Me, ivForeground, world)
	Dim WorldWidth As Float = 6 'meters
	Dim WorldHeight As Float = WorldWidth / 1.5 'same ratio as in the designer script
	X2.ConfigureDimensions(world.CreateVec2(WorldWidth / 2, WorldHeight / 2), WorldWidth)
	'Load the graphics and add them to the cache.
	'comment to disable debug drawing
	X2.EnableDebugDraw
	'Passing Null for the target view parameter because we are not creating the background with a tile layer.
	TileMap.Initialize(X2, File.DirAssets, "floating bodies.json", Null) 
	TileMap.SetSingleTileDimensionsInMeters(WorldWidth / TileMap.TilesPerRow, WorldHeight / TileMap.TilesPerColumn)
	TileMap.PrepareObjectsDef(ObjectLayer)
	water = TileMap.CreateObject2ByName(ObjectLayer, "water")
	TileMap.CreateObject2ByName(ObjectLayer, "ground")
	waterlevel = water.Body.Position.Y + X2.GetShapeWidthAndHeight(water.Body.FirstFixture.Shape).Y / 2
	waterlevelsBCPixels = X2.WorldPointToMainBC(0, waterlevel).Y
	TotalMassOfBodies.Initialize
	Names = Array As String("boat", "circle", "rectangle 1", "rectangle 2")
	CreateStaticBackground
	CreateBlockGraphics
End Sub

Private Sub CreateStaticBackground
	'Note that ivBackground is in front of ivForeground.
	'the background is scaled down to improve performance.
	BackgroundBC.Initialize(X2.MainBC.mWidth / 2, X2.MainBC.mHeight / 2)
	Dim r As B4XRect
	r.Initialize(0, (waterlevelsBCPixels) / 2 , BackgroundBC.mWidth, BackgroundBC.mHeight)
	'create a semitransparent gradient for the water.
	BackgroundBC.FillGradient(Array As Int(0x88006EFF, 0x8800A7FF), r, "BOTTOM_TOP")
	BackgroundBC.DrawLine(0, BackgroundBC.mHeight - 2, BackgroundBC.mWidth, BackgroundBC.mHeight - 2, 0xFF724600, 6)
	X2.SetBitmapWithFitOrFill(ivBackground, BackgroundBC.Bitmap)
End Sub

Public Sub Resize
	X2.ImageViewResized
End Sub

Public Sub Tick (GS As X2GameStep)
'	If GS.ShouldDraw Then
'		Dim red As BCBrush = BackgroundBC.CreateBrushFromColor(xui.Color_Red)
'		Dim r As B4XRect
'		r.Initialize(0, 0, BackgroundBC.mWidth, waterlevelsBCPixels / 2)
'		GS.DrawingTasks.Add(BackgroundBC.AsyncDrawRect(r, BackgroundBC.CreateBrushFromColor(xui.Color_Transparent), True, 0))
'		For i = 1 To 50
'			GS.DrawingTasks.Add(BackgroundBC.AsyncDrawCircle(Rnd(1, 200), Rnd(1, waterlevelsBCPixels / 2), 10, red, True,  5))
'		Next
'	End If
	If X2.RndFloat(0, 2000) < X2.TimeStepMs Then CreateObject
	'find all in-water bodies and apply the floating force.
	For Each contact As B2Contact In water.Body.GetContactList(True)
		Dim cc As X2BodiesFromContact = X2.GetBodiesFromContact(contact, "water")
		If cc.OtherBody.Body.BodyType = cc.OtherBody.Body.TYPE_DYNAMIC Then
			ApplyFloatingForce(cc.OtherBody)
		End If
	Next
	
End Sub


Public Sub DrawingComplete
'	X2.SetBitmapWithFitOrFill(ivBackground, BackgroundBC.Bitmap)
End Sub

Private Sub ApplyFloatingForce(body As X2BodyWrapper)
	body.Body.AngularDamping = 1
	body.Body.LinearDamping = 1
	Dim drawtask As DrawTask = body.CreateDrawTaskBasedOnCache
	Dim cbc As CompressedBC = drawtask.Source
	'position.Y = MainBC.mHeight - 1 - (y - ScreenAABB.BottomLeft.Y) * mBCPixelsPerMeter
	Dim FirstRow As Int = waterlevelsBCPixels - drawtask.TargetY
	If FirstRow < 0 Then
		Dim MassPixels As Int = TotalMassOfBodies.Get(body.Name)
		Dim center As B2Vec2 = body.Body.WorldCenter
	Else
		'the body is partly in the water
		Dim center As B2Vec2 = body.Body.Position.CreateCopy
		Dim MassPixels As Int = CalcMassBasedOnPixels(cbc, body.Name, FirstRow, center)
	End If
	If X2.DebugDraw.IsInitialized Then
		X2.DebugDraw.MarkedPoints.Add(center)
	End If
	Dim underwatermass As Float = body.Body.Mass * MassPixels / TotalMassOfBodies.Get(body.Name)
	Dim dense As Float = body.Body.FirstFixture.Density
	body.Body.ApplyForce(X2.CreateVec2(0, 10 * underwatermass / dense), center)
End Sub

'This code calculates the body mass and mass center based on the body rotated graphics.
'It accesses an internal structure that is normally not used outside of BitmapCreator.
Private Sub CalcMassBasedOnPixels(cbc As CompressedBC, Name As String, FirstRow As Int, center As B2Vec2) As Int
	If FirstRow < 0 Then Return TotalMassOfBodies.Get(Name)
	Dim totalmass As Int
	Dim CenterX As Float
	Dim CenterY As Float
	Dim RowSample As Int = 2
	For rowindex = FirstRow To cbc.mHeight - 1 Step RowSample
		Dim RowSize As Int
		#if B4i
		Dim Row() As Byte = cbc.Rows.Get(rowindex)
		RowSize = Row.Length / 4
		#else
		Dim Row As List = cbc.Rows.Get(rowindex)
		RowSize = Row.Size
		#End If
		Dim RowMass As Int
		Dim RowStart As Int = -1
		Dim x As Int
		For i = 1 To RowSize - 1 Step 2
			#if B4i
			Dim valuetype As Byte = Bit.FastArrayGetInt(Row, i)
			Dim count As Int = Bit.FastArrayGetInt(Row, i + 1)
			#else
			Dim valuetype As Byte = Row.Get(i)
			Dim count As Int = Row.Get(i + 1)
			#end if
			If valuetype > 1 Then
				count = valuetype
			End If
			If valuetype > 0 Then
				If RowStart = -1 Then RowStart = x
				RowMass = RowMass + count
			End If
			x = x + count
		Next
		CenterX = CenterX + (RowStart + RowMass / 2) * RowMass
		CenterY = CenterY + rowindex * RowMass
		totalmass = totalmass + RowMass
	Next
	center.X = center.X + X2.BCPixelsToMeters((CenterX / totalmass - cbc.mWidth / 2))
	center.Y = center.Y + X2.BCPixelsToMeters((cbc.mHeight / 2 - CenterY / totalmass))
	Return totalmass
End Sub

Private Sub CreateObject
	Dim name As String = Names(Rnd(0, Names.Length))
	Dim template As X2TileObjectTemplate = TileMap.GetObjectTemplateByName(ObjectLayer, name)
	template.BodyDef.Position.X = X2.RndFloat(X2.ScreenAABB.BottomLeft.X, X2.ScreenAABB.TopRight.X)
	Dim r As X2BodyWrapper = TileMap.CreateObject(template)
	CalcTotalMass(r.Name, r.GraphicName)
End Sub

Private Sub CreateBlockGraphics
	For Each s As String In Array("rectangle 1", "rectangle 2")
		Dim template As X2TileObjectTemplate = TileMap.GetObjectTemplateByName(ObjectLayer, s)
		Dim size As B2Vec2 = X2.GetShapeWidthAndHeight(template.FixtureDef.Shape)
		Dim rect As B4XRect
		rect.Initialize(0, 0, X2.MetersToBCPixels(size.X), X2.MetersToBCPixels(size.Y))
		Dim bc As BitmapCreator = X2.GraphicCache.GetBitmapCreator(rect.Height)
		bc.FillGradient(Array As Int(Rnd(0xff000000, -1), Rnd(0xff000000, -1)), rect, "TL_BR")
		Dim sb As X2ScaledBitmap
		sb.Scale = 1
		sb.Bmp = bc.Bitmap.Crop(0, 0, rect.Right, rect.Bottom)
		Dim name As String = template.CustomProps.Get("graphic name")
		X2.GraphicCache.PutGraphic2(name, Array(sb), True, 3)
		X2.GraphicCache.WarmGraphic(name)
	Next
End Sub

Private Sub CalcTotalMass(Name As String, GraphicName As String)
	If TotalMassOfBodies.ContainsKey(Name) = False Then
		TotalMassOfBodies.Put(Name, CalcMassBasedOnPixels(X2.GraphicCache.GetGraphic(GraphicName, 0), "", 0, X2.CreateVec2(0, 0)))
	End If
End Sub


'Return True to stop the game loop
Public Sub BeforeTimeStep (GS As X2GameStep) As Boolean
	Return False
End Sub
