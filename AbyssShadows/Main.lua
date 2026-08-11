-- Main.lua
-- Entry point for Abyss Shadows.

local Modules = script:FindFirstChild("Modules") or script
local Constants = require(Modules.Constants)
local Utils = require(Modules.Utils)
local GuiBuilder = require(Modules.GuiBuilder)
local Scanner = require(Modules.Scanner)

local function loadRemoteScript()
    local source = Utils.SafeHttpGetAny(Constants.ScriptUrls)
    if not source or source == "" then
        return false
    end

    local loadFn = loadstring or load
    local fn, compileErr = loadFn(source)
    if not fn then
        warn("[AbyssShadows] Script compile failed: " .. tostring(compileErr))
        return false
    end

    local ok, err = pcall(fn)
    if not ok then
        warn("[AbyssShadows] Script runtime error: " .. tostring(err))
        return false
    end

    return true
end

local loaded = loadRemoteScript()
if not loaded then
    warn("[AbyssShadows] Failed to load SoraPiece remote script. Verify Constants.ScriptUrls and HTTP access.")
end

Scanner:StartAutoRefresh()
GuiBuilder:Build()
