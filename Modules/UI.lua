-- =======================================================
-- PINATHUB - UI MODULE (WINDUI SWING OBBY BRAINROT STYLE)
-- =======================================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

local UI = {}
UI.GuiVisible = true
UI.Window = nil
UI.WindUI = nil
UI.TargetGui = nil
UI.Modules = nil
UI.FOVCircle = nil
UI.ParryRing = nil
UI.MobileRotateBtn = nil

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
    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(1, 0)
    uiCorner.Parent = logoButton
    local hoverTween = TweenService:Create(logoButton, TweenInfo.new(0.2), { Size = UDim2.new(0, 60, 0, 60) })
    local unhoverTween = TweenService:Create(logoButton, TweenInfo.new(0.2), { Size = UDim2.new(0, 50, 0, 50) })
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
                if input.UserInputState == Enum.UserInputState.End then draggingLogo = false end
            end)
        end
    end)
    logoButton.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInputLogo = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInputLogo and draggingLogo then
            local delta = input.Position - dragStartLogo
            local newPos = UDim2.new(startPosLogo.X.Scale, startPosLogo.X.Offset + delta.X, startPosLogo.Y.Scale, startPosLogo.Y.Offset + delta.Y)
            logoButton.Position = newPos
        end
    end)
    return logoGui, logoButton
end

function UI:SetupFOVCircle()
    local IndicatorGui = UI.TargetGui:FindFirstChild("PINATHUB_Indicator") or Instance.new("ScreenGui")
    IndicatorGui.Name = "PINATHUB_Indicator"
    IndicatorGui.IgnoreGuiInset = true
    IndicatorGui.ResetOnSpawn = false
    IndicatorGui.Parent = UI.TargetGui
    if IndicatorGui:FindFirstChild("FOVCircle") then IndicatorGui.FOVCircle:Destroy() end
    UI.FOVCircle = Instance.new("Frame", IndicatorGui)
    UI.FOVCircle.Name = "FOVCircle"
    UI.FOVCircle.Size = UDim2.new(0, UI.Modules.Config.Current.AimRadius * 2, 0, UI.Modules.Config.Current.AimRadius * 2)
    UI.FOVCircle.AnchorPoint = Vector2.new(0.5, 0.5)
    UI.FOVCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
    UI.FOVCircle.BackgroundTransparency = 1
    UI.FOVCircle.Visible = UI.Modules.Config.Current.ShowFOVCircle
    local corner = Instance.new("UICorner", UI.FOVCircle)
    corner.CornerRadius = UDim.new(1, 0)
    local stroke = Instance.new("UIStroke", UI.FOVCircle)
    stroke.Color = Color3.new(1, 1, 1)
    stroke.Transparency = 0.5
    stroke.Thickness = 1.5
end

function UI:SetupParryRing()
    local oldRing = UI.TargetGui:FindFirstChild("PINATHUB_ParryRing")
    if oldRing then oldRing:Destroy() end
    UI.ParryRing = Instance.new("CylinderHandleAdornment")
    UI.ParryRing.Name = "PINATHUB_ParryRing"
    UI.ParryRing.Color3 = Color3.fromRGB(170, 40, 255)
    UI.ParryRing.Transparency = 0.7
    UI.ParryRing.AlwaysOnTop = true
    UI.ParryRing.ZIndex = 10
    UI.ParryRing.Height = 0.05
    UI.ParryRing.Radius = UI.Modules.Config.Current.ParryDistance or 10
    UI.ParryRing.CFrame = CFrame.new(0, -2.8, 0) * CFrame.Angles(math.rad(90), 0, 0)
    UI.ParryRing.Adornee = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    UI.ParryRing.Parent = UI.TargetGui
end

function UI:SetupCrosshair()
    if UI.TargetGui:FindFirstChild("PinatCrosshair") then UI.TargetGui.PinatCrosshair:Destroy() end
    getgenv().CrosshairGui = Instance.new("ScreenGui")
    getgenv().CrosshairGui.Name = "PinatCrosshair"
    getgenv().CrosshairGui.IgnoreGuiInset = true
    getgenv().CrosshairGui.ResetOnSpawn = false
    getgenv().CrosshairGui.Enabled = false
    getgenv().CrosshairGui.Parent = UI.TargetGui
    local crosshair = Instance.new("ImageLabel")
    crosshair.Name = "Crosshair"
    crosshair.Parent = getgenv().CrosshairGui
    crosshair.AnchorPoint = Vector2.new(0.5, 0.5)
    crosshair.Position = UDim2.new(0.5, 0, 0.5, 0)
    crosshair.Size = UDim2.new(0, 28, 0, 28)
    crosshair.BackgroundTransparency = 1
    crosshair.ImageColor3 = Color3.fromRGB(255, 255, 255)
    crosshair.Image = "rbxassetid://9943168532"
