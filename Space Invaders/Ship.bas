B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=6.47
@EndOfDesignText@
Sub Class_Globals
	Public bw As X2BodyWrapper
	Private x2 As X2Utils 'ignore
	Private ImpulseVector As B2Vec2
	Private MaxVelocity As Float = 3
	Private LastFireTime As Int = -100000
	Public HitState As Boolean
	Public MinFireInterval As Int
	Private xui As XUI
End Sub

Public Sub Initialize (wrapper As X2BodyWrapper)
	bw = wrapper
	x2 = bw.X2
	bw.DelegateTo = Me
	ImpulseVector = x2.CreateVec2(0.5 * bw.Body.Mass * x2.TimeStepMs / 16, 0)
End Sub

Public Sub Tick (GS As X2GameStep)
	Dim FireDown, RightDown, LeftDown As Boolean
	#if B4J
	RightDown = x2.mGame.Multitouch.Keys.Contains("Right")
	LeftDown = x2.mGame.Multitouch.Keys.Contains("Left")
	FireDown = x2.mGame.Multitouch.Keys.Contains("Space")
	#else
	Dim touch As X2Touch = x2.mGame.Multitouch.GetSingleTouch(x2.mGame.PanelForTouch)
	If touch.IsInitialized Then
		LeftDown = touch.X < x2.mGame.PanelForTouch.Width / 2
		RightDown = Not(LeftDown)
	End If
	FireDown = True
	#End If
	If RightDown Then
		If bw.Body.LinearVelocity.X < MaxVelocity Then bw.Body.ApplyLinearImpulse(ImpulseVector, bw.Body.WorldCenter)
	Else If LeftDown Then
		If bw.Body.LinearVelocity.X > -MaxVelocity Then bw.Body.ApplyLinearImpulse(ImpulseVector.Negate, bw.Body.WorldCenter)
	End If
	If xui.IsB4A Or xui.IsB4i Then
		
	Else
		
	End If
	
	If FireDown And bw.mGame.CanFire Then
		If LastFireTime + MinFireInterval < GS.GameTimeMs Then
			Fire (GS)
		End If
	End If
	If HitState Then
		bw.CurrentFrame = 1
	Else
		bw.CurrentFrame = 0
	End If
	Dim angle As Float = (bw.Body.Position.X - x2.ScreenAABB.Center.X) / (x2.ScreenAABB.Width / 2) * 40 * cPI / 180
	bw.Body.SetTransform(bw.Body.Position,  angle)
	If GS.ShouldDraw Then
		bw.UpdateGraphic(GS, False)
	End If
End Sub

Private Sub Fire (gs As X2GameStep)
	LastFireTime = gs.GameTimeMs
	Dim template As X2TileObjectTemplate = bw.mGame.TileMap.GetObjectTemplate(bw.mGame.ObjectLayer, 12)
	template.BodyDef.Position = bw.Body.Position
	template.BodyDef.Angle = bw.Body.Angle
	template.BodyDef.LinearVelocity = bw.Body.Transform.MultiplyRot(x2.CreateVec2(0, 5))
	bw.mGame.TileMap.CreateObject(template)
	x2.SoundPool.PlaySound2("shoot", 0.2)
End Sub

Public Sub Hit
	If HitState Then Return
	HitState = True
	x2.AddFutureTask(Me, "End_Hit", 2000, Null)
End Sub

Private Sub End_Hit(ft As X2FutureTask)
	HitState = False
End Sub