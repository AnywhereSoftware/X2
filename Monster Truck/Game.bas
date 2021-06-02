B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=6.47
@EndOfDesignText@
#if B4A
'ignore DIP related warnings as they are not relevant when working with BitmapCreator.
#IgnoreWarnings: 6
#end if
Sub Class_Globals
	Public X2 As X2Utils
	Private xui As XUI 'ignore
	Public world As B2World
	Private ivForeground As B4XView
	Private ivBackground As B4XView
	Public lblStats As B4XView
	Public TileMap As X2TileMap
	Public Const ObjectLayer As String = "Object Layer 2"
	
	Private Truck As X2BodyWrapper
	Private RearJoint As B2WheelJoint
	Private FrontJoint As B2WheelJoint
	Private ivGround As B4XView
	Private StabilizerFixture As B2Fixture
	Private GameOver As Boolean
	Private SmokeBrushes As List
	Private Multitouch As X2MultiTouch
	Private Panel1 As B4XView
End Sub

Public Sub Initialize (Parent As B4XView)
	Parent.LoadLayout("1")
	world.Initialize("world", world.CreateVec2(0, -10))
	X2.Initialize(Me, ivForeground, world)
	lblStats.TextColor = xui.Color_Black
	'comment to disable debug drawing
'	X2.EnableDebugDraw
	'Tileset credit: http://www.kenney.nl
	Multitouch.Initialize(B4XPages.MainPage, Array(Panel1))
End Sub

Public Sub Start
	If X2.IsRunning Then Return
	X2.Reset
	GameOver = False
	Dim WorldHeight As Float = 10
	Dim WorldWidth As Float = WorldHeight * 1.3333
	X2.ConfigureDimensions(world.CreateVec2(WorldWidth / 2, WorldHeight / 2), WorldWidth)
	
	TileMap.Initialize(X2, File.DirAssets, "truck.json", ivGround)
	TileMap.SetSingleTileDimensionsInMeters(0.6, 0.6)
	TileMap.PrepareObjectsDef(ObjectLayer)
	Dim ol As X2ObjectsLayer = TileMap.Layers.Get(ObjectLayer)
	For Each template As X2TileObjectTemplate In ol.ObjectsById.Values
		If template.Name = "hinge" Or template.Name.Contains("template") Then Continue
		TileMap.CreateObject(template)
	Next
	Truck = X2.GetBodyWrapperByName("truck")
	Truck.Body.LinearDamping = 0.5
	Truck.Body.AngularDamping = 1
	Dim TruckWidth As Float = X2.GetShapeWidthAndHeight(Truck.Body.FirstFixture.Shape).X
	X2.GraphicCache.PutGraphic("explosion", X2.ReadSprites(xui.LoadBitmap(File.DirAssets, "explosion_atlas.png"), 3, 3, TruckWidth, TruckWidth))
	SmokeBrushes = Array(X2.MainBC.CreateBrushFromColor(0xFF828282), X2.MainBC.CreateBrushFromColor(0xFF4E4C4C), X2.MainBC.CreateBrushFromColor(0xFF272727))
	'add some weight under the truck to make it more stable
	Dim rect As B2PolygonShape
	rect.Initialize
	rect.SetAsBox2(1, 0.1, X2.CreateVec2(0, -1.5), 0)
	StabilizerFixture = Truck.Body.CreateFixture2(rect, 10)
	StabilizerFixture.IsSensor = True
	'add a sensor at the top of the truck to help with finding out when the truck turned over
	Dim rect As B2PolygonShape
	rect.Initialize
	rect.SetAsBox2(0.2, 0.2, X2.CreateVec2(0, 1), 0)
	Dim f As B2Fixture = Truck.Body.CreateFixture2(rect, 0)
	f.IsSensor = True
	f.Tag = "top"
	
	RearJoint = CreateJoint("wheel left")
	FrontJoint = CreateJoint("wheel right")
	FrontJoint.MaxMotorTorque = 50
	'scale down the background image. It will not be noticeable and it will improve performance on weak devices.
	X2.SetBitmapWithFitOrFill(ivBackground, xui.LoadBitmapResize(File.DirAssets, "sky.jpg", ivBackground.Width / 2, ivBackground.Height / 2, False))
	CreateBridge
	X2.GraphicCache.WarmGraphic(Truck.GraphicName)
	X2.Start
End Sub

Private Sub CreateJoint (WheelName As String) As B2WheelJoint
	Dim wheel As X2BodyWrapper = X2.GetBodyWrapperByName(WheelName)
	wheel.Body.AngularDamping = 0.5
	Dim def As B2WheelJointDef
	def.Initialize(Truck.Body, wheel.Body, wheel.Body.Position, X2.CreateVec2(0, 1)) 'vector length must be 1.
	def.MaxMotorTorque = 1000
	def.DampingRatio = 0.6
	def.MotorSpeed = -30
	def.FrequencyHz = 10
	def.MotorEnabled = False
	Return world.CreateJoint(def)
End Sub

