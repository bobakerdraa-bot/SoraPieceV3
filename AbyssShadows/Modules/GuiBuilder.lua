-- GuiBuilder.lua
-- Minimal Rayfield UI builder for Abyss Shadows.

local Constants = require(script.Parent:FindFirstChild("Constants") or error("[AbyssShadows] Missing Constants"))
local Utils = require(script.Parent:FindFirstChild("Utils") or error("[AbyssShadows] Missing Utils"))
local ExecutorCompat = require(script.Parent:FindFirstChild("ExecutorCompat") or error("[AbyssShadows] Missing ExecutorCompat"))

local function isFunction(value)
    return type(value) == "function"
end

local function isTable(value)
    return type(value) == "table"
end

local DataManagerDefaults = {
    CurrentLocation = "Unknown",
    Status = "Unknown",
    CurrentTargetName = "None",
    CurrentTargetHealth = 0,
    ChestTarget = "None",
    SessionGems = 0,
    GemsPerMinute = 0,
}

local function normalizeNumber(value, default)
    local numberValue = tonumber(value)
    if numberValue == nil then
        return default
    end
    return numberValue
end

local function normalizeString(value, default)
    if value == nil then
        return default
    end
    return tostring(value)
end

local function safeLoadDataManager()
    local dataManagerModule = script.Parent:FindFirstChild("DataManager")
    if not dataManagerModule then
        return nil, "DataManager module missing"
    end
    local ok, dataManager = pcall(require, dataManagerModule)
    if not ok then
        return nil, "Failed to require DataManager: " .. tostring(dataManager)
    end
    if not isTable(dataManager) then
        return nil, "DataManager did not return a table"
    end
    if not isTable(dataManager.State) then
        return nil, "DataManager.State missing or invalid"
    end
    if not isFunction(dataManager.EnsureState) then
        return nil, "DataManager missing EnsureState"
    end
    dataManager:EnsureState()
    return dataManager, nil
end

local function safeGetStateValue(dataManager, key)
    if isTable(dataManager) and isFunction(dataManager.GetState) then
        local ok, value = pcall(dataManager.GetState, dataManager, key)
        if ok and value ~= nil then
            if type(DataManagerDefaults[key]) == "number" then
                return normalizeNumber(value, DataManagerDefaults[key])
            end
            return tostring(value)
        end
    end
    local default = DataManagerDefaults[key]
    if default == nil then
        return "Unknown"
    end
    if type(default) == "number" then
        return default
    end
    return tostring(default)
end

local function safeUpdateState(dataManager, key, value)
    if not isTable(dataManager) or not isFunction(dataManager.UpdateStat) then
        return
    end
    pcall(function()
        dataManager:UpdateStat(key, value)
    end)
end

local function safeCreateStateLabel(section, labelName, stateKey, dataManager)
    return safeCreateElement(section, "CreateLabel", {
        Name = labelName .. ": " .. tostring(safeGetStateValue(dataManager, stateKey)),
    })
end

local function safeCreateWindow(rayfield, options)
    if not rayfield or not isFunction(rayfield.CreateWindow) then
        return nil, "[AbyssShadows] Rayfield missing CreateWindow"
    end
    local ok, window = pcall(rayfield.CreateWindow, rayfield, options)
    if not ok then
        return nil, tostring(window)
    end
    if type(window) ~= "table" then
        return nil, "[AbyssShadows] CreateWindow returned non-table"
    end
    return window, nil
end

local function safeCreateTab(window, name)
    if not window or not isFunction(window.CreateTab) then
        return nil, "[AbyssShadows] Window missing CreateTab"
    end
    local ok, tab = pcall(window.CreateTab, window, name)
    if not ok then
        return nil, tostring(tab)
    end
    if type(tab) ~= "table" then
        return nil, "[AbyssShadows] CreateTab returned non-table"
    end
    return tab, nil
end

