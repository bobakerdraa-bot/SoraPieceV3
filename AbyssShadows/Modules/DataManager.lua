-- DataManager.lua
-- Handles runtime state and session metrics.

local DataManager = {}

DataManager.State = {
    CurrentTargetName = "None",
    CurrentTargetHealth = 0,
    CurrentLocation = "Unknown",
    GemsPerMinute = 0,
    SessionGems = 0,
    LastGemTick = tick(),
    ChestTarget = "None",
    DebugLogging = false,
    Status = "Idle",
}

function DataManager:UpdateStat(key, value)
    if self.State[key] == nil then
        self.State[key] = value
        return
    end
    self.State[key] = value
end

function DataManager:IncrementStat(key, amount)
    amount = amount or 1
    if type(self.State[key]) ~= "number" then
        return
    end
    self.State[key] = self.State[key] + amount
end

function DataManager:ResetSessionStats()
    self.State.SessionGems = 0
    self.State.GemsPerMinute = 0
    self.State.LastGemTick = tick()
end

return DataManager
