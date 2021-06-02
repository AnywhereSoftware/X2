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
	Public Ground As X2BodyWrapper
	Private ivForeground As B4XView
	Private ivBackground As B4XView
	Public lblStats As B4XView
	Public TileMap As X2TileMap
	Public Const ObjectLayer As String = "Object Layer 1"

	Private mMario As Mario
	Private LeftEdge As X2BodyWrapper
	Private ScoreFont As B4XFont
	Private GameOverState As Boolean
	Type EnemyTemplates (Template As X2TileObjectTemplate, XPosition As Float)
	Private EnemyTemplates As List
	Public Multitouch As X2MultiTouch
	Public Panel1 As B4XView
End Sub

Public Sub Initialize (Parent As B4XView)
	Parent.LoadLayout("1")
	world.Initialize("world", world.CreateVec2(0, -20))
	X2.Initialize(Me, ivForeground, world)
	Dim WorldHeight As Float = 14 'the size of each tile will be approximately 1x1 meter
	Dim WorldWidth As Float = WorldHeight * 1.3333
	X2.ConfigureDimensions(world.CreateVec2(WorldWidth / 2, WorldHeight / 2), WorldWidth)
	lblStats.TextColor = xui.Color_Black
	lblStats.Color = 0x88ffffff
	lblStats.Font = xui.CreateDefaultBoldFont(20)
	'comment to disable debug drawing
	'X2.EnableDebugDraw
	LoadMarioGraphics
	LoadBugGraphics
	LoadTurtleGraphics
	X2.SoundPool.AddSound("small jump", File.DirAssets, "small_jump.mp3")
	X2.SoundPool.AddSound("big jump", File.DirAssets, "big_jump.mp3")
	X2.SoundPool.AddSound("powerup", File.DirAssets, "powerup.mp3") 
	X2.SoundPool.AddSound("gameover", File.DirAssets, "game_over.mp3") 
	X2.SoundPool.AddSound("kick", File.DirAssets, "kick.mp3") 
	#if B4J
	Dim fx As JFX
	ScoreFont = fx.LoadFont(File.DirAssets, "fixedsys500c.ttf", 30)
	#else if B4i
	ScoreFont = Font.CreateNew2("FixedsysTTF", 30)
	#else
	ScoreFont = xui.CreateFont(Typeface.LoadFromAssets("Fixedsys500c.ttf"), 30 / xui.Scale)
	#End If
	Multitouch.Initialize(B4XPages.MainPage, Array(Panel1))
End Sub

#If B4i
Private Sub Panel_Multitouch (Stage As Int, Data As Object)
	Multitouch.B4iDelegateMultitouchEvent(Sender, Stage, Data)
End Sub
#End If

Public Sub StartGame
	If X2.IsRunning Then Return
	X2.Reset
	Multitouch.ResetState
	X2.UpdateWorldCenter(X2.CreateVec2(X2.ScreenAABB.Width / 2, X2.ScreenAABB.Height / 2))
	GameOverState = False
	'music file removed to reduce the examples pack size.
	'X2.SoundPool.PlayMusic(File.DirAssets, "main_theme.mp3")
	TileMap.Initialize(X2, File.DirAssets, "mario 1.json", ivBackground)
	Dim TileSizeMeters As Float = X2.ScreenAABB.Height / TileMap.TilesPerColumn
	TileMap.SetSingleTileDimensionsInMeters(TileSizeMeters, TileSizeMeters)
	TileMap.PrepareObjectsDef(ObjectLayer)
	TileMap.SetBackgroundColor(0xFF008AFF)
	'create mario
	Dim bw As X2BodyWrapper = TileMap.CreateObject(TileMap.GetObjectTemplate(ObjectLayer, 3)) '3 = mario id in the map
