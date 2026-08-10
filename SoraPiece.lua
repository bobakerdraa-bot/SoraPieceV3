-- SoraPiece.lua
-- SHADOW HUB | Sora Piece Edition
-- Designed for Sora Piece (91356007281562)
-- Load from GitHub raw URL after publishing to your repo.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("RootPart")
local humanoid = character:FindFirstChildOfClass("Humanoid")

local settings = {
    autoFarm = true,
    autoBoss = false,
    autoGems = false,
    autoChests = true,
    autoBounty = true,
    autoQuest = false,
    enableESP = false,
    scanInterval = 3,
    actionDelay = 0.35,
    useMoveTo = true,
    antiBan = true,
    debug = false,
}

local cache = {
    lastScan = 0,
    remotes = {},
    targets = {
        enemies = {},
        bosses = {},
        gems = {},
        chests = {},
        bounty = {},
        teleports = {},
    },
}

local ui = { espMarkers = {}, teleportButtons = {} }

local keywords = {
    attack = {"attack", "atk", "damage", "hit", "punch", "strike", "combat", "fight", "skill"},
    interact = {"collect", "pickup", "pick", "open", "claim", "use", "activate", "touch", "press", "grab"},
    bounty = {"bounty", "quest", "mission", "task", "objective", "reward", "job"},
    enemy = {"enemy", "enemies", "monster", "monsters", "mob", "mobs", "npc", "npcs", "creep", "bandit", "guard", "soldier"},
    boss = {"boss", "bosses", "raid", "elite", "champion", "king", "queen", "guardian", "overlord", "hero", "master"},
    gem = {"gem", "gems", "crystal", "crystals", "orb", "stone", "token", "coin", "star", "ruby", "sapphire", "emerald", "jewel"},
    chest = {"chest", "chests", "crate", "box", "treasure", "cache", "locker", "gift", "vault"},
    teleport = {"teleport", "portal", "spawn", "home", "village", "hub", "base", "camp", "gate", "gateway"},
}

local function safeCall(fn, ...)
    local ok, result = pcall(fn, ...)
    if not ok and settings.debug then
        warn("[SoraPiece] error", result)
    end
    return ok, result
end

local function refreshCharacter()
    character = player.Character or player.CharacterAdded:Wait()
    rootPart = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("RootPart")
    humanoid = character:FindFirstChildOfClass("Humanoid")
end

player.CharacterAdded:Connect(refreshCharacter)

local function normalize(text)
    return string.lower(tostring(text or ""))
end

local function hasKeyword(name, list)
    name = normalize(name)
    for _, keyword in ipairs(list) do
        if string.find(name, normalize(keyword), 1, true) then
            return true
        end
    end
    return false
end

local function getPrimaryPart(obj)
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
        for _, descendant in ipairs(obj:GetDescendants()) do
            if descendant:IsA("BasePart") then
                return descendant
            end
        end
    end
    return nil
end

local function isPlayerPart(obj)
    return obj:IsDescendantOf(character)
end

local function isValidTarget(obj)
    if not obj or isPlayerPart(obj) then
        return false
    end
    if obj:IsA("BasePart") then
        return true
    end
    if obj:IsA("Model") then
        if obj:FindFirstChildOfClass("Humanoid") then
            return true
        end
        return getPrimaryPart(obj) ~= nil
    end
    return false
end

