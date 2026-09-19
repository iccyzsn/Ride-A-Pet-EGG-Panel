local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

-- EGG DATABASE
local trackedEggs = {
    ["152975769"] = {DisplayName = "Flaming Egg", Icon = "🔥", ImageId = "", Price = "Rare", Rarity = "Fire", Color = Color3.fromRGB(255, 120, 30)},
    ["70549049033717"] = {DisplayName = "Sinister Egg", Icon = "😈", ImageId = "100010318153363", Price = "Secret", Rarity = "Dark", Color = Color3.fromRGB(220, 40, 60)},
    ["131792796847596"] = {DisplayName = "Galaxy Egg", Icon = "🌌", ImageId = "100174338199842", Price = "1.5B", Rarity = "Divine", Color = Color3.fromRGB(180, 100, 255)},
    ["95155753812330"] = {DisplayName = "Soul Egg", Icon = "👻", ImageId = "113516441036388", Price = "Ethereal", Rarity = "Ghost", Color = Color3.fromRGB(120, 220, 255)},
    ["109698896973127"] = {DisplayName = "Skull Egg", Icon = "💀", ImageId = "133763014063788", Price = "Dark", Rarity = "Bone", Color = Color3.fromRGB(180, 180, 180)},
    ["6932488731"] = {DisplayName = "Blackhole Egg", Icon = "🕳️", ImageId = "", Price = "100B", Rarity = "Ethereal", Color = Color3.fromRGB(80, 80, 80)},
    ["99624357990460"] = {DisplayName = "Cherub Egg", Icon = "😇", ImageId = "", Price = "1T", Rarity = "Ethereal", Color = Color3.fromRGB(255, 255, 100)}
}

local selectedTargetEggs = {} 
local activeEggs = {}         
local currentEspMode = "Straight"
local espModes = {"Straight", "Arrow"} 
local currentEspIndex = 1
local autoPickupEnabled = false
local notifiedEggs = {}

-- AUTO PICKUP STATE VARIABLES
local autoPickupState = "Idle" -- "Idle", "ToEgg", "ToPlot"
local targetEgg = nil
local carriedEgg = nil
local flySpeed = 150
local noclipActive = false

local excludePaths = {"Plots", "Plot", "Ranch", "Backpack", "Base", "Farm", "House"} 

-- CREATE MODERN AESTHETIC GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "EggRadarUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true

local success = pcall(function()
    if gethui then
        screenGui.Parent = gethui()
    else
        if game:GetService("CoreGui"):FindFirstChild("EggRadarUI") then
            game:GetService("CoreGui").EggRadarUI:Destroy()
        end
        screenGui.Parent = game:GetService("CoreGui")
    end
end)
if not success then
    screenGui.Parent = player:WaitForChild("PlayerGui")
end

-- TOP CENTER RARE NOTIFICATION
local notifFrame = Instance.new("Frame")
notifFrame.Size = UDim2.new(0, 320, 0, 70)
notifFrame.Position = UDim2.new(0.5, -160, 0, -100)
notifFrame.BackgroundColor3 = Color3.fromRGB(20, 25, 35)
notifFrame.BorderSizePixel = 0
notifFrame.Parent = screenGui

local notifCorner = Instance.new("UICorner")
notifCorner.CornerRadius = UDim.new(0, 10)
notifCorner.Parent = notifFrame

local notifStroke = Instance.new("UIStroke")
notifStroke.Color = Color3.fromRGB(255, 255, 255)
notifStroke.Thickness = 2
notifStroke.Transparency = 0.5
notifStroke.Parent = notifFrame

local notifIcon = Instance.new("TextLabel")
notifIcon.Size = UDim2.new(0, 50, 1, 0)
notifIcon.BackgroundTransparency = 1
notifIcon.Text = "🌟"
notifIcon.TextSize = 32
notifIcon.Parent = notifFrame

local notifTitle = Instance.new("TextLabel")
notifTitle.Size = UDim2.new(1, -60, 0, 25)
notifTitle.Position = UDim2.new(0, 55, 0, 12)
notifTitle.BackgroundTransparency = 1
notifTitle.Text = "RARE EGG SPAWNED!"
notifTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
notifTitle.Font = Enum.Font.GothamBlack
notifTitle.TextSize = 16
notifTitle.TextXAlignment = Enum.TextXAlignment.Left
notifTitle.Parent = notifFrame

