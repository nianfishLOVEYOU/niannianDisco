local bodyItem = require "src.item.bodyItem"

local ball = bodyItem:extend()

function ball:init( imgPath, bodyInfo)
    -- 初始化子类特有属性
    self.type="ball"
end

function ball:interact(player)
    
end

return ball