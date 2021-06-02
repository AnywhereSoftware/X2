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
	Public TileMap As X2TileMap
	Public Const ObjectLayer As String = "Object Layer 2"
	Public WorldHeight As Float
	Private WorldWidth As Float
	Public TotalWidth As Float
	Private bg As Background
	Private pnlTouch As B4XView
	Private TouchStart As B2Vec2
	Private TouchNow As B2Vec2
	Private CurrentState As String
	Private bird As X2BodyWrapper
	Private HookCenter As X2BodyWrapper
	Private PulleyBrush As BCBrush
	Private BirdIdleTime As Int
	Private SimulationWorld As B2World
	Private SimulationBird As B2Body
	Private HintBrush As BCBrush
	Private lblMessages As B4XView
	Private AttemptsCounter As Int
	Type PigData (Damage As Int)
	Private lblAttempts As B4XView
	Public Multitouch As X2MultiTouch
End Sub

Public Sub Initialize (Parent As B4XView)
	Parent.LoadLayout("GameLayout")
	world.Initialize("world", world.CreateVec2(0, -10))
	X2.Initialize(Me, ivForeground, world)
	PulleyBrush = X2.MainBC.CreateBrushFromColor(xui.Color_Black)
	HintBrush = X2.MainBC.CreateBrushFromColor(0xFF007F65)
	SimulationWorld.Initialize("", world.CreateVec2(0, -10))
	xui.SetDataFolder("XUI2D Angry Birds Example")
	Dim SoundsFolder As String = File.DirAssets
	If xui.IsB4J Then
		File.Copy(File.DirAssets, "whoosh.wav", xui.DefaultFolder, "whoosh.wav")
		File.Copy(File.DirAssets, "176731__yottasounds__wild-pig-008.wav", xui.DefaultFolder, "176731__yottasounds__wild-pig-008.wav")
		SoundsFolder = xui.DefaultFolder
	End If
	X2.SoundPool.AddSound("whoosh", SoundsFolder, "whoosh.wav")
	X2.SoundPool.AddSound("pig", SoundsFolder, "176731__yottasounds__wild-pig-008.wav")
	lblMessages.Font = xui.CreateDefaultBoldFont(80)
	lblMessages.TextColor = 0xFF00A39A
	Multitouch.Initialize(B4XPages.MainPage, Array(pnlTouch))
	Start
End Sub

Public Sub Start
	Multitouch.ResetState
	Dim ratio As Float = ivForeground.Width / ivForeground.Height
	WorldHeight = 3
	TotalWidth = WorldHeight * 2
	Dim WorldWidth As Float = WorldHeight * ratio
	X2.ConfigureDimensions(X2.CreateVec2(WorldWidth / 2, WorldHeight / 2), WorldWidth)
	'comment to disable debug drawing
'	X2.EnableDebugDraw
	TileMap.Initialize(X2, File.DirAssets, "angry birds.json", Null)
	TileMap.SetSingleTileDimensionsInMeters(TotalWidth / TileMap.TilesPerRow, WorldHeight / TileMap.TilesPerColumn)
	TileMap.PrepareObjectsDef(ObjectLayer)
	
	'create the ground
	Ground = TileMap.CreateObject2ByName(ObjectLayer, "ground")
	TileMap.CreateObject2ByName(ObjectLayer, "hook")
	TileMap.CreateObject2ByName(ObjectLayer, "hook2")
	HookCenter = TileMap.CreateObject2ByName(ObjectLayer, "hook center")
	bg.Initialize(Me)
	Dim ol As X2ObjectsLayer = TileMap.Layers.Get(ObjectLayer)
	For Each Template As X2TileObjectTemplate In ol.ObjectsById.Values
		If Template.Name = "brick" Or Template.Name = "pig" Or Template.Name = "border" Then
			Dim b As X2BodyWrapper = TileMap.CreateObject(Template)
			If b.Name = "pig" Then
				b.NumberOfFrames = 3
				b.SwitchFrameIntervalMs = Rnd(1000, 2000)
				Dim pd As PigData
				pd.Initialize
				b.Tag = pd
			End If
			b.Body.LinearDamping = 1
		End If
	Next
	CurrentState = "idle"
	lblMessages.Visible = False
	UpdateAttempts (0)
	X2.UpdateTimeParameters
End Sub

Public Sub Resize
	X2.ImageViewResized
End Sub

Public Sub Tick (GS As X2GameStep)
	bg.Tick(GS)
	HandleTouch
	Select CurrentState
		Case "level finished"
			Return
		Case "scrolling"
			ScrollScreen
		Case "pull started"
			PullStarted		
		Case "bird being pulled", "bird pull end 1", "bird pull end 2"
			Pull (GS)
		Case "bird flying"
			BirdFlying (GS)
	End Select
	
End Sub

