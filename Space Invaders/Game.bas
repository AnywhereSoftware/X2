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
	Private ScoreFont As B4XFont
	Private GameOverState As Boolean
	Public mShip As Ship
	Public PanelForTouch As B4XView
	Private ScoreLabel1 As ScoreLabel
	Private CurrentVelocity As B2Vec2
	Private Lives As Int
	Private EnemyShootsInterval As Int
	Private Level As Int
	Public LivesPanel As B4XView
	Private lblLevel As B4XView
	Private lblMessages As B4XView
	Public CanFire As Boolean
	Private HighScore As Int
	Private Const ConfigFile As String = "config.txt"
	Private lblHighScore As B4XView
	Public Multitouch As X2MultiTouch
End Sub

Public Sub Initialize (Parent As B4XView)
	Parent.LoadLayout("1")
	world.Initialize("world", world.CreateVec2(0, 0)) 'no gravity
	X2.Initialize(Me, ivForeground, world)
	Dim WorldHeight As Float = 6 
	Dim WorldWidth As Float = WorldHeight * 1.3333
	X2.ConfigureDimensions(world.CreateVec2(WorldWidth / 2, WorldHeight / 2), WorldWidth)
	X2.SetBitmapWithFitOrFill(ivBackground, xui.LoadBitmapResize(File.DirAssets, "background.jpg", ivBackground.Width / 2, ivBackground.Height / 2, False))
	lblStats.TextColor = xui.Color_White
	'comment to disable debug drawing
	'X2.EnableDebugDraw
	X2.SoundPool.AddSound("shoot", File.DirAssets, "shoot.wav")
	X2.SoundPool.AddSound("shoot2", File.DirAssets, "shoot2.wav")
	X2.SoundPool.AddSound("shipexplosion", File.DirAssets, "shipexplosion.wav")
	X2.SoundPool.AddSound("invaderkilled", File.DirAssets, "invaderkilled.wav")
	X2.SoundPool.AddSound("mystery entered", File.DirAssets, "mysteryentered.wav")
	#if B4J
	Dim fx As JFX
	ScoreFont = fx.LoadFont(File.DirAssets, "space_invaders.ttf", 20)
	For Each lbl As Label In Array(ScoreLabel1.Base.GetView(0), lblMessages, lblLevel, lblHighScore)
		lbl.Style = "" 'to avoid conflicts between the CSS settings and the custom font
	Next
	#else if B4i
	ScoreFont = Font.CreateNew2("Space Invaders", 20)
	#else
	ScoreFont = xui.CreateFont(Typeface.LoadFromAssets("space_invaders.ttf"), 20)
	#End If
	ScoreLabel1.Base.GetView(0).Font = ScoreFont
	lblLevel.Font = ScoreFont
	lblMessages.Font = xui.CreateFont2(ScoreFont, 80)
	lblMessages.Color = 0x66000000
	lblHighScore.Font = ScoreFont
	xui.SetDataFolder("SpaceInvaders")
	If File.Exists(xui.DefaultFolder, ConfigFile) Then
		Dim m As Map = File.ReadMap(xui.DefaultFolder, ConfigFile)
		HighScore = m.GetDefault("highscore", 0)
	End If
	Multitouch.Initialize(B4XPages.MainPage, Array(PanelForTouch))
End Sub

Public Sub StartGame
	If X2.IsRunning Then Return
	X2.Reset
	Multitouch.ResetState
	Lives = 3
	ScoreLabel1.SetValueNow(0)
	X2.UpdateWorldCenter(X2.CreateVec2(X2.ScreenAABB.Width / 2, X2.ScreenAABB.Height / 2))
	GameOverState = False
	TileMap.Initialize(X2, File.DirAssets, "map.json", ivBackground)
	Dim TileSizeMeters As Float = X2.ScreenAABB.Height / TileMap.TilesPerColumn
	TileMap.SetSingleTileDimensionsInMeters(TileSizeMeters, TileSizeMeters)
	TileMap.PrepareObjectsDef(ObjectLayer)
	Dim bw As X2BodyWrapper = TileMap.CreateObject(TileMap.GetObjectTemplate(ObjectLayer, 16)) '16 = ship id in the map
	mShip.Initialize(bw)
	mShip.bw.Body.LinearDamping = 6 'slow down in air
	TileMap.CreateObject(TileMap.GetObjectTemplate(ObjectLayer, 10)) 'edges
	TileMap.CreateObject(TileMap.GetObjectTemplate(ObjectLayer, 11))
	lblHighScore.Text = $"High score: ${HighScore}"$
	ScoreLabel1.Base.GetView(0).TextColor = xui.Color_White
	SetLevel(1)
	UpdateLives(3)
	X2.Start
End Sub


Public Sub IncrementScore (Delta As Int)
	ScoreLabel1.Value = ScoreLabel1.Value + Delta
	If ScoreLabel1.Value > HighScore Then
		ScoreLabel1.Base.GetView(0).TextColor = xui.Color_Yellow
	End If
