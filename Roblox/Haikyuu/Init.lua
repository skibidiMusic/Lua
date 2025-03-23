-->> LDSTN
--	loadstring(game:HttpGet('https://raw.githubusercontent.com/skibidiMusic/Lua/refs/heads/main/Roblox/Haikyuu/Init.lua'))()

-->> SRC
--https://github.com/depthso/Roblox-ImGUI/wiki/Elements
local ImGui = loadstring(game:HttpGet('https://raw.githubusercontent.com/skibidiMusic/Lua/refs/heads/main/Roblox/Util/UiLib/ImGui.lua'))()
local Janitor = loadstring(game:HttpGet('https://raw.githubusercontent.com/skibidiMusic/Lua/refs/heads/main/Roblox/Util/Misc/Janitor.lua'))()

if HaikyuuRaper then
    if HaikyuuRaper.unload then
        HaikyuuRaper.unload()
    end
else
    getgenv().HaikyuuRaper = {}
end

local Window = ImGui:CreateWindow({Title = "HaikyuuRaper", Position = UDim2.new(0.5, 0, 0, 70), Size = UDim2.new(0, 800, 0, 500), AutoSize = false,})
Window:Center()

local hooks = Janitor.new()
HaikyuuRaper.unload = function()
    hooks:Cleanup()
	Window:Destroy()
	HaikyuuRaper.unload = nil
end

--##
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")


-- Direction Ray
do
    local RAY_LENGTH = 25
    local ANGLE = 30
    local AIR_CHECK = true

    -- Table to store player colors and rays
    local playerData = {}
    -- Function to get a random color for a players
    local function getPlayerColor(player)
        if not playerData[player] then
            playerData[player] = {Color = BrickColor.random().Color, Ray = nil}
        end
        return playerData[player].Color
    end
    -- Function to create/update a ray for a player
    local function updateRay(player)
        local character = player.Character
        if not character then return end
    
        local humanoid = character:FindFirstChildOfClass("Humanoid") :: Humanoid
        if not humanoid or humanoid:GetState() == Enum.HumanoidStateType.Seated then return end
    
        local state = humanoid:GetState()
        local inAir = state == Enum.HumanoidStateType.Freefall or state == Enum.HumanoidStateType.Jumping or humanoid.FloorMaterial == Enum.Material.Air
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end
    
        if not AIR_CHECK or inAir then
            -- Apply a downward tilt of ~30 degrees
            local tiltAngle = math.rad(ANGLE)
            local tiltedCFrame = rootPart.CFrame * CFrame.Angles(-tiltAngle, 0, 0)
            local direction = tiltedCFrame.LookVector * RAY_LENGTH
        
            -- Create or update the ray part
            local rayPart = playerData[player].Ray
            if not rayPart then
                rayPart = Instance.new("Part")
                rayPart.Anchored = true
                rayPart.CanCollide = false
                rayPart.Material = Enum.Material.Neon
                rayPart.Color = getPlayerColor(player)
                rayPart.Parent = workspace
                playerData[player].Ray = rayPart
            end

            rayPart.Size = Vector3.new(0.2, 0.2, RAY_LENGTH)
            rayPart.CFrame = CFrame.lookAt(rootPart.Position, rootPart.Position + direction) * CFrame.new(0, 0, -RAY_LENGTH * 0.5)
            rayPart.Transparency = 0.5 -- Make it visible
        else
            -- Hide the ray when not in the air
            if playerData[player].Ray then
                playerData[player].Ray.Transparency = 1
            end
        end
    end

    local connection;
    local function setEnabled(v: boolean)
        if v then
            if not connection then
                connection = RunService.RenderStepped:Connect(function()
                    for _, v in Players:GetPlayers() do
                        updateRay(v)
                    end
                end)
            end
        else
            if connection then
                connection:Disconnect(); connection = nil
            end
        end
    end


    local function loadPlayer(player: Player)
        getPlayerColor(player) -- Assign a color to the player
    end

    local function unloadPlayer(player: Player)
        if playerData[player] and playerData[player].Ray then
            playerData[player].Ray:Destroy()
        end
        playerData[player] = nil 
    end

    hooks:Add(function()
        setEnabled(false)

        for _, v in Players:GetPlayers() do
            unloadPlayer(v)
        end
    end)

    hooks:Add(Players.PlayerAdded:Connect(loadPlayer))
    for _, v in Players:GetPlayers() do
        loadPlayer(v)
    end
    

    local RayTab = Window:CreateTab({
        Name = "Ray",
        Visible = true 
    })

    RayTab:Checkbox({
        Label = "Enabled",
        Value = true,
        saveFlag = "RayEnabledToggle",
        Callback = function(_, v)
            setEnabled(v)
        end,
    })

    RayTab:Separator({
        Text = "Config"
    })

    RayTab:Checkbox({
        Label = "Jump Check",
        Value = AIR_CHECK,
        saveFlag = "RayJumpCheckToggle",
        Callback = function(_, v)
            AIR_CHECK = v
        end,
    })

    RayTab:Slider({
        Label = "Length",
        Format = "%.d/%s", 
        Value = RAY_LENGTH,
        MinValue = 0,
        MaxValue = 120,
        saveFlag = "RayLengthSlider",
    
        Callback = function(self, Value)
            RAY_LENGTH = Value
        end,
    })

    RayTab:Slider({
        Label = "Angle",
        Format = "%.d/%s", 
        Value = ANGLE,
        MinValue = 0,
        MaxValue = 50,
        saveFlag = "RayAngleSlider",
    
        Callback = function(self, Value)
            ANGLE = Value
        end,
    })

