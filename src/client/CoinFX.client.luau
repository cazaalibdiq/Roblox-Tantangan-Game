local RunService = game:GetService("RunService")

local coinsFolder = workspace:WaitForChild("CoinRushCoins")
local coins = {}

local function track(coin)
	if not coin:IsA("BasePart") then
		return
	end
	coins[coin] = {
		position = coin.Position,
		angle = math.random() * math.pi * 2,
		spin = 2.6 + math.random() * 1.4,
		bob = 0.18 + math.random() * 0.12,
	}
end

for _, child in ipairs(coinsFolder:GetChildren()) do
	track(child)
end
coinsFolder.ChildAdded:Connect(track)
coinsFolder.ChildRemoved:Connect(function(coin)
	coins[coin] = nil
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
