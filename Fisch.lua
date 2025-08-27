-- Steal from Sasware

local PreloadConstants = {
	PlaceVersionSupport = 4322,
	BypassVersion = "V3",
}

-- Kinda Important stuffs
local NO_HOOKING = false

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

if ReplicatedStorage:WaitForChild("Link", 1) then
    ReplicatedStorage = ReplicatedStorage:WaitForChild("Link") -- the devs are tweaking
end

-- Game instance paths
local LocalPlayer = Players.LocalPlayer
local Unloaded = false
local CurrentTool: Tool?
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Debris = game:GetService("Debris")
local VirtualUser = game:GetService("VirtualUser")
local StarterGui = game:GetService("StarterGui")
local GuiService = game:GetService("GuiService")
local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local VeryImportantPart = Instance.new("Part") -- fake zone for tricking temperature/oxygen scripts
-- 													it's scuffed but works on literally any exec
-- UI Lib

local repo = 'https://raw.githubusercontent.com/mstudio45/LinoriaLib/main/'

local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()
local Options = getgenv().Options
local Toggles = getgenv().Toggles

    --[[
    Recursively waits for instances to exist from a root instance.
    ]]--
local function WaitForTable(Root: Instance, InstancePath: { string }, Timeout: number?)
    local Instance = Root
    for i, v in pairs(InstancePath) do
        Instance = Instance:WaitForChild(v, Timeout)
    end
    return Instance
end

local function EnsureInstance(Instance: Instance?): boolean
    return (Instance and Instance:IsDescendantOf(game))
end

