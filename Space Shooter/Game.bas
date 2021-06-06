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
	Private ivForeground As B4XView
	Public ivBackground As B4XView
	Public lblStats As B4XView
	Public TileMap As X2TileMap
	Public Const ObjectLayer As String = "Object Layer 1"
	Public WorldHeight As Float
	Private WorldWidth As Float
	
	Private lblMessages As B4XView
	Private Ship As X2BodyWrapper
	Private LaserLevel As Int
	Private LastFireTime As Int
	Private ShipWidth As Float
	Private ScoreLabel1 As ScoreLabel
	Private ShieldTime As Int
	Private ShieldBrush As BCBrush
	Private ImageViews As List
	Private ImageView1 As B4XView
	Private ImageView2 As B4XView
	Private ImageView3 As B4XView
	Private CurrentLives As Int
	Private pnlTouch As B4XView
	Private ShipMotor As B2MotorJoint
	Private LeftBorder As X2BodyWrapper
	Private InputsDisabled As Boolean
	
	Private StartIndex As Int
	Private Multitouch As X2MultiTouch
End Sub

Public Sub Initialize (Parent As B4XView)
	'Credits are listed here: https://www.b4x.com/android/forum/threads/xui2d-space-shooter.99614/
	Parent.LoadLayout("GameLayout")
	world.Initialize("world", world.CreateVec2(0, 0))
	X2.Initialize(Me, ivForeground, world)
	X2.SoundPool.AddSound("laser", File.DirAssets, "pew.wav")
	X2.SoundPool.AddSound("asteroid", File.DirAssets, "expl6.wav")
	X2.SoundPool.AddSound("ship", File.DirAssets, "expl3.wav")
	ivBackground.SetBitmap(xui.LoadBitmapResize(File.DirAssets, "starfield.png", ivBackground.Width, ivBackground.Height, False))
	ShieldBrush = X2.MainBC.CreateBrushFromColor(0xaaFF6A00)
	ImageViews = Array(ImageView1, ImageView2, ImageView3)
	lblMessages.TextColor = 0xFF00C5FF
	ivForeground.Visible = False
	InputsDisabled = True
	Multitouch.Initialize(B4XPages.MainPage, Array(pnlTouch))
End Sub


Public Sub Start
	If X2.IsRunning Then Return
	'Make sure that start was not called while the message appeared (this can happen in edge cases where the app moves to the background
		'and then quickly to the foreground several times).
	StartIndex = StartIndex + 1
	Dim MyIndex As Int = StartIndex
	Wait For (ShowMessage("Get Ready...")) Complete (Success As Boolean)
	If MyIndex <> StartIndex Then Return
	X2.Reset
	Multitouch.ResetState
	Dim ratio As Float = ivForeground.Width / ivForeground.Height
	WorldWidth = 6
	WorldHeight = WorldWidth / ratio
	X2.ConfigureDimensions(X2.CreateVec2(WorldWidth / 2, WorldHeight / 2), WorldWidth)
	'comment to disable debug drawing
'	X2.EnableDebugDraw
	TileMap.Initialize(X2, File.DirAssets, "space shooter.json", Null)
	'square tiles. The base size is the world width.
	TileMap.SetSingleTileDimensionsInMeters(WorldWidth / TileMap.TilesPerRow, WorldWidth / TileMap.TilesPerRow)
	TileMap.PrepareObjectsDef(ObjectLayer)
	lblMessages.Visible = False
	LeftBorder = TileMap.CreateObject2ByName(ObjectLayer, "left border")
	TileMap.CreateObject2ByName(ObjectLayer, "right border")
	Ship = TileMap.CreateObject2ByName(ObjectLayer, "ship")
	If xui.IsB4J Then
		Ship.Body.SetTransform(X2.CreateVec2(Ship.Body.Position.X, 0.5), 0)
	End If
	Ship.Body.LinearDamping = 4 'stop quickly
	ShipWidth = X2.GetShapeWidthAndHeight(Ship.Body.FirstFixture.Shape).X
	ScoreLabel1.SetValueNow(0)
	
	SetLives(3)
	ivForeground.Visible = True
	'motor is used in B4A and B4i to move the ship to the touch position.
	Dim motor As B2MotorJointDef
	motor.Initialize(LeftBorder.Body, Ship.Body)
	motor.MaxMotorForce = 0
	motor.CollideConnected = True
	ShipMotor = world.CreateJoint(motor)
	ShipMotor.CorrectionFactor = 0.2
	X2.Start
	InputsDisabled = False
End Sub

Public Sub Stop
	X2.Stop
	InputsDisabled = True
End Sub


Public Sub Resize
	X2.ImageViewResized
End Sub

