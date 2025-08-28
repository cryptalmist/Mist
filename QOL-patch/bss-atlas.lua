print("[INFO] Starting script...")

-- Prevent multiple queueing on teleport
if not getgenv().BSS_Atlas_Queued then
    if queue_on_teleport then
        print("[INFO] queue_on_teleport is supported. Adding script to teleport queue...")
        queue_on_teleport("loadstring(game:HttpGet('https://raw.githubusercontent.com/cryptalmist/Mist/refs/heads/main/QOL-patch/bss-atlas.lua'))()")
        getgenv().BSS_Atlas_Queued = true
        print("[INFO] Script has been queued for teleport.")
    else
        print("[WARNING] queue_on_teleport is NOT supported by this executor.")
    end
else
    print("[INFO] Teleport queue already set. Skipping queue setup.")
end

-- Force JumpPower using getgenv() configuration
local desiredJumpPower = getgenv().BSS_JumpPower or 100 -- Default is 100 if not set
print("[INFO] Forcing JumpPower to: " .. desiredJumpPower)

local player = game.Players.LocalPlayer

local function setJumpPower(humanoid)
    humanoid.UseJumpPower = true
    humanoid.JumpPower = desiredJumpPower
    print("[SUCCESS] JumpPower set to " .. desiredJumpPower)
end

if player and player.Character then
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        setJumpPower(humanoid)
    else
        print("[WARNING] Humanoid not found. Waiting for respawn...")
    end
end

player.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid")
    setJumpPower(hum)
end)

-- Always load main script
print("[INFO] Loading main script from: https://raw.githubusercontent.com/Chris12089/atlasbss/main/script.lua")
local success, err = pcall(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Chris12089/atlasbss/main/script.lua"))()
end)

if success then
    print("[SUCCESS] Main script loaded successfully!")
else
    print("[ERROR] Failed to load main script: " .. tostring(err))
end

print("[INFO] Script execution finished.")
