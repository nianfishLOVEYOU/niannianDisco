-- dialogueBox.lua - 漫画风格对话框模块
local DialogueBox = {}
DialogueBox.__index = DialogueBox

-- 默认样式配置
local defaultConfig = {
    bgColor = {1, 1, 1, 1},       -- 背景色（白色）
    borderColor = {0, 0, 0, 1},   -- 边框色（黑色）
    textColor = {0, 0, 0, 1},     -- 文字颜色
    borderRadius = 10,            -- 圆角半径
    borderWidth = 2,              -- 边框宽度
    padding = 10,                 -- 内边距
    tailSize = 10,                -- 尾巴大小
    maxWidth = 200                -- 最大宽度
}

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
    
    -- 加载默认字体
    self.font = love.graphics.newFont(16)
    
    return self
end

-- 绘制圆角矩形
local function drawRoundedRect(x, y, w, h, r)
    love.graphics.beginPath()
    -- 左上角
    love.graphics.arc("open", x+r, y+r, r, math.pi, 3*math.pi/2)
    love.graphics.line(x+r, y, x+w-r, y)
    -- 右上角
    love.graphics.arc("open", x+w-r, y+r, r, 3*math.pi/2, 0)
    love.graphics.line(x+w, y+r, x+w, y+h-r)
    -- 右下角
    love.graphics.arc("open", x+w-r, y+h-r, r, 0, math.pi/2)
    love.graphics.line(x+w-r, y+h, x+r, y+h)
    -- 左下角
    love.graphics.arc("open", x+r, y+h-r, r, math.pi/2, math.pi)
    love.graphics.line(x, y+h-r, x, y+r)
    love.graphics.closePath()
end

-- 绘制对话框尾巴
local function drawTail(boxX, boxY, boxW, boxH, targetX, targetY, size, borderWidth)
    local baseX = math.max(boxX + 20, math.min(targetX, boxX + boxW - 20))
    local baseY = boxY + boxH
    
    -- 绘制尾巴填充
    love.graphics.beginPath()
    love.graphics.moveTo(baseX, baseY)
    love.graphics.lineTo(baseX - size, baseY + size)
    love.graphics.lineTo(baseX + size, baseY + size)
    love.graphics.closePath()
    love.graphics.fill()
    
    -- 绘制尾巴边框
    love.graphics.setLineWidth(borderWidth)
    love.graphics.stroke()
end

-- 绘制对话框
function DialogueBox:draw()
    -- 设置字体
    love.graphics.setFont(self.font)
    
    -- 计算文本尺寸
    local textObj = love.graphics.newText(self.font, self.text)
    local textW = math.min(textObj:getWidth(), self.config.maxWidth)
    local textH = textObj:getHeight()
    
    -- 对话框实际尺寸
    local boxW = textW + 2 * self.config.padding
    local boxH = textH + 2 * self.config.padding
    
    -- 保存绘图状态
    love.graphics.push()
    
    -- 1. 绘制背景
    love.graphics.setColor(self.config.bgColor)
    drawRoundedRect(self.x, self.y, boxW, boxH, self.config.borderRadius)
    love.graphics.fill()
    
    -- 2. 绘制边框
    love.graphics.setColor(self.config.borderColor)
    love.graphics.setLineWidth(self.config.borderWidth)
    drawRoundedRect(self.x, self.y, boxW, boxH, self.config.borderRadius)
    love.graphics.stroke()
    
    -- 3. 绘制尾巴
    drawTail(self.x, self.y, boxW, boxH, self.targetX, self.targetY, 
             self.config.tailSize, self.config.borderWidth)
    
    -- 4. 绘制文字
    love.graphics.setColor(self.config.textColor)
    love.graphics.draw(textObj, self.x + self.config.padding, self.y + self.config.padding)
    
    -- 恢复绘图状态
    love.graphics.pop()
end

return DialogueBox