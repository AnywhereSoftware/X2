B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=6.47
@EndOfDesignText@
Sub Class_Globals
	Public X2 As X2Utils
	Public xui As XUI 
	Public world As B2World
	Public Ground As X2BodyWrapper
	Public ivForeground As B4XView
	Public ivBackground As B4XView
	Public lblStats As B4XView
	Private GamePanel As B4XView
	Public BlocksPerRow As Int = 10
	Public NumberOfRows As Int = 20
	Type PieceData (Pattern As List, GraphicName As String, Orientations As Int, CenterX As Int, CenterY As Int)
	Type Piece (Data As PieceData, Bodies As List, CenterX As Int, CenterY As Int, Orientation As Int)
	Private CurrentPiece As Piece
	Private PDs As List
	Private IntervalBetweenUserInputMs As Int = 30
	Private IntervalBetweenAutomaticAdvancementMs As Int
	Private LastAutomaticAdvancement As Int
	Private LastUserInput As Int
	Private ScoreLabel1 As ScoreLabel
	Private GameState As String
	Private btnPause As B4XView
	
	Private lblLevel As B4XView
	
	Private level As Int = 1
	Private NextPieceType As Int
	Private lblNext As B4XView
	Private lblMessage As B4XView
	Public const STATE_NORMAL = "normal", STATE_PAUSED = "paused", STATE_GAMEOVER = "game over" As String
	Private imgNextPiece As B4XView
	Private NextPieceBC As BitmapCreator
	Private Multitouch As X2MultiTouch
	Private LeftDown, RightDown, UpDown, DownDown As Boolean
End Sub

Public Sub Initialize (Parent As B4XView)
	Parent.LoadLayout("1")
	GamePanel.LoadLayout("GameLayout")
	world.Initialize("world", world.CreateVec2(0, 0))
	X2.Initialize(Me, ivForeground, world)
	Dim WorldWidth As Float = BlocksPerRow 'meters
	
	Dim PixelsPerMeter As Int = Floor(X2.MainBC.mWidth / WorldWidth) 'we want the number of pixels per meter to be a whole number
	WorldWidth = X2.MainBC.mWidth / PixelsPerMeter
	Dim WorldHeight As Float = WorldWidth / 0.5 'same ratio as in the designer script
	X2.ConfigureDimensions(world.CreateVec2(WorldWidth / 2, WorldHeight / 2), WorldWidth)
	PDs.Initialize
	LoadPieces
	NextPieceBC.Initialize(X2.MetersToBCPixels(4) + 10, X2.MetersToBCPixels(4) + 10)
'	X2.EnableDebugDraw
	X2.SoundPool.AddSound("row", File.DirAssets, "rows_completed.mp3")
	X2.SoundPool.AddSound("game over", File.DirAssets, "game_over.mp3")
	Multitouch.Initialize(B4XPages.MainPage, Null)
	CreateStaticBackground
	ResetState
	
	
	Dim fnt As B4XFont
	#if B4J
	Dim fx As JFX
	fnt = fx.LoadFont(File.DirAssets, "neutronium.ttf", 30)
	#else if B4A
	fnt = xui.CreateFont(Typeface.LoadFromAssets("neutronium.ttf"), 20)
	#else if B4i
	fnt = xui.CreateFont(Font.CreateNew2("Neutronium", 20), 20)
	#End If
	For Each lbl As B4XView In Array(ScoreLabel1.Base.GetView(0), lblLevel, lblNext, lblMessage)
		#if B4J
		Dim jlbl As Label = lbl
		jlbl.Style = "" 'to avoid conflicts between the CSS settings and the custom font
		#else if B4i
		Dim ilbl As Label = lbl
		ilbl.Multiline = True
		#End If
		lbl.Font = fnt
		lbl.SetTextAlignment("CENTER", "CENTER")
		lbl.TextColor = xui.Color_White
	Next
	lblMessage.Color = 0x88000000
	lblMessage.TextSize = 40
