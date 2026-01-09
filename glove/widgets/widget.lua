local item = require "src.common.item"

local widget = item:extend()

-- is widget
function widget:init(x,y,w,h)
  Glove.clickables[self] = self
  self.visible = true
end

function widget:destroy()
  --父类删除
  widget.super.destroy(self)
  Glove.clickables[self] = nil
end

return widget
