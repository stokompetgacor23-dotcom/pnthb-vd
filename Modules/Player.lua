-- =======================================================
-- PINATHUB - PLAYER MODULE
-- =======================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local Player = {}

Player.Utils = nil
Player.Config = nil
Player.CurrentMoonwalkYaw = 0
Player.CurrentMoonwalkSway = 0
Player.fppHideConn = nil
Player.isFPP = false

function Player.ApplySpeedBoost(hum)
    if not hum then return end
    if Player.Config.Current.SpeedBoost then
        local baseSpeed = 17
        local percentValue = tonumber(Player.Config.Current.BoostSpeed) or 0
        hum.WalkSpeed = baseSpeed + (baseSpeed * (percentValue / 100))
    else
        hum.WalkSpeed = 17
    end
end

function Player.UpdateMoonwalk(deltaTime, myRoot, myHum, camera)
    if not Player.Config.Current.MoonwalkEnabled then
        if myHum and not myHum.AutoRotate then myHum.AutoRotate = true end
        return
    end
    if myHum then
        if myHum.AutoRotate then myHum.AutoRotate = false end
        local look = camera.CFrame.LookVector
        local targetYaw = math.deg(math.atan2(look.X, look.Z)) + 180
        local diff = ((targetYaw - (Player.CurrentMoonwalkYaw or 0) + 180) % 360) - 180
        Player.CurrentMoonwalkYaw = (Player.CurrentMoonwalkYaw or 0) + (diff * (0.22 * math.clamp(deltaTime * 60, 0, 3)))
        local moving = myHum.MoveDirection.Magnitude > 0.01
        local sway = 0
        if moving then sway = math.sin(time() * (Player.Config.Current.MoonwalkZigzagSpeed or 11)) * 48 end
        Player.CurrentMoonwalkSway = (Player.CurrentMoonwalkSway or 0) + (sway - (Player.CurrentMoonwalkSway or 0)) * 0.38
        myRoot.CFrame = CFrame.new(myRoot.Position) * CFrame.Angles(0, math.rad(Player.CurrentMoonwalkYaw + Player.CurrentMoonwalkSway), 0)
        if moving then myHum:Move(myHum.MoveDirection * (Player.Config.Current.MoonwalkBoostPower or 1.08), false) end
    end
end

function Player.SwitchCameraMode(toFPP)
    if toFPP then
        LocalPlayer.CameraMode = Enum.CameraMode.LockFirstPerson
        if not Player.fppHideConn then
            Player.fppHideConn = RunService.RenderStepped:Connect(function()
                local char = LocalPlayer.Character
                if char then
                    local head = char:FindFirstChild("Head")
                    if head then head.LocalTransparencyModifier = 1 end
                    for _, obj in ipairs(char:GetChildren()) do
                        if obj:IsA("Accessory") then
                            local handle = obj:FindFirstChild("Handle")
                            if handle then handle.LocalTransparencyModifier = 1 end
                        end
                    end
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    local hum = char:FindFirstChild("Humanoid")
                    local cam = workspace.CurrentCamera
                    if hrp and hum and cam then
                        hum.AutoRotate = false
                        local lookY = select(2, cam.CFrame:ToEulerAnglesYXZ())
                        local currentLook = hrp.Orientation.Y
                        local targetLook = math.deg(lookY)
                        if math.abs(currentLook - targetLook) > 1 then
                            hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, lookY, 0)
                        end
                    end
                end
            end)
        end
    else
        LocalPlayer.CameraMode = Enum.CameraMode.Classic
        LocalPlayer.CameraMaxZoomDistance = 128
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChild("Humanoid")
        if hum then hum.AutoRotate = true end
        if Player.fppHideConn then Player.fppHideConn:Disconnect(); Player.fppHideConn = nil end
        if char then
            local head = char:FindFirstChild("Head")
            if head then head.LocalTransparencyModifier = 0 end
            for _, obj in ipairs(char:GetChildren()) do
                if obj:IsA("Accessory") then
                    local handle = obj:FindFirstChild("Handle")
                    if handle then handle.LocalTransparencyModifier = 0 end
                end
            end
        end
    end
    Player.isFPP = toFPP
end

