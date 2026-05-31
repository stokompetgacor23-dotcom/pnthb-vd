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

-- ============================================================
-- COLOR3 FROMHEX COMPATIBILITY
-- ============================================================
local function fromHex(hex)
    hex = hex:gsub("#", "")
    local r = tonumber(hex:sub(1,2), 16) or 0
    local g = tonumber(hex:sub(3,4), 16) or 0
    local b = tonumber(hex:sub(5,6), 16) or 0
    return Color3.fromRGB(r, g, b)
end

-- ============================================================
-- GRADIENT HELPER (Smooth Wave Neon Style)
-- ============================================================
local function gradient(text, color1, color2, speed)
    if type(text) ~= "string" or text == "" then return "" end
    if not color1 or not color2 then return text end
    if not speed then speed = 3.5 end
    
    local chars = {}
    for _, c in utf8.codes(text) do 
        table.insert(chars, utf8.char(c)) 
    end
    
    local len = #chars
    local result = table.create(len)
    local t = os.clock() * speed
    
    for i = 1, len do
        local wave = math.sin(t - (i * 0.5))
        local leraRatio = (wave + 1) / 2
        local blendedColor = color1:Lerp(color2, leraRatio)
        result[i] = string.format('<font color="#%s">%s</font>', blendedColor:ToHex(), chars[i])
    end
    
    return table.concat(result)
end

-- ============================================================
-- ANIMATED TITLE (Neon Purple & Gray Wave Moving)
-- ============================================================
local titleAnimationConnection = nil

local function startTitleAnimation(window)
    if titleAnimationConnection then return end
    
    local NeonPurple = fromHex("#A855F7")
    local NeonGray   = fromHex("#9CA3AF")
    local AnimSpeed  = 3.5

    titleAnimationConnection = game:GetService("RunService").RenderStepped:Connect(function()
        if not window or not window.SetTitle then 
            if titleAnimationConnection then 
                titleAnimationConnection:Disconnect() 
            end
            titleAnimationConnection = nil
            return
        end
        
        local animatedText = gradient("PINATHUB", NeonPurple, NeonGray, AnimSpeed)
        pcall(function() window:SetTitle("<b>" .. animatedText .. "</b>") end)
    end)
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
-- SAFE NOTIFY HELPER
-- ============================================
local function safeNotify(window, windui, title, msg, duration)
    pcall(function()
        if window and window.Notify then
            window:Notify(title, msg, duration)
        elseif window and window.Notification then
            window:Notification(title, msg, duration)
        elseif windui and windui.Notify then
            windui:Notify(title, msg, duration)
        elseif windui and windui.Notification then
            windui:Notification(title, msg, duration)
        end
    end)
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
-- SHOW WELCOME POPUP (SEDERHANA, TANPA EMOJI)
-- ============================================
function UI:ShowWelcomePopup(callback)
    local popupClosed = false
    
    local hotkeysText = [[
HOTKEYS

PC / LAPTOP
  - Press [K] -> Toggle GUI
  - Press [R] -> Toggle Moonwalk
  - Press [L] -> Anti-Stuck

MOBILE
  - Tap floating logo -> Toggle GUI
  - Tap Moonwalk button -> Toggle Moonwalk

PINATHUB - BY @viunze
]]
    
    pcall(function()
        self.WindUI:Popup({
            Title = gradient("PINATHUB", fromHex("#8B5CF6"), fromHex("#C084FC"), 3.5),
            Icon = "rbxassetid://118264723961739",
            Content = hotkeysText,
            Buttons = {
                {
                    Title = "Continue to Hub",
                    Icon = "lucide:shield",
                    Variant = "Primary",
                    Callback = function()
                        popupClosed = true
                        if callback then callback() end
                    end
                }
            }
        })
    end)
    
    -- Timeout fallback: jika popup tidak support atau gagal, lanjut otomatis setelah 3 detik
    task.delay(3, function()
        popupClosed = true
    end)
    
    repeat task.wait() until popupClosed
end

