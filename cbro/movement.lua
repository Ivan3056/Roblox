-- Movement Module for Counter Blox Enhanced
-- Includes: WalkSpeed, JumpPower, Fly, Noclip, BunnyHop

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local Movement = {}

-- Movement state
local MovementState = {
    DefaultWalkSpeed = 16,
    DefaultJumpPower = 50,
    FlyEnabled = false,
    NoclipEnabled = false,
    BunnyHopEnabled = false,
    FlyConnection = nil,
    NoclipConnection = nil,
    BunnyHopConnection = nil,
    BodyVelocity = nil
}

-- Get character and humanoid
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

-- WalkSpeed functions
local function setWalkSpeed(speed)
    local humanoid = getHumanoid()
    if humanoid then
        humanoid.WalkSpeed = speed
    end
end

-- JumpPower functions
local function setJumpPower(power)
    local humanoid = getHumanoid()
    if humanoid then
        humanoid.JumpPower = power
    end
end

-- Fly functions
local function enableFly(speed)
    local rootPart = getRootPart()
    if not rootPart then return end
    
    MovementState.FlyEnabled = true
    
    -- Create BodyVelocity for smooth movement
    if MovementState.BodyVelocity then
        MovementState.BodyVelocity:Destroy()
    end
    
    MovementState.BodyVelocity = Instance.new("BodyVelocity")
    MovementState.BodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
    MovementState.BodyVelocity.Velocity = Vector3.new(0, 0, 0)
    MovementState.BodyVelocity.Parent = rootPart
    
    -- Fly control loop
    MovementState.FlyConnection = RunService.Heartbeat:Connect(function()
        if not MovementState.FlyEnabled then return end
        
        local rootPart = getRootPart()
        local humanoid = getHumanoid()
        
        if not rootPart or not humanoid or not MovementState.BodyVelocity then
            return
        end
        
        local camera = workspace.CurrentCamera
        local moveVector = humanoid.MoveDirection
        local lookDirection = camera.CFrame.LookVector
        local rightDirection = camera.CFrame.RightVector
        
        local velocity = Vector3.new(0, 0, 0)
        
        -- Forward/Backward movement
        if moveVector.Magnitude > 0 then
            velocity = velocity + (lookDirection * moveVector.Z + rightDirection * moveVector.X) * speed
        end
        
        -- Up/Down movement
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            velocity = velocity + Vector3.new(0, speed, 0)
        elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            velocity = velocity + Vector3.new(0, -speed, 0)
        end
        
        MovementState.BodyVelocity.Velocity = velocity
    end)
end

local function disableFly()
    MovementState.FlyEnabled = false
    
    if MovementState.FlyConnection then
        MovementState.FlyConnection:Disconnect()
        MovementState.FlyConnection = nil
    end
    
    if MovementState.BodyVelocity then
        MovementState.BodyVelocity:Destroy()
        MovementState.BodyVelocity = nil
    end
end

