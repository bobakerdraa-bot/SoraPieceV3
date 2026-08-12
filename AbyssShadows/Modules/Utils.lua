-- Utils.lua
-- Utility functions for Abyss Shadows.

local HttpService = game:GetService("HttpService")
local ExecutorCompat = require(script.Parent:FindFirstChild("ExecutorCompat") or error("[AbyssShadows] Missing ExecutorCompat"))

local Utils = {}

function Utils.SafeRequest(options)
    local result, err = ExecutorCompat.SafeRequest(options)
    if result and result ~= "" then
        return result
    end
    return nil
end

function Utils.SafeHttpGet(url)
    if type(url) ~= "string" then
        return nil
    end
    return Utils.SafeRequest({ Url = url, Method = "GET" })
end

function Utils.SafeHttpGetAny(urls)
    if type(urls) ~= "table" then
        return nil
    end
    for _, url in ipairs(urls) do
        local result = Utils.SafeHttpGet(url)
        if result and result ~= "" then
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
