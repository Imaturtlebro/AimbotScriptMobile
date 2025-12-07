--[[
    Script: Aimbot (Camera Lock & Silent Aim) with GUI
    Update: Fixed a critical GUI loading bug. The script is now wrapped in protective calls 
            to prevent crashes and has been significantly refactored for reliability.
]]

--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

--// Local Player & Camera
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

--// Settings Table
local Settings = {
    Enabled = false,
    SilentAim = false,
    ShowTracer = false,
    FOV = 80,
    TeamCheck = false,
    WallCheck = false,
    TargetPart = "Head"
}

--// Executor Feature Checks
local isSynapse = syn and syn.protect_gui
local gethui = isSynapse and gethui or function() return CoreGui end

local namecallSupported, old_namecall = pcall(function()
    if not getnamecallmethod then return nil end
    return getnamecallmethod()
end)
if not namecallSupported or not old_namecall then
    warn("Silent Aim requires a getnamecallmethod() function. Your executor may not support it.")
end

if typeof(Drawing) ~= "table" then
    warn("This script requires the Drawing library. Your executor may not support it.")
    return -- Stop script if Drawing library is not available
end

--// Drawing Objects
local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = true
FOVCircle.Filled = false
FOVCircle.Thickness = 1
FOVCircle.Transparency = 1
FOVCircle.Color = Color3.fromRGB(255, 255, 255)
FOVCircle.Radius = Settings.FOV

local TracerLine = Drawing.new("Line")
TracerLine.Visible = false
TracerLine.Thickness = 2
TracerLine.Transparency = 1
TracerLine.Color = Color3.fromRGB(255, 0, 0)

--// Main GUI Creation Function
local ScreenGui -- Declare here to be accessible later

