local colors = require "glove/colors"
local love = require "love"
local widget = require "glove.widgets.widget"

local g = love.graphics
local padding = 10

local Button = widget:extend()


function Button:init(x, y, w, h, label, func)
  local font = g.getFont()
  self.type = "Button"
  self.font = font
  self.label = label
  self.labelColor = colors.black
  self.clickFunc = func

  self:setSize(w, h)
end

function Button:draw()
  local cornerRadius = padding

  if self:isOver(love.mouse.getPosition()) then
    local op = 3 -- outline padding
    g.setColor(Glove.hoverColor)
    g.rectangle(
      "line",
      self.x - op, self.y - op,
      self.w + op * 2, self.h + op * 2,
      cornerRadius, cornerRadius
    )
  end

  g.setColor(self.color)
  g.rectangle("fill", self.x, self.y, self.w, self.h, cornerRadius, cornerRadius)

  g.setColor(self.labelColor)
  g.setFont(self.font)

  --减去字体宽度
  local fw, fh = self:getFontSize()

  g.print(self.label, self.x + self.w / 2 - fw / 2 + padding,
    self.y + self.h / 2 - fh / 2 + padding)
end

function Button:setText(text)
  self.label = text
  Button:setSize(0, 0)
end

function Button:getFontSize()
  local labelWidth = self.font:getWidth(self.label) + padding * 2
  local labelHeight = self.font:getHeight() + padding * 2
  return labelWidth, labelHeight
end

function Button:setSize(w, h)
  local labelWidth = self.font:getWidth(self.label) + padding * 2
  local labelHeight = self.font:getHeight() + padding * 2
  self.w = labelWidth > w and labelWidth or w
  self.h = labelHeight > h and labelHeight or h
end

function Button:onClick(x, y, button)
  self.clickFunc()
end

function Button:destroy()
  if self.__destroyed then return end
  self.__destroyed = true
  Glove.clickables[self] = nil
end

return Button
