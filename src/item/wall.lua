local bodyItem = require "src.item.bodyItem"

local wall = bodyItem:extend()

function wall:init(x, y, w, h, imgPath, bodyInfo)
    
    self.type="wall"
    self:setImage("res/image/wall.png",w,h)
end

return wall