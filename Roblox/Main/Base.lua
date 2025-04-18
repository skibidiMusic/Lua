-->> Loadstring
--	local BaseScript = loadstring(game:HttpGet('https://raw.githubusercontent.com/skibidiMusic/Lua/refs/heads/main/Roblox/Main/Base.lua'))()

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local InsertService = game:GetService("InsertService")
local CoreGui = game:GetService("CoreGui")

local BaseLoader = {}
BaseLoader.__index = BaseLoader

local ImGui = loadstring(game:HttpGet('https://raw.githubusercontent.com/depthso/Dear-ReGui/refs/heads/main/ReGui.lua'))()
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

	local PrefabsId = "rbxassetid://" .. ImGui.PrefabsId
	ImGui:Init({
		Prefabs = InsertService:LoadLocalAsset(PrefabsId)
	})
    
    local Window = ImGui:TabsWindow({Title = "🔥😛 SelamiHub " .. name, Position = UDim2.new(0.5, 0, 0, 70), Size = UDim2.new(0, 600, 0, 700), AutoSize = false,})
    Window:Center()

	--

    local hooks = Janitor.new()

    self.hooks = hooks
    self.window = Window
    self.loaded = true

    return setmetatable(self, BaseLoader)
end

function BaseLoader:Notify(title: string, message: string, length: number?)
	length = 0.5 + (length or 5)

	local notification = ImGui:PopupModal({
		Title = title,
		TabsBar = false,
		AutoSize = "Y",
		NoCollapse = true,
		NoResize = true,
		NoClose = false,
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1 - 0.05, 0, 1 - 0.05, 0),
		Size = UDim2.fromOffset(0, 0), --// Roblox property ,
		Theme = self.window.Theme,
	})

	local windowUi = notification.WindowFrame

	windowUi.AnchorPoint = Vector2.new(1,1)
	notification.AnchorPoint = Vector2.new(1,1)

	local tween = TweenService:Create(windowUi, TweenInfo.new(0.5, Enum.EasingStyle.Circular),  {Size = UDim2.fromOffset(500, 50)})
	tween:Play()

	tween.Completed:Connect(function(playbackState)
		notification:Label({
			Text = message,
			TextWrapped = true,
			RichText = true,
		})
	end)

	task.delay(length, function() 
		notification:ClosePopup()
		notification:Destroy()
	end)

	return notification
end

function BaseLoader:ConfigManager()
	local fileManagerLib = loadstring(game:HttpGet('https://raw.githubusercontent.com/skibidiMusic/Lua/refs/heads/main/Roblox/Util/Exploit/FileManager.lua'))()

	local saveFolder = fileManagerLib.new(self.name)
	local configTabDataFolder = fileManagerLib.new(self.name .. "/tabData")

	local configHandlerSettings = configTabDataFolder:getSave("data") or {
		AutoLoadEnabled = true,
		AutoSaveEnabled = true,
		lastSaveName = "AutoSave"
	}

	local function loadConfig(name: string)
		local save = saveFolder:getSave(name)
		if save then
			ImGui:LoadIni(save, false)
			self:Notify("⚙️Config", `You loaded the config: ({name})`, 6)
		else
			self:Notify("⚙️Config", `There is no config with the name: ({name}), make sure you've saved it first.`, 6)
		end
	end

	local function saveConfig(name: string)
		saveFolder:save(name, ImGui:DumpIni(false))
	end 

	-->> UI
	local tab = self.window:CreateTab({
		Name = "Configs",
	})

	tab:Separator({
		Text = "Save/Load configs"
	})

	local row = tab:Row()

	row:Checkbox({
		Label = "Auto-Save",
		Value = configHandlerSettings.AutoSaveEnabled,
		Callback = function(self, Value)
			configHandlerSettings.AutoSaveEnabled = Value
			configTabDataFolder:save("data", configHandlerSettings)
		end,
	})

	row:Checkbox({
		Label = "Auto-Load",
		Value = configHandlerSettings.AutoLoadEnabled,
		Callback = function(self, Value)
			configHandlerSettings.AutoLoadEnabled = Value
			configTabDataFolder:save("data", configHandlerSettings)
		end,
	})

	tab:Separator({
		Text = "Selected Save"
	})

	--row:Fill()

	local selectedSaveName = configHandlerSettings.lastSaveName;
	local inputText = tab:InputText({
		Text = configHandlerSettings.lastSaveName,
		PlaceHolder = "Type save name",
		Callback = function(self, v)
			selectedSaveName = v;	
		end
	})

	local row2 = tab:Row()

	row2:Button({
		Text = "Load",
		Callback = function(self)
			loadConfig(selectedSaveName)
		end
	})

	row2:Button({
		Text = "Save",
		Callback = function(self)
			saveConfig(selectedSaveName)
		end
	})

	row2:Button({
		Text = "Delete",
		Callback = function(self)
			saveFolder:delete(selectedSaveName)
		end
	})

	--row2:Fill()

	tab:Separator({
		Text = "Save List"
	})

	--local row3 = tab:Row()
	local previousCombo;

	local function getSaves()
		local saves = saveFolder:getSaves()
		local result = {}
		for i, v in saves do
			table.insert(result, i)
		end
		return result
	end

	local function refreshConfigList()
		if previousCombo then
			previousCombo:Destroy()
		end
		previousCombo = tab:Combo({
			Placeholder = "Select a save.",
			Label = "Saves",
			Items = getSaves(),
			Callback = function(self, Value)
				inputText:SetValue(Value)
			end,
		})
	end

	local refreshButton = tab:Button({
		Text = "Refresh",
		Callback = function(self)
			refreshConfigList()
		end
	})

	refreshConfigList()
	--row3:Fill()

	if configHandlerSettings.AutoLoadEnabled then
		loadConfig(configHandlerSettings.lastSaveName)
		self.window:SetTheme(self.window.Theme)
		self:Notify("⚙️Config", "Auto-loaded config: " .. configHandlerSettings.lastSaveName .. ".", 4)
	end

	local function autoSave()
		if not configHandlerSettings.AutoSaveEnabled then return end
		saveConfig("AutoSave")
	end

	--// AutoSave when leaving game / also at a interval, add the connection to the hooks
	self.autosave = autoSave

	--// AutoSave when game closes
	local localPlayer = Players.LocalPlayer
	self.hooks:Add(Players.PlayerRemoving:Connect(function(child)
		if child == localPlayer then
			autoSave()
		end
	end))
