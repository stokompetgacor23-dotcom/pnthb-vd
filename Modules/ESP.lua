-- =======================================================
-- PINATHUB - ESP MODULE
-- =======================================================

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")

local ESP = {}

-- Dependencies (injected from Main)
ESP.Utils = nil
ESP.Config = nil
ESP.WindUI = nil
ESP.TargetGui = nil

-- =========================================================
-- CACHED OBJECTS
-- =========================================================
ESP.CachedMapObjects = {
    Generators = {},
    Pallets = {},
    Hooks = {},
    Gates = {}
}

ESP.PrevESPState = { Generator = false, Hook = false, Pallet = false, Gate = false }
ESP.ESP_PlayerCache = {}
ESP.SCPCache = {}
ESP.SCPConnection = nil
ESP.SCPFolder = nil
ESP.LastESPRefresh = 0

-- =========================================================
-- INIT SCP FOLDER
-- =========================================================
function ESP.InitSCPFolder()
    ESP.SCPFolder = CoreGui:FindFirstChild("PINATHUB_SCP_ESP") or Instance.new("Folder")
    ESP.SCPFolder.Name = "PINATHUB_SCP_ESP"
    ESP.SCPFolder.Parent = CoreGui
end

-- =========================================================
-- UPDATE MAP CACHE
-- =========================================================
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
        
        if n == "Generator" then
            table.insert(ESP.CachedMapObjects.Generators, obj)
        elseif n == "Hook" then
            table.insert(ESP.CachedMapObjects.Hooks, obj)
        elseif n == "Gate" then
            table.insert(ESP.CachedMapObjects.Gates, obj)
        elseif n == "Pallet" or n == "Palletwrong" then
            table.insert(ESP.CachedMapObjects.Pallets, obj)
        end
        
        if i % 500 == 0 then task.wait() end
    end
    
    ESP.PrevESPState.Generator = false
    ESP.PrevESPState.Hook = false
    ESP.PrevESPState.Pallet = false
    ESP.PrevESPState.Gate = false
end

