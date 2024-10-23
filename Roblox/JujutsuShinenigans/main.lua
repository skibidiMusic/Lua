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

--> ref
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService"RunService"

local ServiceFolder = game.ReplicatedStorage.Knit.Knit.Services

local Player = game:GetService("Players").LocalPlayer


-->> dep
--local fileManager = loadstring(game:HttpGet('https://raw.githubusercontent.com/skibidiMusic/Lua/refs/heads/main/Roblox/Util/fileManager.lua'))()
local ImGui = loadstring(game:HttpGet('https://raw.githubusercontent.com/skibidiMusic/Lua/refs/heads/main/Roblox/Util/UiLib/ImGui.lua'))()
local Janitor = loadstring(game:HttpGet('https://raw.githubusercontent.com/skibidiMusic/Lua/refs/heads/main/Roblox/Util/Janitor.lua'))()

-->> main

local disableJanitor = Janitor.new()

-->> default config
local config = {
	autoBlock = {
		enabled = false,
		tryDashIfNotBlockable = true,
		
		tryCounter = true, --< attempts a counter instead of blocking when counter is available
		punish = true, --< auto melees after a block
		
		lookAtPlayer = true, --< makes your character look to the player while blocking (prevent attacks from behind)
		lockCamera = false, --< makes your camera look at the player who tired to attack u (useless basically)
		
		Melee = true, --< block melee attacks
		chase = true, --< block chase attacks (front dash)

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
		
		whiteList = {
		}
	},

	misc = {
		alwaysBlackFlash = true, 
		enterDomain = true,
		antiFall = true,
	}
	
	-->> Misc
}


-->> Gui Setup
local Window = ImGui:CreateWindow({
	Title = "JUJUT-SAKSO SHIT-A-NIGGA-NS",
	Position = UDim2.new(0.5, 0, 0, 70), --// Roblox property 
	Size = UDim2.new(0, 300, 0, 500),
	AutoSize = false,
	NoClose = true
})

Window:Center()

--(tabs)
local AutoblockTab = Window:CreateTab({
	Name = "Autoblock",
	Visible = true 
})

local MiscTab = Window:CreateTab({
	Name = "Misc",
	Visible = false 
})

local ConsoleTab = Window:CreateTab({
	Name = "Console (Output)",
	Visible = false 
})

local KeybindsTab = Window:CreateTab({
	Name = "Keybinds",
	Visible = false 
})

local configsTab = Window:CreateTab({
	Name = "Configs",
	Visible = false 
})

local closeTab = Window:CreateTab({
	Name = "Close",
	Visible = false
})


-->> code
--// debugging (mini-console)

local debugConsole = {};

do
	ConsoleTab:Separator({
		Text = "This is for debuging"
	})

	local Row = ConsoleTab:Row()

	local Console = ConsoleTab:Console({
		Text = "Console",
		ReadOnly = true,
		LineNumbers = true,
		Border = true,
		Fill = false,
		Enabled = true,
		AutoScroll = true,
		RichText = true,
		MaxLines = 50
	})

	Row:Button({
		Text = "Clear",
		Callback = Console.Clear
	})
	
	Row:Checkbox({
		Label = "Pause",
		Value = false,
		Callback = function(self, Value)
			Console.Enabled = not Value
		end,
	})	

	Row:Checkbox({
		Label = "AutoScroll",
		Value = true,
		Callback = function(self, Value)
			Console.AutoScroll = Value
		end,
	})	

	Row:Fill()

	-->> functionality
	local function ToString(v:any, depth: number?)
		local dataType = typeof(v)
		local str;
	
		if dataType == "Instance" then
			dataType = v.ClassName
			str = v:GetFullName()
		else
			if dataType == "table" then
				depth = depth or 0
				local depthShit = string.rep("\t", depth)
				str = "{\n"
				for i, c in v do
					str = str .. string.format(depthShit .. "\t[%s]: %s,\n", tostring(i), ToString(c, depth + 1))
				end
				str = str .. depthShit .. "}"
			elseif dataType == "string" then
				str = string.format("%q", v)
			else
				str = tostring(v)
			end
		end
	
		return string.format("(%s) %s", dataType, str)
	end

    function debugConsole.advancedToString(v)
        return ToString(v)
    end

	function debugConsole.print(...)
		debugConsole.ui:AppendText(...)
	end

	debugConsole.ui = Console

	ConsoleTab:Separator({})
