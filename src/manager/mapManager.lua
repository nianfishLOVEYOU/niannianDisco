-- src/map_loader.lua
local json = require "lib.json" -- 需要放入 json.lua（常用的纯 Lua JSON 库）
local Item = require "src.item.item"

local mapManager = {}

mapManager.itemTypes = {}
mapManager.itemnews = {}

-- 自动加载 src/item 目录下的所有 Lua 文件，注册为可用的 item 类型
local itemFiles = love.filesystem.getDirectoryItems("src/item")
table.sort(itemFiles)
local excludedModules = {
    item = true,
    bodyItem = true,
    imageItem = true
}

for _, file in ipairs(itemFiles) do
    if file:match("%.lua$") then
        local module = file:gsub("%.lua$", "")
        if not excludedModules[module] then
            table.insert(mapManager.itemTypes, module)
            mapManager.itemnews[module] = require("src.item." .. module)
        end
    end
end

--- 读取并解析地图文件
--- @param mapFile 相对根目录的 JSON 路径，例如 "maps/map01.json"
--- @return table 包含 fields: backgroundImage (Image), items (list of Item)
function mapManager.load(mapFile)
    local raw = love.filesystem.read(mapFile)
    if not raw then
        error("无法读取地图文件：" .. mapFile)
    end
    local data = json.decode(raw)

    local map = {}
    -- map.background = resourceManager.loadImage(data.background) -- 背景图片
    map.items = {}
    map.startPoint = {
        x = 0,
        y = 0
    }

    for _, it in ipairs(data.items) do
        print("mapLoad:", it.type)
        if mapManager.itemnews[it.type] then
            local item = mapManager.itemnews[it.type]:new()
            item:setPos(it.x, it.y, it.z)
            -- 特殊的有长宽不定的item
            if it.type == "wall" then
                item:setSize(it.w, it.h)
            end

            table.insert(map.items, item)
        else
            local item = Item:new()
            item:setSize(it.w, it.h)
            item:setPos(it.x, it.y, it.z)
            table.insert(map.items, item)
        end
        -- 如果有开始位子则记录
        if it.type == "startPoint" then
            map.startPoint = {
                x = it.x,
                y = it.y
            }
        end
    end

    return map
end


--加载地图到游戏中，先关闭当前地图（如果有），然后读取新地图并创建物体
function mapManager:loadMap(mapPath)
    self:closeMap()
    if love.filesystem.getInfo(mapPath) then
        globleManager.map = self.load(mapPath)
        for i, v in ipairs(globleManager.map.items) do
            itemManager:addItem(v)
        end
        cameraManager.cam:setPosition(globleManager.map.startPoint.x, globleManager.map.startPoint.y)
    end
end

function mapManager:closeMap()
    globleManager.map = nil
    itemManager:removeAll()
    -- playerManager:removeAllPlayers()
end

function mapManager:saveMap(outFile)
    print("保存地图到:", outFile)
    self.save(itemManager.items, outFile)
end

--- mapTable 包含items  startPoint
--- 将地图对象保存为 JSON（编辑器使用）
--- @param mapTable 必须包含 fields: background (string), items (list)
--- @param outFile 输出路径，例如 "maps/map01.json"
function mapManager.save(items, outFile)
    local out = {
        -- background = "res/image/map01.png",
        items = {}
    }
    for k, it in pairs(items) do
        table.insert(out.items, {
            type = it.type,
            x = it.x,
            y = it.y,
            z = it.z,
            w = it.w,
            h = it.h
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

return mapManager