-- =========================================================
-- PLAYER ESP
-- =========================================================
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
    
    if not root or not hum or hum.Health <= 0 then
        ESP.RemovePlayerESP(player)
        return
    end
    
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    
    local dist = ESP.Utils.m_floor((root.Position - myRoot.Position).Magnitude)
    local color = isKiller and ESP.Config.ESP_COLORS.Killer or ESP.Config.ESP_COLORS.Survivor
    local statusText = ""
    
    if isKiller then
        local detectedMask = char:GetAttribute("CachedMask")
            or char:GetAttribute("KillerType")
            or char:GetAttribute("SelectedKiller")
            or ESP.Utils.GetGameValue(char, "SelectedKiller")
            or ESP.Utils.GetGameValue(player, "SelectedKiller")
            or ESP.Utils.GetGameValue(char, "Mask")
            or ESP.Utils.GetGameValue(player, "Mask")
            or char.Name
        
        if detectedMask then
            char:SetAttribute("CachedMask", detectedMask)
        end
        
        statusText = ESP.Config.MaskNames[detectedMask] or "KILLER"
        color = ESP.Config.MaskColors[detectedMask] or color
    else
        local hooked = ESP.Utils.IsStatusActive(ESP.Utils.GetGameValue(char, "IsHooked")) or ESP.Utils.IsStatusActive(ESP.Utils.GetGameValue(player, "IsHooked"))
        local carried = ESP.Utils.IsStatusActive(ESP.Utils.GetGameValue(char, "Carried")) or ESP.Utils.IsStatusActive(ESP.Utils.GetGameValue(char, "IsCarried")) or ESP.Utils.IsStatusActive(ESP.Utils.GetGameValue(char, "Grabbed")) or ESP.Utils.IsStatusActive(ESP.Utils.GetGameValue(player, "Carried"))
        local knocked = ESP.Utils.IsStatusActive(ESP.Utils.GetGameValue(char, "Knocked")) or ESP.Utils.IsStatusActive(ESP.Utils.GetGameValue(char, "IsKnocked"))
        
        if hooked then
            color = Color3.fromRGB(255, 70, 140)
            statusText = "HOOKED"
        elseif carried then
            color = Color3.fromRGB(190, 90, 255)
            statusText = "CARRIED"
        elseif knocked then
            color = Color3.fromRGB(255, 170, 0)
            statusText = "KNOCKED"
        elseif hum.Health < hum.MaxHealth then
            color = Color3.fromRGB(255, 225, 80)
            statusText = "INJURED"
        else
            statusText = nil
            color = ESP.Config.ESP_COLORS.Survivor
        end
    end
    
    local bottomText
    if isKiller then
        bottomText = ESP.Utils.s_format('<font color="#DCDCDC">%dm</font> • <font color="#%s">[%s]</font>', dist, color:ToHex(), string.upper(statusText))
    elseif statusText then
        bottomText = ESP.Utils.s_format('<font color="#DCDCDC">%dm</font> • <font color="#%s">%s</font>', dist, color:ToHex(), statusText)
    else
        bottomText = ESP.Utils.s_format('<font color="#DCDCDC">%dm</font>', dist)
    end
    
    local finalName = ESP.Utils.s_format('<b>@%s</b>\n%s', player.Name, bottomText)
    
    ESP.ESP_PlayerCache[player.UserId] = { dist = dist, status = statusText }
    
    local showName = isKiller and ESP.Config.Current.ESP_Killer_Name or ESP.Config.Current.ESP_Survivor_Name
    local showHighlight = isKiller and ESP.Config.Current.ESP_Killer_Highlight or ESP.Config.Current.ESP_Survivor_Highlight
    
    if showHighlight then
        ESP.Utils.ApplyHighlight(char, color)
    else
        ESP.Utils.RemoveHighlight(char)
    end
    
    local bg = root:FindFirstChild("TagESP")
    
    if showName then
        if not bg then
            bg = Instance.new("BillboardGui")
            bg.Name = "TagESP"
            bg.Parent = root
            bg.Adornee = root
            bg.AlwaysOnTop = true
            bg.LightInfluence = 0
            bg.ResetOnSpawn = false
            bg.MaxDistance = 1800
            bg.Size = UDim2.new(0, 165, 0, 34)
            bg.StudsOffset = ESP.Utils.v3(0, 3.8, 0)
            
            local lbl = Instance.new("TextLabel")
            lbl.Name = "Label"
            lbl.Parent = bg
            lbl.BackgroundTransparency = 1
            lbl.Size = UDim2.fromScale(1, 1)
            lbl.RichText = true
            lbl.TextScaled = false
            lbl.TextWrapped = false
            lbl.Font = Enum.Font.GothamBold
            lbl.TextSize = 8
            lbl.TextStrokeTransparency = 1
            lbl.TextYAlignment = Enum.TextYAlignment.Center
            lbl.TextXAlignment = Enum.TextXAlignment.Center
            lbl.Text = finalName
            lbl.TextColor3 = color
            
            local stroke = Instance.new("UIStroke")
            stroke.Parent = lbl
            stroke.Thickness = 1.2
            stroke.Transparency = 0.2
            stroke.Color = Color3.new(0, 0, 0)
            
            local constraint = Instance.new("UITextSizeConstraint")
            constraint.Parent = lbl
            constraint.MaxTextSize = 8
            constraint.MinTextSize = 5
        else
            local lbl = bg:FindFirstChild("Label")
            if lbl then
                lbl.Text = finalName
                lbl.TextColor3 = color
                
                if dist > 220 then
                    bg.Size = UDim2.new(0, 105, 0, 20)
                    bg.StudsOffset = ESP.Utils.v3(0, 1.6, 0)
                    lbl.TextSize = 6
                    lbl.TextTransparency = 0.15
                elseif dist > 150 then
                    bg.Size = UDim2.new(0, 120, 0, 22)
                    bg.StudsOffset = ESP.Utils.v3(0, 2, 0)
                    lbl.TextSize = 6.5
                    lbl.TextTransparency = 0.08
                elseif dist > 90 then
                    bg.Size = UDim2.new(0, 140, 0, 26)
                    bg.StudsOffset = ESP.Utils.v3(0, 2.7, 0)
                    lbl.TextSize = 7
                    lbl.TextTransparency = 0
                else
                    bg.Size = UDim2.new(0, 165, 0, 34)
                    bg.StudsOffset = ESP.Utils.v3(0, 3.8, 0)
                    lbl.TextSize = 8
                    lbl.TextTransparency = 0
                end
            end
        end
    elseif bg then
        bg:Destroy()
    end
