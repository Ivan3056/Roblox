-- Counter Blox Enhanced Script Loader
-- Main entry point with key system

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- Key System Configuration
local VALID_KEYS = {
    "CBRO_2025_PREMIUM",
    "CBRO_TEST_KEY", 
    "CBRO_VIP_ACCESS",
    "DEMO_KEY_123",
    "FREE_KEY_2025"
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

-- Create beautiful key input GUI
local function createKeyGUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "CBROKeySystem"
    ScreenGui.Parent = game.CoreGui
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Main Frame with shadow
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Parent = ScreenGui
    MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    MainFrame.BorderSizePixel = 0
    MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    MainFrame.Size = UDim2.new(0, 450, 0, 320)
    MainFrame.ClipsDescendants = true
    
    -- Gradient background
    local Gradient = Instance.new("UIGradient")
    Gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 25, 35)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 15, 20))
    }
    Gradient.Rotation = 45
    Gradient.Parent = MainFrame
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 12)
    Corner.Parent = MainFrame
    
    -- Drop shadow effect
    local Shadow = Instance.new("ImageLabel")
    Shadow.Name = "Shadow"
    Shadow.Parent = MainFrame
    Shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    Shadow.BackgroundTransparency = 1
    Shadow.Position = UDim2.new(0.5, 0, 0.5, 3)
    Shadow.Size = UDim2.new(1, 20, 1, 20)
    Shadow.ZIndex = -1
    Shadow.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
    Shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    Shadow.ImageTransparency = 0.8
    
    -- Top bar for dragging
    local TopBar = Instance.new("Frame")
    TopBar.Name = "TopBar"
    TopBar.Parent = MainFrame
    TopBar.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    TopBar.BorderSizePixel = 0
    TopBar.Size = UDim2.new(1, 0, 0, 40)
    
    local TopBarCorner = Instance.new("UICorner")
    TopBarCorner.CornerRadius = UDim.new(0, 12)
    TopBarCorner.Parent = TopBar
    
    -- Fix top bar corners
    local TopBarFix = Instance.new("Frame")
    TopBarFix.Parent = TopBar
    TopBarFix.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    TopBarFix.BorderSizePixel = 0
    TopBarFix.Position = UDim2.new(0, 0, 0.7, 0)
    TopBarFix.Size = UDim2.new(1, 0, 0.3, 0)
    
    -- Close button
    local CloseButton = Instance.new("TextButton")
    CloseButton.Name = "CloseButton"
    CloseButton.Parent = TopBar
    CloseButton.AnchorPoint = Vector2.new(1, 0.5)
    CloseButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    CloseButton.BorderSizePixel = 0
    CloseButton.Position = UDim2.new(1, -10, 0.5, 0)
    CloseButton.Size = UDim2.new(0, 25, 0, 25)
    CloseButton.Font = Enum.Font.GothamBold
    CloseButton.Text = "×"
    CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseButton.TextScaled = true
    
    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(0, 4)
    CloseCorner.Parent = CloseButton
    
    -- Title
    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Parent = MainFrame
    Title.BackgroundTransparency = 1
    Title.Position = UDim2.new(0, 0, 0, 60)
    Title.Size = UDim2.new(1, 0, 0, 35)
    Title.Font = Enum.Font.GothamBold
    Title.Text = "🎮 Counter Blox Enhanced"
    Title.TextColor3 = Color3.fromRGB(100, 200, 255)
    Title.TextScaled = true
    
    local Subtitle = Instance.new("TextLabel")
    Subtitle.Name = "Subtitle"
    Subtitle.Parent = MainFrame
    Subtitle.BackgroundTransparency = 1
    Subtitle.Position = UDim2.new(0, 0, 0, 95)
    Subtitle.Size = UDim2.new(1, 0, 0, 20)
    Subtitle.Font = Enum.Font.Gotham
    Subtitle.Text = "Premium Key Authentication System"
    Subtitle.TextColor3 = Color3.fromRGB(150, 150, 150)
    Subtitle.TextScaled = true
    
    -- Key input with icon
    local InputFrame = Instance.new("Frame")
    InputFrame.Name = "InputFrame"
    InputFrame.Parent = MainFrame
    InputFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    InputFrame.BorderSizePixel = 0
    InputFrame.Position = UDim2.new(0.1, 0, 0, 140)
    InputFrame.Size = UDim2.new(0.8, 0, 0, 45)
    
    local InputCorner = Instance.new("UICorner")
    InputCorner.CornerRadius = UDim.new(0, 8)
    InputCorner.Parent = InputFrame
    
    local KeyIcon = Instance.new("TextLabel")
    KeyIcon.Name = "KeyIcon"
    KeyIcon.Parent = InputFrame
    KeyIcon.BackgroundTransparency = 1
    KeyIcon.Position = UDim2.new(0, 15, 0.5, -10)
    KeyIcon.Size = UDim2.new(0, 20, 0, 20)
    KeyIcon.Font = Enum.Font.GothamBold
    KeyIcon.Text = "🔑"
    KeyIcon.TextColor3 = Color3.fromRGB(100, 200, 255)
    KeyIcon.TextScaled = true
    
    local KeyInput = Instance.new("TextBox")
    KeyInput.Name = "KeyInput"
    KeyInput.Parent = InputFrame
    KeyInput.BackgroundTransparency = 1
    KeyInput.Position = UDim2.new(0, 50, 0, 0)
    KeyInput.Size = UDim2.new(1, -50, 1, 0)
    KeyInput.Font = Enum.Font.Gotham
    KeyInput.PlaceholderText = "Enter your premium key here..."
    KeyInput.Text = ""
    KeyInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    KeyInput.TextScaled = true
    KeyInput.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Submit button with hover effect
    local SubmitButton = Instance.new("TextButton")
    SubmitButton.Name = "SubmitButton"
    SubmitButton.Parent = MainFrame
    SubmitButton.BackgroundColor3 = Color3.fromRGB(50, 150, 255)
    SubmitButton.BorderSizePixel = 0
    SubmitButton.Position = UDim2.new(0.1, 0, 0, 210)
    SubmitButton.Size = UDim2.new(0.35, 0, 0, 40)
    SubmitButton.Font = Enum.Font.GothamBold
    SubmitButton.Text = "🚀 Verify Key"
    SubmitButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    SubmitButton.TextScaled = true
    
    local SubmitCorner = Instance.new("UICorner")
    SubmitCorner.CornerRadius = UDim.new(0, 8)
    SubmitCorner.Parent = SubmitButton
    
    -- Get Key button
    local GetKeyButton = Instance.new("TextButton")
    GetKeyButton.Name = "GetKeyButton"
    GetKeyButton.Parent = MainFrame
    GetKeyButton.BackgroundColor3 = Color3.fromRGB(150, 50, 200)
    GetKeyButton.BorderSizePixel = 0
    GetKeyButton.Position = UDim2.new(0.55, 0, 0, 210)
    GetKeyButton.Size = UDim2.new(0.35, 0, 0, 40)
    GetKeyButton.Font = Enum.Font.GothamBold
    GetKeyButton.Text = "🔗 Get Key"
    GetKeyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    GetKeyButton.TextScaled = true
    
    local GetKeyCorner = Instance.new("UICorner")
    GetKeyCorner.CornerRadius = UDim.new(0, 8)
    GetKeyCorner.Parent = GetKeyButton
    
    -- Status label with better styling
    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Name = "StatusLabel"
    StatusLabel.Parent = MainFrame
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Position = UDim2.new(0, 0, 0, 270)
    StatusLabel.Size = UDim2.new(1, 0, 0, 30)
    StatusLabel.Font = Enum.Font.Gotham
    StatusLabel.Text = "💡 Enter your key to access premium features"
    StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    StatusLabel.TextScaled = true
    
    -- Make draggable
    local dragging = false
    local dragStart = nil
    local startPos = nil
    
    TopBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    -- Hover effects
    SubmitButton.MouseEnter:Connect(function()
        TweenService:Create(SubmitButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(70, 170, 255)}):Play()
    end)
    
    SubmitButton.MouseLeave:Connect(function()
        TweenService:Create(SubmitButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 150, 255)}):Play()
    end)
    
    GetKeyButton.MouseEnter:Connect(function()
        TweenService:Create(GetKeyButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(170, 70, 220)}):Play()
    end)
    
    GetKeyButton.MouseLeave:Connect(function()
        TweenService:Create(GetKeyButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(150, 50, 200)}):Play()
    end)
    
    CloseButton.MouseEnter:Connect(function()
        TweenService:Create(CloseButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(220, 70, 70)}):Play()
    end)
    
    CloseButton.MouseLeave:Connect(function()
        TweenService:Create(CloseButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(200, 50, 50)}):Play()
    end)
    
    return ScreenGui, KeyInput, SubmitButton, GetKeyButton, StatusLabel, CloseButton
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
    local gui, keyInput, submitButton, getKeyButton, statusLabel, closeButton = createKeyGUI()
    
    -- Close button functionality
    closeButton.MouseButton1Click:Connect(function()
        gui:Destroy()
    end)
    
    submitButton.MouseButton1Click:Connect(function()
        local enteredKey = keyInput.Text
        
        if enteredKey == "" then
            statusLabel.Text = "❌ Please enter a key"
            statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
            return
        end
        
        -- Debug: print entered key
        print("Debug: Entered key: '" .. enteredKey .. "'")
        print("Debug: Valid keys:", table.concat(VALID_KEYS, ", "))
        
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
        
        -- Also show valid keys for testing
        print("Valid keys for testing:")
        for i, key in pairs(VALID_KEYS) do
            print(i .. ". " .. key)
        end
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