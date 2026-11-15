local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local roundState = remotes:WaitForChild("RoundState")
local coinCollected = remotes:WaitForChild("CoinCollected")

local LOBBY_SECONDS = 10
local ROUND_SECONDS = 60
local INTERMISSION_SECONDS = 8
local COIN_TARGET = 24
local COIN_VALUE = 1
local ARENA_HALF = 36
local FLOOR_TOP = 1
local COIN_RADIUS = 2.5
local SPAWN_POSITION = Vector3.new(0, FLOOR_TOP + 4, ARENA_HALF - 8)

local phase = "LOBBY"
local phaseEndsAt = os.clock() + LOBBY_SECONDS
local scores = {}
local arenaFolder
local coinFolder
local obstacleParts = {}
local spawnLocation
local maintainCoins

local function broadcast(payload)
	roundState:FireAllClients(payload)
end

local function secondsLeft()
	if phase == "PLAYING" then
		return math.max(0, phaseEndsAt - os.clock())
	end
	return 0
end

local function lobbyLeft()
	return math.max(0, phaseEndsAt - os.clock())
end

local function makePart(props)
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	for key, value in pairs(props) do
		part[key] = value
	end
	return part
end

local function clearPreviousArena()
	local baseplate = workspace:FindFirstChild("Baseplate")
	if baseplate then
		baseplate:Destroy()
	end
	for _, name in ipairs({ "CoinRushArena", "CoinRushCoins", "CoinRushSpawn" }) do
		local existing = workspace:FindFirstChild(name)
		if existing then
			existing:Destroy()
		end
	end
end

