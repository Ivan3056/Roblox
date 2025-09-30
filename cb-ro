-- Загрузка библиотеки
local library = loadstring(game:HttpGet('https://raw.githubusercontent.com/Ivan3056/Roblox/refs/heads/main/Library.lua'))()

local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game.Workspace
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

_G.FullBrightEnabled = true

local AimbotSettings = {
    Enabled = false,
    FOV = 90,
    Smoothness = 15,
    MaxDistance = 400,
    TeamCheck = true,
    VisibilityCheck = true,
    PredictionStrength = 20,
    NoiseIntensity = 0.1,
    RecoilCompensation = true
}

local ESPSettings = {
    Enabled = false,
    EnemyColor = Color3.fromRGB(255, 100, 100),
    TeamColor = Color3.fromRGB(100, 255, 100),
    Thickness = 2,
    Transparency = 0
}

local Tracking = false
local CurrentTarget = nil
local LastScanTime = 0
local ScanCooldown = 0.02
local NoiseTime = 0
local RecoilOffset = CFrame.new()
local ESPFolder
local ActiveESP = {}

-- Функции освещения
local function SetupEnhancedLighting()
    local atmosphere = Lighting:FindFirstChild("Atmosphere")
    if not atmosphere then
        atmosphere = Instance.new("Atmosphere")
        atmosphere.Parent = Lighting
    end
    
    local sky = Lighting:FindFirstChild("Sky")
    if not sky then
        sky = Instance.new("Sky")
        sky.Parent = Lighting
        sky.SkyboxBk = "rbxassetid://159454299"
        sky.SkyboxDn = "rbxassetid://159454296" 
        sky.SkyboxFt = "rbxassetid://159454293"
        sky.SkyboxLf = "rbxassetid://159454286"
        sky.SkyboxRt = "rbxassetid://159454300"
        sky.SkyboxUp = "rbxassetid://159454288"
    end
    
    if _G.FullBrightEnabled then
        Lighting.Brightness = 2
        Lighting.GlobalShadows = false
        Lighting.Ambient = Color3.fromRGB(178, 178, 178)
    end
    
    Lighting.TimeOfDay = "23:00:00" 
    Lighting.OutdoorAmbient = Color3.fromRGB(60, 60, 100)
    Lighting.FogEnd = 1500
    Lighting.FogStart = 200
    Lighting.FogColor = Color3.fromRGB(100, 80, 140)
    
    atmosphere.Density = 0.15
    atmosphere.Offset = 0.1
    atmosphere.Color = Color3.fromRGB(150, 120, 200)
    atmosphere.Decay = Color3.fromRGB(120, 100, 160)
    atmosphere.Glare = 0.05
    atmosphere.Haze = 0.8
    
    sky.MoonAngularSize = 12
    sky.StarCount = 3000
    sky.SunAngularSize = 8
end

local function MonitorLighting()
    Lighting.Changed:Connect(function(property)
        if _G.FullBrightEnabled then
            if property == "Brightness" and Lighting.Brightness < 2 then
                Lighting.Brightness = 2
            elseif property == "GlobalShadows" and Lighting.GlobalShadows then
                Lighting.GlobalShadows = false
            elseif property == "Ambient" and Lighting.Ambient ~= Color3.fromRGB(178, 178, 178) then
                Lighting.Ambient = Color3.fromRGB(178, 178, 178)
            end
        end
    end)
end

local function MonitorSky()
    Lighting.ChildRemoved:Connect(function(child)
        if child:IsA("Sky") then
            wait(0.1)
            SetupEnhancedLighting()
        end
    end)
end

-- Функции ESP
local function CreateESPFolder()
    if ESPFolder then ESPFolder:Destroy() end
    ESPFolder = Instance.new("Folder")
    ESPFolder.Name = "GlowESP"
    ESPFolder.Parent = Workspace
end

local function IsEnemy(player)
    if not AimbotSettings.TeamCheck then return true end
    if LocalPlayer.Team and player.Team then
        return LocalPlayer.Team ~= player.Team
    end
    return true
end

local function CreateGlowESP(player)
    if not ESPSettings.Enabled or not player or not player.Character then return end
    
    local character = player.Character
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    local espId = player.Name
    if ActiveESP[espId] then
        ActiveESP[espId]:Destroy()
    end
    
    local isEnemyPlayer = IsEnemy(player)
    local espColor = isEnemyPlayer and ESPSettings.EnemyColor or ESPSettings.TeamColor
    
    local highlight = Instance.new("Highlight")
    highlight.Name = player.Name .. "_ESP"
    highlight.Adornee = character
    highlight.FillColor = espColor
    highlight.FillTransparency = 0.7
    highlight.OutlineColor = espColor
    highlight.OutlineTransparency = ESPSettings.Transparency
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = ESPFolder
    
    ActiveESP[espId] = highlight
