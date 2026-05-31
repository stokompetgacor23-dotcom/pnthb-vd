-- =======================================================
-- PINATHUB - CONFIG MODULE
-- =======================================================

local Config = {}

Config.Defaults = {
    Premium = false,
    SpeedBoost = false,
    BoostSpeed = 8,
    MoonwalkEnabled = false,
    MoonwalkZigzagSpeed = 11,
    MoonwalkBoostPower = 1.08,
    AutoParry = false,
    ParryDistance = 10,
    ParryMatchup = "Auto",
    ParryDelayOffset = 0,
    Aimbot = false,
    AimbotPart = "Torso",
    AimbotTrigger = "Hold to Lock",
    AimbotSmoothness = 8,
    AimRadius = 60,
    AimDistance = 80,
    AimStrictness = 1.3,
    WallCheck = true,
    ShowFOVCircle = false,
    HitboxExpander = false,
    HitboxSize = 15,
    AutoAttack = false,
    AttackRange = 10,
    SilentAimPistol = false,
    SilentAimFOV = 180,
    AutoGenerator = false,
    AutoGeneratorMode = "Perfect",
    GeneratorPerfectOffsetStart = 102,
    GeneratorPerfectOffsetEnd = 108,
    SelfHeal = false,
    AntiFallDamage = false,
    AntiLogger = true,
    NotifyStun = false,
    WarnKiller = true,
    DoubleDamageGen = false,
    SilentActions = false,
    AutoFarmBot = false,
    CustomCameraFOV = false,
    CameraFOVValue = 100,
    ESP_Survivor_Name = false,
    ESP_Survivor_Highlight = false,
    ESP_Killer_Name = false,
    ESP_Killer_Highlight = false,
    ESP_Generator = false,
    ESP_Gate = false,
    ESP_Pallet = false,
    ESP_Hook = false,
    ESP_SCP = false,
    FPPEnabled = false,
}

Config.Current = {}
for k, v in pairs(Config.Defaults) do Config.Current[k] = v end

function Config.Get(key) return Config.Current[key] end
function Config.Set(key, value) Config.Current[key] = value end
function Config.GetAll() return Config.Current end

Config.ESP_COLORS = {
    Killer = Color3.fromRGB(255, 93, 108),
    Survivor = Color3.fromRGB(0, 255, 34),
    Generator = Color3.fromRGB(200, 100, 0),
    Gate = Color3.fromRGB(255, 255, 255),
    Pallet = Color3.fromRGB(53, 189, 166),
    Hook = Color3.fromRGB(252, 116, 116)
}

Config.MaskNames = {
    Abysswalker = "ABYSSWALKER", Cure = "CURE", Hidden = "HIDDEN",
    Killer = "THE KILLER", Masked = "PALA AYAM", Stalker = "STALKER",
    Veil = "VEIL", Slasher = "SLASHER",
}

Config.MaskColors = {
    Abysswalker = Color3.fromRGB(110, 20, 255), Cure = Color3.fromRGB(0, 54, 156),
    Hidden = Color3.fromRGB(170, 170, 170), Killer = Color3.fromRGB(255, 40, 40),
    Masked = Color3.fromRGB(255, 90, 20), Stalker = Color3.fromRGB(255, 0, 140),
    Veil = Color3.fromRGB(0, 140, 255), Slasher = Color3.fromRGB(180, 0, 255),
}

Config.KillerProfiles = {
    Killer = { BonusDist = 1, Delay = 0.04 }, Abysswalker = { BonusDist = 3.5, Delay = 0.12 },
    Hidden = { BonusDist = 2.2, Delay = 0 }, Masked = { BonusDist = 1.5, Delay = 0.05 },
    Stalker = { BonusDist = 1.8, Delay = 0 }, Veil = { BonusDist = 3.2, Delay = 0.04 },
    Slasher = { BonusDist = 1.2, Delay = 0.05 }, Cure = { BonusDist = 2, Delay = 0.03 },
}

Config.IgnoreSkills = {
    "Veil", "Masked", "Stalker", "Invisible", "Ghost", "Phase", "Dash", "Warp", "Teleport"
}

return Config