End Sub

Private Sub SetLevel (NewLevel As Int)
	Level = NewLevel
	EnemyShootsInterval = Max(100, 2000 - Level * 200)
	mShip.MinFireInterval = Max(50, 400 - 50 * NewLevel)
	lblLevel.Text = $"Level: ${Level}"$
	CreateEnemies
	CreateShields
	ShowMessage($"Level ${NewLevel}"$, True)
	CurrentVelocity = X2.CreateVec2(0, 0)
	CanFire = False
	'delete lasers
	For Each bw As X2BodyWrapper In X2.GetBodiesWrappersByIds(Array(12, 15))
		bw.Delete(X2.gs)
	Next
	X2.AddFutureTask(Me, "UpdateCurrent_Velocity", 2000, Null)
End Sub

Private Sub UpdateCurrent_Velocity (ft As X2FutureTask)
	CurrentVelocity = X2.CreateVec2(Level / 2, 0)
	CanFire = True
End Sub

Public Sub ShowMessage(Text As String, HideAutomatically As Boolean)
	lblMessages.Text = Text
	lblMessages.SetVisibleAnimated(500, True)
	If HideAutomatically Then
		Sleep(2000)
		If lblMessages.Text = Text Then
			lblMessages.SetVisibleAnimated(500, False)
		End If
	End If
End Sub
Private Sub UpdateLives (NewLives As Int)
	Lives = NewLives
	If NewLives < 0 Then
		GameOverState = True
		ShowMessage("Game Over", True)
		If ScoreLabel1.Value > HighScore Then
			HighScore = ScoreLabel1.Value
			File.WriteMap(xui.DefaultFolder, ConfigFile, CreateMap("highscore": HighScore))
		End If
		Sleep(2000)
		StartGame
	Else
		For i = 1 To 3
			LivesPanel.GetView(i - 1).Visible = i <= NewLives
		Next
	End If
End Sub



Private Sub CreateEnemies
	Dim EnemySize As Float = 100 * TileMap.MapXToMeter 'square shape
	Dim templates() As Int = Array As Int(5, 8, 9)
	For y = 0 To 3
		For x = 0 To 8
			Dim template As X2TileObjectTemplate = TileMap.GetObjectTemplate(ObjectLayer, templates(Rnd(0, templates.Length)))
			template.BodyDef.Position.Set(1 + EnemySize * x, X2.ScreenAABB.TopRight.Y - 1 - EnemySize * y)
			template.Name = "enemy"
			Dim bw As X2BodyWrapper = TileMap.CreateObject(template)
			bw.NumberOfFrames = 2 'don't switch to the explosion graphic
		Next
	Next
End Sub

Private Sub CreateShields
	Dim ids() As Int = Array As Int(17, 19, 20)
	For Each bw As X2BodyWrapper In X2.GetBodiesWrappersByIds(ids)
		bw.Delete(X2.gs)
	Next
	For Each id As Int In ids
		Dim template As X2TileObjectTemplate = TileMap.GetObjectTemplate(ObjectLayer, id)
		Dim bw As X2BodyWrapper = TileMap.CreateObject(template)
		Dim shld As Shield
		shld.Initialize(bw)
	Next
End Sub


Public Sub Resize
	X2.ImageViewResized
End Sub

Public Sub Tick (GS As X2GameStep)
	ScoreLabel1.Tick
	Dim Enemies As List = GetListOfEnemies
	If Enemies.Size = 0 Then
		SetLevel(Level + 1)
	End If
	For Each enemy As X2BodyWrapper In Enemies
		enemy.Body.LinearVelocity = CurrentVelocity
	Next
	'CanFire means that the game is really running.
	If CanFire Then
		If X2.RndFloat(0, EnemyShootsInterval) < X2.TimeStepMs Then
			'shoot
			Dim enemy As X2BodyWrapper = Enemies.Get(Rnd(0, Enemies.Size))
			Dim template As X2TileObjectTemplate = TileMap.GetObjectTemplate(ObjectLayer, 15)
			template.BodyDef.Position.X = enemy.Body.Position.X
			template.BodyDef.Position.Y = enemy.Body.Position.Y - 0.5
			template.BodyDef.LinearVelocity = X2.CreateVec2(0, -2)
			TileMap.CreateObject(template)
			X2.SoundPool.PlaySound("shoot2")
		End If
		If X2.RndFloat(0, 10000) < X2.TimeStepMs Then
			CreateMystery
		End If
	End If
End Sub

Private Sub GetListOfEnemies As List
	Return X2.GetBodiesWrappersByIds(Array(5, 8, 9))
End Sub

