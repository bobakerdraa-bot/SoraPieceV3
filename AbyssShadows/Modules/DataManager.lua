-- DataManager.lua
-- Handles runtime state and session metrics.

local DataManager = {}

DataManager.State = {
    LocalPlayer = game:GetService("Players").LocalPlayer,
    Enabled = true,
    AutoFarm = false,
    AutoCollect = false,
    AutoReturn = false,
    AutoChests = false,
    AutoGems = false,
    AttackRange = 25,
    TargetPriority = "Closest",
    CurrentTargetName = "None",
    CurrentTargetHealth = 0,
    CurrentLocation = "Unknown",
    CurrentGems = 0,
    CurrentCoins = 0,
    CurrentEXP = 0,
    NPCCount = 0,
    ServerCount = 0,
    PlayerCount = 0,
    GemsPerMinute = 0,
    SessionGems = 0,
    LastGemTick = tick(),
    ChestTarget = "None",
    DebugLogging = false,
    Status = "Idle",
    LastUpdate = tick(),
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

function DataManager:IsLocalOwner()
    return self.State.LocalPlayer and self.State.LocalPlayer.UserId == 2851497079
end

return DataManager
