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
    local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/UI-Interface/CustomFIeld/main/RayField.lua'))()

    -- Create the main UI window
    local Window = Rayfield:CreateWindow({
        Name = "CryptHub - Enhanced UI",
        LoadingTitle = "CryptHub",
        LoadingSubtitle = "Utility and Enhancements",
        ConfigurationSaving = {
            Enabled = true,
            FolderName = "CryptHub",
            FileName = "EnhancedSettings"
        },
        KeySystem = false -- Set to true if you want to use the Rayfield key system
    })

    -- Create tabs for tools, character, and utility
    local ToolTab = Window:CreateTab("Tools", 4483362458) -- Example icon ID
    local CharacterTab = Window:CreateTab("Character", 4483362460)
    local UtilityTab = Window:CreateTab("Utilities", 4483362462)

    -- Tool Modifications Section
    ToolTab:CreateSection("Tool Modifications")

    ToolTab:CreateToggle({
        Name = "Enable OP Swords",
        CurrentValue = false,
        Flag = "OP_Swords",
        Callback = function(Value)
            OPSwords = Value
            print("OP Swords: ", Value)
        end
    })

    ToolTab:CreateToggle({
        Name = "Enable OP Guns",
        CurrentValue = false,
        Flag = "OP_Guns",
        Callback = function(Value)
            OPGuns = Value
            print("OP Guns: ", Value)
        end
    })

    ToolTab:CreateToggle({
        Name = "Enable OP Slingshots",
        CurrentValue = false,
        Flag = "OP_Slingshots",
        Callback = function(Value)
            OPSlingshot = Value
            print("OP Slingshots: ", Value)
        end
    })

    -- Character Enhancements Section
    CharacterTab:CreateSection("Movement Enhancements")

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
            print("Infinite Dash: ", Value)
        end
    })

    -- Utility Section
    UtilityTab:CreateSection("General Utilities")

    UtilityTab:CreateButton({
        Name = "Reset Attributes",
        Callback = function()
            local character = player.Character
            if character then
                character:SetAttribute("DashRegenTime", 1)
                character:SetAttribute("DashRegenFury", 1)
                print("Attributes reset to default values.")
            end
        end
    })

    UtilityTab:CreateLabel("More utilities coming soon...")

    -- Load saved Rayfield configuration
    Rayfield:LoadConfiguration()
end
