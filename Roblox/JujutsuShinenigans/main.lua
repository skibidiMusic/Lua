-->> fix repeats
local env = getgenv() :: {};

local dir = env.jjsSakso
if dir and dir.Disable then
    dir.Disable()
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
local ImGui = loadstring(game:HttpGet('https://github.com/depthso/Roblox-ImGUI/raw/main/ImGui.lua'))()
local Janitor = loadstring(game:HttpGet('https://raw.githubusercontent.com/skibidiMusic/Lua/refs/heads/main/Roblox/Util/Janitor.lua'))()


-->> main
local disableJanitor = Janitor.new()
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
		
		whiteList = {
			["length214907"] = true,
			["WilliamsChild7s"] = true
		}
	},

	misc = {
		alwaysBlackFlash = true, 
		enterDomain = true,
		antiFall = true,
	}
	
	-->> Misc
}


-->> gui
local Window = ImGui:CreateWindow({
	Title = "JUJUT-SAKSO SHIT-A-NIGGA-NS",
	Position = UDim2.new(0.5, 0, 0, 70), --// Roblox property 
	AutoSize = "Y",
})
Window:Center()

local AutoblockTab = Window:CreateTab({
	Name = "Autoblock",
	Visible = true 
})

local MiscTab = Window:CreateTab({
	Name = "Misc",
	Visible = true 
})


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

local function findFuturePos(v: BasePart, t: number?)
	if not t then t = Player:GetNetworkPing() * .5 end
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
		local enemyFuturePosition = findFuturePos(enemy.PrimaryPart, Player:GetNetworkPing() * enemyPosMultiplier * 0.5)
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
	
	if currentMoveset == "Itadori" then
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
AutoblockTab:Checkbox({
	Label = "Enabled",
	Value = false,
	Callback = function(self, Value)
		config.autoBlock.enabled = Value
	end,
})

AutoblockTab:Checkbox({
	Label = "Try Countering",
	Value = false,
	Callback = function(self, Value)
		config.autoBlock.tryCounter = Value
	end,
})

AutoblockTab:Checkbox({
	Label = "Punish",
	Value = false,
	Callback = function(self, Value)
		config.autoBlock.punish = Value
	end,
})

--(melee)
local meleeBlockHeader = AutoblockTab:CollapsingHeader({
	Title = "Functions",
	Open = true
})

