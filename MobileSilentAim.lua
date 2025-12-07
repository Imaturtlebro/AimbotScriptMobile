--[[
    Script: Aimbot (Camera Lock & Silent Aim) - Merged & Fixed
    Version: 3.0
    Author: Merged by AI
    
    Changes:
    - Merged features from both provided scripts into a single, cohesive version.
    - FIXED: Silent Aim hook is no longer generic. It now requires a specific remote name to avoid breaking game functions like shooting.
    - FIXED: Tracer line now originates from the mouse cursor for a more intuitive visual, instead of the bottom of the screen.
    - ADDED: Silent Aim and Show Tracer toggles from the new script.
    - ADDED: Robust executor feature checks (syn, gethui, Drawing, getnamecallmethod).
    - ADDED: GUI creation is wrapped in a pcall for stability.
    - RE-INTEGRATED: The "KillCheck" feature from the original script is now a functional toggle.
    - IMPROVED: Overall code structure, readability, and reliability.
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
    KillCheck = false, -- Re-added from original
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
TracerLine.Thickness = 1.5
TracerLine.Transparency = 0.8
TracerLine.Color = Color3.fromRGB(255, 0, 0)

--// Main GUI Container
local ScreenGui
local guiElements = {}

--// Main GUI Creation Function
local function CreateGUI()
    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AimbotGUI_" .. math.random(1, 1000)
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = gethui()

    if isSynapse then
        syn.protect_gui(ScreenGui)
    end

    -- Toggle Button to Show/Hide Main Frame
    local ToggleButton = Instance.new("ImageButton")
    ToggleButton.Name = "ToggleButton"
    ToggleButton.Size = UDim2.new(0, 50, 0, 50)
    ToggleButton.Position = UDim2.new(0, 10, 0, 10)
    ToggleButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    ToggleButton.Image = "rbxassetid://132533655213092" -- A generic settings/gear icon
    ToggleButton.ImageColor3 = Color3.fromRGB(255, 255, 255)
    ToggleButton.ScaleType = Enum.ScaleType.Fit
    ToggleButton.ZIndex = 10
    ToggleButton.Parent = ScreenGui
    Instance.new("UICorner", ToggleButton).CornerRadius = UDim.new(1, 0)
    guiElements.ToggleButton = ToggleButton

    -- Main Frame
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 180, 0, 350) -- Increased height for more buttons
    MainFrame.Position = UDim2.new(0, 70, 0, 10)
    MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Visible = true
    MainFrame.Parent = ScreenGui
    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)
    guiElements.MainFrame = MainFrame

    -- Title
    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Name = "Title"
    TitleLabel.Size = UDim2.new(1, 0, 0, 30)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = "Aimbot Mobile"
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleLabel.TextScaled = true
    TitleLabel.Parent = MainFrame

    -- Close Button
    local CloseButton = Instance.new("TextButton")
    CloseButton.Name = "CloseButton"
    CloseButton.Size = UDim2.new(0, 25, 0, 25)
    CloseButton.Position = UDim2.new(1, -30, 0, 5)
    CloseButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    CloseButton.Text = "X"
    CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseButton.Font = Enum.Font.GothamBold
    CloseButton.TextScaled = true
    CloseButton.Parent = MainFrame
    Instance.new("UICorner", CloseButton).CornerRadius = UDim.new(1, 0)
    guiElements.CloseButton = CloseButton

    -- Helper function to create a standard toggle button
    local function createToggle(name, text, position)
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
        Instance.new("UICorner", button).CornerRadius = UDim.new(0, 6)
        return button
    end
    
    guiElements.AimbotToggle = createToggle("AimbotToggle", "Ativar Aimbot", UDim2.new(0, 10, 0, 35))
    guiElements.AimbotToggle.Size = UDim2.new(1, -20, 0, 30)

    -- FOV Slider
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
    guiElements.FOVLabel = FOVLabel

    local FOVSlider = Instance.new("Frame")
    FOVSlider.Name = "FOVSlider"
    FOVSlider.Size = UDim2.new(1, -20, 0, 15)
    FOVSlider.Position = UDim2.new(0, 10, 0, 105)
    FOVSlider.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    FOVSlider.Parent = MainFrame
    Instance.new("UICorner", FOVSlider).CornerRadius = UDim.new(1, 0)
    guiElements.FOVSlider = FOVSlider
    
    local SliderFill = Instance.new("Frame")
    SliderFill.Name = "SliderFill"
    SliderFill.Size = UDim2.new(Settings.FOV / 200, 0, 1, 0)
    SliderFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    SliderFill.BorderSizePixel = 0
    SliderFill.Parent = FOVSlider
    Instance.new("UICorner", SliderFill).CornerRadius = UDim.new(1, 0)
    guiElements.SliderFill = SliderFill
    
    -- Other Toggles
    guiElements.TeamCheckBtn = createToggle("TeamCheck", "Team Check", UDim2.new(0, 10, 0, 130))
    guiElements.KillCheckBtn = createToggle("KillCheck", "Kill Check", UDim2.new(0, 10, 0, 160))
    guiElements.WallCheckBtn = createToggle("WallCheck", "Wall Check", UDim2.new(0, 10, 0, 190))
    guiElements.SilentAimBtn = createToggle("SilentAim", "Silent Aim", UDim2.new(0, 10, 0, 220))
    guiElements.ShowTracerBtn = createToggle("ShowTracer", "Show Tracer", UDim2.new(0, 10, 0, 250))

    -- Target Part Dropdown
    local TargetContainer = Instance.new("Frame")
    TargetContainer.Name = "TargetContainer"
    TargetContainer.Size = UDim2.new(1, -20, 0, 36)
    TargetContainer.Position = UDim2.new(0, 10, 0, 285)
    TargetContainer.BackgroundTransparency = 1
    TargetContainer.Parent = MainFrame

    local TargetLabel = Instance.new("TextLabel")
    TargetLabel.Name = "TargetLabel"
    TargetLabel.Size = UDim2.new(1, 0, 0, 16)
    TargetLabel.BackgroundTransparency = 1
    TargetLabel.Text = "Target Part"
    TargetLabel.Font = Enum.Font.Gotham
    TargetLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TargetLabel.TextXAlignment = Enum.TextXAlignment.Left
    TargetLabel.Parent = TargetContainer

    local TargetDropdown = Instance.new("TextButton")
    TargetDropdown.Name = "TargetDropdown"
    TargetDropdown.Size = UDim2.new(1, 0, 0, 20)
    TargetDropdown.Position = UDim2.new(0, 0, 0, 16)
    TargetDropdown.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    TargetDropdown.Text = Settings.TargetPart
    TargetDropdown.Font = Enum.Font.GothamBold
    TargetDropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
    TargetDropdown.Parent = TargetContainer

    local DropdownList = Instance.new("ScrollingFrame")
    DropdownList.Name = "DropdownList"
    DropdownList.Size = UDim2.new(1, 0, 3, 0)
    DropdownList.Position = UDim2.new(0, 0, 1, 0)
    DropdownList.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    DropdownList.BorderSizePixel = 0
    DropdownList.Visible = false
    DropdownList.ZIndex = 50
    DropdownList.Parent = TargetDropdown
    local ListLayout = Instance.new("UIListLayout", DropdownList)
    ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    
    local targetParts = {"Head", "Torso", "HumanoidRootPart", "LeftLeg", "RightLeg"}
    for _, partName in ipairs(targetParts) do
        local PartButton = Instance.new("TextButton")
        PartButton.Name = partName
        PartButton.Size = UDim2.new(1, 0, 0, 20)
        PartButton.BackgroundTransparency = 1
        PartButton.Text = partName
        PartButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        PartButton.Font = Enum.Font.Gotham
        PartButton.ZIndex = 51
        PartButton.Parent = DropdownList
        PartButton.MouseButton1Click:Connect(function()
            Settings.TargetPart = partName
            TargetDropdown.Text = partName
            DropdownList.Visible = false
        end)
    end
    guiElements.TargetDropdown = TargetDropdown
    guiElements.DropdownList = DropdownList
