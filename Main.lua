-- =======================================================
-- PINATHUB - MAIN ENTRY POINT
-- =======================================================
-- Author: @viunze on tiktok
-- Architecture: Clean Modular with WindUI Swing Obby Brainrot Style
-- =======================================================

-- =========================================================
-- ANTI MEMORY LEAK & INITIALIZATION
-- =========================================================
if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Stats = game:GetService("Stats")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Lighting = game:GetService("Lighting")
local PathfindingService = game:GetService("PathfindingService")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer

-- Wait for essential services
while not LocalPlayer do task.wait() end
while not workspace.CurrentCamera do task.wait() end

-- Safe cloneref for all services
local cloneref = (cloneref or clonereference or function(v) return v end)

-- Cloneref services for safety
local RunServiceRef = cloneref(RunService)
local UserInputServiceRef = cloneref(UserInputService)
local LightingRef = cloneref(Lighting)
local StatsRef = cloneref(Stats)
local VirtualInputManagerRef = cloneref(VirtualInputManager)
local CoreGuiRef = cloneref(CoreGui)
local ReplicatedStorageRef = cloneref(ReplicatedStorage)
local PathfindingServiceRef = cloneref(PathfindingService)

-- =========================================================
-- GLOBAL STATE
-- =========================================================
getgenv().PINATHUB_RUNNING = true
getgenv().PINATHUB_CONNECTIONS = getgenv().PINATHUB_CONNECTIONS or {}

-- Clear previous connections
for _, conn in ipairs(getgenv().PINATHUB_CONNECTIONS) do
    pcall(function()
        if conn and conn.Disconnect then
            conn:Disconnect()
        end
    end)
end
table.clear(getgenv().PINATHUB_CONNECTIONS)

-- =========================================================
-- GET UI PARENT
-- =========================================================
local function GetUIParent()
    local ok, res = pcall(function()
        if gethui then
            return gethui()
        end
        if syn and syn.protect_gui then
            local gui = Instance.new("ScreenGui")
            syn.protect_gui(gui)
            gui.Parent = CoreGuiRef
            return gui
        end
        return CoreGuiRef
    end)
    return ok and res or CoreGuiRef
end

local TargetGui = GetUIParent()

-- =========================================================
-- LOAD WINDUI
-- =========================================================
local WindUI
do
    local src
    local ok, res = pcall(function()
        return game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua")
    end)
    if ok and res then
        src = res
    end
    
    if src then
        local ok2, res2 = pcall(function()
            return loadstring(src)()
        end)
        if ok2 then
            WindUI = res2
        end
    end
end

if WindUI then
    print("[PINATHUB] WindUI Loaded")
else
    warn("[PINATHUB] Failed Load WindUI")
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "PINATHUB",
            Text = "Failed loading WindUI"
        })
    end)
    return
end

-- =========================================================
-- LOAD MODULES FROM REPSTORAGE
-- =========================================================
local PinatHubFolder = ReplicatedStorageRef:FindFirstChild("PinatHub")
if not PinatHubFolder then
    PinatHubFolder = Instance.new("Folder")
    PinatHubFolder.Name = "PinatHub"
    PinatHubFolder.Parent = ReplicatedStorageRef
end

local ModulesFolder = PinatHubFolder:FindFirstChild("Modules")
if not ModulesFolder then
    ModulesFolder = Instance.new("Folder")
    ModulesFolder.Name = "Modules"
    ModulesFolder.Parent = PinatHubFolder
end

-- Function to require or load module
local function LoadModule(moduleName)
    local module = ModulesFolder:FindFirstChild(moduleName)
    if module and module:IsA("ModuleScript") then
        return require(module)
    end
    error("Module not found: " .. moduleName)
end

-- Load all modules
local Modules = {
    Utils = LoadModule("Utils"),
    Config = LoadModule("Config"),
    ESP = LoadModule("ESP"),
    Player = LoadModule("Player"),
    Combat = LoadModule("Combat"),
    Misc = LoadModule("Misc"),
    UI = LoadModule("UI")
}

-- =========================================================
-- INJECT DEPENDENCIES
-- =========================================================
Modules.ESP.Utils = Modules.Utils
Modules.ESP.Config = Modules.Config
Modules.ESP.WindUI = WindUI
Modules.ESP.TargetGui = TargetGui

Modules.Player.Utils = Modules.Utils
Modules.Player.Config = Modules.Config

Modules.Combat.Utils = Modules.Utils
Modules.Combat.Config = Modules.Config
Modules.Combat.Player = Modules.Player

Modules.Misc.Utils = Modules.Utils
Modules.Misc.Config = Modules.Config
Modules.Misc.ESP = Modules.ESP
Modules.Misc.WindUI = WindUI
Modules.Misc.VirtualInputManager = VirtualInputManagerRef
Modules.Misc.UserInputService = UserInputServiceRef
Modules.Misc.ReplicatedStorage = ReplicatedStorageRef
Modules.Misc.Stats = StatsRef
Modules.Misc.PathfindingService = PathfindingServiceRef
Modules.Misc.TargetGui = TargetGui

