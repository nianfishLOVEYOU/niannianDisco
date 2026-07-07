-- 管理ui页面对象
local uiManager = {
    uiTable = {},
    nextOrder = 0
}
local uipath = "src.ui." -- 以后自动require用

local function sortUIList(uiTable)
    -- 功能：按 ui.z 从大到小排序
    -- 规则：z 相同的元素，保持原来的顺序，绝不交换！
    for i = #uiTable, 1, -1 do
        local maxIndex = i

        -- 找出 i 之前最大的 z（只比大小，相等不换）
        for j = i - 1, 1, -1 do
            local zj = uiTable[j].ui.z or 0
            local zmax = uiTable[maxIndex].ui.z or 0

            -- 只有 z 更大时才更新 maxIndex
            -- z 相等时，不换！保持原来顺序
            if zj > zmax then
                maxIndex = j
            end
        end

        -- 【核心】不是交换！是把最大的元素移到 i 位置，前面顺次后移
        if maxIndex ~= i then
            -- 取出最大元素
            local maxItem = uiTable[maxIndex]

            -- maxIndex 后面的元素 全部向后挪一位（顺序不变）
            for j = maxIndex, i - 1 do
                uiTable[j] = uiTable[j + 1]
            end

            -- 把最大元素放到最后（i 位置）
            uiTable[i] = maxItem
        end
    end
end

systemManager:update_regester(function(dt)
    uiManager:update(dt)
end)
systemManager:draw_regester(function()
    uiManager:draw()
end)

systemManager:mouseLeased_regester(function(x, y, button)
    uiManager:onClickOver(x, y, button)
end)
systemManager:mouseMoved_regester(function(x, y, dx, dy)
    uiManager:mouseMoved(x, y, dx, dy)
end)
systemManager:mousepressed_regester(function(x, y, button)
    uiManager:onClick(x, y, button)
end)
systemManager:wheelMoved_regester(function(x, y)
    uiManager:wheelmoved(x, y)
end)

systemManager:quit_regester(function()
    uiManager:destroy()
end)

function uiManager:visiable(name, visiable)
    local ui = self:getUI(name)
    if (ui) then
        ui.options.visiable = visiable
    end
end

-- 排序
function uiManager:addUI(name, ui)
    if (not self:getUI(name)) then
        self.nextOrder = self.nextOrder + 1
        local instance = {
            name = name,
            ui = ui,
            order = self.nextOrder
        }
        table.insert(self.uiTable, instance)
        if ui.z == nil then
            ui.z = instance.order
        end
        sortUIList(self.uiTable)
        print("[add ui] ", name)
    else
        print("!  ui is have !", name)
        -- replaceUI(name,ui)
    end
end

function uiManager:getUI(name)
    -- print("uiManager:getUI",#self.uiTable)
    for i, v in ipairs(self.uiTable) do
        if v.name == name then
            return v.ui
        end
    end
    return nil
end

function uiManager:removeUI(name)
    local removeIndex = -1
    for i, v in ipairs(self.uiTable) do
        if v.name == name then
            removeIndex = i
        end
    end
    if removeIndex ~= -1 then
        self.uiTable[removeIndex].ui:destroy()
        table.remove(self.uiTable, removeIndex)
        print("remove ui ", name)
    else
        print("uimanager no : ", name)
    end
end

function uiManager:removeAll()
    for i, v in ipairs(self.uiTable) do
        v.ui:destroy()
    end
    self.uiTable = {}
    
end

function uiManager:refresh(name)
    for i, v in ipairs(self.uiTable) do
        if v.name == name and v.ui:getRealVisiable() then
            v.ui:refresh()
        end
    end
end

function uiManager:update(dt)
    for k, v in pairs(self.uiTable) do
        if v.ui.update and v.ui:getRealVisiable() then
            v.ui:update(dt)
        end
    end
end

function uiManager:draw()
    sortUIList(self.uiTable)
    for i, v in ipairs(self.uiTable) do
        if v.ui:getRealVisiable() then
            v.ui:draw()
        end
    end
end

function uiManager:onClickOver(x, y, button)
    for i, v in ipairs(self.uiTable) do
        if v.ui:getRealVisiable() then
            v.ui:onClickOver(x, y, button)
        end
    end
end

function uiManager:onClick(x, y, button)
    for i, v in ipairs(self.uiTable) do
        if v.ui:getRealVisiable() then
            v.ui:onClick(x, y, button)
        end
    end
end

function uiManager:mouseMoved(x, y, dx, dy)
    for i, v in ipairs(self.uiTable) do
        if v.ui:getRealVisiable() then
            v.ui:mouseMoved(x, y, dx, dy)
        end
    end
end

function uiManager:wheelmoved(x, y)
    for i, v in ipairs(self.uiTable) do
        if v.ui:getRealVisiable() then
            v.ui:wheelmoved(x, y)
        end
    end
end

function uiManager:destroy()
    self:removeAll()
end

return uiManager
