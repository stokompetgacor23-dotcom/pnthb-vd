-- =======================================================
-- PINATHUB - MISC MODULE (FIXED - NO NIL RETURN)
-- =======================================================
-- Author: @viunze on tiktok
-- =======================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local LocalPlayer = Players.LocalPlayer

local Misc = {}

Misc.Utils = nil
Misc.Config = nil
Misc.ESP = nil
Misc.WindUI = nil
Misc.VirtualInputManager = nil
Misc.UserInputService = nil
Misc.ReplicatedStorage = nil
Misc.Stats = nil
Misc.PathfindingService = nil
Misc.TargetGui = nil

Misc.GenConnection = nil
Misc.LastSkillHit = 0
Misc.LastGoalRotation = 0
Misc.LastTriggerTick = 0
Misc.SearchedHBRemotes = false
Misc.CachedHBRemotes = {}
Misc.CachedHealEvent = nil
Misc.SearchHealRemote = false
Misc.PlayerGui = nil

-- =========================================================
-- SKILL CHECK GETTER
-- =========================================================
local function GetSkillCheck()
    if not Misc.PlayerGui then 
        Misc.PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
    end
    for _, guiName in ipairs({"SkillCheckPromptGui", "SkillCheckPromptGui-con"}) do
        local gui = Misc.PlayerGui:FindFirstChild(guiName, true)
        if gui then
            local check = gui:FindFirstChild("Check", true)
            if check and check.Visible then
                local line = check:FindFirstChild("Line", true)
                local goal = check:FindFirstChild("Goal", true)
                if line and goal then 
                    return line, goal 
                end
            end
        end
    end
    return nil, nil
end

-- =========================================================
-- PRESS SKILL (PC + MOBILE)
-- =========================================================
local function PressSkill()
    if tick() - Misc.LastTriggerTick < 0.08 then 
        return 
    end
    Misc.LastTriggerTick = tick()
    
    local IsMobile = Misc.UserInputService.TouchEnabled and not Misc.UserInputService.KeyboardEnabled
    
    if IsMobile then
        local btn = Misc.PlayerGui:FindFirstChild("check", true)
        if btn and btn:IsA("GuiObject") then
            local pos = btn.AbsolutePosition
            local size = btn.AbsoluteSize
            local inset = GuiService:GetGuiInset()
            local x = pos.X + (size.X / 2) + inset.X
            local y = pos.Y + (size.Y / 2) + inset.Y
            pcall(function()
                Misc.VirtualInputManager:SendTouchEvent(8822, Enum.UserInputState.Begin.Value, x, y)
                task.wait()
                Misc.VirtualInputManager:SendTouchEvent(8822, Enum.UserInputState.End.Value, x, y)
            end)
            pcall(function() 
                if firesignal and btn.MouseButton1Click then 
                    firesignal(btn.MouseButton1Click) 
                end 
            end)
        end
    else
        pcall(function()
            Misc.VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
            task.wait()
            Misc.VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
        end)
    end
end

-- =========================================================
-- AUTO GENERATOR
-- =========================================================
function Misc.StartAutoGenerator()
    if Misc.GenConnection then 
        Misc.GenConnection:Disconnect() 
    end
    
    Misc.GenConnection = RunService.Heartbeat:Connect(function()
        if not Misc.Config.Current.AutoGenerator then 
            return 
        end
        
        local line, goal = GetSkillCheck()
        if not (line and goal) then 
            return 
        end
        
        local lr = line.Rotation % 360
        local gr = goal.Rotation % 360
        local goalVelocity = math.abs(gr - Misc.LastGoalRotation)
        Misc.LastGoalRotation = gr
        local dynamicOffset = math.clamp(goalVelocity * 0.35, 0, 8)
        
        local startPos, endPos
        if Misc.Config.Current.AutoGeneratorMode == "Neutral" then
            startPos = (gr + 96 - dynamicOffset) % 360
            endPos = (gr + 122 + dynamicOffset) % 360
        else
            startPos = (gr + (Misc.Config.Current.GeneratorPerfectOffsetStart or 102) - dynamicOffset) % 360
            endPos = (gr + (Misc.Config.Current.GeneratorPerfectOffsetEnd or 108) + dynamicOffset) % 360
        end
        
        local inside = false
        if startPos > endPos then
            inside = (lr >= startPos or lr <= endPos)
        else
            inside = (lr >= startPos and lr <= endPos)
        end
        
        if inside then
            Misc.LastSkillHit = tick()
            PressSkill()
        end
    end)
