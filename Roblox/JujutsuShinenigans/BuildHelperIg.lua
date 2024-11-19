local Player = game:GetService("Players").LocalPlayer

local function sakso(child)
    task.wait()
    for _, v: TextBox in child:GetDescendants() do
        if v:IsA("TextBox") then
            v.ClearTextOnFocus = false
        end
    end
end

Player.PlayerGui.ChildAdded:Connect(function(child)
    if child.Name == "BuildTools" then
        sakso(child)
    end
end)

if Player.PlayerGui:FindFirstChild("BuildTools") then
    sakso(Player.PlayerGui.BuildTools)
end

local function update(increment: number)
    if not Player.PlayerGui:FindFirstChild("BuildTools") then return end
    local path = Player.PlayerGui.BuildTools.Menu.Properties2
    local stuff = {
        path.Input,
        path.Output
    }
    for _, v: TextBox in stuff do
        if not tonumber(v.Text ) then continue end
        local val = tostring(tonumber(v.Text) + increment)
        v:CaptureFocus()
        v.Text = val
        v:ReleaseFocus(true)
    end
end



--https://github.com/depthso/Roblox-ImGUI/wiki/Elements
local ImGui = loadstring(game:HttpGet('https://raw.githubusercontent.com/skibidiMusic/Lua/refs/heads/main/Roblox/Util/UiLib/ImGui.lua'))()
local Window = ImGui:CreateWindow({Title = "Build helper sakso", Position = UDim2.new(0.5, 0, 0, 70), Size = UDim2.new(0, 300, 0, 300), AutoSize = false,})
Window:Center()

local tab = Window:CreateTab({
    Name = "main",
    Visible = true 
})

local val = 200
tab:InputText({
    PlaceHolder = "200",
    ClearTextOnFocus = false,
    saveFlag = "mrsaksobeat1",

	Callback = function(self, Value)
		val = tonumber(Value) or val
	end,
})

local lockOnKeybind = tab:Keybind({
    Label = "Update Val",
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

local unloadTab = Window:CreateTab({
    Name = "Unload",
    Visible = false 
})

unloadTab:Button({
	Text = "Unload",
	Callback = function(self)
		Window:Destroy()
	end,
})


Window:CreateConfigSaveHandler("MR_SAKSO_BEAT_JJS")