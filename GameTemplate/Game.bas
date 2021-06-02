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
	Private Car As X2BodyWrapper
	Private force As B2Vec2
	Private Multitouch As X2MultiTouch
	Private sound As X2SoundPool
End Sub

'The example files are located in the Shared Files folder and in each of the projects Files folder. In most cases you will want to delete all these files, except of the layout files.
Public Sub Initialize (Parent As B4XView)
	Parent.LoadLayout("GameLayout")
	world.Initialize("world", world.CreateVec2(0, 0))
	X2.Initialize(Me, ivForeground, world)
	Dim WorldWidth As Float = 10 'meters
	Dim WorldHeight As Float = WorldWidth / 1.333 'same ratio as in the designer script
	X2.ConfigureDimensions(world.CreateVec2(WorldWidth / 2, WorldHeight / 2), WorldWidth)
	'comment to disable debug drawing
	'X2.EnableDebugDraw
	TileMap.Initialize(X2, File.DirAssets, "hello world with background.json", ivBackground)
	'We want the tiles to be square. Otherwise we will have issues with rotated tiles.
	Dim TileSize As Int = Min(X2.MainBC.mWidth / TileMap.TilesPerRow, X2.MainBC.mHeight / TileMap.TilesPerColumn)
	TileMap.SetSingleTileDimensionsInBCPixels(TileSize, TileSize)
	'Update the world center based on the map size
	SetWorldCenter
	TileMap.PrepareObjectsDef(ObjectLayer)
	'create the two borders
	TileMap.CreateObject2(ObjectLayer, 9)
	TileMap.CreateObject2(ObjectLayer, 10)
	'create the car
	Car = TileMap.CreateObject2ByName(ObjectLayer, "car")
	'add the car front and connect it to the car with a WeldJoint.
	Dim front As X2BodyWrapper = TileMap.CreateObject2ByName(ObjectLayer, "car front")
	Dim weld As B2WeldJointDef
	weld.Initialize(Car.Body, front.Body, front.Body.WorldCenter)
	X2.mWorld.CreateJoint(weld)
	force = X2.CreateVec2(0, 0.5)
	Multitouch.Initialize(B4XPages.MainPage, Array(PanelForTouch))
	sound.Initialize
	sound.AddSound("click", File.DirAssets, "click.mp3")
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
	Dim touch As X2Touch = Multitouch.GetSingleTouch(PanelForTouch)
	If touch.IsInitialized Then
		Car.Body.ApplyForceToCenter(Car.Body.Transform.MultiplyRot(force))
		If touch.Handled = False Then
			'check for click on car:
			For Each bw As X2BodyWrapper In X2.GetBodiesIntersectingWithWorldPoint(X2.ScreenPointToWorld(touch.X, touch.Y))
				If bw.Name = "car" Then
					Car.Body.ApplyAngularImpulse(5)
					touch.Handled = True
					sound.PlaySound("click")
				End If
			Next
		End If
	End If
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
