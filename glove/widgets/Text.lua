local widget = require "glove.widgets.widget"

local g = love.graphics
local Text = widget:extend()


-- text可以是string 或者 func返回string
function Text:init(text)
  self.type = "Text"
  local font = g.getFont()
  self.font = font
  self:setText(text)
  self:setSize(60, 20)
end

--设置字符
function Text:setText(text)
  self.text = text
  --self:setSize(0, 0)
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
    self.w,self.h = w, h
  end
end

function Text:draw()
  g.setColor(self.color)
  
  local value = self.text or ""
  local limit = self.w
  local i = 1
  local substr
  local substrWidth
  -- 计算当前文字的宽度
  while true do
    substr = value:sub(i, #value)
    substrWidth = self.font:getWidth(substr)
    if substrWidth <= limit then break end
    i = i + 1
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
