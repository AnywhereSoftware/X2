B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=6.3
@EndOfDesignText@
Sub Class_Globals
	Private bw As X2BodyWrapper
	Private TailHeightMeters As Float
	Private TailCBC As CompressedBC
	Private mMotor As B2MotorJoint
	Private mTail As X2BodyWrapper
	Private X2 As X2Utils
End Sub

Public Sub Initialize (wrapper As X2BodyWrapper, TailBodyWrapper As X2BodyWrapper, Motor As B2MotorJoint)
	bw = wrapper
	bw.DelegateTo = Me
	X2 = bw.X2
	mTail = TailBodyWrapper
	TailCBC = X2.GraphicCache.GetGraphic(mTail.GraphicName, 0)
	TailHeightMeters = X2.GetShapeWidthAndHeight(mTail.Body.FirstFixture.Shape).Y
	mMotor = Motor
	mTail.GraphicName = "" 'we will manually draw the smoke trail.
End Sub

Public Sub Tick (GS As X2GameStep)
	If bw.IsVisible = False Then
		bw.Delete(GS)
		Return
	End If
	If bw.IsDeleted Or mTail.IsDeleted Then Return
	Dim DistanceToTarget As B2Vec2 = mMotor.BodyB.Position.CreateCopy
	DistanceToTarget.SubtractFromThis(mMotor.BodyA.Position)
	DistanceToTarget.SubtractFromThis(mMotor.LinearOffset)
	If DistanceToTarget.LengthSquared < 0.1 Then
		bw.Delete(GS)
		mTail.Delete(GS)
		'create explosion
		bw.X2.SoundPool.PlaySound("fireworks")
		Dim bd As B2BodyDef
		bd.BodyType = bd.TYPE_DYNAMIC
		bd.Position = bw.Body.Position
		bd.GravityScale = 0.2
		Dim gname As String = "Fireworks Explosion"
		Dim shape As B2CircleShape
		shape.Initialize(bw.X2.GraphicCache.GetGraphicSizeMeters(gname, 0).X / 2)
		For i = 1 To 30
			Dim angle As Float = bw.X2.RndFloat(0, cPI * 2)
			Dim speed As Float = bw.X2.RndFloat(1, 3)
			bd.LinearVelocity.X = speed * Sin(angle)
			bd.LinearVelocity.Y = speed * Cos(angle)
			
			Dim wrapper As X2BodyWrapper = bw.X2.CreateBodyAndWrapper(bd, Null, "explosion")
			wrapper.GraphicName = gname
			wrapper.SwitchFrameIntervalMs = 100
			Dim f As B2Fixture = wrapper.Body.CreateFixture2(shape, 1)
			'collide with other objects excluding other objects of same type.
			f.SetFilterBits(bw.mGame.ExplosionCategory, Bit.And(0xffff, Bit.Not(bw.mGame.ExplosionCategory)))
			wrapper.TimeToLiveMs = 1000
		Next
	Else
		If GS.ShouldDraw Then
			bw.UpdateGraphic(GS, True)
			Dim TailTop As Float = mTail.Body.Position.Y + TailHeightMeters / 2
			Dim GroundY As Float = mMotor.BodyA.Position.Y
			'we only draw the part of the tail that is above the ground. The rectangle starts from the bottom of the image and grows up.
			Dim rect As B4XRect
			rect.Initialize(0, TailCBC.mHeight - X2.MetersToBCPixels(TailTop - GroundY), TailCBC.mWidth, TailCBC.mHeight)
			Dim dt As DrawTask = X2.CreateDrawTaskFromCompressedBC(TailCBC, X2.WorldPointToMainBC(mTail.Body.Position.X, (GroundY + TailTop) / 2), rect)
			GS.DrawingTasks.Add(dt)
		End If
	End If
	
End Sub