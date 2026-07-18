if not game:IsLoaded() then
	game.Loaded:Wait()
end

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local ESP_ENABLED = true
local SCRIPT_ACTIVE = true
local connections = {}
local detectedParts = {}

-- ================= COLOR PROFILES =================
local COLOR_TOLERANCE = 5

local COLOR_PROFILES = {
	{
		name = "Ultimate",
		color = Color3.fromRGB(255, 100, 100),
		soundId = "rbxassetid://82845990304289",
		volume = 3.5,
	},
	{
		name = "Legend",
		color = Color3.fromRGB(255, 255, 100),
		soundId = "rbxassetid://107261392908541",
		volume = 3.0,
	},
	{
		name = "Epic",
		color = Color3.fromRGB(100, 255, 255),
		soundId = "rbxassetid://136655923047274",
		volume = 2,
	},
	{
		name = "Rare",
		color = Color3.fromRGB(228, 100, 255),
		soundId = "rbxassetid://136655923047274",
		volume = 2,
	},
	{
		name = "Cake",
		color = Color3.fromRGB(163, 162, 165),
		soundId = nil,
		volume = 0,
	},
}

local SPAWNS = {
	{ name = "Main",      x = 16,    z = -106 },
	{ name = "Downtown",  x = -597,  z = -465 },
	{ name = "Hilton",    x = 174,   z = 161 },
	{ name = "Office",    x = -1206, z = 815 },
	{ name = "Uptown",    x = -1137, z = -1765 },
	{ name = "Crest",     x = 381,   z = -1291 },
	{ name = "Vertex",    x = 1259,  z = 1026 },
	{ name = "Park",      x = 2558,  z = -1445 },
	{ name = "Arch",      x = 2043,  z = 198 },
	{ name = "Townside",  x = 2433,  z = 1616 },
	{ name = "Highrise",  x = 116,   z = 1961 },
	{ name = "Titan",     x = 1444,  z = 1738 },
	{ name = "Eastside",  x = 2764,  z = 3106 },
	{ name = "Lowrise",   x = 1860,  z = 4035 },
}

local CAKE_MIN_SIZE = 3 -- only show Cake ESP if part.Size.X is at least this
local UPDATE_INTERVAL = 0.2 -- throttle label/size refresh (seconds)

-- ==================================================

-- ---------- Logging ----------
local function log(fmt, ...)
	print(string.format("[ESP] " .. fmt, ...))
end

-- ---------- Spawn utils ----------
local function getNearestSpawnXZ(pos)
	local closest, bestDist

	for _, s in ipairs(SPAWNS) do
		local dx = pos.X - s.x
		local dz = pos.Z - s.z
		local dist = math.sqrt(dx * dx + dz * dz)

		if not bestDist or dist < bestDist then
			bestDist = dist
			closest = s.name
		end
	end

	return closest or "Unknown"
end

-- ---------- Color utils ----------
local function colorMatch(a, b)
	return math.abs(a.R * 255 - b.R * 255) <= COLOR_TOLERANCE
		and math.abs(a.G * 255 - b.G * 255) <= COLOR_TOLERANCE
		and math.abs(a.B * 255 - b.B * 255) <= COLOR_TOLERANCE
end

local function getProfile(color)
	for _, p in ipairs(COLOR_PROFILES) do
		if colorMatch(color, p.color) then
			return p
		end
	end
end

-- ---------- Sound ----------
local function playSound(id, volume)
	if not id then return end
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = volume or 2.8
	s.Parent = workspace
	s:Play()
	s.Ended:Once(function() s:Destroy() end)
end

-- ---------- Detection ----------
-- Color + Neon material only (no Shape/Ball check anymore)
local function isNeonSphere(p)
	if not p:IsA("BasePart") then return end
	if p.Material ~= Enum.Material.Neon then return end
	local profile = getProfile(p.Color)
	if not profile then return end
	if profile.name == "Cake" and p.Size.X < CAKE_MIN_SIZE then return end
	return profile
end

