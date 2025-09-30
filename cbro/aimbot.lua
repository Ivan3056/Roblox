-- Aimbot Module for Counter Blox Enhanced
-- Based on working code provided by user - FIXED VERSION

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local Aimbot = {}

-- Aimbot state
local AimbotState = {
    Enabled = false,
    Tracking = false,
    CurrentTarget = nil,
    LastScanTime = 0,
    ScanCooldown = 0.02,
    NoiseTime = 0,
    RecoilOffset = CFrame.new(),
    Connection = nil
}

-- Settings (will be synced with main settings)
local Settings = {
    Enabled = false,
    FOV = 90,
    Smoothness = 0.15, -- Correct value range
    MaxDistance = 400,
    TeamCheck = true,
    VisibilityCheck = true,
    PredictionStrength = 0.2, -- Correct value range
    NoiseIntensity = 0.1,
    RecoilCompensation = true,
    KeyBind = "MouseButton2"
}

-- Check if player is enemy
local function IsEnemy(player)
    if not Settings.TeamCheck then return true end
    if LocalPlayer.Team and player.Team then
        return LocalPlayer.Team ~= player.Team
    end
    return true
end

-- Check if target is visible
local function IsTargetVisible(target)
    if not target or not target.Character or not target.Character:FindFirstChild("Head") then
        return false
    end
    
    local head = target.Character.Head
    local headPosition = head.Position
    local cameraPosition = Camera.CFrame.Position
    
    local rayDirection = (headPosition - cameraPosition)
    local distance = rayDirection.Magnitude
    rayDirection = rayDirection.Unit * (distance - 0.5)
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, target.Character}
    
    local rayResult = workspace:Raycast(cameraPosition, rayDirection, raycastParams)
    
    if rayResult then
        return false
    end
    
    return true
end

-- Get next target (improved from original code)
local function GetNextTarget()
    local bestTarget = nil
    local bestScore = math.huge
    local mousePosition = UserInputService:GetMouseLocation()
    local currentTime = tick()
    
    if currentTime - AimbotState.LastScanTime < AimbotState.ScanCooldown then
        return AimbotState.CurrentTarget
    end
    AimbotState.LastScanTime = currentTime
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
            local character = player.Character
            local head = character.Head
            local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
            
            if not humanoidRootPart then continue end
            if not IsEnemy(player) then continue end
            
            local headPosition = head.Position
            local distance = (Camera.CFrame.Position - headPosition).Magnitude
            
            if distance > Settings.MaxDistance then continue end
            
            if Settings.VisibilityCheck and not IsTargetVisible(player) then
                continue
            end
            
            local screenPosition, onScreen = Camera:WorldToScreenPoint(headPosition)
            if not onScreen then continue end
            
            local screenDistance = (Vector2.new(screenPosition.X, screenPosition.Y) - mousePosition).Magnitude
            local fovRadius = (Settings.FOV * Camera.ViewportSize.Y) / 180
            
            if screenDistance > fovRadius then continue end
            
            local score = screenDistance * 2 + distance * 0.01
            
            if score < bestScore then
                bestScore = score
                bestTarget = player
            end
        end
    end
    
    return bestTarget
end

-- Predict target position (from working code)
local function PredictTargetPosition(target)
    if not target or not target.Character then return nil end
    
    local character = target.Character
    local head = character:FindFirstChild("Head")
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    
    if not head or not humanoidRootPart then return nil end
    
    local currentPosition = head.Position
    local velocity = humanoidRootPart.Velocity
    
    local distance = (Camera.CFrame.Position - currentPosition).Magnitude
    local timeToTarget = distance / 2800 -- Bullet speed approximation
    
    local predictedPosition = currentPosition + (velocity * timeToTarget * Settings.PredictionStrength)
    
    return predictedPosition
end

-- Get smooth noise for natural movement (from working code)
local function GetSmoothNoise()
    AimbotState.NoiseTime = AimbotState.NoiseTime + 0.03
    local noiseX = math.sin(AimbotState.NoiseTime * 1.2) * Settings.NoiseIntensity
    local noiseY = math.cos(AimbotState.NoiseTime * 1.4) * Settings.NoiseIntensity
    return Vector3.new(noiseX * 0.0003, noiseY * 0.0003, 0)
