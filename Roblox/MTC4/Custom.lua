-->> LOADSTRING
--[[
	loadstring(game:HttpGet('https://raw.githubusercontent.com/skibidiMusic/Lua/refs/heads/main/Roblox/MTC4/Custom.lua'))()
]]

-->> SRC
local Janitor = loadstring(game:HttpGet('https://raw.githubusercontent.com/skibidiMusic/Lua/refs/heads/main/Roblox/Util/Misc/Janitor.lua'))()
local ImGui = loadstring(game:HttpGet('https://raw.githubusercontent.com/skibidiMusic/Lua/refs/heads/main/Roblox/Util/UiLib/ImGui.lua'))()

if MTC_SAKSO then
    if MTC_SAKSO.unload then
        MTC_SAKSO.unload()
    end
else
    getgenv().MTC_SAKSO = {}
    if hookmetamethod then
        --disable adonis
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Pixeluted/adoniscries/main/Source.lua", true))()
        --disable goofy anticheat
        local old; old = hookmetamethod(game, "__namecall", function(self: RemoteEvent, arg1, ...)
            if not checkcaller() and typeof(self) == "Instance" and (self.ClassName == "RemoteEvent" or self.ClassName == "UnreliableRemoteEvent" ) then
                local method = getnamecallmethod()
                if method == "FireServer" or method == "fireServer" then
                    if self.Name == "IWantToBeBanned" then
                        return
                    end
                    if typeof(arg1) == "string" and arg1 == "gone" then
                        return
                    end
                end
            end
            return old(self, arg1, ...)
        end)
    end
end

local hooks = Janitor.new()
MTC_SAKSO.unload = function()
    MTC_SAKSO.unload = nil
    hooks:Cleanup()
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

--ui
local Window = ImGui:CreateWindow({Title = "Mtc Sakso", Position = UDim2.new(0.5, 0, 0, 70), Size = UDim2.new(0, 600, 0, 400), AutoSize = false,})
Window:Center()

hooks:Add(
Window
)

