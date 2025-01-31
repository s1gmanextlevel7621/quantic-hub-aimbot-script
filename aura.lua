
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local camera = workspace.CurrentCamera

-- Configuration
local FOV_RADIUS = 120
local ESP_ENABLED = false
local AIMBOT_ENABLED = false
local TEAM_CHECK = true
local HEALTH_CHECK = true
local IS_LOCKED = false
local LOCK_TARGET = nil

-- Player Initialization
local player = Players.LocalPlayer
repeat task.wait() until player
local guiParent = RunService:IsStudio() and player.PlayerGui or game:GetService("CoreGui")

-- Cleanup Previous GUI
if guiParent:FindFirstChild("QUANTICHub") then
    guiParent.QUANTICHub:Destroy()
end

-- Main GUI
local gui = Instance.new("ScreenGui")
gui.Name = "QUANTICHub"
gui.ResetOnSpawn = false
gui.Parent = guiParent

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 400, 0, 350)
mainFrame.Position = UDim2.new(0.5, -200, 0.5, 500) -- Start offscreen
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Parent = gui

-- Animated Entry
TweenService:Create(mainFrame, TweenInfo.new(0.7, Enum.EasingStyle.Quint), {
    Position = UDim2.new(0.5, -200, 0.5, -175)
}):Play()

-- Header
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 40)
header.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
header.Parent = mainFrame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(0.7, 0, 1, 0)
title.Text = "🔮 QUANTIC HUB"
title.TextColor3 = Color3.fromRGB(0, 200, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.BackgroundTransparency = 1
title.Parent = header

local version = Instance.new("TextLabel")
version.Size = UDim2.new(0.3, 0, 1, 0)
version.Position = UDim2.new(0.7, 0, 0, 0)
version.Text = "v2.1.0"
version.TextColor3 = Color3.fromRGB(120, 120, 120)
version.Font = Enum.Font.Gotham
version.TextSize = 12
version.TextXAlignment = Enum.TextXAlignment.Right
version.BackgroundTransparency = 1
version.Parent = header

-- Draggable UI
local dragging, dragInput, dragStart, startPos
header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
    end
end)

header.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)


header.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input == dragInput then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(
            startPos.X.Scale, 
            startPos.X.Offset + delta.X,
            startPos.Y.Scale, 
            startPos.Y.Offset + delta.Y
        )
    end
end)

-- Toggle Buttons
local function CreateToggle(text, yPos)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0.9, 0, 0, 40)
    button.Position = UDim2.new(0.05, 0, 0, yPos)
    button.Text = text
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Font = Enum.Font.Gotham
    button.TextSize = 14
    button.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    button.Parent = mainFrame

    local status = Instance.new("Frame")
    status.Size = UDim2.new(0, 14, 0, 14)
    status.Position = UDim2.new(1, -24, 0.5, -7)
    status.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    status.Parent = button

    return button, status
end

local espButton, espStatus = CreateToggle("Player ESP", 45)
local aimbotButton, aimbotStatus = CreateToggle("Head Aimbot", 95)
local teamButton, teamStatus = CreateToggle("Team Check", 145)
local healthButton, healthStatus = CreateToggle("Health Check", 195)

-- ESP System
local highlights = {}

