-->> LOADSTRING
--[[
	loadstring(game:HttpGet('https://raw.githubusercontent.com/skibidiMusic/Lua/refs/heads/main/Roblox/JujutsuShinenigans/main.lua'))()
]]

-->> SRC

-->> fix repeats
local env = getgenv() :: {};

local dir = env.jjsSakso
if dir then
	if dir.disable then
		dir.disable()
	end
else
    env.jjsSakso = {}
    dir = env.jjsSakso
end

-->> quick fix for require using atlantis
local require = function(v)
	setidentity(2)
	local m = require(v)
	setidentity(8)
	return m
end

--> dep
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local ImGui = loadstring(game:HttpGet('https://raw.githubusercontent.com/skibidiMusic/Lua/refs/heads/main/Roblox/Util/UiLib/ImGui.lua'))()
local Janitor = loadstring(game:HttpGet('https://raw.githubusercontent.com/skibidiMusic/Lua/refs/heads/main/Roblox/Util/Janitor.lua'))()

local ServiceFolder = game.ReplicatedStorage.Knit.Knit.Services
local Player = game:GetService("Players").LocalPlayer

-->> hook control
local disableJanitor = Janitor.new()

-->> default config
local config = {
	combat = {
		autoBlock = {
			enabled = true,

			--<< constant
			lookAtPlayer = true,

			tryCounter = true,
			punish = true,

			melee = true,
			chase = true,

			--// chars
			Megumi = {
				blockToad = true,
				blockDog = true,
			},
		
			Itadori = {
				blockCursedStrikes = true,
			},

			Mahito = {
				blockFocusStrike = true,
				blockSoulFire = true,
				blockSpecialDash = true
			},

			Gojo = {
				blockLapseBlue = true,
				blockReversalRed = true,
			},

			Hakari = {
				blockDoors = true,
				blockBalls = true,
			},

		},

		player = {
			downSlam = true,
			alwaysBlackFlash = true, 
			AutoTarget = true,
			noDashCD = true,
			AntiCounter = true,
			noStun = {
				enabled = true,
				jump = true,
				sprint = true
			},
			lockOn = {
				camera = false,
				character = true
			}
		},
		
		misc = {
			infBlackFlash = true,
			antiFall = true,
			enterDomain = true,
		},

		whiteList = {
				
		}
	},
}

-->> code

--// Helper Funcs
local function distanceFromCharacter(v: Model | BasePart | Vector3) : Vector3?
	local character = Player.Character
	if not character then return end

	local targetPos; 
	if typeof(v) == "Vector3" then
		targetPos = v
	elseif v:IsA("BasePart") then
		targetPos = v.Position
	elseif v:IsA("Model") then
		targetPos = v:GetPivot().Position
	end

	if not targetPos then return end

	local diff = targetPos - character:GetPivot().Position
	return diff
end

local function getClosestCharacter()
	local localChar = game.Players.LocalPlayer.Character
	if localChar then
		local closest; local dist = math.huge;
		for _, v in workspace.Characters:GetChildren() do
			if v ~= localChar then
				local currentDist = (localChar:GetPivot().Position - v:GetPivot().Position).Magnitude
				if currentDist < dist then
					dist = currentDist
					closest = v
				end
			end
		end
		return closest
	end
end

local function findFuturePos(v: BasePart | Model, t: number?)
	if not t then t = Player:GetNetworkPing() * .5 end
	if v:IsA("Model") then
		v = v.PrimaryPart
	end
	return v.Position + v.AssemblyLinearVelocity * t
end

local function normalizeToGround(vector: Vector3)
	return vector * Vector3.new(1, 0, 1)
end

--// block and track

--(locking to a player when blocking etc.)
local isLookingAt = false;
local lookAtData = {
	lastCameraSubject = nil;
	Humanoid = nil;
}

local function stopLookingAt()
	if not isLookingAt then return end
	RunService:UnbindFromRenderStep("elkaka_und_dashQuel")
	lookAtData.Humanoid.AutoRotate = true
end

local function lookAt(enemy: Model, cameraEnabled: boolean, enemyPosMultiplier: number?)
	local localChar = Player.Character
	if not localChar then return end

	if isLookingAt then
		stopLookingAt()
	end

	isLookingAt = true

	enemyPosMultiplier = enemyPosMultiplier or 1

	--logic
	local hum = localChar:FindFirstChildOfClass("Humanoid")
	lookAtData.Humanoid = hum
	hum.AutoRotate = false

	local prevParent = enemy.Parent
	RunService:BindToRenderStep("elkaka_und_dashQuel", Enum.RenderPriority.Last.Value + 100, function()
		if enemy.Parent == prevParent then
			local enemyFuturePosition = findFuturePos(enemy, Player:GetNetworkPing() * enemyPosMultiplier * 0.5)
			localChar.PrimaryPart.CFrame = CFrame.lookAt(localChar.PrimaryPart.CFrame.Position,  normalizeToGround(enemyFuturePosition) + Vector3.new(0, Player.Character.PrimaryPart.CFrame.Position.Y, 0))
		end
	end)
end

disableJanitor:Add(stopLookingAt)

--(attacking)
local function attack(enemy: Model, goBehindEnemy: boolean?)
	local char = Player.Character
	if not char then return end

	local currentMoveset = char:GetAttribute("Moveset")
	local service = game.ReplicatedStorage.Knit.Knit.Services[currentMoveset .. "Service"]

	local remote = service.RE.Activated

	if goBehindEnemy then
		if char.Info:FindFirstChild("Stun") then return end

		local diff = distanceFromCharacter(enemy)
		if diff.Magnitude > 8 then
			return
		end

		local goBehindThread = task.defer(function()
			local totalT = 0
			while true do
				local dt = task.wait()
				totalT += dt
				remote:FireServer("Down")
				char:PivotTo(char:GetPivot():Lerp(enemy:GetPivot() * CFrame.new(Vector3.new(0,0 , 4)), dt * 16))
			end
		end)

		lookAt(enemy)

		task.wait(.35)
		task.cancel(goBehindThread)
		stopLookingAt()
	else
		local diff = distanceFromCharacter(enemy)
		if diff.Magnitude > 8 then
			return
		end
	
		remote:FireServer("Up")
		lookAt(enemy)
		task.delay(.1, stopLookingAt)
	end	
