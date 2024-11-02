local billBoard = Instance.new("BillboardGui")
billBoard.Parent = workspace.SpawnedVehicles["KV-2"]

billBoard.Size = UDim2.fromScale(1, 1)
local ImGui = loadstring(game:HttpGet('https://raw.githubusercontent.com/skibidiMusic/Lua/refs/heads/main/Roblox/Util/UiLib/ImGui.lua'))()

local Window = ImGui:CreateWindow({
	Title = "TEST",
	Size = UDim2.fromScale(1, 1),
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

task.wait()

Window.Parent = billBoard