-- ============================================
-- SHOW HOTKEYS NOTIFICATION
-- ============================================
function UI:ShowHotkeysNotification()
    task.wait(1.5)
    safeNotify(self.Window, self.WindUI, "Hotkeys", "K = Toggle GUI | R = Moonwalk | L = Anti-Stuck", 5)
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
    
    -- SHOW WELCOME POPUP TERLEBIH DAHULU
    self:ShowWelcomePopup()
    
    -- CREATE WINDOW (Brainrot Style)
    self.Window = WindUI:CreateWindow({
        Title = "<b>PINATHUB</b>",
        Author = "@viunze on tiktok",
        Folder = "pinathub",
        Size = UDim2.fromOffset(500, 400),
        Transparent = true,
        Theme = "Dark",
        IsOpenButtonEnabled = false,
        UserEnabled = true,
        HasOutline = true,
        SideBarWidth = 150,
        ToggleKey = Enum.KeyCode.K,
    })
    
    -- Start animated title
    startTitleAnimation(self.Window)
    
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
    
    -- SETUP HOTKEYS NOTIFICATION
    self:ShowHotkeysNotification()
    
    -- SETUP KEYBINDS (R untuk Moonwalk, L untuk Anti-Stuck)
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.R then
            local newState = not config.Current.MoonwalkEnabled
            config.Set("MoonwalkEnabled", newState)
            if not newState then
                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChild("Humanoid")
                if hum then hum.AutoRotate = true end
            end
            safeNotify(self.Window, self.WindUI, "Moonwalk", newState and "ON" or "OFF", 1)
        end
        
        if input.KeyCode == Enum.KeyCode.L then
            misc.TriggerAntiStuck()
            safeNotify(self.Window, self.WindUI, "Anti-Stuck", "Triggered!", 1)
        end
    end)
    
    -- TABS (PINATHUB Features)
    local CombatTab = self.Window:Tab({ Title = "Combat", Icon = "sword" })
    local VisualsTab = self.Window:Tab({ Title = "Visuals", Icon = "eye" })
    local PlayerTab = self.Window:Tab({ Title = "Player", Icon = "user" })
    local MiscTab = self.Window:Tab({ Title = "Misc", Icon = "settings" })
    local CommunityTab = self.Window:Tab({ Title = "Community", Icon = "users" })
    
    -- ============================================
    -- COMBAT TAB
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
    -- VISUALS TAB
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
    -- PLAYER TAB
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
    -- MISC TAB
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
    
    local jumpSection = MiscTab:Section({ Title = "Jump" })
    local jumpEnabled = false
    jumpSection:Toggle({ 
        Title = "Allow Jump", 
        Desc = "Allow Jump if game has Anti Jump",
        Value = false, 
        Callback = function(v)
            jumpEnabled = v
            if v then
                if player.EnableAllowJump then
                    player.EnableAllowJump()
                end
                safeNotify(self.Window, self.WindUI, "Allow Jump", "Jumping force-enabled! Press Space to jump.", 2)
            else
                if player.DisableAllowJump then
                    player.DisableAllowJump()
                end
                safeNotify(self.Window, self.WindUI, "Allow Jump", "Jumping restored to normal", 2)
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
                safeNotify(self.Window, self.WindUI, "Copied!", "WhatsApp link copied!", 2)
            end
        end
    })
    
    communitySection:Button({
        Title = "Discord Server",
        Callback = function()
            if set_clipboard then
                set_clipboard("https://discord.gg/eDbaHKEf7G")
                safeNotify(self.Window, self.WindUI, "Copied!", "Discord link copied!", 2)
            end
        end
    })
    
    communitySection:Button({
        Title = "TikTok @viunze",
        Callback = function()
            if set_clipboard then
                set_clipboard("https://tiktok.com/@viunze")
                safeNotify(self.Window, self.WindUI, "Copied!", "TikTok profile copied!", 2)
            end
        end
    })
    
    -- OPEN WINDOW
    pcall(function() self.Window:Open() end)
    task.wait(0.5)
    safeNotify(self.Window, self.WindUI, "PINATHUB", "Loaded! Press K to toggle GUI | R = Moonwalk | L = Anti-Stuck", 5)
    
    print("PINATHUB Loaded")
    
    return self
end

return UI
