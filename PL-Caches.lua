if not game:IsLoaded() then
	game.Loaded:Wait()
end

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local ESP_ENABLED = true
local connections = {}
local detectedParts = {}

-- ================= COLOR PROFILES =================
local COLOR_TOLERANCE = 5

local COLOR_PROFILES = {
	{
		name = "Ultimate",
		color = Color3.fromRGB(255, 100, 100),
		soundId = "rbxassetid://82845990304289",
	},
	{
		name = "Legend",
		color = Color3.fromRGB(255, 255, 100),
		soundId = "rbxassetid://107261392908541",
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

-- ==================================================

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
local function playSound(id)
	if not id then return end
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = 2.4
	s.Parent = workspace
	s:Play()
	s.Ended:Once(function() s:Destroy() end)
end

-- ---------- Detection ----------
local function isNeonSphere(p)
	if not p:IsA("BasePart") then return end
	if p.Material ~= Enum.Material.Neon then return end
	if p:IsA("Part") and p.Shape ~= Enum.PartType.Ball then return end
	return getProfile(p.Color)
end

-- ---------- ESP ----------
local function createESP(part, profile)
	local bill = Instance.new("BillboardGui")
	bill.Name = "BallESP"
	bill.Size = UDim2.new(0, 230, 0, 70)
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

	local conn
	conn = RunService.RenderStepped:Connect(function()
		if not ESP_ENABLED or not part.Parent then
			conn:Disconnect()
			return
		end

		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hrp then return end

		local dist = (hrp.Position - part.Position).Magnitude
		local nearest = getNearestSpawnXZ(part.Position)

		label.Text = string.format(
			"%s\n%.1f m\n%s",
			profile.name,
			dist,
			nearest
		)
	end)

	table.insert(connections, conn)
end

-- ---------- Scan ----------
local function scan()
	for _, v in ipairs(workspace:GetChildren()) do
		if not detectedParts[v] then
			local profile = isNeonSphere(v)
			if profile then
				detectedParts[v] = true
				createESP(v, profile)
				playSound(profile.soundId)
			end
		end
	end
end

-- ---------- Toggle ----------
local function toggle()
	ESP_ENABLED = not ESP_ENABLED

	if not ESP_ENABLED then
		for _, v in ipairs(workspace:GetChildren()) do
			local esp = v:FindFirstChild("BallESP")
			if esp then esp:Destroy() end
		end
		table.clear(detectedParts)
	end
end

UserInputService.InputBegan:Connect(function(i, gp)
	if not gp and i.KeyCode == Enum.KeyCode.K then
		toggle()
	end
end)

-- Auto refresh
task.spawn(function()
	while true do
		task.wait(1)
		if ESP_ENABLED then
			scan()
		end
	end
end)

scan()
print("Neon Cache ESP ready")
