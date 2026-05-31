-- =======================================================
-- PINATHUB - ESP MODULE
-- =======================================================

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")

local ESP = {}

ESP.Utils = nil
ESP.Config = nil
ESP.WindUI = nil
ESP.TargetGui = nil

ESP.CachedMapObjects = { Generators = {}, Pallets = {}, Hooks = {}, Gates = {} }
ESP.PrevESPState = { Generator = false, Hook = false, Pallet = false, Gate = false }
ESP.ESP_PlayerCache = {}
ESP.SCPCache = {}
ESP.SCPConnection = nil
ESP.SCPFolder = nil
ESP.LastESPRefresh = 0

function ESP.InitSCPFolder()
    ESP.SCPFolder = CoreGui:FindFirstChild("PINATHUB_SCP_ESP") or Instance.new("Folder")
    ESP.SCPFolder.Name = "PINATHUB_SCP_ESP"
    ESP.SCPFolder.Parent = CoreGui
end

function ESP.UpdateMapCache()
    local map = workspace:FindFirstChild("Map")
    if not map then return end
    ESP.CachedMapObjects.Generators = {}
    ESP.CachedMapObjects.Pallets = {}
    ESP.CachedMapObjects.Hooks = {}
    ESP.CachedMapObjects.Gates = {}
    local descendants = map:GetDescendants()
    for i = 1, #descendants do
        local obj = descendants[i]
        local n = obj.Name
        if n == "Generator" then table.insert(ESP.CachedMapObjects.Generators, obj)
        elseif n == "Hook" then table.insert(ESP.CachedMapObjects.Hooks, obj)
        elseif n == "Gate" then table.insert(ESP.CachedMapObjects.Gates, obj)
        elseif n == "Pallet" or n == "Palletwrong" then table.insert(ESP.CachedMapObjects.Pallets, obj) end
        if i % 500 == 0 then task.wait() end
    end
    ESP.PrevESPState.Generator = false; ESP.PrevESPState.Hook = false
    ESP.PrevESPState.Pallet = false; ESP.PrevESPState.Gate = false
end

function ESP.RemovePlayerESP(player)
    local char = player.Character
    if char then
        ESP.Utils.RemoveHighlight(char)
        local bg = char:FindFirstChild("HumanoidRootPart") and char.HumanoidRootPart:FindFirstChild("TagESP")
        if bg then bg:Destroy() end
    end
    ESP.ESP_PlayerCache[player.UserId] = nil
end

