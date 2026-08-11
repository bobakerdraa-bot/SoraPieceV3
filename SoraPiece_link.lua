-- Universal loader for most Roblox executors
-- Copy this into your executor or use the raw URL if you host it.

local url = "https://raw.githubusercontent.com/bobakerdraa-bot/SoraPieceV3/main/SoraPiece.lua"

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

local source = httpGet(url)
if not source or source == "" then
    error("Failed to download script source")
end
local loadFn = loadstring or load
local fn = loadFn(source)
if not fn then
    error("Failed to compile downloaded script")
end
fn()
