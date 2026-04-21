--============================================================
--  NEXUS CLIENT v3.0.0 |  Advanced Edition (GitHub Version)
--============================================================
--  Now with:
--    • Anticheat Warnings
--    • Discord Support Card
--    • Unlimited Number Inputs
--    • ColorSequence Fix
--============================================================

if not game:IsLoaded() then game.Loaded:Wait() end

--// Services
local Players            = game:GetService("Players")
local UserInputService   = game:GetService("UserInputService")
local RunService         = game:GetService("RunService")
local TweenService       = game:GetService("TweenService")
local Lighting           = game:GetService("Lighting")
local Workspace          = game:GetService("Workspace")
local CoreGui            = game:GetService("CoreGui")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera
if not player.Character then player.CharacterAdded:Wait() end

--// Config + Defaults
local Config = {
	ToggleKey = Enum.KeyCode.RightShift,
	Version   = "v3.0.0"
}

local Defaults = {}
local function cacheDefaults()
	Defaults.Ambient         = Lighting.Ambient
	Defaults.Brightness      = Lighting.Brightness
	Defaults.FogEnd          = Lighting.FogEnd
	Defaults.FogColor        = Lighting.FogColor
	Defaults.GlobalShadows   = Lighting.GlobalShadows
	Defaults.ClockTime       = Lighting.ClockTime
	Defaults.Gravity         = Workspace.Gravity
	Defaults.FOV             = camera.FieldOfView
	Defaults.MouseBehavior   = UserInputService.MouseBehavior
	Defaults.MouseIconEnabled= UserInputService.MouseIconEnabled
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	Defaults.WalkSpeed       = hum and hum.WalkSpeed or 16
	Defaults.JumpPower       = hum and hum.JumpPower or 50
end
cacheDefaults()

--// State (trimmed here; full set continues in next file)
local State = {
	Theme = "Dark",
	MenuOpacity = 97,
	MenuScale   = 100,
	AccentR=100, AccentG=180, AccentB=255,
	Draggable=true, ShowHints=true,
	ToggleKeyName="RightShift",
}

--============================================================
--  THEME SYSTEM
--============================================================
local Themes = {
	Dark = {
		BG=Color3.fromRGB(14,14,18),
		Panel=Color3.fromRGB(20,20,26),
		Card=Color3.fromRGB(26,26,34),
		Border=Color3.fromRGB(40,40,55),
		Text=Color3.fromRGB(220,220,230),
		SubText=Color3.fromRGB(120,120,140),
		On  =Color3.fromRGB(60,200,120),
		Off =Color3.fromRGB(60,60,75),
	},
	Neon = {
		BG=Color3.fromRGB(5,5,10),
		Panel=Color3.fromRGB(10,10,20),
		Card=Color3.fromRGB(15,15,28),
		Border=Color3.fromRGB(80,40,120),
		Text=Color3.fromRGB(230,200,255),
		SubText=Color3.fromRGB(140,100,180),
		On  =Color3.fromRGB(180,80,255),
		Off =Color3.fromRGB(40,20,60),
	},
	Blood = {
		BG=Color3.fromRGB(12,6,6),
		Panel=Color3.fromRGB(22,10,10),
		Card=Color3.fromRGB(30,14,14),
		Border=Color3.fromRGB(80,20,20),
		Text=Color3.fromRGB(230,210,210),
		SubText=Color3.fromRGB(140,90,90),
		On  =Color3.fromRGB(220,50,50),
		Off =Color3.fromRGB(60,20,20),
	},
	Light = {
		BG=Color3.fromRGB(240,240,248),
		Panel=Color3.fromRGB(255,255,255),
		Card=Color3.fromRGB(248,248,255),
		Border=Color3.fromRGB(200,200,215),
		Text=Color3.fromRGB(30,30,40),
		SubText=Color3.fromRGB(100,100,120),
		On  =Color3.fromRGB(40,180,100),
		Off =Color3.fromRGB(180,180,200),
	},
}

local function getAccent()
	return Color3.fromRGB(State.AccentR,State.AccentG,State.AccentB)
end

local Theme = {}
local function getTheme()
	local base = Themes[State.Theme] or Themes.Dark
	for k,v in pairs(base) do Theme[k]=v end
	Theme.Accent = getAccent()
end
getTheme()

--============================================================
--  UI BASE
--============================================================
local gui = Instance.new("ScreenGui")
gui.Name="NexusClient"
gui.ResetOnSpawn=false
gui.IgnoreGuiInset=true
gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
pcall(function() gui.Parent=CoreGui end)
if not gui.Parent then gui.Parent=player:WaitForChild("PlayerGui") end

local function make(class,props,parent)
	local obj=Instance.new(class)
	for k,v in pairs(props)do obj[k]=v end
	if parent then obj.Parent=parent end
	return obj
end
local function corner(r,p) return make("UICorner",{CornerRadius=UDim.new(0,r)},p) end
local function stroke(t,c,p) return make("UIStroke",{Thickness=t,Color=c,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},p) end
local function tw(o,p,d,s,e) TweenService:Create(o,TweenInfo.new(d or .18,s or Enum.EasingStyle.Quad,e or Enum.EasingDirection.Out),p):Play() end

-- Accent binder
local accentTargets={}
local function bindAccent(obj,prop)
	table.insert(accentTargets,{object=obj,property=prop})
end
local topGradient -- forward ref