end


do
	
end

--(counter)
local function counter(enemy: Model?)
	local localChar = Player.Character
	if not localChar then return end
	
	local currentMoveset = localChar:GetAttribute("Moveset")
	
	if localChar:FindFirstChild"Moveset" and localChar:FindFirstChild("Moveset"):FindFirstChild("Manji Kick") then
		local service = game.ReplicatedStorage.Knit.Knit.Services.ManjiKickService
		local remote = service.RE.Activated
		remote:FireServer()
	elseif currentMoveset == "Hakari" and not localChar:GetAttribute("InUlt")  then
		local dist = distanceFromCharacter(findFuturePos(enemy))
		if normalizeToGround(dist).Magnitude < 12 then
			ServiceFolder.HakariService.RE.RightActivated:FireServer(enemy)
		end
	elseif currentMoveset == "Mahito" then
		local dist = distanceFromCharacter(findFuturePos(enemy))
		if normalizeToGround(dist).Magnitude < 10 then
			ServiceFolder.HeadSplitterService.RE.Activated:FireServer()
		end
	end
	
	if enemy then
		--lookAt(enemy, false, 1)
	end
end

--(blocking)
local blockRemotes = ServiceFolder.BlockService.RE

local isBlocking = false
local blockData = {
	loopThread = nil,
	delayThread = nil,
}

local function stopBlock(keepBlocking: boolean?)
	if not isBlocking then return end
	isBlocking = false
	stopLookingAt()
	task.cancel(blockData.loopThread)
	if coroutine.status(blockData.delayThread) == "suspended" then
		task.cancel(blockData.delayThread)
	end
	if not keepBlocking then
		blockRemotes.Deactivated:FireServer()
	end
end

local function block(enemy: Model, length: number, enemySpeedMultiplier: number?, punish: boolean?, tryCounter: boolean?)
	if not config.combat.autoBlock.enabled or config.combat.whiteList[enemy and enemy.Name] then return end
	
	local localChar = Player.Character
	if not localChar then return end

	if isBlocking then
		stopBlock(true)
	end

	isBlocking = true
	length = math.max(length - Player:GetNetworkPing() * 0.5, 0)


	if config.combat.autoBlock.lookAtPlayer then lookAt(enemy, config.combat.autoBlock.lockCamera, enemySpeedMultiplier) end
	
	if tryCounter and config.combat.autoBlock.tryCounter then
		counter(enemy)
	end

	blockData.loopThread = task.defer(function()
		while true do
			blockRemotes.Activated:FireServer()
			task.wait(0.025)
		end
	end)

	blockData.delayThread = task.delay(length, function()
		stopBlock(game.UserInputService:IsKeyDown(Enum.KeyCode.F))
		if punish then
			attack(enemy, false)
		end
	end)
end



-->> Gui Setup
local Window = ImGui:CreateWindow({
	Title = "JUJUT-SAKSO SHIT-A-NIGGA-NS",
	Position = UDim2.new(0.5, 0, 0, 70), --// Roblox property 
	Size = UDim2.new(0, 800, 0, 500),
	AutoSize = false,
	--NoClose = false,

	--// Styles
	NoGradientAll = true,
	Colors = {
		Window = {
			BackgroundColor3 = Color3.fromRGB(40, 40, 40),
			BackgroundTransparency = 0.1,
			ResizeGrip = {
				TextColor3 = Color3.fromRGB(80, 80, 80)
			},
			
			TitleBar = {
				BackgroundColor3 = Color3.fromRGB(25, 25, 25),
				[{
					Recursive = true,
					Name = "ToggleButton"
				}] = {
					BackgroundColor3 = Color3.fromRGB(80, 80, 80)
				}
			},
			ToolBar = {
				TabButton = {
					BackgroundColor3 = Color3.fromRGB(80, 80, 80)
				}
			},
		},
		CheckBox = {
			Tickbox = {
				BackgroundColor3 = Color3.fromRGB(20, 20, 20),
				Tick = {
					ImageColor3 = Color3.fromRGB(255, 255, 255)
				}
			}
		},
		Slider = {
			Grab = {
				BackgroundColor3 = Color3.fromRGB(60, 60, 60)
			},
			BackgroundColor3 = Color3.fromRGB(20, 20, 20)
		},
		CollapsingHeader = {
			TitleBar = {
				BackgroundColor3 = Color3.fromRGB(20, 20, 20)
			}
		}
	}

})

Window:Center()

--(tabs)
local CombatTab = Window:CreateTab({
	Name = "Combat",
	Visible = true 
})
local KeybindsTab = Window:CreateTab({
	Name = "Keybinds",
	Visible = false 
})


--// autoBlock
CombatTab:Separator({
	Text = "autoBlock"
})

CombatTab:Checkbox({
	Label = "Enabled",
	Value = config.combat.autoBlock.enabled,
	saveFlag = "BlockEnabled",
	Callback = function(self, Value)
		config.combat.autoBlock.enabled = Value
	end,
})

CombatTab:Checkbox({
	Label = "Auto Counter",
	Value = config.combat.autoBlock.tryCounter,
	saveFlag = "CounterToggle",
	Callback = function(self, Value)
		config.combat.autoBlock.tryCounter = Value
	end,
})

