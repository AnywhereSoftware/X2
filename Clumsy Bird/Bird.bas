B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=6.47
@EndOfDesignText@
Sub Class_Globals
	Public bw As X2BodyWrapper
	Private x2 As X2Utils 'ignore
End Sub

Public Sub Initialize (wrapper As X2BodyWrapper)
	bw = wrapper
	x2 = bw.X2
	bw.SwitchFrameIntervalMs = 50
End Sub

Public Sub Tick (GS As X2GameStep)
	If x2.mGame.GameOverState = False Then
		Dim jump As Boolean
		Dim Multitouch As X2MultiTouch = x2.mGame.Multitouch
		#if B4J
		If Multitouch.Keys.Contains("Space") Then
			jump = True
			Multitouch.Keys.Clear 'don't handle it more than once
		End If
		#Else If B4A or B4i
			Dim touch As X2Touch = Multitouch.GetSingleTouch(x2.mGame.Panel1)
			If touch.IsInitialized And touch.Handled = False Then
				jump = True
				touch.Handled = True
			End If
		#End If
		If jump = True Then
			bw.Body.ApplyLinearImpulse(x2.CreateVec2(0, 2.5), bw.Body.Position)
			x2.SoundPool.PlaySound("wing")
		End If
		Dim PipePositions As List = x2.mGame.PipePositions
		If PipePositions.Size > 0 Then
			Dim position As Float = PipePositions.Get(0)
			If bw.Body.Position.X > position Then
				PipePositions.RemoveAt(0)
				x2.mGame.lblScore.Text = NumberFormat(x2.mGame.lblScore.Text + 1, 0, 0)
				x2.SoundPool.PlaySound("hit")
			End If
		End If
	End If
	bw.Body.LinearVelocity = x2.CreateVec2(x2.mGame.BirdXVelocity, Min(4, bw.Body.LinearVelocity.Y))
	bw.Body.SetTransform(bw.Body.Position, ATan2(bw.Body.LinearVelocity.y, bw.Body.LinearVelocity.X))
	If GS.ShouldDraw Then
		bw.UpdateGraphic(GS, True)
	End If
End Sub