-- Counter Blox Enhanced - Main Script
-- Working optimized code with all features integrated

local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game.Workspace
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Global variables
_G.CBROLoaded = true
_G.FullBrightEnabled = true

-- Configuration system
local Config = {
    Folder = "CBROConfig",
    File = "CBROConfig/settings.json",
    KeyBindsFile = "CBROConfig/keybinds.json"
}

-- Settings with working values
local AimbotSettings = {
    Enabled = false,
    FOV = 90,
    Smoothness = 0.15,
    MaxDistance = 400,
    TeamCheck = true,
    VisibilityCheck = true,
    PredictionStrength = 0.2,
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

local MovementSettings = {
    WalkSpeed = 16,
    JumpPower = 50,
    Fly = false,
    FlySpeed = 50,
    Noclip = false,
    BunnyHop = false
}

local VisualSettings = {
    FullBright = true,
    EnhancedLighting = false
}

-- Aimbot state
local Tracking = false
local CurrentTarget = nil
local LastScanTime = 0
local ScanCooldown = 0.02
local NoiseTime = 0
local RecoilOffset = CFrame.new()

-- ESP state
local ESPFolder
local ActiveESP = {}

-- Movement state
local FlyEnabled = false
local NoclipEnabled = false
local BunnyHopEnabled = false
local FlyConnection = nil
local NoclipConnection = nil
local BunnyHopConnection = nil
local BodyVelocity = nil

-- Key binds
local KeyBinds = {
    Aimbot = "MouseButton2",
    ESP = "P",
    Fly = "F",
    Noclip = "N",
    BunnyHop = "B",
    FullBright = "L"
}

-- Load/Save configuration
local function loadConfig()
    if not isfolder(Config.Folder) then
        makefolder(Config.Folder)
    end
    
    local success, result = pcall(function()
        return readfile(Config.File)
    end)
    
    if success then
        local loadedSettings = HttpService:JSONDecode(result)
        if loadedSettings.AimbotSettings then
            for k, v in pairs(loadedSettings.AimbotSettings) do
                AimbotSettings[k] = v
            end
        end
        if loadedSettings.ESPSettings then
            for k, v in pairs(loadedSettings.ESPSettings) do
                ESPSettings[k] = v
            end
        end
        if loadedSettings.MovementSettings then
            for k, v in pairs(loadedSettings.MovementSettings) do
                MovementSettings[k] = v
            end
        end
        if loadedSettings.VisualSettings then
            for k, v in pairs(loadedSettings.VisualSettings) do
                VisualSettings[k] = v
            end
        end
        print("✅ Configuration loaded")
    end
end

local function saveConfig()
    if not isfolder(Config.Folder) then
        makefolder(Config.Folder)
    end
    
    local settings = {
        AimbotSettings = AimbotSettings,
        ESPSettings = ESPSettings,
        MovementSettings = MovementSettings,
        VisualSettings = VisualSettings
    }
    
    writefile(Config.File, HttpService:JSONEncode(settings))
end

-- Enhanced Lighting Functions (from working code)
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

-- ESP Functions (from working code)
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

-- Aimbot Functions (from working code)
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

local function GetNextTarget()
    return GetBestTarget()
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
    
    local predictedPosition = currentPosition + (velocity * timeToTarget * AimbotSettings.PredictionStrength)
    
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

-- Movement Functions
local function getCharacter()
    return LocalPlayer.Character
end

local function getHumanoid()
    local character = getCharacter()
    return character and character:FindFirstChild("Humanoid")
end

local function getRootPart()
    local character = getCharacter()
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function setWalkSpeed(speed)
    local humanoid = getHumanoid()
    if humanoid then
        humanoid.WalkSpeed = speed
        MovementSettings.WalkSpeed = speed
    end
end

local function setJumpPower(power)
    local humanoid = getHumanoid()
    if humanoid then
        humanoid.JumpPower = power
        MovementSettings.JumpPower = power
    end
end

local function enableFly()
    local rootPart = getRootPart()
    if not rootPart then return end
    
    FlyEnabled = true
    MovementSettings.Fly = true
    
    if BodyVelocity then
        BodyVelocity:Destroy()
    end
    
    BodyVelocity = Instance.new("BodyVelocity")
    BodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
    BodyVelocity.Velocity = Vector3.new(0, 0, 0)
    BodyVelocity.Parent = rootPart
    
    FlyConnection = RunService.Heartbeat:Connect(function()
        if not FlyEnabled then return end
        
        local rootPart = getRootPart()
        local humanoid = getHumanoid()
        
        if not rootPart or not humanoid or not BodyVelocity then
            return
        end
        
        local camera = workspace.CurrentCamera
        local moveVector = humanoid.MoveDirection
        local lookDirection = camera.CFrame.LookVector
        local rightDirection = camera.CFrame.RightVector
        
        local velocity = Vector3.new(0, 0, 0)
        
        if moveVector.Magnitude > 0 then
            velocity = velocity + (lookDirection * moveVector.Z + rightDirection * moveVector.X) * MovementSettings.FlySpeed
        end
        
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            velocity = velocity + Vector3.new(0, MovementSettings.FlySpeed, 0)
        elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            velocity = velocity + Vector3.new(0, -MovementSettings.FlySpeed, 0)
        end
        
        BodyVelocity.Velocity = velocity
    end)
end

local function disableFly()
    FlyEnabled = false
    MovementSettings.Fly = false
    
    if FlyConnection then
        FlyConnection:Disconnect()
        FlyConnection = nil
    end
    
    if BodyVelocity then
        BodyVelocity:Destroy()
        BodyVelocity = nil
    end
end

local function enableNoclip()
    NoclipEnabled = true
    MovementSettings.Noclip = true
    
    NoclipConnection = RunService.Stepped:Connect(function()
        if not NoclipEnabled then return end
        
        local character = getCharacter()
        if not character then return end
        
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end)
end

local function disableNoclip()
    NoclipEnabled = false
    MovementSettings.Noclip = false
    
    if NoclipConnection then
        NoclipConnection:Disconnect()
        NoclipConnection = nil
    end
    
    local character = getCharacter()
    if character then
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                if part.Name == "HumanoidRootPart" or part.Name == "Head" then
                    part.CanCollide = false
                else
                    part.CanCollide = true
                end
            end
        end
    end
end

local function enableBunnyHop()
    BunnyHopEnabled = true
    MovementSettings.BunnyHop = true
    
    BunnyHopConnection = UserInputService.JumpRequest:Connect(function()
        if not BunnyHopEnabled then return end
        
        local humanoid = getHumanoid()
        if humanoid and humanoid:GetState() ~= Enum.HumanoidStateType.Freefall then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
end

local function disableBunnyHop()
    BunnyHopEnabled = false
    MovementSettings.BunnyHop = false
    
    if BunnyHopConnection then
        BunnyHopConnection:Disconnect()
        BunnyHopConnection = nil
    end
end

-- Input handling
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        Tracking = true
    elseif input.KeyCode == Enum.KeyCode.P then
        ESPSettings.Enabled = not ESPSettings.Enabled
        if not ESPSettings.Enabled then
            for _, highlight in pairs(ActiveESP) do
                if highlight and highlight.Parent then highlight:Destroy() end
            end
            ActiveESP = {}
        end
        print(ESPSettings.Enabled and "✅ ESP Enabled" or "❌ ESP Disabled")
    elseif input.KeyCode == Enum.KeyCode.F then
        if FlyEnabled then
            disableFly()
            print("❌ Fly Disabled")
        else
            enableFly()
            print("✅ Fly Enabled")
        end
    elseif input.KeyCode == Enum.KeyCode.N then
        if NoclipEnabled then
            disableNoclip()
            print("❌ Noclip Disabled")
        else
            enableNoclip()
            print("✅ Noclip Enabled")
        end
    elseif input.KeyCode == Enum.KeyCode.B then
        if BunnyHopEnabled then
            disableBunnyHop()
            print("❌ BunnyHop Disabled")
        else
            enableBunnyHop()
            print("✅ BunnyHop Enabled")
        end
    elseif input.KeyCode == Enum.KeyCode.L then
        _G.FullBrightEnabled = not _G.FullBrightEnabled
        VisualSettings.FullBright = _G.FullBrightEnabled
        if _G.FullBrightEnabled then
            Lighting.Brightness = 2
            Lighting.GlobalShadows = false
            Lighting.Ambient = Color3.fromRGB(178, 178, 178)
            print("✅ Full Bright Enabled")
        else
            Lighting.Brightness = 1
            Lighting.GlobalShadows = true
            Lighting.Ambient = Color3.fromRGB(0, 0, 0)
            print("❌ Full Bright Disabled")
        end
    elseif input.KeyCode == Enum.KeyCode.LeftShift then
        local humanoid = getHumanoid()
        if humanoid then
            if humanoid.WalkSpeed == 16 then
                setWalkSpeed(50)
                print("🏃 Speed Boost Enabled")
            else
                setWalkSpeed(16)
                print("🚶 Normal Speed")
            end
        end
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        Tracking = false
        CurrentTarget = nil
    end
end)

-- Main aimbot loop (from working code)
RunService.Heartbeat:Connect(function()
    if not AimbotSettings.Enabled or not Tracking then return end
    
    if not CurrentTarget or not CurrentTarget.Character or not CurrentTarget.Character:FindFirstChild("Head") then
        CurrentTarget = GetBestTarget()
    end
    
    if CurrentTarget and CurrentTarget.Character and CurrentTarget.Character:FindFirstChild("Head") then
        if AimbotSettings.VisibilityCheck and not IsTargetVisible(CurrentTarget) then
            CurrentTarget = GetNextTarget()
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
            
            local smoothness = AimbotSettings.Smoothness
            
            Camera.CFrame = currentCFrame:Lerp(targetCFrame, smoothness)
        end
    end
end)

-- ESP loop (from working code)
spawn(function()
    CreateESPFolder()
    while _G.CBROLoaded do
        if ESPSettings.Enabled then
            UpdateESP()
            CleanupESP()
        end
        wait(0.2)
    end
end)

-- Player events
Players.PlayerRemoving:Connect(function(player)
    if ActiveESP[player.Name] then
        if ActiveESP[player.Name].Parent then
            ActiveESP[player.Name]:Destroy()
        end
        ActiveESP[player.Name] = nil
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    wait(1)
    
    -- Restore movement settings
    if MovementSettings.WalkSpeed ~= 16 then
        setWalkSpeed(MovementSettings.WalkSpeed)
    end
    
    if MovementSettings.JumpPower ~= 50 then
        setJumpPower(MovementSettings.JumpPower)
    end
    
    if MovementSettings.Fly then
        enableFly()
    end
    
    if MovementSettings.Noclip then
        enableNoclip()
    end
    
    if MovementSettings.BunnyHop then
        enableBunnyHop()
    end
end)

-- Initialize UI
local function initializeUI()
    local library = loadstring(game:HttpGet('https://raw.githubusercontent.com/Ivan3056/Roblox/main/Library.lua'))()
    if not library then
        error("Failed to load UI library")
    end
    
    local Window = library:AddWindow("Counter Blox Enhanced", {
        main_color = Color3.fromRGB(41, 74, 122),
        min_size = Vector2.new(500, 600),
        toggle_key = Enum.KeyCode.RightShift,
        can_resize = true,
    })
    
    -- Aimbot Tab
    local AimbotTab = Window:AddTab("Aimbot")
    
    AimbotTab:AddLabel("=== Main Settings ===")
    
    AimbotTab:AddSwitch("Enable Aimbot", function(bool)
        AimbotSettings.Enabled = bool
        saveConfig()
    end)
    
    AimbotTab:AddSlider("FOV", function(value)
        AimbotSettings.FOV = value
        saveConfig()
    end, {
        ["min"] = 10,
        ["max"] = 360,
        ["default"] = AimbotSettings.FOV
    })
    
    AimbotTab:AddSlider("Smoothness", function(value)
        AimbotSettings.Smoothness = value / 100
        saveConfig()
    end, {
        ["min"] = 1,
        ["max"] = 50,
        ["default"] = AimbotSettings.Smoothness * 100
    })
    
    AimbotTab:AddSlider("Max Distance", function(value)
        AimbotSettings.MaxDistance = value
        saveConfig()
    end, {
        ["min"] = 100,
        ["max"] = 1000,
        ["default"] = AimbotSettings.MaxDistance
    })
    
    AimbotTab:AddLabel("=== Checks ===")
    
    AimbotTab:AddSwitch("Team Check", function(bool)
        AimbotSettings.TeamCheck = bool
        saveConfig()
    end)
    
    AimbotTab:AddSwitch("Visibility Check", function(bool)
        AimbotSettings.VisibilityCheck = bool
        saveConfig()
    end)
    
    AimbotTab:AddLabel("=== Advanced ===")
    
    AimbotTab:AddSlider("Prediction Strength", function(value)
        AimbotSettings.PredictionStrength = value / 100
        saveConfig()
    end, {
        ["min"] = 0,
        ["max"] = 100,
        ["default"] = AimbotSettings.PredictionStrength * 100
    })
    
    AimbotTab:AddSwitch("Recoil Compensation", function(bool)
        AimbotSettings.RecoilCompensation = bool
        saveConfig()
    end)
    
    -- ESP Tab
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
        saveConfig()
    end)
    
    ESPTab:AddLabel("Enemy Color:")
    ESPTab:AddColorPicker(function(color)
        ESPSettings.EnemyColor = color
        if ESPSettings.Enabled then
            UpdateESP()
        end
        saveConfig()
    end)
    
    ESPTab:AddLabel("Team Color:")
    ESPTab:AddColorPicker(function(color)
        ESPSettings.TeamColor = color
        if ESPSettings.Enabled then
            UpdateESP()
        end
        saveConfig()
    end)
    
    -- Movement Tab
    local MovementTab = Window:AddTab("Movement")
    
    MovementTab:AddLabel("=== Speed Settings ===")
    
    MovementTab:AddSlider("Walk Speed", function(value)
        setWalkSpeed(value)
        saveConfig()
    end, {
        ["min"] = 16,
        ["max"] = 100,
        ["default"] = MovementSettings.WalkSpeed
    })
    
    MovementTab:AddSlider("Jump Power", function(value)
        setJumpPower(value)
        saveConfig()
    end, {
        ["min"] = 50,
        ["max"] = 200,
        ["default"] = MovementSettings.JumpPower
    })
    
    MovementTab:AddLabel("=== Movement Abilities ===")
    
    MovementTab:AddSwitch("Fly", function(bool)
        if bool then
            enableFly()
        else
            disableFly()
        end
        saveConfig()
    end)
    
    MovementTab:AddSlider("Fly Speed", function(value)
        MovementSettings.FlySpeed = value
        saveConfig()
    end, {
        ["min"] = 10,
        ["max"] = 200,
        ["default"] = MovementSettings.FlySpeed
    })
    
    MovementTab:AddSwitch("Noclip", function(bool)
        if bool then
            enableNoclip()
        else
            disableNoclip()
        end
        saveConfig()
    end)
    
    MovementTab:AddSwitch("Bunny Hop", function(bool)
        if bool then
            enableBunnyHop()
        else
            disableBunnyHop()
        end
        saveConfig()
    end)
    
    -- Visuals Tab
    local VisualsTab = Window:AddTab("Visuals")
    
    VisualsTab:AddLabel("=== Lighting ===")
    
    VisualsTab:AddSwitch("Full Bright", function(bool)
        _G.FullBrightEnabled = bool
        VisualSettings.FullBright = bool
        if bool then
            Lighting.Brightness = 2
            Lighting.GlobalShadows = false
            Lighting.Ambient = Color3.fromRGB(178, 178, 178)
        else
            Lighting.Brightness = 1
            Lighting.GlobalShadows = true
            Lighting.Ambient = Color3.fromRGB(0, 0, 0)
        end
        saveConfig()
    end)
    
    VisualsTab:AddButton("Apply Enhanced Lighting", function()
        SetupEnhancedLighting()
        VisualSettings.EnhancedLighting = true
        saveConfig()
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
        
        VisualSettings.EnhancedLighting = false
        saveConfig()
    end)
    
    -- Settings Tab
    local SettingsTab = Window:AddTab("Settings")
    
    SettingsTab:AddLabel("=== Configuration ===")
    
    SettingsTab:AddButton("Save Settings", function()
        saveConfig()
        print("✅ Settings saved!")
    end)
    
    SettingsTab:AddButton("Reset All", function()
        AimbotSettings.Enabled = false
        ESPSettings.Enabled = false
        disableFly()
        disableNoclip()
        disableBunnyHop()
        setWalkSpeed(16)
        setJumpPower(50)
        saveConfig()
        print("✅ All settings reset!")
    end)
    
    SettingsTab:AddLabel("=== Controls ===")
    SettingsTab:AddLabel("Right Mouse: Aimbot")
    SettingsTab:AddLabel("P: Toggle ESP")
    SettingsTab:AddLabel("F: Toggle Fly")
    SettingsTab:AddLabel("N: Toggle Noclip")
    SettingsTab:AddLabel("B: Toggle Bunny Hop")
    SettingsTab:AddLabel("L: Toggle Full Bright")
    SettingsTab:AddLabel("Shift: Speed Boost")
    SettingsTab:AddLabel("RightShift: Toggle UI")
    
    AimbotTab:Show()
    library:FormatWindows()
    
    print("🎯 Counter Blox Enhanced loaded successfully!")
end

-- Initialize everything
local function initialize()
    loadConfig()
    initializeUI()
    
    -- Apply saved visual settings
    if VisualSettings.FullBright then
        _G.FullBrightEnabled = true
        Lighting.Brightness = 2
        Lighting.GlobalShadows = false
        Lighting.Ambient = Color3.fromRGB(178, 178, 178)
    end
    
    if VisualSettings.EnhancedLighting then
        SetupEnhancedLighting()
    end
    
    -- Setup lighting monitoring
    MonitorLighting()
    MonitorSky()
    
    -- Auto-save every 30 seconds
    spawn(function()
        while _G.CBROLoaded do
            wait(30)
            saveConfig()
        end
    end)
    
    print("✅ All systems initialized!")
end

-- Start the script
initialize()