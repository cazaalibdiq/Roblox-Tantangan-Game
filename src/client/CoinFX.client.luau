local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local coinsFolder = workspace:WaitForChild("CoinRushCoins")
local coins = {}

local function spawnBurst(position)
	local burst = Instance.new("Part")
	burst.Name = "CoinBurst"
	burst.Anchored = true
	burst.CanCollide = false
	burst.CanQuery = false
	burst.CanTouch = false
	burst.Transparency = 1
	burst.Size = Vector3.new(0.2, 0.2, 0.2)
	burst.CFrame = CFrame.new(position)
	burst.Parent = workspace

	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dng"
	emitter.Rate = 0
	emitter.Lifetime = NumberRange.new(0.5)
	emitter.Speed = NumberRange.new(8, 14)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Color = ColorSequence.new(Color3.fromRGB(255, 205, 90))
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.4),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.LightEmission = 1
	emitter.Parent = burst
	emitter:Emit(18)

	task.delay(1, function()
		burst:Destroy()
	end)
end

local function track(coin)
	if not coin:IsA("BasePart") then
		return
	end
	local fullSize = coin.Size
	coin.Size = Vector3.new(0.05, 0.05, 0.05)
	TweenService:Create(coin, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = fullSize }):Play()

	local data = {
		position = coin.Position,
		angle = math.random() * math.pi * 2,
		spin = 2.6 + math.random() * 1.4,
		bob = 0.18 + math.random() * 0.12,
		collected = false,
	}
	coins[coin] = data

	coin.Touched:Connect(function(hit)
		if data.collected then
			return
		end
		local character = hit.Parent
		local player = character and Players:GetPlayerFromCharacter(character)
		if player ~= Players.LocalPlayer then
			return
		end
		data.collected = true
		spawnBurst(coin.Position)
	end)
end

for _, child in ipairs(coinsFolder:GetChildren()) do
	track(child)
end
coinsFolder.ChildAdded:Connect(track)
coinsFolder.ChildRemoved:Connect(function(coin)
	local data = coins[coin]
	coins[coin] = nil
	if data and not data.collected and coin:GetAttribute("Collected") == true then
		spawnBurst(data.position)
	end
end)

RunService.RenderStepped:Connect(function(deltaTime)
	for coin, data in pairs(coins) do
		if not coin.Parent then
			coins[coin] = nil
			continue
		end
		data.angle += deltaTime * data.spin
		local bobY = math.sin(data.angle * 1.7) * data.bob
		coin.CFrame = CFrame.new(data.position.X, data.position.Y + bobY, data.position.Z)
			* CFrame.Angles(0, data.angle, 0)
	end
end)