end

-- =========================================================
-- ANTI STUCK THREAD
-- =========================================================
function Misc.StartAntiStuckThread()
    task.spawn(function()
        while task.wait(0.25) do
            if not Misc.Config.Current.AutoGenerator then 
                continue 
            end
            local line = GetSkillCheck()
            if not line and tick() - Misc.LastSkillHit > 1.1 then
                pcall(function() 
                    Misc.Utils.ForceUnstuck() 
                end)
            end
        end
    end)
end

-- =========================================================
-- TRIGGER ANTI STUCK (Manual)
-- =========================================================
function Misc.TriggerAntiStuck()
    pcall(function()
        local char = workspace:FindFirstChild(LocalPlayer.Name) or LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local cam = workspace.CurrentCamera
        
        pcall(function()
            local remotes = Misc.ReplicatedStorage:FindFirstChild("Remotes")
            if not remotes then return end
            local healing = remotes:FindFirstChild("Healing")
            local reset = healing and healing:FindFirstChild("Reset")
            if reset then 
                reset:FireServer() 
            end
        end)
        
        if hum and root then
            root.Anchored = false
            hum.PlatformStand = false
            hum.AutoRotate = true
            hum.Sit = false
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            
            hum.WalkSpeed = Misc.Config.Current.SpeedBoost 
                and (17 + (17 * ((tonumber(Misc.Config.Current.BoostSpeed) or 0) / 100))) 
                or 17
            
            for _, track in ipairs(hum:GetPlayingAnimationTracks()) do
                pcall(function() track:Stop(0) end)
            end
            
            local badStates = {"Stunned", "IsStunned", "Healing", "IsHealing", 
                               "Repairing", "IsRepairing", "Interacting", "Attacking", 
                               "Using", "Busy", "Action"}
            for _, v in ipairs(badStates) do
                if char:GetAttribute(v) ~= nil then 
                    char:SetAttribute(v, false) 
                end
                local obj = char:FindFirstChild(v)
                if obj and obj:IsA("ValueBase") then
                    pcall(function()
                        if typeof(obj.Value) == "boolean" then 
                            obj.Value = false
                        elseif typeof(obj.Value) == "number" then 
                            obj.Value = 0 
                        end
                    end)
                end
            end
            
            local map = workspace:FindFirstChild("Map")
            if map then
                local genFolder = map:FindFirstChild("new Generators") or map:FindFirstChild("Generators")
                if genFolder then
                    local nearestGen, nearestDist
                    for _, gen in ipairs(genFolder:GetChildren()) do
                        local part = gen:FindFirstChildWhichIsA("BasePart", true)
                        if part then
                            local dist = (root.Position - part.Position).Magnitude
                            if not nearestDist or dist < nearestDist then
                                nearestDist = dist
                                nearestGen = part
                            end
                        end
                    end
                    if nearestGen and nearestDist <= 15 then
                        local dir = (root.Position - nearestGen.Position).Unit
                        if dir.Magnitude <= 0 then 
                            dir = root.CFrame.LookVector 
                        end
                        local escapePos = root.Position + (dir * 20)
                        root.CFrame = CFrame.new(escapePos, escapePos + root.CFrame.LookVector)
                    end
                end
            end
            
            task.wait()
            hum:ChangeState(Enum.HumanoidStateType.Running)
            hum.Jump = true
            
            if cam and cam.CameraType ~= Enum.CameraType.Custom then
                cam.CameraType = Enum.CameraType.Custom
                cam.CameraSubject = hum
            end
        end
        
        if Misc.WindUI then
            Misc.WindUI:Notify({ 
                Title = "Anti-Stuck Triggered", 
                Content = "Character released from stuck state!", 
                Icon = "lucide:unlock" 
            })
        end
    end)
end