local notifSub = Instance.new("TextLabel")
notifSub.Size = UDim2.new(1, -60, 0, 20)
notifSub.Position = UDim2.new(0, 55, 0, 38)
notifSub.BackgroundTransparency = 1
notifSub.Text = "Cherub Egg is now available!"
notifSub.TextColor3 = Color3.fromRGB(200, 210, 230)
notifSub.Font = Enum.Font.GothamBold
notifSub.TextSize = 12
notifSub.TextXAlignment = Enum.TextXAlignment.Left
notifSub.Parent = notifFrame

local notifThread = nil
local function showTopNotif(name)
    local data = nil
    for _, d in pairs(trackedEggs) do
        if d.DisplayName == name then data = d break end
    end
    if not data then return end

    if notifThread then task.cancel(notifThread) end

    notifIcon.Text = data.Icon
    notifTitle.Text = name .. " SPAWNED!"
    notifTitle.TextColor3 = data.Color
    notifSub.Text = "Look up! It's currently available in the world."
    notifStroke.Color = data.Color

    notifFrame.Position = UDim2.new(0.5, -160, 0, -100)
    TweenService:Create(notifFrame, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, -160, 0, 20)}):Play()
    
    pcall(function()
        local snd = Instance.new("Sound")
        snd.SoundId = "rbxassetid://4590660214"
        snd.Volume = 1
        snd.Parent = screenGui
        snd:Play()
        game.Debris:AddItem(snd, 3)
    end)

    notifThread = task.delay(5, function()
        TweenService:Create(notifFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {Position = UDim2.new(0.5, -160, 0, -100)}):Play()
        notifThread = nil
    end)
end

-- MINIMIZED ICON
local miniIcon = Instance.new("TextButton")
miniIcon.Size = UDim2.new(0, 50, 0, 50)
miniIcon.Position = UDim2.new(0.03, 0, 0.3, 0)
miniIcon.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
miniIcon.Text = "🥚"
miniIcon.TextSize = 30
miniIcon.Visible = false
miniIcon.Parent = screenGui
miniIcon.Active = true

local miniCorner = Instance.new("UICorner")
miniCorner.CornerRadius = UDim.new(1, 0)
miniCorner.Parent = miniIcon

local miniStroke = Instance.new("UIStroke")
miniStroke.Color = Color3.fromRGB(50, 55, 70)
miniStroke.Thickness = 2
miniStroke.Parent = miniIcon

-- MAIN WINDOW
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 290, 0, 380)
mainFrame.Position = UDim2.new(0.03, 0, 0.3, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Active = true
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 10)
mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(50, 55, 70)
mainStroke.Thickness = 1
mainStroke.Parent = mainFrame

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 45)
header.BackgroundColor3 = Color3.fromRGB(25, 28, 35)
header.BorderSizePixel = 0
header.Parent = mainFrame
header.Active = true

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 10)
headerCorner.Parent = header

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1, -100, 1, 0)
titleText.Position = UDim2.new(0, 12, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "🥚 PET RADAR"
titleText.TextColor3 = Color3.fromRGB(245, 245, 250)
titleText.Font = Enum.Font.GothamBold
titleText.TextSize = 13
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = header

local miniBtn = Instance.new("TextButton")
miniBtn.Size = UDim2.new(0, 30, 0, 30)
miniBtn.Position = UDim2.new(1, -68, 0.5, -15)
miniBtn.BackgroundColor3 = Color3.fromRGB(45, 50, 65)
miniBtn.Text = "—"
miniBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
miniBtn.Font = Enum.Font.GothamBold
miniBtn.TextSize = 16
miniBtn.Parent = header

local miniBtnCorner = Instance.new("UICorner")
miniBtnCorner.CornerRadius = UDim.new(0, 6)
miniBtnCorner.Parent = miniBtn

local exitBtn = Instance.new("TextButton")
exitBtn.Size = UDim2.new(0, 30, 0, 30)
exitBtn.Position = UDim2.new(1, -34, 0.5, -15)
exitBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 60)
exitBtn.Text = "✕"
exitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
exitBtn.Font = Enum.Font.GothamBold
exitBtn.TextSize = 14
exitBtn.Parent = header