--esp
do
    local SpawnedVehicles = workspace:WaitForChild("SpawnedVehicles")

    local espTab = Window:CreateTab({
        Name = "Esp",
        Visible = true 
    })

    local function getRange(s: Vector3, e: Vector3)
        return math.round((e - s).Magnitude / 2.7777777777777777)
    end

    local function espUi(v)
        local Sakso = Instance.new("Folder")
        local Above = Instance.new("BillboardGui")
        local TextLabel = Instance.new("TextLabel")
        local Below = Instance.new("BillboardGui")
        local TextLabel_2 = Instance.new("TextLabel")

        Sakso.Name = "Sakso"

        Above.Name = "Above"
        Above.Parent = Sakso
        Above.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        Above.Active = true
        Above.AlwaysOnTop = true
        Above.ExtentsOffsetWorldSpace = Vector3.new(0, 1, 0)
        Above.Size = UDim2.new(50, 1000, 2, 15)
        Above.SizeOffset = Vector2.new(0, -1)
        Above.Adornee = v

        TextLabel.Parent = Above
        TextLabel.AnchorPoint = Vector2.new(0.5, 0.5)
        TextLabel.BackgroundColor3 = Color3.fromRGB(255, 238, 0)
        TextLabel.BackgroundTransparency = 1.000
        TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
        TextLabel.BorderSizePixel = 0
        TextLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
        TextLabel.Size = UDim2.new(0, 0, 1, 0)
        TextLabel.AutomaticSize = Enum.AutomaticSize.X
        TextLabel.Font = Enum.Font.SourceSans
        TextLabel.Text = "BMP-204"
        TextLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
        TextLabel.TextScaled = true
        TextLabel.TextSize = 14.000
        TextLabel.TextStrokeTransparency = 0.500
        TextLabel.TextWrapped = true

        Below.Name = "Below"
        Below.Parent = Sakso
        Below.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        Below.Active = true
        Below.AlwaysOnTop = true
        Below.ExtentsOffsetWorldSpace = Vector3.new(0, -1, 0)
        Below.LightInfluence = 1.000
        Below.Size = UDim2.new(50, 1000, 2, 15)
        Below.SizeOffset = Vector2.new(0, 0)
        Below.Adornee = v

        TextLabel_2.Parent = Below
        TextLabel_2.AnchorPoint = Vector2.new(0.5, 0.5)
        TextLabel_2.BackgroundColor3 = Color3.fromRGB(255, 238, 0)
        TextLabel_2.BackgroundTransparency = 1.000
        TextLabel_2.BorderColor3 = Color3.fromRGB(0, 0, 0)
        TextLabel_2.BorderSizePixel = 0
        TextLabel_2.AutomaticSize = Enum.AutomaticSize.X
        TextLabel_2.Position = UDim2.new(0.5, 0, 0.5, 0)
        TextLabel_2.Size = UDim2.new(0, 0, 1, 0)
        TextLabel_2.Font = Enum.Font.SourceSans
        TextLabel_2.Text = "500 studs"
        TextLabel_2.TextColor3 = Color3.fromRGB(255, 255, 255)
        TextLabel_2.TextScaled = true
        TextLabel_2.TextSize = 14.000
        TextLabel_2.TextStrokeTransparency = 0.500
        TextLabel_2.TextWrapped = true

        Sakso.Parent = CoreGui
        return Sakso
    end

    local function createVitalPartGui(v)
        local Converted = {
            ["_VitalPart"] = Instance.new("BillboardGui");
            ["_TextLabel"] = Instance.new("TextLabel");
        }

        Converted["_VitalPart"].Active = true
        Converted["_VitalPart"].Adornee = v
        Converted["_VitalPart"].AlwaysOnTop = true
        Converted["_VitalPart"].LightInfluence = 1
        Converted["_VitalPart"].MaxDistance = math.huge
        Converted["_VitalPart"].Size = UDim2.new(50, 1000, 1, 0)
        Converted["_VitalPart"].ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        Converted["_VitalPart"].Name = "VitalPart"
        Converted["_VitalPart"].Parent = CoreGui

        Converted["_TextLabel"].Font = Enum.Font.SourceSans
        Converted["_TextLabel"].RichText = true
        Converted["_TextLabel"].Text = "Engine"
        Converted["_TextLabel"].TextColor3 = Color3.fromRGB(255, 234.00001645088196, 0)
        Converted["_TextLabel"].TextScaled = true
        Converted["_TextLabel"].TextSize = 14
        Converted["_TextLabel"].TextStrokeTransparency = 0.5
        Converted["_TextLabel"].TextWrapped = true
        Converted["_TextLabel"].AnchorPoint = Vector2.new(0.5, 0)
        Converted["_TextLabel"].AutomaticSize = Enum.AutomaticSize.X
        Converted["_TextLabel"].BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Converted["_TextLabel"].BackgroundTransparency = 1
        Converted["_TextLabel"].BorderColor3 = Color3.fromRGB(0, 0, 0)
        Converted["_TextLabel"].BorderSizePixel = 0
        Converted["_TextLabel"].Position = UDim2.new(0.5, 0, 0, 0)
        Converted["_TextLabel"].Size = UDim2.new(0, 0, 1, 0)
        Converted["_TextLabel"].Parent = Converted["_VitalPart"]

        return Converted
    end

    local function createEspSection(holder: Instance, name: string)
        espTab:Separator({
            Text = name
        })

        local Highlight = Instance.new("Highlight")
        Highlight.Adornee = holder
        Highlight.DepthMode = Enum.HighlightDepthMode.Occluded
        Highlight.FillTransparency = 0.65
        Highlight.OutlineTransparency = 0
        Highlight.Parent = game:GetService("CoreGui")

        espTab:Checkbox({
            Label = "Highlight",
            Value = true,
            saveFlag = name .. "highlight",
            Callback = function(self, Value)
                Highlight.Enabled = Value
            end,
        })

        espTab:Checkbox({
            Label = "Highlight Occuluded",
            Value = true,
            saveFlag = name .. "occuluded",
            Callback = function(self, Value)
                Highlight.DepthMode = Value and Enum.HighlightDepthMode.Occluded or Enum.HighlightDepthMode.AlwaysOnTop
            end,
        })

        local esps = {}
        local nameEnabled = true
        local rangeEnabled = true
        local teamCheck = true
        local vitalParts = true

        local function childRemoved(v)
            local self = esps[v]
            if not self then return end
            if self.Jan then self.Jan:Cleanup   () end
            for _, v in self.Ui:GetChildren() do
                v.Adornee = nil
            end
            self.Ui:Destroy()
            esps[v] = nil
        end

        local function targetAdded(v: Model)
            if v.Name == "DONOT" then return end
            if v == LocalPlayer.Character then return end

            local ui = espUi(v)
            local above = ui:FindFirstChild("Above")
            local nameText = above:FindFirstChildOfClass("TextLabel")

            above.Enabled = nameEnabled

            nameText.Text = v.Name

            local below = ui:FindFirstChild("Below")
            below.Enabled = rangeEnabled

            local self = {}

            self.Ui = ui
            self.Team = name == "Vehicle" and v:GetAttribute("Team").Color or game.Players:GetPlayerFromCharacter(v).TeamColor.Color

            nameText.TextColor3 = self.Team
            
            if name == "Vehicle" then
                self.Jan = Janitor.new()

                --vehicle occupation
                local function occupationChanged()
                    local occupied = v:GetAttribute("Occupied")
                    if not occupied then
                        nameText.Text = v.Name .. " *EMPTY*"
                        nameText.TextColor3 = Color3.new(1, 1, 1):Lerp(self.Team, .5)
                    else
                        nameText.Text = v.Name
                        nameText.TextColor3 = self.Team
                    end
                end
                self.Jan:Add(v:GetAttributeChangedSignal("Occupied"):Connect(occupationChanged))
                occupationChanged()
                
                self.VitalParts = {}

                self.Jan:Add(task.defer(function()
                    local DamageModules = v:WaitForChild("DamageModules", 10)
                    if not DamageModules then return end

                    local Values = v:WaitForChild("Values", 5)
                    if not Values then return end
                    Values = Values:WaitForChild("DamageModule", 5)
                    if not Values then return end

                    local function vitalPartAdded(t: NumberValue)
                        self.Jan:Add(task.defer(function()
                            if string.match(t.Name, "Track") then return end
                            if typeof(t.Value) ~= "number" then return end

                            local model = DamageModules:FindFirstChild(t.Name, true)
                            if not model then
                                repeat
                                    local newDescendant = DamageModules.DescendantAdded:Wait()
                                    if not newDescendant:IsA("Folder") and newDescendant.Name == t.Name then
                                        model = newDescendant
                                    end
                                until model
                            end

                            --print(model:GetFullName())
    
                            local ui = createVitalPartGui(model)
                            ui._VitalPart.Enabled = vitalParts
                            ui._TextLabel.Text = t.Name
    
                            local function healthChanged(health: number)
                                if health > 0 then
                                    ui._TextLabel.TextColor3 = Color3.fromRGB(255, 0, 0):Lerp(Color3.fromRGB(0, 255, 0), health / t:GetAttribute("MaxHealth"))
                                    ui._TextLabel.TextStrokeColor3 = Color3.fromRGB(0,0,0)
                                else
                                    ui._TextLabel.TextColor3 = Color3.new(0,0,0)
                                    ui._TextLabel.TextStrokeColor3 = Color3.fromRGB(255, 0, 0)
                                end
                            end
    
                            self.Jan:Add(t.Changed:Connect(healthChanged))
                            healthChanged(t.Value)
    
                            self.Jan:Add(ui._VitalPart)
    
                            self.VitalParts[t] = ui
                        end))
                    end

                    self.Jan:Add(Values.ChildAdded:Connect(vitalPartAdded))
                    for _, a in Values:GetChildren() do
                        vitalPartAdded(a)
                    end
                end))
            end

            esps[v] = self
        end

        for _, v in holder:GetChildren() do
            targetAdded(v)
        end

        hooks:Add(holder.ChildAdded:Connect(targetAdded))
        hooks:Add(holder.ChildRemoved:Connect(childRemoved))


        --main loop
        hooks:Add(RunService.RenderStepped:Connect(function()
            --range
            if rangeEnabled then
                for t: Model, v in esps do
                    v.Ui.Below.TextLabel.Text = getRange(workspace.CurrentCamera.CFrame.Position, t:GetPivot().Position)
                end
            end
            for t, v in esps do
                --teamcheck
                local visible = (not teamCheck or v.Team ~= LocalPlayer.TeamColor.Color)

                --player seated check
                if name == "Players" then
                    local hum = t:FindFirstChild("Humanoid") :: Humanoid
                    if hum then
                        visible = visible and (not hum.SeatPart or not hum.SeatPart:IsDescendantOf(SpawnedVehicles))
                    end
                end

                v.Ui.Below.Enabled = visible and rangeEnabled
                v.Ui.Above.Enabled = visible and nameEnabled
            end
        end))

        --remove all 
        hooks:Add(function()
            Highlight:Destroy()
            for _, v in esps do
                childRemoved(v)
            end
        end)

        --name
        espTab:Checkbox({
            Label = "Name",
            Value = true,
            saveFlag = name.."NameEnabled",
            Callback = function(self, Value)
                nameEnabled = Value
            end,
        })

        --range
        espTab:Checkbox({
            Label = "Distance",
            Value = true,
            saveFlag = name.."dist",
            Callback = function(self, Value)
                rangeEnabled = Value
            end,
        })

        --teamcheck
        espTab:Checkbox({
            Label = "Team Check",
            Value = true,
            saveFlag = name.."teamcheck",
            Callback = function(self, Value)
                teamCheck = Value
            end,
        })

        
        --wacs
        if name == "Vehicle" then
            espTab:Checkbox({
                Label = "Vital Parts",
                Value = true,
                saveFlag = name.."vitalParts",
                Callback = function(self, Value)
                    vitalParts = Value
                    for _, v in esps do
                        if v.VitalParts then
                            for _, t in v.VitalParts do
                                t._VitalPart.Enabled = vitalParts
                            end
                        end
                    end
                end,
            })
        end
    end

    --vehicle esp
    do
       createEspSection(SpawnedVehicles, "Vehicle")
    end

    --plr esp
    do
        createEspSection(workspace:WaitForChild("SpawnedPlayers"), "Players")
    end
