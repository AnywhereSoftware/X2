B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=6.3
@EndOfDesignText@
Sub Class_Globals
	Public bw As X2BodyWrapper
	Public Size As B2Vec2
	Private Const MIN_DISTANCE_TO_SIDES As Float = 1.5
	Private LastStepTime As Int
	Private xui As XUI
	Public InAir As Boolean
End Sub

Public Sub Initialize (wrapper As X2BodyWrapper)
	bw = wrapper
	Size = bw.mGame.World.CreateVec2(0.65, 1.60)
	bw.SwitchFrameIntervalMs = 50
	'draw the kid after all other elements so it won't be hidden.
	bw.DrawLast = True 
	bw.DelegateTo = Me
	
End Sub

Public Sub Tick (GS As X2GameStep)
	'The kid tick event should run before all other bodies events because it updates the screen AABB.
	'It is therefore called from Game.Tick. The following check prevents it from running twice.
	If LastStepTime = GS.GameTimeMs Then Return
	LastStepTime = GS.GameTimeMs
	'draw the InAir state.
	If InAir Then bw.DebugDrawColor = xui.Color_White Else bw.DebugDrawColor = xui.Color_Black
	Dim IncreaseFrame As Boolean
	If InAir = False And bw.mGame.Jump Then
		Dim v As B2Vec2 = bw.Body.LinearVelocity.CreateCopy
		v.Y = 6
		bw.Body.LinearVelocity = v
		bw.CurrentFrame = 0
	End If
	Dim right As Boolean = bw.mGame.RightDown
	Dim left As Boolean = bw.mGame.LeftDown
	If right And left Then
		right = bw.FlipHorizontal = False
	End If
	Dim vx As Float
	If right Then
		vx = 3
		bw.FlipHorizontal = False
		IncreaseFrame = InAir = False
	Else If left Then
		vx = -3
		IncreaseFrame = InAir = False
		bw.FlipHorizontal = True
	Else if InAir = False Then
		vx = 0
	End If
	bw.Body.LinearVelocity = bw.X2.CreateVec2(vx, bw.Body.LinearVelocity.Y)
	'Check whether the kid is near one of the edges.
	Dim WorldFix As Float
	If bw.X2.ScreenAABB.TopRight.X - bw.Body.WorldCenter.X < MIN_DISTANCE_TO_SIDES Then
		WorldFix = MIN_DISTANCE_TO_SIDES - (bw.X2.ScreenAABB.TopRight.X - bw.Body.WorldCenter.X)
	Else If bw.Body.WorldCenter.X -  bw.X2.ScreenAABB.BottomLeft.X < MIN_DISTANCE_TO_SIDES Then
		WorldFix = -(MIN_DISTANCE_TO_SIDES - (bw.Body.WorldCenter.X - bw.X2.ScreenAABB.BottomLeft.X))
	End If
	
	If WorldFix <> 0 Then
		'update the screen center
		Dim center As B2Vec2 = bw.X2.ScreenAABB.Center
		center.X = center.X + WorldFix
		bw.X2.UpdateWorldCenter(center)
		bw.mGame.WorldCenterUpdated (WorldFix)
	End If
	bw.UpdateGraphic (bw.X2.gs, IncreaseFrame)
	
End Sub

Public Sub Collision_WithBird (ft As X2FutureTask)
	Dim bird As X2BodyWrapper = ft.Value
	If bird.IsDeleted Then Return
	bird.Delete(bw.X2.gs)
	Dim template As X2TileObjectTemplate = bw.X2.mGame.TileMap.GetObjectTemplate(bw.X2.mGame.ObjectLayerName, 40)
	Dim bd As B2BodyDef = template.BodyDef
	bd.BodyType = bd.TYPE_KINEMATIC
	bd.Position = bird.Body.Position.CreateCopy
	bd.AngularVelocity = bw.X2.RndFloat(-8, 8)
	bd.LinearVelocity = bw.Body.LinearVelocity.CreateCopy
	bd.LinearVelocity.MultiplyThis(1.2)
	bw.X2.mGame.TileMap.CreateObject(template)
End Sub

Public Sub Collision_WithCoin (ft As X2FutureTask)
	Log("collision with coin")
	Dim coin As X2BodyWrapper = ft.Value
	If coin.IsDeleted Then Return
	'The moving scores are not physical bodies. Their movement is managed in the MovingScore class.
	'They don't have a shape.
	bw.X2.SoundPool.PlaySound("coin")
	Dim score As Int = Rnd(5, 11) * 10
	Dim TimeToLive As Int = 2000
	bw.X2.AddFutureTask(Me, "Add_Score",TimeToLive, score) 'add the score when the moving score reaches the corner
	Dim bd As B2BodyDef
	bd.BodyType = bd.TYPE_STATIC
	bd.Position = coin.Body.Position
	coin.Delete(bw.X2.gs)
	Dim mscore As MovingScore
	Dim wrapper As X2BodyWrapper = bw.X2.CreateBodyAndWrapper(bd, mscore, "score")
	mscore.Initialize(wrapper, score)
	wrapper.TimeToLiveMs = TimeToLive 
	'uncomment to add a slow down effect
'	bw.X2.SlowDownPhysicsScale = 2
'	bw.X2.UpdateTimeParameters
'	bw.X2.AddFutureTask(Me, "Reset_PhysicsScore", 500, Null)
End Sub

Private Sub Add_Score (ft As X2FutureTask)
	bw.mGame.mScore.IncreaseScore(ft.Value)
End Sub

Private Sub Reset_PhysicsScore (ft As X2FutureTask)
	bw.X2.SlowDownPhysicsScale = 1
	bw.X2.UpdateTimeParameters
End Sub


