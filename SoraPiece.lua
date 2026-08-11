-- SoraPiece.lua
-- Advanced Sora Piece auto-farm script for a LocalScript.
-- It scans the workspace and common remotes broadly so it can adapt to different object names.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
if not player then
    error("[SoraPiece] LocalPlayer missing. Run this from a LocalScript.")
end

local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("RootPart")
local humanoid = character:FindFirstChildOfClass("Humanoid")

local settings = {
    enabled = true,
    autoFarm = true,
    autoBoss = true,
    autoGems = true,
    autoChests = true,
    autoQuest = true,
    autoTeleport = true,
    scanInterval = 1.6,
    minActionDelay = 0.18,
    maxActionDelay = 0.42,
    antiBan = true,
    useMoveTo = true,
    maxTargets = 80,
    debug = true,
}

-- Owners: local player is owner by default; try to merge remote owners.json from repo
local owners = {}
local OWNERS_RAW_URL = "https://raw.githubusercontent.com/bobakerdraa-bot/SoraPieceV3/main/owners.json"

local function loadRemoteOwners()
    local ok, res = pcall(function()
        return game:HttpGet(OWNERS_RAW_URL, true)
    end)
    if not ok or not res or res == "" then
        return
    end
    local ok2, data = pcall(function() return HttpService:JSONDecode(res) end)
    if not ok2 or type(data) ~= "table" then
        return
    end
    if data.owners and type(data.owners) == "table" then
        for _, id in ipairs(data.owners) do
            owners[tonumber(id) or id] = true
        end
    end
end

-- Ensure local player is owner on their client
owners[player.UserId] = true
loadRemoteOwners()

local function isOwner(p)
    p = p or player
    return owners[tonumber(p.UserId) or p.UserId] == true
end

-- Simple owner-only GUI for toggling features and showing status
local gui
local function makeToggle(labelText, getStateFn, onToggle)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 140, 0, 28)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 14
    btn.AutoButtonColor = true
    local function refresh()
        local state = getStateFn()
        btn.BackgroundColor3 = state and Color3.fromRGB(64,160,64) or Color3.fromRGB(160,64,64)
        btn.Text = labelText .. (state and " : ON" or " : OFF")
    end
    btn.MouseButton1Click:Connect(function()
        local ok, err = pcall(function()
            local newVal = not getStateFn()
            onToggle(newVal)
        end)
        if not ok and settings.debug then warn("[SoraPiece] toggle error:", err) end
        refresh()
    end)
    refresh()
    return btn
end

local function createGui()
    if gui then return gui end
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SoraPieceGUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = player:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 160, 0, 260)
    frame.Position = UDim2.new(0, 8, 0, 80)
    frame.BackgroundTransparency = 0.15
    frame.BackgroundColor3 = Color3.fromRGB(20,20,20)
    frame.BorderSizePixel = 0
    frame.Parent = screenGui

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -8, 0, 28)
    title.Position = UDim2.new(0, 4, 0, 4)
    title.BackgroundTransparency = 1
    title.Text = "SoraPiece — Owner Panel"
    title.TextColor3 = Color3.new(1,1,1)
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 16
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = frame

    local y = 40
    local function addRow(obj)
        obj.Position = UDim2.new(0, 8, 0, y)
        obj.Parent = frame
        y = y + 34
    end

    -- Master enable toggle (owner only)
    local master = makeToggle("Automation",
        function() return settings.enabled end,
        function(val) settings.enabled = val end)
    addRow(master)

    local t1 = makeToggle("AutoFarm",
        function() return settings.autoFarm end,
        function(v) settings.autoFarm = v end)
    addRow(t1)
    local t2 = makeToggle("AutoBoss",
        function() return settings.autoBoss end,
        function(v) settings.autoBoss = v end)
    addRow(t2)
    local t3 = makeToggle("AutoGems",
        function() return settings.autoGems end,
        function(v) settings.autoGems = v end)
    addRow(t3)
    local t4 = makeToggle("AutoChests",
        function() return settings.autoChests end,
        function(v) settings.autoChests = v end)
    addRow(t4)
    local t5 = makeToggle("AutoQuest",
        function() return settings.autoQuest end,
        function(v) settings.autoQuest = v end)
    addRow(t5)
    local t6 = makeToggle("AutoTeleport",
        function() return settings.autoTeleport end,
        function(v) settings.autoTeleport = v end)
    addRow(t6)

    local info = Instance.new("TextLabel")
    info.Size = UDim2.new(1, -8, 0, 56)
    info.Position = UDim2.new(0, 8, 0, y)
    info.BackgroundTransparency = 1
    info.TextColor3 = Color3.new(1,0.85,0.2)
    info.Text = "Owner: " .. tostring(isOwner() and player.Name or "No") .. "\nStatus: initializing..."
    info.Font = Enum.Font.SourceSans
    info.TextSize = 14
    info.TextXAlignment = Enum.TextXAlignment.Left
    info.TextYAlignment = Enum.TextYAlignment.Top
    info.Parent = frame
    y = y + 64

    -- Update status periodically
    spawn(function()
        while screenGui.Parent do
            local s = string.format("Owner: %s\nTargets: E=%d B=%d G=%d C=%d Q=%d\nRemotes: atk=%s int=%s q=%s",
                isOwner() and player.Name or "No",
                #cache.targets.enemies, #cache.targets.bosses, #cache.targets.gems, #cache.targets.chests, #cache.targets.quest,
                cache.remotes.attack and cache.remotes.attack.Name or "-",
                cache.remotes.interact and cache.remotes.interact.Name or "-",
                cache.remotes.quest and cache.remotes.quest.Name or "-")
            info.Text = s
            task.wait(3)
        end
    end)

    gui = screenGui
    return gui
