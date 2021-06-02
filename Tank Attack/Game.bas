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
	Public Ground As X2BodyWrapper
	Private ivForeground As B4XView
	Private ivBackground As B4XView
	Public lblStats As B4XView
	Public TileMap As X2TileMap
	Public Const ObjectLayer As String = "Object Layer 1"

	Private Tank As X2BodyWrapper
	Private Kane As X2BodyWrapper
	Private revjoint As B2RevoluteJoint
	Private TankMovementForce As B2Vec2
	Private LastFireTime As Int
	Public Multitouch As X2MultiTouch
	Private Panel1 As B4XView
End Sub

Public Sub Initialize (Parent As B4XView)
	Parent.LoadLayout("1")
	world.Initialize("world", world.CreateVec2(0, -20))
	X2.Initialize(Me, ivForeground, world)
	Dim WorldHeight As Float = 14 'the size of each tile will be approximately 1x1 meter
	Dim WorldWidth As Float = WorldHeight * 1.3333
	X2.ConfigureDimensions(world.CreateVec2(WorldWidth / 2, WorldHeight / 2), WorldWidth)
	lblStats.TextColor = xui.Color_Black
	lblStats.Color = 0x88ffffff
	lblStats.Font = xui.CreateDefaultBoldFont(20)
	'comment to disable debug drawing
	'X2.EnableDebugDraw
	TileMap.Initialize(X2, File.DirAssets, "tank.json", Null)
	TileMap.SetSingleTileDimensionsInMeters(WorldWidth / TileMap.TilesPerRow, WorldHeight / TileMap.TilesPerColumn)
	TileMap.PrepareObjectsDef(ObjectLayer)
	Dim ol As X2ObjectsLayer = TileMap.Layers.Get(ObjectLayer)
	For Each template As X2TileObjectTemplate In ol.ObjectsById.Values
		If template.Name <> "hinge" And template.Name <> "bullet" Then 
			Dim bw As X2BodyWrapper = TileMap.CreateObject(template)
			If bw.Name = "tank" Then 
				Tank = bw
			Else If bw.Name = "kane" Then
				Kane = bw				
			End If
		End If
	Next
	CreateRevJoint
	X2.SetBitmapWithFitOrFill(ivBackground, xui.LoadBitmapResize(File.DirAssets, "sky.jpg", ivBackground.Width / 2, ivBackground.Height / 2, False))
	TankMovementForce = X2.CreateVec2(0.05 * X2.TimeStepMs, 0)
	Multitouch.Initialize(B4XPages.MainPage, Array(Panel1))
End Sub

Private Sub CreateRevJoint
	Dim template As X2TileObjectTemplate = TileMap.GetObjectTemplateByName(ObjectLayer, "hinge")
	Dim revdef As B2RevoluteJointDef
	revdef.Initialize(Tank.Body, Kane.Body, template.BodyDef.Position)
	revdef.SetLimits(0, cPI / 2)
	revdef.LimitEnabled = True
	revdef.MaxMotorTorque = 10
	revjoint = world.CreateJoint(revdef)
	revjoint.MotorEnabled = True
	Kane.Body.GravityScale = 0
End Sub


Public Sub Tick (GS As X2GameStep)
	Dim RightDown, LeftDown, FireDown, DownDown, UpDown As Boolean 'ignore
	#if B4J
	RightDown = Multitouch.Keys.Contains("Right")
	LeftDown = Multitouch.Keys.Contains("Left")
	FireDown = Multitouch.Keys.Contains("Space")
	DownDown = Multitouch.Keys.Contains("Down")
	UpDown = Multitouch.Keys.Contains("Up")
	#Else
	For Each touch As X2Touch In Multitouch.GetTouches(Panel1)
		If touch.X > Panel1.Width * 0.8 Then RightDown = True
		If touch.X < Panel1.Width * 0.2 Then LeftDown = True		
		If touch.Y > Panel1.Height * 0.8 Then DownDown = True		
		If touch.Y < Panel1.Height * 0.2 Then UpDown = True		
	Next
	#End If
	If UpDown Then
		revjoint.MotorSpeed = 1
	Else If DownDown Then
		revjoint.MotorEnabled = True
		revjoint.MotorSpeed = -1
	Else
		revjoint.MotorSpeed = 0
		Kane.Body.AngularVelocity = 0
	End If
	If RightDown Then
		Tank.Body.ApplyLinearImpulse(TankMovementForce, Tank.Body.Position)
		Tank.SwitchFrameIntervalMs = 100
	Else If LeftDown Then
		Tank.Body.ApplyLinearImpulse(TankMovementForce.Negate, Tank.Body.Position)
		Tank.SwitchFrameIntervalMs = 100
	Else
		Tank.SwitchFrameIntervalMs = 0
	End If
	If (xui.IsB4J = False Or FireDown) And LastFireTime < GS.GameTimeMs - 500 Then
		LastFireTime = GS.GameTimeMs
		Fire
	End If
End Sub

Private Sub Fire
	Dim template As X2TileObjectTemplate = TileMap.GetObjectTemplateByName(ObjectLayer, "bullet")
	template.BodyDef.Position = Kane.Body.Position
	'set the velocity direction based on the cannon direction.
	template.BodyDef.LinearVelocity = Kane.Body.Transform.MultiplyRot(X2.CreateVec2(30, 0))
	'better simulation of fast moving objects
	template.BodyDef.Bullet = True
	TileMap.CreateObject(template)
End Sub


Public Sub Resize
	X2.ImageViewResized
End Sub

Public Sub DrawingComplete
End Sub

'Return True to stop the game loop
Public Sub BeforeTimeStep (GS As X2GameStep) As Boolean
	Return False
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
