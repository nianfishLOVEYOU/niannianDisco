
local widget = require "glove.widgets.widget"

local g = love.graphics
local Text = widget:extend()


-- text可以是string 或者 func返回string
function Text:init(x, y, w, h, text)
  self.type = "Text"
  local font = g.getFont()
  self.font = font
  self:setText(text)
end

--设置字符
function Text:setText(text)
  self.text = text
  self:setSize(0, 0)
end

function Text:getFontSize()
  local labelWidth = self.font:getWidth(self:getText())
  local labelHeight = self.font:getHeight()
  return labelWidth, labelHeight
end

function Text:setSize(w, h)
  local labelWidth, labelHeight = self:getFontSize()
  self.w = labelWidth > w and labelWidth or w
  self.h = labelHeight > h and labelHeight or h
end

function Text:draw()
  g.setColor(self.color)
  g.print(self:getText(), self.x, self.y)
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