CombatTab:Checkbox({
	Label = "Punish",
	Value = config.combat.autoBlock.punish,
	saveFlag = "PunishToggle",
	Callback = function(self, Value)
		config.combat.autoBlock.punish = Value
	end,
})


--// character stuff
local characterNames = {
	Megumi = true,
	Mahoraga = true,
	Mahito = true,
	Itadori = true,
	Hakari = true,
	Gojo = true,
	Choso = true,
}

--// autoBlock logic
--(melee)
do
	local characterMeleeActionNames = {
		Megumi = "Swing2",
		Mahoraga = "Swing",
		Mahito = "Swing3",
		Itadori = "Swing2",
		Hakari = "Swing2",
		Gojo = "Swing2",
		Choso = "Swing",
	}

	local meleeBlockHeader = CombatTab:CollapsingHeader({
		Title = "Melee",
		Open = false
	})
	
	--melee attacks
	do
		-->> ui
		meleeBlockHeader:Checkbox({
			Label = "Punches",
			Value = config.combat.autoBlock.melee,
			saveFlag = "BlockMelee",
			Callback = function(self, Value)
				config.combat.autoBlock.melee = Value
			end,
		})
	
		-->> hook
		local function meleeDetected(enemyChar: Model, COMBO: number?)
			if not config.combat.autoBlock.melee then return end
			local localChar = Player.Character
			if localChar == enemyChar then
				return
			end
			if localChar then
				local diffVec : Vector3 = distanceFromCharacter(findFuturePos(enemyChar.PrimaryPart))
				if math.abs(diffVec.Y) < 4 then
					diffVec = normalizeToGround(diffVec)
					if enemyChar:GetAttribute("Moveset") == "Itadori" and enemyChar:GetAttribute("InUlt") then
						if normalizeToGround(diffVec).Magnitude < 20 then	
							block(enemyChar, 0.55, 1, COMBO == 4, true)
						end
					else
						if diffVec.Magnitude < 15 then	
							block(enemyChar, 0.35, 1, true, true)
						end 
					end
				end
			end
		end
	
		for name, actionName in characterMeleeActionNames do
			local service = ServiceFolder:FindFirstChild(name .. "Service")
			if service then
				disableJanitor:Add(service.RE.Effects.OnClientEvent:Connect(function(action: string, character: Model, combo: number, finish: string?)
					if action == actionName then
						meleeDetected(character, combo)
					end
				end))
			end
		end
	end
	
	--chase (front dash)
	do
		-->> ui
		meleeBlockHeader:Checkbox({
			Label = "Front Dash",
			Value = config.combat.autoBlock.chase,
			saveFlag = "BlockChase",
			Callback = function(self, Value)
				config.combat.autoBlock.chase = Value
			end,
		})
	
		-->> hook
		local function chaseDetected(enemyChar: Model)
			if not config.combat.autoBlock.chase then return end
			local localChar = Player.Character
			if localChar and localChar ~= enemyChar then
				local t = tick()

				local isInRadius = false
				local function enteredRadius()
					if not isInRadius then
						isInRadius = true
						block(enemyChar, 2.5, 3, true, true)
					end
				end

				local function outOfRadius()
					if isInRadius then
						isInRadius = false
						stopBlock()
					end
				end


				while task.wait() do
					if not (tick() - t < .5 or enemyChar.Info:FindFirstChild("InSkill")) then
						outOfRadius()
						if config.combat.autoBlock.enabled then
							attack(enemyChar, false)
						end
						return
					end

					local diffVec : Vector3 = distanceFromCharacter(findFuturePos(enemyChar.PrimaryPart))
					if diffVec and math.abs(diffVec.Y) < 8 and normalizeToGround(diffVec).Magnitude < 25 then
						enteredRadius()
					else
						outOfRadius()
					end
				end
			end
		end
	
		for name in characterNames do
			local service = ServiceFolder:FindFirstChild(name .. "Service")
			if service then
				disableJanitor:Add(service.RE.Effects.OnClientEvent:Connect(function(action: string, character: Model)
					if action == "Chase" then
						chaseDetected(character)
					end
				end))
			end
		end
	end	
end

