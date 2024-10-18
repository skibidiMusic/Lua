-->> fix repeats
local env = getgenv() :: {};

local dir = env.fischSakso
if dir then
    dir.Disable()
else
    env.fischSakso = {}
    dir = env.fischSakso
end

--> ref
local VIM = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService"RunService"

local Player = game:GetService("Players").LocalPlayer
local PlayerGui = Player.PlayerGui

-->> dep
local ImGui = loadstring(game:HttpGet('https://github.com/depthso/Roblox-ImGUI/raw/main/ImGui.lua'))()
local Janitor = loadstring(game:HttpGet('https://raw.githubusercontent.com/skibidiMusic/Lua/refs/heads/main/Roblox/Util/Janitor.lua?token=GHSAT0AAAAAACZFNT5CKL6S5JG5QTOG4QGWZYSSNWQ'))()

-->> main
local disableJanitor = Janitor.new()

-->> gui
local Window = ImGui:CreateWindow({
	Title = "Fisch Sakso",
	Size = UDim2.fromOffset(350, 300), --// Roblox property 
	Position = UDim2.new(0.5, 0, 0, 70), --// Roblox property 
})

local MainTab = Window:CreateTab({
	Name = "Main",
	Visible = true 
})

local FuncsHeader = MainTab:CollapsingHeader({
	Title = "Functions",
	Open = true
})
local TeleportsHeader = MainTab:CollapsingHeader({
	Title = "Teleports",
	Open = true
})

-->> hook the rod
local getRod;

do
    local function validateRod(rod: Tool?)
		if rod:IsA("Tool") and rod:FindFirstChild("rod/client") then
            return true
		end
    end

    getRod = function()
        if Player.Character then
            local rod = Player.Character:FindFirstChildOfClass"Tool"
            if rod and validateRod(rod) then
                return rod
            end
        end
    
        for _, v in Player.Backpack:GetChildren() do
            if validateRod(v) then
                return v
            end
        end
    end    
end

-->> auto shake thing
local autoShake = {}
do
    local selfJan = Janitor.new()

    local function buttonDetected(button: GuiButton)
		if button.Name ~= "button" then return end
        while button.Parent do
            task.wait()
            local pos = button.AbsolutePosition
            local size = button.AbsoluteSize
            VIM:SendMouseButtonEvent(pos.X + (size.X / 2), pos.Y + (size.Y / 2), Enum.UserInputType.MouseButton1.Value, true, PlayerGui, 1)
            VIM:SendMouseButtonEvent(pos.X + (size.X / 2), pos.Y + (size.Y / 2), Enum.UserInputType.MouseButton1.Value, false, PlayerGui, 1)
        end
	end

	local function shakeSessionDetected(gui: ScreenGui)
		if gui.Name ~= "shakeui" then return end

        selfJan:Remove("currentSession")
		selfJan:Add(gui.DescendantAdded:Connect(buttonDetected), nil, "currentSession") 

		for _, v in gui:GetDescendants() do
			buttonDetected(v)
        end
	end
	
	autoShake.enable = function()
		selfJan:Add(PlayerGui.ChildAdded:Connect(shakeSessionDetected))
		if PlayerGui:FindFirstChild("shakeui") then
			shakeSessionDetected(PlayerGui.shakeui)
		end
	end

	autoShake.disable = function()
        selfJan:Cleanup()
    end

    disableJanitor:Add(autoShake.disable)

    FuncsHeader:Checkbox({
        Label = "Auto Shake",
        Value = false,
        Callback = function(self, Value)
            if Value then
                autoShake.enable()
            else
                autoShake.disable()
            end
        end,
    })
end