-- =========================================================
-- AUTO FARM AI (BRAIN THREAD)
-- =========================================================
function Misc.StartAutoFarmAI()
    getgenv().AIFinalTarget = nil
    
    -- BRAIN THREAD (Perencanaan rute)
    task.spawn(function()
        while task.wait(0.4) do
            if not getgenv().PINATHUB_RUNNING then break end
            if not Misc.Config.Current.AutoFarmBot then 
                getgenv().CachedWaypoints = nil
                getgenv().AIFinalTarget = nil
                continue 
            end
            
            pcall(function()
                local myChar = LocalPlayer.Character
                local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
                local myHum = myChar and myChar:FindFirstChild("Humanoid")
                
                if not myRoot or not myHum or myHum.Health <= 0 then return end
                
                local team = LocalPlayer.Team and LocalPlayer.Team.Name:lower() or ""
                if team:find("killer") then return end
                
                local function IsImmobilized()
                    if Misc.Utils.GetGameValue(myChar, "IsHooked") or myChar:GetAttribute("IsHooked") then return true end
                    if Misc.Utils.GetGameValue(myChar, "Carried") or Misc.Utils.GetGameValue(myChar, "Grabbed") or myChar:GetAttribute("Carried") then return true end
                    return false
                end
                
                if IsImmobilized() then 
                    getgenv().CachedWaypoints = nil
                    getgenv().AIFinalTarget = nil
                    return 
                end
                
                local myPos = myRoot.Position
                local closestKillerDist = 999
                local killerRoot = nil
                local injuredTeammate = nil
                local shortestMateDist = 90
                
                local players = Players:GetPlayers()
                for _, p in ipairs(players) do
                    if p ~= LocalPlayer and p.Character then
                        local eRoot = p.Character:FindFirstChild("HumanoidRootPart")
                        if eRoot then
                            local eTeam = p.Team and p.Team.Name:lower() or ""
                            local dist = (eRoot.Position - myPos).Magnitude
                            
                            if eTeam:find("killer") then
                                if dist < closestKillerDist then 
                                    closestKillerDist = dist
                                    killerRoot = eRoot 
                                end
                            else
                                local isKnocked = Misc.Utils.GetGameValue(p.Character, "Knocked")
                                local eHum = p.Character:FindFirstChild("Humanoid")
                                local isInjured = eHum and eHum.Health < eHum.MaxHealth
                                
                                if (isKnocked or isInjured) and dist < shortestMateDist then
                                    shortestMateDist = dist
                                    injuredTeammate = p.Character
                                end
                            end
                        end
                    end
                end
                
                local completedGens = 0
                local shortestGenDist = 9999
                local bestGenTarget = nil
                
                if Misc.ESP and Misc.ESP.CachedMapObjects and Misc.ESP.CachedMapObjects.Generators then
                    for _, gen in ipairs(Misc.ESP.CachedMapObjects.Generators) do
                        local progress = Misc.Utils.GetGameValue(gen, "RepairProgress") or Misc.Utils.GetGameValue(gen, "Progress") or 0
                        if progress >= 100 then
                            completedGens = completedGens + 1
                        else
                            local genPos = gen:GetPivot().Position
                            local dist = (genPos - myPos).Magnitude
                            if dist < shortestGenDist then
                                shortestGenDist = dist
                                bestGenTarget = genPos
                            end
                        end
                    end
                end
                
                local targetPos = nil
                local actionState = "Idle"
                
                -- PRIORITAS 1: Lari dari Killer
                if closestKillerDist <= 70 and killerRoot then
                    local maxDistFromKiller = 0
                    local bestEscapeTarget = nil
                    local killerPos = killerRoot.Position
                    
                    local function checkSafeSpot(spot)
                        local spotPos = spot:GetPivot().Position
                        local distFromKiller = (spotPos - killerPos).Magnitude
                        if distFromKiller > maxDistFromKiller then
                            maxDistFromKiller = distFromKiller
                            bestEscapeTarget = spotPos
                        end
                    end
                    
                    if Misc.ESP and Misc.ESP.CachedMapObjects then
                        if Misc.ESP.CachedMapObjects.Generators then
                            for _, g in ipairs(Misc.ESP.CachedMapObjects.Generators) do 
                                checkSafeSpot(g) 
                            end
                        end
                        if Misc.ESP.CachedMapObjects.Gates then
                            for _, g in ipairs(Misc.ESP.CachedMapObjects.Gates) do 
                                checkSafeSpot(g) 
                            end
                        end
                    end
                    
                    if bestEscapeTarget then
                        targetPos = bestEscapeTarget
                    else
                        local runDir = (myPos - killerPos).Unit
                        targetPos = myPos + (runDir * 50)
                    end
                    actionState = "Evading"
                    
                -- PRIORITAS 2: Heal Teman
                elseif injuredTeammate then
                    targetPos = injuredTeammate.HumanoidRootPart.Position
                    actionState = "Healing"
                    
                    if shortestMateDist <= 12 then
                        if not Misc.SearchHealRemote then
                            local remotes = Misc.ReplicatedStorage:FindFirstChild("Remotes")
                            Misc.CachedHealEvent = remotes and (remotes:FindFirstChild("HealEvent", true) 
                                or remotes:FindFirstChild("RequestHeal", true) 
                                or remotes:FindFirstChild("ReviveEvent", true))
                            Misc.SearchHealRemote = true
                        end
                        
                        if Misc.CachedHealEvent then
                            pcall(function() 
                                Misc.CachedHealEvent:FireServer(injuredTeammate, 100) 
                            end)
                            pcall(function() 
                                Misc.CachedHealEvent:FireServer(injuredTeammate, true) 
                            end)
                        end
                        
                        getgenv().CachedWaypoints = nil
                        getgenv().AIFinalTarget = nil
                        if (myHum.WalkToPoint - myPos).Magnitude > 1 then 
                            myHum:MoveTo(myPos) 
                        end
                        return
                    end
                    
                -- PRIORITAS 3: Perbaiki Generator
                elseif completedGens < 5 and bestGenTarget then
                    targetPos = bestGenTarget
                    actionState = "Repairing"
                    
                -- PRIORITAS 4: Lari ke Gerbang
                elseif completedGens >= 5 and Misc.ESP and Misc.ESP.CachedMapObjects and Misc.ESP.CachedMapObjects.Gates then
                    local shortestGate = 9999
                    for _, gate in ipairs(Misc.ESP.CachedMapObjects.Gates) do
                        local gatePos = gate:GetPivot().Position
                        local dist = (gatePos - myPos).Magnitude
                        if dist < shortestGate then
                            shortestGate = dist
                            targetPos = gatePos
                        end
                    end
                    actionState = "Escaping"
                end
                
                -- Notifikasi perubahan state AI
                if getgenv().LastAIState ~= actionState then
                    getgenv().LastAIState = actionState
                    if actionState ~= "Idle" and Misc.WindUI then
                        local notifIcons = {
                            Evading = "lucide:footprints",
                            Healing = "lucide:heart-handshake",
                            Repairing = "lucide:wrench",
                            Escaping = "lucide:door-open",
                            Idle = "lucide:coffee"
                        }
                        Misc.WindUI:Notify({
                            Title = "AI State: " .. string.upper(actionState),
                            Content = "Switching AI priority to: " .. actionState,
                            Icon = notifIcons[actionState] or "lucide:bot",
                            Duration = 3
                        })
                    end
                end
                
                getgenv().AIFinalTarget = targetPos
                
                -- Kalkulasi rute (async)
                if targetPos then
                    local now = os.clock()
                    local lastPathCalc = getgenv().LastPathCalc or 0
                    local lastTargetPos = getgenv().LastTargetPos or Misc.Utils.v3()
                    
                    if (targetPos - lastTargetPos).Magnitude > 5 or (now - lastPathCalc > 1.5) then
                        getgenv().LastPathCalc = now
                        getgenv().LastTargetPos = targetPos
                        
                        task.spawn(function()
                            pcall(function()
                                local path = Misc.PathfindingService:CreatePath({ 
                                    AgentRadius = 2.5,  
                                    AgentHeight = 5, 
                                    AgentCanJump = true,
                                    WaypointSpacing = 4 
                                })
                                path:ComputeAsync(myPos, targetPos)
                                
                                if path.Status == Enum.PathStatus.Success then
                                    getgenv().CachedWaypoints = path:GetWaypoints()
                                    getgenv().CurrentWaypointIdx = 2 
                                else
                                    getgenv().CachedWaypoints = nil
                                end
                            end)
                        end)
                    end
                else
                    getgenv().CachedWaypoints = nil
                    if (myHum.WalkToPoint - myPos).Magnitude > 1 then 
                        myHum:MoveTo(myPos) 
                    end
                end
            end)
        end
    end)
    
    -- MOVEMENT THREAD (Eksekusi pergerakan)
    task.spawn(function()
        while task.wait(0.05) do
            if not getgenv().PINATHUB_RUNNING then break end
            if not Misc.Config.Current.AutoFarmBot then
                continue
            end
            
            pcall(function()
                local myChar = LocalPlayer.Character
                local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
                local myHum = myChar and myChar:FindFirstChild("Humanoid")
                if not myRoot or not myHum or myHum.Health <= 0 then return end
                
                local waypoints = getgenv().CachedWaypoints
                local idx = getgenv().CurrentWaypointIdx
                local myPos = myRoot.Position
                
                if waypoints and idx and idx <= #waypoints then
                    local nextPoint = waypoints[idx]
                    local distToWaypoint = (Misc.Utils.v3(nextPoint.Position.X, myPos.Y, nextPoint.Position.Z) - myPos).Magnitude
                    
                    if distToWaypoint < 4.5 then
                        getgenv().CurrentWaypointIdx = idx + 1
                        if getgenv().CurrentWaypointIdx <= #waypoints then
                            nextPoint = waypoints[getgenv().CurrentWaypointIdx]
                        end
                    end
                    
                    if nextPoint then
                        myHum:MoveTo(nextPoint.Position)
                        if nextPoint.Action == Enum.PathWaypointAction.Jump then 
                            myHum.Jump = true 
                        end
                    end
                elseif getgenv().AIFinalTarget then
                    myHum:MoveTo(getgenv().AIFinalTarget)
                end
                
                -- Anti-stuck system
                local nowTime = os.clock()
                local lastBotPos = getgenv().LastBotPos or myPos
                local lastBotTime = getgenv().LastBotTime or nowTime
                
                if getgenv().AIFinalTarget then
                    if (myPos - lastBotPos).Magnitude < 0.5 then
                        if nowTime - lastBotTime > 1.0 then
                            myHum.Jump = true
                            myRoot.CFrame = myRoot.CFrame * CFrame.new(math.random(-2, 2), 0, math.random(1, 3))
                            getgenv().LastBotTime = nowTime + 0.5 
                        end
                    else
                        getgenv().LastBotPos = myPos
                        getgenv().LastBotTime = nowTime
                    end
                end
            end)
        end
    end)
