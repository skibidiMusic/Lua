local Players = game:GetService("Players")
local player = Players.LocalPlayer
local old; old = hookmetamethod(game, "__index", newcclosure(function(self, index, ...)
        if not checkcaller() and typeof(self) == "Instance" and self == (old(player, "Character") and old(player, "Character"):FindFirstChildOfClass("Humanoid")) and rawequal(index, "MoveDirection") and #({...}) == 0  then
                print( debug.info(3,"n"))
        end
        return old(self, index, ...)
end))