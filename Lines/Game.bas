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
	Private PanelForTouch As B4XView
	Private TouchPoints As List
	Private PrevPoint() As Int
	Private MovingBody As Boolean
	Private TouchedBody As B2Body
	Private DrawingBC As BitmapCreator
	Private ivDrawing As B4XView
	Private Multitouch As X2MultiTouch
End Sub

Public Sub Initialize (Parent As B4XView)
	Parent.LoadLayout("GameLayout")
	world.Initialize("world", world.CreateVec2(0, -10))
	X2.Initialize(Me, ivForeground, world)
	X2.GraphicCache.MAX_SIZE_FOR_ANTIALIAS = 500
	Dim WorldWidth As Float = 6 'meters
	Dim WorldHeight As Float = WorldWidth / 1.333 'same ratio as in the designer script
	X2.ConfigureDimensions(world.CreateVec2(WorldWidth / 2, WorldHeight / 2), WorldWidth)
	'Load the graphics and add them to the cache.
	'comment to disable debug drawing
'	X2.EnableDebugDraw
	
	CreateStaticBackground
	'Passing Null for the target view parameter because we are not creating the background with a tile layer.
	TileMap.Initialize(X2, File.DirAssets, "lines.json", Null)
	TileMap.SetSingleTileDimensionsInMeters(WorldWidth / TileMap.TilesPerRow, WorldHeight / TileMap.TilesPerColumn)
	TileMap.PrepareObjectsDef(ObjectLayer)
	'create the ground
	CreateBorder
	TouchPoints.Initialize
	CreateDrawingBC
	Multitouch.Initialize(B4XPages.MainPage, Array(PanelForTouch))
End Sub

Private Sub CreateBorder
	TileMap.CreateObject(TileMap.GetObjectTemplateByName(ObjectLayer, "border"))
End Sub

Private Sub CreateStaticBackground
	Dim bc As BitmapCreator
	bc.Initialize(ivBackground.Width / xui.Scale / 2, ivBackground.Height / xui.Scale / 2)
	bc.FillGradient(Array As Int(0xFF006EFF, 0xFF00DAAD), bc.TargetRect, "TOP_BOTTOM")
	X2.SetBitmapWithFitOrFill(ivBackground, bc.Bitmap)
End Sub

Private Sub CreateDrawingBC
	DrawingBC.Initialize(ivDrawing.Width / xui.Scale, ivDrawing.Height / xui.Scale)
	X2.SetBitmapWithFitOrFill(ivDrawing, DrawingBC.Bitmap)
End Sub

Public Sub Resize
	X2.ImageViewResized
	CreateDrawingBC
End Sub

Public Sub Tick (GS As X2GameStep)
	HandleTouch
End Sub


Public Sub DrawingComplete
	
End Sub

'Return True to stop the game loop
Public Sub BeforeTimeStep (GS As X2GameStep) As Boolean
	Return False
End Sub


Private Sub HandleTouch
	Dim touch As X2Touch = Multitouch.GetSingleTouch(PanelForTouch)
	If touch.IsInitialized = False Then Return
	Dim x As Int = touch.X
	Dim y As Int = touch.Y
	x = Max(0, Min(x, PanelForTouch.Width)) 
	y = Max(0, Min(y, PanelForTouch.Height))
	If touch.EventCounter = 0 Then
		'down
		Dim p As B2Vec2 = X2.ScreenPointToWorld(X, Y)
		Dim touched As List = X2.GetBodiesIntersectingWithWorldPoint(p)
		If touched.Size > 0 Then
			MovingBody = True
			Dim bw As X2BodyWrapper = touched.Get(0)
			TouchedBody = bw.Body
			TouchedBody.GravityScale = 0
			TouchedBody.SleepingAllowed = False
		Else
			MovingBody = False
			TouchPoints.Clear
			TouchPoints.Add(p)
			PrevPoint = Array As Int(X, Y)
		End If
	Else If touch.FingerUp Then
		'last
		If MovingBody = False Then
			CreatePattern
		Else
			TouchedBody.GravityScale = 1
			TouchedBody.SleepingAllowed = True
		End If
	Else
		Dim p As B2Vec2 = X2.ScreenPointToWorld(X, Y)
		If MovingBody Then
			TouchedBody.SetTransform(p, 0)
		Else
			DrawingBC.DrawLine(PrevPoint(0) / xui.Scale, PrevPoint(1) / xui.Scale, X / xui.Scale, Y / xui.Scale, xui.Color_Black, 10)
			X2.SetBitmapWithFitOrFill(ivDrawing, DrawingBC.Bitmap)
			PrevPoint = Array As Int(X, Y)
			TouchPoints.Add(p)
		End If
	End If