end

-- =========================================================
-- GENERATOR ESP
-- =========================================================
local GEN_COLOR_MID = Color3.fromRGB(255, 140, 0)
local GEN_COLOR_END = Color3.fromRGB(0, 255, 120)

function ESP.UpdateGeneratorProgress(generator)
    if not generator or not generator.Parent then
        return true
    end
    
    local percent = ESP.Utils.GetGameValue(generator, "RepairProgress") or ESP.Utils.GetGameValue(generator, "Progress") or 0
    local billboard = generator:FindFirstChild("GenBitchHook")
    
    if percent >= 100 or not ESP.Config.Current.ESP_Generator then
        if billboard then billboard:Destroy() end
        ESP.Utils.RemoveHighlight(generator)
        generator:SetAttribute("LastESPPercent", nil)
        return percent >= 100
    end
    
    local rounded = math.floor(percent * 10) / 10
    
    if generator:GetAttribute("LastESPPercent") == rounded and billboard then
        return false
    end
    
    generator:SetAttribute("LastESPPercent", rounded)
    
    local cp = math.clamp(percent, 0, 100)
    local finalColor = cp < 50 and ESP.Config.ESP_COLORS.Generator:Lerp(GEN_COLOR_MID, cp / 50) or GEN_COLOR_MID:Lerp(GEN_COLOR_END, (cp - 50) / 50)
    
    ESP.Utils.ApplyHighlight(generator, finalColor)
    
    local targetPart = generator:FindFirstChild("RootPart", true) or generator:FindFirstChild("defaultMaterial", true) or generator.PrimaryPart or generator:FindFirstChildWhichIsA("BasePart", true)
    
    if not targetPart then return false end
    
    local percentStr = ESP.Utils.s_format("%.1f%%", rounded)
    
    if not billboard then
        billboard = Instance.new("BillboardGui")
        billboard.Name = "GenBitchHook"
        billboard.Parent = generator
        billboard.Adornee = targetPart
        billboard.AlwaysOnTop = true
        billboard.LightInfluence = 0
        billboard.ResetOnSpawn = false
        billboard.MaxDistance = 300
        billboard.Size = UDim2.new(0, 125, 0, 24)
        
        local yOffset = 2.8
        pcall(function()
            yOffset = math.clamp((targetPart.Size.Y * 0.5) + 1.15, 2.8, 4.2)
        end)
        billboard.StudsOffset = ESP.Utils.v3(0, yOffset, 0)
        
        local lbl = Instance.new("TextLabel")
        lbl.Name = "Label"
        lbl.Parent = billboard
        lbl.BackgroundTransparency = 1
        lbl.Size = UDim2.fromScale(1, 1)
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 8
        lbl.TextScaled = false
        lbl.TextWrapped = false
        lbl.RichText = false
        lbl.TextXAlignment = Enum.TextXAlignment.Center
        lbl.TextYAlignment = Enum.TextYAlignment.Center
        lbl.Text = percentStr
        lbl.TextColor3 = finalColor
        
        local stroke = Instance.new("UIStroke")
        stroke.Parent = lbl
        stroke.Thickness = 1
        stroke.Transparency = 0.2
        stroke.Color = Color3.new(0, 0, 0)
        
        local constraint = Instance.new("UITextSizeConstraint")
        constraint.Parent = lbl
        constraint.MaxTextSize = 8
        constraint.MinTextSize = 6
    else
        if billboard.Adornee ~= targetPart then
            billboard.Adornee = targetPart
        end
        
        local yOffset = 2.8
        pcall(function()
            yOffset = math.clamp((targetPart.Size.Y * 0.5) + 1.15, 2.8, 4.2)
        end)
        billboard.StudsOffset = ESP.Utils.v3(0, yOffset, 0)
        
        local lbl = billboard:FindFirstChild("Label")
        if lbl then
            lbl.Text = percentStr
            lbl.TextColor3 = finalColor
        end
    end
    return false
end

-- =========================================================
-- SCP ESP
-- =========================================================
function ESP.IsSCP(v)
    if not (v and v:IsA("Model")) then return false end
    local n = v.Name:lower()
    return n == "scp" or n:match("^scp%d*$") or n:match("^scp[%-%_]?%d+$") or n:find("zombie") or n:find("monster") or n:find("infected") or n:find("mutant")
