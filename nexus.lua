-- ============================================================
--  NEXUS CLIENT  |  Executor Ready
-- ============================================================
if not game:IsLoaded() then game.Loaded:Wait() end

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local Lighting         = game:GetService("Lighting")
local TweenService     = game:GetService("TweenService")
local Workspace        = game:GetService("Workspace")
local CoreGui          = game:GetService("CoreGui")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- Wait for character
if not player.Character then player.CharacterAdded:Wait() end
local character = player.Character

local Config = {
    ToggleKey   = Enum.KeyCode.RightShift,
    AccentColor = Color3.fromRGB(100, 180, 255),
    Theme       = "Dark",
    Version     = "v1.0.0",
}

local Defaults = {}
local function cacheDefaults()
    Defaults.Ambient    = Lighting.Ambient
    Defaults.Brightness = Lighting.Brightness
    Defaults.FogEnd     = Lighting.FogEnd
    Defaults.FogColor   = Lighting.FogColor
    Defaults.Gravity    = Workspace.Gravity
    Defaults.FOV        = camera.FieldOfView
    Defaults.ClockTime  = Lighting.ClockTime
end
cacheDefaults()

local State = {
    Fullbright     = false,
    NoFog          = false,
    RainbowAmbient = false,
    FreezeTime     = false,
    NoShadows      = false,
    Noclip         = false,
    InfJump        = false,
    Fly            = false,
    AntiVoid       = false,
    WalkSpeed      = 16,
    JumpPower      = 50,
    FlySpeed       = 40,
    Freecam        = false,
    FreecamSpeed   = 30,
    FreecamSmooth  = true,
    FreecamFOV     = 70,
    ESP            = false,
    Tracers        = false,
    Chams          = false,
    ShowHealth     = false,
    ShowNames      = false,
    Gravity        = 196,
    NoParticles    = false,
    MenuOpacity    = 0.97,
    Draggable      = true,
}

local Themes = {
    Dark = {
        BG      = Color3.fromRGB(14, 14, 18),
        Panel   = Color3.fromRGB(20, 20, 26),
        Card    = Color3.fromRGB(26, 26, 34),
        Border  = Color3.fromRGB(40, 40, 55),
        Text    = Color3.fromRGB(220, 220, 230),
        SubText = Color3.fromRGB(120, 120, 140),
        Accent  = Config.AccentColor,
        On      = Color3.fromRGB(60, 200, 120),
        Off     = Color3.fromRGB(60, 60, 75),
    },
    Neon = {
        BG      = Color3.fromRGB(5, 5, 10),
        Panel   = Color3.fromRGB(10, 10, 20),
        Card    = Color3.fromRGB(15, 15, 28),
        Border  = Color3.fromRGB(80, 40, 120),
        Text    = Color3.fromRGB(230, 200, 255),
        SubText = Color3.fromRGB(140, 100, 180),
        Accent  = Color3.fromRGB(180, 80, 255),
        On      = Color3.fromRGB(180, 80, 255),
        Off     = Color3.fromRGB(40, 20, 60),
    },
    Light = {
        BG      = Color3.fromRGB(240, 240, 248),
        Panel   = Color3.fromRGB(255, 255, 255),
        Card    = Color3.fromRGB(248, 248, 255),
        Border  = Color3.fromRGB(200, 200, 215),
        Text    = Color3.fromRGB(30, 30, 40),
        SubText = Color3.fromRGB(100, 100, 120),
        Accent  = Color3.fromRGB(80, 140, 255),
        On      = Color3.fromRGB(40, 180, 100),
        Off     = Color3.fromRGB(180, 180, 200),
    },
}

local T = Themes[Config.Theme] or Themes.Dark

-- ============================================================
--  DESTROY OLD GUI IF RE-EXECUTING
-- ============================================================
local oldGui = CoreGui:FindFirstChild("NexusClient")
if oldGui then oldGui:Destroy() end

-- ============================================================
--  GUI HELPERS
-- ============================================================
local gui = Instance.new("ScreenGui")
gui.Name           = "NexusClient"
gui.ResetOnSpawn   = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.IgnoreGuiInset = true

-- Executor-safe parenting
local ok = pcall(function() gui.Parent = CoreGui end)
if not ok then gui.Parent = player.PlayerGui end

local function make(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props) do obj[k] = v end
    if parent then obj.Parent = parent end
    return obj
end

