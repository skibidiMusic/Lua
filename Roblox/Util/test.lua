local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ImGui = loadstring(game:HttpGet('https://github.com/depthso/Roblox-ImGUI/raw/main/ImGui.lua'))()

-->> gui
local Window = ImGui:CreateWindow({
	Title = "JUJUT-SAKSO SHIT-A-NIGGA-NS",
	Position = UDim2.new(0.5, 0, 0, 160), --// Roblox property ,
    Size = UDim2.new(0, 350, 0, 370),
	--AutoSize = "Y",
	NoClose = true
})
Window:Center()

local AutoblockTab = Window:CreateTab({
	Name = "Autoblock",
	Visible = true 
})

local MiscTab = Window:CreateTab({
	Name = "Misc",
	Visible = false 
})


-->> code
--// debugging (mini-console)
local ConsoleTab = Window:CreateTab({
	Name = "Console (Output)",
	Visible = false 
})

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
		Fill = true,
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
end

--(whitelist for autoblock)
do
	AutoblockTab:Separator({
		Text = "Whitelist"
	})

    local whitelisted = {}

    local whitelistRow = AutoblockTab:Row()

    local function updateState(name: string)
        if whitelisted[name] then
            whitelisted[name]:Destroy()
            whitelisted[name] = nil
        else
            whitelisted[name] = whitelistRow:Button({
                Text = name,
                Callback = function(self)
                    updateState(name)
                end,
            })
        end
    end

    AutoblockTab:Separator({
		Text = "Add to whitelist:"
	})

    local dropdown;

    local function playerListChanged()
        if dropdown then dropdown:Destroy() end
        local players = game.Players:GetPlayers()
        for i, v: Player in Players do
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

    game.Players.PlayerAdded:Connect(function(player)
        playerListChanged()
    end)

    game.Players.PlayerRemoving:Connect(function(player)
        playerListChanged()
    end)
end

while task.wait(2) do
    debugConsole.print("hi")
end