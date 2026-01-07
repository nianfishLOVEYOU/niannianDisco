local imageItem = require "src.item.imageItem"

local floor = imageItem:extend()

function floor:init(x, y, w, h, imgPath)

    self:setImage("res/image/map01.png")
    -- 初始化子类特有属性
    self.type="floor"
    self.layer =0
    self.z=0

end

return floor
