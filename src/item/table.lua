local bodyItem = require "src.item.bodyItem"

local table = bodyItem:extend()

function table:init( imgPath, bodyInfo)
    self.type="table"
    self:setImage("res/image/table.png")
    self:setBody(self.w,self.h)
end

function table:animation()
    --星星一闪一闪
end

return table