local function findRemote(root, keywordList)
    for _, obj in ipairs(root:GetDescendants()) do
        if (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")) and hasKeyword(obj.Name, keywordList) then
            return obj
        end
    end
    return nil
end

local function scanRemotes()
    cache.remotes.attack = findRemote(ReplicatedStorage, keywords.attack) or findRemote(Workspace, keywords.attack)
    cache.remotes.interact = findRemote(ReplicatedStorage, keywords.interact) or findRemote(Workspace, keywords.interact)
    cache.remotes.bounty = findRemote(ReplicatedStorage, keywords.bounty) or findRemote(Workspace, keywords.bounty)
end

local function addTarget(list, obj)
    if #list >= 120 then
        return
    end
    if isValidTarget(obj) and not table.find(list, obj) then
        list[#list + 1] = obj
    end
end

local function scanTargets()
    cache.targets.enemies = {}
    cache.targets.bosses = {}
    cache.targets.gems = {}
    cache.targets.chests = {}
    cache.targets.bounty = {}
    cache.targets.teleports = {}

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if isPlayerPart(obj) then
            -- skip local player objects
        else
            local name = normalize(obj.Name)
            if isValidTarget(obj) then
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
                if hasKeyword(name, keywords.bounty) then
                    addTarget(cache.targets.bounty, obj)
                end
                if obj:IsA("BasePart") and obj:FindFirstChildOfClass("ClickDetector") then
                    addTarget(cache.targets.bounty, obj)
                end
                if hasKeyword(name, keywords.teleport) then
                    addTarget(cache.targets.teleports, obj)
                end
            end
        end
    end

    if #cache.targets.enemies == 0 then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") and not isPlayerPart(obj) then
                addTarget(cache.targets.enemies, obj)
            end
        end
    end
end

local function scanWorld()
    scanRemotes()
    scanTargets()
    if settings.debug then
        warn("[SoraPiece] attackRemote", cache.remotes.attack)
        warn("[SoraPiece] interactRemote", cache.remotes.interact)
        warn("[SoraPiece] bountyRemote", cache.remotes.bounty)
    end
end

local function getDistance(target)
    local part = getPrimaryPart(target)
    if part and rootPart then
        return (rootPart.Position - part.Position).Magnitude
    end
    return math.huge
end

local function getNearest(list)
    if not list or #list == 0 then
        return nil
    end
    local best
    local shortest = math.huge
    for _, target in ipairs(list) do
        local distance = getDistance(target)
        if distance < shortest then
            shortest = distance
            best = target
        end
    end
    return best
end

local function moveTo(position)
    if not position or not rootPart then
        return
    end
    if settings.useMoveTo and humanoid and humanoid.Health > 0 then
        safeCall(function()
            humanoid:MoveTo(position + Vector3.new(0, 3, 0))
        end)
    else
        safeCall(function()
            rootPart.CFrame = CFrame.new(position + Vector3.new(0, 3, 0))
        end)
    end
end

local function getActionDelay()
    if settings.antiBan then
        return settings.actionDelay + math.random() * 0.18
    end
    return settings.actionDelay
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

local function attackTarget(target)
    if not target then
        return false
    end
    local part = getPrimaryPart(target)
    if part then
        moveTo(part.Position)
        task.wait(0.1)
    end
    if cache.remotes.attack then
        fireRemote(cache.remotes.attack, target)
        return true
    end
    return part ~= nil
end

local function interactTarget(target)
    if not target then
        return false
    end
    local part = getPrimaryPart(target)
    if part then
        moveTo(part.Position)
        task.wait(0.1)
    end
    if cache.remotes.interact then
        fireRemote(cache.remotes.interact, target)
        return true
    end
    return part ~= nil
end

local function claimBounty()
    if cache.remotes.bounty then
        fireRemote(cache.remotes.bounty)
        return true
    end
    return interactTarget(getNearest(cache.targets.bounty))
end

local function collectGem()
    return interactTarget(getNearest(cache.targets.gems))
end

local function openChest()
    return interactTarget(getNearest(cache.targets.chests))
end

local function farmEnemy()
    return attackTarget(getNearest(cache.targets.enemies))
end

local function farmBoss()
    return attackTarget(getNearest(cache.targets.bosses))
end

local function createLabel(parent, text, position, size, textSize)
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Position = position
    label.Size = size
    label.Font = Enum.Font.Gotham
    label.TextSize = textSize or 14
    label.TextColor3 = Color3.fromRGB(245, 245, 245)
    label.Text = text
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = parent
    return label
end

local function createButton(parent, text, position, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 152, 0, 34)
    button.Position = position
    button.BackgroundColor3 = Color3.fromRGB(45, 55, 105)
    button.BorderSizePixel = 0
    button.Font = Enum.Font.GothamSemibold
    button.TextSize = 14
    button.TextColor3 = Color3.fromRGB(245, 245, 255)
    button.Text = text
    button.AutoButtonColor = true
    button.Parent = parent
    button.MouseButton1Click:Connect(callback)
    button.MouseEnter:Connect(function()
        button.BackgroundColor3 = Color3.fromRGB(80, 105, 220)
    end)
    button.MouseLeave:Connect(function()
        button.BackgroundColor3 = Color3.fromRGB(45, 55, 105)
    end)
    return button
end

local function clearESPMarkers()
    for _, marker in ipairs(ui.espMarkers) do
        if marker and marker.Parent then
            marker:Destroy()
        end
    end
    ui.espMarkers = {}
end

local function updateESPMarkers()
    if not settings.enableESP then
        clearESPMarkers()
        return
    end
    local active = {}
    for _, group in pairs(cache.targets) do
        for _, target in ipairs(group) do
            if target and target.Parent then
                local part = getPrimaryPart(target)
                if part then
                    local marker = ui.espMarkers[target]
                    if not marker then
                        marker = Instance.new("BillboardGui")
                        marker.Adornee = part
                        marker.Size = UDim2.new(0, 140, 0, 30)
                        marker.StudsOffset = Vector3.new(0, 2.5, 0)
                        marker.AlwaysOnTop = true
                        marker.Parent = player:WaitForChild("PlayerGui")
                        local label = Instance.new("TextLabel")
                        label.Size = UDim2.new(1, 0, 1, 0)
                        label.BackgroundTransparency = 0.4
                        label.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
                        label.BorderSizePixel = 0
                        label.Font = Enum.Font.GothamSemibold
                        label.TextSize = 12
                        label.TextColor3 = Color3.fromRGB(255, 255, 255)
                        label.Text = target.Name
                        label.Parent = marker
                        ui.espMarkers[target] = marker
                    end
                    active[target] = true
                end
            end
        end
    end
    for target, marker in pairs(ui.espMarkers) do
        if not active[target] or not target.Parent then
            marker:Destroy()
            ui.espMarkers[target] = nil
        end
    end
end

local function setStatus(text)
    if ui.statusLabel then
        ui.statusLabel.Text = "Status: " .. text
    end
end

local function showNotification(text)
    if ui.notificationLabel then
        ui.notificationLabel.Text = text
        ui.notificationLabel.Visible = true
        task.delay(3, function()
            if ui.notificationLabel then
                ui.notificationLabel.Visible = false
            end
        end)
    end
end

local function updateUI()
    if not ui.buttons then
        return
    end
    ui.buttons.autoFarm.Text = "Auto Farm: " .. (settings.autoFarm and "ON" or "OFF")
    ui.buttons.autoBoss.Text = "Boss Farm: " .. (settings.autoBoss and "ON" or "OFF")
    ui.buttons.autoGems.Text = "Auto Gems: " .. (settings.autoGems and "ON" or "OFF")
    ui.buttons.autoChests.Text = "Chest Farm: " .. (settings.autoChests and "ON" or "OFF")
    ui.buttons.autoBounty.Text = "Bounty Farm: " .. (settings.autoBounty and "ON" or "OFF")
    ui.buttons.autoQuest.Text = "Auto Quest: " .. (settings.autoQuest and "ON" or "OFF")
    ui.buttons.enableESP.Text = "ESP: " .. (settings.enableESP and "ON" or "OFF")
    if ui.summaryLabel then
        ui.summaryLabel.Text = string.format("Enemies: %d   Bosses: %d   Gems: %d   Chests: %d   Bounty: %d", #cache.targets.enemies, #cache.targets.bosses, #cache.targets.gems, #cache.targets.chests, #cache.targets.bounty)
    end
    if ui.teleportLabel then
        ui.teleportLabel.Text = "Teleport objects: " .. #cache.targets.teleports
    end
end

local function clearTeleportButtons()
    for _, button in ipairs(ui.teleportButtons) do
        if button and button.Parent then
            button:Destroy()
        end
    end
    ui.teleportButtons = {}
end

local function updateTeleportUI()
    clearTeleportButtons()
    local x = 10
    local y = 40
    for _, target in ipairs(cache.targets.teleports) do
        if target and target.Parent then
            local part = getPrimaryPart(target)
            if part then
                local button = createButton(ui.teleportPanel, target.Name, UDim2.new(0, x, 0, y), function()
                    moveTo(part.Position)
                    setStatus("Moving to " .. target.Name)
                end)
                ui.teleportButtons[#ui.teleportButtons + 1] = button
                x = x + 170
                if x > 430 then
                    x = 10
                    y = y + 42
                end
                if #ui.teleportButtons >= 8 then
                    break
                end
            end
        end
    end
    if #ui.teleportButtons == 0 and ui.teleportPanel then
        createLabel(ui.teleportPanel, "No teleport objects found. Refresh scan to locate nearby portals.", UDim2.new(0, 10, 0, 40), UDim2.new(1, -20, 0, 30), 13)
    end
end

local function buildUI()
    local playerGui = player:WaitForChild("PlayerGui")
    local existing = playerGui:FindFirstChild("SoraPieceGui")
    if existing then
        existing:Destroy()
    end
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SoraPieceGui"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui
    ui.screenGui = screenGui

    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.new(0, 600, 0, 420)
    main.Position = UDim2.new(0.03, 0, 0.05, 0)
    main.BackgroundColor3 = Color3.fromRGB(18, 20, 34)
    main.BorderSizePixel = 0
    main.Parent = screenGui

    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 50)
    header.BackgroundColor3 = Color3.fromRGB(24, 28, 50)
    header.BorderSizePixel = 0
    header.Parent = main

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0.5, 0, 1, 0)
    title.Position = UDim2.new(0, 16, 0, 0)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 18
    title.TextColor3 = Color3.fromRGB(214, 144, 255)
    title.Text = "Sora Piece"
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header

    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(0.4, 0, 1, 0)
    subtitle.Position = UDim2.new(0.5, 0, 0, 0)
    subtitle.BackgroundTransparency = 1
    subtitle.Font = Enum.Font.Gotham
    subtitle.TextSize = 12
    subtitle.TextColor3 = Color3.fromRGB(200, 200, 255)
    subtitle.Text = "Universal auto farm"
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.Parent = header

    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 32, 0, 28)
    closeButton.Position = UDim2.new(1, -40, 0, 11)
    closeButton.BackgroundColor3 = Color3.fromRGB(185, 70, 70)
    closeButton.BorderSizePixel = 0
    closeButton.Font = Enum.Font.GothamBlack
    closeButton.TextSize = 18
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.Text = "X"
    closeButton.Parent = header
    closeButton.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)

    local tabBar = Instance.new("Frame")
    tabBar.Size = UDim2.new(1, -24, 0, 34)
    tabBar.Position = UDim2.new(0, 12, 0, 62)
    tabBar.BackgroundTransparency = 1
    tabBar.Parent = main

    local body = Instance.new("Frame")
    body.Size = UDim2.new(1, -24, 1, -106)
    body.Position = UDim2.new(0, 12, 0, 102)
    body.BackgroundTransparency = 1
    body.Parent = main

    local tabNames = {"Home", "Farm", "Teleports", "Settings"}
    ui.pages = {}
    ui.tabButtons = {}
    for index, name in ipairs(tabNames) do
        local button = createButton(tabBar, name, UDim2.new(0, 12 + (index - 1) * 146, 0, 0), function()
            switchTab(name)
        end)
        button.Size = UDim2.new(0, 140, 0, 32)
        button.BackgroundColor3 = Color3.fromRGB(40, 50, 80)
        ui.tabButtons[name] = button
    end

    local function createPage(name)
        local page = Instance.new("Frame")
        page.Size = UDim2.new(1, 0, 1, 0)
        page.BackgroundTransparency = 1
        page.Parent = body
        ui.pages[name] = page
        return page
    end

    local function switchTab(activeName)
        for name, page in pairs(ui.pages) do
            page.Visible = name == activeName
        end
        for name, button in pairs(ui.tabButtons) do
            button.BackgroundColor3 = name == activeName and Color3.fromRGB(90, 110, 180) or Color3.fromRGB(40, 50, 80)
        end
    end

    local homePage = createPage("Home")
    ui.summaryLabel = createLabel(homePage, "Enemies: 0   Bosses: 0   Gems: 0   Chests: 0   Bounty: 0", UDim2.new(0, 16, 0, 8), UDim2.new(1, -32, 0, 24), 14)
    ui.teleportLabel = createLabel(homePage, "Teleport objects: 0", UDim2.new(0, 16, 0, 34), UDim2.new(1, -32, 0, 24), 14)
    ui.statusLabel = createLabel(homePage, "Status: Ready", UDim2.new(0, 16, 0, 60), UDim2.new(1, -32, 0, 24), 14)
    ui.notificationLabel = createLabel(homePage, "", UDim2.new(0, 16, 0, 86), UDim2.new(1, -32, 0, 24), 13)
    ui.notificationLabel.TextColor3 = Color3.fromRGB(255, 220, 120)
    ui.notificationLabel.Visible = false
    createLabel(homePage, "Automatically detects NPCs, bosses, gems, chests, bounty items, and teleport objects.", UDim2.new(0, 16, 0, 124), UDim2.new(1, -32, 0, 40), 13)

    local farmPage = createPage("Farm")
    ui.buttons = {}
    ui.buttons.autoFarm = createButton(farmPage, "Auto Farm: ON", UDim2.new(0, 16, 0, 10), function()
        settings.autoFarm = not settings.autoFarm
        updateUI()
    end)
    ui.buttons.autoBoss = createButton(farmPage, "Boss Farm: OFF", UDim2.new(0, 16, 0, 54), function()
        settings.autoBoss = not settings.autoBoss
        updateUI()
    end)
    ui.buttons.autoGems = createButton(farmPage, "Auto Gems: OFF", UDim2.new(0, 16, 0, 98), function()
        settings.autoGems = not settings.autoGems
        updateUI()
    end)
    ui.buttons.autoChests = createButton(farmPage, "Chest Farm: ON", UDim2.new(0, 340, 0, 10), function()
        settings.autoChests = not settings.autoChests
        updateUI()
    end)
    ui.buttons.autoBounty = createButton(farmPage, "Bounty Farm: ON", UDim2.new(0, 340, 0, 54), function()
        settings.autoBounty = not settings.autoBounty
        updateUI()
    end)
    ui.buttons.autoQuest = createButton(farmPage, "Auto Quest: OFF", UDim2.new(0, 340, 0, 98), function()
        settings.autoQuest = not settings.autoQuest
        updateUI()
    end)
    createButton(farmPage, "Refresh Scan", UDim2.new(0, 16, 0, 146), function()
        scanWorld()
        updateUI()
        updateTeleportUI()
        showNotification("Scan refreshed")
    end)

    local teleportPage = createPage("Teleports")
    ui.teleportPanel = Instance.new("Frame")
    ui.teleportPanel.Size = UDim2.new(1, -32, 1, -56)
    ui.teleportPanel.Position = UDim2.new(0, 16, 0, 40)
    ui.teleportPanel.BackgroundTransparency = 1
    ui.teleportPanel.Parent = teleportPage
    createLabel(teleportPage, "Teleport objects found in the world are shown here.", UDim2.new(0, 16, 0, 10), UDim2.new(1, -32, 0, 24), 13)

    local settingsPage = createPage("Settings")
    ui.buttons.enableESP = createButton(settingsPage, "ESP: OFF", UDim2.new(0, 16, 0, 10), function()
        settings.enableESP = not settings.enableESP
        updateUI()
    end)
    createButton(settingsPage, "MoveTo: ON", UDim2.new(0, 16, 0, 54), function()
        settings.useMoveTo = not settings.useMoveTo
        showNotification("MoveTo " .. (settings.useMoveTo and "enabled" or "disabled"))
    end)
    createButton(settingsPage, "AntiBan: ON", UDim2.new(0, 16, 0, 98), function()
        settings.antiBan = not settings.antiBan
        showNotification("AntiBan " .. (settings.antiBan and "enabled" or "disabled"))
    end)
    createButton(settingsPage, "Scan: " .. settings.scanInterval .. "s", UDim2.new(0, 340, 0, 10), function()
        settings.scanInterval = settings.scanInterval >= 6 and 2 or settings.scanInterval + 1
        updateUI()
        showNotification("Scan interval set to " .. settings.scanInterval .. "s")
    end)
    createButton(settingsPage, "Debug: OFF", UDim2.new(0, 340, 0, 54), function()
        settings.debug = not settings.debug
        showNotification("Debug " .. (settings.debug and "enabled" or "disabled"))
    end)

    switchTab("Home")
    updateUI()
    updateTeleportUI()
end

refreshCharacter()
buildUI()
scanWorld()
updateUI()
setStatus("Loaded successfully")
showNotification("Sora Piece panel ready")

task.spawn(function()
    while ui.screenGui and ui.screenGui.Parent do
        if not rootPart or not rootPart.Parent then
            refreshCharacter()
        end
        if tick() - cache.lastScan > settings.scanInterval then
            scanWorld()
            cache.lastScan = tick()
            updateUI()
            updateTeleportUI()
            updateESPMarkers()
            setStatus("Scan complete")
        end
        if settings.autoFarm then
            farmEnemy()
        end
        if settings.autoBoss then
            farmBoss()
        end
        if settings.autoGems then
            collectGem()
        end
        if settings.autoChests then
            openChest()
        end
        if settings.autoBounty then
            claimBounty()
        end
        if settings.autoQuest then
            claimBounty()
        end
        task.wait(getActionDelay())
    end
end)

print("[SoraPiece] Loaded SHADOW HUB panel.")
