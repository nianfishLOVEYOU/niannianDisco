-- src/map_loader.lua
local json = require "lib.json" -- 需要放入 json.lua（常用的纯 Lua JSON 库）
local Item = require "src.item.item"
local itemFactory = require "src.map.itemFactory"

local mapManager = {}


function mapManager:init()
    self.itemFactory = itemFactory:new("src/item/items")
    self.gridFactory = itemFactory:new("src/item/grids")
end

mapManager:init()

-- 转网格坐标
function mapManager:toGridIndex(worldx, worldy)
    if (self.map) then
        local gridx = math.ceil(worldx / self.map.gridSize)
        local gridy = math.ceil(worldy / self.map.gridSize)
        if (gridx < 1 or gridy < 1 or gridx > self.map.size.width or gridy > self.map.size.height) then
            return nil, nil
        end
        return gridx, gridy
    end
end

function mapManager:toGridPos(indexx, indexy)
    if (self.map) then
        local worldx = (indexx - 1) * self.map.gridSize + self.map.gridSize / 2
        local worldy = (indexy) * self.map.gridSize
        return worldx, worldy
    end
end

-- 获得地块
function mapManager:getMapGrid(indexx, indexy)
    if (self.map and self.map.grids[indexx] and self.map.grids[indexx][indexy] and self.map.grids[indexx][indexy] ~= 0) then
        return self.map.grids[indexx][indexy]
    end
    return nil
end

-- 获得物体
function mapManager:getMapItem(indexx, indexy)
    if (self.map and self.map.items[indexx] and self.map.items[indexx][indexy] and self.map.items[indexx][indexy] ~= 0) then
        return self.map.items[indexx][indexy]
    end
    return nil
end

-- 添加物体
function mapManager:addItem(type, indexx, indexy, isLoading)
    local itemType = type
    local x, y = self:toGridPos(indexx, indexy)

    if not isLoading and self:getMapItem(indexx, indexy) then
        return
    end
    print("addItem xy:", indexx, indexy, "物体类型：", itemType)
    local newItem = self.itemFactory:newItem(itemType)
    newItem:setPos(x, y)
    newItem.type = itemType
    itemManager:addItem(newItem)
    self.map.items[indexx][indexy] = newItem

end

-- 删除物体
function mapManager:removeItem(indexx, indexy)
    local item = self:getMapItem(indexx, indexy)
    if item then
        itemManager:removeItem(item.id)
        self.map.items[indexx][indexy]:destroy()
        self.map.items[indexx][indexy] = 0
    end
end

-- 地块添加
function mapManager:addGrid(type, indexx, indexy, isLoading)
    local itemType = type
    local x, y = self:toGridPos(indexx, indexy)

    if not isLoading and self:getMapGrid(indexx, indexy) then
        return
    end
    print("addItem xy:", indexx, indexy, "地板类型：", itemType)
    local newItem = self.gridFactory:newItem(itemType)
    newItem:setPos(x, y)
    newItem.type = itemType
    itemManager:addItem(newItem)
    self.map.grids[indexx][indexy] = newItem

end

-- 地块删除
function mapManager:removeGrid(indexx, indexy)
    local item = self:getMapGrid(indexx, indexy)
    if item then
        itemManager:removeItem(item.id)
        self.map.grids[indexx][indexy]:destroy()
        self.map.grids[indexx][indexy] = 0
    end
end

function mapManager:creatMap(w, h)
    local createMap = require "src.map.map"
    local map = createMap()
    map.size.width = w
    map.size.height = h
    for x = 1, w do
        table.insert(map.grids, {})
        table.insert(map.items, {})
        for y = 1, h do
            map.items[x][y] = 0
            map.grids[x][y] = 0
        end
    end
    print("创建新地图，大小：", w, h)
    return map
end

-- 加载地图到游戏中，先关闭当前地图（如果有），然后读取新地图并创建物体
function mapManager:loadMap(mapPath)
    self:closeMap()
    if love.filesystem.getInfo(mapPath) then
        self:_loadMapFile(mapPath)
        --cameraManager.cam:setPosition(self.map.startPoint.x, self.map.startPoint.y)
        print("地图文件存在，加载地图：", mapPath, "起始点：", self.map.startPoint.x, self.map.startPoint.y)
        return self.map
    else
        print("地图文件不存在，创建一个空地图")
        self.map = self:creatMap(10, 10)
        return self.map
    end
end


--- 读取并解析地图文件
--- @param mapFile 相对根目录的 JSON 路径，例如 "maps/map01.json"
--- @return table 包含 fields: backgroundImage (Image), items (list of Item)
function mapManager:_loadMapFile(mapFile)
    local raw = love.filesystem.read(mapFile)
    if not raw then
        error("无法读取地图文件：" .. mapFile .. "，创建一个空地图")
        return nil
    end
    print("加载地图文件:", mapFile)
    local data = json.decode(raw)

    self.map = data

    local w = data.size.width
    local h = data.size.height
    print("地图大小：", w, h)

    -- 解析 items
    if self.map.items and #self.map.items > 0 then
        for x, itemsCol in ipairs(self.map.items) do
            for y, itemdata in ipairs(itemsCol) do
                if itemdata ~= 0 then

                    print("load 创建物体：", itemdata.type, "坐标：", x, y)
                    self:addItem(itemdata.type, x, y, true)
                end
            end
        end
    end

    -- 解析 grids
    if self.map.grids and #self.map.grids > 0 then
        for x, gridCol in ipairs(self.map.grids) do
            for y, gridType in ipairs(gridCol) do
                if gridType ~= 0 then
                    print("load 创建地块：", gridType, "坐标：", x, y)
                    self:addGrid(gridType, x, y, true)
                end
            end
        end
    end

    -- 解析背景图片
    if self.map.background and self.map.background ~= "" then
        self.map.background = love.graphics.newImage(self.map.background)
    end

end


function mapManager:closeMap()
    -- self.map = nil
    itemManager:removeAll()
end

function mapManager:saveMap(outFile)
    print("保存地图到:", outFile)
    self._save(self.map, outFile)
end


--- mapTable 包含items  startPoint
--- 将地图对象保存为 JSON（编辑器使用）
--- @param mapTable 必须包含 fields: background (string), items (list)
--- @param outFile 输出路径，例如 "maps/map01.json"
function mapManager._save(map, outFile)
    -- 导出初始设置
    local createMap = require "src.map.map"
    local out = createMap()
    out.gridSize = map.gridSize or 32
    out.background = map.background or ""
    out.size = {
        width = map.size.width,
        height = map.size.height
    }
    out.startPoint = {
        x = map.startPoint.x,
        y = map.startPoint.y
    }
    print("导出地图设置：", "背景图:", out.background, "网格大小:", out.gridSize, "地图大小:",
        out.size.width, out.size.height, "起始点:", out.startPoint.x, out.startPoint.y)
    nianTool.dump(out)
    for x = 1, out.size.width do
        out.items[x] = {}
        out.grids[x] = {}
        for y = 1, out.size.height do
            print("导出坐标：", x, y, map.items[x][y])
            local item = map.items[x][y]
            if item ~= 0 then
                print("save 物体：", item.type, "坐标：", x, y)
                out.items[x][y] = item:serialize()
            else
                out.items[x][y] = 0
            end

            local grid = map.grids[x][y]
            if grid ~= 0 then
                print("save 地块：", grid.type, "坐标：", x, y)
                out.grids[x][y] = grid.type
            else
                out.grids[x][y] = 0
            end
        end
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
