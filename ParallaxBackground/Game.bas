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
	Public ivBackground As B4XView
	Public lblStats As B4XView
	Public TileMap As X2TileMap
	Public Const ObjectLayer As String = "Object Layer 1"
	Private PanelForTouch As B4XView
	Private Multitouch As X2MultiTouch
	Private sound As X2SoundPool
	Private Parallax As ParallaxBackground
End Sub

'Images source: https://opengameart.org/content/parallax-2d-backgrounds

'The example files are located in the Shared Files folder and in each of the projects Files folder. In most cases you will want to delete all these files, except of the layout files.
Public Sub Initialize (Parent As B4XView)
	Parent.LoadLayout("GameLayout")
	world.Initialize("world", world.CreateVec2(0, 0))
	X2.Initialize(Me, ivForeground, world)
	Dim WorldWidth As Float = 10 'meters
	Dim WorldHeight As Float = WorldWidth * Parent.Height / Parent.Width
	X2.ConfigureDimensions(world.CreateVec2(WorldWidth / 2, WorldHeight / 2), WorldWidth)
	'comment to disable debug drawing
	'X2.EnableDebugDraw
	TileMap.Initialize(X2, File.DirAssets, "hello world with background.json", ivBackground)
	'We want the tiles to be square. Otherwise we will have issues with rotated tiles.
	Dim TileSize As Int = Min(X2.MainBC.mWidth / TileMap.TilesPerRow, X2.MainBC.mHeight / TileMap.TilesPerColumn)
	TileMap.SetSingleTileDimensionsInBCPixels(TileSize, TileSize)
	TileMap.PrepareObjectsDef(ObjectLayer)
	Multitouch.Initialize(B4XPages.MainPage, Array(PanelForTouch))
	sound.Initialize
	Parallax.Initialize(Me, "layer", "png", 7)
End Sub

Public Sub Resize
	X2.ImageViewResized
End Sub

Public Sub Start
	Multitouch.ResetState
	X2.Start
End Sub

Private Sub HandleKeys
	Dim v As B2Vec2 = X2.ScreenAABB.Center
	Dim delta As Float = X2.TimeStepMs / 50
	Dim RightDown, LeftDown, UpDown, DownDown As Boolean 'ignore (UpDown / DownDown are not used)
	#if B4J
	LeftDown = Multitouch.Keys.Contains("Left")
	RightDown = Multitouch.Keys.Contains("Right")
	UpDown = Multitouch.Keys.Contains("Up")
	DownDown = Multitouch.Keys.Contains("Down")
	#End If
	Dim touch As X2Touch = Multitouch.GetSingleTouch(PanelForTouch)
	If touch.IsInitialized Then
		LeftDown = touch.x < PanelForTouch.Width / 3
		RightDown = touch.x > 2 / 3 * PanelForTouch.Width
		UpDown = touch.y < PanelForTouch.Height / 3
		DownDown = touch.y > 2 / 3 * PanelForTouch.Height
	End If
	If RightDown Then
		v.X = v.X + delta
	Else If LeftDown Then
		v.X = v.X - delta
	End If
	If v.Equals(X2.ScreenAABB.Center) = False Then
		X2.UpdateWorldCenter(v)
	End If
End Sub

Public Sub Tick (GS As X2GameStep)
	HandleKeys
	Parallax.Tick(GS)
End Sub

Public Sub DrawingComplete
	Parallax.DrawComplete
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
