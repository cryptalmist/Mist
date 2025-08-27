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
