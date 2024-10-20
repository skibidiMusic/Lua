local char = game.Players.Character
if not char then return end 

local currentMoveset = char:GetAttribute("Moveset")
local service = game.ReplicatedStorage.Knit.Knit.Services[currentMoveset .. "Service"]

local remote = service.RE.Activated
remote:FireServer("Down")