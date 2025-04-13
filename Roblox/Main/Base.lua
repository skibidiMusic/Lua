-->> Loadstring
--	local BaseScript = loadstring(game:HttpGet('https://raw.githubusercontent.com/skibidiMusic/Lua/refs/heads/main/Roblox/Main/Base.lua'))()

local BaseLoader = {}
BaseLoader.__index = BaseLoader

local ImGui = loadstring(game:HttpGet('https://raw.githubusercontent.com/skibidiMusic/Lua/refs/heads/main/Roblox/Util/UiLib/ImGui.lua'))()
local Janitor = loadstring(game:HttpGet('https://raw.githubusercontent.com/skibidiMusic/Lua/refs/heads/main/Roblox/Util/Misc/Janitor.lua'))()
local Signal = loadstring(game:HttpGet('https://raw.githubusercontent.com/skibidiMusic/Lua/refs/heads/main/Roblox/Util/Misc/Signal.lua'))()

BaseLoader.ImGui = ImGui
BaseLoader.Janitor = Janitor
BaseLoader.Signal = Signal

local genv = getgenv()

function BaseLoader.new(name: string)
    local self = {}
    self.name = name

    if genv[name] then
        genv[name]:Unload()
    end

    genv[name] = self
    
    local Window = ImGui:CreateWindow({Title = name, Position = UDim2.new(0.5, 0, 0, 70), Size = UDim2.new(0, 800, 0, 500), AutoSize = false, 	--// Styles
	Colors = {
		Window = {
			BackgroundColor3 = Color3.fromRGB(89, 57, 92),
			BackgroundTransparency = 0.1,
			ResizeGrip = {
				TextColor3 = Color3.fromRGB(87, 26, 95)
			},
			
			TitleBar = {
				BackgroundColor3 = Color3.fromRGB(49, 21, 51),
				[{
					Recursive = true,
					Name = "ToggleButton"
				}] = {
					BackgroundColor3 = Color3.fromRGB(134, 63, 134)
				}
			},
			ToolBar = {
				TabButton = {
					BackgroundColor3 = Color3.fromRGB(170, 81, 155)
				}
			},
		},
		CheckBox = {
			Tickbox = {
				BackgroundColor3 = Color3.fromRGB(20, 20, 20),
				Tick = {
					ImageColor3 = Color3.fromRGB(226, 130, 255)
				}
			}
		},
		Slider = {
			Grab = {
				BackgroundColor3 = Color3.fromRGB(255, 152, 229)
			},
			BackgroundColor3 = Color3.fromRGB(20, 20, 20)
		},
		CollapsingHeader = {
			TitleBar = {
				BackgroundColor3 = Color3.fromRGB(155, 42, 136)
			}
		}
	}
})
    Window:Center()
    
    local hooks = Janitor.new()

    self.hooks = hooks
    self.window = Window
    self.loaded = true

    return setmetatable(self, BaseLoader)
end

function BaseLoader:ConfigManager()
    self.window:CreateConfigSaveHandler(self.name)
end

function BaseLoader:UiTab()
    --ui tab
    local UiTab = self.window:CreateTab({
    	Name = "Ui",
    	Visible = false 
    })

	UiTab:Separator({
		"lol 🙏😭"
	})
	
	do
		local toggleUiKeybind = UiTab:Keybind({
			Label = "Toggle UI",
			Value = Enum.KeyCode.RightControl,
			saveFlag = "ToggleUiKeybind",
			Callback = function()
				self.window:SetVisible(not self.window.Visible)
			end,
		})
		
		local wasClosedBefore = false
		self.window.CloseCallback = function()
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

function BaseLoader:UnloadTab()
    -- unloading gui
    local closeTab = self.window:CreateTab({
    	Name = "Unload",
    	Visible = false
    })

    closeTab:Separator({

    })

    closeTab:Button({
        Text = "Unload the script",
        Callback = function()
            self:Unload()
    		ImGui:Notify("Unload", "Unloaded (Everything disabled, re-execute to enable)" , 3)
        end,
    })
end

function BaseLoader:Unload()
    if not self.loaded then return end
    self.loaded = false
    self.hooks:Cleanup()
    self.window:Destroy()
end

return BaseLoader