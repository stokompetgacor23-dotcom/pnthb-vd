-- =======================================================
-- PINATHUB - COMBAT MODULE
-- =======================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local Combat = {}

Combat.Utils = nil
Combat.Config = nil
Combat.Player = nil

Combat.CachedTarget = nil
Combat.LastTargetCheck = 0
Combat.TargetPartCache = {}
Combat.ExactParryRemote = nil
Combat.LastParryTick = 0
Combat.CachedBasicAttack = nil
Combat.SearchedAttackRemote = false
Combat.lastAttackStrike = 0
Combat.CFG_BurstAmount = 8
Combat.CFG_ParryCooldown = 0.06
Combat.CFG_MaxVelocity = 32
Combat.CFG_AimPrediction = true

function Combat.GetParryRemote()
    if Combat.ExactParryRemote and Combat.ExactParryRemote.Parent then return Combat.ExactParryRemote end
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if not remotes then return nil end
    local items = remotes:FindFirstChild("Items")
    local dagger = items and items:FindFirstChild("Parrying Dagger")
    if dagger and dagger:FindFirstChild("parry") then Combat.ExactParryRemote = dagger.parry
    else for _, v in ipairs(remotes:GetDescendants()) do if v:IsA("RemoteEvent") and v.Name:lower() == "parry" then Combat.ExactParryRemote = v; break end end end
    return Combat.ExactParryRemote
end

function Combat.IsKillerUsingSkill(char)
    for _, skill in ipairs(Combat.Config.IgnoreSkills) do
        if char:GetAttribute(skill) or Combat.Utils.GetGameValue(char, skill) then return true end
    end
    return false
end

function Combat.GetKillerProfile(char)
    local selected = Combat.Config.Current.ParryMatchup or "Auto"
    if selected ~= "Auto" then return Combat.Config.KillerProfiles[selected] or { BonusDist = 1, Delay = 0 } end
    local detect = string.upper(tostring(char:GetAttribute("KillerType") or char:GetAttribute("Mask") or char.Name))
    for profile, mask in pairs(Combat.Config.MaskNames) do if detect:find(mask) then return Combat.Config.KillerProfiles[profile] end end
    return { BonusDist = 1, Delay = 0 }
end

function Combat.TriggerParryDagger()
    local now = tick()
    if now - Combat.LastParryTick < Combat.CFG_ParryCooldown then return end
    local remote = Combat.GetParryRemote()
    if not remote then return end
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not (root and hum) or hum.Health <= 0 then return end
    local tool = char:FindFirstChild("Parrying Dagger") or char:FindFirstChildWhichIsA("Tool")
    if not tool then return end
    local ping = Combat.Utils.GetPing()
    local bestTarget = nil; local bestDistance = math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Team and plr.Team.Name:lower():find("killer") and plr.Character then
            local eChar = plr.Character
            local eRoot = eChar:FindFirstChild("HumanoidRootPart")
            local eHum = eChar:FindFirstChildOfClass("Humanoid")
            if eRoot and eHum and eHum.Health > 0 then
                if Combat.IsKillerUsingSkill(eChar) then continue end
                local profile = Combat.GetKillerProfile(eChar)
                local maxDist = (tonumber(Combat.Config.Current.ParryDistance) or 10) + (profile.BonusDist or 0) + (ping * 10)
                local predictPos = eRoot.Position
                if Combat.CFG_AimPrediction then
                    local vel = eRoot.AssemblyLinearVelocity
                    if vel.Magnitude > Combat.CFG_MaxVelocity then vel = vel.Unit * Combat.CFG_MaxVelocity end
                    local strict = Combat.Config.Current.AimStrictness or 1.3
                    predictPos = predictPos + (vel * (ping + (strict * 0.045)))
                end
                local dist = (predictPos - root.Position).Magnitude
                if dist <= maxDist and dist < bestDistance then bestDistance = dist; bestTarget = { Root = eRoot, Profile = profile } end
            end
        end
    end
    if not bestTarget then return end
    Combat.LastParryTick = now
    local finalDelay = (bestTarget.Profile.Delay or 0) + (Combat.Config.Current.ParryDelayOffset or 0)
    task.spawn(function()
        if finalDelay > 0 then task.wait(finalDelay) end
        for i = 1, Combat.CFG_BurstAmount do
            if not Combat.Config.Current.AutoParry then break end
            if not remote or not remote.Parent then break end
            pcall(function() remote:FireServer() end)
            task.wait(0.008)
        end
    end)
end

function Combat.GetClosestPlayer(currentTarget)
    local camera = workspace.CurrentCamera
    local center = camera.ViewportSize * 0.5
    local shortest = Combat.Config.Current.AimRadius
    local myTeam = (LocalPlayer.Team and LocalPlayer.Team.Name:lower()) or ""
    local isKiller = myTeam:find("killer")
    local camPos = camera.CFrame.Position
    if currentTarget and currentTarget.Parent then
        local hum = currentTarget.Parent:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 then
            local pos, visible = camera:WorldToViewportPoint(currentTarget.Position)
            if visible then
                local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                if dist <= Combat.Config.Current.AimRadius then
                    if not Combat.Config.Current.WallCheck or Combat.Utils.IsVisible(currentTarget, Combat.Config.Current.WallCheck) then
                        return currentTarget
                    end
                end
            end
        end
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer or not p.Character then continue end
        local char = p.Character
        local hum = char:FindFirstChild("Humanoid")
        if not hum or hum.Health <= 0 then continue end
        local enemyTeam = (p.Team and p.Team.Name:lower()) or ""
        local enemyKiller = enemyTeam:find("killer")
        if isKiller and enemyKiller then continue end
        if not isKiller and not enemyKiller then continue end
        if isKiller then
            if Combat.Utils.GetGameValue(char, "Knocked") or Combat.Utils.GetGameValue(char, "IsHooked") then continue end
        end
        local targetPart = Combat.TargetPartCache[char]
        if not targetPart or not targetPart.Parent then
            targetPart = (Combat.Config.Current.AimbotPart == "Head" and char:FindFirstChild("Head"))
                or (Combat.Config.Current.AimbotPart == "Body (RootPart)" and char:FindFirstChild("HumanoidRootPart"))
                or char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
                or char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
            Combat.TargetPartCache[char] = targetPart
        end
        if not targetPart then continue end
        if (targetPart.Position - camPos).Magnitude > Combat.Config.Current.AimDistance then continue end
        local pos, visible = camera:WorldToViewportPoint(targetPart.Position)
        if not visible then continue end
        local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
        if dist < shortest then
            if not Combat.Config.Current.WallCheck or Combat.Utils.IsVisible(targetPart, Combat.Config.Current.WallCheck) then
                shortest = dist
                Combat.CachedTarget = targetPart
            end
        end
    end
    return Combat.CachedTarget
