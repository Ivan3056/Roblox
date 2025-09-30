-- Counter Blox Enhanced Script Loader
-- Main entry point with key system

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- Key System Configuration
local VALID_KEYS = {
    "CBRO_2024_PREMIUM",
    "IVAN_PRIVATE_KEY",
    "DEMO_KEY_123"
}

local CONFIG_FOLDER = "CBROConfig"
local KEY_FILE = CONFIG_FOLDER .. "/auth.json"

-- Check if key is already saved
local function loadSavedKey()
    local success, result = pcall(function()
        return readfile(KEY_FILE)
    end)
    
    if success then
        local keyData = HttpService:JSONDecode(result)
        return keyData.key
    end
    return nil
end

-- Save key to file
local function saveKey(key)
    if not isfolder(CONFIG_FOLDER) then
        makefolder(CONFIG_FOLDER)
    end
    
    local keyData = {
        key = key,
        timestamp = os.time(),
        hwid = game:GetService("RbxAnalyticsService"):GetClientId()
    }
    
    writefile(KEY_FILE, HttpService:JSONEncode(keyData))
end

-- Validate key
local function validateKey(key)
    for _, validKey in pairs(VALID_KEYS) do
        if key == validKey then
            return true
        end
    end
    return false
end

-- Create key input GUI
local function createKeyGUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "CBROKeySystem"
    ScreenGui.Parent = game.CoreGui
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Parent = ScreenGui
    MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    MainFrame.BorderSizePixel = 0
    MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    MainFrame.Size = UDim2.new(0, 400, 0, 250)
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = MainFrame
    
    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Parent = MainFrame
    Title.BackgroundTransparency = 1
    Title.Position = UDim2.new(0, 0, 0, 20)
    Title.Size = UDim2.new(1, 0, 0, 30)
    Title.Font = Enum.Font.GothamBold
    Title.Text = "Counter Blox Enhanced - Key System"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextScaled = true
    
    local KeyInput = Instance.new("TextBox")
    KeyInput.Name = "KeyInput"
    KeyInput.Parent = MainFrame
    KeyInput.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    KeyInput.BorderSizePixel = 0
    KeyInput.Position = UDim2.new(0.1, 0, 0.35, 0)
    KeyInput.Size = UDim2.new(0.8, 0, 0, 35)
    KeyInput.Font = Enum.Font.Gotham
    KeyInput.PlaceholderText = "Enter your key here..."
    KeyInput.Text = ""
    KeyInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    KeyInput.TextScaled = true
    
    local KeyCorner = Instance.new("UICorner")
    KeyCorner.CornerRadius = UDim.new(0, 4)
    KeyCorner.Parent = KeyInput
    
    local SubmitButton = Instance.new("TextButton")
    SubmitButton.Name = "SubmitButton"
    SubmitButton.Parent = MainFrame
    SubmitButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
    SubmitButton.BorderSizePixel = 0
    SubmitButton.Position = UDim2.new(0.1, 0, 0.6, 0)
    SubmitButton.Size = UDim2.new(0.35, 0, 0, 35)
    SubmitButton.Font = Enum.Font.GothamBold
    SubmitButton.Text = "Submit Key"
    SubmitButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    SubmitButton.TextScaled = true
    
    local SubmitCorner = Instance.new("UICorner")
    SubmitCorner.CornerRadius = UDim.new(0, 4)
    SubmitCorner.Parent = SubmitButton
    
    local GetKeyButton = Instance.new("TextButton")
    GetKeyButton.Name = "GetKeyButton"
    GetKeyButton.Parent = MainFrame
    GetKeyButton.BackgroundColor3 = Color3.fromRGB(120, 0, 120)
    GetKeyButton.BorderSizePixel = 0
    GetKeyButton.Position = UDim2.new(0.55, 0, 0.6, 0)
    GetKeyButton.Size = UDim2.new(0.35, 0, 0, 35)
    GetKeyButton.Font = Enum.Font.GothamBold
    GetKeyButton.Text = "Get Key"
    GetKeyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    GetKeyButton.TextScaled = true
    
    local GetKeyCorner = Instance.new("UICorner")
    GetKeyCorner.CornerRadius = UDim.new(0, 4)
    GetKeyCorner.Parent = GetKeyButton
    
    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Name = "StatusLabel"
    StatusLabel.Parent = MainFrame
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Position = UDim2.new(0, 0, 0.8, 0)
    StatusLabel.Size = UDim2.new(1, 0, 0, 25)
    StatusLabel.Font = Enum.Font.Gotham
    StatusLabel.Text = "Enter your key to continue"
    StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    StatusLabel.TextScaled = true
    
    return ScreenGui, KeyInput, SubmitButton, GetKeyButton, StatusLabel
end

-- Load main script
local function loadMainScript()
    local success, error = pcall(function()
        loadstring(game:HttpGet('https://raw.githubusercontent.com/Ivan3056/Roblox/main/cbro/main.lua'))()
    end)
    
    if not success then
        warn("Failed to load main script: " .. tostring(error))
    end
end

-- Main execution
local function main()
    -- Check for saved key first
    local savedKey = loadSavedKey()
    if savedKey and validateKey(savedKey) then
        print("✅ Valid key found, loading script...")
        loadMainScript()
        return
    end
    
    -- Show key input GUI
    local gui, keyInput, submitButton, getKeyButton, statusLabel = createKeyGUI()
    
    submitButton.MouseButton1Click:Connect(function()
        local enteredKey = keyInput.Text
        
        if enteredKey == "" then
            statusLabel.Text = "❌ Please enter a key"
            statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
            return
        end
        
        if validateKey(enteredKey) then
            statusLabel.Text = "✅ Valid key! Loading script..."
            statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
            
            saveKey(enteredKey)
            
            wait(1)
            gui:Destroy()
            loadMainScript()
        else
            statusLabel.Text = "❌ Invalid key, try again"
            statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
            keyInput.Text = ""
        end
    end)
    
    getKeyButton.MouseButton1Click:Connect(function()
        setclipboard("https://discord.gg/your-discord-here")
        statusLabel.Text = "📋 Discord link copied to clipboard!"
        statusLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
    end)
    
    -- Allow Enter key to submit
    keyInput.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            submitButton.MouseButton1Click:Fire()
        end
    end)
end

-- Execute
main()