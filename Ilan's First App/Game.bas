B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=6.47
@EndOfDesignText@
#if B4A
'ignore DIP related warnings as they are not relevant when working with BitmapCreator.
#IgnoreWarnings: 6
#end if
Sub Class_Globals
	Public X2 As X2Utils
	Private xui As XUI 'ignore
	Public world As B2World
	Private ivForeground As B4XView
 	Public TileMap As X2TileMap
	Public Const ObjectLayer As String = "Object Layer 1"
	Public RightDown, LeftDown, FireDown As Boolean
	Private Const ConfigFile As String = "config.txt" 'ignore 
	Private PanelForTouch As B4XView
	Private states As Label
	Type SwitchData (State As Boolean, DoorIds() As String)
	Type BallData (Force As B2Vec2, IsTouched As Boolean)
	Type GroundData (Motor As B2MotorJoint, OpenAngle As Float, CloseAngle As Float)
	Public lblStats As B4XView 'not used
	Private Multitouch As X2MultiTouch
End Sub


Public Sub Initialize (Parent As B4XView)
	Parent.LoadLayout("1")
	world.Initialize("world", world.CreateVec2(0, -9.8)) 'no gravity
	X2.Initialize(Me, ivForeground, world)
	X2.GraphicCache.MAX_SIZE_FOR_ANTIALIAS = 800
	Dim WorldHeight As Float = 6 
	Dim WorldWidth As Float = WorldHeight * 1.3333
	X2.ConfigureDimensions(world.CreateVec2(WorldWidth / 2, WorldHeight / 2), WorldWidth)
 	X2.GraphicCache.PutGraphic("bg", Array(X2.LoadBmp(File.DirAssets, "bg.png", WorldWidth, WorldHeight, False)))
	Multitouch.Initialize(B4XPages.MainPage, Array(PanelForTouch))
	'comment to disable debug drawing
	X2.EnableDebugDraw
End Sub

Public Sub StartGame
	If X2.IsRunning Then Return
	X2.Reset
  	Multitouch.ResetState
	X2.UpdateWorldCenter(X2.CreateVec2(X2.ScreenAABB.Width / 2, X2.ScreenAABB.Height / 2))
	TileMap.Initialize(X2, File.DirAssets, "map.json", Null)
	Dim TileSizeMeters As Float = X2.ScreenAABB.Height / TileMap.TilesPerColumn
	TileMap.SetSingleTileDimensionsInMeters(TileSizeMeters, TileSizeMeters)
	TileMap.PrepareObjectsDef(ObjectLayer)	
	loadGroundBodies 'create bodies
	X2.GraphicCache.WarmGraphic(X2.GetBodyWrapperByName("gear main").GraphicName)
	X2.Start
End Sub

Sub loadGroundBodies
	Dim ol As X2ObjectsLayer = TileMap.Layers.Get(ObjectLayer)
	For Each template As X2TileObjectTemplate In ol.ObjectsById.Values
		Select template.Name
			Case "switch"
				Dim bw As X2BodyWrapper = TileMap.CreateObject(template)
				Dim switch As SwitchData
				switch.Initialize
				switch.DoorIds = Regex.Split(",", bw.TemplateCustomProperties.Get("doorid"))
				bw.Tag = switch
			Case "bg"
				'put the "background body" exactly at the center.
				template.BodyDef.Position = X2.ScreenAABB.Center
				TileMap.CreateObject(template)
			Case "ball"
				
			Case Else 
				TileMap.CreateObject(template)	
		End Select
	Next
	Dim staticground As B2Body = X2.GetBodyWrapperById(79).Body
	'we want to create the joints after all bodies were created
	For Each body As B2Body In world.AllBodies
		Dim bw As X2BodyWrapper = body.Tag
		
		If bw.Name = "switch" Then
			Dim switch As SwitchData = bw.Tag
			For Each id As String In switch.DoorIds
				Dim ground As X2BodyWrapper = X2.GetBodyWrapperById(id)
				Dim def As B2RevoluteJointDef
				def.Initialize(staticground, ground.Body, ground.Body.Position)
				world.CreateJoint(def)
				Dim gd As GroundData
				gd.Initialize
				gd.OpenAngle = X2.DegreesToB2Angle(ground.TemplateCustomProperties.Get("openangle"))
				gd.CloseAngle = X2.DegreesToB2Angle(ground.TemplateCustomProperties.Get("closeangle"))
				Dim motordef As B2MotorJointDef
				motordef.Initialize(staticground, ground.Body)
				gd.Motor = world.CreateJoint(motordef)
				gd.Motor.MaxMotorTorque = 10
				gd.Motor.AngularOffset = gd.CloseAngle
				ground.Tag = gd				
			Next
		Else If bw.Name = "gear" Or bw.Name = "gear main" Then
			'the gears are kinematic types so we just need to set their angular velocity and they will not be affected by collisions.
			bw.Body.AngularVelocity = 2
		End If
	Next
End Sub


 
Public Sub Resize
	X2.ImageViewResized
End Sub

