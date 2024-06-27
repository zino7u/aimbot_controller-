local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = game.Workspace.CurrentCamera

-- GUI erstellen
local ScreenGui = Instance.new("ScreenGui")
local ToggleButton = Instance.new("TextButton")
local TargetBox = Instance.new("Frame")
local ESPContainer = Instance.new("Folder")

ScreenGui.Name = "TrackingGUI"
ScreenGui.Parent = player:WaitForChild("PlayerGui")

ToggleButton.Size = UDim2.new(0, 100, 0, 50)
ToggleButton.Position = UDim2.new(1, -110, 0, 10)
ToggleButton.Text = "Toggle Off"
ToggleButton.Parent = ScreenGui

TargetBox.Size = UDim2.new(0, 10, 0, 10) -- Kleinere Box
TargetBox.BackgroundColor3 = Color3.new(1, 0, 0)
TargetBox.Visible = false
TargetBox.AnchorPoint = Vector2.new(0.5, 0.5)
TargetBox.Parent = ScreenGui

ESPContainer.Name = "ESPContainer"
ESPContainer.Parent = ScreenGui

local trackingEnabled = false
local trackedPlayer = nil

local function toggleTracking(state)
    trackingEnabled = state
    ToggleButton.Text = trackingEnabled and "Toggle On" or "Toggle Off"
    TargetBox.Visible = trackingEnabled
    if trackingEnabled then
        trackedPlayer = trackedPlayer or getNearestPlayer()
    else
        trackedPlayer = nil
    end
end

ToggleButton.MouseButton1Click:Connect(function()
    toggleTracking(not trackingEnabled)
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.ButtonL2 and not gameProcessed then
        toggleTracking(true)
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.ButtonL2 and not gameProcessed then
        toggleTracking(false)
    end
end)

local function createESP(player)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = player.Name .. "_ESP"
    billboard.Adornee = player.Character:WaitForChild("Head")
    billboard.Size = UDim2.new(0, 100, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 2, 0)
    billboard.AlwaysOnTop = true
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Text = player.Name
    nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.TextStrokeTransparency = 0
    nameLabel.Parent = billboard
    
    local healthLabel = Instance.new("TextLabel")
    healthLabel.Text = "Health: " .. math.floor(player.Character.Humanoid.Health)
    healthLabel.Size = UDim2.new(1, 0, 0.5, 0)
    healthLabel.Position = UDim2.new(0, 0, 0.5, 0)
    healthLabel.BackgroundTransparency = 1
    healthLabel.TextColor3 = Color3.new(1, 1, 1)
    healthLabel.TextStrokeTransparency = 0
    healthLabel.Parent = billboard
    
    billboard.Parent = ESPContainer

    local box = Instance.new("BoxHandleAdornment")
    box.Name = player.Name .. "_ESPBox"
    box.Adornee = player.Character
    box.Size = player.Character:GetExtentsSize()
    box.Color3 = Color3.new(math.random(), math.random(), math.random())
    box.Transparency = 0.5
    box.ZIndex = 1
    box.AlwaysOnTop = true
    box.Parent = ESPContainer

    return billboard
end

local function updateESP(esp, player)
    local healthLabel = esp:FindFirstChildOfClass("TextLabel")
    if healthLabel then
        healthLabel.Text = "Health: " .. math.floor(player.Character.Humanoid.Health)
    end

    local box = ESPContainer:FindFirstChild(player.Name .. "_ESPBox")
    if box then
        box.Size = player.Character:GetExtentsSize()
        box.Adornee = player.Character
    end
end

local function getNearestPlayer()
    local nearestPlayer = nil
    local shortestDistance = math.huge

    for _, otherPlayer in pairs(Players:GetPlayers()) do
        if otherPlayer ~= player and otherPlayer.Character and otherPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local distance = (otherPlayer.Character.HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position).magnitude
            if distance < shortestDistance then
                shortestDistance = distance
                nearestPlayer = otherPlayer
            end
        end
    end

    return nearestPlayer
end

local function onCharacterAdded(character)
    -- Code, der beim Hinzufügen eines neuen Charakters ausgeführt werden soll
    character:WaitForChild("HumanoidRootPart")
    character:WaitForChild("Head")
    
    for _, otherPlayer in pairs(Players:GetPlayers()) do
        if otherPlayer ~= player then
            local esp = ESPContainer:FindFirstChild(otherPlayer.Name .. "_ESP")
            if esp then
                esp.Adornee = otherPlayer.Character.Head
            else
                createESP(otherPlayer)
            end
        end
    end
end

player.CharacterAdded:Connect(onCharacterAdded)
if player.Character then
    onCharacterAdded(player.Character)
end

RunService.RenderStepped:Connect(function()
    if not ScreenGui.Parent then
        ScreenGui.Parent = player:WaitForChild("PlayerGui")
    end

    if trackingEnabled and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        if not trackedPlayer or not trackedPlayer.Character or not trackedPlayer.Character:FindFirstChild("HumanoidRootPart") then
            trackedPlayer = getNearestPlayer()
        end
        
        if trackedPlayer and trackedPlayer.Character and trackedPlayer.Character:FindFirstChild("HumanoidRootPart") then
            camera.CFrame = CFrame.new(camera.CFrame.Position, trackedPlayer.Character.HumanoidRootPart.Position)

            local screenPosition, onScreen = camera:WorldToScreenPoint(trackedPlayer.Character.HumanoidRootPart.Position)
            if onScreen then
                TargetBox.Position = UDim2.new(0, screenPosition.X, 0, screenPosition.Y)
                TargetBox.Visible = true
            else
                TargetBox.Visible = false
            end
        else
            TargetBox.Visible = false
        end
    else
        TargetBox.Visible = false
    end
    
    -- ESP aktualisieren
    for _, otherPlayer in pairs(Players:GetPlayers()) do
        if otherPlayer ~= player and otherPlayer.Character and otherPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local esp = ESPContainer:FindFirstChild(otherPlayer.Name .. "_ESP") or createESP(otherPlayer)
            updateESP(esp, otherPlayer)
        end
    end
end)