end

-- Only create GUI for owners
if isOwner() then
    createGui()
end

local cache = {
    lastScan = 0,
    remotes = { attack = nil, interact = nil, quest = nil },
    targets = { enemies = {}, bosses = {}, gems = {}, chests = {}, quest = {}, teleports = {} },
    lastAction = 0,
    actionTimes = {},
}

local keywords = {
    attack = {"attack", "atk", "hit", "damage", "combat", "fight", "skill", "slash", "punch", "strike"},
    interact = {"interact", "use", "collect", "pickup", "pick", "open", "claim", "activate", "touch", "press", "grab", "receive"},
    -- include common quest and quest-group names from Modules/Boss configs and pasted data
    quest = {"quest", "bounty", "mission", "task", "objective", "reward", "job", "event",
             "Bandits", "Bandit", "Monkey", "Spellblade", "Demon", "Angel", "Qin Shi", "Fujitora", "Bandit[Lv.25]",
             "Shadow Army", "Demi-God", "Demi-God[Lv.925]", "Sailor", "Sailor[Lv.450]", "Grade1 Sorcerer", "Grade1 Sorcerer[Lv.700]"},
    enemy = {"enemy", "enemies", "monster", "monsters", "mob", "mobs", "npc", "npcs", "creep", "bandit", "guard", "soldier", "dummy",
             -- Game-specific race names discovered in Modules/RaceInfo
             "Fishman", "Skypiean", "Longarm", "Longleg", "Mink", "Cyborg", "Lunarian", "Giant", "Ancient Oni", "Vampire", "Seraphim",
             "Demon", "Monkey", "Spellblade", "Angel"},
    boss = {"boss", "bosses", "raid", "elite", "champion", "king", "queen", "guardian", "overlord", "hero", "master",
            -- bosses discovered in Modules/Boss configs and pasted data
            "Giant", "Ancient Oni", "Seraphim", "Vampire",
            "Dio Boss", "Cid Kageno Boss", "Igris Boss", "Yami Boss", "Yami", "Julius Boss", "Sung Jin Woo Boss", "Qin Shi Boss",
            "Fujitora Boss", "Julius Boss", "Sung Jin Woo Boss", "Yami", "Julius", "Sung Jin Woo", "Fujitora", "Qin Shi",
            "Bandit Boss", "Bandit Boss[Lv.75]", "Kai Boss", "Kai Boss[Lv.500]", "Kashimo Boss", "Kashimo Boss[Lv.850]",
            "Mihawk Boss", "Gojo Boss", "Gojo Boss[Lv.875]",
            "Sukuna Boss", "Sukuna Boss [Lv. 1000]", "Shanks Boss", "Shanks Boss[Lv. 950]", "Finger Bearer Boss", "Finger Bearer Boss[Lv. 750]",
            "Kizaru Boss", "Kizaru Boss[Lv.425]", "Ace Boss", "Ace Boss[Lv. 475]", "White Beard Boss", "White Beard Boss[Lv. 500]",
            "Mr Boom Boom", "Mr Boom Boom[Lv.200]", "Itadori Boss", "Itadori Boss[Lv. 800]"},
    gem = {"gem", "gems", "crystal", "crystals", "orb", "stone", "token", "coin", "coins", "star", "ruby", "sapphire", "emerald", "jewel", "drop",
           -- fragment names from drops
           "Shadow Fragment", "Atomic Fragment", "Heavenly Fragment", "Mystical Beast Ember Fragment", "Yoru Essence"},
    chest = {"chest", "chests", "crate", "box", "treasure", "reward", "vault", "locker", "gift", "cache",
             "Common Chest", "Rare Chest", "Epic Chest", "Legendary Chest", "Mythic Chest", "Perfect Core", "Empowered Perfect Core"},
        -- include notable drops and fruits
        items = {"Limitless CT", "Six Eyes", "Cursed Core", "Inverted Spear of Heaven", "Light Fruit", "Flame Fruit", "Bomb Fruit", "Death Painting Womb", "Conquerer Fragment", "Quake Fruit", "Cursed Energy"},
    teleport = {"teleport", "portal", "spawn", "home", "village", "hub", "base", "camp", "gate", "gateway", "warp"},
}

