local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

-- ==========================================
-- EGG DATABASE
-- ==========================================
local trackedEggs = {
    ["152975769"] = {DisplayName = "Flaming Egg", Icon = "🔥", ImageId = "", Price = "Rare", Rarity = "Fire", Color = Color3.fromRGB(255, 120, 30)},
    ["70549049033717"] = {DisplayName = "Sinister Egg", Icon = "😈", ImageId = "", Price = "Secret", Rarity = "Dark", Color = Color3.fromRGB(220, 40, 60)},
    ["131792796847596"] = {DisplayName = "Galaxy Egg", Icon = "🌌", ImageId = "", Price = "1.5B", Rarity = "Divine", Color = Color3.fromRGB(180, 100, 255)},
    ["95155753812330"] = {DisplayName = "Soul Egg", Icon = "👻", ImageId = "", Price = "Ethereal", Rarity = "Ghost", Color = Color3.fromRGB(120, 220, 255)},
    ["109698896973127"] = {DisplayName = "Skull Egg", Icon = "💀", ImageId = "", Price = "Dark", Rarity = "Bone", Color = Color3.fromRGB(180, 180, 180)},
    ["6932488731"] = {DisplayName = "Blackhole Egg", Icon = "🕳️", ImageId = "", Price = "100B", Rarity = "Ethereal", Color = Color3.fromRGB(80, 80, 80)},
    ["99624357990460"] = {DisplayName = "Cherub Egg", Icon = "😇", ImageId = "", Price = "1T", Rarity = "Ethereal", Color = Color3.fromRGB(255, 255, 100)}
}

-- Removed the excludePaths restriction that was causing the "Unavailable" bug
local selectedTargetEgg = nil
local currentTrackedInstance = nil
local currentEspMode = "Straight"
local espModes = {"Straight", "Arrow"}
local currentEspIndex = 1
local autoPickupEnabled = false

-- ==========================================
-- 1. CREATE MODERN AESTHETIC GUI
-- ==========================================
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

-- Main Window
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 320, 0, 380)
mainFrame.Position = UDim2.new(0, 20, 0.5, -190)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 10)
mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(50, 55, 70)
mainStroke.Thickness = 1
mainStroke.Parent = mainFrame

-- Header
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 45)
header.BackgroundColor3 = Color3.fromRGB(25, 28, 35)
header.BorderSizePixel = 0
header.Parent = mainFrame

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 10)
headerCorner.Parent = header

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1, -50, 1, 0)
titleText.Position = UDim2.new(0, 15, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "🥚 RIDE A PET RADAR"
titleText.TextColor3 = Color3.fromRGB(245, 245, 250)
titleText.Font = Enum.Font.GothamBold
titleText.TextSize = 14
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = header

local exitBtn = Instance.new("TextButton")
exitBtn.Size = UDim2.new(0, 28, 0, 28)
exitBtn.Position = UDim2.new(1, -36, 0.5, -14)
exitBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 60)
exitBtn.Text = "✕"
exitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
exitBtn.Font = Enum.Font.GothamBold
exitBtn.TextSize = 12
exitBtn.Parent = header

local exitCorner = Instance.new("UICorner")
exitCorner.CornerRadius = UDim.new(0, 6)
exitCorner.Parent = exitBtn

-- Controls Bar
local controlBar = Instance.new("Frame")
controlBar.Size = UDim2.new(1, -20, 0, 35)
controlBar.Position = UDim2.new(0, 10, 0, 50)
controlBar.BackgroundColor3 = Color3.fromRGB(30, 33, 40)
controlBar.BorderSizePixel = 0
controlBar.Parent = mainFrame

local controlCorner = Instance.new("UICorner")
controlCorner.CornerRadius = UDim.new(0, 8)
controlCorner.Parent = controlBar