--(blocking skills)
do
	local skillBlockHeader = CombatTab:CollapsingHeader({
		Title = "Skills",
		Open = false
	})


	--((global helper funcs))
	local function dashAttackDetected(enemy: Model | BasePart, counter: boolean?, from: CFrame?, yLimit: number?, maxDistance: number, blockLength: number) --<< cursed strikes etc.
		local localChar = Player.Character
		if localChar and enemy ~= Player.Character then
			from = from or ((enemy:IsA"Model" and enemy.PrimaryPart) or enemy).CFrame
			local distance = distanceFromCharacter(from.Position)
			if distance and math.abs(distance.Y) < (yLimit or 8) then
				distance = normalizeToGround(distance)
				if distance.Magnitude < maxDistance then
					if distance.Magnitude < 10 then
						block(enemy, blockLength, 1, true, counter)
					elseif distance.Unit:Dot(-from.LookVector) > 0.7 then
						block(enemy, blockLength, 1, true, counter)
					end
				end
			end
		end
	end

	local function bulletDetected() --<< soul fire etc.
		
	end

	--(itadori)
	do
		local itadoriHeader = skillBlockHeader:CollapsingHeader({
			Title = "Itadori",
			Open = false
		})

		-->> cursed strikes (1.)
		do
			itadoriHeader:Checkbox({
				Label = "Cursed Strikes",
				Value = config.combat.autoBlock.Itadori.blockCursedStrikes,
				saveFlag = "blockCursedStrikes",
				Callback = function(self, Value)
					config.combat.autoBlock.Itadori.blockCursedStrikes = Value
				end,
			})

			local function cursedStrikesDetected(enemy: Model, from: CFrame)
				if not config.combat.autoBlock.Itadori.blockCursedStrikes then return end
				if typeof(from) ~= "CFrame" then return end
				dashAttackDetected(enemy, false, from, 8, 40, .5)
			end
		
			disableJanitor:Add( ServiceFolder.CursedStrikesService.RE.Effects.OnClientEvent:Connect(function(action: string, enemy: Model, cfRame: CFrame)
				if action == "Dash" then
					cursedStrikesDetected(enemy, cfRame)
				end
			end) )
		
			disableJanitor:Add( ServiceFolder.CursedStrikesService.RE.Effects.OnClientEvent:Connect(function(action: string, enemy: Model, cfRame: CFrame)
				if action == "Swing" then
					cursedStrikesDetected(enemy, enemy.PrimaryPart.CFrame)
				end
			end) )
		end
	end

	--(megumi)
	do
		local megumiHeader = skillBlockHeader:CollapsingHeader({
			Title = "Megumi",
			Open = false
		})

		-->> toad (1)
		do
			megumiHeader:Checkbox({
				Label = "Toad (frog)",
				saveFlag = "BlockToad",
				Value = config.combat.autoBlock.Megumi.blockToad,
				Callback = function(self, Value)
					config.combat.autoBlock.Megumi.blockToad = Value
				end,
			})

			local function toadDetected(enemy: Model)
				if not config.combat.autoBlock.Megumi.blockToad then return end
				task.delay(.4 - Player:GetNetworkPing() * 0.5, block, enemy, .5, 1, false, false)
			end
		
			disableJanitor:Add( ServiceFolder.ToadService.RE.Effects.OnClientEvent:Connect(function(action: string, enemy: Model, target: Model) 
				if (action == "Toad" or action == "ToadAir") and target == Player.Character then
					toadDetected(enemy.Character)
				end
			end) )
		end

		-->> wolf (2)
		do
			megumiHeader:Checkbox({
				Label = "Wolf",
				Value = config.combat.autoBlock.Megumi.blockDog,
				saveFlag = "BlockWolf",
				Callback = function(self, Value)
					config.combat.autoBlock.Megumi.blockDog = Value
				end,
			})

			local function dogDetected(dogModel: Model, target: Model)
				if not config.combat.autoBlock.Megumi.blockDog then return end
				task.wait(.3 - Player:GetNetworkPing() * 0.5)
				if distanceFromCharacter(target).Magnitude < 6 then
					block(dogModel, .25, 1, false, true)
				end
			end
		
			disableJanitor:Add(ServiceFolder.DivineDogService.RE.Effects.OnClientEvent:Connect(function(action: string, dogModel: Model) 
				if (action == "Slash") then
					local targetValue = dogModel:FindFirstChild("Target")
					if not targetValue then return end
		
					if not targetValue.Value then
						--// wait a bit to see if value changes or not
						local valueWaitConn = targetValue.Changed:Once(function(target: Model) 
							dogDetected(dogModel, target)
						end)
		
						task.delay(.25, function()
							valueWaitConn:Disconnect()
						end)
		
					else
						dogDetected(dogModel, targetValue.Value)
					end
				end
			end) )
		end
	end

	--(mahito)
	do
		local mahitoHeader = skillBlockHeader:CollapsingHeader({
			Title = "Mahito",
			Open = false
		})

		-->> focus strike (1)
		do
			mahitoHeader:Checkbox({
				Label = "Focus Strike",
				Value = config.combat.autoBlock.Mahito.blockFocusStrike,
				saveFlag = "MahitoFocusStrike",
				Callback = function(self, Value)
					config.combat.autoBlock.Mahito.blockFocusStrike = Value
				end,
			})

			local function focusStrikeDetected(enemy: Model)
				if not config.combat.autoBlock.Mahito.blockFocusStrike then return end
				dashAttackDetected(enemy, true, nil, 8, 30, .5)
			end
			
			disableJanitor:Add( ServiceFolder.FocusStrikeService.RE.Effects.OnClientEvent:Connect(function(action: string, enemy: Model, cfRame: CFrame)
				if action == "Startup" then
					focusStrikeDetected(enemy)
				end
			end) )
		
			disableJanitor:Add( ServiceFolder.FocusStrikeService.RE.Effects.OnClientEvent:Connect(function(action: string, enemy: Model, cfRame: CFrame)
				if action == "Swing" then
					focusStrikeDetected(enemy)
				end
			end) )
		end

		-->> soul bullets (2)
		do
			mahitoHeader:Checkbox({
				Label = "Bullets",
				Value = config.combat.autoBlock.Mahito.blockSoulFire,
				saveFlag = "MahitoBullets",
				Callback = function(self, Value)
					config.combat.autoBlock.Mahito.blockSoulFire = Value
				end,
			})

			local function soulFireDetected(enemy: Model)
				if not config.combat.autoBlock.Mahito.blockSoulFire then return end
				local localChar = Player.Character
				if localChar and localChar ~= enemy then
					local distance = distanceFromCharacter(enemy)
					
					if distance and distance.Magnitude < 10 and math.abs(distance.Y) < 3  then
						task.wait(.3 - Player:GetNetworkPing())
					else
						task.wait(.4 - Player:GetNetworkPing())
					end
		
					for i = 1, 3 do			
						local distance = distanceFromCharacter(enemy)
						if distance then
							if distance.Magnitude < 65 and math.abs(distance.Y) < 3 and distance.Unit:Dot(-enemy:GetPivot().LookVector) > 0.8 then
								block(enemy, math.max(0.1 + 0.6 * distance.Magnitude / 60, .3), 1, false, true)
							end
						end
						task.wait(.25 - Player:GetNetworkPing())
					end
				end
			end
			
			disableJanitor:Add( ServiceFolder.SoulfireService.RE.Effects.OnClientEvent:Connect(function(action: string, char: Model) 
				if action == "Morph" then
					soulFireDetected(char)
				end
			end) )
		end

		-->> special dash :)
		do
			mahitoHeader:Checkbox({
				Label = "Special Dash",
				Value = config.combat.autoBlock.Mahito.blockSpecialDash,
				saveFlag = "MahitoSpecialDash",
				Callback = function(self, Value)
					config.combat.autoBlock.Mahito.blockSpecialDash = Value
				end,
			})

			local function specialDashDetected(enemy: Model, style: number)
				if not config.combat.autoBlock.Mahito.blockSpecialDash then return end
				if style == 1 then
					dashAttackDetected(enemy, false, nil, 8, 25, .5)
				elseif Player.Character and Player.Character ~= enemy then
					task.wait(.25 - Player:GetNetworkPing())
					dashAttackDetected(enemy, true, nil, 8, 25, 0)
				end
			end
		
			disableJanitor:Add( ServiceFolder.MahitoService.RE.Effects.OnClientEvent:Connect(function(action: string, enemy: Model, style: number)
				if action == "ChaseStart" then
					specialDashDetected(enemy, style)
				end
			end) )
		
			disableJanitor:Add( ServiceFolder.MahitoService.RE.Effects.OnClientEvent:Connect(function(action: string, enemy: Model, style: number)
				if action == "Chase2" then
					specialDashDetected(enemy, style)
				end
			end) )
		end

	end

	--(hakari)
	do
		local hakariHeader = skillBlockHeader:CollapsingHeader({
			Title = "Hakari",
			Open = false
		})

		-->> doors (1)
		do
			hakariHeader:Checkbox({
				Label = "Doors",
				Value = config.combat.autoBlock.Hakari.blockDoors,
				saveFlag = "HakariDoors",
				Callback = function(self, Value)
					config.combat.autoBlock.Hakari.blockDoors = Value
				end,
			})

			local function doorsDetected(part: BasePart)
				if not config.combat.autoBlock.Hakari.blockDoors then return end

				local dist = distanceFromCharacter(part)
				if dist and math.abs(dist.Y) < 12 and normalizeToGround(dist).Magnitude < 24  then
					task.wait(.2 - Player:GetNetworkPing())
					local dist = distanceFromCharacter(part)
					if normalizeToGround(dist).Magnitude < 12 then
						block(part, .45, 0, false, true)
					end
				end
			end

			disableJanitor:Add ( ServiceFolder.ShutterDoorService.RE.Effects.OnClientEvent:Connect(function(method: string, part: BasePart)
				if method == "Spawn" then
					doorsDetected(part)
				end
			end) )
		end

		-->> reserve balls (2)
		do
			hakariHeader:Checkbox({
				Label = "Balls",
				Value = config.combat.autoBlock.Hakari.blockBalls,
				saveFlag = "HakariBalls",
				Callback = function(self, Value)
					config.combat.autoBlock.Hakari.blockBalls = Value
				end,
			})

			--<< projectile shot
			local raycastParams = RaycastParams.new()
			raycastParams.FilterDescendantsInstances = {workspace.Effects, workspace.Bullets}
			

			local function ballSpawning(enemy: Model)
				if not config.combat.autoBlock.Hakari.blockBalls then return end

				task.wait(.25 - Player:GetNetworkPing())
				if not Player.Character or enemy == Player.Character then return end

				local dist = distanceFromCharacter(enemy)
				if math.abs(dist.Y) < 3 then
					dist = normalizeToGround(dist)
					if dist.Magnitude < 70 then
						if dist.Magnitude < 20 then
							if dist.Unit:Dot(-enemy:GetPivot().LookVector) > 0.8 then
								block(enemy, .3, 1, true, false) --<< countering is just unneccessary atp.
							end
							return
						end

						local dir = enemy:GetPivot().LookVector * dist.Magnitude
						local raycast = workspace:Raycast(enemy:GetPivot().Position, dir, raycastParams) :: RaycastResult

						if raycast then
							if distanceFromCharacter(raycast.Position).Magnitude < 6 then
								block(enemy, math.max(0.1 + 0.6 * dist.Magnitude / 65, .3), 1, true, true)
							end
							return
						end

						if dist.Unit:Dot(-enemy:GetPivot().LookVector) > 0.7 then
							block(enemy, 0.6 * dist.Magnitude / 65, 1, true, true)
						end
					end
				end
			end

			disableJanitor:Add ( ServiceFolder.ReserveBallService.RE.Effects.OnClientEvent:Connect(function(action: string, char: Model)
				if action ~= "Swing" then return end
				ballSpawning(char)
			end) )
		end
	end

	--(gojo)
	do
		local gojoHeader = skillBlockHeader:CollapsingHeader({
			Title = "Gojo",
			Open = false
		})

		-->> blue (1)
		do
			gojoHeader:Checkbox({
				Label = "Lapse Blue",
				Value = config.combat.autoBlock.Gojo.blockLapseBlue,
				saveFlag = "blockLapseBlue",
				Callback = function(self, Value)
					config.combat.autoBlock.Gojo.blockLapseBlue = Value
				end,
			})

			local remote = ServiceFolder.LapseBlueService.RE.Effects

			local grabbedTick = 0;
			local function localCharGrabbed(target: Model)
				if target == Player.Character then
					grabbedTick = tick();
				end
			end
			disableJanitor:Add (
				remote.OnClientEvent:Connect(function(action: string, target: Model)
					if action == "BlueGrab" then
						localCharGrabbed(target)
					end
				end)
			)

			local function blueDetected(enemy: Model)
				if not config.combat.autoBlock.Gojo.blockLapseBlue then return end
				local localChar = Player.Character
				if not localChar then return end
				if tick() - grabbedTick < .2 + Player:GetNetworkPing() * .5 then
					--<<< might be us
					local distance = distanceFromCharacter(enemy)
					if distance.Magnitude < 35 then
						distance = normalizeToGround(distance)
						if enemy:GetPivot().LookVector:Dot(-distance.Unit) > 0.25 then
							--<< it probably IS us
							task.wait(.25 - Player:GetNetworkPing())
							block(enemy, .4, 1, true, true)
						end
					end
				end
			end
			disableJanitor:Add (
				remote.OnClientEvent:Connect(function(action: string, enemy: Model)
					if action == "LapseBlue" then
						blueDetected(enemy)
					end
				end)
			)
		end

		--red (2)
		do
			gojoHeader:Checkbox({
				Label = "Reversal Red",
				Value = config.combat.autoBlock.Gojo.blockReversalRed,
				saveFlag = "BlockReversalRed",
				Callback = function(self, Value)
					config.combat.autoBlock.Gojo.blockReversalRed = Value
				end,
			})

			--<< projectile shot
			local raycastParams = RaycastParams.new()
			raycastParams.FilterDescendantsInstances = {workspace.Effects, workspace.Bullets}

			local function redProjectileDetected(projectile: BasePart)
				if not config.combat.autoBlock.Gojo.blockReversalRed then return end

				local appearTick = tick()
				local thread = task.defer(function()
					while task.wait() do
						local localChar = Player.Character
						if not localChar then continue end

						if distanceFromCharacter(projectile).Magnitude < 15 then
							if tick() - appearTick > 1.7 - Player:GetNetworkPing() or workspace:Raycast(projectile.CFrame.Position, projectile.CFrame.LookVector * Player:GetNetworkPing() * 30, raycastParams) then
								--debugConsole.print("explosion detected!")
								block(projectile, .4, 1, false, true)
								return
							end
						end
					end
				end)
				projectile.Destroying:Connect(function()
					task.cancel(thread)
				end)
			end
			
			--<< cast
			local function redCasted(enemy: Model)
				if not config.combat.autoBlock.Gojo.blockReversalRed then return end

				local localChar = Player.Character
				if not localChar or enemy == localChar then return end

				task.wait(.7 - Player:GetNetworkPing())

				local dist = distanceFromCharacter(enemy)
				if dist and math.abs(dist.Y) < 8 then
					dist = normalizeToGround(dist)
					if dist.Magnitude < 15 then
						if dist.Magnitude < 8 or enemy:GetPivot().LookVector:Dot(-dist.Unit) > .3 then
							block(enemy, .4, 1, true, true)
						end
					end
				end
			end

			--<< hooks
			disableJanitor:Add (
				ServiceFolder.ReversalRedService.RE.Effects.OnClientEvent:Connect(function(action: string, enemy: Model)
					if action == "Red" then
						redCasted(enemy)
					end
				end)
			)

			disableJanitor:Add (
				workspace.Bullets.ChildAdded:Connect(function(child: BasePart)
					if child.Name == "RedProjectile" then
						redProjectileDetected(child)
					end
				end)
			)
		end
	end

