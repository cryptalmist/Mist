--// USER CONFIG (re-executable safe)
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
    "Free Royal Jelly Dispenser"
}
getgenv().ToyCheckDelay = getgenv().ToyCheckDelay or 5
local SAFETY_WINDOW = 40 * 60 -- 40 min

--// STOP OLD LOOP BEFORE STARTING NEW ONE
if getgenv()._ToyLoopRunning then
    getgenv()._ToyLoopRunning = false
    task.wait(0.1)
end
getgenv()._ToyLoopRunning = true

--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ToyEvent = ReplicatedStorage.Events:WaitForChild("ToyEvent")
local RetrieveStats = ReplicatedStorage.Events:WaitForChild("RetrievePlayerStats")

--// SERVER DATA (FULL TABLE)
local toyTimes = {}

--// LOCAL LAST USE TRACKER
local localUse = {}

--// function: full refresh
local function refreshToyTimes()
    local ok, stats = pcall(function()
        return RetrieveStats:InvokeServer()
    end)
    if ok and stats and stats.ToyTimes then
        toyTimes = stats.ToyTimes
    end
end

-- Initial refresh
refreshToyTimes()

--// readiness check (local-first)
local function isReady(toyName)
    local toy = workspace:FindFirstChild("Toys") and workspace.Toys:FindFirstChild(toyName)
    if not toy then return false end

    local cdObj = toy:FindFirstChild("Cooldown")
    if not cdObj then return false end
    local cooldown = cdObj.Value

    -- local cooldown first
    local lastLocal = localUse[toyName]
    if lastLocal then
        local elapsed = os.time() - lastLocal
        if elapsed < cooldown and elapsed < SAFETY_WINDOW then
            return false
        end
    end

    -- if passes local check, check actual server (but cached)
    local lastServer = toyTimes[toyName]
    if not lastServer then return true end
    return (os.time() - lastServer) >= cooldown
end

--// MAIN LOOP
task.spawn(function()
    while getgenv()._ToyLoopRunning do
        for _, toyName in ipairs(getgenv().Toys) do
            if isReady(toyName) then
                -- use toy
                ToyEvent:FireServer(toyName)

                -- store local usage
                localUse[toyName] = os.time()

                -- refresh from server after 2s
                task.delay(2, function()
                    refreshToyTimes()
                end)
            end
        end
        task.wait(getgenv().ToyCheckDelay)
    end
end)

print("✅ Smart Toy Loop Running (40min safety, full refresh 2s after use)")
