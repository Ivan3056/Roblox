-- ESP Module for Counter Blox Enhanced
-- Highlight-based ESP system

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game.Workspace
local LocalPlayer = Players.LocalPlayer

local ESP = {}

-- ESP state
local ESPState = {
    Enabled = false,
    ESPFolder = nil,
    ActiveESP = {},
    UpdateConnection = nil
}

-- Settings
local Settings = {
    Enabled = false,
    EnemyColor = Color3.fromRGB(255, 100, 100),
    TeamColor = Color3.fromRGB(100, 255, 100),
    Thickness = 2,
    Transparency = 0,
    KeyBind = "P"
}

-- Create ESP folder
local function CreateESPFolder()
    if ESPState.ESPFolder then 
        ESPState.ESPFolder:Destroy() 
    end
    
    ESPState.ESPFolder = Instance.new("Folder")
    ESPState.ESPFolder.Name = "CBROGlowESP"
    ESPState.ESPFolder.Parent = Workspace
end

-- Check if player is enemy
local function IsEnemy(player)
    if LocalPlayer.Team and player.Team then
        return LocalPlayer.Team ~= player.Team
    end
    return true
end

-- Create glow ESP for player
local function CreateGlowESP(player)
    if not Settings.Enabled or not player or not player.Character then return end
    
    local character = player.Character
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    local espId = player.Name
    if ESPState.ActiveESP[espId] then
        ESPState.ActiveESP[espId]:Destroy()
    end
    
    local isEnemyPlayer = IsEnemy(player)
    local espColor = isEnemyPlayer and Settings.EnemyColor or Settings.TeamColor
    
    local highlight = Instance.new("Highlight")
    highlight.Name = player.Name .. "_ESP"
    highlight.Adornee = character
    highlight.FillColor = espColor
    highlight.FillTransparency = 0.7
    highlight.OutlineColor = espColor
    highlight.OutlineTransparency = Settings.Transparency
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = ESPState.ESPFolder
    
    ESPState.ActiveESP[espId] = highlight
end

-- Update ESP for all players
local function UpdateESP()
    if not Settings.Enabled then return end
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            CreateGlowESP(player)
        end
    end
end

-- Cleanup ESP
local function CleanupESP()
    for playerId, highlight in pairs(ESPState.ActiveESP) do
        local player = Players:FindFirstChild(playerId)
        if not player or not player.Character then
            if highlight and highlight.Parent then
                highlight:Destroy()
            end
            ESPState.ActiveESP[playerId] = nil
        end
    end
end

-- Start ESP system
local function StartESP()
    if ESPState.UpdateConnection then
        ESPState.UpdateConnection:Disconnect()
    end
    
    CreateESPFolder()
    
    ESPState.UpdateConnection = spawn(function()
        while Settings.Enabled do
            if Settings.Enabled then
                UpdateESP()
                CleanupESP()
            end
            wait(0.2)
        end
    end)
end

-- Stop ESP system
local function StopESP()
    Settings.Enabled = false
    
    if ESPState.UpdateConnection then
        ESPState.UpdateConnection:Disconnect()
        ESPState.UpdateConnection = nil
    end
    
    for _, highlight in pairs(ESPState.ActiveESP) do
        if highlight and highlight.Parent then 
            highlight:Destroy() 
        end
    end
    ESPState.ActiveESP = {}
    
    if ESPState.ESPFolder then
        ESPState.ESPFolder:Destroy()
    end
end

