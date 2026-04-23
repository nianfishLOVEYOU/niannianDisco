local imageItem = require "src.item.imageItem"

local picture = imageItem:extend()

function picture:new( imgPath)
    self.type="picture"
    self:setImage("res/image/picture.png")
    --之后加入可以显示别的图片
end

return picture