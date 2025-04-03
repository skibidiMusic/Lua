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
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local CollectionService = game:GetService("CollectionService")
local VirtualInputManager = game:GetService("VirtualInputManager")

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
    
    local CourtPart = getCourtPart()
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

    -- Ts Hinoto
    if hookmetamethod then
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

        InternalTab:Checkbox({
            Label = "Hinata Max",
            Value = ENABLED,
            saveFlag = "HinataMaxToggle",
            Callback = function(_, v)
                ENABLED = v
            end,
        })

        hooks:Add(function()
            ENABLED = false
        end)
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

    local gameController;
    if getloadedmodules then
        for _, v in getloadedmodules() do
            if v.Name == "GameController" then
                gameController = require(v)
                break
            end
        end
    end

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
        InternalTab:Separator({})
    end

    -- Perfect Dive
    if hookmetamethod and BallTrajectory then
        local ENABLED = true

        local player = Players.LocalPlayer
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

        InternalTab:Checkbox({
            Label = "Perfect Dive",
            Value = ENABLED,
            saveFlag = "PerfectDiveToggle",
            Callback = function(_, v)
                ENABLED = v
            end,
        })

        hooks:Add(function()
            ENABLED = false
        end)
        
        InternalTab:Separator({})
    end
end

-- Ball
if BallTrajectory then
    local BallTab = Window:CreateTab({
        Name = "Ball",
        Visible = false 
    })

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
        local PreviewContainer = Instance.new("Folder")
        PreviewContainer.Name = "BallLandingPreviews"
        PreviewContainer.Parent = workspace
        
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
        
        BallTab:Checkbox({
            Label = "Trajectory Preview",
            Value = true,
            saveFlag = "TrajectoryPreviewToggle",
            Callback = function(_, v)
                ToggleBallTrajectoryPreviews(v)
            end,
        })

    end

end

HaikyuuRaper:UiTab()
HaikyuuRaper:ConfigManager()
HaikyuuRaper:UnloadTab()