end

function UI:SetupMobileUI()
    local isMobileDevice = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
    if not isMobileDevice then return end
    local coreSuccess, coreResult = pcall(function() return cloneref(game:GetService("CoreGui")) end)
    local SafeGuiFolder = coreSuccess and coreResult or LocalPlayer:WaitForChild("PlayerGui")
    local combatGui = SafeGuiFolder:FindFirstChild("PINATHUB_MobileButtons") or Instance.new("ScreenGui")
    combatGui.Name = "PINATHUB_MobileButtons"
    combatGui.ResetOnSpawn = false
    combatGui.IgnoreGuiInset = true
    combatGui.Parent = SafeGuiFolder
    UI.MobileRotateBtn = combatGui:FindFirstChild("RotateBtn") or Instance.new("TextButton")
    UI.MobileRotateBtn.Name = "RotateBtn"
    UI.MobileRotateBtn.Size = UDim2.new(0, 65, 0, 65)
    UI.MobileRotateBtn.Position = UDim2.new(1, -85, 0.5, 30)
    UI.MobileRotateBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    UI.MobileRotateBtn.BackgroundTransparency = 0.15
    UI.MobileRotateBtn.AutoButtonColor = false
    UI.MobileRotateBtn.Text = "TPP"
    UI.MobileRotateBtn.TextColor3 = Color3.new(1, 1, 1)
    UI.MobileRotateBtn.Font = Enum.Font.GothamBlack
    UI.MobileRotateBtn.TextSize = 16
    UI.MobileRotateBtn.Visible = false
    UI.MobileRotateBtn.Parent = combatGui
    for _, child in ipairs(UI.MobileRotateBtn:GetChildren()) do child:Destroy() end
    local corner = Instance.new("UICorner", UI.MobileRotateBtn)
    corner.CornerRadius = UDim.new(1, 0)
    local stroke = Instance.new("UIStroke", UI.MobileRotateBtn)
    stroke.Thickness = 2.5
    stroke.Color = Color3.fromRGB(75, 150, 255)
    local grad = Instance.new("UIGradient", UI.MobileRotateBtn)
    grad.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 150, 150)) })
    grad.Rotation = 45
    local isFPP = false
    UI.MobileRotateBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            UI.MobileRotateBtn.Size = UDim2.new(0, 58, 0, 58)
        end
    end)
    UI.MobileRotateBtn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            UI.MobileRotateBtn.Size = UDim2.new(0, 65, 0, 65)
            isFPP = not isFPP
            UI.Modules.Player.SwitchCameraMode(isFPP)
            stroke.Color = isFPP and Color3.fromRGB(255, 100, 50) or Color3.fromRGB(75, 150, 255)
            UI.MobileRotateBtn.Text = isFPP and "FPP" or "TPP"
        end
    end)
end

function UI:BuildWindow()
    local popupClosed = false
    UI.WindUI:Popup({
        Title = gradient("PINATHUB V2", Color3.fromHex("#FFFFFF"), Color3.fromHex("#9CA3AF")),
        Icon = "rbxassetid://12797629733",
        Content = table.concat({ "Welcome to PINATHUB.", "Violence District script loaded.", "━━━━━━━━━━━━━━━━━━", "🖥️ PC: Press [K] to toggle", "📱 Mobile: Use floating button", "━━━━━━━━━━━━━━━━━━", "Status: Ready" }, "\n"),
        Buttons = {
            { Title = "Close", Icon = "lucide:shield", Variant = "Primary", Callback = function() popupClosed = true end },
            { Title = "Enter Hub", Icon = "lucide:shield", Variant = "Tertiary", Callback = function() popupClosed = true end }
        }
    })
    repeat task.wait() until popupClosed
    UI.Window = UI.WindUI:CreateWindow({
        Title = "<b>" .. gradient("PINATHUB", Color3.fromHex("#FFFFFF"), Color3.fromHex("#8F8F8F")) .. "</b>",
        Author = gradient("@viunze on tiktok", Color3.fromHex("#D4D4D4"), Color3.fromHex("#7A7A7A")),
        Icon = "rbxassetid://109078275720644",
        Theme = "Dark",
        Size = UDim2.fromOffset(600, 420),
        MinSize = Vector2.new(460, 320),
        MaxSize = Vector2.new(760, 520),
        Resizable = true,
        Transparent = false,
        NewElements = true,
        ElementsRadius = 10,
        SideBarWidth = 170,
        TopBarButtonIconSize = 18,
        HideSearchBar = true,
        IgnoreAlerts = true,
        Folder = "PinatHubV2",
        ToggleKey = Enum.KeyCode.K,
        OpenButton = {
            Title = gradient("PINATHUB", Color3.fromHex("#FFFFFF"), Color3.fromHex("#C7D2FE")),
            Icon = "rbxassetid://106965358654204",
            Enabled = true,
            Draggable = true,
            OnlyMobile = false,
            CornerRadius = UDim.new(1, 0),
            StrokeThickness = 1.6,
            Scale = 0.82,
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromHex("#353538")),
                ColorSequenceKeypoint.new(0.35, Color3.fromHex("#8B5CF6")),
                ColorSequenceKeypoint.new(0.7, Color3.fromHex("#A855F7")),
                ColorSequenceKeypoint.new(1, Color3.fromHex("#353538"))
            })
        },
        Topbar = { Height = 42, ButtonsType = "Default" }
    })
