-- ChestManager.lua
-- Handles chest detection and collection logic.

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Scanner = require(script.Parent.Scanner)
local DataManager = require(script.Parent.DataManager)
local Constants = require(script.Parent.Constants)

local ChestManager = {}
ChestManager.Running = false
ChestManager.Connections = {}
ChestManager.CurrentChest = nil

local function getChestPosition(chest)
    if not chest then
        return nil
    end
    local part = chest:IsA("BasePart") and chest or chest:FindFirstChildWhichIsA("BasePart")
    return part and part.Position or nil
end

local function findNearestChest(range)
    local player = Players.LocalPlayer
    if not player or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        return nil
    end
    local root = player.Character.HumanoidRootPart
    local nearest = nil
    local bestDist = math.huge
    for _, chest in ipairs(Scanner.ChestCache) do
        if chest and chest.Parent then
            local pos = getChestPosition(chest)
            if pos then
                local dist = (pos - root.Position).Magnitude
                if dist <= range and dist < bestDist then
                    bestDist = dist
                    nearest = chest
                end
            end
        end
    end
    return nearest
end

function ChestManager:ScanChests()
    Scanner:ScanChests()
    return Scanner.ChestCache
end

function ChestManager:Start()
    if self.Running then
        return
    end
    Scanner:ScanChests()
    self.Running = true
    self.CurrentChest = nil
    DataManager:Log("ChestManager started")
    local connection = RunService.Heartbeat:Connect(function()
        if not self.Running then
            return
        end
        if not Constants.Defaults.AutoChests then
            return
        end
        local chest = findNearestChest(Constants.Defaults.ChestRange)
        if chest then
            self.CurrentChest = chest
            DataManager:UpdateStat("ChestTarget", chest.Name or "Chest")
            DataManager:UpdateStat("Status", "Collecting chest")
            local player = Players.LocalPlayer
            if player and player.Character then
                local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
                local root = player.Character:FindFirstChild("HumanoidRootPart")
                local targetPos = getChestPosition(chest)
                if humanoid and root and targetPos then
                    humanoid:MoveTo(targetPos)
                end
            end
        else
            DataManager:UpdateStat("ChestTarget", "None")
        end
    end)
    table.insert(self.Connections, connection)
end

function ChestManager:Stop()
    self.Running = false
    DataManager:UpdateStat("ChestTarget", "None")
    DataManager:Log("ChestManager stopped")
    for _, conn in ipairs(self.Connections) do
        if conn.Connected then
            conn:Disconnect()
        end
    end
    self.Connections = {}
    self.CurrentChest = nil
end

function ChestManager:Toggle()
    if self.Running then
        self:Stop()
    else
        self:Start()
    end
end

return ChestManager
