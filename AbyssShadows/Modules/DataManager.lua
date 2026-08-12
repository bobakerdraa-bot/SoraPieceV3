-- DataManager.lua
-- Handles runtime state and session metrics.

local DataManager = {}

DataManager.DefaultState = {
    CurrentLocation = "Unknown",
    Status = "Idle",
    CurrentTargetName = "None",
    CurrentTargetHealth = 0,
    ChestTarget = "None",
    SessionGems = 0,
    GemsPerMinute = 0,
    LastGemTick = tick(),
}

DataManager.State = {}

local function normalizeNumber(value, default)
    local numberValue = tonumber(value)
    if numberValue == nil then
        return default
    end
    return numberValue
end

local function normalizeString(value, default)
    if value == nil then
        return default
    end
    return tostring(value)
end

function DataManager:EnsureState()
    if type(self) ~= "table" then
        return
    end
    if type(self.State) ~= "table" then
        self.State = {}
    end
    for key, default in pairs(DataManager.DefaultState) do
        if self.State[key] == nil then
            self.State[key] = default
        else
            if type(default) == "number" then
                self.State[key] = normalizeNumber(self.State[key], default)
            elseif type(default) == "string" then
                self.State[key] = normalizeString(self.State[key], default)
            end
        end
    end
end

function DataManager:GetState(key)
    if type(self) ~= "table" then
        return "Unknown"
    end
    self:EnsureState()
    local value = self.State and self.State[key]
    if value == nil then
        return DataManager.DefaultState[key] or "Unknown"
    end
    if type(DataManager.DefaultState[key]) == "number" then
        return normalizeNumber(value, DataManager.DefaultState[key])
    end
    if type(DataManager.DefaultState[key]) == "string" then
        return normalizeString(value, DataManager.DefaultState[key])
    end
    return value
end

function DataManager:UpdateStat(key, value)
    if type(self) ~= "table" or value == nil then
        return
    end
    self:EnsureState()
    if type(self.State) ~= "table" then
        self.State = {}
    end
    if DataManager.DefaultState[key] ~= nil then
        if type(DataManager.DefaultState[key]) == "number" then
            value = normalizeNumber(value, DataManager.DefaultState[key])
        else
            value = tostring(value)
        end
    end
    self.State[key] = value
end

function DataManager:IncrementStat(key, amount)
    amount = tonumber(amount) or 1
    self:EnsureState()
    if type(self.State[key]) ~= "number" then
        return
    end
    self.State[key] = self.State[key] + amount
end

function DataManager:ResetSessionStats()
    self:EnsureState()
    self.State.SessionGems = 0
    self.State.GemsPerMinute = 0
    self.State.LastGemTick = tick()
end

function DataManager:Log(...)
    local parts = {}
    for i = 1, select("#", ...) do
        parts[i] = tostring(select(i, ...))
    end
    local message = table.concat(parts, " ")
    if type(warn) == "function" then
        warn("[AbyssShadows] " .. message)
    elseif type(print) == "function" then
        print("[AbyssShadows] " .. message)
    end
end

return DataManager
