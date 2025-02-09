-->> SRC
--https://github.com/depthso/Roblox-ImGUI/wiki/Elements
local ImGui = loadstring(game:HttpGet('https://raw.githubusercontent.com/skibidiMusic/Lua/refs/heads/main/Roblox/Util/UiLib/ImGui.lua'))()
local Janitor = loadstring(game:HttpGet('https://raw.githubusercontent.com/skibidiMusic/Lua/refs/heads/main/Roblox/Util/Misc/Janitor.lua'))()

if HaikyuuRaper then
    if HaikyuuRaper.unload then
        HaikyuuRaper.unload()
    end
else
    getgenv().HaikyuuRaper = {}
end

local Window = ImGui:CreateWindow({Title = "HaikyuuRaper", Position = UDim2.new(0.5, 0, 0, 70), Size = UDim2.new(0, 800, 0, 500), AutoSize = false,})
Window:Center()

local hooks = Janitor.new()
HaikyuuRaper.unload = function()
    hooks:Cleanup()
	Window:Destroy()
	HaikyuuRaper.unload = nil
end

