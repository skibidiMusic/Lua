-->> LOADSTRING

-->> SOURCE

-->> fix repeats
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

-->> dep
local RunService = game:GetService("RunService")

local ImGui = loadstring(game:HttpGet('https://raw.githubusercontent.com/skibidiMusic/Lua/refs/heads/main/Roblox/Util/UiLib/ImGui.lua'))()
local Janitor = loadstring(game:HttpGet('https://raw.githubusercontent.com/skibidiMusic/Lua/refs/heads/main/Roblox/Util/Janitor.lua'))()

local vehiclesHolder = workspace.SpawnedVehicles

-->> hook control
local unloadJanitor = Janitor.new()

-->> Window Set-up
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

local mainTab = Window:CreateTab({
	Name = "Main",
	Visible = true 
})

-->> seat picker
do
    mainTab:Separator({
        Text = "Yes"
    })

    local closestVehicle : Model;

    unloadJanitor:Add ( RunService.Heartbeat:Connect(function(deltaTime)
        local localChar = game.Players.LocalPlayer.Character
        if not localChar then return end

        local closestDist = math.huge;
        for _, v in vehiclesHolder:GetChildren() do
            local dist = (localChar:GetPivot().Position - v:GetPivot().Position).Magnitude
            if dist < closestDist then
                closestDist = dist
                closestVehicle = v
            end
        end
    end) )

    local function pickSeat(name: string)
        if closestVehicle  then
            for _, v: Instance in closestVehicle:GetDescendants() do
                if v:IsA("VehicleSeat") and v.Name == name then
                    v.SeatEvt:FireServer()
                end 
            end
        end
    end

    local function createSeatPicker(name: string, defaultKey: Enum.KeyCode)
        local Row = mainTab:Row({

        })

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
    createSeatPicker("Commander", Enum.KeyCode.L)
    createSeatPicker("Loader", Enum.KeyCode.O)
    createSeatPicker("Gunner", Enum.KeyCode.U)
    createSeatPicker("Driver", Enum.KeyCode.P)
end

local KeybindsTab = Window:CreateTab({
	Name = "Keybinds",
	Visible = false 
})

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

-->> config saving & loading
Window:CreateConfigSaveHandler("MTC_SAKSO")

-->> handle unloading (closing)
local function unload()
    Window:Close()
    Window:Destroy()
    unloadJanitor:Cleanup()
    dir.unload = nil
end

dir.unload = unload