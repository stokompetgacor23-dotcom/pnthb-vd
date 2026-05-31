-- =======================================================
-- PINATHUB - UI MODULE (SWING OBBY BRAINROT STYLE)
-- =======================================================
-- ONLY UI STYLE CHANGED (Brainrot look & feel)
-- ALL FEATURES (Combat, Visuals, Player, Misc) REMAIN INTACT
-- =======================================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

local UI = {}
UI.GuiVisible = true
UI.Window = nil
UI.Modules = nil
UI.WindUI = nil
UI.TargetGui = nil

-- ============================================
-- EXECUTOR COMPATIBILITY
-- ============================================
local function noop() end
local set_clipboard = setclipboard or (syn and syn.setclipboard) or noop

-- ============================================
-- GRADIENT HELPER (Brainrot Style)
-- ============================================
local function gradient(text, startColor, endColor, timeOffset)
    if type(text) ~= "string" or text == "" then return "" end
    local chars, result = {}, {}
    for _, c in utf8.codes(text) do chars[#chars + 1] = utf8.char(c) end
    local len = #chars
    local div = math.max(len - 1, 1)
    timeOffset = tonumber(timeOffset) or 0
    for i = 1, len do
        local t = math.abs((((i - 1) / div) + timeOffset) % 2 - 1)
        local color = startColor:Lerp(endColor, t)
        result[i] = string.format('<font color="#%s">%s</font>', color:ToHex(), chars[i])
    end
    return table.concat(result)
end

-- ============================================
-- LOAD WINDUI
-- ============================================
local function loadWindUI()
    local success, result = pcall(function()
        return loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
    end)
    return success and result or nil
end

-- ============================================
-- CREATE LOGO LAUNCHER (Brainrot Style)
-- ============================================
function UI:CreateLogo()
    local logoGui = Instance.new("ScreenGui")
    logoGui.Name = "PinatHubLogo"
    logoGui.ResetOnSpawn = false
    logoGui.Parent = LocalPlayer:WaitForChild("PlayerGui", 5)
    
    local logoButton = Instance.new("ImageButton")
    logoButton.Name = "LogoButton"
    logoButton.Size = UDim2.new(0, 50, 0, 50)
    logoButton.Position = UDim2.new(0.5, -25, 0.5, -25)
    logoButton.BackgroundTransparency = 1
    logoButton.Image = "rbxassetid://118264723961739"
    logoButton.ImageColor3 = Color3.fromRGB(180, 0, 255)
    logoButton.ScaleType = Enum.ScaleType.Fit
    logoButton.Parent = logoGui
    
    local uiCornerLogo = Instance.new("UICorner")
    uiCornerLogo.CornerRadius = UDim.new(1, 0)
    uiCornerLogo.Parent = logoButton
    
    local hoverTween = TweenService:Create(logoButton, TweenInfo.new(0.2), {Size = UDim2.new(0, 60, 0, 60)})
    local unhoverTween = TweenService:Create(logoButton, TweenInfo.new(0.2), {Size = UDim2.new(0, 50, 0, 50)})
    
    logoButton.MouseEnter:Connect(function() hoverTween:Play() end)
    logoButton.MouseLeave:Connect(function() unhoverTween:Play() end)
    
    local dragging = false
    local dragStart = nil
    local startPos = nil
    
    logoButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = logoButton.Position
        end
    end)
    
    logoButton.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
            dragStart = nil
            startPos = nil
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and dragStart and startPos then
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                local delta = input.Position - dragStart
                local newX = startPos.X.Offset + delta.X
                local newY = startPos.Y.Offset + delta.Y
                logoButton.Position = UDim2.new(startPos.X.Scale, newX, startPos.Y.Scale, newY)
            end
        end
    end)
    
    return logoGui, logoButton
end