end

--vehicle
do
	local VehicleTab = Window:CreateTab({
		Name = "Vehicle",
		Visible = false 
	})

	local SpawnedVehicles = workspace:WaitForChild("SpawnedVehicles")

	--seating
	do
		local dropdown = VehicleTab:CollapsingHeader({
			Title = "Seat Changer",
			Open = false
		})


		local function getClosestVehicle()
			local localChar = game.Players.LocalPlayer.Character
			if not localChar then return end
		
			local closestDist = math.huge; local closestVehicle;
			for _, v in SpawnedVehicles:GetChildren() do
				if not  v:IsA("Model") then
					continue
				end
				local dist = (localChar:GetPivot().Position - v:GetPivot().Position).Magnitude
				if dist < closestDist then
					closestDist = dist
					closestVehicle = v
				end
			end
		
			return closestVehicle
		end
	
		local function pickSeat(name: string)
            local char = LocalPlayer.Character
            if not char then return end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if not hum then return end

			local closestVehicle = getClosestVehicle()
			if closestVehicle then
				for _, v: VehicleSeat in closestVehicle:GetDescendants() do
					if v:IsA("VehicleSeat") and v.Name == name then
						v:Sit(hum)
                        return
					end 
				end
			end
		end
	
		local function createSeatPicker(name: string, defaultKey: Enum.KeyCode)
			local Row = dropdown:Row({})
	
			Row:Button({
				Text = "Seat " .. name,
				Callback = function(self)
					pickSeat(name)
				end,
			})
	
			Row:Keybind({
				Label = "Keybind",
				Value = defaultKey,
				saveFlag = name .. "keybind",
				Callback = function()
					pickSeat(name)
				end,
			})
	
			Row:Fill()
		end
	
		--<< keybinds
		createSeatPicker("Commander", Enum.KeyCode.N)
		createSeatPicker("Loader", Enum.KeyCode.Y)
		createSeatPicker("Gunner", Enum.KeyCode.U)
		createSeatPicker("Driver", Enum.KeyCode.P)
	end

    --modifications
    if hookfunction and getrenv and ReplicatedStorage:WaitForChild("DriveData", 10) then
        do
            local modifications = {}
            
            --[[
            accelMult = 10;
            forwardSpeedMult = 10;
            backwardSpeedMult = 10;
            rpmConstant = 1;
            turnAccelBoost = 5;
            ]]
            
            local modificationsEnabled = true
    
            do
                local mt = {}
                mt.__index = function(self, i)
                    if modificationsEnabled then
                        if modifications[i] ~= nil then
                            return modifications[i]
                        end
                    end
                    return self.__base[i]
                end

                local disabled = false
                local DriveData = ReplicatedStorage:FindFirstChild("DriveData")

                local old; old = hookfunction(getrenv().require, function(self: ModuleScript)
                    if not disabled and not checkcaller() and typeof(self) == "Instance" and self:IsA("ModuleScript") and self:IsDescendantOf(DriveData) then
                        local x = old(self)
                        local new = table.clone(x)
                        new.powerDat = setmetatable({__base = x.powerDat}, mt)
                        return new
                    end
                    return old(self)
                end)

                hooks:Add(function()
                    disabled = true
                    modificationsEnabled = false
                end)
            end
    
            local dropdown = VehicleTab:CollapsingHeader({
                Title = "Modifications",
                Open = false
            })

            dropdown:Checkbox({
                Label = "All Disabled",
                Value = not modificationsEnabled,
                saveFlag = "modsEnabledReal",
                Callback = function(_, v)
                    modificationsEnabled = not v
                end,
            })

    
            local function createVal(name: string, val: number, enabled: boolean, enabledCallback: () -> nil, valCallback: () -> nil, min, max)
                dropdown:Separator({
                    Text = name
                })
                dropdown:Checkbox({
                    Label = "Enabled",
                    Value = enabled,
                    saveFlag = name.."enabled_sakso",
                    Callback = enabledCallback,
                })
    
                if min and max then
                    dropdown:Slider({
                        Label = "Amount",
                        Format = "%.d/%s", 
                        Value = val,
                        MinValue = min,
                        MaxValue = max,
                        saveFlag = name.."valSakso",
                    
                        Callback = function(self, Value)
                            valCallback(Value)
                        end,
                    })
                else
                    dropdown:InputText({
                        PlaceHolder = tostring(val),
                        ClearTextOnFocus = false,
                        saveFlag = name.."valSakso",
                        Callback = function(self, Value)
                            valCallback(tonumber(Value) or val)
                        end,
                    })
                end

    
                task.defer(valCallback, (val))
            end
    
            --speed
            do
                local speedVal = 1

                createVal("SpeedMultiplier", 1, false, function(_, v)
                    if v then
                        modifications.forwardSpeedMult = speedVal
                        modifications.backwardSpeedMult = speedVal
                    else
                        modifications.forwardSpeedMult = nil
                        modifications.backwardSpeedMult = nil
                    end
                end, function(v)
                    speedVal = v
                    if modifications.forwardSpeedMult then
                        modifications.forwardSpeedMult = speedVal
                        modifications.backwardSpeedMult = speedVal
                    end
                end, 0, 20)
            end

            --accel
            do
                local accelVal = 1

                createVal("AccelMultiplier", 1, false, function(_, v)
                    if v then
                        modifications.accelMult = accelVal
                    else
                        modifications.accelMult = nil
                    end
                end, function(v)
                    accelVal = v
                    if modifications.accelMult then
                        modifications.accelMult = accelVal
                    end
                end, 0, 20)
            end
    
        end
    end

    --FLY and TP (stole 80% from infinite yield)
    do
		local dropdown = VehicleTab:CollapsingHeader({
			Title = "Fly",
			Open = false
		})

        local enabled = true
        local currentFlying = nil
        local flySpeed = 50

        local checkBox = dropdown:Checkbox({
            Label = "Enabled",
            Value = enabled,
            saveFlag = "FlyEnabledReal",
            Callback = function(self, Value)
                enabled = Value
            end,
        })

        dropdown:Keybind({
            Label = "Keybind",
            Value = Enum.KeyCode.Asterisk,
            saveFlag = "Fly" .. "keybind",
            Callback = function()
                checkBox:Toggle()
            end,
        })

        dropdown:Slider({
            Label = "Speed",
            Format = "%.d/%s", 
            Value = flySpeed,
            MinValue = 1,
            MaxValue = 40,
            saveFlag = "flySpeed",
        
            Callback = function(self, Value)
                flySpeed = Value
            end,
        })



        local CONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
        local lCONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}

        local inputMap = {
            W = {"F", 1},
            A = {"L", -1},
            S = {"B", -1},
            D  = {"R", 1},
            E = {"Q", 2},
            Q = {"E", -2}
        }
        
        local function handleInput()
            for key, vals in inputMap do
                CONTROL[vals[1]] = UserInputService:IsKeyDown(Enum.KeyCode[key]) and flySpeed * vals[2] or 0
            end
        end

        
        local SPEED = 0

        local BG = Instance.new('BodyGyro')
        local BV = Instance.new('BodyVelocity')
        BG.P = 9e4
        BG.maxTorque = Vector3.new(9e9, 9e9, 9e9)
        BV.velocity = Vector3.new(0, 0, 0)
        BV.maxForce = Vector3.new(9e9, 9e9, 9e9)

        local function GetVehicleRoot()
            if not LocalPlayer.Character then return end
            local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
            if not hum or not hum.SeatPart or hum.SeatPart.Name ~= "Driver" then return end

            local Mass = hum.SeatPart.Parent:FindFirstChild("Mass")
            return Mass :: BasePart?
        end

        --CLICK TP
        --[[
                do
            local Mouse = LocalPlayer:GetMouse()
            if Mouse then
                local tpEnabled = false

                local dropdown = VehicleTab:CollapsingHeader({
                    Title = "Teleport",
                    Open = false
                })
        
                local checkBox = dropdown:Checkbox({
                    Label = "Enabled",
                    Value = tpEnabled,
                    saveFlag = "tpEnabledReals",
                    Callback = function(self, Value)
                        tpEnabled = Value
                    end,
                })
        
                dropdown:Keybind({
                    Label = "Keybind",
                    Value = Enum.KeyCode.Insert,
                    saveFlag = "Tp" .. "keybind",
                    Callback = function()
                        checkBox:Toggle()
                    end,
                })

                hooks:Add(UserInputService.InputEnded:Connect(function(input, gameProcessedEvent)
                    if not gameProcessedEvent and input.UserInputType == Enum.UserInputType.MouseButton1 then
                        if tpEnabled then
                            local root = GetVehicleRoot()
                            if not root then return end
                            local hitPosition = Mouse.Hit.Position
                            local newCFrame = CFrame.new(
                                hitPosition + Vector3.new(0, (root.Size.Y + 20) ,0)
                            ) * root.CFrame.Rotation
                            TweenService:Create(root, TweenInfo.new(1), {CFrame = newCFrame}):Play()
                        end
                    end
                end))
            end
        end
        ]]

        --NOCLIP


        --FLY LOOP
        hooks:Add(RunService.Heartbeat:Connect(function()
            local shouldFly = if enabled then GetVehicleRoot() else nil
            if shouldFly ~= currentFlying then
                currentFlying = shouldFly
                BG.Parent = shouldFly
                BV.Parent = shouldFly
                if not shouldFly then
                    CONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
                    lCONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
                    SPEED = 0
                end
            end
            if shouldFly then
                handleInput()
                if CONTROL.L + CONTROL.R ~= 0 or CONTROL.F + CONTROL.B ~= 0 or CONTROL.Q + CONTROL.E ~= 0 then
                    SPEED = 50
                elseif not (CONTROL.L + CONTROL.R ~= 0 or CONTROL.F + CONTROL.B ~= 0 or CONTROL.Q + CONTROL.E ~= 0) and SPEED ~= 0 then
                    SPEED = 0
                end
                if (CONTROL.L + CONTROL.R) ~= 0 or (CONTROL.F + CONTROL.B) ~= 0 or (CONTROL.Q + CONTROL.E) ~= 0 then
                    BV.velocity = ((workspace.CurrentCamera.CFrame.LookVector * (CONTROL.F + CONTROL.B)) + ((workspace.CurrentCamera.CFrame * CFrame.new(CONTROL.L + CONTROL.R, (CONTROL.F + CONTROL.B + CONTROL.Q + CONTROL.E) * 0.2, 0).Position) - workspace.CurrentCamera.CFrame.Position)) * SPEED
                    lCONTROL = {F = CONTROL.F, B = CONTROL.B, L = CONTROL.L, R = CONTROL.R}
                elseif (CONTROL.L + CONTROL.R) == 0 and (CONTROL.F + CONTROL.B) == 0 and (CONTROL.Q + CONTROL.E) == 0 and SPEED ~= 0 then
                    BV.velocity = ((workspace.CurrentCamera.CFrame.LookVector * (lCONTROL.F + lCONTROL.B)) + ((workspace.CurrentCamera.CFrame * CFrame.new(lCONTROL.L + lCONTROL.R, (lCONTROL.F + lCONTROL.B + CONTROL.Q + CONTROL.E) * 0.2, 0).Position) - workspace.CurrentCamera.CFrame.Position)) * SPEED
                else
                    BV.velocity = Vector3.new(0, 0, 0)
                end
                BG.CFrame = workspace.CurrentCamera.CFrame
            end
        end))
    end
