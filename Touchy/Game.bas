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
	Private Character As X2BodyWrapper
	Private Multitouch As X2MultiTouch
	Private TouchBrush As BCBrush
End Sub

'Sprite source: https://opengameart.org/content/character-sprite-walk-animation
Public Sub Initialize (Parent As B4XView)
	Parent.LoadLayout("GameLayout")
	world.Initialize("world", world.CreateVec2(0, 0))
	X2.Initialize(Me, ivForeground, world)
	Dim WorldWidth As Float = 20 'meters
	Dim WorldHeight As Float = WorldWidth / 1.333 'same ratio as in the designer script
	X2.ConfigureDimensions(world.CreateVec2(WorldWidth / 2, WorldHeight / 2), WorldWidth)
	'comment to disable debug drawing
'	X2.EnableDebugDraw
	TileMap.Initialize(X2, File.DirAssets, "hello world with background.json", ivBackground)
	'We want the tiles to be square. Otherwise we will have issues with rotated tiles.
	Dim TileSize As Int = Min(X2.MainBC.mWidth / TileMap.TilesPerRow, X2.MainBC.mHeight / TileMap.TilesPerColumn)
	TileMap.SetSingleTileDimensionsInBCPixels(TileSize, TileSize)
	'Update the world center based on the map size
	SetWorldCenter
	TileMap.PrepareObjectsDef(ObjectLayer)
	'create the border
	TileMap.CreateObject2(ObjectLayer, 9)
	'create the car
	Character = TileMap.CreateObject2ByName(ObjectLayer, "character")
	Multitouch.Initialize(B4XPages.MainPage, Array(PanelForTouch))
	CreateCharacterGraphics
	TouchBrush = X2.MainBC.CreateBrushFromColor(xui.Color_Red)
End Sub

'Called from B4XMainPage (two places)
Public Sub Start
	Multitouch.ResetState 'prevent cases where a touch ended when the app was in the background.
	X2.Start
End Sub

Private Sub CreateCharacterGraphics
	Dim ScaledBitmaps As List = X2.ReadSprites(xui.LoadBitmap(File.DirAssets, "ch003.png"), 4, 4, 1, 1)
	X2.GraphicCache.PutGraphic("chr down", Array(ScaledBitmaps.Get(0), ScaledBitmaps.Get(1), ScaledBitmaps.Get(2), ScaledBitmaps.Get(3)))
	X2.GraphicCache.PutGraphic("chr up", Array(ScaledBitmaps.Get(4), ScaledBitmaps.Get(5), ScaledBitmaps.Get(6), ScaledBitmaps.Get(7)))
	X2.GraphicCache.PutGraphic("chr left", Array(ScaledBitmaps.Get(8), ScaledBitmaps.Get(9), ScaledBitmaps.Get(10), ScaledBitmaps.Get(11)))
	X2.GraphicCache.PutGraphic("chr right", Array(ScaledBitmaps.Get(12), ScaledBitmaps.Get(13), ScaledBitmaps.Get(14), ScaledBitmaps.Get(15)))
	Character.GraphicName = "chr up"
End Sub

Private Sub SetWorldCenter
	'The map size will not be identical to the screen size. This happens because the tile size in (bc) pixels needs to be a whole number.
	'So we need to update the world center and move the map to the center.
	X2.UpdateWorldCenter(TileMap.MapAABB.Center)
End Sub

Public Sub Resize
	X2.ImageViewResized
End Sub

Public Sub Tick (GS As X2GameStep)
	TileMap.DrawScreen(Array("Tile Layer 1"), GS.DrawingTasks)
	DrawTouches
	HandleTouch
	
End Sub

Private Sub DrawTouches
	For Each Touch As X2Touch In Multitouch.GetTouches(PanelForTouch)
		If Touch.EventCounter = 0 Then
			Log("down")
		Else If Touch.FingerUp Then
			Log("up")
			'the touch will not be returned on the next call.
		End If
		'convert screen point to world point
		Dim worldpoint As B2Vec2 = X2.ScreenPointToWorld(Touch.X, Touch.Y)
		'convert world point to drawing point.
		Dim bcpoint As B2Vec2 = X2.WorldPointToMainBC(worldpoint.X, worldpoint.Y)
		X2.LastDrawingTasks.Add(X2.MainBC.AsyncDrawCircle(bcpoint.X, bcpoint.Y, X2.MetersToBCPixels(2), TouchBrush, True, 0))
	Next
End Sub

Private Sub HandleTouch
	Dim LeftDown, RightDown, UpDown, DownDown As Boolean
	'keyboard handling
	#if B4J
	LeftDown = Multitouch.Keys.Contains("Left")
	RightDown = Multitouch.Keys.Contains("Right")
	UpDown = Multitouch.Keys.Contains("Up")
	DownDown = Multitouch.Keys.Contains("Down")
	#End If
	Dim touch As X2Touch = Multitouch.GetSingleTouch(PanelForTouch)
	If touch.IsInitialized Then
		LeftDown = touch.X < 0.3 * PanelForTouch.Width
		RightDown = touch.X > 0.7 * PanelForTouch.Width
		UpDown = touch.Y < 0.3 * PanelForTouch.Height
		DownDown = touch.Y > 0.7 * PanelForTouch.Height
	End If
	Dim vx, vy As Float
	Dim graphicname As String
	Dim speed As Float = 2
	If LeftDown Then
		vx = -speed
		graphicname = "chr left"
	Else If RightDown Then
		vx = speed
		graphicname = "chr right"
	Else If UpDown Then
		vy = speed
		graphicname = "chr up"
	Else If DownDown Then
		vy = -speed
		graphicname = "chr down"
	End If
	If graphicname <> "" Then
		Character.GraphicName = graphicname
		Character.SwitchFrameIntervalMs = 200
	Else
		Character.SwitchFrameIntervalMs = 0
	End If
	Character.Body.LinearVelocity = X2.CreateVec2(vx, vy)
End Sub

Public Sub DrawingComplete
	TileMap.DrawingComplete
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
