-- Loader: fetches the main SoraPiece script from the repo and runs it
local url = "https://raw.githubusercontent.com/bobakerdraa-bot/SoraPieceV3/main/SoraPiece.lua"

local function httpGet(link)
    if type(game.HttpGet) == "function" then
        return game:HttpGet(link, true)
    end
    if type(game.HttpGetAsync) == "function" then
        return game:HttpGetAsync(link, true)
    end
    if type(syn) == "table" and type(syn.request) == "function" then
        return syn.request({Url = link, Method = "GET"}).Body
    end
    if type(request) == "function" then
        return request({Url = link, Method = "GET"}).Body
    end
    if type(http_request) == "function" then
        return http_request({Url = link, Method = "GET"}).Body
    end
    if type(httprequest) == "function" then
        return httprequest({Url = link, Method = "GET"}).Body
    end
    error("[SoraPiece_loader] No supported HTTP request function found.")
end

local function loadCode(code)
    if type(loadstring) == "function" then
        return loadstring(code)
    end
    if type(load) == "function" then
        return load(code)
    end
    error("[SoraPiece_loader] No supported loadstring function found.")
end

local status, ok, result = pcall(function()
    local source = httpGet(url)
    if not source or source == "" then
        error("[SoraPiece_loader] failed to fetch remote script")
    end
    local fn = loadCode(source)
    if not fn then
        error("[SoraPiece_loader] failed to compile remote script")
    end
    return pcall(fn)
end)

if not status then
    warn("[SoraPiece_loader] failed to load remote script:", ok)
elseif not ok then
    warn("[SoraPiece_loader] remote script execution failed:", result)
end
