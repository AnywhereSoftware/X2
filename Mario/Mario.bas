B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=6.47
@EndOfDesignText@
Sub Class_Globals
	Public bw As X2BodyWrapper
	Private x2 As X2Utils 'ignore
	Public InAir As Boolean
	Public IsSmall As Boolean = True
	Private LastTickTime As Int
	Private FaceRight As Boolean = True
	Private MaxVelocity As Float = 10
	Private SpecialState As Boolean
	Private ImpulseVector As B2Vec2
	Private ProtectedTime As Int
End Sub

Public Sub Initialize (wrapper As X2BodyWrapper)
	bw = wrapper
	x2 = bw.X2
	bw.DelegateTo = Me
	UpdateImpulseVector
	CreateMarioLegs
End Sub

Private Sub CreateMarioLegs
	Dim rect As B2PolygonShape
	rect.Initialize
	rect.SetAsBox2(0.45, 0.05, x2.CreateVec2(0, -x2.GetShapeWidthAndHeight(bw.Body.FirstFixture.Shape).y / 2 + 0.05), 0)
	Dim f As B2Fixture = bw.Body.CreateFixture2(rect, 0.1)
	f.Friction = 1
	f.Tag = "legs"
End Sub

Private Sub UpdateImpulseVector
	ImpulseVector = x2.CreateVec2(0.5 * bw.Body.Mass * x2.TimeStepMs / 16, 0) 
End Sub

Public Sub Hit_Start (ft As X2FutureTask)
	If SpecialState Then Return
	If x2.gs.GameTimeMs < ProtectedTime Then Return
	If IsSmall = False Then
		ChangeSize(False)
	Else
		StartGameOver
	End If
End Sub

Private Sub StartGameOver
	SpecialState = True
	bw.GraphicName = "mario small strike"
	bw.Body.FirstFixture.SetFilterBits(0, 0)
	bw.Body.FirstFixture.NextFixture.SetFilterBits(0, 0)
	bw.Body.LinearVelocity = x2.CreateVec2(0, 15)
	bw.mGame.GameOver
End Sub

Public Sub Tick (GS As X2GameStep)
	If LastTickTime = GS.GameTimeMs Then Return
	LastTickTime = GS.GameTimeMs
	Dim changingDirection As Boolean
	If SpecialState Then
		'do nothing
	Else
		Dim RightDown, LeftDown, JumpDown  As Boolean
		Dim mt As X2MultiTouch = x2.mGame.Multitouch
		#if B4J
		RightDown = mt.Keys.Contains("Right")
		LeftDown = mt.Keys.Contains("Left")
		JumpDown = mt.Keys.Contains("Space")
		#Else
		For Each touch As X2Touch In mt.GetTouches(x2.mGame.Panel1)
			If touch.Y > 0.6 * x2.mGame.Panel1.Height Then
				'bottom area
				If touch.X < 0.5 * x2.mGame.Panel1.Width Then
					LeftDown = True
				Else
					RightDown = True
				End If
			Else
				JumpDown = True
			End If
		Next
		#End If
		If InAir = False And JumpDown Then
			bw.Body.LinearVelocity = x2.CreateVec2(bw.Body.LinearVelocity.X, 13)
			If IsSmall Then
				x2.SoundPool.PlaySound("small jump")
			Else
				x2.SoundPool.PlaySound("big jump")
			End If
			InAir = True
		Else If RightDown Then
			If InAir = False Then
				FaceRight = True
				changingDirection = bw.Body.LinearVelocity.X < 0
			End If
			If bw.Body.LinearVelocity.X < MaxVelocity Then bw.Body.ApplyLinearImpulse(ImpulseVector, bw.Body.WorldCenter)
		Else If LeftDown Then
			If InAir = False Then
				FaceRight = False
				changingDirection = bw.Body.LinearVelocity.X > 0
			End If
			If bw.Body.LinearVelocity.X > -MaxVelocity Then bw.Body.ApplyLinearImpulse(ImpulseVector.Negate, bw.Body.WorldCenter)
		End If
	
		If InAir Then
			bw.GraphicName = GetGraphicName("jumping")
		Else If Abs(bw.Body.LinearVelocity.X) < 0.4 Then
			If bw.Body.LinearVelocity.X <> 0 Then bw.Body.LinearVelocity = x2.CreateVec2(0, 0)
			bw.GraphicName = GetGraphicName("standing")
		Else
			bw.GraphicName = GetGraphicName("walking")
		End If
		bw.FlipHorizontal = FaceRight = False
		If changingDirection Then bw.GraphicName = GetGraphicName("change direction")
		If bw.Body.Position.Y < 1 Then StartGameOver
	End If
	
	If bw.Body.WorldCenter.X > x2.ScreenAABB.Center.X Then
		'update the screen center
		Dim WorldX As Float = Min(bw.Body.WorldCenter.X, bw.mGame.TileMap.MapAABB.TopRight.X - x2.ScreenAABB.Width / 2)
		If WorldX > x2.ScreenAABB.Center.X Then
			x2.UpdateWorldCenter(x2.CreateVec2(WorldX, x2.ScreenAABB.Center.Y))
			bw.mGame.WorldCenterUpdated(GS)
		End If
	End If
	
	If GS.ShouldDraw Then
		bw.UpdateGraphic(GS, True)
	End If
End Sub

Private Sub Touch_Mushroom (ft As X2FutureTask)
	If SpecialState Then Return
	Dim mushroom As X2BodyWrapper = ft.Value
	mushroom.Delete(x2.gs)
	ChangeSize(True)
End Sub

Private Sub ChangeSize (ToLarge As Boolean)
	x2.SoundPool.PlaySound("powerup")
	bw.GraphicName = "mario change size"
	bw.Body.LinearVelocity = x2.CreateVec2(0, 0)
	Dim id As Int
	If ToLarge Then
		id = 24
		bw.mGame.CreateScore(bw.Body.Position, 100)
	Else
		id = 3
	End If
	Dim template As X2TileObjectTemplate = bw.mGame.TileMap.GetObjectTemplate(bw.mGame.ObjectLayer, id)
	Dim fixture As B2Fixture = bw.Body.FirstFixture
	If IsLegsFixture(fixture) = False Then fixture = fixture.NextFixture
	bw.Body.DestroyFixture(fixture)
	Dim FixtureToDestroy As B2Fixture = bw.Body.FirstFixture
	bw.Body.CreateFixture(template.FixtureDef)
	bw.X2.AddFutureTask(Me, "ChangeSize_End", 1500, Array(ToLarge, FixtureToDestroy))
	SpecialState = True
	
End Sub

Public Sub IsLegsFixture (Fixture As B2Fixture) As Boolean
	Return Fixture.Tag <> Null And Fixture.Tag = "legs"
End Sub

Private Sub ChangeSize_End (ft As X2FutureTask)
	SpecialState = False
	Dim params() As Object = ft.Value
	IsSmall = Not(params(0))
	bw.Body.DestroyFixture(params(1))
	UpdateImpulseVector
	ProtectedTime = x2.gs.GameTimeMs + 2000
	CreateMarioLegs
End Sub

Private Sub GetGraphicName(variant As String) As String
	If IsSmall Then
		Return "mario small " & variant
	Else
		Return "mario large " & variant
	End If
End Sub