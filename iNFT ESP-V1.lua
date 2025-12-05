-- ============================================================--
-- DARKCARBON HUB + Ore ESP (Full Working)
-- Toggle → Menu dengan Tab (Home / Controls / Settings)
-- ============================================================--

-- ===== Services =====
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

-- ===== Cleanup old GUIs =====
for _,name in ipairs({"DarkCarbonUI_Final","OreESP_Billboards"}) do
    local old = PlayerGui:FindFirstChild(name)
    if old then pcall(function() old:Destroy() end) end
end

-- ===== Helper funcs =====
local function tween(obj, props, t)
    TweenService:Create(obj, TweenInfo.new(t or 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end
local function makeCorner(parent, rad) local c = Instance.new("UICorner", parent); c.CornerRadius = UDim.new(0, rad or 8); return c end
local function clamp(v,a,b) return math.clamp(v,a,b) end

-- ===== Ore Data =====
local ORE_DATA = {
    ["Pebble"]=14, ["Rock"]=45, ["Boulder"]=100,
    ["Basalt Rock"]=250, ["Basalt Core"]=750, ["Basalt Vein"]=2750,
    ["Volcanic Rock"]=4500, ["Crimson Crystal"]=5005,
    ["Earth Crystal"]=5005, ["Cyan Crystal"]=5005
}

local ORE_COLORS = {
    ["Pebble"]=Color3.fromRGB(0,255,0),
    ["Rock"]=Color3.fromRGB(150,150,150),
    ["Boulder"]=Color3.fromRGB(200,200,200),
    ["Basalt Rock"]=Color3.fromRGB(70,70,70),
    ["Basalt Core"]=Color3.fromRGB(150,0,255),
    ["Basalt Vein"]=Color3.fromRGB(90,0,180),
    ["Volcanic Rock"]=Color3.fromRGB(255,80,0),
    ["Crimson Crystal"]=Color3.fromRGB(255,0,60),
    ["Earth Crystal"]=Color3.fromRGB(0,255,100),
    ["Cyan Crystal"]=Color3.fromRGB(0,255,255),
    DEFAULT=Color3.fromRGB(0,200,255)
}
local function GetOreColor(n) return ORE_COLORS[n] or ORE_COLORS.DEFAULT end

-- ===== ESP State =====
local ESP_ByHitbox = {} -- [hitbox] = {box, billboard, label, oreName}
local OreToggle = {}    -- per-ore ON/OFF
for k,_ in pairs(ORE_DATA) do OreToggle[k]=false end

-- Folder rocks
local ROCK_FOLDER_NAME = "Rocks"
local ROCK_FOLDER = Workspace:FindFirstChild(ROCK_FOLDER_NAME)

-- Billboard container
local BillboardGuiContainer = Instance.new("ScreenGui")
BillboardGuiContainer.Name = "OreESP_Billboards"
BillboardGuiContainer.ResetOnSpawn = false
BillboardGuiContainer.Parent = PlayerGui

-- ===== Functions =====
local function GetOreHP(hitbox)
    if not hitbox or not hitbox.Parent then return 0 end
    local model = hitbox.Parent
    local a = hitbox:GetAttribute("Health")
    if type(a)=="number" then return a end
    local b = model:GetAttribute("Health")
    if type(b)=="number" then return b end
    for _,v in ipairs(model:GetDescendants()) do
        if v:IsA("NumberValue") or v:IsA("IntValue") then
            local n = string.lower(v.Name)
            if n=="hp" or n=="health" then return v.Value end
        end
    end
    return ORE_DATA[model.Name] or 0
end

local function CreateESP(hitbox)
    if not hitbox or not hitbox:IsA("BasePart") then return end
    if ESP_ByHitbox[hitbox] then return end
    if not hitbox.Parent then return end
    local oreName = hitbox.Parent.Name
    if not OreToggle[oreName] then return end
    local color = GetOreColor(oreName)

    local box = Instance.new("BoxHandleAdornment")
    box.Name = "OreBox"
    box.Adornee = hitbox
    box.Size = hitbox.Size
    box.Color3 = color
    box.AlwaysOnTop = true
    box.Transparency = 0.5
    box.ZIndex = 5
    box.Parent = hitbox

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "OreBillboard"
    billboard.Adornee = hitbox
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0,180,0,24)
    billboard.Parent = BillboardGuiContainer

    local label = Instance.new("TextLabel")
    label.Name = "OreLabel"
    label.Size = UDim2.new(1,0,1,0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextScaled = true
    label.TextColor3 = color
    label.TextStrokeTransparency = 0.6
    label.Parent = billboard

    ESP_ByHitbox[hitbox] = {box=box,billboard=billboard,label=label,oreName=oreName,hitbox=hitbox}
end

local function RemoveESP(hitbox)
    local data = ESP_ByHitbox[hitbox]
    if not data then return end
    pcall(function()
        if data.box and data.box.Parent then data.box:Destroy() end
        if data.billboard and data.billboard.Parent then data.billboard:Destroy() end
    end)
    ESP_ByHitbox[hitbox]=nil
end

local function ScanOre(oreName)
    if not ROCK_FOLDER then return end
    for _,desc in ipairs(ROCK_FOLDER:GetDescendants()) do
        if desc:IsA("BasePart") and desc.Name=="Hitbox" and desc.Parent.Name==oreName then
            pcall(function() CreateESP(desc) end)
        end
    end
end

local function WatchFolder(folder)
    if not folder then return end
    folder.DescendantAdded:Connect(function(obj)
        if obj:IsA("BasePart") and obj.Name=="Hitbox" then
            local oreName=obj.Parent and obj.Parent.Name
            if OreToggle[oreName] then pcall(function() CreateESP(obj) end) end
        end
    end)
    folder.DescendantRemoving:Connect(function(obj)
        if obj:IsA("BasePart") and ESP_ByHitbox[obj] then
            pcall(function() RemoveESP(obj) end)
        end
    end)
end
if ROCK_FOLDER then WatchFolder(ROCK_FOLDER) end
Workspace.DescendantAdded:Connect(function(obj)
    if obj.Name==ROCK_FOLDER_NAME and obj:IsA("Folder") then
        ROCK_FOLDER=obj
        for ore,_ in pairs(OreToggle) do if OreToggle[ore] then ScanOre(ore) end end
        WatchFolder(obj)
    end
end)

-- ===== Throttled update =====
local accumulator=0
local UPDATE_INTERVAL=0.25
RunService.Heartbeat:Connect(function(dt)
    accumulator=accumulator+dt
    if accumulator<UPDATE_INTERVAL then return end
    accumulator=0
    local rootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    for hitbox,data in pairs(ESP_ByHitbox) do
        if not hitbox or not hitbox.Parent then RemoveESP(hitbox) else
            local visible = OreToggle[data.oreName]
            if not visible then RemoveESP(hitbox) else
                local hp=GetOreHP(hitbox)
                local dist=rootPart and math.floor((rootPart.Position-hitbox.Position).Magnitude) or 0
                if data.label then
                    data.label.Text=string.format("%s | HP: %d | %dm",data.oreName,hp,dist)
                end
                if data.box and data.box.Adornee==hitbox and data.box.Size~=hitbox.Size then
                    data.box.Size=hitbox.Size
                end
            end
        end
    end
end)

-- ===== GUI =====
local UI = Instance.new("ScreenGui")
UI.Name = "DarkCarbonUI_Final"
UI.ResetOnSpawn=false
UI.Parent=PlayerGui
UI.DisplayOrder=100000

-- main frame
local main = Instance.new("Frame")
main.Name="MainFrame"
main.Size=UDim2.new(0,480,0,420)
main.Position=UDim2.new(0.25,0,0.18,0)
main.BackgroundColor3=Color3.fromRGB(18,18,22)
main.BorderSizePixel=0
main.Parent=UI
makeCorner(main,14)

-- draggable
local dragging,dragStart,startPos
main.InputBegan:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 then
        dragging=true
        dragStart=input.Position
        startPos=main.Position
    end
end)
main.InputEnded:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType==Enum.UserInputType.MouseMovement then
        local delta=input.Position-dragStart
        main.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+delta.X,startPos.Y.Scale,startPos.Y.Offset+delta.Y)
    end
