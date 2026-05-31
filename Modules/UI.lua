-- =======================================================
-- PINATHUB - UI MODULE (WINDUI SWING OBBY BRAINROT STYLE)
-- =======================================================
-- ONLY UI STYLE CHANGED, ALL FEATURES REMAIN INTACT
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

-- Load WindUI (Latest Version / Swing Obby Brainrot Style)
local function loadWindUI()
    local success, result = pcall(function()
        return loadstring(game:HttpGet('https://github.com/Footagesus/WindUI/releases/latest/download/main.lua'))()
    end)
    return success and result or nil
end

-- Create logo (Swing Obby Brainrot Style)
function UI:CreateLogo()
    local player = LocalPlayer
    local UIS = UserInputService
    
    local logoGui = Instance.new("ScreenGui")
    logoGui.Name = "PinatHubLogo"
    logoGui.ResetOnSpawn = false
    logoGui.Parent = player:WaitForChild("PlayerGui", 5)
    
    local logoButton = Instance.new("ImageButton")
    logoButton.Name = "LogoButton"
    logoButton.Size = UDim2.new(0, 50, 0, 50)
    logoButton.Position = UDim2.new(0.5, -25, 0.5, -25)
    logoButton.BackgroundTransparency = 1
    logoButton.Image = "rbxassetid://118264723961739"
    logoButton.ImageColor3 = Color3.fromRGB(180, 0, 255)
    logoButton.ScaleType = Enum.ScaleType.Fit
    logoButton.Parent = logoGui
    
    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(1, 0)
    uiCorner.Parent = logoButton
    
    local hoverTween = TweenService:Create(logoButton, TweenInfo.new(0.2), {Size = UDim2.new(0, 60, 0, 60)})
    local unhoverTween = TweenService:Create(logoButton, TweenInfo.new(0.2), {Size = UDim2.new(0, 50, 0, 50)})
    
    logoButton.MouseEnter:Connect(function() hoverTween:Play() end)
    logoButton.MouseLeave:Connect(function() unhoverTween:Play() end)
    
    local draggingLogo = false
    local dragInputLogo, dragStartLogo, startPosLogo
    
    logoButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingLogo = true
            dragStartLogo = input.Position
            startPosLogo = logoButton.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    draggingLogo = false
                end
            end)
        end
    end)
    
    logoButton.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInputLogo = input
        end
    end)
    
    UIS.InputChanged:Connect(function(input)
        if input == dragInputLogo and draggingLogo then
            local delta = input.Position - dragStartLogo
            local newPos = UDim2.new(startPosLogo.X.Scale, startPosLogo.X.Offset + delta.X, startPosLogo.Y.Scale, startPosLogo.Y.Offset + delta.Y)
            logoButton.Position = newPos
        end
    end)
    
    return logoGui, logoButton
