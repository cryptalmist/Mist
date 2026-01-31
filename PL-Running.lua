local Players = game:GetService("Players")
local VIM = game:GetService("VirtualInputManager")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local running = false

-- Toggle with L
UIS.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.L then
		running = not running
		warn("Running:", running)
	end
end)

local function PressRightBracket()
	VIM:SendKeyEvent(true, Enum.KeyCode.RightBracket, false, game)
	task.wait(0.05)
	VIM:SendKeyEvent(false, Enum.KeyCode.RightBracket, false, game)
end

local function PressSpace()
	VIM:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
	task.wait(0.05)
	VIM:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
end

local function SetYaw(deg)
	local char = player.Character or player.CharacterAdded:Wait()
	local root = char:WaitForChild("HumanoidRootPart")

	local yaw = math.rad(deg)
	local pos = root.Position
	local rot = CFrame.Angles(0, yaw, 0)

	root.CFrame = CFrame.new(pos) * rot

	local camPos = camera.CFrame.Position
	local offset = camPos - pos
	camera.CFrame = CFrame.new(pos) * rot * CFrame.new(offset)
end

task.spawn(function()
	while true do
		-- Wait until enabled
		while not running do
			task.wait(0.1)
		end

		local char = player.Character or player.CharacterAdded:Wait()
		local hum = char:WaitForChild("Humanoid")
		local root = char:WaitForChild("HumanoidRootPart")

		-- If dead, wait 3s
		if hum.Health <= 0 then
			task.wait(2)
			continue
		end

		PressRightBracket()
		task.wait(0.5)
		SetYaw(90)

		-- Continuous movement
		local moveConn
		moveConn = RunService.RenderStepped:Connect(function()
			if not running or hum.Health <= 0 then
				moveConn:Disconnect()
				return
			end
			hum:Move(Vector3.new(1, 0, 0), true)
		end)

		-- Jump with Space
		task.wait(0.5)
		for i = 1, 20 do
			if not running or hum.Health <= 0 then break end
			PressSpace()
			task.wait(1.5)
		end

		-- Wait until condition or stop
		while running and hum.Health > 0 and root.Position.Z > -2500 do
			task.wait(0.1)
		end

		if moveConn then moveConn:Disconnect() end
		hum:Move(Vector3.zero, true)

		if hum.Health <= 0 then
			task.wait(3)
		end
	end
end)

print("Running Initialized")