end

--// player functions
do
	CombatTab:Separator({
		Text = "Player"
	})
	
	--<< Anti-Counter
	do
		local success, ToolController = pcall(function()
			return require(game.Players.LocalPlayer.PlayerScripts.Controllers.Character.ToolController) 
		end)

		local feintRemote = ServiceFolder.ItadoriService.RE.RightActivated
		local isTargetCountering;
		disableJanitor:Add ( RunService.RenderStepped:Connect(function()
			local target = success and ToolController:GetTarget() or getClosestCharacter()
			if target and target:FindFirstChild"Info" and target.Info:FindFirstChild("Counter") then
				isTargetCountering = target
				-->> spam itadori feint if target is countering
				if not config.combat.player.AntiCounter then return end
				feintRemote.FireServer(feintRemote)
			else
				isTargetCountering = nil
			end
		end))

		if hookmetamethod then
			local disabled = false

			local old;
			old = hookmetamethod(game, "__namecall", function(self, ...)
				if not disabled and not checkcaller() and config.combat.player.AntiCounter and isTargetCountering then
					if getnamecallmethod() == "FireServer" and typeof(self) == "Instance" and self.ClassName == "RemoteEvent" and self.Name == "Activated" then
						return
					end
				end
				return old(self, ...)
			end)

			disableJanitor:Add ( function()
				disabled = true
			end )
		end

		--(ui)
		CombatTab:Checkbox({
			Label = "AntiCounter",
			Value = config.combat.player.AntiCounter,
			saveFlag = "AntiCounter",
			Callback = function(self, Value)
				config.combat.player.AntiCounter = Value
			end,
		})
	end
	
	--<< Downslam
	do
		if hookmetamethod then
			local function getRemote()
				local char = game.Players.LocalPlayer.Character
				if not char then return end
			
				local moveSet = char.GetAttribute(char, "Moveset")
				if not moveSet then return end
			
				return ServiceFolder[moveSet .. "Service"].RE.Activated
			end
	
			local disabled = false
			
			local old;
			old = hookmetamethod(game, "__namecall", function(self, ...): any
				if not disabled and config.combat.player.downSlam then
					if not checkcaller() and getnamecallmethod() == "FireServer" then
						local remote = getRemote()
						if remote then
							if self == remote then
								local args = {...}
								if args[1] == false then
									return old(self, "Down")
								end
							end
						end
					end
				end
			   return old(self, ...)
			end)
	
			disableJanitor:Add (function()
				disabled = true
			end)
	
			CombatTab:Checkbox({
				Label = "Auto-Downslam",
				Value = config.combat.player.downSlam,
				saveFlag = "downslam",
				Callback = function(self, Value)
					config.combat.player.downSlam = Value
				end,
			})
		end
	end

	--<< Always black flash
	do
		local remote = ServiceFolder.DivergentFistService.RE.Activated

		local function blackFlashDetected(character: Model)
			if not config.combat.player.alwaysBlackFlash then return end
			local localChar = Player.Character
			if not localChar or localChar ~= character then return end

			task.wait(.15 - Player:GetNetworkPing())
			remote:FireServer()
		end

		disableJanitor:Add( ServiceFolder.DivergentFistService.RE.Effects.OnClientEvent:Connect(function(effectName: string, char: Model) 
			if effectName == "CurseBuild" then
				blackFlashDetected(char)
			end
		end) )

		CombatTab:Checkbox({
			Label = "Always Black Flash",
			Value = config.combat.player.alwaysBlackFlash,
			saveFlag = "AlwaysBlackFlash",
			Callback = function(self, Value)
				config.combat.player.alwaysBlackFlash = Value
			end,
		})
	end

	--<< AutoTarget
	do
		local success, ToolController = pcall(require, game.Players.LocalPlayer.PlayerScripts.Controllers.Character.ToolController)
		if success then
			local disabled = false
			local old = ToolController.GetTarget;
			ToolController.GetTarget = function(self, ...)
				if not disabled and not checkcaller() and config.combat.player.AutoTarget then
					local result = old(self, ...) or getClosestCharacter()
					return result
				end
				return old(self, ...)
			end
			disableJanitor:Add ( function()
				disabled = true
			end)
			CombatTab:Checkbox({
				Label = "Auto-Target",
				Value = config.combat.player.AutoTarget,
				saveFlag = "autoTarget",
				Callback = function(self, Value)
					config.combat.player.AutoTarget = Value
				end,
			})
		end
	end

	--<< Lock On
	do
		local t, MovementController = pcall(require, game.Players.LocalPlayer.PlayerScripts.Controllers.Character.MovementController)
		if t then
			local success, ToolController = pcall(require, game.Players.LocalPlayer.PlayerScripts.Controllers.Character.ToolController)

			local dropdown = CombatTab:CollapsingHeader({
				Title = "Lock On",
				Open = false
			})

			local lockOnKeybind = dropdown:Keybind({
				Label = "Keybind",
				Value = Enum.KeyCode.LeftAlt,
				saveFlag = "lockOnKeybind",
				Callback = function()
					if MovementController.LockOn then
						MovementController.LockOn = nil
					else
						local target = success and ToolController:GetTarget() or getClosestCharacter() 
						MovementController.LockOn = target
					end
				end,
			})
		end
	end	

	--<< noDashCD
	do
		if debug and debug.setupvalue then
			local controller = require(game.Players.LocalPlayer.PlayerScripts.Controllers.Character.MovementController)
			local old = controller.DashRequest
	
			controller.DashRequest = function(self)
				if config.combat.player.noDashCD then
					debug.setupvalue(old, 3, 0)
				end
				return old(self)
			end
	
			disableJanitor:Add ( function()
				controller.DashRequest = old
			end)
	
			CombatTab:Checkbox({
				Label = "No Dash CD",
				Value = config.combat.player.noDashCD,
				saveFlag = "noDashCD",
				Callback = function(self, Value)
					config.combat.player.noDashCD = Value
				end,
			})
		end
	end

	--<< no Stun
	do
		local dropdown = CombatTab:CollapsingHeader({
			Title = "No-Stun",
			Open = false
		})

		dropdown:Checkbox({
			Label = "Enabled",
			Value = config.combat.player.noStun.enabled,
			saveFlag = "nostunenabled",
			Callback = function(self, Value)
				config.combat.player.noStun.enabled = Value
			end,
		})

		dropdown:Checkbox({
			Label = "Jump",
			Value = config.combat.player.noStun.jump,
			saveFlag = "nostunjump",
			Callback = function(self, Value)
				config.combat.player.noStun.jump = Value
			end,
		})

		dropdown:Checkbox({
			Label = "Sprint",
			Value = config.combat.player.noStun.sprint,
			saveFlag = "nostunsprint",
			Callback = function(self, Value)
				config.combat.player.noStun.sprint = Value
			end,
		})

		disableJanitor:Add (
			task.defer(function()
				while true do
					task.wait()
					local charInfo = Player.Character and Player.Character:FindFirstChild("Info")
					if charInfo then
						if config.combat.player.noStun.enabled then
							local values = {
								Stun = true,
								NoSprint = config.combat.player.noStun.sprint,
								NoJump = config.combat.player.noStun.jump,
								InSkill = true,
							}

							for name, bool in values do
								if bool then
									local val =charInfo:FindFirstChild(name)
									if val then
										val:Destroy()
									end
								end
							end
						end
					end
				end
			end)
		)
	end