local function safeCreateSection(tab, name)
    if not tab or not isFunction(tab.CreateSection) then
        return nil, "[AbyssShadows] Tab missing CreateSection"
    end
    local ok, section = pcall(tab.CreateSection, tab, name)
    if not ok then
        return nil, tostring(section)
    end
    if type(section) ~= "table" then
        return nil, "[AbyssShadows] CreateSection returned non-table"
    end
    return section, nil
end

local function safeCreateElement(parent, methodName, config)
    if not parent or not isFunction(parent[methodName]) then
        return false, "[AbyssShadows] Missing element method: " .. tostring(methodName)
    end
    local ok, result = pcall(parent[methodName], parent, config)
    if not ok then
        return false, tostring(result)
    end
    return true, result
end

local function safeNotify(rayfield, payload)
    if not rayfield or not isFunction(rayfield.Notify) then
        return false, "[AbyssShadows] Rayfield missing Notify"
    end
    local ok, result = pcall(rayfield.Notify, rayfield, payload)
    if not ok then
        return false, tostring(result)
    end
    return true, result
end

local ConfigFolderName = "Rayfield/Configurations"
local ConfigFileName = "Abyss_Shadow"

local function getConfigPath()
    return ConfigFolderName .. "/" .. ConfigFileName .. ".rfld"
end

local function ensureConfigFolder()
    if ExecutorCompat.SafeIsFolder(ConfigFolderName) then
        return true
    end
    return ExecutorCompat.SafeMakeFolder(ConfigFolderName)
end

local fnot ensureConfigFolder() then
        return false, "failed to ensure configuration folder"
    end
    local ok, result = ExecutorCompat.SafeWriteFile(getConfigPath(), tostring(content or "{}"))
    if not ok then
        return false, tostring(result)
    end
    return true
end

local function safeDeleteConfigFile()
    local ok, result = ExecutorCompat.SafeDeleteFile(getConfigPath())
    if not ok then
        return false, tostring(result)
    end
    return true
    return safeWriteConfigFile("{}")
end

local function safeReloadConfiguration(rayfield)
    if not rayfield or not isFunction(rayfield.LoadConfiguration) then
        return false, "Rayfield missing LoadConfiguration"
    end
    local ok, result = pcall(rayfield.LoadConfiguration, rayfield)
    return ok, result
end

local function safeResetConfiguration(rayfield)
    local ok, result = safeDeleteConfigFile()
    if not ok then
        return false, result
    end
    return safeReloadConfiguration(rayfield)
end

local function safeLoadScanner()
    local scannerModule = script.Parent:FindFirstChild("Scanner")
    if not scannerModule then
        return nil, "Scanner module missing"
    end
    local ok, scanner = pcall(require, scannerModule)
    if not ok then
        return nil, "Failed to require Scanner: " .. tostring(scanner)
    end
    if not isTable(scanner) then
        return nil, "Scanner did not return a table"
    end

    local missing = {}
    if not isFunction(scanner.ScanNpcs) then
        table.insert(missing, "ScanNpcs")
    end
    if not isFunction(scanner.ScanChests) then
        table.insert(missing, "ScanChests")
    end
    if not isFunction(scanner.ScanGems) then
        table.insert(missing, "ScanGems")
    end
    if not isTable(scanner.NPCCache) then
        table.insert(missing, "NPCCache")
    end
    if not isTable(scanner.ChestCache) then
        table.insert(missing, "ChestCache")
    end
    if not isTable(scanner.GemCache) then
        table.insert(missing, "GemCache")
    end

    if #missing > 0 then
        return scanner, "Scanner missing: " .. table.concat(missing, ", ")
    end
    return scanner, nil
end

local function safeRunScanner(scanner, methodName, cacheName)
    if not isTable(scanner) then
        return false, "Scanner module missing or invalid"
    end
    if not isFunction(scanner[methodName]) then
        return false, methodName .. " missing"
    end
    local ok, result = pcall(scanner[methodName], scanner)
    if not ok then
        return false, tostring(result)
    end
    local cache = scanner[cacheName]
    if not isTable(cache) then
        return false, cacheName .. " missing or invalid"
    end
    return true, #cache
