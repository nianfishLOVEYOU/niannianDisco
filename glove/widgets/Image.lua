
local image = require "src.common.aUIImage"
local widget = require "glove.widgets.widget"

local Image = widget:extend()

function Image:init(x, y, w, h, imagepath)
  self.type = "Image"
  self.image = image:new(imagepath, 0, 0, 0, 0)
  self.w,self.h = self.image:getSize()
end

function Image:draw()
    self.image:setPos(self.x,self.y)
    self.image:setScale(1,1)
    self.image:draw()
end


function Image:setSize(w, h)
  self.image:setSize(w,h)
  self.w = w
  self.h = h
end

return Image
