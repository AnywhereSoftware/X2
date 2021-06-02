B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=6.47
@EndOfDesignText@
#if B4A
'ignore DIP related warnings as they are not relevant when working with BitmapCreator
#IgnoreWarnings: 6
#end if
Sub Class_Globals
	Public X2 As X2Utils
	Private xui As XUI
	Public world As B2World
	Public Ground As X2BodyWrapper
	Private ivForeground As B4XView
	Private ivBackground As B4XView
	Public lblStats As B4XView
	Private TileMap As X2TileMap
	Private MiniTileMap As X2TileMap
	Private pnlMiniMap As B4XView
	
	Private pnlTouch As B4XView 
	Private ivMiniMap As ImageView
	Private ivMiniMapBC As BitmapCreator
	Private MiniMapScreenWindow As CompressedBC
	Private Multitouch As X2MultiTouch
End Sub

Public Sub Initialize (Parent As B4XView)
	Parent.LoadLayout("1")
	world.Initialize("world", world.CreateVec2(0, -10))
	X2.Initialize(Me, ivForeground, world)
	'Configure the dimensions.
	X2.ConfigureDimensions(world.CreateVec2(10, 10), 10)
	TileMap.Initialize(X2, File.DirAssets, "map1.json", ivBackground)
	Dim TileSize As Int = X2.MetersToBCPixels(X2.ScreenAABB.Width / 15) '15 tiles per screen
	TileMap.SetSingleTileDimensionsInBCPixels(TileSize, TileSize)
	lblStats.TextColor = xui.Color_Blue
	'comment to disable debug drawing
	'X2.EnableDebugDraw
	CreateMiniMap
	TileMap.PrepareObjectsDef("Object Layer 1")
	Dim layer As X2ObjectsLayer = TileMap.Layers.Get("Object Layer 1")
	For Each template As X2TileObjectTemplate In layer.ObjectsById.Values
		TileMap.CreateObject(template)
	Next
	ivMiniMapBC.Initialize(ivMiniMap.Width / xui.Scale, ivMiniMap.Height / xui.Scale)
	Multitouch.Initialize(B4XPages.MainPage, Array(pnlTouch, pnlMiniMap))
End Sub


Private Sub CreateMiniMap

	'load the map
	MiniTileMap.Initialize(X2, File.DirAssets, "map1.json", ivMiniMap)
	MiniTileMap.SetSingleTileDimensionsInBCPixels(ivMiniMap.Width / xui.Scale / MiniTileMap.TilesPerRow, ivMiniMap.Height / xui.Scale / MiniTileMap.TilesPerColumn)
	Dim tasks As List
	tasks.Initialize
	MiniTileMap.Draw(Array("Tile Layer 1"), MiniTileMap.MapAABB, tasks)
	'draw it synchronously to make the flow simpler
	For Each dt As DrawTask In tasks
		If dt.IsCompressedSource Then
			MiniTileMap.CurrentBC.DrawCompressedBitmap(dt.Source, dt.SrcRect, dt.TargetX, dt.TargetY)
		End If
	Next
	'create the yellow rectangle
	Dim scale As Float = MiniTileMap.TileWidthMeters / TileMap.TileWidthMeters * X2.mBCPixelsPerMeter
	Dim bc As BitmapCreator
	bc.Initialize(Ceil(X2.ScreenAABB.Width * scale) + 4, Ceil(X2.ScreenAABB.Height * scale) + 4)
	bc.DrawRect(bc.TargetRect, xui.Color_Yellow, False, 2)
	MiniMapScreenWindow = bc.ExtractCompressedBC(bc.TargetRect, X2.GraphicCache.CBCCache)
End Sub
 
