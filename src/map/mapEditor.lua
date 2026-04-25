-- src/main_editor.lua
local Item = require "src.item.item"
local MapEditorUI = require "src.ui.editor.mapEdiorUI"

local itemFactory = require "src.map.itemFactory"
local wallFactory = require "src.map.wallFactory"
local gridFactory = require "src.map.gridFactory"

local mapEditor = {
    brushOpen = false, --是否打开右键菜单
    brushSize = 1, --画笔大小，默认为1格
    brush = 0 --0=物体 1=墙 2=地板
}

local history = {}

mouseManager:mousepressed_regester(function(x, y, button)
    mapEditor:mousepressed(x, y, button)
end)
mouseManager:mouseMoved_regester(function(x, y, dx, dy)
    mapEditor:mousemoved(x, y, dx, dy)
end)
mouseManager:mouseLeased_regester(function(x, y, button)
    mapEditor:mousereleased(x, y, button)
end)
mouseManager:wheelMoved_regester(function(x, y)
    mapEditor:wheelmoved(x, y)
end)
keybordManager:keypressed_regester(function(key)
    mapEditor:keypressed(key)
end)

 

function mapEditor:init()
    print("开始地图编辑")

    mapManager:loadMap("res/maps/edited.json")

    -- keep a direct reference for convenience
    mapEditor.map = globleManager.map

    mapEditor.selected = nil -- 当前选中的块
    mapEditor.dragOffset = {
        x = 0,
        y = 0
    } -- 拖拽时的相对位移
    mapEditor.dragging = false -- 是否正在拖拽
    mapEditor.dragStartPos = {
        x = 0,
        y = 0
    } -- 拖拽开始时的位置

    -- 创建 UI 组件并注册到 uiManager
    if not uiManager:getUI("mapEditorUI") then
        local ui = MapEditorUI:new(self)
        uiManager:addUI("mapEditorUI", ui)
    end
end

function mapEditor:update(dt)
    for _, it in ipairs(itemManager.items) do
        if it.update then
            it:update(dt)
        end
    end
end

local function floorToPixSize(x)
    return math.floor(x / pixSize) * pixSize
end

function mapEditor:mousepressed(x, y, button)
    local worldX, worldY = cameraManager.cam:toWorld(x, y)
    print("button", x, y, "world", worldX, worldY)
    if button == 1 then -- 左键：选中
        mapEditor.selected = nil
        for _, item in pairs(itemManager.items) do
            if item:isOver(worldX, worldY) then
                if (not mapEditor.selected) or (item.layer > mapEditor.selected.layer) or
                    (item.layer == mapEditor.selected.layer and item.z > mapEditor.selected.z) then
                    mapEditor.selected = item
                end
            end
        end
        -- 记录偏移量，防止选中时瞬移到鼠标位置
        if mapEditor.selected then
            mapEditor.dragOffset.x = mapEditor.selected.x - worldX
            mapEditor.dragOffset.y = mapEditor.selected.y - worldY
            -- 开始拖拽时记录起始位置，用于撤销
            mapEditor.dragging = true
            mapEditor.dragStartPos.x = mapEditor.selected.x
            mapEditor.dragStartPos.y = mapEditor.selected.y
        else
            mapEditor.dragging = false
        end
    elseif button == 2 then
        -- 逻辑层不再直接创建 UI，仅负责记录选中等，UI 层通过右键事件弹出菜单
    end
end

function mapEditor:addItem(type, x, y)
    print("mapEditor:addItem", type, x, y, mapEditor.selected)
    local itemType = type 
    if not itemType or not itemFactory.news[itemType] then
        return
    end
    local newItem = itemFactory:newItem(itemType)
    local px, py = mapManager:getMapGridIndex(x, y)
    newItem:setPos(px, py)
    itemManager:addItem(newItem)

    -- 新建物体时重置拖拽偏移
    mapEditor.dragOffset.x = 0
    mapEditor.dragOffset.y = 0
end

