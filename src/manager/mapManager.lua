-- src/map_loader.lua
local json = require "lib.json" -- 需要放入 json.lua（常用的纯 Lua JSON 库）
local Item = require "src.item.item"

local mapManager = {
}

local itemFactory = require "src.map.itemFactory"
local gridFactory = require "src.map.gridFactory"

--转网格坐标
function mapManager:toGridIndex(worldx,worldy)
    if (self.map) then
        local gridx = math.ceil(worldx / self.map.gridSize)
        local gridy = math.ceil(worldy / self.map.gridSize)
        print("获得map grid index：", gridx, gridy)
        if(gridx < 1 or gridy < 1 or gridx > self.map.size.width or gridy > self.map.size.height) then
            return nil, nil
        end
        return gridx, gridy
    end
end

function mapManager:toGridPos(indexx,indexy)
    if (self.map) then
        local worldx = (indexx - 1) * self.map.gridSize
        local worldy = (indexy - 1) * self.map.gridSize
        return worldx, worldy
    end
end


--获得地块
function mapManager:getMapGrid(indexx, indexy)
    if (self.map and self.map.grids[indexx] and self.map.grids[indexx][indexy]) then
        return self.map.grids[indexx][indexy]
    end
    return nil
end

--获得物体
function mapManager:getMapItem(indexx, indexy)
    if (self.map and self.map.items[indexx] and self.map.items[indexx][indexy]) then
        return self.map.items[indexx][indexy]
    end
    return nil
end


--- 读取并解析地图文件
--- @param mapFile 相对根目录的 JSON 路径，例如 "maps/map01.json"
--- @return table 包含 fields: backgroundImage (Image), items (list of Item)
function mapManager.loadMapFile(mapFile)
    local raw = love.filesystem.read(mapFile)
    if not raw then
        error("无法读取地图文件：" .. mapFile .. "，创建一个空地图")
        return nil
    end
    print("加载地图文件:", mapFile)
    local data = json.decode(raw)

    local map = data 

    local w = data.size.width
    local h = data.size.height
    print("地图大小：", w, h)

    -- 解析 items
    if map.items and #map.items > 0 then
        for x, itemsCol in ipairs(map.items) do
            for y, itemdata in ipairs(itemsCol) do
                if itemdata ~= nil then
                    print("mapLoad:", itemdata.type)

                    if itemFactory.types[itemdata.type] then

                        local item = itemFactory:newItem(itemdata.type)
                        item:setPos(itemdata.x, itemdata.y, itemdata.z)
                        -- 特殊的有长宽不定的item
                        map.items[x][y] = item
                    else
                        local item = Item:new()
                        item:setSize(itemdata.w, itemdata.h)
                        item:setPos(itemdata.x, itemdata.y, itemdata.z)
                        map.items[x][y] = item
                    end
                end
            end
        end
    end

    -- 解析 grids
    if map.grids and #map.grids > 0 then
        for x, gridCol in ipairs(map.grids) do
            for y, gridType in ipairs(gridCol) do
                if gridType ~= nil then
                    map.grids[x][y] = gridFactory:newGrid(gridType)
                end
            end
        end
    end

    -- 解析背景图片
    if map.background and map.background ~= "" then
        map.background = love.graphics.newImage(map.background)
    end

    return map
end

function mapManager:creatMap(w, h)
    local map = require "src.map.map"
    map.size.width = w
    map.size.height = h
    for x = 1, w do
        table.insert(map.grids, {})
        table.insert(map.items, {})
        for y = 1, h do
            map.items[x][y] = nil
            map.grids[x][y] = nil
        end
    end
    print("创建新地图，大小：", w, h)
    return map
end

-- 加载地图到游戏中，先关闭当前地图（如果有），然后读取新地图并创建物体
function mapManager:loadMap(mapPath)
    self:closeMap()
    if love.filesystem.getInfo(mapPath) then
        self.map = self.loadMapFile(mapPath)
        -- 将地图中的 items 添加到 itemManager 中进行管理
        for i, v in ipairs(self.map.items) do
            for j, item in ipairs(v) do
                if item then
                    itemManager:addItem(item)
                end
            end
        end
        for i, v in ipairs(self.map.grids) do
            for j, grid in ipairs(v) do
                if grid then
                    gridManager:addGrid(grid, i, j)
                end
            end
        end
        
        cameraManager.cam:setPosition(self.map.startPoint.x, self.map.startPoint.y)
        return self.map
    else
        print("地图文件不存在，创建一个空地图")
        self.map=self:creatMap(10, 10)
        return self.map
    end
end

function mapManager:closeMap()
    --self.map = nil
    itemManager:removeAll()
end

function mapManager:saveMap(outFile)
    print("保存地图到:", outFile)
    self.save(self.map, outFile)
end

--- mapTable 包含items  startPoint
--- 将地图对象保存为 JSON（编辑器使用）
--- @param mapTable 必须包含 fields: background (string), items (list)
--- @param outFile 输出路径，例如 "maps/map01.json"
function mapManager.save(map, outFile)
    --导出初始设置
    local out = require "src.map.map"
    out.gridSize=map.gridSize or 32
    out.background = map.background or ""
    out.size = {width=map.size.width, height=map.size.height}
    out.startPoint = { x = map.startPoint.x, y = map.startPoint.y }
    
    for x = 1, out.size.width do
        table.insert(out.items, {})
        table.insert(out.grids, {})

        for y = 1, out.size.height do
            
            local item = map.items[x][y]
            if item ~= nil then
                out.items[x][y] = item:serialize()
            else
                out.items[x][y] = nil
            end

            local grid = map.grids[x][y]
            if grid ~= nil then
                out.grids[x][y] = grid.type
            else
                out.grids[x][y] = nil
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