Private Sub DrawMiniMap (gs As X2GameStep)
	Dim scale As Float = MiniTileMap.TileWidthMeters / TileMap.TileWidthMeters * X2.mBCPixelsPerMeter
	Dim dt As DrawTask = ivMiniMapBC.CreateDrawTask(MiniTileMap.CurrentBC, MiniTileMap.CurrentBC.TargetRect, 0, 0, True)
	dt.TargetBC = ivMiniMapBC 'must set the target as it is not the the default one (MainBC)
	gs.DrawingTasks.Add(dt)
	Dim x As Int = X2.ScreenAABB.BottomLeft.X * scale
	Dim y As Int = X2.ScreenAABB.TopRight.Y * scale
	y = ivMiniMapBC.mHeight - y 'BC Y axis goes from the top to the bottom
	dt = ivMiniMapBC.CreateDrawTask(MiniMapScreenWindow, MiniMapScreenWindow.TargetRect, x - 2, y - 2, True)
	dt.IsCompressedSource = True
	dt.TargetBC = ivMiniMapBC 'must set the target as it is not the the default one (MainBC)
	gs.DrawingTasks.Add(dt)
End Sub

Private Sub handleMinimapTouches
	Dim touch As X2Touch = Multitouch.GetSingleTouch(pnlMiniMap)
	If touch.IsInitialized = False Then Return
	Dim v As B2Vec2
	v.X = touch.x / pnlMiniMap.Width * TileMap.TilesPerRow * TileMap.TileWidthMeters
	v.Y = (pnlMiniMap.Height - touch.Y) / pnlMiniMap.Height * TileMap.TilesPerColumn * TileMap.TileHeightMeters
	v = ClipScreenCenterToMapArea(v)
	X2.UpdateWorldCenter(v)
End Sub

Public Sub Resize
	X2.ImageViewResized
End Sub

Public Sub DrawingComplete
	TileMap.DrawingComplete
	X2.SetBitmapWithFitOrFill(ivMiniMap, ivMiniMapBC.Bitmap)
End Sub

'Return True to stop the game loop
Public Sub BeforeTimeStep (GS As X2GameStep) As Boolean
	Return False
End Sub

Public Sub Tick (GS As X2GameStep)
	HandleKeys
	handleMinimapTouches
	If TileMap.DrawScreen(Array("Tile Layer 1"), X2.gs.DrawingTasks) Then
		DrawMiniMap(GS)
	End If
	
End Sub

Private Sub HandleKeys 
	Dim v As B2Vec2 = X2.ScreenAABB.Center
	Dim delta As Float = X2.TimeStepMs / 100
	Dim RightDown, LeftDown, UpDown, DownDown As Boolean
	#if B4J
	LeftDown = Multitouch.Keys.Contains("Left")
	RightDown = Multitouch.Keys.Contains("Right")
	UpDown = Multitouch.Keys.Contains("Up")
	DownDown = Multitouch.Keys.Contains("Down")
	#Else
	Dim touch As X2Touch = Multitouch.GetSingleTouch(pnlTouch)
	If touch.IsInitialized Then
		LeftDown = touch.x < pnlTouch.Width / 3
		RightDown = touch.x > 2 / 3 * pnlTouch.Width
		UpDown = touch.y < pnlTouch.Height / 3
		DownDown = touch.y > 2 / 3 * pnlTouch.Height
	End If
	#End If
	If RightDown Then
		v.X = v.X + delta
	Else If LeftDown Then
		v.X = v.X - delta
	End If
	If UpDown Then
		v.Y = v.y + delta
	Else If DownDown Then
		v.y = v.y - delta
	End If
	v = ClipScreenCenterToMapArea(v)
	If v.Equals(X2.ScreenAABB.Center) = False Then
		X2.UpdateWorldCenter(v)
	End If
End Sub

Sub ClipScreenCenterToMapArea (v As B2Vec2) As B2Vec2
	Dim ScreenHalfWidth As Float = X2.ScreenAABB.Width / 2
	Dim ScreenHalfHeight As Float = X2.ScreenAABB.Height / 2
	v.X = Max(ScreenHalfWidth, Min(TileMap.MapAABB.Width - ScreenHalfWidth, v.X))
	v.Y = Max(ScreenHalfHeight, Min(TileMap.MapAABB.Height - ScreenHalfHeight, v.Y))
	Return v
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