Private Sub BirdFlying (gs As X2GameStep)
	X2.UpdateWorldCenter(ClampScreenCenter(bird.Body.Position.X))
	If bird.Body.LinearVelocity.LengthSquared < 0.1 Or bird.Body.Position.X > TotalWidth Then
		If BirdIdleTime = 0 Then
			BirdIdleTime = gs.GameTimeMs
		Else if BirdIdleTime + 1000  < gs.GameTimeMs Then
			X2.UpdateWorldCenter(ClampScreenCenter(0))
			bird.Delete(gs)
			CurrentState = "idle"
		End If
	Else
		BirdIdleTime = 0
	End If
End Sub

Private Sub Pull (gs As X2GameStep)
	Dim vec As B2Vec2 = HookCenter.Body.Position.CreateCopy
	vec.SubtractFromThis(bird.Body.Position)
	Dim angle As Float = ATan2(vec.Y, vec.X)
	If CurrentState = "bird being pulled" Then
		TouchNow.X = Min(TouchNow.X, HookCenter.Body.Position.X - 0.2)
		TouchNow.Y = Max(0.2, TouchNow.Y)
		bird.Body.SetTransform(TouchNow, angle)
		SimulationBird.SetTransform(TouchNow, angle)
		RunSimulation (gs)
	End If
	DrawRopes(gs, angle)
	If CurrentState = "bird pull end 1" Then
		UpdateAttempts (AttemptsCounter + 1)
		X2.SoundPool.PlaySound("whoosh")
		CurrentState = "bird pull end 2"
	End If
	If CurrentState = "bird pull end 2" Then
		
		If bird.Body.Position.X < HookCenter.Body.Position.X Then
			Dim length As Float = vec.Length
			Dim force As B2Vec2 = X2.CreateVec2(Cos(angle), Sin(angle))
			force.MultiplyThis(1.5 * length)
			bird.Body.ApplyForce(force, bird.Body.Position)
		Else
			bird.Body.GravityScale = 1
			CurrentState = "bird flying"
		End If
	End If
End Sub

Private Sub UpdateAttempts (NewValue As Int)
	AttemptsCounter = NewValue
	lblAttempts.Visible = AttemptsCounter > 0
	lblAttempts.Text = AttemptsCounter
End Sub

Private Sub RunSimulation (gs As X2GameStep)
	If gs.ShouldDraw Then
		SimulationBird.GravityScale = 0
		SimulationBird.LinearVelocity = X2.CreateVec2(0, 0)
		For i = 1 To 20
			Dim vec As B2Vec2 = HookCenter.Body.Position.CreateCopy
			vec.SubtractFromThis(SimulationBird.Position)
			Dim angle As Float = ATan2(vec.Y, vec.X)
			If SimulationBird.Position.X < HookCenter.Body.Position.X Then
				Dim length As Float = vec.Length
				Dim force As B2Vec2 = X2.CreateVec2(Cos(angle), Sin(angle))
				force.MultiplyThis(1.5 * length)
				SimulationBird.ApplyForce(force, SimulationBird.Position)
			Else
				SimulationBird.GravityScale = 1
			End If
			SimulationWorld.TimeStep(X2.TimeStepMs / 1000 * 4, 1, 1)
			Dim v As B2Vec2 = X2.WorldPointToMainBC(SimulationBird.Position.X, SimulationBird.Position.Y)
			X2.LastDrawingTasks.Add(X2.MainBC.AsyncDrawCircle(v.X, v.Y, 10, HintBrush, True, 0))
		Next
	End If
End Sub

Private Sub DrawRopes (gs As X2GameStep, angle As Float)
	Dim BirdRadius As Float = bird.Body.FirstFixture.Shape.Radius
	Dim bcpoint As B2Vec2 = X2.WorldPointToMainBC(bird.Body.Position.X - BirdRadius * Cos(angle), bird.Body.Position.Y - BirdRadius * Sin(angle))
	Dim HookPointLeft As B2Vec2 = X2.WorldPointToMainBC(HookCenter.Body.Position.X - 0.1, HookCenter.Body.Position.Y)
	Dim HookPointRight As B2Vec2 = X2.WorldPointToMainBC(HookCenter.Body.Position.X + 0.1, HookCenter.Body.Position.Y)
	gs.DrawingTasks.Add(X2.MainBC.AsyncDrawLine(bcpoint.X, bcpoint.Y, HookPointLeft.X, HookPointLeft.Y, PulleyBrush, 5))
	X2.LastDrawingTasks.Add(X2.MainBC.AsyncDrawLine(bcpoint.X, bcpoint.Y, HookPointRight.X, HookPointRight.Y, PulleyBrush, 5))
End Sub

Private Sub PullStarted
	bird = CreateBird (world)
	'The property is named IsBullet in iXUI2D v0.99. This is fixed for the next update.
	'For now we just disable it in B4i as it is not very important.
	#if Not(B4i)
	bird.Body.Bullet = True
	#end if
	For Each body As B2Body In SimulationWorld.AllBodies
		SimulationWorld.DestroyBody(body)
	Next
	SimulationBird = CreateBird(SimulationWorld).Body
	X2.mWorld = world
	CurrentState = "bird being pulled" 
End Sub

