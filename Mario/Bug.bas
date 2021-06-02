B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=6.47
@EndOfDesignText@
Sub Class_Globals
	Public bw As X2BodyWrapper
	Private x2 As X2Utils 'ignore
	Private idle As Boolean = True
	Private v As Float
	Private HitState As Boolean
End Sub

Public Sub Initialize (wrapper As X2BodyWrapper)
	bw = wrapper
	x2 = bw.X2
	bw.DelegateTo = Me
	ChangeDirection(0)
End Sub

Public Sub ChangeDirection (Normal As Float)
	If Normal >= 0 Then
		v = -2
	Else		
		v = 2
	End If
End Sub

Public Sub Hit_Start (ft As X2FutureTask)
	bw.Name = "bug squashed"
	bw.GraphicName = "bug squashed"
	bw.Body.LinearVelocity = x2.CreateVec2(0, 0)
	bw.Body.DestroyFixture(bw.Body.FirstFixture)
	bw.Body.SetTransform(x2.CreateVec2(bw.Body.Position.X, bw.Body.Position.Y - 0.25), 0)
	Dim fd As B2FixtureDef = bw.mGame.TileMap.GetObjectTemplate(bw.mGame.ObjectLayer, 31).FixtureDef
	bw.Body.CreateFixture(fd)
	HitState = True
	x2.AddFutureTask(Me, "Hit_End", 1000, Null)
	bw.mGame.HitEnemy(bw.Body.Position)
End Sub

Private Sub Hit_End(ft As X2FutureTask)
	bw.Delete(x2.gs)
End Sub

Public Sub Tick (GS As X2GameStep)
	If idle And bw.IsVisible Then
		idle = False
		
		bw.SwitchFrameIntervalMs = 100
	End If
	If HitState = False Then
		If idle = False Then
			bw.Body.LinearVelocity = x2.CreateVec2(v, bw.Body.LinearVelocity.Y)
		End If
	End If
	If GS.ShouldDraw Then
		bw.UpdateGraphic(GS, True)
	End If
End Sub