end

function BaseLoader:UiTab()
    --ui tab
    local UiTab = self.window:CreateTab({
    	Name = "Ui",
    })

	UiTab:Separator({
		Text = "Keybind"
	})
	
	do
		local toggleUiKeybind = UiTab:Keybind({
			Label = "Toggle UI",
			Value = Enum.KeyCode.RightControl,
			IniFlag = "ToggleUiKeybind",
			Callback = function()
				self.window:SetVisible(not self.window.Visible)
			end,
		})
		
		local wasClosedBefore = false
		self.window.WindowFrame:GetPropertyChangedSignal("Visible"):Connect(function()
			if self.window.Visible then return end

			if toggleUiKeybind.Value then
				if wasClosedBefore then
					--ImGui:Notify("Press " .. `{toggleUiKeybind.Value}` .. " to re-open the gui." , 1)
					return
				end
				wasClosedBefore = true
				self:Notify("Gui", "Press " .. `{toggleUiKeybind.Value.Name}` .. " to re-open the gui." , 4)
			end
		end)
	end

	UiTab:Separator({
		Text = "Theme 🎨"
	})

	do
		ImGui:DefineTheme("🌸 Pink", {
			TitleAlign = Enum.TextXAlignment.Center,
			TextDisabled = Color3.fromRGB(150, 120, 150),
			Text = Color3.fromRGB(255, 200, 255),
			
			FrameBg = Color3.fromRGB(35, 25, 35),
			FrameBgTransparency = 0.4,
			FrameBgActive = Color3.fromRGB(180, 120, 180),
			FrameBgTransparencyActive = 0.4,
			
			CheckMark = Color3.fromRGB(255, 130, 255),
			SliderGrab = Color3.fromRGB(255, 130, 255),
			ButtonsBg = Color3.fromRGB(255, 130, 255),
			CollapsingHeaderBg = Color3.fromRGB(255, 130, 255),
			CollapsingHeaderText = Color3.fromRGB(255, 200, 255),
			RadioButtonHoveredBg = Color3.fromRGB(255, 130, 255),
			
			WindowBg = Color3.fromRGB(45, 35, 45),
			TitleBarBg = Color3.fromRGB(45, 35, 45),
			TitleBarBgActive = Color3.fromRGB(70, 55, 70),
			
			Border = Color3.fromRGB(70, 55, 70),
			ResizeGrab = Color3.fromRGB(70, 55, 70),
			RegionBgTransparency = 1,
		
			TabText = Color3.fromRGB(24, 24, 24),
			TabBg = Color3.fromRGB(255, 150, 255),
			TabTextActive = Color3.fromRGB(255, 255, 255),
			TabBgActive = Color3.fromRGB(70, 30, 70),
		})

		-- Green Theme
		ImGui:DefineTheme("🍀 Green", {
		    TitleAlign = Enum.TextXAlignment.Center,
		    TextDisabled = Color3.fromRGB(100, 120, 100),
		    Text = Color3.fromRGB(180, 200, 180),
		
		    FrameBg = Color3.fromRGB(20, 25, 20),
		    FrameBgTransparency = 0.4,
		    FrameBgActive = Color3.fromRGB(100, 120, 100),
		    FrameBgTransparencyActive = 0.4,
		
		    CheckMark = Color3.fromRGB(100, 150, 100),
		    SliderGrab = Color3.fromRGB(100, 150, 100),
		    ButtonsBg = Color3.fromRGB(100, 150, 100),
		    CollapsingHeaderBg = Color3.fromRGB(100, 150, 100),
		    CollapsingHeaderText = Color3.fromRGB(180, 200, 180),
		    RadioButtonHoveredBg = Color3.fromRGB(100, 150, 100),
		
		    WindowBg = Color3.fromRGB(30, 35, 30),
		    TitleBarBg = Color3.fromRGB(30, 35, 30),
		    TitleBarBgActive = Color3.fromRGB(45, 50, 45),
		
		    Border = Color3.fromRGB(45, 50, 45),
		    ResizeGrab = Color3.fromRGB(45, 50, 45),
		    RegionBgTransparency = 1,
		
		    TabText = Color3.fromRGB(24, 24, 24),
		    TabBg = Color3.fromRGB(141, 201, 141),
		    TabTextActive = Color3.fromRGB(255, 255, 255),
		    TabBgActive = Color3.fromRGB(22, 41, 22),
		})

		-- Red Theme
		ImGui:DefineTheme("🍒 Red", {
		    TitleAlign = Enum.TextXAlignment.Center,
		    TextDisabled = Color3.fromRGB(120, 100, 100),
		    Text = Color3.fromRGB(200, 180, 180),
		
		    FrameBg = Color3.fromRGB(25, 20, 20),
		    FrameBgTransparency = 0.4,
		    FrameBgActive = Color3.fromRGB(120, 100, 100),
		    FrameBgTransparencyActive = 0.4,
		
		    CheckMark = Color3.fromRGB(150, 100, 100),
		    SliderGrab = Color3.fromRGB(150, 100, 100),
		    ButtonsBg = Color3.fromRGB(150, 100, 100),
		    CollapsingHeaderBg = Color3.fromRGB(150, 100, 100),
		    CollapsingHeaderText = Color3.fromRGB(200, 180, 180),
		    RadioButtonHoveredBg = Color3.fromRGB(150, 100, 100),
		
		    WindowBg = Color3.fromRGB(35, 30, 30),
		    TitleBarBg = Color3.fromRGB(35, 30, 30),
		    TitleBarBgActive = Color3.fromRGB(50, 45, 45),
		
		    Border = Color3.fromRGB(50, 45, 45),
		    ResizeGrab = Color3.fromRGB(50, 45, 45),
		    RegionBgTransparency = 1,
		
		    TabText = Color3.fromRGB(24, 24, 24),
		    TabBg = Color3.fromRGB(201, 141, 141),
		    TabTextActive = Color3.fromRGB(255, 255, 255),
		    TabBgActive = Color3.fromRGB(41, 22, 22),
		})

		-- Yellow Theme
		ImGui:DefineTheme("🍋 Yellow", {
		    TitleAlign = Enum.TextXAlignment.Center,
		    TextDisabled = Color3.fromRGB(120, 120, 100),
		    Text = Color3.fromRGB(200, 200, 180),
		
		    FrameBg = Color3.fromRGB(25, 25, 20),
		    FrameBgTransparency = 0.4,
		    FrameBgActive = Color3.fromRGB(120, 120, 100),
		    FrameBgTransparencyActive = 0.4,
		
		    CheckMark = Color3.fromRGB(150, 150, 100),
		    SliderGrab = Color3.fromRGB(150, 150, 100),
		    ButtonsBg = Color3.fromRGB(150, 150, 100),
		    CollapsingHeaderBg = Color3.fromRGB(150, 150, 100),
		    CollapsingHeaderText = Color3.fromRGB(200, 200, 180),
		    RadioButtonHoveredBg = Color3.fromRGB(150, 150, 100),
		
		    WindowBg = Color3.fromRGB(35, 35, 30),
		    TitleBarBg = Color3.fromRGB(35, 35, 30),
		    TitleBarBgActive = Color3.fromRGB(50, 50, 45),
		
		    Border = Color3.fromRGB(50, 50, 45),
		    ResizeGrab = Color3.fromRGB(50, 50, 45),
		    RegionBgTransparency = 1,
		
		    TabText = Color3.fromRGB(24, 24, 24),
		    TabBg = Color3.fromRGB(201, 201, 141),
		    TabTextActive = Color3.fromRGB(255, 255, 255),
		    TabBgActive = Color3.fromRGB(41, 41, 22),
		})

		-- Blue Theme
		ImGui:DefineTheme("🌊 Blue", {
		    TitleAlign = Enum.TextXAlignment.Center,
		    TextDisabled = Color3.fromRGB(100, 100, 120),
		    Text = Color3.fromRGB(180, 180, 200),
		
		    FrameBg = Color3.fromRGB(20, 20, 25),
		    FrameBgTransparency = 0.4,
		    FrameBgActive = Color3.fromRGB(100, 100, 120),
		    FrameBgTransparencyActive = 0.4,
		
		    CheckMark = Color3.fromRGB(100, 100, 150),
		    SliderGrab = Color3.fromRGB(100, 100, 150),
		    ButtonsBg = Color3.fromRGB(100, 100, 150),
		    CollapsingHeaderBg = Color3.fromRGB(100, 100, 150),
		    CollapsingHeaderText = Color3.fromRGB(180, 180, 200),
		    RadioButtonHoveredBg = Color3.fromRGB(100, 100, 150),
		
		    WindowBg = Color3.fromRGB(30, 30, 35),
		    TitleBarBg = Color3.fromRGB(30, 30, 35),
		    TitleBarBgActive = Color3.fromRGB(45, 45, 50),
		
		    Border = Color3.fromRGB(45, 45, 50),
		    ResizeGrab = Color3.fromRGB(45, 45, 50),
		    RegionBgTransparency = 1,
		
		    TabText = Color3.fromRGB(24, 24, 24),
		    TabBg = Color3.fromRGB(141, 141, 201),
		    TabTextActive = Color3.fromRGB(255, 255, 255),
		    TabBgActive = Color3.fromRGB(22, 22, 41),
		})

		-- Purple Theme
		ImGui:DefineTheme("🍇 Purple", {
		    TitleAlign = Enum.TextXAlignment.Center,
		    TextDisabled = Color3.fromRGB(120, 100, 130),
		    Text = Color3.fromRGB(200, 180, 210),
		
		    FrameBg = Color3.fromRGB(25, 20, 30),
		    FrameBgTransparency = 0.4,
		    FrameBgActive = Color3.fromRGB(120, 100, 130),
		    FrameBgTransparencyActive = 0.4,
		
		    CheckMark = Color3.fromRGB(150, 100, 170),
		    SliderGrab = Color3.fromRGB(150, 100, 170),
		    ButtonsBg = Color3.fromRGB(150, 100, 170),
		    CollapsingHeaderBg = Color3.fromRGB(150, 100, 170),
		    CollapsingHeaderText = Color3.fromRGB(200, 180, 210),
		    RadioButtonHoveredBg = Color3.fromRGB(150, 100, 170),
		
		    WindowBg = Color3.fromRGB(35, 30, 40),
		    TitleBarBg = Color3.fromRGB(35, 30, 40),
		    TitleBarBgActive = Color3.fromRGB(50, 45, 55),
		
		    Border = Color3.fromRGB(50, 45, 55),
		    ResizeGrab = Color3.fromRGB(50, 45, 55),
		    RegionBgTransparency = 1,
		
		    TabText = Color3.fromRGB(24, 24, 24),
		    TabBg = Color3.fromRGB(171, 141, 201),
		    TabTextActive = Color3.fromRGB(255, 255, 255),
		    TabBgActive = Color3.fromRGB(35, 22, 41),
		})

		local allThemes = {}

		for i, v in ImGui.ThemeConfigs do
			table.insert(allThemes, i)
		end

		UiTab:Combo({
			Placeholder = "Select Theme",
			Label = "Theme",
			IniFlag = "ThemeSelectorDropdown",
			Items = allThemes,
			Value = "🌸Pink",
			Callback = function(_, Value)
				for _, v in ImGui.Windows do
					v:SetTheme(Value)
				end
			end,
		})
	end
end

function BaseLoader:UnloadTab()
    -- unloading gui
    local closeTab = self.window:CreateTab({
    	Name = "Unload",
    })

    closeTab:Separator({

    })

    closeTab:Button({
        Text = "Unload the script",
        Callback = function()
            self:Unload()
    		self:Notify("Unload", "Unloaded (Everything disabled, re-execute to enable)" , 3)
        end,
    })
end

function BaseLoader:Unload()
    if not self.loaded then return end
    self.loaded = false
	if self.autosave then
		self.autosave()
	end
    self.hooks:Cleanup()
	self.window:Close()
    self.window.WindowFrame:Destroy()
	self.window:Destroy()
end

return BaseLoader