bss:
```lua
--// HIVE MASK
getgenv().HiveMaskConfig = getgenv().HiveMaskConfig or {
	CheckInterval = 2, -- seconds between position checks
	InsideMask = "Honey Mask", -- mask to equip inside hive
	OutsideMask = "Diamond Mask", -- mask to equip outside hive
	PrintStatus = true, -- print logs
}

--// TOYS
getgenv().Toys = getgenv().Toys or {
    "Honey Dispenser",
    "Coconut Dispenser",
    "Treat Dispenser",
    "Blueberry Dispenser",
    "Strawberry Dispenser",
    "Wealth Clock",
    "Blue Field Booster",
    "Field Booster",
    "Red Field Booster",
    "Wealth Clock",
    "Glue Dispenser",
    "Glue Dispenser",
    "Sprout Summoner",
    "Honneystorm",
    "Free Royal Jelly Dispenser"
}

getgenv().ToyCheckDelay = getgenv().ToyCheckDelay or 5

loadstring(game:HttpGet('https://raw.githubusercontent.com/cryptalmist/Mist/refs/heads/main/BSSAutoToys.lua'))()
loadstring(game:HttpGet('https://raw.githubusercontent.com/cryptalmist/Mist/refs/heads/main/MaskAtHive.lua'))()
```



[QOL](queue_on_load)-patch:

- [Atlas-BSS](https://discord.gg/KevBAZ3SE9)
```lua
getgenv().BSS_JumpPower = 80
loadstring(game:HttpGet('https://raw.githubusercontent.com/cryptalmist/Mist/refs/heads/main/QOL-patch/bss-atlas.lua'))()
```

combat initiation:
```lua
--idk if this work
getgenv().attributesToSet = {
    Lifesteal = 1,
    Lightning_Chance = 0,
    Melee_Range = 10,
    Pogo_Range = 2
}
loadstring(game:HttpGet("https://raw.githubusercontent.com/cryptalmist/Mist/refs/heads/main/Combat-Initiation.lua"))()
```
buff script:
```lua
local player = game.Players.LocalPlayer

-- Function to set or edit custom attributes for the AccessoryEffects folder
local function editAccessoryAttributes()
    -- Reference to the AccessoryEffects folder
    local accessoryFolder = player:FindFirstChild("AccessoryEffects")
    
    if accessoryFolder then
        -- Setting or updating attributes
        accessoryFolder:SetAttribute("Lifesteal", 1)
        accessoryFolder:SetAttribute("Lightning_Chance", 0)
        accessoryFolder:SetAttribute("Melee_Range", 23)
        accessoryFolder:SetAttribute("Pogo_Range", 2)


        print("Attributes updated for AccessoryEffects folder.")
    else
        print("AccessoryEffects folder not found.")
    end
end

-- Run the function to edit attributes
editAccessoryAttributes()
```
Fisch (may be detected) but work now:
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/cryptalmist/Mist/refs/heads/main/Fisch.lua"))()
```
Fisch SasGuard: `https://github.com/cryptalmist/sasware-fisch/tree/main/bypasses` V3

Thx chatGPT and people letme borrow code :)
