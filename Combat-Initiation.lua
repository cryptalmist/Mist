local player = game.Players.LocalPlayer
local attributesToSet = getgenv().attributesToSet
if game.GameId == 4712126054 then

    if placeId == 14582748896 then
        print("In Game")
        if attributesToSet then
            local function editAccessoryAttributes(attributeList)
                -- Reference to the AccessoryEffects folder
                local accessoryFolder = player:FindFirstChild("AccessoryEffects")
                
                if accessoryFolder then
                    -- Iterate through the list and set or update attributes
                    for attributeName, attributeValue in pairs(attributeList) do
                        accessoryFolder:SetAttribute(attributeName, attributeValue)
                    end
        
                    print("Attributes updated for AccessoryEffects folder.")
                else
                    print("AccessoryEffects folder not found.")
                end
            end
            editAccessoryAttributes(attributesToSet)

        print("Waiting for game to start...")
        local function waitForItemInBackpack()
            local backpack = player:WaitForChild("Backpack") -- Ensure the Backpack exists

            -- Wait until the backpack contains at least one item
            repeat
                wait() -- Prevent busy-waiting
            until #backpack:GetChildren() > 0
            print("Item detected in Backpack. Proceeding...")
        end
        waitForItemInBackpack()
    end

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

    local ToolTab = Window:CreateTab("Tool") -- Tab for tool modifications
    local CharacterTab = Window:CreateTab("Character") -- Tab for character modifications

    -- Function to modify tool attributes
    local function modifyToolAttributes(toolName, attributes)
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

    -- Function to set up event listeners for equipping tools
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

        -- Initial check for already equipped tools
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

    -- Infinite Dash Toggle with 2-second interval
    CharacterTab:CreateToggle({
        Name = "Infinite Dash",
        CurrentValue = false,
        Flag = "Infinite_Dash",
        Callback = function(Value)
            local character = game.Players.LocalPlayer.Character
            spawn(function()
                while Value do
                    if character then
                        character:SetAttribute("DashRegenTime", 0.05)
                        character:SetAttribute("DashRegenFury", 0.05)
                    end
                    wait(0.5)
                end
                -- Reset values when Infinite Dash is toggled off
                if character then
                    character:SetAttribute("DashRegenTime", 1)
                    character:SetAttribute("DashRegenFury", 1)
                end
            end)
        end
    })

    -- Connect tool listeners on player character respawn
    game.Players.LocalPlayer.CharacterAdded:Connect(function()
        wait()
        setupToolListeners()
    end)

    Rayfield:LoadConfiguration() -- Load saved configurations on launch
end