end

function ESP.RemoveSCP(v)
    local h = ESP.SCPCache[v]
    if h then
        pcall(function() h:Destroy() end)
    end
    ESP.SCPCache[v] = nil
end

function ESP.CreateSCP(v)
    if not ESP.Config.Current.ESP_SCP or ESP.SCPCache[v] or not (v and v.Parent) or not ESP.IsSCP(v) then
        return
    end
    
    local root = v:FindFirstChild("HumanoidRootPart", true) or v.PrimaryPart or v:FindFirstChildWhichIsA("BasePart", true)
    if not root then return end
    
    local h = Instance.new("Highlight")
    h.Name = "SCPESP"
    h.Adornee = v
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    h.FillColor = Color3.fromRGB(170, 0, 255)
    h.OutlineColor = Color3.fromRGB(255, 220, 255)
    h.FillTransparency = 0.78
    h.OutlineTransparency = 0.03
    h.Parent = ESP.SCPFolder
    
    ESP.SCPCache[v] = h
    
    v.AncestryChanged:Connect(function(_, p)
        if not p then ESP.RemoveSCP(v) end
    end)
    
    local hum = v:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.Died:Connect(function() ESP.RemoveSCP(v) end)
    end
end

function ESP.ScanSCP()
    for _, v in ipairs(workspace:GetChildren()) do
        if ESP.IsSCP(v) then
            ESP.CreateSCP(v)
        end
    end
end

function ESP.ConnectSCP()
    if ESP.SCPConnection then
        ESP.SCPConnection:Disconnect()
    end
    ESP.SCPConnection = workspace.ChildAdded:Connect(function(v)
        if not ESP.Config.Current.ESP_SCP or not (v and v:IsA("Model")) then return end
        task.delay(0.12, function()
            if v and v.Parent and ESP.IsSCP(v) then
                ESP.CreateSCP(v)
            end
        end)
    end)
end

function ESP.UpdateSCPLoop()
    task.spawn(function()
        while task.wait(0.7) do
            if not getgenv().PINATHUB_RUNNING then break end
            if not ESP.Config.Current.ESP_SCP then
                for v in pairs(ESP.SCPCache) do
                    ESP.RemoveSCP(v)
                end
            else
                for v, h in pairs(ESP.SCPCache) do
                    if not (v and v.Parent and h and h.Parent) then
                        ESP.RemoveSCP(v)
                    else
                        if h.Adornee ~= v then h.Adornee = v end
                        if h.FillTransparency ~= 0.78 then h.FillTransparency = 0.78 end
                        if h.OutlineTransparency ~= 0.03 then h.OutlineTransparency = 0.03 end
                    end
                end
                ESP.ScanSCP()
            end
        end
    end)
end