-- =========================================================
-- INITIALIZE MODULES
-- =========================================================

-- Initialize ESP
Modules.ESP.InitSCPFolder()
Modules.ESP.StartMapDetector()
Modules.ESP.UpdateSCPLoop()
Modules.ESP.ConnectSCP()
Modules.ESP.ScanSCP()

-- Initialize Combat
Modules.Combat.StartAutoAttackLoop()

-- Initialize Misc
Modules.Misc.StartAutoGenerator()
Modules.Misc.StartAntiStuckThread()
Modules.Misc.StartAutoFarmAI()
Modules.Misc.SetupNamecallHook()

-- =========================================================
-- INITIALIZE UI
-- =========================================================
local UI = Modules.UI
UI.WindUI = WindUI
UI.TargetGui = TargetGui
UI.Modules = Modules

UI:Init()

-- =========================================================
-- RENDER STEP CONNECTIONS (AIMBOT, MOONWALK, FOV)
-- =========================================================
local CachedTarget = nil
local LastTargetCheck = 0
local cachedIsCarrying = false
local lastRenderCheck = 0
local CurrentMoonwalkYaw = 0
local CurrentMoonwalkSway = 0

table.insert(getgenv().PINATHUB_CONNECTIONS, RunServiceRef.RenderStepped:Connect(function(deltaTime)
    local myChar = LocalPlayer.Character
    if not myChar then return end
    
    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
    local myHum = myChar:FindFirstChild("Humanoid")
    local camera = workspace.CurrentCamera
    
    if not myRoot or not myHum then return end
    if myHum.Health <= 0 then return end
    
    -- Moonwalk
    Modules.Player.UpdateMoonwalk(deltaTime, myRoot, myHum, camera, CurrentMoonwalkYaw, CurrentMoonwalkSway)
    
    -- Aimbot
    if Modules.Config.Current.Aimbot then
        local now = time()
        
        if now - lastRenderCheck > 0.25 then
            cachedIsCarrying = Modules.Utils.GetGameValue(myChar, "Carrying") or Modules.Utils.GetGameValue(myChar, "IsCarrying") or false
            lastRenderCheck = now
        end
        
        if not cachedIsCarrying then
            if now - LastTargetCheck > 0.12 then
                CachedTarget = Modules.Combat.GetClosestPlayer(CachedTarget)
                LastTargetCheck = now
            end
            
            if CachedTarget and (not CachedTarget.Parent or not CachedTarget:IsDescendantOf(workspace)) then
                CachedTarget = nil
            end
            
            local target = CachedTarget
            if target and target.Parent then
                local firing = Modules.Config.Current.AimbotTrigger == "Auto Lock (Always)"
                
                if not firing then
                    firing = UserInputServiceRef:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
                        or UserInputServiceRef:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
                        or getgenv().isMobileFiring == true
                end
                
                if firing then
                    local targetPos = target.Position
                    local smooth = math.clamp(deltaTime * (tonumber(Modules.Config.Current.AimbotSmoothness) or 8), 0.08, 0.28)
                    
                    camera.CFrame = camera.CFrame:Lerp(CFrame.lookAt(camera.CFrame.Position, targetPos), smooth)
                end
            end
        else
            CachedTarget = nil
        end
    end
end))

-- FOV Render Step
RunServiceRef:BindToRenderStep("SmoothFOV", Enum.RenderPriority.Camera.Value + 1, function()
    if Modules.Config.Current.CustomCameraFOV and workspace.CurrentCamera then
        workspace.CurrentCamera.FieldOfView = Modules.Config.Current.CameraFOVValue
    end
end)

-- Heartbeat for ESP refresh
table.insert(getgenv().PINATHUB_CONNECTIONS, RunServiceRef.Heartbeat:Connect(function()
    local now = os.clock()
    if now - (Modules.ESP.LastESPRefresh or 0) > 0.35 then
        Modules.ESP.LastESPRefresh = now
        pcall(function() Modules.ESP.RefreshESP() end)
    end
end))

-- Character added connection for speed boost
table.insert(getgenv().PINATHUB_CONNECTIONS, LocalPlayer.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid", 5)
    if hum and Modules.Config.Current.SpeedBoost then
        Modules.Player.ApplySpeedBoost(hum)
    end
end))

-- Player removing cleanup
table.insert(getgenv().PINATHUB_CONNECTIONS, Players.PlayerRemoving:Connect(function(player)
    Modules.Player.ResetScope()
    if Modules.ESP.ESP_PlayerCache then
        Modules.ESP.ESP_PlayerCache[player.UserId] = nil
    end
    if player.Character then
        local root = player.Character:FindFirstChild("HumanoidRootPart")
        if root then
            local tag = root:FindFirstChild("TagESP")
            if tag then tag:Destroy() end
        end
    end
end))

print("[PINATHUB] All systems initialized successfully!")
