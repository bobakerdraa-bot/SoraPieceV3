-- Main.lua
-- Entry point for Abyss Shadows.

local function findModulesRoot()
    local function hasModulesFolder(instance)
        return instance and type(instance.FindFirstChild) == "function" and instance:FindFirstChild("Modules")
    end

    if script and type(script) ~= "nil" then
        local root = script.Parent
        while root do
            if hasModulesFolder(root) then
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

local root = findModulesRoot()
if not root then
    error("[AbyssShadows] Unable to locate the Modules folder. Make sure Main.lua is a LocalScript inside AbyssShadows or the AbyssShadows folder exists in the game.")
end

local Modules = root:FindFirstChild("Modules")
local GuiBuilder = require(Modules.GuiBuilder)
local Scanner = require(Modules.Scanner)

Scanner:StartAutoRefresh()
GuiBuilder:Build()
