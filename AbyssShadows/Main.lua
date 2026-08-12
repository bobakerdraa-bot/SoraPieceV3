-- Main.lua
-- Entry point for Abyss Shadows.
local function bootLog(message)
    local logger = type(warn) == "function" and warn or print
    if type(logger) == "function" then
        logger("[BOOT] " .. tostring(message))
    end
end

-- Minimal, centralized loader that fetches modules from the GitHub repo
local BaseRaw = "https://raw.githubusercontent.com/bobakerdraa-bot/SoraPieceV3/main/AbyssShadows/"

local function tryRequest(url)
    local function tryfn(fn)
        if type(fn) ~= "function" then return nil end
        local ok, res = pcall(fn)
        if ok and res and res ~= "" then return res end
        return nil
    end

    -- syn.request / request / http_request / httprequest
    if type(syn) == "table" and type(syn.request) == "function" then
        local r = tryfn(function() return syn.request({Url = url, Method = "GET"}).Body end)
        if r then return r end
    end
    if type(request) == "function" then
        local r = tryfn(function() return request({Url = url, Method = "GET"}).Body end)
        if r then return r end
    end
    if type(http_request) == "function" then
        local r = tryfn(function() return http_request({Url = url, Method = "GET"}).Body end)
        if r then return r end
    end
    if type(httprequest) == "function" then
        local r = tryfn(function() return httprequest({Url = url, Method = "GET"}).Body end)
        if r then return r end
    end
    -- game HttpGet variants
    if type(game.HttpGet) == "function" then
        local r = tryfn(function() return game:HttpGet(url, true) end)
        if r then return r end
    end
    if type(game.HttpGetAsync) == "function" then
        local r = tryfn(function() return game:HttpGetAsync(url, true) end)
        if r then return r end
    end
    -- HttpService
    local ok, HttpService = pcall(function() return game:GetService("HttpService") end)
    if ok and HttpService and type(HttpService.GetAsync) == "function" then
        local r = tryfn(function() return HttpService:GetAsync(url) end)
        if r then return r end
    end
    return nil, "no http method available"
end

local loader = loadstring or load
if type(loader) ~= "function" then
    error("[BOOT] No loadstring/load available; cannot proceed")
end

local function compileModule(source, name)
    local chunk, err = loader(source, name)
    if not chunk then return nil, err end
    -- set secure env so modules that reference `script` work
    local proxyScript = { Parent = { Name = "AbyssShadows" } }
    local repok = pcall(function() return game:GetService("ReplicatedStorage") end)
    local ReplicatedStorage = repok and game:GetService("ReplicatedStorage") or nil
    local okEnv = setmetatable({ script = proxyScript, game = game, workspace = workspace, ReplicatedStorage = ReplicatedStorage, HttpService = (pcall(function() return game:GetService("HttpService") end) and game:GetService("HttpService") or nil) }, { __index = _G })
    if type(setfenv) == "function" then
        setfenv(chunk, okEnv)
    else
        if type(debug) == "table" and type(debug.setupvalue) == "function" then
            local i = 1
            while true do
                local name = debug.getupvalue(chunk, i)
                if not name then break end
                if name == "_ENV" then
                    debug.setupvalue(chunk, i, okEnv)
                    break
                end
                i = i + 1
            end
        end
    end
    local ok, result = pcall(chunk)
    if not ok then return nil, result end
    return result
end

local ModulesNeeded = {
    { Name = "ExecutorCompat", Path = "Modules/ExecutorCompat.lua", Required = true },
    { Name = "Constants", Path = "Modules/Constants.lua", Required = true },
    { Name = "Utils", Path = "Modules/Utils.lua", Required = true },
    { Name = "DataManager", Path = "Modules/DataManager.lua", Required = true },
    { Name = "Scanner", Path = "Modules/Scanner.lua", Required = false },
    { Name = "GuiBuilder", Path = "Modules/GuiBuilder.lua", Required = true },
    { Name = "Farming", Path = "Modules/Farming.lua", Required = false },
    { Name = "ChestManager", Path = "Modules/ChestManager.lua", Required = false },
    { Name = "GemManager", Path = "Modules/GemManager.lua", Required = false },
}

local loaded = {}

bootLog("Starting Abyss_Shadow (remote loader)")

