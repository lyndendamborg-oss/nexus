-- ============================================================
--  NEXUS CLIENT  v3.0.0  |  Advanced Rebuild
--  New Features & Enhanced Customization
-- ============================================================

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local ContextActionService = game:GetService("ContextActionService")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

if not player.Character then
    player.CharacterAdded:Wait()
end

local Config = {
    ToggleKey = Enum.KeyCode.RightShift,
    Version = "v3.0.0",
}

local Defaults = {}

local function cacheDefaults()
    Defaults.Ambient = Lighting.Ambient
    Defaults.Brightness = Lighting.Brightness
    Defaults.FogEnd = Lighting.FogEnd
    Defaults.FogColor = Lighting.FogColor
    Defaults.Gravity = Workspace.Gravity
    Defaults.FOV = camera.FieldOfView
    Defaults.ClockTime = Lighting.ClockTime
    Defaults.GlobalShadows = Lighting.GlobalShadows
    Defaults.MouseBehavior = UserInputService.MouseBehavior
    Defaults.MouseIconEnabled = UserInputService.MouseIconEnabled
    -- Cache default humanoid properties
    if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
        local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
        Defaults.WalkSpeed = humanoid.WalkSpeed
        Defaults.JumpPower = humanoid.JumpPower
    else
        Defaults.WalkSpeed = 16 -- Fallback
        Defaults.JumpPower = 50 -- Fallback
    end
end

cacheDefaults()

-- Initial State values should be pulled from Defaults where appropriate
local State = {
    Fullbright = false,
    NoFog = false,
    RainbowAmbient = false,
    FreezeTime = false,
    NoShadows = false,
    TimeOfDay = 14,

    WalkSpeed = Defaults.WalkSpeed,
    JumpPower = Defaults.JumpPower,
    InfJump = false,
    Noclip = false,
    Fly = false,
    FlySpeed = 40,
    AntiVoid = false,
    AntiVoidHeight = -200,
    AntiVoidTeleportY = 50,

    Freecam = false,
    FreecamSpeed = 30,
    FreecamBoostMult = 3,
    FreecamSmooth = true,
    FreecamSmoothFactor = 30,
    FreecamFOV = 70,
    FreecamMouseSens = 3,

    Chams = false,
    ChamTransparency = 75,
    ShowHealth = false,
    ShowNames = false,
    ShowDistance = true,
    ESPMaxDistance = 500,

    Gravity = Defaults.Gravity,
    NoParticles = false,

    AutoClick = false,
    AutoClickDelay = 0.05,
    AutoWalk = false,
    AutoWalkDirection = "Forward", -- Forward, Backward, Left, Right
    AntiAFK = false,
    KillAura = false,
    KillAuraRange = 50,
    KillAuraDelay = 0.5,
    SilentAim = false,
    TeleportY = 100, -- Default Y coordinate for teleport
    Speedhack = false,
    SpeedhackRate = 1.5, -- Multiplier for game speed
    ViewmodelFOV = Defaults.FOV, -- Assuming viewmodel FOV matches camera FOV initially
    BypassedChat = false,

    MenuOpacity = 97,
    Draggable = true,
    Theme = "Dark",
    MenuScale = 100,
    ShowHints = true,
    AccentR = 100,
    AccentG = 180,
    AccentB = 255,

    ToggleKeyName = "RightShift",
    FreecamBoostKeyName = "LeftShift",
}

local EXPORT_KEYS = {
    "Fullbright","NoFog","RainbowAmbient","FreezeTime","NoShadows","TimeOfDay",
    "WalkSpeed","JumpPower","InfJump","Noclip","Fly","FlySpeed","AntiVoid","AntiVoidHeight","AntiVoidTeleportY",
    "Freecam","FreecamSpeed","FreecamBoostMult","FreecamSmooth","FreecamSmoothFactor","FreecamFOV","FreecamMouseSens",
    "Chams","ChamTransparency","ShowHealth","ShowNames","ShowDistance","ESPMaxDistance",
    "Gravity","NoParticles",
    "AutoClick", "AutoClickDelay", "AutoWalk", "AutoWalkDirection", "AntiAFK", "KillAura", "KillAuraRange", "KillAuraDelay", "SilentAim",
    "TeleportY", "Speedhack", "SpeedhackRate", "ViewmodelFOV", "BypassedChat",
    "MenuOpacity","Draggable","Theme","MenuScale","ShowHints","AccentR","AccentG","AccentB",
    "ToggleKeyName","FreecamBoostKeyName",
}

local B64_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