function ESP.CreatePlayerESP(player, isKiller)
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")
    if not root or not hum or hum.Health <= 0 then ESP.RemovePlayerESP(player); return end
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    local dist = ESP.Utils.m_floor((root.Position - myRoot.Position).Magnitude)
    local color = isKiller and ESP.Config.ESP_COLORS.Killer or ESP.Config.ESP_COLORS.Survivor
    local statusText = ""
    if isKiller then
        local detectedMask = char:GetAttribute("CachedMask") or char:GetAttribute("KillerType") or char:GetAttribute("SelectedKiller")
            or ESP.Utils.GetGameValue(char, "SelectedKiller") or ESP.Utils.GetGameValue(player, "SelectedKiller")
            or ESP.Utils.GetGameValue(char, "Mask") or ESP.Utils.GetGameValue(player, "Mask") or char.Name
        if detectedMask then char:SetAttribute("CachedMask", detectedMask) end
        statusText = ESP.Config.MaskNames[detectedMask] or "KILLER"
        color = ESP.Config.MaskColors[detectedMask] or color
    else
        local hooked = ESP.Utils.IsStatusActive(ESP.Utils.GetGameValue(char, "IsHooked")) or ESP.Utils.IsStatusActive(ESP.Utils.GetGameValue(player, "IsHooked"))
        local carried = ESP.Utils.IsStatusActive(ESP.Utils.GetGameValue(char, "Carried")) or ESP.Utils.IsStatusActive(ESP.Utils.GetGameValue(char, "IsCarried"))
            or ESP.Utils.IsStatusActive(ESP.Utils.GetGameValue(char, "Grabbed")) or ESP.Utils.IsStatusActive(ESP.Utils.GetGameValue(player, "Carried"))
        local knocked = ESP.Utils.IsStatusActive(ESP.Utils.GetGameValue(char, "Knocked")) or ESP.Utils.IsStatusActive(ESP.Utils.GetGameValue(char, "IsKnocked"))
        if hooked then color = Color3.fromRGB(255, 70, 140); statusText = "HOOKED"
        elseif carried then color = Color3.fromRGB(190, 90, 255); statusText = "CARRIED"
        elseif knocked then color = Color3.fromRGB(255, 170, 0); statusText = "KNOCKED"
        elseif hum.Health < hum.MaxHealth then color = Color3.fromRGB(255, 225, 80); statusText = "INJURED"
        else statusText = nil; color = ESP.Config.ESP_COLORS.Survivor end
    end
    local bottomText
    if isKiller then bottomText = ESP.Utils.s_format('<font color="#DCDCDC">%dm</font> • <font color="#%s">[%s]</font>', dist, color:ToHex(), string.upper(statusText))
    elseif statusText then bottomText = ESP.Utils.s_format('<font color="#DCDCDC">%dm</font> • <font color="#%s">%s</font>', dist, color:ToHex(), statusText)
    else bottomText = ESP.Utils.s_format('<font color="#DCDCDC">%dm</font>', dist) end
    local finalName = ESP.Utils.s_format('<b>@%s</b>\n%s', player.Name, bottomText)
    ESP.ESP_PlayerCache[player.UserId] = { dist = dist, status = statusText }
    local showName = isKiller and ESP.Config.Current.ESP_Killer_Name or ESP.Config.Current.ESP_Survivor_Name
    local showHighlight = isKiller and ESP.Config.Current.ESP_Killer_Highlight or ESP.Config.Current.ESP_Survivor_Highlight
    if showHighlight then ESP.Utils.ApplyHighlight(char, color) else ESP.Utils.RemoveHighlight(char) end
    local bg = root:FindFirstChild("TagESP")
    if showName then
        if not bg then
            bg = Instance.new("BillboardGui")
            bg.Name = "TagESP"; bg.Parent = root; bg.Adornee = root; bg.AlwaysOnTop = true
            bg.LightInfluence = 0; bg.ResetOnSpawn = false; bg.MaxDistance = 1800
            bg.Size = UDim2.new(0, 165, 0, 34); bg.StudsOffset = ESP.Utils.v3(0, 3.8, 0)
            local lbl = Instance.new("TextLabel")
            lbl.Name = "Label"; lbl.Parent = bg; lbl.BackgroundTransparency = 1; lbl.Size = UDim2.fromScale(1, 1)
            lbl.RichText = true; lbl.TextScaled = false; lbl.TextWrapped = false; lbl.Font = Enum.Font.GothamBold
            lbl.TextSize = 8; lbl.TextStrokeTransparency = 1; lbl.TextYAlignment = Enum.TextYAlignment.Center
            lbl.TextXAlignment = Enum.TextXAlignment.Center; lbl.Text = finalName; lbl.TextColor3 = color
            local stroke = Instance.new("UIStroke"); stroke.Parent = lbl; stroke.Thickness = 1.2
            stroke.Transparency = 0.2; stroke.Color = Color3.new(0, 0, 0)
            local constraint = Instance.new("UITextSizeConstraint"); constraint.Parent = lbl
            constraint.MaxTextSize = 8; constraint.MinTextSize = 5
        else
            local lbl = bg:FindFirstChild("Label")
            if lbl then
                lbl.Text = finalName; lbl.TextColor3 = color
                if dist > 220 then bg.Size = UDim2.new(0, 105, 0, 20); bg.StudsOffset = ESP.Utils.v3(0, 1.6, 0); lbl.TextSize = 6; lbl.TextTransparency = 0.15
                elseif dist > 150 then bg.Size = UDim2.new(0, 120, 0, 22); bg.StudsOffset = ESP.Utils.v3(0, 2, 0); lbl.TextSize = 6.5; lbl.TextTransparency = 0.08
                elseif dist > 90 then bg.Size = UDim2.new(0, 140, 0, 26); bg.StudsOffset = ESP.Utils.v3(0, 2.7, 0); lbl.TextSize = 7; lbl.TextTransparency = 0
                else bg.Size = UDim2.new(0, 165, 0, 34); bg.StudsOffset = ESP.Utils.v3(0, 3.8, 0); lbl.TextSize = 8; lbl.TextTransparency = 0 end
            end
        end
    elseif bg then bg:Destroy() end
end