local function corner(r, p)
    make("UICorner", { CornerRadius = UDim.new(0, r) }, p)
end

local function stroke(thickness, color, p)
    make("UIStroke", {
        Thickness       = thickness,
        Color           = color,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, p)
end

local function tween(obj, props, t)
    TweenService:Create(obj, TweenInfo.new(t or 0.18, Enum.EasingStyle.Quad), props):Play()
end

-- ============================================================
--  MAIN WINDOW
-- ============================================================
local win = make("Frame", {
    Size                   = UDim2.new(0, 580, 0, 420),
    Position               = UDim2.new(0.5, -290, 0.5, -210),
    BackgroundColor3       = T.BG,
    BackgroundTransparency = 1 - State.MenuOpacity,
    BorderSizePixel        = 0,
    Visible                = false,
    Active                 = true,
    Draggable              = true,
}, gui)
corner(12, win)
stroke(1, T.Border, win)

local topBar = make("Frame", {
    Size             = UDim2.new(1, 0, 0, 48),
    BackgroundColor3 = T.Panel,
    BorderSizePixel  = 0,
}, win)
corner(12, topBar)

make("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, T.Accent),
        ColorSequenceKeypoint.new(1, T.BG),
    }),
    Rotation     = 90,
    Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.6),
        NumberSequenceKeypoint.new(1, 1),
    }),
}, topBar)

make("TextLabel", {
    Size                   = UDim2.new(0, 200, 1, 0),
    Position               = UDim2.new(0, 16, 0, 0),
    BackgroundTransparency = 1,
    Text                   = "NEXUS",
    TextColor3             = T.Text,
    TextSize               = 18,
    Font                   = Enum.Font.GothamBold,
    TextXAlignment         = Enum.TextXAlignment.Left,
}, topBar)

make("TextLabel", {
    Size                   = UDim2.new(0, 80, 1, 0),
    Position               = UDim2.new(1, -90, 0, 0),
    BackgroundTransparency = 1,
    Text                   = Config.Version,
    TextColor3             = T.SubText,
    TextSize               = 11,
    Font                   = Enum.Font.Gotham,
    TextXAlignment         = Enum.TextXAlignment.Right,
}, topBar)

local closeBtn = make("TextButton", {
    Size             = UDim2.new(0, 28, 0, 28),
    Position         = UDim2.new(1, -36, 0.5, -14),
    BackgroundColor3 = Color3.fromRGB(200, 60, 60),
    Text             = "x",
    TextColor3       = Color3.fromRGB(255, 255, 255),
    TextSize         = 12,
    Font             = Enum.Font.GothamBold,
    BorderSizePixel  = 0,
}, topBar)
corner(6, closeBtn)
closeBtn.MouseButton1Click:Connect(function()
    tween(win, { Position = UDim2.new(0.5, -290, 0.6, -210), BackgroundTransparency = 1 }, 0.22)
    task.delay(0.22, function() win.Visible = false end)
end)

-- ============================================================
--  TAB BAR
-- ============================================================
local tabList   = { "Visual", "Player", "Freecam", "ESP", "World", "Settings" }
local tabFrames = {}
local tabBtns   = {}

local tabBar = make("Frame", {
    Size             = UDim2.new(0, 110, 1, -48),
    Position         = UDim2.new(0, 0, 0, 48),
    BackgroundColor3 = T.Panel,
    BorderSizePixel  = 0,
}, win)

local tabIcons = {
    Visual   = "V",
    Player   = "P",
    Freecam  = "C",
    ESP      = "E",
    World    = "W",
    Settings = "S",
}

local function switchTab(name)
    for _, t in ipairs(tabList) do
        local btn   = tabBtns[t]
        local frame = tabFrames[t]
        if t == name then
            tween(btn, { BackgroundColor3 = T.Accent, TextColor3 = Color3.fromRGB(255, 255, 255) })
            frame.Visible = true
        else
            tween(btn, { BackgroundColor3 = T.Card, TextColor3 = T.SubText })
            frame.Visible = false
        end
    end
end

