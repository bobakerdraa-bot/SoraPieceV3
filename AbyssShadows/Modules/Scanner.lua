-- Scanner.lua
-- Inspects NPCs, chests, and other game objects for runtime debugging.

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local DataManager = require(script.Parent.DataManager)

local Scanner = {}
Scanner.NPCCache = {}
Scanner.ChestCache = {}
Scanner.GemCache = {}
Scanner.Connections = {}

local function gatherNpcInfo(model)
    if not model or not model:IsA("Model") then
        return nil
    end
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return nil
    end
    local root = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Root") or model:FindFirstChild("Torso")
    local position = root and root.Position or Vector3.new()
    return {
        Name = model.Name,
        Model = model,
        Folder = model.Parent and model.Parent:GetFullName() or "Unknown",
        HasHumanoid = true,
        HasRoot = root ~= nil,
        Health = humanoid.Health,
        MaxHealth = humanoid.MaxHealth,
        Position = position,
        RespawnInfo = model:FindFirstChild("Respawn") and true or false,
        Category = model:GetAttribute("NPCType") or model:GetAttribute("Type") or "Unknown",
        Humanoid = humanoid,
    }
end

local function scanWorkspaceFor(predicate)
    local results = {}
    for _, root in ipairs({Workspace, ReplicatedStorage}) do
        for _, descendant in ipairs(root:GetDescendants()) do
            if predicate(descendant) then
                table.insert(results, descendant)
            end
        end
    end
    return results
end

function Scanner:ScanNpcs()
    self.NPCCache = {}
    local candidates = scanWorkspaceFor(function(descendant)
        if not descendant:IsA("Model") or not descendant:FindFirstChildOfClass("Humanoid") then
            return false
        end
        return not Players:GetPlayerFromCharacter(descendant)
    end)
    for _, model in ipairs(candidates) do
        local info = gatherNpcInfo(model)
        if info then
            table.insert(self.NPCCache, info)
        end
    end
    DataManager:Log("ScanNpcs found", #self.NPCCache, "NPCs")
    return self.NPCCache
end

function Scanner:ScanChests()
    self.ChestCache = {}
    local candidates = scanWorkspaceFor(function(descendant)
        if not (descendant:IsA("Model") or descendant:IsA("BasePart")) then
            return false
        end
        local name = tostring(descendant.Name):lower()
        return name:find("chest") or name:find("crate") or name:find("treasure") or name:find("vault") or name:find("reward")
    end)
    for _, chest in ipairs(candidates) do
        table.insert(self.ChestCache, chest)
    end
    DataManager:Log("ScanChests found", #self.ChestCache, "chests")
    return self.ChestCache
end

function Scanner:ScanGems()
    self.GemCache = {}
    local candidates = scanWorkspaceFor(function(descendant)
        if not (descendant:IsA("Model") or descendant:IsA("BasePart")) then
            return false
        end
        local name = tostring(descendant.Name):lower()
        return name:find("gem") or name:find("crystal") or name:find("orb") or name:find("token") or name:find("jewel")
    end)
    for _, gem in ipairs(candidates) do
        table.insert(self.GemCache, gem)
    end
    DataManager:Log("ScanGems found", #self.GemCache, "gems")
    return self.GemCache
end

function Scanner:StartAutoRefresh()
    self:Disconnect()
    self:ScanNpcs()
    self:ScanChests()
    self:ScanGems()
    local connection = RunService.Heartbeat:Connect(function()
        self:ScanNpcs()
        self:ScanChests()
        self:ScanGems()
    end)
    table.insert(self.Connections, connection)
end

function Scanner:Disconnect()
    for _, conn in ipairs(self.Connections) do
        if conn.Connected then
            conn:Disconnect()
        end
    end
    self.Connections = {}
end

return Scanner
