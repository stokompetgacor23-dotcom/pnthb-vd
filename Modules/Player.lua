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

return Player