end

function UI:BuildTabs()
    local tabInfo = UI.Window:Tab({ Title = "Info", Icon = "lucide:info" })
    local tabVisuals = UI.Window:Tab({ Title = "Visuals", Icon = "lucide:eye" })
    local tabPlayer = UI.Window:Tab({ Title = "Player", Icon = "lucide:user" })
    local tabCombat = UI.Window:Tab({ Title = "Combat", Icon = "lucide:sword" })
    local tabGenerator = UI.Window:Tab({ Title = "Generator", Icon = "lucide:bot" })
    local tabMisc = UI.Window:Tab({ Title = "Misc", Icon = "lucide:settings" })
    
    tabInfo:Section({ Title = "PINATHUB Information" })
    tabInfo:Paragraph({ Title = "Welcome to PINATHUB!", Desc = "Created by: @viunze on TikTok" })
    tabInfo:Divider()
    tabInfo:Section({ Title = "Supported Games" })
    tabInfo:Paragraph({ Title = "Violence District", Desc = "Full support for all features" })
    
    local config = UI.Modules.Config
    local esp = UI.Modules.ESP
    local player = UI.Modules.Player
    local combat = UI.Modules.Combat
    local misc = UI.Modules.Misc
    
    tabVisuals:Section({ Title = "Player ESP" })
    tabVisuals:Toggle({ Title = "ESP Survivor (Name)", Value = config.Current.ESP_Survivor_Name, Callback = function(v) config.Set("ESP_Survivor_Name", v); esp.RefreshESP() end })
    tabVisuals:Toggle({ Title = "ESP Survivor (Highlight)", Value = config.Current.ESP_Survivor_Highlight, Callback = function(v) config.Set("ESP_Survivor_Highlight", v); esp.RefreshESP() end })
    tabVisuals:Toggle({ Title = "ESP Killer (Name)", Value = config.Current.ESP_Killer_Name, Callback = function(v) config.Set("ESP_Killer_Name", v); esp.RefreshESP() end })
    tabVisuals:Toggle({ Title = "ESP Killer (Highlight)", Value = config.Current.ESP_Killer_Highlight, Callback = function(v) config.Set("ESP_Killer_Highlight", v); esp.RefreshESP() end })
    tabVisuals:Divider()
    tabVisuals:Section({ Title = "Object ESP" })
    tabVisuals:Toggle({ Title = "ESP Generator", Value = config.Current.ESP_Generator, Callback = function(v) config.Set("ESP_Generator", v); esp.RefreshESP() end })
    tabVisuals:Toggle({ Title = "ESP Gate", Value = config.Current.ESP_Gate, Callback = function(v) config.Set("ESP_Gate", v); esp.RefreshESP() end })
    tabVisuals:Toggle({ Title = "ESP Pallet", Value = config.Current.ESP_Pallet, Callback = function(v) config.Set("ESP_Pallet", v); esp.RefreshESP() end })
    tabVisuals:Toggle({ Title = "ESP Hook", Value = config.Current.ESP_Hook, Callback = function(v) config.Set("ESP_Hook", v); esp.RefreshESP() end })
    tabVisuals:Toggle({ Title = "ESP SCP/Zombie", Value = config.Current.ESP_SCP, Callback = function(v) config.Set("ESP_SCP", v) end })
    tabVisuals:Divider()
    tabVisuals:Section({ Title = "Camera Settings" })
    tabVisuals:Toggle({ Title = "Custom FOV", Value = config.Current.CustomCameraFOV, Callback = function(v) config.Set("CustomCameraFOV", v) end })
    tabVisuals:Slider({ Title = "Field Of View", Value = { Min = 70, Max = 120, Default = config.Current.CameraFOVValue }, Callback = function(v) config.Set("CameraFOVValue", v) end })
    tabVisuals:Toggle({ Title = "FPP Mode", Value = config.Current.FPPEnabled, Callback = function(v) config.Set("FPPEnabled", v); player.SwitchCameraMode(v) end })
    tabVisuals:Toggle({ Title = "Show FOV Circle", Value = config.Current.ShowFOVCircle, Callback = function(v) config.Set("ShowFOVCircle", v); if UI.FOVCircle then UI.FOVCircle.Visible = v end end })
    
    tabPlayer:Section({ Title = "Movement" })
    tabPlayer:Toggle({ Title = "Speed Boost", Value = config.Current.SpeedBoost, Callback = function(v) config.Set("SpeedBoost", v); local char = LocalPlayer.Character; local hum = char and char:FindFirstChild("Humanoid"); if hum then player.ApplySpeedBoost(hum) end end })
    tabPlayer:Slider({ Title = "Boost Power (%)", Value = { Min = 0, Max = 150, Default = config.Current.BoostSpeed }, Callback = function(v) config.Set("BoostSpeed", v); if config.Current.SpeedBoost then local char = LocalPlayer.Character; local hum = char and char:FindFirstChild("Humanoid"); if hum then player.ApplySpeedBoost(hum) end end end })
    tabPlayer:Toggle({ Title = "Moonwalk", Value = config.Current.MoonwalkEnabled, Callback = function(v) config.Set("MoonwalkEnabled", v); if not v then local char = LocalPlayer.Character; local hum = char and char:FindFirstChild("Humanoid"); if hum then hum.AutoRotate = true end end end })
    tabPlayer:Slider({ Title = "Moonwalk Intensity", Value = { Min = 5, Max = 50, Default = config.Current.MoonwalkZigzagSpeed }, Callback = function(v) config.Set("MoonwalkZigzagSpeed", v) end })
    tabPlayer:Slider({ Title = "Moonwalk Boost", Value = { Min = 1, Max = 1.5, Default = config.Current.MoonwalkBoostPower, Decimals = 2 }, Callback = function(v) config.Set("MoonwalkBoostPower", v) end })
    tabPlayer:Divider()
    tabPlayer:Section({ Title = "Utilities" })
    tabPlayer:Toggle({ Title = "Anti Fall Slow", Value = config.Current.AntiFallDamage, Callback = function(v) config.Set("AntiFallDamage", v) end })
    tabPlayer:Toggle({ Title = "Silent Actions", Value = config.Current.SilentActions, Callback = function(v) config.Set("SilentActions", v) end })
    tabPlayer:Toggle({ Title = "Notify Killer Stun", Value = config.Current.NotifyStun, Callback = function(v) config.Set("NotifyStun", v) end })
    tabPlayer:Button({ Title = "Force Reset State (Anti-Stuck)", Icon = "lucide:refresh-cw", Callback = function() misc.TriggerAntiStuck() end })
    
    tabCombat:Section({ Title = "Auto Parry" })
    tabCombat:Toggle({ Title = "Auto Parry", Value = config.Current.AutoParry, Callback = function(v) config.Set("AutoParry", v) end })
    tabCombat:Slider({ Title = "Parry Distance", Value = { Min = 3, Max = 25, Default = config.Current.ParryDistance }, Callback = function(v) config.Set("ParryDistance", v); if UI.ParryRing then UI.ParryRing.Radius = v end end })
    tabCombat:Dropdown({ Title = "Killer Matchup", Values = { "Auto", "Abysswalker", "Hidden", "Killer", "Masked", "Stalker", "Veil", "Slasher", "Cure" }, Value = config.Current.ParryMatchup, Callback = function(v) config.Set("ParryMatchup", v) end })
    tabCombat:Slider({ Title = "Parry Delay (ms)", Value = { Min = -150, Max = 1000, Default = config.Current.ParryDelayOffset * 1000 }, Callback = function(v) config.Set("ParryDelayOffset", v / 1000) end })
    tabCombat:Divider()
    tabCombat:Section({ Title = "Aimbot" })
    tabCombat:Toggle({ Title = "Aimbot", Value = config.Current.Aimbot, Callback = function(v) config.Set("Aimbot", v) end })
    tabCombat:Dropdown({ Title = "Aimbot Target", Values = { "Head", "Torso", "Body (RootPart)" }, Value = config.Current.AimbotPart, Callback = function(v) config.Set("AimbotPart", v) end })
    tabCombat:Dropdown({ Title = "Aimbot Trigger", Values = { "Hold to Lock", "Auto Lock (Always)" }, Value = config.Current.AimbotTrigger, Callback = function(v) config.Set("AimbotTrigger", v) end })
    tabCombat:Slider({ Title = "Aim Radius", Value = { Min = 30, Max = 150, Default = config.Current.AimRadius }, Callback = function(v) config.Set("AimRadius", v); if UI.FOVCircle then UI.FOVCircle.Size = UDim2.new(0, v * 2, 0, v * 2) end end })
    tabCombat:Slider({ Title = "Aim Distance", Value = { Min = 30, Max = 150, Default = config.Current.AimDistance }, Callback = function(v) config.Set("AimDistance", v) end })
    tabCombat:Slider({ Title = "Smoothness", Value = { Min = 1, Max = 20, Default = config.Current.AimbotSmoothness }, Callback = function(v) config.Set("AimbotSmoothness", v) end })
    tabCombat:Toggle({ Title = "Wall Check", Value = config.Current.WallCheck, Callback = function(v) config.Set("WallCheck", v) end })
    tabCombat:Divider()
    tabCombat:Section({ Title = "Misc Combat" })
    tabCombat:Toggle({ Title = "Silent Aim Pistol", Value = config.Current.SilentAimPistol, Callback = function(v) config.Set("SilentAimPistol", v); if not v then player.ResetScope() end end })
    tabCombat:Toggle({ Title = "Auto Attack (Killer)", Value = config.Current.AutoAttack, Callback = function(v) config.Set("AutoAttack", v) end })
    tabCombat:Slider({ Title = "Attack Range", Value = { Min = 5, Max = 25, Default = config.Current.AttackRange }, Callback = function(v) config.Set("AttackRange", v) end })
    tabCombat:Toggle({ Title = "Hitbox Expander", Value = config.Current.HitboxExpander, Callback = function(v) config.Set("HitboxExpander", v) end })
    tabCombat:Slider({ Title = "Hitbox Size", Value = { Min = 2, Max = 50, Default = config.Current.HitboxSize }, Callback = function(v) config.Set("HitboxSize", v) end })
    tabCombat:Toggle({ Title = "Double Damage Generator", Value = config.Current.DoubleDamageGen, Callback = function(v) config.Set("DoubleDamageGen", v) end })
    
    tabGenerator:Section({ Title = "Generator" })
    tabGenerator:Toggle({ Title = "Auto Generator", Value = config.Current.AutoGenerator, Callback = function(v) config.Set("AutoGenerator", v) end })
    tabGenerator:Dropdown({ Title = "SkillCheck Mode", Values = { "Perfect", "Neutral" }, Value = config.Current.AutoGeneratorMode, Callback = function(v) config.Set("AutoGeneratorMode", v); if v == "Perfect" then config.Set("GeneratorPerfectOffsetStart", 102); config.Set("GeneratorPerfectOffsetEnd", 108) else config.Set("GeneratorPerfectOffsetStart", 102); config.Set("GeneratorPerfectOffsetEnd", 114) end end })
    
    tabMisc:Section({ Title = "Auto Farm" })
    tabMisc:Toggle({ Title = "Auto Play (AI Survivor)", Value = config.Current.AutoFarmBot, Callback = function(v) config.Set("AutoFarmBot", v); if v then config.Set("AutoGenerator", true); config.Set("AutoGeneratorMode", "Perfect") end end })
    tabMisc:Toggle({ Title = "Self Heal", Value = config.Current.SelfHeal, Callback = function(v) config.Set("SelfHeal", v) end })
    tabMisc:Divider()
    tabMisc:Section({ Title = "Protection" })
    tabMisc:Toggle({ Title = "Anti-Logger", Value = config.Current.AntiLogger, Callback = function(v) config.Set("AntiLogger", v) end })
    tabMisc:Toggle({ Title = "Anti Aura", Value = getgenv().AntiAura or false, Callback = function(v) getgenv().AntiAura = v end })
end

function UI:Init()
    self:SetupFOVCircle()
    self:SetupParryRing()
    self:SetupCrosshair()
    self:SetupMobileUI()
    self:BuildWindow()
    self:BuildTabs()
    local logoGui, logoButton = self:CreateLogo()
    logoButton.MouseButton1Click:Connect(function()
        self.GuiVisible = not self.GuiVisible
        if self.Window then
            pcall(function()
                if self.GuiVisible then self.Window:Open() else self.Window:Minimize() end
            end)
        end
    end)
    self.Window:Open()
    print("[PINATHUB] UI initialized successfully!")
end

return UI