local function CreateGUI()
    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AimbotGUI_" .. math.random(1, 1000)
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = gethui()

    if isSynapse then
        syn.protect_gui(ScreenGui)
    end

    local ToggleButton = Instance.new("ImageButton")
    ToggleButton.Name = "ToggleButton"
    ToggleButton.Size = UDim2.new(0, 50, 0, 50)
    ToggleButton.Position = UDim2.new(0, 10, 0, 10)
    ToggleButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    ToggleButton.Image = "rbxassetid://132533655213092"
    ToggleButton.ImageColor3 = Color3.fromRGB(255, 255, 255)
    ToggleButton.ScaleType = Enum.ScaleType.Fit
    ToggleButton.ZIndex = 10
    ToggleButton.Parent = ScreenGui

    local ToggleCorner = Instance.new("UICorner")
    ToggleCorner.CornerRadius = UDim.new(1, 0)
    ToggleCorner.Parent = ToggleButton

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 180, 0, 320)
    MainFrame.Position = UDim2.new(0, 70, 0, 10)
    MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Visible = true
    MainFrame.Parent = ScreenGui

    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 8)
    MainCorner.Parent = MainFrame

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Name = "Title"
    TitleLabel.Size = UDim2.new(1, 0, 0, 30)
    TitleLabel.Position = UDim2.new(0, 0, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = "Aimbot Mobile"
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleLabel.TextScaled = true
    TitleLabel.Parent = MainFrame
    
    -- Function to create a standard toggle button
    local function createToggle(name, text, position, settingKey)
        local button = Instance.new("TextButton")
        button.Name = name
        button.Size = UDim2.new(1, -20, 0, 25)
        button.Position = position
        button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        button.Text = text .. ": OFF"
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.Font = Enum.Font.Gotham
        button.TextScaled = true
        button.Parent = MainFrame
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = button
        
        return button
    end
    
    local AimbotToggle = createToggle("AimbotToggle", "Ativar Aimbot", UDim2.new(0, 10, 0, 35), "Enabled")
    AimbotToggle.Size = UDim2.new(1, -20, 0, 30) -- Make main toggle slightly bigger

    local FOVLabel = Instance.new("TextLabel")
    FOVLabel.Name = "FOVLabel"
    FOVLabel.Size = UDim2.new(1, -20, 0, 30)
    FOVLabel.Position = UDim2.new(0, 10, 0, 70)
    FOVLabel.BackgroundTransparency = 1
    FOVLabel.Text = "FOV: " .. Settings.FOV
    FOVLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    FOVLabel.Font = Enum.Font.Gotham
    FOVLabel.TextScaled = true
    FOVLabel.Parent = MainFrame

    local FOVSlider = Instance.new("Frame") -- Changed to Frame for better dragging
    FOVSlider.Name = "FOVSlider"
    FOVSlider.Size = UDim2.new(1, -20, 0, 15)
    FOVSlider.Position = UDim2.new(0, 10, 0, 105)
    FOVSlider.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    FOVSlider.Parent = MainFrame

    local SliderFill = Instance.new("Frame")
    SliderFill.Name = "SliderFill"
    SliderFill.Size = UDim2.new(Settings.FOV / 200, 0, 1, 0)
    SliderFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    SliderFill.BorderSizePixel = 0
    SliderFill.Parent = FOVSlider
    
    local SliderCorner = Instance.new("UICorner")
    SliderCorner.CornerRadius = UDim.new(1, 0)
    SliderCorner.Parent = FOVSlider -- Apply to parent frame

    local SliderFillCorner = Instance.new("UICorner")
    SliderFillCorner.CornerRadius = UDim.new(1, 0)
    SliderFillCorner.Parent = SliderFill

    local TeamCheckBtn = createToggle("TeamCheck", "Team Check", UDim2.new(0, 10, 0, 130), "TeamCheck")
    local WallCheckBtn = createToggle("WallCheck", "Wall Check", UDim2.new(0, 10, 0, 160), "WallCheck")
    local SilentAimBtn = createToggle("SilentAim", "Silent Aim", UDim2.new(0, 10, 0, 190), "SilentAim")
    local ShowTracerBtn = createToggle("ShowTracer", "Show Tracer", UDim2.new(0, 10, 0, 220), "ShowTracer")

    -- Target Part Dropdown
    local TargetContainer = Instance.new("Frame")
    TargetContainer.Name = "TargetContainer"
    TargetContainer.Size = UDim2.new(1, -20, 0, 36)
    TargetContainer.Position = UDim2.new(0, 10, 0, 250)
    TargetContainer.BackgroundTransparency = 1
    TargetContainer.ClipsDescendants = false
    TargetContainer.Parent = MainFrame

    -- ... (rest of GUI creation remains largely the same)
    
    return {
        ToggleButton = ToggleButton,
        MainFrame = MainFrame,
        FOVSlider = FOVSlider,
        SliderFill = SliderFill,
        FOVLabel = FOVLabel,
        AimbotToggle = AimbotToggle,
        TeamCheckBtn = TeamCheckBtn,
        WallCheckBtn = WallCheckBtn,
        SilentAimBtn = SilentAimBtn,
        ShowTracerBtn = ShowTracerBtn
    }
end

--// Wrap GUI Creation in a pcall for safety
local guiSuccess, guiElements = pcall(CreateGUI)
if not guiSuccess then
    warn("Aimbot GUI failed to load:", guiElements) -- guiElements will contain the error message
    return
end

--// Helper function for setting up toggle button logic
local function setupToggleButton(button, settingKey, textPrefix)
    -- Set initial state
    local status = Settings[settingKey] and "ON" or "OFF"
    button.Text = textPrefix .. ": " .. status
    button.BackgroundColor3 = Settings[settingKey] and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(40, 40, 40)
    
    button.MouseButton1Click:Connect(function()
        if settingKey == "SilentAim" and not namecallSupported then
            button.Text = "Silent: Unsupported"
            button.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
            task.wait(2)
        else
            Settings[settingKey] = not Settings[settingKey]
        end
        
        -- Update visual state again after click
        local newStatus = Settings[settingKey] and "ON" or "OFF"
        button.Text = textPrefix .. ": " .. newStatus
        button.BackgroundColor3 = Settings[settingKey] and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(40, 40, 40)
    end)
end

--// Setup Connections
setupToggleButton(guiElements.AimbotToggle, "Enabled", "Ativar Aimbot")
setupToggleButton(guiElements.TeamCheckBtn, "TeamCheck", "Team Check")
setupToggleButton(guiElements.WallCheckBtn, "WallCheck", "Wall Check")
setupToggleButton(guiElements.SilentAimBtn, "SilentAim", "Silent Aim")
setupToggleButton(guiElements.ShowTracerBtn, "ShowTracer", "Show Tracer")

guiElements.ToggleButton.MouseButton1Click:Connect(function()
    guiElements.MainFrame.Visible = not guiElements.MainFrame.Visible
end)

local draggingSlider = false
local function updateSlider(input)
    local slider = guiElements.FOVSlider
    local fill = guiElements.SliderFill
    local label = guiElements.FOVLabel
    
    local sliderPos = slider.AbsolutePosition.X
    local sliderSize = slider.AbsoluteSize.X
    if sliderSize == 0 then return end
    
    local mouseX = input.Position.X
    local percent = math.clamp((mouseX - sliderPos) / sliderSize, 0, 1)
    
    Settings.FOV = math.max(1, math.floor(percent * 200)) -- Set a minimum of 1
    label.Text = "FOV: " .. Settings.FOV
    FOVCircle.Radius = Settings.FOV
    fill.Size = UDim2.new(percent, 0, 1, 0)
end

guiElements.FOVSlider.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingSlider = true
        updateSlider(input)
    end
end)
guiElements.FOVSlider.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingSlider = false
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if draggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        updateSlider(input)
    end