End Sub

Private Sub CreatePiece
	Dim pd As PieceData = PDs.Get(NextPieceType)
	Dim p As Piece
	p.Initialize
	p.Bodies.Initialize
	For i = 0 To 3
		Dim bd As B2BodyDef
		bd.BodyType = bd.TYPE_KINEMATIC
		Dim bw As X2BodyWrapper = X2.CreateBodyAndWrapper(bd, Null, "")
		bw.GraphicName = pd.GraphicName
		bw.DestroyIfInvisible = False
		bw.Tag = "moving"
		p.Bodies.Add(bw)
		Dim shape As B2PolygonShape
		shape.Initialize
		shape.SetAsBox(0.5, 0.5)
		bw.Body.CreateFixture2(shape, 1).SetFilterBits(0, 0)
	Next
	p.Data = pd
	p.CenterX = 4
	p.CenterY = 18
	CurrentPiece = p
	UpdatePattern
	If CanMove(0, -1) = False Then
		SetGameState(STATE_GAMEOVER)
		X2.SoundPool.PlaySound("game over")
	End If
	NextPieceType = Rnd(0, PDs.Size)
	DrawNextPiece (PDs.Get(NextPieceType))
End Sub

Public Sub PieceStoppedMoving
	Dim RemovedRows As List
	For Each bw As X2BodyWrapper In CurrentPiece.Bodies
		bw.Tag = "static"
	Next
	For i = 0 To NumberOfRows - 1
		If IsFullRow(i) Then
			If RemovedRows.IsInitialized = False Then RemovedRows.Initialize
			RemovedRows.Add(i)
			ScoreLabel1.Value = ScoreLabel1.Value + 100
			If ScoreLabel1.Value Mod 200 = 0 Then
				UpdateLevel(level + 1)
			End If
		End If
	Next
	If RemovedRows.IsInitialized Then
		RemoveRows(RemovedRows)
	Else
		CreatePiece
	End If
End Sub

Private Sub RemoveRows(rows As List)
	X2.SoundPool.PlaySound("row")
	Dim deltay As Int
	Dim y As Int
	Do While y < NumberOfRows
		If rows.Size > 0 And y = rows.Get(0) Then
			rows.RemoveAt(0)
			deltay = deltay + 1
			For x = 0 To BlocksPerRow - 1
				Dim bw As X2BodyWrapper = GetStaticBlock(x, y)
				bw.Tag = "removed"
				bw.DestroyIfInvisible = True
				bw.Body.LinearVelocity = X2.CreateVec2(X2.RndFloat(-5, 5), X2.RndFloat(5, 20))
				bw.Body.AngularVelocity = X2.RndFloat(5, 15)
				
			Next
		Else if deltay > 0 Then
			For x = 0 To BlocksPerRow - 1
				If IsBlockEmpty(x, y) = False Then
					Dim bw As X2BodyWrapper = GetStaticBlock(x, y)
					bw.Body.SetTransform(X2.CreateVec2(x + 0.5, y + 0.5 - deltay), 0)
				End If
			Next
		End If
		y = y + 1
	Loop
	CreatePiece
End Sub

Private Sub GetStaticBlock(x As Int, y As Int) As X2BodyWrapper
	For Each bw As X2BodyWrapper In X2.GetBodiesIntersectingWithWorldPoint(X2.CreateVec2(x + 0.5, y + 0.5))
		If bw.Tag = "static" Then Return bw
	Next
	Return Null
End Sub

