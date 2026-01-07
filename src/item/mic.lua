local bodyItem = require "src.item.bodyItem"

local mic = bodyItem:extend()

function mic:init(x, y, w, h, imgPath, bodyInfo)
    self.type="mic"
    self:setImage("res/image/mic.png")
    self:setBody(w/1.5,h/2)
end


return mic