-- GemManager.lua
-- Handles gem collection and session tracking.

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Scanner = require(script.Parent.Scanner)
local DataManager = require(script.Parent.DataManager)
local Constants = require(script.Parent.Constants)

local GemManager = {}
GemManager.Running = false
GemManager.Connections = {}

local function findNearbyGem(range)
    local player = Players.LocalPlayer
    if not player or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        return nil
    end
    local root = player.Character.HumanoidRootPart
    local nearest = nil
    local bestDist = math.huge
    for _, gem in ipairs(Scanner.GemCache or {}) do
        if gem and gem.Parent then
            local part = gem:IsA("BasePart") and gem or gem:FindFirstChildWhichIsA("BasePart")
            if part then
                local dist = (part.Position - root.Position).Magnitude
                if dist <= range and dist < bestDist then
                    bestDist = dist
                    nearest = gem
                end
            end
        end
    end
    return nearest
end

function GemManager:Start()
    if self.Running then
        return
    end
    Scanner:ScanGems()
    self.Running = true
    local connection = RunService.Heartbeat:Connect(function()
        if not self.Running then
            return
        end
        if not Constants.Defaults.AutoGems then
            return
        end
        local gem = findNearbyGem(Constants.Defaults.GemRange)
        if gem then
            DataManager:IncrementStat("SessionGems", 1)
            local now = tick()
            if DataManager.State.LastGemTick == 0 then
                DataManager.State.LastGemTick = now
            end
            local elapsed = math.max(1, now - DataManager.State.LastGemTick)
            DataManager:UpdateStat("GemsPerMinute", DataManager.State.SessionGems / (elapsed / 60))
            DataManager:UpdateStat("Status", "Collecting gem")
            if gem:IsA("BasePart") then
                local player = Players.LocalPlayer
                if player and player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
                    player.Character:FindFirstChildOfClass("Humanoid"):MoveTo(gem.Position)
                end
            end
        end
    end)
    table.insert(self.Connections, connection)
end

function GemManager:Stop()
    self.Running = false
    for _, conn in ipairs(self.Connections) do
        if conn.Connected then
            conn:Disconnect()
        end
    end
    self.Connections = {}
end

return GemManager