--melee attacks
do
	-->> ui
	meleeBlockHeader:Checkbox({
		Label = "Block Melee",
		Value = false,
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
		Value = false,
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
					if diffVec.Magnitude < 8 or diffVec.Unit:Dot(-enemyChar:GetPivot().LookVector) > 0.8  then
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








local autoblockMelee = {}



--// CONFIG AND LOADUP SHIT
local config = {

	
}









--// block Melee

--// block chase(dash)
if config.autoBlock.chase then
	local function chaseDetected(enemyChar: Model)
		local localChar = Player.Character
		if localChar and localChar ~= enemyChar then
			local diffVec : Vector3 = distanceFromCharacter(findFuturePos(enemyChar.PrimaryPart))
			if math.abs(diffVec.Y) < 15 and diffVec.Magnitude < 35 then	
				if diffVec.Magnitude < 15 or diffVec.Unit:Dot(-enemy:GetPivot().LookVector) > 0.8  then
					block(enemyChar, 0.5, 3, true, true)
				end
			end 
		end
	end

	local remoteHooks = {}

	for name in characterNames do
		local service = ServiceFolder:FindFirstChild(name .. "Service")
		if service then
			table.insert(remoteHooks, service.RE.Effects.OnClientEvent:Connect(function(action: string, character: Model)
				if action == "Chase" then
					chaseDetected(character)
				end
			end))
		end
	end

	table.insert(disableFuncs, function()
		for _, v in remoteHooks do
			v:Disconnect()
		end
	end)
end

--// enter domain
if config.enterDomain then
	local function domainDetected(domainPart: BasePart)
		domainPart.CanCollide = false
	end

	local hook = workspace.Domains.ChildAdded:Connect(function(child: Instance) 
		domainDetected(child)
	end)

	for _, v in workspace.Domains:GetChildren() do
		domainDetected(v)
	end

	table.insert(disableFuncs, function()
		hook:Disconnect()
	end)
end

--// block megumi skills

--(toad)
if config.autoBlock.Megumi.blockToad then
	local function toadDetected(enemy: Model)
		task.delay(.4 - Player:GetNetworkPing() * 0.5, block, enemy, .5, 1, false, false)
	end

	local remoteHook = ServiceFolder.ToadService.RE.Effects.OnClientEvent:Connect(function(action: string, enemy: Model, target: Model) 
		if (action == "Toad" or action == "ToadAir") and target == Player.Character then
			toadDetected(enemy.Character)
		end
	end)

	table.insert(disableFuncs, function()
		remoteHook:Disconnect()
	end)
end

--(dog)
if config.autoBlock.Megumi.blockDog then
	local function dogDetected(dogModel: Model, target: Model)
		task.wait(.3 - Player:GetNetworkPing() * 0.5)
		if distanceFromCharacter(target).Magnitude < 6 then
			block(dogModel, .25, 1, false, true)
		end
	end

	local remoteHook = ServiceFolder.DivineDogService.RE.Effects.OnClientEvent:Connect(function(action: string, dogModel: Model) 
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
	end)

	table.insert(disableFuncs, function()
		remoteHook:Disconnect()
	end)
end

--// block Itadori Skills

--(cursed strikes)
if config.autoBlock.Itadori.blockCursedStrikes then
	local function cursedStrikesDetected(enemy: Model, from: CFrame)
		if typeof(from) ~= "CFrame" then return end
		local localChar = Player.Character
		if localChar and enemy ~= Player.Character then
			local distance = distanceFromCharacter(from.Position)
			if distance then
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

	local remoteHook1 = ServiceFolder.CursedStrikesService.RE.Effects.OnClientEvent:Connect(function(action: string, enemy: Model, cfRame: CFrame)
		if action == "Dash" then
			cursedStrikesDetected(enemy, cfRame)
		end
	end)

	local remoteHook2 = ServiceFolder.CursedStrikesService.RE.Effects.OnClientEvent:Connect(function(action: string, enemy: Model, cfRame: CFrame)
		if action == "Swing" then
			cursedStrikesDetected(enemy, enemy.PrimaryPart.CFrame)
		end
	end)

	table.insert(disableFuncs, function()
		remoteHook1:Disconnect()
		remoteHook2:Disconnect()
	end)
end

--// mahito skills
if config.autoBlock.Mahito.blockFocusStrike then
	local function focusStrikeDetected(enemy: Model)
		local localChar = Player.Character
		if localChar and enemy ~= Player.Character then
			local distance = distanceFromCharacter(enemy)
			if distance then
				if distance.Magnitude < 25 then
					if distance.Magnitude < 15 then
						block(enemy, 0.5, 1, true, true)
					elseif distance.Unit:Dot(-enemy:GetPivot().LookVector) > 0.7 then
						block(enemy, 0.5, 1, true, true)
					end
				end
			end
		end
	end
	
	local remoteHook1 = ServiceFolder.FocusStrikeService.RE.Effects.OnClientEvent:Connect(function(action: string, enemy: Model, cfRame: CFrame)
		if action == "Startup" then
			focusStrikeDetected(enemy)
		end
	end)

	local remoteHook2 = ServiceFolder.FocusStrikeService.RE.Effects.OnClientEvent:Connect(function(action: string, enemy: Model, cfRame: CFrame)
		if action == "Swing" then
			focusStrikeDetected(enemy)
		end
	end)

	table.insert(disableFuncs, function()
		remoteHook1:Disconnect()
		remoteHook2:Disconnect()
	end)
end

if config.autoBlock.Mahito.blockSoulFire then
	local function soulFireDetected(enemy: Model)
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
	
	local remoteHook = ServiceFolder.SoulfireService.RE.Effects.OnClientEvent:Connect(function(action: string, char: Model) 
		if action == "Morph" then
			soulFireDetected(char)
		end
	end)
	
	table.insert(disableFuncs, function()
		remoteHook:Disconnect()
	end)
end

if config.autoBlock.Mahito.blockSpecialDash then
	local function specialDashDetected(enemy: Model, style: number)
		local localChar = Player.Character
		if localChar and enemy ~= Player.Character then
			local distance = distanceFromCharacter(enemy)
			if distance then
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

	local remoteHook1 = ServiceFolder.MahitoService.RE.Effects.OnClientEvent:Connect(function(action: string, enemy: Model, style: number)
		if action == "ChaseStart" then
			specialDashDetected(enemy, style)
		end
	end)

	local remoteHook2 = ServiceFolder.MahitoService.RE.Effects.OnClientEvent:Connect(function(action: string, enemy: Model, style: number)
		if action == "Chase2" then
			specialDashDetected(enemy, style)
		end
	end)

	table.insert(disableFuncs, function()
		remoteHook1:Disconnect()
		remoteHook2:Disconnect()
	end)
end



--//
--misc stuff 

--// always black flash
if config.alwaysBlackFlash then
	local remote = ServiceFolder.DivergentFistService.RE.Activated
	
	local function blackFlashDetected(character: Model)
		local localChar = Player.Character
		if not localChar or localChar ~= character then return end
		
		task.wait(.2 - Player:GetNetworkPing())
		remote:FireServer()
	end
	
	local remoteHook = ServiceFolder.DivergentFistService.RE.Effects.OnClientEvent:Connect(function(effectName: string, char: Model) 
		if effectName == "CurseBuild" then
			blackFlashDetected(char)
		end
	end)
	
	table.insert(disableFuncs, function()
		remoteHook:Disconnect()
	end)
end

if config.antiFall then
	local partData = {
		{size = Vector3.new(-17.25, 11.75, -533.115), pos = Vector3.new(740.5, 2.5, 372.771)},
		{size = Vector3.new(145, 2.5, 1389.771), pos = Vector3.new(352.5, 11.75, -24.615)},
		{size = Vector3.new(598, 2.5, 36.771), pos = Vector3.new(126, 11.75, 651.885)},
		{size = Vector3.new(298, 2.5, 1091.271), pos = Vector3.new(-313.5, 11.75, 124.635)}
	}
	
	local parts = {}
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
	
	table.insert(disableFuncs, function()
		for _, v in parts do
			v:Destroy()
		end
	end)
end

--//

local function disable()
	for _, v in disableFuncs do
		v()
	end
end

dir.disable = disable