end)

-- show/hide toggle (left-top)
local topToggle = Instance.new("TextButton",UI)
topToggle.Size=UDim2.new(0,56,0,56)
topToggle.Position=UDim2.new(0,18,0,18)
topToggle.BackgroundColor3=Color3.fromRGB(20,20,24)
topToggle.Text="≡"
topToggle.Font=Enum.Font.GothamBold
topToggle.TextColor3=Color3.fromRGB(150,255,160)
makeCorner(topToggle,12)
local uiOpen=true
topToggle.MouseButton1Click:Connect(function()
    uiOpen=not uiOpen
    main.Visible=uiOpen
end)

-- panels & tabs
local header=Instance.new("Frame",main)
header.Size=UDim2.new(1,0,0,56)
header.BackgroundColor3=Color3.fromRGB(26,26,32)
header.Position=UDim2.new(0,0,0,0)
makeCorner(header,12)

local title=Instance.new("TextLabel",header)
title.Size=UDim2.new(0.5,-12,1,0)
title.Position=UDim2.new(0.02,0,0,0)
title.BackgroundTransparency=1
title.Text="DarkCarbon — Dev UI"
title.Font=Enum.Font.GothamBold
title.TextColor3=Color3.fromRGB(150,255,160)
title.TextScaled=true

-- tab container
local tabContainer=Instance.new("Frame",header)
tabContainer.Size=UDim2.new(0.58,0,1,0)
tabContainer.Position=UDim2.new(0.4,0,0,0)
tabContainer.BackgroundTransparency=1
local tabLayout=Instance.new("UIListLayout",tabContainer)
tabLayout.FillDirection=Enum.FillDirection.Horizontal
tabLayout.Padding=UDim.new(0,8)
tabLayout.HorizontalAlignment=Enum.HorizontalAlignment.Right