local function _round(num, numDecimalPlaces): number
    local mult = 10 ^ (numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

local function GetToggleValue(Name: string): boolean?
    local Toggle = Toggles[Name]

    if not Toggle then
        dbgwarn("Toggle not found:", Name)
        return nil
    else
        return Toggles.Value
    end
end

local function GetOptionValue(Name: string)
    local Option = Options[Name]

    if not Option then
        dbgwarn("Option not found:", Name)
        return nil
    else
        return Option.Value
    end
end

local Configuration = {
    CheckSafeRange = 50,
}

local Remotes = {
    ReelFinished = ReplicatedStorage.events:WaitForChild("reelfinished"),
    SellAll = ReplicatedStorage.events:WaitForChild("SellAll"),
}

-- Smt
local Interface = {
    Items = ReplicatedStorage.resources.items.items,
    -- FishRadar = Items["Fish Radar"]["Fish Radar"],
    TeleportSpots = WaitForTable(workspace, { "world", "spawns", "TpSpots" }),
    Inventory = WaitForTable(LocalPlayer.PlayerGui, { "hud", "safezone", "backpack" }),
}

local Collection = {}
local OnUnload = Instance.new("BindableEvent")

local function Collect(Item: RBXScriptConnection | thread)
    table.insert(Collection, Item)
end

local platform
local Camera = workspace.CurrentCamera

local ZoneFishOrigin = nil
local FishingZones = {}
local FishingZones_DropDownValues = {}

local PreAutoloadConfig = true

local State = {
    GettingMeteor = false,
    OwnedBoats = {},
}

-- Random function
local Utils = {}

do
    function Utils.CountInstances(Parent : Instance, Name : string) : number
        local Count = 0
        for _, Instance in next, Parent:GetChildren() do
            if Instance.Name == Name then
                Count += 1
            end
        end
        return Count
    end

    function Utils:BreakVelocity()
        if LocalPlayer.Character then
            task.spawn(function()
                for i = 20, 1, -1 do
                    RunService.Heartbeat:Wait()
                    for _, Part in next, LocalPlayer.Character:GetDescendants() do
                        if Part:IsA("BasePart") then
                            Part.Velocity = Vector3.new(0, 0, 0)
                            Part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                        end
                    end
                end
            end)
        end
    end

    function Utils.ToggleLocationCC(Value: boolean)
        local LocationCC = Lighting:FindFirstChild("location")

        if LocationCC then
            LocationCC.Enabled = Value
        end
    end    
    
    function Utils.ToggleUnderWater(Value: boolean)
        local underwaterbl = Lighting:FindFirstChild("underwaterbl")
        local underwatercc = Lighting:FindFirstChild("underwatercc")

        if underwaterbl then
            underwaterbl.Enabled = Value
        end
        if underwatercc then
            underwatercc.Enabled = Value
        end
    end

    function Utils.GameNotify(Message: string)
        ReplicatedStorage.events.anno_localthoughtbig:Fire(Message, nil, nil, nil, "Exotic")
    end

    function Utils.GetCharacters()
        local Characters = {}

        for _, Player: Player in next, Players:GetPlayers() do
            if Player.Character then
                table.insert(Characters, Player.Character)
            end
        end

        return Characters
    end

    function Utils.Character()
        return LocalPlayer.Character
    end

    function Utils.Humanoid(): Humanoid?
        local Character = Utils.Character()

        if Character then
            return Character:FindFirstChildOfClass("Humanoid")
        end

        return nil
    end

    function Utils.CastTo(A: Vector3, B: Vector3, Params: RaycastParams): RaycastResult?
        local Direction = (B - A)
        return workspace:Raycast(A, Direction, Params)
    end

    --[[
        Checks if there are any characters within range of a position.
        It raycasts from the position to the character's head, alongside checking a sphere of half the range around the position.
    ]]--
    function Utils.SafePosition(Position: Vector3, Range: number)
        local Characters = Utils.GetCharacters()
        local RayParams = RaycastParams.new()
        RayParams.FilterType = Enum.RaycastFilterType.Exclude
        RayParams.RespectCanCollide = true
        RayParams.FilterDescendantsInstances = Characters

        for _, Character in next, Characters do
            local Head = Character:FindFirstChild("Head")
            local Pivot = Character:GetPivot()

            if Head then
                local Raycast = Utils.CastTo(Position, Head.Position, RayParams)

                if Raycast then
                    return false
                end
            end

            if Pivot then
                local Distance = (Position - Pivot.Position).Magnitude * 0.5

                if Distance <= Range then
                    return false
                end
            end
        end

        return true
    end

    function Utils.TP(Target: Vector3 | CFrame | PVInstance, CheckSafe: boolean?): boolean
        local Pivot: CFrame

        if typeof(Target) == "CFrame" then
            Pivot = Target
        elseif typeof(Target) == "Vector3" then
            Pivot = CFrame.new(Target)
        elseif typeof(Target) == "PVInstance" then
            Pivot = Target:GetPivot()
        elseif typeof(Target) == "BasePart" then
            Pivot = Target:GetPivot()
        elseif typeof(Target) == "Model" then
            Pivot = Target:GetPivot()
        end

        if CheckSafe then
            if not Utils.SafePosition(Pivot.Position, Configuration.CheckSafeRange) then
                return false
            end
        end

        local Character = Utils.Character()
        if Character then
            Character:PivotTo(Pivot)
            return true
        end

        return false
    end

    function Utils.EliminateVelocity(Model: Model): nil
        for _, Part in next, Model:GetDescendants() do
            if Part:IsA("BasePart") then
                Part.Velocity = Vector3.new(0, 0, 0)
                Part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            end
        end
        return nil
    end

    function Utils.GetUsernameMatch(PartialName: string): Player?
        local BestMatch = nil
        local BestMatchLength = 0

        for _, Player in next, Players:GetPlayers() do
            if string.find(Player.Name:lower(), PartialName:lower()) then
                if #Player.Name > BestMatchLength then
                    BestMatch = Player
                    BestMatchLength = #Player.Name
                end
            end
        end

        return BestMatch
    end

    function Utils.CharacterChildAdded(Child: Instance)
        if Child:IsA("Tool") then
            CurrentTool = Child

        elseif Child:IsA("Humanoid") then
            Collect(Child.StateChanged:Connect(function()
                if Toggles.ZoneFish.Value then
                    Child:ChangeState(Enum.HumanoidStateType.Running)
                end
            end))
            Collect(Child.Died:Once(function()
                Toggles.ZoneFish:SetValue(false)
            end))
        end
    end

    function Utils.CharacterChildRemoved(Child: Instance)
        if Child:IsA("Tool") then
            CurrentTool = nil
        end
    end

    function Utils.CharacterAdded(Character: Model)
        for _, Child in next, Character:GetChildren() do
            Utils.CharacterChildAdded(Child)
        end
        Collect(Character.ChildAdded:Connect(Utils.CharacterChildAdded))
        Collect(Character.ChildRemoved:Connect(Utils.CharacterChildRemoved))
        local Zone = Character:WaitForChild("zone", 1) :: ObjectValue
    end

    function Utils.Capitalize(String: string): string
        return string.upper(string.sub(String, 1, 1)) .. string.sub(String, 2)
    end

    function Utils.GetNPC(Type: string, Single: boolean?): Model | { Model } | nil
        local function GetNPCType(NPC: Model) -- i hate this function so much
            local NPCType = "Unknown"

            if NPC:FindFirstChild("shipwright") then
                NPCType = "Shipwright"
            elseif NPC:FindFirstChild("merchant") then
                NPCType = "Merchant"
            elseif NPC:FindFirstChild("angler") then
                NPCType = "Angler"
            end

            return NPCType
        end

        local NPCs = Interface.NPCs:GetChildren()
        local Results = {}

        for _, Character in next, NPCs do
            local NPCType = GetNPCType(Character)

            if NPCType == Type then
                if Single then
                    return Character
                else
                    table.insert(Results, Character)
                end
            end
        end

        return nil
    end

    function Utils.UpdateShopDropdown()
        local Values = { "Bait Crate" }
    
        for _, Item in next, Interface.Items:GetChildren() do
            table.insert(Values, Item.Name)
        end
    
        table.sort(Values)
        Options.RemoteShopDropdown:SetValues(Values)
    end
    
    function Utils.UpdateFishingZonesDropdown()
        FishingZones={}
        FishingZones_DropDownValues={}
        for _, Zone in next, workspace:WaitForChild("zones"):WaitForChild("fishing"):GetChildren() do
            if not FishingZones[Zone.Name] then
                FishingZones[Zone.Name] = Zone
            end
        end

        for Name, Zone in next, FishingZones do
            table.insert(FishingZones_DropDownValues, Name)
            print(Name)
        end

        Options.ZoneFishDropdown:SetValues(FishingZones_DropDownValues)
    end

    function Utils.UpdateWaterPlatform()
        local Params = RaycastParams.new()
        Params.FilterType = Enum.RaycastFilterType.Include
        Params.FilterDescendantsInstances = {workspace.Terrain}
    
        -- Cast a ray down from the humanoid root part
        local RaycastResult = workspace:Raycast(LocalPlayer.Character.HumanoidRootPart.Position, -Vector3.yAxis * 20, Params)  -- Increased length for better detection
    
        if RaycastResult then
            -- Check if the ray hit water
            if RaycastResult.Instance:IsA("Terrain") and RaycastResult.Material == Enum.Material.Water then
                -- If the platform doesn't exist, create it
                if not platform then
                    platform = Instance.new("Part")
                    platform.Name = "wplatform"
                    platform.Size = Vector3.new(5, 0.1, 5)  -- Customize platform size
                    platform.Anchored = true
                    platform.CanCollide = true  -- Make it so players can walk on it
                    platform.BrickColor = BrickColor.new("Bright blue")  -- Change color if needed
                    platform.Parent = workspace  -- Parent to workspace
                end
    
                -- Update the platform position to the water surface
                platform.Position = RaycastResult.Position + Vector3.new(0, platform.Size.Y / 2, 0)
            end
        end
    end
end
print(1)
-- Test if hooking is enabled
pcall(function()
    if not (hookfunction and hookmetamethod) then
    hookfunction = function(...) end
    hookmetamethod = function(...) end
    NO_HOOKING = true
    end

    if not getconnections then
    getconnections = function(...) end
    end

    if not setthreadidentity then
    setthreadidentity = function(...) end
    end

    if getgenv().MainUnload then
    pcall(getgenv().MainUnload)
    end

    local Configuration = {
    CheckSafeRange = 50,
    }

    local Remotes = {
    ReelFinished = ReplicatedStorage.events:WaitForChild("reelfinished"),
    }
end)

-- smt to teleport
local TeleportLocations = {}
local TeleportLocations_DropDownValues = {}

for _, Location in next, Interface.TeleportSpots:GetChildren() do
    TeleportLocations[Utils.Capitalize(Location.Name)] = Location.Position + Vector3.new(0, 6, 0)
end

for Name, Position in next, TeleportLocations do
    table.insert(TeleportLocations_DropDownValues, Name)
end

table.sort(TeleportLocations_DropDownValues)

local function ResetTool()
    if CurrentTool then
        local ToolCache = LocalPlayer.Character:FindFirstChildOfClass("Tool")
        if CurrentTool then
            LocalPlayer.Character.Humanoid:UnequipTools()
            task.wait()
            ToolCache.Parent = LocalPlayer.Character
        end
    end
end

--Another skibidi
local function Unload()
    Library:Unload()

    for _, Item in ipairs(Collection) do
        if typeof(Item) == "RBXScriptConnection" then
            Item:Disconnect()
        end

        if type(Item) == "thread" then
            coroutine.close(Item)
        end
    end

    local Inventory = WaitForTable(LocalPlayer.PlayerGui, { "hud", "safezone", "backpack" })
    if Inventory then
        Inventory.Visible = true
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
    end

    Utils.ToggleLocationCC(true)

    if Toggles.ZoneFish.Value then
        task.defer(function()
            LocalPlayer.Character.Humanoid:UnequipTools()
            for _ = 1, 10 do
                task.wait()
                Utils.TP(ZoneFishOrigin.Position)
            end
            ZoneFishOrigin = nil
        end)
    end

    OnUnload:Fire()

    platform = nil
    Library = nil
    ThemeManager = nil
    SaveManager = nil
    Utils = nil
    AutoCastCoroutine = nil
    AutoClickCoroutine = nil
    AutoReelCoroutine = nil

    getgenv().Toggles = nil
    getgenv().Options = nil
    getgenv().sasware_fisch_unload = nil
    getgenv().MainUnload = nil
    Unload = nil

    Unloaded = true
end
getgenv().MainUnload = Unload
print(2)

-- Check PlaceVersion

if game.PlaceVersion > PreloadConstants.PlaceVersionSupport then

    local PromptToast, Button1, Button2 = InteractiveToast()
    PromptToast.Parent = CoreGui

    local Con1, Con2, Done

    Con1 = Button1.MouseButton1Click:Connect(function()
        PromptToast:Destroy()
        LocalPlayer:Kick("Aborted due to PlaceVersion being higher than supported version.")
        game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end)

    Con2 = Button2.MouseButton1Click:Connect(function()
        PromptToast:Destroy()
        Con1:Disconnect()
        Con2:Disconnect()
        Done = true
    end)

    repeat RunService.Heartbeat:Wait() until Done == true
end
print(3)

-- Load bypasses

pcall(function()
    if game.PlaceVersion >= 3744 and (game.PlaceVersion <= PreloadConstants.PlaceVersionSupport) then
        local URL = "https://raw.githubusercontent.com/cryptalmist/sasware-fisch/refs/heads/main/bypasses/"
            .. PreloadConstants.BypassVersion
            .. ".luau"

        local Success, Error = pcall(function()
            return loadstring(game:HttpGet(URL))()
        end)

        if not Success then
            LocalPlayer:Kick("Failed to load SasGuard! " .. Error)
        end
    end
end)

-- UI riel
local Window = Library:CreateWindow({
	Title = 'Mist | Fisch',
	Center = true,
	AutoShow = true,
	Resizable = true,
	NotifySide = "Right",
	TabPadding = 1,
	MenuFadeTime = 0,
	ShowCustomCursor = false,
})

local Tabs = {
	Main = Window:AddTab('Main'),
    Render = Window:AddTab('Visuals'),
	Settings = Window:AddTab("Settings"),
}

-- Fish haxmaxin
local FishingTabBox = Tabs.Main:AddLeftTabbox("Fishing")
local CastingGroup = FishingTabBox:AddTab("Casting")
local ReelingGroup = FishingTabBox:AddTab("Reeling")
local ShakingGroup = FishingTabBox:AddTab("Shaking")
local ZoneFishing = Tabs.Main:AddLeftGroupbox("Zone Fish")
pcall(function()
    CastingGroup:AddToggle("AutoCast", {
        Text = "Auto-cast",
        Default = false,
        Tooltip = "Automatically casts for you.",
    })

    CastingGroup:AddToggle("PerfectCast", {
        Text = "Always perfect [Server]",
        Default = false,
        Tooltip = "Makes your casts always perfect.",
    })

    CastingGroup:AddToggle("InstantBob", {
        Text = "Instant bob [Blatant]",
        Default = false,
        Tooltip = "Forces the bobber to fall instantly.",
    })

    ReelingGroup:AddToggle("AutoReel", {
        Text = "Auto-reel [Legit]",
        Default = false,
        Tooltip = "Automatically plays the reel minigame.",
        Callback = function(Value: boolean)
            if Value then
                Toggles.InstantReel:SetValue(false)
            end
        end,
    })

    ReelingGroup:AddToggle(
        "InstantReel", {
        Text = "Insta-reel [Blatant]",
        Default = false,
        Tooltip = "Automatically reels in fish instantly.",
        Callback = function(Value: boolean)
            if Value then
                Toggles.AutoReel:SetValue(false)
            end
        end,
    })

    ReelingGroup:AddToggle("PerfectReel", {
        Text = "Always perfect",
        Default = false,
        Tooltip = "Reels in fish perfectly!",
    })

    ShakingGroup:AddToggle("AutoShakeClick", {
        Text = "Auto shake (Click)",
        Default = true,
        Tooltip = "Automatically shakes the rod.",
        Callback = function(Value: boolean)
            if Value then
                Toggles.AutoShakeNav:SetValue(false)
                Toggles.CenterShake:SetValue(false)
            end
        end,
    })

    ShakingGroup:AddToggle("AutoShakeNav", {
        Text = "Auto shake (Navigation)",
        Default = false,
        Tooltip = "Automatically shakes the rod.",
        Callback = function(Value: boolean)
            if Value then
                Toggles.AutoShakeClick:SetValue(false)
            end
        end,
    })

    ShakingGroup:AddToggle("CenterShake", {
        Text = "Center-shake [Improves AutoShake]",
        Default = false,
        Tooltip = "Centers the shake ",
        Callback = function(Value: boolean)
            if Value then
                Toggles.AutoShakeClick:SetValue(false)
            end
        end,
    })

    ZoneFishing:AddToggle("ZoneFish", {
        Text = "Zone-fish",
        Default = false,
        Tooltip = "Zones fish for you.",
        Callback = function(Value: boolean)
            if Value then
                Toggles.InfiniteOxygen:SetValue(true)
                ZoneFishOrigin = LocalPlayer.Character:GetPivot()
            else
                if ZoneFishOrigin then
                    LocalPlayer.Character.Humanoid:UnequipTools()
                    for _ = 1, 10 do
                        task.wait()
                        Utils.TP(ZoneFishOrigin.Position)
                    end
                    ZoneFishOrigin = nil
                end
            end
        end,
    })

    ZoneFishing:AddDropdown("ZoneFishDropdown", {
        Values = {},
        Default = 1,
        Multi = false,
        Text = "Select zone",
        Tooltip = "Zone to fish in",
        Searchable = true,
    })

    ZoneFishing:AddButton("Refresh",function()
        Utils.UpdateFishingZonesDropdown()
    end)
end)

-- Teleport
local TeleportsGroupBox = Tabs.Main:AddLeftGroupbox("Teleports")

pcall(function()
    TeleportsGroupBox:AddDropdown("TeleportsDropdown", {
        Values = TeleportLocations_DropDownValues,
        Default = 1,
        Multi = false,
        Searchable = true,
        Text = "Select location",
        Tooltip = "Location to teleport to",
    })

    TeleportsGroupBox:AddButton("Teleport", function()
        local Selected = GetOptionValue("TeleportsDropdown")
        local Position = TeleportLocations[Selected]

        if Position then
            Utils.TP(Position)
        end
    end)
end)

-- Utilities
local UtilitiesGroupBox = Tabs.Main:AddRightGroupbox("Utilities")

pcall(function()
    --[[
    if not NO_HOOKING then
        UtilitiesGroupBox:AddToggle("FakeFishRadar", {
            Text = "Fish radar",
            Default = false,
            Tooltip = "A fake clientside fish radar.",
        }):AddKeyPicker("FakeFishRadarKeybind", {
            Default = "Insert",
            SyncToggleState = true,

            Mode = "Toggle",

            Text = "Fish radar",
            NoUI = false,
        })
    end
    ]]--

    UtilitiesGroupBox:AddToggle("DisablePeakEffects", {
        Text = "Disable oxygen/temperature",
        Default = false,
        Tooltip = "Disables peak effects."
    })

    UtilitiesGroupBox:AddToggle("InfiniteOxygen", {
        Text = "Infinite oxygen [Water]",
        Default = false,
        Tooltip = "Gives you infinite oxygen.",
    })

    UtilitiesGroupBox:AddToggle("AntiAFK", {
        Text = "Anti-AFK",
        Default = false,
        Tooltip = "Prevents you from being kicked for being AFK.",
    })

    UtilitiesGroupBox:AddDivider()
    UtilitiesGroupBox:AddLabel("Mobility")

    UtilitiesGroupBox:AddToggle("WalkOnWater", {
        Text = "Walk on water",
        Default = false,
        Tooltip = "duh uh"
    })

    UtilitiesGroupBox:AddSlider("WalkSpeed", {
        Text = "Walk Speed",
        Min = 16,
		Max = 300,
        Rounding = 0,
        Default = 16,
        Compact = true,
    })

    UtilitiesGroupBox:AddSlider("JumpPower", {
        Text = "Jump Power",
        Min = 50,
		Max = 300,
        Rounding = 0,
        Default = 50,
        Compact = true,
    })

    UtilitiesGroupBox:AddDivider()
    UtilitiesGroupBox:AddLabel("Tools")

    UtilitiesGroupBox:AddToggle("SpamTool", {
        Text = "Spam equipped tool",
        Default = false,
        Tooltip = "Spam-activates your equipped tool. [For crates]",
    })
end)

-- Shops
local ShopGroupBox = Tabs.Main:AddRightGroupbox("Remote Shop")

pcall(function()
	ShopGroupBox:AddDropdown("RemoteShopDropdown", {
        Values = {},
		Default = 1,
		Multi = false,
		Text = "Target item",
		Tooltip = "The item you want to buy",
        Searchable = true,
	})

    ShopGroupBox:AddSlider('BuyAmount', {
        Text = 'Amounts to buy',
        Default = 0,
        Min = 1,
        Max = 100,
        Rounding = 0,
        Compact = true,
    })

	ShopGroupBox:AddButton("Buy Items", function()
		local Selected = tostring(Options.RemoteShopDropdown.Value)
        local category = (Selected == "Bait Crate") and 'fish' or 'item'
        ReplicatedStorage.events.purchase:FireServer(Selected, category, nil, Options.BuyAmount.Value)
    end)
end)

-- Render
local CameraVisualsGroup = Tabs.Render:AddLeftGroupbox("Camera")
local WorldVisualGroup = Tabs.Render:AddRightGroupbox("World")

pcall(function()
	CameraVisualsGroup:AddToggle("NoLocationCC", {
		Text = "No ambient",
		Default = false,
		Tooltip = "Disables the location Color-Correction.",
	})

	CameraVisualsGroup:AddToggle("NoUnderWaterE", {
		Text = "No blur/color Under Water",
		Default = true,
		Tooltip = "Disables the under water Color-Correction and Blur effect.",
	})

    WorldVisualGroup:AddToggle("DestroyFish", {
        Text = "No fish models",
        Default = false,
        Tooltip = "Automatically deletes fish models.",
    })

    WorldVisualGroup:AddToggle("DisableInventory", {
        Text = "Disable custom inventory [+FPS]",
        Default = false,
        Tooltip = "Disables the inventory ",
        Callback = function(Value: boolean)
            if Interface.Inventory then
                Interface.Inventory.Visible = not Value
                StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, Value)
            end
        end,
    })
    

    WorldVisualGroup:AddToggle("PersistentModels", {
        Text = "Persistent map [-Ping]",
		Default = false,
		Tooltip = "Attempts to prevent models from being unloaded.",
		Callback = function(Value: boolean)
			if Value then
				for _, Descendant in next, workspace:GetDescendants() do
					if Descendant:IsA("Model") then
						if Descendant.ModelStreamingMode ~= Enum.ModelStreamingMode.Persistent then
							CollectionService:AddTag(Descendant, "ForcePersistent")
							Descendant:SetAttribute("OldStreamingMode", Descendant.ModelStreamingMode.Name)
							Descendant.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
						end
					end
				end
			else
				for _, PersistentModel: Model in next, CollectionService:GetTagged("ForcePersistent") do
					if PersistentModel:GetAttribute("OldStreamingMode") then
						local OldStreamingMode: string = PersistentModel:GetAttribute("OldStreamingMode") :: string
						PersistentModel.ModelStreamingMode =
							Enum.ModelStreamingMode[OldStreamingMode] :: Enum.ModelStreamingMode
					else
						PersistentModel.ModelStreamingMode = Enum.ModelStreamingMode.Default
					end

					CollectionService:RemoveTag(PersistentModel, "ForcePersistent")
					PersistentModel:SetAttribute("OldStreamingMode", nil)
				end
			end
		end,
	})
end)

