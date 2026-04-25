-- src/map_loader.lua
local json = require "lib.json" -- 需要放入 json.lua（常用的纯 Lua JSON 库）
local Item = require "src.item.item"

local mapManager = {
    map=nil
}

local itemFactory = require "src.map.itemFactory"
local wallFactory = require "src.map.wallFactory"
local gridFactory = require "src.map.gridFactory"


function mapManager:getMapGridIndex(x,y)
    if(self.map) then
        local gridx=math.ceil(x/self.map.gridSize)
        local gridy=math.ceil(y/self.map.gridSize)
        return gridx,gridy
    end
end

function mapManager:getMapGrid(x,y)
    local gridx,gridy=self:getMapGridIndex(x,y)
    if(self.map and self.map.grids[gridy] and self.map.grids[gridy][gridx]) then
        return self.map.grids[gridy][gridx]
    end
end

function mapManager:getMapWall(x,y)
    local gridx,gridy=self:getMapGridIndex(x,y)
    if(self.map and self.map.walls[gridy] and self.map.walls[gridy][gridx]) then
        return self.map.walls[gridy][gridx]
    end
end

function mapManager:GridIndexToScreen(index_x,index_y)
    if(self.map) then
        local x = (index_x - 0.5) * self.map.gridSize
        local y = (index_y - 0.5) * self.map.gridSize
        return x, y
    end
end




--- 读取并解析地图文件
--- @param mapFile 相对根目录的 JSON 路径，例如 "maps/map01.json"
--- @return table 包含 fields: backgroundImage (Image), items (list of Item)
function mapManager.load(mapFile)
    local raw = love.filesystem.read(mapFile)
    if not raw then
        error("无法读取地图文件：" .. mapFile .. "，创建一个空地图")
        return mapManager:creatMap(256, 256) -- 创建一个默认大小的空地图
    end
    local data = json.decode(raw)

    local map = require "src.map.map"

    -- 解析 items，创建对应的 Item 实例
    for _, it in ipairs(data.items) do
        print("mapLoad:", it.type)
        if itemFactory.types[it.type] then

            local item = itemFactory:newItem(it.type)
            item:setPos(it.x, it.y, it.z)
            -- 特殊的有长宽不定的item
            table.insert(map.items, item)
        else
            local item = Item:new()
            item:setSize(it.w, it.h)
            item:setPos(it.x, it.y, it.z)
            table.insert(map.items, item)
        end
    end

    local w = data.size.width
    local h = data.size.height
    -- 解析 walls
    for y = 1, h do
        table.insert(map.walls, {})
        for x = 1, w do
            map.walls[y][x] = "empty"
        end
    end
    if data.walls and #data.walls > 0 then
        for row, wallRow in ipairs(data.walls) do
            for col, wallType in ipairs(wallRow) do
                if wallType ~= "empty" then
                    map.walls[row][col] = wallFactory:newWall(wallType)
                end
            end
        end
    end

    -- 解析 grids
    for y = 1, h do
        table.insert(map.grids, {})
        for x = 1, w do
            map.grids[y][x] = "empty"
        end
    end
    if data.grids and #data.grids > 0 then
        for row, gridRow in ipairs(data.grids) do
            for col, gridType in ipairs(gridRow) do
                if gridType ~= "empty" then
                    map.grids[row][col] = gridFactory:newGrid(gridType)
                end
            end
        end
    end

    -- 解析背景图片
    if data.background then
        map.background = love.graphics.newImage(data.background)
    end

    return map
end

function mapManager:creatMap(w, h)
    local map = require "src.map.map"
    map.size.width = w
    map.size.height = h
    for y = 1, h do
        table.insert(map.walls, {})
        table.insert(map.grids, {})
        for x = 1, w do
            map.walls[y][x] = "empty"
            map.grids[y][x] = "empty"
        end
    end
    return map
end

-- 加载地图到游戏中，先关闭当前地图（如果有），然后读取新地图并创建物体
function mapManager:loadMap(mapPath)
    self:closeMap()
    if love.filesystem.getInfo(mapPath) then
        self.map = self.load(mapPath)
        for i, v in ipairs(self.map.items) do
            itemManager:addItem(v)
        end
        cameraManager.cam:setPosition(self.map.startPoint.x, self.map.startPoint.y)
    end
end

function mapManager:closeMap()
    self.map = nil
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

    local out = require "src.map.map"

    for k, it in pairs(map.items) do
        table.insert(out.items, it:serialize())
    end

    for y = 1, #map.walls do
        out.walls[y] = {}
        for x = 1, #map.walls[y] do
            local wall = map.walls[y][x]
            if wall ~= "empty" then
                out.walls[y][x] = wall.type
            else
                out.walls[y][x] = "empty"
            end
        end
    end

    for y = 1, #map.grids do
        out.grids[y] = {}
        for x = 1, #map.grids[y] do
            local grid = map.grids[y][x]
            if grid ~= "empty" then
                out.grids[y][x] = grid.type
            else
                out.grids[y][x] = "empty"
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