for i, name in ipairs(tabList) do
    local btn = make("TextButton", {
        Size             = UDim2.new(1, -12, 0, 38),
        Position         = UDim2.new(0, 6, 0, 8 + (i - 1) * 44),
        BackgroundColor3 = T.Card,
        Text             = (tabIcons[name] or "") .. "  " .. name,
        TextColor3       = T.SubText,
        TextSize         = 13,
        Font             = Enum.Font.GothamSemibold,
        BorderSizePixel  = 0,
        TextXAlignment   = Enum.TextXAlignment.Left,
    }, tabBar)
    corner(8, btn)
    make("UIPadding", { PaddingLeft = UDim.new(0, 10) }, btn)
    tabBtns[name] = btn

    local frame = make("ScrollingFrame", {
        Size                 = UDim2.new(1, -118, 1, -56),
        Position             = UDim2.new(0, 114, 0, 52),
        BackgroundTransparency = 1,
        BorderSizePixel      = 0,
        ScrollBarThickness   = 3,
        ScrollBarImageColor3 = T.Accent,
        AutomaticCanvasSize  = Enum.AutomaticSize.Y,
        CanvasSize           = UDim2.new(0, 0, 0, 0),
        Visible              = (i == 1),
    }, win)

    make("UIListLayout", {
        Padding   = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, frame)
    make("UIPadding", {
        PaddingTop    = UDim.new(0, 6),
        PaddingBottom = UDim.new(0, 6),
        PaddingLeft   = UDim.new(0, 2),
        PaddingRight  = UDim.new(0, 8),
    }, frame)

    tabFrames[name] = frame
    btn.MouseButton1Click:Connect(function() switchTab(name) end)
end

-- ============================================================
--  WIDGET BUILDERS
-- ============================================================
local layoutOrder = {}
for _, t in ipairs(tabList) do layoutOrder[t] = 0 end
local function nextOrder(tabName)
    layoutOrder[tabName] = layoutOrder[tabName] + 1
    return layoutOrder[tabName]
end

local function addToggle(tabName, label, desc, callback)
    local f    = tabFrames[tabName]
    local card = make("Frame", {
        Size             = UDim2.new(1, 0, 0, 56),
        BackgroundColor3 = T.Card,
        BorderSizePixel  = 0,
        LayoutOrder      = nextOrder(tabName),
    }, f)
    corner(8, card)
    stroke(1, T.Border, card)

    make("TextLabel", {
        Size                   = UDim2.new(1, -70, 0, 22),
        Position               = UDim2.new(0, 12, 0, 8),
        BackgroundTransparency = 1,
        Text                   = label,
        TextColor3             = T.Text,
        TextSize               = 13,
        Font                   = Enum.Font.GothamSemibold,
        TextXAlignment         = Enum.TextXAlignment.Left,
    }, card)

    make("TextLabel", {
        Size                   = UDim2.new(1, -70, 0, 18),
        Position               = UDim2.new(0, 12, 0, 30),
        BackgroundTransparency = 1,
        Text                   = desc,
        TextColor3             = T.SubText,
        TextSize               = 11,
        Font                   = Enum.Font.Gotham,
        TextXAlignment         = Enum.TextXAlignment.Left,
    }, card)

    local pill = make("Frame", {
        Size             = UDim2.new(0, 44, 0, 22),
        Position         = UDim2.new(1, -56, 0.5, -11),
        BackgroundColor3 = T.Off,
        BorderSizePixel  = 0,
    }, card)
    corner(11, pill)

    local knob = make("Frame", {
        Size             = UDim2.new(0, 16, 0, 16),
        Position         = UDim2.new(0, 3, 0.5, -8),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel  = 0,
    }, pill)
    corner(8, knob)

    local enabled = false
    local btn = make("TextButton", {
        Size                   = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text                   = "",
        ZIndex                 = 2,
    }, card)

    btn.MouseButton1Click:Connect(function()
        enabled = not enabled
        tween(pill, { BackgroundColor3 = enabled and T.On or T.Off })
        tween(knob, {
            Position = enabled
                and UDim2.new(0, 25, 0.5, -8)
                or  UDim2.new(0, 3,  0.5, -8),
        })
        callback(enabled)
    end)
    return card
end

local function addSlider(tabName, label, min, max, default, callback)
    local f    = tabFrames[tabName]
    local card = make("Frame", {
        Size             = UDim2.new(1, 0, 0, 64),
        BackgroundColor3 = T.Card,
        BorderSizePixel  = 0,
        LayoutOrder      = nextOrder(tabName),
    }, f)
    corner(8, card)
    stroke(1, T.Border, card)

    local valLabel = make("TextLabel", {
        Size                   = UDim2.new(0, 50, 0, 20),
        Position               = UDim2.new(1, -60, 0, 10),
        BackgroundTransparency = 1,
        Text                   = tostring(default),
        TextColor3             = T.Accent,
        TextSize               = 12,
        Font                   = Enum.Font.GothamBold,
        TextXAlignment         = Enum.TextXAlignment.Right,
    }, card)

    make("TextLabel", {
        Size                   = UDim2.new(1, -70, 0, 20),
        Position               = UDim2.new(0, 12, 0, 10),
        BackgroundTransparency = 1,
        Text                   = label,
        TextColor3             = T.Text,
        TextSize               = 13,
        Font                   = Enum.Font.GothamSemibold,
        TextXAlignment         = Enum.TextXAlignment.Left,
    }, card)

    local track = make("Frame", {
        Size             = UDim2.new(1, -24, 0, 4),
        Position         = UDim2.new(0, 12, 0, 46),
        BackgroundColor3 = T.Border,
        BorderSizePixel  = 0,
    }, card)
    corner(2, track)

    local initPct = (default - min) / (max - min)
    local fill = make("Frame", {
        Size             = UDim2.new(initPct, 0, 1, 0),
        BackgroundColor3 = T.Accent,
        BorderSizePixel  = 0,
    }, track)
    corner(2, fill)

    local handle = make("Frame", {
        Size             = UDim2.new(0, 12, 0, 12),
        Position         = UDim2.new(initPct, -6, 0.5, -6),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel  = 0,
    }, track)
    corner(6, handle)

    local dragging = false
    local function updateSlider(x)
        local abs = track.AbsolutePosition.X
        local w   = track.AbsoluteSize.X
        if w == 0 then return end
        local pct = math.clamp((x - abs) / w, 0, 1)
        local val = math.floor(min + pct * (max - min))
        valLabel.Text = tostring(val)
        tween(fill,   { Size     = UDim2.new(pct, 0, 1, 0) },     0.05)
        tween(handle, { Position = UDim2.new(pct, -6, 0.5, -6) }, 0.05)
        callback(val)
    end

    local trackBtn = make("TextButton", {
        Size                   = UDim2.new(1, 0, 0, 20),
        Position               = UDim2.new(0, 0, 0, 38),
        BackgroundTransparency = 1,
        Text                   = "",
        ZIndex                 = 2,
    }, card)

    trackBtn.MouseButton1Down:Connect(function()
        dragging = true
        updateSlider(UserInputService:GetMouseLocation().X)
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            updateSlider(inp.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

local function addHeader(tabName, text)
    local f = tabFrames[tabName]
    local lbl = make("TextLabel", {
        Size                   = UDim2.new(1, 0, 0, 22),
        BackgroundTransparency = 1,
        Text                   = text,
        TextColor3             = T.Accent,
        TextSize               = 11,
        Font                   = Enum.Font.GothamBold,
        TextXAlignment         = Enum.TextXAlignment.Left,
        LayoutOrder            = nextOrder(tabName),
    }, f)
    make("UIPadding", { PaddingLeft = UDim.new(0, 4) }, lbl)
end

-- ============================================================
--  POPULATE TABS
-- ============================================================

-- VISUAL
addHeader("Visual", "LIGHTING")
addToggle("Visual", "Fullbright", "Max ambient, see everything clearly", function(on)
    Lighting.Ambient    = on and Color3.fromRGB(255, 255, 255) or Defaults.Ambient
    Lighting.Brightness = on and 2 or Defaults.Brightness
end)
addToggle("Visual", "No Fog", "Remove all atmospheric fog", function(on)
    Lighting.FogEnd = on and 1000000 or Defaults.FogEnd
end)
addToggle("Visual", "Rainbow Ambient", "Cycles ambient color through hues", function(on)
    State.RainbowAmbient = on
    if not on then Lighting.Ambient = Defaults.Ambient end
end)
addToggle("Visual", "No Shadows", "Disable shadow rendering", function(on)
    Lighting.GlobalShadows = not on
end)
addHeader("Visual", "TIME")
addToggle("Visual", "Freeze Time", "Lock time of day", function(on)
    State.FreezeTime = on
    if on then Defaults.FrozenClock = Lighting.ClockTime end
end)
addSlider("Visual", "Time of Day", 0, 24, 14, function(v)
    Lighting.ClockTime = v
end)

-- PLAYER
addHeader("Player", "MOVEMENT")
addSlider("Player", "Walk Speed", 8, 150, 16, function(v)
    State.WalkSpeed = v
    local c = player.Character
    if c then
        local h = c:FindFirstChildOfClass("Humanoid")
        if h then h.WalkSpeed = v end
    end
end)
addSlider("Player", "Jump Power", 10, 200, 50, function(v)
    State.JumpPower = v
    local c = player.Character
    if c then
        local h = c:FindFirstChildOfClass("Humanoid")
        if h then h.JumpPower = v end
    end
end)
addToggle("Player", "Infinite Jump", "Jump while in the air", function(on)
    State.InfJump = on
end)
addToggle("Player", "Noclip", "Phase through walls", function(on)
    State.Noclip = on
end)
addHeader("Player", "ADVANCED")
addToggle("Player", "Fly", "Free flight", function(on)
    State.Fly = on
end)
addSlider("Player", "Fly Speed", 10, 200, 40, function(v)
    State.FlySpeed = v
end)
addToggle("Player", "Anti-Void", "Teleport back if you fall out", function(on)
    State.AntiVoid = on
end)

-- FREECAM
local freecamCF = camera.CFrame
addHeader("Freecam", "CAMERA")
addToggle("Freecam", "Freecam", "Detach camera from character", function(on)
    State.Freecam = on
    if on then
        freecamCF = camera.CFrame
        camera.CameraType = Enum.CameraType.Scriptable
    else
        camera.CameraType  = Enum.CameraType.Custom
        camera.FieldOfView = Defaults.FOV
    end
end)
addToggle("Freecam", "Smooth Movement", "Cinematic eased movement", function(on)
    State.FreecamSmooth = on
end)
addSlider("Freecam", "Freecam Speed", 5, 200, 30, function(v)
    State.FreecamSpeed = v
end)
addSlider("Freecam", "Field of View", 40, 120, 70, function(v)
    State.FreecamFOV = v
    if State.Freecam then camera.FieldOfView = v end
end)

-- ESP
addHeader("ESP", "PLAYER INFO")
addToggle("ESP", "Chams", "Highlight players through walls", function(on)
    State.Chams = on
    if not on then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= player and p.Character then
                local hl = p.Character:FindFirstChild("_NexusHL")
                if hl then hl:Destroy() end
            end
        end
    end
end)
addToggle("ESP", "Show Health", "Health bar above players", function(on)
    State.ShowHealth = on
end)
addToggle("ESP", "Show Names + Distance", "Names and distance above heads", function(on)
    State.ShowNames = on
    if not on and not State.ShowHealth then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= player and p.Character then
                local bb = p.Character:FindFirstChild("_NexusBB")
                if bb then bb:Destroy() end
            end
        end
    end
end)

-- WORLD
addHeader("World", "PHYSICS")
addSlider("World", "Gravity", 0, 400, 196, function(v)
    Workspace.Gravity = v
end)
addHeader("World", "ENVIRONMENT")
addToggle("World", "No Particles", "Remove all particles", function(on)
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("ParticleEmitter") or v:IsA("Fire")
        or v:IsA("Smoke") or v:IsA("Sparkles") then
            v.Enabled = not on
        end
    end
end)

-- SETTINGS
addHeader("Settings", "DISPLAY")
addSlider("Settings", "Menu Opacity", 50, 100, 97, function(v)
    win.BackgroundTransparency = 1 - v / 100
end)
addToggle("Settings", "Draggable Window", "Allow dragging the menu", function(on)
    win.Draggable = on
end)
addHeader("Settings", "INFO")
local infoCard = make("Frame", {
    Size             = UDim2.new(1, 0, 0, 48),
    BackgroundColor3 = T.Card,
    BorderSizePixel  = 0,
    LayoutOrder      = nextOrder("Settings"),
}, tabFrames["Settings"])
corner(8, infoCard)
stroke(1, T.Border, infoCard)
make("TextLabel", {
    Size                   = UDim2.new(1, -16, 1, 0),
    Position               = UDim2.new(0, 12, 0, 0),
    BackgroundTransparency = 1,
    Text                   = "Nexus Client " .. Config.Version .. " | RightShift to toggle",
    TextColor3             = T.SubText,
    TextSize               = 12,
    Font                   = Enum.Font.Gotham,
    TextXAlignment         = Enum.TextXAlignment.Left,
    TextWrapped            = true,
}, infoCard)

-- ============================================================
--  RUNTIME LOOPS
-- ============================================================

-- Infinite jump
UserInputService.JumpRequest:Connect(function()
    if not State.InfJump then return end
    local c = player.Character
    if not c then return end
    local h = c:FindFirstChildOfClass("Humanoid")
    if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
end)

-- Noclip
RunService.Stepped:Connect(function()
    if not State.Noclip then return end
    local c = player.Character
    if not c then return end
    for _, p in pairs(c:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = false end
    end
end)

-- Freeze time
RunService.Heartbeat:Connect(function()
    if State.FreezeTime and Defaults.FrozenClock then
        Lighting.ClockTime = Defaults.FrozenClock
    end
end)

-- Rainbow ambient
local hue = 0
RunService.Heartbeat:Connect(function(dt)
    if not State.RainbowAmbient then return end
    hue = (hue + dt * 0.1) % 1
    Lighting.Ambient = Color3.fromHSV(hue, 0.6, 1)
end)

-- Freecam
RunService.RenderStepped:Connect(function(dt)
    if not State.Freecam then return end
    local spd   = State.FreecamSpeed * dt
    local delta = UserInputService:GetMouseDelta()
    local rx, ry, rz = freecamCF:ToEulerAnglesYXZ()
    local newPitch = math.clamp(rx - delta.Y * 0.003, -1.5, 1.5)
    freecamCF = CFrame.new(freecamCF.Position)
        * CFrame.Angles(0, ry - delta.X * 0.003, 0)
        * CFrame.Angles(newPitch, 0, 0)
    local move = Vector3.new(
        (UserInputService:IsKeyDown(Enum.KeyCode.D) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.A) and 1 or 0),
        (UserInputService:IsKeyDown(Enum.KeyCode.E) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.Q) and 1 or 0),
        (UserInputService:IsKeyDown(Enum.KeyCode.S) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.W) and 1 or 0)
    )
    freecamCF = freecamCF * CFrame.new(move * spd)
    if State.FreecamSmooth then
        camera.CFrame = camera.CFrame:Lerp(freecamCF, 0.3)
    else
        camera.CFrame = freecamCF
    end
    camera.FieldOfView = State.FreecamFOV
end)

-- Anti-void
RunService.Heartbeat:Connect(function()
    if not State.AntiVoid then return end
    local c = player.Character
    if not c then return end
    local root = c:FindFirstChild("HumanoidRootPart")
    if root and root.Position.Y < -200 then
        root.CFrame = CFrame.new(0, 50, 0)
    end
end)

-- Fly
local bodyVel, bodyGyro
RunService.Heartbeat:Connect(function()
    local c = player.Character
    if not c then return end
    local root = c:FindFirstChild("HumanoidRootPart")
    local hum  = c:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end
    if State.Fly then
        hum.PlatformStand = true
        if not bodyVel or not bodyVel.Parent then
            bodyVel          = Instance.new("BodyVelocity")
            bodyVel.MaxForce = Vector3.new(1e5, 1e5, 1e5)
            bodyVel.Parent   = root
        end
        if not bodyGyro or not bodyGyro.Parent then
            bodyGyro           = Instance.new("BodyGyro")
            bodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
            bodyGyro.P         = 1e4
            bodyGyro.Parent    = root
        end
        local dir = Vector3.new(
            (UserInputService:IsKeyDown(Enum.KeyCode.D) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.A) and 1 or 0),
            (UserInputService:IsKeyDown(Enum.KeyCode.Space) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) and 1 or 0),
            (UserInputService:IsKeyDown(Enum.KeyCode.S) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.W) and 1 or 0)
        )
        bodyVel.Velocity = dir.Magnitude > 0
            and camera.CFrame:VectorToWorldSpace(dir.Unit) * State.FlySpeed
            or Vector3.new(0, 0, 0)
        bodyGyro.CFrame = camera.CFrame
    else
        hum.PlatformStand = false
        if bodyVel  and bodyVel.Parent  then bodyVel:Destroy();  bodyVel  = nil end
        if bodyGyro and bodyGyro.Parent then bodyGyro:Destroy(); bodyGyro = nil end
    end
