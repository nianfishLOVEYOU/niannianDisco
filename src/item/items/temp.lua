local bodyItem = require "src.item.bodyItem"

local temp = bodyItem:extend()

function temp:init( imgPath, bodyInfo)
    self.type="temp"
    self:setImage("res/image/scence/sand_temp.png")
    --self:setScale(0.6,0.6)
    self:setBody(40,10)
end


return temp