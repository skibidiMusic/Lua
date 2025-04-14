-->> LDSTN
--	loadstring(game:HttpGet('https://raw.githubusercontent.com/skibidiMusic/Lua/refs/heads/main/Roblox/Haikyuu/Init.lua'))()

-->> SRC
--https://github.com/depthso/Roblox-ImGUI/wiki/Elements

local isPublic = loadstring(game:HttpGet('https://raw.githubusercontent.com/skibidiMusic/Lua/refs/heads/main/Roblox/Util/Misc/PublicKey.lua'))()
if not isPublic then game.Players.LocalPlayer:Kick("Broken") return end

local BaseScript = loadstring(game:HttpGet('https://raw.githubusercontent.com/skibidiMusic/Lua/refs/heads/main/Roblox/Main/Base.lua'))()
local HaikyuuRaper = BaseScript.new("HaikyuuRaper")

local Janitor = HaikyuuRaper.Janitor
local Signal = HaikyuuRaper.Signal

local Window = HaikyuuRaper.window
local hooks = HaikyuuRaper.hooks

--##
local Players = game:GetService("Players")
--local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
--local ReplicatedFirst = game:GetService("ReplicatedFirst")
local CollectionService = game:GetService("CollectionService")
--local UserInputService = game:GetService("UserInputService")
--local VirtualInputManager = game:GetService("VirtualInputManager")
local UserGameSettings = UserSettings():GetService("UserGameSettings")

local LocalPlayer = Players.LocalPlayer

-- Game Stuff
local function getCourtPart()
    for _, v in CollectionService:GetTagged("Court") do
        if v:IsDescendantOf(workspace:WaitForChild("Map")) then
            return v
        end
    end
end

local CourtPart = getCourtPart()

-- Ball Stuff
local BallTrajectory;
if hookfunction and newcclosure and getloadedmodules then
    BallTrajectory = {}

    local function getCourtPart()
        for _, v in CollectionService:GetTagged("Court") do
            if v:IsDescendantOf(workspace.Map) then
                return v
            end
        end
    end
    
    local BallModule, GameModule
    for _, v in getloadedmodules() do
        if v.Name == "Ball" then
            BallModule = require(v)
        elseif v.Name == "Game" then
            GameModule = require(v)
        end
    end
    
    local newBallSignal, ballDestroySignal, trajectoryUpdatedSignal = Signal.new(), Signal.new(), Signal.new()

    BallTrajectory.newBallSignal, BallTrajectory.ballDestroySignal, BallTrajectory.trajectoryUpdatedSignal = newBallSignal, ballDestroySignal, trajectoryUpdatedSignal
    
    local function trajectoryResult(ball)
        local gravityMultiplier = ball.GravityMultiplier or 1
        local acceleration = ball.Acceleration or Vector3.new(0, 0, 0)
        local ballPart = ball.Ball.PrimaryPart
        local velocity, position = ballPart.AssemblyLinearVelocity, ballPart.Position
        local floorY = CourtPart.Position.Y + GameModule.Physics.Radius
        local GRAVITY = -GameModule.Physics.Gravity * gravityMultiplier


        local a, b, c = 0.5 * (acceleration.Y + GRAVITY), velocity.Y, position.Y - floorY
        local discriminant = b * b - 4 * a * c

        --warn("a:", a, "b:", b, "c:", c, "discriminant:", discriminant)

        if discriminant < 0 then return nil, nil end
        
        local t1, t2 = (-b + math.sqrt(discriminant)) / (2 * a), (-b - math.sqrt(discriminant)) / (2 * a)
        local timeToHit = (t1 > 0 and t2 > 0) and math.min(t1, t2) or (t1 > 0 and t1) or (t2 > 0 and t2) or nil

        --warn("t1:", t1, "t2:", t2, "timeToHit:", timeToHit)
        if not timeToHit then return nil, nil end
        
        local landingX = position.X + velocity.X * timeToHit + 0.5 * acceleration.X * timeToHit * timeToHit
        local landingZ = position.Z + velocity.Z * timeToHit + 0.5 * acceleration.Z * timeToHit * timeToHit

        return Vector3.new(landingX, floorY, landingZ), timeToHit
    end

    local function predictBallLanding(ball)
        local resultVector, dT = trajectoryResult(ball)

        BallTrajectory.LastTrajectory = resultVector
        BallTrajectory.LastTime = dT

        trajectoryUpdatedSignal:Fire(ball, resultVector, dT)
    end

    local function getAllBalls()
        return BallModule.All
    end
    BallTrajectory.getAllBalls = getAllBalls

    local UNHOOKED = false
    
    local oldNew; oldNew = hookfunction(BallModule.new, newcclosure(function(...)
        if UNHOOKED then return oldNew(...) end
        local newBall = oldNew(...)
        newBallSignal:Fire(newBall)
        predictBallLanding(newBall)
        return newBall
    end))
    
    local oldUpdate; oldUpdate = hookfunction(BallModule.Update, newcclosure(function(self, ...)
        if UNHOOKED then return oldUpdate(self, ...) end
        oldUpdate(self, ...)
        predictBallLanding(self)
    end))

    --[[
    hooks:Add(RunService.Heartbeat:Connect(function()
        for _, v in getAllBalls() do
            predictBallLanding(v)
        end
    end))
    ]]
    
    local oldDestroy; oldDestroy = hookfunction(BallModule.Destroy, newcclosure(function(self, ...)
        if UNHOOKED then return oldDestroy(self, ...) end
        ballDestroySignal:Fire(self)
        oldDestroy(self, ...)
    end))


    hooks:Add(function()
        UNHOOKED = true
    end)
    
