-- GuiBuilder.lua
-- Builds a polished Rayfield UI for Abyss Shadows.

local Players = game:GetService("Players")

local Constants = require(script.Parent.Constants)
local Utils = require(script.Parent.Utils)
local DataManager = require(script.Parent.DataManager)
local Scanner = require(script.Parent.Scanner)
local Farming = require(script.Parent.Farming)
local ChestManager = require(script.Parent.ChestManager)
local GemManager = require(script.Parent.GemManager)

local GuiBuilder = {}

local function formatLabel(name, value)
    return string.format("%s: %s", name, tostring(value or "Unknown"))
end

local function safeCall(fn, ...)
    if type(fn) ~= "function" then
        return false
    end
    return pcall(fn, ...)
end

local function buildMetrics()
    return {
        { Title = "Player", Value = Players.LocalPlayer and Players.LocalPlayer.Name or "Unknown" },
        { Title = "Location", Value = DataManager.State.CurrentLocation },
        { Title = "Status", Value = DataManager.State.Status },
        { Title = "NPCs", Value = #Scanner.NPCCache },
        { Title = "Chests", Value = #Scanner.ChestCache },
        { Title = "Session Gems", Value = DataManager.State.SessionGems },
        { Title = "Gems / Min", Value = math.floor(DataManager.State.GemsPerMinute) },
    }
end

function GuiBuilder:Build()
    local rayfieldSource = Utils.SafeHttpGetAny(Constants.RayfieldUrls or {Constants.RayfieldUrl})
    if not rayfieldSource or rayfieldSource == "" then
        error("[AbyssShadows] Failed to download Rayfield UI from any configured URL.")
    end

    local Rayfield, loadError = Utils.SafeLoadString(rayfieldSource, Constants.RayfieldUrl)
    if not Rayfield then
        error("[AbyssShadows] Failed to load Rayfield UI: " .. tostring(loadError))
    end

    if type(Rayfield) == "function" then
        Rayfield = Rayfield()
    end
    if type(Rayfield) ~= "table" then
        error("[AbyssShadows] Rayfield loader returned invalid library type.")
    end

    local Window = Rayfield:CreateWindow({
        Name = "Abyss Shadows",
        Icon = 0,
        LoadingTitle = "Abyss Shadows",
        LoadingSubtitle = "Premium Farm Panel",
        ShowText = "Abyss",
        Theme = "Dark",
        ToggleUIKeybind = "K",
        DisableRayfieldPrompts = true,
        DisableBuildWarnings = true,
        ConfigurationSaving = {
            Enabled = true,
            FolderName = "AbyssShadows",
            FileName = "Settings"
        },
        KeySystem = false,
    })

    local homeTab = Window:CreateTab("Home")
    local farmTab = Window:CreateTab("Auto Farm")
    local chestTab = Window:CreateTab("Chests")
    local gemsTab = Window:CreateTab("Gems")
    local scannerTab = Window:CreateTab("NPC Scanner")
    local debugTab = Window:CreateTab("Debug")

    pcall(function()
        Scanner:ScanNpcs()
    end)
    pcall(function()
        Scanner:ScanChests()
    end)
    pcall(function()
        Scanner:ScanGems()
    end)

    local overviewSection = homeTab:CreateSection("Overview")
    local success, metrics = pcall(buildMetrics)
    metrics = success and metrics or {}
    for _, metric in ipairs(metrics) do
        overviewSection:CreateLabel({
            Name = formatLabel(metric.Title, metric.Value),
        })
    end

    homeTab:CreateParagraph({
        Title = "Panel Summary",
        Content = "Abyss Shadows provides clean control over farming, chests, gems, and NPC scanning. Use the tabs to start and stop automation safely.",
    })

    homeTab:CreateButton({
        Name = "Refresh Overview",
        Callback = function()
            Scanner:ScanNpcs()
            Scanner:ScanChests()
            Scanner:ScanGems()
            Rayfield:Notify({ Title = "Overview", Content = "Data refreshed.", Duration = 3 })
        end,
    })

    local farmSection = farmTab:CreateSection("Farm Control")
    farmSection:CreateToggle({
        Name = "Auto Farm",
        CurrentValue = Constants.Defaults.AutoFarm,
        Flag = "AutoFarmEnabled",
        Callback = function(enabled)
            Constants.Defaults.AutoFarm = enabled
            if enabled then
                Scanner:ScanNpcs()
                Farming:Start()
                Rayfield:Notify({ Title = "Auto Farm", Content = "Auto farming enabled.", Duration = 3 })
            else
                Farming:Stop()
                Rayfield:Notify({ Title = "Auto Farm", Content = "Auto farming disabled.", Duration = 3 })
            end
        end,
    })

    farmSection:CreateDropdown({
        Name = "Target Priority",
        Options = Constants.TargetPriorities,
        CurrentOption = Constants.Defaults.TargetPriority,
        Flag = "TargetPriority",
        Callback = function(option)
            Constants.Defaults.TargetPriority = option
        end,
    })

    farmSection:CreateSlider({
        Name = "Attack Range",
        Min = 10,
        Max = 80,
        Increment = 1,
        Suffix = "studs",
        CurrentValue = Constants.Defaults.AttackRange,
        Flag = "AttackRange",
        Callback = function(value)
            Constants.Defaults.AttackRange = value
        end,
    })

    local farmControlSection = farmTab:CreateSection("Actions")
    farmControlSection:CreateButton({
        Name = "Start Farming",
        Callback = function()
            Scanner:ScanNpcs()
            Farming:Start()
            Rayfield:Notify({ Title = "Farming", Content = "Farming started.", Duration = 3 })
        end,
    })
    farmControlSection:CreateButton({
        Name = "Stop Farming",
        Callback = function()
            Farming:Stop()
            Rayfield:Notify({ Title = "Farming", Content = "Farming stopped.", Duration = 3 })
        end,
    })

    farmTab:CreateParagraph({
        Title = "Current Farm Status",
        Content = string.format("Target: %s\nHealth: %s\nState: %s", DataManager.State.CurrentTargetName, DataManager.State.CurrentTargetHealth, DataManager.State.Status),
    })

    local chestSection = chestTab:CreateSection("Chest Automation")
    chestSection:CreateToggle({
        Name = "Auto Collect Chests",
        CurrentValue = Constants.Defaults.AutoChests,
        Flag = "AutoCollectChests",
        Callback = function(enabled)
            Constants.Defaults.AutoChests = enabled
            if enabled then
                Scanner:ScanChests()
                ChestManager:Start()
                Rayfield:Notify({ Title = "Chests", Content = "Chest auto-collect enabled.", Duration = 3 })
            else
                ChestManager:Stop()
                Rayfield:Notify({ Title = "Chests", Content = "Chest auto-collect disabled.", Duration = 3 })
            end
        end,
    })
    chestSection:CreateSlider({
        Name = "Chest Range",
        Min = 10,
        Max = 80,
        Increment = 1,
        Suffix = "studs",
        CurrentValue = Constants.Defaults.ChestRange,
        Flag = "ChestRange",
        Callback = function(value)
            Constants.Defaults.ChestRange = value
        end,
    })
    chestSection:CreateButton({
        Name = "Refresh Chest List",
        Callback = function()
            Scanner:ScanChests()
            Rayfield:Notify({ Title = "Chests", Content = string.format("Found %d chests.", #Scanner.ChestCache), Duration = 3 })
        end,
    })
    chestTab:CreateParagraph({
        Title = "Chest Status",
        Content = string.format("Current chest: %s", tostring(DataManager.State.ChestTarget)),
    })

    local gemSection = gemsTab:CreateSection("Gem Automation")
    gemSection:CreateToggle({
        Name = "Auto Collect Gems",
        CurrentValue = Constants.Defaults.AutoGems,
        Flag = "AutoCollectGems",
        Callback = function(enabled)
            Constants.Defaults.AutoGems = enabled
            if enabled then
                Scanner:ScanGems()
                GemManager:Start()
                Rayfield:Notify({ Title = "Gems", Content = "Gem auto-collect enabled.", Duration = 3 })
            else
                GemManager:Stop()
                Rayfield:Notify({ Title = "Gems", Content = "Gem auto-collect disabled.", Duration = 3 })
            end
        end,
    })
    gemSection:CreateLabel({ Name = formatLabel("Session Gems", DataManager.State.SessionGems) })
    gemSection:CreateLabel({ Name = formatLabel("Gems / Min", math.floor(DataManager.State.GemsPerMinute)) })
    gemSection:CreateButton({
        Name = "Refresh Gem Scan",
        Callback = function()
            Scanner:ScanGems()
            Rayfield:Notify({ Title = "Gems", Content = string.format("Found %d gems.", #Scanner.GemCache), Duration = 3 })
        end,
    })

    local scannerSection = scannerTab:CreateSection("Scanner Tools")
    scannerSection:CreateButton({
        Name = "Scan NPCs",
        Callback = function()
            local npcs = Scanner:ScanNpcs()
            Rayfield:Notify({ Title = "NPC Scanner", Content = string.format("Found %d NPCs.", #npcs), Duration = 3 })
        end,
    })
    scannerSection:CreateButton({
        Name = "Scan Chests",
        Callback = function()
            local chests = Scanner:ScanChests()
            Rayfield:Notify({ Title = "NPC Scanner", Content = string.format("Found %d chests.", #chests), Duration = 3 })
        end,
    })
    scannerSection:CreateButton({
        Name = "Scan Gems",
        Callback = function()
            local gems = Scanner:ScanGems()
            Rayfield:Notify({ Title = "NPC Scanner", Content = string.format("Found %d gems.", #gems), Duration = 3 })
        end,
    })

    local debugSection = debugTab:CreateSection("Debug")
    debugSection:CreateButton({
        Name = "Print Detected Objects",
        Callback = function()
            warn("NPCs:", #Scanner.NPCCache, "Chests:", #Scanner.ChestCache, "Gems:", #Scanner.GemCache)
            Rayfield:Notify({ Title = "Debug", Content = "Printed detected objects.", Duration = 3 })
        end,
    })

    Rayfield:LoadConfiguration()
    Window.Flags = Window.Flags or {}

    local function syncSavedSettings()
        local flags = Window.Flags or {}
        Constants.Defaults.AutoFarm = flags.AutoFarmEnabled or Constants.Defaults.AutoFarm
        Constants.Defaults.TargetPriority = flags.TargetPriority or Constants.Defaults.TargetPriority
        Constants.Defaults.AttackRange = flags.AttackRange or Constants.Defaults.AttackRange
        Constants.Defaults.AutoChests = flags.AutoCollectChests or Constants.Defaults.AutoChests
        Constants.Defaults.ChestRange = flags.ChestRange or Constants.Defaults.ChestRange
        Constants.Defaults.AutoGems = flags.AutoCollectGems or Constants.Defaults.AutoGems

        pcall(function()
            if Constants.Defaults.AutoFarm then
                Farming:Start()
            end
        end)
        pcall(function()
            if Constants.Defaults.AutoChests then
                ChestManager:Start()
            end
        end)
        pcall(function()
            if Constants.Defaults.AutoGems then
                GemManager:Start()
            end
        end)
    end

    syncSavedSettings()
    Rayfield:Notify({ Title = "Abyss Shadows", Content = "Interface loaded.", Duration = 4 })
end

return GuiBuilder