end

-- =========================================================
-- NAMECALL HOOK (AMAN - SETIAP CABANG ADA RETURN)
-- =========================================================
function Misc.SetupNamecallHook()
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        
        -- SAFETY: Pastikan self dan method valid
        if not self or type(method) ~= "string" then
            return oldNamecall(self, ...)
        end
        
        -- =====================================================
        -- HANYA PROSES METHOD FireServer
        -- =====================================================
        if method == "FireServer" and typeof(self) == "Instance" then
            local n = tostring(self):lower()
            
            -- SELF HEAL
            if Misc.Config.Current.SelfHeal and n:find("healevent") then
                local char = LocalPlayer.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if root and hum and hum.Health > 0 then
                    local newArgs = table.clone(args)
                    newArgs[1] = root
                    if newArgs[2] == nil then newArgs[2] = true end
                    return oldNamecall(self, unpack(newArgs))
                end
                -- Jika kondisi tidak terpenuhi, lanjut ke return default di bawah
            end
            
            -- DOUBLE DAMAGE GENERATOR
            if Misc.Config.Current.DoubleDamageGen and n:find("breakgenevent") then
                local team = LocalPlayer.Team
                if team and team.Name:lower():find("killer") then
                    local saved = table.clone(args)
                    local result = oldNamecall(self, unpack(saved))
                    task.spawn(function()
                        for i = 1, 4 do
                            task.wait(0.08)
                            pcall(function() 
                                oldNamecall(self, unpack(saved)) 
                            end)
                        end
                        local char = LocalPlayer.Character
                        local hum = char and char:FindFirstChildOfClass("Humanoid")
                        local root = char and char:FindFirstChild("HumanoidRootPart")
                        if hum and root then
                            root.Anchored = false
                            hum.PlatformStand = false
                            hum.AutoRotate = true
                            hum.Sit = false
                            hum:ChangeState(Enum.HumanoidStateType.Running)
                        end
                    end)
                    return result
                end
                -- Jika kondisi tidak terpenuhi, lanjut ke return default di bawah
            end
            
            -- SILENT ACTIONS (Block noise notifications)
            if Misc.Config.Current.SilentActions then
                local blockKeywords = {"noise", "scream", "vaultalert", "spotted", "alert", 
                                       "ping", "loud", "notify", "notification", "sound"}
                local firstArg = typeof(args[1]) == "string" and args[1]:lower() or ""
                for _, w in ipairs(blockKeywords) do
                    if n:find(w) or firstArg:find(w) then
                        return  -- BLOCK, jangan panggil oldNamecall
                    end
                end
            end
            
            -- ANTI LOGGER
            if Misc.Config.Current.AntiLogger then
                local blockLogger = {"log", "error", "report", "anticheat", "ban"}
                for _, w in ipairs(blockLogger) do
                    if n:find(w) then
                        return  -- BLOCK
                    end
                end
            end
            
            -- ANTI FALL DAMAGE
            if Misc.Config.Current.AntiFallDamage then
                local blockFall = {"falldamage", "fall", "ragdollfall"}
                for _, w in ipairs(blockFall) do
                    if n:find(w) then
                        return  -- BLOCK
                    end
                end
            end
            
            -- SILENT AIM PISTOL
            if Misc.Config.Current.SilentAimPistol and n:find("fire") then
                local team = LocalPlayer.Team
                local survivor = not (team and team.Name:lower():find("killer"))
                if survivor then
                    local char = LocalPlayer.Character
                    local myRoot = char and char:FindFirstChild("HumanoidRootPart")
                    local tool = char and char:FindFirstChildOfClass("Tool")
                    if myRoot and tool then
                        local firing = Misc.UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
                                    or (Misc.UserInputService.TouchEnabled and getgenv().isMobileFiring)
                        if firing then
                            local combat = require(script.Parent.Combat)
                            local target = combat.GetClosestSilentTarget()
                            if target and target.Parent then
                                local vel = target.AssemblyLinearVelocity or Vector3.zero
                                if vel.Magnitude > 45 then vel = vel.Unit * 45 end
                                local ping = 0.08
                                pcall(function() 
                                    ping = Misc.Stats.Network.ServerStatsItem["Data Ping"]:GetValue() / 1000 
                                end)
                                ping = math.clamp(ping, 0.05, 0.18)
                                local predicted = target.Position + (vel * (0.11 + ping))
                                local origin = workspace.CurrentCamera.CFrame.Position
                                local dir = (predicted - origin).Unit * 1000
                                for i, v in ipairs(args) do
                                    if typeof(v) == "Vector3" then
                                        args[i] = dir
                                        break
                                    end
                                end
                                task.spawn(function()
                                    pcall(function()
                                        workspace.CurrentCamera.CFrame = CFrame.lookAt(
                                            workspace.CurrentCamera.CFrame.Position, 
                                            predicted
                                        )
                                    end)
                                end)
                                return oldNamecall(self, unpack(args))
                            end
                        end
                    end
                end
                -- Jika kondisi tidak terpenuhi, lanjut ke return default di bawah
            end
        end
        
        -- =====================================================
        -- WAJIB: RETURN DEFAULT UNTUK SEMUA METHOD (TERMASUK FIRESERVER YANG TIDAK DIHANDLE)
        -- =====================================================
        return oldNamecall(self, ...)
    end)
    
    print("[PINATHUB] Namecall hook installed safely")
end

return Misc
