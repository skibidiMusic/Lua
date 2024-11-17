-->> LOADSTRING
--[[
	loadstring(game:HttpGet('https://raw.githubusercontent.com/skibidiMusic/Lua/refs/heads/main/Roblox/JujutsuShinenigans/Init.lua'))()
]]

-->> SRC
local ImGui = loadstring(game:HttpGet('https://raw.githubusercontent.com/skibidiMusic/Lua/refs/heads/main/Roblox/Util/UiLib/ImGui.lua'))()
local Janitor = loadstring(game:HttpGet('https://raw.githubusercontent.com/skibidiMusic/Lua/refs/heads/main/Roblox/Util/Misc/Janitor.lua'))()

if JJS_SAKSO then
    if JJS_SAKSO.unload then
        JJS_SAKSO.unload()
    end
else
    getgenv().JJS_SAKSO = {}
end

--atlantis require fix
do
    local require = function(v)
        setidentity(2)
        local m = require(v)
        setidentity(8)
        return m
    end
end


local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ServiceFolder = ReplicatedStorage.Knit.Knit.Services
local Player = game:GetService("Players").LocalPlayer


local Window = ImGui:CreateWindow({Title = "JUJUT-SAKSO SHIT-A-NIGGA-NS", Position = UDim2.new(0.5, 0, 0, 70), Size = UDim2.new(0, 800, 0, 500), AutoSize = false,})

Window:Center()


local hooks = Janitor.new()
JJS_SAKSO.unload = function()
    hooks:Cleanup()
	Window:Destroy()
	JJS_SAKSO.unload = nil
end



--tabs
local function checkbox(tab, name: string, flag: string?, default: boolean?, keybind: Enum.KeyCode?, callback: (v: boolean) -> any)
    if keybind then
        local Row = tab:Row({})
        local checkBox = Row:Checkbox({
            Label = name,
            Value = default or true,
            saveFlag = name,
            Callback = function(self, Value)
                callback(Value)
            end,
        })
        local kb = Row:Keybind({
            Label = "Keybind",
            Value = keybind,
            saveFlag = flag .. "keybind",
            Callback = function()
                checkBox:Toggle()
            end,
        })
        Row:Fill()
        return checkBox, kb, Row
    else
        local checkBox = tab:Checkbox({
            Label = name,
            Value = default or true,
            saveFlag = flag,
            Callback = function(self, Value)
                callback(Value)
            end,
        })
        return checkBox
    end
end