local function safeCall(fn, ...)
    local ok, result = pcall(fn, ...)
    if not ok and settings.debug then
        warn("[SoraPiece] safeCall error:", result)
    end
    return ok, result
end

local function refreshCharacter()
    character = player.Character or player.CharacterAdded:Wait()
    rootPart = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("RootPart")
    humanoid = character:FindFirstChildOfClass("Humanoid")
end

player.CharacterAdded:Connect(refreshCharacter)

local function normalize(value)
    return string.lower(tostring(value or ""))
end

local function hasKeyword(name, list)
    local text = normalize(name)
    for _, keyword in ipairs(list) do
        if string.find(text, normalize(keyword), 1, true) then
            return true
        end
    end
    return false
end

local function getPrimaryPart(obj)
    if not obj then
        return nil
    end
    if obj:IsA("BasePart") then
        return obj
    end
    if obj:IsA("Model") then
        if obj.PrimaryPart and obj.PrimaryPart:IsA("BasePart") then
            return obj.PrimaryPart
        end
        local part = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("UpperTorso") or obj:FindFirstChild("LowerTorso") or obj:FindFirstChild("Torso")
        if part and part:IsA("BasePart") then
            return part
        end
        for _, child in ipairs(obj:GetDescendants()) do
            if child:IsA("BasePart") then
                return child
            end
        end
    end
    return nil
end

local function isValidTarget(obj)
    if not obj or not obj.Parent then
        return false
    end
    if obj:IsDescendantOf(character) then
        return false
    end
    if obj:IsA("BasePart") then
        return true
    end
    if obj:IsA("Model") then
        return getPrimaryPart(obj) ~= nil
    end
    return false
end

local function addTarget(list, obj)
    if not list or not obj then
        return
    end
    if #list >= settings.maxTargets then
        return
    end
    if not table.find(list, obj) then
        table.insert(list, obj)
    end
end