-- =========================================================
-- REFRESH ESP
-- =========================================================
function ESP.RefreshESP()
    if not workspace.CurrentCamera then return end
    if #Players:GetPlayers() <= 1 then return end
    
    local players = Players:GetPlayers()
    for _, p in ipairs(players) do
        if p ~= LocalPlayer then
            local team = p.Team
            local isKiller = false
            if team and team.Name then
                isKiller = string.find(string.lower(team.Name), "killer") ~= nil
            end
            
            local shouldESP = false
            if isKiller and (ESP.Config.Current.ESP_Killer_Name or ESP.Config.Current.ESP_Killer_Highlight) then
                shouldESP = true
            elseif not isKiller and (ESP.Config.Current.ESP_Survivor_Name or ESP.Config.Current.ESP_Survivor_Highlight) then
                shouldESP = true
            end
            
            if shouldESP then
                ESP.CreatePlayerESP(p, isKiller)
            else
                ESP.RemovePlayerESP(p)
            end
        end
    end
    
    if not ESP.CachedMapObjects then return end
    
    -- Generator ESP
    if ESP.Config.Current.ESP_Generator then
        if not ESP.PrevESPState.Generator then ESP.PrevESPState.Generator = true end
        local gens = ESP.CachedMapObjects.Generators
        local newActiveGens = {}
        for i = 1, #gens do
            local obj = gens[i]
            if obj and obj.Parent then
                local isFinished = ESP.UpdateGeneratorProgress(obj)
                if not isFinished then
                    table.insert(newActiveGens, obj)
                end
            end
        end
        ESP.CachedMapObjects.Generators = newActiveGens
    elseif ESP.PrevESPState.Generator then
        for _, obj in ipairs(ESP.CachedMapObjects.Generators) do
            if obj and obj.Parent then
                ESP.Utils.RemoveHighlight(obj)
                local b = obj:FindFirstChild("GenBitchHook")
                if b then b:Destroy() end
            end
        end
        ESP.PrevESPState.Generator = false
    end
    
    -- Pallet ESP
    if ESP.Config.Current.ESP_Pallet then
        if not ESP.PrevESPState.Pallet then ESP.PrevESPState.Pallet = true end
        local pallets = ESP.CachedMapObjects.Pallets
        local MAX_DISTANCE = 140
        
        for i = #pallets, 1, -1 do
            local pallet = pallets[i]
            local isValid = pallet and pallet.Parent and pallet:IsDescendantOf(workspace)
            
            if isValid then
                local targetPart = (pallet:IsA("Model") and pallet.PrimaryPart) or pallet:FindFirstChildWhichIsA("BasePart", true) or (pallet:IsA("BasePart") and pallet)
                
                local hasVisibleParts = false
                if targetPart then
                    if pallet:IsA("BasePart") then
                        hasVisibleParts = pallet.Transparency < 1
                    else
                        local parts = pallet:GetDescendants()
                        for j = 1, #parts do
                            local p = parts[j]
                            if p:IsA("BasePart") and p.Transparency < 1 then
                                hasVisibleParts = true
                                break
                            end
                        end
                    end
                end
                
                local nLower = string.lower(pallet.Name)
                local isDropped = ESP.Utils.IsStatusActive(ESP.Utils.GetGameValue(pallet, "Dropped")) or ESP.Utils.IsStatusActive(ESP.Utils.GetGameValue(pallet, "IsDropped"))
                local isBroken = ESP.Utils.IsStatusActive(ESP.Utils.GetGameValue(pallet, "Broken")) or ESP.Utils.IsStatusActive(ESP.Utils.GetGameValue(pallet, "IsBroken")) or ESP.Utils.IsStatusActive(ESP.Utils.GetGameValue(pallet, "Destroyed"))
                local isFake = string.find(nLower, "fake") or string.find(nLower, "broken") or string.find(nLower, "destroyed")
                
                if isDropped or isBroken or isFake or not hasVisibleParts or not targetPart then
                    local tag = pallet:FindFirstChild("PalletTag")
                    if tag then tag:Destroy() end
                    if isDropped or isBroken or isFake then
                        table.remove(pallets, i)
                    end
                else
                    local tag = pallet:FindFirstChild("PalletTag")
                    if not tag then
                        local b = ESP.Utils.CreateBillboardTag("<b>[PALLET]</b>", ESP.Config.ESP_COLORS.Pallet, UDim2.new(0, 50, 0, 18), 6)
                        b.Name = "PalletTag"
                        b.Parent = pallet
                        b.Adornee = targetPart
                        b.MaxDistance = MAX_DISTANCE
                    else
                        if not tag.Adornee then tag.Adornee = targetPart end
                        local lbl = tag:FindFirstChild("Label")
                        if lbl and lbl.TextColor3 ~= ESP.Config.ESP_COLORS.Pallet then
                            lbl.TextColor3 = ESP.Config.ESP_COLORS.Pallet
                        end
                    end
                end
            else
                if pallet then
                    local tag = pallet:FindFirstChild("PalletTag")
                    if tag then tag:Destroy() end
                end
                table.remove(pallets, i)
            end
        end
    elseif ESP.PrevESPState.Pallet then
        for _, pallet in ipairs(ESP.CachedMapObjects.Pallets) do
            if pallet then
                local tag = pallet:FindFirstChild("PalletTag")
                if tag then tag:Destroy() end
            end
        end
        ESP.PrevESPState.Pallet = false
    end
    
    -- Gate ESP
    if ESP.Config.Current.ESP_Gate then
        if not ESP.PrevESPState.Gate then ESP.PrevESPState.Gate = true end
        local gates = ESP.CachedMapObjects.Gates
        for i = #gates, 1, -1 do
            local gate = gates[i]
            if gate and gate.Parent then
                ESP.Utils.ApplyHighlight(gate, ESP.Config.ESP_COLORS.Gate)
            else
                table.remove(gates, i)
            end
        end
    elseif ESP.PrevESPState.Gate then
        for _, gate in ipairs(ESP.CachedMapObjects.Gates) do
            if gate and gate.Parent then ESP.Utils.RemoveHighlight(gate) end
        end
        ESP.PrevESPState.Gate = false
    end
    
    -- Hook ESP
    if ESP.Config.Current.ESP_Hook then
        if not ESP.PrevESPState.Hook then ESP.PrevESPState.Hook = true end
        local hooks = ESP.CachedMapObjects.Hooks
        for i = #hooks, 1, -1 do
            local hook = hooks[i]
            if hook and hook.Parent then
                local m = hook:FindFirstChild("Model")
                if m then
                    for _, p in ipairs(m:GetDescendants()) do
                        if p:IsA("MeshPart") then ESP.Utils.ApplyHighlight(p, ESP.Config.ESP_COLORS.Hook) end
                    end
                else
                    ESP.Utils.ApplyHighlight(hook, ESP.Config.ESP_COLORS.Hook)
                end
            else
                table.remove(hooks, i)
            end
        end
    elseif ESP.PrevESPState.Hook then
        for _, hook in ipairs(ESP.CachedMapObjects.Hooks) do
            if hook and hook.Parent then
                local m = hook:FindFirstChild("Model")
                if m then
                    for _, p in ipairs(m:GetDescendants()) do
                        if p:IsA("MeshPart") then ESP.Utils.RemoveHighlight(p) end
                    end
                else
                    ESP.Utils.RemoveHighlight(hook)
                end
            end
        end
        ESP.PrevESPState.Hook = false
    end
