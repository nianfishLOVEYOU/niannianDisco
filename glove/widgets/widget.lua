local item = require "src.item.item"

local widget = item:extend()

-- is widget
function widget:init()
  Glove.widgets[self] = self
  self.visible = true
end

function widget:setVisible(v)
  self.visible=v
end

function widget:destroy()
  --父类删除
  widget.super.destroy(self)
  Glove.widgets[self] = nil
end

return widget
