local function ToScript(v:any, depth: number?)
    local dataType = typeof(v)
    local str;

    if dataType == "Instance" then
        dataType = v.ClassName
        str = "game." .. v:GetFullName()
    else
        if dataType == "table" then
            depth = depth or 0
            local depthShit = string.rep("\t", depth)
            str = "{\n"
            for i, c in v do
                str = str .. string.format(depthShit .. "\t[%s] = %s,\n", ToScript(i, depth), ToScript(c, depth + 1))
            end
            str = str .. depthShit .. "}"
        elseif dataType == "string" then
            str = string.format("%q", v)
        else
            str = tostring(v)
        end
    end

    return str
end

return ToScript