-- ============================================
-- INIT FUNCTION (Brainrot UI Style - Features Intact)
-- ============================================
function UI:Init()
    local WindUI = loadWindUI()
    if not WindUI then 
        print("Failed to load WindUI Library")
        return nil
    end
    
    self.WindUI = WindUI
    local config = self.Modules.Config
    local esp = self.Modules.ESP
    local player = self.Modules.Player
    local combat = self.Modules.Combat
    local misc = self.Modules.Misc
    
    -- Create Window (Brainrot Style)
    self.Window = WindUI:CreateWindow({
        Title = gradient("PINATHUB", Color3.fromHex("#FFFFFF"), Color3.fromHex("#8F8F8F")),
        Author = "@viunze on tiktok",
        Folder = "pinathub",
        Size = UDim2.fromOffset(500, 400),
        Transparent = true,
        Theme = "Dark",
        IsOpenButtonEnabled = false,
        UserEnabled = true,
        HasOutline = true,
        SideBarWidth = 150,
    })
    
    -- Create Logo
    local logoGui, logoButton = self:CreateLogo()
    
    local guiVisible = true
    logoButton.MouseButton1Click:Connect(function()
        guiVisible = not guiVisible
        if self.Window then
            pcall(function()
                if guiVisible then
                    self.Window:Open()
                else
                    self.Window:Minimize()
                end
            end)
        end
    end)
    
    -- ============================================
    -- TABS (PINATHUB Features)
    -- ============================================
    local CombatTab = self.Window:Tab({ Title = "Combat", Icon = "sword" })
    local VisualsTab = self.Window:Tab({ Title = "Visuals", Icon = "eye" })
    local PlayerTab = self.Window:Tab({ Title = "Player", Icon = "user" })
    local MiscTab = self.Window:Tab({ Title = "Misc", Icon = "settings" })
    local CommunityTab = self.Window:Tab({ Title = "Community", Icon = "users" })
    
    -- ============================================
    -- COMBAT TAB (Auto Parry, Aimbot, Hitbox, Auto Attack)
    -- ============================================
    local parrySection = CombatTab:Section({ Title = "Auto Parry" })
    parrySection:Toggle({ Title = "Auto Parry", Value = config.Current.AutoParry, Callback = function(v) config.Set("AutoParry", v) end })
    parrySection:Slider({ Title = "Parry Distance", Value = { Min = 3, Max = 25, Default = config.Current.ParryDistance }, Callback = function(v) config.Set("ParryDistance", v) end })
    parrySection:Dropdown({ Title = "Killer Matchup", Values = { "Auto", "Abysswalker", "Hidden", "Killer", "Masked", "Stalker", "Veil", "Slasher", "Cure" }, Value = config.Current.ParryMatchup, Callback = function(v) config.Set("ParryMatchup", v) end })
    parrySection:Slider({ Title = "Parry Delay (ms)", Value = { Min = -150, Max = 1000, Default = config.Current.ParryDelayOffset * 1000 }, Callback = function(v) config.Set("ParryDelayOffset", v / 1000) end })
    parrySection:Divider()
    
    local aimbotSection = CombatTab:Section({ Title = "Aimbot" })
    aimbotSection:Toggle({ Title = "Aimbot", Value = config.Current.Aimbot, Callback = function(v) config.Set("Aimbot", v) end })
    aimbotSection:Dropdown({ Title = "Aimbot Target", Values = { "Head", "Torso", "Body (RootPart)" }, Value = config.Current.AimbotPart, Callback = function(v) config.Set("AimbotPart", v) end })
    aimbotSection:Dropdown({ Title = "Aimbot Trigger", Values = { "Hold to Lock", "Auto Lock (Always)" }, Value = config.Current.AimbotTrigger, Callback = function(v) config.Set("AimbotTrigger", v) end })
    aimbotSection:Slider({ Title = "Aim Radius", Value = { Min = 30, Max = 150, Default = config.Current.AimRadius }, Callback = function(v) config.Set("AimRadius", v) end })
    aimbotSection:Slider({ Title = "Aim Distance", Value = { Min = 30, Max = 150, Default = config.Current.AimDistance }, Callback = function(v) config.Set("AimDistance", v) end })
    aimbotSection:Slider({ Title = "Smoothness", Value = { Min = 1, Max = 20, Default = config.Current.AimbotSmoothness }, Callback = function(v) config.Set("AimbotSmoothness", v) end })
    aimbotSection:Toggle({ Title = "Wall Check", Value = config.Current.WallCheck, Callback = function(v) config.Set("WallCheck", v) end })
    aimbotSection:Divider()
    
    local miscCombatSection = CombatTab:Section({ Title = "Misc Combat" })
    miscCombatSection:Toggle({ Title = "Silent Aim Pistol", Value = config.Current.SilentAimPistol, Callback = function(v) config.Set("SilentAimPistol", v); if not v then player.ResetScope() end end })
    miscCombatSection:Toggle({ Title = "Auto Attack (Killer)", Value = config.Current.AutoAttack, Callback = function(v) config.Set("AutoAttack", v) end })
    miscCombatSection:Slider({ Title = "Attack Range", Value = { Min = 5, Max = 25, Default = config.Current.AttackRange }, Callback = function(v) config.Set("AttackRange", v) end })
    miscCombatSection:Toggle({ Title = "Hitbox Expander", Value = config.Current.HitboxExpander, Callback = function(v) config.Set("HitboxExpander", v) end })
    miscCombatSection:Slider({ Title = "Hitbox Size", Value = { Min = 2, Max = 50, Default = config.Current.HitboxSize }, Callback = function(v) config.Set("HitboxSize", v) end })
    miscCombatSection:Toggle({ Title = "Double Damage Generator", Value = config.Current.DoubleDamageGen, Callback = function(v) config.Set("DoubleDamageGen", v) end })
    
    -- ============================================
    -- VISUALS TAB (ESP)
    -- ============================================
    local playerEspSection = VisualsTab:Section({ Title = "Player ESP" })
    playerEspSection:Toggle({ Title = "ESP Survivor (Name)", Value = config.Current.ESP_Survivor_Name, Callback = function(v) config.Set("ESP_Survivor_Name", v); esp.RefreshESP() end })
    playerEspSection:Toggle({ Title = "ESP Survivor (Highlight)", Value = config.Current.ESP_Survivor_Highlight, Callback = function(v) config.Set("ESP_Survivor_Highlight", v); esp.RefreshESP() end })
    playerEspSection:Toggle({ Title = "ESP Killer (Name)", Value = config.Current.ESP_Killer_Name, Callback = function(v) config.Set("ESP_Killer_Name", v); esp.RefreshESP() end })
    playerEspSection:Toggle({ Title = "ESP Killer (Highlight)", Value = config.Current.ESP_Killer_Highlight, Callback = function(v) config.Set("ESP_Killer_Highlight", v); esp.RefreshESP() end })
    playerEspSection:Divider()
    
    local objectEspSection = VisualsTab:Section({ Title = "Object ESP" })
    objectEspSection:Toggle({ Title = "ESP Generator", Value = config.Current.ESP_Generator, Callback = function(v) config.Set("ESP_Generator", v); esp.RefreshESP() end })
    objectEspSection:Toggle({ Title = "ESP Gate", Value = config.Current.ESP_Gate, Callback = function(v) config.Set("ESP_Gate", v); esp.RefreshESP() end })
    objectEspSection:Toggle({ Title = "ESP Pallet", Value = config.Current.ESP_Pallet, Callback = function(v) config.Set("ESP_Pallet", v); esp.RefreshESP() end })
    objectEspSection:Toggle({ Title = "ESP Hook", Value = config.Current.ESP_Hook, Callback = function(v) config.Set("ESP_Hook", v); esp.RefreshESP() end })
    objectEspSection:Toggle({ Title = "ESP SCP/Zombie", Value = config.Current.ESP_SCP, Callback = function(v) config.Set("ESP_SCP", v) end })
    objectEspSection:Divider()
    
    local cameraSection = VisualsTab:Section({ Title = "Camera Settings" })
    cameraSection:Toggle({ Title = "Custom FOV", Value = config.Current.CustomCameraFOV, Callback = function(v) config.Set("CustomCameraFOV", v) end })
    cameraSection:Slider({ Title = "Field Of View", Value = { Min = 70, Max = 120, Default = config.Current.CameraFOVValue }, Callback = function(v) config.Set("CameraFOVValue", v) end })
    cameraSection:Toggle({ Title = "FPP Mode", Value = config.Current.FPPEnabled, Callback = function(v) config.Set("FPPEnabled", v); player.SwitchCameraMode(v) end })
    cameraSection:Toggle({ Title = "Show FOV Circle", Value = config.Current.ShowFOVCircle, Callback = function(v) config.Set("ShowFOVCircle", v) end })
    
    -- ============================================
    -- PLAYER TAB (Movement & Utilities)
    -- ============================================
    local movementSection = PlayerTab:Section({ Title = "Movement" })
    movementSection:Toggle({ Title = "Speed Boost", Value = config.Current.SpeedBoost, Callback = function(v) config.Set("SpeedBoost", v); local char = LocalPlayer.Character; local hum = char and char:FindFirstChild("Humanoid"); if hum then player.ApplySpeedBoost(hum) end end })
    movementSection:Slider({ Title = "Boost Power (%)", Value = { Min = 0, Max = 150, Default = config.Current.BoostSpeed }, Callback = function(v) config.Set("BoostSpeed", v) end })
    movementSection:Toggle({ Title = "Moonwalk", Value = config.Current.MoonwalkEnabled, Callback = function(v) config.Set("MoonwalkEnabled", v); if not v then local char = LocalPlayer.Character; local hum = char and char:FindFirstChild("Humanoid"); if hum then hum.AutoRotate = true end end end })
    movementSection:Slider({ Title = "Moonwalk Intensity", Value = { Min = 5, Max = 50, Default = config.Current.MoonwalkZigzagSpeed }, Callback = function(v) config.Set("MoonwalkZigzagSpeed", v) end })
    movementSection:Slider({ Title = "Moonwalk Boost", Value = { Min = 1, Max = 1.5, Default = config.Current.MoonwalkBoostPower, Decimals = 2 }, Callback = function(v) config.Set("MoonwalkBoostPower", v) end })
    movementSection:Divider()
    
    local utilitySection = PlayerTab:Section({ Title = "Utilities" })
    utilitySection:Toggle({ Title = "Anti Fall Slow", Value = config.Current.AntiFallDamage, Callback = function(v) config.Set("AntiFallDamage", v) end })
    utilitySection:Toggle({ Title = "Silent Actions", Value = config.Current.SilentActions, Callback = function(v) config.Set("SilentActions", v) end })
    utilitySection:Toggle({ Title = "Notify Killer Stun", Value = config.Current.NotifyStun, Callback = function(v) config.Set("NotifyStun", v) end })
    utilitySection:Button({ Title = "Force Reset State (Anti-Stuck)", Icon = "lucide:refresh-cw", Callback = function() misc.TriggerAntiStuck() end })
    
    -- ============================================
    -- MISC TAB (Generator, Auto Farm, Protection, Allow Jump)
    -- ============================================
    local genSection = MiscTab:Section({ Title = "Generator" })
    genSection:Toggle({ Title = "Auto Generator", Value = config.Current.AutoGenerator, Callback = function(v) config.Set("AutoGenerator", v) end })
    genSection:Dropdown({ Title = "SkillCheck Mode", Values = { "Perfect", "Neutral" }, Value = config.Current.AutoGeneratorMode, Callback = function(v) config.Set("AutoGeneratorMode", v) end })
    genSection:Divider()
    
    local farmSection = MiscTab:Section({ Title = "Auto Farm" })
    farmSection:Toggle({ Title = "Auto Play (AI Survivor)", Value = config.Current.AutoFarmBot, Callback = function(v) config.Set("AutoFarmBot", v); if v then config.Set("AutoGenerator", true); config.Set("AutoGeneratorMode", "Perfect") end end })
    farmSection:Toggle({ Title = "Self Heal", Value = config.Current.SelfHeal, Callback = function(v) config.Set("SelfHeal", v) end })
    farmSection:Divider()
    
    local protectionSection = MiscTab:Section({ Title = "Protection" })
    protectionSection:Toggle({ Title = "Anti-Logger", Value = config.Current.AntiLogger, Callback = function(v) config.Set("AntiLogger", v) end })
    protectionSection:Toggle({ Title = "Anti Aura", Value = getgenv().AntiAura or false, Callback = function(v) getgenv().AntiAura = v end })
    protectionSection:Divider()
    
    -- =========================================================
    -- ALLOW JUMP SECTION (FIXED - Terhubung ke player.ToggleAllowJump)
    -- =========================================================
    local jumpSection = MiscTab:Section({ Title = "Jump" })
    
    -- State lokal untuk toggle
    local jumpEnabled = false
    
    jumpSection:Toggle({ 
        Title = "Allow Jump", 
        Desc = "Maksa game untuk mengizinkan lompatan meskipun dinonaktifkan (Cooldown: 2 detik)",
        Value = false, 
        Callback = function(v)
            jumpEnabled = v
            if v then
                -- Panggil fungsi EnableAllowJump dari Player module
                if player.EnableAllowJump then
                    player.EnableAllowJump()
                else
                    warn("[PINATHUB] player.EnableAllowJump not found!")
                end
                if self.Window then
                    self.Window:Notify("Allow Jump", "Jumping force-enabled! Press Space to jump.", 2)
                end
            else
                -- Panggil fungsi DisableAllowJump dari Player module
                if player.DisableAllowJump then
                    player.DisableAllowJump()
                end
                if self.Window then
                    self.Window:Notify("Allow Jump", "Jumping restored to normal", 2)
                end
            end
        end 
    })
    
    -- ============================================
    -- COMMUNITY TAB
    -- ============================================
    local communitySection = CommunityTab:Section({ Title = "Join Community" })
    
    communitySection:Button({
        Title = "WhatsApp Group",
        Callback = function()
            if set_clipboard then
                set_clipboard("https://chat.whatsapp.com/Cxr7poqqID6Ha6C2MfFOMU")
                self.Window:Notify("Copied!", "WhatsApp link copied!", 2)
            end
        end
    })
    
    communitySection:Button({
        Title = "Discord Server",
        Callback = function()
            if set_clipboard then
                set_clipboard("https://discord.gg/eDbaHKEf7G")
                self.Window:Notify("Copied!", "Discord link copied!", 2)
            end
        end
    })
    
    communitySection:Button({
        Title = "TikTok @viunze",
        Callback = function()
            if set_clipboard then
                set_clipboard("https://tiktok.com/@viunze")
                self.Window:Notify("Copied!", "TikTok profile copied!", 2)
            end
        end
    })
    
    -- ============================================
    -- OPEN WINDOW
    -- ============================================
    self.Window:Open()
    task.wait(1)
    self.Window:Notify("PINATHUB", "Loaded!", 3)
    
    print("PINATHUB Loaded")
    
    return self
end

return UI
