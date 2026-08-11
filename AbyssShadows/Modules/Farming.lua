-- Farming.lua
-- Core farming logic for Abyss Shadows.

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local DataManager = require(script.Parent.DataManager)
local Scanner = require(script.Parent.Scanner)
local Constants = require(script.Parent.Constants)

local Farming = {}
Farming.Connections = {}
Farming.Running = false
Farming.CurrentTarget = nil

local function safeDestroy(instance)
    if instance and instance.Destroy then
        instance:Destroy()
    end
end

local function compareTargets(a, b, root)
    local distA = math.huge
    local distB = math.huge
    if a and a.Model then
        local partA = a.Model:FindFirstChild("HumanoidRootPart") or a.Model:FindFirstChild("Root")
        if partA then
            distA = (partA.Position - root.Position).Magnitude
        end
    end
    if b and b.Model then
        local partB = b.Model:FindFirstChild("HumanoidRootPart") or b.Model:FindFirstChild("Root")
        if partB then
            distB = (partB.Position - root.Position).Magnitude
        end
    end

    local priority = Constants.Defaults.TargetPriority
    if priority == "Closest" then
        return distA < distB
    elseif priority == "Lowest Health" then
        return (a.Health or math.huge) < (b.Health or math.huge)
    elseif priority == "Highest Health" then
        return (a.Health or 0) > (b.Health or 0)
    elseif priority == "Bosses First" then
        local bossA = tostring(a.Category):lower():find("boss") and 1 or 0
        local bossB = tostring(b.Category):lower():find("boss") and 1 or 0
        if bossA ~= bossB then
            return bossA > bossB
        end
        return distA < distB
    else
        return math.random() < 0.5
    end
end

local function findNearestTarget(area)
    local player = Players.LocalPlayer
    if not player or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        return nil
    end
    local root = player.Character.HumanoidRootPart
    local bestTarget = nil

    for _, npc in ipairs(Scanner.NPCCache) do
        if npc and npc.Model and npc.Model.Parent then
            local npcRoot = npc.Model:FindFirstChild("HumanoidRootPart") or npc.Model:FindFirstChild("Root")
            if npcRoot then
                if not bestTarget or compareTargets(npc, bestTarget, root) then
                    bestTarget = npc
                end
            end
        end
    end
    return bestTarget
end

local function updateTargetStatus(target)
    if target then
        DataManager:UpdateStat("CurrentTargetName", target.Name or "Unknown")
        DataManager:UpdateStat("CurrentTargetHealth", target.Health or 0)
    else
        DataManager:UpdateStat("CurrentTargetName", "None")
        DataManager:UpdateStat("CurrentTargetHealth", 0)
    end
end

local function attackTarget(target)
    if not target or not target.Model or not target.Model.Parent then
        return false
    end
    local player = Players.LocalPlayer
    if not player or not player.Character or not player.Character:FindFirstChildOfClass("Humanoid") then
        return false
    end
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    local root = player.Character:FindFirstChild("HumanoidRootPart") or player.Character:FindFirstChild("Root")
    if not root then
        return false
    end

    local targetRoot = target.Model:FindFirstChild("HumanoidRootPart") or target.Model:FindFirstChild("Root")
    if not targetRoot then
        return false
    end

    DataManager:UpdateStat("Status", "Moving to " .. tostring(target.Name))
    DataManager:UpdateStat("CurrentLocation", target.Folder or "Unknown")
    humanoid:MoveTo(targetRoot.Position)

    if (targetRoot.Position - root.Position).Magnitude <= 6 then
        DataManager:UpdateStat("Status", "Engaging " .. tostring(target.Name))
    end
    return true
end

function Farming:Refresh()
    Scanner:ScanNpcs()
    Scanner:ScanChests()
    DataManager:UpdateStat("NPCCount", #Scanner.NPCCache)
    return Scanner.NPCCache, Scanner.ChestCache
end

function Farming:Start()
    if self.Running then
        return
    end
    Scanner:ScanNpcs()
    Scanner:ScanChests()
    self.Running = true
    DataManager:UpdateStat("Status", "Farming")
    table.insert(self.Connections, RunService.Heartbeat:Connect(function()
        if not self.Running then
            return
        end
        local target = findNearestTarget(Constants.Defaults.FarmArea or Constants.FarmAreas[1])
        if target then
            self.CurrentTarget = target
            updateTargetStatus(target)
            attackTarget(target)
        else
            DataManager:UpdateStat("Status", "No target found")
            updateTargetStatus(nil)
        end
    end))
end

function Farming:Stop()
    self.Running = false
    DataManager:UpdateStat("Status", "Stopped")
    DataManager:UpdateStat("CurrentTargetName", "None")
    DataManager:UpdateStat("CurrentTargetHealth", 0)
    for _, conn in ipairs(self.Connections) do
        if conn.Connected then
            conn:Disconnect()
        end
    end
    self.Connections = {}
end

function Farming:Toggle()
    if self.Running then
        self:Stop()
    else
        self:Start()
    end
end

return Farming
