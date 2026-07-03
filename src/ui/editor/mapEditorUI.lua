local ui = require "src.ui.ui"
local MapEditorUI = ui:extend()

function MapEditorUI:init(editor)

    self.itemFactory = mapManager.itemFactory
    self.gridFactory = mapManager.gridFactory
    -- editor 是逻辑层的 mapEditor（src/map/mapEditor.lua）
    self.editor = editor
    self:refresh()
end

function MapEditorUI:refresh()
    self:clearStacks()
    -- 这里只需要创建一次右键菜单窗口，实际显示/隐藏由 _open/_close 控制
    self:_ensureEditorUIState()
end

-- 左上角/底部文字提示仍然用 love.graphics 直接画
function MapEditorUI:draw()
    self:drawStacks()

    if not self.editor then
        return
    end

    local width, height = love.graphics.getDimensions()

    love.graphics.setColor(1, 0, 0, 0.9)

    love.graphics.setFont(smallFont)
    love.graphics.print(
        "左键：添加/创建菜单  右键：删除   S：保存  OP：摄像机缩放  I：设置出身点", 6,
        height - 30)
    love.graphics.setFont(myFont)

    love.graphics.setColor(1, 1, 1, 1)
end

-- ---------- 右键菜单状态 ----------

-- 搭建笔刷选择单选框
function MapEditorUI:_buildBrushMenuStack()

    -- 清理之前的笔刷选择界面
    if self.BrushMenuStack then
        self:removeStack(self.BrushMenuStack)
        self.BrushMenuStack = nil
    end

    local burshRadioButtons = Glove.RadioButtons:new({{
        label = "物体",
        value = "item"
    }, {
        label = "地板",
        value = "grid"
    }}, function(value)
        self:_setBrush(value)
    end)
    local stack = Glove.VStack:new({burshRadioButtons}, 10)
    stack:setPos(100, 0, self.z)
    self.BrushMenuStack = stack
    self:addStack(stack)
end

-- 详细的笔刷选择界面，包含所有 item 类型的按钮
function MapEditorUI:_setBrush(value)

    self.editor.brush = value

    -- 清理之前的笔刷选择界面
    if self._brushSelectStack then
        self:removeStack(self._brushSelectStack)
        self._brushSelectStack = nil
    end
    print("选择笔刷类型：", value)
    if value == "item" then
        local burshTable = {}
        for _, itemType in ipairs(self.itemFactory.types) do
            table.insert(burshTable, {
                label = itemType,
                value = itemType
            })
        end
        local burshRadioButtons = Glove.RadioButtons:new(burshTable, function(value)
            self.editor.selectItemBrushType = value
            print("当前物体笔刷：", value)
        end)
        local stack = Glove.VStack:new({burshRadioButtons}, 10)
        stack:setPos(200, 0, self.z)
        self._brushSelectStack = stack
        self:addStack(stack)
        print("当前笔刷：物体")
    elseif value == "grid" then
        local burshTable = {}
        for _, gridType in ipairs(self.gridFactory.types) do
            table.insert(burshTable, {
                label = gridType,
                value = gridType
            })
        end
        local burshRadioButtons = Glove.RadioButtons:new(burshTable, function(value)
            self.editor.selectGridBrushType = value
            print("当前地板笔刷：", value)
        end)
        local stack = Glove.VStack:new({burshRadioButtons}, 10)
        stack:setPos(200, 0, self.z)
        self._brushSelectStack = stack
        self:addStack(stack)
        print("当前笔刷：地板")
    end
end

function MapEditorUI:_ensureEditorUIState()
    -- 记录最近一次右键时是否点在选中对象上
    self._ctxMenu = self._ctxMenu or {
        open = false,
        x = 0,
        y = 0,
        onSelected = false
    }
end

function MapEditorUI:_openBrushMenu()
    self._brushIsOpen = true
    if not self.BrushMenuStack then
        self:_buildBrushMenuStack()
    end
    self:_buildBrushMenuStack()
end

function MapEditorUI:_closeBrushMenu()
    self._brushIsOpen = false
    self.editor.brush = ""
    if self._brushSelectStack then
        self:removeStack(self._brushSelectStack)
        self._brushSelectStack = nil
    end
    if self.BrushMenuStack then
        self:removeStack(self.BrushMenuStack)
        self.BrushMenuStack = nil
    end
    self:_ensureEditorUIState()
end

-- UI 接管鼠标事件（由 uiManager 分发）
function MapEditorUI:onClick(x, y, button)

    if button == 1 then
        local screenX, screenY = x, y
        local indexx, indexy = mapManager:toGridIndex(cameraManager.cam:toWorld(screenX, screenY))
        if (indexx and indexy) then
            if not self._brushIsOpen then
                self:_openBrushMenu()
            end
        else
            if self._brushIsOpen then
                local w = Glove.getFirstWidget(x, y) -- 检测点击位置是否在菜单上
                if w then
                    return
                end
                print("右键点击地图外部，关闭菜单")
                self:_closeBrushMenu()
            end
        end
    elseif button == 2 then

    end
end

-- 当右键菜单打开时，用滚轮滚动菜单
function MapEditorUI:wheelmoved(x, y)

end

return MapEditorUI
