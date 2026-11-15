local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local roundState = remotes:WaitForChild("RoundState")
local coinCollected = remotes:WaitForChild("CoinCollected")

local BASE_FOV = 70
local shakeUntil = 0
local fovToken = 0
local lastCombo = 0
local trailParts = nil

local function shakeCamera()
	shakeUntil = os.clock() + 0.15
end

local function pulseFov()
	fovToken += 1
	local token = fovToken
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	camera.FieldOfView = BASE_FOV
	TweenService:Create(camera, TweenInfo.new(0.2), { FieldOfView = 78 }):Play()
	task.delay(0.2, function()
		if token ~= fovToken then
			return
		end
		local currentCamera = workspace.CurrentCamera
		if currentCamera then
			TweenService:Create(currentCamera, TweenInfo.new(0.2), { FieldOfView = BASE_FOV }):Play()
		end
	end)
end

local function clearTrail()
	if not trailParts then
		return
	end
	if trailParts.trail and trailParts.trail.Parent then
		trailParts.trail:Destroy()
	end
	for _, attachment in ipairs(trailParts.attachments) do
		if attachment.Parent then
			attachment:Destroy()
		end
	end
	trailParts = nil
end

local function attachTrail()
	clearTrail()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end

	local topAttachment = Instance.new("Attachment")
	topAttachment.Name = "CoinRushTrailTop"
	topAttachment.Position = Vector3.new(0, 0.6, 0)
	topAttachment.Parent = root

	local bottomAttachment = Instance.new("Attachment")
	bottomAttachment.Name = "CoinRushTrailBottom"
	bottomAttachment.Position = Vector3.new(0, -0.6, 0)
	bottomAttachment.Parent = root

	local trail = Instance.new("Trail")
	trail.Name = "CoinRushSpeedTrail"
	trail.Attachment0 = topAttachment
	trail.Attachment1 = bottomAttachment
	trail.Color = ColorSequence.new(Color3.fromRGB(80, 200, 120))
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.3, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	trail.Lifetime = 0.4
	trail.LightEmission = 1
	trail.Parent = root

	trailParts = {
		trail = trail,
		attachments = { topAttachment, bottomAttachment },
	}
end

player.CharacterAdded:Connect(function()
	clearTrail()
end)

coinCollected.OnClientEvent:Connect(function(payload)
	if type(payload) ~= "table" then
		return
	end
	shakeCamera()
	local combo = type(payload.combo) == "number" and payload.combo or 1
	if combo >= 2 and combo > lastCombo then
		pulseFov()
	end
	lastCombo = combo
end)

roundState.OnClientEvent:Connect(function(payload)
	if type(payload) ~= "table" then
		return
	end
	if payload.kind == "START" then
		lastCombo = 0
		clearTrail()
	elseif payload.kind == "POWERUP" then
		if payload.active == true then
			attachTrail()
		else
			clearTrail()
		end
	end
end)

RunService:BindToRenderStep("CoinRushCameraShake", Enum.RenderPriority.Camera.Value + 1, function()
	if os.clock() >= shakeUntil then
		return
	end
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local offset = Vector3.new((math.random() - 0.5) * 0.25, (math.random() - 0.5) * 0.25, 0)
	camera.CFrame = camera.CFrame * CFrame.new(offset)
end)
