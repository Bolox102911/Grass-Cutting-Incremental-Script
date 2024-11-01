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

    local LeftGroupBox = Tabs.Main:AddLeftGroupbox('Silent Aim')
    local ESPGroupBox = Tabs.Main:AddLeftGroupbox('ESP')
    local FOVGroupBox = Tabs.Extra:AddLeftGroupbox('Field of View Settings') -- Group box for FOV
    local ChangeDistanceGroupBox = Tabs.Extra:AddLeftGroupbox('Change Distance') -- New group box for Camera Max Zoom

    -- Trolling group box
    local TrollingGroupBox = Tabs.Extra:AddLeftGroupbox('Trolling') -- New Trolling GroupBox

    -- Main settings group box under UI Settings
    local MainGroup = Tabs.UI_Settings:AddLeftGroupbox('Main Options')
    MainGroup:AddButton('Unload', function() Library:Unload() end)
    MainGroup:AddLabel('Close menu with the key:'):AddKeyPicker('MenuKeybind', { Default = 'End', NoUI = true, Text = 'Menu Key' })

    -- Add the custom cursor toggle
    MainGroup:AddToggle('ShowCustomCursor', {
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

    LeftGroupBox:AddButton({
        Text = 'Silent Aim',
        Func = function()
            local HitboxSize = Vector3.new(10, 10, 10) -- too big won't work

            if getgenv().c then getgenv().c:Disconnect() end

            getgenv().c = game:GetService("RunService").RenderStepped:Connect(function()
                for _, v in pairs(workspace:GetChildren()) do
                    if v:IsA("BasePart") and v.Color == Color3.new(1, 0, 0) then
                        v.Transparency = 0.5
                        v.Size = HitboxSize
                    end
                end    
            end)
        end,
    })

    ESPGroupBox:AddButton({
        Text = 'ESP 1',
        Func = function()
            local function ezEsp(player)
                local esp = Instance.new("Highlight", player)
                wait(1)
                if player:FindFirstChild("friendly_marker") then
                    esp.FillColor = Color3.new(0, 0, 1)
                end
            end

            local function Lesp(player)
                for _, shit in pairs(player:GetChildren()) do
                    if shit.Name == "Highlight" then
                        shit:Destroy()
                    end
                end
            end

            for _, player in pairs(game.Workspace:GetChildren()) do
                if player.Name == "soldier_model" then
                    Lesp(player)
                    ezEsp(player)
                end
            end

            game.Workspace.DescendantAdded:Connect(function(player)
                if player.Name == "soldier_model" then
                    Lesp(player)
                    spawn(function() ezEsp(player) end)
                end
            end)
        end,
    })

    ESPGroupBox:AddButton({
        Text = 'ESP 2',
        Func = function()
            -- Required services
            local UserInputService = game:GetService("UserInputService")
            local Players = game:GetService("Players")
            local StarterGui = game:GetService("StarterGui")

            -- Set hitbox size, transparency level, and notification status
            local size = Vector3.new(10, 10, 10)
            local trans = 1
            local notifications = false
            local espEnabled = true

            -- Store the time when the code starts executing
            local start = os.clock()

            -- Send a notification saying that the script is loading
            StarterGui:SetCore("SendNotification", {
                Title = "Script",
                Text = "Loading script...",
                Icon = "",
                Duration = 5
            })

            -- Load the ESP library and turn it on
            local esp = loadstring(game:HttpGet("https://raw.githubusercontent.com/andrewc0de/Roblox/main/Dependencies/ESP.lua"))()
            esp:Toggle(espEnabled)

            -- Toggle notifications
            local function toggleNotifications()
                notifications = not notifications
                StarterGui:SetCore("SendNotification", {
                    Title = "Script",
                    Text = notifications and "Notifications Enabled" or "Notifications Disabled",
                    Duration = 3
                })
            end

            -- Toggle ESP
            local function toggleESP()
                espEnabled = not espEnabled
                esp:Toggle(espEnabled)
                StarterGui:SetCore("SendNotification", {
                    Title = "Script",
                    Text = espEnabled and "ESP Enabled" or "ESP Disabled",
                    Duration = 3
                })
            end

            -- Key press event listener for toggling
            UserInputService.InputBegan:Connect(function(input, isProcessed)
                if not isProcessed then
                    if input.KeyCode == Enum.KeyCode.N then
                        toggleNotifications()  -- Toggle notifications on 'N' key press
                    elseif input.KeyCode == Enum.KeyCode.E then
                        toggleESP()  -- Toggle ESP on 'E' key press
                    end
                end
            end)

            -- Utility function to apply hitboxes
            local function applyHitboxes(model)
                local pos = model:FindFirstChild("HumanoidRootPart").Position
                for _, bp in pairs(workspace:GetChildren()) do
                    if bp:IsA("BasePart") then
                        local distance = (bp.Position - pos).Magnitude
                        if distance <= 5 then
                            bp.Transparency = trans
                            bp.Size = size
                        end
                    end
                end
            end

            -- Add an object listener to the workspace to detect enemy models
            esp:AddObjectListener(workspace, {
                Name = "soldier_model",
                Type = "Model",
                Color = Color3.fromRGB(255, 0, 4),

                PrimaryPart = function(obj)
                    local root
                    repeat
                        root = obj:FindFirstChild("HumanoidRootPart")
                        task.wait()
                    until root
                    return root
                end,

                Validator = function(obj)
                    task.wait(1)
                    return not obj:FindFirstChild("friendly_marker")
                end,

                CustomName = function(obj)
                    local playerNameValue = obj:FindFirstChild("PlayerName") -- Hypothetical property
                    if playerNameValue then
                        print("Found PlayerName:", playerNameValue.Value) -- Debug print for found PlayerName
                        return playerNameValue.Value -- Use the actual name if found
                    else
                        print("PlayerName not found for object:", obj.Name) -- Debug print when PlayerName is not found
                        return "?" -- Fallback name if not found
                    end
                end,

                IsEnabled = "enemy"
            })

            -- Enable the ESP for enemy models
            esp.enemy = true

            -- Wait for the game to load fully before applying hitboxes
            task.wait(1)

            -- Apply hitboxes to all existing enemy models in the workspace
            for _, v in pairs(workspace:GetDescendants()) do
                if v.Name == "soldier_model" and v:IsA("Model") and not v:FindFirstChild("friendly_marker") then
                    applyHitboxes(v)
                end
            end

            -- Connect the handleDescendantAdded function to the DescendantAdded event
            task.spawn(function()
                workspace.DescendantAdded:Connect(function(descendant)
                    task.wait(1)
                    if descendant.Name == "soldier_model" and descendant:IsA("Model") and not descendant:FindFirstChild("friendly_marker") then
                        if notifications then
                            StarterGui:SetCore("SendNotification", {
                                Title = "Script",
                                Text = "[Warning] New Enemy Spawned! Applied hitboxes.",
                                Icon = "",
                                Duration = 3
                            })
                        end
                        applyHitboxes(descendant)
                    end
                end)
            end)

            -- Store the time when the code finishes executing
            local finish = os.clock()

            -- Calculate how long the code took to run and determine a rating for the loading speed
            local time = finish - start
            local rating
            if time < 3 then
                rating = "fast"
            elseif time < 5 then
                rating = "acceptable"
            else
                rating = "slow"
            end

            -- Send a notification about loading time
            StarterGui:SetCore("SendNotification", {
                Title = "Script",
                Text = string.format("Script loaded in %.2f seconds (%s loading)", time, rating),
                Icon = "",
                Duration = 5
            })
        end,
    })

    -- UI settings tab
    local MenuGroup = Tabs.UI_Settings:AddLeftGroupbox('Menu Options')
    MenuGroup:AddButton('Unload', function() Library:Unload() end)
    MenuGroup:AddLabel('Close menu with the key:'):AddKeyPicker('MenuKeybind', { Default = 'End', NoUI = true, Text = 'Menu Key' })

    -- Add the custom cursor toggle to UI Settings
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
