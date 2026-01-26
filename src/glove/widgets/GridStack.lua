local fun = require "src.glove.fun"
local widget = require "src.glove.widgets.widget"

-- Grid 网格布局容器
local Grid = widget:extend()

function Grid:init(childrenTB, options)
    self.type = "Grid"
    
    -- 默认选项
    self.options = options or {}
    self.columns = self.options.columns or 2
    self.rows = self.options.rows or nil
    self.hGap = self.options.hGap or 10
    self.vGap = self.options.vGap or 10
    self.align = self.options.align or "left"  -- 水平对齐: left, center, right
    self.valign = self.options.valign or "top" -- 垂直对齐: top, center, bottom
    self.fillMode = self.options.fillMode or "even" -- 填充模式: even(等宽等高), auto(自动)
    
    self.w = 0
    self.h = 0
    
    self.cellWidth = 0
    self.cellHeight = 0
    
    -- 添加子组件
    for i, child in ipairs(childrenTB or {}) do
        self:addChild(child)
    end
    
    self:layout()
end

function Grid:draw()
    self:localPosRefresh()
    for _, child in ipairs(self.children) do
        child:draw()
    end
end

function Grid:setSize(w, h)
    self.w = w
    self.h = h
    self:layout()
end

function Grid:getSize()
    return self.w, self.h
end

-- 计算网格参数
function Grid:calculateGrid()
    local children = self.children
    local count = #children
    
    if count == 0 then
        return 0, 0, 0, 0, {}
    end
    
    local columns = self.columns
    local rows = self.rows
    
    -- 如果指定了行数，计算列数
    if rows and not columns then
        columns = math.ceil(count / rows)
    -- 如果指定了列数，计算行数
    elseif columns and not rows then
        rows = math.ceil(count / columns)
    -- 如果都没指定，使用默认列数
    else
        rows = rows or math.ceil(count / columns)
    end
    
    -- 计算单元格尺寸
    local cellWidth, cellHeight = 0, 0
    
    if self.fillMode == "even" then
        -- 等宽等高模式：找到最大宽度和高度
        for _, child in ipairs(children) do
            local cw, ch = child:getSize()
            cellWidth = math.max(cellWidth, cw or 0)
            cellHeight = math.max(cellHeight, ch or 0)
        end
    else
        -- 自动模式：使用容器尺寸计算
        if self.w > 0 and self.h > 0 then
            cellWidth = (self.w - (columns - 1) * self.hGap) / columns
            cellHeight = (self.h - (rows - 1) * self.vGap) / rows
        else
            -- 如果容器没有尺寸，回退到 even 模式
            for _, child in ipairs(children) do
                local cw, ch = child:getSize()
                cellWidth = math.max(cellWidth, cw or 0)
                cellHeight = math.max(cellHeight, ch or 0)
            end
        end
    end
    
    self.cellWidth = cellWidth
    self.cellHeight = cellHeight
    
    -- 计算容器尺寸
    local gridWidth = columns * cellWidth + (columns - 1) * self.hGap
    local gridHeight = rows * cellHeight + (rows - 1) * self.vGap
    
    if self.w == 0 then
        self.w = gridWidth
    end
    if self.h == 0 then
        self.h = gridHeight
    end
    
    return columns, rows, cellWidth, cellHeight, {gridWidth, gridHeight}
end

-- 布局方法
function Grid:layout()
    local children = self.children
    if #children == 0 then
        self.w = 0
        self.h = 0
        return
    end
    
    -- 重新布局子组件
    for _, child in ipairs(children) do
        if child.type == "VStack" or child.type == "HStack" or child.type == "Grid" then
            child:layout()
        end
    end
    
    local columns, rows, cellWidth, cellHeight, gridSize = self:calculateGrid()
    local gridWidth, gridHeight = gridSize[1], gridSize[2]
    
    -- 计算对齐偏移
    local offsetX, offsetY = 0, 0
    
    if self.align == "center" then
        offsetX = (self.w - gridWidth) / 2
    elseif self.align == "right" then
        offsetX = self.w - gridWidth
    end
    
    if self.valign == "center" then
        offsetY = (self.h - gridHeight) / 2
    elseif self.valign == "bottom" then
        offsetY = self.h - gridHeight
    end
    
    -- 布置子组件
    for i, child in ipairs(children) do
        local row = math.floor((i - 1) / columns)
        local col = (i - 1) % columns
        
        if row < rows then
            local x = offsetX + col * (cellWidth + self.hGap)
            local y = offsetY + row * (cellHeight + self.vGap)
            
            -- 计算组件在单元格内的位置
            local cw, ch = child:getSize()
            local childX, childY = x, y
            
            if self.fillMode == "even" then
                -- 在单元格内居中
                childX = x + (cellWidth - (cw or 0)) / 2
                childY = y + (cellHeight - (ch or 0)) / 2
            end
            
            child:setLocalPos(childX, childY)
            
            -- 如果 fillMode 是 auto 且容器有尺寸，设置子组件大小
            if self.fillMode == "auto" and cellWidth > 0 and cellHeight > 0 then
                if child.setSize then
                    child:setSize(cellWidth, cellHeight)
                end
            end
        end
    end
    
    -- 更新容器尺寸
    if self.w == 0 then
        self.w = gridWidth
    end
    if self.h == 0 then
        self.h = gridHeight
    end
end

-- 添加子组件
function Grid:addChild(child)
    widget.super.addChild(self, child)
    self:layout()
    return self
end

-- 移除子组件
function Grid:removeChild(child)
    local result = widget.super.removeChild(self, child)
    if result then
        self:layout()
    end
    return result
end

-- 设置列数
function Grid:setColumns(columns)
    self.columns = columns
    self.rows = nil
    self:layout()
    return self
end

-- 设置行数
function Grid:setRows(rows)
    self.rows = rows
    self.columns = nil
    self:layout()
    return self
end

-- 设置水平和垂直间距
function Grid:setGap(hGap, vGap)
    self.hGap = hGap or self.hGap
    self.vGap = vGap or self.vGap
    self:layout()
    return self
end

-- 设置对齐方式
function Grid:setAlign(align, valign)
    self.align = align or self.align
    self.valign = valign or self.valign
    self:layout()
    return self
end

-- 设置填充模式
function Grid:setFillMode(fillMode)
    self.fillMode = fillMode
    self:layout()
    return self
end

-- 设置位置
function Grid:setLocalPos(x, y, z)
    Grid.super.setLocalPos(self, x, y, z)
    self:layout()
    return self
end

function Grid:setPos(x, y, z)
    Grid.super.setPos(self, x, y, z)
    self:layout()
    return self
end

-- 获取单元格数量
function Grid:getCellCount()
    return #self.children
end

-- 获取网格信息
function Grid:getGridInfo()
    local columns, rows = self.columns, self.rows
    local count = #self.children
    
    if not rows then
        rows = math.ceil(count / columns)
    elseif not columns then
        columns = math.ceil(count / rows)
    end
    
    return {
        columns = columns,
        rows = rows,
        cellCount = count,
        cellWidth = self.cellWidth,
        cellHeight = self.cellHeight,
        hGap = self.hGap,
        vGap = self.vGap,
        align = self.align,
        valign = self.valign,
        fillMode = self.fillMode
    }
end

return Grid