end

--// misc stuff.
do
	CombatTab:Separator({
		Text = "Misc"
	})
	--<< inf black flash
	do
		local remote = ServiceFolder.DivergentFistService.RE.Activated
		
		local function blackFlashDetected(localChar: Model, character: Model)
			if not config.combat.misc.infBlackFlash then return end
			if Player.Character ~= localChar then return end
			task.wait(0.5 - Player:GetNetworkPing())
	
			if character.Info:FindFirstChild("Knockback") or not character.Info:FindFirstChild("Stun") then return end
			remote:FireServer()
	
			task.wait(.15 - Player:GetNetworkPing())
	
			local thread = task.defer(function()

				while true do
					local dt = task.wait()
					localChar:PivotTo(localChar:GetPivot():Lerp(character:GetPivot() * CFrame.new(Vector3.new(0,0 , 4)), dt * 20))
				end
			end)
	
			lookAt(character, false, 0)
	
			task.wait(.25 + Player:GetNetworkPing())
			remote:FireServer()
	
			task.wait(.35)
	
			stopLookingAt()
			task.cancel(thread)
		end
		
		disableJanitor:Add( ServiceFolder.DivergentFistService.RE.Effects.OnClientEvent:Connect(function(effectName: string, localChar: Model, char: Model) 
			if effectName == "BlackFlashHit" then
				blackFlashDetected(localChar, char)
			end
		end) )
	
		CombatTab:Checkbox({
			Label = "Inf Black Flash",
			Value = config.combat.misc.infBlackFlash,
			saveFlag = "InfBlackFlash",
			Callback = function(self, Value)
				config.combat.misc.infBlackFlash = Value
			end,
		})
	end

	--<< anti fall
	do
		local partData = {
			{size = Vector3.new(-17.25, 11.75, -533.115), pos = Vector3.new(740.5, 2.5, 372.771)},
			{size = Vector3.new(145, 2.5, 1389.771), pos = Vector3.new(352.5, 11.75, -24.615)},
			{size = Vector3.new(598, 2.5, 36.771), pos = Vector3.new(126, 11.75, 651.885)},
			{size = Vector3.new(298, 2.5, 1091.271), pos = Vector3.new(-313.5, 11.75, 124.635)}
		}
		
		local parts = {}
	
		local function spawnParts()
			for _, v in partData do
				local part = Instance.new("Part")
				part.Color = Color3.fromRGB(0, 0, 0)
				part.Transparency = 0.9
				part.Position = v.pos
				part.Size = v.size
				part.Anchored = true
				part.CanCollide = true
				part.CanTouch = false
				part.CanQuery = false
				part.Parent = workspace.Map.Core
				table.insert(parts, part)
			end
		end
	
		local function cleanUp()
			for _, v in parts do
				v:Destroy()
			end
			table.clear(parts)
		end
	
		disableJanitor:Add(cleanUp)
	
		CombatTab:Checkbox({
			Label = "Anti-Void",
			Value = config.combat.misc.antiFall,
			saveFlag = "AntiVoid",
			Callback = function(self, Value)
				config.combat.misc.antiFall = Value
				if Value then
					spawnParts()
				else
					cleanUp()
				end
			end,
		})
	end

	--<< enterable domains
	do
		local function toggle(val: boolean)
			config.combat.misc.enterDomain = val
			if val then
				disableJanitor:Add(workspace.Domains.ChildAdded:Connect(function(child: Instance) 
					child.CanCollide = false
				end), nil, "enterDomains") 
				for _, v in workspace.Domains:GetChildren() do
					v.CanCollide = false
				end		
			else
				disableJanitor:Remove("enterDomains")
				for _, v in workspace.Domains:GetChildren() do
					v.CanCollide = true
				end		
			end
		end
	
		CombatTab:Checkbox({
			Label = "Enter Domains",
			Value = config.combat.misc.enterDomain,
			saveFlag = "EnterDomains",
			Callback = function(self, Value)
				toggle(Value)
			end,
		})
	end