end

-- Character Tweaks
do
    local connection;
    local function setEnabled(v)
        if v then
            if not connection then
                connection = RunService.RenderStepped:Connect(function()
                    local player = Players.LocalPlayer
                    if player.Character then
                        local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
                        if humanoid then
                            humanoid.AutoRotate = true
                        end
                    end
                end)
            end
        else
            if connection then
                connection:Disconnect(); connection = nil
            end
        end
    end

    hooks:Add(function()
        setEnabled(false)
    end)

    local CharacterTab = Window:CreateTab({
        Name = "Character",
        Visible = false 
    })

    CharacterTab:Checkbox({
        Label = "Rotate In Air",
        Value = true,
        saveFlag = "CharacterRotateToggle",
        Callback = setEnabled,
    })

    
    CharacterTab:Separator({
        Text = "Attributes"
    })

    -- Attribute Modifiers
    local function attributeModifier(name: string, attributeName: string, baseVal: number, min: number, max: number)
        local defaultText;

        local currentValue = baseVal
        local db = false
        local gameValue = Players.LocalPlayer:GetAttribute(attributeName)
        hooks:Add(Players.LocalPlayer:GetAttributeChangedSignal(name):Connect(function()
            if db then db = false return end

            gameValue = Players.LocalPlayer:GetAttribute(name)
            defaultText.Text = `default: {gameValue}`

            db = true
            Players.LocalPlayer:SetAttribute(name, currentValue)
        end))


        local dropdown = CharacterTab:CollapsingHeader({
            Title = name,
            Open = true
        })

        local row = dropdown:Row()

        local slider = dropdown:Slider({
            Label = name,
            Format = "%.2f/%s", 
            Value = baseVal,
            MinValue = min,
            MaxValue = max,
            saveFlag = name.."sliderAttribute",
            Callback = function(self, Value)
                currentValue = Value
                db = true
                Players.LocalPlayer:SetAttribute(attributeName, Value)
            end,
        })

        row:Button({
            Text = "Reset",
            Callback = function(self)
                slider:SetValue(gameValue)
            end
        })

        defaultText = row:Label({
            Text = `default: {gameValue}`,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center,
			RichText = false,
        })

        row:Fill()

        hooks:Add(function()
            db = true
            Players.LocalPlayer:SetAttribute(attributeName, gameValue)
        end)
    end

    attributeModifier("Dive Speed Mult.", "GameDiveSpeedMultiplier", 1, 0, 5)
    --GameJumpPowerMultiplier
    attributeModifier("Jump Power Mult.", "GameJumpPowerMultiplier", 1, 0, 5)
    --GameSpeedMultiplier
    attributeModifier("Speed Mult.", "GameSpeedMultiplier", 1, 0, 5)
end

-- Internals
do
    local InternalTab = Window:CreateTab({
        Name = "Internals",
        Visible = false 
    })

    -- Serve Power
    if hookmetamethod then
        local enabled = true
        local value = 0

        local function setEnabled(v)
            enabled = v
        end
    
        hooks:Add(function()
            setEnabled(false)
        end)

        local old;
        old = hookmetamethod(game, "__namecall", function(self, ...)
            local args = {...}
            if enabled and not checkcaller() then
                if getnamecallmethod() == "InvokeServer" and typeof(self) == "Instance" and self.ClassName == "RemoteFunction" and self.Name == "Serve" then
                    args[2] = value
                end
            end
            return old(self, table.unpack(args))
        end)

        -- ui
        InternalTab:Slider({
            Label = "Serve Power",
            Format = "%.d/%s", 
            Value = ANGLE,
            MinValue = 0,
            MaxValue = 100,
            saveFlag = "ServeFixedPowerSlider",
        
            Callback = function(self, Value)
                value = Value / 100
            end,
        })
    
        InternalTab:Checkbox({
            Label = "Serve Power Enabled",
            Value = true,
            saveFlag = "RayEnabledToggle",
            Callback = function(_, v)
                setEnabled(v)
            end,
        })

        InternalTab:Separator({})
    end

    -- Hitbox Expander
end


--ui tab
local KeybindsTab = Window:CreateTab({
	Name = "Ui",
	Visible = false 
})

--keybinds
do
	KeybindsTab:Separator({
		"lol 🙏😭"
	})
	
	do
		local toggleUiKeybind = KeybindsTab:Keybind({
			Label = "Toggle UI",
			Value = Enum.KeyCode.RightControl,
			saveFlag = "ToggleUiKeybind",
			Callback = function()
				Window:SetVisible(not Window.Visible)
			end,
		})
		
		local wasClosedBefore = false
		Window.CloseCallback = function()
			if toggleUiKeybind.Value then
				if wasClosedBefore then
					--ImGui:Notify("Press " .. `{toggleUiKeybind.Value}` .. " to re-open the gui." , 1)
					return
				end
				wasClosedBefore = true
				ImGui:Notify("Gui", "Press " .. `{toggleUiKeybind.Value.Name}` .. " to re-open the gui." , 4)
			end
		end
	end
end

Window:CreateConfigSaveHandler("HaikkyuuSaksooo3131")

-- unloading gui
local closeTab = Window:CreateTab({
	Name = "Unload",
	Visible = false
})

closeTab:Separator({

})

closeTab:Button({
    Text = "Unload the cheat",
    Callback = function(self)
        MTC_SAKSO.unload()
		ImGui:Notify("Sakso", "Fenasin basa belasin kankitom" , 3)
    end,
})
