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

        -- ==========================================
        -- REVISED ARROW ESP UI SETUP
        -- ==========================================
        local arrowGui = hrp:FindFirstChild("NavArrowGui")
        if not arrowGui then
            arrowGui = Instance.new("BillboardGui")
            arrowGui.Name = "NavArrowGui"
            arrowGui.Size = UDim2.new(0, 120, 0, 120)
            arrowGui.StudsOffset = Vector3.new(0, 5, 0)
            arrowGui.AlwaysOnTop = true
            arrowGui.Adornee = hrp
            arrowGui.Parent = hrp

            -- White Circular Base (like the image)
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

            -- Glowing Green Arrow
            local arrowImg = Instance.new("ImageLabel")
            arrowImg.Name = "ArrowImage"
            arrowImg.Size = UDim2.new(0, 60, 0, 60)
            arrowImg.Position = UDim2.new(0.5, -30, 0, -15)
            arrowImg.BackgroundTransparency = 1
            -- Using a standard clean arrow asset. You can replace this ID with a custom one if you have it.
            arrowImg.Image = "rbxassetid://107233777" 
            arrowImg.ImageColor3 = Color3.fromRGB(0, 255, 120)
            arrowImg.Parent = arrowGui

            -- Distance Text
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

        if arrowGui then arrowGui.Enabled = false end
        
        if currentEspMode == "Arrow" and closestAdornee then
            arrowGui.Enabled = true
            
            local lookVector = hrp.CFrame.LookVector
            local targetDir = (closestAdornee.Position - hrp.Position).Unit
            local look2D = Vector2.new(lookVector.X, lookVector.Z).Unit
            local target2D = Vector2.new(targetDir.X, targetDir.Z).Unit
            
            -- Calculate angle relative to camera
            local angle = math.atan2(target2D.Y, target2D.X) - math.atan2(look2D.Y, look2D.X)
            local degrees = math.deg(angle)
            
            local arrowImg = arrowGui:FindFirstChild("ArrowImage")
            local distText = arrowGui:FindFirstChild("DistText")
            local baseCircle = arrowGui:FindFirstChild("BaseCircle")
            
            if arrowImg then
                -- Rotate the arrow
                arrowImg.Rotation = -degrees
                
                -- Change arrow color based on alignment
                local dotProduct = look2D:Dot(target2D)
                if dotProduct > 0.85 then
                    arrowImg.ImageColor3 = Color3.fromRGB(0, 255, 120) -- Bright Green (Facing target)
                    if baseCircle then baseCircle.BackgroundColor3 = Color3.fromRGB(0, 255, 120) end
                elseif dotProduct > 0.3 then
                    arrowImg.ImageColor3 = Color3.fromRGB(255, 200, 50) -- Yellow (Close)
                    if baseCircle then baseCircle.BackgroundColor3 = Color3.fromRGB(255, 200, 50) end
                else
                    arrowImg.ImageColor3 = Color3.fromRGB(255, 60, 60) -- Red (Behind)
                    if baseCircle then baseCircle.BackgroundColor3 = Color3.fromRGB(255, 60, 60) end
                end
            end
            
            if distText then
                distText.Text = math.floor(closestDist) .. "m"
            end
        end

        if autoPickupEnabled and hum and hum.Health > 0 and closestAdornee then
            if closestDist > 5 then
                hum:MoveTo(closestAdornee.Position)
            else
                hum:MoveTo(hrp.Position)
            end
        elseif autoPickupEnabled and hum and hum.Health > 0 and not closestAdornee then
            hum:MoveTo(hrp.Position)
        end
    end
end)
