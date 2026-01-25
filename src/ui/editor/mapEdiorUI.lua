local ui = require "src.ui.ui"

local mapManager = mapManager
local itemTypes = mapManager.itemTypes
local itemnews = mapManager.itemnews

local MapEditorUI = ui:extend()

function MapEditorUI:init(editor)
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

    if not self.editor then return end

    local width, height = love.graphics.getDimensions()

    love.graphics.setColor(1, 0, 0, 0.9)
    love.graphics.print("创建 : " .. (itemTypes[self.editor.ItemIndex or 1] or ""), 10, 10)
    love.graphics.print("操作: 右键=菜单  左键=选择/关闭菜单  滚轮=切换创建物  S=保存  Delete=删除选中", 10, 28)
    love.graphics.setColor(1, 1, 1, 1)

    love.graphics.setColor(1, 0, 0, 0.9)
    love.graphics.print("左键：选中  右键：创建/菜单  滚轮：切换  S：保存  Delete：删除选中块", 10, height - 30)
    love.graphics.setColor(1, 1, 1, 1)
end

-- ---------- 右键菜单状态 ----------
function MapEditorUI:_ensureEditorUIState()
    -- 记录最近一次右键时是否点在选中对象上
    self._ctxMenu = self._ctxMenu or { open = false, x = 0, y = 0, onSelected = false }
end

function MapEditorUI:_closeContextMenu()
    self:_ensureEditorUIState()
    if self._ctxMenuWindow then
        self:removeStack(self._ctxMenuWindow)
        self._ctxMenuWindow = nil
    end
    self._ctxMenu.open = false
    self._ctxMenu.onSelected = false
end

-- 根据 mapManager.itemnews 里的类型生成菜单按钮
local function buildCreateButtons(self, win)

    for _, t in ipairs(itemTypes) do
        if itemnews[t] then
            local btn = Glove.Button:new("创建: " .. tostring(t), function()
                if self.editor and self.editor.addItem then
                    -- 使用当前鼠标位置创建
                    local mx, my = love.mouse.getPosition()
                    local worldX, worldY = cameraManager.cam:toWorld(mx, my)
                    self.editor:addItem(t, worldX, worldY)
                end
                self:_closeContextMenu()
            end)
            btn:setSize(0,0)
            win:addChild(btn)
        end
    end

end

local function isRightClickOnSelected(editor, screenX, screenY)
    if not (editor and editor.selected and editor.selected.isOver) then
        return false
    end
    local worldX, worldY = cameraManager.cam:toWorld(screenX, screenY)
    return editor.selected:isOver(worldX, worldY)
end

function MapEditorUI:_openContextMenu(screenX, screenY)
    if not self.editor then return end

    self:_ensureEditorUIState()
    -- 判断这次右键是否点在当前选中对象上
    self._ctxMenu.onSelected = isRightClickOnSelected(self.editor, screenX, screenY)
    self._ctxMenu.x, self._ctxMenu.y = screenX, screenY

    -- rebuild window
    self:_closeContextMenu()
    self:_ensureEditorUIState()
    self._ctxMenu.onSelected = isRightClickOnSelected(self.editor, screenX, screenY)
    self._ctxMenu.x, self._ctxMenu.y = screenX, screenY

    local title = self.editor.selected and "对象操作" or "地图操作"
    local VS = Glove.VStack:new({},0)

    local padX, padY = 10, 10
    local curY = padY

    if self._ctxMenu.onSelected then
        -- 只有在右键点在已选中的对象上时，才显示“删除对象”
        local delBtn = Glove.Button:new("删除对象", function()
            if self.editor and self.editor.selected then
                self.editor:removeItem(self.editor.selected)
            end
            self:_closeContextMenu()
        end)
        VS:addChild(delBtn)
        delBtn:setSize(0,0)
        VS:layout()
    else
        -- 地图操作：根据所有 itemTypes 生成“创建对象”按钮
        buildCreateButtons(self, VS)

        local saveBtn = Glove.Button:new("保存地图", function()
            mapManager:saveMap("res/maps/edited.json")
            self:_closeContextMenu()
        end)
        saveBtn:setSize(0,0)
        VS:addChild(saveBtn)
        VS:layout()
    end

    -- 创建一个可滚动容器包裹菜单
    local screenW, screenH = love.graphics.getDimensions()
    local maxHeight = screenH * 0.6

    local contentHeight = curY + padY
    local viewHeight = math.min(contentHeight, maxHeight)

    local scrollContainer = Glove.ScrollArea and Glove.ScrollArea:new({ content = VS, width = 220, height = viewHeight }) or VS

    if scrollContainer ~= VS then
        -- 如果有 ScrollArea 组件，则使用它来包装 VS
        scrollContainer:setPos(self._ctxMenu.x, self._ctxMenu.y, (self.z or 0) + 100)
        scrollContainer:setContent(VS)
        self._ctxMenuWindow = scrollContainer
    else
        -- 否则退回到原来的行为
        VS:setPos(self._ctxMenu.x, self._ctxMenu.y, (self.z or 0) + 100)
        self._ctxMenuWindow = VS
    end

    self:addStack(self._ctxMenuWindow)
    self._ctxMenu.open = true
end

-- UI 接管鼠标事件（由 uiManager 分发）
function MapEditorUI:mousePressed(x, y, button)
    if button == 2 then
        -- 右键总是打开/重建菜单
        self:_openContextMenu(x, y)
    elseif button == 1 then
        -- 左键：只有在点到菜单外面时才关闭菜单
        if self._ctxMenuWindow and self._ctxMenu and self._ctxMenu.open then
            if self._ctxMenuWindow.hitTest then
                -- 如果 Glove 控件有 hitTest，优先使用
                if not self._ctxMenuWindow:hitTest(x, y) then
                    self:_closeContextMenu()
                end
            else
                -- 简单的矩形包围盒检测
                local wx, wy = self._ctxMenu.x, self._ctxMenu.y
                local ww = self._ctxMenuWindow.w or self._ctxMenuWindow.width or 220
                local wh = self._ctxMenuWindow.h or self._ctxMenuWindow.height or 200
                if x < wx or x > wx + ww or y < wy or y > wy + wh then
                    self:_closeContextMenu()
                end
            end
        end
    end
end

-- 当右键菜单打开时，用滚轮滚动菜单
function MapEditorUI:wheelmoved(x, y)
    if not (self._ctxMenu and self._ctxMenu.open and self._ctxMenuWindow) then return end

    -- 如果使用的是 ScrollArea 组件，优先调用它的滚动接口
    if self._ctxMenuWindow.scrollBy then
        self._ctxMenuWindow:scrollBy(0, y * 20)
        return
    end

    -- 简单回退：直接移动整个菜单窗口的位置
    local wx, wy, wz = self._ctxMenuWindow:getPos()
    self._ctxMenuWindow:setPos(wx, wy + y * 20, wz)
end

function MapEditorUI:mouseLeased(x, y, button)
    -- 预留
end

return MapEditorUI