local function applyAccent()
	getTheme()
	for _,item in ipairs(accentTargets) do
		if item.object and item.object.Parent then
			if item.property=="Color" and item.object:IsA("UIGradient") then
				item.object.Color=ColorSequence.new{
					ColorSequenceKeypoint.new(0,Theme.Accent),
					ColorSequenceKeypoint.new(1,Theme.BG)
				}
			else
				item.object[item.property]=Theme.Accent
			end
		end
	end
	if topGradient then
		topGradient.Color=ColorSequence.new{
			ColorSequenceKeypoint.new(0,Theme.Accent),
			ColorSequenceKeypoint.new(1,Theme.BG)
		}
	end
end

--============================================================
--  MAIN WINDOW
--============================================================
local win=make("Frame",{
	Size=UDim2.new(0,600,0,440),
	Position=UDim2.new(.5,-300,.5,-220),
	BackgroundColor3=Theme.BG,
	BackgroundTransparency=1,
	BorderSizePixel=0,
	Visible=false,
	Active=true,
	Draggable=State.Draggable
},gui)
corner(12,win)
stroke(1,Theme.Border,win)
local winScale=make("UIScale",{Scale=0.9},win)

local menuOpen,menuAnimating=false,false
local function openMenu()
	if menuOpen or menuAnimating then return end
	menuAnimating=true
	win.Visible=true
	win.BackgroundTransparency=1
	winScale.Scale=.85
	tw(win,{BackgroundTransparency=1-(State.MenuOpacity/100)},.25,Enum.EasingStyle.Quint)
	tw(winScale,{Scale=State.MenuScale/100},.3,Enum.EasingStyle.Back)
	task.delay(.31,function() menuAnimating=false menuOpen=true end)
end
local function closeMenu()
	if not menuOpen or menuAnimating then return end
	menuAnimating=true
	tw(win,{BackgroundTransparency=1},.2)
	tw(winScale,{Scale=.85},.18)
	task.delay(.22,function()
		win.Visible=false
		menuAnimating=false
		menuOpen=false
	end)
end

--============================================================
--  TOP BAR
--============================================================
local topBar=make("Frame",{
	Size=UDim2.new(1,0,0,48),
	BackgroundColor3=Theme.Panel,
	BorderSizePixel=0
},win)
corner(12,topBar)

topGradient=make("UIGradient",{
	Color=ColorSequence.new{
		ColorSequenceKeypoint.new(0,Theme.Accent),
		ColorSequenceKeypoint.new(1,Theme.BG)
	},
	Rotation=90,
	Transparency=NumberSequence.new{
		NumberSequenceKeypoint.new(0,0.55),
		NumberSequenceKeypoint.new(1,1)
	}
},topBar)
bindAccent(topGradient,"Color")

make("TextLabel",{
	Size=UDim2.new(0,200,1,0),
	Position=UDim2.new(0,16,0,0),
	BackgroundTransparency=1,
	Text="NEXUS",
	TextColor3=Theme.Text,
	TextSize=18,Font=Enum.Font.GothamBold,
	TextXAlignment=Enum.TextXAlignment.Left
},topBar)

make("TextLabel",{
	Size=UDim2.new(0,120,1,0),
	Position=UDim2.new(1,-140,0,0),
	BackgroundTransparency=1,
	Text=Config.Version,
	TextColor3=Theme.SubText,
	TextSize=11,Font=Enum.Font.Gotham,
	TextXAlignment=Enum.TextXAlignment.Right
},topBar)

local closeBtn=make("TextButton",{
	Size=UDim2.new(0,28,0,28),
	Position=UDim2.new(1,-36,0.5,-14),
	BackgroundColor3=Color3.fromRGB(200,60,60),
	BorderSizePixel=0,
	Text="X",TextColor3=Color3.new(1,1,1),
	TextSize=12,Font=Enum.Font.GothamBold
},topBar)
corner(6,closeBtn)
closeBtn.MouseButton1Click:Connect(closeMenu)
closeBtn.MouseEnter:Connect(function() tw(closeBtn,{BackgroundColor3=Color3.fromRGB(240,80,80)},.1) end)
closeBtn.MouseLeave:Connect(function() tw(closeBtn,{BackgroundColor3=Color3.fromRGB(200,60,60)},.1) end)

--============================================================
--  WARNING HELPER + BASIC TAB STRUCTURE (continued later)
--============================================================
local tabFrames,layoutOrder,tabButtons={}, {}, {}
local function nextOrder(tab) layoutOrder[tab]=(layoutOrder[tab] or 0)+1 return layoutOrder[tab] end

local function addWarning(tab,text)
	local parent=tabFrames[tab]
	local warn=make("Frame",{
		Size=UDim2.new(1,0,0,36),
		BackgroundColor3=Color3.fromRGB(50,15,15),
		BorderSizePixel=0,
		LayoutOrder=nextOrder(tab)
	},parent)
	corner(8,warn)
	stroke(1,Color3.fromRGB(200,80,80),warn)
	make("TextLabel",{
		Size=UDim2.new(1,-16,1,-6),
		Position=UDim2.new(0,8,0,3),
		BackgroundTransparency=1,
		Text="⚠️  "..text,
		TextColor3=Color3.fromRGB(255,140,140),
		TextSize=12,Font=Enum.Font.GothamSemibold,
		TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true
	},warn)
end

--============================================================
--  CONTINUE IN NEXT MODULE ...
--============================================================
print("[Nexus Client] Core + UI loaded successfully.")
