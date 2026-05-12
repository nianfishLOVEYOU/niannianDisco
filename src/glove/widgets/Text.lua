--输入框
local widget = require "src.glove.widgets.widget"

local g = love.graphics
local Text = widget:extend()

-- text可以是string 或者 func返回string
function Text:init(text, w, h)
    self.type = "Text"
    local font = g.getFont()
    self.font = font
    self.autoW = false
    self.autoH = false
    self:setText(text)
    self:setSize(w or 60, h or 20)

end

-- 设置字符
function Text:setText(text)
    self.text = text
    self:_updateLayout()
end

function Text:getFontSize()
    local labelWidth = self.font:getWidth(self:getText())
    local labelHeight = self.font:getHeight()
    return labelWidth, labelHeight
end

function Text:_updateLayout()
    local value = self:getText() or ""
    local lineHeight = self.font:getHeight()

    if self.autoW then
        self.w = self.font:getWidth(value)
    end

    if self.autoH then
        if self.w and self.w > 0 then
            local _, wrappedLines = self.font:getWrap(value, self.w)
            local lines = #wrappedLines
            if lines < 1 then
                lines = 1
            end
            self.h = lines * lineHeight
        else
            self.h = lineHeight
        end
    end
end

-- 设置大小，w为0时根据文本自动调整宽度，h为0时根据文本自动调整高度
function Text:setSize(w, h)
    w = w or self.w or 0
    h = h or self.h or 0

    self.autoW = (w == 0)
    self.autoH = (h == 0)

    if not self.autoW then
        self.w = w
    end
    if not self.autoH then
        self.h = h
    end

    self:_updateLayout()
end

function Text:draw()
    g.setColor(self.color)

    self:_updateLayout()

    local value = self:getText() or ""
    if self.w and self.w > 0 then
        g.printf(value, self.x, self.y, self.w, "left")
    else
        g.print(value, self.x, self.y)
    end
end

function Text:getText()
    local value
    if type(self.text) == "function" then
        value = self.text()
    else
        value = self.text
    end

    return value
end

return Text
