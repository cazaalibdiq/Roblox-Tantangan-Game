local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local roundState = remotes:WaitForChild("RoundState")
local coinCollected = remotes:WaitForChild("CoinCollected")

local coinSound = Instance.new("Sound")
coinSound.Name = "CoinPickup"
coinSound.SoundId = "rbxassetid://9125402735"
coinSound.Volume = 0.5
coinSound.Parent = SoundService

local COLORS = {
	bgTop = Color3.fromRGB(27, 22, 46),
	bgBottom = Color3.fromRGB(10, 9, 18),
	panel = Color3.fromRGB(34, 29, 54),
	gold = Color3.fromRGB(255, 199, 39),
	goldSoft = Color3.fromRGB(255, 224, 130),
	text = Color3.fromRGB(245, 243, 255),
	muted = Color3.fromRGB(166, 158, 198),
	danger = Color3.fromRGB(255, 112, 112),
	dangerPanel = Color3.fromRGB(62, 26, 40),
	purple = Color3.fromRGB(124, 92, 255),
}

local TITLE_FONT = Enum.Font.GothamBlack
local BOLD_FONT = Enum.Font.GothamBold
local BODY_FONT = Enum.Font.Gotham

local function addCorner(instance, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = instance
	return corner
end

local function addStroke(instance, color, thickness, transparency)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness or 1
	stroke.Transparency = transparency or 0
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = instance
	return stroke
end

local function addPadding(instance, top, right, bottom, left)
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, top)
	padding.PaddingRight = UDim.new(0, right)
	padding.PaddingBottom = UDim.new(0, bottom)
	padding.PaddingLeft = UDim.new(0, left)
	padding.Parent = instance
	return padding
end

local function addList(instance, direction, padding)
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = direction
	layout.Padding = UDim.new(0, padding or 0)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = instance
	return layout
end

local function makeLabel(parent, props)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.BorderSizePixel = 0
	label.Font = BODY_FONT
	label.TextSize = 14
	label.TextColor3 = COLORS.text
	label.Text = ""
	for key, value in pairs(props) do
		label[key] = value
	end
	label.Parent = parent
	return label
end

local function makeCard(parent)
	local card = Instance.new("Frame")
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Position = UDim2.fromScale(0.5, 0.5)
	card.Size = UDim2.new(0.9, 0, 0, 0)
	card.AutomaticSize = Enum.AutomaticSize.Y
	card.BackgroundColor3 = COLORS.panel
	card.BackgroundTransparency = 0.03
	card.BorderSizePixel = 0
	addCorner(card, 24)
	addStroke(card, COLORS.gold, 1.5, 0.72)
	addPadding(card, 28, 26, 28, 26)
	addList(card, Enum.FillDirection.Vertical, 12)

	local constraint = Instance.new("UISizeConstraint")
	constraint.MaxSize = Vector2.new(460, 2000)
	constraint.MinSize = Vector2.new(272, 0)
	constraint.Parent = card

	local scale = Instance.new("UIScale")
	scale.Parent = card

	card.Parent = parent
	return card, scale
end

local function makeButton(parent, text, layoutOrder)
	local button = Instance.new("TextButton")
	button.Name = text .. "Button"
	button.LayoutOrder = layoutOrder
	button.Size = UDim2.new(1, 0, 0, 54)
	button.BackgroundColor3 = COLORS.gold
	button.BorderSizePixel = 0
	button.AutoButtonColor = false
	button.Font = TITLE_FONT
	button.TextSize = 20
	button.TextColor3 = Color3.fromRGB(24, 19, 36)
	button.Text = text
	addCorner(button, 14)
	addStroke(button, Color3.fromRGB(212, 158, 22), 1, 0.25)

	local scale = Instance.new("UIScale")
	scale.Parent = button

	button.MouseEnter:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.14), { BackgroundColor3 = COLORS.goldSoft }):Play()
		TweenService:Create(scale, TweenInfo.new(0.14), { Scale = 1.03 }):Play()
	end)

	button.MouseLeave:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.14), { BackgroundColor3 = COLORS.gold }):Play()
		TweenService:Create(scale, TweenInfo.new(0.14), { Scale = 1 }):Play()
	end)

	button.MouseButton1Down:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.08), { Scale = 0.97 }):Play()
	end)

	button.MouseButton1Up:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.12), { Scale = 1 }):Play()
	end)

	button.Parent = parent
	return button
