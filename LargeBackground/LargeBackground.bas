B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=9
@EndOfDesignText@
'Version 1.00
Sub Class_Globals
	Private x2 As X2Utils
	Type X2LargeTile (WorldRect As B2AABB, BCRect As B4XRect, FileName As String, BC As BitmapCreator)
	Private EmptyBC As BitmapCreator
	Private Tiles(0, 0) As X2LargeTile
	Private mNumberOfRows, mNumberOfColumns As Int
	Private TileWidthMeters, TileHeightMeters As Float
	Private TileWidthPixels, TileHeightPixels As Int
	Private WorldHeightPixels As Int
	Private xui As XUI
End Sub

Public Sub Initialize (Prefix As String, Extension As String, WorldWidth As Float, WorldHeight As Float, NumberOfRows As Int, NumberOfColumns As Int)
	x2 = B4XPages.MainPage.mGame.X2
	mNumberOfColumns = NumberOfColumns
	mNumberOfRows = NumberOfRows
	Dim Tiles(mNumberOfColumns, mNumberOfRows) As X2LargeTile
	TileWidthMeters = WorldWidth / NumberOfColumns
	TileHeightMeters = WorldHeight / NumberOfRows
	TileWidthPixels = Round(TileWidthMeters * x2.mBCPixelsPerMeter)
	TileHeightPixels = Round(TileHeightMeters * x2.mBCPixelsPerMeter)
	WorldHeightPixels = TileHeightPixels * NumberOfRows
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

Public Sub Draw (gs As X2GameStep)
	If gs.ShouldDraw = False Then Return
	Dim BCLeft As Int = Round(x2.ScreenAABB.BottomLeft.X * x2.mBCPixelsPerMeter)
	Dim BCTop As Int = Round(WorldHeightPixels - x2.ScreenAABB.TopRight.Y * x2.mBCPixelsPerMeter)
	For c = 0 To mNumberOfColumns - 1
		For r = 0 To mNumberOfRows - 1
			Dim Tile As X2LargeTile = Tiles(c, r)
			If x2.ScreenAABB.TestOverlap(Tile.WorldRect) Then
				If Tile.BC.IsInitialized = False Then LoadBC(Tile)
				'draw the tile BC on the game BC
				Dim task As DrawTask = x2.MainBC.CreateDrawTask(Tile.BC, Tile.BC.TargetRect, Tile.BCRect.Left - BCLeft, Tile.BCRect.Top - BCTop, True)
				gs.DrawingTasks.Add(task)
			Else
				Tile.BC = EmptyBC
			End If
		Next
	Next
End Sub

Private Sub LoadBC (Tile As X2LargeTile)
	Dim bmp As B4XBitmap = xui.LoadBitmapResize(File.DirAssets, Tile.FileName, TileWidthPixels, TileHeightPixels, False)
	Dim bc As BitmapCreator
	bc.Initialize(bmp.Width, bmp.Height)
	bc.CopyPixelsFromBitmap(bmp)
	Tile.BC = bc
End Sub

