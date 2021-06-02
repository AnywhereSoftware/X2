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
	Public ivBackground As B4XView
	Public lblStats As B4XView
	Private Ground As X2BodyWrapper
	Private ivMessages As B4XView
	Private LastPipe As Float
	Public GroundLevel As Float
	
	Public mBird As Bird
	Public BirdXVelocity As Float = 3
	Public GameOverState As Boolean
	Public lblScore As B4XView
	Public PipePositions As List
	Public Panel1 As B4XView 
	Private mBackground As Background
	Public Multitouch As X2MultiTouch
End Sub

Public Sub Initialize (Parent As B4XView)
	Parent.LoadLayout("GameLayout")
	world.Initialize("world", world.CreateVec2(0, -10))
	X2.Initialize(Me, ivForeground, world)
	'Configure the dimensions. Center point is (0, 3) and the visible height is 6 meters.
	X2.ConfigureDimensions(world.CreateVec2(0, 3), 9)
	'Load the graphics and add them to the cache.
	'comment to disable debug drawing
'	X2.EnableDebugDraw
	LoadPipesGraphics
	Dim sprites As List = X2.ReadSprites(xui.LoadBitmap(File.DirAssets, "clumsy.png"), 1, 3, 0.5, 60 / 85 * 0.5)
	X2.GraphicCache.PutGraphic("bird", sprites)
	X2.SoundPool.AddSound("wing", File.DirAssets, "wing.mp3")
	X2.SoundPool.AddSound("hit", File.DirAssets, "hit.mp3")
	X2.SoundPool.AddSound("lose", File.DirAssets, "lose.mp3")
	PipePositions.Initialize
	Multitouch.Initialize(B4XPages.MainPage, Array(Panel1))
'	X2.SlowDownPhysicsScale = 5
'	X2.UpdateTimeParameters
End Sub

#If B4i
Private Sub Panel_Multitouch (Stage As Int, Data As Object)
	Multitouch.B4iDelegateMultitouchEvent(Sender, Stage, Data)
End Sub
#End If

Private Sub LoadPipesGraphics
	Dim sb As X2ScaledBitmap = X2.LoadBmp(File.DirAssets, "pipe.png", 1.5, 1.5 * 370 / 148, True)
	X2.GraphicCache.PutGraphic("pipe", Array(sb))
End Sub

Public Sub StartGame
	If X2.IsRunning Then Return
	PipePositions.Clear
	GameOverState = False
	LastPipe = 0
	X2.Reset
	X2.UpdateWorldCenter(X2.CreateVec2(0, 3))
	CreateGround
	mBackground.Initialize(Me)
	X2.Start
	X2.AddFutureTask(Me, "Show_GetReady", 0, Null)
	X2.AddFutureTask(Me, "Create_Bird", 1500, Null)
	lblScore.Text = 0
End Sub

Public Sub Stop
	X2.Stop
End Sub


Public Sub Resize
	X2.ImageViewResized
End Sub

Public Sub DrawingComplete
	mBackground.DrawComplete
End Sub

Public Sub BeforeTimeStep (GS As X2GameStep) As Boolean
	Return False
End Sub

Public Sub Tick (GS As X2GameStep)
	Dim center As B2Vec2 = X2.ScreenAABB.Center
	center.X = center.X + X2.TimeStepMs / 1000 * BirdXVelocity
	X2.UpdateWorldCenter(center)
	UpdateGround
	mBackground.Tick(GS)
	If X2.ScreenAABB.TopRight.X - LastPipe > 5 And GS.GameTimeMs > 1500 Then
		CreatePipe	
	End If
End Sub


Public Sub GameOver
	X2.SoundPool.PlaySound("lose")
	GameOverState = True
	Sleep(100)
	ivMessages.SetBitmap(xui.LoadBitmap(File.DirAssets, "gameover.png"))
	ivMessages.SetVisibleAnimated(1000, True)
	Sleep(2000)
	X2.Stop
	X2.Reset
	If B4XPages.GetManager.IsForeground Then
		StartGame
	End If
End Sub


Private Sub Create_Bird(ft As X2FutureTask)
	Dim bd As B2BodyDef
	bd.BodyType = bd.TYPE_DYNAMIC
	bd.Position = X2.CreateVec2(X2.ScreenAABB.BottomLeft.X + 1.5, 4)
	bd.LinearVelocity = X2.CreateVec2(BirdXVelocity, 0)
	Dim wrapper As X2BodyWrapper = X2.CreateBodyAndWrapper(bd, mBird, "bird")
	wrapper.GraphicName = "bird"
	mBird.Initialize(wrapper)
	
	Dim size As B2Vec2 = X2.GraphicCache.GetGraphicSizeMeters(wrapper.GraphicName, 0)
	Dim circle As B2CircleShape
	circle.Initialize(size.Y / 2)
	wrapper.Body.CreateFixture2(circle, 0.2)