Private Sub CreateMystery
	'the mystery enemy category bits = 0xffff - 1 so it ignores the walls
	Dim bw As X2BodyWrapper = TileMap.CreateObject(TileMap.GetObjectTemplate(ObjectLayer, 22))
	bw.Body.LinearVelocity = X2.CreateVec2(3, 0)
	X2.SoundPool.PlaySound("mystery entered")
	
End Sub

Public Sub DrawingComplete

End Sub


'This event fires while the world is locked.
'We need to use AddFutureTask to run code after the physics engine completed the time step.
Private Sub World_BeginContact (Contact As B2Contact)
	Dim bodies As X2BodiesFromContact = X2.GetBodiesFromContact(Contact, "enemy")
	If bodies <> Null Then
		If bodies.OtherBody.Name = "left edge" Then
			X2.AddFutureTask(Me, "change_direction", 0, True)
		Else If bodies.OtherBody.Name = "right edge" Then
			X2.AddFutureTask(Me, "change_direction", 0, False)
		Else If bodies.OtherBody.Name = "ship laser" Then
			X2.AddFutureTask(Me, "EnemyHit_WithMissle", 0, bodies)
		Else If bodies.OtherBody.Name = "ship" Then
			X2.AddFutureTask(Me, "ShipHit_WithEnemy", 0, bodies)
		End If
	End If
	bodies = X2.GetBodiesFromContact(Contact, "enemy laser")
	If bodies <> Null And bodies.OtherBody.Name = "ship" Then
		X2.AddFutureTask(Me, "ShipHit_WithMissile", 0, bodies)
	End If
	bodies = X2.GetBodiesFromContact(Contact, "shield")
	If bodies <> Null Then 
		X2.AddFutureTask(Me, "Shield_Hit", 0, bodies)
	End If
	bodies = X2.GetBodiesFromContact(Contact, "mystery")
	If bodies <> Null Then X2.AddFutureTask(Me, "Mystery_Hit", 0, bodies)
End Sub

Private Sub Mystery_Hit (ft As X2FutureTask)
	X2.SoundPool.PlaySound("invaderkilled")
	IncrementScore(1000)
	Dim bodies As X2BodiesFromContact = ft.Value
	bodies.ThisBody.Body.AngularVelocity = 5
End Sub


Private Sub Shield_Hit (ft As X2FutureTask)
	Dim bodies As X2BodiesFromContact = ft.Value
	If bodies.OtherBody.Name <> "enemy" Then
		bodies.OtherBody.Delete(X2.gs) 'delete the missile
	End If
	Dim shld As Shield = bodies.ThisBody.DelegateTo
	shld.Hit(bodies.ThisFixture)
End Sub

Private Sub ShipHit_WithEnemy(ft As X2FutureTask)
	UpdateLives(-1)
	X2.SoundPool.PlaySound("shipexplosion")
End Sub

Private Sub ShipHit_WithMissile(ft As X2FutureTask)
	Dim bodies As X2BodiesFromContact = ft.Value
	bodies.ThisBody.Delete(X2.gs) 'delete the missile
	If mShip.HitState Then Return
	UpdateLives(Lives - 1)
	mShip.Hit
	X2.SoundPool.PlaySound("shipexplosion")
End Sub

Private Sub EnemyHit_WithMissle(ft As X2FutureTask)
	Dim bodies As X2BodiesFromContact = ft.Value
	bodies.OtherBody.Delete(X2.gs) 'delete the missile
	Dim enemy As X2BodyWrapper = bodies.ThisBody
	enemy.CurrentFrame = 2
	enemy.SwitchFrameIntervalMs = 0
	IncrementScore(100)
	X2.AddFutureTask(Me, "Delete_Enemy", 100, enemy)
	X2.SoundPool.PlaySound2("invaderkilled", 0.3)
End Sub

Private Sub Delete_Enemy(ft As X2FutureTask)
	Dim enemy As X2BodyWrapper = ft.Value
	If enemy.IsDeleted Then Return
	enemy.Delete(X2.gs)
End Sub

Private Sub Change_Direction(ft As X2FutureTask)
	Dim Left As Boolean = ft.Value
	If Left Then
		CurrentVelocity.Set(CurrentVelocity.Length, 0)
	Else
		CurrentVelocity.Set(-CurrentVelocity.Length, 0)
	End If
	For Each Enemy As X2BodyWrapper In GetListOfEnemies
		Enemy.Body.SetTransform(X2.CreateVec2(Enemy.Body.Position.X + CurrentVelocity.X / 10, Enemy.Body.Position.Y - 0.2), Enemy.Body.Angle)
	Next
End Sub


'Return True to stop the game loop
Public Sub BeforeTimeStep (GS As X2GameStep) As Boolean
	If GameOverState Then
		Return True
	End If
	Return False
End Sub


Public Sub StopGame
	X2.Stop
End Sub

#If B4i
Private Sub Panel_Multitouch (Stage As Int, Data As Object)
	Multitouch.B4iDelegateMultitouchEvent(Sender, Stage, Data)
End Sub
#End If
