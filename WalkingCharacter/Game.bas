B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=6.3
@EndOfDesignText@
Sub Class_Globals
	Public X2 As X2Utils
	Private xui As XUI
	Public mKid As Kid
	Public world As B2World
	Public Ground As X2BodyWrapper
	Public mBackgroundView As B4XView
	Public mScore As ScoreLabel
	Public mBackground As Background
	Public WidthToHeightRatio As Float = 1.333 'should match the ratio in the designer script
	Private ImageView1 As B4XView
	Private ImageView2 As B4XView
	Private ScoreLabel1 As ScoreLabel
	Private Panel1 As B4XView
	Public lblStats As B4XView
	'filter bits must be powers of 2.
	Public const KidCategory As Int = 2
	Public const ExplosionCategory As Int = 4
	Private RaycastBody As X2BodyWrapper
	Private RaycastPoint As B2Vec2
	Private LaserBmp As X2ScaledBitmap
	Public TileMap As X2TileMap
	Public const ObjectLayerName As String = "Object Layer 1"
	Public BlockBrush As BCBrush
	Public MultiTouch As X2MultiTouch
	Private TouchPanel As B4XView
	Public RightDown, LeftDown, Jump As Boolean
End Sub


Public Sub Initialize (Parent As B4XView)
	Parent.LoadLayout("1")
	mBackgroundView = ImageView2 'Will be drawn from Background class.
	world.Initialize("world", world.CreateVec2(0, -10))
	X2.Initialize(Me, ImageView1, world)
	Dim ScreenWidth As Float = 6
	Dim ScreenHeight As Float = ScreenWidth / 1.33333
	X2.ConfigureDimensions(world.CreateVec2(ScreenWidth / 2, ScreenHeight / 2), ScreenWidth)
	TileMap.Initialize(X2, File.DirAssets, "walking character.json", Null)
	TileMap.SetSingleTileDimensionsInMeters(X2.ScreenAABB.Width / TileMap.TilesPerRow, X2.ScreenAABB.Height / TileMap.TilesPerColumn)
	TileMap.PrepareObjectsDef(ObjectLayerName)
	Ground = TileMap.CreateObject(TileMap.GetObjectTemplate(ObjectLayerName, 10))
	mScore = ScoreLabel1
	CreateKid
	mBackground.Initialize(Me)
	LoadFireworksGraphics
	LoadBirdGraphics
	LaserBmp = X2.LoadBmp2(File.DirAssets, "laser.png", 5.08, 0.15, 1, False)
	X2.SoundPool.AddSound("coin", File.DirAssets, "Picked Coin Echo 2.wav")
	X2.SoundPool.AddSound("fireworks", File.DirAssets, "8bit_bomb_explosion.wav")
	MultiTouch.Initialize(B4XPages.MainPage,Array(TouchPanel, Panel1))
	BlockBrush = X2.MainBC.CreateBrushFromBitmap(xui.LoadBitmap(File.DirAssets, "horizontal.png"))
'	Enable debug drawing
'	X2.EnableDebugDraw
'	X2.SlowDownPhysicsScale = 5
'	X2.UpdateTimeParameters
 End Sub
 
Public Sub Resize
	X2.ImageViewResized
End Sub

'In B4i and B4J we need to delegate the events to MultiTouch. Note that the panels EventName is set to Panel.
#if B4i
Private Sub Panel_Multitouch (Stage As Int, Data As Object)
	MultiTouch.B4iDelegateMultitouchEvent(Sender, Stage, Data)
End Sub
#else if b4j
Private Sub Panel_Touch (Action As Int, X As Float, Y As Float)
	MultiTouch.B4JDelegateTouchEvent(Sender, Action, X, Y)
End Sub

#end if

Private Sub CreateKid
	'https://opengameart.org/content/2d-character-animation-sprite
	Dim template As X2TileObjectTemplate = TileMap.GetObjectTemplate(ObjectLayerName, 39)
	Dim bw As X2BodyWrapper = TileMap.CreateObject(template)
	mKid.Initialize(bw)
End Sub

Private Sub LoadBirdGraphics
	
	X2.GraphicCache.PutGraphic("fried", Array(X2.LoadBmp(File.DirAssets, "fried.png", 0.5, 0.5, True))).VerticalSymmetry = True
'	X2.GraphicCache.GetGraphic2("fried", 0, 0, True, False)
End Sub