-- Settings
local MenuGroup = Tabs.Settings:AddLeftGroupbox("Menu")

pcall(function()
    MenuGroup:AddButton("Unload", Unload)

    MenuGroup:AddLabel("Menu bind")
        :AddKeyPicker("MenuKeybind", { Default = "RightControl", NoUI = true, Text = "Menu keybind"})

    Library.ToggleKeybind = Options.MenuKeybind

    ThemeManager:SetLibrary(Library)
    SaveManager:SetLibrary(Library)

    SaveManager:IgnoreThemeSettings()

    SaveManager:SetIgnoreIndexes({ "MenuKeybind" })

    ThemeManager:SetFolder("MistHub")
    SaveManager:SetFolder("MistHub/fisch")

    SaveManager:BuildConfigSection(Tabs.Settings)

    ThemeManager:ApplyToTab(Tabs.Settings)
end)

-- Sigma toggles

Toggles.InfiniteOxygen:OnChanged(function(Value: boolean)
    if Value then
        LocalPlayer.Character.Resources.oxygen.Enabled=false
    else
        LocalPlayer.Character.Resources.oxygen.Enabled=true
    end
end)

Toggles.DisablePeakEffects:OnChanged(function(Value: boolean)
    if Value then
        LocalPlayer.Character.Resources:WaitForChild("oxygen(peaks)").Enabled = false
        LocalPlayer.Character.Resources:WaitForChild("temperature(heat)").Enabled = false
        LocalPlayer.Character.Resources.temperature.Enabled = false
    else
        LocalPlayer.Character.Resources:WaitForChild("oxygen(peaks)").Enabled = true
        LocalPlayer.Character.Resources:WaitForChild("temperature(heat)").Enabled = true
        LocalPlayer.Character.Resources.temperature.Enabled = true
    end
end)

