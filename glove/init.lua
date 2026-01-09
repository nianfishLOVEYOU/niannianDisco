--管理ui组件功能
local love = require "love"
local colors = require "glove/colors"
require "glove/string-extensions"
require "src.manager.mouseManager"

local focusedWidget = nil
local g = love.graphics

local utilities = { "colors", "fonts", "fun" }

local widgets = {
  "Button",
  "Button_img",
  "Slider",
  "Checkbox",
  "FPS",
  "HStack",
  "Image",
  "Input",
  "RadioButtons",
  "Select",
  "Spacer",
  "Tabs",
  "Text",
  "Toggle",
  "VStack",
  "ZStack"
}

Glove = {
  clickables = {},
  mousemoveables = {},
  mousereleaseables = {},

  getAvailableHeight = function()
    return g.getHeight() - Glove.margin * 2
  end,

  getAvailableWidth = function()
    return g.getWidth() - Glove.margin * 2
  end,

  hoverColor = colors.green,

  margin = 20, -- inside window

  isFocused = function(widget)
    return widget == focusedWidget
  end,

  mousePressed = function(mouseX, mouseY, button)
    --按照渲染顺序点击
    --按照z轴前后点击
    if button ~= 1 then return end
    local clickWidget=nil
    for _, widget in pairs(Glove.clickables) do
      if widget.visible then
        local x, y, _ = widget:getPos()
        local width, height = self:getSize()
        if x <= mouseX and mouseX <= x + width and
            y <= mouseY and mouseY <= y + height then
          if clickWidget==nil or widget.z>=clickWidget.z then
            clickWidget=widget
          end
        end
      end
    end
    clickWidget:handleClick(mouseX, mouseY)
  end,

  mousemoved = function(x, y, dx, dy)
    for _, widget in pairs(Glove.mousemoveables) do
      if widget.visible then widget:mousemoved(x, y, dx, dy) end
    end
  end,

  mousereleased = function(x, y, button)
    if button ~= 1 then return end
    for _, widget in pairs(Glove.mousereleaseables) do
      if widget.visible then widget:mousereleased(x, y) end
    end
  end,

  setFocus = function(widget)
    if focusedWidget and focusedWidget.removeFocus then
      focusedWidget:removeFocus()
    end
    focusedWidget = widget
  end
}


for _, module in ipairs(utilities) do
  Glove[module] = require("glove/" .. module)
end

for _, module in ipairs(widgets) do
  Glove[module] = require("glove/widgets/" .. module)
end

mouseManager:mousepressed_regester(function(x, y, button)
  Glove.mousePressed(x, y, button)
end)

mouseManager:mouseMoved_regester(function(x, y, dx, dy)
  Glove.mousemoved(x, y, dx, dy)
end)

mouseManager:mouseLeased_regester(function(x, y, button)
  Glove.mousereleased(x, y, button)
end)