end

local function pop(scale)
	scale.Scale = 0.94
	TweenService:Create(scale, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
end

local function formatClock(seconds)
	local total = math.max(0, math.ceil(seconds or 0))
	return string.format("%d:%02d", math.floor(total / 60), total % 60)
end

local function formatSeconds(seconds)
	return tostring(math.max(0, math.ceil(seconds or 0)))
end

local gui = Instance.new("ScreenGui")
gui.Name = "CoinRushUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 10
gui.Parent = playerGui

local backdrop = Instance.new("Frame")
backdrop.Name = "Backdrop"
backdrop.Size = UDim2.fromScale(1, 1)
backdrop.BackgroundColor3 = COLORS.bgTop
backdrop.BackgroundTransparency = 0.45
backdrop.BorderSizePixel = 0
backdrop.ZIndex = 1
backdrop.Parent = gui

local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, COLORS.bgTop),
	ColorSequenceKeypoint.new(1, COLORS.bgBottom),
})
gradient.Rotation = 90
gradient.Parent = backdrop

local glowA = Instance.new("Frame")
glowA.AnchorPoint = Vector2.new(0.5, 0.5)
glowA.Position = UDim2.fromScale(0.12, 0.16)
glowA.Size = UDim2.fromOffset(380, 380)
glowA.BackgroundColor3 = COLORS.purple
glowA.BackgroundTransparency = 0.88
glowA.BorderSizePixel = 0
glowA.ZIndex = 2
addCorner(glowA, 9999)
glowA.Parent = backdrop

local glowB = Instance.new("Frame")
glowB.AnchorPoint = Vector2.new(0.5, 0.5)
glowB.Position = UDim2.fromScale(0.9, 0.88)
glowB.Size = UDim2.fromOffset(320, 320)
glowB.BackgroundColor3 = COLORS.gold
glowB.BackgroundTransparency = 0.92
glowB.BorderSizePixel = 0
glowB.ZIndex = 2
addCorner(glowB, 9999)
glowB.Parent = backdrop

local startScreen = Instance.new("Frame")
startScreen.Name = "StartScreen"
startScreen.Size = UDim2.fromScale(1, 1)
startScreen.BackgroundTransparency = 1
startScreen.BorderSizePixel = 0
startScreen.ZIndex = 5
startScreen.Parent = gui

local startCard, startScale = makeCard(startScreen)

makeLabel(startCard, {
	LayoutOrder = 1,
	Name = "Tag",
	Size = UDim2.new(1, 0, 0, 16),
	Font = BOLD_FONT,
	TextSize = 12,
	TextColor3 = COLORS.gold,
	Text = "MINI GAME  \u{00B7}  60 DETIK",
})

makeLabel(startCard, {
	LayoutOrder = 2,
	Name = "Title",
	Size = UDim2.new(1, 0, 0, 56),
	Font = TITLE_FONT,
	TextSize = 42,
	TextColor3 = COLORS.gold,
	Text = "Coin Rush",
})

makeLabel(startCard, {
	LayoutOrder = 3,
	Name = "Subtitle",
	Size = UDim2.new(1, 0, 0, 42),
	Font = BODY_FONT,
	TextSize = 15,
	TextColor3 = COLORS.muted,
	TextWrapped = true,
	TextYAlignment = Enum.TextYAlignment.Top,
	Text = "Kumpulkan coin sebanyak mungkin sebelum waktu 60 detik habis.",
})

local startSpacer = Instance.new("Frame")
startSpacer.LayoutOrder = 4
startSpacer.Size = UDim2.new(1, 0, 0, 4)
startSpacer.BackgroundTransparency = 1
startSpacer.Parent = startCard

local playButton = makeButton(startCard, "Play", 5)

local startCountdown = makeLabel(startCard, {
	LayoutOrder = 6,
	Name = "Countdown",
	Size = UDim2.new(1, 0, 0, 18),
	Font = BOLD_FONT,
	TextSize = 13,
	TextColor3 = COLORS.muted,
	Text = "Bersiap...",
})

makeLabel(startCard, {
	LayoutOrder = 7,
	Name = "Footnote",
	Size = UDim2.new(1, 0, 0, 30),
	Font = BODY_FONT,
	TextSize = 12,
	TextColor3 = COLORS.muted,
	TextTransparency = 0.15,
	TextWrapped = true,
	Text = "Kamu otomatis masuk arena saat ronde dimulai.",
})

