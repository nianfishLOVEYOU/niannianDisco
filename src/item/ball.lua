local bodyItem = require "src.item.bodyItem"

local ball = bodyItem:extend()

function ball:init(x,y,w,h, imgPath, bodyInfo)
    -- 初始化子类特有属性
    obj.type="ball"
end

function ball:interact(player)
    
end

return ball