Public Sub Tick (GS As X2GameStep)	
	updateBallForce 'apply force if hit sensor
	HandleTouch
	writeStates
End Sub

Sub updateBallForce
	For Each bd As B2Body In world.AllBodies
		Dim bw As X2BodyWrapper = bd.Tag
		If bw.Name = "ball" Then
			Dim data As BallData = bw.Tag
			If data.IsTouched Then
				bd.ApplyForce(data.force,bd.WorldCenter)
			End If
		End If
	Next
End Sub
 
Public Sub DrawingComplete

End Sub

Sub writeStates
	states.Text = "Bodies in World: " & world.AllBodies.Size & "  FPS: " & NumberFormat2(X2.FPS,1,0,0,False)
End Sub
  
'This event fires while the world is locked.
'We need to use AddFutureTask to run code after the physics engine completed the time step.
Private Sub World_BeginContact (Contact As B2Contact)
	Dim bodies As X2BodiesFromContact = X2.GetBodiesFromContact(Contact,  "ball")
	If bodies <> Null Then
		Dim data As BallData = bodies.ThisBody.Tag
		
		If bodies.OtherBody.Name = "forceright" Then
			data.IsTouched = True
			data.Force.Set(0.1, 0)
		else if bodies.OtherBody.Name = "forceup" Then
			data.IsTouched = True
			data.Force.Set(0, 0.5)
		End If
	End If
End Sub
 
Private Sub World_EndContact(Contact As B2Contact)
	Dim bodies As X2BodiesFromContact = X2.GetBodiesFromContact(Contact,  "ball")
	If bodies <> Null Then
		Dim data As BallData = bodies.ThisBody.Tag
		If bodies.OtherBody.Name.StartsWith("force") Then
			data.IsTouched = False
			data.Force.Set(0, 0)
		End If
	End If
End Sub
 
Private Sub Delete_Enemy(ft As X2FutureTask)
	Dim enemy As X2BodyWrapper = ft.Value
	If enemy.IsDeleted Then Return
	enemy.Delete(X2.gs)
End Sub
 
'Return True to stop the game loop
Public Sub BeforeTimeStep (GS As X2GameStep) As Boolean
	Return False
End Sub

Public Sub StopGame
	X2.Stop
End Sub

Private Sub HandleTouch
	Dim touch As X2Touch = Multitouch.GetSingleTouch(PanelForTouch)
	If touch.IsInitialized = False Or touch.Handled Then Return
	touch.Handled = True
	Dim worldpoint As B2Vec2 = X2.ScreenPointToWorld(touch.X, touch.Y)
	For Each TouchedBody As X2BodyWrapper In X2.GetBodiesIntersectingWithWorldPoint(worldpoint)
		If TouchedBody.Tag Is SwitchData Then
			Log("YOU TOUCHED A SWITCH")
			Dim Sw As SwitchData = TouchedBody.Tag
			Sw.State = Not(Sw.State)
			If Sw.State Then
				TouchedBody.CurrentFrame = 1
			Else
				TouchedBody.CurrentFrame = 0
			End If
			For Each id As String In Sw.DoorIds
				Dim ground As X2BodyWrapper = X2.GetBodyWrapperById(id)
				Dim gd As GroundData = ground.Tag
				If Sw.State Then
					gd.Motor.AngularOffset = gd.OpenAngle
				Else
					gd.Motor.AngularOffset = gd.CloseAngle
				End If
			Next
			Return
		End If
	Next
	Dim template As X2TileObjectTemplate = TileMap.GetObjectTemplateByName(ObjectLayer, "ball")
	template.BodyDef.Position = worldpoint
	Dim ball As X2BodyWrapper = TileMap.CreateObject(template)
	ball.GraphicName = CreateCircleForBall(ball.Body.FirstFixture.Shape)
	Dim bd As BallData
	bd.Initialize
	ball.Tag = bd
End Sub
 
Private Sub PanelForTouch_Touch (Action As Int, X As Float, Y As Float)
	If Action = PanelForTouch.TOUCH_ACTION_DOWN Then
		
	End If
End Sub

'returns the graphic name
Private Sub CreateCircleForBall (Shape As B2Shape) As String
	Dim ballsize As B2Vec2 = X2.GetShapeWidthAndHeight(Shape)
	'we could have used B4XCanvas here instead of BitmapCreator.
	Dim bc As BitmapCreator
	bc.Initialize(X2.MetersToBCPixels(ballsize.X), X2.MetersToBCPixels(ballsize.Y))
	bc.DrawCircle(bc.TargetRect.CenterX, bc.TargetRect.CenterY, bc.mWidth / 2 - 1, Rnd(0xff000000, -1), True, 0)
	bc.DrawCircle(bc.TargetRect.CenterX, bc.TargetRect.CenterY, bc.mWidth / 2 - 1, xui.Color_Black, False, 2)
	Dim gname As String = X2.GraphicCache.GetTempName
	'the balls are simple circles so there is no reason to "rotate" them. Setting AngleInterval to 360 disables rotation.
	X2.GraphicCache.PutGraphicBCs(gname, Array(bc), True, 360)
	Return gname
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