local hud = Instance.new("Frame")
hud.Name = "HUD"
hud.Size = UDim2.fromScale(1, 1)
hud.BackgroundTransparency = 1
hud.BorderSizePixel = 0
hud.Visible = false
hud.ZIndex = 10
hud.Parent = gui

local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.AnchorPoint = Vector2.new(0.5, 0)
topBar.Position = UDim2.new(0.5, 0, 0, 54)
topBar.Size = UDim2.new(0, 0, 0, 56)
topBar.AutomaticSize = Enum.AutomaticSize.X
topBar.BackgroundTransparency = 1
topBar.BorderSizePixel = 0
topBar.Parent = hud
addList(topBar, Enum.FillDirection.Horizontal, 12)

local function makePill(labelText, layoutOrder)
	local pill = Instance.new("Frame")
	pill.Name = labelText .. "Pill"
	pill.LayoutOrder = layoutOrder
	pill.Size = UDim2.new(0, 0, 0, 56)
	pill.AutomaticSize = Enum.AutomaticSize.X
	pill.BackgroundColor3 = COLORS.panel
	pill.BackgroundTransparency = 0.08
	pill.BorderSizePixel = 0
	addCorner(pill, 16)
	local stroke = addStroke(pill, COLORS.gold, 1, 0.7)
	addPadding(pill, 10, 18, 10, 18)
	addList(pill, Enum.FillDirection.Horizontal, 10)

	local label = makeLabel(pill, {
		LayoutOrder = 1,
		Name = "Caption",
		Size = UDim2.new(0, 0, 0, 16),
		AutomaticSize = Enum.AutomaticSize.X,
		Font = BOLD_FONT,
		TextSize = 12,
		TextColor3 = COLORS.muted,
		Text = labelText,
	})

	local value = makeLabel(pill, {
		LayoutOrder = 2,
		Name = "Value",
		Size = UDim2.new(0, 0, 0, 30),
		AutomaticSize = Enum.AutomaticSize.X,
		Font = TITLE_FONT,
		TextSize = 24,
		TextColor3 = COLORS.gold,
		Text = "0",
	})

	local scale = Instance.new("UIScale")
	scale.Parent = pill

	pill.Parent = topBar
	return pill, value, stroke, scale
end

local scorePill, scoreValue, scoreStroke, scoreScale = makePill("SKOR", 1)
local comboPill, comboValue, comboStroke, comboScale = makePill("KOMBO", 2)
local timerPill, timerValue, timerStroke, timerScale = makePill("WAKTU", 3)
local bestPill, bestValue, bestStroke, bestScale = makePill("TERBAIK", 4)
timerValue.Text = "1:00"
scoreValue.Text = "0"
comboValue.Text = "x1"
bestValue.Text = "0"

local hint = Instance.new("TextLabel")
hint.Name = "Hint"
hint.AnchorPoint = Vector2.new(0.5, 1)
hint.Position = UDim2.new(0.5, 0, 1, -30)
hint.Size = UDim2.new(0, 0, 0, 34)
hint.AutomaticSize = Enum.AutomaticSize.X
hint.BackgroundColor3 = COLORS.panel
hint.BackgroundTransparency = 0.25
hint.BorderSizePixel = 0
hint.Font = BOLD_FONT
hint.TextSize = 14
hint.TextColor3 = COLORS.text
hint.Text = "Kejar coin emas di arena!"
hint.Visible = false
addCorner(hint, 17)
addPadding(hint, 7, 18, 7, 18)
hint.Parent = hud

local speedLabel = Instance.new("TextLabel")
speedLabel.Name = "Speed"
speedLabel.AnchorPoint = Vector2.new(0.5, 0)
speedLabel.Position = UDim2.new(0.5, 0, 0, 120)
speedLabel.Size = UDim2.new(0, 0, 0, 26)
speedLabel.AutomaticSize = Enum.AutomaticSize.X
speedLabel.BackgroundColor3 = Color3.fromRGB(22, 46, 34)
speedLabel.BackgroundTransparency = 0.15
speedLabel.BorderSizePixel = 0
speedLabel.Font = TITLE_FONT
speedLabel.TextSize = 16
speedLabel.TextColor3 = Color3.fromRGB(80, 200, 120)
speedLabel.Text = "SPEED!"
speedLabel.Visible = false
addCorner(speedLabel, 13)
addPadding(speedLabel, 4, 14, 4, 14)
speedLabel.Parent = hud