end

-- =========================================================
-- MAP DETECTOR LOOP
-- =========================================================
function ESP.StartMapDetector()
    task.spawn(function()
        local mapWasEmpty = true
        local descendantConn = nil
        
        while task.wait(2) do
            if not getgenv().PINATHUB_RUNNING then
                if descendantConn then descendantConn:Disconnect() end
                break
            end
            
            local currentMap = workspace:FindFirstChild("Map")
            local hasContents = currentMap and #currentMap:GetChildren() > 0
            
            if hasContents and mapWasEmpty then
                mapWasEmpty = false
                
                task.delay(8, function()
                    if currentMap and #currentMap:GetChildren() > 0 then
                        ESP.UpdateMapCache()
                        
                        if descendantConn then descendantConn:Disconnect() end
                        descendantConn = currentMap.DescendantAdded:Connect(function(obj)
                            local n = obj.Name
                            if n == "Generator" then
                                table.insert(ESP.CachedMapObjects.Generators, obj)
                            elseif n == "Hook" then
                                table.insert(ESP.CachedMapObjects.Hooks, obj)
                            elseif n == "Gate" then
                                table.insert(ESP.CachedMapObjects.Gates, obj)
                            elseif n == "Pallet" or n == "Palletwrong" then
                                table.insert(ESP.CachedMapObjects.Pallets, obj)
                            end
                        end)
                        
                        local palletCount = #ESP.CachedMapObjects.Pallets
                        local genCount = #ESP.CachedMapObjects.Generators
                        
                        if ESP.WindUI then
                            ESP.WindUI:Notify({
                                Title = "Map Loaded",
                                Content = "Found " .. palletCount .. " Pallets & " .. genCount .. " Gens. Radar Active!",
                                Icon = "lucide:radar"
                            })
                        end
                    end
                end)
                
            elseif not hasContents and not mapWasEmpty then
                mapWasEmpty = true
                
                if descendantConn then
                    descendantConn:Disconnect()
                    descendantConn = nil
                end
                
                ESP.CachedMapObjects.Generators = {}
                ESP.CachedMapObjects.Pallets = {}
                ESP.CachedMapObjects.Hooks = {}
                ESP.CachedMapObjects.Gates = {}
                
                ESP.PrevESPState.Generator = false
                ESP.PrevESPState.Hook = false
                ESP.PrevESPState.Pallet = false
                ESP.PrevESPState.Gate = false
            end
        end
    end)
end

return ESP
