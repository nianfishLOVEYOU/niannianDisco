--所有ui的父类
local item = require "src.item.item"

local widget = item:extend()

-- is widget
function widget:init()
  Glove.widgets[self] = self
  self.visible = true
  self.color = {1, 1, 1, 1}
end

function widget:setVisible(v)
  self.visible = v
end

-- 设置裁剪,只是裁剪掉isover ，显示还是需要统一来裁剪
function widget:setShade(shade)
  if self == shade then
    print("不能设置自己为裁剪对象!!!!!!!!")
    return
  end
  local function childSetShade(parent, shade)
    parent.shade = shade
    for _, child in pairs(parent.children) do
      childSetShade(child, shade)
    end
  end

  childSetShade(self, shade)
end

function widget:isOver(mouseX, mouseY)
  --如果有裁剪点到外面就不算
  if self.shade and not self.shade:isOver(mouseX, mouseY) then
    
    return false
  end
  local width, height = self:getSize()
  return self.x - self.overPadding <= mouseX and mouseX <= self.x + width and self.y <= mouseY and mouseY <= self.y +
      height
end

function widget:setParentInit()
  if self.parent.shade then
    self.shade = self.parent.shade
  end
  self.localX = self.x - self.parent.x
  self.localY = self.y - self.parent.y
  self.localZ = 1
end

function widget:destroy()
  --父类删除
  widget.super.destroy(self)
  Glove.widgets[self] = nil
end

return widget