-- W coroutine

local AutoCastCoroutine = coroutine.create(function()
    local LastCastAttempt = 0
    local ResetCooldown = 6 -- Cooldown duration in seconds

    while task.wait(0.1) do
        if Toggles.AutoCast.Value then
            pcall(function()
                if not CurrentTool then
                    return
                end
    
                local Values = CurrentTool:FindFirstChild("values")
                if CurrentTool and Values then
                    local Events = CurrentTool:FindFirstChild("events")
    
                    -- Fix for tool resetting spam
                    if
                        Values:FindFirstChild("bite")
                        and Values.bite.Value == true
                        and Values.casted.Value == true
                    then
                        if (not LocalPlayer.PlayerGui:FindFirstChild("reel")) and (tick() - LastResetAttempt > ResetCooldown) then
                            LastResetAttempt = tick()
                            ResetTool()
                        end
                    end
    
                    -- Another fix
                    if Utils.CountInstances(LocalPlayer.PlayerGui, "reel") > 1 then
                        if tick() - LastResetAttempt > ResetCooldown then
                            LastResetAttempt = tick()
                            ResetTool()
                            for _, Child in next, LocalPlayer.PlayerGui:GetChildren() do
                                if Child.Name == "reel" then
                                    Child:Destroy()
                                end
                            end
                        end
                    end

                    if Values.casted.Value == false then
                        LastCastAttempt = tick()

                        local AnimationFolder = ReplicatedStorage:WaitForChild("resources")
                            :WaitForChild("animations")

                        local CastAnimation: AnimationTrack = LocalPlayer.Character
                            :FindFirstChild("Humanoid")
                            :LoadAnimation(AnimationFolder.fishing.throw)
                        CastAnimation.Priority = Enum.AnimationPriority.Action3
                        CastAnimation:Play()
                        Events.cast:FireServer(100, 1)

                        CastAnimation.Stopped:Once(function()
                            CastAnimation:Destroy()

                            local WaitingAnimation: AnimationTrack = LocalPlayer.Character
                                :FindFirstChild("Humanoid")
                                :LoadAnimation(AnimationFolder.fishing.waiting)
                            WaitingAnimation.Priority = Enum.AnimationPriority.Action3
                            WaitingAnimation:Play()

                            local UnequippedLoop, CastConnection

                            CastConnection = Values.casted.Changed:Once(function()
                                WaitingAnimation:Stop()
                                WaitingAnimation:Destroy()
                                coroutine.close(UnequippedLoop)
                            end)

                            UnequippedLoop = coroutine.create(function()
                                repeat
                                    task.wait()
                                until not CurrentTool
                                WaitingAnimation:Stop()
                                WaitingAnimation:Destroy()
                                CastConnection:Disconnect()
                            end)

                            coroutine.resume(UnequippedLoop)
                        end)
                    end
                end
            end)
        end
    end
end)