'	bw.Body.LinearDamping = 1
	mMario.Initialize(bw)
	LeftEdge = TileMap.CreateObject(TileMap.GetObjectTemplate(ObjectLayer, 2))
	'create all other objects
	Dim layer As X2ObjectsLayer = TileMap.Layers.Get(ObjectLayer)
	EnemyTemplates.Initialize
	For Each template As X2TileObjectTemplate In layer.ObjectsById.Values
		If template.FirstTime And template.Name.Contains("template") = False Then
			If template.Name.Contains("enemy") Then 
				'enemies are only created when they become visible
				Dim et As EnemyTemplates
				et.Template = template
				et.XPosition = template.Position.X
				EnemyTemplates.Add(et)
				Continue
			End If
			TileMap.CreateObject(template)
		End If
	Next
	EnemyTemplates.SortType("XPosition", True)
	CreateEnemies
	X2.Start
End Sub

Private Sub CreateEnemies
	Do While EnemyTemplates.Size > 0
		Dim et As EnemyTemplates = EnemyTemplates.Get(0)
		If et.XPosition <= X2.ScreenAABB.TopRight.X Then
			Dim bw As X2BodyWrapper = TileMap.CreateObject(et.Template)
			Dim bg As Enemy
			bg.Initialize(bw) 'this sets the delegate
			bg.IsBug = bw.GraphicName = "bug"
			EnemyTemplates.RemoveAt(0)
		Else
			Exit
		End If
	Loop
End Sub

Private Sub LoadMarioGraphics
	Dim bmp As B4XBitmap = xui.LoadBitmap(File.DirAssets, "mario_bros.png")
	Dim NumberOfSprites As Int = 14
	Dim MarioSmall As B4XBitmap = bmp.Crop(80, 32, NumberOfSprites * 16, 16)
	Dim AllSmall As List = X2.ReadSprites(MarioSmall, 1, NumberOfSprites, 1, 1)
	X2.GraphicCache.PutGraphic("mario small walking", Array(AllSmall.Get(0), AllSmall.Get(1), AllSmall.Get(2)))
	X2.GraphicCache.PutGraphic("mario small standing", Array(AllSmall.Get(6)))
	X2.GraphicCache.PutGraphic("mario small jumping", Array(AllSmall.Get(4)))
	X2.GraphicCache.PutGraphic("mario small strike", Array(AllSmall.Get(5)))
	X2.GraphicCache.PutGraphic("mario small change direction", Array(AllSmall.Get(3)))
	NumberOfSprites = 19
	Dim MarioLarge As B4XBitmap = bmp.Crop(80, 0, NumberOfSprites * 16, 32)
	Dim AllLarge As List = X2.ReadSprites(MarioLarge, 1, NumberOfSprites, 1, 2)
	X2.GraphicCache.PutGraphic("mario large walking", Array(AllLarge.Get(0), AllLarge.Get(1), AllLarge.Get(2)))
	X2.GraphicCache.PutGraphic("mario large standing", Array(AllLarge.Get(6)))
	X2.GraphicCache.PutGraphic("mario large jumping", Array(AllLarge.Get(4)))
	X2.GraphicCache.PutGraphic("mario large strike", Array(AllLarge.Get(5)))
	X2.GraphicCache.PutGraphic("mario large change direction", Array(AllLarge.Get(3)))
	
	X2.GraphicCache.PutGraphic("mario change size", Array(AllSmall.Get(6), AllLarge.Get(6)))
End Sub

Private Sub LoadBugGraphics
	Dim all As List = X2.ReadSprites(xui.LoadBitmap(File.DirAssets, "enemy1.png"), 1, 3, 1, 1)
	X2.GraphicCache.PutGraphic("bug", Array(all.Get(0), all.Get(1)))
	Dim squashed As X2ScaledBitmap = all.Get(2)
	squashed.Bmp = squashed.Bmp.Crop(0, squashed.Bmp.Height / 2, squashed.Bmp.Width, squashed.Bmp.Height / 2)
	X2.GraphicCache.PutGraphic("bug squashed", Array(squashed))
End Sub

