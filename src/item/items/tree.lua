local bodyItem = require "src.item.bodyItem"

local tree = bodyItem:extend()

function tree:init( imgPath, bodyInfo)
    self.type="tree"
    self:setImage("res/image/scence/sand_tree.png")
    --self:setScale(0.6,0.6)
    self:setAnchor(0.18,0.96)
    self:setBody(10,10)
end


return tree