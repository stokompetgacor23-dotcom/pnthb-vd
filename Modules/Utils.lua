-- =======================================================
-- PINATHUB - UTILS MODULE
-- =======================================================

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Stats = game:GetService("Stats")

local Utils = {}

function Utils.GetGameValue(obj, name)
    if typeof(obj) ~= "Instance" then return nil end
    local attr = obj:GetAttribute(name)
    if attr ~= nil then return attr end
    local child = obj:FindFirstChild(name)
    if child and child:IsA("ValueBase") then return child.Value end
    return nil
end

function Utils.IsStatusActive(val)
    return val == true or (type(val) == "number" and val > 0)
end

Utils.v3 = Vector3.new
Utils.v2 = Vector2.new
Utils.cnew = CFrame.new
Utils.cangles = CFrame.Angles
Utils.t_insert = table.insert
Utils.t_remove = table.remove
Utils.m_floor = math.floor
Utils.m_round = math.round
Utils.s_format = string.format

local aimRayParams = RaycastParams.new()
aimRayParams.FilterType = Enum.RaycastFilterType.Blacklist

function Utils.IsVisible(targetPart, wallCheck)
    if not wallCheck then return true end
    local camera = workspace.CurrentCamera
    local origin = camera.CFrame.Position
    local direction = (targetPart.Position - origin)
    local myChar = LocalPlayer.Character
    local filterList = {}
    if camera then table.insert(filterList, camera) end
    if myChar then table.insert(filterList, myChar) end
    aimRayParams.FilterDescendantsInstances = filterList
    local result = workspace:Raycast(origin, direction, aimRayParams)
    if result then return result.Instance:IsDescendantOf(targetPart.Parent) end
    return true
end

function Utils.CreateBillboardTag(text, color, size, textSize)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "TagESP"
    billboard.AlwaysOnTop = true
    billboard.Size = size or UDim2.new(0, 150, 0, 40)
    billboard.LightInfluence = 0
    billboard.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = color
    label.Font = Enum.Font.GothamBold
    label.TextSize = textSize or 12
    label.TextWrapped = true
    label.RichText = true
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1.2
    stroke.Color = Color3.new(0, 0, 0)
    stroke.Transparency = 0.2
    stroke.Parent = label
    label.Parent = billboard
    return billboard
end

function Utils.ApplyHighlight(object, color)
    local h = object:FindFirstChild("H")
    if not h then
        h = Instance.new("Highlight")
        h.Name = "H"
        h.Adornee = object
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.FillTransparency = 0.82
        h.OutlineTransparency = 0.03
        h.LineThickness = 2
        h.Parent = object
    end
    if h.FillColor ~= color then
        h.FillColor = color
        h.OutlineColor = color:Lerp(Color3.new(1, 1, 1), 0.15)
    end
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local root = object:FindFirstChild("HumanoidRootPart") or object.PrimaryPart
    if root and myRoot then
        local dist = (root.Position - myRoot.Position).Magnitude
        if dist > 120 then
            h.FillTransparency = 0.92
            h.OutlineTransparency = 0
        elseif dist > 70 then
            h.FillTransparency = 0.88
            h.OutlineTransparency = 0.02
        else
            h.FillTransparency = 0.82
            h.OutlineTransparency = 0.05
        end
    end
    if not h.Enabled then h.Enabled = true end
end

function Utils.RemoveHighlight(object)
    if object then
        local h = object:FindFirstChild("H")
        if h then h:Destroy() end
    end
end

function Utils.GetPing()
    local ping = 0.09
    pcall(function()
        ping = Stats.Network.ServerStatsItem["Data Ping"]:GetValue() / 1000
    end)
    return math.clamp(ping, 0.04, 0.22)
end

function Utils.ForceUnstuck()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not (char and hum and root) then return end
    for _, track in ipairs(hum:GetPlayingAnimationTracks()) do
        local anim = track.Animation
        local name = ((anim and anim.Name) or ""):lower()
        if name:find("repair") or name:find("generator") or name:find("fix") or name:find("interaction") then
            pcall(function() track:Stop(0) end)
        end
    end
    for _, v in ipairs({"Repairing", "IsRepairing", "Interacting", "Busy", "Action", "Using"}) do
        pcall(function()
            if char:GetAttribute(v) ~= nil then char:SetAttribute(v, false) end
            local obj = char:FindFirstChild(v)
            if obj and obj:IsA("ValueBase") then
                if typeof(obj.Value) == "boolean" then obj.Value = false
                elseif typeof(obj.Value) == "number" then obj.Value = 0 end
            end
        end)
    end
    root.Anchored = false
    hum.PlatformStand = false
    hum.AutoRotate = true
    hum.Sit = false
    hum:ChangeState(Enum.HumanoidStateType.Running)
end

return Utils
