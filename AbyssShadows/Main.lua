-- Main.lua
-- Entry point for Abyss Shadows.

local function getAbyssRoot()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local root = ReplicatedStorage:FindFirstChild("AbyssShadows")
    if root and root:FindFirstChild("Modules") then
        return root
    end

    if script then
        local current = script.Parent
        while current do
            if current:FindFirstChild("Modules") then
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
