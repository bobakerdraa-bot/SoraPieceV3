-- Utils.lua
-- Utility functions for Abyss Shadows.

local HttpService = game:GetService("HttpService")

local Utils = {}

function Utils.SafeHttpGet(url)
    if type(game.HttpGet) == "function" then
        return game:HttpGet(url, true)
    end
    if type(game.HttpGetAsync) == "function" then
        return game:HttpGetAsync(url, true)
    end
    if type(syn) == "table" and type(syn.request) == "function" then
        return syn.request({Url = url, Method = "GET"}).Body
    end
    if type(request) == "function" then
        return request({Url = url, Method = "GET"}).Body
    end
    if type(http_request) == "function" then
        return http_request({Url = url, Method = "GET"}).Body
    end
    if type(httprequest) == "function" then
        return httprequest({Url = url, Method = "GET"}).Body
    end
    if HttpService and type(HttpService.GetAsync) == "function" then
        return HttpService:GetAsync(url)
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

function Utils.SanitizeText(value)
    return tostring(value or "-")
end

function Utils.CreateStatusIcon(parent, isActive)
    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 10, 0, 10)
    dot.BackgroundTransparency = 0
    dot.BorderSizePixel = 0
    dot.AnchorPoint = Vector2.new(0, 0.5)
    dot.Position = UDim2.new(0, 0, 0.5, 0)
    dot.BackgroundColor3 = isActive and Color3.fromRGB(102, 255, 178) or Color3.fromRGB(197, 59, 59)
    dot.Rotation = 0
    dot.ClipsDescendants = false
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = dot
    dot.Parent = parent
    return dot
end

return Utils