end


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
	wasCameraEnabled = true, 
	lastCameraSubject = nil;
	Humanoid = nil;
}

local function stopLookingAt()
	if not isLookingAt then return end
	game:GetService("RunService"):UnbindFromRenderStep("lvfkma231231kaslslvlscas123")
	lookAtData.Humanoid.AutoRotate = true

	if lookAtData.wasCameraEnabled then
		workspace.Camera.CameraType = Enum.CameraType.Custom
		if lookAtData.lastCameraSubject and lookAtData.lastCameraSubject.Parent then
			workspace.Camera.CameraSubject = lookAtData.lastCameraSubject
		else
			workspace.Camera.CameraSubject = Player.Character.Head
		end
	end
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

	lookAtData.wasCameraEnabled = cameraEnabled

	if cameraEnabled then
		lookAtData.lastCameraSubject = workspace.Camera.CameraSubject
		workspace.Camera.CameraType = Enum.CameraType.Watch
		workspace.Camera.CameraSubject = enemy
	end

	game:GetService("RunService"):BindToRenderStep("lvfkma231231kaslslvlscas123", Enum.RenderPriority.Last.Value + 100, function()
		local enemyFuturePosition = findFuturePos(enemy, Player:GetNetworkPing() * enemyPosMultiplier * 0.5)
		localChar.PrimaryPart.CFrame = CFrame.lookAt(localChar.PrimaryPart.CFrame.Position, enemyFuturePosition)
	end)
end

disableJanitor:Add(stopLookingAt)

--(attacking)
local function attack(enemy: Model)
	local char = Player.Character
	if not char then return end 
	
	local diff = distanceFromCharacter(enemy)
	if diff.Magnitude > 8 then
		return
	end

	local currentMoveset = char:GetAttribute("Moveset")
	local service = game.ReplicatedStorage.Knit.Knit.Services[currentMoveset .. "Service"]

	local remote = service.RE.Activated
	remote:FireServer("Down")

	lookAt(enemy)
	task.delay(.1, stopLookingAt)
end

--(counter)
local function counter()
	local localChar = Player.Character
	if not localChar then return end
	
	local currentMoveset = localChar:GetAttribute("Moveset")
	
	if localChar:FindFirstChild"Moveset" and localChar:FindFirstChild("Moveset"):FindFirstChild("Manji Kick") then
		local service = game.ReplicatedStorage.Knit.Knit.Services.ManjiKickService
		local remote = service.RE.Activated
		remote:FireServer()
	elseif currentMoveset == "Hakari" then
		
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
	if not config.autoBlock.enabled or config.autoBlock.whiteList[enemy and enemy.Name] then return end
	
	local localChar = Player.Character
	if not localChar then return end

	if isBlocking then
		stopBlock(true)
	end

	isBlocking = true
	length = math.max(length - Player:GetNetworkPing() * 0.5, 0)


	if config.autoBlock.lookAtPlayer then lookAt(enemy, config.autoBlock.lockCamera, enemySpeedMultiplier) end
	
	if tryCounter and config.autoBlock.tryCounter then
		counter()
	end

	blockData.loopThread = task.defer(function()
		while task.wait(0.025) do
			blockRemotes.Activated:FireServer()
		end
	end)

	blockData.delayThread = task.delay(length, function()
		stopBlock(game.UserInputService:IsKeyDown(Enum.KeyCode.F))
		if punish then
			attack(enemy)
		end
	end)
end


--// AUTOBLOCK

