-- Define player and global attributes
local player = game.Players.LocalPlayer
local attributesToSet = getgenv().attributesToSet

-- Ensure the script runs only in the correct game and place
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

-- Function to wait for an item to appear in the player's backpack
local function waitForItemInBackpack()
    local backpack = player:WaitForChild("Backpack")
    
    -- Check if there is already an item in the backpack
    if #backpack:GetChildren() > 0 then
        print("Item detected in Backpack. Proceeding immediately...")
        return
    end

    -- If no item, wait for one to be added
    print("Waiting for an item to appear in Backpack...")
    backpack.ChildAdded:Wait()
    print("Item detected in Backpack. Proceeding...")
end
waitForItemInBackpack()

-- Load Linoria UI Library
local repo = 'https://raw.githubusercontent.com/mstudio45/LinoriaLib/main/'

local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()
local Options = Library.Options
local Toggles = Library.Toggles

local Window = Library:CreateWindow({
	Title = 'Mist | Combat Initiation',
	Center = true,
	AutoShow = true,
	Resizable = true,
	NotifySide = "Right",
	TabPadding = 1,
	MenuFadeTime = 0,
	ShowCustomCursor = false,
})

print(1)

local Tabs = {
    Main = Window:AddTab("Tools"),
    Settings = Window:AddTab("Settings"),
}

-- UI Elements
local Toolbox = Tabs.Main:AddLeftGroupbox("Item")

Toolbox:AddToggle("OPSwords", {
    Text = "Enable OP Swords",
    Default = true })

Toolbox:AddToggle("OPGuns", {
    Text = "Enable OP Guns",
    Default = true })

Toolbox:AddToggle("OPSlingshots", {
    Text = "Enable OP Slingshots",
    Default = true })

local Dash = Tabs.Main:AddRightGroupbox("Dash")

Dash:AddToggle("Infinite_Dash", {
    Text = "Infinite Dash",
    Default = false,
    Callback = function(Value)
        task.spawn(function()
            while Value and player.Character do
                local character = player.Character
                if character then
                    character:SetAttribute("DashRegenTime", 0.05)
                    character:SetAttribute("DashRegenFury", 0.05)
                end
                task.wait(0.5)
            end
            
            -- Reset attributes when disabled
            if player.Character then
                player.Character:SetAttribute("DashRegenTime", 1)
                player.Character:SetAttribute("DashRegenFury", 1)
            end
        end)
    end
})

local MenuGroup = Tabs.Settings:AddLeftGroupbox("Menu")

MenuGroup:AddButton("Unload", function() Library:Unload() end)

MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "RightAlt", NoUI = true, Text = "Menu keybind"})

Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()

SaveManager:SetIgnoreIndexes({ "MenuKeybind" })

ThemeManager:SetFolder("MistHub")
SaveManager:SetFolder("MistHub/CI")

SaveManager:BuildConfigSection(Tabs.Settings)

ThemeManager:ApplyToTab(Tabs.Settings)

-- Ensure Toggles are Ready Before Proceeding
local function GetToggleValue(Name: string): boolean
    if not Toggles or not Toggles[Name] then
        warn("Toggle not found or not initialized:", Name)
        return false -- Default to false
    end
    return Toggles[Name].Value
end

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
    if GetToggleValue("OPSwords") and (itemName == "Sword" or itemName == "Firebrand" or itemName == "Katana") then
        modifyToolAttributes(itemName, { LungeRate = 0, Swingrate = 0, OffhandSwingRate = 0 })
        if itemName == "Firebrand" then
            modifyToolAttributes(itemName, { Windup = 0 })
        end
    end
    
    -- Check for guns
    if GetToggleValue("OPGuns") and (itemName == "Paintball Gun" or itemName == "BB Gun" or itemName == "Freeze Ray") then
        modifyToolAttributes(itemName, { Firerate = 0, ProjectileSpeed = 2250 })
        if itemName == "BB Gun" then
            modifyToolAttributes(itemName, { MinShots = 2, MaxShots = math.huge })
        end
        if itemName == "Freeze Ray" then
            modifyToolAttributes(itemName, { ChargeTime = 0 })
        end
    end
    
    -- Check for slingshots
    if GetToggleValue("OPSlingshots") and (itemName == "Slingshot" or itemName == "Flamethrower") then
        modifyToolAttributes(itemName, { Capacity = 10000, ChargeRate = 0, Firerate = 0, Spread = 0, ProjectileSpeed = 2250, PelletTossRate = 0})
        if itemName == "Flamethrower" then
            modifyToolAttributes(itemName, { Cooldown = 0, EjectUse = 0, Intake = 0 , EjectRate = 1.5})
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


player.CharacterAdded:Connect(function()
    wait()
    setupToolListeners()
end)

setupToolListeners()

Library:Notify("CryptHub UI Loaded!", 5)