Public Sub Tick (GS As X2GameStep)
	Dim ShouldFire As Boolean
	Dim touch As X2Touch = Multitouch.GetSingleTouch(pnlTouch) 'we always get the touch even if it will be ignored. This call clears touch that ended.
	If InputsDisabled = False Then
		#if b4j
		ShouldFire = Multitouch.Keys.Contains("Space")
		If Multitouch.Keys.Contains("Left") Then
			Ship.Body.ApplyForceToCenter(X2.CreateVec2(-4, 0))
		Else If Multitouch.Keys.Contains("Right") Then
			Ship.Body.ApplyForceToCenter(X2.CreateVec2(4, 0))
		End If
		#else
		If touch.IsInitialized = False Then
			ShipMotor.MaxMotorForce = 0
			ShouldFire = False
		Else
			Dim v As B2Vec2 = X2.ScreenPointToWorld(touch.X, touch.Y)
			ShipMotor.LinearOffset = X2.CreateVec2(v.X, ShipMotor.LinearOffset.Y)
			ShipMotor.MaxMotorForce = 5
			ShouldFire = True
		End If
		#end if
		If ShouldFire Then
			Fire(GS)
		End If
	End If
	Dim AsteroidInterval As Int = Max(200, 800 - GS.GameTimeMs / 20)
	If X2.RndFloat(0, AsteroidInterval) < X2.TimeStepMs Then CreateAsteroid
	If X2.RndFloat(0, 10000) < X2.TimeStepMs Then CreatePowerUp 
	ScoreLabel1.Tick
	If IsProtected Then
		DrawShield(GS)
	End If
End Sub

Private Sub DrawShield (gs As X2GameStep)
	Dim v As B2Vec2 = X2.WorldPointToMainBC(Ship.Body.Position.X, Ship.Body.Position.Y)
	Dim radius As Float = ShipWidth / 2 * X2.mBCPixelsPerMeter + 30
	gs.DrawingTasks.Add(X2.MainBC.AsyncDrawCircle(v.X, v.Y, radius, ShieldBrush, False, 10))
End Sub

Private Sub CreatePowerUp
	Dim powerbody As X2BodyWrapper = TileMap.CreateObject2ByName(ObjectLayer, "power")
	powerbody.Body.SetTransform(X2.CreateVec2(X2.RndFloat(0, WorldWidth), WorldHeight), 0)
	powerbody.Body.LinearVelocity = X2.CreateVec2(X2.RndFloat(-1, 1), X2.RndFloat(-6, -2))
End Sub

Private Sub CreateAsteroid 
	Dim asteroid As X2BodyWrapper = TileMap.CreateObject2ByName(ObjectLayer, "asteroid " & Rnd(1, 4))
	Dim pos As Int = Rnd(1, 11)
	If pos < 6 Then 'top
		asteroid.Body.SetTransform(X2.CreateVec2(X2.RndFloat(0, WorldWidth), WorldHeight), 0)
		asteroid.Body.LinearVelocity = X2.CreateVec2(X2.RndFloat(-3, 3), X2.RndFloat(-6, -2))
	Else if pos < 9 Then 'left 
		asteroid.Body.SetTransform(X2.CreateVec2(0, WorldHeight / 2), 0)
		asteroid.Body.LinearVelocity = X2.CreateVec2(X2.RndFloat(1, 3), X2.RndFloat(-2, 2))
	Else 'right
		asteroid.Body.SetTransform(X2.CreateVec2(WorldWidth, WorldHeight / 2), 0)
		asteroid.Body.LinearVelocity = X2.CreateVec2(X2.RndFloat(-3, -1), X2.RndFloat(-2, 2))
	End If
	asteroid.Body.AngularVelocity = X2.RndFloat(-3, 3)
End Sub

Private Sub Fire (GS As X2GameStep)
	If GS.GameTimeMs < LastFireTime + 200 Then Return
	LastFireTime = GS.GameTimeMs
	Dim lasers As List
	lasers.Initialize
	If LaserLevel = 1 Or LaserLevel = 3 Then
		Dim lasercenter As X2BodyWrapper = TileMap.CreateObject2ByName(ObjectLayer, "laser")
		lasers.Add(lasercenter)
		lasercenter.Body.SetTransform(Ship.Body.Position, 0)
	End If
	If LaserLevel >= 2 Then
		Dim laserleft As X2BodyWrapper = TileMap.CreateObject2ByName(ObjectLayer, "laser")
		Dim laserright As X2BodyWrapper = TileMap.CreateObject2ByName(ObjectLayer, "laser")
		Dim v As B2Vec2 = Ship.Body.Position.CreateCopy
		v.X = v.X - ShipWidth / 2
		laserleft.Body.SetTransform(v, 0)
		v.X = v.X + ShipWidth
		laserright.Body.SetTransform(v, 0)
		lasers.Add(laserleft)
		lasers.Add(laserright)
	End If
	Dim velocity As B2Vec2 = X2.CreateVec2(0, 10)
	For Each laser As X2BodyWrapper In lasers
		laser.Name = "fire" 'for the collision detection
		laser.Body.LinearVelocity = velocity
	Next
	X2.SoundPool.PlaySound2("laser", 0.2)
	