Private Sub UpdatePattern
	For i = 0 To 3
		Dim p() As Int = CurrentPiece.Data.Pattern.Get(i)
		Dim x, y As Int
		Select CurrentPiece.orientation
			Case 0
				x = p(0)
				y = p(1)
			Case 1
				x = p(1)
				y = -p(0)
			Case 2
				x = -p(0)
				y = -p(1)
			Case 3
				x = -p(1)
				y = p(0)
		End Select
		Dim bw As X2BodyWrapper = CurrentPiece.Bodies.Get(i)
		bw.Body.SetTransform(X2.CreateVec2(CurrentPiece.Data.CenterX + CurrentPiece.CenterX + x + 0.5, CurrentPiece.Data.CenterY + CurrentPiece.CenterY + y + 0.5), 0)
	Next
End Sub


Private Sub CreateStaticBackground
	Dim bc As BitmapCreator
	bc.Initialize(ivBackground.Width / xui.Scale, ivBackground.Height / xui.Scale)
	Dim rect As B4XRect
	Dim width As Int = X2.mBCPixelsPerMeter * BlocksPerRow
	rect.Initialize(0, 0, width, bc.mHeight - 1)
	bc.FillGradient(Array As Int(0xFF006EFF, 0xFF00DAAD), rect, "TOP_BOTTOM")
	X2.SetBitmapWithFitOrFill(ivBackground, bc.Bitmap)
End Sub

Public Sub Resize
	X2.ImageViewResized
End Sub

Public Sub Tick (GS As X2GameStep)
	ScoreLabel1.Tick
	If GameState = "normal" Then
		If GS.GameTimeMs - LastUserInput < IntervalBetweenUserInputMs Then Return
		LastUserInput = GS.GameTimeMs
		Dim dx As Int
	
		#if B4J
		LeftDown = Multitouch.Keys.Contains("Left")
		RightDown = Multitouch.Keys.Contains("Right")
		UpDown = Multitouch.Keys.Contains("Up")
		DownDown = Multitouch.Keys.Contains("Down")
		Multitouch.Keys.Clear 'don't handle the same keystrokes again
		#End If
		If LeftDown Then
			dx = -1
			LeftDown = False
		Else if RightDown Then
			dx = 1
			RightDown = False
		End If
		If dx <> 0 Then
			Move(dx, 0, False)
		End If
		If UpDown Then
			UpDown = False
			'rotate
			CurrentPiece.orientation = (CurrentPiece.orientation + 1) Mod CurrentPiece.Data.Orientations
			UpdatePattern
			If CanMove(0, 0) = True Then
				Move(0, 0, True)
			Else if CanMove(1, 0) Then
				Move(1, 0, True)
			Else if CanMove(-1, 0) Then
				Move(-1, 0, True)
			Else
				CurrentPiece.orientation = (CurrentPiece.orientation - 1 + CurrentPiece.Data.Orientations) Mod CurrentPiece.Data.Orientations
				UpdatePattern
				Move(0, 0, True)
			End If
		End If
		If GS.GameTimeMs - LastAutomaticAdvancement > IntervalBetweenAutomaticAdvancementMs Or DownDown Then
			LastAutomaticAdvancement = GS.GameTimeMs
			Dim dy As Int = -1
			If DownDown And (xui.IsB4A Or xui.IsB4i) Then
				'move as far as possible
				For i = -2 To -20 Step - 1
					If CanMove(0, i) = False Then
						dy = i + 1
						Exit
					End If
				Next
				LastAutomaticAdvancement = 0
			End If
			
			DownDown = False
			If Move(0, dy, False) = False Then
				PieceStoppedMoving
			End If
		End If
	End If
End Sub

Private Sub Move (dx As Int, dy As Int, onlyset As Boolean) As Boolean
	If Not(onlyset) And CanMove(dx, dy) = False Then
		'cannot move so return previous state
		Move(0, 0, True)
		Return False
	End If
	CurrentPiece.CenterX = CurrentPiece.CenterX + dx
	CurrentPiece.CenterY = CurrentPiece.CenterY + dy
	UpdatePattern
	Return True
End Sub

