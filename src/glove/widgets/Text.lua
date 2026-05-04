--输入框
local widget = require "src.glove.widgets.widget"

local g = love.graphics
local Text = widget:extend()

-- text可以是string 或者 func返回string
function Text:init(text, w, h)
    self.type = "Text"
    local font = g.getFont()
    self.font = font
    self:setText(text)
    self:setSize(w or 60, h or 20)
end

-- 设置字符
function Text:setText(text)
    self.text = text
    -- self:setSize(0, 0)
end

function Text:getFontSize()
    local labelWidth = self.font:getWidth(self:getText())
    local labelHeight = self.font:getHeight()
    return labelWidth, labelHeight
end

function Text:setSize(w, h)
    if w == 0 then
        local labelWidth, labelHeight = self:getFontSize()
        self.w = labelWidth > w and labelWidth or w
        self.h = labelHeight > h and labelHeight or h
    else
        self.w, self.h = w, h
    end
end

function Text:draw()
    g.setColor(self.color)

    local value = self.text or ""
    local limit = self.w
    local i = #value
    local substr = ""
    local substrWidth

    -- 计算当前文字的宽度
    for i = value:utf8len(), 1, -1 do
        substr = value:utf8sub(1, i)
        local substrWidth = self.font:getWidth(substr)
        --print(i, substr, width, limit)
        if substrWidth <= limit then
            break
        end
    end
    g.print(substr, self.x, self.y)
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
