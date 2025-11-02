getgenv().HiveMaskConfig = getgenv().HiveMaskConfig or {
	CheckInterval = 0.25, -- seconds between position checks
	InsideMask = "Honey Mask", -- mask to equip inside hive
	OutsideMask = "Diamond Mask", -- mask to equip outside hive
	PrintStatus = true, -- print logs
}

if getgenv().HiveMaskManager then
	warn("[HiveMaskManager] Re-execution detected — cleaning up old thread...")
	if getgenv().HiveMaskManager._running then
		getgenv().HiveMaskManager._running = false
	end
	task.wait(0.2)
end

--// 🧠 STATE HOLDER
getgenv().HiveMaskManager = { _running = true }
local Manager = getgenv().HiveMaskManager
local Config = getgenv().HiveMaskConfig

--// 🧾 SERVICES
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local Events = ReplicatedStorage:WaitForChild("Events")
local ItemPackageEvent = Events:WaitForChild("ItemPackageEvent")
local Honeycombs = Workspace:WaitForChild("Honeycombs")

--// 🧰 UTILITIES
local function log(...)
	if Config.PrintStatus then print("[HiveMaskManager]", ...) end
end

local function warnLog(...)
	if Config.PrintStatus then warn("[HiveMaskManager]", ...) end
end

local function EquipMask(mask)
	local args = {
		"Equip",
		{
			Category = "Accessory",
			Type = mask
		}
	}
	local ok, err = pcall(function()
		ItemPackageEvent:InvokeServer(unpack(args))
	end)
	if ok then
		log("Equipped:", mask)
	else
		warnLog("Failed to equip mask:", err)
	end
end

local function FindPlayerHive()
	for _, hive in ipairs(Honeycombs:GetChildren()) do
		local owner = hive:FindFirstChild("Owner")
		if owner and owner:IsA("ObjectValue") and owner.Value == LocalPlayer then
			return hive
		end
	end
end

--// 🧠 MAIN LOOP
task.spawn(function()
	local playerHive
	repeat
		playerHive = FindPlayerHive()
		if not Manager._running then return end
		task.wait(1)
	until playerHive

	log("Your hive detected:", playerHive.Name)
	local insideHive = false

	while Manager._running and task.wait(Config.CheckInterval) do
		local char = LocalPlayer.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hrp or not playerHive then continue end

		local cf, size = playerHive:GetBoundingBox()
		local rel = cf:PointToObjectSpace(hrp.Position)
		local inHive = (
			math.abs(rel.X) <= size.X / 2 and
			math.abs(rel.Y) <= size.Y / 2 and
			math.abs(rel.Z) <= size.Z / 2
		)

		if inHive and not insideHive then
			insideHive = true
			EquipMask(Config.InsideMask)
		elseif not inHive and insideHive then
			insideHive = false
			EquipMask(Config.OutsideMask)
		end
	end

	log("Loop stopped.")
end)