end


--// whitelist handler
do
	CombatTab:Separator({
		Text = "Whitelist"
	})

	local dropdown = CombatTab:CollapsingHeader({
		Title = "Players",
		Open = false
	})

	local playerCheckboxes = {}

	local function playerAdded(player: Players)
		if player == Player then return end --<< if player is the LocalPlayer
		playerCheckboxes[player] = dropdown:Checkbox({
			Label = player.Name,
			Value = config.combat.whiteList[player.Name],
			--saveFlag = "Whitelist_" .. player.Name,
			Callback = function(self, Value)
				config.combat.whiteList[player.Name] = Value
			end,
		})
	end

	local function playerRemoving(player: Player)
		config.combat.whiteList[player.Name] = nil
		playerCheckboxes[player]:Destroy()
		playerCheckboxes[player] = nil
	end

	disableJanitor:Add (
		game.Players.PlayerAdded:Connect(playerAdded)
	)

	disableJanitor:Add (
		game.Players.PlayerRemoving:Connect(playerRemoving)
	)

	for _, v in game.Players:GetPlayers() do
		playerAdded(v)
	end
end



-->> keybinds
do
	KeybindsTab:Separator({
		"Press Backspace to Delete Keybind"
	})

	do
		--<< go behind enemy and attack
		local goBehindEnemyKeybind = KeybindsTab:Keybind({
			Label = "Attack Closest Enemy",
			Value = Enum.KeyCode.C,
			saveFlag = "goBehindEnemyKeybind",
			Callback = function()
				attack(getClosestCharacter(), true)
			end,
		})

		disableJanitor:Add( 
			function()
				goBehindEnemyKeybind.Callback = nil
			end
		)
	end
	
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

-->> disable (unload)
local function disable()
	disableJanitor:Cleanup()
	--Window:Close()
	Window:Destroy()
	dir.disable = nil
end

dir.disable = disable

-->> config saving & loading
Window:CreateConfigSaveHandler("JJS_SAKSO")

-->> unloading gui
local closeTab = Window:CreateTab({
	Name = "Unload",
	Visible = false
})

closeTab:Separator({

})

closeTab:Button({
    Text = "Unload the cheat",
    Callback = function(self)
        disable()
		ImGui:Notify("JJS-SAKSO", "Unloaded the cheat. Re-execute if you want to use again." , 3)
    end,
})

--// wiz special technique
if Player.Name == "IIlIllIIIIlIIIlllIIl" or Player.Name == "casckmaskcmwoda" then
	task.wait(5)
	ImGui:Notify("Sa", "Wiz sa nbr knks 31" , 5)
end