local ItemManager = {
    items = {},
    focusedItem = nil,
    clickItem = nil,
    canInteractItem = nil,
    mouseLeftDown = false,
}

systemManager:update_regester(function(dt)
    ItemManager:update(dt)
end)
systemManager:camdraw_regester(function()
    ItemManager:draw()
end)

--初始化获取item文件夹下的所有编辑好的item
local function loadItemsFromFolder()
    ItemManager.itemnews = {}
    local items = {}

    -- 使用 Love2D 的文件系统
    local files = love.filesystem.getDirectoryItems("src/item")

    for _, filename in ipairs(files) do
        -- 检查是否是 .lua 文件
        if filename:match("%.lua$") then
            local itemname = filename:gsub("%.lua$", "")

            -- 跳过 init.lua 或其他特殊文件
            if itemname ~= "init" and itemname ~= "item" and itemname~="bodyItem" and itemname~="imageItem"then
                table.insert(items, itemname)

                -- 尝试加载模块
                local success, module = pcall(function()
                    return require("src.item." .. itemname)
                end)

                if success and module then
                    ItemManager.itemnews[itemname] = module
                    print("成功加载物品: " .. itemname)
                else
                    print("警告: 无法加载物品 " .. itemname .. ": " .. tostring(module))
                    ItemManager.itemnews[itemname] = nil
                end
            end
        end
    end

    -- 排序并保存物品类型列表
    table.sort(items)
    ItemManager.itemTypes = items

    return ItemManager.itemnews
end

-- 加载物品
loadItemsFromFolder()


-- 注册鼠标事件，用于管理 item 的点击/拖拽/松开交互
mouseManager:mousepressed_regester(function(x, y, button)
    if button ~= 1 then return end
    ItemManager.mouseLeftDown = true
    x, y = cameraManager.cam:toWorld(x, y)
    local clickItem = ItemManager:getFirstItem(x, y)
    if clickItem and ItemManager:isItemInRange(clickItem) then
        ItemManager.focusedItem = clickItem
        ItemManager.clickItem = clickItem
        if clickItem.onClick then
            clickItem:onClick(x, y, button)
        end
    else
        ItemManager.focusedItem = nil
        ItemManager.clickItem = nil
    end
end)

mouseManager:mouseMoved_regester(function(x, y, dx, dy)
    -- 不再用鼠标位置决定 canInteractItem，只处理拖拽/悬停
    local item = ItemManager.focusedItem
    if item and item.interaction and ItemManager:isItemInRange(item) then
        if ItemManager.mouseLeftDown and item.onDrag then
            item.isDrag = true
            item:onDrag(x, y, dx, dy)
        elseif item.onHold then
            item:onHold(x, y)
        end
    end
end)

mouseManager:mouseLeased_regester(function(x, y, button)
    if button ~= 1 then return end
    ItemManager.mouseLeftDown = false
    local item = ItemManager.focusedItem
    if item and item.interaction and ItemManager:isItemInRange(item) then
        if item.isDrag and item.onDragOver then
            item.isDrag = false
            item:onDragOver(x, y)
        elseif item.onClickOver then
            item:onClickOver(x, y)
        end
    end
    ItemManager.focusedItem = nil
    ItemManager.clickItem = nil
end)

function ItemManager:getFirstItem(x, y, ignoreRange)
    -- 找到最后渲染、且带有 interaction=true 的 item
    local clickItem = nil
    for _, item in ipairs(self.items) do
        if item.interaction and item.isOver and item:isOver(x, y) then
            if ignoreRange or self:isItemInRange(item) then
                if not clickItem then
                    clickItem = item
                else
                    local z = item.z or 0
                    local cz = clickItem.z or 0
                    if z >= cz then
                        clickItem = item
                    end
                end
            end
        end
    end
    return clickItem
end

function ItemManager:isItemInRange(item)
    if not playerManager or not playerManager.player then return false end
    local px, py = playerManager.player:getPos()
    local ix, iy = item:getPos()
    local dx, dy = px - ix, py - iy
    local dist2 = dx * dx + dy * dy
    return dist2 <= 100 * 100
end

function ItemManager:addItem(item)
    if item then
        table.insert(self.items, item)
    else
        print("id:" .. id .. " item exsit !")
    end
end

function ItemManager:removeItem(id)
    local index = 0
    for i, v in ipairs(self.items) do
        if v.id == id then
            index = i
        end
    end
    table.remove(self.items, index)
end

function ItemManager:removeAll()
    for i = #self.items, 1, -1 do
        self.items[i]:destroy()
        table.remove(self.items, i)
    end
end

function ItemManager:update(dt)
    -- 先正常更新
    for _, v in pairs(self.items) do
        if v.update then
            v:update(dt)
        end
    end

    -- 重新计算当前最近且在 100 范围内的交互 item
    ItemManager.canInteractItem = nil
    if playerManager and playerManager.player then
        local bestItem = nil
        local bestDist2 = 100 * 100
        local px, py = playerManager.player:getPos()
        for _, v in ipairs(self.items) do
            if v.interaction then
                local ix, iy = v:getPos()
                local dx, dy = px - ix, py - iy
                local dist2 = dx * dx + dy * dy
                if dist2 <= bestDist2 then
                    if not bestItem then
                        bestItem = v
                        bestDist2 = dist2
                    else
                        local z = v.z or 0
                        local cz = bestItem.z or 0
                        if z >= cz then
                            bestItem = v
                            bestDist2 = dist2
                        end
                    end
                end
            end
        end
        ItemManager.canInteractItem = bestItem
    end
end

function ItemManager:draw()
    for i, v in ipairs(self.items) do
        if v.draw then
            v:draw()
        end
        -- 在可交互 item 右上角画 info 图标（只根据距离和 interaction）
        if v == self.canInteractItem and v.interaction and self:isItemInRange(v) then
            if not self.infoImage then
                self.infoImage = resourceManager.loadImage("res/image/info.png")
            end
            local x, y = v:getPos()
            local w, h = v:getSize()
            local iw, ih = self.infoImage:getWidth() * pixSize
            , self.infoImage:getHeight() * pixSize
            local drawX = x + w - iw / 2
            local drawY = y - h / 2 - ih
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(self.infoImage, drawX, drawY, 0, pixSize, pixSize)
        end
    end
end

return ItemManager
