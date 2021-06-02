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
	Private marbles As List
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
	X2.GraphicCache.PutGraphic2("rope", Array(X2.LoadBmp(File.DirAssets, "rope-34141_1280.png", 0.1, 1.5, False)), True, 3)
	'Passing Null for the target view parameter because we are not creating the background with a tile layer.
	TileMap.Initialize(X2, File.DirAssets, "newton.json", Null) 
	TileMap.SetSingleTileDimensionsInMeters(WorldWidth / TileMap.TilesPerRow, WorldHeight / TileMap.TilesPerColumn)
	TileMap.PrepareObjectsDef(ObjectLayer)
	Dim ol As X2ObjectsLayer = TileMap.Layers.Get(ObjectLayer)	
	For Each template As X2TileObjectTemplate In ol.ObjectsById.Values
		If template.Name <> "hinge" Then
			TileMap.CreateObject(template)
		End If
	Next
	marbles.Initialize
	Dim top As X2BodyWrapper = X2.GetBodyWrapperByName("top")
	For Each body As B2Body In world.AllBodies
		Dim bw As X2BodyWrapper = body.Tag
		If bw.Name = "marble" Then
			marbles.Add(bw)
			Dim hinge As X2TileObjectTemplate = TileMap.GetObjectTemplate(ObjectLayer, bw.Tag)
			bw.Tag = hinge 
			Dim rope As B2RopeJointDef
			Dim TopPosition As B2Vec2 = hinge.BodyDef.Position.CreateCopy
			TopPosition.SubtractFromThis(top.Body.Position)
			rope.Initialize(top.Body, bw.Body, TopPosition, X2.CreateVec2(0, 0), 1.5)
			world.CreateJoint(rope)
		End If
	Next
	
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
	For Each marble As X2BodyWrapper In marbles
		DrawRope(marble, GS)
	Next
End Sub

Private Sub DrawRope (marble As X2BodyWrapper, gs As X2GameStep)
	If gs.ShouldDraw Then
		Dim hinge As X2TileObjectTemplate = marble.Tag
		Dim vec As B2Vec2 = hinge.BodyDef.Position.CreateCopy
		vec.SubtractFromThis(marble.Body.Position)
		Dim Rope As CompressedBC = X2.GraphicCache.GetGraphic2("rope", 0, X2.B2AngleToDegrees(ATan2(vec.y, vec.x) + cPI / 2), False, False)
		vec.MultiplyThis(0.5)
		vec.AddToThis(marble.Body.Position)
		Dim dt As DrawTask = X2.CreateDrawTaskFromCompressedBC(Rope, X2.WorldPointToMainBC(vec.X, vec.Y), Rope.TargetRect)
		gs.DrawingTasks.Add(dt)
	End If
End Sub

Public Sub DrawingComplete
	
End Sub

'Return True to stop the game loop
Public Sub BeforeTimeStep (GS As X2GameStep) As Boolean
	Return False
End Sub
