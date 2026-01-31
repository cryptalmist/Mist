local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VIM = game:GetService("VirtualInputManager")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- LIMITS
local POS_SOFT, POS_HARD = 4150, 4550
local NEG_SOFT, NEG_HARD = -2156, -2450

local TAP_DELAY = 0.1
local FLIP_COOLDOWN = 0.3
local TOGGLE_KEY = Enum.KeyCode.U
local dev = false

-- state
local enabled = false
local targetZ = nil
local flipping = false

-- runtime refs
local char = nil
local root = nil
local humanoid = nil

-- debug throttle
local lastPrint = 0
local PRINT_INTERVAL = 0.25

local function dprint(...)
	if dev then
		print("[Z-AUTO]", ...)
	end
end

-- ================= CHARACTER BIND =================
local function bindCharacter(character)
	char = character
	root = character:WaitForChild("HumanoidRootPart")
	humanoid = character:WaitForChild("Humanoid")

	targetZ = nil
	flipping = false

	dprint("Character bound")

	humanoid.Died:Once(function()
		dprint("Character died, waiting for respawn")
	end)
end

-- initial bind
if player.Character then
	bindCharacter(player.Character)
end

player.CharacterAdded:Connect(bindCharacter)

-- ================= TOGGLE =================
UIS.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == TOGGLE_KEY then
		enabled = not enabled
		targetZ = nil
		flipping = false
		print("SYSTEM", enabled and "ENABLED" or "DISABLED")
	end
end)

-- ================= INPUT =================
local function tap(key)
	VIM:SendKeyEvent(true, key, false, game)
	task.wait(TAP_DELAY)
	VIM:SendKeyEvent(false, key, false, game)
end

local function flip()
	if flipping or not enabled or not root then return end
	flipping = true

	print("FLIP TRIGGERED")

	tap(Enum.KeyCode.RightShift)
	tap(Enum.KeyCode.Q)
	tap(Enum.KeyCode.RightShift)

	task.wait(FLIP_COOLDOWN)

	targetZ = nil
	flipping = false
end

-- ================= LOGIC =================
local function getDirection()
	if not root then return end
	local vz = root.AssemblyLinearVelocity.Z
	if vz > 0.5 then
		return "POS", vz
	elseif vz < -0.5 then
		return "NEG", vz
	end
	return nil, vz
end

local function pickTarget(dir)
	local t
	if dir == "POS" then
		t = math.random(POS_SOFT * 100, POS_HARD * 100) / 100
	else
		t = math.random(NEG_HARD * 100, NEG_SOFT * 100) / 100
	end
	print("Target picked:", t)
	return t
end

-- ================= HEARTBEAT =================
RunService.Heartbeat:Connect(function()
	if not enabled or flipping or not root or not root.Parent then return end

	local dir, vz = getDirection()
	if not dir then return end

	local z = root.Position.Z
	local now = os.clock()

	if dev and now - lastPrint >= PRINT_INTERVAL then
		lastPrint = now
		dprint(
			"Dir:", dir,
			"Z:", math.floor(z),
			"VZ:", string.format("%.2f", vz),
			"Target:", targetZ
		)
	end

	if dir == "POS" then
		if z >= POS_SOFT and not targetZ then
			dprint("POS soft crossed:", z)
			targetZ = pickTarget("POS")
		end
		if targetZ and z >= targetZ then
			dprint("POS target reached:", z)
			flip()
		end
	else
		if z <= NEG_SOFT and not targetZ then
			dprint("NEG soft crossed:", z)
			targetZ = pickTarget("NEG")
		end
		if targetZ and z <= targetZ then
			dprint("NEG target reached:", z)
			flip()
		end
	end
end)

print("ZFlip Initialized (Respawn Safe)")