end

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
-- INIT FUNCTION (WITH BRAINROT UI STYLE)
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
    
    -- Create Window (SWING OBBY BRAINROT STYLE)
    self.Window = WindUI:CreateWindow({
        Title = "<b>" .. gradient("PINATHUB", Color3.fromHex("#FFFFFF"), Color3.fromHex("#8F8F8F")) .. "</b>",
        Author = gradient("@viunze on tiktok", Color3.fromHex("#D4D4D4"), Color3.fromHex("#7A7A7A")),
        Folder = "pinathub",
        Size = UDim2.fromOffset(500, 400),
        Transparent = true,
        Theme = "Dark",
        -- Hapus OpenButton bawaan
        IsOpenButtonEnabled = false,
        User = {Enabled = true, Anonymous = true},
        UserEnabled = true,
        HasOutline = true,
        SideBarWidth = 150,
        ToggleKey = Enum.KeyCode.K, -- Tetap bisa toggle dengan K
    })
    
    -- Create Logo (pengganti OpenButton)
    local logoGui, logoButton = self:CreateLogo()
    
    self.GuiVisible = true
    logoButton.MouseButton1Click:Connect(function()
        self.GuiVisible = not self.GuiVisible
        if self.Window then
            pcall(function()
                if self.GuiVisible then
                    self.Window:Open()
                else
                    self.Window:Minimize()
                end
            end)
        end
    end)
    
    -- Create Tabs
    local InfoTab = self.Window:Tab({Title = "Info", Icon = "info"})
    local VisualsTab = self.Window:Tab({Title = "Visuals", Icon = "eye"})
    local PlayerTab = self.Window:Tab({Title = "Player", Icon = "user"})
    local CombatTab = self.Window:Tab({Title = "Combat", Icon = "swords"})
    local MiscTab = self.Window:Tab({Title = "Misc", Icon = "settings"})
    local CommunityTab = self.Window:Tab({Title = "Community", Icon = "users"})
    
    -- ============================================
    -- INFO TAB
    -- ============================================
    InfoTab:Section({ Title = "PINATHUB Information" })
    InfoTab:Paragraph({ Title = "Welcome to PINATHUB!", Desc = "Created by: @viunze on TikTok" })
    InfoTab:Divider()
    InfoTab:Section({ Title = "Supported Games" })
    InfoTab:Paragraph({ Title = "Violence District", Desc = "Full support for all features" })
    
    -- ============================================
    -- VISUALS TAB (ESP)
    -- ============================================
    VisualsTab:Section({ Title = "Player ESP" })
    VisualsTab:Toggle({ Title = "ESP Survivor (Name)", Value = config.Current.ESP_Survivor_Name, Callback = function(v) config.Set("ESP_Survivor_Name", v); esp.RefreshESP() end })
    VisualsTab:Toggle({ Title = "ESP Survivor (Highlight)", Value = config.Current.ESP_Survivor_Highlight, Callback = function(v) config.Set("ESP_Survivor_Highlight", v); esp.RefreshESP() end })
    VisualsTab:Toggle({ Title = "ESP Killer (Name)", Value = config.Current.ESP_Killer_Name, Callback = function(v) config.Set("ESP_Killer_Name", v); esp.RefreshESP() end })
    VisualsTab:Toggle({ Title = "ESP Killer (Highlight)", Value = config.Current.ESP_Killer_Highlight, Callback = function(v) config.Set("ESP_Killer_Highlight", v); esp.RefreshESP() end })
    VisualsTab:Divider()
    VisualsTab:Section({ Title = "Object ESP" })
    VisualsTab:Toggle({ Title = "ESP Generator", Value = config.Current.ESP_Generator, Callback = function(v) config.Set("ESP_Generator", v); esp.RefreshESP() end })
    VisualsTab:Toggle({ Title = "ESP Gate", Value = config.Current.ESP_Gate, Callback = function(v) config.Set("ESP_Gate", v); esp.RefreshESP() end })
    VisualsTab:Toggle({ Title = "ESP Pallet", Value = config.Current.ESP_Pallet, Callback = function(v) config.Set("ESP_Pallet", v); esp.RefreshESP() end })
    VisualsTab:Toggle({ Title = "ESP Hook", Value = config.Current.ESP_Hook, Callback = function(v) config.Set("ESP_Hook", v); esp.RefreshESP() end })
    VisualsTab:Toggle({ Title = "ESP SCP/Zombie", Value = config.Current.ESP_SCP, Callback = function(v) config.Set("ESP_SCP", v) end })
    VisualsTab:Divider()
    VisualsTab:Section({ Title = "Camera Settings" })
    VisualsTab:Toggle({ Title = "Custom FOV", Value = config.Current.CustomCameraFOV, Callback = function(v) config.Set("CustomCameraFOV", v) end })
    VisualsTab:Slider({ Title = "Field Of View", Value = { Min = 70, Max = 120, Default = config.Current.CameraFOVValue }, Callback = function(v) config.Set("CameraFOVValue", v) end })
    VisualsTab:Toggle({ Title = "FPP Mode", Value = config.Current.FPPEnabled, Callback = function(v) config.Set("FPPEnabled", v); player.SwitchCameraMode(v) end })
    VisualsTab:Toggle({ Title = "Show FOV Circle", Value = config.Current.ShowFOVCircle, Callback = function(v) config.Set("ShowFOVCircle", v) end })
    
    -- ============================================
    -- PLAYER TAB
    -- ============================================
    PlayerTab:Section({ Title = "Movement" })
    PlayerTab:Toggle({ Title = "Speed Boost", Value = config.Current.SpeedBoost, Callback = function(v) config.Set("SpeedBoost", v); local char = LocalPlayer.Character; local hum = char and char:FindFirstChild("Humanoid"); if hum then player.ApplySpeedBoost(hum) end end })
    PlayerTab:Slider({ Title = "Boost Power (%)", Value = { Min = 0, Max = 150, Default = config.Current.BoostSpeed }, Callback = function(v) config.Set("BoostSpeed", v); if config.Current.SpeedBoost then local char = LocalPlayer.Character; local hum = char and char:FindFirstChild("Humanoid"); if hum then player.ApplySpeedBoost(hum) end end end })
    PlayerTab:Toggle({ Title = "Moonwalk", Value = config.Current.MoonwalkEnabled, Callback = function(v) config.Set("MoonwalkEnabled", v); if not v then local char = LocalPlayer.Character; local hum = char and char:FindFirstChild("Humanoid"); if hum then hum.AutoRotate = true end end end })
    PlayerTab:Slider({ Title = "Moonwalk Intensity", Value = { Min = 5, Max = 50, Default = config.Current.MoonwalkZigzagSpeed }, Callback = function(v) config.Set("MoonwalkZigzagSpeed", v) end })
    PlayerTab:Slider({ Title = "Moonwalk Boost", Value = { Min = 1, Max = 1.5, Default = config.Current.MoonwalkBoostPower, Decimals = 2 }, Callback = function(v) config.Set("MoonwalkBoostPower", v) end })
    PlayerTab:Divider()
    PlayerTab:Section({ Title = "Utilities" })
    PlayerTab:Toggle({ Title = "Anti Fall Slow", Value = config.Current.AntiFallDamage, Callback = function(v) config.Set("AntiFallDamage", v) end })
    PlayerTab:Toggle({ Title = "Silent Actions", Value = config.Current.SilentActions, Callback = function(v) config.Set("SilentActions", v) end })
    PlayerTab:Toggle({ Title = "Notify Killer Stun", Value = config.Current.NotifyStun, Callback = function(v) config.Set("NotifyStun", v) end })
    PlayerTab:Button({ Title = "Force Reset State (Anti-Stuck)", Icon = "lucide:refresh-cw", Callback = function() misc.TriggerAntiStuck() end })
    
    -- ============================================
    -- COMBAT TAB
    -- ============================================
    CombatTab:Section({ Title = "Auto Parry" })
    CombatTab:Toggle({ Title = "Auto Parry", Value = config.Current.AutoParry, Callback = function(v) config.Set("AutoParry", v) end })
    CombatTab:Slider({ Title = "Parry Distance", Value = { Min = 3, Max = 25, Default = config.Current.ParryDistance }, Callback = function(v) config.Set("ParryDistance", v) end })
    CombatTab:Dropdown({ Title = "Killer Matchup", Values = { "Auto", "Abysswalker", "Hidden", "Killer", "Masked", "Stalker", "Veil", "Slasher", "Cure" }, Value = config.Current.ParryMatchup, Callback = function(v) config.Set("ParryMatchup", v) end })
    CombatTab:Slider({ Title = "Parry Delay (ms)", Value = { Min = -150, Max = 1000, Default = config.Current.ParryDelayOffset * 1000 }, Callback = function(v) config.Set("ParryDelayOffset", v / 1000) end })
    CombatTab:Divider()
    CombatTab:Section({ Title = "Aimbot" })
    CombatTab:Toggle({ Title = "Aimbot", Value = config.Current.Aimbot, Callback = function(v) config.Set("Aimbot", v) end })
    CombatTab:Dropdown({ Title = "Aimbot Target", Values = { "Head", "Torso", "Body (RootPart)" }, Value = config.Current.AimbotPart, Callback = function(v) config.Set("AimbotPart", v) end })
    CombatTab:Dropdown({ Title = "Aimbot Trigger", Values = { "Hold to Lock", "Auto Lock (Always)" }, Value = config.Current.AimbotTrigger, Callback = function(v) config.Set("AimbotTrigger", v) end })
    CombatTab:Slider({ Title = "Aim Radius", Value = { Min = 30, Max = 150, Default = config.Current.AimRadius }, Callback = function(v) config.Set("AimRadius", v) end })
    CombatTab:Slider({ Title = "Aim Distance", Value = { Min = 30, Max = 150, Default = config.Current.AimDistance }, Callback = function(v) config.Set("AimDistance", v) end })
    CombatTab:Slider({ Title = "Smoothness", Value = { Min = 1, Max = 20, Default = config.Current.AimbotSmoothness }, Callback = function(v) config.Set("AimbotSmoothness", v) end })
    CombatTab:Toggle({ Title = "Wall Check", Value = config.Current.WallCheck, Callback = function(v) config.Set("WallCheck", v) end })
    CombatTab:Divider()
    CombatTab:Section({ Title = "Misc Combat" })
    CombatTab:Toggle({ Title = "Silent Aim Pistol", Value = config.Current.SilentAimPistol, Callback = function(v) config.Set("SilentAimPistol", v); if not v then player.ResetScope() end end })
    CombatTab:Toggle({ Title = "Auto Attack (Killer)", Value = config.Current.AutoAttack, Callback = function(v) config.Set("AutoAttack", v) end })
    CombatTab:Slider({ Title = "Attack Range", Value = { Min = 5, Max = 25, Default = config.Current.AttackRange }, Callback = function(v) config.Set("AttackRange", v) end })
    CombatTab:Toggle({ Title = "Hitbox Expander", Value = config.Current.HitboxExpander, Callback = function(v) config.Set("HitboxExpander", v) end })
    CombatTab:Slider({ Title = "Hitbox Size", Value = { Min = 2, Max = 50, Default = config.Current.HitboxSize }, Callback = function(v) config.Set("HitboxSize", v) end })
    CombatTab:Toggle({ Title = "Double Damage Generator", Value = config.Current.DoubleDamageGen, Callback = function(v) config.Set("DoubleDamageGen", v) end })
    
    -- ============================================
    -- MISC TAB (DENGAN FITUR ALLOW JUMP)
    -- ============================================
    MiscTab:Section({ Title = "Generator" })
    MiscTab:Toggle({ Title = "Auto Generator", Value = config.Current.AutoGenerator, Callback = function(v) config.Set("AutoGenerator", v) end })
    MiscTab:Dropdown({ Title = "SkillCheck Mode", Values = { "Perfect", "Neutral" }, Value = config.Current.AutoGeneratorMode, Callback = function(v) config.Set("AutoGeneratorMode", v); if v == "Perfect" then config.Set("GeneratorPerfectOffsetStart", 102); config.Set("GeneratorPerfectOffsetEnd", 108) else config.Set("GeneratorPerfectOffsetStart", 102); config.Set("GeneratorPerfectOffsetEnd", 114) end end })
    MiscTab:Divider()
    MiscTab:Section({ Title = "Auto Farm" })
    MiscTab:Toggle({ Title = "Auto Play (AI Survivor)", Value = config.Current.AutoFarmBot, Callback = function(v) config.Set("AutoFarmBot", v); if v then config.Set("AutoGenerator", true); config.Set("AutoGeneratorMode", "Perfect") end end })
    MiscTab:Toggle({ Title = "Self Heal", Value = config.Current.SelfHeal, Callback = function(v) config.Set("SelfHeal", v) end })
    MiscTab:Divider()
    MiscTab:Section({ Title = "Movement Helper" })
    MiscTab:Toggle({ Title = "Allow Jump When Stuck", Desc = "Mengizinkan karakter untuk melompat saat terkena anti-stuck", Value = getgenv().ALLOW_JUMP_ON_STUCK or false, Callback = function(v) getgenv().ALLOW_JUMP_ON_STUCK = v end })
    MiscTab:Divider()
    MiscTab:Section({ Title = "Protection" })
    MiscTab:Toggle({ Title = "Anti-Logger", Value = config.Current.AntiLogger, Callback = function(v) config.Set("AntiLogger", v) end })
    MiscTab:Toggle({ Title = "Anti Aura", Value = getgenv().AntiAura or false, Callback = function(v) getgenv().AntiAura = v end })
    
    -- ============================================
    -- COMMUNITY TAB (SAMA PERSIS)
    -- ============================================
    CommunityTab:Section({ Title = "WhatsApp Group" })
    CommunityTab:Button({ Title = "Join WhatsApp Group", Callback = function()
        if setclipboard then
            setclipboard("https://chat.whatsapp.com/Cxr7poqqID6Ha6C2MfFOMU")
            WindUI:Notify({ Title = "Success", Content = "WhatsApp link copied to clipboard!", Icon = "lucide:check" })
        else
            WindUI:Notify({ Title = "Error", Content = "Clipboard not supported!", Icon = "lucide:x" })
        end
    end })
    
    CommunityTab:Section({ Title = "Discord Server" })
    CommunityTab:Button({ Title = "Join Discord Server", Callback = function()
        if setclipboard then
            setclipboard("https://discord.gg/eDbaHKEf7G")
            WindUI:Notify({ Title = "Success", Content = "Discord link copied to clipboard!", Icon = "lucide:check" })
        else
            WindUI:Notify({ Title = "Error", Content = "Clipboard not supported!", Icon = "lucide:x" })
        end
    end })
    
    CommunityTab:Section({ Title = "TikTok" })
    CommunityTab:Button({ Title = "Follow @viunze on TikTok", Callback = function()
        if setclipboard then
            setclipboard("https://www.tiktok.com/@viunze")
            WindUI:Notify({ Title = "Success", Content = "TikTok link copied to clipboard!", Icon = "lucide:check" })
        else
            WindUI:Notify({ Title = "Error", Content = "Clipboard not supported!", Icon = "lucide:x" })
        end
    end })
    
    self.Window:Open()
    print("UI initialized successfully!")
    
    return self
end

return UI