local AutoClickCoroutine = coroutine.create(function()
    function Utils.MountShakeUI(ShakeUI: ScreenGui)
        local SafeZone: Frame? = ShakeUI:WaitForChild("safezone", 5) :: Frame?

        -- Auto click toggle
        if Toggles.AutoShakeClick.Value then
            while LocalPlayer.PlayerGui:FindFirstChild("shakeui") do
                pcall(function()
                    local Button = SafeZone:FindFirstChild("button")
                    if Button then
                        Button.Size = UDim2.new(1000, 0, 1000, 0)
                        VirtualUser:Button1Down(Vector2.new(1, 1))
                        VirtualUser:Button1Up(Vector2.new(1, 1))
                    end
                end)
                wait()
            end
            return
        end

        local function HandleButton(Button: ImageButton)
            Button.Selectable = true -- For some reason this is false for the first 0.2 seconds.

            GuiService.AutoSelectGuiEnabled = false
            GuiService.GuiNavigationEnabled = true

            if EnsureInstance(Button) then
                GuiService.SelectedObject = Button
                task.wait()
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
                task.wait()
            end

            GuiService.AutoSelectGuiEnabled = true
            GuiService.GuiNavigationEnabled = false
            GuiService.SelectedObject = nil
        end

        -- Center SafeZone if toggle enabled
        if Toggles.CenterShake.Value then
            local Connect = SafeZone:WaitForChild("connect", 1)
            if Connect then
                Connect.Enabled = false -- Lock size of SafeZone
            end
            SafeZone.Size = UDim2.fromOffset(0, 0)
            SafeZone.Position = UDim2.fromScale(0.5, 0.5)
            SafeZone.AnchorPoint = Vector2.new(0.5, 0.5)
        end

        if Toggles.AutoShakeNav.Value then
            local Connection = SafeZone.ChildAdded:Connect(function(Child)
                if Child:IsA("ImageButton") then
                    local Done = false
                    print("New button detected:", Child)

                    task.spawn(function()
                        repeat
                            RunService.RenderStepped:Wait()
                            HandleButton(Child)
                        until Done
                    end)

                    task.spawn(function()
                        repeat
                            RunService.RenderStepped:Wait()
                        until (not Child) or (not Child:IsDescendantOf(SafeZone))
                        Done = true
                    end)
                end
            end)

            repeat
                wait()
            until not SafeZone:IsDescendantOf(LocalPlayer.PlayerGui)
            Connection:Disconnect()
        end
    end

    Collect(LocalPlayer.PlayerGui.ChildAdded:Connect(function(Child: Instance)
        if Child.Name == "shakeui" and Child:IsA("ScreenGui") then
            Utils.MountShakeUI(Child)
        end
    end))
end)