for _, mod in ipairs(ModulesNeeded) do
    bootLog("Fetching module: " .. mod.Name)
    local url = BaseRaw .. mod.Path
    local source, serr = tryRequest(url)
    if not source then
        if mod.Required then
            print("[Abyss_Shadow]\nModule: " .. mod.Name .. "\nStatus: FAILED\nReason: HTTP fetch failed: " .. tostring(serr))
            error("[BOOT] Required module fetch failed: " .. mod.Name)
        else
            print("[Abyss_Shadow]\nModule: " .. mod.Name .. "\nStatus: SKIPPED\nReason: HTTP fetch failed: " .. tostring(serr))
        end
    else
        -- Special, verbose diagnostics for ExecutorCompat to reveal exact errors
        if mod.Name == "ExecutorCompat" then
            print("[COMPAT] SOURCE LENGTH: " .. tostring(#source))
            local loaderfn = loadstring or load
            if type(loaderfn) ~= "function" then
                print("[COMPAT] COMPILE: FAIL")
                print("COMPILE ERROR:\nno loadstring/load available in this executor")
                if mod.Required then
                    error("[BOOT] Required module compile failed: " .. mod.Name .. " -> no loadstring/load")
                end
            else
                local chunk, compileErr = loaderfn(source, url)
                if not chunk then
                    print("[COMPAT] COMPILE: FAIL")
                    print("COMPILE ERROR:\n" .. tostring(compileErr))
                    if mod.Required then
                        print("[Abyss_Shadow]\nModule: " .. mod.Name .. "\nStatus: FAILED\nReason:\n" .. tostring(compileErr))
                        error("[BOOT] Required module compile failed: " .. mod.Name .. " -> " .. tostring(compileErr))
                    end
                else
                    print("[COMPAT] COMPILE: PASS")
                    local ok, runtimeResult = xpcall(function() return chunk() end, debug and debug.traceback or function(e) return tostring(e) end)
                    if not ok then
                        print("[COMPAT] RUNTIME: FAIL")
                        print("RUNTIME ERROR:\n" .. tostring(runtimeResult))
                        if mod.Required then
                            print("[Abyss_Shadow]\nModule: " .. mod.Name .. "\nStatus: FAILED\nReason:\n" .. tostring(runtimeResult))
                            error("[BOOT] Required module runtime failed: " .. mod.Name .. " -> " .. tostring(runtimeResult))
                        end
                    else
                        print("[COMPAT] RUNTIME: PASS")
                        loaded[mod.Name] = runtimeResult
                        print("[COMPAT] MODULE RETURN TYPE: " .. type(runtimeResult))
                        print("[Abyss_Shadow]\nModule: " .. mod.Name .. "\nStatus: LOADED")
                    end
                end
            end
        else
            local ok, mres = pcall(function() return compileModule(source, url) end)
            if not ok or mres == nil then
                local reason = tostring(mres or "compile/runtime error")
                if mod.Required then
                    print("[Abyss_Shadow]\nModule: " .. mod.Name .. "\nStatus: FAILED\nReason: " .. reason)
                    error("[BOOT] Required module compile failed: " .. mod.Name .. " -> " .. reason)
                else
                    print("[Abyss_Shadow]\nModule: " .. mod.Name .. "\nStatus: FAILED\nReason: " .. reason)
                end
            else
                loaded[mod.Name] = mres
                print("[Abyss_Shadow]\nModule: " .. mod.Name .. "\nStatus: LOADED")
            end
        end
    end
end

-- Validate core modules types
local function expectTable(name)
    if type(loaded[name]) ~= "table" then
        error(string.format("[BOOT] Module %s did not return a table (got %s)", name, type(loaded[name])))
    end
end

expectTable("ExecutorCompat")
expectTable("Constants")
expectTable("Utils")
expectTable("DataManager")
expectTable("GuiBuilder")

local ExecutorCompat = loaded.ExecutorCompat
local Constants = loaded.Constants
local Utils = loaded.Utils
local DataManager = loaded.DataManager
local Scanner = loaded.Scanner
local GuiBuilder = loaded.GuiBuilder

bootLog("Environment checks (via ExecutorCompat)")
local envSummary = {
    Executor = (type(ExecutorCompat.GetEnvironment) == "function" and ExecutorCompat.GetEnvironment().Name) or "UNKNOWN",
}
bootLog("[ENV] Executor: " .. tostring(envSummary.Executor))

-- Load Rayfield via GuiBuilder
bootLog("Loading Rayfield and building GUI")
local ok, berr = pcall(function()
    if type(GuiBuilder.Build) ~= "function" then error("GuiBuilder missing Build()") end
    GuiBuilder:Build()
end)
if not ok then
    error("[BOOT] GUI creation failed: " .. tostring(berr))
end

bootLog("Initialization complete")
print("[Abyss_Shadow]\nInitialization complete.")