-- combat
do
    local util = {}

    do
        function util.distanceFromCharacter(v: Model | BasePart | Vector3) : Vector3?
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
        
        function util.getClosestCharacter()
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
        
        function util.findFuturePos(v: BasePart | Model, t: number?)
            if not t then t = Player:GetNetworkPing() * .5 end
            if v:IsA("Model") then
                v = v.PrimaryPart
            end
            return v.Position + v.AssemblyLinearVelocity * t
        end
        
        function util.normalizeToGround(vector: Vector3)
            return vector * Vector3.new(1, 0, 1)
        end
    end

    local combat = {}

    -- config
    combat.autoBlockEnabled = true
    combat.counterEnabled = true
    combat.punishEnabled = true

    combat.whitelist = {}


    -- counter
    do
        local manjiKick = ServiceFolder.ManjiKickService.RE.Activated
        local hakariCounter = ServiceFolder.HakariService.RE.RightActivated
        local mahitoCounter = ServiceFolder.HeadSplitterService.RE.Activated
        function combat.counter(enemy: Model?)
            if combat.whitelist[enemy and enemy.Name] then return end
            
            local localChar = Player.Character
            if not localChar then return end

            -- itadori
            manjiKick:FireServer()
            
            -- mahito & hakari
            local dist = util.distanceFromCharacter(util.findFuturePos(enemy))
            if util.normalizeToGround(dist).Magnitude < 16 then
                mahitoCounter:FireServer()
                if localChar:GetAttribute("Moveset") == "Hakari" and not localChar:GetAttribute("InUlt") then
                    hakariCounter:FireServer()
                end
            end
        end
    end


    -- attack
    function combat.attack(enemy: Model, goBehindEnemy: boolean?)
        if combat.whitelist[enemy and enemy.Name]  then return end

        local char = Player.Character
        if not char then return end
    
        local currentMoveset = char:GetAttribute("Moveset")
        local service = game.ReplicatedStorage.Knit.Knit.Services[currentMoveset .. "Service"]
    
        local remote = service.RE.Activated
    
        if goBehindEnemy then
            if char.Info:FindFirstChild("Stun") then return end
    
            local diff = util.distanceFromCharacter(enemy)
    
            local goBehindThread = task.defer(function()
                while true do
                    local dt = task.wait()
                    remote:FireServer("Down")
                    char:PivotTo(char:GetPivot():Lerp(enemy:GetPivot() * CFrame.new(Vector3.new(0,0 , 4)), dt * 16))
                end
            end)
    
            local lockOn = combat.lockOn(enemy, 1, nil, 2)
    
            task.wait(.35)
            task.cancel(goBehindThread)
            lockOn:Destroy()
        else
            local diff = util.distanceFromCharacter(enemy)
            if diff.Magnitude > 8 then
                return
            end
        
            remote:FireServer("Up")
            combat.lockOn(enemy, 1, .2, 2)
        end	
    end

    -- lock on
    do
        local lockOn = {}
        lockOn.instances = {}
        lockOn.__index = lockOn

        function lockOn:Destroy()
            if self.delayThread then
                task.cancel(self.delayThread)
            end
            table.remove(lockOn.instances, table.find(lockOn.instances, self))
            setmetatable(self, nil)
            table.clear(self)
        end

        function lockOn:Stop()
            return self:Destroy()
        end

        function combat.lockOn(target, enemyPosMultiplier: number?, length: number?, priority: number?)
            local self = setmetatable({}, lockOn)
            self.target = target
            self.enemyPosMultiplier = enemyPosMultiplier or 1
            self.priority = priority or 1
            
            local index = nil
            for i, v in lockOn.instances do
                if self.priority >= v.priority then
                    index = i
                    break
                end
            end
            if index then
                table.insert(lockOn.instances, index, self)
            else
                table.insert(lockOn.instances, self)
            end


            if length then
                self.delayThread = task.delay(length, function()
                    self.delayThread = nil
                    self:Destroy()
                end)
            end

            return self
        end

        --binding the loop
        local rand = tostring(math.random(1, 39458349))

        hooks:Add (
            function()
                RunService:UnbindFromRenderStep(rand)
            end
        )
        
        RunService:BindToRenderStep(rand, Enum.RenderPriority.Last.Value + 100, function(dt)
            local localChar = Player.Character
            local hum = localChar and localChar:FindFirstChild("Humanoid")
            if not hum then return end
            for i, v in lockOn.instances do
                if not v.target then continue end

                local target;
                if typeof(v.target) == "CFrame" then
                    target = v.target.Position
                elseif typeof(v.target) == "Instance" then
                    if not v.target.Parent then continue end
                    target = util.findFuturePos(v.target, Player:GetNetworkPing() * v.enemyPosMultiplier * 0.5)
                elseif typeof(v.target) == "Vector3" then
                    target = v.target
                end
                if not target or target.Magnitude < 0.01 or util.distanceFromCharacter(target).Magnitude > 100 then continue end

                hum.AutoRotate = false
                localChar.PrimaryPart.CFrame = CFrame.lookAt(localChar.PrimaryPart.CFrame.Position,  util.normalizeToGround(target) + Vector3.new(0, Player.Character.PrimaryPart.CFrame.Position.Y, 0))
                return
            end
            hum.AutoRotate = true
        end)
    end

    -- block
    do
        local blockRemotes = ServiceFolder.BlockService.RE

        local block = {}
        block.lockOn = combat.lockOn()
        block.isBlocking = false
        block.instances = {}
        block.__index = block

        function block:Destroy(punish: boolean?)
            table.remove(block.instances, table.find(block.instances, self))
            setmetatable(self, nil)
            if punish and self.target then
                for _, v in block.instances do
                    if v.enabled and v.target then
                        return
                    end
                end
                block.isBlocking = false
                block.lockOn.target = nil
                blockRemotes.Deactivated:FireServer()
                combat.attack(self.target)
            end
        end

        function block:Stop(punish: boolean?)
            return self:Destroy(punish)
        end

        function combat.block(target, length: number?, enemyPosMultiplier: number?, punish: boolean?, tryCounter: boolean?, enabled: boolean?, priority: number?)
            local self = setmetatable({
                target = target,
                length = length,
                enemyPosMultiplier = enemyPosMultiplier,
                punish = punish,
                enabled = if enabled ~= nil then enabled else true,
                priority = priority or 1,
                __startClock = os.clock(),
                --__lockOn = combat.lockOn(target, enemyPosMultiplier)
            }, block)

            local index = nil
            for i, v in block.instances do
                if self.priority >= v.priority then
                    index = i
                    break
                end
            end
            if index then
                table.insert(block.instances, index, self)
            else
                table.insert(block.instances, self)
            end

            if tryCounter and self.target then
                combat.counter(self.target)
            end

            return self
        end

        -- binding the loop
        local rand = tostring(math.random(39458350, 39458349 * 2))

        hooks:Add (
            function()
                RunService:UnbindFromRenderStep(rand)
            end
        )
        RunService:BindToRenderStep(rand, Enum.RenderPriority.Last.Value + 50, function(dt)
            local localChar = Player.Character
            if localChar then
                local found = false

                for i, v in block.instances do
                    if not v.enabled or not v.target or combat.whitelist[v.target.Name] then continue end
    
                    block.lockOn.target = v.target
                    block.lockOn.enemyPosMultiplier = v.enemyPosMultiplier
    
                    blockRemotes.Activated:FireServer()
                    block.isBlocking = true

                    found = true
                    break
                end
    
                if not found and block.isBlocking then
                    block.isBlocking = false
                    block.lockOn.target = nil
                    if not game.UserInputService:IsKeyDown(Enum.KeyCode.F) then
                        blockRemotes.Deactivated:FireServer()
                    end
                end
            end
            
            -- delay thingy
            for i, v in block.instances do
                if v.length and os.clock() - v.__startClock >= v.length - Player:GetNetworkPing() then
                    v:Destroy(v.punish)
                end
            end
        end)
    end

    local CombatTab = Window:CreateTab({
        Name = "Combat",
        Visible = true 
    })

    -- autoblock
    -- base config
    CombatTab:Separator({
        Text = "autoBlock"
    })
    
    CombatTab:Checkbox({
        Label = "Enabled",
        Value = true,
        saveFlag = "BlockEnabled",
        Callback = function(self, Value)
            combat.autoBlockEnabled = Value
        end,
    })
    
    CombatTab:Checkbox({
        Label = "Auto Counter",
        Value = true,
        saveFlag = "CounterToggle",
        Callback = function(self, Value)
            combat.counterEnabled = Value
        end,
    })
    
    CombatTab:Checkbox({
        Label = "Punish",
        Value = true,
        saveFlag = "PunishToggle",
        Callback = function(self, Value)
            combat.punishEnabled = Value
        end,
    })
    
    

    local characterNames = {
        Megumi = true,
        Mahoraga = true,
        Mahito = true,
        Itadori = true,
        Hakari = true,
        Gojo = true,
        Choso = true,
    }
    
    --autoBlock logic
    --melee
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
            local enabled = true

            -->> ui
            meleeBlockHeader:Checkbox({
                Label = "Punches",
                Value = enabled,
                saveFlag = "BlockMelee",
                Callback = function(self, Value)
                    enabled = Value
                end,
            })
        
            -->> hook
            local function meleeDetected(enemyChar: Model, COMBO: number?)
                if not enabled then return end
                local localChar = Player.Character
                if localChar == enemyChar then
                    return
                end
                if localChar then
                    local diffVec : Vector3 = util.distanceFromCharacter(util.findFuturePos(enemyChar.PrimaryPart))
                    if math.abs(diffVec.Y) < 4 then
                        diffVec = util.normalizeToGround(diffVec)
                        if enemyChar:GetAttribute("Moveset") == "Itadori" and enemyChar:GetAttribute("InUlt") then
                            if util.normalizeToGround(diffVec).Magnitude < 20 then	
                                combat.block(enemyChar, 0.55, 1, COMBO == 4, true)
                            end
                        else
                            if diffVec.Magnitude < 15 then	
                                combat.block(enemyChar, 0.35, 1, true, true)
                            end 
                        end
                    end
                end
            end
        
            for name, actionName in characterMeleeActionNames do
                local service = ServiceFolder:FindFirstChild(name .. "Service")
                if service then
                    hooks:Add(service.RE.Effects.OnClientEvent:Connect(function(action: string, character: Model, combo: number, finish: string?)
                        if action == actionName then
                            meleeDetected(character, combo)
                        end
                    end))
                end
            end
        end
        
        --chase (front dash)
        do
            local enabled = true

            -->> ui
            meleeBlockHeader:Checkbox({
                Label = "Front Dash",
                Value = enabled,
                saveFlag = "BlockChase",
                Callback = function(self, Value)
                    enabled = Value
                end,
            })
        
            -->> hook
            local function chaseDetected(enemyChar: Model)
                if not enabled then return end
                local localChar = Player.Character
                if localChar and localChar ~= enemyChar then
                    local t = tick()
    
                    local blockInstance = combat.block(enemyChar, 2.5, 3, false, false, false)

                    local isInRadius = false
                    local function enteredRadius()
                        if not isInRadius then
                            isInRadius = true
                            combat.counter(enemyChar)
                            blockInstance.enabled = true
                            --combat.block(enemyChar, 2.5, 3, true, true)
                        end
                    end
    
                    local function outOfRadius()
                        if isInRadius then
                            isInRadius = false
                            blockInstance.enabled = false
                        end
                    end
    
    
                    while task.wait() do
                        if not (tick() - t < .5 or enemyChar.Info:FindFirstChild("InSkill")) then
                            outOfRadius()
                            blockInstance:Destroy(true)
                            return
                        end
    
                        local diffVec : Vector3 = util.distanceFromCharacter(util.findFuturePos(enemyChar.PrimaryPart))
                        if diffVec and math.abs(diffVec.Y) < 8 and util.normalizeToGround(diffVec).Magnitude < 25 then
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
                    hooks:Add(service.RE.Effects.OnClientEvent:Connect(function(action: string, character: Model)
                        if action == "Chase" then
                            chaseDetected(character)
                        end
                    end))
                end
            end
        end	
    end
    
    --skills
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
                local distance = util.distanceFromCharacter(from.Position)
                if distance and math.abs(distance.Y) < (yLimit or 8) then
                    distance = util.normalizeToGround(distance)
                    if distance.Magnitude < maxDistance then
                        if distance.Magnitude < 10 then
                            combat.block(enemy, blockLength, 1, true, counter)
                        elseif distance.Unit:Dot(-from.LookVector) > 0.7 then
                            combat.block(enemy, blockLength, 1, true, counter)
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
                local enabled = true

                itadoriHeader:Checkbox({
                    Label = "Cursed Strikes",
                    Value = enabled,
                    saveFlag = "blockCursedStrikes",
                    Callback = function(self, Value)
                        enabled = Value
                    end,
                })
    
                local function cursedStrikesDetected(enemy: Model, from: CFrame)
                    if not enabled then return end
                    if typeof(from) ~= "CFrame" then return end
                    dashAttackDetected(enemy, false, from, 8, 40, .5)
                end
            
                hooks:Add( ServiceFolder.CursedStrikesService.RE.Effects.OnClientEvent:Connect(function(action: string, enemy: Model, cfRame: CFrame)
                    if action == "Dash" then
                        cursedStrikesDetected(enemy, cfRame)
                    end
                end) )
            
                hooks:Add( ServiceFolder.CursedStrikesService.RE.Effects.OnClientEvent:Connect(function(action: string, enemy: Model, cfRame: CFrame)
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
                local enabled = true

                megumiHeader:Checkbox({
                    Label = "Toad (frog)",
                    saveFlag = "BlockToad",
                    Value = enabled,
                    Callback = function(self, Value)
                        enabled = Value
                    end,
                })
    
                local function toadDetected(enemy: Model)
                    if not enabled then return end
                    task.delay(.4 - Player:GetNetworkPing() * 0.5, combat.block, enemy, .5, 1, false, false)
                end
            
                hooks:Add( ServiceFolder.ToadService.RE.Effects.OnClientEvent:Connect(function(action: string, enemy: Model, target: Model) 
                    if (action == "Toad" or action == "ToadAir") and target == Player.Character then
                        toadDetected(enemy.Character)
                    end
                end) )
            end
    
            -->> wolf (2)
            do
                local enabled = true

                megumiHeader:Checkbox({
                    Label = "Wolf",
                    Value = enabled,
                    saveFlag = "BlockWolf",
                    Callback = function(self, Value)
                        enabled = Value
                    end,
                })
    
                local function dogDetected(dogModel: Model, target: Model)
                    if not enabled then return end
                    task.wait(.3 - Player:GetNetworkPing() * 0.5)
                    if util.distanceFromCharacter(target).Magnitude < 6 then
                        combat.block(dogModel, .25, 1, false, true)
                    end
                end
            
                hooks:Add(ServiceFolder.DivineDogService.RE.Effects.OnClientEvent:Connect(function(action: string, dogModel: Model) 
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
                local enabled = true

                mahitoHeader:Checkbox({
                    Label = "Focus Strike",
                    Value = enabled,
                    saveFlag = "MahitoFocusStrike",
                    Callback = function(self, Value)
                        enabled = Value
                    end,
                })
    
                local function focusStrikeDetected(enemy: Model)
                    if not enabled then return end
                    dashAttackDetected(enemy, true, nil, 8, 30, .5)
                end
                
                hooks:Add( ServiceFolder.FocusStrikeService.RE.Effects.OnClientEvent:Connect(function(action: string, enemy: Model, cfRame: CFrame)
                    if action == "Startup" then
                        focusStrikeDetected(enemy)
                    end
                end) )
            
                hooks:Add( ServiceFolder.FocusStrikeService.RE.Effects.OnClientEvent:Connect(function(action: string, enemy: Model, cfRame: CFrame)
                    if action == "Swing" then
                        focusStrikeDetected(enemy)
                    end
                end) )
            end
    
            -->> soul bullets (2)
            do
                local enabled = true

                mahitoHeader:Checkbox({
                    Label = "Bullets",
                    Value = enabled,
                    saveFlag = "MahitoBullets",
                    Callback = function(self, Value)
                        enabled = Value
                    end,
                })
    
                local function soulFireDetected(enemy: Model)
                    if not enabled then return end
                    local localChar = Player.Character
                    if localChar and localChar ~= enemy then
                        local distance = util.distanceFromCharacter(enemy)
                        
                        if distance and distance.Magnitude < 10 and math.abs(distance.Y) < 3  then
                            task.wait(.3 - Player:GetNetworkPing())
                        else
                            task.wait(.4 - Player:GetNetworkPing())
                        end
            
                        for i = 1, 3 do			
                            local distance = util.distanceFromCharacter(enemy)
                            if distance then
                                if distance.Magnitude < 65 and math.abs(distance.Y) < 3 and distance.Unit:Dot(-enemy:GetPivot().LookVector) > 0.8 then
                                    combat.block(enemy, math.max(0.1 + 0.6 * distance.Magnitude / 60, .3), 1, false, true)
                                end
                            end
                            task.wait(.25 - Player:GetNetworkPing())
                        end
                    end
                end
                
                hooks:Add( ServiceFolder.SoulfireService.RE.Effects.OnClientEvent:Connect(function(action: string, char: Model) 
                    if action == "Morph" then
                        soulFireDetected(char)
                    end
                end) )
            end
    
            -->> special dash :)
            do
                local enabled = true

                mahitoHeader:Checkbox({
                    Label = "Special Dash",
                    Value = enabled,
                    saveFlag = "MahitoSpecialDash",
                    Callback = function(self, Value)
                        enabled = Value
                    end,
                })
    
                local function specialDashDetected(enemy: Model, style: number)
                    if not enabled then return end
                    if style == 1 then
                        dashAttackDetected(enemy, false, nil, 8, 25, .5)
                    elseif Player.Character and Player.Character ~= enemy then
                        task.wait(.25 - Player:GetNetworkPing())
                        dashAttackDetected(enemy, true, nil, 8, 25, 0)
                    end
                end
            
                hooks:Add( ServiceFolder.MahitoService.RE.Effects.OnClientEvent:Connect(function(action: string, enemy: Model, style: number)
                    if action == "ChaseStart" then
                        specialDashDetected(enemy, style)
                    end
                end) )
            
                hooks:Add( ServiceFolder.MahitoService.RE.Effects.OnClientEvent:Connect(function(action: string, enemy: Model, style: number)
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
                local enabled = true
                
                hakariHeader:Checkbox({
                    Label = "Doors",
                    Value = enabled,
                    saveFlag = "HakariDoors",
                    Callback = function(self, Value)
                        enabled= Value
                    end,
                })
    
                local function doorsDetected(part: BasePart)
                    if not enabled then return end
    
                    local dist = util.distanceFromCharacter(part)
                    if dist and math.abs(dist.Y) < 12 and util.normalizeToGround(dist).Magnitude < 24  then
                        task.wait(.2 - Player:GetNetworkPing())
                        local dist = util.distanceFromCharacter(part)
                        if util.normalizeToGround(dist).Magnitude < 12 then
                            combat.block(part, .45, 0, false, true)
                        end
                    end
                end
    
                hooks:Add ( ServiceFolder.ShutterDoorService.RE.Effects.OnClientEvent:Connect(function(method: string, part: BasePart)
                    if method == "Spawn" then
                        doorsDetected(part)
                    end
                end) )
            end
    
            -->> reserve balls (2)
            do
                local enebled = true

                hakariHeader:Checkbox({
                    Label = "Balls",
                    Value = enebled,
                    saveFlag = "HakariBalls",
                    Callback = function(self, Value)
                        enebled = Value
                    end,
                })
    
                --<< projectile shot
                local raycastParams = RaycastParams.new()
                raycastParams.FilterDescendantsInstances = {workspace.Effects, workspace.Bullets}
                
    
                local function ballSpawning(enemy: Model)
                    if not enebled then return end
    
                    task.wait(.25 - Player:GetNetworkPing())
                    if not Player.Character or enemy == Player.Character then return end
    
                    local dist = util.distanceFromCharacter(enemy)
                    if math.abs(dist.Y) < 3 then
                        dist = util.normalizeToGround(dist)
                        if dist.Magnitude < 70 then
                            if dist.Magnitude < 20 then
                                if dist.Unit:Dot(-enemy:GetPivot().LookVector) > 0.8 then
                                    combat.block(enemy, .3, 1, true, false) --<< countering is just unneccessary atp.
                                end
                                return
                            end
    
                            local dir = enemy:GetPivot().LookVector * dist.Magnitude
                            local raycast = workspace:Raycast(enemy:GetPivot().Position, dir, raycastParams) :: RaycastResult
    
                            if raycast then
                                if util.distanceFromCharacter(raycast.Position).Magnitude < 6 then
                                    combat.block(enemy, math.max(0.1 + 0.6 * dist.Magnitude / 65, .3), 1, true, true)
                                end
                                return
                            end
    
                            if dist.Unit:Dot(-enemy:GetPivot().LookVector) > 0.7 then
                                combat.block(enemy, 0.6 * dist.Magnitude / 65, 1, true, true)
                            end
                        end
                    end
                end
    
                hooks:Add ( ServiceFolder.ReserveBallService.RE.Effects.OnClientEvent:Connect(function(action: string, char: Model)
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
                local enabled = true

                gojoHeader:Checkbox({
                    Label = "Lapse Blue",
                    Value = enabled,
                    saveFlag = "blockLapseBlue",
                    Callback = function(self, Value)
                        enabled = Value
                    end,
                })
    
                local remote = ServiceFolder.LapseBlueService.RE.Effects
    
                local grabbedTick = 0;
                local function localCharGrabbed(target: Model)
                    if target == Player.Character then
                        grabbedTick = tick();
                    end
                end
                hooks:Add (
                    remote.OnClientEvent:Connect(function(action: string, target: Model)
                        if action == "BlueGrab" then
                            localCharGrabbed(target)
                        end
                    end)
                )
    
                local function blueDetected(enemy: Model)
                    if not enabled then return end
                    local localChar = Player.Character
                    if not localChar then return end
                    if tick() - grabbedTick < .2 + Player:GetNetworkPing() * .5 then
                        --<<< might be us
                        local distance = util.distanceFromCharacter(enemy)
                        if distance.Magnitude < 35 then
                            distance = util.normalizeToGround(distance)
                            if enemy:GetPivot().LookVector:Dot(-distance.Unit) > 0.25 then
                                --<< it probably IS us
                                task.wait(.25 - Player:GetNetworkPing())
                                combat.block(enemy, .4, 1, true, true)
                            end
                        end
                    end
                end
                hooks:Add (
                    remote.OnClientEvent:Connect(function(action: string, enemy: Model)
                        if action == "LapseBlue" then
                            blueDetected(enemy)
                        end
                    end)
                )
            end
    
            --red (2)
            do
                local enabled = true
                
                gojoHeader:Checkbox({
                    Label = "Reversal Red",
                    Value = enabled,
                    saveFlag = "BlockReversalRed",
                    Callback = function(self, Value)
                        enabled = Value
                    end,
                })
    
                --<< projectile shot
                local raycastParams = RaycastParams.new()
                raycastParams.FilterDescendantsInstances = {workspace.Effects, workspace.Bullets}
    
                local function redProjectileDetected(projectile: BasePart)
                    if not enabled then return end
    
                    local appearTick = tick()
                    local thread = task.defer(function()
                        while task.wait() do
                            local localChar = Player.Character
                            if not localChar then continue end
    
                            local dist = util.distanceFromCharacter(projectile)
                            if dist.Magnitude < 15 then
                                if dist.Magnitude < 8 or 
                                tick() - appearTick > 1.7 or
                                workspace:Raycast(projectile.CFrame.Position, projectile.CFrame.LookVector * Player:GetNetworkPing() * 30, raycastParams) then
                                    combat.block(projectile, .3, 1, false, true)
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
                    if not enabled then return end
    
                    local localChar = Player.Character
                    if not localChar or enemy == localChar then return end
    
                    task.wait(.5 - Player:GetNetworkPing())
    
                    local dist = util.distanceFromCharacter(enemy)
                    if dist and math.abs(dist.Y) < 8 then
                        dist = util.normalizeToGround(dist)
                        if dist.Magnitude < 15 then
                            if dist.Magnitude < 8 or enemy:GetPivot().LookVector:Dot(-dist.Unit) > .5 then
                                combat.block(enemy, .4, 1, true, true)
                            end
                        end
                    end
                end
    
                --<< hooks
                hooks:Add (
                    ServiceFolder.ReversalRedService.RE.Effects.OnClientEvent:Connect(function(action: string, enemy: Model)
                        if action == "Red" then
                            redCasted(enemy)
                        end
                    end)
                )
    
                hooks:Add (
                    workspace.Bullets.ChildAdded:Connect(function(child: BasePart)
                        if child.Name == "RedProjectile" then
                            redProjectileDetected(child)
                        end
                    end)
                )
            end
        end
    
    end
    
    --player
    do
        CombatTab:Separator({
            Text = "Player"
        })
        
        --<< Anti-Counter
        do
            local enabled = true

            local success, ToolController = pcall(function()
                return require(game.Players.LocalPlayer.PlayerScripts.Controllers.Character.ToolController) 
            end)
    
            local feintRemote = ServiceFolder.ItadoriService.RE.RightActivated
            local isTargetCountering;
            hooks:Add ( RunService.RenderStepped:Connect(function()
                local target = success and ToolController:GetTarget() or util.getClosestCharacter()
                if target and target:FindFirstChild"Info" and target.Info:FindFirstChild("Counter") then
                    isTargetCountering = target
                    -->> spam itadori feint if target is countering
                    if not enabled then return end
                    feintRemote.FireServer(feintRemote)
                else
                    isTargetCountering = nil
                end
            end))
    
            if hookmetamethod then
                local disabled = false
    
                local old;
                old = hookmetamethod(game, "__namecall", function(self, ...)
                    if not disabled and not checkcaller() and enabled and isTargetCountering then
                        if getnamecallmethod() == "FireServer" and typeof(self) == "Instance" and self.ClassName == "RemoteEvent" and self.Name == "Activated" then
                            return
                        end
                    end
                    return old(self, ...)
                end)
    
                hooks:Add ( function()
                    disabled = true
                end )
            end
    
            --(ui)
            CombatTab:Checkbox({
                Label = "AntiCounter",
                Value = enabled,
                saveFlag = "AntiCounter",
                Callback = function(self, Value)
                    enabled = Value
                end,
            })
        end
        
        --<< Downslam
        do
            local enabled = true

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
                    if not disabled and enabled then
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
        
                hooks:Add (function()
                    disabled = true
                end)
        
                CombatTab:Checkbox({
                    Label = "Auto-Downslam",
                    Value = enabled,
                    saveFlag = "downslam",
                    Callback = function(self, Value)
                        enabled = Value
                    end,
                })
            end
        end
    
        --<< Always black flash
        do
            local enabled = true

            local remote = ServiceFolder.DivergentFistService.RE.Activated
    
            local function blackFlashDetected(character: Model)
                if not enabled then return end
                local localChar = Player.Character
                if not localChar or localChar ~= character then return end
    
                task.wait(.15 - Player:GetNetworkPing())
                remote:FireServer()
            end
    
            hooks:Add( ServiceFolder.DivergentFistService.RE.Effects.OnClientEvent:Connect(function(effectName: string, char: Model) 
                if effectName == "CurseBuild" then
                    blackFlashDetected(char)
                end
            end) )
    
            CombatTab:Checkbox({
                Label = "Always Black Flash",
                Value = enabled,
                saveFlag = "AlwaysBlackFlash",
                Callback = function(self, Value)
                    enabled = Value
                end,
            })
        end
    
        --<< AutoTarget
        do
            local enabled = true

            local success, ToolController = pcall(require, game.Players.LocalPlayer.PlayerScripts.Controllers.Character.ToolController)
            if success then
                local disabled = false
                local old = ToolController.GetTarget;
                ToolController.GetTarget = function(self, ...)
                    if not disabled and not checkcaller() and enabled then
                        local result = old(self, ...) or util.getClosestCharacter()
                        return result
                    end
                    return old(self, ...)
                end
                hooks:Add ( function()
                    disabled = true
                end)
                CombatTab:Checkbox({
                    Label = "Auto-Target",
                    Value = enabled,
                    saveFlag = "autoTarget",
                    Callback = function(self, Value)
                        enabled = Value
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
                            local target = success and ToolController:GetTarget() or util.getClosestCharacter() 
                            MovementController.LockOn = target
                        end
                    end,
                })
            end
        end	
    
        --<< noDashCD
        do
            local enabled = true

            if debug and debug.setupvalue then
                local controller = require(game.Players.LocalPlayer.PlayerScripts.Controllers.Character.MovementController)
                local old = controller.DashRequest
        
                controller.DashRequest = function(self)
                    if enabled then
                        debug.setupvalue(old, 3, 0)
                    end
                    return old(self)
                end
        
                hooks:Add ( function()
                    controller.DashRequest = old
                end)
        
                CombatTab:Checkbox({
                    Label = "No Dash CD",
                    Value = enabled,
                    saveFlag = "noDashCD",
                    Callback = function(self, Value)
                        enabled = Value
                    end,
                })
            end
        end
    
        --<< no Stun
        do
            local enabled = {
                main = true,
                jump = true,
                sprint = true,
                ragdoll = true
            }

            local dropdown = CombatTab:CollapsingHeader({
                Title = "No-Stun",
                Open = false
            })
    
            dropdown:Checkbox({
                Label = "Enabled",
                Value = enabled.main,
                saveFlag = "nostunenabled",
                Callback = function(self, Value)
                    enabled.main = Value
                end,
            })
    
            dropdown:Checkbox({
                Label = "Jump",
                Value = enabled.jump,
                saveFlag = "nostunjump",
                Callback = function(self, Value)
                    enabled.jump = Value
                end,
            })
    
            dropdown:Checkbox({
                Label = "Sprint",
                Value = enabled.sprint,
                saveFlag = "nostunsprint",
                Callback = function(self, Value)
                    enabled.sprint = Value
                end,
            })
    
            dropdown:Checkbox({
                Label = "NoRagdoll",
                Value = enabled.ragdoll,
                saveFlag = "noragdolll",
                Callback = function(self, Value)
                    enabled.ragdoll = Value
                end,
            })
    
            hooks:Add (
                task.defer(function()
                    while true do
                        task.wait()
                        if not enabled.main then continue end
                        local char = Player.Character
                        if not char then continue end
    
                        if enabled.ragdoll then
                            char:SetAttribute("Ragdoll", 0)
                            if char:FindFirstChild("RagdollConstraints") then
                                char:FindFirstChild("RagdollConstraints").Parent = nil
                                for _, v in char:GetDescendants() do
                                    if v:IsA("Motor6D") then
                                        v.Enabled = true
                                    end
                                end
                            end
                        end
    
    
                        local charInfo = char:FindFirstChild("Info")
                        if charInfo then
                            local values = {
                                Stun = true,
                                NoSprint = enabled.sprint,
                                NoJump = enabled.jump,
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
                end)
            )
        end
    end
    
    --misc
    do
        CombatTab:Separator({
            Text = "Misc"
        })
        --inf black flash
        do
            local enabled = true

            local remote = ServiceFolder.DivergentFistService.RE.Activated
            
            local function blackFlashDetected(localChar: Model, character: Model)
                if not enabled then return end
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
        
                local lockOn = combat.lockOn(character, 1, nil, 3)
        
                task.wait(.25 + Player:GetNetworkPing())
                remote:FireServer()
        
                task.wait(.35)
        
                lockOn:Destroy()
                task.cancel(thread)
            end
            
            hooks:Add( ServiceFolder.DivergentFistService.RE.Effects.OnClientEvent:Connect(function(effectName: string, localChar: Model, char: Model) 
                if effectName == "BlackFlashHit" then
                    blackFlashDetected(localChar, char)
                end
            end) )
        
            CombatTab:Checkbox({
                Label = "Inf Black Flash",
                Value = enabled,
                saveFlag = "InfBlackFlash",
                Callback = function(self, Value)
                    enabled = Value
                end,
            })
        end
    
        --anti fall
        do
            local enabled = true

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
        
            hooks:Add(cleanUp)
        
            CombatTab:Checkbox({
                Label = "Anti-Void",
                Value = enabled,
                saveFlag = "AntiVoid",
                Callback = function(self, Value)
                    enabled= Value
                    if Value then
                        spawnParts()
                    else
                        cleanUp()
                    end
                end,
            })
        end
    
        --enterable domains
        do
            local enabled = true

            local function toggle(val: boolean)
                enabled = val
                if val then
                    hooks:Add(workspace.Domains.ChildAdded:Connect(function(child: Instance) 
                        child.CanCollide = false
                    end), nil, "enterDomains") 
                    for _, v in workspace.Domains:GetChildren() do
                        v.CanCollide = false
                    end		
                else
                    hooks:Remove("enterDomains")
                    for _, v in workspace.Domains:GetChildren() do
                        v.CanCollide = true
                    end		
                end
            end
        
            CombatTab:Checkbox({
                Label = "Enter Domains",
                Value = enabled,
                saveFlag = "EnterDomains",
                Callback = function(self, Value)
                    toggle(Value)
                end,
            })
        end

        --attack closest char
        do
            local goBehindEnemyKeybind = CombatTab:Keybind({
                Label = "Attack Closest Enemy",
                Value = Enum.KeyCode.C,
                saveFlag = "goBehindEnemyKeybind",
                Callback = function()
                    combat.attack(util.getClosestCharacter(), true)
                end,
            })
    
            hooks:Add( 
                function()
                    goBehindEnemyKeybind.Callback = nil
                end
            )
        end
    end
    
    --whitelist stuff
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
                Value = combat.whitelist[player.Name],
                --saveFlag = "Whitelist_" .. player.Name,
                Callback = function(self, Value)
                    combat.whitelist[player.Name] = Value
                end,
            })
        end
    
        local function playerRemoving(player: Player)
            combat.whitelist[player.Name] = nil
            playerCheckboxes[player]:Destroy()
            playerCheckboxes[player] = nil
        end
    
        hooks:Add (
            game.Players.PlayerAdded:Connect(playerAdded)
        )
    
        hooks:Add (
            game.Players.PlayerRemoving:Connect(playerRemoving)
        )
    
        for _, v in game.Players:GetPlayers() do
            playerAdded(v)
        end
    end
    
end

-- ui tab
do
    local UiTab = Window:CreateTab({
        Name = "GUI",
        Visible = false 
    })

    local toggleUiKeybind = UiTab:Keybind({
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


--finalize

-- config saving & loading
Window:CreateConfigSaveHandler("JJS_SAKSO")

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
        JJS_SAKSO.unload()
		ImGui:Notify("JJS-SAKSO", "Unloaded the cheat. Re-execute if you want to use again." , 3)
    end,
})

-- wiz special technique
if Player.Name == "IIlIllIIIIlIIIlllIIl" or Player.Name == "casckmaskcmwoda" then
	task.wait(5)
	ImGui:Notify("Sa", "Wiz sa nbr knks 31" , 5)
end

if Player.UserId == 7268859271 then
    task.wait(5)
	ImGui:Notify("Those who know ☠️", "Balkan Rage 💀😜" , 5)
end