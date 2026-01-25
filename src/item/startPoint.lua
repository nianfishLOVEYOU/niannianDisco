local item = require "src.item.imageItem"

local startPoint = item:extend()

function startPoint:init(imagePath)
    -- 初始化子类特有属性
    self.type="startPoint"
    self.color = {1,1,0} 
    self:setSize(40,40)
    self.layer = 0
    self.z=0.5
end

return startPoint