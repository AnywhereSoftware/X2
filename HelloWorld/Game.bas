﻿B4J=true
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
	X2.EnableDebugDraw
	CreateStaticBackground
	'Passing Null for the target view parameter because we are not creating the background with a tile layer.
	TileMap.Initialize(X2, File.DirAssets, "hello world.json", Null) 
	TileMap.SetSingleTileDimensionsInMeters(WorldWidth / TileMap.TilesPerRow, WorldHeight / TileMap.TilesPerColumn)
	TileMap.PrepareObjectsDef(ObjectLayer)
	'create the ground
	TileMap.CreateObject(TileMap.GetObjectTemplate(ObjectLayer, 1)) '1 = ID of ground object in the TileMap file.
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
	If X2.RndFloat(0, 1000) < X2.TimeStepMs Then CreateBlock
	If X2.RndFloat(0, 1000) < X2.TimeStepMs Then CreateCircle
End Sub

Private Sub CreateCircle
	Dim template As X2TileObjectTemplate = TileMap.GetObjectTemplate(ObjectLayer, 2) '2 is the circle ID
	template.BodyDef.Position.X = X2.RndFloat(X2.ScreenAABB.BottomLeft.X, X2.ScreenAABB.TopRight.X)
	TileMap.CreateObject(template)
End Sub

Private Sub CreateBlock
	Dim template As X2TileObjectTemplate = TileMap.GetObjectTemplate(ObjectLayer, 3) '3 is the rectangle id
	'change the X position.
	template.BodyDef.Position.X = X2.RndFloat(X2.ScreenAABB.BottomLeft.X, X2.ScreenAABB.TopRight.X)
	TileMap.CreateObject(template)
End Sub

Public Sub DrawingComplete
	
End Sub

'Return True to stop the game loop
Public Sub BeforeTimeStep (GS As X2GameStep) As Boolean
	Return False
End Sub