Private Sub CanMove (dx As Int, dy As Int) As Boolean
	For Each bw As X2BodyWrapper In CurrentPiece.Bodies
		Dim vec As B2Vec2 = bw.Body.Position.CreateCopy
		vec.X = vec.X + dx
		vec.Y = vec.Y + dy
		If IsBlockEmpty(vec.X - 0.5, vec.Y - 0.5) = False Then Return False
	Next
	Return True
End Sub

Public Sub DrawingComplete
	
End Sub

'Return True to stop the game loop
Public Sub BeforeTimeStep (GS As X2GameStep) As Boolean
	Return False
End Sub


Private Sub LoadPieces
	Dim bmp As X2ScaledBitmap = X2.LoadBmp(File.DirAssets, "block.png", 1, 1, False)
	Dim src As BitmapCreator
	src.Initialize(bmp.Bmp.Width, bmp.Bmp.Height)
	src.CopyPixelsFromBitmap(bmp.Bmp)
	Dim m As Map = File.ReadMap(File.DirAssets, "pieces.txt")
	Dim i As Int = 1
	Dim rb As RegexBuilder
	rb.Initialize.AppendEscaped("(").StartCapture.AppendAnyBut(Array(",")).AppendAtLeastOne.EndCapture.AppendEscaped(",")
	rb.StartCapture.AppendAnyBut(Array(")")).AppendAtLeastOne.EndCapture.AppendEscaped(")")
	Do While m.ContainsKey($"P${i}.Color"$)
		Dim pd As PieceData
		pd.Initialize
		'the full value as an unsigned number is too large to fit in a signed int so we need to add the alpha level ourselves.
		Dim clr As Int = 0xff000000 + Bit.ParseInt(m.Get($"P${i}.Color"$), 16)
		Dim bc As BitmapCreator = GreyscaleToColor(src, clr)
		X2.GraphicCache.PutGraphicBCs(clr, Array(bc), False, 5)
		pd.GraphicName = clr
		pd.Orientations = m.Get($"P${i}.Orientations"$)
		pd.Pattern.Initialize
		Dim match As Matcher = Regex.Matcher(rb.Pattern, m.Get($"P${i}.Pattern"$))
		Do While match.Find
			pd.Pattern.Add(Array As Int(match.Group(1), match.Group(2)))
		Loop
		match = Regex.Matcher(rb.Pattern, m.Get($"P${i}.Center"$))
		match.Find
		pd.CenterX = match.Group(1)
		pd.CenterY = match.Group(2)
		PDs.Add(pd)
		i = i + 1
	Loop
End Sub

Public Sub Start

	X2.Start
End Sub

Private Sub ResetState
	GameState = STATE_NORMAL
	LastAutomaticAdvancement = 0
	LastUserInput = 0
	Multitouch.ResetState
	X2.Reset
	CreatePiece
	ScoreLabel1.SetValueNow(0)
	UpdateLevel(1)
End Sub


Private Sub IsFullRow(row As Int) As Boolean
	For x = 0 To BlocksPerRow - 1
		If IsBlockEmpty(x, row) Then Return False
	Next
	Return True
End Sub

Private Sub IsBlockEmpty(x As Float, y As Float) As Boolean
	If x < 0 Or x >= BlocksPerRow Or y < 0 Then Return False
	Dim b As List = X2.GetBodiesIntersectingWithWorldPoint(X2.CreateVec2(x + 0.5, y + 0.5))
	If b.Size = 0 Then 
		Return True
	End If
	Dim bw As X2BodyWrapper = b.Get(0)
	
	If bw.Tag <> "static" Then Return True
	Return False
End Sub

Private Sub UpdateLevel (lvl As Int)
	level = lvl
	lblLevel.Text = "Level" & CRLF & lvl
	IntervalBetweenAutomaticAdvancementMs = 400 - level * 5
End Sub

Public Sub Pause
	SetGameState(STATE_PAUSED)
End Sub

