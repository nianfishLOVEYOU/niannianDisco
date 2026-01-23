--管理ui组件功能
local love = require "love"
local colors = require "src.glove.colors"
require "src.glove.string-extensions"
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
  "SlidePanel",
  "Window",
  "ShadePanel",
}

local mouseIsDown1 = false

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


  -- 获得排序最后最上的ui ,type 查找固定的type
  getFirstWidget = function(mouseX, mouseY, type ,nottype)
    local clickWidget = nil
    for _, widget in pairs(Glove.widgets) do

      if widget.visible then
        local _, _, z = widget:getPos()
        if widget:isOver(mouseX, mouseY) and not (nottype and widget.type == nottype) then
          -- 如果控件提供 isOver 方法，则让控件决定该点是否可被点击（用于裁剪区域内外判定）

          local isFindType
          if type then
            isFindType = widget.type == type
          else
            isFindType = true
          end

          if isFindType then
            if clickWidget == nil then
              clickWidget = widget
            else
              local _, _, cz = clickWidget:getPos()
              if z >= cz then
                clickWidget = widget
              end
            end
          end
        end
      end
    end
    return clickWidget
  end,

  mousePressed = function(mouseX, mouseY, button)
    --按照渲染顺序点击
    --按照z轴前后点击
    if button ~= 1 then return end
    mouseIsDown1 = true
    local clickWidget = Glove.getFirstWidget(mouseX, mouseY,nil,"SlidePanel")
    if clickWidget then
      clickWidget:onClick(mouseX, mouseY)
      Glove.setFocus(clickWidget)
      print("'o'mouseInThe:", clickWidget.type, clickWidget.name)
    else
      print(" mousePressed setFocus nil")
      --移除焦点
      Glove.setFocus(nil)
    end

    --滑动块

    local clickSlidePanel = Glove.getFirstWidget(mouseX, mouseY, "SlidePanel")
    if clickSlidePanel then
      Glove.clickSlidePanel = clickSlidePanel
      
    else
      --移除焦点
      Glove.clickSlidePanel = nil
    end
  end,

  mousemoved = function(x, y, dx, dy)
    if mouseIsDown1 then
      local clickWidget = focusedWidget
      if clickWidget then
        clickWidget:onDrag(x, y, dx, dy)
        clickWidget.isDrag = true
      end

      if Glove.clickSlidePanel then
        Glove.clickSlidePanel:onDrag(x, y, dx, dy)
        Glove.clickSlidePanel.isDrag = true
      end
    else
      local clickWidget = Glove.getFirstWidget(x, y)
      if clickWidget then
        clickWidget:onHold(x, y)
      end
    end
  end,

  mousereleased = function(x, y, button)
    if button ~= 1 then return end
    local clickWidget = focusedWidget
    if clickWidget and clickWidget.isDrag then
      clickWidget.isDrag = false
      clickWidget:onDragOver(x, y)
    elseif clickWidget then
      clickWidget:onClickOver(x, y)
    end
    mouseIsDown1 = false

    --滑动条
    if Glove.clickSlidePanel then
      Glove.clickSlidePanel.isDrag = false
      Glove.clickSlidePanel = nil
    end
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
  Glove[module] = require("src.glove." .. module)
end

for _, module in ipairs(widgets) do
  print("init ui " .. module)
  Glove[module] = require("src.glove.widgets." .. module)
end

keybordManager:keypressed_regester(function(key)
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
