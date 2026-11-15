-- Coin Rush server: builds the arena, runs the 60 second round, spawns coins
-- and counts each player's score. The client draws every screen from the state
-- this script broadcasts on Remotes.RoundState.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local roundState = remotes:WaitForChild("RoundState")
local coinCollected = remotes:WaitForChild("CoinCollected")

local LOBBY_SECONDS = 10
local ROUND_SECONDS = 60
local COIN_TARGET = 24 -- coins kept alive in the arena
local COIN_VALUE = 1
local ARENA_HALF = 36 -- playable half-extent, walls sit just outside

local state = "LOBBY" -- LOBBY | PLAYING | ENDED
local lobbyEndsAt = os.clock() + LOBBY_SECONDS
local roundEndsAt = 0
local scores = {} -- [Player] = number
local arenaFolder
local coinFolder
local obstacleFolder

local function broadcast(payload)
	roundState:FireAllClients(payload)
end

local function secondsLeft()
	if state == "PLAYING" then
		return math.max(0, roundEndsAt - os.clock())
	end
	return 0
end

local function lobbyLeft()
	return math.max(0, lobbyEndsAt - os.clock())
end

-- Arena ---------------------------------------------------------------

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

local function buildArena()
	arenaFolder = Instance.new("Folder")
	arenaFolder.Name = "Arena"

	local floor = makePart({
		Name = "Floor",
		Size = Vector3.new(ARENA_HALF * 2 + 8, 1, ARENA_HALF * 2 + 8),
		Position = Vector3.new(0, 0, 0),
		Color = Color3.fromRGB(24, 22, 40),
		Material = Enum.Material.SmoothPlastic,
	})
	floor.Parent = arenaFolder

	-- Neon rim around the floor edge, so the arena reads at a glance.
	local rimColor = Color3.fromRGB(255, 199, 39)
	local wallColor = Color3.fromRGB(45, 38, 74)
	local wallDefs = {
		{ Vector3.new(0, 3, ARENA_HALF + 2), Vector3.new(ARENA_HALF * 2 + 8, 6, 2) },
		{ Vector3.new(0, 3, -ARENA_HALF - 2), Vector3.new(ARENA_HALF * 2 + 8, 6, 2) },
		{ Vector3.new(ARENA_HALF + 2, 3, 0), Vector3.new(2, 6, ARENA_HALF * 2 + 8) },
		{ Vector3.new(-ARENA_HALF - 2, 3, 0), Vector3.new(2, 6, ARENA_HALF * 2 + 8) },
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
	end

	-- Glowing rim strip on top of each wall.
	local stripDefs = {
		{ Vector3.new(0, 6.1, ARENA_HALF + 2), Vector3.new(ARENA_HALF * 2 + 8, 0.3, 2) },
		{ Vector3.new(0, 6.1, -ARENA_HALF - 2), Vector3.new(ARENA_HALF * 2 + 8, 0.3, 2) },
		{ Vector3.new(ARENA_HALF + 2, 6.1, 0), Vector3.new(2, 0.3, ARENA_HALF * 2 + 8) },
		{ Vector3.new(-ARENA_HALF - 2, 6.1, 0), Vector3.new(2, 0.3, ARENA_HALF * 2 + 8) },
	}
	for index, def in ipairs(stripDefs) do
		local strip = makePart({
			Name = "Rim" .. index,
			Position = def[1],
			Size = def[2],
			Color = rimColor,
			Material = Enum.Material.Neon,
		})
		strip.CanCollide = false
		strip.Parent = arenaFolder
	end

	arenaFolder.Parent = workspace
end

-- Obstacles: fixed blocks that slow a greedy route and break the arena up.
local function buildObstacles()
	obstacleFolder = Instance.new("Folder")
	obstacleFolder.Name = "Obstacles"
	local defs = {
		{ Vector3.new(-14, 2, -14), Vector3.new(10, 4, 3) },
		{ Vector3.new(14, 2, 14), Vector3.new(10, 4, 3) },
		{ Vector3.new(-14, 2, 14), Vector3.new(3, 4, 10) },
		{ Vector3.new(14, 2, -14), Vector3.new(3, 4, 10) },
		{ Vector3.new(0, 2, 0), Vector3.new(6, 4, 6) },
	}
	for index, def in ipairs(defs) do
		local block = makePart({
			Name = "Block" .. index,
			Position = def[1],
			Size = def[2],
			Color = Color3.fromRGB(88, 66, 158),
			Material = Enum.Material.SmoothPlastic,
		})
		local trim = makePart({
			Name = "Trim",
			Size = def[2] + Vector3.new(0.2, 0.25, 0.2),
			Position = def[1] + Vector3.new(0, def[2].Y / 2 + 0.1, 0),
			Color = Color3.fromRGB(255, 199, 39),
			Material = Enum.Material.Neon,
		})
		trim.CanCollide = false
		trim.Parent = block
		block.Parent = obstacleFolder
	end
	obstacleFolder.Parent = workspace
end

-- Coins ---------------------------------------------------------------

local coinSpots = {} -- positions where coins may spawn, kept off obstacles

local function buildCoinSpots()
	for x = -ARENA_HALF + 6, ARENA_HALF - 6, 6 do
		for z = -ARENA_HALF + 6, ARENA_HALF - 6, 6 do
			local clear = true
			for _, def in ipairs(obstacleFolder:GetChildren()) do
				if def:IsA("BasePart") then
					local half = def.Size / 2 + Vector3.new(2, 0, 2)
					local d = def.Position - Vector3.new(x, def.Position.Y, z)
					if math.abs(d.X) < half.X and math.abs(d.Z) < half.Z then
						clear = false
						break
					end
				end
			end
			if clear then
				table.insert(coinSpots, Vector3.new(x, 1.5, z))
			end
		end
	end
end

local function spawnCoin()
	if #coinSpots == 0 then
		return
	end
	local spot = coinSpots[math.random(#coinSpots)]
	local coin = makePart({
		Name = "Coin",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.6, 2.4, 2.4),
		CFrame = CFrame.new(spot) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(255, 199, 39),
		Material = Enum.Material.Neon,
	})
	coin.CanCollide = false
	local taken = false
	coin.Touched:Connect(function(hit)
		if taken or state ~= "PLAYING" then
			return
		end
		local character = hit.Parent
		local player = character and Players:GetPlayerFromCharacter(character)
		if not player or hit ~= character:FindFirstChild("HumanoidRootPart") then
			return
		end
		taken = true
		scores[player] = (scores[player] or 0) + COIN_VALUE
		coinCollected:FireClient(player, scores[player])
		coin:Destroy()
	end)
	coin.Parent = coinFolder
end

local function keepCoinsAlive()
	if state == "PLAYING" then
		local alive = #coinFolder:GetChildren()
		for _ = alive + 1, COIN_TARGET do
			spawnCoin()
		end
	end
end

-- Round loop ------------------------------------------------------------

local function topScores()
	local rows = {}
	for player, score in pairs(scores) do
		if player.Parent then
			table.insert(rows, { name = player.DisplayName, score = score })
		end
	end
	table.sort(rows, function(a, b)
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
	if root then
		root.CFrame = CFrame.new(0, 4, ARENA_HALF - 6)
	end
end

local function startRound()
	state = "PLAYING"
	roundEndsAt = os.clock() + ROUND_SECONDS
	coinFolder:ClearAllChildren()
	for _, player in ipairs(Players:GetPlayers()) do
		teleportToArena(player)
	end
	keepCoinsAlive()
	broadcast({ kind = "START", seconds = ROUND_SECONDS })
end

local function endRound()
	state = "ENDED"
	coinFolder:ClearAllChildren()
	broadcast({ kind = "END", top = topScores() })
	task.delay(8, function()
		if state ~= "ENDED" then
			return
		end
		state = "LOBBY"
		lobbyEndsAt = os.clock() + LOBBY_SECONDS
		for player in pairs(scores) do
			scores[player] = nil
		end
		broadcast({ kind = "LOBBY", seconds = LOBBY_SECONDS })
	end)
end

-- Player lifecycle ------------------------------------------------------

local function onPlayerAdded(player)
	scores[player] = 0
	if state == "PLAYING" then
		player.CharacterAdded:Connect(function()
			teleportToArena(player)
		end)
	end
	-- Tell the joining client where the round stands.
	if state == "LOBBY" then
		roundState:FireClient(player, { kind = "LOBBY", seconds = lobbyLeft() })
	elseif state == "PLAYING" then
		roundState:FireClient(player, { kind = "START", seconds = secondsLeft(), score = scores[player] or 0 })
	else
		roundState:FireClient(player, { kind = "END", top = topScores() })
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(function(player)
	scores[player] = nil
end)

buildArena()
buildObstacles()
buildCoinSpots()
coinFolder = Instance.new("Folder")
coinFolder.Name = "Coins"
coinFolder.Parent = workspace

for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

-- Heartbeat: drive the round timer and the lobby countdown.
while true do
	task.wait(0.25)
	if state == "LOBBY" then
		if os.clock() >= lobbyEndsAt then
			startRound()
		else
			broadcast({ kind = "LOBBY_TICK", seconds = lobbyLeft() })
		end
	elseif state == "PLAYING" then
		if os.clock() >= roundEndsAt then
			endRound()
		else
			keepCoinsAlive()
			broadcast({ kind = "TICK", seconds = secondsLeft() })
		end
	end
end
