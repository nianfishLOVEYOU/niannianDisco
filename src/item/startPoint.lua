local item = require "src.item.item"

local startPoint = item:extend()

startPoint.__index = startPoint
setmetatable(startPoint, {
    __index = item
}) -- 子类继承父类
function startPoint:init(x, y, w, h)
    -- 初始化子类特有属性
    self.type="startPoint"
    self.color = {1,0,0} 
end

return startPoint