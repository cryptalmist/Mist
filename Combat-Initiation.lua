local OrionLib = loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Orion/main/source'))()

local Window = OrionLib:MakeWindow({
    Name = "CryptHub - Combat-Initiation",
    HidePremium = false,
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

local debounce = false -- Add a debounce to prevent freezing

local function modifyToolAttributes(toolName, attributes)
    local player = game.Players.LocalPlayer
    local tool = player.Backpack:FindFirstChild(toolName) or player.Character:FindFirstChild(toolName)

    if tool then
        for attribute, value in pairs(attributes) do
            tool:SetAttribute(attribute, value)
        end
    end
end

local function OnEquipped(Item)
    if debounce then return end
    debounce = true

    local itemName = Item.Name

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
                Windup = 0
            })
        elseif itemName == "Katana" then
            modifyToolAttributes(itemName, {
                LungeRate = 0,
                Swingrate = 0,
                OffhandSwingRate = 0
            })
        end
    end

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
                MaxShots = math.huge
            })
        elseif itemName == "Freeze Ray" then
            modifyToolAttributes(itemName, {
                Firerate = 0,
                ProjectileSpeed = 2250,
                ChargeTime = 0
            })
        end
    end

    if OPSlingshot and (itemName == "Slingshot" or itemName == "Flamethrower") then
        if itemName == "Slingshot" then
            modifyToolAttributes(itemName, {
                Capacity = 10000,
                ChargeRate = 0,
                PelletTossRate=0,
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

    debounce = false -- Reset debounce after modification
end

local function setupToolListeners()
    local player = game.Players.LocalPlayer

    player.Character.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            child.Equipped:Connect(function()
                OnEquipped(child)
            end)
        end
    end)

    player.Backpack.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            child.Equipped:Connect(function()
                OnEquipped(child)
            end)
        end
    end)

    for _, child in ipairs(player.Character:GetChildren()) do
        if child:IsA("Tool") then
            OnEquipped(child)
        end
    end
end

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

CharacterTab:AddParagraph("Character Attributes", "Enable infinite dash.")
CharacterTab:AddToggle({
    Name = "Infinite Dash",
    Default = false,
    Callback = function(Value)
        InfiniteDash = Value
        local character = game.Players.LocalPlayer.Character
        -- Start the infinite dash loop
        spawn(function()
            while InfiniteDash do
                -- Ensure the character is loaded and modify dash attributes
                if character then
                    character:SetAttribute("DashRegenTime", 0.05)
                    character:SetAttribute("DashRegenFury", 0.05)
                end
                wait(2) -- Wait 2 seconds before resetting attributes
            end
            -- Reset attributes when Infinite Dash is toggled off
            if character then
                character:SetAttribute("DashRegenTime", 1)
                character:SetAttribute("DashRegenFury", 1)
            end
        end)
    end
})

game.Players.LocalPlayer.CharacterAdded:Connect(function()
    wait()
    setupToolListeners()
end)

OrionLib:Init()
