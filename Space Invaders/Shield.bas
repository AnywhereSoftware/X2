B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=6.47
@EndOfDesignText@
Sub Class_Globals
	Public bw As X2BodyWrapper
	Private x2 As X2Utils 'ignore
	Private bc As BitmapCreator
	Private ShapeSize As B2Vec2
	Private cbc As CompressedBC
	Private HalfWidth, HalfHeight As Float
	Private xui As XUI
End Sub

Public Sub Initialize (wrapper As X2BodyWrapper)
	bw = wrapper
	x2 = bw.X2
	bw.DelegateTo = Me
	ShapeSize = x2.GetShapeWidthAndHeight(bw.Body.FirstFixture.Shape)
	bc.Initialize(x2.MetersToBCPixels(ShapeSize.X), x2.MetersToBCPixels(ShapeSize.Y))
	bc.FillGradient(Array As Int(0xFF006016, 0xFF92F7AA), bc.TargetRect, "RECTANGLE")
	'remove the large shape and create smaller blocks
	bw.Body.DestroyFixture(bw.Body.FirstFixture)
	Dim fd As B2FixtureDef
	Dim rect As B2PolygonShape
	rect.Initialize
	fd.Shape = rect
	Dim BlocksPerRow = 6, BlocksPerColumn = 3 As Int
	HalfWidth = ShapeSize.X / BlocksPerRow / 2
	HalfHeight = ShapeSize.Y / BlocksPerColumn / 2
	fd.Friction = 0	
	fd.IsSensor = True
	For y = 0 To BlocksPerColumn - 1
		For x = 0 To BlocksPerRow - 1
			Dim position As B2Vec2 = x2.CreateVec2(-ShapeSize.X / 2 + (x * 2 + 1) * HalfWidth, -ShapeSize.Y / 2 + (y * 2 + 1) * HalfHeight)
			rect.SetAsBox2(HalfWidth, HalfHeight, position, 0)
			Dim fixture As B2Fixture = bw.Body.CreateFixture(fd)
			'we save the x and y indices. Later they will be used to clear the broken fixtures.
			fixture.Tag = Array As Float(x / BlocksPerRow, y / BlocksPerColumn)
		Next
	Next
	UpdateCBC
End Sub

Public Sub Hit(Fixture As B2Fixture)
	Dim xy() As Float = Fixture.Tag
	bw.Body.DestroyFixture(Fixture)
	Dim rect As B4XRect
	Dim width As Int = x2.MetersToBCPixels(HalfWidth * 2)
	Dim height As Int = x2.MetersToBCPixels(HalfHeight * 2)
	'need to turn the y position upside down.
	rect.Initialize(xy(0) * bc.mWidth - 1, bc.mHeight - height - xy(1) * bc.mHeight, 0, 0)
	rect.Width = width + 2
	rect.Height = height + 2
	bc.FillRect(xui.Color_Transparent, rect)
	UpdateCBC
End Sub

Private Sub UpdateCBC
	cbc = bc.ExtractCompressedBC(bc.TargetRect, x2.GraphicCache.CBCCache)
End Sub

Public Sub Tick (GS As X2GameStep)
	If GS.ShouldDraw Then
		GS.DrawingTasks.Add(x2.CreateDrawTaskFromCompressedBC(cbc, x2.WorldPointToMainBC(bw.Body.Position.X, bw.Body.Position.Y), cbc.TargetRect))
	End If
End Sub