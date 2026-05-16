-- src/main_editor.lua
local Item = require "src.item.item"
local MapEditorUI = require "src.ui.editor.mapEditorUI"

local itemFactory = require "src.map.itemFactory"
local gridFactory = require "src.map.gridFactory"

local mapEditor = {
    brushOpen = false, -- 是否打开右键菜单
    brushSize = 1, -- 画笔大小，默认为1格
    brush = "", -- item or grid
    selectItemBrushType = "",
    selectGridBrushType = ""
}

local history = {}

systemManager:mousepressed_regester(function(x, y, button)
    mapEditor:onClick(x, y, button)
end)
systemManager:mouseMoved_regester(function(x, y, dx, dy)
    mapEditor:mouseMoved(x, y, dx, dy)
end)
systemManager:mouseLeased_regester(function(x, y, button)
    mapEditor:onClickOver(x, y, button)
end)
systemManager:wheelMoved_regester(function(x, y)
    mapEditor:wheelMoved(x, y)
end)
systemManager:keypressed_regester(function(key)
    mapEditor:keyPressed(key)
end)

function mapEditor:init()
    print("开始地图编辑")

    mapManager:loadMap("res/maps/edited.json")

    -- keep a direct reference for convenience

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



-- 画笔触碰事件，参数是格子坐标和鼠标按钮
function mapEditor:brushTouch(indexx, indexy, mouseButton)
    if mapEditor.brush == "item" then

        if mouseButton == 1 and self.selectItemBrushType ~= "" then -- 左键添加，右键删除\
            local item = mapManager:getMapItem(indexx, indexy)
            if item then
                return
            end
            mapManager:addItem(self.selectItemBrushType, indexx, indexy)
        elseif mouseButton == 2 then
            mapManager:removeItem(indexx, indexy)
        end
    elseif mapEditor.brush == "grid" then

        if mouseButton == 1 and self.selectGridBrushType ~= "" then -- 左键添加，右键删除
            local grid = mapManager:getMapGrid(indexx, indexy)
            if grid then
                return
            end
            mapManager:addGrid(self.selectGridBrushType, indexx, indexy)
        elseif mouseButton == 2 then
            mapManager:removeGrid(indexx, indexy)
        end
    end
end

function mapEditor:onClickOver(x, y, button)
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

function mapEditor:onClick(x, y, button)
    local worldX, worldY = cameraManager.cam:toWorld(x, y)
    if button == 1 then -- 左键：选中
        mapEditor.selected = nil
        -- for _, item in pairs(itemManager.items) do
        --     if item:isOver(worldX, worldY) then
        --         if (not mapEditor.selected) or (item.layer > mapEditor.selected.layer) or
        --             (item.layer == mapEditor.selected.layer and item.z > mapEditor.selected.z) then
        --             mapEditor.selected = item
        --         end
        --     end
        -- end

        if mapEditor.brush ~= "" then
            local indexx, indexy = mapManager:toGridIndex(worldX, worldY)
            if indexx and indexy then
                mapEditor:brushTouch(indexx, indexy, 1)
            end
        end
    elseif button == 2 then
        if mapEditor.brush ~= "" then
            local indexx, indexy = mapManager:toGridIndex(worldX, worldY)
            if indexx and indexy then
                mapEditor:brushTouch(indexx, indexy, 2)
            end
        end
    end

end

function mapEditor:mouseMoved(x, y, dx, dy, istouch)
    local worldX, worldY = cameraManager.cam:toWorld(x, y)

    if love.mouse.isDown(1) then -- 右键选中物体
        if mapEditor.brush ~= "" then
            local indexx, indexy = mapManager:toGridIndex(worldX, worldY)
            if indexx and indexy then
                mapEditor:brushTouch(indexx, indexy, 1)
            end
        end
    elseif love.mouse.isDown(2) then -- 画笔拖拽
        if mapEditor.brush ~= "" then
            local indexx, indexy = mapManager:toGridIndex(worldX, worldY)
            if indexx and indexy then
                mapEditor:brushTouch(indexx, indexy, 2)
            end
        end
    elseif love.mouse.isDown(3) then
        cameraManager.cam:setPosition(cameraManager.cam.x - dx, cameraManager.cam.y - dy)
    end
end

function mapEditor:wheelMoved(dx, dy)

end

function mapEditor:keyPressed(key)

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

-- 绘制物体中心点
function mapEditor:printItemCenter()
    love.graphics.setColor(1, 0, 0)
    for _, item in ipairs(itemManager.items) do
        if item.getPos then
            local x, y = item:getPos()
            drawArrow(x, y, x + 50, y, 1, 0, 0) -- 示例箭头，实际参数根据需求调整
            drawArrow(x, y, x, y - 50, 1, 0, 0) -- 示例箭头，实际参数根据需求调整
            love.graphics.circle("fill", x, y, 3)
        end
    end
end

function mapEditor:draw()

    love.graphics.setLineWidth(2)
    -- 这里仅绘制编辑辅助信息：每个 item 的包围框 & 选中高亮
    local lg = love.graphics

    -- 绘制所有 item 的包围框，选中项高亮
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

    -- 绘制网格线
    lg.setColor(1, 1, 1, 1)
    -- 绘制grid网格线,在世界空间下
    local cam = cameraManager.cam
    local x, y = cam:toScreen(0, 0)
    local sizeS = mapManager.map.gridSize

    for g_x = 0, mapManager.map.size.width do
        for g_y = 0, mapManager.map.size.height do
            local posx, posy = g_x * mapManager.map.gridSize, g_y * mapManager.map.gridSize
            -- print("网格线坐标：", posx, posy, "格子坐标：", g_x, g_y)
            lg.rectangle("line", posx, posy, sizeS, sizeS)
        end
    end

    -- 世界坐标中线
    lg.setColor(1, 0, 0, 1)
    local cam = cameraManager.cam
    local screenW, screenH = love.graphics.getDimensions()
    local worldLeft, worldTop = cam:toWorld(0, 0)
    local worldRight, worldBottom = cam:toWorld(screenW, screenH)
    -- 绘制世界坐标系的 X 和 Y 轴
    lg.line(worldLeft, 0, worldRight, 0) -- X 轴
    lg.line(0, worldTop, 0, worldBottom) -- Y 轴

    -- 绘制物体中心点
    mapEditor:printItemCenter()
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
