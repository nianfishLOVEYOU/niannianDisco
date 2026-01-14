local bodyItem = require "src.item.bodyItem"

local mic = bodyItem:extend()

function mic:init( imgPath, bodyInfo)
    self.type="mic"
    self:setImage("res/image/mic.png")
    self:setBody(self.w/1.5,self.h/2)
end


return mic