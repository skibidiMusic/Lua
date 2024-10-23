-->> loadstrng
--[[
    
    local fileManager = loadstring(game:HttpGet('https://raw.githubusercontent.com/skibidiMusic/Lua/refs/heads/main/Roblox/Util/fileManager.lua'))()
]]

-->> src
local HttpService = game:GetService"HttpService"

local function findLastPath(v: string)
    local found = string.find(v, "/")
    if found then
        return findLastPath(string.sub(v, found + 1))
    end
    return v
end

local function fileNameFromPath(path: string)
    local file = findLastPath(path)
    return string.sub(file, 1, string.find(file, "%.") - 1)
end

local function filePathFromName(folderPath: string, name: string)
    return folderPath .. "/" .. name .. ".txt"
end

local fileManager = {}
fileManager.__index = fileManager

function fileManager.new(folderPath: string)
    if not isfolder(folderPath) then
        makefolder(folderPath)
    end
    return setmetatable({folderPath = folderPath}, fileManager)
end

function fileManager.getSave(self, fileName: string)
    local filePath = filePathFromName(self.folderPath, fileName)
    if isfile(filePath) then
        return HttpService:JSONDecode(readfile(filePath))
    end
end

function fileManager.getSaves(self)
    local files = listfiles(self.folderPath)
    local saves = {}
    for _, filePath in files do
        local fileName = fileNameFromPath(filePath)
        saves[fileName] = HttpService:JSONDecode(readfile(filePath))
    end
    return saves
end

function fileManager.delete(self, fileName: string)
    local filePath = filePathFromName(self.folderPath, fileName)
    if isfile(filePath) then
        delfile(filePath)
    end
end

function fileManager.save(self, fileName: string, configTable: {})
    local filePath = filePathFromName(self.folderPath, fileName)
    writefile(filePath, HttpService:JSONEncode(configTable))
end

return fileManager