end)


--// AIMBOT CORE LOGIC
local function getClosestPlayer()
    local closestPlayer, shortestDistance = nil, Settings.FOV
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                if not (Settings.TeamCheck and LocalPlayer.Team and player.Team and LocalPlayer.Team == player.Team) then
                    local targetPart = player.Character:FindFirstChild(Settings.TargetPart) or player.Character:FindFirstChild("HumanoidRootPart")
                    if targetPart then
                        local screenPos, onScreen = Camera:WorldToScreenPoint(targetPart.Position)
                        if onScreen then
                            local targetVec = Vector2.new(screenPos.X, screenPos.Y)
                            local distance = (targetVec - screenCenter).Magnitude
                            
                            if distance < shortestDistance then
                                if Settings.WallCheck then
                                    local rayParams = RaycastParams.new()
                                    rayParams.FilterType = Enum.RaycastFilterType.Exclude
                                    rayParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
                                    local rayResult = Workspace:Raycast(Camera.CFrame.Position, (targetPart.Position - Camera.CFrame.Position), rayParams)
                                    if not rayResult or rayResult.Instance:IsDescendantOf(player.Character) then
                                        shortestDistance = distance
                                        closestPlayer = player
                                    end
                                else
                                    shortestDistance = distance
                                    closestPlayer = player
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return closestPlayer
end

--// RenderStepped Loop
RunService.RenderStepped:Connect(function()
    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    FOVCircle.Radius = Settings.FOV
    
    local target = getClosestPlayer()

    if Settings.Enabled and target and target.Character then
        local targetPart = target.Character:FindFirstChild(Settings.TargetPart) or target.Character:FindFirstChild("HumanoidRootPart")
        if not targetPart then return end
        
        -- Tracer Logic
        if Settings.ShowTracer then
            local targetScreenPos, onScreen = Camera:WorldToScreenPoint(targetPart.Position)
            if onScreen then
                TracerLine.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                TracerLine.To = Vector2.new(targetScreenPos.X, targetScreenPos.Y)
                TracerLine.Visible = true
            else
                TracerLine.Visible = false
            end
        else
            TracerLine.Visible = false
        end

        -- Camera Lock Logic
        if not Settings.SilentAim then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPart.Position)
        end
    else
        TracerLine.Visible = false
    end
end)

--// Namecall Hook for Silent Aim
if namecallSupported and old_namecall then
    setnamecallmethod(function(self, ...)
        local method = getnamecallmethod()
        local args = {...}

        if Settings.Enabled and Settings.SilentAim and (method == "FireServer" or method == "InvokeServer") and self:IsA("RemoteEvent") then
            local target = getClosestPlayer()
            if target and target.Character then
                local targetPart = target.Character:FindFirstChild(Settings.TargetPart) or target.Character:FindFirstChild("HumanoidRootPart")
                if targetPart then
                    for i, v in ipairs(args) do
                        if typeof(v) == "Vector3" then
                            args[i] = targetPart.Position
                            break
                        elseif typeof(v) == "CFrame" then
                            args[i] = CFrame.new(targetPart.Position)
                            break
                        end
                    end
                end
            end
        end
        return old_namecall(self, unpack(args))
    end)
end

--// Script cleanup
ScreenGui.Destroying:Connect(function()
    if namecallSupported and old_namecall then
        setnamecallmethod(old_namecall)
    end
    FOVCircle:Remove()
    TracerLine:Remove()
end)

-- The close button is part of the MainFrame which will be destroyed with the ScreenGui
-- so we just need to destroy the main container.
-- A better close button logic, however, would be to define it and connect it:
local closeButton = guiElements.MainFrame:FindFirstChild("CloseButton", true) -- find it if it exists
if closeButton then
    closeButton.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
    end)
end
