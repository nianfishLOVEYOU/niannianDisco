local colors = require "src.glove.colors"
local love = require "love"
local widget = require "src.glove.widgets.widget"

local g = love.graphics
local padding = 10

local Button = widget:extend()


function Button:init(label, func)
  local font = g.getFont()
  self.type = "Button"
  self.font = font
  self.label = label
  self.labelColor = colors.black
  self.clickFunc = func
  self:setSize(40, 20)
end

function Button:draw()
  local cornerRadius = padding



  g.setColor(self.color)
  g.rectangle("fill", self.x, self.y, self.w, self.h, cornerRadius, cornerRadius)

  g.setColor(self.labelColor)
  g.setFont(self.font)

  --减去字体宽度
  local fw, fh = self:getFontSize()

  if self:isOver(love.mouse.getPosition()) then
    g.setColor(Glove.hoverColor)
    g.rectangle(
      "line",
      self.x, self.y,
      self.w, self.h,
      cornerRadius, cornerRadius
    )
  end

  g.print(self.label, self.x + self.w / 2 - fw / 2 + padding,
    self.y + self.h / 2 - fh / 2 + padding)
end

function Button:setText(text)
  self.label = text
  self:setSize(0, 0)
end

function Button:getFontSize()
  local labelWidth = self.font:getWidth(self.label) + padding * 2
  local labelHeight = self.font:getHeight() + padding * 2
  return labelWidth, labelHeight
end

function Button:setSize(w, h)
  local labelWidth, labelHeight = self:getFontSize()
  self.w = labelWidth > w and labelWidth or w
  self.h = labelHeight > h and labelHeight or h
end

function Button:onClick(x, y, button)
  self.clickFunc()
end

return Button