Private Sub LoadTurtleGraphics
	Dim all As List = X2.ReadSprites(xui.LoadBitmap(File.DirAssets, "enemy2.png"), 1, 5, 1, 1.5)
	X2.GraphicCache.PutGraphic("turtle", Array(all.Get(0), all.Get(1)))
	Dim squashed As X2ScaledBitmap = all.Get(4)
	squashed.Bmp = squashed.Bmp.Crop(0, squashed.Bmp.Height * 1 / 3, squashed.Bmp.Width, squashed.Bmp.Height * 2 / 3)
	X2.GraphicCache.PutGraphic("turtle squashed", Array(squashed))
End Sub

Public Sub Resize
	X2.ImageViewResized
End Sub

Public Sub Tick (GS As X2GameStep)
	mMario.Tick(GS) 'run first as mario updates the world position
	TileMap.DrawScreen(Array("Tile Layer 1", "Tile Layer 2"), GS.DrawingTasks)
End Sub

Public Sub WorldCenterUpdated (gs As X2GameStep)
	CreateEnemies
	'move the left edge to limit the movement.
	LeftEdge.Body.SetTransform(X2.CreateVec2(X2.ScreenAABB.BottomLeft.X, LeftEdge.Body.Position.Y), 0)
End Sub

Public Sub DrawingComplete
	TileMap.DrawingComplete
End Sub

'must handle this event if we want to handle the PreSolve event.
Private Sub World_BeginContact (Contact As B2Contact)
	Dim bodies As X2BodiesFromContact = X2.GetBodiesFromContact(Contact, "mario")
	If bodies <> Null Then
		If bodies.OtherBody.Name = "mushroom" Then
			'we cannot modify the world state inside these events. So we add a future task with time = 0.
			X2.AddFutureTask(mMario, "Touch_Mushroom", 0, bodies.OtherBody)
		End If
	End If
	
	Dim bodies As X2BodiesFromContact = X2.GetBodiesFromContact(Contact, "left edge")
	If bodies <> Null And bodies.OtherBody.DelegateTo Is Enemy Then
		X2.AddFutureTask(Me, "Delete_Enemy", 0, bodies.OtherBody)
		Return
	End If
	
End Sub

Private Sub World_PreSolve (Contact As B2Contact, OldManifold As B2Manifold)
	Dim BodyA As X2BodyWrapper = Contact.FixtureA.Body.Tag
	Dim BodyB As X2BodyWrapper = Contact.FixtureB.Body.Tag
	If BodyA.IsVisible = False Or BodyB.IsVisible = False Then Return
	CheckMarioCollisions (Contact, X2.GetBodiesFromContact(Contact, "mario"))
	CheckEnemyCollisions(Contact, X2.GetBodiesFromContact(Contact, "enemy bug"))
	CheckEnemyCollisions(Contact, X2.GetBodiesFromContact(Contact, "enemy turtle"))
End Sub

Private Sub CheckEnemyCollisions (Contact As B2Contact, bodies As X2BodiesFromContact)
	If bodies = Null Then Return
	If bodies.ThisBody.Body.Position.Y < 1.5 Then
		X2.AddFutureTask(Me, "Delete_Enemy", 0, bodies.ThisBody)
		Return
	End If
	If bodies.OtherBody.Name = "turtle squashed" And bodies.OtherBody.Body.LinearVelocity.Length > 2 Then
		X2.AddFutureTask(bodies.ThisBody.DelegateTo, "HitFromTurtleShield_Start", 0, Null)
		Contact.IsEnabled = False 'disable so it will not slow down
		Return
	End If
	Dim wm As B2WorldManifold
	Contact.GetWorldManifold(wm)
	wm.Normal.MultiplyThis(bodies.NormalSign)
	If wm.Normal.x < -0.5 Or wm.Normal.X > 0.5 Then
		X2.AddFutureTask(bodies.ThisBody.DelegateTo, "Change_Direction", 0, wm.Normal.X)
		If bodies.OtherBody.DelegateTo Is Enemy Then
			X2.AddFutureTask(bodies.OtherBody.DelegateTo, "Change_Direction", 0, -wm.Normal.X)
		End If
	End If