local endScreen = Instance.new("Frame")
endScreen.Name = "EndScreen"
endScreen.Size = UDim2.fromScale(1, 1)
endScreen.BackgroundTransparency = 1
endScreen.BorderSizePixel = 0
endScreen.Visible = false
endScreen.ZIndex = 6
endScreen.Parent = gui

local endCard, endScale = makeCard(endScreen)

makeLabel(endCard, {
	LayoutOrder = 1,
	Name = "Tag",
	Size = UDim2.new(1, 0, 0, 16),
	Font = BOLD_FONT,
	TextSize = 12,
	TextColor3 = COLORS.muted,
	Text = "RONDE SELESAI",
})

makeLabel(endCard, {
	LayoutOrder = 2,
	Name = "Title",
	Size = UDim2.new(1, 0, 0, 44),
	Font = TITLE_FONT,
	TextSize = 34,
	TextColor3 = COLORS.gold,
	Text = "Waktu Habis",
})

makeLabel(endCard, {
	LayoutOrder = 3,
	Name = "ScoreCaption",
	Size = UDim2.new(1, 0, 0, 16),
	Font = BOLD_FONT,
	TextSize = 12,
	TextColor3 = COLORS.muted,
	Text = "SKOR KAMU",
})

local ownScoreValue = makeLabel(endCard, {
	LayoutOrder = 4,
	Name = "OwnScore",
	Size = UDim2.new(1, 0, 0, 56),
	Font = TITLE_FONT,
	TextSize = 48,
	TextColor3 = COLORS.text,
	Text = "0",
})

local divider = Instance.new("Frame")
divider.LayoutOrder = 5
divider.Size = UDim2.new(1, 0, 0, 1)
divider.BackgroundColor3 = COLORS.muted
divider.BackgroundTransparency = 0.8
divider.BorderSizePixel = 0
divider.Parent = endCard

makeLabel(endCard, {
	LayoutOrder = 6,
	Name = "BoardCaption",
	Size = UDim2.new(1, 0, 0, 16),
	Font = BOLD_FONT,
	TextSize = 12,
	TextColor3 = COLORS.muted,
	Text = "PAPAN SKOR",
})

local board = Instance.new("Frame")
board.Name = "Board"
board.LayoutOrder = 7
board.Size = UDim2.new(1, 0, 0, 0)
board.AutomaticSize = Enum.AutomaticSize.Y
board.BackgroundTransparency = 1
board.BorderSizePixel = 0
board.Parent = endCard

local boardLayout = Instance.new("UIListLayout")
boardLayout.FillDirection = Enum.FillDirection.Vertical
boardLayout.Padding = UDim.new(0, 6)
boardLayout.SortOrder = Enum.SortOrder.LayoutOrder
boardLayout.Parent = board

local mainLagiButton = makeButton(endCard, "Main Lagi", 8)

local endStatus = makeLabel(endCard, {
	LayoutOrder = 9,
	Name = "Status",
	Size = UDim2.new(1, 0, 0, 18),
	Font = BODY_FONT,
	TextSize = 12,
	TextColor3 = COLORS.muted,
	Text = "Ronde baru akan segera dimulai",
})

local waiting = Instance.new("Frame")
waiting.Name = "Waiting"
waiting.AnchorPoint = Vector2.new(0.5, 0)
waiting.Position = UDim2.new(0.5, 0, 0, 54)
waiting.Size = UDim2.new(0, 0, 0, 44)
waiting.AutomaticSize = Enum.AutomaticSize.X
waiting.BackgroundColor3 = COLORS.panel
waiting.BackgroundTransparency = 0.08
waiting.BorderSizePixel = 0
waiting.Visible = false
waiting.ZIndex = 12
addCorner(waiting, 22)
addStroke(waiting, COLORS.gold, 1, 0.55)
addPadding(waiting, 8, 20, 8, 20)

local waitingLabel = makeLabel(waiting, {
	Name = "Text",
	Size = UDim2.new(0, 0, 0, 24),
	AutomaticSize = Enum.AutomaticSize.X,
	Font = BOLD_FONT,
	TextSize = 14,
	TextColor3 = COLORS.text,
	Text = "Menunggu ronde dimulai...",
})

waiting.Parent = gui

local currentScore = 0
local currentCombo = 1
local bestScore = 0
local timerUrgent = false
local lobbySeconds = nil
local awaitingNextRound = false
local hintToken = 0
local speedToken = 0

