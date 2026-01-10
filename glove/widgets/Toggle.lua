local widget = require "glove.widgets.widget"

local Toggle = widget:extend()

local g = love.graphics

local padding = 2
local size = 24
local halfSize = size / 2
local width = size * 1.8

-- 开关表，开关关键key，开关状态改变事件
function Toggle:init(x, y, w, h, t, key, onChange)
  self.type = "Toggle"

  self:setSize(width, size)
  self.font = font
  self.table = t
  self.key = key
  self.onChange = onChange
end

function Toggle:draw()
  local over = self:isOver(love.mouse.getPosition())
  g.setColor(over and Glove.hoverColor or self.color)
  g.setFont(self.font)
  g.rectangle("line", x, y, width, size, halfSize, halfSize)

  g.setColor(self.color)

  local checked = self.table[self.key]
  local circleRadius = size / 2 - padding
  local circleX = checked and x + width - padding - circleRadius or x + padding + circleRadius
  local circleY = y + padding + circleRadius
  g.circle("fill", circleX, circleY, circleRadius)
end

function Toggle:getFontSize()
  local labelWidth = self.font:getWidth(self:getText())
  local labelHeight = self.font:getHeight()
  return labelWidth, labelHeight
end

function Toggle:onClick(x, y, button)
  Glove.setFocus(self)
  local t = self.table
  local key = self.key
  local checked = t[key]
  t[key] = not checked
  if self.onChange then
    self.onChange(t, key, not checked)
  end
end

return Toggle
