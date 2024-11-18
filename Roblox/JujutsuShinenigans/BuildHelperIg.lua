local path = game:GetService("Players").LocalPlayer.PlayerGui.BuildTools.Menu.Properties2

local stuff = {
    path.Input,
    path.Output
}

local function update(increment: number)
    for _, v: TextBox in stuff do
        if not tonumber(v.Text ) then continue end
        local val = tostring(tonumber(v.Text) + increment)
        v:CaptureFocus()
        v.Text = val
        v:ReleaseFocus(true)
    end
end

local ImGui = loadstring(game:HttpGet('https://raw.githubusercontent.com/skibidiMusic/Lua/refs/heads/main/Roblox/Util/UiLib/ImGui.lua'))()
local Window = ImGui:CreateWindow({Title = "Build helper sakso", Position = UDim2.new(0.5, 0, 0, 70), Size = UDim2.new(0, 800, 0, 500), AutoSize = false,})
Window:Center()

local tab = Window:CreateTab({
    Name = "main",
    Visible = true 
})

local val = 200
local slider = tab:Slider({
	Label = "Increment Value",
	Format = "%.d/%s", 
	Value = 200,
	MinValue = 1,
	MaxValue = 1000,
    saveFlag = "mrsaksobeat",

	Callback = function(self, Value)
		val = math.round(Value)
	end,
})

local lockOnKeybind = tab:Keybind({
    Label = "Keybind",
    Value = Enum.KeyCode.X,
    saveFlag = "saksoMakso",
    Callback = function()
        update(val)
    end,
})


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

Window:CreateConfigSaveHandler("MR_SAKSO_BEAT_JJS")