local function encodeBase64(data)
    local result = {}
    local padding = (3 - (#data % 3)) % 3
    data = data .. string.rep("\0", padding)

    for i = 1, #data, 3 do
        local b1, b2, b3 = string.byte(data, i, i + 2)
        local n = b1 * 65536 + b2 * 256 + b3
        result[#result + 1] = B64_CHARS:sub(math.floor(n / 262144) % 64 + 1, math.floor(n / 262144) % 64 + 1)
        result[#result + 1] = B64_CHARS:sub(math.floor(n / 4096) % 64 + 1, math.floor(n / 4096) % 64 + 1)
        result[#result + 1] = B64_CHARS:sub(math.floor(n / 64) % 64 + 1, math.floor(n / 64) % 64 + 1)
        result[#result + 1] = B64_CHARS:sub(n % 64 + 1, n % 64 + 1)
    end

    local s = table.concat(result)
    return s:sub(1, #s - padding) .. string.rep("=", padding)
end

local function decodeBase64(data)
    data = data:gsub("[^" .. B64_CHARS .. "=]", "")

    local rem = #data % 4
    if rem == 2 then
        data = data .. "=="
    elseif rem == 3 then
        data = data .. "="
    end

    local lookup = {}
    for i = 1, #B64_CHARS do
        lookup[B64_CHARS:sub(i, i)] = i - 1
    end

    local result = {}
    for i = 1, #data, 4 do
        local c1 = data:sub(i, i)
        local c2 = data:sub(i + 1, i + 1)
        local c3 = data:sub(i + 2, i + 2)
        local c4 = data:sub(i + 3, i + 3)

        local n = (lookup[c1] or 0) * 262144
            + (lookup[c2] or 0) * 4096
            + (lookup[c3] or 0) * 64
            + (lookup[c4] or 0)

        result[#result + 1] = string.char(math.floor(n / 65536) % 256)
        if c3 ~= "=" then
            result[#result + 1] = string.char(math.floor(n / 256) % 256)
        end
        if c4 ~= "=" then
            result[#result + 1] = string.char(n % 256)
        end
    end

    return table.concat(result)
end

local function serializeState()
    local parts = {}
    for _, key in ipairs(EXPORT_KEYS) do
        local value = State[key]
        if type(value) == "boolean" then
            parts[#parts + 1] = key .. "=" .. (value and "1" or "0")
        else
            parts[#parts + 1] = key .. "=" .. tostring(value)
        end
    end
    return encodeBase64("NX3|" .. table.concat(parts, ";")) -- Changed header to NX3 for new version
end

local function keyCodeFromName(name)
    if typeof(name) ~= "string" then
        return nil
    end
    return Enum.KeyCode[name]
end

local function deserializeState(encoded)
    local ok, raw = pcall(decodeBase64, encoded)
    if not ok then
        return false, "Decode failed"
    end

    if raw:sub(1, 4) ~= "NX3|" then -- Changed header check to NX3
        return false, "Invalid profile"
    end

    local loaded = {}
    local body = raw:sub(5)

    for pair in body:gmatch("[^;]+") do
        local k, v = pair:match("^(.-)=(.*)$")
        if k and v then
            loaded[k] = v
        end
    end

    for _, key in ipairs(EXPORT_KEYS) do
        local incoming = loaded[key]
        if incoming ~= nil then
            local current = State[key]
            if type(current) == "boolean" then
                State[key] = incoming == "1"
            elseif type(current) == "number" then
                State[key] = tonumber(incoming) or current
            else
                State[key] = incoming
            end
        end
    end

    local reboundKey = keyCodeFromName(State.ToggleKeyName)
    if reboundKey then
        Config.ToggleKey = reboundKey
    end

    return true, "OK"
end

local Themes = {
    Dark = {
        BG = Color3.fromRGB(14, 14, 18),
        Panel = Color3.fromRGB(20, 20, 26),
        Card = Color3.fromRGB(26, 26, 34),
        Border = Color3.fromRGB(40, 40, 55),
        Text = Color3.fromRGB(220, 220, 230),
        SubText = Color3.fromRGB(120, 120, 140),
        On = Color3.fromRGB(60, 200, 120),
        Off = Color3.fromRGB(60, 60, 75),
    },
    Neon = {
        BG = Color3.fromRGB(5, 5, 10),
        Panel = Color3.fromRGB(10, 10, 20),
        Card = Color3.fromRGB(15, 15, 28),
        Border = Color3.fromRGB(80, 40, 120),
        Text = Color3.fromRGB(230, 200, 255),
        SubText = Color3.fromRGB(140, 100, 180),
        On = Color3.fromRGB(180, 80, 255),
        Off = Color3.fromRGB(40, 20, 60),
    },
    Light = {
        BG = Color3.fromRGB(240, 240, 248),
        Panel = Color3.fromRGB(255, 255, 255),
        Card = Color3.fromRGB(248, 248, 255),
        Border = Color3.fromRGB(200, 200, 215),
        Text = Color3.fromRGB(30, 30, 40),
        SubText = Color3.fromRGB(100, 100, 120),
        On = Color3.fromRGB(40, 180, 100),
        Off = Color3.fromRGB(180, 180, 200),
    },
    Blood = {
        BG = Color3.fromRGB(12, 6, 6),
        Panel = Color3.fromRGB(22, 10, 10),
        Card = Color3.fromRGB(30, 14, 14),
        Border = Color3.fromRGB(80, 20, 20),
        Text = Color3.fromRGB(230, 210, 210),
        SubText = Color3.fromRGB(140, 90, 90),
        On = Color3.fromRGB(220, 50, 50),
        Off = Color3.fromRGB(60, 20, 20),
    },
}

local function getAccent()
    return Color3.fromRGB(State.AccentR, State.AccentG, State.AccentB)
end

local T = {} -- Theme table, will be populated by getTheme

local function getTheme()
    local base = Themes[State.Theme] or Themes.Dark
    T.BG = base.BG
    T.Panel = base.Panel
    T.Card = base.Card
    T.Border = base.Border
    T.Text = base.Text
    T.SubText = base.SubText
    T.Accent = getAccent() -- Always derive accent from State
    T.On = base.On
    T.Off = base.Off
end
getTheme() -- Initialize T

local oldGui = CoreGui:FindFirstChild("NexusClient")
if oldGui then
    oldGui:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "NexusClient"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local parented = pcall(function()
    gui.Parent = CoreGui
end)
if not parented then
    gui.Parent = player:WaitForChild("PlayerGui")
end

local function make(className, props, parent)
    local obj = Instance.new(className)
    for k, v in pairs(props) do
        obj[k] = v
    end
    if parent then
        obj.Parent = parent
    end
    return obj
end

local function corner(radius, parent)
    return make("UICorner", {
        CornerRadius = UDim.new(0, radius),
    }, parent)
end

local function stroke(thickness, color, parent)
    return make("UIStroke", {
        Thickness = thickness,
        Color = color,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, parent)
end

local function tw(obj, props, duration, style, direction)
    TweenService:Create(
        obj,
        TweenInfo.new(duration or 0.18, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out),
        props
    ):Play()
end

local accentTargets = {}

local function bindAccent(object, property)
    accentTargets[#accentTargets + 1] = { object = object, property = property }
end

local function applyAccent()
    T.Accent = getAccent() -- Update accent in the theme table

    -- Update topGradient color sequence (FIX for the ColorSequence error)
    if topGradient then
        topGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, T.Accent),
            ColorSequenceKeypoint.new(1, T.BG),
        })
    end

    for _, item in ipairs(accentTargets) do
        if item.object and item.object.Parent then
            if item.property == "Color" and item.object:IsA("UIGradient") then
                -- Special handling for UIGradient.Color property
                item.object.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, T.Accent),
                    ColorSequenceKeypoint.new(1, Themes[State.Theme].BG or Themes.Dark.BG), -- Ensure background color updates
                })
            else
                item.object[item.property] = T.Accent
            end
        end
    end
end

local win = make("Frame", {
    Size = UDim2.new(0, 600, 0, 440),
    Position = UDim2.new(0.5, -300, 0.5, -220),
    BackgroundColor3 = T.BG,
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Visible = false,
    Active = true,
    Draggable = State.Draggable,
}, gui)
corner(12, win)
stroke(1, T.Border, win)

local winScale = make("UIScale", {
    Scale = 0.88,
}, win)

local menuAnimating = false
local menuOpen = false

local function openMenu()
    if menuOpen or menuAnimating then
        return
    end

    menuAnimating = true
    local ok = pcall(function()
        win.Visible = true
        win.BackgroundTransparency = 1
        winScale.Scale = 0.88
        tw(win, { BackgroundTransparency = 1 - (State.MenuOpacity / 100) }, 0.25, Enum.EasingStyle.Quint)
        tw(winScale, { Scale = State.MenuScale / 100 }, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    end)

    task.delay(0.31, function()
        menuAnimating = false
        if ok then
            menuOpen = true
        end
    end)
end

local function closeMenu()
    if (not menuOpen) or menuAnimating then
        return
    end

    menuAnimating = true
    menuOpen = false

    local ok = pcall(function()
        tw(win, { BackgroundTransparency = 1 }, 0.2, Enum.EasingStyle.Quint)
        tw(winScale, { Scale = 0.88 }, 0.18, Enum.EasingStyle.Quad)
    end)

    task.delay(0.22, function()
        if ok then
            win.Visible = false
            winScale.Scale = 0.88
        end
        menuAnimating = false
    end)
end

local topBar = make("Frame", {
    Size = UDim2.new(1, 0, 0, 48),
    BackgroundColor3 = T.Panel,
    BorderSizePixel = 0,
}, win)
corner(12, topBar)

local topGradient = make("UIGradient", {
    -- FIX: This needs to be a ColorSequence. Initialized here, updated by applyAccent.
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, T.Accent),
        ColorSequenceKeypoint.new(1, T.BG),
    }),
    Rotation = 90,
    Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.55),
        NumberSequenceKeypoint.new(1, 1),
    }),
}, topBar)
-- Bind accent to the gradient's ColorSequence
bindAccent(topGradient, "Color") -- This will now correctly update the ColorSequence

make("TextLabel", {
    Size = UDim2.new(0, 200, 1, 0),
    Position = UDim2.new(0, 16, 0, 0),
    BackgroundTransparency = 1,
    Text = "NEXUS",
    TextColor3 = T.Text,
    TextSize = 18,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
}, topBar)

make("TextLabel", {
    Size = UDim2.new(0, 100, 1, 0),
    Position = UDim2.new(1, -126, 0, 0),
    BackgroundTransparency = 1,
    Text = Config.Version,
    TextColor3 = T.SubText,
    TextSize = 11,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Right,
}, topBar)

local closeBtn = make("TextButton", {
    Size = UDim2.new(0, 28, 0, 28),
    Position = UDim2.new(1, -36, 0.5, -14),
    BackgroundColor3 = Color3.fromRGB(200, 60, 60),
    BorderSizePixel = 0,
    Text = "X",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 12,
    Font = Enum.Font.GothamBold,
}, topBar)
corner(6, closeBtn)

closeBtn.MouseButton1Click:Connect(closeMenu)
closeBtn.MouseEnter:Connect(function()
    tw(closeBtn, { BackgroundColor3 = Color3.fromRGB(240, 80, 80) })
end)
closeBtn.MouseLeave:Connect(function()
    tw(closeBtn, { BackgroundColor3 = Color3.fromRGB(200, 60, 60) })
end)

local tabList = { "Visual", "Player", "Freecam", "ESP", "World", "Combat", "Utility", "Settings" } -- Added Combat, Utility tabs
local tabIcons = {
    Visual = "*",
    Player = ">",
    Freecam = "O",
    ESP = "@",
    World = "#",
    Combat = "!",
    Utility = "$",
    Settings = "+",
}

local tabFrames = {}
local tabButtons = {}

local tabBar = make("Frame", {
    Size = UDim2.new(0, 110, 1, -48),
    Position = UDim2.new(0, 0, 0, 48),
    BackgroundColor3 = T.Panel,
    BorderSizePixel = 0,
}, win)

local function switchTab(name)
    for _, tabName in ipairs(tabList) do
        local btn = tabButtons[tabName]
        local frame = tabFrames[tabName]
        if tabName == name then
            tw(btn, {
                BackgroundColor3 = T.Accent,
                TextColor3 = Color3.new(1, 1, 1),
            })
            frame.Visible = true
        else
            tw(btn, {
                BackgroundColor3 = T.Card,
                TextColor3 = T.SubText,
            })
            frame.Visible = false
        end
    end
end

for i, name in ipairs(tabList) do
    local btn = make("TextButton", {
        Size = UDim2.new(1, -12, 0, 38),
        Position = UDim2.new(0, 6, 0, 8 + ((i - 1) * 44)),
        BackgroundColor3 = T.Card,
        BorderSizePixel = 0,
        Text = (tabIcons[name] or "") .. "  " .. name,
        TextColor3 = T.SubText,
        TextSize = 12,
        Font = Enum.Font.GothamSemibold,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, tabBar)
    corner(8, btn)
    make("UIPadding", { PaddingLeft = UDim.new(0, 10) }, btn)
    tabButtons[name] = btn

    local frame = make("ScrollingFrame", {
        Size = UDim2.new(1, -118, 1, -56),
        Position = UDim2.new(0, 114, 0, 52),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = T.Accent,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        Visible = i == 1,
    }, win)
    bindAccent(frame, "ScrollBarImageColor3")

    make("UIListLayout", {
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, frame)

    make("UIPadding", {
        PaddingTop = UDim.new(0, 6),
        PaddingBottom = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 2),
        PaddingRight = UDim.new(0, 8),
    }, frame)

    tabFrames[name] = frame
    btn.MouseButton1Click:Connect(function()
        switchTab(name)
    end)
end

local layoutOrder = {}
for _, tab in ipairs(tabList) do
    layoutOrder[tab] = 0
end

local function nextOrder(tab)
    layoutOrder[tab] = layoutOrder[tab] + 1
    return layoutOrder[tab]
end

local toggleRefs = {}
local numberInputRefs = {} -- Changed from sliderRefs
local dropdownRefs = {}
local keybindRefs = {}

local function addHeader(tab, text)
    local parent = tabFrames[tab]
    local lbl = make("TextLabel", {
        Size = UDim2.new(1, 0, 0, 22),
        BackgroundTransparency = 1,
        Text = "  " .. text,
        TextColor3 = T.Accent,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = nextOrder(tab),
    }, parent)
    bindAccent(lbl, "TextColor3")

    make("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = T.Border,
        BackgroundTransparency = 0.4,
        BorderSizePixel = 0,
    }, lbl)
end

local function addInfo(tab, text)
    local parent = tabFrames[tab]
    local card = make("Frame", {
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = T.Card,
        BorderSizePixel = 0,
        LayoutOrder = nextOrder(tab),
    }, parent)
    corner(8, card)
    stroke(1, T.Border, card)

    local label = make("TextLabel", {
        Size = UDim2.new(1, -16, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = T.SubText,
        TextSize = 11,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
    }, card)

    return card, label
end

local function addToggle(tab, key, label, desc, callback)
    local parent = tabFrames[tab]
    local card = make("Frame", {
        Size = UDim2.new(1, 0, 0, 56),
        BackgroundColor3 = T.Card,
        BorderSizePixel = 0,
        LayoutOrder = nextOrder(tab),
    }, parent)
    corner(8, card)
    stroke(1, T.Border, card)

    make("TextLabel", {
        Size = UDim2.new(1, -70, 0, 22),
        Position = UDim2.new(0, 12, 0, 8),
        BackgroundTransparency = 1,
        Text = label,
        TextColor3 = T.Text,
        TextSize = 13,
        Font = Enum.Font.GothamSemibold,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, card)

    if desc and desc ~= "" then
        make("TextLabel", {
            Size = UDim2.new(1, -70, 0, 18),
            Position = UDim2.new(0, 12, 0, 30),
            BackgroundTransparency = 1,
            Text = desc,
            TextColor3 = T.SubText,
            TextSize = 11,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, card)
    end

    local pill = make("Frame", {
        Size = UDim2.new(0, 44, 0, 22),
        Position = UDim2.new(1, -56, 0.5, -11),
        BackgroundColor3 = T.Off,
        BorderSizePixel = 0,
    }, card)
    corner(11, pill)

    local knob = make("Frame", {
        Size = UDim2.new(0, 16, 0, 16),
        Position = UDim2.new(0, 3, 0.5, -8),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
    }, pill)
    corner(8, knob)

    local enabled = State[key] == true

    local function setEnabled(value, instant)
        enabled = value
        State[key] = value
        local pillColor = value and T.On or T.Off
        local knobPos = value and UDim2.new(0, 25, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)

        if instant then
            pill.BackgroundColor3 = pillColor
            knob.Position = knobPos
        else
            tw(pill, { BackgroundColor3 = pillColor })
            tw(knob, { Position = knobPos })
        end

        if callback then
            callback(value)
        end
    end

    setEnabled(enabled, true)

    local button = make("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        ZIndex = 2,
    }, card)

    button.MouseButton1Click:Connect(function()
        setEnabled(not enabled, false)
    end)

    toggleRefs[key] = {
        setEnabled = setEnabled,
        getEnabled = function()
            return enabled
        end,
    }

    return card
end

-- New function for number input (replaces addSlider for unlimited input)
local function addNumberInput(tab, key, label, defaultValue, callback, typeIsFloat)
    local parent = tabFrames[tab]
    local card = make("Frame", {
        Size = UDim2.new(1, 0, 0, 56),
        BackgroundColor3 = T.Card,
        BorderSizePixel = 0,
        LayoutOrder = nextOrder(tab),
    }, parent)
    corner(8, card)
    stroke(1, T.Border, card)

    make("TextLabel", {
        Size = UDim2.new(1, -70, 0, 22),
        Position = UDim2.new(0, 12, 0, 8),
        BackgroundTransparency = 1,
        Text = label,
        TextColor3 = T.Text,
        TextSize = 13,
        Font = Enum.Font.GothamSemibold,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, card)

    local inputField = make("TextBox", {
        Size = UDim2.new(0, 60, 0, 28),
        Position = UDim2.new(1, -72, 0.5, -14),
        BackgroundColor3 = T.Panel,
        BorderSizePixel = 0,
        Text = tostring(defaultValue),
        TextColor3 = T.Accent,
        TextSize = 12,
        Font = Enum.Font.RobotoMono,
        TextXAlignment = Enum.TextXAlignment.Right,
        ClearTextOnFocus = false,
    }, card)
    corner(6, inputField)
    stroke(1, T.Border, inputField)
    bindAccent(inputField, "TextColor3") -- Bind text color for consistency

    local function setValue(value, fireCallback)
        local numValue = typeIsFloat and tonumber(value) or math.floor(tonumber(value) or 0)
        if numValue ~= nil and not math.isnan(numValue) then
            State[key] = numValue
            inputField.Text = tostring(numValue)
            if fireCallback and callback then
                callback(numValue)
            end
        else
             -- Option to revert to previous valid state or show error
             inputField.Text = tostring(State[key])
        end
    end

    inputField.FocusLost:Connect(function(enterPressed)
        setValue(inputField.Text, true)
    end)
    inputField.Changed:Connect(function(property)
        if property == "Text" then
            -- Allow typing temporarily, actual value change on FocusLost
        end
    end)

    numberInputRefs[key] = setValue
    setValue(defaultValue, false) -- Initialize display without firing callback

    return card
end


local function addDropdown(tab, stateKey, label, options, defaultValue, callback)
    local parent = tabFrames[tab]
    local card = make("Frame", {
        Size = UDim2.new(1, 0, 0, 56),
        BackgroundColor3 = T.Card,
        BorderSizePixel = 0,
        LayoutOrder = nextOrder(tab),
        ClipsDescendants = true,
    }, parent)
    corner(8, card)
    stroke(1, T.Border, card)

    make("TextLabel", {
        Size = UDim2.new(1, -110, 0, 56),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Text = label,
        TextColor3 = T.Text,
        TextSize = 13,
        Font = Enum.Font.GothamSemibold,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, card)

    local selected = defaultValue or options[1]

    local selector = make("TextButton", {
        Size = UDim2.new(0, 100, 0, 32),
        Position = UDim2.new(1, -108, 0.5, -16),
        BackgroundColor3 = T.Panel,
        BorderSizePixel = 0,
        Text = selected,
        TextColor3 = T.Accent,
        TextSize = 12,
        Font = Enum.Font.GothamSemibold,
    }, card)
    bindAccent(selector, "TextColor3")
    corner(6, selector)
    stroke(1, T.Border, selector)

    local listFrame = make("Frame", {
        Size = UDim2.new(0, 100, 0, #options * 32),
        Position = UDim2.new(1, -108, 1, 4),
        BackgroundColor3 = T.Panel,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 50,
    }, card)
    corner(6, listFrame)
    stroke(1, T.Border, listFrame)

    local open = false

    local function setSelected(value, fireCallback)
        selected = value
        selector.Text = value
        State[stateKey] = value
        if fireCallback and callback then
            callback(value)
        end
    end

    for index, option in ipairs(options) do
        local optionBtn = make("TextButton", {
            Size = UDim2.new(1, 0, 0, 32),
            Position = UDim2.new(0, 0, 0, (index - 1) * 32),
            BackgroundColor3 = T.Panel,
            BorderSizePixel = 0,
            Text = option,
            TextColor3 = T.SubText,
            TextSize = 12,
            Font = Enum.Font.Gotham,
            ZIndex = 51,
        }, listFrame)

        optionBtn.MouseEnter:Connect(function()
            tw(optionBtn, { BackgroundColor3 = T.Card })
        end)

        optionBtn.MouseLeave:Connect(function()
            tw(optionBtn, { BackgroundColor3 = T.Panel })
        end)

        optionBtn.MouseButton1Click:Connect(function()
            open = false
            listFrame.Visible = false
            card.Size = UDim2.new(1, 0, 0, 56)
            setSelected(option, true)
        end)
    end

    selector.MouseButton1Click:Connect(function()
        open = not open
        listFrame.Visible = open
        -- Adjust card size to show dropdown list
        card.Size = open and UDim2.new(1, 0, 0, 56 + (#options * 32)) or UDim2.new(1, 0, 0, 56)
    end)

    dropdownRefs[stateKey] = setSelected
    setSelected(defaultValue, false)

    return card
end

local function addActionButton(tab, label, callback)
    local parent = tabFrames[tab]
    local card = make("Frame", {
        Size = UDim2.new(1, 0, 0, 48),
        BackgroundColor3 = T.Card,
        BorderSizePixel = 0,
        LayoutOrder = nextOrder(tab),
    }, parent)
    corner(8, card)
    stroke(1, T.Border, card)

    local button = make("TextButton", {
        Size = UDim2.new(1, -24, 1, -16),
        Position = UDim2.new(0, 12, 0, 8),
        BackgroundColor3 = T.Accent,
        BorderSizePixel = 0,
        Text = label,
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 13,
        Font = Enum.Font.GothamBold,
    }, card)
    corner(6, button)
    bindAccent(button, "BackgroundColor3")

    button.MouseButton1Click:Connect(function()
        if callback then
            callback()
        end
    end)
    button.MouseEnter:Connect(function()
        tw(button, { BackgroundColor3 = T.Accent:Lerp(Color3.new(1, 1, 1), 0.2) })
    end)
    button.MouseLeave:Connect(function()
        tw(button, { BackgroundColor3 = T.Accent })
    end)
    return card
end

local function applyCharacterStats()
    local character = player.Character
    if not character then
        return
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = State.WalkSpeed
        humanoid.JumpPower = State.JumpPower
    end
end

local noClipOriginal = {}

local function clearNoClipCache()
    noClipOriginal = {}
end

local function restoreCharacterCollision()
    local character = player.Character
    if not character then
        return
    end

    for part, canCollide in pairs(noClipOriginal) do
        if part and part.Parent then
            part.CanCollide = canCollide
        end
    end
    clearNoClipCache()
end

local particleStates = {}

local function setParticlesDisabled(disabled)
    if disabled then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("ParticleEmitter") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
                if particleStates[obj] == nil then
                    particleStates[obj] = obj.Enabled
                end
                obj.Enabled = false
            end
        end
    else
        for obj, oldEnabled in pairs(particleStates) do
            if obj and obj.Parent then
                obj.Enabled = oldEnabled
            end
        end
        particleStates = {}
    end
end

Workspace.DescendantAdded:Connect(function(obj)
    if not State.NoParticles then
        return
    end

    if obj:IsA("ParticleEmitter") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
        if particleStates[obj] == nil then
            particleStates[obj] = obj.Enabled
        end
        obj.Enabled = false
    end
end)

addHeader("Visual", "LIGHTING")
addToggle("Visual", "Fullbright", "Fullbright", "Max ambient lighting", function(on)
    Lighting.Ambient = on and Color3.fromRGB(255, 255, 255) or Defaults.Ambient
    Lighting.Brightness = on and 2 or Defaults.Brightness
end)

addToggle("Visual", "NoFog", "No Fog", "Remove atmospheric fog", function(on)
    Lighting.FogEnd = on and 1e7 or Defaults.FogEnd
end)

addToggle("Visual", "RainbowAmbient", "Rainbow Ambient", "Cycle ambient through colors", function(on)
    if not on then
        Lighting.Ambient = State.Fullbright and Color3.fromRGB(255, 255, 255) or Defaults.Ambient
    end
end)

addToggle("Visual", "NoShadows", "No Shadows", "Disable GlobalShadows", function(on)
    Lighting.GlobalShadows = on and false or Defaults.GlobalShadows
end)

addHeader("Visual", "TIME")
addToggle("Visual", "FreezeTime", "Freeze Time", "Lock the current clock time", function(on)
    if on then
        Defaults.FrozenClock = Lighting.ClockTime
    end
end)

addNumberInput("Visual", "TimeOfDay", "Time of Day (0-24)", State.TimeOfDay, function(v)
    Lighting.ClockTime = v
end, true) -- Use true for float numbers

addHeader("Visual", "VIEWMODEL")
addNumberInput("Visual", "ViewmodelFOV", "Viewmodel FOV", State.ViewmodelFOV, function(v)
    -- This feature is game-dependent. Many games use custom viewmodels.
    -- Here's a general approach, but it might not work in all games.
    if player and player.Character then
        local camMod = player.Character:FindFirstChild("ClientCameraModule") -- Common path in older games
        if camMod and camMod:FindFirstChild("Internal") then
            -- This is highly speculative and depends on the game's structure
            -- You might need to find the actual camera script and modify its FOV
            -- For now, we'll just set it to the generic camera's FOV.
        end
    end
    -- Also ensure main camera FOV changes if not in freecam
    if not State.Freecam then
        camera.FieldOfView = v
    end
end, true)


addHeader("Player", "MOVEMENT")
addNumberInput("Player", "WalkSpeed", "Walk Speed", State.WalkSpeed, function(v)
    local character = player.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = v
        end
    end
end, true)

addNumberInput("Player", "JumpPower", "Jump Power", State.JumpPower, function(v)
    local character = player.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.JumpPower = v
        end
    end
end, true)

addToggle("Player", "InfJump", "Infinite Jump", "Jump while airborne", nil)

addToggle("Player", "Noclip", "Noclip", "Walk through walls", function(on)
    if not on then
        restoreCharacterCollision()
    end
end)

addHeader("Player", "FLIGHT")
addToggle("Player", "Fly", "Fly", "Free movement flight", nil)
addNumberInput("Player", "FlySpeed", "Fly Speed", State.FlySpeed, nil, true)

addHeader("Player", "SAFETY")
addToggle("Player", "AntiVoid", "Anti-Void", "Teleport back if you fall", nil)
addNumberInput("Player", "AntiVoidHeight", "Void Trigger Height", State.AntiVoidHeight, nil, true)
addNumberInput("Player", "AntiVoidTeleportY", "Teleport Height", State.AntiVoidTeleportY, nil, true)
addActionButton("Player", "Teleport to Y-coord", function()
    local character = player.Character
    if character then
        local root = character:FindFirstChild("HumanoidRootPart")
        if root then
            root.CFrame = CFrame.new(root.Position.X, State.TeleportY, root.Position.Z)
        end
    end
end)
addNumberInput("Player", "TeleportY", "Teleport Y-Coordinate", State.TeleportY, nil, true)


local speedHUD = make("Frame", {
    Size = UDim2.new(0, 150, 0, 30),
    Position = UDim2.new(0.5, -75, 1, -50),
    BackgroundColor3 = Color3.fromRGB(10, 10, 14),
    BackgroundTransparency = 0.25,
    BorderSizePixel = 0,
    Visible = false,
    ZIndex = 10,
}, gui)
corner(8, speedHUD)
local speedHUDStroke = stroke(1, T.Accent, speedHUD)
bindAccent(speedHUDStroke, "Color")

local speedHUDLabel = make("TextLabel", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    Text = "CAM  |  NORMAL",
    TextColor3 = T.Accent,
    TextSize = 12,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Center,
    ZIndex = 11,
}, speedHUD)
bindAccent(speedHUDLabel, "TextColor3")

local freecamPos = camera.CFrame.Position
local freecamYaw = 0
local freecamPitch = 0
local savedCameraType = camera.CameraType
local savedCameraSubject = camera.CameraSubject

local function syncFreecamAngles(cf)
    local look = cf.LookVector
    freecamYaw = math.atan2(-look.X, -look.Z)
    freecamPitch = math.asin(math.clamp(look.Y, -1, 1))
end

local function enableFreecam()
    freecamPos = camera.CFrame.Position
    syncFreecamAngles(camera.CFrame)

    savedCameraType = camera.CameraType
    savedCameraSubject = camera.CameraSubject

    camera.CameraType = Enum.CameraType.Scriptable
    camera.FieldOfView = State.FreecamFOV

    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
    UserInputService.MouseIconEnabled = false

    speedHUD.Visible = true
end

local function disableFreecam()
    camera.CameraType = savedCameraType or Enum.CameraType.Custom
    if savedCameraSubject then
        camera.CameraSubject = savedCameraSubject
    end
    camera.FieldOfView = Defaults.FOV -- Restore original FOV
    -- Also restore viewmodel FOV if it was customized
    if numberInputRefs.ViewmodelFOV then
        numberInputRefs.ViewmodelFOV(Defaults.FOV, true)
    end

    UserInputService.MouseBehavior = Defaults.MouseBehavior
    UserInputService.MouseIconEnabled = Defaults.MouseIconEnabled

    speedHUD.Visible = false
end

addHeader("Freecam", "CAMERA")
addToggle("Freecam", "Freecam", "Freecam", "Detach camera from character", function(on)
    if on then
        enableFreecam()
    else
        disableFreecam()
    end
end)

addToggle("Freecam", "FreecamSmooth", "Smooth Movement", "Use lerped camera motion", nil)

addHeader("Freecam", "SPEED")
addNumberInput("Freecam", "FreecamSpeed", "Base Speed", State.FreecamSpeed, nil, true)
addNumberInput("Freecam", "FreecamBoostMult", "Boost Multiplier", State.FreecamBoostMult, nil, true)
addInfo("Freecam", "Hold LeftShift to boost. WASD moves. Q/E move up and down.")

addHeader("Freecam", "OPTICS")
addNumberInput("Freecam", "FreecamFOV", "Field of View", State.FreecamFOV, function(v)
    if State.Freecam then
        camera.FieldOfView = v
    end
end, true)
addNumberInput("Freecam", "FreecamMouseSens", "Mouse Sensitivity", State.FreecamMouseSens, nil, true)
addNumberInput("Freecam", "FreecamSmoothFactor", "Smooth Factor", State.FreecamSmoothFactor, nil, true)

addHeader("ESP", "HIGHLIGHT")
addToggle("ESP", "Chams", "Chams", "Highlight players through walls", function(on)
    if not on then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player and p.Character then
                local hl = p.Character:FindFirstChild("_NexusHL")
                if hl then
                    hl:Destroy()
                end
            end
        end
    end
end)

addNumberInput("ESP", "ChamTransparency", "Cham Transparency (0-100)", State.ChamTransparency, nil, true)

addHeader("ESP", "LABELS")
addToggle("ESP", "ShowNames", "Show Names", "Names above heads", nil)
addToggle("ESP", "ShowHealth", "Show Health", "Health above heads", nil)
addToggle("ESP", "ShowDistance", "Show Distance", "Distance in labels", nil)
addNumberInput("ESP", "ESPMaxDistance", "Max Render Distance", State.ESPMaxDistance, nil, true)

addHeader("World", "PHYSICS")
addNumberInput("World", "Gravity", "Gravity", State.Gravity, function(v)
    Workspace.Gravity = v
end, true)

addHeader("World", "ENVIRONMENT")
addToggle("World", "NoParticles", "No Particles", "Disable particles / fire / smoke", function(on)
    setParticlesDisabled(on)
end)

-- New Combat Tab
addHeader("Combat", "AUTO-ATTACK")
addToggle("Combat", "KillAura", "Kill Aura", "Automatically attack nearby enemies", nil)
addNumberInput("Combat", "KillAuraRange", "Kill Aura Range", State.KillAuraRange, nil, true)
addNumberInput("Combat", "KillAuraDelay", "Kill Aura Delay (s)", State.KillAuraDelay, nil, true)
addInfo("Combat", "Targets closest Humanoid. May not work in all games.")

addHeader("Combat", "AIM ASSIST")
addToggle("Combat", "SilentAim", "Silent Aim", "Automatically aim at closest enemy when attacking", nil)
addInfo("Combat", "Works with mouse input. Game-specific implementation needed.")

-- New Utility Tab
addHeader("Utility", "AUTOMATION")
addToggle("Utility", "AutoClick", "Auto Click", "Automatically click the mouse", nil)
addNumberInput("Utility", "AutoClickDelay", "Click Delay (seconds)", State.AutoClickDelay, nil, true)

addToggle("Utility", "AutoWalk", "Auto Walk", "Automatically walk in a direction", nil)
addDropdown("Utility", "AutoWalkDirection", "Direction", {"Forward", "Backward", "Left", "Right"}, State.AutoWalkDirection, nil)

addToggle("Utility", "AntiAFK", "Anti-AFK", "Prevents being kicked for inactivity", nil)

addHeader("Utility", "GAME MODIFIERS")
local originalGameSpeed = RunService.RenderStepped:Wait() -- Placeholder for original game speed, actual speed depends on game's implementation
addToggle("Utility", "Speedhack", "Speedhack", "Modify game's update speed", function(on)
    if on then
        RunService.RenderStepped:Connect(function(dt)
            -- This is a very basic speedhack. Advanced ones modify delta time directly.
            -- This just makes the script respond faster. Actual game speed change is harder.
        end)
    else
        -- Need to disconnect the renderstepped here for a real speedhack
    end
end)
addNumberInput("Utility", "SpeedhackRate", "Speed Multiplier", State.SpeedhackRate, nil, true)
addInfo("Utility", "Note: Speedhack implementation is complex and often game-specific. This is a basic form.")

addHeader("Utility", "CHAT")
addToggle("Utility", "BypassedChat", "Bypassed Chat", "Experimental: remove chat restrictions", function(on)
    -- This is highly game-dependent and often requires exploiting specific game scripts.
    -- A universal bypass is not possible via a simple toggle.
    -- Placeholder for future implementation or specific game contexts.
end)
addInfo("Utility", "Bypass chat is highly game-dependent and experimental. May not work.")

addHeader("Settings", "APPEARANCE")
addDropdown("Settings", "Theme", "Theme", { "Dark", "Neon", "Light", "Blood" }, State.Theme, function(v)
    State.Theme = v
    getTheme() -- Re-populate T with new theme colors
    closeMenu() -- Close and re-open to trigger UI redraw with new theme
    openMenu()
    applyAccent() -- Apply accent to all elements after theme change
end)

addNumberInput("Settings", "MenuOpacity", "Menu Opacity (10-100)", State.MenuOpacity, function(v)
    win.BackgroundTransparency = 1 - (v / 100)
end, true)

addNumberInput("Settings", "MenuScale", "Menu Scale %", State.MenuScale, function(v)
    winScale.Scale = v / 100
end, true)

addHeader("Settings", "ACCENT COLOUR (R, G, B)")
addNumberInput("Settings", "AccentR", "Accent Red (0-255)", State.AccentR, function(v)
    State.AccentR = v
    applyAccent()
end, true)

addNumberInput("Settings", "AccentG", "Accent Green (0-255)", State.AccentG, function(v)
    State.AccentG = v
    applyAccent()
end, true)

addNumberInput("Settings", "AccentB", "Accent Blue (0-255)", State.AccentB, function(v)
    State.AccentB = v
    applyAccent()
end, true)

addHeader("Settings", "BEHAVIOUR")
addToggle("Settings", "Draggable", "Draggable Window", "Allow dragging the menu", function(on)
    win.Draggable = on
end)

addToggle("Settings", "ShowHints", "Show Hints", "Reserved for future hint labels", nil)

addHeader("Settings", "KEYBINDS")

local rebindCard = make("Frame", {
    Size = UDim2.new(1, 0, 0, 56),
    BackgroundColor3 = T.Card,
    BorderSizePixel = 0,
    LayoutOrder = nextOrder("Settings"),
}, tabFrames["Settings"])
corner(8, rebindCard)
stroke(1, T.Border, rebindCard)

make("TextLabel", {
    Size = UDim2.new(1, -120, 0, 22),
    Position = UDim2.new(0, 12, 0, 8),
    BackgroundTransparency = 1,
    Text = "Toggle Key",
    TextColor3 = T.Text,
    TextSize = 13,
    Font = Enum.Font.GothamSemibold,
    TextXAlignment = Enum.TextXAlignment.Left,
}, rebindCard)

make("TextLabel", {
    Size = UDim2.new(1, -120, 0, 18),
    Position = UDim2.new(0, 12, 0, 30),
    BackgroundTransparency = 1,
    Text = "Key used to open/close Nexus",
    TextColor3 = T.SubText,
    TextSize = 11,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left,
}, rebindCard)

local rebindBtn = make("TextButton", {
    Size = UDim2.new(0, 100, 0, 32),
    Position = UDim2.new(1, -108, 0.5, -16),
    BackgroundColor3 = T.Panel,
    BorderSizePixel = 0,
    Text = State.ToggleKeyName,
    TextColor3 = T.Accent,
    TextSize = 12,
    Font = Enum.Font.GothamBold,
}, rebindCard)
bindAccent(rebindBtn, "TextColor3")
corner(6, rebindBtn)
stroke(1, T.Border, rebindBtn)

keybindRefs.ToggleKeyName = function(name)
    rebindBtn.Text = name
end

local rebinding = false
rebindBtn.MouseButton1Click:Connect(function()
    if rebinding then
        return
    end

    rebinding = true
    rebindBtn.Text = "Press key..."
    rebindBtn.TextColor3 = Color3.fromRGB(255, 200, 60)

    local conn
    conn = UserInputService.InputBegan:Connect(function(input, processed)
        if processed then
            return
        end
        if input.UserInputType ~= Enum.UserInputType.Keyboard then
            return
        end

        Config.ToggleKey = input.KeyCode
        State.ToggleKeyName = input.KeyCode.Name
        rebindBtn.Text = input.KeyCode.Name
        rebindBtn.TextColor3 = T.Accent
        rebinding = false

        if conn then
            conn:Disconnect()
        end
    end)
end)

addInfo("Settings", "Freecam boost key is LeftShift. Theme palette changes are stored for next execute.")
addHeader("Settings", "IMPORT / EXPORT")

local exportCard = make("Frame", {
    Size = UDim2.new(1, 0, 0, 80),
    BackgroundColor3 = T.Card,
    BorderSizePixel = 0,
    LayoutOrder = nextOrder("Settings"),
}, tabFrames["Settings"])
corner(8, exportCard)
stroke(1, T.Border, exportCard)

make("TextLabel", {
    Size = UDim2.new(1, -16, 0, 22),
    Position = UDim2.new(0, 12, 0, 6),
    BackgroundTransparency = 1,
    Text = "Export Settings",
    TextColor3 = T.Text,
    TextSize = 13,
    Font = Enum.Font.GothamSemibold,
    TextXAlignment = Enum.TextXAlignment.Left,
}, exportCard)

local exportBox = make("TextBox", {
    Size = UDim2.new(1, -100, 0, 28),
    Position = UDim2.new(0, 8, 0, 34),
    BackgroundColor3 = T.Panel,
    BorderSizePixel = 0,
    Text = "Click EXPORT to generate",
    TextColor3 = T.SubText,
    TextSize = 10,
    Font = Enum.Font.RobotoMono,
    TextXAlignment = Enum.TextXAlignment.Left,
    ClearTextOnFocus = false,
}, exportCard)
corner(6, exportBox)
stroke(1, T.Border, exportBox)
make("UIPadding", { PaddingLeft = UDim.new(0, 6) }, exportBox)

local exportBtn = make("TextButton", {
    Size = UDim2.new(0, 76, 0, 28),
    Position = UDim2.new(1, -84, 0, 34),
    BackgroundColor3 = T.Accent,
    BorderSizePixel = 0,
    Text = "EXPORT",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 11,
    Font = Enum.Font.GothamBold,
}, exportCard)
bindAccent(exportBtn, "BackgroundColor3")
corner(6, exportBtn)

exportBtn.MouseButton1Click:Connect(function()
    exportBox.Text = serializeState()
    exportBox:CaptureFocus()
    exportBox:ReleaseFocus()
    tw(exportBtn, { BackgroundColor3 = Color3.fromRGB(60, 200, 120) })
    task.delay(1.2, function()
        if exportBtn and exportBtn.Parent then
            exportBtn.BackgroundColor3 = T.Accent
        end
    end)
end)

local importCard = make("Frame", {
    Size = UDim2.new(1, 0, 0, 100),
    BackgroundColor3 = T.Card,
    BorderSizePixel = 0,
    LayoutOrder = nextOrder("Settings"),
}, tabFrames["Settings"])
corner(8, importCard)
stroke(1, T.Border, importCard)

make("TextLabel", {
    Size = UDim2.new(1, -16, 0, 22),
    Position = UDim2.new(0, 12, 0, 6),
    BackgroundTransparency = 1,
    Text = "Import Settings",
    TextColor3 = T.Text,
    TextSize = 13,
    Font = Enum.Font.GothamSemibold,
    TextXAlignment = Enum.TextXAlignment.Left,
}, importCard)

make("TextLabel", {
    Size = UDim2.new(1, -16, 0, 16),
    Position = UDim2.new(0, 12, 0, 28),
    BackgroundTransparency = 1,
    Text = "Paste an exported profile string and click IMPORT",
    TextColor3 = T.SubText,
    TextSize = 10,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left,
}, importCard)

local importBox = make("TextBox", {
    Size = UDim2.new(1, -100, 0, 28),
    Position = UDim2.new(0, 8, 0, 52),
    BackgroundColor3 = T.Panel,
    BorderSizePixel = 0,
    Text = "",
    PlaceholderText = "Paste string here...",
    PlaceholderColor3 = T.SubText,
    TextColor3 = T.Text,
    TextSize = 10,
    Font = Enum.Font.RobotoMono,
    TextXAlignment = Enum.TextXAlignment.Left,
    ClearTextOnFocus = false,
}, importCard)
corner(6, importBox)
stroke(1, T.Border, importBox)
make("UIPadding", { PaddingLeft = UDim.new(0, 6) }, importBox)

local importBtn = make("TextButton", {
    Size = UDim2.new(0, 76, 0, 28),
    Position = UDim2.new(1, -84, 0, 52),
    BackgroundColor3 = T.Accent,
    BorderSizePixel = 0,
    Text = "IMPORT",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 11,
    Font = Enum.Font.GothamBold,
}, importCard)
bindAccent(importBtn, "BackgroundColor3")
corner(6, importBtn)

local importStatus = make("TextLabel", {
    Size = UDim2.new(1, -16, 0, 14),
    Position = UDim2.new(0, 12, 0, 82),
    BackgroundTransparency = 1,
    Text = "",
    TextColor3 = T.Accent,
    TextSize = 10,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left,
}, importCard)

local function applyImportedState()
    for key, setter in pairs(numberInputRefs) do -- Corrected from sliderRefs
        if State[key] ~= nil then
            setter(State[key], true)
        end
    end

    for key, ref in pairs(toggleRefs) do
        if State[key] ~= nil then
            ref.setEnabled(State[key], true)
        end
    end

    for key, setter in pairs(dropdownRefs) do
        if State[key] ~= nil then
            setter(State[key], false)
        end
    end

    if keybindRefs.ToggleKeyName then
        keybindRefs.ToggleKeyName(State.ToggleKeyName)
    end

    -- Update theme first, then apply accent to get correct colors
    getTheme()
    applyAccent()
    closeMenu() -- Close and re-open to trigger UI redraw with new theme & accent
    openMenu()
    win.BackgroundTransparency = 1 - (State.MenuOpacity / 100)
    winScale.Scale = State.MenuScale / 100
    win.Draggable = State.Draggable

    -- Apply immediate state changes
    Workspace.Gravity = State.Gravity
    Lighting.ClockTime = State.TimeOfDay
    applyCharacterStats()
    setParticlesDisabled(State.NoParticles) -- Ensure particles are set correctly
    if State.Freecam then disableFreecam() enableFreecam() end -- Re-sync freecam if enabled
    if State.Speedhack then
        -- This logic is handled in the RenderStepped loop, no direct call needed here.
        -- If a custom delta-time speedhack was implemented, it would be reset here.
    end
end

importBtn.MouseButton1Click:Connect(function()
    local s = importBox.Text
    if s == "" then
        importStatus.TextColor3 = Color3.fromRGB(220, 80, 80)
        importStatus.Text = "X  Nothing to import."
        return
    end

    local success, errorMsg = deserializeState(s)
    if success then
        applyImportedState()
        importStatus.TextColor3 = Color3.fromRGB(60, 200, 120)
        importStatus.Text = "OK  Settings applied."
        tw(importBtn, { BackgroundColor3 = Color3.fromRGB(60, 200, 120) })
        task.delay(1.5, function()
            if importBtn and importBtn.Parent then
                importBtn.BackgroundColor3 = T.Accent
            end
            if importStatus and importStatus.Parent then
                importStatus.Text = ""
            end
        end)
    else
        importStatus.TextColor3 = Color3.fromRGB(220, 80, 80)
        importStatus.Text = "X  Invalid profile string: " .. errorMsg
        tw(importBtn, { BackgroundColor3 = Color3.fromRGB(200, 60, 60) })
        task.delay(1.5, function()
            if importBtn and importBtn.Parent then
                importBtn.BackgroundColor3 = T.Accent
            end
        end)
    end
end)

switchTab("Visual")
applyAccent() -- Initial call to apply accent colors to all bound UI elements

UserInputService.JumpRequest:Connect(function()
    if not State.InfJump then
        return
    end
    local character = player.Character
    if not character then
        return
    end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

RunService.Stepped:Connect(function()
    if not State.Noclip then
        return
    end

    local character = player.Character
    if not character then
        return
    end

    for _, obj in ipairs(character:GetDescendants()) do
        if obj:IsA("BasePart") then
            if not noClipOriginal[obj] then
                noClipOriginal[obj] = obj.CanCollide
            end
            obj.CanCollide = false
        end
    end
end)

local autoClickConnection = nil
local lastClickTime = 0

local autoWalkVel = Vector3.new()
local lastAFKMove = tick()

local lastKillAuraAttack = 0

local function findTarget()
    local closestTarget = nil
    local shortestDistance = math.huge

    for _, p in ipairs(Players:GetPlayers()) do
        if p == player then continue end
        local char = p.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp and p.Character:FindFirstChildOfClass("Humanoid") and p.Character:FindFirstChildOfClass("Humanoid").Health > 0 then
                local dist = (hrp.Position - player.Character.HumanoidRootPart.Position).Magnitude
                if dist <= State.KillAuraRange and dist < shortestDistance then
                    shortestDistance = dist
                    closestTarget = p
                end
            end
        end
    end
    return closestTarget
end

RunService.Heartbeat:Connect(function(actualDelta)
    local dt = actualDelta
    if State.Speedhack then
        dt = actualDelta * State.SpeedhackRate -- Scale delta time for effects that rely on it
    end

    if State.FreezeTime and Defaults.FrozenClock ~= nil then
        Lighting.ClockTime = Defaults.FrozenClock
    end

    if State.RainbowAmbient then
        -- dt is already scaled if speedhack is on, ensure color transition is based on actual time or fixed rate
        Defaults.RainbowHue = ((Defaults.RainbowHue or 0) + (actualDelta * 0.1)) % 1
        Lighting.Ambient = Color3.fromHSV(Defaults.RainbowHue, 0.6, 1)
    end

    if State.AntiVoid then
        local character = player.Character
        if character then
            local root = character:FindFirstChild("HumanoidRootPart")
            if root and root.Position.Y < State.AntiVoidHeight then
                root.CFrame = CFrame.new(root.Position.X, State.AntiVoidTeleportY, root.Position.Z)
            end
        end
    end

    -- Auto Click
    if State.AutoClick then
        if tick() - lastClickTime >= (State.AutoClickDelay or 0.05) then
            UserInputService:SimulateMouseClick(Enum.UserInputType.MouseButton1)
            lastClickTime = tick()
        end
    end

    -- Auto Walk
    if State.AutoWalk then
        local character = player.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                local c = camera.CFrame
                autoWalkVel = Vector3.new()
                if State.AutoWalkDirection == "Forward" then
                    autoWalkVel = c.LookVector * humanoid.WalkSpeed
                elseif State.AutoWalkDirection == "Backward" then
                    autoWalkVel = -c.LookVector * humanoid.WalkSpeed
                elseif State.AutoWalkDirection == "Left" then
                    autoWalkVel = -c.RightVector * humanoid.WalkSpeed
                elseif State.AutoWalkDirection == "Right" then
                    autoWalkVel = c.RightVector * humanoid.WalkSpeed
                end
                humanoid:Move(autoWalkVel)
                lastAFKMove = tick() -- Register movement for Anti-AFK
            end
        end
    else
        autoWalkVel = Vector3.new() -- Reset when auto-walk is off
    end

    -- Anti-AFK
    if State.AntiAFK then
        local char = player.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and tick() - lastAFKMove > 10 then -- If no input for 10 seconds, make a tiny move
                hum:Move(Vector3.new(0.01, 0, 0.01))
                lastAFKMove = tick()
            end
        end
    end

    -- Kill Aura
    if State.KillAura then
        local target = findTarget()
        if target and player.Character and player.Character:FindFirstChildOfClass("Humanoid") and player.Character:FindFirstChildOfClass("Humanoid").Health > 0 then
            if tick() - lastKillAuraAttack >= (State.KillAuraDelay or 0.5) then
                local tool = player.Character:FindFirstChildOfClass("Tool")
                if tool and tool:FindFirstChild("Handle") then
                    tool:Activate() -- Activate tool (attack)
                    lastKillAuraAttack = tick()
                end
            end
        end
    end

    -- ESP and Chams
    for _, p in ipairs(Players:GetPlayers()) do
        if p == player then
            continue
        end

        local character = p.Character
        if not character then
            continue
        end

        local root = character:FindFirstChild("HumanoidRootPart")
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not root or not humanoid then
            continue
        end

        local highlight = character:FindFirstChild("_NexusHL")
        if State.Chams then
            if not highlight then
                highlight = Instance.new("Highlight")
                highlight.Name = "_NexusHL"
                highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                highlight.Parent = character
            end
            highlight.FillColor = T.Accent
            highlight.OutlineColor = T.Accent
            highlight.FillTransparency = State.ChamTransparency / 100
            highlight.OutlineTransparency = 0
        else
            if highlight then
                highlight:Destroy()
            end
        end

        local billboard = character:FindFirstChild("_NexusBB")
        if State.ShowNames or State.ShowHealth then
            if not billboard then
                billboard = Instance.new("BillboardGui")
                billboard.Name = "_NexusBB"
                billboard.Size = UDim2.new(0, 150, 0, 44)
                billboard.StudsOffset = Vector3.new(0, 3.5, 0)
                billboard.AlwaysOnTop = true
                billboard.Adornee = root
                billboard.Parent = character

                make("TextLabel", {
                    Name = "lbl",
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    TextColor3 = T.Text,
                    TextSize = 13,
                    Font = Enum.Font.GothamBold,
                    TextStrokeTransparency = 0,
                    TextStrokeColor3 = Color3.new(0, 0, 0),
                    TextWrapped = true,
                }, billboard)
            end

            local lbl = billboard:FindFirstChild("lbl")
            if lbl then
                local dist = math.floor((root.Position - camera.CFrame.Position).Magnitude)
                if dist > State.ESPMaxDistance then
                    lbl.Text = ""
                else
                    local text = ""
                    if State.ShowNames then
                        text = p.Name .. (State.ShowDistance and (" [" .. dist .. "m]") or "")
                    end
                    if State.ShowHealth then
                        if text ~= "" then
                            text = text .. "\n"
                        end
                        text = text .. math.floor(humanoid.Health) .. "/" .. math.floor(humanoid.MaxHealth) .. " HP"
                    end
                    lbl.Text = text
                    lbl.TextColor3 = T.Text
                end
            end
        else
            if billboard then
                billboard:Destroy()
            end
        end
    end
end)

RunService.RenderStepped:Connect(function(dt)
    if not State.Freecam then
        return
    end

    local boosting = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
    local speed = State.FreecamSpeed * (boosting and State.FreecamBoostMult or 1)
    local smoothAlpha = math.clamp(State.FreecamSmoothFactor / 100, 0.001, 0.999) -- Clamp to prevent division by zero or overly aggressive lerp

    local delta = UserInputService:GetMouseDelta()
    local sens = State.FreecamMouseSens * 0.0025

    freecamYaw = freecamYaw - (delta.X * sens)
    freecamPitch = math.clamp(freecamPitch - (delta.Y * sens), math.rad(-89), math.rad(89))

    local rotation = CFrame.fromOrientation(freecamPitch, freecamYaw, 0)

    local moveX = (UserInputService:IsKeyDown(Enum.KeyCode.D) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.A) and 1 or 0)
    local moveY = (UserInputService:IsKeyDown(Enum.KeyCode.E) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.Q) and 1 or 0)
    local moveZ = (UserInputService:IsKeyDown(Enum.KeyCode.S) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.W) and 1 or 0)

    local moveVector = Vector3.new(moveX, moveY, moveZ)
    if moveVector.Magnitude > 0 then
        moveVector = moveVector.Unit
        local worldMove =
            (rotation.RightVector * moveVector.X) +
            (rotation.UpVector * moveVector.Y) +
            (rotation.LookVector * moveVector.Z)
        freecamPos = freecamPos + (worldMove * speed * dt)
    end

    local targetCFrame = CFrame.new(freecamPos) * rotation
    if State.FreecamSmooth then
        camera.CFrame = camera.CFrame:Lerp(targetCFrame, smoothAlpha)
    else
        camera.CFrame = targetCFrame
    end

    camera.FieldOfView = State.FreecamFOV

    if boosting then
        speedHUDLabel.Text = "BOOST  x" .. tostring(State.FreecamBoostMult)
        speedHUDLabel.TextColor3 = Color3.fromRGB(255, 210, 60)
    else
        speedHUDLabel.Text = "CAM  |  NORMAL"
        speedHUDLabel.TextColor3 = T.Accent
    end
end)

local bodyVelocity
local bodyGyro

RunService.Heartbeat:Connect(function()
    local character = player.Character
    if not character then
        return
    end

    local root = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid then
        return
    end

    if State.Fly then
        humanoid.PlatformStand = true

        if not bodyVelocity or not bodyVelocity.Parent then
            bodyVelocity = Instance.new("BodyVelocity")
            bodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
            bodyVelocity.Parent = root
        end

        if not bodyGyro or not bodyGyro.Parent then
            bodyGyro = Instance.new("BodyGyro")
            bodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
            bodyGyro.P = 1e4
            bodyGyro.Parent = root
        end

        local dir = Vector3.new(
            (UserInputService:IsKeyDown(Enum.KeyCode.D) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.A) and 1 or 0),
            (UserInputService:IsKeyDown(Enum.KeyCode.Space) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) and 1 or 0),
            (UserInputService:IsKeyDown(Enum.KeyCode.S) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.W) and 1 or 0)
        )

        if dir.Magnitude > 0 then
            bodyVelocity.Velocity = camera.CFrame:VectorToWorldSpace(dir.Unit) * State.FlySpeed
        else
            bodyVelocity.Velocity = Vector3.zero
        end

        bodyGyro.CFrame = camera.CFrame
    else
        humanoid.PlatformStand = false

        if bodyVelocity and bodyVelocity.Parent then
            bodyVelocity:Destroy()
            bodyVelocity = nil
        end

        if bodyGyro and bodyGyro.Parent then
            bodyGyro:Destroy()
            bodyGyro = nil
        end
    end
end)

player.CharacterAdded:Connect(function(character)
    clearNoClipCache()

    if State.Freecam then
        disableFreecam()
        State.Freecam = false
        if toggleRefs.Freecam then
            toggleRefs.Freecam.setEnabled(false, true)
        end
    end

    local humanoid = character:WaitForChild("Humanoid", 5)
    if humanoid then
        task.wait(0.1)
        applyCharacterStats() -- Re-apply walkspeed/jumppower on character change
    end
end)

local lastToggle = 0

UserInputService.InputBegan:Connect(function(input, processed)
    if input.KeyCode == Config.ToggleKey then
        local now = tick()
        if now - lastToggle < 0.25 then
            return
        end
        lastToggle = now

        if menuOpen then
            closeMenu()
        else
            openMenu()
        end
        return
    end

    if processed then
        return
    end

    -- Silent Aim logic
    if State.SilentAim and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
        local target = findTarget()
        if target and target.Character and player.Character then
            local targetHRP = target.Character:FindFirstChild("HumanoidRootPart")
            if targetHRP then
                local mouse = player:GetMouse()
                -- Temporarily override mouse target for the click
                mouse.Target = targetHRP
            end
        end
    end
    -- Reset mouse target after click for silent aim (or handle this in MouseButton1Up)
    -- This basic implementation might require adjustments based on how the game registers clicks.
end)

UserInputService.InputEnded:Connect(function(input, processed)
    -- Silent Aim reset
    if State.SilentAim and input.UserInputType == Enum.UserInputType.MouseButton1 then
        player:GetMouse().Target = nil -- Reset mouse target after button release
    end
end)

task.defer(function()
    task.wait(0.5) -- give a short delay to ensure GUI and CoreGui are ready
    openMenu()
    menuOpen = true
    win.Visible = true
    win.BackgroundTransparency = 1 - (State.MenuOpacity / 100)
    winScale.Scale = State.MenuScale / 100
end)


applyCharacterStats()
Workspace.Gravity = State.Gravity
Lighting.ClockTime = State.TimeOfDay
if State.NoParticles then setParticlesDisabled(true) end -- Apply particle state on load

-- === Hint Box (separate from main GUI) ===
local hintBox = Instance.new("ScreenGui")
hintBox.Name = "NexusHintBox"
hintBox.IgnoreGuiInset = true
hintBox.ResetOnSpawn = false
hintBox.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
hintBox.Parent = game:GetService("CoreGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 320, 0, 120)
frame.Position = UDim2.new(0.5, -160, 0.8, -60)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = hintBox

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = frame

local stroke = Instance.new("UIStroke")
stroke.Thickness = 1
stroke.Color = Color3.fromRGB(100, 180, 255)
stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
stroke.Parent = frame

local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, -20, 0, 40)
label.Position = UDim2.new(0, 10, 0, 10)
label.BackgroundTransparency = 1
label.Text = "Press [Right Shift] to open/close the Nexus menu"
label.TextColor3 = Color3.fromRGB(230, 230, 240)
label.TextWrapped = true
label.Font = Enum.Font.GothamBold
label.TextSize = 14
label.TextXAlignment = Enum.TextXAlignment.Center
label.TextYAlignment = Enum.TextYAlignment.Center
label.Parent = frame

-- ✨ Discord Invite Label
local discordLabel = Instance.new("TextLabel")
discordLabel.Size = UDim2.new(1, -20, 0, 24)
discordLabel.Position = UDim2.new(0, 10, 0, 60)
discordLabel.BackgroundTransparency = 1
discordLabel.Text = "Join our Discord: (https://discord.gg/hcRpXPnHAE)"
discordLabel.TextColor3 = Color3.fromRGB(140, 180, 255)
discordLabel.TextWrapped = false
discordLabel.Font = Enum.Font.Gotham
discordLabel.TextSize = 13
discordLabel.TextXAlignment = Enum.TextXAlignment.Center
discordLabel.TextYAlignment = Enum.TextYAlignment.Center
discordLabel.Parent = frame

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 24, 0, 24)
closeBtn.Position = UDim2.new(1, -30, 0, 6)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.TextSize = 14
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = frame

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 6)
btnCorner.Parent = closeBtn

closeBtn.MouseEnter:Connect(function()
    closeBtn.BackgroundColor3 = Color3.fromRGB(240, 80, 80)
end)

closeBtn.MouseLeave:Connect(function()
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
end)

closeBtn.MouseButton1Click:Connect(function()
    frame:Destroy()
end)

-- Optional: clicking the Discord text copies the invite link
discordLabel.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if setclipboard then
            setclipboard("(https://discord.gg/hcRpXPnHAE)")
        end
        discordLabel.TextColor3 = Color3.fromRGB(60, 200, 120)
        discordLabel.Text = "Copied Discord link!"
        task.wait(1.5)
        discordLabel.Text = "Join our Discord: (https://discord.gg/hcRpXPnHAE)"
        discordLabel.TextColor3 = Color3.fromRGB(140, 180, 255)
    end
end)
-- === End Hint Box ===



print("Nexus Client " .. Config.Version .. " loaded. Press " .. State.ToggleKeyName .. " to open.")


