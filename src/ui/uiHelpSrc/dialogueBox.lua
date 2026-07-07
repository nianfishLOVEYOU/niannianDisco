-- dialogueBox.lua - 漫画风格对话框模块
local DialogueBox = {}
DialogueBox.__index = DialogueBox

-- 默认样式配置
local defaultConfig = {
    bgColor = {1, 1, 1, 1},       -- 背景色（白色）
    borderColor = {0, 0, 0, 1},   -- 边框色（黑色）
    textColor = {0, 0, 0, 1},     -- 文字颜色
    borderRadius = 10,            -- 圆角半径
    borderWidth = 1,              -- 边框宽度
    padding = 10,                 -- 内边距
    tailSize = 8,                -- 尾巴大小
    maxWidth = 100                -- 最大宽度
}

local function clamp(value, minValue, maxValue)
    if value < minValue then
        return minValue
    end
    if value > maxValue then
        return maxValue
    end
    return value
end

-- 创建新的对话框实例
function DialogueBox:new(text, x, y, targetX, targetY, config)
    local self = setmetatable({}, DialogueBox)
    
    -- 合并配置
    config=config or {}
    self.config = {}
    for k, v in pairs(defaultConfig) do
        self.config[k] = config and config[k] or v
    end
    
    -- 基础属性
    self.text = text or ""
    self.x = x or 100
    self.y = y or 100
    self.targetX = targetX or self.x + 50
    self.targetY = targetY or self.y + 80
    
    
    return self
end

-- LÖVE 没有 beginPath/closePath 这类路径 API，直接用原生圆角矩形接口绘制。
local function drawRoundedRect(mode, x, y, w, h, r)
    love.graphics.rectangle(mode, x, y, w, h, r, r)
end

-- 绘制对话框
function DialogueBox:draw()
    local font = myFont or love.graphics.getFont()
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    local margin = 8
    local padding = self.config.padding

    -- 气泡宽度不能超过屏幕可用宽度，避免文字或背景超出屏幕
    local maxTextWidth = math.max(1, math.min(self.config.maxWidth, screenW - margin * 2 - padding * 2))

    -- 按最大宽度换行并计算实际文本块尺寸
    local _, wrappedLines = font:getWrap(self.text or "", maxTextWidth)
    local lineCount = math.max(#wrappedLines, 1)
    local textH = lineCount * font:getHeight()
    
    -- 对话框固定宽度；高度随行数增长
    local boxW = maxTextWidth + 2 * self.config.padding
    local boxH = textH + 2 * self.config.padding
    -- self.y 作为气泡底边，文本增多时仅向上扩展，避免向下覆盖尾巴
    local boxBottomY = clamp(self.y, margin + boxH, screenH - margin)
    local boxY = boxBottomY - boxH

    -- 横向也做屏幕内约束，避免气泡整体跑出右侧或左侧
    local drawX = clamp(self.x, margin, screenW - margin - boxW)
    local drawBoxW = boxW
    local drawBoxH = boxH
    
    -- 保存绘图状态
    love.graphics.push()


    -- 漫画风格尾巴：粗端贴在气泡边缘，细端指向目标点
    local sideThreshold = drawX + drawBoxW * 0.5
    local edgeInset = math.max(self.config.tailSize +  self.config.borderWidth, 2)
    local anchorX -- 尾巴根部X坐标，根据目标点位置决定贴在左边还是右边
    if self.targetX <= sideThreshold then
        -- 根部固定在左下
        anchorX = drawX + edgeInset
    else
        -- 根部固定在右下
        anchorX = drawX + drawBoxW - edgeInset
    end
    local anchorY = boxY + drawBoxH

    -- 2. 绘制尾巴
    drawTail(anchorX, anchorY, self.targetX, self.targetY, 
             self.config.tailSize, self.config.borderWidth,
             self.config.bgColor, self.config.borderColor)

    -- 1. 绘制背景
    love.graphics.setColor(self.config.bgColor)
    drawRoundedRect("fill", drawX, boxY, drawBoxW, drawBoxH, self.config.borderRadius)



    -- 3. 绘制边框
    love.graphics.setColor(self.config.borderColor)
    love.graphics.setLineWidth(self.config.borderWidth)
    drawRoundedRect("line", drawX, boxY, drawBoxW, drawBoxH, self.config.borderRadius)
    

    
    -- 4. 绘制文字
    love.graphics.setColor(self.config.textColor)
    love.graphics.setFont(font)
    love.graphics.printf(
        self.text or "",
        drawX + self.config.padding,
        boxY + self.config.padding,
        maxTextWidth,
        "left"
    )
    
    -- 恢复绘图状态
    love.graphics.pop()
end

return DialogueBox