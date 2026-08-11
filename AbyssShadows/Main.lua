-- Main.lua
-- Entry point for Abyss Shadows.

local function safeGetService(name)
    if type(game) == "table" or type(game) == "userdata" then
        if type(game.GetService) == "function" then
            local ok, service = pcall(game.GetService, game, name)
            if ok and service then
                return service
            end
        end
    end
    if type(workspace) == "table" or type(workspace) == "userdata" then
        if name == "Workspace" then
            return workspace
        elseif name == "ReplicatedStorage" then
            if type(workspace.FindFirstChild) == "function" then
                return workspace:FindFirstChild("ReplicatedStorage")
            end
        end
    end
    return nil
end

local function getAbyssRoot()
    local ReplicatedStorage = safeGetService("ReplicatedStorage")
    if ReplicatedStorage and type(ReplicatedStorage.FindFirstChild) == "function" then
        local root = ReplicatedStorage:FindFirstChild("AbyssShadows")
        if root and type(root.FindFirstChild) == "function" and root:FindFirstChild("Modules") then
            return root
        end
    end

    if type(workspace) == "table" or type(workspace) == "userdata" then
        if type(workspace.FindFirstChild) == "function" then
            local root = workspace:FindFirstChild("AbyssShadows")
            if root and type(root.FindFirstChild) == "function" and root:FindFirstChild("Modules") then
                return root
            end
        end
    end

    if script then
        local current = script.Parent
        while current do
            if type(current.FindFirstChild) == "function" and current:FindFirstChild("Modules") then
                return current
            end
            current = current.Parent
        end
    end

    return nil
end

local root = getAbyssRoot()
if not root then
    error("[AbyssShadows] Unable to locate the AbyssShadows root. Ensure the module folder is available in ReplicatedStorage or alongside Main.lua.")
end

local Modules = root:FindFirstChild("Modules")
if not Modules then
    error("[AbyssShadows] Modules folder not found under AbyssShadows.")
end

local GuiBuilder = require(Modules:FindFirstChild("GuiBuilder") or error("GuiBuilder module missing"))
local Scanner = require(Modules:FindFirstChild("Scanner") or error("Scanner module missing"))

Scanner:StartAutoRefresh()
GuiBuilder:Build()
