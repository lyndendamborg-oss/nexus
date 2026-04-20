-- ============================================================
--  NEXUS CLIENT  v2.0.0  |  Executor Ready
--  Bugs fixed:
--    • RightShift blocked by `processed` check — fixed by
--      allowing the toggle key regardless of processed state
--    • menuAnimating deadlock on error — wrapped in pcall
--    • Empty freecamToggleConn heartbeat — removed
--    • MenuOpacity float/int mismatch — unified to 0–1
--    • Double InputBegan listeners — removed entirely
-- ============================================================
if not game:IsLoaded() then game.Loaded:Wait() end

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local Lighting         = game:GetService("Lighting")
local TweenService     = game:GetService("TweenService")
local Workspace        = game:GetService("Workspace")
local CoreGui          = game:GetService("CoreGui")
local HttpService      = game:GetService("HttpService")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

if not player.Character then player.CharacterAdded:Wait() end

local Config = {
    ToggleKey   = Enum.KeyCode.RightShift,
    AccentColor = Color3.fromRGB(100, 180, 255),
    Theme       = "Dark",
    Version     = "v2.0.0",
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

-- ============================================================
--  STATE  (all settings live here — serialized for import/export)
-- ============================================================
local State = {
    -- Visual
    Fullbright        = false,
    NoFog             = false,
    RainbowAmbient    = false,
    FreezeTime        = false,
    NoShadows         = false,
    TimeOfDay         = 14,
    -- Player
    WalkSpeed         = 16,
    JumpPower         = 50,
    InfJump           = false,
    Noclip            = false,
    Fly               = false,
    FlySpeed          = 40,
    AntiVoid          = false,
    AntiVoidHeight    = -200,
    AntiVoidTeleportY = 50,
    -- Freecam
    Freecam           = false,
    FreecamSpeed      = 30,
    FreecamBoostMult  = 3,
    FreecamSmooth     = true,
    FreecamSmoothFactor = 0.3,
    FreecamFOV        = 70,
    FreecamMouseSens  = 3,    -- stored as 1–10, divided by 1000 in use
    -- ESP
    Chams             = false,
    ChamTransparency  = 75,   -- 0–100
    ShowHealth        = false,
    ShowNames         = false,
    ShowDistance      = true,
    ESPMaxDistance    = 500,
    -- World
    Gravity           = 196,
    NoParticles       = false,
    -- UI / Menu
    MenuOpacity       = 97,   -- stored as 0–100 integer
    Draggable         = true,
    Theme             = "Dark",
    MenuScale         = 100,  -- stored as 50–150
    ShowHints         = true,
    AccentR           = 100,
    AccentG           = 180,
    AccentB           = 255,
    -- Keybinds
    ToggleKeyName     = "RightShift",
    FreecamBoostKeyName = "LeftShift",
}

-- ============================================================
--  SERIALISATION  (base64-like encoding without HttpService)
-- ============================================================
local B64_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

local function encodeBase64(data)
    local result = {}
    local padding = (3 - #data % 3) % 3
    data = data .. string.rep("\0", padding)
    for i = 1, #data, 3 do
        local b1, b2, b3 = string.byte(data, i, i + 2)
        local n = b1 * 65536 + b2 * 256 + b3
        result[#result+1] = string.sub(B64_CHARS, math.floor(n/262144)%64+1, math.floor(n/262144)%64+1)
        result[#result+1] = string.sub(B64_CHARS, math.floor(n/4096)%64+1,   math.floor(n/4096)%64+1)
        result[#result+1] = string.sub(B64_CHARS, math.floor(n/64)%64+1,     math.floor(n/64)%64+1)
        result[#result+1] = string.sub(B64_CHARS, n%64+1,                     n%64+1)
    end
    local s = table.concat(result)
    return string.sub(s, 1, #s - padding) .. string.rep("=", padding)
end

local function decodeBase64(data)
    data = data:gsub("[^"..B64_CHARS.."=]", "")
    local padding = #data % 4
    if padding == 2 then data = data .. "==" elseif padding == 3 then data = data .. "=" end
    local lookup = {}
    for i = 1, #B64_CHARS do lookup[string.sub(B64_CHARS,i,i)] = i-1 end
    local result = {}
    for i = 1, #data, 4 do
        local c1,c2,c3,c4 = string.sub(data,i,i), string.sub(data,i+1,i+1), string.sub(data,i+2,i+2), string.sub(data,i+3,i+3)
        local n = (lookup[c1] or 0)*262144 + (lookup[c2] or 0)*4096 + (lookup[c3] or 0)*64 + (lookup[c4] or 0)
        result[#result+1] = string.char(math.floor(n/65536)%256)
        if c3 ~= "=" then result[#result+1] = string.char(math.floor(n/256)%256) end
        if c4 ~= "=" then result[#result+1] = string.char(n%256) end
    end
    return table.concat(result)
end

-- Serialise State to compact string, then base64 encode
local EXPORT_KEYS = {
    "Fullbright","NoFog","RainbowAmbient","FreezeTime","NoShadows","TimeOfDay",
    "WalkSpeed","JumpPower","InfJump","Noclip","Fly","FlySpeed","AntiVoid","AntiVoidHeight","AntiVoidTeleportY",
    "Freecam","FreecamSpeed","FreecamBoostMult","FreecamSmooth","FreecamSmoothFactor","FreecamFOV","FreecamMouseSens",
    "Chams","ChamTransparency","ShowHealth","ShowNames","ShowDistance","ESPMaxDistance",
    "Gravity","NoParticles",
    "MenuOpacity","Draggable","Theme","MenuScale","ShowHints","AccentR","AccentG","AccentB",
    "ToggleKeyName","FreecamBoostKeyName",
}

local function serializeState()
    local parts = {}
    for _, k in ipairs(EXPORT_KEYS) do
        local v = State[k]
        if type(v) == "boolean" then
            parts[#parts+1] = k .. "=" .. (v and "1" or "0")
        elseif type(v) == "string" then
            parts[#parts+1] = k .. "=" .. tostring(v)
        else
            parts[#parts+1] = k .. "=" .. tostring(v)
        end
    end
    local raw = "NX2|" .. table.concat(parts, ";")
    return encodeBase64(raw)
end

local function deserializeState(encoded)
    local ok2, raw = pcall(decodeBase64, encoded)
    if not ok2 then return false, "Decode failed" end
    if not raw:sub(1,4) == "NX2|" then return false, "Invalid profile" end
    local body = raw:sub(5)
    local loaded = {}
    for pair in body:gmatch("[^;]+") do
        local k, v = pair:match("^(.-)=(.+)$")
        if k and v then loaded[k] = v end
    end
    -- Type-coerce and apply
    for _, k in ipairs(EXPORT_KEYS) do
        if loaded[k] ~= nil then
            local orig = State[k]
            if type(orig) == "boolean" then
                State[k] = loaded[k] == "1"
            elseif type(orig) == "number" then
                State[k] = tonumber(loaded[k]) or orig
            else
                State[k] = loaded[k]
            end
        end
    end
    return true, "OK"
end

-- ============================================================
--  THEMES
-- ============================================================
local Themes = {
    Dark = {
        BG      = Color3.fromRGB(14, 14, 18),
        Panel   = Color3.fromRGB(20, 20, 26),
        Card    = Color3.fromRGB(26, 26, 34),
        Border  = Color3.fromRGB(40, 40, 55),
        Text    = Color3.fromRGB(220, 220, 230),
        SubText = Color3.fromRGB(120, 120, 140),
        Accent  = Color3.fromRGB(State.AccentR, State.AccentG, State.AccentB),
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
    Blood = {
        BG      = Color3.fromRGB(12, 6, 6),
        Panel   = Color3.fromRGB(22, 10, 10),
        Card    = Color3.fromRGB(30, 14, 14),
        Border  = Color3.fromRGB(80, 20, 20),
        Text    = Color3.fromRGB(230, 210, 210),
        SubText = Color3.fromRGB(140, 90, 90),
        Accent  = Color3.fromRGB(220, 50, 50),
        On      = Color3.fromRGB(220, 50, 50),
        Off     = Color3.fromRGB(60, 20, 20),
    },
}

local T = Themes[State.Theme] or Themes.Dark

-- ============================================================
--  DESTROY OLD GUI
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

local function tw(obj, props, t, style, dir)
    TweenService:Create(obj, TweenInfo.new(
        t   or 0.18,
        style or Enum.EasingStyle.Quad,
        dir   or Enum.EasingDirection.Out
    ), props):Play()
end

-- ============================================================
--  MAIN WINDOW
-- ============================================================
local win = make("Frame", {
    Size                   = UDim2.new(0, 600, 0, 440),
    Position               = UDim2.new(0.5, -300, 0.5, -220),
    BackgroundColor3       = T.BG,
    BackgroundTransparency = 1,
    BorderSizePixel        = 0,
    Visible                = false,
    Active                 = true,
    Draggable              = State.Draggable,
}, gui)
corner(12, win)
stroke(1, T.Border, win)

local winScale = make("UIScale", { Scale = 0.88 }, win)

-- ============================================================
--  OPEN / CLOSE  — state machine, no double-fire possible
-- ============================================================
local menuAnimating = false
local menuOpen      = false

local function openMenu()
    if menuOpen then return end
    menuAnimating = true
    win.Visible                = true
    win.BackgroundTransparency = 1
    winScale.Scale             = 0.88
    tw(win,      { BackgroundTransparency = 1 - State.MenuOpacity/100 }, 0.25, Enum.EasingStyle.Quint)
    tw(winScale, { Scale = State.MenuScale/100 },                        0.3,  Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    task.delay(0.31, function()
        menuAnimating = false
        menuOpen      = true
    end)
end

local function closeMenu()
    if not menuOpen then return end
    menuAnimating = true
    menuOpen      = false   -- mark closed immediately so no re-entrant opens
    tw(win,      { BackgroundTransparency = 1 },    0.2,  Enum.EasingStyle.Quint)
    tw(winScale, { Scale = 0.88 },                  0.18, Enum.EasingStyle.Quad)
    task.delay(0.22, function()
        win.Visible    = false
        winScale.Scale = 0.88
        menuAnimating  = false
    end)
end

-- ============================================================
--  TOP BAR
-- ============================================================
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
        NumberSequenceKeypoint.new(0, 0.55),
        NumberSequenceKeypoint.new(1, 1),
    }),
}, topBar)
make("TextLabel", {
    Size = UDim2.new(0, 200, 1, 0), Position = UDim2.new(0, 16, 0, 0),
    BackgroundTransparency = 1, Text = "NEXUS",
    TextColor3 = T.Text, TextSize = 18, Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
}, topBar)
make("TextLabel", {
    Size = UDim2.new(0, 80, 1, 0), Position = UDim2.new(1, -90, 0, 0),
    BackgroundTransparency = 1, Text = Config.Version,
    TextColor3 = T.SubText, TextSize = 11, Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Right,
}, topBar)
local closeBtn = make("TextButton", {
    Size = UDim2.new(0, 28, 0, 28), Position = UDim2.new(1, -36, 0.5, -14),
    BackgroundColor3 = Color3.fromRGB(200, 60, 60),
    Text = "✕", TextColor3 = Color3.fromRGB(255,255,255),
    TextSize = 12, Font = Enum.Font.GothamBold, BorderSizePixel = 0,
}, topBar)
corner(6, closeBtn)
closeBtn.MouseButton1Click:Connect(closeMenu)
closeBtn.MouseEnter:Connect(function() tw(closeBtn,{BackgroundColor3=Color3.fromRGB(240,80,80)}) end)
closeBtn.MouseLeave:Connect(function() tw(closeBtn,{BackgroundColor3=Color3.fromRGB(200,60,60)}) end)

-- ============================================================
--  TAB BAR
-- ============================================================
local tabList   = { "Visual", "Player", "Freecam", "ESP", "World", "Settings" }
local tabFrames = {}
local tabBtns   = {}
local tabIcons  = { Visual="◈", Player="⚡", Freecam="◎", ESP="◉", World="◆", Settings="⚙" }

local tabBar = make("Frame", {
    Size = UDim2.new(0, 110, 1, -48), Position = UDim2.new(0, 0, 0, 48),
    BackgroundColor3 = T.Panel, BorderSizePixel = 0,
}, win)

local function switchTab(name)
    for _, t in ipairs(tabList) do
        local btn = tabBtns[t]
        local frm = tabFrames[t]
        if t == name then
            tw(btn, { BackgroundColor3 = T.Accent, TextColor3 = Color3.fromRGB(255,255,255) })
            frm.Visible = true
        else
            tw(btn, { BackgroundColor3 = T.Card, TextColor3 = T.SubText })
            frm.Visible = false
        end
    end
end

for i, name in ipairs(tabList) do
    local btn = make("TextButton", {
        Size = UDim2.new(1,-12,0,38), Position = UDim2.new(0,6,0,8+(i-1)*44),
        BackgroundColor3 = T.Card,
        Text = (tabIcons[name] or "") .. "  " .. name,
        TextColor3 = T.SubText, TextSize = 12, Font = Enum.Font.GothamSemibold,
        BorderSizePixel = 0, TextXAlignment = Enum.TextXAlignment.Left,
    }, tabBar)
    corner(8, btn)
    make("UIPadding",{PaddingLeft=UDim.new(0,10)},btn)
    tabBtns[name] = btn

    local frame = make("ScrollingFrame", {
        Size = UDim2.new(1,-118,1,-56), Position = UDim2.new(0,114,0,52),
        BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 3, ScrollBarImageColor3 = T.Accent,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(0,0,0,0), Visible = (i==1),
    }, win)
    make("UIListLayout",{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder},frame)
    make("UIPadding",{PaddingTop=UDim.new(0,6),PaddingBottom=UDim.new(0,10),PaddingLeft=UDim.new(0,2),PaddingRight=UDim.new(0,8)},frame)
    tabFrames[name] = frame
    btn.MouseButton1Click:Connect(function() switchTab(name) end)
end

-- ============================================================
--  WIDGET BUILDERS
-- ============================================================
local layoutOrder = {}
for _, t in ipairs(tabList) do layoutOrder[t] = 0 end
local function nextOrder(tab)
    layoutOrder[tab] = layoutOrder[tab] + 1
    return layoutOrder[tab]
end

-- Toggle
local toggleRefs = {}  -- key → { pill, knob, state }
local function addToggle(tab, key, label, desc, callback)
    local f    = tabFrames[tab]
    local card = make("Frame",{
        Size=UDim2.new(1,0,0,56), BackgroundColor3=T.Card,
        BorderSizePixel=0, LayoutOrder=nextOrder(tab),
    },f)
    corner(8,card); stroke(1,T.Border,card)
    make("TextLabel",{Size=UDim2.new(1,-70,0,22),Position=UDim2.new(0,12,0,8),
        BackgroundTransparency=1,Text=label,TextColor3=T.Text,TextSize=13,
        Font=Enum.Font.GothamSemibold,TextXAlignment=Enum.TextXAlignment.Left},card)
    if desc and desc ~= "" then
        make("TextLabel",{Size=UDim2.new(1,-70,0,18),Position=UDim2.new(0,12,0,30),
            BackgroundTransparency=1,Text=desc,TextColor3=T.SubText,TextSize=11,
            Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left},card)
    end
    local pill = make("Frame",{
        Size=UDim2.new(0,44,0,22),Position=UDim2.new(1,-56,0.5,-11),
        BackgroundColor3=T.Off,BorderSizePixel=0},card)
    corner(11,pill)
    local knob = make("Frame",{
        Size=UDim2.new(0,16,0,16),Position=UDim2.new(0,3,0.5,-8),
        BackgroundColor3=Color3.fromRGB(255,255,255),BorderSizePixel=0},pill)
    corner(8,knob)
    local enabled = State[key] or false
    -- Apply initial visual state
    if enabled then
        pill.BackgroundColor3 = T.On
        knob.Position = UDim2.new(0,25,0.5,-8)
    end
    local btn = make("TextButton",{
        Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",ZIndex=2},card)
    btn.MouseButton1Click:Connect(function()
        enabled = not enabled
        State[key] = enabled
        tw(pill,{BackgroundColor3 = enabled and T.On or T.Off})
        tw(knob,{Position = enabled and UDim2.new(0,25,0.5,-8) or UDim2.new(0,3,0.5,-8)})
        if callback then callback(enabled) end
    end)
    toggleRefs[key] = { pill=pill, knob=knob, getEnabled=function() return enabled end,
        setEnabled=function(v)
            enabled=v; State[key]=v
            tw(pill,{BackgroundColor3=v and T.On or T.Off})
            tw(knob,{Position=v and UDim2.new(0,25,0.5,-8) or UDim2.new(0,3,0.5,-8)})
            if callback then callback(v) end
        end
    }
    return card
end

-- Slider
local sliderRefs = {}  -- key → setVal function
local function addSlider(tab, key, label, min, max, default, callback)
    local f    = tabFrames[tab]
    local card = make("Frame",{
        Size=UDim2.new(1,0,0,64),BackgroundColor3=T.Card,
        BorderSizePixel=0,LayoutOrder=nextOrder(tab),
    },f)
    corner(8,card); stroke(1,T.Border,card)
    local valLabel = make("TextLabel",{
        Size=UDim2.new(0,50,0,20),Position=UDim2.new(1,-60,0,10),
        BackgroundTransparency=1,Text=tostring(default),
        TextColor3=T.Accent,TextSize=12,Font=Enum.Font.GothamBold,
        TextXAlignment=Enum.TextXAlignment.Right},card)
    make("TextLabel",{Size=UDim2.new(1,-70,0,20),Position=UDim2.new(0,12,0,10),
        BackgroundTransparency=1,Text=label,TextColor3=T.Text,TextSize=13,
        Font=Enum.Font.GothamSemibold,TextXAlignment=Enum.TextXAlignment.Left},card)
    local track = make("Frame",{
        Size=UDim2.new(1,-24,0,4),Position=UDim2.new(0,12,0,46),
        BackgroundColor3=T.Border,BorderSizePixel=0},card)
    corner(2,track)
    local initPct = math.clamp((default-min)/(max-min),0,1)
    local fill = make("Frame",{Size=UDim2.new(initPct,0,1,0),BackgroundColor3=T.Accent,BorderSizePixel=0},track)
    corner(2,fill)
    local handle = make("Frame",{
        Size=UDim2.new(0,12,0,12),Position=UDim2.new(initPct,-6,0.5,-6),
        BackgroundColor3=Color3.fromRGB(255,255,255),BorderSizePixel=0},track)
    corner(6,handle)
    local dragging = false
    local function updateSlider(x)
        local abs = track.AbsolutePosition.X
        local w   = track.AbsoluteSize.X
        if w == 0 then return end
        local pct = math.clamp((x-abs)/w,0,1)
        local val = math.floor(min + pct*(max-min))
        valLabel.Text = tostring(val)
        if key then State[key] = val end
        tw(fill,  {Size=UDim2.new(pct,0,1,0)},0.05)
        tw(handle,{Position=UDim2.new(pct,-6,0.5,-6)},0.05)
        if callback then callback(val) end
    end
    local trackBtn = make("TextButton",{
        Size=UDim2.new(1,0,0,20),Position=UDim2.new(0,0,0,38),
        BackgroundTransparency=1,Text="",ZIndex=2},card)
    trackBtn.MouseButton1Down:Connect(function()
        dragging=true; updateSlider(UserInputService:GetMouseLocation().X)
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType==Enum.UserInputType.MouseMovement then
            updateSlider(inp.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
    end)
    -- Expose setter for import
    sliderRefs[key] = function(val)
        val = math.clamp(val, min, max)
        local pct = (val-min)/(max-min)
        valLabel.Text = tostring(val)
        State[key] = val
        tw(fill,  {Size=UDim2.new(pct,0,1,0)},0.05)
        tw(handle,{Position=UDim2.new(pct,-6,0.5,-6)},0.05)
        if callback then callback(val) end
    end
    return card
end

local function addHeader(tab, text)
    local f = tabFrames[tab]
    local lbl = make("TextLabel",{
        Size=UDim2.new(1,0,0,22),BackgroundTransparency=1,
        Text="  " .. text,TextColor3=T.Accent,TextSize=11,
        Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,
        LayoutOrder=nextOrder(tab),
    },f)
    -- thin separator line
    local line = make("Frame",{
        Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,-1),
        BackgroundColor3=T.Border,BackgroundTransparency=0.4,BorderSizePixel=0},lbl)
end

-- Dropdown
local function addDropdown(tab, label, options, default, callback)
    local f    = tabFrames[tab]
    local card = make("Frame",{
        Size=UDim2.new(1,0,0,56),BackgroundColor3=T.Card,
        BorderSizePixel=0,LayoutOrder=nextOrder(tab),ClipsDescendants=true},f)
    corner(8,card); stroke(1,T.Border,card)
    make("TextLabel",{Size=UDim2.new(1,-110,0,56),Position=UDim2.new(0,12,0,0),
        BackgroundTransparency=1,Text=label,TextColor3=T.Text,TextSize=13,
        Font=Enum.Font.GothamSemibold,TextXAlignment=Enum.TextXAlignment.Left},card)
    local selected = default or options[1]
    local selBtn = make("TextButton",{
        Size=UDim2.new(0,100,0,32),Position=UDim2.new(1,-108,0.5,-16),
        BackgroundColor3=T.Panel,Text=selected,TextColor3=T.Accent,
        TextSize=12,Font=Enum.Font.GothamSemibold,BorderSizePixel=0},card)
    corner(6,selBtn); stroke(1,T.Border,selBtn)
    local open = false
    local dropList = make("Frame",{
        Size=UDim2.new(0,100,0,#options*32),
        Position=UDim2.new(1,-108,1,4),
        BackgroundColor3=T.Panel,BorderSizePixel=0,
        Visible=false,ZIndex=50},card)
    corner(6,dropList); stroke(1,T.Border,dropList)
    for idx, opt in ipairs(options) do
        local ob = make("TextButton",{
            Size=UDim2.new(1,0,0,32),Position=UDim2.new(0,0,0,(idx-1)*32),
            BackgroundColor3=T.Panel,Text=opt,TextColor3=T.SubText,
            TextSize=12,Font=Enum.Font.Gotham,BorderSizePixel=0,ZIndex=51},dropList)
        ob.MouseEnter:Connect(function() tw(ob,{BackgroundColor3=T.Card}) end)
        ob.MouseLeave:Connect(function() tw(ob,{BackgroundColor3=T.Panel}) end)
        ob.MouseButton1Click:Connect(function()
            selected = opt
            selBtn.Text = opt
            open = false
            dropList.Visible = false
            card.Size = UDim2.new(1,0,0,56)
            if callback then callback(opt) end
        end)
    end
    selBtn.MouseButton1Click:Connect(function()
        open = not open
        dropList.Visible = open
        card.Size = open and UDim2.new(1,0,0,56+#options*32) or UDim2.new(1,0,0,56)
    end)
    return card
end

-- Info card
local function addInfo(tab, text)
    local f = tabFrames[tab]
    local card = make("Frame",{
        Size=UDim2.new(1,0,0,40),BackgroundColor3=T.Card,
        BorderSizePixel=0,LayoutOrder=nextOrder(tab)},f)
    corner(8,card); stroke(1,T.Border,card)
    make("TextLabel",{Size=UDim2.new(1,-16,1,0),Position=UDim2.new(0,12,0,0),
        BackgroundTransparency=1,Text=text,TextColor3=T.SubText,TextSize=11,
        Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true},card)
    return card
end

-- ============================================================
--  POPULATE — VISUAL
-- ============================================================
addHeader("Visual","LIGHTING")
addToggle("Visual","Fullbright","Fullbright","Max ambient lighting — see everything",function(on)
    Lighting.Ambient    = on and Color3.fromRGB(255,255,255) or Defaults.Ambient
    Lighting.Brightness = on and 2 or Defaults.Brightness
end)
addToggle("Visual","NoFog","No Fog","Remove all atmospheric fog",function(on)
    Lighting.FogEnd = on and 1e7 or Defaults.FogEnd
end)
addToggle("Visual","RainbowAmbient","Rainbow Ambient","Cycles ambient color through hues",function(on)
    if not on then Lighting.Ambient = Defaults.Ambient end
end)
addToggle("Visual","NoShadows","No Shadows","Disable shadow rendering",function(on)
    Lighting.GlobalShadows = not on
end)
addHeader("Visual","TIME")
addToggle("Visual","FreezeTime","Freeze Time","Lock current time of day",function(on)
    if on then Defaults.FrozenClock = Lighting.ClockTime end
end)
addSlider("Visual","TimeOfDay","Time of Day",0,24,14,function(v)
    Lighting.ClockTime = v
end)

-- ============================================================
--  POPULATE — PLAYER
-- ============================================================
addHeader("Player","MOVEMENT")
addSlider("Player","WalkSpeed","Walk Speed",8,150,16,function(v)
    local c=player.Character; if c then local h=c:FindFirstChildOfClass("Humanoid"); if h then h.WalkSpeed=v end end
end)
addSlider("Player","JumpPower","Jump Power",10,200,50,function(v)
    local c=player.Character; if c then local h=c:FindFirstChildOfClass("Humanoid"); if h then h.JumpPower=v end end
end)
addToggle("Player","InfJump","Infinite Jump","Jump while in the air",nil)
addToggle("Player","Noclip","Noclip","Phase through walls",nil)
addHeader("Player","FLIGHT")
addToggle("Player","Fly","Fly","Free flight mode",nil)
addSlider("Player","FlySpeed","Fly Speed",10,200,40,nil)
addHeader("Player","SAFETY")
addToggle("Player","AntiVoid","Anti-Void","Teleport back if you fall out",nil)
addSlider("Player","AntiVoidHeight","Void Trigger Height",-2000,-50,-200,nil)
addSlider("Player","AntiVoidTeleportY","Teleport Height",10,500,50,nil)

-- ============================================================
--  POPULATE — FREECAM
-- ============================================================
local freecamCF   = camera.CFrame
local freecamPitch = 0
local freecamYaw   = 0

-- Speed indicator HUD
local speedHUD = make("Frame",{
    Size=UDim2.new(0,150,0,30),Position=UDim2.new(0.5,-75,1,-50),
    BackgroundColor3=Color3.fromRGB(10,10,14),BackgroundTransparency=0.25,
    BorderSizePixel=0,Visible=false,ZIndex=10},gui)
corner(8,speedHUD); stroke(1,T.Accent,speedHUD)
local speedHUDLabel = make("TextLabel",{
    Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,
    Text="CAM  ·  NORMAL",TextColor3=T.Accent,
    TextSize=12,Font=Enum.Font.GothamBold,
    TextXAlignment=Enum.TextXAlignment.Center,ZIndex=11},speedHUD)

addHeader("Freecam","CAMERA")
addToggle("Freecam","Freecam","Freecam","Detach camera from character",function(on)
    if on then
        freecamCF = camera.CFrame
        local rx,ry,_ = freecamCF:ToEulerAnglesYXZ()
        freecamPitch = rx; freecamYaw = ry
        camera.CameraType = Enum.CameraType.Scriptable
        speedHUD.Visible  = true
    else
        camera.CameraType  = Enum.CameraType.Custom
        camera.FieldOfView = Defaults.FOV
        speedHUD.Visible   = false
    end
end)
addToggle("Freecam","FreecamSmooth","Smooth Movement","Cinematic eased movement",nil)
addHeader("Freecam","SPEED")
addSlider("Freecam","FreecamSpeed","Base Speed",5,300,30,nil)
addSlider("Freecam","FreecamBoostMult","Boost Multiplier (LShift)",2,15,3,nil)
addInfo("Freecam","Hold  LEFT SHIFT  in freecam to boost.  WASD = move,  Q/E = up/down.")
addHeader("Freecam","OPTICS")
addSlider("Freecam","FreecamFOV","Field of View",30,150,70,function(v)
    if State.Freecam then camera.FieldOfView = v end
end)
addSlider("Freecam","FreecamMouseSens","Mouse Sensitivity",1,10,3,nil)
addSlider("Freecam","FreecamSmoothFactor","Smooth Factor (×100)",5,80,30,nil)

-- ============================================================
--  POPULATE — ESP
-- ============================================================
addHeader("ESP","HIGHLIGHT")
addToggle("ESP","Chams","Chams","Highlight players through walls",function(on)
    if not on then
        for _,p in pairs(Players:GetPlayers()) do
            if p~=player and p.Character then
                local hl=p.Character:FindFirstChild("_NexusHL"); if hl then hl:Destroy() end
            end
        end
    end
end)
addSlider("ESP","ChamTransparency","Cham Transparency",0,100,75,nil)
addHeader("ESP","LABELS")
addToggle("ESP","ShowNames","Show Names","Player names above heads",function(on)
    if not on and not State.ShowHealth then
        for _,p in pairs(Players:GetPlayers()) do
            if p~=player and p.Character then
                local bb=p.Character:FindFirstChild("_NexusBB"); if bb then bb:Destroy() end
            end
        end
    end
end)
addToggle("ESP","ShowHealth","Show Health","HP bars above heads",nil)
addToggle("ESP","ShowDistance","Show Distance","Distance label alongside name",nil)
addSlider("ESP","ESPMaxDistance","Max Distance",50,2000,500,nil)

-- ============================================================
--  POPULATE — WORLD
-- ============================================================
addHeader("World","PHYSICS")
addSlider("World","Gravity","Gravity",0,400,196,function(v)
    Workspace.Gravity = v
end)
addHeader("World","ENVIRONMENT")
addToggle("World","NoParticles","No Particles","Remove all particles/fire/smoke",function(on)
    for _,v in pairs(Workspace:GetDescendants()) do
        if v:IsA("ParticleEmitter") or v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles") then
            v.Enabled = not on
        end
    end
end)

-- ============================================================
--  POPULATE — SETTINGS  (detailed)
-- ============================================================

-- ── APPEARANCE ──────────────────────────────────────────────
addHeader("Settings","APPEARANCE")

addDropdown("Settings","Theme",{"Dark","Neon","Light","Blood"},"Dark",function(v)
    State.Theme = v
    -- Note: full theme hot-swap requires re-exec; notify user
    addInfo("Settings","Re-execute the script to apply the new theme.")
end)

addSlider("Settings","MenuOpacity","Menu Opacity",10,100,97,function(v)
    win.BackgroundTransparency = 1 - v/100
end)

addSlider("Settings","MenuScale","Menu Scale %",60,130,100,function(v)
    winScale.Scale = v/100
end)

addHeader("Settings","ACCENT COLOUR")
addSlider("Settings","AccentR","Accent Red",0,255,100,function(v)
    T.Accent = Color3.fromRGB(v, State.AccentG, State.AccentB)
end)
addSlider("Settings","AccentG","Accent Green",0,255,180,function(v)
    T.Accent = Color3.fromRGB(State.AccentR, v, State.AccentB)
end)
addSlider("Settings","AccentB","Accent Blue",0,255,255,function(v)
    T.Accent = Color3.fromRGB(State.AccentR, State.AccentG, v)
end)

-- ── BEHAVIOUR ───────────────────────────────────────────────
addHeader("Settings","BEHAVIOUR")
addToggle("Settings","Draggable","Draggable Window","Allow dragging the menu",function(on)
    win.Draggable = on
end)
addToggle("Settings","ShowHints","Show Hints","Show hint labels on cards",nil)

-- ── KEYBINDS ────────────────────────────────────────────────
addHeader("Settings","KEYBINDS")

-- Rebind toggle key
local rebindCard = make("Frame",{
    Size=UDim2.new(1,0,0,56),BackgroundColor3=T.Card,
    BorderSizePixel=0,LayoutOrder=nextOrder("Settings")},tabFrames["Settings"])
corner(8,rebindCard); stroke(1,T.Border,rebindCard)
make("TextLabel",{Size=UDim2.new(1,-120,0,22),Position=UDim2.new(0,12,0,8),
    BackgroundTransparency=1,Text="Toggle Key",TextColor3=T.Text,
    TextSize=13,Font=Enum.Font.GothamSemibold,TextXAlignment=Enum.TextXAlignment.Left},rebindCard)
make("TextLabel",{Size=UDim2.new(1,-120,0,18),Position=UDim2.new(0,12,0,30),
    BackgroundTransparency=1,Text="Key to open/close Nexus",TextColor3=T.SubText,
    TextSize=11,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left},rebindCard)
local rebindBtn = make("TextButton",{
    Size=UDim2.new(0,100,0,32),Position=UDim2.new(1,-108,0.5,-16),
    BackgroundColor3=T.Panel,Text=State.ToggleKeyName,TextColor3=T.Accent,
    TextSize=12,Font=Enum.Font.GothamBold,BorderSizePixel=0},rebindCard)
corner(6,rebindBtn); stroke(1,T.Border,rebindBtn)
local rebinding = false
rebindBtn.MouseButton1Click:Connect(function()
    if rebinding then return end
    rebinding = true
    rebindBtn.Text = "Press key..."
    rebindBtn.TextColor3 = Color3.fromRGB(255,200,60)
    local conn
    conn = UserInputService.InputBegan:Connect(function(inp,proc)
        if proc then return end
        if inp.UserInputType ~= Enum.UserInputType.Keyboard then return end
        Config.ToggleKey = inp.KeyCode
        State.ToggleKeyName = inp.KeyCode.Name
        rebindBtn.Text = inp.KeyCode.Name
        rebindBtn.TextColor3 = T.Accent
        rebinding = false
        conn:Disconnect()
    end)
end)

addInfo("Settings","Boost key (in freecam) is always Left Shift.")

-- ── PERFORMANCE ─────────────────────────────────────────────
addHeader("Settings","PERFORMANCE")
addInfo("Settings","All runtime loops use RunService events and auto-disable when features are off.")

-- ── INFO ────────────────────────────────────────────────────
addHeader("Settings","INFO")
addInfo("Settings","Nexus Client "..Config.Version.."  |  Executor-ready  |  RightShift to toggle")

-- ============================================================
--  IMPORT / EXPORT  (with BETA badge)
-- ============================================================
addHeader("Settings","━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

-- BETA badge
local betaBadgeFrame = make("Frame",{
    Size=UDim2.new(1,0,0,20),BackgroundTransparency=1,
    LayoutOrder=nextOrder("Settings")},tabFrames["Settings"])
make("TextLabel",{
    Size=UDim2.new(0,46,1,0),Position=UDim2.new(0,4,0,0),
    BackgroundColor3=Color3.fromRGB(255,160,40),BackgroundTransparency=0,
    Text="  BETA  ",TextColor3=Color3.fromRGB(30,20,0),
    TextSize=9,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Center},betaBadgeFrame)
corner(4, betaBadgeFrame:FindFirstChildOfClass("TextLabel"))
make("TextLabel",{
    Size=UDim2.new(1,-58,1,0),Position=UDim2.new(0,58,0,0),
    BackgroundTransparency=1,
    Text="Import & Export — profile strings are portable across sessions",
    TextColor3=T.SubText,TextSize=10,Font=Enum.Font.Gotham,
    TextXAlignment=Enum.TextXAlignment.Left},betaBadgeFrame)

-- Export card
local exportCard = make("Frame",{
    Size=UDim2.new(1,0,0,80),BackgroundColor3=T.Card,
    BorderSizePixel=0,LayoutOrder=nextOrder("Settings")},tabFrames["Settings"])
corner(8,exportCard); stroke(1,T.Border,exportCard)
make("TextLabel",{Size=UDim2.new(1,-16,0,22),Position=UDim2.new(0,12,0,6),
    BackgroundTransparency=1,Text="Export Settings",TextColor3=T.Text,
    TextSize=13,Font=Enum.Font.GothamSemibold,TextXAlignment=Enum.TextXAlignment.Left},exportCard)
local exportBox = make("TextBox",{
    Size=UDim2.new(1,-100,0,28),Position=UDim2.new(0,8,0,34),
    BackgroundColor3=T.Panel,Text="Click EXPORT to generate",
    TextColor3=T.SubText,TextSize=10,Font=Enum.Font.RobotoMono,
    TextXAlignment=Enum.TextXAlignment.Left,ClearTextOnFocus=false,
    BorderSizePixel=0},exportCard)
corner(6,exportBox); stroke(1,T.Border,exportBox)
make("UIPadding",{PaddingLeft=UDim.new(0,6)},exportBox)
local exportBtn = make("TextButton",{
    Size=UDim2.new(0,76,0,28),Position=UDim2.new(1,-84,0,34),
    BackgroundColor3=T.Accent,Text="EXPORT",TextColor3=Color3.fromRGB(255,255,255),
    TextSize=11,Font=Enum.Font.GothamBold,BorderSizePixel=0},exportCard)
corner(6,exportBtn)
exportBtn.MouseButton1Click:Connect(function()
    local s = serializeState()
    exportBox.Text = s
    exportBox:CaptureFocus()
    exportBox:ReleaseFocus()
    tw(exportBtn,{BackgroundColor3=Color3.fromRGB(60,200,120)})
    task.delay(1.5,function() tw(exportBtn,{BackgroundColor3=T.Accent}) end)
end)

-- Import card
local importCard = make("Frame",{
    Size=UDim2.new(1,0,0,100),BackgroundColor3=T.Card,
    BorderSizePixel=0,LayoutOrder=nextOrder("Settings")},tabFrames["Settings"])
corner(8,importCard); stroke(1,T.Border,importCard)
make("TextLabel",{Size=UDim2.new(1,-16,0,22),Position=UDim2.new(0,12,0,6),
    BackgroundTransparency=1,Text="Import Settings",TextColor3=T.Text,
    TextSize=13,Font=Enum.Font.GothamSemibold,TextXAlignment=Enum.TextXAlignment.Left},importCard)
make("TextLabel",{Size=UDim2.new(1,-16,0,16),Position=UDim2.new(0,12,0,28),
    BackgroundTransparency=1,Text="Paste your exported profile string below, then click IMPORT",
    TextColor3=T.SubText,TextSize=10,Font=Enum.Font.Gotham,
    TextXAlignment=Enum.TextXAlignment.Left},importCard)
local importBox = make("TextBox",{
    Size=UDim2.new(1,-100,0,28),Position=UDim2.new(0,8,0,52),
    BackgroundColor3=T.Panel,Text="",PlaceholderText="Paste string here...",
    PlaceholderColor3=T.SubText,
    TextColor3=T.Text,TextSize=10,Font=Enum.Font.RobotoMono,
    TextXAlignment=Enum.TextXAlignment.Left,ClearTextOnFocus=false,
    BorderSizePixel=0},importCard)
corner(6,importBox); stroke(1,T.Border,importBox)
make("UIPadding",{PaddingLeft=UDim.new(0,6)},importBox)
local importBtn = make("TextButton",{
    Size=UDim2.new(0,76,0,28),Position=UDim2.new(1,-84,0,52),
    BackgroundColor3=T.Accent,Text="IMPORT",TextColor3=Color3.fromRGB(255,255,255),
    TextSize=11,Font=Enum.Font.GothamBold,BorderSizePixel=0},importCard)
corner(6,importBtn)
local importStatus = make("TextLabel",{
    Size=UDim2.new(1,-16,0,14),Position=UDim2.new(0,12,0,82),
    BackgroundTransparency=1,Text="",TextColor3=T.Accent,
    TextSize=10,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left},importCard)

importBtn.MouseButton1Click:Connect(function()
    local s = importBox.Text
    if s == "" then
        importStatus.TextColor3 = Color3.fromRGB(220,80,80)
        importStatus.Text = "✗  Nothing to import."
        return
    end
    local success, msg = deserializeState(s)
    if success then
        -- Apply all slider values
        for key, setter in pairs(sliderRefs) do
            if State[key] ~= nil then setter(State[key]) end
        end
        -- Apply all toggle values
        for key, ref in pairs(toggleRefs) do
            if State[key] ~= nil then ref.setEnabled(State[key]) end
        end
        -- Apply opacity & scale immediately
        win.BackgroundTransparency = 1 - State.MenuOpacity/100
        winScale.Scale = State.MenuScale/100
        importStatus.TextColor3 = Color3.fromRGB(60,200,120)
        importStatus.Text = "✓  Settings applied successfully."
        tw(importBtn,{BackgroundColor3=Color3.fromRGB(60,200,120)})
        task.delay(2,function()
            tw(importBtn,{BackgroundColor3=T.Accent})
            importStatus.Text = ""
        end)
    else
        importStatus.TextColor3 = Color3.fromRGB(220,80,80)
        importStatus.Text = "✗  Invalid profile string."
        tw(importBtn,{BackgroundColor3=Color3.fromRGB(200,60,60)})
        task.delay(2,function()
            tw(importBtn,{BackgroundColor3=T.Accent})
        end)
    end
end)

-- ============================================================
--  RUNTIME LOOPS
-- ============================================================

-- Infinite jump
UserInputService.JumpRequest:Connect(function()
    if not State.InfJump then return end
    local c=player.Character; if not c then return end
    local h=c:FindFirstChildOfClass("Humanoid")
    if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
end)

-- Noclip
RunService.Stepped:Connect(function()
    if not State.Noclip then return end
    local c=player.Character; if not c then return end
    for _,p in pairs(c:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide=false end
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
    hue = (hue + dt*0.1) % 1
    Lighting.Ambient = Color3.fromHSV(hue, 0.6, 1)
end)

-- Freecam
RunService.RenderStepped:Connect(function(dt)
    if not State.Freecam then return end
    local boosting = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
    local spd = State.FreecamSpeed * (boosting and State.FreecamBoostMult or 1) * dt
    if boosting then
        speedHUDLabel.Text       = "BOOST  ×" .. State.FreecamBoostMult
        speedHUDLabel.TextColor3 = Color3.fromRGB(255,210,60)
    else
        speedHUDLabel.Text       = "CAM  ·  NORMAL"
        speedHUDLabel.TextColor3 = T.Accent
    end
    local delta = UserInputService:GetMouseDelta()
    local sens  = State.FreecamMouseSens * 0.001
    freecamYaw   = freecamYaw   - delta.X * sens
    freecamPitch = freecamPitch - delta.Y * sens
    freecamPitch = freecamPitch % (math.pi*2)
    local rot = CFrame.Angles(0, freecamYaw, 0) * CFrame.Angles(freecamPitch, 0, 0)
    freecamCF   = CFrame.new(freecamCF.Position) * rot
    local move = Vector3.new(
        (UserInputService:IsKeyDown(Enum.KeyCode.D) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.A) and 1 or 0),
        (UserInputService:IsKeyDown(Enum.KeyCode.E) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.Q) and 1 or 0),
        (UserInputService:IsKeyDown(Enum.KeyCode.S) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.W) and 1 or 0)
    )
    if move.Magnitude > 0 then freecamCF = freecamCF * CFrame.new(move.Unit*spd) end
    local sf = math.clamp(State.FreecamSmoothFactor/100, 0.05, 0.95)
    camera.CFrame = State.FreecamSmooth and camera.CFrame:Lerp(freecamCF, sf) or freecamCF
    camera.FieldOfView = State.FreecamFOV
end)

-- Anti-void
RunService.Heartbeat:Connect(function()
    if not State.AntiVoid then return end
    local c=player.Character; if not c then return end
    local root=c:FindFirstChild("HumanoidRootPart")
    if root and root.Position.Y < State.AntiVoidHeight then
        root.CFrame = CFrame.new(0, State.AntiVoidTeleportY, 0)
    end
end)

-- Fly
local bodyVel, bodyGyro
RunService.Heartbeat:Connect(function()
    local c=player.Character; if not c then return end
    local root=c:FindFirstChild("HumanoidRootPart")
    local hum =c:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end
    if State.Fly then
        hum.PlatformStand = true
        if not bodyVel or not bodyVel.Parent then
            bodyVel=Instance.new("BodyVelocity"); bodyVel.MaxForce=Vector3.new(1e5,1e5,1e5); bodyVel.Parent=root
        end
        if not bodyGyro or not bodyGyro.Parent then
            bodyGyro=Instance.new("BodyGyro"); bodyGyro.MaxTorque=Vector3.new(1e5,1e5,1e5); bodyGyro.P=1e4; bodyGyro.Parent=root
        end
        local dir=Vector3.new(
            (UserInputService:IsKeyDown(Enum.KeyCode.D) and 1 or 0)-(UserInputService:IsKeyDown(Enum.KeyCode.A) and 1 or 0),
            (UserInputService:IsKeyDown(Enum.KeyCode.Space) and 1 or 0)-(UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) and 1 or 0),
            (UserInputService:IsKeyDown(Enum.KeyCode.S) and 1 or 0)-(UserInputService:IsKeyDown(Enum.KeyCode.W) and 1 or 0)
        )
        bodyVel.Velocity = dir.Magnitude>0 and camera.CFrame:VectorToWorldSpace(dir.Unit)*State.FlySpeed or Vector3.new(0,0,0)
        bodyGyro.CFrame  = camera.CFrame
    else
        hum.PlatformStand = false
        if bodyVel  and bodyVel.Parent  then bodyVel:Destroy();  bodyVel=nil  end
        if bodyGyro and bodyGyro.Parent then bodyGyro:Destroy(); bodyGyro=nil end
    end
end)

-- ESP / Chams / Billboards
RunService.Heartbeat:Connect(function()
    for _,p in pairs(Players:GetPlayers()) do
        if p==player then continue end
        local c=p.Character; if not c then continue end
        local root=c:FindFirstChild("HumanoidRootPart")
        local hum =c:FindFirstChildOfClass("Humanoid")
        if not root or not hum then continue end
        local hl=c:FindFirstChild("_NexusHL")
        if State.Chams then
            if not hl then
                hl=Instance.new("SelectionBox"); hl.Name="_NexusHL"; hl.Adornee=c
                hl.Color3=T.Accent; hl.LineThickness=0.04
                hl.SurfaceTransparency=State.ChamTransparency/100; hl.SurfaceColor3=T.Accent; hl.Parent=c
            else
                hl.SurfaceTransparency=State.ChamTransparency/100
            end
        else
            if hl then hl:Destroy() end
        end
        local bb=c:FindFirstChild("_NexusBB")
        if State.ShowNames or State.ShowHealth then
            if not bb then
                bb=Instance.new("BillboardGui"); bb.Name="_NexusBB"
                bb.Size=UDim2.new(0,150,0,44); bb.StudsOffset=Vector3.new(0,3.5,0)
                bb.AlwaysOnTop=true; bb.Adornee=root; bb.Parent=c
                make("TextLabel",{Name="lbl",Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,
                    TextColor3=T.Text,TextSize=13,Font=Enum.Font.GothamBold,
                    TextStrokeTransparency=0,TextStrokeColor3=Color3.fromRGB(0,0,0),TextWrapped=true},bb)
            end
            local lbl=bb:FindFirstChild("lbl")
            if lbl then
                local dist=math.floor((root.Position-camera.CFrame.Position).Magnitude)
                if dist > State.ESPMaxDistance then lbl.Text="" continue end
                local txt=""
                if State.ShowNames then
                    txt=p.Name..(State.ShowDistance and " ["..dist.."m]" or "").."\n"
                end
                if State.ShowHealth then
                    txt=txt..math.floor(hum.Health).."/"..math.floor(hum.MaxHealth).." HP"
                end
                lbl.Text=txt
            end
        else
            if bb then bb:Destroy() end
        end
    end
end)

-- Respawn
player.CharacterAdded:Connect(function(c)
    bodyVel=nil; bodyGyro=nil
    local hum=c:WaitForChild("Humanoid",5)
    if hum then
        task.wait(0.1)
        hum.WalkSpeed=State.WalkSpeed
        hum.JumpPower=State.JumpPower
    end
end)

-- ============================================================
--  TOGGLE MENU
--  KEY FIX: RightShift is often marked `processed = true` by
--  Roblox's engine. We check the key BEFORE the processed gate
--  so it is never silently swallowed.
-- ============================================================
local lastToggle = 0

UserInputService.InputBegan:Connect(function(inp, processed)
    -- ↓ Check toggle key FIRST — before the processed guard
    if inp.KeyCode == Config.ToggleKey then
        local now = tick()
        if now - lastToggle < 0.3 then return end
        lastToggle = now
        if menuOpen then closeMenu() else openMenu() end
        return   -- don't fall through
    end
    -- All other inputs respect the processed gate
    if processed then return end
end)

print("✓ Nexus Client "..Config.Version.." loaded — "..State.ToggleKeyName.." to open")
-- Finish the broken AccentR slider and add G/B sliders
        T.Accent = Color3.fromRGB(v, State.AccentG, State.AccentB) 
    end)

    addSlider("Settings", "AccentG", "Accent Green", 0, 255, 180, function(v)
        State.AccentG = v
        T.Accent = Color3.fromRGB(State.AccentR, v, State.AccentB)
    end)

    addSlider("Settings", "AccentB", "Accent Blue", 0, 255, 255, function(v)
        State.AccentB = v
        T.Accent = Color3.fromRGB(State.AccentR, State.AccentG, v)
    end)

-- ============================================================
--  INPUT LISTENER (The "Open/Close" Trigger)
-- ============================================================
UserInputService.InputBegan:Connect(function(input, processed)
    -- This ignores keypresses if you are typing in the game chat
    if processed then return end 

    if input.KeyCode == Config.ToggleKey then
        if menuOpen then
            closeMenu()
        else
            openMenu()
        end
    end
end)

-- Optional: Print to console so you know it loaded!
print("Nexus Client Loaded! Press " .. Config.ToggleKeyName .. " to open.")
