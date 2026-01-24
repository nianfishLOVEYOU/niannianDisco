-- src/main_editor.lua
local Item = require "src.item.item"
local MapEditorUI = require "src.ui.editor.mapEdiorUI"
local historyManager = require "src.manager.historyManager"

local mapEditor = {}
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

local itemTypes = mapManager.itemTypes
local itemnews = mapManager.itemnews

mapEditor.ItemIndex = 1

function mapEditor:init()
    print("开始地图编辑")

    for _, module in ipairs(itemTypes) do
        itemnews[module] = require("src.item." .. module)
    end

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
    local cls = itemnews[type] or itemnews[itemTypes[self.ItemIndex]]
    if not cls then
        return
    end
    local newItem = cls:new()
    local px = floorToPixSize(x)
    local py = floorToPixSize(x)
    newItem:setPos(px, py)
    -- newItem:setSize(64, 64)
    itemManager:addItem(newItem)

    -- 记录历史：创建
    historyManager:push({
        type = "create",
        item = newItem,
        undo = function(self)
            print("undo create item")
            if not self.item then
                return
            end
            for i = #itemManager.items, 1, -1 do
                if itemManager.items[i] == self.item then
                    itemManager.items[i]:destroy()
                    table.remove(itemManager.items, i)
                    break
                end
            end
            if mapEditor.selected == self.item then
                mapEditor.selected = nil
            end
        end
    })

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

    historyManager:push({
        type = "delete",
        snapshot = {
            clsName = clsName,
            x = x,
            y = y,
            z = z,
            w = w,
            h = h,
            layer = layer,
            index = index
        },
        undo = function(self)
            print("undo delete item")
            local s = self.snapshot
            if not s or not s.clsName then
                return
            end

            -- 找到对应类
            local cls = itemnews[s.clsName]
            if not cls then
                print("undo error : class not found ", s.clsName)
                return
            end

            local newItem = cls:new()
            -- 还原基础属性
            newItem:setPos(s.x, s.y, s.z)
            newItem:setSize(s.w, s.h)
            newItem.layer = s.layer or newItem.layer

            -- 按原来索引插回去
            itemManager:addItem(newItem)
        end
    })


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
                historyManager:push({
                    type = "move",
                    item = target,
                    from = {
                        x = sx,
                        y = sy
                    },
                    to = {
                        x = ex,
                        y = ey
                    },
                    undo = function(self)
                        if not (self.item and self.item.setPos) then
                            return
                        end
                        self.item:setPos(self.from.x, self.from.y)
                        if mapEditor.selected == self.item then
                            -- 同步编辑器内状态
                            mapEditor.dragOffset.x = 0
                            mapEditor.dragOffset.y = 0
                        end
                    end
                })
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
    if mapEditor.selected then
        return
    end
    if dy > 0 then
        self.ItemIndex = self.ItemIndex - 1
        if self.ItemIndex < 1 then
            self.ItemIndex = #itemTypes
        end
    elseif dy < 0 then
        self.ItemIndex = (self.ItemIndex % #itemTypes) + 1
    end
    print("ItemIndex : " .. self.ItemIndex)
end

function mapEditor:keypressed(key)
    -- 尺寸修改暂不进历史
    if mapEditor.selected then
        if key == "=" then
            mapEditor.selected.h = mapEditor.selected.h + pixSize * 2
        elseif key == "-" then
            mapEditor.selected.h = mapEditor.selected.h - pixSize * 2
        elseif key == "]" then
            mapEditor.selected.w = mapEditor.selected.w + pixSize * 2
        elseif key == "[" then
            mapEditor.selected.w = mapEditor.selected.w - pixSize * 2
        end
    end

    -- Ctrl+Z 撤销
    if key == "z" and (love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")) then
        historyManager:undo()
        return
    end

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
