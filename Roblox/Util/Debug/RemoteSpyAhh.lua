-->> loadstring
--[[
    loadstring(game:HttpGet('https://raw.githubusercontent.com/skibidiMusic/Lua/refs/heads/main/Roblox/Util/basic_remote_spy.lua'))()
]]

--//config

local useRobloxConsole = true; --< dont set to false, lags too much ig.


-->> src

-->> fix repeats
local env = getgenv() :: {};

local dir = env.basicRemoteSpy
if dir then
	if dir.disable then
		dir.Disable()
	end
else
    env.basicRemoteSpy = {}
    dir = env.basicRemoteSpy
end

-->> main
local Janitor = loadstring(game:HttpGet('https://raw.githubusercontent.com/skibidiMusic/Lua/refs/heads/main/Roblox/Util/Misc/Janitor.lua'))()
local disableJanitor = Janitor.new()

dir.Disable = function()
    disableJanitor:Cleanup()
end

if not useRobloxConsole then
    local ImGui = loadstring(game:HttpGet('https://github.com/depthso/Roblox-ImGUI/raw/main/ImGui.lua'))()
    -->> gui
    local Window = ImGui:CreateWindow({
	    Title = "rem / ote spy (go / jo get it?)",
	    Position = UDim2.new(0.5, 0, 0, 70), --// Roblox property 
	    AutoSize = "Y",
        CloseCallback = function()
            dir.Disable()
        end
    })

    local ConsoleTab = Window:CreateTab({
        Name = "Console (Output)",
        Visible = true 
    })

    ConsoleTab:Separator({
		Text = "the fuck begins here"
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

    print = function(...)
        Console:AppendText(...)
    end

    dir.Disable = function()
        Window:Destroy()
        disableJanitor:Cleanup()
    end
else
    dir.Disable = function()
        disableJanitor:Cleanup()
    end
end

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

-->> logic

local remoteConnections = {};

local function startTracking(v: RemoteEvent)
	if not v:IsA("RemoteEvent") or remoteConnections[v] then return end
	remoteConnections[v] = v.OnClientEvent:Connect(function(...: any) 
		local args = {...}
		print(string.format("[%s].OnClientEvent: [Args]: %s", v:GetFullName(), ToString(args)))
	end)
end

local function stopTracking(v)
	if not remoteConnections[v] then return end
	remoteConnections[v]:Disconnect()
	remoteConnections[v] = nil
end 

local trackConnections = {}

local function enable()
	trackConnections[1] = game.DescendantAdded:Connect(startTracking)
	trackConnections[2] = game.DescendantRemoving:Connect(stopTracking)
	
	for _, v in game:GetDescendants() do
		startTracking(v)
	end
end

disableJanitor:Add( function()
    for _, v in trackConnections do
		v:Disconnect()
	end
	for v in remoteConnections do
		stopTracking(v)
	end
end)

enable()