function mapEditor:removeItem(item)
    local target = mapEditor.selected

    -- 记录删除前的信息（类型 + 位置 + 尺寸等）
    local clsName = target.type or target.name -- 你这里真实的类型字段自己调整
    local x, y, z = target.x, target.y, target.z
    local w, h = target.w, target.h
    local layer = target.layer
    local index
    for i = #itemManager.items, 1, -1 do
        if itemManager.items[i] == target then
            index = i
            break
        end
    end

    -- 真正删除
    for i = #itemManager.items, 1, -1 do
        if itemManager.items[i] == item then
            itemManager.items[i]:destroy()
            table.remove(itemManager.items, i)
            break
        end
    end
    if mapEditor.selected == item then
        mapEditor.selected = nil
    end
end


function mapEditor:addWall(x,y,type)
    
end

function mapEditor:removeWall(x,y)
    
end

function mapEditor:addGrid(x,y,type)
    
end

function mapEditor:removeGrid(x,y)
    
end

function mapEditor:mousereleased(x, y, button)
    if button == 1 then
        if (mapEditor.selected) then
            print("item xywh2", mapEditor.selected.x, mapEditor.selected.y, mapEditor.selected.w, mapEditor.selected.h)
        end
        -- 如果本次有拖拽行为且位置发生变化，则记录历史
        if mapEditor.dragging and mapEditor.selected then
            local sx, sy = mapEditor.dragStartPos.x, mapEditor.dragStartPos.y
            local ex, ey = mapEditor.selected.x, mapEditor.selected.y
            if sx ~= ex or sy ~= ey then
                local target = mapEditor.selected
            end
        end
        mapEditor.dragging = false
    end
end

function mapEditor:mousemoved(x, y, dx, dy, istouch)
    local worldX, worldY = cameraManager.cam:toWorld(x, y)
    if mapEditor.selected and love.mouse.isDown(1) then
        local posx = floorToPixSize(worldX + mapEditor.dragOffset.x)
        local posy = floorToPixSize(worldY + mapEditor.dragOffset.y)
        mapEditor.selected:setPos(posx, posy)
    elseif love.mouse.isDown(3) then
        cameraManager.cam:setPosition(cameraManager.cam.x - dx, cameraManager.cam.y - dy)
    end
end

function mapEditor:wheelmoved(dx, dy)

end

function mapEditor:keypressed(key)

    if key == "s" then
        mapManager:saveMap("res/maps/edited.json")
        print("地图已保存到 res/maps/edited.json")
    elseif key == "o" then
        cameraManager.cam:setScale(cameraManager.cam:getScale() - 0.2)
    elseif key == "p" then
        cameraManager.cam:setScale(cameraManager.cam:getScale() + 0.2)
    elseif key == "delete" then
        if mapEditor.selected then
            self:removeItem(mapEditor.selected)
        end
    end
end

function mapEditor:draw()
    -- 这里仅绘制编辑辅助信息：每个 item 的包围框 & 选中高亮
    local lg = love.graphics

    for _, it in ipairs(itemManager.items) do
        if it.getPos and it.getSize then
            local x, y = it:getPos()
            local w, h = it:getSize()
            -- 先将世界坐标转换为屏幕坐标来画框

            if it == mapEditor.selected then
                -- 选中项：高亮颜色，比如黄色
                lg.setColor(1, 1, 0, 1)
            else
                -- 普通项：半透明绿色
                lg.setColor(1, 0, 1, 1)
            end
            -- 注意：item 的 pos 在 item:draw 里是中心点，所以这里也以中心点来画
            lg.rectangle("line", x - w / 2, y - h, w, h)
        end
    end

    -- 画完辅助框后恢复颜色
    lg.setColor(1, 1, 1, 1)
end

function mapEditor:leave()
    -- 结束生命周期时卸载 UI
    local ui = uiManager:getUI("mapEditorUI")
    if ui then
        uiManager:removeUI("mapEditorUI")
    end
end

return mapEditor
