-- Utils.lua
-- Utility functions for Abyss Shadows.

local HttpService = game:GetService("HttpService")

local Utils = {}

function Utils.SafeHttpGet(url)
    local function try(fn, ...)
        if type(fn) ~= "function" then
            return nil
        end
        local ok, result = pcall(fn, ...)
        if not ok then
            return nil
        end
        return result
    end

    local requesters = {
        function()
            return try(game.HttpGet, game, url, true)
        end,
        function()
            return try(game.HttpGetAsync, game, url, true)
        end,
        function()
            if type(syn) == "table" and type(syn.request) == "function" then
                return try(function()
                    return syn.request({Url = url, Method = "GET"}).Body
                end)
            end
        end,
        function()
            if type(request) == "function" then
                return try(function()
                    return request({Url = url, Method = "GET"}).Body
                end)
            end
        end,
        function()
            if type(http_request) == "function" then
                return try(function()
                    return http_request({Url = url, Method = "GET"}).Body
                end)
            end
        end,
        function()
            if type(httprequest) == "function" then
                return try(function()
                    return httprequest({Url = url, Method = "GET"}).Body
                end)
            end
        end,
        function()
            if HttpService and type(HttpService.GetAsync) == "function" then
                return try(function()
                    return HttpService:GetAsync(url)
                end)
            end
        end,
    }

    for _, requester in ipairs(requesters) do
        local result = requester()
        if result and result ~= "" then
            return result
        end
    end

    return nil
end

function Utils.SafeHttpGetAny(urls)
    if type(urls) ~= "table" then
        return nil
    end
    for _, url in ipairs(urls) do
        local ok, result = pcall(Utils.SafeHttpGet, url)
        if ok and result and result ~= "" then
            return result
        end
    end
    return nil
end

function Utils.SafeLoadString(code, source)
    local loader = loadstring or load
    if type(loader) ~= "function" then
        return nil, "no loadstring/load available"
    end
    local chunk, err = loader(code, source or "chunk")
    if not chunk then
        return nil, err
    end
    local ok, result = pcall(chunk)
    if not ok then
        return nil, result
    end
    return result
end

return Utils