Public Sub WorldCenterUpdated (length As Float)
	length = Abs(length)
	If X2.RndFloat(0, 2) < length   Then '1 per 2 meters
		CreateCoin
	End If
	If X2.RndFloat(0, 10) < length Then '1 per 10 meters
		CreateHorizontalPlatform
	End If
	If X2.RndFloat(0, 10) < length Then '1 per 10 meters
		CreateRotatingBlock
	End If
End Sub

Public Sub BeforeTimeStep (GS As X2GameStep)
	mKid.InAir = True
End Sub

Public Sub Tick (GS As X2GameStep)
	UpdateTouchState
	mScore.Tick
	mKid.Tick(GS)
	mBackground.Tick(GS)
	If X2.RndFloat(0, 2000) < X2.TimeStepMs  Then CreateDonut '1 per 2 seconds
	If X2.RndFloat(0, 2000) < X2.TimeStepMs  Then CreateBird '1 per 2 seconds
	If X2.RndFloat(0, 5000) < X2.TimeStepMs Then CreateFireworks '1 per 5 seconds
End Sub

Private Sub UpdateTouchState
	#if B4A or B4i
	LeftDown = False
	RightDown = False
	For Each touch As X2Touch In MultiTouch.GetTouches(TouchPanel)
		If touch.X < TouchPanel.Width / 2 Then
			LeftDown = True
		Else
			RightDown = True
		End If
	Next
	Jump = LeftDown And RightDown
	#else if B4J
	LeftDown = MultiTouch.Keys.Contains("Left")
	RightDown = MultiTouch.Keys.Contains("Right")
	Jump = MultiTouch.Keys.Contains("Space")
	#end if
	Dim LaserTouch As X2Touch = MultiTouch.GetSingleTouch(Panel1)
	If LaserTouch.IsInitialized And LaserTouch.Handled = False Then 
		LaserTouch.Handled = True
		LaserPanelTouched(LaserTouch.X, LaserTouch.Y)
	End If
End Sub

'example of a one way body.
'The important implementation is in World_PreSolve.
Private Sub CreateHorizontalPlatform
	Dim template As X2TileObjectTemplate = TileMap.GetObjectTemplate(ObjectLayerName, 35)
	template.BodyDef.GravityScale = 0
	If mKid.bw.Body.LinearVelocity.X > 0 Then
		template.BodyDef.Position.X = X2.ScreenAABB.TopRight.X + 0.5
	Else
		template.BodyDef.Position.X = X2.ScreenAABB.BottomLeft.X - 0.5
	End If
	Dim hblock As X2BodyWrapper = TileMap.CreateObject(template)
	'create a prismatic joint between the block and the ground. The joint will push the block up.
	Dim prismatic As B2PrismaticJointDef
	prismatic.Initialize(Ground.Body, hblock.Body, hblock.Body.Position, X2.CreateVec2(0, 1))
	prismatic.MaxMotorForce = 15
	prismatic.MotorSpeed = 0.5
	prismatic.SetLimits(0, 2)
	prismatic.MotorEnabled = True
	prismatic.LimitEnabled = True
	world.CreateJoint(prismatic)
	
End Sub

Private Sub CreateRotatingBlock
	Dim bd As B2BodyDef
	bd.BodyType = bd.TYPE_KINEMATIC 'infinite mass
	If mKid.bw.Body.LinearVelocity.X > 0 Then
		bd.Position = X2.CreateVec2(X2.ScreenAABB.TopRight.X + 1, 3.7)
	Else
		bd.Position = X2.CreateVec2(X2.ScreenAABB.BottomLeft.X - 1, 3.7)
	End If
	bd.AngularVelocity = X2.RndFloat(1, 5)
	If Rnd(0, 2) = 0 Then bd.AngularVelocity = -bd.AngularVelocity
	Dim rb As RotatingBlock
	Dim wrapper As X2BodyWrapper = X2.CreateBodyAndWrapper(bd, rb, "Rotating Block")
	wrapper.DestroyIfInvisible = False
	rb.Initialize(wrapper)
	Dim shape As B2PolygonShape
	shape.Initialize
	shape.SetAsBox(rb.Size.X / 2, rb.Size.Y / 2)
	Dim f As B2Fixture = wrapper.Body.CreateFixture2(shape, 1)
	f.Friction = 0
End Sub

Private Sub CreateDonut
	Dim template As X2TileObjectTemplate = TileMap.GetObjectTemplate(ObjectLayerName, 15)
	template.BodyDef.Position.X = X2.RndFloat(X2.ScreenAABB.BottomLeft.X, X2.ScreenAABB.TopRight.X)
	TileMap.CreateObject(template)
End Sub