Private Sub CreateBird (vWorld As B2World) As X2BodyWrapper
	X2.mWorld = vWorld
	Dim b As X2BodyWrapper = TileMap.CreateObject2ByName(ObjectLayer, "bird")
	b.Body.SetTransform(TouchStart, 0)
	b.Body.GravityScale = 0
	b.Body.LinearDamping = 1
	Return b
End Sub

Private Sub ScrollScreen
	Dim n As B2Vec2 = TouchNow.CreateCopy
	n.SubtractFromThis(TouchStart)
	Dim dx As Float = n.X
	X2.UpdateWorldCenter(ClampScreenCenter(X2.ScreenAABB.Center.X - dx))
	TouchNow = TouchStart
End Sub

Private Sub ClampScreenCenter (x As Float) As B2Vec2
	Return X2.CreateVec2(Max(WorldWidth / 2, Min(TotalWidth - WorldWidth / 2, x)), X2.ScreenAABB.Center.Y)
End Sub

Private Sub World_BeginContact (Contact As B2Contact)
	'collisions with sensors do not raise the PostSolve event.
	'we need to handle it here.
	Dim bc As X2BodiesFromContact = X2.GetBodiesFromContact(Contact, "pig")
	If bc <> Null Then
		If bc.OtherBody.Name = "border" Then
			X2.AddFutureTask2(Me, "Pig_Killed", 0, bc.ThisBody, True)
		End If
	End If
End Sub

Private Sub World_PostSolve (Contact As B2Contact, Impulse As B2ContactImpulse)
	Dim bc As X2BodiesFromContact = X2.GetBodiesFromContact(Contact, "pig")
	If bc <> Null Then
		Dim force As Float = Impulse.GetNormalImpulse(0)
		If Abs(force) > 0.01 Then
			If force > 0.08 Then
				X2.SoundPool.PlaySound("pig")
			End If
			Dim pd As PigData = bc.ThisBody.Tag
			pd.Damage = pd.Damage + force * 300
			If pd.Damage > 80 Then
				bc.ThisBody.MinFrame = 6
				bc.ThisBody.CurrentFrame = bc.ThisBody.MinFrame
			Else If pd.Damage > 30 Then
				bc.ThisBody.MinFrame = 3
				bc.ThisBody.CurrentFrame = bc.ThisBody.MinFrame
			End If
			bc.ThisBody.NumberOfFrames = bc.ThisBody.MinFrame + 3
			If pd.Damage > 100 Then
				X2.AddFutureTask2(Me, "Pig_Killed", 0, bc.ThisBody, True)
			End If
		End If
	End If
End Sub

Private Sub Pig_Killed (ft As X2FutureTask)
	Dim pig As X2BodyWrapper = ft.Value
	If pig.IsDeleted Then Return
	pig.Delete(X2.gs)
	For Each body As B2Body In world.AllBodies
		Dim wrapper As X2BodyWrapper = body.Tag
		If wrapper.Name = "pig" And wrapper.IsDeleted = False Then
			Return
		End If
	Next
	CurrentState = "level finished"
	'all pigs were killed
	Wait For (ShowMessage("Well Done!!!")) Complete (Success As Boolean)
	btnRestart_Click
End Sub


Public Sub DrawingComplete
	bg.DrawComplete
End Sub

'Return True to stop the game loop
Public Sub BeforeTimeStep (GS As X2GameStep) As Boolean
	Return False
End Sub

Private Sub HandleTouch
	Dim touch As X2Touch = Multitouch.GetSingleTouch(pnlTouch)
	If CurrentState = "bird flying" Or CurrentState.StartsWith("bird pull end") Then Return
	If touch.IsInitialized = False Then Return
	Log(CurrentState)
	If touch.FingerUp Then
		If CurrentState = "bird being pulled" Then
			CurrentState = "bird pull end 1"
		Else
			CurrentState = "idle"
		End If
	Else if touch.EventCounter = 0 Then
		TouchStart = X2.ScreenPointToWorld(touch.X, touch.Y)
		TouchNow = TouchStart
		For Each body As X2BodyWrapper In X2.GetBodiesIntersectingWithWorldPoint(TouchStart)
			If body.Name = "hook" Then
				CurrentState = "pull started"
				Return
			End If
		Next
		CurrentState = "scrolling"
	Else
		TouchNow = X2.ScreenPointToWorld(touch.X, touch.Y)
	End If
End Sub

Sub btnRestart_Click
	X2.Stop
	X2.Reset
	Sleep(100)
	Start
	X2.Start
End Sub

Sub ShowMessage (Text As String) As ResumableSub
	lblMessages.SetVisibleAnimated(300, True)
	lblMessages.Text = Text
	Sleep(2000)
	lblMessages.SetVisibleAnimated(300, False)
	Sleep(300)
	Return True
End Sub

#If B4J
Private Sub Panel_Touch (Action As Int, X As Float, Y As Float)
	Multitouch.B4JDelegateTouchEvent(Sender, Action, X, Y)
End Sub
#End If

#If B4i
Private Sub Panel_Multitouch (Stage As Int, Data As Object)
	MultiTouch.B4iDelegateMultitouchEvent(Sender, Stage, Data)
End Sub
#End If