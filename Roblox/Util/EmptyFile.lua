local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local t = tick()

getgenv().sakso3169 = t

while true and getgenv().sakso3169 == t do
	task.wait()
	local charInfo = Player.Character and Player.Character:FindFirstChild("Info")
	if charInfo then
		local values = {
			Stun = true,
			NoSprint = true,
			NoJump = true,
			InSkill = true,
		}
		for name, bool in values do
			if bool then
				local val =charInfo:FindFirstChild(name)
				if val then
					val:Destroy()
				end
			end
		end
	end
end