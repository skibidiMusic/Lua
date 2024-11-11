-->> LOADSTRING
--[[
	loadstring(game:HttpGet('https://raw.githubusercontent.com/skibidiMusic/Lua/refs/heads/main/Roblox/JujutsuShinenigans/main.lua'))()
]]

-->> SRC

-->> fix repeats
local env = getgenv() :: {};

local dir = env.beeSwarmSakso
if dir then
	if dir.disable then
		dir.disable()
	end
else
    env.beeSwarmSakso = {}
    dir = env.beeSwarmSakso
end

--> ref
local Player = game:GetService("Players").LocalPlayer
local TWEENSERVICE = game:GetService"TweenService"


-->> dep
--local fileManager = loadstring(game:HttpGet('https://raw.githubusercontent.com/skibidiMusic/Lua/refs/heads/main/Roblox/Util/fileManager.lua'))()
local ImGui = loadstring(game:HttpGet('https://raw.githubusercontent.com/skibidiMusic/Lua/refs/heads/main/Roblox/Util/UiLib/ImGui.lua'))()
local Janitor = loadstring(game:HttpGet('https://raw.githubusercontent.com/skibidiMusic/Lua/refs/heads/main/Roblox/Util/Janitor.lua'))()

-->> base config
local config = {
    snowflakeTp = true,
    ticketTp = true,
}

local Window = ImGui:CreateWindow({
	Title = "BEE SWARM TUAH",
	Position = UDim2.new(0.5, 0, 0, 70), --// Roblox property 
	Size = UDim2.new(0, 600, 0, 500),
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

local function lerp(v1, v2, a)
    return v1 + (v2 - v1) * a
end

-->> var
local disableJan = Janitor.new()

local function tpTo(pos: Vector3)
    local char = Player.Character
    if char then
        TWEENSERVICE:Create(char.PrimaryPart, TweenInfo.new(1, Enum.EasingStyle.Linear), {CFrame = CFrame.new(pos)}):Play()
    end
end


--(tabs)
local MainTab = Window:CreateTab({
	Name = "MAIN",
	Visible = true 
})

MainTab:Separator({
    Text = "WIZE SAKSOOO"
})


--->> snowflake tp

do
    MainTab:Checkbox({
		Label = "SNOWFLAKE TP",
		Value = true,
        saveFlag = "SNOWFLAKE_TP",
		Callback = function(self, Value)
			config.snowflakeTp = Value
		end,
	})	

    local function snowFlakeFound(v)
        task.wait(5)
        if config.snowflakeTp then
            tpTo(v.Position) 
        end
    end

    disableJan:Add (
        workspace.Particles.Snowflakes.ChildAdded:Connect(snowFlakeFound)
    )
end

--->>
-->> config saving & loading
Window:CreateConfigSaveHandler("BEE_SAKSO")

dir.disable = function()
    disableJan:Destroy()
    Window:Destroy()
	dir.disable = nil
end

Window.CloseCallback = function()
    dir.disable()
end

--// wiz special technique
if Player.Name == "IIlIllIIIIlIIIlllIIl" or Player.Name == "casckmaskcmwoda" then
	task.wait(5)
	ImGui:Notify("Sa", "Wiz sa nbr knks 31" , 5)
end