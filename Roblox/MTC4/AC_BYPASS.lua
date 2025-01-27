--adonis
loadstring(game:HttpGet("https://raw.githubusercontent.com/Pixeluted/adoniscries/main/Source.lua", true))()

--ac bypass
do
    local IsA = Instance.new("Part").IsA

    local function hook(self: RemoteEvent, ...)
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
        return true
    end

    --namecall hook
    do
        local old; old = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
    
            if method and method == "FireServer" or method == "fireServer" then
                if hook(self, ...) then
                    return old(self, ...)
                end
            end
        end)
    end

    --function hook
    do
        --remote event
        do
            local old; old = hookfunction(Instance.new("RemoteEvent").FireServer, function(self, ...)
                if hook(self, ...) then return old(self, ...) end 
            end)
        end
        --unrealiable remote event
        do
            local old; old = hookfunction(Instance.new("UnreliableRemoteEvent").FireServer, function(self, ...)
                if hook(self, ...) then return old(self, ...) end 
            end)
        end
    end
end