local function buildArena()
	arenaFolder = Instance.new("Folder")
	arenaFolder.Name = "CoinRushArena"

	local floor = makePart({
		Name = "Platform",
		Size = Vector3.new(ARENA_HALF * 2 + 8, 2, ARENA_HALF * 2 + 8),
		Position = Vector3.new(0, FLOOR_TOP - 1, 0),
		Color = Color3.fromRGB(24, 22, 40),
		Material = Enum.Material.SmoothPlastic,
	})
	floor.Parent = arenaFolder

	local underlay = makePart({
		Name = "PlatformBase",
		Size = Vector3.new(ARENA_HALF * 2 - 2, 8, ARENA_HALF * 2 - 2),
		Position = Vector3.new(0, FLOOR_TOP - 5, 0),
		Color = Color3.fromRGB(14, 12, 26),
		Material = Enum.Material.SmoothPlastic,
	})
	underlay.Parent = arenaFolder

	local edgeColor = Color3.fromRGB(255, 199, 39)
	local gridColor = Color3.fromRGB(64, 54, 102)
	for index = -3, 3 do
		local offset = index * 12
		local lineZ = makePart({
			Name = "GridLine",
			Size = Vector3.new(0.12, 0.06, ARENA_HALF * 2),
			Position = Vector3.new(offset, FLOOR_TOP + 0.03, 0),
			Color = gridColor,
			Material = Enum.Material.SmoothPlastic,
		})
		lineZ.CanCollide = false
		lineZ.Parent = arenaFolder

		local lineX = makePart({
			Name = "GridLine",
			Size = Vector3.new(ARENA_HALF * 2, 0.06, 0.12),
			Position = Vector3.new(0, FLOOR_TOP + 0.03, offset),
			Color = gridColor,
			Material = Enum.Material.SmoothPlastic,
		})
		lineX.CanCollide = false
		lineX.Parent = arenaFolder
	end

	local edgeDefs = {
		{ Vector3.new(0, FLOOR_TOP + 0.05, ARENA_HALF - 0.4), Vector3.new(ARENA_HALF * 2, 0.1, 0.8) },
		{ Vector3.new(0, FLOOR_TOP + 0.05, -ARENA_HALF + 0.4), Vector3.new(ARENA_HALF * 2, 0.1, 0.8) },
		{ Vector3.new(ARENA_HALF - 0.4, FLOOR_TOP + 0.05, 0), Vector3.new(0.8, 0.1, ARENA_HALF * 2) },
		{ Vector3.new(-ARENA_HALF + 0.4, FLOOR_TOP + 0.05, 0), Vector3.new(0.8, 0.1, ARENA_HALF * 2) },
	}
	for index, def in ipairs(edgeDefs) do
		local edge = makePart({
			Name = "Edge" .. index,
			Position = def[1],
			Size = def[2],
			Color = edgeColor,
			Material = Enum.Material.SmoothPlastic,
		})
		edge.CanCollide = false
		edge.Parent = arenaFolder
	end

	local wallColor = Color3.fromRGB(45, 38, 74)
	local wallDefs = {
		{ Vector3.new(0, 4, ARENA_HALF + 2), Vector3.new(ARENA_HALF * 2 + 8, 8, 2) },
		{ Vector3.new(0, 4, -ARENA_HALF - 2), Vector3.new(ARENA_HALF * 2 + 8, 8, 2) },
		{ Vector3.new(ARENA_HALF + 2, 4, 0), Vector3.new(2, 8, ARENA_HALF * 2 + 8) },
		{ Vector3.new(-ARENA_HALF - 2, 4, 0), Vector3.new(2, 8, ARENA_HALF * 2 + 8) },
	}
	for index, def in ipairs(wallDefs) do
		local wall = makePart({
			Name = "Wall" .. index,
			Position = def[1],
			Size = def[2],
			Color = wallColor,
			Material = Enum.Material.SmoothPlastic,
		})
		wall.Parent = arenaFolder

		local rim = makePart({
			Name = "Rim" .. index,
			Position = def[1] + Vector3.new(0, def[2].Y / 2 + 0.15, 0),
			Size = Vector3.new(def[2].X + 0.4, 0.3, def[2].Z + 0.4),
			Color = edgeColor,
			Material = Enum.Material.SmoothPlastic,
		})
		rim.CanCollide = false
		rim.Parent = arenaFolder
	end

	for _, xSign in ipairs({ -1, 1 }) do
		for _, zSign in ipairs({ -1, 1 }) do
			local position = Vector3.new(xSign * (ARENA_HALF - 2), FLOOR_TOP + 5, zSign * (ARENA_HALF - 2))
			local pillar = makePart({
				Name = "Pillar",
				Size = Vector3.new(3, 10, 3),
				Position = position,
				Color = wallColor,
				Material = Enum.Material.SmoothPlastic,
			})
			pillar.Parent = arenaFolder

			local cap = makePart({
				Name = "PillarLight",
				Size = Vector3.new(3.6, 0.4, 3.6),
				Position = position + Vector3.new(0, 5.2, 0),
				Color = edgeColor,
				Material = Enum.Material.SmoothPlastic,
			})
			cap.CanCollide = false
			cap.Parent = arenaFolder

			local light = Instance.new("PointLight")
			light.Color = edgeColor
			light.Range = 22
			light.Brightness = 1.4
			light.Shadows = false
			light.Parent = cap
		end
	end

	local obstacleDefs = {
		{ Vector3.new(0, FLOOR_TOP + 2.5, -12), Vector3.new(18, 5, 3) },
		{ Vector3.new(-18, FLOOR_TOP + 2.5, 12), Vector3.new(3, 5, 16) },
		{ Vector3.new(18, FLOOR_TOP + 2.5, 12), Vector3.new(12, 5, 3) },
		{ Vector3.new(0, FLOOR_TOP + 3, 4), Vector3.new(6, 6, 6) },
	}
	for index, def in ipairs(obstacleDefs) do
		local obstacle = makePart({
			Name = "Obstacle" .. index,
			Position = def[1],
			Size = def[2],
			Color = Color3.fromRGB(88, 66, 158),
			Material = Enum.Material.SmoothPlastic,
		})
		obstacle.Parent = arenaFolder
		table.insert(obstacleParts, obstacle)

		local trim = makePart({
			Name = "Trim",
			Position = def[1] + Vector3.new(0, def[2].Y / 2 + 0.12, 0),
			Size = Vector3.new(def[2].X + 0.3, 0.25, def[2].Z + 0.3),
			Color = edgeColor,
			Material = Enum.Material.SmoothPlastic,
		})
		trim.CanCollide = false
		trim.Parent = obstacle
	end

	spawnLocation = Instance.new("SpawnLocation")
	spawnLocation.Name = "CoinRushSpawn"
	spawnLocation.Size = Vector3.new(8, 1, 8)
	spawnLocation.Position = Vector3.new(0, FLOOR_TOP + 0.5, ARENA_HALF - 8)
	spawnLocation.Anchored = true
	spawnLocation.CanCollide = false
	spawnLocation.CanQuery = false
	spawnLocation.Transparency = 1
	spawnLocation.Neutral = true
	spawnLocation.Enabled = true
	spawnLocation.Duration = 0
	spawnLocation.Parent = workspace

	arenaFolder.Parent = workspace
end

local function insideObstacle(position)
	for _, obstacle in ipairs(obstacleParts) do
		local half = obstacle.Size * 0.5
		if
			math.abs(position.X - obstacle.Position.X) < half.X + COIN_RADIUS
			and math.abs(position.Z - obstacle.Position.Z) < half.Z + COIN_RADIUS
		then
			return true
		end
	end
	return false
end

local function nearExistingCoin(position)
	for _, coin in ipairs(coinFolder:GetChildren()) do
		if (coin.Position - position).Magnitude < COIN_RADIUS * 1.5 then
			return true
		end
	end
	return false
end

