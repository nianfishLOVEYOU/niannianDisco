-- src/map_loader.lua
local json = require "json"          -- 需要放入 json.lua（常用的纯 Lua JSON 库）
local Item = require "item"
local Resource = require "resource"

local MapLoader = {}

--- 读取并解析地图文件
--- @param mapFile 相对根目录的 JSON 路径，例如 "maps/map01.json"
--- @return table 包含 fields: backgroundImage (Image), items (list of Item)
function MapLoader.load(mapFile)
    local raw = love.filesystem.read(mapFile)
    if not raw then error("无法读取地图文件："..mapFile) end
    local data = json.decode(raw)

    local map = {}
    map.background = Resource.loadImage(data.background)   -- 背景图片
    map.items = {}

    for _, it in ipairs(data.items) do
        local item = Item:new(it.x, it.y, it.w, it.h, it.img)
        table.insert(map.items, item)
    end

    return map
end

--- 将地图对象保存为 JSON（编辑器使用）
--- @param mapTable 必须包含 fields: background (string), items (list)
--- @param outFile 输出路径，例如 "maps/map01.json"
function MapLoader.save(mapTable, outFile)
    local jsonStr = json.encode(mapTable, {indent = true})
    love.filesystem.write(outFile, jsonStr)
end

return MapLoader