end

-- Apply recoil compensation (from working code)
local function ApplyRecoilCompensation()
    if Settings.RecoilCompensation then
        local compensationAngle = -0.0008
        AimbotState.RecoilOffset = AimbotState.RecoilOffset:Lerp(CFrame.Angles(compensationAngle, 0, 0), 0.06)
    else
        AimbotState.RecoilOffset = AimbotState.RecoilOffset:Lerp(CFrame.new(), 0.04)
    end
end

-- Main aimbot loop (from working code - FIXED)
local function StartAimbot()
    if AimbotState.Connection then
        AimbotState.Connection:Disconnect()
    end
    
    AimbotState.Connection = RunService.Heartbeat:Connect(function()
        if not Settings.Enabled or not AimbotState.Tracking then return end
        
        if not AimbotState.CurrentTarget or not AimbotState.CurrentTarget.Character or not AimbotState.CurrentTarget.Character:FindFirstChild("Head") then
            AimbotState.CurrentTarget = GetNextTarget()
        end
        
        if AimbotState.CurrentTarget and AimbotState.CurrentTarget.Character and AimbotState.CurrentTarget.Character:FindFirstChild("Head") then
            if Settings.VisibilityCheck and not IsTargetVisible(AimbotState.CurrentTarget) then
                AimbotState.CurrentTarget = GetNextTarget()
                return
            end
            
            local predictedPosition = PredictTargetPosition(AimbotState.CurrentTarget)
            
            if predictedPosition then
                local currentCFrame = Camera.CFrame
                local targetCFrame = CFrame.lookAt(currentCFrame.Position, predictedPosition)
                
                local noise = GetSmoothNoise()
                targetCFrame = targetCFrame + noise
                
                ApplyRecoilCompensation()
                targetCFrame = targetCFrame * AimbotState.RecoilOffset
                
                -- Use correct smoothness value
                Camera.CFrame = currentCFrame:Lerp(targetCFrame, Settings.Smoothness)
            end
        end
    end)
end

-- Stop aimbot
local function StopAimbot()
    if AimbotState.Connection then
        AimbotState.Connection:Disconnect()
        AimbotState.Connection = nil
    end
end

-- Key input handlers
local function setupInputHandlers()
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            AimbotState.Tracking = true
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            AimbotState.Tracking = false
            AimbotState.CurrentTarget = nil
        end
    end)
end

