local bodyItem = require "src.item.bodyItem"

local temp = bodyItem:extend()

function temp:init( imgPath, bodyInfo)
    self.type="temp"
    self:setImage("res/image/scence/森林帐篷.png")
    --self:setScale(0.6,0.6)
    self:setBody(40,10)
end

function temp:animation()
    --星星一闪一闪
end

return temp