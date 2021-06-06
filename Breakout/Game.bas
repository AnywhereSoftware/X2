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
	Private PanelForTouch As B4XView
	Private Ship As X2BodyWrapper
	Private Multitouch As X2MultiTouch
	Private sound As X2SoundPool
	Private ColumnWidth = 1.30, RowHeight = 0.44 As Float
	Private ShipMotor As B2MotorJoint
	Private Border As X2BodyWrapper
	Private Ball As X2BodyWrapper
	Private Weld As B2WeldJoint
	Private BallParked As Boolean
	Private lblMessages As B4XView
	Private Lives As Int
	Private SmallShip As B4XBitmap
	Private pnlLives As B4XView
	Private GameState As String
	Private RedBrickIndex As Int
	Private Const STATE_GETTING_READY = "get ready", STATE_PAUSED = "paused", STATE_PLAYING = "playing", STATE_GAMEOVER = "gameover" As String
End Sub

'The example files are located in the Shared Files folder and in each of the projects Files folder. In most cases you will want to delete all these files, except of the layout files.
Public Sub Initialize (Parent As B4XView)
	Parent.LoadLayout("GameLayout")
	world.Initialize("world", world.CreateVec2(0, 0))
	X2.Initialize(Me, ivForeground, world)
	TileMap.Initialize(X2, File.DirAssets, "hello world with background.json", ivBackground)
	Dim ratio As Float = ColumnWidth * TileMap.TilesPerRow / (RowHeight * TileMap.TilesPerColumn)
	Log("ratio: " & ratio) 'this number is set in the designer
	Dim WorldWidth As Float = TileMap.TilesPerRow * ColumnWidth 'meters
	Dim WorldHeight As Float = WorldWidth / ratio 'same ratio as in the designer script
	X2.ConfigureDimensions(world.CreateVec2(WorldWidth / 2, WorldHeight / 2), WorldWidth)
	'comment to disable debug drawing
'	X2.EnableDebugDraw
	TileMap.SetSingleTileDimensionsInMeters(ColumnWidth, RowHeight)
	'The map size will not be identical to the screen size. This happens because the tile size in (bc) pixels needs to be a whole number.
	'So we need to update the world center and move the map to the center.
	X2.UpdateWorldCenter(TileMap.MapAABB.Center)

	Multitouch.Initialize(B4XPages.MainPage, Array(PanelForTouch))
	sound.Initialize
	sound.AddSound("hit", File.DirAssets, "hit.m4a")
	sound.AddSound("break brick", File.DirAssets, "fail.m4a")
	sound.AddSound("fail", File.DirAssets, "fail2.m4a")
	sound.AddSound("win", File.DirAssets, "starup.m4a")
	GameState = STATE_GAMEOVER
	lblMessages.TextColor = xui.Color_White
End Sub

Private Sub PrepareWorld
	lblStats.Text = ""
	TileMap.PrepareObjectsDef(ObjectLayer)
	'create the two borders
	Border = TileMap.CreateObject2ByName(ObjectLayer, "border")
	Border.Body.AngularDamping = 0
	Ship = TileMap.CreateObject2ByName(ObjectLayer, "ship")
	ReadSprite
	Ship.Body.LinearDamping = 6 'stop quickly
	'create the bricks
	For y = 1 To 3
		For x = 1 To TileMap.TilesPerRow - 2
			Dim template As X2TileObjectTemplate = TileMap.GetObjectTemplateByName(ObjectLayer, "brick")
			template.BodyDef.Position= X2.CreateVec2((x + 0.5) * ColumnWidth, TileMap.MapAABB.TopRight.Y - (1 + y) * RowHeight)
			Dim bw As X2BodyWrapper = TileMap.CreateObject(template)
			bw.GraphicName = "brick" 'need to do it programmatically because we created the graphics programmatically.
			bw.CurrentFrame = Rnd(0, bw.NumberOfFrames)
			If bw.CurrentFrame = RedBrickIndex Then
				bw.Tag = "red"
			End If
		Next
	Next
	'The motor is used to move the ship to the touch position.
	Dim motor As B2MotorJointDef
	motor.Initialize(Border.Body, Ship.Body)
	motor.MaxMotorForce = 0 'diabled for now
	motor.CollideConnected = True
	ShipMotor = world.CreateJoint(motor)
	ShipMotor.CorrectionFactor = 0.2
	
	Ball = TileMap.CreateObject2ByName(ObjectLayer, "ball")
	Ball.Body.Bullet = True 'makes collisions more accurate

	'allow the ship to move left and right only.
	Dim ShipPivot As B2PrismaticJointDef
	ShipPivot.Initialize(Ship.Body, Border.Body, Ship.Body.WorldCenter, X2.CreateVec2(1, 0))
	ShipPivot.CollideConnected = True
	world.CreateJoint(ShipPivot)
	
	Lives = 3
	UpdateLives
	AttachBallToShip