--few toggles
AutoblockTab:Separator({
	Text = "Tunes"
})

AutoblockTab:Checkbox({
	Label = "Enabled",
	Value = true,
	saveFlag = "BlockEnabled",
	Callback = function(self, Value)
		config.autoBlock.enabled = Value
	end,
})

AutoblockTab:Checkbox({
	Label = "Try Countering",
	Value = true,
	saveFlag = "CounterToggle",
	Callback = function(self, Value)
		config.autoBlock.tryCounter = Value
	end,
})

AutoblockTab:Checkbox({
	Label = "Punish",
	Value = true,
	saveFlag = "PunishToggle",
	Callback = function(self, Value)
		config.autoBlock.punish = Value
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
}

--// autoblock logic
--(melee)
do
	local meleeBlockHeader = AutoblockTab:CollapsingHeader({
		Title = "Melee",
		Open = false
	})
	
	--melee attacks
	do
		-->> ui
		meleeBlockHeader:Checkbox({
			Label = "Block Melee",
			Value = true,
			saveFlag = "BlockMelee",
			Callback = function(self, Value)
				config.autoBlock.Melee = Value
			end,
		})
	
		-->> hook
		local function meleeDetected(enemyChar: Model, COMBO: number?)
			if not config.autoBlock.Melee then return end
			local localChar = Player.Character
			if localChar and localChar ~= enemyChar then
				local diffVec : Vector3 = distanceFromCharacter(findFuturePos(enemyChar.PrimaryPart))
				if math.abs(diffVec.Y) < 4 then
					diffVec = normalizeToGround(diffVec)
					if enemyChar:GetAttribute("Moveset") == "Itadori" and enemyChar:GetAttribute("InUlt") then
						if normalizeToGround(diffVec).Magnitude < 20 then	
							block(enemyChar, 0.55, 1, diffVec.Magnitude < 10 and config.autoBlock.punish and COMBO == 4, true)
						end
					else
						if diffVec.Magnitude < 15 then	
							block(enemyChar, 0.35, 1, config.autoBlock.punish and diffVec.Magnitude < 10)
						end 
					end
				end
			end
		end
	
		for name in characterNames do
			local service = ServiceFolder:FindFirstChild(name .. "Service")
			if service then
				if name == "Mahoraga" or name == "Mahito" then
					disableJanitor:Add(service.RE.Effects.OnClientEvent:Connect(function(action: string, character: Model, combo: number, finish: string?)
						if action == "Swing" then
							meleeDetected(character)
						end
					end))
				else
					disableJanitor:Add(service.RE.Effects.OnClientEvent:Connect(function(action: string, character: Model, combo: number, finish: string?)
						if action == "Swing2" then
							meleeDetected(character, combo)
						end
					end))
				end
			end
		end
	end
	
	--chase (front dash)
	do
		-->> ui
		meleeBlockHeader:Checkbox({
			Label = "Block Chase",
			Value = true,
			saveFlag = "BlockChase",
			Callback = function(self, Value)
				config.autoBlock.chase = Value
			end,
		})
	
		-->> hook
		local function chaseDetected(enemyChar: Model)
			if not config.autoBlock.chase then return end
			local localChar = Player.Character
			if localChar and localChar ~= enemyChar then
				local diffVec : Vector3 = distanceFromCharacter(findFuturePos(enemyChar.PrimaryPart))
				if math.abs(diffVec.Y) < 15 then
					diffVec = normalizeToGround(diffVec)
					if diffVec.Magnitude < 35 then
						if diffVec.Magnitude < 12 or diffVec.Unit:Dot(-enemyChar:GetPivot().LookVector) > 0.8  then
							block(enemyChar, 0.5, 3, true, true)
						end
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
	local skillBlockHeader = AutoblockTab:CollapsingHeader({
		Title = "Skills",
		Open = false
	})

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
				Value = true,
				saveFlag = "blockCursedStrikes",
				Callback = function(self, Value)
					config.autoBlock.Itadori.blockCursedStrikes = Value
				end,
			})

			local function cursedStrikesDetected(enemy: Model, from: CFrame)
				if not config.autoBlock.Itadori.blockCursedStrikes then return end
				if typeof(from) ~= "CFrame" then return end
				local localChar = Player.Character
				if localChar and enemy ~= Player.Character then
					local distance = distanceFromCharacter(from.Position)
					if distance and math.abs(distance.Y) < 8 then
						distance = normalizeToGround(distance)
						if distance.Magnitude < 40 then
							if distance.Magnitude < 15 then
								block(enemy, 0.5, 1, true)
							elseif distance.Unit:Dot(-from.LookVector) > 0.5 then
								block(enemy, 0.5, 1, true)
							end
						end
					end
				end
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
				Value = true,
				Callback = function(self, Value)
					config.autoBlock.Megumi.blockToad = Value
				end,
			})

			local function toadDetected(enemy: Model)
				if not config.autoBlock.Megumi.blockToad then return end
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
				Value = true,
				saveFlag = "BlockWolf",
				Callback = function(self, Value)
					config.autoBlock.Megumi.blockDog = Value
				end,
			})

			local function dogDetected(dogModel: Model, target: Model)
				if not config.autoBlock.Megumi.blockDog then return end
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
				Value = true,
				saveFlag = "MahitoFocusStrike",
				Callback = function(self, Value)
					config.autoBlock.Mahito.blockFocusStrike = Value
				end,
			})

			local function focusStrikeDetected(enemy: Model)
				if not config.autoBlock.Mahito.blockFocusStrike then return end
				local localChar = Player.Character
				if localChar and enemy ~= Player.Character then
					local distance = distanceFromCharacter(enemy)
					if distance and math.abs(distance.Y) < 8 then
						distance = normalizeToGround(distance)
						if distance.Magnitude < 25 then
							if distance.Magnitude < 15 then
								block(enemy, 0.5, 1, true, true)
							elseif distance.Unit:Dot(-enemy:GetPivot().LookVector) > 0.8 then
								block(enemy, 0.5, 1, true, true)
							end
						end
					end
				end
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
				Value = true,
				saveFlag = "MahitoBullets",
				Callback = function(self, Value)
					config.autoBlock.Mahito.blockSoulFire = Value
				end,
			})

			local function soulFireDetected(enemy: Model)
				if not config.autoBlock.Mahito.blockSoulFire then return end
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
				Value = true,
				saveFlag = "MahitoSpecialDash",
				Callback = function(self, Value)
					config.autoBlock.Mahito.blockSpecialDash = Value
				end,
			})

			local function specialDashDetected(enemy: Model, style: number)
				if not config.autoBlock.Mahito.blockSpecialDash then return end
				local localChar = Player.Character
				if localChar and enemy ~= Player.Character then
					local distance = distanceFromCharacter(enemy)
					if distance and math.abs(distance.Y) < 8 then
						distance = normalizeToGround(distance)
						if distance.Magnitude < 25 then
							if distance.Magnitude < 8 or distance.Unit:Dot(-enemy:GetPivot().LookVector) > 0.8  then
								if style == 1 then
									block(enemy, 0.5, 1, true, false)
								else
									counter()
								end
		
							end
						end
					end
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
				Value = true,
				saveFlag = "blockLapseBlue",
				Callback = function(self, Value)
					config.autoBlock.Gojo.blockLapseBlue = Value
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
				if not config.autoBlock.Gojo.blockLapseBlue then return end
				local localChar = Player.Character
				if not localChar then return end
				if tick() - grabbedTick < .2 then
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
				Value = true,
				saveFlag = "BlockReversalRed",
				Callback = function(self, Value)
					config.autoBlock.Gojo.blockReversalRed = Value
				end,
			})

			--<< projectile shot
			local raycastParams = RaycastParams.new()
			raycastParams.FilterDescendantsInstances = {workspace.Effects, workspace.Bullets}

			local function redProjectileDetected(projectile: BasePart)
				if not config.autoBlock.Gojo.blockReversalRed then return end

				local appearTick = tick()
				local thread = task.defer(function()
					while task.wait() do
						local localChar = Player.Character
						if not localChar then continue end

						if distanceFromCharacter(projectile).Magnitude < 15 then
							if tick() - appearTick > 1.7 - Player:GetNetworkPing() or workspace:Raycast(projectile.CFrame.Position, projectile.CFrame.LookVector * Player:GetNetworkPing() * 30, raycastParams) then
								debugConsole.print("explosion detected!")
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
				if not config.autoBlock.Gojo.blockReversalRed then return end

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


--(whitelist for autoblock)
do
	AutoblockTab:Separator({
		Text = "Whitelist"
	})

    local whitelistRow = AutoblockTab:Row()

    local function updateState(name: string)
        if config.autoBlock.whiteList[name] then
            config.autoBlock.whiteList[name]:Destroy()
            config.autoBlock.whiteList[name] = nil
        else
            config.autoBlock.whiteList[name] = whitelistRow:Button({
                Text = name,
                Callback = function(self)
                    updateState(name)
                end,
            })
        end
    end

    AutoblockTab:Separator({})

    local dropdown;

    local function playerListChanged()
        if dropdown then dropdown:Destroy() end
        local players = game.Players:GetPlayers()
        for i, v: Player in game.Players do
            players[i] = v.Name
        end
        dropdown = AutoblockTab:Combo({
            Placeholder = "Choose to add.",
            Label = "Players",
            Items = players,
            Callback = function(self, Value)
                updateState(Value)
            end,
        })
    end

    playerListChanged()

    disableJanitor:Add( game.Players.PlayerAdded:Connect(function(player)
        playerListChanged()
    end) )

    disableJanitor:Add( game.Players.PlayerRemoving:Connect(function(player)
        playerListChanged()
    end) )
end


--// misc. stuff
MiscTab:Separator({

})


--(entering domains)
do
	local function toggle(val: boolean)
		config.misc.enterDomain = val
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

	MiscTab:Checkbox({
		Label = "Enter Domains",
		Value = true,
		saveFlag = "EnterDomains",
		Callback = function(self, Value)
			toggle(Value)
		end,
	})
end

--(always black flash)
do
	local remote = ServiceFolder.DivergentFistService.RE.Activated
	
	local function blackFlashDetected(character: Model)
		if not config.misc.alwaysBlackFlash then return end
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

	MiscTab:Checkbox({
		Label = "Always Black Flash",
		Value = true,
		saveFlag = "AlwaysBlackFlash",
		Callback = function(self, Value)
			config.misc.alwaysBlackFlash = Value
		end,
	})
end

--(u cant fall off map)
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

	MiscTab:Checkbox({
		Label = "Anti-Void",
		Value = true,
		Callback = function(self, Value)
			config.misc.antiFall = Value
			if Value then
				spawnParts()
			else
				cleanUp()
			end
		end,
	})
end

--<< clear parts
do
	MiscTab:Button({
		Text = "Clear Parts (fix lag?)",
		Callback = function(self)
			for _, v in workspace.Map.Data:GetChildren() do
				v:Destroy()
			end
		end,
	})
end



-->> keybinds
KeybindsTab:Separator({

})

KeybindsTab:Keybind({
	Label = "Toggle UI",
	Value = Enum.KeyCode.RightControl,
	saveFlag = "ToggleUiKeybind",
	Callback = function()
		Window:SetVisible(not Window.Visible)
	end,
})


-->> config saving & loading
Window:CreateConfigSaveHandler("JJS_SAKSO")

-->> unloading the gui
local function disable()
	disableJanitor:Cleanup()
	Window:Destroy()
	dir.disable = nil
end

closeTab:Separator({

})

closeTab:Button({
    Text = "Unload the cheat",
    Callback = function(self)
        disable()
    end,
})

dir.disable = disable