-- =======================================================
-- PINATHUB - MISC MODULE
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

local function GetSkillCheck()
    if not Misc.PlayerGui then Misc.PlayerGui = LocalPlayer:WaitForChild("PlayerGui") end
    for _, guiName in ipairs({"SkillCheckPromptGui", "SkillCheckPromptGui-con"}) do
        local gui = Misc.PlayerGui:FindFirstChild(guiName, true)
        if gui then
            local check = gui:FindFirstChild("Check", true)
            if check and check.Visible then
                local line = check:FindFirstChild("Line", true)
                local goal = check:FindFirstChild("Goal", true)
                if line and goal then return line, goal end
            end
        end
    end
    return nil, nil
end

local function PressSkill()
    if tick() - Misc.LastTriggerTick < 0.08 then return end
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
            pcall(function() if firesignal and btn.MouseButton1Click then firesignal(btn.MouseButton1Click) end end)
        end
    else
        pcall(function()
            Misc.VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
            task.wait()
            Misc.VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
        end)
    end
end

function Misc.StartAutoGenerator()
    if Misc.GenConnection then Misc.GenConnection:Disconnect() end
    Misc.GenConnection = RunService.Heartbeat:Connect(function()
        if not Misc.Config.Current.AutoGenerator then return end
        local line, goal = GetSkillCheck()
        if not (line and goal) then return end
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
        if startPos > endPos then inside = (lr >= startPos or lr <= endPos)
        else inside = (lr >= startPos and lr <=
