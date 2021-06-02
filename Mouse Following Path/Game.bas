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
	Private ivBackground As B4XView
	Public lblStats As B4XView
	Public TileMap As X2TileMap
	Public Const ObjectLayer As String = "Object Layer 1"
	Private Mouse As X2BodyWrapper
	Private pnlTouch As B4XView
	Private PathMainBCForward As BCPath
	Private PathMainBCBackwards As BCPath
	Private PathWorld As List
	Private BrushForward As BCBrush
	Private BrushBackwards As BCBrush
	Private MouseMotor As B2MotorJoint
	Private Border As X2BodyWrapper
	Private Enemy As X2BodyWrapper
	Private Multitouch As X2MultiTouch
End Sub

Public Sub Initialize (Parent As B4XView)
	Parent.LoadLayout("GameLayout")
	world.Initialize("world", world.CreateVec2(0, 0))
	X2.Initialize(Me, ivForeground, world)
	Dim WorldWidth As Float = 6 'meters
	Dim WorldHeight As Float = WorldWidth / 1.333 'same ratio as in the designer script
	X2.ConfigureDimensions(world.CreateVec2(WorldWidth / 2, WorldHeight / 2), WorldWidth)
	'Load the graphics and add them to the cache.
	'comment to disable debug drawing
	X2.EnableDebugDraw
	CreateStaticBackground
	'Passing Null for the target view parameter because we are not creating the background with a tile layer.
	TileMap.Initialize(X2, File.DirAssets, "mouse.json", Null) 
	TileMap.SetSingleTileDimensionsInMeters(WorldWidth / TileMap.TilesPerRow, WorldHeight / TileMap.TilesPerColumn)
	TileMap.PrepareObjectsDef(ObjectLayer)
	'create the ground
	Border = TileMap.CreateObject2ByName(ObjectLayer, "border")
	Mouse = TileMap.CreateObject2ByName(ObjectLayer, "mouse")
	'We want to switch the frames between frames 6 to 8.
	Mouse.MinFrame = 6
	Mouse.CurrentFrame = Mouse.MinFrame
	Mouse.NumberOfFrames = 9 'last frame index + 1
	Enemy = TileMap.CreateObject2ByName(ObjectLayer, "enemy")
	Enemy.MinFrame = 6
	Enemy.CurrentFrame = Mouse.MinFrame
	Enemy.NumberOfFrames = 9 'last frame index + 1
	PathMainBCForward.Initialize(0, 0)
 	PathMainBCBackwards.Initialize(0, 0)
	PathWorld.Initialize
	BrushForward = X2.MainBC.CreateBrushFromBitmap(xui.LoadBitmap(File.DirAssets, "dirt.png"))
	BrushBackwards = X2.MainBC.CreateBrushFromColor(xui.Color_Red)
	'mouse graphics: Created by Tuomo Untinen (Reemax) & Jordan Irwin (AntumDeluge)
	Dim MotorDef As B2MotorJointDef
	MotorDef.Initialize(Border.Body, Mouse.Body)
	MotorDef.MaxMotorTorque = 1
	MotorDef.MaxMotorForce = 1
	MotorDef.CollideConnected = True 'let the mouse collide with the borders
	MouseMotor = X2.mWorld.CreateJoint(MotorDef)
	MouseMotor.CorrectionFactor = 0.1
	Multitouch.Initialize(B4XPages.MainPage, Array(pnlTouch))
End Sub


Private Sub CreateStaticBackground
	Dim bc As BitmapCreator
	bc.Initialize(ivBackground.Width / xui.Scale / 2, ivBackground.Height / xui.Scale / 2)
	bc.FillGradient(Array As Int(0xFF006EFF, 0xFF00DAAD), bc.TargetRect, "TOP_BOTTOM")
	X2.SetBitmapWithFitOrFill(ivBackground, bc.Bitmap)
End Sub

Sub HandleTouch
	Dim touch As X2Touch = Multitouch.GetSingleTouch(pnlTouch)
	If touch.IsInitialized = False Then Return
	Dim WorldPoint As B2Vec2 = X2.ScreenPointToWorld(touch.X, touch.Y)
	Dim MainBCPoint As B2Vec2 = X2.WorldPointToMainBC(WorldPoint.X, WorldPoint.Y)
	If touch.EventCounter = 0 Then
		Dim FirstPointBC As B2Vec2 = X2.WorldPointToMainBC(Mouse.Body.Position.X, Mouse.Body.Position.Y)
		'Clone the paths before modifying them.
		PathMainBCForward = PathMainBCForward.Clone
		PathMainBCForward.Reset(FirstPointBC.X, FirstPointBC.Y)
		PathMainBCBackwards = PathMainBCBackwards.Clone
		PathMainBCBackwards.Reset(FirstPointBC.X, FirstPointBC.Y)
		PathWorld.Clear
	End If
	If PathWorld.Size > 0 Then
		Dim PrevPoint As B2Vec2 = PathWorld.Get(PathWorld.Size - 1)
		Dim distance As B2Vec2 = PrevPoint.CreateCopy
		distance.SubtractFromThis(WorldPoint)
		'to improve performance we skip very close points.
		If distance.LengthSquared < 0.1 Then
			Return
		End If
	End If
	PathMainBCForward = PathMainBCForward.Clone
	PathMainBCForward.LineTo(MainBCPoint.X, MainBCPoint.Y)
	PathWorld.Add(WorldPoint)