-- ---------- ESP ----------
local function createESP(part, profile)
	local bill = Instance.new("BillboardGui")
	bill.Name = "BallESP"
	bill.Size = UDim2.new(0, 250, 0, 80)
	bill.AlwaysOnTop = true
	bill.Adornee = part
	bill.Parent = part

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextColor3 = part.Color
	label.TextStrokeTransparency = 0
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = bill

	local lastUpdate = 0

	local conn
	conn = RunService.RenderStepped:Connect(function()
		if not ESP_ENABLED or not part.Parent then
			conn:Disconnect()
			return
		end

		local now = os.clock()
		if now - lastUpdate < UPDATE_INTERVAL then
			return
		end
		lastUpdate = now

		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hrp then return end

		local dist = (hrp.Position - part.Position).Magnitude
		local nearest = getNearestSpawnXZ(part.Position)

		if not SCRIPT_ACTIVE then
			conn:Disconnect()
			return
		end

		-- Scale label size down as distance increases
		local scale = math.clamp(1 - (dist / 400), 0.85, 1)
		bill.Size = UDim2.new(0, 230 * scale, 0, 80 * scale)

		if profile.name == "Cake" then
			-- size is uniform on X/Y/Z, so just show one value
			label.Text = string.format(
				"%s\n%.1f m\n%s\nSize: %.2f",
				profile.name,
				dist,
				nearest,
				part.Size.X
			)
		else
			label.Text = string.format(
				"%s\n%.1f m\n%s",
				profile.name,
				dist,
				nearest
			)
		end
	end)

	table.insert(connections, conn)
end

-- ---------- Detection handler (single part) ----------
local function handlePart(v)
	if detectedParts[v] then return end

	local profile = isNeonSphere(v)
	if not profile then return end

	detectedParts[v] = true
	createESP(v, profile)
	playSound(profile.soundId, profile.volume)

	log("Detected %s | pos=(%.1f, %.1f, %.1f) | nearest=%s",
		profile.name, v.Position.X, v.Position.Y, v.Position.Z,
		getNearestSpawnXZ(v.Position))
end

-- ---------- Initial scan (existing children only) ----------
local function initialScan()
	for _, v in ipairs(workspace.Map:GetChildren()) do
		handlePart(v)
	end
	log("Initial scan complete: %d children checked", #workspace.Map:GetChildren())
end

-- ---------- Toggle ----------
local function toggle()
	ESP_ENABLED = not ESP_ENABLED
	log("ESP %s", ESP_ENABLED and "ENABLED" or "DISABLED")

	if not ESP_ENABLED then
		for _, v in ipairs(workspace:GetChildren()) do
			local esp = v:FindFirstChild("BallESP")
			if esp then esp:Destroy() end
		end
		table.clear(detectedParts)
	end
end

-- ---------- Kill switch ----------
local inputConn

local function killScript()
	SCRIPT_ACTIVE = false
	ESP_ENABLED = false
	log("Kill switch triggered, shutting down")

	-- Disconnect everything tracked
	for _, c in ipairs(connections) do
		if c.Connected then c:Disconnect() end
	end
	table.clear(connections)

	-- Destroy any remaining ESP guis
	for _, v in ipairs(workspace:GetChildren()) do
		local esp = v:FindFirstChild("BallESP")
		if esp then esp:Destroy() end
	end
	table.clear(detectedParts)

	-- Stop listening for the toggle key
	if inputConn then
		inputConn:Disconnect()
		inputConn = nil
	end

	log("Script killed")
end

inputConn = UserInputService.InputBegan:Connect(function(i, gp)
	if gp then return end
	if i.KeyCode == Enum.KeyCode.K then
		toggle()
	elseif i.KeyCode == Enum.KeyCode.Delete then
		killScript()
	end
end)

-- ---------- Event-based scanning ----------
-- Only react to direct children of workspace.Map being added/removed,
-- not changes within those children's own descendants.
local mapAddedConn = workspace.Map.ChildAdded:Connect(function(v)
	if not SCRIPT_ACTIVE or not ESP_ENABLED then return end
	handlePart(v)
end)
table.insert(connections, mapAddedConn)

local mapRemovedConn = workspace.Map.ChildRemoved:Connect(function(v)
	if detectedParts[v] then
		detectedParts[v] = nil
		log("Removed from tracking: %s", v.Name)
	end
end)
table.insert(connections, mapRemovedConn)

log("Script started")
initialScan()