End Sub

Private Sub CreatePattern
	Dim def As B2BodyDef
	def.BodyType = def.TYPE_DYNAMIC
	
	'find the shape dimensions
	Dim aabb As B2AABB
	Dim prev As B2Vec2 = TouchPoints.Get(0)
	aabb.Initialize2(prev, prev)
	For i = 1 To TouchPoints.Size - 1
		Dim NewPoint As B2Vec2 = TouchPoints.Get(i)
		aabb.BottomLeft.Set(Min(aabb.BottomLeft.X, NewPoint.X), Min(aabb.BottomLeft.Y, NewPoint.Y))
		aabb.TopRight.Set(Max(aabb.TopRight.X, NewPoint.X), Max(aabb.TopRight.Y, NewPoint.Y))
	Next
	If aabb.Width > 0.1 And aabb.Height > 0.1 Then
		'set the body position based on the shape center
		def.Position = aabb.Center
		Dim bw As X2BodyWrapper = X2.CreateBodyAndWrapper(def, Null, "line")
		Dim prev As B2Vec2 = TouchPoints.Get(0)
		For i = 1 To TouchPoints.Size - 1
			Dim NewPoint As B2Vec2 = TouchPoints.Get(i)
			Dim diff As B2Vec2 = NewPoint.CreateCopy
			diff.SubtractFromThis(prev)
			diff.MultiplyThis(0.5)
			Dim len As Float = diff.Length
			If len < 0.1 And i < TouchPoints.Size - 1 Then Continue
			Dim rect As B2PolygonShape
			rect.Initialize
			Dim angle As Float = ATan2(diff.Y, diff.X)
			diff.AddToThis(prev)
			diff.SubtractFromThis(def.Position)
			rect.SetAsBox2(len, 0.05, diff, angle)
			Dim f As B2Fixture = bw.Body.CreateFixture2(rect, 1)
			f.Friction = 0.7
			prev = NewPoint
		Next
		Dim gname As String = X2.GraphicCache.GetTempName
		Dim Scale As Float = DrawingBC.TargetRect.Width / X2.ScreenAABB.Width
		'crop the image
		Dim cvsrect As B4XRect
		cvsrect.Initialize(aabb.BottomLeft.X * Scale - 4, (X2.ScreenAABB.Height - aabb.TopRight.Y) * Scale - 6, 0, 0)
		cvsrect.Width = aabb.Width * Scale + 12
		cvsrect.Height =aabb.Height * Scale + 12
		Dim bmp As B4XBitmap = DrawingBC.Bitmap.Crop(Max(0, cvsrect.Left), Max(0, cvsrect.Top), Max(0, cvsrect.Width), Max(0, cvsrect.Height))
		Dim sb As X2ScaledBitmap
		sb.Bmp = bmp
		sb.Scale = Scale / X2.mBCPixelsPerMeter
		X2.GraphicCache.PutGraphic2(gname, Array(sb), True, 2)
		bw.GraphicName = gname
	End If
	DrawingBC.FillRect(xui.Color_Transparent, DrawingBC.TargetRect)
	X2.SetBitmapWithFitOrFill(ivDrawing, DrawingBC.Bitmap)
End Sub

Sub btnClear_Click
	X2.Reset
	CreateBorder
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