local tabNames={"Home","Controls","Settings"}
local tabButtons={}
for i,name in ipairs(tabNames) do
    local b=Instance.new("TextButton",tabContainer)
    b.Name="Tab_"..name
    b.Size=UDim2.new(0,90,0,40)
    b.AutoButtonColor=false
    b.Text=name
    b.Font=Enum.Font.GothamSemibold
    b.TextColor3=Color3.fromRGB(200,200,220)
    b.BackgroundTransparency=1
    makeCorner(b,8)
    tabButtons[name]=b
end

-- content root
local contentRoot=Instance.new("Frame",main)
contentRoot.Size=UDim2.new(1,0,1,-56)
contentRoot.Position=UDim2.new(0,0,0,56)
contentRoot.BackgroundTransparency=1
local panels={}
local function makePanel(name)
    local p=Instance.new("Frame",contentRoot)
    p.Name=name
    p.Size=UDim2.new(1,0,1,0)
    p.Position=UDim2.new(0,0,0,0)
    p.BackgroundTransparency=1
    p.Visible=false
    panels[name]=p
    return p
end
local homePanel=makePanel("Home")
local controlsPanel=makePanel("Controls")
local settingsPanel=makePanel("Settings")

local function makeScroll(area)
    local s=Instance.new("ScrollingFrame",area)
    s.Size=UDim2.new(1,-24,1,-24)
    s.Position=UDim2.new(0,12,0,12)
    s.BackgroundTransparency=1
    s.AutomaticCanvasSize=Enum.AutomaticSize.Y
    s.ScrollBarThickness=8
    local layout=Instance.new("UIListLayout",s)
    layout.Padding=UDim.new(0,10)
    layout.SortOrder=Enum.SortOrder.LayoutOrder
    return s
end

local homeScroll=makeScroll(homePanel)
local controlsScroll=makeScroll(controlsPanel)
local settingsScroll=makeScroll(settingsPanel)

-- Tabs activation
local function activateTab(name)
    for k,v in pairs(panels) do v.Visible=(k==name) end
end
for name,btn in pairs(tabButtons) do
    btn.MouseButton1Click:Connect(function() activateTab(name) end)
end
activateTab("Home")

-- ===== SETTINGS: ESP toggles =====
local settingsTitle=Instance.new("TextLabel",settingsScroll)
settingsTitle.Size=UDim2.new(1,0,0,28)
settingsTitle.BackgroundTransparency=1
settingsTitle.Text="ESP Settings (tap to toggle)"
settingsTitle.Font=Enum.Font.GothamBold
settingsTitle.TextColor3=Color3.fromRGB(200,255,180)

local function addOreToggle(parent, oreName)
    local row=Instance.new("Frame",parent)
    row.Size=UDim2.new(1,0,0,36)
    row.BackgroundTransparency=1

    local label=Instance.new("TextLabel",row)
    label.Size=UDim2.new(0.65,0,1,0)
    label.BackgroundTransparency=1
    label.Text=oreName.." ("..tostring(ORE_DATA[oreName] or 0)..")"
    label.Font=Enum.Font.Gotham
    label.TextColor3=GetOreColor(oreName)

    local btn=Instance.new("TextButton",row)
    btn.Size=UDim2.new(0,88,0,28)
    btn.Position=UDim2.new(1,-96,0,4)
    btn.Text="OFF"
    btn.Font=Enum.Font.GothamBold
    btn.TextColor3=Color3.fromRGB(240,240,240)
    btn.BackgroundColor3=Color3.fromRGB(80,80,90)
    makeCorner(btn,8)

    btn.MouseButton1Click:Connect(function()
        local newState = not OreToggle[oreName]
        OreToggle[oreName]=newState
        if newState then
            btn.Text="ON"
            btn.BackgroundColor3=Color3.fromRGB(0,150,60)
            ScanOre(oreName)
        else
            btn.Text="OFF"
            btn.BackgroundColor3=Color3.fromRGB(80,80,90)
            for hitbox,data in pairs(ESP_ByHitbox) do
                if data.oreName==oreName then RemoveESP(hitbox) end
            end
        end
    end)
end

local oreNames={}
for n,_ in pairs(ORE_DATA) do table.insert(oreNames,n) end
table.sort(oreNames)
for _,name in ipairs(oreNames) do addOreToggle(settingsScroll,name) end

-- Final
print("DarkCarbon UI + OreESP loaded — toggles default OFF, drag GUI with mouse or touch.")