local exitCorner = Instance.new("UICorner")
exitCorner.CornerRadius = UDim.new(0, 6)
exitCorner.Parent = exitBtn

-- CONTROL BAR
local controlBar = Instance.new("Frame")
controlBar.Size = UDim2.new(1, -16, 0, 70)
controlBar.Position = UDim2.new(0, 8, 0, 50)
controlBar.BackgroundColor3 = Color3.fromRGB(30, 33, 40)
controlBar.BorderSizePixel = 0
controlBar.Parent = mainFrame

local controlCorner = Instance.new("UICorner")
controlCorner.CornerRadius = UDim.new(0, 8)
controlCorner.Parent = controlBar

local modeBtn = Instance.new("TextButton")
modeBtn.Size = UDim2.new(0.45, 0, 0, 25)
modeBtn.Position = UDim2.new(0.04, 0, 0, 6)
modeBtn.BackgroundColor3 = Color3.fromRGB(45, 50, 65)
modeBtn.Text = "📏 Line"
modeBtn.TextColor3 = Color3.fromRGB(240, 240, 245)
modeBtn.Font = Enum.Font.GothamBold
modeBtn.TextSize = 11
modeBtn.Parent = controlBar

local modeCorner = Instance.new("UICorner")
modeCorner.CornerRadius = UDim.new(0, 6)
modeCorner.Parent = modeBtn

local pickupBtn = Instance.new("TextButton")
pickupBtn.Size = UDim2.new(0.45, 0, 0, 25)
pickupBtn.Position = UDim2.new(0.51, 0, 0, 6)
pickupBtn.BackgroundColor3 = Color3.fromRGB(45, 50, 65)
pickupBtn.Text = "🤖 Pickup: OFF"
pickupBtn.TextColor3 = Color3.fromRGB(240, 240, 245)
pickupBtn.Font = Enum.Font.GothamBold
pickupBtn.TextSize = 11
pickupBtn.Parent = controlBar

local pickupCorner = Instance.new("UICorner")
pickupCorner.CornerRadius = UDim.new(0, 6)
pickupCorner.Parent = pickupBtn

local speedBox = Instance.new("TextBox")
speedBox.Size = UDim2.new(0.92, 0, 0, 25)
speedBox.Position = UDim2.new(0.04, 0, 0, 38)
speedBox.BackgroundColor3 = Color3.fromRGB(45, 50, 65)
speedBox.Text = "🚀 Speed: 150"
speedBox.TextColor3 = Color3.fromRGB(240, 240, 245)
speedBox.Font = Enum.Font.GothamBold
speedBox.TextSize = 11
speedBox.ClearTextOnFocus = false
speedBox.Parent = controlBar

local speedCorner = Instance.new("UICorner")
speedCorner.CornerRadius = UDim.new(0, 6)
speedCorner.Parent = speedBox

speedBox.FocusLost:Connect(function()
    local num = tonumber(string.match(speedBox.Text, "%d+"))
    if num then
        flySpeed = math.clamp(num, 10, 1000)
    end
    speedBox.Text = "🚀 Speed: " .. tostring(flySpeed)
end)

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, -16, 1, -130)
scrollFrame.Position = UDim2.new(0, 8, 0, 127)
scrollFrame.BackgroundTransparency = 1
scrollFrame.ScrollBarThickness = 3
scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 105, 120)
scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.BorderSizePixel = 0
scrollFrame.Parent = mainFrame

local uiLayout = Instance.new("UIListLayout")
uiLayout.Padding = UDim.new(0, 6)
uiLayout.Parent = scrollFrame

local eggUI = {}

