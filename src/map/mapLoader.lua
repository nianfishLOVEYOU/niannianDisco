-- src/map_loader.lua
local json = require "lib.json" -- 需要放入 json.lua（常用的纯 Lua JSON 库）
local Item = require "src.item.item"

local MapLoader = {}

local itemTypes = {"floor","tree", "wall", "mic", "ball", "sofa", "startPoint", "eventZone", "lightpoint", "fire"}
local itemnews = {}

for _, module in ipairs(itemTypes) do
    itemnews[module] = require("src.item." .. module)
end

--- 读取并解析地图文件
--- @param mapFile 相对根目录的 JSON 路径，例如 "maps/map01.json"
--- @return table 包含 fields: backgroundImage (Image), items (list of Item)
function MapLoader.load(mapFile)

    local raw = love.filesystem.read(mapFile)
    if not raw then
        error("无法读取地图文件：" .. mapFile)
    end
    local data = json.decode(raw)

    local map = {}
    --map.background = resourceManager.loadImage(data.background) -- 背景图片
    map.items = {}
    if data.startPoint then
        map.startPoint = {
            x = data.startPoint.x,
            y = data.startPoint.y
        }
    else
        map.startPoint = {
            x = 0,
            y = 0
        }
    end

    for _, it in ipairs(data.items) do
        print("mapLoad:", it.type)
        if itemnews[it.type] then
            local item = itemnews[it.type]:new(it.x, it.y, it.w, it.h)
            item:setPos(it.x, it.y,it.z)
            table.insert(map.items, item)
        else
            local item=Item:new(it.x, it.y, it.w, it.h)
            item:setPos(it.x, it.y,it.z)
            table.insert(map.items, item)
            item.color={1,0,0}
        end
    end

    return map
end
--- mapTable 包含items  startPoint
--- 将地图对象保存为 JSON（编辑器使用）
--- @param mapTable 必须包含 fields: background (string), items (list)
--- @param outFile 输出路径，例如 "maps/map01.json"
function MapLoader.save(mapTable, outFile)
    local out = {
        --background = "res/image/map01.png",
        items = {},
        startPoint = {
            x = mapTable.startPoint.x,
            y = mapTable.startPoint.y
        }
    }
    for _, it in ipairs(mapTable.items) do
        table.insert(out.items, {
            type = it.type,
            x = it.x,
            y = it.y,
            z = it.z,
            w = it.w,
            h = it.h,
        })
    end

    local jsonStr = json.encode(out, {
        indent = true
    })

    local file, err = io.open(outFile, "w") -- "a" 追加写入，若文件不存在会自动创建
    if not file then
        print("打开文件失败:", err)
        return
    end
    file:write(jsonStr)
    file:close()

end

return MapLoader