local function findRemote(root, keyList)
    if not root then
        return nil
    end
    for _, obj in ipairs(root:GetDescendants()) do
        if (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")) and hasKeyword(obj.Name, keyList) then
            return obj
        end
    end
    return nil
end

local function scanTargets()
    cache.targets = { enemies = {}, bosses = {}, gems = {}, chests = {}, quest = {}, teleports = {} }

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if isValidTarget(obj) then
            local name = obj.Name
            if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") then
                if hasKeyword(name, keywords.boss) then
                    addTarget(cache.targets.bosses, obj)
                else
                    addTarget(cache.targets.enemies, obj)
                end
            end

            if hasKeyword(name, keywords.gem) then
                addTarget(cache.targets.gems, obj)
            end
            if hasKeyword(name, keywords.chest) then
                addTarget(cache.targets.chests, obj)
            end
            if hasKeyword(name, keywords.quest) then
                addTarget(cache.targets.quest, obj)
            end
            if hasKeyword(name, keywords.teleport) then
                addTarget(cache.targets.teleports, obj)
            end

            if obj:IsA("BasePart") and obj:FindFirstChildOfClass("ClickDetector") then
                addTarget(cache.targets.quest, obj)
            end
        end
    end

    if #cache.targets.enemies == 0 then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") and not obj:IsDescendantOf(character) then
                addTarget(cache.targets.enemies, obj)
            end
        end
    end
end

local function getRemoteRoots()
    local roots = { ReplicatedStorage, Workspace }
    local maybe = { "Remotes", "Events", "Shared", "RemoteEvents", "RemoteFunctions" }
    for _, name in ipairs(maybe) do
        local child = ReplicatedStorage:FindFirstChild(name)
        if child then
            table.insert(roots, child)
        end
    end
    return roots
end

local function scanRemotes()
    local roots = getRemoteRoots()
    cache.remotes.attack = nil
    cache.remotes.interact = nil
    cache.remotes.quest = nil

    for _, root in ipairs(roots) do
        cache.remotes.attack = cache.remotes.attack or findRemote(root, keywords.attack)
        cache.remotes.interact = cache.remotes.interact or findRemote(root, keywords.interact)
        cache.remotes.quest = cache.remotes.quest or findRemote(root, keywords.quest)
    end
end

local _lastLog = 0
local function scanWorld()
    scanTargets()
    scanRemotes()
    if settings.debug and tick() - _lastLog > 5 then
        _lastLog = tick()
        warn("[SoraPiece] targets:", #cache.targets.enemies, #cache.targets.bosses, #cache.targets.gems, #cache.targets.chests, #cache.targets.quest)
        warn("[SoraPiece] remotes:", cache.remotes.attack and cache.remotes.attack.Name or "nil", cache.remotes.interact and cache.remotes.interact.Name or "nil", cache.remotes.quest and cache.remotes.quest.Name or "nil")
    end
end

local function getNearest(list)
    if not list or #list == 0 or not rootPart then
        return nil
    end
    local best = nil
    local closest = math.huge
    for _, obj in ipairs(list) do
        if obj and obj.Parent then
            local part = getPrimaryPart(obj)
            if part then
                local dist = (rootPart.Position - part.Position).Magnitude
                if dist < closest then
                    closest = dist
                    best = obj
                end
            end
        end
    end
    return best
end

local function moveTo(position)
    if not position or not rootPart then
        return
    end
    local targetPos = position + Vector3.new(0, 3, 0)
    if (rootPart.Position - targetPos).Magnitude < 2 then
        return
    end
    if settings.useMoveTo and humanoid and humanoid.Health > 0 then
        safeCall(function()
            humanoid:MoveTo(targetPos)
        end)
    else
        safeCall(function()
            rootPart.CFrame = CFrame.new(targetPos)
        end)
    end
    end
end

local function fireRemote(remote, target)
    if not remote then
        return false
    end
    return safeCall(function()
        if remote:IsA("RemoteEvent") then
            remote:FireServer(target)
        else
            remote:InvokeServer(target)
        end
    end)
end

local function canPerform(action, cooldown)
    cooldown = cooldown or 0.8
    local last = cache.actionTimes[action] or 0
    if tick() - last >= cooldown then
        cache.actionTimes[action] = tick()
        return true
    end
    return false
end

local function interactTarget(target)
    if not target then
        return false
    end
    if not canPerform("interact", 1.0) then
        return false
    end
    local part = getPrimaryPart(target)
    if part then
        moveTo(part.Position)
        task.wait(0.12)
    end
    if cache.remotes.interact then
        return fireRemote(cache.remotes.interact, target) or (part ~= nil)
    end
    return part ~= nil
end

local function attackTarget(target)
    if not target then
        return false
    end
    if not canPerform("attack", 0.6) then
        return false
    end
    local part = getPrimaryPart(target)
    if part then
        moveTo(part.Position)
        task.wait(0.12)
    end
    if cache.remotes.attack then
        return fireRemote(cache.remotes.attack, target) or (part ~= nil)
    end
    return part ~= nil
end

local function claimQuest()
    if not canPerform("claim", 2.0) then
        return false
    end
    if cache.remotes.quest then
        return fireRemote(cache.remotes.quest)
    end
    return interactTarget(getNearest(cache.targets.quest))
end

local function collectGem()
    if not canPerform("collect", 1.2) then
        return false
    end
    return interactTarget(getNearest(cache.targets.gems))
end

local function openChest()
    if not canPerform("chest", 1.5) then
        return false
    end
    return interactTarget(getNearest(cache.targets.chests))
end

local function farmEnemy()
    if not settings.autoFarm then return false end
    return attackTarget(getNearest(cache.targets.enemies))
end

local function farmBoss()
    if not settings.autoBoss then return false end
    return attackTarget(getNearest(cache.targets.bosses))
end

local function teleportToPortal()
    if not canPerform("teleport", 3.0) then
        return false
    end
    return interactTarget(getNearest(cache.targets.teleports))
end

local function randomDelay()
    if settings.antiBan then
        return settings.minActionDelay + math.random() * (settings.maxActionDelay - settings.minActionDelay)
    end
    return settings.minActionDelay
end

math.randomseed(tick())
scanWorld()

-- If not owner, disable active automation features to prevent abuse/lag
if not isOwner() then
    settings.autoFarm = false
    settings.autoBoss = false
    settings.autoGems = false
    settings.autoChests = false
    settings.autoQuest = false
    settings.autoTeleport = false
    if settings.debug then
        warn("[SoraPiece] You are not listed as an owner. Automation disabled. Request owner add your UserId to owners.json in the repo.")
    end
end

RunService.Heartbeat:Connect(function(dt)
    if not settings.enabled then
        return
    end
    if not rootPart or not rootPart.Parent then
        refreshCharacter()
    end

    if tick() - cache.lastScan > settings.scanInterval then
        scanWorld()
        cache.lastScan = tick()
    end

    -- Perform actions with internal cooldowns to avoid spamming
    farmEnemy()
    farmBoss()
    if settings.autoGems then
        collectGem()
    end
    if settings.autoChests then
        openChest()
    end
    if settings.autoQuest then
        claimQuest()
    end
    if settings.autoTeleport then
        teleportToPortal()
    end

    task.wait(0.05)
end)

print("[SoraPiece] Adaptive auto-farm script ready.")