for meshId, data in pairs(trackedEggs) do
    local card = Instance.new("TextButton")
    card.Size = UDim2.new(1, 0, 0, 52)
    card.BackgroundColor3 = Color3.fromRGB(28, 31, 38)
    card.BorderSizePixel = 0
    card.AutoButtonColor = false
    card.Text = ""
    card.Parent = scrollFrame
    
    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 8)
    cardCorner.Parent = card
    
    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = Color3.fromRGB(60, 65, 80)
    cardStroke.Thickness = 1
    cardStroke.Parent = card

    local accent = Instance.new("Frame")
    accent.Size = UDim2.new(0, 4, 1, -12)
    accent.Position = UDim2.new(0, 6, 0, 6)
    accent.BackgroundColor3 = data.Color
    accent.BorderSizePixel = 0
    accent.Parent = card
    
    local accentCorner = Instance.new("UICorner")
    accentCorner.CornerRadius = UDim.new(0, 4)
    accentCorner.Parent = accent

    local iconLabel
    if data.ImageId and data.ImageId ~= "" then
        iconLabel = Instance.new("ImageLabel")
        iconLabel.Image = "rbxassetid://" .. data.ImageId
        iconLabel.BackgroundColor3 = Color3.fromRGB(40, 45, 60)
    else
        iconLabel = Instance.new("TextLabel")
        iconLabel.Text = data.Icon
        iconLabel.TextSize = 20
        iconLabel.BackgroundTransparency = 1
    end
    iconLabel.Size = UDim2.new(0, 30, 0, 30)
    iconLabel.Position = UDim2.new(0, 16, 0.5, -15)
    iconLabel.Parent = card
    
    local iconCorner = Instance.new("UICorner")
    iconCorner.CornerRadius = UDim.new(0, 6)
    iconCorner.Parent = iconLabel

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(0.5, -15, 0, 18)
    nameLabel.Position = UDim2.new(0, 52, 0, 6)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = data.DisplayName
    nameLabel.TextColor3 = Color3.fromRGB(235, 235, 240)
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 12
    nameLabel.Parent = card

    local infoLabel = Instance.new("TextLabel")
    infoLabel.Size = UDim2.new(0.5, -15, 0, 14)
    infoLabel.Position = UDim2.new(0, 52, 0, 24)
    infoLabel.BackgroundTransparency = 1
    infoLabel.Text = data.Rarity .. " • " .. data.Price
    infoLabel.TextColor3 = Color3.fromRGB(140, 145, 160)
    infoLabel.TextXAlignment = Enum.TextXAlignment.Left
    infoLabel.Font = Enum.Font.Gotham
    infoLabel.TextSize = 10
    infoLabel.Parent = card

    local statusDot = Instance.new("Frame")
    statusDot.Size = UDim2.new(0, 6, 0, 6)
    statusDot.Position = UDim2.new(1, -80, 0.5, -3)
    statusDot.BackgroundColor3 = Color3.fromRGB(240, 70, 70)
    statusDot.BorderSizePixel = 0
    statusDot.Parent = card

    local dotCorner = Instance.new("UICorner")
    dotCorner.CornerRadius = UDim.new(1, 0)
    dotCorner.Parent = statusDot

    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(0, 68, 0, 20)
    statusLabel.Position = UDim2.new(1, -70, 0.5, -10)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "UNAVAILABLE"
    statusLabel.TextColor3 = Color3.fromRGB(150, 155, 170)
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.Font = Enum.Font.GothamBold
    statusLabel.TextSize = 8
    statusLabel.Parent = card

    card.MouseButton1Click:Connect(function()
        if selectedTargetEggs[data.DisplayName] then
            selectedTargetEggs[data.DisplayName] = nil
            card.BackgroundColor3 = Color3.fromRGB(28, 31, 38)
            cardStroke.Color = Color3.fromRGB(60, 65, 80)
            cardStroke.Thickness = 1
        else
            selectedTargetEggs[data.DisplayName] = true
            card.BackgroundColor3 = Color3.fromRGB(50, 80, 160) 
            cardStroke.Color = Color3.fromRGB(0, 255, 120)     
            cardStroke.Thickness = 2.5
        end
    end)

    eggUI[data.DisplayName] = {Card = card, Status = statusLabel, Dot = statusDot, Stroke = cardStroke}
end

