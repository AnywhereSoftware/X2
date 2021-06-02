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
	Private Pendulum, PendulumPivot As X2BodyWrapper
End Sub

Public Sub Initialize (Parent As B4XView)
	Parent.LoadLayout("GameLayout")
	world.Initialize("world", world.CreateVec2(0, -10))
	X2.Initialize(Me, ivForeground, world)
	Dim WorldWidth As Float = 6 'meters
	Dim WorldHeight As Float = WorldWidth / 1.333 'same ratio as in the designer script
	X2.ConfigureDimensions(world.CreateVec2(WorldWidth / 2, WorldHeight / 2), WorldWidth)
	'Load the graphics and add them to the cache.
	'comment to disable debug drawing
	'X2.EnableDebugDraw
	CreateStaticBackground
	TileMap.Initialize(X2, File.DirAssets, "hello world.json", Null)
	TileMap.SetSingleTileDimensionsInMeters(WorldWidth / TileMap.TilesPerRow, WorldHeight / TileMap.TilesPerColumn)
	TileMap.PrepareObjectsDef(ObjectLayer)
	'multicolors_s source: https://opengameart.org/content/multicolor-brick-wall-seamless-texture-with-normalmap
	CreateChain
	X2.GraphicCache.PutGraphic2("rope", Array(X2.LoadBmp(File.DirAssets, "rope-34141_1280.png", 0.1, 1, True)), True, 5)
	'The rope can rotate fast so it is better to build the cache before we start.
	X2.GraphicCache.WarmGraphic("rope")
End Sub

Private Sub CreateChain
	Dim ol As X2ObjectsLayer = TileMap.Layers.Get(ObjectLayer)
	'create the elements
	For Each template As X2TileObjectTemplate In ol.ObjectsById.Values
		If template.Name.Contains("hinge") = False Then
			TileMap.CreateObject(template)
		End If
	Next
	
	'create the joints
	For Each template As X2TileObjectTemplate In ol.ObjectsById.Values
		If template.Name.Contains("hinge") Then
			'split the string (and remove spaces near the commas)
			'Tag looks like this: weld, chain 6, fence 6
			Dim s() As String = Regex.Split("\s*,\s*", template.Tag)
			Dim JointType As String = s(0)
			Dim BodyA As X2BodyWrapper = X2.GetBodyWrapperByName(s(1))
			Dim BodyB As X2BodyWrapper = X2.GetBodyWrapperByName(s(2))
			Dim position As B2Vec2 = template.BodyDef.Position
			Select JointType
				Case "revolute"
					Dim revdef As B2RevoluteJointDef
					revdef.Initialize(BodyA.Body, BodyB.Body, position)
					world.CreateJoint(revdef)
				Case "weld"
					Dim welddef As B2WeldJointDef
					welddef.Initialize(BodyA.Body, BodyB.Body, position)
					world.CreateJoint(welddef)
				Case "rope"
					Dim ropedef As B2RopeJointDef
					'position is not used in this case
					ropedef.Initialize(BodyA.Body, BodyB.Body, X2.CreateVec2(0, 0), X2.CreateVec2(0, 0), 1)
					world.CreateJoint(ropedef)
			End Select
		End If
	Next
	Pendulum = X2.GetBodyWrapperByName("pendulum")
	PendulumPivot = X2.GetBodyWrapperByName("pendulum pivot")
End Sub

Private Sub CreateStaticBackground
	Dim bc As BitmapCreator
	bc.Initialize(ivBackground.Width / xui.Scale / 2, ivBackground.Height / xui.Scale / 2)
	bc.FillGradient(Array As Int(0xFF006EFF, 0xFF00DAAD), bc.TargetRect, "TOP_BOTTOM")
	X2.SetBitmapWithFitOrFill(ivBackground, bc.Bitmap)
End Sub

Public Sub Resize
	X2.ImageViewResized
End Sub

Public Sub Tick (GS As X2GameStep)
	If X2.RndFloat(0, 1000) < X2.TimeStepMs Then CreateDonut
	If X2.RndFloat(0, 1000) < X2.TimeStepMs Then CreateFastDonut
	DrawRope(GS)
End Sub

Private Sub CreateDonut
	Dim template As X2TileObjectTemplate = TileMap.GetObjectTemplateByName(ObjectLayer, "donut")
	template.BodyDef.Position.X = X2.RndFloat(1, 5)
	TileMap.CreateObject(template)
End Sub

Private Sub CreateFastDonut
	Dim template As X2TileObjectTemplate = TileMap.GetObjectTemplateByName(ObjectLayer, "donut 2")
	template.BodyDef.LinearVelocity = X2.CreateVec2(X2.RndFloat(-3, 3), 9)
	template.BodyDef.Position.X = X2.RndFloat(1, 5)
	template.BodyDef.Bullet = True
	TileMap.CreateObject(template)
End Sub

Private Sub DrawRope (gs As X2GameStep)
	If gs.ShouldDraw Then
		'step #1: find the rope length and angle and get the rotated graphic
		Dim vec As B2Vec2 = PendulumPivot.Body.Position.CreateCopy
		vec.SubtractFromThis(Pendulum.Body.Position)
		Dim Rope As CompressedBC = X2.GraphicCache.GetGraphic2("rope", 0, X2.B2AngleToDegrees(ATan2(vec.y, vec.x) + cPI / 2), False, False)
		'step #2: crop the image based on the full rope length and the current length
		Dim RopeRatio As Float = Min(1, Max(0.1, vec.Length / X2.GraphicCache.GetGraphicSizeMeters("rope", 0).Y))
		Dim Rect As B4XRect
		Dim width As Int = Rope.TargetRect.Width * RopeRatio
		Dim height As Int = Rope.TargetRect.Height * RopeRatio
		Rect.Initialize(Rope.TargetRect.CenterX - width / 2, Rope.TargetRect.CenterY - height / 2, 0, 0)
		Rect.Width = width
		Rect.Height = height
		'step #3: find the rope center
		vec.MultiplyThis(0.5)
		Dim vec2 As B2Vec2 = Pendulum.Body.Position.CreateCopy
		vec2.AddToThis(vec)
		'step #4: create the drawing task
		Dim dt As DrawTask = X2.CreateDrawTaskFromCompressedBC(Rope, X2.WorldPointToMainBC(vec2.X, vec2.Y), Rect)
		gs.DrawingTasks.Add(dt)
	End If
	
End Sub


Public Sub DrawingComplete
	
End Sub

'Return True to stop the game loop
Public Sub BeforeTimeStep (GS As X2GameStep) As Boolean
	Return False
End Sub