end

--// Wrap GUI Creation in a pcall for safety
local guiSuccess, errorMessage = pcall(CreateGUI)
if not guiSuccess then
    warn("Aimbot GUI failed to load:", errorMessage)
    return
end

--// CONNECTIONS
-- Helper function for setting up toggle button logic
local function setupToggleButton(button, settingKey, textPrefix)
    button.MouseButton1Click:Connect(function()
        if settingKey == "SilentAim" and not namecallSupported then
            button.Text = "Silent: Unsupported"
            button.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
            task.wait(1.5)
        else
            Settings[settingKey] = not Settings[settingKey]
        end
        
        local status = Settings[settingKey] and "ON" or "OFF"
        button.Text = textPrefix .. ": " .. status
        button.BackgroundColor3 = Settings[settingKey] and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(40, 40, 40)
    end)
end

setupToggleButton(guiElements.AimbotToggle, "Enabled", "Ativar Aimbot")
setupToggleButton(guiElements.TeamCheckBtn, "TeamCheck", "Team Check")
setupToggleButton(guiElements.KillCheckBtn, "KillCheck", "Kill Check")
setupToggleButton(guiElements.WallCheckBtn, "WallCheck", "Wall Check")
setupToggleButton(guiElements.SilentAimBtn, "SilentAim", "Silent Aim")
setupToggleButton(guiElements.ShowTracerBtn, "ShowTracer", "Show Tracer")

-- Show/Hide and Close Logic
guiElements.ToggleButton.MouseButton1Click:Connect(function()
    guiElements.MainFrame.Visible = not guiElements.MainFrame.Visible
end)
guiElements.CloseButton.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- Dropdown Logic
guiElements.TargetDropdown.MouseButton1Click:Connect(function()
    guiElements.DropdownList.Visible = not guiElements.DropdownList.Visible
end)