End Sub

Private Sub CreatePipe
	Dim imgsize As B2Vec2 = X2.GraphicCache.GetGraphicSizeMeters("pipe", 0)
	Dim HoleBottom As Float = X2.RndFloat(GroundLevel + 0.5, GroundLevel + 2.5)
	Dim HoleTop As Float = HoleBottom + 2
	Dim bd As B2BodyDef
	bd.BodyType = bd.TYPE_STATIC
	Dim size As B2Vec2 = X2.CreateVec2(imgsize.X, X2.ScreenAABB.TopRight.y - HoleTop)
	bd.Position = X2.CreateVec2(X2.ScreenAABB.TopRight.X + 0.5, HoleTop + size.Y / 2 )
	Dim p As Pipe
	Dim wrapper As X2BodyWrapper = X2.CreateBodyAndWrapper(bd, p, "top pipe")
	wrapper.GraphicName = "pipe"
	p.Initialize(wrapper, size)
	Dim rect As B2PolygonShape
	rect.Initialize
	rect.SetAsBox(size.X / 2, size.Y / 2) 'half sizes
	wrapper.Body.CreateFixture2(rect, 1)
	
	size = X2.CreateVec2(imgsize.X, HoleBottom - GroundLevel)
	bd.Position = X2.CreateVec2(X2.ScreenAABB.TopRight.X + 0.5, GroundLevel + size.Y / 2)
	Dim p As Pipe
	Dim wrapper As X2BodyWrapper = X2.CreateBodyAndWrapper(bd, p, "bottom pipe")
	wrapper.GraphicName = "pipe"
	wrapper.FlipVertical = True
	p.Initialize(wrapper, size)
	Dim rect As B2PolygonShape
	rect.Initialize
	rect.SetAsBox(size.X / 2, size.Y / 2) 'half sizes
	wrapper.Body.CreateFixture2(rect, 1)
	
	LastPipe = X2.ScreenAABB.TopRight.X
	PipePositions.Add(bd.Position.X)
	
End Sub

Private Sub Show_GetReady (ft As X2FutureTask)
	ivMessages.Visible = True
	ivMessages.SetBitmap(xui.LoadBitmap(File.DirAssets, "getready.png"))
	ivMessages.SetVisibleAnimated(2000, False)
End Sub

Private Sub UpdateGround
	Dim Extra As Float = 0.3
	Dim delta As Float = X2.ScreenAABB.Center.X - Ground.Body.Position.X
	If delta > Extra Then
		Ground.Body.SetTransform(X2.CreateVec2(Ground.Body.Position.X + 0.48, Ground.Body.Position.Y), 0)
	End If
End Sub

Private Sub CreateGround
	Dim GroundBox As B2Vec2 = X2.CreateVec2(9.6, 0.96)
	Dim sb As X2ScaledBitmap = X2.LoadBmp(File.DirAssets, "ground.png", GroundBox.X, GroundBox.Y, False)
	X2.GraphicCache.PutGraphic("Ground", Array(sb))
	Dim bd As B2BodyDef
	bd.BodyType = bd.TYPE_STATIC 'the engine should not move it
	bd.Position = X2.CreateVec2(X2.ScreenAABB.Center.X, X2.ScreenAABB.BottomLeft.Y + GroundBox.Y / 2)
	Ground = X2.CreateBodyAndWrapper(bd, Null, "Ground")
	Ground.GraphicName = "ground"
	Dim rect As B2PolygonShape
	rect.Initialize
	rect.SetAsBox(GroundBox.X / 2, GroundBox.Y / 2)
	Ground.Body.CreateFixture2(rect, 1)
	GroundLevel = X2.ScreenAABB.BottomLeft.Y + GroundBox.Y
	Dim edge As B2EdgeShape
	edge.Initialize(X2.CreateVec2(-20, X2.ScreenAABB.TopRight.Y - bd.Position.Y - 0.01), _
		X2.CreateVec2(20, X2.ScreenAABB.TopRight.Y - bd.Position.Y - 0.01))
	Ground.Body.CreateFixture2(edge, 1)
End Sub

Private Sub World_BeginContact (Contact As B2Contact)
	If GameOverState = True Then Return
	Dim bodies As X2BodiesFromContact = X2.GetBodiesFromContact(Contact, "bird")
	If bodies <> Null Then
		GameOver
	End If
End Sub