local function setTimer(seconds)
	if type(seconds) ~= "number" then
		return
	end
	local urgent = seconds <= 10
	timerUrgent = urgent
	timerValue.Text = formatClock(seconds)
	timerValue.TextColor3 = urgent and COLORS.danger or COLORS.gold
	timerPill.BackgroundColor3 = urgent and COLORS.dangerPanel or COLORS.panel
	timerStroke.Color = urgent and COLORS.danger or COLORS.gold
	timerStroke.Transparency = urgent and 0.35 or 0.7
end

local function setScore(score, animate)
	currentScore = score
	scoreValue.Text = tostring(score)
	if animate then
		scoreScale.Scale = 1.12
		TweenService:Create(scoreScale, TweenInfo.new(0.24, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	end
end

local function setCombo(combo)
	combo = math.clamp(combo, 1, 5)
	local increased = combo > currentCombo
	currentCombo = combo
	comboValue.Text = "x" .. combo
	if increased then
		comboScale.Scale = 1.25
		TweenService:Create(comboScale, TweenInfo.new(0.24, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	end
end

local function showCoinPopup(value)
	if type(value) ~= "number" then
		return
	end
	local character = player.Character
	local head = character and (character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart"))
	if not head then
		return
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "CoinPopup"
	billboard.AlwaysOnTop = true
	billboard.Size = UDim2.fromOffset(120, 44)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.Adornee = head
	billboard.Parent = head

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = TITLE_FONT
	label.TextSize = 24
	label.TextColor3 = COLORS.gold
	label.TextStrokeTransparency = 0.4
	label.TextStrokeColor3 = Color3.fromRGB(60, 40, 0)
	label.Text = "+" .. tostring(value)
	label.Parent = billboard

	TweenService:Create(billboard, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		StudsOffset = Vector3.new(0, 6, 0),
	}):Play()
	TweenService:Create(label, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	}):Play()
	task.delay(0.65, function()
		billboard:Destroy()
	end)
end

local function setSpeedActive(active, duration)
	speedToken += 1
	local token = speedToken
	if not active then
		speedLabel.Visible = false
		return
	end
	speedLabel.Visible = true
	task.delay(duration or 5, function()
		if token == speedToken then
			speedLabel.Visible = false
		end
	end)
end

RunService.RenderStepped:Connect(function()
	if timerUrgent then
		timerScale.Scale = 1 + math.sin(os.clock() * 9) * 0.06
	elseif timerScale.Scale ~= 1 then
		timerScale.Scale = 1
	end
end)

local function updateStartCountdown()
	if lobbySeconds then
		startCountdown.Text = "Ronde dimulai dalam " .. formatSeconds(lobbySeconds) .. " detik"
	else
		startCountdown.Text = "Bersiap..."
	end
end

local function updateWaitingText()
	if lobbySeconds then
		waitingLabel.Text = "Ronde dimulai dalam " .. formatSeconds(lobbySeconds) .. " detik"
	else
		waitingLabel.Text = "Menunggu ronde dimulai..."
	end
end

local function showStart()
	backdrop.Visible = true
	startScreen.Visible = true
	endScreen.Visible = false
	hud.Visible = false
	waiting.Visible = false
	updateStartCountdown()
	pop(startScale)
end

local function showWaiting()
	backdrop.Visible = true
	startScreen.Visible = false
	endScreen.Visible = false
	hud.Visible = false
	waiting.Visible = true
	updateWaitingText()
end

local function showHint()
	hintToken = hintToken + 1
	local token = hintToken
	hint.Visible = true
	hint.TextTransparency = 0
	hint.BackgroundTransparency = 0.25
	task.delay(4, function()
		if token ~= hintToken then
			return
		end
		local fade = TweenInfo.new(0.4)
		TweenService:Create(hint, fade, { TextTransparency = 1, BackgroundTransparency = 1 }):Play()
		task.wait(0.45)
		if token == hintToken then
			hint.Visible = false
		end
	end)
end

local function showHud(score, seconds)
	setScore(score or 0, false)
	setTimer(seconds or 60)
	setCombo(1)
	speedToken += 1
	speedLabel.Visible = false
	backdrop.Visible = false
	startScreen.Visible = false
	endScreen.Visible = false
	waiting.Visible = false
	hud.Visible = true
	showHint()
end

local function rowFor(entry, index)
	local isLeader = index == 1
	local row = Instance.new("Frame")
	row.Name = "Row" .. index
	row.LayoutOrder = index
	row.Size = UDim2.new(1, 0, 0, 40)
	row.BackgroundColor3 = isLeader and COLORS.gold or Color3.fromRGB(255, 255, 255)
	row.BackgroundTransparency = isLeader and 0.86 or 0.94
	row.BorderSizePixel = 0
	addCorner(row, 10)

	makeLabel(row, {
		Name = "Rank",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 12, 0.5, 0),
		Size = UDim2.new(0, 26, 0, 20),
		Font = TITLE_FONT,
		TextSize = 15,
		TextColor3 = isLeader and COLORS.gold or COLORS.muted,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = tostring(index),
	})

	makeLabel(row, {
		Name = "PlayerName",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 46, 0.5, 0),
		Size = UDim2.new(1, -112, 0, 20),
		Font = BOLD_FONT,
		TextSize = 14,
		TextColor3 = COLORS.text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Text = tostring(entry.name or "Pemain"),
	})

	makeLabel(row, {
		Name = "Score",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.new(0, 70, 0, 20),
		Font = TITLE_FONT,
		TextSize = 16,
		TextColor3 = isLeader and COLORS.gold or COLORS.goldSoft,
		TextXAlignment = Enum.TextXAlignment.Right,
		Text = tostring(entry.score or 0),
	})

	return row
end

local function rebuildBoard(top)
	for _, child in ipairs(board:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	if type(top) ~= "table" or #top == 0 then
		local empty = makeLabel(board, {
			Name = "Empty",
			LayoutOrder = 1,
			Size = UDim2.new(1, 0, 0, 32),
			Font = BODY_FONT,
			TextSize = 14,
			TextColor3 = COLORS.muted,
			Text = "Belum ada skor yang tercatat.",
		})
		empty.Parent = board
		return
	end

	for index = 1, math.min(5, #top) do
		local entry = top[index]
		if type(entry) == "table" then
			rowFor(entry, index).Parent = board
		end
	end
end

local function showEnd(top)
	rebuildBoard(top)
	ownScoreValue.Text = tostring(currentScore)
	if currentScore > bestScore then
		bestScore = currentScore
	end
	bestValue.Text = tostring(bestScore)
	speedToken += 1
	speedLabel.Visible = false
	backdrop.Visible = true
	startScreen.Visible = false
	hud.Visible = false
	waiting.Visible = false
	endScreen.Visible = true
	pop(endScale)
end

playButton.MouseButton1Click:Connect(function()
	awaitingNextRound = true
	showWaiting()
end)

mainLagiButton.MouseButton1Click:Connect(function()
	awaitingNextRound = true
	showWaiting()
end)

coinCollected.OnClientEvent:Connect(function(payload)
	if type(payload) ~= "table" then
		return
	end
	if type(payload.score) == "number" then
		setScore(payload.score, true)
	end
	if type(payload.combo) == "number" then
		setCombo(payload.combo)
	end
	if type(payload.value) == "number" then
		showCoinPopup(payload.value)
	end
	coinSound.TimePosition = 0
	coinSound:Play()
end)

roundState.OnClientEvent:Connect(function(payload)
	if type(payload) ~= "table" then
		return
	end

	local kind = payload.kind
	if kind == "LOBBY_TICK" then
		if type(payload.seconds) == "number" then
			lobbySeconds = payload.seconds
		end
		if startScreen.Visible then
			updateStartCountdown()
		end
		if waiting.Visible then
			updateWaitingText()
		end
		return
	end

	if kind == "LOBBY" then
		setScore(0, false)
		lobbySeconds = type(payload.seconds) == "number" and payload.seconds or nil
		if awaitingNextRound then
			showWaiting()
		else
			showStart()
		end
		return
	end

	if kind == "START" then
		awaitingNextRound = false
		lobbySeconds = nil
		showHud(payload.score, payload.seconds)
		return
	end

	if kind == "TICK" then
		lobbySeconds = nil
		setTimer(payload.seconds)
		return
	end

	if kind == "POWERUP" then
		setSpeedActive(payload.active == true, payload.duration)
		return
	end

	if kind == "END" then
		awaitingNextRound = false
		lobbySeconds = nil
		showEnd(payload.top)
	end
end)

updateStartCountdown()
showStart()