end

local function UpdateESP()
    if not ESPSettings.Enabled then return end
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            CreateGlowESP(player)
        end
    end
end

local function CleanupESP()
    for playerId, highlight in pairs(ActiveESP) do
        local player = Players:FindFirstChild(playerId)
        if not player or not player.Character then
            if highlight and highlight.Parent then
                highlight:Destroy()
            end
            ActiveESP[playerId] = nil
        end
    end
end

-- Функции Aimbot
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
    
    local rayResult = Workspace:Raycast(cameraPosition, rayDirection, raycastParams)
    
    if rayResult then
        return false
    end
    
    return true
end

local function GetBestTarget()
    local bestTarget = nil
    local bestScore = math.huge
    local mousePosition = UserInputService:GetMouseLocation()
    local currentTime = tick()
    
    if currentTime - LastScanTime < ScanCooldown then
        return CurrentTarget
    end
    LastScanTime = currentTime
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
            local character = player.Character
            local head = character.Head
            local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
            
            if not humanoidRootPart then continue end
            if not IsEnemy(player) then continue end
            
            local headPosition = head.Position
            local distance = (Camera.CFrame.Position - headPosition).Magnitude
            
            if distance > AimbotSettings.MaxDistance then continue end
            
            if AimbotSettings.VisibilityCheck and not IsTargetVisible(player) then
                continue
            end
            
            local screenPosition, onScreen = Camera:WorldToScreenPoint(headPosition)
            if not onScreen then continue end
            
            local screenDistance = (Vector2.new(screenPosition.X, screenPosition.Y) - mousePosition).Magnitude
            local fovRadius = (AimbotSettings.FOV * Camera.ViewportSize.Y) / 180
            
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

local function PredictTargetPosition(target)
    if not target or not target.Character then return nil end
    
    local character = target.Character
    local head = character:FindFirstChild("Head")
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    
    if not head or not humanoidRootPart then return nil end
    
    local currentPosition = head.Position
    local velocity = humanoidRootPart.Velocity
    
    local distance = (Camera.CFrame.Position - currentPosition).Magnitude
    local timeToTarget = distance / 2800
    
    local predictedPosition = currentPosition + (velocity * timeToTarget * (AimbotSettings.PredictionStrength / 100))
    
    return predictedPosition
end

local function GetSmoothNoise()
    NoiseTime = NoiseTime + 0.03
    local noiseX = math.sin(NoiseTime * 1.2) * AimbotSettings.NoiseIntensity
    local noiseY = math.cos(NoiseTime * 1.4) * AimbotSettings.NoiseIntensity
    return Vector3.new(noiseX * 0.0003, noiseY * 0.0003, 0)
end

local function ApplyRecoilCompensation()
    if AimbotSettings.RecoilCompensation then
        local compensationAngle = -0.0008
        RecoilOffset = RecoilOffset:Lerp(CFrame.Angles(compensationAngle, 0, 0), 0.06)
    else
        RecoilOffset = RecoilOffset:Lerp(CFrame.new(), 0.04)
    end
end

-- Создание UI
local Window = library:AddWindow("Combat Hub", {
    main_color = Color3.fromRGB(41, 74, 122),
    min_size = Vector2.new(450, 550),
    toggle_key = Enum.KeyCode.RightShift,
    can_resize = true,
})

-- Вкладка Aimbot
local AimbotTab = Window:AddTab("Aimbot")

AimbotTab:AddLabel("=== Main Settings ===")

AimbotTab:AddSwitch("Enable Aimbot", function(bool)
    AimbotSettings.Enabled = bool
end)

AimbotTab:AddSlider("FOV", function(value)
    AimbotSettings.FOV = value
end, {
    ["min"] = 10,
    ["max"] = 360,
})

AimbotTab:AddSlider("Smoothness", function(value)
    AimbotSettings.Smoothness = value
end, {
    ["min"] = 1,
    ["max"] = 100,
})

AimbotTab:AddSlider("Max Distance", function(value)
    AimbotSettings.MaxDistance = value
end, {
    ["min"] = 100,
    ["max"] = 1000,
})

AimbotTab:AddLabel("=== Checks ===")

local TeamCheckSwitch = AimbotTab:AddSwitch("Team Check", function(bool)
    AimbotSettings.TeamCheck = bool
end)

local VisCheckSwitch = AimbotTab:AddSwitch("Visibility Check", function(bool)
    AimbotSettings.VisibilityCheck = bool
end)

AimbotTab:AddLabel("=== Advanced ===")

AimbotTab:AddSlider("Prediction Strength", function(value)
    AimbotSettings.PredictionStrength = value
end, {
    ["min"] = 0,
    ["max"] = 100,
})

AimbotTab:AddSwitch("Recoil Compensation", function(bool)
    AimbotSettings.RecoilCompensation = bool
end)