end

--gunner
do
	local gunnerTab = Window:CreateTab({
		Name = "Gunner",
		Visible = false 
	})

    -- crosshair
    do
        gunnerTab:Separator({
            Text = "True Aim Crosshair"
        })
    
        local currentUi = nil
        local crosshairEnabled = true
    
        local function uiAdded(gunAim: ScreenGui)
            local mobileFrame = gunAim:WaitForChild("MobileFrame") :: Frame
            local mobileGui = mobileFrame:WaitForChild("mobilegui") :: ScreenGui
            local crosshair = mobileGui:WaitForChild("crosshair") :: ImageLabel
    
            mobileFrame:WaitForChild("ButtonContainer").Visible = false
        
            mobileFrame.Visible = crosshairEnabled
            mobileGui.Enabled = true
        
            crosshair.Size = UDim2.new(0,20,0,20)
            crosshair.BackgroundTransparency = .5
            crosshair.BackgroundColor3 = Color3.new(1,1,1)
            crosshair.BorderSizePixel = 2
            crosshair.BorderColor3 = Color3.new(0,0,0)
            crosshair.ImageColor3 = Color3.new(1, 0, 0)
            crosshair.ImageTransparency = 0
            crosshair.ZIndex = 5
        end
    
        hooks:Add( LocalPlayer.PlayerGui.ChildAdded:Connect(function(v)
            if v.Name == "GunAim" then
                uiAdded(v)
            end
        end) )
    
        hooks:Add( function()
            if currentUi then
                currentUi.MobileFrame.Visible = false
            end
        end )
    
        if LocalPlayer.PlayerGui:FindFirstChild("GunAim") then
            uiAdded(LocalPlayer.PlayerGui:FindFirstChild("GunAim"))
        end
    
        gunnerTab:Checkbox({
            Label = "Enabled",
            Value = true,
            saveFlag = "crosshair",
            Callback = function(self, Value)
                if currentUi then
                    currentUi.MobileFrame.Visible = Value
                end
            end,
        })
    end

    --zoom
    do
        gunnerTab:Separator({
            Text = "Zoom"
        })
    
        local camera = workspace.CurrentCamera
    
        local target;
        local enabled = false;
        local debounce = false;
        local lastNonZoomVal = camera.FieldOfView;
        local zoomAmount = 1;
    
        local function zoom(normalFov: number)
            lastNonZoomVal = normalFov
            local targetFov = normalFov / zoomAmount
            debounce = true
            camera.FieldOfView = targetFov
        end
    
        hooks:Add(
            camera:GetPropertyChangedSignal("FieldOfView"):Connect(function()
                if enabled and not debounce then
                    zoom(camera.FieldOfView)
                else
                    debounce = false
                end
            end)
        )
    
        local function enableZoom()
            enabled = true
            zoom(camera.FieldOfView)
        end
    
        local function disableZoom()
            enabled = false
            camera.FieldOfView = lastNonZoomVal
        end
    
        
        local checkBox = gunnerTab:Checkbox({
            Label = "Enabled",
            Value = false,
            saveFlag = "zoomEnabled",
            Callback = function(self, Value)
                if Value then enableZoom() else disableZoom() end
            end,
        })
    
        local keybind = gunnerTab:Keybind({
            Label = "Keybind",
            Value = Enum.KeyCode.V,
            saveFlag = "gunnerzoomkeybind",
            Callback = function()
                checkBox:Toggle()
            end,
        })
    
        gunnerTab:Slider({
            Label = "Amount",
            Format = "%.d/%s", 
            Value = zoomAmount,
            MinValue = 1,
            MaxValue = 10,
            saveFlag = "zoomValue",
        
            Callback = function(self, Value)
                zoomAmount = Value
                if enabled then
                    zoom(lastNonZoomVal)
                end
            end,
        })
    end

    -- Turret Modifications
    if hookfunction and getrenv then
        do
            local modifications = {}
            
            --[[
            accelMult = 10;
            forwardSpeedMult = 10;
            backwardSpeedMult = 10;
            rpmConstant = 1;
            turnAccelBoost = 5;
            ]]
            
            local modificationsEnabled = true
    
            do
                local mt = {}

                mt.__newindex = function(self, i, v)
                    self.__base[i] = v
                end
                mt.__index = function(self, i)
                    if modificationsEnabled then
                        if modifications[i] ~= nil then
                            return modifications[i]
                        end
                    end
                    return self.__base[i]
                end

                local disabled = false

                local old; old = hookfunction(getrenv().require, function(self: ModuleScript)
                    if not disabled and not checkcaller() and typeof(self) == "Instance" and self:IsA("ModuleScript") and self.Name == "TurretInfo" then
                        local x = old(self)
                        return setmetatable({__base = x}, mt)
                    end
                    return old(self)
                end)

                hooks:Add(function()
                    disabled = true
                    modificationsEnabled = false
                end)
            end
    
            local dropdown = gunnerTab:CollapsingHeader({
                Title = "Modifications",
                Open = false
            })

            dropdown:Checkbox({
                Label = "All Disabled",
                Value = not modificationsEnabled,
                saveFlag = "modsEnabledReal_Turret",
                Callback = function(_, v)
                    modificationsEnabled = not v
                end,
            })

            --rotation
            do
                local rotTable = {
                    horizontal = {nil, nil, 100},
                    vertical = {-99999, 99999, 100},
                }

                dropdown:Separator({
                    Text = "Rotation (Remove Angle Limits)"
                })
                
                dropdown:Checkbox({
                    Label = "Enabled",
                    Value = true,
                    saveFlag = "rotEnabledReal",
                    Callback = function(_, v)
                        if v then
                            modifications.anglelimits = rotTable
                        else
                            modifications.anglelimits = nil
                        end
                    end,
                })

                dropdown:Slider({
                    Label = "Rotation Speed",
                    Format = "%.d/%s", 
                    Value = 50,
                    MinValue = 0,
                    MaxValue = 300,
                    saveFlag = "raotionSpeedSaksoMakso",
                
                    Callback = function(self, Value)
                        for _, v in rotTable do
                            v[3] = Value
                        end
                    end,
                })
            end

            --stabilizer
            do
                local Stabiliser = {
                    StabRatio = {1, 1};
                };

                dropdown:Separator({
                    Text = "Perfect Stabilizer"
                })
                
                dropdown:Checkbox({
                    Label = "Enabled",
                    Value = true,
                    saveFlag = "stabEnabled",
                    Callback = function(_, v)
                        if v then
                            modifications.Stabiliser = Stabiliser
                        else
                            modifications.Stabiliser = nil
                        end
                    end,
                })
            end
    
            --mouse aim
            do
                dropdown:Separator({
                    Text = "Mouse Aim"
                })
                
                dropdown:Checkbox({
                    Label = "Enabled",
                    Value = true,
                    saveFlag = "mouseAimMakcijk",
                    Callback = function(_, v)
                        if v then
                            modifications.MouseAim = true
                        else
                            modifications.MouseAim = nil
                        end
                    end,
                })
            end

            --perfect range finder
            do
                local mds = {
                    unit = 1;
                    maxAccurateRange = 99999999;
                    speed = 0.1;
                }

                dropdown:Separator({
                    Text = "Perfect Range Finder"
                })
                
                dropdown:Checkbox({
                    Label = "Enabled",
                    Value = true,
                    saveFlag = "RANGEFINERMONKEY",
                    Callback = function(_, v)
                        if v then
                            modifications.rangeFinderAccuracy = mds
                        else
                            modifications.rangeFinderAccuracy = nil
                        end
                    end,
                })

                dropdown:Slider({
                    Label = "Find Time",
                    Format = "%.d/%s", 
                    Value = 1,
                    MinValue = 0,
                    MaxValue = 10,
                    saveFlag = "rangeFindTimeNig",
                
                    Callback = function(self, Value)
                        mds.speed = Value
                    end,
                })
            end
        end
    end
end

--weapons
--(90% ban stuff)
do
    if hookmetamethod then
        local weaponTab = Window:CreateTab({
            Name = "Weapons",
            Visible = false 
        })


        
    end
end

--Mod detection
do
    local modRanks = {
        "Moderator",
        "Non TC Dev",
        "TC Dev",
        "Administrator",
        "Owner",
        "Game Admin"
    }

    local function playerDetected(v: Player)
        local rank = v:GetRoleInGroup(13466988)
        if table.find(modRanks, rank) then
            ImGui:Notify("Moderator Detector", "A fatass moderator is in the server!!v!!11! 💀☠️🙏, Name: " .. v.Name .. " Rank: " .. rank , 99999999)
        end
    end

    hooks:Add(Players.PlayerAdded:Connect(playerDetected))
    for _, v in Players:GetPlayers() do
        task.defer(playerDetected,(v))
    end
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

Window:CreateConfigSaveHandler("MTC_3169")

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
		ImGui:Notify("MTC", "Unloaded the cheat. Re-execute if you want to use again." , 3)
    end,
})
