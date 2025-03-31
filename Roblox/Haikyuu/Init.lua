-->> LDSTN
--	loadstring(game:HttpGet('https://raw.githubusercontent.com/skibidiMusic/Lua/refs/heads/main/Roblox/Haikyuu/Init.lua'))()

-->> SRC
--https://github.com/depthso/Roblox-ImGUI/wiki/Elements

local BaseScript = loadstring(game:HttpGet('https://raw.githubusercontent.com/skibidiMusic/Lua/refs/heads/main/Roblox/Main/Base.lua'))()
local HaikyuuRaper = BaseScript.new("HaikyuuRaper")

local Janitor = HaikyuuRaper.Janitor

local Window = HaikyuuRaper.window
local hooks = HaikyuuRaper.hooks

--##
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local VirtualInputManager = game:GetService("VirtualInputManager")


-- Direction Ray
do
    local RAY_LENGTH = 120
    local ANGLE = 10
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
    local CharacterTab = Window:CreateTab({
        Name = "Character",
        Visible = false 
    })

    do
        local thread;
        local connections = Janitor.new() ;
    
        local DLY_SLIDER = .33
    
        local function charAdded(char: Model)
            connections:Add(char:GetAttributeChangedSignal("Jumping"):Connect(function()
                if char:GetAttribute("Jumping") then
                    --if not __ENABLED then return end
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if not hum then return end
                    thread = task.spawn(function()
                        hum.AutoRotate = true
                        task.wait(DLY_SLIDER)
                        hum.AutoRotate = false
                    end)
                else
                    if thread then
                        task.cancel(thread)
                        thread = nil
                    end
                end
            end), nil, "jumpCon")
        end
    
        local function setEnabled(v)
            if v then
                connections:Add(Players.LocalPlayer.CharacterAdded:Connect(charAdded))
                if Players.LocalPlayer.Character then
                    charAdded(Players.LocalPlayer.Character)
                end
            else   
                connections:Cleanup()
            end
        end
    
        hooks:Add(function()
            setEnabled(false)
        end)
    
        CharacterTab:Checkbox({
            Label = "Rotate In Air",
            Value = true,
            saveFlag = "CharacterRotateToggle",
            Callback = function(_, v)
                setEnabled(v)
            end,
        })
    
        CharacterTab:Slider({
            Label = "Rotate Off Delay",
            Format = "%.2f/%s", 
            Value = DLY_SLIDER,
            MinValue = 0,
            MaxValue = 4,
            saveFlag = "RotateOffDelaySlider",
            Callback = function(self, Value)
                DLY_SLIDER = Value
            end,
        })
    
        CharacterTab:Separator({ })
    end
    
    -- Shiftlock in Air
    do
                local connections = Janitor.new()
    
                local function charAdded(char: Model)
                    connections:Add(char:GetAttributeChangedSignal("Jumping"):Connect(function()
                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.LeftShift, false, Players.LocalPlayer)
                        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.LeftShift, false, Players.LocalPlayer)
                    end), nil, "jumpCon")
                end
            
                local function setEnabled(v)
                    if v then
                        connections:Add(Players.LocalPlayer.CharacterAdded:Connect(charAdded))
                        if Players.LocalPlayer.Character then
                            charAdded(Players.LocalPlayer.Character)
                        end
                    else   
                        connections:Cleanup()
                    end
                end
            
                hooks:Add(function()
                    setEnabled(false)
                end)
    
                CharacterTab:Checkbox({
                    Label = "Auto Shiftlock Air",
                    Value = true,
                    saveFlag = "AirShiftlockToggle",
                    Callback = function(_, v)
                        setEnabled(v)
                    end,
                })
    
                CharacterTab:Separator({})
    end
    

    
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

    attributeModifier("Dive Speed Mult.", "GameDiveSpeedMultiplier", 1.5, 0, 5)
    --GameJumpPowerMultiplier
    attributeModifier("Jump Power Mult.", "GameJumpPowerMultiplier", 1.15, 0, 5)
    --GameSpeedMultiplier
    attributeModifier("Speed Mult.", "GameSpeedMultiplier", 0.85, 0, 5)
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
            Value = 100,
            MinValue = 0,
            MaxValue = 100,
            saveFlag = "ServeFixedPowerSlider",
        
            Callback = function(self, Value)
                value = Value / 100
                print(value)
            end,
        })
    
        InternalTab:Checkbox({
            Label = "Serve Power Enabled",
            Value = true,
            saveFlag = "ServePowerToggle",
            Callback = function(_, v)
                setEnabled(v)
            end,
        })

        InternalTab:Separator({})
    end


    -- No Cooldowns
    if getloadedmodules and hookfunction and checkcaller and newcclosure then
        for _, v in getloadedmodules() do
            if v.Name == "GameController" then
                    local t = require(v)
                    local val = t.IsBusy

                    local ENABLED = false

                    -- ui
                    InternalTab:Checkbox({
                        Label = "No Cooldowns",
                        Value = ENABLED,
                        saveFlag = "NoCooldownsToggle",
                        Callback = function(_, v)
                            ENABLED = v
                        end,
                    })

                    hooks:Add(function()
                        ENABLED = false
                    end)
                    
                    if ENABLED then
                        val:set(false)  
                    end

                    local old; old = hookfunction(val.set, newcclosure(function(self, ...)
                        if ENABLED and not checkcaller() and rawequal(self, val) and not Players.LocalPlayer:GetAttribute("IsServing") then
                            return old(self, false)
                        end     
                        return old(self, ...)
                    end))
            end
        end
        InternalTab:Separator({})
    end

    -- Hitbox Expander
    if hookmetamethod then
        local ENABLED = false
        local MULTIPLIER = 1

        local old ; old = hookmetamethod(game, "__namecall", function(self, ...)
            local args = {...}
            if ENABLED and not checkcaller() and rawequal(self, workspace) and getnamecallmethod() == "GetPartsInPart" then
                    local hitboxPart = args[1]
                    local overlapParams = args[2] :: OverlapParams
    
                    if rawequal(args[3], nil) and (typeof(hitboxPart) == "Instance" and hitboxPart.IsA(hitboxPart, "BasePart") and typeof(overlapParams) == "OverlapParams") then
                            local testPart = overlapParams.FilterDescendantsInstances[1]
                            if testPart and testPart.HasTag(testPart, "Ball") then
                                    
                                    local oldSize = hitboxPart.Size
                                    hitboxPart.Size = oldSize * MULTIPLIER
                                    local result = old(self, ...)
                                    hitboxPart.Size = oldSize
                                    return result
    
                            end
                    end
            end
    
            return old(self, unpack(args))
        end)

        InternalTab:Slider({
            Label = "Hitbox Multiplier",
            Format = "%.2f/%s", 
            Value = MULTIPLIER,
            MinValue = 0,
            MaxValue = 10,
            saveFlag = "HitboxMultiplier",
        
            Callback = function(self, Value)
                MULTIPLIER = Value
            end,
        })
    
        InternalTab:Checkbox({
            Label = "Hitbox Expander Enabled",
            Value = true,
            saveFlag = "HitboxToggle",
            Callback = function(_, v)
                ENABLED = v
            end,
        })

        hooks:Add(function()
            ENABLED = false
        end)
        InternalTab:Separator({})
    end

    -- Op Charge
    if getloadedmodules and hookfunction and checkcaller and newcclosure then
        for _, v in getloadedmodules() do
            if v.Name == "GameController" then
                    local t = require(v)
                    local val = t.Power

                    local SLIDER = 1
                    local ENABLED = false

                    -- ui
                    InternalTab:Checkbox({
                        Label = "Custom Charge",
                        Value = ENABLED,
                        saveFlag = "CustomChargeToggle",
                        Callback = function(_, v)
                            ENABLED = v
                        end,
                    })

                    InternalTab:Slider({
                        Label = "Charge Val",
                        Format = "%.2f/%s", 
                        Value = SLIDER,
                        MinValue = 0,
                        MaxValue = 10,
                        saveFlag = "ChargeValSlider",
                    
                        Callback = function(self, Value)
                            SLIDER = Value
                        end,
                    })

                    hooks:Add(function()
                        ENABLED = false
                    end)

                    local old; old = hookfunction(val.getCharge, newcclosure(function(self, ...)
                        if ENABLED and not checkcaller() and rawequal(self, val) then
                            return SLIDER
                        end     
                        return old(self, ...)
                    end))
            end
        end
        InternalTab:Separator({})
    end
    
end

HaikyuuRaper:UiTab()
HaikyuuRaper:ConfigManager()
HaikyuuRaper:UnloadTab()
