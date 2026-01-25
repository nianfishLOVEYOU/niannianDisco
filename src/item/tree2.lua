local bodyItem = require "src.item.bodyItem"

local tree2 = bodyItem:extend()

function tree2:init( imgPath, bodyInfo)
    self.type="tree2"
    self:setImage("res/image/tree2.png")
    self:setBody(self.w/2,10)
end

function tree2:animation()
    --星星一闪一闪
end

return tree2