local GEN_COLOR_MID = Color3.fromRGB(255, 140, 0)
local GEN_COLOR_END = Color3.fromRGB(0, 255, 120)

function ESP.UpdateGeneratorProgress(generator)
    if not generator or not generator.Parent then return true end
    local percent = ESP.Utils.GetGameValue(generator, "RepairProgress") or ESP.Utils.GetGameValue(generator, "Progress") or 0
    local billboard = generator:FindFirstChild("GenBitchHook")
    if percent >= 100 or not ESP.Config.Current.ESP_Generator then
        if billboard then billboard:Destroy() end
        ESP.Utils.RemoveHighlight(generator)
        generator:SetAttribute("LastESPPercent", nil)
        return percent >= 100
    end
    local rounded = math.floor(percent * 10) / 10
    if generator:GetAttribute("LastESPPercent") == rounded and billboard then return false end
    generator:SetAttribute("LastESPPercent", rounded)
    local cp = math.clamp(percent, 0, 100)
    local finalColor = cp < 50 and ESP.Config.ESP_COLORS.Generator:Lerp(GEN_COLOR_MID, cp / 50) or GEN_COLOR_MID:Lerp(GEN_COLOR_END, (cp - 50) / 50)
    ESP.Utils.ApplyHighlight(generator, finalColor)
    local targetPart = generator:FindFirstChild("RootPart", true) or generator:FindFirstChild("defaultMaterial", true) or generator.PrimaryPart or generator:FindFirstChildWhichIsA("BasePart", true)
    if not targetPart then return false end
    local percentStr = ESP.Utils.s_format("%.1f%%", rounded)
    if not billboard then
        billboard = Instance.new("BillboardGui")
        billboard.Name = "GenBitchHook"; billboard.Parent = generator; billboard.Adornee = targetPart
        billboard.AlwaysOnTop = true; billboard.LightInfluence = 0; billboard.ResetOnSpawn = false
        billboard.MaxDistance = 300; billboard.Size = UDim2.new(0, 125, 0, 24)
        local yOffset = 2.8
        pcall(function() yOffset = math.clamp((targetPart.Size.Y * 0.5) + 1.15, 2.8, 4.2) end)
        billboard.StudsOffset = ESP.Utils.v3(0, yOffset, 0)
        local lbl = Instance.new("TextLabel")
        lbl.Name = "Label"; lbl.Parent = billboard; lbl.BackgroundTransparency = 1; lbl.Size = UDim2.fromScale(1, 1)
        lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 8; lbl.TextScaled = false; lbl.TextWrapped = false
        lbl.RichText = false; lbl.TextXAlignment = Enum.TextXAlignment.Center; lbl.TextYAlignment = Enum.TextYAlignment.Center
        lbl.Text = percentStr; lbl.TextColor3 = finalColor
        local stroke = Instance.new("UIStroke"); stroke.Parent = lbl; stroke.Thickness = 1; stroke.Transparency = 0.2; stroke.Color = Color3.new(0, 0, 0)
        local constraint = Instance.new("UITextSizeConstraint"); constraint.Parent = lbl; constraint.MaxTextSize = 8; constraint.MinTextSize = 6
    else
        if billboard.Adornee ~= targetPart then billboard.Adornee = targetPart end
        local yOffset = 2.8
        pcall(function() yOffset = math.clamp((targetPart.Size.Y * 0.5) + 1.15, 2.8, 4.2) end)
        billboard.StudsOffset = ESP.Utils.v3(0, yOffset, 0)
        local lbl = billboard:FindFirstChild("Label")
        if lbl then lbl.Text = percentStr; lbl.TextColor3 = finalColor end
    end
    return false
end

function ESP.IsSCP(v) if not (v and v:IsA("Model")) then return false end local n = v.Name:lower() return n == "scp" or n:match("^scp%d*$") or n:match("^scp[%-%_]?%d+$") or n:find("zombie") or n:find("monster") or n:find("infected") or n:find("mutant") end
function ESP.RemoveSCP(v) local h = ESP.SCPCache[v]; if h then pcall(function() h:Destroy() end) end; ESP.SCPCache[v] = nil end
function ESP.CreateSCP(v)
    if not ESP.Config.Current.ESP_SCP or ESP.SCPCache[v] or not (v and v.Parent) or not ESP.IsSCP(v) then return end
    local root = v:FindFirstChild("HumanoidRootPart", true)