-- Initialize UI
function ESP.InitializeUI(Window, settings, saveConfig, bindKey)
    -- Sync settings
    for key, value in pairs(settings) do
        if Settings[key] ~= nil then
            if key == "EnemyColor" then
                Settings[key] = Color3.fromRGB(value[1], value[2], value[3])
            elseif key == "TeamColor" then
                Settings[key] = Color3.fromRGB(value[1], value[2], value[3])
            else
                Settings[key] = value
            end
        end
    end
    
    local ESPTab = Window:AddTab("ESP")
    
    ESPTab:AddLabel("=== ESP Settings ===")
    
    ESPTab:AddSwitch("Enable ESP", function(bool)
        Settings.Enabled = bool
        settings.Enabled = bool
        
        if bool then
            StartESP()
        else
            StopESP()
        end
        
        saveConfig()
    end)
    
    ESPTab:AddLabel("=== Colors ===")
    
    ESPTab:AddLabel("Enemy Color:")
    ESPTab:AddColorPicker(function(color)
        Settings.EnemyColor = color
        settings.EnemyColor = {color.R * 255, color.G * 255, color.B * 255}
        saveConfig()
        
        if Settings.Enabled then
            UpdateESP()
        end
    end)
    
    ESPTab:AddLabel("Team Color:")
    ESPTab:AddColorPicker(function(color)
        Settings.TeamColor = color
        settings.TeamColor = {color.R * 255, color.G * 255, color.B * 255}
        saveConfig()
        
        if Settings.Enabled then
            UpdateESP()
        end
    end)
    
    ESPTab:AddLabel("=== Appearance ===")
    
    ESPTab:AddSlider("Outline Transparency", function(value)
        Settings.Transparency = value / 100
        settings.Transparency = value / 100
        saveConfig()
        
        -- Update existing ESP
        for _, highlight in pairs(ESPState.ActiveESP) do
            if highlight then
                highlight.OutlineTransparency = Settings.Transparency
            end
        end
    end, {
        ["min"] = 0,
        ["max"] = 100,
        ["default"] = (settings.Transparency or 0) * 100
    })
    
    ESPTab:AddLabel("=== Key Binds ===")
    
    ESPTab:AddKeybind("Toggle ESP Key", function(key)
        settings.KeyBind = key.Name
        saveConfig()
        
        -- Setup toggle keybind
        bindKey("ESP_Toggle", key.Name, function(pressed)
            if pressed then
                Settings.Enabled = not Settings.Enabled
                settings.Enabled = Settings.Enabled
                
                if Settings.Enabled then
                    StartESP()
                else
                    StopESP()
                end
                
                saveConfig()
                print(Settings.Enabled and "✅ ESP Enabled" or "❌ ESP Disabled")
            end
        end)
    end, {
        ["default"] = Enum.KeyCode[settings.KeyBind or "P"]
    })
    
    ESPTab:AddLabel("=== Controls ===")
    
    ESPTab:AddButton("Refresh ESP", function()
        CleanupESP()
        if Settings.Enabled then
            UpdateESP()
        end
        print("✅ ESP refreshed!")
    end)
    
    ESPTab:AddButton("Test ESP", function()
        print("🔧 Current ESP Settings:")
        print("Enabled:", Settings.Enabled)
        print("Enemy Color:", Settings.EnemyColor)
        print("Team Color:", Settings.TeamColor)
        print("Transparency:", Settings.Transparency)
        print("Active ESP Count:", #ESPState.ActiveESP)
    end)
    
    ESPTab:AddLabel("=== Information ===")
    ESPTab:AddLabel("Highlights players through walls")
    ESPTab:AddLabel("Red = Enemies, Green = Team")
    ESPTab:AddLabel("Auto-updates when players spawn")
    
    print("👁️ ESP module loaded successfully!")
end

-- Handle player events
Players.PlayerRemoving:Connect(function(player)
    if ESPState.ActiveESP[player.Name] then
        if ESPState.ActiveESP[player.Name].Parent then
            ESPState.ActiveESP[player.Name]:Destroy()
        end
        ESPState.ActiveESP[player.Name] = nil
    end
end)

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        wait(1) -- Wait for character to fully load
        if Settings.Enabled then
            CreateGlowESP(player)
        end
    end)
end)

-- Handle existing players
for _, player in pairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        player.CharacterAdded:Connect(function()
            wait(1)
            if Settings.Enabled then
                CreateGlowESP(player)
            end
        end)
    end
end

-- Cleanup function
function ESP.Cleanup()
    StopESP()
end

return ESP