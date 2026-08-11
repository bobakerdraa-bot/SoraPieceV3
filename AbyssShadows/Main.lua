-- Main.lua
-- Entry point for Abyss Shadows.

warn("[BOOT] Starting")

local function findModulesRoot()
    if script and type(script.FindFirstChild) == "function" then
        local root = script.Parent
        while root do
            if root:FindFirstChild("Modules") then
                return root
            end
            root = root.Parent
        end
    end

    local searchContainers = {
        game:GetService("Workspace"),
        game:GetService("ReplicatedStorage"),
        game:GetService("StarterPlayer"),
        game:GetService("StarterGui"),
        game:GetService("ServerStorage"),
    }
    for _, container in ipairs(searchContainers) do
        for _, child in ipairs(container:GetDescendants()) do
            if child:IsA("Folder") and child.Name == "AbyssShadows" and child:FindFirstChild("Modules") then
                return child
            end
        end
    end
    return nil
end

warn("[BOOT] Dependencies loaded")
local root = findModulesRoot()
if not root then
    error("[BOOT] Missing dependency: AbyssShadows root folder not found")
end

local Modules = root:FindFirstChild("Modules")
if not Modules then
    error("[BOOT] Missing dependency: Modules folder not found under AbyssShadows")
end

local function safeRequire(childName)
    local instance = Modules:FindFirstChild(childName)
    if not instance then
        warn("[BOOT] Missing dependency: " .. childName)
        return nil
    end
    local ok, result = pcall(require, instance)
    if not ok then
        warn("[BOOT] Failed requiring " .. childName .. ": " .. tostring(result))
        return nil
    end
    return result
end

local GuiBuilder = safeRequire("GuiBuilder")
if not GuiBuilder then
    error("[BOOT] Cannot continue without GuiBuilder")
end

local Scanner = safeRequire("Scanner")
local ScannerSafe = Scanner

warn("[BOOT] Rayfield loaded")
warn("[BOOT] Creating GUI")

local ok, buildErr = pcall(function()
    GuiBuilder:Build()
end)

if not ok then
    error("[BOOT] Failed to create GUI: " .. tostring(buildErr))
end

warn("[BOOT] GUI created")
warn("[BOOT] Initializing systems")

if ScannerSafe then
    pcall(function()
        if type(ScannerSafe.StartAutoRefresh) == "function" then
            ScannerSafe:StartAutoRefresh()
        end
    end)
end
