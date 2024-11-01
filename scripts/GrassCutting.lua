local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'
    local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
    local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
    local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

    local Window = Library:CreateWindow({
        Title = 'Grass Cutting Incremental',
        Center = true,
        AutoShow = true,
    })

    -- Add Tabs
    local Tabs = {
        Main = Window:AddTab('Main'),
        Extra = Window:AddTab('Extra'),  -- Tab for FOV settings
        UI_Settings = Window:AddTab('UI Settings'),
    }

    local LeftGroupBox = Tabs.Main:AddLeftGroupbox('Walk Path')
    local TeleportGroupBox = Tabs.Main:AddLeftGroupbox('Teleport to Grass Objects')
    local LoopGroupBox = Tabs.Main:AddLeftGroupbox('Change Pickup Size') -- New group box
    local FOVGroupBox = Tabs.Extra:AddLeftGroupbox('Field of View Settings') -- Group box for FOV
    local ChangeDistanceGroupBox = Tabs.Extra:AddLeftGroupbox('Change Distance') -- New group box for Camera Max Zoom

    -- Trolling group box
    local TrollingGroupBox = Tabs.Extra:AddLeftGroupbox('Trolling') -- New Trolling GroupBox

    -- Button to freeze the screen for 5 seconds
    TrollingGroupBox:AddButton({
        Text = 'Freeze Screen for 5 sec',
        Func = function()
            print("Freezing screen for 5 seconds.")

            -- Create a blocking overlay
            local overlay = Instance.new("ScreenGui", game.Players.LocalPlayer:WaitForChild("PlayerGui"))
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 1, 0) -- Full screen
            frame.AnchorPoint = Vector2.new(0.5, 0.5) -- Center the frame
            frame.Position = UDim2.new(0.5, 0, 0.5, 0) -- Center the frame
            frame.BackgroundColor3 = Color3.new(0, 0, 0) -- Solid black color
            frame.BackgroundTransparency = 0 -- Opaque
            frame.Parent = overlay
            frame.ZIndex = 10 -- Make sure it appears above other elements

            -- Wait for the desired freezing duration
            wait(5) 

            overlay:Destroy() -- Remove the overlay
            print("Screen has been unfrozen.")
        end
    })

    -- Variables for FOV
    local playerCamera = game:GetService("Workspace").CurrentCamera
    local defaultFOV = 70 -- Default FOV value
    local fovSlider -- Variable to store the FOV slider instance

    -- FOV Slider
    fovSlider = FOVGroupBox:AddSlider('FOVSlider', {
        Text = 'Field of View',
        Default = defaultFOV,
        Min = 1,
        Max = 120,
        Rounding = 0,
        Callback = function(Value)
            playerCamera.FieldOfView = Value
            print("Field of View set to:", Value)
        end,
    })

    FOVGroupBox:AddButton({
        Text = 'Reset FOV',
        Func = function()
            playerCamera.FieldOfView = defaultFOV -- Reset camera FOV
            fovSlider:SetValue(defaultFOV) -- Reset slider value
        end,
    })

    local Players = game:GetService("Players")
    local player = Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local workspace = game:GetService("Workspace")
    local grassObjects = workspace:WaitForChild("GrassObjects")

    -- Variables for action loop
    local actionEnabled = false -- To track when the action loop is running
    local actionInterval = 1 -- Default interval for actions
    local actionCoroutine = nil -- Track action coroutine

    -- Variables for path following
    local pathPoints = {}
    local lineParts = {}
    local delayTime = 0 
    local delayEnabled = false
    local repeatPathEnabled = false

    -- Variable to determine if teleportation to grass objects is enabled
    local teleportToGrassEnabled = false
    local teleportSpeed = 1 -- Default speed multiplier for teleportation
    local teleportRange = 50 -- Default teleport range
    local teleportCoroutine = nil -- Track the teleportation coroutine

    -- Function to continuously teleport to grass objects
    local function startTeleportation()
        -- Only start a new coroutine if it's not already running
        if not teleportCoroutine then
            teleportCoroutine = coroutine.create(function()
                while teleportToGrassEnabled do
                    -- Get the player's humanoid root part for teleportation
                    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
                    local currentPosition = humanoidRootPart.Position

                    -- Boolean to track if we teleported during this loop
                    local didTeleport = false
                    
                    -- Loop through all children in GrassObjects
                    for _, object in ipairs(grassObjects:GetChildren()) do
                        if object.Name == "g" then
                            local distance = (object.Position - currentPosition).Magnitude
                            if distance <= teleportRange then
                                -- Calculate the time it takes to teleport
                                humanoidRootPart.CFrame = object.CFrame
                                didTeleport = true -- Mark that we have teleported
                                wait(0) -- Yield briefly to let the teleportation occur
                            end
                        end
                    end

                    if didTeleport then
                        wait(teleportSpeed) -- Wait for the teleport speed duration after a teleport occurs
                    else
                        wait(0.1) -- Brief wait if no teleportation occurred
                    end
                end
                teleportCoroutine = nil -- Reset the teleport coroutine when done
            end)
            coroutine.resume(teleportCoroutine)
        end
    end

    -- Placeholder function for the action to loop
    local function actionToLoop()
        -- Change the size of the GrassCollider or desired object
        local grassCollider = workspace:FindFirstChild("GrassCollider")
        if grassCollider then
            local collider = grassCollider:FindFirstChild("GrassCollider")
            if collider then
                collider.Size = Vector3.new(128, 128, 128) -- Set size to 128, 128, 128
                print("GrassCollider size set to (128, 128, 128)")
            else
                warn("GrassCollider child not found inside GrassCollider!")
            end
        else
            warn("GrassCollider not found in workspace!")
        end
    end

    local function drawPath()
        if #pathPoints < 2 then return end

        local startPoint = pathPoints[#pathPoints - 1]
        local endPoint = pathPoints[#pathPoints]
        local line = Instance.new("Part")

        line.Size = Vector3.new(0.4, 0.4, (endPoint - startPoint).Magnitude)
        line.Anchored = true
        line.BrickColor = BrickColor.new("Bright blue")
        line.Material = Enum.Material.Neon
        line.Position = (startPoint + endPoint) / 2
        line.CFrame = CFrame.lookAt(line.Position, endPoint)
        line.Parent = workspace

        line.CanCollide = false

        table.insert(lineParts, line)
    end

    -- Function to move the avatar along the path
    local function followPath(reverse)
        local humanoid = character:FindFirstChildOfClass("Humanoid")

        if not humanoid then
            print("No humanoid found!")
            return
        end

        local pointsToFollow = (reverse and pathPoints) or pathPoints

        for i = (reverse and #pointsToFollow or 1), (reverse and 1 or #pointsToFollow), (reverse and -1 or 1) do
            local currentPoint = pointsToFollow[i]

            humanoid:MoveTo(currentPoint)
            local reached = humanoid.MoveToFinished:Wait()

            if delayEnabled then
                wait(delayTime)
            end

            if not reached then
                print("Movement not completed to point:", currentPoint)
                break
            end
        end

        print("Path followed!")
    end

    -- Function to start the action loop
    local function startActionLoop()
        if actionCoroutine then return end -- Prevent starting a new loop if already running

        actionCoroutine = coroutine.create(function()
            while actionEnabled do
                actionToLoop() -- Execute the action
                wait(actionInterval) -- Wait for the specified interval
            end
        end)
        coroutine.resume(actionCoroutine)
    end

    -- Teleport to Grass Objects Toggle
    TeleportGroupBox:AddToggle('TeleportToGrassToggle', {
        Text = 'Enable Teleport to Grass Objects',
        Default = false,
        Tooltip = 'Enable this to teleport to grass objects named "g".',
        Callback = function(Value)
            teleportToGrassEnabled = Value
            if Value then
                startTeleportation() -- Start the teleportation loop
            else
                teleportToGrassEnabled = false -- Stop the teleportation loop
                if teleportCoroutine then
                    -- Wait for the coroutine to complete the current iteration
                    while coroutine.status(teleportCoroutine) == "running" do
                        wait(0.1)
                    end
                    teleportCoroutine = nil -- Reset the teleport coroutine
                end
            end
        end,
    })

    -- New Slider for Action Interval
    LoopGroupBox:AddSlider('ActionIntervalSlider', {
        Text = 'Change Pickup Size (s)',
        Default = 1,
        Min = 0.1,
        Max = 10,
        Rounding = 1,
        Increment = 0.1,  -- Allows adjusting by 0.1 increments
        Callback = function(Value)
            actionInterval = Value
            print("Pickup Size set to:", actionInterval)
            if actionEnabled then
                startActionLoop() -- Restart the action loop to reflect the new interval
            end
        end,
    })

    -- Toggle to enable/disable action loop
    LoopGroupBox:AddToggle('EnableActionLoop', {
        Text = 'Enable Change Size loop',
        Default = false,
        Tooltip = 'Enable this to start running the action every X seconds.',
        Callback = function(Value)
            actionEnabled = Value
            if Value then
                startActionLoop() -- Start the action loop
            else
                actionCoroutine = nil -- Stop the action loop
            end
        end,
    })

    -- Add GUI elements to your script window
    LoopGroupBox:AddButton({
        Text = 'Change Pickup Size',
        Func = function()
            -- Find the GrassCollider located inside the GrassCollider parent in Workspace
            local grassCollider = game.Workspace:FindFirstChild("GrassCollider")
            if grassCollider then
                local innerCollider = grassCollider:FindFirstChild("GrassCollider")
                if innerCollider then
                    -- Change the Size of the inner GrassCollider to 128, 128, 128
                    innerCollider.Size = Vector3.new(128, 128, 128)
                    print("GrassCollider size set to (128, 128, 128)")
                else
                    warn("Inner GrassCollider not found inside GrassCollider!")
                end
            else
                warn("GrassCollider not found in Workspace!")
            end
        end
    })

    -- Slider for Teleport Speed
    TeleportGroupBox:AddSlider('TeleportSpeedSlider', {
        Text = 'Teleport Speed',
        Default = 1,
        Min = 1,
        Max = 100,
        Rounding = 0,
        Callback = function(Value)
            teleportSpeed = Value
            print("Teleport speed set to:", teleportSpeed)
        end
    })

    -- Slider for Teleport Range
    TeleportGroupBox:AddSlider('TeleportRangeSlider', {
        Text = 'Teleport Range',
        Default = 50,
        Min = 10,
        Max = 200,
        Rounding = 0,
        Callback = function(Value)
            teleportRange = Value
            print("Teleport range set to:", teleportRange)
        end
    })

    -- Slider for walk speed
    LeftGroupBox:AddSlider('WalkSpeedSlider', {
        Text = 'Walk Speed',
        Default = 16,
        Min = 16,
        Max = 100,
        Rounding = 0,
        Callback = function(Value)
            if character:FindFirstChildOfClass("Humanoid") then
                character:FindFirstChildOfClass("Humanoid").WalkSpeed = Value
            end
        end
    })

    -- Checkbox to enable delay
    LeftGroupBox:AddToggle('DelayToggle', {
        Text = 'Enable Delay',
        Default = false,
        Tooltip = 'Enable this to set a delay between points.',
        Callback = function(Value)
            delayEnabled = Value
        end
    })

    -- Slider to set delay time
    LeftGroupBox:AddSlider('DelaySlider', {
        Text = 'Delay Time (s)',
        Default = 0,
        Min = 0,
        Max = 5,
        Rounding = 1,
        Callback = function(Value)
            if Value < 0 then Value = 0 end
            delayTime = Value
        end,
    })

    -- Checkbox to repeat the path
    LeftGroupBox:AddToggle('RepeatPathToggle', {
        Text = 'Repeat Path',
        Default = false,
        Tooltip = 'Enable this to repeat the path without removing it.',
        Callback = function(Value)
            repeatPathEnabled = Value
            if repeatPathEnabled then
                coroutine.wrap(function()
                    while repeatPathEnabled do
                        if #pathPoints > 1 then
                            followPath() -- Go forward
                            followPath(true) -- Go backward
                        else
                            print("Add more points to the path.")
                        end
                        wait(delayTime) -- Wait between repetitions
                    end
                end)() -- Start the loop in a coroutine
            end
        end
    })

    -- Reset path
    LeftGroupBox:AddButton({
        Text = 'Reset Path',
        Func = function()
            pathPoints = {}
            for _, line in ipairs(lineParts) do
                line:Destroy()
            end
            lineParts = {}
            print("Path cleared!")
        end,
    })

    -- Add current position to the path
    LeftGroupBox:AddButton({
        Text = 'Add Point to Path',
        Func = function()
            local position = character.HumanoidRootPart.Position
            table.insert(pathPoints, position)
            drawPath()
            print("Point added:", position)
        end,
    })

    -- Add the Camera Max Zoom Distance Slider to the Change Distance group box
    local camZoomSlider -- Variable to store the Camera Max Zoom Distance slider instance
    camZoomSlider = ChangeDistanceGroupBox:AddSlider('CameraMaxZoomDistanceSlider', {
        Text = 'Max Camera Zoom Distance',
        Default = player.CameraMaxZoomDistance, -- Set default to the current value
        Min = 0.5,
        Max = 10000,
        Rounding = 0,
        Callback = function(Value)
            player.CameraMaxZoomDistance = Value -- Update max zoom distance
            print("Camera Max Zoom Distance set to:", Value)
        end,
    })

    ChangeDistanceGroupBox:AddButton({
        Text = 'Reset Cam Zoom Distance',
        Func = function()
            player.CameraMaxZoomDistance = 128 -- Reset Camera Max Zoom Distance
            camZoomSlider:SetValue(128) -- Reset slider value
        end,
    })

    -- UI settings tab
    local MenuGroup = Tabs.UI_Settings:AddLeftGroupbox('Menu Options')
    MenuGroup:AddButton('Unload', function() Library:Unload() end)
    MenuGroup:AddLabel('Close menu with the key:'):AddKeyPicker('MenuKeybind', { Default = 'End', NoUI = true, Text = 'Menu Key' })

    -- Add the custom cursor toggle
    MenuGroup:AddToggle('ShowCustomCursor', {
        Text = 'Show Custom Cursor',
        Default = false,
        Tooltip = 'Enable this to show the custom cursor.',
        Callback = function(Value)
            if Value then
                -- Logic to show custom cursor
                UserInputService.MouseIconId = "rbxassetid://123456789" -- Replace with your custom cursor ID
            else
                -- Logic to hide custom cursor and revert to default
                UserInputService.MouseIconId = ""
            end
        end,
    })

    Library.ToggleKeybind = Options.MenuKeybind

    -- OnUnload function
    Library:OnUnload(function()
        print('Unloaded!')
        Library.Unloaded = true
    end)

    -- Hand the library over to our managers
    ThemeManager:SetLibrary(Library)
    SaveManager:SetLibrary(Library)

    -- Build our configuration menu on the right side of our tab
    SaveManager:SetFolder('MyScriptHub/specific-game')
    SaveManager:BuildConfigSection(Tabs['UI Settings'])

    -- Build our theme menu on the left side
    ThemeManager:ApplyToTab(Tabs['UI Settings'])

    -- Load the autoload configuration
    SaveManager:LoadAutoloadConfig()
end