local function UpdateESP()
    for _, targetPlayer in ipairs(Players:GetPlayers()) do
        if targetPlayer ~= player then
            local character = targetPlayer.Character
            local existing = highlights[targetPlayer]
            
            if ESP_ENABLED and character then
                if not existing then
                    local highlight = Instance.new("Highlight")
                    highlight.Adornee = character
                    highlight.FillColor = targetPlayer.TeamColor.Color
                    highlight.OutlineTransparency = 0.5
                    highlight.Parent = character
                    
                    local billboard = Instance.new("BillboardGui")
                    billboard.Size = UDim2.new(0, 100, 0, 50)
                    billboard.Adornee = character:WaitForChild("Head")
                    billboard.AlwaysOnTop = true
                    billboard.Parent = character
                    
                    local label = Instance.new("TextLabel")
                    label.Size = UDim2.new(1, 0, 1, 0)
                    label.Text = targetPlayer.Name
                    label.TextColor3 = Color3.new(1, 1, 1)
                    label.BackgroundTransparency = 1
                    label.Parent = billboard
                    
                    highlights[targetPlayer] = {highlight, billboard}
                end
                
                -- Update distance
                if character:FindFirstChild("HumanoidRootPart") then
                    local distance = (character.HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude
                    highlights[targetPlayer][2].TextLabel.Text = string.format("%s\n%d studs", targetPlayer.Name, math.floor(distance))
                end
            elseif existing then
                existing[1]:Destroy()
                existing[2]:Destroy()
                highlights[targetPlayer] = nil
            end
        end
    end
end

-- Aimbot System
local fovCircle
if not RunService:IsStudio() then
    fovCircle = Drawing.new("Circle")
    fovCircle.Visible = true
    fovCircle.Color = Color3.new(1, 1, 1)
    fovCircle.Thickness = 2
    fovCircle.Filled = false
    fovCircle.Radius = FOV_RADIUS
end

local function ValidateTarget(head)
    if not head then return false end
    local character = head.Parent
    local humanoid = character:FindFirstChild("Humanoid")
    local player = Players:GetPlayerFromCharacter(character)
    
    if TEAM_CHECK and player and player.Team == Players.LocalPlayer.Team then return false end
    if HEALTH_CHECK and (not humanoid or humanoid.Health <= 0) then return false end
    
    return true
end

local function GetClosestHead()
    local closestHead, closestDist = nil, math.huge
    local mousePos = UserInputService:GetMouseLocation()
    
    for _, targetPlayer in ipairs(Players:GetPlayers()) do
        if targetPlayer ~= player then
            local character = targetPlayer.Character
            if character then
                local head = character:FindFirstChild("Head")
                if head and ValidateTarget(head) then
                    local screenPos, onScreen = camera:WorldToViewportPoint(head.Position)
                    if onScreen then
                        local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                        if dist < FOV_RADIUS and dist < closestDist then
                            closestHead = head
                            closestDist = dist
                        end
                    end
                end
            end
        end
    end
    return closestHead
end

-- Input Handling
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 and AIMBOT_ENABLED then
        IS_LOCKED = true
        LOCK_TARGET = GetClosestHead()
        
        while IS_LOCKED and task.wait() do
            if not ValidateTarget(LOCK_TARGET) then
                LOCK_TARGET = GetClosestHead()
            end
            
            if LOCK_TARGET and ValidateTarget(LOCK_TARGET) then
                camera.CFrame = CFrame.lookAt(camera.CFrame.Position, LOCK_TARGET.Position)
            else
                IS_LOCKED = false
                break
            end
            
            if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
                IS_LOCKED = false
                break
            end
        end
    end
end)

-- Toggle Handlers
local function UpdateStatus(status, state)
    TweenService:Create(status, TweenInfo.new(0.2), {
        BackgroundColor3 = state and Color3.fromRGB(0, 200, 255) or Color3.fromRGB(80, 80, 80)
    }):Play()
end

espButton.MouseButton1Click:Connect(function()
    ESP_ENABLED = not ESP_ENABLED
    UpdateStatus(espStatus, ESP_ENABLED)
    espButton.Text = "ESP: " .. (ESP_ENABLED and "ON" or "OFF")
end)

aimbotButton.MouseButton1Click:Connect(function()
    AIMBOT_ENABLED = not AIMBOT_ENABLED
    UpdateStatus(aimbotStatus, AIMBOT_ENABLED)
    aimbotButton.Text = "Aimbot: " .. (AIMBOT_ENABLED and "ON" or "OFF")
end)

teamButton.MouseButton1Click:Connect(function()
    TEAM_CHECK = not TEAM_CHECK
    UpdateStatus(teamStatus, TEAM_CHECK)
    teamButton.Text = "Team Check: " .. (TEAM_CHECK and "ON" or "OFF")
end)

healthButton.MouseButton1Click:Connect(function()
    HEALTH_CHECK = not HEALTH_CHECK
    UpdateStatus(healthStatus, HEALTH_CHECK)
    healthButton.Text = "Health Check: " .. (HEALTH_CHECK and "ON" or "OFF")
end)

-- Discord Button
local discordButton = CreateToggle("Join Discord", 245)
discordButton.MouseButton1Click:Connect(function()
    pcall(function()
        setclipboard("https://discord.gg/yourlink")
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Discord",
            Text = "Link copied to clipboard!",
            Duration = 3
        })
    end)
end)

-- Runtime Updates
RunService.RenderStepped:Connect(function()
    UpdateESP()
    if fovCircle then
        fovCircle.Position = UserInputService:GetMouseLocation()
    end
end)