local AutoReelCoroutine = coroutine.create(function()
    while true do
        RunService.RenderStepped:Wait()

        local ReelUI: ScreenGui = LocalPlayer.PlayerGui:FindFirstChild("reel")

        if not ReelUI then
            continue
        end

        if Toggles.InstantReel.Value then
            local Bar = ReelUI:FindFirstChild("bar")

            if Bar then
                local ReelScript = Bar:FindFirstChild("reel")
                if ReelScript and ReelScript.Enabled == true then
                    Remotes.ReelFinished:FireServer(100, Toggles.PerfectReel.Value)
                end
            end
        elseif Toggles.AutoReel.Value then
            local Bar = ReelUI:FindFirstChild("bar")

            if not Bar then
                continue
            end

            local PlayerBar: Frame = Bar:FindFirstChild("playerbar")
            local TargetBar: Frame = Bar:FindFirstChild("fish")

            while Bar and ReelUI:IsDescendantOf(LocalPlayer.PlayerGui) do
                RunService.RenderStepped:Wait()
                local UnfilteredTargetPosition = PlayerBar.Position:Lerp(TargetBar.Position, 0.7)
                local TargetPosition = UDim2.fromScale(
                    math.clamp(UnfilteredTargetPosition.X.Scale, 0.15, 0.85),
                    UnfilteredTargetPosition.Y.Scale
                )

                PlayerBar.Position = TargetPosition
            end
        end
    end
end)

