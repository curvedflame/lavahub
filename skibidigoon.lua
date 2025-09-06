--[[
  LAVAHUB snippet by curvedflame (https://github.com/curvedflame)
  Licensed under GPL-3.0
  Redistribution without proper credit is prohibited.
  DMCA will be enforced against skids. (credit me and i wont)
]]

-- really old not sure if it even works at this point

-- only kill aura enhance weapon and voicespam worked last time i played
-- i do not recomend this code its INSANELY bad 


-- i pray you can understand this
local Services = setmetatable({}, {__index = function(_, key) return game:GetService(key) end})
local Players, ReplicatedStorage, RunService, UserInputService, TweenService = Services.Players, Services.ReplicatedStorage, Services.RunService, Services.UserInputService, Services.TweenService
local LocalPlayer, Combat, Voice = Players.LocalPlayer, ReplicatedStorage:WaitForChild("Combat"), ReplicatedStorage:WaitForChild("Environment"):WaitForChild("Voice")
-- the config thing obviously (DO NOT LOWER UPDATEINTERVAL)
local Config = {
    toggles = {}, settings = {updateInterval = 0.75, voiceInterval = 0.1, voiceLine = "Line3", killAllOffset = Vector3.new(0, 2, 0)},
    weaponEnhancements = {Reach = 10000, AttackDelay = -10000, Damage = 10000, BluntChance = 10000, SwingSpeed = 100000, CouchDelay = -100, EncloseSpeed = -1000, BlockedTime = -10000, BaseForce = 100, LockSpread = 0, MaxAmmo = 100, Ammo = 100, ReleaseSpeed = 10000},
    weaponSizes = {Sword = Vector3.new(7, 2, 2), Spear = Vector3.new(25, 1.5, 1.5), Javelin = Vector3.new(10, 1.5, 1.5), Longsword = Vector3.new(7, 2, 2), Polearm = Vector3.new(20, 1.5, 1.5), ["Sapper Axe"] = Vector3.new(15, 2.5, 2.5)},
    specialWeaponAttributes = {Longbow = {BaseDamage = 1000, Ammo = 10000, EncloseSpeed = -1000, MaxAmmo = 10000}, Crossbow = {Ammo = 10000, EncloseSpeed = -1000, MaxAmmo = 10000}},
    constructibles = {"Large Abatis", "Abatis", "Reinforced Palisade", "Palisade", "Plank Palisade", "Open Plank Palisade", "Large Plank Palisade"}
}
-- gang its literally called utils
local Utils = {
    safeFind = function(parent, ...) for _, name in ipairs({...}) do parent = parent and parent:FindFirstChild(name) if not parent then return end end return parent end,
    getRoot = function(character) return character and (character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")) end,
    getClosestEnemy = function(character)
        if not character or not character:IsDescendantOf(workspace) then return end
        local myTeam, closestEnemy, closestDistance = character.Parent, nil, math.huge
        for _, player in ipairs(Players:GetPlayers()) do
            local enemyChar = player.Character
            if enemyChar and enemyChar ~= character and enemyChar.Parent ~= myTeam then
                local humanoid, head = enemyChar:FindFirstChild("Humanoid"), enemyChar:FindFirstChild("Head")
                if humanoid and humanoid.Health > 0 and head then
                    local distance = (head.Position - character.Head.Position).Magnitude
                    if distance < closestDistance then closestEnemy, closestDistance = enemyChar, distance end
                end
            end
        end
        return closestEnemy
    end,
    createGuiElement = function(elementType, properties)
        local element = Instance.new(elementType)
        for property, value in pairs(properties) do element[property] = value end
        return element
    end,
    debounce = function(func, wait)
        local lastCall = 0
        return function(...)
            local now = tick()
            if now - lastCall >= wait then lastCall = now return func(...) end
        end
    end
}

local Features = {
    enhanceWeapon = function(weapon) -- i love femboys
        local weaponType = weapon:GetAttribute("WeaponType")
        for attribute, value in pairs(Config.weaponEnhancements) do weapon:SetAttribute(attribute, value) end
        local size = Config.weaponSizes[weaponType] or Config.weaponSizes[weapon.Name]
        if size and weapon:FindFirstChild("Blade") then weapon.Blade.Size = size end
        local specialAttributes = Config.specialWeaponAttributes[weapon.Name]
        if specialAttributes then for attr, value in pairs(specialAttributes) do weapon:SetAttribute(attr, value) end end
    end,
    executeVoiceSpam = Utils.debounce(function() -- bro you have to be ungodly levels of stupid to not understand this
        local voiceFrame = Utils.safeFind(LocalPlayer.PlayerGui, "HealthUI", "VoiceFrame")
        if voiceFrame then Voice:FireServer(voiceFrame.Lines, Config.settings.voiceLine) end
    end, Config.settings.voiceInterval),
    autoReload = Utils.debounce(function()
        local refillStation = Utils.safeFind(workspace, "Map", "Refill Station")
        if refillStation then Combat:WaitForChild("Pickup"):FireServer(refillStation) end
    end, 1),
    autoConstruct = Utils.debounce(function(character)
        local hammer = Utils.safeFind(character, "Hammer")
        local destructibleAssets = Utils.safeFind(workspace, "Map", "DestructibleAssets")
        if hammer and destructibleAssets then
            for _, constructibleName in ipairs(Config.constructibles) do
                local asset = Utils.safeFind(destructibleAssets, constructibleName)
                if asset and asset:IsA("Model") and asset:FindFirstChild("MeshPart") then
                    Combat:WaitForChild("PropInteract"):FireServer("Construct", hammer, asset.MeshPart, asset, true)
                end
            end
        end
    end, 0.5),
    autoDestroy = Utils.debounce(function(character) -- made a working version once i dont have but this one broken
        local sapperAxe = Utils.safeFind(character, "Sapper Axe")
        local destructibleAssets = Utils.safeFind(workspace, "Map", "DestructibleAssets")
        if sapperAxe and destructibleAssets then
            for _, asset in ipairs(destructibleAssets:GetChildren()) do
                if asset:IsA("Model") and asset:FindFirstChild("MeshPart") then
                    Combat:WaitForChild("Feedback"):InvokeServer(asset.MeshPart, sapperAxe, 2, Vector3.new(1.5, 2.17, 14.29), false)
                end
            end
        end
    end, 0.5),
    killAll = Utils.debounce(function(character) --broken 
        local root = Utils.getRoot(character)
        local targetEnemy = Utils.getClosestEnemy(character)
        if root and targetEnemy then
            local targetRoot = Utils.getRoot(targetEnemy)
            if targetRoot then root.CFrame = targetRoot.CFrame * CFrame.new(Config.settings.killAllOffset) end
        end
    end, 0.1),
    alwaysParry = Utils.debounce(function() Combat.Parry:FireServer() end, 0.1)
}

local function mainLoop()
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("Humanoid") or character.Humanoid.Health <= 0 then return end
    if Config.toggles.Loop then
        for _, weapon in ipairs(character:GetChildren()) do
            local weaponType = weapon:GetAttribute("WeaponType")
            if (weaponType and Config.weaponSizes[weaponType]) or Config.weaponSizes[weapon.Name] then
                if weapon:IsA("Model") and weapon:FindFirstChild("Blade") then
                    local enemy = Utils.getClosestEnemy(character)
                    if enemy then Combat:WaitForChild("Feedback"):InvokeServer(enemy.Head, weapon, 2, Vector3.new(1.2233424186706543, 1.2570219039916992, 1.2233424186706543), true) end
                end
            end
        end
    end
    if Config.toggles.EnhanceWeapons then for _, weapon in ipairs(character:GetChildren()) do local weaponType = weapon:GetAttribute("WeaponType") if (weaponType and Config.weaponSizes[weaponType]) or Config.weaponSizes[weapon.Name] then if weapon:IsA("Model") and weapon:FindFirstChild("Blade") then Features.enhanceWeapon(weapon) end end end end
    if Config.toggles.KillAll then Features.killAll(character) end
    if Config.toggles.AutoReload then Features.autoReload() end
    if Config.toggles.AutoConstruct then Features.autoConstruct(character) end
    if Config.toggles.AutoDestroy then Features.autoDestroy(character) end
    if Config.toggles.AlwaysParry then Features.alwaysParry() end
    if Config.toggles.VoiceSpam then Features.executeVoiceSpam() end
    if Config.toggles.WalkSpeed then character.Humanoid.WalkSpeed = 14 end
end

local function createGui()
    local screenGui = Utils.createGuiElement("ScreenGui", {Name = "EnhancedGUI", ResetOnSpawn = false, Parent = LocalPlayer.PlayerGui})
    local mainFrame = Utils.createGuiElement("Frame", {Name = "MainFrame", Size = UDim2.new(0, 300, 0, 400), Position = UDim2.new(0.5, -150, 0.5, -200), BackgroundColor3 = Color3.fromRGB(30, 30, 30), Active = true, Draggable = true, Parent = screenGui})
    Utils.createGuiElement("TextLabel", {Name = "Title", Size = UDim2.new(1, -80, 0, 30), Position = UDim2.new(0, 10, 0, 5), BackgroundTransparency = 1, Text = "ayJadi femboy", TextColor3 = Color3.new(1, 1, 1), TextSize = 24, Font = Enum.Font.SourceSansBold, Parent = mainFrame})
    local closeButton = Utils.createGuiElement("TextButton", {Name = "CloseButton", Size = UDim2.new(0, 20, 0, 20), Position = UDim2.new(1, -25, 0, 5), BackgroundColor3 = Color3.fromRGB(200, 50, 50), Text = "X", TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.SourceSansBold, Parent = mainFrame})
    local minimizeButton = Utils.createGuiElement("TextButton", {Name = "MinimizeButton", Size = UDim2.new(0, 20, 0, 20), Position = UDim2.new(1, -50, 0, 5), BackgroundColor3 = Color3.fromRGB(50, 50, 200), Text = "-", TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.SourceSansBold, Parent = mainFrame})
    local contentFrame = Utils.createGuiElement("ScrollingFrame", {Name = "ContentFrame", Size = UDim2.new(1, -20, 1, -40), Position = UDim2.new(0, 10, 0, 35), BackgroundTransparency = 1, ScrollBarThickness = 8, Parent = mainFrame})
    closeButton.MouseButton1Click:Connect(function() screenGui:Destroy() end)
    local minimized = false
    minimizeButton.MouseButton1Click:Connect(function() minimized = not minimized TweenService:Create(mainFrame, TweenInfo.new(0.3), {Size = minimized and UDim2.new(0, 300, 0, 35) or UDim2.new(0, 300, 0, 400)}):Play() contentFrame.Visible = not minimized minimizeButton.Text = minimized and "+" or "-" end)
    local toggleButtons = {"Loop", "BindToLeftClick", "EnhanceWeapons", "VoiceSpam", "KillAll", "AutoReload", "AutoConstruct", "AutoDestroy", "AlwaysParry", "WalkSpeed"}
    for i, toggleName in ipairs(toggleButtons) do
        local button = Utils.createGuiElement("TextButton", {Name = toggleName, Size = UDim2.new(0.9, 0, 0, 30), Position = UDim2.new(0.05, 0, 0, 10 + 40 * (i-1)), BackgroundColor3 = Color3.fromRGB(50, 50, 50), Text = toggleName .. ": OFF", TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.SourceSans, TextSize = 18, Parent = contentFrame})
        button.MouseButton1Click:Connect(function() Config.toggles[toggleName] = not Config.toggles[toggleName] button.Text = toggleName .. ": " .. (Config.toggles[toggleName] and "ON" or "OFF") button.BackgroundColor3 = Config.toggles[toggleName] and Color3.fromRGB(0, 128, 0) or Color3.fromRGB(50, 50, 50) end)
    end
    local infiniteYieldButton = Utils.createGuiElement("TextButton", {Name = "InfiniteYield", Size = UDim2.new(0.9, 0, 0, 30), Position = UDim2.new(0.05, 0, 0, 10 + 40 * #toggleButtons), BackgroundColor3 = Color3.fromRGB(50, 50, 200), Text = "Infinite Yield", TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.SourceSansBold, TextSize = 18, Parent = contentFrame})
    infiniteYieldButton.MouseButton1Click:Connect(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))() end)
end
-- bro wtf was i on when this was made 
createGui()
RunService.Heartbeat:Connect(Utils.debounce(mainLoop, Config.settings.updateInterval))
UserInputService.InputBegan:Connect(function(input, gameProcessedEvent) if not gameProcessedEvent and Config.toggles.BindToLeftClick and input.UserInputType == Enum.UserInputType.MouseButton1 then mainLoop() end end)
if Utils.safeFind(LocalPlayer.PlayerGui, "Chat", "Logger") then LocalPlayer.PlayerGui.Chat.Logger.Disabled = true end
LocalPlayer:SetAttribute("JoinTime", nil)
for _, script in ipairs({"Chat.WarningFrame.WarningScript", "HealthUI.HealthScript", "Menu.Timer.TimerScript", "Menu.LogsFrame.LogsScript", "Menu.StoreFrame.StoreScript", "Menu.PingFPS.PingFPS", "ShieldHealth.ShieldHealth.ShieldUI"}) do
    local scriptInstance = Utils.safeFind(LocalPlayer.PlayerGui, unpack(script:split(".")))
    if scriptInstance then scriptInstance.Disabled = true end
end
for _, script in ipairs({"Barrier", "CheckDevice"}) do
    local scriptInstance = Utils.safeFind(LocalPlayer.PlayerScripts, script)
    if scriptInstance then scriptInstance.Disabled = true end
end
for _, anim in ipairs(LocalPlayer.PlayerScripts.CharacterAnimations:GetChildren()) do anim.AnimationSpeed = anim.AnimationSpeed * 10 end
if workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Waterdetection") then workspace.Map.Waterdetection:Destroy() end
