local OrionLib = loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Orion/main/source'))()

local Window = OrionLib:MakeWindow({
    Name = "CryptHub - Combat-Initiation",
    SaveConfig = true,
    ConfigFolder = "CryptHub",
    IntroText = "Hi!"
})

local Tool = Window:MakeTab({
    Name = "Tool",
    Icon = "rbxassetid://4483345998"
})

local CharacterTab = Window:MakeTab({
    Name = "Character",
    Icon = "rbxassetid://4483345998"
})

local OPSwords = false -- Variable to track the toggle state for swords
local OPGuns = false -- Variable to track the toggle state for guns
local OPSlingshot = false -- Variable to track the toggle state for slingshots
local InfiniteStamina = false -- Variable to track the toggle state for infinite stamina

-- Function to modify tool attributes safely (check both Backpack and equipped tools)
local function modifyToolAttributes(toolName, attributes)
    local player = game.Players.LocalPlayer
    local tool = player.Backpack:FindFirstChild(toolName) or player.Character:FindFirstChild(toolName)

    if tool then
        for attribute, value in pairs(attributes) do
            tool:SetAttribute(attribute, value)
        end
    end
end

-- Function to handle item equipping
local function OnEquipped(Item)
    local itemName = Item.Name

    -- Check for swords
    if OPSwords and (itemName == "Sword" or itemName == "Firebrand" or itemName == "Katana") then
        if itemName == "Sword" then
            modifyToolAttributes(itemName, {
                LungeRate = 0,
                Swingrate = 0,
                OffhandSwingRate = 0
            })
        elseif itemName == "Firebrand" then
            modifyToolAttributes(itemName, {
                LungeRate = 0,
                Swingrate = 0,
                OffhandSwingRate = 0,
                Windup = 0 -- Assuming Firebrand has a Windup attribute
            })
        elseif itemName == "Katana" then
            modifyToolAttributes(itemName, {
                LungeRate = 0,
                Swingrate = 0,
                OffhandSwingRate = 0
            })
        end
    end
    
    -- Check for guns
    if OPGuns and (itemName == "Paintball Gun" or itemName == "BB Gun" or itemName == "Freeze Ray") then
        if itemName == "Paintball Gun" then
            modifyToolAttributes(itemName, {
                Firerate = 0,
                ProjectileSpeed = 2250
            })
        elseif itemName == "BB Gun" then
            modifyToolAttributes(itemName, {
                Firerate = 0,
                MinShots = 2,
                MaxShots = math.huge -- Use `math.huge` for infinite value
            })
        elseif itemName == "Freeze Ray" then
            modifyToolAttributes(itemName, {
                Firerate = 0,
                ProjectileSpeed = 2250,
                ChargeTime = 0
            })
        end
    end
    
    -- Check for slingshots
    if OPSlingshot and (itemName == "Slingshot" or itemName == "Flamethrower") then
        if itemName == "Slingshot" then
            modifyToolAttributes(itemName, {
                Capacity = 10000,
                ChargeRate = 0,
                Firerate = 0,
                Spread = 0,
                ProjectileSpeed = 2250
            })
        elseif itemName == "Flamethrower" then
            modifyToolAttributes(itemName, {
                Cooldown = 0
            })
        end
    end
end

-- Function to set up event listeners for equipping tools
local function setupToolListeners()
    local player = game.Players.LocalPlayer

    -- Listen for when a tool is added to the character
    player.Character.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            child.Equipped:Connect(function()
                OnEquipped(child) -- Call OnEquipped when the tool is equipped
            end)
        end
    end)

    -- Listen for when a tool is added to the Backpack
    player.Backpack.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            child.Equipped:Connect(function()
                OnEquipped(child) -- Call OnEquipped when the tool is equipped
            end)
        end
    end)

    -- Check equipped tools on spawn
    for _, child in ipairs(player.Character:GetChildren()) do
        if child:IsA("Tool") then
            OnEquipped(child)
        end
    end
end

-- Tools Tab
local Tab = Tool

Tab:AddParagraph("Sword Mod", "Enable to modify sword attributes.")
Tab:AddToggle({
    Name = "OP Swords",
    Default = false,
    Callback = function(Value)
        OPSwords = Value
        setupToolListeners()
    end    
})

Tab:AddParagraph("Gun Mod", "Enable to modify gun attributes.")
Tab:AddToggle({
    Name = "OP Guns",
    Default = false,
    Callback = function(Value)
        OPGuns = Value
        setupToolListeners()
    end    
})

Tab:AddParagraph("Slingshot Mod", "Enable to modify slingshot attributes.")
Tab:AddToggle({
    Name = "OP Slingshots",
    Default = false,
    Callback = function(Value)
        OPSlingshot = Value
        setupToolListeners()
    end    
})

-- Character Tab
CharacterTab:AddParagraph("Character Attributes", "Enable infinite stamina.")
CharacterTab:AddToggle({
    Name = "Infinite Stamina",
    Default = false,
    Callback = function(Value)
        InfiniteStamina = Value
        local character = game.Players.LocalPlayer.Character
        if character then
            if InfiniteStamina then
                character:SetAttribute("Stamina", math.huge) -- Set stamina to infinite
            else
                character:SetAttribute("Stamina", 100) -- Reset to normal value (assuming 100 is the max)
            end
        end
    end
})

-- Connect to the Player's CharacterAdded event to re-establish listeners on respawn
game.Players.LocalPlayer.CharacterAdded:Connect(function()
    wait() -- Wait for the character to load
    setupToolListeners() -- Re-setup listeners for tools
end)

OrionLib:Init()
