-- Define player and global attributes
local player = game.Players.LocalPlayer
local attributesToSet = getgenv().attributesToSet
local placeId = game.PlaceId

-- Ensure the script runs only in the correct game and place
if game.GameId == 4712126054 and placeId == 14582748896 then
    print("In Game")

    -- Function to edit accessory attributes
    local function editAccessoryAttributes(attributeList)
        local accessoryFolder = player:FindFirstChild("AccessoryEffects")

        if accessoryFolder then
            for attributeName, attributeValue in pairs(attributeList) do
                accessoryFolder:SetAttribute(attributeName, attributeValue)
            end
            print("Attributes updated for AccessoryEffects folder.")
        else
            print("AccessoryEffects folder not found.")
        end
    end

    -- Update accessory attributes if specified
    if attributesToSet then
        editAccessoryAttributes(attributesToSet)
    end

    -- Function to wait for an item to appear in the player's backpack
    local function waitForItemInBackpack()
        local backpack = player:WaitForChild("Backpack")
        repeat
            wait()
        until #backpack:GetChildren() > 0
        print("Item detected in Backpack. Proceeding...")
    end
    waitForItemInBackpack()

    -- Load Rayfield UI Library
    local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

    local Window = Rayfield:CreateWindow({
        Name = "CryptHub - Combat-Initiation",
        LoadingTitle = "CryptHub",
        LoadingSubtitle = "Combat Script",
        ConfigurationSaving = {
            Enabled = true,
            FolderName = "CryptHub",
            FileName = "CombatInitiation"
        }
    })

    -- Create tabs for tools and character
    local ToolTab = Window:CreateTab("Tool")
    local CharacterTab = Window:CreateTab("Character")

    -- Function to modify tool attributes
    local function modifyToolAttributes(toolName, attributes)
        local tool = player.Backpack:FindFirstChild(toolName) or player.Character:FindFirstChild(toolName)
        if tool then
            for attribute, value in pairs(attributes) do
                if tool:GetAttribute(attribute) ~= nil then
                    tool:SetAttribute(attribute, value)
                end
            end
        end
    end

    -- Function to handle tool equipping
    local function OnEquipped(Item)
        local itemName = Item.Name

        -- Check for swords
        if OPSwords and (itemName == "Sword" or itemName == "Firebrand" or itemName == "Katana") then
            modifyToolAttributes(itemName, { LungeRate = 0, Swingrate = 0, OffhandSwingRate = 0 })
            if itemName == "Firebrand" then
                modifyToolAttributes(itemName, { Windup = 0 })
            end
        end

        -- Check for guns
        if OPGuns and (itemName == "Paintball Gun" or itemName == "BB Gun" or itemName == "Freeze Ray") then
            modifyToolAttributes(itemName, { Firerate = 0, ProjectileSpeed = 2250 })
            if itemName == "BB Gun" then
                modifyToolAttributes(itemName, { MinShots = 2, MaxShots = math.huge })
            end
            if itemName == "Freeze Ray" then
                modifyToolAttributes(itemName, { ChargeTime = 0 })
            end
        end

        -- Check for slingshots
        if OPSlingshot and (itemName == "Slingshot" or itemName == "Flamethrower") then
            modifyToolAttributes(itemName, { Capacity = 1000, ChargeRate = 0, Firerate = 0, ProjectileSpeed = 2250, PelletTossRate = 0 })
            if itemName == "Flamethrower" then
                modifyToolAttributes(itemName, { Cooldown = 0, Intake = 0 })
            end
        end
    end

    -- Set up listeners for tool equipping
    local function setupToolListeners()
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

        -- Check for tools already equipped
        for _, child in ipairs(player.Character:GetChildren()) do
            if child:IsA("Tool") then
                OnEquipped(child)
            end
        end
    end

    -- Tool Mod Toggles
    ToolTab:CreateToggle({
        Name = "OP Swords Tree",
        CurrentValue = false,
        Flag = "OP_Swords",
        Callback = function(Value)
            OPSwords = Value
        end
    })

    ToolTab:CreateToggle({
        Name = "OP Guns Tree",
        CurrentValue = false,
        Flag = "OP_Guns",
        Callback = function(Value)
            OPGuns = Value
        end
    })

    ToolTab:CreateToggle({
        Name = "OP Slingshots Tree",
        CurrentValue = false,
        Flag = "OP_Slingshot",
        Callback = function(Value)
            OPSlingshot = Value
        end
    })

    -- Infinite Dash Toggle
    CharacterTab:CreateToggle({
        Name = "Infinite Dash",
        CurrentValue = false,
        Flag = "Infinite_Dash",
        Callback = function(Value)
            local character = player.Character
            spawn(function()
                while Value and character do
                    character:SetAttribute("DashRegenTime", 0.05)
                    character:SetAttribute("DashRegenFury", 0.05)
                    wait(0.5)
                end
                if character then
                    character:SetAttribute("DashRegenTime", 1)
                    character:SetAttribute("DashRegenFury", 1)
                end
            end)
        end
    })

    -- Connect tool listeners on respawn
    player.CharacterAdded:Connect(function()
        wait()
        setupToolListeners()
    end)

    -- Load saved Rayfield configuration
    Rayfield:LoadConfiguration()
end
