--loadstring
--[[
	loadstring(game:HttpGet('https://raw.githubusercontent.com/skibidiMusic/Lua/refs/heads/main/Roblox/MTC4/main.lua'))()
]]

--src
local env = getgenv() :: {};

local dir = env.mtcSakso
if dir then
	if dir.disable then
		dir.disable()
    elseif dir.unload then
        dir.unload()
	end
else
    env.mtcSakso = {}
    dir = env.mtcSakso
end

-->> quick fix for require using atlantis
local require = function(v)
	setidentity(2)
	local m = require(v)
	setidentity(8)
	return m
end


local ImGui = loadstring(game:HttpGet('https://raw.githubusercontent.com/skibidiMusic/Lua/refs/heads/main/Roblox/Util/UiLib/ImGui.lua'))()
local Janitor = loadstring(game:HttpGet('https://raw.githubusercontent.com/skibidiMusic/Lua/refs/heads/main/Roblox/Util/Janitor.lua'))()

do
	-- adonis bypass (thanks to this dude)
	loadstring(game:HttpGet("https://raw.githubusercontent.com/Pixeluted/adoniscries/main/Source.lua", true))()
end

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")


local Player = game.Players.LocalPlayer
local PlayerGui = Player.PlayerGui


local Hooks = Janitor.new()
local Window = ImGui:CreateWindow({
	Title = "MTC4 SAKSO",
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

}); Window:Center()



--vehicle
do
	local VehicleTab = Window:CreateTab({
		Name = "Vehicles",
		Visible = false 
	})

	local SpawnedVehicles = workspace:WaitForChild("SpawnedVehicles")

	--seating
	do
		local dropdown = VehicleTab:CollapsingHeader({
			Title = "Seats",
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
			local closestVehicle = getClosestVehicle()
			if closestVehicle then
				for _, v: Instance in closestVehicle:GetDescendants() do
					if v:IsA("VehicleSeat") and v.Name == name then
						v.SeatEvt:FireServer()
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
	do
		local dropdown = VehicleTab:CollapsingHeader({
			Title = "Modifications",
			Open = false
		})

		local hooked = {

		}

		--speed
		do
			local speedVal = 100;
			local enabled = false;

			local function updateHooked()
				if enabled then
					for data in hooked do
						data.speed = speedVal
					end
				end
			end

			local Row = dropdown:Row({})
			Row:Checkbox({
				Label = "",
				Value = enabled,
				saveFlag = "speedEnabledMod",
				Callback = function(self, Value)
					enabled = Value
					if not Value then
						for t, v in hooked do
							t.speed = v.speed
						end
					else
						updateHooked()
					end
				end,
			})

			Row:Slider({
				Label = "Speed",
				Format = "%.d/%s", 
				Value = 100,
				MinValue = 0,
				MaxValue = 500,
				saveFlag = "speedValMod",
			
				Callback = function(self, Value)
					speedVal = Value
					updateHooked()
				end,
			})
		end

		--speedMultiplier
		do
			local speedVal = 2;
			local enabled = false;

			local function updateHooked()
				if enabled then
					for data, def in hooked do
						data.powerDat.forwardSpeedMult = def.powerDat.forwardSpeedMult * speedVal
						data.powerDat.backwardSpeedMult = def.powerDat.backwardSpeedMult * speedVal
					end
				end
			end

			local Row = dropdown:Row({})
			Row:Checkbox({
				Label = "",
				Value = enabled,
				saveFlag = "spdmultenabled",
				Callback = function(self, Value)
					enabled = Value
					if not Value then
						for t, v in hooked do
							t.powerDat.forwardSpeedMult = v.powerDat.forwardSpeedMult
							t.powerDat.backwardSpeedMult = v.powerDat.backwardSpeedMult
						end
					else
						updateHooked()
					end
				end,
			})

			Row:Slider({
				Label = "Spd. Multiplier",
				Format = "%.d/%s", 
				Value = 2,
				MinValue = 0,
				MaxValue = 10,
				saveFlag = "speedmultval",
			
				Callback = function(self, Value)
					speedVal = Value
					updateHooked()
				end,
			})
		end

		--rpmConstant
		do
			local speedVal = 2;
			local enabled = false;

			local function updateHooked()
				if enabled then
					for data, def in hooked do
						data.powerDat.rpmConstant = speedVal
					end
				end
			end

			local Row = dropdown:Row({})
			Row:Checkbox({
				Label = "",
				Value = enabled,
				saveFlag = "rpmEnabledMod",
				Callback = function(self, Value)
					enabled = Value
					if not Value then
						for t, v in hooked do
							t.powerDat.rpmConstant = v.powerDat.rpmConstant
						end
					else
						updateHooked()
					end
				end,
			})

			Row:Slider({
				Label = "RPMconst",
				Format = "%.d/%s", 
				Value = 2,
				MinValue = 0,
				MaxValue = 10,
				saveFlag = "rmpValMod",
			
				Callback = function(self, Value)
					speedVal = Value
					updateHooked()
				end,
			})
		end

		--hooking
		local function deepCopy(original)	
			local copy = {}
			for key, value in original do
				copy[key] = type(value) == "table" and deepCopy(value) or value
			end
			return copy
		end

		local function hookDriveData(driveData: {any})
			local defaults = deepCopy(driveData)
			hooked[driveData] = defaults
		end

		local driveDataFolder = ReplicatedStorage:WaitForChild("DriveData")
		for i, v: Instance? in driveDataFolder:GetChildren() do
			if v:IsA("ModuleScript") then
				hookDriveData(require(v))
			end
		end

		Hooks:Add( function()
			for driveData, defaults in hooked do
				for i, v in defaults do
					driveData[i] = v
				end
			end
			table.clear(hooked)
		end )
	end

	
end

local KeybindsTab = Window:CreateTab({
	Name = "Keybinds",
	Visible = false 
})

-->> functionality


--<< esp workaround
--[[


do
	local function highlightAdded(highlight, tank)
		if not highlight.Parent:IsA("Folder") or highlight.Parent.Name ~= "Comical" then return end
		highlight:Destroy()
	end

	local function vehicleAdded(v: Model)
		for _, a in v:GetDescendants() do
			if a:IsA("Highlight") then
				highlightAdded(a, v)
			end
		end

		v.DescendantAdded:Connect(function(descendant)
			if descendant:IsA("Highlight") then
				highlightAdded(descendant, v)
			end
		end)
	end

	UnloadJanitor:Add( vehiclesHolder.ChildAdded:Connect(function(v)
		vehicleAdded(v)
	end ) )

	for _, v in :GetChildren() do
		vehicleAdded(v)
	end

	local mainHighlight = Instance.new("Highlight")
	mainHighlight.FillColor = Color3.new(1,0,0)
	mainHighlight.OutlineColor = Color3.new(1, 1, 1)
	mainHighlight.OutlineTransparency = .1
	mainHighlight.FillTransparency = .5
	mainHighlight.DepthMode = Enum.HighlightDepthMode.Occluded
	mainHighlight.Parent = vehiclesHolder
end
]]

--keybinds
do
	KeybindsTab:Separator({
		"Press Backspace to Delete Keybind"
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

--unload
local function unload()
    Window:Close()
    Window:Destroy()
    unloadJanitor:Cleanup()
    dir.unload = nil
end

dir.unload = unload

--config stuff
Window:CreateConfigSaveHandler("MTC_SAKSO")