local modeBtn = Instance.new("TextButton")
modeBtn.Size = UDim2.new(0.45, 0, 0, 25)
modeBtn.Position = UDim2.new(0, 5, 0.5, -12.5)
modeBtn.BackgroundColor3 = Color3.fromRGB(45, 50, 65)
modeBtn.Text = "📏 Straight Line"
modeBtn.TextColor3 = Color3.fromRGB(240, 240, 245)
modeBtn.Font = Enum.Font.GothamBold
modeBtn.TextSize = 10
modeBtn.Parent = controlBar

local modeCorner = Instance.new("UICorner")
modeCorner.CornerRadius = UDim.new(0, 6)
modeCorner.Parent = modeBtn

local pickupBtn = Instance.new("TextButton")
pickupBtn.Size = UDim2.new(0.45, 0, 0, 25)
pickupBtn.Position = UDim2.new(0.55, 0, 0.5, -12.5)
pickupBtn.BackgroundColor3 = Color3.fromRGB(45, 50, 65)
pickupBtn.Text = "🤖 Auto Pickup: OFF"
pickupBtn.TextColor3 = Color3.fromRGB(240, 240, 245)
pickupBtn.Font = Enum.Font.GothamBold
pickupBtn.TextSize = 10
pickupBtn.Parent = controlBar

local pickupCorner = Instance.new("UICorner")
pickupCorner.CornerRadius = UDim.new(0, 6)
pickupCorner.Parent = pickupBtn

-- Scroll Area
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, -16, 1, -100)
scrollFrame.Position = UDim2.new(0, 8, 0, 92)
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

-- Egg Cards
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

    -- Icon/Image Logic
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
    nameLabel.Position = UDim2.new(0, 52, 0, 8)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = data.DisplayName
    nameLabel.TextColor3 = Color3.fromRGB(235, 235, 240)
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 12
    nameLabel.Parent = card

    local infoLabel = Instance.new("TextLabel")
    infoLabel.Size = UDim2.new(0.5, -15, 0, 14)
    infoLabel.Position = UDim2.new(0, 52, 0, 26)
    infoLabel.BackgroundTransparency = 1
    infoLabel.Text = data.Rarity .. " • " .. data.Price
    infoLabel.TextColor3 = Color3.fromRGB(140, 145, 160)
    infoLabel.TextXAlignment = Enum.TextXAlignment.Left
    infoLabel.Font = Enum.Font.Gotham
    infoLabel.TextSize = 10
    infoLabel.Parent = card

    local statusDot = Instance.new("Frame")
    statusDot.Size = UDim2.new(0, 6, 0, 6)
    statusDot.Position = UDim2.new(1, -85, 0.5, -3)
    statusDot.BackgroundColor3 = Color3.fromRGB(240, 70, 70)
    statusDot.BorderSizePixel = 0
    statusDot.Parent = card

    local dotCorner = Instance.new("UICorner")
    dotCorner.CornerRadius = UDim.new(1, 0)
    dotCorner.Parent = statusDot

    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(0, 72, 0, 20)
    statusLabel.Position = UDim2.new(1, -75, 0.5, -10)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "UNAVAILABLE"
    statusLabel.TextColor3 = Color3.fromRGB(150, 155, 170)
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.Font = Enum.Font.GothamBold
    statusLabel.TextSize = 9
    statusLabel.Parent = card

    card.MouseButton1Click:Connect(function()
        selectedTargetEgg = data.DisplayName
        currentTrackedInstance = nil 
        for _, ui in pairs(eggUI) do
            ui.Card.BackgroundColor3 = Color3.fromRGB(28, 31, 38)
            ui.Stroke.Color = Color3.fromRGB(60, 65, 80)
        end
        card.BackgroundColor3 = Color3.fromRGB(40, 45, 60)
        cardStroke.Color = data.Color
    end)

    eggUI[data.DisplayName] = {Card = card, Status = statusLabel, Dot = statusDot, Stroke = cardStroke}
end

