-- SoraPiece_link.lua
-- Direct loader for AbyssShadows from GitHub.

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function safeRequest(url)
    local function try(fn)
        if type(fn) ~= "function" then
            return nil
        end
        local ok, result = pcall(fn)
        if ok and result and result ~= "" then
            return result
        end
        return nil
    end

    local requesters = {
        function() return try(function() return game:HttpGet(url, true) end) end,
        function() return try(function() return game:HttpGetAsync(url, true) end) end,
        function() if type(syn) == "table" and type(syn.request) == "function" then return try(function() return syn.request({Url = url, Method = "GET"}).Body end) end end,
        function() if type(request) == "function" then return try(function() return request({Url = url, Method = "GET"}).Body end) end end,
        function() if type(http_request) == "function" then return try(function() return http_request({Url = url, Method = "GET"}).Body end) end end,
        function() if type(httprequest) == "function" then return try(function() return httprequest({Url = url, Method = "GET"}).Body end) end end,
        function() return try(function() return HttpService:GetAsync(url) end) end,
    }

    for _, requester in ipairs(requesters) do
        local result = requester()
        if result and result ~= "" then
            return result
        end
    end

    return nil
end

local baseUrl = "https://raw.githubusercontent.com/bobakerdraa-bot/SoraPieceV3/main/"
local files = {
    "AbyssShadows/Modules/Constants.lua",
    "AbyssShadows/Modules/Utils.lua",
    "AbyssShadows/Modules/DataManager.lua",
    "AbyssShadows/Modules/Scanner.lua",
    "AbyssShadows/Modules/Farming.lua",
    "AbyssShadows/Modules/ChestManager.lua",
    "AbyssShadows/Modules/GemManager.lua",
    "AbyssShadows/Modules/GuiBuilder.lua",
}

local abyssFolder = ReplicatedStorage:FindFirstChild("AbyssShadows")
if not abyssFolder then
    abyssFolder = Instance.new("Folder")
    abyssFolder.Name = "AbyssShadows"
    abyssFolder.Parent = ReplicatedStorage
end

local modulesFolder = abyssFolder:FindFirstChild("Modules")
if not modulesFolder then
    modulesFolder = Instance.new("Folder")
    modulesFolder.Name = "Modules"
    modulesFolder.Parent = abyssFolder
end

for _, path in ipairs(files) do
    local fileName = path:match("([^/]+)%.lua$")
    if fileName then
        local sourceUrl = baseUrl .. path
        local source = safeRequest(sourceUrl)
        if not source then
            error("[AbyssShadows Loader] Failed to fetch " .. sourceUrl)
        end

        local moduleScript = modulesFolder:FindFirstChild(fileName)
        if not moduleScript then
            moduleScript = Instance.new("ModuleScript")
            moduleScript.Name = fileName
            moduleScript.Parent = modulesFolder
        end
        moduleScript.Source = source
    end
end

local mainUrl = baseUrl .. "AbyssShadows/Main.lua"
local mainSource = safeRequest(mainUrl)
if not mainSource then
    error("[AbyssShadows Loader] Failed to fetch " .. mainUrl)
end

local mainScript = Instance.new("LocalScript")
mainScript.Name = "AbyssShadowsMain"
mainScript.Parent = abyssFolder

local env = setmetatable({ script = mainScript, game = game, workspace = workspace, ReplicatedStorage = ReplicatedStorage, HttpService = HttpService }, { __index = _G })

local chunk, err = loadstring(mainSource, mainUrl)
if not chunk then
    error("[AbyssShadows Loader] Failed to compile Main.lua: " .. tostring(err))
end

setfenv(chunk, env)
local ok, runErr = pcall(chunk)
if not ok then
    error("[AbyssShadows Loader] Failed to execute Main.lua: " .. tostring(runErr))
end