End Sub

Sub MoveMouse (gs As X2GameStep)
	'This loop might be a bit confusing. The loop ends after the first far enough point.
	Do While PathWorld.Size > 0
		Dim NextPoint As B2Vec2 = PathWorld.Get(0)
		Dim CurrentPoint As B2Vec2 = Mouse.Body.Position
		Dim distance As B2Vec2 = NextPoint.CreateCopy
		distance.SubtractFromThis(CurrentPoint)
		If (distance.Length < 0.3 And PathWorld.Size > 1) Or (distance.Length < 0.1) Then
			PathWorld.RemoveAt(0)
			Dim v As B2Vec2 = X2.WorldPointToMainBC(NextPoint.X, NextPoint.Y)
			'clone the paths before modifying them as they are being drawn asynchronously.
			PathMainBCForward = PathMainBCForward.Clone
			PathMainBCBackwards = PathMainBCBackwards.Clone
			'remove the first point from the "forward" path and add it to the "backwards" path.
			PathMainBCForward.Points.RemoveAt(0)
			PathMainBCForward.Invalidate 'need to call Invalidate after we directly access the points list.
			PathMainBCBackwards.LineTo(v.X, v.Y)
			Continue 'skip to the next point
		End If
		MouseMotor.AngularOffset = FindAngleToTarget(Mouse.Body, NextPoint)
		Dim delta As B2Vec2 = NextPoint.CreateCopy
		delta.SubtractFromThis(Border.Body.Position)
		MouseMotor.LinearOffset = delta
		'draw the small red circle
		v = X2.WorldPointToMainBC(NextPoint.X, NextPoint.Y)
		gs.DrawingTasks.Add(X2.MainBC.AsyncDrawCircle(v.X, v.Y, 5, BrushBackwards, True, 0))
		Exit '<-----
	Loop
End Sub

Sub FindAngleToTarget(Body As B2Body, Target As B2Vec2) As Float
	If Abs(Body.Angle) > 2 * cPI Then
		'make sure that the current angle is between -2*cPI to 2*cPI
		Body.SetTransform(Body.Position, X2.ModFloat(Body.Angle, 2 * cPI))
	End If
	Dim angle As Float = ATan2(Target.Y - Body.Position.Y, Target.X - Body.Position.X) + cPI / 2
	Dim CurrentAngle As Float = Body.Angle
	'find the shortest direction
	Dim anglediff As Float = angle - CurrentAngle
	If anglediff > cPI Then
		angle = -(2 * cPI - angle)
	Else If anglediff < -cPI Then
		angle = angle + 2 * cPI
	End If
	Return angle
End Sub

Public Sub Resize
	X2.ImageViewResized
End Sub

Public Sub Tick (GS As X2GameStep)
	HandleTouch
	If GS.ShouldDraw Then
		Dim width As Float = X2.MetersToBCPixels(0.2)
		GS.DrawingTasks.Add(X2.MainBC.AsyncDrawPath(PathMainBCForward, BrushForward, False, width))
		GS.DrawingTasks.Add(X2.MainBC.AsyncDrawPath(PathMainBCBackwards, BrushBackwards, False, width))
	End If
	MoveMouse (GS)
	MoveEnemy
	If Mouse.Body.LinearVelocity.LengthSquared > 0.1 Then Mouse.SwitchFrameIntervalMs = 100 Else Mouse.SwitchFrameIntervalMs = 0
	If Enemy.Body.LinearVelocity.LengthSquared > 0.1 Then Enemy.SwitchFrameIntervalMs = 100 Else Enemy.SwitchFrameIntervalMs = 0
End Sub

Private Sub MoveEnemy
	Dim v As B2Vec2 = Mouse.Body.Position.CreateCopy
	v.SubtractFromThis(Enemy.Body.Position)
	If v.Length > 0.7 Then
		v.NormalizeThis
		Enemy.Body.LinearVelocity = v
		Enemy.Body.SetTransform(Enemy.Body.Position, ATan2(v.Y, v.X) + cPI / 2)
	Else
		Enemy.Body.LinearVelocity = X2.CreateVec2(0, 0)
	End If
	
End Sub


Public Sub DrawingComplete
	
End Sub

'Return True to stop the game loop
Public Sub BeforeTimeStep (GS As X2GameStep) As Boolean
	Return False
End Sub


#If B4J
Private Sub Panel_Touch (Action As Int, X As Float, Y As Float)
	Multitouch.B4JDelegateTouchEvent(Sender, Action, X, Y)
End Sub
#Else If B4i
Private Sub Panel_Multitouch (Stage As Int, Data As Object)
	Multitouch.B4iDelegateMultitouchEvent(Sender, Stage, Data)
End Sub
#End If