End Sub

Private Sub AttachBallToShip
	'put the ball 0.5 meter above the ship
	Dim pos As B2Vec2 = Ship.Body.WorldCenter.CreateCopy
	pos.Y = pos.Y + 0.5
	Ball.Body.SetTransform(pos, 0)
	'connect the ball to the ship with a weld joint
	Dim WeldDef As B2WeldJointDef
	WeldDef.Initialize(Ship.Body, Ball.Body, Ball.Body.WorldCenter)
	Weld = world.CreateJoint(WeldDef)
	BallParked = True
End Sub

Private Sub UpdateLives
	pnlLives.RemoveAllViews
	For i = 1 To Lives
		Dim iv As B4XImageView = XUIViewsUtils.CreateB4XImageView
		iv.mBackgroundColor = xui.Color_Transparent
		pnlLives.AddView(iv.mBase, pnlLives.Width - 60dip * i, 0dip, 50dip, pnlLives.Height)
		iv.Bitmap = SmallShip
	Next
End Sub

Public Sub StartOrResume
	If GameState <> STATE_PAUSED And GameState <> STATE_GAMEOVER Then Return
	If GameState = STATE_GAMEOVER Then
		ivForeground.Visible = False
		X2.Reset
		PrepareWorld
	End If
	GameState = STATE_GETTING_READY
	Multitouch.ResetState
	Wait For (ShowMessage("Get Ready...", 2000)) Complete (Success As Boolean)
	If B4XPages.GetManager.IsForeground = False Then
		GameState = STATE_PAUSED
		Return
	End If
	X2.Start
	GameState = STATE_PLAYING
	ivForeground.Visible = True
End Sub

Public Sub Pause
	If GameState <> STATE_PLAYING Then Return
	X2.Stop
	GameState = STATE_PAUSED
	If BallParked = False Then AttachBallToShip
End Sub

Private Sub ReadSprite
	Dim SpritesPerRow As Int = 7
	Dim SpritesPerColumn As Int = 10
	Dim all As List = X2.ReadSprites(xui.LoadBitmap(File.DirAssets, "set0.png"), SpritesPerColumn, SpritesPerRow, ColumnWidth, RowHeight)
	Dim BricksGraphics As List
	BricksGraphics.Initialize
	'x, y
	For Each pair() As Object In Array(Array(0, 5), Array(1, 5), Array(0, 6), Array(2, 7), Array(3, 7), Array(0, 8), Array(1, 8), Array(2, 8), Array(0, 9), Array(4, 9))
		BricksGraphics.Add(all.Get(pair(1) * SpritesPerRow + pair(0)))
	Next
	RedBrickIndex = 2 '0, 6
	X2.GraphicCache.PutGraphic("brick", BricksGraphics)
	X2.GraphicCache.PutGraphic("broken red brick", Array(all.Get(1 + 7 * SpritesPerRow)))
	'we need to read the sprite again with the ship size:
	Dim ShipSize As B2Vec2 = X2.GetShapeWidthAndHeight(Ship.Body.FirstFixture.Shape)
	all = X2.ReadSprites(xui.LoadBitmap(File.DirAssets, "set0.png"), SpritesPerColumn, SpritesPerRow, ShipSize.X, ShipSize.Y)
	Dim ShipGraphics As List
	ShipGraphics.Initialize
	For Each pair() As Object In Array(Array(4, 5), Array(5, 6), Array(6, 7))
		ShipGraphics.Add(all.Get(pair(1) * SpritesPerRow + pair(0)))
	Next
	X2.GraphicCache.PutGraphic("ship", ShipGraphics)
	Dim b As X2ScaledBitmap = ShipGraphics.Get(0)
	SmallShip = b.Bmp.Resize(50dip, 50dip, True)
	Ship.GraphicName = "ship"
End Sub


Public Sub Resize
	X2.ImageViewResized
End Sub