modeBtn.MouseButton1Click:Connect(function()
    currentEspIndex = (currentEspIndex % #espModes) + 1
    currentEspMode = espModes[currentEspIndex]
    if currentEspMode == "Straight" then modeBtn.Text = "📏 Line"
    elseif currentEspMode == "Arrow" then modeBtn.Text = "🎯 Arrow" end
end)

pickupBtn.MouseButton1Click:Connect(function()
    autoPickupEnabled = not autoPickupEnabled
    if autoPickupEnabled then
        pickupBtn.Text = "🤖 Pickup: ON"
        pickupBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 80)
        autoPickupState = "Idle"
        noclipActive = true
    else
        pickupBtn.Text = "🤖 Pickup: OFF"
        pickupBtn.BackgroundColor3 = Color3.fromRGB(45, 50, 65)
        autoPickupState = "Idle"
        noclipActive = false
        targetEgg = nil
        if carriedEgg and carriedEgg.Parent then
            local adornee = getAdornee(carriedEgg)
            if adornee and adornee:FindFirstChild("AutoPickupWeld") then
                adornee.AutoPickupWeld:Destroy()
            end
        end
        carriedEgg = nil
    end
end)

local dragging, dragInput, dragStart, startPos
local function update(input, frame)
    local delta = input.Position - dragStart
    frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

local function setupDrag(handle, frame)
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
    end)
end

setupDrag(header, mainFrame)
setupDrag(miniIcon, miniIcon)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        if mainFrame.Visible then
            update(input, mainFrame)
        else
            update(input, miniIcon)
        end
    end
end)

miniBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = false
    miniIcon.Position = mainFrame.Position
    miniIcon.Visible = true
end)

miniIcon.MouseButton1Click:Connect(function()
    miniIcon.Visible = false
    mainFrame.Position = miniIcon.Position
    mainFrame.Visible = true
end)

-- HELPER FUNCTIONS
local function extractId(str)
    if not str or str == "" then return nil end
    return string.match(str, "%d+")
end

local function getAdornee(obj)
    if obj:IsA("BasePart") then return obj end
    if obj:IsA("Model") then
        if obj.PrimaryPart then return obj.PrimaryPart end
        return obj:FindFirstChildWhichIsA("BasePart", true)
    end
    return nil
end

local function checkEggByMesh(obj)
    if not (obj:IsA("BasePart") or obj:IsA("Model")) then return nil end
    
    local path = obj:GetFullName()
    for _, exclude in ipairs(excludePaths) do
        if string.find(path, exclude) then return nil end
    end
    if player.Character and obj:IsDescendantOf(player.Character) then return nil end
    
    if obj:IsA("MeshPart") then
        local meshId = extractId(obj.MeshId)
        if meshId and trackedEggs[meshId] then return trackedEggs[meshId].DisplayName end
    end
    local specialMesh = obj:FindFirstChildWhichIsA("SpecialMesh", true)
    if specialMesh then
        local meshId = extractId(specialMesh.MeshId)
        if meshId and trackedEggs[meshId] then return trackedEggs[meshId].DisplayName end
    end
    return nil
end