local PlayerStatsCoroutine = coroutine.create(function()
    while task.wait(1) do
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = Options.WalkSpeed.Value
            LocalPlayer.Character.Humanoid.JumpPower = Options.JumpPower.Value
        end
    end
end)

-- Nah i'd steal

--Render shit :)
Collect(RunService.RenderStepped:Connect(function()
    if Toggles.SpamTool.Value then
        if CurrentTool then
            for i = 20, 1, -1 do
                CurrentTool:Activate()
            end
        end
    end

    if Toggles.NoLocationCC.Value then
        Utils.ToggleLocationCC(false)
    else
        Utils.ToggleLocationCC(true)
    end

    if Toggles.NoUnderWaterE.Value then
        Utils.ToggleUnderWater(false)
    else
        Utils.ToggleUnderWater(true)
    end
end))

Collect(RunService.PostSimulation:Connect(function()
    if Toggles.ZoneFish.Value then
        if State.GettingMeteor then
            return -- dont conflict with meteor grabbing
        end

        for _, Part in next, LocalPlayer.Character:GetDescendants() do
            if Part:IsA("BasePart") then
                Part.CanTouch = false -- killzones and such
            end
        end

        local Zone = FishingZones[Options.ZoneFishDropdown.Value]

        if Zone then
            local Origin = Zone:GetPivot()
            Utils.TP(Origin + Vector3.new(0, -20, 0))

            if CurrentTool then
                local Bobber = CurrentTool:FindFirstChild("bobber")
                if Bobber then
                    local Rope = Bobber:FindFirstChildOfClass("RopeConstraint")
                    if Rope then
                        Rope.Length = 9e9
                    end
                    Bobber:PivotTo(Origin)
                end
            end
        end
    elseif Toggles.InstantBob.Value then
        if CurrentTool then
            local Bobber = CurrentTool:FindFirstChild("bobber")
            if Bobber then
                local Params = RaycastParams.new()
                Params.FilterType = Enum.RaycastFilterType.Include
                Params.FilterDescendantsInstances = { workspace.Terrain }
        
                local RaycastResult = workspace:Raycast(Bobber.Position, -Vector3.yAxis * 100, Params)
        
                if RaycastResult then
                    if RaycastResult.Instance:IsA("Terrain") and RaycastResult.Material == Enum.Material.Water then
                        Bobber:PivotTo(CFrame.new(RaycastResult.Position))
                    end
                end
            end
        end
    end

    if Toggles.WalkOnWater.Value then
        Utils.UpdateWaterPlatform()
    else platform = nil
    end
end))

