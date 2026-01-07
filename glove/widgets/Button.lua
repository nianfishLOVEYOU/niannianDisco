local colors = require "glove/colors"
local love = require "love"

local g = love.graphics
local padding = 10

local mt = {
  __index = {
    autoSize = true,
    draw = function(self, parentX, parentY)
      local cornerRadius = padding
      local x = parentX + self.x
      local y = parentY + self.y
      self.actualX = x
      self.actualY = y
      --如果有自动尺寸则用自动尺寸，否则用
      local width = self.autoSize and self:getWidth() or self.width
      local height = self.autoSize and self:getHeight() or self.height

      if self:isOver(love.mouse.getPosition()) then
        local op = 3 -- outline padding
        g.setColor(Glove.hoverColor)
        g.rectangle(
          "line",
          x - op, y - op,
          width + op * 2, height + op * 2,
          cornerRadius, cornerRadius
        )
      end

      g.setColor(self.buttonColor)
      g.rectangle("fill", x, y, width, height, cornerRadius, cornerRadius)

      g.setColor(self.labelColor)
      g.setFont(self.font)
      if self.autoSize then
        g.print(self.label, x + padding, y + padding)
      else
        g.print(self.label, x + self.width / 2 - self:getWidth() / 2 + padding,
          y + self.height / 2 - self:getHeight() / 2 + padding)
      end
    end,

    getHeight = function(self)
      local labelHeight = self.font:getHeight()
      return labelHeight + padding * 2
    end,

    getWidth = function(self)
      local labelWidth = self.font:getWidth(self.label)
      return labelWidth + padding * 2
    end,

    handleClick = function(self, clickX, clickY)
      local clicked = self:isOver(clickX, clickY)
      if clicked then
        print("by clicked -----------------")
        Glove.setFocus(self)
        if self.onClick then
          self.onClick()
        end
      end
      return clicked
    end,

    isOver = function(self, mouseX, mouseY)
      local x = self.actualX
      local y = self.actualY
      if not x or not y then return false end
      local width = self:getWidth()
      local height = self:getHeight()
      return x <= mouseX and mouseX <= x + width and
          y <= mouseY and mouseY <= y + height
    end,

    destroy = function(self)
      if self.__destroyed then return end
      self.__destroyed = true
      if self.onDestroy then
        self.onDestroy()
      end
    end,
  }
}

--[[
This widget is a clickable button.

The parameters are:

- text to display on the button
- table of options

The supported options are:

- `buttonColor`: background color of the button; defaults to white
- `font`: font used for the button label
- `labelColor`: color of the label; defaults to black
- `onClick`: function called when the button is clicked
--]]
local function Button(label, options)
  options = options or {}
  assert(type(options) == "table", "Button options must be a table.")

  local font = options.font or g.getFont()
  local instance = options
  instance.kind = "Button"
  instance.font = font
  instance.label = label
  instance.labelColor = instance.labelColor or colors.black
  instance.buttonColor = instance.buttonColor or colors.white
  instance.visible = true
  instance.autoSize = instance.width == nil or instance.height == nil
  instance.width = instance.width or 0
  instance.height = instance.height or 0
  instance.x = 0
  instance.y = 0
  setmetatable(instance, mt)

  Glove.clickables[instance] = instance

  instance.onDestroy = function()
    print("onDestroy")
    Glove.clickables[instance] = nil
  end

  return instance
end

return Button