AimbotTab:AddLabel("Hold Right Mouse Button to aim")

-- Вкладка ESP
local ESPTab = Window:AddTab("ESP")

ESPTab:AddLabel("=== ESP Settings ===")

ESPTab:AddSwitch("Enable ESP", function(bool)
    ESPSettings.Enabled = bool
    if not bool then
        for _, highlight in pairs(ActiveESP) do
            if highlight and highlight.Parent then highlight:Destroy() end
        end
        ActiveESP = {}
    end
end)

ESPTab:AddLabel("Enemy Color:")
ESPTab:AddColorPicker(function(color)
    ESPSettings.EnemyColor = color
    if ESPSettings.Enabled then
        UpdateESP()
    end
end)

ESPTab:AddLabel("Team Color:")
ESPTab:AddColorPicker(function(color)
    ESPSettings.TeamColor = color
    if ESPSettings.Enabled then
        UpdateESP()
    end
end)

ESPTab:AddButton("Refresh ESP", function()
    CleanupESP()
    UpdateESP()
end)

-- Вкладка Visuals
local VisualsTab = Window:AddTab("Visuals")

VisualsTab:AddLabel("=== Lighting ===")

local FullBrightSwitch = VisualsTab:AddSwitch("Full Bright", function(bool)
    _G.FullBrightEnabled = bool
    if bool then
        Lighting.Brightness = 2
        Lighting.GlobalShadows = false
        Lighting.Ambient = Color3.fromRGB(178, 178, 178)
    else
        Lighting.Brightness = 1
        Lighting.GlobalShadows = true
        Lighting.Ambient = Color3.fromRGB(0, 0, 0)
    end
end)

VisualsTab:AddButton("Apply Enhanced Lighting", function()
    SetupEnhancedLighting()
end)

VisualsTab:AddButton("Reset Lighting", function()
    Lighting.Brightness = 1
    Lighting.GlobalShadows = true
    Lighting.Ambient = Color3.fromRGB(0, 0, 0)
    Lighting.TimeOfDay = "14:00:00"
    Lighting.FogEnd = 100000
    Lighting.FogStart = 0
    
    local atmosphere = Lighting:FindFirstChild("Atmosphere")
    if atmosphere then atmosphere:Destroy() end
    
    local sky = Lighting:FindFirstChild("Sky")
    if sky then sky:Destroy() end
end)

-- Вкладка Info
local InfoTab = Window:AddTab("Info")

InfoTab:AddLabel("=== Controls ===")
InfoTab:AddLabel("Right Mouse: Aim Lock")
InfoTab:AddLabel("RightShift: Toggle UI")
InfoTab:AddLabel("")
InfoTab:AddLabel("=== Features ===")
InfoTab:AddLabel("• Advanced Aimbot")
InfoTab:AddLabel("• ESP with Highlights")
InfoTab:AddLabel("• Enhanced Lighting")
InfoTab:AddLabel("• Prediction System")

-- Показываем первую вкладку
AimbotTab:Show()
library:FormatWindows()

-- Основная логика
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        Tracking = true
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        Tracking = false
        CurrentTarget = nil
    end
end)

RunService.Heartbeat:Connect(function()
    if not AimbotSettings.Enabled or not Tracking then return end
    
    if not CurrentTarget or not CurrentTarget.Character or not CurrentTarget.Character:FindFirstChild("Head") then
        CurrentTarget = GetBestTarget()
    end
    
    if CurrentTarget and CurrentTarget.Character and CurrentTarget.Character:FindFirstChild("Head") then
        if AimbotSettings.VisibilityCheck and not IsTargetVisible(CurrentTarget) then
            CurrentTarget = GetBestTarget()
            return
        end
        
        local predictedPosition = PredictTargetPosition(CurrentTarget)
        
        if predictedPosition then
            local currentCFrame = Camera.CFrame
            local targetCFrame = CFrame.lookAt(currentCFrame.Position, predictedPosition)
            
            local noise = GetSmoothNoise()
            targetCFrame = targetCFrame + noise
            
            ApplyRecoilCompensation()
            targetCFrame = targetCFrame * RecoilOffset
            
            Camera.CFrame = currentCFrame:Lerp(targetCFrame, AimbotSettings.Smoothness / 100)
        end
    end
end)

spawn(function()
    CreateESPFolder()
    while true do
        if ESPSettings.Enabled then
            UpdateESP()
            CleanupESP()
        end
        wait(0.2)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    if ActiveESP[player.Name] then
        if ActiveESP[player.Name].Parent then
            ActiveESP[player.Name]:Destroy()
        end
        ActiveESP[player.Name] = nil
    end
end)

SetupEnhancedLighting()
MonitorLighting()
MonitorSky()

print("Combat Hub loaded successfully!")