-- Noclip functions
local function enableNoclip()
    MovementState.NoclipEnabled = true
    
    MovementState.NoclipConnection = RunService.Stepped:Connect(function()
        if not MovementState.NoclipEnabled then return end
        
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
    MovementState.NoclipEnabled = false
    
    if MovementState.NoclipConnection then
        MovementState.NoclipConnection:Disconnect()
        MovementState.NoclipConnection = nil
    end
    
    -- Restore collision
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

-- BunnyHop functions
local function enableBunnyHop()
    MovementState.BunnyHopEnabled = true
    
    MovementState.BunnyHopConnection = UserInputService.JumpRequest:Connect(function()
        if not MovementState.BunnyHopEnabled then return end
        
        local humanoid = getHumanoid()
        if humanoid and humanoid:GetState() ~= Enum.HumanoidStateType.Freefall then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
end

local function disableBunnyHop()
    MovementState.BunnyHopEnabled = false
    
    if MovementState.BunnyHopConnection then
        MovementState.BunnyHopConnection:Disconnect()
        MovementState.BunnyHopConnection = nil
    end
end

-- Initialize UI
function Movement.InitializeUI(Window, settings, saveConfig, bindKey)
    local MovementTab = Window:AddTab("Movement")
    
    MovementTab:AddLabel("=== Speed Settings ===")
    
    -- WalkSpeed
    MovementTab:AddSlider("Walk Speed", function(value)
        settings.WalkSpeed = value
        setWalkSpeed(value)
        saveConfig()
    end, {
        ["min"] = 16,
        ["max"] = 100,
        ["default"] = settings.WalkSpeed or 16
    })
    
    -- JumpPower
    MovementTab:AddSlider("Jump Power", function(value)
        settings.JumpPower = value
        setJumpPower(value)
        saveConfig()
    end, {
        ["min"] = 50,
        ["max"] = 200,
        ["default"] = settings.JumpPower or 50
    })
    
    MovementTab:AddLabel("=== Movement Abilities ===")
    
    -- Fly
    local flyEnabled = false
    MovementTab:AddSwitch("Fly", function(bool)
        flyEnabled = bool
        settings.Fly = bool
        
        if bool then
            enableFly(settings.FlySpeed or 50)
        else
            disableFly()
        end
        saveConfig()
    end)
    
    MovementTab:AddSlider("Fly Speed", function(value)
        settings.FlySpeed = value
        saveConfig()
    end, {
        ["min"] = 10,
        ["max"] = 200,
        ["default"] = settings.FlySpeed or 50
    })
    
    -- Noclip
    MovementTab:AddSwitch("Noclip", function(bool)
        settings.Noclip = bool
        
        if bool then
            enableNoclip()
        else
            disableNoclip()
        end
        saveConfig()
    end)
    
    -- BunnyHop
    MovementTab:AddSwitch("Bunny Hop", function(bool)
        settings.BunnyHop = bool
        
        if bool then
            enableBunnyHop()
        else
            disableBunnyHop()
        end
        saveConfig()
    end)
    
    MovementTab:AddLabel("=== Key Binds ===")
    
    -- Key bind setup
    local function setupKeyBind(name, action)
        MovementTab:AddKeybind(name .. " Key", function(key)
            if settings.KeyBinds then
                settings.KeyBinds[action] = key.Name
                saveConfig()
                
                -- Setup the actual keybind
                bindKey("Movement_" .. action, key.Name, function(pressed)
                    if action == "Fly" and pressed then
                        flyEnabled = not flyEnabled
                        settings.Fly = flyEnabled
                        if flyEnabled then
                            enableFly(settings.FlySpeed or 50)
                        else
                            disableFly()
                        end
                    elseif action == "Noclip" and pressed then
                        settings.Noclip = not settings.Noclip
                        if settings.Noclip then
                            enableNoclip()
                        else
                            disableNoclip()
                        end
                    elseif action == "BunnyHop" and pressed then
                        settings.BunnyHop = not settings.BunnyHop
                        if settings.BunnyHop then
                            enableBunnyHop()
                        else
                            disableBunnyHop()
                        end
                    elseif action == "WalkSpeed" and pressed then
                        -- Toggle between normal and fast speed
                        if settings.WalkSpeed == 16 then
                            setWalkSpeed(50)
                            settings.WalkSpeed = 50
                        else
                            setWalkSpeed(16)
                            settings.WalkSpeed = 16
                        end
                    end
                    saveConfig()
                end)
            end
        end, {
            ["default"] = Enum.KeyCode[settings.KeyBinds and settings.KeyBinds[action] or "F"]
        })
    end
    
    setupKeyBind("Fly", "Fly")
    setupKeyBind("Noclip", "Noclip")
    setupKeyBind("Bunny Hop", "BunnyHop")
    setupKeyBind("Speed Toggle", "WalkSpeed")
    
    MovementTab:AddLabel("=== Controls ===")
    MovementTab:AddLabel("Fly: WASD + Space/Ctrl")
    MovementTab:AddLabel("Space: Fly Up")
    MovementTab:AddLabel("Left Ctrl: Fly Down")
    
    MovementTab:AddLabel("=== Quick Actions ===")
    
    MovementTab:AddButton("Reset Character", function()
        LocalPlayer.Character:BreakJoints()
    end)
    
    MovementTab:AddButton("Disable All", function()
        disableFly()
        disableNoclip()
        disableBunnyHop()
        setWalkSpeed(16)
        setJumpPower(50)
        
        settings.Fly = false
        settings.Noclip = false
        settings.BunnyHop = false
        settings.WalkSpeed = 16
        settings.JumpPower = 50
        
        saveConfig()
    end)
end

-- Handle character respawn
LocalPlayer.CharacterAdded:Connect(function()
    wait(1) -- Wait for character to fully load
    
    -- Restore settings after respawn
    if _G.CBROSettings and _G.CBROSettings.Movement then
        local settings = _G.CBROSettings.Movement
        
        if settings.WalkSpeed and settings.WalkSpeed ~= 16 then
            setWalkSpeed(settings.WalkSpeed)
        end
        
        if settings.JumpPower and settings.JumpPower ~= 50 then
            setJumpPower(settings.JumpPower)
        end
        
        if settings.Fly then
            enableFly(settings.FlySpeed or 50)
        end
        
        if settings.Noclip then
            enableNoclip()
        end
        
        if settings.BunnyHop then
            enableBunnyHop()
        end
    end
end)

-- Cleanup on leave
local function cleanup()
    disableFly()
    disableNoclip()
    disableBunnyHop()
end

Players.PlayerRemoving:Connect(function(player)
    if player == LocalPlayer then
        cleanup()
    end
end)

return Movement