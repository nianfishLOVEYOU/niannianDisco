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
  --"Checkbox",
  --"FPS",
  "HStack",
  "Image",
  "Input",
  --"RadioButtons",
  --"Select",
  "Spacer",
  --"Tabs",
  "Text",
  "Toggle",
  "VStack",
  --"ZStack"
}

local mouseIsDown1=false

Glove = {
  widgets = {},

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
    mouseIsDown1 =true
    local clickWidget=Glove.getFirstWidget(mouseX,mouseY)
    if clickWidget then 
      clickWidget:onClick(mouseX, mouseY)
      Glove.setFocus(clickWidget)
      print(clickWidget.type)
    else 
      print("nil")
      --移除焦点
      Glove.setFocus(nil)
    end
  end,

    -- 获得排序最后最上的ui
  getFirstWidget = function(mouseX,mouseY)
    local clickWidget=nil
    for _, widget in pairs(Glove.widgets) do
      if widget.type =="HStack" or widget.type =="VStack" then
      
      elseif widget.visible then
        local x, y, _ = widget:getPos()
        local width, height = widget:getSize()
        if x <= mouseX and mouseX <= x + width and
            y <= mouseY and mouseY <= y + height then
          if clickWidget==nil or widget.z>=clickWidget.z then
            clickWidget=widget
          end
        end
      end
    end
    return clickWidget
  end,

  mousemoved = function(x, y, dx, dy)
    if mouseIsDown1 then
      local clickWidget=Glove.getFirstWidget(x,y)
      if focusedWidget and focusedWidget ==clickWidget then
        clickWidget:onDrag(x, y,dx,dy)
      end
    else
      local clickWidget=Glove.getFirstWidget(x,y)
      if clickWidget then
        clickWidget:onHold(x, y)
      end
    end
  end,

  mousereleased = function(x, y, button)
    if button ~= 1 then return end
    mouseIsDown1 =false
  end,

  keypressed = function(key)
    if focusedWidget and focusedWidget.keypressed then
      focusedWidget:keypressed(key)
    end
  end,

  setFocus = function(widget)
    if focusedWidget and focusedWidget.removeFocus then
      focusedWidget:removeFocus()
    end
    focusedWidget = widget
  end,
}


for _, module in ipairs(utilities) do
  Glove[module] = require("glove/" .. module)
end

for _, module in ipairs(widgets) do
  print("init ui "..module)
  Glove[module] = require("glove/widgets/" .. module)
end

keybordManager:keypressed_regester(function (key)
  Glove.keypressed(key)
end)

mouseManager:mousepressed_regester(function(x, y, button)
  Glove.mousePressed(x, y, button)
end)

mouseManager:mouseMoved_regester(function(x, y, dx, dy)
  Glove.mousemoved(x, y, dx, dy)
end)

mouseManager:mouseLeased_regester(function(x, y, button)
  Glove.mousereleased(x, y, button)
end)