-- Initialize UI
function Aimbot.InitializeUI(Window, settings, saveConfig, bindKey)
    -- Sync settings
    for key, value in pairs(settings) do
        if Settings[key] ~= nil then
            Settings[key] = value
        end
    end
    
    local AimbotTab = Window:AddTab("Aimbot")
    
    AimbotTab:AddLabel("=== Main Settings ===")
    
    AimbotTab:AddSwitch("Enable Aimbot", function(bool)
        Settings.Enabled = bool
        settings.Enabled = bool
        AimbotState.Enabled = bool
        saveConfig()
    end)
    
    AimbotTab:AddSlider("FOV", function(value)
        Settings.FOV = value
        settings.FOV = value
        saveConfig()
    end, {
        ["min"] = 10,
        ["max"] = 360,
        ["default"] = settings.FOV or 90
    })
    
    -- Smoothness - convert from percentage to decimal
    AimbotTab:AddSlider("Smoothness", function(value)
        Settings.Smoothness = value / 100 -- Convert 15 -> 0.15
        settings.Smoothness = value / 100
        saveConfig()
    end, {
        ["min"] = 1,
        ["max"] = 50, -- 1% to 50%
        ["default"] = (settings.Smoothness or 0.15) * 100 -- Convert 0.15 -> 15
    })
    
    AimbotTab:AddSlider("Max Distance", function(value)
        Settings.MaxDistance = value
        settings.MaxDistance = value
        saveConfig()
    end, {
        ["min"] = 100,
        ["max"] = 1000,
        ["default"] = settings.MaxDistance or 400
    })
    
    AimbotTab:AddLabel("=== Checks ===")
    
    AimbotTab:AddSwitch("Team Check", function(bool)
        Settings.TeamCheck = bool
        settings.TeamCheck = bool
        saveConfig()
    end)
    
    AimbotTab:AddSwitch("Visibility Check", function(bool)
        Settings.VisibilityCheck = bool
        settings.VisibilityCheck = bool
        saveConfig()
    end)
    
    AimbotTab:AddLabel("=== Advanced ===")
    
    -- Prediction - convert from percentage to decimal
    AimbotTab:AddSlider("Prediction Strength", function(value)
        Settings.PredictionStrength = value / 100 -- Convert 20 -> 0.2
        settings.PredictionStrength = value / 100
        saveConfig()
    end, {
        ["min"] = 0,
        ["max"] = 100,
        ["default"] = (settings.PredictionStrength or 0.2) * 100 -- Convert 0.2 -> 20
    })
    
    AimbotTab:AddSlider("Noise Intensity", function(value)
        Settings.NoiseIntensity = value / 100
        settings.NoiseIntensity = value / 100
        saveConfig()
    end, {
        ["min"] = 0,
        ["max"] = 50,
        ["default"] = (settings.NoiseIntensity or 0.1) * 100
    })
    
    AimbotTab:AddSwitch("Recoil Compensation", function(bool)
        Settings.RecoilCompensation = bool
        settings.RecoilCompensation = bool
        saveConfig()
    end)
    
    AimbotTab:AddLabel("=== Key Binds ===")
    
    AimbotTab:AddKeybind("Toggle Aimbot Key", function(key)
        settings.KeyBind = key.Name
        saveConfig()
        
        -- Setup toggle keybind
        bindKey("Aimbot_Toggle", key.Name, function(pressed)
            if pressed then
                Settings.Enabled = not Settings.Enabled
                settings.Enabled = Settings.Enabled
                AimbotState.Enabled = Settings.Enabled
                saveConfig()
                print(Settings.Enabled and "✅ Aimbot Enabled" or "❌ Aimbot Disabled")
            end
        end)
    end, {
        ["default"] = Enum.KeyCode[settings.KeyBind and settings.KeyBind:gsub("MouseButton", "") or "F"]
    })
    
    AimbotTab:AddLabel("=== Information ===")
    AimbotTab:AddLabel("Hold Right Mouse Button to aim")
    AimbotTab:AddLabel("Or use keybind to toggle")
    AimbotTab:AddLabel("Target: Head tracking with prediction")
    
    AimbotTab:AddButton("Test Aimbot Settings", function()
        print("🔧 Current Aimbot Settings:")
        print("Enabled:", Settings.Enabled)
        print("FOV:", Settings.FOV)
        print("Smoothness:", Settings.Smoothness)
        print("Max Distance:", Settings.MaxDistance)
        print("Team Check:", Settings.TeamCheck)
        print("Visibility Check:", Settings.VisibilityCheck)
        print("Prediction:", Settings.PredictionStrength)
        print("Recoil Comp:", Settings.RecoilCompensation)
    end)
    
    AimbotTab:AddButton("Reset to Working Values", function()
        -- Set to known working values from user's code
        Settings.Smoothness = 0.15
        Settings.PredictionStrength = 0.2
        Settings.NoiseIntensity = 0.1
        Settings.FOV = 90
        Settings.MaxDistance = 400
        
        settings.Smoothness = 0.15
        settings.PredictionStrength = 0.2
        settings.NoiseIntensity = 0.1
        settings.FOV = 90
        settings.MaxDistance = 400
        
        saveConfig()
        print("✅ Reset to working values!")
    end)
    
    -- Setup input handlers and start aimbot
    setupInputHandlers()
    StartAimbot()
    
    print("🎯 Aimbot module loaded successfully!")
end

-- Cleanup function
function Aimbot.Cleanup()
    StopAimbot()
end

return Aimbot