Public Sub Tick (GS As X2GameStep)
	Dim touch As X2Touch = Multitouch.GetSingleTouch(PanelForTouch)
	#if b4j
	If Multitouch.Keys.Contains("Left") Then
		Ship.Body.ApplyForceToCenter(X2.CreateVec2(-50, 0))
	Else If Multitouch.Keys.Contains("Right") Then
		Ship.Body.ApplyForceToCenter(X2.CreateVec2(50, 0))
	End If
	#end if
	If touch.IsInitialized = False Then
		ShipMotor.MaxMotorForce = 0 'disable the motor
	Else
		'the touch panel is wider than the game screen so we need to fix the offsets.
		Dim x As Float = Min(ivForeground.Width, Max(0, touch.X - (ivForeground.Left - PanelForTouch.Left)))
		Dim v As B2Vec2 = X2.ScreenPointToWorld(X, touch.Y)
		ShipMotor.LinearOffset = X2.CreateVec2(v.X, ShipMotor.LinearOffset.Y)
		ShipMotor.MaxMotorForce = 50
	End If
	If BallParked And (Multitouch.Keys.Contains("Space") Or touch.FingerUp) Then
		BallParked = False
		world.DestroyJoint(Weld)
		Ball.Body.ApplyLinearImpulse(X2.CreateVec2(0.5, 0.5), Ball.Body.WorldCenter)
	End If
	If BallParked = False Then
		CheckForBallContacts(GS)
	End If
End Sub

Private Sub CheckForBallContacts (gs As X2GameStep)
	Dim ContactList As List = Ball.Body.GetContactList(True)
	If ContactList.Size > 0 Then
		Dim SoundToPlay As String = "hit"
		For Each contact As B2Contact In ContactList
			Dim bodies As X2BodiesFromContact = X2.GetBodiesFromContact(contact, "ball")
			Select bodies.OtherBody.Name
				Case "brick"
					If bodies.OtherBody.Tag = "red" Then
						bodies.OtherBody.GraphicName = "broken red brick"
						bodies.OtherBody.Tag = ""
					Else
						bodies.OtherBody.Delete(gs)
						SoundToPlay = "break brick"
						If CheckIfLastBrick Then
							SoundToPlay = "win"
							Win
						End If
					End If
				Case "border"
					If Ball.Body.WorldCenter.Y < Ship.Body.WorldCenter.Y Then
						Fail
						SoundToPlay = "fail"
					End If
			End Select
		Next
		sound.PlaySound(SoundToPlay)
	Else 'in air
		'we don't want the ball to move up-down or left-right
		Dim vx As Float = Ball.Body.LinearVelocity.X
		Dim vy As Float = Ball.Body.LinearVelocity.Y
		Dim f As B2Vec2
		If Abs(vx) < 3 Then
			f.X = Sign(vx)
		End If
		If Abs(vy) < 3 Then
			f.y = Sign(vy)
		End If
		f.MultiplyThis(3)
		Ball.Body.ApplyForceToCenter(f)
		'we don't want the ball to move too slow as it loses energy
		If Ball.Body.LinearVelocity.Length < 10 Then
			f = Ball.Body.LinearVelocity.CreateCopy
			f.NormalizeThis
			f.MultiplyThis(3)
			Ball.Body.ApplyForceToCenter(f)
		End If
	End If
End Sub

Private Sub CheckIfLastBrick As Boolean
	For Each body As B2Body In world.AllBodies
		Dim xbody As X2BodyWrapper = body.Tag
		If xbody.Name = "brick" And xbody.IsDeleted = False Then Return False
	Next
	Return True
End Sub

Private Sub Win
	GameState = STATE_GAMEOVER
	X2.Stop
	Wait For (ShowMessage("Well Done!!!", 2000)) Complete (unused As Boolean)
	StartOrResume
End Sub

Private Sub Fail
	Lives = Lives - 1
	UpdateLives
	If Lives >= 0 Then
		AttachBallToShip
	Else
		GameState = STATE_GAMEOVER
		X2.Stop
		Wait For (ShowMessage("Game Over", 2000)) Complete (unused As Boolean)
		StartOrResume
	End If
End Sub

Private Sub Sign(f As Float) As Float
	If f < 0 Then Return -1 Else Return 1
End Sub

Public Sub DrawingComplete
	TileMap.DrawingComplete
End Sub

'Return True to stop the game loop
Public Sub BeforeTimeStep (GS As X2GameStep) As Boolean
	Return False
End Sub

Sub ShowMessage (Text As String, HideAfterMs As Int) As ResumableSub
	Log("ShowMessage: " & Text)
	lblMessages.SetVisibleAnimated(300, True)
	lblMessages.Text = Text
	If HideAfterMs > 0 Then
		Sleep(HideAfterMs)
		lblMessages.SetVisibleAnimated(300, False)
		Sleep(350)
		
	End If
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
