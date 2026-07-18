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
local activeESP = {} -- Map child (v) -> { conn = RenderStepped connection, gui = BillboardGui }

-- ================= COLOR PROFILES =================
-- Exact color matching only (no tolerance).

-- Caches (neon ball parts directly under workspace.Map)
local CACHE_PROFILES = {
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
		volume = 2.5,
	},
	{
		name = "Cake",
		color = Color3.fromRGB(163, 162, 165),
		soundId = nil,
		volume = 0,
	},
}

-- Bags (Model instances under workspace.Map, rarity read from their "Side" part color)
local BAG_PROFILES = {
	{
		name = "Ultimate",
		color = Color3.fromRGB(0, 0, 0),
		soundId = "rbxassetid://82845990304289",
		volume = 3.5,
	},
	{
		name = "Legend",
		color = Color3.fromRGB(255, 244, 119),
		soundId = "rbxassetid://107261392908541",
		volume = 3.0,
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
-- Exact match (rounded to nearest integer to avoid float rounding noise from
-- Color3.fromRGB conversion). No tolerance window anymore.
local function colorMatch(a, b)
	local ar, ag, ab = math.floor(a.R * 255 + 0.5), math.floor(a.G * 255 + 0.5), math.floor(a.B * 255 + 0.5)
	local br, bg, bb = math.floor(b.R * 255 + 0.5), math.floor(b.G * 255 + 0.5), math.floor(b.B * 255 + 0.5)
	return ar == br and ag == bg and ab == bb
end

local function getProfile(color, profiles)
	for _, p in ipairs(profiles) do
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
	local profile = getProfile(p.Color, CACHE_PROFILES)
	if not profile then return end
	if profile.name == "Cake" and p.Size.X < CAKE_MIN_SIZE then return end
	return profile, p
end

-- Bags: className Model, rarity read from the "Main" part's Color.
local function isBagModel(v)
	if v.ClassName ~= "Model" then return end
	local main = v:FindFirstChild("Main")
	if not main or not main:IsA("BasePart") then return end
	local profile = getProfile(main.Color, BAG_PROFILES)
	if not profile then return end
	return profile, main
end

-- ---------- ESP ----------
-- `anchor` is the BasePart used for position/adornee/color (the ball itself,
-- or a bag's "Main" part). `mapChild` is the direct workspace.Map child that
-- was actually detected (needed so removal can be looked up on ChildRemoved).
local function createESP(anchor, profile, mapChild)
	local bill = Instance.new("BillboardGui")
	bill.Name = "BallESP"
	bill.Size = UDim2.new(0, 250, 0, 80)
	bill.AlwaysOnTop = true
	bill.Adornee = anchor
	bill.Parent = anchor

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextColor3 = anchor.Color
	label.TextStrokeTransparency = 0
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = bill

	-- No time-based throttle anymore: existence/cleanup is driven entirely by
	-- workspace.Map's ChildRemoved event (see mapRemovedConn below), not by
	-- polling here. This loop only keeps the label's live distance/position updated.
	local conn
	conn = RunService.RenderStepped:Connect(function()
		if not ESP_ENABLED then
			return
		end

		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hrp then return end

		local dist = (hrp.Position - anchor.Position).Magnitude
		local nearest = getNearestSpawnXZ(anchor.Position)

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
				anchor.Size.X
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
	activeESP[mapChild] = { conn = conn, gui = bill }
end

-- ---------- Detection handler (single part) ----------
local function handlePart(v)
	if detectedParts[v] then return end

	local profile, anchor = isNeonSphere(v)
	if not profile then
		profile, anchor = isBagModel(v)
	end
	if not profile then return end

	detectedParts[v] = true
	createESP(anchor, profile, v)
	playSound(profile.soundId, profile.volume)

	log("Detected %s | pos=(%.1f, %.1f, %.1f) | nearest=%s",
		profile.name, anchor.Position.X, anchor.Position.Y, anchor.Position.Z,
		getNearestSpawnXZ(anchor.Position))
end

-- ---------- Initial scan (existing children only) ----------
local function initialScan()
	for _, v in ipairs(workspace.Map:GetChildren()) do
		handlePart(v)
	end
	log("Initial scan complete: %d children checked", #workspace.Map:GetChildren())
end

-- ---------- Cleanup helper ----------
local function cleanupTrackedPart(v)
	local entry = activeESP[v]
	if entry then
		if entry.conn and entry.conn.Connected then
			entry.conn:Disconnect()
		end
		if entry.gui then
			entry.gui:Destroy()
		end
		activeESP[v] = nil
	end
	detectedParts[v] = nil
end

-- ---------- Toggle ----------
local function toggle()
	ESP_ENABLED = not ESP_ENABLED
	log("ESP %s", ESP_ENABLED and "ENABLED" or "DISABLED")

	if not ESP_ENABLED then
		for v in pairs(activeESP) do
			cleanupTrackedPart(v)
		end
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

	for v in pairs(activeESP) do
		cleanupTrackedPart(v)
	end

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
-- not changes within those children's own descendants. This is also now the
-- ONLY mechanism used to detect removal/cleanup (no per-frame existence poll).
local mapAddedConn = workspace.Map.ChildAdded:Connect(function(v)
	if not SCRIPT_ACTIVE or not ESP_ENABLED then return end
	handlePart(v)
end)
table.insert(connections, mapAddedConn)

local mapRemovedConn = workspace.Map.ChildRemoved:Connect(function(v)
	if detectedParts[v] then
		log("Removed from tracking: %s", v.Name)
		cleanupTrackedPart(v)
	end
end)
table.insert(connections, mapRemovedConn)

log("Script started")
initialScan()
