-- Counter Blox Enhanced - Main Script
-- Modular structure with configuration system

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

-- Global variables
_G.CBROLoaded = true
_G.CBROSettings = _G.CBROSettings or {}

-- Configuration system
local Config = {
    Folder = "CBROConfig",
    File = "CBROConfig/settings.json",
    KeyBindsFile = "CBROConfig/keybinds.json"
}

-- Default settings
local DefaultSettings = {
    Aimbot = {
        Enabled = false,
        FOV = 90,
        Smoothness = 0.15,
        MaxDistance = 400,
        TeamCheck = true,
        VisibilityCheck = true,
        PredictionStrength = 0.2,
        RecoilCompensation = true,
        KeyBind = "MouseButton2"
    },
    ESP = {
        Enabled = false,
        EnemyColor = {255, 100, 100},
        TeamColor = {100, 255, 100},
        Thickness = 2,
        Transparency = 0,
        KeyBind = "P"
    },
    Visuals = {
        FullBright = false,
        EnhancedLighting = false,
        KeyBind = "L"
    },
    Movement = {
        WalkSpeed = 16,
        JumpPower = 50,
        Fly = false,
        FlySpeed = 50,
        Noclip = false,
        BunnyHop = false,
        KeyBinds = {
            Fly = "F",
            Noclip = "N",
            BunnyHop = "B",
            WalkSpeed = "LeftShift"
        }
    },
    UI = {
        Theme = "Dark",
        ToggleKey = "RightShift"
    }
}

-- Load configuration
local function loadConfig()
    if not isfolder(Config.Folder) then
        makefolder(Config.Folder)
    end
    
    local success, result = pcall(function()
        return readfile(Config.File)
    end)
    
    if success then
        local loadedSettings = HttpService:JSONDecode(result)
        -- Merge with defaults
        for category, settings in pairs(DefaultSettings) do
            if loadedSettings[category] then
                for key, value in pairs(settings) do
                    if loadedSettings[category][key] ~= nil then
                        DefaultSettings[category][key] = loadedSettings[category][key]
                    end
                end
            end
        end
    end
    
    _G.CBROSettings = DefaultSettings
end

-- Save configuration
local function saveConfig()
    if not isfolder(Config.Folder) then
        makefolder(Config.Folder)
    end
    
    writefile(Config.File, HttpService:JSONEncode(_G.CBROSettings))
end

-- Key binding system
local KeyBinds = {}
local function loadKeyBinds()
    local success, result = pcall(function()
        return readfile(Config.KeyBindsFile)
    end)
    
    if success then
        KeyBinds = HttpService:JSONDecode(result)
    end
end

local function saveKeyBinds()
    writefile(Config.KeyBindsFile, HttpService:JSONEncode(KeyBinds))
end

local function bindKey(action, key, callback)
    KeyBinds[action] = {
        Key = key,
        Callback = callback
    }
    saveKeyBinds()
end

-- Key input handler
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    local keyName = input.KeyCode.Name
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        keyName = "MouseButton1"
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
        keyName = "MouseButton2"
    end
    
    for action, bind in pairs(KeyBinds) do
        if bind.Key == keyName and bind.Callback then
            bind.Callback(true)
        end
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    local keyName = input.KeyCode.Name
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        keyName = "MouseButton1"
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
        keyName = "MouseButton2"
    end
    
    for action, bind in pairs(KeyBinds) do
        if bind.Key == keyName and bind.Callback then
            bind.Callback(false)
        end
    end
end)

-- Load modules function
local function loadModule(moduleName)
    local success, module = pcall(function()
        return loadstring(game:HttpGet('https://raw.githubusercontent.com/Ivan3056/Roblox/main/cbro/' .. moduleName .. '.lua'))()
    end)
    
    if success then
        print("✅ Loaded module: " .. moduleName)
        return module
    else
        warn("❌ Failed to load module: " .. moduleName .. " - " .. tostring(module))
        return nil
    end
end

-- Initialize function
local function initialize()
    print("🚀 Counter Blox Enhanced - Initializing...")
    
    -- Load configuration
    loadConfig()
    loadKeyBinds()
    
    -- Load UI library
    print("🎨 Loading UI library...")
    local library = loadstring(game:HttpGet('https://raw.githubusercontent.com/Ivan3056/Roblox/main/Library.lua'))()
    if not library then
        error("Failed to load UI library")
    end
    
    -- Load modules
    print("🔧 Loading modules...")
    
    local modules = {
        Movement = loadModule("movement"),
        Aimbot = loadModule("aimbot"),
        ESP = loadModule("esp"),
        Visuals = loadModule("visuals")
    }
    
    -- Create main window
    local Window = library:AddWindow("Counter Blox Enhanced", {
        main_color = Color3.fromRGB(41, 74, 122),
        min_size = Vector2.new(500, 600),
        toggle_key = Enum.KeyCode[_G.CBROSettings.UI.ToggleKey],
        can_resize = true,
    })
    
    -- Initialize modules with UI
    if modules.Movement then
        modules.Movement.InitializeUI(Window, _G.CBROSettings.Movement, saveConfig, bindKey)
    end
    
    if modules.Aimbot then
        modules.Aimbot.InitializeUI(Window, _G.CBROSettings.Aimbot, saveConfig, bindKey)
    end
    
    if modules.ESP then
        modules.ESP.InitializeUI(Window, _G.CBROSettings.ESP, saveConfig, bindKey)
    end
    
    if modules.Visuals then
        modules.Visuals.InitializeUI(Window, _G.CBROSettings.Visuals, saveConfig, bindKey)
    end
    
    -- Settings tab
    local SettingsTab = Window:AddTab("Settings")
    
    SettingsTab:AddLabel("=== Configuration ===")
    
    SettingsTab:AddButton("Save Settings", function()
        saveConfig()
        print("✅ Settings saved successfully!")
    end)
    
    SettingsTab:AddButton("Load Settings", function()
        loadConfig()
        print("✅ Settings loaded successfully!")
    end)
    
    SettingsTab:AddButton("Reset Settings", function()
        _G.CBROSettings = DefaultSettings
        saveConfig()
        print("✅ Settings reset to default!")
    end)
    
    SettingsTab:AddLabel("=== Key Binds ===")
    
    SettingsTab:AddButton("Save Keybinds", function()
        saveKeyBinds()
        print("✅ Keybinds saved successfully!")
    end)
    
    SettingsTab:AddButton("Reset Keybinds", function()
        KeyBinds = {}
        saveKeyBinds()
        print("✅ Keybinds reset!")
    end)
    
    SettingsTab:AddLabel("=== Information ===")
    SettingsTab:AddLabel("Version: 2.0")
    SettingsTab:AddLabel("Author: Ivan3056")
    SettingsTab:AddLabel("Discord: [Your Discord]")
    
    -- Show first tab and format
    if modules.Movement then
        Window.tabs[1]:Show()
    end
    library:FormatWindows()
    
    -- Auto-save every 30 seconds
    spawn(function()
        while _G.CBROLoaded do
            wait(30)
            saveConfig()
        end
    end)
    
    print("✅ Counter Blox Enhanced loaded successfully!")
    print("🎮 Press " .. _G.CBROSettings.UI.ToggleKey .. " to toggle UI")
end

-- Cleanup function
local function cleanup()
    _G.CBROLoaded = false
    saveConfig()
    saveKeyBinds()
    print("📤 Counter Blox Enhanced unloaded")
end

-- Handle player leaving
Players.PlayerRemoving:Connect(function(player)
    if player == LocalPlayer then
        cleanup()
    end
end)

-- Start the script
initialize()