End Sub

Sub World_BeginContact (Contact As B2Contact)
	Dim bc As X2BodiesFromContact = X2.GetBodiesFromContact(Contact, "fire")
	If bc <> Null And bc.OtherBody.Name.StartsWith("asteroid") Then
		X2.AddFutureTask2(Me, "Destroy_Asteroid", 0, bc, True)
	Else
		bc = X2.GetBodiesFromContact(Contact, "ship")
		If bc <> Null Then 
			If bc.OtherBody.Name = "power" Then
				X2.AddFutureTask(Me, "Power_Up", 0, bc.OtherBody)
			Else If bc.OtherBody.Name.StartsWith("asteroid") And IsProtected = False Then
				X2.AddFutureTask(Me, "Destroy_Ship", 0, Null)
			End If
		End If
	End If
End Sub

Sub World_PreSolve (Contact As B2Contact, OldManifold As B2Manifold)
	Dim bc As X2BodiesFromContact = X2.GetBodiesFromContact(Contact, "ship")
	If bc <> Null And bc.OtherBody.Name.StartsWith("asteroid") Then
		Contact.IsEnabled = False 'don't be pushed by the asteroids
	End If
End Sub



Sub IsProtected As Boolean
	Return ShieldTime > 0 And X2.gs.GameTimeMs < ShieldTime
End Sub

Sub Destroy_Ship (ft As X2FutureTask)
	Dim explosion As X2BodyWrapper = TileMap.CreateObject2ByName(ObjectLayer, "ship explosion")
	explosion.Body.SetTransform(Ship.Body.Position, 0)
	Ship.Body.LinearVelocity = X2.CreateVec2(0, 0)
	X2.SoundPool.PlaySound("ship")
	SetLives(CurrentLives - 1)
	InputsDisabled = True
	X2.AddFutureTask(Me, "Enable_Inputs", 1000, Null)
End Sub

Sub Enable_Inputs (ft As X2FutureTask)
	InputsDisabled = False
End Sub

Sub Destroy_Asteroid (ft As X2FutureTask)
	Dim bc As X2BodiesFromContact = ft.Value
	Dim asteroid As X2BodyWrapper = bc.OtherBody
	If asteroid.IsDeleted Then Return
	Dim explosion As X2BodyWrapper = TileMap.CreateObject2ByName(ObjectLayer, "explosion")
	explosion.Body.SetTransform(asteroid.Body.Position, 0)
	X2.SoundPool.PlaySound("asteroid")
	Dim FireBody As X2BodyWrapper = bc.ThisBody
	FireBody.Delete(X2.gs)
	asteroid.Delete(X2.gs)
	ScoreLabel1.Value = ScoreLabel1.Value + 100
End Sub

Sub Power_Up (ft As X2FutureTask)
	Dim powerup As X2BodyWrapper = ft.Value
	powerup.Delete(X2.gs)
	LaserLevel = Min(3, LaserLevel + 1)
	ShieldTime = X2.gs.GameTimeMs + 2000
End Sub

Public Sub SetLives(Lives As Int)
	CurrentLives = Lives
	For i = ImageViews.Size - 1 To 0 Step - 1
		Dim iv As B4XView = ImageViews.Get(i)
		iv.Visible = i + 1 <= CurrentLives
	Next
	ShieldTime = X2.gs.GameTimeMs + 3000
	LaserLevel = 1
	If CurrentLives <= 0 Then
		GameOver	
	End If
	LastFireTime = -1000
	
End Sub

Sub GameOver
	Sleep(1000)
	X2.Stop
	Wait For (ShowMessage("Game Over")) Complete (Success As Boolean)
	Start
End Sub


Public Sub DrawingComplete
End Sub

'Return True to stop the game loop
Public Sub BeforeTimeStep (GS As X2GameStep) As Boolean
	Return False
End Sub

Sub ShowMessage (Text As String) As ResumableSub
	lblStats.Visible = False
	lblMessages.SetVisibleAnimated(300, True)
	lblMessages.Text = Text
	Sleep(2000)
	lblMessages.SetVisibleAnimated(300, False)
	Sleep(300)
	lblStats.Visible = True
	Return True
End Sub


'Make sure that the panels event name is set to Panel.
#If B4J
Private Sub Panel_Touch (Action As Int, X As Float, Y As Float)
	Multitouch.B4JDelegateTouchEvent(Sender, Action, X, Y)
End Sub
#Else If B4i
Private Sub Panel_Multitouch (Stage As Int, Data As Object)
	Multitouch.B4iDelegateMultitouchEvent(Sender, Stage, Data)
End Sub
#End If
