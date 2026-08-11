-- SoraPiece_link.lua
-- Stable loader for AbyssShadows pinned to a fixed GitHub commit.

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

local function createFolder(parent, name)
    local folder = parent:FindFirstChild(name)
    if folder and folder:IsA("Folder") then
        return folder
    end
    folder = Instance.new("Folder")
    folder.Name = name
    folder.Parent = parent
    return folder
end

local commitHash = "1fe3196bf0fb614953dffdfb644b4d3c596147d2"
local baseUrl = "https://raw.githubusercontent.com/bobakerdraa-bot/SoraPieceV3/" .. commitHash .. "/"
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

local abyssFolder = createFolder(ReplicatedStorage, "AbyssShadows")
local modulesFolder = createFolder(abyssFolder, "Modules")

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

local proxyScript = { Parent = abyssFolder }
local env = setmetatable({ script = proxyScript, game = game, workspace = workspace, ReplicatedStorage = ReplicatedStorage, HttpService = HttpService }, { __index = _G })

local loader = loadstring or load
if type(loader) ~= "function" then
    error("[AbyssShadows Loader] No loadstring or load available.")
end

local chunk, err = loader(mainSource, mainUrl)
if not chunk then
    error("[AbyssShadows Loader] Failed to compile Main.lua: " .. tostring(err))
end

if type(setfenv) == "function" then
    setfenv(chunk, env)
elseif type(debug) == "table" and type(debug.setupvalue) == "function" then
    local i = 1
    while true do
        local name = debug.getupvalue(chunk, i)
        if not name then break end
        if name == "_ENV" then
            debug.setupvalue(chunk, i, env)
            break
        end
        i = i + 1
    end
end

local ok, runErr = pcall(chunk)
if not ok then
    error("[AbyssShadows Loader] Failed to execute Main.lua: " .. tostring(runErr))
end