Private Sub LoadFireworksGraphics
	Dim radius As Float = X2.MetersToBCPixels(0.05)
	Dim bc As BitmapCreator = X2.GraphicCache.GetBitmapCreator(2 * radius)
	Dim bmps As List
	bmps.Initialize
	For Each clr As Int In Array (xui.Color_Red, xui.Color_Yellow)
		bc.FillRect(xui.Color_Transparent, bc.TargetRect)
		bc.DrawCircle(radius, radius, radius, clr, True, 0)
		Dim sb1 As X2ScaledBitmap
		sb1.Scale = 1
		sb1.Bmp = bc.Bitmap.Crop(0, 0, radius * 2, radius * 2)
		bmps.Add(sb1)
	Next
	X2.GraphicCache.PutGraphic2("fireworks explosion", bmps, False, 360) '360 = no rotation
End Sub

Private Sub CreateFireworks
	Dim headtemplate As X2TileObjectTemplate = TileMap.GetObjectTemplateByName(ObjectLayerName, "fireworks head")
	headtemplate.BodyDef.Position.X = X2.RndFloat(X2.ScreenAABB.BottomLeft.X, X2.ScreenAABB.TopRight.X)
	Dim tailtemplate As X2TileObjectTemplate = TileMap.GetObjectTemplateByName(ObjectLayerName, "fireworks tail")
	tailtemplate.BodyDef.Position.X = headtemplate.BodyDef.Position.X
	Dim head As X2BodyWrapper = TileMap.CreateObject(headtemplate)
	Dim tail As X2BodyWrapper = TileMap.CreateObject(tailtemplate)
	'connect the two bodies
	Dim weld As B2WeldJointDef
	weld.Initialize(head.Body, tail.Body, head.Body.Position)
	X2.mWorld.CreateJoint(weld)
	'add a motor to move the head relatively to the ground.
	Dim motor As B2MotorJointDef
	motor.Initialize(Ground.Body, head.Body)
	motor.LinearOffset = X2.CreateVec2(head.Body.Position.x, _
		 X2.GetShapeWidthAndHeight(head.Body.FirstFixture.Shape).Y + X2.GetShapeWidthAndHeight(tail.Body.FirstFixture.Shape).Y)
	motor.MaxMotorForce = 5
	Dim mj As B2MotorJoint = X2.mWorld.CreateJoint(motor)
	Dim f As Fireworks
	f.Initialize(head, tail, mj)
End Sub

Private Sub CreateCoin
	Dim template As X2TileObjectTemplate = TileMap.GetObjectTemplate(ObjectLayerName, 20)
	If mKid.bw.Body.LinearVelocity.X > 0 Then
		template.BodyDef.Position.X = X2.ScreenAABB.TopRight.X + 1
	Else
		template.BodyDef.Position.X = X2.ScreenAABB.BottomLeft.X - 1
	End If
	TileMap.CreateObject(template)
End Sub

Private Sub CreateBird
	Dim template As X2TileObjectTemplate = TileMap.GetObjectTemplate(ObjectLayerName, 16)
	Dim ShouldFlip As Boolean
	If X2.RndFloat(0, 1) < 0.5 Then
		template.BodyDef.Position = world.CreateVec2(X2.ScreenAABB.BottomLeft.X, X2.RndFloat(2, 4.5))
		template.BodyDef.LinearVelocity = world.CreateVec2(X2.RndFloat(0.5, 1), 0)
		ShouldFlip = True
	Else
		template.BodyDef.Position = world.CreateVec2(X2.ScreenAABB.TopRight.X,  X2.RndFloat(2, 4.5))
		template.BodyDef.LinearVelocity = world.CreateVec2(X2.RndFloat(-1, -0.5), 0)
	End If
	Dim wrapper As X2BodyWrapper = TileMap.CreateObject(template)
	wrapper.FlipHorizontal = ShouldFlip
	For Each donut As X2BodyWrapper In X2.GetBodiesWrappersByIds(Array(15))
		If donut = Null Or donut.Tag = "" Then
			'connect them with a distance joint
			'enable debug drawing to see the connection.
			Dim distance As B2DistanceJointDef
			distance.Initialize(donut.Body, wrapper.Body, donut.Body.Position, wrapper.Body.Position)
			distance.Length = 0.2
			distance.FrequencyHz = 1
			distance.DampingRatio = 0.2
			donut.DestroyIfInvisible = False
			donut.TimeToLiveMs = 20000
			world.CreateJoint(distance)
			donut.Tag = "used"
			Exit
		End If
	Next
