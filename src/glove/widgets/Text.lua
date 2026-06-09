-- 输入框
local widget = require "src.glove.widgets.widget"

local g = love.graphics
local Text = widget:extend()

-- text可以是string 或者 func返回string
function Text:init(text, w, h)
    self.type = "Text"
    local font = g.getFont()
    self.font = font
    self.autoW = false -- 是否根据文本自动调整宽度，默认为false，设置为true后w参数将被忽略
    self.autoH = false -- 是否根据文本自动调整宽高，默认为false，设置为true后w或h参数将被忽略
    self.omit = false -- 是否启用省略号（...）功能，当文本过长时显示省略号
    self.outline = false -- 是否启用描边功能
    self.outlineColor = {0, 0, 0, 1}

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

function Text:setOmit(omit)
    self.omit = omit and true or false
end

function Text:_getOmittedText(value)
    if not self.omit or self.autoW or self.autoH then
        return value
    end
    if not self.w or not self.h or self.w <= 0 or self.h <= 0 then
        return value
    end

    local lineHeight = self.font:getHeight()
    local maxLines = math.floor(self.h / lineHeight)
    if maxLines <= 0 then
        return ""
    end

    local _, wrappedLines = self.font:getWrap(value, self.w)
    if #wrappedLines <= maxLines then
        return value
    end

    local lines = {}
    for i = 1, maxLines do
        lines[i] = wrappedLines[i] or ""
    end

    local ellipsis = "..."
    local last = lines[maxLines] or ""
    while last:utf8len() > 0 and self.font:getWidth(last .. ellipsis) > self.w do
        last = last:utf8sub(1, last:utf8len() - 1)
    end
    if self.font:getWidth(ellipsis) <= self.w then
        lines[maxLines] = last .. ellipsis
    else
        lines[maxLines] = ""
    end

    return table.concat(lines, "\n")
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
    local displayValue = self:_getOmittedText(value)
    if self.outline then
        drawOutlinedText(displayValue, self.x, self.y,self.w,self.color, self.outlineColor)
    else
        if self.w and self.w > 0 then
            g.printf(displayValue, self.x, self.y, self.w, "left")
        else
            g.print(displayValue, self.x, self.y)
        end
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