-->> auto minigame
local autoMinigame = {}
do
    local remote = ReplicatedStorage.events:FindFirstChild("reelfinished")
    local thread;

    local function loop()
        while task.wait(1) do
            local reel = PlayerGui:FindFirstChild("reel")
            if not reel then return end

            local bar = reel:FindFirstChild("bar")
            if not bar then return end

            local playerbar = bar:FindFirstChild("playerbar")

            if playerbar then
                remote:FireServer(100, true)
            end
        end
    end

	autoMinigame.enable = function()
        thread = task.defer(loop)
	end
	
	autoMinigame.disable = function()
		task.cancel(thread)
	end

    disableJanitor:Add(autoMinigame.disable)

    FuncsHeader:Checkbox({
        Label = "Auto Minigame (Rell)",
        Value = false,
        Callback = function(self, Value)
            if Value then
                autoMinigame.enable()
            else
                autoMinigame.disable()
            end
        end,
    })
end


-->> perfect cast
local function perfectCast()
    local rod = getRod()
    if rod then
        rod.events.reset:FireServer()
        rod.events.cast:FireServer(100)
    end
end

FuncsHeader:Button({
    Text = "Perfect Throw (Cast)",
    Callback = function(self)
        perfectCast()
    end,
})


-->> auto sell stuff idk.
local autoSell = {}
do
    local con;

    local remote = workspace:WaitForChild("world"):WaitForChild("npcs"):WaitForChild("Marc Merchant"):WaitForChild("merchant"):WaitForChild("sellall")
    local function fireRemote()
        remote:InvokeServer()
    end

    autoSell.enabe = function()
        fireRemote()
        con = Player.Backpack.ChildAdded:Connect(fireRemote)
    end
    autoSell.disable = function()
        con:Disconnect()
    end

    disableJanitor:Add(autoSell.disable)

    FuncsHeader:Checkbox({
        Label = "Auto Sell",
        Value = false,
        Callback = function(self, Value)
            if Value then
                autoSell.enable()
            else
                autoSell.disable()
            end
        end,
    })
end


-->> auto cast
local autoCast = {}
do
    local thread;

    local function loop()
        while task.wait(1) do
            local rod = getRod()
            if rod and rod.Parent == Player.Character and not rod.values.casted.value then
                perfectCast()
            end
        end
    end

    autoCast.enable = function()
        thread = task.defer(loop)
    end

    autoCast.disable = function()
        task.cancel(thread)
    end

    disableJanitor:Add(autoCast.disable)

    FuncsHeader:Checkbox({
        Label = "Auto Throw (Cast)",
        Value = false,
        Callback = function(self, Value)
            if Value then
                autoCast.enable()
            else
                autoCast.disable()
            end
        end,
    })
end


-->> teleports
local function teleportTo(currentOption, folder)
	local selectedPart = folder:FindFirstChild(currentOption)
	if selectedPart then
		-- Teleport the player to the part's position
		local player = game.Players.LocalPlayer
		local character = player.Character
		if character then
			character:PivotTo(selectedPart.CFrame + Vector3.new(0, 3, 0)) -- Teleport above the part
		end
	else
		warn("Selected part not found")
	end
end

--> zone tp
local folder = game.Workspace.zones.player
local teleportOptions = {}
for _, part in ipairs(folder:GetChildren()) do
	if part:IsA("BasePart") then -- Ensuring it's a part you can teleport to
		table.insert(teleportOptions, part.Name)
	end
end

TeleportsHeader:Combo({
	Placeholder = "Choose to tp (freaky tp)",
	Label = "Zones",
	Items = teleportOptions,
	Callback = function(self, Value)
		teleportTo(Value, folder)
	end,
})

--> fishing zones tp
local folder = game.Workspace.zones.fishing
local teleportOptions = {}
for _, part in ipairs(folder:GetChildren()) do
	if part:IsA("BasePart") then -- Ensuring it's a part you can teleport to
		table.insert(teleportOptions, part.Name)
	end
end

TeleportsHeader:Combo({
	Placeholder = "Choose to tp (freaky tp)",
	Label = "Fishing Zones",
	Items = teleportOptions,
	Callback = function(self, Value)
		teleportTo(Value, folder)
	end,
})


-->> DISABLING (REMOVING)
dir.Disable = function()
    disableJanitor:Cleanup()
    Window:Close()
end