Collect(LocalPlayer.Idled:Connect(function()
    if GetToggleValue("AntiAFK") then -- pasted from infinite yield weeeeeeeee
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end))

Collect(workspace:WaitForChild("active").ChildAdded:Connect(function(Child: Instance)
    if Child:IsA("Model") then
        local Fish = Child:WaitForChild("Fish", 1)

        if Fish then
            if GetToggleValue("DestroyFish") then
                task.wait()
                Child:Destroy()
            end
        end
    end
end))

Collect(Interface.Inventory:GetPropertyChangedSignal("Visible"):Connect(function()
    if GetToggleValue("DisableInventory") then
        task.wait()
        Interface.Inventory.Visible = false
    end
end))

-- Resume coroutines
coroutine.resume(AutoClickCoroutine)
coroutine.resume(AutoReelCoroutine)
coroutine.resume(AutoCastCoroutine)
coroutine.resume(PlayerStatsCoroutine)

Collect(LocalPlayer.CharacterAdded:Connect(Utils.CharacterAdded))

if LocalPlayer.Character then
    Utils.CharacterAdded(LocalPlayer.Character)
end
print(1)
Utils.UpdateShopDropdown()
Utils.UpdateFishingZonesDropdown()

SaveManager:LoadAutoloadConfig()
PreAutoloadConfig = false
Utils.GameNotify("Mist 🔥")
