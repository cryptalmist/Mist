if not game:IsLoaded() then
	game.Loaded:Wait()
end

task.wait(3)

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- Globals
_G.NEON_ESP = true
local ESP_ENABLED = true
local connections = {}

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
-- ==================================================

-- Detection memory & sound debounce
local detectedParts = {} -- [Instance] = true
local soundCooldown = false

-- ---------- Utility ----------
local function colorMatch(c1, c2, tol)
	return math.abs(c1.R*255 - c2.R*255) <= tol
	and math.abs(c1.G*255 - c2.G*255) <= tol
	and math.abs(c1.B*255 - c2.B*255) <= tol
end

local function getColorProfile(color)
	for _, profile in ipairs(COLOR_PROFILES) do
		if colorMatch(color, profile.color, COLOR_TOLERANCE) then
			return profile
		end
	end
	return nil
end

local function playDetectSound(soundId)
	if soundCooldown then return end
	soundCooldown = true

	local s = Instance.new("Sound")
	s.SoundId = soundId
	s.Volume = 1
	s.Parent = workspace
	s:Play()

	s.Ended:Once(function()
		s:Destroy()
	end)

	task.delay(0.3, function()
		soundCooldown = false
	end)
end

-- ---------- ESP Core ----------
local function clearESP()
	for _, v in ipairs(workspace:GetChildren()) do
		if v:FindFirstChild("BallESP") then
			v.BallESP:Destroy()
		end
	end
	for _, c in ipairs(connections) do
		c:Disconnect()
	end
	table.clear(connections)
	table.clear(detectedParts)
end

local function isNeonSphere(p)
	if not p:IsA("BasePart") then return nil end
	if p.Material ~= Enum.Material.Neon then return nil end

	local profile = getColorProfile(p.Color)
	if not profile then return nil end

	if p:IsA("Part") and p.Shape == Enum.PartType.Ball then
		return profile
	end

	if p:IsA("MeshPart") then
		return profile
	end

	return nil
end

local function createESP(part, profile)
	if part:FindFirstChild("BallESP") then return end

	local bill = Instance.new("BillboardGui")
	bill.Name = "BallESP"
	bill.Size = UDim2.new(0, 220, 0, 50)
	bill.AlwaysOnTop = true
	bill.Adornee = part
	bill.Parent = part

	local text = Instance.new("TextLabel")
	text.Parent = bill
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.TextColor3 = part.Color
	text.TextStrokeTransparency = 0
	text.TextScaled = true
	text.Font = Enum.Font.GothamBold

	local conn = RunService.RenderStepped:Connect(function()
		if not ESP_ENABLED then return end
		local char = player.Character
		if not char then return end
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if not hrp then return end

		local dist = (hrp.Position - part.Position).Magnitude
		text.Text = string.format("%s | %.1f m", profile.name, dist)
	end)

	table.insert(connections, conn)
end

local function scanWorkspace()
	local playedSoundThisScan = false

	for _, v in ipairs(workspace:GetChildren()) do
		if not detectedParts[v] then
			local profile = isNeonSphere(v)
			if profile then
				detectedParts[v] = true
				createESP(v, profile)

				-- console output (ONCE per new cache)
				local pos = v.Position
				warn(string.format(
					"[CACHE DETECTED] %s | X: %.1f Y: %.1f Z: %.1f",
					profile.name,
					pos.X, pos.Y, pos.Z
				))

				if profile.soundId and not playedSoundThisScan then
					playDetectSound(profile.soundId)
					playedSoundThisScan = true
				end
			end
		end
	end
end

local function toggleESP(state)
	ESP_ENABLED = state
	_G.NEON_ESP = state

	if not state then
		clearESP()
		warn("Neon Sphere ESP: OFF")
	else
		scanWorkspace()
		warn("Neon Sphere ESP: ON")
	end
end

-- Hotkey: K
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.K then
		toggleESP(not ESP_ENABLED)
	end
end)

-- Auto refresh
task.spawn(function()
	while true do
		task.wait(1)
		if ESP_ENABLED then
			scanWorkspace()
		end
	end
end)

-- Start
scanWorkspace()
print("Caches Initialized")
