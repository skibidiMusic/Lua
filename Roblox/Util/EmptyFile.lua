if not REALEST_OF_ALL then
	loadstring(game:HttpGet("https://raw.githubusercontent.com/Pixeluted/adoniscries/main/Source.lua", true))()
end

local real = REALEST_OF_ALL  and REALEST_OF_ALL + 1 or 0
getgenv().REALEST_OF_ALL = real

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

local old; old = hookmetamethod(game, "__newindex", function(self, index: string, ...)
	if REALEST_OF_ALL == real and not checkcaller() and typeof(index) == "string" and index == "Position" and typeof(self) == "Instance" and self.Parent and self.Name == "crosshair" and self.Parent.Name == "mobilegui" then
		local caller = getcallingscript()
		warn(ToString(caller))
	end
	return old(self, index, ...)
end)