End Sub

Public Sub GetGroundLevel As Float
	Return Ground.Body.Position.Y
End Sub


Public Sub DrawingComplete 
	mBackground.DrawComplete
End Sub

'not called every time step.
Private Sub World_BeginContact (Contact As B2Contact)
	Dim bodies As X2BodiesFromContact = X2.GetBodiesFromContact(Contact, "kid")
	If bodies = Null Then Return
	'we cannot delete or add bodies from these events as they happen inside the TimeStep call.
	'So we will run them after this time step.
	If bodies.OtherBody.Name = "coin" Then
		'allow duplicates is set to true because the kid can collide with multiple coins and BeginContact is not called too frequently anyway.
		X2.AddFutureTask2(mKid, "Collision_WithCoin", 0, bodies.OtherBody, True)
	Else If bodies.OtherBody.Name = "bird" Then
		Contact.IsEnabled = False
		X2.AddFutureTask2(mKid, "Collision_WithBird", 0, bodies.OtherBody, True)
	End If
End Sub

'not called for sensors nor for sleeping bodies.
Private Sub World_PreSolve (Contact As B2Contact, OldManifold As B2Manifold)
	Dim bodies As X2BodiesFromContact = X2.GetBodiesFromContact(Contact, "kid")
	If bodies = Null Then Return
	If bodies.OtherBody.Name = "horizontal" Then
		'ignore the collision if the kid is not above the horizontal block
		If bodies.ThisBody.Body.Position.Y - mKid.Size.Y / 2 < bodies.OtherBody.Body.Position.Y + 0.05 Then
 			Contact.IsEnabled = False
			Return
		End If
	End If
	'check the normal between the kid and other bodies. If the Y value is negative then the kid is standing on something.
	Dim wm As B2WorldManifold
	Contact.GetWorldManifold(wm)
	wm.Normal.MultiplyThis(bodies.NormalSign)
	If wm.Normal.Y < 0 Then mKid.InAir = False 
	
End Sub

Private Sub World_PostSolve (Contact As B2Contact, Impulse As B2ContactImpulse)
	
End Sub
   





Private Sub LaserPanelTouched (x As Float, y As Float)
	Dim p As B2Vec2 = X2.ScreenPointToWorld(X, Y)
	'cast a ray from the kid to the point
	RaycastBody = Null
	RaycastPoint = p
	world.RayCast(mKid.bw.Body.Position, p)
	If RaycastBody <> Null And RaycastBody.IsDeleted = False Then
		'ray hit a body
		RaycastBody.TimeToLiveMs = 1
	End If
	CreateLaser
End Sub

Private Sub World_RaycastCallback (Fixture As B2Fixture, Point As B2Vec2, Normal As B2Vec2, Fraction As Float) As Float
	Dim bw As X2BodyWrapper = Fixture.Body.Tag
	'ignore static bodies
	If bw.Body.BodyType = bw.Body.TYPE_STATIC Then Return -1
	RaycastBody = bw
	RaycastPoint = Point.CreateCopy
	'return fraction to limit the ray up to the current fixture.
	'The result is that the last event will be the closest body.
	Return Fraction
End Sub

Private Sub CreateLaser
	Dim bd As B2BodyDef
	bd.BodyType = bd.TYPE_STATIC
	Dim vec As B2Vec2 = RaycastPoint
	Dim kidvec As B2Vec2 = mKid.bw.Body.Position
	vec.SubtractFromThis(kidvec)
	Dim length As Float = vec.Length
	Dim angle As Float = ATan2(vec.y, vec.x)
	'find center
	vec.MultiplyThis(0.5)
	vec.AddToThis(kidvec)
	bd.Position = vec
	bd.Angle = angle
	Dim wrapper As X2BodyWrapper = X2.CreateBodyAndWrapper(bd, Null, "laser")
	Dim gname As String = X2.GraphicCache.GetTempName
	Dim sb As X2ScaledBitmap
	sb.Bmp = LaserBmp.Bmp.Resize(X2.MetersToBCPixels(length), LaserBmp.Bmp.Height, False)
	sb.Scale = 1
	Dim shape As B2PolygonShape
	shape.Initialize
	shape.SetAsBox(length / 2, 0.2)
	Dim f As B2Fixture = wrapper.Body.CreateFixture2(shape, 1)
	f.SetFilterBits(0, 0) 'no collisions
	X2.GraphicCache.PutGraphic(gname, Array(sb))
	wrapper.GraphicName = gname
	wrapper.TimeToLiveMs = 100
End Sub