End Sub

Private Sub Delete_Enemy(ft As X2FutureTask)
	Dim bw As X2BodyWrapper = ft.Value
	bw.Delete(X2.gs)
End Sub



Private Sub CheckMarioCollisions (Contact As B2Contact, bodies As X2BodiesFromContact)
	If bodies = Null Then Return
	'check the normal between the kid and other bodies. If the Y value is negative then the kid is standing on something.
	Dim wm As B2WorldManifold
	Contact.GetWorldManifold(wm)
	wm.Normal.MultiplyThis(bodies.NormalSign)
	If wm.Normal.Y < -0.5 Then
		mMario.InAir = False
	End If
	If bodies.OtherBody.DelegateTo Is Enemy Then
		Dim Other As Enemy = bodies.OtherBody.DelegateTo
		If Other.HitState Then Return
		If wm.Normal.Y < -0.5 Then
			'hit enemy from above
			X2.AddFutureTask(bodies.OtherBody.DelegateTo, "HitFromMario_Start", 0, Null)
			If mMario.IsLegsFixture(bodies.ThisFixture) Then
				'give mario a small push
				mMario.bw.Body.ApplyLinearImpulse(X2.CreateVec2(0, 20 * mMario.bw.Body.Mass), mMario.bw.Body.WorldCenter)
			End If
		Else
			'hit enemy from the side
			X2.AddFutureTask(mMario, "Hit_Start", 0, Null)
		End If
	End If
End Sub

'Return True to stop the game loop
Public Sub BeforeTimeStep (GS As X2GameStep) As Boolean
	mMario.InAir = True
	If GameOverState Then
		Return True
	End If
	Return False
End Sub

Public Sub HitEnemy (Position As B2Vec2)
	X2.SoundPool.PlaySound("kick")
	CreateScore(Position, Rnd(1, 1000))
End Sub

Public Sub CreateScore (Position As B2Vec2, Score As Int)
	Dim template As X2TileObjectTemplate = TileMap.GetObjectTemplate(ObjectLayer, 72)
	template.BodyDef.Position = Position
	template.BodyDef.LinearVelocity = X2.CreateVec2(0, 2)
	Dim bw As X2BodyWrapper = TileMap.CreateObject(template)
	Dim gname As String = X2.GraphicCache.GetTempName
	Dim ShapeSize As B2Vec2 = X2.GetShapeWidthAndHeight(template.FixtureDef.Shape)
	ShapeSize.MultiplyThis(X2.mBCPixelsPerMeter)
	Dim cvs As B4XCanvas = X2.GraphicCache.GetCanvas(ShapeSize.X / X2.BmpSmoothScale)
	cvs.ClearRect(cvs.TargetRect)
	Dim text As String = Score
	Dim r As B4XRect = cvs.MeasureText(text, ScoreFont)
	Dim BaseLine As Int = ShapeSize.Y / 2 - r.Height / 2 - r.Top
	cvs.DrawText(text, ShapeSize.X / 2, BaseLine, ScoreFont,  xui.Color_White, "CENTER")
	Dim sb As X2ScaledBitmap
	sb.Bmp = cvs.CreateBitmap.Crop(0, 0, ShapeSize.X, ShapeSize.Y)
	sb.Scale = 1
	X2.GraphicCache.PutGraphic(gname, Array(sb))
	bw.GraphicName = gname
End Sub

Public Sub GameOver
	X2.SoundPool.StopMusic
	X2.SoundPool.PlaySound("gameover")
	X2.AddFutureTask(Me, "Set_GameOver", 3500, Null)
End Sub

Private Sub Set_GameOver (ft As X2FutureTask)
	GameOverState = True
	Sleep(500)
	StartGame
End Sub

Public Sub StopGame
	X2.SoundPool.StopMusic
	X2.Stop
End Sub