local function randomCoinPosition()
	local limit = ARENA_HALF - 6
	for _ = 1, 24 do
		local position = Vector3.new(math.random(-limit, limit), FLOOR_TOP + 1.6, math.random(-limit, limit))
		if not insideObstacle(position) and not nearExistingCoin(position) then
			return position
		end
	end
	return nil
end

local function spawnCoin()
	if phase ~= "PLAYING" then
		return
	end
	local position = randomCoinPosition()
	if not position then
		return
	end

	local coin = makePart({
		Name = "Coin",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.45, 2.4, 2.4),
		CFrame = CFrame.new(position),
		Color = Color3.fromRGB(255, 190, 30),
		Reflectance = 0.15,
		Material = Enum.Material.Metal,
	})
	coin.CanCollide = false
	coin.CastShadow = false

	local glow = Instance.new("PointLight")
	glow.Color = Color3.fromRGB(255, 205, 90)
	glow.Range = 7
	glow.Brightness = 0.8
	glow.Shadows = false
	glow.Parent = coin

	local claimed = false
	coin.Touched:Connect(function(hit)
		if claimed or phase ~= "PLAYING" then
			return
		end
		local character = hit.Parent
		local player = character and Players:GetPlayerFromCharacter(character)
		if not player or player.Character ~= character then
			return
		end
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid or humanoid.Health <= 0 then
			return
		end

		claimed = true
		scores[player] = (scores[player] or 0) + COIN_VALUE
		coinCollected:FireClient(player, scores[player])
		coin:Destroy()

		task.defer(function()
			if phase == "PLAYING" then
				maintainCoins()
			end
		end)
	end)

	coin.Parent = coinFolder
end

maintainCoins = function()
	if phase ~= "PLAYING" then
		return
	end
	for _ = #coinFolder:GetChildren() + 1, COIN_TARGET do
		spawnCoin()
	end
end

local function topScores()
	local rows = {}
	for player, score in pairs(scores) do
		if player.Parent then
			table.insert(rows, { name = player.DisplayName, score = score })
		end
	end
	table.sort(rows, function(a, b)
		if a.score == b.score then
			return a.name < b.name
		end
		return a.score > b.score
	end)
	local out = {}
	for index = 1, math.min(5, #rows) do
		out[index] = rows[index]
	end
	return out
end

local function teleportToArena(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	root.CFrame = CFrame.lookAt(SPAWN_POSITION, Vector3.new(0, FLOOR_TOP + 3, 0))
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
end

local function startRound()
	phase = "PLAYING"
	phaseEndsAt = os.clock() + ROUND_SECONDS
	coinFolder:ClearAllChildren()
	for player in pairs(scores) do
		scores[player] = 0
	end
	for _, player in ipairs(Players:GetPlayers()) do
		scores[player] = 0
		teleportToArena(player)
	end
	maintainCoins()
	broadcast({ kind = "START", seconds = ROUND_SECONDS })
end

local function endRound()
	phase = "ENDED"
	coinFolder:ClearAllChildren()
	broadcast({ kind = "END", top = topScores() })
	task.delay(INTERMISSION_SECONDS, function()
		if phase ~= "ENDED" then
			return
		end
		phase = "LOBBY"
		phaseEndsAt = os.clock() + LOBBY_SECONDS
		for player in pairs(scores) do
			scores[player] = 0
		end
		broadcast({ kind = "LOBBY", seconds = LOBBY_SECONDS })
	end)
end

local function sendCurrentState(player)
	if phase == "LOBBY" then
		roundState:FireClient(player, { kind = "LOBBY", seconds = lobbyLeft() })
	elseif phase == "PLAYING" then
		roundState:FireClient(player, { kind = "START", seconds = secondsLeft(), score = scores[player] or 0 })
	else
		roundState:FireClient(player, { kind = "END", top = topScores() })
	end
end

local function onPlayerAdded(player)
	scores[player] = 0
	if spawnLocation and spawnLocation.Parent then
		player.RespawnLocation = spawnLocation
	end
	player.CharacterAdded:Connect(function()
		task.defer(teleportToArena, player)
	end)
	if player.Character then
		task.defer(teleportToArena, player)
	end
	sendCurrentState(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(function(player)
	scores[player] = nil
end)

clearPreviousArena()
buildArena()
coinFolder = Instance.new("Folder")
coinFolder.Name = "CoinRushCoins"
coinFolder.Parent = workspace

for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

while true do
	if phase == "LOBBY" then
		if os.clock() >= phaseEndsAt then
			startRound()
		else
			broadcast({ kind = "LOBBY_TICK", seconds = lobbyLeft() })
		end
	elseif phase == "PLAYING" then
		if os.clock() >= phaseEndsAt then
			endRound()
		else
			maintainCoins()
			broadcast({ kind = "TICK", seconds = secondsLeft() })
		end
	end
	task.wait(0.25)
end
