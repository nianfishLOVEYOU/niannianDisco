local item = require "src.item.item"

local startPoint = item:extend()

function startPoint:init()
    -- 初始化子类特有属性
    self.type="startPoint"
    self.color = {1,0,0} 
end

return startPoint