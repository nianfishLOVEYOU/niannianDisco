local bodyItem = require "src.item.bodyItem"

local tree = bodyItem:extend()

function tree:init(x, y, w, h, imgPath, bodyInfo)
    self.type="tree"
    self:setImage("res/image/tree.png")
    self:setBody(w/2,10)
end

function tree:animation()
    --星星一闪一闪
end

return tree