end

function Combat.GetClosestSilentTarget()
    local camera = workspace.CurrentCamera
    local center = camera.ViewportSize * 0.5
    local closest = nil
    local shortest = Combat.Config.Current.SilentAimFOV or 250
    local myTeam = (LocalPlayer.Team and LocalPlayer.Team.Name:lower()) or ""
    local survivor = not myTeam:find("killer")
    if not survivor then return nil end
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer or not p.Character then continue end
        local enemyTeam = (p.Team and p.Team.Name:lower()) or ""
        if not enemyTeam:find("killer") then continue end
        local char = p.Character
        local root = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not (root and hum and hum.Health > 0) then continue end
        local pos, visible = camera:WorldToViewportPoint(root.Position)
        if not visible then continue end
        if Combat.Config.Current.WallCheck and not Combat.Utils.IsVisible(root, Combat.Config.Current.WallCheck) then continue end
        local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
        if dist < shortest then shortest = dist; closest = root end
    end
    return closest
end

function Combat.UpdateHitbox(eRoot)
    if Combat.Config.Current.HitboxExpander then
        local targetSize = Combat.Utils.v3(Combat.Config.Current.HitboxSize, Combat.Config.Current.HitboxSize, Combat.Config.Current.HitboxSize)
        if eRoot.Size ~= targetSize then
            pcall(function()
                eRoot.Size = targetSize
                eRoot.Transparency = 0.9
                eRoot.Material = Enum.Material.ForceField
                eRoot.Color = Color3.fromRGB(255, 0, 0)
                eRoot.Massless = false
                eRoot.CanCollide = false
            end)
        end
    else
        if Combat.Utils.m_round(eRoot.Size.X) ~= 2 then
            pcall(function()
                eRoot.Size = Combat.Utils.v3(2, 2, 1)
                eRoot.Transparency = 1
                eRoot.Material = Enum.Material.Plastic
                eRoot.Massless = false
                eRoot.CanCollide = false
            end)
        end
    end
end

function Combat.StartAutoAttackLoop()
    task.spawn(function()
        while task.wait(0.15) do
            if not getgenv().PINATHUB_RUNNING then break end
            if not Combat.Config.Current.AutoAttack then continue end
            local myChar = LocalPlayer.Character
            local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
            local myHum = myChar and myChar:FindFirstChild("Humanoid")
            if not myRoot or not myHum or myHum.Health <= 0 then continue end
            local myTeam = LocalPlayer.Team and LocalPlayer.Team.Name:lower() or ""
            if not myTeam:find("killer") then continue end
            local isCarrying = Combat.Utils.GetGameValue(myChar, "Carrying") or Combat.Utils.GetGameValue(myChar, "IsCarrying")
            local isStunned = Combat.Utils.GetGameValue(myChar, "Stunned")
            if isCarrying or isStunned then continue end
            local targetFound = false
            local players = Players:GetPlayers()
            for i = 1, #players do
                local p = players[i]
                if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    local enemyTeam = p.Team and p.Team.Name:lower() or ""
                    if not enemyTeam:find("killer") then
                        local enemyChar = p.Character
                        local enemyHum = enemyChar:FindFirstChild("Humanoid")
                        if enemyHum and enemyHum.Health > 0 then
                            local isKnocked = Combat.Utils.GetGameValue(enemyChar, "Knocked")
                            local isHooked = Combat.Utils.GetGameValue(enemyChar, "IsHooked")
                            if not isKnocked and not isHooked then
                                local dist = (enemyChar.HumanoidRootPart.Position - myRoot.Position).Magnitude
                                local isEnemyRunning = enemyHum.MoveDirection.Magnitude > 0
                                local effectiveRange = isEnemyRunning and (Combat.Config.Current.AttackRange + 3) or Combat.Config.Current.AttackRange
                                if dist <= effectiveRange then targetFound = true; break end
                            end
                        end
                    end
                end
            end
            local now = os.clock()
            if targetFound and (now - Combat.lastAttackStrike > 0.6) then
                Combat.lastAttackStrike = now
                if not Combat.SearchedAttackRemote then
                    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                    local attacks = remotes and (remotes:FindFirstChild("Attacks") or remotes:FindFirstChild("attacks") or remotes:FindFirstChild("Attack"))
                    if attacks then Combat.CachedBasicAttack = attacks:FindFirstChild("BasicAttack") or attacks:FindFirstChild("basicattack") end
                    Combat.SearchedAttackRemote = true
                end
                if Combat.CachedBasicAttack then
                    Combat.CachedBasicAttack:FireServer(false)
                    task.wait(0.05)
                    Combat.CachedBasicAttack:FireServer(true)
                end
            end
        end
    end)
end

return Combat