Private Sub CreateBridge
	Dim ol As X2ObjectsLayer = TileMap.Layers.Get(ObjectLayer)
	For Each template As X2TileObjectTemplate In ol.ObjectsById.Values
		If template.Name = "hinge" Then
			Dim ids() As String = Regex.Split("\s*,\s*", template.Tag)
			Dim def As B2RevoluteJointDef
			def.Initialize(X2.GetBodyWrapperById(ids(0)).Body, X2.GetBodyWrapperById(ids(1)).Body, template.BodyDef.Position)
			world.CreateJoint(def)
		End If
	Next
End Sub


Public Sub Tick (GS As X2GameStep)
	If GameOver Then Return
	Dim RightDown As Boolean
	#if B4J
	RightDown = Multitouch.Keys.Contains("Right")
	#Else
	RightDown = Multitouch.GetSingleTouch(Panel1).IsInitialized
	#End If
	RearJoint.MotorEnabled = RightDown
	FrontJoint.MotorEnabled = RightDown

	Dim dx As Float = X2.ScreenAABB.TopRight.X - Truck.Body.Position.X
	Dim dy1 As Float = X2.ScreenAABB.TopRight.Y - Truck.Body.Position.Y
	Dim dy2 As Float = Truck.Body.Position.Y - X2.ScreenAABB.BottomLeft.Y
	If dx < 6 Or dy1 < 4 Or dy2 < 2 Then
		Dim vec As B2Vec2 = X2.ScreenAABB.Center.CreateCopy
		vec.X = vec.X + 6 - dx
		vec.Y = vec.Y + 4 - Min(4, dy1)
		vec.Y = vec.Y - (2 - Min(2, dy2))
		X2.UpdateWorldCenter(vec)
	End If
	TileMap.DrawScreen(Array("Tile Layer 1"), GS.DrawingTasks)
	If Truck.Body.Position.X > 100 And StabilizerFixture.IsInitialized Then
		'break the stabilizer to "help" the user crash
		Log("destroy stabilizer")
		Truck.Body.DestroyFixture(StabilizerFixture)
	End If
	If RightDown And X2.FPS >= 57 Then
		Dim smoke As X2TileObjectTemplate = TileMap.GetObjectTemplateByName(ObjectLayer, "smoke template")
		smoke.BodyDef.Position.Set(Truck.Body.Position.X - 0.5, Truck.Body.Position.Y - 0.5)
		smoke.BodyDef.LinearVelocity = Truck.Body.LinearVelocity.Negate
		smoke.BodyDef.LinearVelocity.X = smoke.BodyDef.LinearVelocity.X / 5 + X2.RndFloat(-.5, .5)
		smoke.BodyDef.LinearVelocity.Y = smoke.BodyDef.LinearVelocity.Y / 5 + X2.RndFloat(-.5, .5)
		Dim bw As X2BodyWrapper = TileMap.CreateObject(smoke)
		bw.TimeToLiveMs = X2.RndFloat(200, 700)
		bw.Tag = SmokeBrushes.Get(Rnd(0, SmokeBrushes.Size))
	End If
	
	For Each b As B2Body In X2.mWorld.AllBodies
		Dim bw As X2BodyWrapper = b.Tag
		If bw.Name = "smoke template" Then
			Dim v As B2Vec2 = X2.WorldPointToMainBC(b.Position.X, b.Position.Y)
			Dim TimeLeft As Int = Max(0, bw.TimeToLiveMs - (GS.GameTimeMs - bw.StartTime))
			GS.DrawingTasks.Add(X2.MainBC.AsyncDrawCircle(v.X, v.Y, X2.MetersToBCPixels(0.05 + TimeLeft / 5000), bw.Tag, True, 0))
		End If
		
	Next
'	If FrontJoint.BodyB.GetContactList(True).Size > 0 Or RearJoint.BodyB.GetContactList(True).Size > 0 Then
'		Log("on ground")
'	Else
'		Log("in air")
'	End If
End Sub

Private Sub World_BeginContact (Contact As B2Contact)
	Dim bodies As X2BodiesFromContact = X2.GetBodiesFromContact(Contact, "truck")
	If bodies <> Null Then
		If bodies.ThisFixture.Tag <> Null And bodies.ThisFixture.Tag = "top" Then
			Truck.GraphicName = "explosion"
			X2.AddFutureTask(Me, "Break_Wheels", 0, Null)
			X2.AddFutureTask(Me, "game_over", 3000, Null)
			GameOver = True
		End If
	End If
End Sub

Private Sub Break_Wheels(ft As X2FutureTask)
	If RearJoint.IsInitialized = False Then Return
	world.DestroyJoint(RearJoint)
	world.DestroyJoint(FrontJoint)
End Sub

Private Sub Game_Over(ft As X2FutureTask)
	X2.Stop
	Sleep(100)
	Start
End Sub

Public Sub Resize
	X2.ImageViewResized
End Sub

Public Sub DrawingComplete
	TileMap.DrawingComplete
End Sub

'Return True to stop the game loop
Public Sub BeforeTimeStep (GS As X2GameStep) As Boolean
	Return False
End Sub

#If B4J
Private Sub Panel_Touch (Action As Int, X As Float, Y As Float)
	Multitouch.B4JDelegateTouchEvent(Sender, Action, X, Y)
End Sub
#Else If B4i
Private Sub Panel_Multitouch (Stage As Int, Data As Object)
	Multitouch.B4iDelegateMultitouchEvent(Sender, Stage, Data)
End Sub
#End If