end

local function safeCreateScannerButton(section, rayfield, scanner, name, methodName, cacheName)
    return safeCreateElement(section, "CreateButton", {
        Name = name,
        Callback = function()
            local success, value = safeRunScanner(scanner, methodName, cacheName)
            if success then
                safeCreateElement(section, "CreateLabel", {
                    Name = name .. " count: " .. tostring(value),
                })
                safeNotify(rayfield, {
                    Title = "Abyss_Shadow",
                    Content = name .. " found: " .. tostring(value),
                    Duration = 4,
                })
            else
                safeCreateElement(section, "CreateLabel", {
                    Name = name .. " failed: " .. tostring(value),
                })
                safeNotify(rayfield, {
                    Title = "Abyss_Shadow",
                    Content = name .. " failed: " .. tostring(value),
                    Duration = 4,
                })
                warn("[AbyssShadows] " .. name .. " failed: " .. tostring(value))
            end
        end,
    })
end

local function bootLog(message)
    if type(print) == "function" then
        print("[BOOT] " .. tostring(message))
    end
end

local GuiBuilder = {}

function GuiBuilder:Build()
    local rayfieldSource = Utils.SafeHttpGetAny(Constants.RayfieldUrls or {Constants.RayfieldUrl})
    if not rayfieldSource or rayfieldSource == "" then
        error("[AbyssShadows] Failed to download Rayfield source")
    end

    local Rayfield, loadError = Utils.SafeLoadString(rayfieldSource, Constants.RayfieldUrl)
    if not Rayfield then
        error("[AbyssShadows] Failed to load Rayfield source: " .. tostring(loadError))
    end
    if type(Rayfield) == "function" then
        Rayfield = Rayfield()
    end
    if type(Rayfield) ~= "table" then
        error("[AbyssShadows] Rayfield loader returned invalid library type")
    end

    bootLog("Rayfield loaded")

    local Window, windowErr = safeCreateWindow(Rayfield, {
        Name = "Abyss_Shadow",
        Icon = 0,
        LoadingTitle = "Abyss_Shadow",
        LoadingSubtitle = "Sora Piece",
        ShowText = "Abyss_Shadow",
        Theme = "Dark",
        ToggleUIKeybind = "K",
        DisableRayfieldPrompts = true,
        DisableBuildWarnings = true,
        ConfigurationSaving = {
            Enabled = true,
            FolderName = "AbyssShadows",
            FileName = "Abyss_Shadow",
        },
        KeySystem = false,
    })
    if not Window then
        error(windowErr)
    end
    bootLog("[BOOT] Rayfield OK")
    bootLog("[BOOT] Window OK")

    local homeTab, homeErr = safeCreateTab(Window, "Home")
    if not homeTab then
        error(homeErr)
    end
    bootLog("Home tab created")
    bootLog("[BOOT] Tabs OK")

    local overviewSection, sectionErr = safeCreateSection(homeTab, "Overview")
    if not overviewSection then
        error(sectionErr)
    end

    local ok, elementErr = safeCreateElement(overviewSection, "CreateLabel", {
        Name = "Abyss_Shadow is ready",
    })
    if not ok then
        error(elementErr)
    end

    local dataManager, dataManagerErr = safeLoadDataManager()
    if dataManagerErr then
        warn("[DATA] DataManager FAILED: " .. tostring(dataManagerErr))
    else
        bootLog("[DATA] DataManager loaded")
        bootLog("[DATA] State initialized")
        local success, validateErr = pcall(function()
            dataManager:EnsureState()
        end)
        if success then
            bootLog("[DATA] State validation passed")
        else
            warn("[DATA] State validation failed: " .. tostring(validateErr))
        end
    end

    safeCreateStateLabel(overviewSection, "Location", "CurrentLocation", dataManager)
    safeCreateStateLabel(overviewSection, "Status", "Status", dataManager)
    safeCreateStateLabel(overviewSection, "Target", "CurrentTargetName", dataManager)
    safeCreateStateLabel(overviewSection, "Target Health", "CurrentTargetHealth", dataManager)
    safeCreateStateLabel(overviewSection, "Chest Target", "ChestTarget", dataManager)
    safeCreateStateLabel(overviewSection, "Session Gems", "SessionGems", dataManager)
    safeCreateStateLabel(overviewSection, "Gems / Min", "GemsPerMinute", dataManager)

    ok, elementErr = safeCreateElement(overviewSection, "CreateButton", {
        Name = "Show Ready Notification",
        Callback = function()
            local notifyOk, notifyErr = safeNotify(Rayfield, {
                Title = "Abyss_Shadow",
                Content = "GUI READY",
                Duration = 4,
            })
            if not notifyOk then
                warn("[AbyssShadows] Notification failed: " .. tostring(notifyErr))
            end
        end,
    })
    if not ok then
        error(elementErr)
    end

    local ok, configStatusOrErr = safeCreateElement(overviewSection, "CreateLabel", {
        Name = "Config Status: Pending",
    })
    if not ok then
        error(configStatusOrErr)
    end

    local configStatusLabel = configStatusOrErr
    local function updateConfigStatus(text)
        pcall(function()
            if configStatusLabel and type(configStatusLabel.Set) == "function" then
                configStatusLabel:Set("Config Status: " .. tostring(text))
            end
        end)
    end

    ok, elementErr = safeCreateElement(overviewSection, "CreateButton", {
        Name = "Reload Configuration",
        Callback = function()
            local success, result = safeReloadConfiguration(Rayfield)
            updateConfigStatus(success and "Reloaded" or "Reload failed")
            safeNotify(Rayfield, {
                Title = "Abyss_Shadow",
                Content = success and "Configuration reloaded." or "Reload failed: " .. tostring(result),
                Duration = 4,
            })
        end,
    })
    if not ok then
        error(elementErr)
    end

    ok, elementErr = safeCreateElement(overviewSection, "CreateButton", {
        Name = "Reset Configuration",
        Callback = function()
            local success, result = safeResetConfiguration(Rayfield)
            updateConfigStatus(success and "Reset and reloaded" or "Reset failed")
            safeNotify(Rayfield, {
                Title = "Abyss_Shadow",
                Content = success and "Configuration reset." or "Reset failed: " .. tostring(result),
                Duration = 4,
            })
        end,
    })
    if not ok then
        error(elementErr)
    end

    updateConfigStatus("Ready")

    ok, elementErr = safeNotify(Rayfield, {
        Title = "Abyss_Shadow",
        Content = "Interface loaded.",
        Duration = 4,
    })
    if not ok then
        error(elementErr)
    end

    bootLog("CONFIG READY")
    bootLog("GUI READY")

    local debugTab, debugErr = safeCreateTab(Window, "Debug")
    if not debugTab then
        warn("[AbyssShadows] Debug tab creation failed: " .. tostring(debugErr))
    else
        local debugSection, debugSectionErr = safeCreateSection(debugTab, "Scanner")
        if not debugSection then
            warn("[AbyssShadows] Debug section creation failed: " .. tostring(debugSectionErr))
        else
            local scanner, scannerErr = safeLoadScanner()
            if scannerErr then
                warn("[AbyssShadows] Scanner load failed: " .. tostring(scannerErr))
                safeCreateElement(debugSection, "CreateLabel", {
                    Name = "Scanner load failed: " .. tostring(scannerErr),
                })
            else
                safeCreateElement(debugSection, "CreateLabel", {
                    Name = "Scanner READY",
                })
                safeCreateScannerButton(debugSection, Rayfield, scanner, "Scan NPCs", "ScanNpcs", "NPCCache")
                safeCreateScannerButton(debugSection, Rayfield, scanner, "Scan Chests", "ScanChests", "ChestCache")
                safeCreateScannerButton(debugSection, Rayfield, scanner, "Scan Gems", "ScanGems", "GemCache")
            end
        end
    end

    bootLog("ABYSS_SHADOW READY")
    return true
end

return GuiBuilder
