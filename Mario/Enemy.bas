B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=6.47
@EndOfDesignText@
Sub Class_Globals
	Public bw As X2BodyWrapper
	Private x2 As X2Utils 'ignore
	Private v As Float
	Public HitState As Boolean
	Public IsBug As Boolean
	Public Turtle As Boolean
End Sub

Public Sub Initialize (wrapper As X2BodyWrapper)
	bw = wrapper
	x2 = bw.X2
	bw.DelegateTo = Me
	Dim ft As X2FutureTask
	ft.Value = 0
	v = -2
End Sub

Public Sub Change_Direction (ft As X2FutureTask)
	Dim Normal As Float = ft.Value
	If Normal >= 0 Then
		v = -2
		bw.FlipHorizontal = False
	Else
		v = 2
		bw.FlipHorizontal = True
	End If
	If IsBug = False And HitState = False Then
		Dim id As Int
		If bw.FlipHorizontal Then id = 110 Else id = 107
		bw.Body.DestroyFixture(bw.Body.FirstFixture)
		bw.Body.CreateFixture(bw.mGame.TileMap.GetObjectTemplate(bw.mGame.ObjectLayer, id).FixtureDef)
	End If
End Sub

Public Sub HitFromTurtleShield_Start (ft As X2FutureTask)
	If HitState Then Return
	HitState = True
	bw.FlipVertical = True
	'zero the filter bits to cause the enemy to fall out of the screen.
	bw.Body.FirstFixture.SetFilterBits(0, 0)
	bw.Body.LinearVelocity = x2.CreateVec2(0, 5)
	x2.AddFutureTask(Me, "Hit_End", 2000, Null)
	bw.mGame.HitEnemy(bw.Body.Position)
End Sub

Public Sub HitFromMario_Start (ft As X2FutureTask)
	If HitState Then Return
	bw.Body.DestroyFixture(bw.Body.FirstFixture)
	HitState = True
	bw.mGame.HitEnemy(bw.Body.Position)
	bw.Body.LinearVelocity = x2.CreateVec2(0, 0)
	If IsBug Then
		HitBug
	Else
		'hit turtle
		bw.Name = "turtle squashed"
		bw.GraphicName = bw.Name
		Dim fd As B2FixtureDef = bw.mGame.TileMap.GetObjectTemplate(bw.mGame.ObjectLayer, 113).FixtureDef
		bw.Body.CreateFixture(fd)
	End If
End Sub

Private Sub HitBug
	bw.Name = "bug squashed"
	bw.GraphicName = "bug squashed"
	bw.Body.SetTransform(x2.CreateVec2(bw.Body.Position.X, bw.Body.Position.Y - 0.25), 0)
	Dim fd As B2FixtureDef = bw.mGame.TileMap.GetObjectTemplate(bw.mGame.ObjectLayer, 70).FixtureDef
	bw.Body.CreateFixture(fd)
	x2.AddFutureTask(Me, "Hit_End", 1000, Null)
End Sub

Private Sub Hit_End(ft As X2FutureTask)
	bw.Delete(x2.gs)
End Sub

Public Sub Tick (GS As X2GameStep)
	If HitState = False Then
		bw.Body.LinearVelocity = x2.CreateVec2(v, bw.Body.LinearVelocity.Y)
	End If
	If GS.ShouldDraw Then
		bw.UpdateGraphic(GS, True)
	End If
End Sub

