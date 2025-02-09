--adonis
loadstring(game:HttpGet("https://raw.githubusercontent.com/Pixeluted/adoniscries/main/Source.lua", true))()

--game anticheat bypass
local IsA = Instance.new("Part").IsA
local old; old = hookmetamethod(game, "__namecall", function(self, ...)
    if typeof(self) == "Instance" and IsA(self, "RemoteEvent") or IsA(self, "UnreliableRemoteEvent") then

        if self.Name == "IWantToBeBanned" then
            print("ban remote bypassed")
            return
        end

        local args = {...}
        if rawequal(args[1], "gone") then
            print("goner bypassed")
            return
        end

    end
    return old(self, ...)
end)