end

-- Direction Ray
do
    local RAY_LENGTH = 120
    local ANGLE = 10
    local AIR_CHECK = true

    -- Table to store player colors and rays
    local playerData = {}
    local BrightColors = {
        Color3.fromRGB(255, 99, 71),    -- Tomato Red
        Color3.fromRGB(255, 165, 0),    -- Orange
        Color3.fromRGB(255, 255, 0),    -- Yellow
        Color3.fromRGB(0, 255, 0),      -- Lime
        Color3.fromRGB(0, 255, 255),    -- Cyan
        Color3.fromRGB(30, 144, 255),   -- Dodger Blue
        Color3.fromRGB(138, 43, 226),   -- Blue Violet
        Color3.fromRGB(255, 20, 147),   -- Deep Pink
        Color3.fromRGB(255, 105, 180),  -- Hot Pink
    }
    -- Function to get a random color for a players
    local function getPlayerColor(player)
        if not playerData[player] then
            playerData[player] = {Color = BrightColors[math.random(#BrightColors)], Ray = nil}
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
            rayPart.Transparency = 0.6 -- Make it visible
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
    hooks:Add(Players.PlayerRemoving:Connect(unloadPlayer))

    for _, v in Players:GetPlayers() do
        loadPlayer(v)
    end
    

    local RayTab = Window:CreateTab({
        Name = "Ray",
        Visible = true 
    })

    RayTab:Separator({
        Text = "Main"
    })

    RayTab:Checkbox({
        Label = "Enabled",
        Value = true,
        IniFlag = "RayEnabledToggle",
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
        IniFlag = "RayJumpCheckToggle",
        Callback = function(_, v)
            AIR_CHECK = v
        end,
    })

    RayTab:SliderInt({
        Label = "Length",
        Value = RAY_LENGTH,
        Minimum = 0,
        Maximum = 120,
        IniFlag = "RayLengthSlider",
    
        Callback = function(self, Value)
            RAY_LENGTH = Value
        end,
    })

    RayTab:SliderInt({
        Label = "Angle",
        Value = ANGLE,
        Minimum = 0,
        Maximum = 50,
        IniFlag = "RayAngleSlider",
        Callback = function(self, Value)
            ANGLE = Value
        end,
    })

end

-- Character Tweaks
do
    local CharacterTab = Window:CreateTab({
        Name = "Character",

    })

    -- Rotate Air
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
                connections:Add(LocalPlayer.CharacterAdded:Connect(charAdded))
                if LocalPlayer.Character then
                    charAdded(LocalPlayer.Character)
                end
            else   
                connections:Cleanup()
            end
        end
    
        hooks:Add(function()
            setEnabled(false)
        end)
   
        CharacterTab:Separator({
            Text = "Air Rotate"
        })

        CharacterTab:Checkbox({
            Label = "Enabled",
            Value = true,
            IniFlag = "CharacterRotateToggle",
            Callback = function(_, v)
                setEnabled(v)
            end,
        })
    
        CharacterTab:SliderFloat({
            Label = "Max Time",
            Format = "%.2f", 
            Value = DLY_SLIDER,
            Minimum = 0,
            Maximum = 4,
            IniFlag = "RotateOffDelaySlider",
            Callback = function(self, Value)
                DLY_SLIDER = Value
            end,
        })
    end

    -- GetIsMouseLocked
    -- Hidden Shiftlock
    do
        local connections = Janitor.new()

        local IN_AIR = false
        local ENABLED = true

        local default = Enum.RotationType.CameraRelative
        --setreadonly(Enum.RotationType, false)

        local old; old = hookmetamethod(game, "__newindex", newcclosure(function(self, index, val, ...)
            if not checkcaller() and ENABLED and IN_AIR and rawequal(self, UserGameSettings) and rawequal(index, "RotationType") then
                return old(self, index, Enum.RotationType.MovementRelative)
            end
            return old(self, index, val, ...)
        end))

        local function setActive(v)
            IN_AIR = v
        end

        local function charAdded(char: Model)
            setActive(true)
            connections:Add(char:GetAttributeChangedSignal("Jumping"):Connect(function()
                if char:GetAttribute("Jumping") then
                    setActive(false)
                else
                    setActive(true)
                end
            end), nil, "jumpCon")
        end
    
        local function setEnabled(v)
            ENABLED = v
            if v then
                connections:Add(LocalPlayer.CharacterAdded:Connect(charAdded))
                if LocalPlayer.Character then
                    charAdded(LocalPlayer.Character)
                end
            else   
                setActive(false)
                connections:Cleanup()
            end
        end
    
        hooks:Add(function()
            setEnabled(false)
        end)

        CharacterTab:Separator({
            Text = "Hidden Shiftlock"
        })

        local checkBox = CharacterTab:Checkbox({
            Label = "Enabled",
            Value = true,
            IniFlag = "AirShiftlockToggle",
            Callback = function(_, v)
                setEnabled(v)
            end,
        })

        local kb = CharacterTab:Keybind({
            Label = "Keybind",
            Value = Enum.KeyCode.R,
            IniFlag = "AirShiftlockKeybind",
            Callback = function()
                checkBox:Toggle()
            end,
        })
      end

    -- Walkspeed
    do
        local WALKSPEED_VALUE = 26
        local ENABLED = true

        local connections = Janitor.new()

        local defaultWalkspeed = nil
        local currentHum = nil
        local function WalkSpeedChange()
            if currentHum then
                currentHum.WalkSpeed = WALKSPEED_VALUE
            end
        end  

        local function charAdded(char)
            currentHum = char:WaitForChild("Humanoid", 2)
            if not currentHum then return end

            connections:Add(currentHum:GetPropertyChangedSignal("WalkSpeed"):Connect(WalkSpeedChange), nil, "WalkSpeedChange")
            WalkSpeedChange()
        end
        
        local function setEnabled(v)
            ENABLED = v
            if v then
                connections:Add(LocalPlayer.CharacterAdded:Connect(charAdded))
                if LocalPlayer.Character then
                    charAdded(LocalPlayer.Character)
                end
            else
                if currentHum then
                    currentHum.WalkSpeed = defaultWalkspeed
                end
                connections:Cleanup()
            end
        end

        hooks:Add(function()
            setEnabled(false)
        end)

        CharacterTab:Separator({
            Text = "Walkspeed"
        })

        CharacterTab:Checkbox({
            Label = "Enabled",
            Value = ENABLED,
            IniFlag = "WalkspeedEnabled",
            Callback = function(_, v)
                setEnabled(v)
            end,
        })

        CharacterTab:SliderInt({
            Label = "Speed",
            Value = WALKSPEED_VALUE,
            Minimum = 0,
            Maximum = 40,
            IniFlag = "WalkspeedValueSlider",
            Callback = function(self, Value)
                WALKSPEED_VALUE = math.round(Value)
                if ENABLED then
                    WalkSpeedChange()
                end
            end,
        })
        
    end
    
    CharacterTab:Separator({
        Text = "Attributes"
    })

    CharacterTab:Label({
        Text = ``
    })

    -- Attribute Modifiers
    local function attributeModifier(name: string, attributeName: string, baseVal: number, min: number, max: number)
        local defaultText;

        local currentValue = baseVal
        local db = false
        local gameValue = LocalPlayer:GetAttribute(attributeName)
        hooks:Add(LocalPlayer:GetAttributeChangedSignal(name):Connect(function()
            if db then db = false return end

            gameValue = LocalPlayer:GetAttribute(name)
            defaultText.Text = `default: {gameValue}`

            db = true
            LocalPlayer:SetAttribute(name, currentValue)
        end))

        CharacterTab:Separator({
            Text = name,
        })

        local row = CharacterTab:Row()

        local slider = CharacterTab:SliderFloat({
            Label = name,
            Format = "%.2f", 
            Value = baseVal,
            Minimum = min,
            Maximum = max,
            IniFlag = name.."sliderAttribute",
            Callback = function(self, Value)
                currentValue = Value
                db = true
                LocalPlayer:SetAttribute(attributeName, Value)
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

        --row:Fill()

        hooks:Add(function()
            db = true
            LocalPlayer:SetAttribute(attributeName, gameValue)
        end)
    end

    attributeModifier("Dive Speed Mult.", "GameDiveSpeedMultiplier", 1.5, 0, 5)
    --GameJumpPowerMultiplier
    attributeModifier("Jump Power Mult.", "GameJumpPowerMultiplier", 1.15, 0, 5)
    --GameSpeedMultiplier
    attributeModifier("Speed Mult.", "GameSpeedMultiplier", 0.85, 0, 5)
end

-- Camera
local currentCam = workspace.CurrentCamera
if currentCam then
    local CameraTab = Window:CreateTab({
        Name = "Camera",
    })

    -- Fov
    do
        local DEFAULT_FOV = currentCam.FieldOfView
        local FOV_VALUE = 90
        local ENABLED = true
        
        local connections = Janitor.new()

        local function fovUpdated()
            currentCam.FieldOfView = FOV_VALUE
        end

        local function setEnabled(v)
            ENABLED = v
            if v then
                fovUpdated()
                connections:Add(currentCam:GetPropertyChangedSignal("FieldOfView"):Connect(fovUpdated))
            else
                connections:Cleanup()
                currentCam.FieldOfView = DEFAULT_FOV
            end
        end

        hooks:Add(function()
            setEnabled(false)
        end)

        CameraTab:Separator({
            Text = "FOV"
        })

        CameraTab:Checkbox({
            Label = "Enabled",
            Value = ENABLED,
            IniFlag = "FovEnabled",
            Callback = function(_, v)
                setEnabled(v)
            end,
        })

        CameraTab:SliderInt({
            Label = "FOV Value",
            Value = FOV_VALUE,
            Minimum = 1,
            Maximum = 120,
            IniFlag = "FovValueSlider",
            Callback = function(self, Value)
                FOV_VALUE = math.round(Value)
                if ENABLED then
                    fovUpdated()
                end
            end,
        })
    end
end

-- Internals
do
    local InternalTab = Window:CreateTab({
        Name = "Internals",

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

        InternalTab:Separator({
            Text = "Serve"
        })

        -- ui
        InternalTab:SliderInt({
            Label = "Power",
            Value = 100,
            Minimum = 0,
            Maximum = 100,
            IniFlag = "ServeFixedPowerSlider",
            Callback = function(self, Value)
                value = Value / 100
                print(value)
            end,
        })
    
        InternalTab:Checkbox({
            Label = "Enabled",
            Value = true,
            IniFlag = "ServePowerToggle",
            Callback = function(_, v)
                setEnabled(v)
            end,
        })

    end

    -- Ts Hinoto
    if hookmetamethod and hookfunction and newcclosure then
        InternalTab:Separator({
            Text = "Timeskip Hinata"
        })

        local specialController;
        for _, v in getloadedmodules() do
            if v.Name ~= "SpecialController" then continue end
            specialController = require(v)
            break
        end

        do
            local function valueHook(name, value)
                InternalTab:Label({
                    Text = `* {name}`
                })

                local MULTIPLIER = 1
                local ENABLED = false

                local old; old = hookfunction(value.get, newcclosure(function(self, ...)
                    if not ENABLED or not rawequal(self, value) then return old(self, ...) end

                    local result = old(self, ...)
                    if typeof(result) ~= "number" then return result end

                    if result == 20 then
                        return result * 0.75
                    else
                        return result * MULTIPLIER
                    end
                end))


                -- ui
                InternalTab:Checkbox({
                    Label = "Enabled",
                    Value = ENABLED,
                    IniFlag = `TsHinoto{name}Toggle`,
                    Callback = function(_, v)
                        ENABLED = v
                    end,
                })

                InternalTab:SliderInt({
                    Label = "Multiplier",
                    Value = 1,
                    Minimum = 0,
                    Maximum = 10,
                    IniFlag = `TsHinoto{name}ValueSlider`,
                    Callback = function(self, Value)
                        MULTIPLIER = Value
                    end,
                })

                hooks:Add(function()
                    ENABLED = false
                end)
            end
                
            -- Speed
            local speedVal = specialController.ChargeSpringSpeed
            valueHook("Fill Speed", speedVal)
        
            -- Damping
            --local dampingVal = specialController.ChargeSpringSpeed
            --valueHook("Fill Damping", dampingVal)
        end


        -- Always Max
        do     
            local ENABLED = true
            local old;
            old = hookmetamethod(game, "__namecall", function(self, ...)
                local args = {...}
                if ENABLED and not checkcaller() then
                    if getnamecallmethod() == "InvokeServer" and typeof(self) == "Instance" and self.ClassName == "RemoteFunction" and self.Name == "Interact" then
                        local t = args[1]
                        if typeof(t) == "table" and rawget(t, "SpecialCharge") ~= nil then
                            rawset(t, "SpecialCharge", 2)
                        end
                    end
                end
                return old(self, table.unpack(args))
            end)

            InternalTab:Label({
                Text = `* Always Purple`
            })

            InternalTab:Checkbox({
                Label = "Enabled",
                Value = ENABLED,
                IniFlag = "HinataMaxToggle",
                Callback = function(_, v)
                    ENABLED = v
                end,
            })

            hooks:Add(function()
                ENABLED = false
            end)
        end
    end

    -- Sanu Tilt
    if hookmetamethod and newcclosure then
        local ENABLED = true
        local MAX_ANGLE = 10

        local function rotateTowardsXZ(lookVector, tiltVector, maxAngleDegrees)
            local lookXZ = Vector2.new(lookVector.X, lookVector.Z)
            local tiltXZ = Vector2.new(tiltVector.X, tiltVector.Z)
            
            if lookXZ.Magnitude == 0 or tiltXZ.Magnitude == 0 then
                return lookVector
            end
            
            lookXZ = lookXZ.Unit
            tiltXZ = tiltXZ.Unit
            
            local dot = lookXZ.Dot(lookXZ, tiltXZ)
            
            if dot < -0.9 then
                return lookVector
            end
            
            local angle = math.acos(math.clamp(dot, -1, 1))
            local cross = lookXZ.X * tiltXZ.Y - lookXZ.Y * tiltXZ.X
            local direction = math.sign(cross)
            
            local maxAngle = math.rad(maxAngleDegrees)
            local rotationAngle = math.min(angle, maxAngle)
            
            local cos = math.cos(rotationAngle)
            local sin = math.sin(rotationAngle) * direction
            
            local rotated = Vector2.new(
                lookXZ.X * cos - lookXZ.Y * sin,
                lookXZ.X * sin + lookXZ.Y * cos
            )
            
            return Vector3.new(rotated.X, lookVector.Y, rotated.Y).Unit
        end
        

        local old;
        old = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local args = {...}
            if  ENABLED and not checkcaller() then
                if getnamecallmethod() == "InvokeServer" and typeof(self) == "Instance" and self.ClassName == "RemoteFunction" and self.Name == "Interact" then
                    local t = args[1]
                    if typeof(t) == "table" then
                        local action = rawget(t, "Action")
                        if action == "Spike" or action == "Block" then
                            local lookVector, tiltDirection = rawget(t, "LookVector"), rawget(t, "TiltDirection")
                            if lookVector and tiltDirection then
                                local rotatedVector = rotateTowardsXZ(lookVector, tiltDirection, MAX_ANGLE)
                                rawset(t, "LookVector", rotatedVector)
                                --rawset(t, "TiltDirection", tiltDirection)
                            end
                        end
                    end
                end
            end
            return old(self, table.unpack(args))
        end))

        hooks:Add(function()
            ENABLED = false
        end)

        InternalTab:Separator({
            Text = "Sanu Tilt"
        })

        -- ui
        InternalTab:SliderInt({
            Label = "Max Angle",
            Value = MAX_ANGLE,
            Minimum = 0,
            Maximum = 90,
            IniFlag = "SanuTiltMaxAngle",
            Callback = function(self, Value)
                MAX_ANGLE = Value
            end,
        })
        
    
        InternalTab:Checkbox({
            Label = "Enabled",
            Value = ENABLED,
            IniFlag = "SanuTiltToggle",
            Callback = function(_, v)
                ENABLED = v
            end,
        })
    end

    -- No Cooldowns
    if getloadedmodules and hookfunction and newcclosure then
        for _, v in getloadedmodules() do
            if v.Name == "GameController" then
                    local t = require(v)
                    local val = t.IsBusy

                    local ENABLED = false

                    -- ui
                    InternalTab:Separator({
                        Text = "No Cooldowns"
                    })

                    InternalTab:Checkbox({
                        Label = "Enabled",
                        Value = ENABLED,
                        IniFlag = "NoCooldownsToggle",
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
                        if ENABLED and not checkcaller() and rawequal(self, val) and not LocalPlayer:GetAttribute("IsServing") then
                            return old(self, false)
                        end     
                        return old(self, ...)
                    end))

                    local spikeClock = os.clock()
                    local oldMove; oldMove = hookfunction(t.DoMove, newcclosure(function(_, name, ...)
                        if ENABLED and not checkcaller() and (rawequal(name, "Spike") or rawequal(name, "Block"))  then
                            if os.clock() - spikeClock < 0.25 + LocalPlayer:GetNetworkPing() then
                                return
                            else
                                spikeClock = os.clock()
                            end
                        end
                        return oldMove(_, name, ...)
                    end))
            end
        end
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

        InternalTab:Separator({
            Text = "Hitbox Expander"
        })

        InternalTab:SliderFloat({
            Label = "Size",
            Format = "%.2f", 
            Value = MULTIPLIER,
            Minimum = 0,
            Maximum = 10,
            IniFlag = "HitboxMultiplier",
            Callback = function(self, Value)
                MULTIPLIER = Value
            end,
        })
    
        InternalTab:Checkbox({
            Label = "Enabled",
            Value = true,
            IniFlag = "HitboxToggle",
            Callback = function(_, v)
                ENABLED = v
            end,
        })

        hooks:Add(function()
            ENABLED = false
        end)
    end

    local gameController;
    if getloadedmodules then
        for _, v in getloadedmodules() do
            if v.Name == "GameController" then
                gameController = require(v)
                break
            end
        end
    end

    --[[
    -- Op Charge
    if gameController and hookfunction and checkcaller and newcclosure then
        local t = gameController
        local val = t.Power

        local SLIDER = 1
        local ENABLED = false

        -- ui
        InternalTab:Checkbox({
            Label = "Custom Charge",
            Value = ENABLED,
            IniFlag = "CustomChargeToggle",
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
            IniFlag = "ChargeValSlider",
        
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
        
        InternalTab:Separator({})
    end
    ]]

    -- Perfect Dive
    if hookmetamethod and BallTrajectory then
        local ENABLED = true

        local player = LocalPlayer
        local old; old = hookmetamethod(game, "__index", newcclosure(function(self, index, ...)
            if ENABLED and not checkcaller() and typeof(self) == "Instance" and old(self, "ClassName") == "Humanoid" and rawequal(index, "MoveDirection") and #({...}) == 0 and rawequal(debug.info(3,"f"), gameController.Dive)  then
                if BallTrajectory.LastTrajectory then
                    local diffVector = ((BallTrajectory.LastTrajectory - player.Character:GetPivot().Position) * Vector3.new(1, 0, 1))
                    if diffVector.Magnitude <= 30 then
                        return diffVector.Unit
                    end
                end
            end
            return old(self, index, ...)
        end))

        InternalTab:Separator({
            Text = "Perfect Dive"
        })

        InternalTab:Checkbox({
            Label = "Enabled",
            Value = ENABLED,
            IniFlag = "PerfectDiveToggle",
            Callback = function(_, v)
                ENABLED = v
            end,
        })

        hooks:Add(function()
            ENABLED = false
        end)
    end
end

-- Debug
do
    local DebugTab = Window:CreateTab({
        Name = "Debug",

    })

    local PreviewContainer = Instance.new("Folder")
    PreviewContainer.Name = "DebugFolder"
    PreviewContainer.Parent = workspace

    -- Ball Trajectory
    if BallTrajectory then
        -->> Preview 
        do
            local PreviewConfig = {
                Enabled = false,
                PreviewBallColor = Color3.fromRGB(255, 0, 0),
                PreviewBallTransparency = 0.5,
                BeamColor = Color3.fromRGB(82, 82, 82),
                BeamWidth = 0.2,
                PreviewBallScale = .8, -- Scale factor for the preview ball
            }
            
            local BallPreviews = {}
            
            local function removeBallPreview(ball)
                if not BallPreviews[ball] then return end
                for _, obj in pairs(BallPreviews[ball]) do
                    if obj and obj.Parent then obj:Destroy() end
                end
                BallPreviews[ball] = nil
            end
            
            local function createBallPreview(ball)
                if not PreviewConfig.Enabled then return end
                removeBallPreview(ball)
            
                local originalBall = ball.Ball
                local originalPart = originalBall.PrimaryPart
                local ballSize = originalPart.Size.Magnitude * PreviewConfig.PreviewBallScale
            
                -- Create a new sphere as the preview ball
                local previewBall = Instance.new("Part")
                previewBall.Shape = Enum.PartType.Ball
                previewBall.Size = Vector3.new(ballSize, ballSize, ballSize)
                previewBall.Color = PreviewConfig.PreviewBallColor
                previewBall.Transparency = PreviewConfig.PreviewBallTransparency
                previewBall.CanCollide = false
                previewBall.Anchored = true
                previewBall.CanQuery = false
                previewBall.CanTouch = false
                previewBall.Parent = PreviewContainer
            
                local sourceAttachment, targetAttachment = Instance.new("Attachment"), Instance.new("Attachment")
                sourceAttachment.Parent, sourceAttachment.Name = originalPart, "TrajectoryBeamSource"
                targetAttachment.Parent, targetAttachment.Name = previewBall, "TrajectoryBeamTarget"
            
                local beam = Instance.new("Beam")
                beam.Name, beam.Color = "TrajectoryBeam", ColorSequence.new(PreviewConfig.BeamColor)
                beam.Width0, beam.Width1, beam.FaceCamera = PreviewConfig.BeamWidth, PreviewConfig.BeamWidth, true
                beam.Attachment0, beam.Attachment1, beam.Parent = sourceAttachment, targetAttachment, previewBall
            
                BallPreviews[ball] = { PreviewBall = previewBall, Beam = beam, SourceAttachment = sourceAttachment, TargetAttachment = targetAttachment }
            end
            
            local function updateBallPreview(ball, landingPosition)
                if PreviewConfig.Enabled and BallPreviews[ball] then
                    BallPreviews[ball].PreviewBall.Position = landingPosition
                end
            end
            
            local function cleanupAllPreviews()
                for ball in pairs(BallPreviews) do removeBallPreview(ball) end
                BallPreviews = {}
            end
            
            function ToggleBallTrajectoryPreviews(enabled)
                if PreviewConfig.Enabled == enabled then return end
                PreviewConfig.Enabled = enabled
                if not enabled then cleanupAllPreviews() else
                    for _, ball in BallTrajectory.getAllBalls() do createBallPreview(ball) end
                end
                return PreviewConfig.Enabled
            end
            
            BallTrajectory.newBallSignal:Connect(createBallPreview)
            BallTrajectory.trajectoryUpdatedSignal:Connect(function(ball, landingPosition)
                if landingPosition then
                    if BallPreviews[ball] then updateBallPreview(ball, landingPosition) else createBallPreview(ball) end
                else removeBallPreview(ball) end
            end)
            BallTrajectory.ballDestroySignal:Connect(removeBallPreview)
            
            hooks:Add(function()
                ToggleBallTrajectoryPreviews(false)
            end)
      
            DebugTab:Separator({
                Text = "Ball Trajectory"
            })
            
            DebugTab:Checkbox({
                Label = "Enabled",
                Value = true,
                IniFlag = "TrajectoryPreviewToggle",
                Callback = function(_, v)
                    ToggleBallTrajectoryPreviews(v)
                end,
            })
    
        end
    
    end

    -- Safe Zone
    do
        local toggleEnabled = false
        local enemyCylinders = {}
        local courtHighlight = nil
        local enemyHighlightModel = nil
        
        local janitor = Janitor.new()
        
        local function createHighlightModel()
            enemyHighlightModel = Instance.new("Model")
            enemyHighlightModel.Name = "EnemyHighlights"
            enemyHighlightModel.Parent = PreviewContainer
        
            janitor:Add(enemyHighlightModel)
        end
        
        local function updateCourtHighlight()
            if not courtHighlight then return end
        
            if not LocalPlayer.Team or not LocalPlayer.Team:GetAttribute("Index") then
                courtHighlight.Parent = nil
                return
            else
                courtHighlight.Parent = PreviewContainer
            end
        
            local courtPos = CourtPart.Position
            local halfZ = CourtPart.Size.Z / 2
            local newPos = courtPos
        
            if LocalPlayer.Team and LocalPlayer.Team:GetAttribute("Index") == 1 then
                newPos = Vector3.new(courtPos.X, courtPos.Y + 0.1, courtPos.Z + (halfZ / 2))
            elseif LocalPlayer.Team and LocalPlayer.Team:GetAttribute("Index") == 2 then
                newPos = Vector3.new(courtPos.X, courtPos.Y + 0.1, courtPos.Z - (halfZ / 2))
            end
        
            courtHighlight.Size = Vector3.new(CourtPart.Size.X, CourtPart.Size.Y, halfZ)
            courtHighlight.CFrame = CFrame.new(newPos) * CourtPart.CFrame.Rotation
        end
        
        local function createCourtHighlight()
            local highlightPart = Instance.new("Part")
            highlightPart.Name = "CourtHighlightPart"
            highlightPart.Anchored = true
            highlightPart.CanCollide = false
            highlightPart.Color = Color3.fromRGB(165, 255, 165)
            highlightPart.Material = Enum.Material.ForceField
            highlightPart.Transparency = 0.5
            highlightPart.Parent = PreviewContainer
        
            courtHighlight = highlightPart
            updateCourtHighlight()
        
            janitor:Add(highlightPart)
        end
        
        local function createEnemyCylinder(player)
            if player == LocalPlayer then return end
            if not player.Team or (LocalPlayer.Team and player.Team and player.Team == LocalPlayer.Team) then return end
        
            local multiplier = player:GetAttribute("GameDiveSpeedMultiplier") or 1
            local radius = 10 * multiplier
        
            local cylinder = Instance.new("Part")
            cylinder.Shape = Enum.PartType.Cylinder
            cylinder.Name = player.Name .. "_HighlightCylinder"
            cylinder.Anchored = true
            cylinder.CanCollide = false
            cylinder.Color = Color3.new(1, 0, 0)
            cylinder.Material = Enum.Material.Neon
            cylinder.Transparency = 0.75
            cylinder.Size = Vector3.new(0.2, radius * 2, radius * 2)
            cylinder.Parent = enemyHighlightModel
        
            enemyCylinders[player] = cylinder
            janitor:Add(cylinder, nil, player)
        
            return cylinder
        end
        
        local function updateEnemyCylinder(player)
            if not enemyCylinders[player] then
                createEnemyCylinder(player)
            end
        
            local cyl = enemyCylinders[player]
            if cyl and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                cyl.Parent = enemyHighlightModel
                local hrp = player.Character.HumanoidRootPart
                cyl.CFrame = CFrame.new(hrp.Position.X, CourtPart.Position.Y + CourtPart.Size.Y + 0.2, hrp.Position.Z) * CFrame.Angles(0, 0, math.rad(90))

            else
                if cyl then
                    cyl.Parent = nil
                end
            end
        end
        
        local function removeEnemyCylinder(player)
            local cyl = enemyCylinders[player]
            if cyl then
                janitor:Remove(player)
                enemyCylinders[player] = nil
            end
        end
        
        local function setup()
            createHighlightModel()
            createCourtHighlight()
        
            janitor:Add(RunService.Heartbeat:Connect(function()
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer then
                        if LocalPlayer.Team and player.Team and player.Team ~= LocalPlayer.Team then
                            updateEnemyCylinder(player)
                        else
                            removeEnemyCylinder(player)
                        end
                    end
                end
            end))
        
            janitor:Add(Players.PlayerRemoving:Connect(removeEnemyCylinder))
            janitor:Add(LocalPlayer:GetPropertyChangedSignal("Team"):Connect(updateCourtHighlight))
        end
        
        local function toggle(on)
            if on then
                setup()
            else
                janitor:Cleanup()
                table.clear(enemyCylinders)
                courtHighlight = nil
                enemyHighlightModel = nil
            end
        end
                
        DebugTab:Separator({
            Text = "Dive Range"
        })
        
        DebugTab:Checkbox({
            Label = "Enabled",
            Value = toggleEnabled,
            IniFlag = "HitZoneToggle",
            Callback = function(_, v)
                toggle(v)
            end,
        })
        
        hooks:Add(function()
            toggle(false)
        end)
    end        
end


HaikyuuRaper:UiTab()
HaikyuuRaper:ConfigManager()
HaikyuuRaper:UnloadTab()