function Player.ToggleFPP()
    Player.SwitchCameraMode(not Player.isFPP)
    Player.Config.Set("FPPEnabled", Player.isFPP)
end

function Player.ResetScope()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChild("Humanoid")
    if hum then
        for _, track in ipairs(hum:GetPlayingAnimationTracks()) do
            local anim = track.Animation
            local name = (anim and anim.Name:lower()) or ""
            if name:find("aim") or name:find("scope") or name:find("gun") then
                pcall(function() track:Stop(0) end)
            end
        end
    end
    workspace.CurrentCamera.FieldOfView = 70
end

-- =========================================================
-- ALLOW JUMP (Force Jump - Berdasarkan Script yang Terbukti)
-- =========================================================

Player.allowJumpEnabled = false
Player.lastJumpTime = 0
Player.jumpCooldown = 2
Player.jumpRequestConn = nil
Player.inputBeganConn = nil
Player.heartbeatConn = nil
Player.jumpPowerConn = nil

function Player.EnableAllowJump()
    if Player.allowJumpEnabled then return end
    
    local char = LocalPlayer.Character
    if not char then
        warn("[PINATHUB] Cannot enable jump: Character not found")
        return
    end
    
    local humanoid = char:FindFirstChild("Humanoid")
    if not humanoid then
        warn("[PINATHUB] Cannot enable jump: Humanoid not found")
        return
    end
    
    Player.allowJumpEnabled = true
    
    -- Set JumpPower ke 50
    humanoid.JumpPower = 50
    
    -- Handle jump function (sama persis dengan script yang berhasil)
    local function HandleJump()
        if humanoid.FloorMaterial ~= Enum.Material.Air then
            local currentTime = os.time()
            if currentTime - Player.lastJumpTime >= Player.jumpCooldown then
                pcall(function()
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end)
                Player.lastJumpTime = currentTime
            end
        end
    end
    
    -- Listen untuk tombol Space
    Player.inputBeganConn = UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
        if input.KeyCode == Enum.KeyCode.Space and not gameProcessedEvent then
            HandleJump()
        end
    end)
    
    -- Monitor perubahan JumpPower (reset ke 50 jika diubah game)
    Player.jumpPowerConn = humanoid:GetPropertyChangedSignal("JumpPower"):Connect(function()
        if Player.allowJumpEnabled and humanoid.JumpPower == 0 then
            humanoid.JumpPower = 50
            print("[PINATHUB] Jump Power reset to 50")
        end
    end)
    
    -- Heartbeat untuk menjaga JumpPower tetap 50
    Player.heartbeatConn = game:GetService("RunService").Heartbeat:Connect(function()
        if not Player.allowJumpEnabled then return end
        
        local currentChar = LocalPlayer.Character
        if not currentChar then return end
        
        local hum = currentChar:FindFirstChild("Humanoid")
        if not hum then return end
        
        if hum.JumpPower == 0 then
            hum.JumpPower = 50
        end
    end)
    
    print("[PINATHUB] Allow Jump enabled - Press Space to jump!")
    
    if UI and UI.Window then
        UI.Window:Notify("Allow Jump", "Jumping force-enabled!", 2)
    end
end

function Player.DisableAllowJump()
    if not Player.allowJumpEnabled then return end
    Player.allowJumpEnabled = false
    
    -- Disconnect semua koneksi
    if Player.inputBeganConn then
        Player.inputBeganConn:Disconnect()
        Player.inputBeganConn = nil
    end
    
    if Player.jumpPowerConn then
        Player.jumpPowerConn:Disconnect()
        Player.jumpPowerConn = nil
    end
    
    if Player.heartbeatConn then
        Player.heartbeatConn:Disconnect()
        Player.heartbeatConn = nil
    end
    
    -- Reset JumpPower ke normal (50)
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChild("Humanoid")
        if hum and hum.JumpPower == 0 then
            hum.JumpPower = 50
        end
    end
    
    print("[PINATHUB] Allow Jump disabled")
    
    if UI and UI.Window then
        UI.Window:Notify("Allow Jump", "Jumping restored to normal", 2)
    end
end

function Player.ToggleAllowJump(state)
    if state then
        Player.EnableAllowJump()
    else
        Player.DisableAllowJump()
    end
end

return Player