end)

-- ESP / Chams / Billboards
RunService.Heartbeat:Connect(function()
    for _, p in pairs(Players:GetPlayers()) do
        if p == player then continue end
        local c = p.Character
        if not c then continue end
        local root = c:FindFirstChild("HumanoidRootPart")
        local hum  = c:FindFirstChildOfClass("Humanoid")
        if not root or not hum then continue end

        local hl = c:FindFirstChild("_NexusHL")
        if State.Chams then
            if not hl then
                hl = Instance.new("SelectionBox")
                hl.Name                = "_NexusHL"
                hl.Adornee             = c
                hl.Color3              = T.Accent
                hl.LineThickness       = 0.04
                hl.SurfaceTransparency = 0.75
                hl.SurfaceColor3       = T.Accent
                hl.Parent              = c
            end
        else
            if hl then hl:Destroy() end
        end

        local bb = c:FindFirstChild("_NexusBB")
        if State.ShowNames or State.ShowHealth then
            if not bb then
                bb             = Instance.new("BillboardGui")
                bb.Name        = "_NexusBB"
                bb.Size        = UDim2.new(0, 140, 0, 40)
                bb.StudsOffset = Vector3.new(0, 3.5, 0)
                bb.AlwaysOnTop = true
                bb.Adornee     = root
                bb.Parent      = c
                make("TextLabel", {
                    Name                   = "lbl",
                    Size                   = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    TextColor3             = T.Text,
                    TextSize               = 13,
                    Font                   = Enum.Font.GothamBold,
                    TextStrokeTransparency = 0,
                    TextStrokeColor3       = Color3.fromRGB(0, 0, 0),
                    TextWrapped            = true,
                }, bb)
            end
            local lbl = bb:FindFirstChild("lbl")
            if lbl then
                local dist = math.floor((root.Position - camera.CFrame.Position).Magnitude)
                local txt  = ""
                if State.ShowNames  then txt = p.Name .. " [" .. dist .. "m]\n" end
                if State.ShowHealth then txt = txt .. math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth) .. " HP" end
                lbl.Text = txt
            end
        else
            if bb then bb:Destroy() end
        end
    end