local function firePrompts(obj)
    if not obj then return end
    for _, prompt in ipairs(obj:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") then
            fireproximityprompt(prompt, 0)
        end
    end
end

local function findPlayerPlot()
    local searchFolders = {"Plots", "Ranches", "Ranch", "Farm", "Base", "Houses", "House"}
    for _, folderName in ipairs(searchFolders) do
        local folder = Workspace:FindFirstChild(folderName)
        if folder then
            local plot = folder:FindFirstChild(player.Name) or folder:FindFirstChild(tostring(player.UserId))
            if not plot then
                for _, child in ipairs(folder:GetChildren()) do
                    if child:GetAttribute("Owner") == player.Name or child:GetAttribute("Owner") == tostring(player.UserId) then
                        plot = child
                        break
                    end
                end
            end
            if plot then
                local base = plot:FindFirstChild("Base") or plot:FindFirstChild("PlotBase") or plot:FindFirstChildWhichIsA("BasePart", true)
                if base then return base end
            end
        end
    end
    return nil
end

local function clearESPForEgg(eggInst)
    if eggInst and eggInst.Parent then
        local hl = eggInst:FindFirstChild("RadarHighlight")
        if hl then hl:Destroy() end
        local tag = eggInst:FindFirstChild("RadarTag")
        if tag then tag:Destroy() end
        local att = eggInst:FindFirstChild("RadarAtt")
        if att then att:Destroy() end
    end
end

local function applyESPToEgg(eggInst, displayName)
    local adornee = getAdornee(eggInst)
    if not adornee then return end

    local espColor = Color3.new(1, 1, 1)
    for _, data in pairs(trackedEggs) do
        if data.DisplayName == displayName then espColor = data.Color break end
    end

    local highlight = Instance.new("Highlight")
    highlight.Name = "RadarHighlight"
    highlight.FillColor = espColor
    highlight.OutlineColor = Color3.new(1, 1, 1)
    highlight.FillTransparency = 0.4
    highlight.Parent = eggInst

    local eggAtt = Instance.new("Attachment")
    eggAtt.Name = "RadarAtt"
    eggAtt.Parent = adornee

    local beam = Instance.new("Beam")
    beam.Name = "RadarBeam"
    beam.Attachment1 = eggAtt
    beam.Color = ColorSequence.new(espColor)
    beam.Width0 = 0.12
    beam.Width1 = 0.12
    beam.FaceCamera = true
    beam.Transparency = NumberSequence.new(0.3)
    beam.Enabled = false
    beam.Parent = adornee

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "RadarTag"
    billboard.Size = UDim2.new(0, 150, 0, 30)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.LightInfluence = 0
    billboard.Adornee = adornee
    billboard.Parent = eggInst

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 1, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = displayName
    nameLabel.TextColor3 = espColor
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextStrokeColor3 = Color3.fromRGB(10, 10, 15)
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.GothamBlack
    nameLabel.Parent = billboard
end

-- BACKGROUND TRACKER
task.spawn(function()
    while task.wait(0.5) do
        local foundEggsMap = {} 
        for _, obj in ipairs(Workspace:GetDescendants()) do
            local displayName = checkEggByMesh(obj)
            if displayName then
                foundEggsMap[displayName] = obj
            end
        end

        for displayName, ui in pairs(eggUI) do
            if foundEggsMap[displayName] then
                ui.Status.Text = "AVAILABLE"
                ui.Status.TextColor3 = Color3.fromRGB(60, 230, 120)
                ui.Dot.BackgroundColor3 = Color3.fromRGB(60, 230, 120)
                
                if (displayName == "Cherub Egg" or displayName == "Blackhole Egg") and not notifiedEggs[displayName] then
                    showTopNotif(displayName)
                    notifiedEggs[displayName] = true
                end
            else
                ui.Status.Text = "UNAVAILABLE"
                ui.Status.TextColor3 = Color3.fromRGB(140, 145, 160)
                ui.Dot.BackgroundColor3 = Color3.fromRGB(240, 70, 70)
                if notifiedEggs[displayName] then notifiedEggs[displayName] = false end
            end
        end

        for eggInst, eggName in pairs(activeEggs) do
            if not selectedTargetEggs[eggName] or not eggInst.Parent or not foundEggsMap[eggName] then
                clearESPForEgg(eggInst)
                activeEggs[eggInst] = nil
            end
        end

        for eggName, _ in pairs(selectedTargetEggs) do
            local inst = foundEggsMap[eggName]
            if inst and not activeEggs[inst] then
                applyESPToEgg(inst, eggName)
                activeEggs[inst] = eggName
            end
        end
    end
end)

-- NOCLIP LOOP
RunService.Stepped:Connect(function()
    if noclipActive and player.Character then
        for _, part in pairs(player.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end
end)

-- MAIN RENDER & FLIGHT LOGIC
RunService.RenderStepped:Connect(function(dt)
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    
    if hrp then
        if not hrp:FindFirstChild("PlayerRadarAtt") then
            local att = Instance.new("Attachment")
            att.Name = "PlayerRadarAtt"
            att.Parent = hrp
        end
        local playerAtt = hrp:FindFirstChild("PlayerRadarAtt")

        -- ARROW ESP UI SETUP
        local arrowGui = hrp:FindFirstChild("NavArrowGui")
        if not arrowGui then
            arrowGui = Instance.new("BillboardGui")
            arrowGui.Name = "NavArrowGui"
            arrowGui.Size = UDim2.new(0, 120, 0, 120)
            arrowGui.StudsOffset = Vector3.new(0, 5, 0)
            arrowGui.AlwaysOnTop = true
            arrowGui.Adornee = hrp
            arrowGui.Parent = hrp

            local baseCircle = Instance.new("Frame")
            baseCircle.Name = "BaseCircle"
            baseCircle.Size = UDim2.new(0, 30, 0, 30)
            baseCircle.Position = UDim2.new(0.5, -15, 0.5, -15)
            baseCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            baseCircle.BorderSizePixel = 0
            baseCircle.Parent = arrowGui
            
            local baseCorner = Instance.new("UICorner")
            baseCorner.CornerRadius = UDim.new(1, 0)
            baseCorner.Parent = baseCircle

            local arrowImg = Instance.new("ImageLabel")
            arrowImg.Name = "ArrowImage"
            arrowImg.Size = UDim2.new(0, 60, 0, 60)
            arrowImg.Position = UDim2.new(0.5, -30, 0, -15)
            arrowImg.BackgroundTransparency = 1
            arrowImg.Image = "rbxassetid://107233777" 
            arrowImg.ImageColor3 = Color3.fromRGB(0, 255, 120)
            arrowImg.Parent = arrowGui

            local distLabel = Instance.new("TextLabel")
            distLabel.Name = "DistText"
            distLabel.Size = UDim2.new(1, 0, 0, 20)
            distLabel.Position = UDim2.new(0, 0, 0, 75)
            distLabel.BackgroundTransparency = 1
            distLabel.Text = "0m"
            distLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            distLabel.TextStrokeTransparency = 0.3
            distLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
            distLabel.Font = Enum.Font.GothamBlack
            distLabel.TextSize = 18
            distLabel.Parent = arrowGui
        end

        local closestEggInst = nil
        local closestDist = math.huge
        local closestAdornee = nil

        -- Process ESP for active eggs
        for eggInst, eggName in pairs(activeEggs) do
            if eggInst and eggInst.Parent then
                local adornee = getAdornee(eggInst)
                if adornee then
                    local dist = (adornee.Position - hrp.Position).Magnitude
                    if dist < closestDist then
                        closestDist = dist
                        closestEggInst = eggInst
                        closestAdornee = adornee
                    end

                    local beam = adornee:FindFirstChild("RadarBeam")
                    local billboard = eggInst:FindFirstChild("RadarTag")
                    if beam then beam.Enabled = false end
                    if billboard then billboard.Enabled = false end

                    if currentEspMode == "Straight" then
                        if beam then
                            beam.Attachment0 = playerAtt
                            beam.Enabled = true
                        end
                        if billboard then
                            billboard.Enabled = true
                            billboard.Size = UDim2.new(0, 150, 0, 30)
                            billboard.StudsOffset = Vector3.new(0, 3, 0)
                        end
                    end
                end
            else
                clearESPForEgg(eggInst)
                activeEggs[eggInst] = nil
            end
        end

        -- Handle Arrow UI
        if arrowGui then arrowGui.Enabled = false end
        if currentEspMode == "Arrow" and closestAdornee and autoPickupState == "Idle" then
            arrowGui.Enabled = true
            local lookVector = hrp.CFrame.LookVector
            local targetDir = (closestAdornee.Position - hrp.Position).Unit
            local look2D = Vector2.new(lookVector.X, lookVector.Z).Unit
            local target2D = Vector2.new(targetDir.X, targetDir.Z).Unit
            local angle = math.atan2(target2D.Y, target2D.X) - math.atan2(look2D.Y, look2D.X)
            local degrees = math.deg(angle)
            
            local arrowImg = arrowGui:FindFirstChild("ArrowImage")
            local distText = arrowGui:FindFirstChild("DistText")
            local baseCircle = arrowGui:FindFirstChild("BaseCircle")
            
            if arrowImg then
                arrowImg.Rotation = -degrees
                local dotProduct = look2D:Dot(target2D)
                if dotProduct > 0.85 then
                    arrowImg.ImageColor3 = Color3.fromRGB(0, 255, 120)
                    if baseCircle then baseCircle.BackgroundColor3 = Color3.fromRGB(0, 255, 120) end
                elseif dotProduct > 0.3 then
                    arrowImg.ImageColor3 = Color3.fromRGB(255, 200, 50)
                    if baseCircle then baseCircle.BackgroundColor3 = Color3.fromRGB(255, 200, 50) end
                else
                    arrowImg.ImageColor3 = Color3.fromRGB(255, 60, 60)
                    if baseCircle then baseCircle.BackgroundColor3 = Color3.fromRGB(255, 60, 60) end
                end
            end
            if distText then distText.Text = math.floor(closestDist) .. "m" end
        end

        -- FLIGHT & AUTO PICKUP STATE MACHINE
        if autoPickupEnabled and hum and hum.Health > 0 then
            hum.PlatformStand = true -- Prevent falling
            
            local targetPos = nil
            local arrivalDist = 5

            if autoPickupState == "Idle" then
                if closestEggInst then
                    targetEgg = closestEggInst
                    autoPickupState = "ToEgg"
                end
            
            elseif autoPickupState == "ToEgg" then
                if not targetEgg or not targetEgg.Parent then
                    autoPickupState = "Idle"
                    targetEgg = nil
                else
                    local adornee = getAdornee(targetEgg)
                    if adornee then
                        targetPos = adornee.Position
                        arrivalDist = 4
                        
                        if (adornee.Position - hrp.Position).Magnitude < 6 then
                            -- Instantly fire any proximity prompts to pick up
                            firePrompts(targetEgg)
                            
                            -- Weld it to us in case the game expects us to physically carry it
                            adornee.Anchored = false
                            adornee.CanCollide = false
                            if not adornee:FindFirstChild("AutoPickupWeld") then
                                local weld = Instance.new("WeldConstraint")
                                weld.Name = "AutoPickupWeld"
                                weld.Part0 = hrp
                                weld.Part1 = adornee
                                weld.Parent = adornee
                            end
                            carriedEgg = targetEgg
                            targetEgg = nil
                            autoPickupState = "ToPlot"
                        end
                    end
                end
            
            elseif autoPickupState == "ToPlot" then
                local plotBase = findPlayerPlot()
                if not plotBase then
                    -- No plot found, drop it
                    if carriedEgg and carriedEgg.Parent then
                        local adornee = getAdornee(carriedEgg)
                        if adornee and adornee:FindFirstChild("AutoPickupWeld") then
                            adornee.AutoPickupWeld:Destroy()
                        end
                    end
                    carriedEgg = nil
                    autoPickupState = "Idle"
                else
                    targetPos = plotBase.Position + Vector3.new(0, 8, 0)
                    arrivalDist = 8
                    
                    if (targetPos - hrp.Position).Magnitude < 10 then
                        -- Arrived at plot, fire drop prompts if any exist
                        firePrompts(plotBase)
                        firePrompts(carriedEgg)
                        
                        -- Unweld
                        if carriedEgg and carriedEgg.Parent then
                            local adornee = getAdornee(carriedEgg)
                            if adornee and adornee:FindFirstChild("AutoPickupWeld") then
                                adornee.AutoPickupWeld:Destroy()
                            end
                        end
                        carriedEgg = nil
                        autoPickupState = "Idle"
                    end
                end
            end

            -- VELOCITY FLIGHT LOGIC
            if targetPos then
                local dir = (targetPos - hrp.Position)
                local dist = dir.Magnitude
                
                if dist > arrivalDist then
                    -- Push character towards target smoothly using AssemblyLinearVelocity
                    hrp.AssemblyLinearVelocity = dir.Unit * flySpeed
                    
                    -- Keep character upright and looking in the direction of movement
                    local lookAtPos = Vector3.new(targetPos.X, hrp.Position.Y, targetPos.Z)
                    if (lookAtPos - hrp.Position).Magnitude > 0.5 then
                        hrp.CFrame = CFrame.lookAt(hrp.Position, lookAtPos)
                    end
                else
                    -- Stop moving when arrived
                    hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                end
            else
                -- Hover in place if idle
                hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            end
        else
            if hum then hum.PlatformStand = false end
        end
    end
end)

-- CLEANUP ON EXIT
exitBtn.MouseButton1Click:Connect(function()
    for eggInst, _ in pairs(activeEggs) do
        clearESPForEgg(eggInst)
    end
    activeEggs = {}
    
    local char = player.Character
    if char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local att = hrp:FindFirstChild("PlayerRadarAtt")
            if att then att:Destroy() end
            local arrowGui = hrp:FindFirstChild("NavArrowGui")
            if arrowGui then arrowGui:Destroy() end
        end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false end
    end
    screenGui:Destroy()
end) 