-- Button Logic
modeBtn.MouseButton1Click:Connect(function()
    currentEspIndex = (currentEspIndex % #espModes) + 1
    currentEspMode = espModes[currentEspIndex]
    modeBtn.Text = currentEspMode == "Straight" and "📏 Straight Line" or "🎯 Nav Arrow"
end)

pickupBtn.MouseButton1Click:Connect(function()
    autoPickupEnabled = not autoPickupEnabled
    if autoPickupEnabled then
        pickupBtn.Text = "🤖 Auto Pickup: ON"
        pickupBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 80)
    else
        pickupBtn.Text = "🤖 Auto Pickup: OFF"
        pickupBtn.BackgroundColor3 = Color3.fromRGB(45, 50, 65)
    end
end)

-- Dragging Logic
local dragging, dragInput, dragStart, startPos
local function update(input)
    local delta = input.Position - dragStart
    mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true; dragStart = input.Position; startPos = mainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
header.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then update(input) end
end)

-- ==========================================
-- 2. ESP & TRACKING LOGIC
-- ==========================================
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
    
    -- Removed the path exclusion here so it finds eggs everywhere
    
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

local function clearESP()
    if currentTrackedInstance and currentTrackedInstance.Parent then
        local hl = currentTrackedInstance:FindFirstChild("RadarHighlight")
        if hl then hl:Destroy() end
        local tag = currentTrackedInstance:FindFirstChild("RadarTag")
        if tag then tag:Destroy() end
        local att = currentTrackedInstance:FindFirstChild("RadarAtt")
        if att then att:Destroy() end
    end
end

local function applyESP(egg)
    clearESP()
    local adornee = getAdornee(egg)
    if not adornee then return end

    local espColor = Color3.new(1, 1, 1)
    for _, data in pairs(trackedEggs) do
        if data.DisplayName == selectedTargetEgg then espColor = data.Color break end
    end

    local highlight = Instance.new("Highlight")
    highlight.Name = "RadarHighlight"
    highlight.FillColor = espColor
    highlight.OutlineColor = Color3.new(1, 1, 1)
    highlight.FillTransparency = 0.4
    highlight.Parent = egg

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
    beam.Enabled = (currentEspMode == "Straight")
    beam.Parent = adornee

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "RadarTag"
    billboard.Size = UDim2.new(0, 150, 0, 30)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Adornee = adornee
    billboard.Parent = egg

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 1, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = selectedTargetEgg
    nameLabel.TextColor3 = espColor
    nameLabel.TextStrokeTransparency = 0.2
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Parent = billboard
end

-- ==========================================
-- 3. BACKGROUND TRACKER & RENDER LOOP
-- ==========================================
task.spawn(function()
    while task.wait(0.5) do
        local foundEgg = nil
        local isAvailable = false
        
        for _, obj in ipairs(Workspace:GetDescendants()) do
            local displayName = checkEggByMesh(obj)
            if displayName and displayName == selectedTargetEgg then
                foundEgg = obj
                isAvailable = true
                break
            end
        end

        if selectedTargetEgg and eggUI[selectedTargetEgg] then
            local ui = eggUI[selectedTargetEgg]
            if isAvailable then
                ui.Status.Text = "AVAILABLE"
                ui.Status.TextColor3 = Color3.fromRGB(60, 230, 120)
                ui.Dot.BackgroundColor3 = Color3.fromRGB(60, 230, 120)
            else
                ui.Status.Text = "UNAVAILABLE"
                ui.Status.TextColor3 = Color3.fromRGB(140, 145, 160)
                ui.Dot.BackgroundColor3 = Color3.fromRGB(240, 70, 70)
            end
        end

        if foundEgg and currentTrackedInstance ~= foundEgg then
            currentTrackedInstance = foundEgg
            applyESP(foundEgg)
        elseif not foundEgg and currentTrackedInstance then
            clearESP()
            currentTrackedInstance = nil
        end
    end
end)