end)

-- Reapply stats on respawn
player.CharacterAdded:Connect(function(c)
    bodyVel  = nil
    bodyGyro = nil
    local hum = c:WaitForChild("Humanoid", 5)
    if hum then
        task.wait(0.1)
        hum.WalkSpeed = State.WalkSpeed
        hum.JumpPower = State.JumpPower
    end
end)

-- ============================================================
--  TOGGLE MENU
-- ============================================================
UserInputService.InputBegan:Connect(function(inp, processed)
    if processed then return end
    if inp.KeyCode ~= Config.ToggleKey then return end
    if win.Visible then
        tween(win, { Position = UDim2.new(0.5, -290, 0.6, -210), BackgroundTransparency = 1 }, 0.22)
        task.delay(0.22, function() win.Visible = false end)
    else
        win.Visible                = true
        win.BackgroundTransparency = 1
        win.Position               = UDim2.new(0.5, -290, 0.4, -210)
        tween(win, {
            BackgroundTransparency = 1 - State.MenuOpacity,
            Position               = UDim2.new(0.5, -290, 0.5, -210),
        }, 0.22)
    end
end)

print("Nexus Client loaded -- RightShift to open")

print("Nexus Client loaded -- Press F to toggle the menu (debug mode)")

-- Debug toggle menu (no `processed` check, uses F key for reliability)
Config.ToggleKey = Enum.KeyCode.F -- Change hotkey for testing!

UserInputService.InputBegan:Connect(function(inp, processed)
    print("Input detected: ", inp.UserInputType, inp.KeyCode, "Processed:", processed)
    if inp.KeyCode == Config.ToggleKey then
        print("Toggle key pressed! (", tostring(Config.ToggleKey), ")")
        if win.Visible then
            tween(win, { Position = UDim2.new(0.5, -290, 0.6, -210), BackgroundTransparency = 1 }, 0.22)
            task.delay(0.22, function() win.Visible = false end)
        else
            win.Visible                = true
            win.BackgroundTransparency = 1
            win.Position               = UDim2.new(0.5, -290, 0.4, -210)
            tween(win, {
                BackgroundTransparency = 1 - State.MenuOpacity,
                Position               = UDim2.new(0.5, -290, 0.5, -210),
            }, 0.22)
        end
    end
end)

-- Always start visible for debug (so you know UI works):
win.Visible = true
win.BackgroundTransparency = 1 - State.MenuOpacity
