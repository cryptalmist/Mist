-- LocalPlayer and global attributes
local player = game.Players.LocalPlayer
local attributesToSet = getgenv().attributesToSet

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

    if attributesToSet then
        editAccessoryAttributes(attributesToSet)
    end

    -- Wait for backpack item
    local function waitForItemInBackpack()
        local backpack = player:WaitForChild("Backpack")
        repeat wait() until #backpack:GetChildren() > 0
        print("Item detected in Backpack. Proceeding...")
    end
    waitForItemInBackpack()

    -- Load Rayfield UI
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

    -- Tabs for UI
    local ToolTab = Window:CreateTab("Tool")
    local CharacterTab = Window:CreateTab("Character")

    -- Function to modify tool attributes
    local function modifyToolAttributes(toolName, attributes)
        local tool = player.Backpack:FindFirstChild(toolName) or player.Character:FindFirstChild(toolName)
        if tool then
            for attribute, value in pairs(attributes) do
                tool:SetAttribute(attribute, value)
            end
        end
    end

    -- Tool equip handler
    local function OnEquipped(tool)
        local itemName = tool.Name

        if OPSwords and (itemName == "Sword" or itemName == "Firebrand" or itemName == "Katana") then
            modifyToolAttributes(itemName, { LungeRate = 0, Swingrate = 0, OffhandSwingRate = 0 })
            if itemName == "Firebrand" then
                modifyToolAttributes(itemName, { Windup = 0 })
            end
        end

        if OPGuns and (itemName == "Paintball Gun" or itemName == "BB Gun" or itemName == "Freeze Ray") then
            modifyToolAttributes(itemName, { Firerate = 0, ProjectileSpeed = 2250 })
            if itemName == "BB Gun" then
                modifyToolAttributes(itemName, { MinShots = 2, MaxShots = math.huge })
            end
            if itemName == "Freeze Ray" then
                modifyToolAttributes(itemName, { ChargeTime = 0 })
            end
        end

        if OPSlingshot and (itemName == "Slingshot" or itemName == "Flamethrower") then
            modifyToolAttributes(itemName, { Capacity = 1000, ChargeRate = 0, Firerate = 0, ProjectileSpeed = 2250, PelletTossRate = 0 })
            if itemName == "Flamethrower" then
                modifyToolAttributes(itemName, { Cooldown = 0, Intake = 0 })
            end
        end
    end

    -- Listener setup for tools
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

        for _, tool in ipairs(player.Character:GetChildren()) do
            if tool:IsA("Tool") then
                OnEquipped(tool)
            end
        end
    end

    -- Tool toggles
    ToolTab:CreateToggle({
        Name = "OP Swords",
        CurrentValue = false,
        Flag = "OP_Swords",
        Callback = function(Value) OPSwords = Value end
    })

    ToolTab:CreateToggle({
        Name = "OP Guns",
        CurrentValue = false,
        Flag = "OP_Guns",
        Callback = function(Value) OPGuns = Value end
    })

    ToolTab:CreateToggle({
        Name = "OP Slingshots",
        CurrentValue = false,
        Flag = "OP_Slingshot",
        Callback = function(Value) OPSlingshot = Value end
    })

    -- Infinite dash toggle
    CharacterTab:CreateToggle({
        Name = "Infinite Dash",
        CurrentValue = false,
        Flag = "Infinite_Dash",
        Callback = function(Value)
            local character = player.Character
            spawn(function()
                while Value do
                    if character then
                        character:SetAttribute("DashRegenTime", 0.05)
                        character:SetAttribute("DashRegenFury", 0.05)
                    end
                    wait(0.5)
                end
                if character then
                    character:SetAttribute("DashRegenTime", 1)
                    character:SetAttribute("DashRegenFury", 1)
                end
            end)
        end
    })

    -- Setup listeners on character respawn
    player.CharacterAdded:Connect(function()
        wait()
        setupToolListeners()
    end)

    Rayfield:LoadConfiguration()
end