-- Slider Logic
local draggingSlider = false
local function updateSlider(input)
    local sliderPos = guiElements.FOVSlider.AbsolutePosition.X
    local sliderSize = guiElements.FOVSlider.AbsoluteSize.X
    if sliderSize == 0 then return end
    
    local mouseX = input.Position.X
    local percent = math.clamp((mouseX - sliderPos) / sliderSize, 0, 1)
    
    Settings.FOV = math.max(1, math.floor(percent * 200)) -- Min FOV of 1
    guiElements.FOVLabel.Text = "FOV: " .. Settings.FOV
    FOVCircle.Radius = Settings.FOV
    guiElements.SliderFill.Size = UDim2.new(percent, 0, 1, 0)
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
local function isAlive(player)
    if Settings.KillCheck then
        return false -- If KillCheck is on, we consider everyone "dead" so we don't target them.
    end
    local character = player.Character
    if not character then return false end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    return humanoid and humanoid.Health > 0
end

local function isTeammate(player)
    if not Settings.TeamCheck then return false end
    if not LocalPlayer.Team or not player.Team then return false end
    return LocalPlayer.Team == player.Team
end

local function isVisible(targetPart)
    if not Settings.WallCheck then return true end
    local origin = Camera.CFrame.Position
    local direction = targetPart.Position - origin
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    local result = Workspace:Raycast(origin, direction, rayParams)
    
    -- If the ray hits nothing, or it hits something that is part of the target's character, they are visible.
    return not result or result.Instance:IsDescendantOf(targetPart.Parent)
end

local function getClosestPlayer()
    local closestPlayer, shortestDistance = nil, Settings.FOV
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and not isTeammate(player) and isAlive(player) then
            local targetPart = player.Character:FindFirstChild(Settings.TargetPart) or player.Character:FindFirstChild("HumanoidRootPart")
            if targetPart then
                local screenPos, onScreen = Camera:WorldToScreenPoint(targetPart.Position)
                if onScreen then
                    local distance = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                    if distance < shortestDistance and isVisible(targetPart) then
                        shortestDistance = distance
                        closestPlayer = player
                    end
                end
            end
        end
    end
    return closestPlayer
end


--// RENDER STEP (Main Loop)
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
                -- FIXED: Originates from mouse for a more natural feel
                TracerLine.From = UserInputService:GetMouseLocation()
                TracerLine.To = Vector2.new(targetScreenPos.X, targetScreenPos.Y)
                TracerLine.Visible = true
            else
                TracerLine.Visible = false
            end
        else
            TracerLine.Visible = false
        end

        -- Camera Lock Logic (normal aimbot)
        if not Settings.SilentAim then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPart.Position)
        end
    else
        -- If no target, hide tracer
        TracerLine.Visible = false
    end
end)


--// SILENT AIM NAMECASE HOOK
if namecallSupported and old_namecall then
    setnamecallmethod(function(self, ...)
        -- This function is now much more specific to prevent breaking your game.
        
        local method = getnamecallmethod()
        local args = {...}
        
        -- !! IMPORTANT !!
        -- The line below is the KEY to fixing the "can't shoot" issue.
        -- The old script checked for ANY RemoteEvent, which broke shooting, movement, etc.
        -- You must replace "YourFireRemoteNameHere" with the actual name of the remote event
        -- that your game's gun uses to fire.
        --
        -- How to find the name:
        -- 1. Use an executor tool like RemoteSpy or SimpleSpy.
        -- 2. Fire your gun and look for a remote event that is called.
        -- 3. Common names include: "Fire", "Update", "Ray", "FireBullet", "Damage".
        -- 4. Once you find it, put its exact name in the quotes below.
        --
        -- EXAMPLE: if the remote is named "FireBullet", the line should be:
        -- if Settings.Enabled and Settings.SilentAim and self.Name == "FireBullet" then
        
        if Settings.Enabled and Settings.SilentAim and self.Name == "YourFireRemoteNameHere" then
            local target = getClosestPlayer()
            if target and target.Character then
                local targetPart = target.Character:FindFirstChild(Settings.TargetPart) or target.Character:FindFirstChild("HumanoidRootPart")
                if targetPart then
                    -- This loop finds the first directional vector or CFrame in the arguments and replaces it.
                    -- Some games might use the 2nd argument (args[2]), 3rd (args[3]), etc.
                    -- You may need to adjust this if it doesn't work.
                    for i, v in ipairs(args) do
                        if typeof(v) == "Vector3" then
                            args[i] = targetPart.Position
                            break -- Stop after replacing one to prevent breaking things
                        elseif typeof(v) == "CFrame" then
                            args[i] = CFrame.new(Camera.CFrame.Position, targetPart.Position) -- Send a CFrame looking at the target
                            break
                        end
                    end
                end
            end
        end
        
        -- This passes the (possibly modified) arguments to the original function, ensuring the game continues to work.
        return old_namecall(self, unpack(args))
    end)
end


--// Script Cleanup
ScreenGui.Destroying:Connect(function()
    -- This is crucial to prevent errors when the script is destroyed.
    if namecallSupported and old_namecall then
        setnamecallmethod(old_namecall) -- Restore the original namecall function
    end
    FOVCircle:Remove()
    TracerLine:Remove()
end)