Public Sub SetGameState(state As String)
	If state = GameState Then Return
	If GameState = STATE_NORMAL Then
		GameState = state
		If state = STATE_PAUSED Then
			ShowMessage("PAUSED")
		Else If state = STATE_GAMEOVER Then
			ShowMessage("GAME OVER")
		End If
		btnPause.Text = Chr(0xF04B)
	Else if state = STATE_NORMAL Then
		If GameState = STATE_GAMEOVER Then ResetState
		GameState = STATE_NORMAL
		btnPause.Text = Chr(0xF04C)
		lblMessage.Visible = False
	End If
	
End Sub

Private Sub ShowMessage(msg As String)
	lblMessage.Text = msg
	lblMessage.Visible = True
End Sub


#if B4A or B4i

'Sub ImageViewPanel_Click
'	Main.UpDown = True
'	PerformHapticFeedback(Sender)
'End Sub

Sub lblDown_Click
	DownDown = True
	XUIViewsUtils.PerformHapticFeedback(Sender)
End Sub

Sub lblRight_Click
	RightDown = True
	XUIViewsUtils.PerformHapticFeedback(Sender)
End Sub

Sub lblRotate_Click
	UpDown = True
	XUIViewsUtils.PerformHapticFeedback(Sender)
End Sub

Sub lblLeft_Click
	LeftDown = True
	XUIViewsUtils.PerformHapticFeedback(Sender)
End Sub
#end if

Private Sub GreyscaleToColor (src As BitmapCreator, TargetColor As Int) As BitmapCreator
	Dim bc As BitmapCreator
	bc.Initialize(src.mWidth, src.mHeight)
	Dim a As ARGBColor
	Dim clr As ARGBColor
	src.ColorToARGB(TargetColor, clr)
	For y = 0 To src.mHeight - 1
		For x = 0 To src.mWidth - 1
			src.GetARGB(x, y, a)
			Dim f As Float = a.r / 255
			a.r = clr.r * f
			a.g = clr.g * f
			a.b = clr.b * f
			bc.SetARGB(x, y, a)
		Next
	Next
	Return bc
End Sub


Sub btnPause_Click
	If GameState = STATE_NORMAL Then SetGameState(STATE_PAUSED) Else SetGameState(STATE_NORMAL)
End Sub

Sub DrawNextPiece (pd As PieceData)
	NextPieceBC.FillRect(xui.Color_Transparent, NextPieceBC.TargetRect)
	Dim ActualBounds As B4XRect
	ActualBounds.Initialize(1000, 1000, 0, 0) 'ignore
	Dim BlockSize As Int = X2.MetersToBCPixels(1)
	'First we find the actual bounds of the piece as it is not centered.
	For Each xy() As Int In pd.Pattern
		Dim left As Int = (pd.CenterX + xy(0)) * BlockSize
		Dim top As Int = (pd.CenterY - xy(1)) * BlockSize
		ActualBounds.Left = Min(ActualBounds.Left, left)
		ActualBounds.Top = Min(ActualBounds.Top, top)
		ActualBounds.Right = Max(ActualBounds.Right, left + BlockSize)
		ActualBounds.Bottom = Max(ActualBounds.Bottom, top + BlockSize)
	Next
	Dim OffsetX As Int = NextPieceBC.mWidth / 2 - ActualBounds.CenterX
	Dim OffsetY As Int = NextPieceBC.mHeight / 2 - ActualBounds.CenterY
	Dim cbc As CompressedBC = X2.GraphicCache.GetGraphic(pd.GraphicName, 0)
	For Each xy() As Int In pd.Pattern
		Dim left As Int = (pd.CenterX + xy(0)) * BlockSize + OffsetX
		Dim top As Int = (pd.CenterY - xy(1)) * BlockSize + OffsetY
		NextPieceBC.DrawCompressedBitmap(cbc, cbc.TargetRect, left, top)
	Next
	NextPieceBC.SetBitmapToImageView(NextPieceBC.Bitmap, imgNextPiece)
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

