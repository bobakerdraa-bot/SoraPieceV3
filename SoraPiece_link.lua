-- Universal loader for most Roblox executors
-- Copy this into your executor or use the raw URL if you host it.

local sources = {
    "https://cdn.jsdelivr.net/gh/bobakerdraa-bot/SoraPieceV3@main/SoraPiece.lua",
    "https://raw.githubusercontent.com/bobakerdraa-bot/SoraPieceV3/main/SoraPiece.lua",
    "https://raw.githack.com/bobakerdraa-bot/SoraPieceV3/main/SoraPiece.lua",
}

local function httpGet(remote)
    if type(game.HttpGet) == "function" then
        return game:HttpGet(remote, true)
    end
    if type(game.HttpGetAsync) == "function" then
        return game:HttpGetAsync(remote, true)
    end
    if type(syn) == "table" and type(syn.request) == "function" then
        return syn.request({Url = remote, Method = "GET"}).Body
    end
    if type(request) == "function" then
        return request({Url = remote, Method = "GET"}).Body
    end
    if type(http_request) == "function" then
        return http_request({Url = remote, Method = "GET"}).Body
    end
    if type(httprequest) == "function" then
        return httprequest({Url = remote, Method = "GET"}).Body
    end
    local HttpService = game:GetService("HttpService")
    if HttpService and type(HttpService.GetAsync) == "function" then
        return HttpService:GetAsync(remote)
    end
    error("No supported HTTP request function found")
end

local source, lastError
for _, url in ipairs(sources) do
    local ok, result = pcall(httpGet, url)
    if ok and result and result ~= "" then
        source = result
        break
    end
    lastError = result
end

if not source or source == "" then
    error("Failed to download script source from all sources: " .. tostring(lastError))
end

local loadFn = loadstring or load
local fn, compileErr = loadFn(source)
if not fn then
    error("Failed to compile downloaded script: " .. tostring(compileErr))
end
fn()
