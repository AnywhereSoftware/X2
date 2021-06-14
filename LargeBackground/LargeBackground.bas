B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=9
@EndOfDesignText@
'Version 1.01
Sub Class_Globals
	Private x2 As X2Utils
	Type X2LargeTile (WorldRect As B2AABB, BCRect As B4XRect, FileName As String, bc As BitmapCreator)
	Private EmptyBC As BitmapCreator
	Private Tiles(0, 0) As X2LargeTile
	Private mNumberOfRows, mNumberOfColumns As Int
	Private TileWidthMeters, TileHeightMeters As Float
	Private TileWidthPixels, TileHeightPixels As Int
	Private WorldHeightPixels As Int
	Private xui As XUI
	Private bc As BitmapCreator
	Private UpdateInterval As Int = 1 'can change to 2 or 3 to improve performance
	Private BackgroundExtraScale As Float = 1.5 'increase to improve performance
	Private Counter As Int
	Private mGame As Game
	Private LastCreatedCenter, LastDrawnCenter As B2Vec2
End Sub

Public Sub Initialize (vGame As Game, Prefix As String, Extension As String, WorldWidth As Float, WorldHeight As Float, NumberOfRows As Int, NumberOfColumns As Int)
	mGame = vGame
	x2 = vGame.X2
	mNumberOfColumns = NumberOfColumns
	mNumberOfRows = NumberOfRows
	Dim Tiles(mNumberOfColumns, mNumberOfRows) As X2LargeTile
	TileWidthMeters = WorldWidth / NumberOfColumns
	TileHeightMeters = WorldHeight / NumberOfRows
	TileWidthPixels = Round(TileWidthMeters * x2.mBCPixelsPerMeter / BackgroundExtraScale)
	TileHeightPixels = Round(TileHeightMeters * x2.mBCPixelsPerMeter / BackgroundExtraScale)
	WorldHeightPixels = TileHeightPixels * NumberOfRows
	bc.Initialize(x2.MainBC.mWidth / BackgroundExtraScale, x2.MainBC.mHeight / BackgroundExtraScale)
	LastCreatedCenter.X = -999999
	For c = 0 To mNumberOfColumns - 1
		For r = 0 To mNumberOfRows - 1
			Dim t As X2LargeTile
			t.Initialize
			t.FileName = $"${Prefix}_${c}x${r}.${Extension}"$
			t.WorldRect.Initialize2(x2.CreateVec2(TileWidthMeters * c, TileHeightMeters * r), _
				x2.CreateVec2(TileWidthMeters * (c + 1), TileHeightMeters * (r + 1)))
			t.BCRect.Initialize(TileWidthPixels * c, WorldHeightPixels - TileHeightPixels *  (r + 1), 0, 0)
			t.BCRect.Width = TileWidthPixels
			t.BCRect.Height = TileHeightPixels
			Tiles(c, r) = t
		Next
	Next
End Sub

Public Sub Tick (gs As X2GameStep)
	Counter = Counter + 1
	If gs.ShouldDraw = False Or Counter Mod UpdateInterval = 1 Then Return
	If LastDrawnCenter.Equals(x2.ScreenAABB.Center) Then Return
	Dim BCLeft As Int = Round(x2.ScreenAABB.BottomLeft.X * x2.mBCPixelsPerMeter / BackgroundExtraScale)
	Dim BCTop As Int = Round(WorldHeightPixels - x2.ScreenAABB.TopRight.Y * x2.mBCPixelsPerMeter / BackgroundExtraScale)
	For c = 0 To mNumberOfColumns - 1
		For r = 0 To mNumberOfRows - 1
			Dim Tile As X2LargeTile = Tiles(c, r)
			If x2.ScreenAABB.TestOverlap(Tile.WorldRect) Then
				If Tile.BC.IsInitialized = False Then LoadBC(Tile)
				'draw the tile BC on the game BC
				Dim task As DrawTask = bc.CreateDrawTask(Tile.BC, Tile.BC.TargetRect, Tile.BCRect.Left - BCLeft, Tile.BCRect.Top - BCTop, True)
				task.TargetBC = bc
				gs.DrawingTasks.Add(task)
			Else
				Tile.BC = EmptyBC
			End If
		Next
	Next
	LastCreatedCenter.X = x2.ScreenAABB.Center.X
	LastCreatedCenter.Y = x2.ScreenAABB.Center.Y
End Sub

Private Sub LoadBC (Tile As X2LargeTile)
	Dim bmp As B4XBitmap = xui.LoadBitmapResize(File.DirAssets, Tile.FileName, TileWidthPixels, TileHeightPixels, False)
	Dim bc2 As BitmapCreator
	bc2.Initialize(bmp.Width, bmp.Height)
	bc2.CopyPixelsFromBitmap(bmp)
	Tile.BC = bc2
End Sub

Public Sub DrawComplete
	If LastCreatedCenter.Equals(LastDrawnCenter) Then Return
	LastDrawnCenter.X = LastCreatedCenter.X
	LastDrawnCenter.Y = LastCreatedCenter.Y
	x2.SetBitmapWithFitOrFill(mGame.ivBackground, bc.Bitmap)
End Sub

