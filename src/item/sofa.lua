local bodyItem = require "src.item.bodyItem"

local sofa = bodyItem:extend()

function sofa:init(imgPath, bodyInfo)
    self.type="sofa"
    self:setImage("res/image/sofa.png")
    self:setBody(self.w/1.5,self.h/2)
end

function sofa:setdown()
    --玩家坐在沙发上
end

return sofa