RunService.RenderStepped:Connect(function()
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

        local arrowGui = hrp:FindFirstChild("NavArrowGui")
        if not arrowGui then
            arrowGui = Instance.new("BillboardGui")
            arrowGui.Name = "NavArrowGui"
            arrowGui.Size = UDim2.new(0, 100, 0, 60)
            arrowGui.StudsOffset = Vector3.new(0, 5, 0)
            arrowGui.AlwaysOnTop = true
            arrowGui.Adornee = hrp
            arrowGui.Parent = hrp

            local arrowLabel = Instance.new("TextLabel")
            arrowLabel.Name = "ArrowText"
            arrowLabel.Size = UDim2.new(1, 0, 0, 35)
            arrowLabel.BackgroundTransparency = 1
            arrowLabel.Text = "🎯"
            arrowLabel.TextColor3 = Color3.fromRGB(0, 255, 120)
            arrowLabel.Font = Enum.Font.GothamBold
            arrowLabel.TextSize = 30
            arrowLabel.Parent = arrowGui

            local distLabel = Instance.new("TextLabel")
            distLabel.Name = "DistText"
            distLabel.Size = UDim2.new(1, 0, 0, 20)
            distLabel.Position = UDim2.new(0, 0, 0, 35)
            distLabel.BackgroundTransparency = 1
            distLabel.Text = "0m"
            distLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            distLabel.Font = Enum.Font.GothamBold
            distLabel.TextSize = 14
            distLabel.Parent = arrowGui
        end

        if currentTrackedInstance and currentTrackedInstance.Parent then
            local adornee = getAdornee(currentTrackedInstance)
            if adornee then
                local dist = (adornee.Position - hrp.Position).Magnitude
                
                local beam = adornee:FindFirstChild("RadarBeam")
                if beam then
                    beam.Attachment0 = playerAtt
                    beam.Enabled = (currentEspMode == "Straight")
                end

                arrowGui.Enabled = (currentEspMode == "Arrow")
                if currentEspMode == "Arrow" then
                    local lookVector = hrp.CFrame.LookVector
                    local targetDir = (adornee.Position - hrp.Position).Unit
                    local look2D = Vector2.new(lookVector.X, lookVector.Z).Unit
                    local target2D = Vector2.new(targetDir.X, targetDir.Z).Unit
                    local angle = math.atan2(target2D.Y, target2D.X) - math.atan2(look2D.Y, look2D.X)
                    local degrees = math.deg(angle)
                    
                    local arrowText = arrowGui:FindFirstChild("ArrowText")
                    local distText = arrowGui:FindFirstChild("DistText")
                    if arrowText then
                        arrowText.Rotation = -degrees
                        local dotProduct = look2D:Dot(target2D)
                        if dotProduct > 0.85 then
                            arrowText.TextColor3 = Color3.fromRGB(0, 255, 120)
                        elseif dotProduct > 0.3 then
                            arrowText.TextColor3 = Color3.fromRGB(255, 200, 50)
                        else
                            arrowText.TextColor3 = Color3.fromRGB(255, 60, 60)
                        end
                    end
                    if distText then
                        distText.Text = math.floor(dist) .. "m"
                    end
                end

                if autoPickupEnabled and hum and hum.Health > 0 then
                    if dist > 5 then
                        hum:MoveTo(adornee.Position)
                    else
                        hum:MoveTo(hrp.Position)
                    end
                end
            end
        else
            arrowGui.Enabled = false
            if autoPickupEnabled and hum and hum.Health > 0 then
                hum:MoveTo(hrp.Position)
            end
        end
    end
end)

-- Exit Logic
exitBtn.MouseButton1Click:Connect(function()
    clearESP()
    local char = player.Character
    if char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local att = hrp:FindFirstChild("PlayerRadarAtt")
            if att then att:Destroy() end
            local arrowGui = hrp:FindFirstChild("NavArrowGui")
            if arrowGui then arrowGui:Destroy() end
        end
    end
    screenGui:Destroy()
end)

-- Notification
pcall(function()
    StarterGui:SetCore("SendNotification", {
        Title = "Radar Ready",
        Text = "Select an egg from the menu to begin tracking.",
        Duration = 4
    })
end)
