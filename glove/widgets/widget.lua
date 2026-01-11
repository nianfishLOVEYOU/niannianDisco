local item = require "src.item.item"

local widget = item:extend()

-- is widget
function widget:init(x,y,w,h)
  Glove.widgets[self] = self
  self.visible = true
end

function widget:destroy()
  --父类删除
  widget.super.destroy(self)
  Glove.widgets[self] = nil
end

return widget
