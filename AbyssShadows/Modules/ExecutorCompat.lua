-- ExecutorCompat.lua
-- Detects Xeno / Project Real and exposes safe capability wrappers.

local HttpService = game:GetService("HttpService")

local ExecutorCompat = {}

local function safeCall(fn, ...)
    if type(fn) ~= "function" then
        return false, "no function"
    end
    local ok, result = pcall(fn, ...)
    if not ok then
        return false, result
    end
    return true, result
end

local function detectEnvironment()
    local env = {
        Name = "Unknown",
        Exact = false,
        Xeno = false,
        ProjectReal = false,
    }

    if type(Xeno) == "table" or type(xeno) == "table" or type(XENO) == "table" then
        env.Name = "Xeno"
        env.Exact = true
        env.Xeno = true
    elseif type(ProjectReal) == "table" or type(projectreal) == "table" or type(PROJECTREAL) == "table" then
        env.Name = "Project Real"
        env.Exact = true
        env.ProjectReal = true
    end

    return env
end

local ok_detect, detected = pcall(detectEnvironment)
local Environment = (ok_detect and type(detected) == "table") and detected or {
    Name = "Unknown",
    Exact = false,
    Xeno = false,
    ProjectReal = false,
}

function ExecutorCompat.GetEnvironment()
    return Environment
end

function ExecutorCompat.IsXeno()
    return Environment.Xeno
end

function ExecutorCompat.IsProjectReal()
    return Environment.ProjectReal
end

function ExecutorCompat.IsExactEnvironment()
    return Environment.Exact
end

function ExecutorCompat.HasLoadString()
    return type(loadstring) == "function" or type(load) == "function"
end

function ExecutorCompat.GetLoadStringStatus()
    if ExecutorCompat.HasLoadString() then
        return "AVAILABLE"
    end
    return "UNAVAILABLE"
end

function ExecutorCompat.HasHttp()
    return type(game.HttpGet) == "function"
        or type(game.HttpGetAsync) == "function"
        or (type(syn) == "table" and type(syn.request) == "function")
        or type(request) == "function"
        or type(http_request) == "function"
        or type(httprequest) == "function"
        or (HttpService and type(HttpService.GetAsync) == "function")
end

function ExecutorCompat.GetHttpStatus()
    if type(game.HttpGet) == "function" or type(game.HttpGetAsync) == "function" then
        return "AVAILABLE"
    end
    if (type(syn) == "table" and type(syn.request) == "function")
        or type(request) == "function"
        or type(http_request) == "function"
        or type(httprequest) == "function" then
        return "AVAILABLE"
    end
    if HttpService and type(HttpService.GetAsync) == "function" then
        return "LIMITED"
    end
    return "UNAVAILABLE"
end

function ExecutorCompat.HasFileIO()
    return type(writefile) == "function"
        or type(readfile) == "function"
        or type(delfile) == "function"
        or type(isfile) == "function"
        or type(isfolder) == "function"
        or type(makefolder) == "function"
end

function ExecutorCompat.GetFileIOStatus()
    local availableCount = 0
    if type(writefile) == "function" then availableCount = availableCount + 1 end
    if type(readfile) == "function" then availableCount = availableCount + 1 end
    if type(delfile) == "function" then availableCount = availableCount + 1 end
    if type(isfile) == "function" then availableCount = availableCount + 1 end
    if type(isfolder) == "function" then availableCount = availableCount + 1 end
    if type(makefolder) == "function" then availableCount = availableCount + 1 end
    if availableCount >= 3 then
        return "AVAILABLE"
    elseif availableCount > 0 then
        return "LIMITED"
    end
    return "UNAVAILABLE"
end

function ExecutorCompat.HasCustomAsset()
    return type(getcustomasset) == "function"
end

function ExecutorCompat.GetOtherCapabilitiesSummary()
    local parts = {
        "FileIO=" .. ExecutorCompat.GetFileIOStatus(),
        "CustomAsset=" .. (ExecutorCompat.HasCustomAsset() and "AVAILABLE" or "UNAVAILABLE"),
    }
    return table.concat(parts, ", ")
end

function ExecutorCompat.SafeRequest(options)
    if type(options) == "string" then
        options = { Url = options, Method = "GET" }
    end
    if type(options) ~= "table" or type(options.Url) ~= "string" then
        return nil, "invalid request options"
    end

    local url = options.Url
    local method = options.Method or "GET"
    local headers = options.Headers
    local body = options.Body

    local requesters = {}
    if type(syn) == "table" and type(syn.request) == "function" then
        table.insert(requesters, function()
            return syn.request({ Url = url, Method = method, Headers = headers, Body = body })
        end)
    end

    if type(request) == "function" then
        table.insert(requesters, function()
            return request({ Url = url, Method = method, Headers = headers, Body = body })
        end)
    end

    if type(http_request) == "function" then
        table.insert(requesters, function()
            return http_request({ Url = url, Method = method, Headers = headers, Body = body })
        end)
    end

    if type(httprequest) == "function" then
        table.insert(requesters, function()
            return httprequest({ Url = url, Method = method, Headers = headers, Body = body })
        end)
    end

    if type(game.HttpGetAsync) == "function" then
        table.insert(requesters, function()
            return game:HttpGetAsync(url)
        end)
    end

    if type(game.HttpGet) == "function" then
        table.insert(requesters, function()
            return game:HttpGet(url, true)
        end)
    end

    if HttpService and type(HttpService.GetAsync) == "function" then
            table.insert(requesters, function()
                return HttpService:GetAsync(url)
            end)
    end

    for _, requester in ipairs(requesters) do
        local ok, result = safeCall(requester)
        if ok and result and result ~= "" then
            if type(result) == "table" and type(result.Body) == "string" then
                return result.Body
            end
            return result
        end
    end

    return nil, "no http request method available"
end

function ExecutorCompat.SafeReadFile(path)
    if type(readfile) ~= "function" then
        return nil, "readfile unavailable"
    end
    return safeCall(readfile, path)
end

function ExecutorCompat.SafeWriteFile(path, content)
    if type(writefile) ~= "function" then
        return false, "writefile unavailable"
    end
    return safeCall(writefile, path, tostring(content or ""))
end

function ExecutorCompat.SafeDeleteFile(path)
    if type(delfile) == "function" then
        return safeCall(delfile, path)
    end
    if type(writefile) == "function" then
        return safeCall(writefile, path, "{}")
    end
    return false, "delete unavailable"
end

function ExecutorCompat.SafeIsFile(path)
    if type(isfile) == "function" then
        local ok, result = safeCall(isfile, path)
        if ok then
            return result
        end
    end
    return false
end

function ExecutorCompat.SafeIsFolder(path)
    if type(isfolder) == "function" then
        local ok, result = safeCall(isfolder, path)
        if ok then
            return result
        end
    end
    return false
end

function ExecutorCompat.SafeMakeFolder(path)
    if type(makefolder) == "function" then
        return safeCall(makefolder, path)
    end
    return false, "makefolder unavailable"
end

return ExecutorCompat

-- Diagnostics: safe, minimal load-time reporting
pcall(function()
    print("[COMPAT] Module loaded")
    print("[COMPAT] Executor: " .. tostring(Environment.Name))
    print("[COMPAT] HTTP: " .. ExecutorCompat.GetHttpStatus())
    print("[COMPAT] LOADSTRING: " .. ExecutorCompat.GetLoadStringStatus())
    print("[COMPAT] OTHER REQUIRED CAPABILITIES: " .. ExecutorCompat.GetOtherCapabilitiesSummary())
    print("[COMPAT] Module READY")
end)
